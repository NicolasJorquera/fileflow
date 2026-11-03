import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/features/shared/processing_screen.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/merge/presentation/merge_controller.dart';
import 'package:fileflow/features/tools/merge/presentation/merge_screen.dart';
import 'package:fileflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../support/fakes.dart';

const _mb = 1024 * 1024;

final _picked = [
  const PickedFile(ref: 'content://1', name: 'Escaneo carnet ambos lados.pdf', sizeBytes: 3 * _mb),
  const PickedFile(ref: 'content://2', name: 'certificado-residencia.pdf', sizeBytes: _mb ~/ 2),
  const PickedFile(ref: 'content://3', name: 'certificado-firmado.pdf', sizeBytes: _mb),
  const PickedFile(ref: 'content://4', name: 'liquidaciones-sueldo.pdf', sizeBytes: 4 * _mb),
];

final _pdf = FakePdfService(
  pages: {'Escaneo carnet ambos lados.pdf': 2, 'certificado-residencia.pdf': 1, 'liquidaciones-sueldo.pdf': 11},
  failures: {'certificado-firmado.pdf': const PdfPasswordRequired()},
);

Widget _screen(Widget child, {Brightness brightness = Brightness.light, Locale locale = const Locale('es')}) =>
    ProviderScope(
      overrides: fakeOverrides(pdf: _pdf, recents: MemoryRecents([sampleRecent()])),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

/// A job stuck at 37 of 120 steps, for a still frame of Procesando.
ProcessingScreen _processing() {
  final events = StreamController<JobEvent>()..add(const JobProgress(37, 120));
  return ProcessingScreen(
    args: ProcessingArgs(job: JobRunner().enqueue((_) => events.stream), title: 'Uniendo…'),
  );
}

void main() {
  const phone = BoxConstraints.tightFor(width: 390, height: 844);
  final merge = MergeScreen(args: MergeArgs(picked: _picked));

  goldenTest(
    'Unir, Procesando y Resultado en claro, oscuro e inglés',
    fileName: 'merge',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        GoldenTestScenario(name: 'unir claro', constraints: phone, child: _screen(merge)),
        GoldenTestScenario(
          name: 'unir oscuro',
          constraints: phone,
          child: _screen(merge, brightness: Brightness.dark),
        ),
        GoldenTestScenario(
          name: 'merge en',
          constraints: phone,
          child: _screen(merge, locale: const Locale('en')),
        ),
        GoldenTestScenario(name: 'procesando', constraints: phone, child: _screen(_processing())),
        GoldenTestScenario(
          name: 'resultado claro',
          constraints: phone,
          child: _screen(const ResultScreen(id: 'r1')),
        ),
        GoldenTestScenario(
          name: 'resultado oscuro',
          constraints: phone,
          child: _screen(const ResultScreen(id: 'r1'), brightness: Brightness.dark),
        ),
        GoldenTestScenario(
          name: 'resultado pt',
          constraints: phone,
          child: _screen(const ResultScreen(id: 'r1'), locale: const Locale('pt')),
        ),
        GoldenTestScenario(name: 'unir vacío', constraints: phone, child: _screen(const MergeScreen())),
      ],
    ),
  );
}
