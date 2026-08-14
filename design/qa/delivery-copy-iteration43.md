# Iteration 43 — State-Accurate Delivery Copy

Date: 2026-08-10

> Iteration 44 refines this rule: only the currently reviewed sealed card offers delivery; other cards now offer a non-destructive review step before confirmation.

## Problem

After a cup was sealed, pressing an order card delivered the cup immediately, but the card still said `Select as current order / 点按设为当前订单`. The UI therefore described an action that was no longer possible at the exact moment when the player was choosing a delivery target.

## Accepted behavior

- Before sealing, regular, special-customer, event and featured-menu cards retain their authored order or reward notes.
- After sealing, the currently reviewed order card describes its real action: `A · Deliver Here` in gamepad mode or `Click/Tap · Deliver Here` for pointer/touch input.
- Switching between gamepad and keyboard/mouse while a sealed cup is waiting rewrites the card hints immediately.
- Resetting the cup restores each card's original customer/menu note instead of leaving stale delivery copy.
- The global pointer instruction now uses `Click/Tap` rather than touch-only `Tap`, matching the shared PC/mobile build.

## Visual evidence

- `iteration43-delivery-copy/01-correct-gamepad-en.png` — correct sealed cup, mint 5/5 verification, border-only gamepad focus and `A · Deliver Here`.
- `iteration43-delivery-copy/02-wrong-pointer-zh.png` — wrong sealed cup, coral `! 1/5` verification and `点击 · 交付到此` without overflow.
- `iteration43-delivery-copy/03-mobile-stress.png` — accepted Forward Mobile Day 10/max-upgrade/three-customer stress frame.

## Automated evidence

`input_check.tscn` now seals a correct cup with a real X-button shake event, verifies the gamepad delivery hint, changes to pointer input and verifies the live copy update, resets and verifies the normal order hint returns, then seals a deliberately wrong cup and verifies both the mismatch state and pointer delivery action. `localization_check.tscn` guards both new English/Chinese keys.

The Forward Mobile stress scene remains at 59,324 triangles, 195 surfaces, 328 maximum draw calls and 128.14 MiB against budgets of 120,000 / 200 / 360 / 160 MiB. All 24 guarded check scenes pass. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
