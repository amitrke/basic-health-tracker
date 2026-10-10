import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/calories.dart';
import '../data/database.dart';
import '../services/services.dart';
import '../services/user_prefs.dart';
import '../theme.dart';
import '../util/units.dart';
import '../widgets/common.dart';
import 'food_editor.dart';

/// The last seven days: calories against the goal and the macro split.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({
    super.key,
    required this.database,
    required this.services,
  });

  final AppDatabase database;
  final AppServices services;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final DateTime _end = today();
  late final DateTime _start = _end.subtract(const Duration(days: 6));
  late final Stream<List<FoodEntry>> _entries = widget.database.watchRange(
    _start,
    _end,
  );

  /// The selected bar, as an index into the week. Today by default.
  int _selected = 6;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.services.prefs,
      builder: (context, _) {
        final prefs = widget.services.prefs.value;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Trends'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${DateFormat.MMMd().format(_start)} – '
                    '${DateFormat.MMMd().format(_end)}',
                    style: TextStyle(
                      color: context.palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: StreamBuilder<List<FoodEntry>>(
            stream: _entries,
            builder: (context, snapshot) =>
                _body(prefs, snapshot.data ?? const []),
          ),
        );
      },
    );
  }

  Widget _body(UserPrefs prefs, List<FoodEntry> entries) {
    final p = context.palette;
    final units = Units(prefs);
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(_start.year, _start.month, _start.day + i),
    ];
    final byDay = [
      for (final d in days)
        entries.where((e) => DateUtils.isSameDay(e.loggedAt, d)).toList(),
    ];
    final kcal = [
      for (final list in byDay)
        list.fold<int>(0, (s, e) => s + (e.calories ?? 0)),
    ];
    // Averages skip today, which is not over, and days with nothing logged.
    final complete = [
      for (var i = 0; i < 6; i++)
        if (byDay[i].isNotEmpty) i,
    ];
    final avg = complete.isEmpty
        ? null
        : complete.map((i) => kcal[i]).reduce((a, b) => a + b) /
              complete.length;
    final onTarget = complete
        .where(
          (i) => (kcal[i] - prefs.calorieGoal).abs() <= prefs.calorieGoal * 0.1,
        )
        .length;
    final macros = Macros.total([for (final i in complete) ...byDay[i]]);
    final n = complete.isEmpty ? 1 : complete.length;
    final avgP = (macros.protein ?? 0) / n;
    final avgC = (macros.carbs ?? 0) / n;
    final avgF = (macros.fat ?? 0) / n;
    final macroKcal = avgP * 4 + avgC * 4 + avgF * 9;

    final maxKcal =
        [
          ...kcal,
          prefs.calorieGoal,
        ].reduce((a, b) => a > b ? a : b).toDouble() *
        1.1;
    final sel = _selected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: SectionCard(
                padding: const EdgeInsets.all(16),
                child: Stat(
                  label: 'Avg calories',
                  value: avg == null ? '—' : units.energy(avg),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SectionCard(
                padding: const EdgeInsets.all(16),
                child: Stat(
                  label: 'Days on target',
                  value: complete.isEmpty
                      ? '—'
                      : '$onTarget of ${complete.length}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardHeader(
                'Calories',
                trailing: Text(
                  '${DateFormat.E().format(days[sel])} · '
                  '${units.energy(kcal[sel])}${sel == 6 ? ' so far' : ''}',
                  style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 190,
                child: LayoutBuilder(
                  builder: (context, box) {
                    const labelSpace = 22.0;
                    final barArea = box.maxHeight - labelSpace;
                    final goalY = barArea * prefs.calorieGoal / maxKcal;
                    return Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: labelSpace + goalY,
                          child: Container(height: 2, color: p.line),
                        ),
                        Positioned(
                          right: 0,
                          bottom: labelSpace + goalY + 4,
                          child: Text(
                            'Goal ${units.energyNumber(prefs.calorieGoal)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: p.muted,
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  selected: i == sel,
                                  label:
                                      '${DateFormat.EEEE().format(days[i])}, '
                                      '${units.energy(kcal[i])}',
                                  excludeSemantics: true,
                                  child: InkWell(
                                    onTap: () => setState(() => _selected = i),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            height: barArea * kcal[i] / maxKcal,
                                            decoration: BoxDecoration(
                                              color: i == sel
                                                  ? p.accent
                                                  : p.accent.withValues(
                                                      alpha: i == 6
                                                          ? 0.25
                                                          : 0.4,
                                                    ),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(8),
                                                    bottom: Radius.circular(4),
                                                  ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: labelSpace,
                                            child: Center(
                                              child: Text(
                                                DateFormat.E()
                                                    .format(days[i])
                                                    .substring(0, 1),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: i == sel
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: i == sel
                                                      ? p.ink
                                                      : p.muted,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardHeader(
                'Macro split',
                trailing: Text(
                  'daily average',
                  style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              if (macroKcal == 0)
                Text(
                  'Log foods with protein, carbs and fat to see your split. '
                  'AI estimates and barcode scans fill them in.',
                  style: TextStyle(color: p.muted),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        for (final (v, color) in [
                          (avgP * 4, p.protein),
                          (avgC * 4, p.carbs),
                          (avgF * 9, p.fat),
                        ])
                          if (v > 0)
                            Expanded(
                              flex: (v / macroKcal * 1000).round(),
                              child: Container(color: color),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final (label, grams, goal, kcalShare, color) in [
                  ('Protein', avgP, prefs.proteinGoal, avgP * 4, p.protein),
                  ('Carbs', avgC, prefs.carbsGoal, avgC * 4, p.carbs),
                  ('Fat', avgF, prefs.fatGoal, avgF * 9, p.fat),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Dot(color),
                    minLeadingWidth: 10,
                    title: Text(
                      '$label · ${(kcalShare / macroKcal * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${grams.round()} g',
                            style: TextStyle(
                              color: p.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: ' / $goal g goal'),
                        ],
                      ),
                      style: TextStyle(color: p.muted),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
