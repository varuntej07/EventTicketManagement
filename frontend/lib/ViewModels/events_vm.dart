import 'package:flutter/foundation.dart';
import '../Models/event_model.dart';
import '../services/api_service.dart';

/// ViewModel for managing events data and state
class EventsViewModel extends ChangeNotifier {
  // Private fields
  final ApiService _apiService = ApiService();    // Instance of ApiService for API calls to backend server
  List<EventModel> _events = [];          // List to store fetched events
  bool _isLoading = false;
  String? _errorMessage;

  // Public getters to access private fields
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Additional getters for UI convenience
  bool get hasEvents => _events.isNotEmpty;
  bool get hasError => _errorMessage != null;
  int get eventsCount => _events.length;

  /// Fetch events from the API
  Future<void> fetchEvents() async {
    // Set loading state to true and clear any previous errors
    _setLoading(true);
    _clearError();

    try {
      final List<EventModel> fetchedEvents = (await _apiService.fetchEvents()).cast<EventModel>();

      // Update the events list with fetched data
      _events = fetchedEvents;
      notifyListeners();

    } catch (error) {
      _setError('Failed to load events: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh events data, this method can be called for pull-to-refresh functionality
  Future<void> refreshEvents() async {
    await fetchEvents();
  }

  /// Get event by ID
  EventModel? getEventById(int id) {
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Filter events by status
  List<EventModel> getEventsByStatus(String status) {
    return _events.where((event) => event.status.toLowerCase() == status.toLowerCase()).toList();
  }

  /// Get only active events
  List<EventModel> get activeEvents {
    return getEventsByStatus('active');
  }

  ///------ Private helper methods-------------///

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearData() {
    _events = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}