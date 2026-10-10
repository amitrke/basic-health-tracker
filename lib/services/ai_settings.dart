import 'dart:convert';

enum AiProvider {
  anthropic(
    label: 'Anthropic',
    defaultModel: 'claude-haiku-5-5',
    defaultBaseUrl: 'https://api.anthropic.com',
  ),
  openRouter(
    label: 'OpenRouter',
    defaultModel: 'openrouter/free',
    defaultBaseUrl: 'https://openrouter.ai/api/v1',
  ),
  custom(label: 'Custom', defaultModel: '', defaultBaseUrl: '');

  const AiProvider({
    required this.label,
    required this.defaultModel,
    required this.defaultBaseUrl,
  });

  final String label;
  final String defaultModel;
  final String defaultBaseUrl;

  /// Custom endpoints (a local Ollama, say) may not need a key.
  bool get requiresKey => this != custom;

  /// Anthropic and OpenRouter have fixed endpoints.
  bool get hasEditableBaseUrl => this == custom;
}

/// One provider's saved connection details.
class AiConfig {
  const AiConfig({
    required this.provider,
    this.apiKey = '',
    this._model,
    this._baseUrl,
  });

  final AiProvider provider;
  final String apiKey;
  final String? _model;
  final String? _baseUrl;

  String get model => (_model?.trim().isNotEmpty ?? false)
      ? _model!.trim()
      : provider.defaultModel;

  String get baseUrl {
    final url = (_baseUrl?.trim().isNotEmpty ?? false)
        ? _baseUrl!.trim()
        : provider.defaultBaseUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Enough is filled in to make a request.
  bool get isUsable =>
      model.isNotEmpty &&
      baseUrl.isNotEmpty &&
      (!provider.requiresKey || apiKey.trim().isNotEmpty);

  AiConfig copyWith({String? apiKey, String? model, String? baseUrl}) =>
      AiConfig(
        provider: provider,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? _model,
        baseUrl: baseUrl ?? _baseUrl,
      );

  Map<String, dynamic> toJson() => {
    'apiKey': apiKey,
    'model': _model,
    'baseUrl': _baseUrl,
  };

  factory AiConfig.fromJson(AiProvider provider, Map<String, dynamic> json) =>
      AiConfig(
        provider: provider,
        apiKey: (json['apiKey'] as String?) ?? '',
        model: json['model'] as String?,
        baseUrl: json['baseUrl'] as String?,
      );
}

/// Every provider's saved config plus which one is in use. Switching
/// providers never throws away the others' keys.
class AiSettings {
  const AiSettings({
    this.active = AiProvider.anthropic,
    this.configs = const {},
  });

  final AiProvider active;
  final Map<AiProvider, AiConfig> configs;

  AiConfig configFor(AiProvider p) => configs[p] ?? AiConfig(provider: p);

  AiConfig get activeConfig => configFor(active);

  AiSettings withConfig(AiConfig config, {bool activate = true}) => AiSettings(
    active: activate ? config.provider : active,
    configs: {...configs, config.provider: config},
  );

  AiSettings withoutKey(AiProvider p) => AiSettings(
    active: active,
    configs: {
      ...configs,
      p: configFor(p).copyWith(apiKey: ''),
    },
  );

  String encode() => jsonEncode({
    'active': active.name,
    'providers': {
      for (final e in configs.entries) e.key.name: e.value.toJson(),
    },
  });

  static AiSettings decode(String source) {
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      AiProvider? byName(String? n) =>
          AiProvider.values.where((p) => p.name == n).firstOrNull;
      final configs = <AiProvider, AiConfig>{};
      for (final e in ((json['providers'] as Map?) ?? const {}).entries) {
        final p = byName(e.key as String);
        if (p != null) {
          configs[p] = AiConfig.fromJson(p, Map<String, dynamic>.from(e.value));
        }
      }
      return AiSettings(
        active: byName(json['active'] as String?) ?? AiProvider.anthropic,
        configs: configs,
      );
    } catch (_) {
      return const AiSettings();
    }
  }
}

/// Drops any whitespace from a pasted key. Keys never contain spaces, but a
/// copied one often carries a trailing newline.
String cleanApiKey(String raw) => raw.replaceAll(RegExp(r'\s'), '');

/// Keys are plain printable ASCII. Anything else (a zero-width character from
/// a web page, say) cannot go in an HTTP header and makes every request fail.
bool isValidApiKey(String key) => RegExp(r'^[\x21-\x7E]*$').hasMatch(key);
