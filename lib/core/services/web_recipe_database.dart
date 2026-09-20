import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<Database> openWebRecipeDatabase(String assetName) async {
  final data = await rootBundle.load('assets/data/$assetName');
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final factory = databaseFactoryFfiWeb;
  // New asset versions must not replace a database open in another tab.
  final path = '/recipe_assets/${sha256.convert(bytes)}/$assetName';
  final cachedBytes = await factory.databaseExists(path)
      ? await factory.readDatabaseBytes(path)
      : null;
  if (!listEquals(cachedBytes, bytes)) {
    await factory.writeDatabaseBytes(path, bytes);
  }
  return factory.openDatabase(
    path,
    // SharedWorker connections have no cross-tab close reference counting.
    options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
  );
}
