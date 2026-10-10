import 'package:flutter/material.dart';

import 'data/database.dart';
import 'screens/log_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/today_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/weight_screen.dart';
import 'services/services.dart';
import 'theme.dart';

void main() {
  runApp(
    BasicHealthTrackerApp(database: AppDatabase(), services: AppServices()),
  );
}

class BasicHealthTrackerApp extends StatefulWidget {
  const BasicHealthTrackerApp({
    super.key,
    required this.database,
    required this.services,
  });

  final AppDatabase database;
  final AppServices services;

  @override
  State<BasicHealthTrackerApp> createState() => _BasicHealthTrackerAppState();
}

class _BasicHealthTrackerAppState extends State<BasicHealthTrackerApp> {
  @override
  void initState() {
    super.initState();
    widget.services.prefs.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basic Health Tracker',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: ListenableBuilder(
        listenable: widget.services.prefs,
        builder: (context, _) {
          final prefs = widget.services.prefs;
          if (!prefs.loaded) return const Scaffold();
          if (!prefs.value.onboarded) {
            return OnboardingScreen(
              database: widget.database,
              services: widget.services,
            );
          }
          return HomeShell(
            database: widget.database,
            services: widget.services,
          );
        },
      ),
    );
  }
}

/// The four main tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.database, required this.services});

  final AppDatabase database;
  final AppServices services;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _open(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final db = widget.database;
    final services = widget.services;
    return Scaffold(
      // Only the open tab is built, so each one reads fresh data on return.
      body: switch (_tab) {
        0 => TodayScreen(database: db, services: services, onOpenTab: _open),
        1 => LogScreen(database: db, services: services),
        2 => WeightScreen(database: db, services: services),
        _ => TrendsScreen(database: db, services: services),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _open,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Weight',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Trends',
          ),
        ],
      ),
    );
  }
}
