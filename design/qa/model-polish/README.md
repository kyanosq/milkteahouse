# Model polish — 2026-09-05

- Fixed inward winding on all six curved counter strips. The exporter now checks closed, consistently oriented edges and positive signed volume before batching.
- Smoothed the curved fascia, limited bevels to hard edges, and added an 8 mm countertop bevel. Shop export remains 23 meshes / 6,368 triangles; GLB size decreased from 4,568,148 to 4,479,504 bytes.
- Replaced the preparation mat's square backing with fitted rounded geometry. Corrected the pickup tray's rear taper to follow its surface art.
- Added weighted normals to the eight prop builders. Export evaluates modifiers after deformation and before material batching, preserving flat surfaces and soft bevels.
- Rebuilt the editable prop library and all nine source/runtime GLB pairs; each pair is byte-identical.
- Mounted all route reliefs below the worktop, with a regression assertion for clearance. Moved the smart sugar console and tip jar onto the left worktop so they no longer intersect the pickup tray or its label in the upgraded shop.

Validation: Blender export assertions, Godot import, `model_asset_check.tscn`, `input_check.tscn`, and `git diff --check` pass. Final Forward Mobile Day 10 capture: 58 visible meshes, 12,860 triangles, 181 maximum draw calls, 146.38 MiB video memory; all existing resource budgets pass. The desktop capture measured 65.887 ms average process time; this is not a device frame-rate acceptance result.

Visual evidence: [before](before.png), [after](after.png) (same Day 1 topping-selection state), and [Mobile Day 10](mobile-day10.png).

Rebuild with Blender 5.1: `blender --background --python assets_src/blend/optimize_shop_export.py` and `blender --background assets_src/blend/props_hd.blend --python assets_src/blend/build_props_hd.py`, then reimport the Godot project.
