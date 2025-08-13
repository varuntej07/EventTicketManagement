import 'package:eventeny_ticketing/Views/ticket_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ViewModels/events_vm.dart';
import 'event_card.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch events right when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsViewModel>().fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Events',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.tealAccent,
        elevation: 0,
      ),
      body: Consumer<EventsViewModel>(
        builder: (context, eventsViewModel, child) {
          if (eventsViewModel.isLoading) return _buildLoadingState();

          if (eventsViewModel.hasError) return _buildErrorState(eventsViewModel.errorMessage!, eventsViewModel);

          if (!eventsViewModel.hasEvents) return _buildEmptyState();

          return _buildEventsList(eventsViewModel);
        },
      ),
    );
  }

  /// Build loading state widget
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading events...', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorState(String errorMessage, EventsViewModel eventsVM) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => eventsVM.fetchEvents(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No events found', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'There are no events available at the moment.\nPlease check back later.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build events list widget
  Widget _buildEventsList(EventsViewModel eventsVM) {
    return RefreshIndicator(
      onRefresh: () => eventsVM.refreshEvents(),
      child: Column(
        children: [
          // Events count header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Text(
              '${eventsVM.eventsCount} ${eventsVM.eventsCount == 1 ? 'Event' : 'Events'} Available for you',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),

          // Events list
          Expanded(
            child: ListView.builder(
              itemCount: eventsVM.events.length,                // events is a list of EventModel objects from eventsVM
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                final event = eventsVM.events[index];
                return EventCard(
                  event: event,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => TicketSelectionScreen(event: event))); // Navigate to ticket selection screen with the event
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}