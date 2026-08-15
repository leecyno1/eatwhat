# 预制菜图库批处理

这个批处理用于把 `unified_recipes.db` 里的高频菜导出成预制菜图计划，或者直接调用 MiniMax 生图并产出 `dish_image_manifest.json`。

## 当前状态

- App 端已经优先读取预制图库 manifest，不再默认现场生图。
- 当前仓库里的 `unified_recipes.db` 只有 43 道菜。
- 因此脚本已经支持 300 到 500 道批量目标，但前提是后续先把统一菜谱库扩充到对应规模。

## 输入

- 数据库：`unified_recipes.db`
- 环境变量：
  - `MINIMAX_API_KEY`
  - `MINIMAX_API_URL`
  - `MINIMAX_IMAGE_MODEL`
  - `PREBUILT_IMAGE_BASE_URL`

## 输出

- `tmp/prebuilt_dish_catalog/jobs/prompts.jsonl`
- `tmp/prebuilt_dish_catalog/dish_image_manifest.json`
- `tmp/prebuilt_dish_catalog/review.md`
- `tmp/prebuilt_dish_catalog/report.json`
- 执行在线生图时还会生成：
  - `tmp/prebuilt_dish_catalog/images_raw/`
  - `tmp/prebuilt_dish_catalog/images/`

## 用法

只生成批处理计划，不调生图：

```bash
python3 scripts/build_prebuilt_dish_catalog.py --limit 180
```

直接调用 MiniMax 生成并下载图片：

```bash
python3 scripts/build_prebuilt_dish_catalog.py --limit 120 --execute
```

## 产物约定

- 生成 prompt 默认是 `4:3` 真实食物摄影。
- 下载原图后会尝试产出两档：
  - `*_1280.jpg`
  - `*_768.jpg`
- manifest 键优先使用 `dishId`，别名包含 `canonical_name` 与 `name_cn`。
- 脚本会先按标准化菜名去重，避免 `可乐鸡翅` 这类重复记录重复生图，同时自动合并别名。
- 如果设置了 `PREBUILT_IMAGE_BASE_URL`，manifest 会直接输出可公开访问的 URL。
- 如果未设置 `PREBUILT_IMAGE_BASE_URL`，manifest 会输出相对路径，方便你先本地验收再同步到对象存储。
- App 端现在支持“manifest 里先保留相对路径，后续只通过 `.env` 配置 `PREBUILT_IMAGE_BASE_URL` 动态补全”，不需要重新生成 manifest。

## 建议批次

- 批次 A：先跑 `--limit 120`，覆盖最常见结果页菜品。
- 批次 B：统一菜谱库扩容后跑到 `300-500`。

## 对象存储策略

脚本本身不绑定具体云厂商。

- 你可以把 `tmp/prebuilt_dish_catalog/images/` 同步到任意 S3 兼容对象存储、R2、COS、OSS 或 CDN 源站。
- 只要把公开前缀写进 `PREBUILT_IMAGE_BASE_URL`，manifest 就会输出稳定 URL。
