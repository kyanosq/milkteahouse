# Iteration 36 — Route-Specific Event Calendars

Date: 2026-08-10

## Rejected state

Iteration 35 made New Shop+ routes change arrivals, patience, featured traffic and per-cup rewards, but all four campaigns still consumed exactly the same event sequence: Lunch → Light → Brown Sugar → Critic → Influencer → Group, repeated from Day 9. Menu forecasting therefore asked for the same nightly answers in every replay. The route was mechanically different but the fourteen-day preparation rhythm remained a duplicate seed.

## Accepted calendar rule

Days 1–2 remain calm and Days 3–8 retain the original sequence. This is an unlock-safety requirement: Brown Sugar first appears when its topping exists, while Critic, Influencer and Group orders arrive only after their supporting ingredient and tutorial steps.

From Day 9 onward, the active sign supplies a deterministic six-event permutation:

| Day | Turnover | Reputation | Trend |
|---:|---|---|---|
| 9 | Group Visit | Critic Day | Camera Visit |
| 10 | Lunch Rush | Light-Drink Trend | Brown-Sugar Trend |
| 11 | Camera Visit | Group Visit | Light-Drink Trend |
| 12 | Critic Day | Brown-Sugar Trend | Lunch Rush |
| 13 | Light-Drink Trend | Camera Visit | Critic Day |
| 14 | Brown-Sugar Trend | Lunch Rush | Group Visit |

Every route contains each event exactly once per six-day block. Route identity comes from sequence and preparation cadence, not from receiving more high-payout days. Endless days continue the same deterministic route calendar.

## Player-facing forecast

The route confirmation now adds a second-week opening cue beneath the selected risk/reward summary. The full schedule is not dumped up front; the existing night preview and menu board continue to expose the exact next event one day ahead, preserving the intended prepare-tonight/operate-tomorrow loop.

Visual evidence:

- `iteration36-route-calendars/01-route-calendar-zh.png`
- `iteration36-route-calendars/02-route-calendar-en.png`
- `iteration36-route-calendars/03-rush-day9-preview-zh.png`

Chinese and English confirmation copy fits at 1280×720. The Day 8 Turnover capture correctly forecasts Group Visit on Day 9, proving the visible preview reads the routed schedule rather than the old global rotation.

## Persistent fourteen-day evidence

The real day scene was replayed through all fourteen days with the same balanced regular-speed policy, S-grade 80-coin / 3-inspiration inheritance, upgrades, staff and event-aware featured-menu decisions.

| Route | Gross / operating net | Final cash | Route bonus | Menu rotations | Served | Upgrade finish | Stars / grade |
|---|---:|---:|---:|---:|---:|---|---|
| Turnover | 6,033 / 4,648 | 1,753 | 105 | 10 | 328 | Day 10 | 42/42 · S |
| Reputation | 5,962 / 4,627 | 1,732 | 159 | 10 | 323 | Day 10 | 41/42 · S |
| Trend | 5,903 / 4,551 | 1,656 | 78 | 11 | 321 | Day 10 | 41/42 · S |

The new calendars change real preparation behavior—the former common schedule caused 12 rotations on every route—without breaking progression. All routes retain the same upgrade finish and S grade, no employee wage shortfall occurs, and the largest final-cash gap falls to 97 coins / 5.9%.

## Verification boundary

`event_check.tscn` guards the unchanged first calendar, all three exact Day 9–14 permutations and once-per-cycle coverage. Localization checks the three bilingual opening cues. Campaign, menu and night tests ensure routed events still flow into day setup, event-fit recipes and tomorrow's preview. The full 24-scene suite passes after the implementation and visual check, and the real player save remains byte-identical.

Deterministic balance proves schedule integrity and affordability, not whether people remember or emotionally associate the sequences with each district. Human second/third campaigns should record forecast comprehension, manual menu changes, surprise at Day 9 and whether the route feels distinct before reading its payout.
