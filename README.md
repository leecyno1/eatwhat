# 《吃什么》- EatWhat App

一个帮助用户解决饮食选择困难的创新Flutter应用。通过气泡交互的方式，让用户选择口味、菜系、食材等偏好，智能生成个性化的美食推荐。

## 🌟 功能特性

### 核心功能
- **气泡交互系统**: 创新的气泡选择界面，支持点击、滑动等手势操作
- **智能推荐引擎**: 基于用户选择的气泡组合，生成个性化美食推荐
- **用户偏好学习**: 记录用户的喜好历史，不断优化推荐算法
- **物理引擎**: 真实的气泡物理效果，包含重力、碰撞检测等

### 气泡类型
- **口味气泡**: 甜、酸、辣、鲜、苦等味觉偏好
- **菜系气泡**: 川菜、粤菜、日料、韩料、西餐等
- **食材气泡**: 肉类、蔬菜、海鲜、豆制品等
- **情境气泡**: 早餐、午餐、晚餐、夜宵等用餐场景
- **营养气泡**: 高蛋白、低脂肪、高纤维等营养需求
- **温度气泡**: 热菜、冷菜、温菜等
- **辣度气泡**: 不辣、微辣、中辣、重辣等

### 推荐功能
- **食物卡片**: 精美的食物展示卡片，包含图片、评分、价格等信息
- **营养信息**: 详细的营养成分和热量信息
- **收藏功能**: 收藏喜欢的食物，建立个人美食库
- **评分系统**: 用户可以对推荐的食物进行评分

## 🛠 技术栈

### 前端框架
- **Flutter 3.32.0**: 跨平台移动应用开发框架
- **Dart**: 编程语言

### 状态管理
- **Provider**: 轻量级状态管理解决方案

### 数据存储
- **Hive**: 轻量级、快速的本地数据库
- **SharedPreferences**: 用户偏好设置存储

### 动画和物理
- **Flame**: 游戏引擎，用于气泡物理效果
- **Flutter Animation**: 原生动画系统

### 网络和工具
- **Dio**: HTTP客户端，用于网络请求
- **UUID**: 唯一标识符生成
- **Vector Math**: 数学计算库

## 📱 支持平台

- ✅ iOS
- ✅ Android
- ✅ macOS (测试用)

## 🚀 快速开始

### 环境要求
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- iOS: Xcode 14.0+
- Android: Android Studio 4.0+

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd eatwhat_app
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行应用**
```bash
# iOS模拟器
flutter run

# Android模拟器
flutter run

# macOS桌面 (测试用)
flutter run -d macos
```

### 编译发布版本

```bash
# iOS
flutter build ios

# Android
flutter build apk
```

## 📁 项目结构

```
lib/
├── core/                    # 核心功能
│   ├── models/             # 数据模型
│   │   ├── bubble.dart     # 气泡模型
│   │   ├── food.dart       # 食物模型
│   │   ├── user_preference.dart # 用户偏好模型
│   │   └── bubble_factory.dart # 气泡工厂
│   ├── services/           # 服务层
│   │   └── recommendation_engine.dart # 推荐引擎
│   ├── physics/            # 物理引擎
│   │   └── bubble_physics.dart # 气泡物理
│   └── utils/              # 工具类
├── features/               # 功能模块
│   ├── bubble/            # 气泡功能
│   │   ├── controllers/   # 控制器
│   │   ├── screens/       # 页面
│   │   └── widgets/       # 组件
│   └── recommendation/    # 推荐功能
│       ├── screens/       # 页面
│       └── widgets/       # 组件
├── shared/                # 共享组件
│   ├── widgets/          # 通用组件
│   ├── themes/           # 主题配置
│   └── constants/        # 常量定义
└── main.dart             # 应用入口
```

## 🎯 开发计划

### 已完成
- ✅ 项目架构搭建
- ✅ 气泡数据模型
- ✅ 气泡物理引擎
- ✅ 基础UI组件
- ✅ 推荐算法框架
- ✅ 用户偏好系统

### 进行中
- 🔄 气泡交互优化
- 🔄 推荐算法完善
- 🔄 UI/UX优化

### 待开发
- ⏳ 网络API集成
- ⏳ 用户账户系统
- ⏳ 社交分享功能
- ⏳ 离线模式
- ⏳ 多语言支持

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 项目Issues: [GitHub Issues](https://github.com/your-repo/issues)
- 邮箱: your-email@example.com

---

**《吃什么》** - 让选择美食变得简单有趣！ 🍽️✨ 