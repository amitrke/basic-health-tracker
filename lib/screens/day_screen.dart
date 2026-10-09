import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
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

class _DayScreenState extends State<DayScreen> {
  late DateTime _day = _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isToday => _day == _today();

  void _shift(int days) =>
      setState(() => _day = DateTime(_day.year, _day.month, _day.day + days));

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: _today(),
    );
    if (picked != null) {
      setState(() => _day = DateTime(picked.year, picked.month, picked.day));
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(services: widget.services),
              ),
            ),
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
          if (entries.isEmpty) {
            return const Center(child: Text('Nothing logged yet.'));
          }
          final total = entries.fold<int>(0, (s, e) => s + (e.calories ?? 0));
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              ListTile(
                title: const Text('Total calories'),
                trailing: Text(
                  '$total kcal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
