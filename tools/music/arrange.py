"""Раскладка трека по слоям: что играет в base, battle и boss."""
import numpy as np
import synth as S
import comp as C

INST = {
    "flute": S.flute, "whistle": S.whistle, "harp": S.harp, "guitar": S.guitar, "pizz": S.pizz, "koto": S.koto,
    "marimba": S.marimba, "xylo": S.xylo, "kalimba": S.kalimba, "bell": S.bell, "celesta": S.celesta,
    "musicbox": S.musicbox, "glass": S.glass, "epiano": S.epiano, "organ": S.organ, "chip": S.chip,
    "saw_lead": S.saw_lead, "fiddle": S.fiddle, "accordion": S.accordion, "brass": S.brass, "horn": S.horn,
    "tuba": S.tuba, "choir": S.choir, "choir_o": lambda f, d, v=0.8: S.choir(f, d, v, "o"),
    "choir_u": lambda f, d, v=0.8: S.choir(f, d, v, "u"), "strings": S.strings, "stacc": S.stacc, "pad": S.pad,
    "warm_pad": S.warm_pad, "glass_pad": S.glass_pad, "bass_pluck": S.bass_pluck, "bass_saw": S.bass_saw,
    "bass_sub": S.bass_sub, "bass_dist": S.bass_dist, "bass_upright": S.bass_upright, "bass_tuba": S.bass_tuba,
    "dark_lead": lambda f, d, v=0.8: S.saw_lead(f, d, v, cutoff=3.0, vib=16.0),
    "lead_soft": lambda f, d, v=0.8: S.saw_lead(f, d, v, cutoff=4.0, vib=12.0),
}

# Выравнивание громкости инструментов: каждый приводится к одной громкости
# (протяжные — по первой секунде, щипковые и ударные — по первым 0,3 с)
SUSTAINED = {"flute", "whistle", "organ", "chip", "saw_lead", "fiddle", "accordion", "brass", "horn", "tuba", "choir",
             "choir_o", "choir_u", "strings", "pad", "warm_pad", "glass_pad", "bass_sub", "bass_saw", "bass_dist",
             "bass_tuba", "dark_lead", "lead_soft"}


def _calibrate():
    norm = {}
    for k, fn in INST.items():
        S.seed(12345)
        low = k.startswith("bass") or k == "tuba"
        mid = k in ("horn", "brass", "choir", "choir_o", "choir_u", "strings", "pad", "warm_pad", "glass_pad",
                    "organ", "stacc", "accordion")
        m = 45 if low else (57 if mid else 69)
        x = np.asarray(fn(S.midi_hz(m), 1.0, 0.8))
        win = int((1.0 if k in SUSTAINED else 0.3) * S.SR)
        x = x[..., :win]
        r = np.sqrt(np.mean(x ** 2)) * (np.sqrt(2) if x.ndim == 2 else 1.0)
        norm[k] = 0.2 / max(r, 1e-6)
    return norm


NORM = _calibrate()
RAW = dict(INST)
INST = {k: (lambda fn, g: (lambda f, d, v=0.8, **kw: fn(f, d, v, **kw) * g))(fn, NORM[k]) for k, fn in RAW.items()}

# уровни партий по умолчанию (поверх них — spec["mix"])
GAIN = {"lead": 1.0, "lead2": 0.5, "pad": 0.45, "bass": 1.15, "arp": 0.5, "comp": 0.42, "perc": 0.7,
        "drums": 0.6, "bass2": 0.5, "ost": 0.42, "boss_lead": 0.85, "counter": 0.55, "boss_drums": 0.4,
        "braam": 0.7, "choir_pad": 0.45, "bells": 0.5}


def g(spec, k):
    return GAIN[k] * spec.get("mix", {}).get(k, 1.0)


def build(spec):
    song = C.Song(spec)
    B = song.beats
    sd = spec.get("seed", 1)
    lo, hi = spec["lead_range"]
    style = spec.get("style", "lively")
    na = 8
    nb = len(spec["B"]) if "B" in spec else 8
    melA, motif = C.melody(song, 0, na, style, lo, hi, cadence=spec.get("cadA", "tonic"), seed=sd)
    melB, _ = C.melody(song, na, nb, spec.get("style_b", style), lo + spec.get("b_shift", 2), hi + spec.get("b_shift", 2),
                       cadence="dominant", seed=sd + 11)
    off = (na + nb) * B
    melA2 = [(b + off, d, m, v) for (b, d, m, v) in melA]
    mel = melA + melB + melA2
    leg = spec.get("legato", 0.92)

    # ---------------- base: подклад, бас, арпеджио, мелодия, лёгкая перкуссия
    song.tag = "pad"
    pr = spec.get("pad_range", (55, 72))
    C.part_pad(song, "base", INST[spec.get("pad", "strings")], pr[0], pr[1], 0.7, g(spec, "pad"), rev=0.45)
    song.tag = "bass"
    C.part_bass(song, "base", INST[spec.get("bass", "bass_upright")], spec.get("bass_base", "root2"), gain=g(spec, "bass"))
    if spec.get("arp"):
        song.tag = "arp"
        ar = spec.get("arp_range", (60, 84))
        C.part_arp(song, "base", INST[spec["arp"]], spec.get("arp_pat", "up8"), ar[0], ar[1], 0.6, g(spec, "arp"),
                   rev=0.32, dly=spec.get("arp_dly", 0.0))
    if spec.get("comp"):
        song.tag = "comp"
        cr = spec.get("comp_range", (52, 70))
        C.part_comp(song, "base", INST[spec["comp"]], spec.get("comp_pat", "strum4"), cr[0], cr[1], 0.6, g(spec, "comp"))
    song.tag = "lead"
    C.part_melody(song, "base", INST[spec.get("lead", "flute")], mel, g(spec, "lead"), 0.0, rev=0.28,
                  dly=spec.get("lead_dly", 0.0), legato=leg)
    if spec.get("lead2"):
        song.tag = "lead2"
        C.part_melody(song, "base", INST[spec["lead2"]], melA2, g(spec, "lead2"), 0.25, rev=0.3,
                      octave=spec.get("lead2_oct", 1), legato=leg)
    if spec.get("perc"):
        song.tag = "perc"
        C.part_drums(song, "base", spec["perc"], gain=g(spec, "perc"), fills=False, crash_every=0)
    for amb in spec.get("ambient", []):
        C.ambient(song, "base", amb, spec.get("amb_gain", 1.0))
    if spec.get("alarm"):
        song.tag = "bells"
        for bar in range(0, song.nbars, 2):
            song.sound("base", S.alarm_bell(0.8, S.midi_hz(spec["key"] + 7 - 12)), bar * B, -0.3, 0.4, g(spec, "bells"))
    if spec.get("solo"):
        return song

    # ---------------- battle: полные ударные, бас восьмыми, остинато
    song.tag = "drums"
    C.part_drums(song, "battle", spec.get("kit", "rock"), gain=g(spec, "drums"), crash_every=8)
    song.tag = "bass2"
    C.part_bass(song, "battle", INST[spec.get("bass2", spec.get("bass", "bass_upright"))], spec.get("bass_battle", "pump8"),
                gain=g(spec, "bass2"))
    song.tag = "ost"
    ost = spec.get("ost", "stacc")
    orr = spec.get("ost_range", (55, 76))
    if spec.get("ost_pat", "eighths") in ("eighths", "stab", "offbeat", "strum4", "pah"):
        C.part_comp(song, "battle", INST[ost], spec.get("ost_pat", "eighths"), orr[0], orr[1], 0.75, g(spec, "ost"),
                    rev=0.25, pan=-0.2)
    else:
        C.part_arp(song, "battle", INST[ost], spec.get("ost_pat"), orr[0], orr[1], 0.7, g(spec, "ost"), rev=0.25)
    if "crowd" in spec.get("battle_ambient", []):
        C.ambient(song, "battle", "crowd", 0.8)

    # ---------------- boss: медь/хор, вторая мелодия, тяжёлые барабаны, удары
    song.tag = "boss_drums"
    C.part_drums(song, "boss", spec.get("kit_boss", "taiko"), gain=g(spec, "boss_drums"), crash_every=4)
    song.tag = "boss_lead"
    C.part_melody(song, "boss", INST[spec.get("boss_lead", "brass")], mel, g(spec, "boss_lead"), -0.2, rev=0.35,
                  octave=spec.get("boss_oct", -1), legato=0.9)
    song.tag = "counter"
    cl, ch = spec.get("counter_range", (lo - 5, hi - 7))
    cm = C.counter(song, 0, song.nbars, cl, ch, mel, seed=sd)
    C.part_melody(song, "boss", INST[spec.get("counter", "choir")], cm, g(spec, "counter"), 0.3, rev=0.5, legato=0.98)
    song.tag = "braam"
    for st in song.section_starts:
        root, tones = song.bars[st][0][2], song.bars[st][0][3]
        r = 36 + ((song.key + root - 36) % 12)
        song.sound("boss", S.braam(S.midi_hz(r), B * song.spb * 1.6, 0.95), st * B, 0.0, 0.35, g(spec, "braam"))
    if "crowd" in spec.get("boss_ambient", []):
        C.ambient(song, "boss", "crowd", 1.0)
    return song


def report(song):
    tot = {}
    for (stem, tag), e in song.energy.items():
        tot.setdefault(stem, {})[tag] = e
    lines = []
    ref = tot.get("base", {}).get("lead", 1.0)
    for stem, d in tot.items():
        parts = ", ".join("%s %+.0f" % (t, 10 * np.log10(e / ref + 1e-12)) for t, e in sorted(d.items(), key=lambda x: -x[1]))
        lines.append("  %s: %s" % (stem, parts))
    return "\n".join(lines)
