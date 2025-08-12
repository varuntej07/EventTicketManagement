import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String qrData;
  final int eventId;
  final String title;       // event name
  final String venue;
  final String dateTime;    // of the event
  final int totalTickets;

  const OrderConfirmationScreen({
    super.key,
    required this.qrData,
    required this.eventId,
    required this.title,
    required this.venue,
    required this.dateTime,
    required this.totalTickets,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('$venue on $dateTime', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Tickets: $totalTickets'),
            const SizedBox(height: 24),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Show this QR at entry', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 18),
                  Center(
                    child: QrImageView(
                      data: eventId.toString(),
                      version: QrVersions.auto,
                      size: 240,
                    ),
                  ),
                ]
              ),
            )
          ],
        ),
      ),
    );
  }
}
