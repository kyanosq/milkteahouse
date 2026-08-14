# Onboarding, Pause, and Accessibility Audit

Date: 2026-08-09  
Viewport: 1280 × 720  
Result: passed

## First-session flow

The first real Day 1 session now opens a four-step, skippable tutorial while the business timer is frozen. The scene creates the first customer before showing the overlay, so every spotlight refers to visible, actionable game content.

1. Read the highlighted order card and learn how to switch orders.
2. Follow the contextual recipe panel and its stable `1–9` keyboard labels.
3. Shake, seal, and deliver from the cup station; Space is called out as the fast shake input.
4. Connect daily performance to coins, shop upgrades, inspiration, and night research.

Completion is saved once for a new player. Replay is available from the pause menu and does not rewrite first-session state.

## Pause and settings

- Escape pauses the day shop, including countdown and customer patience, then restores the prior running state on resume.
- The day panel exposes input guidance, sound volume, reduced motion, tutorial replay, and resume.
- The night lab uses the same settings implementation in a shorter card and hides the irrelevant replay action.
- Old saves without `tutorial_completed` or `settings` migrate to safe defaults (`false`, 75% volume, full motion).

## Reduced-motion contract

The preference removes purely decorative motion: HUD coin flights and punches, cup wobble and serve squash, prop bounce, customer idle loops, and animated ingress/egress. Timing, scoring, order validation, upgrades, and recipe outcomes are unchanged.

## Evidence

- `assets_src/renders/game_tutorial1.png`
- `assets_src/renders/game_tutorial2.png`
- `assets_src/renders/game_tutorial3.png`
- `assets_src/renders/game_tutorial4.png`
- `assets_src/renders/game_pause.png`
- `assets_src/renders/game_night_settings.png`

Automated `onboarding_check.tscn` verifies tutorial progression, keyboard selection, pause-time freeze, volume state, reduced motion, and clean resume. The upgrade, night-lab, and deterministic autoplay suites also pass after the change. Test mode prevents all suites and screenshot captures from mutating the player's actual save.
