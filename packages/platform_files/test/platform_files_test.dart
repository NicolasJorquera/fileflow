import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_files/platform_files.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('io.github.nicolasjorquera.platform_files');
  final api = MethodChannelPlatformFiles();
  final calls = <MethodCall>[];

  void reply(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(calls.clear);

  test('pickDocuments maps the native list', () async {
    reply(
      (_) => [
        {'uri': 'content://x/1', 'name': 'a.pdf', 'size': 10, 'mime': 'application/pdf'},
      ],
    );
    final docs = await api.pickDocuments(mimeTypes: ['application/pdf'], multiple: true);
    expect(docs.single.name, 'a.pdf');
    expect(docs.single.size, 10);
    expect(calls.single.arguments, {
      'mimeTypes': ['application/pdf'],
      'multiple': true,
    });
  });

  test('a cancelled picker is an empty list', () async {
    reply((_) => <Object?>[]);
    expect(await api.pickImages(), isEmpty);
  });

  test('native errors become PlatformFilesException with the same code', () async {
    reply((_) => throw PlatformException(code: PlatformFilesException.accessLost, message: 'SecurityException'));
    await expectLater(
      api.copyToFile(uri: 'content://x/1', destPath: '/tmp/a', copyId: '1'),
      throwsA(isA<PlatformFilesException>().having((e) => e.code, 'code', PlatformFilesException.accessLost)),
    );
  });
}
