import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_settings.dart';

class EstimatedItem {
  const EstimatedItem({
    required this.name,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  final String name;
  final int calories;

  /// Grams, when the model gave them.
  final int? protein;
  final int? carbs;
  final int? fat;
}

class AiEstimate {
  const AiEstimate(this.items);

  final List<EstimatedItem> items;

  int get totalCalories => items.fold(0, (s, i) => s + i.calories);

  /// Null for a macro no item reported.
  int? _sum(int? Function(EstimatedItem) pick) {
    final known = items.map(pick).whereType<int>();
    return known.isEmpty ? null : known.fold<int>(0, (s, g) => s + g);
  }

  int? get totalProtein => _sum((i) => i.protein);
  int? get totalCarbs => _sum((i) => i.carbs);
  int? get totalFat => _sum((i) => i.fat);
  String get summary => items.map((i) => i.name).join(', ');
}

class AiEstimateException implements Exception {
  const AiEstimateException(this.message, {this.fixInSettings = false});

  final String message;

  /// The cause is the saved key or provider, so Settings is the way out.
  final bool fixInSettings;

  @override
  String toString() => message;
}

typedef _Request = ({Uri uri, Map<String, String> headers, String body});

/// Estimates calories from a description and/or photo, calling the user's
/// chosen provider directly with their own key. Anthropic uses its Messages
/// API; OpenRouter and custom endpoints use the OpenAI-compatible chat API.
class AiEstimator {
  AiEstimator({required this.config, required this._client});

  static const _system =
      'You estimate calories for food logging. Given a description and/or '
      'photo of a meal, list each distinct food with a realistic calorie '
      'estimate for the portion shown or described (assume a typical single '
      'serving if unspecified), plus protein, carbohydrate and fat in grams. '
      'Respond with only JSON, no prose, in this shape: '
      '{"items":[{"name":"short food name","calories":123,"protein":10,'
      '"carbs":15,"fat":5}]}';

  final AiConfig config;
  final http.Client _client;

  bool get _isAnthropic => config.provider == AiProvider.anthropic;

  Future<AiEstimate> estimate({
    String? description,
    Uint8List? imageBytes,
    String imageMediaType = 'image/jpeg',
  }) async {
    final text = description?.trim() ?? '';
    if (text.isEmpty && imageBytes == null) {
      throw const AiEstimateException('Describe the food or add a photo.');
    }
    final prompt = text.isEmpty ? 'Estimate the calories in this meal.' : text;
    final image = imageBytes == null ? null : base64Encode(imageBytes);

    if (!isValidApiKey(config.apiKey.trim())) {
      throw const AiEstimateException(
        'The saved API key has hidden or unusual characters. Remove it in '
        'Settings and paste it again.',
        fixInSettings: true,
      );
    }

    final request = _isAnthropic
        ? _anthropicRequest(prompt, image, imageMediaType)
        : _openAiRequest(prompt, image, imageMediaType);

    final http.Response response;
    try {
      response = await _client
          .post(request.uri, headers: request.headers, body: request.body)
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw AiEstimateException(_describeFailure(e));
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 401 || 403:
        throw const AiEstimateException(
          'The API key was rejected. Check it in Settings.',
          fixInSettings: true,
        );
      case 402:
        throw const AiEstimateException(
          'The provider says this account is out of credit.',
        );
      case 429:
        throw const AiEstimateException(
          'Rate limited. Wait a moment and try again (free models are '
          'limited).',
        );
      default:
        throw AiEstimateException(
          'Estimator error (${response.statusCode}). Check the model name '
          'in Settings, or try again.',
        );
    }

    final String reply;
    try {
      reply = _isAnthropic
          ? _anthropicReply(response.body)
          : _openAiReply(response.body);
    } catch (_) {
      throw const AiEstimateException('Could not read the estimator reply.');
    }
    return parseEstimate(reply);
  }

  /// Says why a request never produced a response, so a bad key, a bad URL
  /// and a dead connection do not all read the same.
  static String _describeFailure(Exception e) {
    return switch (e) {
      TimeoutException() =>
        'The estimator took too long to answer. Try again, or pick a faster '
            'model in Settings.',
      HandshakeException() || TlsException() =>
        'The secure connection to the estimator failed (${e.runtimeType}).',
      SocketException() =>
        'No connection to the estimator. Check your internet.',
      FormatException() || ArgumentError() =>
        'The request could not be built. Check the base URL and key in '
            'Settings.',
      _ =>
        'Could not reach the estimator (${e.runtimeType}). Check your '
            'connection and settings.',
    };
  }

  _Request _anthropicRequest(String prompt, String? image, String mediaType) {
    return (
      uri: Uri.parse('${config.baseUrl}/v1/messages'),
      headers: {
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': config.model,
        'max_tokens': 512,
        'system': _system,
        'messages': [
          {
            'role': 'user',
            'content': [
              if (image != null)
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': image,
                  },
                },
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
      }),
    );
  }

  _Request _openAiRequest(String prompt, String? image, String mediaType) {
    final key = config.apiKey.trim();
    return (
      uri: Uri.parse('${config.baseUrl}/chat/completions'),
      headers: {
        if (key.isNotEmpty) 'Authorization': 'Bearer $key',
        'content-type': 'application/json',
        if (config.provider == AiProvider.openRouter)
          'X-Title': 'Basic Health Tracker',
      },
      body: jsonEncode({
        'model': config.model,
        'max_tokens': 512,
        'messages': [
          {'role': 'system', 'content': _system},
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              if (image != null)
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:$mediaType;base64,$image'},
                },
            ],
          },
        ],
      }),
    );
  }

  static String _anthropicReply(String body) {
    final blocks = (jsonDecode(body)['content'] as List?) ?? const [];
    return blocks
        .whereType<Map>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
  }

  static String _openAiReply(String body) {
    final content = jsonDecode(body)['choices'][0]['message']['content'];
    if (content is String) return content;
    // Some providers return a list of typed parts.
    return (content as List)
        .whereType<Map>()
        .map((p) => (p['text'] as String?) ?? '')
        .join();
  }

  /// Pulls the JSON object out of [reply], tolerating stray prose or fences.
  static AiEstimate parseEstimate(String reply) {
    final start = reply.indexOf('{');
    final end = reply.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const AiEstimateException('Could not read the estimate.');
    }
    try {
      final json = jsonDecode(reply.substring(start, end + 1));
      final items = <EstimatedItem>[];
      for (final raw in (json['items'] as List)) {
        final name = (raw['name'] as String).trim();
        final calories = (raw['calories'] as num).round();
        int? grams(String key) {
          final v = raw[key];
          return v is num && v >= 0 ? v.round() : null;
        }

        if (name.isNotEmpty && calories >= 0) {
          items.add(
            EstimatedItem(
              name: name,
              calories: calories,
              protein: grams('protein'),
              carbs: grams('carbs'),
              fat: grams('fat'),
            ),
          );
        }
      }
      if (items.isEmpty) {
        throw const AiEstimateException('No food found in that.');
      }
      return AiEstimate(items);
    } on AiEstimateException {
      rethrow;
    } catch (_) {
      throw const AiEstimateException('Could not read the estimate.');
    }
  }
}
