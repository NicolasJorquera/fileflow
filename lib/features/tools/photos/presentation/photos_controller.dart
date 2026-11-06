import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/domain/failures.dart';
import '../../../../core/domain/files.dart';
import '../../../../core/domain/pdf.dart';
import '../../../../core/domain/result.dart';
import '../../../../core/domain/tools.dart';
import '../../../../core/jobs/jobs.dart';
import '../../shared/presentation/run_job.dart';

/// One photo of the grid: copied into the job folder with a small upright
/// thumbnail, or marked unreadable (E-IMG-01: it is left out).
class PhotoItem {
  const PhotoItem({
    required this.key,
    required this.name,
    this.file,
    this.thumbnail,
    this.turns = 0,
    this.unreadable = false,
  });

  final int key;
  final String name;
  final LocalFile? file;
  final String? thumbnail;
  final int turns;
  final bool unreadable;

  bool get isReady => thumbnail != null && file != null;
  bool get isPreparing => !isReady && !unreadable;

  PhotoItem copyWith({LocalFile? file, String? thumbnail, int? turns, bool? unreadable}) => PhotoItem(
    key: key,
    name: name,
    file: file ?? this.file,
    thumbnail: thumbnail ?? this.thumbnail,
    turns: turns ?? this.turns,
    unreadable: unreadable ?? this.unreadable,
  );
}

enum PhotoQuality {
  high(300, 90),
  balanced(200, 80);

  const PhotoQuality(this.dpi, this.jpegQuality);

  final int dpi, jpegQuality;

  /// Bytes per pixel a JPEG photo usually takes at this quality: what the
  /// «Tamaño estimado» uses.
  double get bytesPerPixel => this == high ? 0.12 : 0.1;
}

class PhotosState {
  const PhotosState({
    this.items = const [],
    this.preset = PagePreset.auto,
    this.margin = false,
    this.quality = PhotoQuality.balanced,
  });

  final List<PhotoItem> items;
  final PagePreset preset;
  final bool margin;
  final PhotoQuality quality;

  List<PhotoItem> get ready => [
    for (final i in items)
      if (i.isReady) i,
  ];
  int get unreadable => items.where((i) => i.unreadable).length;
  bool get preparing => items.any((i) => i.isPreparing);
  bool get canCreate => ready.isNotEmpty && !preparing;

  /// Rough: every page the size of an A4 at the chosen resolution.
  int get estimatedBytes =>
      (ready.length * (8.27 * quality.dpi) * (11.69 * quality.dpi) * quality.bytesPerPixel).round();

  PhotosState copyWith({List<PhotoItem>? items, PagePreset? preset, bool? margin, PhotoQuality? quality}) =>
      PhotosState(
        items: items ?? this.items,
        preset: preset ?? this.preset,
        margin: margin ?? this.margin,
        quality: quality ?? this.quality,
      );
}

final photosControllerProvider = NotifierProvider.autoDispose<PhotosController, PhotosState>(PhotosController.new);

/// Fotos a PDF: photos are copied into a job folder one at a time, each with
/// a thumbnail decoded scaled by the platform (HEIC included).
class PhotosController extends Notifier<PhotosState> {
  final _imports = CancelToken();
  Future<JobDir>? _dir;
  Future<void> _queue = Future.value();
  var _nextKey = 0;

  static const _thumbnailSide = 360;

  @override
  PhotosState build() {
    final workspace = ref.read(jobWorkspaceProvider);
    ref.onDispose(() {
      _imports.cancel();
      final dir = _dir;
      if (dir != null) _queue.whenComplete(() async => workspace.delete(await dir));
    });
    return const PhotosState();
  }

  /// Opens the Photo Picker for the room left. Returns the failure to show.
  Future<AppFailure?> pick() async {
    final room = PhotoLimits.maxPhotos - state.items.length;
    if (room <= 0) return const LimitExceeded(Limit.images, PhotoLimits.maxPhotos, PhotoLimits.maxPhotos);
    return switch (await ref.read(fileGatewayProvider).pickImages(max: room)) {
      Ok(:final value) => addPicked(value),
      Err(:final failure) => failure,
    };
  }

  /// Adds photos chosen in the picker or shared from another app.
  AppFailure? addPicked(List<PickedFile> photos) {
    final room = PhotoLimits.maxPhotos - state.items.length;
    for (final picked in photos.take(room)) {
      final item = PhotoItem(key: _nextKey++, name: picked.name);
      state = state.copyWith(items: [...state.items, item]);
      _queue = _queue.then((_) => _imports.isCancelled ? null : _import(item.key, picked));
    }
    return photos.length > room
        ? LimitExceeded(Limit.images, state.items.length + photos.length - room, PhotoLimits.maxPhotos)
        : null;
  }

  Future<void> _import(int key, PickedFile picked) async {
    final dir = await (_dir ??= ref.read(jobWorkspaceProvider).create());
    final copied = await ref.read(fileGatewayProvider).importToJob(picked, dir, token: _imports);
    if (!ref.mounted) return;
    final file = copied.valueOrNull;
    if (file == null) return _update(key, (i) => i.copyWith(unreadable: true));
    final thumb = await ref
        .read(imageCodecProvider)
        .preparePhoto(
          src: file.path,
          dest: '${dir.workDir}/thumb_$key.jpg',
          maxWidth: _thumbnailSide,
          maxHeight: _thumbnailSide,
          quality: 70,
        );
    _update(
      key,
      (i) => thumb.isOk
          ? i.copyWith(file: file, thumbnail: '${dir.workDir}/thumb_$key.jpg')
          : i.copyWith(unreadable: true),
    );
  }

  void _update(int key, PhotoItem Function(PhotoItem) change) {
    if (!ref.mounted) return;
    state = state.copyWith(items: [for (final i in state.items) i.key == key ? change(i) : i]);
  }

  void rotate(int key) => _update(key, (i) => i.copyWith(turns: (i.turns + 1) % 4));

  (int, PhotoItem) remove(int key) {
    final index = state.items.indexWhere((i) => i.key == key);
    final item = state.items[index];
    state = state.copyWith(items: [...state.items]..removeAt(index));
    return (index, item);
  }

  void restore((int, PhotoItem) removed) {
    final (index, item) = removed;
    state = state.copyWith(items: [...state.items]..insert(index.clamp(0, state.items.length), item));
  }

  void moveTo(int key, int position) {
    final items = [...state.items];
    final item = items.removeAt(items.indexWhere((i) => i.key == key));
    items.insert(position.clamp(0, items.length), item);
    state = state.copyWith(items: items);
  }

  void moveOne(int key, int delta) {
    final from = state.items.indexWhere((i) => i.key == key);
    final to = from + delta;
    if (to >= 0 && to < state.items.length) moveTo(key, to);
  }

  void setPreset(PagePreset preset) => state = state.copyWith(preset: preset);
  void setMargin(bool margin) => state = state.copyWith(margin: margin);
  void setQuality(PhotoQuality quality) => state = state.copyWith(quality: quality);

  /// The page size «Automático» stands for here.
  PagePreset get resolvedPreset =>
      state.preset == PagePreset.auto ? resolveAutoPage(ref.read(regionProvider)) : state.preset;

  Job create(String name) {
    final ready = state.ready;
    final spec = PhotoPageSpec(
      preset: resolvedPreset,
      margin: state.margin,
      dpi: state.quality.dpi,
      quality: state.quality.jpegQuality,
    );
    return runKeepingAlive(
      ref,
      ref
          .read(photosToPdfProvider)
          .call(
            [for (final i in ready) PhotoInput(i.file!.path, i.turns)],
            spec: spec,
            name: name,
            inputBytes: ready.fold<int>(0, (sum, i) => sum + i.file!.sizeBytes),
          ),
    );
  }
}
