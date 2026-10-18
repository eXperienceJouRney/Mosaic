#!/usr/bin/env python3
"""
Mosaic — icon presentation sheet.

Renders the installed AppIcon (light / dark / tinted) at review sizes, plus the
alternate concepts that Tools/generate_app_icons.py can install.

    python3 Tools/make_icon_preview.py
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageFont

SET = "Mosaic/Assets.xcassets/AppIcon.appiconset"
ALT = "Design/AppIcon/master"
OUT_SHEET = "Design/AppIcon/icon-sheet.png"
OUT_HOME = "Design/AppIcon/icon-home-screen.png"

INK = (0x24, 0x25, 0x22)
MUTED = (0x77, 0x77, 0x6F)
FAINT = (0x92, 0x91, 0x88)
PAGE = (0xEC, 0xEB, 0xE6)
RULE = (0xD9, 0xD7, 0xCF)

SF = "/System/Library/Fonts/SFNS.ttf"
CJK = "/System/Library/Fonts/Hiragino Sans GB.ttc"


def font(size: int, weight: str = "Regular", cjk: bool = False) -> ImageFont.FreeTypeFont:
    if cjk:
        return ImageFont.truetype(CJK, size, index=0)
    f = ImageFont.truetype(SF, size, index=0)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def track(draw, xy, text, f, fill, spacing=1.6):
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=f, fill=fill, anchor="ls")
        x += draw.textlength(ch, font=f) + spacing
    return x


def squircle(size: int, ratio: float = 0.2237) -> Image.Image:
    ss = 4
    mask = Image.new("L", (size * ss, size * ss), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size * ss - 1, size * ss - 1), radius=ratio * size * ss, fill=255
    )
    return mask.resize((size, size), Image.LANCZOS)


def icon_tile(path: str, size: int, chip=None, masked=True) -> Image.Image:
    img = Image.open(path).convert("RGBA").resize((size, size), Image.LANCZOS)
    if chip is not None:
        bg = Image.new("RGBA", (size, size), tuple(chip) + (255,))
        img = Image.alpha_composite(bg, img)
    if masked:
        img.putalpha(Image.composite(img.getchannel("A"), Image.new("L", (size, size), 0), squircle(size)))
    return img


def sheet() -> None:
    W, H, M = 1120, 1170, 72
    page = Image.new("RGB", (W, H), PAGE)
    d = ImageDraw.Draw(page)

    d.text((M, 96), "Mosaic · 图标方案", font=font(38, "Medium", cjk=True), fill=INK, anchor="ls")
    d.text((M, 132), "App icon — 1024 px master, light / dark / tinted appearances",
           font=font(17), fill=MUTED, anchor="ls")
    d.text((M, 158), "纸感底色 + 墨色 + 照片色块：把日历里的拼贴网格做成图标",
           font=font(16, cjk=True), fill=MUTED, anchor="ls")
    d.line([(M, 192), (W - M, 192)], fill=RULE, width=1)

    track(d, (M, 220), "PRIMARY · 主图标", font(12), FAINT, 2.2)

    primary = os.path.join(SET, "AppIcon.png")
    dark = os.path.join(SET, "AppIcon-Dark.png")
    tinted = os.path.join(SET, "AppIcon-Tinted.png")
    s = 224
    items = [
        (primary, None, "亮色 Light"),
        (dark, None, "深色 Dark"),
        (tinted, (0xE4, 0xE3, 0xDE), "着色 Tinted · 系统着色"),
    ]
    for i, (path, chip, label) in enumerate(items):
        x = M + i * (s + 62)
        page.paste(icon_tile(path, s, chip), (x, 246), icon_tile(path, s, chip))
        d.text((x, 246 + s + 24), label, font=font(15, cjk=True), fill=MUTED, anchor="ls")

    d.line([(M, 540), (W - M, 540)], fill=RULE, width=1)
    track(d, (M, 568), "LEGIBILITY · 各尺寸", font(12), FAINT, 2.2)

    sizes = [180, 120, 80, 60, 40]
    x = M
    base = 604
    for size in sizes:
        tile = icon_tile(primary, size)
        page.paste(tile, (x, base), tile)
        d.text((x, base + 180 + 26), f"{size}px", font=font(14), fill=MUTED, anchor="ls")
        x += size + max(36, 64 - size // 6)

    d.line([(M, 852), (W - M, 852)], fill=RULE, width=1)
    track(d, (M, 880), "ALTERNATES · 备选（均可一键安装）", font(12), FAINT, 2.2)

    alts = [
        (os.path.join(ALT, "monogram-light.png"), "monogram · 字母 M 拼贴"),
        (os.path.join(ALT, "bento-cool-light.png"), "bento-cool · 冷色块"),
        (os.path.join(ALT, "edge-light.png"), "edge · 满版拼贴"),
    ]
    for i, (path, label) in enumerate(alts):
        x = M + i * (128 + 88)
        tile = icon_tile(path, 128)
        page.paste(tile, (x, 910), tile)
        d.text((x, 910 + 128 + 24), label, font=font(14, cjk=True), fill=MUTED, anchor="ls")

    d.text((M, 1128),
           "生成：python3 Tools/generate_app_icons.py --concept <bento|monogram|bento-cool|edge> --install",
           font=font(12), fill=FAINT, anchor="ls")
    page.save(OUT_SHEET)
    print("wrote", OUT_SHEET, page.size)


def home_screen() -> None:
    W, H = 1200, 820
    page = Image.new("RGB", (W, H), PAGE)
    d = ImageDraw.Draw(page)
    d.text((W // 2, 52), "Mosaic 在壁纸上的呈现", font=font(20, "Medium", cjk=True), fill=INK, anchor="ms")

    panels = [
        (80, ((0xF7, 0xF0, 0xE5), (0xDF, 0xD1, 0xBC)), INK),
        (620, ((0x25, 0x26, 0x21), (0x14, 0x15, 0x11)), (0xF2, 0xF0, 0xE9)),
    ]
    pw, ph, py = 500, 640, 92
    for px, (top, bottom), label in panels:
        panel = Image.new("RGB", (pw, ph), top)
        grad = Image.new("RGB", (pw, ph))
        gd = ImageDraw.Draw(grad)
        for y in range(ph):
            t = y / (ph - 1)
            gd.line([(0, y), (pw, y)],
                    fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
        panel.paste(grad, (0, 0))
        mask = Image.new("L", (pw * 2, ph * 2), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, pw * 2 - 1, ph * 2 - 1), radius=44 * 2, fill=255)
        mask = mask.resize((pw, ph), Image.LANCZOS)
        page.paste(panel, (px, py), mask)

        icon = icon_tile(os.path.join(SET, "AppIcon.png"), 172)
        page.paste(icon, (px + (pw - 172) // 2, py + 176), icon)
        d.text((px + pw // 2, py + 176 + 172 + 42), "Mosaic",
               font=font(25, "Medium"), fill=label, anchor="ms")

    d.text((W // 2, 770),
           "浅色壁纸与深色壁纸上都保持纸感与墨色的对比",
           font=font(15, cjk=True), fill=MUTED, anchor="ms")
    page.save(OUT_HOME)
    print("wrote", OUT_HOME, page.size)


if __name__ == "__main__":
    sheet()
    home_screen()
