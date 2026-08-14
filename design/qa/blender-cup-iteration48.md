# Iteration 48 — Blender MCP Branded Gameplay Cup

Date: 2026-08-10

## Art gap

The runtime cup already supported recipe-driven liquid, pearls, sealing and a straw, but its clear shell had no MilkTeaHouse identity. In both day and night cameras it read as a generic container, and a first branded pass created too many independent material objects for the Mobile stress scene.

## Blender rebuild

`assets_src/blend/build_character_cup_hd.py` is now the authoritative cup builder. Blender MCP rebuilt and exported the same GLB to source and runtime directories with:

- a cream sleeve with coral borders and a coral/mint leaf badge;
- a mint/coral striped straw and coral translucent seal;
- preserved `Cup`, `LiquidTea`, `LiquidMilk`, `Pearl_00`, `Straw` and `SealFilm` runtime contracts;
- one source pearl mesh, with the existing Godot rig still creating ten physical pearls;
- a merged transparent shell and vertex-colored single-surface brand/straw meshes.

The cup builder no longer rebuilds or exports `customer.glb`; the regular customer remains owned by `build_customer_classic_mobile.py`. This prevents an unrelated cup iteration from bypassing the customer batching gate.

## Budget correction

The rejected first pass reached 19,344 triangles and 26 objects. LOD, one pearl seed, low-segment rings and geometry/material batching reduced the accepted asset to:

| Metric | Accepted |
|---|---:|
| GLB source objects / surfaces | 7 / 7 |
| Full source triangles | 4,920 |
| Visible runtime cup surfaces | 4 |
| Runtime GLB size | 156,072 bytes |

The first game-ready multi-material pass still raised the stress scene to 213 surfaces / 364 draw calls. Vertex color and shell batching corrected it to 194 surfaces / 327 draw calls while retaining all three brand colors.

## Visual evidence

- `iteration48-blender-cup/01-night-unsealed.png` — accepted unsealed night-lab cup; sleeve and dynamic layers are visible while straw/seal remain hidden.
- `iteration48-blender-cup/02-day-sealed.png` — accepted sealed day cup; stripe, seal and badge survive the gameplay camera.
- `iteration48-blender-cup/03-mobile-stress.png` — accepted max-upgrade/three-customer Mobile frame.

## Gate

Forward Mobile passes at 58,228 visible triangles, 194 meshes/surfaces, 327 maximum draw calls and 127.50 MiB. `model_asset_check.tscn` confirms the restored classic customer at 8 meshes / 3,228 triangles. All 24 guarded scenes pass, and the real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
