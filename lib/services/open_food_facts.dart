import 'dart:convert';

import 'package:http/http.dart' as http;

class ScannedProduct {
  const ScannedProduct({
    required this.barcode,
    required this.name,
    this.calories,
    this.portionLabel,
    this.protein,
    this.carbs,
    this.fat,
  });

  final String barcode;
  final String name;

  /// Per serving when the product lists one, otherwise per 100 g.
  final int? calories;
  final String? portionLabel;

  /// Grams for the same amount as [calories].
  final int? protein;
  final int? carbs;
  final int? fat;
}

/// Looks up packaged food by barcode in the free Open Food Facts database.
class OpenFoodFacts {
  OpenFoodFacts(this._client);

  final http.Client _client;

  /// Returns null when the barcode is unknown. Throws on network failure.
  Future<ScannedProduct?> lookup(String barcode) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$barcode.json',
      {
        'fields':
            'product_name,brands,nutriments,serving_size,serving_quantity',
      },
    );
    final response = await _client
        .get(
          uri,
          headers: {'User-Agent': 'BasicHealthTracker/1.0 (food logger)'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Open Food Facts returned ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    if (body is! Map || body['status'] != 1) return null;
    return parseProduct(barcode, body['product'] as Map<String, dynamic>);
  }

  static ScannedProduct? parseProduct(
    String barcode,
    Map<String, dynamic> product,
  ) {
    final productName = (product['product_name'] as String?)?.trim() ?? '';
    if (productName.isEmpty) return null;
    final brand = (product['brands'] as String?)?.split(',').first.trim();
    final name = brand == null || brand.isEmpty || productName.contains(brand)
        ? productName
        : '$brand $productName';

    final nutriments = (product['nutriments'] as Map?) ?? const {};
    double? number(String key) => (nutriments[key] as num?)?.toDouble();

    final perServing = number('energy-kcal_serving');
    final per100 = number('energy-kcal_100g');
    final servingGrams = (product['serving_quantity'] is num)
        ? (product['serving_quantity'] as num).toDouble()
        : double.tryParse('${product['serving_quantity'] ?? ''}');
    final servingSize = (product['serving_size'] as String?)?.trim();

    int? calories;
    String? label;
    // How to turn a per-100 g value into the amount [calories] is for.
    double? per100Factor;
    if (perServing != null) {
      calories = perServing.round();
      label = servingSize;
      if (servingGrams != null && servingGrams > 0) {
        per100Factor = servingGrams / 100;
      }
    } else if (per100 != null && servingGrams != null && servingGrams > 0) {
      per100Factor = servingGrams / 100;
      calories = (per100 * per100Factor).round();
      label = servingSize ?? '${servingGrams.round()} g';
    } else if (per100 != null) {
      per100Factor = 1;
      calories = per100.round();
      label = '100 g';
    }

    int? grams(String nutrient) {
      final serving = number('${nutrient}_serving');
      if (perServing != null && serving != null) return serving.round();
      final p100 = number('${nutrient}_100g');
      if (p100 == null || per100Factor == null) return null;
      return (p100 * per100Factor).round();
    }

    return ScannedProduct(
      barcode: barcode,
      name: name,
      calories: calories,
      portionLabel: label == null || label.isEmpty ? null : label,
      protein: grams('proteins'),
      carbs: grams('carbohydrates'),
      fat: grams('fat'),
    );
  }
}
