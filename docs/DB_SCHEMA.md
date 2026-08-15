# 数据与索引设计（SQLite + Hive）

## SQLite（recipes.db）
```sql
-- 菜品
CREATE TABLE dish (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  cuisine TEXT,
  taste_vec TEXT,           -- JSON: {spicy:0.8, sour:0.2, ...}
  methods TEXT,             -- 逗号分隔/JSON: 炒,煮,炸
  calories INTEGER,
  time_minutes INTEGER,
  price_level INTEGER,      -- 1~5
  tags TEXT                 -- JSON 数组
);

-- 食材
CREATE TABLE ingredient (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  taste_hint TEXT           -- JSON 口味提示
);

-- 菜谱
CREATE TABLE recipe (
  id INTEGER PRIMARY KEY,
  dish_id INTEGER REFERENCES dish(id),
  ingredients TEXT,         -- JSON: [{name, qty, alt:[...]}]
  steps TEXT,               -- JSON: ["...","..."]
  utensils TEXT             -- JSON
);

-- FTS（名称/标签/食材）
CREATE VIRTUAL TABLE dish_fts USING fts5(name, tags, content='dish', content_rowid='id');
CREATE TRIGGER dish_ai AFTER INSERT ON dish BEGIN
  INSERT INTO dish_fts(rowid, name, tags) VALUES (new.id, new.name, new.tags);
END;
```

## Hive（本地状态）
- `PreferenceState`：w 向量、冷启动标记、探索参数 ε、最近交互时间。
- `Settings`：禁忌/过敏、预算、时长、器具、心情偏好。
