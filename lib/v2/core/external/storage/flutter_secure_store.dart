import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../ports/secure_store.dart';

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<bool> containsKey({required String key}) =>
      _storage.containsKey(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();
}
