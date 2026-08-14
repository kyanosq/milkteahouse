# Desktop Release Settings QA — Iteration 17

Date: 2026-08-09  
Target: player-controlled desktop display modes, safe resolution choices and persistent keyboard remapping.

## Delivered settings

The shared pause/settings surface now contains a focused `显示与按键` subpage available from the title screen, day shop and night laboratory.

Display choices:

- windowed;
- borderless desktop window;
- fullscreen;
- 1280 × 720, 1440 × 900, 1600 × 900, 1920 × 1080 and 2560 × 1440 windowed resolutions.

Resolution is disabled outside windowed mode because fullscreen and borderless modes inherit the current display. Windowed sizes are centered on the active monitor. Changes save and apply immediately in a real game session; `GameState.test_mode` deliberately suppresses desktop window mutation during screenshots and automated checks.

Keyboard remapping covers the three gameplay-specific actions:

- pause/settings;
- shake tea;
- interact with staff.

The capture flow shows `等待输入…`, accepts one ordinary keyboard key, allows Escape to cancel, rejects modifier-only keys and prevents duplicate action conflicts with a named explanation. `恢复默认按键` restores Esc / Space / F. Gamepad remains on the predictable A/B/X/Y/Menu contract.

## Persistence and migration

- Older saves adopt `windowed`, `1280x720` and Esc/Space/F without losing their audio or accessibility values.
- Invalid window modes and resolutions fall back safely.
- Invalid, modifier-only or duplicate stored key maps normalize to the complete default set.
- New Game and New Shop+ preserve display, input, audio and reduced-motion preferences while clearing progression.
- Main-menu startup applies the saved desktop mode before building the interactive menu; tests bypass this side effect.

## Visual acceptance

- `iteration17-settings/01-menu-settings-entry.png`: the existing audio/accessibility page retains its hierarchy and gains one secondary entry action.
- `iteration17-settings/02-display-and-bindings.png`: the 640 × 540 advanced page fits all selectors, bindings and reset/back actions at 1280 × 720.
- `iteration17-settings/03-day-settings-entry.png`: the largest day variant still fits without clipping.
- `iteration17-settings/04-display-ultrawide.png`: advanced settings remain centered while the scrim covers the full 1920 × 720 viewport.
- `iteration17-settings/05-night-settings-entry.png`: the compact night variant remains readable and preserves its research CTA.

During QA, the advanced panel initially expanded to 1323 px after its first visibility change despite a 540 px minimum. A deferred refit now resets and locks it to 640 × 540 after container sorting; automated acceptance guards that exact size.

## Automated acceptance

`release_settings_check.tscn` verifies:

- three window modes and five resolution entries;
- safe resolution parsing and fallback;
- immediate setting-state updates without changing the test machine window;
- a real InputMap rebind from Space to R;
- duplicate conflict rejection and Escape cancellation;
- default-key restoration;
- advanced-page enter/back flow and exact 640 × 540 geometry;
- preference preservation across progression reset.

The complete release-settings/input/audio/menu/onboarding/night/campaign/event/staff/upgrade/model suite passes, including warning-free shutdown. The real save SHA-256 remained `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

## Remaining platform work

The desktop settings path is complete. Remaining release work is platform export smoke testing, save-version fixtures, localization extraction and measured mobile draw-call/memory/thermal profiling. PlayStation/Nintendo-specific glyph art can be layered on the existing device router later.
