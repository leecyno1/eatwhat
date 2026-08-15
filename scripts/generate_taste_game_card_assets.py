from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFilter


OUT = Path("assets/images/card_game")
OUT.mkdir(parents=True, exist_ok=True)


def rgba(hex_color, alpha=255):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def gradient(size, top, bottom):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    h = size[1]
    for y in range(h):
        t = y / max(1, h - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(4))
        draw.line([(0, y), (size[0], y)], fill=color)
    return img


def glow(size, color, radius=80, center=None):
    w, h = size
    cx, cy = center or (w / 2, h / 2)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    pix = img.load()
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - cx, y - cy)
            a = max(0, 1 - d / radius) ** 2
            pix[x, y] = (color[0], color[1], color[2], int(color[3] * a))
    return img


def draw_frame(name, outer, inner, gem):
    w, h = 512, 768
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle([18, 18, w - 18, h - 18], radius=58, fill=rgba("#16110f", 220))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(shadow)

    draw.rounded_rectangle([26, 18, w - 26, h - 18], radius=58, fill=outer)
    draw.rounded_rectangle([48, 44, w - 48, h - 44], radius=42, fill=rgba("#2a1d18", 245))
    draw.rounded_rectangle([64, 78, w - 64, h - 130], radius=34, fill=inner)
    draw.rounded_rectangle([68, 82, w - 68, h - 134], radius=30, outline=rgba("#fff3cf", 92), width=4)

    for i in range(7):
        y = 86 + i * 78
        draw.arc([42, y, 120, y + 70], 110, 250, fill=rgba("#f7d98f", 72), width=3)
        draw.arc([w - 120, y, w - 42, y + 70], -70, 70, fill=rgba("#f7d98f", 72), width=3)

    draw.ellipse([205, 10, 307, 112], fill=rgba("#1b1110", 245), outline=rgba("#fff0bb", 170), width=5)
    draw.ellipse([220, 24, 292, 96], fill=gem, outline=rgba("#ffffff", 120), width=3)
    draw.polygon([(256, 30), (286, 58), (256, 90), (226, 58)], fill=rgba("#ffffff", 42))

    draw.rounded_rectangle([96, h - 142, w - 96, h - 54], radius=26, fill=rgba("#180f0c", 220))
    draw.rounded_rectangle([114, h - 124, w - 114, h - 72], radius=18, outline=rgba("#fff0bb", 120), width=3)

    img.save(OUT / f"{name}.png")


def draw_category_art(name, palette, motif):
    w, h = 512, 512
    img = gradient((w, h), rgba(palette[0], 255), rgba(palette[1], 255))
    img.alpha_composite(glow((w, h), rgba(palette[2], 190), radius=280, center=(w * 0.6, h * 0.38)))
    draw = ImageDraw.Draw(img)

    for i in range(16):
        x = 40 + (i * 73) % 430
        y = 44 + (i * 97) % 420
        r = 2 + i % 4
        draw.ellipse([x - r, y - r, x + r, y + r], fill=rgba("#fff4cf", 50 + i % 3 * 18))

    if motif == "flame":
        for i, color in enumerate(["#ff3d1f", "#ff9b24", "#ffe37d"]):
            inset = 70 + i * 34
            draw.pieslice([inset, 80 + i * 16, w - inset, h + 120], 210, 330, fill=rgba(color, 205))
        draw.ellipse([158, 276, 354, 392], fill=rgba("#2b1009", 230), outline=rgba("#ffd58f", 130), width=6)
    elif motif == "ingredient":
        draw.rounded_rectangle([112, 132, 400, 370], radius=54, fill=rgba("#5a271c", 230), outline=rgba("#ffdca8", 130), width=6)
        draw.ellipse([156, 100, 304, 248], fill=rgba("#d64d32", 230))
        draw.ellipse([250, 184, 390, 326], fill=rgba("#8fd06a", 210))
        draw.rectangle([176, 338, 360, 362], fill=rgba("#fff1c0", 185))
    elif motif == "scene":
        draw.ellipse([148, 78, 368, 298], fill=rgba("#ffe3a0", 190))
        draw.ellipse([190, 58, 420, 288], fill=rgba(palette[0], 255))
        draw.rounded_rectangle([96, 310, 416, 372], radius=28, fill=rgba("#2b1c1b", 235))
        for x in [150, 220, 292, 362]:
            draw.line([(x, 304), (x - 22, 410)], fill=rgba("#ffe1a0", 130), width=6)
    elif motif == "cuisine":
        draw.rounded_rectangle([118, 108, 394, 394], radius=34, fill=rgba("#f2d7a2", 215), outline=rgba("#4d2b1d", 190), width=8)
        for i in range(5):
            draw.arc([150 + i * 24, 155 + i * 18, 360 - i * 16, 346 - i * 10], 20, 300, fill=rgba("#7c2c20", 155), width=6)
    elif motif == "staple":
        draw.ellipse([110, 250, 402, 410], fill=rgba("#fff0ce", 235), outline=rgba("#6a4022", 180), width=8)
        for x in range(160, 360, 34):
            draw.line([(x, 160), (x + 18, 278)], fill=rgba("#ffe4a5", 160), width=10)
    elif motif == "fortune":
        draw.polygon([(256, 78), (378, 196), (330, 374), (182, 374), (134, 196)], fill=rgba("#f0b83f", 230), outline=rgba("#fff4bd", 150))
        draw.ellipse([202, 162, 310, 270], fill=rgba("#7d311b", 230))
        draw.polygon([(256, 136), (292, 214), (256, 304), (220, 214)], fill=rgba("#fff0a8", 110))
    elif motif == "diet":
        draw.polygon([(256, 72), (386, 142), (354, 350), (256, 430), (158, 350), (126, 142)], fill=rgba("#6ecf8a", 215), outline=rgba("#ecffd8", 130), width=6)
        draw.arc([174, 152, 352, 330], 200, 25, fill=rgba("#113f2c", 200), width=16)
    else:
        for i in range(5):
            angle = i * math.tau / 5 - math.pi / 2
            x = 256 + math.cos(angle) * 128
            y = 256 + math.sin(angle) * 128
            draw.ellipse([x - 46, y - 46, x + 46, y + 46], fill=rgba("#fff0a8", 92), outline=rgba("#2f1822", 130), width=4)
        draw.ellipse([188, 188, 324, 324], fill=rgba("#6a44c8", 220), outline=rgba("#fff0ff", 140), width=6)

    img = img.filter(ImageFilter.UnsharpMask(radius=2, percent=120))
    img.save(OUT / f"{name}.png")


def draw_effect(name, kind, color):
    w, h = 512, 512
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = rgba(color, 230)

    if kind == "slash":
        for i in range(5):
            width = 24 - i * 3
            alpha = 170 - i * 25
            draw.line([(64 + i * 14, 380 - i * 32), (448 - i * 24, 110 + i * 18)], fill=(c[0], c[1], c[2], alpha), width=width)
        draw.line([(120, 420), (426, 104)], fill=rgba("#ffffff", 220), width=8)
    elif kind == "burst":
        for i in range(18):
            a = i * math.tau / 18
            r1 = 54 + (i % 3) * 8
            r2 = 220 - (i % 4) * 16
            p1 = (256 + math.cos(a) * r1, 256 + math.sin(a) * r1)
            p2 = (256 + math.cos(a) * r2, 256 + math.sin(a) * r2)
            draw.line([p1, p2], fill=(c[0], c[1], c[2], 145), width=6)
        img.alpha_composite(glow((w, h), rgba(color, 210), radius=210))
        draw.ellipse([202, 202, 310, 310], fill=rgba("#ffffff", 190))
    else:
        for i in range(34):
            a = i * math.tau / 34
            r = 70 + (i * 41) % 180
            x = 256 + math.cos(a) * r
            y = 256 + math.sin(a) * r
            draw.polygon([(x, y - 10), (x + 7, y), (x, y + 10), (x - 7, y)], fill=(c[0], c[1], c[2], 130 + i % 4 * 20))

    img = img.filter(ImageFilter.GaussianBlur(0.4))
    img.save(OUT / f"{name}.png")


frames = {
    "frame_common": ("#5a4639", "#b48349", "#d8ae69"),
    "frame_rare": ("#1e6d6b", "#38b8a8", "#8ff7e1"),
    "frame_refined": ("#263c83", "#7a8eff", "#c2cdfd"),
    "frame_epic": ("#6b2c85", "#d07cff", "#ffd06f"),
}
for name, (outer, inner, gem) in frames.items():
    draw_frame(name, rgba(outer, 255), rgba(inner, 225), rgba(gem, 230))

arts = {
    "art_flavor": (("#47100b", "#ff7b2f", "#ffd45c"), "flame"),
    "art_ingredient": (("#2f1b12", "#9d5135", "#88d46d"), "ingredient"),
    "art_scene": (("#201735", "#2d5a8f", "#ffe494"), "scene"),
    "art_cuisine": (("#2e1f16", "#a56d3a", "#f2d7a2"), "cuisine"),
    "art_staple": (("#3b2418", "#c59b56", "#fff0ce"), "staple"),
    "art_fortune": (("#321831", "#8a2f63", "#ffcf52"), "fortune"),
    "art_dietary": (("#123727", "#54a96a", "#d9ffd0"), "diet"),
    "art_meta": (("#281542", "#6f42c1", "#f4c8ff"), "meta"),
}
for name, (palette, motif) in arts.items():
    draw_category_art(name, palette, motif)

draw_effect("effect_slash", "slash", "#ffefb0")
draw_effect("effect_burst", "burst", "#ff7a2f")
draw_effect("effect_spark", "spark", "#9cf7ff")

atlas_items = [
    "frame_common",
    "frame_rare",
    "frame_refined",
    "frame_epic",
    "art_flavor",
    "art_ingredient",
    "art_scene",
    "art_cuisine",
    "art_staple",
    "art_fortune",
    "art_dietary",
    "art_meta",
    "effect_slash",
    "effect_burst",
    "effect_spark",
]
tile = 256
atlas = Image.new("RGBA", (tile * 4, tile * 4), (0, 0, 0, 0))
for idx, item in enumerate(atlas_items):
    img = Image.open(OUT / f"{item}.png").convert("RGBA")
    img.thumbnail((tile, tile), Image.Resampling.LANCZOS)
    x = idx % 4 * tile + (tile - img.width) // 2
    y = idx // 4 * tile + (tile - img.height) // 2
    atlas.alpha_composite(img, (x, y))
atlas.save(OUT / "taste_card_game_atlas.png")
