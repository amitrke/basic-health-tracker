import 'package:drift/drift.dart';

import '../data/database.dart';
import 'sync_snapshot.dart';

const _templates = 'meal_templates';
const _items = 'template_items';

/// What two rows must share to be the same thing logged on two devices. Names
/// are unique in the schema, so those always match; the rest only match the
/// first time a device syncs, to pair up data that existed before sync did.
class _Spec {
  const _Spec(this.key, {this.alwaysMatch = false});

  final String? Function(Map<String, Object?> row) key;
  final bool alwaysMatch;
}

String? _name(Map<String, Object?> r) => (r['name'] as String?)?.toLowerCase();

final _specs = <String, _Spec>{
  'food_entries': _Spec(
    (r) => '${_name(r)}|${r['meal_type']}|${r['logged_at']}',
  ),
  'saved_foods': _Spec(_name, alwaysMatch: true),
  _templates: _Spec(_name, alwaysMatch: true),
  'weight_entries': _Spec((r) => '${r['measured_at']}|${r['kg']}'),
};

/// How long a delete is remembered. A device offline for longer than this
/// could bring a deleted row back.
const _tombstoneKeep = Duration(days: 365);

/// Reads and writes the synced tables as plain maps. Raw SQL on purpose: the
/// column lists are discovered, so a column added later syncs automatically.
class SyncStore {
  SyncStore(this.db);

  final AppDatabase db;
  final _columns = <String, Set<String>>{};

  Future<Set<String>> _columnsOf(String table) async => _columns[table] ??=
      (await db
              .customSelect('PRAGMA table_info($table)')
              .map((r) => r.read<String>('name'))
              .get())
          .toSet();

  TableInfo _info(String table) =>
      db.allTables.firstWhere((t) => t.actualTableName == table);

  Variable<Object> _v(Object? value) => Variable<Object>(value);

  Future<List<Map<String, Object?>>> _rows(
    String sql, [
    List<Object?> args = const [],
  ]) => db
      .customSelect(sql, variables: [for (final a in args) _v(a)])
      .map((r) => Map<String, Object?>.of(r.data))
      .get();

  Future<SyncSnapshot> export() async {
    final snapshot = SyncSnapshot();
    for (final table in AppDatabase.syncedTables) {
      final rows = await _rows('SELECT * FROM $table');
      final out = <Map<String, Object?>>[];
      for (final row in rows) {
        final id = row.remove('id');
        if (table == _templates) {
          final items = await _rows(
            'SELECT * FROM $_items WHERE template_id = ? ORDER BY id',
            [id],
          );
          row['items'] = [
            for (final i in items) (i..remove('id')..remove('template_id')),
          ];
        }
        out.add(row);
      }
      snapshot.tables[table] = out;
    }
    snapshot.tombstones.addAll(
      await _rows('SELECT uuid, kind, deleted_at FROM sync_tombstones'),
    );
    return snapshot;
  }

  /// Folds [remote] into the local database. Newer wins per row; a delete
  /// wins over edits made before it.
  Future<void> apply(SyncSnapshot remote, {required bool firstSync}) =>
      db.transaction(() async {
        final tombstones = await _applyTombstones(remote.tombstones);
        for (final table in AppDatabase.syncedTables) {
          await _applyRows(
            table,
            remote.tables[table] ?? const [],
            tombstones,
            firstSync: firstSync,
          );
        }
        final cutoff =
            DateTime.now().subtract(_tombstoneKeep).millisecondsSinceEpoch ~/
            1000;
        await db.customUpdate(
          'DELETE FROM sync_tombstones WHERE deleted_at < ?',
          variables: [_v(cutoff)],
          updates: {db.syncTombstones},
          updateKind: UpdateKind.delete,
        );
      });

  /// Returns uuid -> deleted_at after merging in [incoming].
  Future<Map<String, int>> _applyTombstones(
    List<Map<String, Object?>> incoming,
  ) async {
    final known = {
      for (final t in await _rows(
        'SELECT uuid, deleted_at FROM sync_tombstones',
      ))
        t['uuid'] as String: t['deleted_at'] as int,
    };
    for (final t in incoming) {
      final uuid = t['uuid'] as String?;
      final kind = t['kind'] as String?;
      final at = t['deleted_at'] as int?;
      // `kind` becomes a table name below, so only known ones get through.
      if (uuid == null ||
          at == null ||
          !AppDatabase.syncedTables.contains(kind)) {
        continue;
      }
      final local = await _rows('SELECT updated_at FROM $kind WHERE uuid = ?', [
        uuid,
      ]);
      var deletedAt = at;
      if (local.isNotEmpty) {
        // Edited after it was deleted elsewhere: the edit wins.
        if ((local.first['updated_at'] as int) > at) continue;
        await _deleteRow(kind!, uuid);
      } else if ((known[uuid] ?? 0) > at) {
        deletedAt = known[uuid]!;
      }
      known[uuid] = deletedAt;
      await db.customUpdate(
        'INSERT OR REPLACE INTO sync_tombstones(uuid, kind, deleted_at) '
        'VALUES (?, ?, ?)',
        variables: [_v(uuid), _v(kind), _v(deletedAt)],
        updates: {db.syncTombstones},
        updateKind: UpdateKind.insert,
      );
    }
    return known;
  }

  Future<void> _deleteRow(String table, String uuid) async {
    if (table == _templates) {
      await db.customUpdate(
        'DELETE FROM $_items WHERE template_id = '
        '(SELECT id FROM $_templates WHERE uuid = ?)',
        variables: [_v(uuid)],
        updates: {db.templateItems},
        updateKind: UpdateKind.delete,
      );
    }
    await db.customUpdate(
      'DELETE FROM $table WHERE uuid = ?',
      variables: [_v(uuid)],
      updates: {_info(table)},
      updateKind: UpdateKind.delete,
    );
  }

  Future<void> _applyRows(
    String table,
    List<Map<String, Object?>> remoteRows,
    Map<String, int> tombstones, {
    required bool firstSync,
  }) async {
    final spec = _specs[table]!;
    final matching = spec.alwaysMatch || firstSync;
    final local = {
      for (final r in await _rows('SELECT * FROM $table'))
        r['uuid'] as String: r,
    };
    final remoteUuids = {for (final r in remoteRows) r['uuid']};
    // Local rows free to be paired with a remote row of the same key.
    final unclaimed = <String, List<Map<String, Object?>>>{};
    if (matching) {
      for (final r in local.values) {
        if (remoteUuids.contains(r['uuid'])) continue;
        final k = spec.key(r);
        if (k != null) unclaimed.putIfAbsent(k, () => []).add(r);
      }
    }

    for (final r in remoteRows) {
      final uuid = r['uuid'] as String?;
      final updated = r['updated_at'] as int?;
      if (uuid == null || updated == null) continue;
      final deletedAt = tombstones[uuid];
      if (deletedAt != null && deletedAt >= updated) continue;

      final mine = local[uuid];
      try {
        if (mine != null) {
          if (updated > (mine['updated_at'] as int)) {
            await _update(table, mine['id'] as int, r);
          }
          continue;
        }
        final key = matching ? spec.key(r) : null;
        final twins = key == null ? null : unclaimed[key];
        final twin = twins == null || twins.isEmpty ? null : twins.removeLast();
        if (twin != null) {
          // The device that syncs second adopts the id already in the file,
          // so every device ends up agreeing without a tie-break.
          final id = twin['id'] as int;
          if (updated > (twin['updated_at'] as int)) {
            await _update(table, id, r);
          } else {
            await _setUuid(table, id, uuid, twin['updated_at'] as int);
          }
          continue;
        }
        await _insert(table, r);
      } on Exception {
        // One bad row (say a clashing name) must not block the rest.
        continue;
      }
    }
  }

  Future<(List<String>, List<Object?>)> _writable(
    String table,
    Map<String, Object?> row,
  ) async {
    final known = await _columnsOf(table);
    final cols = <String>[];
    final vals = <Object?>[];
    row.forEach((k, v) {
      if (k == 'id' || k == 'items' || !known.contains(k)) return;
      cols.add(k);
      vals.add(v);
    });
    return (cols, vals);
  }

  Future<void> _insert(String table, Map<String, Object?> row) async {
    final (cols, vals) = await _writable(table, row);
    await db.customUpdate(
      'INSERT INTO $table (${cols.join(', ')}) '
      'VALUES (${List.filled(cols.length, '?').join(', ')})',
      variables: [for (final v in vals) _v(v)],
      updates: {_info(table)},
      updateKind: UpdateKind.insert,
    );
    if (table == _templates) {
      final created = await _rows('SELECT id FROM $table WHERE uuid = ?', [
        row['uuid'],
      ]);
      await _replaceItems(created.first['id'] as int, row['items']);
    }
  }

  Future<void> _update(String table, int id, Map<String, Object?> row) async {
    final (cols, vals) = await _writable(table, row);
    await db.customUpdate(
      'UPDATE $table SET ${cols.map((c) => '$c = ?').join(', ')} WHERE id = ?',
      variables: [for (final v in vals) _v(v), _v(id)],
      updates: {_info(table)},
      updateKind: UpdateKind.update,
    );
    if (table == _templates) await _replaceItems(id, row['items']);
  }

  /// Adopts [uuid] without touching the data. Keeps the old timestamp, or the
  /// trigger would stamp it as a fresh edit.
  Future<void> _setUuid(String table, int id, String uuid, int updated) async {
    await db.customUpdate(
      'UPDATE $table SET uuid = ?, updated_at = ? WHERE id = ?',
      variables: [_v(uuid), _v(updated), _v(id)],
      updates: {_info(table)},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> _replaceItems(int templateId, Object? items) async {
    await db.customUpdate(
      'DELETE FROM $_items WHERE template_id = ?',
      variables: [_v(templateId)],
      updates: {db.templateItems},
      updateKind: UpdateKind.delete,
    );
    final known = await _columnsOf(_items);
    for (final raw in (items as List? ?? const [])) {
      final item = (raw as Map).cast<String, Object?>();
      final cols = [
        'template_id',
        ...item.keys.where(
          (k) => k != 'id' && k != 'template_id' && known.contains(k),
        ),
      ];
      final vals = [templateId, ...cols.skip(1).map((c) => item[c])];
      await db.customUpdate(
        'INSERT INTO $_items (${cols.join(', ')}) '
        'VALUES (${List.filled(cols.length, '?').join(', ')})',
        variables: [for (final v in vals) _v(v)],
        updates: {db.templateItems},
        updateKind: UpdateKind.insert,
      );
    }
  }
}
