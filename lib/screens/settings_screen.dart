import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ai_settings.dart';
import '../services/health_service.dart';
import '../services/services.dart';
import '../services/user_prefs.dart';
import '../theme.dart';
import '../util/units.dart';
import '../widgets/common.dart';
import 'goals_screen.dart';

const _privacyUrl = 'https://amitrke.github.io/basic-health-tracker/';

String get _healthName => Platform.isIOS ? 'Apple Health' : 'Health Connect';

/// A grey caps heading above a settings card.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: context.palette.muted,
      ),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _healthOn = false;
  bool _healthBusy = false;
  String? _healthNote;
  BodyStats _body = const BodyStats();
  final _age = TextEditingController();
  Sex? _sex;
  AiSettings _ai = const AiSettings();

  AppServices get _services => widget.services;

  int? get _resting => restingKcal(
    weightKg: _body.weightKg,
    heightCm: _body.heightCm ?? _services.prefs.value.heightCm,
    age: int.tryParse(_age.text.trim()),
    sex: _sex,
  );

  @override
  void initState() {
    super.initState();
    _services.healthPrefs.readProfile().then((p) {
      if (!mounted) return;
      setState(() {
        _age.text = p.age?.toString() ?? '';
        _sex = p.sex;
      });
    });
    _services.healthPrefs.readEnabled().then((on) {
      if (!mounted) return;
      setState(() => _healthOn = on);
      if (on) _loadBody();
    });
    _loadAi();
  }

  Future<void> _loadAi() async {
    final ai = await _services.settingsStore.read();
    if (mounted) setState(() => _ai = ai);
  }

  @override
  void dispose() {
    _age.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {});
    final age = int.tryParse(_age.text.trim());
    await _services.healthPrefs.writeProfile(
      BodyProfile(
        age: age != null && age > 0 && age < 120 ? age : null,
        sex: _sex,
      ),
    );
  }

  Future<void> _loadBody() async {
    final body = await _services.health.bodyStats();
    if (mounted) setState(() => _body = body);
  }

  Future<void> _setHealth(bool on) async {
    setState(() {
      _healthBusy = true;
      _healthNote = null;
    });
    final health = _services.health;
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
    await _services.healthPrefs.writeEnabled(on);
    if (!mounted) return;
    setState(() {
      _healthOn = on;
      _healthBusy = false;
      _body = const BodyStats();
    });
    if (on) _loadBody();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) _loadAi();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _services.prefs,
      builder: (context, _) => _build(context, _services.prefs.value),
    );
  }

  Widget _build(BuildContext context, UserPrefs prefs) {
    final theme = Theme.of(context);
    final p = context.palette;
    final units = Units(prefs);
    final aiInUse = _ai.activeConfig.isUsable;
    Widget chevron(String value) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: p.muted)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: p.muted),
      ],
    );
    final goals = GoalsScreen(services: _services);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const _SectionLabel('Goals'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Daily calories'),
                  trailing: chevron(units.energy(prefs.calorieGoal)),
                  onTap: () => _open(goals),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('Macros'),
                  trailing: chevron(
                    'P ${prefs.proteinGoal} · C ${prefs.carbsGoal} · '
                    'F ${prefs.fatGoal} g',
                  ),
                  onTap: () => _open(goals),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('Goal weight'),
                  trailing: chevron(
                    prefs.goalWeightKg == null
                        ? 'Not set'
                        : units.weight(prefs.goalWeightKg!),
                  ),
                  onTap: () => _open(goals),
                ),
              ],
            ),
          ),
          const _SectionLabel('Units'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _UnitRow(
                    label: 'Weight',
                    child: SegmentedButton<WeightUnit>(
                      segments: const [
                        ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                        ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                      ],
                      selected: {prefs.weightUnit},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => _services.prefs.update(
                        (v) => v.copyWith(weightUnit: s.first),
                      ),
                    ),
                  ),
                  _UnitRow(
                    label: 'Height',
                    child: SegmentedButton<HeightUnit>(
                      segments: const [
                        ButtonSegment(value: HeightUnit.cm, label: Text('cm')),
                        ButtonSegment(
                          value: HeightUnit.ftIn,
                          label: Text('ft/in'),
                        ),
                      ],
                      selected: {prefs.heightUnit},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => _services.prefs.update(
                        (v) => v.copyWith(heightUnit: s.first),
                      ),
                    ),
                  ),
                  _UnitRow(
                    label: 'Energy',
                    child: SegmentedButton<EnergyUnit>(
                      segments: const [
                        ButtonSegment(
                          value: EnergyUnit.kcal,
                          label: Text('kcal'),
                        ),
                        ButtonSegment(value: EnergyUnit.kJ, label: Text('kJ')),
                      ],
                      selected: {prefs.energyUnit},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => _services.prefs.update(
                        (v) => v.copyWith(energyUnit: s.first),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SectionLabel(_healthName),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: p.burnSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.favorite_border, color: p.burn, size: 20),
                  ),
                  title: Text('Use $_healthName data'),
                  subtitle: const Text(
                    'Reads calories burned, weight and height. Never writes.',
                  ),
                  value: _healthOn,
                  onChanged: _healthBusy ? null : _setHealth,
                ),
                if (_healthNote != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      _healthNote!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                if (_healthOn) ...[
                  const Divider(indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('Add exercise to my budget'),
                    subtitle: const Text(
                      'Active calories raise the day’s calorie budget',
                    ),
                    value: prefs.addActiveToBudget,
                    onChanged: (on) => _services.prefs.update(
                      (v) => v.copyWith(addActiveToBudget: on),
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: Text(
                      _body.isEmpty
                          ? 'No weight or height found'
                          : [
                              if (_body.weightKg != null)
                                units.weight(_body.weightKg!),
                              if (_body.heightCm != null)
                                units.height(_body.heightCm!),
                            ].join(' · '),
                    ),
                    subtitle: const Text('Latest values in Health'),
                  ),
                ],
              ],
            ),
          ),
          const _SectionLabel('Profile'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Used to estimate the calories you burn at rest. Health '
                    'does not share age or sex.',
                    style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
                  ),
                  const SizedBox(height: 12),
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
                        'Resting burn about ${units.energy(_resting!)} a day.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const _SectionLabel('Food'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.auto_awesome, color: p.accent),
                  title: const Text('AI estimates'),
                  subtitle: Text(
                    aiInUse
                        ? 'Using ${_ai.active.label}'
                        : 'Not set up. Add a provider and key',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(AiSettingsScreen(services: _services)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(
                Uri.parse(_privacyUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        child,
      ],
    ),
  );
}

/// Pick an AI provider and save its key, model and URL.
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  final _baseUrl = TextEditingController();
  AiSettings _settings = const AiSettings();
  AiProvider _provider = AiProvider.anthropic;
  bool _loaded = false;
  String? _error;

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
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    _baseUrl.dispose();
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
    void unfocus(PointerDownEvent _) =>
        FocusManager.instance.primaryFocus?.unfocus();
    return Scaffold(
      appBar: AppBar(title: const Text('AI estimates')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            'Describe a meal or snap a photo and an AI model estimates the '
            'calories and macros. Pick a provider and add your own key. Keys '
            'stay in this device\'s secure storage and are only sent to the '
            'provider.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.muted,
            ),
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
          SectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loaded && inUse)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.check_circle_outline,
                      color: context.palette.accent,
                    ),
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
                    onTapOutside: unfocus,
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
                  onTapOutside: unfocus,
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
                  onTapOutside: unfocus,
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
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _save,
                  child: Text('Save and use ${_provider.label}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
