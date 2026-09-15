# -*- coding: utf-8 -*-
"""
Derives the Android TV image assets from the existing brand source.

Source of truth: assets/icons/icon.png (512x512, transparent background with a
blue gradient TV glyph). Everything here is scaling and compositing of that
single file plus the bundled MiSans font, so the assets stay in sync when the
brand mark changes. No artwork is invented and nothing is watermarked.

Outputs:
  android/app/src/main/res/drawable-xhdpi/app_banner.png   320x180  TV banner
  android/app/src/main/res/drawable/app_banner.png         320x180  density fallback
  android/app/src/main/res/mipmap-<density>/ic_banner_foreground.png
      adaptive icon foreground, transparent background, per-density sizes

Why these sizes:
  * The Android TV launcher expects a 320x180 banner. Shipping the square app
    icon there makes the launcher stretch or crop it.
  * The adaptive foreground is a 108dp canvas: 108 / 162 / 216 / 324 / 432 px
    for mdpi / hdpi / xhdpi / xxhdpi / xxxhdpi. The glyph is kept near 62% of
    the canvas so it stays inside the 66dp safe area once the mask is applied.
  * The foreground must be transparent; the solid background comes from
    @color/ic_banner_background.

Usage:
    py -3 generate_android_icons.py
"""

import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
ICON_PATH = os.path.join(ROOT, "assets", "icons", "icon.png")
FONT_PATH = os.path.join(ROOT, "assets", "MiSans-Regular.ttf")

APP_NAME = "纯粹直播"
BANNER_SIZE = (320, 180)

# Gradient endpoints sampled from the blue body of the source glyph.
DEEP = (65, 126, 213)
LIGHT = (94, 212, 242)

# 108dp adaptive-icon canvas per density bucket.
FOREGROUND_DENSITIES = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}
FOREGROUND_GLYPH_RATIO = 0.62

RESAMPLE = Image.Resampling


def horizontal_gradient(size, start, end):
    """Left-to-right linear gradient, matching the brand mark's direction."""
    width, height = size
    strip = Image.new("RGB", (width, 1))
    pixels = strip.load()
    for x in range(width):
        t = x / max(1, width - 1)
        pixels[x, 0] = tuple(
            int(start[i] + (end[i] - start[i]) * t) for i in range(3)
        )
    return strip.resize((width, height), RESAMPLE.BILINEAR)


def white_glyph(icon, height):
    """Recolours the mark to solid white while keeping its alpha cut-outs."""
    width, src_height = icon.size
    glyph = icon.resize((int(height * width / src_height), height), RESAMPLE.LANCZOS)
    flat = Image.new("RGBA", glyph.size, (255, 255, 255, 255))
    flat.putalpha(glyph.getchannel("A"))
    return flat


def build_banner(icon):
    """320x180 TV banner: white mark on the brand gradient plus the app name."""
    canvas = horizontal_gradient(BANNER_SIZE, DEEP, LIGHT).convert("RGBA")
    glyph = white_glyph(icon, 96)
    left = 26
    canvas.alpha_composite(glyph, (left, (BANNER_SIZE[1] - glyph.height) // 2))

    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(FONT_PATH, 34)
    box = draw.textbbox((0, 0), APP_NAME, font=font)
    text_x = left + glyph.width + 22
    text_y = (BANNER_SIZE[1] - (box[3] - box[1])) // 2 - box[1]
    draw.text((text_x, text_y), APP_NAME, font=font, fill=(255, 255, 255, 255))
    return canvas.convert("RGB")


def build_foreground(icon, size):
    """Transparent 108dp foreground with the coloured mark centred."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glyph_height = int(size * FOREGROUND_GLYPH_RATIO)
    width, src_height = icon.size
    glyph = icon.resize(
        (int(glyph_height * width / src_height), glyph_height), RESAMPLE.LANCZOS
    )
    canvas.alpha_composite(
        glyph, ((size - glyph.width) // 2, (size - glyph.height) // 2)
    )
    return canvas


def save(image, *parts):
    target = os.path.join(RES, *parts)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    image.save(target, optimize=True)
    print(f"  {os.path.join(*parts).replace(os.sep, '/')}  {image.size}")


def main():
    if not os.path.exists(ICON_PATH):
        raise SystemExit(f"missing brand source: {ICON_PATH}")

    icon = Image.open(ICON_PATH).convert("RGBA")
    print(f"source: {ICON_PATH} {icon.size}")

    banner = build_banner(icon)
    # xhdpi is the documented TV banner bucket; the density-less copy keeps the
    # resource resolvable from any bucket.
    save(banner, "drawable-xhdpi", "app_banner.png")
    save(banner, "drawable", "app_banner.png")

    for density, size in FOREGROUND_DENSITIES.items():
        save(
            build_foreground(icon, size),
            f"mipmap-{density}",
            "ic_banner_foreground.png",
        )


if __name__ == "__main__":
    main()
