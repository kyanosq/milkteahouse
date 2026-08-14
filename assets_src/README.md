# MilkTeaHouse Asset Manifest

Runtime-loaded copies live under `game/assets/`. Editable Blender sources and acceptance renders stay under `assets_src/`.

## Iteration 13 — Blender MCP premium bar and customer silhouettes

All assets below were authored locally through Blender MCP. No paid image or 3D generation API was used.

| Name | Description | In-game size | Editable source | Runtime asset | Triangles | Cost |
| --- | --- | --- | --- | --- | ---: | ---: |
| Premium shop scene | Coral/mint counter fascia, layered trim, pendant shades, geometry menu graphics, four filled glass jars, labels and shelf details | 8 × 3 × 2.6 m room | `blend/shop_scene.blend` | `../game/assets/glb/shop_scene.glb` | 17,748 | $0.00 |
| Customer · classic | Original rounded customer silhouette, mobile-retopologized in Iteration 23 | about 0.40 m tall after runtime scale | `blend/customer.blend` | `../game/assets/glb/customer.glb` | 3,228 | $0.00 |
| Customer · bob | Round bob, flower clip and cream collar | about 0.42 m tall after runtime scale | `blend/customer_bob.blend` | `../game/assets/glb/customer_bob.glb` | 3,490 | $0.00 |
| Customer · cap | Knit cap, brim and cross-body satchel | about 0.49 m tall after runtime scale | `blend/customer_cap.blend` | `../game/assets/glb/customer_cap.glb` | 3,438 | $0.00 |
| Customer · buns | Twin buns, color ties, hoodie volume and badge | about 0.45 m tall after runtime scale | `blend/customer_buns.blend` | `../game/assets/glb/customer_buns.glb` | 3,474 | $0.00 |
| Night research lab | Indigo room, walnut experiment desk, hero mat, lamp, candle, shelves, jars, flasks, papers and plant | 6.6 × 3.3 × 2.9 m room | `blend/night_lab_scene.blend` | `../game/assets/glb/night_lab_scene.glb` | 24,332 | $0.00 |

Runtime compatibility contract:

- Tintable clothing meshes use a `Body*` or `Arm*` object name.
- Randomized hair meshes use a `Hair*` object name.
- Customer variants share the same origin, facing direction and gameplay scale.
- Special-customer hair keeps its authored color; only the four regular variants are randomized.
- `model_asset_check.tscn` guards the four-model rotation, all three special bindings, file budgets and required environment nodes.

## Iteration 18 — gameplay-readable special customers

All three models were authored through Blender MCP from the existing chibi proportion contract. Editable parts remain separate in `.blend`; runtime GLBs are joined by material before export.

| Name | Gameplay-readable silhouette | Editable source | Runtime asset | Triangles | Runtime meshes | Size | Cost |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: |
| Critic | Wine beret, dark glasses, serious brows, lapels, notebook and pencil | `blend/customer_critic.blend` | `../game/assets/glb/customer_critic.glb` | 3,336 | 10 | 104,208 B | $0.00 |
| Influencer | Pink high ponytail, headphones, star details, raised phone and selfie stick | `blend/customer_influencer.blend` | `../game/assets/glb/customer_influencer.glb` | 3,404 | 10 | 107,876 B | $0.00 |
| Group duo | Two scaled friends, distinct head silhouettes, coral/mint scarves and shared charm | `blend/customer_group.blend` | `../game/assets/glb/customer_group.glb` | 3,436 | 9 | 110,360 B | $0.00 |

Blender previews: `renders/customer_critic_preview.png`, `renders/customer_influencer_preview.png`, and `renders/customer_group_preview.png`. Runtime density evidence lives in `../design/qa/iteration18-special-models/`.

## Iteration 19 — trait-readable staff roster

The original `staff_barista` remains a compatibility fallback. Known first-shop hires now bind by staff ID to distinct models, all authored through Blender MCP and batched by material for runtime.

| Name | Trait-readable silhouette | Editable source | Runtime asset | Triangles | Runtime meshes | Size | Cost |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: |
| 小满 · Slacker | Soft mint cap, half-lidded eyes, flat mouth and personal mug | `blend/staff_xiaoman.blend` | `../game/assets/glb/staff_xiaoman.glb` | 3,024 | 9 | 146,944 B | $0.00 |
| 桃子 · Social | High side ponytail, mint hair tie, headset and open smile | `blend/staff_taozi.blend` | `../game/assets/glb/staff_taozi.glb` | 3,290 | 9 | 159,388 B | $0.00 |
| 阿澄 · Perfectionist | Dark inspection glasses, clipboard, aligned pencil and timer badge | `blend/staff_acheng.blend` | `../game/assets/glb/staff_acheng.glb` | 3,088 | 9 | 150,816 B | $0.00 |

Blender previews: `renders/staff_xiaoman_preview.png`, `renders/staff_taozi_preview.png`, and `renders/staff_acheng_preview.png`. Runtime evidence lives in `../design/qa/iteration19-staff-models/`.

## Iteration 21 — visible shop progression kit

The four existing economy upgrades now have physical Blender-authored states. Editable parts stay separate in one library file; export duplicates are joined by level tier and material so `L2_` / `L3_` remain independently visible at runtime.

| Name | Visible progression | Editable source | Runtime asset | Triangles | Runtime meshes | Size | Cost |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: |
| Automatic shaker | Clamp/display → seal module → dual motors/light arch | `blend/upgrade_kit.blend` | `../game/assets/glb/props/upgrades/auto_shaker.glb` | 1,780 | 13 | 64,388 B | $0.00 |
| Waiting comfort | Bench/rug → planter → floor lamp | `blend/upgrade_kit.blend` | `../game/assets/glb/props/upgrades/comfort.glb` | 1,736 | 12 | 64,584 B | $0.00 |
| Smart sugar | Five reservoirs, scan pad and illuminated control screen | `blend/upgrade_kit.blend` | `../game/assets/glb/props/upgrades/smart_sugar.glb` | 1,712 | 8 | 60,640 B | $0.00 |
| Tip jar | Coin jar → ribbon → illuminated topper | `blend/upgrade_kit.blend` | `../game/assets/glb/props/upgrades/tip_jar.glb` | 1,816 | 8 | 61,680 B | $0.00 |

Deterministic builder: `blend/build_upgrade_kit.py`. Blender preview: `renders/upgrade_kit_preview.png`. Runtime placement evidence and the rejected first layout live in `../design/qa/iteration21-upgrade-models/`.

## Iteration 22 — release identity and packaged assets

The application icon was generated as one premium 1024 × 1024 milk-tea master using the built-in image generator with the accepted gameplay render as a style reference. Local deterministic resizing produced every required iOS size from 40 through 192 px; all PNGs are exact-size and opaque, with the 58 px result inspected at native resolution.

| Asset | Runtime/source location | Notes | Cost |
| --- | --- | --- | ---: |
| App icon master | `../game/assets/icons/app/icon_1024.png` | Opaque RGB, SHA-256 `8f3b7d3d1143b1a2d3097649cf4c594c8876bf207f35f62e49d6de18ff616cb3` | $0.00 |
| iOS icon set | `../game/assets/icons/app/icon_{40…192}.png` | 14 exact opaque sizes derived from the master | $0.00 |
| Runtime font subset | `../game/assets/fonts/LXGWWenKai-Regular.ttf` | 505,004 B deterministic FontTools subset; full OFL source retained in `fonts/` | $0.00 |

The shop GLB imports embedded images as Basis Universal. Historical extracted `shop_scene_tmp*` and floor copies remain editable/source evidence but are excluded from release packages. The 14 derivative platform-icon sizes are likewise excluded from ordinary PCK resources after export processing; the 1024 px project icon remains a runtime dependency. Detailed package evidence: `../design/qa/package-export-iteration22.md`.

## Iteration 23 — Blender MCP mobile runtime pass

No paid generation API was used. The editable Blender sources keep their independent pieces; batching occurs only on temporary export duplicates.

| Asset group | Before | Final runtime | Deterministic builder/exporter |
| --- | --- | --- | --- |
| Static shop | 135 meshes / 17,748 triangles | 32 meshes / 17,748 triangles | `blend/optimize_shop_export.py` |
| Classic customer | 20 meshes / 40,980 Godot triangles / 917,912 B | 8 meshes / 3,228 triangles / 114,972 B | `blend/build_customer_classic_mobile.py` |
| Day 10 repeated props | 111 meshes / 68,988 triangles | 71 meshes / 17,916 triangles | `blend/build_props_hd.py` |

Per-operation-prop runtime budgets:

| Asset | Meshes | Godot triangles | GLB bytes |
| --- | ---: | ---: | ---: |
| Kettle | 5 | 2,116 | 61,988 |
| Milk carton | 4 | 884 | 28,704 |
| Pickup tray | 3 | 312 | 11,016 |
| Preparation mat | 3 | 456 | 14,572 |
| Service bell | 5 | 1,236 | 36,092 |
| Manual shaker | 8 | 2,128 | 62,244 |
| Sugar pump | 4 | 952 | 30,464 |
| Topping bin | 5 | 1,004 | 31,392 |

Classic customer preview: `renders/customer_classic_mobile_preview.png`. Runtime performance evidence and exact Mobile/Forward+ measurements: `../design/qa/mobile-render-performance-iteration23.md`.

## Iteration 38 — physical New Shop+ route signs

No paid generation API was used. A deterministic local Blender 5.1 builder creates three text-free relief signs, keeps editable pieces in one source file and batches runtime duplicates by material. Only the active New Shop+ route is loaded; the first campaign loads no sign.

| Name | Gameplay silhouette | In-game size | Editable source | Runtime asset | Triangles | Meshes | Bytes | Cost |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: |
| Turnover sign | Coral directional flag with three throughput chevrons | 0.49 × 0.25 × 0.05 m | `blend/route_signs.blend` | `../game/assets/glb/props/routes/route_rush.glb` | 276 | 4 | 15,444 | $0.00 |
| Reputation sign | Purple quality seal, mint star and twin ribbons | 0.39 × 0.45 × 0.05 m | `blend/route_signs.blend` | `../game/assets/glb/props/routes/route_precision.glb` | 676 | 4 | 36,908 | $0.00 |
| Trend sign | Gold arch with a rising mint trail and coral sparkle | 0.46 × 0.31 × 0.05 m | `blend/route_signs.blend` | `../game/assets/glb/props/routes/route_trend.glb` | 544 | 4 | 31,536 | $0.00 |

Deterministic builder: `blend/build_route_signs.py`. Blender overview: `renders/route_signs_preview.png`. Runtime Forward+/Mobile shop placement evidence lives in `../design/qa/iteration38-route-signs/`; day/night reuse, first-campaign suppression and payout-response evidence lives in `../design/qa/iteration39-route-continuity/`.

## Iteration 15 — original audio identity

| Library | Source | Runtime output | Contents | Cost |
| --- | --- | --- | --- | ---: |
| Scene music | `audio/generate_audio.py` + `audio/masters/` | `../game/assets/music/` | 4 looping Ogg themes | $0.00 |
| Interaction SFX | `audio/generate_audio.py` | `../game/assets/sfx/` | 19 stereo WAV cues | $0.00 |

The generator uses deterministic seed `4804` and no third-party samples. `audio_check.tscn` guards resource presence, bus levels, music crossfades, voice limits and playback cleanup.

Acceptance renders:

- `renders/shop_scene_iteration13_full.png`
- `renders/customer_bob_preview.png`
- `renders/customer_cap_preview.png`
- `renders/customer_buns_preview.png`
- `renders/night_lab_scene_blender.png`
