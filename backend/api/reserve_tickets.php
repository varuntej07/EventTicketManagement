<?php
declare(strict_types=1);

ini_set('display_errors', '0');
error_reporting(E_ALL);
header('Content-Type: application/json; charset=utf-8');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/../config/database.php';

const TABLE_RESERVATIONS = 'ticket_reservations';    // table in my database to hold reservations
const TABLE_TICKET_TYPES = 'ticket_types';          // ticket types table

// column names for ticket_types
const TT_COL_ID = 'ticket_type_id';         // PK of ticket_types
const TT_COL_EVENT_ID = 'event_id';         // Event foreign key
const TT_COL_PRICE = 'price';               // unit price
const TT_COL_AVAIL = 'available_quantity';     // Remaining tickets available for this type

// holding window, 2 minutes for testing
const HOLD_MINUTES = 2;

// helper to send an error JSON and abort
function fail(int $code, string $msg, ?string $internal=null): void {
  http_response_code($code);
  $out = ['success'=>false,'message'=>$msg];
  if ($internal) $out['internal_error']=$internal;
  echo json_encode($out, JSON_UNESCAPED_SLASHES);
  exit;
}

// helper to generate a random hex string as token
function gen_token(): string { return bin2hex(random_bytes(16)); }

try {
  $raw = file_get_contents('php://input');              // read raw JSON from request body
  $input = json_decode($raw, true);                     // decoding as associative array
  if (!is_array($input)) fail(400, 'Invalid JSON');

  // session_id is optional; generates only if missing
  $sessionId = trim((string)($input['session_id'] ?? ''));
  if ($sessionId === '') $sessionId = gen_token();

 // event_id and items are required from client
  $eventId = $input['event_id'] ?? null;
  $items = $input['items'] ?? null;             //  Array of objects [{ticket_type_id, quantity}]

  if (!is_numeric($eventId)) fail(400, 'event_id required');
  if (!is_array($items) || !$items ) fail(400, 'items required');

  $norm = [];
  foreach ($items as $i) {                      // looping through client items array
    $tt = $i['ticket_type_id'] ?? null;
    $q  = $i['quantity'] ?? null;
    if (!is_numeric($tt) || !is_numeric($q) || (int)$q <= 0) fail(400, 'Invalid item');
    $norm[] = ['ticket_type_id'=>(int)$tt,'quantity'=>(int)$q];
  }

  // get PDO connection
  $db = (new Database())->getConnection();
  if (!$db) fail(500, 'DB unavailable');
  $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
  $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

  // Values to use in the transaction
  $eventId = (int)$eventId;
  $expiresAt = gmdate('Y-m-d H:i:s', time() + HOLD_MINUTES*60);         // UTC timestamp + 2 minutes to hold
  $userIp = $_SERVER['REMOTE_ADDR'] ?? null;                            // client IP address optional

  $db->beginTransaction();

  // 1. lock ticket type rows to serialize availability checks
  $ttIds = array_column($norm, 'ticket_type_id');
  $ph    = implode(',', array_fill(0, count($ttIds), '?'));
  $sqlLock = sprintf(
    "SELECT %s AS id, %s AS event_id, %s AS price, %s AS avail
       FROM %s
      WHERE %s IN (%s) AND %s = ?
      FOR UPDATE",
    TT_COL_ID, TT_COL_EVENT_ID, TT_COL_PRICE, TT_COL_AVAIL,
    TABLE_TICKET_TYPES,
    TT_COL_ID, $ph, TT_COL_EVENT_ID
  );

  $stmt = $db->prepare($sqlLock);
  $pos=1; foreach ($ttIds as $v) $stmt->bindValue($pos++, $v, PDO::PARAM_INT);
  $stmt->bindValue($pos, $eventId, PDO::PARAM_INT);
  $stmt->execute();
  $locked = $stmt->fetchAll();
  if (count($locked) !== count($norm)) { $db->rollBack(); fail(404,'ticket type not found'); }

  $catalog = [];
  foreach ($locked as $r) $catalog[(int)$r['id']] = ['price'=>(float)$r['price'],'avail'=>(int)$r['avail']];

  // 2. count active (unexpired) holds that already exist
  $sqlHeld = sprintf(
    "SELECT ticket_type_id, COALESCE(SUM(quantity),0) AS qty
       FROM %s
      WHERE ticket_type_id IN (%s)
        AND event_id = ?
        AND status = 'reserved'
        AND expires_at > UTC_TIMESTAMP()
      GROUP BY ticket_type_id",
    TABLE_RESERVATIONS, $ph
  );

  $stmt = $db->prepare($sqlHeld);
  $pos=1; foreach ($ttIds as $v) $stmt->bindValue($pos++, $v, PDO::PARAM_INT);
  $stmt->bindValue($pos, $eventId, PDO::PARAM_INT);
  $stmt->execute();
  $heldByType = [];
  foreach ($stmt->fetchAll() as $r) $heldByType[(int)$r['ticket_type_id']] = (int)$r['qty'];

  // 3 availability check for each ticket type while rows are locked
  foreach ($norm as $it) {
    $ttId = $it['ticket_type_id']; $qty = $it['quantity'];
    if (!isset($catalog[$ttId])) { $db->rollBack(); fail(404,'ticket type not found'); }
    $free = $catalog[$ttId]['avail'] - ($heldByType[$ttId] ?? 0);
    if ($free < $qty) { $db->rollBack(); fail(409,'Not enough availability'); }
  }

  // 4 insert hold rows (one for each ticket type)
  $sqlIns = "INSERT INTO ".TABLE_RESERVATIONS."
    (session_id, event_id, ticket_type_id, quantity, unit_price, total_price,
     status, created_at, expires_at, user_ip)
    VALUES
    (:sid, :eid, :tt, :qty, :u, :t, 'reserved', UTC_TIMESTAMP(), :exp, :ip)";
  $ins = $db->prepare($sqlIns);

  $out = [];
  foreach ($norm as $it) {
    $tt  = $it['ticket_type_id']; $qty = $it['quantity'];
    $u   = $catalog[$tt]['price']; $t = $u*$qty;
    $ins->execute([':sid'=>$sessionId, ':eid'=>$eventId, ':tt'=>$tt, ':qty'=>$qty,
                   ':u'=>$u, ':t'=>$t, ':exp'=>$expiresAt, ':ip'=>$userIp]);
    $out[] = ['ticket_type_id'=>$tt,'quantity'=>$qty,'unit_price'=>number_format($u,2,'.',''),
              'total_price'=>number_format($t,2,'.','')];
  }

  $db->commit();            // commit: release locks, persist holds

  echo json_encode([
    'success'=>true,
    'message'=>'Tickets reserved',
    'session_id'=>$sessionId,            // server-generated if client omitted
    'event_id'=>$eventId,
    'expires_at'=>gmdate('c', strtotime($expiresAt)),
    'reservations'=>$out
  ], JSON_UNESCAPED_SLASHES);

} catch (Throwable $e) {
  if (isset($db) && $db instanceof PDO && $db->inTransaction()) $db->rollBack();
  error_log('reserve_tickets error: '.$e->getMessage());
  // show underlying error to debug
  echo json_encode(['success'=>false,'message'=>'Internal server error','internal_error'=>$e->getMessage()]);
  http_response_code(500);
  exit;
}

