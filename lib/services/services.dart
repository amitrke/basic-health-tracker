import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'ai_estimator.dart';
import 'open_food_facts.dart';

/// Where the user's Anthropic API key lives. Kept in the platform keystore.
abstract class ApiKeyStore {
  Future<String?> read();
  Future<void> write(String key);
  Future<void> clear();
}

class SecureApiKeyStore implements ApiKeyStore {
  static const _storage = FlutterSecureStorage();
  static const _name = 'anthropic_api_key';

  @override
  Future<String?> read() => _storage.read(key: _name);

  @override
  Future<void> write(String key) => _storage.write(key: _name, value: key);

  @override
  Future<void> clear() => _storage.delete(key: _name);
}

class MemoryApiKeyStore implements ApiKeyStore {
  MemoryApiKeyStore([this._key]);

  String? _key;

  @override
  Future<String?> read() async => _key;

  @override
  Future<void> write(String key) async => _key = key;

  @override
  Future<void> clear() async => _key = null;
}

/// Network-backed helpers shared by the screens.
class AppServices {
  AppServices({ApiKeyStore? keyStore, http.Client? client})
    : keyStore = keyStore ?? SecureApiKeyStore(),
      client = client ?? http.Client();

  final ApiKeyStore keyStore;
  final http.Client client;

  OpenFoodFacts get openFoodFacts => OpenFoodFacts(client);

  /// Null when no API key has been saved yet.
  Future<AiEstimator?> aiEstimator() async {
    final key = (await keyStore.read())?.trim();
    if (key == null || key.isEmpty) return null;
    return AiEstimator(apiKey: key, client: client);
  }
}
