import 'package:eatwhat_app/v2/features/home/game/sweep_controller.dart';
import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveSweepFlickIntent', () {
    test('结尾向上收尾判定为收集', () {
      final points = <Vector2>[
        Vector2(100, 400),
        Vector2(140, 360),
        Vector2(170, 300),
        Vector2(180, 220),
      ];
      expect(resolveSweepFlickIntent(points), SweepFlickIntent.up);
    });

    test('结尾向下收尾判定为拉黑', () {
      final points = <Vector2>[
        Vector2(100, 200),
        Vector2(140, 240),
        Vector2(170, 300),
        Vector2(180, 380),
      ];
      expect(resolveSweepFlickIntent(points), SweepFlickIntent.down);
    });

    test('中途向下但结尾向上仍判定为收集', () {
      // 路径先向下探，再明确向上收尾：只有结尾段参与判定。
      final points = <Vector2>[
        Vector2(100, 200),
        Vector2(130, 260),
        Vector2(150, 330),
        Vector2(160, 280),
        Vector2(170, 200),
        Vector2(180, 120),
      ];
      expect(resolveSweepFlickIntent(points), SweepFlickIntent.up);
    });

    test('水平收尾不执行任何操作', () {
      final points = <Vector2>[
        Vector2(60, 300),
        Vector2(120, 310),
        Vector2(200, 300),
        Vector2(280, 305),
      ];
      expect(resolveSweepFlickIntent(points), SweepFlickIntent.cancel);
    });

    test('结尾位移太短视为误触取消', () {
      // 结尾仅移动 10px，不足以构成明确意图。
      final points = <Vector2>[
        Vector2(100, 300),
        Vector2(200, 320),
        Vector2(205, 312),
      ];
      expect(resolveSweepFlickIntent(points), SweepFlickIntent.cancel);
    });

    test('对角线偏水平的收尾取消', () {
      // dx=200, dy=-60：垂直分量不足主导阈值。
      final points = <Vector2>[
        Vector2(80, 320),
        Vector2(180, 290),
        Vector2(280, 260),
      ];
      expect(resolveSweepFlickIntent(points), SweepFlickIntent.cancel);
    });

    test('不足两个轨迹点直接取消', () {
      expect(resolveSweepFlickIntent([]), SweepFlickIntent.cancel);
      expect(
        resolveSweepFlickIntent([Vector2(100, 100)]),
        SweepFlickIntent.cancel,
      );
    });
  });

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

    test('中部任意位置松手判定为落回堆中', () {
      expect(
        resolveGrabOutcome(releaseY: 300, stageHeight: 620),
        GrabReleaseOutcome.drop,
      );
    });
  });
}
