import 'dart:io';

import '../../core/domain/files.dart';

/// Job folders under `<cache>/jobs/<id>/{in,work}` and results under
/// `<files>/results` (the only folder the FileProvider exposes). Both trees are
/// excluded from Android backups (data_extraction_rules.xml).
class DiskJobWorkspace implements JobWorkspace {
  DiskJobWorkspace({required this.cacheDir, required this.filesDir});

  final String cacheDir;
  final String filesDir;
  var _counter = 0;

  Directory get _jobsRoot => Directory('$cacheDir/jobs');

  @override
  Future<JobDir> create() async {
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
    final input = Directory('${_jobsRoot.path}/$id/in');
    final work = Directory('${_jobsRoot.path}/$id/work');
    await input.create(recursive: true);
    await work.create(recursive: true);
    return JobDir(id: id, inputDir: input.path, workDir: work.path);
  }

  @override
  Future<void> delete(JobDir job) async {
    final dir = Directory('${_jobsRoot.path}/${job.id}');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  @override
  Future<String> resultsDir() async {
    final dir = Directory('$filesDir/results');
    await dir.create(recursive: true);
    return dir.path;
  }

  /// Called once at startup, before any job runs: every folder found belongs to
  /// a job the system interrupted.
  @override
  Future<int> sweepLeftovers() async {
    if (!await _jobsRoot.exists()) return 0;
    var removed = 0;
    await for (final entry in _jobsRoot.list()) {
      await entry.delete(recursive: true);
      removed++;
    }
    return removed;
  }
}
