# P2 Mastery Playtest — 2026-08-15

Player profile: optimizing/completionist. Method: D10/D14 upgrade-panel shots, campaign report + New Shop+ confirm, D13 research notebook, skilled headless bot (day 14, bare and full upgrades).

## Findings

1. **[流失风险] Endless endgame fully saturates — every ladder hard-caps.**
   Evidence: rank stops at 20 stamps ("MAX", `game/autoload/endless_contracts.gd:210-228`); streak/precision targets cap at 40 (creep +1/6d ends ~day 100, `:84-93`); revenue target caps at 420×1.08×1.35≈612 (`:96-102`) while a full-upgrade skilled shop earns 778/day (bot RESULT: earned=778 net=576) — revenue sprint becomes free stamps. Sign costs saturate at +210 from day 58 (`:77-80`).
   Fix: after day 100, switch to an uncapped soft curve (+1 target / 4 days) and extend rank tiers past LEGEND (e.g. 30/40/50 stamps with new names); make revenue target ≥ 85% of trailing 5-day earned so a maxed shop can't autopilot it.

2. **[流失风险] Post-full-upgrade coins are a dead currency mid-campaign.**
   Evidence: only 4 upgrade tracks, total tree cost 2930 (`autoload/upgrade_catalog.gd:4-38`: 800+940+360+830). Bot nets 373/day bare, 576/day upgraded (day 14), so full tree lands ~day 11-13; afterwards the only sink is one contract/day (≤400). Upgrade panel at D14 (p2_d14end.png) already reads as "nothing left to want".
   Fix: add endless-only coin sinks with flat weekly cost — decor tiers that only style the shop, contract re-roll fee, or a "premium booth" that raises event bonus; or convert surplus coins to inspiration at a poor-but-nonzero rate (e.g. 50:1).

3. **[挫败] New Shop+ route rewards are near-cosmetic; the choice is completionist, not strategic.**
   Evidence: `autoload/legacy_routes.gd:66-74` — rush/precision pay +1 coin per trigger, trend +3 on menu orders, vs 574-778/day revenue (<2% swing), while `:5` makes all goals +8% harder. Route risk is real (spawn 0.88 / patience 0.88) but the reward never scales with skill.
   Fix: scale route bonus with performance (rush: +1 per 3-streak, uncapped; precision: tip ×1.5 at patience>0.85; trend: menu orders +5% price per hype tier), and show expected-day-1 delta on the confirm dialog.

4. **[挫败] Tracked endless stats exist but are never surfaced.**
   Evidence: `endless_contracts.gd:196-202` records completed/failed/streak/best_streak; the only UI reads are rank_name + stamps (`ui/endless_contract_panel.gd:112-114`, `scenes/day_shop/day_shop.gd:2584-2585`). A streak chaser can't see their 12-contract streak anywhere.
   Fix: one line in the contract panel header: "连签 X (最佳 Y) · 成功 A / 失败 B"; reuse it in the day-end endless hint.

5. **[打磨] Campaign report nudges mastery but never quantifies the gap.**
   Evidence: p2_report.png / `scenes/campaign_summary/campaign_summary.gd:376-384` — next-challenge picks the weakest dimension ratio but shows no "距 S 还差 N 分" and no S threshold per dimension; grade ceiling is single S (no S+/SS for repeat runs). No per-day revenue/stars trend for optimizers.
   Fix: print each dimension's S threshold and points-short on the card; add a "S 需 90 分" line under the score; consider S+ at 96+.

6. **[打磨] Night-lab research has no repeat/preset — completionism is 150+ redundant taps.**
   Evidence: `scenes/night_lab/night_lab.gd` — every craft re-picks base/milk/topping/sugar + try (only `_on_try`, line 916; no repeat/preset anywhere). Notebook goals are 10 legends + 12 affinities + 3 dark (p2_notebook.png), each needing multiple mixes.
   Fix: "再来一杯" button restoring the last mix, and one-tap presets for known recipe IDs once discovered.

7. **[打磨] S-grade New Shop+ bonus is too small to be a trophy.**
   Evidence: `autoload/game_state.gd:785-797` — S grants 80 coins + 3 inspiration vs a 2930-coin tree and daily 60 rent; everything else is wiped by reset_progress. An S run starts effectively identical to a C run.
   Fix: scale bonus (S: 200 coins + 5 inspiration + one free tier-1 upgrade) or let S keep one quality-of-life upgrade (e.g. smart_sugar) across New Shop+.

## Strengths

1. **Contract risk is fully legible before signing** — sign cost, refund %, inspiration, and quantified traffic/patience deltas on every card (`endless_contract_panel.gd:180-211`), plus explicit creep caps commented and enforced (`endless_contracts.gd:84-102`). Optimizers can compute expected value; no hidden gotchas.
2. **Campaign report structure genuinely rewards mastery** — 4 dimension cards with value/max sub-scores and progress bars, best-run legacy line, routes-cleared 0/3 tracker, and a weakest-dimension challenge line (p2_report.png; `campaign_summary.gd:138-147, 149-167`); New Shop+ confirm quantifies exactly what carries and what resets (p2_confirm.png).
