import 'package:flutter/foundation.dart';
import '../Models/ticket_type_model.dart';
import '../Services/api_service.dart';

/// ViewModel to manage ticket selection state and business logic
class TicketsViewModel extends ChangeNotifier {
  final ApiService _ticketsService = ApiService();   // Service to fetch ticket types for an event from backend via API declared in api_service.dart

  // State variables
  List<TicketTypeModel> _ticketTypes = [];         // List of TicketTypeModel objects representing available ticket types
  List<TicketSelectionModel> _selections = [];    // List of TicketSelectionModel objects representing user's ticket selections for each ticket type
  bool _isLoading = false;
  String? _errorMessage;

  // Getters for accessing state
  List<TicketTypeModel> get ticketTypes => _ticketTypes;
  List<TicketSelectionModel> get selections => _selections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasTicketTypes => _ticketTypes.isNotEmpty;

  /// Get total amount for all selected tickets
  double get totalAmount {
    return _selections.fold(0.0, (sum, selection) => sum + selection.totalPrice);
  }

  /// Get formatted total amount
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';

  /// Get total number of tickets selected
  int get totalTicketsSelected {
    return _selections.fold(0, (sum, selection) => sum + selection.quantity);
  }

  /// Check if any tickets are selected
  bool get hasSelectedTickets => totalTicketsSelected > 0;

  /// Get selected tickets summary for checkout
  List<Map<String, dynamic>> get selectedTicketsSummary {
    return _selections
        .where((selection) => selection.quantity > 0)
        .map((selection) => {
      'ticketTypeId': selection.ticketType.ticketTypeId,
      'ticketName': selection.ticketType.ticketName,
      'quantity': selection.quantity,
      'unitPrice': selection.ticketType.price,
      'totalPrice': selection.totalPrice,
    }).toList();
  }

  /// Fetch ticket types for a specific event
  Future<void> fetchTicketTypes(int eventId) async {
    _setLoading(true);
    _clearError();

    try {
      // Fetch ticket types from API
      final ticketTypes = await _ticketsService.getTicketTypesForEvent(eventId);

      // Update state with fetched data
      _ticketTypes = ticketTypes;

      // Initialize selections for each ticket type
      _selections = ticketTypes
          .map((ticketType) => TicketSelectionModel(ticketType: ticketType))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Update quantity for a specific ticket type
  void updateTicketQuantity(int ticketTypeId, int newQuantity) {
    try {
      // Find the selection for this ticket type
      final selectionIndex = _selections.indexWhere((selection) => selection.ticketType.ticketTypeId == ticketTypeId);

      if (selectionIndex != -1) {
        final selection = _selections[selectionIndex];

        // Validate new quantity
        if (newQuantity < 0) {
          newQuantity = 0;
        } else if (newQuantity > selection.ticketType.maxPerOrder) {
          newQuantity = selection.ticketType.maxPerOrder;
        } else if (newQuantity > selection.ticketType.remainingTickets) {
          newQuantity = selection.ticketType.remainingTickets;
        }

        // Update quantity
        selection.quantity = newQuantity;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error updating quantity: ${e.toString()}');
    }
  }

  /// Increase quantity for a specific ticket type
  void increaseQuantity(int ticketTypeId) {
    final selection = _getSelectionById(ticketTypeId);
    if (selection != null && selection.canIncrease) {
      selection.increaseQuantity();
      notifyListeners();
    }
  }

  /// Decrease quantity for a specific ticket type
  void decreaseQuantity(int ticketTypeId) {
    final selection = _getSelectionById(ticketTypeId);
    if (selection != null && selection.canDecrease) {
      selection.decreaseQuantity();
      notifyListeners();
    }
  }

  /// Reset all selections
  void resetSelections() {
    for (var selection in _selections) {
      selection.reset();
    }
    notifyListeners();
  }

  /// Get selection by ticket type ID
  TicketSelectionModel? _getSelectionById(int ticketTypeId) {
    try {
      return _selections.firstWhere((selection) => selection.ticketType.ticketTypeId == ticketTypeId);
    } catch (e) {
      return null;
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  void clearData() {
    _ticketTypes = [];
    _selections = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    clearData();
    super.dispose();
  }
}

/// class to track user's ticket selection
class TicketSelectionModel {
  final TicketTypeModel ticketType;  // Ticket type associated with this selection
  int quantity;

  TicketSelectionModel({
    required this.ticketType,
    this.quantity = 0,
  });

  /// Calculate total price for selected quantity
  double get totalPrice => ticketType.price * quantity;

  /// Format total price for display
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  /// Check if selection is valid
  bool get isValid => quantity > 0 && quantity <= ticketType.maxPerOrder;

  /// Check if quantity can be increased
  bool get canIncrease => quantity < ticketType.maxPerOrder && quantity < ticketType.remainingTickets;

  /// Check if quantity can be decreased
  bool get canDecrease => quantity > 0;

  /// Increase quantity by 1
  void increaseQuantity() {
    if (canIncrease) {
      quantity++;
    }
  }

  /// Decrease quantity by 1
  void decreaseQuantity() {
    if (canDecrease) {
      quantity--;
    }
  }

  /// Reset quantity to 0
  void reset() {
    quantity = 0;
  }
}