import 'tools.dart';

/// A finished result kept in the app (PRD RN-06): deleted automatically after
/// the configured period unless the user saves it elsewhere.
class RecentItem {
  const RecentItem({
    required this.id,
    required this.name,
    required this.path,
    required this.tool,
    required this.pages,
    required this.sizeBytes,
    required this.createdAt,
    this.inputBytes,
  });

  final String id;

  /// File name shown to the user and to apps it is shared with.
  final String name;
  final String path;
  final ToolId tool;
  final int pages;
  final int sizeBytes;

  /// Total size of what went in, for «antes → después».
  final int? inputBytes;
  final DateTime createdAt;

  RecentItem copyWith({String? name, String? path}) => RecentItem(
    id: id,
    name: name ?? this.name,
    path: path ?? this.path,
    tool: tool,
    pages: pages,
    sizeBytes: sizeBytes,
    inputBytes: inputBytes,
    createdAt: createdAt,
  );
}

/// Where a new result is written before it is registered.
class ResultSlot {
  const ResultSlot({required this.id, required this.path, required this.name});

  final String id;
  final String path;
  final String name;
}

abstract interface class RecentsRepository {
  /// Current items, newest first; emits again on every change.
  Stream<List<RecentItem>> watch();
  List<RecentItem> get current;

  /// Reserves a unique path for a result called [name] (made unique if taken).
  Future<ResultSlot> reserve(String name);

  /// Registers the file written at [slot] (the file must exist).
  Future<RecentItem> add(ResultSlot slot, {required ToolId tool, required int pages, int? inputBytes});

  /// Deletes a reserved slot that was never added (failed or cancelled job).
  Future<void> discard(ResultSlot slot);

  Future<RecentItem> rename(String id, String newName);
  Future<void> remove(String id);
  Future<int> purgeExpired(DateTime now, Duration ttl);
  Future<int> clear();
}
