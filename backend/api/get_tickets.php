<?php
// Enable CORS for Flutter app to access the API
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require_once '../config/database.php';      // path to the database.php file in the config folder

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
if ($event_id === false) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Invalid Event ID format"
    ]);
    exit();
}

// Create database instance and get connection
$database = new Database();
$db = $database->getConnection();

// Check if database connection is successful
if ($db === null) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Database connection failed"
    ]);
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
        echo json_encode([
            "success" => false,
            "message" => "Event not found"
        ]);
        exit();
    }

    if ($event['status'] !== 'active') {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Event is not active"
        ]);
        exit();
    }

    // SQL query to fetch all ticket types for the specified event
    $query = "SELECT
                ticket_type_id,
                event_id,
                ticket_name,
                ticket_description,
                price,
                available_quantity,
                sold_quantity,
                max_per_order,
                sale_start_date,
                sale_end_date
              FROM ticket_types
              WHERE event_id = :event_id
              ORDER BY price ASC";

    // Prepare and execute the query
    $stmt = $db->prepare($query);
    $stmt->bindParam(':event_id', $event_id, PDO::PARAM_INT);
    $stmt->execute();

    // Fetch all ticket types as associative array
    $ticketTypes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format the response data
    $formatted_ticket_types = [];
    foreach ($ticketTypes as $ticket) {
        // Calculate if ticket is currently on sale
        $now = new DateTime();
        $isOnSale = true;

        if ($ticket['sale_start_date']) {
            $saleStart = new DateTime($ticket['sale_start_date']);
            if ($now < $saleStart) {
                $isOnSale = false;
            }
        }

        if ($ticket['sale_end_date']) {
            $saleEnd = new DateTime($ticket['sale_end_date']);
            if ($now > $saleEnd) {
                $isOnSale = false;
            }
        }

        $formatted_ticket_types[] = [
            'ticketTypeId' => (int)$ticket['ticket_type_id'],
            'eventId' => (int)$ticket['event_id'],
            'ticketName' => $ticket['ticket_name'],
            'ticketDescription' => $ticket['ticket_description'] ?? '',
            'price' => (float)$ticket['price'],
            'availableQuantity' => (int)$ticket['available_quantity'],
            'soldQuantity' => (int)$ticket['sold_quantity'],
            'maxPerOrder' => (int)($ticket['max_per_order'] ?? 10),
            'saleStartDate' => $ticket['sale_start_date'],
            'saleEndDate' => $ticket['sale_end_date'],
            'isOnSale' => $isOnSale,
            'remainingQuantity' => (int)$ticket['available_quantity'] - (int)$ticket['sold_quantity']
        ];
    }

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
    // Handle database errors
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Failed to retrieve ticket types: " . $exception->getMessage()
    ]);
}

// Close database connection
$db = null;
?>