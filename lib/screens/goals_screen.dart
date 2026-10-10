import 'package:flutter/material.dart';

import '../services/services.dart';
import '../services/user_prefs.dart';
import '../theme.dart';
import '../util/units.dart';
import '../widgets/common.dart';

/// Edit the daily calorie budget, macro goals and weight goal. Every change
/// saves straight away.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final UserPrefs _start = widget.services.prefs.value;
  late final _protein = TextEditingController(text: '${_start.proteinGoal}');
  late final _carbs = TextEditingController(text: '${_start.carbsGoal}');
  late final _fat = TextEditingController(text: '${_start.fatGoal}');
  late final _goalWeight = TextEditingController(
    text: _start.goalWeightKg == null
        ? ''
        : Units(_start).weightNumber(_start.goalWeightKg!),
  );

  PrefsController get _prefs => widget.services.prefs;

  @override
  void dispose() {
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _goalWeight.dispose();
    super.dispose();
  }

  void _setCalories(int kcal) {
    _prefs.update((v) => v.copyWith(calorieGoal: kcal.clamp(1000, 6000)));
  }

  void _matchMacros() {
    final m = macrosFor(_prefs.value.calorieGoal);
    _protein.text = '${m.protein}';
    _carbs.text = '${m.carbs}';
    _fat.text = '${m.fat}';
    _prefs.update(
      (v) => v.copyWith(
        proteinGoal: m.protein,
        carbsGoal: m.carbs,
        fatGoal: m.fat,
      ),
    );
  }

  void _saveMacro(String text, UserPrefs Function(UserPrefs, int) apply) {
    final n = int.tryParse(text.trim());
    if (n == null || n < 0 || n > 1000) return;
    _prefs.update((v) => apply(v, n));
  }

  void _saveGoalWeight(String text) {
    final units = Units(_prefs.value);
    final kg = units.parseWeight(text);
    _prefs.update(
      (v) => kg == null
          ? v.copyWith(clearGoalWeight: true)
          : v.copyWith(goalWeightKg: kg),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _prefs,
      builder: (context, _) => _build(context, _prefs.value),
    );
  }

  Widget _build(BuildContext context, UserPrefs prefs) {
    final theme = Theme.of(context);
    final p = context.palette;
    final units = Units(prefs);
    void unfocus(PointerDownEvent _) =>
        FocusManager.instance.primaryFocus?.unfocus();
    final macroKcal =
        prefs.proteinGoal * 4 + prefs.carbsGoal * 4 + prefs.fatGoal * 9;
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          CalorieStepper(
            units: units,
            kcal: prefs.calorieGoal,
            onChanged: _setCalories,
            footnote: prefs.addActiveToBudget
                ? 'Plus exercise calories from Health, when connected'
                : 'Exercise is not added to the budget',
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardHeader(
                  'Macros',
                  trailing: TextButton(
                    onPressed: _matchMacros,
                    child: const Text('Match calories'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final (label, controller, color, apply) in [
                      (
                        'Protein',
                        _protein,
                        p.protein,
                        (UserPrefs v, int n) => v.copyWith(proteinGoal: n),
                      ),
                      (
                        'Carbs',
                        _carbs,
                        p.carbs,
                        (UserPrefs v, int n) => v.copyWith(carbsGoal: n),
                      ),
                      (
                        'Fat',
                        _fat,
                        p.fat,
                        (UserPrefs v, int n) => v.copyWith(fatGoal: n),
                      ),
                    ]) ...[
                      if (label != 'Protein') const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onTapOutside: unfocus,
                          keyboardType: TextInputType.number,
                          onChanged: (t) => _saveMacro(t, apply),
                          decoration: InputDecoration(
                            labelText: label,
                            suffixText: 'g',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Dot(color),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'These macros add up to ${units.energy(macroKcal)}.',
                  style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CardHeader('Weight goal'),
                const SizedBox(height: 12),
                SegmentedButton<WeightGoal>(
                  segments: const [
                    ButtonSegment(value: WeightGoal.lose, label: Text('Lose')),
                    ButtonSegment(
                      value: WeightGoal.maintain,
                      label: Text('Maintain'),
                    ),
                    ButtonSegment(value: WeightGoal.gain, label: Text('Gain')),
                  ],
                  selected: {prefs.goal},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      _prefs.update((v) => v.copyWith(goal: s.first)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _goalWeight,
                  onTapOutside: unfocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: _saveGoalWeight,
                  decoration: InputDecoration(
                    labelText: 'Goal weight (optional)',
                    suffixText: units.weightLabel,
                  ),
                ),
                if (prefs.goal != WeightGoal.maintain) ...[
                  const SizedBox(height: 12),
                  Text('Pace', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  PacePicker(
                    units: units,
                    value: prefs.paceKgPerWeek,
                    onChanged: (pace) =>
                        _prefs.update((v) => v.copyWith(paceKgPerWeek: pace)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Relaxed, steady or faster weekly change.
class PacePicker extends StatelessWidget {
  const PacePicker({
    super.key,
    required this.units,
    required this.value,
    required this.onChanged,
  });

  static final paces = {0.25: 'Relaxed', 0.5: 'Steady', 0.75: 'Faster'};

  final Units units;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<double>(
      segments: [
        for (final e in paces.entries)
          ButtonSegment(
            value: e.key,
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.value),
                Text(
                  '${units.weightNumber(e.key)} ${units.weightLabel}/wk',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
      selected: {paces.containsKey(value) ? value : 0.25},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// The dark budget card with − and + buttons, in steps of 50 kcal.
class CalorieStepper extends StatelessWidget {
  const CalorieStepper({
    super.key,
    required this.units,
    required this.kcal,
    required this.onChanged,
    required this.footnote,
  });

  final Units units;
  final int kcal;
  final ValueChanged<int> onChanged;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SectionCard(
      color: p.hero,
      child: Column(
        children: [
          Text(
            'Daily calorie budget',
            style: TextStyle(color: p.onHeroMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _RoundButton(
                icon: Icons.remove,
                tooltip: 'Decrease by 50 kcal',
                onPressed: () => onChanged(kcal - 50),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: units.energyNumber(kcal),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' ${units.energyLabel}',
                        style: TextStyle(color: p.onHeroMuted),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.onHero),
                ),
              ),
              _RoundButton(
                icon: Icons.add,
                tooltip: 'Increase by 50 kcal',
                onPressed: () => onChanged(kcal + 50),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            footnote,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.heroAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: p.onHero.withValues(alpha: 0.12),
        foregroundColor: p.onHero,
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }
}
