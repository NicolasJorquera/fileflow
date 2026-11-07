import 'dart:io';

import 'package:fileflow/app/app.dart';
import 'package:fileflow/app/version.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/pdf.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/features/home/presentation/home_screen.dart';
import 'package:fileflow/features/recents/presentation/recents_screen.dart';
import 'package:fileflow/features/settings/presentation/privacy_screen.dart';
import 'package:fileflow/features/settings/presentation/settings_screen.dart';
import 'package:fileflow/features/shared/processing_screen.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/merge/presentation/merge_screen.dart';
import 'package:fileflow/features/tools/organize/presentation/organize_screen.dart';
import 'package:fileflow/features/tools/photos/presentation/photos_screen.dart';
import 'package:fileflow/features/tools/reduce/presentation/reduce_screen.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:fileflow/features/tools/to_image/presentation/to_image_screen.dart';
import 'package:fileflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

const _mb = 1024 * 1024;
const _pdf = LocalFile(path: '/in/cartola-octubre.pdf', name: 'cartola-octubre.pdf', sizeBytes: 28 * _mb);

MemoryRecents _recents() => MemoryRecents([
  sampleRecent(),
  RecentItem(
    id: 'red',
    name: 'cartola-octubre (reducido).pdf',
    dir: '/results/red',
    files: const ['cartola-octubre (reducido).pdf'],
    kind: ResultKind.reduced,
    pages: 120,
    sizeBytes: (2.6 * _mb).round(),
    createdAt: testNow,
    inputBytes: 31 * _mb,
    targetBytes: _mb,
  ),
  sampleRecent(
    id: 'img',
    name: 'boleta (imágenes)',
    kind: ResultKind.images,
    files: [for (var i = 1; i <= 12; i++) 'boleta-p${'$i'.padLeft(2, '0')}.jpg'],
  ),
]);

/// Every screen of 1.0 with data in it.
Map<String, Widget Function()> _screens() => {
  'inicio': () => const HomeScreen(),
  'ajustes': () => const SettingsScreen(),
  'privacidad': () => const PrivacyScreen(),
  'recientes': () => const RecentsScreen(),
  'unir': () => MergeScreen(
    args: ToolArgs(
      picked: [
        for (final n in ['Escaneo carnet ambos lados de la cédula.pdf', 'certificado-residencia.pdf'])
          PickedFile(ref: 'content://$n', name: n, sizeBytes: _mb),
      ],
    ),
  ),
  'organizar': () => const OrganizeScreen(args: ToolArgs(local: [_pdf])),
  'pdf a imagen': () => const ToImageScreen(args: ToolArgs(local: [_pdf])),
  'reducir': () => const ReduceScreen(args: ToolArgs(local: [_pdf])),
  'fotos': () => const PhotosScreen(),
  'resultado': () => const ResultScreen(id: 'r1'),
  'resultado reducido': () => const ResultScreen(id: 'red'),
  'resultado imágenes': () => const ResultScreen(id: 'img'),
  'procesando': () => ProcessingScreen(
    args: ProcessingArgs(job: JobRunner().enqueue((_) => Stream.value(const JobProgress(37, 120))), title: 'Uniendo…'),
  ),
};

Widget _app(Widget child, {double textScale = 1, Locale locale = const Locale('es'), bool rtl = false}) =>
    ProviderScope(
      overrides: fakeOverrides(
        pdf: FakePdfService(pages: {'cartola-octubre.pdf': 12}),
        recents: _recents(),
        files: FakeFileGateway()
          ..nextImages = [
            for (final n in ['carnet.jpg', 'dañada.jpg', 'recibo.png'])
              PickedFile(ref: 'content://$n', name: n, sizeBytes: _mb),
          ],
      ),
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, page) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: page!),
        ),
        home: child,
      ),
    );

void main() {
  /// Pumps without settling: Procesando has an endless animation.
  Future<void> pump(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(app);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  for (final MapEntry(key: name, value: screen) in _screens().entries) {
    group(name, () {
      testWidgets('texto al 200 % en un teléfono angosto: nada se corta', (tester) async {
        tester.view
          ..physicalSize = const Size(320, 640) * 3
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await pump(tester, _app(screen(), textScale: 2));
      });

      testWidgets('portugués y RTL: nada se corta', (tester) async {
        tester.view
          ..physicalSize = const Size(360, 720) * 3
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await pump(tester, _app(screen(), locale: const Locale('pt'), rtl: true));
      });

      testWidgets('áreas táctiles, etiquetas y contraste', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, _app(screen()));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    });
  }

  testWidgets('elegir English en Ajustes cambia el idioma al instante', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final settings = MemorySettings();
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeOverrides(settings: settings),
        child: const FileFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Igual que el teléfono'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(settings.language, 'en');
  });

  testWidgets('el tamaño de página por defecto llega a Fotos a PDF', (tester) async {
    final settings = MemorySettings()..defaultPage = PagePreset.oficio;
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeOverrides(
          settings: settings,
          files: FakeFileGateway()..nextImages = [const PickedFile(ref: 'content://a', name: 'a.jpg')],
        ),
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PhotosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Oficio (216 × 330 mm)'), findsOneWidget);
  });

  test('la versión de Ajustes es la de pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^version: (\S+?)\+', multiLine: true).firstMatch(pubspec)!.group(1), appVersion);
  });
}
