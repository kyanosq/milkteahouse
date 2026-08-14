# MilkTeaHouse Original Audio

All music and sound effects in this folder's generated output are original procedural synthesis created for this project. They contain no third-party samples, recordings, or copyrighted melodies.

- Source of truth: `generate_audio.py`
- Deterministic seed: `4804`
- Master format: stereo PCM WAV, 44.1 kHz / 16-bit
- Runtime music: Ogg Vorbis, quality 5
- Runtime SFX: stereo PCM WAV

Regenerate with the bundled NumPy-capable Python, then convert `masters/*.wav` into `game/assets/music/*.ogg` with ffmpeg. Runtime track names and SFX keys are asserted by `game/tests/audio_check.gd`.

## Runtime integration

- `game/autoload/sfx.gd` owns two reusable music decks and the bounded SFX pool.
- Scene routing keys are `menu`, `day`, `night`, and `campaign`.
- Programmatic `Music` and `SFX` buses use independent values from `GameState.settings`.
- Music defaults to 55%; SFX defaults to 75%. Legacy `sound_volume` saves migrate to the SFX value.
- Music crossfades over 0.8 seconds. Important results temporarily duck the Music bus.
- SFX concurrency is capped at 12 players, with cooldowns on frequently repeated cues.

Run the automated acceptance test with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --audio-driver Dummy --path game res://tests/audio_check.tscn
```
