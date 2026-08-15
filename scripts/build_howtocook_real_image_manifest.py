#!/usr/bin/env python3
"""Build real dish image manifest entries from local HowToCook markdown assets."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sqlite3
from dataclasses import dataclass
from pathlib import Path


DEFAULT_HOWTOCOOK_ROOTS = ('HowToCook/dishes', 'HowToCook-1.5.0/dishes')
DEFAULT_UNIFIED_DB_PATH = 'assets/data/unified_recipes.db'
DEFAULT_ASSET_DIR = 'assets/images/prebuilt_dishes'
DEFAULT_MANIFEST_PATH = 'assets/data/dish_image_manifest.json'
DEFAULT_REPORT_PATH = 'tmp/howtocook_real_image_report.json'
DEFAULT_AUDIT_PATH = 'tmp/dish_image_source_audit.json'

_LOCAL_IMAGE_PATTERN = re.compile(r'!\[[^\]]*]\(([^)]+)\)')
_NORMALIZE_PATTERN = re.compile(r'[\s\-_·•,，。.!！？?、（）()]+')
_CATEGORY_DIRS = {
    'dishes',
    'meat_dish',
    'vegetable_dish',
    'aquatic',
    'staple',
    'breakfast',
    'dessert',
    'soup',
    'condiment',
    'semi-finished',
    'template',
}
_SAFE_PREFIXES = (
    '简易',
    '家常',
    '经典',
    '正宗',
    '懒人',
    '快手',
    '基础',
    '微波炉',
    '烤箱版',
    '无厨师机',
    '完美',
    '家庭版',
)


@dataclass(frozen=True)
class HowToCookImageRecord:
    markdown_path: Path
    recipe_name: str
    aliases: list[str]
    local_image_refs: list[str]


@dataclass(frozen=True)
class HowToCookRecipeRecord:
    markdown_path: Path
    recipe_name: str
    aliases: list[str]


def normalize_text(value: str) -> str:
    return _NORMALIZE_PATTERN.sub('', value.strip()).lower()


def extract_local_image_refs(markdown: str) -> list[str]:
    refs: list[str] = []
    for match in _LOCAL_IMAGE_PATTERN.finditer(markdown):
      # keep indentation local to the regex loop
        ref = match.group(1).strip()
        if not ref or ref.startswith('http://') or ref.startswith('https://'):
            continue
        refs.append(ref)
    return refs


def build_aliases_for_markdown(path: Path) -> list[str]:
    aliases: list[str] = []

    def add_alias(value: str) -> None:
        candidate = value.strip()
        if candidate and candidate not in aliases:
            aliases.append(candidate)

    stem = path.stem
    add_alias(stem)

    parent = path.parent.name
    if parent not in _CATEGORY_DIRS and parent != stem:
        add_alias(parent)

    simplified = stem
    changed = True
    while changed and simplified:
        changed = False
        for prefix in _SAFE_PREFIXES:
            if simplified.startswith(prefix) and len(simplified) > len(prefix) + 1:
                simplified = simplified[len(prefix) :]
                changed = True
    add_alias(simplified)

    if parent not in _CATEGORY_DIRS:
        for prefix in _SAFE_PREFIXES:
            if parent.startswith(prefix) and len(parent) > len(prefix) + 1:
                add_alias(parent[len(prefix) :])

    return aliases


def scan_howtocook_records(howtocook_root: Path) -> list[HowToCookImageRecord]:
    records: list[HowToCookImageRecord] = []
    for markdown_path in sorted(howtocook_root.rglob('*.md')):
        markdown = markdown_path.read_text(encoding='utf-8', errors='ignore')
        image_refs = extract_local_image_refs(markdown)
        if not image_refs:
            continue
        records.append(
            HowToCookImageRecord(
                markdown_path=markdown_path,
                recipe_name=markdown_path.stem,
                aliases=build_aliases_for_markdown(markdown_path),
                local_image_refs=image_refs,
            ),
        )
    return records


def scan_howtocook_recipe_records(howtocook_root: Path) -> list[HowToCookRecipeRecord]:
    records: list[HowToCookRecipeRecord] = []
    for markdown_path in sorted(howtocook_root.rglob('*.md')):
        records.append(
            HowToCookRecipeRecord(
                markdown_path=markdown_path,
                recipe_name=markdown_path.stem,
                aliases=build_aliases_for_markdown(markdown_path),
            ),
        )
    return records


def load_unified_dishes(db_path: Path) -> list[dict[str, str]]:
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    try:
        rows = conn.execute(
            '''
            select id, canonical_name
            from dish
            where canonical_name is not null
              and trim(canonical_name) <> ''
              and canonical_name not like '%示例菜谱%'
            order by popularity_score desc, id asc
            '''
        ).fetchall()
        return [
            {
                'dishId': str(row['id']),
                'dishName': str(row['canonical_name']).strip(),
            }
            for row in rows
        ]
    finally:
        conn.close()


def match_records_to_dishes(
    dishes: list[dict[str, str]],
    records: list[HowToCookImageRecord],
) -> list[dict[str, object]]:
    matched: list[dict[str, object]] = []
    scored_records: list[tuple[int, HowToCookImageRecord]] = []
    for record in records:
        normalized_aliases = {normalize_text(alias) for alias in record.aliases}
        primary = normalize_text(record.recipe_name)
        parent = normalize_text(record.markdown_path.parent.name)
        base_score = 1
        if parent and parent in normalized_aliases and parent != primary:
            base_score = 2
        scored_records.append((base_score, record))

    for dish in dishes:
        dish_name = str(dish['dishName']).strip()
        normalized_dish = normalize_text(dish_name)
        best: tuple[int, HowToCookImageRecord] | None = None
        for record_score, record in scored_records:
            alias_set = {normalize_text(alias) for alias in record.aliases}
            if normalized_dish not in alias_set:
                continue
            score = record_score
            if normalize_text(record.recipe_name) == normalized_dish:
                score = 3
            if best is None or score > best[0]:
                best = (score, record)
        if best is None:
            continue
        _, record = best
        matched.append(
            {
                'dishId': str(dish['dishId']),
                'dishName': dish_name,
                'markdownPath': str(record.markdown_path),
                'imageRef': record.local_image_refs[0],
                'aliases': record.aliases,
            }
        )
    return matched


def fill_missing_entries_by_dish_name(
    dishes: list[dict[str, str]],
    existing_by_id: dict[str, dict[str, object]],
) -> dict[str, dict[str, object]]:
    normalized_source: dict[str, dict[str, object]] = {}
    for entry in existing_by_id.values():
        dish_name = str(entry.get('dishName', '')).strip()
        hero_url = str(entry.get('heroUrl', '')).strip()
        thumb_url = str(entry.get('thumbUrl', '')).strip()
        if not dish_name or not hero_url or not thumb_url:
            continue
        normalized_source.setdefault(normalize_text(dish_name), entry)

    for dish in dishes:
        dish_id = str(dish['dishId']).strip()
        dish_name = str(dish['dishName']).strip()
        if not dish_id or dish_id in existing_by_id:
            continue
        source = normalized_source.get(normalize_text(dish_name))
        if source is None:
            continue
        aliases = _merge_unique_strings(source.get('aliases', []), [dish_name])
        cloned = dict(source)
        cloned['dishId'] = dish_id
        cloned['dishName'] = dish_name
        cloned['aliases'] = aliases
        existing_by_id[dish_id] = cloned
    return existing_by_id


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Map unified dishes to real HowToCook local images and update manifest.',
    )
    parser.add_argument(
        '--howtocook-root',
        action='append',
        dest='howtocook_roots',
        help='HowToCook dishes 根目录。可重复传入多个。',
    )
    parser.add_argument('--db-path', default=DEFAULT_UNIFIED_DB_PATH)
    parser.add_argument('--asset-dir', default=DEFAULT_ASSET_DIR)
    parser.add_argument('--manifest-path', default=DEFAULT_MANIFEST_PATH)
    parser.add_argument('--report-path', default=DEFAULT_REPORT_PATH)
    parser.add_argument('--audit-path', default=DEFAULT_AUDIT_PATH)
    parser.add_argument(
        '--limit',
        type=int,
        default=0,
        help='Optional maximum number of matched dishes to install. 0 means no limit.',
    )
    return parser.parse_args()


def _load_existing_manifest(manifest_path: Path) -> dict[str, dict[str, object]]:
    if not manifest_path.exists():
        return {}
    payload = json.loads(manifest_path.read_text(encoding='utf-8'))
    raw_items = payload.get('items')
    if not isinstance(raw_items, list):
        return {}
    by_id: dict[str, dict[str, object]] = {}
    for item in raw_items:
        if not isinstance(item, dict):
            continue
        dish_id = str(item.get('dishId', '')).strip()
        if not dish_id:
            continue
        by_id[dish_id] = dict(item)
    return by_id


def _merge_unique_strings(*groups: object) -> list[str]:
    merged: list[str] = []
    for group in groups:
        if not isinstance(group, list):
            continue
        for item in group:
            if not isinstance(item, str):
                continue
            candidate = item.strip()
            if candidate and candidate not in merged:
                merged.append(candidate)
    return merged


def _default_source_metadata(entry: dict[str, object]) -> dict[str, str]:
    hero_url = str(entry.get('heroUrl', '')).strip()
    style_tag = str(entry.get('styleTag', '')).strip()
    source_type = str(entry.get('sourceType', '')).strip()
    source_project = str(entry.get('sourceProject', '')).strip()
    source_path = str(entry.get('sourcePath', '')).strip()
    source_recipe_name = str(entry.get('sourceRecipeName', '')).strip()

    if source_type:
        return {
            'sourceType': source_type,
            'sourceProject': source_project,
            'sourcePath': source_path,
            'sourceRecipeName': source_recipe_name,
        }

    if style_tag == 'howtocook_real_photo':
        return {
            'sourceType': 'howtocook_real_local',
            'sourceProject': source_project or 'HowToCook',
            'sourcePath': source_path,
            'sourceRecipeName': source_recipe_name or str(entry.get('dishName', '')).strip(),
        }

    return {
        'sourceType': 'legacy_prebuilt_asset' if hero_url.startswith('assets/') else 'unknown',
        'sourceProject': source_project or ('eatwhat_assets' if hero_url.startswith('assets/') else ''),
        'sourcePath': source_path or hero_url,
        'sourceRecipeName': source_recipe_name or str(entry.get('dishName', '')).strip(),
    }


def enrich_manifest_sources(
    existing_by_id: dict[str, dict[str, object]],
) -> dict[str, dict[str, object]]:
    enriched: dict[str, dict[str, object]] = {}
    for dish_id, entry in existing_by_id.items():
        source_meta = _default_source_metadata(entry)
        merged = dict(entry)
        merged.update(source_meta)
        merged['aliases'] = _merge_unique_strings(
            merged.get('aliases', []),
            [str(merged.get('dishName', '')).strip()],
        )
        enriched[dish_id] = merged
    return enriched


def build_recipe_presence_index(
    recipe_records: list[HowToCookRecipeRecord],
) -> dict[str, list[str]]:
    index: dict[str, list[str]] = {}
    for record in recipe_records:
        path_str = str(record.markdown_path)
        keys = {normalize_text(record.recipe_name)}
        keys.update(normalize_text(alias) for alias in record.aliases)
        for key in keys:
            if not key:
                continue
            bucket = index.setdefault(key, [])
            if path_str not in bucket:
                bucket.append(path_str)
    return index


def build_source_audit(
    dishes: list[dict[str, str]],
    manifest_items: list[dict[str, object]],
    recipe_presence_index: dict[str, list[str]],
) -> dict[str, object]:
    manifest_by_id = {
        str(item.get('dishId', '')).strip(): item
        for item in manifest_items
        if str(item.get('dishId', '')).strip()
    }
    rows: list[dict[str, object]] = []
    real_count = 0
    legacy_count = 0
    missing_count = 0
    recipe_exists_without_real_count = 0

    for dish in dishes:
        dish_id = str(dish['dishId']).strip()
        dish_name = str(dish['dishName']).strip()
        item = manifest_by_id.get(dish_id, {})
        source_type = str(item.get('sourceType', '')).strip()
        recipe_paths = recipe_presence_index.get(normalize_text(dish_name), [])
        if source_type == 'howtocook_real_local':
            coverage = 'exact_local_photo'
            real_count += 1
        elif item:
            coverage = 'legacy_prebuilt'
            legacy_count += 1
            if recipe_paths:
                recipe_exists_without_real_count += 1
        else:
            coverage = 'missing'
            missing_count += 1

        rows.append(
            {
                'dishId': dish_id,
                'dishName': dish_name,
                'coverage': coverage,
                'sourceType': source_type or 'missing',
                'sourceProject': str(item.get('sourceProject', '')).strip(),
                'sourcePath': str(item.get('sourcePath', '')).strip(),
                'hasHowToCookRecipe': bool(recipe_paths),
                'howToCookRecipePaths': recipe_paths[:3],
            }
        )

    return {
        'summary': {
            'dishCount': len(dishes),
            'exactLocalPhotoCount': real_count,
            'legacyPrebuiltCount': legacy_count,
            'missingCount': missing_count,
            'exactRecipeWithoutLocalImageCount': recipe_exists_without_real_count,
        },
        'items': rows,
    }


def _copy_as_real_asset(
    source_path: Path,
    dish_id: str,
    asset_dir: Path,
    asset_prefix: str,
) -> tuple[str, str]:
    suffix = source_path.suffix.lower() or '.jpg'
    hero_name = f'dish-{dish_id}-howtocook-real_1280{suffix}'
    thumb_name = f'dish-{dish_id}-howtocook-real_768{suffix}'
    hero_target = asset_dir / hero_name
    thumb_target = asset_dir / thumb_name
    shutil.copy2(source_path, hero_target)
    shutil.copy2(source_path, thumb_target)
    return f'{asset_prefix}/{hero_name}', f'{asset_prefix}/{thumb_name}'


def main() -> int:
    args = parse_args()
    repo_root = Path.cwd()
    howtocook_roots = args.howtocook_roots or list(DEFAULT_HOWTOCOOK_ROOTS)
    resolved_howtocook_roots = [
        (repo_root / root).resolve()
        for root in howtocook_roots
    ]
    db_path = (repo_root / args.db_path).resolve()
    asset_dir = (repo_root / args.asset_dir).resolve()
    asset_prefix = args.asset_dir.replace('\\', '/').strip('/')
    manifest_path = (repo_root / args.manifest_path).resolve()
    report_path = (repo_root / args.report_path).resolve()
    audit_path = (repo_root / args.audit_path).resolve()

    for howtocook_root in resolved_howtocook_roots:
        if not howtocook_root.exists():
            raise SystemExit(f'HowToCook 目录不存在: {howtocook_root}')
    if not db_path.exists():
        raise SystemExit(f'统一菜谱数据库不存在: {db_path}')

    records: list[HowToCookImageRecord] = []
    recipe_records: list[HowToCookRecipeRecord] = []
    for howtocook_root in resolved_howtocook_roots:
        records.extend(scan_howtocook_records(howtocook_root))
        recipe_records.extend(scan_howtocook_recipe_records(howtocook_root))
    dishes = load_unified_dishes(db_path)
    matches = match_records_to_dishes(dishes, records)
    if args.limit > 0:
        matches = matches[: args.limit]

    asset_dir.mkdir(parents=True, exist_ok=True)
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    audit_path.parent.mkdir(parents=True, exist_ok=True)

    existing = _load_existing_manifest(manifest_path)
    installed: list[dict[str, object]] = []
    unresolved = []

    for match in matches:
        markdown_path = Path(str(match['markdownPath']))
        image_ref = str(match['imageRef'])
        source_image = (markdown_path.parent / image_ref).resolve()
        if not source_image.exists():
            unresolved.append(
                {
                    'dishId': match['dishId'],
                    'dishName': match['dishName'],
                    'reason': f'源图片不存在: {source_image}',
                }
            )
            continue

        hero_url, thumb_url = _copy_as_real_asset(
            source_path=source_image,
            dish_id=str(match['dishId']),
            asset_dir=asset_dir,
            asset_prefix=asset_prefix,
        )
        previous = existing.get(str(match['dishId']), {})
        aliases = _merge_unique_strings(
            previous.get('aliases', []),
            match['aliases'],
            [str(match['dishName'])],
        )

        entry = {
            'dishId': str(match['dishId']),
            'dishName': str(match['dishName']),
            'aliases': aliases,
            'heroUrl': hero_url,
            'thumbUrl': thumb_url,
            'styleTag': 'howtocook_real_photo',
            'updatedAt': previous.get('updatedAt') or '2026-04-14T00:00:00Z',
            'sourceType': 'howtocook_real_local',
            'sourceProject': 'HowToCook',
            'sourcePath': str(source_image),
            'sourceRecipeName': markdown_path.stem,
        }
        existing[str(match['dishId'])] = entry
        installed.append(
            {
                **entry,
                'markdownPath': str(markdown_path),
                'sourceImage': str(source_image),
            }
        )

    existing = fill_missing_entries_by_dish_name(
        dishes=dishes,
        existing_by_id=existing,
    )
    existing = enrich_manifest_sources(existing)

    final_items = sorted(
        existing.values(),
        key=lambda item: (
            0 if str(item.get('dishId', '')).isdigit() else 1,
            int(str(item.get('dishId', '0')))
            if str(item.get('dishId', '')).isdigit()
            else str(item.get('dishId', '')),
        ),
    )
    manifest_path.write_text(
        json.dumps({'items': final_items}, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    report_path.write_text(
        json.dumps(
            {
                'matchedCount': len(matches),
                'installedCount': len(installed),
                'recordsWithImages': len(records),
                'recipeRecordCount': len(recipe_records),
                'dishCount': len(dishes),
                'installed': installed,
                'unresolved': unresolved,
            },
            ensure_ascii=False,
            indent=2,
        )
        + '\n',
        encoding='utf-8',
    )
    audit_path.write_text(
        json.dumps(
            build_source_audit(
                dishes=dishes,
                manifest_items=final_items,
                recipe_presence_index=build_recipe_presence_index(recipe_records),
            ),
            ensure_ascii=False,
            indent=2,
        )
        + '\n',
        encoding='utf-8',
    )

    print(
        json.dumps(
            {
                'matchedCount': len(matches),
                'installedCount': len(installed),
                'manifestPath': str(manifest_path),
                'reportPath': str(report_path),
                'auditPath': str(audit_path),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
