#!/bin/bash

echo "🎯 新交互逻辑测试 - iOS设备"
echo "==========================="

echo ""
echo "📱 检查设备连接..."
flutter devices

echo ""
echo "🔍 寻找iOS设备..."
DEVICE_INFO=$(flutter devices | grep -i "iphone\|ios")

if [ ! -z "$DEVICE_INFO" ]; then
    echo "✅ 找到iOS设备:"
    echo "$DEVICE_INFO"
    
    echo ""
    echo "🚀 启动应用测试..."
    echo ""
    echo "🎯 重点测试项目:"
    echo "   1. 📍 点击/长按无评分验证"
    echo "   2. 🔝 上滑喜欢 - 飞向顶端"
    echo "   3. 🔽 下滑讨厌 - 消失机制"
    echo "   4. 🎭 拖拽动画 - 跟随手势"
    echo "   5. 🔄 5个补充 - 自动替换"
    echo ""
    echo "🎮 新手势映射:"
    echo "   • 点击/长按: 选择 (无评分)"
    echo "   • 上滑: 喜欢 (+10分, 飞向顶端)"
    echo "   • 下滑: 讨厌 (-15分, 消失)"
    echo "   • 左滑: 忽略 (-2分)"
    echo "   • 右滑: 确认 (+5分)"
    echo ""
    echo "⚠️  关键测试: 连续下滑5个气泡观察补充效果!"
    echo ""
    
    # 运行到iOS设备
    flutter run -d ios --release
    
    echo ""
    echo "🎉 测试完成!"
    echo ""
    echo "📊 预期看到的效果:"
    echo "   ✅ 拖拽时气泡跟随手指移动"
    echo "   ✅ 上滑气泡飞向顶端"
    echo "   ✅ 下滑气泡飞向底端并消失"
    echo "   ✅ 每消失5个自动补充5个新气泡"
    echo "   ✅ 点击不影响气泡大小"
    
else
    echo "❌ 未找到iOS设备"
    echo ""
    echo "🔧 解决方案:"
    echo "   1. 连接iPhone到Mac"
    echo "   2. 解锁设备并信任电脑"
    echo "   3. 在Xcode中打开: ios/Runner.xcworkspace"
    echo "   4. 或使用模拟器: open -a Simulator"
fi