import 'dart:async';
import 'dart:typed_data';

import 'package:platform_files/platform_files.dart';

import '../../core/domain/failures.dart';
import '../../core/domain/files.dart';
import '../../core/domain/result.dart';
import '../../core/jobs/jobs.dart';

/// [FileGateway] and [ImageCodec] on the platform_files plugin. Maps every
/// plugin error code to an [AppFailure]; nothing native leaks upwards.
class PlatformFileGateway implements FileGateway, ImageCodec {
  PlatformFileGateway(this._api, {required this.freeSpacePath, this.cancelPoll = const Duration(milliseconds: 150)});

  final PlatformFilesApi _api;

  /// A path on the volume where jobs live, for free-space checks.
  final String freeSpacePath;
  final Duration cancelPoll;
  var _copies = 0;

  static const _pdf = 'application/pdf';

  Future<Result<T>> _guard<T>(Future<T> Function() action, {int requiredBytes = 0}) async {
    try {
      return Ok(await action());
    } on PlatformFilesException catch (e) {
      return Err(switch (e.code) {
        PlatformFilesException.accessLost => const SourceAccessLost(),
        PlatformFilesException.noSpace => InsufficientStorage(requiredBytes),
        PlatformFilesException.cancelled => const Cancelled(),
        PlatformFilesException.noApp => const NoAppAvailable(),
        _ => Unexpected('platform_files:${e.code}'),
      });
    }
  }

  static PickedFile _map(PickedDocument d) => PickedFile(ref: d.uri, name: d.name, sizeBytes: d.size, mime: d.mime);

  @override
  Future<Result<List<PickedFile>>> pickPdfs({bool multiple = false}) =>
      _guard(() async => (await _api.pickDocuments(mimeTypes: [_pdf], multiple: multiple)).map(_map).toList());

  @override
  Future<Result<List<PickedFile>>> pickImages({int max = 100}) =>
      _guard(() async => (await _api.pickImages(max: max)).map(_map).toList());

  @override
  Future<Result<LocalFile>> importToJob(PickedFile file, JobDir job, {CancelToken? token}) async {
    final size = file.sizeBytes;
    if (size != null) {
      final required = size * 2;
      final free = await _guard(() => _api.freeBytes(freeSpacePath));
      if (free case Ok(:final value) when value < required) return Err(InsufficientStorage(required));
    }
    final copyId = '${job.id}_${_copies++}';
    final dest = '${job.inputDir}/${_copies.toString().padLeft(4, '0')}_${_safeName(file.name)}';
    Timer? poll;
    if (token != null) {
      poll = Timer.periodic(cancelPoll, (_) {
        if (token.isCancelled) {
          poll?.cancel();
          _api.cancelCopy(copyId);
        }
      });
    }
    try {
      final copied = await _guard(
        () => _api.copyToFile(uri: file.ref, destPath: dest, copyId: copyId),
        requiredBytes: (size ?? 0) * 2,
      );
      return copied.map((bytes) => LocalFile(path: dest, name: file.name, sizeBytes: bytes));
    } finally {
      poll?.cancel();
    }
  }

  /// File names come from other apps: keep them readable, never a path.
  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f]'), '_').trim();
    return cleaned.isEmpty ? 'documento' : (cleaned.length > 120 ? cleaned.substring(cleaned.length - 120) : cleaned);
  }

  @override
  Future<Result<String?>> saveAs(LocalFile file, {required String suggestedName}) =>
      _guard(() => _api.saveAs(srcPath: file.path, name: suggestedName, mime: _mimeOf(file.path)));

  @override
  Future<Result<int?>> saveAllToFolder(List<LocalFile> files, {required List<String> names}) => _guard(
    () =>
        _api.saveAllToFolder(srcPaths: [for (final f in files) f.path], names: names, mime: _mimeOf(files.first.path)),
  );

  @override
  Future<Result<void>> share(List<LocalFile> files) =>
      _guard(() => _api.share(paths: [for (final f in files) f.path], mime: _mimeOf(files.first.path)));

  @override
  Future<Result<void>> openWith(LocalFile file) =>
      _guard(() => _api.openWith(path: file.path, mime: _mimeOf(file.path)));

  @override
  Stream<List<PickedFile>> incomingShares() => _api.incoming.map((docs) => docs.map(_map).toList());

  @override
  Future<Result<Uint8List>> encodeJpeg({
    required Uint8List rgba,
    required int width,
    required int height,
    required int targetWidth,
    required int targetHeight,
    required int quality,
  }) => _guard(
    () => _api.encodeJpeg(
      rgba: rgba,
      width: width,
      height: height,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    ),
  );

  @override
  Future<Result<int>> writeImage({
    required Uint8List rgba,
    required int width,
    required int height,
    required ImageFormat format,
    required int quality,
    required String path,
  }) => _guard(
    () => _api.encodeToFile(
      rgba: rgba,
      width: width,
      height: height,
      png: format == ImageFormat.png,
      quality: quality,
      destPath: path,
    ),
  );

  static String _mimeOf(String path) => switch (path.split('.').last.toLowerCase()) {
    'pdf' => _pdf,
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'zip' => 'application/zip',
    _ => 'application/octet-stream',
  };
}
