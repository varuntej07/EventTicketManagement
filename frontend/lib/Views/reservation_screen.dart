import 'dart:async';
import 'package:flutter/material.dart';
import '../Services/api_service.dart';
import 'order_confirmation.dart';

class ReservationTestPage extends StatefulWidget {
  final int eventId;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> ticketsSummary;

  const ReservationTestPage({
    super.key,
    required this.eventId,
    required this.items,
    required this.ticketsSummary,
  });

  @override
  State<ReservationTestPage> createState() => _ReservationTestPageState();
}

class _ReservationTestPageState extends State<ReservationTestPage> {
  static const _holdSeconds = 120;

  DateTime? _expiresAtUtc;
  Duration _clockSkew = Duration.zero; // server_now_estimate - device_now
  Timer? _timer;
  Duration _remaining = const Duration(seconds: _holdSeconds);
  bool _loading = false;
  bool _holdReady = false; // hide clock until we have server time
  String? _error;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _reserveNow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _reserveNow() async {
    setState(() {
      _loading = true;
      _error = null;
      _holdReady = false;
    });

    final sessionId = _ensureSessionId();

    try {
      final api = ApiService();
      final resp = await api.reserveTickets(        // Making a POST request to the API
        sessionId: sessionId,
        eventId: widget.eventId,
        items: widget.items,
      );

      _sessionId = resp.sessionId;
      _expiresAtUtc = resp.expiresAtUtc;

      // Estimate server 'now' as expires_at - 120s, then compute skew vs device.
      final serverNowEstimate = _expiresAtUtc!.subtract(const Duration(seconds: _holdSeconds));
      final deviceNowUtc = DateTime.now().toUtc();
      _clockSkew = serverNowEstimate.difference(deviceNowUtc);

      // First tick immediately so you see a proper value (02:00 -> ..).
      _startCountdown();

      // Proof in logs that rows are held
      print('HOLD CONFIRMED -> session=$_sessionId event=${resp.eventId} '
          'expiresAt(UTC)=${_expiresAtUtc!.toIso8601String()}'
      );

      _holdReady = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    if (_expiresAtUtc == null) return;

    void tick() {
      final adjustedNow = DateTime.now().toUtc().add(_clockSkew);
      final diff = _expiresAtUtc!.difference(adjustedNow);
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
      if (diff <= Duration.zero) _timer?.cancel();
    }

    tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _fmtClock(Duration d) {
    final total = d.inSeconds;
    final sec = total < 0 ? 0 : total;
    final mm = (sec ~/ 60).toString().padLeft(2, '0');
    final ss = (sec % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  bool get _active => _expiresAtUtc != null && _remaining > Duration.zero;

  @override
  Widget build(BuildContext context) {
    final clockText = _fmtClock(_remaining);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const Text('Complete payment before the hold expires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            // Digital countdown (shown only after we know server time)
            if (_holdReady) Text(
              clockText,
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ) else const SizedBox(height: 88),

            const Spacer(),

            Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),

            const Divider(indent: 150, endIndent: 150),

            SizedBox(height: 20),

            // Selected tickets list with quantity and total price
            ...widget.ticketsSummary.map((ticket) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Column(
                    children: [
                      Text(ticket['ticketName'] ?? "General Ticket", style: const TextStyle(fontSize: 18)),
                      Text(
                        '${ticket['quantity'] ?? 0} x \$${ticket['unitPrice'].toStringAsFixed(2) ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),

                      const SizedBox(width: 20),

                      Text('\$${ticket['totalPrice'].toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700], fontSize: 18),
                      ),
                    ],
                  ),
                ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _active ? () async {
                  try {
                    final api = ApiService();
                    final resp = await api.purchaseTickets(
                      sessionId: _sessionId!,
                      eventId: widget.eventId,
                      // no email/name/phone to pass
                    );
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrderConfirmationScreen(
                              qrData: resp['qr'],
                              eventId: resp['event_id'],
                              title: resp['title'],
                              venue: resp['venue'],
                              dateTime: resp['date_time'],
                              totalTickets: resp['total_tickets'],
                            )
                        )
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Purchase failed: $e')),
                    );
                  }
                } : null,
                child: const Text('Buy Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            if (!_active) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _reserveNow,
                  child: const Text('Hold expired, Select the tickets again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ),
              ),
            ],
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

String _ensureSessionId() {
    // should persist a UUID in SharedPreferences for real use cases
    // Minimal MVP, so using single hardcoded token for local testing
    return 'demo-session-123';
  }
}
