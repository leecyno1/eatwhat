#!/usr/bin/env python3
"""Dish image backfill pipeline.

Every dish in unified_recipes.db must carry a prebuilt image so the app
never depends on runtime image generation. This pipeline:

  plan   — lists dishes missing a prebuilt image and emits a generation
           plan (dish id, name, ingredients, image prompt) to
           output/image_backfill_plan.json. Images are then generated
           per plan (by the AI image tool) into
           assets/images/prebuilt_dishes/dish-<id>-ai-v2_1280.png.
  sync   — after images land, derives 768px thumbnails with sips and
           appends manifest entries for every new file, keyed to the
           current db ids.

Usage:
  python3 scripts/build_missing_dish_images.py plan
  python3 scripts/build_missing_dish_images.py sync
"""

import json
import os
import re
import sqlite3
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / 'assets/data/unified_recipes.db'
MANIFEST_PATH = PROJECT_ROOT / 'assets/data/dish_image_manifest.json'
IMAGE_DIR = PROJECT_ROOT / 'assets/images/prebuilt_dishes'
PLAN_PATH = PROJECT_ROOT / 'output/image_backfill_plan.json'

STYLE_PROMPT = (
    '中式家常菜美食摄影，餐厅级摆盘，{scene}，主食材为{ingredients}，'
    '暖色灯光，浅景深，木质桌面配深色餐具，食欲感强，真实照片质感，'
    '画面主体居中占 70%，4K 高清'
)

SCENE_HINTS = {
    '水产': '带汤汁的深盘盛装，点缀葱花与红椒',
    '肉类': '铸铁锅或深盘盛装，酱汁光泽油亮',
    '蔬菜': '浅色瓷盘盛装，突出翠绿与清爽',
    '汤品': '白瓷汤碗盛装，热气与枸杞点缀',
    '主食': '宽口碗盛装，筷子或勺子侧放',
    '甜品': '玻璃碗或白瓷小碟，薄荷叶点缀',
}


def normalize(value: str) -> str:
    return re.sub(r'[\s\-_·•,，。.!！？?、（）()：:]+', '', value.strip().lower())


def load_db():
    db = sqlite3.connect(DB_PATH)
    rows = db.execute(
        '''
        SELECT d.id, d.name_cn, d.cuisine, d.main_ingredients,
          (SELECT GROUP_CONCAT(ri.name_override, '、')
             FROM recipe_variant rv
             JOIN recipe_ingredient ri ON ri.recipe_id = rv.id
            WHERE rv.dish_id = d.id AND ri.is_main = 1)
        FROM dish d ORDER BY d.id
        '''
    ).fetchall()
    dishes = []
    for dish_id, name, cuisine, main_ingredients, variant_ingredients in rows:
        try:
            ingredients = json.loads(main_ingredients or '[]')
        except json.JSONDecodeError:
            ingredients = []
        if not ingredients and variant_ingredients:
            ingredients = [
                i.strip()
                for i in variant_ingredients.split('、')
                if i.strip()
            ][:6]
        dishes.append(
            {
                'id': dish_id,
                'name': name,
                'cuisine': cuisine or '',
                'ingredients': ingredients[:6],
            }
        )
    return dishes


def manifest_names():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding='utf-8'))
    names = set()
    for entry in manifest['items']:
        names.add(normalize(entry.get('dishName', '')))
        for alias in entry.get('aliases', []) or []:
            names.add(normalize(alias))
    return names


def build_prompt(dish):
    scene = SCENE_HINTS.get(dish['cuisine'], '家常圆盘盛装，配米饭碗一角')
    ingredients = '、'.join(dish['ingredients'][:4]) or '应季食材'
    return STYLE_PROMPT.format(scene=scene, ingredients=ingredients)


def cmd_plan():
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    known = manifest_names()
    dishes = load_db()

    # Coverage is judged by manifest names only. File-name dish ids belong
    # to the old database build and can point at a different dish, so they
    # must never be trusted as evidence of coverage.
    plan = []
    for dish in dishes:
        if normalize(dish['name']) in known:
            continue
        plan.append(
            {
                'dishId': str(dish['id']),
                'dishName': dish['name'],
                'cuisine': dish['cuisine'],
                'ingredients': dish['ingredients'],
                'prompt': build_prompt(dish),
                'targetFile': f'dish-{dish["id"]}-ai-v2_1280.png',
            }
        )

    PLAN_PATH.parent.mkdir(parents=True, exist_ok=True)
    PLAN_PATH.write_text(
        json.dumps(plan, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    print(f'missing dishes: {len(plan)}')
    print(f'plan written: {PLAN_PATH}')
    for item in plan[:10]:
        print(' ', item['dishId'], item['dishName'])
    return 0


def cmd_sync():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding='utf-8'))
    entries = manifest['items']
    known_files = {e.get('heroUrl', '') for e in entries}
    known_files |= {e.get('thumbUrl', '') for e in entries}

    dishes = {str(d['id']): d for d in load_db()}
    added = 0
    for path in sorted(IMAGE_DIR.iterdir()):
        m = re.match(r'^dish-(\d+)-ai-v2_1280\.(png|jpg|jpeg|webp)$', path.name)
        if not m:
            continue
        dish_id = m.group(1)
        dish = dishes.get(dish_id)
        if dish is None:
            continue
        hero = f'assets/images/prebuilt_dishes/{path.name}'
        if hero in known_files:
            continue

        # Derive the 768px thumbnail if missing.
        stem = path.stem
        thumb_name = f'{stem[:-5]}768{path.suffix}'
        thumb_path = IMAGE_DIR / thumb_name
        if not thumb_path.exists():
            subprocess.run(
                ['sips', '-Z', '768', str(path), '--out', str(thumb_path)],
                check=True,
                capture_output=True,
            )
        thumb = f'assets/images/prebuilt_dishes/{thumb_name}'

        entries.append(
            {
                'dishId': dish_id,
                'dishName': dish['name'],
                'aliases': [dish['name']],
                'heroUrl': hero,
                'thumbUrl': thumb,
                'styleTag': 'ai_food_photo_v2',
                'updatedAt': '2026-08-20T00:00:00Z',
                'sourceType': 'ai_generated_v2',
                'sourceProject': 'MiniMax-ImageGen',
                'ingredients': dish['ingredients'][:6],
                'cuisine': dish['cuisine'],
            }
        )
        known_files.add(hero)
        added += 1

    if added:
        MANIFEST_PATH.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + '\n',
            encoding='utf-8',
        )
    print(f'manifest entries added: {added}')
    return 0


def cmd_salvage():
    """Import real photos from the HowToCook repo for dishes that still
    lack a prebuilt image."""
    import shutil
    from collections import defaultdict

    htc = defaultdict(list)
    htc_root = PROJECT_ROOT / 'HowToCook/dishes'
    for path in sorted(htc_root.rglob('*')):
        if path.suffix.lower() in {'.jpg', '.jpeg', '.png', '.webp'}:
            htc[normalize(path.parent.name)].append(path)

    known = manifest_names()
    manifest = json.loads(MANIFEST_PATH.read_text(encoding='utf-8'))
    entries = manifest['items']
    dishes = load_db()

    added = 0
    for dish in dishes:
        if normalize(dish['name']) in known:
            continue
        sources = htc.get(normalize(dish['name']))
        if not sources:
            continue
        # Prefer the first image (usually the finished-dish hero).
        source = sources[0]
        hero_name = f'dish-{dish["id"]}-howtocook-real2_1280.jpg'
        hero_path = IMAGE_DIR / hero_name
        subprocess.run(
            ['sips', '-Z', '1280', str(source), '--out', str(hero_path)],
            check=True,
            capture_output=True,
        )
        thumb_name = f'dish-{dish["id"]}-howtocook-real2_768.jpg'
        thumb_path = IMAGE_DIR / thumb_name
        subprocess.run(
            ['sips', '-Z', '768', str(source), '--out', str(thumb_path)],
            check=True,
            capture_output=True,
        )
        entries.append(
            {
                'dishId': str(dish['id']),
                'dishName': dish['name'],
                'aliases': [dish['name']],
                'heroUrl': f'assets/images/prebuilt_dishes/{hero_name}',
                'thumbUrl': f'assets/images/prebuilt_dishes/{thumb_name}',
                'styleTag': 'howtocook_real_photo',
                'updatedAt': '2026-08-20T00:00:00Z',
                'sourceType': 'howtocook_real',
                'sourceProject': 'HowToCook',
                'sourcePath': str(source),
                'ingredients': dish['ingredients'][:6],
                'cuisine': dish['cuisine'],
            }
        )
        known.add(normalize(dish['name']))
        added += 1
        print(f'  salvaged {dish["name"]} <- {source}')

    if added:
        MANIFEST_PATH.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + '\n',
            encoding='utf-8',
        )
    print(f'salvaged from HowToCook: {added}')
    return 0


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in {'plan', 'sync', 'salvage'}:
        print(__doc__)
        return 1
    if sys.argv[1] == 'plan':
        return cmd_plan()
    if sys.argv[1] == 'salvage':
        return cmd_salvage()
    return cmd_sync()


if __name__ == '__main__':
    sys.exit(main())
