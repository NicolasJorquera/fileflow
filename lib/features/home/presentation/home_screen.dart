import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/format/sizes.dart';
import '../../../design_system/theme.dart';
import '../../../design_system/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/registry.dart';

/// Inicio: privacy line, the tools available so far and the latest results.
/// The scan card and the ad slot arrive in H6 and H9.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// How many results Inicio shows; the rest are in Recientes (H5).
  static const _recentCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final recents = (ref.watch(recentsProvider).value ?? const []).take(_recentCount).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
          if (ref.watch(interruptedNoticeProvider)) ...[
            _Notice(
              text: l10n.interruptedNotice,
              closeLabel: l10n.close,
              onClose: ref.read(interruptedNoticeProvider.notifier).dismiss,
            ),
            const SizedBox(height: Space.l),
          ],
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: palette.success),
              const SizedBox(width: Space.s),
              Expanded(
                child: Text(l10n.privacyNote, style: text.bodySmall?.copyWith(color: palette.muted)),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          _SectionTitle(l10n.homeSection),
          for (final tool in tools) ...[_ToolCard(tool: tool), const SizedBox(height: Space.s)],
          if (recents.isNotEmpty) ...[
            const SizedBox(height: Space.l),
            _SectionTitle(l10n.recentTitle),
            Material(
              color: palette.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.card),
                side: BorderSide(color: palette.line),
              ),
              child: Column(
                children: [
                  for (final (index, item) in recents.indexed) ...[
                    if (index > 0) const Divider(indent: Space.l, endIndent: Space.l),
                    ListTile(
                      leading: Icon(Icons.picture_as_pdf_outlined, color: palette.muted),
                      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        l10n.itemMeta(item.pages, formatBytes(item.sizeBytes, l10n.localeName)),
                        style: text.bodySmall?.copyWith(color: palette.muted),
                      ),
                      onTap: () => context.push(Routes.result(item.id)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.m),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    ),
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});

  final ToolEntry tool;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final (bg, fg) = palette.tools[tool.tint]!;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: palette.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: () => context.push(tool.route),
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.small)),
                child: Padding(
                  padding: const EdgeInsets.all(Space.s + 2),
                  child: Icon(tool.icon, color: fg),
                ),
              ),
              const SizedBox(width: Space.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tool.title(l10n), style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      tool.subtitle(l10n),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.closeLabel, required this.onClose});

  final String text, closeLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.warnSoft, borderRadius: BorderRadius.circular(Radii.card)),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.l, Space.xs, Space.xs, Space.xs),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: palette.warn),
            const SizedBox(width: Space.m),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.fg)),
            ),
            IconButton(tooltip: closeLabel, icon: const Icon(Icons.close), onPressed: onClose),
          ],
        ),
      ),
    );
  }
}
