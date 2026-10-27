import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/support/atomic_json_file.dart';

void main() {
  late Directory directory;
  late File file;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('atomic-json-file-');
    file = File('${directory.path}/missing/parents/data.json');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  group('writeJsonAtomically', () {
    test('creates missing parent directories recursively', () async {
      expect(file.parent.existsSync(), isFalse);

      await writeJsonAtomically(file, const {'created': true});

      expect(file.existsSync(), isTrue);
    });

    test('writes valid JSON content', () async {
      const value = {
        'name': '吃什么',
        'count': 2,
        'enabled': true,
        'nothing': null,
      };

      await writeJsonAtomically(file, value);

      expect(jsonDecode(await file.readAsString()), value);
    });

    test('removes the temporary file after success', () async {
      await writeJsonAtomically(file, const {'written': true});

      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });

    test('replaces an existing file', () async {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('{"version":1}');

      await writeJsonAtomically(file, const {'version': 2});

      expect(jsonDecode(await file.readAsString()), const {'version': 2});
    });

    test('serialization failure leaves the existing target intact', () async {
      const original = '{"stable":true}';
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(original);

      await expectLater(
        writeJsonAtomically(file, <String, Object?>{'invalid': Object()}),
        throwsA(isA<JsonUnsupportedObjectError>()),
      );

      expect(await file.readAsString(), original);
      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });
  });

  group('writeJsonAtomicallySync', () {
    test('creates missing parent directories recursively', () {
      expect(file.parent.existsSync(), isFalse);

      writeJsonAtomicallySync(file, const {'created': true});

      expect(file.existsSync(), isTrue);
    });

    test('writes valid JSON content', () {
      const value = [
        {'id': 1, 'name': '吃什么'},
        {'id': 2, 'active': true, 'nothing': null},
      ];

      writeJsonAtomicallySync(file, value);

      expect(jsonDecode(file.readAsStringSync()), value);
    });

    test('removes the temporary file after success', () {
      writeJsonAtomicallySync(file, const {'written': true});

      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });

    test('replaces an existing file', () {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('[{"version":1}]');

      writeJsonAtomicallySync(file, const [
        {'version': 2},
      ]);

      expect(jsonDecode(file.readAsStringSync()), const [
        {'version': 2},
      ]);
    });

    test('serialization failure leaves the existing target intact', () {
      const original = '[{"stable":true}]';
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(original);

      expect(
        () => writeJsonAtomicallySync(
          file,
          <String, Object?>{'invalid': Object()},
        ),
        throwsA(isA<JsonUnsupportedObjectError>()),
      );

      expect(file.readAsStringSync(), original);
      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });
  });
}
