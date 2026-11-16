# Soft toon character pass — 2026-09-05

Native Godot captures: [staff close-up](characters.png), [staff work animation](characters.mp4), [shop](day8.png), [shop gameplay](gameplay.mp4), [Mobile Day 10 with staff](mobile-staff-day10.png).

- Rebuilt all three staff members and the generic barista with 13-bone skins, `Work`/`Idle` clips, tailored shirts, curved aprons, straps, pockets, cuffs, name badges and a hand-bound cup. Mint cap, coral ponytail and indigo glasses distinguish the roster. Each uses 8 meshes and 14,832–15,404 triangles.
- Refined walking customers to 13,116 triangles: tapered hair locks, fitted forehead opening, irises, ears, nose, collar, buttons, cuffs, shoe seams and covered knee joints. The existing foot-planted gait, queue advancement, pause and reduced-motion behavior remain active.
- Used Godot's native toon diffuse, disabled specular/metallic shine, softened contact shadows and balanced daylight with a cool fill. A canvas shader softens highlights and color transitions in existing painted props while preserving transparency and keeping the interactive text/UI unchanged.
- Staff stand at floor level behind the counter; a cropped view composites their heads and working hands above the painted background. The head has a matching physics hit target. The staff skeleton resumes after reduced motion is disabled; the obsolete whole-body bob/tilt was removed.
- Staff models load on demand. Removed superseded photographic wood/floor maps from the shop export; the runtime keeps its shared floor art. Shop GLB decreased from 4,479,504 to 336,616 bytes without changing its 6,368 triangles.

Validation: all 26 core Godot checks passed. Model, staff and input checks were repeated after final material/placement adjustments. The model check verifies skeletal clips, actual hand movement, reduced-motion pause, matte toon materials and a physics ray to the visible staff head. Forward Mobile's full-upgrade Day 10 scene with three customers plus 小满 measures 90 meshes, 67,612 triangles, 251 maximum draw calls and 156.55 MiB video memory, passing the existing budgets and visible-bounds gates. The desktop Metal run is a resource-budget check, not a phone frame-rate measurement. Source/runtime GLB pairs match; `git diff --check` passes.

Rebuild a character with `CHARACTER_ROLE=taozi blender --background --python assets_src/blend/build_customer_walk.py`; choose `customer`, `barista`, `xiaoman`, `taozi` or `acheng` as the role. Then run `blender --background --python assets_src/blend/optimize_shop_export.py` and reimport Godot. Editable sources are in `assets_src/blend/`. The installed local Blender was used because Blender MCP could not connect.

Capture commands, from the repository root:

```sh
SHOWCASE_OUTPUT=/absolute/path/characters.png SHOWCASE_MOVIE=1 godot --path game res://tests/character_showcase.tscn --write-movie /tmp/characters.avi --fixed-fps 30 --disable-vsync
WALK_STAFF=1 WALK_CAPTURE=1 godot --path game res://tests/customer_walk_check.tscn --write-movie /tmp/gameplay.avi --fixed-fps 30 --disable-vsync
PERF_STAFF=xiaoman PERF_OUTPUT=/absolute/path/mobile.png godot --path game --rendering-method mobile res://tests/mobile_render_check.tscn
```

The MP4 files are H.264 encodings of engine recordings. Native material behavior follows [Godot's StandardMaterial3D documentation](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html).
