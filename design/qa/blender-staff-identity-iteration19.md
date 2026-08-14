# Blender Staff Identity · Iteration 19

Date: 2026-08-09

## Outcome

The first-shop roster no longer loads one generic barista for every hire. Xiaoman, Taozi and Acheng now have distinct Blender-authored silhouettes that reinforce their live behavior and match the name shown in the staff card.

## Blender MCP work

- **Xiaoman / Slacker:** removed the rigid visor and headset, flattened the eyes, replaced the smile with a neutral mouth, and added a soft mint cap plus personal mug. The existing idle lean now reads as intentional sleepiness.
- **Taozi / Social:** retained the open smile and headset, then added a high side ponytail and mint tie. The first render hid the ponytail on the far side, so it was moved to the camera side before export.
- **Acheng / Perfectionist:** removed the social headset/towel and blush, kept the rigid visor, then added inspection glasses, a layered clipboard, aligned pencil and timer badge.
- Removed Taozi's tiny cheek meshes after converted curve geometry put the first runtime pass 70 triangles over budget; the important smile, headset and ponytail remain.

## Runtime budgets

| Asset | Triangles | Runtime meshes | GLB size |
| --- | ---: | ---: | ---: |
| Xiaoman | 3,024 | 9 | 146,944 B |
| Taozi | 3,290 | 9 | 159,388 B |
| Acheng | 3,088 | 9 | 150,816 B |

All assets fit the GDD's 2,000–3,500 character budget and stay below 256 KiB. Source curves remain editable; export copies convert them to meshes and join equal-material pieces before GLB export.

## Godot integration

- `ShopStage.STAFF_MODELS` maps `xiaoman`, `taozi` and `acheng` to dedicated PackedScenes.
- Day setup passes `StaffCatalog.current().id` into `add_staff`.
- Unknown or future IDs use `staff_barista.glb` as a safe fallback.
- The actor records `staff_model` metadata so automated tests can catch mismatches between save data and the visible character.

## Visual evidence

- Blender previews: `assets_src/renders/staff_xiaoman_preview.png`, `staff_taozi_preview.png`, `staff_acheng_preview.png`.
- Runtime: `iteration19-staff-models/01-xiaoman-idle.png`, `02-taozi-working.png`, `03-acheng-working.png`.

At 1280 × 720, all three head silhouettes remain readable beside the staff card. Xiaoman's cap and lean, Taozi's ponytail/headset, and Acheng's glasses/clipboard remain visible despite the sugar pumps in the foreground.

## Verification

- Godot 4.6.3 imported all three GLBs without parser or material errors.
- `model_asset_check.tscn` verifies Body/Hair semantic prefixes, ≤9 meshes, <256 KiB and exact staff-ID mapping.
- `staff_check.tscn` verifies Xiaoman and Acheng runtime bindings alongside the existing wake/rescue/economy behavior.
- Source/runtime copies have matching SHA-256 hashes and test mode preserves the real player save.
