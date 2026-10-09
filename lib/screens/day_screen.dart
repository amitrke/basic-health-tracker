import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';

class DayScreen extends StatefulWidget {
  const DayScreen({super.key, required this.database});

  final AppDatabase database;

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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EntryEditor(
        database: widget.database,
        day: _day,
        existing: existing,
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          toBeginningOfSentenceCase(meal.name),
          style: Theme.of(context).textTheme.titleSmall,
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
            subtitle: e.notes == null || e.notes!.isEmpty
                ? Text(DateFormat.jm().format(e.loggedAt))
                : Text('${DateFormat.jm().format(e.loggedAt)} · ${e.notes}'),
            trailing: e.calories == null ? null : Text('${e.calories} kcal'),
            onTap: () => _openEditor(e),
          ),
        ),
    ];
  }
}

class _EntryEditor extends StatefulWidget {
  const _EntryEditor({
    required this.database,
    required this.day,
    this.existing,
  });

  final AppDatabase database;
  final DateTime day;
  final FoodEntry? existing;

  @override
  State<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<_EntryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _calories = TextEditingController(
    text: widget.existing?.calories?.toString(),
  );
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late MealType _meal = widget.existing?.mealType ?? _guessMeal();

  static MealType _guessMeal() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 15) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final calories = int.tryParse(_calories.text.trim());
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final existing = widget.existing;
    if (existing == null) {
      final now = DateTime.now();
      // Keep the time of day for today; for past days log at noon.
      final isToday = DateUtils.isSameDay(widget.day, now);
      final at = isToday
          ? now
          : DateTime(widget.day.year, widget.day.month, widget.day.day, 12);
      await widget.database.addEntry(
        FoodEntriesCompanion.insert(
          name: _name.text.trim(),
          mealType: _meal,
          loggedAt: at,
          calories: Value(calories),
          notes: Value(notes),
        ),
      );
    } else {
      await widget.database.updateEntry(
        existing.copyWith(
          name: _name.text.trim(),
          mealType: _meal,
          calories: Value(calories),
          notes: Value(notes),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What did you eat?'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a food' : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<MealType>(
              segments: [
                for (final m in MealType.values)
                  ButtonSegment(
                    value: m,
                    label: Text(toBeginningOfSentenceCase(m.name)),
                  ),
              ],
              selected: {_meal},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _meal = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _calories,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories (optional)',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                return (n == null || n < 0 || n > 20000)
                    ? 'Enter a valid number'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
