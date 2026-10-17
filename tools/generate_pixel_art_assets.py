#!/usr/bin/env python3
"""Generate Hero Town's small, tileable nearest-filter pixel-art materials."""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "pixel"
SIZE = 128


PALETTE = {
    "grass_dark": "#315c3b",
    "grass_mid": "#4b7c43",
    "grass_light": "#6f9c4e",
    "grass_pale": "#a1bd60",
    "flower_gold": "#e7c86b",
    "flower_cream": "#e9e4bc",
    "stone_dark": "#696b5e",
    "stone_mid": "#929282",
    "stone_light": "#c4b99a",
    "stone_hi": "#ded3ae",
    "window_dark": "#223844",
    "window_blue": "#50798b",
    "window_lit": "#e2c982",
    "brick": "#a95f49",
    "brick_light": "#c27b58",
    "brick_dark": "#744737",
    "bark": "#76513c",
    "leaf_dark": "#2e673d",
    "leaf_mid": "#438747",
    "leaf_light": "#68a04a",
    "leaf_sun": "#8eb85c",
}


def color(value: str) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4)) + (255,)


def save(image: Image.Image, filename: str) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT / filename, format="PNG", optimize=True)


def wrapped_rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: str) -> None:
    x0, y0, x1, y1 = box
    width = x1 - x0 + 1
    height = y1 - y0 + 1
    for ox in (-SIZE, 0, SIZE):
        for oy in (-SIZE, 0, SIZE):
            draw.rectangle((x0 + ox, y0 + oy, x0 + ox + width - 1, y0 + oy + height - 1), fill=fill)


def grass_texture(seed: int, flowers: bool = False) -> Image.Image:
    rng = random.Random(seed)
    image = Image.new("RGBA", (SIZE, SIZE), color(PALETTE["grass_mid"]))
    draw = ImageDraw.Draw(image)
    for _ in range(350):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        width = rng.choice((1, 2, 3, 4))
        height = rng.choice((1, 2, 3))
        tone = rng.choices(
            ("grass_dark", "grass_mid", "grass_light", "grass_pale"),
            weights=(26, 36, 31, 7),
        )[0]
        wrapped_rect(draw, (x, y, x + width, y + height), PALETTE[tone])
    for _ in range(38):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        wrapped_rect(draw, (x, y - 3, x, y + 1), PALETTE["grass_dark"])
        wrapped_rect(draw, (x + 1, y - 2, x + 1, y + 2), PALETTE["grass_light"])
    if flowers:
        for _ in range(20):
            x, y = rng.randrange(SIZE), rng.randrange(SIZE)
            petal = PALETTE["flower_gold"] if rng.random() > 0.45 else PALETTE["flower_cream"]
            for dx, dy in ((0, -2), (-2, 0), (2, 0), (0, 2)):
                wrapped_rect(draw, (x + dx, y + dy, x + dx, y + dy), petal)
            wrapped_rect(draw, (x, y, x, y), "#8c663c")
    return image


def stone_texture(size: int, seed: int, mortar: str, tones: tuple[str, ...]) -> Image.Image:
    rng = random.Random(seed)
    image = Image.new("RGBA", (SIZE, SIZE), color(mortar))
    draw = ImageDraw.Draw(image)
    cells = SIZE // size
    for row in range(cells):
        offset = (size // 2) if row % 2 else 0
        for column in range(-1, cells + 1):
            x = column * size + offset
            y = row * size
            tone = rng.choice(tones)
            # Keep the stone grid periodic; the stagger repeats at the tile boundary.
            wrapped_rect(draw, (x + 1, y + 1, x + size - 2, y + size - 2), tone)
            wrapped_rect(draw, (x + 2, y + 2, x + size - 3, y + 2), PALETTE["stone_hi"])
            if rng.random() > 0.6:
                wrapped_rect(draw, (x + size - 5, y + 4, x + size - 4, y + size - 4), PALETTE["stone_dark"])
            if rng.random() > 0.75:
                wrapped_rect(draw, (x + 5, y + size - 5, x + 10, y + size - 4), PALETTE["stone_dark"])
    return image


def facade_texture(base: str, shadow: str, highlight: str, window: str, seed: int) -> Image.Image:
    rng = random.Random(seed)
    image = Image.new("RGBA", (SIZE, SIZE), color(base))
    draw = ImageDraw.Draw(image)
    # Art-deco floor bands and brick coursing.
    for y in range(0, SIZE, 32):
        draw.rectangle((0, y, SIZE - 1, y + 2), fill=color(shadow))
        draw.rectangle((0, y + 3, SIZE - 1, y + 4), fill=color(highlight))
    for x in range(0, SIZE, 32):
        draw.rectangle((x, 0, x + 2, SIZE - 1), fill=color(shadow))
        draw.rectangle((x + 3, 0, x + 4, SIZE - 1), fill=color(highlight))
    for row, y in enumerate(range(9, SIZE - 12, 30)):
        for column, x in enumerate(range(8, SIZE - 8, 24)):
            if (row + column + seed) % 7 == 0:
                pane = PALETTE["window_lit"]
            else:
                pane = window
            draw.rectangle((x, y, x + 12, y + 18), fill=color(PALETTE["window_dark"]))
            draw.rectangle((x + 2, y + 2, x + 10, y + 15), fill=color(pane))
            draw.rectangle((x + 2, y + 2, x + 4, y + 15), fill=color(highlight))
            draw.rectangle((x, y + 18, x + 13, y + 20), fill=color(shadow))
            draw.rectangle((x + 6, y + 2, x + 7, y + 15), fill=color(PALETTE["window_dark"]))
    # A few lintels and chipped masonry pixels keep the facades from looking too regular.
    for _ in range(52):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        draw.rectangle((x, y, x + rng.choice((1, 2, 3)), y), fill=color(rng.choice((base, shadow, highlight))))
    return image


def canopy_texture(seed: int = 41) -> Image.Image:
    rng = random.Random(seed)
    image = Image.new("RGBA", (SIZE, SIZE), color(PALETTE["leaf_dark"]))
    draw = ImageDraw.Draw(image)
    for _ in range(280):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        width = rng.choice((2, 3, 4, 5, 7))
        height = rng.choice((2, 3, 4, 6))
        tone = rng.choices(
            ("leaf_dark", "leaf_mid", "leaf_light", "leaf_sun"),
            weights=(25, 42, 27, 6),
        )[0]
        wrapped_rect(draw, (x, y, x + width, y + height), PALETTE[tone])
    for _ in range(22):
        x, y = rng.randrange(SIZE), rng.randrange(SIZE)
        wrapped_rect(draw, (x, y, x + 2, y), "#b4c86b")
    return image


def wood_texture() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), color("#76513c"))
    draw = ImageDraw.Draw(image)
    bands = ("#654333", "#8e6345", "#a2784f", "#573d34", "#936447")
    for y in range(0, SIZE, 8):
        draw.rectangle((0, y, SIZE - 1, y + 2), fill=color(bands[(y // 8) % len(bands)]))
        draw.rectangle((0, y + 3, SIZE - 1, y + 3), fill=color("#bd9160"))
    for x in range(12, SIZE, 32):
        draw.rectangle((x, 0, x + 1, SIZE - 1), fill=color("#543c35"))
    return image


def fabric_texture(cape: bool = False) -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), color("#e9dfc9"))
    draw = ImageDraw.Draw(image)
    for y in range(SIZE):
        for x in range(SIZE):
            if (x // 8 + y // 8) % 2 == 0:
                draw.point((x, y), fill=color("#f4ead3"))
    for y in range(0, SIZE, 32):
        draw.rectangle((0, y, SIZE - 1, y + 1), fill=color("#c1b7a5"))
    if cape:
        for x in range(0, SIZE, 32):
            draw.rectangle((x, 0, x + 2, SIZE - 1), fill=color("#b6aa98"))
        for y in range(12, SIZE, 32):
            draw.rectangle((0, y, SIZE - 1, y + 2), fill=color("#f8eed8"))
    return image


def water_texture() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), color("#397b85"))
    draw = ImageDraw.Draw(image)
    for y in range(4, SIZE, 12):
        phase = (y // 12) % 2
        for x in range(phase * 12, SIZE, 32):
            draw.rectangle((x, y, x + 13, y + 1), fill=color("#75b5b0"))
            draw.rectangle((x + 3, y + 2, x + 9, y + 2), fill=color("#4c9492"))
    for x in range(7, SIZE, 37):
        for y in range(9, SIZE, 41):
            draw.point((x, y), fill=color("#a1c9b4"))
    return image


def crest_texture() -> Image.Image:
    image = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Pixel-sharp shield silhouette, inset rim, skyline and heroic star.
    shield = [(24, 16), (104, 16), (104, 70), (96, 88), (64, 116), (32, 88), (24, 70)]
    draw.polygon(shield, fill=color("#d8bd6b"))
    inner = [(32, 24), (96, 24), (96, 68), (88, 82), (64, 104), (40, 82), (32, 68)]
    draw.polygon(inner, fill=color("#17333e"))
    for x, width, height, shade in (
        (39, 12, 34, "#6b8992"),
        (53, 14, 48, "#8ca6a2"),
        (69, 11, 39, "#65818b"),
        (82, 8, 28, "#a4b3a0"),
    ):
        draw.rectangle((x, 68 - height, x + width, 68), fill=color(shade))
        for wy in range(72 - height, 66, 9):
            draw.rectangle((x + 3, wy, x + 5, wy + 3), fill=color("#e6c86e"))
    draw.rectangle((39, 70, 90, 73), fill=color("#d8bd6b"))
    star = [(64, 42), (69, 54), (82, 55), (72, 63), (76, 76), (64, 68), (52, 76), (56, 63), (46, 55), (59, 54)]
    draw.polygon(star, fill=color("#f0d887"))
    return image


def main() -> None:
    save(grass_texture(7), "grass_meadow.png")
    save(grass_texture(19, flowers=True), "grass_wildflower.png")
    save(stone_texture(16, 21, "#554f46", ("#8d8776", "#b7aa8b", "#c7b99a", "#a69a7e")), "stone_path.png")
    save(stone_texture(32, 13, "#77786f", ("#a7a99b", "#bebca7", "#91958a", "#cfcaaf")), "promenade.png")
    save(facade_texture("#a9604c", "#704638", "#d18c62", "#85a9b2", 4), "facade_terracotta.png")
    save(facade_texture("#bba987", "#81745d", "#e0cda1", "#80a8b5", 7), "facade_limestone.png")
    save(facade_texture("#637783", "#3c5662", "#9db7b5", "#83c1d1", 11), "facade_glass.png")
    save(facade_texture("#85877f", "#565e60", "#b9b6a6", "#8eafba", 17), "facade_slate.png")
    save(canopy_texture(), "tree_canopy.png")
    save(wood_texture(), "wood_pixel.png")
    save(fabric_texture(), "suit_weave.png")
    save(fabric_texture(cape=True), "cape_weave.png")
    save(water_texture(), "park_water.png")
    save(stone_texture(16, 29, "#746853", ("#b3a17d", "#d0bc91", "#8c7c62", "#c4ad82")), "curb_stone.png")
    save(crest_texture(), "hero_town_crest.png")


if __name__ == "__main__":
    main()
