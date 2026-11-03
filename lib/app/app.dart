import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/domain/settings.dart';
import '../design_system/theme.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class ListoApp extends ConsumerStatefulWidget {
  const ListoApp({super.key});

  @override
  ConsumerState<ListoApp> createState() => _ListoAppState();
}

class _ListoAppState extends ConsumerState<ListoApp> {
  late final GoRouter _router = buildRouter();

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
