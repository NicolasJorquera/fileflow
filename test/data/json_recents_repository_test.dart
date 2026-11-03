import 'dart:io';

import 'package:fileflow/core/domain/tools.dart';
import 'package:fileflow/data/recents/json_recents_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late String filesDir, resultsDir;
  var now = DateTime(2026, 11, 3, 10);

  Future<JsonRecentsRepository> open() =>
      JsonRecentsRepository.open(filesDir: filesDir, resultsDir: resultsDir, clock: () => now);

  /// Reserves a slot, writes [bytes] into it and registers it.
  Future<String> addResult(JsonRecentsRepository repo, String name, {int bytes = 10}) async {
    final slot = await repo.reserve(name);
    await File(slot.path).writeAsBytes(List.filled(bytes, 1));
    return (await repo.add(slot, tool: ToolId.merge, pages: 3, inputBytes: 99)).id;
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('fileflow_recents_test');
    filesDir = root.path;
    resultsDir = '${root.path}/results';
    Directory(resultsDir).createSync();
    now = DateTime(2026, 11, 3, 10);
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('keeps results across launches, newest first, with their size', () async {
    final repo = await open();
    await addResult(repo, 'uno.pdf', bytes: 5);
    now = now.add(const Duration(minutes: 1));
    await addResult(repo, 'dos.pdf', bytes: 7);

    final again = await open();
    expect([for (final i in again.current) i.name], ['dos.pdf', 'uno.pdf']);
    expect(again.current.first.sizeBytes, 7);
    expect(again.current.first.inputBytes, 99);
    expect(File('$filesDir/recents.json.tmp').existsSync(), isFalse);
  });

  test('repeated names get «(2)», «(3)»… and never a path', () async {
    final repo = await open();
    await addResult(repo, 'Documento unido.pdf');
    await addResult(repo, 'documento UNIDO.pdf');
    final slot = await repo.reserve('Documento unido.pdf');
    expect(slot.name, 'Documento unido (3).pdf');
    expect((await repo.reserve('../../etc/passwd')).name, '.._.._etc_passwd');
  });

  test('rename moves the file and survives a relaunch', () async {
    final repo = await open();
    final id = await addResult(repo, 'a.pdf');
    final renamed = await repo.rename(id, 'Postulación beca.pdf');

    expect(File(renamed.path).existsSync(), isTrue);
    expect((await open()).current.single.name, 'Postulación beca.pdf');
  });

  test('purge removes results older than the period, files included', () async {
    final repo = await open();
    final old = await addResult(repo, 'viejo.pdf');
    now = now.add(const Duration(days: 6));
    await addResult(repo, 'nuevo.pdf');
    now = now.add(const Duration(days: 1));

    expect(await repo.purgeExpired(now, const Duration(days: 7)), 1);
    expect([for (final i in repo.current) i.name], ['nuevo.pdf']);
    expect(Directory('$resultsDir/$old').existsSync(), isFalse);
  });

  test('a discarded slot leaves no folder', () async {
    final repo = await open();
    final slot = await repo.reserve('x.pdf');
    await File('${slot.path}.part').writeAsString('partial');
    await repo.discard(slot);
    expect(Directory(resultsDir).listSync(), isEmpty);
  });

  test('on launch, folders of killed jobs and entries without file are cleaned', () async {
    final repo = await open();
    final kept = await addResult(repo, 'ok.pdf');
    final lost = await addResult(repo, 'perdido.pdf');
    File(repo.current.firstWhere((i) => i.id == lost).path).deleteSync();
    final orphan = await repo.reserve('a medias.pdf');
    await File('${orphan.path}.part').writeAsString('partial');

    final again = await open();
    expect([for (final i in again.current) i.id], [kept]);
    expect(Directory(resultsDir).listSync().map((e) => e.uri.pathSegments.lastWhere((s) => s.isNotEmpty)), [kept]);
  });

  test('a damaged index loses the list, not the app', () async {
    File('$filesDir/recents.json').writeAsStringSync('{not json');
    expect((await open()).current, isEmpty);
  });

  test('watch emits the current list and every change', () async {
    final repo = await open();
    final seen = <int>[];
    final sub = repo.watch().listen((items) => seen.add(items.length));
    await Future<void>.delayed(Duration.zero);
    await addResult(repo, 'a.pdf');
    await repo.clear();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(seen, [0, 1, 0]);
  });
}
