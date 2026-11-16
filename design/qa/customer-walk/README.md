# Customer walking — 2026-09-05

Actual Godot recording: [walking.mp4](walking.mp4) (18 seconds, 1280 × 720, 30 fps). Three customers enter, the first leaves at 8.5 seconds, the queue advances, and a new customer joins. Stills: [Day 1](day1.png), [Forward Mobile Day 10](mobile-day10.png).

The former sliding portrait sprites now use one rounded, skinned GLB with two color palettes: 13 bones, 8 meshes, 6,912 triangles, `Walk` and `Idle` clips. Walk phase follows travelled distance; the baked 0.36 m stride cancels root travel during stance, lifts the other foot and counter-swings the arms. Turning, acceleration and stopping run in Godot. Both feet remain grounded while idling.

Queue cards retain their interaction and promotion rules. Departing customers walk out while remaining customers move into the vacated slots. Pause freezes movement; reduced motion settles arrivals and cleans up departures. Actors share the shop's world, perspective and lights. A 360 × 720 transparent camera crop places them above the painted background and below the rail/cards without allocating another full-screen render target.

Validation:

- `bash tools/run_godot_checks.sh`: all 26 checks passed. The walking check covers skeletal clips, planted feet, queue movement, pause and reduced motion. Walking and input checks were rerun after the final route adjustment.
- Forward Mobile Day 10, three customers, full upgrades: 82 visible meshes, 33,596 triangles, 227 maximum draw calls, 153.95 MiB video memory. Existing geometry, memory and visible-bounds checks passed. This desktop Metal capture is not a phone frame-rate measurement.
- `git diff --check` passed; source/runtime customer GLBs are identical.

Rebuild: `blender --background --python assets_src/blend/build_customer_walk.py`, then import the Godot project. Editable source: `assets_src/blend/customer_walk.blend`; runtime: `game/assets/glb/customer_walk.glb` (paths relative to the repository).

Record: `WALK_CAPTURE=1 godot --path game res://tests/customer_walk_check.tscn --write-movie /tmp/customer-walk.avi --fixed-fps 30 --disable-vsync`. The MP4 is an H.264 encoding of that engine output.
