// Renders Play Store phone screenshots (1080x2160, 2:1) from the real screens with
// sample data, in es, en and pt. No ads, no device needed.
// Run: flutter test tool/brand/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/features/home/presentation/home_screen.dart';
import 'package:fileflow/features/recents/presentation/recents_screen.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/reduce/presentation/reduce_screen.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:fileflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/fakes.dart';

const _mb = 1024 * 1024;
RecentItem _reduced(RecentItem r, {required int input, required int target}) => RecentItem(
  id: r.id,
  name: r.name,
  dir: r.dir,
  files: r.files,
  kind: r.kind,
  pages: r.pages,
  sizeBytes: r.sizeBytes,
  createdAt: r.createdAt,
  inputBytes: input,
  targetBytes: target,
);

MemoryRecents _recents() => MemoryRecents([
  _reduced(
    sampleRecent(
      id: 'ok',
      name: 'Postulación beca (reducido).pdf',
      kind: ResultKind.reduced,
      pages: 12,
      sizeBytes: (1.7 * _mb).round(),
      createdAt: testNow.subtract(const Duration(minutes: 20)),
    ),
    input: 28 * _mb,
    target: 2 * _mb,
  ),
  sampleRecent(id: 'a', name: 'Documento unido 2026-11-03.pdf', createdAt: testNow.subtract(const Duration(hours: 1))),
  sampleRecent(
    id: 'b',
    name: 'contrato-arriendo (págs. 3-5).pdf',
    kind: ResultKind.extracted,
    pages: 3,
    sizeBytes: 629145,
    createdAt: testNow.subtract(const Duration(hours: 2)),
  ),
  sampleRecent(
    id: 'c',
    name: 'Escaneo carnet ambos lados.pdf',
    kind: ResultKind.scanned,
    pages: 2,
    sizeBytes: 412000,
    createdAt: testNow.subtract(const Duration(days: 2)),
  ),
]);

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await loader.load();
}

ThemeData _withFallback(ThemeData t) => t.copyWith(
  textTheme: t.textTheme.apply(fontFamilyFallback: ['Fallback']),
  primaryTextTheme: t.primaryTextTheme.apply(fontFamilyFallback: ['Fallback']),
);

void main() {
  final fonts = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';

  setUpAll(() async {
    await _font('Roboto', [
      for (final w in ['Regular', 'Medium', 'Bold']) '$fonts/Roboto-$w.ttf',
    ]);
    await _font('MaterialIcons', ['$fonts/MaterialIcons-Regular.otf']);
    // Symbols Roboto lacks (→, …); Android falls back to Noto the same way.
    await _font('Fallback', ['/System/Library/Fonts/Supplemental/Arial Unicode.ttf']);
  });

  const reduce = ReduceScreen(
    args: ToolArgs(
      local: [LocalFile(path: '/in/cartola-octubre.pdf', name: 'cartola-octubre.pdf', sizeBytes: 28 * _mb)],
    ),
  );
  final screens = <String, Widget>{
    '1-inicio': const HomeScreen(),
    '2-reducir': reduce,
    '3-resultado': const ResultScreen(id: 'ok'),
    '4-recientes': const RecentsScreen(),
  };

  for (final locale in ['es', 'en', 'pt']) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('$locale $name', (tester) async {
        tester.view
          ..physicalSize = const Size(1080, 2160)
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: ProviderScope(
              overrides: fakeOverrides(
                pdf: FakePdfService(pages: {'cartola-octubre.pdf': 12}),
                recents: _recents(),
              ),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: _withFallback(buildTheme(Brightness.light)),
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: screen,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 3);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File('docs/store/graphics/screenshots/$locale/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!.buffer.asUint8List());
        });
      });
    }
  }
}
