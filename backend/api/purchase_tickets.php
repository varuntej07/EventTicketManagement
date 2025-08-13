<?php
declare(strict_types=1);

ini_set('display_errors', '0');
error_reporting(E_ALL);
header('Content-Type: application/json; charset=utf-8');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require_once __DIR__ . '/../config/database.php';

const TABLE_RES = 'ticket_reservations';
const TABLE_TYPES = 'ticket_types';
const TABLE_ORDERS = 'orders';        // table with user_name, event_id, total_amount, order_status, created_at..
const TABLE_LINES = 'order_items';   // table with order_id, ticket_type_id, quantity, unit_price columns

// ticket_types columns
const TT_ID = 'ticket_type_id';
const TT_EVENT = 'event_id';
const TT_AVAIL = 'available_quantity';

function fail(int $code, string $msg, ?string $internal=null): void {
  http_response_code($code);
  $out = ['success'=>false,'message'=>$msg];
  if ($internal) $out['internal_error'] = $internal;
  echo json_encode($out, JSON_UNESCAPED_SLASHES);
  exit;
}

try {
  $raw = file_get_contents('php://input');
  $in = json_decode($raw, true);
  if (!is_array($in)) fail(400, 'Invalid JSON');

  $sessionId = trim((string)($in['session_id'] ?? ''));
  $eventId = $in['event_id'] ?? null;
  $email = trim((string)($in['user_email'] ?? ''));
  $name = trim((string)($in['user_name'] ?? ''));
  $phone = trim((string)($in['user_phone'] ?? ''));

  if ($sessionId === '') fail(400, 'session_id required');
  if (!is_numeric($eventId)) fail(400, 'event_id required');
  $eventId = (int)$eventId;

  $db = (new Database())->getConnection();
  if (!$db) fail(500, 'DB unavailable');
  $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
  $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

  $db->exec("SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED");              // avoids dirty reads and repeatable reads
  $db->beginTransaction();

  // Clean up expired reservations before checking
  $db->prepare("
        UPDATE ticket_reservations
        SET status = 'expired'
        WHERE status = 'reserved' AND expires_at <= NOW()
  ")->execute();

  // 1) Lock this session' active holds so no one else can consume while we finish
  $qHolds = $db->prepare("
    SELECT reservation_id, ticket_type_id, quantity, unit_price
      FROM ".TABLE_RES."
     WHERE session_id = :sid
       AND event_id = :eid
       AND status = 'reserved'
       AND expires_at > UTC_TIMESTAMP()
     FOR UPDATE
  ");
  $qHolds->execute([':sid'=>$sessionId, ':eid'=>$eventId]);
  $holds = $qHolds->fetchAll();
  if (!$holds) { $db->rollBack(); fail(409, 'Hold expired or not found'); }

  // Group quantities by ticket type
  $byType = [];
  $total = 0.0;
  foreach ($holds as $h) {
    $tt = (int)$h['ticket_type_id'];
    $qty = (int)$h['quantity'];
    $price = (float)$h['unit_price'];
    $byType[$tt] = ($byType[$tt] ?? 0) + $qty;
    $total += $price * $qty;
  }

  // 2) Lock ticket_types rows we will decrement
  $ttIds = array_keys($byType);
  $ph = implode(',', array_fill(0, count($ttIds), '?'));

  $qLock = $db->prepare("
    SELECT ".TT_ID." AS id, ".TT_AVAIL." AS avail
      FROM ".TABLE_TYPES."
     WHERE ".TT_ID." IN ($ph) AND ".TT_EVENT." = ?
     FOR UPDATE
  ");

  $pos=1; foreach ($ttIds as $v) $qLock->bindValue($pos++, $v, PDO::PARAM_INT);
  $qLock->bindValue($pos, $eventId, PDO::PARAM_INT);
  $qLock->execute();
  $locked = $qLock->fetchAll();
  if (count($locked) !== count($ttIds)) { $db->rollBack(); fail(404, 'Ticket type not found'); }

  $avail = []; foreach ($locked as $r) { $avail[(int)$r['id']] = (int)$r['avail']; }

  // Verifying if we have enough inventory
  foreach ($byType as $tt => $qty) {
    if (($avail[$tt] ?? 0) < $qty) { $db->rollBack(); fail(409, 'Inventory changed; not enough'); }
  }

  // 4) Insert order header (matches your orders schema; no user_email/expires_at)
  $insOrder = $db->prepare("
    INSERT INTO ".TABLE_ORDERS."
      (user_name, user_phone, event_id, total_amount, order_status, created_at)
    VALUES
      (:name, :phone, :eid, :total, 'confirmed', UTC_TIMESTAMP())
  ");
  $insOrder->execute([
    ':name' => ($name !== '' ? $name : null),
    ':phone' => ($phone !== '' ? $phone : null),
    ':eid' => $eventId,
    ':total' => number_format($total, 2, '.', ''),
  ]);
  $orderId = (int)$db->lastInsertId();

  // Building a simple QR payload for the client that derives the event_id when scanned
  $qrPayload = 'ORD-'.$orderId .'-'.substr(sha1($sessionId.'|'.$eventId), 0, 12);

  // 5) Insert order lines (one per hold row so price history matches)
  $insLine = $db->prepare("
    INSERT INTO ".TABLE_LINES."
      (order_id, ticket_type_id, quantity, unit_price)
    VALUES
      (:oid, :tt, :qty, :price)
  ");
  foreach ($holds as $h) {
    $insLine->execute([
      ':oid' => $orderId,
      ':tt' => (int)$h['ticket_type_id'],
      ':qty' => (int)$h['quantity'],
      ':price' => number_format((float)$h['unit_price'], 2, '.', ''),
    ]);
  }

  // 6) Decrement inventory (+ increment sold) per type
  $dec = $db->prepare("
    UPDATE ticket_types
       SET available_quantity = available_quantity - :qty,
           sold_quantity = COALESCE(sold_quantity,0) + :qty
     WHERE ticket_type_id = :tt
       AND event_id = :eid
       AND available_quantity >= :qty
  ");
  foreach ($byType as $tt => $qty) {
    $dec->execute([':qty'=>$qty, ':tt'=>$tt, ':eid'=>$eventId]);
    if ($dec->rowCount() !== 1) {
      $db->rollBack();
      fail(409, 'Concurrent update; try again');
    }
  }

  // 7) Mark holding tickets as completed
 $upd = $db->prepare("
   UPDATE ticket_reservations
      SET status = 'completed'
    WHERE session_id = :sid
     AND event_id = :eid
     AND status = 'reserved'
     AND expires_at > UTC_TIMESTAMP()
 ");
 $upd->execute([':sid'=>$sessionId, ':eid'=>$eventId]);

 // Preparing confirmation fields expected by the frontend
 $totalTickets = array_sum($byType);

 // fetch event details for confirmation screen
 $eventRow = ['event_name'=>null,'venue_name'=>null,'event_date'=>null,'event_time'=>null];
 $qEvt = $db->prepare("SELECT event_name, venue_name, event_date, event_time
                         FROM events
                        WHERE event_id = :eid
                        LIMIT 1");
 $qEvt->execute([':eid'=>$eventId]);
 if ($tmp = $qEvt->fetch()) { $eventRow = $tmp; }

  $db->commit();

  echo json_encode([
    'success' => true,
    'message' => 'Order confirmed',
    'order_id' => $orderId,
    'event_id' => $eventId,
    'total_amount' => number_format($total, 2, '.', ''),
    'qr' => $qrPayload,
    'title' => $eventRow['event_name'],
    'venue' => $eventRow['venue_name'],
    'date_time' => trim(($eventRow['event_date'] ?? '').' '.($eventRow['event_time'] ?? '')),
    'total_tickets' => $totalTickets,
  ], JSON_UNESCAPED_SLASHES);

} catch (Throwable $e) {
  if (isset($db) && $db instanceof PDO && $db->inTransaction()) $db->rollBack();
  error_log('purchase_tickets error: '.$e->getMessage());
  fail(500, 'Internal server error', $e->getMessage()); // sending JSON, not HTML
}
