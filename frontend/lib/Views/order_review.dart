import 'package:eventeny_ticketing/Views/reservation_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/event_model.dart';
import '../ViewModels/tickets_vm.dart';
import 'event_card.dart';

class OrderReviewScreen extends StatefulWidget {
  final EventModel event;
  final List<Map<String, dynamic>> selectedTicketsSummary;
  final double totalAmount;

  const OrderReviewScreen({
    super.key,
    required this.event,
    required this.selectedTicketsSummary,
    required this.totalAmount,
  });

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  late TicketsViewModel _ticketsViewModel; // late because it's initialized in initState

  @override
  void initState() {
    super.initState();
    _ticketsViewModel = TicketsViewModel();     // Initializing ViewModel here
  }

  @override
  void dispose() {
    _ticketsViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ticketsViewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Order Review'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          elevation: 0,
        ),
        body: Consumer<TicketsViewModel>(
          builder: (context, ticketsVM, child) {
            if (ticketsVM.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // Reusing EventCard again
                EventCard(event: widget.event, onTap: null),

                // Order Summary
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),

                        SizedBox(height: 20),

                        // Selected tickets list with quantity and total price
                        ...widget.selectedTicketsSummary.map((ticket) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(ticket['ticketName'] ?? "General Ticket", style: TextStyle(fontSize: 16))
                                  ),
                                  Row(
                                    children: [
                                      Text('${ticket['quantity'] ?? 0}', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                      Text(' X ', style: TextStyle(color: Colors.black54)),
                                      Text('\$${ticket['unitPrice'].toStringAsFixed(2) ?? 0}', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric( horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Service Charges(18%):', style: TextStyle(fontSize: 12)),
                              Text('\$${(widget.totalAmount * 0.18).toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                            ],
                          ),
                        ),

                        Divider(),

                        // Total Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('\$${widget.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                          ],
                        ),

                        SizedBox(height: 50),

                        Center(child:Text("Taxes apply depending on billing address", style: TextStyle(fontSize: 12, color: Colors.black54))),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomBar(_ticketsViewModel),
      ),
    );
  }

  Widget _buildBottomBar(TicketsViewModel ticketsVM) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Proceed to payment button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _handleProceed(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProceed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationTestPage(
          eventId: widget.event.id,                // Accessing event from widget (from the constructor)
          items: widget.selectedTicketsSummary,   // list of maps with ticket summary
          ticketsSummary : widget.selectedTicketsSummary,
        ),
      ),
    );
  }
}