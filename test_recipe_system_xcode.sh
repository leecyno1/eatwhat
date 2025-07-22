#!/bin/bash

echo "🧪 菜谱系统 Xcode 测试脚本"
echo "=============================="

# 项目路径
PROJECT_PATH="/Users/lichengyin/Desktop/Projects/eatwhat"
cd "$PROJECT_PATH"

echo ""
echo "📱 检查iOS设备连接..."
flutter devices

echo ""
echo "🔍 检查iOS设备是否可用..."
IOS_DEVICE=$(flutter devices | grep -i "ios" | head -1)

if [ -z "$IOS_DEVICE" ]; then
    echo "❌ 未找到iOS设备，启动模拟器..."
    open -a Simulator
    sleep 10
    
    echo "🔄 重新检查设备..."
    flutter devices
    IOS_DEVICE=$(flutter devices | grep -i "ios" | head -1)
fi

if [ -z "$IOS_DEVICE" ]; then
    echo "❌ 仍未找到iOS设备或模拟器"
    echo "请确保："
    echo "1. iPhone连接到Mac并已信任"
    echo "2. 或iOS模拟器已启动"
    exit 1
fi

echo "✅ 找到iOS设备/模拟器"
echo "设备信息: $IOS_DEVICE"

echo ""
echo "🧹 清理构建缓存..."
flutter clean
flutter pub get

echo ""
echo "🔧 检查依赖..."
flutter pub deps

echo ""
echo "🚀 开始构建并运行应用..."
echo ""
echo "🎯 测试重点："
echo "   1. 📱 首页底部导航功能"
echo "   2. 🫧 偏好选择页面(气泡系统)"
echo "   3. 🍽️ 推荐菜谱页面"
echo "   4. 🔍 菜谱搜索页面"
echo "   5. ❤️ 收藏功能"
echo "   6. 📄 菜谱详情展示"
echo ""
echo "⚠️  重要测试项目："
echo "   • 验证菜谱数据是否正确加载"
echo "   • 测试用户偏好推荐算法"
echo "   • 检查UI组件响应性"
echo "   • 验证收藏/取消收藏功能"
echo "   • 测试搜索筛选功能"
echo ""

# 运行应用
echo "🏃‍♂️ 启动应用..."
flutter run -d ios --debug

echo ""
echo "🎉 测试完成！"
echo ""
echo "📊 预期测试结果："
echo "✅ 应用正常启动"
echo "✅ 底部导航正常工作"
echo "✅ 气泡偏好选择功能正常"
echo "✅ 菜谱推荐页面显示5个示例菜谱"
echo "✅ 菜谱搜索和筛选功能正常"
echo "✅ 收藏功能正常工作"
echo "✅ 菜谱详情弹窗正常显示"
echo ""
echo "🔍 如有问题，请检查："
echo "   • 控制台输出日志"
echo "   • 菜谱数据库初始化"
echo "   • UI组件渲染状态"
echo "   • 用户偏好服务运行状态"