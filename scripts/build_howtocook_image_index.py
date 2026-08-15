#!/usr/bin/env python3
"""Build HowToCook image index for Stage 2/3 recipe enrichment."""

from __future__ import annotations

import json
import re
import shutil
from pathlib import Path


DEFAULT_ROOTS = ('HowToCook/dishes', 'HowToCook-1.5.0/dishes')
DEFAULT_OUTPUT = 'assets/data/howtocook_image_index.json'
DEFAULT_ASSET_DIR = 'assets/images/howtocook_gallery'
IMAGE_EXTS = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.JPG', '.JPEG', '.PNG', '.WEBP'}
IMAGE_REF_PATTERN = re.compile(r'!\[[^\]]*]\(([^)]+)\)')


def build_aliases(markdown_path: Path) -> list[str]:
    aliases = [markdown_path.stem]
    if markdown_path.parent.name not in {'dishes', 'meat_dish', 'vegetable_dish', 'staple'}:
        aliases.append(markdown_path.parent.name)
    deduped = []
    for item in aliases:
        value = item.strip()
        if value and value not in deduped:
            deduped.append(value)
    return deduped


def extract_image_refs(markdown: str) -> list[str]:
    refs = []
    for match in IMAGE_REF_PATTERN.finditer(markdown):
      ref = match.group(1).strip()
      if ref and not ref.startswith('http://') and not ref.startswith('https://'):
          refs.append(ref)
    return refs


def slugify(path: Path) -> str:
    raw = path.stem.strip() or path.parent.name.strip() or 'dish'
    raw = raw.replace(' ', '_')
    raw = re.sub(r'[^\w\u4e00-\u9fff-]+', '_', raw)
    raw = re.sub(r'_+', '_', raw).strip('_')
    return raw.lower() or 'dish'


def main() -> int:
    repo_root = Path.cwd()
    asset_root = repo_root / DEFAULT_ASSET_DIR
    asset_root.mkdir(parents=True, exist_ok=True)
    items = []
    for root in DEFAULT_ROOTS:
        dishes_root = repo_root / root
        if not dishes_root.exists():
            continue
        for markdown_path in sorted(dishes_root.rglob('*.md')):
            markdown = markdown_path.read_text(encoding='utf-8', errors='ignore')
            image_refs = extract_image_refs(markdown)
            if not image_refs:
                continue
            asset_urls = []
            dish_slug = slugify(markdown_path)
            target_dir = asset_root / dish_slug
            target_dir.mkdir(parents=True, exist_ok=True)
            for ref in image_refs:
                source = (markdown_path.parent / ref).resolve()
                if source.exists() and source.suffix in IMAGE_EXTS:
                    target = target_dir / source.name
                    shutil.copy2(source, target)
                    asset_urls.append(target.relative_to(repo_root).as_posix())
            if not asset_urls:
                continue
            items.append(
                {
                    'recipeId': markdown_path.relative_to(dishes_root).as_posix(),
                    'name': markdown_path.stem,
                    'aliases': build_aliases(markdown_path),
                    'assetImageUrls': asset_urls,
                    'markdownPath': markdown_path.relative_to(repo_root).as_posix(),
                    'sourceProject': 'HowToCook-1.5.0'
                    if 'HowToCook-1.5.0' in markdown_path.as_posix()
                    else 'HowToCook',
                }
            )

    output = repo_root / DEFAULT_OUTPUT
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps({'items': items}, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    print(json.dumps({'count': len(items), 'output': str(output)}, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
