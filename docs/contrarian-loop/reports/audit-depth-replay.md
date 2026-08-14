# Depth & Replay Value Audit — Milk Tea House (Godot 4.6)

Reviewer stance: demanding Steam player auditing depth and replay value across the 14-day campaign, New Shop+ routes, endless contracts, and the research/collections night loop. Evidence only — every claim below is backed by a file:line, a deterministic sim number, or a doc table. No game files were modified.

## Sim and doc evidence captured

- Fresh campaign strategy sim, 2026-08-15 (`RUN_CAMPAIGN=1 tools/run_godot_checks.sh`): **core=25 PASS, campaign=3 PASS, failed=0.**
  - Growth route (skilled): `gross=8632 operating_net=6965 coins=3990 upgrades=10/10 finish_day=10 stars=42/42 served=390 angry=0 menu=5 rotations=8 discoveries=5 score=100 grade=S`. Day 13 optimal action logged as `actions=hold`; day 14 as a 3-slot featured rotation.
  - Conservative/balanced routes (roadmap Balance watch, re-asserted in iteration 54): 9/10 upgrades + A + 174 coins; 10/10 on Day 11 + S + 1,516; growth 10/10 on Day 10 + S (3,990 in the current build).
  - New Shop+ route sim (roadmap): gross 6,033 / 5,962 / 5,903; attributable route bonus **105 / 159 / 78 coins**; all three finish the tree Day 10 and grade S; max cash spread 97 coins (5.9%).
- Difficulty tables (`design/design-qa.md`): newbie pressure lands Day ~8 (Day 9: 73%/140, Day 12: 57%/112) while skilled stays 100% with ~3–4× earnings; max-progression Day 12 skilled: 100% / 760 / 3★.
- Data (`game/data/ingredients.json`): topping unlock days `1,1,2,5,3,5,7,8` — **nothing new unlocks after Day 8**. 3 bases × 4 milks (incl. `none`) = 12 affinity cells; 10 legendary + 3 dark recipes.

---

## Ranked weaknesses (max 6)

### 1. [P0 — shallow/refund risk] Days 9–14 of the first campaign add zero new decisions — the back half is a literal replay of Days 3–8

**Evidence**

- `game/autoload/daily_events.gd:90-97` — `event_for_day` is `(day - 3) % 6`; the Day 9+ reorder branch requires `LegacyRoutes.is_active()`. In the first campaign, Day 9 = Lunch Rush (same as Day 3), Day 10 = Light Drinks (same as Day 4) … Day 14 = Group Day (same as Day 8). Six identical days with identical modifiers, same order, no intensity change.
- `game/data/ingredients.json` — last topping unlocks Day 8; `staff` decision is Day 8; rent caps at 120; upgrade tree completes Day 10–11 on every route (sim `finish_day=10`, roadmap "10/10 on Day 11/Day 10").
- The strategy harness's own optimal policy logs `actions=hold` for Day 13 — the decision space collapses to "hold cash, rotate menu," for the final third of the campaign. Growth ends with 42/42 stars and 3,990 coins sitting idle.

**Why a reviewer bounces** This is the exact "fun for 2 hours then repetitive" curve: Days 1–8 drip a new ingredient, event, rent tier, staff hire, or upgrade nearly every day; Days 9–14 drip nothing. The player has seen every event, every ingredient, and bought every upgrade — the remaining six shifts differ only in spawn/patience multipliers they already mastered. The finale (Day 14 report) is one screen, then New Shop+.

**Minimal fix (no new systems)** Give week 2 an identity using fields that already exist: (a) apply an intensity bend to the six existing events on their second pass (`spawn_mult` ×0.94, `patience_mult` ×0.96 in `event_for_day`, exactly the mechanism `apply_to_event` already uses for contracts); (b) reorder Days 9–14 using the already-authored `ROUTE_ROTATIONS` table even when no route is active; (c) add 2 late ingredients (Day 10/12) — journal clues, mastery cards, affinity cells, menu candidates and event-match rules all derive from `ingredients.json` automatically, so content, not systems. Optional: keep the star goal honest for skilled play late (42/42 with 0 angry customers is a formality; 80+18×day grows slower than upgraded throughput).

### 2. [P1 — thin] Endless mode freezes all progression by ~Day 28 — rank hits MAX, contract targets and costs stop moving, star goal is pinned

**Evidence**

- `game/autoload/endless_contracts.gd:85-87` — streak/precision targets are `28 + mini(2, (day-16)/12)`: they cap at 30 forever. `:78-79` — cost step is `clampi(..., 0, MAX_COST_STEP=6)`: price caps at base+90 around Day 34. `:95` — star goal pinned at 380 from Day 17.
- `:203-217` — ranks end at 12 stamps (`CONTRACT_RANK_GOLD`, then `CONTRACT_RANK_MAX`). With one contract per day, a regular-profile player (roadmap: clears all nine sampled combos) maxes rank around Day 28. After that: same 6 events, 13/13 journal, 10/10 upgrades, static targets, and a deliberate 78–122-coin sink per success.

**Why a reviewer bounces** "Endless" is on the store-page feature list; a player arriving at Day 15+ is the most invested customer, and the mode's entire progression is four rank titles that end. Past the stamps there is literally nothing left to earn — the contract is then a pure coin tax with a text stamp.

**Minimal fix** Parameters only: let cost step and streak/precision targets creep (+1 target per ~6 days past Day 34, sanity-capped ~40), extend `rank_name`/`next_rank_text` past 12 (e.g., 18 / 25 tiers reusing the same pattern), and let the 380 goal drift +1/day to a 420 ceiling after Day 30 so a fully upgraded shop still has a reason to optimize throughput.

### 3. [P1 — thin] New Shop+ routes are one tuning slider each — route identity is 1.3–2.7% of gross income

**Evidence**

- `game/autoload/legacy_routes.gd:54-74` — the entire gameplay delta is: rush `spawn_mult 0.88`, precision `patience_mult 0.88`, trend traffic step `0.06` (vs `0.04`), plus per-sale pings of **+1 / +1 / +3 coins** on qualifying sales (`sale_bonus`). Everything else (+8% goals, shared inheritance) is shared.
- Sim: route bonus totals 105 / 159 / 78 coins against ~6,000 gross; all three routes finish 10/10 on Day 10, grade S, cash within 5.9%. The only structural difference is the Day 9+ event reorder (`daily_events.gd:91-96`), which is real but subtle — same six events, different order.

**Why a reviewer bounces** "Turnover, Reputation or Trend District" promises three builds; what ships is the same shop with arrivals 12% faster, or patience 12% lower, or a slightly steeper featured-traffic curve. When every route ends S with the same upgrade timeline and near-identical cash, the second playthrough reads as "the same 14 days with a different colored sign" — which the roadmap itself flags as the human-test question ("district identity rather than an arbitrary difficulty shuffle").

**Minimal fix** Make each route bend one authored rule through systems that already exist, instead of only multipliers: trend route auto-pins one featured slot to tomorrow's best `event_match_bonus` candidate (forces menu engagement); precision route guarantees a critic every event day (reuse `customer_kind` cadence); rush route drops the third featured slot in exchange for the faster spawn clock. Escalate the sale pings (+1→+2 by week 2) so the route's identity is visible in the ledger rather than 78–159 coins across 14 days.

### 4. [P1 — thin] The night loop degrades into checkbox busywork once collections mature (~Day 12+)

**Evidence**

- `game/autoload/research_briefs.gd:106-110` — after the pair pool empties and every ingredient passes Lv3, briefs permanently become "make one 75+ quality cup" (`balanced`, `QUALITY_TARGET := 75`). Any competent player trivially satisfies this every night for the same +2 inspiration refund. That is a daily chore, not a decision.
- `game/autoload/research_progress.gd:15-20, 48-60` — the affinity matrix is 12 one-time cells (`record_pair` never re-rewards); realistically complete around Day 10–12, then pays a flat +2/night forever. `game/data/recipes.json` — the journal is 13 entries, all unlockable once the Day-8 topping arrives; `discoveries=5` in the growth sim means the collection is finished mid-run with nothing new in New Shop+ (progression is inherited).
- `game/autoload/market_tests.gd:41-53` — prices are hard-coded (18/15/12 by tier); the player never prices, positions, or risks anything — the only decision is which formula to send into the fixed 3-night arc.

**Why a reviewer bounces** By Day 12 the night is: one guaranteed brief cup, maybe start a market test, rotate three slots, sleep. The beautiful lab UI becomes a corridor. Reviewers specifically punish "night phase felt like clicking through menus after week one."

**Minimal fix** Keep the loop, escalate it: make the mature-state brief a quality ladder (75 → 82 → 88 reusing `QUALITY_TARGET` as a per-day array), and give market tests a player price choice among 2–3 authored points per tier that trade order frequency against margin (small data + one control in the existing board). Optionally let post-maturity repeated-pair trials feed mastery XP so the Lv4/Lv5 tail has a nightly purpose.

### 5. [P1 — thin] The upgrade tree is a linear checklist with one optimal path, dead after Day 10 while cash piles up

**Evidence**

- `game/autoload/upgrade_catalog.gd:4-38` — four items, ten levels, zero branches or exclusivity; total tree cost 2,930. Every sim route (and every New Shop+ route) buys everything (`finish_day=10/11`, 10/10). After Day 10 the night store is inert UI.
- Sims end with 1,516–3,990 coins and nothing left to purchase; the roadmap itself asks whether "a 520–600-coin final upgrade feels aspirational" — the current answer from the harness is that the final 3–4 days have no economic decision at all (`actions=hold`).

**Why a reviewer bounces** Progression systems are the retention spine of shop sims. A tree where every run ends identical (all four maxed) means the only expression is buy order, and even that converges by Day 10. Late-campaign cash with no sink reads as "the economy stops."

**Minimal fix** Reuse the catalog shape: add week-2 premium tiers (max_level 3→4 at 700–900 coins, consuming the documented surplus) and exactly one mutually exclusive pair (e.g., smart sugar vs. a "signature seal" that pays +1 on perfect serves) so each run has at least one real build fork. No new UI needed.

### 6. [P2 — could be deeper] Menu rotation pressure is real early, then the supply runs dry and set-and-forget returns

**Evidence**

- The rotation incentive is genuinely good on paper — fresh items order every 4th spawn vs 6th stale (`menu_catalog.gd:8-9, 173-177`), +2 launch premium (`:421`), event-match bonuses +2–6 with double rotation weight (`:388-409, 180-193`). But supply: 10 legendary + a handful of customs per run (each custom needs a 3-night market arc at 2 inspiration/trial). The growth sim finished Day 14 with `menu=5` total items and 8 rotations — choosing 3 of 5 slots is a thin decision, and two of three are auto-featured on registration (`_auto_feature`, `:509-511`).
- Once every item is evergreen, `advance_day` (`:424-432`) only decrements hype; a stale board is stable forever. Evergreen-vs-fresh is a 4-vs-6 spawn cadence and +2 coins — enough to matter Day 5–9, invisible once the player is rich.

**Why a reviewer bounces** "I rotated the menu for a week, realized nothing bad happens if I don't, and stopped." The event-match rules are the strongest version of this pressure and top out at +6/sale.

**Minimal fix** Make staleness bite: evergreen items that go N idle days lose 1 price coin per further 3 days (one field + branch in `advance_day`), and allow a paid "relaunch" of an evergreen formula that restores half hype (reuses hype fields). Bump match bonuses to 4–8 so matching tomorrow's event beats stacking the three priciest formulas — the exact behavior the roadmap says human sessions must verify.

---

## Three genuinely strong depth aspects

1. **Event-coupled featured-menu forecasting.** Tomorrow's event is forecast in the lab, and `event_match_bonus` (`menu_catalog.gd:388-409`) makes the match rules formula-readable (≤1 topping & ≤13 price for lunch rush; `none` milk & ≤30 sugar for light drinks; tier matches for critic/influencer days), with matched drinks getting double rotation weight and per-sale rewards. This is a real, learnable planning layer — the night board is a puzzle, not a checkbox, during the week it has supply.
2. **An operating economy with honest ledgers and recovery paths.** 50%-wholesale stock cost on every cup, priced discards, wages settling before stock/rent, shortfall → rest day without debt, rent capped at 25% of post-stock cash, and a five-column net ledger. The margin floors (69.7% / 71.6% / 74.4% by policy) and the sim's per-day wage/stock/rent lines show a shop sim where money decisions have texture and failure states are recoverable rather than punitive.
3. **Craft skill separates players without a death spiral.** Clean-build vs. rework keeps full revenue while withholding the mastery signal; deterministic bot profiles prove the spread (newbie 2.0–2.2★ / 71–80% clean vs. skilled 3★ / 98–100% across Day 1/5/9/12 samples; newbie Day 12 no-progression 0★ vs. 3★ maxed) while every sampled run stayed 100% service and net-positive. Speed and precision visibly pay (tips, combos, route payouts), and the worst case is still playable — the right difficulty philosophy for a cozy shop sim.

## Verdict

The first eight days are a genuinely well-paced shop sim with real systems. The depth problem is concentrated and structural: **the game stops introducing anything new exactly when a Steam reviewer's 2-hour refund window closes.** Days 9–14 repeat Days 3–8 verbatim, upgrades end Day 10, collections mature ~Day 12, endless freezes ~Day 28, and New Shop+ changes ~2% of the ledger. All six fixes above are parameter/content work inside existing systems — no new systems required.

*Audit method: campaign strategy sim (3 routes + 25 core checks, all PASS), roadmap Balance watch, design-qa difficulty tables, and direct reads of `daily_events.gd`, `upgrade_catalog.gd`, `legacy_routes.gd`, `endless_contracts.gd`, `menu_catalog.gd`, `recipe_journal.gd`, `research_progress.gd`, `research_briefs.gd`, `market_tests.gd`, `ingredients.json`, `recipes.json`, `dark_recipes.json`.*
