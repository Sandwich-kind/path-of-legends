"""Музыка приёмов DJ Климы: python3 tools/music/dj.py -> audio/music/dj_slam.ogg, dj_rave.ogg

Обе вещи свои (написаны здесь, без чужих сэмплов и мелодий), темп 150 уд/мин — один удар
бита 0,4 с, ровно как такт приёмов в игре (characters/dj_kit.gd, BEAT):
  dj_slam — «Лютый слэм»: тяжёлый рифф на дисторшн-басу, бочка в каждую долю, хлопки на 2 и 4,
            рваные аккорды-«квинты»; первый удар — сразу (слэм бьёт волной с первого бита).
  dj_rave — «Рейв-пати»: 4 доли разгона (дробь малого, нарастающий шум, восходящая пила), пауза-
            вдох и ДРОП на 1,6 с: бочка «четыре в пол», качающий суб-бас, суперсо-аккорды с
            «пампингом», яркий хук. Дальше 20 долей вечеринки (игра обрывает с затуханием).
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import synth as S  # noqa: E402
from render import encode, OUT  # noqa: E402

SR = S.SR
BEAT = 60.0 / 150.0
SIX = BEAT / 4.0


class Mix:
    """Несколько шин (моно) -> стерео; у шины своя панорама, громкость и «пампинг» от бочки."""

    def __init__(self, seconds):
        self.n = int(seconds * SR)
        self.bus = {}

    def add(self, bus, x, t, gain=1.0):
        b = self.bus.setdefault(bus, np.zeros(self.n))
        i = int(round(t * SR))
        if i >= self.n:
            return
        k = min(len(x), self.n - i)
        b[i:i + k] += np.asarray(x[:k]) * gain

    def get(self, bus):
        return self.bus.setdefault(bus, np.zeros(self.n))


def supersaw(f, dur, vel=0.8, cut=3800.0, voices=7, spread=0.018):
    n = int(dur * SR)
    y = np.zeros(n)
    for k in range(voices):
        d = (k - (voices - 1) / 2) / ((voices - 1) / 2) * spread
        y += S.saw(np.full(n, f * (1 + d)))
    y /= voices
    e = S.adsr(n, 0.005, 0.25, 0.7, 0.08)[:n]
    y = S.lp(y[:len(e)], cut)
    return y * e * vel


def power(f, dur, vel=0.8):
    """«Квинта» на перегрузе: тоника + квинта + октава, пила, жёсткий клип."""
    n = int(dur * SR)
    y = S.saw(np.full(n, f)) + S.saw(np.full(n, f * 1.4983)) + 0.6 * S.saw(np.full(n, f * 2.0))
    y = np.tanh(4.0 * y) * 0.5
    y = S.lp(y, 3200)
    e = S.adsr(n, 0.003, 0.12, 0.6, 0.05)[:n]
    return y[:len(e)] * e * vel


def riser(sec):
    n = int(sec * SR)
    t = np.arange(n) / SR
    x = t / sec
    nz = S.noise(n)
    # шум, который «поднимается»: полоса едет вверх, громкость растёт
    out = np.zeros(n)
    seg = int(0.05 * SR)
    for i in range(0, n, seg):
        j = min(n, i + seg)
        fc = 400 + 7000 * (i / n) ** 2
        out[i:j] = S.bp(nz[max(0, i - 2000):j], fc * 0.7, min(16000, fc * 1.6))[-(j - i):]
    pitch = S.midi_hz(41) * 2 ** (3.0 * x ** 1.6)          # пила от фа большой октавы на три октавы вверх
    saw = S.lp(S.saw(pitch), 5000) * 0.35
    return (out * 0.6 + saw) * (0.15 + 0.85 * x ** 1.5)


def crash(vel=1.0):
    return S.crash(vel, 1.4)


def pump_env(n, kicks, depth=0.75, rel=0.22):
    """Огибающая «пампинга»: музыка приседает на каждой бочке и плавно поднимается."""
    e = np.ones(n)
    for t in kicks:
        i = int(t * SR)
        k = min(n - i, int(rel * SR))
        if k <= 0:
            continue
        x = np.arange(k) / (rel * SR)
        e[i:i + k] = np.minimum(e[i:i + k], 1.0 - depth * (1.0 - x) ** 2)
    return e


def finish(m, pans, gains, peak=0.88):
    L = np.zeros(m.n)
    R = np.zeros(m.n)
    for name, x in m.bus.items():
        p = pans.get(name, 0.0)
        g = gains.get(name, 1.0)
        L += x * g * np.sqrt(0.5 * (1 - p))
        R += x * g * np.sqrt(0.5 * (1 + p))
    y = np.vstack([L, R])
    ir = S.make_ir(1.1, 0.55)
    wet = S.lin_conv(y * 0.18, ir)[:, : m.n]
    y = y + wet * 0.35
    y = S.hp(y, 28)
    y = np.tanh(1.6 * y / (np.abs(y).max() + 1e-9)) / np.tanh(1.6)
    y *= peak / (np.abs(y).max() + 1e-9)
    tail = int(0.35 * SR)
    y[:, -tail:] *= np.linspace(1, 0, tail)
    return y


# ---------------------------------------------------------------- Лютый слэм
def slam():
    S.seed(150)
    off = 0.05                     # в игре первый удар слэма — через 0,05 с после нажатия
    beats = 18
    m = Mix(off + beats * BEAT + 0.9)
    F1, Ab1, Db1, Eb1, C1 = 29, 32, 25, 27, 24
    bars = [[F1] * 4, [F1, F1, Ab1, Ab1], [Db1, Db1, Db1, Eb1], [Eb1, Eb1, C1, C1]]
    riff = [1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1]
    kicks = []
    m.add("fx", crash(1.0), off, 0.9)
    m.add("fx", S.braam(S.midi_hz(29), 0.9, 1.0), off, 0.5)
    for b in range(beats):
        t = off + b * BEAT
        bar, beat = divmod(b, 4)
        m.add("drums", S.kick(1.0, 1.05, 0.28), t, 1.0)
        kicks.append(t)
        if beat in (1, 3):
            m.add("drums", S.snare(1.0, 1.1, 1.2), t, 0.85)
            m.add("drums", S.clap(1.0), t, 0.6)
        m.add("hats", S.hat(0.8, open_=True), t + BEAT / 2, 0.55)
        for s in range(4):
            m.add("hats", S.hat(0.5 + 0.3 * (s % 2)), t + s * SIX, 0.35)
        if bar % 2 == 1 and beat == 3:
            m.add("drums", S.kick(0.8, 1.0, 0.2), t + 3 * SIX, 0.8)          # подбивка в конце фразы
        root = bars[bar % 4][beat]
        for s in range(4):
            if riff[beat * 4 + s]:
                m.add("bass", S.bass_dist(S.midi_hz(root + (12 if s == 3 and beat == 3 else 0)), SIX * 0.9, 0.95), t + s * SIX)
        if beat == 0 or (beat == 1 and bar % 2 == 0):
            m.add("gtr", power(S.midi_hz(root + 24), BEAT * (0.9 if beat == 0 else 0.45), 0.9), t + (0 if beat == 0 else SIX * 2))
        # хук сверху: короткие рваные ноты, своя фраза в фа миноре
        hook = [65, 0, 68, 70, 0, 72, 70, 68] if bar % 2 == 0 else [65, 0, 63, 65, 0, 60, 63, 0]
        for s in range(2):
            n_ = hook[(beat * 2 + s) % 8]
            if n_ and b >= 4:
                m.add("lead", S.saw_lead(S.midi_hz(n_), SIX * 1.6, 0.6, 7.0, 0.0), t + s * 2 * SIX, 0.55)
    pe = pump_env(m.n, kicks, 0.45, 0.18)
    for name in ("bass", "gtr", "lead"):
        m.bus[name] *= pe
    return finish(m, {"hats": 0.25, "gtr": -0.3, "lead": 0.3}, {"drums": 1.0, "bass": 0.9, "gtr": 0.55, "lead": 0.45, "hats": 0.6, "fx": 0.6}, 0.8)


# ---------------------------------------------------------------- Рейв-пати
def rave():
    S.seed(151)
    build = 4 * BEAT                 # 1,6 с разгона, ДРОП ровно на 1,6 с — как в игре
    party = 20
    m = Mix(build + party * BEAT + 1.2)
    # --- разгон
    m.add("build", riser(build - 0.08), 0.0, 1.0)
    roll = []
    for b in range(4):
        step = [BEAT / 2, BEAT / 2, BEAT / 4, BEAT / 8][b]
        k = 0
        while k * step < BEAT - 1e-6:
            roll.append(b * BEAT + k * step)
            k += 1
    for i, t in enumerate(roll):
        if t < build - 0.06:
            v = 0.35 + 0.65 * (t / build) ** 1.4
            m.add("build", S.snare(v, 1.0 + 0.5 * t / build, 0.7), t, 0.8)
    chords = [[53, 56, 60], [49, 53, 56], [56, 60, 63], [51, 55, 58]]       # Fm  Db  Ab  Eb
    for b in range(4):
        cut = 500 + 2600 * (b / 3) ** 1.5
        for f in chords[0]:
            m.add("build", supersaw(S.midi_hz(f), BEAT * 0.95, 0.5, cut, 5, 0.012), b * BEAT, 0.45)
    # --- ДРОП
    kicks = []
    m.add("fx", crash(1.0), build, 1.0)
    m.add("fx", S.kick(1.0, 0.8, 0.9), build, 1.0)
    for b in range(party):
        t = build + b * BEAT
        bar, beat = divmod(b, 4)
        m.add("drums", S.kick(1.0, 1.0, 0.32), t, 1.0)
        kicks.append(t)
        if beat in (1, 3):
            m.add("drums", S.clap(1.0), t, 0.75)
            m.add("drums", S.snare(0.5, 1.2, 0.8), t, 0.3)
        m.add("hats", S.hat(0.9, open_=True), t + BEAT / 2, 0.6)
        for s in (1, 3):
            m.add("hats", S.hat(0.6), t + s * SIX, 0.4)
        ch = chords[bar % 4]
        root = ch[0] - 24
        for s in (1, 2, 3):                                              # качающий бас на «и»
            m.add("bass", S.bass_saw(S.midi_hz(root), SIX * 0.85, 0.9), t + s * SIX)
        m.add("sub", S.bass_sub(S.midi_hz(root), BEAT * 0.95, 0.9), t)
        if beat == 0 or beat == 2:
            for f in ch:
                m.add("chords", supersaw(S.midi_hz(f + 12), BEAT * 1.9, 0.55, 4200, 7, 0.02), t, 0.5)
        # хук: яркие ноты «пилой» с коротким звоном, своя фраза
        hook = [[72, 0, 72, 75, 0, 77, 75, 72], [70, 0, 68, 70, 0, 72, 0, 68],
                [72, 0, 72, 75, 0, 79, 77, 75], [77, 0, 75, 72, 0, 70, 72, 0]][bar % 4]
        for s in range(2):
            n_ = hook[(beat * 2 + s) % 8]
            if n_:
                m.add("lead", supersaw(S.midi_hz(n_), SIX * 1.7, 0.6, 6500, 5, 0.008), t + s * 2 * SIX, 0.6)
                m.add("lead", S.bell(S.midi_hz(n_ + 12), SIX * 2, 0.35), t + s * 2 * SIX, 0.25)
        if beat == 0 and bar > 0:
            m.add("fx", crash(0.6), t, 0.35)
    pe = pump_env(m.n, kicks, 0.7, 0.24)
    for name in ("chords", "bass", "lead"):
        m.bus[name] *= pe
    return finish(m, {"hats": 0.2, "chords": 0.0, "lead": 0.15},
                  {"drums": 1.0, "sub": 0.9, "bass": 0.55, "chords": 0.55, "lead": 0.5, "hats": 0.6, "build": 2.2, "fx": 0.6}, 0.8)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("dj_slam", slam), ("dj_rave", rave)):
        y = fn()
        assert np.isfinite(y).all(), name
        encode(y, os.path.join(OUT, name + ".ogg"), 5.0)
        print(name, "%.2f s" % (y.shape[1] / SR), "peak %.2f rms %.3f" % (np.abs(y).max(), np.sqrt(np.mean(y ** 2))))
