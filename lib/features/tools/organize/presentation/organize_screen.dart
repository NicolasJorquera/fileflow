import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/domain/files.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/jobs/jobs.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/failure_text.dart';
import '../../../shared/processing_screen.dart';
import '../../shared/presentation/page_thumbnail.dart';
import '../../shared/presentation/tool_args.dart';
import '../domain/page_ranges.dart';
import 'organize_controller.dart';
import 'range_field.dart';
import 'split_sheet.dart';

/// Organizar páginas (UX v1.0): file, selection bar, thumbnail grid, actions.
/// Tap selects; long press drags; «Más» has the same moves without dragging.
class OrganizeScreen extends ConsumerStatefulWidget {
  const OrganizeScreen({super.key, this.args = const ToolArgs()});

  final ToolArgs args;

  @override
  ConsumerState<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _OrganizeScreenState extends ConsumerState<OrganizeScreen> {
  OrganizeController get _controller => ref.read(organizeControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.args.isEmpty) {
        _controller.pick();
      } else {
        _controller.start(widget.args);
      }
    });
  }

  void _snack(String text, {SnackBarAction? action}) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action, duration: const Duration(seconds: 5)));

  Future<void> _run(Job Function() start, String title) async {
    final retry = await context.push<bool>(
      Routes.processing,
      extra: ProcessingArgs(job: start(), title: title),
    );
    if (retry == true && mounted) await _run(start, title);
  }

  String get _stem => fileStem(ref.read(organizeControllerProvider).source!.file.name);

  void _save() {
    final l10n = AppLocalizations.of(context);
    _run(() => _controller.save('${l10n.nameEdited(_stem)}.pdf'), l10n.processingSave);
  }

  void _extract() {
    final l10n = AppLocalizations.of(context);
    final positions = ref.read(organizeControllerProvider).selectedPositions;
    final name = positions.length == 1
        ? l10n.namePage(_stem, '${positions.single}')
        : l10n.namePages(_stem, describePages(positions));
    _run(() => _controller.extract('$name.pdf'), l10n.processingExtract);
  }

  void _delete() {
    final l10n = AppLocalizations.of(context);
    final count = ref.read(organizeControllerProvider).selected.length;
    final before = _controller.deleteSelected();
    if (before == null) return _snack(l10n.organizeKeepOne);
    _snack(
      l10n.organizeDeleted(count),
      action: SnackBarAction(label: l10n.undo, onPressed: () => _controller.restore(before)),
    );
  }

  Future<void> _split() async {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(organizeControllerProvider);
    final parts = await showSplitSheet(context, pageCount: state.pages.length);
    if (parts == null || !mounted) return;
    final names = [
      for (final r in parts) '${r.length == 1 ? l10n.namePage(_stem, '${r.first}') : l10n.namePages(_stem, '$r')}.pdf',
    ];
    await _run(() => _controller.split(parts, setName: l10n.nameSplit(_stem), partNames: names), l10n.processingSplit);
  }

  Future<void> _selectRange() async {
    final ranges = await showRangeDialog(context, pageCount: ref.read(organizeControllerProvider).pages.length);
    if (ranges != null) _controller.selectRanges(ranges);
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.discardTitle),
            content: Text(l10n.discardBody),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.keepEditing)),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.discard)),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final state = ref.watch(organizeControllerProvider);
    final source = state.source;
    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.toolOrganizeTitle),
              if (source != null)
                Text(
                  l10n.sourceMeta(source.file.name, state.pages.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
            ],
          ),
          actions: [if (source != null) TextButton(onPressed: state.isDirty ? _save : null, child: Text(l10n.save))],
        ),
        body: switch (state.status) {
          OrganizeStatus.loading => const Center(child: CircularProgressIndicator()),
          OrganizeStatus.empty => _PickPrompt(onPick: _controller.pick),
          OrganizeStatus.failed => _PickPrompt(onPick: _controller.pick, failure: l10n.failureText(state.failure!)),
          OrganizeStatus.ready => _Editor(state: state, onSelectAll: _controller.selectAll),
        },
        bottomNavigationBar: state.status == OrganizeStatus.ready
            ? _Actions(
                hasSelection: state.selected.isNotEmpty,
                onRotate: _controller.rotateSelected,
                onExtract: _extract,
                onDelete: _delete,
                onSplit: _split,
                onMove: _controller.moveSelected,
                onSelectRange: _selectRange,
              )
            : null,
      ),
    );
  }
}

/// No file yet, or the last one could not be opened.
class _PickPrompt extends StatelessWidget {
  const _PickPrompt({required this.onPick, this.failure});

  final VoidCallback onPick;
  final String? failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              failure ?? l10n.organizeEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: failure == null ? null : context.palette.danger),
            ),
            const SizedBox(height: Space.l),
            FilledButton.icon(onPressed: onPick, icon: const Icon(Icons.folder_open), label: Text(l10n.choosePdf)),
          ],
        ),
      ),
    );
  }
}

class _Editor extends ConsumerWidget {
  const _Editor({required this.state, required this.onSelectAll});

  final OrganizeState state;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final controller = ref.read(organizeControllerProvider.notifier);
    final thumbnails = ref.watch(thumbnailsProvider(state.source!.file.path)).value;
    final count = state.selected.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.l, 0, Space.s, 0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    count == 0 ? l10n.organizeHint : l10n.selectedCount(count),
                    style: text.bodyMedium?.copyWith(
                      color: count == 0 ? palette.muted : palette.fg,
                      fontWeight: count == 0 ? null : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: TextButton(
                  onPressed: count == state.pages.length ? controller.clearSelection : onSelectAll,
                  child: Text(
                    count == state.pages.length ? l10n.clearSelection : l10n.selectAll,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.isLong)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
            child: Text(l10n.organizeLong, style: text.bodySmall?.copyWith(color: palette.warn)),
          ),
        Expanded(
          child: PageGrid(
            pages: state.pages,
            selected: state.selected,
            thumbnails: thumbnails,
            onTap: controller.toggle,
            onMoveTo: controller.moveTo,
            onMoveOne: controller.moveOne,
          ),
        ),
      ],
    );
  }
}

/// The thumbnail grid of Organizar, also used to choose pages for PDF a
/// imagen. Without [onMoveTo] pages cannot be dragged.
class PageGrid extends StatelessWidget {
  const PageGrid({
    super.key,
    required this.pages,
    required this.selected,
    required this.thumbnails,
    required this.onTap,
    this.onMoveTo,
    this.onMoveOne,
  });

  final List<OrgPage> pages;
  final Set<int> selected;
  final Thumbnails? thumbnails;
  final void Function(int source) onTap;
  final void Function(int source, int position)? onMoveTo;
  final void Function(int source, int delta)? onMoveOne;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.l),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: Space.m,
        crossAxisSpacing: Space.m,
        childAspectRatio: 0.72,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        final tile = _PageTile(
          page: page,
          position: index + 1,
          isLast: index == pages.length - 1,
          selected: selected.contains(page.source),
          thumbnails: thumbnails,
          onTap: () => onTap(page.source),
          onMoveOne: onMoveOne == null ? null : (delta) => onMoveOne!(page.source, delta),
        );
        final moveTo = onMoveTo;
        if (moveTo == null) return tile;
        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != page.source,
          onAcceptWithDetails: (details) => moveTo(details.data, index),
          builder: (context, candidates, _) => LongPressDraggable<int>(
            data: page.source,
            feedback: SizedBox(
              width: 100,
              height: 139,
              child: Opacity(opacity: 0.85, child: Material(elevation: 6, child: tile)),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: tile),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: candidates.isEmpty
                    ? null
                    : BorderDirectional(start: BorderSide(color: context.palette.primary, width: 3)),
              ),
              child: tile,
            ),
          ),
        );
      },
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.page,
    required this.position,
    required this.isLast,
    required this.selected,
    required this.thumbnails,
    required this.onTap,
    required this.onMoveOne,
  });

  final OrgPage page;
  final int position;
  final bool isLast, selected;
  final Thumbnails? thumbnails;
  final VoidCallback onTap;
  final void Function(int delta)? onMoveOne;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final moveOne = onMoveOne;
    return Semantics(
      button: true,
      selected: selected,
      label: page.quarterTurns == 0
          ? l10n.pageLabel(position)
          : l10n.pageLabelRotated(position, page.quarterTurns * 90),
      customSemanticsActions: moveOne == null
          ? null
          : {
              if (position > 1) CustomSemanticsAction(label: l10n.moveBefore): () => moveOne(-1),
              if (!isLast) CustomSemanticsAction(label: l10n.moveAfter): () => moveOne(1),
            },
      excludeSemantics: true,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.small),
          side: BorderSide(color: selected ? palette.primary : palette.line, width: selected ? 3 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.s, Space.s, Space.s, Space.xl),
                  child: PageThumbnail(
                    thumbnails: thumbnails,
                    index: page.source,
                    label: '$position',
                    quarterTurns: page.quarterTurns,
                  ),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: Space.xs,
                child: Text(
                  '$position',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? palette.primary : palette.muted,
                  ),
                ),
              ),
              if (selected)
                PositionedDirectional(
                  top: Space.xs,
                  end: Space.xs,
                  child: Icon(Icons.check_circle, color: palette.primary, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.hasSelection,
    required this.onRotate,
    required this.onExtract,
    required this.onDelete,
    required this.onSplit,
    required this.onMove,
    required this.onSelectRange,
  });

  final bool hasSelection;
  final VoidCallback onRotate, onExtract, onDelete, onSplit, onSelectRange;
  final void Function(int delta) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    Widget action(IconData icon, String label, VoidCallback? onPressed) => Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          foregroundColor: palette.fg,
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            action(Icons.rotate_right, l10n.rotate, hasSelection ? onRotate : null),
            action(Icons.content_copy_outlined, l10n.extract, hasSelection ? onExtract : null),
            action(Icons.delete_outline, l10n.delete, hasSelection ? onDelete : null),
            Expanded(
              child: PopupMenuButton<VoidCallback>(
                tooltip: l10n.more,
                onSelected: (run) => run(),
                itemBuilder: (context) => [
                  PopupMenuItem(value: onSplit, child: Text(l10n.splitMenu)),
                  PopupMenuItem(value: onSelectRange, child: Text(l10n.selectRangeMenu)),
                  PopupMenuItem(value: () => onMove(-1), enabled: hasSelection, child: Text(l10n.moveBefore)),
                  PopupMenuItem(value: () => onMove(1), enabled: hasSelection, child: Text(l10n.moveAfter)),
                ],
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.more_horiz, color: palette.fg),
                      const SizedBox(height: 2),
                      Text(
                        l10n.more,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: palette.fg),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
