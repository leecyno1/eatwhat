#!/usr/bin/env python3
"""Install a generated prebuilt dish catalog into Flutter assets."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


DEFAULT_SOURCE_DIR = 'tmp/prebuilt_dish_catalog_live_full37'
DEFAULT_ASSET_DIR = 'assets/images/prebuilt_dishes'
DEFAULT_MANIFEST_PATH = 'assets/data/dish_image_manifest.json'


def is_placeholder_dish(name: str) -> bool:
    compact = name.strip().lower()
    return '示例菜谱' in compact or compact.startswith(
        ('soup_', 'dessert_', 'drink_', 'condiment_', 'semi-finished_', 'aquatic_'),
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Copy generated dish images into assets and rewrite manifest.',
    )
    parser.add_argument(
        '--source-dir',
        default=DEFAULT_SOURCE_DIR,
        help='Directory created by build_prebuilt_dish_catalog.py --execute',
    )
    parser.add_argument(
        '--asset-dir',
        default=DEFAULT_ASSET_DIR,
        help='Target asset directory for copied images.',
    )
    parser.add_argument(
        '--manifest-path',
        default=DEFAULT_MANIFEST_PATH,
        help='Target manifest path written for Flutter runtime.',
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path.cwd()

    source_dir = (repo_root / args.source_dir).resolve()
    asset_dir = (repo_root / args.asset_dir).resolve()
    manifest_path = (repo_root / args.manifest_path).resolve()

    source_manifest_path = source_dir / 'dish_image_manifest.json'
    source_image_dir = source_dir / 'images'

    if not source_manifest_path.exists():
        raise SystemExit(f'源 manifest 不存在: {source_manifest_path}')
    if not source_image_dir.exists():
        raise SystemExit(f'源图片目录不存在: {source_image_dir}')

    source_manifest = json.loads(source_manifest_path.read_text(encoding='utf-8'))
    items = source_manifest.get('items')
    if not isinstance(items, list):
        raise SystemExit('源 manifest 缺少 items 数组。')

    asset_dir.mkdir(parents=True, exist_ok=True)

    existing_items: list[dict[str, object]] = []
    if manifest_path.exists():
        try:
            existing_manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            raw_existing = existing_manifest.get('items')
            if isinstance(raw_existing, list):
                existing_items = [
                    item
                    for item in raw_existing
                    if isinstance(item, dict)
                    and not is_placeholder_dish(str(item.get('dishName', '')))
                ]
        except Exception:  # noqa: BLE001
            existing_items = []

    installed_by_id = {
        str(item.get('dishId', '')).strip(): dict(item)
        for item in existing_items
        if str(item.get('dishId', '')).strip()
    }
    copied_files = 0
    for item in items:
        if not isinstance(item, dict):
            continue

        hero_url = str(item.get('heroUrl', '')).strip()
        thumb_url = str(item.get('thumbUrl', '')).strip()
        hero_name = Path(hero_url).name
        thumb_name = Path(thumb_url).name
        if not hero_name or not thumb_name:
            continue

        hero_source = source_image_dir / hero_name
        thumb_source = source_image_dir / thumb_name
        if not hero_source.exists() or not thumb_source.exists():
            continue

        hero_target = asset_dir / hero_name
        thumb_target = asset_dir / thumb_name
        shutil.copy2(hero_source, hero_target)
        shutil.copy2(thumb_source, thumb_target)
        copied_files += 2

        asset_prefix = args.asset_dir.replace('\\', '/').strip('/')
        normalized = dict(item)
        if is_placeholder_dish(str(normalized.get('dishName', ''))):
            continue
        normalized['heroUrl'] = f'{asset_prefix}/{hero_name}'
        normalized['thumbUrl'] = f'{asset_prefix}/{thumb_name}'
        dish_id = str(normalized.get('dishId', '')).strip()
        if dish_id:
            installed_by_id[dish_id] = normalized

    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    installed_items = sorted(
        installed_by_id.values(),
        key=lambda item: (
            0 if str(item.get('dishId', '')).isdigit() else 1,
            int(str(item.get('dishId', '0'))) if str(item.get('dishId', '')).isdigit() else str(item.get('dishId', '')),
        ),
    )
    manifest_path.write_text(
        json.dumps({'items': installed_items}, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )

    print(
        json.dumps(
            {
                'installed_item_count': len(installed_items),
                'copied_file_count': copied_files,
                'asset_dir': str(asset_dir),
                'manifest_path': str(manifest_path),
            },
            ensure_ascii=False,
            indent=2,
        ),
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
