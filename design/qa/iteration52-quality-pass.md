# Iteration 52 — Quality Pass

Date: 2026-08-13  
Status: project-side quality pass; external release gates remain open.

## Evidence boundary

The final visual audit set is stored in `design/qa/iteration52-audit` and contains nine main-path captures regenerated from the accepted code on 2026-08-13. Screenshot review cannot by itself prove save durability, focus-loop termination, safe-area behavior on hardware or deterministic campaign policy, so the automated and external evidence boundaries below still apply.

No unmeasured native-device performance or human-playtest result is claimed in this document.

## Goal

This pass closes the highest-risk project-side quality gaps before release-candidate packaging:

- prevent sealed-order focus from entering a deferred rebuild loop and exhausting the message queue;
- make primary copy and focus state readable through a consistent Cocoa contrast language;
- ensure the day HUD is populated immediately and retains a stable information hierarchy under the Day 10 Mobile stress state;
- replace direct save overwrites with validated atomic replacement and last-known-good recovery;
- make the fourteen-day balance gate independent from host render-frame timing;
- keep authored UI inside system safe areas in either landscape orientation;
- ship the font license/notices in every export and provide one canonical headless runner;
- persist the live night-research budget without refresh or loss across scene recreation and save/load.

This is a project-side quality pass, not permission to publish. Signing, target-device and human-session gates are listed at the end.

## Fixes accepted

### 1. Sealed-order focus OOM and high-contrast interaction states

The failure was caused by focus entering the already active sealed-order card, rebuilding the contextual controls, then scheduling another focus request. A rendered build could repeatedly feed `focus_entered` back into deferred UI reconstruction until the message queue was exhausted.

`game/scenes/day_shop/day_shop.gd` now treats reselecting the active customer as a no-op. Deferred focus resolves the latest active order at execution time and only calls `grab_focus()` when necessary. The regression in `game/tests/input_check.gd` switches sealed-order focus repeatedly, waits for queued requests to drain, and verifies that the cup remains sealed, the latest order remains active and controls are not rebuilt.

The main interaction language now uses Cocoa for button copy and focus outlines:

- `game/ui/app_theme.gd` defines Cocoa copy and a 4 px Cocoa focus ring for default Coral buttons;
- main-menu secondary actions, day ingredient/utility actions, sealed order cards and night secondary actions use the same high-contrast focus language;
- sealed order cards now expose tooltip, accessibility name and full-formula accessibility description instead of relying on an empty transparent button.

`input_check.tscn` guards the 4 px Cocoa focus ring, Cocoa default button copy, order-card semantic text and the rapid focus handoff that previously triggered the failure.

### 2. HUD initialization and two-level layout

`game/scenes/day_shop/day_shop.gd` now calls `_update_info()` during `_start_day()`, after day state is initialized but before the first process tick. Immediate pause, screenshot and performance harness states therefore no longer show empty metrics.

The HUD is split into two explicit levels:

1. a fixed primary row for day/time, target progress, cash/costs, inspiration, Perfect, streak and shop progression;
2. a compact status row for the event/route and optional endless contract.

Moving two-line route/event copy out of the primary `HBoxContainer` prevents it from squeezing late-game values into collapsed labels. `mobile_render_check.tscn` asserts that each guarded label has text and usable width, and that the status row ends before the preparation panel.

### 3. Atomic save, backup rotation and recovery

`game/autoload/game_state.gd` now writes JSON to a temporary path, flushes and parses it before replacement. A parseable current primary is copied to a validated temporary backup and rotated into `save.backup.json`; the verified temporary primary is then renamed into place and parsed again. A corrupt primary is never allowed to overwrite the last-known-good backup.

Loading accepts the primary when valid, otherwise loads the backup, records that recovery occurred and restores the primary. `save_migration_check.tscn` performs this durability exercise only on temporary test paths: it writes two valid snapshots, verifies rotation, truncates the primary and proves automatic recovery from the previous snapshot. It does not write the player's real save.

### 4. Fixed-step fourteen-day strategy policy gate

`game/tests/campaign_strategy_sim.gd` now owns a logical `1/30 s` clock. It disables the shop's host-driven process and advances the real production day scene and bot with the same fixed step; `CAMPAIGN_TICKS_PER_FRAME` only changes how many logical ticks are batched in one host frame. Host render delta therefore cannot change arrival, patience, staff, shake or shift-time policy.

The three final fourteen-day policies are asserted rather than merely printed:

- careful: 14 settled days, grade A, 9/10 upgrades and no angry customers;
- balanced: 14 settled days, grade S, 10/10 upgrades on Day 10 and no angry customers;
- growth: 14 settled days, grade S, 10/10 upgrades on Day 10 and no angry customers.

Each route also has a bounded final-cash assertion, so an economy change outside the accepted envelope fails the scene instead of silently changing the report.

### 5. Safe area and both landscape orientations

`game/ui/safe_frame.gd` keeps the authored 1280 × 720 UI inside the logical display safe area while allowing scene backgrounds to remain full bleed. On mobile it maps `DisplayServer.get_display_safe_area()` into logical viewport coordinates, intersects it with the viewport, scales down only when required, and centers the authored frame in the usable rectangle.

`input_check.tscn` guards ultrawide centering, extra-height centering and an asymmetric cutout/home-indicator inset. `game/project.godot` uses the orientation value guarded by `export_config_check.tscn` as allowing both landscape orientations.

### 6. License delivery and canonical runner

`game/OFL-1.1.txt` contains the full SIL Open Font License and the LXGW/Klee copyright and additional-permission notices. `game/THIRD_PARTY_NOTICES.md` identifies the shipped LXGW WenKai runtime font and points to the complete license. All four export presets explicitly include both files; `export_config_check.tscn` verifies those include filters and the required notice contents.

`tools/run_godot_checks.sh` is the canonical headless project runner. It resolves Godot consistently, creates isolated logs under `/private/tmp`, checks that all 23 configured scenes exist, runs every scene without fail-fast hiding later results, and returns non-zero when any scene fails. The rendered Mobile budget and the longer strategy policies remain explicit gates outside this fast 23-scene runner.

### 7. Capped active night budget and persistent inspiration

Save version 21 adds `night_performance_remaining` beside the existing `night_budget` and `night_budget_day`. Day performance inspiration and buzz first enter a persistent reserve. Each night loads no more than 16 active points, including the base/menu/mastery allowance, so the research session tops out at eight standard trials. Reserve that was not loaded never disappears; the unspent loaded portion is returned idempotently when the lab closes.

Every spend consumes temporary nightly allowance before touching the tracked reserve portion. Re-entering the same night restores both amounts exactly, while an older in-progress night without the new source field conservatively treats its existing budget as temporary instead of duplicating a refund. `night_resume_check.tscn` proves capped loading, spend/resume, close-time banking, idempotency and mastery refund; `save_migration_check.tscn` covers v21 persistence and safe legacy defaults.

## Main-flow health, 1–9

The status below combines the current source, automated checks and the final regenerated audit captures.

| # | Audit evidence | Health | Accepted conclusion |
|---:|---|---|---|
| 1 | `design/qa/iteration52-audit/01-main-menu.png` | Healthy | Continue/New Game hierarchy is clear; Cocoa copy and focus distinguish primary and secondary actions. |
| 2 | `design/qa/iteration52-audit/02-tutorial-shake.png` | Healthy | Tutorial blocks play safely, exposes shake alternatives and retains a singular next action. |
| 3 | `design/qa/iteration52-audit/03-live-craft.png` | Healthy | Ingredient choices are Cream by default and Coral only when selected, with distinct utility pause and destructive reset actions. |
| 4 | `design/qa/iteration52-audit/04-sealed-review.png` | Healthy | Review-before-deliver semantics, current-cup comparison and action copy are coherent. The runtime regression proves focus-loop termination. |
| 5 | `design/qa/iteration52-audit/05-day-settlement.png` | Healthy | Settlement preserves a clear result-to-next-step hierarchy and the rating/CTA now use Cocoa contrast. |
| 6 | `design/qa/iteration52-audit/06-night-lab.png` | Healthy; density watch | The Day 10 shelf is readable at 1280 × 720, the active/saved budget is explicit and secondary growth actions are visually demoted. Density remains a human-test watch item. |
| 7 | `design/qa/iteration52-audit/07-night-recipe.png` | Healthy; density watch | Selected ingredients are restated in text, the trial action remains primary and the final Day 10 density state is represented. |
| 8 | `design/qa/iteration52-audit/08-mobile-stress-hud.png` | Runtime pass | Day 10/max-upgrade/three-customer Mobile stress retains all guarded HUD values without overlap. |
| 9 | `design/qa/iteration52-audit/09-day-choice-hierarchy.png` | Healthy | The regenerated baseline confirms the Cream default / Coral selected / outlined utility hierarchy. |

There is no remaining project-side P0 in this path. The two internal visual follow-ups are a coherent final 01–09 recapture and a late-game night-lab density review; neither is evidence that the focus, save or HUD regressions remain open.

## Automated evidence

Evidence recorded during this pass:

| Gate | Actual result |
|---|---|
| `tools/run_godot_checks.sh` | All 23 configured headless scenes passed at the unified-runner checkpoint. Later focus/safe-area, export and night hierarchy edits also received their targeted reruns. |
| `tests/input_check.tscn` | Passed after the final focus/accessibility changes: controller families, 4 px Cocoa focus, safe-frame and cutout fit, stable sealed-order focus, semantic order-card text, gestures and haptics. |
| `tests/save_migration_check.tscn` | Passed for save v21 migration, atomic backup rotation and truncated-primary recovery on isolated temporary files. |
| `tests/night_resume_check.tscn` | Passed with active cap 16, spend/resume 14, banked reserve 13, completion bonus/refund 2 and no refresh. |
| `tests/export_config_check.tscn` | Passed for four presets, compiled scripts, license/notices inclusion, resource exclusions, Android arm64, iOS icons, Basis Universal handling, two locales and dual-landscape project setting. |
| `tests/mobile_render_check.tscn` | Passed under Godot 4.6.3 Forward Mobile on the Apple M3 Ultra reference renderer: 58,228 visible triangles, 194 surfaces, 335 maximum draw calls and 130.61 MiB video memory; guarded HUD labels were populated and the status row did not overlap preparation controls. |
| `tests/campaign_strategy_sim.tscn` | Final careful, balanced and growth runs all reached their 14-day assertions with A / S / S and 9/10 / 10/10 / 10/10 upgrades respectively. |

The macOS headless runs emitted the engine's system-CA lookup message, but no listed project assertion failed. These results do not substitute for packaged target-device tests.

## External release gates still open

1. **macOS signing and notarization.** The current preset does not prove a Developer ID release signature. Produce the release artifact with the intended identity and entitlements, submit it for Apple notarization, staple the ticket, and perform Gatekeeper install/launch smoke on a clean machine.
2. **Android SDK and production signing.** Install and pin the compatible JDK/Android SDK toolchain, build the release artifact, sign it with the production keystore, verify the signature, then install and smoke-test it on representative hardware. Project-side arm64/export configuration alone does not close this gate.
3. **iOS distribution and physical device.** Create the App Store distribution certificate/profile, export the distribution build, validate its signature/provisioning and install it on a real supported iPhone/iPad. The configured team ID and development export path do not prove distribution readiness, touch-safe-area behavior or sustained device performance.
4. **Five-person, fourteen-day human test.** Five independent players must each complete the fourteen-day campaign. Record completion/blockers and qualitative evidence for order readability, review/delivery comprehension, late-game night density, perceived economy fairness, upgrade decisions, save/resume confidence and replay intent. No human result is claimed until those sessions occur.

Release-candidate signoff remains blocked until all four external gates have traceable artifacts and results. The regenerated `design/qa/iteration52-audit` set is the final-code visual baseline for this pass.
