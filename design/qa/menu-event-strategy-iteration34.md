# Iteration 34 — Event-Aware Featured Menu Strategy

Date: 2026-08-10

## Rejected state

The three-slot menu was functional but not yet strategic. Every hot recipe used the same order interval and every featured recipe received equal rotation weight. Featured orders also preserved their authored recipe by bypassing random event mutation. In a controlled real-scene replay, the 18-coin Brown Sugar Boba dominated all sampled events simply because its seven fresh sales paid more:

| Day / event | Classic Boba net | Brown Sugar net | First-Love Jasmine net |
|---|---:|---:|---:|
| 9 / Lunch Rush | 302 | **318** | 299 |
| 10 / Light-Drink Trend | 417 | **447** | 410 |
| 11 / Brown-Sugar Trend | 351 | **384** | 345 |

The result contradicted the night panel's promise of a meaningful three-recipe choice: the rational answer was to retain the most expensive recipes rather than read tomorrow's event.

## Accepted rules

The authored recipe remains unchanged; the event acts on demand and payout instead of silently altering a named drink's formula.

| Tomorrow's event | Matching recipe signal | Match reward per real sale |
|---|---|---:|
| Lunch Rush | ≤1 topping and base price ≤13 | +4 |
| Light-Drink Trend | no milk and maximum sugar ≤30 | +6 |
| Brown-Sugar Trend | contains brown-sugar jelly | +2, stacking with the existing +4 trend reward |
| Critic Day | Signature tier | +4 |
| Influencer Day | Hit tier | +4 |
| Group Day | at least two toppings | +4 |

Within the normal featured-order cadence, matching recipes appear twice in the weighted rotation while every selected non-match remains eligible once. No reward is granted at day end or for merely occupying a slot; the player must make and sell the matching cup. Hot/evergreen cadence, stock costs, recipe complexity and the three-slot limit remain intact.

## Player-facing readability

- The menu header names tomorrow's event, matched-slot count and current arrival-speed increase.
- Every recipe card says either `Tomorrow's trend match · +N Coins per sale` or `Normal demand tomorrow` before the formula.
- A live matching order says `Menu price · Trend +N · Heat`, so the extra payout is attributable during pressure rather than hidden in settlement.
- Simplified Chinese and English use the same hierarchy and fit at 1280×720.

Evidence:

- `iteration34-menu-event-strategy/01-menu-forecast-zh.png`
- `iteration34-menu-event-strategy/02-menu-forecast-en.png`
- `iteration34-menu-event-strategy/03-matched-order-zh.png`

## Controlled outcome

The same real day-shop scene, regular-speed bot and 2/2/1/2 mid-game upgrades were replayed after integration:

| Day / event | Best contextual choice | Net | Previous always-premium choice | Net |
|---|---|---:|---|---:|
| 9 / Lunch Rush | Classic Boba | **330** | Brown Sugar Boba | 318 |
| 10 / Light-Drink Trend | First-Love Jasmine | **452** | Brown Sugar Boba | 447 |
| 11 / Brown-Sugar Trend | Brown Sugar Boba | **397** | Classic Boba | 351 |

The margin is deliberately small on Light-Drink Day: choosing the forecast beats the premium default without turning a low-complexity recipe into a permanent new dominant strategy.

The full fourteen-day harness was then upgraded with conservative/simple, balanced/forecast and growth/premium menu policies. All routes proactively rotate rather than pinning their first three discoveries:

| Route | Menu rotations | Gross / operating net | Upgrade finish | Cash | Stars / grade |
|---|---:|---:|---|---:|---|
| Conservative | 8 | 3,516 / 2,629 | 9/10 | 174 | 29/42 · A |
| Balanced | 12 | 5,838 / 4,491 | 10/10 on Day 11 | 1,516 | 42/42 · S |
| Growth | 8 | 7,814 / 6,212 | 10/10 on Day 10 | 3,237 | 42/42 · S |

The Iteration 33 capital separation therefore survives the legitimate new income source.

## Verification boundary

`menu_catalog_check.tscn` covers all six matching rules, weighted first demand, order metadata, light-event payout and stacked brown-sugar payout. `autoplay.tscn` now reports featured sales/revenue/heat and accepts a configurable time scale/stale-menu fixture. `campaign_strategy_sim.tscn` records menu rotations across persistent days. All 24 project regression scenes pass after the final implementation and visual pass, including localization, event, save migration, Mobile render and model budgets. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

Deterministic bots know every formula and cannot measure whether humans consider nightly rotation satisfying or busywork. The next five human campaigns should record forecast comprehension, number of manual menu changes and whether players can explain why their chosen drink sold more.
