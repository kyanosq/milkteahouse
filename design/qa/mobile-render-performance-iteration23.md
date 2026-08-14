# Iteration 23 — Blender MCP Mobile Render Performance

Date: 2026-08-09  
Stress scene: Day 10, all ten shop-upgrade levels visible, three regular customers, 1280 × 720  
Measured renderer: Godot 4.6.3 Forward Mobile on Apple M3 Ultra / Metal

## Why this pass was required

The GDD sets a 120,000 visible-triangle ceiling and identifies draw calls as the actual mobile red line, but the project previously had no rendered measurement. A dedicated stress harness exposed three problems that file-size checks had hidden:

- the classic customer was 40,980 Godot triangles and 20 runtime meshes, not the earlier approximate source-side count;
- the Day 10 interactive prop group contributed 68,988 triangles and 111 mesh surfaces;
- the editable shop's 135 small objects reached the runtime GLB without material batching.

Forward Mobile also received an unsupported SSAO setting every time the day/night scene opened.

## Reproducible measurement

`game/tests/mobile_render_check.tscn` constructs the exact stress scene, freezes gameplay after three customers, settles 90 frames and samples 60 rendered frames. It reports:

- visible meshes, surfaces and Godot-triangulated geometry from the live SubViewport tree;
- shadow-casting lights and SubViewport count;
- actual draw calls, rendered primitives, video memory and process monitor samples when a display renderer is available;
- a per-direct-subtree breakdown that identifies asset hot spots.

The static portion runs headlessly in CI. A display-backed Mobile run additionally enforces ≤360 draw calls and ≤160 MiB video memory on this reference configuration.

## Blender MCP asset work

### Classic customer

`build_customer_classic_mobile.py` rebuilt the original silhouette with small-screen topology while preserving the mint bang shape, white glasses, cheeks, expression, clothing tint and hair-tint contracts. Twenty-five editable source parts remain in `customer.blend`; only the GLB export duplicate is batched into eight semantic/material meshes.

- Before: 20 meshes, 40,980 Godot triangles, 917,912 B.
- After: 8 meshes, 3,228 Godot triangles, 114,972 B.
- Preview: `assets_src/renders/customer_classic_mobile_preview.png`.

### Repeated counter props

`build_props_hd.py` now uses 18 × 9 spheres, 20 × 6 tori, 20-sided primary cylinders and lower-resolution curve bevels. Editable pieces remain separate; export duplicates batch fixed parts by material while keeping `Tint*` groups independent for data-driven tea/milk/topping colors.

| Asset | Runtime meshes | Godot triangles | GLB bytes |
| --- | ---: | ---: | ---: |
| Kettle | 5 | 2,116 | 61,988 |
| Milk carton | 4 | 884 | 28,704 |
| Pickup tray | 3 | 312 | 11,016 |
| Preparation mat | 3 | 456 | 14,572 |
| Service bell | 5 | 1,236 | 36,092 |
| Manual shaker | 8 | 2,128 | 62,244 |
| Sugar pump | 4 | 952 | 30,464 |
| Topping bin | 5 | 1,004 | 31,392 |

The Day 10 repeated-prop subtree dropped from 111 meshes / 68,988 triangles to 71 / 17,916.

### Static shop

`optimize_shop_export.py` copies evaluated mesh data into a temporary collection, batches by material, keeps `PD_Fascia_Base`, `PD_JarFill_0`, `PD_LampShade_0` and `PD_MenuCup` as exact semantic nodes, exports only the active Shop scene, then reopens the untouched source file. Runtime shop geometry remains 17,748 triangles while mesh surfaces drop from 135 to 32. Embedded textures still import as Basis Universal.

## Renderer-specific policy

- Forward Mobile no longer receives unsupported SSAO state in either the day shop or night lab.
- On Mobile only, small interactive props and upgrade models skip the directional shadow pass. Structural shop geometry, customers and the work cup still cast shadows.
- Forward+ retains SSAO, glow and all authored prop shadows; no desktop-quality setting was removed.

## Measured result

| Stage | Visible meshes/surfaces | Visible triangles | Max draw calls | Max rendered primitives | Video memory |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before | 346 | 155,236 | 730 | 217,424 | 122.39 MiB |
| Blender batching/low-poly | 191 | 58,780 | 439 | 208,718 | 120.17 MiB |
| Final Mobile shadow policy | 191 | 58,780 | **316** | 139,778 | 120.23 MiB |

Final reduction versus baseline:

- visible triangles: −62.1%;
- mesh surfaces: −44.8%;
- actual Mobile draw calls: −56.7%;
- rendered primitives: −35.7%.

This local reference run proves the project-side budget and renderer policy, not low-end-device FPS or thermal behavior. The final hardware gate still requires Android/iOS device frame-time, memory-pressure and sustained thermal captures.

## Visual and regression evidence

- `01-before-mobile-day10.png`: unoptimized Mobile baseline.
- `02-after-blender-batch-mobile-day10.png`: Blender asset pass before shadow policy.
- `03-final-mobile-day10.png`: final Mobile renderer acceptance.
- `04-final-forwardplus-day10.png`: desktop Forward+ acceptance with full shadows/SSAO.

All gameplay, campaign, event, staff, input, audio, release, font, export and model tests pass. The model regression now hard-caps the shop at 40 meshes / 20k triangles, every regular customer at 8–13 meshes / 1.5k–3.6k triangles and each operation prop at ≤8 meshes / ≤2.5k triangles. Day 10 regular autoplay remains 29/29 served, 515 coins and 3 stars. The real player save hash remains unchanged.

Current rebuilt artifacts:

- macOS universal ZIP: 73,380,459 B; packaged startup/shutdown passed.
- Windows x86-64 EXE: 114,784,560 B; structure passed.
- signed iOS arm64 IPA: 37,737,456 B; archive/export and strict signing passed.
