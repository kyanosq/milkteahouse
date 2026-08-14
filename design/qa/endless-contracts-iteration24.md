# Iteration 24 — Endless Contract Loop and Save Migration

Date: 2026-08-10  
Scope: post-campaign replayability, endless-economy sink, impossible-goal prevention, save compatibility and visual acceptance

## Outcome

The Day 15+ loop no longer repeats the campaign with an ever-growing balance and an eventually impossible star target. After the first endless day, every night offers three optional commercial contracts for the following shift. The player pays a visible signing fee, accepts a visible pressure modifier, tracks the requirement in the day HUD and receives an attributed settlement result.

Contract success never creates a coin-profit loop: only part of the signing fee is returned. The durable reward is a shop-sign stamp and rank progression, with a small inspiration grant that feeds the existing research loop.

## Contract set

| Contract | Day 16 target | Pressure | Fee / success refund | Net success sink | Durable reward |
| --- | --- | --- | ---: | ---: | --- |
| Golden Streak Stage | best streak ≥ x28 | arrival interval -8%, patience -6% | 120 / 42 | 78 | +1 stamp, +2 inspiration |
| Zero-Complaint Tasting | 0 angry, ≥28 perfect cups | arrival interval -4%, patience -12% | 150 / 51 | 99 | +1 stamp, +2 inspiration |
| District Revenue Sprint | operating revenue ≥497 | arrival interval -18%, patience +4% | 190 / 68 | 122 | +1 stamp, +3 inspiration |

Fees rise by 15 coins every three endless days, capped after six steps. Skill targets rise slowly and remain bounded. Stamps visibly advance the shop-sign ranks at 3, 7 and 12 completions: `街区联名 → 商圈红店 → 城市招牌 → 金杯主理人`.

Failure loses the full signing fee, clears the active contract and resets the contract streak. Success/failure resolution clears the active contract before saving, so repeated settlement calls cannot duplicate refunds or stamps.

## Infinite-target correction

The previous goal formula was `80 + 18 × day` without a ceiling. That meant Day 30 required 620 coins and the requirement continued increasing forever even though service throughput, queue slots and shift duration were bounded.

The shared goal function now preserves the campaign curve and caps at 380 coins from Day 17 onward:

- Day 14: 332
- Day 16: 368
- Day 17+: 380

The ordinary 0–3 star loop therefore remains recoverable. Contracts sit above that baseline as optional mastery targets instead of making the whole endless mode punitive.

## Player-facing integration

- Night lab: a `经营委托` entry appears from the night of Day 15. Three cards expose target, pressure, fee, partial refund, inspiration and failure loss before purchase.
- Tomorrow preview: immediately repeats the signed contract and exact target.
- Day HUD: the contract chip remains width-stable and reports live progress (`连击`, `完美/气走`, or `营收`).
- Event briefing: repeats the active contract alongside the rotating daily event.
- Settlement: attributes the stamp, inspiration and refund or the lost fee; the footer shows current shop-sign rank and stamp count.
- Main menu: Day 15+ save summaries include shop-sign rank and stamps.

Visual evidence:

- `iteration24-endless-contracts/01-contract-selection.png`
- `iteration24-endless-contracts/02-contract-active.png`
- `iteration24-endless-contracts/03-contract-success.png`

All three 1280 × 720 captures were inspected at original resolution. The selection modal fits without clipping, the live contract chip fits before the fixed pause button, and the settlement attribution fits inside the report panel.

## Balance evidence

The first target pass was rejected: with all ten shop-upgrade levels, the slow bot completed all three contracts, so the advertised risk existed only in copy. The final targets were rerun with the same deterministic Day 16 seed and a fully upgraded shop plus the Social King employee.

| Profile | Streak | Precision | Revenue |
| --- | --- | --- | --- |
| Newbie cadence | 25 cups / failed | 25 cups / failed | 446 / 497 / failed |
| Regular cadence | 36 cups / passed | 34 cups / passed | 652 / 497 / passed |

The regular fully-upgraded profile was then sampled on light-drink, critic and group days (Day 16/18/20). All nine contract/event combinations passed with 30–35+ cups and 566–634+ operating revenue. This proves the final targets are reachable across materially different event structures while still separating the slower profile.

The bots always read orders correctly, so the zero-complaint contract's human error pressure remains a playtest question. This result proves mathematical reachability and cadence separation, not human enjoyment.

## Save compatibility

`save_version: 10` is now written explicitly. The new `endless` block stores stamps, completion/failure counts, current/best contract streak, the active signed contract and the last attributed result.

The audit also found a pre-existing night-resume exploit: available inspiration existed only in the scene-local `budget`. Any upgrade, staff or contract purchase could save after the raw inspiration had been zeroed, while exiting and resuming recomputed a different allowance. The v10 save now stores `night_budget` plus its owning day. Entry converts day resources exactly once, each trial synchronizes the remaining value, and leaving for the next day clears it. A 23-point fixture spends to 21, destroys the lab scene and resumes at exactly 21—no loss and no free refresh.

`save_migration_check.tscn` applies fixtures entirely in memory and never redirects or writes the player's save:

- a v5-style save without campaign/endless fields receives valid defaults;
- the former single `sound_volume` migrates to SFX while music retains its safe default;
- a v10 active contract survives normalization;
- negative counters and unknown contract IDs are rejected or clamped.

The real player save SHA-256 remained `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392` after screenshots, simulations and the full regression suite.

## Verification

- `endless_contract_check.tscn`: 3 offers, bounded goals, signing deduction, event modifier composition, success/failure, idempotence and night UI integration passed.
- `save_migration_check.tscn`: legacy/current/corrupt fixtures, active contracts and persisted night budget passed.
- `night_resume_check.tscn`: initial 23 → spent 21 → resumed 21 passed without refreshing consumable resources.
- Existing campaign, night, daily-event, upgrades, staff, onboarding, menu, audio, input, release settings, export, model and Mobile render regressions passed.
- The Day 10 render budget remains 58,780 visible triangles / 191 surfaces with no asset regression.

## Remaining evidence gate

Five human 14-day sessions are still required for campaign pacing, contract comprehension and whether the signing loss feels motivating rather than punitive. Device thermal/performance checks and native Windows runtime smoke also remain release gates; this gameplay iteration does not claim those external checks.
