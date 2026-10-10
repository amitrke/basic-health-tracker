import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../data/database.dart';
import 'drive_backend.dart';
import 'icloud_backend.dart';
import 'sync_backend.dart';
import 'sync_engine.dart';
import 'sync_snapshot.dart';
import 'sync_store.dart';

/// What survives a restart: whether sync is on, and whether this device has
/// ever synced (the first run pairs up pre-existing data).
class SyncPrefs {
  const SyncPrefs({this.enabled = false, this.lastSynced});

  final bool enabled;
  final DateTime? lastSynced;

  String encode() => jsonEncode({
    'enabled': enabled,
    'lastSynced': lastSynced?.millisecondsSinceEpoch,
  });

  static SyncPrefs decode(String text) {
    final j = jsonDecode(text) as Map<String, Object?>;
    final ms = j['lastSynced'] as int?;
    return SyncPrefs(
      enabled: j['enabled'] as bool? ?? false,
      lastSynced: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }
}

abstract class SyncPrefsStore {
  Future<SyncPrefs> read();
  Future<void> write(SyncPrefs prefs);
}

class SecureSyncPrefsStore implements SyncPrefsStore {
  static const _storage = FlutterSecureStorage();
  static const _name = 'sync_prefs';

  @override
  Future<SyncPrefs> read() async {
    final stored = await _storage.read(key: _name);
    return stored == null ? const SyncPrefs() : SyncPrefs.decode(stored);
  }

  @override
  Future<void> write(SyncPrefs prefs) =>
      _storage.write(key: _name, value: prefs.encode());
}

class MemorySyncPrefsStore implements SyncPrefsStore {
  MemorySyncPrefsStore([this._prefs = const SyncPrefs()]);

  SyncPrefs _prefs;

  @override
  Future<SyncPrefs> read() async => _prefs;

  @override
  Future<void> write(SyncPrefs prefs) async => _prefs = prefs;
}

/// Turns sync on and off and keeps it running: after a change, on launch, and
/// whenever the app comes back to the foreground.
class SyncController extends ChangeNotifier {
  SyncController({
    required this.database,
    required this.backend,
    SyncPrefsStore? prefsStore,
    this.debounce = const Duration(seconds: 8),
  }) : _prefsStore = prefsStore ?? SecureSyncPrefsStore(),
       _engine = SyncEngine(SyncStore(database), backend);

  /// Sync for this platform: Google Drive on Android, iCloud on iOS. Null
  /// elsewhere.
  static SyncController? forPlatform(AppDatabase database) {
    final SyncBackend backend;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        backend = DriveSyncBackend(
          auth: GoogleDriveAuth(),
          client: http.Client(),
        );
      case TargetPlatform.iOS:
        backend = ICloudSyncBackend();
      default:
        return null;
    }
    return SyncController(database: database, backend: backend);
  }

  final AppDatabase database;
  final SyncBackend backend;
  final Duration debounce;
  final SyncPrefsStore _prefsStore;
  final SyncEngine _engine;

  SyncPrefs _prefs = const SyncPrefs();
  bool _syncing = false;
  bool _loaded = false;
  String? _error;
  StreamSubscription<Set<TableUpdate>>? _changes;
  Timer? _timer;

  bool get enabled => _prefs.enabled;
  bool get syncing => _syncing;
  bool get loaded => _loaded;
  DateTime? get lastSynced => _prefs.lastSynced;

  /// Message from the last failed sync, cleared by the next good one.
  String? get error => _error;

  String get label => backend.label;
  String? get unavailableReason => backend.unavailableReason;

  /// Restores the saved choice and, if sync was on, catches up.
  Future<void> load() async {
    _prefs = await _prefsStore.read();
    _loaded = true;
    notifyListeners();
    if (_prefs.enabled) {
      _watchChanges();
      unawaited(syncNow());
    }
  }

  /// Signs in, then runs the first sync. Leaves sync off if either fails.
  Future<void> enable() async {
    _error = null;
    try {
      await backend.connect();
    } on SyncException catch (e) {
      _error = e.message;
      notifyListeners();
      return;
    }
    await _save(SyncPrefs(enabled: true, lastSynced: _prefs.lastSynced));
    _watchChanges();
    await syncNow();
    // A first sync that failed (say, no network) still leaves sync on; the
    // error shows and the next trigger retries.
  }

  Future<void> disable() async {
    _changes?.cancel();
    _changes = null;
    _timer?.cancel();
    _error = null;
    await _save(const SyncPrefs());
    try {
      await backend.signOut();
    } on Object {
      // Nothing to undo if sign-out itself fails.
    }
  }

  /// Syncs now unless one is already running. Safe to call at any time.
  Future<void> syncNow() async {
    if (!_prefs.enabled || _syncing) return;
    _timer?.cancel();
    _syncing = true;
    _error = null;
    notifyListeners();
    try {
      await _engine.sync(firstSync: _prefs.lastSynced == null);
      await _save(SyncPrefs(enabled: true, lastSynced: DateTime.now()));
    } on SyncException catch (e) {
      _error = e.message;
    } on Object catch (e) {
      _error = 'Sync failed: $e';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  void _watchChanges() {
    _changes?.cancel();
    _changes = database
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            database.foodEntries,
            database.savedFoods,
            database.mealTemplates,
            database.weightEntries,
          ]),
        )
        .listen((_) {
          // Writes made by sync itself land here too; skip them or every
          // sync would trigger another.
          if (_syncing) return;
          _timer?.cancel();
          _timer = Timer(debounce, syncNow);
        });
  }

  Future<void> _save(SyncPrefs prefs) async {
    _prefs = prefs;
    await _prefsStore.write(prefs);
  }

  @override
  void dispose() {
    _changes?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
