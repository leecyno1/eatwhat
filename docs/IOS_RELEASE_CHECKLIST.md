# iOS 上线清单（App Store）

## 合规与权限
- 隐私：App Privacy（数据收集/用途），符合中国区要求；
- 权限文案：`NSLocationWhenInUseUsageDescription`、相册/相机（如需）、网络；
- ATS：外链使用 HTTPS；必要时配置例外并说明；
- 交易合规：外卖/餐馆为实物交易，允许外链（使用 `SFSafariViewController` 或跳转 Safari）。

## 项目设置
- 包标识与签名，版本与构建号；
- App Icon 与启动页（`flutter_native_splash`）；
- Deep Link/URL Scheme（可选：美团/饿了么，含回退 H5）。
  - `ios/Runner/Info.plist` 增加查询白名单（示例）：
    ```xml
    <key>LSApplicationQueriesSchemes</key>
    <array>
      <string>imeituan</string>
      <string>dianping</string>
      <string>xiachufang</string>
      <string>xhsdiscover</string>
    </array>
    ```

## 质量保障
- `flutter analyze`、`dart format`、`flutter test` 通过；
- 关键路径性能：启动 < 2.0s，候选生成 < 200ms；
- Sentry 崩溃率 < 1%。

## 测试与发布
- TestFlight 内测：功能用例、权限、弱网、定位；
- 审核材料：截图、描述、关键字、演示视频（可选）；
- 提交审核与应答模板（外链解释、定位用途说明）。
