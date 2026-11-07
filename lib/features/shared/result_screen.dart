import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/domain/files.dart';
import '../../core/domain/recents.dart';
import '../../core/format/sizes.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../tools/registry.dart';
import '../tools/shared/presentation/page_thumbnail.dart';
import '../tools/shared/presentation/tool_args.dart';
import 'result_actions.dart';
import 'retention_label.dart';

/// Resultado (UX v1.0): verdict, the file with an editable name (or the list
/// of files), Compartir and Guardar en…, the next steps and the Recientes
/// note. Works for any result in Recientes, so it is also what a recent opens.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    bool isThis(RecentItem i) => i.id == id;
    // The repository is the truth; the stream may lag right after a job adds
    // the result this screen opens with.
    final item =
        (ref.watch(recentsProvider).value ?? const <RecentItem>[]).where(isThis).firstOrNull ??
        ref.read(recentsRepositoryProvider).current.where(isThis).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resultTitle),
        leading: IconButton(
          tooltip: l10n.close,
          icon: const Icon(Icons.close),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: item == null ? const SizedBox.shrink() : _Body(item: item),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.item});

  final RecentItem item;

  String _verdict(AppLocalizations l10n) {
    final size = formatBytes(item.sizeBytes, l10n.localeName);
    return switch (item.kind) {
      ResultKind.merged => l10n.resultMerged,
      ResultKind.edited => l10n.resultEdited,
      ResultKind.extracted => l10n.resultExtracted(item.pages),
      ResultKind.split => l10n.resultSplit(item.files.length),
      ResultKind.images => l10n.resultImages(item.files.length),
      ResultKind.scanned => l10n.resultScanned,
      ResultKind.photos => l10n.resultPhotos(item.pages),
      ResultKind.reduced => switch (item.targetBytes) {
        null => l10n.resultReduced(_savedPercent),
        final target when item.metTarget => l10n.resultUnder(formatSizeGoal(target, l10n.localeName)),
        final target => l10n.resultMissed(size, formatSizeGoal(target, l10n.localeName)),
      },
    };
  }

  int get _savedPercent {
    final before = item.inputBytes;
    if (before == null || before == 0) return 0;
    return ((1 - item.sizeBytes / before) * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final size = formatBytes(item.sizeBytes, l10n.localeName);
    final retention = ref.watch(retentionProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xl),
      children: [
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: item.metTarget ? palette.successSoft : palette.warnSoft,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Space.s),
                child: Icon(
                  item.metTarget ? Icons.check : Icons.info_outline,
                  color: item.metTarget ? palette.success : palette.warn,
                ),
              ),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(_verdict(l10n), style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        if (item.kind == ResultKind.reduced && item.inputBytes != null) ...[
          const SizedBox(height: Space.l),
          _BeforeAfter(before: item.inputBytes!, after: item.sizeBytes, percent: _savedPercent),
          if (!item.metTarget) ...[
            const SizedBox(height: Space.s),
            Text(l10n.resultMissedHint, style: text.bodyMedium?.copyWith(color: palette.warn)),
          ],
        ],
        const SizedBox(height: Space.xl),
        if (item.isSingleFile) ...[
          if (item.kind.isSinglePdf) ...[_Preview(path: item.path), const SizedBox(height: Space.l)],
          _NameField(item: item),
          const SizedBox(height: Space.s),
          Text(l10n.resultMeta(item.pages, size), style: text.bodySmall?.copyWith(color: palette.muted)),
        ] else
          _FileList(item: item),
        const SizedBox(height: Space.xl),
        FilledButton.icon(
          onPressed: () => shareResult(context, ref, item),
          icon: const Icon(Icons.share_outlined),
          label: Text(item.isSingleFile ? l10n.share : l10n.shareAll),
        ),
        const SizedBox(height: Space.s),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Touch.primaryButton)),
          onPressed: () => saveResult(context, ref, item),
          icon: const Icon(Icons.download_outlined),
          label: Text(item.isSingleFile ? l10n.saveTo : l10n.saveToFolder),
        ),
        if (item.isSingleFile) ...[
          const SizedBox(height: Space.s),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(Touch.minTarget)),
            onPressed: () =>
                reportOutcome(context, () => ref.read(fileGatewayProvider).openWith(item.localFiles.single)),
            child: Text(l10n.openWith),
          ),
        ],
        if (item.kind.isSinglePdf) ...[
          const SizedBox(height: Space.xl),
          Semantics(
            header: true,
            child: Text(
              l10n.nextStep.toUpperCase(),
              style: text.labelMedium?.copyWith(color: palette.muted, letterSpacing: 0.3),
            ),
          ),
          const SizedBox(height: Space.s),
          Material(
            color: palette.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card),
              side: BorderSide(color: palette.line),
            ),
            child: Column(
              children: [
                for (final (i, tool) in pdfTools.indexed) ...[
                  if (i > 0) const Divider(indent: Space.l, endIndent: Space.l),
                  ListTile(
                    leading: Icon(tool.icon, color: palette.tools[tool.tint]!.$2),
                    title: Text(tool.nextStep(l10n)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(tool.route, extra: ToolArgs(local: item.localFiles)),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.xl),
        Text(
          retention.period == null ? l10n.recentsNoteForever : l10n.recentsNote(retentionLabel(l10n, retention)),
          style: text.bodySmall?.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

/// First page of the result (PRD RF-03), from the thumbnail cache.
class _Preview extends ConsumerWidget {
  const _Preview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: SizedBox(
      height: 180,
      child: AspectRatio(
        aspectRatio: 0.72,
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: context.palette.line)),
          child: ExcludeSemantics(
            child: PageThumbnail(thumbnails: ref.watch(thumbnailsProvider(path)).value, index: 0, label: '1'),
          ),
        ),
      ),
    ),
  );
}

/// «Antes → Ahora» (UX v1.0): the bars are decorative, the figures are text.
class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter({required this.before, required this.after, required this.percent});

  final int before, after, percent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    Widget bar(String label, int bytes, Color color) => Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: text.bodySmall?.copyWith(color: palette.muted)),
        ),
        Expanded(
          child: ExcludeSemantics(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: (bytes / before).clamp(0.02, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Space.s),
        SizedBox(
          width: 72,
          child: Text(formatBytes(bytes, l10n.localeName), textAlign: TextAlign.end, style: text.bodyMedium),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.beforeAfter(formatBytes(before, l10n.localeName), formatBytes(after, l10n.localeName), percent),
          style: text.bodyMedium?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: Space.s),
        bar(l10n.before, before, palette.line),
        const SizedBox(height: Space.xs),
        bar(l10n.after, after, palette.success),
      ],
    );
  }
}

/// The files of a multi-file result: count, total size and the first names.
class _FileList extends StatelessWidget {
  const _FileList({required this.item});

  final RecentItem item;

  static const _shown = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final more = item.files.length - _shown;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: text.titleMedium),
            Text(
              l10n.filesMeta(item.files.length, formatBytes(item.sizeBytes, l10n.localeName)),
              style: text.bodySmall?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: Space.s),
            for (final name in item.files.take(_shown))
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
            if (more > 0) Text(l10n.andMore(more), style: text.bodyMedium?.copyWith(color: palette.muted)),
          ],
        ),
      ),
    );
  }
}

/// The name without «.pdf»; saved when the field loses focus or on Done.
class _NameField extends ConsumerStatefulWidget {
  const _NameField({required this.item});

  final RecentItem item;

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  late final _controller = TextEditingController(text: _stem(widget.item.name));
  final _focus = FocusNode();

  static String _stem(String name) => fileStem(name);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final stem = _controller.text.trim();
    if (stem.isEmpty || stem == _stem(widget.item.name)) {
      _controller.text = _stem(widget.item.name);
      return;
    }
    try {
      final renamed = await ref.read(recentsRepositoryProvider).rename(widget.item.id, '$stem.pdf');
      if (mounted) _controller.text = _stem(renamed.name);
    } on Exception {
      // Renaming is cosmetic: on any failure the file keeps its name.
      if (mounted) _controller.text = _stem(widget.item.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      focusNode: _focus,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: l10n.fileNameLabel,
        suffixText: '.pdf',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.small)),
      ),
      onSubmitted: (_) => _focus.unfocus(),
    );
  }
}
