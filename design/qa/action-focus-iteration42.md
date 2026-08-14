# Iteration 42 — Shake/Seal Action Focus

Date: 2026-08-10

## Problem

The 800-pixel preparation panel was authored for multi-choice ingredient grids. The shake step reused it with one 220-pixel button pinned to the left, leaving most of the panel empty. After sealing, the same panel remained as a title over an empty body even though the next decision had moved to the order cards. This hid the upper shop shelf during the moment when the player should visually confirm the finished cup and delivery target.

## Accepted flow

- The shake/seal action is a 300-pixel centered button inside the existing panel, so a single action reads as a deliberate focal step rather than the first cell of a missing grid.
- Sealing clears the choice controls and hides the preparation panel in 0.10 seconds. The bottom instruction and current-cup summary remain visible, while the complete 3D shelf and all order cards are exposed.
- Starting a new cup restores the panel with a 0.12-second fade.
- Reduced-motion mode skips both fades and switches visibility immediately.
- Gamepad mode focuses the current order after sealing; keyboard continues to support the numbered order shortcuts, and touch keeps the active-card border without forcing a focus ring.

## Rejected state and bug fix

The first sealed screenshot revealed that the transparent full-card `Button` inherited the global filled focus style. Once gamepad focus moved to the order, a solid coral rectangle covered the title, components, progress and patience bar. The order overlay now has a dedicated four-pixel mint focus `StyleBoxFlat` with `draw_center = false`. The active coral card border remains visible behind it, so selection and input focus are redundant without obscuring content.

## Visual evidence

- `iteration42-action-focus/01-shake-centered-en.png` — centered English gamepad shake action.
- `iteration42-action-focus/03-sealed-order-focus-en-final.png` — hidden panel plus readable border-only gamepad order focus.
- `iteration42-action-focus/04-sealed-touch-zh.png` — hidden panel and active-card-only touch state.
- `iteration42-action-focus/05-sealed-touch-mobile.png` — accepted sealed composition on Forward Mobile.

## Automated evidence

`input_check.tscn` completes the real shake count, proves the cup seals, proves the preparation panel is hidden, verifies gamepad focus moves to the active order, checks the focus style has no center fill and retains a four-pixel border, then resets the cup and proves preparation controls return.

The final routed Day 10/max-upgrade/three-customer Mobile stress scene remains at 59,324 triangles and 195 surfaces. The latest sample measured 328 maximum draw calls and 128.14 MiB against budgets of 120,000 / 200 / 360 / 160 MiB. All 24 guarded check scenes pass. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
