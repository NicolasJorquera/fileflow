import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/domain/files.dart';
import '../../core/domain/recents.dart';

/// Recientes as an index file (`files/recents.json`) plus one folder per result
/// under `files/results/<id>/`. Files keep their user-facing names, which is
/// what other apps see when they are shared. Writes are atomic (temporary file
/// + rename) so a crash never corrupts the index.
class JsonRecentsRepository implements RecentsRepository {
  JsonRecentsRepository._(this._indexFile, this._resultsDir, this._items, this._clock);

  static const _version = 2;

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
        items = [];
      } on TypeError {
        // A damaged index loses the list, never the app; the orphan sweep
        // below then removes the files it pointed to.
        items = [];
      }
    }
    // Drop entries with a missing file, and folders no entry owns: a job the
    // system killed after reserving its slot (RF-08).
    items = [
      for (final i in items)
        if (i.paths.every((p) => File(p).existsSync())) i,
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
  Stream<List<RecentItem>> watch() {
    // Subscribed to changes in onListen, before anything can happen: an
    // async* generator would miss a change made between its first yield and
    // its subscription.
    StreamSubscription<List<RecentItem>>? changes;
    late final StreamController<List<RecentItem>> out;
    out = StreamController<List<RecentItem>>(
      onListen: () {
        out.add(current);
        changes = _changes.stream.listen(out.add);
      },
      onCancel: () => changes?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<ResultSlot> reserve(String name) async {
    final id = '${_clock().microsecondsSinceEpoch}_${_counter++}';
    final dir = Directory('$_resultsDir/$id');
    await dir.create(recursive: true);
    return ResultSlot(id: id, dir: dir.path, name: _uniqueName(_safe(name)));
  }

  @override
  Future<RecentItem> add(
    ResultSlot slot, {
    required ResultKind kind,
    required int pages,
    int? inputBytes,
    int? targetBytes,
    List<String>? files,
  }) async {
    final names = files ?? [slot.name];
    var size = 0;
    for (final f in names) {
      size += await File('${slot.dir}/$f').length();
    }
    final item = RecentItem(
      id: slot.id,
      name: slot.name,
      dir: slot.dir,
      files: names,
      kind: kind,
      pages: pages,
      sizeBytes: size,
      inputBytes: inputBytes,
      targetBytes: targetBytes,
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
    if (!item.isSingleFile) throw StateError('only single-file results can be renamed');
    final safe = _safe(newName);
    if (safe == item.name) return item;
    final renamed = item.copyWith(name: safe, files: [safe]);
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

  bool _expired(RecentItem i, DateTime now, Duration? period) =>
      period != null && !now.isBefore(i.createdAt.add(period));

  @override
  (int, int) expiring(DateTime now, Duration? period) {
    final expired = _items.where((i) => _expired(i, now, period));
    return (expired.length, expired.fold(0, (sum, i) => sum + i.sizeBytes));
  }

  @override
  Future<int> purgeExpired(DateTime now, Duration? period) async {
    final expired = [
      for (final i in _items)
        if (_expired(i, now, period)) i,
    ];
    for (final i in expired) {
      await _deleteFolder(i.id);
    }
    if (expired.isNotEmpty) {
      _items = [
        for (final i in _items)
          if (!_expired(i, now, period)) i,
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
        'version': _version,
        'items': [for (final i in _items) _toJson(i)],
      }),
      flush: true,
    );
    await tmp.rename(_indexFile.path);
    _changes.add(current);
  }

  static String _safe(String name) => safeFileName(name);

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
    'files': i.files,
    'kind': i.kind.name,
    'pages': i.pages,
    'sizeBytes': i.sizeBytes,
    'inputBytes': i.inputBytes,
    'targetBytes': i.targetBytes,
    'createdAt': i.createdAt.toUtc().toIso8601String(),
  };

  /// Version 1 (H4) had one file named like the item and only merge results.
  static RecentItem _fromJson(Map<String, Object?> j, String resultsDir) => RecentItem(
    id: j['id']! as String,
    name: j['name']! as String,
    dir: '$resultsDir/${j['id']}',
    files: [
      for (final f in (j['files'] as List<Object?>?) ?? [j['name']]) f! as String,
    ],
    kind: ResultKind.values.asNameMap()[j['kind']] ?? ResultKind.merged,
    pages: j['pages']! as int,
    sizeBytes: j['sizeBytes']! as int,
    inputBytes: j['inputBytes'] as int?,
    targetBytes: j['targetBytes'] as int?,
    createdAt: DateTime.parse(j['createdAt']! as String).toLocal(),
  );
}
