#!/usr/bin/env python3
"""
Mosaic app icon generator.

Draws the icon geometry in code (no hand-made bitmaps) so it stays reproducible
and stays in sync with the app's design tokens in Mosaic/Support/Theme.swift.

Shipped design ("bento"):
    A warm paper squircle holding four unequal "photo" tiles — one deep-ink tile
    as the brand anchor, warm apricot as the hero, sand and olive as the quiet
    counterweights. Tiles carry a soft horizon so they read as photographs, and
    the whole mosaic sits on a hairline paper ground with a light print shadow.

Design tokens (Mosaic/Support/Theme.swift):
    paper #F7F6F2   surface #FFFEFA   ink #242522
    sand  #E3CBA6   sage    #9EAA93   dusty #A4B3BC   apricot #E0A87E

Alternate concepts (same generator): monogram, bento-cool, edge.

Usage:
    python3 Tools/generate_app_icons.py --all                     # every concept, 3 appearances
    python3 Tools/generate_app_icons.py --concept bento --install  # ship it in the asset catalog
    python3 Tools/generate_app_icons.py --concept edge --variant dark --out /tmp/x
"""

from __future__ import annotations

import argparse
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# ---------------------------------------------------------------- fundamentals

SIZE = 1024
SS = 4                      # supersampling factor for the 8-bit render
CANVAS = SIZE * SS

PAPER = (0xF7, 0xF6, 0xF2)
PAPER_TOP = (0xFC, 0xFB, 0xF7)
PAPER_BOTTOM = (0xF2, 0xF0, 0xE9)

# Muted "photo" tones, all warmer/duller than a stock photo app palette.
APRICOT = ((0xE3, 0xB0, 0x87), (0xCA, 0x88, 0x63))
SAND = ((0xE8, 0xD5, 0xB8), (0xCB, 0xAD, 0x82))
DUSTY = ((0xAF, 0xBD, 0xC4), (0x7E, 0x92, 0x9E))
OLIVE = ((0xA9, 0xAE, 0x8E), (0x76, 0x82, 0x62))


def hx(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


# ------------------------------------------------------------------- painting

def gradient(
    w: int,
    h: int,
    c1,
    c2,
    angle: float = 60.0,
    highlight: float = 0.0,
    landscape: float = 0.0,
    horizon: float = 0.60,
    vignette: float = 0.0,
) -> np.ndarray:
    """Linear gradient with an optional soft "sky light" and horizon shading."""
    ys, xs = np.mgrid[0:h, 0:w]
    u = (xs + 0.5) / w
    v = (ys + 0.5) / h

    a = math.radians(angle)
    proj = u * math.cos(a) + v * math.sin(a)
    t = (proj - proj.min()) / max(float(proj.max() - proj.min()), 1e-6)

    col = np.stack([c1[i] + (c2[i] - c1[i]) * t for i in range(3)], axis=-1)

    if highlight:
        d2 = (u - 0.20) ** 2 + (v - 0.12) ** 2
        col = col + (255.0 - col) * (np.exp(-d2 / 0.20) * highlight)[:, :, None]

    if landscape:
        curve = horizon + 0.05 * np.sin(u * math.pi * 1.3 + 0.6)
        m = np.clip((v - curve) / 0.12, 0.0, 1.0)
        m = m * m * (3.0 - 2.0 * m)
        col = col * (1.0 - landscape * m)[:, :, None]

    if vignette:
        d = np.sqrt(((u - 0.5) * 1.02) ** 2 + ((v - 0.44) * 0.98) ** 2)
        col = col * (1.0 - vignette * np.clip((d - 0.38) / 0.62, 0.0, 1.0))[:, :, None]

    return np.clip(col, 0, 255).astype(np.uint8)


def rounded_mask(w: int, h: int, radius: float, corners=(True, True, True, True)) -> Image.Image:
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, w - 1, h - 1), radius=radius, fill=255, corners=corners
    )
    return mask


def paper_background(variant: str) -> Image.Image:
    """Warm paper with a soft top light. Composited in numpy so nothing darkens."""
    if variant == "tinted":
        return Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))

    if variant == "light":
        top, bottom, halo = PAPER_TOP, PAPER_BOTTOM, (1.0, 0.995, 0.975)
        strength = 0.42
    else:
        top, bottom, halo = hx("#191A14"), hx("#11120E"), (1.0, 0.97, 0.90)
        strength = 0.035

    base = gradient(CANVAS, CANVAS, top, bottom, angle=90, vignette=0.015).astype(np.float32)

    ys, xs = np.mgrid[0:CANVAS, 0:CANVAS]
    u = (xs + 0.5) / CANVAS
    v = (ys + 0.5) / CANVAS
    d = ((u - 0.5) / 0.92) ** 2 + ((v - 0.16) / 0.78) ** 2
    a = (np.clip(1.0 - d, 0.0, 1.0) ** 2) * strength
    glow = np.array(halo, dtype=np.float32) * 255.0
    out = base * (1.0 - a[:, :, None]) + glow * a[:, :, None]
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


def draw_tiles(canvas: Image.Image, tiles, *, shadow: bool, variant: str) -> None:
    """tiles: list of dicts {x,y,w,h,r,c1,c2,angle,highlight,landscape}"""
    silent = Image.new("L", canvas.size, 0)
    for t in tiles:
        silent.paste(255, (t["x"], t["y"], t["x"] + t["w"], t["y"] + t["h"]),
                     rounded_mask(t["w"], t["h"], t["r"], t.get("corners", (True,) * 4)))

    if shadow:
        strength = 38 if variant == "light" else 110
        alpha = silent.point(lambda x: int(x * strength / 255))
        sh = Image.new("RGBA", canvas.size, (18, 19, 16, 0))
        sh.putalpha(alpha)
        sh = sh.filter(ImageFilter.GaussianBlur(16 * SS))
        sh = sh.transform(
            canvas.size, Image.AFFINE, (1, 0, 0, 0, 1, 0, -8 * SS), resample=Image.BILINEAR
        )
        canvas.alpha_composite(sh)

    for t in tiles:
        arr = gradient(
            t["w"], t["h"], t["c1"], t["c2"],
            angle=t.get("angle", 58),
            highlight=t.get("highlight", 0.10),
            landscape=t.get("landscape", 0.0),
            horizon=t.get("horizon", 0.60),
            vignette=t.get("vignette", 0.06),
        )
        tile = Image.fromarray(arr, "RGB")
        if variant == "tinted":
            # Luminance only: the system applies the user's tint.
            tile = tile.convert("L").convert("RGB")
        tile = tile.convert("RGBA")
        corners = t.get("corners", (True,) * 4)
        tile.putalpha(rounded_mask(t["w"], t["h"], t["r"], corners))
        canvas.alpha_composite(tile, (t["x"], t["y"]))

    if variant == "dark":
        rim = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        rd = ImageDraw.Draw(rim)
        for t in tiles:
            rd.rounded_rectangle(
                (t["x"], t["y"], t["x"] + t["w"] - 1, t["y"] + t["h"] - 1),
                radius=t["r"], outline=(247, 246, 242, 42), width=int(3 * SS),
                corners=t.get("corners", (True,) * 4),
            )
        canvas.alpha_composite(rim)


def add_grain(img: Image.Image, variant: str, block: int = 4, sigma: float = 1.2) -> Image.Image:
    """Paper fibre: block noise reads as texture but still compresses as PNG."""
    if variant == "tinted":
        return img
    rng = np.random.default_rng(7)
    arr = np.asarray(img.convert("RGB")).astype(np.float32)
    w, h = img.size
    n = (w + block - 1) // block
    coarse = rng.normal(0.0, sigma, (n, n)).astype(np.float32)
    noise = np.repeat(np.repeat(coarse, block, axis=0), block, axis=1)[:h, :w, None]
    return Image.fromarray(np.clip(arr + noise, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


def finish(high: Image.Image, variant: str) -> Image.Image:
    out = high.resize((SIZE, SIZE), Image.LANCZOS)
    if variant != "tinted":
        out = add_grain(out, variant)
        out = out.convert("RGB")
    return out


# ------------------------------------------------------------------- concepts

BENTO_REGION = 760
BENTO_ORIGIN = (SIZE - BENTO_REGION) // 2
BENTO_GAP = 28
BENTO_RADIUS = 27


def concept_bento(variant: str, cool: bool = False) -> Image.Image:
    """Four unequal tiles: the app's collage grid, cut like a printed page."""
    o = BENTO_ORIGIN * SS
    g = BENTO_GAP * SS
    r = BENTO_RADIUS * SS
    R = BENTO_REGION * SS

    top_h = int(R * 0.615)
    left_w = int(R * 0.320)          # bottom row breaks at a different beat
    right_x = o + top_h + g

    accent = DUSTY if cool else OLIVE
    ink_pair = (hx("#42443B"), hx("#2E3028")) if variant == "dark" else (hx("#2A2B26"), hx("#181916"))

    tiles = [
        # hero block: warm landscape
        dict(x=o, y=o, w=top_h, h=top_h, r=r,
             c1=APRICOT[0], c2=APRICOT[1], highlight=0.15, landscape=0.10, horizon=0.58),
        # ink block: brand anchor
        dict(x=right_x, y=o, w=R - top_h - g, h=top_h, r=r,
             c1=ink_pair[0], c2=ink_pair[1], highlight=0.05, landscape=0.0),
        # sand block
        dict(x=o, y=o + top_h + g, w=left_w, h=R - top_h - g, r=r,
             c1=SAND[0], c2=SAND[1], highlight=0.14, landscape=0.07, horizon=0.66),
        # accent block
        dict(x=o + left_w + g, y=o + top_h + g, w=R - left_w - g, h=R - top_h - g, r=r,
             c1=accent[0], c2=accent[1], highlight=0.14, landscape=0.10, horizon=0.52),
    ]
    canvas = paper_background(variant)
    draw_tiles(canvas, tiles, shadow=(variant != "tinted"), variant=variant)
    return finish(canvas, variant)


def concept_edge(variant: str) -> Image.Image:
    """Full-bleed version: the mosaic runs off the edges of the icon."""
    canvas = paper_background(variant)
    gap = 34 * SS
    top_h = int(CANVAS * 0.576)
    left_w = int(CANVAS * 0.332)
    r = 34 * SS
    ink_pair = (hx("#42443B"), hx("#2E3028")) if variant == "dark" else (hx("#2A2B26"), hx("#181916"))
    tiles = [
        dict(x=0, y=0, w=CANVAS, h=top_h, r=r, corners=(False, False, True, True),
             c1=APRICOT[0], c2=APRICOT[1], highlight=0.15, landscape=0.12, horizon=0.57),
        dict(x=0, y=top_h + gap, w=left_w, h=CANVAS - top_h - gap, r=r,
             corners=(True, False, False, False),
             c1=ink_pair[0], c2=ink_pair[1], highlight=0.06, landscape=0.0),
        dict(x=left_w + gap, y=top_h + gap, w=CANVAS - left_w - gap, h=CANVAS - top_h - gap,
             r=r, corners=(False, True, False, False),
             c1=SAND[0], c2=SAND[1], highlight=0.14, landscape=0.08, horizon=0.64),
    ]
    draw_tiles(canvas, tiles, shadow=False, variant=variant)
    return finish(canvas, variant)


def concept_monogram(variant: str) -> Image.Image:
    """M built out of mosaic tiles; one tile carries the photo tone."""
    tile = int(560 * SS / 5)
    gap = 18 * SS
    span = tile * 5 + gap * 4
    o = (CANVAS - span) // 2
    r = int(tile * 0.24)
    pattern = [
        (1, 0, 0, 0, 1),
        (1, 1, 0, 1, 1),
        (1, 0, 1, 0, 1),
        (1, 0, 0, 0, 1),
        (1, 0, 0, 0, 1),
    ]
    tiles = []
    for row in range(5):
        for col in range(5):
            if not pattern[row][col]:
                continue
            warm = (row, col) == (2, 2)
            tiles.append(
                dict(
                    x=o + col * (tile + gap), y=o + row * (tile + gap),
                    w=tile, h=tile, r=r,
                    c1=APRICOT[0] if warm else hx("#2D2E29"),
                    c2=APRICOT[1] if warm else hx("#1B1C19"),
                    highlight=0.16 if warm else 0.05,
                    landscape=0.06 if warm else 0.0,
                    horizon=0.58,
                )
            )
    canvas = paper_background(variant)
    draw_tiles(canvas, tiles, shadow=(variant != "tinted"), variant=variant)
    return finish(canvas, variant)


APPICONSET = "Mosaic/Assets.xcassets/AppIcon.appiconset"

CONTENTS = {
    "images": [
        {"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        {"appearances": [{"appearance": "luminosity", "value": "dark"}],
         "filename": "AppIcon-Dark.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        {"appearances": [{"appearance": "luminosity", "value": "tinted"}],
         "filename": "AppIcon-Tinted.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
    ],
    "info": {"author": "xcode", "version": 1},
}


def install(concept: str) -> None:
    """Write the chosen concept into the app's asset catalog (light/dark/tinted)."""
    import json

    images = {
        "light": "AppIcon.png",
        "dark": "AppIcon-Dark.png",
        "tinted": "AppIcon-Tinted.png",
    }
    for variant, filename in images.items():
        img = CONCEPTS[concept](variant)
        path = os.path.join(APPICONSET, filename)
        img.save(path, optimize=True)
        print("installed", path, img.size, img.mode)

    with open(os.path.join(APPICONSET, "Contents.json"), "w") as fh:
        json.dump(CONTENTS, fh, indent=2)
        fh.write("\n")
    print("installed", os.path.join(APPICONSET, "Contents.json"))


CONCEPTS = {
    "bento": concept_bento,
    "bento-cool": lambda variant: concept_bento(variant, cool=True),
    "monogram": concept_monogram,
    "edge": concept_edge,
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--concept", choices=sorted(CONCEPTS), default=None)
    ap.add_argument("--variant", choices=["light", "dark", "tinted"], default="light")
    ap.add_argument("--out", default="Design/AppIcon/master")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--install", action="store_true",
                    help="copy the chosen concept into Mosaic/Assets.xcassets/AppIcon.appiconset")
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    concepts = sorted(CONCEPTS) if (args.all or args.concept is None) else [args.concept]
    variants = ["light", "dark", "tinted"] if args.all else [args.variant]

    for concept in concepts:
        for variant in variants:
            img = CONCEPTS[concept](variant)
            name = f"{concept}-{variant}.png"
            path = os.path.join(args.out, name)
            img.save(path)
            print(path, img.size, img.mode)

    if args.install:
        install(args.concept or "bento")


if __name__ == "__main__":
    main()
