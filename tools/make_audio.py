#!/usr/bin/env python3
"""
Generates all of REWIND LIFE's audio from scratch: an original 80s synth-pop
loop for the house, and the sound effects. Nothing is sampled; every sound is
synthesized here, so it is all yours to use.

    python3 tools/make_audio.py          # writes audio/*.ogg

Needs: Python 3, numpy, scipy, and ffmpeg (for Ogg Vorbis encoding).
Tweak the melody, tempo or chords below and run it again.
"""
import os
import subprocess
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "audio")
rng = np.random.default_rng(1986)


# =============================================================== basics

def mtof(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def secs(s):
    return int(round(s * SR))


def tvec(n):
    return np.arange(n) / SR


def noise(n):
    return rng.uniform(-1.0, 1.0, n)


def saw(freq, n, phase0=0.0):
    """Band-limited sawtooth (polyBLEP). freq may be a number or an array."""
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,))
    dt = f / SR
    ph = (phase0 + np.cumsum(dt)) % 1.0
    y = 2.0 * ph - 1.0
    m = ph < dt
    t = ph[m] / dt[m]
    y[m] -= t + t - t * t - 1.0
    m = ph > 1.0 - dt
    t = (ph[m] - 1.0) / dt[m]
    y[m] -= t * t + t + t + 1.0
    return y


def square(freq, n, pw=0.5):
    return 0.5 * (saw(freq, n) - saw(freq, n, pw))


def sine(freq, n, phase0=0.0):
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,))
    return np.sin(2 * np.pi * (phase0 + np.cumsum(f) / SR))


def env_adsr(n, a, d, s, r, gate):
    """ADSR in seconds; `gate` = how long the key is held."""
    t = tvec(n)
    e = np.where(t < a, t / max(a, 1e-6), s + (1 - s) * np.exp(-(t - a) / max(d, 1e-6)))
    rel = t > gate
    e_at_gate = s + (1 - s) * np.exp(-max(gate - a, 0) / max(d, 1e-6)) if gate > a else gate / max(a, 1e-6)
    e[rel] = e_at_gate * np.exp(-(t[rel] - gate) / max(r, 1e-6))
    return e


def lp(x, fc, order=2):
    sos = signal.butter(order, min(fc, SR * 0.45), "low", fs=SR, output="sos")
    return signal.sosfilt(sos, x, axis=0)


def hp(x, fc, order=2):
    sos = signal.butter(order, fc, "high", fs=SR, output="sos")
    return signal.sosfilt(sos, x, axis=0)


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, min(hi, SR * 0.45)], "band", fs=SR, output="sos")
    return signal.sosfilt(sos, x, axis=0)


def resonator(x, f, q):
    b, a = signal.iirpeak(f, q, fs=SR)
    return signal.lfilter(b, a, x)


def add(buf, start, y, gain=1.0, pan=0.0):
    """Mix mono y into stereo buf at sample `start` (pan -1 left .. 1 right)."""
    if start >= len(buf):
        return
    y = y[: len(buf) - start] * gain
    lg = np.cos((pan + 1) * np.pi / 4) * np.sqrt(2)
    rg = np.sin((pan + 1) * np.pi / 4) * np.sqrt(2)
    buf[start:start + len(y), 0] += y * lg
    buf[start:start + len(y), 1] += y * rg


def reverb_ir(seconds, decay, seed, bright=6000):
    r = np.random.default_rng(seed)
    n = secs(seconds)
    t = tvec(n)
    ir = np.stack([r.uniform(-1, 1, n), r.uniform(-1, 1, n)], axis=1)
    ir *= np.exp(-t * decay)[:, None]
    ir = lp(ir, bright)
    ir[: secs(0.012)] = 0.0  # pre-delay
    return ir / np.sqrt(np.sum(ir ** 2, axis=0, keepdims=True))


def convolve_stereo(x, ir):
    return np.stack([signal.fftconvolve(x[:, i], ir[:, i])[: len(x)] for i in range(2)], axis=1)


def fold(buf, length):
    """Wrap the tail past `length` onto the start, so the loop is seamless."""
    out = buf[:length].copy()
    tail = buf[length:]
    while len(tail):
        k = min(len(tail), length)
        out[:k] += tail[:k]
        tail = tail[k:]
    return out


def save(name, x, peak=0.89):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m * peak
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "a.wav")
        wavfile.write(wav, SR, (x * 32767).astype(np.int16))
        dst = os.path.join(OUT, name + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", dst], check=True)
    print(f"  {name}.ogg  ({len(x) / SR:.1f}s)")


# =============================================================== the song

BPM = 112
BEAT = 60.0 / BPM
BAR = 4 * BEAT

CHORDS = {   # pad voicing (MIDI) and bass root
    "Am": ([57, 60, 64], 45), "F": ([57, 60, 65], 41), "C": ([55, 60, 64], 48),
    "G": ([55, 59, 62], 43), "Dm": ([57, 62, 65], 38), "E": ([56, 59, 64], 40),
    "Em": ([55, 59, 64], 40),
}
SECTIONS = [
    ("intro",     ["Am", "F", "C", "G", "Am", "F", "C", "G"]),
    ("verse",     ["Am", "F", "C", "G", "Am", "F", "Dm", "E"]),
    ("chorus",    ["F", "G", "Em", "Am", "F", "G", "C", "E"]),
    ("breakdown", ["Dm", "Dm", "Am", "Am", "F", "F", "E", "E"]),
]

# Lead melody: per bar, (MIDI note, start beat, length in beats)
VERSE = [
    [(76, 0, 1), (72, 1, .5), (74, 1.5, .5), (76, 2, 1.5)],
    [(77, 0, .5), (76, .5, .5), (72, 1, 1), (69, 2, 2)],
    [(67, 0, .5), (72, .5, .5), (76, 1, 1), (79, 2, 1), (76, 3, 1)],
    [(74, 0, 1.5), (71, 1.5, .5), (74, 2, 2)],
    [(76, 0, 1), (72, 1, .5), (74, 1.5, .5), (76, 2, 1), (81, 3, 1)],
    [(79, 0, .5), (77, .5, .5), (76, 1, 1), (72, 2, 2)],
    [(74, 0, 1), (77, 1, 1), (81, 2, 1), (79, 3, 1)],
    [(80, 0, 2), (76, 2, 1), (71, 3, 1)],
]
CHORUS = [
    [(81, 0, 1.5), (79, 1.5, .5), (77, 2, 1), (76, 3, 1)],
    [(74, 0, 1), (79, 1, 1), (83, 2, 1.5), (81, 3.5, .5)],
    [(79, 0, 1.5), (76, 1.5, .5), (71, 2, 2)],
    [(72, 0, .5), (74, .5, .5), (76, 1, 1), (81, 2, 2)],
    [(81, 0, 1.5), (79, 1.5, .5), (77, 2, 1), (81, 3, 1)],
    [(83, 0, 1), (86, 1, 1), (83, 2, 1), (79, 3, 1)],
    [(84, 0, 2), (79, 2, 1), (76, 3, 1)],
    [(80, 0, 1), (83, 1, 1), (88, 2, 2)],
]


def kick():
    n = secs(0.45)
    t = tvec(n)
    f = 45 + 80 * np.exp(-t * 30)
    y = sine(f, n) * np.exp(-t * 7.5)
    y += lp(noise(n), 3000) * np.exp(-t * 250) * 0.4
    return y


def snare():
    n = secs(0.3)
    t = tvec(n)
    y = bp(noise(n), 1200, 7000) * np.exp(-t * 16)
    y += sine(185, n) * np.exp(-t * 28) * 0.6
    # layered clap
    for d in (0.0, 0.011, 0.022):
        k = secs(d)
        c = bp(noise(n - k), 900, 3200) * np.exp(-tvec(n - k) * 60)
        y[k:] += c * 0.5
    return y


def hat(open_=False):
    n = secs(0.35 if open_ else 0.07)
    t = tvec(n)
    return hp(noise(n), 7000, 4) * np.exp(-t * (11 if open_ else 70))


def tom(f0):
    n = secs(0.4)
    t = tvec(n)
    return sine(f0 * (1 + 0.6 * np.exp(-t * 20)), n) * np.exp(-t * 7)


def pad_note(m, dur, detune_cents):
    n = secs(dur + 0.6)
    f = mtof(m) * 2 ** (detune_cents / 1200.0)
    y = saw(f, n, rng.uniform()) + 0.6 * saw(f * 0.5, n, rng.uniform())
    return lp(y, 1900) * env_adsr(n, 0.25, 0.8, 0.85, 0.45, dur)


def bass_note(m, dur):
    n = secs(dur + 0.15)
    t = tvec(n)
    y = saw(mtof(m), n) * 0.7 + square(mtof(m), n, 0.5) * 0.3
    body = lp(y, 750, 4)
    bite = lp(y, 2600, 2) * np.exp(-t * 18)
    return (body + bite * 0.6) * env_adsr(n, 0.004, 0.2, 0.7, 0.05, dur)


def arp_note(m, dur):
    n = secs(dur + 0.05)
    y = square(mtof(m), n, 0.32)
    return lp(y, 3200) * env_adsr(n, 0.002, 0.11, 0.25, 0.04, dur)


def lead_note(m, dur):
    n = secs(dur + 0.25)
    t = tvec(n)
    vib = 1 + (2 ** (14 / 1200.0) - 1) * np.sin(2 * np.pi * 5.6 * t) * np.clip((t - 0.18) * 4, 0, 1)
    f = mtof(m) * vib
    y = saw(f, n) * 0.6 + square(f * 1.003, n, 0.5) * 0.4
    return lp(y, 3600) * env_adsr(n, 0.012, 0.25, 0.72, 0.16, dur)


def bell_note(m, dur=1.6):
    """DX7-style FM electric piano / bell."""
    n = secs(dur)
    t = tvec(n)
    f = mtof(m)
    index = 2.4 * np.exp(-t * 5.5) + 0.35
    y = np.sin(2 * np.pi * f * t + index * np.sin(2 * np.pi * f * t))
    y += 0.25 * np.sin(2 * np.pi * f * 3.5 * t) * np.exp(-t * 14)   # tine "ping"
    return y * np.exp(-t * 2.6) * np.minimum(1, t * 400)


def make_song():
    bars = sum(len(s[1]) for s in SECTIONS)
    L = secs(bars * BAR)
    T = secs(3.0)  # room for tails, folded back for a seamless loop
    drums = np.zeros((L + T, 2))
    snare_bus = np.zeros((L + T, 2))
    gate = np.zeros(L + T)
    bass = np.zeros((L + T, 2))
    pads = np.zeros((L + T, 2))
    arp = np.zeros((L + T, 2))
    lead = np.zeros((L + T, 2))
    bells = np.zeros((L + T, 2))
    K, S, H, HO = kick(), snare(), hat(), hat(True)

    bar_i = 0
    for name, prog in SECTIONS:
        for j, ch in enumerate(prog):
            b0 = bar_i * BAR
            voicing, root = CHORDS[ch]
            at = lambda beat: secs(b0 + beat * BEAT)

            # --- drums
            light = name == "intro" and j < 4
            if name == "breakdown":
                add(drums, at(0), K, 0.9)
                if j % 2 == 1:
                    add(drums, at(2.5), K, 0.6)
                for e in range(8):
                    add(drums, at(e * 0.5), H, 0.12 if e % 2 else 0.2, 0.35)
                if j == 7:  # tom fill back into the intro
                    for k, (b, f) in enumerate([(2, 180), (2.5, 150), (3, 120), (3.5, 95)]):
                        add(drums, at(b), tom(f), 0.55, -0.4 + k * 0.25)
            else:
                for b in (0, 1.5, 2, 2.75) if name == "chorus" else (0, 1.5, 2):
                    add(drums, at(b), K, 1.0)
                if not light:
                    for b in (1, 3):
                        add(snare_bus, at(b), S, 0.6)
                        # the 80s gated reverb: a big room, chopped off short
                        s0 = at(b)
                        on, off = secs(0.26), secs(0.03)
                        gate[s0:s0 + on] = 1.0
                        seg = gate[s0 + on:s0 + on + off]
                        seg[:] = np.maximum(seg, np.linspace(1, 0, off)[: len(seg)])
                steps = 16 if name == "chorus" else 8
                for e in range(steps):
                    beat = e * 4.0 / steps
                    if not light or e % 2 == 0:
                        add(drums, at(beat), H, (0.16 if e % 2 else 0.26), 0.35)
                if name != "intro" and j % 4 == 3:
                    add(drums, at(3.5), HO, 0.2, 0.35)

            # --- bass: pumping eighths (sustained in the breakdown)
            if name == "breakdown":
                add(bass, at(0), bass_note(root, BAR * 0.95), 0.5)
            else:
                for e in range(8):
                    m = root + (12 if e % 2 else 0)
                    add(bass, at(e * 0.5), bass_note(m, BEAT * 0.42), 0.42)

            # --- pads: detuned saws, spread wide
            for m in voicing:
                for cents, pan in ((-9, -0.8), (0, 0.0), (9, 0.8)):
                    add(pads, at(0), pad_note(m, BAR, cents), 0.05, pan)

            # --- arpeggio (16ths)
            if name != "breakdown" or j >= 4:
                tones = voicing + [voicing[0] + 12]
                pattern = [0, 1, 2, 3, 2, 1, 2, 3, 0, 1, 2, 3, 2, 3, 1, 2]
                vol = 0.09 if name != "breakdown" else 0.06
                for e, p in enumerate(pattern):
                    add(arp, at(e * 0.25), arp_note(tones[p] + 12, BEAT * 0.2), vol, 0.25)

            # --- lead melody
            phrase = VERSE if name == "verse" else CHORUS if name == "chorus" else None
            if phrase:
                for m, b, d in phrase[j]:
                    add(lead, at(b), lead_note(m, d * BEAT * 0.95), 0.2)

            # --- FM bells
            if name == "intro" and j >= 4:
                for m, b, d in VERSE[j - 4]:
                    add(bells, at(b), bell_note(m + 12), 0.1, -0.45)
            elif name == "chorus":
                for b, k in ((0.5, 0), (1.5, 1), (2.5, 2), (3.5, 1)):
                    add(bells, at(b), bell_note(voicing[k] + 24), 0.07, -0.5)
            elif name == "breakdown":
                for b, k in ((0, 2), (1, 1), (2, 0), (3, 1)):
                    add(bells, at(b), bell_note(voicing[k] + 12, 2.0), 0.11, -0.3 + 0.2 * (b % 2))
            bar_i += 1

    # --- effects
    hall = reverb_ir(2.4, 2.4, 7)
    room = reverb_ir(1.2, 3.5, 11, bright=9000)
    gated = convolve_stereo(snare_bus, room) * gate[:, None] * 1.4
    d8 = secs(BEAT * 0.75)  # dotted-eighth echo, ping-pong
    for bus, taps in ((arp, 4), (lead, 3)):
        src = bus.mean(axis=1)
        for k in range(1, taps + 1):
            ch = 1 if k % 2 else 0          # echoes bounce right, left, right...
            bus[d8 * k:, ch] += src[: len(bus) - d8 * k] * 0.38 ** k
    wet = convolve_stereo(pads * 0.6 + lead * 0.35 + bells * 0.5 + arp * 0.25, hall)
    mix = drums + snare_bus + gated + bass + pads + arp + lead + bells + wet * 0.55
    mix = fold(mix, L)
    mix = lp(mix, 15000)
    mix = mix / np.max(np.abs(mix))
    mix = np.tanh(mix * 1.4) / np.tanh(1.4)   # gentle tape-style saturation
    return mix


# =============================================================== effects

def tel(x):
    """Sound like it's coming through a phone line."""
    return bp(x, 320, 3400, 3)


def sfx_tv_on():
    n = secs(1.4)
    t = tvec(n)
    y = sine(55, n) * np.exp(-t * 14) * 0.9                   # power-on thunk
    y += lp(noise(n), 2500) * np.exp(-t * 120) * 0.6
    hum = sum(sine(60 * k, n) / k for k in (1, 2, 3)) * np.exp(-t * 4) * (1 + 0.3 * np.sin(2 * np.pi * 7 * t))
    y += hum * 0.5                                            # degauss "bwong"
    st = hp(noise(n), 1500) * np.clip((t - 0.15) * 8, 0, 1) * np.exp(-np.maximum(t - 0.25, 0) * 5)
    y += st * 0.35                                            # static
    y += sine(15700, n) * np.clip(t - 0.3, 0, 1) * 0.015      # the CRT whine
    return y


def sfx_tv_off():
    n = secs(0.7)
    t = tvec(n)
    y = lp(noise(n), 4000) * np.exp(-t * 300) * 0.8           # switch click
    f = 80 + 1100 * np.exp(-t * 25)
    y += sine(f, n) * np.exp(-t * 9) * 0.5                    # the zap down
    y += hp(noise(n), 2000) * np.exp(-t * 14) * 0.15
    return y


def sfx_tv_show():
    """A bouncy cartoon theme heard through a TV speaker (loops)."""
    bpm = 150
    beat = 60 / bpm
    L = secs(16 * beat)
    buf = np.zeros(L + secs(1.5))
    melody = [72, 76, 79, 76, 77, 74, 71, 74, 72, 76, 79, 84, 83, 79, 76, 79,
              77, 81, 84, 81, 79, 76, 72, 76, 74, 77, 79, 83, 84, 79, 72, 0]
    for i, m in enumerate(melody):
        if m == 0:
            continue
        n = secs(0.35)
        tt = tvec(n)
        f = mtof(m)
        note = (np.sin(2 * np.pi * f * tt) + 0.35 * np.sin(2 * np.pi * f * 4 * tt) * np.exp(-tt * 30)) * np.exp(-tt * 9)
        s = secs(i * beat / 2)
        buf[s:s + n] += note * 0.5
    for i, m in enumerate([48, 55, 53, 55, 48, 55, 50, 55, 53, 57, 55, 59, 48, 55, 43, 48]):
        n = secs(beat * 0.6)
        s = secs(i * beat)
        buf[s:s + n] += lp(saw(mtof(m), n), 400) * np.exp(-tvec(n) * 6) * 0.45   # tuba oom-pah
    n = secs(0.6)                                             # slide whistle
    tt = tvec(n)
    f = 600 + 900 * tt / 0.6 + 30 * np.sin(2 * np.pi * 9 * tt)
    s = secs(8 * beat)
    buf[s:s + n] += sine(f, n) * np.hanning(n) * 0.35
    n = secs(0.5)                                             # boing!
    tt = tvec(n)
    s = secs(13.5 * beat)
    buf[s:s + n] += sine(110 + 220 * np.exp(-tt * 6) * (1 + 0.25 * np.sin(2 * np.pi * 18 * tt)), n) * np.exp(-tt * 5) * 0.5
    y = fold(buf, L)
    y = bp(y, 260, 4500, 2)                                   # little TV speaker
    y = np.tanh(y * 2.0)
    y += hp(noise(L), 3000) * 0.012                           # broadcast hiss
    return y


def creak(n, f_lo, f_hi, seed):
    r = np.random.default_rng(seed)
    t = tvec(n)
    y = np.zeros(n)
    pos = 0.0
    while pos < n:
        frac = pos / n
        f = f_lo + (f_hi - f_lo) * np.sin(np.pi * frac)
        i = int(pos)
        y[i] = r.uniform(0.4, 1.0)
        pos += SR / (f * r.uniform(0.85, 1.15))
    y = resonator(y, 950, 6) + resonator(y, 1750, 8) * 0.6 + resonator(y, 3100, 10) * 0.3
    return y * np.sin(np.pi * np.clip(t / (n / SR), 0, 1)) ** 0.7


def latch(n, at):
    y = np.zeros(n)
    s = secs(at)
    k = secs(0.008)
    y[s:s + k] = bp(noise(k), 2000, 7000) * np.exp(-tvec(k) * 500)
    return y


def sfx_door_open():
    n = secs(1.4)
    t = tvec(n)
    y = latch(n, 0.0) + latch(n, 0.045) * 0.7
    c = np.zeros(n)
    s = secs(0.12)
    c[s:] = creak(n - s, 70, 150, 3)
    y += c * 0.5
    y += lp(noise(n), 500) * np.sin(np.pi * np.clip((t - 0.1) / 1.0, 0, 1)) * 0.15   # air
    return y


def sfx_door_close():
    n = secs(0.9)
    t = tvec(n)
    y = lp(noise(n), 600) * np.clip(t / 0.15, 0, 1) * np.exp(-t * 6) * 0.2          # whoosh
    s = secs(0.16)
    tt = tvec(n - s)
    thud = sine(68, n - s) * np.exp(-tt * 14) + lp(noise(n - s), 900) * np.exp(-tt * 40) * 0.8
    y[s:] += thud
    y += latch(n, 0.19) * 0.8
    r = np.zeros(n)                                                                  # frame rattle
    r[s:] = bp(noise(n - s), 1500, 4000) * np.exp(-tt * 30) * 0.25
    return y + r


def clink(n, at, f, amp):
    y = np.zeros(n)
    s = secs(at)
    k = min(secs(0.25), n - s)
    tt = tvec(k)
    y[s:s + k] = (np.sin(2 * np.pi * f * tt) + 0.5 * np.sin(2 * np.pi * f * 2.76 * tt)) * np.exp(-tt * 22) * amp
    return y


def sfx_fridge_open():
    n = secs(1.9)
    t = tvec(n)
    y = lp(noise(n), 400) * np.clip(t / 0.12, 0, 1) * (t < 0.14) * 0.5          # seal pulls
    s = secs(0.14)
    tt = tvec(n - s)
    y[s:] += sine(120, n - s) * np.exp(-tt * 30) * 0.8 + lp(noise(n - s), 1500) * np.exp(-tt * 80) * 0.5  # pop
    for at, f, a in ((0.22, 2300, 0.25), (0.29, 3050, 0.2), (0.36, 2650, 0.15)):
        y += clink(n, at, f, a)                                                    # bottles in the door
    hum = sine(60, n) + 0.6 * sine(120, n) + 0.3 * sine(180, n)
    y += hum * np.clip((t - 0.2) * 2, 0, 1) * np.clip((1.9 - t) * 2, 0, 1) * 0.12
    y += lp(noise(n), 3000) * np.clip((t - 0.2) * 2, 0, 1) * np.clip((1.9 - t) * 2, 0, 1) * 0.05  # cold air
    return y


def sfx_fridge_close():
    n = secs(0.8)
    t = tvec(n)
    y = lp(noise(n), 500) * np.clip(t / 0.1, 0, 1) * np.exp(-t * 8) * 0.2
    s = secs(0.1)
    tt = tvec(n - s)
    y[s:] += sine(90, n - s) * np.exp(-tt * 18) * 0.9 + lp(noise(n - s), 700) * np.exp(-tt * 25) * 0.6
    y += clink(n, 0.13, 2400, 0.2) + clink(n, 0.16, 2900, 0.12)
    return y


def sfx_snore():
    """One slow breath cycle of snoring (loops)."""
    L = secs(4.6)
    y = np.zeros(L)
    n = secs(1.6)                                             # inhale: the snore itself
    t = tvec(n)
    flutter = (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * (26 + 6 * t / 1.6) * t))) ** 2
    src = bp(noise(n), 90, 900) * flutter
    src = resonator(src, 180, 2) + resonator(src, 420, 3) * 0.6
    y[secs(0.1):secs(0.1) + n] += src * np.sin(np.pi * t / 1.6) ** 1.5
    n = secs(1.4)                                             # exhale: soft breath
    t = tvec(n)
    s = secs(2.0)
    y[s:s + n] += bp(noise(n), 300, 1800) * np.sin(np.pi * t / 1.4) ** 2 * 0.18
    y[s + n - secs(0.15):s + n] += bp(noise(secs(0.15)), 600, 2500) * np.hanning(secs(0.15)) * 0.12  # "pff"
    return y


def click(n, at, amp=1.0):
    y = np.zeros(n)
    s = secs(at)
    k = secs(0.005)
    if s + k <= n:
        y[s:s + k] = bp(noise(k), 1500, 6000) * np.exp(-tvec(k) * 700) * amp
    return y


def sfx_phone_dial():
    """Rotary-dialing four digits, then the US ringback tone, then a pick-up."""
    digits = [8, 6, 7, 5]
    pos = 0.15
    parts = []
    for d in digits:
        parts.append(("wind", pos, 0.38))
        pos += 0.4
        parts.append(("return", pos, d))
        pos += d * 0.1 + 0.18
    ring_at = pos + 0.5
    n = secs(ring_at + 2.0 + 1.6 + 0.4)
    y = np.zeros(n)
    for kind, at, v in parts:
        if kind == "wind":
            k = secs(v)
            s = secs(at)
            y[s:s + k] += bp(noise(k), 500, 2200) * np.linspace(0.05, 0.25, k)
            for c in range(5):
                y += click(n, at + c * v / 5, 0.25)
        else:
            k = secs(v * 0.1)
            s = secs(at)
            y[s:s + k] += lp(saw(190, k), 1200) * 0.12               # governor whir
            for c in range(v):
                y += click(n, at + c * 0.1 + 0.02, 0.9)              # line pulses
    k = secs(2.0)
    s = secs(ring_at)
    ring = (sine(440, k) + sine(480, k)) * 0.25
    y[s:s + k] += tel(ring) * np.minimum(1, np.minimum(tvec(k), 2.0 - tvec(k)) * 50)
    y += tel(noise(n)) * 0.01                                         # line hiss
    y += click(n, ring_at + 2.0 + 1.5, 1.0) + click(n, ring_at + 2.0 + 1.52, 0.6)  # they pick up
    return y


def sfx_phone_talk():
    """The friend's voice, tinny from the handset: cheerful gibberish (loops)."""
    L = secs(6.0)
    y = np.zeros(L + secs(0.5))
    vowels = [(800, 1200), (500, 1800), (320, 2300), (520, 920), (360, 820), (650, 1650)]
    pos = 0.1
    r = np.random.default_rng(42)
    while pos < 5.6:
        syllables = r.integers(4, 9)
        f0 = r.uniform(190, 240)
        for i in range(syllables):
            dur = r.uniform(0.09, 0.22)
            n = secs(dur)
            t = tvec(n)
            pitch = f0 * (1 + 0.12 * np.sin(2 * np.pi * r.uniform(1, 3) * t)) * (1.08 if i == 0 else 1.0)
            pulses = (np.sin(2 * np.pi * np.cumsum(pitch) / SR) > 0.92).astype(float)
            v1, v2 = vowels[r.integers(len(vowels))]
            s = resonator(pulses, v1, 4) + resonator(pulses, v2, 6) * 0.6
            if r.uniform() < 0.5:                                    # a consonant
                k = secs(0.025)
                s[:k] += hp(noise(k), 2500) * 0.8
            st = secs(pos)
            y[st:st + n] += s * np.hanning(n)
            pos += dur + r.uniform(0.0, 0.04)
            if pos > 5.6:
                break
        pos += r.uniform(0.35, 0.7)
    y = fold(y, L)
    y = np.tanh(tel(y) * 3.0)
    return y


def sfx_phone_busy():
    n = secs(4.0)
    t = tvec(n)
    tone = (sine(480, n) + sine(620, n)) * ((t % 1.0) < 0.5)
    return tel(tone) + tel(noise(n)) * 0.02


def sfx_phone_hangup():
    n = secs(0.9)
    t = tvec(n)
    y = sine(95, n) * np.exp(-t * 25) * 0.8 + bp(noise(n), 800, 4000) * np.exp(-t * 90) * 0.7   # clunk
    s = secs(0.03)
    tt = tvec(n - s)
    ding = (np.sin(2 * np.pi * 2450 * tt) + 0.6 * np.sin(2 * np.pi * 3120 * tt)) * np.exp(-tt * 9)
    y[s:] += ding * 0.12                                     # the bell inside the phone
    return y


def sfx_memory():
    n = secs(4.2)
    y = np.zeros((n, 2))
    for i, m in enumerate([72, 76, 79, 84, 88]):
        add(y, secs(0.13 * i), bell_note(m, 3.0), 0.35, -0.5 + i * 0.25)
    for m in (60, 64, 67):
        k = secs(3.2)
        p = lp(saw(mtof(m), k) + saw(mtof(m) * 1.004, k), 1400) * env_adsr(k, 0.8, 1.0, 0.8, 1.0, 1.8)
        add(y, 0, p, 0.06)
    wet = convolve_stereo(np.concatenate([y, np.zeros((secs(2), 2))]), reverb_ir(2.5, 2.2, 5))[:n]
    return y + wet * 0.7


def sfx_door_locked():
    """Jiggling the handle of a locked door: rattles and a dull knock of the latch."""
    n = secs(1.0)
    y = np.zeros(n)
    for at in (0.0, 0.16, 0.34, 0.5):
        y += latch(n, at) * 0.9
        s0 = secs(at + 0.01)
        k = secs(0.12)
        tt = tvec(k)
        y[s0:s0 + k] += bp(noise(k), 1200, 5000) * np.exp(-tt * 45) * 0.35       # metal rattle
        y[s0:s0 + k] += sine(140, k) * np.exp(-tt * 40) * 0.4                    # door shifts in frame
    return y


def sfx_crickets():
    """Summer night outside the window (loops)."""
    L = secs(6.0)
    y = np.zeros(L + secs(1.0))
    r = np.random.default_rng(7)
    for voice in range(5):
        f = r.uniform(4200, 5200)
        rate = r.uniform(0.55, 0.9)              # chirps per second
        t0 = r.uniform(0, 0.8)
        while t0 < 6.0:
            for p in range(3):                   # each chirp = 3 quick pulses
                k = secs(0.018)
                tt = tvec(k)
                s0 = secs(t0 + p * 0.03)
                y[s0:s0 + k] += np.sin(2 * np.pi * f * tt) * np.hanning(k) * r.uniform(0.3, 0.6)
            t0 += 1.0 / rate + r.uniform(-0.1, 0.1)
    y = fold(y, L)
    y += lp(noise(L), 600) * 0.03                # warm night air
    return y


def sfx_alarm_clock():
    """An 80s digital clock radio alarm: beep-beep-beep-beep, pause, again."""
    n = secs(3.4)
    t = tvec(n)
    y = np.zeros(n)
    for group in range(3):
        for b in range(4):
            at = group * 1.1 + b * 0.12
            s0 = secs(at)
            k = secs(0.07)
            y[s0:s0 + k] += square(2900, k, 0.5) * np.minimum(1, np.minimum(tvec(k), 0.07 - tvec(k)) * 400)
    return lp(y, 7000) * 0.8


def sfx_page_flip():
    n = secs(0.5)
    t = tvec(n)
    env = np.exp(-((t - 0.16) / 0.07) ** 2)
    return bp(noise(n), 1500, 9000) * env * (1 + 0.5 * np.sin(2 * np.pi * 35 * t))


def sfx_pencil():
    """Pencil scratching on paper, with little pauses (loops)."""
    L = secs(4.0)
    y = np.zeros(L)
    r = np.random.default_rng(11)
    t0 = 0.05
    while t0 < 3.8:
        dur = r.uniform(0.15, 0.45)
        k = secs(dur)
        tt = tvec(k)
        stroke = bp(noise(k), 2500, 9000) * (0.6 + 0.4 * np.sin(2 * np.pi * r.uniform(6, 11) * tt)) ** 2
        s0 = secs(t0)
        y[s0:s0 + k] += stroke * np.hanning(k)
        t0 += dur + r.uniform(0.05, 0.35)
    return y


def sfx_knock():
    """Three knocks on a wooden front door."""
    n = secs(1.3)
    y = np.zeros(n)
    for at in (0.0, 0.22, 0.44):
        s0 = secs(at)
        k = secs(0.25)
        tt = tvec(k)
        hit = resonator(np.concatenate([[1.0], np.zeros(k - 1)]), 180, 6) * 3
        hit += resonator(np.concatenate([[1.0], np.zeros(k - 1)]), 520, 10)
        hit += lp(noise(k), 2500) * np.exp(-tt * 120) * 0.6
        y[s0:s0 + k] += hit * np.exp(-tt * 18)
    return y


def sfx_mailbox():
    """A metal mailbox door: creak open, rustle of mail, clank shut."""
    n = secs(1.8)
    y = np.zeros(n)
    c = creak(secs(0.45), 260, 420, 9)
    y[:len(c)] += bp(c, 1500, 6000) * 0.5
    s0 = secs(0.5)
    k = secs(0.6)
    y[s0:s0 + k] += bp(noise(k), 2000, 8000) * np.hanning(k) * 0.25          # paper rustle
    s1 = secs(1.25)
    k = secs(0.4)
    tt = tvec(k)
    clank = (np.sin(2 * np.pi * 1850 * tt) + 0.7 * np.sin(2 * np.pi * 2760 * tt) + 0.4 * np.sin(2 * np.pi * 4100 * tt))
    y[s1:s1 + k] += clank * np.exp(-tt * 14) * 0.5 + lp(noise(k), 3000) * np.exp(-tt * 80) * 0.6
    return y


def sfx_birds():
    """A summer morning: a few different birds chirping (loops)."""
    L = secs(12.0)
    y = np.zeros(L + secs(1.0))
    r = np.random.default_rng(23)
    songs = [  # (base freq, notes per call, note length, sweep)
        (3200, 4, 0.07, 900), (2400, 2, 0.16, -700), (4100, 6, 0.04, 400), (2800, 3, 0.11, 1300)]
    for f0, notes, dur, sweep in songs:
        t0 = r.uniform(0, 2.0)
        while t0 < 11.5:
            for i in range(notes):
                k = secs(dur)
                tt = tvec(k)
                f = f0 * r.uniform(0.95, 1.05) + sweep * (tt / dur)
                note = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.hanning(k)
                s0 = secs(t0 + i * dur * 1.3)
                y[s0:s0 + k] += note * r.uniform(0.25, 0.5)
            t0 += r.uniform(2.0, 4.5)
    y = fold(y, L)
    y += lp(noise(L), 900) * 0.025             # a breeze
    return y


# ---------------------------------------------------------------- v1.0.5: kitchen, fun, cars, menus

def sfx_microwave():
    """The microwave running: a low hum with the turntable rattle (loops)."""
    L = secs(4.0)
    t = tvec(L)
    hum = sine(120, L) * 0.5 + sine(240, L) * 0.25 + sine(360, L) * 0.1
    fan = lp(noise(L), 1200) * 0.18
    rattle = bp(noise(L), 1800, 4000) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.5 * t)) * 0.05
    return hum + fan + rattle


def sfx_microwave_beep():
    n = secs(1.6)
    y = np.zeros(n)
    for i in range(3):
        s0 = secs(i * 0.5)
        k = secs(0.25)
        y[s0:s0 + k] += square(2000, k, 0.5) * np.minimum(1, np.minimum(tvec(k), 0.25 - tvec(k)) * 300) * 0.6
    return lp(y, 6000)


def sfx_popcorn():
    """Popcorn popping inside the microwave (loops)."""
    L = secs(5.0)
    y = np.zeros(L + secs(0.2))
    r = np.random.default_rng(31)
    for _ in range(70):
        at = r.uniform(0, 5.0)
        k = secs(0.04)
        s0 = secs(at)
        tt = tvec(k)
        y[s0:s0 + k] += bp(noise(k), 600, 3500) * np.exp(-tt * 140) * r.uniform(0.4, 1.0)
    y = fold(y, L)
    hum = np.tile(sfx_microwave(), 2)[:L]
    return y + hum * 0.5


def sfx_water():
    """A running kitchen faucet (loops)."""
    L = secs(4.0)
    t = tvec(L)
    y = bp(noise(L), 400, 6000) * (0.8 + 0.2 * np.sin(2 * np.pi * 3.1 * t))
    y += bp(noise(L), 2500, 9000) * 0.3
    return y


def sfx_sizzle():
    """Something frying (loops)."""
    L = secs(4.0)
    r = np.random.default_rng(13)
    y = hp(noise(L), 2500) * 0.4
    crackle = np.zeros(L)
    for _ in range(160):
        s0 = r.integers(0, L - 400)
        crackle[s0:s0 + 300] += bp(noise(300), 3000, 9000) * np.exp(-tvec(300) * 300) * r.uniform(0.3, 1)
    return y * (0.8 + 0.2 * np.sin(2 * np.pi * 0.7 * tvec(L))) + crackle


def sfx_vinyl():
    """Record crackle and a needle in the groove (loops), under the music."""
    L = secs(1.8)   # 33 1/3 rpm: one turn every 1.8 seconds
    r = np.random.default_rng(5)
    y = lp(noise(L), 3000) * 0.04
    for _ in range(40):
        s0 = r.integers(0, L - 200)
        y[s0:s0 + 120] += hp(noise(120), 2000) * np.exp(-tvec(120) * 900) * r.uniform(0.2, 0.8)
    s0 = secs(0.9)                 # the scratch that comes round every turn
    y[s0:s0 + 400] += bp(noise(400), 1000, 5000) * np.exp(-tvec(400) * 200)
    return y


def sfx_basketball():
    """Dribbling a basketball on the driveway (loops)."""
    L = secs(2.4)
    y = np.zeros(L + secs(0.3))
    for at in (0.0, 0.6, 1.2, 1.8):
        k = secs(0.25)
        tt = tvec(k)
        s0 = secs(at)
        y[s0:s0 + k] += (sine(95 * (1 + np.exp(-tt * 30)), k) * np.exp(-tt * 20) + lp(noise(k), 2000) * np.exp(-tt * 90) * 0.5)
    return fold(y, L)


def sfx_engine():
    """An idling 80s V8 (loops). The game raises its pitch as the car speeds up."""
    L = secs(2.0)
    t = tvec(L)
    f = 34.0
    pulses = np.zeros(L)
    period = int(SR / f)
    r = np.random.default_rng(3)
    for i in range(0, L, period):
        k = min(period, L - i)
        pulses[i:i + k] += np.exp(-tvec(k) * 60) * r.uniform(0.8, 1.0)
    y = lp(pulses, 400, 2) * 3.0 + sine(f * 2, L) * 0.2 + lp(noise(L), 700) * 0.15
    y = np.tanh(y * 1.5)
    return y * (1 - 0.05 * np.sin(2 * np.pi * 0.5 * t))


def sfx_horn():
    n = secs(0.7)
    t = tvec(n)
    y = (saw(350, n) + saw(440, n) * 0.8)
    y = bp(y, 300, 2500) * np.minimum(1, np.minimum(t * 60, (0.7 - t) * 30))
    return np.tanh(y * 2)


def sfx_car_door():
    n = secs(0.8)
    t = tvec(n)
    y = latch(n, 0.0) * 0.8
    s0 = secs(0.12)
    tt = tvec(n - s0)
    y[s0:] += sine(80, n - s0) * np.exp(-tt * 18) + bp(noise(n - s0), 300, 3000) * np.exp(-tt * 40) * 0.6
    y += clink(n, 0.13, 2600, 0.15)
    return y


def sfx_car_bump():
    n = secs(0.6)
    tt = tvec(n)
    y = sine(60, n) * np.exp(-tt * 12) + lp(noise(n), 1500) * np.exp(-tt * 30) * 0.8
    y += bp(noise(n), 1500, 5000) * np.exp(-tt * 25) * 0.3
    return y


def sfx_ui_move():
    n = secs(0.06)
    return square(1400, n, 0.5) * np.exp(-tvec(n) * 60) * 0.4


def sfx_ui_select():
    n = secs(0.35)
    y = np.zeros(n)
    for i, f in enumerate((880, 1320)):
        s0 = secs(i * 0.07)
        k = n - s0
        y[s0:] += square(f, k, 0.5) * np.exp(-tvec(k) * 14) * 0.35
    return lp(y, 5000)


def sfx_cash_register():
    """Ka-ching: keys, the drawer sliding out, and the bell."""
    n = secs(1.2)
    y = np.zeros(n)
    for i in range(3):
        y += click(n, 0.02 + i * 0.07, 0.6)
    s0 = secs(0.25)
    k = n - s0
    tt = tvec(k)
    y[s0:] += bp(noise(k), 200, 2000) * np.exp(-tt * 9) * 0.5 * (tt < 0.25)
    s1 = secs(0.3)
    k1 = n - s1
    t1 = tvec(k1)
    for f, a in ((2093, 0.6), (2637, 0.4), (4186, 0.2)):
        y[s1:] += sine(f, k1) * np.exp(-t1 * 5) * a
    return y


def sfx_arcade_game():
    """A chiptune arcade game: square-wave melody, bass and laser blips (loops)."""
    L = secs(4.0)
    y = np.zeros(L + secs(0.3))
    step = 0.125
    mel = [76, 79, 83, 79, 76, 74, 72, 74, 76, 79, 84, 83, 79, 76, 74, 71,
           72, 76, 79, 76, 72, 71, 69, 71, 72, 76, 81, 79, 76, 74, 72, 71]
    for i, m in enumerate(mel):
        k = secs(step * 0.9)
        y[secs(i * step):secs(i * step) + k] += square(mtof(m), k, 0.25) * np.exp(-tvec(k) * 6) * 0.25
    for i in range(16):
        m = [45, 45, 52, 52, 48, 48, 43, 43][i % 8]
        k = secs(0.24)
        y[secs(i * 0.25):secs(i * 0.25) + k] += square(mtof(m), k, 0.5) * 0.18
    r = np.random.default_rng(8)
    for _ in range(10):
        s0 = secs(r.uniform(0, 3.8))
        k = secs(0.12)
        f = np.linspace(1800, 300, k)
        y[s0:s0 + k] += square(f, k, 0.5) * 0.12
    return fold(y, L)


def sfx_doorbell():
    """Ding-dong."""
    n = secs(2.2)
    y = np.zeros(n)
    for at, f in ((0.0, 659.0), (0.55, 523.0)):
        s0 = secs(at)
        k = n - s0
        tt = tvec(k)
        y[s0:] += (sine(f, k) + sine(f * 2.76, k) * 0.25) * np.exp(-tt * 2.2)
    return y


def sfx_tape_rewind():
    """A VCR rewinding a tape, then the clunk."""
    n = secs(2.0)
    t = tvec(n)
    f = 300 + 900 * np.minimum(1, t / 0.3)
    y = bp(saw(f, n) * 0.3 + noise(n) * 0.2, 200, 3000) * (t < 1.6) * np.minimum(1, (1.6 - t) * 20)
    y += click(n, 1.65, 1.0) + lp(noise(n), 800) * np.exp(-np.maximum(0, t - 1.65) * 40) * (t > 1.65) * 0.6
    return y


def sfx_firework():
    """A rocket's whistle, a deep boom, then crackles."""
    n = secs(3.2)
    t = tvec(n)
    y = np.zeros(n)
    up = t < 0.6
    y += sine(1800 + 1400 * t, n) * up * 0.12 * np.minimum(1, t * 8)
    k = n - secs(0.6)
    tt = tvec(k)
    boom = lp(noise(k), 180) * np.exp(-tt * 3.5) * 2.5 + sine(55, k) * np.exp(-tt * 5) * 0.8
    y[secs(0.6):] += boom
    rng = np.random.default_rng(4)
    for _ in range(60):
        at = 0.9 + rng.random() * 1.9
        y += click(n, at, 0.25 * rng.random())
    return y


def sfx_bark():
    """Woof! Woof!"""
    n = secs(0.9)
    y = np.zeros(n)
    for at in (0.0, 0.4):
        s0 = secs(at)
        k = secs(0.22)
        tt = tvec(k)
        f = 420 - 180 * tt / 0.22
        y[s0:s0 + k] += bp(saw(f, k) + noise(k) * 0.4, 250, 1800) * np.exp(-tt * 9) * np.minimum(1, tt * 60)
    return y


def sfx_meow():
    """Mrrr-OW."""
    n = secs(0.8)
    t = tvec(n)
    f = 550 + 350 * np.sin(np.minimum(1, t / 0.7) * np.pi)
    y = bp(saw(f, n) * 0.6 + sine(f * 2, n) * 0.3, 400, 3000) * np.sin(np.minimum(1, t / 0.75) * np.pi)
    return y


def sfx_light_switch():
    """The click of a wall switch."""
    n = secs(0.25)
    return click(n, 0.01, 1.0) + click(n, 0.03, 0.5)


def sfx_siren():
    """A police / fire siren: a rising and falling wail (loops)."""
    L = secs(3.0)
    t = tvec(L)
    f = 700 + 450 * (0.5 - 0.5 * np.cos(2 * np.pi * t / 3.0))
    ph = 2 * np.pi * np.cumsum(f) / SR
    y = np.sin(ph) * 0.55 + np.sign(np.sin(ph)) * 0.12 + np.sin(ph * 2) * 0.12
    return bp(y, 400, 4000) * 0.9


def sfx_glass_break():
    """A window breaking: a crack, then tinkling shards."""
    n = secs(1.6)
    t = tvec(n)
    y = hp(noise(n), 2500) * np.exp(-t * 18) * 1.2 + lp(noise(n), 900) * np.exp(-t * 30) * 0.8
    r = np.random.default_rng(12)
    for _ in range(40):
        at = 0.05 + r.random() * 1.3
        y += clink(n, at, r.uniform(2500, 6500), 0.08 + r.random() * 0.12)
    return y


def sfx_milk_clink():
    """Glass milk bottles set down on a porch: clink, clink."""
    n = secs(0.9)
    y = np.zeros(n)
    for at, f in ((0.0, 2200), (0.08, 2900), (0.35, 2500), (0.42, 3300)):
        y += clink(n, at, f, 0.5)
    return y


def sfx_mower():
    """A push lawn mower: a buzzy little two-stroke engine (loops)."""
    L = secs(2.0)
    t = tvec(L)
    f = 46.0
    pulses = np.zeros(L)
    period = int(SR / f)
    for i in range(0, L, period):
        k = min(period, L - i)
        pulses[i:i + k] += np.exp(-tvec(k) * 120)
    y = bp(pulses, 80, 2500) * 2.0 + bp(noise(L), 1500, 5000) * 0.1
    y = np.tanh(y * 2.0) * (1 - 0.06 * np.sin(2 * np.pi * 3 * t))
    return y * 0.7


def sfx_bike_bell():
    """Ring-ring!"""
    n = secs(1.0)
    y = np.zeros(n)
    for at in (0.0, 0.18):
        s0 = secs(at)
        k = n - s0
        tt = tvec(k)
        y[s0:] += (sine(2900, k) + sine(4100, k) * 0.5 + sine(5700, k) * 0.25) * np.exp(-tt * 7) * 0.5
    return y


def sfx_splash():
    """A cannonball into the pool."""
    n = secs(1.4)
    t = tvec(n)
    y = lp(noise(n), 1200) * np.exp(-t * 4) * 1.3 + bp(noise(n), 2000, 7000) * np.exp(-t * 6) * 0.5
    y += sine(90, n) * np.exp(-t * 14) * 0.8
    r = np.random.default_rng(5)
    for _ in range(25):
        y += clink(n, 0.2 + r.random() * 1.0, r.uniform(600, 1600), 0.05)
    return y


def sfx_whistle():
    """The coach's whistle: two sharp blasts."""
    n = secs(1.1)
    t = tvec(n)
    gate = ((t < 0.3) | ((t > 0.45) & (t < 0.95))).astype(float)
    trill = 1 + 0.03 * np.sign(np.sin(2 * np.pi * 28 * t))
    y = (sine(2800 * trill, n) + bp(noise(n), 2400, 3400) * 0.25) * gate
    return lp(y, 7000) * 0.6


def sfx_school_bell():
    """The school bell: a long electric ring."""
    n = secs(2.2)
    t = tvec(n)
    hammer = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 22 * t))
    y = (sine(1200, n) + sine(1850, n) * 0.6 + sine(3300, n) * 0.3) * hammer * (t < 1.9) * np.minimum(1, (1.95 - t) * 10)
    return np.tanh(y * 0.8) * 0.7


def sfx_trash():
    """Garbage cans dragged down the driveway, then a lid clank."""
    n = secs(1.8)
    t = tvec(n)
    y = bp(noise(n), 200, 2000) * (t < 1.2) * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * t)) * 0.5
    s0 = secs(1.3)
    k = n - s0
    tt = tvec(k)
    y[s0:] += (sine(420, k) + sine(1130, k) * 0.6) * np.exp(-tt * 9) * 0.6 + bp(noise(k), 800, 5000) * np.exp(-tt * 30) * 0.4
    return y


NEW_SFX = ("siren", "glass_break", "milk_clink", "mower", "bike_bell", "splash", "whistle", "school_bell", "trash")


# =============================================================== v1.6.0: the mall, the bowling alley, the weather...

def sfx_coin():
    """A quarter dropping into a payphone."""
    n = secs(0.6)
    y = clink(n, 0.0, 2600, 0.5) + clink(n, 0.09, 3100, 0.35) + clink(n, 0.2, 1800, 0.3)
    t = tvec(n)
    y += bp(noise(n), 300, 1200) * np.exp(-np.maximum(t - 0.25, 0) * 30) * (t > 0.25) * 0.3
    return y


def sfx_phone_ring():
    """An old phone's bell: brrring brrring."""
    n = secs(2.4)
    t = tvec(n)
    gate = ((t < 0.9) | ((t > 1.3) & (t < 2.2))).astype(float)
    hammer = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 20 * t))
    y = (sine(1180, n) + sine(1760, n) * 0.6 + sine(2950, n) * 0.25) * hammer * gate
    return lp(np.tanh(y), 6000) * 0.6


def _beat_loop(bpm, bars, pattern, bass=None):
    beat = 60.0 / bpm
    n = secs(bars * 4 * beat)
    buf = np.zeros((n + secs(1.0), 2))
    for bar in range(bars):
        for step in range(16):
            at = secs((bar * 4 + step / 4.0) * beat)
            if pattern["k"][step] == "x":
                add(buf, at, kick(), 1.0)
            if pattern["s"][step] == "x":
                add(buf, at, snare(), 0.7)
            if pattern["h"][step] == "x":
                add(buf, at, hat(), 0.25, 0.3)
            if bass and bass[bar % len(bass)][step] is not None:
                add(buf, at, bass_note(bass[bar % len(bass)][step], beat * 0.45), 0.55)
    return fold(buf, n)


def sfx_boombox():
    """A boombox on somebody's shoulder: a fresh beat with a bass line (loops)."""
    pat = {"k": "x.....x...x.....", "s": "....x.......x...", "h": "x.x.x.x.x.x.x.xx"}
    b1 = [36, None, None, 36, None, None, 39, None, 36, None, None, 34, None, None, 31, None]
    b2 = [41, None, None, 41, None, None, 43, None, 41, None, None, 39, None, None, 36, None]
    y = _beat_loop(96, 4, pat, [b1, b1, b2, b1])
    # through a little speaker
    return lp(hp(y, 120), 4500) * 0.9


def sfx_bowling():
    """A ball rolling down the lane, then the crash of pins (loops, while bowling)."""
    n = secs(5.0)
    t = tvec(n)
    roll = lp(noise(n), 260, 3) * (0.5 + 0.5 * np.sin(2 * np.pi * 3.0 * t)) * np.clip((t - 0.3) * 3, 0, 1) * (t < 2.6) * 2.2
    y = roll + sine(55, n) * (t < 2.6) * np.clip((t - 0.3) * 3, 0, 1) * 0.3
    y += _pins(n, 2.6)
    return y


def _pins(n, at):
    y = np.zeros(n)
    r = np.random.default_rng(int(at * 100))
    for _ in range(14):
        y += clink(n, at + r.random() * 0.35, r.uniform(700, 2400), 0.25)
    s0 = secs(at)
    k = n - s0
    y[s0:] += bp(noise(k), 400, 4000) * np.exp(-tvec(k) * 9) * 0.8
    return y


def sfx_bowling_pins():
    n = secs(1.4)
    return _pins(n, 0.02)


def sfx_bowling_strike():
    """STRIKE: the pins crash, and a little celebration jingle."""
    n = secs(2.2)
    y = _pins(n, 0.02) * 1.2
    for k, m in enumerate([72, 76, 79, 84]):
        s0 = secs(0.5 + k * 0.12)
        b = bell_note(m, 1.0)
        y[s0:s0 + len(b)] += b[: n - s0] * 0.35
    return y


def sfx_rain():
    """Steady rain, with drips (loops)."""
    n = secs(6.0)
    t = tvec(n)
    y = lp(hp(noise(n), 400), 5000) * 0.35 + lp(noise(n), 700) * 0.25
    r = np.random.default_rng(9)
    for _ in range(180):
        y += clink(n, r.random() * 5.9, r.uniform(2500, 6000), r.uniform(0.02, 0.08))
    return fold(np.stack([y, np.roll(y, 1700)], axis=1), n)


def sfx_sprinkler():
    """A lawn sprinkler: tick-tick-tick and the hiss of the spray (loops)."""
    n = secs(2.4)
    t = tvec(n)
    y = hp(noise(n), 1800) * (0.25 + 0.1 * np.sin(2 * np.pi * 0.5 * t))
    for k in range(16):
        y += click(n, k * 0.15, 0.5)
    return y


def sfx_carnival():
    """A carnival organ playing a waltz (loops)."""
    bpm = 150
    beat = 60.0 / bpm
    bars = 8
    n = secs(bars * 3 * beat)
    buf = np.zeros((n + secs(1.5), 2))
    melody = [72, 76, 79, 81, 79, 76, 74, 77, 81, 79, 77, 74, 72, 76, 79, 84, 83, 79, 77, 74, 71, 74, 72, None]
    roots = [48, 48, 50, 50, 48, 48, 43, 48]
    for bar in range(bars):
        r = roots[bar]
        add(buf, secs(bar * 3 * beat), _organ(r, beat * 0.9), 0.5, -0.2)
        for b in (1, 2):
            for m in (r + 16, r + 19):
                add(buf, secs((bar * 3 + b) * beat), _organ(m, beat * 0.5), 0.22, 0.2)
        for b in range(3):
            m = melody[(bar * 3 + b) % len(melody)]
            if m is not None:
                add(buf, secs((bar * 3 + b) * beat), _organ(m, beat * 0.85, bright=True), 0.4)
    return fold(buf, n)


def _organ(m, dur, bright=False):
    n = secs(dur + 0.08)
    f = mtof(m)
    y = square(f, n, 0.5) * 0.5 + sine(f * 2, n) * 0.4 + sine(f * 4, n) * (0.25 if bright else 0.1)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 6 * tvec(n))
    y *= vib
    return lp(y, 4200 if bright else 2200) * env_adsr(n, 0.01, 0.1, 0.8, 0.05, dur)


def sfx_circus():
    """An oom-pah circus march with a snare roll under it (loops)."""
    bpm = 168
    beat = 60.0 / bpm
    bars = 8
    n = secs(bars * 4 * beat)
    buf = np.zeros((n + secs(1.5), 2))
    melody = [76, 75, 76, 72, 74, 72, 71, 72, 79, 78, 79, 76, 77, 76, 74, 72, 76, 75, 76, 72, 74, 76, 77, 79, 81, 79, 77, 76, 74, 71, 72, None]
    roots = [36, 43, 36, 43, 41, 36, 43, 36]
    for bar in range(bars):
        r = roots[bar]
        for b in range(4):
            at = secs((bar * 4 + b) * beat)
            if b % 2 == 0:
                add(buf, at, bass_note(r if b == 0 else r + 7, beat * 0.6), 0.6)
            else:
                for m in (r + 24, r + 28, r + 31):
                    add(buf, at, _organ(m, beat * 0.4), 0.18, 0.3)
            m2 = melody[(bar * 4 + b) % len(melody)]
            if m2 is not None:
                add(buf, at, lead_note(m2, beat * 0.8), 0.32, -0.1)
            add(buf, at + secs(beat * 0.5), hat(), 0.12)
        add(buf, secs(bar * 4 * beat), snare(), 0.25)
    return fold(buf, n)


NEW_SFX_16 = ("coin", "phone_ring", "boombox", "bowling", "bowling_pins", "bowling_strike", "rain", "sprinkler", "carnival", "circus")


# =============================================================== v1.7.0: schools, and real shows on the TV

def _mono(y):
    y = np.asarray(y)
    return y.mean(axis=1) if y.ndim == 2 else y


def _tv(y, hiss=0.01):
    """Through a little TV speaker: no lows, no highs, a bit of grit and broadcast hiss."""
    y = _mono(y)
    y = bp(y, 220, 5000, 2)
    y = np.tanh(y * 1.6)
    return y + hp(noise(len(y)), 3000) * hiss


def _song(bpm, bars, chords, melody, lead=None, drums=None, bass_style="root", pad=True, beats=4, lead_gain=0.4):
    """A little loop: chords (one per bar: [midi notes]), a melody (per beat, None = rest), drums pattern (16 steps)."""
    beat = 60.0 / bpm
    n = secs(bars * beats * beat)
    buf = np.zeros((n + secs(1.5), 2))
    lead = lead or lead_note
    for bar in range(bars):
        ch = chords[bar % len(chords)]
        t0 = secs(bar * beats * beat)
        if pad:
            for m in ch:
                add(buf, t0, pad_note(m, beats * beat * 0.95, 6), 0.16, 0.2)
        if bass_style == "root":
            for b in range(beats):
                add(buf, secs((bar * beats + b) * beat), bass_note(ch[0] - 12, beat * 0.8), 0.45)
        elif bass_style == "walk":
            for b, iv in enumerate((0, 4, 7, 9)[:beats]):
                add(buf, secs((bar * beats + b) * beat), bass_note(ch[0] - 12 + iv, beat * 0.8), 0.45)
        elif bass_style == "eighths":
            for b in range(beats * 2):
                add(buf, secs((bar * beats + b * 0.5) * beat), bass_note(ch[0] - 12 + (12 if b % 4 == 3 else 0), beat * 0.4), 0.45)
        if drums:
            for step in range(4 * beats):
                at = secs((bar * beats + step / 4.0) * beat)
                if drums["k"][step % 16] == "x":
                    add(buf, at, kick(), 0.9)
                if drums["s"][step % 16] == "x":
                    add(buf, at, snare(), 0.55)
                if drums["h"][step % 16] == "x":
                    add(buf, at, hat(), 0.2, 0.3)
        for b in range(beats):
            m = melody[(bar * beats + b) % len(melody)]
            if m is not None:
                add(buf, secs((bar * beats + b) * beat), lead(m, beat * 0.85), lead_gain, -0.1)
    return fold(buf, n)


ROCK = {"k": "x.......x.x.....", "s": "....x.......x...", "h": "x.x.x.x.x.x.x.x."}
DISCO = {"k": "x...x...x...x...", "s": "....x.......x...", "h": "..x...x...x...x."}
MARCH = {"k": "x.......x.......", "s": "x.x.x.xxx.x.x.xx", "h": "................"}


def sfx_tv_gameshow():
    """A game show: a big brassy fanfare, then dings and an audience clapping."""
    y = _song(140, 4, [[60, 64, 67], [65, 69, 72], [67, 71, 74], [60, 64, 67]],
              [72, 76, 79, 84, 81, 79, 77, 76, 74, 77, 81, 79, 84, None, 84, None], drums=DISCO, bass_style="walk")
    y = _mono(y)
    t = tvec(len(y))
    for k in range(6):                                            # ding ding ding!
        at = secs(0.4 + k * 1.1)
        d = bell_note(96, 0.5)
        y[at:at + len(d)] += d * 0.35
    clap = bp(noise(len(y)), 900, 4000) * (0.5 + 0.5 * np.sin(2 * np.pi * 7 * t) ** 2) * (np.sin(2 * np.pi * t / len(y) * SR) > 0.3)
    return _tv(y + clap * 0.18)


def sfx_tv_news():
    """The evening news: a serious synth theme with a ticking clock, then a voice-ish murmur."""
    y = _song(108, 4, [[57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 56, 59]],
              [76, None, 74, 72, 74, None, 72, 69, 71, None, 72, 74, 76, None, None, None], lead=bell_note, bass_style="eighths", lead_gain=0.5)
    y = _mono(y)
    t = tvec(len(y))
    tick = np.zeros(len(y))
    for k in range(int(len(y) / SR * 2)):
        at = secs(k * 0.5)
        c = click(secs(0.03), 0, 0.6)
        tick[at:at + len(c)] += c
    voice = bp(noise(len(y)), 300, 2400) * (0.5 + 0.5 * np.sin(2 * np.pi * 3.1 * t)) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.7 * t))
    return _tv(y * 0.8 + tick * 0.3 + voice * 0.12 * (t > len(y) / SR * 0.5))


def sfx_tv_sitcom():
    """A sitcom: a bouncy slap-bass theme, and the studio audience laughing."""
    y = _mono(_song(124, 4, [[60, 64, 67, 71], [57, 60, 64, 67], [62, 65, 69, 72], [55, 59, 62, 65]],
                    [79, 76, 77, 79, None, 74, 72, None, 77, 74, 76, 72, 74, None, None, None], drums=DISCO, bass_style="walk"))
    t = tvec(len(y))
    laugh = np.zeros(len(y))
    for at_s in (2.5, 6.0, 9.5, 13.0):
        n = secs(1.6)
        tt = tvec(n)
        l = bp(noise(n), 500, 3000) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 6 * tt))) * np.exp(-tt * 1.6)
        at = secs(at_s % (len(y) / SR))
        laugh[at:at + n] += l[: len(laugh) - at]
    return _tv(y * 0.7 + laugh * 0.5)


def sfx_tv_soap():
    """A soap opera: a weepy organ, very dramatic."""
    y = _song(70, 4, [[57, 60, 64], [53, 57, 60], [50, 53, 57], [52, 56, 59]],
              [76, 77, 76, 72, 74, 72, 71, 69, 72, 74, 76, 79, 76, None, None, None],
              lead=lambda m, d: _organ(m, d * 1.1, bright=True), bass_style="root", lead_gain=0.45)
    return _tv(y)


def sfx_tv_cops():
    """A cop show: a driving synth bass, a synth riff, and a siren in the distance."""
    y = _mono(_song(128, 4, [[52, 55, 59], [52, 55, 59], [48, 52, 55], [50, 54, 57]],
                    [76, None, 76, 79, 76, None, 74, 71, 72, None, 72, 76, 74, None, 71, None], drums=ROCK, bass_style="eighths", pad=False))
    t = tvec(len(y))
    siren = sine(700 + 250 * np.sin(2 * np.pi * 0.6 * t), len(y)) * (0.25 + 0.2 * np.sin(2 * np.pi * 0.1 * t))
    return _tv(y + siren * 0.15)


def sfx_tv_music():
    """The music video channel: a big synth-pop song."""
    y = _song(118, 4, [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]],
              [76, 76, 74, 72, 72, 74, 76, 79, 77, 76, 74, 72, 71, 72, 74, None], drums=DISCO, bass_style="eighths")
    return _tv(y, 0.006)


def sfx_tv_sports():
    """A ballgame: the crowd, the stadium organ, the crack of the bat."""
    n = secs(12)
    t = tvec(n)
    crowd = lp(noise(n), 1500) * (0.6 + 0.3 * np.sin(2 * np.pi * 0.13 * t))
    cheer = bp(noise(n), 400, 3000) * np.exp(-np.maximum(t - 5.0, 0) * 1.2) * (t > 5.0)
    bat = np.zeros(n)
    c = click(secs(0.08), 0, 1.0)
    bat[secs(4.9):secs(4.9) + len(c)] += c * 2.0
    org = _mono(_song(150, 2, [[60, 64, 67], [55, 59, 62]], [67, 72, 76, 79, None, 76, 79, None], lead=lambda m, d: _organ(m, d, True), pad=False, bass_style="none"))
    o = np.zeros(n)
    o[:min(n, len(org))] += org[:n] * (t[:min(n, len(org))] < 4.5)
    return _tv(crowd * 0.35 + cheer * 0.6 + bat + o * 0.5)


def sfx_tv_parade():
    """The parade on TV: a marching band, snare and all."""
    y = _song(116, 4, [[60, 64, 67], [65, 69, 72], [67, 71, 74], [60, 64, 67]],
              [72, 72, 74, 76, 77, 77, 76, 74, 76, 79, 77, 76, 74, 72, 72, None], drums=MARCH, bass_style="root", pad=False,
              lead=lambda m, d: _organ(m, d, True))
    return _tv(y)


def sfx_tv_action():
    """An action movie: pounding drums, a power-chord riff, laser zaps."""
    y = _mono(_song(140, 4, [[50, 57, 62], [50, 57, 62], [48, 55, 60], [53, 60, 65]],
                    [74, None, 74, 77, 79, None, 77, 74, 72, None, 72, 74, 77, None, 74, None], drums=ROCK, bass_style="eighths", pad=False))
    t = tvec(len(y))
    zaps = np.zeros(len(y))
    for k in range(5):
        n = secs(0.25)
        tt = tvec(n)
        z = sine(1800 * np.exp(-tt * 12) + 200, n) * np.exp(-tt * 10)
        at = secs(1.3 + k * 2.7)
        if at + n < len(zaps):
            zaps[at:at + n] += z
    return _tv(y + zaps * 0.4)


def sfx_tv_horror():
    """A scary movie: a low drone, heartbeats, and a shriek of violins now and then."""
    n = secs(12)
    t = tvec(n)
    drone = lp(saw(55, n) + saw(55.7, n), 400) * 0.4
    heart = np.zeros(n)
    for k in range(10):
        for d in (0.0, 0.22):
            at = secs(k * 1.2 + d)
            c = kick()
            if at + len(c) < n:
                heart[at:at + len(c)] += c * (0.6 if d else 0.8)
    stab = np.zeros(n)
    for at_s in (5.5, 10.2):
        m = secs(0.8)
        tt = tvec(m)
        st = (saw(880 + 40 * np.sin(2 * np.pi * 9 * tt), m) + saw(932, m)) * np.exp(-tt * 3)
        stab[secs(at_s):secs(at_s) + m] += hp(st, 1200)
    wind = bp(noise(n), 300, 900) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.21 * t))
    return _tv(drone + heart * 0.5 + stab * 0.35 + wind * 0.2)


def sfx_tv_scifi():
    """A space movie: a twinkly arpeggio, a big pad, and spaceship whooshes."""
    y = _mono(_song(110, 4, [[57, 64, 69], [53, 60, 65], [55, 62, 67], [52, 59, 64]],
                    [81, 76, 84, 76, 81, 77, 84, 77, 79, 74, 83, 74, 76, 71, 80, 71], lead=lambda m, d: arp_note(m, d), lead_gain=0.3, bass_style="root"))
    t = tvec(len(y))
    whoosh = bp(noise(len(y)), 600, 3000) * np.maximum(0, np.sin(2 * np.pi * t / 6.0)) ** 4
    return _tv(y + whoosh * 0.35)


def sfx_tv_comedy():
    """A goofy comedy: a tuba and a kazoo-ish melody, with a slide whistle."""
    y = _mono(_song(132, 4, [[60, 64, 67], [55, 59, 62], [57, 60, 64], [55, 59, 62]],
                    [72, 74, 76, 72, 79, None, 77, 76, 74, 72, 71, 74, 72, None, 67, None],
                    lead=lambda m, d: lp(square(mtof(m), secs(d + 0.05), 0.2), 2500) * env_adsr(secs(d + 0.05), 0.01, 0.1, 0.8, 0.05, d),
                    bass_style="walk", pad=False))
    t = tvec(len(y))
    n = secs(0.7)
    tt = tvec(n)
    slide = sine(500 + 800 * tt / 0.7, n) * np.hanning(n)
    y[secs(3.5):secs(3.5) + n] += slide * 0.4
    return _tv(y)


def sfx_piano():
    """A few bars on the school piano (a little out of tune)."""
    notes = [(60, 0), (64, 0.3), (67, 0.6), (72, 0.9), (67, 1.2), (64, 1.5), (65, 1.8), (69, 2.1), (72, 2.4), (69, 2.7), (67, 3.0), (64, 3.3), (60, 3.6)]
    n = secs(5.0)
    y = np.zeros(n)
    for m, at in notes:
        k = bell_note(m, 1.2) * 0.6 + bell_note(m + 0.12, 1.2) * 0.4
        s0 = secs(at)
        y[s0:s0 + len(k)] += k[: n - s0]
    return lp(y, 5000)


def sfx_xylophone():
    """Bonk, bink, bonk: a run up the xylophone."""
    n = secs(2.2)
    y = np.zeros(n)
    for i, m in enumerate([72, 74, 76, 77, 79, 81, 83, 84]):
        k = secs(0.4)
        tt = tvec(k)
        note = (sine(mtof(m), k) + 0.3 * sine(mtof(m) * 4, k) * np.exp(-tt * 40)) * np.exp(-tt * 12)
        s0 = secs(i * 0.16)
        y[s0:s0 + k] += note
    return y


def sfx_band():
    """The middle school band: a march, a little ragged (loops)."""
    y = _song(112, 4, [[58, 62, 65], [63, 67, 70], [65, 69, 72], [58, 62, 65]],
              [70, 70, 72, 74, 75, 74, 72, 70, 72, 74, 75, 77, 79, None, 77, None], drums=MARCH, bass_style="root", pad=False,
              lead=lambda m, d: _organ(m + 0.15 * np.sin(m), d, True))
    return lp(_mono(y), 6000)


def sfx_typing():
    """A room full of typewriters, and the DING at the end of a line (loops)."""
    n = secs(6.0)
    y = np.zeros(n)
    r = np.random.default_rng(7)
    at = 0.0
    while at < 5.8:
        c = click(secs(0.05), 0, r.uniform(0.6, 1.0))
        s0 = secs(at)
        y[s0:s0 + len(c)] += lp(c, 4000)
        at += r.uniform(0.07, 0.2)
    for d_at in (2.9, 5.6):
        d = bell_note(100, 0.6)
        y[secs(d_at):secs(d_at) + len(d)] += d[: n - secs(d_at)] * 0.5
    return y


NEW_SFX_17 = ("tv_gameshow", "tv_news", "tv_sitcom", "tv_soap", "tv_cops", "tv_music", "tv_sports", "tv_parade",
              "tv_action", "tv_horror", "tv_scifi", "tv_comedy", "piano", "xylophone", "band", "typing")


def main():
    import sys
    only = sys.argv[1:]
    if only:
        for name in only:
            save(name, globals()["sfx_" + name]())
        return
    print("Composing the house music…")
    save("music_house", make_song(), peak=0.8)
    print("Sound effects:")
    save("tv_on", sfx_tv_on())
    save("tv_off", sfx_tv_off())
    save("tv_show", sfx_tv_show())
    save("door_open", sfx_door_open())
    save("door_close", sfx_door_close())
    save("fridge_open", sfx_fridge_open())
    save("fridge_close", sfx_fridge_close())
    save("snore", sfx_snore())
    save("phone_dial", sfx_phone_dial())
    save("phone_talk", sfx_phone_talk())
    save("phone_busy", sfx_phone_busy())
    save("phone_hangup", sfx_phone_hangup())
    save("memory_chime", sfx_memory())
    save("door_locked", sfx_door_locked())
    save("crickets", sfx_crickets())
    save("alarm_clock", sfx_alarm_clock())
    save("page_flip", sfx_page_flip())
    save("pencil", sfx_pencil())
    save("knock", sfx_knock())
    save("mailbox", sfx_mailbox())
    save("birds", sfx_birds())
    for name in ("microwave", "microwave_beep", "popcorn", "water", "sizzle", "vinyl", "basketball",
                 "engine", "horn", "car_door", "car_bump", "ui_move", "ui_select",
                 "cash_register", "arcade_game", "doorbell", "tape_rewind", "firework", "bark", "meow",
                 "light_switch") + NEW_SFX + NEW_SFX_16 + NEW_SFX_17:
        save(name, globals()["sfx_" + name]())


if __name__ == "__main__":
    main()
