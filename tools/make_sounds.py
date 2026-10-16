"""All sound for Forgotten Acorns, synthesised with numpy: chirpy SFX and four
seasonal music loops (plus a title loop). 22.05 kHz 16-bit mono WAV."""
import os
import wave

import numpy as np

SR = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "game", "assets", "audio")
rs = np.random.RandomState(3)


def t_(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, r=0.1, curve=3.0):
    e = np.ones(n)
    na, nr = max(1, int(a * SR)), max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na)
    if nr < n:
        e[-nr:] = np.linspace(1, 0, nr) ** curve
    return e


def osc(kind, f, d, f2=None):
    t = t_(d)
    fr = np.full(len(t), float(f)) if f2 is None else np.linspace(f, f2, len(t))
    ph = 2 * np.pi * np.cumsum(fr) / SR
    if kind == "sin":
        return np.sin(ph)
    if kind == "tri":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    if kind == "sq":
        return np.sign(np.sin(ph)) * 0.6
    if kind == "saw":
        return ((ph / np.pi) % 2 - 1) * 0.6
    raise ValueError(kind)


def noise(d, lp=1.0):
    x = rs.uniform(-1, 1, int(SR * d))
    if lp < 1.0:  # one-pole low-pass
        y = np.zeros_like(x)
        a = lp
        for i in range(1, len(x)):
            y[i] = y[i - 1] + a * (x[i] - y[i - 1])
        x = y / max(1e-6, np.abs(y).max())
    return x


def cat(*parts, gap=0.0):
    g = np.zeros(int(gap * SR))
    out = []
    for p in parts:
        out += [p, g]
    return np.concatenate(out)


def mixl(*parts):
    n = max(len(p) for p in parts)
    o = np.zeros(n)
    for p in parts:
        o[:len(p)] += p
    return o


def write(name, x, sub="sfx", vol=0.8):
    os.makedirs(os.path.join(OUT, sub), exist_ok=True)
    x = np.asarray(x, dtype=float)
    peak = np.abs(x).max() or 1.0
    x = np.clip(x / peak * vol, -1, 1)
    with wave.open(os.path.join(OUT, sub, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def sfx():
    s = {}
    s["pickup"] = osc("sq", 880, 0.07, 1320) * env(int(SR * .07), r=.05) * 0.5
    s["eat"] = cat(*[noise(0.04, 0.5) * env(int(SR * .04), r=.03) for _ in range(3)], gap=0.05)
    s["munch"] = cat(*[noise(0.03, 0.3) * env(int(SR * .03), r=.02) * 0.7 for _ in range(2)], gap=0.04)
    s["berry"] = osc("tri", 1200, 0.08, 1600) * env(int(SR * .08), r=.06)
    s["bury"] = mixl(noise(0.18, 0.08) * env(int(SR * .18), r=.15), osc("sin", 160, 0.12, 90) * env(int(SR * .12), r=.1) * 0.6)
    s["dig"] = cat(noise(0.07, 0.25) * env(int(SR * .07), r=.05), noise(0.07, 0.3) * env(int(SR * .07), r=.05), gap=0.03)
    s["climb"] = cat(*[noise(0.025, 0.6) * env(int(SR * .025), r=.02) * 0.6 for _ in range(5)], gap=0.035)
    s["burrow"] = mixl(noise(0.3, 0.06) * env(int(SR * .3), a=.02, r=.25), osc("sin", 420, 0.25, 140) * env(int(SR * .25), r=.2) * 0.4)
    s["burrow_made"] = cat(*[osc("tri", f, 0.09) * env(int(SR * .09), r=.07) for f in (523, 659, 784, 1047)])
    s["deny"] = osc("sq", 200, 0.12, 150) * env(int(SR * .12), r=.08) * 0.5
    s["hurt"] = mixl(osc("saw", 520, 0.22, 180) * env(int(SR * .22), r=.18), noise(0.15, 0.4) * env(int(SR * .15), r=.12) * 0.4)
    bark = lambda f: mixl(osc("saw", f, 0.13, f * 0.6) * env(int(SR * .13), a=.01, r=.08), noise(0.1, 0.3) * env(int(SR * .1), r=.08) * 0.5)
    s["bark"] = cat(bark(330), bark(300), gap=0.08)
    s["bark2"] = bark(360)
    s["hawk"] = mixl(osc("saw", 1900, 0.6, 1100) * env(int(SR * .6), a=.04, r=.35) * 0.6, osc("sin", 2400, 0.6, 1500) * env(int(SR * .6), a=.04, r=.3) * 0.3)
    s["whoosh"] = noise(0.45, 0.15) * np.concatenate([np.linspace(0, 1, int(SR * .3)), np.linspace(1, 0, int(SR * .15))])
    s["hit"] = mixl(noise(0.25, 0.35) * env(int(SR * .25), r=.2), osc("sq", 140, 0.25, 70) * env(int(SR * .25), r=.2) * 0.6)
    tb = t_(0.5)
    s["buzz"] = osc("saw", 210, 0.5) * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * tb)) * env(len(tb), a=.08, r=.15) * 0.5
    s["sting"] = mixl(osc("sq", 1500, 0.1, 900) * env(int(SR * .1), r=.08), noise(0.08, 0.6) * env(int(SR * .08), r=.06) * 0.5)
    s["chatter"] = cat(*[osc("sq", f, 0.035, f * 1.3) * env(int(SR * .035), r=.025) for f in (1500, 1700, 1400, 1800, 1550, 1650)], gap=0.025)
    s["steal"] = cat(*[osc("tri", f, 0.07) * env(int(SR * .07), r=.05) for f in (784, 659, 523, 392)])
    s["flee"] = osc("sq", 1300, 0.18, 2200) * env(int(SR * .18), r=.12) * 0.6
    s["yip"] = cat(osc("saw", 900, 0.09, 1400) * env(int(SR * .09), r=.06), osc("saw", 1000, 0.12, 700) * env(int(SR * .12), r=.08), gap=0.05)
    s["sniff"] = cat(*[noise(0.05, 0.2) * env(int(SR * .05), a=.01, r=.04) * 0.6 for _ in range(3)], gap=0.05)
    s["sparkle"] = cat(*[osc("sin", f, 0.05) * env(int(SR * .05), r=.04) * 0.6 for f in (2093, 2637, 3136)])
    s["sprout"] = cat(*[osc("tri", f, 0.12) * env(int(SR * .12), r=.1) for f in (392, 523, 659, 784, 1047)])
    s["season"] = cat(*[mixl(osc("tri", f, 0.16), osc("sin", f * 2, 0.16) * 0.3) * env(int(SR * .16), r=.12) for f in (523, 659, 784, 1047)])
    s["warn"] = cat(osc("sq", 988, 0.06) * env(int(SR * .06), r=.04), osc("sq", 988, 0.06) * env(int(SR * .06), r=.04), gap=0.08) * 0.6
    s["fluff"] = osc("sin", 300, 0.14, 520) * env(int(SR * .14), r=.1)
    s["shiver"] = osc("sq", 180, 0.3) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 22 * t_(0.3)))) * env(int(SR * .3), r=.1) * 0.4
    s["death"] = cat(*[osc("tri", f, 0.25) * env(int(SR * .25), r=.2) for f in (523, 440, 349, 262)])
    s["win"] = cat(*[mixl(osc("tri", f, 0.16), osc("sin", f / 2, 0.16) * 0.5) * env(int(SR * .16), r=.12) for f in (523, 659, 784, 659, 784, 1047, 1319)])
    s["ui"] = osc("sq", 1200, 0.03) * env(int(SR * .03), r=.02) * 0.4
    s["step_snow"] = noise(0.06, 0.4) * env(int(SR * .06), r=.05) * 0.4
    tr = t_(4.0)
    s["rain"] = noise(4.0, 0.7) * (0.6 + 0.2 * np.sin(2 * np.pi * 0.5 * tr)) * env(len(tr), a=.6, r=.8, curve=1)
    # ambience one-shots, sprinkled in by season
    def chirp(f0, n, gap):
        parts = []
        for i in range(n):
            x = osc("sin", f0 * (1 + 0.08 * (i % 2)), 0.06, f0 * 1.35) * env(int(SR * .06), a=.005, r=.05)
            parts.append(x)
        return cat(*parts, gap=gap)
    s["amb_bird1"] = chirp(2600, 3, 0.05) * 0.5
    s["amb_bird2"] = cat(chirp(3100, 2, 0.03), chirp(2400, 2, 0.04), gap=0.12) * 0.45
    tc = t_(0.9)
    s["amb_cricket"] = osc("sq", 4200, 0.9) * (np.sin(2 * np.pi * 28 * tc) > 0.3) * env(len(tc), a=.05, r=.2) * 0.12
    s["amb_leaves"] = noise(0.9, 0.5) * np.abs(np.sin(np.linspace(0, 3 * np.pi, int(SR * .9)))) * env(int(SR * .9), a=.1, r=.3) * 0.35
    tw_ = t_(2.2)
    s["amb_wind"] = noise(2.2, 0.05) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.4 * tw_ - 1.5)) * env(len(tw_), a=.6, r=.8, curve=1) * 0.8
    s["amb_owl"] = cat(osc("sin", 420, 0.22, 380) * env(int(SR * .22), a=.03, r=.15), osc("sin", 400, 0.42, 340) * env(int(SR * .42), a=.03, r=.3), gap=0.18) * 0.6
    gain = {"deny": 0.45, "flee": 0.5, "pickup": 0.45, "shiver": 0.45, "ui": 0.4, "chatter": 0.55,
            "fluff": 0.55, "amb_cricket": 0.22}
    for k, v in s.items():
        write(k, v, vol=gain.get(k, 0.75 if not k.startswith("amb_") else 0.4))


# --------------------------------------------------------------------- music
NOTE = lambda m: 440.0 * 2 ** ((m - 69) / 12)


def voice(kind, midi, d, vol, a=0.01, r=None):
    if midi is None:
        return np.zeros(int(SR * d))
    x = osc(kind, NOTE(midi), d)
    return x * env(len(x), a=a, r=r if r is not None else d * 0.6) * vol


def song(bpm, beats_per_bar, bars, lead, bass, lead_kind, bass_kind, perc=None, pad=None):
    beat = 60 / bpm
    beats = max(sum(dd for _, dd in lead), sum(dd for _, dd in bass), sum(dd for _, dd in (pad or [])))
    bars = max(bars, int(np.ceil(beats / beats_per_bar)))
    total = int(SR * beat * beats_per_bar * bars)
    out = np.zeros(total + SR)
    def place(x, at):
        i = int(at * SR)
        if i >= len(out):
            return
        x = x[:len(out) - i]
        out[i:i + len(x)] += x
    for track, kind, vol in ((lead, lead_kind, 0.22), (bass, bass_kind, 0.26)):
        at = 0.0
        for (m, d) in track:
            place(voice(kind, m, d * beat * 0.95, vol), at)
            at += d * beat
    if pad:
        at = 0.0
        for chord, d in pad:
            for m in chord:
                place(voice("sin", m, d * beat, 0.07, a=0.3, r=d * beat * 0.4), at)
            at += d * beat
    if perc:
        for b in range(int(beats_per_bar * bars)):
            k = perc[b % len(perc)]
            if k == "k":
                place(osc("sin", 120, 0.12, 50) * env(int(SR * .12), r=.1) * 0.35, b * beat)
            elif k == "h":
                place(noise(0.04) * env(int(SR * .04), r=.03) * 0.08, b * beat)
            elif k == "s":
                place(noise(0.1, 0.5) * env(int(SR * .1), r=.08) * 0.15, b * beat)
    return out[:total]


def seq(notes, d=1):
    return [(n, d) for n in notes]


def _tr(seq, k):
    return [(None if n is None else n + k, l) for n, l in seq]


def _thin(seq, every):
    return [((None if i % every == every - 1 else n), l) for i, (n, l) in enumerate(seq)]


def form(a, bass, pads, b_shift=5, c_shift=-2):
    """A B A C: the theme, the theme up a fourth with gaps, the theme, the theme backwards and lower."""
    lead = a + _thin(_tr(a, b_shift), 4) + a + _tr(a[::-1], c_shift)
    bs = bass + _tr(bass, b_shift) + bass + _tr(bass, c_shift)
    pd = pads + [(tuple(n + b_shift for n in ch), l) for ch, l in pads] + pads + [(tuple(n + c_shift for n in ch), l) for ch, l in pads]
    return lead, bs, pd


def music():
    _ = None
    # spring: light plucky major, 104 bpm
    a = seq([72, 74, 76, 79, 76, 74, 72, _, 74, 76, 79, 81, 79, 76, 74, _,
             72, 76, 79, 84, 81, 79, 76, 74, 72, 74, 76, 74, 72, _, _, _], 0.5)
    lead, bass, pads = form(a, seq([48, 55, 52, 55, 50, 57, 53, 57, 48, 55, 52, 55, 43, 50, 47, 50], 1),
                            [((60, 64, 67), 4), ((62, 65, 69), 4), ((60, 64, 67), 4), ((55, 59, 62), 4)])
    write("spring", song(104, 4, 16, lead, bass, "tri", "sin", "khsh", pads), "music", 0.6)
    # summer: bright and bouncy, 124 bpm
    a = seq([79, 81, 83, 86, 83, 81, 79, 76, 78, 79, 81, 83, 81, 79, 78, _,
             79, 83, 86, 88, 86, 83, 81, 79, 76, 78, 79, 81, 79, _, _, _], 0.5)
    lead, bass, pads = form(a, seq([43, 43, 50, 50, 40, 40, 47, 47, 45, 45, 52, 52, 38, 38, 45, 45], 1),
                            [((55, 59, 62), 4), ((52, 55, 59), 4), ((57, 60, 64), 4), ((50, 54, 57), 4)], 5, -5)
    write("summer", song(124, 4, 16, lead, bass, "sq", "tri", "kshs", pads), "music", 0.55)
    # autumn: gentle minor waltz, 3/4 at 96 bpm
    a = seq([69, 72, 76, 74, 72, 71, 69, _, 67, 69, 71, 72, 71, 69, 67, _, _, _,
             69, 72, 76, 77, 76, 74, 72, 71, 69, 71, 72, 69, 68, _, _, _, _, _], 0.5)
    lead, bass, pads = form(a, seq([45, 52, 52, 43, 50, 50, 41, 48, 48, 40, 47, 47], 1),
                            [((57, 60, 64), 3), ((55, 59, 62), 3), ((53, 57, 60), 3), ((52, 56, 59), 3)], 3, -2)
    write("autumn", song(96, 3, 16, lead, bass, "tri", "sin", "khh", pads), "music", 0.55)
    # winter: sparse music-box bells, 66 bpm
    a = seq([76, _, 79, 81, _, 79, 76, _, 74, _, 76, 72, _, _, _, _], 1)
    lead, bass, pads = form(a, seq([45, _, _, _, 41, _, _, _, 43, _, _, _, 40, _, _, _], 1),
                            [((57, 60, 64), 4), ((53, 57, 60), 4), ((55, 59, 62), 4), ((52, 55, 59), 4)], 5, -3)
    write("winter", song(66, 4, 16, lead, bass, "sin", "sin", None, pads), "music", 0.55)
    # title: calm, a little of every season
    a = seq([72, 76, 79, 76, 74, 77, 81, 77, 72, 76, 79, 84, 83, 79, 76, 74], 1)
    lead, bass, pads = form(a, seq([48, _, 53, _, 50, _, 55, _, 48, _, 53, _, 43, _, 47, _], 1),
                            [((60, 64, 67), 4), ((62, 65, 69), 4), ((60, 64, 67), 4), ((55, 59, 62), 4)])
    write("title", song(84, 4, 16, lead, bass, "tri", "sin", None, pads), "music", 0.5)


if __name__ == "__main__":
    sfx()
    music()
    print("audio ok")
