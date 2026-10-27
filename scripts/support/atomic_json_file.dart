import 'dart:convert';
import 'dart:io';

Future<void> writeJsonAtomically(File file, Object? value) async {
  await file.parent.create(recursive: true);
  final temporary = File('${file.path}.tmp');
  await temporary.writeAsString(jsonEncode(value), flush: true);
  await temporary.rename(file.path);
}

void writeJsonAtomicallySync(File file, Object? value) {
  final parent = file.parent;
  if (!parent.existsSync()) {
    parent.createSync(recursive: true);
  }
  File('${file.path}.tmp')
    ..writeAsStringSync(jsonEncode(value), flush: true)
    ..renameSync(file.path);
}
