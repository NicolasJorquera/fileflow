import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Home (H1 shell). The tool catalog, scan card and recents arrive from H4 on,
/// following the approved canvas.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.l, Space.xs, Space.l, Space.l),
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: palette.success),
              const SizedBox(width: Space.s),
              Expanded(
                child: Text(
                  l10n.privacyNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          Text(l10n.homeToolsPending, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
