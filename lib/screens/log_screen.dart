import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/calories.dart';
import '../data/database.dart';
import '../services/services.dart';
import '../services/user_prefs.dart';
import '../theme.dart';
import '../util/units.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'food_editor.dart';

/// Everything eaten on one day, by meal. Any past day can be picked.
class LogScreen extends StatefulWidget {
  const LogScreen({super.key, required this.database, required this.services});

  final AppDatabase database;
  final AppServices services;

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  DateTime _day = today();

  bool get _isToday => _day == today();

  void _setDay(DateTime day) => setState(() => _day = day);

  void _shift(int days) =>
      _setDay(DateTime(_day.year, _day.month, _day.day + days));

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: today(),
    );
    if (picked != null) {
      _setDay(DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _edit([FoodEntry? existing]) => openFoodEditor(
    context,
    database: widget.database,
    services: widget.services,
    day: _day,
    existing: existing,
  );

  Future<void> _saveAsTemplate(MealType meal, List<FoodEntry> entries) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: 'Usual ${meal.name}'),
    );
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
    final p = context.palette;
    final title = _isToday ? 'Today' : DateFormat.MMMEd().format(_day);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: TextButton.icon(
          onPressed: _pickDay,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.expand_more),
          label: Text(title, style: Theme.of(context).textTheme.titleLarge),
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
      body: ListenableBuilder(
        listenable: widget.services.prefs,
        builder: (context, _) {
          final prefs = widget.services.prefs.value;
          final units = Units(prefs);
          return StreamBuilder<List<FoodEntry>>(
            stream: widget.database.watchDay(_day),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const <FoodEntry>[];
              if (snapshot.connectionState == ConnectionState.waiting &&
                  entries.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return CenteredListView(
                top: 4,
                bottom: 96,
                children: [
                  _WeekStrip(day: _day, onPick: _setDay),
                  const SizedBox(height: 12),
                  _Summary(prefs: prefs, units: units, entries: entries),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Nothing logged yet.',
                          style: TextStyle(color: p.muted),
                        ),
                      ),
                    ),
                  for (final meal in MealType.values)
                    ..._section(
                      units,
                      meal,
                      entries.where((e) => e.mealType == meal).toList(),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-food-log',
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('Add food'),
      ),
    );
  }

  List<Widget> _section(Units units, MealType meal, List<FoodEntry> entries) {
    if (entries.isEmpty) return const [];
    final p = context.palette;
    final kcal = entries.fold<int>(0, (s, e) => s + (e.calories ?? 0));
    return [
      const SizedBox(height: 12),
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      toBeginningOfSentenceCase(meal.name),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    units.energy(kcal),
                    style: TextStyle(
                      color: p.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Save ${meal.name} as a meal',
                    icon: const Icon(Icons.bookmark_add_outlined),
                    onPressed: () => _saveAsTemplate(meal, entries),
                  ),
                ],
              ),
            ),
            for (final e in entries) ...[
              const Divider(indent: 20, endIndent: 20),
              Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete),
                ),
                onDismissed: (_) => widget.database.deleteEntry(e.id),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(
                    e.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_subtitle(e)),
                      MacroLine(protein: e.protein, carbs: e.carbs, fat: e.fat),
                    ],
                  ),
                  trailing: e.calories == null
                      ? null
                      : Text(
                          units.energy(e.calories!, estimate: e.isEstimate),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                  onTap: () => _edit(e),
                ),
              ),
            ],
          ],
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

/// The seven days of [day]'s week, Sunday first. Future days are disabled.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.day, required this.onPick});

  final DateTime day;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final start = DateTime(day.year, day.month, day.day - day.weekday % 7);
    final now = today();
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Builder(
            builder: (context) {
              final d = DateTime(start.year, start.month, start.day + i);
              final selected = d == day;
              final future = d.isAfter(now);
              final fg = selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : (future ? p.muted.withValues(alpha: 0.4) : p.ink);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: Material(
                    color: selected ? p.accent : p.card,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: future ? null : () => onPick(d),
                      child: Semantics(
                        selected: selected,
                        label: DateFormat.MMMMEEEEd().format(d),
                        excludeSemantics: true,
                        child: SizedBox(
                          height: 60,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat.E().format(d).substring(0, 1),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: fg,
                                ),
                              ),
                              Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// The dark card: eaten against the goal, and the day's macros.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.prefs,
    required this.units,
    required this.entries,
  });

  final UserPrefs prefs;
  final Units units;
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final eaten = entries.fold<int>(0, (s, e) => s + (e.calories ?? 0));
    final left = prefs.calorieGoal - eaten;
    final m = Macros.total(entries);
    final muted = TextStyle(color: p.onHeroMuted, fontWeight: FontWeight.w600);
    final bold = TextStyle(color: p.onHero, fontWeight: FontWeight.w700);
    return SectionCard(
      color: p.hero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                units.energyNumber(eaten),
                style: TextStyle(
                  color: p.onHero,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '/ ${units.energy(prefs.calorieGoal)}',
                  style: muted,
                ),
              ),
              Text(
                left >= 0
                    ? '${units.energyNumber(left)} left'
                    : '${units.energyNumber(-left)} over',
                style: TextStyle(
                  color: p.heroAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prefs.calorieGoal <= 0
                  ? 0
                  : (eaten / prefs.calorieGoal).clamp(0.0, 1.0),
              minHeight: 8,
              color: p.heroAccent,
              backgroundColor: p.onHero.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (label, grams) in [
                ('Protein', m.protein),
                ('Carbs', m.carbs),
                ('Fat', m.fat),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: muted.copyWith(fontSize: 13)),
                      Text('${grams ?? 0} g', style: bold),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks for a meal name. Owns its controller so it outlives the closing
/// animation.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as meal'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
