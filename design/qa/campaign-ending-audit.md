# Fourteen-Day Campaign Ending Audit

Date: 2026-08-09  
Viewport: 1280 × 720  
Result: passed for the implemented campaign-ending flow

## Player journey

```text
Day 14 service → night research/market settlement → first-shop report
                                                     ├─ continue into Day 15 endless play
                                                     ├─ confirmed New Shop+ with legacy bonus
                                                     └─ return to title and safely resume report
```

Day 14 night copy explicitly announces the end of the authored campaign and changes the primary action to `查看首店评级`. The report is a persisted `campaign` phase, so quitting at this decision never skips the ending or restarts Day 14.

## Scoring contract

The score is capped at 100 and remains explainable on one screen:

| Dimension | Maximum | Inputs |
| --- | ---: | --- |
| Craft & operations | 35 | Perfect cups and 10 shop-upgrade levels |
| Research creativity | 30 | Five discoveries and three launched menu items |
| Business momentum | 20 | Up to 900 retained coins and 36 cumulative earned buzz |
| Journey | 15 | Average day stars and tracked-day coverage |

Grades are C below 55, B from 55, A from 70, and S from 85. Live buzz is consumed when entering the night lab, so the report intentionally grades the cumulative `buzz_earned` ledger instead of the usually-zero live balance.

Every settled Day 1–14 is recorded once. Re-running a settlement cannot duplicate revenue or stars in the campaign ledger. A migrated old save begins tracked-day coverage on its current day; missing history is not fabricated and does not unfairly lower the coverage component.

## Replay contract

- `继续经营` keeps recipes, coins, upgrades, and discoveries and enters Day 15.
- `带着店招开新店 +` requires a confirmation and preserves lifetime completed-campaign count plus best grade/score.
- New Shop+ grants C/B/A/S bonuses of 20/40/60/80 coins and 0/1/2/3 inspiration, then starts Day 1 with the forced tutorial skipped. Tutorial replay remains available from pause.
- Returning to the title keeps phase `campaign`; Continue reads `查看评级 · 第 14 天` and routes back to the report.

## Visual evidence

- `iteration11-campaign/01-campaign-report.png` — A-grade report, score breakdown, career highlights, three routes, and personalized next-run challenge.
- `iteration11-campaign/02-new-shop-confirm.png` — destructive reset scope, exact inheritance, cancel, and confirmation.
- `iteration11-campaign/03-day14-night-gate.png` — authored Day 14 transition after market settlement.
- `iteration11-campaign/04-campaign-resume.png` — title-screen campaign state and safe report resume.

All four captures are 1280 × 720 with no clipping, overlap, or hidden primary action. The report uses the existing editable 3D shop as its backdrop and the established coral/mint/cream visual language.

## Automated evidence

`campaign_check.tscn` verifies:

- C, A, and S scoring profiles, including the exact 100-point S profile;
- old-save tracked-day migration;
- Day 14 night gate copy;
- idempotent daily recording and idempotent campaign completion;
- persisted campaign phase and lifetime best result;
- Day 15 endless continuation;
- S-grade New Shop+ inheritance of 80 coins and 3 inspiration;
- confirmation open/close state and report labels.

The existing menu, onboarding, upgrade, night, event, and autoplay suites remain part of the release regression.

## Evidence limits

The automated bot can prove state transitions and arithmetic, but it cannot prove that the 14-day cadence feels the right length or that players understand all four scoring dimensions. The next research gate is five complete human sessions. The first employee/trait loop is now implemented; the main presentation gap is a coherent original audio identity, while later staff traits remain coupled to second-shop systems.
