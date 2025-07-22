#!/bin/bash

echo "🔧 Xcode构建失败诊断和修复脚本"
echo "=================================="

# 项目路径
PROJECT_PATH="/Users/lichengyin/Desktop/Projects/eatwhat"
cd "$PROJECT_PATH"

echo ""
echo "📋 当前目录: $(pwd)"
echo "📅 时间: $(date)"

echo ""
echo "🔍 Step 1: 检查Flutter环境"
echo "-------------------------"
flutter --version
flutter doctor

echo ""
echo "🔍 Step 2: 检查项目结构"
echo "--------------------"
if [ -f "pubspec.yaml" ]; then
    echo "✅ pubspec.yaml 存在"
else
    echo "❌ pubspec.yaml 不存在"
    exit 1
fi

if [ -d "ios" ]; then
    echo "✅ ios 目录存在"
else
    echo "❌ ios 目录不存在"
    exit 1
fi

if [ -d "lib" ]; then
    echo "✅ lib 目录存在"
else
    echo "❌ lib 目录不存在"
    exit 1
fi

echo ""
echo "🔍 Step 3: 检查关键文件"
echo "--------------------"
KEY_FILES=(
    "lib/main.dart"
    "lib/core/models/recipe.dart"
    "lib/core/services/recipe_database_service.dart"
    "lib/features/home/screens/home_screen.dart"
    "ios/Runner.xcodeproj/project.pbxproj"
)

for file in "${KEY_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file 不存在"
    fi
done

echo ""
echo "🔍 Step 4: 检查iOS配置"
echo "-------------------"
if [ -f "ios/Podfile" ]; then
    echo "✅ Podfile 存在"
else
    echo "❌ Podfile 不存在"
fi

if [ -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]; then
    echo "✅ Xcode workspace 存在"
else
    echo "❌ Xcode workspace 不存在"
fi

echo ""
echo "🧹 Step 5: 清理构建缓存"
echo "---------------------"
echo "清理Flutter缓存..."
flutter clean

echo "清理iOS构建缓存..."
if [ -d "ios/build" ]; then
    rm -rf ios/build
    echo "✅ 清理 ios/build"
fi

if [ -d "ios/Pods" ]; then
    rm -rf ios/Pods
    echo "✅ 清理 ios/Pods"
fi

if [ -f "ios/Podfile.lock" ]; then
    rm -f ios/Podfile.lock
    echo "✅ 清理 Podfile.lock"
fi

echo ""
echo "📦 Step 6: 重新获取依赖"
echo "---------------------"
echo "获取Flutter依赖..."
flutter pub get

echo "获取iOS依赖..."
cd ios
pod install --repo-update
cd ..

echo ""
echo "🔍 Step 7: 检查语法错误"
echo "--------------------"
echo "检查Dart语法..."
flutter analyze

echo ""
echo "🔍 Step 8: 尝试构建"
echo "-----------------"
echo "检查可用设备..."
flutter devices

echo ""
echo "尝试构建iOS应用..."
flutter build ios --debug --no-codesign

echo ""
echo "🔍 Step 9: 构建结果分析"
echo "--------------------"
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "✅ 构建成功！"
    echo ""
    echo "🚀 尝试启动应用..."
    flutter run -d ios --debug
else
    echo "❌ 构建失败，错误代码: $BUILD_EXIT_CODE"
    echo ""
    echo "🔍 常见问题检查:"
    echo "1. 检查Xcode版本是否支持"
    echo "2. 检查iOS部署目标版本"
    echo "3. 检查代码签名配置"
    echo "4. 检查依赖包版本冲突"
    echo ""
    echo "📋 建议修复步骤:"
    echo "1. 打开Xcode: open ios/Runner.xcworkspace"
    echo "2. 检查项目设置中的Team和Bundle Identifier"
    echo "3. 确保iOS版本设置正确"
    echo "4. 手动构建查看详细错误信息"
fi

echo ""
echo "🎉 诊断完成！"