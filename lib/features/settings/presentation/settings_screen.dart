import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/domain/settings.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Settings (H1: theme only). Language, page size, recents and privacy rows
/// arrive with their features.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final theme = ref.watch(themePreferenceProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.xs, Space.xs, 0, Space.s),
            child: Semantics(
              header: true,
              child: Text(
                l10n.settingsAppearance.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: palette.muted, letterSpacing: 0.3),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: palette.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.themeLabel, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: Space.m),
                  SegmentedButton<ThemePreference>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: ThemePreference.system, label: Text(l10n.themeSystem)),
                      ButtonSegment(value: ThemePreference.light, label: Text(l10n.themeLight)),
                      ButtonSegment(value: ThemePreference.dark, label: Text(l10n.themeDark)),
                    ],
                    selected: {theme},
                    onSelectionChanged: (s) => ref.read(themePreferenceProvider.notifier).select(s.single),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
