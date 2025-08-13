<?php
// Enable CORS for Flutter app to access the API
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Include database connection
require_once __DIR__ . '/../config/database.php';

// Create database instance with the class declared in database.php and get database connection
$database = new Database();
$db = $database->getConnection();               // creates and returns a PDO connection object

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
    // SQL query to fetch all active events
    $query = "SELECT * FROM events WHERE status = 'active' ORDER BY event_date ASC";

    $stmt = $db->prepare($query);                   // compiles the sql query first and returns a PDO statement object
    $stmt->execute();

    // Fetch all events as associative array (keys are column names)
    $events = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format the response data
    $formatted_events = [];
    foreach ($events as $event) {
        $formatted_events[] = [
            'id' => (int)$event['event_id'],
            'name' => $event['event_name'],
            'description' => $event['event_description'],
            'date' => $event['event_date'],
            'time' => $event['event_time'],
            'venue' => [
                'name' => $event['venue_name'],
                'address' => $event['venue_address']
            ],
            'imageUrl' => $event['event_image_url'],
            'capacity' => (int)$event['total_capacity'],
            'status' => $event['status'],
            'createdAt' => $event['created_at']
        ];
    }

    // Return successful response with events data
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Events retrieved successfully",
        "data" => $formatted_events,
        "count" => count($formatted_events)
    ]);

} catch(PDOException $exception) {
    http_response_code(500);            // database errors with messages sent to client if any
    echo json_encode([
        "success" => false,
        "message" => "Failed to retrieve events: " . $exception->getMessage()
    ]);
}

// Close database connection
$db = null;
?>