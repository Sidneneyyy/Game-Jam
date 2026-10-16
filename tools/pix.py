"""Pixel helpers for Forgotten Acorns: a small canvas with shapes, shading and an
auto outline, plus sprite-sheet export (PNG + JSON meta that Godot turns into
SpriteFrames). Every sprite gets the same warm 1px outline."""
import json
import math
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "game", "assets")
INK = (34, 22, 18, 255)  # warm near-black outline used on everything


def rgb(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3)) + (255,)


class Px:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.p = [[None] * w for _ in range(h)]
        self.ox = self.oy = 0  # drawing offset (lets a pose spill past its nominal box)

    # --- primitives -------------------------------------------------------
    def dot(self, x, y, c):
        x, y = int(round(x + self.ox)), int(round(y + self.oy))
        if c is not None and 0 <= x < self.w and 0 <= y < self.h:
            self.p[y][x] = rgb(c) if isinstance(c, str) else c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.p[y][x]
        return None

    def clear(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.p[y][x] = None

    def rect(self, x, y, w, h, c):
        for j in range(int(h)):
            for i in range(int(w)):
                self.dot(x + i, y + j, c)

    def oval(self, cx, cy, rx, ry, shade):
        """Filled ellipse. `shade` is a colour or fn(nx, ny) -> colour, with
        nx, ny in -1..1 relative to the centre (light comes from top-left)."""
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                nx = (x + 0.5 - cx) / max(rx, 0.5)
                ny = (y + 0.5 - cy) / max(ry, 0.5)
                if nx * nx + ny * ny <= 1.0:
                    self.dot(x, y, shade(nx, ny) if callable(shade) else shade)

    def line(self, x0, y0, x1, y1, c, w=1):
        n = int(max(abs(x1 - x0), abs(y1 - y0), 1))
        for i in range(n + 1):
            t = i / n
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            for k in range(w):
                self.dot(x + (k if abs(y1 - y0) > abs(x1 - x0) else 0), y + (0 if abs(y1 - y0) > abs(x1 - x0) else k), c)

    def ascii(self, rows, x, y, pal, flip=False):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in ". " or ch not in pal:
                    continue
                xx = x + (len(row) - 1 - i if flip else i)
                self.dot(xx, y + j, pal[ch])

    # --- whole-image ops --------------------------------------------------
    def outlined(self, col=INK, diag=False):
        o = Px(self.w, self.h)
        o.p = [row[:] for row in self.p]
        nb = [(1, 0), (-1, 0), (0, 1), (0, -1)] + ([(1, 1), (-1, -1), (1, -1), (-1, 1)] if diag else [])
        for y in range(self.h):
            for x in range(self.w):
                if self.p[y][x] is None and any(self.get(x + dx, y + dy) is not None and self.get(x + dx, y + dy) != col for dx, dy in nb):
                    o.p[y][x] = col
        return o

    def flipped(self):
        o = Px(self.w, self.h)
        o.p = [row[::-1] for row in self.p]
        return o

    def paste(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                if other.p[y][x] is not None:
                    self.dot(ox + x, oy + y, other.p[y][x])

    def recolor(self, fn):
        o = Px(self.w, self.h)
        o.p = [[fn(c) if c is not None else None for c in row] for row in self.p]
        return o

    def image(self):
        im = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                if self.p[y][x] is not None:
                    im.putpixel((x, y), self.p[y][x])
        return im


def ramp(cols):
    """Shade fn for oval(): picks from a light->dark ramp by top-left lighting."""
    cs = [rgb(c) if isinstance(c, str) else c for c in cols]

    def f(nx, ny):
        v = (nx * 0.55 + ny * 0.85) * 0.5 + 0.5  # 0 lit .. 1 shadow
        return cs[min(len(cs) - 1, int(v * len(cs)))]
    return f


def hashf(*a):
    h = 2166136261
    for v in a:
        h = ((h ^ (int(v) & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
    return (h % 10007) / 10007.0


# --- export -----------------------------------------------------------------
def save(name, img, sub):
    d = os.path.join(ASSETS, sub)
    os.makedirs(d, exist_ok=True)
    im = img.image() if isinstance(img, Px) else img
    im.save(os.path.join(d, name + ".png"))
    return im


def sheet(name, fw, fh, anims, sub="sprites"):
    """anims: [(anim, [Px...], fps, loop)] -> one row per animation + meta json."""
    cols = max(len(fr) for _, fr, _, _ in anims)
    im = Image.new("RGBA", (fw * cols, fh * len(anims)), (0, 0, 0, 0))
    meta = {"w": fw, "h": fh, "anims": {}}
    for row, (an, frames, fps, loop) in enumerate(anims):
        for i, f in enumerate(frames):
            im.paste(f.image(), (i * fw, row * fh))
        meta["anims"][an] = {"row": row, "n": len(frames), "fps": fps, "loop": loop}
    d = os.path.join(ASSETS, sub)
    os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, name + ".png"))
    with open(os.path.join(d, name + ".json"), "w") as fh_:
        json.dump(meta, fh_, indent=1)
    return im


def zoom(img, path, k=6, bg=(84, 110, 70, 255)):
    big = Image.new("RGBA", img.size, bg)
    big.alpha_composite(img)
    big.resize((img.width * k, img.height * k), Image.NEAREST).save(path)
