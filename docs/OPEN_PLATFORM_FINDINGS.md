# 开放平台对接调研（仅官方公开文档）

> 目标：为 EatWhat V2 的“到店/外卖（模块3）”提供**合规**的开放平台对接依据。
>
> 重要声明：
> - 本文只基于**官方公开文档/页面**整理，不包含逆向抓包、私有接口挖掘、绕过登录等行为。
> - 是否能实现“用户侧下单”取决于平台是否向你开放相应能力（很多开放平台能力偏 **商家/ISV 侧**：门店、菜品、订单同步/履约，而非消费者 App 直接下单）。

---

## 1. 美团外卖通用解决方案 — 已确认的消费者点餐 OpenAPI

官方入口：`https://open.waimai.meituan.com/program/general`

官方文档已明确提供以下消费者点餐接口：

- `POST https://openapi.waimai.meituan.com/openapi/v1/poilist`：按用户定位和关键词获取真实商家
- `POST https://openapi.waimai.meituan.com/openapi/v1/poi/food`：获取商家菜品、SPU、SKU、规格、价格和库存
- `POST https://openapi.waimai.meituan.com/openapi/v1/order/preview`：订单预览，返回价格、配送费、优惠和订单 token
- `POST https://openapi.waimai.meituan.com/openapi/v1/order/submit`：提交订单，返回订单号和美团收银台 `payUrl`
- 另有订单列表、订单详情、取消订单、地址列表等接口

这套能力与商家接单 API、联盟推广 API 是三套不同业务。EatWhat 应申请这里的消费者 OAuth 与下单权限。

### 1.1 签名算法（MD5, 参数名 `sign`）

来源（官方文档）：`https://developer.meituan.com/docs/biz/biz_wmh5api_4bd84411-fbc1-4668-b1e6-8c5cf255b1f4`

- 仅支持 `GET` / `POST`
- `POST` 只支持 `content-type: application/x-www-form-urlencoded`
- 计算方式（摘要）：
  1) 取所有认证参数与业务参数（除 `sign`），按参数名排序后用 `&` 连接：`k1=v1&k2=v2...`
  2) 拼接：`url + "?" + sortedQuery + consumer_secret`
  3) 对拼接字符串做 `MD5` → 得到 `sign`（小写）
  4) 将 `sign` 作为请求参数传入

### 1.2 协议与 OAuth

OAuth 文档：`https://developer.meituan.com/docs/biz/biz_wmh5api_da85b8ae-b59b-4c72-815a-af7048706db0`

- POST 业务参数使用 `application/x-www-form-urlencoded` 请求体
- 认证参数 `app_id`、`timestamp`、`access_token` 或 `open_id`、`sign` 放在 URL 查询参数
- OAuth 使用 authorization_code 模式，AppSecret、access_token、refresh_token 必须存放在 EatWhat 服务端
- 未审核应用只能使用官方指定测试坐标和测试商家；真实门店和订单必须通过平台审核

### 1.3 支付边界

EatWhat 可以通过已获批接口创建订单，但不能自己代收美团外卖订单款。`order/submit` 返回 `payUrl` 后，应跳到美团收银台支付，并附加 `pay_success_url` 和 `redr_url` 作为成功/失败回跳地址。

---

## 2. 美团技术服务合作中心（Tech Portal）— 签名规则（SHA1, 参数名 `sign`）

来源（官方文档）：`https://developer.meituan.com/docs/biz/comm-dev-isv-sign-rule`

- 使用 `SHA1` 计算 `sign`
- 计算方式（摘要）：
  1) 将请求参数中除 `sign` 外的键值对按 key 字典序排序
  2) 按 `key1value1key2value2...` 拼接（不含 `=` 与 `&`）
  3) 将 `signKey` 拼在最前面：`signKey + sortedKeyValueString`
  4) 做 `SHA1` 得到 `sign`（小写）
- 文档中示例 host 包含：`api-open-cater.meituan.com`（偏餐饮/到店业务接口体系）

---

## 3. 饿了么（open.faas.ele.me）页面加载问题说明

- 我尝试通过 Playwright 打开 `https://open.faas.ele.me/docs`，页面依赖 `github.elemecdn.com` 的 Vue 资源，在当前网络环境下多次出现 `ERR_TIMED_OUT` / `Vue is not defined`，导致页面内容无法正常渲染（截图为空白）。
- 通过抓取可见到导航目录（不含具体接口细节）：包含“API 接入文档/快速接入/标准H5接入文档/支付/消息推送/对账”等栏目。

### 3.1 可用的“公开 API/H5 接入文档”入口（推荐用这个）

饿了么有一套可公开访问的文档站：
- 首页：`https://openapi-doc.faas.ele.me/`
- 用户端 OpenAPI（目录页）：`https://openapi-doc.faas.ele.me/v2/`
- Opensite（APP 内嵌 H5）接入文档：`https://openapi-doc.faas.ele.me/h5v2/`
  - 快速入门：`https://openapi-doc.faas.ele.me/h5v2/quickstart.html`
  - 入口形式（官方写法）：`https://h5.ele.me/?opensite_source={source}`（`source` 由饿了么提供）
  - 可选：前置登录（带 `jwt`）

联系方式（文档首页可见）：
- 用户端：`openapi.coop@ele.me`
- 商户端：`openapi.merchant@ele.me`

---

## 4. 对“用户点单链路”的现实约束

EatWhat 已明确选择消费者侧点餐模式。技术路线是：

1. 用户授权美团账号。
2. EatWhat 服务端按定位和菜名查真实门店。
3. 获取门店菜品与 SKU，用户确认购物车和地址。
4. 调用订单预览，取得价格和订单 token。
5. 提交订单，取得订单号和 `payUrl`。
6. 打开美团收银台；美团负责支付、配送和履约。

平台审核通过前只能调用官方测试商家，不能把商家接单 API 或联盟链接当成这条消费者下单链路。

---

## 5. 工程落地建议（安全与合规）

- 不把 `appSecret/consumer_secret` 放到 Flutter 客户端；统一走自建后端签名转发（或使用平台提供的安全 SDK/网关）。
- 客户端仅传：`dishName + location + filters` 和 EatWhat 登录态到后端；美团 OAuth token 由后端按当前用户读取。后端负责：
  - 签名、鉴权、限流、重试
  - 响应裁剪与缓存
  - 统一错误码与风控日志

---

## 6. EatWhat V2 当前已完成的“执行骨架”

代码已接入（可从菜品详情页触发）：
- V2 执行 Sheet（三路径 UI）：`lib/v2/features/execution/execution_sheet.dart`
- Provider/签名/Client 骨架：`lib/v2/core/external/platform/`
- 定位服务（权限/兜底）：`lib/v2/core/services/v2_location_service.dart`
