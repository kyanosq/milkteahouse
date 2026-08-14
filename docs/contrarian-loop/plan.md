# Contrarian Loop Plan — MilkTeaHouse Steam 推荐级打磨

## Objective

Raise the game to the quality bar where a demanding Steam player would leave a
recommendation (特别好评): tight first-hour experience, fair and legible core
loop, satisfying depth/replay arc, zero known gameplay defects.

## Non-goals (hard constraints)

- No 3D model/texture/GLB/Blender source changes (`assets_src/**`,
  `game/assets/glb/**`, `game/assets/music/**`, `game/assets/sfx/**` are
  protected; art issues may only be recorded).
- No Steamworks SDK / achievements (needs partner account + credentials).
- No code signing / notarization work (needs user credentials).
- No balance changes without deterministic bot evidence (autoplay/sim) before
  and after.

## Loop envelope

- Sprints: up to 3, each capped at 3 Generator→Evaluator rounds.
- Baseline (must stay green every round):
  `bash tools/run_godot_checks.sh` → 25/25 core.
- Release gate (final round only): `RUN_CAMPAIGN=1 bash tools/run_godot_checks.sh`
  → 25/25 core + 3/3 campaign routes.
- Real-environment surfaces available to the Evaluator:
  - headless autoplay bots (`BOT_PROFILE/BOT_DAY/BOT_SAMPLE` via
    `game/tests/autoplay.tscn`) with serve-rate/clean-rate/star metrics;
  - windowed screenshot harness (`SHOT_*` env via `game/tests/screenshot.tscn`);
  - the 25-scene regression suite;
  - Android arm64 emulator (rebuild path recorded in Iteration 54).
- Rollback rule: every fix lands as its own commit; a failing round is fixed
  forward, never by weakening acceptance criteria or tests.
- Evidence lives in `docs/contrarian-loop/evaluations/` and
  `design/qa/iteration55*/`.

## Sprint order

1. **S1 弱点清障** — fix the highest-severity weaknesses found by the audit
   agents (gameplay defects first, then feel/legibility).
2. **S2 首小时体验** — tutorial/early-day pacing and readability improvements
   validated by newbie-bot metrics and fresh screenshots.
3. **S3 深度与重玩信号** — replay-arc legibility improvements validated by
   campaign sim + contracts data.

Sprints beyond audit findings are skipped rather than invented.

## Roles

- Planner/Generator: main session (this agent), commits directly.
- Evaluator: fresh subagent each round with read+run tools only; writes
  `evaluations/<sprint>-round-<n>.md`; MUST be able to FAIL a round; never
  edits code.

## Stop condition

All feature-list items pass with recorded evidence, or the 3-sprint cap is
reached, or two consecutive rounds fail on the same issue class (escalate to
Planner redesign).
