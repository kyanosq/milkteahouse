# Blender Upgrade Visuals — Iteration 21

Date: 2026-08-09  
Target: make the existing coin upgrades visible in the playable shop without exceeding the equipment or mobile draw-call budgets.

## Gap closed

The four upgrades previously changed only timing, error tolerance and rewards. The HUD exposed a shop level, but the 3D counter looked almost identical before and after investment. This pass gives every first-shop upgrade a physical identity:

- **Comfort:** cream/coral bench, cushions and rug at level 1; planter at level 2; floor lamp at level 3.
- **Automatic shaker:** clamped cup and control display at level 1; seal module at level 2; dual motors and light arch at level 3.
- **Smart sugar:** five-reservoir dosing console, scan pad and illuminated screen. When purchased, it replaces the five manual sugar pumps because gameplay also skips manual sugar selection.
- **Tip jar:** transparent coin jar at level 1; mint ribbon at level 2; illuminated topper at level 3.

## Blender and runtime assets

All models were authored locally through Blender MCP. No paid generation API was used.

| Asset | Triangles | Editable meshes | Runtime meshes | GLB size |
| --- | ---: | ---: | ---: | ---: |
| Automatic shaker | 1,780 | 18 | 13 | 64,388 B |
| Comfort set | 1,736 | 17 | 12 | 64,584 B |
| Smart sugar console | 1,712 | 16 | 8 | 60,640 B |
| Tip jar | 1,816 | 15 | 8 | 61,680 B |

The editable source is `assets_src/blend/upgrade_kit.blend`; the deterministic builder is `assets_src/blend/build_upgrade_kit.py`. Source GLBs live in `assets_src/glb/props/upgrades/`, with byte-identical runtime copies in `game/assets/glb/props/upgrades/`.

The first pass measured 5,112–6,304 triangles per item and was rejected. Reducing hidden cylinder, sphere, torus and bevel segmentation brought every item inside the GDD's 1,000–2,500 equipment budget without changing the 720p silhouette. Export duplicates are joined by level tier plus material, keeping the 66 authored parts editable while reducing runtime meshes. `Base_`, `L2_` and `L3_` prefixes are the visibility contract used by Godot.

## Gameplay integration

- `ShopStage` selects the manual shaker at level 0 and the new automatic model at levels 1–3.
- Purchased upgrade roots record `upgrade_id` and `upgrade_level` metadata for regression checks.
- Level 2 and level 3 meshes are hidden below their required level and become visible on the next business day after purchase.
- Smart sugar removes the obsolete manual pumps instead of presenting five clickable-looking controls for a step that is now automatic.
- The comfort set remains in the physical waiting area. The fixed order rail partially covers it at 720p, but it does not overlap customer slots, ingredient controls or the delivery path.

## Visual QA

- Blender product view: `assets_src/renders/upgrade_kit_preview.png`.
- Initial in-game placement: `iteration21-upgrade-models/01-day10-max-upgrades.png` exposed redundant manual pumps and a mostly occluded tip jar.
- Placement refinement: `02-day10-max-upgrades-refined.png` removes the pumps and moves the jar clear of the side counter.
- Final post-batch acceptance: `03-day10-batched-final.png` confirms the optimized GLBs retain the same silhouettes and materials at 1280 × 720.

The final frame keeps all order-card bounds, contextual controls, work cup, three customers and bottom actions readable. The automatic shaker, sugar console and tip jar form three separate shapes on the right rather than one equipment pile.

## Verification

- Godot 4.6.3 imported all four GLBs without parser or material errors.
- `model_asset_check.tscn` verifies all files, the `Base_` contract, ≤14 runtime meshes, <256 KiB per asset, exact shop bindings and L2/L3 visibility behavior.
- Source/runtime GLB SHA-256 values match for all four assets.
- Full gameplay and release regression suites pass after integration.
- Regular-profile Day 10 autoplay with all ten upgrade levels served 29/29 customers, earned 515 coins and reached 3 stars; removing the obsolete manual sugar pumps did not break automatic sugar matching.
- Screenshot and test mode do not persist their max-upgrade fixture to the player's real save.
