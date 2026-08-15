# 执行层代理接口

## 目标
客户端不直接调用美团/点评/饿了么开放平台，也不在本地做签名。  
统一由代理后端承接平台凭据、鉴权、签名和字段解析，Flutter 端只消费业务语义化结果。

当前客户端已接入四条统一链路：

- `POST /v2/execution/meituan/delivery-match`
- `POST /v2/execution/eleme/delivery-match`
- `POST /v2/execution/jd-delivery/delivery-match`
- `POST /v2/execution/dianping/delivery-match`

美团真实点餐链路另外提供：

- `POST /api/v1/delivery/merchants/search`
- `POST /api/v1/delivery/products/search`
- `POST /api/v1/delivery/order-previews`
- `POST /api/v1/delivery/orders`

平台密钥、签名、用户授权和交易权限全部留在代理后端。客户端只接收候选与官方承载链接。

生产链路分两层：

1. `eatwhat_auth_server.dart`：吃什么账号服务，负责注册、登录、会话校验和签发用户 JWT。
2. `execution_proxy_server.dart`：统一网关，验证吃什么 JWT，从 `sub` 取得可信用户 ID。
3. 平台适配器：分别负责美团、饿了么、京东、大众点评的官方签名、授权和字段转换。

Flutter 只登录“吃什么”。美团 OAuth 是首次交易时的一次授权，凭证由服务端按吃什么用户保存；它不是再次注册吃什么账号。

吃什么账号接口：

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/session`

适配器必须返回本文定义的统一响应，不能把平台原始响应直接暴露给客户端。

## 请求

### Path

```text
/v2/execution/meituan/delivery-match
```

### Headers

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <EXECUTION_PROXY_AUTH_TOKEN>  # 可选
X-Execution-Proxy-Token: <网关服务令牌>               # 配置固定服务令牌时使用
X-Request-Id: <request-id>                           # 可选，网关会自动补齐
```

### Body

```json
{
  "dishName": "番茄肥牛锅",
  "recipeId": "r1",
  "pairings": [
    {
      "category": "饮品",
      "title": "酸梅汤",
      "subtitle": "解腻"
    }
  ],
  "sourceTags": ["辣", "火锅", "夜宵"],
  "geo": {
    "latitude": 39.9042,
    "longitude": 116.4074
  },
  "limit": 10
}
```

## 响应

### 成功

```json
{
  "status": "available",
  "providerState": {
    "platform": "meituan",
    "displayName": "美团外卖",
    "reason": null,
    "supportsDishSearch": true,
    "supportsOrderPreview": true,
    "supportsOrderSubmit": true
  },
  "matches": [
    {
      "merchantId": "mt_hotpot_001",
      "merchantName": "锅气食堂",
      "dishName": "番茄肥牛锅",
      "appUrl": "meituan://...",
      "productId": "sku_hotpot_001",
      "price": 46,
      "deliveryTimeMinutes": 28,
      "supportsPrefillCart": false,
      "note": "命中辣 / 火锅 / 夜宵，并带上酸梅汤这类搭配建议。",
      "source": "proxy",
      "linkTarget": "app"
    }
  ]
}
```

### 失败

```json
{
  "status": "unavailable",
  "reason": "美团代理未返回可用商品检索结果",
  "matches": []
}
```

HTTP 状态码：

- `400`：JSON 格式错误
- `401`：客户端鉴权失败
- `404`：代理路由不存在
- `422`：菜名、定位或数量不合法
- `502`：平台适配器调用失败
- `503`：平台适配器尚未配置

错误响应包含 `requestId`，用于定位一次完整调用。

## 字段约定

- `status`
  - `available`：返回了可展示候选
  - `partial`：代理本身可用，但本轮没有命中候选
  - `unavailable`：代理未配置、平台未开通、鉴权失败或接口不可用
- `jumpUrl`
  - 兼容旧代理响应
- `appUrl` / `webUrl`
  - 客户端优先唤起 `appUrl`，失败后打开 `webUrl`
- `productId`
  - 商品标识；即使当前页面只外跳，也必须返回，方便后续接预填购物车
- `supportsPrefillCart`
  - 这里只表示当前候选链接是否已经带好购物车，不表示平台是否具备下单 API
  - 美团真实下单使用独立的“订单预览 → 提交订单 → 打开 paymentUrl”链路
- `source`
  - 当前建议固定返回 `proxy`、`platform` 或 `fallback`
- `linkTarget`
  - `web` / `app` / `none`

## 本地联调

仓库已提供本地 mock 代理：

```bash
dart run scripts/mock_execution_proxy_server.dart
```

默认监听：

```text
http://127.0.0.1:8787
```

健康检查：

```bash
curl http://127.0.0.1:8787/health
```

`.env` 示例：

```env
EXECUTION_PROXY_BASE_URL=http://127.0.0.1:8787
EXECUTION_PROXY_HEALTH_PATH=/health
MEITUAN_DELIVERY_MATCH_PATH=/v2/execution/meituan/delivery-match
MEITUAN_MERCHANT_SEARCH_PATH=/api/v1/delivery/merchants/search
MEITUAN_PRODUCT_SEARCH_PATH=/api/v1/delivery/products/search
MEITUAN_ORDER_PREVIEW_PATH=/api/v1/delivery/order-previews
MEITUAN_ORDER_SUBMIT_PATH=/api/v1/delivery/orders
ELEME_DELIVERY_MATCH_PATH=/v2/execution/eleme/delivery-match
JD_DELIVERY_MATCH_PATH=/v2/execution/jd-delivery/delivery-match
DIANPING_DELIVERY_MATCH_PATH=/v2/execution/dianping/delivery-match
```

## 生产代理启动

```bash
export EXECUTION_PROXY_BIND_ADDRESS=0.0.0.0
export EXECUTION_PROXY_PORT=8787
export EXECUTION_PROXY_REQUIRED_TOKEN=<由登录系统签发或网关校验的令牌>
export EXECUTION_PROXY_JWT_SECRET=<与吃什么登录系统签发 JWT 相同的服务端密钥>
export MEITUAN_EXECUTION_ADAPTER_URL=https://<adapter-host>/meituan/delivery-match
export MEITUAN_MERCHANT_SEARCH_ADAPTER_URL=https://<adapter-host>/merchants/search
export MEITUAN_PRODUCT_SEARCH_ADAPTER_URL=https://<adapter-host>/products/search
export MEITUAN_ORDER_PREVIEW_ADAPTER_URL=https://<adapter-host>/order-previews
export MEITUAN_ORDER_SUBMIT_ADAPTER_URL=https://<adapter-host>/orders
export ELEME_EXECUTION_ADAPTER_URL=https://<adapter-host>/eleme/delivery-match
export JD_DELIVERY_EXECUTION_ADAPTER_URL=https://<adapter-host>/jd-delivery/delivery-match
export DIANPING_EXECUTION_ADAPTER_URL=https://<adapter-host>/dianping/delivery-match

dart run scripts/execution_proxy_server.dart
```

生产环境由“吃什么”登录系统签发短期用户 JWT。网关验证后从 `sub` 取得用户 ID，转发为可信的 `X-EatWhat-User-Id`，适配器再按这个 ID 读取该用户的美团 OAuth 凭证。客户端不能自行传用户 ID。

### 美团消费者点餐适配器

这不是联盟推广或返佣接口。仓库提供的是美团外卖消费者点餐 OpenAPI 适配器：

```bash
export MEITUAN_OPEN_APP_ID=<美团审核通过的网站应用 AppID>
export MEITUAN_OPEN_APP_SECRET=<AppSecret>
export MEITUAN_OPEN_ACCESS_TOKEN=<本地联调用户 OAuth access_token>
export MEITUAN_OPEN_ORDER_ENABLED=true
export MEITUAN_OPEN_REVIEW_MODE=true
export MEITUAN_OAUTH_REDIRECT_URL=https://<你的域名>/oauth/callback
export MEITUAN_DELIVERY_ADAPTER_REQUIRED_TOKEN=<网关到适配器令牌>

dart run scripts/meituan_delivery_adapter_server.dart
```

网关指向适配器：

```env
MEITUAN_EXECUTION_ADAPTER_URL=http://127.0.0.1:8788/delivery-match
MEITUAN_MERCHANT_SEARCH_ADAPTER_URL=http://127.0.0.1:8788/merchants/search
MEITUAN_PRODUCT_SEARCH_ADAPTER_URL=http://127.0.0.1:8788/products/search
MEITUAN_ORDER_PREVIEW_ADAPTER_URL=http://127.0.0.1:8788/order-previews
MEITUAN_ORDER_SUBMIT_ADAPTER_URL=http://127.0.0.1:8788/orders
MEITUAN_OAUTH_STATUS_ADAPTER_URL=http://127.0.0.1:8788/oauth/status
MEITUAN_OAUTH_AUTHORIZE_ADAPTER_URL=http://127.0.0.1:8788/oauth/authorize
MEITUAN_EXECUTION_ADAPTER_TOKEN=<同上令牌>
```

适配器调用的美团官方接口：

- `POST /openapi/v1/poilist`：按定位和菜名查真实门店
- `POST /openapi/v1/poi/food`：获取门店菜品、SPU、SKU、规格和库存
- `POST /openapi/v1/order/preview`：校验购物车、地址、起送价、配送费并获取订单 token
- `POST /openapi/v1/order/submit`：创建订单并返回美团 `payUrl`

签名按美团外卖通用解决方案规则生成：全部认证参数和业务参数按参数名升序，以 `key=value&...` 拼接，再按 `请求 URL + ? + 参数串 + AppSecret` 计算 MD5。

生产环境不能把同一个 `access_token` 给所有用户共用。用户第一次下单时做一次美团消费者交易授权；之后由 EatWhat 服务端按当前“吃什么”用户保存、读取和刷新 `access_token/refresh_token/open_id`，不需要再次注册“吃什么”或反复登录美团。`.env` 的 token 只用于审核沙箱或单用户联调。

未审核应用启用 `MEITUAN_OPEN_REVIEW_MODE=true` 时，门店和菜品请求自动改用美团官方测试坐标 `95.369826, 29.735952`。真实坐标必须等接口权限审核通过后再启用。

下单响应中的 `paymentUrl` 必须打开美团收银台。EatWhat 不自己收取这笔外卖款；支付成功或失败后，美团按 `pay_success_url` / `redr_url` 回跳 EatWhat。

### 美团订单请求

订单预览与提交使用同一份购物车和收货信息。提交时额外传预览返回的 `previewToken`：

```json
{
  "merchantId": "171899",
  "items": [
    {
      "skuId": "441067569",
      "count": 1,
      "attributeIds": [23]
    }
  ],
  "recipient": {
    "name": "张三",
    "phone": "13800000000",
    "address": "北京市朝阳区示例地址",
    "currentLatitude": 40.007069,
    "currentLongitude": 116.488645,
    "addressLatitude": 40.007069,
    "addressLongitude": 116.488645,
    "note": "少放辣"
  },
  "previewToken": "ORDER_PREVIEW_TOKEN",
  "paymentSuccessUrl": "https://example.com/open/callback/meituan/success",
  "paymentFailureUrl": "https://example.com/open/callback/meituan/failure"
}
```

成功提交订单后返回：

```json
{
  "status": "payment_required",
  "orderId": "6015602307419773",
  "paymentUrl": "https://...美团收银台...",
  "requiresVerification": false
}
```

适配器配置状态可通过以下接口检查，响应只返回布尔状态，不返回 URL 或密钥：

```http
GET /health
```

```json
{
  "status": "ok",
  "providers": {
    "meituan": true,
    "eleme": false,
    "jd_delivery": false,
    "dianping": true,
    "dianping_dine_in": true
  }
}
```

## 平台适配器职责

- 美团：根据已获批业务线完成 `sig/sign`、门店商品匹配与官方承载链接生成。
- 饿了么：根据 `opensite_source`、JWT 或已获批 OpenAPI 生成官方 H5/结算链接。
- 京东外卖：通过 `open.jd.com` 获批应用完成秒送商品匹配与官方承载链接生成。
- 大众点评：按获批能力完成到店/外卖匹配，并返回点评 App/H5 链接。
- 无商品直达权限时，返回搜索链接并设置 `supportsPrefillCart=false`。

## 客户端当前行为

- 进入执行页时先读取 `/health`，只请求服务端标记为已配置的平台适配器
- 平台健康状态为 `false`：页面显示“生产适配器未配置”，并使用官方搜索入口兜底
- 健康检查暂时失败：不中断下单流程，继续尝试具体平台路由
- `supportsPrefillCart=true`：按钮显示 `去平台下单`
- `supportsPrefillCart=false`：按钮显示 `去平台搜索`
- `jumpUrl` 为空：按钮显示 `能力未开通`
- 代理请求失败：执行页展示 `执行路径暂时不可用`

## 资质边界

- 美团、饿了么、大众点评的消费者下单能力需要对应业务线授权，不能用商家订单接口冒充消费者下单。
- 京东外卖/秒送新增接入从 `https://open.jd.com` 申请。JOS 已公告于 2026 年迁移并关闭旧入口，新增应用要求企业账号与对应资质。
- 没有交易权限时，代理必须返回官方 App/H5 搜索或结算承载链接，不能在客户端模拟创建订单。
