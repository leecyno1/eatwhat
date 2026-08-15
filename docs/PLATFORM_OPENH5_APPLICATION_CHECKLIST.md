# 平台消费者点餐 API / H5 申请清单（美团外卖 + 饿了么）

> 目标：让用户在你的 App 内“内嵌打开平台承载页”，并**直达商品/结算页完成支付**，支付完成后**回跳你的 App**。
>
> 重要提示：如果你要“直达商品/结算”，通常需要平台给你开通白名单/更深层能力；仅有 openH5/Opensite 基础能力往往只能做到搜索/店铺页。

## 1. 你这边需要准备的固定信息（可直接填表）

### 1.1 App 标识
- iOS Bundle ID：`com.eatwhat.eatwhatApp`
- Android Application ID：`com.eatwhat.eatwhat_app`

### 1.2 基础材料
- 个体工商户营业执照（统一社会信用代码）
- 经营者身份证（平台要求时）
- 联系人手机/邮箱（建议单独准备“对接人邮箱”）
- App 介绍（1 段话）
- App 截图（建议 5 张）：
  - 首页气泡偏好
  - 老虎机/决策页
  - 推荐结果页
  - 菜品详情页
  - 执行页（自制/到店/外卖）

### 1.3 合规链接（平台基本都会要）
- 隐私政策 URL：`https://<你的域名>/privacy`
- 用户协议 URL：`https://<你的域名>/terms`

> 没有域名也可以先用最简静态站（后续再换），但“回跳白名单”通常要求 HTTPS 可访问域名。

## 2. 回跳（redirect）方案：建议这样定（最省坑）

### 2.1 优先用 Universal Links（iOS）/ App Links（Android）
- 回跳域名：`https://<你的域名>`
- 回跳路径建议统一：
  - `https://<你的域名>/open/callback/eleme`
  - `https://<你的域名>/open/callback/meituan`
- 你 App 侧只负责接收 deep link，并展示：
  - 订单结果页（成功/取消/失败）
  - 收藏/复盘入口

### 2.2 备选：URL Scheme（开发快，但稳定性不如 Universal Link）
- iOS Scheme：`eatwhat://open/callback/eleme` / `eatwhat://open/callback/meituan`
- Android Scheme：同上

## 3. 饿了么（Opensite / Open H5）申请步骤（操作路径）

### 3.1 入口
- 饿了么开放平台（EOP）：`https://open.faas.ele.me`

### 3.2 控制台操作（你要做什么）
1) 注册/登录 → 完成主体认证（个体户）  
2) 创建应用  
3) 申请能力（关键词照抄）：
   - `Open H5 / Opensite`
   - `商品直达/预填购物车/直达结算（白名单）`
   - `redirect_url 回跳白名单（HTTPS 域名）`
   - `订单状态回传/查询（可选）`

### 3.3 你希望平台最终发给你的“关键凭证/参数”
- `opensite_source`（文档明确：`source 饿了么提供`）
- `client_id` / `client_secret`
- `authorize_url`（用于授权/换 token）
- 测试环境与联调支持（有些能力需要平台侧排期）

### 3.4 你在申请说明里要写的“关键诉求”（复制粘贴）
> 我们是用户侧 App（非商家系统），希望通过饿了么 Open H5 / Opensite 在 App 内嵌完成外卖下单与支付闭环。  
> 用户在 App 中先选择偏好并生成目标菜品，然后点击“外卖”直接跳转到饿了么**指定门店/指定商品（SKU）**的购买流程，并**直达结算页**完成支付；支付完成后通过 `redirect_url` 回跳 App。  
> 如菜名无法唯一定位 SKU，希望开通/提供“门店/商品搜索”能力（按定位与关键词），由我方先定位 `shopId/skuId` 再生成直达结算链接。

### 3.5 你可以提前熟悉的公开文档（术语对齐）
- Eleme Open H5（quickstart/account/payment）：`https://openapi-doc.faas.ele.me/h5v2/`
- quickstart 里给出了 opensite 入口形态：
  - `https://h5.ele.me/?opensite_source={source}`
  - `https://h5.ele.me/?opensite_source={source}&jwt={jwt}`

## 4. 美团外卖（openH5）申请步骤（操作路径）

### 4.1 入口
- 外卖通用解决方案（含 openH5/SDK/OpenAPI；EatWhat 不申请 CPS）：`https://open.waimai.meituan.com/program/general`

### 4.2 控制台操作（你要做什么）
1) 注册/登录美团开放平台账号 → 完成主体认证（个体户）  
2) 选择“外卖通用解决方案” → 创建网站应用并申请消费者 OpenAPI  
3) 申请能力（关键词照抄）：
   - `外卖通用解决方案 OpenAPI`
   - `消费者 OAuth2 授权`
   - `商家列表 /openapi/v1/poilist`
   - `商家菜品 /openapi/v1/poi/food`
   - `订单预览 /openapi/v1/order/preview`
   - `提交订单 /openapi/v1/order/submit`
   - `订单列表、订单详情、取消订单`
   - `支付成功/失败回跳域名白名单`

### 4.3 你在申请说明里要写的“关键诉求”（复制粘贴）
> 我们是消费者侧菜品推荐 App，不是商家 ERP，也不申请联盟推广能力。  
> 用户先在 EatWhat 生成目标菜品，我方通过美团外卖通用解决方案 OpenAPI 按定位查询真实门店与菜品 SKU，在用户确认购物车和收货地址后调用订单预览、提交订单接口。  
> 订单创建后打开美团返回的 payUrl，由美团完成支付、配送和订单履约；支付成功或失败后回跳 EatWhat。希望开通 OAuth2、商家列表、商家菜品、订单预览、提交订单、订单查询/取消及支付回跳白名单。

## 5. 你拿到能力后，我们落地要做的 3 件事（开发任务）

1) 做一个你自己的轻量后端（必须）：负责 OAuth 换 token、签名、门店/菜品查询、订单预览和提交（客户端不放 secret/token）。
2) App 端：点“外卖”后在 EatWhat 选门店与 SKU；提交订单成功后打开美团返回的 `payUrl`。
3) 回跳闭环：处理 deep link，展示订单结果，并把订单/菜品写入收藏与历史。
