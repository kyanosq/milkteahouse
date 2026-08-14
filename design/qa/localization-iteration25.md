# Iteration 25 — Bilingual Release Copy and Layout

Date: 2026-08-10

## Outcome

The complete playable loop now supports persistent Simplified Chinese and English from the title settings. The language switch covers the title screen, pause/display settings, tutorial, day service, order cards, 3D ingredient labels, settlement, night research, recipe discovery and market tests, shop upgrades, staff hiring/traits, endless contracts and the fourteen-day campaign report.

Godot's native CSV translation importer produces the two runtime translation resources. `GameLocale` owns the safe locale switch and dynamic formatting while `GameState.settings.locale` preserves the player's choice without resetting progression.

## Visual corrections found during English QA

- Day 10's eight unlocked toppings initially pushed the one-row context bar beyond the right edge. It is now a fixed-width two-row grid with compact localized ingredient names and full tooltips.
- The same Day 10 scene exposed untranslated Chinese `Label3D` prop names. World labels now use localized short names and refresh live after a language change.
- Full English ingredient names collided across the night shelf. Shelf captions now use compact names while the selected-recipe summary and tooltips retain full names.
- Long contract targets and refund copy widened the three-card endless panel beyond 1280 px. Contract cards now wrap the name target pressure and reward blocks inside a stable three-column layout.
- The event HUD uses dedicated short names so `Light-Drink Trend` and other modifiers no longer destabilize the top bar.
- The expanded day context panel changed tutorial geometry. Step 2 now highlights the complete 800 px interaction surface.

## Coverage

- 2 locales: `zh_CN` and `en`.
- 20 ingredients/sugar states with full and compact names.
- 10 regular recipes and 3 dark recipes with names and descriptions.
- 3 staff candidates with introductions plus all implemented trait names/effects.
- 4 upgrade paths and 10 visible levels.
- 7 daily-event states including the calm tutorial state.
- 3 endless contracts and 4 shop-sign ranks.
- C/B/A/S campaign titles verdicts dimensions highlights actions and New Shop+ confirmation.

## Automated verification

`localization_check.tscn` now verifies:

- both language directions and unsupported-locale fallback;
- native static-Control translation instead of only translated data values;
- formatted-copy keys;
- full and compact ingredient coverage;
- every recipe description and staff introduction;
- upgrade event and contract data localization;
- required release-screen keys.

Font coverage now includes critical Latin release copy. Export configuration tests require both generated translation resources and the source CSV. The complete project regression passed 18/18 with no `SCRIPT ERROR` or runtime `ERROR` output.

The real player save remained byte-identical after import screenshots and tests:

`c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`

## Visual evidence

All captures are 1280 × 720 and were inspected at original resolution:

- `iteration25-localization/01-main-menu-en.png`
- `iteration25-localization/02-night-lab-en.png`
- `iteration25-localization/03-upgrades-en.png`
- `iteration25-localization/04-staff-recruit-en.png`
- `iteration25-localization/05-contracts-en.png`
- `iteration25-localization/06-campaign-en.png`
- `iteration25-localization/07-day-shop-en.png`
- `iteration25-localization/08-day-result-en.png`
- `iteration25-localization/09-settings-en.png`
- `iteration25-localization/10-event-briefing-en.png`
- `iteration25-localization/11-tutorial-en.png`
- `iteration25-localization/12-night-recipe-en.png`
- `iteration25-localization/13-campaign-confirm-en.png`
- `iteration25-localization/14-day-shop-zh.png`
- `iteration25-localization/15-night-lab-zh.png`

## Remaining release gates

This iteration completes project-side bilingual support. Native Windows/iOS runtime smoke Android toolchain/device performance and five human fourteen-day sessions remain external release gates. Store-page copy achievements and cloud-save integration are still separate Steam publishing work.
