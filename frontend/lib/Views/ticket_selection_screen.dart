import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ViewModels/tickets_vm.dart';
import '../models/event_model.dart';
import 'event_card.dart';

/// Screen for selecting tickets for a specific event
class TicketSelectionScreen extends StatefulWidget {
  final EventModel event;       // Event for which tickets are being selected in the previous screen

  const TicketSelectionScreen({super.key, required this.event});

  @override
  State<TicketSelectionScreen> createState() => _TicketSelectionScreenState();
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  late TicketsViewModel _ticketsViewModel;    // late because it's initialized in initState

  @override
  void initState() {
    super.initState();
    // Initialize ViewModel and fetch ticket types
    _ticketsViewModel = TicketsViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ticketsViewModel.fetchTicketTypes(widget.event.id);  // Fetch ticket types for a specific event, widget is passed in the constructor above
    });
  }

  @override
  void dispose() {
    _ticketsViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ticketsViewModel,     // using already initialized ViewModel in initState to share data between widgets
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Select Tickets'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          elevation: 0,
        ),
        body: Consumer<TicketsViewModel>(              // Consumer to listen to ViewModel changes
          builder: (context, ticketsVM, child) {      // ticketsVM is the reference of TicketsViewModel above
            if (ticketsVM.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (ticketsVM.hasError) {
              return _buildErrorState(ticketsVM.errorMessage!);     // Any error message if caught in TicketsViewModel
            }

            if (!ticketsVM.hasTicketTypes) {
              return _buildEmptyState();                  // Empty state if no ticket types available for the event
            }

            return _buildContent(ticketsVM);
          },
        ),
        bottomNavigationBar: Consumer<TicketsViewModel>(
          builder: (context, ticketsVM, child) {
            if (!ticketsVM.hasTicketTypes || ticketsVM.isLoading) {
              return const SizedBox.shrink();
            }
            return _buildBottomBar(ticketsVM);
          },
        ),
      ),
    );
  }

  /// Helper empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
                'No tickets available for this event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper error state widget
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load tickets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _ticketsViewModel.fetchTicketTypes(widget.event.id),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }

  /// Main content with event details in same card structure as in the previous example and ticket list with quantity selector for the selected event
  Widget _buildContent(TicketsViewModel viewModel) {
    return Column(
      children: [
        // Fixed custom EventCard at the top of the ticket selection screen declared in event_card.dart
        EventCard(event: widget.event, onTap: null),

        // Expanded to make the rest of the content scrollable
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ticket selection header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    "Select Tickets",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87
                    ),
                  ),
                ),

                // Ticket types list (Early bird, GA, VIP)
                _buildTicketsList(viewModel),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build list of ticket types
  Widget _buildTicketsList(TicketsViewModel ticketsVM) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: ticketsVM.selections.length,     // Number of ticket types available for the specific event (3 types if it has Early bird, GA, VIP ticket types)
      itemBuilder: (context, index) {
        final selection = ticketsVM.selections[index];
        return _buildTicketCard(selection, ticketsVM);
      },
    );
  }

  /// Custom helper ticket card widget responsible for displaying ticket type details and quantity selector
  Widget _buildTicketCard(TicketSelectionModel selection, TicketsViewModel viewModel) {
    final ticketType = selection.ticketType;
    final isAvailable = ticketType.isAvailable;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selection.quantity > 0 ? Colors.blue : Colors.grey[300]!,
          width: selection.quantity > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row - ticket type and price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ticketType.ticketName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  ticketType.formattedPrice,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green[700] : Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Description about the ticket type
            if (ticketType.ticketDescription.isNotEmpty)
              Text(
                ticketType.ticketDescription,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 1,
              ),

            const SizedBox(height: 8),

            // Availability status and sold out message
            Text(
              isAvailable ? 'Only ${ticketType.remainingTickets} tickets left, hurry up' : 'Sold Out',
              style: TextStyle(
                fontSize: 12,
                color: isAvailable ? Colors.grey[600] : Colors.red,
                fontWeight: isAvailable ? FontWeight.normal : FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Quantity selector
            if (isAvailable)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quantity:', style: TextStyle(fontSize: 14, color: Colors.grey[700])),

                  // Ticket quantity selector widget
                  _buildQuantitySelector(selection, viewModel),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Helper ticket quantity selector widget with + and - buttons
  Widget _buildQuantitySelector(TicketSelectionModel selection, TicketsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(14)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button, disabled if quantity is 0
          IconButton(
            onPressed: selection.canDecrease
                ? () => viewModel.decreaseQuantity(selection.ticketType.ticketTypeId)
                : null,
            icon: const Icon(Icons.remove),
            iconSize: 16,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),

          // Quantity display
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            child: Text(
              '${selection.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Increase button
          IconButton(
            onPressed: selection.canIncrease
                ? () => viewModel.increaseQuantity(selection.ticketType.ticketTypeId)
                : null,
            icon: const Icon(Icons.add),
            iconSize: 16,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  /// Build bottom bar with total and proceed button
  Widget _buildBottomBar(TicketsViewModel viewModel) {
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
            // Total summary
            if (viewModel.hasSelectedTickets)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${viewModel.totalTicketsSelected} ${viewModel.totalTicketsSelected == 1 ? 'Ticket' : 'Tickets'}',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    Text(
                      'Total: ${viewModel.formattedTotalAmount}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),

            // Proceed button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: viewModel.hasSelectedTickets
                    ? () => _handleProceed(viewModel)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: viewModel.hasSelectedTickets ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle proceed button tap
  void _handleProceed(TicketsViewModel viewModel) {
    // TODO: Navigate to payment screen by locking the tickets for 10 minutes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${viewModel.totalTicketsSelected} tickets for ${viewModel.formattedTotalAmount}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}