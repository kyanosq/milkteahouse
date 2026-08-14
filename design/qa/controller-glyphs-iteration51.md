# Iteration 51 — Controller-Family Prompts and Active-Pad Haptics

Date: 2026-08-10

## Gap closed

The full controller flow worked, but every device displayed the Xbox `A/B/X/Y/Menu` contract. A DualSense player was told to press X when the real west button was Square; a Nintendo player saw Xbox letters that did not match the face buttons. The old Iteration 16 audit explicitly left PlayStation/Nintendo device glyphs as future work.

## Runtime routing

`autoload/input_prompts.gd` now tracks the device ID that produced the latest joypad button/axis event. Godot's SDL-normalized name, GUID and platform vendor information classify it without changing the underlying south/east/west/north action map:

| Family | Confirm | Cancel | Shake | Staff | Pause |
|---|---|---|---|---|---|
| Xbox / XInput | A | B | X | Y | Menu |
| PlayStation / DualShock / DualSense | × | ○ | □ | △ | Options |
| Nintendo / Switch / Joy-Con | B | A | Y | X | + |
| Unknown generic | South | East | West | North | Start |

Detection prefers USB vendor IDs (`045e`, `054c`, `057e`), then SDL/Godot names and the Windows `__XINPUT_DEVICE__` GUID. Unknown hardware never receives a guessed brand label.

Connecting or using a different controller while already in gamepad mode emits the same scheme-refresh signal, so title, pause/settings, tutorial, ingredient confirmation, shake, sealed-order review and delivery hints update in place. Disconnecting the active pad selects a remaining pad or falls back to pointer mode. Haptics now target this active device rather than the first connected controller.

## Font and localization

Every formerly hard-coded gamepad sentence now formats semantic prompt labels. English and Simplified Chinese share the same physical symbols and retain authored grammar.

The deterministic LXGW WenKai runtime subset was rebuilt with pinned FontTools 4.63.0. It includes `× ○ □ △`, measures 503,208 bytes, and hashes to `e0ff0a50889a23ff24612d37526349681a08f21f703c38c34d4dce99a37e5a29`. The font guard now covers 95 critical characters while preserving the 256 KiB–1 MiB budget and system fallback for player-entered names.

## Automated evidence

`input_check.tscn` verifies Xbox, DualSense, Nintendo Switch Pro and unknown-device classification plus every confirm/cancel/shake/staff/pause label. It then drives the real cup with the unchanged west-button event, opens a Chinese PlayStation pause panel, and advances the Nintendo tutorial to prove dynamic copy refreshes through live UI.

Targeted `font_asset_check`, `localization_check`, `menu_check`, `onboarding_check` and `release_settings_check` scenes pass without parser, formatting or engine errors. The complete guarded suite also passes.

## Visual acceptance

- `iteration51-controller-glyphs/01-playstation-shake-en.png` — English PlayStation Square shake action and focus ring.
- `iteration51-controller-glyphs/02-nintendo-pause-zh.png` — Chinese Nintendo `B/Y/X/+` pause guidance.
- `iteration51-controller-glyphs/03-playstation-menu-en.png` — title hint with PlayStation `×` confirm and `○` back.
- `iteration51-controller-glyphs/04-mobile-stress.png` — unchanged Day 10 / max-upgrade / three-customer Mobile frame.

All three controller captures remain inside the 1280 × 720 safe frame. Symbols use the same shipped typeface, align with adjacent labels, and do not introduce clipping or layout jumps.

## Performance and final gate

Godot 4.6.3 Forward Mobile on the Apple M3 Ultra reference renderer measured 58,228 visible triangles, 194 surfaces, 327 maximum draw calls and 127.56 MiB video memory against budgets of 120,000 / 200 / 360 / 160 MiB.

All 24 guarded scenes pass: 23 headless checks plus the real Forward Mobile render. The real player save remained byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

Native hardware smoke remains the final controller gate: test at least one Xbox, DualSense and Switch Pro/Joy-Con through Steam Input to confirm the SDL names/vendor values and preferred glyph semantics on each shipping desktop OS.
