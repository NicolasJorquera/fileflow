import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/domain/files.dart';
import '../../core/domain/recents.dart';
import '../../core/domain/result.dart';
import '../../core/domain/tools.dart';
import '../../core/format/sizes.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../tools/merge/presentation/merge_controller.dart';
import 'failure_text.dart';

/// Resultado (UX v1.0): verdict, the file with an editable name, Compartir and
/// Guardar en…, the next step and the Recientes note. Works for any result in
/// Recientes, so it is also what a recent opens.
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

  LocalFile get _file => LocalFile(path: item.path, name: item.name, sizeBytes: item.sizeBytes);

  Future<void> _run(BuildContext context, Future<Result<Object?>> Function() action, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final text = switch (await action()) {
      Ok(:final value) when value != null => done,
      Ok() => null,
      Err(:final failure) => l10n.failureText(failure),
    };
    if (text == null || text.isEmpty) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final files = ref.read(fileGatewayProvider);
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
                child: Text(switch (item.tool) {
                  ToolId.merge => l10n.resultMerged,
                  _ => l10n.resultTitle,
                }, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        _NameField(item: item),
        const SizedBox(height: Space.s),
        Text(
          l10n.resultMeta(item.pages, formatBytes(item.sizeBytes, l10n.localeName)),
          style: text.bodySmall?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: Space.xl),
        FilledButton.icon(
          onPressed: () => _run(context, () => files.share([_file])),
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.share),
        ),
        const SizedBox(height: Space.s),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Touch.primaryButton)),
          onPressed: () => _run(context, () => files.saveAs(_file, suggestedName: item.name), done: l10n.savedSnack),
          icon: const Icon(Icons.download_outlined),
          label: Text(l10n.saveTo),
        ),
        const SizedBox(height: Space.s),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(Touch.minTarget)),
          onPressed: () => _run(context, () => files.openWith(_file)),
          child: Text(l10n.openWith),
        ),
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
          child: ListTile(
            leading: Icon(Icons.merge_type, color: palette.tools[ToolTint.merge]!.$2),
            title: Text(l10n.nextMergeAnother),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.merge, extra: MergeArgs(local: [_file])),
          ),
        ),
        const SizedBox(height: Space.xl),
        Text(l10n.recentsNote, style: text.bodySmall?.copyWith(color: palette.muted)),
      ],
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

  static String _stem(String name) => name.toLowerCase().endsWith('.pdf') ? name.substring(0, name.length - 4) : name;

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
