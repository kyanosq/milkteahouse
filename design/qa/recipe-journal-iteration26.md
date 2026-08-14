# Iteration 26 — Recipe Journal and Directed Research

Date: 2026-08-10

## Outcome

The night laboratory now turns the former `3/10 · 1/3` collection counter into a playable planning surface. Players can open the journal from the persistent top collection pill browse all ten legendary recipes and three dark legends and choose one available rumor as tonight's research target.

Discovered entries reveal the exact tea milk topping and sugar formula. Undiscovered entries keep their name and formula hidden while giving one authored directional clue. If any required ingredient has not unlocked yet the clue is replaced by the exact future unlock day and the target action remains disabled.

The selected target persists in save v11. Reproducing or discovering that exact recipe clears the target automatically and adds an explicit completion line to the trial result. The current-trial header also repeats the target so players do not need to reopen the journal after every attempt.

## Interaction and visual design

- The existing top collection pill is now a button. This preserves the crowded bottom action row and makes the former passive count afford its expanded behavior.
- Legendary and dark collections use separate tabs with independent progress counts.
- Active tabs use the primary coral fill; inactive tabs use cream with a mint outline. The first visual pass exposed the inverse state and was corrected before acceptance.
- The target strip is always present to prevent layout movement. Its clear action uses coral text on a pale mint surface after the first capture exposed insufficient contrast.
- Three fixed-width cards fit inside the 1280 × 720 safe frame. Longer collections scroll vertically; formulas and English clues wrap within each card.
- Discovered and rumor states are redundantly communicated by status text border color and content shape rather than color alone.
- `ui_cancel` / game pause closes the journal first. Opening upgrades staff contracts or the journal closes the other night modal so focus cannot become trapped behind an overlay.

## Data and save contract

- `RecipeJournal` is the single runtime service for recipe lookup discovery state unlock-day calculation localized clues formula rendering and research-target lifecycle.
- The thirteen clue strings are localized independently from recipe names and descriptions so English can preserve the intended non-spoiler wordplay.
- `GameState.research_target` stores only a validated recipe ID. Missing and unknown IDs migrate to an empty target.
- `SAVE_VERSION` is now 11. Older saves remain compatible because the new field defaults to empty.

## Automated verification

`recipe_book_check.tscn` verifies:

- 10 regular and 3 dark entries;
- exact unlock days and locked-rumor behavior;
- localized exact formula rendering;
- unavailable valid and invalid target guards;
- non-spoiler target naming;
- 10-card and 3-card panel population;
- live Simplified Chinese / English refresh;
- idempotent completion and target clearing.

`night_check.tscn` additionally performs the real classic-boba trial with that recipe selected and asserts both persisted target clearing and visible completion feedback. `save_migration_check.tscn` covers a valid v11 target plus an invalid-ID corruption fixture.

The complete project regression passed 19/19 with no script or runtime errors. The real player save remained byte-identical before and after the suite:

`c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`

## Visual evidence

All captures are 1280 × 720 and were inspected at original resolution:

- `iteration26-recipe-journal/01-recipe-book-zh.png` — legendary collection and Chinese formulas/clues;
- `iteration26-recipe-journal/02-recipe-book-en.png` — English wrapping and target copy;
- `iteration26-recipe-journal/03-dark-legends-zh.png` — three dark entries and distinct plum collection treatment.

## Remaining tuning gate

The journal closes the mechanical planning gap without changing recipe solutions or attempt economy. Human campaign sessions should now evaluate whether clues are specific enough to create an informed hypothesis while still preserving the pleasure of discovery. Any clue that drives repeated blind retries should be rewritten before adding more recipes.
