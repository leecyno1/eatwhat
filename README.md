# 《吃什么》Flutter 应用

一个帮助用户解决饮食选择困难的创新移动应用，通过气泡交互方式提供个性化美食推荐。

## 🌟 核心功能

### ✅ 已实现
- **气泡交互系统**: 创新的气泡选择界面，支持点击、滑动等手势
- **智能推荐引擎**: 基于用户偏好的食物推荐算法
- **外卖平台集成**: 美团、饿了么API接口集成
- **用户系统**: 登录、注册、个人资料管理
- **收藏功能**: 食物收藏和管理
- **搜索功能**: 智能食物搜索和筛选
- **历史记录**: 浏览历史追踪

### 🚧 开发中
- 真实API接口对接
- 推荐算法优化
- 用户偏好学习系统
- 社交分享功能

## 🏗️ 项目架构

```
lib/
├── core/                   # 核心模块
│   ├── models/            # 数据模型
│   ├── services/          # 业务服务
│   ├── utils/             # 工具类
│   └── theme/             # 主题配置
├── features/              # 功能模块
│   ├── auth/              # 认证模块
│   ├── bubble/            # 气泡系统
│   ├── recommendation/    # 推荐模块
│   ├── search/            # 搜索功能
│   ├── favorites/         # 收藏功能
│   └── user/              # 用户管理
└── shared/                # 共享组件
```

## 🚀 快速开始

### 环境要求
- Flutter SDK >=3.4.4
- Dart SDK >=3.4.4
- iOS 12.0+ / Android API 21+
- macOS 10.14+ (macOS版本)

### 安装依赖
```bash
flutter pub get
```

### 运行应用
```bash
# 调试模式
flutter run

# 发布模式
flutter run --release
```

## 📱 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Provider
- **本地存储**: Hive
- **网络请求**: Dio
- **动画**: Flutter原生动画库
- **图标**: Cupertino Icons

## 🎯 开发计划

### 阶段一 (当前)
- [x] 基础架构搭建
- [x] 核心功能实现
- [ ] 代码质量优化
- [ ] 单元测试编写

### 阶段二 (下期)
- [ ] 真实API集成
- [ ] 性能优化
- [ ] 用户反馈系统
- [ ] 多语言支持

### 阶段三 (未来)
- [ ] AI智能推荐
- [ ] 社交功能
- [ ] 离线模式
- [ ] 跨平台发布

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📊 项目统计

- **代码文件**: 38个Dart文件
- **代码行数**: 12,728行
- **功能模块**: 9个主要模块
- **开发进度**: 70%完成

## 🐛 问题反馈

如果你发现任何问题，请在 [Issues](https://github.com/your-repo/issues) 页面提交。

## 📞 联系我们

- 邮箱: your-email@example.com
- 微信: your-wechat
