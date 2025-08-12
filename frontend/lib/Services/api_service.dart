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

      // Check if the request was successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);     // Parse the JSON response

        // Check if the API response indicates success
        if (jsonData['success'] == true) {
          // Extract the events data from the response
          final List<dynamic> eventsJson = jsonData['data'] ?? [];

          // Converting JSON array to list of EventModel objects
          final List<EventModel> events = eventsJson
              .map((eventJson) => EventModel.fromJson(eventJson))
              .toList();

          return events;
        } else {
          throw Exception('API Error: ${jsonData['message'] ?? 'Unknown error'}');    //  means API returned success: false
        }
      } else {
        // HTTP request failed
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

    final bodyText = res.body;
    print('reserve ${res.statusCode} ${res.headers['content-type']} len=${bodyText.length}');


    if (res.statusCode != 200) {
      throw Exception('Reserve failed: HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Reservation failed');
    }
    return ReserveResponse.fromJson(body);
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
