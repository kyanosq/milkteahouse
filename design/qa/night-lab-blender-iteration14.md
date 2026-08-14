# Night Lab Blender Iteration 14 Audit

Date: 2026-08-09

## Outcome

The research phase now has its own Blender-authored room rather than a darkened reuse of the daytime shop. The cup sits on a physical preparation mat, practical lights establish a night identity, and the background supports the UI without taking over its interaction hierarchy.

## Baseline problem

- The old night background reused `shop_scene.glb`, leaving daytime kettles, cartons and service furniture behind the recipe interface.
- The transparent CupView appeared to float over a flat dark band.
- Lighting was a global blue/warm tint with no authored source, so the space did not explain why the cup was the focus.

## Blender MCP work

- Built a deep-indigo room shell, walnut experiment desk, drawer fascia, brass wall rails and raised laboratory backboard.
- Added a coral-rimmed cream work mat with a mint dashed placement ring aligned to the existing CupView.
- Modeled an articulated mint/brass desk lamp, candle, succulent, recipe board, paper stack, pencil and spoon.
- Added upper research shelves, four filled glass tea jars, books, two mixing flasks and a four-tube test rack.
- Authored a 44 mm 16:9 acceptance camera and cool-fill / warm-practical lighting setup.

## Runtime optimization

| Artifact | Result |
| --- | ---: |
| Editable Blender source | 147 scene objects / 24,332 triangles / 274 KiB |
| Runtime GLB | 26 mesh objects / 24,332 triangles / 1.4 MiB |
| Draw-call strategy | same-material pieces merged only for export |

The editable `.blend` keeps every prop separate. Runtime batching is performed in memory, exported, then the saved editable source is restored.

## Godot integration

- Added `NightLabBackdrop`, with the Blender camera mapped into Godot coordinates.
- Added three lighting layers: cool directional room light, warm lamp/candle practicals and a shadow-free camera-side readability fill.
- Replaced the darkened daytime `ShopBackdrop` in `night_lab.gd` without changing recipe logic or hit targets.
- Kept the old dim overlay at only 4% opacity for UI color unification.

## Evidence

- Blender acceptance: `assets_src/renders/night_lab_scene_blender.png`
- Initial Godot lighting audit: `design/qa/iteration14-night-lab/01-night-lab-3d.png`
- Final base state: `design/qa/iteration14-night-lab/03-night-lab-final.png`
- Selected recipe density state: `design/qa/iteration14-night-lab/04-night-lab-recipe.png`

## Verification

- `model_asset_check.tscn`: 5 required night nodes, ≤30 runtime meshes, GLB size budget — passed.
- `night_check.tscn`: legendary discovery, dark recipe, buzz/menu changes and sleep settlement — passed.
- `campaign_check.tscn`: Day 14 report, endless mode and New Shop+ — passed.
- Godot 4.6.3 imported the GLB with no parser/material errors.
- Source/runtime GLBs have identical SHA-256 hashes.
- Real save SHA-256 remained `c1fed78f...6392` after screenshots and tests.

## Remaining night-phase priorities

1. Integrate the already-generated original night music and step-specific laboratory SFX.
2. Add a short discovery light pulse and paper-card entrance animation, respecting reduced-motion mode.
3. Profile the night viewport on the lowest mobile target before adding more decorative props.
