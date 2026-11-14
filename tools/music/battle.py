"""Боевая музыка Арены: волны, мини-боссы, боссы — и музыка Лавки.

В отличие от «прогулочных» тем локаций (tracks.py), здесь один плотный стерео-трек:
быстрый темп, ударные со вступлениями и сбивками, бас восьмыми или галопом,
струнное остинато шестнадцатыми, аккорды меди, главная тема с удвоением, хор.
Форма: A (тема) — A2 (кульминация) — B (напряжение: половинный темп, низкая медь,
удар-«браам», нарастание) — A2 (финал со всеми слоями). Петля без шва.

Сведение (master_battle): реверберация, мягкая компрессия шины (считается по
трём копиям петли — на шве нет скачка громкости), лёгкий эквалайзер, расширение
стерео и ограничитель пиков.
"""
import numpy as np
import synth as S
import comp as C
import arrange as A

I = A.INST


def _addpad(a, b):
    n = max(a.shape[1], b.shape[1])
    out = np.zeros((2, n))
    out[:, :a.shape[1]] += a
    out[:, :b.shape[1]] += b
    return out


def ens(name, voices=3, cents=8.0, spread=0.6, skew=0.006):
    """Ансамбль: несколько чуть расстроенных голосов разнесены по стерео (секция, а не солист)."""
    fn = I[name]

    def f(freq, dur, vel=0.8, **kw):
        acc = None
        mid = (voices - 1) / 2.0
        for k in range(voices):
            rel = (k - mid) / max(mid, 1.0)
            x = np.asarray(fn(freq * 2 ** (rel * cents / 1200.0), dur, vel, **kw))
            st = S.pan2(x, rel * spread) if x.ndim == 1 else x
            off = int(abs(k - mid) * skew * S.SR)
            if off:
                st = np.pad(st, ((0, 0), (off, 0)))
            acc = st if acc is None else _addpad(acc, st)
        return acc / np.sqrt(voices)
    return f


def riser(seconds, vel=1.0):
    """Нарастание: шум с поднимающимся фильтром и восходящий тон — к началу следующей части."""
    n = int(seconds * S.SR)
    t = S.secs(n)
    k = t / seconds
    nz = S.noise(n)
    out = np.zeros(n)
    seg = max(1, n // 24)
    for i in range(0, n, seg):
        j = min(n, i + seg)
        fc = 300 + 7000 * (i / n) ** 2
        out[i:j] = S.bp(nz[max(0, i - 2000):j], fc * 0.7, fc * 1.3)[-(j - i):]
    tone = np.sin(2 * np.pi * np.cumsum(110 + 660 * k ** 2) / S.SR) * 0.25
    y = (out * 0.8 + tone) * k ** 2 * vel
    return S.fade_tail(y, 20)


def impact(vel=1.0, f=55.0):
    """Удар в начале части: глубокий «бум» с хвостом."""
    n = int(1.6 * S.SR)
    t = S.secs(n)
    sweep = f * (1.0 + 1.5 * np.exp(-t / 0.05))
    y = np.sin(2 * np.pi * np.cumsum(sweep) / S.SR) * np.exp(-t / 0.55)
    y += S.lp(S.noise(n), 900) * np.exp(-t / 0.12) * 0.5
    return np.tanh(1.6 * y) * vel * 0.9


def bars_of(song, names):
    return [i for i, s in enumerate(song.section_of) if s in names]


def section_bars(song, k):
    st = song.section_starts[k]
    en = song.section_starts[k + 1] if k + 1 < len(song.section_starts) else song.nbars
    return list(range(st, en))


def part_ost(song, bars, inst, lo, hi, step=0.25, pat=(0, 2, 1, 2), vel=0.62, gain=1.0, rev=0.18, pan=0.0, acc_every=4):
    """Остинато по звукам аккорда: шестнадцатые (или восьмые), акцент на долю."""
    B = song.beats
    for bi in bars:
        for (st, d, root, tones) in song.bars[bi]:
            ms = song.chord_midis(root, tones, lo, hi)
            if not ms:
                continue
            k = 0
            for o in np.arange(0, d - 1e-6, step):
                m = ms[min(pat[k % len(pat)], len(ms) - 1)]
                a = 1.0 if k % acc_every == 0 else 0.78
                song.note("base", inst, m, bi * B + st + o, step * 0.9, vel * a, pan, rev, gain=gain)
                k += 1


def part_stabs(song, bars, inst, lo, hi, hits=((0, 0.5, 1.0), (1.5, 0.5, 0.85), (3.0, 0.5, 0.9)), vel=0.8, gain=1.0, rev=0.25):
    B = song.beats
    prev = None
    for bi in bars:
        for (st, d, root, tones) in song.bars[bi]:
            v = C.voicing(song, root, tones, lo, hi, prev, n=4)
            prev = v
            for (o, dd, a) in hits:
                if o >= d:
                    continue
                for m in v:
                    song.note("base", inst, m, bi * B + st + o, dd, vel * a, 0.0, rev, gain=gain / len(v) * 2.0)


def part_pad_bars(song, bars, inst, lo, hi, vel=0.7, gain=1.0, rev=0.45):
    B = song.beats
    prev = None
    for bi in bars:
        for (st, d, root, tones) in song.bars[bi]:
            v = C.voicing(song, root, tones, lo, hi, prev)
            prev = v
            for m in v:
                song.note("base", inst, m, bi * B + st, d, vel, 0.0, rev, gain=gain / max(1, len(v)) * 2.2)


def part_bass_bars(song, bars, inst, pattern, gain=1.0, lo=31, hi=50):
    """Бас только в нужных тактах (обёртка над comp.part_bass)."""
    keep = song.bars
    sub = [keep[i] if i in bars else [] for i in range(song.nbars)]
    song.bars = sub
    try:
        _bass(song, inst, pattern, gain, lo, hi)
    finally:
        song.bars = keep


def _bass(song, inst, pattern, gain, lo, hi):
    B = song.beats
    for bi, bar in enumerate(song.bars):
        for (st, d, root, tones) in bar:
            r = C._nearest([m for m in range(lo, hi + 1) if (m - song.key - root) % 12 == 0], (lo + hi) // 2 - 3)
            fifth = r + 7 if r + 7 <= hi + 5 else r - 5
            b = bi * B + st
            if pattern == "pump8":
                seq = [(k, 0.42, r) for k in np.arange(0, d, 0.5)]
            elif pattern == "oct8":
                seq = [(k, 0.42, r + (12 if int(k * 2) % 2 else 0)) for k in np.arange(0, d, 0.5)]
            elif pattern == "gallop":
                seq = []
                for k in np.arange(0, d, 1.0):
                    seq += [(k, 0.45, r), (k + 0.5, 0.22, r), (k + 0.75, 0.22, r)]
            elif pattern == "drive16":
                seq = [(k, 0.22, r if int(k * 4) % 4 != 3 else fifth) for k in np.arange(0, d, 0.25)]
            elif pattern == "half":
                seq = [(0, d * 0.5, r), (d * 0.5, d * 0.45, r if d < 4 else fifth)]
            elif pattern == "root1":
                seq = [(0, d, r)]
            else:
                seq = [(k, 0.42, r) for k in np.arange(0, d, 0.5)]
            for (o, dd, m) in seq:
                song.note("base", inst, int(m), b + o, dd, 0.85 if o == 0 else 0.72, 0.0, 0.03, gain=gain)


def shift(notes, beats):
    return [(b + beats, d, m, v) for (b, d, m, v) in notes]


def build_battle(spec):
    """Боевой трек: одна плотная стерео-дорожка."""
    spec = dict(spec)
    spec.setdefault("form", ["A", "A2", "B", "A2"])
    song = C.Song(spec)
    B = song.beats
    sd = spec.get("seed", 1)
    lo, hi = spec["lead_range"]
    style = spec.get("style", "march")
    secs = [song.section_of[s] for s in song.section_starts]
    S1, S2, S3, S4 = [section_bars(song, k) for k in range(4)]
    b0 = [b * B for b in (S1[0], S2[0], S3[0], S4[0])]
    melA, motif = C.melody(song, S1[0], len(S1), style, lo, hi, cadence="dominant", seed=sd)
    melA2, _ = C.melody(song, S2[0], len(S2), style, lo + 2, hi + 2, cadence="tonic", motif=motif, seed=sd + 5)
    melB, _ = C.melody(song, S3[0], len(S3), spec.get("style_b", "sparse"), lo - 5, hi - 7, cadence="dominant", seed=sd + 11)
    melA3 = shift(melA2, b0[3] - b0[1])
    full = S1 + S2 + S4
    every = S1 + S2 + S3 + S4
    G = spec.get("mix", {})

    def gg(k, v):
        return v * G.get(k, 1.0)

    # ---------- ударные
    song.tag = "drums"
    kit = spec.get("kit", "rock")
    C.part_drums(song, "base", kit, bars=full, gain=gg("drums", 0.56), crash_every=8)
    C.part_drums(song, "base", spec.get("kit_b", "half"), bars=S3, gain=gg("drums", 0.5), crash_every=0)
    song.tag = "taiko"
    C.part_drums(song, "base", spec.get("kit2", "taiko"), bars=S2 + S4 + S3[4:], gain=gg("taiko", 0.34), fills=False, crash_every=0)
    for b in (b0[1], b0[3]):
        song.hit("base", "crash", b, 1.0, gg("drums", 0.8))
        song.hit("base", "kick2", b, 1.0, gg("drums", 0.8))
    # ---------- бас: основной рисунок + саб
    song.tag = "bass"
    part_bass_bars(song, full, I[spec.get("bass", "bass_dist")], spec.get("bass_pat", "pump8"), gain=gg("bass", 0.9))
    part_bass_bars(song, S3, I[spec.get("bass", "bass_dist")], "half", gain=gg("bass", 0.85))
    song.tag = "sub"
    part_bass_bars(song, every, I["bass_sub"], "root1", gain=gg("sub", 0.55), lo=26, hi=45)
    # ---------- остинато
    song.tag = "ost"
    olo, ohi = spec.get("ost_range", (55, 74))
    ost = ens(spec.get("ost", "stacc"), voices=2, cents=6.0, spread=0.55)
    part_ost(song, full, ost, olo, ohi, step=0.25, pat=spec.get("ost_pat", (0, 2, 1, 2)), gain=gg("ost", 0.5))
    part_ost(song, S3, ost, olo - 5, ohi - 5, step=0.5, pat=(0, 1), gain=gg("ost", 0.42))
    if spec.get("ost2"):
        song.tag = "ost2"
        part_ost(song, S2 + S4, I[spec["ost2"]], olo + 12, ohi + 12, step=0.25, pat=spec.get("ost2_pat", (0, 1, 2, 3)),
                 gain=gg("ost2", 0.32), rev=0.3, pan=0.25)
    # ---------- аккорды: струнный подклад, медь, хор
    song.tag = "pad"
    part_pad_bars(song, every, ens(spec.get("pad", "strings"), voices=2, cents=5.0, spread=0.4), 52, 71, gain=gg("pad", 0.32))
    song.tag = "stabs"
    part_stabs(song, S1 + S4, ens(spec.get("stab", "brass"), voices=3, cents=7.0, spread=0.5), 50, 67,
               hits=spec.get("stab_hits", ((0, 0.45, 1.0), (1.5, 0.45, 0.85), (3.0, 0.45, 0.9))), gain=gg("stabs", 0.42))
    song.tag = "choir"
    part_pad_bars(song, S3 + S4, I[spec.get("choir", "choir")], 55, 72, gain=gg("choir", 0.3), rev=0.55)
    # ---------- тема
    lead = ens(spec.get("lead", "brass"), voices=spec.get("lead_voices", 2), cents=5.0, spread=0.25)
    dbl = ens(spec.get("double", "strings"), voices=2, cents=6.0, spread=0.5)
    song.tag = "lead"
    C.part_melody(song, "base", lead, melA, gg("lead", 1.1), 0.0, rev=0.3, legato=0.9)
    C.part_melody(song, "base", lead, melA2, gg("lead", 1.15), 0.0, rev=0.3, legato=0.9)
    C.part_melody(song, "base", lead, melA3, gg("lead", 1.2), 0.0, rev=0.32, legato=0.9)
    song.tag = "double"
    C.part_melody(song, "base", dbl, melA2, gg("double", 0.45), 0.0, rev=0.35, octave=spec.get("double_oct", 1), legato=0.95)
    C.part_melody(song, "base", dbl, melA3, gg("double", 0.5), 0.0, rev=0.35, octave=spec.get("double_oct", 1), legato=0.95)
    if spec.get("lead_hi"):
        song.tag = "lead_hi"
        C.part_melody(song, "base", I[spec["lead_hi"]], melA3, gg("lead_hi", 0.4), 0.15, rev=0.3, octave=1, legato=0.85)
    song.tag = "counter"
    cm = C.counter(song, S4[0], len(S4), lo - 7, hi - 9, melA3, seed=sd)
    C.part_melody(song, "base", I[spec.get("counter", "horn")], cm, gg("counter", 0.42), -0.25, rev=0.45, legato=0.97)
    # ---------- B: низкая медь, удар, нарастание
    song.tag = "low"
    C.part_melody(song, "base", ens(spec.get("low", "horn"), voices=3, cents=6.0, spread=0.45), melB, gg("low", 0.75), 0.0,
                  rev=0.4, octave=spec.get("low_oct", -1), legato=0.95)
    song.tag = "braam"
    root = song.bars[S3[0]][0][2]
    r = 36 + ((song.key + root - 36) % 12)
    song.sound("base", S.braam(S.midi_hz(r), B * song.spb * 1.6, 0.95), b0[2], 0.0, 0.35, gg("braam", 0.55))
    song.sound("base", impact(0.9, S.midi_hz(r - 12)), b0[2], 0.0, 0.25, gg("impact", 0.55))
    song.sound("base", impact(0.8, S.midi_hz(r - 12)), b0[1], 0.0, 0.25, gg("impact", 0.4))
    song.tag = "riser"
    song.sound("base", riser(B * song.spb * 2.0, 0.9), b0[3] - 2 * B, 0.0, 0.3, gg("riser", 0.35))
    song.sound("base", riser(B * song.spb * 1.0, 0.7), b0[1] - B, 0.0, 0.3, gg("riser", 0.25))
    for k in range(len(S3) // 2):                                   # литавры в напряжении
        song.hit("base", "timp", (S3[0] + k * 2) * B, 0.9, gg("timp", 0.8))
        song.hit("base", "timp_hi", (S3[0] + k * 2) * B + 1.5, 0.7, gg("timp", 0.6))
    # ---------- краски локации
    for amb in spec.get("ambient", []):
        C.ambient(song, "base", amb, spec.get("amb_gain", 0.7))
    if spec.get("alarm"):
        song.tag = "bells"
        for bar in range(0, song.nbars, 2):
            song.sound("base", S.alarm_bell(0.8, S.midi_hz(spec["key"] + 7 - 12)), bar * B, -0.3, 0.4, gg("bells", 0.35))
    if spec.get("anvil"):
        song.tag = "anvil"
        for bi in full:
            song.hit("base", "anvil", bi * B + 1, 0.8, gg("anvil", 0.6))
            song.hit("base", "anvil", bi * B + 3, 0.7, gg("anvil", 0.5))
    return song


def build_shop(spec):
    """Лавка: уютная торговая тема — щипковые, аккордеон, флейта, лёгкие ударные."""
    spec = dict(spec)
    song = C.Song(spec)
    sd = spec.get("seed", 1)
    lo, hi = spec["lead_range"]
    melA, motif = C.melody(song, 0, 8, "lively", lo, hi, cadence="dominant", seed=sd)
    melB, _ = C.melody(song, 8, 8, "lyric", lo, hi, cadence="dominant", seed=sd + 3)
    melA2, _ = C.melody(song, 16, 8, "lively", lo, hi, cadence="tonic", motif=motif, seed=sd + 7)
    song.tag = "pad"
    C.part_pad(song, "base", I["accordion"], 55, 70, 0.6, 0.26, rev=0.3)
    song.tag = "bass"
    C.part_bass(song, "base", I["bass_upright"], "walk", gain=0.9)
    song.tag = "comp"
    C.part_comp(song, "base", I["guitar"], "offbeat", 52, 69, 0.6, 0.42, rev=0.2, pan=-0.25)
    song.tag = "arp"
    C.part_arp(song, "base", I["harp"], "broken", 60, 84, 0.55, 0.32, rev=0.35, dly=0.25)
    song.tag = "lead"
    C.part_melody(song, "base", I["flute"], melA, 0.85, 0.1, rev=0.3)
    C.part_melody(song, "base", I["marimba"], melB, 0.75, -0.1, rev=0.3)
    C.part_melody(song, "base", I["flute"], melA2, 0.85, 0.1, rev=0.3)
    C.part_melody(song, "base", I["pizz"], melA2, 0.35, -0.3, rev=0.25, octave=-1)
    song.tag = "perc"
    C.part_drums(song, "base", "l_tamb", gain=0.55, fills=False, crash_every=0)
    for bar in range(0, song.nbars, 4):                       # колокольчик над дверью лавки
        song.sound("base", S.bell(S.midi_hz(spec["key"] + 24), 1.2, 0.5), bar * song.beats, 0.4, 0.5, 0.25)
    return song


# ---------------------------------------------------------------- сведение
def _comp_gain(y, thr_db, ratio, att=0.01, rel=0.18, win=0.03):
    """Огибающая громкости -> коэффициент усиления компрессора (по сумме каналов)."""
    from scipy import signal as sg
    m = np.mean(y ** 2, axis=0)
    w = max(1, int(win * S.SR))
    env = np.sqrt(np.convolve(m, np.ones(w) / w, mode="same") + 1e-12)
    db = 20 * np.log10(env + 1e-9)
    over = np.maximum(0.0, db - thr_db)
    gr = over * (1.0 - 1.0 / ratio)
    # медленный отпуск: однополюсный фильтр (атака быстрее)
    a_rel = np.exp(-1.0 / (rel * S.SR))
    sm = sg.lfilter([1 - a_rel], [1, -a_rel], gr)
    sm = np.maximum(sm, sg.lfilter([1 - np.exp(-1.0 / (att * S.SR))], [1, -np.exp(-1.0 / (att * S.SR))], gr) * 0.6)
    return 10 ** (-sm / 20.0)


def master_battle(song, ir_seconds=2.4, damp=0.5, target_rms=0.2, width=1.22, comp=(-20.0, 3.0), air=2.0):
    ir = S.make_ir(ir_seconds, damp, seed_=song.spec.get("seed", 1))
    mx = song.stems["base"]
    y = mx.dry + S.circ_conv(mx.rev, ir) * 0.5
    if np.abs(mx.dly).max() > 0:
        y += S.pingpong(mx.dly, 0.75 * song.spb, 0.3)
    y = S.hp(y, 30)
    # тембр: чуть тепла внизу, меньше «картона» в середине, воздух сверху
    y = S.peak(y, 110, 0.7, 1.5)
    y = S.peak(y, 420, 1.0, -1.5)
    y = S.peak(y, 9000, 0.6, air)
    # стерео шире: усиливаем разницу каналов
    mid = (y[0] + y[1]) * 0.5
    side = (y[0] - y[1]) * 0.5 * width
    y = np.stack([mid + side, mid - side])
    # громкость к цели, потом компрессор (считается по трём копиям петли — шов без скачка)
    rms = np.sqrt(np.mean(y ** 2)) + 1e-9
    y = y * (target_rms / rms)
    L = y.shape[1]
    tri = np.concatenate([y, y, y], axis=1)
    gain = _comp_gain(tri, comp[0], comp[1])[L:2 * L]
    y = y * gain
    rms = np.sqrt(np.mean(y ** 2)) + 1e-9
    y = y * (target_rms / rms)
    # мягкий ограничитель пиков
    lim, top = 0.82, 0.95
    a = np.abs(y)
    y = np.where(a > lim, np.sign(y) * (lim + (top - lim) * np.tanh((a - lim) / (top - lim))), y)
    return {"base": y}
