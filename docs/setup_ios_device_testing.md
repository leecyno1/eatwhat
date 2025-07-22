# iOS真机测试设置指南

## 当前状态
✅ **iOS项目配置**: 已检查完毕
✅ **依赖项安装**: 已完成 flutter pub get
✅ **设备发现**: 检测到无线连接的iPhone设备 "12pm" (iOS 18.5)
✅ **应用构建**: iOS应用已成功构建

## 在Xcode中设置真机测试

### 1. 打开Xcode项目
```bash
open ios/Runner.xcworkspace
```
*注意：请使用 `.xcworkspace` 文件，不是 `.xcodeproj`*

### 2. 配置签名和团队
1. 在Xcode中选择 **Runner** 项目
2. 选择 **Signing & Capabilities** 标签
3. 设置以下配置：
   - **Team**: 选择你的Apple Developer账号团队
   - **Bundle Identifier**: `com.eatwhat.eatwhatApp` (已配置)
   - **Signing Certificate**: 选择 "Apple Development"
   - **Provisioning Profile**: 选择 "Automatic"

### 3. 配置设备目标
1. 在Xcode顶部选择设备下拉菜单
2. 选择你的真机设备："12pm"
3. 确保设备已解锁并信任此电脑

### 4. 运行Flutter命令进行真机测试
```bash
# 方法1: 直接使用Flutter运行到设备
flutter run -d 00008140-001C29D93E60801C

# 方法2: 使用设备名称
flutter run -d "12pm"

# 方法3: 构建并安装
flutter install -d 00008140-001C29D93E60801C
```

## 物理引擎真机测试要点

### 测试项目
1. **触摸交互**: 点击气泡测试选择反馈
2. **物理运动**: 观察气泡的自然运动和碰撞
3. **性能表现**: 检查60FPS物理更新是否流畅
4. **触觉反馈**: 验证HapticFeedback在真机上的效果
5. **手势识别**: 测试滑动手势和长按交互

### 期望效果
- 29个气泡在屏幕中自由运动
- 气泡间碰撞产生真实的物理反应
- 边界反弹效果自然
- 触摸交互响应灵敏
- 物理运动流畅无卡顿

## 常见问题解决

### 签名问题
如果遇到签名错误：
1. 确保你有有效的Apple Developer账号
2. 在Xcode中登录你的Apple ID
3. 选择正确的开发团队
4. 信任开发者证书（设置 → 通用 → VPN与设备管理）

### 设备连接问题
如果设备未显示：
1. 确保设备已解锁
2. 信任此电脑
3. 检查WiFi连接（无线调试）
4. 重启Xcode和设备

### 性能问题
如果遇到性能问题：
1. 在真机上测试，模拟器性能不代表真机
2. 检查物理引擎16ms更新频率
3. 观察内存使用情况
4. 必要时调整物理参数

## 下一步操作
运行以下命令开始真机测试：
```bash
flutter run -d "12pm" --release
```

这将在发布模式下运行，获得最佳性能体验。