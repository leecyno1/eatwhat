# MiniMax 官方接入配置

本项目已按 MiniMax 官方文档切到两条能力：

- 文本推理：OpenAI 兼容接口
- 图片生成：官方 `image_generation` 接口

## 官方接口

- 文本接口基地址：`https://api.minimaxi.com/v1`
- 文本接口路径：`POST /chat/completions`
- 官方模型：`MiniMax-M2.7`
- 图片接口基地址：`https://api.minimaxi.com/v1/image_generation`
- 官方图片模型：`image-01`

## 当前项目映射

- `SILICONFLOW_API_URL` 实际映射为 MiniMax 文本 OpenAI 兼容地址
- `AI_MODEL_NAME=MiniMax-M2.7`
- `MINIMAX_API_URL=https://api.minimaxi.com/v1/image_generation`
- `MINIMAX_IMAGE_MODEL=image-01`

## 当前参数

- `AI_TEMPERATURE=1.0`
- `AI_TOP_P=0.95`
- `AI_MAX_TOKENS=4096`
- `AI_REQUEST_TIMEOUT=60`
- 图片默认：
  - `aspect_ratio=4:3`
  - `response_format=base64`

## 项目内兼容处理

- [generation_service.dart](/Volumes/PSSD/Projects/eatwhat/lib/v2/core/services/generation_service.dart)
  现在会在 MiniMax 文本基地址下自动识别图片官方接口，不再错误调用 `images/generations`。
- [result_page.dart](/Volumes/PSSD/Projects/eatwhat/lib/v2/features/result/result_page.dart)
  现在可直接显示 MiniMax 返回的 `data:image/...;base64,...`。
- [build_prebuilt_dish_catalog.py](/Volumes/PSSD/Projects/eatwhat/scripts/build_prebuilt_dish_catalog.py)
  现在按官方图片接口请求 `response_format=base64`，并可直接落盘。

## 官方文档

- [MiniMax OpenAI Compatible Text API](https://platform.minimaxi.com/docs/api-reference/text-openai-api)
- [MiniMax Image Generation Guide](https://platform.minimaxi.com/docs/guides/image-generation)

## 注意

当前 `.env` 中保存的是开发态直连配置，只适合本地开发和内部测试。

- 当前项目这把 `sk-cp-...` key 已经实测可调用 `POST /v1/image_generation`，文本与图片都能返回有效结果。
- 如果出现 `status_code=1004` / `Authorization` / `secret key` 相关报错，优先检查是否用了旧环境变量覆盖了项目 `.env`。
- 如果出现 `status_code=1033` 这类 `system error`，更可能是服务端瞬时波动，建议直接重试。
- 如果你要上架 iOS App，不应把正式 API Key 放在 Flutter 客户端。
- 生产环境应改成后端代理或临时凭证方案。
