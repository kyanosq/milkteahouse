# Iteration 28 — Research Growth and Affinity Notebook

Date: 2026-08-10

## Outcome

Repeated night experiments now create visible long-term progress even when they do not discover a recipe. The existing recipe journal has a third bilingual growth page combining a 3×4 tea/milk affinity notebook with ingredient mastery.

## Implemented rules

- Three tea bases and four milk choices create exactly 12 affinity cells.
- The first valid night trial using a pair reveals its rating and signed affinity score; repeats are idempotent.
- Ratings reuse the production affinity rules: clash wins when clash is non-zero and at least as strong as synergy; otherwise synergy 6+ is Perfect, positive synergy is Good, and zero is Neutral.
- Completing 12/12 permanently adds two inspiration to each newly initialized night budget. The final reveal also refunds two inspiration immediately.
- Fourteen usable ingredients expose Lv1–5 mastery. Every eight XP advances one level; Lv3+ applies the production `RecipeLab` main-flavor +1 effect.
- Save v13 persists only validated unique `base|milk` keys. Old saves start with an empty notebook while retaining all previous progress and ingredient XP.

## Visual QA

Initial 1280 × 720 capture showed the entire matrix but only the mastery heading. Matrix headers and rows were compacted while preserving 200 px cell width and readable type. The accepted composition shows the matrix, mastery completion count and first five XP cards simultaneously; the next-row edge and scrollbar communicate additional content.

- `iteration28-research-growth/01-research-notebook-zh.png`
- `iteration28-research-growth/02-research-notebook-en.png`

Both languages fit without clipping, mixed-language keys or horizontal scrolling. Unknown cells remain color-independent through `?` and explicit try-tonight copy; seen cells combine rank text, score and border color.

## Regression evidence

`research_progress_check.tscn` verifies 12 keys, representative Perfect/Good/Neutral/Clash cases, idempotent discovery, invalid-key rejection, completion bonus, Lv1/Lv3/Lv5 progression, panel population and bilingual refresh. Night tests verify real-trial discovery, persistent budget resume, completed-notebook start bonus and same-night final-cell refund. Save migration verifies v13 validation and deduplication.

All 21 project regression scenes passed. Godot editor import/compile passed. The real player save remained unchanged at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

## Balance judgment

The reward is deliberately one extra trial per night after twelve distinct experiments. It does not increase daytime revenue, arrival pressure or recipe prices, so it cannot erase the shop-upgrade economy. Human campaign sessions should still observe whether players understand the Lv3 flavor change and whether filling all 12 cells feels exploratory rather than mandatory.
