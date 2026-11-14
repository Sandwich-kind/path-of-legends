"""Сочинитель: гармония, мелодия, бас, арпеджио, ударные — и сведение в слои.

Трек собирается по описанию (см. tracks.py) в три слоя одинаковой длины:
  base   — обычный бой: подклад, бас, арпеджио, мелодия, лёгкая перкуссия;
  battle — мини-босс: полные ударные, бас восьмыми, струнное остинато;
  boss   — босс: медь/хор, вторая мелодия, тайко и литавры, тарелки.
В игре слои играют одновременно, громкость каждого плавно меняется.
"""
import re
import numpy as np
import synth as S

SCALES = {
    "major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10], "lydian": [0, 2, 4, 6, 7, 9, 11], "mixolydian": [0, 2, 4, 5, 7, 9, 10],
    "harmonic": [0, 2, 3, 5, 7, 8, 11], "phrygdom": [0, 1, 4, 5, 7, 8, 10],
}
MAJOR = [0, 2, 4, 5, 7, 9, 11]
ROMAN = {"i": 0, "ii": 1, "iii": 2, "iv": 3, "v": 4, "vi": 5, "vii": 6}


def parse_chord(sym, scale):
    acc = 0
    s = sym
    natural = False
    if s.startswith("b"):
        acc, s = -1, s[1:]
    elif s.startswith("#"):
        acc, s = 1, s[1:]
    elif s.startswith("n"):
        natural, s = True, s[1:]          # ступень натурального мажора (минорная iv в лидийском)
    m = re.match(r"(VII|VI|IV|V|III|II|I|vii|vi|iv|v|iii|ii|i)(.*)", s)
    if not m:
        raise ValueError("bad chord " + sym)
    num, rest = m.groups()
    deg = ROMAN[num.lower()]
    root = MAJOR[deg] + acc if (acc or natural) else scale[deg]
    upper = num.isupper()
    if "o" in rest or "dim" in rest:
        tones = [0, 3, 6]
    elif "+" in rest:
        tones = [0, 4, 8]
    elif "sus4" in rest:
        tones = [0, 5, 7]
    elif "sus2" in rest:
        tones = [0, 2, 7]
    else:
        tones = [0, 4, 7] if upper else [0, 3, 7]
    if "maj7" in rest:
        tones.append(11)
    elif "7" in rest:
        tones.append(9 if ("o" in rest) else 10)
    if "add9" in rest:
        tones.append(14)
    return root % 12, tones


DRUM_FN = {
    "kick": lambda v: S.kick(v), "kick2": lambda v: S.kick(v, tone=0.8, decay=0.5), "snare": lambda v: S.snare(v),
    "snare2": lambda v: S.snare(v, tone=0.85, snappy=1.6), "clap": lambda v: S.clap(v), "hat": lambda v: S.hat(v),
    "open": lambda v: S.hat(v, True), "shaker": lambda v: S.shaker(v), "tamb": lambda v: S.tamb(v),
    "tom_hi": lambda v: S.tom(180, v), "tom_mid": lambda v: S.tom(130, v), "tom_lo": lambda v: S.tom(92, v, 0.4),
    "taiko": lambda v: S.taiko(v), "taiko_hi": lambda v: S.taiko(v, 96), "crash": lambda v: S.crash(v),
    "ride": lambda v: S.ride(v), "wood": lambda v: S.woodblock(v), "wood_lo": lambda v: S.woodblock(v, 620),
    "conga": lambda v: S.conga(210, v), "conga_lo": lambda v: S.conga(150, v), "bongo": lambda v: S.conga(320, v),
    "frame": lambda v: S.frame_drum(v), "anvil": lambda v: S.anvil(v), "sleigh": lambda v: S.sleigh(v),
    "timp": lambda v: S.timpani(65, v), "timp_hi": lambda v: S.timpani(98, v),
}
# уровень, панорама, доля в ревербе
DRUM_MIX = {
    "kick": (1.0, 0.0, 0.05), "kick2": (1.0, 0.0, 0.08), "snare": (0.65, 0.05, 0.18), "snare2": (0.6, 0.05, 0.2),
    "clap": (0.55, 0.0, 0.2), "hat": (0.42, 0.3, 0.05), "open": (0.35, 0.3, 0.08), "shaker": (0.5, -0.35, 0.08),
    "tamb": (0.45, 0.35, 0.12), "tom_hi": (0.6, 0.35, 0.18), "tom_mid": (0.6, 0.0, 0.18), "tom_lo": (0.65, -0.35, 0.18),
    "taiko": (0.85, -0.15, 0.3), "taiko_hi": (0.65, 0.25, 0.3), "crash": (0.4, -0.3, 0.2), "ride": (0.3, 0.35, 0.1),
    "wood": (0.45, 0.4, 0.15), "wood_lo": (0.45, -0.4, 0.15), "conga": (0.55, 0.3, 0.1), "conga_lo": (0.6, -0.25, 0.1),
    "bongo": (0.5, 0.45, 0.1), "frame": (0.6, -0.2, 0.15), "anvil": (0.35, 0.4, 0.25), "sleigh": (0.5, 0.4, 0.15),
    "timp": (0.7, -0.2, 0.3), "timp_hi": (0.6, 0.2, 0.3),
}

# Рисунки ударных: 16 шагов на такт 4/4 (12 — на 3/4). x — акцент, o — обычный, g — призрачный
KITS = {
    "rock": {"kick": "x.....o.x.o.....", "snare": "....x.......x...", "hat": "o.o.o.o.o.o.o.o."},
    "drive": {"kick": "x...x...x...x...", "snare": "....x.......x...", "hat": "..o...o...o...o.", "open": "......o.......o."},
    "gallop": {"kick": "x..ox..ox..ox..o", "snare": "....x.......x...", "hat": "o.o.o.o.o.o.o.o."},
    "march": {"kick": "x.......x.......", "snare2": "..g.x.gg..g.x.go", "hat": "o...o...o...o..."},
    "folk": {"frame": "x.....o.x.....o.", "tamb": "....o.......o...", "shaker": "o.o.o.o.o.o.o.o."},
    "tribal": {"tom_lo": "x..o..x...o.x...", "conga": "..o.o...o.o..o.o", "bongo": "o.....o.....o...", "shaker": "o.o.o.o.o.o.o.o."},
    "taiko": {"taiko": "x.....o.x...o...", "taiko_hi": "....o.......o.oo", "wood": "o...o...o...o..."},
    "half": {"kick": "x.........x.....", "snare": "........x.......", "hat": "o.o.o.o.o.o.o.o."},
    "dance": {"kick": "x...x...x...x...", "clap": "....x.......x...", "hat": "..o...o...o...o.", "shaker": "o.o.o.o.o.o.o.o."},
    "epic": {"kick2": "x.....x...x.....", "snare": "....x.......x...", "taiko": "x.......x.......", "hat": "o.o.o.o.o.o.o.o."},
    "skip": {"kick": "x.......o.......", "snare2": "....o.g.....o.g.", "wood": "o.o.o.o.o.o.o.o."},
    "swamp": {"kick": "x.....o...x.....", "snare2": "....o.......o..g", "wood_lo": "o..o..o.o..o..o.", "shaker": "..o...o...o...o."},
    # лёгкая перкуссия для слоя base
    "l_shaker": {"shaker": "o.o.o.o.o.o.o.o.", "kick": "x.......x......."},
    "l_folk": {"frame": "x.......o.......", "shaker": "o.o.o.o.o.o.o.o."},
    "l_tamb": {"tamb": "....o.......o...", "kick": "x.......x.......", "shaker": "o.o.o.o.o.o.o.o."},
    "l_wood": {"wood": "o.o.o.o.o.o.o.o.", "kick": "x.......x......."},
    "l_conga": {"conga": "..o...o...o...o.", "conga_lo": "o.......o.......", "shaker": "o.o.o.o.o.o.o.o."},
    "l_hat": {"hat": "o.o.o.o.o.o.o.o.", "kick": "x.......x......."},
    "l_soft": {"kick": "x.......x.......", "hat": "..o...o...o...o."},
    "l_sleigh": {"sleigh": "o.......o.......", "shaker": "..o...o...o...o.", "kick": "x..............."},
    "l_timp": {"timp": "x...............", "shaker": "o.o.o.o.o.o.o.o."},
    "l_drip": {"wood_lo": "o.......o.......", "shaker": "..o...o...o...o."},
    "l_anvil": {"anvil": "x.......o.......", "shaker": "o.o.o.o.o.o.o.o.", "kick": "x.......x......."},
    # 3/4
    "waltz": {"kick": "x...........", "snare2": "....o...o...", "hat": "o.o.o.o.o.o."},
    "waltz_taiko": {"taiko": "x.......o...", "taiko_hi": "....o...o.oo", "kick": "x..........."},
    "l_waltz": {"kick": "x...........", "shaker": "o.o.o.o.o.o."},
}


class Mix:
    def __init__(self, L):
        self.L = L
        self.dry = np.zeros((2, L))
        self.rev = np.zeros((2, L))
        self.dly = np.zeros((2, L))

    def add(self, x, start, pan=0.0, rev=0.2, dly=0.0, gain=1.0):
        st = S.pan2(np.asarray(x) * gain, pan)
        for buf, g in ((self.dry, 1.0), (self.rev, rev), (self.dly, dly)):
            if g > 0:
                _place(buf, st * g, start)


def _place(buf, x, start):
    L = buf.shape[1]
    n = x.shape[1]
    s = start % L
    i = 0
    while i < n:
        k = min(n - i, L - s)
        buf[:, s:s + k] += x[:, i:i + k]
        i += k
        s = 0


class Song:
    def __init__(self, spec):
        self.spec = spec
        self.bpm = spec["bpm"]
        self.beats = spec.get("beats", 4)
        self.spb = 60.0 / self.bpm
        self.key = spec["key"]
        self.scale = SCALES[spec["scale"]]
        self.swing = spec.get("swing", 0.0)
        self.rng = np.random.default_rng(spec.get("seed", 1))
        S.seed(spec.get("seed", 1) * 7 + 3)
        # секции: A, B, A' (по 8 тактов) — либо своя форма
        form = spec.get("form", ["A", "B", "A2"])
        self.bars = []           # аккорды по тактам: список [(доля начала в такте, длительность, корень, ступени)]
        self.section_of = []
        self.section_starts = []
        for sec in form:
            prog = spec["A"] if sec in ("A", "A2") else spec[sec]
            if sec == "A2" and "A2" in spec:
                prog = spec["A2"]
            self.section_starts.append(len(self.bars))
            for sym in prog:
                parts = sym.split("|")
                d = self.beats / len(parts)
                self.bars.append([(k * d, d) + parse_chord(p, self.scale) for k, p in enumerate(parts)])
                self.section_of.append(sec)
        self.nbars = len(self.bars)
        self.total_beats = self.nbars * self.beats
        self.L = int(round(self.total_beats * self.spb * S.SR))
        self.stems = {k: Mix(self.L) for k in ("base", "battle", "boss")}
        self.tag = "?"
        self.energy = {}

    def _trace(self, stem, x, gain):
        k = (stem, self.tag)
        self.energy[k] = self.energy.get(k, 0.0) + float(np.sum((np.asarray(x) * gain) ** 2))

    # ---- время
    def samp(self, beat):
        b = beat
        if self.swing and abs((beat * 2) % 2 - 1) < 1e-6:     # нечётные восьмые чуть позже
            b += self.swing * 0.5
        return int(round(b * self.spb * S.SR))

    def chord_at(self, beat):
        bar = int(beat // self.beats) % self.nbars
        pos = beat - (beat // self.beats) * self.beats
        for (st, d, root, tones) in self.bars[bar]:
            if st <= pos + 1e-6 < st + d + 1e-6:
                return root, tones
        return self.bars[bar][-1][2:]

    # ---- ноты
    def note(self, stem, inst, midi, beat, dur, vel=0.8, pan=0.0, rev=0.25, dly=0.0, gain=1.0, **kw):
        x = inst(S.midi_hz(midi), max(0.03, dur * self.spb), vel, **kw)
        self._trace(stem, x, gain)
        self.stems[stem].add(x, self.samp(beat), pan, rev, dly, gain)

    def hit(self, stem, name, beat, vel=1.0, gain=1.0, pan=None, rev=None):
        lvl, pn, rv = DRUM_MIX[name]
        x = DRUM_FN[name](vel)
        self._trace(stem, x, gain * lvl)
        self.stems[stem].add(x, self.samp(beat), pn if pan is None else pan, rv if rev is None else rv, 0.0, gain * lvl)

    def sound(self, stem, x, beat, pan=0.0, rev=0.2, gain=1.0):
        self._trace(stem, x, gain)
        self.stems[stem].add(x, self.samp(beat), pan, rev, 0.0, gain)

    # ---- высоты
    def pitch_sets(self, root, tones, lo, hi):
        pcs = set((self.key + s) % 12 for s in self.scale)
        chord = set((self.key + root + t) % 12 for t in tones)
        for c in chord:
            if c not in pcs:
                pcs.discard((c + 1) % 12)
                pcs.discard((c - 1) % 12)
                pcs.add(c)
        allowed = [m for m in range(lo, hi + 1) if m % 12 in pcs]
        ct = [m for m in range(lo, hi + 1) if m % 12 in chord]
        return allowed, ct

    def chord_midis(self, root, tones, lo, hi):
        return [m for m in range(lo, hi + 1) if (m - self.key - root) % 12 in [t % 12 for t in tones]]


# ---------------------------------------------------------------- мелодия
R4 = {
    "lyric": [[2, 1, 1], [1, 1, 2], [1.5, 0.5, 2], [3, 1], [1, 1, 1, 1], [2, 2], [1.5, 0.5, 1, 1], [-1, 1, 1, 1]],
    "lively": [[1, 0.5, 0.5, 1, 1], [0.5, 0.5, 1, 0.5, 0.5, 1], [1, 1, 0.5, 0.5, 1], [0.75, 0.75, 0.5, 1, 1],
               [1.5, 0.5, 1, 1], [0.5, 0.5, 0.5, 0.5, 1, 1], [-0.5, 0.5, 1, 1, 1]],
    "march": [[1, 0.5, 0.5, 1, 1], [1.5, 0.5, 1, 1], [1, 1, 1, 1], [0.5, 0.5, 1, 2], [0.75, 0.25, 0.75, 0.25, 2],
              [0.75, 0.25, 1, 1, 1]],
    "run": [[0.5] * 8, [0.5, 0.5, 0.5, 0.5, 1, 1], [0.25, 0.25, 0.5, 0.5, 0.5, 1, 1], [1, 0.5, 0.5, 0.5, 0.5, 1]],
    "sparse": [[2, 2], [3, 1], [-1, 1, 2], [1, 3], [2, 1, 1]],
}
CAD4 = [[2, 2], [3, 1], [4], [1, 1, 2], [1.5, 0.5, 2], [1, 3]]
R3 = {
    "lyric": [[2, 1], [1, 1, 1], [1.5, 0.5, 1], [-1, 1, 1]],
    "lively": [[1, 0.5, 0.5, 1], [0.5, 0.5, 1, 1], [1, 1, 1], [1, 0.5, 0.5, 0.5, 0.5]],
    "sparse": [[2, 1], [3], [-1, 2]],
}
CAD3 = [[3], [2, 1], [1, 2]]


def _bank(song, style):
    if song.beats == 3:
        return R3.get(style, R3["lyric"]), CAD3
    return R4.get(style, R4["lyric"]), CAD4


def _cells_to_notes(cells, start_beat):
    """[[ритм такта], ...] -> [(доля, длительность, это_пауза)]"""
    out = []
    b = start_beat
    for cell in cells:
        for d in cell:
            out.append((b, abs(d), d < 0))
            b += abs(d)
    return out


def _step(allowed, m, k):
    if not allowed:
        return m
    i = int(np.argmin([abs(a - m) for a in allowed]))
    i = max(0, min(len(allowed) - 1, i + k))
    return allowed[i]


def _nearest(ct, m):
    return min(ct, key=lambda c: (abs(c - m), c)) if ct else m


def melody(song, bar0, nbars, style, lo, hi, cadence="tonic", motif=None, seed=0):
    """Мелодия на nbars тактов (обычно 8): мотив — его секвенция — развитие — каденция.
    Возвращает [(доля, длительность, midi, сила)] и мотив (для повторов)."""
    rng = np.random.default_rng(seed)
    bank, cads = _bank(song, style)
    B = song.beats
    units = nbars // 2
    if motif is None:
        r1 = bank[rng.integers(len(bank))]
        r2 = bank[rng.integers(len(bank))]
        steps = []
        n = sum(1 for d in r1 + r2 if d > 0)
        for i in range(n):
            up = rng.uniform() < (0.68 if i < n * 0.55 else 0.32)
            sz = rng.choice([1, 1, 1, 2, 2, 3, 0], p=None)
            steps.append(int(sz if up else -sz))
        motif = {"r": [r1, r2], "steps": steps, "start": rng.integers(0, 3)}
    notes = []
    center = (lo + hi) // 2
    prev = None
    for u in range(units):
        b0 = (bar0 + u * 2) * B
        last = u == units - 1
        if last:
            cells = [bank[rng.integers(len(bank))], cads[rng.integers(len(cads))]]
        elif u == 2 and units >= 4:
            cells = [motif["r"][0], bank[rng.integers(len(bank))]]     # развитие: новый второй такт
        else:
            cells = motif["r"]
        seq = _cells_to_notes(cells, b0)
        root, tones = song.chord_at(b0)
        allowed, ct = song.pitch_sets(root, tones, lo, hi)
        # опорная нота мотива — звук аккорда (третья группа — повыше, кульминация)
        tgt = center + (4 if u == 2 else 0) if prev is None else prev + (3 if u == 2 else 0)
        cur = _nearest(ct, tgt)
        cur = _step(allowed, cur, int(motif["start"]) - 1) if u == 0 else cur
        k = 0
        for i, (b, d, rest) in enumerate(seq):
            if rest:
                continue
            root, tones = song.chord_at(b)
            allowed, ct = song.pitch_sets(root, tones, lo, hi)
            if k > 0:
                st = motif["steps"][(k - 1) % len(motif["steps"])]
                if u == 2 and k > len(seq) // 2:
                    st = -abs(st) if st != 0 else -1            # после кульминации — вниз
                # мелодия не убегает к краям: далеко от середины — шаг обратно
                if st != 0 and (cur - center) * st > 0 and abs(cur - center) > 5:
                    st = -st
                cur = _step(allowed, cur, st)
            if cur >= hi - 1:
                cur = _step(allowed, cur, -2)
            if cur <= lo + 1:
                cur = _step(allowed, cur, 2)
            pos = b - (b // B) * B
            strong = abs(pos) < 1e-6 or (B == 4 and abs(pos - 2) < 1e-6) or d >= 1.5
            if strong:
                cur = _nearest(ct, cur)
            is_last = last and i == len(seq) - 1
            if is_last:
                # последняя нота — устой аккорда: тоника, если она в аккорде, иначе основной тон или квинта
                want = 0 if cadence == "tonic" else 7
                cands = [m for m in ct if (m - song.key) % 12 == want] or \
                        [m for m in ct if (m - song.key - root) % 12 in (0, 7)] or ct
                cur = _nearest(cands, cur)
            vel = (0.95 if abs(pos) < 1e-6 else 0.8) * rng.uniform(0.92, 1.05)
            notes.append((b, d, int(cur), float(vel)))
            k += 1
        prev = cur
    return notes, motif


def counter(song, bar0, nbars, lo, hi, mel, seed=0, rhythm=None):
    """Вторая мелодия длинными нотами: звуки аккорда, не в унисон с главной."""
    rng = np.random.default_rng(seed + 99)
    out = []
    B = song.beats
    prev = (lo + hi) // 2
    rhythm = rhythm or ([B] if B == 3 else [2, 2])
    for bar in range(bar0, bar0 + nbars):
        b = bar * B
        for d in rhythm:
            root, tones = song.chord_at(b)
            ct = song.chord_midis(root, tones, lo, hi)
            near = [m for (mb, md, m, v) in mel if mb <= b < mb + md]
            cands = [c for c in ct if all(abs(c - n) % 12 != 0 for n in near)] or ct
            cur = min(cands, key=lambda c: abs(c - prev) + rng.uniform(0, 0.6))
            out.append((b, d, cur, 0.8))
            prev = cur
            b += d
    return out


# ---------------------------------------------------------------- партии
def voicing(song, root, tones, lo, hi, prev=None, n=4):
    pcs = [(song.key + root + t) % 12 for t in tones]
    if len(pcs) < n:
        pcs = pcs + [pcs[0]]
    pcs = pcs[:n]
    center = np.mean(prev) if prev else (lo + hi) / 2
    out = []
    for pc in pcs:
        cands = [m for m in range(lo, hi + 1) if m % 12 == pc]
        if not cands:
            continue
        out.append(min(cands, key=lambda m: abs(m - center)))
    out = sorted(set(out))
    return out


def part_pad(song, stem, inst, lo=55, hi=72, vel=0.7, gain=1.0, rev=0.4, pan=0.0, every=None):
    prev = None
    for bi, bar in enumerate(song.bars):
        for (st, d, root, tones) in bar:
            v = voicing(song, root, tones, lo, hi, prev)
            prev = v
            b = bi * song.beats + st
            for m in v:
                song.note(stem, inst, m, b, d, vel, pan, rev, gain=gain / max(1, len(v)) * 2.2)


def part_bass(song, stem, inst, pattern="root2", lo=31, hi=50, vel=0.85, gain=1.0, rev=0.03):
    B = song.beats
    for bi, bar in enumerate(song.bars):
        nxt = song.bars[(bi + 1) % song.nbars][0]
        for (st, d, root, tones) in bar:
            r = _nearest([m for m in range(lo, hi + 1) if (m - song.key - root) % 12 == 0], (lo + hi) // 2 - 3)
            fifth = r + 7 if r + 7 <= hi + 5 else r - 5
            b = bi * B + st
            seq = []
            if pattern == "root1":
                seq = [(0, d, r)]
            elif pattern == "drone":
                seq = [(0, d, r)]
            elif pattern == "root2":
                seq = [(0, d / 2, r), (d / 2, d / 2, fifth if d >= 2 else r)]
            elif pattern == "oompah":
                seq = [(k, 0.6, r if (k // 2) % 2 == 0 else fifth) for k in np.arange(0, d, 2.0)]
            elif pattern == "pump8":
                seq = [(k, 0.42, r) for k in np.arange(0, d, 0.5)]
            elif pattern == "oct8":
                seq = [(k, 0.42, r + (12 if int(k * 2) % 2 else 0)) for k in np.arange(0, d, 0.5)]
            elif pattern == "gallop":
                for k in np.arange(0, d, 1.0):
                    seq += [(k, 0.45, r), (k + 0.5, 0.22, r), (k + 0.75, 0.22, r)]
            elif pattern == "synco":
                seq = [(0, 1.4, r), (1.5, 1.4, r), (3.0, 0.9, fifth)] if d >= 4 else [(0, d, r)]
            elif pattern == "walk":
                nr = _nearest([m for m in range(lo, hi + 1) if (m - song.key - nxt[2]) % 12 == 0], r)
                allowed, _ = song.pitch_sets(root, tones, lo - 2, hi + 7)
                steps = int(d)
                cur = r
                for k in range(steps):
                    seq.append((k, 0.9, cur))
                    cur = _step(allowed, cur, 1 if nr > cur else -1)
            elif pattern == "waltz":
                seq = [(0, 1.0, r), (1, 0.5, fifth), (2, 0.5, fifth)] if d >= 3 else [(0, d, r)]
            elif pattern == "quarter":
                seq = [(k, 0.85, r if k % 2 == 0 else (fifth if k % 4 == 1 else r)) for k in np.arange(0, d, 1.0)]
            for (o, dd, m) in seq:
                acc = 1.0 if o == 0 else 0.85
                song.note(stem, inst, int(m), b + o, dd, vel * acc, 0.0, rev, gain=gain)


def part_arp(song, stem, inst, pattern="up8", lo=60, hi=84, vel=0.6, gain=1.0, rev=0.3, dly=0.0, spread=0.35):
    B = song.beats
    for bi, bar in enumerate(song.bars):
        for (st, d, root, tones) in bar:
            ms = song.chord_midis(root, tones, lo, hi)
            if not ms:
                continue
            base = ms[: min(len(ms), 7)]
            if pattern in ("up8", "up16", "updown8", "updown16"):
                step = 0.25 if "16" in pattern else 0.5
                seqm = base if "updown" not in pattern else base + base[-2:0:-1]
            elif pattern == "broken":
                step = 0.5
                seqm = [base[0], base[min(2, len(base) - 1)], base[min(4, len(base) - 1)], base[min(2, len(base) - 1)]]
            elif pattern == "alberti":
                step = 0.5
                seqm = [base[0], base[min(4, len(base) - 1)], base[min(2, len(base) - 1)], base[min(4, len(base) - 1)]]
            elif pattern == "quarters":
                step = 1.0
                seqm = base[:4]
            elif pattern == "triplet":
                step = 1.0 / 3.0
                seqm = base[:5] + base[3:0:-1]
            else:
                step = 0.5
                seqm = base
            b = bi * B + st
            k = 0
            for o in np.arange(0, d - 1e-6, step):
                m = seqm[k % len(seqm)]
                pan = spread if k % 2 else -spread
                song.note(stem, inst, m, b + o, step * 1.6, vel * (1.0 if k % 4 == 0 else 0.82), pan, rev, dly, gain)
                k += 1


def part_comp(song, stem, inst, pattern="strum4", lo=52, hi=70, vel=0.6, gain=1.0, rev=0.2, pan=0.2):
    B = song.beats
    prev = None
    for bi, bar in enumerate(song.bars):
        for (st, d, root, tones) in bar:
            v = voicing(song, root, tones, lo, hi, prev, n=4)
            prev = v
            b = bi * B + st
            if pattern == "strum4":
                hits = [(k, 0.9, 1.0 if k == 0 else 0.8) for k in np.arange(0, d, 1.0)]
            elif pattern == "offbeat":
                hits = [(k + 0.5, 0.35, 0.85) for k in np.arange(0, d, 1.0)]
            elif pattern == "pah":
                hits = [(k, 0.45, 0.8) for k in np.arange(1, d, 2.0)]
            elif pattern == "waltzpah":
                hits = [(1, 0.6, 0.8), (2, 0.6, 0.75)] if d >= 3 else [(0, d, 0.8)]
            elif pattern == "stab":
                hits = [(0, 0.4, 1.0), (1.5, 0.4, 0.85), (3, 0.4, 0.8)] if d >= 4 else [(0, 0.4, 1.0)]
            elif pattern == "eighths":
                hits = [(k, 0.3, 1.0 if k % 1 == 0 else 0.7) for k in np.arange(0, d, 0.5)]
            else:
                hits = [(0, d, 0.9)]
            for (o, dd, a) in hits:
                for j, m in enumerate(v):
                    song.note(stem, inst, m, b + o + j * 0.012 / song.spb, dd, vel * a, pan, rev, gain=gain / len(v) * 2.0)


def part_melody(song, stem, inst, notes, gain=1.0, pan=0.0, rev=0.25, dly=0.0, octave=0, legato=0.92, vel=1.0, **kw):
    for (b, d, m, v) in notes:
        song.note(stem, inst, m + 12 * octave, b, d * legato, v * vel, pan, rev, dly, gain, **kw)


def part_drums(song, stem, kit, bars=None, gain=1.0, fills=True, crash_every=8, vel=1.0):
    pat = KITS[kit]
    B = song.beats
    steps = B * 4
    bars = range(song.nbars) if bars is None else bars
    for bi in bars:
        sec_end = (bi + 1) in song.section_starts or bi == song.nbars - 1
        for name, s in pat.items():
            for k, ch in enumerate(s[:steps]):
                if ch == ".":
                    continue
                if fills and sec_end and k >= steps // 2 and name not in ("hat", "shaker", "open", "ride", "tamb"):
                    continue
                a = {"x": 1.0, "o": 0.78, "g": 0.35}[ch] * vel
                a *= song.rng.uniform(0.92, 1.04)
                song.hit(stem, name, bi * B + k * 0.25, a, gain)
        if fills and sec_end:
            _fill(song, stem, bi, kit, gain * vel)
        if crash_every and bi % crash_every == 0 and "crash" not in pat:
            song.hit(stem, "crash", bi * B, 0.9 * vel, gain)


def _fill(song, stem, bi, kit, gain):
    B = song.beats
    start = bi * B + B / 2
    if kit in ("taiko", "waltz_taiko", "epic"):
        names = ["taiko_hi", "taiko_hi", "taiko", "taiko"]
    elif kit in ("tribal", "folk"):
        names = ["bongo", "conga", "conga_lo", "tom_lo"]
    elif kit in ("march", "skip"):
        names = ["snare2"] * 4
    else:
        names = ["tom_hi", "tom_mid", "tom_lo", "tom_lo"]
    n = int(B / 2 / 0.25)
    for k in range(n):
        nm = names[min(len(names) - 1, k * len(names) // n)]
        song.hit(stem, nm, start + k * 0.25, 0.65 + 0.35 * k / n, gain)


def ambient(song, stem, kind, gain=1.0):
    L = song.L
    if kind == "wind":
        song.stems[stem].add(S.wind(L) * gain, 0, 0.0, 0.25)
    elif kind == "wind_high":
        song.stems[stem].add(S.wind(L, lo=900, hi=4200) * gain * 0.7, 0, 0.2, 0.3)
    elif kind == "crackle":
        song.stems[stem].add(S.crackle(L) * gain, 0, 0.1, 0.1)
    elif kind == "crowd":
        song.stems[stem].add(S.crowd(L) * gain, 0, 0.0, 0.3)
    else:
        fn = {"birds": S.bird, "crickets": S.cricket, "drips": S.drip, "frogs": S.frog, "thunder": S.thunder}[kind]
        every = {"birds": 2.5, "crickets": 0.9, "drips": 1.7, "frogs": 2.2, "thunder": 9.0}[kind]
        t = 0.3
        while t < song.total_beats * song.spb - 0.2:
            x = fn(song.rng.uniform(0.6, 1.0))
            song.stems[stem].add(x * gain, int(t * S.SR), song.rng.uniform(-0.7, 0.7), 0.35)
            t += every * song.rng.uniform(0.5, 1.5)


# ---------------------------------------------------------------- сведение
def master(song, ir_seconds=2.2, damp=0.5, delay_beats=0.75, fb=0.32, target_rms=0.16, stems=("base", "battle", "boss")):
    ir = S.make_ir(ir_seconds, damp, seed_=song.spec.get("seed", 1))
    outs = {}
    for k in stems:
        mx = song.stems[k]
        y = mx.dry + S.circ_conv(mx.rev, ir) * 0.55
        if np.abs(mx.dly).max() > 0:
            y += S.pingpong(mx.dly, delay_beats * song.spb, fb)
        y = S.hp(y, 28)                      # убираем инфрабас
        outs[k] = y
    full = sum(outs.values())
    rms = np.sqrt(np.mean(full ** 2)) + 1e-9
    pk = np.abs(full).max() + 1e-9
    g = min(target_rms / rms, 0.92 / pk * 1.25)
    for k in outs:
        y = outs[k] * g
        y = np.where(np.abs(y) > 0.9, np.sign(y) * (0.9 + 0.1 * np.tanh((np.abs(y) - 0.9) / 0.1)), y)
        outs[k] = y
    return outs
