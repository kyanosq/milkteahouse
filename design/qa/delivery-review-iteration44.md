# Iteration 44 — Cross-Input Delivery Review

Date: 2026-08-10

## Problem

Gamepad users could move focus between sealed order cards, inspect the cup comparison, and then press A to deliver. Pointer, touch and number-key users delivered immediately on the first press of any card, so switching targets gave them no chance to inspect the same mismatch feedback. Identical gameplay therefore assigned accidental mistakes differently by input device.

## Accepted rule

- The currently reviewed order remains fast: one confirmation delivers.
- Selecting a different sealed order by click, tap or number key changes the reviewed target without consuming the cup. Its active border and component comparison update immediately.
- A second confirmation on that current target delivers and retains every normal success or wrong-cup consequence.
- Gamepad behavior remains focus-to-review, A-to-deliver; pointer and keyboard now use the same semantic sequence.
- Sealed inactive cards say `Review Order / 核对订单`; only the current card says `Deliver Here / 交付到此`.
- Tutorial, seal feedback and bottom next-action copy explain review then confirmation in both languages.

## Visual evidence

- `iteration44-delivery-review/01-current-gamepad-en.png` — current English gamepad card offers delivery while the other two offer review.
- `iteration44-delivery-review/02-cross-order-review-zh.png` — after a pointer target change, order 2 owns the current border and coral `! 0/4` comparison while the sealed cup remains intact.
- `iteration44-delivery-review/03-mobile-stress.png` — accepted Forward Mobile Day 10/max-upgrade/three-customer frame.

## Automated evidence

`input_check.tscn` now proves gamepad focus, pointer click and the `1` number shortcut can change a sealed target without delivery; it checks the active/inactive hint swap, then confirms a deliberately wrong reviewed order and verifies the cup resets and patience penalty still applies. Localization coverage guards all four review/delivery variants and onboarding remains green.

The Forward Mobile stress scene measured 59,324 triangles, 195 surfaces, 326 maximum draw calls and 128.08 MiB against budgets of 120,000 / 200 / 360 / 160 MiB. All 24 guarded check scenes pass. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
