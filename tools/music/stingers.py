"""Короткие музыкальные вставки: волна пройдена, босс повержен, победа, поражение, раунд."""
import numpy as np
import synth as S


class Lin:
    def __init__(self, seconds):
        self.n = int(seconds * S.SR)
        self.dry = np.zeros((2, self.n))
        self.rev = np.zeros((2, self.n))

    def add(self, x, t, pan=0.0, rev=0.3, gain=1.0):
        st = S.pan2(np.asarray(x) * gain, pan)
        i = int(t * S.SR)
        k = min(st.shape[1], self.n - i)
        if k <= 0:
            return
        self.dry[:, i:i + k] += st[:, :k]
        self.rev[:, i:i + k] += st[:, :k] * rev

    def note(self, inst, midi, t, dur, vel=0.8, pan=0.0, rev=0.3, gain=1.0):
        self.add(inst(S.midi_hz(midi), dur, vel), t, pan, rev, gain)

    def chord(self, inst, midis, t, dur, vel=0.8, rev=0.35, gain=1.0, spread=0.3):
        for j, m in enumerate(midis):
            self.note(inst, m, t + j * 0.008, dur, vel, (j / max(1, len(midis) - 1) - 0.5) * 2 * spread, rev, gain / len(midis) * 2)

    def done(self, ir_s=2.0, peak=0.8):
        ir = S.make_ir(ir_s, 0.5)
        y = self.dry + S.lin_conv(self.rev, ir)[:, : self.n] * 0.5
        y = S.hp(y, 30)
        y *= peak / (np.abs(y).max() + 1e-9)
        tail = int(0.3 * S.SR)
        y[:, -tail:] *= np.linspace(1, 0, tail)
        return y


def wave_clear():
    s = Lin(2.6)
    for k, m in enumerate([72, 76, 79, 84]):
        s.note(S.celesta, m, k * 0.09, 0.3, 0.8, (k - 1.5) * 0.2, 0.4)
    s.chord(S.brass, [60, 64, 67, 72], 0.36, 1.0, 0.8, gain=0.9)
    s.add(S.crash(0.5, 1.2), 0.36, 0.2, 0.2, 0.5)
    s.add(S.timpani(65, 0.8), 0.36, -0.2, 0.3, 0.8)
    return s.done()


def boss_down():
    s = Lin(4.6)
    s.add(S.taiko(1.0), 0.0, 0.0, 0.3, 0.9)
    s.add(S.gong(0.9), 0.0, 0.0, 0.3, 0.7)
    for k, (m, d) in enumerate([(67, 0.22), (67, 0.22), (67, 0.22), (72, 1.2)]):
        s.note(S.brass, m, 0.35 + k * 0.24, d, 0.9, 0.0, 0.35, 1.2)
    s.chord(S.brass, [48, 55, 60, 64], 1.07, 1.8, 0.85, gain=0.9)
    s.chord(S.choir, [60, 64, 67, 72], 1.07, 2.2, 0.9, gain=1.0)
    s.chord(S.strings, [72, 76, 79, 84], 1.07, 2.0, 0.7, gain=0.6)
    s.add(S.crash(0.9, 2.2), 1.07, -0.2, 0.25, 0.8)
    for k in range(10):
        s.add(S.timpani(65, 0.4 + 0.05 * k), 0.35 + k * 0.07, -0.25, 0.3, 0.5)
    return s.done(2.6)


def victory():
    s = Lin(7.0)
    mel = [(67, 0.0, 0.3), (72, 0.32, 0.3), (76, 0.64, 0.3), (79, 0.96, 0.9), (76, 1.92, 0.3), (79, 2.24, 1.6)]
    for (m, t, d) in mel:
        s.note(S.brass, m, t, d, 0.9, 0.0, 0.35, 1.1)
        s.note(S.flute, m + 12, t, d, 0.6, 0.3, 0.4, 0.4)
    for (ch, t, d) in [([48, 55, 60, 64], 0.0, 0.9), ([53, 57, 60, 65], 0.96, 0.9), ([55, 59, 62, 67], 1.92, 0.3),
                       ([48, 55, 60, 64, 67], 2.24, 3.5)]:
        s.chord(S.strings, [m + 12 for m in ch], t, d, 0.75, gain=0.6)
        s.chord(S.choir, ch, t, d, 0.8, gain=0.7)
        s.note(S.bass_upright, ch[0] - 12, t, d, 0.9, 0.0, 0.05, 0.9)
    for t in (0.0, 0.96, 2.24):
        s.add(S.crash(0.8, 2.0), t, 0.3, 0.2, 0.6)
        s.add(S.timpani(65, 0.9), t, -0.2, 0.3, 0.8)
    for k in range(12):
        s.note(S.celesta, [72, 76, 79, 84][k % 4] + 12, 2.3 + k * 0.08, 0.2, 0.5, (k % 2) * 0.6 - 0.3, 0.5, 0.5)
    return s.done(2.6)


def defeat():
    s = Lin(5.0)
    for (m, t, d) in [(69, 0.0, 0.6), (67, 0.6, 0.6), (65, 1.2, 0.6), (64, 1.8, 2.4)]:
        s.note(S.horn, m - 12, t, d, 0.75, 0.0, 0.4, 1.0)
    for (ch, t, d) in [([57, 60, 64], 0.0, 1.2), ([53, 57, 62], 1.2, 0.6), ([52, 56, 59, 64], 1.8, 2.8)]:
        s.chord(S.strings, ch, t, d, 0.7, gain=0.7)
        s.note(S.bass_upright, ch[0] - 12, t, d, 0.8, 0.0, 0.05, 0.8)
    s.add(S.timpani(55, 0.7), 1.8, 0.0, 0.4, 0.8)
    return s.done(3.0, 0.7)


def round_won():
    s = Lin(3.0)
    for k, m in enumerate([67, 71, 74]):
        s.note(S.brass, m, k * 0.13, 0.15, 0.85, 0.0, 0.3, 1.0)
    s.chord(S.brass, [55, 62, 67, 71, 79], 0.42, 1.3, 0.9, gain=0.9)
    s.chord(S.strings, [67, 71, 74, 79], 0.42, 1.5, 0.7, gain=0.5)
    s.add(S.crash(0.7, 1.6), 0.42, 0.3, 0.2, 0.6)
    s.add(S.kick(0.9), 0.42, 0.0, 0.1, 0.8)
    return s.done()


def unlock():
    s = Lin(3.2)
    for k, m in enumerate([72, 76, 79, 83, 84, 88, 91, 96]):
        s.note(S.celesta, m, k * 0.07, 0.4, 0.7, (k % 2) * 0.6 - 0.3, 0.5, 0.7)
    s.chord(S.glass_pad, [60, 64, 67, 71, 76], 0.5, 2.0, 0.8, gain=1.0)
    s.chord(S.choir, [60, 64, 67, 72], 0.5, 2.0, 0.7, gain=0.6)
    return s.done(3.0, 0.75)


def all_stingers():
    S.seed(5)
    return {"wave_clear": wave_clear(), "boss_down": boss_down(), "victory": victory(), "defeat": defeat(),
            "round_won": round_won(), "unlock": unlock()}
