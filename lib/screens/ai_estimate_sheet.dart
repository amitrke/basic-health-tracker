import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_estimator.dart';
import '../services/services.dart';
import '../theme.dart';
import '../util/units.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

/// Collects a description and/or photo, asks the estimator, and pops with the
/// accepted [AiEstimate].
class AiEstimateSheet extends StatefulWidget {
  const AiEstimateSheet({
    super.key,
    required this.services,
    this.initialDescription,
  });

  final AppServices services;

  /// What was already typed in the food form. When present the estimate runs
  /// straight away instead of asking for it again.
  final String? initialDescription;

  @override
  State<AiEstimateSheet> createState() => _AiEstimateSheetState();
}

class _AiEstimateSheetState extends State<AiEstimateSheet> {
  final _description = TextEditingController();
  Uint8List? _image;
  AiEstimate? _result;
  String? _error;
  bool _loading = false;
  bool _needsKey = false;

  bool get _hasInitialDescription =>
      widget.initialDescription?.trim().isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    if (_hasInitialDescription) {
      _description.text = widget.initialDescription!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _estimate();
      });
    }
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _image = bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open the camera or photos.');
      }
    }
  }

  Future<void> _estimate() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    final estimator = await widget.services.aiEstimator();
    if (estimator == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _needsKey = true;
        });
      }
      return;
    }
    try {
      final result = await estimator.estimate(
        description: _description.text,
        imageBytes: _image,
      );
      if (mounted) setState(() => _result = result);
    } on AiEstimateException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _needsKey = e.fixInSettings;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiSettingsScreen(services: widget.services),
      ),
    );
    if (!mounted) return;
    final estimator = await widget.services.aiEstimator();
    if (!mounted) return;
    setState(() => _needsKey = estimator == null);
    // Back from Settings with a usable key: carry on without another tap.
    if (estimator != null && _description.text.trim().isNotEmpty) _estimate();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final units = Units(widget.services.prefs.value);
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: p.accent),
                const SizedBox(width: 8),
                Text(
                  'Estimate with AI',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              // No keyboard when the estimate is already running.
              autofocus: !_hasInitialDescription,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Describe the meal',
                hintText: 'Two eggs, buttered toast, coffee with milk',
              ),
            ),
            const SizedBox(height: 12),
            if (_image != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _image!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Remove photo',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _image = null),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose photo'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (_needsKey)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: Text(
                    _error == null
                        ? 'Set up an AI provider to use estimates'
                        : 'Open Settings to fix the AI key',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openSettings,
                ),
              )
            else
              FilledButton.icon(
                onPressed: _loading ? null : _estimate,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'Estimating…' : 'Estimate calories'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 12),
              SectionCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in result.items)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: MacroLine(
                          protein: item.protein,
                          carbs: item.carbs,
                          fat: item.fat,
                        ),
                        trailing: Text(
                          units.energy(item.calories),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Total (estimate)',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: MacroLine(
                        protein: result.totalProtein,
                        carbs: result.totalCarbs,
                        fat: result.totalFat,
                      ),
                      trailing: Text(
                        units.energy(result.totalCalories),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      'Estimates can be off. You can adjust the numbers before '
                      'saving.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: p.muted),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(result),
                      child: const Text('Use this'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
