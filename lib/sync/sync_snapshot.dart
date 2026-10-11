import 'dart:convert';

/// Bumped when the file layout changes in a way older apps cannot read.
const syncFormat = 1;

/// Everything one device knows, as plain JSON-ready maps. Row maps use the
/// SQL column names (minus `id`), so a column added later syncs without
/// changes here.
class SyncSnapshot {
  SyncSnapshot({
    this.format = syncFormat,
    Map<String, List<Map<String, Object?>>>? tables,
    List<Map<String, Object?>>? tombstones,
  }) : tables = tables ?? {},
       tombstones = tombstones ?? [];

  final int format;

  /// Table name -> rows, each with `uuid` and `updated_at` (unix seconds).
  /// Meal templates also carry their `items`.
  final Map<String, List<Map<String, Object?>>> tables;

  /// `{uuid, kind, deleted_at}`.
  final List<Map<String, Object?>> tombstones;

  /// Stable text for the same content: rows are sorted, so two devices with
  /// the same data produce the same string.
  String encode() {
    String key(Map<String, Object?> r) => '${r['uuid']}';
    final names = tables.keys.toList()..sort();
    return jsonEncode({
      'format': format,
      'tables': {
        for (final n in names)
          n: (tables[n]!.toList()..sort((a, b) => key(a).compareTo(key(b))))
              .map(_sortedKeys)
              .toList(),
      },
      'tombstones': (tombstones.toList()
            ..sort((a, b) => key(a).compareTo(key(b))))
          .map(_sortedKeys)
          .toList(),
    });
  }

  static Map<String, Object?> _sortedKeys(Map<String, Object?> m) {
    final keys = m.keys.toList()..sort();
    return {
      for (final k in keys)
        k: m[k] is Map<String, Object?>
            ? _sortedKeys(m[k] as Map<String, Object?>)
            : m[k] is List
            ? [
                for (final e in m[k] as List)
                  e is Map<String, Object?> ? _sortedKeys(e) : e,
              ]
            : m[k],
    };
  }

  static SyncSnapshot decode(String text) {
    final json = jsonDecode(text) as Map<String, Object?>;
    final format = json['format'] as int? ?? 0;
    if (format > syncFormat) {
      throw const SyncException(
        'The synced data was saved by a newer version of the app. '
        'Update this app to keep syncing.',
      );
    }
    final tables = <String, List<Map<String, Object?>>>{};
    final raw = (json['tables'] as Map?)?.cast<String, Object?>() ?? const {};
    raw.forEach((name, rows) {
      tables[name] = [
        for (final r in rows as List) (r as Map).cast<String, Object?>(),
      ];
    });
    return SyncSnapshot(
      format: format,
      tables: tables,
      tombstones: [
        for (final t in (json['tombstones'] as List? ?? const []))
          (t as Map).cast<String, Object?>(),
      ],
    );
  }
}

class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}
