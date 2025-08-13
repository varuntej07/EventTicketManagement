import 'package:flutter/material.dart';
import '../Models/event_model.dart';

/// Reusable EventCard widget to display event information in a card format
class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            _buildEventImage(),

            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  _buildEventName(context),

                  const SizedBox(height: 8),

                  // Event Description
                  _buildEventDescription(context),

                  const SizedBox(height: 12),

                  // Date and Time
                  _buildDateTimeRow(),

                  const SizedBox(height: 8),

                  // Venue Information
                  _buildVenueInfo(),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build event image with placeholder
  Widget _buildEventImage() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        color: Colors.grey[300],
      ),
      child: event.imageUrl.isNotEmpty
          ? ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        child: Image.network(
          event.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>  _buildImagePlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      )
          : _buildImagePlaceholder(),
    );
  }

  /// Build image placeholder when no image is available
  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[400]!, Colors.purple[400]!],
        ),
      ),
      child: const Center(child: Icon(Icons.event, size: 48, color: Colors.white)),
    );
  }

  /// Build event name
  Widget _buildEventName(BuildContext context) {
    return Text(
      event.name,
      style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold, fontSize: 20)
    );
  }

  /// Build event description
  Widget _buildEventDescription(BuildContext context) {
    return Text(
      event.description,
      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build date and time row
  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            event.formattedDateTime,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Build venue information
  Widget _buildVenueInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            event.venue.fullVenueInfo,
            style: TextStyle(color: Colors.grey[700]),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}