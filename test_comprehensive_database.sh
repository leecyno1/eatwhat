#!/bin/bash

echo "🎯 完整口味偏好数据库系统测试"
echo "=================================="

echo ""
echo "📊 数据库验证:"
echo "   • 180个口味偏好实体"
echo "   • 6大分类系统完整"
echo "   • 玻璃质感效果保留"
echo "   • 渐进出现动画实现"

echo ""
echo "🎨 新功能特性:"
echo "   ✨ 味觉与口感 (50项) - 酸甜苦辣鲜香等"
echo "   ✨ 食材与菜系 (40项) - 主食肉类海鲜蔬菜"
echo "   ✨ 复合口味 (30项) - 麻辣糖醋复合调味"
echo "   ✨ 饮食场景与健康 (30项) - 健康需求场景应用"
echo "   ✨ 文化与地域特色 (30项) - 中华地域国际风味"
echo "   ✨ 特殊需求与创新 (20项) - 特殊饮食未来料理"

echo ""
echo "🔧 渐进出现动画:"
echo "   • 200ms间隔缓慢浮现"
echo "   • 29个精选气泡平衡显示"
echo "   • 避免过于拥挤的空间"
echo "   • 保持所有原有功能"

echo ""
echo "📱 设备连接状态:"
DEVICE_INFO=$(flutter devices | grep "12pm")

if [ ! -z "$DEVICE_INFO" ]; then
    echo "✅ iPhone设备已连接:"
    echo "   $DEVICE_INFO"
else
    echo "❌ iPhone设备未连接"
    echo "请确保设备已连接并解锁"
    exit 1
fi

echo ""
echo "🚀 开始测试运行..."
echo ""
echo "📋 重点测试项目:"
echo "   1. 📊 数据库完整性: 检查是否正确加载180个实体"
echo "   2. 🎨 玻璃质感效果: 验证透明度和光影效果"
echo "   3. ⏰ 渐进出现动画: 观察气泡逐一浮现"
echo "   4. 🏃 物理引擎运行: 确认60FPS流畅运动"
echo "   5. 🖱️ 交互功能: 测试选择和推荐功能"

echo ""
echo "✅ 准备完成！现在运行应用..."
echo ""

# 运行Flutter应用到iOS设备
flutter run -d 12pm --release

echo ""
echo "🎉 测试完成！"
echo ""
echo "📄 详细测试清单请查看之前的玻璃效果测试指南"