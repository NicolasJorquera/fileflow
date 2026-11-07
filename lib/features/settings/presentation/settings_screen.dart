import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/flavor.dart';
import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/version.dart';
import '../../../core/domain/pdf.dart';
import '../../../core/domain/settings.dart';
import '../../../core/format/sizes.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/retention_label.dart';

/// Ajustes (UX v1.0): theme, language, default page size, Recientes, privacy
/// and about.
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
          _SectionLabel(l10n.settingsAppearance),
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
          const SizedBox(height: Space.s),
          _Card(
            children: [
              ListTile(
                title: Text(l10n.languageLabel),
                subtitle: Text(_languageName(l10n, ref.watch(languageProvider))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _chooseLanguage(context, ref),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          _SectionLabel(l10n.settingsDocuments),
          _Card(
            children: [
              ListTile(
                title: Text(l10n.defaultPageLabel),
                subtitle: Text(_pageName(l10n, ref.watch(defaultPageProvider))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _choosePage(context, ref),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          _SectionLabel(l10n.settingsRecents),
          const _RetentionCard(),
          const SizedBox(height: Space.xl),
          _SectionLabel(l10n.settingsPrivacy),
          _Card(
            children: [
              ListTile(
                leading: Icon(Icons.verified_user_outlined, color: palette.success),
                title: Text(l10n.privacyTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.privacy),
              ),
              const Divider(indent: Space.l, endIndent: Space.l),
              ListTile(
                leading: const Icon(Icons.tune_outlined),
                title: Text(l10n.adsOptionsTitle),
                subtitle: Text(l10n.adsOptionsBody),
                onTap: () => ref.read(consentGatewayProvider).showPrivacyOptions(),
              ),
              const Divider(indent: Space.l, endIndent: Space.l),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutTitle),
                subtitle: Text(l10n.aboutVersion(appVersion)),
                onTap: () =>
                    showLicensePage(context: context, applicationName: l10n.appName, applicationVersion: appVersion),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          if (ref.watch(flavorProvider) == Flavor.dev) ...[
            const SizedBox(height: Space.xl),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Diagnóstico (solo dev)'),
              onTap: () => context.push(Routes.diagnostics),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Space.xs, Space.xs, 0, Space.s),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.palette.muted, letterSpacing: 0.3),
      ),
    ),
  );
}

/// «Borrar resultados»: 1, 7 or 30 days, or never. A shorter period warns how
/// many results go right away (UX v1.0, Ajustes).
class _RetentionCard extends ConsumerWidget {
  const _RetentionCard();

  Future<void> _select(BuildContext context, WidgetRef ref, RecentsRetention value) async {
    final l10n = AppLocalizations.of(context);
    final (count, bytes) = ref.read(recentsRepositoryProvider).expiring(ref.read(clockProvider)(), value.period);
    if (count > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.retentionShortenTitle),
          content: Text(l10n.retentionShortenBody(count, formatBytes(bytes, l10n.localeName))),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.clearAllConfirm)),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(retentionProvider.notifier).select(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final retention = ref.watch(retentionProvider);
    return Material(
      color: palette.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s),
        child: RadioGroup<RecentsRetention>(
          groupValue: retention,
          onChanged: (value) => _select(context, ref, value!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                child: Text(l10n.retentionLabel, style: Theme.of(context).textTheme.bodyLarge),
              ),
              for (final option in RecentsRetention.values)
                RadioListTile<RecentsRetention>(
                  value: option,
                  title: Text(
                    option.period == null ? l10n.retentionNever : l10n.retentionAfter(retentionLabel(l10n, option)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: context.palette.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.card),
      side: BorderSide(color: context.palette.line),
    ),
    child: Column(children: children),
  );
}

/// The languages of 1.0 (Gate C) by their own names, so anyone can find theirs.
const _languages = <String?>[null, 'es', 'es_ES', 'en', 'pt'];

String _languageName(AppLocalizations l10n, String? tag) => switch (tag) {
  null => l10n.languageSystem,
  'es' => 'Español (Latinoamérica)',
  'es_ES' => 'Español (España)',
  'en' => 'English',
  'pt' => 'Português (Brasil)',
  _ => tag,
};

String _pageName(AppLocalizations l10n, PagePreset preset) => switch (preset) {
  PagePreset.auto => l10n.pageAuto,
  PagePreset.a4 => 'A4',
  PagePreset.letter => l10n.pageLetter,
  PagePreset.oficio => l10n.pageOficio,
  PagePreset.fitImage => l10n.pageFitImage,
};

Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) => _chooseFrom<String?>(
  context,
  values: _languages,
  current: ref.read(languageProvider),
  label: (l10n, tag) => _languageName(l10n, tag),
  onSelected: ref.read(languageProvider.notifier).select,
);

Future<void> _choosePage(BuildContext context, WidgetRef ref) => _chooseFrom<PagePreset>(
  context,
  values: PagePreset.values,
  current: ref.read(defaultPageProvider),
  label: _pageName,
  onSelected: ref.read(defaultPageProvider.notifier).select,
);

Future<void> _chooseFrom<T>(
  BuildContext context, {
  required List<T> values,
  required T current,
  required String Function(AppLocalizations, T) label,
  required Future<void> Function(T) onSelected,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);
    return SafeArea(
      child: RadioGroup<T>(
        groupValue: current,
        onChanged: (value) {
          Navigator.of(sheetContext).pop();
          onSelected(value as T);
        },
        child: ListView(
          shrinkWrap: true,
          children: [for (final v in values) RadioListTile<T>(value: v, title: Text(label(l10n, v)))],
        ),
      ),
    );
  },
);
