"""Park art (top-down, 3/4 view): oaks in 4 seasons (trunk + canopy split so the
canopy can fade when you're under it), sprouts, saplings, burrow, flowers, bushes,
acorns, stashes, footprints, props, and the single-screen park ground per season."""
import math
import random

import numpy as np
from PIL import Image

from pix import Px, ramp, rgb, mix, save, sheet, hashf, INK, ASSETS

SEASONS = ["spring", "summer", "autumn", "winter"]
W, H = 384, 216  # the whole park is one screen

LEAVES = {
    "spring": ["d4f0a0", "a8dc70", "78bc4c", "4e963a", "336e2c"],
    "summer": ["a6d460", "6eae3a", "4a8a2c", "326a24", "22501c"],
    "autumn": None,  # mixed per clump below
    "winter": None,
}
AUTUMN_CLUMPS = [
    ["fcd27a", "f2a83a", "d87a24", "aa5418", "7a3a12"],
    ["f8b06a", "e8743a", "c44e22", "963418", "6a2410"],
    ["f6dc7c", "e6b440", "c0902a", "8e6a1e", "5e4614"],
]
BARK = ["c49a6c", "9a6e44", "74502e", "523620", "3a2416"]
SNOW = ["ffffff", "eef6fc", "d2e4f2", "a8c4dc"]


# --------------------------------------------------------------------- oak
def trunk(season):
    c = Px(14, 20)
    for y in range(0, 18):
        w = 4 if y < 12 else 4 + (y - 11) // 2
        x0 = 7 - w // 2 - (1 if y > 14 else 0)
        for i in range(w + (2 if y > 15 else 0)):
            k = i / max(1, w + 1)
            col = BARK[1] if k < 0.25 else BARK[2] if k < 0.7 else BARK[3]
            if (y * 3 + i * 5) % 9 == 0:
                col = BARK[3]
            c.dot(x0 + i, y, col)
    c.dot(5, 17, BARK[3]); c.dot(9, 17, BARK[3]); c.dot(3, 18, BARK[2]); c.dot(11, 18, BARK[2])  # roots
    if season == "winter":
        for x in range(2, 13):
            c.dot(x, 18 + (x % 3 == 0), SNOW[1])
    return c.outlined()


CLUMPS = [(0, -1, 11), (-9, 3, 8), (9, 3, 8), (-6, -7, 8), (7, -6, 8), (0, 6, 9), (-11, -2, 6), (12, -1, 6), (1, -10, 7)]


def canopy(season, variant=0):
    """44x38 leafy crown seen from above at 3/4; light from top-left, dark rim below."""
    c = Px(44, 38)
    cx, cy = 22, 19
    rng = random.Random(7 + variant)
    if season == "winter":
        # bare crown: branches radiating from the trunk top, snow along their tops
        for i in range(9):
            a = -math.pi / 2 + (i - 4) * 0.42 + rng.uniform(-0.1, 0.1)
            ln = rng.uniform(12, 18)
            x1, y1 = cx + math.cos(a) * ln * 1.15, cy + 6 + math.sin(a) * ln * 0.9
            c.line(cx, cy + 6, x1, y1, BARK[2])
            for t in (0.5, 0.8):  # forks
                fx, fy = cx + (x1 - cx) * t, cy + 6 + (y1 - cy - 6) * t
                b = a + rng.choice([-0.7, 0.7])
                c.line(fx, fy, fx + math.cos(b) * 5, fy + math.sin(b) * 4, BARK[1])
                c.dot(fx + math.cos(b) * 5, fy + math.sin(b) * 4 - 1, SNOW[0])
            c.dot(x1, y1 - 1, SNOW[0]); c.dot(x1 + 1, y1 - 1, SNOW[1])
        c.oval(cx, cy + 6, 3, 2, rgb(BARK[2]))
        for _ in range(26):  # snow caught on the branches
            x, y = rng.randint(4, 40), rng.randint(3, 32)
            if c.get(x, y + 1) is not None:
                c.dot(x, y, SNOW[0])
        return c.outlined()
    order = sorted(CLUMPS, key=lambda b: b[1])
    for idx, (dx, dy, r) in enumerate(order):
        cols = LEAVES[season] if season != "autumn" else AUTUMN_CLUMPS[(idx + variant) % 3]
        sh = ramp(cols[:4])
        bx, by = cx + dx, cy + dy
        for y in range(int(by - r - 1), int(by + r + 2)):
            for x in range(int(bx - r - 1), int(bx + r + 2)):
                nx, ny = (x - bx) / r, (y - by) / (r * 0.86)
                d = nx * nx + ny * ny
                edge = 1.0 + (hashf(x, y, idx) - 0.5) * 0.28
                if d > edge:
                    continue
                col = sh(nx, ny)
                if d > 0.72 and ny > 0.1:
                    col = rgb(cols[4]) if hashf(x, y) > 0.35 else rgb(cols[3])  # shadowed rim
                if hashf(x * 3, y * 7, idx) > 0.9:
                    col = rgb(cols[0]) if ny < 0 else rgb(cols[3])        # leaf glints
                c.dot(x, y, col)
    # seasonal details
    if season == "spring":
        for _ in range(16):
            x, y = rng.randint(6, 38), rng.randint(4, 30)
            if c.get(x, y) is not None:
                c.dot(x, y, "fbd2e0"); c.dot(x + 1, y, "f6a8c4")
    if season == "summer":
        for _ in range(6):
            x, y = rng.randint(8, 36), rng.randint(6, 28)
            if c.get(x, y) is not None:
                c.dot(x, y, "f4f0a0")
    if season == "autumn":
        for _ in range(9):  # acorns hanging in the crown
            x, y = rng.randint(8, 36), rng.randint(8, 30)
            if c.get(x, y) is not None:
                c.dot(x, y, "5e3a1e"); c.dot(x, y + 1, "b88446")
    return c.outlined()


def sapling(season):
    c = Px(22, 26)
    for y in range(12, 25):
        c.dot(11, y, BARK[2]); c.dot(10, y, BARK[1]) if y > 18 else None
    if season == "winter":
        for a, ln in [(-2.2, 7), (-1.0, 8), (-1.6, 9)]:
            c.line(11, 14, 11 + math.cos(a) * ln, 14 + math.sin(a) * ln, BARK[2])
            c.dot(11 + math.cos(a) * ln, 13 + math.sin(a) * ln, SNOW[0])
        for x in range(8, 15):
            c.dot(x, 25, SNOW[1])
        return c.outlined()
    cols = LEAVES[season] if season != "autumn" else AUTUMN_CLUMPS[0]
    for (dx, dy, r) in [(0, -1, 6), (-4, 2, 4), (4, 2, 4), (0, -5, 4)]:
        c.oval(11 + dx, 10 + dy, r, r * 0.85, ramp(cols[:4]))
    if season == "spring":
        c.dot(9, 7, "fbd2e0"); c.dot(13, 10, "fbd2e0")
    return c.outlined()


def sprout(season):
    c = Px(12, 12)
    c.oval(6, 10, 3, 1.2, rgb("6a4a30") if season != "winter" else rgb(SNOW[2]))
    c.line(6, 10, 6, 5, "4e8a32" if season != "winter" else BARK[2])
    if season == "winter":
        c.dot(6, 4, SNOW[0])
        return c.outlined()
    leaf = {"spring": ("a8dc70", "78bc4c"), "summer": ("6eae3a", "4a8a2c"), "autumn": ("f2a83a", "c44e22")}[season]
    c.oval(4, 5, 2, 1.2, rgb(leaf[0])); c.oval(8, 4, 2, 1.2, rgb(leaf[1]))
    return c.outlined()


def burrow(season):
    c = Px(14, 8)
    c.oval(7, 4, 6, 3, rgb("8a6440") if season != "winter" else rgb(SNOW[2]))
    c.oval(7, 4.5, 4, 2, rgb("1e120c"))
    c.dot(5, 3, "3a2416")
    if season == "winter":
        for x in range(2, 12):
            c.dot(x, 1 + (x % 4 == 0), SNOW[0])
    return c.outlined()


def shadow(rx, ry, a=70):
    c = Px(rx * 2 + 2, ry * 2 + 2)
    c.oval(rx + 1, ry + 1, rx, ry, (20, 32, 18, a))
    return c


# --------------------------------------------------------------------- small things
FLOWERS = {
    "daisy": {"petal": "fbf8f0", "petal2": "e6e0d4", "eye": "f6c63a"},
    "tulip": {"petal": "f0524a", "petal2": "c0302e", "eye": "f8a088"},
    "bell": {"petal": "a690f0", "petal2": "7a64cc", "eye": "e4dcff"},
}


def flower(kind, f):
    c = Px(11, 13)
    k = FLOWERS[kind]
    sway = [0, 1][f]
    c.line(5, 12, 5 + sway, 6, "4a8a32")
    c.dot(4, 10, "6eae3a"); c.dot(3, 9, "6eae3a"); c.dot(6, 9, "4a8a32"); c.dot(7, 8, "4a8a32")
    hx, hy = 5 + sway, 4
    if kind == "daisy":
        for dx, dy in [(-2, 0), (2, 0), (0, -2), (0, 2), (-1, -1), (1, 1), (1, -1), (-1, 1)]:
            c.dot(hx + dx, hy + dy, k["petal"] if dy <= 0 else k["petal2"])
        c.dot(hx, hy, k["eye"])
    elif kind == "tulip":
        c.rect(hx - 1, hy - 1, 3, 3, k["petal"]); c.dot(hx - 1, hy - 2, k["petal"]); c.dot(hx + 1, hy - 2, k["petal"])
        c.dot(hx + 1, hy + 1, k["petal2"]); c.dot(hx - 1, hy - 1, k["eye"])
    else:
        c.rect(hx - 1, hy - 1, 3, 2, k["petal"]); c.dot(hx - 2, hy + 1, k["petal2"]); c.dot(hx + 2, hy + 1, k["petal2"])
        c.dot(hx, hy + 1, k["petal2"]); c.dot(hx - 1, hy - 1, k["eye"])
    return c.outlined()


def flower_eaten():
    c = Px(11, 13)
    c.line(5, 12, 5, 9, "4a8a32"); c.dot(4, 11, "6eae3a"); c.dot(6, 10, "4a8a32")
    return c.outlined()


BUSH = {
    "spring": ["c4e88c", "8ccc5c", "5ea83e", "3e7e2e", "2a5a22"],
    "summer": ["9ccc54", "62a032", "447e26", "2e5e1e", "1e4416"],
    "autumn": ["f2c060", "d68a34", "aa5e22", "7a3e18", "522812"],
    "winter": SNOW + ["7a96b0"],
}


def bush(season, berries=0):
    c = Px(26, 18)
    cols = BUSH[season]
    for dx, dy, r in [(-6, 1, 6), (6, 1, 6), (0, -2, 7), (0, 3, 6)]:
        c.oval(13 + dx, 10 + dy, r, r * 0.8, ramp(cols[:4]))
    if season == "winter":
        for x in range(4, 22, 3):
            c.dot(x, 13, "8aa2b8")
    if season == "spring":
        for x, y in [(8, 6), (16, 5), (12, 11), (19, 10), (5, 11)]:
            c.dot(x, y, "ffffff")
    for x, y in [(8, 8), (17, 7), (12, 12), (19, 11), (6, 12), (13, 5)][:berries]:
        c.dot(x, y, "d8283c"); c.dot(x + 1, y, "a81a2e"); c.dot(x, y - 1, "ff7a88")
    return c.outlined()


def acorn():
    c = Px(8, 9)
    c.oval(4, 5.5, 2.6, 2.8, ramp(["e2b070", "c08a4a", "9a6430", "6e4420"]))
    c.rect(1, 2, 6, 2, "6e4a2a"); c.dot(2, 2, "8e6438"); c.dot(4, 2, "8e6438"); c.dot(6, 3, "4e321c")
    c.dot(4, 1, "4e321c"); c.dot(4, 0, "4e321c")
    c.dot(3, 5, "f2cc90")
    return c.outlined()


def stash(season, n=1):
    """A freshly dug, patted-down mound; a bigger stash is a bigger mound."""
    c = Px(14, 9)
    if season == "winter":
        c.oval(7, 6, 4.5, 2, rgb("e6f0f8")); c.dot(6, 4, "ffffff")
        return c  # snow bump, deliberately hard to see (no outline)
    dirt = ["c49a68", "a07648", "7c5634", "56381e"]
    big = n >= 3
    rx, ry = (5.2, 3.2) if big else (4.2, 2.6)
    c.oval(7, 6, rx, ry, ramp(dirt))
    # crumbs kicked out around it
    for x, y in [(1, 7), (12, 6), (2, 4), (13, 8)][: 2 + big * 2]:
        c.dot(x, y, dirt[2])
    c.dot(6, 4, dirt[0]); c.dot(7, 4 if big else 5, dirt[0])     # patted top
    c.dot(5, 6, dirt[3]); c.dot(9, 7, dirt[3])                    # paw marks
    if season == "autumn":
        c.dot(10, 4, "d87a24"); c.dot(3, 8, "f2a83a")
    if season == "spring":
        c.dot(11, 5, "78bc4c")
    return c.outlined()


def sparkle(f):
    c = Px(7, 7)
    pts = [[(3, 3)], [(3, 2), (3, 4), (2, 3), (4, 3), (3, 3)], [(3, 0), (3, 1), (3, 5), (3, 6), (0, 3), (1, 3), (5, 3), (6, 3), (3, 3)]][f]
    for x, y in pts:
        c.dot(x, y, "fff6c0" if (x, y) != (3, 3) else "ffffff")
    return c


def print_fox():
    c = Px(5, 5)
    c.rect(1, 2, 3, 2, (110, 132, 160, 255))
    for x in (0, 2, 4):
        c.dot(x, 0 if x == 2 else 1, (110, 132, 160, 255))
    return c


def print_sq():
    c = Px(4, 3)
    c.dot(0, 0, (140, 160, 184, 255)); c.dot(1, 1, (140, 160, 184, 255)); c.dot(3, 0, (140, 160, 184, 255)); c.dot(2, 2, (140, 160, 184, 255))
    return c


# --------------------------------------------------------------------- props
def bench(season):
    c = Px(30, 18)
    wood = ["d8a468", "b07a44", "84562c", "5a3a1e"]
    for i, y in enumerate((3, 6)):  # backrest slats
        c.rect(2, y, 26, 2, wood[1 + i])
    for y in (10, 12, 14):          # seat slats
        c.rect(1, y, 28, 2, wood[0] if y == 10 else wood[1 + (y == 14)])
    for x in (3, 25):
        c.rect(x, 2, 2, 16, "3a3a42"); c.dot(x, 2, "6a6a74")
    if season == "winter":
        c.rect(2, 9, 26, 2, SNOW[0]); c.rect(3, 2, 24, 1, SNOW[0])
    if season == "autumn":
        c.dot(8, 11, "d87a24"); c.dot(20, 13, "e6b440"); c.dot(14, 12, "c44e22")
    return c.outlined()


def lamp(season):
    c = Px(10, 34)
    c.rect(4, 8, 2, 25, "3e4048"); c.rect(3, 31, 4, 2, "2e3038"); c.dot(4, 8, "6a6e78")
    c.rect(2, 2, 6, 6, "2e3038"); c.rect(3, 3, 4, 4, "f8dc84"); c.dot(3, 3, "fff4c8")
    c.rect(1, 1, 8, 1, "2e3038"); c.dot(4, 0, "2e3038"); c.dot(5, 0, "2e3038")
    if season == "winter":
        c.rect(1, 0, 8, 1, SNOW[0])
    return c.outlined()


def bin_(season):
    c = Px(12, 15)
    c.rect(2, 3, 8, 11, "4e7a4a"); c.rect(2, 3, 2, 11, "6a9a62"); c.rect(8, 3, 2, 11, "385a36")
    c.rect(1, 1, 10, 2, "2e4a2c"); c.rect(3, 6, 6, 1, "385a36"); c.rect(3, 10, 6, 1, "385a36")
    if season == "winter":
        c.rect(1, 0, 10, 2, SNOW[0])
    return c.outlined()


def rock(season, v):
    c = Px(14, 10)
    cols = ["c4c0b8", "a09a92", "7c766e", "5a544e"]
    c.oval(7, 6, 6 - v, 3.4, ramp(cols))
    c.oval(5 + v, 5, 2.5, 1.6, ramp(cols[:3]))
    if season == "winter":
        c.oval(7, 4, 4.5 - v, 1.4, rgb(SNOW[0]))
    elif season == "spring":
        c.dot(10, 7, "6eae3a"); c.dot(3, 8, "6eae3a")
    return c.outlined()


def fence_h(season):
    c = Px(16, 12)
    c.rect(0, 4, 16, 2, "8e6640"); c.rect(0, 8, 16, 2, "74502e")
    for x in (2, 10):
        c.rect(x, 1, 3, 11, "b48a5c"); c.rect(x + 2, 1, 1, 11, "8e6640"); c.dot(x + 1, 0, "b48a5c")
    if season == "winter":
        for x in (2, 10):
            c.rect(x, 0, 3, 1, SNOW[0])
        c.rect(0, 4, 16, 1, SNOW[1])
    return c.outlined()


def fence_v(season):
    c = Px(8, 16)
    c.rect(3, 0, 2, 16, "74502e")
    c.rect(2, 5, 4, 5, "b48a5c"); c.rect(5, 5, 1, 5, "8e6640")
    if season == "winter":
        c.rect(2, 4, 4, 1, SNOW[0])
    return c.outlined()


# --------------------------------------------------------------------- ground (one screen)
GROUND = {
    "spring": dict(base=["7cbc4e", "6eae44", "62a03c", "56923a"], path=["c8a878", "b4946a", "9e805a"], fleck=["a8dc70", "fbd2e0", "ffffff"]),
    "summer": dict(base=["a2b84a", "94ac44", "86a03e", "78923a"], path=["d6b880", "c4a470", "ac8e5e"], fleck=["c8d26a", "6e8e30", "f4e070"]),
    "autumn": dict(base=["9ea04a", "8e9244", "7e843e", "6e7438"], path=["c4a074", "b08c64", "987854"], fleck=["e8802e", "c44e22", "f2b040"]),
    "winter": dict(base=["f4f8fc", "e8f0f8", "dae6f2", "c8d8ea"], path=["c6d2e0", "b4c2d4", "a2b2c6"], fleck=["ffffff", "b8cce0", "d6e4f0"]),
}


def path_dist(x, y):
    """Distance to the park's dirt path: a lazy loop plus a crossing track."""
    cx, cy = W / 2, H / 2 + 6
    a = np.arctan2((y - cy) / 66.0, (x - cx) / 128.0)
    r = np.sqrt(((x - cx) / 128.0) ** 2 + ((y - cy) / 66.0) ** 2)
    wob = 1.0 + 0.06 * np.sin(a * 3 + 1.3)
    loop = np.abs(r - wob) * 70.0
    cross = np.abs(y - (cy + 20 * np.sin(x / 60.0))) + np.where((x > 120) & (x < 264), 99, 0)
    return np.minimum(loop, cross)


def ground(season):
    g = GROUND[season]
    rs = np.random.RandomState(11)
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    # low-frequency value noise for big soft patches
    n = np.zeros((H, W))
    for scale, amp in ((48, 1.0), (20, 0.5), (8, 0.22)):
        gh, gw = H // scale + 2, W // scale + 2
        grid = rs.rand(gh, gw)
        im = Image.fromarray((grid * 255).astype(np.uint8)).resize((gw * scale, gh * scale), Image.BICUBIC)
        n += amp * (np.asarray(im, dtype=float)[:H, :W] / 255.0)
    n /= 1.72
    bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0
    dither = bayer[(yy.astype(int) % 4), (xx.astype(int) % 4)]
    lvl = np.clip((n * 4 + dither * 0.9 - 0.45).astype(int), 0, 3)
    base = np.array([rgb(c) for c in g["base"]], dtype=np.uint8)
    img = base[lvl]
    # path with soft dithered edge and darker rim
    pd = path_dist(xx, yy)
    pcol = np.array([rgb(c) for c in g["path"]], dtype=np.uint8)
    on = pd < 6.0 + dither * 1.6
    rim = (pd >= 6.0 + dither * 1.6) & (pd < 7.4 + dither)
    pl = np.clip((n * 3 + dither * 0.7 - 0.2).astype(int), 0, 2)
    img[on] = pcol[pl][on]
    img[rim] = pcol[2] if season != "winter" else pcol[1]
    out = Image.fromarray(img.copy(), "RGBA").copy()
    px = out.load()
    rng = random.Random(5)
    fl = [rgb(c) for c in g["fleck"]]
    # grass tufts / snow ripples / leaf litter / flowers specks
    for _ in range(900 if season != "winter" else 500):
        x, y = rng.randrange(2, W - 2), rng.randrange(2, H - 3)
        if path_dist(np.array(x, float), np.array(y, float)) < 8:
            continue
        if season == "winter":
            px[x, y] = fl[1] if rng.random() < 0.5 else fl[2]
            px[x + 1, y] = fl[0]
        elif season == "autumn" and rng.random() < 0.45:
            px[x, y] = fl[rng.randrange(3)]
        else:
            dark = rgb(g["base"][3]); light = fl[0]
            px[x, y + 1] = dark; px[x, y] = dark if rng.random() < 0.5 else light
            if rng.random() < 0.4:
                px[x + 2, y + 1] = dark; px[x + 2, y] = light
            if season == "spring" and rng.random() < 0.06:
                px[x + 1, y - 1] = fl[1 + rng.randrange(2)]
            if season == "summer" and rng.random() < 0.05:
                px[x + 1, y - 1] = fl[2]
    # hedge border round the park (outside the fence)
    hedge = BUSH[season] if season != "winter" else ["ffffff", "e6eef6", "c8d8ea", "a6bcd2", "8aa2b8"]
    for y in range(H):
        for x in range(W):
            e = min(x, W - 1 - x, y, H - 1 - y)
            if e < 5 + (hashf(x // 3, y // 3) * 3):
                k = min(4, int(e / 2 + hashf(x, y) * 1.5))
                px[x, y] = rgb(hedge[4 - k] if season != "winter" else hedge[k])
    return out


def build():
    for s in SEASONS:
        save("trunk_" + s, trunk(s), "park")
        for v in range(2):
            save(f"canopy{v}_{s}", canopy(s, v), "park")
        save("sapling_" + s, sapling(s), "park")
        save("sprout_" + s, sprout(s), "park")
        save("burrow_" + s, burrow(s), "park")
        for b in (0, 3, 6):
            save(f"bush{b}_{s}" if b else "bush_" + s, bush(s, b), "park")
        save("stash_" + s, stash(s, 1), "park")
        save("stash2_" + s, stash(s, 3), "park")
        save("bench_" + s, bench(s), "park")
        save("lamp_" + s, lamp(s), "park")
        save("bin_" + s, bin_(s), "park")
        for v in range(2):
            save(f"rock{v}_{s}", rock(s, v), "park")
        save("fence_h_" + s, fence_h(s), "park")
        save("fence_v_" + s, fence_v(s), "park")
        ground(s).save(f"{ASSETS}/park/ground_{s}.png")
    for k in FLOWERS:
        sheet("flower_" + k, 11, 13, [("idle", [flower(k, 0), flower(k, 1)], 2.5, True)], "park")
    save("flower_eaten", flower_eaten(), "park")
    save("acorn", acorn(), "park")
    save("shadow_tree", shadow(17, 6), "park")
    save("shadow_small", shadow(6, 2, 60), "park")
    save("print_fox", print_fox(), "park")
    save("print_squirrel", print_sq(), "park")
    sheet("sparkle", 7, 7, [("idle", [sparkle(0), sparkle(1), sparkle(2), sparkle(1)], 6, True)], "park")


if __name__ == "__main__":
    build()
    print("park ok")
