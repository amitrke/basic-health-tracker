import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../services/energy.dart';
import '../services/health_service.dart';
import '../services/services.dart';
import '../services/user_prefs.dart';
import '../theme.dart';
import '../util/units.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

enum _Range {
  week('1W', 7),
  month('1M', 30),
  quarter('3M', 91),
  year('1Y', 365);

  const _Range(this.label, this.days);

  final String label;
  final int days;
}

/// Weight over time, progress toward the goal, and every weigh-in.
class WeightScreen extends StatefulWidget {
  const WeightScreen({
    super.key,
    required this.database,
    required this.services,
  });

  final AppDatabase database;
  final AppServices services;

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  _Range _range = _Range.month;
  late final Stream<List<WeightEntry>> _app = widget.database.watchWeights();
  late Future<List<WeightReading>> _health;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  void _loadHealth() {
    _health = healthWeights(
      widget.services,
      DateTime.now().subtract(const Duration(days: 366)),
    );
  }

  Future<void> _logWeight(Units units) async {
    final kg = await showDialog<double>(
      context: context,
      builder: (_) => _LogWeightDialog(units: units),
    );
    if (kg != null) await widget.database.addWeight(kg, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.services.prefs,
      builder: (context, _) {
        final prefs = widget.services.prefs.value;
        final units = Units(prefs);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Weight'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 44),
                  ),
                  onPressed: () => _logWeight(units),
                  icon: const Icon(Icons.add),
                  label: const Text('Log weight'),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(_loadHealth);
              await _health;
            },
            child: StreamBuilder<List<WeightEntry>>(
              stream: _app,
              builder: (context, app) => FutureBuilder<List<WeightReading>>(
                future: _health,
                builder: (context, health) => _body(
                  prefs,
                  units,
                  mergeWeights(app.data ?? const [], health.data ?? const []),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(UserPrefs prefs, Units units, List<WeightReading> all) {
    final p = context.palette;
    if (all.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Icon(Icons.monitor_weight_outlined, size: 48, color: p.muted),
          const SizedBox(height: 12),
          Text(
            'No weigh-ins yet. Tap Log weight, or connect Health in Settings '
            'to bring in readings from a smart scale.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted),
          ),
        ],
      );
    }
    final from = DateTime.now().subtract(Duration(days: _range.days));
    final inRange = all.where((r) => r.at.isAfter(from)).toList();
    final latest = all.last;
    final shown = inRange.length >= 2 ? inRange : const <WeightReading>[];
    return CenteredListView(
      top: 4,
      bottom: 32,
      children: [
        SectionCard(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current · ${DateFormat.MMMd().format(latest.at)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.muted,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: units.weightNumber(latest.kg),
                                style: const TextStyle(
                                  fontSize: 36,
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
                      ],
                    ),
                  ),
                  if (shown.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: p.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        units.weightChange(shown.last.kg - shown.first.kg),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p.accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<_Range>(
                segments: [
                  for (final r in _Range.values)
                    ButtonSegment(value: r, label: Text(r.label)),
                ],
                selected: {_range},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _range = s.first),
              ),
              const SizedBox(height: 16),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Log at least two weigh-ins in this range to see a chart.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.muted),
                  ),
                )
              else
                Semantics(
                  label:
                      'Weight from ${units.weight(shown.first.kg)} to '
                      '${units.weight(shown.last.kg)}',
                  excludeSemantics: true,
                  child: TrendChart(
                    values: [for (final r in shown) units.weightValue(r.kg)],
                    startLabel: DateFormat.MMMd().format(shown.first.at),
                    endLabel: DateFormat.MMMd().format(shown.last.at),
                    formatY: (v) => v.toStringAsFixed(1),
                  ),
                ),
            ],
          ),
        ),
        if (prefs.goalWeightKg != null) ...[
          const SizedBox(height: 12),
          _GoalCard(
            units: units,
            start: all.first.kg,
            current: latest.kg,
            goal: prefs.goalWeightKg!,
          ),
        ],
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: CardHeader('History'),
              ),
              for (final (i, r) in all.reversed.take(30).indexed) ...[
                if (i > 0) const Divider(indent: 20, endIndent: 20),
                _historyTile(units, r, all),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _historyTile(Units units, WeightReading r, List<WeightReading> all) {
    final p = context.palette;
    final index = all.indexOf(r);
    final previous = index > 0 ? all[index - 1] : null;
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        DateFormat.MMMEd().format(r.at),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${DateFormat.jm().format(r.at)}${r.fromHealth ? ' · from Health' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (previous != null)
            Text(
              units.weightChange(r.kg - previous.kg),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.muted,
              ),
            ),
          const SizedBox(width: 12),
          Text(
            units.weight(r.kg),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    final id = r.id;
    if (id == null) return tile;
    return Dismissible(
      key: ValueKey('weight-$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete),
      ),
      onDismissed: (_) => widget.database.deleteWeight(id),
      child: tile,
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.units,
    required this.start,
    required this.current,
    required this.goal,
  });

  final Units units;
  final double start;
  final double current;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = (goal - start).abs();
    final done = total == 0
        ? 1.0
        : ((current - start) / (goal - start)).clamp(0.0, 1.0);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            'Goal',
            trailing: Text(
              '${(done * 100).round()}% of the way',
              style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: done,
              minHeight: 10,
              color: p.accent,
              backgroundColor: p.line,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Stat(label: 'Start', value: units.weight(start)),
              ),
              Expanded(
                child: Stat(label: 'Goal', value: units.weight(goal)),
              ),
              Expanded(
                child: Stat(
                  label: 'To go',
                  value: units.weight((goal - current).abs()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks for one weight in the chosen unit and pops it in kilograms. Owns its
/// controller so it outlives the closing animation.
class _LogWeightDialog extends StatefulWidget {
  const _LogWeightDialog({required this.units});

  final Units units;

  @override
  State<_LogWeightDialog> createState() => _LogWeightDialogState();
}

class _LogWeightDialogState extends State<_LogWeightDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final kg = widget.units.parseWeight(_controller.text);
    if (kg == null || kg > 500) {
      setState(() => _error = 'Enter your weight');
      return;
    }
    Navigator.pop(context, kg);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log weight'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Weight',
          suffixText: widget.units.weightLabel,
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
