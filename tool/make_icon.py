"""Draws the Wellbite bowl icon masters into assets/icon/.

Run: python tool/make_icon.py   (needs Pillow), then
     dart run flutter_launcher_icons
"""
import math
from PIL import Image, ImageDraw

SS = 4          # supersampling factor
N = 1024
CREAM = (255, 233, 184, 255)


def bez(p0, p1, p2, p3, n=24):
    return [
        tuple(
            (1 - t) ** 3 * a + 3 * (1 - t) ** 2 * t * b + 3 * (1 - t) * t ** 2 * c + t ** 3 * d
            for a, b, c, d in zip(p0, p1, p2, p3)
        )
        for t in (i / n for i in range(n + 1))
    ]


def ellipse(cx, cy, rx, ry, deg, n=48):
    r = math.radians(deg)
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        x, y = rx * math.cos(a), ry * math.sin(a)
        pts.append((cx + x * math.cos(r) - y * math.sin(r), cy + x * math.sin(r) + y * math.cos(r)))
    return pts


def round_rect(x, y, w, h, r):
    pts = []
    for cx, cy, a0 in ((x + w - r, y + r, -90), (x + w - r, y + h - r, 0), (x + r, y + h - r, 90), (x + r, y + r, 180)):
        for i in range(13):
            a = math.radians(a0 + 90 * i / 12)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


# Shapes in a 120-unit design space, content centred on (60, 60).
def shapes():
    bowl = [(24, 60), (96, 60)] + bez((96, 60), (96, 88), (80, 102), (60, 102)) + bez((60, 102), (40, 102), (24, 88), (24, 60))
    return [
        (ellipse(47, 40, 6, 14, -30), (102, 187, 106)),
        (ellipse(73, 40, 6, 14, 30), (129, 199, 132)),
        (ellipse(60, 34, 6, 16, 0), (67, 160, 71)),
        (bowl, (46, 125, 50)),
        (round_rect(20, 55, 80, 9, 4.5), (27, 94, 32)),
    ]


def render(scale, background):
    img = Image.new("RGBA", (N * SS, N * SS), background)
    d = ImageDraw.Draw(img)
    off = N * SS / 2 - 60 * scale * SS
    for pts, color in shapes():
        d.polygon([(off + x * scale * SS, off + y * scale * SS) for x, y in pts], fill=color + (255,))
    return img.resize((N, N), Image.LANCZOS)


# iOS and legacy Android: full-bleed square, the OS applies the mask.
render(8.0, CREAM).convert("RGB").save("assets/icon/icon.png")
# Android adaptive: transparent foreground. flutter_launcher_icons insets it by
# 16% per side, so this is drawn large to land inside the 66% safe zone.
render(9.5, (0, 0, 0, 0)).save("assets/icon/foreground.png")
