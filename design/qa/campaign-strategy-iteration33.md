# Iteration 33 — Fourteen-Day Capital Strategy

Date: 2026-08-10

## Outcome

The campaign economy is now verified as one continuous strategy instead of fourteen isolated skill checks. The new deterministic harness instantiates the real day-shop scene, makes real cups, settles stock/waste/wages/rent, then chooses upgrades, one employee and available recipes at night. It preserves the same state through Day 14 and reads the real campaign report.

The first replay rejected the existing balance. Every route completed all ten upgrade levels by Day 10, after which the only possible action was to hold cash. Even the conservative novice route ended with 972 coins and an S grade; balanced and growth ended with 2,682 / 4,160. The tree had been priced against one day of revenue, not the revenue compounding caused by the tree itself.

## Accepted capital curve

| Route | Level 1 | Level 2 | Level 3 | Total |
|---|---:|---:|---:|---:|
| Lounge comfort | 60 | 220 | 520 | 800 |
| Auto shaker | 80 | 260 | 600 | 940 |
| Smart sugar | 360 | — | — | 360 |
| Tip jar | 70 | 240 | 520 | 830 |
| Whole tree |  |  |  | **2,930** |

The 60/70/80 entry choice is unchanged, so a new player can buy a visible improvement after the first shift. Only compounding mid/late tiers moved. The night panel now shows tomorrow's exact fixed reserve as `wage + rent`, plus the amount safe to invest. A risky purchase remains possible and is marked in coral instead of being silently blocked.

## Strategy evidence

Each route starts at zero coins, uses a different deterministic human-speed profile and protects next-day fixed commitments before investing. Hiring becomes possible on Day 8; one unlocked recipe may be researched per night when inspiration allows.

| Route | Profile / intent | Gross | Net operating | Upgrade finish | Final cash | Stars | Grade |
|---|---|---:|---:|---|---:|---:|---|
| Conservative | Newbie, comfort first, Xiaoman | 3,327 | 2,480 | 9/10 | 25 | 28/42 | A |
| Balanced | Regular, mixed plan, Taozi | 5,713 | 4,399 | 10/10 on Day 11 | 1,424 | 42/42 | S |
| Growth | Skilled, income first, Acheng | 7,507 | 5,944 | 10/10 on Day 10 | 2,969 | 42/42 | S |

The conservative route now has four genuine hold nights and finishes one level short without debt, wage shortfall or an unwinnable star spiral. The balanced route reaches completion late enough that order and reserve matter. The growth route still converts execution mastery into earlier completion and an endless-contract runway; that surplus is an earned reward rather than a shared default.

## Visual QA

- `iteration33-campaign-strategy/01-upgrade-reserve-zh.png`
- `iteration33-campaign-strategy/02-upgrade-reserve-en.png`

Both 1280×720 captures retain four complete upgrade cards, readable effects, 50 px purchase targets and the new reserve line without clipping in Simplified Chinese or English.

## Verification boundary

`campaign_strategy_sim.tscn` is a long-running balance harness and accepts `CAMPAIGN_STRATEGY=careful|balanced|growth`. `upgrade_check.tscn` guards the 2,930 total, entry and late-tier prices, and the Day 7 reserve calculation. Localization guards both new strings. All 24 project regression scenes pass without script/runtime errors after the final UI and documentation pass. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

This simulation is deterministic and never misreads an order. It proves state continuity, affordability and relative strategy separation; it cannot prove that humans understand the reserve cue or enjoy waiting for a final tier. Five fresh human campaigns remain the release gate for those questions.
