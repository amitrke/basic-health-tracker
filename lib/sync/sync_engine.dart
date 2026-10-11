import 'sync_backend.dart';
import 'sync_snapshot.dart';
import 'sync_store.dart';

enum SyncOutcome { unchanged, uploaded }

/// One sync: download, merge into the local database, upload if that changed
/// anything. Merging is idempotent, so a lost race just costs another round.
class SyncEngine {
  SyncEngine(this.store, this.backend);

  final SyncStore store;
  final SyncBackend backend;

  static const _attempts = 3;

  Future<SyncOutcome> sync({required bool firstSync}) async {
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final remote = await backend.read();
      SyncSnapshot? remoteSnapshot;
      if (remote != null) {
        remoteSnapshot = SyncSnapshot.decode(remote.text);
        await store.apply(remoteSnapshot, firstSync: firstSync);
      }
      final local = (await store.export()).encode();
      if (remoteSnapshot != null && remoteSnapshot.encode() == local) {
        return SyncOutcome.unchanged;
      }
      try {
        await backend.write(local, ifVersion: remote?.version);
        return SyncOutcome.uploaded;
      } on SyncConflict {
        continue;
      }
    }
    throw const SyncException('Sync is busy on another device. Try again.');
  }
}
