/// Model class representing a ticket type for an event
class TicketTypeModel {
  final int ticketTypeId;
  final int eventId;
  final String ticketName;
  final String ticketDescription;
  final double price;
  final int availableQuantity;
  final int soldQuantity;
  final int maxPerOrder;
  final DateTime? saleStartDate;
  final DateTime? saleEndDate;

  TicketTypeModel({
    required this.ticketTypeId,
    required this.eventId,
    required this.ticketName,
    required this.ticketDescription,
    required this.price,
    required this.availableQuantity,
    required this.soldQuantity,
    required this.maxPerOrder,
    this.saleStartDate,
    this.saleEndDate,
  });

  /// Factory constructor to create TicketTypeModel from JSON
  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    return TicketTypeModel(
      ticketTypeId: json['ticketTypeId'] ?? 0,
      eventId: json['eventId'] ?? 0,
      ticketName: json['ticketName'] ?? '',
      ticketDescription: json['ticketDescription'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      availableQuantity: json['availableQuantity'] ?? 0,
      soldQuantity: json['soldQuantity'] ?? 0,
      maxPerOrder: json['maxPerOrder'] ?? 10,
      saleStartDate: json['saleStartDate'] != null
          ? DateTime.parse(json['saleStartDate'])
          : null,
      saleEndDate: json['saleEndDate'] != null
          ? DateTime.parse(json['saleEndDate'])
          : null,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'ticketTypeId': ticketTypeId,
      'eventId': eventId,
      'ticketName': ticketName,
      'ticketDescription': ticketDescription,
      'price': price,
      'availableQuantity': availableQuantity,
      'soldQuantity': soldQuantity,
      'maxPerOrder': maxPerOrder,
      'saleStartDate': saleStartDate?.toIso8601String(),
      'saleEndDate': saleEndDate?.toIso8601String(),
    };
  }

  /// Check if ticket is currently available for sale
  bool get isAvailable => availableQuantity > 0;

  /// Get remaining tickets count
  int get remainingTickets => availableQuantity;

  /// Format price for display
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Check if ticket sales are currently active
  bool get isSaleActive {
    final now = DateTime.now();
    if (saleStartDate != null && now.isBefore(saleStartDate!)) {
      return false;
    }
    if (saleEndDate != null && now.isAfter(saleEndDate!)) {
      return false;
    }
    return true;
  }
}