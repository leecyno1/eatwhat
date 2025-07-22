#!/bin/bash

echo "🎯 用户偏好系统 iOS 测试"
echo "========================="

echo ""
echo "📱 检查设备连接状态..."
flutter devices

echo ""
echo "🔍 查找iPhone设备..."
DEVICE_INFO=$(flutter devices | grep -i "iphone\|ios")

if [ ! -z "$DEVICE_INFO" ]; then
    echo "✅ 找到iOS设备:"
    echo "$DEVICE_INFO"
    
    DEVICE_ID=$(echo "$DEVICE_INFO" | head -n1 | awk '{print $(NF-1)}')
    echo ""
    echo "📱 使用设备ID: $DEVICE_ID"
    
    echo ""
    echo "🚀 开始运行应用..."
    echo ""
    echo "📋 新功能测试指南:"
    echo "   1. 🎯 观察气泡数量: 应显示30个随机气泡"
    echo "   2. 📏 测试动态大小: 多次点赞同一气泡观察大小变化"
    echo "   3. ⬇️ 测试滑动替换: 向下滑动气泡看是否替换"
    echo "   4. 🎲 验证概率权重: 高分项目重新启动后更容易出现"
    echo "   5. 💾 测试数据持久化: 关闭重开app验证偏好保存"
    echo ""
    echo "🎮 手势操作说明:"
    echo "   • 点击: 选择偏好 (+5分)"
    echo "   • 向上滑: 点赞 (+10分) 🔥 重点测试"
    echo "   • 向下滑: 删除替换 (-8分) 🔥 重点测试"
    echo "   • 向左滑: 忽略 (-2分)"
    echo "   • 向右滑: 确认 (+5分)"
    echo ""
    
    # 运行应用
    flutter run -d "$DEVICE_ID" --release
    
    echo ""
    echo "🎉 测试完成!"
    echo ""
    echo "📊 预期测试结果:"
    echo "   ✅ 每次启动显示30个不同的气泡组合"
    echo "   ✅ 点赞的气泡会逐渐变大 (20px → 50px)"
    echo "   ✅ 向下滑动的气泡被新气泡替换"
    echo "   ✅ 用户偏好在app重启后保持"
    echo "   ✅ 高分偏好在后续启动中更频繁出现"
    
else
    echo "❌ 未找到iOS设备"
    echo ""
    echo "🔧 请检查:"
    echo "   1. iPhone连接到Mac并已解锁"
    echo "   2. 在设备上信任此电脑"
    echo "   3. 在iPhone设置中启用开发者模式"
    echo ""
    echo "📋 所有设备列表:"
    flutter devices
fi