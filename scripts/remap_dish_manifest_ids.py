#!/usr/bin/env python3
"""Re-align dish_image_manifest.json dishIds with the current unified DB.

The manifest was generated against an older build of unified_recipes.db.
The database was later rebuilt, so dish ids drifted: 105 of 273 entries
carried an id that now points at a different dish, and the app's
first-stage lookup (dishId match + name verification) failed almost
everywhere, leaving only the 50% name-based fallback.

This script re-maps every manifest entry to the current dish.id by
resolving its dishName (and aliases) against the current dish table:
  1. exact normalized dishName match wins,
  2. then alias matches,
  3. entries whose names no longer exist in the DB keep their old id
     (harmless: the app falls back to the full name-based scan).

Run from the project root:  python3 scripts/remap_dish_manifest_ids.py
"""

import json
import re
import shutil
import sqlite3
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = PROJECT_ROOT / 'assets/data/dish_image_manifest.json'
DB_PATH = PROJECT_ROOT / 'assets/data/unified_recipes.db'


def normalize(value: str) -> str:
    return re.sub(
        r'[\s\-_·•,，。.!！？?、（）()]+', '', value.strip().lower()
    )


def _entry_names(entry: dict) -> set[str]:
    return {normalize(entry.get('dishName', ''))} | {
        normalize(a) for a in entry.get('aliases', []) or []
    }


def main() -> int:
    if not MANIFEST_PATH.exists() or not DB_PATH.exists():
        print('manifest or database missing', file=sys.stderr)
        return 1

    db = sqlite3.connect(DB_PATH)
    dishes = {
        row[0]: row[1] for row in db.execute('SELECT id, name_cn FROM dish')
    }
    name_to_id = {normalize(name): dish_id for dish_id, name in dishes.items()}

    manifest = json.loads(MANIFEST_PATH.read_text(encoding='utf-8'))
    entries = manifest['items']

    remapped_exact = 0
    remapped_alias = 0
    unchanged = 0
    for entry in entries:
        old_id = str(entry.get('dishId', '')).strip()
        new_id = name_to_id.get(normalize(entry.get('dishName', '')))
        matched_by = 'exact'
        if new_id is None:
            for alias in entry.get('aliases', []) or []:
                new_id = name_to_id.get(normalize(alias))
                if new_id is not None:
                    matched_by = 'alias'
                    break
        if new_id is None:
            unchanged += 1
            continue
        if str(new_id) != old_id:
            entry['dishId'] = str(new_id)
            if matched_by == 'exact':
                remapped_exact += 1
            else:
                remapped_alias += 1
        else:
            unchanged += 1

    backup = MANIFEST_PATH.with_suffix('.json.bak')
    shutil.copy2(MANIFEST_PATH, backup)

    MANIFEST_PATH.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )

    print(f'entries: {len(entries)}')
    print(f'remapped (dishName exact): {remapped_exact}')
    print(f'remapped (alias): {remapped_alias}')
    print(f'unchanged / no current-db match: {unchanged}')
    print(f'backup: {backup}')

    # Post-check: how many current-db dishes resolve via dishId now?
    # The app collects ALL entries with a matching dishId and accepts the
    # first whose names match, so multiple claimants of one id are fine.
    resolved = 0
    for dish_id, name in dishes.items():
        matched = any(
            str(dish_id) == str(e.get('dishId', ''))
            and normalize(name) in _entry_names(e)
            for e in entries
        )
        if matched:
            resolved += 1
    print(f'current-db dishes resolvable by dishId: {resolved}/{len(dishes)}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
