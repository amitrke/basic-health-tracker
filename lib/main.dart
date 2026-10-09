import 'package:flutter/material.dart';

import 'data/database.dart';
import 'screens/day_screen.dart';
import 'services/services.dart';

void main() {
  runApp(
    BasicHealthTrackerApp(database: AppDatabase(), services: AppServices()),
  );
}

class BasicHealthTrackerApp extends StatelessWidget {
  const BasicHealthTrackerApp({
    super.key,
    required this.database,
    required this.services,
  });

  final AppDatabase database;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basic Health Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: DayScreen(database: database, services: services),
    );
  }
}
