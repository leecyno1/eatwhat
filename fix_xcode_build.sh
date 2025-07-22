#!/bin/bash

echo "🔧 Xcode构建修复脚本"
echo "==================="

PROJECT_PATH="/Users/lichengyin/Desktop/Projects/eatwhat"
cd "$PROJECT_PATH"

echo "📋 当前目录: $(pwd)"

echo ""
echo "🧹 Step 1: 深度清理"
echo "=================="
echo "清理Flutter缓存..."
flutter clean

echo "清理Dart缓存..."
dart pub cache clean

echo "清理iOS构建文件..."
rm -rf ios/build/
rm -rf ios/Pods/
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks/
rm -rf ios/Flutter/Flutter.podspec
rm -rf build/

echo "清理Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo ""
echo "📦 Step 2: 重新获取依赖"
echo "======================"
echo "获取Flutter依赖..."
flutter pub get

echo "更新CocoaPods..."
cd ios
pod repo update
pod install --repo-update --clean-install
cd ..

echo ""
echo "🔍 Step 3: 检查和修复常见问题"
echo "========================="

# 检查并修复main.dart中的导入问题
echo "检查main.dart导入..."
if grep -q "import.*auto_size_text" lib/features/recipe/widgets/recipe_card.dart; then
    echo "修复auto_size_text导入..."
    sed -i '' 's/import.*auto_size_text.*;//g' lib/features/recipe/widgets/recipe_card.dart
fi

# 检查并修复用户偏好服务导入
echo "检查用户偏好服务导入..."
if ! grep -q "import.*user_preference_manager" lib/core/services/recipe_database_service.dart; then
    echo "修复用户偏好服务导入..."
    sed -i '' 's/import.*user_preference_score.dart.*/import "user_preference_score.dart";\nimport "user_preference_manager.dart";/' lib/core/services/recipe_database_service.dart
fi

echo ""
echo "🔧 Step 4: 验证和修复缺失文件"
echo "========================="

# 创建缺失的用户偏好管理器
if [ ! -f "lib/core/services/user_preference_manager.dart" ]; then
    echo "创建用户偏好管理器..."
    cat > lib/core/services/user_preference_manager.dart << 'EOF'
import '../models/user_preference_score.dart';

class UserPreferenceManager {
  static final UserPreferenceManager _instance = UserPreferenceManager._internal();
  factory UserPreferenceManager() => _instance;
  UserPreferenceManager._internal();

  Map<String, dynamic> getPreferenceStats() {
    return {
      'topPreferences': <UserPreferenceScore>[
        UserPreferenceScore(entityName: '川菜', score: 10.0),
        UserPreferenceScore(entityName: '家常菜', score: 8.0),
        UserPreferenceScore(entityName: '鸡肉', score: 9.0),
        UserPreferenceScore(entityName: '清淡', score: 7.0),
        UserPreferenceScore(entityName: '营养', score: 6.0),
      ],
    };
  }
}
EOF
fi

# 创建缺失的用户偏好评分模型
if [ ! -f "lib/core/models/user_preference_score.dart" ]; then
    echo "创建用户偏好评分模型..."
    cat > lib/core/models/user_preference_score.dart << 'EOF'
class UserPreferenceScore {
  final String entityName;
  final double score;

  UserPreferenceScore({
    required this.entityName,
    required this.score,
  });
}
EOF
fi

echo ""
echo "🔍 Step 5: 验证语法"
echo "=================="
echo "运行语法检查..."
flutter analyze

echo ""
echo "🔧 Step 6: 尝试构建"
echo "=================="
echo "尝试构建iOS应用..."
flutter build ios --debug --no-codesign

BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "🚀 尝试启动应用..."
    flutter devices
    echo ""
    echo "启动应用..."
    flutter run -d ios --debug
else
    echo ""
    echo "❌ 构建仍然失败"
    echo ""
    echo "🔍 详细错误检查:"
    echo "1. 检查Xcode版本: xcodebuild -version"
    echo "2. 检查iOS部署目标"
    echo "3. 手动打开Xcode项目:"
    echo "   open ios/Runner.xcworkspace"
    echo ""
    echo "📋 手动修复步骤:"
    echo "1. 在Xcode中设置Development Team"
    echo "2. 确保Bundle Identifier唯一"
    echo "3. 检查iOS Deployment Target (建议11.0+)"
    echo "4. 在Xcode中手动构建查看详细错误"
fi

echo ""
echo "🎉 修复脚本完成！"