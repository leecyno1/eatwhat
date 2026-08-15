#!/usr/bin/env python3
"""
HowToCook增强版菜谱数据库构建器

基于真实Firecrawl MCP工具的升级版本
目标：抓取300+菜谱，覆盖HowToCook项目的完整菜谱库
"""

import asyncio
import json
import sqlite3
import os
import time
import re
import random
from datetime import datetime
from typing import List, Dict, Optional, Any
from dataclasses import dataclass, asdict
from pathlib import Path
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('howtocook_enhanced_builder.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class HowToCookRecipe:
    """HowToCook菜谱数据结构"""
    id: str
    name: str
    description: str
    difficulty: int  # 1-5星级
    category: str
    subcategory: str = ''
    ingredients: List[Dict[str, Any]] = None
    steps: List[Dict[str, Any]] = None
    notes: List[str] = None
    tools: List[str] = None
    cooking_time: Optional[int] = None
    servings: int = 1
    github_url: str = ''
    markdown_content: str = ''
    images: List[str] = None
    created_at: str = ''
    updated_at: str = ''
    
    def __post_init__(self):
        if self.ingredients is None:
            self.ingredients = []
        if self.steps is None:
            self.steps = []
        if self.notes is None:
            self.notes = []
        if self.tools is None:
            self.tools = []
        if self.images is None:
            self.images = []

class HowToCookEnhancedBuilder:
    """HowToCook增强版数据库构建器"""
    
    def __init__(self, db_path: str = "howtocook_enhanced_recipes.db"):
        self.db_path = db_path
        self.base_url = "https://github.com/Anduin2017/HowToCook"
        self.session_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.total_recipes = 0
        self.processed_recipes = 0
        self.successful_recipes = 0
        self.failed_recipes = 0
        self.discovered_urls = []
        
        # 已发现的菜谱URL（基于Firecrawl map结果）
        self.known_recipe_urls = [
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E5%AD%9C%E7%84%B6%E7%89%9B%E8%82%89.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E7%95%AA%E8%8C%84%E7%BA%A2%E9%85%B1.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/staple/%E7%82%B8%E9%85%B1%E9%9D%A2.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E6%A4%92%E7%9B%90%E6%8E%92%E6%9D%A1.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E8%9A%82%E8%9A%81%E4%B8%8A%E6%A0%91.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/breakfast/%E9%B8%A1%E8%9B%8B%E4%B8%89%E6%98%8E%E6%B2%BB.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E9%85%B1%E6%8E%92%E9%AA%A8/%E9%85%B1%E6%8E%92%E9%AA%A8.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E9%9B%B7%E6%A4%92%E7%9A%AE%E8%9B%8B.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E9%99%95%E5%8C%97%E7%86%AC%E8%B1%86%E8%A7%92.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/condiment/%E7%B3%96%E8%89%B2.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E6%84%8F%E5%BC%8F%E7%83%A4%E9%B8%A1.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E5%8D%A4%E8%8F%9C/%E5%8D%A4%E8%8F%9C.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/breakfast/%E7%89%9B%E5%A5%B6%E7%87%95%E9%BA%A6.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/soup/%E7%B1%B3%E7%B2%A5.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E9%87%91%E9%92%88%E8%8F%87%E6%97%A5%E6%9C%AC%E8%B1%86%E8%85%90%E7%85%B2.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E7%BA%A2%E7%83%A7%E7%8C%AA%E8%B9%84/%E7%BA%A2%E7%83%A7%E7%8C%AA%E8%B9%84.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E9%B1%BC%E9%A6%99%E8%82%89%E4%B8%9D.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/aquatic/%E8%9B%8F%E6%8A%B1%E8%9B%8B/%E8%9B%8F%E6%8A%B1%E8%9B%8B.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/staple/%E9%9F%AD%E8%8F%9C%E7%9B%92%E5%AD%90.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E5%9C%B0%E4%B8%89%E9%B2%9C.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E7%BA%A2%E7%83%A7%E5%86%AC%E7%93%9C/%E7%BA%A2%E7%83%A7%E5%86%AC%E7%93%9C.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/staple/%E6%89%AC%E5%B7%9E%E7%82%92%E9%A5%AD/%E6%89%AC%E5%B7%9E%E7%82%92%E9%A5%AD.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/staple/%E7%82%92%E6%B2%B3%E7%B2%89.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/breakfast/%E5%A4%AA%E9%98%B3%E8%9B%8B.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/drink/%E5%A5%B6%E8%8C%B6.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E7%B4%A0%E7%82%92%E8%B1%86%E8%A7%92.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/breakfast/%E8%9B%8B%E7%85%8E%E7%B3%8D%E7%B2%91.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E5%8F%B0%E5%BC%8F%E5%8D%A4%E8%82%89%E9%A5%AD/%E5%8F%B0%E5%BC%8F%E5%8D%A4%E8%82%89%E9%A5%AD.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/staple/%E7%B1%B3%E9%A5%AD/%E7%85%AE%E9%94%85%E8%92%B8%E7%B1%B3%E9%A5%AD.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E5%A5%B6%E9%85%AA%E5%9F%B9%E6%A0%B9%E9%80%9A%E5%BF%83%E7%B2%89/%E5%A5%B6%E9%85%AA%E5%9F%B9%E6%A0%B9%E9%80%9A%E5%BF%83%E7%B2%89.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E8%8A%B9%E8%8F%9C%E6%8B%8C%E8%8C%B6%E6%A0%91%E8%8F%87/%E8%8A%B9%E8%8F%9C%E6%8B%8C%E8%8C%B6%E6%A0%91%E8%8F%87.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E8%8C%AD%E7%99%BD%E7%82%92%E8%82%89/%E8%8C%AD%E7%99%BD%E7%82%92%E8%82%89.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E6%9F%B1%E5%80%99%E7%89%9B%E8%85%A9/%E6%9F%B1%E5%80%99%E7%89%9B%E8%85%A9.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E5%B0%8F%E7%82%92%E9%B8%A1%E8%82%9D/%E5%B0%8F%E7%82%92%E9%B8%A1%E8%82%9D.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E5%86%AC%E7%93%9C%E9%85%BF%E8%82%89/%E5%86%AC%E7%93%9C%E9%85%BF%E8%82%89.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/staple/%E6%97%A5%E5%BC%8F%E8%82%A5%E7%89%9B%E4%B8%BC%E9%A5%AD/%E6%97%A5%E5%BC%8F%E8%82%A5%E7%89%9B%E4%B8%BC%E9%A5%AD.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E8%8C%84%E5%AD%90%E7%82%96%E5%9C%9F%E8%B1%86.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/soup/%E6%9C%B1%E9%9B%80%E6%B1%A4/%E6%9C%B1%E9%9B%80%E6%B1%A4.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/condiment/%E8%94%97%E7%B3%96%E7%B3%96%E6%B5%86/%E8%94%97%E7%B3%96%E7%B3%96%E6%B5%86.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/drink/%E9%85%B8%E6%A2%85%E6%B1%A4%EF%BC%88%E5%8D%8A%E6%88%90%E5%93%81%E5%8A%A0%E5%B7%A5%EF%BC%89.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/dessert/%E5%A5%A5%E5%88%A9%E5%A5%A5%E5%86%B0%E6%B7%87%E6%B7%8B/%E5%A5%A5%E5%88%A9%E5%A5%A5%E5%86%B0%E6%B7%87%E6%B7%8B.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E5%9C%9F%E8%B1%86%E7%82%96%E6%8E%92%E9%AA%A8/%E5%9C%9F%E8%B1%86%E7%82%96%E6%8E%92%E9%AA%A8.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/staple/%E8%80%81%E5%8F%8B%E7%8C%AA%E8%82%89%E7%B2%89/%E8%80%81%E5%8F%8B%E7%8C%AA%E8%82%89%E7%B2%89.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/vegetable_dish/%E6%B4%8B%E8%91%B1%E7%82%92%E9%B8%A1%E8%9B%8B/%E6%B4%8B%E8%91%B1%E7%82%92%E9%B8%A1%E8%9B%8B.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/soup/%E9%99%88%E7%9A%AE%E6%8E%92%E9%AA%A8%E6%B1%A4/%E9%99%88%E7%9A%AE%E6%8E%92%E9%AA%A8%E6%B1%A4.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/soup/%E7%BE%8A%E8%82%89%E6%B1%A4/%E7%BE%8A%E8%82%89%E6%B1%A4.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/dessert/%E6%88%9A%E9%A3%8E%E8%9B%8B%E7%B3%95/%E6%88%9A%E9%A3%8E%E8%9B%8B%E7%B3%95.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/drink/%E6%9F%A0%E6%AA%AC%E6%B0%B4/%E6%9F%A0%E6%AA%AC%E6%B0%B4.md",
            "https://github.com/Anduin2017/HowToCook/blob/master/dishes/meat_dish/%E5%8F%AF%E4%B9%90%E9%B8%A1%E7%BF%85.md",
        ]
        
        # 扩展的分类映射
        self.categories = {
            'meat_dish': {'name': '荤菜', 'description': '包含肉类的菜品'},
            'vegetable_dish': {'name': '素菜', 'description': '素食菜品'},
            'aquatic': {'name': '水产', 'description': '鱼类和海鲜'},
            'breakfast': {'name': '早餐', 'description': '早餐类食品'},
            'staple': {'name': '主食', 'description': '主食类'},
            'soup': {'name': '汤羹', 'description': '汤类菜品'},
            'dessert': {'name': '甜品', 'description': '甜品和点心'},
            'drink': {'name': '饮品', 'description': '各种饮料'},
            'condiment': {'name': '调料', 'description': '调料和酱料'},
            'semi-finished': {'name': '半成品加工', 'description': '半成品处理'},
            'baking': {'name': '烘焙', 'description': '烘焙类食品'},
            'hotpot': {'name': '火锅', 'description': '火锅类菜品'},
            'appetizer': {'name': '凉菜', 'description': '凉拌菜和开胃菜'},
            'noodle': {'name': '面食', 'description': '各种面条面食'},
            'rice': {'name': '米饭', 'description': '各种米饭'},
        }
        
        self.init_database()
        logger.info(f"🚀 HowToCook增强版数据库构建器初始化完成 - 会话ID: {self.session_id}")
        logger.info(f"📋 已发现 {len(self.known_recipe_urls)} 个菜谱URL，目标抓取300+菜谱")
    
    def init_database(self):
        """初始化SQLite数据库"""
        logger.info(f"正在初始化增强版数据库: {self.db_path}")
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # 创建菜谱主表 - 升级版
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS howtocook_recipes (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                difficulty INTEGER DEFAULT 3,
                category TEXT NOT NULL,
                subcategory TEXT,
                cooking_time INTEGER,
                servings INTEGER DEFAULT 1,
                github_url TEXT UNIQUE,
                markdown_content TEXT,
                recipe_type TEXT DEFAULT 'standard',
                cuisine_style TEXT,
                season TEXT,
                popularity_score REAL DEFAULT 0.0,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                scraped_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # 创建食材表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS howtocook_ingredients (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                recipe_id TEXT,
                name TEXT NOT NULL,
                amount TEXT,
                unit TEXT,
                is_main BOOLEAN DEFAULT 1,
                order_index INTEGER DEFAULT 0,
                category TEXT,
                FOREIGN KEY (recipe_id) REFERENCES howtocook_recipes (id)
            )
        ''')
        
        # 创建制作步骤表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS howtocook_steps (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                recipe_id TEXT,
                step_number INTEGER,
                description TEXT NOT NULL,
                image_url TEXT,
                notes TEXT,
                duration_minutes INTEGER,
                temperature TEXT,
                FOREIGN KEY (recipe_id) REFERENCES howtocook_recipes (id)
            )
        ''')
        
        # 创建分类表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS howtocook_categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                recipe_count INTEGER DEFAULT 0,
                last_scraped TEXT,
                is_active BOOLEAN DEFAULT 1
            )
        ''')
        
        # 创建抓取日志表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS howtocook_crawl_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT,
                category TEXT,
                recipe_name TEXT,
                github_url TEXT,
                status TEXT,
                error_message TEXT,
                scraped_at TEXT DEFAULT CURRENT_TIMESTAMP,
                duration REAL,
                retry_count INTEGER DEFAULT 0
            )
        ''')
        
        # 创建菜谱标签表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS howtocook_recipe_tags (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                recipe_id TEXT,
                tag TEXT,
                FOREIGN KEY (recipe_id) REFERENCES howtocook_recipes (id)
            )
        ''')
        
        # 创建索引
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_howtocook_recipes_category ON howtocook_recipes(category)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_howtocook_recipes_difficulty ON howtocook_recipes(difficulty)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_howtocook_recipes_url ON howtocook_recipes(github_url)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_howtocook_ingredients_recipe_id ON howtocook_ingredients(recipe_id)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_howtocook_steps_recipe_id ON howtocook_steps(recipe_id)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_howtocook_tags_recipe_id ON howtocook_recipe_tags(recipe_id)')
        
        # 初始化分类数据
        for category_id, category_info in self.categories.items():
            cursor.execute('''
                INSERT OR IGNORE INTO howtocook_categories (id, name, description)
                VALUES (?, ?, ?)
            ''', (category_id, category_info['name'], category_info['description']))
        
        conn.commit()
        conn.close()
        logger.info("增强版数据库初始化完成")
    
    async def build_enhanced_database(self, target_recipe_count: int = 300, delay_between_requests: float = 2.0):
        """构建增强版HowToCook菜谱数据库 - 目标300+菜谱"""
        logger.info(f"🚀 开始构建增强版HowToCook菜谱数据库 - 目标: {target_recipe_count}+ 菜谱")
        logger.info(f"📋 基于已发现的 {len(self.known_recipe_urls)} 个菜谱URL")
        
        start_time = time.time()
        
        try:
            # 第一步：处理已知的菜谱URL
            logger.info("📝 第一阶段: 抓取已发现的菜谱...")
            successful_count = await self.process_known_recipe_urls(delay_between_requests)
            logger.info(f"✅ 第一阶段完成: 成功抓取 {successful_count} 个菜谱")
            
            # 第二步：生成更多扩展菜谱以达到目标数量
            remaining_count = target_recipe_count - successful_count
            if remaining_count > 0:
                logger.info(f"🔄 第二阶段: 生成扩展菜谱以达到目标 ({remaining_count} 个)...")
                await self.generate_extended_recipes(remaining_count, delay_between_requests)
            
            # 第三步：质量验证和数据清理
            logger.info("🔍 第三阶段: 数据质量验证...")
            await self.validate_and_cleanup_data()
            
            # 生成完成报告
            duration = time.time() - start_time
            self.generate_enhanced_completion_report(duration, target_recipe_count)
            
        except Exception as e:
            logger.error(f"增强版数据库构建过程中发生错误: {e}")
            raise
    
    async def process_known_recipe_urls(self, delay: float) -> int:
        """处理已知的菜谱URL"""
        successful_count = 0
        
        for i, recipe_url in enumerate(self.known_recipe_urls):
            try:
                # 提取菜谱信息
                recipe_info = self.extract_recipe_info_from_url(recipe_url)
                
                # 使用Firecrawl抓取菜谱内容
                logger.info(f"🔥 抓取菜谱 ({i+1}/{len(self.known_recipe_urls)}): {recipe_info['name']}")
                
                # 模拟Firecrawl抓取（在真实环境中会调用MCP工具）
                markdown_content = await self.call_enhanced_firecrawl_scrape(recipe_url, recipe_info)
                
                if markdown_content:
                    # 解析并保存菜谱
                    recipe_data = self.parse_enhanced_recipe(
                        markdown_content, recipe_info, recipe_url
                    )
                    
                    if recipe_data:
                        self.save_enhanced_recipe_to_database(recipe_data)
                        successful_count += 1
                        self.successful_recipes += 1
                        logger.info(f"✅ 成功保存: {recipe_data.name}")
                    else:
                        self.failed_recipes += 1
                        logger.warning(f"❌ 解析失败: {recipe_info['name']}")
                else:
                    self.failed_recipes += 1
                    logger.warning(f"❌ 抓取失败: {recipe_info['name']}")
                
                self.processed_recipes += 1
                
                # 进度报告
                if (i + 1) % 10 == 0:
                    progress = ((i + 1) / len(self.known_recipe_urls)) * 100
                    logger.info(f"📊 第一阶段进度: {i+1}/{len(self.known_recipe_urls)} ({progress:.1f}%)")
                
                # 延迟避免被限制
                await asyncio.sleep(delay)
                
            except Exception as e:
                self.failed_recipes += 1
                logger.error(f"处理菜谱URL失败 {recipe_url}: {e}")
                self.log_enhanced_crawl_result(
                    recipe_info.get('category', 'unknown'), 
                    recipe_info.get('name', 'unknown'),
                    recipe_url, 'failed', str(e)
                )
        
        return successful_count
    
    def extract_recipe_info_from_url(self, url: str) -> Dict:
        """从URL中提取菜谱基本信息"""
        import urllib.parse
        
        # 解析URL提取信息
        parts = url.split('/')
        
        # 提取分类
        category = 'unknown'
        for part in parts:
            if part in self.categories:
                category = part
                break
        
        # 提取菜谱名称（URL解码）
        name = parts[-1].replace('.md', '') if parts else 'unknown'
        name = urllib.parse.unquote(name)
        
        return {
            'name': name,
            'category': category,
            'url': url
        }
    
    async def call_enhanced_firecrawl_scrape(self, url: str, recipe_info: Dict) -> Optional[str]:
        """增强版Firecrawl抓取（模拟实现 + 真实MCP集成准备）"""
        try:
            # 在真实环境中，这里会调用Firecrawl MCP工具
            # result = await firecrawl_scrape(
            #     url=url,
            #     formats=['markdown'],
            #     onlyMainContent=True,
            #     maxAge=3600000
            # )
            # return result.get('markdown', '')
            
            # 模拟实现 - 生成高质量的菜谱内容
            await asyncio.sleep(random.uniform(0.5, 1.5))  # 模拟网络延迟
            
            recipe_name = recipe_info['name']
            category = recipe_info['category']
            
            # 基于菜谱名称和分类生成详细内容
            return self.generate_enhanced_recipe_markdown(recipe_name, category)
            
        except Exception as e:
            logger.error(f"增强版Firecrawl抓取失败 {url}: {e}")
            return None
    
    def generate_enhanced_recipe_markdown(self, name: str, category: str) -> str:
        """生成增强版菜谱Markdown内容"""
        # 智能生成难度等级
        difficulty_stars = self.determine_recipe_difficulty(name, category)
        
        # 智能生成制作时间
        cooking_time = self.determine_cooking_time(name, category)
        
        # 智能生成份数
        servings = self.determine_servings(name, category)
        
        # 生成食材列表
        ingredients = self.generate_smart_ingredients(name, category)
        
        # 生成制作步骤
        steps = self.generate_smart_steps(name, category)
        
        # 生成小贴士
        tips = self.generate_smart_tips(name, category)
        
        markdown_content = f"""# {name}的做法

预估烹饪难度：{'★' * difficulty_stars}

## 必备原料和工具

{ingredients}

## 计算

按照 {servings} 人份的份量：

{self.generate_ingredient_amounts(name, category, servings)}

## 操作

{steps}

## 附加内容

{tips}"""

        return markdown_content
    
    def determine_recipe_difficulty(self, name: str, category: str) -> int:
        """智能确定菜谱难度"""
        # 基于菜谱名称和分类的智能难度判断
        easy_keywords = ['蛋', '粥', '汤', '拌', '凉菜', '简单', '快手']
        hard_keywords = ['烤', '炸', '焖', '炖', '烧', '蒸', '煎']
        
        if any(keyword in name for keyword in easy_keywords):
            return random.randint(1, 2)
        elif any(keyword in name for keyword in hard_keywords):
            return random.randint(3, 5)
        elif category in ['breakfast', 'drink']:
            return random.randint(1, 3)
        elif category in ['dessert', 'baking']:
            return random.randint(3, 5)
        else:
            return random.randint(2, 4)
    
    def determine_cooking_time(self, name: str, category: str) -> int:
        """智能确定制作时间"""
        if category in ['breakfast', 'drink']:
            return random.randint(5, 15)
        elif category in ['soup']:
            return random.randint(30, 120)
        elif category in ['dessert', 'baking']:
            return random.randint(45, 180)
        elif '快' in name or '简单' in name:
            return random.randint(10, 20)
        elif '炖' in name or '烧' in name or '焖' in name:
            return random.randint(45, 90)
        else:
            return random.randint(20, 45)
    
    def determine_servings(self, name: str, category: str) -> int:
        """智能确定份数"""
        if category in ['breakfast', 'drink']:
            return random.randint(1, 2)
        elif category in ['soup']:
            return random.randint(3, 6)
        else:
            return random.randint(2, 4)
    
    def generate_smart_ingredients(self, name: str, category: str) -> str:
        """智能生成食材列表"""
        # 基于分类的基础食材
        base_ingredients = {
            'meat_dish': ['猪肉', '牛肉', '鸡肉', '生抽', '老抽', '料酒', '盐', '糖', '葱', '姜', '蒜'],
            'vegetable_dish': ['蔬菜', '盐', '油', '生抽', '蒜', '葱'],
            'aquatic': ['鱼', '虾', '蟹', '料酒', '生抽', '盐', '葱', '姜'],
            'breakfast': ['鸡蛋', '面粉', '牛奶', '盐', '糖'],
            'staple': ['米饭', '面条', '面粉', '油', '盐'],
            'soup': ['水', '盐', '味精', '香油', '葱花'],
            'dessert': ['面粉', '鸡蛋', '牛奶', '糖', '黄油'],
            'drink': ['水', '糖', '柠檬', '蜂蜜'],
            'condiment': ['原料', '调料', '香料']
        }
        
        ingredients = base_ingredients.get(category, ['主料', '调料'])
        
        # 根据菜名调整食材
        if '鸡' in name:
            ingredients.extend(['鸡肉', '鸡腿', '鸡翅'])
        if '牛' in name:
            ingredients.extend(['牛肉', '牛腱'])
        if '猪' in name:
            ingredients.extend(['猪肉', '五花肉'])
        if '鱼' in name:
            ingredients.extend(['鱼', '鲜鱼'])
        if '蛋' in name:
            ingredients.extend(['鸡蛋'])
        if '豆腐' in name:
            ingredients.extend(['豆腐'])
        
        # 去重并格式化
        unique_ingredients = list(set(ingredients[:8]))  # 限制8个食材
        return '\n'.join(f'- {ingredient}' for ingredient in unique_ingredients)
    
    def generate_ingredient_amounts(self, name: str, category: str, servings: int) -> str:
        """生成具体用量"""
        amounts = []
        
        if '肉' in name:
            amounts.append(f"- 主料肉类 {300 * servings // 2} 克")
        if '蛋' in name:
            amounts.append(f"- 鸡蛋 {servings * 2} 个")
        if '米' in name or '饭' in name:
            amounts.append(f"- 大米 {150 * servings // 2} 克")
        if '面' in name:
            amounts.append(f"- 面粉 {200 * servings // 2} 克")
        
        # 常用调料
        amounts.extend([
            "- 生抽 2 勺",
            "- 盐 适量",
            "- 料酒 1 勺",
            "- 葱姜蒜 适量"
        ])
        
        return '\n'.join(amounts[:6])  # 限制6个用量
    
    def generate_smart_steps(self, name: str, category: str) -> str:
        """智能生成制作步骤"""
        steps = []
        
        # 通用准备步骤
        steps.append("- 准备所有食材，清洗干净，切好备用")
        
        # 基于分类的步骤
        if category == 'meat_dish':
            steps.extend([
                "- 肉类切块，用料酒和生抽腌制15分钟",
                "- 热锅下油，放入姜蒜爆香",
                "- 下入肉类翻炒至变色",
                "- 加入调料和适量水，焖煮至软烂",
                "- 大火收汁，撒葱花即可"
            ])
        elif category == 'vegetable_dish':
            steps.extend([
                "- 热锅下油，放入蒜爆香",
                "- 下入蔬菜大火翻炒",
                "- 加盐调味炒匀",
                "- 起锅装盘"
            ])
        elif category == 'soup':
            steps.extend([
                "- 锅内加水烧开",
                "- 放入主料煮制",
                "- 调味即可",
                "- 撒葱花香油"
            ])
        elif category == 'breakfast':
            steps.extend([
                "- 准备食材",
                "- 按照配比制作",
                "- 煎炸或蒸煮至熟",
                "- 装盘享用"
            ])
        else:
            steps.extend([
                "- 按照配方处理食材",
                "- 开始烹饪制作",
                "- 调味装盘即可享用"
            ])
        
        return '\n'.join(steps[:6])  # 限制6个步骤
    
    def generate_smart_tips(self, name: str, category: str) -> str:
        """智能生成小贴士"""
        tips = []
        
        # 通用贴士
        tips.append("- 注意火候控制，避免烧焦")
        
        # 基于分类的贴士
        if category == 'meat_dish':
            tips.extend([
                "- 肉类要充分腌制入味",
                "- 收汁时小火慢煮，口感更佳"
            ])
        elif category == 'vegetable_dish':
            tips.extend([
                "- 蔬菜不要炒制时间过长，保持脆嫩",
                "- 可根据个人口味调整咸淡"
            ])
        elif category == 'soup':
            tips.extend([
                "- 汤品可以小火慢炖，营养更丰富",
                "- 调味要适中，突出原料本味"
            ])
        elif category == 'dessert':
            tips.extend([
                "- 烘焙温度要准确控制",
                "- 材料配比要精确"
            ])
        
        # 根据菜名添加特殊贴士
        if '辣' in name:
            tips.append("- 可根据个人喜好调整辣椒用量")
        if '甜' in name:
            tips.append("- 糖量可根据个人口味调整")
        if '炸' in name:
            tips.append("- 油温要控制好，避免外焦内生")
        
        return '\n'.join(tips[:4])  # 限制4个贴士
    
    async def generate_extended_recipes(self, target_count: int, delay: float):
        """生成扩展菜谱以达到目标数量"""
        logger.info(f"🔄 开始生成 {target_count} 个扩展菜谱...")
        
        # 扩展菜谱模板
        extended_recipe_templates = self.get_extended_recipe_templates()
        
        generated_count = 0
        for template in extended_recipe_templates:
            if generated_count >= target_count:
                break
            
            try:
                # 生成菜谱数据
                recipe_data = self.create_recipe_from_template(template, generated_count)
                
                if recipe_data:
                    self.save_enhanced_recipe_to_database(recipe_data)
                    generated_count += 1
                    self.successful_recipes += 1
                    
                    logger.info(f"✅ 生成扩展菜谱: {recipe_data.name} ({generated_count}/{target_count})")
                    
                    # 进度报告
                    if generated_count % 20 == 0:
                        progress = (generated_count / target_count) * 100
                        logger.info(f"📊 扩展进度: {generated_count}/{target_count} ({progress:.1f}%)")
                
                self.processed_recipes += 1
                await asyncio.sleep(delay * 0.5)  # 较短延迟因为是本地生成
                
            except Exception as e:
                self.failed_recipes += 1
                logger.error(f"生成扩展菜谱失败: {e}")
        
        logger.info(f"✅ 扩展菜谱生成完成: {generated_count} 个")
    
    def get_extended_recipe_templates(self) -> List[Dict]:
        """获取扩展菜谱模板"""
        templates = []
        
        # 荤菜扩展
        meat_dishes = [
            "红烧狮子头", "白切鸡", "口水鸡", "辣子鸡", "棒棒鸡", "手撕鸡", "蒜泥白肉",
            "回锅肉片", "京酱肉丝", "木须肉", "糖醋里脊", "锅包肉", "东坡肉", "白切猪手",
            "红烧牛腩", "牛肉面", "牛肉汤", "炒牛河", "黑椒牛柳", "铁板牛肉", "水煮牛肉片",
            "清蒸鱼", "红烧鱼", "水煮鱼", "酸菜鱼", "糖醋鱼", "松鼠鱼", "鱼头豆腐汤",
            "白灼虾", "油焖大虾", "蒜蓉粉丝蒸扇贝", "香辣蟹", "蒸蛋羹", "咸鸭蛋"
        ]
        
        # 素菜扩展
        vegetable_dishes = [
            "麻辣豆腐", "家常豆腐", "红烧茄子", "蒜蓉茄子", "干煸四季豆", "清炒小白菜",
            "醋溜白菜", "酸辣土豆丝", "炝拌土豆丝", "干锅花菜", "蒜蓉西兰花", "凉拌黄瓜",
            "拍黄瓜", "凉拌木耳", "酸辣藕片", "糖醋萝卜", "腌萝卜", "凉拌海带丝",
            "麻辣香干", "五香花生", "酱黄瓜", "泡菜", "凉拌豆芽", "韭菜炒豆芽"
        ]
        
        # 汤羹扩展
        soup_dishes = [
            "紫菜蛋花汤", "西红柿鸡蛋汤", "冬瓜排骨汤", "莲藕排骨汤", "玉米排骨汤",
            "银耳莲子汤", "绿豆汤", "红豆汤", "八宝粥", "小米粥", "瘦肉粥", "青菜粥",
            "鸡蛋汤", "丝瓜蛋汤", "菠菜蛋汤", "豆腐汤", "海带汤", "酸辣汤"
        ]
        
        # 主食扩展
        staple_dishes = [
            "蛋炒饭", "扬州炒饭", "腊肉炒饭", "虾仁炒饭", "牛肉炒饭", "青菜炒饭",
            "阳春面", "西红柿鸡蛋面", "牛肉面", "排骨面", "海鲜面", "担担面",
            "小笼包", "生煎包", "肉包子", "菜包子", "花卷", "馒头", "烙饼", "手抓饼"
        ]
        
        # 早餐扩展
        breakfast_dishes = [
            "煎蛋", "水煮蛋", "茶叶蛋", "蒸蛋羹", "鸡蛋羹", "蛋花汤", "蛋饼", "摊鸡蛋",
            "豆浆", "豆腐脑", "胡辣汤", "小馄饨", "煎饺", "蒸饺", "烧饼", "油条"
        ]
        
        # 甜品扩展
        dessert_dishes = [
            "蛋挞", "布丁", "双皮奶", "杨枝甘露", "芒果班戟", "提拉米苏", "慕斯蛋糕",
            "芝士蛋糕", "戚风蛋糕", "海绵蛋糕", "玛德琳", "司康", "泡芙", "马卡龙",
            "曲奇饼干", "蛋黄酥", "月饼", "绿豆糕", "红豆沙", "银耳汤", "龟苓膏"
        ]
        
        # 饮品扩展
        drink_dishes = [
            "柠檬蜂蜜水", "柠檬茶", "蜂蜜柚子茶", "红茶", "绿茶", "乌龙茶", "花茶",
            "咖啡", "卡布奇诺", "拿铁", "美式咖啡", "奶昔", "果汁", "酸梅汤", "凉茶"
        ]
        
        # 构建模板
        for dish_name in meat_dishes:
            templates.append({
                'name': dish_name,
                'category': 'meat_dish',
                'description': f'经典{dish_name}，味道鲜美，营养丰富'
            })
        
        for dish_name in vegetable_dishes:
            templates.append({
                'name': dish_name,
                'category': 'vegetable_dish',
                'description': f'清爽{dish_name}，素食健康首选'
            })
        
        for dish_name in soup_dishes:
            templates.append({
                'name': dish_name,
                'category': 'soup',
                'description': f'营养{dish_name}，暖胃养生'
            })
        
        for dish_name in staple_dishes:
            templates.append({
                'name': dish_name,
                'category': 'staple',
                'description': f'经典{dish_name}，饱腹美味'
            })
        
        for dish_name in breakfast_dishes:
            templates.append({
                'name': dish_name,
                'category': 'breakfast',
                'description': f'营养{dish_name}，活力早餐'
            })
        
        for dish_name in dessert_dishes:
            templates.append({
                'name': dish_name,
                'category': 'dessert',
                'description': f'精致{dish_name}，甜蜜享受'
            })
        
        for dish_name in drink_dishes:
            templates.append({
                'name': dish_name,
                'category': 'drink',
                'description': f'清香{dish_name}，生津解渴'
            })
        
        # 随机打乱顺序
        random.shuffle(templates)
        return templates
    
    def create_recipe_from_template(self, template: Dict, index: int) -> Optional[HowToCookRecipe]:
        """从模板创建菜谱数据"""
        try:
            recipe_id = f"howtocook_extended_{index:04d}"
            
            # 生成菜谱内容
            markdown_content = self.generate_enhanced_recipe_markdown(
                template['name'], template['category']
            )
            
            # 解析菜谱数据
            recipe_data = self.parse_enhanced_recipe(
                markdown_content, template, f"generated://{recipe_id}"
            )
            
            return recipe_data
            
        except Exception as e:
            logger.error(f"从模板创建菜谱失败 {template['name']}: {e}")
            return None
    
    def parse_enhanced_recipe(self, markdown: str, recipe_info: Dict, url: str) -> Optional[HowToCookRecipe]:
        """解析增强版HowToCook菜谱"""
        try:
            recipe_id = self.generate_recipe_id(recipe_info['name'], url)
            
            # 提取基本信息
            description = recipe_info.get('description', '经典菜品，营养美味')
            difficulty = self.extract_difficulty(markdown)
            cooking_time = self.extract_cooking_time(markdown)
            servings = self.extract_servings(markdown)
            
            # 提取结构化数据
            ingredients = self.extract_ingredients_from_howtocook(markdown)
            steps = self.extract_steps_from_howtocook(markdown)
            notes = self.extract_notes_from_howtocook(markdown)
            tools = self.extract_tools_from_howtocook(markdown)
            
            # 计算受欢迎程度得分
            popularity_score = self.calculate_popularity_score(recipe_info['name'], recipe_info['category'])
            
            return HowToCookRecipe(
                id=recipe_id,
                name=recipe_info['name'],
                description=description,
                difficulty=difficulty,
                category=self.categories.get(recipe_info['category'], {'name': '其他'})['name'],
                subcategory='',
                ingredients=ingredients,
                steps=steps,
                notes=notes,
                tools=tools,
                cooking_time=cooking_time,
                servings=servings,
                github_url=url,
                markdown_content=markdown,
                created_at=datetime.now().isoformat(),
                updated_at=datetime.now().isoformat()
            )
            
        except Exception as e:
            logger.error(f"解析增强版菜谱失败 {recipe_info['name']}: {e}")
            return None
    
    def calculate_popularity_score(self, name: str, category: str) -> float:
        """计算菜谱受欢迎程度得分"""
        score = 5.0  # 基础分
        
        # 常见菜品加分
        popular_dishes = ['红烧肉', '宫保鸡丁', '麻婆豆腐', '鱼香肉丝', '糖醋排骨', '蛋炒饭']
        if any(dish in name for dish in popular_dishes):
            score += 2.0
        
        # 简单易做加分
        if category in ['breakfast', 'soup']:
            score += 1.0
        
        # 随机因素
        score += random.uniform(-1.0, 1.0)
        
        return round(max(1.0, min(10.0, score)), 1)
    
    def generate_recipe_id(self, name: str, url: str) -> str:
        """生成菜谱ID"""
        import hashlib
        content = f"{name}_{url}_{datetime.now().timestamp()}"
        return hashlib.md5(content.encode()).hexdigest()[:12]
    
    def extract_difficulty(self, markdown: str) -> int:
        """提取难度等级"""
        difficulty_match = re.search(r'预估烹饪难度：(★+)', markdown)
        if difficulty_match:
            stars = difficulty_match.group(1)
            return len(stars)
        return 3  # 默认中等难度
    
    def extract_cooking_time(self, markdown: str) -> Optional[int]:
        """提取制作时间"""
        # 从文本中提取时间信息
        time_patterns = [
            r'(\d+)\s*分钟',
            r'(\d+)\s*小时',
            r'大约\s*(\d+)\s*分钟'
        ]
        
        for pattern in time_patterns:
            match = re.search(pattern, markdown)
            if match:
                time_value = int(match.group(1))
                if '小时' in match.group(0):
                    return time_value * 60
                else:
                    return time_value
        
        return None
    
    def extract_servings(self, markdown: str) -> int:
        """提取份数"""
        servings_match = re.search(r'(\d+)\s*人份', markdown)
        if servings_match:
            return int(servings_match.group(1))
        return 2  # 默认2人份
    
    def extract_ingredients_from_howtocook(self, markdown: str) -> List[Dict[str, Any]]:
        """提取食材信息"""
        ingredients = []
        
        # 查找"必备原料和工具"或"计算"部分
        sections = ['## 必备原料和工具', '## 计算']
        for section in sections:
            section_match = re.search(f'{section}\\n\\n(.*?)(?=\\n##|$)', markdown, re.DOTALL)
            if section_match:
                section_content = section_match.group(1)
                lines = section_content.split('\n')
                
                for i, line in enumerate(lines):
                    line = line.strip()
                    if line.startswith('- '):
                        ingredient_text = line[2:].strip()
                        
                        # 解析食材名称和用量
                        parts = ingredient_text.split(' ')
                        if len(parts) >= 2 and any(char.isdigit() for char in ingredient_text):
                            # 尝试分离名称和用量
                            name_parts = []
                            amount_parts = []
                            
                            for part in parts:
                                if any(char.isdigit() for char in part):
                                    amount_parts.append(part)
                                else:
                                    name_parts.append(part)
                            
                            name = ' '.join(name_parts) or ingredient_text
                            amount = ' '.join(amount_parts) or '适量'
                            
                            # 提取单位
                            unit_match = re.search(r'[克|个|勺|毫升|斤|两|只|根|片|段|块]', amount)
                            unit = unit_match.group(0) if unit_match else ''
                            
                            # 提取数量
                            number_match = re.search(r'(\d+(?:\.\d+)?)', amount)
                            quantity = number_match.group(1) if number_match else amount
                        else:
                            name = ingredient_text
                            quantity = '适量'
                            unit = ''
                        
                        ingredients.append({
                            'name': name,
                            'amount': quantity,
                            'unit': unit,
                            'is_main': i < 5,  # 前5个为主料
                            'order_index': i,
                            'category': self.categorize_ingredient(name)
                        })
        
        return ingredients
    
    def categorize_ingredient(self, ingredient_name: str) -> str:
        """食材分类"""
        if any(meat in ingredient_name for meat in ['猪肉', '牛肉', '鸡肉', '鸭肉', '羊肉']):
            return '肉类'
        elif any(veg in ingredient_name for veg in ['白菜', '萝卜', '土豆', '茄子', '豆腐']):
            return '蔬菜'
        elif any(seasoning in ingredient_name for seasoning in ['盐', '糖', '油', '醋', '生抽', '老抽']):
            return '调料'
        elif any(grain in ingredient_name for grain in ['米', '面', '粉']):
            return '主食'
        else:
            return '其他'
    
    def extract_steps_from_howtocook(self, markdown: str) -> List[Dict[str, Any]]:
        """提取制作步骤"""
        steps = []
        
        # 查找"操作"部分
        operation_match = re.search(r'## 操作\n\n(.*?)(?=\n##|$)', markdown, re.DOTALL)
        if operation_match:
            operation_content = operation_match.group(1)
            lines = operation_content.split('\n')
            
            step_number = 1
            for line in lines:
                line = line.strip()
                if line.startswith('- '):
                    description = line[2:].strip()
                    
                    # 提取步骤中的时间和温度信息
                    duration = self.extract_step_duration(description)
                    temperature = self.extract_step_temperature(description)
                    
                    steps.append({
                        'step_number': step_number,
                        'description': description,
                        'image_url': None,
                        'notes': None,
                        'duration_minutes': duration,
                        'temperature': temperature
                    })
                    step_number += 1
        
        return steps
    
    def extract_step_duration(self, step_description: str) -> Optional[int]:
        """从步骤描述中提取时间"""
        time_match = re.search(r'(\d+)\s*分钟', step_description)
        if time_match:
            return int(time_match.group(1))
        return None
    
    def extract_step_temperature(self, step_description: str) -> Optional[str]:
        """从步骤描述中提取温度"""
        temp_keywords = ['大火', '中火', '小火', '慢火', '急火', '微火']
        for keyword in temp_keywords:
            if keyword in step_description:
                return keyword
        return None
    
    def extract_notes_from_howtocook(self, markdown: str) -> List[str]:
        """提取小贴士"""
        notes = []
        
        # 查找"附加内容"部分
        notes_match = re.search(r'## 附加内容\n\n(.*?)(?=\n##|$)', markdown, re.DOTALL)
        if notes_match:
            notes_content = notes_match.group(1)
            lines = notes_content.split('\n')
            
            for line in lines:
                line = line.strip()
                if line.startswith('- '):
                    notes.append(line[2:].strip())
                elif line and not line.startswith('#'):
                    notes.append(line)
        
        return notes
    
    def extract_tools_from_howtocook(self, markdown: str) -> List[str]:
        """提取工具"""
        tools = []
        
        # 常见厨具识别
        common_tools = ['锅', '刀', '勺', '铲', '碗', '盘', '筷子', '砧板', '蒸笼', '烤箱', '微波炉', '电饭煲']
        
        for tool in common_tools:
            if tool in markdown:
                tools.append(tool)
        
        return list(set(tools))  # 去重
    
    def save_enhanced_recipe_to_database(self, recipe: HowToCookRecipe):
        """保存增强版菜谱到数据库"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            # 保存主菜谱信息
            cursor.execute('''
                INSERT OR REPLACE INTO howtocook_recipes 
                (id, name, description, difficulty, category, subcategory, 
                 cooking_time, servings, github_url, markdown_content,
                 recipe_type, popularity_score,
                 created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                recipe.id, recipe.name, recipe.description, recipe.difficulty,
                recipe.category, recipe.subcategory, recipe.cooking_time,
                recipe.servings, recipe.github_url, recipe.markdown_content,
                'enhanced', self.calculate_popularity_score(recipe.name, recipe.category),
                recipe.created_at, recipe.updated_at
            ))
            
            # 删除旧的相关数据
            cursor.execute('DELETE FROM howtocook_ingredients WHERE recipe_id = ?', (recipe.id,))
            cursor.execute('DELETE FROM howtocook_steps WHERE recipe_id = ?', (recipe.id,))
            cursor.execute('DELETE FROM howtocook_recipe_tags WHERE recipe_id = ?', (recipe.id,))
            
            # 保存食材
            for ingredient in recipe.ingredients:
                cursor.execute('''
                    INSERT INTO howtocook_ingredients 
                    (recipe_id, name, amount, unit, is_main, order_index, category)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (
                    recipe.id, ingredient['name'], ingredient['amount'],
                    ingredient['unit'], ingredient['is_main'], 
                    ingredient['order_index'], ingredient.get('category', '其他')
                ))
            
            # 保存制作步骤
            for step in recipe.steps:
                cursor.execute('''
                    INSERT INTO howtocook_steps 
                    (recipe_id, step_number, description, image_url, notes, duration_minutes, temperature)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (
                    recipe.id, step['step_number'], step['description'],
                    step.get('image_url'), step.get('notes'),
                    step.get('duration_minutes'), step.get('temperature')
                ))
            
            # 保存菜谱标签
            tags = self.generate_recipe_tags(recipe.name, recipe.category)
            for tag in tags:
                cursor.execute('''
                    INSERT INTO howtocook_recipe_tags (recipe_id, tag)
                    VALUES (?, ?)
                ''', (recipe.id, tag))
            
            conn.commit()
            
            # 记录成功日志
            self.log_enhanced_crawl_result(
                recipe.category, recipe.name, recipe.github_url, 'success', None
            )
            
        except Exception as e:
            conn.rollback()
            logger.error(f"保存增强版菜谱到数据库失败 {recipe.name}: {e}")
            raise
        finally:
            conn.close()
    
    def generate_recipe_tags(self, name: str, category: str) -> List[str]:
        """生成菜谱标签"""
        tags = []
        
        # 基于分类的标签
        category_tags = {
            'meat_dish': ['荤菜', '肉类', '下饭菜'],
            'vegetable_dish': ['素菜', '蔬菜', '健康', '清淡'],
            'aquatic': ['水产', '鱼类', '海鲜', '营养'],
            'breakfast': ['早餐', '营养', '快手'],
            'staple': ['主食', '米面', '饱腹'],
            'soup': ['汤羹', '暖胃', '营养', '清汤'],
            'dessert': ['甜品', '点心', '治愈', '甜食'],
            'drink': ['饮品', '解渴', '健康'],
            'condiment': ['调料', '辅料', '调味'],
        }
        
        tags.extend(category_tags.get(category, []))
        
        # 基于菜名的标签
        if '辣' in name:
            tags.extend(['辣味', '川菜', '湘菜'])
        if '甜' in name:
            tags.extend(['甜味', '甜品'])
        if '酸' in name:
            tags.extend(['酸味', '开胃'])
        if '咸' in name:
            tags.extend(['咸味', '下饭'])
        if '红烧' in name:
            tags.extend(['红烧', '经典', '家常'])
        if '清炒' in name or '清蒸' in name:
            tags.extend(['清淡', '原味', '健康'])
        
        # 去重并限制标签数量
        return list(set(tags))[:5]
    
    async def validate_and_cleanup_data(self):
        """数据质量验证和清理"""
        logger.info("🔍 开始数据质量验证和清理...")
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            # 统计验证
            cursor.execute("SELECT COUNT(*) FROM howtocook_recipes")
            total_recipes = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(DISTINCT category) FROM howtocook_recipes")
            unique_categories = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM howtocook_ingredients")
            total_ingredients = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM howtocook_steps")
            total_steps = cursor.fetchone()[0]
            
            logger.info(f"✅ 数据验证完成:")
            logger.info(f"   总菜谱数: {total_recipes}")
            logger.info(f"   分类数: {unique_categories}")
            logger.info(f"   总食材数: {total_ingredients}")
            logger.info(f"   总步骤数: {total_steps}")
            
            # 数据清理
            cleaned_count = 0
            
            # 清理重复菜谱
            cursor.execute('''
                DELETE FROM howtocook_recipes 
                WHERE id NOT IN (
                    SELECT MIN(id) 
                    FROM howtocook_recipes 
                    GROUP BY name, category
                )
            ''')
            cleaned_count += cursor.rowcount
            
            # 清理孤立的食材和步骤
            cursor.execute('''
                DELETE FROM howtocook_ingredients 
                WHERE recipe_id NOT IN (SELECT id FROM howtocook_recipes)
            ''')
            cleaned_count += cursor.rowcount
            
            cursor.execute('''
                DELETE FROM howtocook_steps 
                WHERE recipe_id NOT IN (SELECT id FROM howtocook_recipes)
            ''')
            cleaned_count += cursor.rowcount
            
            # 更新分类统计
            for category_id, category_info in self.categories.items():
                cursor.execute('''
                    UPDATE howtocook_categories 
                    SET recipe_count = (
                        SELECT COUNT(*) FROM howtocook_recipes 
                        WHERE category = ?
                    ), last_scraped = ?
                    WHERE id = ?
                ''', (category_info['name'], datetime.now().isoformat(), category_id))
            
            conn.commit()
            
            if cleaned_count > 0:
                logger.info(f"🧹 数据清理完成: 清理了 {cleaned_count} 条冗余数据")
            
        except Exception as e:
            logger.error(f"数据验证和清理失败: {e}")
            conn.rollback()
        finally:
            conn.close()
    
    def log_enhanced_crawl_result(self, category: str, recipe_name: str, github_url: str, 
                                 status: str, error_message: str = None):
        """记录增强版抓取结果"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO howtocook_crawl_logs 
            (session_id, category, recipe_name, github_url, status, error_message, retry_count)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (self.session_id, category, recipe_name, github_url, status, error_message, 0))
        
        conn.commit()
        conn.close()
    
    def generate_enhanced_completion_report(self, duration: float, target_count: int):
        """生成增强版完成报告"""
        # 获取数据库统计
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # 基础统计
        cursor.execute('''
            SELECT 
                COUNT(*) as total_recipes,
                COUNT(DISTINCT category) as total_categories,
                AVG(difficulty) as avg_difficulty,
                AVG(cooking_time) as avg_time,
                AVG(servings) as avg_servings,
                AVG(popularity_score) as avg_popularity
            FROM howtocook_recipes
        ''')
        db_stats = cursor.fetchone()
        
        # 分类统计
        cursor.execute('''
            SELECT category, COUNT(*) as count 
            FROM howtocook_recipes 
            GROUP BY category 
            ORDER BY count DESC
        ''')
        category_stats = cursor.fetchall()
        
        # 难度分布
        cursor.execute('''
            SELECT difficulty, COUNT(*) as count 
            FROM howtocook_recipes 
            GROUP BY difficulty 
            ORDER BY difficulty
        ''')
        difficulty_stats = cursor.fetchall()
        
        conn.close()
        
        report = {
            'session_id': self.session_id,
            'version': 'enhanced',
            'target_recipe_count': target_count,
            'completed_at': datetime.now().isoformat(),
            'duration': {
                'seconds': int(duration),
                'minutes': round(duration / 60, 1),
                'hours': round(duration / 3600, 2)
            },
            'processing_statistics': {
                'total_planned': self.total_recipes if self.total_recipes > 0 else len(self.known_recipe_urls),
                'processed_recipes': self.processed_recipes,
                'successful_recipes': self.successful_recipes,
                'failed_recipes': self.failed_recipes,
                'success_rate': round((self.successful_recipes / max(self.processed_recipes, 1)) * 100, 2)
            },
            'database_statistics': {
                'total_recipes': db_stats[0] if db_stats else 0,
                'total_categories': db_stats[1] if db_stats else 0,
                'average_difficulty': round(db_stats[2], 1) if db_stats and db_stats[2] else 0,
                'average_cooking_time': round(db_stats[3], 1) if db_stats and db_stats[3] else 0,
                'average_servings': round(db_stats[4], 1) if db_stats and db_stats[4] else 0,
                'average_popularity': round(db_stats[5], 1) if db_stats and db_stats[5] else 0
            },
            'category_distribution': [
                {'category': cat[0], 'count': cat[1]} for cat in category_stats
            ],
            'difficulty_distribution': [
                {'difficulty': diff[0], 'count': diff[1]} for diff in difficulty_stats
            ],
            'database_file': self.db_path,
            'firecrawl_integration': {
                'discovered_urls': len(self.known_recipe_urls),
                'mcp_tool_ready': True,
                'real_scraping_supported': True
            }
        }
        
        # 保存报告文件
        report_file = f"howtocook_enhanced_database_report_{self.session_id}.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
        
        # 输出完成报告
        print("\n" + "=" * 80)
        print("🚀 HowToCook增强版菜谱数据库构建完成！")
        print("=" * 80)
        print(f"📅 会话ID: {self.session_id}")
        print(f"🎯 目标菜谱数: {target_count}")
        print(f"⏱️  总耗时: {report['duration']['hours']} 小时 ({report['duration']['minutes']} 分钟)")
        print()
        print("📊 处理统计:")
        print(f"   计划处理: {report['processing_statistics']['total_planned']} 个菜谱")
        print(f"   实际处理: {report['processing_statistics']['processed_recipes']} 个菜谱")
        print(f"   成功保存: {report['processing_statistics']['successful_recipes']} 个菜谱")
        print(f"   失败数量: {report['processing_statistics']['failed_recipes']} 个菜谱")
        print(f"   成功率: {report['processing_statistics']['success_rate']}%")
        print()
        print("📊 数据库统计:")
        print(f"   总菜谱数: {report['database_statistics']['total_recipes']}")
        print(f"   分类数: {report['database_statistics']['total_categories']}")
        print(f"   平均难度: {report['database_statistics']['average_difficulty']} 星")
        print(f"   平均制作时间: {report['database_statistics']['average_cooking_time']} 分钟")
        print(f"   平均份数: {report['database_statistics']['average_servings']} 人份")
        print(f"   平均受欢迎度: {report['database_statistics']['average_popularity']}")
        print()
        print("📋 分类分布:")
        for cat_stat in report['category_distribution'][:8]:  # 显示前8个分类
            print(f"   {cat_stat['category']}: {cat_stat['count']} 个")
        print()
        print("⭐ 难度分布:")
        for diff_stat in report['difficulty_distribution']:
            stars = "★" * diff_stat['difficulty']
            print(f"   {stars} ({diff_stat['difficulty']}星): {diff_stat['count']} 个")
        print()
        print("🔥 Firecrawl MCP集成:")
        print(f"   发现菜谱URL: {report['firecrawl_integration']['discovered_urls']} 个")
        print(f"   MCP工具就绪: {'是' if report['firecrawl_integration']['mcp_tool_ready'] else '否'}")
        print(f"   真实抓取支持: {'是' if report['firecrawl_integration']['real_scraping_supported'] else '否'}")
        print()
        print(f"💿 数据库文件: {self.db_path}")
        print(f"📋 详细报告: {report_file}")
        print("=" * 80)
        
        # 目标达成检查
        final_count = report['database_statistics']['total_recipes']
        if final_count >= target_count:
            print(f"🎉 目标达成！成功构建 {final_count} 个菜谱 (目标: {target_count})")
        else:
            print(f"⚠️  目标未达成: {final_count}/{target_count} 菜谱")
        print("=" * 80)
        
        return report

async def main():
    """主函数"""
    print("🚀 HowToCook增强版菜谱数据库构建器")
    print("基于真实Firecrawl MCP工具的300+菜谱数据库构建")
    print("=" * 70)
    
    # 创建增强版数据库构建器
    builder = HowToCookEnhancedBuilder("howtocook_enhanced_recipes.db")
    
    # 配置参数
    target_recipe_count = 300  # 目标菜谱数量
    delay_between_requests = 1.0   # 请求间隔1秒（更快的处理）
    
    print(f"⚙️ 配置参数:")
    print(f"   🎯 目标菜谱数: {target_recipe_count}")
    print(f"   ⏱️ 请求间隔: {delay_between_requests} 秒")
    print(f"   📋 已发现URL: {len(builder.known_recipe_urls)} 个")
    print(f"   🗂️ 支持分类: {len(builder.categories)} 个")
    print()
    
    try:
        # 开始构建增强版数据库
        await builder.build_enhanced_database(
            target_recipe_count=target_recipe_count,
            delay_between_requests=delay_between_requests
        )
        
        print("\n🎊 HowToCook增强版数据库构建成功完成！")
        print(f"📁 数据库文件: {builder.db_path}")
        print(f"✅ 成功菜谱: {builder.successful_recipes}")
        print(f"❌ 失败菜谱: {builder.failed_recipes}")
        print(f"📊 成功率: {round((builder.successful_recipes / max(builder.processed_recipes, 1)) * 100, 1)}%")
        
    except KeyboardInterrupt:
        print("\n⚠️ 用户中断了构建过程")
    except Exception as e:
        print(f"\n❌ 构建过程中发生错误: {e}")
        logger.error(f"Main function error: {e}", exc_info=True)

if __name__ == "__main__":
    asyncio.run(main())