import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../services/health_service.dart';
import '../services/services.dart';
import 'add_food_sheet.dart';
import 'settings_screen.dart';

class DayScreen extends StatefulWidget {
  const DayScreen({super.key, required this.database, required this.services});

  final AppDatabase database;
  final AppServices services;

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> with WidgetsBindingObserver {
  late DateTime _day = _today();

  /// Null when health data is off, unavailable or has nothing for the day.
  Future<EnergyBurned?> _burned = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshBurned();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Today's total keeps growing, so reread it when the app comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(_refreshBurned);
  }

  void _refreshBurned() {
    final day = _day;
    _burned = () async {
      try {
        if (!await widget.services.healthPrefs.readEnabled()) return null;
        final burned = await widget.services.health.energyBurned(day);
        if (burned.isEmpty) return null;
        if (burned.total != null || burned.active == null) return burned;
        // Health gave only exercise calories. Add what the body burns at
        // rest, if weight, height, age and sex are known.
        final body = await widget.services.health.bodyStats();
        final profile = await widget.services.healthPrefs.readProfile();
        final resting = restingKcal(
          weightKg: body.weightKg,
          heightCm: body.heightCm,
          age: profile.age,
          sex: profile.sex,
        );
        if (resting == null) return burned;
        return EnergyBurned(
          active: burned.active,
          total: burned.active! + resting,
          totalIsEstimate: true,
        );
      } catch (_) {
        // Health is a bonus; the food log must work without it.
        return null;
      }
    }();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isToday => _day == _today();

  void _setDay(DateTime day) => setState(() {
    _day = day;
    _refreshBurned();
  });

  void _shift(int days) =>
      _setDay(DateTime(_day.year, _day.month, _day.day + days));

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: _today(),
    );
    if (picked != null) {
      _setDay(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _openEditor([FoodEntry? existing]) async {
    final messenger = ScaffoldMessenger.of(context);
    final logged = await showModalBottomSheet<LoggedResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddFoodSheet(
        database: widget.database,
        services: widget.services,
        day: _day,
        existing: existing,
      ),
    );
    if (logged == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Logged ${logged.label}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => widget.database.deleteEntries(logged.ids),
          ),
        ),
      );
  }

  Future<void> _saveAsTemplate(MealType meal, List<FoodEntry> entries) async {
    final controller = TextEditingController(text: 'Usual ${meal.name}');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as meal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    await widget.database.saveTemplate(name, meal, entries);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Saved "${name.trim()}". Find it under Add food.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isToday ? 'Today' : DateFormat.MMMEd().format(_day);
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: _pickDay,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        leading: IconButton(
          tooltip: 'Previous day',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _shift(-1),
        ),
        actions: [
          IconButton(
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday ? null : () => _shift(1),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(services: widget.services),
                ),
              );
              if (mounted) setState(_refreshBurned);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<FoodEntry>>(
        stream: widget.database.watchDay(_day),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <FoodEntry>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final total = entries.fold<int>(0, (s, e) => s + (e.calories ?? 0));
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Nothing logged yet.')),
                )
              else
                ListTile(
                  title: const Text('Total calories'),
                  trailing: Text(
                    '$total kcal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              FutureBuilder<EnergyBurned?>(
                future: _burned,
                builder: (context, snap) {
                  final burned = snap.data;
                  if (burned == null) return const SizedBox.shrink();
                  return _BurnedTile(burned: burned, eaten: total);
                },
              ),
              const Divider(height: 1),
              for (final meal in MealType.values)
                ..._section(meal, entries.where((e) => e.mealType == meal)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add),
        label: const Text('Add food'),
      ),
    );
  }

  List<Widget> _section(MealType meal, Iterable<FoodEntry> entries) {
    if (entries.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                toBeginningOfSentenceCase(meal.name),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: 'Save ${meal.name} as a meal',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => _saveAsTemplate(meal, entries.toList()),
            ),
          ],
        ),
      ),
      for (final e in entries)
        Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete),
          ),
          onDismissed: (_) => widget.database.deleteEntry(e.id),
          child: ListTile(
            title: Text(e.name),
            subtitle: Text(_subtitle(e)),
            trailing: e.calories == null
                ? null
                : Text('${e.isEstimate ? '~' : ''}${e.calories} kcal'),
            onTap: () => _openEditor(e),
          ),
        ),
    ];
  }

  static String _subtitle(FoodEntry e) {
    final parts = [
      DateFormat.jm().format(e.loggedAt),
      if (e.portion != null && e.portion != Portion.normal)
        toBeginningOfSentenceCase(e.portion!.name),
      if (e.notes != null && e.notes!.isNotEmpty) e.notes!,
    ];
    return parts.join(' · ');
  }
}

/// Calories burned from Health, with what is left after the day's food.
class _BurnedTile extends StatelessWidget {
  const _BurnedTile({required this.burned, required this.eaten});

  final EnergyBurned burned;
  final int eaten;

  @override
  Widget build(BuildContext context) {
    final out = burned.total ?? burned.active!;
    final net = eaten - out;
    return ListTile(
      leading: const Icon(Icons.local_fire_department_outlined),
      title: const Text('Calories burned'),
      subtitle: Text(
        [
          if (burned.active != null) 'Active ${burned.active} kcal',
          'Net ${net > 0 ? '+' : ''}$net kcal',
        ].join(' · '),
      ),
      trailing: Text(
        '${burned.totalIsEstimate ? '~' : ''}$out kcal',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
