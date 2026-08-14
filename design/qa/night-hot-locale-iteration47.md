# Iteration 47 — Semantic Night-Lab Hot Localization

Date: 2026-08-10

## Problem

The project-wide translation table covered static controls, but the night lab kept already translated strings after a trial. Switching language in the same scene could therefore leave the result log, recipe note and formatted trial button in the previous language. Raw localized dark-menu names were also stored in save data, so a saved Chinese name could leak into an English session.

## Implementation

- Trial output is stored as semantic message keys plus typed arguments (`ingredient`, `recipe`, `affinity`, `rank`, `grade`, `brief`, `dark_menu`) and rendered only at display time.
- The persistent note card stores a semantic `legend`, `dark` or `shelf` state. Rebuilding it preserves an entered custom drink name.
- Locale change now refreshes the complete lab, re-renders the result log and visible note card, and reformats the primary trial action without replaying a trial or reward.
- Save v19 normalizes dark-menu entries to legendary recipe IDs, mystery-drink serials or a safe legacy fallback. Chinese and English legacy names migrate to the same stable entry.

## Regression coverage

`night_check.tscn` switches Chinese → English → Chinese after a real trial and asserts translated recipe/result/note/button copy while inspiration and discovery state remain unchanged. It also covers a preserved custom shelf name and semantic mystery-drink re-rendering. `save_migration_check.tscn` covers mixed legacy Chinese/English strings, semantic entries and overflow trimming.

## Visual evidence

- `iteration47-night-hot-locale/01-trial-result-en.png` — accepted English result state.
- `iteration47-night-hot-locale/02-trial-result-zh.png` — accepted Chinese result state.
- `iteration47-night-hot-locale/04-hot-switch-fixed.png` — accepted Chinese-to-English in-scene switch; the central action now reads `Trial Cup · 2 Inspiration` with no mixed language.

The first hot-switch capture exposed the untranslated primary action and was moved to `/tmp/milkteahouse-iteration47-rejected/03-hot-switch-zh-to-en.png`; it is not accepted evidence.

## Gate

All 24 guarded scenes pass after the fix. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
