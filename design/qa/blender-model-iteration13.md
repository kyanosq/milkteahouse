# Blender Model Iteration 13 Audit

Date: 2026-08-09

## Outcome

The day shop now reads as a deliberately art-directed commercial space rather than a set of props on blank counters. The queue also uses four stable character silhouettes instead of cloning one customer and changing only the shirt color.

## Baseline findings

- The counter front was a large cream rectangle with no visual hierarchy.
- Hanging bulbs had no shades, shelf jars looked like opaque white cylinders, and the menu board carried no internal detail.
- Three simultaneous customers shared the same hair and body silhouette, making a busy queue look duplicated.
- First-pass customer variants exceeded the GDD's 3,500-triangle character ceiling and used too many separate mesh objects.

## Blender MCP work

- Added three framed mint fascia panels, brass studs, layered coral/mint edge trim, a central milk-tea emblem and a darker foot rail.
- Modeled two mint pendant shades with brass caps and warm inner rings.
- Rebuilt four shelf containers as readable glass ingredient jars with colored fill, wood lids, brass knobs and front plaques.
- Added localization-safe geometry graphics to the wall menu and upgraded cup/shelf dressing.
- Built three editable customer variants: bob/flower/collar, knit-cap/satchel, and twin-buns/hoodie.
- Consolidated same-material parts and decimated secondary curves after visual review.

## Runtime metrics

| Asset | Mesh objects | Triangles | Runtime size |
| --- | ---: | ---: | ---: |
| Shop scene | 135 | 17,748 | 4.0 MiB |
| Customer classic (Iteration 13 source-side estimate) | 9 | ~2,356 | 896 KiB |
| Customer bob | 12 | 3,490 | < 200 KiB |
| Customer cap | 13 | 3,438 | < 200 KiB |
| Customer buns | 10 | 3,474 | < 200 KiB |

The original Iteration 13 source-side estimates appeared to place the queue below the 120k on-screen triangle budget. Iteration 23 later measured the imported classic GLB at 20 meshes / 40,980 Godot-triangulated faces, then rebuilt it through Blender MCP to 8 meshes / 3,228 triangles / 114,972 B. `mobile-render-performance-iteration23.md` is authoritative for current runtime budgets.

## Godot integration

- `ShopStage` preloads four PackedScenes and rotates them deterministically `0 → 1 → 2 → 3`.
- `Body*`/`Arm*` meshes inherit the customer tint; all `Hair*` meshes share one randomized hair material.
- Each actor records its model variant as metadata for deterministic regression checks.

## Evidence

- Blender baseline: `assets_src/renders/shop_scene_iteration13_before.png`
- Blender full-scene acceptance: `assets_src/renders/shop_scene_iteration13_full.png`
- Final Day 10 density capture: `design/qa/iteration13-blender/03-day10-final.png`
- Individual previews: `assets_src/renders/customer_bob_preview.png`, `customer_cap_preview.png`, `customer_buns_preview.png`

## Verification

- Godot 4.6.3 imported all four customer GLBs and the revised shop GLB without parser or material errors.
- `model_asset_check.tscn`: shop nodes 4/4, customer variants 4/4, deterministic rotation, runtime file budgets — passed.
- `staff_check.tscn`: employee interaction and customer-dependent error rescue — passed.
- `onboarding_check.tscn`: tutorial/settings regression — passed.
- Skilled Day 10 autoplay: 29/29 served, 3 stars, no script/resource warnings — passed.
- Automated screenshots and tests left the real save SHA-256 unchanged.

## Remaining visual asset priorities

1. Give the night lab its own Blender-authored desk/background kit instead of relying mainly on UI planes.
2. Add two more customer silhouettes only when a new special-customer behavior needs them; avoid cosmetic-only mesh growth.
3. Completed in Iteration 23: rendered Mobile stress capture, Blender batching/retopology and automatic draw-call/triangle budgets.
