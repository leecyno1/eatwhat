import 'package:eatwhat_app/v2/features/onboarding/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('全新安装显示手感教学', () async {
    expect(
      await OnboardingService().shouldShowHandfeelTutorial(),
      isTrue,
    );
  });

  test('任一旧引导标记都会抑制新教学', () async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding_v2': true,
    });
    expect(
      await OnboardingService().shouldShowHandfeelTutorial(),
      isFalse,
    );

    SharedPreferences.setMockInitialValues({
      'v2_home_generation_guide_seen': true,
    });
    expect(
      await OnboardingService().shouldShowHandfeelTutorial(),
      isFalse,
    );
  });

  test('完成与重置会正确更新新标记', () async {
    final service = OnboardingService();
    await service.markHandfeelTutorialSeen();
    expect(await service.shouldShowHandfeelTutorial(), isFalse);

    await service.resetHandfeelTutorial();
    expect(await service.shouldShowHandfeelTutorial(), isTrue);
  });
}
