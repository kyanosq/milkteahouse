# Iteration 35 — New Shop+ Replay Routes

Date: 2026-08-10

## Outcome

New Shop+ is now a real replay choice instead of a second copy of the same fourteen days. After the campaign report, the player chooses one of three bilingual sign routes. The active route is persisted, previewed before confirmation, named in the event briefing and HUD, attributed in the daily ledger, summarized on the title screen, and recorded permanently when its campaign is cleared.

All routes retain the existing C/B/A/S inheritance of 20/40/60/80 coins and 0/1/2/3 inspiration, skip the forced tutorial, and raise every daily or revenue-contract goal by 8%.

| Route | Real pressure | Attributable reward |
|---|---|---|
| Turnover District | Customer refill interval -12% | Every third correct cup +1 coin |
| Reputation District | Customer patience -12% | Delivery above 70% patience +1 coin |
| Trend District | Each hot featured drink adds 6% traffic instead of 4% | Event-match featured sale +3 coins |

Cleared route IDs are validated, deduplicated and shown as `Sign Legacy x/3`. Completing or reopening the same campaign report cannot award a second clear.

## Rejected first pass

The first implementation paid Turnover +1 on every correct cup and Trend +2 on a matching sale. A fourteen-day replay showed a dominant route:

| Route | Gross / operating net | Final cash | Route bonus | Upgrade finish | Stars / grade |
|---|---:|---:|---:|---|---|
| Turnover | 6,245 / 4,884 | **1,989** | **327** | Day 10 | 42/42 · S |
| Reputation | 5,899 / 4,557 | 1,662 | 151 | Day 10 | 42/42 · S |
| Trend | 5,911 / 4,559 | 1,664 | 56 | Day 10 | 41/42 · S |

The faster queue generated only five more served cups than the other routes, so a 327-coin advantage was not proportionate to its risk. Turnover would have been the obvious answer before considering play style.

## Accepted fourteen-day balance

Turnover was changed to an every-third-correct-cup payout and Trend's match payout rose to +3. The real persistent day scene was then replayed from Day 1 through Day 14 with the same regular-speed balanced policy, S-grade inheritance, upgrades, staff hiring and event-aware menu rotations.

| Route | Gross / operating net | Final cash | Route bonus | Served | Upgrade finish | Stars / grade |
|---|---:|---:|---:|---:|---|---|
| Turnover | 6,026 / 4,668 | 1,773 | 104 | 327 | Day 10 | 42/42 · S |
| Reputation | 5,873 / 4,527 | 1,632 | 150 | 321 | Day 10 | 42/42 · S |
| Trend | 5,941 / 4,588 | 1,693 | 84 | 322 | Day 10 | 41/42 · S |

The largest final-cash gap is 141 coins, or 8.6% relative to the lowest result. No route changes the upgrade finish, campaign grade, wages, rent or shortfall outcome. The payout profiles remain different: Reputation rewards consistent early delivery, Turnover rewards throughput, and Trend rewards nightly forecast preparation.

## Pressure boundary

A deterministic Day 12 newbie replay used the same 2/2/1/2 upgrade package and Classic Boba / Jasmine Coconut / Brown Sugar menu:

| Route | Gross / operating net | Served / angry | Route bonus | Goal / stars |
|---|---:|---:|---:|---:|
| Turnover | 282 / 229 | 15 / 0 | 5 | 320 / 1 |
| Reputation | 265 / 207 | 15 / 1 | 0 | 320 / 1 |
| Trend | 297 / 238 | 16 / 0 | 6 | 320 / 1 |

The common 8% target creates pressure without turning one route into a fail state. Reputation visibly sacrifices a customer when the player cannot serve early enough; Trend only pays when the chosen menu actually matches the critic event.

## Visual QA

- `iteration35-new-shop-routes/01-route-choice-zh.png` — Chinese route selection and final reward wording.
- `iteration35-new-shop-routes/02-route-choice-en.png` — English 1280×720 layout without clipping.
- `iteration35-new-shop-routes/03-route-briefing-zh.png` — route risk/reward appended to the daily briefing.
- `iteration35-new-shop-routes/04-route-hud-zh.png` — active route combined with the live event chip.
- `iteration35-new-shop-routes/05-route-main-menu-zh.png` — active route survives into the title-screen resume summary.

Selected state uses both a checkmark and a coral border, so it does not rely on color alone. The three cards expose pressure and payout before confirmation, and the longer English copy remains within the modal.

## Verification boundary

`campaign_check.tscn` covers all route hooks, the selected New Shop+ reset and idempotent route clearing. `menu_catalog_check.tscn` covers Trend traffic composition; `endless_contract_check.tscn` covers the 8% revenue goal; `save_migration_check.tscn` covers v18 valid/invalid active routes and deduplicated clear records; localization guards every route-facing key. The full 24-scene project regression passes after the final balance and visual pass.

The deterministic agent never hesitates, changes its play style after a mistake, or forms a preference for a district fantasy. Five human second campaigns should record route choice, perceived pressure, nightly menu changes and whether the 3/3 sign legacy is enough motivation to begin a third run.
