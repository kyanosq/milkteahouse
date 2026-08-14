# Iteration 53 · Dark Orders and Parallel Prep

Date: 2026-08-13

## Player-facing outcome

This pass closes two of the largest gaps between the previous click-chain and a memorable hands-on shop loop.

- Dark-menu entries are no longer passive counters. Three separate slots hold an exact orderable formula. A real named novelty order appears every five ordinary arrival opportunities; only a completed cup awards buzz. A clean non-overcooked sale awards 2 buzz and any other correct sale awards 1.
- Full-slot discoveries are no longer silently discarded. The new candidate opens the dark board, where all three current formulas, prices and real sales totals remain visible while the player chooses the exact replacement. Drinks can also be unlisted deliberately.
- Tea and pearls are now independent live stations. Tea is stocked per base; pearls have their own portion queue. Tea reaches ready at 8 seconds and pearls at 10 seconds, both with a 4-second golden and 6-second late window before overcooking.
- Golden portions add 2 coins and one inspiration to a clean sale. Overcooked portions remain recoverable but remove 2 coins and Perfect eligibility. This creates a soft mistake instead of a shift-ending deadlock.
- The stations never replace the cup screen: Q/E, controller shoulders or touch can start/collect a batch while another cup step remains active. The first-day tutorial now teaches the concurrent mental model explicitly.

## Persistence and economy

- Save version is 22. Mystery dark entries retain base, milk, toppings, sugar, quality, novelty price and sales; older mystery slots without a recoverable formula stay visible but cannot generate impossible orders.
- End-of-day passive dark-slot buzz was removed. Day stats now record `dark_sales`, `dark_buzz`, `golden_batches` and `poor_batches` from actual play.
- Settled day buzz is snapshotted for the following day. Each point accelerates arrivals by 2%, capped at 12%, and the same amount enters persistent inspiration before the active-night budget cap is applied.

## Automated evidence

- `bash tools/run_godot_checks.sh`: 25/25 core scenes passed.
- `prep_batch_check.tscn`: parallel clocks, exact windows, overcooking, portion inventory, an empty-stock block and the golden sale outcome passed.
- `dark_menu_check.tscn`: exact formula, 3-slot replacement, real dark order, +2 sale buzz, no passive day-end buzz and a 4% next-day traffic snapshot passed.
- Input regression now covers five gameplay actions and Xbox/PlayStation/Nintendo shoulder labels. Onboarding regression requires all five tutorial steps.
- Fixed-clock fourteen-day strategies after the new preparation workload:
  - careful/newbie: A, 30/42 stars, 214 served, 0 angry, 9/10 upgrades, 158 cash;
  - balanced/regular: S, 42/42 stars, 343 served, 0 angry, 10/10 upgrades by Day 10, 2,228 cash;
  - growth/skilled: S, 42/42 stars, 390 served, 0 angry, 10/10 upgrades by Day 10, 4,002 cash.

## Visual evidence

- `design/qa/iteration53-depth/01-batch-parallel.png` shows both stations inside their golden windows while the ordinary order/cup loop remains visible.
- `design/qa/iteration53-depth/02-dark-order.png` exposed a title-width issue during review; the order title was subsequently changed to a compact localized `黑 · 配方名` / `DARK · name` treatment and named-order wrapping.

## Remaining human gates

- Run five full human campaigns and record refill misses, golden/late/overcooked mix, whether Q/E or shoulders become muscle memory, and whether players willingly replace a high-selling dark drink.
- Verify station density and touch accuracy on representative notched iOS/Android hardware. Desktop Metal evidence does not close mobile thermal or reachability gates.
