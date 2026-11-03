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

/// Runs [action] and reports its outcome in a snackbar: [done] on success
/// with a value, the failure's message otherwise. A cancelled picker says
/// nothing.
Future<void> reportOutcome(BuildContext context, Future<Result<Object?>> Function() action, {String? done}) async {
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

Future<void> shareResult(BuildContext context, WidgetRef ref, RecentItem item) =>
    reportOutcome(context, () => ref.read(fileGatewayProvider).share(item.localFiles));

/// «Guardar en…» for one file; a folder for several (PRD RF-04).
Future<void> saveResult(BuildContext context, WidgetRef ref, RecentItem item) {
  final l10n = AppLocalizations.of(context);
  final files = ref.read(fileGatewayProvider);
  if (item.isSingleFile) {
    return reportOutcome(
      context,
      () => files.saveAs(item.localFiles.single, suggestedName: item.name),
      done: l10n.savedSnack,
    );
  }
  return reportOutcome(
    context,
    () => files.saveAllToFolder(item.localFiles, names: item.files),
    done: l10n.savedFolderSnack(item.files.length),
  );
}

/// «Elegir un PDF», «Usar en otra herramienta»: a sheet with the tools that
/// take one PDF; the chosen one opens with [args].
Future<void> showToolChooser(BuildContext context, ToolArgs args) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);
    final palette = sheetContext.palette;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
            child: Semantics(
              header: true,
              child: Text(l10n.chooseToolTitle, style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
          ),
          for (final tool in tools)
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
