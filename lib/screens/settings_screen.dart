import 'package:flutter/material.dart';

import '../services/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _key = TextEditingController();
  bool _hasKey = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.services.keyStore.read().then((k) {
      if (!mounted) return;
      setState(() {
        _hasKey = k != null && k.isNotEmpty;
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _key.text.trim();
    if (value.isEmpty) return;
    await widget.services.keyStore.write(value);
    if (!mounted) return;
    _key.clear();
    setState(() => _hasKey = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('API key saved')));
  }

  Future<void> _remove() async {
    await widget.services.keyStore.clear();
    if (mounted) setState(() => _hasKey = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'AI calorie estimates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe a meal or snap a photo and Claude estimates the '
            'calories. Add your own Anthropic API key to turn it on. The key '
            'stays in this device\'s secure storage and is only sent to '
            'Anthropic. Each estimate uses your account.',
          ),
          const SizedBox(height: 16),
          if (_loaded && _hasKey)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('API key saved'),
              trailing: TextButton(
                onPressed: _remove,
                child: const Text('Remove'),
              ),
            ),
          TextField(
            controller: _key,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: _hasKey ? 'Replace API key' : 'Anthropic API key',
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Save key')),
        ],
      ),
    );
  }
}
