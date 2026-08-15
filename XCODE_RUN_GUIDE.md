# Xcode 运行指南 - 《吃什么》iOS 项目

## 🚀 快速开始

### 1. 环境检查
确保你的开发环境已经设置好：
```bash
flutter doctor
```
✅ Flutter (Channel stable, 3.32.0)
✅ Xcode - develop for iOS and macOS (Xcode 16.4)

### 2. 项目准备
```bash
# 清理缓存
flutter clean

# 获取依赖
flutter pub get

# 安装 iOS 依赖
cd ios && pod install && cd ..

# 构建项目（验证）
flutter build ios --no-codesign
```

## 🛠️ 通过 Xcode 运行项目

### 方法一：直接打开 Xcode 项目
1. 打开终端，进入项目目录
2. 执行命令：`open ios/Runner.xcworkspace`
3. 在 Xcode 中选择目标设备或模拟器
4. 点击 ▶️ 运行按钮

### 方法二：命令行打开
```bash
# 打开 Xcode 工作空间
open ios/Runner.xcworkspace

# 或者使用 Flutter 命令在 iOS 模拟器运行
flutter run

# 在真机运行（需要开发者账号）
flutter run -d [device-id]
```

## 📱 设备配置

### iOS 模拟器
- iPhone 15 Pro Max (推荐)
- iPhone 15 Pro
- iPhone 14 Pro Max
- iPad Pro 12.9"

### 真机测试
1. 连接 iPhone/iPad 到 Mac
2. 在 Xcode 中选择你的设备
3. 确保开发者账号已配置
4. 点击运行

## 🎯 Xcode 项目结构

```
ios/
├── Runner.xcworkspace          # 主工作空间（打开这个）
├── Runner.xcodeproj/           # Xcode 项目文件
├── Runner/                     # iOS 应用代码
│   ├── AppDelegate.swift       # 应用委托
│   ├── Info.plist             # 应用配置
│   └── Assets.xcassets/       # 应用图标和资源
├── Pods/                      # CocoaPods 依赖
└── RunnerTests/               # iOS 单元测试
    ├── BubblePhysicsTests.swift
    └── RunnerTests.swift
```

## ⚙️ 关键配置

### Bundle Identifier
- **当前配置**: `com.eatwhat.eatwhatApp`
- **可在**: `Runner/Info.plist` 中修改

### iOS 版本支持
- **最低版本**: iOS 12.0
- **推荐版本**: iOS 15.0+

### 权限配置
项目已配置以下权限：
- 📍 位置服务（用于外卖推荐）
- 📷 相机访问（用于拍照分享）
- 📱 网络访问（用于数据同步）

## 🔧 常见问题解决

### 1. Pod 安装失败
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

### 2. 签名错误
- 在 Xcode 中选择 `Runner` 项目
- 前往 `Signing & Capabilities`
- 选择你的开发团队
- 确保 Bundle Identifier 唯一

### 3. 模拟器黑屏
- 重启模拟器：`Device` → `Restart`
- 或使用命令：`xcrun simctl shutdown all`

### 4. 构建错误
```bash
# 清理所有缓存
flutter clean
cd ios && rm -rf build && cd ..
flutter pub get
cd ios && pod install && cd ..
```

## 🎨 应用特性

### 核心功能
- 🫧 **智能气泡交互系统** - 创新的用户偏好选择界面
- 🤖 **AI 智能推荐引擎** - 基于46维度口味向量的个性化推荐
- 📱 **现代化 UI 设计** - Material Design 3 + iOS 风格适配
- ⚡ **高性能物理引擎** - 流畅的气泡物理模拟
- 🔒 **安全数据加密** - 用户偏好本地加密存储

### 技术亮点
- **Flutter 3.32.0** - 最新稳定版本
- **Provider 状态管理** - 高效的状态管理解决方案
- **Go Router** - 声明式路由导航
- **Hive 数据库** - 轻量级本地数据存储
- **自定义物理引擎** - 零重力气泡交互体验

## 🚀 部署指南

### App Store 发布准备
1. 更新版本号：`pubspec.yaml` 中的 `version`
2. 生成发布构建：`flutter build ios --release`
3. 在 Xcode 中配置发布签名
4. 上传到 App Store Connect

### TestFlight 测试
1. 在 Xcode 中选择 "Any iOS Device (arm64)"
2. 选择 `Product` → `Archive`
3. 在 Organizer 中上传到 App Store Connect
4. 在 App Store Connect 中配置 TestFlight

## 🔍 调试技巧

### Xcode 调试
- **断点调试**: 在 Swift 代码中设置断点
- **性能分析**: 使用 Instruments 工具
- **内存分析**: 检查内存泄漏和性能问题

### Flutter 调试
```bash
# 调试模式运行
flutter run --debug

# 性能分析
flutter run --profile

# 查看日志
flutter logs
```

## 📞 支持与帮助

如果遇到问题，请检查：
1. ✅ Flutter 版本是否为 3.32.0
2. ✅ Xcode 版本是否为 16.4+
3. ✅ iOS 部署目标是否为 12.0+
4. ✅ CocoaPods 是否正确安装

---

**🍽️ 祝你使用愉快！享受《吃什么》带来的美食探索之旅！**