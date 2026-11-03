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
    final items = ref.watch(recentsProvider).value ?? ref.read(recentsRepositoryProvider).current;
    final item = items.where((i) => i.id == id).firstOrNull;
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

  String _verdict(AppLocalizations l10n) => switch (item.kind) {
    ResultKind.merged => l10n.resultMerged,
    ResultKind.edited => l10n.resultEdited,
    ResultKind.extracted => l10n.resultExtracted(item.pages),
    ResultKind.split => l10n.resultSplit(item.files.length),
    ResultKind.images => l10n.resultImages(item.files.length),
  };

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
              decoration: BoxDecoration(color: palette.successSoft, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(Space.s),
                child: Icon(Icons.check, color: palette.success),
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
        const SizedBox(height: Space.xl),
        if (item.isSingleFile) ...[
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
                for (final (i, tool) in tools.indexed) ...[
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
