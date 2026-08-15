#!/usr/bin/env python3
"""Build prebuilt dish image prompts, assets, and manifest from unified_recipes.db.

Default mode only exports a batch plan:
- prompts JSONL
- upload-ready manifest skeleton
- report JSON

Use `--execute` to call MiniMax image generation and download images locally.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from http.client import IncompleteRead
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.error import URLError


DEFAULT_DB_PATH = 'unified_recipes.db'
DEFAULT_OUTPUT_DIR = 'tmp/prebuilt_dish_catalog'
DEFAULT_LIMIT = 180
DEFAULT_MINIMAX_URL = 'https://api.minimaxi.com/v1/image_generation'
DEFAULT_MINIMAX_MODEL = 'image-01'
GENERIC_INGREDIENT_TOKENS = {
    '主料',
    '辅料',
    '调料',
    '配料',
    '配菜',
    '食材',
    '调味料',
    '材料',
    '适量',
    '少许',
}
SAUCE_LIKE_TOKENS = {
    '生抽',
    '老抽',
    '蚝油',
    '料酒',
    '白糖',
    '冰糖',
    '糖',
    '盐',
    '鸡精',
    '味精',
    '淀粉',
    '酱油',
    '醋',
    '胡椒',
    '花椒',
    '干辣椒',
}
NAME_INGREDIENT_HINTS = [
    ('红烧肉', '五花肉'),
    ('回锅肉', '五花肉'),
    ('里脊', '里脊肉'),
    ('鸡翅', '鸡翅'),
    ('鸡丁', '鸡腿肉'),
    ('鸡', '鸡肉'),
    ('牛肉', '牛肉'),
    ('肥牛', '肥牛'),
    ('猪肉', '猪肉'),
    ('肉丝', '猪里脊'),
    ('肉末', '猪肉末'),
    ('排骨', '排骨'),
    ('五花肉', '五花肉'),
    ('豆腐', '豆腐'),
    ('土豆', '土豆'),
    ('茄子', '茄子'),
    ('花菜', '花菜'),
    ('鱼', '鱼片'),
    ('虾', '虾仁'),
    ('鸡蛋', '鸡蛋'),
    ('番茄', '番茄'),
    ('沙拉', '生菜'),
]


@dataclass(frozen=True)
class DishRecord:
    dish_id: str
    dish_name: str
    canonical_name: str
    cuisine: str
    main_ingredients: list[str]
    taste_profile: list[str]
    scenes: list[str]
    popularity_score: float
    rating_count: int
    source_count: int
    slug: str
    aliases: list[str]
    dedupe_key: str


class StorageTarget:
    def __init__(self, base_url: str) -> None:
        self.base_url = base_url.rstrip('/')

    def public_url(self, relative_path: str) -> str:
        normalized = relative_path.replace('\\', '/').lstrip('/')
        if not self.base_url:
            return normalized
        return f'{self.base_url}/{normalized}'


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for raw in path.read_text(encoding='utf-8').splitlines():
        line = raw.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        key, value = line.split('=', 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        # Prefer repo-local .env over inherited shell variables so live batch
        # generation uses the project's currently configured provider credentials.
        os.environ[key] = value


def parse_jsonish_list(raw: Any) -> list[str]:
    if raw is None:
        return []
    text = str(raw).strip()
    if not text or text == '{}':
        return []
    try:
        decoded = json.loads(text)
    except json.JSONDecodeError:
        return [part.strip() for part in text.split('、') if part.strip()]

    if isinstance(decoded, list):
        return [str(item).strip() for item in decoded if str(item).strip()]
    if isinstance(decoded, dict):
        values: list[str] = []
        for key, value in decoded.items():
            if isinstance(value, bool):
                if value:
                    values.append(str(key).strip())
                continue
            if value:
                values.append(f'{key}:{value}')
        return [value for value in values if value]
    return [text]


def clean_ingredients(values: list[str]) -> list[str]:
    cleaned: list[str] = []
    for value in values:
        text = value.strip()
        if not text:
            continue
        compact = text.replace(' ', '')
        if compact in GENERIC_INGREDIENT_TOKENS:
            continue
        if compact.endswith('适量') and len(compact) <= 6:
            continue
        cleaned.append(text)

    seen: set[str] = set()
    ordered: list[str] = []
    for item in cleaned:
        key = normalize_name(item)
        if not key or key in seen:
            continue
        seen.add(key)
        ordered.append(item)
    return ordered


def enrich_ingredients_from_name(name: str, ingredients: list[str]) -> list[str]:
    material_like = [item for item in ingredients if item not in SAUCE_LIKE_TOKENS]
    if material_like:
        return ingredients

    hints = [hint for keyword, hint in NAME_INGREDIENT_HINTS if keyword in name]
    merged = [*hints[:2], *ingredients]
    seen: set[str] = set()
    ordered: list[str] = []
    for item in merged:
        key = normalize_name(item)
        if not key or key in seen:
            continue
        seen.add(key)
        ordered.append(item)
    return ordered


def slugify(text: str) -> str:
    safe = []
    for char in text.lower().strip():
        if char.isascii() and (char.isalnum() or char in {'-', '_'}):
            safe.append(char)
        elif char.isspace() or char in {'/', '\\', '·', '•', '，', ',', '。'}:
            safe.append('-')
    slug = ''.join(safe).strip('-_')
    while '--' in slug:
        slug = slug.replace('--', '-')
    return slug or 'dish'


def normalize_name(text: str) -> str:
    normalized = []
    for char in text.strip().lower():
        if char.isalnum() or '\u4e00' <= char <= '\u9fff':
            normalized.append(char)
    return ''.join(normalized)


def is_placeholder_dish(name: str) -> bool:
    compact = name.strip().lower()
    return '示例菜谱' in compact or compact.startswith(('soup_', 'dessert_', 'drink_', 'condiment_', 'semi-finished_'))


def fetch_dishes(
    db_path: Path,
    limit: int,
    include_ids: set[str] | None = None,
    exclude_sample: bool = False,
) -> list[DishRecord]:
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    try:
        rows = conn.execute(
            """
            SELECT
              id,
              name_cn,
              canonical_name,
              cuisine,
              main_ingredients,
              taste_profile,
              scenes,
              COALESCE(popularity_score, 0) AS popularity_score,
              COALESCE(rating_count, 0) AS rating_count,
              COALESCE(source_count, 0) AS source_count
            FROM dish
            ORDER BY
              COALESCE(popularity_score, 0) DESC,
              COALESCE(source_count, 0) DESC,
              COALESCE(rating_count, 0) DESC,
              id ASC
            """,
        ).fetchall()
    finally:
        conn.close()

    deduped: dict[str, DishRecord] = {}
    for row in rows:
        row_id = str(row['id'])
        if include_ids is not None and row_id not in include_ids:
            continue
        canonical_name = (row['canonical_name'] or row['name_cn'] or '').strip()
        name_cn = (row['name_cn'] or canonical_name).strip()
        if exclude_sample and is_placeholder_dish(name_cn or canonical_name):
            continue
        aliases = [alias for alias in {canonical_name, name_cn} if alias]
        slug = f"dish-{row['id']}-{slugify(canonical_name or name_cn)}"
        dedupe_key = normalize_name(canonical_name or name_cn)
        candidate = DishRecord(
            dish_id=row_id,
            dish_name=name_cn,
            canonical_name=canonical_name or name_cn,
            cuisine=(row['cuisine'] or '').strip(),
            main_ingredients=enrich_ingredients_from_name(
                name_cn,
                clean_ingredients(parse_jsonish_list(row['main_ingredients'])),
            ),
            taste_profile=parse_jsonish_list(row['taste_profile']),
            scenes=parse_jsonish_list(row['scenes']),
            popularity_score=float(row['popularity_score'] or 0),
            rating_count=int(row['rating_count'] or 0),
            source_count=int(row['source_count'] or 0),
            slug=slug,
            aliases=aliases,
            dedupe_key=dedupe_key,
        )
        existing = deduped.get(dedupe_key)
        if existing is None:
            deduped[dedupe_key] = candidate
            continue

        merged_aliases = sorted({*existing.aliases, *candidate.aliases})
        better = candidate if (
            candidate.popularity_score,
            candidate.source_count,
            candidate.rating_count,
        ) > (
            existing.popularity_score,
            existing.source_count,
            existing.rating_count,
        ) else existing
        deduped[dedupe_key] = DishRecord(
            dish_id=better.dish_id,
            dish_name=better.dish_name,
            canonical_name=better.canonical_name,
            cuisine=better.cuisine or existing.cuisine,
            main_ingredients=better.main_ingredients or existing.main_ingredients,
            taste_profile=better.taste_profile or existing.taste_profile,
            scenes=better.scenes or existing.scenes,
            popularity_score=better.popularity_score,
            rating_count=better.rating_count,
            source_count=max(existing.source_count, candidate.source_count),
            slug=better.slug,
            aliases=merged_aliases,
            dedupe_key=dedupe_key,
        )
    return list(deduped.values())[:limit]


def count_raw_dishes(db_path: Path) -> int:
    conn = sqlite3.connect(str(db_path))
    try:
        row = conn.execute('SELECT COUNT(*) FROM dish').fetchone()
        return int(row[0]) if row else 0
    finally:
        conn.close()


def style_tag_for(record: DishRecord) -> str:
    name = record.dish_name
    if any(keyword in name for keyword in ['红烧', '黄焖', '卤', '酱']):
        return 'braised_home_style'
    if any(keyword in name for keyword in ['水煮', '麻辣', '香辣', '辣子', '麻婆']):
        return 'spicy_sichuan'
    if any(keyword in name for keyword in ['汤', '锅', '煲']):
        return 'stew_hotpot'
    if any(keyword in name for keyword in ['沙拉', '凉拌']):
        return 'fresh_cold_plate'
    if any(keyword in name for keyword in ['煎', '炸', '排骨', '鸡翅']):
        return 'golden_crisp'
    if any(keyword in name for keyword in ['清蒸', '白灼']):
        return 'light_clean_plate'
    tags = [record.cuisine, *record.taste_profile[:2], *record.scenes[:1]]
    compact = [slugify(tag) for tag in tags if tag]
    return '_'.join(compact[:3]) or 'dish_photo'


def build_prompt(record: DishRecord) -> str:
    ingredients = '、'.join(record.main_ingredients[:6]) or '家常食材'
    tastes = '、'.join(record.taste_profile[:4]) or fallback_taste_hint(record)
    scenes = '、'.join(record.scenes[:3]) or '日常就餐'
    cuisine = record.cuisine or '家常菜'
    return (
        f'{record.dish_name}，真实食物摄影，{cuisine}。'
        f'主要食材：{ingredients}。'
        f'口味关键词：{tastes}。'
        f'适用场景：{scenes}。'
        '镜头为 35 度近景摆盘，美食棚拍级布光，热菜保留蒸汽和油润质感，'
        '冷菜保留新鲜水润质感，餐具克制，背景干净，不要人物，不要手，不要文字，不要拼贴。'
    )


def fallback_taste_hint(record: DishRecord) -> str:
    name = record.dish_name
    if any(keyword in name for keyword in ['麻辣', '香辣', '辣子', '麻婆', '水煮']):
        return '麻辣浓香'
    if any(keyword in name for keyword in ['糖醋', '酸汤', '茄汁', '番茄']):
        return '酸甜开胃'
    if any(keyword in name for keyword in ['红烧', '黄焖', '酱', '卤']):
        return '酱香浓郁'
    if any(keyword in name for keyword in ['清蒸', '白灼', '原味', '沙拉']):
        return '清爽鲜润'
    if any(keyword in name for keyword in ['煎', '炸']):
        return '焦香酥脆'
    return '风味平衡'


def build_manifest_entry(
    record: DishRecord,
    storage: StorageTarget,
    hero_relative: str,
    thumb_relative: str,
) -> dict[str, Any]:
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z')
    return {
        'dishId': record.dish_id,
        'dishName': record.dish_name,
        'aliases': record.aliases,
        'heroUrl': storage.public_url(hero_relative),
        'thumbUrl': storage.public_url(thumb_relative),
        'styleTag': style_tag_for(record),
        'updatedAt': now,
    }


def resolve_image_payload(payload: Any) -> dict[str, str | None]:
    url_value: str | None = None
    base64_value: str | None = None

    def pick_first_string(candidate: Any) -> str | None:
        if isinstance(candidate, str) and candidate.strip():
            return candidate.strip()
        if isinstance(candidate, list):
            for item in candidate:
                value = pick_first_string(item)
                if value:
                    return value
        return None

    if isinstance(payload, dict):
        direct_candidates = [
            payload.get('url'),
            payload.get('image_url'),
        ]
        direct_base64 = [
            payload.get('base64'),
            payload.get('image_base64'),
            payload.get('base64_data'),
            payload.get('b64_json'),
        ]
        data = payload.get('data')
        if isinstance(data, dict):
            direct_candidates.extend([
                data.get('url'),
                data.get('image_url'),
            ])
            direct_base64.extend([
                data.get('base64'),
                data.get('image_base64'),
                data.get('base64_data'),
                data.get('b64_json'),
            ])
            images = data.get('images') or data.get('image_urls')
            if isinstance(images, list) and images:
                first = images[0]
                if isinstance(first, dict):
                    direct_candidates.extend([first.get('url'), first.get('image_url')])
                    direct_base64.extend([
                        first.get('base64'),
                        first.get('image_base64'),
                        first.get('base64_data'),
                        first.get('b64_json'),
                    ])
                elif isinstance(first, str):
                    direct_candidates.append(first)
        elif isinstance(data, list) and data:
            first = data[0]
            if isinstance(first, dict):
                direct_candidates.extend([first.get('url'), first.get('image_url')])
                direct_base64.extend([
                    first.get('base64'),
                    first.get('image_base64'),
                    first.get('base64_data'),
                    first.get('b64_json'),
                ])
            elif isinstance(first, str):
                direct_candidates.append(first)
        for candidate in direct_candidates:
            value = pick_first_string(candidate)
            if value:
                url_value = value
                break
        for candidate in direct_base64:
            value = pick_first_string(candidate)
            if value:
                base64_value = value
                break
    return {'url': url_value, 'base64': base64_value}


def call_minimax(prompt: str, seed: int) -> str:
    api_key = os.environ.get('MINIMAX_API_KEY', '').strip()
    if not api_key:
        raise RuntimeError('缺少 MINIMAX_API_KEY，无法执行在线生图。')

    api_url = os.environ.get('MINIMAX_API_URL', DEFAULT_MINIMAX_URL).strip()
    model = os.environ.get('MINIMAX_IMAGE_MODEL', DEFAULT_MINIMAX_MODEL).strip()
    payload = {
        'model': model,
        'prompt': prompt,
        'aspect_ratio': '4:3',
        'response_format': 'base64',
        'seed': seed,
    }
    request = urllib.request.Request(
        api_url,
        data=json.dumps(payload).encode('utf-8'),
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json',
        },
        method='POST',
    )
    with urllib.request.urlopen(request, timeout=120) as response:
        body = response.read().decode('utf-8')
    parsed = json.loads(body)
    base_resp = parsed.get('base_resp') if isinstance(parsed, dict) else None
    if isinstance(base_resp, dict):
        status_code = str(base_resp.get('status_code', '')).strip()
        status_msg = str(base_resp.get('status_msg', '')).strip()
        normalized_msg = status_msg.lower()
        success_messages = {'', 'success', 'ok'}
        if (status_code and status_code != '0') or normalized_msg not in success_messages:
            if status_code == '1004' or 'authorization' in normalized_msg or 'secret key' in normalized_msg:
                raise RuntimeError(
                    'MiniMax 图片接口鉴权失败，请检查当前使用的 API Key、'
                    '请求头中的 Authorization 和项目 .env 配置。'
                    f' 官方返回：status_code={status_code}, status_msg={status_msg}'
                )
            raise RuntimeError(
                f'MiniMax 图片接口返回错误：status_code={status_code}, status_msg={status_msg}'
            )
    image_payload = resolve_image_payload(parsed)
    image_base64 = image_payload.get('base64')
    image_url = image_payload.get('url')
    if image_base64:
        return f'base64:{image_base64}'
    if image_url:
        return image_url
    raise RuntimeError(f'MiniMax 返回中未找到图片结果: {body[:300]}')


def download_file(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=120) as response:
        destination.write_bytes(response.read())


def write_base64_image(data: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(base64.b64decode(data))


def create_variant(source: Path, destination: Path, width: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if shutil.which('sips'):
        result = subprocess.run(
            ['sips', '--resampleWidth', str(width), str(source), '--out', str(destination)],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode == 0 and destination.exists():
            return
    shutil.copy2(source, destination)


def export_plan(records: list[DishRecord], output_dir: Path, storage: StorageTarget) -> dict[str, Any]:
    prompts_path = output_dir / 'jobs' / 'prompts.jsonl'
    manifest_path = output_dir / 'dish_image_manifest.json'
    review_path = output_dir / 'review.md'
    prompts_path.parent.mkdir(parents=True, exist_ok=True)

    manifest_items: list[dict[str, Any]] = []
    review_lines = [
        '# 预制菜图库 Prompt Review',
        '',
        f'- 生成时间：{datetime.now(timezone.utc).isoformat()}',
        f'- 菜品数量：{len(records)}',
        '',
    ]
    with prompts_path.open('w', encoding='utf-8') as handle:
        for index, record in enumerate(records):
            prompt = build_prompt(record)
            hero_relative = f'images/{record.slug}_1280.jpg'
            thumb_relative = f'images/{record.slug}_768.jpg'
            handle.write(
                json.dumps(
                    {
                        'dishId': record.dish_id,
                        'dishName': record.dish_name,
                        'styleTag': style_tag_for(record),
                        'prompt': prompt,
                    },
                    ensure_ascii=False,
                )
                + '\n'
            )
            manifest_items.append(
                build_manifest_entry(record, storage, hero_relative, thumb_relative)
            )
            review_lines.extend([
                f'## {index + 1}. {record.dish_name}',
                '',
                f'- dishId: `{record.dish_id}`',
                f'- cuisine: `{record.cuisine or "unknown"}`',
                f'- aliases: `{", ".join(record.aliases)}`',
                f'- styleTag: `{style_tag_for(record)}`',
                f'- prompt: {prompt}',
                '',
            ])

    manifest_path.write_text(
        json.dumps({'items': manifest_items}, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    review_path.write_text('\n'.join(review_lines), encoding='utf-8')
    return {
        'manifest_path': str(manifest_path),
        'prompts_path': str(prompts_path),
        'review_path': str(review_path),
        'selected_count': len(records),
    }


def should_retry(exc: Exception) -> bool:
    text = str(exc).lower()
    if isinstance(exc, (URLError, IncompleteRead)):
        return True
    return (
        'remote end closed connection' in text
        or 'incompleteread' in text
        or 'timed out' in text
        or 'timeout' in text
        or 'connection reset' in text
        or 'system error' in text
    )


def execute_generation(
    records: list[DishRecord],
    output_dir: Path,
    storage: StorageTarget,
    sleep_seconds: float,
    retry_count: int,
) -> dict[str, Any]:
    raw_dir = output_dir / 'images_raw'
    image_dir = output_dir / 'images'
    failures: list[dict[str, str]] = []
    manifest_items: list[dict[str, Any]] = []

    for index, record in enumerate(records):
        prompt = build_prompt(record)
        seed = 1000 + index
        try:
            raw_file = raw_dir / f'{record.slug}.jpg'
            hero_file = image_dir / f'{record.slug}_1280.jpg'
            thumb_file = image_dir / f'{record.slug}_768.jpg'
            last_error: Exception | None = None
            for attempt in range(retry_count + 1):
                try:
                    remote_url = call_minimax(prompt, seed + attempt)
                    if remote_url.startswith('base64:'):
                        write_base64_image(remote_url.split(':', 1)[1], raw_file)
                    else:
                        download_file(remote_url, raw_file)
                    create_variant(raw_file, hero_file, 1280)
                    create_variant(raw_file, thumb_file, 768)
                    manifest_items.append(
                        build_manifest_entry(
                            record,
                            storage,
                            hero_file.relative_to(output_dir).as_posix(),
                            thumb_file.relative_to(output_dir).as_posix(),
                        )
                    )
                    last_error = None
                    break
                except Exception as exc:  # noqa: BLE001
                    last_error = exc
                    if attempt >= retry_count or not should_retry(exc):
                        raise
                    time.sleep(min(3.0, 0.8 * (attempt + 1)))
            if last_error is not None:
                raise last_error
            if sleep_seconds > 0:
                time.sleep(sleep_seconds)
        except Exception as exc:  # noqa: BLE001
            failures.append({'dishId': record.dish_id, 'dishName': record.dish_name, 'error': str(exc)})

    manifest_path = output_dir / 'dish_image_manifest.json'
    manifest_path.write_text(
        json.dumps({'items': manifest_items}, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    return {
        'manifest_path': str(manifest_path),
        'selected_count': len(records),
        'generated_count': len(manifest_items),
        'failure_count': len(failures),
        'failures': failures,
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Generate prebuilt dish image plan or assets.')
    parser.add_argument('--db', default=DEFAULT_DB_PATH, help='Path to unified recipe sqlite db.')
    parser.add_argument('--output-dir', default=DEFAULT_OUTPUT_DIR, help='Directory for prompts, images, and manifest.')
    parser.add_argument('--limit', type=int, default=DEFAULT_LIMIT, help='Number of dishes to select.')
    parser.add_argument('--ids', default='', help='Comma separated dish ids to generate.')
    parser.add_argument('--exclude-sample', action='store_true', help='Skip example/placeholder dishes.')
    parser.add_argument('--execute', action='store_true', help='Call MiniMax and download images.')
    parser.add_argument('--sleep-seconds', type=float, default=1.2, help='Sleep between live image requests.')
    parser.add_argument('--retry-count', type=int, default=2, help='Retry count for transient network/provider failures.')
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    repo_root = Path.cwd()
    load_env_file(repo_root / '.env')

    db_path = Path(args.db)
    if not db_path.is_absolute():
        db_path = repo_root / db_path
    if not db_path.exists():
        raise SystemExit(f'数据库不存在: {db_path}')

    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = repo_root / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    storage = StorageTarget(os.environ.get('PREBUILT_IMAGE_BASE_URL', '').strip())
    include_ids = {
        item.strip() for item in args.ids.split(',') if item.strip()
    } or None
    records = fetch_dishes(
        db_path,
        args.limit,
        include_ids=include_ids,
        exclude_sample=args.exclude_sample,
    )
    if not records:
        raise SystemExit('没有从 unified_recipes.db 读取到可生成的菜品。')

    summary = export_plan(records, output_dir, storage)
    summary['database_dish_count'] = len(
        fetch_dishes(db_path, 100000, exclude_sample=args.exclude_sample)
    )
    summary['database_raw_row_count'] = count_raw_dishes(db_path)
    summary['mode'] = 'execute' if args.execute else 'plan'

    if args.execute:
        summary.update(
            execute_generation(
                records,
                output_dir,
                storage,
                args.sleep_seconds,
                args.retry_count,
            )
        )

    report_path = output_dir / 'report.json'
    report_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
