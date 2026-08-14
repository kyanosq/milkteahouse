# Gamepad and Expanded-Aspect QA — Iteration 16

Date: 2026-08-09  
Target: complete controller operation and stable composition at 16:10 and 21:9 without compromising the authored 1280 × 720 layout.

## Controller contract

| Action | Keyboard / mouse | Gamepad |
| --- | --- | --- |
| Navigate UI | arrows / pointer | D-pad or left stick |
| Confirm | Enter / click | A |
| Back | Escape | B |
| Pause / settings | Escape | Menu / Start |
| Shake tea | Space | X |
| Interact with staff | F / click actor | Y |
| Fast ingredient slots | 1–9 | spatial focus + A |

`InputPrompts` creates the three gameplay-specific actions at startup and watches real key, mouse-button, joypad-button and significant axis events. Copy changes immediately between keyboard/mouse and gamepad language without reacting to harmless mouse jitter.

## Focus and flow

- Every themed button now has a 4 px mint focus ring plus restrained glow.
- Day ingredient controls automatically focus their first valid option after each recipe step.
- D-pad Right moves through the ingredient row; A invokes the same button callback as mouse/touch.
- X shakes without stealing A from normal UI confirmation.
- Order-card focus updates the active order; after sealing, the active card receives focus for A delivery.
- Night research focuses the first ingredient tile when a gamepad becomes active.
- Menu, tutorial and pause/settings copy expose the current device glyphs. Upgrade, staff and campaign surfaces already had deterministic focus entry points and inherit the new focus treatment.

## Expanded-aspect layout

The 3D scenes remain full-bleed. Foreground gameplay/UI is placed in a centered 1280 × 720 `SafeFrame`:

- 1440 × 900 (16:10): logical 1280 × 800 canvas → 40 px vertical authored-space offset.
- 1920 × 720 (21:9): 320 px horizontal offset.
- smaller viewports clamp the offset to zero, avoiding negative-position clipping.

This keeps order cards, the action bar, night shelves and the campaign report in a predictable reading zone while allowing extra shop/lab environment to appear around them. Fullscreen scrims deliberately overscan the safe frame: pause, tutorial, event, settlement, upgrade, staff and confirmation states dim the entire expanded viewport while their cards remain aligned to the authored center.

The night environment background was lifted from near-black to deep indigo, so 21:9 overscan reads as atmospheric room depth rather than accidental pillarboxing.

## Visual evidence

- Before safe framing: `iteration16-input/current-16x10.png`, `current-ultrawide.png`.
- 16:10 menu with visible A/B copy and focus: `01-menu-gamepad-16x10.png`.
- 720p controller pause copy: `02-day-gamepad-pause.png`.
- 21:9 day and night gameplay: `03-day-gamepad-ultrawide.png`, `04-night-gamepad-ultrawide.png`.
- 21:9 campaign report: `05-campaign-gamepad-ultrawide.png`.
- Full-viewport modal coverage: `06-day-pause-ultrawide.png`, `07-upgrades-ultrawide.png`.

All reviewed screenshots preserve readable text, one clear primary action, centered composition and visible controller focus. No control is clipped or stranded in the former left-aligned 1280 px region.

## Automated acceptance

`input_check.tscn` verifies:

- `game_pause`, `game_shake` and `staff_interact` mappings;
- A/B/X/Y/Menu prompt selection and keyboard restoration;
- D-pad spatial navigation to the next ingredient;
- 4 px focus treatment;
- controller X changing actual shake progress;
- controller focus selecting a different order card;
- controller copy in pause and tutorial;
- exact `SafeFrame` offsets at 1920 × 720 and logical 1280 × 800.

The complete input/audio/menu/onboarding/night/campaign/event/staff/upgrade/model suite passes without resource warnings. The real save SHA-256 remained `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

## Remaining release work

Historical note: window modes, selectable resolutions and remapping were completed in Iteration 17. Iteration 51 later replaced the Xbox-only letter contract with automatic Xbox / PlayStation / Nintendo / generic physical-position prompts without changing gameplay actions.
