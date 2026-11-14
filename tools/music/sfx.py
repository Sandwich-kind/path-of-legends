"""Звуки игры: python3 tools/music/sfx.py -> audio/sfx/*.wav (моно, 16 бит).

У частых звуков по 2–3 варианта (_1, _2, _3), игра выбирает случайный.
Появление боссов (intro_*, у каждого свой голос): python3 tools/music/sfx.py --intros
— пересобирает только их (44,1 кГц), остальные звуки не трогает.
Звуки DJ Климы (скретч, фонящий микрофон, дроп, пластинки, дубинки): python3 tools/music/sfx.py --dj
Звуки Почти легенды (удары, рельсотрон, метеорит, Титан): python3 tools/music/sfx.py --almost
"""
import os
import sys

import numpy as np
from scipy.io import wavfile
from scipy import signal

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import synth as S  # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, "..", "..", "audio", "sfx"))
SR = S.SR
R = np.random.default_rng(42)


def t_(sec):
    return np.arange(int(sec * SR)) / SR


def nz(n):
    return R.uniform(-1, 1, n)


def env(n, a, d):
    t = np.arange(n) / SR
    e = np.exp(-t / d)
    na = max(1, int(a * SR))
    e[:na] *= np.linspace(0, 1, na)
    return e


def sweep(f0, f1, sec, curve=3.0, n=None):
    """Частота от f0 к f1 за sec секунд; если задан n — массив длиной n (дальше держится f1)."""
    t = t_(sec) if n is None else np.arange(n) / SR
    x = np.clip(t / sec, 0.0, 1.0)
    k = x ** (1.0 / curve) if f1 < f0 else x ** curve
    return f0 + (f1 - f0) * k


def tone(f, kind="sine"):
    ph = np.cumsum(f) / SR
    if kind == "sine":
        return np.sin(2 * np.pi * ph)
    if kind == "square":
        return np.sign(np.sin(2 * np.pi * ph))
    if kind == "saw":
        return 2 * (ph % 1.0) - 1
    if kind == "tri":
        return 4 * np.abs((ph % 1.0) - 0.5) - 1


def mix(*parts):
    n = max(len(p) for p in parts)
    y = np.zeros(n)
    for p in parts:
        y[: len(p)] += p
    return y


def at(x, sec, total=None):
    i = int(sec * SR)
    y = np.zeros(i + len(x) if total is None else int(total * SR))
    k = min(len(x), len(y) - i)
    y[i:i + k] += x[:k]
    return y


def norm(y, peak=0.9):
    y = S.hp(y, 40)
    m = np.abs(y).max() + 1e-9
    y = y / m * peak
    n = min(len(y), int(0.004 * SR))
    y[-n:] *= np.linspace(1, 0, n)
    y[:2] *= np.array([0.0, 0.5])
    return y


# ---------------------------------------------------------------- звуки
def shot_bow(v):
    f0 = 180 + 40 * v
    tw = S.pluck(f0, 0.06, 0.9, decay=0.12, bright=0.6, ring=0.05, K=10, body=False)
    w = S.bp(nz(int(0.22 * SR)), 1500 + 400 * v, 6000) * env(int(0.22 * SR), 0.03, 0.06)
    return norm(mix(tw * 0.8, w * 0.5), 0.75)


def shot_gun(v):
    n = int(0.16 * SR)
    pop = S.bp(nz(n), 800, 7000) * env(n, 0.001, 0.02 + 0.005 * v)
    th = tone(sweep(260 - 30 * v, 70, 0.12)) * env(int(0.12 * SR), 0.001, 0.03)
    return norm(mix(pop, th * 0.8), 0.7)


def shot_heavy(v):
    n = int(0.6 * SR)
    boom = tone(sweep(150 + 20 * v, 38, 0.6, 2.0, n=n)) * env(n, 0.002, 0.18)
    blast = S.lp(nz(n), 1800) * env(n, 0.001, 0.07)
    return norm(np.tanh(1.8 * mix(boom, blast * 0.9)), 0.85)


def shot_magic(v):
    n = int(0.28 * SR)
    f = sweep(1500 + 300 * v, 420, 0.28, 2.0)
    y = tone(f, "tri") * env(n, 0.002, 0.08)
    sp = S.hp(nz(n), 5000) * env(n, 0.001, 0.03) * 0.4
    fm = np.sin(2 * np.pi * np.cumsum(f * 2.5) / SR) * env(n, 0.001, 0.05) * 0.4
    return norm(mix(y, sp, fm), 0.6)


def shot_throw(v):
    n = int(0.24 * SR)
    t = t_(0.24)
    y = nz(n)
    lo = S.bp(y, 500 + 200 * v, 2500)
    e = np.sin(np.pi * np.clip(t / 0.22, 0, 1)) ** 1.5
    return norm(lo * e, 0.55)


def swing(v):
    n = int(0.2 * SR)
    t = t_(0.2)
    a = S.bp(nz(n), 900 + 300 * v, 4200)
    e = np.sin(np.pi * np.clip(t / 0.17, 0, 1)) ** 3
    return norm(a * e, 0.6)


def swing_heavy(v):
    n = int(0.34 * SR)
    t = t_(0.34)
    a = S.bp(nz(n), 250 + 60 * v, 1600)
    e = np.sin(np.pi * np.clip(t / 0.3, 0, 1)) ** 2.5
    return norm(a * e, 0.7)


def hit(v):
    n = int(0.16 * SR)
    th = tone(sweep(180 + 30 * v, 60, 0.14, n=n)) * env(n, 0.001, 0.035)
    cl = S.bp(nz(n), 1200, 5000) * env(n, 0.0005, 0.008)
    return norm(np.tanh(2.0 * mix(th, cl * 0.6)), 0.8)


def hit_big():
    n = int(0.35 * SR)
    th = tone(sweep(130, 40, 0.3, n=n)) * env(n, 0.001, 0.08)
    cr = S.lp(nz(n), 3000) * env(n, 0.001, 0.03)
    return norm(np.tanh(2.2 * mix(th, cr * 0.8)), 0.9)


def clank(v):
    n = int(0.3 * SR)
    y = S.additive(1.0, n, [1800 + 200 * v, 2950, 4400, 6100], [1.0, 0.6, 0.4, 0.2], [0.09, 0.06, 0.04, 0.03])
    y += S.hp(nz(n), 3000) * env(n, 0.0005, 0.004)
    return norm(y, 0.5)


def impact(v):
    n = int(0.09 * SR)
    y = S.bp(nz(n), 500 + 300 * v, 4000) * env(n, 0.0005, 0.012)
    y += tone(np.full(n, 140.0 + 40 * v)) * env(n, 0.0005, 0.015) * 0.5
    return norm(y, 0.55)


def boom(big, v):
    sec = 1.4 if big else 0.7
    n = int(sec * SR)
    low = tone(sweep(90 if big else 130, 30, sec, 2.0, n=n)) * env(n, 0.002, 0.35 if big else 0.15)
    body = S.lp(nz(n), 1200 if big else 2200) * env(n, 0.002, 0.25 if big else 0.1)
    crack = S.hp(nz(n), 2500) * env(n, 0.0005, 0.03)
    deb = S.crackle(n, 40.0) * env(n, 0.05, 0.3) * (0.8 if big else 0.4)
    y = mix(low * 1.2, body, crack * 0.5, deb)
    return norm(np.tanh(1.6 * y), 0.95 if big else 0.85)


def break_wood(v):
    n = int(0.35 * SR)
    y = np.zeros(n)
    for k in range(5):
        i = int(R.uniform(0, 0.12) * SR)
        L = int(R.uniform(0.02, 0.07) * SR)
        b = S.bp(nz(L), R.uniform(300, 700), R.uniform(1500, 3000)) * np.exp(-np.arange(L) / (L / 4))
        y[i:i + L] += b * R.uniform(0.5, 1.0)
    y += tone(np.full(n, 110.0 + 20 * v)) * env(n, 0.001, 0.04) * 0.4
    return norm(y, 0.65)


def break_stone(v):
    n = int(0.5 * SR)
    y = S.lp(nz(n), 1400) * env(n, 0.001, 0.08)
    y += S.crackle(n, 70.0) * env(n, 0.01, 0.18) * 1.4
    return norm(y, 0.65)


def break_glass(v):
    n = int(0.6 * SR)
    y = np.zeros(n)
    for k in range(9):
        i = int(R.uniform(0, 0.15) * SR)
        f = R.uniform(2500, 6500)
        L = n - i
        y[i:] += np.sin(2 * np.pi * f * np.arange(L) / SR) * np.exp(-np.arange(L) / (R.uniform(0.04, 0.15) * SR)) * R.uniform(0.3, 1.0)
    y += S.hp(nz(n), 4000) * env(n, 0.0005, 0.02)
    return norm(y, 0.5)


def hurt(v):
    n = int(0.22 * SR)
    f = sweep(420 - 60 * v, 180, 0.22, 1.5)
    y = tone(f, "square") * env(n, 0.002, 0.08)
    y = S.lp(y, 1800)
    th = tone(sweep(160, 60, 0.12, n=n)) * env(n, 0.001, 0.04)
    return norm(mix(y * 0.5, th), 0.75)


def death_hero():
    n = int(1.0 * SR)
    f = sweep(520, 110, 1.0, 1.2)
    y = S.lp(tone(f, "saw"), 2200) * env(n, 0.01, 0.4)
    poof = S.lp(nz(n), 2500) * env(n, 0.002, 0.12)
    return norm(mix(y * 0.6, poof * 0.7), 0.8)


def death_bot(v):
    n = int(0.4 * SR)
    poof = S.bp(nz(n), 300, 3500) * env(n, 0.002, 0.07 + 0.02 * v)
    pop = tone(sweep(300 + 60 * v, 80, 0.15, n=n)) * env(n, 0.001, 0.05)
    return norm(mix(poof, pop * 0.7), 0.7)


def death_boss():
    n = int(2.4 * SR)
    rum = S.lp(nz(n), 300) * env(n, 0.02, 0.9) * 1.5
    b = boom(True, 0)
    f = sweep(180, 50, 2.0, 1.5)
    growl = S.bp(tone(f, "saw") * (1 + 0.5 * np.sin(2 * np.pi * 23 * t_(2.0))), 150, 1600) * env(int(2.0 * SR), 0.05, 0.7)
    return norm(np.tanh(1.4 * mix(rum, b, growl * 0.7)), 0.95)


def jump(v):
    n = int(0.16 * SR)
    t = t_(0.16)
    y = S.bp(nz(n), 600, 3000) * np.sin(np.pi * np.clip(t / 0.14, 0, 1)) ** 2
    bl = tone(sweep(260 + 30 * v, 520, 0.12, 1.0, n=n)) * env(n, 0.002, 0.04)
    return norm(mix(y * 0.6, bl * 0.25), 0.4)


def ability(v):
    n = int(0.45 * SR)
    w = S.bp(nz(n), 700, 5000) * np.sin(np.pi * np.clip(t_(0.45) / 0.35, 0, 1)) ** 2
    ch = S.celesta(S.midi_hz(76 + 3 * v), 0.25, 0.8)[:n]
    return norm(mix(w * 0.5, ch * 0.7), 0.6)


def mega():
    n = int(0.9 * SR)
    sh = np.zeros(n)
    for k, m in enumerate([72, 76, 79, 84, 88]):
        sh += at(S.celesta(S.midi_hz(m), 0.3, 0.8), 0.04 * k, 0.9)
    sub = tone(sweep(60, 120, 0.9, 1.0, n=n)) * env(n, 0.05, 0.4) * 0.8
    w = S.bp(nz(n), 1000, 7000) * env(n, 0.05, 0.25) * 0.5
    return norm(mix(sh, sub, w), 0.75)


def ult():
    n = int(1.2 * SR)
    t = t_(1.2)
    rise = S.bp(nz(n), 400, 6000) * np.clip(t / 0.7, 0, 1) ** 2 * (t < 0.75)
    f = sweep(110, 440, 0.75, 1.0)
    sw = np.zeros(n)
    sw[: len(f)] = S.lp(tone(f, "saw"), 3000) * np.clip(t_(0.75) / 0.7, 0, 1) * 0.5
    hitp = at(boom(True, 1)[: int(0.8 * SR)], 0.72, 1.2)
    return norm(mix(rise * 0.6, sw, hitp), 0.9)


def heal():
    n = int(0.75 * SR)
    y = np.zeros(n)
    for k, m in enumerate([76, 79, 83, 88]):
        y += at(S.bell(S.midi_hz(m), 0.2, 0.7)[: int(0.5 * SR)], 0.07 * k, 0.75)
    return norm(y, 0.55)


def buff():
    n = int(0.6 * SR)
    y = np.zeros(n)
    for k, m in enumerate([67, 71, 74, 79]):
        y += at(S.chip(S.midi_hz(m), 0.09, 0.9, pw=0.5), 0.065 * k, 0.6)
    return norm(y, 0.55)


def buff_mega():
    n = int(1.0 * SR)
    y = np.zeros(n)
    for k, m in enumerate([67, 71, 74, 79, 83, 86, 91]):
        y += at(S.chip(S.midi_hz(m), 0.1, 0.9, pw=0.25), 0.055 * k, 1.0)
    y += at(S.crash(0.5, 0.8)[: int(0.6 * SR)], 0.38, 1.0) * 0.5
    return norm(y, 0.7)


def coin(v):
    n = int(0.3 * SR)
    a = S.additive(1.0, n, [2637 + 200 * v, 3520 + 200 * v], [1.0, 0.7], [0.08, 0.12])
    b = at(S.additive(1.0, int(0.25 * SR), [3951 + 150 * v, 5274], [1.0, 0.5], [0.07, 0.09]), 0.06, 0.3)
    return norm(mix(a, b), 0.5)


def click():
    n = int(0.05 * SR)
    y = tone(np.full(n, 1700.0)) * env(n, 0.0005, 0.008)
    y += S.hp(nz(n), 4000) * env(n, 0.0005, 0.003) * 0.4
    return norm(y, 0.4)


def beep():
    n = int(0.18 * SR)
    y = tone(np.full(n, 880.0)) * env(n, 0.003, 0.09) + 0.3 * tone(np.full(n, 1760.0)) * env(n, 0.003, 0.05)
    return norm(y, 0.55)


def go():
    n = int(1.2 * SR)
    br = mix(*[S.brass(S.midi_hz(m), 0.55, 0.95) for m in (55, 62, 67, 71)])
    y = mix(br, S.crash(0.7, 1.0) * 0.6, S.kick(1.0) * 0.8)
    return norm(y[:n], 0.85)


def horn():
    n = int(1.6 * SR)
    y = mix(S.horn(S.midi_hz(45), 1.0, 0.9), S.horn(S.midi_hz(52), 1.0, 0.7) * 0.6)
    return norm(y[:n], 0.75)


def roar():
    sec = 1.6
    n = int(sec * SR)
    t = t_(sec)
    f = 90 + 30 * np.sin(np.pi * t / sec) + 8 * np.sin(2 * np.pi * 17 * t)
    src = tone(f, "saw") + 0.6 * nz(n)
    y = S.bp(src, 120, 900) * 1.0 + S.bp(src, 900, 2600) * 0.5
    e = np.sin(np.pi * np.clip(t / sec, 0, 1)) ** 0.7 * (1 - np.exp(-t / 0.05))
    return norm(np.tanh(2.0 * y * e), 0.9)


def stun():
    n = int(0.9 * SR)
    y = np.zeros(n)
    for k in range(6):
        m = [84, 88, 91][k % 3]
        y += at(S.musicbox(S.midi_hz(m), 0.1, 0.7)[: int(0.4 * SR)], 0.11 * k, 0.9)
    return norm(y, 0.5)


def siren():
    sec = 2.2
    t = t_(sec)
    f = 620 + 320 * np.sin(2 * np.pi * t / 1.1 - np.pi / 2) * 0.5 + 160
    y = S.lp(tone(f, "saw"), 3000) * 0.6 + tone(f * 1.5) * 0.3
    e = np.clip(t / 0.1, 0, 1) * np.clip((sec - t) / 0.3, 0, 1)
    return norm(y * e, 0.65)


def zap(v):
    n = int(0.55 * SR)
    y = S.hp(nz(n), 2000) * env(n, 0.0005, 0.04)
    y += S.crackle(n, 120.0) * env(n, 0.001, 0.15) * 2.0
    y += S.lp(nz(n), 500) * env(n, 0.01, 0.2) * 0.8
    return norm(y, 0.8)


def slam(v):
    n = int(0.7 * SR)
    th = tone(sweep(90 + 10 * v, 35, 0.5, n=n)) * env(n, 0.001, 0.15)
    rum = S.lp(nz(n), 500) * env(n, 0.005, 0.2)
    deb = S.crackle(n, 40.0) * env(n, 0.03, 0.2) * 0.6
    return norm(np.tanh(1.8 * mix(th * 1.2, rum, deb)), 0.9)


def fire():
    n = int(0.7 * SR)
    t = t_(0.7)
    y = S.bp(nz(n), 300, 3000) * np.sin(np.pi * np.clip(t / 0.65, 0, 1)) ** 1.2
    y += S.crackle(n, 60.0) * 0.8
    return norm(y, 0.6)


def splat(v):
    n = int(0.3 * SR)
    y = S.lp(nz(n), 1200 + 300 * v) * env(n, 0.002, 0.05)
    bl = tone(sweep(300 + 50 * v, 900, 0.08, 1.0)) * env(int(0.08 * SR), 0.002, 0.03)
    return norm(mix(y, bl * 0.4), 0.6)


# ---------------------------------------------------------------- появление боссов
def verb(y, sec=1.6, wet=0.3, seed=11):
    """Хвост реверберации (моно): зал, в котором появляется босс."""
    ir = S.make_ir(sec, 0.55, 0.015, 1.0, seed)[0]
    w = signal.fftconvolve(y, ir)[: len(y) + int(0.7 * SR)]
    out = np.zeros(len(w))
    out[: len(y)] += y
    out += w * wet * 0.12
    k = int(0.5 * SR)
    out[-k:] *= np.linspace(1, 0, k) ** 2           # хвост затихает плавно
    return out


def growl(f0, sec, rough=1.0, hi=1800):
    """Рык зверя: низкая пила с «дребезгом», немного дыхания (не шипение)."""
    n = int(sec * SR)
    t = t_(sec)
    f = f0 * (1 + 0.18 * np.sin(np.pi * t / sec)) + 5 * np.sin(2 * np.pi * 21 * t)
    src = tone(f, "saw") * (0.65 + 0.35 * np.sin(2 * np.pi * 29 * t) * rough) + 0.22 * nz(n)
    y = S.bp(src, 70, 650) + S.bp(src, 650, hi) * 0.28
    e = np.sin(np.pi * np.clip(t / sec, 0, 1)) ** 0.6 * (1 - np.exp(-t / 0.04))
    return np.tanh(2.4 * y * e)


def caw(f0=900.0):
    """Карканье вороны."""
    sec = 0.32
    n = int(sec * SR)
    t = t_(sec)
    f = f0 * (1.0 - 0.35 * t / sec)
    src = tone(f, "saw") + 0.4 * nz(n)
    y = S.bp(src, 600, 2400) * np.sin(np.pi * np.clip(t / sec, 0, 1)) ** 0.5
    return np.tanh(2.0 * y) * 0.6


# Главный акцент (крик, удар, рог) — сразу, в первые доли секунды: звук звучит
# вместе с криком босса на экране, а не после него. Хвост — следом.
def intro_war():          # сержант: удар и аккорд горна сразу, следом барабанная дробь
    L = 2.2
    hit = mix(S.kick(1.0) * 1.1, S.crash(0.8, 1.3) * 0.8, S.taiko(0.9) * 0.8)
    hc = mix(S.horn(S.midi_hz(55), 1.2, 1.0), S.horn(S.midi_hz(62), 1.2, 0.95) * 0.8, S.horn(S.midi_hz(67), 1.2, 0.9) * 0.6,
             S.horn(S.midi_hz(43), 1.2, 0.9) * 0.6)
    roll = np.zeros(int(L * SR))
    for k in range(18):
        roll += at(S.snare(0.85 - 0.6 * k / 18), 0.35 + 0.045 * k, L)
    return norm(verb(mix(at(hit, 0.0, L), at(hc * 1.4, 0.0, L), roll * 0.5), 1.4, 0.3), 0.9)


def intro_bandit():       # атаман: боевой выкрик и звон клинков сразу, потом топот и свист
    L = 2.0
    gr = growl(130, 0.75, 0.6, 2200) * 0.7
    clang = mix(S.anvil(1.0), at(S.anvil(0.8), 0.12) * 0.8)
    stomp = mix(*[at(S.tom(90, 0.9, 0.25), 0.2 + 0.17 * k, L) for k in range(4)])
    t = t_(0.5)
    f = 1900 + 900 * np.clip(t / 0.2, 0, 1) - 900 * np.clip((t - 0.3) / 0.2, 0, 1)
    wh = S.bp(tone(f) + 0.05 * nz(len(t)), 900, 4000) * np.clip(t / 0.03, 0, 1) * np.clip((0.5 - t) / 0.08, 0, 1) * 0.4
    return norm(verb(mix(at(gr, 0.0, L), at(clang * 0.7, 0.02, L), stomp * 0.8, at(wh, 0.85, L)), 1.2, 0.25), 0.9)


def intro_goblin():       # вождь гоблинов: боевой визг и рог сразу, следом племенные барабаны
    L = 2.4
    n = int(1.0 * SR)
    t = t_(1.0)
    f = S.midi_hz(58) * (1 + 0.05 * np.sin(2 * np.pi * 6.5 * t)) * (1 + 0.25 * np.exp(-t / 0.08)) * (1 - 0.1 * t)
    shriek = S.bp(tone(f, "saw") * 0.6 + tone(f * 1.5, "square") * 0.25 + 0.15 * nz(n), 400, 3200)
    shriek *= np.clip(t / 0.015, 0, 1) * np.exp(-t / 0.45)
    fr = S.midi_hz(46) * (1 + 0.04 * np.sin(2 * np.pi * 5.5 * t)) * (1 - 0.06 * t)
    rg = S.bp(tone(fr, "square") * 0.6 + tone(fr * 1.01, "saw") * 0.5, 200, 1600) * np.clip(t / 0.03, 0, 1) * np.clip((1.0 - t) / 0.25, 0, 1)
    dr = np.zeros(int(L * SR))
    tt = 0.0
    gap = 0.2
    for k in range(9):
        dr += at(S.taiko(0.95 - 0.04 * k, 70 if k % 2 == 0 else 95), tt, L)
        tt += gap
        gap *= 0.92
    return norm(verb(mix(at(np.tanh(2.0 * shriek) * 0.7, 0.0, L), at(rg * 0.8, 0.0, L), dr), 1.3, 0.25), 0.9)


def intro_wood():         # Энт: удар корней и стон дерева сразу, потом шелест и гул
    L = 2.4
    n = int(L * SR)
    t = t_(L)
    f = 60 + 30 * np.exp(-t / 0.6) + 3 * np.sin(2 * np.pi * 0.8 * t)
    stick = (np.sin(2 * np.pi * np.cumsum(9 + 6 * np.sin(2 * np.pi * 0.5 * t)) / SR) > 0.6).astype(float)
    cr = S.bp(tone(f, "saw") * (0.5 + 0.5 * stick), 120, 1100) * np.clip(t / 0.03, 0, 1) * np.exp(-t / 1.2)
    leaves = S.bp(nz(n), 2500, 7000) * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 1.3 * t))) * np.clip((t - 0.3) / 0.4, 0, 1) * 0.1
    rumble = S.lp(nz(n), 120) * np.exp(-t / 1.0) * 2.0
    return norm(verb(mix(at(S.taiko(1.0, 48), 0.0, L), np.tanh(2.5 * cr) * 0.7, leaves, rumble), 1.6, 0.3), 0.9)


def intro_insect():       # Паучья королева: визг и щелчки жвал сразу, стрекот следом
    L = 1.9
    n = int(L * SR)
    t = t_(0.8)
    f = 2600 + 900 * np.exp(-t / 0.2) + 120 * np.sin(2 * np.pi * 37 * t)
    scr = S.bp(tone(f, "saw"), 1500, 6000) * np.clip(t / 0.01, 0, 1) * np.exp(-t / 0.35) * 0.4
    clicks = mix(*[at(S.woodblock(0.9, 1400 + 200 * k), 0.05 * k, L) for k in range(5)])
    y = np.zeros(n)
    tt = 0.25
    while tt < 1.4:
        y += at(S.bp(nz(int(0.012 * SR)), 2500, 6500) * np.linspace(1, 0, int(0.012 * SR)), tt, L) * R.uniform(0.3, 0.8)
        tt += R.uniform(0.02, 0.06)
    return norm(verb(mix(at(scr, 0.0, L), clicks * 0.6, at(growl(140, 0.7, 1.0, 2400), 0.0, L) * 0.35, y * 0.45), 1.1, 0.25), 0.85)


def intro_bone():         # Король скелетов: удар колокола и литавры сразу, хор и стук костей
    L = 2.6
    bell = S.alarm_bell(0.9, 110.0)
    ch = mix(*[S.choir(S.midi_hz(m), 1.8, 0.9, "o") for m in (45, 48, 52, 57)])
    rat = np.zeros(int(L * SR))
    tt = 0.15
    for k in range(16):
        rat += at(S.woodblock(R.uniform(0.4, 1.0), R.uniform(1500, 2600)), tt, L)
        tt += R.uniform(0.03, 0.07)
    return norm(verb(mix(at(bell, 0.0, L), at(S.timpani(55, 1.0), 0.0, L), at(ch * 2.2, 0.0, L), rat * 0.6), 2.0, 0.4), 0.9)


def intro_mine():         # Барон Грыз: взрыв сразу, следом звон кирок и обвал
    L = 2.2
    bang = boom(True, 0)
    picks = mix(*[at(S.anvil(0.7), 0.35 + 0.2 * k, L) * (0.8 - 0.15 * k) for k in range(4)])
    debris = at(S.crackle(int(1.2 * SR), 50.0) * np.linspace(1, 0, int(1.2 * SR)), 0.1, L)
    return norm(verb(mix(at(bang, 0.0, L) * 1.2, picks * 0.5, debris), 1.3, 0.25), 0.9)


def intro_crystal():      # Ирида: звон колокольчика и хрустальный перезвон сразу
    L = 2.4
    bell = S.bell(S.midi_hz(76), 1.6, 0.9)
    ar = mix(*[at(S.glass(S.midi_hz(m), 0.9, 0.8), 0.06 * k, L) for k, m in enumerate((76, 79, 83, 86, 88, 91, 95))])
    gp = S.glass_pad(S.midi_hz(64), 1.6, 0.8)
    sw = at(gp[0] if gp.ndim == 2 else gp, 0.1, L)
    return norm(verb(mix(at(bell * 0.7, 0.0, L), ar * 0.8, sw * 1.2), 2.0, 0.45), 0.85)


def intro_arena():        # гладиатор: фанфара и удар сразу, трибуны взрываются рёвом
    L = 2.4
    n = int(L * SR)
    t = t_(L)
    cr = S.crowd(n, 1.0) * np.clip(t / 0.25, 0, 1) * np.clip((L - t) / 0.7, 0, 1) * 3.0
    fan = mix(S.brass(S.midi_hz(60), 1.2, 1.0), S.brass(S.midi_hz(64), 1.2, 0.95) * 0.8, S.brass(S.midi_hz(67), 1.2, 1.0),
              S.brass(S.midi_hz(72), 1.2, 0.9) * 0.8)
    return norm(verb(mix(cr, at(fan * 1.3, 0.0, L), at(S.taiko(1.0), 0.0, L)), 1.6, 0.3), 0.9)


def intro_giant():        # Колосс: тяжёлый шаг и стон металла сразу, ещё два шага
    L = 2.2
    steps = mix(*[at(mix(S.taiko(1.0, 45), slam(0) * 0.6), 0.4 * k, L) * (1.0 - 0.15 * k) for k in range(3)])
    n = int(1.3 * SR)
    t = t_(1.3)
    f = 140 * (1 - 0.35 * t / 1.3)
    gm = S.bp(tone(f, "saw") + tone(f * 1.51, "saw") * 0.4, 150, 1400) * np.clip(t / 0.03, 0, 1) * np.exp(-t / 0.8)
    return norm(verb(mix(steps, at(np.tanh(2 * gm) * 0.5, 0.0, L), at(S.anvil(0.6), 0.0, L) * 0.4), 1.4, 0.3), 0.9)


def intro_witch():        # ведьма: хохот сразу, вороны и тревожный аккорд
    L = 2.3
    ha = np.zeros(int(L * SR))
    for k in range(7):
        ha += at(S.choir(S.midi_hz(76 - k * 1.5), 0.12, 1.0, "a") * 4.0, 0.12 * k, L)
    caws = mix(at(caw(950), 0.9, L), at(caw(820), 1.2, L), at(caw(1050), 1.45, L))
    pad = mix(*[at(S.strings(S.midi_hz(m), 1.6, 0.6)[0], 0.0, L) for m in (57, 60, 63, 66)])
    return norm(verb(mix(ha, caws * 0.7, pad * 1.5), 1.8, 0.35), 0.85)


def intro_swamp():        # Трясинный Владыка: рык и всплеск сразу, потом бульканье и гул
    L = 2.3
    n = int(L * SR)
    t = t_(L)
    spl = mix(S.lp(nz(int(0.8 * SR)), 900) * env(int(0.8 * SR), 0.005, 0.18) * 1.5, S.taiko(1.0, 40))
    bub = np.zeros(n)
    tt = 0.3
    while tt < 1.8:
        m = int(0.07 * SR)
        tb = np.arange(m) / SR
        f0 = R.uniform(180, 420)
        bub += at(np.sin(2 * np.pi * np.cumsum(f0 * (1 + 2.5 * tb / 0.07)) / SR) * np.exp(-tb / 0.03), tt, L) * R.uniform(0.3, 0.8)
        tt += R.uniform(0.05, 0.16)
    gur = S.lp(nz(n), 180) * (0.5 + 0.5 * np.sin(2 * np.pi * 3.0 * t)) * 2.0 * np.exp(-t / 1.2)
    dr = tone(np.full(n, 41.0)) * np.exp(-t / 1.0) * 0.5
    return norm(verb(mix(at(spl, 0.0, L), at(growl(70, 0.9, 1.2, 900), 0.0, L) * 0.7, bub * 0.5, gur, dr), 1.5, 0.3), 0.9)


def intro_ice():          # Ётун: рог великана и треск льда сразу, вой вьюги следом
    L = 2.4
    n = int(L * SR)
    t = t_(L)
    hn = mix(S.tuba(S.midi_hz(33), 1.3, 1.0), S.horn(S.midi_hz(40), 1.3, 0.8))
    crk = mix(*[at(mix(S.crackle(int(0.25 * SR), 250.0) * 2.0, S.glass(R.uniform(2500, 3500), 0.2, 0.6) * 0.4), 0.08 * k, L) for k in range(4)])
    wf = 600 + 500 * np.sin(np.pi * np.clip(t / L, 0, 1))
    wnd = (S.bp(nz(n), 300, 2200) * 0.6 + tone(wf) * 0.08) * np.clip((t - 0.2) / 0.5, 0, 1) * np.clip((L - t) / 0.8, 0, 1) * 0.8
    return norm(verb(mix(at(hn * 1.4, 0.0, L), crk * 0.7, wnd), 1.8, 0.3), 0.9)


def intro_storm():        # Владыка Бури: разряд и гром сразу, ветер следом
    L = 2.6
    n = int(L * SR)
    t = t_(L)
    crack = mix(S.bp(nz(int(0.12 * SR)), 1200, 5000) * env(int(0.12 * SR), 0.0005, 0.025) * 0.35, zap(0) * 0.25)
    th = mix(S.thunder(1.0) * 1.6, S.taiko(1.0, 42) * 0.9, S.timpani(41, 1.0) * 0.8)
    wind_ = S.bp(nz(n), 300, 2200) * np.clip((t - 0.4) / 0.6, 0, 1) * np.clip((L - t) / 0.8, 0, 1) * 0.35
    return norm(verb(np.tanh(1.6 * mix(at(crack, 0.0, L), at(th, 0.02, L), wind_)), 1.6, 0.25), 0.92)


def intro_hell():         # Цербер: рык трёх голов и вспышка пламени сразу
    L = 2.2
    n = int(0.8 * SR)
    t = t_(0.8)
    wh = S.bp(nz(n), 200, 2500) * np.clip(t / 0.03, 0, 1) * np.exp(-t / 0.35) + S.crackle(n, 80.0)
    g = mix(at(growl(75, 1.3, 1.2, 1200), 0.0, L), at(growl(95, 1.2, 1.0, 1400), 0.12, L) * 0.8, at(growl(120, 1.1, 0.9, 1600), 0.24, L) * 0.7)
    return norm(verb(mix(at(wh, 0.0, L) * 0.7, g, at(S.taiko(0.9, 50), 0.0, L)), 1.3, 0.25), 0.92)


def intro_dark():         # Тёмный Лорд: удар меди, гонг и хор сразу
    L = 2.6
    imp = mix(S.braam(S.midi_hz(26), 1.6, 1.0), S.braam(S.midi_hz(27), 1.6, 0.7) * 0.6, S.gong(1.0) * 1.2, S.kick(1.0) * 0.8)
    ch = mix(*[S.choir(S.midi_hz(m), 1.6, 0.8, "u") for m in (38, 45, 50)])
    return norm(verb(mix(at(imp, 0.0, L), at(ch * 2.0, 0.0, L)), 2.2, 0.35), 0.92)


def intro_void():         # Пустокрыл: провал звука вниз и удар сразу, звон пустоты
    L = 2.4
    n = int(L * SR)
    t = t_(L)
    f = 900 * np.exp(-t / 0.35) + 38
    drop = np.tanh(2.0 * (tone(f) + 0.4 * tone(f * 1.5))) * np.clip(t / 0.01, 0, 1) * np.exp(-t / 1.4)
    shim = S.fm(S.midi_hz(84), n, 1.414, 4.0, 0.8, 1.2) * 0.4
    return norm(verb(mix(drop, at(shim, 0.05, L), S.kick(1.0)), 2.0, 0.4), 0.9)


def intro_herald():       # Предвестник: набат, провал и голоса бездны сразу
    L = 2.8
    n = int(L * SR)
    t = t_(L)
    ch = mix(*[S.choir(S.midi_hz(m), 2.2, 0.9, "a") for m in (50, 53, 57, 61)])
    f = 600 * np.exp(-t / 0.5) + 32
    drop = np.tanh(2.2 * (tone(f) + 0.5 * tone(f * 2.01))) * np.clip(t / 0.01, 0, 1) * np.exp(-t / 1.6)
    bell = S.alarm_bell(0.9, 98.0)
    return norm(verb(mix(ch * 2.4, drop, at(bell, 0.0, L), at(S.gong(1.0), 0.0, L) * 0.8, S.kick(1.0)), 2.2, 0.4), 0.9)


def intro_mill():         # Мельник Жернов: удар молота и скрип жерновов сразу, мука сыплется, ветер
    L = 2.4
    n = int(L * SR)
    t = t_(L)
    hit_ = mix(S.taiko(1.0, 44), slam(1) * 0.7, S.kick(1.0) * 0.6)
    # скрип: низкая «пила» с рваной частотой — деревянный вал под нагрузкой
    m = int(1.6 * SR)
    tm = t_(1.6)
    f = 95 + 25 * np.sin(2 * np.pi * 1.3 * tm) + 8 * np.sin(2 * np.pi * 17 * tm)
    crk = S.bp(tone(f, "saw") * (0.6 + 0.4 * (np.sin(2 * np.pi * 9 * tm) > 0)), 180, 1600) * np.clip(tm / 0.02, 0, 1) * np.exp(-tm / 1.1)
    flour = S.bp(nz(n), 900, 5000) * np.clip((t - 0.15) / 0.3, 0, 1) * np.exp(-t / 0.9) * 0.25
    wnd = S.bp(nz(n), 250, 1400) * np.clip((t - 0.5) / 0.6, 0, 1) * np.clip((L - t) / 0.7, 0, 1) * 0.3
    vo = mix(*[S.choir(S.midi_hz(mm), 1.8, 0.6, "u") for mm in (40, 47)]) * 1.4
    return norm(verb(mix(at(hit_, 0.0, L), at(np.tanh(1.8 * crk) * 0.6, 0.0, L), flour, wnd, at(vo, 0.1, L)), 1.6, 0.3), 0.9)


def intro_headsman():     # Палач Бездны: лязг цепей и удар тесака сразу, скрежет по камню, низкий хор
    L = 2.5
    n = int(L * SR)
    t = t_(L)
    imp = mix(S.anvil(1.0), S.kick(1.0), S.braam(S.midi_hz(28), 1.4, 0.9) * 0.8)
    chains = mix(*[at(mix(S.glass(R.uniform(2600, 4200), 0.12, 0.7) * 0.5, S.bp(nz(int(0.05 * SR)), 2500, 7000)
                          * env(int(0.05 * SR), 0.001, 0.015) * 0.5), 0.03 + 0.055 * k, L) for k in range(9)])
    sc = S.bp(nz(n), 1500, 4500) * np.clip((t - 0.45) / 0.1, 0, 1) * np.clip((1.5 - t) / 0.2, 0, 1) * (0.6 + 0.4 * np.sin(2 * np.pi * 23 * t)) * 0.35
    ch = mix(*[S.choir(S.midi_hz(mm), 2.0, 0.8, "o") for mm in (36, 43)]) * 1.6
    return norm(verb(mix(at(imp, 0.0, L), chains, sc, at(ch, 0.05, L)), 1.8, 0.35), 0.92)


def intro_weaver():       # Ткачиха Разлома: звенящий аккорд нитей сразу, переборы сверху, шёпот хора
    L = 2.6
    ch = mix(*[S.glass(S.midi_hz(mm), 2.2, 0.8) for mm in (71, 74, 78, 83)])
    pl = mix(*[at(S.harp(S.midi_hz(mm), 0.9, 0.7), 0.08 + 0.09 * k, L) for k, mm in enumerate((83, 86, 90, 95, 90, 86, 95, 98))])
    vo = mix(*[S.choir(S.midi_hz(mm), 2.2, 0.6, "a") for mm in (59, 62, 66)]) * 1.3
    sw = tone(sweep(2400, 600, 0.5, 2.0)) * env(int(0.5 * SR), 0.002, 0.2) * 0.15
    return norm(verb(mix(at(ch * 1.3, 0.0, L), pl * 0.7, at(vo, 0.0, L), at(sw, 0.0, L), S.kick(0.6) * 0.5), 2.2, 0.45), 0.85)


def intro_wanderer():     # Странник: не рык — один тихий удар колокола, мягкий хор и ветер
    L = 3.0
    n = int(L * SR)
    t = t_(L)
    bl = mix(S.bell(S.midi_hz(45), 2.6, 0.9), S.bell(S.midi_hz(57), 2.2, 0.5) * 0.5)
    vo = mix(*[S.choir(S.midi_hz(mm), 2.6, 0.55, "o") for mm in (45, 52, 57, 60)]) * 1.2
    wnd = S.bp(nz(n), 300, 1800) * np.clip(t / 0.8, 0, 1) * np.clip((L - t) / 1.0, 0, 1) * 0.18
    low = tone(np.full(n, 55.0)) * np.clip(t / 0.05, 0, 1) * np.exp(-t / 1.6) * 0.35
    return norm(verb(mix(at(bl, 0.0, L), at(vo, 0.05, L), wnd, low), 2.6, 0.45), 0.72)


def intro_shepherd():     # Пастух Разлома: удар колокола сразу, следом топот стада и низкий хор
    L = 2.6
    n = int(L * SR)
    t = t_(L)
    bl = mix(S.bell(S.midi_hz(50), 2.2, 1.0), S.bell(S.midi_hz(57), 1.8, 0.5) * 0.5, S.kick(0.8) * 0.5)
    hooves = np.zeros(n)
    tt = 0.25
    while tt < 2.0:
        hooves += at(mix(S.taiko(0.5, 70), S.woodblock(0.3, 420.0) * 0.4), tt, L) * (0.4 + 0.6 * min(1.0, tt))
        tt += R.uniform(0.07, 0.13)
    vo = mix(*[S.choir(S.midi_hz(m), 2.2, 0.55, "u") for m in (38, 45, 50)]) * 1.3
    return norm(verb(mix(at(bl, 0.0, L), hooves * 0.6, at(vo, 0.1, L)), 1.8, 0.35), 0.88)


def intro_abyss_lord():   # Лорд Бездны: Тёмный Лорд, собранный бездной заново, — тот же удар меди, но ниже
    L = 3.0                # и «треснувший»: камень крошится, в груди дважды бьётся сердце, хор расходится
    n = int(L * SR)
    t = t_(L)
    imp = mix(S.braam(S.midi_hz(23), 1.9, 1.0), S.braam(S.midi_hz(29), 1.7, 0.7) * 0.55, S.gong(1.0), S.kick(1.0, 0.8, 0.5))
    f = 420 * np.exp(-t / 0.45) + 30
    drop = np.tanh(2.2 * (tone(f) + 0.5 * tone(f * 1.5))) * np.clip(t / 0.01, 0, 1) * np.exp(-t / 1.5)
    stone = S.crackle(n, 55.0) * np.clip(t / 0.05, 0, 1) * np.exp(-t / 0.7) * 0.7 + S.bp(nz(n), 150, 900) * np.exp(-t / 0.35) * 0.5
    heart = mix(*[at(mix(S.taiko(1.0, 46), S.kick(0.9, 0.7, 0.4)), tt, L) * k for tt, k in ((0.75, 0.9), (0.95, 0.6), (1.55, 0.8), (1.75, 0.5))])
    ch = mix(*[S.choir(S.midi_hz(m), 2.4, 0.8, "o") for m in (35, 41, 42, 47)]) * 1.8      # малая секунда внутри — «не тот» Лорд
    return norm(verb(mix(at(imp, 0.0, L), drop * 0.8, stone, heart * 0.9, at(ch, 0.05, L)), 2.4, 0.4), 0.92)


def intro_mad_wanderer():  # Странник, поглощённый бездной: его колокол бьёт так же, но тон сползает вниз,
    L = 3.2                # хор срывается в диссонанс, под ним бьётся сердце бездны
    n = int(L * SR)
    t = t_(L)
    k = int(2.8 * SR)
    tk = np.arange(k) / SR
    bend = 1.0 - 0.16 * np.clip((tk - 0.25) / 1.6, 0, 1) ** 1.5              # колокол «плывёт» вниз
    bl = (np.sin(2 * np.pi * np.cumsum(S.midi_hz(45) * bend) / SR) * 0.7
          + np.sin(2 * np.pi * np.cumsum(S.midi_hz(45) * 2.76 * bend) / SR) * 0.3
          + np.sin(2 * np.pi * np.cumsum(S.midi_hz(45) * 5.4 * bend) / SR) * 0.15) * np.clip(tk / 0.004, 0, 1) * np.exp(-tk / 1.1)
    strike = S.bp(nz(int(0.05 * SR)), 900, 5000) * env(int(0.05 * SR), 0.001, 0.012) * 0.6
    vo = mix(*[S.choir(S.midi_hz(mm), 2.8, 0.55, "o") for mm in (45, 52, 57)]) * 1.1
    vo2 = mix(*[S.choir(S.midi_hz(mm), 2.0, 0.6, "a") for mm in (46, 51, 58)]) * 1.2      # вторая, «чужая» половина хора
    heart = mix(*[at(mix(S.taiko(0.9, 40), S.kick(0.8, 0.6, 0.45)), tt, L) * kk for tt, kk in ((0.6, 0.7), (0.82, 0.45), (1.5, 0.85), (1.72, 0.55), (2.4, 1.0), (2.62, 0.6))])
    wnd = S.bp(nz(n), 200, 1500) * np.clip(t / 0.8, 0, 1) * np.clip((L - t) / 0.9, 0, 1) * (0.6 + 0.4 * np.sin(2 * np.pi * 5.5 * t)) * 0.2
    low = tone(sweep(62.0, 31.0, 2.2, 2.0, n)) * np.clip(t / 0.05, 0, 1) * np.exp(-t / 1.8) * 0.5
    return norm(verb(mix(at(bl, 0.0, L), at(strike, 0.0, L), at(vo, 0.05, L), at(vo2, 0.9, L), heart * 0.8, wnd, low), 2.6, 0.45), 0.86)


INTROS = {"intro_war": intro_war, "intro_bandit": intro_bandit, "intro_goblin": intro_goblin, "intro_wood": intro_wood,
          "intro_insect": intro_insect, "intro_bone": intro_bone, "intro_mine": intro_mine, "intro_crystal": intro_crystal,
          "intro_arena": intro_arena, "intro_giant": intro_giant, "intro_witch": intro_witch, "intro_swamp": intro_swamp,
          "intro_ice": intro_ice, "intro_storm": intro_storm, "intro_hell": intro_hell, "intro_dark": intro_dark,
          "intro_void": intro_void, "intro_herald": intro_herald, "intro_mill": intro_mill,
          "intro_headsman": intro_headsman, "intro_weaver": intro_weaver, "intro_wanderer": intro_wanderer,
          "intro_shepherd": intro_shepherd,
          # новые голоса — только в конец: каждый следующий звук берёт случайные числа после
          # предыдущих, и вставка в середину изменила бы все звуки ниже
          "intro_abyss_lord": intro_abyss_lord, "intro_mad_wanderer": intro_mad_wanderer}


# ---------------------------------------------------------------- телефон (ульта Главного)
def phone_ring():
    """Мелодичный рингтон: маримба играет короткую фразу дважды (≈2 с, играет по кругу)."""
    notes = [76, 79, 84, 83, 79, 76, 79, 81]
    y = np.zeros(int(2.1 * SR))
    for rep in range(2):
        for k, m in enumerate(notes):
            y = mix(y, at(mix(S.marimba(S.midi_hz(m), 0.22, 0.85), 0.5 * S.kalimba(S.midi_hz(m + 12), 0.2, 0.5)), rep * 1.0 + k * 0.11))
    return norm(y[:int(2.1 * SR)], 0.6)


def phone_babble():
    """Неразборчивая речь из трубки: «слоги» из пилы с формантами, узкая телефонная полоса."""
    sec = 5.0
    n = int(sec * SR)
    t = np.arange(n) / SR
    rg = np.random.default_rng(7)
    # высота голоса гуляет, как в речи
    f0 = 165 + 35 * np.sin(2 * np.pi * 0.7 * t) + 20 * np.sin(2 * np.pi * 2.3 * t + 1.0)
    src = S.saw(f0)
    out = np.zeros(n)
    # слоги: случайной длины, с паузами; у каждого — своя «гласная» (две форманты)
    vowels = [(730, 1090), (270, 2290), (530, 1840), (570, 840), (440, 1020), (300, 870)]
    pos = 0.0
    while pos < sec - 0.1:
        ln = rg.uniform(0.09, 0.22)
        i0, i1 = int(pos * SR), min(n, int((pos + ln) * SR))
        f1, f2 = vowels[rg.integers(len(vowels))]
        seg = src[i0:i1]
        v = S.bp(seg, f1 * 0.8, f1 * 1.25) + 0.6 * S.bp(seg, f2 * 0.85, f2 * 1.2)
        w = np.sin(np.linspace(0, np.pi, i1 - i0)) ** 0.7
        out[i0:i1] += v * w * rg.uniform(0.6, 1.0)
        pos += ln + (rg.uniform(0.25, 0.5) if rg.random() < 0.18 else rg.uniform(0.01, 0.05))
    out += 0.02 * nz(n)                                   # шипение линии
    out = S.bp(out, 300, 3400, 4)                         # телефонная полоса
    out = np.tanh(out * 3.0)                              # слегка «пережато», как в динамике телефона
    return norm(out, 0.5)


def notify():
    """Уведомление: короткое двухтоновое «дзынь»."""
    a = S.additive(1.0, int(0.25 * SR), [1318.5, 2637], [1.0, 0.4], [0.07, 0.05])
    b = at(S.additive(1.0, int(0.3 * SR), [1975.5, 3951], [1.0, 0.35], [0.09, 0.06]), 0.08, 0.38)
    return norm(mix(a, b), 0.45)


PHONE = {"phone_ring": phone_ring, "phone_babble": phone_babble, "notify": notify}


# ---------------------------------------------------------------- DJ Клима
def scratch(v):
    """Скретч: короткий «сэмпл» (аккорд пилой с шумом) гоняют пальцем по пластинке туда-сюда."""
    rg = np.random.default_rng(60 + v)
    src_n = int(0.6 * SR)
    ts = np.arange(src_n) / SR
    src = sum(np.sign(np.sin(2 * np.pi * f * ts)) * a for f, a in ((220, 0.5), (330, 0.35), (440, 0.3)))
    src = S.lp(src + 0.4 * nz(src_n), 4200) * 0.6
    sec = 0.34 + 0.06 * v
    n = int(sec * SR)
    t = np.arange(n) / SR
    # скорость пластинки: вперёд-назад, два «вжика» с разной резкостью
    strokes = [0.0, 0.11, 0.2, sec]
    speed = np.zeros(n)
    for k in range(len(strokes) - 1):
        i0, i1 = int(strokes[k] * SR), int(strokes[k + 1] * SR)
        x = np.linspace(0, 1, i1 - i0)
        speed[i0:i1] = (1 if k % 2 == 0 else -1) * np.sin(np.pi * x) * rg.uniform(1.6, 2.6)
    pos = np.cumsum(speed) / SR * SR * 0.35 + src_n * 0.3
    pos = np.clip(pos, 0, src_n - 2)
    i = pos.astype(int)
    fr = pos - i
    y = src[i] * (1 - fr) + src[i + 1] * fr
    y *= np.abs(speed) / (np.abs(speed).max() + 1e-9)
    y = S.bp(y, 300, 6000)
    return norm(y, 0.7)


def feedback():
    """Фонящий микрофон: удар о врага, нарастающий писк обратной связи и звон в ушах."""
    sec = 1.9
    n = int(sec * SR)
    t = np.arange(n) / SR
    thump = mix(S.kick(0.8, 1.6, 0.08), 0.5 * S.lp(nz(int(0.03 * SR)), 3000))
    f = 2960 + 40 * np.sin(2 * np.pi * 5.5 * t) + 300 * np.clip(t / 0.5, 0, 1)
    squeal = (np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.3 * np.sin(4 * np.pi * np.cumsum(f) / SR))
    e1 = np.clip(t / 0.35, 0, 1) ** 2 * np.exp(-np.clip(t - 0.55, 0, None) / 0.08)
    ring = np.sin(2 * np.pi * 4200 * t) * np.exp(-np.clip(t - 0.6, 0, None) / 0.6) * (t > 0.5) * 0.35
    y = mix(thump * 0.8, squeal * e1 * 0.55, ring)
    return norm(np.tanh(1.5 * y), 0.6)


def drop():
    """Басовый «дроп»: глубокая бочка с сабом, уходящим вниз, и шумовой удар."""
    sec = 1.3
    n = int(sec * SR)
    t = np.arange(n) / SR
    f = 30 + 90 * np.exp(-t / 0.06) + 20 * np.exp(-t / 0.4)
    sub = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.55)
    hit = S.lp(nz(n), 2500) * np.exp(-t / 0.08) * 0.7
    air = S.hp(nz(n), 5000) * np.exp(-t / 0.35) * 0.25
    return norm(np.tanh(2.2 * (sub + hit + air)), 0.9)


def vinyl(v):
    """Бросок пластинки: свист воздуха и лёгкое «фр-р» вращения."""
    sec = 0.2
    n = int(sec * SR)
    t = np.arange(n) / SR
    w = S.bp(nz(n), 900 + 300 * v, 4500) * np.sin(np.pi * np.clip(t / sec, 0, 1)) ** 1.5
    flutter = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * (38 + 6 * v) * t))
    return norm(w * (0.6 + 0.4 * flutter), 0.55)


def baton(v):
    """Удар дубинкой: глухой шлепок и щелчок."""
    sec = 0.2
    n = int(sec * SR)
    t = np.arange(n) / SR
    body = np.sin(2 * np.pi * (140 + 30 * v) * t) * np.exp(-t / 0.035)
    click = S.bp(nz(n), 1500, 6000) * np.exp(-t / 0.012)
    return norm(body + click * 0.8, 0.75)


# ---------------------------------------------------------------- Почти легенда
def punch(v):
    """Удар силовой перчаткой: глухой шлепок, щелчок и короткий «вжух»."""
    sec = 0.22
    n = int(sec * SR)
    t = np.arange(n) / SR
    body = np.sin(2 * np.pi * np.cumsum(110 + 90 * np.exp(-t / 0.02) + 15 * v) / SR) * np.exp(-t / 0.05)
    snap = S.bp(nz(n), 1800, 7000) * np.exp(-t / 0.01)
    whoosh = S.bp(nz(n), 500, 2500) * np.sin(np.pi * np.clip(t / 0.12, 0, 1)) * (t < 0.12) * 0.4
    return norm(np.tanh(1.8 * (body + 0.7 * snap + whoosh)), 0.8)


def rail():
    """Рельсовая винтовка: нарастающий писк зарядки и резкий сухой выстрел с хвостом."""
    sec = 0.9
    n = int(sec * SR)
    t = np.arange(n) / SR
    f = 600 + 4200 * np.clip(t / 0.28, 0, 1) ** 1.5
    whine = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.clip(t / 0.28, 0, 1) * (t < 0.28) * 0.4
    k = t - 0.28
    crack = (S.hp(nz(n), 1500) * np.exp(-np.clip(k, 0, None) / 0.03) + np.sin(2 * np.pi * 70 * t) * np.exp(-np.clip(k, 0, None) / 0.18)) * (k >= 0)
    tail = S.bp(nz(n), 300, 2000) * np.exp(-np.clip(k, 0, None) / 0.25) * (k >= 0) * 0.3
    return norm(np.tanh(1.6 * (whine + crack + tail)), 0.85)


def meteor():
    """Метеорит: низкий нарастающий свист падения."""
    sec = 0.9
    n = int(sec * SR)
    t = np.arange(n) / SR
    w = S.bp(nz(n), 200, 1800) * (t / sec) ** 1.5
    tone = np.sin(2 * np.pi * np.cumsum(900 - 600 * t / sec) / SR) * (t / sec) ** 2 * 0.25
    return norm(w + tone, 0.6)


def rocket():
    """Залп ракет: шипящий старт с треском."""
    sec = 0.8
    n = int(sec * SR)
    t = np.arange(n) / SR
    hiss = S.bp(nz(n), 1500, 8000) * np.exp(-t / 0.35)
    crackle = S.hp(nz(n), 3000) * (R.random(n) < 0.02) * 2.0 * np.exp(-t / 0.3)
    thump = np.sin(2 * np.pi * 80 * t) * np.exp(-t / 0.06)
    return norm(hiss + crackle + thump, 0.7)


def laser():
    """Лазеры из глаз робота: гудящий луч с биением."""
    sec = 2.0
    n = int(sec * SR)
    t = np.arange(n) / SR
    f = 220 + 30 * np.sin(2 * np.pi * 6 * t)
    y = S.saw(f) * 0.5 + np.sin(2 * np.pi * np.cumsum(f * 3.01) / SR) * 0.3
    e = np.clip(t / 0.6, 0, 1) * np.exp(-np.clip(t - 1.6, 0, None) / 0.1)
    return norm(S.lp(y, 3000) * e, 0.55)


def servo():
    """Титан поднимается: гул моторов, лязг и тяжёлый удар."""
    sec = 1.6
    n = int(sec * SR)
    t = np.arange(n) / SR
    motor = S.saw(60 + 50 * np.clip(t / 1.0, 0, 1)) * 0.4 * np.clip(t / 0.2, 0, 1) * np.exp(-np.clip(t - 1.0, 0, None) / 0.2)
    clank = S.bp(nz(n), 2000, 6000) * np.exp(-np.clip(t - 1.05, 0, None) / 0.05) * (t > 1.05)
    boom = np.sin(2 * np.pi * np.cumsum(40 + 60 * np.exp(-np.clip(t - 1.05, 0, None) / 0.05)) / SR) * np.exp(-np.clip(t - 1.05, 0, None) / 0.35) * (t > 1.05)
    return norm(np.tanh(1.5 * (S.lp(motor, 900) + clank * 0.6 + boom)), 0.85)


def orb():
    """Ядро копит энергию: восходящий гул и звон перед выстрелом."""
    sec = 1.5
    n = int(sec * SR)
    t = np.arange(n) / SR
    f = 120 * 2 ** (2.5 * t / sec)
    y = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.5 * np.sin(2 * np.pi * np.cumsum(f * 2.0) / SR)
    shimmer = S.hp(nz(n), 6000) * 0.2
    return norm((y * 0.6 + shimmer) * (t / sec) ** 1.3, 0.7)


ALMOST = {"punch_1": lambda: punch(0), "punch_2": lambda: punch(1), "rail": rail, "meteor": meteor,
          "rocket": rocket, "laser": laser, "servo": servo, "orb": orb}

DJ = {"scratch_1": lambda: scratch(0), "scratch_2": lambda: scratch(1), "feedback": feedback, "drop": drop,
      "vinyl_1": lambda: vinyl(0), "vinyl_2": lambda: vinyl(1), "vinyl_3": lambda: vinyl(2),
      "baton_1": lambda: baton(0), "baton_2": lambda: baton(1)}


def build():
    S.seed(9)
    out = {}
    for v in range(3):
        out["shot_bow_%d" % (v + 1)] = shot_bow(v)
        out["shot_gun_%d" % (v + 1)] = shot_gun(v)
        out["shot_magic_%d" % (v + 1)] = shot_magic(v)
        out["shot_throw_%d" % (v + 1)] = shot_throw(v)
        out["swing_%d" % (v + 1)] = swing(v)
        out["hit_%d" % (v + 1)] = hit(v)
        out["impact_%d" % (v + 1)] = impact(v)
    for v in range(2):
        out["shot_heavy_%d" % (v + 1)] = shot_heavy(v)
        out["swing_heavy_%d" % (v + 1)] = swing_heavy(v)
        out["clank_%d" % (v + 1)] = clank(v)
        out["boom_small_%d" % (v + 1)] = boom(False, v)
        out["boom_big_%d" % (v + 1)] = boom(True, v)
        out["break_wood_%d" % (v + 1)] = break_wood(v)
        out["break_stone_%d" % (v + 1)] = break_stone(v)
        out["break_glass_%d" % (v + 1)] = break_glass(v)
        out["hurt_%d" % (v + 1)] = hurt(v)
        out["death_bot_%d" % (v + 1)] = death_bot(v)
        out["jump_%d" % (v + 1)] = jump(v)
        out["ability_%d" % (v + 1)] = ability(v)
        out["coin_%d" % (v + 1)] = coin(v)
        out["zap_%d" % (v + 1)] = zap(v)
        out["slam_%d" % (v + 1)] = slam(v)
        out["splat_%d" % (v + 1)] = splat(v)
    out.update({"hit_big": hit_big(), "death_hero": death_hero(), "death_boss": death_boss(), "mega": mega(),
                "ult": ult(), "heal": heal(), "buff": buff(), "buff_mega": buff_mega(), "click": click(),
                "beep": beep(), "go": go(), "horn": horn(), "roar": roar(), "stun": stun(), "siren": siren(),
                "fire": fire()})
    return out


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    total = 0
    if "--phone" in sys.argv:
        # звуки ульты Главного (рингтон, речь из трубки, уведомление) — остальные не трогает
        S.seed(33)
        for name, fn in PHONE.items():
            y = fn()
            assert np.isfinite(y).all(), name
            y = signal.resample_poly(y, 22050, SR)
            pcm = (np.clip(y, -1, 1) * 32767).astype(np.int16)
            p = os.path.join(OUT, name + ".wav")
            wavfile.write(p, 22050, pcm)
            print(name, "%.2f s" % (len(y) / 22050))
        sys.exit(0)
    if "--almost" in sys.argv:
        # звуки Почти легенды (удары, рельсотрон, метеорит, Титан) — остальные не трогает
        S.seed(35)
        for name, fn in ALMOST.items():
            y = fn()
            assert np.isfinite(y).all(), name
            y = signal.resample_poly(y, 22050, SR)
            pcm = (np.clip(y, -1, 1) * 32767).astype(np.int16)
            wavfile.write(os.path.join(OUT, name + ".wav"), 22050, pcm)
            print(name, "%.2f s" % (len(y) / 22050))
        sys.exit(0)
    if "--dj" in sys.argv:
        # звуки DJ Климы (скретч, фонящий микрофон, дроп, пластинки, дубинки) — остальные не трогает
        S.seed(34)
        for name, fn in DJ.items():
            y = fn()
            assert np.isfinite(y).all(), name
            y = signal.resample_poly(y, 22050, SR)
            pcm = (np.clip(y, -1, 1) * 32767).astype(np.int16)
            wavfile.write(os.path.join(OUT, name + ".wav"), 22050, pcm)
            print(name, "%.2f s" % (len(y) / 22050))
        sys.exit(0)
    if "--intros" in sys.argv:
        # появление боссов — в полном качестве (44,1 кГц)
        S.seed(21)
        for name, fn in INTROS.items():
            y = fn()
            assert np.isfinite(y).all(), name
            y = norm(np.tanh(1.7 * y) / np.tanh(1.7), 0.9)      # чуть «плотнее» — громкость ровнее
            y = signal.resample_poly(y, 44100, SR)
            pcm = (np.clip(y, -1, 1) * 32767).astype(np.int16)
            p = os.path.join(OUT, name + ".wav")
            wavfile.write(p, 44100, pcm)
            total += os.path.getsize(p)
            print(name, "%.2f s" % (len(y) / 44100))
        print("intros:", total // 1024, "KB")
        sys.exit(0)
    for name, y in build().items():
        assert np.isfinite(y).all(), name
        y = signal.resample_poly(y, 22050, SR)         # звукам хватает 22,05 кГц, файлы меньше
        pcm = (np.clip(y, -1, 1) * 32767).astype(np.int16)
        p = os.path.join(OUT, name + ".wav")
        wavfile.write(p, 22050, pcm)
        total += os.path.getsize(p)
    print("sfx:", len(os.listdir(OUT)), "files,", total // 1024, "KB")
