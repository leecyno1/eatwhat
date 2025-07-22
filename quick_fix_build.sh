#!/bin/bash

echo "🚀 快速修复Xcode构建问题"
echo "========================"

cd /Users/lichengyin/Desktop/Projects/eatwhat

echo "🧹 清理构建环境..."
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf build/

echo "📦 重新获取依赖..."
flutter pub get

echo "🔧 重新安装iOS依赖..."
cd ios
pod install --repo-update
cd ..

echo "🔍 检查语法..."
flutter analyze

echo "🏗️ 尝试构建..."
flutter build ios --debug --no-codesign

if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    echo "🚀 启动应用..."
    flutter run -d ios --debug
else
    echo "❌ 构建失败"
    echo "📋 尝试手动修复："
    echo "1. 打开 Xcode: open ios/Runner.xcworkspace"
    echo "2. 设置开发团队 (Development Team)"
    echo "3. 检查 Bundle Identifier"
    echo "4. 确保 iOS 版本 >= 11.0"
    echo "5. 在 Xcode 中手动构建"
fi