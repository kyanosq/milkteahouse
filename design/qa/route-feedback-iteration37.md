# Iteration 37 — Live Route Feedback

Date: 2026-08-10

## Rejected state

New Shop+ route rules were clear in the campaign confirmation and daily briefing, and successful payouts appeared in the transient serve message and settlement. During the actual 120-second shift, however, the permanent HUD only said `event · route`:

- Turnover did not expose whether the next correct cup was cup 1, 2 or 3 of its payout cycle.
- Reputation mentioned a 70% condition before opening but drew no threshold on the draining patience bar.
- Trend marked event-fit recipes but did not keep a visible total of route matches or route income.

This left a broken feedback loop: players could choose a rule and receive money from it without being able to steer toward the next trigger under pressure.

## Accepted live language

The existing event pill becomes a compact two-line route instrument instead of adding another top-level HUD chip:

| Route | Persistent second line | Actionable order signal |
|---|---|---|
| Turnover | `Sign +N · Cycle 0–2/3` | Uses the live correct-cup streak; a wrong cup or angry departure returns the cycle to 0/3 |
| Reputation | `Sign +N · Fast N` | Every patience bar draws a purple 70% tick; its seconds label includes `· +1` only while eligible |
| Trend | `Sign +N · Match N` | Counts only sold featured cups carrying a real event-match bonus |

The first line remains `event · route`, so the new information does not displace the daily modifier. Route trigger count is shift-local like every other live HUD value and resets at opening. The settlement still reports coin value rather than a redundant trigger count.

The Reputation threshold uses position plus text, not color alone. The purple marker remains visible across the bar, and the `+1` token disappears exactly when the ratio crosses 70%. Its tooltip explains the threshold in Simplified Chinese and English.

## Real-flow evidence

A regular-speed Day 10 agent played the real cup workflow with 2/2/1/2 upgrades and the same three featured recipes:

| Route / routed event | Served | Route triggers | Route coins | Stars |
|---|---:|---:|---:|---:|
| Turnover / Lunch Rush | 24 | 8 | 8 | 3 |
| Reputation / Light-Drink Trend | 27 | 9 | 9 | 3 |
| Trend / Brown-Sugar Trend | 23 | 3 | 9 | 3 |

The numbers prove the HUD unit matches the payout rule: Turnover and Reputation pay one coin per trigger, while Trend pays three. Existing boundary assertions cover 75% eligible versus 65% ineligible Reputation delivery and the every-third-cup Turnover rule.

## Visual QA

- `iteration37-route-feedback/01-rush-live-zh.png` — Turnover shows `+4` and `2/3` without expanding the top bar into Pause.
- `iteration37-route-feedback/02-precision-threshold-zh.png` — the selected order shows `15秒 · +1` and the purple 70% marker.
- `iteration37-route-feedback/03-trend-live-en.png` — English `Sign +6 · Match 2` fits beside the other 720p HUD pills.

All captures use the Day 10 stress layout. The order queue, context controls and bottom cup guidance retain their previous positions.

## Verification boundary

Campaign checks guard all three formatted progress states and payout boundaries. Localization covers the route progress, eligible-seconds label and patience tooltip. The autoplay harness reports both route coins and trigger count from the real scene. The full 24-scene regression passes after visual acceptance, and the real player save remains byte-identical.

The automated agent proves correctness and fit, not glance comprehension. A human replay should verify that the two-line pill can be read peripherally and that the disappearing Reputation `+1` creates urgency without encouraging unsafe target switching.
