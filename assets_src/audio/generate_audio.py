#!/usr/bin/env python3
"""Deterministically synthesize MilkTeaHouse's original music and SFX library.

No samples or third-party recordings are used. Run with the bundled Codex Python
(NumPy required), then convert music WAV masters to OGG with ffmpeg.
"""
from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np

SR = 44_100
ROOT = Path(__file__).resolve().parents[2]
SFX_DIR = ROOT / "game/assets/sfx"
MUSIC_DIR = ROOT / "game/assets/music"
MASTER_DIR = Path(__file__).resolve().parent / "masters"
RNG = np.random.default_rng(4804)


def midi(note: float) -> float:
    return 440.0 * 2.0 ** ((note - 69.0) / 12.0)


def envelope(size: int, attack: float, release: float, decay: float = 0.0) -> np.ndarray:
    env = np.ones(size, dtype=np.float64)
    a = min(size, int(attack * SR))
    r = min(size, int(release * SR))
    if a:
        env[:a] = np.linspace(0.0, 1.0, a, endpoint=False)
    if decay > 0.0:
        env *= np.exp(-np.arange(size) / SR * decay)
    if r:
        env[-r:] *= np.linspace(1.0, 0.0, r)
    return env


def pan(signal: np.ndarray, position: float) -> np.ndarray:
    angle = (np.clip(position, -1.0, 1.0) + 1.0) * math.pi / 4.0
    return np.column_stack((signal * math.cos(angle), signal * math.sin(angle)))


def tone(freq: float, duration: float, kind: str = "mallet") -> np.ndarray:
    n = max(1, int(duration * SR))
    t = np.arange(n) / SR
    if kind == "mallet":
        sig = np.sin(2 * np.pi * freq * t) + 0.32 * np.sin(2 * np.pi * freq * 2.01 * t)
        sig += 0.12 * np.sin(2 * np.pi * freq * 3.98 * t)
        sig *= envelope(n, 0.006, min(0.16, duration * 0.5), 3.4)
    elif kind == "pluck":
        sig = np.sin(2 * np.pi * freq * t) + 0.22 * np.sin(2 * np.pi * freq * 2 * t)
        sig += 0.08 * RNG.normal(size=n)
        sig *= envelope(n, 0.003, min(0.12, duration * 0.45), 5.3)
    elif kind == "epiano":
        sig = np.sin(2 * np.pi * freq * t) + 0.20 * np.sin(2 * np.pi * freq * 2 * t + 0.3)
        sig *= 0.94 + 0.06 * np.sin(2 * np.pi * 4.2 * t)
        sig *= envelope(n, 0.018, min(0.35, duration * 0.35), 0.52)
    elif kind == "pad":
        sig = sum(np.sin(2 * np.pi * freq * ratio * t + phase) for ratio, phase in [(0.997, 0.1), (1.0, 0.8), (1.004, 1.6)]) / 3.0
        sig += 0.12 * np.sin(2 * np.pi * freq * 0.5 * t)
        sig *= envelope(n, min(0.45, duration * 0.25), min(0.55, duration * 0.3), 0.03)
    elif kind == "bass":
        sig = np.sin(2 * np.pi * freq * t) + 0.22 * np.sin(2 * np.pi * freq * 2 * t)
        sig *= envelope(n, 0.012, min(0.20, duration * 0.4), 1.2)
    elif kind == "sine":
        sig = np.sin(2 * np.pi * freq * t) * envelope(n, 0.005, min(0.15, duration * 0.5), 1.0)
    else:
        raise ValueError(kind)
    return sig


def add_note(track: np.ndarray, start: float, duration: float, note: float, amp: float, kind: str, position: float = 0.0) -> None:
    begin = int(start * SR)
    sample = pan(tone(midi(note), duration, kind) * amp, position)
    end = min(track.shape[0], begin + sample.shape[0])
    if begin < track.shape[0] and end > begin:
        track[begin:end] += sample[: end - begin]


def add_noise_hit(track: np.ndarray, start: float, duration: float, amp: float, position: float = 0.0, bright: bool = True) -> None:
    n = max(1, int(duration * SR))
    noise = RNG.normal(size=n)
    if bright:
        noise = np.concatenate(([noise[0]], np.diff(noise)))
    else:
        kernel = np.ones(28) / 28.0
        noise = np.convolve(noise, kernel, mode="same")
    noise *= envelope(n, 0.001, duration * 0.8, 12.0) * amp
    begin = int(start * SR)
    end = min(track.shape[0], begin + n)
    if begin < track.shape[0]:
        track[begin:end] += pan(noise[: end - begin], position)


def master(audio: np.ndarray, peak: float = 0.82, fade: float = 0.025) -> np.ndarray:
    audio = np.tanh(audio * 1.15)
    nfade = min(audio.shape[0] // 2, int(fade * SR))
    if nfade:
        ramp = np.linspace(0.0, 1.0, nfade)
        audio[:nfade] *= ramp[:, None]
        audio[-nfade:] *= ramp[::-1, None]
    current = float(np.max(np.abs(audio))) or 1.0
    return np.clip(audio * (peak / current), -1.0, 1.0)


def write_wav(path: Path, audio: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (master(audio) * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as out:
        out.setnchannels(2)
        out.setsampwidth(2)
        out.setframerate(SR)
        out.writeframes(pcm.tobytes())


def music_track(name: str, bpm: float, bars: int, progression: list[tuple[int, ...]], melody: list[int], mood: str) -> None:
    beat = 60.0 / bpm
    duration = bars * 4 * beat
    track = np.zeros((round(duration * SR), 2), dtype=np.float64)
    for bar in range(bars):
        chord = progression[bar % len(progression)]
        start = bar * 4 * beat
        if mood == "day":
            for note in chord:
                add_note(track, start, 3.85 * beat, note, 0.075, "pad", -0.22)
            for b in range(4):
                add_note(track, start + b * beat, 0.72 * beat, chord[0] - 12, 0.13, "bass", -0.05)
                add_noise_hit(track, start + b * beat + 0.5 * beat, 0.055, 0.017, 0.65)
            for step in range(8):
                note = melody[(bar * 8 + step) % len(melody)]
                add_note(track, start + step * beat / 2, 0.42 * beat, note, 0.11 if step % 2 == 0 else 0.075, "mallet", 0.36)
        elif mood == "night":
            for note in chord:
                add_note(track, start, 3.9 * beat, note, 0.085, "pad", -0.30)
            add_note(track, start, 1.7 * beat, chord[0] - 12, 0.12, "bass", -0.10)
            add_note(track, start + 2 * beat, 1.7 * beat, chord[0] - 5, 0.10, "bass", -0.10)
            for step in [0, 2, 5, 7]:
                note = melody[(bar * 4 + [0, 2, 5, 7].index(step)) % len(melody)]
                add_note(track, start + step * beat / 2, 1.15 * beat, note, 0.095, "epiano", 0.28)
            add_noise_hit(track, start + 2 * beat, 0.10, 0.012, 0.55, False)
        elif mood == "menu":
            for note in chord:
                add_note(track, start, 3.9 * beat, note, 0.065, "pad", -0.20)
            for step in [0, 3, 4, 6]:
                note = melody[(bar * 4 + [0, 3, 4, 6].index(step)) % len(melody)]
                add_note(track, start + step * beat / 2, 0.8 * beat, note, 0.095, "pluck", 0.32)
            add_note(track, start, 1.2 * beat, chord[0] - 12, 0.09, "bass", -0.15)
        else:  # campaign
            for note in chord:
                add_note(track, start, 3.9 * beat, note, 0.09, "pad", -0.25)
            for step in range(4):
                note = melody[(bar * 4 + step) % len(melody)]
                add_note(track, start + step * beat, 0.9 * beat, note, 0.12, "mallet", 0.30)
            add_note(track, start, 1.5 * beat, chord[0] - 12, 0.11, "bass", -0.05)
            if bar % 4 == 3:
                for i, note in enumerate(chord):
                    add_note(track, start + (3.0 + i * 0.18) * beat, 0.7 * beat, note + 12, 0.065, "epiano", 0.45)
    write_wav(MASTER_DIR / f"{name}.wav", track)


def sweep(duration: float, start_hz: float, end_hz: float, amp: float = 0.3) -> np.ndarray:
    n = int(duration * SR)
    t = np.arange(n) / SR
    phase = 2 * np.pi * (start_hz * t + (end_hz - start_hz) / (2 * duration) * t * t)
    return np.sin(phase) * envelope(n, 0.004, duration * 0.65, 2.0) * amp


def sfx(name: str, duration: float, builder) -> None:
    track = np.zeros((int(duration * SR), 2), dtype=np.float64)
    builder(track)
    write_wav(SFX_DIR / f"{name}.wav", track)


def make_sfx() -> None:
    sfx("select", 0.11, lambda x: add_note(x, 0, 0.10, 76, 0.22, "sine", 0.15))
    sfx("ui_open", 0.18, lambda x: [add_note(x, i * 0.035, 0.14, n, 0.17, "sine", 0.1) for i, n in enumerate([67, 72, 76])])
    sfx("ui_close", 0.16, lambda x: [add_note(x, i * 0.035, 0.13, n, 0.15, "sine", -0.1) for i, n in enumerate([76, 72, 67])])
    sfx("pour_tea", 0.62, lambda x: [add_noise_hit(x, 0.03 + i * 0.07, 0.18, 0.035, -0.3 + i * 0.08, False) for i in range(7)])
    sfx("pour_milk", 0.68, lambda x: [add_noise_hit(x, 0.02 + i * 0.08, 0.21, 0.030, 0.3 - i * 0.07, False) for i in range(7)])
    sfx("topping", 0.24, lambda x: [add_note(x, 0.015 + i * 0.045, 0.16, 49 - i, 0.16, "pluck", -0.25 + i * 0.25) for i in range(3)])
    sfx("sugar", 0.24, lambda x: [add_note(x, 0, 0.17, 64, 0.14, "sine"), add_noise_hit(x, 0.08, 0.08, 0.04, 0.2)])
    sfx("shake", 0.105, lambda x: add_noise_hit(x, 0, 0.10, 0.10, float(RNG.uniform(-0.35, 0.35))))
    sfx("seal", 0.18, lambda x: [add_noise_hit(x, 0, 0.055, 0.13, -0.1), add_note(x, 0.04, 0.13, 57, 0.12, "pluck", 0.1)])
    sfx("serve", 0.34, lambda x: [add_note(x, i * 0.055, 0.26, n, 0.15, "mallet", -0.2 + i * 0.2) for i, n in enumerate([72, 76, 79])])
    sfx("coin", 0.24, lambda x: [add_note(x, i * 0.045, 0.18, n, 0.18, "mallet", 0.15) for i, n in enumerate([84, 91])])
    sfx("combo", 0.58, lambda x: [add_note(x, i * 0.075, 0.42, n, 0.17, "mallet", -0.3 + i * 0.2) for i, n in enumerate([72, 76, 79, 84])])
    sfx("bad", 0.42, lambda x: [add_note(x, i * 0.08, 0.30, n, 0.18, "sine", 0) for i, n in enumerate([58, 55, 51])])
    sfx("discover", 0.82, lambda x: [add_note(x, i * 0.10, 0.62, n, 0.15, "mallet", -0.35 + i * 0.18) for i, n in enumerate([67, 72, 76, 79, 84])])
    sfx("customer_arrive", 0.28, lambda x: [add_note(x, i * 0.055, 0.22, n, 0.13, "pluck", 0.25) for i, n in enumerate([69, 74, 76])])
    sfx("customer_leave", 0.34, lambda x: [add_note(x, i * 0.07, 0.25, n, 0.13, "sine", -0.25) for i, n in enumerate([69, 65, 62])])
    sfx("staff_alert", 0.46, lambda x: [add_note(x, i * 0.11, 0.26, n, 0.16, "sine", 0.28) for i, n in enumerate([66, 61, 66])])
    sfx("staff_wake", 0.38, lambda x: [add_note(x, i * 0.06, 0.28, n, 0.16, "mallet", 0.24) for i, n in enumerate([67, 72, 79])])
    sfx("lab_stir", 0.55, lambda x: [add_noise_hit(x, i * 0.08, 0.22, 0.025, -0.25 + i * 0.08, False) for i in range(6)])


def main() -> None:
    for directory in (SFX_DIR, MUSIC_DIR, MASTER_DIR):
        directory.mkdir(parents=True, exist_ok=True)
    day_chords = [(60, 64, 67, 71), (57, 60, 64, 67), (53, 57, 60, 64), (55, 59, 62, 64)]
    night_chords = [(57, 60, 64, 69), (53, 57, 60, 64), (60, 64, 67, 71), (55, 59, 62, 69)]
    music_track("day_coral_market", 96, 16, day_chords, [72, 76, 79, 76, 74, 72, 69, 67, 72, 74, 76, 79, 81, 79, 76, 74], "day")
    music_track("night_mint_lab", 76, 12, night_chords, [69, 72, 76, 71, 69, 67, 64, 67, 72, 71, 69, 64], "night")
    music_track("menu_teahouse", 84, 8, day_chords, [72, 76, 79, 83, 81, 79, 76, 72], "menu")
    music_track("campaign_cup_of_stars", 88, 12, day_chords, [72, 76, 79, 84, 83, 79, 76, 74, 72, 74, 76, 79], "campaign")
    make_sfx()
    print(f"Generated 4 music masters and {len(list(SFX_DIR.glob('*.wav')))} SFX at {SR} Hz stereo.")


if __name__ == "__main__":
    main()
