#!/usr/bin/env python3
"""Draw the osmanthus-jelly and cheese-foam topping icons in the existing icon
family style, fully deterministically (no RNG, no manual art).

Family contract, measured from game/assets/icons/{pudding,coconut_jelly}.png:
128x128 RGBA, ~33% opaque footprint, a soft-shaded white round bowl in the
lower two thirds (x 14..108, y ~43..105) with a slightly gray rim gradient,
the food subject sitting on top (x ~30..91, y ~29..62), three-tone soft
shading, a light specular, and no dark outline.

Canonical subject colors come from game/data/ingredients.json (`color` is the
same single source of truth the in-cup liquid uses). Shapes are authored as
pixel-space signed-distance fields, drawn on a 4x supersample and downscaled
with LANCZOS for clean anti-aliased edges.

Run: tools/.venv/bin/python tools/gen_ingredient_icons.py
Writes: game/assets/icons/osmanthus_jelly.png, game/assets/icons/cheese_foam.png
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ICONS_DIR = ROOT / "game/assets/icons"
INGREDIENTS = ROOT / "game/data/ingredients.json"

SS = 4  # supersample factor: draw at 512, ship at 128
SIZE = 128 * SS
FEATHER = 1.6  # shipped-pixel edge feather


def hex_rgb(value: str) -> tuple[float, float, float]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def mix(rgb, t: float) -> tuple[float, float, float]:
    """Blend a color toward white (t>0) or black (t<0)."""
    o = 255.0 if t >= 0 else 0.0
    k = abs(t)
    return tuple(c * (1 - k) + o * k for c in rgb)  # type: ignore[return-value]


def coords() -> tuple[np.ndarray, np.ndarray]:
    ys, xs = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64)
    # Author in 128-space coordinates: (0,0) top-left of the shipped icon.
    return xs / SS, ys / SS


def soft_mask(sdf: np.ndarray, feather: float = FEATHER) -> np.ndarray:
    """0..1 mask from a signed distance in shipped pixels (~feather wide edge)."""
    return np.clip(0.5 - sdf / feather, 0.0, 1.0)


def ellipse_sdf(x, y, cx, cy, rx, ry, rot=0.0) -> np.ndarray:
    """Cheap ellipse SDF (exact for circles, fine for moderate aspect ratios)."""
    dx, dy = x - cx, y - cy
    c, s = np.cos(rot), np.sin(rot)
    u, v = c * dx + s * dy, -s * dx + c * dy
    return (np.hypot(u / rx, v / ry) - 1.0) * min(rx, ry)


def rounded_cube_sdf(x, y, cx, cy, w, h, r=6.0, rot=0.0) -> np.ndarray:
    """Rounded-rect SDF; w/h are full sizes, r the corner radius, in 128 px."""
    dx, dy = x - cx, y - cy
    c, s = np.cos(rot), np.sin(rot)
    u, v = c * dx + s * dy, -s * dx + c * dy
    qx, qy = np.abs(u) - (w / 2 - r), np.abs(v) - (h / 2 - r)
    outside = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0))
    inside = np.minimum(np.maximum(qx, qy), 0)
    return outside + inside - r


class Layer:
    """Float canvas accumulating color with soft alpha compositing."""

    def __init__(self) -> None:
        self.rgb = np.zeros((SIZE, SIZE, 3), dtype=np.float64)
        self.a = np.zeros((SIZE, SIZE), dtype=np.float64)

    def over(self, mask: np.ndarray, color) -> None:
        color = np.asarray(color, dtype=np.float64)
        a_new = mask * (1.0 - self.a) + self.a
        self.rgb = (self.rgb * self.a[..., None]
                    + color * (mask * (1.0 - self.a))[..., None])
        self.a = a_new

    def image(self) -> Image.Image:
        rgb = np.clip(self.rgb / np.maximum(self.a[..., None], 1e-6), 0, 255)
        rgba = np.dstack([rgb, self.a * 255.0]).astype(np.uint8)
        return Image.fromarray(rgba, "RGBA").resize((128, 128), Image.LANCZOS)


def shade(top_rgb, base_rgb, dark_rgb, top_y, bot_y, y, top_stop=0.55) -> np.ndarray:
    """Vertical 3-stop ramp (light top, base mid, dark bottom) as an HxWx3 array."""
    t = np.clip((y - top_y) / max(bot_y - top_y, 1e-6), 0.0, 1.0)
    stop = np.clip(t / top_stop, 0, 1)  # light->base over the top portion
    top_rgb, base_rgb, dark_rgb = (np.array(c, dtype=np.float64) for c in (top_rgb, base_rgb, dark_rgb))
    ramp_lb = top_rgb + (base_rgb - top_rgb) * stop[..., None]
    ramp_bd = base_rgb + (dark_rgb - base_rgb) * np.clip((t - top_stop) / (1.0 - top_stop), 0, 1)[..., None]
    return np.where((t <= top_stop)[..., None], ramp_lb, ramp_bd)


def bowl(x, y) -> Layer:
    """The shared white ceramic bowl of the topping family."""
    layer = Layer()
    body = ellipse_sdf(x, y, 61.5, 74, 47.5, 29)
    layer.over(soft_mask(body), (250, 249, 245))
    # Rim: slightly cooler white ring + inner face.
    rim = ellipse_sdf(x, y, 61.5, 69.5, 46.5, 26)
    inner = ellipse_sdf(x, y, 61.5, 70.5, 41, 21.5)
    ring = np.clip(soft_mask(rim) - soft_mask(inner), 0, 1)
    layer.over(ring * 0.85, (232, 230, 224))
    layer.over(soft_mask(inner) * 0.55, (240, 238, 232))
    # Bottom shadow (ambient occlusion under the bowl).
    shadow = ellipse_sdf(x, y, 61.5, 101, 42, 7)
    layer.over(soft_mask(shadow, 2.2) * 0.5, (186, 182, 176))
    # Soft specular on the upper-left rim.
    spec = ellipse_sdf(x, y, 33, 61, 9.5, 5, -0.5)
    layer.over(soft_mask(spec) * 0.75, (255, 255, 255))
    return layer


def draw_osmanthus_jelly(base_hex: str) -> Image.Image:
    x, y = coords()
    layer = bowl(x, y)
    base = hex_rgb(base_hex)
    light = mix(base, 0.45)
    dark = mix(base, -0.22)
    face = mix(base, 0.25)  # dominant bright top face

    cubes = [  # (cx, cy, w, h) — two below, one resting on top, like the family
        (48, 56, 30, 24),
        (74, 54, 30, 25),
        (61.5, 39, 27, 22),
    ]
    for i, (cx, cy, w, h) in enumerate(cubes):
        m = soft_mask(rounded_cube_sdf(x, y, cx, cy, w, h))
        col = shade(light, face, dark, cy - h / 2, cy + h / 2, y, top_stop=0.45)
        layer.over(m, col)
        # Specular blob upper-left of each cube.
        spec = ellipse_sdf(x, y, cx - w * 0.22, cy - h * 0.28, w * 0.2, h * 0.16, -0.4)
        layer.over(soft_mask(spec) * m * 0.4, light)
        # Bottom ambient occlusion where the cube meets its neighbor/bowl.
        ao = ellipse_sdf(x, y, cx, cy + h * 0.34, w * 0.42, h * 0.2)
        layer.over(soft_mask(ao, 2.0) * m * 0.35, dark)

    # Osmanthus flower specks: tiny 4-petal clusters pressed into the jelly.
    specks = [(54, 34.5), (69, 42.5), (43, 51), (80, 49), (61.5, 58.5)]
    petal = hex_rgb("#f7d98b")
    for sx, sy in specks:
        hit = np.zeros((SIZE, SIZE), dtype=np.float64)
        for ang in (0.0, np.pi / 2):
            p = soft_mask(ellipse_sdf(x, y, sx, sy, 2.6, 1.1, ang))
            hit = np.maximum(hit, p)
        layer.over(hit * 0.8 * layer.a, petal)

    # Cast shadow of the cube stack onto the bowl.
    cast = ellipse_sdf(x, y, 61.5, 68, 34, 8)
    layer.over(soft_mask(cast, 2.2) * 0.3, (205, 200, 192))
    return layer.image()


def draw_cheese_foam(base_hex: str) -> Image.Image:
    x, y = coords()
    layer = bowl(x, y)
    base = hex_rgb(base_hex)
    light = mix(base, 0.5)
    dark = mix(base, -0.08)

    # Cheese foam: three overlapping soft-serve swirls forming a rounded cap.
    domes = [  # (cx, cy, rx, ry): two shoulders + one crown
        (47, 55, 17.5, 13.5),
        (76, 55, 17.5, 13.5),
        (61.5, 42.5, 17, 14),
    ]
    foam_field = np.minimum.reduce([ellipse_sdf(x, y, cx, cy, rx, ry)
                                    for cx, cy, rx, ry in domes])
    foam = soft_mask(foam_field)
    col = shade(light, base, dark, 28.5, 68, y, top_stop=0.28)
    layer.over(foam, col)
    # Soft highlight band across the crown (glossy milk cap).
    spec = ellipse_sdf(x, y, 56, 36.5, 9, 4.5, -0.35)
    layer.over(soft_mask(spec) * foam * 0.7, light)
    # Creases between swirls: gentle darker arcs.
    for cx in (54.5, 68.5):
        crease = ellipse_sdf(x, y, cx, 48, 7.5, 13.5)
        ring = np.clip(soft_mask(crease) - soft_mask(ellipse_sdf(x, y, cx, 48, 4.5, 10.5)), 0, 1)
        layer.over(ring * foam * 0.18, dark)
    # Salt-golden finish: one thin warm drizzle line over the crown.
    drizzle = ellipse_sdf(x, y, 61.5, 32.5, 13.0, 2.6)
    layer.over(soft_mask(drizzle) * foam * 0.9, hex_rgb("#e8c987"))
    # Where foam meets the bowl: cast shadow.
    cast = ellipse_sdf(x, y, 61.5, 67, 32, 7)
    layer.over(soft_mask(cast, 2.2) * 0.32, (208, 203, 195))
    return layer.image()


def main() -> None:
    data = json.loads(INGREDIENTS.read_text())
    colors = {t["id"]: t["color"] for t in data["toppings"]}
    outputs = {
        "osmanthus_jelly": draw_osmanthus_jelly,
        "cheese_foam": draw_cheese_foam,
    }
    for tid, drawer in outputs.items():
        img = drawer(colors[tid])
        out = ICONS_DIR / f"{tid}.png"
        img.save(out)
        arr = np.array(img)
        opaque = (arr[:, :, 3] > 200).mean()
        print(f"wrote {out.relative_to(ROOT)} opaque={opaque:.0%}")


if __name__ == "__main__":
    main()
