"""Сборка музыки: python3 tools/music/render.py [имя_трека ...] [--stingers] [--q 1]

Пишет audio/music/<трек>_0.ogg (base), _1 (battle), _2 (boss) и короткие
музыкальные вставки audio/music/sting_*.ogg. Без аргументов — всё.
"""
import os
import subprocess
import sys
import tempfile
import time

import numpy as np
from scipy.io import wavfile
from scipy import signal

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import synth as S  # noqa: E402
import comp as C  # noqa: E402
import arrange as A  # noqa: E402
from tracks import TRACKS  # noqa: E402
import stingers  # noqa: E402
import battle as BT  # noqa: E402
from battle_tracks import BATTLE, SHOP  # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, "..", "..", "audio", "music"))


def encode(y, path, q=4.0, layer=False):
    """Стерео 44,1 кГц, Vorbis q≈4 (~128 кбит/с): полноценное качество и для слоёв battle/boss."""
    rate = S.SR
    y = np.clip(y, -1.0, 1.0)
    pcm = (y.T * 32767.0).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        tmp = f.name
    wavfile.write(tmp, rate, pcm)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", tmp, "-c:a", "libvorbis", "-q:a", str(q), path],
                   check=True)
    os.unlink(tmp)


def render_track(name, q=1.0, verbose=True):
    spec = dict(TRACKS[name])
    spec["name"] = name
    t0 = time.time()
    song = A.build(spec)
    rv = spec.get("reverb", (2.2, 0.5))
    stems = ("base",) if spec.get("solo") else ("base", "battle", "boss")
    outs = C.master(song, rv[0], rv[1], target_rms=spec.get("target", 0.16), stems=stems)
    os.makedirs(OUT, exist_ok=True)
    for i, k in enumerate(stems):
        encode(outs[k], os.path.join(OUT, "%s_%d.ogg" % (name, i)), q, layer=i > 0)
    if verbose:
        full = sum(outs.values())
        print("%-16s %5.1fs  len %.1fs  peak %.2f  rms full %.3f base %.3f  (%.1fs)" % (
            name, song.L / S.SR, song.L / S.SR, np.abs(full).max(), np.sqrt(np.mean(full ** 2)),
            np.sqrt(np.mean(outs["base"] ** 2)), time.time() - t0))
        print(A.report(song))
    return song


def render_battle(name, q=4.0):
    """Боевой трек Арены, мини-босс, босс — один стерео-файл <имя>_0.ogg."""
    t0 = time.time()
    spec = dict(BATTLE[name])
    spec["name"] = name
    song = BT.build_battle(spec)
    out = BT.master_battle(song, target_rms=spec.get("target", 0.2))["base"]
    os.makedirs(OUT, exist_ok=True)
    encode(out, os.path.join(OUT, "%s_0.ogg" % name), q)
    print("%-16s len %.1fs  peak %.2f  rms %.3f  (%.1fs)" % (name, song.L / S.SR, np.abs(out).max(),
                                                         np.sqrt(np.mean(out ** 2)), time.time() - t0))
    print(A.report(song))


def render_shop(q=4.0):
    t0 = time.time()
    spec = dict(SHOP)
    spec["name"] = "shop"
    song = BT.build_shop(spec)
    out = BT.master_battle(song, ir_seconds=2.0, target_rms=0.15, width=1.15, comp=(-22.0, 2.0), air=1.5)["base"]
    encode(out, os.path.join(OUT, "shop_0.ogg"), q)
    print("shop             len %.1fs  peak %.2f  rms %.3f  (%.1fs)" % (song.L / S.SR, np.abs(out).max(),
                                                                      np.sqrt(np.mean(out ** 2)), time.time() - t0))


def main(argv):
    if "--battle" in argv:
        q = float(argv[argv.index("--q") + 1]) if "--q" in argv else 4.0
        names = [a for a in argv if a in BATTLE] or list(BATTLE)
        for n in names:
            render_battle(n, q)
        if "shop" in argv or len(names) == len(BATTLE):
            render_shop(q)
        return
    if "shop" in argv:
        render_shop()
        return
    q = 4.0
    if "--q" in argv:
        q = float(argv[argv.index("--q") + 1])
    names = [a for a in argv if a in TRACKS]
    do_st = "--stingers" in argv or not names
    if not names and "--stingers" not in argv:
        names = list(TRACKS)
    for n in names:
        render_track(n, q)
    if do_st:
        os.makedirs(OUT, exist_ok=True)
        for sid, y in stingers.all_stingers().items():
            encode(y, os.path.join(OUT, "sting_%s.ogg" % sid), q)
            print("sting", sid, "%.1fs" % (y.shape[1] / S.SR))


if __name__ == "__main__":
    main(sys.argv[1:])
