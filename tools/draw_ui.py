"""UI art: a chunky 5x7 pixel font (imported by Godot as an image font), HUD icons,
season icons, key / mouse glyphs for the wordless tutorial."""
import os

from PIL import Image

from pix import Px, rgb, save, ASSETS, INK

# Rounded, chunky 5x7 capitals + digits + punctuation ('#' = ink).
GLYPHS = {
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
    "D": ["###..", "#..#.", "#...#", "#...#", "#...#", "#..#.", "###.."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
    "X": ["#...#", ".#.#.", ".#.#.", "..#..", ".#.#.", ".#.#.", "#...#"],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "0": [".###.", "#..##", "#.#.#", "#.#.#", "##..#", "#...#", ".###."],
    "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
    " ": ["....."] * 7,
    ".": [".....", ".....", ".....", ".....", ".....", ".##..", ".##.."],
    ",": [".....", ".....", ".....", ".....", ".##..", "..#..", ".#..."],
    "!": ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
    "?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
    ":": [".....", ".##..", ".##..", ".....", ".##..", ".##..", "....."],
    "-": [".....", ".....", ".....", ".###.", ".....", ".....", "....."],
    "+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
    "/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
    "'": ["..#..", "..#..", ".#...", ".....", ".....", ".....", "....."],
    "(": ["...#.", "..#..", ".#...", ".#...", ".#...", "..#..", "...#."],
    ")": [".#...", "..#..", "...#.", "...#.", "...#.", "..#..", ".#..."],
    "%": ["##..#", "##.#.", "...#.", "..#..", ".#...", ".#.##", "#..##"],
    "<": ["...#.", "..#..", ".#...", "#....", ".#...", "..#..", "...#."],
    ">": [".#...", "..#..", "...#.", "....#", "...#.", "..#..", ".#..."],
    "=": [".....", ".....", "#####", ".....", "#####", ".....", "....."],
    "x": [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
}
FIRST, LAST, COLS = 32, 126, 16
CW, CH = 6, 9


def build_font():
    n = LAST - FIRST + 1
    rows = (n + COLS - 1) // COLS
    im = Image.new("RGBA", (COLS * CW, rows * CH), (0, 0, 0, 0))
    for i in range(n):
        ch = chr(FIRST + i)
        g = GLYPHS.get(ch) or GLYPHS.get(ch.upper()) or GLYPHS["?"]
        if ch == "x":
            g = GLYPHS["x"]
        cx, cy = (i % COLS) * CW, (i // COLS) * CH
        for y, row in enumerate(g):
            for x, v in enumerate(row):
                if v == "#":
                    im.putpixel((cx + x, cy + y + 1), (255, 255, 255, 255))
    d = os.path.join(ASSETS, "fonts")
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, "acorn5x7.png")
    im.save(path)
    with open(path + ".import", "w") as f:
        f.write(f"""[remap]

importer="font_data_image"
type="FontFile"
uid="uid://bacorn5x7font"
path="res://.godot/imported/acorn5x7.png-font.fontdata"

[deps]

source_file="res://assets/fonts/acorn5x7.png"
dest_files=["res://.godot/imported/acorn5x7.png-font.fontdata"]

[params]

character_ranges=PackedStringArray("{FIRST}-{LAST}")
kerning_pairs=PackedStringArray()
columns={COLS}
rows={rows}
image_margin=Rect2i(0, 0, 0, 0)
character_margin=Rect2i(0, 0, 0, 0)
ascent=0
descent=0
fallbacks=[]
compress=true
scaling_mode=2
""")


# --------------------------------------------------------------------- icons (9x9)
ICONS = {
    "acorn": ["..u.....", ".uUUu...", "uUUUUu..", ".aAAa...", ".AAAAa..", ".aAAAa..", "..aAa...", "...a...."],
    "acorn_empty": ["..g.....", ".g..g...", "g....g..", ".g..g...", ".g...g..", ".g...g..", "..g.g...", "...g...."],
    "hunger": ["........", ".aAAAa..", "aAAAAAa.", "aAyAAAa.", "aAAAAAa.", ".aAAAa..", "..aaa...", "........"],
    "fluff": ["..wW....", ".wWWw.w.", "wWWWWwWw", "WWWWWWWw", "wWWWWWWw", ".wWWWWw.", "..wwww..", "........"],
    "warm": ["...r....", "..rRr...", ".rRYRr..", ".rYYYr..", "rRYyYRr.", ".rRYRr..", "..rrr...", "........"],
    "tree": ["..GGG...", ".GgGGG..", "GgGGGGG.", "GGGGGGG.", ".GGGGG..", "...b....", "...b....", "..bbb..."],
    "bee": ["..c.c...", "...c....", ".YkYkY..", "YkYkYkY.", ".YkYkY..", "........", "........", "........"],
    "paw": [".a...a..", "...a....", ".a...a..", "..aaa...", ".aaaaa..", ".aaaaa..", "..aaa...", "........"],
    "heart": [".rr.rr..", "rRRrRRr.", "rRRRRRr.", ".rRRRr..", "..rRr...", "...r....", "........", "........"],
    "star": ["...Y....", "...Y....", "YYYYYYY.", ".YYYYY..", "..YYY...", ".YY.YY..", "Y.....Y.", "........"],
}
ICON_PAL = {
    "u": "6e4a2a", "U": "8e6438", "a": "9a6430", "A": "c08a4a", "g": "6a5a4a",
    "y": "f2cc90", "w": "e6dccc", "W": "fbf6ec", "r": "d8483a", "R": "f08a3a", "Y": "f8d84a",
    "G": "5ea83e", "b": "74502e", "c": "dff4ff", "k": "2a1a14",
}

SEASON_ICONS = {
    "spring": ["...pp.....", "..pPPp....", "..pPPp.gg.", "...pp.ggG.", "....g.gG..", "....gGg...", ".....g....", ".....g....", "....ggg...", "..........", "..........", ".........."],
    "summer": ["....Y.....", ".Y..Y..Y..", "..YYYYY...", ".YYyyyYY..", "YYyyyyyYY.", ".YYyyyYY..", "..YYYYY...", ".Y..Y..Y..", "....Y.....", ".........."],
    "autumn": ["......oO..", ".....oOO..", "....oOOO..", "...oOOOo..", "..oOOOo...", ".oOOOo....", ".oOOo.....", "o.oo......", "o.........", ".........."],
    "winter": ["....c.....", "..c.c.c...", "...ccc....", "cc.cCc.cc.", "..cCCCc...", "cc.cCc.cc.", "...ccc....", "..c.c.c...", "....c.....", ".........."],
}
SEASON_PAL = {"p": "f6a8c4", "P": "fbd2e0", "g": "4e963a", "G": "a8dc70", "Y": "f8c83a", "y": "fff0a0",
              "o": "c44e22", "O": "f2a83a", "c": "a8d8f8", "C": "ffffff"}


def icon(rows, pal, w=9, h=9):
    c = Px(w, h)
    c.ascii(rows, 0, 0, pal)
    return c.outlined()


def key_cap(label, w=None):
    w = w or (len(label) * 6 + 5)
    c = Px(w, 13)
    for y in range(1, 12):
        for x in range(1, w - 1):
            top = y < 10
            col = "ece4d4" if top else "a89e8e"
            if x in (1, w - 2) and top:
                col = "c8beae"
            c.dot(x, y, col)
    tx = (w - len(label) * 6 + 1) // 2
    for i, ch in enumerate(label):
        for y, row in enumerate(GLYPHS.get(ch, GLYPHS["?"])):
            for x, v in enumerate(row):
                if v == "#":
                    c.dot(tx + i * 6 + x, 2 + y, "3a2a20")
    return c.outlined()


def mouse(button):
    c = Px(11, 14)
    body = ["..ddddddd..", ".dbbbdbbbd.", "dbbbbdbbbbd", "dbbbbdbbbbd", "ddddddddddd", "dbbbbbbbbbd", "dbbbbbbbbbd", "dbbbbbbbbbd", ".dbbbbbbbd.", "..ddddddd.."]
    pal = {"d": "a89e8e", "b": "ece4d4"}
    c.ascii(body, 0, 1, pal)
    lit = "f0524a"
    for y in (2, 3, 4):
        for x in (range(1, 5) if button == "left" else range(6, 10)):
            if c.get(x, y) == rgb("ece4d4"):
                c.dot(x, y, lit)
    return c.outlined()


def arrow_up():
    c = Px(7, 7)
    c.ascii(["...w...", "..www..", ".wwwww.", "www.www", "..www..", "..www..", "..www.."], 0, 0, {"w": "fbf6ec"})
    return c.outlined()


def acorn_tiny():
    c = Px(5, 6)
    c.dot(2, 0, "4e321c")
    c.rect(1, 1, 3, 1, "6e4a2a")
    c.rect(1, 2, 3, 2, "c08a4a"); c.dot(1, 2, "e2b070")
    c.dot(2, 4, "9a6430")
    return c.outlined()


def build():
    build_font()
    save("acorn_tiny", acorn_tiny(), "ui")
    for n, rows in ICONS.items():
        save("icon_" + n, icon(rows, ICON_PAL), "ui")
    for n, rows in SEASON_ICONS.items():
        save("season_" + n, icon(rows, SEASON_PAL, 11, 11), "ui")
    for k in ["W", "A", "S", "D", "E", "F", "SHIFT", "SPACE", "ESC"]:
        save("key_" + k, key_cap(k), "ui")
    save("mouse_left", mouse("left"), "ui")
    save("mouse_right", mouse("right"), "ui")
    save("arrow_up", arrow_up(), "ui")
    # app icon: the squirrel's face on an acorn-brown tile
    from PIL import Image as I
    sq = I.open(os.path.join(ASSETS, "sprites", "squirrel.png")).crop((0, 24 * 3, 30, 24 * 4))
    ic = I.new("RGBA", (32, 32), (78, 52, 30, 255))
    ic.alpha_composite(sq, (1, 4))
    ic.resize((128, 128), I.NEAREST).save(os.path.join(os.path.dirname(ASSETS), "icon.png"))


if __name__ == "__main__":
    build()
    print("ui ok")
