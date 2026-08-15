# Six-Player Playtest Summary — Optimization Round

Six parallel playtester agents (first-time / mastery / gamepad-only / English /
night-researcher / late-game pressure) each ran the real game via the windowed
screenshot harness and headless player-model bots, then filed evidence-backed
findings (`p1-first-time.md` … `p6-pressure.md`). Every claimed defect below
was re-verified against code before fixing.

## Fixed this round (all with regression assertions; 25/25 suite green)

| # | Source | Finding | Fix |
| --- | --- | --- | --- |
| 1 | P3 手柄不可用 | Night-lab shelf tiles overrode normal/hover/pressed but never `focus` — gamepad navigation was blind with focus grabbed onto an invisible target | 3px cocoa focus ring on every tile (border-only, icon never covered); night_check asserts the stylebox |
| 2 | P5 困惑 | Changing any ingredient after a shelveable trial silently voided the pending score — iterating researchers read it as a bug | Invalidation now appends a visible NIGHT_SHELF_VOIDED result line + cue; night_check asserts the message |
| 3 | P1 困惑 | HUD jargon pills (店铺0/10 · 完美0 · x0 · 租金D7) had no labels or tooltips | Six localized tooltips on the pills (goal/star rule, shop levels, perfect/combo, streak, inspiration, restock+rent); onboarding_check asserts |
| 4 | P4 难读 | Five EN strings dropped the Chinese 、 without commas ("tea milk toppings", "press 1 2 or 3") | Commas restored in all five keys |
| 5 | P1 困惑 | Day settlement always showed zero-noise sub-line "主推销售 0 · 事件 +0" on quiet days | Revenue detail sub-line only renders when either income exists |
| 6 | P2 挫败 | Campaign report never quantified "points to S" per dimension | Each dimension card now shows "距满分 +N" when below cap (zh+en) |
| 7 | P6 公平感 | Revenue-sprint contract read as unfair when a no-upgrade shop forfeits the full fee | Bot-verified feasible with intended progression (upgraded regular day-16: 573 vs 497 target → success); contract copy now warns it targets a fully-upgraded shop |

## Verified-but-recorded (product decisions, not unilaterally changed)

- P2: endgame coin economy saturates (~576/day income vs 2,930 full tree) and
  endless rank/target caps still trail a maxed shop's 778/day — the upgrade-tier
  / endless-economy redesign stays on the recorded product list (3rd time
  flagged; strongest evidence yet).
- P2/P6: New Shop+ route payouts near-cosmetic; endless streak/completed/failed
  stats tracked but unshown.
- P1: core objective (goal/stars/timer) not taught in the tutorial — teaching
  step 6 or interactive gating remains the recorded tutorial item.
- P3: tutorial skip/next unstyled; mouse wording in gamepad mode for idle
  order cards.
- P5: market cards lack formula + tier cutoffs; try-button disabled without
  explanation below 2 inspiration; dark slots hidden behind the 主推 pill.
- P4: "Fu"/"No" sugar-tile truncation fallback; ¥ vs coins currency mix; a few
  machine-y event lines.

## Process notes

- P6's harness misuse (BOT_DAY=12 with a day-16 contract; SHOT_UPGRADES
  swallowing scenario flags) produced two false captures — re-run correctly
  by the agent itself before reporting.
- Zero CJK leftovers on EN screens (matches the earlier value-as-key audit).
