// H5 acceptance on a device with the real engine and platform codecs:
// Organizar (save, split), PDF a imagen and live thumbnails. Run with the
// device in airplane mode:
//
//   fvm flutter test integration_test/organize_test.dart --flavor dev
import 'dart:io';
import 'dart:typed_data';

import 'package:fileflow/app/router.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'support.dart';

/// Width and height from a JPEG's SOF0/SOF2 segment or a PNG's IHDR.
(int, int) imageSize(Uint8List bytes) {
  if (bytes[0] == 0x89 && bytes[1] == 0x50) {
    final data = ByteData.sublistView(bytes);
    return (data.getUint32(16), data.getUint32(20));
  }
  var i = 2;
  while (i < bytes.length) {
    final marker = bytes[i + 1];
    final length = (bytes[i + 2] << 8) | bytes[i + 3];
    if (marker == 0xC0 || marker == 0xC2) {
      return ((bytes[i + 7] << 8) | bytes[i + 8], (bytes[i + 5] << 8) | bytes[i + 6]);
    }
    i += 2 + length;
  }
  throw StateError('no size found');
}

Future<(int, List<int>)> pagesAndRotations(String path) async {
  final doc = await PdfDocument.openFile(path);
  try {
    return (doc.pages.length, [for (final p in doc.pages) p.rotation.index]);
  } finally {
    await doc.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  final env = DeviceEnv();

  setUpAll(env.setUp);
  tearDownAll(env.tearDown);

  Future<void> open(WidgetTester tester, String route, String path) async {
    await env.pumpApp(tester);
    final file = File(path);
    GoRouter.of(tester.element(find.text('FileFlow'))).push(
      route,
      extra: ToolArgs(
        local: [LocalFile(path: path, name: file.uri.pathSegments.last, sizeBytes: file.lengthSync())],
      ),
    );
    await waitFor(tester, find.byType(Scaffold).last);
  }

  testWidgets('Organizar: rotar, eliminar y guardar con el motor real; miniaturas reales', (tester) async {
    final source = await textPdf(env.sources.path, 'contrato', 9);
    final original = File(source).readAsBytesSync();
    await open(tester, Routes.organize, source);
    await waitFor(tester, find.text('contrato.pdf · 9 págs.'));
    // Thumbnails come from the engine and the platform codec.
    await waitFor(tester, find.byType(Image), timeout: const Duration(seconds: 30));

    for (final target in [
      find.bySemanticsLabel('Página 1'),
      find.text('Rotar'),
      find.bySemanticsLabel('Página 1, girada 90°'),
      find.bySemanticsLabel('Página 2'),
      find.text('Eliminar'),
    ]) {
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.widgetWithText(TextButton, 'Guardar'));
    await waitFor(tester, find.byType(ResultScreen));

    final item = env.recents.current.single;
    expect(item.name, 'contrato (editado).pdf');
    final (pages, rotations) = await pagesAndRotations(item.path);
    expect(pages, 8);
    expect(rotations.first, 1, reason: 'first page turned 90°');
    expect(await pageTexts(item.path), [
      for (var i = 1; i <= 9; i++)
        if (i != 2) 'contrato pagina $i',
    ]);
    expect(File(source).readAsBytesSync(), original, reason: 'the source never changes');
  });

  testWidgets('Separar 120 páginas cada 10: 12 PDF de 10 páginas, juntos', (tester) async {
    await env.recents.clear();
    final source = await textPdf(env.sources.path, 'libro', 120);
    await open(tester, Routes.organize, source);
    await waitFor(tester, find.text('libro.pdf · 120 págs.'));
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Separar…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Separar en 12 archivos'));
    await waitFor(tester, find.text('Separado en 12 archivos'));

    final item = env.recents.current.single;
    expect(item.files.first, 'libro (págs. 1-10).pdf');
    expect(item.files.last, 'libro (págs. 111-120).pdf');
    for (final path in item.paths) {
      expect(File(path).parent.path, item.dir);
      expect((await pagesAndRotations(path)).$1, 10);
    }
    expect((await pageTexts(item.paths[3])).first, 'libro pagina 31');
  });

  testWidgets('PDF a imagen: 12 páginas a 150 dpi, nunca más de 4.000 px', (tester) async {
    await env.recents.clear();
    final source = await textPdf(env.sources.path, 'boleta', 12);
    await open(tester, Routes.toImage, source);
    await waitFor(tester, find.text('Convertir 12 páginas'));
    await tester.tap(find.text('Convertir 12 páginas'));
    await waitFor(tester, find.text('12 imágenes listas'));

    final item = env.recents.current.single;
    expect(item.files.first, 'boleta-p01.jpg');
    for (final path in item.paths) {
      final (width, height) = imageSize(File(path).readAsBytesSync());
      expect(width, lessThanOrEqualTo(4000));
      expect(width, closeTo(595.28 * 150 / 72, 2), reason: 'A4 at 150 dpi');
      expect(height, greaterThan(width));
    }
  });

  testWidgets('PDF a imagen: PNG a 300 dpi', (tester) async {
    await env.recents.clear();
    final source = await textPdf(env.sources.path, 'carta', 2);
    await open(tester, Routes.toImage, source);
    await waitFor(tester, find.text('Convertir 2 páginas'));
    await tester.tap(find.text('PNG · sin pérdida'));
    await tester.tap(find.text('300 dpi'));
    await tester.pump();
    await tester.tap(find.text('Convertir 2 páginas'));
    await waitFor(tester, find.text('2 imágenes listas'));

    final item = env.recents.current.single;
    expect(item.files, ['carta-p01.png', 'carta-p02.png']);
    expect(imageSize(File(item.paths.first).readAsBytesSync()).$1, closeTo(595.28 * 300 / 72, 2));
  });
}
