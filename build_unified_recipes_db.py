#!/usr/bin/env python3
"""
Builds unified_recipes.db from HowToCook recipes into the schema defined in
docs/UNIFIED_RECIPE_SCHEMA.md.
"""

from __future__ import annotations

import json
import re
import sqlite3
import time
from pathlib import Path
from urllib.parse import quote
from typing import Any, Dict, Iterable, List, Optional, Tuple

ROOT = Path(__file__).parent

HOWTOCOOK_LOCAL_ROOT = ROOT / "HowToCook/dishes"
HOWTOCOOK_DB_CANDIDATES = [
    ROOT / "assets/data/howtocook_enhanced_recipes.db",
    ROOT / "howtocook_enhanced_recipes.db",
    ROOT / "assets/data/howtocook_complete_recipes.db",
    ROOT / "howtocook_complete_recipes.db",
]
HOWTOCOOK_DB = next(
    (path for path in HOWTOCOOK_DB_CANDIDATES if path.exists()),
    HOWTOCOOK_DB_CANDIDATES[-1],
)
UNIFIED_DB = ROOT / "unified_recipes.db"


def now_ms() -> int:
    return int(time.time() * 1000)


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^\w\s-]", "", value)
    value = re.sub(r"[\s_-]+", "-", value)
    return value.strip("-") or "unknown"


def normalize_name(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[（）()]", "", value)
    value = re.sub(r"[^a-z0-9\u4e00-\u9fa5]+", "", value)
    return value


def json_dump(obj: Any) -> str:
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def create_schema(conn: sqlite3.Connection) -> None:
    schema_sql = """
CREATE TABLE dish (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  slug                  TEXT UNIQUE,
  name_cn               TEXT NOT NULL,
  name_en               TEXT,
  canonical_name        TEXT,
  cuisine               TEXT,
  main_ingredients      TEXT,
  taste_profile         TEXT,
  cooking_methods       TEXT,
  scenes                TEXT,
  health_tags           TEXT,
  seasonality           TEXT,
  popularity_score      REAL,
  average_rating        REAL,
  rating_count          INTEGER,
  source_count          INTEGER DEFAULT 0,
  created_at            INTEGER,
  updated_at            INTEGER
);
CREATE INDEX idx_dish_cuisine ON dish(cuisine);

CREATE TABLE recipe_variant (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  dish_id               INTEGER NOT NULL REFERENCES dish(id) ON DELETE CASCADE,
  source                TEXT NOT NULL,
  source_recipe_id      TEXT,
  title                 TEXT,
  description           TEXT,
  difficulty            INTEGER,
  total_time_minutes    INTEGER,
  prep_time_minutes     INTEGER,
  cook_time_minutes     INTEGER,
  servings              INTEGER,
  cover_image_url       TEXT,
  cover_image_attribution TEXT,
  language              TEXT,
  is_structured         INTEGER NOT NULL DEFAULT 1,
  created_at            INTEGER,
  updated_at            INTEGER
);
CREATE INDEX idx_recipe_variant_dish ON recipe_variant(dish_id);
CREATE INDEX idx_recipe_variant_source ON recipe_variant(source, source_recipe_id);

CREATE TABLE ingredient (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  name_cn               TEXT NOT NULL,
  name_en               TEXT,
  canonical_name        TEXT,
  category              TEXT,
  aliases               TEXT,
  created_at            INTEGER,
  updated_at            INTEGER
);
CREATE INDEX idx_ingredient_canonical ON ingredient(canonical_name);

CREATE TABLE recipe_ingredient (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_id             INTEGER NOT NULL REFERENCES recipe_variant(id) ON DELETE CASCADE,
  ingredient_id         INTEGER REFERENCES ingredient(id),
  name_override         TEXT,
  quantity              REAL,
  unit                  TEXT,
  preparation           TEXT,
  is_main               INTEGER NOT NULL DEFAULT 1,
  display_order         INTEGER
);
CREATE INDEX idx_recipe_ingredient_recipe ON recipe_ingredient(recipe_id);

CREATE TABLE recipe_step (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_id             INTEGER NOT NULL REFERENCES recipe_variant(id) ON DELETE CASCADE,
  step_index            INTEGER NOT NULL,
  instruction           TEXT NOT NULL,
  image_url             TEXT,
  duration_seconds      INTEGER,
  tips                  TEXT
);
CREATE UNIQUE INDEX idx_recipe_step_unique ON recipe_step(recipe_id, step_index);

CREATE TABLE nutrition_profile (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  target_type           TEXT NOT NULL,
  target_id             INTEGER NOT NULL,
  calories              REAL,
  protein               REAL,
  fat                   REAL,
  carbs                 REAL,
  fiber                 REAL,
  sugar                 REAL,
  sodium                REAL,
  per                   TEXT NOT NULL DEFAULT 'serving',
  data_source           TEXT,
  created_at            INTEGER,
  updated_at            INTEGER,
  UNIQUE(target_type, target_id)
);
CREATE INDEX idx_nutrition_target ON nutrition_profile(target_type, target_id);

CREATE TABLE tag (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  category              TEXT NOT NULL,
  key                   TEXT NOT NULL,
  name_cn               TEXT NOT NULL,
  name_en               TEXT,
  description           TEXT,
  icon_key              TEXT,
  created_at            INTEGER,
  updated_at            INTEGER,
  UNIQUE(category, key)
);
CREATE INDEX idx_tag_category ON tag(category);

CREATE TABLE dish_tag (
  dish_id               INTEGER NOT NULL REFERENCES dish(id) ON DELETE CASCADE,
  tag_id                INTEGER NOT NULL REFERENCES tag(id) ON DELETE CASCADE,
  weight                REAL DEFAULT 1.0,
  PRIMARY KEY (dish_id, tag_id)
);
CREATE INDEX idx_dish_tag_tag ON dish_tag(tag_id);

CREATE TABLE pairing (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  dish_id               INTEGER NOT NULL REFERENCES dish(id) ON DELETE CASCADE,
  type                  TEXT NOT NULL,
  target_dish_id        INTEGER,
  name                  TEXT,
  description           TEXT,
  strength              REAL,
  source                TEXT,
  created_at            INTEGER,
  updated_at            INTEGER
);
CREATE INDEX idx_pairing_dish ON pairing(dish_id);

CREATE VIRTUAL TABLE dish_fts USING fts5(
  name_cn,
  name_en,
  tags,
  ingredients,
  content='',
  tokenize='unicode61'
);
"""
    conn.executescript(schema_sql)


TASTE_KEYWORDS = {
    "辣": ("spicy", 0.4),
    "麻": ("spicy", 0.3),
    "酸": ("sour", 0.4),
    "甜": ("sweet", 0.4),
    "苦": ("bitter", 0.3),
    "咸": ("salty", 0.4),
    "鲜": ("umami", 0.4),
    "香": ("fragrant", 0.3),
}

METHOD_KEYWORDS = {
    "炒": "炒",
    "煮": "煮",
    "蒸": "蒸",
    "炸": "炸",
    "烤": "烤",
    "炖": "炖",
    "焖": "焖",
    "煎": "煎",
    "烘焙": "烘焙",
    "凉拌": "凉拌",
    "拌": "拌",
    "煲": "煲",
}

SCENE_KEYWORDS = {
    "早餐": "早餐",
    "午餐": "午餐",
    "晚餐": "晚餐",
    "宵夜": "夜宵",
    "夜宵": "夜宵",
    "下午茶": "下午茶",
    "聚餐": "聚餐",
    "聚会": "聚餐",
    "减脂": "减脂",
    "健身": "健身",
    "夏": "夏日",
    "冬": "暖冬",
}

HEALTH_KEYWORDS = {
    "低脂": "低脂",
    "高蛋白": "高蛋白",
    "少油": "低油",
    "素食": "素食",
    "清淡": "清淡",
}

SEMANTIC_TAG_RULES: List[Tuple[str, str, List[str]]] = [
    ("dish", "豆腐菜", ["豆腐"]),
    ("dish", "鸡肉菜", ["鸡", "鸡翅", "鸡丁", "黄焖鸡", "大盘鸡"]),
    ("dish", "牛肉菜", ["牛", "肥牛", "牛肉", "牛腩"]),
    ("dish", "猪肉菜", ["猪", "肉丝", "五花肉", "排骨", "里脊", "红烧肉", "回锅肉"]),
    ("dish", "素菜", ["素菜", "花菜", "豆角", "西兰花", "小白菜", "土豆丝", "地三鲜"]),
    ("dish", "叶菜", ["生菜", "小白菜", "西兰花"]),
    ("dish", "根茎菜", ["土豆", "土豆丝"]),
    ("dish", "沙拉", ["沙拉", "生菜", "牛油果"]),
    ("dish", "米饭类", ["饭", "蛋炒饭", "米"]),
    ("dish", "面食", ["面", "炸酱面", "面条"]),
    ("dish", "包点", ["包", "小笼包"]),
    ("dish", "汤羹", ["汤", "羹", "soup"]),
    ("dish", "甜品", ["甜品", "dessert"]),
    ("dish", "饮品", ["饮品", "豆浆", "drink"]),
    ("dish", "调味蘸料", ["调料", "酱", "condiment"]),
    ("taste", "麻辣", ["麻辣", "水煮", "麻婆"]),
    ("taste", "香辣", ["香辣", "干锅", "回锅", "干煸", "辣"]),
    ("taste", "酸甜", ["糖醋", "番茄", "可乐"]),
    ("taste", "酱香", ["红烧", "黄焖", "炸酱", "酱"]),
    ("taste", "蒜香", ["蒜蓉", "蒜"]),
    ("taste", "咸鲜", ["肉丝", "鸡丁", "小笼包", "煎蛋"]),
    ("taste", "清爽", ["沙拉", "清炒", "黄瓜", "生菜", "饮品"]),
    ("texture", "脆爽", ["黄瓜", "花菜", "豆角", "土豆丝", "沙拉"]),
    ("texture", "软嫩", ["豆腐", "鸡蛋", "煎蛋", "牛肉", "鸡丁"]),
    ("texture", "酥脆", ["油条", "炸", "煎"]),
    ("texture", "浓郁", ["红烧", "黄焖", "可乐", "糖醋", "锅"]),
    ("texture", "汤汁感", ["汤", "羹", "水煮", "黄焖", "红烧"]),
    ("texture", "干香", ["干锅", "干煸", "回锅", "炒"]),
    ("scene", "下饭", ["麻婆", "红烧", "回锅", "肉丝", "鸡丁", "水煮", "黄焖", "干锅"]),
    ("scene", "快手", ["清炒", "煎蛋", "蛋炒饭", "沙拉", "豆浆"]),
    ("scene", "热乎", ["锅", "汤", "羹", "水煮", "黄焖", "红烧", "面"]),
    ("scene", "轻食", ["沙拉", "清炒", "素菜", "牛油果"]),
    ("scene", "夜宵", ["烧烤", "炸", "油条", "麻辣", "干锅"]),
    ("scene", "聚餐", ["大盘鸡", "水煮", "红烧", "排骨", "火锅"]),
    ("diet", "高蛋白", ["鸡", "牛", "肉", "蛋", "豆腐", "鱼", "虾"]),
    ("diet", "素食友好", ["素菜", "沙拉", "小白菜", "西兰花", "豆角", "花菜"]),
    ("diet", "主食友好", ["饭", "面", "包", "粥", "油条"]),
    ("execution", "可做可点", ["家常菜", "荤菜", "素菜", "主食", "早餐"]),
    ("execution", "适合外卖", ["黄焖", "麻辣", "水煮", "炸酱", "小笼包", "蛋炒饭"]),
    ("execution", "适合在家做", ["清炒", "蒜蓉", "煎蛋", "沙拉", "豆浆"]),
]

PROTEIN_KEYWORDS = ["鸡", "牛", "猪", "羊", "鱼", "虾", "鸭", "蛋", "肉", "豆腐"]
CARB_KEYWORDS = ["饭", "米", "面", "粉", "土豆", "薯", "饼", "面包", "面条"]
VEG_KEYWORDS = ["菜", "瓜", "椒", "豆", "菌", "蔬", "白菜", "青菜", "茄", "菜花"]
GENERIC_INGREDIENT_TOKENS = {
    "主料",
    "辅料",
    "调料",
    "配料",
    "配菜",
    "食材",
    "调味料",
    "材料",
    "适量",
    "少许",
}
SAUCE_LIKE_TOKENS = {
    "生抽",
    "老抽",
    "蚝油",
    "料酒",
    "白糖",
    "冰糖",
    "糖",
    "盐",
    "鸡精",
    "味精",
    "淀粉",
    "酱油",
    "醋",
    "胡椒",
    "花椒",
    "干辣椒",
}

HOWTOCOOK_CATEGORY_LABELS = {
    "meat_dish": "荤菜",
    "vegetable_dish": "素菜",
    "aquatic": "水产",
    "breakfast": "早餐",
    "staple": "主食",
    "soup": "汤羹",
    "dessert": "甜品",
    "drink": "饮品",
    "condiment": "调料",
    "semi-finished": "半成品加工",
}

HOWTOCOOK_TOOL_KEYWORDS = {
    "锅",
    "刀",
    "砧板",
    "案板",
    "碗",
    "盆",
    "盘",
    "勺",
    "筷",
    "烤箱",
    "微波炉",
    "空气炸锅",
    "电饭煲",
    "搅拌机",
    "厨师机",
    "保鲜膜",
    "锡纸",
    "模具",
    "手套",
    "厨房纸",
    "牙签",
    "滤网",
    "擀面杖",
    "裱花袋",
}


class UnifiedBuilder:
    def __init__(self, conn: sqlite3.Connection) -> None:
        self.conn = conn
        self.dish_cache: Dict[str, int] = {}
        self.dish_key_cache: Dict[Tuple[str, str, str], int] = {}
        self.ingredient_cache: Dict[str, int] = {}
        self.tag_cache: Dict[Tuple[str, str], int] = {}
        self.stats: Dict[str, int] = {
            "howtocook_recipes": 0,
            "new_dishes": 0,
            "merged_dishes": 0,
            "nutrition_created": 0,
        }

    def get_or_create_dish(
        self,
        name: str,
        cuisine: Optional[str],
        main_ingredients: Optional[List[str]],
        rating: Optional[float],
        popularity: Optional[float],
        labels: List[str],
    ) -> int:
        canonical = normalize_name(name) or f"unnamed-{len(self.dish_cache)+1}"
        dish_id = self.dish_cache.get(canonical)
        if dish_id:
            self._update_existing_dish(
                dish_id,
                main_ingredients or [],
                labels,
                rating,
                popularity,
            )
            self.stats["merged_dishes"] += 1
            return dish_id
        main_key = normalize_name(main_ingredients[0]) if main_ingredients else ""
        key = (canonical, (cuisine or "").lower(), main_key)
        taste_profile = self._infer_taste_profile(labels)
        methods = self._infer_methods(labels)
        scenes = self._infer_scenes(labels)
        health_tags = self._infer_health_tags(labels)
        payload = {
            "slug": self._generate_unique_slug(name),
            "name_cn": name,
            "name_en": None,
            "canonical_name": canonical,
            "cuisine": cuisine,
            "main_ingredients": json_dump(main_ingredients or []),
            "taste_profile": json_dump(taste_profile),
            "cooking_methods": json_dump(methods),
            "scenes": json_dump(scenes),
            "health_tags": json_dump(health_tags),
            "seasonality": json_dump([]),
            "popularity_score": popularity or 0.0,
            "average_rating": rating or None,
            "rating_count": None,
            "source_count": 0,
            "created_at": now_ms(),
            "updated_at": now_ms(),
        }
        columns = ", ".join(payload.keys())
        placeholders = ", ".join(["?"] * len(payload))
        cur = self.conn.execute(
            f"INSERT INTO dish ({columns}) VALUES ({placeholders})",
            tuple(payload.values()),
        )
        dish_id = cur.lastrowid
        self.dish_cache[canonical] = dish_id
        self.dish_key_cache[key] = dish_id
        self.stats["new_dishes"] += 1
        self._ensure_nutrition_profile(dish_id, main_ingredients)
        self.ensure_pairings_for_dish(dish_id, name, labels, main_ingredients or [])
        return dish_id

    def _update_existing_dish(
        self,
        dish_id: int,
        main_ingredients: List[str],
        labels: List[str],
        rating: Optional[float],
        popularity: Optional[float],
    ) -> None:
        row = self.conn.execute(
            "SELECT main_ingredients, taste_profile, cooking_methods, scenes, health_tags, "
            "popularity_score, average_rating FROM dish WHERE id=?",
            (dish_id,),
        ).fetchone()
        if not row:
            return
        merged_main = self._merge_json_list(row["main_ingredients"], main_ingredients, max_items=8)
        merged_methods = self._merge_json_list(
            row["cooking_methods"], self._infer_methods(labels), max_items=8
        )
        merged_scenes = self._merge_json_list(
            row["scenes"], self._infer_scenes(labels), max_items=8
        )
        merged_health = self._merge_json_list(
            row["health_tags"], self._infer_health_tags(labels), max_items=6
        )
        merged_taste = self._merge_taste_profile(row["taste_profile"], labels)
        new_popularity = max(popularity or 0.0, row["popularity_score"] or 0.0)
        new_rating = row["average_rating"]
        if rating:
            if not new_rating:
                new_rating = rating
            else:
                new_rating = round((new_rating + rating) / 2, 2)
        self.conn.execute(
            """
            UPDATE dish
            SET main_ingredients=?,
                taste_profile=?,
                cooking_methods=?,
                scenes=?,
                health_tags=?,
                popularity_score=?,
                average_rating=?,
                updated_at=?
            WHERE id=?
            """,
            (
                json_dump(merged_main),
                json_dump(merged_taste),
                json_dump(merged_methods),
                json_dump(merged_scenes),
                json_dump(merged_health),
                new_popularity,
                new_rating,
                now_ms(),
                dish_id,
            ),
        )
        dish_name = self.conn.execute(
            "SELECT name_cn FROM dish WHERE id=?",
            (dish_id,),
        ).fetchone()["name_cn"]
        self.ensure_pairings_for_dish(
            dish_id,
            dish_name,
            labels,
            merged_main,
        )

    def ensure_tag(self, category: str, name: str) -> Optional[int]:
        if not name:
            return None
        key = slugify(name)
        cache_key = (category, key)
        if cache_key in self.tag_cache:
            return self.tag_cache[cache_key]
        row = self.conn.execute(
            "SELECT id FROM tag WHERE category=? AND key=?", (category, key)
        ).fetchone()
        if row:
            tag_id = row[0]
        else:
            cur = self.conn.execute(
                """
                INSERT INTO tag (category, key, name_cn, name_en, description, icon_key,
                                 created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    category,
                    key,
                    name,
                    None,
                    None,
                    key,
                    now_ms(),
                    now_ms(),
                ),
            )
            tag_id = cur.lastrowid
        self.tag_cache[cache_key] = tag_id
        return tag_id

    def _generate_unique_slug(self, name: str) -> str:
        base = slugify(name) or f"dish-{len(self.dish_cache)+1}"
        slug_value = base
        counter = 2
        while (
            self.conn.execute("SELECT 1 FROM dish WHERE slug=?", (slug_value,)).fetchone()
            is not None
        ):
            slug_value = f"{base}-{counter}"
            counter += 1
        return slug_value

    def add_dish_tag(self, dish_id: int, category: str, name: str) -> None:
        tag_id = self.ensure_tag(category, name)
        if not tag_id:
            return
        self.conn.execute(
            """
            INSERT OR IGNORE INTO dish_tag (dish_id, tag_id, weight)
            VALUES (?, ?, ?)
            """,
            (dish_id, tag_id, 1.0),
        )

    def add_standard_dish_tags(
        self,
        dish_id: int,
        name: str,
        cuisine: Optional[str],
        labels: List[str],
        ingredients: List[str],
    ) -> None:
        for category, tag_name in self._standard_tags_for(
            name,
            cuisine,
            labels,
            ingredients,
        ):
            self.add_dish_tag(dish_id, category, tag_name)

    def _standard_tags_for(
        self,
        name: str,
        cuisine: Optional[str],
        labels: List[str],
        ingredients: List[str],
    ) -> List[Tuple[str, str]]:
        joined = " ".join([name, cuisine or "", *labels, *ingredients])
        tags: List[Tuple[str, str]] = []

        if cuisine:
            tags.append(("cuisine", cuisine))

        for keyword in TASTE_KEYWORDS:
            if keyword in joined:
                tags.append(("taste", keyword))

        for keyword, method in METHOD_KEYWORDS.items():
            if keyword in joined:
                tags.append(("method", method))

        for keyword, scene in SCENE_KEYWORDS.items():
            if keyword in joined:
                tags.append(("scene", scene))

        for keyword, health in HEALTH_KEYWORDS.items():
            if keyword in joined:
                tags.append(("health", health))

        for category, tag_name, keywords in SEMANTIC_TAG_RULES:
            if any(keyword in joined for keyword in keywords):
                tags.append((category, tag_name))

        material_ingredients = self._material_ingredients(ingredients)
        for ingredient in material_ingredients[:4]:
            tags.append(("ingredient", ingredient))

        if any(any(keyword in item for keyword in PROTEIN_KEYWORDS) for item in material_ingredients):
            tags.append(("health", "高蛋白"))
        if any(any(keyword in item for keyword in CARB_KEYWORDS) for item in material_ingredients):
            tags.append(("staple", "主食"))
        if any(any(keyword in item for keyword in VEG_KEYWORDS) for item in material_ingredients):
            tags.append(("ingredient", "蔬菜"))

        seen: List[Tuple[str, str]] = []
        for item in tags:
            if item[1] and item not in seen:
                seen.append(item)
        return seen

    def _material_ingredients(self, ingredients: List[str]) -> List[str]:
        cleaned: List[str] = []
        for ingredient in ingredients:
            text = ingredient.strip()
            compact = text.replace(" ", "")
            if not compact:
                continue
            if compact in GENERIC_INGREDIENT_TOKENS:
                continue
            if compact in SAUCE_LIKE_TOKENS:
                continue
            if compact.endswith("适量") and len(compact) <= 6:
                continue
            cleaned.append(text)
        return cleaned

    def get_or_create_ingredient(self, name: str) -> Optional[int]:
        if not name:
            return None
        canonical = normalize_name(name)
        if not canonical:
            return None
        if canonical in self.ingredient_cache:
            return self.ingredient_cache[canonical]
        row = self.conn.execute(
            "SELECT id FROM ingredient WHERE canonical_name=?", (canonical,)
        ).fetchone()
        if row:
            ingredient_id = row[0]
        else:
            cur = self.conn.execute(
                """
                INSERT INTO ingredient
                (name_cn, name_en, canonical_name, category, aliases, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    name,
                    None,
                    canonical,
                    None,
                    json_dump([]),
                    now_ms(),
                    now_ms(),
                ),
            )
            ingredient_id = cur.lastrowid
        self.ingredient_cache[canonical] = ingredient_id
        return ingredient_id

    def insert_recipe_variant(
        self,
        dish_id: int,
        source: str,
        source_recipe_id: str,
        title: str,
        description: Optional[str],
        difficulty: Optional[int],
        total_time_minutes: Optional[int],
        prep_time_minutes: Optional[int],
        cook_time_minutes: Optional[int],
        servings: Optional[int],
        cover_image_url: Optional[str],
        language: str = "zh-CN",
    ) -> int:
        payload = {
            "dish_id": dish_id,
            "source": source,
            "source_recipe_id": source_recipe_id,
            "title": title,
            "description": description,
            "difficulty": difficulty,
            "total_time_minutes": total_time_minutes,
            "prep_time_minutes": prep_time_minutes,
            "cook_time_minutes": cook_time_minutes,
            "servings": servings,
            "cover_image_url": cover_image_url,
            "cover_image_attribution": None,
            "language": language,
            "is_structured": 1,
            "created_at": now_ms(),
            "updated_at": now_ms(),
        }
        columns = ", ".join(payload.keys())
        placeholders = ", ".join(["?"] * len(payload))
        cur = self.conn.execute(
            f"INSERT INTO recipe_variant ({columns}) VALUES ({placeholders})",
            tuple(payload.values()),
        )
        recipe_id = cur.lastrowid
        self.conn.execute(
            "UPDATE dish SET source_count = source_count + 1, updated_at=? WHERE id=?",
            (now_ms(), dish_id),
        )
        return recipe_id

    def insert_ingredients(
        self, recipe_id: int, items: Iterable[Dict[str, Any]]
    ) -> None:
        for idx, item in enumerate(items, start=1):
            name = item.get("name") or item.get("ingredient")
            ingredient_id = self.get_or_create_ingredient(name)
            quantity = None
            try:
                quantity = float(item.get("amount"))
            except (TypeError, ValueError):
                quantity = None
            self.conn.execute(
                """
                INSERT INTO recipe_ingredient
                (recipe_id, ingredient_id, name_override, quantity, unit, preparation,
                 is_main, display_order)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    recipe_id,
                    ingredient_id,
                    name,
                    quantity,
                    item.get("unit"),
                    item.get("preparation"),
                    1 if item.get("is_main", True) else 0,
                    idx,
                ),
            )

    def insert_steps(
        self, recipe_id: int, steps: Iterable[Dict[str, Any]], description_key: str
    ) -> None:
        for step in steps:
            idx = step.get("step") or step.get("step_number")
            instruction = step.get(description_key)
            if not instruction:
                continue
            self.conn.execute(
                """
                INSERT INTO recipe_step
                (recipe_id, step_index, instruction, image_url, duration_seconds, tips)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    recipe_id,
                    int(idx) if idx else None,
                    instruction,
                    step.get("image_url"),
                    None,
                    step.get("notes"),
                ),
            )

    def _merge_json_list(
        self, existing_json: Optional[str], incoming: List[str], max_items: int
    ) -> List[str]:
        base: List[str] = []
        if existing_json:
            try:
                base = json.loads(existing_json)
            except json.JSONDecodeError:
                base = []
        seen: List[str] = []
        for item in base + incoming:
            if item and item not in seen:
                seen.append(item)
            if len(seen) >= max_items:
                break
        return seen

    def _merge_taste_profile(self, existing_json: Optional[str], labels: List[str]) -> Dict[str, float]:
        profile: Dict[str, float] = {}
        if existing_json:
            try:
                profile = json.loads(existing_json)
            except json.JSONDecodeError:
                profile = {}
        new_profile = self._infer_taste_profile(labels)
        for key, value in new_profile.items():
            profile[key] = min(1.0, max(profile.get(key, 0.0), value))
        return profile

    def _infer_taste_profile(self, labels: List[str]) -> Dict[str, float]:
        profile: Dict[str, float] = {}
        for label in labels:
            for keyword, (dimension, weight) in TASTE_KEYWORDS.items():
                if keyword in label:
                    profile[dimension] = min(1.0, profile.get(dimension, 0.0) + weight)
        return profile

    def _infer_methods(self, labels: List[str]) -> List[str]:
        results: List[str] = []
        for label in labels:
            for keyword, method in METHOD_KEYWORDS.items():
                if keyword in label and method not in results:
                    results.append(method)
        return results

    def _infer_scenes(self, labels: List[str]) -> List[str]:
        scenes: List[str] = []
        for label in labels:
            for keyword, scene in SCENE_KEYWORDS.items():
                if keyword in label and scene not in scenes:
                    scenes.append(scene)
        return scenes

    def _infer_health_tags(self, labels: List[str]) -> List[str]:
        tags: List[str] = []
        for label in labels:
            for keyword, tag in HEALTH_KEYWORDS.items():
                if keyword in label and tag not in tags:
                    tags.append(tag)
        return tags

    def _ensure_nutrition_profile(self, dish_id: int, ingredients: List[str]) -> None:
        if not ingredients:
            return
        row = self.conn.execute(
            "SELECT id FROM nutrition_profile WHERE target_type='dish' AND target_id=?",
            (dish_id,),
        ).fetchone()
        if row:
            return
        nutrition = self._estimate_nutrition_from_ingredients(ingredients)
        self.conn.execute(
            """
            INSERT INTO nutrition_profile
            (target_type, target_id, calories, protein, fat, carbs, fiber, sugar, sodium,
             per, data_source, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                "dish",
                dish_id,
                nutrition["calories"],
                nutrition["protein"],
                nutrition["fat"],
                nutrition["carbs"],
                nutrition["fiber"],
                nutrition["sugar"],
                nutrition["sodium"],
                "serving",
                "estimated",
                now_ms(),
                now_ms(),
            ),
        )
        self.stats["nutrition_created"] += 1

    def ensure_pairings_for_dish(
        self,
        dish_id: int,
        name: str,
        labels: List[str],
        ingredients: List[str],
    ) -> None:
        existing = self.conn.execute(
            "SELECT COUNT(*) FROM pairing WHERE dish_id=? AND source='rule'",
            (dish_id,),
        ).fetchone()[0]
        if existing:
            return

        joined = " ".join([name, *labels, *(ingredients or [])])
        pairings = self._rule_pairings_for(joined)
        for item in pairings:
            self.conn.execute(
                """
                INSERT INTO pairing
                (dish_id, type, target_dish_id, name, description, strength, source,
                 created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    dish_id,
                    item["type"],
                    None,
                    item["name"],
                    item["description"],
                    item["strength"],
                    "rule",
                    now_ms(),
                    now_ms(),
                ),
            )

    def _rule_pairings_for(self, joined: str) -> List[Dict[str, Any]]:
        def has_any(keywords: List[str]) -> bool:
            return any(keyword in joined for keyword in keywords)

        pairings: List[Dict[str, Any]] = []
        seen: set[Tuple[str, str]] = set()

        def add_pairing(
            pairing_type: str,
            name: str,
            description: str,
            strength: float,
        ) -> None:
            key = (pairing_type, name)
            if key in seen:
                return
            seen.add(key)
            pairings.append(
                {
                    "type": pairing_type,
                    "name": name,
                    "description": description,
                    "strength": strength,
                }
            )

        if has_any(["锅", "汤", "辣", "肥牛", "羊肉", "麻辣", "火锅"]):
            add_pairing(
                "side",
                "凉拌黄瓜",
                "清口解腻，能把热和辣往下收一点。",
                0.86,
            )
            add_pairing(
                "drink",
                "冰乌龙茶",
                "茶感干净，适合搭配重口和热菜。",
                0.78,
            )
        if has_any(["番茄", "牛腩", "炖", "煲", "焖", "红烧", "黄焖"]):
            add_pairing(
                "side",
                "蒜蓉生菜",
                "补一点脆感和青味，整口更平衡。",
                0.82,
            )
            add_pairing(
                "staple",
                "米饭",
                "适合接住汤汁和浓郁酱香。",
                0.76,
            )
        if has_any(["糖醋", "可乐", "甜", "酸甜"]):
            add_pairing(
                "drink",
                "无糖气泡水",
                "把甜口往清爽方向拉，吃完不腻。",
                0.8,
            )
            add_pairing(
                "side",
                "清炒时蔬",
                "用一口青味平衡酸甜和酱汁。",
                0.74,
            )
        if has_any(["早餐", "主食", "面", "粉", "饼", "粥", "包", "油条"]):
            add_pairing(
                "drink",
                "温豆浆",
                "让主食更完整，也不会抢味。",
                0.78,
            )
            add_pairing(
                "side",
                "爽口小菜",
                "补一点咸鲜和脆感，早餐更顺。",
                0.72,
            )
        if has_any(["沙拉", "清炒", "素菜", "西兰花", "小白菜", "生菜"]):
            add_pairing(
                "drink",
                "柠檬水",
                "延续清爽感，适合轻一点的菜。",
                0.76,
            )
            add_pairing(
                "staple",
                "杂粮饭",
                "补一点饱腹感，不破坏清爽口味。",
                0.7,
            )
        if has_any(["鸡", "牛", "猪", "肉", "排骨", "里脊", "豆腐"]):
            add_pairing(
                "side",
                "蒜蓉青菜",
                "肉菜旁边补一份绿叶菜，整餐更稳。",
                0.72,
            )
            add_pairing(
                "drink",
                "大麦茶",
                "谷物香能接住油香，喝起来不抢味。",
                0.68,
            )

        if not pairings:
            add_pairing(
                "side",
                "时蔬小菜",
                "补一份清爽蔬菜，吃起来更完整。",
                0.68,
            )
        if not any(item["type"] == "drink" for item in pairings):
            add_pairing(
                "drink",
                "冰乌龙茶",
                "清爽不甜，适合当一份通用解腻饮品。",
                0.64,
            )
        if not any(item["type"] == "side" for item in pairings):
            add_pairing(
                "side",
                "时蔬小菜",
                "补一份清爽蔬菜，吃起来更完整。",
                0.62,
            )
        return pairings[:4]

    def _estimate_nutrition_from_ingredients(self, ingredients: List[str]) -> Dict[str, float]:
        calories = 220.0
        protein = 8.0
        fat = 6.0
        carbs = 22.0
        fiber = 2.0
        sugar = 4.0
        sodium = 350.0
        for ingredient in ingredients:
            name = ingredient.lower()
            if any(keyword in name for keyword in PROTEIN_KEYWORDS):
                calories += 120
                protein += 18
                fat += 10
            elif any(keyword in name for keyword in CARB_KEYWORDS):
                calories += 90
                carbs += 20
                sugar += 2
            elif any(keyword in name for keyword in VEG_KEYWORDS):
                calories += 40
                fiber += 3
                carbs += 6
        return {
            "calories": round(calories, 1),
            "protein": round(protein, 1),
            "fat": round(fat, 1),
            "carbs": round(carbs, 1),
            "fiber": round(fiber, 1),
            "sugar": round(sugar, 1),
            "sodium": round(sodium, 1),
        }

    def populate_fts(self) -> None:
        self.conn.execute("DELETE FROM dish_fts")
        dishes = self.conn.execute("SELECT id, name_cn, name_en FROM dish").fetchall()
        for dish in dishes:
            tags_text = (
                self.conn.execute(
                    """
                    SELECT GROUP_CONCAT(t.name_cn, ' ')
                    FROM dish_tag dt
                    JOIN tag t ON t.id = dt.tag_id
                    WHERE dt.dish_id=?
                    """,
                    (dish["id"],),
                ).fetchone()[0]
                or ""
            )
            ingredients_text = (
                self.conn.execute(
                    """
                    SELECT GROUP_CONCAT(COALESCE(i.name_cn, ri.name_override), ' ')
                    FROM recipe_variant rv
                    JOIN recipe_ingredient ri ON ri.recipe_id = rv.id
                    LEFT JOIN ingredient i ON i.id = ri.ingredient_id
                    WHERE rv.dish_id=?
                    """,
                    (dish["id"],),
                ).fetchone()[0]
                or ""
            )
            self.conn.execute(
                """
                INSERT INTO dish_fts(rowid, name_cn, name_en, tags, ingredients)
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    dish["id"],
                    dish["name_cn"],
                    dish["name_en"],
                    tags_text,
                    ingredients_text,
                ),
            )

    def run_validation(self) -> None:
        dish_count = self.conn.execute("SELECT COUNT(*) FROM dish").fetchone()[0]
        recipe_count = self.conn.execute("SELECT COUNT(*) FROM recipe_variant").fetchone()[0]
        duplicate_rows = self.conn.execute(
            """
            SELECT canonical_name, COUNT(*) c
            FROM dish
            WHERE canonical_name IS NOT NULL AND canonical_name != ''
            GROUP BY canonical_name
            HAVING c > 1
            ORDER BY c DESC
            LIMIT 10
            """
        ).fetchall()
        missing_nutrition = self.conn.execute(
            """
            SELECT COUNT(*)
            FROM dish d
            LEFT JOIN nutrition_profile n
              ON n.target_type='dish' AND n.target_id=d.id
            WHERE n.id IS NULL
            """
        ).fetchone()[0]
        print("=== Unified DB Validation Report ===")
        print(f"Total dishes: {dish_count}")
        print(f"Total recipe variants: {recipe_count}")
        print(f"Dishes without nutrition profile: {missing_nutrition}")
        if duplicate_rows:
            print("Potential duplicate canonical names:")
            for row in duplicate_rows:
                print(f"  - {row['canonical_name']}: {row['c']} entries")
        print("Import stats:", self.stats)


def difficulty_from_label(label: Optional[str]) -> Optional[int]:
    if label is None:
        return None
    mapping = {"easy": 2, "medium": 3, "hard": 4}
    return mapping.get(label.lower(), None)


def _clean_markdown_text(value: str) -> str:
    value = re.sub(r"!\[[^\]]*]\([^)]+\)", "", value)
    value = re.sub(r"\[([^\]]+)]\([^)]+\)", r"\1", value)
    value = value.replace("`", "")
    value = re.sub(r"\*\*([^*]+)\*\*", r"\1", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip(" \t\r\n；;。")


def _strip_howtocook_title(value: str) -> str:
    title = _clean_markdown_text(value)
    for suffix in ("的做法", "做法", "食谱"):
        if title.endswith(suffix) and len(title) > len(suffix) + 1:
            title = title[: -len(suffix)]
    return title.strip() or value.strip()


def _extract_markdown_title(markdown: str, fallback: str) -> str:
    match = re.search(r"^#\s+(.+)$", markdown, re.MULTILINE)
    return _strip_howtocook_title(match.group(1)) if match else fallback


def _extract_howtocook_difficulty(markdown: str) -> int:
    match = re.search(r"预估烹饪难度[：:]\s*([★☆]+)", markdown)
    if not match:
        return 3
    return max(1, min(5, match.group(1).count("★")))


def _extract_howtocook_intro(markdown: str) -> str:
    title_match = re.search(r"^#\s+.+$", markdown, re.MULTILINE)
    start = title_match.end() if title_match else 0
    next_heading = re.search(r"^##\s+", markdown[start:], re.MULTILINE)
    end = start + next_heading.start() if next_heading else len(markdown)
    raw = markdown[start:end]
    raw = re.sub(r"预估烹饪难度[：:].*", "", raw)
    lines = [
        _clean_markdown_text(line)
        for line in raw.splitlines()
        if _clean_markdown_text(line)
    ]
    return " ".join(lines[:3])[:240]


def _extract_markdown_section(markdown: str, heading_keywords: List[str]) -> str:
    pattern = re.compile(r"^##\s+(.+)$", re.MULTILINE)
    matches = list(pattern.finditer(markdown))
    for index, match in enumerate(matches):
        heading = match.group(1).strip()
        if not any(keyword in heading for keyword in heading_keywords):
            continue
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(markdown)
        return markdown[start:end].strip()
    return ""


def _extract_list_items(section: str) -> List[str]:
    items: List[str] = []
    for raw_line in section.splitlines():
        line = raw_line.strip()
        match = re.match(r"^(?:[-*+]|\d+[.)])\s+(.+)$", line)
        if not match:
            continue
        text = _clean_markdown_text(match.group(1))
        if text:
            items.append(text)
    return items


def _is_probable_tool(value: str) -> bool:
    compact = re.sub(r"\s+", "", value)
    if not compact:
        return True
    if compact in GENERIC_INGREDIENT_TOKENS:
        return True
    return any(keyword in compact for keyword in HOWTOCOOK_TOOL_KEYWORDS)


def _parse_howtocook_ingredients(markdown: str) -> List[Dict[str, Any]]:
    required_section = _extract_markdown_section(
        markdown,
        ["必备原料", "原料", "材料"],
    )
    ingredient_names: List[str] = []
    for item in _extract_list_items(required_section):
        name = re.split(r"[=：:，,（(]", item, maxsplit=1)[0].strip()
        name = re.sub(r"\s+", " ", name)
        if not name or _is_probable_tool(name):
            continue
        if name not in ingredient_names:
            ingredient_names.append(name)

    return [
        {
            "name": name,
            "amount": None,
            "unit": None,
            "preparation": None,
            "is_main": True,
            "order_index": index,
        }
        for index, name in enumerate(ingredient_names, start=1)
    ]


def _parse_howtocook_steps(markdown: str) -> List[Dict[str, Any]]:
    operation_section = _extract_markdown_section(
        markdown,
        ["操作", "做法", "步骤"],
    )
    items = _extract_list_items(operation_section)
    if not items:
        items = [
            _clean_markdown_text(line)
            for line in operation_section.splitlines()
            if _clean_markdown_text(line)
            and not line.lstrip().startswith("#")
            and not line.lstrip().startswith("!")
        ]
    return [
        {
            "step_number": index,
            "description": item,
            "image_url": None,
            "notes": None,
        }
        for index, item in enumerate(items, start=1)
        if item
    ]


def _first_howtocook_local_image(markdown_path: Path, markdown: str) -> Optional[str]:
    for match in re.finditer(r"!\[[^\]]*]\(([^)]+)\)", markdown):
        ref = match.group(1).strip()
        if not ref or ref.startswith(("http://", "https://")):
            continue
        source_image = (markdown_path.parent / ref).resolve()
        if not source_image.exists():
            continue
        try:
            relative = source_image.relative_to(ROOT)
        except ValueError:
            continue
        return str(relative).replace("\\", "/")
    return None


def _github_url_for_howtocook_path(markdown_path: Path) -> str:
    relative = markdown_path.relative_to(ROOT / "HowToCook")
    encoded = "/".join(quote(part) for part in relative.parts)
    return f"https://github.com/Anduin2017/HowToCook/blob/master/{encoded}"


def build_from_howtocook(builder: UnifiedBuilder) -> None:
    if HOWTOCOOK_LOCAL_ROOT.exists():
        markdown_paths = sorted(
            path
            for path in HOWTOCOOK_LOCAL_ROOT.rglob("*.md")
            if path.name.lower() not in {"readme.md", "template.md"}
        )
        imported_count = 0
        for markdown_path in markdown_paths:
            relative_parts = markdown_path.relative_to(HOWTOCOOK_LOCAL_ROOT).parts
            if not relative_parts:
                continue
            raw_category = relative_parts[0]
            if raw_category == "template":
                continue
            cuisine = HOWTOCOOK_CATEGORY_LABELS.get(raw_category, raw_category)
            subcategory = ""
            if len(relative_parts) > 2:
                subcategory = markdown_path.parent.name

            markdown = markdown_path.read_text(encoding="utf-8", errors="ignore")
            name = _extract_markdown_title(markdown, markdown_path.stem)
            description = _extract_howtocook_intro(markdown)
            difficulty = _extract_howtocook_difficulty(markdown)
            ingredients = _parse_howtocook_ingredients(markdown)
            steps = _parse_howtocook_steps(markdown)
            if not ingredients or not steps:
                continue

            main_ingredients = [item["name"] for item in ingredients[:6]]
            labels = [
                item
                for item in [name, cuisine, raw_category, subcategory]
                if item
            ]
            dish_id = builder.get_or_create_dish(
                name,
                cuisine,
                main_ingredients,
                None,
                None,
                labels,
            )
            builder.add_dish_tag(dish_id, "howtocook_category", cuisine)
            builder.add_dish_tag(dish_id, "howtocook_source_category", raw_category)
            if subcategory and subcategory != name:
                builder.add_dish_tag(dish_id, "howtocook_subcategory", subcategory)
            builder.add_standard_dish_tags(
                dish_id,
                name,
                cuisine,
                labels,
                main_ingredients,
            )
            recipe_id = builder.insert_recipe_variant(
                dish_id=dish_id,
                source="howtocook",
                source_recipe_id=str(markdown_path.relative_to(ROOT)),
                title=name,
                description=description or f"来自 HowToCook 原项目的{cuisine}菜谱。",
                difficulty=difficulty,
                total_time_minutes=None,
                prep_time_minutes=None,
                cook_time_minutes=None,
                servings=1,
                cover_image_url=None,
            )
            builder.insert_ingredients(recipe_id, ingredients)
            builder.insert_steps(recipe_id, steps, description_key="description")
            imported_count += 1

        builder.stats["howtocook_recipes"] += imported_count
        return

    if not HOWTOCOOK_DB.exists():
        print("Skipping HowToCook import: database not found.")
        return
    conn = sqlite3.connect(HOWTOCOOK_DB)
    conn.row_factory = sqlite3.Row
    ingredient_rows = conn.execute(
        "SELECT recipe_id, name, amount, unit, is_main, order_index FROM howtocook_ingredients"
    ).fetchall()
    step_rows = conn.execute(
        "SELECT recipe_id, step_number, description, image_url, notes FROM howtocook_steps"
    ).fetchall()

    ingredients_by_recipe: Dict[str, List[Dict[str, Any]]] = {}
    for row in ingredient_rows:
        ingredients_by_recipe.setdefault(row["recipe_id"], []).append(
            {
                "name": row["name"],
                "amount": row["amount"],
                "unit": row["unit"],
                "preparation": None,
                "is_main": row["is_main"],
                "order_index": row["order_index"],
            }
        )

    steps_by_recipe: Dict[str, List[Dict[str, Any]]] = {}
    for row in step_rows:
        steps_by_recipe.setdefault(row["recipe_id"], []).append(
            {
                "step_number": row["step_number"],
                "description": row["description"],
                "image_url": row["image_url"],
                "notes": row["notes"],
            }
        )

    recipes = conn.execute("SELECT * FROM howtocook_recipes").fetchall()
    for row in recipes:
        ingredients = ingredients_by_recipe.get(row["id"], [])
        steps = steps_by_recipe.get(row["id"], [])
        main_ingredients = (
            [item["name"] for item in ingredients if item.get("is_main")] or [i["name"] for i in ingredients]
        )[:5]
        dish_id = builder.get_or_create_dish(
            row["name"],
            row["category"],
            main_ingredients,
            None,
            None,
            [tag for tag in [row["category"], row["subcategory"]] if tag],
        )
        builder.add_dish_tag(dish_id, "howtocook_category", row["category"])
        if row["subcategory"]:
            builder.add_dish_tag(dish_id, "howtocook_subcategory", row["subcategory"])
        builder.add_standard_dish_tags(
            dish_id,
            row["name"],
            row["category"],
            [tag for tag in [row["category"], row["subcategory"]] if tag],
            main_ingredients,
        )
        recipe_id = builder.insert_recipe_variant(
            dish_id=dish_id,
            source="howtocook",
            source_recipe_id=row["id"],
            title=row["name"],
            description=row["description"],
            difficulty=row["difficulty"],
            total_time_minutes=row["cooking_time"],
            prep_time_minutes=None,
            cook_time_minutes=None,
            servings=row["servings"],
            cover_image_url=None,
        )
        builder.insert_ingredients(recipe_id, ingredients)
        builder.insert_steps(recipe_id, steps, description_key="description")
    conn.close()
    builder.stats["howtocook_recipes"] += len(recipes)


def main() -> None:
    if UNIFIED_DB.exists():
        UNIFIED_DB.unlink()
    conn = sqlite3.connect(UNIFIED_DB)
    conn.row_factory = sqlite3.Row
    create_schema(conn)
    builder = UnifiedBuilder(conn)
    build_from_howtocook(builder)
    builder.populate_fts()
    builder.run_validation()
    conn.commit()
    conn.close()
    print(f"Unified database built at {UNIFIED_DB}")


if __name__ == "__main__":
    main()
