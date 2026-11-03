import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/domain/recents.dart';
import '../../core/domain/tools.dart';

/// Recientes as an index file (`files/recents.json`) plus one folder per result
/// under `files/results/<id>/<name>`. The folder keeps the user-facing name,
/// which is what other apps see when the file is shared. Writes are atomic
/// (temporary file + rename) so a crash never corrupts the index.
class JsonRecentsRepository implements RecentsRepository {
  JsonRecentsRepository._(this._indexFile, this._resultsDir, this._items, this._clock);

  static Future<JsonRecentsRepository> open({
    required String filesDir,
    required String resultsDir,
    DateTime Function()? clock,
  }) async {
    final index = File('$filesDir/recents.json');
    var items = <RecentItem>[];
    if (await index.exists()) {
      try {
        final json = jsonDecode(await index.readAsString()) as Map<String, Object?>;
        items = [for (final e in json['items']! as List<Object?>) _fromJson(e! as Map<String, Object?>, resultsDir)];
      } on FormatException {
        // A damaged index loses the list, never the app: results stay on disk
        // until the purge or "Borrar todo" removes them.
        items = [];
      }
    }
    // Drop entries whose file disappeared, and folders no entry owns: a job the
    // system killed after reserving its slot (RF-08).
    items = [
      for (final i in items)
        if (File(i.path).existsSync()) i,
    ];
    final owned = {for (final i in items) i.id};
    final root = Directory(resultsDir);
    if (await root.exists()) {
      await for (final entry in root.list()) {
        if (!owned.contains(entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty))) {
          await entry.delete(recursive: true);
        }
      }
    }
    return JsonRecentsRepository._(index, resultsDir, items, clock ?? DateTime.now);
  }

  final File _indexFile;
  final String _resultsDir;
  final DateTime Function() _clock;
  List<RecentItem> _items;
  final _changes = StreamController<List<RecentItem>>.broadcast();
  var _counter = 0;

  @override
  List<RecentItem> get current => List.unmodifiable(_items);

  @override
  Stream<List<RecentItem>> watch() async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  Future<ResultSlot> reserve(String name) async {
    final id = '${_clock().microsecondsSinceEpoch}_${_counter++}';
    final dir = Directory('$_resultsDir/$id');
    await dir.create(recursive: true);
    final safe = _uniqueName(_safe(name));
    return ResultSlot(id: id, path: '${dir.path}/$safe', name: safe);
  }

  @override
  Future<RecentItem> add(ResultSlot slot, {required ToolId tool, required int pages, int? inputBytes}) async {
    final item = RecentItem(
      id: slot.id,
      name: slot.name,
      path: slot.path,
      tool: tool,
      pages: pages,
      sizeBytes: await File(slot.path).length(),
      inputBytes: inputBytes,
      createdAt: _clock(),
    );
    _items = [item, ..._items];
    await _save();
    return item;
  }

  @override
  Future<void> discard(ResultSlot slot) => _deleteFolder(slot.id);

  @override
  Future<RecentItem> rename(String id, String newName) async {
    final item = _items.firstWhere((i) => i.id == id);
    final safe = _safe(newName);
    if (safe == item.name) return item;
    final renamed = item.copyWith(name: safe, path: '${File(item.path).parent.path}/$safe');
    await File(item.path).rename(renamed.path);
    _items = [for (final i in _items) i.id == id ? renamed : i];
    await _save();
    return renamed;
  }

  @override
  Future<void> remove(String id) async {
    _items = [
      for (final i in _items)
        if (i.id != id) i,
    ];
    await _deleteFolder(id);
    await _save();
  }

  @override
  Future<int> purgeExpired(DateTime now, Duration ttl) async {
    final expired = [
      for (final i in _items)
        if (now.difference(i.createdAt) >= ttl) i,
    ];
    for (final i in expired) {
      await _deleteFolder(i.id);
    }
    if (expired.isNotEmpty) {
      _items = [
        for (final i in _items)
          if (now.difference(i.createdAt) < ttl) i,
      ];
      await _save();
    }
    return expired.length;
  }

  @override
  Future<int> clear() async {
    final count = _items.length;
    final root = Directory(_resultsDir);
    if (await root.exists()) await root.delete(recursive: true);
    await root.create(recursive: true);
    _items = [];
    await _save();
    return count;
  }

  Future<void> _deleteFolder(String id) async {
    final dir = Directory('$_resultsDir/$id');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> _save() async {
    final tmp = File('${_indexFile.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'version': 1,
        'items': [for (final i in _items) _toJson(i)],
      }),
      flush: true,
    );
    await tmp.rename(_indexFile.path);
    _changes.add(current);
  }

  /// Names come from people and other apps: keep them readable, never a path.
  static String _safe(String name) {
    var s = name.replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f]'), '_').trim();
    if (s.isEmpty) s = 'documento.pdf';
    return s.length > 120 ? s.substring(0, 120) : s;
  }

  /// «Documento unido.pdf», «Documento unido (2).pdf»… among current results.
  String _uniqueName(String name) {
    final taken = {for (final i in _items) i.name.toLowerCase()};
    if (!taken.contains(name.toLowerCase())) return name;
    final dot = name.lastIndexOf('.');
    final (stem, ext) = dot > 0 ? (name.substring(0, dot), name.substring(dot)) : (name, '');
    for (var n = 2; ; n++) {
      final candidate = '$stem ($n)$ext';
      if (!taken.contains(candidate.toLowerCase())) return candidate;
    }
  }

  static Map<String, Object?> _toJson(RecentItem i) => {
    'id': i.id,
    'name': i.name,
    'tool': i.tool.name,
    'pages': i.pages,
    'sizeBytes': i.sizeBytes,
    'inputBytes': i.inputBytes,
    'createdAt': i.createdAt.toUtc().toIso8601String(),
  };

  static RecentItem _fromJson(Map<String, Object?> j, String resultsDir) => RecentItem(
    id: j['id']! as String,
    name: j['name']! as String,
    path: '$resultsDir/${j['id']}/${j['name']}',
    tool: ToolId.values.byName(j['tool']! as String),
    pages: j['pages']! as int,
    sizeBytes: j['sizeBytes']! as int,
    inputBytes: j['inputBytes'] as int?,
    createdAt: DateTime.parse(j['createdAt']! as String).toLocal(),
  );
}
