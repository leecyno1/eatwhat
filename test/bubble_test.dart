import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:eatwhat_app/features/bubble/controllers/bubble_controller.dart';
import 'package:eatwhat_app/core/models/bubble.dart';

void main() {
  group('Bubble Tests', () {
    test('Bubble模型测试', () {
      final bubble = Bubble(
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
      );

      expect(bubble.name, '甜');
      expect(bubble.type, BubbleType.taste);
      expect(bubble.size, 300.0);
      expect(bubble.isSelected, false);
    });

    test('BubbleController测试', () {
      final controller = BubbleController();
      
      expect(controller.bubbles, isEmpty);
      expect(controller.isInitialized, false);
      
      controller.initializeBubbles();
      expect(controller.bubbles, isNotEmpty);
      expect(controller.isInitialized, true);
      
      controller.dispose();
    });

    test('气泡选择测试', () {
      final controller = BubbleController();
      controller.initializeBubbles();
      
      final bubble = controller.bubbles.first;
      expect(controller.selectedBubbles, isEmpty);
      
      controller.toggleBubble(bubble);
      expect(controller.selectedBubbles.length, 1);
      
      controller.toggleBubble(bubble);
      expect(controller.selectedBubbles, isEmpty);
      
      controller.dispose();
    });

    test('推荐置信度测试', () {
      final controller = BubbleController();
      controller.initializeBubbles();
      
      expect(controller.getRecommendationConfidence(), 0.0);
      
      controller.toggleBubble(controller.bubbles[0]);
      expect(controller.getRecommendationConfidence(), 0.3);
      
      controller.dispose();
    });
  });
} 