import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:wellbite/screens/ai_estimate_sheet.dart';
import 'package:wellbite/services/ai_settings.dart';
import 'package:wellbite/services/services.dart';

/// A zero-width space, which is invisible when pasted from a web page.
final _hidden = String.fromCharCode(0x200B);

AppServices _services(http.Client client, {String key = 'sk-test-123'}) {
  return AppServices(
    settingsStore: MemoryAiSettingsStore(
      const AiSettings().withConfig(
        AiConfig(provider: AiProvider.openRouter, apiKey: key),
      ),
    ),
    client: client,
  );
}

Widget _host(AppServices services, {String? description}) => MaterialApp(
  home: Scaffold(
    body: AiEstimateSheet(services: services, initialDescription: description),
  ),
);

void main() {
  test(
    'cleanApiKey drops whitespace and isValidApiKey rejects hidden chars',
    () {
      expect(cleanApiKey(' sk-abc\n'), 'sk-abc');
      expect(isValidApiKey('sk-or-v1-abc123'), isTrue);
      expect(isValidApiKey('sk-abc$_hidden'), isFalse);
      expect(isValidApiKey('sk abc'), isFalse);
    },
  );

  testWidgets('a typed food is estimated without asking again', (tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': '{"items":[{"name":"Oatmeal, 1 cup cooked","calories":154}]}',
              },
            },
          ],
        }),
        200,
      );
    });
    await tester.pumpWidget(
      _host(_services(client), description: 'Oatmeal 1 cup cooked'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Oatmeal 1 cup cooked'), findsOneWidget);
    expect(find.text('154 kcal'), findsWidgets);
    expect(find.text('Use this'), findsOneWidget);
  });

  testWidgets('a key with a hidden character points to Settings', (
    tester,
  ) async {
    final client = MockClient((request) async => http.Response('{}', 200));
    await tester.pumpWidget(
      _host(_services(client, key: 'sk-bad$_hidden'), description: 'Toast'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('hidden or unusual'), findsOneWidget);
    expect(find.text('Open Settings to fix the AI key'), findsOneWidget);
  });
}
