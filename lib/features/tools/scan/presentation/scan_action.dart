import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../core/domain/failures.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/domain/scanner.dart';
import '../../../../design_system/theme.dart';
import '../../../../design_system/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/failure_text.dart';

/// «Escanear» (PRD H1): opens the system scanner and, when it brings a PDF,
/// its Resultado. Closing the scanner returns without a message.
Future<void> startScan(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final issue = switch (await ref.read(scannerGatewayProvider).readiness()) {
    ScannerReadiness.unsupported => ScannerIssue.deviceNotSupported,
    ScannerReadiness.offline => ScannerIssue.moduleNotDownloaded,
    ScannerReadiness.ready || ScannerReadiness.needsDownload => null,
  };
  if (issue != null) {
    if (context.mounted) await showScannerProblem(context, issue);
    return;
  }
  final stamp = DateFormat('yyyy-MM-dd HH.mm').format(DateTime.now());
  final result = await ref.read(scanDocumentProvider).call(name: '${l10n.nameScan(stamp)}.pdf');
  if (!context.mounted) return;
  switch (result) {
    case Ok(value: final item?):
      await context.push(Routes.result(item.id));
    case Ok():
      break;
    case Err(failure: ScannerUnavailable(:final reason)):
      await showScannerProblem(context, reason);
    case Err(:final failure):
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.failureText(failure))));
  }
}

/// E-SCAN-01 / E-SCAN-02 (UX v1.0, «Escáner sin conexión»): what happened and
/// the alternative, Fotos a PDF.
Future<void> showScannerProblem(BuildContext context, ScannerIssue issue) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);
    final palette = sheetContext.palette;
    final text = Theme.of(sheetContext).textTheme;
    final offline = issue == ScannerIssue.moduleNotDownloaded;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(offline ? Icons.cloud_off_outlined : Icons.no_photography_outlined, size: 40, color: palette.warn),
            const SizedBox(height: Space.m),
            Semantics(
              header: true,
              child: Text(
                offline ? l10n.scanOfflineTitle : l10n.scanUnsupportedTitle,
                textAlign: TextAlign.center,
                style: text.titleLarge,
              ),
            ),
            const SizedBox(height: Space.s),
            Text(
              offline ? l10n.scanOfflineBody : l10n.scanUnsupportedBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: Space.xl),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push(Routes.photos);
              },
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.scanUsePhotos),
            ),
            const SizedBox(height: Space.s),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(Touch.minTarget)),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(l10n.understood),
            ),
          ],
        ),
      ),
    );
  },
);
