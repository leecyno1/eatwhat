import 'package:eatwhat_app/v2/features/home/game/bubble_game.dart';
import 'package:eatwhat_app/v2/features/home/game/grab_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveGrabOutcome', () {
    test('顶部托盘区松手判定为收集', () {
      expect(
        resolveGrabOutcome(releaseY: 40, stageHeight: 620),
        GrabReleaseOutcome.collect,
      );
      expect(
        resolveGrabOutcome(releaseY: grabTrayZoneDepth, stageHeight: 620),
        GrabReleaseOutcome.collect,
      );
    });

    test('底部拉黑区松手判定为拉黑', () {
      expect(
        resolveGrabOutcome(releaseY: 600, stageHeight: 620),
        GrabReleaseOutcome.reject,
      );
      expect(
        resolveGrabOutcome(
          releaseY: 620 - grabDiscardZoneDepth,
          stageHeight: 620,
        ),
        GrabReleaseOutcome.reject,
      );
    });

    test('中间区域松手判定为落回', () {
      expect(
        resolveGrabOutcome(releaseY: 300, stageHeight: 620),
        GrabReleaseOutcome.drop,
      );
    });
  });

  group('ShakeDetector', () {
    test('静止重力样本不触发', () {
      final detector = ShakeDetector();
      final now = DateTime(2026, 1, 1, 12);
      for (var i = 0; i < 50; i++) {
        expect(detector.register(9.8, now: now), isFalse);
      }
    });

    test('连续超阈值样本触发一次', () {
      final detector = ShakeDetector();
      final now = DateTime(2026, 1, 1, 12);
      expect(detector.register(23.5, now: now), isFalse);
      expect(detector.register(21.0, now: now), isTrue);
      // Shake is reported exactly once per burst.
      expect(detector.register(24.0, now: now), isFalse);
      expect(detector.register(22.0, now: now), isFalse);
    });

    test('单尖峰被普通样本隔开不触发', () {
      final detector = ShakeDetector();
      final now = DateTime(2026, 1, 1, 12);
      expect(detector.register(25.0, now: now), isFalse);
      expect(detector.register(9.8, now: now), isFalse); // resets the streak
      expect(detector.register(25.0, now: now), isFalse);
      expect(detector.register(9.8, now: now), isFalse);
    });

    test('冷却期内不再触发，冷却结束后可再次触发', () {
      final detector = ShakeDetector();
      final start = DateTime(2026, 1, 1, 12);
      expect(detector.register(23.0, now: start), isFalse);
      expect(detector.register(23.0, now: start), isTrue);

      // Inside the cooldown: a fresh burst stays silent.
      final duringCooldown = start.add(const Duration(milliseconds: 800));
      expect(detector.register(23.0, now: duringCooldown), isFalse);
      expect(detector.register(23.0, now: duringCooldown), isFalse);

      // Past the cooldown: a new burst fires again.
      final afterCooldown = start.add(const Duration(milliseconds: 1500));
      expect(detector.register(23.0, now: afterCooldown), isFalse);
      expect(detector.register(23.0, now: afterCooldown), isTrue);
    });
  });

  group('pot configuration', () {
    test('舞台分三层且每层实体数与总数匹配', () {
      expect(BubbleGame.potLayerCount, 3);
      expect(BubbleGame.visibleBubbleCount, 60);
      expect(BubbleGame.visibleBubbleCount % BubbleGame.potLayerCount, 0);
    });

    test('稀有实体概率与偏好加成配置合理', () {
      // Golden rares stay rare but present: at 60 entities the expected
      // count on stage is 60 * (1/15) = 4.
      expect(BubbleGame.goldenEntityChance, greaterThan(0));
      expect(BubbleGame.goldenEntityChance, lessThan(0.2));
      expect(BubbleGame.goldenFeedbackDelta, greaterThan(BubbleGame.normalFeedbackDelta));
    });
  });
}
