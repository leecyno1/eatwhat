import 'package:eatwhat_app/core/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('系统安全存储读写且不落地普通偏好存储', (tester) async {
    const key = 'pr2_native_storage_probe';
    await SecureStorageService.removeSecureString(key);
    addTearDown(() => SecureStorageService.removeSecureString(key));

    expect(
      await SecureStorageService.setSecureString(key, 'native-round-trip'),
      isTrue,
    );
    expect(
        await SecureStorageService.getSecureString(key), 'native-round-trip');
    expect(await SecureStorageService.containsSecureKey(key), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('secure_$key'), isFalse);
    expect(prefs.containsKey('iv_$key'), isFalse);
  });
}
