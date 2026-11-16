import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_engine/pdf_engine.dart';

import '../core/domain/ads.dart';
import '../core/domain/files.dart';
import '../core/domain/pdf.dart';
import '../core/domain/purchases.dart';
import '../core/domain/recents.dart';
import '../core/domain/scanner.dart';
import '../core/domain/settings.dart';
import '../core/jobs/jobs.dart';
import '../features/tools/merge/domain/merge_documents.dart';
import '../features/tools/organize/domain/organize_document.dart';
import '../features/tools/photos/domain/photos_to_pdf.dart';
import '../features/tools/reduce/domain/reduce_document.dart';
import '../features/tools/scan/domain/scan_document.dart';
import '../features/tools/to_image/domain/export_images.dart';
import 'flavor.dart';

// Ports are overridden at startup with real adapters (bootstrap.dart) and in
// tests with fakes. Presentation reads them here and never builds adapters.

Never _missing(String name) => throw UnimplementedError('$name must be overridden in bootstrap');

final adsGatewayProvider = Provider<AdsGateway>((ref) => _missing('adsGatewayProvider'));
final consentGatewayProvider = Provider<ConsentGateway>((ref) => _missing('consentGatewayProvider'));
final billingGatewayProvider = Provider<BillingGateway>((ref) => _missing('billingGatewayProvider'));

/// AdMob banner for a screen. The default shows nothing; bootstrap installs
/// AdMob. Screens read [adBannerProvider], never this one.
final adMobBannerProvider = Provider<Widget Function(AdPlacement)>(
  (ref) =>
      (_) => const SizedBox.shrink(),
);

/// Banner for a screen: nothing at all once «Sin anuncios» is bought.
final adBannerProvider = Provider<Widget Function(AdPlacement)>(
  (ref) => ref.watch(adsRemovedProvider) ? (_) => const SizedBox.shrink() : ref.watch(adMobBannerProvider),
);

final interstitialProvider = Provider<InterstitialCoordinator>(
  (ref) => InterstitialCoordinator(
    ads: ref.watch(adsGatewayProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    adsRemoved: () => ref.read(adsRemovedProvider),
  ),
);

/// Play first, then consent, then the SDK. A buyer (also on a new phone, once
/// Play answers) never sees the consent form or an ad. Failures are ignored:
/// the app works without ads.
final adsBootProvider = FutureProvider<void>((ref) async {
  try {
    await ref.read(removeAdsProvider.notifier).verifyWithStore().timeout(_playTimeout, onTimeout: () {});
    if (ref.read(adsRemovedProvider)) return;
    await ref.read(consentGatewayProvider).gather();
    await ref.read(adsGatewayProvider).start();
  } catch (_) {}
});

/// Ads do not wait longer than this for Play at startup; Play's answer still
/// applies when it comes.
const _playTimeout = Duration(seconds: 10);

final removeAdsProvider = NotifierProvider<RemoveAdsController, RemoveAdsState>(RemoveAdsController.new);

/// «Sin anuncios» is active: no banner and no interstitial.
final adsRemovedProvider = Provider<bool>((ref) => ref.watch(removeAdsProvider.select((s) => s.owned)));

/// The one-time purchase «Sin anuncios».
///
/// * The state is saved in the settings and read at startup: offline, a buyer
///   stays without ads.
/// * At startup Play is asked again ([verifyWithStore]). When Play answers,
///   its answer wins, also to revoke (a refund, or a backup from another
///   account). No server: the check runs on the phone.
/// * A pending purchase keeps the ads until Play confirms it.
class RemoveAdsController extends Notifier<RemoveAdsState> {
  BillingGateway get _billing => ref.read(billingGatewayProvider);

  @override
  RemoveAdsState build() {
    final sub = ref.watch(billingGatewayProvider).updates.listen(_onUpdate);
    ref.onDispose(sub.cancel);
    return RemoveAdsState(owned: ref.read(settingsRepositoryProvider).adsRemoved);
  }

  /// The price for the card in Ajustes.
  Future<void> loadProduct() async {
    final price = await _billing.price();
    if (ref.mounted && price != null) state = state.copyWith(price: price);
  }

  /// Opens Play's purchase sheet; the result arrives through the updates.
  Future<void> buy() async {
    if (state.owned || state.flow == PurchaseFlow.busy) return;
    _setFlow(PurchaseFlow.busy);
    final price = await _billing.price();
    if (price == null) {
      _setFlow(PurchaseFlow.unavailable);
      return;
    }
    if (ref.mounted) state = state.copyWith(price: price);
    switch (await _billing.buy()) {
      case BuyLaunch.launched:
        break;
      case BuyLaunch.unavailable:
        _setFlow(PurchaseFlow.unavailable);
      case BuyLaunch.alreadyOwned:
        await _restore(userInitiated: true);
      case BuyLaunch.failed:
        _setFlow(PurchaseFlow.error);
    }
  }

  /// «Restaurar compra».
  Future<void> restore() => _restore(userInitiated: true);

  /// At startup, silently.
  Future<void> verifyWithStore() => _restore(userInitiated: false);

  Future<void> _restore({required bool userInitiated}) async {
    if (userInitiated) _setFlow(PurchaseFlow.busy);
    final ownership = await _billing.ownership();
    if (ownership == null) {
      // Offline or no Play: what was saved stays.
      if (userInitiated) _setFlow(PurchaseFlow.unavailable);
      return;
    }
    await _save(ownership == StoreOwnership.owned);
    if (userInitiated) {
      _setFlow(switch (ownership) {
        StoreOwnership.owned => PurchaseFlow.restored,
        StoreOwnership.pending => PurchaseFlow.pending,
        StoreOwnership.none => PurchaseFlow.nothingToRestore,
      });
    }
  }

  Future<void> _onUpdate(PurchaseUpdate update) async {
    switch (update) {
      case PurchaseUpdate.purchased || PurchaseUpdate.restored:
        await _save(true);
        _setFlow(update == PurchaseUpdate.purchased ? PurchaseFlow.purchased : PurchaseFlow.restored);
      case PurchaseUpdate.pending:
        _setFlow(PurchaseFlow.pending);
      case PurchaseUpdate.canceled:
        _setFlow(PurchaseFlow.canceled);
      case PurchaseUpdate.error:
        _setFlow(PurchaseFlow.error);
      case PurchaseUpdate.alreadyOwned:
        await _restore(userInitiated: true);
    }
  }

  Future<void> _save(bool owned) async {
    if (!ref.mounted) return;
    state = state.copyWith(owned: owned);
    await ref.read(settingsRepositoryProvider).setAdsRemoved(owned);
  }

  void _setFlow(PurchaseFlow flow) {
    if (ref.mounted) state = state.copyWith(flow: flow);
  }
}

final flavorProvider = Provider<Flavor>((ref) => Flavor.prod);
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => _missing('settingsRepositoryProvider'));
final fileGatewayProvider = Provider<FileGateway>((ref) => _missing('fileGatewayProvider'));
final imageCodecProvider = Provider<ImageCodec>((ref) => _missing('imageCodecProvider'));
final jobWorkspaceProvider = Provider<JobWorkspace>((ref) => _missing('jobWorkspaceProvider'));
final pdfEngineProvider = Provider<PdfEngine>((ref) => const PdfiumEngine());
final pdfServiceProvider = Provider<PdfService>((ref) => _missing('pdfServiceProvider'));
final scannerGatewayProvider = Provider<ScannerGateway>((ref) => _missing('scannerGatewayProvider'));
final thumbnailSourceProvider = Provider<ThumbnailSource>((ref) => _missing('thumbnailSourceProvider'));
final recentsRepositoryProvider = Provider<RecentsRepository>((ref) => _missing('recentsRepositoryProvider'));
final jobRunnerProvider = Provider<JobRunner>((ref) => JobRunner());

/// Current time; tests replace it to make results expire on demand.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Results kept in the app, newest first.
final recentsProvider = StreamProvider<List<RecentItem>>((ref) => ref.watch(recentsRepositoryProvider).watch());

final organizeDocumentProvider = Provider<OrganizeDocument>(
  (ref) => OrganizeDocument(pdf: ref.watch(pdfServiceProvider), recents: ref.watch(recentsRepositoryProvider)),
);

final exportImagesProvider = Provider<ExportImages>(
  (ref) => ExportImages(pdf: ref.watch(pdfServiceProvider), recents: ref.watch(recentsRepositoryProvider)),
);

final reduceDocumentProvider = Provider<ReduceDocument>(
  (ref) => ReduceDocument(pdf: ref.watch(pdfServiceProvider), recents: ref.watch(recentsRepositoryProvider)),
);

final photosToPdfProvider = Provider<PhotosToPdf>(
  (ref) => PhotosToPdf(pdf: ref.watch(pdfServiceProvider), recents: ref.watch(recentsRepositoryProvider)),
);

final scanDocumentProvider = Provider<ScanDocument>(
  (ref) => ScanDocument(scanner: ref.watch(scannerGatewayProvider), recents: ref.watch(recentsRepositoryProvider)),
);

/// Country of the device locale, for the automatic page size of Fotos a PDF.
final regionProvider = Provider<String?>((ref) => null);

final mergeDocumentsProvider = Provider<MergeDocuments>(
  (ref) => MergeDocuments(pdf: ref.watch(pdfServiceProvider), recents: ref.watch(recentsRepositoryProvider)),
);

/// Job folders found at startup: the system killed the app mid-job (RF-08).
final interruptedJobsProvider = Provider<int>((ref) => 0);

/// Whether Inicio still shows the «operación interrumpida» notice. It shows
/// once per launch that found leftovers, until the user closes it.
final interruptedNoticeProvider = NotifierProvider<InterruptedNoticeController, bool>(InterruptedNoticeController.new);

class InterruptedNoticeController extends Notifier<bool> {
  @override
  bool build() => ref.read(interruptedJobsProvider) > 0;

  void dismiss() => state = false;
}

final themePreferenceProvider = NotifierProvider<ThemePreferenceController, ThemePreference>(
  ThemePreferenceController.new,
);

/// App language tag, null for the phone's (Ajustes).
final languageProvider = NotifierProvider<LanguageController, String?>(LanguageController.new);

class LanguageController extends Notifier<String?> {
  @override
  String? build() => ref.read(settingsRepositoryProvider).language;

  Future<void> select(String? tag) async {
    state = tag;
    await ref.read(settingsRepositoryProvider).setLanguage(tag);
  }
}

/// Page size Fotos a PDF starts with (Ajustes).
final defaultPageProvider = NotifierProvider<DefaultPageController, PagePreset>(DefaultPageController.new);

class DefaultPageController extends Notifier<PagePreset> {
  @override
  PagePreset build() => ref.read(settingsRepositoryProvider).defaultPage;

  Future<void> select(PagePreset value) async {
    state = value;
    await ref.read(settingsRepositoryProvider).setDefaultPage(value);
  }
}

/// How long results stay in Recientes (Ajustes).
final retentionProvider = NotifierProvider<RetentionController, RecentsRetention>(RetentionController.new);

class RetentionController extends Notifier<RecentsRetention> {
  @override
  RecentsRetention build() => ref.read(settingsRepositoryProvider).retention;

  /// Applies at once: a shorter period deletes what is already older.
  Future<void> select(RecentsRetention value) async {
    state = value;
    await ref.read(settingsRepositoryProvider).setRetention(value);
    await ref.read(purgeRecentsProvider)();
  }
}

/// Removes expired results now. Runs at startup, when the app comes back to
/// the foreground, when Recientes opens and when the period changes.
final purgeRecentsProvider = Provider<Future<int> Function()>(
  (ref) =>
      () => ref
          .read(recentsRepositoryProvider)
          .purgeExpired(ref.read(clockProvider)(), ref.read(retentionProvider).period),
);

class ThemePreferenceController extends Notifier<ThemePreference> {
  @override
  ThemePreference build() => ref.read(settingsRepositoryProvider).theme;

  Future<void> select(ThemePreference value) async {
    state = value;
    await ref.read(settingsRepositoryProvider).setTheme(value);
  }
}
