#!/usr/bin/env python3
"""商店截图批量生成：Playwright 驱动本机 Chrome 按 App Store/Play 像素规格截取关键页面。

用法（需先启动 flutter web-server :8795）：
    python3 scripts/store_screenshots.py

输出：docs/store_assets/<规格>_<页面>.png
规格对应关系（viewport × deviceScaleFactor = 输出像素）：
  6.7inch  430×932  @3x = 1290×2796   App Store 6.7"
  6.1inch  393×852  @3x = 1179×2556   参考规格（App Store 不收 6.1"，仅备用）
  play     360×640  @3x = 1080×1920   Google Play 手机（宽高比须 ≤9:16）

可选参数：python3 scripts/store_screenshots.py [规格名] 仅重跑指定规格。
"""

import os
import sys
from playwright.sync_api import sync_playwright

BASE = 'http://localhost:8795/#'
OUT = os.path.join(os.path.dirname(__file__), '..', 'docs', 'store_assets')
os.makedirs(OUT, exist_ok=True)

SIZES = {
    '6.7inch': (430, 932, 3),
    '6.1inch': (393, 852, 3),
    'play': (360, 640, 3),
}

PAGES = {
    'home': '',                # 首页口味舞台
    'result': '/result-demo',  # 推荐结果页
    'detail': '/recipe-detail-demo',  # 菜谱详情
    'favorites': '/favorites',  # 收藏页
    'library': '/howtocook',   # 菜谱库
}


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    sizes = {only: SIZES[only]} if only else SIZES
    with sync_playwright() as p:
        browser = p.chromium.launch(channel='chrome', headless=True)
        for name, (w, h, dsf) in sizes.items():
            ctx = browser.new_context(
                viewport={'width': w, 'height': h},
                device_scale_factor=dsf,
                is_mobile=True,
                has_touch=True,
            )
            # 预置「已看过新手引导」与「首页引导卡已见」，避免遮罩遮挡商店截图
            ctx.add_init_script(
                "localStorage.setItem('flutter.has_seen_onboarding_v2','true');"
                "localStorage.setItem('flutter.v2_home_generation_guide_seen','true');"
            )
            page = ctx.new_page()
            for label, route in PAGES.items():
                page.goto(f'{BASE}{route}')
                # 等待字体与图片加载、首页物理动画进入稳态
                page.wait_for_timeout(12000)
                path = os.path.join(OUT, f'{name}_{label}.png')
                page.screenshot(path=path)
                print(f'{path}  ({w * dsf}x{h * dsf})')
            ctx.close()
        browser.close()


if __name__ == '__main__':
    main()
