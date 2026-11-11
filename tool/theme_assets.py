#!/usr/bin/env python3
"""Crop/split ImageGen theme accessories into Flutter-ready WebP assets.

Reads staged sources from build/review/theme-assets-src-20261111/<slug>_<kind>.png
(kind in button/frame/well/seal) and writes assets/themes/<slug>_<kind>.webp.

- button: center-cropped 2:1 material swatch (clipped to a half-round in Flutter)
- frame:  square 9-slice border, outer background knocked out to alpha;
          saved at 500px and consumed with ExactAssetImage(scale: 3) so the
          ring renders ~15 logical px sharp on 3x devices
- well:   3:1 recessed input panel (plain stretch)
- seal:   tight-cropped stamp with the light background knocked out to alpha

Also writes a per-slug contact sheet for visual verification. Re-run any time;
it processes every slug present in the staging directory.
"""
from __future__ import annotations

import glob
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "build", "review", "theme-assets-src-20261111")
OUT = os.path.join(ROOT, "assets", "themes")
KINDS = ("button", "frame", "well", "seal")


def center_crop(im: Image.Image, ratio_w: int, ratio_h: int) -> Image.Image:
    w, h = im.size
    target = ratio_w / ratio_h
    if w / h > target:  # too wide -> crop width
        nw = int(h * target)
        x = (w - nw) // 2
        return im.crop((x, 0, x + nw, h))
    nh = int(w / target)  # too tall -> crop height
    y = (h - nh) // 2
    return im.crop((0, y, w, y + nh))


def save_webp(im: Image.Image, path: str, quality: int = 82) -> None:
    im.save(path, "WEBP", quality=quality, method=6)


def process_button(src: str, dst: str) -> Image.Image:
    im = Image.open(src).convert("RGB")
    im = center_crop(im, 2, 1).resize((768, 384), Image.LANCZOS)
    save_webp(im, dst, 82)
    return im


def process_frame(src: str, dst: str) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()

    def is_backdrop(p) -> bool:
        r, g, b, _ = p
        return min(r, g, b) > 200 and max(r, g, b) - min(r, g, b) < 30

    # Flood-fill the outer backdrop from the four corners so the rounded
    # frame corners stay transparent; the enclosed ivory center is untouched.
    stack = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    seen = set()
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        if not is_backdrop(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    im = im.resize((500, 500), Image.LANCZOS)
    save_webp(im, dst, 82)
    return im


def process_well(src: str, dst: str) -> Image.Image:
    im = Image.open(src).convert("RGB")
    im = center_crop(im, 3, 1).resize((768, 256), Image.LANCZOS)
    save_webp(im, dst, 82)
    return im


def process_seal(src: str, dst: str) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()

    def is_backdrop(p) -> bool:
        r, g, b, _ = p
        return min(r, g, b) > 185 and max(r, g, b) - min(r, g, b) < 30

    # Bounding box of everything that is not the light backdrop, so seals of
    # any ink color (cinnabar, jade, ink black, rose gold) crop tightly.
    minx, miny, maxx, maxy = w, h, 0, 0
    found = False
    for y in range(h):
        for x in range(w):
            if not is_backdrop(px[x, y]):
                found = True
                minx, miny = min(minx, x), min(miny, y)
                maxx, maxy = max(maxx, x), max(maxy, y)
    if found:
        pad = 8
        box = (max(0, minx - pad), max(0, miny - pad),
               min(w, maxx + pad), min(h, maxy + pad))
        im = im.crop(box)
    else:
        im = center_crop(im, 1, 1)
    # Knock out the light background to transparency.
    px = im.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            r, g, b, a = px[x, y]
            if min(r, g, b) > 185:
                px[x, y] = (r, g, b, 0)
    im = im.resize((128, 128), Image.LANCZOS)
    save_webp(im, dst, 90)
    return im


def contact_sheet(slug: str, parts: dict) -> str:
    canvas = Image.new("RGB", (820, 470), (247, 243, 234))
    draw = ImageDraw.Draw(canvas)
    placements = {
        "button": (16, 30, (384, 192)),
        "frame": (430, 30, (200, 200)),
        "well": (16, 262, (384, 128)),
        "seal": (430, 262, (128, 128)),
    }
    for kind, (x, y, size) in placements.items():
        if kind not in parts:
            continue
        thumb = parts[kind].convert("RGBA").resize(size, Image.LANCZOS)
        canvas.paste(thumb, (x, y), thumb)
        draw.text((x, y - 16), f"{slug} / {kind}", fill=(36, 31, 26))
    path = os.path.join(SRC, f"{slug}_contact.png")
    canvas.save(path)
    return path


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    slugs = sorted({
        os.path.basename(p).rsplit("_", 1)[0]
        for p in glob.glob(os.path.join(SRC, "*_*.png"))
        if os.path.basename(p).rsplit("_", 1)[1].split(".")[0] in KINDS
    })
    if not slugs:
        print("no staged sources found")
        return
    processors = {
        "button": process_button,
        "frame": process_frame,
        "well": process_well,
        "seal": process_seal,
    }
    for slug in slugs:
        parts = {}
        for kind in KINDS:
            src = os.path.join(SRC, f"{slug}_{kind}.png")
            if not os.path.exists(src):
                continue
            dst = os.path.join(OUT, f"{slug}_{kind}.webp")
            parts[kind] = processors[kind](src, dst)
            kb = os.path.getsize(dst) / 1024
            print(f"{slug}_{kind}.webp  {parts[kind].size}  {kb:.1f} KB")
        sheet = contact_sheet(slug, parts)
        print(f"contact sheet -> {sheet}")


if __name__ == "__main__":
    main()