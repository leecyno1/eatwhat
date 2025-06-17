import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:eatwhat_app/features/bubble/controllers/bubble_controller.dart';
import 'package:eatwhat_app/core/models/bubble.dart';

void main() {
  group('BubbleController Tests', () {
    late BubbleController controller;

    setUp(() {
      controller = BubbleController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('初始化时应该为空', () {
      expect(controller.bubbles, isEmpty);
      expect(controller.selectedBubbles, isEmpty);
      expect(controller.isInitialized, false);
    });

    test('初始化气泡后应该有默认气泡', () {
      controller.initializeBubbles();
      
      expect(controller.bubbles, isNotEmpty);
      expect(controller.isInitialized, true);
      expect(controller.bubbles.length, greaterThan(0));
    });

    test('切换气泡选择状态', () {
      controller.initializeBubbles();
      final bubble = controller.bubbles.first;
      
      // 初始状态应该未选中
      expect(bubble.isSelected, false);
      expect(controller.selectedBubbles, isEmpty);
      
      // 选中气泡
      controller.toggleBubble(bubble);
      expect(controller.selectedBubbles.length, 1);
      
      // 再次切换应该取消选中
      controller.toggleBubble(bubble);
      expect(controller.selectedBubbles, isEmpty);
    });

    test('重置选择应该清空所有选中的气泡', () {
      controller.initializeBubbles();
      
      // 选中几个气泡
      for (int i = 0; i < 3; i++) {
        controller.toggleBubble(controller.bubbles[i]);
      }
      
      expect(controller.selectedBubbles.length, 3);
      
      // 重置选择
      controller.resetSelection();
      expect(controller.selectedBubbles, isEmpty);
    });

    test('处理气泡手势 - 点击', () {
      controller.initializeBubbles();
      final bubble = controller.bubbles.first;
      
      controller.handleBubbleGesture(
        bubble, 
        BubbleGesture.tap, 
        Offset.zero, 
        0.0
      );
      
      expect(controller.selectedBubbles.length, 1);
    });

    test('处理气泡手势 - 上滑喜欢', () {
      controller.initializeBubbles();
      final bubble = controller.bubbles.first;
      
      controller.handleBubbleGesture(
        bubble, 
        BubbleGesture.swipeUp, 
        Offset.zero, 
        0.0
      );
      
      expect(controller.selectedBubbles.contains(bubble), true);
    });

    test('处理气泡手势 - 下滑不喜欢', () {
      controller.initializeBubbles();
      final bubble = controller.bubbles.first;
      
      // 先选中气泡
      controller.toggleBubble(bubble);
      expect(controller.selectedBubbles.contains(bubble), true);
      
      // 下滑不喜欢
      controller.handleBubbleGesture(
        bubble, 
        BubbleGesture.swipeDown, 
        Offset.zero, 
        0.0
      );
      
      expect(controller.selectedBubbles.contains(bubble), false);
    });

    test('生成推荐应该设置加载状态', () async {
      controller.initializeBubbles();
      
      // 选中一些气泡
      for (int i = 0; i < 3; i++) {
        controller.toggleBubble(controller.bubbles[i]);
      }
      
      expect(controller.isLoading, false);
      
      final future = controller.generateRecommendations();
      expect(controller.isLoading, true);
      
      await future;
      expect(controller.isLoading, false);
      expect(controller.recommendedFoods, isNotNull);
    });

    test('获取推荐置信度', () {
      controller.initializeBubbles();
      
      // 没有选择时置信度为0
      expect(controller.getRecommendationConfidence(), 0.0);
      
      // 选择1-2个气泡时置信度较低
      controller.toggleBubble(controller.bubbles[0]);
      expect(controller.getRecommendationConfidence(), 0.3);
      
      // 选择3-4个气泡时置信度中等
      controller.toggleBubble(controller.bubbles[1]);
      controller.toggleBubble(controller.bubbles[2]);
      expect(controller.getRecommendationConfidence(), 0.6);
      
      // 选择5个或更多气泡时置信度高
      controller.toggleBubble(controller.bubbles[3]);
      controller.toggleBubble(controller.bubbles[4]);
      expect(controller.getRecommendationConfidence(), 0.9);
    });

    test('添加自定义气泡', () {
      controller.initializeBubbles();
      final initialCount = controller.bubbles.length;
      
      final customBubble = Bubble(
        type: BubbleType.taste,
        name: '测试气泡',
        color: Colors.red,
      );
      
      controller.addCustomBubble(customBubble);
      expect(controller.bubbles.length, initialCount + 1);
      expect(controller.bubbles.contains(customBubble), true);
    });

    test('移除气泡', () {
      controller.initializeBubbles();
      final bubble = controller.bubbles.first;
      final initialCount = controller.bubbles.length;
      
      controller.removeBubble(bubble.id);
      expect(controller.bubbles.length, initialCount - 1);
      expect(controller.bubbles.contains(bubble), false);
    });

    test('获取气泡统计信息', () {
      controller.initializeBubbles();
      
      // 选中不同类型的气泡
      final tasteBubbles = controller.bubbles
          .where((b) => b.type == BubbleType.taste)
          .take(2);
      final cuisineBubbles = controller.bubbles
          .where((b) => b.type == BubbleType.cuisine)
          .take(1);
      
      for (final bubble in tasteBubbles) {
        controller.toggleBubble(bubble);
      }
      for (final bubble in cuisineBubbles) {
        controller.toggleBubble(bubble);
      }
      
      final stats = controller.getBubbleStats();
      expect(stats[BubbleType.taste], 2);
      expect(stats[BubbleType.cuisine], 1);
    });
  });
} 