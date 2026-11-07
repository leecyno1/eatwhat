# 两店提审执行清单（2026-11-01）

> 当前状态：**iOS 已提交审核**（`WAITING_FOR_REVIEW`，2026-11-01 20:33 CST）。Android 按用户决定暂缓，先完成 App Store 上线；App 备案暂不办理。
> 当前基线：`1.0.0+2`，Android `targetSdk 36`，iOS 仅 iPhone。

## 一、iOS 提审状态（2026-11-07 二次提交，等待审核）

| 项 | 值 |
| --- | --- |
| App Store Connect App | `6829432497`，Bundle ID `com.eatwhat.eatwhatApp`，SKU `EATWHAT-IOS-2026` |
| 版本 | `1.0`（`06a7ede0-3a69-4eeb-86ae-bae21d40a733`），自动发布（审核通过后） |
| 构建 | Build `2`（`73516623-248e-4313-9ade-21d48749bd93`），`VALID`，已关联版本 |
| 提审记录 | `6cdd5b4b-2917-4b83-9272-6b98ac98d95a`，提交时间 `2026-11-01T12:33:45Z` |
| IPA | `build/ios/ipa_manual/EatWhat.ipa`，149,396,815 B，SHA-256 `2c8bceca7793c1255915199034f2df25b9a4c77247d0841b9621e943e0d30523` |
| 签名 | 公司 Distribution 证书 `C77WZB6C97`；描述文件 `EatWhat App Store 2026-11`（UUID `6379a3b4-2b77-44aa-a4c1-5adcf242b576`）；`codesign --verify --deep --strict` 通过 |
| 截图 | iPhone 6.7" 1290×2796 ×3，状态 `COMPLETE` |
| 价格 | 免费（美国 USD 0.00 价格点） |
| 销售范围 | 144 个国家或地区；**排除中国大陆**（未办备案）与 **EEA 30 国**（DSA 交易商状态未申报） |
| 年龄分级 | 全部分级项 `NONE`/`false`；`ageRatingOverrideV2=NONE` |
| 内容版权 | `USES_THIRD_PARTY_CONTENT`（HowToCook 上游 Unlicense，菜品图为项目预构建/AI 生成） |
| App 隐私 | 已发布：精确位置（App 功能）、其他用户内容（产品个性化、App 功能）；均不关联身份、不用于追踪 |
| 审核信息 | 演示账号、账号删除路径、外卖降级说明、位置/麦克风触发说明、无 App 内购说明；联系方式盛恬子 / +86 18810660112 / apple@monkeykingfury.com |
| 2.1 被拒与重提 | 2026-11-02 被拒（2.1 Information Needed）；已补英文六项说明与 69 秒录屏 https://eatwhat.monkeykingfury.com/review/eatwhat-review.mp4；2026-11-07 14:05 UTC 重新提交，当前 `WAITING_FOR_REVIEW` |
| 隐私/支持网页 | `https://eatwhat.monkeykingfury.com/privacy_policy.html`、`support.html`、`account_deletion.html` |

### 本次修复

- Build 1 上传失败（错误 90426：缺少 `SwiftSupport`）：重新按标准 IPA 结构打包，加入 `SwiftSupport/iphoneos/libswift_Concurrency.dylib`，Build 2 处理通过。
- 补充 `NSLocationAlwaysAndWhenInUseUsageDescription`，消除上传警告 90683。
- 仍有一条警告：iOS 部署目标 13.0；**2027-04 前需升至 15.0**，否则无法再上传或提交。

## 二、仍需账户持有人处理

1. **《Apple Developer Program 许可协议》已更新**：App Store Connect 首页仍显示需账户持有人到 `https://developer.apple.com/account` 查阅并接受。本次提审已通过，但建议尽快接受，避免审核流程被协议状态卡住。
2. **欧盟 DSA 交易商状态**：当前未申报，故已排除 EEA 30 国。如需欧盟分发，先申报交易商状态，再把 EEA 加回销售范围。
3. **中国大陆**：按用户 2026-11-01 决定暂缓备案，已排除中国大陆。后续办理需域名、国内云资源、HTTPS 与工信部 App 备案号，再勾选中国大陆。
4. **Google Play**：尚未注册。组织账号可用公司 D-U-N-S `443805134`，免个人新号的「12 名测试员连续 14 天」封闭测试；一次性注册费 $25，无额外测试费。若只上国内安卓商店，Play 非必需，但国内商店需要 App 备案。

## 三、Android 现状（暂缓）

| 项 | 值 |
| --- | --- |
| AAB | `build/app/outputs/bundle/release/app-release.aab`，184,689,353 B，SHA-256 `1f23c1cfdda02cd9417eed04ba70630abccaa73449df820e2d75b53e9fb6524a` |
| 上传密钥 | `eatwhat-upload`（CN=EatWhat Upload, O=Beijing Dasheng Zhinu Technology Co Ltd），证书 SHA-256 `D7:40:E8:95:…:9A:FB`；`android/app/upload-keystore.p12` 必须离线备份 |
| Play 下载体积 | bundletool：最小 138,176,362 B（131.8 MiB），最大 146,895,762 B（140.1 MiB），低于 200 MB |
| 16 KB 页对齐 | APK `zipalign -c -P 16` 通过；arm64 `libflutter.so`/`libapp.so` PT_LOAD 对齐 `0x10000` |
| targetSdk | 36（满足 2026-08-31 起的新规），minSdk 23 |

## 三点五、蒲公英内测分发（2026-11-03 已上传）

| 端 | 短链 | 版本 | 包 |
| --- | --- | --- | --- |
| Android | https://www.pgyer.com/chishenme-android-9 | 1.0.0 (versionCode 1) | `build/pgyer/eatwhat-android-1.0.0.apk`，SHA-256 `68ca0bd5…2df3b` |
| iOS Ad Hoc | https://www.pgyer.com/chishenme-ios-5 | 1.0.0 (CFBundleVersion 2) | `build/ios/adhoc/EatWhat-AdHoc.ipa`，SHA-256 `834b82a7…d396` |

- iOS 包由 App Store Archive 的 `Runner.app` 用公司 Distribution 证书 `C77WZB6C97` 重签，嵌入 eatwhat 专用 Ad Hoc 描述文件 `EatWhat Ad Hoc 2026-11`（profile id `J3Z58WMD94`，UUID `b792bd48-425c-4f5b-a6c4-73ee4d96e730`，有效期至 2027-10-23），**未复用其他 App 的描述文件**。
- Ad Hoc 只能装到已登记 UDID 的设备；当前公司团队有 3 台设备（1 台 iPhone、2 台 iPad）。新增设备：ASC API `POST /v1/devices` 登记 → 把设备加入该 profile → 重新下载 profile 并重签 IPA → 重新上传蒲公英。
- 蒲公英页面显示的「build 1」是蒲公英自己的上传序号，不是 CFBundleVersion。
- API Key 只从 macOS 钥匙串读取（`uk.newma.pgyer.api-key`），不写入仓库或文档。
- macOS / Windows / Linux / Web 不在蒲公英支持范围；需要分发时另走 GitHub Releases 或自建网页。

## 三点六、官网与服务器域名（2026-11-06 已迁移）

| 项 | 值 |
| --- | --- |
| 会员官网 | https://eatwhat.monkeykingfury.com（原裸 IP `http://154.194.253.179`，release 包会因非 HTTPS 判定不可用） |
| 认证 / 会员 API | https://eatwhat.monkeykingfury.com/api/v1/... |
| 执行代理 | https://eatwhat.monkeykingfury.com/eatwhat/ |
| 美团 OAuth 回调 | https://eatwhat.monkeykingfury.com/eatwhat/api/v1/delivery/oauth/callback |
| 证书 | Let's Encrypt，`eatwhat.monkeykingfury.com`，至 2027-02-04，certbot 自动续期 |
| 服务 | systemd `eatwhat-auth` (8789)、`eatwhat-proxy` (8787)、`eatwhat-adapter` (8788)，开机自启 |
| 权限归属 | Cloudflare zone `monkeykingfury.com`，A 记录 DNS only |
| drlemon.cc | 保持原样，个人档案站，与本 App 无关 |

- 客户端 `.env` 已切换到上述域名；已提审的 build 2 仍是旧 IP 构建，AI/外卖/会员入口在 release 下按降级隐藏。要启用需要重新构建并重新提审。

## 四、App Store 后台字段速填

| 字段 | 值 |
| --- | --- |
| 应用名 | 吃什么-今天吃啥一摇就有答案 |
| 副标题 | 口味气泡摇一摇，秒出菜品推荐 |
| 分类 | Food & Drink（主）、Lifestyle（次） |
| 支持 URL | https://eatwhat.monkeykingfury.com/support.html |
| 隐私政策 | https://eatwhat.monkeykingfury.com/privacy_policy.html |
| 账号删除 | https://eatwhat.monkeykingfury.com/account_deletion.html |
| 客服邮箱 | leecyno1@hotmail.com |
| 审核联系方式 | 盛恬子 / +86 18810660112 / apple@monkeykingfury.com |
| 演示账号 | 17600806220 / Iv19whot@123（应用内置本地账号） |

## 五、提审前最后复核

- [x] 公司签名 Archive、IPA 校验、上传与构建处理
- [x] 截图、文案、审核备注、联系方式
- [x] App 隐私、年龄分级、内容版权、免费定价、销售范围
- [x] 演示账号、账号删除入口、隐私/支持网页公网可访问
- [x] 提交审核（`WAITING_FOR_REVIEW`）
- [ ] 账户持有人接受更新后的 Apple Developer Program 许可协议
- [ ] 如需欧盟：申报 DSA 交易商状态并加回 EEA
- [ ] 如需中国大陆/国内安卓：办理 App 备案
