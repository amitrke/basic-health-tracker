import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/calories.dart';
import '../data/database.dart';
import '../services/energy.dart';
import '../services/health_service.dart';
import '../services/services.dart';
import '../services/user_prefs.dart';
import '../theme.dart';
import '../util/units.dart';
import '../widgets/common.dart';
import 'food_editor.dart';
import 'settings_screen.dart';

/// The home tab: calories left, macros, weight and today's meals at a glance.
class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.database,
    required this.services,
    required this.onOpenTab,
  });

  final AppDatabase database;
  final AppServices services;

  /// Switches the bottom navigation to another tab.
  final ValueChanged<int> onOpenTab;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  late Future<EnergyBurned?> _burned;
  late Future<List<WeightReading>> _healthWeights;
  late final Stream<List<FoodEntry>> _entries;
  late final Stream<List<WeightEntry>> _weights;
  final DateTime _day = today();

  DateTime get _monthAgo => _day.subtract(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entries = widget.database.watchDay(_day);
    _weights = widget.database.watchWeights(from: _monthAgo);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Today's burn keeps growing, so reread it when the app comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(_refresh);
  }

  void _refresh() {
    _burned = loadBurned(widget.services, _day);
    _healthWeights = healthWeights(widget.services, _monthAgo);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(services: widget.services),
      ),
    );
    if (mounted) setState(_refresh);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.services.prefs,
          builder: (context, _) {
            final prefs = widget.services.prefs.value;
            final units = Units(prefs);
            return StreamBuilder<List<FoodEntry>>(
              stream: _entries,
              builder: (context, snapshot) {
                final entries = snapshot.data ?? const <FoodEntry>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMM d')
                                    .format(_day)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: p.muted,
                                ),
                              ),
                              Text(
                                _greeting,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Settings',
                          onPressed: _openSettings,
                          style: IconButton.styleFrom(
                            backgroundColor: p.accentSoft,
                            foregroundColor: p.accent,
                            minimumSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.person_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<EnergyBurned?>(
                      future: _burned,
                      builder: (context, snap) => _CaloriesCard(
                        prefs: prefs,
                        units: units,
                        entries: entries,
                        burned: snap.data,
                        onViewLog: () => widget.onOpenTab(1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MacrosCard(prefs: prefs, entries: entries),
                    const SizedBox(height: 12),
                    _MealsCard(
                      units: units,
                      entries: entries,
                      onOpenLog: () => widget.onOpenTab(1),
                      onAdd: () => openFoodEditor(
                        context,
                        database: widget.database,
                        services: widget.services,
                        day: _day,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<WeightEntry>>(
                      stream: _weights,
                      builder: (context, app) =>
                          FutureBuilder<List<WeightReading>>(
                            future: _healthWeights,
                            builder: (context, health) => _WeightCard(
                              units: units,
                              readings: mergeWeights(
                                app.data ?? const [],
                                health.data ?? const [],
                              ),
                              onTap: () => widget.onOpenTab(2),
                            ),
                          ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-food-today',
        onPressed: () => openFoodEditor(
          context,
          database: widget.database,
          services: widget.services,
          day: _day,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add food'),
      ),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({
    required this.prefs,
    required this.units,
    required this.entries,
    required this.burned,
    required this.onViewLog,
  });

  final UserPrefs prefs;
  final Units units;
  final List<FoodEntry> entries;
  final EnergyBurned? burned;
  final VoidCallback onViewLog;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final eaten = entries.fold<int>(0, (s, e) => s + (e.calories ?? 0));
    final exercise = prefs.addActiveToBudget ? burned?.active : null;
    final budget = prefs.calorieGoal + (exercise ?? 0);
    final left = budget - eaten;
    final b = burned;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            'Calories',
            trailing: TextButton(
              onPressed: onViewLog,
              child: const Text('View log'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CalorieRing(
                progress: budget <= 0 ? 0 : eaten / budget,
                value: units.energyNumber(left.abs()),
                caption: '${units.energyLabel} ${left >= 0 ? 'left' : 'over'}',
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stat(
                      label: 'Daily goal',
                      value: units.energyNumber(prefs.calorieGoal),
                    ),
                    const SizedBox(height: 10),
                    Stat(label: 'Eaten', value: units.energyNumber(eaten)),
                    if (exercise != null) ...[
                      const SizedBox(height: 10),
                      Stat(
                        label: 'Exercise',
                        value: '+${units.energyNumber(exercise)}',
                        color: p.burn,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (b != null) ...[
            const SizedBox(height: 12),
            _BurnedRow(burned: b, eaten: eaten, units: units),
          ],
        ],
      ),
    );
  }
}

/// Calories burned from Health, with the net after the day's food.
class _BurnedRow extends StatelessWidget {
  const _BurnedRow({
    required this.burned,
    required this.eaten,
    required this.units,
  });

  final EnergyBurned burned;
  final int eaten;
  final Units units;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final out = burned.total ?? burned.active!;
    final net = eaten - out;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.ground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_outlined, color: p.burn),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calories burned',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  [
                    if (burned.active != null)
                      'Active ${units.energy(burned.active!)}',
                    'Net ${units.energySigned(net)}',
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
              ],
            ),
          ),
          Text(
            units.energy(out, estimate: burned.totalIsEstimate),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MacrosCard extends StatelessWidget {
  const _MacrosCard({required this.prefs, required this.entries});

  final UserPrefs prefs;
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = Macros.total(entries);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader('Macros'),
          const SizedBox(height: 14),
          MacroBar(
            label: 'Protein',
            value: m.protein ?? 0,
            goal: prefs.proteinGoal,
            color: p.protein,
            track: p.proteinSoft,
          ),
          const SizedBox(height: 14),
          MacroBar(
            label: 'Carbs',
            value: m.carbs ?? 0,
            goal: prefs.carbsGoal,
            color: p.carbs,
            track: p.carbsSoft,
          ),
          const SizedBox(height: 14),
          MacroBar(
            label: 'Fat',
            value: m.fat ?? 0,
            goal: prefs.fatGoal,
            color: p.fat,
            track: p.fatSoft,
          ),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.units,
    required this.readings,
    required this.onTap,
  });

  final Units units;
  final List<WeightReading> readings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (readings.isEmpty) {
      return SectionCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.monitor_weight_outlined, color: p.accent),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Log your weight to see your trend',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right, color: p.muted),
          ],
        ),
      );
    }
    final latest = readings.last;
    final change = latest.kg - readings.first.kg;
    final days = latest.at.difference(readings.first.at).inDays;
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardHeader('Weight'),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: units.weightNumber(latest.kg),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' ${units.weightLabel}',
                        style: TextStyle(
                          color: p.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (readings.length > 1)
                  Text(
                    '${units.weightChange(change)} in $days '
                    '${days == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.accent,
                    ),
                  ),
              ],
            ),
          ),
          if (readings.length > 1)
            Sparkline(values: [for (final r in readings) r.kg]),
        ],
      ),
    );
  }
}

class _MealsCard extends StatelessWidget {
  const _MealsCard({
    required this.units,
    required this.entries,
    required this.onOpenLog,
    required this.onAdd,
  });

  final Units units;
  final List<FoodEntry> entries;
  final VoidCallback onOpenLog;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader('Meals'),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                'Nothing logged yet.',
                style: TextStyle(color: p.muted),
              ),
            ),
          for (final meal in MealType.values)
            Builder(
              builder: (context) {
                final items = entries.where((e) => e.mealType == meal);
                final kcal = items.fold<int>(
                  0,
                  (s, e) => s + (e.calories ?? 0),
                );
                final name =
                    meal.name[0].toUpperCase() + meal.name.substring(1);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    items.isEmpty
                        ? 'Nothing yet'
                        : items.map((e) => e.name).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: items.isEmpty
                      ? TextButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        )
                      : Text(
                          units.energy(
                            kcal,
                            estimate: items.any((e) => e.isEstimate),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                  onTap: items.isEmpty ? onAdd : onOpenLog,
                );
              },
            ),
        ],
      ),
    );
  }
}
