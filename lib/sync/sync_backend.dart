import 'sync_snapshot.dart';

/// The file as stored, plus a token that changes whenever it does.
class RemoteDoc {
  const RemoteDoc(this.text, this.version);

  final String text;
  final String version;
}

/// Another device wrote the file between our read and our write.
class SyncConflict implements Exception {
  const SyncConflict();
}

/// Where the one shared sync file lives: Google Drive's app folder on
/// Android, an iCloud container on iOS.
abstract class SyncBackend {
  /// Shown in settings, e.g. "Google Drive".
  String get label;

  /// Why sync cannot work in this build (missing configuration), or null.
  String? get unavailableReason;

  /// Signs in if needed. Needs the user present; throws [SyncException] if
  /// they decline.
  Future<void> connect();

  /// Null when nothing has been uploaded yet.
  Future<RemoteDoc?> read();

  /// Replaces the file. Throws [SyncConflict] if [ifVersion] no longer
  /// matches what is stored (null means "expect no file").
  Future<void> write(String text, {String? ifVersion});

  /// Called when the user turns sync off; forgets any sign-in.
  Future<void> signOut();
}

/// A [SyncBackend] held in memory, for tests and for two-device simulations.
class MemorySyncBackend implements SyncBackend {
  @override
  String get label => 'Memory';

  @override
  String? get unavailableReason => null;

  /// Set to make [connect] fail, like a declined sign-in.
  String? connectError;

  @override
  Future<void> connect() async {
    final error = connectError;
    if (error != null) throw SyncException(error);
  }

  /// Set to make [read] and [write] fail, like a dropped connection.
  String? networkError;

  String? text;
  int _version = 0;

  /// Runs once, just before the next write, to simulate another device
  /// getting in first.
  void Function()? beforeNextWrite;

  @override
  Future<RemoteDoc?> read() async {
    if (networkError != null) throw SyncException(networkError!);
    return text == null ? null : RemoteDoc(text!, '$_version');
  }

  @override
  Future<void> write(String newText, {String? ifVersion}) async {
    if (networkError != null) throw SyncException(networkError!);
    final hook = beforeNextWrite;
    beforeNextWrite = null;
    hook?.call();
    final current = text == null ? null : '$_version';
    if (current != ifVersion) throw const SyncConflict();
    text = newText;
    _version++;
  }

  /// Replaces the file as if another device had written it.
  void overwrite(String newText) {
    text = newText;
    _version++;
  }

  @override
  Future<void> signOut() async {}

  SyncSnapshot? get snapshot => text == null ? null : SyncSnapshot.decode(text!);
}
