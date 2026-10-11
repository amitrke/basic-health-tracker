import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wellbite/data/database.dart';
import 'package:wellbite/sync/drive_backend.dart';
import 'package:wellbite/sync/sync_backend.dart';
import 'package:wellbite/sync/sync_engine.dart';
import 'package:wellbite/sync/sync_snapshot.dart';
import 'package:wellbite/sync/sync_store.dart';

class FakeAuth implements DriveAuth {
  final invalidated = <String>[];
  int _n = 0;
  bool signedIn = true;

  @override
  String? get unavailableReason => null;

  @override
  Future<void> signIn() async => signedIn = true;

  @override
  Future<String> accessToken() async {
    if (!signedIn) throw const SyncException('Signed out of Google.');
    return 'token-${_n++}';
  }

  @override
  Future<void> invalidate(String token) async => invalidated.add(token);

  @override
  Future<void> signOut() async => signedIn = false;
}

/// Just enough of Drive's REST API for one file in the app data folder.
class FakeDrive {
  String? content;
  int version = 0;
  final requests = <String>[];

  /// Status codes to answer with before behaving, oldest first.
  final failures = <int>[];

  Future<http.Response> handle(http.Request r) async {
    requests.add('${r.method} ${r.url.path}');
    if (failures.isNotEmpty) return http.Response('{}', failures.removeAt(0));
    final path = r.url.path;
    if (r.method == 'GET' && path == '/drive/v3/files') {
      expect(r.url.queryParameters['spaces'], 'appDataFolder');
      expect(r.url.queryParameters['q'], contains(DriveSyncBackend.fileName));
      return http.Response(
        jsonEncode({
          'files': content == null
              ? []
              : [
                  {'id': 'file1', 'version': '$version'},
                ],
        }),
        200,
      );
    }
    if (r.method == 'GET' && path == '/drive/v3/files/file1') {
      expect(r.url.queryParameters['alt'], 'media');
      return http.Response.bytes(utf8.encode(content!), 200);
    }
    if (r.method == 'POST' && path == '/upload/drive/v3/files') {
      final parts = utf8.decode(r.bodyBytes).split(RegExp(r'--wellbite-sync-boundary(--)?\r\n?'));
      final meta = jsonDecode(parts[1].split('\r\n\r\n')[1].trim()) as Map;
      expect(meta['name'], DriveSyncBackend.fileName);
      expect(meta['parents'], ['appDataFolder']);
      content = parts[2].split('\r\n\r\n')[1].replaceAll(RegExp(r'\r\n--wellbite-sync-boundary--$'), '').trimRight();
      version++;
      return http.Response('{"id":"file1"}', 200);
    }
    if (r.method == 'PATCH' && path == '/upload/drive/v3/files/file1') {
      content = utf8.decode(r.bodyBytes);
      version++;
      return http.Response('{"id":"file1"}', 200);
    }
    return http.Response('unexpected ${r.method} $path', 404);
  }
}

DriveSyncBackend backendFor(FakeDrive drive, FakeAuth auth) =>
    DriveSyncBackend(
      auth: auth,
      client: MockClient((r) => drive.handle(r)),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeDrive drive;
  late FakeAuth auth;
  late DriveSyncBackend backend;

  setUp(() {
    drive = FakeDrive();
    auth = FakeAuth();
    backend = backendFor(drive, auth);
  });

  test('reading before anything is uploaded gives nothing', () async {
    expect(await backend.read(), isNull);
  });

  test('first write creates the file, later writes replace it', () async {
    await backend.write('{"a":"é"}');
    expect(drive.content, '{"a":"é"}');
    final doc = (await backend.read())!;
    expect(doc.text, '{"a":"é"}');

    await backend.write('{"a":2}', ifVersion: doc.version);
    expect(drive.content, '{"a":2}');
    expect(drive.requests.last, 'PATCH /upload/drive/v3/files/file1');
  });

  test('a write against an old version is refused', () async {
    await backend.write('one');
    final old = (await backend.read())!.version;
    drive.version++; // another device wrote
    expect(
      backend.write('two', ifVersion: old),
      throwsA(isA<SyncConflict>()),
    );
    expect(drive.content, 'one');
  });

  test('creating when another device already did is a conflict', () async {
    drive.content = 'theirs';
    drive.version = 1;
    expect(backend.write('mine'), throwsA(isA<SyncConflict>()));
    expect(drive.content, 'theirs');
  });

  test('an expired token is replaced once and the call retried', () async {
    drive.failures.add(401);
    expect(await backend.read(), isNull);
    expect(auth.invalidated, ['token-0']);
  });

  test('errors become messages the user can act on', () async {
    drive.failures.add(403);
    await expectLater(
      backend.read(),
      throwsA(
        isA<SyncException>().having((e) => e.message, 'message', contains('Drive API')),
      ),
    );
    drive.failures.add(503);
    await expectLater(
      backend.read(),
      throwsA(
        isA<SyncException>().having((e) => e.message, 'message', contains('trouble')),
      ),
    );
  });

  test('signed out means a clear error, not a crash', () async {
    await backend.signOut();
    expect(backend.read(), throwsA(isA<SyncException>()));
  });

  test('two phones sync through the Drive API end to end', () async {
    final dbA = AppDatabase(NativeDatabase.memory());
    final dbB = AppDatabase(NativeDatabase.memory());
    addTearDown(dbA.close);
    addTearDown(dbB.close);
    final a = SyncEngine(SyncStore(dbA), backendFor(drive, FakeAuth()));
    final b = SyncEngine(SyncStore(dbB), backendFor(drive, FakeAuth()));

    await dbA.logFood(
      name: 'Dal',
      meal: MealType.dinner,
      at: DateTime(2026, 5, 2, 19),
      baseCalories: 180,
    );
    expect(await a.sync(firstSync: true), SyncOutcome.uploaded);
    await b.sync(firstSync: true);
    expect((await dbB.select(dbB.foodEntries).get()).single.name, 'Dal');

    await dbB.addWeight(71.2, DateTime(2026, 5, 3, 7));
    await b.sync(firstSync: false);
    await a.sync(firstSync: false);
    expect((await dbA.select(dbA.weightEntries).get()).single.kg, 71.2);
    expect(await a.sync(firstSync: false), SyncOutcome.unchanged);
  });
}
