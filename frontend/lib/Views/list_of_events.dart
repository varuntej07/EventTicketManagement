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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            onPressed: () {
              context.read<EventsViewModel>().refreshEvents();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Events',
          ),
        ],
      ),
      body: Consumer<EventsViewModel>(
        builder: (context, eventsViewModel, child) {
          if (eventsViewModel.isLoading) {
            return _buildLoadingState();
          }

          if (eventsViewModel.hasError) {
            return _buildErrorState(eventsViewModel.errorMessage!, eventsViewModel);
          }

          if (!eventsViewModel.hasEvents) {
            return _buildEmptyState();
          }

          // Show events list when data is available
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
          Text(
            'Loading events...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorState(String errorMessage, EventsViewModel viewModel) {
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
              onPressed: () => viewModel.fetchEvents(),
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
  Widget _buildEventsList(EventsViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.refreshEvents(),
      child: Column(
        children: [
          // Events count header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Text(
              '${viewModel.eventsCount} ${viewModel.eventsCount == 1 ? 'Event' : 'Events'} Available',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),

          // Events list
          Expanded(
            child: ListView.builder(
              itemCount: viewModel.events.length,
              padding: const EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                final event = viewModel.events[index];
                return EventCard(
                  event: event,
                  onTap: () {
                    // TODO: Navigate to event details screen
                    _showEventDetails(event.name);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show event details
  void _showEventDetails(String eventName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped on: $eventName'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}