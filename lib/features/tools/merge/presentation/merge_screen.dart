import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../../core/domain/failures.dart';
import '../../../../core/domain/tools.dart';
import '../../../../core/format/sizes.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/failure_text.dart';
import '../../../shared/processing_screen.dart';
import 'merge_controller.dart';

/// Unir en uno solo (UX v1.0): instruction, numbered list, «Agregar PDF»,
/// summary and the button that says what will happen.
class MergeScreen extends ConsumerStatefulWidget {
  const MergeScreen({super.key, this.args = const MergeArgs()});

  final MergeArgs args;

  @override
  ConsumerState<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends ConsumerState<MergeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(mergeControllerProvider.notifier);
      controller.addLocal(widget.args.local);
      _report(controller.addPicked(widget.args.picked));
    });
  }

  void _report(AppFailure? failure) {
    if (failure == null || !mounted) return;
    final text = AppLocalizations.of(context).failureText(failure);
    if (text.isNotEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pick() async => _report(await ref.read(mergeControllerProvider.notifier).pick());

  void _remove(MergeItem item) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(mergeControllerProvider.notifier);
    final removed = controller.remove(item.key);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(l10n.removedSnack(item.name)),
          action: SnackBarAction(label: l10n.undo, onPressed: () => controller.restore(removed)),
        ),
      );
  }

  Future<void> _merge() async {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final job = ref.read(mergeControllerProvider.notifier).start('${l10n.mergedName(date)}.pdf');
    final retry = await context.push<bool>(
      Routes.processing,
      extra: ProcessingArgs(job: job, title: l10n.processingMerge),
    );
    if (retry == true && mounted) await _merge();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final state = ref.watch(mergeControllerProvider);
    final controller = ref.read(mergeControllerProvider.notifier);
    final full = state.items.length >= MergeLimits.maxFiles;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.toolMergeTitle)),
      body: state.items.isEmpty
          ? _Empty(onAdd: _pick)
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
              buildDefaultDragHandles: false,
              header: Padding(
                padding: const EdgeInsets.only(bottom: Space.m),
                child: Text(l10n.mergeHint, style: text.bodyMedium?.copyWith(color: palette.muted)),
              ),
              footer: Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: full ? null : _pick,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.mergeAdd),
                  ),
                ),
              ),
              itemCount: state.items.length,
              onReorderItem: controller.reorder,
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _Row(
                  key: ValueKey(item.key),
                  item: item,
                  index: index,
                  isLast: index == state.items.length - 1,
                  onRemove: () => _remove(item),
                  onMove: (delta) => controller.move(item.key, delta),
                );
              },
            ),
      bottomNavigationBar: state.items.isEmpty ? null : _Summary(state: state, onMerge: _merge),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.mergeEmpty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: Space.l),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(l10n.mergeAdd)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.item,
    required this.index,
    required this.isLast,
    required this.onRemove,
    required this.onMove,
  });

  final MergeItem item;
  final int index;
  final bool isLast;
  final VoidCallback onRemove;
  final void Function(int delta) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final failure = item.failure;
    final meta = switch (item) {
      MergeItem(isPreparing: true) => l10n.itemPreparing,
      MergeItem(:final pages?, :final file?) => l10n.itemMeta(pages, formatBytes(file.sizeBytes, l10n.localeName)),
      _ => l10n.failureText(failure!),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Semantics(
        customSemanticsActions: {
          if (index > 0) CustomSemanticsAction(label: l10n.moveUp): () => onMove(-1),
          if (!isLast) CustomSemanticsAction(label: l10n.moveDown): () => onMove(1),
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: failure == null ? palette.surface : palette.dangerSoft,
            borderRadius: BorderRadius.circular(Radii.small),
            border: Border.all(color: failure == null ? palette.line : palette.danger),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: _MoveMenu(name: item.name, canUp: index > 0, canDown: !isLast, onMove: onMove),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${item.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        style: text.bodySmall?.copyWith(color: failure == null ? palette.muted : palette.danger),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(tooltip: l10n.removeItem(item.name), icon: const Icon(Icons.close), onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}

/// The drag handle. Dragging reorders; tapping it opens «Mover arriba/abajo»
/// for people who cannot drag (UX v1.0, «Accesibilidad»).
class _MoveMenu extends StatelessWidget {
  const _MoveMenu({required this.name, required this.canUp, required this.canDown, required this.onMove});

  final String name;
  final bool canUp, canDown;
  final void Function(int delta) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<int>(
      tooltip: l10n.moveItem(name),
      icon: Icon(Icons.drag_indicator, color: context.palette.muted),
      onSelected: onMove,
      itemBuilder: (context) => [
        PopupMenuItem(value: -1, enabled: canUp, child: Text(l10n.moveUp)),
        PopupMenuItem(value: 1, enabled: canDown, child: Text(l10n.moveDown)),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state, required this.onMerge});

  final MergeState state;
  final VoidCallback onMerge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final ready = state.ready.length;
    final note = switch (state) {
      MergeState(tooManyPages: true) => (l10n.mergeTooManyPages(state.pages, MergeLimits.maxPages), palette.danger),
      MergeState(skipped: > 0) => (l10n.mergeSkipped(state.skipped), palette.danger),
      MergeState(isBig: true) => (l10n.mergeBig, palette.warn),
      _ => null,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l10n.mergeSummary(ready, state.pages), style: text.bodyMedium)),
                  Text(
                    formatBytes(state.bytes, l10n.localeName),
                    style: text.bodyMedium?.copyWith(color: palette.muted),
                  ),
                ],
              ),
              const SizedBox(height: Space.m),
              FilledButton(
                onPressed: state.canMerge ? onMerge : null,
                child: Text(ready >= 2 ? l10n.mergeButton(ready) : l10n.mergeNeedTwo),
              ),
              if (note != null) ...[
                const SizedBox(height: Space.s),
                Text(
                  note.$1,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: note.$2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
