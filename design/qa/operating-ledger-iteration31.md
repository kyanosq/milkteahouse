# Iteration 31 — Operating Ledger and Fair Weekly Rent

Date: 2026-08-10

## Outcome

The campaign economy now distinguishes shift performance from spendable profit. Stars and contract revenue still use gross shift revenue, so new costs do not move the mastery target after the player has performed the work. The cash balance settles real cup consumption, staff wage and weekly rent into a visible net-operating result.

## Rules

- Every sealed cup sums the authored `ingredients.json` costs for its tea, milk and toppings, then rounds 50% wholesale pricing upward.
- Correct drinks add stock cost. A delivered wrong drink adds the same cost and exposes it as waste; a perfectionist rescue still consumes the discarded cup.
- Wages settle first, then stock. Weekly rent is due on Days 7, 14, 21… at 40, 60, 80… and caps at 120.
- Rent can use at most 25% of the cash remaining after wage and stock. Any unpaid stock or rent is explicit startup relief; the till never becomes negative and no hidden debt persists.
- The live cash pill shows accumulated stock plus the next rent day, or today's rent ceiling. Closing shows Gross / Stock / Wage / Rent / Net and previews the next base rent.

## Balance evidence

All 14 days were replayed with the same deterministic bot profiles and 5,000 starting coins so both weekly rents were charged in full rather than reduced by the protection rule.

| Profile | Gross 14d | Net operating | Stock | Rent | Net margin | Stars | Day 1 net | Day 7 net | Day 14 net |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Newbie | 2,304 | 1,606 | 598 | 100 | 69.7% | 15/42 | 113 | 92 | 60 |
| Regular | 3,948 | 2,828 | 1,020 | 100 | 71.6% | 33/42 | 115 | 181 | 158 |
| Skilled | 5,925 | 4,410 | 1,415 | 100 | 74.4% | 42/42 | 119 | 303 | 362 |

The novice still clears the 60/70/80-coin comfort, tip or shaker entry options after Day 1. At this iteration the whole tree cost 1,740 coins; Iteration 33 later retained those entry prices and recalibrated the compounding mid/late tiers to 2,930 after a true cross-day strategy replay. Faster profiles keep a slightly better margin because tips and event rewards do not raise ingredient cost.

## Visual QA

The first live pill used a long localized sentence and clipped the rent value in both languages. The accepted version uses a 152 px two-line cash pill and compact 10 px secondary line. Both rent meaning and number remain visible at 1280×720 without displacing the event pill or pause control. The 700×540 closing panel fits the five-column ledger, next-rent note, unlocks and primary CTA in both languages.

- `iteration31-operating-ledger/01-hud-zh.png`
- `iteration31-operating-ledger/02-hud-en.png`
- `iteration31-operating-ledger/03-ledger-zh.png`
- `iteration31-operating-ledger/04-ledger-en.png`

## Verification

`operating_cost_check.tscn` covers wholesale rounding, no-milk cost, weekly escalation/cap, waste, full payment, 25% protection, relief/no-debt, campaign idempotency and bilingual HUD output. Save v16 adds normalized campaign totals for operating cost, rent and relief. All 24 project regression scenes pass after Godot import. The real player save remains unchanged at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
