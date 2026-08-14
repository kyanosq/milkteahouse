# Iteration 39 — Route Identity Across Day and Night

Date: 2026-08-10

## Problem

Iteration 38 made the selected New Shop+ route physical during the day, but the identity disappeared in the night laboratory where the player reads tomorrow's event and chooses the featured menu. The route was therefore mechanically relevant across the full loop but visually present in only half of it. The sign also remained static when its rule paid out, leaving its reward feedback entirely inside text and coin totals.

## Blender MCP placement audit

Blender MCP first reported the open `props_hd.blend` scene as clean, so it was safe to switch to `assets_src/blend/night_lab_scene.blend`. The source-space audit measured the 6.6 m back wall, 4.55 m upper shelf, 5.85 m desk and authored acceptance camera. A temporary import of the heaviest Trend GLB measured a 0.68 × 0.133 × 0.46 m source-space bound; the lab file was immediately reloaded without saving, returning to a clean state.

The first runtime wall transform at `(0.10, 1.26, -1.13)` was rejected because the sign loaded but was fully occluded. A second near-wall attempt at z `-0.85` remained hidden. A diagnostic foreground placement proved the asset, materials, route binding and renderer were correct. The accepted shared transform is `(0.68, 1.32, 0.05)` at scale `0.62`: it reads as a plaque on the right experiment-frame post, remains clear of the hero cup, ingredient selector, research brief, flavor radar, test-tube rack and tomorrow card, and accommodates all three silhouettes.

## Runtime behavior

- `night_lab_backdrop.gd` maps the validated route ID to the same three Blender GLBs used by the day shop, tags the instance for regression and disables only small-sign shadow submission on Mobile.
- No valid route means no night sign, preserving the first-campaign laboratory exactly.
- `shop_stage.gd` exposes a 0.24-second 1.10× sign pulse. `day_shop.gd` calls it only when `LegacyRoutes.sale_bonus()` actually returns coins, so decoration never implies a payout that did not occur.
- Reduced-motion mode kills any active sign tween, restores the exact base scale and skips the pulse.
- The screenshot harness can trigger the accepted payout pose through `SHOT_ROUTE_PULSE=1`; this is a QA hook only and does not alter gameplay state.

## Visual evidence

- `iteration39-route-continuity/02-rush-night-final-zh.png`
- `iteration39-route-continuity/02-precision-night-final-zh.png`
- `iteration39-route-continuity/02-trend-night-final-zh.png`
- `iteration39-route-continuity/03-trend-night-mobile.png`
- `iteration39-route-continuity/04-trend-day-payout-pulse.png`
- `iteration39-route-continuity/05-first-campaign-night-clean.png`

The three accepted Forward+ captures use the same mount and prove the widest and tallest variants stay inside the available 3D negative space. The Mobile capture retains the mint trail, coral star and gold frame without unsupported SSAO or an extra shadow submission. The first-campaign capture proves the mount does not leak a default or stale route.

## Automated evidence

`model_asset_check.tscn` now validates all three day bindings, all three night bindings, first-campaign suppression in both scenes, reduced-motion suppression, pulse departure from base scale and exact settlement back to `0.68`.

The routed Day 10/max-upgrade/three-customer Forward Mobile stress scene remains at 59,324 visible triangles and 195 surfaces. This run measured 326 maximum draw calls and 118.06 MiB video memory against budgets of 120,000 / 200 / 360 / 160 MiB. The previous accepted run measured 325 / 118.12 MiB, so the one-call variation is normal frame sampling rather than new geometry.

All 24 guarded check scenes pass, including the real Mobile render. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

Route identity now survives the full operate → plan → operate loop and answers a real reward with a small physical response. A human replay should still judge whether repeated payout pulses remain satisfying over a full high-skill shift; the motion is deliberately short and scale-only to limit fatigue.
