import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:wellbite/data/calories.dart';
import 'package:wellbite/data/database.dart';
import 'package:wellbite/services/ai_estimator.dart';
import 'package:wellbite/services/ai_settings.dart';
import 'package:wellbite/services/open_food_facts.dart';

void main() {
  group('resolveCalories', () {
    test('scales known calories by portion', () {
      final r = resolveCalories(
        base: 300,
        portion: Portion.large,
        meal: MealType.lunch,
      );
      expect(r.kcal, 420);
      expect(r.isEstimate, isFalse);
    });

    test('normal portion when unset', () {
      expect(resolveCalories(base: 300, meal: MealType.lunch).kcal, 300);
    });

    test('coarse estimate when only a portion is given', () {
      final r = resolveCalories(portion: Portion.small, meal: MealType.snack);
      expect(r.kcal, 100);
      expect(r.isEstimate, isTrue);
    });

    test('nothing when neither is given', () {
      expect(resolveCalories(meal: MealType.dinner).kcal, isNull);
    });
  });

  group('saved foods and templates', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('logging remembers the food; re-logging is one call', () async {
      final now = DateTime.now();
      await db.logFood(
        name: 'Oatmeal',
        meal: MealType.breakfast,
        at: now,
        baseCalories: 300,
      );
      final saved = (await db.searchFoods('oat')).single;
      expect(saved.calories, 300);
      expect(saved.useCount, 1);

      await db.logSavedFood(
        saved,
        meal: MealType.breakfast,
        at: now,
        portion: Portion.large,
      );
      final entries = await db.watchDay(now).first;
      expect(entries.map((e) => e.calories), [300, 420]);
      expect((await db.findFood('OATMEAL'))!.useCount, 2);
    });

    test('logging without calories keeps the stored ones', () async {
      final now = DateTime.now();
      await db.logFood(
        name: 'Rice',
        meal: MealType.dinner,
        at: now,
        baseCalories: 200,
      );
      await db.logFood(name: 'rice', meal: MealType.dinner, at: now);
      expect((await db.findFood('Rice'))!.calories, 200);
    });

    test('no-calorie food with a portion logs a flagged estimate', () async {
      final now = DateTime.now();
      await db.logFood(
        name: 'Pasta',
        meal: MealType.dinner,
        at: now,
        portion: Portion.normal,
      );
      final e = (await db.watchDay(now).first).single;
      expect(e.calories, 700);
      expect(e.isEstimate, isTrue);
      expect((await db.findFood('Pasta'))!.calories, isNull);
    });

    test('frequent foods order by use', () async {
      final now = DateTime.now();
      for (final n in ['A', 'B', 'B', 'C', 'B', 'C']) {
        await db.logFood(name: n, meal: MealType.snack, at: now);
      }
      final names = (await db.watchFrequentFoods(limit: 2).first).map(
        (f) => f.name,
      );
      expect(names, ['B', 'C']);
    });

    test('template logs all its items under the chosen meal', () async {
      final now = DateTime.now();
      await db.logFood(
        name: 'Eggs',
        meal: MealType.breakfast,
        at: now,
        baseCalories: 150,
      );
      await db.logFood(
        name: 'Toast',
        meal: MealType.breakfast,
        at: now,
        baseCalories: 100,
      );
      final entries = await db.watchDay(now).first;
      await db.saveTemplate('Usual', MealType.breakfast, entries);
      final tpl = (await db.watchTemplates().first).single;

      final ids = await db.logTemplate(tpl, meal: MealType.lunch, at: now);
      expect(ids, hasLength(2));
      final lunch = (await db.watchDay(now).first).where(
        (e) => e.mealType == MealType.lunch,
      );
      expect(lunch.map((e) => e.name), ['Eggs', 'Toast']);

      await db.deleteEntries(ids);
      expect(await db.watchDay(now).first, hasLength(2));

      await db.deleteTemplate(tpl.id);
      expect(await db.watchTemplates().first, isEmpty);
    });

    test('saving a template under the same name replaces it', () async {
      final now = DateTime.now();
      await db.logFood(name: 'Eggs', meal: MealType.breakfast, at: now);
      final entries = await db.watchDay(now).first;
      await db.saveTemplate('Usual', MealType.breakfast, entries);
      await db.saveTemplate('usual', MealType.breakfast, entries);
      expect(await db.watchTemplates().first, hasLength(1));
    });
  });

  test('upgrading from v1 keeps entries and seeds saved foods', () async {
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
          CREATE TABLE food_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            meal_type INTEGER NOT NULL,
            calories INTEGER NULL,
            notes TEXT NULL,
            logged_at INTEGER NOT NULL
          )''');
        final t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        raw.execute(
          "INSERT INTO food_entries (name, meal_type, calories, logged_at) "
          "VALUES ('Soup', 1, 250, $t), ('Soup', 1, 260, $t + 1)",
        );
        raw.execute('PRAGMA user_version = 1');
      },
    );
    final db = AppDatabase(executor);
    addTearDown(db.close);

    final entries = await db.watchDay(DateTime.now()).first;
    expect(entries, hasLength(2));
    expect(entries.first.isEstimate, isFalse);
    final soup = (await db.findFood('soup'))!;
    expect(soup.calories, 260);
    expect(soup.useCount, 2);
  });

  group('Open Food Facts', () {
    OpenFoodFacts withBody(Map<String, dynamic> body, [int status = 200]) =>
        OpenFoodFacts(
          MockClient((_) async => http.Response(jsonEncode(body), status)),
        );

    test('uses per-serving calories when present', () async {
      final p = await withBody({
        'status': 1,
        'product': {
          'product_name': 'Granola',
          'brands': 'Acme, Other',
          'serving_size': '40 g',
          'nutriments': {'energy-kcal_serving': 180.4},
        },
      }).lookup('123');
      expect(p!.name, 'Acme Granola');
      expect(p.calories, 180);
      expect(p.portionLabel, '40 g');
    });

    test('derives serving from per-100g and serving grams', () async {
      final p = await withBody({
        'status': 1,
        'product': {
          'product_name': 'Crackers',
          'serving_quantity': 30,
          'nutriments': {'energy-kcal_100g': 400},
        },
      }).lookup('123');
      expect(p!.calories, 120);
      expect(p.portionLabel, '30 g');
    });

    test('falls back to per 100 g', () async {
      final p = await withBody({
        'status': 1,
        'product': {
          'product_name': 'Cheese',
          'nutriments': {'energy-kcal_100g': 350},
        },
      }).lookup('123');
      expect(p!.calories, 350);
      expect(p.portionLabel, '100 g');
    });

    test('unknown product is null', () async {
      expect(await withBody({'status': 0}).lookup('000'), isNull);
      expect(await withBody({}, 404).lookup('000'), isNull);
    });
  });

  group('AiEstimator', () {
    AiEstimator estimator(AiConfig config, http.Client c) =>
        AiEstimator(config: config, client: c);

    const anthropic = AiConfig(provider: AiProvider.anthropic, apiKey: 'k');
    const openRouter = AiConfig(provider: AiProvider.openRouter, apiKey: 'or');

    const eggsJson =
        '{"items":[{"name":"Eggs","calories":140},'
        '{"name":"Toast","calories":90.4}]}';

    test('anthropic: sends key, model, text; parses fenced JSON', () async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'content': [
              {'type': 'text', 'text': 'Here:\n```json\n$eggsJson\n```'},
            ],
          }),
          200,
        );
      });
      final result = await estimator(
        anthropic,
        client,
      ).estimate(description: '2 eggs');
      expect(seen.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(seen.headers['x-api-key'], 'k');
      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['model'], 'claude-haiku-5-5');
      expect(result.totalCalories, 230);
      expect(result.summary, 'Eggs, Toast');
    });

    test('openrouter: bearer auth, free model, image as data URL', () async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': eggsJson},
              },
            ],
          }),
          200,
        );
      });
      final result = await estimator(openRouter, client).estimate(
        description: 'breakfast',
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(
        seen.url.toString(),
        'https://openrouter.ai/api/v1/chat/completions',
      );
      expect(seen.headers['Authorization'], 'Bearer or');
      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['model'], 'openrouter/free');
      final parts = (body['messages'][1]['content'] as List);
      expect(
        parts.last['image_url']['url'],
        startsWith('data:image/jpeg;base64,'),
      );
      expect(result.totalCalories, 230);
    });

    test('custom endpoint: own base URL, no key header when blank', () async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': [
                    {'type': 'text', 'text': eggsJson},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      const custom = AiConfig(
        provider: AiProvider.custom,
        model: 'llava',
        baseUrl: 'http://192.168.1.5:11434/v1/',
      );
      await estimator(custom, client).estimate(description: 'x');
      expect(
        seen.url.toString(),
        'http://192.168.1.5:11434/v1/chat/completions',
      );
      expect(seen.headers.containsKey('Authorization'), isFalse);
    });

    test('errors map to friendly messages', () async {
      Future<String> messageFor(int status) async {
        final client = MockClient((_) async => http.Response('{}', status));
        try {
          await estimator(openRouter, client).estimate(description: 'x');
        } on AiEstimateException catch (e) {
          return e.message;
        }
        fail('expected an exception');
      }

      expect(await messageFor(401), contains('key was rejected'));
      expect(await messageFor(429), contains('Rate limited'));
      expect(await messageFor(402), contains('credit'));
      expect(await messageFor(500), contains('model name'));
    });

    test('rejects an empty request without calling the API', () async {
      final client = MockClient((_) async => fail('should not be called'));
      expect(
        estimator(anthropic, client).estimate(),
        throwsA(isA<AiEstimateException>()),
      );
    });

    test('garbage reply is an error, not a crash', () {
      expect(
        () => AiEstimator.parseEstimate('no json here'),
        throwsA(isA<AiEstimateException>()),
      );
      expect(
        () => AiEstimator.parseEstimate('{"items":[]}'),
        throwsA(isA<AiEstimateException>()),
      );
    });
  });

  group('AiSettings', () {
    test('round-trips and keeps each provider separate', () {
      const s = AiSettings();
      final updated = s
          .withConfig(
            const AiConfig(provider: AiProvider.anthropic, apiKey: 'a'),
          )
          .withConfig(
            const AiConfig(provider: AiProvider.openRouter, apiKey: 'o'),
          );
      final back = AiSettings.decode(updated.encode());
      expect(back.active, AiProvider.openRouter);
      expect(back.configFor(AiProvider.anthropic).apiKey, 'a');
      expect(back.activeConfig.model, 'openrouter/free');
      expect(
        back.withoutKey(AiProvider.openRouter).activeConfig.isUsable,
        isFalse,
      );
      expect(back.configFor(AiProvider.anthropic).isUsable, isTrue);
    });

    test('custom needs a URL and model but not a key', () {
      expect(const AiConfig(provider: AiProvider.custom).isUsable, isFalse);
      expect(
        const AiConfig(
          provider: AiProvider.custom,
          model: 'm',
          baseUrl: 'http://x/v1',
        ).isUsable,
        isTrue,
      );
    });

    test('corrupt stored data falls back to defaults', () {
      expect(AiSettings.decode('not json').active, AiProvider.anthropic);
    });
  });
}
