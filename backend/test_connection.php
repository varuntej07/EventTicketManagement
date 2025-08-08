<?php
/**
 * Test script to verify database connection and setup
 * This will tell us if everything is working correctly
 */

// Include our database class
include_once 'config/database.php';

echo "<h2>Database Connection Test</h2>";

// Try to create database connection by instantiating the class declared in database.php
$database = new Database();
$db = $database->getConnection();

// Check if connection was successful
if ($db) {
    echo "<p style='color: green;'> SUCCESS: Database connected successfully!</p>";
    echo "<p>Connected to database: <strong>event_tickets</strong></p>";

    // Test if our tables exist
    echo "<h3>Checking Tables:</h3>";

    $tables = ['events', 'ticket_types', 'orders', 'order_items', 'tickets'];       // tables already created in phpmyadmin

    foreach ($tables as $table) {
        try {
            $stmt = $db->query("SELECT COUNT(*) as count FROM $table");
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            echo "<p style='color: green;'> Table '$table' exists with {$result['count']} records</p>";
        } catch(PDOException $e) {
            echo "<p style='color: red;'> Table '$table' does not exist or has error</p>";
        }
    }

    // Test sample data
    echo "<h3>Sample Data Check:</h3>";
    try {
        $stmt = $db->query("SELECT event_name, event_date FROM events LIMIT 3");
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            echo "<p>Event: <strong>{$row['event_name']}</strong> on {$row['event_date']}</p>";
        }
    } catch(PDOException $e) {
        echo "<p style='color: red;'> No sample events found</p>";
    }

} else {
    echo "<p style='color: red;'> ERROR: Database connection failed!</p>";
    echo "<p>Please check:</p>";
    echo "<ul>";
    echo "<li>XAMPP MySQL is running</li>";
    echo "<li>Database 'event_tickets' exists</li>";
    echo "<li>Username and password are correct</li>";
    echo "</ul>";
}
?>