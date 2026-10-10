import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wellbite/data/calories.dart';
import 'package:wellbite/data/database.dart';
import 'package:wellbite/main.dart';
import 'package:wellbite/services/health_service.dart';
import 'package:wellbite/services/services.dart';
import 'package:wellbite/services/user_prefs.dart';

const _phone = Size(390, 844);
const _tabletPortrait = Size(834, 1194);
const _tabletLandscape = Size(1194, 834);

Future<AppDatabase> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  await tester.runAsync(() async {
    await db.logFood(
      name: 'Chicken rice bowl',
      meal: MealType.lunch,
      at: DateTime.now(),
      baseCalories: 540,
      baseMacros: const Macros(protein: 42, carbs: 62, fat: 14),
    );
    await db.addWeight(80, DateTime.now().subtract(const Duration(days: 10)));
    await db.addWeight(79, DateTime.now());
  });
  await tester.pumpWidget(
    BasicHealthTrackerApp(
      database: db,
      services: AppServices(
        settingsStore: MemoryAiSettingsStore(),
        userPrefs: MemoryUserPrefsStore(
          const UserPrefs(onboarded: true, goalWeightKg: 74),
        ),
        healthPrefs: MemoryHealthPrefsStore(),
      ),
    ),
  );
  await _settle(tester);
  return db;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _unmount(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(db.close);
}

void main() {
  testWidgets('phones keep the bottom bar', (tester) async {
    final db = await _pumpApp(tester, _phone);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await _unmount(tester, db);
  });

  for (final (name, size) in [
    ('portrait', _tabletPortrait),
    ('landscape', _tabletLandscape),
  ]) {
    testWidgets('tablet $name: side rail, and every tab lays out', (
      tester,
    ) async {
      final db = await _pumpApp(tester, size);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // Overflow or layout errors would fail the test as they happen.
      for (final tab in ['Log', 'Weight', 'Trends', 'Today']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text(tab),
          ),
        );
        await _settle(tester);
      }

      await tester.tap(find.byTooltip('Settings'));
      await _settle(tester);
      expect(find.text('Units'.toUpperCase()), findsOneWidget);
      await _unmount(tester, db);
    });
  }

  testWidgets('tablet landscape: Today shows two columns', (tester) async {
    final db = await _pumpApp(tester, _tabletLandscape);
    final calories = tester.getTopLeft(find.text('Calories'));
    final meals = tester.getTopLeft(find.text('Meals'));
    final weight = tester.getTopLeft(find.text('Weight').first);
    // Meals sits beside Calories, not below it, and everything is on screen.
    expect(meals.dx, greaterThan(calories.dx + 300));
    expect(meals.dy, lessThan(calories.dy + 50));
    expect(weight.dy, lessThan(_tabletLandscape.height));
    await _unmount(tester, db);
  });

  testWidgets('tablet portrait: Today stays one column', (tester) async {
    final db = await _pumpApp(tester, _tabletPortrait);
    final calories = tester.getTopLeft(find.text('Calories'));
    final macros = tester.getTopLeft(find.text('Macros'));
    expect(macros.dx, calories.dx);
    expect(macros.dy, greaterThan(calories.dy));
    await _unmount(tester, db);
  });

  testWidgets('tablet: list screens cap their content width', (tester) async {
    final db = await _pumpApp(tester, _tabletLandscape);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Trends'),
      ),
    );
    await _settle(tester);
    final cardWidths = tester
        .widgetList<Card>(find.byType(Card))
        .map((c) => tester.getSize(find.byWidget(c)).width);
    expect(cardWidths, isNotEmpty);
    expect(cardWidths.every((w) => w <= 720), isTrue);
    await _unmount(tester, db);
  });
}
