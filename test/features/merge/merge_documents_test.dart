import 'package:fileflow/core/domain/failures.dart';
import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:fileflow/features/tools/merge/domain/merge_documents.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

LocalFile _file(String name, int size) => LocalFile(path: '/in/$name', name: name, sizeBytes: size);

void main() {
  late FakePdfService pdf;
  late MemoryRecents recents;
  late MergeDocuments merge;

  setUp(() {
    pdf = FakePdfService(pages: {'a.pdf': 2, 'b.pdf': 3, 'c.pdf': 4});
    recents = MemoryRecents();
    merge = MergeDocuments(pdf: pdf, recents: recents);
  });

  test('merges in order, reports every step and registers the result', () async {
    final events = await merge([_file('a.pdf', 10), _file('b.pdf', 20), _file('c.pdf', 30)], outputName: 'Unido.pdf')(
      CancelToken(),
    ).toList();

    expect(pdf.merges.single, ['/in/a.pdf', '/in/b.pdf', '/in/c.pdf']);
    expect([for (final e in events.whereType<JobProgress>()) '${e.done}/${e.total}'], ['1/4', '2/4', '3/4', '4/4']);
    final item = (events.last as JobCompleted<RecentItem>).output;
    expect(item.pages, 9);
    expect(item.inputBytes, 60);
    expect(item.name, 'Unido.pdf');
    expect(recents.current.single.id, item.id);
  });

  test('a cancelled merge discards its slot and adds nothing', () async {
    final token = CancelToken()..cancel();
    final events = await merge([_file('a.pdf', 1), _file('b.pdf', 1)], outputName: 'x.pdf')(token).toList();

    expect(events.last, isA<JobFailed>().having((e) => e.failure, 'failure', isA<Cancelled>()));
    expect(recents.discarded, hasLength(1));
    expect(recents.current, isEmpty);
  });

  test('an engine failure is reported as is and leaves nothing behind', () async {
    final failing = MergeDocuments(pdf: FakePdfService()..mergeFailure = const PdfDamaged(), recents: recents);
    final events = await failing([_file('a.pdf', 1), _file('b.pdf', 1)], outputName: 'x.pdf')(CancelToken()).toList();

    expect(events.last, isA<JobFailed>().having((e) => e.failure, 'failure', isA<PdfDamaged>()));
    expect(recents.discarded, hasLength(1));
  });

  test('fewer than two files is refused before touching anything', () async {
    final events = await merge([_file('a.pdf', 1)], outputName: 'x.pdf')(CancelToken()).toList();

    expect(events.single, isA<JobFailed>());
    expect(pdf.merges, isEmpty);
  });
}
