import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/domain/failures.dart';
import '../../../../core/domain/files.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/domain/tools.dart';
import '../../../../core/jobs/jobs.dart';

/// One row of the Unir list: preparing (copying and reading), ready with its
/// page count, or marked with the reason it will be skipped.
class MergeItem {
  const MergeItem({required this.key, required this.name, this.file, this.pages, this.failure});

  final int key;
  final String name;
  final LocalFile? file;
  final int? pages;
  final AppFailure? failure;

  bool get isReady => file != null && pages != null;
  bool get isPreparing => failure == null && pages == null;

  MergeItem _ready(LocalFile file, int pages) => MergeItem(key: key, name: name, file: file, pages: pages);
  MergeItem _failed(AppFailure failure) => MergeItem(key: key, name: name, failure: failure);
}

class MergeState {
  const MergeState([this.items = const []]);

  final List<MergeItem> items;

  List<MergeItem> get ready => [
    for (final i in items)
      if (i.isReady) i,
  ];
  int get pages => ready.fold(0, (sum, i) => sum + i.pages!);
  int get bytes => ready.fold(0, (sum, i) => sum + i.file!.sizeBytes);
  int get skipped => items.where((i) => i.failure != null).length;
  bool get preparing => items.any((i) => i.isPreparing);
  bool get tooManyPages => pages > MergeLimits.maxPages;
  bool get isBig => bytes > MergeLimits.softTotalBytes;
  bool get canMerge => ready.length >= 2 && !preparing && !tooManyPages;
}

/// What Unir starts with: files shared to the app, or a previous result
/// («Siguiente paso → Unir con otro PDF»).
class MergeArgs {
  const MergeArgs({this.picked = const [], this.local = const []});

  final List<PickedFile> picked;
  final List<LocalFile> local;
}

final mergeControllerProvider = NotifierProvider.autoDispose<MergeController, MergeState>(MergeController.new);

/// State of the Unir screen. Inputs are copied into a job folder that lives as
/// long as this controller; while a merge runs the controller stays alive so
/// the folder is not deleted under the job.
class MergeController extends Notifier<MergeState> {
  final _imports = CancelToken();
  Future<JobDir>? _dir;
  Future<void> _queue = Future.value();
  var _nextKey = 0;

  @override
  MergeState build() {
    final workspace = ref.read(jobWorkspaceProvider);
    ref.onDispose(() {
      _imports.cancel();
      final dir = _dir;
      if (dir != null) _queue.whenComplete(() async => workspace.delete(await dir));
    });
    return const MergeState();
  }

  /// Opens the system picker. Returns the failure to show, if any (a cancelled
  /// picker is not one).
  Future<AppFailure?> pick() async => switch (await ref.read(fileGatewayProvider).pickPdfs(multiple: true)) {
    Ok(:final value) => addPicked(value),
    Err(:final failure) => failure,
  };

  /// Adds files chosen in a picker or shared from another app. Beyond
  /// [MergeLimits.maxFiles] the rest are left out and the limit is returned.
  AppFailure? addPicked(List<PickedFile> files) {
    final room = MergeLimits.maxFiles - state.items.length;
    for (final f in files.take(room)) {
      final item = _append(f.name);
      _enqueue(() => _import(item.key, f));
    }
    return files.length > room ? LimitExceeded(Limit.files, state.items.length + files.length - room) : null;
  }

  /// Adds files already in the app (a result from Recientes). They are read
  /// in place: merging never modifies its inputs.
  void addLocal(List<LocalFile> files) {
    for (final f in files.take(MergeLimits.maxFiles - state.items.length)) {
      final item = _append(f.name);
      _enqueue(() => _inspect(item.key, f));
    }
  }

  /// Removes a row and returns what [restore] needs to undo it.
  (int, MergeItem) remove(int key) {
    final index = state.items.indexWhere((i) => i.key == key);
    final item = state.items[index];
    state = MergeState([...state.items]..removeAt(index));
    return (index, item);
  }

  void restore((int, MergeItem) removed) {
    final (index, item) = removed;
    if (state.items.length >= MergeLimits.maxFiles) return;
    state = MergeState([...state.items]..insert(index.clamp(0, state.items.length), item));
  }

  /// Moves the row at [from] so it ends up at [to] (both in the final list,
  /// as [ReorderableListView.onReorderItem] reports them).
  void reorder(int from, int to) {
    final items = [...state.items];
    items.insert(to, items.removeAt(from));
    state = MergeState(items);
  }

  void move(int key, int delta) {
    final from = state.items.indexWhere((i) => i.key == key);
    final to = from + delta;
    if (to < 0 || to >= state.items.length) return;
    reorder(from, to);
  }

  /// Starts merging the ready files in their current order.
  Job start(String outputName) {
    final inputs = [for (final i in state.ready) i.file!];
    final body = ref.read(mergeDocumentsProvider).call(inputs, outputName: outputName);
    final link = ref.keepAlive();
    return ref.read(jobRunnerProvider).enqueue((token) async* {
      try {
        yield* body(token);
      } finally {
        link.close();
      }
    });
  }

  MergeItem _append(String name) {
    final item = MergeItem(key: _nextKey++, name: name);
    state = MergeState([...state.items, item]);
    return item;
  }

  /// Files are prepared one at a time: copies compete for the same disk and
  /// the engine has a single worker anyway.
  void _enqueue(Future<void> Function() task) => _queue = _queue.then((_) => _imports.isCancelled ? null : task());

  Future<void> _import(int key, PickedFile picked) async {
    final dir = await (_dir ??= ref.read(jobWorkspaceProvider).create());
    final copied = await ref.read(fileGatewayProvider).importToJob(picked, dir, token: _imports);
    switch (copied) {
      case Ok(:final value):
        await _inspect(key, value);
      case Err(:final failure):
        _update(key, (i) => i._failed(failure));
    }
  }

  Future<void> _inspect(int key, LocalFile file) async {
    if (!ref.mounted) return;
    final summary = await ref.read(pdfServiceProvider).inspect(file.path);
    _update(
      key,
      (i) => switch (summary) {
        Ok(:final value) => i._ready(file, value.pageCount),
        Err(:final failure) => i._failed(failure),
      },
    );
  }

  void _update(int key, MergeItem Function(MergeItem) change) {
    if (!ref.mounted) return;
    state = MergeState([for (final i in state.items) i.key == key ? change(i) : i]);
  }
}
