# Daily Events and Special-Customer Audit

Date: 2026-08-09  
Viewport: 1280 × 720  
Result: passed for the current vertical slice

## Player-facing contract

Daily events are deterministic and visible before the shift. Each briefing states one challenge, one opportunity, and tomorrow's event. The event name stays in the HUD; affected orders explain their reward; settlement attributes the event income; the night lab previews the next event before upgrades are purchased.

| Day cycle | Event | Gameplay change |
| --- | --- | --- |
| 1–2 | Calm | No modifier; protects onboarding. |
| 3, 9, 15… | Lunch Rush | Arrival interval ×0.72, patience ×1.08. |
| 4, 10, 16… | Light Drinks | Strong pure-tea/low-sugar bias, fewer toppings, +2 coins for no-topping orders. |
| 5, 11, 17… | Brown Sugar Trend | Brown-sugar jelly appears in most orders, +4 coins for affected orders. |
| 6, 12, 18… | Critic Day | First/every fourth customer is a critic: two toppings, patience ×0.78, +8 coins and +1 inspiration. |
| 7, 13, 19… | Influencer Visit | First/every fifth customer requests an unusual topping: patience ×0.90, +5 coins and +3 buzz. |
| 8, 14, 20… | Group Visit | First/every sixth customer holds one queue slot for a two-cup ticket: +10 coins and +2 inspiration on completion. |

## Visual evidence

- `design/qa/iteration9-events/01-brown-sugar-briefing.png` — challenge/opportunity briefing and tomorrow preview.
- `design/qa/iteration9-events/02-critic-active.png` — persistent event chip, purple critic, textual critic title, and reward copy.
- `design/qa/iteration9-events/03-critic-settlement.png` — event income and review count in settlement.
- `design/qa/iteration9-events/04-night-next-event.png` — tomorrow's event shown before the upgrade decision.
- `design/qa/iteration9-events/05-menu-event-summary.png` — saved day and current event shown at entry.
- `design/qa/iteration10-special-customers/01-influencer-briefing.png` through `07-group-settlement.png` — influencer and group briefing, live ticket progression, and settlement attribution.

## Automated evidence

`event_check.tscn` confirms the six-event rotation, 33/40 light-order bias hits, 33/40 brown-sugar trend hits, all three special-customer cadences, forced critic/influencer/group order structures, and exact reward payout. All existing menu, onboarding, upgrade, and night tests still pass.

Difficulty autoplay after events:

| Day / event | Newbie | Skilled |
| --- | --- | --- |
| 3 / Lunch Rush | 100% · 203 · 3★ | 100% · 308 · 3★ |
| 4 / Light Drinks | 100% · 229 · 3★ | 100% · 260 · 3★ |
| 5 / Brown Sugar | 100% · 247 · 3★ | 100% · 442 · 3★ |
| 6 / Critic | 100% · 226 · 2★ | 100% · 490 · 3★ |
| 7 / Influencer | 100% · 206 · 2★ | 100% · 482 · 3★ |
| 8 / Group | 93% · 194 · 1★ | 100% · 604 · 3★ |
| 9 / Lunch Rush, newbie mid upgrades | 100% · 284 · 2★ | — |
| 14 / Group, newbie full upgrades | 100% · 360 · 2★ | — |

The early learning window remains winnable. Critic Day introduces precision pressure; Influencer Day adds high upside; Group Day is the first meaningful queue-pressure spike. The expected upgrade package restores full service rate by Day 14, preserving the growth loop.

## Evidence limits and next test

The deterministic bot always reads orders correctly and cannot measure whether event copy is memorable or whether human players enjoy the repeated cadence. The next playtest should compare event recognition, upgrade choice, and perceived variety across at least five human sessions. Skilled Group Day income is intentionally conspicuous but needs a late-game sink during the 14-day campaign-ending pass.
