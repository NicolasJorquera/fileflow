/// File plumbing for FileFlow on Android. See README.md.
library;

import 'package:flutter/services.dart';

/// A document chosen in a system picker or received through "Share". [uri] is
/// a content:// URI: read it once with [PlatformFilesApi.copyToFile].
class PickedDocument {
  const PickedDocument({required this.uri, required this.name, this.size, this.mime});

  factory PickedDocument.fromMap(Map<Object?, Object?> map) => PickedDocument(
    uri: map['uri']! as String,
    name: map['name']! as String,
    size: map['size'] as int?,
    mime: map['mime'] as String?,
  );

  final String uri;
  final String name;

  /// Bytes, when the provider reports it.
  final int? size;
  final String? mime;
}

/// [code] is one of the constants in this class.
class PlatformFilesException implements Exception {
  const PlatformFilesException(this.code, [this.message]);

  static const accessLost = 'access_lost';
  static const noSpace = 'no_space';
  static const io = 'io';
  static const cancelled = 'cancelled';
  static const busy = 'busy';
  static const noApp = 'no_app';
  static const notImplemented = 'not_implemented';
  static const imageUnreadable = 'image_unreadable';
  static const scannerModuleMissing = 'scanner_module_missing';
  static const scannerUnsupported = 'scanner_unsupported';

  final String code;

  /// Exception class name on the native side; never contains paths.
  final String? message;

  @override
  String toString() => 'PlatformFilesException($code${message == null ? '' : ', $message'})';
}

abstract interface class PlatformFilesApi {
  /// Empty when the user cancels.
  Future<List<PickedDocument>> pickDocuments({required List<String> mimeTypes, bool multiple = false});
  Future<List<PickedDocument>> pickImages({int max = 100});

  /// Streams [uri] into [destPath]; [copyId] lets [cancelCopy] stop it. Returns bytes copied.
  Future<int> copyToFile({required String uri, required String destPath, required String copyId});
  Future<void> cancelCopy(String copyId);

  /// Asks where to save and streams [srcPath] there. Null when cancelled.
  Future<String?> saveAs({required String srcPath, required String name, required String mime});

  /// Asks for a folder and streams every file there. Null when cancelled.
  Future<int?> saveAllToFolder({required List<String> srcPaths, required List<String> names, required String mime});

  /// [paths] must live under the app's files/results/.
  Future<void> share({required List<String> paths, required String mime});
  Future<void> openWith({required String path, required String mime});
  Future<int> freeBytes(String path);

  /// Platform JPEG encoder for RGBA pixels (scales to the target size first).
  Future<Uint8List> encodeJpeg({
    required Uint8List rgba,
    required int width,
    required int height,
    required int targetWidth,
    required int targetHeight,
    required int quality,
  });

  /// Encodes RGBA pixels as JPEG ([png] false) or PNG straight into
  /// [destPath] and returns the file size. PNG ignores [quality].
  Future<int> encodeToFile({
    required Uint8List rgba,
    required int width,
    required int height,
    required bool png,
    required int quality,
    required String destPath,
  });

  /// Decodes a photo scaled to fit [maxWidth] × [maxHeight], turns it upright
  /// (EXIF orientation plus [quarterTurns]) and writes it as JPEG to
  /// [destPath]. Returns the written size. Throws [PlatformFilesException.imageUnreadable] for photos
  /// the device cannot decode.
  Future<(int, int)> prepareImage({
    required String srcPath,
    required String destPath,
    required int maxWidth,
    required int maxHeight,
    required int quality,
    int quarterTurns = 0,
  });

  /// Total RAM of the device in bytes.
  Future<int> deviceMemory();

  /// `ready`, `needsDownload`, `offline` (module missing and no connection)
  /// or `unsupported` (DocumentScanner on Android).
  Future<String> scannerStatus();

  /// Asks Google Play services to download the scanner module when it can.
  Future<void> prepareScanner();

  /// Opens the document scanner and copies the scanned PDF to [destPath].
  /// Returns its page count, or null when the user cancels. Throws
  /// [PlatformFilesException.scannerModuleMissing] or
  /// [PlatformFilesException.scannerUnsupported] when it cannot start.
  Future<int?> scanDocument({required int maxPages, required String destPath});

  /// Documents received through "Share" from other apps, including the one
  /// that launched the app.
  Stream<List<PickedDocument>> get incoming;
}

class MethodChannelPlatformFiles implements PlatformFilesApi {
  static const _channel = MethodChannel('io.github.nicolasjorquera.platform_files');
  static const _incoming = EventChannel('io.github.nicolasjorquera.platform_files/incoming');

  Future<T> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args) as T;
    } on PlatformException catch (e) {
      throw PlatformFilesException(e.code, e.message);
    } on MissingPluginException {
      throw const PlatformFilesException(PlatformFilesException.notImplemented);
    }
  }

  List<PickedDocument> _docs(Object? list) => [
    for (final m in (list as List<Object?>? ?? const [])) PickedDocument.fromMap(m! as Map<Object?, Object?>),
  ];

  @override
  Future<List<PickedDocument>> pickDocuments({required List<String> mimeTypes, bool multiple = false}) async =>
      _docs(await _call<Object?>('pickDocuments', {'mimeTypes': mimeTypes, 'multiple': multiple}));

  @override
  Future<List<PickedDocument>> pickImages({int max = 100}) async =>
      _docs(await _call<Object?>('pickImages', {'max': max}));

  @override
  Future<int> copyToFile({required String uri, required String destPath, required String copyId}) =>
      _call<int>('copyToFile', {'uri': uri, 'destPath': destPath, 'copyId': copyId});

  @override
  Future<void> cancelCopy(String copyId) => _call<void>('cancelCopy', {'copyId': copyId});

  @override
  Future<String?> saveAs({required String srcPath, required String name, required String mime}) =>
      _call<String?>('saveAs', {'srcPath': srcPath, 'name': name, 'mime': mime});

  @override
  Future<int?> saveAllToFolder({required List<String> srcPaths, required List<String> names, required String mime}) =>
      _call<int?>('saveAllToFolder', {'srcPaths': srcPaths, 'names': names, 'mime': mime});

  @override
  Future<void> share({required List<String> paths, required String mime}) =>
      _call<void>('share', {'paths': paths, 'mime': mime});

  @override
  Future<void> openWith({required String path, required String mime}) =>
      _call<void>('openWith', {'path': path, 'mime': mime});

  @override
  Future<int> freeBytes(String path) => _call<int>('freeBytes', {'path': path});

  @override
  Future<Uint8List> encodeJpeg({
    required Uint8List rgba,
    required int width,
    required int height,
    required int targetWidth,
    required int targetHeight,
    required int quality,
  }) => _call<Uint8List>('encodeJpeg', {
    'bytes': rgba,
    'width': width,
    'height': height,
    'targetWidth': targetWidth,
    'targetHeight': targetHeight,
    'quality': quality,
  });

  @override
  Future<int> encodeToFile({
    required Uint8List rgba,
    required int width,
    required int height,
    required bool png,
    required int quality,
    required String destPath,
  }) => _call<int>('encodeToFile', {
    'bytes': rgba,
    'width': width,
    'height': height,
    'format': png ? 'png' : 'jpeg',
    'quality': quality,
    'destPath': destPath,
  });

  @override
  Future<(int, int)> prepareImage({
    required String srcPath,
    required String destPath,
    required int maxWidth,
    required int maxHeight,
    required int quality,
    int quarterTurns = 0,
  }) async {
    final size = await _call<List<Object?>>('prepareImage', {
      'srcPath': srcPath,
      'destPath': destPath,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'quality': quality,
      'quarterTurns': quarterTurns,
    });
    return (size[0]! as int, size[1]! as int);
  }

  @override
  Future<int> deviceMemory() => _call<int>('deviceMemory');

  @override
  Future<String> scannerStatus() => _call<String>('scannerStatus');

  @override
  Future<void> prepareScanner() => _call<void>('prepareScanner');

  @override
  Future<int?> scanDocument({required int maxPages, required String destPath}) =>
      _call<int?>('scanDocument', {'maxPages': maxPages, 'destPath': destPath});

  @override
  Stream<List<PickedDocument>> get incoming => _incoming.receiveBroadcastStream().map(_docs);
}
