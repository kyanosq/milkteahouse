# Iteration 30 — Market-Test Payoff and Locked Settlement

Date: 2026-08-10

## Outcome

Closing the lab now produces a staged market-test reveal instead of a paragraph of settlement text. The same pass closes two integrity exploits: rerolling scores by leaving before transition and reopening the lab after a result to continue experimenting.

## Result model

- Each active drink receives one score per operating day for three nights.
- Score remains `quality ± 8`; a stable drink/name/day/stage hash selects the offset.
- Cards show score, stage, progress, running average and trend while testing.
- Third-night averages resolve at the existing thresholds: 88 hit / 78 signature / 62 regular / below 62 low sales.
- Successful drinks retain their full formula and enter the menu at 18/15/12. Low sales never list and refund three inspiration.
- A 300-sample automated distribution reaches -8 and +8 and keeps the mean within one point of zero.

## Save integrity

`MarketTests.advance()` first checks the persisted `market_settlement.day`. A second call returns the stored deep copy without appending scores, registering another menu item or repeating a refund. Close Lab saves immediately. If the process exits from the reveal, the next night-scene construction restores the same panel before interaction. Proceeding to the next day clears the transaction.

Save v15 validates day ownership, result count, names, stage, score, average, trend, outcome, price and refund. Settlement data from a different day or non-night phase is discarded.

## Visual QA

The first implementation used centered anchors inside the full-screen dim layer; its parent did not provide a reliable container rect at child minimum-size resolution, so half the 920 px panel rendered left of the screen. Accepted layout computes position from the actual viewport and updates on resize.

The final 1280 × 720 composition fits two active cards or three final cards without clipping. Outcome remains redundant: rank text, border/score color, numeric average and listing/refund copy all communicate the result. Reduced Motion skips card fades/scales.

- `iteration30-market-settlement/01-testing-zh.png`
- `iteration30-market-settlement/02-testing-en.png`
- `iteration30-market-settlement/03-final-zh.png`
- `iteration30-market-settlement/04-final-en.png`

## Verification

`market_test_check.tscn` covers deterministic distribution, same-input reproduction, same-day idempotency, all three stages, hit registration, formula retention, low-sales refund, bilingual panel population and forced settlement restoration on scene resume. Existing campaign smoke finds the Day 14 CTA through the new panel.

All 23 project regression scenes passed. Godot import/compile passed. The real player save remained unchanged at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
