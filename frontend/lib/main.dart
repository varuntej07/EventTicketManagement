import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ViewModels/events_vm.dart';
import 'ViewModels/tickets_vm.dart';
import 'Views/list_of_events.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EventsViewModel()),
        ChangeNotifierProvider(create: (context) => TicketsViewModel()),
      ],
      child: MaterialApp(
        title: 'Eventeny Ticketing Platform',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          useMaterial3: true,
        ),
        home: const EventsListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}