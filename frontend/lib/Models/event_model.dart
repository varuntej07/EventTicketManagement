/// Event model representing an event with its details
class EventModel {
  final int id;
  final String name;
  final String description;
  final String date;
  final String time;
  final Venue venue;
  final String imageUrl;
  final int capacity;
  final String status;
  final String createdAt;

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.time,
    required this.venue,
    required this.imageUrl,
    required this.capacity,
    required this.status,
    required this.createdAt,
  });

  /// Factory constructor to create EventModel from JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      venue: Venue.fromJson(json['venue'] ?? {}),
      imageUrl: json['imageUrl'] ?? '',
      capacity: json['capacity'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  /// Convert EventModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date': date,
      'time': time,
      'venue': venue.toJson(),
      'imageUrl': imageUrl,
      'capacity': capacity,
      'status': status,
      'createdAt': createdAt,
    };
  }

  /// Get formatted date and time string
  String get formattedDateTime {
    return '$date at $time';
  }

  /// Check if event is active
  bool get isActive {
    return status.toLowerCase() == 'active';
  }
}

/// Venue model representing event venue information
class Venue {
  final String name;
  final String address;

  Venue({
    required this.name,
    required this.address,
  });

  /// Factory constructor to create Venue from JSON
  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  /// Convert Venue to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
    };
  }

  /// Get full venue information as string
  String get fullVenueInfo {
    return '$name\n$address';
  }
}