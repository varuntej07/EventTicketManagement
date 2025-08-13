<?php
// Enable CORS & JSON headers for Flutter app to access the API
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . '/../config/database.php';    // path to the database.php file in the config folder

// Explicit timezone to avoid surprises on XAMPP
date_default_timezone_set('UTC');

// Check if event_id parameter is provided
if (!isset($_GET['event_id']) || empty($_GET['event_id'])) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Event ID is required"
    ]);
    exit();
}

// Validate event_id is a number
$event_id = filter_var($_GET['event_id'], FILTER_VALIDATE_INT);

if ($event_id === false || $event_id <= 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Invalid Event ID"
    ]);
    exit();
}

// Create database instance and get connection
$database = new Database();
$db = $database->getConnection();
if ($db === null) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database connection failed"]);
    exit();
}

try {
    // First, check if the event exists and is active
    $eventCheckQuery = "SELECT event_id, status FROM events WHERE event_id = :event_id";
    $eventStmt = $db->prepare($eventCheckQuery);
    $eventStmt->bindParam(':event_id', $event_id, PDO::PARAM_INT);
    $eventStmt->execute();
    $event = $eventStmt->fetch(PDO::FETCH_ASSOC);

    if (!$event) {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Event not found for the given ID"]);
        exit();
    }

    if ($event['status'] !== 'active') {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Event is not active"]);
        exit();
    }

    // SQL query to fetch all ticket types for the specified event
    $query = "
            SELECT
                ticket_type_id,
                event_id,
                ticket_name,
                COALESCE(ticket_description, '') AS ticket_description,
                price,
                available_quantity,
                sold_quantity,
                COALESCE(max_per_order, 10) AS max_per_order,
                sale_start_date,
                sale_end_date,
                GREATEST(available_quantity - sold_quantity, 0) AS remaining_quantity,
                CASE
                  WHEN (sale_start_date IS NOT NULL AND UTC_TIMESTAMP() < sale_start_date) THEN 0
                  WHEN (sale_end_date IS NOT NULL AND UTC_TIMESTAMP() > sale_end_date) THEN 0
                  ELSE 1
                END AS is_on_sale
            FROM ticket_types
            WHERE event_id = :event_id
            ORDER BY price ASC
        ";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':event_id', $event_id, PDO::PARAM_INT);
    $stmt->execute();
    $ticketTypes = $stmt->fetchAll(PDO::FETCH_ASSOC);

   // Shape response by preserving the original column names (keys)
   $formatted_ticket_types = array_map(function ($t) {
       return [
           'ticketTypeId' => (int)$t['ticket_type_id'],
           'eventId' => (int)$t['event_id'],
           'ticketName' => $t['ticket_name'],
           'ticketDescription' => $t['ticket_description'],
           'price' => (float)$t['price'],
           'availableQuantity' => (int)$t['available_quantity'],
           'soldQuantity' => (int)$t['sold_quantity'],
           'maxPerOrder' => (int)$t['max_per_order'],
           'saleStartDate' => $t['sale_start_date'],
           'saleEndDate' => $t['sale_end_date'],
           'isOnSale' => (bool)$t['is_on_sale'],
           'remainingQuantity' => (int)$t['remaining_quantity'],
       ];
   }, $ticketTypes);

    // Return successful response with ticket types data
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Ticket types retrieved successfully",
        "eventId" => $event_id,
        "data" => $formatted_ticket_types,
        "count" => count($formatted_ticket_types)
    ]);

} catch(PDOException $exception) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Failed to retrieve ticket types: " . $exception->getMessage()
    ]);
}

$db = null;
?>