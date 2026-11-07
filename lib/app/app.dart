import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/files.dart';
import '../core/domain/settings.dart';
import '../design_system/theme.dart';
import '../features/shared/result_actions.dart';
import '../features/tools/shared/presentation/tool_args.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class FileFlowApp extends ConsumerStatefulWidget {
  const FileFlowApp({super.key});

  @override
  ConsumerState<FileFlowApp> createState() => _FileFlowAppState();
}

class _FileFlowAppState extends ConsumerState<FileFlowApp> {
  late final GoRouter _router = buildRouter();

  /// Results expire while the app sits in the background too.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(purgeRecentsProvider)());
    _shares = ref.read(fileGatewayProvider).incomingShares().listen(_openShared);
  }

  late final StreamSubscription<List<PickedFile>> _shares;

  /// PRD RF-02: files from «Compartir» in other apps. Photos open Fotos a
  /// PDF, several PDFs open Unir, one PDF asks which tool.
  void _openShared(List<PickedFile> files) {
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (context == null || files.isEmpty) return;
    bool isPdf(PickedFile f) => f.mime == 'application/pdf' || f.name.toLowerCase().endsWith('.pdf');
    final pdfs = files.where(isPdf).toList();
    final images = files.where((f) => !isPdf(f)).toList();
    if (pdfs.isEmpty) {
      _router.push(Routes.photos, extra: ToolArgs(picked: images));
    } else if (pdfs.length > 1) {
      _router.push(Routes.merge, extra: ToolArgs(picked: pdfs));
    } else {
      showToolChooser(context, ToolArgs(picked: pdfs));
    }
  }

  @override
  void dispose() {
    _shares.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themePreferenceProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: switch (ref.watch(languageProvider)?.split('_')) {
        null => null,
        [final language] => Locale(language),
        [final language, final country, ...] => Locale(language, country),
        _ => null,
      },
      routerConfig: _router,
    );
  }
}
