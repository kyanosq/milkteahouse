# Godogen Asset Generator (Qoder Plugin)

Cross-engine AI game-asset generation skill, packaged from
[htdt/godogen](https://github.com/htdt/godogen) (`asset-gen/` directory) into a
Qoder-native plugin.

## What it does

- **Images (PNG)** — Gemini (precise prompt following) / xAI Grok (cheap, high
  quality) via `tools/asset_gen.py image`, with image-to-image variants and
  sprite-kit grid slicing (`tools/grid_slice.py`).
- **3D models (GLB)** — Tripo3D image-to-3D (`glb`), biped rigging (`rig`),
  animation retargeting with ~100 presets (`retarget`), and free `resume` for
  timed-out jobs (avoids double-charging).
- **Animated sprites** — reference → pose → video → frame extraction →
  loop-trim (`tools/find_loop_frame.py`) → background matting
  (`tools/rembg_matting.py`, see `rembg.md`).

⚠️ All generation calls hit **paid APIs** — the skill instructs the agent to
confirm spend with the user before generating.

## Provenance

- Source: https://github.com/htdt/godogen (cloned 2026-07, MIT-style license in
  upstream `LICENSE.md`)
- Skill source path: `asset-gen/` (SKILL.md + rembg.md + tools/)
- Logo: no upstream logo exists; `assets/avatar.svg` is a placeholder drawn for
  this package (cube/asset motif), not an official godogen logo.

## Included

- `skills/asset-gen/SKILL.md` — adapted: upstream `${ASSET_SKILL_COMMAND}` /
  `${ASSET_GEN_SKILL_DIR}` / `${RUNTIME_ASSET_DIR}` are publish-time template
  variables rendered by upstream `publish.sh`; this package resolves
  `${ASSET_SKILL_COMMAND}` to `/asset-gen` and documents how to set the other
  two at the top of SKILL.md. No workflow content was changed.
- `skills/asset-gen/rembg.md` — background-removal guide (referenced by SKILL.md).
- `skills/asset-gen/tools/` — `asset_gen.py`, `tripo3d.py`, `rembg_matting.py`,
  `find_loop_frame.py`, `grid_slice.py`, `requirements.txt` (all copied verbatim).

## Omitted (not part of the skill)

- `prompts/runtime.md`, `engines/*.md`, `publish.sh`, `docs/` — these belong to
  godogen's game-repo generator scaffold (CLAUDE.md/AGENTS.md rendering), not to
  the asset-generation skill itself.

## Setup

1. API keys (see `CONNECTORS.md`): `GOOGLE_API_KEY`, `XAI_API_KEY`,
   `TRIPO3D_API_KEY`.
2. Python deps: `pip install -r skills/asset-gen/tools/requirements.txt`
   (rembg needs `rembg[cpu,cli]` or `rembg[gpu,cli]`).
3. System tools for the sprite pipeline: `ffmpeg`, `imagemagick`.

## Validation

- `python3 <create-plugin>/scripts/validate_qoder_plugin.py plugins/godogen-asset-gen` — see conversation record.
- All JSON manifests parse; manifest paths verified to exist.
