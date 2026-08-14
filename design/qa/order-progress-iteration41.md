# Iteration 41 — Current-Order Component Verification

Date: 2026-08-10

## Problem

The order card showed the target while the current cup summary lived at the bottom of the screen. Under three-customer pressure and two-topping recipes, players repeatedly scanned between those regions to remember whether each step matched. A wrong cup was often discovered only after sealing and delivery, even though every selected component was already known to the UI.

## Accepted interaction

Only the active order compares itself with the cup:

- unselected target components remain neutral;
- matching components receive a mint border and `✓`;
- mismatching components receive a coral-red border and `!`;
- the header shows compact matched/total progress, changing to `! n/total` on any mismatch and `✓ total/total` only when complete;
- inactive order cards keep their original neutral icon row, so one cup never appears to make progress on three customers at once;
- the choice buttons remain unmarked, preserving the read-and-select challenge rather than revealing the answer.

Base, milk and confirmed sugar compare directly. Each required topping becomes matched only when present; a wrong topping marks the missing target as wrong. Extra toppings are checked independently of target slots, including the zero-topping case, so a cup can never display a false all-clear.

Sugar uses the existing localized short name (`50%`, `None`, `五分糖`) inside cards. Two-topping orders reduce icon and sugar-slot dimensions slightly, keeping the widest English row inside the active card.

## Rejected and optimized states

The first pass drew a subtle panel behind every component on all three cards. It looked orderly but raised the Mobile stress sample to 337 draw calls. Neutral inactive slots now use `StyleBoxEmpty`; only the active order submits state backgrounds. The final sample is 329, preserving 31 calls of guardrail headroom.

## Visual evidence

- `iteration41-order-progress/05-wrong-double-topping-zh-final.png` — Chinese two-topping mismatch: one matched component, four visibly wrong targets and `! 1/5`.
- `iteration41-order-progress/06-match-double-topping-en-final.png` — English two-topping completion: five mint states, `✓ 5/5`, full compact sugar labels and neutral inactive cards.
- `iteration41-order-progress/07-wrong-double-topping-mobile-final.png` — the mismatch state under Forward Mobile.

The state uses shape/symbol and text-count redundancy in addition to color. The active-card coral outline and patience bar remain independent, so route precision feedback is not conflated with recipe correctness.

## Automated evidence

`input_check.tscn` now verifies pending state, a wrong tea base, correction to four matches, exact `✓ 4/4` settlement and the zero-target extra-topping guard. Existing gameplay tests still prove final delivery against the canonical recipe comparison rather than trusting the visual checklist.

The final routed Day 10/max-upgrade/three-customer Mobile stress scene measures 59,324 triangles, 195 surfaces, 329 maximum draw calls and 127.75 MiB against budgets of 120,000 / 200 / 360 / 160 MiB. All 24 guarded check scenes pass. The real player save remains byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.
