import 'tools.dart';

/// What a result is, which decides its tag in Recientes and the steps it
/// offers next. Several kinds come from the same tool (Organizar).
enum ResultKind {
  merged(ToolId.merge),
  edited(ToolId.organize),
  extracted(ToolId.organize),
  split(ToolId.organize),
  images(ToolId.pdfToImage),
  reduced(ToolId.reduce),
  scanned(ToolId.scan),
  photos(ToolId.imagesToPdf);

  const ResultKind(this.tool);

  final ToolId tool;

  /// Whether the result is one PDF that other tools can take as input.
  bool get isSinglePdf => this != split && this != images;
}

/// A finished result kept in the app (PRD RN-06): deleted automatically after
/// the configured period unless the user saves it elsewhere. Most results are
/// one file; Separar and PDF a imagen produce several, kept in one folder.
class RecentItem {
  const RecentItem({
    required this.id,
    required this.name,
    required this.dir,
    required this.files,
    required this.kind,
    required this.pages,
    required this.sizeBytes,
    required this.createdAt,
    this.inputBytes,
    this.targetBytes,
  });

  final String id;

  /// Name shown to the user: the file name of a single result, or the name
  /// of the set («contrato (separado)») when there are several files.
  final String name;

  /// Folder holding [files].
  final String dir;

  /// File names inside [dir], in order.
  final List<String> files;
  final ResultKind kind;
  final int pages;

  /// Total size of [files].
  final int sizeBytes;

  /// Total size of what went in, for «antes → después».
  final int? inputBytes;

  /// «Ajustar a X MB»: the size asked for. The result met it when
  /// [sizeBytes] is not above it.
  final int? targetBytes;
  final DateTime createdAt;

  bool get metTarget => targetBytes == null || sizeBytes <= targetBytes!;

  /// The first (usually the only) file.
  String get path => '$dir/${files.first}';
  List<String> get paths => [for (final f in files) '$dir/$f'];
  bool get isSingleFile => files.length == 1;

  RecentItem copyWith({String? name, List<String>? files}) => RecentItem(
    id: id,
    name: name ?? this.name,
    dir: dir,
    files: files ?? this.files,
    kind: kind,
    pages: pages,
    sizeBytes: sizeBytes,
    inputBytes: inputBytes,
    targetBytes: targetBytes,
    createdAt: createdAt,
  );

  /// Time left before the purge removes it; null when results never expire.
  Duration? remaining(DateTime now, Duration? period) => period == null ? null : createdAt.add(period).difference(now);
}

/// Where a new result is written before it is registered. Single-file tools
/// write [path]; multi-file tools write any names into [dir].
class ResultSlot {
  const ResultSlot({required this.id, required this.dir, required this.name});

  final String id;
  final String dir;

  /// Unique among current results.
  final String name;

  String get path => '$dir/$name';
}

abstract interface class RecentsRepository {
  /// Current items, newest first; emits again on every change.
  Stream<List<RecentItem>> watch();
  List<RecentItem> get current;

  /// Reserves a folder for a result called [name] (made unique if taken).
  Future<ResultSlot> reserve(String name);

  /// Registers what was written in [slot]: [files] names inside its folder,
  /// or the single file at [ResultSlot.path] when omitted.
  Future<RecentItem> add(
    ResultSlot slot, {
    required ResultKind kind,
    required int pages,
    int? inputBytes,
    int? targetBytes,
    List<String>? files,
  });

  /// Deletes a reserved slot that was never added (failed or cancelled job).
  Future<void> discard(ResultSlot slot);

  /// Renames a single-file result.
  Future<RecentItem> rename(String id, String newName);
  Future<void> remove(String id);

  /// Removes results older than [period]; does nothing when it is null.
  Future<int> purgeExpired(DateTime now, Duration? period);

  /// How many results and bytes [purgeExpired] would remove right now.
  (int, int) expiring(DateTime now, Duration? period);
  Future<int> clear();
}
