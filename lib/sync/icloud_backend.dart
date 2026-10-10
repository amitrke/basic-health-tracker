import 'package:flutter/services.dart';

import 'sync_backend.dart';
import 'sync_snapshot.dart';

/// The sync file in the app's iCloud container, through `ios/Runner/ICloudSync.swift`.
/// iCloud carries it to the user's other Apple devices.
class ICloudSyncBackend implements SyncBackend {
  ICloudSyncBackend([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('wellbite/icloud');

  final MethodChannel _channel;

  @override
  String get label => 'iCloud';

  @override
  String? get unavailableReason => null;

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw SyncException(e.message ?? 'iCloud failed.');
    } on MissingPluginException {
      throw const SyncException('iCloud is not available in this build.');
    }
  }

  /// There is no sign-in to show: iCloud uses the device's account. This just
  /// explains what to fix when it is off.
  @override
  Future<void> connect() async {
    switch (await _call<String>('status')) {
      case 'ok':
        return;
      case 'signedOut':
        throw const SyncException(
          'Sign in to iCloud in the Settings app, and turn on iCloud Drive.',
        );
      default:
        throw const SyncException(
          'iCloud is not available. Check iCloud Drive is on for this app.',
        );
    }
  }

  @override
  Future<RemoteDoc?> read() async {
    final reply = await _call<Map<Object?, Object?>>('read');
    if (reply == null) return null;
    return RemoteDoc(reply['text']! as String, reply['version']! as String);
  }

  @override
  Future<void> write(String text, {String? ifVersion}) async {
    final outcome = await _call<String>('write', {
      'text': text,
      'ifVersion': ifVersion,
    });
    if (outcome == 'conflict') throw const SyncConflict();
  }

  /// Nothing to sign out of; the file stays in iCloud for other devices.
  @override
  Future<void> signOut() async {}
}
