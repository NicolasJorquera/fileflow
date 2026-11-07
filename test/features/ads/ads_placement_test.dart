import 'package:fileflow/app/providers.dart';
import 'package:fileflow/design_system/theme.dart';
import 'package:fileflow/l10n/app_localizations.dart';
import 'package:fileflow/core/domain/ads.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:fileflow/features/home/presentation/home_screen.dart';
import 'package:fileflow/features/recents/presentation/recents_screen.dart';
import 'package:fileflow/features/shared/processing_screen.dart';
import 'package:fileflow/features/shared/result_screen.dart';
import 'package:fileflow/features/tools/merge/presentation/merge_screen.dart';
import 'package:fileflow/features/tools/organize/presentation/organize_screen.dart';
import 'package:fileflow/features/tools/photos/presentation/photos_screen.dart';
import 'package:fileflow/features/tools/reduce/presentation/reduce_screen.dart';
import 'package:fileflow/features/tools/shared/presentation/tool_args.dart';
import 'package:fileflow/features/tools/to_image/presentation/to_image_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

const _pdf = LocalFile(path: '/in/contrato.pdf', name: 'contrato.pdf', sizeBytes: 1000);

/// Banner requests made by the screens, in the order they were made.
class _Banners {
  final requested = <AdPlacement>[];
}

Future<void> _pumpWith(
  WidgetTester tester,
  Widget screen,
  _Banners banners, {
  FakeAds? ads,
  MemoryRecents? recents,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...fakeOverrides(recents: recents ?? MemoryRecents([sampleRecent()]), files: FakeFileGateway(), ads: ads),
        adBannerProvider.overrideWithValue((placement) {
          banners.requested.add(placement);
          return const SizedBox.shrink();
        }),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Each screen that shows document content (or file names, or runs a job) must never ask for a banner.
  final forbidden = <String, Widget Function()>{
    'organizar': () => const OrganizeScreen(args: ToolArgs(local: [_pdf])),
    'unir': () => const MergeScreen(args: ToolArgs(local: [_pdf, _pdf])),
    'pdf a imagen': () => const ToImageScreen(args: ToolArgs(local: [_pdf])),
    'fotos': () => const PhotosScreen(),
    'recientes': () => const RecentsScreen(),
    'procesando': () => ProcessingScreen(
      args: ProcessingArgs(job: JobRunner().enqueue((_) => const Stream.empty()), title: 'x'),
    ),
  };

  for (final MapEntry(key: name, value: screen) in forbidden.entries) {
    testWidgets('$name never asks for a banner (RN-08)', (tester) async {
      final banners = _Banners();
      await _pumpWith(tester, screen(), banners);
      expect(banners.requested.where((p) => !bannerAllowed(p)), isEmpty);
      expect(banners.requested, isEmpty, reason: 'this screen is not on the list of banner screens');
    });
  }

  testWidgets('Inicio, Resultado y Reducir piden banner (solo los permitidos)', (tester) async {
    final banners = _Banners();
    await _pumpWith(tester, const HomeScreen(), banners);
    expect(banners.requested.toSet(), {AdPlacement.home});

    final result = _Banners();
    await _pumpWith(tester, const ResultScreen(id: 'r1'), result);
    expect(result.requested.toSet(), {AdPlacement.result});

    final reduce = _Banners();
    await _pumpWith(tester, const ReduceScreen(args: ToolArgs(local: [_pdf])), reduce);
    await tester.pumpAndSettle();
    expect(reduce.requested, contains(AdPlacement.reduceOptions));
  });

  testWidgets('la vista previa es opcional: no aparece hasta que se pide', (tester) async {
    await _pumpWith(tester, const ResultScreen(id: 'r1'), _Banners());
    expect(find.text('Ver primera página'), findsOneWidget);
    expect(find.text('Ocultar primera página'), findsNothing);
    await tester.tap(find.text('Ver primera página'));
    await tester.pump();
    expect(find.text('Ocultar primera página'), findsOneWidget);
  });

  testWidgets('compartir un resultado con 5 tareas hechas muestra un intersticial', (tester) async {
    final ads = FakeAds();
    final settings = MemorySettings()..completedTasks = 5;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeOverrides(
            recents: MemoryRecents([sampleRecent()]),
            files: FakeFileGateway(),
            settings: settings,
            ads: ads,
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ResultScreen(id: 'r1'),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Compartir'));
    await tester.pump();
    expect(ads.shown, 1);
    expect(settings.interstitialAtTask, 5);
  });

  testWidgets('con 3 tareas o menos no se muestra intersticial', (tester) async {
    final ads = FakeAds();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeOverrides(recents: MemoryRecents([sampleRecent()]), files: FakeFileGateway(), ads: ads),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ResultScreen(id: 'r1'),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Compartir'));
    await tester.pump();
    expect(ads.requested, 0);
  });
}
