import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class EstimatedItem {
  const EstimatedItem({required this.name, required this.calories});

  final String name;
  final int calories;
}

class AiEstimate {
  const AiEstimate(this.items);

  final List<EstimatedItem> items;

  int get totalCalories => items.fold(0, (s, i) => s + i.calories);
  String get summary => items.map((i) => i.name).join(', ');
}

class AiEstimateException implements Exception {
  const AiEstimateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Estimates calories from a description and/or photo using the Claude API,
/// called directly with the user's own API key.
class AiEstimator {
  AiEstimator({required this.apiKey, required this._client});

  static const model = 'claude-haiku-5-5';
  static final _endpoint = Uri.https('api.anthropic.com', '/v1/messages');

  static const _system =
      'You estimate calories for food logging. Given a description and/or '
      'photo of a meal, list each distinct food with a realistic calorie '
      'estimate for the portion shown or described (assume a typical single '
      'serving if unspecified). Respond with only JSON, no prose, in this '
      'shape: {"items":[{"name":"short food name","calories":123}]}';

  final String apiKey;
  final http.Client _client;

  Future<AiEstimate> estimate({
    String? description,
    Uint8List? imageBytes,
    String imageMediaType = 'image/jpeg',
  }) async {
    final text = description?.trim() ?? '';
    if (text.isEmpty && imageBytes == null) {
      throw const AiEstimateException('Describe the food or add a photo.');
    }
    final content = <Map<String, dynamic>>[
      if (imageBytes != null)
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': imageMediaType,
            'data': base64Encode(imageBytes),
          },
        },
      {
        'type': 'text',
        'text': text.isEmpty ? 'Estimate the calories in this meal.' : text,
      },
    ];

    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': 512,
              'system': _system,
              'messages': [
                {'role': 'user', 'content': content},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on Exception {
      throw const AiEstimateException(
        'Could not reach the estimator. Check your connection.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AiEstimateException(
        'The API key was rejected. Check it in Settings.',
      );
    }
    if (response.statusCode != 200) {
      throw AiEstimateException(
        'Estimator error (${response.statusCode}). Try again.',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final blocks = (body['content'] as List?) ?? const [];
    final reply = blocks
        .whereType<Map>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    return parseEstimate(reply);
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
        if (name.isNotEmpty && calories >= 0) {
          items.add(EstimatedItem(name: name, calories: calories));
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
