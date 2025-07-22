#!/bin/bash

echo "🎯 iOS真机物理引擎测试脚本"
echo "================================"

# 检查设备连接
echo "📱 检查设备连接..."
flutter devices | grep "12pm"

if [ $? -eq 0 ]; then
    echo "✅ 设备连接正常"
else
    echo "❌ 设备连接失败"
    exit 1
fi

# 清理并构建
echo ""
echo "🧹 清理项目..."
flutter clean > /dev/null 2>&1

echo "📦 获取依赖..."
flutter pub get > /dev/null 2>&1

# 构建iOS应用
echo ""
echo "🔨 构建iOS应用..."
flutter build ios --debug --no-codesign

if [ $? -eq 0 ]; then
    echo "✅ iOS应用构建成功"
else
    echo "❌ iOS应用构建失败"
    exit 1
fi

# 安装到设备
echo ""
echo "📲 安装到真机设备..."
flutter install -d "12pm"

if [ $? -eq 0 ]; then
    echo "✅ 应用安装成功"
else
    echo "❌ 应用安装失败"
    exit 1
fi

# 启动应用
echo ""
echo "🚀 启动应用并监控..."
echo "请在设备上查看以下物理引擎效果："
echo ""
echo "🔮 预期效果："
echo "  • 29个气泡在屏幕中自由运动"
echo "  • 气泡间发生碰撞和反弹"
echo "  • 点击气泡产生选择效果"
echo "  • 触摸产生触觉反馈"
echo "  • 边界反弹效果自然"
echo ""
echo "📊 性能指标："
echo "  • 帧率: 60FPS"
echo "  • 更新频率: 16ms"
echo "  • 内存使用: <200MB"
echo ""

# 启动并监控
flutter run -d "12pm" --debug --verbose &
FLUTTER_PID=$!

echo "🔍 应用已启动，PID: $FLUTTER_PID"
echo "💡 提示："
echo "  • 在设备上打开'吃什么'应用"
echo "  • 观察气泡物理运动效果"
echo "  • 测试触摸交互功能"
echo "  • 按 Ctrl+C 停止监控"
echo ""

# 等待用户中断
wait $FLUTTER_PID

echo ""
echo "✅ iOS真机测试完成"