# Iteration 46 — Error-Aware Craft Balance

Date: 2026-08-10

## Why the old bot was insufficient

The former newbie/regular/skilled autoplay profiles differed only in action and reading speed. All three always selected the exact recipe and never discarded a cup, so they could verify throughput but could not test the new clean-build reward. A green autoplay after Iteration 45 would therefore be indirect evidence: it said nothing about inspiration loss, visible waste or recovery after human-like corrections.

## Reproducible behavior model

`autoplay.gd` now uses a craft RNG independent from the authored order RNG and accepts `BOT_SAMPLE`:

| Profile | Rework tendency | Discard tendency | Tap / read / shake |
|---|---:|---:|---|
| Newbie | 28% | 8% | 0.90s / 2.20s / 3.0s⁻¹ |
| Regular | 12% | 3% | 0.60s / 1.40s / 4.2s⁻¹ |
| Skilled | 3% | 0% | 0.35s / 0.80s / 6.0s⁻¹ |

A rework trace deliberately pours the alternate unlocked tea and then corrects it. A discard trace pours the alternate tea, uses the real priced reset action, then restarts the same order. Output now includes perfect rate, rework count, discard count and final inspiration as well as revenue, net, star and service metrics.

## Five-sample results

Each cell is the mean of five real 120-second shop scenes. Day 5/9/12 use the matching early/mid/full upgrade package; all scenes start from the same 400-coin analysis balance so `operating net` remains directly comparable.

| Day | Profile | Stars | Served | Clean | Rework | Discard | Inspiration | Gross | Operating net |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | Newbie | 2.0 | 11.0 | 73% | 3.0 | 1.0 | 9.4 | 131 | 106 |
| 1 | Regular | 2.0 | 11.0 | 89% | 1.2 | 0.6 | 12.2 | 134 | 113 |
| 1 | Skilled | 3.0 | 11.8 | 100% | 0.0 | 0.0 | 18.6 | 150 | 122 |
| 5 | Newbie | 2.2 | 13.2 | 71% | 3.8 | 1.6 | 12.2 | 226 | 165 |
| 5 | Regular | 3.0 | 21.0 | 83% | 3.6 | 0.6 | 25.0 | 393 | 301 |
| 5 | Skilled | 3.0 | 23.0 | 98% | 0.6 | 0.0 | 32.4 | 421 | 328 |
| 9 | Newbie | 1.4 | 16.6 | 80% | 3.6 | 0.6 | 16.8 | 237 | 168 |
| 9 | Regular | 3.0 | 25.8 | 87% | 3.4 | 0.0 | 31.6 | 392 | 280 |
| 9 | Skilled | 3.0 | 40.0 | 98% | 0.8 | 0.0 | 54.6 | 671 | 514 |
| 12 | Newbie | 2.0 | 18.0 | 72% | 5.0 | 1.8 | 20.2 | 313 | 238 |
| 12 | Regular | 3.0 | 27.0 | 89% | 3.0 | 1.6 | 40.8 | 516 | 395 |
| 12 | Skilled | 3.0 | 30.0 | 98% | 0.6 | 0.0 | 49.8 | 614 | 475 |

All 60 scenes served 100% of resolved customers, had zero angry departures and positive operating net. Newbie Day 9 was the lowest star point: samples were `[1, 1, 1, 2, 2]`, gross ranged 224–246, clean rate 75–88%, and inspiration 15–19. No sampled novice run fell to zero stars or negative operation, so the clean-craft reward remains unchanged.

## Player-facing debrief

The shift result's Perfect card now explains its numerator with `clean rate · reworked cups · customers lost` instead of showing only customers lost. This closes the loop from live `Clean Build/Reworked` status to the daily result without adding another modal.

## Visual and automated evidence

- `iteration46-craft-balance/01-result-craft-en.png` and `02-result-craft-zh.png` — accepted bilingual two-line craft debrief without overflow.
- `iteration46-craft-balance/03-mobile-stress.png` — accepted Forward Mobile stress frame.
- `BOT_SAMPLE=0..4` produced 60/60 successful real-scene runs; `input_check`, `operating_cost_check` and localization continue to guard the underlying rules.

The Forward Mobile stress scene measured 59,324 triangles, 195 surfaces, 329 maximum draw calls and 127.81 MiB against budgets of 120,000 / 200 / 360 / 160 MiB. All 24 guarded check scenes pass. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
