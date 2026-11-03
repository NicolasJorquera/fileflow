import 'dart:typed_data';

import '../jobs/jobs.dart';
import 'result.dart';

/// A document the user chose or shared to the app, not yet copied in.
/// [ref] is opaque (a content URI on Android).
class PickedFile {
  const PickedFile({required this.ref, required this.name, this.sizeBytes, this.mime});

  final String ref;
  final String name;
  final int? sizeBytes;
  final String? mime;
}

/// A file inside the app's storage that tools can read and write.
class LocalFile {
  const LocalFile({required this.path, required this.name, required this.sizeBytes});

  final String path;

  /// Name shown to the user (the original name for imported files).
  final String name;
  final int sizeBytes;
}

/// Scratch folders of one job: inputs are copied to [inputDir], intermediate
/// files go to [workDir]. Both disappear when the job ends.
class JobDir {
  const JobDir({required this.id, required this.inputDir, required this.workDir});

  final String id;
  final String inputDir, workDir;
}

/// Temporary storage lifecycle (Arquitectura v1.0, «Manejo de archivos»).
abstract interface class JobWorkspace {
  Future<JobDir> create();
  Future<void> delete(JobDir job);

  /// Folder of finished results (Recientes); the only one shared with other apps.
  Future<String> resultsDir();

  /// Removes job folders left by a previous run. A non-zero count means the
  /// system killed the app mid-job: the UI says so once (RF-08).
  Future<int> sweepLeftovers();
}

/// System pickers and moving files in and out of the app (PRD H2, RN-12).
abstract interface class FileGateway {
  /// Empty when the user cancels.
  Future<Result<List<PickedFile>>> pickPdfs({bool multiple = false});
  Future<Result<List<PickedFile>>> pickImages({int max = 100});

  /// Copies [file] into [job].inputDir after checking free space (RF-10:
  /// at least twice its size). Cancelling [token] stops the copy.
  Future<Result<LocalFile>> importToJob(PickedFile file, JobDir job, {CancelToken? token});

  /// Lets the user pick where to save. Ok(null) when cancelled.
  Future<Result<String?>> saveAs(LocalFile file, {required String suggestedName});
  Future<Result<int?>> saveAllToFolder(List<LocalFile> files, {required List<String> names});
  Future<Result<void>> share(List<LocalFile> files);
  Future<Result<void>> openWith(LocalFile file);

  /// Files other apps send through "Share".
  Stream<List<PickedFile>> incomingShares();
}

/// JPEG with the platform codec.
abstract interface class ImageCodec {
  Future<Result<Uint8List>> encodeJpeg({
    required Uint8List rgba,
    required int width,
    required int height,
    required int targetWidth,
    required int targetHeight,
    required int quality,
  });
}
