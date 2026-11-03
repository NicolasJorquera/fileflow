import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/domain/tools.dart';
import '../../design_system/tokens.dart';
import '../../l10n/app_localizations.dart';

/// How Inicio presents a tool. Tools join the list as their milestone lands
/// (Plan de desarrollo: H4 Unir, H5 Organizar y PDF a imagen, H6 el resto).
class ToolEntry {
  const ToolEntry({
    required this.id,
    required this.icon,
    required this.tint,
    required this.route,
    required this.title,
    required this.subtitle,
  });

  final ToolId id;
  final IconData icon;
  final ToolTint tint;
  final String route;
  final String Function(AppLocalizations) title, subtitle;
}

final tools = <ToolEntry>[
  ToolEntry(
    id: ToolId.merge,
    icon: Icons.merge_type,
    tint: ToolTint.merge,
    route: Routes.merge,
    title: (l10n) => l10n.toolMergeTitle,
    subtitle: (l10n) => l10n.toolMergeSubtitle,
  ),
];
