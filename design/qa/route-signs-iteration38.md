# Iteration 38 — Physical New Shop+ Route Signs

Date: 2026-08-10

## Rejected state

Turnover, Reputation and Trend had different rules, calendars, HUD progress and permanent clear records, but the rendered shop remained pixel-identical. The route identity disappeared whenever the player looked away from the small top pill. For a second campaign, that made the most important meta choice feel like a difficulty setting rather than a shop the player had actually opened.

## Authored asset family

Three text-free reliefs were built locally in Blender 5.1 using a deterministic source script. No paid image or Tripo generation call was made.

| Route | Shape language | Runtime meshes / triangles / bytes | In-game size |
|---|---|---:|---|
| Turnover | Coral directional flag with three forward chevrons | 4 / 276 / 15,444 | 0.49 × 0.25 × 0.05 m |
| Reputation | Purple quality seal with mint star and twin ribbons | 4 / 676 / 36,908 | 0.39 × 0.45 × 0.05 m |
| Trend | Gold arch with rising mint trail and coral sparkle | 4 / 544 / 31,536 | 0.46 × 0.31 × 0.05 m |

Editable parts live in `assets_src/blend/route_signs.blend`; `assets_src/blend/build_route_signs.py` rebuilds the source/runtime GLBs and the family preview. Export duplicates join by material so each asset costs exactly four surfaces while the `.blend` retains 17 editable pieces.

## Runtime composition

`shop_stage.gd` maps the validated active route ID to one preloaded sign. It loads exactly one model, tags it with the route ID, disables only its small-prop shadow submission on Mobile, and mounts it on the center-left front fascia. The first campaign has an empty route and instantiates no sign.

Two placement attempts were rejected during screenshot review:

1. At 0.64 m high the sign read as a dropped floor object and crossed the customer silhouette.
2. At 0.88 m it still overlapped the customer's head and hung below the fascia.

The accepted 1.02 m / x -0.30 mount sits above the teal trim, clears the queue, remains left of the hero cup and does not enter any clickable ingredient, order or bottom-guidance region.

## Visual evidence

- `assets_src/renders/route_signs_preview.png` — Blender family review.
- `iteration38-route-signs/01-rush-sign-zh.png` — accepted Turnover Forward+ placement.
- `iteration38-route-signs/02-precision-sign-zh.png` — accepted Reputation Forward+ placement.
- `iteration38-route-signs/03-trend-sign-zh.png` — accepted Trend Forward+ placement.
- `iteration38-route-signs/04-trend-sign-mobile.png` — heaviest sign in the full Mobile Day 10 / three-customer / max-upgrade stress scene.

The silhouettes differ in outline and internal geometry, not color alone. They use no baked text, so Chinese/English switching cannot produce stale language or additional texture memory.

## Performance and regression evidence

The model test loads all three GLBs, enforces ≤5 meshes, ≤1,000 triangles and <64 KiB per asset, proves every validated route binds to the matching model, and proves the first campaign binds none.

The heaviest Trend sign adds 4 meshes and 544 triangles to the stress scene. Forward Mobile measures 59,324 visible triangles, 195 surfaces, 325 maximum draw calls and 118.12 MiB video memory against budgets of 120,000 / 200 / 360 / 160 MiB. The sign is listed as its own subtree in the renderer output, so this is measured inclusion rather than an inferred asset sum.

The full 24-scene regression passes after the final placement and the real player save remains byte-identical.

Physical route identity is now present during every shift, but a static relief cannot prove emotional attachment. Human replay sessions should ask players to identify their route without reading the HUD and whether the sign feels like an earned shop identity rather than decoration.
