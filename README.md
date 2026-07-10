# 《吃什么》Flutter 应用

一个帮助用户解决饮食选择困难的 Flutter 应用。当前主线是 V2 体验：通过口味卡片收集偏好，先从本地统一菜谱库召回候选，再用 AI 做推荐收束与理由生成。

## 🌟 核心功能

### ✅ 已实现
- **V2 口味选择**: 首页通过口味卡片、自由文本和语音输入形成口味信号
- **本地优先推荐**: 基于 `unified_recipes.db` 做召回和启发式打分
- **AI 推荐收束**: 使用 SiliconFlow/MiniMax 兼容接口生成精排、理由、简介、营养和搭配内容
- **HowToCook 菜谱增强**: 用 HowToCook 数据补全食材、步骤和菜图
- **收藏与偏好学习**: 收藏标签/菜品，并把反馈写入本地偏好分数
- **执行路径**: 预留美团、饿了么、大众点评 Provider 和代理服务接入

### 🚧 开发中
- 真实外卖/到店 API 资质与代理服务对接
- 推荐算法优化
- 仓库治理与 CI 稳定化
- 旧版 `lib/core + lib/features` 收敛到 V2 主线

## 🏗️ 项目架构

```
lib/
├── main.dart              # 应用入口，初始化 Hive、EnvConfig、ProviderScope
├── v2/                    # 当前产品主线
│   ├── app_v2.dart        # MaterialApp + ScreenUtil + 首启问卷/引导
│   ├── core/              # V2 数据模型、推荐服务、执行平台、主题
│   └── features/          # V2 首页、决策页、结果页、详情页、收藏、执行
├── core/                  # 旧版基础服务和部分仍复用的数据/数据库服务
├── features/              # 旧版功能页，新增产品功能优先不要从这里扩展
└── shared/                # 跨版本共享组件和设计 token
```

当前主流程：

```text
main.dart -> AppV2 -> HomePage -> DecisionPage -> ResultPage
```

推荐链路：

```text
口味标签/自由输入
  -> V2Phase2RecommendationService
  -> UnifiedRecommendationServiceV2 本地召回
  -> GenerationService AI 收束
  -> V2HowToCookRecipeService 补全菜谱详情
  -> ResultPage 展示与执行
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

### 配置环境变量
开发时可以复制示例文件：

```bash
cp .env.example .env
```

`.env` 已被 `.gitignore` 忽略，并且不会作为 Flutter asset 打包。生产或 CI 更推荐使用编译参数注入非敏感配置：

```bash
flutter run --dart-define=SILICONFLOW_API_KEY=your_key
```

正式发布不要把长期有效的 AI 或平台密钥放在客户端包内，优先通过后端代理或短期 token 调用。

### 运行应用
```bash
# 调试模式
flutter run

# 发布模式
flutter run --release
```

## 📱 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Riverpod + 局部 ChangeNotifier/Service 单例
- **本地存储**: SharedPreferences、Hive、SQLite
- **网络请求**: Dio
- **路由**: V2 当前使用 MaterialApp + Navigator；旧版保留 GoRouter
- **动画/交互**: Flutter 动画、Flame、Rive、传感器输入

## 🎯 开发计划

### 当前优先级
- [x] V2 主链路搭建
- [x] 本地菜谱库 + AI 收束推荐
- [x] HowToCook 菜谱增强
- [ ] 修复 CI 阻断项
- [ ] 清理历史产物和旧版入口

### 下期
- [ ] 拆分结果页职责
- [ ] 扩充统一菜谱库
- [ ] 接入正式执行层代理服务
- [ ] 完善偏好学习和回归测试

## 📊 当前数据规模

- `assets/data/unified_recipes.db`: 340 道菜、341 个菜谱变体、710 个标签
- `assets/data/howtocook_complete_recipes.db`: 195 条 HowToCook 菜谱
- `assets/images/prebuilt_dishes/`: 结果页优先使用的预制菜图

核对命令：

```bash
sqlite3 assets/data/unified_recipes.db "select 'dish', count(*) from dish union all select 'recipe_variant', count(*) from recipe_variant union all select 'tag', count(*) from tag;"
sqlite3 assets/data/howtocook_complete_recipes.db 'select count(*) from howtocook_recipes;'
```

## 🧪 常用命令

```bash
flutter analyze
dart format .
flutter test
dart run build_runner build --delete-conflicting-outputs
```

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情
