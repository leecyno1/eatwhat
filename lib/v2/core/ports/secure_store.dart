abstract interface class SecureStore {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});

  Future<bool> containsKey({required String key});

  Future<Map<String, String>> readAll();
}
