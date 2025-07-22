#!/bin/bash

echo "🎯 iOS设备测试 - 新用户偏好系统"
echo "=================================="

echo ""
echo "📱 检查设备连接状态:"
flutter devices

echo ""
echo "🔍 检查iPhone设备:"
DEVICE_INFO=$(flutter devices | grep -i "iphone\|ios\|12pm")

if [ ! -z "$DEVICE_INFO" ]; then
    echo "✅ 找到iOS设备:"
    echo "   $DEVICE_INFO"
    
    echo ""
    echo "🚀 开始在iOS设备上测试应用..."
    echo ""
    echo "📋 新功能测试清单:"
    echo "   1. 🎯 验证30个气泡随机显示"
    echo "   2. 📏 测试动态气泡大小 (点赞后观察大小变化)"
    echo "   3. ⬇️ 测试向下滑动替换气泡功能"
    echo "   4. 🎲 验证概率权重系统 (高分项目更容易出现)"
    echo "   5. 💾 测试偏好持久化 (重启app后偏好保持)"
    echo ""
    echo "🎮 交互指南:"
    echo "   • 点击气泡: 选择偏好 (+5分)"
    echo "   • 向上滑动: 点赞 (+10分, 气泡变大)"
    echo "   • 向下滑动: 删除并替换 (-8分)"
    echo "   • 向左滑动: 忽略 (-2分)"
    echo "   • 向右滑动: 确认选择 (+5分)"
    echo ""
    
    # 运行Flutter应用
    flutter run -d ios --release
    
    echo ""
    echo "🎉 测试完成！"
    echo ""
    echo "📊 期望观察到的效果:"
    echo "   ✨ 每次启动显示不同的30个气泡组合"
    echo "   📈 喜欢的气泡会逐渐变大"
    echo "   🔄 滑动删除的气泡会被新气泡替换"
    echo "   💾 关闭重开app后用户偏好保持不变"
    
else
    echo "❌ 未找到iOS设备"
    echo ""
    echo "🔧 请确保:"
    echo "   1. iPhone已连接到Mac"
    echo "   2. 设备已解锁并信任此电脑"
    echo "   3. Xcode中已配置开发者账号"
    echo "   4. 在设备上启用开发者模式"
    echo ""
    echo "📱 所有可用设备:"
    flutter devices
fi