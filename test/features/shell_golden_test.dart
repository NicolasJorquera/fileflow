import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fileflow/app/providers.dart';
import 'package:fileflow/core/domain/settings.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/features/home/presentation/home_screen.dart';
import 'package:fileflow/features/settings/presentation/privacy_screen.dart';
import 'package:fileflow/features/settings/presentation/settings_screen.dart';
import 'package:fileflow/l10n/app_localizations.dart';

import '../support/fakes.dart';

/// One phone-sized screen with the real theme, locale and providers.
Widget _screen(
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('es'),
  bool rtl = false,
}) {
  return ProviderScope(
    overrides: fakeOverrides(
      recents: MemoryRecents([
        sampleRecent(),
        sampleRecent(id: 'r2', name: 'Escaneo carnet ambos lados.pdf', pages: 2),
      ]),
    ),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(brightness),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, page) =>
          Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: page!),
      home: child,
    ),
  );
}

void main() {
  const phone = BoxConstraints.tightFor(width: 390, height: 844);

  goldenTest(
    'Inicio y Ajustes en claro, oscuro, inglés y RTL',
    fileName: 'shell',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        GoldenTestScenario(name: 'inicio claro', constraints: phone, child: _screen(const HomeScreen())),
        GoldenTestScenario(
          name: 'inicio oscuro',
          constraints: phone,
          child: _screen(const HomeScreen(), brightness: Brightness.dark),
        ),
        GoldenTestScenario(
          name: 'home en',
          constraints: phone,
          child: _screen(const HomeScreen(), locale: const Locale('en')),
        ),
        GoldenTestScenario(name: 'inicio rtl', constraints: phone, child: _screen(const HomeScreen(), rtl: true)),
        GoldenTestScenario(name: 'ajustes claro', constraints: phone, child: _screen(const SettingsScreen())),
        GoldenTestScenario(
          name: 'ajustes oscuro',
          constraints: phone,
          child: _screen(const SettingsScreen(), brightness: Brightness.dark),
        ),
        GoldenTestScenario(
          name: 'ajustes pt',
          constraints: phone,
          child: _screen(const SettingsScreen(), locale: const Locale('pt')),
        ),
        GoldenTestScenario(name: 'ajustes rtl', constraints: phone, child: _screen(const SettingsScreen(), rtl: true)),
        GoldenTestScenario(name: 'privacidad', constraints: phone, child: _screen(const PrivacyScreen())),
        GoldenTestScenario(
          name: 'privacidad oscuro',
          constraints: phone,
          child: _screen(const PrivacyScreen(), brightness: Brightness.dark),
        ),
      ],
    ),
  );

  testWidgets('elegir Oscuro en Ajustes cambia el tema al instante', (tester) async {
    final settings = MemorySettings();
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeOverrides(settings: settings),
        child: Consumer(
          builder: (context, ref, _) {
            final pref = ref.watch(themePreferenceProvider);
            return MaterialApp(
              theme: buildTheme(Brightness.light),
              darkTheme: buildTheme(Brightness.dark),
              themeMode: pref == ThemePreference.dark ? ThemeMode.dark : ThemeMode.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('es'),
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    expect(settings.theme, ThemePreference.dark);
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness, Brightness.dark);
  });

  testWidgets('pantallas cumplen las guías de accesibilidad', (tester) async {
    final handle = tester.ensureSemantics();
    for (final screen in const [HomeScreen(), SettingsScreen()]) {
      await tester.pumpWidget(_screen(screen));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
    handle.dispose();
  });
}
