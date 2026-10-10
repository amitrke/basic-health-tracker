import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/calories.dart';
import '../data/database.dart';
import '../services/ai_estimator.dart';
import '../services/services.dart';
import 'ai_estimate_sheet.dart';
import 'scan_screen.dart';

/// What a sheet logged, so the day screen can offer Undo.
class LoggedResult {
  const LoggedResult(this.label, this.ids);

  final String label;
  final List<int> ids;
}

/// Add a new food (pops a [LoggedResult]) or edit an existing entry.
///
/// New foods start with one-tap shortcuts (recent foods and saved meals);
/// everything else is a fallback for things not logged before: type, scan a
/// barcode, or ask the AI for an estimate.
class AddFoodSheet extends StatefulWidget {
  const AddFoodSheet({
    super.key,
    required this.database,
    required this.services,
    required this.day,
    this.existing,
  });

  final AppDatabase database;
  final AppServices services;
  final DateTime day;
  final FoodEntry? existing;

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _calories = TextEditingController(
    text: widget.existing?.calories?.toString(),
  );
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late MealType _meal = widget.existing?.mealType ?? _guessMeal();

  Portion? _portion;
  bool _estimated = false;
  String? _barcode;
  String? _portionLabel;
  List<SavedFood> _suggestions = const [];
  String? _message;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

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

  /// Keep the time of day for today; for past days log at noon.
  DateTime _loggedAt() {
    final now = DateTime.now();
    final d = widget.day;
    return DateUtils.isSameDay(d, now)
        ? now
        : DateTime(d.year, d.month, d.day, 12);
  }

  int? get _baseCalories => int.tryParse(_calories.text.trim());

  Future<void> _onNameChanged(String text) async {
    final found = _isEdit
        ? const <SavedFood>[]
        : await widget.database.searchFoods(text);
    if (mounted && text == _name.text) setState(() => _suggestions = found);
  }

  void _applySaved(SavedFood food) {
    setState(() {
      _name.text = food.name;
      _calories.text = food.calories?.toString() ?? '';
      _estimated = food.isEstimate;
      _barcode = food.barcode;
      _portionLabel = food.portionLabel;
      _suggestions = const [];
      _message = null;
    });
  }

  Future<void> _quickLogFood(SavedFood food) async {
    final id = await widget.database.logSavedFood(
      food,
      meal: _meal,
      at: _loggedAt(),
    );
    if (mounted) Navigator.of(context).pop(LoggedResult(food.name, [id]));
  }

  Future<void> _quickLogTemplate(MealTemplate template) async {
    final ids = await widget.database.logTemplate(
      template,
      meal: _meal,
      at: _loggedAt(),
    );
    if (mounted) Navigator.of(context).pop(LoggedResult(template.name, ids));
  }

  Future<void> _confirmDelete({
    required String title,
    required Future<void> Function() onDelete,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await onDelete();
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (code == null || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final saved = await widget.database.findFoodByBarcode(code);
      if (saved != null) {
        _applySaved(saved);
        return;
      }
      final product = await widget.services.openFoodFacts.lookup(code);
      if (!mounted) return;
      if (product == null) {
        setState(
          () => _message = 'No product found for $code. Enter it by hand.',
        );
        return;
      }
      setState(() {
        _name.text = product.name;
        _calories.text = product.calories?.toString() ?? '';
        _estimated = false;
        _barcode = product.barcode;
        _portionLabel = product.portionLabel;
        _suggestions = const [];
        _message = product.calories == null
            ? 'Found ${product.name}, but it has no calorie info.'
            : product.portionLabel == null
            ? null
            : 'Calories are per ${product.portionLabel}.';
      });
    } on Exception {
      if (mounted) {
        setState(
          () => _message = 'Could not look that up. Check your connection.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askAi() async {
    final result = await showModalBottomSheet<AiEstimate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AiEstimateSheet(
        services: widget.services,
        initialDescription: _name.text,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (_name.text.trim().isEmpty) _name.text = result.summary;
      _calories.text = result.totalCalories.toString();
      _estimated = true;
      if (_notes.text.trim().isEmpty && result.items.length > 1) {
        _notes.text = result.items
            .map((i) => '${i.name} ~${i.calories}')
            .join(', ');
      }
      _suggestions = const [];
      _message = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final existing = widget.existing;
    if (existing == null) {
      final id = await widget.database.logFood(
        name: name,
        meal: _meal,
        at: _loggedAt(),
        baseCalories: _baseCalories,
        baseIsEstimate: _estimated,
        portion: _portion,
        notes: notes,
        portionLabel: _portionLabel,
        barcode: _barcode,
      );
      if (mounted) Navigator.of(context).pop(LoggedResult(name, [id]));
      return;
    }
    final calories = _baseCalories;
    await widget.database.updateEntry(
      existing.copyWith(
        name: name,
        mealType: _meal,
        calories: Value(calories),
        notes: Value(notes),
        isEstimate:
            _estimated ||
            (calories != null &&
                calories == existing.calories &&
                existing.isEstimate),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = resolveCalories(
      base: _baseCalories,
      baseIsEstimate: _estimated,
      portion: _portion,
      meal: _meal,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              if (!_isEdit) _quickAdd(theme),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What did you eat?',
                ),
                onChanged: _onNameChanged,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a food' : null,
              ),
              if (_suggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final f in _suggestions)
                        ActionChip(
                          label: Text(
                            f.calories == null
                                ? f.name
                                : '${f.name} · ${f.calories}',
                          ),
                          onPressed: () => _applySaved(f),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _calories,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Calories (optional)',
                  helperText: _estimated ? 'Estimated' : _portionLabel,
                ),
                onChanged: (_) => setState(() => _estimated = false),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  return (n == null || n < 0 || n > 20000)
                      ? 'Enter a valid number'
                      : null;
                },
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                SegmentedButton<Portion>(
                  emptySelectionAllowed: true,
                  segments: [
                    for (final p in Portion.values)
                      ButtonSegment(
                        value: p,
                        label: Text(toBeginningOfSentenceCase(p.name)),
                      ),
                  ],
                  selected: {?_portion},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _portion = s.firstOrNull),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    preview.kcal == null
                        ? 'Pick a size for a rough calorie estimate, or skip it.'
                        : 'Logs as ${preview.isEstimate ? '~' : ''}${preview.kcal} kcal',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _scan,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _askAi,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Estimate'),
                    ),
                  ),
                ],
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_message!, style: theme.textTheme.bodySmall),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }

  /// Saved meals and most-used foods; one tap logs them under the selected
  /// meal. Long-press removes one.
  Widget _quickAdd(ThemeData theme) {
    return StreamBuilder<List<MealTemplate>>(
      stream: widget.database.watchTemplates(),
      builder: (context, templates) => StreamBuilder<List<SavedFood>>(
        stream: widget.database.watchFrequentFoods(),
        builder: (context, foods) {
          final t = templates.data ?? const <MealTemplate>[];
          final f = foods.data ?? const <SavedFood>[];
          if (t.isEmpty && f.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tap to log', style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  children: [
                    for (final tpl in t)
                      GestureDetector(
                        onLongPress: () => _confirmDelete(
                          title: 'Remove "${tpl.name}"?',
                          onDelete: () =>
                              widget.database.deleteTemplate(tpl.id),
                        ),
                        child: ActionChip(
                          avatar: const Icon(Icons.restaurant_menu, size: 18),
                          label: Text(tpl.name),
                          onPressed: () => _quickLogTemplate(tpl),
                        ),
                      ),
                    for (final food in f)
                      GestureDetector(
                        onLongPress: () => _confirmDelete(
                          title: 'Remove "${food.name}" from quick add?',
                          onDelete: () =>
                              widget.database.deleteSavedFood(food.id),
                        ),
                        child: ActionChip(
                          label: Text(food.name),
                          onPressed: () => _quickLogFood(food),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
