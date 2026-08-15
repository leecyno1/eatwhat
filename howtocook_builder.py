import os
import json
import re

# 配置路径
HOW_TO_COOK_PATH = "HowToCook/dishes"
OUTPUT_DIR = "assets/data"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "recipes.json")
TAGS_FILE = os.path.join(OUTPUT_DIR, "tags.json")

# 确保输出目录存在
os.makedirs(OUTPUT_DIR, exist_ok=True)

def parse_markdown_recipe(file_path):
    """
    解析单个 Markdown 菜谱文件
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 提取标题 (# 标题)
    title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
    title = title_match.group(1).strip() if title_match else os.path.basename(file_path).replace('.md', '')

    # 提取简介 (标题之后，第一个二级标题之前)
    intro = ""
    intro_match = re.search(r'^#\s+.+\n([\s\S]*?)(?=\n##)', content, re.MULTILINE)
    if intro_match:
        intro = intro_match.group(1).strip()

    # 提取原料 (## 必备原料... 下面的列表)
    ingredients = []
    ing_section_match = re.search(r'##\s+(必备原料|原料|材料).*?\n([\s\S]*?)(?=\n##)', content, re.MULTILINE)
    if ing_section_match:
        raw_ings = re.findall(r'-\s+(.+)', ing_section_match.group(2))
        for item in raw_ings:
            # 简单清洗，去除括号内的备注等
            clean_item = re.sub(r'（.*?）', '', item).strip()
            ingredients.append(clean_item)

    # 提取步骤 (## 操作... 下面的内容)
    steps = []
    steps_section_match = re.search(r'##\s+(操作|做法|步骤).*?\n([\s\S]*?)(?=\n##|$)', content, re.MULTILINE)
    if steps_section_match:
        raw_steps = steps_section_match.group(2).strip().split('\n')
        for step in raw_steps:
            if step.strip():
                steps.append(step.strip())

    # 估算难度 (根据步骤数量和原料数量简单估算)
    difficulty = "medium"
    if len(steps) < 5 and len(ingredients) < 5:
        difficulty = "easy"
    elif len(steps) > 10 or len(ingredients) > 10:
        difficulty = "hard"

    return {
        "id": title, # 暂时用标题作ID
        "name": title,
        "description": intro,
        "ingredients": ingredients,
        "steps": steps,
        "difficulty": difficulty,
        "source": "HowToCook"
    }

def build_database():
    recipes = []
    all_tags = set()
    
    # 遍历目录
    for root, dirs, files in os.walk(HOW_TO_COOK_PATH):
        for file in files:
            if file.endswith(".md") and file != "README.md" and file != "template.md":
                full_path = os.path.join(root, file)
                
                # 获取分类 (文件夹名)
                category = os.path.basename(root)
                if category == "dishes": continue # 跳过根目录
                
                try:
                    recipe = parse_markdown_recipe(full_path)
                    recipe["category"] = category
                    recipe["tags"] = [category] # 初始标签为分类名
                    
                    # 简单的标签推断
                    if "辣" in recipe["name"] or "辣" in recipe["description"]:
                        recipe["tags"].append("spicy")
                    if "甜" in recipe["name"]:
                        recipe["tags"].append("sweet")
                    if "汤" in recipe["name"]:
                        recipe["tags"].append("soup")
                    if "面" in recipe["name"]:
                        recipe["tags"].append("noodle")
                    if "饭" in recipe["name"]:
                        recipe["tags"].append("rice")
                    if "鸡" in recipe["name"]:
                        recipe["tags"].append("chicken")
                    if "牛" in recipe["name"]:
                        recipe["tags"].append("beef")
                    if "猪" in recipe["name"]:
                        recipe["tags"].append("pork")
                    if "鱼" in recipe["name"] or "虾" in recipe["name"] or "蟹" in recipe["name"]:
                        recipe["tags"].append("seafood")
                    
                    recipes.append(recipe)
                    all_tags.add(category)
                    
                    print(f"Parsed: {recipe['name']} ({category})")
                except Exception as e:
                    print(f"Error parsing {file}: {e}")

    # 保存菜谱库
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(recipes, f, ensure_ascii=False, indent=2)
    
    # 生成标签库结构
    tags_data = []
    for tag in all_tags:
        tags_data.append({
            "id": tag,
            "label": tag,
            "type": "category", # 默认为分类
            "color": "0xFF4CAF50", # 默认绿色
            "icon": "default"
        })
        
    # 添加一些预设的口味/营养标签
    presets = [
        {"id": "spicy", "label": "辣", "type": "flavor", "color": "0xFFF44336", "icon": "chili"},
        {"id": "sweet", "label": "甜", "type": "flavor", "color": "0xFFFF9800", "icon": "candy"},
        {"id": "sour", "label": "酸", "type": "flavor", "color": "0xFFCDDC39", "icon": "lemon"},
        {"id": "salty", "label": "咸", "type": "flavor", "color": "0xFF9E9E9E", "icon": "salt"},
        {"id": "low_carb", "label": "低碳", "type": "nutrition", "color": "0xFF8BC34A", "icon": "leaf"},
        {"id": "high_protein", "label": "高蛋白", "type": "nutrition", "color": "0xFF2196F3", "icon": "muscle"},
        {"id": "noodle", "label": "面食", "type": "category", "color": "0xFFFFC107", "icon": "bowl"},
        {"id": "rice", "label": "米饭", "type": "category", "color": "0xFFFFFFFF", "icon": "rice"},
        {"id": "chicken", "label": "鸡肉", "type": "ingredient", "color": "0xFFFFE082", "icon": "chicken"},
        {"id": "beef", "label": "牛肉", "type": "ingredient", "color": "0xFF795548", "icon": "cow"},
        {"id": "pork", "label": "猪肉", "type": "ingredient", "color": "0xFFF48FB1", "icon": "pig"},
        {"id": "seafood", "label": "海鲜", "type": "ingredient", "color": "0xFF29B6F6", "icon": "fish"},
    ]
    tags_data.extend(presets)

    with open(TAGS_FILE, 'w', encoding='utf-8') as f:
        json.dump(tags_data, f, ensure_ascii=False, indent=2)

    print(f"\nDatabase build complete!")
    print(f"Recipes: {len(recipes)} saved to {OUTPUT_FILE}")
    print(f"Tags: {len(tags_data)} saved to {TAGS_FILE}")

if __name__ == "__main__":
    build_database()
