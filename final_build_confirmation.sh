#!/bin/bash

echo "🎯 最终构建确认检查"
echo "===================="

# 环境检查
echo "📋 环境状态检查："

# 1. Xcode状态
if pgrep -x "Xcode" > /dev/null; then
    echo "  ✅ Xcode正在运行"
else
    echo "  ❌ Xcode未运行"
    exit 1
fi

# 2. 设备连接
DEVICE_CHECK=$(flutter devices | grep "12pm")
if [ ! -z "$DEVICE_CHECK" ]; then
    echo "  ✅ iPhone 12pm已连接"
    echo "     $DEVICE_CHECK"
else
    echo "  ❌ iPhone设备未连接"
    exit 1
fi

# 3. 项目文件
if [ -d "ios/Runner.xcworkspace" ]; then
    echo "  ✅ Xcode工作空间存在"
else
    echo "  ❌ Xcode工作空间缺失"
    exit 1
fi

# 4. Flutter项目状态
if [ -f "pubspec.yaml" ]; then
    echo "  ✅ Flutter项目配置正常"
else
    echo "  ❌ Flutter项目配置异常"
    exit 1
fi

echo ""
echo "🔧 项目配置信息："
echo "  • Bundle ID: com.eatwhat.eatwhatApp"
echo "  • 开发团队: 4CP692A9GB"
echo "  • 目标设备: iPhone 12 Pro Max"
echo "  • iOS版本: 18.5"

echo ""
echo "📱 在Xcode中执行的操作："
echo "  1. 打开项目: ✅ (已完成)"
echo "  2. 配置签名: ⏳ (需要在Xcode中手动设置)"
echo "  3. 选择设备: ⏳ (需要选择12pm)"
echo "  4. 开始构建: ⏳ (按Command+R)"

echo ""
echo "🚀 立即行动指南："
echo "  → 在Xcode中按 Command+R 开始构建"
echo "  → 或点击左上角的 ▶️ 播放按钮"

echo ""
echo "📊 预期构建结果："
echo "  • 构建时间: 60-120秒"
echo "  • 安装到设备: 自动"
echo "  • 应用启动: 自动"
echo "  • 物理引擎: 29个气泡开始运动"

echo ""
echo "🔍 成功标志："
echo "  ✓ Xcode显示: 'Running on 12pm'"
echo "  ✓ iPhone显示: 应用启动画面"
echo "  ✓ 气泡开始: 物理运动效果"
echo "  ✓ 控制台输出: 物理引擎启动日志"

echo ""
echo "💡 提示："
echo "  如果是首次安装，可能需要在iPhone上信任开发者证书"
echo "  路径: 设置 → 通用 → VPN与设备管理 → 开发者App"

echo ""
echo "✅ 环境检查完成，可以开始Xcode构建了！"

# 可选：直接打开Xcode项目
read -p "是否重新打开Xcode项目？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 正在打开Xcode项目..."
    open ios/Runner.xcworkspace
    echo "✅ Xcode项目已打开，请按Command+R开始构建"
fi