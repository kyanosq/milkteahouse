# Iteration 8 — Full Player Journey Audit

Date: 2026-08-09  
Mode: combined UX and screenshot-based accessibility review  
Viewport: 1280 × 720

## Scope and player goal

The reviewed journey is: launch/return → first-day guidance → active serving → pause/settings → day result → night research → shop upgrades. The player goal is to understand where they are, complete a drink quickly, recover from mistakes, see useful progress, and safely return or start over.

## Step evidence

1. **Direct entry — needs work.** `01-direct-entry.png` is visually clean and immediately playable, but the project opens directly into a live timed shift. There is no title screen, continue/new-game choice, save summary, or safe reset path. A returning player gets no reorientation; a player wanting to restart has no supported route.
2. **First-day tutorial — healthy.** `02-first-day-tutorial.png` freezes play, guarantees a visible order, uses a non-color-only mint focus frame, explains mouse and number-key input, and keeps skip/next actions large. Screenshot review cannot prove screen-reader reading order.
3. **Active serving — healthy.** `03-serving.png` has one clear contextual choice, stable order status, a visible day goal, persistent combo state, and large touch targets. The cup-status line and next-action line partially repeat one another, but the redundancy currently helps recovery more than it harms density.
4. **Pause/settings — healthy.** `04-pause.png` visibly separates gameplay from settings, exposes input help, provides a persistent reduced-motion option, and keeps resume as the terminal action. Focus order and assistive-technology labels require runtime testing beyond screenshots.
5. **Day result — usable, needs hierarchy polish.** `05-day-result.png` explains earnings and the route into the next loop, but the result is a dense text block. Stars, earnings, mistakes, and upgrade affordability should become scannable metric rows/cards in a later polish pass.
6. **Night research — needs work.** `06-night-lab.png` exposes all choices, cup, feedback, and primary actions, but the top shelf is over-dense: item labels collide visually with the counter geometry, group cards vary in width, and the action bar reintroduces emoji glyphs. The current selection is communicated mainly through thin coral borders and the cup model, creating a color/vision and recovery risk.
7. **Shop upgrades — healthy.** `07-upgrades.png` clearly states balance, level, effect, next effect, price, and return action. Four cards compare cleanly at 720p and provide the missing coin sink. The night shelf remains faintly visible behind the overlay, but it does not compete with the foreground content.

## Highest-impact changes

1. Add a real title screen with continue, new-game confirmation, settings, save summary, and quit.
2. Rebuild the night ingredient selector into stable, readable groups with an explicit current-recipe summary and consistent keyboard/touch affordances.
3. Convert day settlement from a paragraph into a stronger score/reward hierarchy.

## Evidence limits

Screenshots establish layout, hierarchy, visible labels, contrast risks, and target sizing only. Automated runtime checks are still required for keyboard focus, timer freezing, destructive confirmation, save persistence, and scene transitions. No claim of full WCAG compliance is made.

## Post-audit implementation

All three recommendations were implemented in the same iteration:

- `08-main-menu.png`, `09-new-game-confirm.png`, and `10-menu-settings.png` show the new entry/save/settings flow.
- `11-night-refined.png` and `12-night-selection.png` show the high-contrast ingredient groups and explicit current-recipe summary; `13-night-settings-refined.png` verifies scene-specific settings copy.
- `15-day-result-refined.png` shows the new score hierarchy, while `14-day-pause-refined.png` and `16-return-menu-confirm.png` show safe pause and return behavior.

`menu_check.tscn`, `onboarding_check.tscn`, `night_check.tscn`, `upgrade_check.tscn`, and day-9 deterministic autoplay all pass after the changes. The player's real legacy save remains untouched and continues to load with backward-compatible defaults.
