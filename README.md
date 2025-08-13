This project is a mobile event ticketing system that demonstrates safe ticket reservations and purchasing with concurrency control. 

The system lets users browse events and ticket types, reserve tickets with a 2-minute hold, prevent double-booking of the last ticket, complete purchases that update inventory and confirm orders, and generate a QR code for confirmation.

Built with Flutter/Dart for the frontend, PHP (PDO, InnoDB) for the backend, MySQL (XAMPP) for the database, and Apache (XAMPP) as the server.

**Database Tables**
events: stores event details;
ticket_types: stores ticket type info, price, and stock;
ticket_reservations: holds active/expired/completed reservations;
orders: records confirmed purchases;
order_items: stores purchased ticket details;

This project was developed as part of my second-round interview, where I was asked to design and implement a complete event ticke management system with concurrency-safe reservations and purchases.
