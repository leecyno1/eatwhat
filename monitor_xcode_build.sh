#!/bin/bash

echo "📱 Xcode真机构建监控脚本"
echo "============================="

# 检查Xcode是否运行
if ! pgrep -x "Xcode" > /dev/null; then
    echo "❌ Xcode未运行，正在启动..."
    open ios/Runner.xcworkspace
    echo "⏳ 等待Xcode启动..."
    sleep 5
else
    echo "✅ Xcode已运行"
fi

# 检查设备连接
echo ""
echo "📱 检查设备连接状态："
flutter devices | grep "12pm"

if [ $? -eq 0 ]; then
    echo "✅ iPhone设备已连接"
else
    echo "❌ iPhone设备未连接，请检查连接"
    exit 1
fi

echo ""
echo "🔍 当前构建环境信息："
echo "  • Xcode工作空间: ios/Runner.xcworkspace"
echo "  • 目标设备: iPhone 12 Pro Max (12pm)"
echo "  • Bundle ID: com.eatwhat.eatwhatApp"
echo "  • 开发团队: 4CP692A9GB"

echo ""
echo "📋 Xcode构建步骤提醒："
echo "  1. 确认项目已在Xcode中打开"
echo "  2. 选择Runner项目 → Signing & Capabilities"
echo "  3. 配置自动签名和开发团队"
echo "  4. 选择目标设备：12pm"
echo "  5. 按 Cmd+R 开始构建"

echo ""
echo "🔧 如需重新打开Xcode项目："
echo "  open ios/Runner.xcworkspace"

echo ""
echo "📊 实时监控构建日志..."
echo "  (监控Xcode构建过程，按Ctrl+C退出)"

# 监控Xcode构建活动
while true; do
    # 检查是否有活跃的xcodebuild进程
    BUILD_PROCESS=$(pgrep -f "xcodebuild.*Runner" 2>/dev/null)
    
    if [ ! -z "$BUILD_PROCESS" ]; then
        echo "🔨 [$(date '+%H:%M:%S')] Xcode正在构建..."
        
        # 检查构建日志
        if [ -f ~/Library/Developer/Xcode/DerivedData/*/Logs/Build/*.xcactivitylog ]; then
            LATEST_LOG=$(ls -t ~/Library/Developer/Xcode/DerivedData/*/Logs/Build/*.xcactivitylog 2>/dev/null | head -1)
            if [ ! -z "$LATEST_LOG" ]; then
                echo "📝 最新构建日志: $(basename "$LATEST_LOG")"
            fi
        fi
        
        # 等待构建完成
        while kill -0 $BUILD_PROCESS 2>/dev/null; do
            echo -n "."
            sleep 2
        done
        
        echo ""
        echo "✅ [$(date '+%H:%M:%S')] 构建过程完成"
        
        # 检查是否有运行中的应用
        if pgrep -f "Runner" > /dev/null; then
            echo "🎉 应用可能已在设备上启动"
        fi
        
        break
    else
        echo "⏳ [$(date '+%H:%M:%S')] 等待Xcode构建开始..."
        sleep 3
    fi
done

echo ""
echo "🔍 构建后检查："

# 检查构建产物
if [ -d "build/ios/iphoneos/Runner.app" ]; then
    echo "✅ iOS应用包已生成"
    echo "  路径: build/ios/iphoneos/Runner.app"
    
    # 检查应用包信息
    APP_SIZE=$(du -sh build/ios/iphoneos/Runner.app 2>/dev/null | cut -f1)
    echo "  大小: $APP_SIZE"
else
    echo "❌ 未找到iOS应用包"
fi

# 提供后续测试建议
echo ""
echo "🧪 后续测试建议："
echo "  1. 在iPhone上查找并启动'Eatwhat App'"
echo "  2. 观察29个气泡的物理运动效果"
echo "  3. 测试触摸交互和触觉反馈"
echo "  4. 检查Xcode Console的运行日志"

echo ""
echo "📱 物理引擎测试要点："
echo "  • 气泡自由运动 ✓"
echo "  • 碰撞检测效果 ✓"
echo "  • 触摸选择反馈 ✓"
echo "  • 60FPS流畅性 ✓"

echo ""
echo "✅ 监控完成。请在iPhone上测试应用效果！"