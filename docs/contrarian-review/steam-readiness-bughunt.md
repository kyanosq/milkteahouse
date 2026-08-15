# Adversarial Bug Review: MilkTeaHouse full-codebase bug hunt

## Scope

Target: `game/` runtime correctness at Steam-release level — arithmetic
boundaries, save round-trips, abnormal-flow state machines, order generation,
research math, recent-change self-review, staff lifecycle, audio/haptics/
display prefs, menu/campaign/one-shot transitions, prep inventory accounting,
UI layout fit. Out of scope: 3D art/modeling assets, recorded product
decisions (progress.md deferred list), external release gates.

## Stop Rule

N = 10 consecutive noise findings (user-specified); stopped after **12
consecutive** (R10: 5, R11: 7) with zero S0-S2 in the final two rounds.

## Rounds and verdicts

| Round | Lens | Findings | Counter after |
| --- | --- | --- | --- |
| R1 | Numeric boundaries (stars/goals/contracts/prep windows) | 5 noise (all hand-computed clean) | 5 |
| R2 | Save round-trip completeness | **2×S2** (settlement name truncation; 16-card cap vs 24 legal) → fixed | 0 |
| R3 | Abnormal flows (pause/locale/focus interleaving) | **2×S1** (paused-delivery focus exploit; settlement focus dead-end) → fixed | 0 |
| R4 | Order generation vs menu/event rules | **1×S1** (custom-drink name collision rewrite → locked-ingredient orders) → fixed | 0 |
| R5 | Night research progression math | 5 noise (mastery/affinity/briefs/market variance/targets all hold) | 5 |
| R6 | Self-review of recent commits | **1×S2** (red-band rear customer promoted without warning) → fixed | 0 |
| R7 | Staff system end-to-end | **1×S2** (wake prompt hardcoded F; staff card missed scheme refresh) → fixed | 0 |
| R8 | Audio/haptics/display/rebind | **1×S2** (rebind onto fixed Q/E bricks an action) → fixed | 0 |
| R9 | Menu/campaign/New Shop+ | **1×S2** (same-frame double-press corrupts inheritance / skips day 15) → fixed; 5 hypotheses noise first | 0 |
| R10 | Prep inventory accounting | 5 noise (FIFO portions, quality composition, day-replay consistency all hold) | 5 |
| R11 | UI layout fit | 7 noise (5 geometry hypotheses disproven; 1 S3 shelf-fit spill; 1 false positive) | **12 → STOP** |

## Findings fixed (all with regression tests, individually committed)

1. **S2** market-settlement names >40 chars truncated on load while the input
   was unbounded; results capped at 16 while 24 cards are legally writable —
   writer-side 40-char cap + 24-card cap; stress fixture.
2. **S1** switching language/input scheme while paused re-stole gamepad focus
   onto hidden order cards; A then delivered the sealed cup with the timer
   frozen (repeatable). Focus helper + order/reset presses now running-gated.
3. **S1** day settlement never grabbed focus after freeing the focused order
   card — gamepad/keyboard dead-end (or hidden-button activation). Continue
   button now takes focus.
4. **S1** shelving a custom drink whose free-text name equals a legend recipe
   silently replaced the player's formula and could inject locked ingredients
   into featured orders. Name fallback exempts custom ids; formula_available
   requires day-unlocked ingredients (locked formulas degrade to random orders).
5. **S2** a rear customer drained to the red band and then promoted to head
   departed with no warning. Promotion now re-issues the band cue.
6. **S2** the slacker wake prompt hardcoded "F" for gamepad/rebound players and
   missed the input-scheme refresh chain. Prompts now use staff_hint().
7. **S2** rebinding onto the fixed prep keys Q/E was accepted and silently
   bricked one of the two colliding actions. Conflict guard + save normalizer
   reject Q/E; assertion added.
8. **S2** same-frame double activation of one-shot transitions (gamepad +
   keyboard) could downgrade an S-grade New Shop+ inheritance to C or skip
   day 15. Three handlers re-entry guarded.

## Noise Log (final rounds, with disproof evidence)

- R10: tea portions strict FIFO with blocked pour on empty; boba is the sole
  pearl-class topping; cup quality snapshotted at pour and immutable after
  seal; day-replay stock reset is consistent with day_open rollback; collect
  window mapping [2/1/0]×4 exact at boundaries.
- R11 geometry: tutorial EN cards grow within screen; overscan modal math
  correct at 1920×720; two-row topping grid fits 8 EN toppings; 3D prop labels
  are mutually exclusive (no overlap); shelf worst case 1342px → 0.918 scale.
- R11 **false positive caught by verification**: "hardcoded Chinese bypasses
  localization" — every literal is a value-as-key CSV entry with an EN
  translation (Godot auto-translates Control.text); 24/24 strings verified
  present as keys. No fix needed; recorded to prevent future mis-fixes.

## Residual Risk

- **S3 (recorded, unfixed by stop rule)**: night shelf `_fit_shelf` budgets
  the raw viewport width rather than the SafeFrame-authored width, so on
  wider-than-16:9 displays (most phones, ultrawide) the late-game shelf stays
  at 1.0 scale and spills ~66px past the safe frame — under the notch band on
  cutout phones. Fix direction: budget against SafeFrame.usable width and
  refit on locale change.
- Same-frame dual-device input on non-one-shot buttons remains theoretically
  possible elsewhere; the three highest-consequence handlers are guarded.
- External release gates unchanged (signing, physical devices, human
  campaigns).

## Recommendation

The codebase has converged: the final two independent lenses (prep inventory
accounting, UI fit) produced zero S0-S2 findings across 12 verified
hypotheses, and every real defect found in nine prior rounds ships with a
regression test. Full 25/25 core suite green after every fix. Fix the
recorded S3 shelf-fit if a mobile-notch pass is scheduled; otherwise the
review loop is complete at N=10 (actual: 12).
