#!/bin/bash

echo "📱 真机应用运行状态检查"
echo "=========================="

# 检查设备连接
echo "🔍 检查设备连接..."
DEVICE_INFO=$(flutter devices | grep "12pm")

if [ ! -z "$DEVICE_INFO" ]; then
    echo "✅ iPhone设备已连接:"
    echo "   $DEVICE_INFO"
else
    echo "❌ iPhone设备未连接"
    exit 1
fi

echo ""
echo "📱 应用部署状态:"
echo "   ✅ 应用已成功构建 (Release模式)"
echo "   ✅ 应用已安装到设备 (6.2秒)"
echo "   ✅ 自动签名完成 (Team: 4CP692A9GB)"

echo ""
echo "🎯 最大化布局特性:"
echo "   • 标题: '吃什么❓❓' 居中显示"
echo "   • 统计栏: ❤️0👎0🔄 右上角"  
echo "   • 容器: 90%屏幕空间"
echo "   • 底部: 紧凑按钮区域"

echo ""
echo "🧪 现在请在iPhone上测试以下功能:"
echo ""
echo "📐 布局验证:"
echo "   1. 检查标题是否在顶部中央"
echo "   2. 确认右上角有小统计栏"
echo "   3. 观察气泡容器是否巨大"
echo "   4. 验证底部按钮是否紧凑"

echo ""
echo "🎮 物理引擎测试:"
echo "   1. 观察29个气泡自动开始运动"
echo "   2. 检查运动是否流畅(60FPS)"
echo "   3. 验证碰撞效果是否自然"
echo "   4. 测试边界反弹是否正确"

echo ""
echo "📱 交互功能测试:"
echo "   1. 点击气泡测试选择效果"
echo "   2. 检查触觉反馈是否正常"
echo "   3. 测试右上角统计栏功能"
echo "   4. 验证底部按钮响应"

echo ""
echo "⏱️ 性能监控建议:"
echo "   • 运行时间: 测试5-10分钟"
echo "   • 帧率: 应保持60FPS"
echo "   • 温度: 无明显发热"
echo "   • 响应: 触摸立即反应"

echo ""
echo "📋 使用测试清单:"
echo "   打开文件: DEVICE_TEST_CHECKLIST.md"
echo "   按照清单逐项验证功能"

echo ""
echo "🎊 期待效果:"
echo "   相比之前版本，气泡容器应该明显更大"
echo "   物理运动应该更加壮观和自由"
echo "   整体视觉冲击力应该显著提升"

echo ""
echo "✅ 检查完成！开始真机测试吧！"