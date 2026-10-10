import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ai_settings.dart';
import '../services/health_service.dart';
import '../services/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  final _baseUrl = TextEditingController();
  AiSettings _settings = const AiSettings();
  AiProvider _provider = AiProvider.anthropic;
  bool _loaded = false;
  String? _error;
  bool _healthOn = false;
  bool _healthBusy = false;
  String? _healthNote;
  BodyStats _body = const BodyStats();
  final _age = TextEditingController();
  Sex? _sex;

  static const _privacyUrl = 'https://amitrke.github.io/basic-health-tracker/';

  int? get _resting => restingKcal(
    weightKg: _body.weightKg,
    heightCm: _body.heightCm,
    age: int.tryParse(_age.text.trim()),
    sex: _sex,
  );

  Future<void> _saveProfile() async {
    setState(() {});
    final age = int.tryParse(_age.text.trim());
    await widget.services.healthPrefs.writeProfile(
      BodyProfile(
        age: age != null && age > 0 && age < 120 ? age : null,
        sex: _sex,
      ),
    );
  }

  static String get _healthName =>
      Platform.isIOS ? 'Apple Health' : 'Health Connect';

  AiConfig get _saved => _settings.configFor(_provider);
  bool get _hasKey => _saved.apiKey.isNotEmpty;

  static const _help = {
    AiProvider.anthropic:
        'Claude models. Get a key at console.anthropic.com. Requests are '
        'billed to your Anthropic account.',
    AiProvider.openRouter:
        'One key for many models. Get one at openrouter.ai/keys. The default '
        'model, openrouter/free, picks a free model that can read photos. '
        'Free models are rate limited, and free providers may log what you '
        'send, so keep it to food. You can also enter any OpenRouter model id.',
    AiProvider.custom:
        'Any OpenAI-compatible endpoint, such as OpenAI, Ollama or LM Studio. '
        'The base URL looks like https://api.openai.com/v1. The key is '
        'optional for a local server. Use a model that accepts images if you '
        'want photo estimates.',
  };

  @override
  void initState() {
    super.initState();
    widget.services.settingsStore.read().then((s) {
      if (!mounted) return;
      setState(() {
        _settings = s;
        _loaded = true;
        _select(s.active);
      });
    });
    widget.services.healthPrefs.readProfile().then((p) {
      if (!mounted) return;
      setState(() {
        _age.text = p.age?.toString() ?? '';
        _sex = p.sex;
      });
    });
    widget.services.healthPrefs.readEnabled().then((on) {
      if (!mounted) return;
      setState(() => _healthOn = on);
      if (on) _loadBody();
    });
  }

  Future<void> _loadBody() async {
    final body = await widget.services.health.bodyStats();
    if (mounted) setState(() => _body = body);
  }

  Future<void> _setHealth(bool on) async {
    setState(() {
      _healthBusy = true;
      _healthNote = null;
    });
    final health = widget.services.health;
    if (on) {
      if (!await health.isAvailable()) {
        if (!mounted) return;
        setState(() {
          _healthBusy = false;
          _healthNote = Platform.isAndroid
              ? 'Health Connect is not installed. Install it from Google Play '
                    'and try again.'
              : 'Health data is not available on this device.';
        });
        return;
      }
      if (!await health.requestAccess()) {
        if (!mounted) return;
        setState(() {
          _healthBusy = false;
          _healthNote =
              'Access was not granted. You can allow it in $_healthName '
              'settings.';
        });
        return;
      }
    }
    await widget.services.healthPrefs.writeEnabled(on);
    if (!mounted) return;
    setState(() {
      _healthOn = on;
      _healthBusy = false;
      _body = const BodyStats();
    });
    if (on) _loadBody();
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    _baseUrl.dispose();
    _age.dispose();
    super.dispose();
  }

  /// Shows [provider]'s saved details in the form. The key is never echoed.
  void _select(AiProvider provider) {
    _provider = provider;
    final config = _settings.configFor(provider);
    _model.text = config.model;
    _baseUrl.text = provider.hasEditableBaseUrl ? config.baseUrl : '';
    _key.clear();
    _error = null;
  }

  Future<void> _save() async {
    final typedKey = cleanApiKey(_key.text);
    if (!isValidApiKey(typedKey)) {
      setState(
        () => _error =
            'That key has hidden or unusual characters. Copy it again from '
            'the provider and paste it here.',
      );
      return;
    }
    final config = AiConfig(
      provider: _provider,
      apiKey: typedKey.isNotEmpty ? typedKey : _saved.apiKey,
      model: _model.text,
      baseUrl: _provider.hasEditableBaseUrl ? _baseUrl.text : null,
    );
    if (!config.isUsable) {
      setState(() {
        _error = switch (_provider) {
          AiProvider.custom => 'Enter a base URL and model name.',
          _ => 'Enter an API key.',
        };
      });
      return;
    }
    final updated = _settings.withConfig(config);
    await widget.services.settingsStore.write(updated);
    if (!mounted) return;
    setState(() {
      _settings = updated;
      _key.clear();
      _error = null;
    });
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('${_provider.label} saved and in use')),
      );
  }

  Future<void> _removeKey() async {
    final updated = _settings.withoutKey(_provider);
    await widget.services.settingsStore.write(updated);
    if (mounted) setState(() => _settings = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inUse =
        _settings.active == _provider && _settings.activeConfig.isUsable;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          Text('AI calorie estimates', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Describe a meal or snap a photo and an AI model estimates the '
            'calories. Pick a provider and add your own key. Keys stay in '
            'this device\'s secure storage and are only sent to the provider.',
          ),
          const SizedBox(height: 16),
          SegmentedButton<AiProvider>(
            segments: [
              for (final p in AiProvider.values)
                ButtonSegment(value: p, label: Text(p.label)),
            ],
            selected: {_provider},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _select(s.first)),
          ),
          const SizedBox(height: 8),
          Text(_help[_provider]!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          if (_loaded && inUse)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text('${_provider.label} is in use'),
            ),
          if (_loaded && _hasKey)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.key),
              title: const Text('API key saved'),
              trailing: TextButton(
                onPressed: _removeKey,
                child: const Text('Remove'),
              ),
            ),
          if (_provider.hasEditableBaseUrl) ...[
            TextField(
              controller: _baseUrl,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://api.openai.com/v1',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _model,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Model',
              hintText: _provider.defaultModel.isEmpty
                  ? 'e.g. gpt-4o-mini'
                  : _provider.defaultModel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _key,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: _hasKey
                  ? 'Replace API key'
                  : _provider.requiresKey
                  ? 'API key'
                  : 'API key (optional)',
            ),
            onSubmitted: (_) => _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: Text('Save and use ${_provider.label}'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(_healthName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Read calories burned, weight and height from $_healthName and '
            'show them next to what you eat. Wellbite only reads, never '
            'writes, and the data stays on this device.',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Use $_healthName data'),
            value: _healthOn,
            onChanged: _healthBusy ? null : _setHealth,
          ),
          if (_healthNote != null)
            Text(
              _healthNote!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (_healthOn) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.monitor_weight_outlined),
              title: Text(
                _body.isEmpty
                    ? 'No weight or height found'
                    : [
                        if (_body.weightKg != null)
                          '${_body.weightKg!.toStringAsFixed(1)} kg',
                        if (_body.heightCm != null)
                          '${_body.heightCm!.round()} cm',
                      ].join(' · '),
              ),
              subtitle: const Text('Latest values in Health'),
            ),
            const SizedBox(height: 8),
            Text(
              'Health does not share your age or sex. Add them to estimate the '
              'calories you burn at rest when Health only reports exercise.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(labelText: 'Age'),
              onChanged: (_) => _saveProfile(),
            ),
            const SizedBox(height: 12),
            SegmentedButton<Sex>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: Sex.female, label: Text('Female')),
                ButtonSegment(value: Sex.male, label: Text('Male')),
              ],
              selected: {?_sex},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                setState(() => _sex = s.firstOrNull);
                _saveProfile();
              },
            ),
            if (_resting != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Resting burn about $_resting kcal a day.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.parse(_privacyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}
