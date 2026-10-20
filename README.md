# 《吃什么》Flutter 应用

解决「今天吃什么」的个性化饮食推荐 App：黑金物理舞台点选口味气泡、摇一摇生成推荐，覆盖做菜与到店两条执行路径。

## 当前状态（2026-10）

- 主线功能完成，release 构建三端通过：Android AAB 已用上传密钥签名（184MB）、iOS `--no-codesign` 存档（125MB）、Web 构建可用（170MB）
- 外卖下单：客户端与代理链路就绪，但美团开放平台资质认证挂起；生产环境外卖入口显示「尚未开通」（预期降级）
- AI 增强与会员支付：依赖自营后端三服务；未部署时自动降级，本地推荐/做菜链路不受影响
- 账号：本地共用账号，无云端同步（既定策略）

## 核心功能

- **口味气泡舞台**：食材/菜系/口味实体物理堆叠，点选收下、按住抓起、拖顶收下/拖底拉黑、摇一摇翻锅
- **本地优先推荐**：时间感知（早餐推粥面、深夜推烧烤）+ 近期已吃短期降权 + 营养向打分
- **冰箱找菜**：按家里现有食材反查可做菜品
- **结果页**：推荐理由、分享卡片（系统分享）、「就吃这个」直达做菜
- **做菜与到店**：步骤、食材采购清单；到店路径
- **收藏与周报**：收藏标签/菜品；一周饮食报告与判词
- **HowToCook 菜谱库**：195 条菜谱的完整步骤与 323 张步骤图
- **语音输入**：长按口述忌口，系统语音服务转写

## 架构

```text
main.dart -> AppV2 -> HomePage -> DecisionPage -> ResultPage
```

- `lib/v2/`：产品主线（首页/决策/结果/详情/执行/收藏/周报/主题）
- `lib/core/`、`lib/features/`：仍被复用的认证与基础服务（新增功能优先 `lib/v2/`）
- 资产：菜品图与步骤图以 WebP 形式打包，经 Git LFS 管理；`assets/data/*.db` 为本地菜谱库

## 快速开始

```bash
flutter pub get
cp .env.example .env          # .env 不入库、不打包
flutter run -d ios|android|chrome
```

客户端只应配置后端地址（`EXECUTION_PROXY_BASE_URL` 等非敏感项）；**长期有效的 AI/平台密钥一律放服务端**，不要进客户端包。

## 服务端（可选）

`scripts/` 提供三服务：`execution_proxy_server.dart`（AI/执行代理，默认 8787）、`meituan_delivery_adapter_server.dart`（美团适配器，默认 8788）、`payment_server.dart`（会员支付）。部署步骤见 `docs/DEPLOYMENT_GUIDE.md`；`scripts/mock_execution_proxy_server.dart` 供本地与集成测试使用。

## 测试

```bash
flutter analyze
flutter test                  # 465 个单元/Widget 用例
```

集成测试（需模拟器 + mock 代理）：

```bash
dart run scripts/mock_execution_proxy_server.dart 8787
flutter test integration_test -d <simulator-udid> --dart-define=EXECUTION_PROXY_BASE_URL=http://127.0.0.1:8787
```

Flutter 3.32 的 integration_test 不支持 Web 设备，Web 专属用例在 iOS 模拟器上显示 skip 属正常。

## 发布

```bash
flutter build appbundle --release     # Android（需 android/key.properties + 上传密钥库，二者已 gitignore，务必备份）
flutter build ios --release --no-codesign   # 需自有证书签名后上传 App Store Connect
flutter build web --release
```

商店材料（图标/头图/截图/双店文案/审核备注）见 `docs/store_assets/`；隐私政策：https://leecyno1.github.io/eatwhat/privacy_policy.html

## 数据规模

- `unified_recipes.db`：340 道菜、341 个菜谱变体、710 个标签
- `howtocook_complete_recipes.db`：195 条 HowToCook 菜谱
- `assets/images/prebuilt_dishes/`：882 张预制菜图（WebP）

## 已知限制

- 外卖未开通：等待美团开放平台资质审批（协议与安全证明按用户决定挂起）
- 部分 HowToCook 菜谱未收录步骤图，列表与详情显示占位图
- Web 端分享依赖浏览器文件分享能力；不支持时自动回退为复制分享文案（移动端为系统分享面板）

## 许可证

MIT，见 [LICENSE](LICENSE)。
