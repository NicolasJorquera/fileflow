import 'package:fileflow/app/router.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The real app shell (router, theme, Spanish) over [overrides]. Returns the
/// router so a test can open a route that takes `extra`.
Future<GoRouter> pumpApp(WidgetTester tester, List<Override> overrides, {String at = Routes.home}) async {
  final router = buildRouter(initialLocation: at);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: buildTheme(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
