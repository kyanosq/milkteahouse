# Blender Special Customers · Iteration 18

Date: 2026-08-09

## Outcome

The three gameplay-significant visitors can now be recognized from their 3D silhouettes before reading the ticket. Critic, influencer and group rules are no longer represented by ordinary customers with only a purple, pink or mint clothing tint.

## Blender MCP work

- **Critic:** wine beret and pin, dark round glasses, serious brows, cream lapels, brass badge, notebook and pencil.
- **Influencer:** authored pink high ponytail, mint headphones, star details, selfie stick and raised phone with screen/lens layers.
- **Group:** a real two-person asset with different heights and head silhouettes, knit-cap/twin-bun cues, coral/mint scarves, four shoes and a shared charm.
- Corrected the first group preview after render inspection: the original hair caps were occluded by the heads, so four low-poly fringe pieces were added before export.

## Runtime budgets

| Asset | Triangles | Runtime meshes | GLB size |
| --- | ---: | ---: | ---: |
| Critic | 3,336 | 10 | 104,208 B |
| Influencer | 3,404 | 10 | 107,876 B |
| Group duo | 3,436 | 9 | 110,360 B |

Editable sources preserve 24–33 individually selectable mesh parts plus preview lights/camera. Equal-material pieces are joined only in memory for export, after which Blender reopens the saved editable source. Each source/runtime GLB pair was copied byte-for-byte and verified with SHA-256.

## Godot integration

- `ShopStage.add_customer` accepts the event kind and maps `critic`, `influencer` and `group` to dedicated PackedScenes.
- Special spawns do not consume `_customer_variant_serial`; the next regular customer therefore continues the stable `0 → 1 → 2 → 3` rotation.
- `Body*` remains tintable. Regular `Hair*` keeps randomized cocoa/chestnut shades, while special hair preserves the authored identity colors.
- The group actor uses a slightly larger common scale but stays within one queue slot.

## Visual evidence

- Blender previews: `assets_src/renders/customer_critic_preview.png`, `customer_influencer_preview.png`, `customer_group_preview.png`.
- Single-spawn gameplay: `iteration18-special-models/01-critic-ingame.png`, `02-influencer-ingame.png`, `03-group-ingame.png`.
- Three-slot pressure: `iteration18-special-models/04-critic-dense-queue.png`, `05-group-dense-queue.png`.

At 1280 × 720, all three event models remain recognizable, order cards retain their full bounds, and dense queues preserve separation between the special actor and two regular customers.

## Automated verification

- Godot 4.6.3 imported all three GLBs successfully.
- `model_asset_check.tscn` verifies model loading, semantic mesh prefixes, ≤10 runtime meshes, <256 KiB per asset, exact kind binding and regular-rotation isolation.
- Event, staff, input/onboarding and night/campaign regressions are run after integration.
- Screenshot and test mode do not write the real player save.
