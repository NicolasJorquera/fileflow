import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/domain/recents.dart';
import '../../../core/domain/result.dart';
import '../../../core/format/sizes.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/failure_text.dart';
import '../../shared/result_actions.dart';
import '../../shared/retention_label.dart';
import '../../tools/registry.dart';
import '../../tools/shared/presentation/tool_args.dart';

/// Recientes (UX v1.0): purge notice, «Hoy» / «Esta semana» / «Antes», rows
/// with the tool tag and the days left. No ads here: it shows document names.
class RecentsScreen extends ConsumerStatefulWidget {
  const RecentsScreen({super.key});

  @override
  ConsumerState<RecentsScreen> createState() => _RecentsScreenState();
}

enum _Group { today, week, older }

class _RecentsScreenState extends ConsumerState<RecentsScreen> {
  /// Rows removed but still undoable; deleted for real when the snackbar
  /// closes without «Deshacer».
  final _hidden = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(purgeRecentsProvider)());
  }

  void _remove(RecentItem item) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(recentsRepositoryProvider);
    setState(() => _hidden.add(item.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(l10n.removedSnack(item.name)),
          action: SnackBarAction(label: l10n.undo, onPressed: () => setState(() => _hidden.remove(item.id))),
        ),
      ).closed.then((reason) async {
        if (reason == SnackBarClosedReason.action) return;
        await repo.remove(item.id);
        if (mounted) setState(() => _hidden.remove(item.id));
      });
  }

  Future<void> _clearAll(List<RecentItem> items) async {
    final l10n = AppLocalizations.of(context);
    final bytes = items.fold(0, (sum, i) => sum + i.sizeBytes);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearAllTitle),
        content: Text(l10n.clearAllBody(items.length, formatBytes(bytes, l10n.localeName))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.clearAllConfirm)),
        ],
      ),
    );
    if (confirmed == true) await ref.read(recentsRepositoryProvider).clear();
  }

  Future<void> _pickPdf() async {
    final result = await ref.read(fileGatewayProvider).pickPdfs();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value) when value.isNotEmpty:
        await showToolChooser(context, ToolArgs(picked: [value.first]));
      case Ok():
        break;
      case Err(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).failureText(failure))));
    }
  }

  static bool _alive(Duration? remaining) => remaining == null || remaining > Duration.zero;

  _Group _groupOf(RecentItem item, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (!item.createdAt.isBefore(today)) return _Group.today;
    if (item.createdAt.isAfter(today.subtract(const Duration(days: 6)))) return _Group.week;
    return _Group.older;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final retention = ref.watch(retentionProvider);
    // Hide what already expired even before the purge runs.
    final items = [
      for (final i in ref.watch(recentsProvider).value ?? const <RecentItem>[])
        if (!_hidden.contains(i.id) && _alive(i.remaining(now, retention.period))) i,
    ];
    final groups = <_Group, List<RecentItem>>{};
    for (final item in items) {
      groups.putIfAbsent(_groupOf(item, now), () => []).add(item);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recentTitle),
        actions: [if (items.isNotEmpty) TextButton(onPressed: () => _clearAll(items), child: Text(l10n.clearAll))],
      ),
      body: items.isEmpty
          ? _Empty(onPick: _pickPdf)
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule, size: 18, color: palette.muted),
                    const SizedBox(width: Space.s),
                    Expanded(
                      child: Text(
                        retention.period == null
                            ? l10n.recentsNoticeForever
                            : l10n.recentsNotice(retentionLabel(l10n, retention)),
                        style: text.bodySmall?.copyWith(color: palette.muted),
                      ),
                    ),
                  ],
                ),
                for (final group in _Group.values)
                  if (groups[group] case final list?) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.s),
                      child: Semantics(
                        header: true,
                        child: Text(
                          switch (group) {
                            _Group.today => l10n.groupToday,
                            _Group.week => l10n.groupWeek,
                            _Group.older => l10n.groupOlder,
                          }.toUpperCase(),
                          style: text.labelMedium?.copyWith(color: palette.muted, letterSpacing: 0.3),
                        ),
                      ),
                    ),
                    Material(
                      color: palette.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.card),
                        side: BorderSide(color: palette.line),
                      ),
                      child: Column(
                        children: [
                          for (final (i, item) in list.indexed) ...[
                            if (i > 0) const Divider(indent: Space.l, endIndent: Space.l),
                            _Row(item: item, now: now, period: retention.period, onRemove: () => _remove(item)),
                          ],
                        ],
                      ),
                    ),
                  ],
              ],
            ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.item, required this.now, required this.period, required this.onRemove});

  final RecentItem item;
  final DateTime now;
  final Duration? period;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final (tagBg, tagFg) = palette.tools[resultTint(item.kind)]!;
    final size = formatBytes(item.sizeBytes, l10n.localeName);
    final remaining = item.remaining(now, period);
    final meta = remaining == null
        ? size
        : remaining < const Duration(days: 1)
        ? l10n.expiresToday(size)
        : l10n.expiresInDays(size, (remaining.inHours / 24).ceil());
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: Space.l, end: Space.xs),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: Space.xs),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(Radii.small)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 2),
                child: Text(resultTag(l10n, item.kind), style: text.labelSmall?.copyWith(color: tagFg)),
              ),
            ),
            const SizedBox(width: Space.s),
            Expanded(
              child: Text(meta, style: text.bodySmall?.copyWith(color: palette.muted)),
            ),
          ],
        ),
      ),
      onTap: () => context.push(Routes.result(item.id)),
      trailing: PopupMenuButton<void Function()>(
        tooltip: l10n.moreFor(item.name),
        onSelected: (run) => run(),
        itemBuilder: (_) => [
          PopupMenuItem(value: () => shareResult(context, ref, item), child: Text(l10n.share)),
          PopupMenuItem(
            value: () => saveResult(context, ref, item),
            child: Text(item.isSingleFile ? l10n.saveTo : l10n.saveToFolder),
          ),
          if (item.kind.isSinglePdf)
            PopupMenuItem(
              value: () => showToolChooser(context, ToolArgs(local: item.localFiles)),
              child: Text(l10n.useInTool),
            ),
          PopupMenuItem(value: onRemove, child: Text(l10n.delete)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: palette.surface2, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(Space.l),
                child: Icon(Icons.history, size: 36, color: palette.muted),
              ),
            ),
            const SizedBox(height: Space.l),
            Text(l10n.recentsEmptyTitle, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Space.s),
            Text(
              l10n.recentsEmptyBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: Space.xl),
            FilledButton.icon(onPressed: onPick, icon: const Icon(Icons.folder_open), label: Text(l10n.choosePdf)),
          ],
        ),
      ),
    );
  }
}
