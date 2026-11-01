# 两店提审执行清单（2026-11-01）

> 技术侧已收口；剩余步骤需要商店账号登录或区域资质。当前基线：version `1.0.0+1`，Android `targetSdk 36`，iOS 仅 iPhone、竖屏。

## 一、已就绪

| 项 | 证据 |
| --- | --- |
| Android 包 | `build/app/outputs/bundle/release/app-release.aab`（SHA-256 `1f23c1cfdda02cd9417eed04ba70630abccaa73449df820e2d75b53e9fb6524a`），上传密钥 `eatwhat-upload`（CN=EatWhat Upload, O=Beijing Dasheng Zhinu Technology Co Ltd），证书 SHA-256 `D7:40:E8:95:…:9A:FB` |
| Play 下载体积 | bundletool `get-size total`：最小 138,176,362 B（131.8 MiB），最大 146,895,762 B（140.1 MiB），低于 200 MB |
| 16 KB 页对齐 | APK `zipalign -c -P 16` 通过；arm64 `libflutter.so`/`libapp.so` 的 PT_LOAD 对齐 0x10000 |
| Play targetSdk | manifest `targetSdkVersion=36`、`minSdkVersion=23`，符合 2026-08-31 起的新规 |
| iOS 构建环境 | Xcode 26.6 / iOS 26.5 SDK；`flutter build ios --release --no-codesign` 可产出 Release |
| iOS 合规 | `PrivacyInfo.xcprivacy` 随包；`ITSAppUsesNonExemptEncryption=false`；麦克风/定位/语音用途文案齐全 |
| 账号删除 | 账号面板底部「注销账号」→ 密码确认；说明页 `docs/account_deletion.html` |
| 商店图形 | App Store 6.7" 1290×2796 ×3；Play 1080×1920 ×4、1024×500 头图、512×512 图标；1024 图标无 alpha |
| 文案 | `docs/store_assets/store_copy.md`（名称/副标题/短描述/完整描述/关键词） |
| 审核备注 | `docs/store_assets/review_notes.md`（演示账号 17600806220 / Iv19whot@123） |
| 内容版权 | HowToCook 上游为 Unlicense（公有领域，允许商用）；菜品图为本项目预构建/AI 生成 |
| 网页 | 隐私政策、账号删除、支持页，托管于 `https://leecyno1.github.io/eatwhat/` |

## 二、需要账号操作的阻塞项

### 1. Apple 团队与 App 记录（公司团队已配置）

- 已注册公司 Bundle ID：`com.eatwhat.eatwhatApp`，资源 ID `F82JFDS5MG`，Seed `LS66SWVCG2`。
- 已导入公司 Distribution 证书 `C77WZB6C97` 到专用钥匙串 `~/Library/Keychains/eatwhat-signing.keychain-db`；钥匙串密码存于登录钥匙串条目 `eatwhat-signing-keychain`，不写入仓库。
- 已创建并安装 App Store 描述文件 `EatWhat App Store 2026-11`，UUID `6379a3b4-2b77-44aa-a4c1-5adcf242b576`。
- Release/Profile 已切公司团队手动签名；Archive 成功，IPA 已生成并通过 `codesign --verify --deep --strict`。
- **仍缺 App Store Connect App 记录**：API 不支持创建 App，需登录网页创建（平台 iOS、Bundle ID `com.eatwhat.eatwhatApp`、SKU 可用 `EATWHAT-IOS-2026`、主要语言简体中文）。创建后即可上传 IPA。
- 上传命令：`xcrun altool --upload-app -f build/ios/ipa_manual/EatWhat.ipa -t ios --apiKey 225ZN37C2H --apiIssuer e79e0f6f-5e22-4a9f-a6d4-0db64049825b`（需先把 `.p8` 放到 `~/.appstoreconnect/private_keys/`）。

### 2. Google Play 开发者账号（需要新注册）

- 建议注册**组织账号**并使用公司 D-U-N-S `443805134`，卖方显示公司主体；组织验证通常需要数天。
- 若注册**个人账号**：正式发布前必须完成封闭测试，**12 名测试员连续 14 天**保持参与，再申请生产权限。
- 注册入口：https://play.google.com/console/signup（Google 账号、25 美元注册费、身份/组织材料）。
- 注册后操作：创建应用 → 商店信息 → 数据安全 → 内容分级 → 广告声明 → 应用访问 → 账号删除 URL → 上传 AAB（内部测试 → 封闭测试 → 正式版）。

### 3. 中国大陆 availability 与 App 备案（现在办理）

- App Store 中国大陆分发需要工信部 **App 备案号**；总控未登记任何 ICP/App 备案信息。
- 备案必须通过 **App 的网络接入服务提供者**（阿里云/腾讯云/华为云等）提交，由主体所在省通信管理局审核；需要域名、国内服务器/云资源与主体材料。
- 当前生产配置为 `http://154.194.253.179`（明文、境外 IP），**不能直接用于备案**，也不满足 release 的 HTTPS 约束。备案前需要：域名（如 `eatwhat.app`）+ 国内云服务器/接入商 + HTTPS 证书 + 反向代理。
- 备案常见材料：营业执照、法人身份证、法人手机号/邮箱、App 负责人信息、App 名称与包名（`com.eatwhat.eatwhatApp` / `com.eatwhat.eatwhat_app`）、App 图标与签名信息、域名与服务器信息、服务内容说明、承诺书。
- 备案号下来后填入 App Store Connect「China mainland ICP filing」，再勾选中国大陆。
- Google Play 不覆盖中国大陆，无此要求。
- 另：欧盟 DSA 交易商身份（Apple 与 Google 都要填）尚未在总控确认，影响欧盟分发。

## 三、商店后台字段速填

### 两店共用

| 字段 | 值 |
| --- | --- |
| 应用名（Play） | 吃什么：今天吃啥一摇就有答案 |
| 应用名（Apple） | 吃什么-今天吃啥一摇就有答案 |
| 副标题 / 短描述 | 口味气泡摇一摇，秒出菜品推荐 / 选择困难终结者：点选口味气泡、摇一摇翻锅，秒出个性化菜品推荐；冰箱剩啥反查能做菜，一周饮食报告帮你吃得更健康。 |
| 分类 | Food & Drink；Apple 可选 Lifestyle |
| 客服邮箱 | leecyno1@hotmail.com |
| 支持 URL | https://leecyno1.github.io/eatwhat/support.html |
| 隐私政策 | https://leecyno1.github.io/eatwhat/privacy_policy.html |
| 账号删除 | https://leecyno1.github.io/eatwhat/account_deletion.html |
| 审核联系方式 | 盛恬子 / +86 18810660112 / apple@monkeykingfury.com |
| 演示账号 | 17600806220 / Iv19whot@123 |

### Google Play

- **广告**：不含广告。
- **应用访问**：核心功能无需登录；登录演示账号见上。
- **内容分级**：无暴力、色情、赌博、恐怖内容；菜谱可能含料酒/啤酒等酒精配料，按问卷如实选“轻微提及酒精”，预计 12+/Teen。
- **目标受众**：13 岁及以上（含酒精配料内容，不申报儿童）。
- **数据安全（建议口径）**：
  - 位置：仅用户主动搜索附近门店时收集，经自营代理转发美团/点评，不长期留存；用途“应用功能”；可拒绝。
  - 用户内容：口味描述/忌口文本；AI 增强启用时经自营服务器转发 MiniMax，不含身份信息。
  - 账号信息（用户名/邮箱）、收藏与记录：仅本机，不上传。
  - 不收集：通讯录、短信、照片、财务信息、健康数据、广告 ID。
  - 删除方式：应用内注销 + 账号删除 URL。
- **敏感权限**：麦克风声明见 `review_notes.md`。

### App Store

- **App 隐私**：与上表一致；位置、用户内容、账号标识（如申报）均“不用于追踪、不与广告共享”。
- **年龄分级**：含轻微酒精配料提及，建议 12+/13+；不使用“儿童”类别。
- **出口合规**：仅使用 HTTPS/系统加密，勾选豁免。
- **审核备注**：直接粘贴 `docs/store_assets/review_notes.md`。
- **截图**：6.7" 三张 1290×2796 已满足当前 iPhone 要求；如后续 Apple 强制 6.9" 新尺寸（2027-04 起），再补 1320×2868。
- **iPad**：工程已改为 iPhone-only，无需 iPad 截图与 iPad 审核适配。

## 四、上传与提交流程

### Google Play

1. Play Console → 创建应用 → 填写默认语言、应用名、游戏/应用、免费。
2. 设置 → 应用完整性 → 应用签名：上传密钥即 `android/app/upload-keystore.p12`（务必备份，丢失无法更新）。
3. 内部测试 → 创建版本 → 上传 `app-release.aab` → 填写版本说明。
4. 补齐商店信息、数据安全、内容分级、广告、应用访问、账号删除 URL。
5. 内测安装核对下载体积与首启；如为个人新号，转封闭测试 12 人/14 天。
6. 申请正式发布 → 分阶段 rollout。

### App Store

1. 确认团队与证书（见阻塞项）。
2. 注册 Bundle ID `com.eatwhat.eatwhat_app` → App Store Connect 创建 App 记录。
3. 填写商店信息、上传截图、填写隐私与年龄分级、审核备注。
4. `flutter build ipa --release`（使用公司团队签名）→ Transporter 或 `xcrun altool --upload-app` 上传。
5. TestFlight 内测 → 提交审核。
6. 中国大陆区域待 App 备案号下来后再勾选。

## 五、提审前最后复核

- [ ] `flutter analyze` 无 issue；`flutter test` 全绿；`dart format --set-exit-if-changed` 通过
- [ ] 用最终 AAB/ipa 复跑首启、登录、注销、推荐、做菜、收藏、周报
- [ ] 隐私政策/账号删除/支持页公网 200
- [ ] 商店截图与当前构建 UI 一致（无旧图标/旧文案）
- [ ] 演示账号可登录，注销路径可用
- [ ] 版本号与构建号在商店内唯一
- [ ] 上传密钥与公司证书已离线备份
