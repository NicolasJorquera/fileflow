import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/settings.dart';
import '../design_system/theme.dart';
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
  }

  @override
  void dispose() {
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
      routerConfig: _router,
    );
  }
}
