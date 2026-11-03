import 'package:alchemist/alchemist.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/features/recents/presentation/recents_screen.dart';
import 'package:fileflow/features/settings/presentation/settings_screen.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/organize/presentation/organize_controller.dart';
import 'package:fileflow/features/tools/organize/presentation/organize_screen.dart';
import 'package:fileflow/features/tools/shared/presentation/source_loader.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:fileflow/features/tools/to_image/presentation/to_image_screen.dart';
import 'package:fileflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/fakes.dart';

const _contract = LocalFile(path: '/in/contrato-arriendo.pdf', name: 'contrato-arriendo.pdf', sizeBytes: 1258291);

/// Organizar as in the canvas: 9 pages, 3 to 5 selected.
class _SelectedPages extends OrganizeController {
  @override
  OrganizeState build() {
    super.build();
    return OrganizeState(
      status: OrganizeStatus.ready,
      source: const LoadedSource(file: _contract, pageCount: 9),
      pages: [for (var i = 0; i < 9; i++) OrgPage(i, i == 6 ? 1 : 0)],
      selected: const {2, 3, 4},
    );
  }
}

MemoryRecents _recents() => MemoryRecents([
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
    name: 'boleta-honorarios-oct (imágenes)',
    kind: ResultKind.images,
    pages: 12,
    files: [for (var i = 1; i <= 12; i++) 'boleta-honorarios-oct-p${'$i'.padLeft(2, '0')}.jpg'],
    sizeBytes: 3250585,
    createdAt: testNow.subtract(const Duration(days: 3)),
  ),
]);

Widget _screen(
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('es'),
  MemoryRecents? recents,
  bool organize = false,
}) => ProviderScope(
  overrides: [
    ...fakeOverrides(
      pdf: FakePdfService(pages: {'boleta-honorarios-oct.pdf': 12}),
      recents: recents ?? _recents(),
    ),
    if (organize) organizeControllerProvider.overrideWith(_SelectedPages.new),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(brightness),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  const phone = BoxConstraints.tightFor(width: 390, height: 844);
  const toImage = ToImageScreen(
    args: ToolArgs(
      local: [LocalFile(path: '/in/boleta-honorarios-oct.pdf', name: 'boleta-honorarios-oct.pdf', sizeBytes: 1258291)],
    ),
  );

  goldenTest(
    'Organizar, PDF a imagen, Recientes, Ajustes y Resultado con varios archivos',
    fileName: 'h5',
    builder: () => GoldenTestGroup(
      columns: 5,
      children: [
        GoldenTestScenario(
          name: 'organizar selección',
          constraints: phone,
          child: _screen(const OrganizeScreen(), organize: true),
        ),
        GoldenTestScenario(
          name: 'organizar oscuro',
          constraints: phone,
          child: _screen(const OrganizeScreen(), organize: true, brightness: Brightness.dark),
        ),
        GoldenTestScenario(name: 'pdf a imagen', constraints: phone, child: _screen(toImage)),
        GoldenTestScenario(
          name: 'to image en',
          constraints: phone,
          child: _screen(toImage, locale: const Locale('en')),
        ),
        GoldenTestScenario(
          name: 'resultado imágenes',
          constraints: phone,
          child: _screen(const ResultScreen(id: 'c')),
        ),
        GoldenTestScenario(name: 'recientes', constraints: phone, child: _screen(const RecentsScreen())),
        GoldenTestScenario(
          name: 'recientes oscuro',
          constraints: phone,
          child: _screen(const RecentsScreen(), brightness: Brightness.dark),
        ),
        GoldenTestScenario(
          name: 'recientes vacío',
          constraints: phone,
          child: _screen(const RecentsScreen(), recents: MemoryRecents()),
        ),
        GoldenTestScenario(
          name: 'recientes pt',
          constraints: phone,
          child: _screen(const RecentsScreen(), locale: const Locale('pt')),
        ),
        GoldenTestScenario(name: 'ajustes', constraints: phone, child: _screen(const SettingsScreen())),
      ],
    ),
  );
}
