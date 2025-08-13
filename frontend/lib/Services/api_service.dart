import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/event_model.dart';
import '../Models/ticket_type_model.dart';

// Base URL for my local XAMPP server
const String baseUrl = 'http://10.0.0.157/event_tickets_api';        // as im using my physical device to test the app had to use my local IP instead of localhost

/// Service class to handle all API calls to the PHP backend
class ApiService {

  // API endpoint to get all events
  static const String eventsEndpoint = '$baseUrl/api/get_events.php';

  /// Fetch all events from the API, returns a list of EventModel objects
  Future<List<EventModel>> fetchEvents() async {
    try {
      // HTTP GET request to fetch events
      final response = await http.get(
        Uri.parse(eventsEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);     // Parse the JSON response

        if (jsonData['success'] == true) {
          final List<dynamic> eventsJson = jsonData['data'] ?? [];          // Extract the events data from the response

          // Converting JSON array to list of EventModel objects
          final List<EventModel> events = eventsJson
              .map((eventJson) => EventModel.fromJson(eventJson))
              .toList();

          return events;
        } else {
          throw Exception('API Error: ${jsonData['message'] ?? 'Unknown error'}');    //  means API returned success: false
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      // any other exceptions, such as network or parsing errors
      throw Exception('Failed to fetch events: $e');
    }
  }

  /// Fetch all ticket types for a specific eventId, returns a list of TicketTypeModel objects
  Future<List<TicketTypeModel>> getTicketTypesForEvent(int eventId) async {
    try {
      // API endpoint URL with event ID parameter
      final getTicketTypesForEventEndpoint = Uri.parse('$baseUrl/api/get_tickets.php?event_id=$eventId');

      final response = await http.get(
        getTicketTypesForEventEndpoint,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Please check your connection.');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          // Extract ticket types data
          final List<dynamic> ticketTypesJson = jsonResponse['data'] ?? [];

          // Convert JSON to list of TicketTypeModel objects
          return ticketTypesJson
              .map((ticketJson) => TicketTypeModel.fromJson(ticketJson))
              .toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load ticket types');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Re-throw the error to be handled by ViewModel
      throw Exception('Error fetching ticket types: ${e.toString()}');
    }
  }

  Future<ReserveResponse> reserveTickets({
    required String sessionId,
    required int eventId,
    required List<Map<String, dynamic>> items,
  }) async {
    final reserveTicketsEndpoint = Uri.parse("$baseUrl/api/reserve_tickets.php");
    final res = await http.post(
      reserveTicketsEndpoint,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "session_id": sessionId,
        "event_id": eventId,
        "items":items.map((m) => {
          "ticket_type_id": m["ticket_type_id"] ?? m["ticketTypeId"],
          "quantity": m["quantity"] ?? m["qty"] ?? m["selectedQuantity"],
        }).toList(),
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Reserve failed: HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Reservation failed');
    }
    return ReserveResponse.fromJson(body);
  }

  // POST request to purchase tickets when user confirms payment
  Future<Map<String, dynamic>> purchaseTickets({
    required String sessionId,
    required int eventId,
    String? email,
    String? name,
    String? phone,
  }) async {
    final url = Uri.parse('$baseUrl/api/purchase_tickets.php');
    print('purchasing tickets with URL: $url, for body $sessionId, $eventId, $email, $name, $phone from reservation_screen.dart');
    final res = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'event_id': eventId,
        'user_email': email,
        'user_name': name,
        'user_phone': phone,
      }),
    );
    final body = jsonDecode(res.body);
    print('Final purchase response body after decoding: $body');
    if (res.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Purchase failed');
    }
    return body; // has order_id, event_id, total_amount, qr, title, venue, date_time, total_tickets
  }
}

class ReserveResponse {
  final bool success;
  final String sessionId;
  final int eventId;
  final DateTime expiresAtUtc;
  final List<dynamic> reservations;
  ReserveResponse({
    required this.success,
    required this.sessionId,
    required this.eventId,
    required this.expiresAtUtc,
    required this.reservations,
  });
  factory ReserveResponse.fromJson(Map<String, dynamic> j) {
    return ReserveResponse(
      success: j['success'] == true,
      sessionId: j['session_id'],
      eventId: j['event_id'],
      expiresAtUtc: DateTime.parse(j['expires_at']).toUtc(),
      reservations: j['reservations'] ?? const [],
    );
  }
}