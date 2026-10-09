import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_estimator.dart';
import '../services/services.dart';
import 'settings_screen.dart';

/// Collects a description and/or photo, asks the estimator, and pops with the
/// accepted [AiEstimate].
class AiEstimateSheet extends StatefulWidget {
  const AiEstimateSheet({super.key, required this.services});

  final AppServices services;

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
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(services: widget.services),
      ),
    );
    if (!mounted) return;
    final estimator = await widget.services.aiEstimator();
    if (mounted) setState(() => _needsKey = estimator == null);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _description,
              autofocus: true,
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
                  title: const Text('Set up an AI provider to use estimates'),
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
              for (final item in result.items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  trailing: Text('${item.calories} kcal'),
                ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Total (estimate)'),
                trailing: Text(
                  '${result.totalCalories} kcal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(result),
                child: const Text('Use this'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
