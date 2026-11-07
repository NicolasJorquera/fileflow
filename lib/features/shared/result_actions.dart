import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/domain/files.dart';
import '../../core/domain/recents.dart';
import '../../core/domain/result.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../tools/registry.dart';
import '../tools/shared/presentation/tool_args.dart';
import 'failure_text.dart';

/// What Resultado and the Recientes menu do with a result: share, save and
/// open its files, or hand it to another tool.
extension ResultFiles on RecentItem {
  List<LocalFile> get localFiles => [
    for (final (i, name) in files.indexed)
      LocalFile(path: paths[i], name: name, sizeBytes: isSingleFile ? sizeBytes : 0),
  ];
}

/// Runs [action] and reports its outcome in a snackbar: [done] on success,
/// the failure's message otherwise. A cancelled picker says nothing. Returns
/// whether it succeeded (with [requireValue], only when the action returned a
/// value: saving returns null when the user cancels).
Future<bool> reportOutcome(
  BuildContext context,
  Future<Result<Object?>> Function() action, {
  String? done,
  bool requireValue = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final result = await action();
  final text = switch (result) {
    Ok(:final value) when value != null => done,
    Ok() => null,
    Err(:final failure) => l10n.failureText(failure),
  };
  if (text != null && text.isNotEmpty) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
  return switch (result) {
    Ok(:final value) => !requireValue || value != null,
    Err() => false,
  };
}

/// Compartir: the sheet opened, so a full-screen ad may follow (RN-09).
Future<void> shareResult(BuildContext context, WidgetRef ref, RecentItem item) async {
  final shared = await reportOutcome(context, () => ref.read(fileGatewayProvider).share(item.localFiles));
  if (shared && context.mounted) await ref.read(interstitialProvider).afterSaveOrShare();
}

/// «Guardar en…» for one file; a folder for several (PRD RF-04).
Future<void> saveResult(BuildContext context, WidgetRef ref, RecentItem item) async {
  final l10n = AppLocalizations.of(context);
  final files = ref.read(fileGatewayProvider);
  final saved = item.isSingleFile
      ? await reportOutcome(
          context,
          () => files.saveAs(item.localFiles.single, suggestedName: item.name),
          done: l10n.savedSnack,
          requireValue: true,
        )
      : await reportOutcome(
          context,
          () => files.saveAllToFolder(item.localFiles, names: item.files),
          done: l10n.savedFolderSnack(item.files.length),
          requireValue: true,
        );
  if (saved && context.mounted) await ref.read(interstitialProvider).afterSaveOrShare();
}

/// «Elegir un PDF», «Usar en otra herramienta»: a sheet with the tools that
/// take one PDF; the chosen one opens with [args].
Future<void> showToolChooser(BuildContext context, ToolArgs args) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);
    final palette = sheetContext.palette;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
            child: Semantics(
              header: true,
              child: Text(l10n.chooseToolTitle, style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
          ),
          for (final tool in pdfTools)
            ListTile(
              leading: Icon(tool.icon, color: palette.tools[tool.tint]!.$2),
              title: Text(tool.title(l10n)),
              subtitle: Text(tool.subtitle(l10n)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(tool.route, extra: args);
              },
            ),
          const SizedBox(height: Space.s),
        ],
      ),
    );
  },
);
