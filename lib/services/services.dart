import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'ai_estimator.dart';
import 'ai_settings.dart';
import 'health_service.dart';
import 'open_food_facts.dart';

/// Where the AI provider settings (including API keys) live.
abstract class AiSettingsStore {
  Future<AiSettings> read();
  Future<void> write(AiSettings settings);
}

/// Keeps settings in the platform keystore.
class SecureAiSettingsStore implements AiSettingsStore {
  static const _storage = FlutterSecureStorage();
  static const _name = 'ai_settings';
  static const _legacyAnthropicKey = 'anthropic_api_key';

  @override
  Future<AiSettings> read() async {
    final stored = await _storage.read(key: _name);
    if (stored != null) return AiSettings.decode(stored);
    // Builds before multi-provider support saved only an Anthropic key.
    final legacy = await _storage.read(key: _legacyAnthropicKey);
    if (legacy != null && legacy.isNotEmpty) {
      return const AiSettings().withConfig(
        AiConfig(provider: AiProvider.anthropic, apiKey: legacy),
      );
    }
    return const AiSettings();
  }

  @override
  Future<void> write(AiSettings settings) =>
      _storage.write(key: _name, value: settings.encode());
}

class MemoryAiSettingsStore implements AiSettingsStore {
  MemoryAiSettingsStore([this._settings = const AiSettings()]);

  AiSettings _settings;

  @override
  Future<AiSettings> read() async => _settings;

  @override
  Future<void> write(AiSettings settings) async => _settings = settings;
}

/// Network-backed helpers shared by the screens.
class AppServices {
  AppServices({
    AiSettingsStore? settingsStore,
    http.Client? client,
    HealthSource? health,
    HealthPrefsStore? healthPrefs,
  }) : settingsStore = settingsStore ?? SecureAiSettingsStore(),
       client = client ?? http.Client(),
       health = health ?? PlatformHealthSource(),
       healthPrefs = healthPrefs ?? SecureHealthPrefsStore();

  final AiSettingsStore settingsStore;
  final http.Client client;
  final HealthSource health;
  final HealthPrefsStore healthPrefs;

  OpenFoodFacts get openFoodFacts => OpenFoodFacts(client);

  /// Null until the active provider has enough saved to make a request.
  Future<AiEstimator?> aiEstimator() async {
    final config = (await settingsStore.read()).activeConfig;
    if (!config.isUsable) return null;
    return AiEstimator(config: config, client: client);
  }
}
