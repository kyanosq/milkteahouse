# Iteration 45 — Clean Craft, Rework and Priced Discard

Date: 2026-08-10

## Problem

Before this iteration, every finally correct recipe counted as Perfect even after repeated wrong selections and corrections. It granted the same inspiration and combo as a clean build. The reset button also erased any started cup for free. Perfect rate therefore collapsed into served rate, the combo did not measure execution mastery, and the operating ledger could be bypassed whenever a player noticed an error early.

## Accepted rules

- Replacing an already selected tea or milk, changing a confirmed sugar level, or removing an added topping marks one rework.
- A matching reworked cup still sells at full price and keeps its normal tip, event and staff rewards. Precision/Trend route rewards remain independently eligible; the Turnover route's explicitly combo-based third-cup payout resets with the combo. It does not add Perfect or the base one inspiration.
- A matching cup with zero reworks remains a clean build and receives the existing Perfect/inspiration/combo path.
- The sealed status says `Clean Build / 无返工` or `Reworked ×N / 返工 ×N` before delivery.
- The reset button is disabled on an empty cup. Once ingredients are committed it previews the exact wholesale loss; player-initiated discard adds that amount once to stock and waste.
- Internal resets used for day start, automatic target changes and post-delivery cleanup remain free.

## Visual evidence

- `iteration45-clean-craft/01-clean-build-en.png` — correct 5/5 sealed cup, `Clean Build`, and visible ¥4 discard alternative.
- `iteration45-clean-craft/02-reworked-build-zh.png` — the same final 5/5 recipe after one correction, visibly marked `返工 ×1` with the same ¥4 discard cost.
- `iteration45-clean-craft/04-tutorial-step3-en.png` and `05-tutorial-step3-zh.png` — accepted 720p onboarding copy in both languages without overflow.
- `iteration45-clean-craft/03-mobile-stress.png` — accepted Forward Mobile Day 10/max-upgrade/three-customer frame.

## Automated evidence

`input_check.tscn` proves a wrong-then-corrected base increments the visible rework state and that a new cup clears it. `operating_cost_check.tscn` builds and successfully delivers a corrected matching drink, then proves served increments while Perfect, inspiration and a two-cup combo do not. The same test discards a started cup and verifies stock/waste rise by the visible cost exactly once and the empty reset control disables. Localization coverage guards every status, action and reward key.

The Forward Mobile stress scene measured 59,324 triangles, 195 surfaces, 327 maximum draw calls and 128.14 MiB against budgets of 120,000 / 200 / 360 / 160 MiB. All 24 guarded check scenes pass. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
