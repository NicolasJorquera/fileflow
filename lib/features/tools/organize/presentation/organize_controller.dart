import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/domain/failures.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/recents.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/domain/tools.dart';
import '../../../../core/jobs/jobs.dart';
import '../../shared/presentation/run_job.dart';
import '../../shared/presentation/source_loader.dart';
import '../../shared/presentation/tool_args.dart';
import '../domain/page_ranges.dart';

/// A page of the source as it stands in the editor. [source] (0-based) also
/// identifies it: each source page appears at most once.
class OrgPage {
  const OrgPage(this.source, [this.quarterTurns = 0]);

  final int source;
  final int quarterTurns;

  PageRef get ref => PageRef(source, quarterTurns);

  OrgPage turned() => OrgPage(source, (quarterTurns + 1) % 4);

  @override
  bool operator ==(Object other) => other is OrgPage && other.source == source && other.quarterTurns == quarterTurns;

  @override
  int get hashCode => Object.hash(source, quarterTurns);
}

enum OrganizeStatus { empty, loading, ready, failed }

class OrganizeState {
  const OrganizeState({
    this.status = OrganizeStatus.empty,
    this.failure,
    this.source,
    this.pages = const [],
    this.selected = const {},
  });

  final OrganizeStatus status;
  final AppFailure? failure;
  final LoadedSource? source;
  final List<OrgPage> pages;

  /// Source indices of the selected pages.
  final Set<int> selected;

  bool get isDirty {
    if (source == null) return false;
    if (pages.length != source!.pageCount) return true;
    for (final (i, p) in pages.indexed) {
      if (p.source != i || p.quarterTurns != 0) return true;
    }
    return false;
  }

  /// Selected pages in their current order.
  List<OrgPage> get selection => [
    for (final p in pages)
      if (selected.contains(p.source)) p,
  ];

  /// 1-based positions of the selection, for names like «(págs. 3-5)».
  List<int> get selectedPositions => [
    for (final (i, p) in pages.indexed)
      if (selected.contains(p.source)) i + 1,
  ];

  bool get isLong => pages.length > OrganizeLimits.softPages;

  OrganizeState copyWith({
    OrganizeStatus? status,
    AppFailure? failure,
    LoadedSource? source,
    List<OrgPage>? pages,
    Set<int>? selected,
  }) => OrganizeState(
    status: status ?? this.status,
    failure: failure ?? this.failure,
    source: source ?? this.source,
    pages: pages ?? this.pages,
    selected: selected ?? this.selected,
  );
}

final organizeControllerProvider = NotifierProvider.autoDispose<OrganizeController, OrganizeState>(
  OrganizeController.new,
);

/// Organizar páginas (UX v1.0): every edit is in memory until «Guardar»,
/// «Extraer» or «Separar» writes a new PDF; the source never changes.
class OrganizeController extends Notifier<OrganizeState> {
  late SourceLoader _loader;

  @override
  OrganizeState build() {
    final loader = _loader = SourceLoader(
      files: ref.read(fileGatewayProvider),
      pdf: ref.read(pdfServiceProvider),
      workspace: ref.read(jobWorkspaceProvider),
    );
    ref.onDispose(loader.dispose);
    return const OrganizeState();
  }

  Future<void> start(ToolArgs args) => _load(() => _loader.fromArgs(args));

  Future<void> pick() => _load(_loader.pick);

  Future<void> _load(Future<Result<LoadedSource>?> Function() load) async {
    final previous = state;
    state = state.copyWith(status: OrganizeStatus.loading);
    final result = await load();
    if (!ref.mounted) return;
    state = switch (result) {
      null => previous,
      Ok(:final value) when value.pageCount > OrganizeLimits.maxPages => OrganizeState(
        status: OrganizeStatus.failed,
        failure: LimitExceeded(Limit.pages, value.pageCount, OrganizeLimits.maxPages),
      ),
      Ok(:final value) => OrganizeState(
        status: OrganizeStatus.ready,
        source: value,
        pages: [for (var i = 0; i < value.pageCount; i++) OrgPage(i)],
      ),
      Err(:final failure) => OrganizeState(status: OrganizeStatus.failed, failure: failure),
    };
  }

  void toggle(int source) {
    final selected = {...state.selected};
    if (!selected.remove(source)) selected.add(source);
    state = state.copyWith(selected: selected);
  }

  void selectAll() => state = state.copyWith(selected: {for (final p in state.pages) p.source});

  void clearSelection() => state = state.copyWith(selected: {});

  /// Selects the pages at the 1-based positions in [ranges].
  void selectRanges(List<PageRange> ranges) => state = state.copyWith(
    selected: {
      for (final r in ranges)
        for (final i in r.indices) state.pages[i].source,
    },
  );

  void rotateSelected() =>
      state = state.copyWith(pages: [for (final p in state.pages) state.selected.contains(p.source) ? p.turned() : p]);

  /// Removes the selected pages and returns the previous pages for «Deshacer»,
  /// or null when that would leave the document empty (not allowed).
  List<OrgPage>? deleteSelected() {
    final kept = [
      for (final p in state.pages)
        if (!state.selected.contains(p.source)) p,
    ];
    if (kept.isEmpty) return null;
    final before = state.pages;
    state = state.copyWith(pages: kept, selected: {});
    return before;
  }

  void restore(List<OrgPage> pages) => state = state.copyWith(pages: pages);

  /// Moves page [source] to [position] (0-based, in the list without it).
  void moveTo(int source, int position) {
    final pages = [...state.pages];
    final from = pages.indexWhere((p) => p.source == source);
    final page = pages.removeAt(from);
    pages.insert(position.clamp(0, pages.length), page);
    state = state.copyWith(pages: pages);
  }

  /// «Mover antes» / «Mover después» for one page ([delta] −1 or +1).
  void moveOne(int source, int delta) {
    final from = state.pages.indexWhere((p) => p.source == source);
    final to = from + delta;
    if (to < 0 || to >= state.pages.length) return;
    moveTo(source, to);
  }

  /// Moves the selected pages one place earlier ([delta] −1) or later (+1),
  /// keeping their order; a page already at the edge stays.
  void moveSelected(int delta) {
    final pages = [...state.pages];
    final order = delta < 0
        ? List.generate(pages.length, (i) => i)
        : List.generate(pages.length, (i) => pages.length - 1 - i);
    for (final i in order) {
      final j = i + delta;
      if (!state.selected.contains(pages[i].source) || j < 0 || j >= pages.length) continue;
      if (state.selected.contains(pages[j].source)) continue;
      final page = pages[i];
      pages[i] = pages[j];
      pages[j] = page;
    }
    state = state.copyWith(pages: pages);
  }

  Job _enqueue(JobBody body) => runKeepingAlive(ref, body);

  /// «Guardar»: the whole document as edited.
  Job save(String name) => _enqueue(
    ref
        .read(organizeDocumentProvider)
        .save(state.source!.file, [for (final p in state.pages) p.ref], name: name, kind: ResultKind.edited),
  );

  /// «Extraer»: the selected pages, in their current order.
  Job extract(String name) => _enqueue(
    ref
        .read(organizeDocumentProvider)
        .save(state.source!.file, [for (final p in state.selection) p.ref], name: name, kind: ResultKind.extracted),
  );

  /// «Separar»: [parts] are ranges over the current order.
  Job split(List<PageRange> parts, {required String setName, required List<String> partNames}) => _enqueue(
    ref
        .read(organizeDocumentProvider)
        .split(
          state.source!.file,
          [
            for (final r in parts) [for (final i in r.indices) state.pages[i].ref],
          ],
          setName: setName,
          partNames: partNames,
        ),
  );
}
