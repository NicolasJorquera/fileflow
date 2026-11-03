import 'package:fileflow/core/domain/files.dart';
import 'package:fileflow/core/domain/recents.dart';
import 'package:fileflow/core/jobs/jobs.dart';
import 'package:fileflow/features/tools/to_image/domain/export_images.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  test('names are «nombre-p01.jpg», padded to the longest page number', () {
    expect(ExportImages.namesFor('boleta.pdf', [0, 11], 12, ImageFormat.jpeg), ['boleta-p01.jpg', 'boleta-p12.jpg']);
    expect(ExportImages.namesFor('libro.pdf', [4], 150, ImageFormat.png), ['libro-p005.png']);
    expect(ExportImages.namesFor('a/b.pdf', [0], 3, ImageFormat.jpeg), ['a_b-p01.jpg']);
  });

  test('12 pages at 150 dpi become one result with 12 images', () async {
    final pdf = FakePdfService();
    final recents = MemoryRecents();
    final events = await ExportImages(pdf: pdf, recents: recents)(
      const LocalFile(path: '/in/boleta.pdf', name: 'boleta.pdf', sizeBytes: 100),
      List.generate(12, (i) => i),
      pageCount: 12,
      setName: 'boleta (imágenes)',
      format: ImageFormat.jpeg,
      dpi: 150,
    )(CancelToken()).toList();

    final item = (events.last as JobCompleted<RecentItem>).output;
    expect(item.kind, ResultKind.images);
    expect(item.files.length, 12);
    expect(item.files.first, 'boleta-p01.jpg');
    final (_, outputs, format, dpi) = pdf.exported.single;
    expect((format, dpi), (ImageFormat.jpeg, 150));
    expect(outputs.every((o) => o.startsWith('${item.dir}/')), isTrue, reason: 'saved together');
  });
}
