import 'package:alchemist/alchemist.dart';
import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/photos/presentation/photos_screen.dart';
import 'package:fileflow/features/tools/reduce/presentation/reduce_screen.dart';
import 'package:fileflow/features/tools/scan/presentation/scan_action.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:fileflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/fakes.dart';

const _mb = 1024 * 1024;

MemoryRecents _recents() => MemoryRecents([
  sampleRecent(
    id: 'ok',
    name: 'Postulación beca (reducido).pdf',
    kind: ResultKind.reduced,
    pages: 12,
    sizeBytes: (1.7 * _mb).round(),
  ).copyWithTarget(input: 28 * _mb, target: 2 * _mb),
  sampleRecent(
    id: 'missed',
    name: 'cartola-octubre (reducido).pdf',
    kind: ResultKind.reduced,
    pages: 120,
    sizeBytes: (2.6 * _mb).round(),
  ).copyWithTarget(input: 31 * _mb, target: _mb),
]);

extension on RecentItem {
  RecentItem copyWithTarget({required int input, required int target}) => RecentItem(
    id: id,
    name: name,
    dir: dir,
    files: files,
    kind: kind,
    pages: pages,
    sizeBytes: sizeBytes,
    createdAt: createdAt,
    inputBytes: input,
    targetBytes: target,
  );
}

Widget _screen(Widget child, {Brightness brightness = Brightness.light, Locale locale = const Locale('es')}) =>
    ProviderScope(
      overrides: fakeOverrides(
        pdf: FakePdfService(pages: {'cartola-octubre.pdf': 12}),
        recents: _recents(),
        files: FakeFileGateway()
          ..nextImages = [
            for (final n in ['carnet-1.jpg', 'carnet-2.jpg', 'boleta.heic', 'dañada.jpg', 'recibo.png', 'firma.jpg'])
              PickedFile(ref: 'content://media/$n', name: n, sizeBytes: 3000000),
          ],
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

/// Inicio-like backdrop with the E-SCAN-01 sheet open.
class _ScanSheet extends StatefulWidget {
  const _ScanSheet();

  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<_ScanSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => showScannerProblem(context, ScannerIssue.moduleNotDownloaded));
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

void main() {
  const phone = BoxConstraints.tightFor(width: 390, height: 844);
  const reduce = ReduceScreen(
    args: ToolArgs(
      local: [LocalFile(path: '/in/cartola-octubre.pdf', name: 'cartola-octubre.pdf', sizeBytes: 28 * _mb)],
    ),
  );

  goldenTest(
    'Reducir, Fotos a PDF, escáner sin conexión y resultados de Reducir',
    fileName: 'h6',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        GoldenTestScenario(name: 'reducir', constraints: phone, child: _screen(reduce)),
        GoldenTestScenario(
          name: 'reducir oscuro',
          constraints: phone,
          child: _screen(reduce, brightness: Brightness.dark),
        ),
        GoldenTestScenario(
          name: 'reduce en',
          constraints: phone,
          child: _screen(reduce, locale: const Locale('en')),
        ),
        GoldenTestScenario(name: 'fotos a pdf', constraints: phone, child: _screen(const PhotosScreen())),
        GoldenTestScenario(
          name: 'cumplió la meta',
          constraints: phone,
          child: _screen(const ResultScreen(id: 'ok')),
        ),
        GoldenTestScenario(
          name: 'no alcanzó la meta',
          constraints: phone,
          child: _screen(const ResultScreen(id: 'missed')),
        ),
        GoldenTestScenario(
          name: 'no alcanzó oscuro',
          constraints: phone,
          child: _screen(const ResultScreen(id: 'missed'), brightness: Brightness.dark),
        ),
        GoldenTestScenario(name: 'escáner sin conexión', constraints: phone, child: _screen(const _ScanSheet())),
      ],
    ),
  );
}
