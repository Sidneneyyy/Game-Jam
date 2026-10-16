"""Creatures: red squirrel (you, normal + fluffed for winter), grey rival squirrel,
park dog, winter fox, the hawk's dive blur, bees + hive. Side-profile sprites
facing right (the engine flips them), chunky low-fps animation."""
from pix import Px, ramp, rgb, mix, sheet, save, hashf, INK

RED = {
    "fur": ["f4ac64", "de8238", "bc5c28", "8e3e1c", "642814"],
    "tail": ["f6b878", "e0843c", "c0602a", "92421e", "6a2c16"],
    "belly": ["fbe6c0", "efcc96"],
    "ear": "642814",
}
RIVAL = {  # same species, darker chestnut coat so they read apart from you
    "fur": ["c27a4a", "9e5530", "7c3c1e", "582812", "3c180a"],
    "tail": ["cc8452", "a85c32", "84421e", "5e2c14", "40180a"],
    "belly": ["e4c49a", "c8a274"],
    "ear": "2e1208",
}

# tail centre-lines (relative to the body's rear) + radii
TAILS = {
    "up":    ([(-4, 1), (-7, -1), (-8, -4), (-8, -7), (-7, -10), (-4, -11)], [2.4, 3.0, 3.2, 3.1, 2.6, 1.9]),
    "up2":   ([(-4, 1), (-7, -1), (-9, -4), (-9, -7), (-8, -10), (-5, -11)], [2.4, 3.0, 3.2, 3.1, 2.6, 1.9]),
    "flat":  ([(-4, 0), (-7, -1), (-10, -2), (-12, -4), (-13, -6), (-12, -8)], [2.3, 2.8, 3.0, 2.9, 2.5, 1.8]),
    "flat2": ([(-4, 0), (-7, 0), (-10, -1), (-12, -2), (-14, -3), (-14, -5)], [2.3, 2.8, 3.0, 2.9, 2.5, 1.8]),
    "hang":  ([(-1, 3), (-2, 6), (-2, 9), (-1, 11), (1, 12)], [2.2, 2.6, 2.8, 2.4, 1.8]),
    "puff":  ([(-4, 1), (-8, -1), (-10, -4), (-10, -8), (-8, -11), (-5, -12)], [3.0, 3.8, 4.0, 3.9, 3.2, 2.4]),
}


def _tail(c, pal, bx, by, kind, fluffy):
    pts, rad = TAILS[kind]
    sh = ramp(pal["tail"])
    k = 1.0 + 0.32 * float(fluffy)
    for (dx, dy), r in zip(pts, rad):
        c.oval(bx + dx, by + dy, r * k, r * k, sh)
    # light fringe along the outer edge of the tail for that bushy look
    for (dx, dy), r in zip(pts, rad):
        c.dot(bx + dx - r * k + 0.5, by + dy - 0.5, pal["tail"][0])


def squirrel(pal, pose="stand", f=0, fluffy=False):
    """One 30x24 frame, feet on y=22, body centred on x=16, facing right."""
    c = Px(30, 24)
    c.ox, c.oy = 5, 4
    fur, belly = pal["fur"], pal["belly"]
    F = 2.6 * float(fluffy)  # 0 lean .. 1 winter-fluffy (a round little ball)
    cx = 11
    if pose in ("stand", "run", "dig", "hurt"):
        # (body dx, body dy, stretch, head dx, head dy, tail, front leg dx/lift, back leg dx/lift)
        P = {
            "stand": [(0, 0, 0, 0, 0, "up", 0, 0, 0, 0), (0, 0, 0, 0, 1, "up2", 0, 0, 0, 0)],
            "run": [(0, 0, -0.5, 0, 0, "up2", -1, 0, 1, 0),
                    (0, -2, 1.0, 1, -1, "flat", 3, 1, -3, 1),
                    (0, -3, 0.5, 1, -2, "flat2", 1, 2, -1, 2),
                    (0, -1, 0, 0, 0, "up", 2, 0, -2, 1)],
            "dig": [(0, 1, 0, 1, 4, "up", 2, 1, 0, 0), (0, 0, 0, 1, 5, "up2", 3, 0, 0, 0), (0, 1, 0, 0, 4, "up", 1, 2, 0, 0)],
            "hurt": [(0, -1, -0.5, 0, -2, "puff", 0, 1, 0, 1)],
        }[pose][f]
        bdx, bdy, st, hdx, hdy, tail, fdx, flift, bkdx, blift = P
        bx, by = cx + bdx, 13 + bdy
        _tail(c, pal, bx, by, tail, fluffy)
        # back haunch + feet
        c.oval(bx - 2 + bkdx * 0.3, by + 1.5, 2.6 + F * 0.6, 2.4 + F * 0.4, ramp(fur[1:]))
        c.rect(bx - 3 + bkdx, 17 - blift, 3, 1, fur[3])
        # body
        def body(nx, ny):
            if nx > 0.05 and ny > 0.15:
                return rgb(belly[0] if ny < 0.6 else belly[1])
            return ramp(fur)(nx, ny)
        c.oval(bx, by, 4.6 + st + F, 3.4 + F * 0.8, body)
        # front leg
        c.rect(bx + 3 + fdx, by + 2 - flift, 1, 3 + max(0, 1 - flift), fur[3])
        c.dot(bx + 4 + fdx, by + 4 - flift + max(0, 1 - flift), fur[4])
        # head
        hx, hy = bx + 5 + hdx, 9 + bdy + hdy
        c.oval(hx, hy, 3.3 + F * 0.4, 3.0 + F * 0.3, ramp(fur))
        c.oval(hx + 1.5, hy + 1.2, 1.6, 1.2, rgb(belly[0]))       # cheek / muzzle
        c.dot(hx + 3.5, hy + 0.5, "3a2018")                        # nose
        c.dot(hx + 1, hy - 1, INK); c.dot(hx + 1, hy, INK)         # eye
        c.dot(hx + 1.5, hy - 1.6, "fff6e0") if pose != "hurt" else None
        c.dot(hx - 1, hy - 3, pal["ear"]); c.dot(hx - 1, hy - 4, pal["ear"]); c.dot(hx - 2, hy - 5, pal["ear"])  # tufted ear
        c.dot(hx, hy - 3, fur[2])
        if pose == "hurt":
            c.dot(hx + 1, hy - 1, "ffffff"); c.dot(hx + 2, hy, INK)
    elif pose in ("sit", "eat", "fight"):
        lean = [0, 1][f % 2] if pose == "sit" else 0
        bx, by = cx, 12
        _tail(c, pal, bx - 1, by + 3, "puff" if pose == "fight" else ("up" if f % 2 == 0 else "up2"), fluffy)
        def body(nx, ny):
            if nx > 0.0 and ny > -0.3:
                return rgb(belly[0] if ny < 0.4 else belly[1])
            return ramp(fur)(nx, ny)
        c.oval(bx - 1, by + 4, 3.2 + F, 2.4 + F * 0.4, ramp(fur[1:]))   # haunch
        c.oval(bx, by + 1, 3.6 + F, 5.0 + F * 0.6, body)
        c.rect(bx - 2, 17, 4, 1, fur[3])
        hx, hy = bx + 2 + lean, 5 - (1 if pose == "fight" else 0)
        if pose == "eat":
            hy += [0, 1][f % 2]
        c.oval(hx, hy, 3.2 + F * 0.4, 3.0, ramp(fur))
        c.oval(hx + 1.5, hy + 1.2, 1.6, 1.2, rgb(belly[0]))
        c.dot(hx + 3.5, hy + 0.5, "3a2018")
        c.dot(hx + 1, hy - 1, INK); c.dot(hx + 1, hy, INK); c.dot(hx + 1.5, hy - 1.6, "fff6e0")
        c.dot(hx - 1, hy - 3, pal["ear"]); c.dot(hx - 1, hy - 4, pal["ear"]); c.dot(hx - 2, hy - 5, pal["ear"])
        # arms: at the chest (sit), at the mouth (eat), thrown out (fight)
        if pose == "eat":
            c.rect(hx + 1, hy + 3 - f % 2, 2, 2, fur[3])
            c.dot(hx + 2, hy + 2 - f % 2, "b07038")  # the acorn
            c.dot(hx + 3, hy + 2 - f % 2, "6a4020")
        elif pose == "fight":
            c.line(bx + 2, by - 1, bx + 6, by - 3 - f, fur[3])
            c.dot(bx + 6, by - 4 - f, INK)
            c.dot(hx + 2, hy + 2, "ffffff")  # bared teeth
        else:
            c.rect(bx + 2, by, 2, 1, fur[3])
    elif pose == "climb":
        # clinging to a trunk (on its right), head up, tail curled up its back
        bx, by = cx, 11 + [0, -1][f]
        sh = ramp(pal["tail"])
        k = 1.0 + 0.32 * float(fluffy)
        for (dx, dy), r in zip([(-3, 6), (-5, 3), (-6, 0), (-6, -3), (-5, -6)], [2.0, 2.4, 2.6, 2.4, 2.0]):
            c.oval(bx + dx, by + dy, r * k, r * k, sh)
        def body(nx, ny):
            if nx > 0.35:
                return rgb(belly[0] if ny < 0.4 else belly[1])
            return ramp(fur)(nx, ny)
        c.oval(bx, by, 3.0 + F * 0.6, 4.6 + F * 0.4, body)
        hx, hy = bx + 1, by - 6
        c.oval(hx, hy, 2.6 + F * 0.2, 2.6, ramp(fur))
        c.dot(hx + 1, hy - 3, fur[1]); c.dot(hx + 1, hy - 4, "3a2018")     # snout up, nose
        c.dot(hx + 1, hy - 1, INK)                                         # eye
        c.dot(hx - 1, hy - 3, pal["ear"]); c.dot(hx - 2, hy - 4, pal["ear"])  # ear tuft
        up = [0, 2][f]
        c.rect(bx + 3, by - 3 - up, 2, 1, fur[3]); c.dot(bx + 5, by - 3 - up, fur[4])   # front paws
        c.rect(bx + 3, by + 3 + up // 2, 2, 1, fur[3]); c.dot(bx + 5, by + 3 + up // 2, fur[4])  # hind feet
    if fluffy > 0:
        _fringe(c, pal, fluffy)
    return c.outlined()


def _fringe(c, pal, fluffy):
    """Fluffed-up fur: little tufts poking out of the silhouette, lighter tips."""
    tip = pal["fur"][0]
    pts = []
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] is not None and c.p[y][x] != INK:
                for dx, dy in ((1, 0), (-1, 0), (0, -1)):
                    if c.get(x + dx, y + dy) is None and hashf(x, y, dx * 3 + dy) < 0.22 * fluffy:
                        pts.append((x + dx, y + dy))
    for x, y in pts:
        c.p[y][x] = rgb(tip) if 0 <= y < c.h and 0 <= x < c.w else None


def burrow_frame(pal, f, fluffy):
    """Diving head-first into a burrow: dig, half in, only the tail left."""
    if f == 0:
        return squirrel(pal, "dig", 1, fluffy)
    c = squirrel(pal, "dig", 0, fluffy)
    cut = 16 if f == 1 else 10  # everything right of `cut` is already underground
    for y in range(c.h):
        for x in range(c.w):
            if x > cut or (f == 2 and y > 15):
                c.clear(x, y)
    hole = Px(30, 24)
    hole.oval(18, 21, 6, 2.2, rgb("1e120c"))
    hole.paste(c, 0, 0)
    return hole.outlined()


def squirrel_sheet(name, pal, fluffy=0.0):
    S = lambda pose, f: squirrel(pal, pose, f, fluffy)
    return sheet(name, 30, 24, [
        ("burrow", [burrow_frame(pal, i, fluffy) for i in range(3)], 6, False),
        ("idle", [S("stand", 0), S("stand", 1)], 3.3, True),
        ("run", [S("run", i) for i in range(4)], 9, True),
        ("sit", [S("sit", 0), S("sit", 1)], 2.5, True),
        ("eat", [S("eat", 0), S("eat", 1)], 5, True),
        ("dig", [S("dig", i) for i in range(3)], 7, True),
        ("climb", [S("climb", 0), S("climb", 1)], 6, True),
        ("hurt", [S("hurt", 0)], 1, False),
        ("fight", [S("fight", 0), S("fight", 1)], 6, True),
    ])


# --------------------------------------------------------------------- dog
DOG = ["f6dc9c", "e2b46a", "c08c44", "8e602a", "62401c"]


def dog(pose, f):
    c = Px(36, 22)
    c.ox = 4
    by = {"run": [0, -2, -3, -1], "idle": [0, 0], "bark": [0, -1], "sniff": [1, 1]}[pose][f]
    bx = 14
    # tail
    wag = {"idle": [-2, 1], "bark": [0, 2], "run": [3, 4, 4, 3], "sniff": [-1, 1]}[pose][f]
    c.line(bx - 7, 11 + by, bx - 10 - (wag > 2) * 2, 6 + by + wag, DOG[2], 2)
    c.dot(bx - 10 - (wag > 2) * 2, 5 + by + wag, DOG[1])
    # legs (back pair, front pair)
    if pose == "run":  # gallop: legs gather, reach, fly, land
        L = [(-4, -2, 3, 5), (-8, -6, 7, 9), (-5, -3, 4, 6), (-3, -1, 6, 8)][f]
    else:
        L = (-5, -3, 4, 6)
    for i, lx in enumerate(L):
        x = bx + lx
        shade = DOG[3] if i % 2 else DOG[2]
        c.rect(x, 14 + by, 2, 6 - (1 if pose == "run" and f in (1, 2) and i % 2 else 0), shade)
        c.rect(x, 20 - (1 if pose == "run" and f in (1, 2) and i % 2 else 0), 3, 1, DOG[4])
    # body
    c.oval(bx, 12 + by, 8.5, 4.6, ramp(DOG))
    c.oval(bx + 5, 14 + by, 3, 2, rgb(DOG[0]))  # chest
    # head
    hd = 4 if pose == "sniff" else (-1 if pose == "bark" else 0)
    hx, hy = bx + 9, 7 + by + hd
    c.oval(hx, hy, 4.4, 4.0, ramp(DOG))
    c.rect(hx + 3, hy, 4, 3, DOG[1])              # snout
    c.rect(hx + 3, hy + 2, 4, 1, DOG[2])
    c.dot(hx + 7, hy, INK)                        # nose
    c.dot(hx + 2, hy - 1, INK)                    # eye
    c.line(hx - 2, hy - 3, hx - 4, hy + 3, DOG[4], 2)  # floppy ear
    c.rect(hx - 4, hy + 3, 2, 1, "c83a32")        # collar
    c.rect(hx - 3, hy + 4, 3, 1, "c83a32")
    c.dot(hx - 1, hy + 5, "f2c84a")               # tag
    if pose == "bark" and f == 1:
        c.rect(hx + 3, hy + 3, 3, 2, "7a1e1e")    # open mouth
        c.dot(hx + 4, hy + 4, "e86a7a")
    if pose == "run" and f in (1, 2):
        c.dot(hx + 4, hy + 4, "e86a7a"); c.dot(hx + 4, hy + 5, "e86a7a")  # tongue
    return c.outlined()


# --------------------------------------------------------------------- fox
FOX = ["f8b070", "e8803a", "c85e22", "943e16", "6a2a10"]
WHITE = "f8f4ec"


def fox(pose, f):
    c = Px(40, 18)
    c.ox = 6
    by = {"walk": [0, 0, -1, 0], "run": [0, -1, -2, -1], "pounce": [-1, -4], "sniff": [1, 1]}[pose][f]
    bx = 15
    # big bushy tail, white tip
    sway = [0, 1, 0, -1][f % 4]
    c.oval(bx - 13, 7 + by + sway, 7, 2.8, ramp(FOX))
    c.oval(bx - 19, 7 + by + sway, 2.6, 2.2, rgb(WHITE))
    # legs (black socks)
    if pose == "run":
        L = [(-5, 2, 5, -2), (-7, 0, 7, 0), (-3, -3, 3, 3), (-5, 1, 6, -1)][f]
    elif pose == "walk":
        L = [(-5, -3, 4, 6), (-4, -4, 5, 5), (-6, -2, 3, 6), (-5, -3, 5, 4)][f]
    elif pose == "pounce":
        L = [(-6, -4, 4, 6), (-8, -6, 8, 10)][f]
    else:
        L = (-5, -3, 4, 6)
    for i, lx in enumerate(L):
        c.rect(bx + lx, 11 + by, 1, 5, "2a1a14")
        c.dot(bx + lx + 1, 15 + by, "2a1a14")
    # body: long and low
    def body(nx, ny):
        if ny > 0.35 and nx > -0.2:
            return rgb(WHITE)
        return ramp(FOX)(nx, ny)
    c.oval(bx, 9 + by, 8.5, 3.4, body)
    # head
    hd = 3 if pose == "sniff" else (1 if pose == "walk" else 0)
    hx, hy = bx + 9, 6 + by + hd
    c.oval(hx, hy, 3.4, 2.8, ramp(FOX))
    c.line(hx + 2, hy, hx + 6, hy + 2, FOX[2])
    c.line(hx + 2, hy + 1, hx + 5, hy + 2, WHITE)
    c.dot(hx + 6, hy + 2, INK)                     # nose
    c.dot(hx + 1, hy - 1, INK)                     # eye
    for ex in (-1, 1):                             # pointed ears, black tips
        c.dot(hx + ex, hy - 3, FOX[2]); c.dot(hx + ex, hy - 4, "2a1a14")
    c.dot(hx - 1, hy - 2, FOX[1])
    return c.outlined()


# --------------------------------------------------------------------- hawk (top-down dive blur)
HAWK = ["e8d2a8", "c49a64", "966a3c", "6a4626", "46301a"]


def hawk(pose, f):
    c = Px(48, 44)
    cx, cy = 24, 22
    span = {"dive": [10, 13, 16], "strike": [21], "rise": [19, 15]}[pose][f]
    up = {"dive": [6, 5, 4], "strike": [0], "rise": [-2, 4]}[pose][f]
    # speed streaks (the blur): faint ghost lines around the body
    streak = rgb("fff4dc", 150)
    n = {"dive": 7, "strike": 4, "rise": 5}[pose]
    for i in range(n):
        x = cx - 14 + i * 28 / max(1, n - 1)
        ln = 6 + int(hashf(i, f, 3) * 8)
        y0 = 2 if pose != "rise" else 30
        for k in range(ln):
            c.dot(x, y0 + k + (i % 2) * 3, streak)
    # wings: swept triangles of feathers
    for side in (-1, 1):
        for t in range(span):
            x = cx + side * (3 + t)
            yb = cy - 2 + up * t / max(1, span) - (t // 4)
            w = max(2, 6 - t // 3)
            for k in range(w):
                col = HAWK[1 + min(3, (k + t // 5) % 4)] if k < w - 1 else HAWK[0]
                c.dot(x, yb + k, col)
            if t % 3 == 0 and t > 2:
                c.dot(x, yb + w, HAWK[3])  # primary feather tips
    # body, head, tail fan
    c.oval(cx, cy + 1, 3.2, 7.5, ramp(HAWK))
    c.oval(cx, cy - 7, 2.6, 2.6, ramp(HAWK))
    c.dot(cx, cy - 9, "f2c84a")  # beak
    c.oval(cx, cy + 9, 4.2, 2.4, ramp(HAWK[1:]))
    if pose == "strike":
        for side in (-1, 1):  # talons out
            c.line(cx + side * 2, cy + 3, cx + side * 4, cy + 7, "f2c84a")
            c.dot(cx + side * 4, cy + 8, INK)
    return c.outlined()


# --------------------------------------------------------------------- bees + hive
def bee(f):
    c = Px(7, 6)
    c.rect(2, 3, 4, 2, "f2c23a")
    c.rect(3, 3, 1, 2, "2a1a14"); c.rect(5, 3, 1, 2, "2a1a14")
    c.dot(6, 3, "2a1a14")
    wing = rgb("dff4ff")
    if f == 0:
        c.rect(2, 1, 2, 2, wing)
    else:
        c.rect(3, 2, 3, 1, wing)
    return c.outlined()


def hive(season, f=0):
    c = Px(14, 17)
    cols = ["fbe08a", "f2c24a", "d89a2c", "a86a1c"]
    c.line(7, 0, 7, 2, "6a4626")  # hanging from a branch
    rows = [(3, 3), (4, 4), (5, 5), (6, 5), (7, 5), (8, 5), (9, 4), (10, 4), (11, 3), (12, 2), (13, 1)]
    for y, hw in rows:
        band = (y // 2) % 2
        for x in range(7 - hw, 7 + hw + 1):
            k = (x - (7 - hw)) / max(1, 2 * hw)
            col = cols[0 if k < 0.25 else 1 if k < 0.6 else 2]
            if band:
                col = cols[min(3, cols.index(col) + 1)]
            c.dot(x, y, col)
    c.rect(6, 9, 2, 2, "3a2210")  # entrance
    if season == "winter":
        for x in range(3, 12):
            c.dot(x, 3 + (abs(x - 7) > 3), "ffffff")
    elif f == 1:
        c.dot(10, 11, "2a1a14"); c.dot(3, 7, "2a1a14")
    return c.outlined()


def build():
    squirrel_sheet("squirrel", RED)
    squirrel_sheet("squirrel_plump", RED, fluffy=0.5)
    squirrel_sheet("squirrel_fluffy", RED, fluffy=1.0)
    squirrel_sheet("rival", RIVAL)
    sheet("dog", 36, 22, [
        ("run", [dog("run", i) for i in range(4)], 10, True),
        ("idle", [dog("idle", i) for i in range(2)], 4, True),
        ("bark", [dog("bark", i) for i in range(2)], 5, True),
        ("sniff", [dog("sniff", i) for i in range(2)], 3, True),
    ])
    sheet("fox", 40, 18, [
        ("walk", [fox("walk", i) for i in range(4)], 5, True),
        ("run", [fox("run", i) for i in range(4)], 10, True),
        ("pounce", [fox("pounce", i) for i in range(2)], 6, False),
        ("sniff", [fox("sniff", i) for i in range(2)], 3, True),
    ])
    sheet("hawk", 48, 44, [
        ("dive", [hawk("dive", i) for i in range(3)], 10, False),
        ("strike", [hawk("strike", 0)], 1, False),
        ("rise", [hawk("rise", i) for i in range(2)], 8, True),
    ])
    sheet("bee", 7, 6, [("fly", [bee(0), bee(1)], 8, True)])
    for s in ("spring", "summer", "autumn", "winter"):
        sheet("hive_" + s, 14, 17, [("idle", [hive(s, 0), hive(s, 1)], 3, True)], "park")


if __name__ == "__main__":
    import os, sys
    from PIL import Image
    from pix import zoom
    build()
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    root = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "game", "assets", "sprites")
    ims = [Image.open(os.path.join(root, n + ".png")) for n in ("squirrel", "squirrel_fluffy", "rival", "dog", "fox", "hawk")]
    W = max(i.width for i in ims); H = sum(i.height + 2 for i in ims)
    board = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    y = 0
    for i in ims:
        board.alpha_composite(i, (0, y)); y += i.height + 2
    zoom(board, os.path.join(out, "creatures.png"), 3)
    print("ok", board.size)
