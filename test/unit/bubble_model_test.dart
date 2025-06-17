import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:eatwhat_app/core/models/bubble.dart';

void main() {
  group('Bubble Model Tests', () {
    test('创建气泡时应该有默认值', () {
      final bubble = Bubble(
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
      );

      expect(bubble.id, isNotEmpty);
      expect(bubble.type, BubbleType.taste);
      expect(bubble.name, '甜');
      expect(bubble.color, Colors.orange);
      expect(bubble.size, 300.0);
      expect(bubble.position, Offset.zero);
      expect(bubble.velocity, Offset.zero);
      expect(bubble.opacity, 1.0);
      expect(bubble.isSelected, false);
      expect(bubble.isAnimating, false);
      expect(bubble.weight, 1.0);
    });

    test('创建气泡时可以指定自定义值', () {
      final bubble = Bubble(
        id: 'test-id',
        type: BubbleType.cuisine,
        name: '川菜',
        icon: '🌶️',
        color: Colors.red,
        size: 150.0,
        description: '辣味菜系',
        position: const Offset(100, 200),
        velocity: const Offset(5, -3),
        opacity: 0.8,
        isSelected: true,
        isAnimating: true,
        weight: 2.0,
      );

      expect(bubble.id, 'test-id');
      expect(bubble.type, BubbleType.cuisine);
      expect(bubble.name, '川菜');
      expect(bubble.icon, '🌶️');
      expect(bubble.color, Colors.red);
      expect(bubble.size, 150.0);
      expect(bubble.description, '辣味菜系');
      expect(bubble.position, const Offset(100, 200));
      expect(bubble.velocity, const Offset(5, -3));
      expect(bubble.opacity, 0.8);
      expect(bubble.isSelected, true);
      expect(bubble.isAnimating, true);
      expect(bubble.weight, 2.0);
    });

    test('copyWith应该正确复制和修改属性', () {
      final originalBubble = Bubble(
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
        isSelected: false,
      );

      final copiedBubble = originalBubble.copyWith(
        isSelected: true,
        position: const Offset(50, 100),
      );

      // 原始属性应该保持不变
      expect(copiedBubble.id, originalBubble.id);
      expect(copiedBubble.type, originalBubble.type);
      expect(copiedBubble.name, originalBubble.name);
      expect(copiedBubble.color, originalBubble.color);

      // 修改的属性应该更新
      expect(copiedBubble.isSelected, true);
      expect(copiedBubble.position, const Offset(50, 100));

      // 原始对象应该保持不变
      expect(originalBubble.isSelected, false);
      expect(originalBubble.position, Offset.zero);
    });

    test('相等性比较应该基于ID', () {
      final bubble1 = Bubble(
        id: 'same-id',
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
      );

      final bubble2 = Bubble(
        id: 'same-id',
        type: BubbleType.cuisine,
        name: '川菜',
        color: Colors.red,
      );

      final bubble3 = Bubble(
        id: 'different-id',
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
      );

      expect(bubble1, equals(bubble2)); // 相同ID
      expect(bubble1, isNot(equals(bubble3))); // 不同ID
      expect(bubble1.hashCode, equals(bubble2.hashCode));
      expect(bubble1.hashCode, isNot(equals(bubble3.hashCode)));
    });

    test('emoji和text getter应该返回正确值', () {
      final bubbleWithIcon = Bubble(
        type: BubbleType.taste,
        name: '甜',
        icon: '🍯',
        color: Colors.orange,
      );

      final bubbleWithoutIcon = Bubble(
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
      );

      expect(bubbleWithIcon.emoji, '🍯');
      expect(bubbleWithIcon.text, '甜');
      expect(bubbleWithoutIcon.emoji, '🔮'); // 默认emoji
      expect(bubbleWithoutIcon.text, '甜');
    });

    test('toString应该包含关键信息', () {
      final bubble = Bubble(
        id: 'test-id',
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
        position: const Offset(100, 200),
      );

      final stringRepresentation = bubble.toString();
      expect(stringRepresentation, contains('test-id'));
      expect(stringRepresentation, contains('BubbleType.taste'));
      expect(stringRepresentation, contains('甜'));
      expect(stringRepresentation, contains('Offset(100.0, 200.0)'));
    });
  });

  group('BubbleType Tests', () {
    test('所有气泡类型应该存在', () {
      expect(BubbleType.values, contains(BubbleType.taste));
      expect(BubbleType.values, contains(BubbleType.cuisine));
      expect(BubbleType.values, contains(BubbleType.ingredient));
      expect(BubbleType.values, contains(BubbleType.nutrition));
      expect(BubbleType.values, contains(BubbleType.calorie));
      expect(BubbleType.values, contains(BubbleType.scenario));
      expect(BubbleType.values, contains(BubbleType.temperature));
      expect(BubbleType.values, contains(BubbleType.spiciness));
    });
  });

  group('BubbleGesture Tests', () {
    test('所有手势类型应该存在', () {
      expect(BubbleGesture.values, contains(BubbleGesture.swipeUp));
      expect(BubbleGesture.values, contains(BubbleGesture.swipeDown));
      expect(BubbleGesture.values, contains(BubbleGesture.swipeLeft));
      expect(BubbleGesture.values, contains(BubbleGesture.swipeRight));
      expect(BubbleGesture.values, contains(BubbleGesture.tap));
      expect(BubbleGesture.values, contains(BubbleGesture.longPress));
    });
  });

  group('BubbleInteraction Tests', () {
    test('创建气泡交互应该包含所有必要信息', () {
      final bubble = Bubble(
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
      );

      final timestamp = DateTime.now();
      final interaction = BubbleInteraction(
        bubble: bubble,
        gesture: BubbleGesture.tap,
        timestamp: timestamp,
        gesturePosition: const Offset(100, 200),
        gestureVelocity: 5.0,
      );

      expect(interaction.bubble, equals(bubble));
      expect(interaction.gesture, BubbleGesture.tap);
      expect(interaction.timestamp, timestamp);
      expect(interaction.gesturePosition, const Offset(100, 200));
      expect(interaction.gestureVelocity, 5.0);
    });
  });

  group('BubbleFactory Tests', () {
    test('创建默认气泡应该返回预定义的气泡列表', () {
      final bubbles = BubbleFactory.createDefaultBubbles();

      expect(bubbles, isNotEmpty);
      expect(bubbles.length, greaterThan(5)); // 至少有几个预定义气泡

      // 检查是否包含不同类型的气泡
      final types = bubbles.map((b) => b.type).toSet();
      expect(types, contains(BubbleType.taste));
      expect(types, contains(BubbleType.cuisine));
      expect(types, contains(BubbleType.ingredient));
      expect(types, contains(BubbleType.scenario));
    });

    test('根据类型获取颜色应该返回正确颜色', () {
      expect(BubbleFactory.getColorByType(BubbleType.taste), Colors.orange);
      expect(BubbleFactory.getColorByType(BubbleType.cuisine), Colors.red);
      expect(BubbleFactory.getColorByType(BubbleType.ingredient), Colors.green);
      expect(BubbleFactory.getColorByType(BubbleType.nutrition), Colors.blue);
    });

    test('根据类型获取名称应该返回正确名称', () {
      expect(BubbleFactory.getNameByType(BubbleType.taste), '口味');
      expect(BubbleFactory.getNameByType(BubbleType.cuisine), '菜系');
      expect(BubbleFactory.getNameByType(BubbleType.ingredient), '食材');
      expect(BubbleFactory.getNameByType(BubbleType.nutrition), '营养');
    });
  });
} 