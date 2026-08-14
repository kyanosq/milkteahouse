# Iteration 50 — Physical Shake Gesture and Platform Copy

Date: 2026-08-10

## Gap closed

The GDD defined shaking as a physical signature interaction, but the runtime only had a raw per-frame accelerometer delta plus tap/key/controller actions. A single mobile motion could therefore be counted across several rendered frames, while the promised desktop mouse gesture did not exist. Mobile also inherited desktop `Space` copy from the pointer input branch.

## Gesture model

`input/shake_gesture.gd` is a pure discrete detector shared by the day shop and regression harness:

- Mouse motion must exceed 900 px/s, be at least 1.25× more horizontal than vertical, and reverse direction within 460 ms. The first stroke only arms the gesture; a qualifying reversal advances the cup once. An 85 ms cooldown coalesces event bursts.
- The first non-zero mobile accelerometer sample calibrates gravity/orientation. Later samples require a 7.5 m/s² peak-to-peak change and a 150 ms cooldown. Desktop zero vectors never create a gesture.
- The detector resets with every new cup. It is only sampled after tea, milk and sugar are ready, so navigating ingredients cannot create latent shake progress.
- The existing centered button, cup tap, remappable keyboard shortcut and controller X action remain full gameplay paths. Gesture input is an additional expressive route rather than a mandatory dexterity gate.

The gameplay still owns progress decay, upgrade shake-count reductions, cup animation, audio, semantic haptics and final seal. The detector only converts continuous device input into one accepted `_on_shake()` call, keeping every input mode on the same rules.

## Platform-specific communication

- Desktop pointer: `Space or Flick Side to Side`.
- Mobile touch: `Shake Device or Tap`; the button reads `Tap / Shake` and never exposes a desktop key.
- Controller: the existing `X Shake` action remains primary.
- Tutorial step three and pause help explain the gesture plus fallback without removing the rework/delivery rule.

All copy is authored in English and Simplified Chinese through the native translation CSV.

## Automated evidence

`input_check.tscn` now proves:

- slow horizontal and fast vertical cursor motion do not count;
- the first fast horizontal stroke only arms the detector;
- a fast reversal counts exactly once and advances the real gameplay cup;
- reversals inside the cooldown coalesce and a stale stroke only re-arms;
- the first sensor sample calibrates gravity, an impulse counts, and repeated impulses inside 150 ms do not;
- touch-mode helper copy uses the mobile strings, while controller routing is restored for the existing X-button and haptic checks.

`localization_check.tscn` verifies both locales and formatting arity. `onboarding_check.tscn` verifies the four-step tutorial still starts, advances and resumes play. All three targeted scenes completed without engine errors before the full suite.

## Visual acceptance

- `iteration50-shake-gesture/01-shake-step-en.png` — accepted English desktop shake step.
- `iteration50-shake-gesture/02-shake-step-zh.png` — accepted Chinese desktop shake step.
- `iteration50-shake-gesture/03-tutorial-gesture-en.png` — accepted tutorial step three with gesture and fallback copy.
- `iteration50-shake-gesture/04-mobile-copy-en.png` — accepted English Mobile-renderer touch wording.
- `iteration50-shake-gesture/05-mobile-copy-zh.png` — accepted Chinese Mobile-renderer touch wording.
- `iteration50-shake-gesture/06-mobile-stress.png` — accepted Day 10 / max-upgrade / three-customer stress frame.

The desktop and mobile variants remain inside the 1280 × 720 safe frame, preserve the centered action focal point, and do not reduce order-card or work-surface visibility. The tutorial card wraps without clipping its actions.

## Performance and final gate

Godot 4.6.3 Forward Mobile on the Apple M3 Ultra reference renderer measured 58,228 visible triangles, 194 surfaces, 324 maximum draw calls and 128.08 MiB video memory against budgets of 120,000 / 200 / 360 / 160 MiB.

All 24 guarded scenes pass: 23 headless checks plus the real Forward Mobile render. The real player save remained byte-identical at SHA-256 `c1fed78f3dd425680f1227fbd924af26a6b85a0949cb6fba7e6e7c0664546392`.

Target-device feel remains a release gate: one representative Android and iOS device should confirm that 7.5 m/s² / 150 ms feels deliberate across their sensor filtering. The button, keyboard and controller paths ensure this calibration cannot block play in the meantime.
