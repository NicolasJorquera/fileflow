import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/result.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:fileflow/data/files/disk_job_workspace.dart';
import 'package:fileflow/data/files/platform_file_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_files/platform_files.dart';

/// Records calls and lets each test decide how the native side behaves.
class FakePlatformFiles implements PlatformFilesApi {
  int free = 1 << 40;
  Future<int> Function(String uri, String dest, String copyId)? onCopy;
  final cancelled = <String>{};
  final incomingController = StreamController<List<PickedDocument>>.broadcast();

  @override
  Future<int> freeBytes(String path) async => free;

  @override
  Future<int> copyToFile({required String uri, required String destPath, required String copyId}) =>
      onCopy!(uri, destPath, copyId);

  @override
  Future<void> cancelCopy(String copyId) async => cancelled.add(copyId);

  @override
  Stream<List<PickedDocument>> get incoming => incomingController.stream;

  @override
  Future<List<PickedDocument>> pickDocuments({required List<String> mimeTypes, bool multiple = false}) async => [
    const PickedDocument(uri: 'content://docs/1', name: 'cartola.pdf', size: 10, mime: 'application/pdf'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory root;
  late DiskJobWorkspace workspace;
  late FakePlatformFiles api;
  late PlatformFileGateway gateway;

  setUp(() {
    root = Directory.systemTemp.createTempSync('fileflow_files_test');
    workspace = DiskJobWorkspace(cacheDir: '${root.path}/cache', filesDir: '${root.path}/files');
    api = FakePlatformFiles();
    gateway = PlatformFileGateway(api, freeSpacePath: root.path, cancelPoll: const Duration(milliseconds: 5));
  });
  tearDown(() => root.deleteSync(recursive: true));

  group('JobWorkspace', () {
    test('creates in/ and work/ and deletes the whole job', () async {
      final job = await workspace.create();
      expect(Directory(job.inputDir).existsSync() && Directory(job.workDir).existsSync(), isTrue);
      await workspace.delete(job);
      expect(Directory(job.inputDir).parent.existsSync(), isFalse);
    });

    test('jobs left by a killed process are swept and counted at startup', () async {
      await workspace.create();
      await workspace.create();
      expect(await workspace.sweepLeftovers(), 2);
      expect(await workspace.sweepLeftovers(), 0);
    });

    test('results live under files/results (the FileProvider root)', () async {
      expect(await workspace.resultsDir(), endsWith('/files/results'));
    });
  });

  group('FileGateway', () {
    const picked = PickedFile(ref: 'content://docs/1', name: 'cartola octubre.pdf', sizeBytes: 1000);

    test('imports into the job input folder with a safe name', () async {
      api.onCopy = (uri, dest, id) async {
        File(dest).writeAsBytesSync(Uint8List(1000));
        return 1000;
      };
      final job = await workspace.create();
      final file = (await gateway.importToJob(picked, job)).valueOrNull!;
      expect(file.path, startsWith(job.inputDir));
      expect(file.name, 'cartola octubre.pdf');
      expect(file.sizeBytes, 1000);
    });

    test('not enough free space fails before copying (RF-10)', () async {
      api
        ..free = 1500
        ..onCopy = (_, _, _) => fail('must not copy');
      final result = await gateway.importToJob(picked, await workspace.create());
      expect((result as Err).failure, isA<InsufficientStorage>().having((f) => f.requiredBytes, 'required', 2000));
    });

    test('native access_lost and no_space map to AppFailures', () async {
      final job = await workspace.create();
      api.onCopy = (_, _, _) => throw const PlatformFilesException(PlatformFilesException.accessLost);
      expect(((await gateway.importToJob(picked, job)) as Err).failure, isA<SourceAccessLost>());
      api.onCopy = (_, _, _) => throw const PlatformFilesException(PlatformFilesException.noSpace);
      expect(((await gateway.importToJob(picked, job)) as Err).failure, isA<InsufficientStorage>());
    });

    test('cancelling the token cancels the native copy', () async {
      final copyStarted = Completer<String>();
      final release = Completer<void>();
      api.onCopy = (uri, dest, id) async {
        copyStarted.complete(id);
        await release.future;
        throw const PlatformFilesException(PlatformFilesException.cancelled);
      };
      final token = CancelToken();
      final pending = gateway.importToJob(picked, await workspace.create(), token: token);
      final id = await copyStarted.future;
      token.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(api.cancelled, contains(id));
      release.complete();
      expect(((await pending) as Err).failure, isA<Cancelled>());
    });

    test('pickers map documents to PickedFile', () async {
      final files = (await gateway.pickPdfs()).valueOrNull!;
      expect(files.single.ref, 'content://docs/1');
    });

    test('incoming shares are forwarded', () async {
      final next = gateway.incomingShares().first;
      api.incomingController.add([const PickedDocument(uri: 'content://wa/9', name: 'foto.jpg')]);
      expect((await next).single.name, 'foto.jpg');
    });
  });
}
