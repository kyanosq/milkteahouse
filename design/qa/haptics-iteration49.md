# Iteration 49 — Semantic Haptics and Feedback Settings

Date: 2026-08-10

## Gap closed

The GDD promised a light mobile vibration for moment-to-moment preparation, but the playable project had no haptic API calls. Feedback was therefore weaker on touch devices and controllers, while adding calls directly to individual scenes would have made intensity, rate limiting and user preference inconsistent.

## Implementation

`autoload/haptics.gd` is now the single semantic feedback route. Gameplay sends one of six named outcomes; the manager selects the authored profile, suppresses repeated bursts of the same type, and routes it to the active connected gamepad or handheld vibration API.

| Profile | Duration | Handheld amplitude | Purpose |
|---|---:|---:|---|
| `tap` | 18 ms | 0.18 | ingredient and recipe-tile selection |
| `shake` | 22 ms | 0.22 | accepted shake cadence |
| `confirm` | 46 ms | 0.46 | seal and trial confirmation |
| `success` | 76 ms | 0.66 | delivery and completed objective |
| `warning` | 112 ms | 0.92 | incomplete, wrong or destructive action |
| `discover` | 148 ms | 0.78 | legendary/dark recipe discovery |

Cooldowns range from 42 ms for taps to 220 ms for discoveries. This keeps rapid ingredient input and shake presses readable instead of becoming a continuous buzz. Controller feedback uses independent weak/strong motor values; handheld feedback uses duration and amplitude.

The persistent `Haptic Feedback / 触觉反馈` switch is available from both the title settings and in-game pause panel. Enabling it previews a confirmation pulse. It is independent from Music, SFX and Reduce Motion, and its bilingual tooltip explains that disabling vibration does not alter sound or animation.

Save schema v20 stores `settings.haptics`. Old or incomplete saves migrate to the safe default `true`; new-game/reset preserves the player's setting.

## Automated coverage

- `input_check.tscn` records semantic events without touching physical hardware, verifies gamepad routing, same-frame tap rate limiting, shake coalescing, seal confirmation and wrong-delivery warning.
- `release_settings_check.tscn` verifies disabled suppression, the enable-preview pulse and preservation through progress reset.
- `save_migration_check.tscn` verifies legacy default-on migration, explicit current-save opt-out and corrupt/missing-settings recovery.
- Night regression covers the integrated selection, trial, discovery, quality and brief outcomes.
- Test mode never invokes a physical vibration API, so headless regression is deterministic and does not shake a connected user device.

## Visual acceptance

- `iteration49-haptics/01-menu-settings-en.png` — English title settings: both feedback switches fit on one row at 1280 × 720.
- `iteration49-haptics/02-day-pause-zh.png` — Chinese in-shift settings: both switches, help copy and all actions remain inside the pause panel.
- `iteration49-haptics/03-mobile-stress.png` — Forward Mobile Day 10 / max-upgrade / three-customer frame; no UI or branded Blender cup regression.

The two settings captures were inspected for clipping, overlap, control alignment and safe-frame containment. The final Mobile frame retains readable order cards, the contextual preparation panel and the complete work surface.

## Performance and final gate

Godot 4.6.3 Forward Mobile on the Apple M3 Ultra reference renderer measured 58,228 visible triangles, 194 surfaces, 326 maximum draw calls and 127.89 MiB video memory against budgets of 120,000 / 200 / 360 / 160 MiB.

All 24 guarded scenes pass: 23 headless checks plus the real Forward Mobile render. The real player save remained byte-identical before and after the suite at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

Physical intensity still requires one short Android/iOS and one representative controller feel pass before release-candidate signoff; desktop routing and semantic correctness cannot substitute for actuator feel on target hardware.
