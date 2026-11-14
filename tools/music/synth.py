"""Синтезатор для музыки и звуков Path of Legends.

Всё звучание игры собирается здесь из простых волн и шума: никаких чужих
сэмплов. Инструменты — функции, которые по частоте, длительности и силе
возвращают массив отсчётов (моно или стерео 2×N). Частота дискретизации — SR.
"""
import numpy as np
from scipy import signal

SR = 44100
_rng = np.random.default_rng(20261026)


def seed(n):
    global _rng
    _rng = np.random.default_rng(n)


def rng():
    return _rng


def midi_hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def secs(n):
    return np.arange(n) / SR


def noise(n):
    return _rng.uniform(-1.0, 1.0, n)


# ---------------------------------------------------------------- фильтры
def _sos(kind, fc, order=2):
    nyq = SR / 2.0
    if kind == "band":
        lo, hi = fc
        lo = max(20.0, min(lo, nyq * 0.95))
        hi = max(lo * 1.05, min(hi, nyq * 0.97))
        return signal.butter(order, [lo / nyq, hi / nyq], btype="band", output="sos")
    fc = max(20.0, min(fc, nyq * 0.97))
    return signal.butter(order, fc / nyq, btype=kind, output="sos")


def lp(x, fc, order=2):
    return signal.sosfilt(_sos("low", fc, order), x, axis=-1)


def hp(x, fc, order=2):
    return signal.sosfilt(_sos("high", fc, order), x, axis=-1)


def bp(x, lo, hi, order=2):
    return signal.sosfilt(_sos("band", (lo, hi), order), x, axis=-1)


def peak(x, fc, q, gain_db):
    """Пиковый эквалайзер (RBJ)."""
    a = 10 ** (gain_db / 40.0)
    w0 = 2 * np.pi * min(fc, SR * 0.45) / SR
    alpha = np.sin(w0) / (2 * q)
    b = np.array([1 + alpha * a, -2 * np.cos(w0), 1 - alpha * a])
    aa = np.array([1 + alpha / a, -2 * np.cos(w0), 1 - alpha / a])
    return signal.lfilter(b / aa[0], aa / aa[0], x, axis=-1)


# ---------------------------------------------------------------- огибающие
def adsr(n_gate, a, d, s, r):
    """Огибающая длиной n_gate + r: атака, спад (экспонентой), удержание, затухание."""
    n_gate = max(1, int(n_gate))
    na = max(1, int(a * SR))
    nd = max(1, int(d * SR))
    nr = max(1, int(r * SR))
    k = np.arange(n_gate, dtype=np.float64)
    g = np.empty(n_gate)
    att = k < na
    g[att] = (k[att] / na) ** 0.9
    rest = ~att
    g[rest] = s + (1.0 - s) * np.exp(-(k[rest] - na) / nd * 3.0)
    last = g[-1]
    rel = last * np.exp(-np.arange(nr) / nr * 6.0)
    return np.concatenate([g, rel])


def perc_env(n, decay, attack=0.002):
    t = secs(n)
    e = np.exp(-t / max(decay, 1e-4))
    na = max(1, int(attack * SR))
    e[:na] *= np.linspace(0.0, 1.0, na)
    return e


def fade_tail(x, ms=8):
    n = min(len(x), int(ms * SR / 1000))
    if n > 1:
        x[..., -n:] *= np.linspace(1.0, 0.0, n)
    return x


# ---------------------------------------------------------------- генераторы
def freq_track(f, n, vib_cents=0.0, vib_rate=5.5, vib_delay=0.25, scoop=0.0, scoop_t=0.05, drift=0.0):
    """Частота по отсчётам: вибрато (нарастает после задержки), подъезд к ноте, лёгкий дрейф."""
    t = secs(n)
    cents = np.zeros(n)
    if vib_cents:
        ramp = np.clip((t - vib_delay) / 0.35, 0.0, 1.0)
        cents += vib_cents * ramp * np.sin(2 * np.pi * vib_rate * t + _rng.uniform(0, 6.28))
    if scoop:
        cents += scoop * np.exp(-t / scoop_t)
    if drift:
        cents += drift * np.sin(2 * np.pi * 0.7 * t + _rng.uniform(0, 6.28))
    return f * 2.0 ** (cents / 1200.0)


def phase(freq):
    return np.cumsum(freq) / SR


def _blep(t, dt):
    y = np.zeros_like(t)
    m = t < dt
    x = t[m] / dt[m]
    y[m] = x + x - x * x - 1.0
    m = t > 1.0 - dt
    x = (t[m] - 1.0) / dt[m]
    y[m] = x * x + x + x + 1.0
    return y


def saw(freq, ph0=None):
    ph = phase(freq) + (_rng.uniform() if ph0 is None else ph0)
    t = ph % 1.0
    dt = np.minimum(freq / SR, 0.5)
    return 2.0 * t - 1.0 - _blep(t, dt)


def square(freq, pw=0.5, ph0=None):
    ph = phase(freq) + (_rng.uniform() if ph0 is None else ph0)
    t = ph % 1.0
    dt = np.minimum(freq / SR, 0.5)
    y = np.where(t < pw, 1.0, -1.0)
    y = y + _blep(t, dt) - _blep((t + 1.0 - pw) % 1.0, dt)
    return y


def sine(freq, ph0=0.0):
    return np.sin(2 * np.pi * (phase(freq) + ph0))


def tri(freq):
    ph = phase(freq) + _rng.uniform()
    t = ph % 1.0
    return 4.0 * np.abs(t - 0.5) - 1.0


def additive(f, n, partials, amps, decays, inharm=0.0, phases=None):
    """Сумма синусов с собственным затуханием у каждой гармоники."""
    t = secs(n)
    y = np.zeros(n)
    for i, (k, a, d) in enumerate(zip(partials, amps, decays)):
        fk = f * k * np.sqrt(1.0 + inharm * k * k)
        if fk >= SR * 0.45:
            continue
        p0 = 0.0 if phases is None else phases[i]
        y += a * np.sin(2 * np.pi * fk * t + p0) * np.exp(-t / d)
    return y


# ---------------------------------------------------------------- инструменты (мелодические)
# Каждый: (частота, длительность в секундах, сила 0..1) -> массив
def flute(f, dur, vel=0.8, breath=0.25, vib=14.0):
    n = int(dur * SR)
    e = adsr(n, 0.05, 0.12, 0.82, 0.14)
    N = len(e)
    fr = freq_track(f, N, vib_cents=vib, vib_rate=5.0, vib_delay=0.22, scoop=-25, scoop_t=0.03)
    ph = phase(fr)
    y = np.sin(2 * np.pi * ph) + 0.22 * np.sin(4 * np.pi * ph) + 0.07 * np.sin(6 * np.pi * ph) \
        + 0.03 * np.sin(8 * np.pi * ph)
    br = bp(noise(N), 1400, 5200) * (0.15 + 0.85 * np.exp(-secs(N) / 0.06))
    return (0.78 * y + breath * br) * e * vel


def whistle(f, dur, vel=0.8):
    """Высокая дудочка: почти чистый тон, лёгкое дыхание."""
    return flute(f, dur, vel, breath=0.15, vib=18.0)


def pluck(f, dur, vel=0.8, decay=1.4, bright=1.0, pos=0.22, ring=0.3, K=18, inharm=0.00008, body=True):
    """Щипок струны: гармоники гаснут тем быстрее, чем они выше."""
    n = int(min(dur + ring, decay * 4.0 + 0.05) * SR)
    ks = np.arange(1, K + 1)
    amps = np.abs(np.sin(np.pi * ks * pos)) / ks ** 1.05
    amps /= amps.max()
    decs = decay / (1.0 + 0.22 * (ks - 1) ** 1.25 / max(bright, 0.05))
    y = additive(f, n, ks, amps, decs, inharm=inharm, phases=_rng.uniform(0, 6.28, K))
    # щелчок пальца
    nc = int(0.006 * SR)
    y[:nc] += hp(noise(nc), 1500) * 0.35 * bright * np.linspace(1, 0, nc)
    # отпустили — струна глушится
    gate = int(dur * SR)
    if gate < n:
        rel = np.ones(n)
        k = np.arange(n - gate)
        rel[gate:] = np.exp(-k / max(1, int(ring * SR)) * 5.0)
        y *= rel
    if body:
        y = peak(y, 220, 1.2, 3.0)
    return fade_tail(y * vel * 0.8)


def harp(f, dur, vel=0.8):
    return pluck(f, dur, vel, decay=2.4, bright=0.9, pos=0.3, ring=1.6)


def guitar(f, dur, vel=0.8):
    return pluck(f, dur, vel, decay=1.3, bright=0.75, pos=0.18, ring=0.25)


def pizz(f, dur, vel=0.8):
    return pluck(f, dur, vel, decay=0.32, bright=0.55, pos=0.25, ring=0.12, K=12)


def koto(f, dur, vel=0.8):
    y = pluck(f, dur, vel, decay=1.6, bright=1.4, pos=0.12, ring=0.8, inharm=0.0003)
    return y


def marimba(f, dur, vel=0.8):
    n = int(min(dur + 0.6, 1.4) * SR)
    sc = max(0.35, min(1.4, 300.0 / f))
    y = additive(f, n, [1.0, 3.93, 9.2], [1.0, 0.3, 0.08], [0.55 * sc, 0.12 * sc, 0.04])
    nc = int(0.008 * SR)
    y[:nc] += lp(noise(nc), 3000) * 0.3 * np.linspace(1, 0, nc)
    return fade_tail(y * vel * 0.85)


def xylo(f, dur, vel=0.8):
    n = int(0.9 * SR)
    sc = max(0.3, min(1.2, 400.0 / f))
    y = additive(f, n, [1.0, 3.0, 6.1, 10.2], [1.0, 0.45, 0.15, 0.06], [0.28 * sc, 0.09, 0.04, 0.02])
    nc = int(0.004 * SR)
    y[:nc] += hp(noise(nc), 2500) * 0.5 * np.linspace(1, 0, nc)
    return fade_tail(y * vel * 0.8)


def kalimba(f, dur, vel=0.8):
    n = int(1.6 * SR)
    y = additive(f, n, [1.0, 5.93, 11.3], [1.0, 0.22, 0.07], [0.9, 0.12, 0.05])
    return fade_tail(y * vel * 0.85)


def fm(f, n, ratio, index, idx_decay, amp_decay, attack=0.002):
    t = secs(n)
    mod = index * np.exp(-t / idx_decay) * np.sin(2 * np.pi * f * ratio * t)
    y = np.sin(2 * np.pi * f * t + mod) * np.exp(-t / amp_decay)
    na = max(1, int(attack * SR))
    y[:na] *= np.linspace(0, 1, na)
    return y


def bell(f, dur, vel=0.8):
    n = int(min(dur + 2.0, 3.0) * SR)
    y = fm(f, n, 3.5, 2.4, 0.5, 1.4) * 0.7 + fm(f * 2.0, n, 1.41, 1.0, 0.3, 0.7) * 0.3
    return fade_tail(y * vel * 0.6)


def celesta(f, dur, vel=0.8):
    n = int(min(dur + 1.2, 2.0) * SR)
    y = fm(f, n, 4.0, 1.2, 0.08, 0.7) * 0.8 + 0.2 * fm(f * 2, n, 1.0, 0.3, 0.1, 0.4)
    return fade_tail(y * vel * 0.65)


def musicbox(f, dur, vel=0.8):
    n = int(1.6 * SR)
    y = additive(f, n, [1.0, 2.0, 4.97, 7.6], [1.0, 0.3, 0.25, 0.08], [0.8, 0.4, 0.09, 0.04])
    nc = int(0.003 * SR)
    y[:nc] += hp(noise(nc), 4000) * 0.4
    return fade_tail(y * vel * 0.7)


def glass(f, dur, vel=0.8):
    """Стеклянный звон для кристальных пещер."""
    n = int(min(dur + 1.5, 2.6) * SR)
    y = additive(f, n, [1.0, 2.32, 4.25, 6.63], [1.0, 0.5, 0.3, 0.12], [1.2, 0.6, 0.3, 0.15])
    e = np.ones(n)
    na = int(0.01 * SR)
    e[:na] = np.linspace(0, 1, na)
    return fade_tail(y * e * vel * 0.55)


def epiano(f, dur, vel=0.8):
    n = int((dur + 0.5) * SR)
    y = fm(f, n, 1.0, 1.6 * vel, 0.35, 1.6) + 0.15 * fm(f, n, 14.0, 0.8, 0.02, 0.1)
    rel = np.ones(n)
    g = int(dur * SR)
    rel[g:] = np.exp(-np.arange(n - g) / (0.08 * SR))
    return fade_tail(y * rel * vel * 0.6)


def organ(f, dur, vel=0.8, reg=(0.6, 1.0, 0.7, 0.4, 0.3, 0.15, 0.1)):
    n = int(dur * SR)
    e = adsr(n, 0.012, 0.05, 0.95, 0.09)
    N = len(e)
    t = secs(N)
    hs = [0.5, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0]
    y = np.zeros(N)
    for h, a in zip(hs, reg):
        if f * h < SR * 0.45:
            y += a * np.sin(2 * np.pi * f * h * t + _rng.uniform(0, 6.28))
    y *= 1.0 + 0.06 * np.sin(2 * np.pi * 6.2 * t)
    nc = int(0.004 * SR)
    y[:nc] += noise(nc) * 0.2
    return y * e * vel * 0.32


def chip(f, dur, vel=0.8, pw=0.25):
    n = int(dur * SR)
    e = adsr(n, 0.004, 0.12, 0.6, 0.05)
    N = len(e)
    fr = freq_track(f, N, vib_cents=12, vib_rate=6.0, vib_delay=0.18)
    y = square(fr, pw)
    y = lp(y, min(9000, f * 10))
    return y * e * vel * 0.3


def saw_lead(f, dur, vel=0.8, cutoff=6.0, vib=10.0):
    n = int(dur * SR)
    e = adsr(n, 0.01, 0.2, 0.7, 0.12)
    N = len(e)
    fr = freq_track(f, N, vib_cents=vib, vib_rate=5.6, vib_delay=0.2)
    y = 0.6 * saw(fr) + 0.4 * saw(fr * 1.004)
    y = lp(y, min(9000, f * cutoff))
    return y * e * vel * 0.32


def fiddle(f, dur, vel=0.8):
    n = int(dur * SR)
    e = adsr(n, 0.06, 0.15, 0.85, 0.12)
    N = len(e)
    fr = freq_track(f, N, vib_cents=22, vib_rate=6.0, vib_delay=0.15, scoop=-30, scoop_t=0.04)
    y = saw(fr)
    y = peak(y, 300, 1.4, 6.0)
    y = peak(y, 1050, 1.6, 5.0)
    y = peak(y, 2800, 1.8, 4.0)
    y = lp(y, 6500)
    bow = bp(noise(N), 2000, 7000) * 0.06
    return (y * 0.22 + bow) * e * vel


def accordion(f, dur, vel=0.8):
    n = int(dur * SR)
    e = adsr(n, 0.03, 0.1, 0.9, 0.08)
    N = len(e)
    y = square(np.full(N, f), 0.32) + square(np.full(N, f * 1.0045), 0.32) + 0.5 * square(np.full(N, f * 2.0), 0.4)
    y = bp(y, f * 0.8, min(6000, f * 9))
    y *= 1.0 + 0.08 * np.sin(2 * np.pi * 5.0 * secs(N))
    return y * e * vel * 0.22


def brass(f, dur, vel=0.8, dark=2.4, bright=9.0, att=0.05):
    n = int(dur * SR)
    e = adsr(n, att, 0.25, 0.78, 0.16)
    N = len(e)
    fr = freq_track(f, N, vib_cents=9, vib_rate=5.2, vib_delay=0.3, scoop=-35, scoop_t=0.06)
    y = 0.55 * saw(fr) + 0.45 * saw(fr * 1.003)
    yd = lp(y, min(8000, f * dark))
    yb = lp(y, min(11000, f * bright * (0.6 + 0.6 * vel)))
    t = secs(N)
    b = (1.0 - np.exp(-t / 0.07)) * (0.55 + 0.45 * np.exp(-t / 0.4))
    out = yd * (1 - b) + yb * b
    return out * e * vel * 0.32


def horn(f, dur, vel=0.8):
    return brass(f, dur, vel, dark=1.6, bright=4.5, att=0.08)


def tuba(f, dur, vel=0.8):
    return brass(f, dur, vel, dark=1.5, bright=3.2, att=0.03) * 1.3


def choir(f, dur, vel=0.8, vowel="a"):
    n = int(dur * SR)
    e = adsr(n, 0.28, 0.3, 0.9, 0.55)
    N = len(e)
    y = np.zeros(N)
    for dc in (-9.0, 0.0, 8.0, 15.0):
        fr = freq_track(f * 2 ** (dc / 1200), N, vib_cents=14, vib_rate=4.6 + _rng.uniform(-0.4, 0.4), vib_delay=0.1)
        y += saw(fr)
    forms = {"a": [(760, 1.0), (1150, 0.55), (2650, 0.3)], "o": [(460, 1.0), (820, 0.6), (2550, 0.18)],
             "u": [(340, 1.0), (720, 0.4), (2450, 0.08)]}[vowel]
    out = lp(y, 900) * 0.12
    for fc, g in forms:
        out += bp(y, fc * 0.86, fc * 1.16) * g
    out = lp(out, 4500)
    return out * e * vel * 0.16


def strings(f, dur, vel=0.8, att=0.22, bright=5.0):
    """Струнная группа: несколько расстроенных пил, вибрато, мягкая атака. Стерео."""
    n = int(dur * SR)
    e = adsr(n, att, 0.3, 0.88, 0.4)
    N = len(e)
    out = np.zeros((2, N))
    for i, dc in enumerate((-11.0, -4.0, 4.0, 11.0)):
        fr = freq_track(f * 2 ** (dc / 1200), N, vib_cents=10, vib_rate=5.4 + _rng.uniform(-0.5, 0.5), vib_delay=0.2)
        v = saw(fr)
        out[i % 2] += v
    out = lp(out, min(9000, f * bright))
    out = peak(out, 900, 0.8, 2.0)
    return out * e * vel * 0.12


def stacc(f, dur, vel=0.8):
    """Короткие струнные (остинато)."""
    d = min(dur, 0.22)
    return strings(f, d, vel, att=0.008, bright=7.0) * 1.3


def pad(f, dur, vel=0.8, bright=3.5, att=0.6):
    n = int(dur * SR)
    e = adsr(n, att, 0.5, 0.85, 1.2)
    N = len(e)
    out = np.zeros((2, N))
    for i, dc in enumerate((-14.0, -6.0, 0.0, 7.0, 13.0)):
        fr = freq_track(f * 2 ** (dc / 1200), N, drift=4.0)
        out[i % 2] += saw(fr) * (0.8 if i == 2 else 1.0)
    out = lp(out, min(6000, f * bright), order=2)
    return out * e * vel * 0.09


def warm_pad(f, dur, vel=0.8):
    return pad(f, dur, vel, bright=2.2, att=0.9)


def glass_pad(f, dur, vel=0.8):
    n = int(dur * SR)
    e = adsr(n, 0.8, 0.5, 0.9, 1.4)
    N = len(e)
    t = secs(N)
    out = np.zeros((2, N))
    for i, (h, a) in enumerate([(1.0, 1.0), (2.0, 0.35), (3.0, 0.2), (4.0, 0.12), (6.0, 0.06)]):
        for ch in (0, 1):
            fr = f * h * (1.0 + (0.0012 if ch else -0.0012) * (i + 1))
            out[ch] += a * np.sin(2 * np.pi * fr * t + _rng.uniform(0, 6.28))
    out *= 1.0 + 0.15 * np.sin(2 * np.pi * 0.35 * t)
    return out * e * vel * 0.12


# ---------------------------------------------------------------- басы
def bass_pluck(f, dur, vel=0.8):
    y = pluck(f, dur, vel, decay=0.9, bright=0.45, pos=0.3, ring=0.1, K=10, body=False)
    n = len(y)
    y += 0.5 * np.sin(2 * np.pi * f * secs(n)) * np.exp(-secs(n) / 0.6) * vel
    return y


def bass_saw(f, dur, vel=0.8):
    n = int(dur * SR)
    e = adsr(n, 0.004, 0.25, 0.6, 0.06)
    N = len(e)
    y = saw(np.full(N, f)) + 0.6 * np.sin(2 * np.pi * f * secs(N))
    t = secs(N)
    b = np.exp(-t / 0.12)
    y = lp(y, f * 2.0) * (1 - b) + lp(y, min(5000, f * 9)) * b
    return y * e * vel * 0.5


def bass_sub(f, dur, vel=0.8):
    n = int(dur * SR)
    e = adsr(n, 0.008, 0.3, 0.85, 0.08)
    N = len(e)
    t = secs(N)
    y = np.sin(2 * np.pi * f * t) + 0.2 * np.sin(4 * np.pi * f * t)
    return np.tanh(1.5 * y) * e * vel * 0.55


def bass_dist(f, dur, vel=0.8):
    n = int(dur * SR)
    e = adsr(n, 0.003, 0.2, 0.75, 0.05)
    N = len(e)
    y = saw(np.full(N, f)) + 0.7 * square(np.full(N, f * 0.5), 0.5)
    y = np.tanh(3.5 * y)
    y = lp(y, 1600)
    return y * e * vel * 0.32


def bass_upright(f, dur, vel=0.8):
    y = pluck(f, dur, vel, decay=0.7, bright=0.35, pos=0.35, ring=0.08, K=8, body=False)
    n = len(y)
    y += 0.6 * np.sin(2 * np.pi * f * secs(n)) * np.exp(-secs(n) / 0.45) * vel
    return y * 1.1


def bass_tuba(f, dur, vel=0.8):
    return tuba(f, dur, vel)


# ---------------------------------------------------------------- ударные (одиночные удары)
def kick(vel=1.0, tone=1.0, decay=0.35):
    n = int(0.5 * SR)
    t = secs(n)
    fr = 45.0 * tone + 110.0 * tone * np.exp(-t / 0.035)
    y = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / decay)
    nc = int(0.004 * SR)
    y[:nc] += lp(noise(nc), 4000) * 0.6
    return np.tanh(1.4 * y) * vel * 0.9


def snare(vel=1.0, tone=1.0, snappy=1.0):
    n = int(0.35 * SR)
    t = secs(n)
    body = np.sin(2 * np.pi * 185.0 * tone * t) * np.exp(-t / 0.05) * 0.6
    nz = bp(noise(n), 1200, 9000) * np.exp(-t / (0.11 * snappy))
    return (body + nz * 0.9) * vel * 0.7


def clap(vel=1.0):
    n = int(0.3 * SR)
    y = np.zeros(n)
    nz = bp(noise(n), 900, 5000)
    for k, off in enumerate((0, 0.009, 0.019, 0.03)):
        i = int(off * SR)
        dec = 0.012 if k < 3 else 0.12
        y[i:] += nz[i:] * np.exp(-secs(n - i) / dec)
    return y * vel * 0.6


def hat(vel=1.0, open_=False):
    n = int((0.35 if open_ else 0.06) * SR)
    t = secs(n)
    y = hp(noise(n), 7000, order=2)
    # металлический призвук
    for fr in (5400, 7800, 10300):
        y += 0.15 * np.sign(np.sin(2 * np.pi * fr * t))
    y = hp(y, 6000)
    return y * np.exp(-t / (0.12 if open_ else 0.018)) * vel * 0.32


def shaker(vel=1.0):
    n = int(0.09 * SR)
    t = secs(n)
    e = np.sin(np.pi * np.clip(t / 0.08, 0, 1)) ** 2
    return bp(noise(n), 4000, 11000) * e * vel * 0.25


def tamb(vel=1.0):
    n = int(0.25 * SR)
    t = secs(n)
    y = hp(noise(n), 6000) * np.exp(-t / 0.07) * 0.5
    for fr in (6100, 7400, 8900, 9700):
        y += 0.12 * np.sin(2 * np.pi * fr * t + _rng.uniform(0, 6)) * np.exp(-t / 0.12)
    return y * vel * 0.4


def tom(f=110.0, vel=1.0, decay=0.3):
    n = int(0.6 * SR)
    t = secs(n)
    fr = f * (1.0 + 0.6 * np.exp(-t / 0.05))
    y = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / decay)
    y += lp(noise(n), 2500) * np.exp(-t / 0.03) * 0.25
    return y * vel * 0.75


def taiko(vel=1.0, f=62.0):
    n = int(1.0 * SR)
    t = secs(n)
    fr = f * (1.0 + 0.9 * np.exp(-t / 0.04))
    y = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / 0.45)
    y += lp(noise(n), 900) * np.exp(-t / 0.06) * 0.7
    y += bp(noise(n), 200, 2000) * np.exp(-t / 0.015) * 0.4
    return np.tanh(1.3 * y) * vel * 0.85


def timpani(f=65.0, vel=1.0):
    n = int(1.6 * SR)
    t = secs(n)
    y = additive(f, n, [1.0, 1.5, 1.98, 2.44], [1.0, 0.5, 0.35, 0.2], [0.9, 0.5, 0.35, 0.25])
    y *= 1.0 + 0.0 * t
    y += lp(noise(n), 1200) * np.exp(-t / 0.04) * 0.5
    return y * vel * 0.7


def crash(vel=1.0, decay=1.6):
    n = int(decay * 1.8 * SR)
    t = secs(n)
    y = hp(noise(n), 3500) * np.exp(-t / decay) * 0.6
    for fr in (3150, 4280, 5320, 6990, 8100):
        y += 0.08 * np.sin(2 * np.pi * fr * t + _rng.uniform(0, 6)) * np.exp(-t / (decay * 0.8))
    na = int(0.003 * SR)
    y[:na] *= np.linspace(0, 1, na)
    return y * vel * 0.4


def ride(vel=1.0):
    n = int(0.8 * SR)
    t = secs(n)
    y = hp(noise(n), 5000) * np.exp(-t / 0.25) * 0.25
    for fr in (3900, 5100, 6400):
        y += 0.1 * np.sin(2 * np.pi * fr * t) * np.exp(-t / 0.5)
    return y * vel * 0.35


def woodblock(vel=1.0, f=900.0):
    n = int(0.12 * SR)
    t = secs(n)
    y = np.sin(2 * np.pi * f * t) * np.exp(-t / 0.025) + 0.4 * np.sin(2 * np.pi * f * 2.7 * t) * np.exp(-t / 0.01)
    return y * vel * 0.45


def conga(f=200.0, vel=1.0):
    n = int(0.4 * SR)
    t = secs(n)
    fr = f * (1.0 + 0.25 * np.exp(-t / 0.02))
    y = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / 0.16)
    y += bp(noise(n), 800, 4000) * np.exp(-t / 0.01) * 0.4
    return y * vel * 0.6


def frame_drum(vel=1.0):
    n = int(0.5 * SR)
    t = secs(n)
    y = np.sin(2 * np.pi * 95 * t * (1 + 0.2 * np.exp(-t / 0.03))) * np.exp(-t / 0.2)
    y += bp(noise(n), 300, 3000) * np.exp(-t / 0.05) * 0.5
    return y * vel * 0.6


def anvil(vel=1.0):
    n = int(1.2 * SR)
    y = additive(1.0, n, [1250, 2610, 3980, 5250], [1.0, 0.6, 0.4, 0.25], [0.5, 0.3, 0.2, 0.15])
    nc = int(0.003 * SR)
    y[:nc] += noise(nc)
    return y * vel * 0.3


def sleigh(vel=1.0):
    n = int(0.3 * SR)
    t = secs(n)
    y = np.zeros(n)
    for k in range(4):
        i = int(_rng.uniform(0, 0.03) * SR)
        for fr in (5200, 6600, 8300):
            y[i:] += np.sin(2 * np.pi * fr * _rng.uniform(0.97, 1.03) * t[: n - i]) * np.exp(-t[: n - i] / 0.06)
    return hp(y, 4000) * vel * 0.12


def alarm_bell(vel=1.0, f=330.0):
    """Набатный колокол: гул, основной тон, малая терция, квинта, октава."""
    n = int(3.0 * SR)
    y = additive(f, n, [0.5, 1.0, 1.2, 1.5, 2.0, 2.52, 3.0], [0.5, 1.0, 0.6, 0.4, 0.5, 0.25, 0.2],
                 [2.4, 1.6, 1.1, 0.9, 0.8, 0.5, 0.4])
    nc = int(0.004 * SR)
    y[:nc] += noise(nc) * 0.5
    return y * vel * 0.25


def gong(vel=1.0):
    n = int(4.0 * SR)
    t = secs(n)
    y = additive(68.0, n, [1.0, 1.52, 2.03, 2.71, 3.4, 4.6], [1.0, 0.7, 0.6, 0.4, 0.3, 0.2], [2.5, 2.0, 1.6, 1.2, 1.0, 0.7])
    y *= 1.0 - np.exp(-t / 0.05)
    return y * vel * 0.35


def braam(f, dur, vel=1.0):
    """Низкий кинематографический удар: медь + саб."""
    y = brass(f, dur, vel, dark=2.0, bright=5.0, att=0.02) * 1.6
    n = len(y)
    t = secs(n)
    y += 0.5 * np.sin(2 * np.pi * f * 0.5 * t) * np.exp(-t / 1.2) * vel
    return np.tanh(1.3 * y)


# ---------------------------------------------------------------- атмосфера
def wind(n, strength=1.0, lo=200, hi=1400):
    y = bp(noise(n), lo, hi, order=1)
    t = secs(n)
    sw = 0.55 + 0.45 * np.sin(2 * np.pi * t / 7.3 + 1.0) * np.sin(2 * np.pi * t / 3.1)
    return y * sw * strength * 0.35


def crackle(n, density=30.0):
    y = np.zeros(n)
    count = int(n / SR * density)
    for _ in range(count):
        i = int(_rng.uniform(0, n - 400))
        L = int(_rng.uniform(40, 300))
        y[i:i + L] += noise(L) * np.exp(-np.arange(L) / (L / 4)) * _rng.uniform(0.2, 1.0)
    return hp(y, 1500) * 0.3


def thunder(vel=1.0):
    n = int(3.5 * SR)
    t = secs(n)
    y = lp(noise(n), 400, order=2) * (np.exp(-t / 1.0) * (1 - np.exp(-t / 0.08)))
    y += lp(noise(n), 1600) * np.exp(-t / 0.15) * 0.6
    return y * vel * 1.4


def bird(vel=1.0):
    n = int(0.35 * SR)
    t = secs(n)
    f0 = _rng.uniform(2600, 4200)
    fr = f0 * (1.0 + 0.25 * np.sin(2 * np.pi * _rng.uniform(9, 16) * t)) * (1.0 + 0.3 * t)
    e = np.sin(np.pi * np.clip(t / 0.3, 0, 1)) ** 2
    return np.sin(2 * np.pi * np.cumsum(fr) / SR) * e * vel * 0.08


def cricket(vel=1.0):
    n = int(0.25 * SR)
    t = secs(n)
    gate = (np.sin(2 * np.pi * 32 * t) > 0.3).astype(float)
    y = np.sin(2 * np.pi * 4300 * t) * gate * np.sin(np.pi * t / 0.25)
    return y * vel * 0.05


def drip(vel=1.0):
    n = int(0.25 * SR)
    t = secs(n)
    f0 = _rng.uniform(900, 1700)
    fr = f0 * (1.0 + 1.2 * (1 - np.exp(-t / 0.02)))
    return np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.exp(-t / 0.05) * vel * 0.25


def frog(vel=1.0):
    n = int(0.3 * SR)
    t = secs(n)
    f0 = _rng.uniform(140, 220)
    y = saw(np.full(n, f0)) * (np.sin(2 * np.pi * 28 * t) > 0).astype(float)
    y = bp(y, 300, 1500) * np.sin(np.pi * t / 0.3)
    return y * vel * 0.15


def crowd(n, strength=1.0):
    y = bp(noise(n), 300, 2500, order=1)
    y += 0.5 * bp(noise(n), 900, 3500, order=1)
    t = secs(n)
    return y * (0.6 + 0.4 * np.sin(2 * np.pi * t / 5.0)) * strength * 0.25


# ---------------------------------------------------------------- эффекты
def make_ir(seconds=2.2, damp=0.5, predelay=0.012, width=1.0, seed_=7):
    r = np.random.default_rng(seed_)
    n = int(seconds * SR)
    t = secs(n)
    out = np.zeros((2, n))
    for ch in (0, 1):
        nz = r.uniform(-1, 1, n)
        bright = nz * np.exp(-t / (seconds * 0.12))
        dark = lp(nz, 2500 * (1.0 - damp) + 500) * np.exp(-t / (seconds * 0.22))
        out[ch] = bright * 0.35 + dark
    # ранние отражения
    for k in range(8):
        i = int((predelay + r.uniform(0.005, 0.06)) * SR)
        out[k % 2, i] += r.uniform(0.3, 0.8)
    pd = int(predelay * SR)
    out = np.concatenate([np.zeros((2, pd)), out[:, : n - pd]], axis=1)
    mid = out.mean(axis=0, keepdims=True)
    out = mid + (out - mid) * width
    out /= np.sqrt((out ** 2).sum() / 2.0) + 1e-9
    return out


def circ_conv(x, ir):
    """Свёртка по кругу: хвост реверберации переходит в начало петли — шва нет."""
    L = x.shape[-1]
    out = np.zeros_like(x)
    for ch in range(2):
        y = signal.fftconvolve(x[ch], ir[ch])
        out[ch] += y[:L]
        tail = y[L:]
        while len(tail) > 0:
            k = min(L, len(tail))
            out[ch, :k] += tail[:k]
            tail = tail[k:]
    return out


def lin_conv(x, ir):
    out = np.zeros((2, x.shape[-1] + ir.shape[-1] - 1))
    for ch in range(2):
        out[ch] = signal.fftconvolve(x[ch], ir[ch])
    return out


def pingpong(x, delay_s, fb=0.35, taps=5, tone=3500, circular=True):
    d = int(delay_s * SR)
    L = x.shape[-1]
    wet = np.zeros_like(x)
    src = lp(x, tone)
    g = 1.0
    for k in range(1, taps + 1):
        g *= fb
        sh = d * k
        tap = np.roll(src, sh, axis=-1) if circular else np.pad(src, ((0, 0), (sh, 0)))[:, :L]
        if k % 2 == 1:
            tap = tap[::-1]          # каналы меняются местами — эхо «прыгает»
        wet += tap * g
    return wet


def pan2(x, pan):
    """Моно -> стерео с постоянной мощностью; pan от -1 (лево) до 1 (право)."""
    a = (pan + 1.0) * np.pi / 4.0
    if x.ndim == 1:
        return np.stack([x * np.cos(a), x * np.sin(a)])
    m = np.array([[np.cos(a) * 1.414], [np.sin(a) * 1.414]])
    return x * m
