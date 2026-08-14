# S1 Evaluation — Round 1

- Evaluator: independent subagent (did not author any game code; no game file modified)
- Commit under review: `0d33708` "S1 feel and legibility pass from three audit dimensions" (parent `41d1229`)
- Date: 2026-08-15 · Godot 4.6.3 · macOS arm64

## VERDICT: PASS

All 8 contracted behaviors are implemented and evidenced; the 25/25 check gate passes;
no economy constant, goal formula, price, or patience rate changed; no test was weakened;
new motion is reduced-motion gated; the flash is bounded and does not overflow.
Two follow-ups are required (documentation/baseline integrity + S3 re-baselining) —
neither violates a contract hard-fail gate, but one is a Generator report-accuracy
issue that must be corrected in the record.

## Raw gate outputs (observed by evaluator)

Check suite — `bash tools/run_godot_checks.sh 2>&1 | tail -3`:

```
[UPGRADE] passed coins=1430 levels=7/10 patience=1.54 shakes=3 auto_sugar=true tip=1
[GODOT_CHECKS] PASS tests/upgrade_check.tscn
[GODOT_CHECKS] PASSED core=25 campaign=0 failed=0 logs=/private/tmp/milkteahouse-godot-checks.6k0BCP
```

Bots (headless, deterministic — 4 identical repeats of the n3 run):

```
S1 newbie d3:   [RESULT] earned=222 net=171 goal=134 stars=3 served=17 perfect=14 perfect_rate=82% reworks=3 angry=0 serve_rate=100% event=lunch_rush
S1 regular d7:  [RESULT] earned=349 net=211 goal=206 stars=3 served=24 perfect=19 perfect_rate=79% reworks=5 waste=0 rent=40/40 angry=0 serve_rate=100% event=influencer_day event_bonus=25
parent commit (worktree, same machine) newbie d3:
                [RESULT] earned=185 net=136 goal=134 stars=2 served=16 perfect=13 perfect_rate=81% reworks=3 angry=0 serve_rate=100% event=lunch_rush
S1 + SHAKE_GRACE_SECONDS=0.0 (attribution control, /tmp copy, since deleted) newbie d3:
                [RESULT] earned=185 net=136 goal=134 stars=2 served=16 perfect=13 perfect_rate=81% reworks=3 angry=0 serve_rate=100% event=lunch_rush
```

Contract gate reading: serve_rate/stars must not regress (newbie d3 baseline 2★/100%,
regular d7 baseline 3★/100%). Observed: 3★/100% and 3★/100% — no regression, no collapse.

Screenshots captured fresh by evaluator: `/tmp/ev_day.png` (SHOT_DAY=10),
`/tmp/ev_end.png` (SHOT_END=1), plus supporting `/tmp/ev_day12.png`, `/tmp/ev_batch.png`.

## Per-behavior evidence

| # | Behavior | Evidence | Status |
|---|----------|----------|--------|
| 1 | Goal stretch to 140% + tick + 3★ copy | `day_shop.gd`: `hud_goal_bar.max_value = STAR_GOAL_MULT*100.0` (STAR_GOAL_MULT=1.4), goal-tick ColorRect anchored at 1/1.4, `hud_goal_text` uses new `DAY_HUD_GOAL` (zh "…· 3★需%d", en "…· 3★ at %d"); settlement `result_goal.max_value = maxi(goal+1, star_goal)` with tick at goal/max and `DAY_RESULT_GOAL_NUMBERS` (zh+en). CSV rows present in both locales. Verified in shots: HUD reads `0/260 · 3★需364` (260×1.4=364) with tick at ~71%; settlement reads `171 / 123 · 3★需172` with tick at ~71%. Pinned by new onboarding_check assertions (max=140, 1 tick child, "3★" in copy). | PASS |
| 2 | Verdict 1-2★ discloses net | `day_shop.gd` `_end_day`: stars 1 or 2 → `DAY_RESULT_VERDICT_%d` with `[net_operating]`; stars 0/3 unchanged. CSV: "Goal Reached · Net %d" / "目标达成 · 净入 %d" (+ VERDICT_1 both locales). Live evidence: ev_end.png shows verdict "目标达成 · 净入 86" on a 2★ result. | PASS |
| 3 | Patience tri-band + head-customer band-drop cue | `_process`: band = 2 if ratio>0.70 / 1 if >0.40 / else 0 — matches service_tip tiers; fill styles mint 27B9A7 / amber D99A43 / red E5484D (`_style_order_card`), seconds label recolored on band change via `PATIENCE_BAND_COLORS`. Head customer (i==0) crossing down a band plays one cue: amber→`Sfx.play("select",0.72)`, red→`Sfx.play("customer_leave",1.4)`+`Haptics.play("warning")`. Cue is transition-gated (patience is monotonic → each band crossing fires once; equivalent to cooldown for this signal); Sfx additionally cooldown-gates "select" (45ms) and `play()` early-returns under `GameState.test_mode` (autoplay sets it) — "test-mode muted as usual" holds. Visual: ev_day12.png shows one card at 5s left with red bar+red label beside mint cards (pixel scan confirms red run x29-82 y202 and mint runs y358/y516); ev_day.png froze all-mint, which is a capture-timing artifact, not a defect. | PASS |
| 4 | Prep fill per state + GOLDEN/SPOILED cues | `_prep_fill_style`: GOLDEN F5C351 / LATE D99A43 / SPOILED E5484D / default 8C67B5; applied via `add_theme_stylebox_override("fill", …)` in `_configure_prep_controls` (state is part of the dedup key, so the fill follows every state change). `_play_prep_transition_cue`: GOLDEN → `Sfx.play("coin",1.3)`+confirm haptic; SPOILED → `Sfx.play("bad",0.9)`+warning haptic — existing SFX pitched, no new audio files. Visual: ev_batch.png (SHOT_BATCH=1) pixel scan shows a 491px-wide #F5C351 fill — the golden fill rendering live. | PASS |
| 5 | Wrong delivery names component + tossed-cup cost | `_on_deliver` wrong branch calls `_flash(DAY_FEEDBACK_WRONG, [_wrong_component_names(order), consumed_cost])` BEFORE `_reset_cup()` (snapshot semantics honored — `_wrong_component_names` reads cup_base/milk/sugar/tops while still populated). `_wrong_component_names` diffs base/milk/sugar/tops with localized names (DAY_COMPONENT_BASE/MILK/SUGAR/TOPPING zh+en) joined by `DAY_FEEDBACK_WRONG_PARTS_SEP`. CSV: en "Wrong: %s · cup tossed (−%d). …", zh "做错了：%s · 已倒杯（−%d）——…" — 2 args in both locales, no format mismatch. Pinned by new operating_cost_check assertions (component name + cost in flash text); flash itself is UI-only and fires in test mode as before. | PASS |
| 6 | Reward flash bounded + tween kill | `feedback_label`: `custom_minimum_size = Vector2(760,0)`, `autowrap_mode = WORD_SMART`, `max_lines_visible = 2`, centered; `_flash` kills `_flash_tween` before creating the new one (kill-and-restart). x438+760=1198 < 1280 viewport. Pixel evidence: flash-row pixels span x446-1225 only; settlement capture shows no clipped or overlapping text. | PASS |
| 7 | Shake 0.5s decay grace + ceili counter | `SHAKE_GRACE_SECONDS := 0.5` set on every registered shake; `_process` drains `_shake_grace_left` first and applies `SHAKE_DECAY` only after grace expires. Display: `_shake_count_display() = mini(ceili(shake_progress), _shakes_needed())` used by all four copy sites. Seal condition unchanged — still `shake_progress >= _shakes_needed()` (day_shop.gd:1149); at level 0, 5 shakes still seal exactly; grace only pauses decay, it does not reduce the net requirement. SHAKE_DECAY stays 1.2. Pinned by onboarding_check (`_shake_count_display()==2` at progress 1.2). | PASS |
| 8 | Streak pill pulse, reduced-motion gated | `_pulse_streak_pill()` called on streak increment; first line `if GameState.reduced_motion(): return`; kills `_streak_tween` and restarts (scale 1.0→1.22→1.0 with TRANS_BACK ease-out). Target is `hud_streak.get_parent().get_parent()` = the pill's PanelContainer (same chain the pre-existing visibility code uses), not the HUD row. `GameState.reduced_motion()` exists (game_state.gd:580). | PASS |

## Non-goals / hard-fail sweep (diff `git show HEAD`)

- `SHAKE_DECAY := 1.2` unchanged; star threshold is the same 1.4 value via a named constant
  (`earned >= int(goal * STAR_GOAL_MULT)`); patience drain line untouched
  (`c["patience"] -= delta * (1.0 if i == 0 else 0.5) * …`); no price/wage/goal-formula edit;
  `endless_contracts.gd`, `prep_batch.gd`, `operating_costs.gd`, `upgrade_catalog.gd` not touched.
- Tests: onboarding_check.gd +12 lines, operating_cost_check.gd +13 lines — additions only,
  no assertion removed or weakened. input_check.gd untouched (contract listed it as "likely", not required).
- Localization: changed/added rows all have matching format args in zh and en; suite green.
- Reduced motion: the only new motion (streak pill scale tween) is gated; other changes are
  color/copy/tick (static) or a pre-existing alpha tween with added kill logic.
- Unlisted-but-benign hunk: `LIST_SEPARATOR,"; ",、` → `LIST_SEPARATOR,; ,、` (same effective
  en value "; "; CSV hygiene). No behavior change detected; localization check passes.

## Follow-up findings (Generator must action; none block this PASS)

1. **Generator's bot-baseline claim is inaccurate and must be corrected in the record.**
   The commit message states "bots match the audit baseline (newbie d3 identical
   185/2-star/100% serve)". A fresh run of the shipped commit yields, deterministically
   (4/4 identical runs), earned=222, stars=3, served=17, serve_rate=100%. The pre-S1
   parent commit on the same machine reproduces the audit baseline exactly
   (185/2★/16 served). The Generator either ran the bot before implementing the shake
   grace or did not re-run it. The artifact itself violates no contract gate — serve
   rate held at 100% and stars did not regress (2★→3★ is an improvement, not a
   regression) — but a false evidence claim in the sprint record cannot stand.
   Required: append a correction note (commit message follow-up or sprint log) with the
   real post-S1 numbers.
2. **The +20% newbie-d3 spike exceeds the ±15% observation threshold and is fully
   attributed to contracted behavior 6.** Controlled experiment: S1 code with
   `SHAKE_GRACE_SECONDS := 0.0` (everything else identical) returns exactly to the
   185/2★/16-served baseline. Mechanism: the autoplay bot presses at ~4.2/s
   (0.24s interval < 0.5s grace), so decay never engages during a shake burst — a
   5-shake seal now takes 5 presses instead of ~7, each cup seals ~0.5s faster, tips
   land in higher patience tiers, and one extra customer gets served (16→17).
   Regular d7 shows the same direction (+13.7%, 307→349, served 21→24, still 3★/100%).
   This is the intended, prescribed effect of CF#5's fix (audit explicitly ordered the
   0.5s grace), not an unauthorized balance edit — no economy number changed. But it
   materially shifts first-week effective difficulty.
3. **S3 balance work must re-baseline against post-S1 bots.** The first-hour audit's
   difficulty-wall analysis (FH#2: "newbie is 2★ every day, misses 3★ by 3 coins on
   d3") is stale: the same bot now clears day 3 at 3★ with 222 (166% of goal). Any S3
   goal-curve or catch-up design must use the new baselines (newbie d3 222/3★,
   regular d7 349/3★), not the audit numbers, and should re-check the 1★-death
   projection for days 5-8 under the faster seal loop.
4. Minor, non-blocking: the patience band-drop "cooldown" is implemented as a
   per-crossing transition gate rather than a time-based cooldown — functionally
   equivalent here because patience is monotonic within a customer (each band can be
   crossed at most once), and Sfx still enforces its per-cue cooldowns. Worth a comment
   in code if anyone later adds patience-refill mechanics, which would break the
   monotonicity assumption.
5. Minor, non-blocking: `_shake_grace_left` is not reset in `_reset_cup()`; it decays
   on its own within 0.5s and has no effect while `shake_progress == 0`, so it is
   harmless today.

## Evaluator's trail (for reproducibility; all temp artifacts removed)

- Worktree at /tmp/mth-baseline (parent commit) used for the baseline bot run — removed after evidence capture; repo working tree untouched (`git status` clean, `git worktree list` shows only main).
- /tmp/mth-s1-nograce (S1 + grace=0 attribution control) and pixel-scan scripts — deleted.
- Kept evidence: /tmp/ev_n3.log, /tmp/ev_r7.log, /tmp/ev_n3_base.log, /tmp/ev_n3_nograce.log,
  /tmp/ev_day.png, /tmp/ev_end.png, /tmp/ev_day12.png, /tmp/ev_batch.png.
