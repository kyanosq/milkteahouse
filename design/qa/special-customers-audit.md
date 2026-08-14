# Special Customers Audit

Date: 2026-08-09  
Viewport: 1280 × 720  
Result: passed

## Design result

The three special customers now create different decisions instead of sharing a cosmetic skin:

| Archetype | Recognition | Order pressure | Visible payoff |
| --- | --- | --- | --- |
| Critic | Purple actor, `评论家` ticket title | Two toppings, 22% lower patience | +8 coins, +1 inspiration |
| Influencer | Pink actor, `网红` ticket title | Unusual coriander/fish-mint order, 10% lower patience | +5 coins, +3 buzz |
| Group | Mint actor, `团单 · 1/2` ticket title | One queue slot persists through two complete cups | +10 coins, +2 inspiration after cup two |

Color is redundant rather than essential: each state also has a textual title, ticket progress, and reward hint. The group ticket rebuilds its ingredient row after cup one and restores only 48% patience, so the player must read and execute the second cup under continuing pressure.

The influencer reward closes a cross-system loop: accurate daytime service creates buzz that the night lab can convert into traffic and inspiration. The group ticket creates throughput pressure and makes the comfort/shaker/smart-sugar upgrades visibly valuable.

## Visual evidence

- `iteration10-special-customers/01-influencer-briefing.png` — challenge, opportunity, and next-event preview.
- `iteration10-special-customers/02-influencer-order.png` — pink actor, unusual topping, reward hint, and persistent HUD event chip.
- `iteration10-special-customers/03-group-briefing.png` — two-cup rule and full-ticket reward.
- `iteration10-special-customers/04-group-first-cup.png` — `团单 · 1/2` and first recipe.
- `iteration10-special-customers/05-group-second-cup.png` — same ticket advances to `团单 · 2/2` with a visibly different recipe.
- `iteration10-special-customers/06-influencer-settlement.png` — event coins, buzz, and recommendation count are attributed.
- `iteration10-special-customers/07-group-settlement.png` — event coins and completed group tickets are attributed.

All seven captures fit at 1280 × 720 without clipping, card overlap, or ambiguous state.

## Automated evidence

`event_check.tscn` verifies:

- the six-event deterministic rotation;
- critic first/every-fourth, influencer first/every-fifth, and group first/every-sixth cadence;
- forced critic two-topping and influencer unusual-topping composition;
- a real group ticket that remains after cup one, changes to its second recipe, and leaves only after cup two;
- exact +8/+1 critic, +5/+3 buzz influencer, and +10/+2 group payouts.

Difficulty autoplay:

| Scenario | Serve rate | Earnings | Stars | Event result |
| --- | ---: | ---: | ---: | --- |
| Day 7 influencer, newbie, no upgrades | 100% | 206 | 2★ | 3 recommendations, +15 coins, +9 buzz |
| Day 7 influencer, skilled, no upgrades | 100% | 482 | 3★ | 6 recommendations, +30 coins, +18 buzz |
| Day 8 group, newbie, no upgrades | 93% | 194 | 1★ | 2 tickets, +20 coins |
| Day 8 group, skilled, no upgrades | 100% | 604 | 3★ | 5 tickets, +50 coins |
| Day 14 group, newbie, full upgrades | 100% | 360 | 2★ | 3 tickets, +30 coins |

Menu, onboarding, upgrade, night-lab, event, and Godot parse suites pass with clean shutdown. Tests use `GameState.test_mode`; the real save remained at Day 9, 306 coins, and no upgrades.

## Follow-up

The bot never misreads an order, so a human test is still required to validate second-cup recognition and whether 48% restored patience feels tense rather than unfair. Skilled Group Day can exceed 600 coins; the 14-day campaign-ending pass should add a shop-grade target or late-game sink before more income multipliers are introduced.
