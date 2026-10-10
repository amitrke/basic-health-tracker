import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbite/sync/icloud_backend.dart';
import 'package:wellbite/sync/sync_backend.dart';
import 'package:wellbite/sync/sync_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('wellbite/icloud');
  late ICloudSyncBackend backend;
  late Object? Function(MethodCall) handler;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    backend = ICloudSyncBackend(channel);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads the file and its version', () async {
    handler = (_) => {'text': '{"a":1}', 'version': '17-9'};
    final doc = (await backend.read())!;
    expect(doc.text, '{"a":1}');
    expect(doc.version, '17-9');
  });

  test('no file yet reads as nothing', () async {
    handler = (_) => null;
    expect(await backend.read(), isNull);
  });

  test('a write passes the version it expects', () async {
    handler = (_) => 'ok';
    await backend.write('text', ifVersion: '17-9');
    expect(calls.single.method, 'write');
    expect(calls.single.arguments, {'text': 'text', 'ifVersion': '17-9'});
  });

  test('a write against a changed file is a conflict', () async {
    handler = (_) => 'conflict';
    expect(backend.write('text'), throwsA(isA<SyncConflict>()));
  });

  test('turning on explains a signed-out iCloud', () async {
    handler = (_) => 'signedOut';
    await expectLater(
      backend.connect(),
      throwsA(
        isA<SyncException>().having((e) => e.message, 'message', contains('Sign in to iCloud')),
      ),
    );
    handler = (_) => 'ok';
    await backend.connect();
  });

  test('native errors become messages', () async {
    handler = (_) => throw PlatformException(code: 'icloud', message: 'disk full');
    await expectLater(
      backend.read(),
      throwsA(isA<SyncException>().having((e) => e.message, 'message', 'disk full')),
    );
  });
}
