import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/domain/recents.dart';
import '../../core/domain/tools.dart';
import '../../design_system/tokens.dart';
import '../../l10n/app_localizations.dart';

/// How the app presents a tool: Inicio's card, «Siguiente paso» in Resultado
/// and «Usar en otra herramienta». Tools join the list as their milestone
/// lands (Plan de desarrollo: H4 Unir, H5 Organizar y PDF a imagen, H6 el
/// resto). Every tool route takes ToolArgs as `extra`.
class ToolEntry {
  const ToolEntry({
    required this.id,
    required this.icon,
    required this.tint,
    required this.route,
    required this.title,
    required this.subtitle,
    required this.nextStep,
    this.takesPdf = true,
  });

  final ToolId id;
  final IconData icon;
  final ToolTint tint;
  final String route;
  final String Function(AppLocalizations) title, subtitle;

  /// Label as a next step for a PDF result («Unir con otro PDF»).
  final String Function(AppLocalizations) nextStep;

  /// Whether it works on a PDF (offered as a next step and in «Usar en otra
  /// herramienta»). Fotos a PDF takes photos instead.
  final bool takesPdf;
}

/// In Inicio's order (approved canvas). Escanear has its own card above.
final tools = <ToolEntry>[
  ToolEntry(
    id: ToolId.reduce,
    icon: Icons.compress,
    tint: ToolTint.reduce,
    route: Routes.reduce,
    title: (l10n) => l10n.toolReduceTitle,
    subtitle: (l10n) => l10n.toolReduceSubtitle,
    nextStep: (l10n) => l10n.nextReduce,
  ),
  ToolEntry(
    id: ToolId.merge,
    icon: Icons.merge_type,
    tint: ToolTint.merge,
    route: Routes.merge,
    title: (l10n) => l10n.toolMergeTitle,
    subtitle: (l10n) => l10n.toolMergeSubtitle,
    nextStep: (l10n) => l10n.nextMergeAnother,
  ),
  ToolEntry(
    id: ToolId.imagesToPdf,
    icon: Icons.photo_library_outlined,
    tint: ToolTint.photos,
    route: Routes.photos,
    title: (l10n) => l10n.toolPhotosTitle,
    subtitle: (l10n) => l10n.toolPhotosSubtitle,
    nextStep: (l10n) => l10n.toolPhotosTitle,
    takesPdf: false,
  ),
  ToolEntry(
    id: ToolId.organize,
    icon: Icons.grid_view,
    tint: ToolTint.organize,
    route: Routes.organize,
    title: (l10n) => l10n.toolOrganizeTitle,
    subtitle: (l10n) => l10n.toolOrganizeSubtitle,
    nextStep: (l10n) => l10n.toolOrganizeTitle,
  ),
  ToolEntry(
    id: ToolId.pdfToImage,
    icon: Icons.image_outlined,
    tint: ToolTint.toImage,
    route: Routes.toImage,
    title: (l10n) => l10n.toolToImageTitle,
    subtitle: (l10n) => l10n.toolToImageSubtitle,
    nextStep: (l10n) => l10n.nextToImage,
  ),
];

/// The tools that take one PDF, in the same order.
Iterable<ToolEntry> get pdfTools => tools.where((t) => t.takesPdf);

/// Tag of a result in Recientes («Unido», «Extraído»…).
String resultTag(AppLocalizations l10n, ResultKind kind) => switch (kind) {
  ResultKind.merged => l10n.tagMerged,
  ResultKind.edited => l10n.tagEdited,
  ResultKind.extracted => l10n.tagExtracted,
  ResultKind.split => l10n.tagSplit,
  ResultKind.images => l10n.tagImages,
  ResultKind.reduced => l10n.tagReduced,
  ResultKind.scanned => l10n.tagScanned,
  ResultKind.photos => l10n.tagPhotos,
};

ToolTint resultTint(ResultKind kind) => switch (kind.tool) {
  ToolId.merge => ToolTint.merge,
  ToolId.organize => ToolTint.organize,
  ToolId.pdfToImage => ToolTint.toImage,
  ToolId.reduce => ToolTint.reduce,
  ToolId.scan => ToolTint.scan,
  ToolId.imagesToPdf => ToolTint.photos,
};
