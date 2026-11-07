# 提审备注与演示账号（2026-11-01 版）

提交时直接使用以下内容；真实凭据仅用于商店审核演示，勿用于其他服务。

## 演示账号（两店通用）

- 用户名：17600806220
- 密码：Iv19whot@123
- 该账号为应用内置本地账号，无服务端校验；首次启动自动创建。
- 推荐、菜谱、收藏与周报等核心功能无需登录即可体验；登录后可查看会员状态。

## Google Play「应用访问说明」

本应用核心功能无需登录。若需查看登录后的账号与会员面板，请使用上方演示账号。

## Google Play「敏感权限用途声明」（麦克风）

麦克风仅用于用户长按语音按钮时，将口述的忌口与要求经系统语音服务转写为文字；应用不录制、不存储、不上传录音。

## Google Play「账号删除」

- 应用内路径：首页右上角账号入口 → 账号面板底部「注销账号」→ 输入密码确认。
- 删除说明页：https://eatwhat.monkeykingfury.com/account_deletion.html

## App Store「App 审核信息 / 备注」（2026-11-06 2.1 被拒后重写）

> 2026-11-02 Apple 以 Guideline 2.1 - Information Needed 拒绝，要求补充录屏与六项说明。以下为提交到 App Store Connect「App 审核信息 → 备注」的英文正文，录屏链接待补。

```text
Guideline 2.1 - Information Provided

1. Screen recording
https://eatwhat.monkeykingfury.com/review/eatwhat-review.mp4
Recorded with the submitted build (1.0, build 2) on an iPhone 17 simulator running the latest iOS. It starts at the Home Screen with the app launch and shows: first-launch tutorial, taste-bubble tap/hold/drag, shake-to-generate, result page with reasons, recipe detail with steps and shopping list, fridge-ingredient search, favorites and weekly report, account registration/login, and the account-deletion confirmation flow.

2. Purpose and target audience
"EatWhat" (吃什么) helps people decide what to eat today. Target users are students and office workers who cook at home or order takeout and often face decision fatigue. The app turns taste preferences into a physical bubble pot; shaking generates dishes ranked by time of day, recent meals and nutrition. It also turns the ingredients already in the fridge into cookable dishes, with step-by-step recipes and shopping lists. Value: fewer decisions, less food waste, more home cooking.

3. Setup and access
No server, registration or configuration is required; all data is stored on the device. A demo account is seeded on first launch: 17600806220 / Iv19whot@123. If it is deleted, relaunching the app recreates it. All core features (bubbles, recommendation, recipes, fridge search, favorites, weekly report) work without login; login only opens the account/membership panel.

4. External services, tools and platforms
- Core app: none. The recipe library and step images are bundled in the app.
- Optional AI enhancement: a self-hosted proxy to MiniMax's chat API. This build has no proxy configured, so AI enhancement is disabled and the app uses its local recommendation engine.
- Delivery: Meituan Open Platform integration is implemented but disabled in this build ("service not yet available") pending platform approval. No order or payment can occur.
- Voice input: Apple's system Speech framework; audio is not recorded, stored or uploaded.
- Location: requested only when the user searches nearby stores; not used in this build.
- No ads, no third-party analytics SDK, no payment SDK and no in-app purchases.

5. Regional differences
None. The app behaves identically in all regions. The delivery entry is shown as unavailable everywhere until platform approval is completed.

6. Regulated industry / third-party material
Not a regulated industry. Recipe texts and step photos come from the open-source HowToCook project (MIT License); UI, branding, icons and generated dish images are original works owned by us.

Support: https://eatwhat.monkeykingfury.com/support.html
Privacy: https://eatwhat.monkeykingfury.com/privacy_policy.html
Account deletion: https://eatwhat.monkeykingfury.com/account_deletion.html
```

## 数据安全 / 隐私标签申报口径（两店通用）

- 收集：精确位置（仅附近门店搜索，经自营代理转发美团，不留存历史）、语音转写文本（设备端系统服务完成）、用户生成内容（口味偏好/收藏/记录，仅本地）。
- AI 增强启用时：口味描述经自营服务器转发 MiniMax，不含身份信息。
- 不收集：联系方式、证件号（会员实名信息仅存在于美团/支付宝侧）、财务信息（支付走支付宝）、健康医疗数据。
- 用途：应用功能；不与广告/营销共享；不出售。

## 商店链接

- 隐私政策：https://eatwhat.monkeykingfury.com/privacy_policy.html
- 账号删除：https://eatwhat.monkeykingfury.com/account_deletion.html
- 支持页面：https://eatwhat.monkeykingfury.com/support.html
