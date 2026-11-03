import 'dart:async';
import 'dart:typed_data';

import 'package:fileflow/app/providers.dart';
import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/pdf.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/core/domain/result.dart';
import 'package:fileflow/core/domain/settings.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// In-memory fakes for widget tests (no disk, no platform channels).

class MemorySettings implements SettingsRepository {
  @override
  ThemePreference theme = ThemePreference.system;

  @override
  Future<void> setTheme(ThemePreference value) async => theme = value;

  @override
  RecentsRetention retention = RecentsRetention.sevenDays;

  @override
  Future<void> setRetention(RecentsRetention value) async => retention = value;
}

class FakeWorkspace implements JobWorkspace {
  final created = <JobDir>[];
  final deleted = <String>[];

  @override
  Future<JobDir> create() async {
    final job = JobDir(id: 'job${created.length}', inputDir: '/in', workDir: '/work');
    created.add(job);
    return job;
  }

  @override
  Future<void> delete(JobDir job) async => deleted.add(job.id);

  @override
  Future<String> resultsDir() async => '/results';

  @override
  Future<int> sweepLeftovers() async => 0;
}

/// Picks return [nextPick]; imports succeed unless the name is in [importFailures].
class FakeFileGateway implements FileGateway {
  List<PickedFile> nextPick = const [];
  final importFailures = <String, AppFailure>{};
  final shared = <List<LocalFile>>[];
  final savedAs = <String>[];
  final opened = <String>[];
  AppFailure? openFailure;

  @override
  Future<Result<List<PickedFile>>> pickPdfs({bool multiple = false}) async => Ok(nextPick);

  @override
  Future<Result<List<PickedFile>>> pickImages({int max = 100}) async => const Ok([]);

  @override
  Future<Result<LocalFile>> importToJob(PickedFile file, JobDir job, {CancelToken? token}) async {
    final failure = importFailures[file.name];
    if (failure != null) return Err(failure);
    return Ok(LocalFile(path: '${job.inputDir}/${file.name}', name: file.name, sizeBytes: file.sizeBytes ?? 0));
  }

  @override
  Future<Result<String?>> saveAs(LocalFile file, {required String suggestedName}) async {
    savedAs.add(suggestedName);
    return const Ok('content://saved');
  }

  @override
  Future<Result<int?>> saveAllToFolder(List<LocalFile> files, {required List<String> names}) async => Ok(files.length);

  @override
  Future<Result<void>> share(List<LocalFile> files) async {
    shared.add(files);
    return const Ok(null);
  }

  @override
  Future<Result<void>> openWith(LocalFile file) async {
    opened.add(file.name);
    final failure = openFailure;
    return failure == null ? const Ok(null) : Err(failure);
  }

  @override
  Stream<List<PickedFile>> incomingShares() => const Stream.empty();
}

/// Page counts by file name (the last path segment); a failure instead when
/// listed in [failures].
class FakePdfService implements PdfService {
  FakePdfService({this.pages = const {}, this.failures = const {}});

  final Map<String, int> pages;
  final Map<String, AppFailure> failures;
  final merges = <List<String>>[];

  /// When set, merge fails with it after the first input.
  AppFailure? mergeFailure;

  String _name(String path) => path.split('/').last;

  @override
  Future<Result<PdfSummary>> inspect(String path) async {
    final failure = failures[_name(path)];
    if (failure != null) return Err(failure);
    return Ok(PdfSummary(pageCount: pages[_name(path)] ?? 1, looksTextOnly: false));
  }

  @override
  Future<Result<int>> merge(
    List<String> inputs,
    String output, {
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  }) async {
    merges.add(inputs);
    for (var i = 0; i < inputs.length; i++) {
      if (token?.isCancelled ?? false) return const Err(Cancelled());
      final failure = mergeFailure;
      if (failure != null) return Err(failure);
      onProgress?.call(i + 1, inputs.length + 1);
    }
    onProgress?.call(inputs.length + 1, inputs.length + 1);
    return Ok(inputs.fold(0, (sum, p) => sum + (pages[_name(p)] ?? 1)));
  }

  /// (input, pages, output) of every compose call.
  final composed = <(String, List<PageRef>, String)>[];

  @override
  Future<Result<int>> compose(
    String input,
    List<PageRef> pages,
    String output, {
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  }) async {
    if (token?.isCancelled ?? false) return const Err(Cancelled());
    final failure = mergeFailure;
    if (failure != null) return Err(failure);
    composed.add((input, pages, output));
    onProgress?.call(1, 1);
    return Ok(pages.length);
  }

  /// (pages, outputs, format, dpi) of every export call.
  final exported = <(List<int>, List<String>, ImageFormat, int)>[];

  @override
  Future<Result<int>> exportImages(
    String input,
    List<int> pages,
    List<String> outputs, {
    required ImageFormat format,
    required int dpi,
    CancelToken? token,
    void Function(int done, int total)? onProgress,
  }) async {
    exported.add((pages, outputs, format, dpi));
    for (var i = 0; i < pages.length; i++) {
      if (token?.isCancelled ?? false) return const Err(Cancelled());
      onProgress?.call(i + 1, pages.length);
    }
    return Ok(pages.length * 1000);
  }
}

/// Thumbnails that never arrive: tiles keep their numbered placeholder.
class FakeThumbnailSource implements ThumbnailSource {
  @override
  Future<Result<Thumbnails>> open(String path) async => Ok(_NoThumbnails(pages: 1));
}

class _NoThumbnails implements Thumbnails {
  _NoThumbnails({required this.pages});

  final int pages;

  @override
  int get pageCount => pages;

  @override
  Future<Uint8List?> page(int index) async => null;

  @override
  void cancel(int index) {}

  @override
  Future<void> close() async {}
}

class MemoryRecents implements RecentsRepository {
  MemoryRecents([List<RecentItem> items = const []]) : _items = [...items];

  List<RecentItem> _items;
  final _changes = StreamController<List<RecentItem>>.broadcast();
  final discarded = <String>[];

  @override
  List<RecentItem> get current => List.unmodifiable(_items);

  @override
  Stream<List<RecentItem>> watch() async* {
    yield current;
    yield* _changes.stream;
  }

  void _emit() => _changes.add(current);

  @override
  Future<ResultSlot> reserve(String name) async =>
      ResultSlot(id: 'r${_items.length}', dir: '/results/r${_items.length}', name: name);

  @override
  Future<RecentItem> add(
    ResultSlot slot, {
    required ResultKind kind,
    required int pages,
    int? inputBytes,
    List<String>? files,
  }) async {
    final item = RecentItem(
      id: slot.id,
      name: slot.name,
      dir: slot.dir,
      files: files ?? [slot.name],
      kind: kind,
      pages: pages,
      sizeBytes: 1024 * 1024,
      inputBytes: inputBytes,
      createdAt: DateTime(2026, 11, 3, 12),
    );
    _items = [item, ..._items];
    _emit();
    return item;
  }

  @override
  Future<void> discard(ResultSlot slot) async => discarded.add(slot.id);

  @override
  Future<RecentItem> rename(String id, String newName) async {
    final item = _items.firstWhere((i) => i.id == id).copyWith(name: newName, files: [newName]);
    _items = [for (final i in _items) i.id == id ? item : i];
    _emit();
    return item;
  }

  @override
  Future<void> remove(String id) async {
    _items = [
      for (final i in _items)
        if (i.id != id) i,
    ];
    _emit();
  }

  bool _expired(RecentItem i, DateTime now, Duration? period) =>
      period != null && !now.isBefore(i.createdAt.add(period));

  @override
  Future<int> purgeExpired(DateTime now, Duration? period) async {
    final before = _items.length;
    _items = [
      for (final i in _items)
        if (!_expired(i, now, period)) i,
    ];
    if (_items.length != before) _emit();
    return before - _items.length;
  }

  @override
  (int, int) expiring(DateTime now, Duration? period) {
    final expired = _items.where((i) => _expired(i, now, period));
    return (expired.length, expired.fold(0, (sum, i) => sum + i.sizeBytes));
  }

  @override
  Future<int> clear() async {
    final n = _items.length;
    _items = [];
    _emit();
    return n;
  }
}

/// The fixed «now» of widget tests (see [fakeOverrides]).
final testNow = DateTime(2026, 11, 3, 12);

RecentItem sampleRecent({
  String id = 'r1',
  String name = 'Documento unido 2026-11-03.pdf',
  int pages = 14,
  ResultKind kind = ResultKind.merged,
  List<String>? files,
  DateTime? createdAt,
  int sizeBytes = 7969177,
}) => RecentItem(
  id: id,
  name: name,
  dir: '/results/$id',
  files: files ?? [name],
  kind: kind,
  pages: pages,
  sizeBytes: sizeBytes,
  createdAt: createdAt ?? DateTime(2026, 11, 3, 10),
);

/// Every port overridden with a fake; pass the ones a test inspects.
List<Override> fakeOverrides({
  MemorySettings? settings,
  FakeFileGateway? files,
  FakePdfService? pdf,
  MemoryRecents? recents,
  FakeWorkspace? workspace,
  int interrupted = 0,
}) => [
  settingsRepositoryProvider.overrideWithValue(settings ?? MemorySettings()),
  fileGatewayProvider.overrideWithValue(files ?? FakeFileGateway()),
  pdfServiceProvider.overrideWithValue(pdf ?? FakePdfService()),
  recentsRepositoryProvider.overrideWithValue(recents ?? MemoryRecents()),
  jobWorkspaceProvider.overrideWithValue(workspace ?? FakeWorkspace()),
  interruptedJobsProvider.overrideWithValue(interrupted),
  thumbnailSourceProvider.overrideWithValue(FakeThumbnailSource()),
  clockProvider.overrideWithValue(() => testNow),
];
