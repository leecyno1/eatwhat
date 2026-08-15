#!/usr/bin/env python3
"""Audit the unified food corpus used by the V2 recommendation flow."""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path
from typing import Any


DEFAULT_DB_PATH = Path("assets/data/unified_recipes.db")
DEFAULT_MANIFEST_PATH = Path("assets/data/dish_image_manifest.json")


def scalar(conn: sqlite3.Connection, sql: str, params: tuple[Any, ...] = ()) -> int:
    row = conn.execute(sql, params).fetchone()
    return int(row[0] or 0) if row else 0


def rows(conn: sqlite3.Connection, sql: str) -> list[dict[str, Any]]:
    return [dict(row) for row in conn.execute(sql).fetchall()]


def load_manifest_dish_ids(path: Path) -> set[str]:
    if not path.exists():
        return set()
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return set()

    items = payload.get("items") if isinstance(payload, dict) else payload
    if not isinstance(items, list):
        return set()

    ids: set[str] = set()
    for item in items:
        if not isinstance(item, dict):
            continue
        dish_id = str(item.get("dishId") or "").strip()
        if dish_id:
            ids.add(dish_id)
    return ids


def audit(db_path: Path, manifest_path: Path | None) -> dict[str, Any]:
    if not db_path.exists():
        raise FileNotFoundError(f"Unified DB not found: {db_path}")

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    try:
        dish_count = scalar(conn, "SELECT COUNT(*) FROM dish")
        recipe_variant_count = scalar(conn, "SELECT COUNT(*) FROM recipe_variant")
        tag_count = scalar(conn, "SELECT COUNT(*) FROM tag")
        dish_tag_count = scalar(conn, "SELECT COUNT(*) FROM dish_tag")
        pairing_count = scalar(conn, "SELECT COUNT(*) FROM pairing")
        nutrition_count = scalar(
            conn,
            "SELECT COUNT(*) FROM nutrition_profile WHERE target_type='dish'",
        )
        ingredient_count = scalar(conn, "SELECT COUNT(*) FROM ingredient")
        step_count = scalar(conn, "SELECT COUNT(*) FROM recipe_step")

        dishes_without_tags = scalar(
            conn,
            """
            SELECT COUNT(*)
            FROM dish d
            LEFT JOIN dish_tag dt ON dt.dish_id = d.id
            WHERE dt.tag_id IS NULL
            """,
        )
        dishes_without_nutrition = scalar(
            conn,
            """
            SELECT COUNT(*)
            FROM dish d
            LEFT JOIN nutrition_profile n
              ON n.target_type='dish' AND n.target_id=d.id
            WHERE n.id IS NULL
            """,
        )
        recipes_without_ingredients = scalar(
            conn,
            """
            SELECT COUNT(*)
            FROM recipe_variant rv
            LEFT JOIN recipe_ingredient ri ON ri.recipe_id = rv.id
            WHERE ri.id IS NULL
            """,
        )
        recipes_without_steps = scalar(
            conn,
            """
            SELECT COUNT(*)
            FROM recipe_variant rv
            LEFT JOIN recipe_step rs ON rs.recipe_id = rv.id
            WHERE rs.id IS NULL
            """,
        )
        duplicate_canonical_names = rows(
            conn,
            """
            SELECT canonical_name, COUNT(*) AS dish_count
            FROM dish
            WHERE canonical_name IS NOT NULL AND canonical_name != ''
            GROUP BY canonical_name
            HAVING dish_count > 1
            ORDER BY dish_count DESC, canonical_name
            LIMIT 12
            """,
        )

        top_tags = rows(
            conn,
            """
            SELECT t.category, t.name_cn, COUNT(*) AS dish_count
            FROM dish_tag dt
            JOIN tag t ON t.id = dt.tag_id
            GROUP BY t.id
            ORDER BY dish_count DESC, t.category, t.name_cn
            LIMIT 12
            """,
        )
        source_mix = rows(
            conn,
            """
            SELECT source, COUNT(*) AS recipe_count
            FROM recipe_variant
            GROUP BY source
            ORDER BY recipe_count DESC, source
            """,
        )
        category_mix = rows(
            conn,
            """
            SELECT COALESCE(cuisine, '未分类') AS cuisine, COUNT(*) AS dish_count
            FROM dish
            GROUP BY cuisine
            ORDER BY dish_count DESC, cuisine
            LIMIT 12
            """,
        )
    finally:
        conn.close()

    manifest_ids = load_manifest_dish_ids(manifest_path) if manifest_path else set()
    image_coverage = len(manifest_ids) / dish_count if dish_count else 0.0

    score = 100
    warnings: list[str] = []
    if dish_count < 300:
        score -= 30
        warnings.append("菜品池不足 300 道，推荐多样性会明显受限。")
    if tag_count < 80:
        score -= 18
        warnings.append("DB 标签少于 80 个，偏好卡牌与推荐召回仍会脱节。")
    if pairing_count == 0:
        score -= 14
        warnings.append("pairing 为空，搭配/整套方案还缺数据底座。")
    if image_coverage < 0.6:
        score -= 10
        warnings.append("菜品图片覆盖不足 60%，结果页质感会不稳定。")
    if recipes_without_steps:
        score -= 8
        warnings.append("存在缺少步骤的菜谱变体。")
    if recipes_without_ingredients:
        score -= 8
        warnings.append("存在缺少食材的菜谱变体。")
    if dishes_without_tags:
        score -= 6
        warnings.append("存在无标签菜品，会降低召回和解释质量。")
    if duplicate_canonical_names:
        score -= 8
        warnings.append("存在重复 canonical 菜名，推荐结果可能出现同菜多版本挤占。")

    score = max(0, score)
    if score >= 85:
        stage = "beta-ready corpus"
    elif score >= 70:
        stage = "alpha corpus"
    elif score >= 50:
        stage = "demo corpus"
    else:
        stage = "prototype corpus"

    return {
        "dbPath": str(db_path),
        "manifestPath": str(manifest_path) if manifest_path else None,
        "score": score,
        "stage": stage,
        "counts": {
            "dish": dish_count,
            "recipeVariant": recipe_variant_count,
            "tag": tag_count,
            "dishTag": dish_tag_count,
            "ingredient": ingredient_count,
            "recipeStep": step_count,
            "pairing": pairing_count,
            "dishNutrition": nutrition_count,
            "manifestDishImages": len(manifest_ids),
        },
        "coverage": {
            "imageCoverage": round(image_coverage, 4),
            "dishesWithoutTags": dishes_without_tags,
            "dishesWithoutNutrition": dishes_without_nutrition,
            "recipesWithoutIngredients": recipes_without_ingredients,
            "recipesWithoutSteps": recipes_without_steps,
            "duplicateCanonicalNames": len(duplicate_canonical_names),
        },
        "mix": {
            "topTags": top_tags,
            "sources": source_mix,
            "cuisines": category_mix,
            "duplicateCanonicalNames": duplicate_canonical_names,
        },
        "warnings": warnings,
        "nextActions": _next_actions(
            dish_count=dish_count,
            tag_count=tag_count,
            pairing_count=pairing_count,
            image_coverage=image_coverage,
            duplicate_canonical_names=duplicate_canonical_names,
        ),
    }


def _next_actions(
    *,
    dish_count: int,
    tag_count: int,
    pairing_count: int,
    image_coverage: float,
    duplicate_canonical_names: list[dict[str, Any]],
) -> list[str]:
    actions: list[str] = []
    if dish_count < 300:
        actions.append("把 unified_recipes.db 扩到 300-800 道可推荐菜。")
    if tag_count < 80:
        actions.append("补齐 taste/ingredient/scene/dietary 标签到 DB 层，减少静态 fallback。")
    if pairing_count == 0:
        actions.append("生成 pairing：主食、饮品、配菜、酱汁四类先覆盖 Top 100 菜。")
    elif pairing_count < dish_count * 2:
        actions.append("扩展 pairing：让 Top 推荐菜至少有饮品/配菜两类搭配。")
    if image_coverage < 0.9:
        actions.append("让图片 manifest 覆盖 Top 推荐菜，优先补齐首页和结果页常出现菜品。")
    if duplicate_canonical_names:
        actions.append("收紧 dish 去重策略，避免同名菜多版本挤占推荐位。")
    return actions


def print_text_report(report: dict[str, Any]) -> None:
    counts = report["counts"]
    coverage = report["coverage"]
    print(f"Food corpus audit: {report['score']}/100, {report['stage']}")
    print("")
    print("Counts")
    for key, value in counts.items():
        print(f"  {key}: {value}")
    print("")
    print("Coverage")
    for key, value in coverage.items():
        print(f"  {key}: {value}")
    if report["warnings"]:
        print("")
        print("Warnings")
        for warning in report["warnings"]:
            print(f"  - {warning}")
    print("")
    print("Next actions")
    for action in report["nextActions"]:
        print(f"  - {action}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB_PATH)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST_PATH)
    parser.add_argument("--json", action="store_true", help="Print JSON output")
    parser.add_argument("--fail-under-dishes", type=int, default=0)
    parser.add_argument("--fail-under-tags", type=int, default=0)
    parser.add_argument("--fail-under-score", type=int, default=0)
    args = parser.parse_args(argv)

    report = audit(args.db, args.manifest)

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print_text_report(report)

    counts = report["counts"]
    failed = False
    if args.fail_under_dishes and counts["dish"] < args.fail_under_dishes:
        failed = True
    if args.fail_under_tags and counts["tag"] < args.fail_under_tags:
        failed = True
    if args.fail_under_score and report["score"] < args.fail_under_score:
        failed = True
    return 2 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
