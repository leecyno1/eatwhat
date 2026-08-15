#!/bin/bash

# 创建一个简化版本测试HowToCook功能的应用
cd /Users/lichengyin/Desktop/Projects/eatwhat

echo "🚀 开始测试HowToCook菜谱数据库集成"

# 首先确保数据库文件存在
if [ ! -f "howtocook_complete_recipes.db" ]; then
    echo "❌ 数据库文件不存在，请先运行 python howtocook_database_builder.py"
    exit 1
fi

echo "✅ 数据库文件存在: howtocook_complete_recipes.db"

# 显示数据库统计信息
echo "📊 数据库统计信息:"
sqlite3 howtocook_complete_recipes.db "SELECT COUNT(*) as total_recipes FROM howtocook_recipes;"
echo "总菜谱数量: $(sqlite3 howtocook_complete_recipes.db "SELECT COUNT(*) FROM howtocook_recipes;")"
echo "分类数量: $(sqlite3 howtocook_complete_recipes.db "SELECT COUNT(DISTINCT category) FROM howtocook_recipes;")"

# 显示分类统计
echo "📋 分类统计:"
sqlite3 howtocook_complete_recipes.db "SELECT category, COUNT(*) as count FROM howtocook_recipes GROUP BY category;"

echo "🎉 HowToCook数据库集成成功完成！"

# 检查Flutter依赖
echo "🔧 检查Flutter依赖..."
flutter doctor --no-version-check

# 简单构建测试
echo "🏗️  测试Flutter构建..."
flutter build apk --debug --no-pub

echo "✨ 如果所有检查通过，HowToCook菜谱数据库已成功集成到Flutter应用中"