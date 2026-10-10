import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/health_service.dart';
import '../services/services.dart';
import '../services/user_prefs.dart';
import '../theme.dart';
import '../util/units.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import 'goals_screen.dart';

/// First-run setup: about you, a weight goal, Health, and a daily plan.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.database,
    required this.services,
  });

  final AppDatabase database;
  final AppServices services;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  bool _metric = true;
  Sex? _sex;
  final _age = TextEditingController();
  final _heightCm = TextEditingController();
  final _heightFt = TextEditingController();
  final _heightIn = TextEditingController();
  final _weight = TextEditingController();
  final _goalWeight = TextEditingController();
  WeightGoal _goal = WeightGoal.lose;
  double _pace = 0.25;
  int _kcal = 2000;
  String? _error;
  bool _healthBusy = false;
  String? _healthNote;

  static String get _healthName =>
      Platform.isIOS ? 'Apple Health' : 'Health Connect';

  UserPrefs get _unitPrefs => widget.services.prefs.value.copyWith(
    weightUnit: _metric ? WeightUnit.kg : WeightUnit.lb,
    heightUnit: _metric ? HeightUnit.cm : HeightUnit.ftIn,
  );

  Units get _units => Units(_unitPrefs);

  int? get _ageValue {
    final a = int.tryParse(_age.text.trim());
    return a != null && a >= 13 && a < 120 ? a : null;
  }

  double? get _heightValue {
    if (_metric) {
      final cm = double.tryParse(_heightCm.text.trim());
      return cm != null && cm > 80 && cm < 250 ? cm : null;
    }
    final ft = int.tryParse(_heightFt.text.trim());
    final inches = int.tryParse(_heightIn.text.trim()) ?? 0;
    if (ft == null) return null;
    final cm = (ft * 12 + inches) * 2.54;
    return cm > 80 && cm < 250 ? cm : null;
  }

  double? get _weightValue {
    final kg = _units.parseWeight(_weight.text);
    return kg != null && kg > 25 && kg < 400 ? kg : null;
  }

  double? get _goalWeightValue => _units.parseWeight(_goalWeight.text);

  @override
  void dispose() {
    for (final c in [
      _age,
      _heightCm,
      _heightFt,
      _heightIn,
      _weight,
      _goalWeight,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == 1 &&
        (_sex == null ||
            _ageValue == null ||
            _heightValue == null ||
            _weightValue == null)) {
      setState(() => _error = 'Fill in all four so the plan fits you.');
      return;
    }
    if (_step == 3) {
      _kcal = suggestCalories(
        weightKg: _weightValue!,
        heightCm: _heightValue!,
        age: _ageValue!,
        sex: _sex!,
        goal: _goal,
        paceKgPerWeek: _pace,
      );
    }
    setState(() {
      _error = null;
      _step++;
    });
  }

  void _back() => setState(() {
    _error = null;
    _step--;
  });

  Future<void> _skip() =>
      widget.services.prefs.update((v) => v.copyWith(onboarded: true));

  Future<void> _connectHealth() async {
    setState(() {
      _healthBusy = true;
      _healthNote = null;
    });
    final health = widget.services.health;
    final ok = await health.isAvailable() && await health.requestAccess();
    if (ok) await widget.services.healthPrefs.writeEnabled(true);
    if (!mounted) return;
    setState(() {
      _healthBusy = false;
      if (!ok) {
        _healthNote =
            '$_healthName is not available, or access was not given. You '
            'can connect it later in Settings.';
      }
    });
    if (ok) _next();
  }

  Future<void> _finish() async {
    final macros = macrosFor(_kcal);
    final weight = _weightValue!;
    await widget.services.healthPrefs.writeProfile(
      BodyProfile(age: _ageValue, sex: _sex),
    );
    await widget.database.addWeight(weight, DateTime.now());
    await widget.services.prefs.update(
      (v) => _unitPrefs.copyWith(
        onboarded: true,
        calorieGoal: _kcal,
        proteinGoal: macros.protein,
        carbsGoal: macros.carbs,
        fatGoal: macros.fat,
        goal: _goal,
        goalWeightKg: _goal == WeightGoal.maintain ? null : _goalWeightValue,
        clearGoalWeight: _goal == WeightGoal.maintain,
        paceKgPerWeek: _pace,
        heightCm: _heightValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) return _welcome(context);
    final p = context.palette;
    final (title, subtitle, body, action) = switch (_step) {
      1 => (
        'About you',
        'This is used to estimate how much energy your body needs each day.',
        _about(),
        FilledButton(onPressed: _next, child: const Text('Continue')),
      ),
      2 => (
        'What’s your goal?',
        'You can change this later in Settings.',
        _goalStep(),
        FilledButton(onPressed: _next, child: const Text('Continue')),
      ),
      3 => (
        'Count your activity',
        'Connect $_healthName so calories you burn are added to your daily '
            'budget.',
        _healthStep(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _healthBusy ? null : _connectHealth,
              child: Text('Connect $_healthName'),
            ),
            TextButton(onPressed: _next, child: const Text('Not now')),
          ],
        ),
      ),
      _ => (
        'Your daily plan',
        'A starting point. Adjust anything that doesn’t feel right.',
        _planStep(),
        FilledButton(onPressed: _finish, child: const Text('Start tracking')),
      ),
    };
    return Scaffold(
      body: SafeArea(
        child: MaxWidth(
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        label: 'Step $_step of 4',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: _step / 4,
                            minHeight: 6,
                            color: p.accent,
                            backgroundColor: p.line,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(color: p.muted, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    body,
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: action,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context) {
    final p = context.palette;
    Widget point(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.onHero.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: p.heroAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.onHero,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(text, style: TextStyle(color: p.onHeroMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: p.hero,
      body: SafeArea(
        child: MaxWidth(
          maxWidth: 560,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: p.heroAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.eco, color: p.hero, size: 34),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'BASIC HEALTH TRACKER',
                        style: TextStyle(
                          color: p.heroAccent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Eat well, without the busywork.',
                        style: TextStyle(
                          color: p.onHero,
                          fontSize: 36,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Keep track of calories, macros and weight so you can '
                        'focus on the food.',
                        style: TextStyle(
                          color: p.onHeroMuted,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      point(
                        Icons.auto_awesome,
                        'Just describe your meal',
                        'AI works out the calories and macros for you.',
                      ),
                      point(
                        Icons.history,
                        'One tap for the usual',
                        'Foods you log are saved, so repeats take a second.',
                      ),
                      point(
                        Icons.local_fire_department_outlined,
                        'Activity counts',
                        'Calories burned sync from Apple Health or Health '
                            'Connect.',
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.heroAccent,
                    foregroundColor: p.hero,
                    minimumSize: const Size(48, 56),
                  ),
                  onPressed: () => setState(() => _step = 1),
                  child: const Text('Get started'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: p.onHeroMuted),
                  onPressed: _skip,
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _about() {
    void unfocus(PointerDownEvent _) =>
        FocusManager.instance.primaryFocus?.unfocus();
    final number = const TextInputType.numberWithOptions(decimal: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Metric')),
            ButtonSegment(value: false, label: Text('Imperial')),
          ],
          selected: {_metric},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _metric = s.first),
        ),
        const SizedBox(height: 16),
        SectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<Sex>(
                emptySelectionAllowed: true,
                segments: const [
                  ButtonSegment(value: Sex.female, label: Text('Female')),
                  ButtonSegment(value: Sex.male, label: Text('Male')),
                ],
                selected: {?_sex},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _sex = s.firstOrNull),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _age,
                onTapOutside: unfocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              const SizedBox(height: 12),
              if (_metric)
                TextField(
                  controller: _heightCm,
                  onTapOutside: unfocus,
                  keyboardType: number,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    suffixText: 'cm',
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightFt,
                        onTapOutside: unfocus,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          suffixText: 'ft',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _heightIn,
                        onTapOutside: unfocus,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '',
                          suffixText: 'in',
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _weight,
                onTapOutside: unfocus,
                keyboardType: number,
                decoration: InputDecoration(
                  labelText: 'Current weight',
                  suffixText: _units.weightLabel,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sex is used only for the calorie formula.',
          style: TextStyle(fontSize: 12, color: context.palette.muted),
        ),
      ],
    );
  }

  Widget _goalStep() {
    final p = context.palette;
    const labels = {
      WeightGoal.lose: ('Lose weight', 'Eat a little under what you burn'),
      WeightGoal.maintain: ('Maintain', 'Stay steady and eat balanced'),
      WeightGoal.gain: ('Gain weight', 'Build up with a small surplus'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioGroup<WeightGoal>(
          groupValue: _goal,
          onChanged: (g) => setState(() => _goal = g ?? _goal),
          child: Column(
            children: [
              for (final e in labels.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: _goal == e.key ? p.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: RadioListTile<WeightGoal>(
                      value: e.key,
                      controlAffinity: ListTileControlAffinity.trailing,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: Text(
                        e.value.$1,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(e.value.$2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_goal != WeightGoal.maintain) ...[
          const SizedBox(height: 8),
          SectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _goalWeight,
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Goal weight (optional)',
                    suffixText: _units.weightLabel,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Pace', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                PacePicker(
                  units: _units,
                  value: _pace,
                  onChanged: (v) => setState(() => _pace = v),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _healthStep() {
    final p = context.palette;
    Widget row(IconData icon, Color color, String title, String note) =>
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Text(note, style: TextStyle(color: p.muted, fontSize: 12)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: p.burnSoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(Icons.monitor_heart_outlined, color: p.burn, size: 48),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  'WE WILL READ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: p.muted,
                  ),
                ),
              ),
              row(
                Icons.local_fire_department_outlined,
                p.burn,
                'Calories burned',
                'active and resting',
              ),
              const Divider(indent: 16, endIndent: 16),
              row(
                Icons.monitor_weight_outlined,
                p.accent,
                'Weight and height',
                'from smart scales',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Read only. Nothing is written to Health and nothing leaves your '
          'phone.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: p.muted),
        ),
        if (_healthNote != null) ...[
          const SizedBox(height: 12),
          Text(
            _healthNote!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _planStep() {
    final p = context.palette;
    final units = _units;
    final m = macrosFor(_kcal);
    final goalWeight = _goalWeightValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalorieStepper(
          units: units,
          kcal: _kcal,
          onChanged: (k) => setState(() => _kcal = k.clamp(1000, 6000)),
          footnote: '+ calories you burn, from Health',
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardHeader('Macros'),
              const SizedBox(height: 12),
              for (final (label, grams, color) in [
                ('Protein', m.protein, p.protein),
                ('Carbs', m.carbs, p.carbs),
                ('Fat', m.fat, p.fat),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Dot(color),
                  minLeadingWidth: 10,
                  title: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    '$grams g',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
        if (_goal != WeightGoal.maintain && goalWeight != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Goal: ${units.weight(_weightValue!)} to '
              '${units.weight(goalWeight)}, about '
              '${((goalWeight - _weightValue!).abs() / _pace).ceil()} weeks '
              'at this pace.',
              style: TextStyle(color: p.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}
