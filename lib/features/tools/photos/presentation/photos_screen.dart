import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../../core/domain/failures.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/format/sizes.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/failure_text.dart';
import '../../../shared/processing_screen.dart';
import '../../shared/presentation/tool_args.dart';
import 'photos_controller.dart';

/// Fotos a PDF (UX v1.0): count, numbered grid, page options and a button
/// with the number of pages.
class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key, this.args = const ToolArgs()});

  final ToolArgs args;

  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  PhotosController get _controller => ref.read(photosControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.args.picked.isEmpty) {
        _pick();
      } else {
        _report(_controller.addPicked(widget.args.picked));
      }
    });
  }

  void _report(AppFailure? failure) {
    if (failure == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final text = switch (failure) {
      LimitExceeded(:final max) => l10n.photosTooMany(max),
      _ => l10n.failureText(failure),
    };
    if (text.isNotEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pick() async => _report(await _controller.pick());

  void _remove(PhotoItem item, int position) {
    final l10n = AppLocalizations.of(context);
    final removed = _controller.remove(item.key);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(l10n.photoRemoved(position)),
          action: SnackBarAction(label: l10n.undo, onPressed: () => _controller.restore(removed)),
        ),
      );
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final stamp = DateFormat('yyyy-MM-dd HH.mm').format(DateTime.now());
    final name = '${l10n.namePhotos(stamp)}.pdf';
    while (mounted) {
      final retry = await context.push<bool>(
        Routes.processing,
        extra: ProcessingArgs(job: _controller.create(name), title: l10n.processingPhotos),
      );
      if (retry != true) break;
    }
  }

  Future<void> _choosePage() async {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(photosControllerProvider);
    final auto = _controller.resolvedPreset;
    final chosen = await showModalBottomSheet<PagePreset>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: RadioGroup<PagePreset>(
          groupValue: state.preset,
          onChanged: (p) => Navigator.of(context).pop(p),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final preset in PagePreset.values)
                RadioListTile<PagePreset>(
                  value: preset,
                  title: Text(
                    preset == PagePreset.auto ? l10n.pageAutoNamed(_presetName(l10n, auto)) : _presetName(l10n, preset),
                  ),
                  subtitle: preset == PagePreset.fitImage ? Text(l10n.pageFitImageHelp) : null,
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) _controller.setPreset(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(photosControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.toolPhotosTitle),
        actions: [if (state.items.isNotEmpty) TextButton(onPressed: _pick, child: Text(l10n.add))],
      ),
      body: state.items.isEmpty
          ? _Empty(onPick: _pick)
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l10n.photosCount(state.items.length),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.palette.muted),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.l),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 140,
                      mainAxisSpacing: Space.m,
                      crossAxisSpacing: Space.m,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      final tile = _PhotoTile(
                        item: item,
                        position: index + 1,
                        count: state.items.length,
                        onRotate: () => _controller.rotate(item.key),
                        onRemove: () => _remove(item, index + 1),
                        onMoveOne: (delta) => _controller.moveOne(item.key, delta),
                      );
                      return DragTarget<int>(
                        onWillAcceptWithDetails: (d) => d.data != item.key,
                        onAcceptWithDetails: (d) => _controller.moveTo(d.data, index),
                        builder: (context, candidates, _) => LongPressDraggable<int>(
                          data: item.key,
                          feedback: SizedBox(width: 100, height: 125, child: Material(elevation: 6, child: tile)),
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
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(Space.l),
                  sliver: SliverToBoxAdapter(
                    child: _PageOptions(state: state, onChoosePage: _choosePage),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: state.items.isEmpty ? null : _CreateBar(state: state, onCreate: _create),
    );
  }
}

String _presetName(AppLocalizations l10n, PagePreset preset) => switch (preset) {
  PagePreset.a4 => 'A4',
  PagePreset.letter => l10n.pageLetter,
  PagePreset.oficio => l10n.pageOficio,
  PagePreset.fitImage => l10n.pageFitImage,
  PagePreset.auto => l10n.pageAuto,
};

class _Empty extends StatelessWidget {
  const _Empty({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.photosEmpty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: Space.l),
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.choosePhotos),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.item,
    required this.position,
    required this.count,
    required this.onRotate,
    required this.onRemove,
    required this.onMoveOne,
  });

  final PhotoItem item;
  final int position, count;
  final VoidCallback onRotate, onRemove;
  final void Function(int delta) onMoveOne;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final thumbnail = item.thumbnail;
    final Widget image;
    if (item.unreadable) {
      image = ColoredBox(
        color: palette.warnSoft,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: palette.warn),
              const SizedBox(height: Space.xs),
              Text(
                l10n.photoUnreadable,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: palette.warn),
              ),
            ],
          ),
        ),
      );
    } else if (thumbnail == null) {
      image = ColoredBox(color: palette.surface2);
    } else {
      image = RotatedBox(
        quarterTurns: item.turns,
        child: Image.file(
          File(thumbnail),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => ColoredBox(color: palette.surface2),
        ),
      );
    }
    return Semantics(
      label: item.unreadable ? l10n.photoLabelUnreadable(position, count) : l10n.photoLabel(position, count),
      customSemanticsActions: {
        if (position > 1) CustomSemanticsAction(label: l10n.moveBefore): () => onMoveOne(-1),
        if (position < count) CustomSemanticsAction(label: l10n.moveAfter): () => onMoveOne(1),
      },
      child: Material(
        color: palette.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.small),
          side: BorderSide(color: item.unreadable ? palette.warn : palette.line),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(child: image),
            PositionedDirectional(
              top: Space.xs,
              start: Space.xs,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(Radii.small)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 2),
                    child: Text(
                      '$position',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: palette.fg),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              bottom: 0,
              start: 0,
              end: 0,
              child: ColoredBox(
                color: palette.surface.withValues(alpha: 0.92),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!item.unreadable)
                      IconButton(
                        tooltip: l10n.rotatePhoto(position),
                        icon: const Icon(Icons.rotate_right, size: 20),
                        onPressed: onRotate,
                      )
                    else
                      const SizedBox.shrink(),
                    IconButton(
                      tooltip: l10n.removePhoto(position),
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onRemove,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageOptions extends ConsumerWidget {
  const _PageOptions({required this.state, required this.onChoosePage});

  final PhotosState state;
  final VoidCallback onChoosePage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final controller = ref.read(photosControllerProvider.notifier);
    final preset = state.preset == PagePreset.auto
        ? l10n.pageAutoShort(_presetName(l10n, controller.resolvedPreset))
        : _presetName(l10n, state.preset);
    return Material(
      color: palette.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(l10n.pageSize),
            subtitle: Text(preset, style: text.bodyMedium?.copyWith(color: palette.primary)),
            trailing: const Icon(Icons.chevron_right),
            onTap: onChoosePage,
          ),
          const Divider(indent: Space.l, endIndent: Space.l),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.s),
            child: Text(l10n.margins, style: text.bodyLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.marginNone)),
                ButtonSegment(value: true, label: Text(l10n.marginSmall)),
              ],
              selected: {state.margin},
              onSelectionChanged: (s) => controller.setMargin(s.single),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
            child: Text(l10n.photoQuality, style: text.bodyLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
            child: SegmentedButton<PhotoQuality>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: PhotoQuality.balanced, label: Text(l10n.levelBalanced)),
                ButtonSegment(value: PhotoQuality.high, label: Text(l10n.levelHigh)),
              ],
              selected: {state.quality},
              onSelectionChanged: (s) => controller.setQuality(s.single),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateBar extends StatelessWidget {
  const _CreateBar({required this.state, required this.onCreate});

  final PhotosState state;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: state.canCreate ? onCreate : null,
                child: Text(l10n.createPdfButton(state.ready.length)),
              ),
              const SizedBox(height: Space.s),
              Text(
                state.unreadable > 0
                    ? l10n.photosSkipped(state.unreadable)
                    : l10n.photosEstimate(formatBytes(state.estimatedBytes, l10n.localeName)),
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: state.unreadable > 0 ? palette.warn : palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
