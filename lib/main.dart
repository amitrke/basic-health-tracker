import 'package:flutter/material.dart';

import 'data/database.dart';
import 'screens/log_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/today_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/weight_screen.dart';
import 'services/services.dart';
import 'sync/sync_controller.dart';
import 'theme.dart';
import 'widgets/responsive.dart';

void main() {
  final database = AppDatabase();
  runApp(
    BasicHealthTrackerApp(
      database: database,
      services: AppServices(sync: SyncController.forPlatform(database)),
    ),
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

class _BasicHealthTrackerAppState extends State<BasicHealthTrackerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.services.prefs.load();
    widget.services.sync?.load();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pick up what the other device logged while this one was in a pocket.
    if (state == AppLifecycleState.resumed) widget.services.sync?.syncNow();
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

  static const _tabs = [
    (Icons.home_outlined, Icons.home, 'Today'),
    (Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Log'),
    (Icons.monitor_weight_outlined, Icons.monitor_weight, 'Weight'),
    (Icons.insights_outlined, Icons.insights, 'Trends'),
  ];

  @override
  Widget build(BuildContext context) {
    final db = widget.database;
    final services = widget.services;
    // Only the open tab is built, so each one reads fresh data on return.
    final body = switch (_tab) {
      0 => TodayScreen(database: db, services: services, onOpenTab: _open),
      1 => LogScreen(database: db, services: services),
      2 => WeightScreen(database: db, services: services),
      _ => TrendsScreen(database: db, services: services),
    };
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.rail;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: _tab,
                onDestinationSelected: _open,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.9,
                destinations: [
                  for (final (icon, selected, label) in _tabs)
                    NavigationRailDestination(
                      icon: Icon(icon),
                      selectedIcon: Icon(selected),
                      label: Text(label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _open,
        destinations: [
          for (final (icon, selected, label) in _tabs)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
