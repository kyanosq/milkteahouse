# MilkTeaHouse 3D Asset Manifest

Art direction: premium stylized 3D game props with soft toy-like forms, coral
`#FF6259`, mint `#27B9A7`, cream `#FFF8ED`, cocoa `#30201D`, matte PBR
surfaces, restrained highlights, and readable silhouettes at a 1280×720
isometric gameplay camera.

Generated references are reviewed before image-to-3D. Raw Tripo downloads stay
under `downloads/`; Blender-cleaned sources stay under `processed/`; only
validated GLBs are copied into `game/assets/glb/`.

| Name | Description | In-game size | Source/reference | Runtime target | Status |
|---|---|---:|---|---|---|
| customer_mint | Rig-ready chibi customer, separated limbs and tintable clothes | 0.72 m tall | `assets_src/blend/build_character_cup_hd.py` | `game/assets/glb/customer.glb` | Blender MCP rebuilt · accepted |
| kettle | Coral tea kettle with mint heating tray | 0.30 m wide | `assets_src/blend/build_props_hd.py` | `game/assets/glb/props/kettle.glb` | Blender MCP rebuilt · accepted |
| milk_carton | Cream carton with mint side panel | 0.23 m tall | `assets_src/blend/build_props_hd.py` | `game/assets/glb/props/milk_carton.glb` | Blender MCP rebuilt · accepted |
| topping_bin | Modular cream topping bin with wood lid and scoop | 0.14 m tall | `assets_src/blend/build_props_hd.py` | `game/assets/glb/props/topping_bin.glb` | Blender MCP rebuilt · accepted |
| sugar_pump | Modular pump bottle with tintable liquid shell | 0.22 m tall | `assets_src/blend/build_props_hd.py` | `game/assets/glb/props/sugar_pump.glb` | Blender MCP rebuilt · accepted |
| shaker | Mint counter shaker machine with transparent cup insert | 0.25 m tall | `assets_src/blend/build_props_hd.py` | `game/assets/glb/props/shaker.glb` | Blender MCP rebuilt · accepted |
| prep_mat | Cream inset preparation mat | 0.38 m wide | `assets_src/blend/build_props_hd.py` | `game/assets/glb/props/prep_mat.glb` | Blender MCP rebuilt · accepted |
| pickup_tray | Mint frame pickup tray | 0.32 m wide | `assets_src/blend/build_props_hd.py` | `game/assets/glb/props/pickup_tray.glb` | Blender MCP rebuilt · accepted |
| service_bell | Mint dome service bell with cocoa base | 0.10 m wide | `assets_src/blend/build_props_hd.py` | `game/assets/glb/props/service_bell.glb` | Blender MCP rebuilt · accepted |
| milk_tea_cup | Branded layered gameplay cup; vertex-colored sleeve, striped straw, seal film and runtime liquid/toppings | 0.17 m cup / 0.28 m with straw | `assets_src/blend/build_character_cup_hd.py` | `game/assets/glb/milk_tea_cup.glb` | Blender MCP rebuilt · 4,920 tris / 7 surfaces · accepted |
| shop_scene | Counter, shelves, floor, rails, wall decor and lighting fixtures | 5.4 m wide gameplay set | `assets_src/blend/shop_scene.blend` | `game/assets/glb/shop_scene.glb` | Blender MCP material pass · accepted |
| upgrade_auto_shaker | Three-level clamped automatic shaker | 0.52 m tall | `assets_src/blend/upgrade_kit.blend` | `game/assets/glb/props/upgrades/auto_shaker.glb` | Blender MCP rebuilt · accepted |
| upgrade_comfort | Three-level waiting bench, plant and lamp set | 0.95 m wide | `assets_src/blend/upgrade_kit.blend` | `game/assets/glb/props/upgrades/comfort.glb` | Blender MCP rebuilt · accepted |
| upgrade_smart_sugar | Five-reservoir automatic sugar console | 0.58 m wide | `assets_src/blend/upgrade_kit.blend` | `game/assets/glb/props/upgrades/smart_sugar.glb` | Blender MCP rebuilt · accepted |
| upgrade_tip_jar | Three-level transparent coin jar | 0.68 m tall | `assets_src/blend/upgrade_kit.blend` | `game/assets/glb/props/upgrades/tip_jar.glb` | Blender MCP rebuilt · accepted |

## Acceptance gate

- One centered subject and no baked backdrop geometry.
- Correct upright orientation, origin at floor/counter contact point.
- Real-world scale within 2% of the manifest.
- No non-manifold holes visible from gameplay camera.
- Project budgets: major equipment 1k–2.5k triangles, characters 2k–3.5k, small props 200–800.
- 2K texture atlas maximum per asset, PBR roughness kept matte.
- Tintable gameplay parts remain separate named meshes/material slots.
- Godot import has no missing textures, animations, or unexpected collision.
- Final acceptance is based on a running 1280×720 gameplay screenshot.
