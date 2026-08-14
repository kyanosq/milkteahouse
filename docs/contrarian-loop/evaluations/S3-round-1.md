# S3 Round 1 Evaluation — VERDICT: PASS

Date: 2026-08-15. Evaluator: independent (did not author the code).
Method: commands + code reads only (no screenshots, no pixel scans).

## Item 1 — Core checks 25/25

`bash tools/run_godot_checks.sh 2>&1 | tail -2`

```
[GODOT_CHECKS] PASS tests/upgrade_check.tscn
[GODOT_CHECKS] PASSED core=25 campaign=0 failed=0 logs=/private/tmp/milkteahouse-godot-checks.nqtdO2
```

PASS — 25/25, failed=0.

## Item 2 — Campaign run

`RUN_CAMPAIGN=1 bash tools/run_godot_checks.sh 2>&1 | tail -2` (background, exit 0)

```
[GODOT_CHECKS] PASS campaign_strategy:growth
[GODOT_CHECKS] PASSED core=25 campaign=3 failed=0 logs=/private/tmp/milkteahouse-godot-checks.nqXw2J
```

PASS — core=25 campaign=3 failed=0; all three strategy routes green.

## Item 3 — game/autoload/endless_contracts.gd

- Lines 88/90 (streak_stage, precision_shift) — exact match to the required
  formula: `return 28 + mini(2, elapsed / 12) + clampi((elapsed - 24) / 6, 0, 10)`
- Line 79 cost cap: `var step := clampi((target_day - FIRST_TARGET_DAY) / 3, 0, 14)`
  → cap 14 (14 * 15 = +210 max step, saturating at day 58). PASS.
- Lines 99-102 `goal_for_day`: `base = mini(380, 80 + 18 * day)`; day <= 30 →
  base; else `mini(420, base + (day - 30) * 2)`. Piecewise 380 → 420 past
  day 30. Day 40 = 400 (as repinned by contract); saturates 420 at day 50. PASS.
- `rank_name` lines 211-214: `stamps >= 20` → CONTRACT_RANK_LEGEND;
  `stamps >= 15` → CONTRACT_RANK_CITY_PLUS (above GOLD at 12). PASS.
- Day-16 values, hand-computed with elapsed = 0:
  - target: 28 + mini(2, 0/12)=0 + clampi(-24/6=-4, 0, 10)=0 → **28** (unchanged)
  - cost: step = clampi(0/3, 0, 14) = 0 → 120/150/190 base costs (unchanged)
  - revenue: goal_for_day(16) = min(380, 368) = 368; ceil(368 * 1.0 * 1.35) =
    ceil(496.8) = **497** (unchanged)
  PASS — day-16 assertions unaffected.

## Item 4 — Relief experiment fully reverted

`grep -rn "yesterday_stars\|day_stars\|BOT_PREV_STARS\|prev_stars" game/`
→ no output, exit code 1 (zero matches). PASS.

## Item 5 — game/tests/campaign_strategy_sim.gd

Lines 374-381: dated comment `2026-08-15 再基线：S1 摇杯衰减宽限… careful 从
A/30★/80-180 迁移到 S/33★/500-550，balanced 现金上限抬至 2360。门禁仍是
逐项精确钉定，非放松。` Expected table exactly as required:
`careful: S / 9 levels / 33★ / 500-550`, `balanced: S / 10 / 42★ / 1900-2360`
(ceiling 2360), `growth: S / 10 / 42★ / 3500-4200`. PASS.

## Item 6 — Rank localization keys

`grep -n "CONTRACT_RANK_CITY_PLUS\|CONTRACT_RANK_LEGEND" game/localization/ui.csv`

```
812:CONTRACT_RANK_CITY_PLUS,City Legend,全城名店
813:CONTRACT_RANK_LEGEND,Milk-Tea Legend,奶茶传奇
```

PASS — both keys present in both languages (EN + CN).

## Issues found

None blocking. Two observations:

1. Contract S3.md "Included behavior 1" (追赶宽限 ×0.85 relief) is absent from
   the code — it was fully reverted (Item 4 confirms zero trace), matching the
   evaluator mandate for this round. The contract text is now stale relative to
   shipped behavior; a follow-up note in the contract file would avoid confusion.
2. Contract wording "每 2 天 +1" (every 2 days +1) does not literally describe
   the implemented `+2/day` slope; the pinned day40=400 value and 420 cap do
   match the code, so this is a doc-wording nit only.

Bottom line: 6/6 items verified, all green.
