# Iteration 40 — Contextual World Labels

Date: 2026-08-10

## Problem

The day shop already hid unrelated ingredient groups, but every label in the current group appeared at once. That duplicated the complete context-button row, left distant text clipped under the HUD and placed topping names across the rear kettles. The issue recurred on every cup and became worst on Day 10 with eight topping bins.

## Interaction rule

The context row remains the authoritative complete list for touch, keyboard and accessibility. The 3D scene now shows at most one ingredient name:

- Mouse hover on a physical prop identifies that prop.
- Mouse hover or gamepad focus on a context button identifies the matching physical prop.
- Focus has priority over button hover, which has priority over world hover.
- Leaving a target clears only that input source; a stale exit signal cannot erase a newer focus.
- Changing the recipe step clears every old source before building the next choice row.
- Touch idle shows no duplicate world label because the large context buttons already carry the complete name and icon.

Labels ignore 3D depth only while visible so the focused name cannot disappear behind the prop it describes. Screen-space controls still render later and continue to occlude the label. Topping labels were moved from alternating heights to the front face of the selected bin; the former height pattern existed only to mitigate simultaneous overlap and is no longer needed.

## Rejected states

1. Focus-only logic passed the input assertion, but the first English `Boba` label was completely hidden behind the rear kettle.
2. Disabling 3D depth made it visible, but the raised label still sat on the kettle silhouette.
3. The accepted placement lowers the single label onto the ingredient bin itself, preserving the world-to-button relationship without contaminating adjacent props.

## Evidence

- `iteration40-context-labels/01-day10-touch-clean-zh.png` — Forward+ Day 10 touch/keyboard idle with no duplicate world text.
- `iteration40-context-labels/05-day10-gamepad-focus-en-binlabel.png` — English gamepad focus on `Boba`, with exactly one synchronized label on the first bin.
- `iteration40-context-labels/06-day10-touch-clean-mobile.png` — the same dense idle state on Forward Mobile.

`input_check.tscn` now proves the first gamepad focus shows only the first tea label, moving right shows only the second, and releasing focus in keyboard mode leaves no world label. Existing language-change handling still regenerates label text from the current locale.

The routed Day 10/max-upgrade/three-customer Mobile stress scene remains at 59,324 triangles and 195 surfaces. Maximum draw calls decreased from the prior 325–326 sample to 321 because dormant label batches no longer submit; this run measured 127.12 MiB against the 160 MiB guard. All 24 guarded check scenes pass, and the real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
