# Audio Identity QA — Iteration 15

Date: 2026-08-09  
Target: a coherent, original, production-safe audio layer for the complete menu → day → night → campaign loop.

## Delivered identity

The game now has four deterministic, project-original themes rather than one generic background loop:

| Scene | Runtime key | Character | Duration | Integrated loudness |
| --- | --- | --- | ---: | ---: |
| Main menu | `menu` | soft pluck, pad and restrained bass | 22.86 s | -12.8 LUFS |
| Day shop | `day` | bright mallet pulse, warm pad and active bass | 40.00 s | -13.2 LUFS |
| Night lab | `night` | slower electric piano, cool pad and sparse rhythm | 37.90 s | -12.2 LUFS |
| Campaign report | `campaign` | ascending mallet motif and resolved chords | 32.73 s | -12.9 LUFS |

All four tracks and all 19 sound effects were synthesized from code with seed `4804`. They contain no external samples or borrowed melodies. Runtime music defaults to 55%, placing the musical bed near the intended gameplay range while leaving transient feedback readable.

## Interaction sound map

- Day preparation: separate tea pour, milk pour, topping drop, sugar pump, shake, seal and serve cues.
- Queue and mastery: customer arrival/departure, combo milestone, incorrect cup, staff alert and staff wake cues.
- Night research: concise tile selection, physical lab stir, discovery, failed experiment and shelving cues.
- UI: paired open/close motifs shared by menu, pause and research settings.

The implementation caps concurrent effects at 12 voices, evicts the oldest voice under burst load and applies short per-cue cooldowns to high-frequency actions. `bad`, `discover`, `combo` and `staff_alert` briefly duck the music, so important outcomes remain legible even when reduced motion disables visual punch effects.

## Runtime architecture

- `Sfx` remains the compatibility-facing autoload but now acts as an audio director.
- `Music` and `SFX` buses are created if absent and receive independent persistent volume values.
- Two persistent music decks crossfade for 0.8 seconds; the outgoing Ogg playback is stopped and released after the transition.
- Old saves containing only `sound_volume` migrate that value to `sfx_volume`; music adopts the authored 55% default.
- `stop_all()` releases active playback without unloading the cached asset library, allowing clean tests and safe reuse.

## Visual acceptance

The shared settings panel now exposes two clearly named sliders and retains reduced-motion control. All three variants fit the authored 1280 × 720 viewport with a single coral primary action:

- `iteration15-audio/01-menu-audio-settings.png`
- `iteration15-audio/02-day-audio-settings.png`
- `iteration15-audio/03-night-audio-settings.png`

## Automated acceptance

`audio_check.tscn` verifies:

- 19/19 SFX and 4/4 music resources;
- Music/SFX bus creation and exact 40% / 65% test levels;
- two-deck crossfade settling back to one playing stream;
- a 12-voice upper bound under a 19-cue burst;
- automatic effect cleanup and warning-free Ogg shutdown;
- cached resources surviving `stop_all()`.

Menu, onboarding, night and campaign tests additionally assert their scene music keys. The full audio/menu/onboarding/night/campaign/event/staff/upgrade/model suite passes. The real player save SHA-256 remained `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392` before and after verification.

## Remaining listening work

No automated test can judge fatigue or masking over an entire campaign. The next human playtest should specifically rate day-loop repetition, combo audibility during busy queues, night-theme fatigue and whether 55% music / 75% SFX are comfortable defaults on speakers and headphones.
