# Design QA — Day Shop Option 3

- Source visual truth: `design/mockups/coral_mint/01-day-shop.png`
- Implementation screenshot: `assets_src/renders/game_day_demo.png`
- Combined comparison: `design/qa/day-shop-steam-final-comparison.png`
- Viewport / CSS size: 1280 × 720 landscape
- Source pixels: 1672 × 941, normalized to 1280 × 720 for comparison
- Implementation pixels: 1280 × 720 at 1× density
- State: Day 1, one active order, tea and milk selected, topping selection open

## Full-view comparison evidence

The implementation preserves the selected coral-mint concept's interaction hierarchy: a fixed order queue on the left, an immersive 3D counter as the primary surface, a centered preparation cup, a contextual ingredient chooser, and one persistent next-step prompt. The shop, customer, cup, and gameplay props are editable Blender sources exported as native GLBs; no mockup raster is used as scene geometry.

## Focused region evidence

- Order queue: the active card has a non-color-only orange outline, ingredient icons, a numeric countdown, and a patience bar.
- Context chooser: only the current step is exposed; buttons use project ingredient images and readable labels.
- Preparation area: the cup is centered and enlarged under a higher, warmer camera with real-time liquid state.
- Bottom actions: reset remains secondary; the next required action is persistent and centered.

## Required fidelity surfaces

- Fonts and typography: the project continues to use LXGW WenKai. Hierarchy is clear at 13–20 px; no visible clipping in the 1280 × 720 capture.
- Spacing and layout rhythm: the left queue, center work area, contextual chooser, and bottom prompt form distinct regions without covering persistent controls.
- Colors and visual tokens: cream, warm wood, coral active state, mint healthy progress, mango reward icons, and red warning state match the selected coral-mint direction.
- Image quality and asset fidelity: existing GLB characters, shop, cup, and PNG ingredient icons are reused at native quality. No mockup raster is used as in-game chrome.
- Copy and content: order, countdown, ingredient step, cup contents, reset, and next action are visible in Chinese.

## Comparison history

### Iteration 1

- Earlier P1: the preparation cup was too small and the counter read as a distant background.
- Earlier P2: flat lighting weakened station separation; prop labels were visually crowded.
- Fixes: moved the camera closer and higher, enlarged and repositioned the cup, enabled directional shadows, warmed and lowered ambient lighting, reduced label size, and widened prop spacing.
- Post-fix evidence: `assets_src/renders/game_day_demo.png` and `design/qa/day_shop_option3_comparison.png`.

### Iteration 2 (self-playtest pass)

- P1 gameplay: autoplay showed no pressure curve — a newbie-profile bot kept 100% serve rate and 100% perfect through day 5, and newbie vs skilled earnings were nearly identical (164 vs 172). Fixed by steepening patience decay (32→16s floor), faster spawn intervals (4s floor), a 4th topping tier from day 6, head-of-queue-only full patience drain (waiting customers drain at 0.5×), and tiered tips (+3 fast / +1 ok / 0 slow).
- P1 night lab: the sugar shelf group was clipped at the right screen edge on later days (8 toppings unlocked). Fixed with `_fit_shelf`, which scales the shelf row down whenever its width exceeds the viewport.
- P2 day shop: the queued customer model was half-cropped at the screen edge; sugar-pump labels overlapped; late-game topping bins collided with the sugar pump row. Fixed by moving queue slots inward and shrinking customers to 1.25×, widening pump spacing with smaller staggered labels, and compressing the 8-bin topping row clear of the pumps.
- Post-fix evidence: `assets_src/renders/game_day.png`, `game_day_demo.png`, `game_day10.png` (three-order density check), `game_night.png`.

### Iteration 3 (Steam-quality visual & playability pass)

- Rendering: desktop now runs Forward+ (mobile keeps Mobile renderer) with MSAA 2x, ACES tonemapping plus saturation/contrast grading, SSAO, restrained glow, soft directional shadows, and a mint fill light.
- Scene remodel (Blender `Scene` in shop_scene.blend, baked-tint CC0 textures): honey fine-grained wood on all counters and the new front prep tier, light-grey cartago tile floor, queue railing with coral posts and mint caps, soft-mint wainscot with cream cap and wall frames, emissive hanging bulbs, relocated chalkboard and pickup sign. Tint adjustments are baked into texture pixels because Blender shader node color math does not survive glTF export.
- Composition: the front prep tier is shortened to the right so the customer queue (scaled to 0.88×, diagonal along the railing) stays fully visible even with three orders; the work cup keeps its center spot with visible mat.
- Playability: perfect serves now build a combo streak (every 3rd serve pays +3 coins +1 inspiration; a wrong drink or an angry walk-out resets it) and each day has a coin goal (70 + 25×day) settled as a 0–3 star rating, with +3 inspiration at three stars; the HUD shows goal progress and the live streak.
- Evidence: `assets_src/renders/game_day.png`, `game_day_demo.png`, `game_day10.png`, `game_night.png`, `shop_scene_blender.png` (Blender render acceptance).

### Iteration 4 (final polish closure)

- P3 HUD: replaced the remaining top-row emoji glyphs with five coherent, transparent, low-poly runtime icons for day/time, coins, inspiration, perfect serves, and combo streak. Each icon was independently generated on a chroma-key background, converted to alpha, downsampled to 128 × 128, imported by Godot, and displayed in a 28 × 28 HUD slot. Alpha and small-size legibility were inspected before integration.
- P3 density: moved the late-game milk group left, shortened sugar labels (`3分/5分/7分`), lowered and reduced pump labels, and kept contextual controls as the authoritative readable sugar selector. `game_day10.png` confirms that milk and sugar text no longer collide.
- P3 character motion: customer actors now use separate walk, breathing, look-around, and hop pivots so their tweens do not fight. Correctly served customers walk toward the pickup area and exit right; angry/end-of-day customers leave along the entrance path.
- Visual correction: the earlier Forward+ capture still clipped too much highlight detail. Reduced key/fill/ambient energy, neutralized the white balance, lowered post-process brightness, raised contrast, reduced glow, and retained ACES/SSAO. Counter texture, cup, labels, coral buttons, and mint surfaces now remain distinguishable.
- Post-fix evidence: `assets_src/renders/game_day_hud.png`, `game_day_demo.png`, `game_day10.png`, and `design/qa/day-shop-steam-final-comparison.png`.

### Iteration 5 (Blender MCP asset rebuild)

- Rebuilt the customer, layered gameplay cup, kettles, milk cartons, topping bins, sugar pumps, shaker, preparation mat, pickup tray, and service bell as a coherent coral/mint/cream matte-PBR library. Tintable meshes retain the runtime names expected by Godot (`Body`, `Arm_*`, `Hair`, `Tint*`, `Liquid*`, and `Pearl_*`).
- Rebalanced the gameplay composition around the larger, more detailed assets: cup scale reduced to 2.20×, camera raised and widened, prop dressing normalized, and the three late-game customers placed in horizontally staggered slots clear of both the order cards and bottom controls.
- Reworked the shop floor in Blender by baking a low-contrast warm-grey tile texture (`assets_src/textures/floor_coral_mint.png`) into the GLB. Runtime shadow opacity, ambient fill, and SSAO were reduced so floor shadows retain depth without becoming the focal point.
- World-space labels now appear only for the currently requested ingredient category; the streak chip remains in the HUD at `x0`, and the day goal uses a stable micro progress bar.
- Fixed an actual night-lab ownership leak: the persistent naming row is hidden while unused instead of being detached from the tree. Test audio players are synchronously stopped and released before headless shutdown.
- Post-fix evidence: `assets_src/renders/game_day1.png`, `assets_src/renders/game_day10.png`, `assets_src/renders/game_night.png`, `assets_src/renders/props_hd_overview.png`, and `assets_src/renders/customer_cup_hd.png`.

### Iteration 6 (economy and progression loop)

- Added a persistent 10-level shop progression system with four meaningful coin sinks: waiting-area comfort (+18% patience per level), automatic shaker (5→2 actions), smart sugar matching (removes one choice and error point), and tip jar (+1 coin per level and completed order).
- Added a fully keyboard-focusable night upgrade store with current balance, level progress, plain-language effect previews, exact costs, insufficient-funds states, save persistence, and Escape-to-close behavior. Day HUD now keeps the shop level visible.
- Rebuilt day settlement into a centered 620 px card with wrapped, scannable results and a direct prompt explaining that coins can be spent on upgrades in the research room.
- Rebalanced daily goals from `70 + 25×day` to `80 + 18×day`. This preserves a day-1 three-star onboarding win while keeping late-game one/two-star recovery reachable through upgrades.
- Tests now set `GameState.test_mode`, so screenshots, smoke tests, and autoplay never overwrite the real player save. Audio is muted in test mode and all current headless suites exit without resource warnings.
- Full flow audit: `design/qa/growth-loop-audit.md`. Evidence: `game_day_hud.png`, `game_day_end.png`, `game_night.png`, and `game_upgrades.png`.

### Iteration 7 (onboarding, pause, input, and accessibility)

- Added a four-step first-day tutorial that pauses the business clock and spotlights the live order card, contextual recipe controls, shake/delivery station, and progression HUD. A customer is guaranteed before the overlay opens, so the first focus target is never empty. The tutorial can be skipped and replayed from the day-shop pause menu.
- Added stable keyboard operation: number keys `1–9` select the visible contextual action, `1–3` deliver a sealed cup to an order slot, Space shakes, and Escape opens/closes pause or settings. Context numbers now rebuild from `1` after every recipe step instead of inheriting queued-for-deletion controls.
- Added pause/settings surfaces to both the day shop and night lab. The day version includes input guidance and tutorial replay; the compact night version omits the irrelevant tutorial control. Pausing freezes customer patience and the business timer.
- Added persistent sound volume and reduced-motion preferences with backward-compatible defaults for older saves. Reduced motion removes coin flights, camera/control punches, cup wobble/squash, customer bob/look/hop, and animated arrivals/departures without changing game outcomes.
- Fixed a responsive-layout defect discovered during 720p screenshot review: wrapped tutorial labels briefly reported an oversized minimum and left later cards clipped below the viewport. Cards now refit after container sorting and remain at the authored 500 × 272 layout.
- Full flow audit: `design/qa/onboarding-flow-audit.md`. Evidence: `game_tutorial1.png` through `game_tutorial4.png`, `game_pause.png`, and `game_night_settings.png`.

### Iteration 8 (complete entry/resume journey and night-lab clarity)

- Added a production-style title screen over the real 3D shop scene. It exposes save summary, phase-aware Continue, confirmed New Game, settings, and Quit instead of dropping the player into a live timer on launch.
- Save data now records `phase` (`day` or `night`). Continue returns to the correct half of the loop, while old saves migrate to `day`. New Game resets progression but preserves sound and reduced-motion preferences.
- Added a safe Return to Main Menu path from both day and night settings. The day flow explains that the unsettled shift will restart and reloads the last saved state, preventing retry-based coin duplication; the night flow preserves already-saved research and upgrades.
- Reworked the night ingredient shelf with opaque high-contrast group cards, readable cocoa labels, selected-state tooltips, and a persistent text summary of the complete current recipe. Persistent UI and result copy no longer depend on platform emoji glyphs.
- Rebuilt day settlement into a goal progress row plus three icon-backed metric cards for revenue, perfect serves, and best combo. Rewards, unlocks, available balance, and the research-room CTA now form separate scan lines instead of one paragraph.
- Fixed the shared settings overlay so its scrim actually fills the viewport, and gave replay/menu actions secondary styling so Continue remains the unambiguous primary action.
- Audit and before/after evidence: `design/qa/iteration8-audit/audit.md`, including `01-direct-entry.png` through `16-return-menu-confirm.png`.

### Iteration 9 (daily events and the first special customer)

- Added a deterministic four-day event rotation from Day 3 onward: Lunch Rush, Light Drinks, Brown Sugar Trend, and Critic Day. Days 1–2 remain calm onboarding days. Events are known before opening and repeat predictably, so challenge is learnable rather than hidden randomness.
- Each event changes decisions: Lunch Rush shortens arrival intervals by 28%; Light Drinks biases milk/sugar/topping structure and rewards no-topping orders; Brown Sugar Trend places brown-sugar jelly in most orders and pays a visible trend bonus; Critic Day inserts a purple special customer every fourth spawn with two toppings, 22% lower patience, and a high coin/inspiration reward.
- Added a full-screen pre-shift briefing with separate challenge/opportunity cards, tomorrow preview, keyboard focus, and a single open-shop CTA. The current event remains visible in a bordered HUD chip.
- Order cards now explain event rewards directly. Critics also use a textual `评论家` title and distinct character color, so the special state is not communicated by color alone.
- Settlement now attributes event income and critic reviews separately. The night lab previews tomorrow's event before the player opens the upgrade store, turning equipment purchases into informed preparation. The main-menu save summary also names the current event.
- Event definitions and order/reward rules live in `DailyEvents`; event selection is derived from day number and requires no save migration.
- Full audit: `design/qa/daily-events-audit.md`. Evidence: `design/qa/iteration9-events/01-brown-sugar-briefing.png` through `05-menu-event-summary.png`.

### Iteration 10 (complete special-customer set)

- Expanded the deterministic event cycle from four to six modes with Influencer Visit and Group Visit. Existing briefing, HUD, main-menu, night-preview, order-hint, and settlement surfaces inherit the new events without save migration.
- Added a pink influencer archetype that deliberately requests unlocked unusual toppings such as coriander or fish mint. A correct cup pays +5 coins and +3 buzz, connecting a visible daytime risk to the night research/traffic economy.
- Added a mint group archetype backed by a real two-cup ticket rather than a doubled reward. After cup one, the customer stays in the queue, the card advances from `团单 · 1/2` to `团单 · 2/2`, the recipe row is rebuilt, and 48% patience is restored for the second cup. Completing the ticket pays +10 coins and +2 inspiration.
- Special-customer identity is redundant across character tint, textual ticket title, progress state, and reward copy. Dynamic special cards remain stable at 1280 × 720 and do not depend on color recognition alone.
- Settlement attributes influencer coins/buzz/recommendations and group coins/completed tickets independently. `event_check.tscn` covers all three cadences, generated order structures, two-stage group delivery, and exact rewards.
- Full audit: `design/qa/special-customers-audit.md`. Evidence: `design/qa/iteration10-special-customers/01-influencer-briefing.png` through `07-group-settlement.png`.

### Iteration 11 (fourteen-day campaign payoff)

- Replaced the silent Day 14→15 rollover with an authored campaign ending. Night settlement now announces campaign completion and routes to a dedicated first-shop report; `campaign` is a persisted resume phase rather than a transient overlay.
- Added an explainable 100-point C/B/A/S rating across craft/operations, research creativity, business momentum, and journey performance. The report exposes every dimension, career highlights, lifetime best, and a personalized next-run challenge based on the weakest ratio.
- Added an idempotent Day 1–14 campaign ledger for revenue, service, stars, event rewards, cumulative buzz, special orders, and best streak. Old saves begin journey tracking on their migration day instead of receiving invented history or an unavoidable coverage penalty.
- Added two distinct postgame loops: endless continuation enters Day 15 with all progress, while confirmed New Shop+ preserves lifetime best grade/score and grants grade-based starting coins/inspiration. Returning to the title safely resumes the report.
- Full audit: `design/qa/campaign-ending-audit.md`. Evidence: `design/qa/iteration11-campaign/01-campaign-report.png` through `04-campaign-resume.png`.

### Iteration 12 (first employee slot and Blender barista)

- Added a Day 8 night-lab recruitment surface with three candidates, readable speed/care/charm stats, exact hire/wage costs, clue-bearing introductions, and traits that remain hidden until their first real daytime trigger.
- Implemented three non-linear common traits: Xiaoman reduces rear-queue patience drain but idles until clicked/F-woken; Taozi adds 20% patience while accelerating arrivals by 12%; Acheng grants +2 coins and one daily wrong-cup rescue while adding one shake to every cup.
- Added daily wages, two-step paid dismissal, trait revelation, staff status, settlement attribution, title-screen resume copy, campaign staff ledger fields, keyboard/touch interaction, and reduced-motion-safe actor states.
- Built a distinct editable barista through Blender MCP using the shared character language plus apron, visor, badge, headset, towel, legs, and shoes. Targeted optimization reduced the first 7,596-triangle pass to approximately 3,210 triangles and 170 KiB without losing the small-screen silhouette.
- Full audit: `design/qa/staff-system-audit.md`. Evidence: `design/qa/iteration12-staff/01-recruit-candidates.png` through `06-staff-resume.png`, plus `assets_src/renders/staff_barista_preview.png`.

### Iteration 13 (Blender MCP environment and customer identity pass)

- Reworked the day-shop shell into a premium coral/mint bar: framed counter fascia, brass fasteners, layered edge trim, a milk-tea emblem, pendant shades, filled glass ingredient jars, wood lids, labels, menu geometry and refined shelf dressing.
- Added three editable customer silhouettes alongside the classic model: round bob/flower/collar, knit cap/cross-body satchel, and twin buns/hoodie. Runtime selection rotates deterministically through all four models while preserving shared clothing and hair tint behavior.
- Performed a second optimization pass after the first models exceeded the GDD budget. Same-material parts were consolidated and secondary curves decimated to 3,490 / 3,438 / 3,474 triangles and 12 / 13 / 10 mesh objects, all within the 2k–3.5k character target.
- Added `model_asset_check.tscn` to guard shop nodes, all four model loads, runtime file budgets and the `0→1→2→3` rotation contract.
- Full audit: `design/qa/blender-model-iteration13.md`. Evidence: `assets_src/renders/shop_scene_iteration13_full.png`, the three customer previews, and `design/qa/iteration13-blender/03-day10-final.png`.

### Iteration 14 (dedicated Blender night laboratory)

- Replaced the darkened daytime-shop reuse with a purpose-built indigo/walnut research room: physical experiment desk, coral/cream work mat, mint placement ring, articulated lamp, candle, plant, papers, research shelf, filled jars, books, flasks and test tubes.
- Added a dedicated Godot backdrop with a Blender-matched camera, cool room light, restrained warm practicals and a shadow-free readability fill. The existing CupView now lands on the modeled mat without changing any recipe input or hit target.
- Kept 147 source objects independently editable while batching equal-material pieces only during export. The runtime GLB is 26 mesh objects, 24,332 triangles and 1.4 MiB.
- Extended the asset test to require five semantic night-lab nodes, ≤30 meshes and a 2 MiB file budget.
- Full audit: `design/qa/night-lab-blender-iteration14.md`. Evidence: `assets_src/renders/night_lab_scene_blender.png` and `design/qa/iteration14-night-lab/03-night-lab-final.png` / `04-night-lab-recipe.png`.

### Iteration 15 (original audio identity)

- Added four deterministic original themes for the menu, day shop, night laboratory and campaign report. Two persistent music decks crossfade over 0.8 seconds, so the day/night loop no longer hard-cuts or restarts the same track.
- Expanded the feedback library to 19 purpose-built cues. Tea, milk, topping, sugar, shake, seal, serve, combo, customer, staff, lab and UI actions now have distinct sonic roles instead of reusing shake/coin for unrelated actions.
- Added programmatic Music/SFX buses, independent saved volume controls, old-save migration, important-outcome ducking, per-cue cooldowns and a 12-voice concurrency ceiling. Audio remains the information fallback when reduced motion removes camera and object punch effects.
- Reworked all three settings variants to expose background music and operation SFX separately. Menu, day and night captures fit at 1280 × 720 without clipping.
- Added `audio_check.tscn` plus scene-routing assertions. The suite verifies 19 SFX, 4 music tracks, exact bus values, two-deck crossfade, burst limiting, automatic cleanup and warning-free Ogg shutdown.
- Full audit: `design/qa/audio-identity-iteration15.md`. Evidence: `design/qa/iteration15-audio/01-menu-audio-settings.png` through `03-night-audio-settings.png`.

### Iteration 16 (gamepad and expanded-aspect release pass)

- Added an input-device router and gameplay actions for Menu/Start pause, X shake and Y staff interaction while preserving A for universal UI confirmation and B for back. Keyboard/mouse and gamepad prompts switch immediately from actual input.
- Added a consistent 4 px mint focus ring, automatic per-step ingredient focus, D-pad row navigation, focus-driven order selection and a dedicated night-lab focus entry point. Tutorial, menu and settings surfaces now explain the active control scheme.
- Added a centered 1280 × 720 SafeFrame to menu, day, night and campaign UI while keeping 3D backgrounds full-bleed. 16:10 receives 40 logical pixels of vertical centering; 1920 × 720 receives 320 px horizontal centering.
- Fixed a visual defect discovered during ultrawide QA: modal scrims initially ended at the safe-frame edge. Pause, tutorial, event, settlement, upgrade, staff and confirmation overlays now dim the entire viewport while their content remains centered.
- Added `input_check.tscn` to verify mappings, glyph switching, focus styling/navigation, controller shake, focus-driven order selection and exact expanded-aspect offsets.
- Full audit: `design/qa/input-resolution-iteration16.md`. Evidence: `design/qa/iteration16-input/01-menu-gamepad-16x10.png` through `07-upgrades-ultrawide.png`.

### Iteration 17 (desktop display and remapping settings)

- Added a shared `显示与按键` subpage reachable from title/day/night settings with windowed, borderless and fullscreen modes plus five 16:9/16:10 window resolutions. Windowed sizes center on the active monitor; fullscreen and borderless correctly disable the irrelevant resolution selector.
- Added persistent keyboard remapping for pause/settings, shake and staff interaction. Capture supports cancellation, rejects modifier-only keys, prevents duplicate conflicts with named feedback and restores Esc/Space/F defaults in one action.
- Extended save migration and progression reset preservation to display and input preferences. Corrupt modes/resolutions/key maps fall back to complete safe defaults.
- Kept gamepad actions fixed to A/B/X/Y/Menu and routed dynamic keyboard names back into day instructions and the tutorial, so remapped controls never leave stale help copy.
- Fixed a first-open layout defect found in screenshot QA: the advanced PanelContainer expanded from 540 to 1323 px after becoming visible. A deferred post-sort refit now guarantees 640 × 540 and keeps both bottom actions on-screen.
- Added `release_settings_check.tscn` for mode/resolution state, actual InputMap remap, duplicate guard, cancellation, default reset, geometry and preference preservation.
- Full audit: `design/qa/release-settings-iteration17.md`. Evidence: `design/qa/iteration17-settings/01-menu-settings-entry.png` through `05-night-settings-entry.png`.

### Iteration 18 (Blender MCP special-customer identity)

- Replaced the event-only recolors for critics, influencers and group tickets with three gameplay-specific Blender models. The critic carries a notebook under a wine beret, the influencer raises a mint phone beside a high pink ponytail, and the group ticket is represented by two actual friends sharing one queue actor.
- Kept all editable parts separate in the `.blend` sources, then batched same-material meshes only for GLB export. The three assets remain within the 2,000–3,500 triangle role budget at 3,336 / 3,404 / 3,436 triangles, use 10 / 10 / 9 runtime meshes, and each stays below 111 KiB.
- Bound model selection directly to `customer.kind`. Special spawns no longer advance the deterministic four-model regular rotation; regular clothing remains tintable, while special hair preserves authored colors.
- Added asset checks for all three semantic bindings, mesh/file ceilings and rotation isolation. Single-spawn and three-slot pressure captures verify readable silhouettes, intact order cards and no customer overlap at 1280 × 720.
- Full audit: `design/qa/blender-special-customers-iteration18.md`. Evidence: `design/qa/iteration18-special-models/01-critic-ingame.png` through `05-group-dense-queue.png`, plus the three Blender previews in `assets_src/renders/`.

### Iteration 19 (Blender MCP trait-readable staff roster)

- Replaced the single shared barista for the three first-shop hires with behavior-specific models: sleepy soft-cap Xiaoman with a mug, headset/high-ponytail Taozi, and glasses/clipboard Acheng. The existing generic barista remains only as an unknown-ID compatibility fallback.
- Kept the common apron/body contract while using headwear, face geometry and hand props to explain each trait in the 3D scene. Visual QA caught Taozi's first ponytail placement hiding behind the visor; it was moved to the camera-side silhouette without adding geometry.
- Converted source mouth/headset curves only in the export copy, joined equal-material pieces, and reopened each editable source after export. Final assets use 3,024 / 3,290 / 3,088 triangles, 9 runtime meshes each and 144–156 KiB.
- `ShopStage.add_staff` now selects by persisted staff ID and records the chosen model. Asset/staff tests verify all three imports and bindings; 1280 × 720 captures verify that the staff card name matches the visible character and that key props survive the sugar-pump foreground.
- Full audit: `design/qa/blender-staff-identity-iteration19.md`. Evidence: `design/qa/iteration19-staff-models/01-xiaoman-idle.png` through `03-acheng-working.png`, plus the three Blender previews in `assets_src/renders/`.

### Iteration 20 (runtime font and package budget)

- Replaced the 25,575,676-byte full multilingual runtime font with a deterministic 505,004-byte subset while retaining the untouched OFL source under `assets_src/fonts/`. This removes 98.0% of the font payload without changing the accepted LXGW WenKai typography.
- Pinned the builder to FontTools 4.63.0, stored the exact collected glyph input, reopened the result to verify the cmap and preserved system fallback for player-entered recipe names. Eleven symbols absent from the source font remain explicit fallbacks rather than silent subsetting failures.
- Added `font_asset_check.tscn` for import, 45 critical interface characters, fallback and a 256 KiB–1 MiB size budget. Menu, Day 10 and night-lab screenshots show no clipping or fallback regression.
- Evidence: `design/qa/iteration20-font-package/01-menu-subset-font.png` through `03-night-subset-font.png`; pipeline notes and exact hash live in `assets_src/fonts/README.md`.

### Iteration 21 (Blender MCP visible shop progression)

- Added physical models for all four first-shop upgrades: a three-stage comfort set, three-stage automatic shaker, smart sugar console and three-stage tip jar. The shop now changes visibly after coin investment instead of communicating progression only through HUD numbers.
- Rejected the first 5,112–6,304-triangle pass, then reduced hidden round-segment and bevel density to 1,712–1,816 triangles per asset. Editable parts remain separate; GLB export batches by level tier plus material for 8–13 runtime meshes per asset.
- Bound visibility to saved upgrade levels through `Base_` / `L2_` / `L3_` node prefixes and metadata. Level 0 retains the manual shaker; higher levels add their authored modules on the next day.
- Screenshot QA found that the first smart-sugar placement left five obsolete manual pumps and that the tip jar was hidden by the side counter. The final layout removes those misleading pumps and moves the jar into a clear rear-counter slot.
- Full audit: `design/qa/blender-upgrade-visuals-iteration21.md`. Evidence: `assets_src/renders/upgrade_kit_preview.png` and `design/qa/iteration21-upgrade-models/01-day10-max-upgrades.png` through `03-day10-batched-final.png`.

### Iteration 22 (four-platform package and export readiness)

- Added reproducible macOS, Windows Desktop, Android and iOS release presets with compiled scripts, shared resource exclusions and platform identities. A new `export_config_check.tscn` locks all four presets, mobile texture support, Android arm64, iOS team/icon fields and the shop import strategy.
- Switched the embedded shop images from extracted dependencies to Basis Universal inside the imported scene. The first exclusion attempt correctly failed exported-app smoke due to missing textures; only the reimported, dependency-free scene was accepted. The final Day 10 render retained the authored wood, tile, jars and upgrade materials.
- Generated one opaque 1024 px milk-tea app icon from the accepted gameplay style, resized it deterministically to 14 additional exact iOS sizes and excluded those derivative size sources from ordinary PCK resources while preserving both the project master and platform-generated icons.
- Final artifacts (refreshed after Iteration 23): macOS universal ZIP 73,380,459 B with clean exported startup/shutdown; Windows x86-64 single EXE 114,784,560 B with package structure verified; signed arm64 development IPA 37,737,456 B with strict code-sign, bundle/version, provisioning and icon checks passed.
- Android is blocked only by this Mac's absent JDK/Android SDK (`platform-tools`, `adb`, `build-tools`, `apksigner`). All 24 installed iOS simulators were shutdown, so the debugger workflow did not boot one without user action; runtime mobile performance remains a hardware gate.
- Full audit: `design/qa/package-export-iteration22.md`. Visual evidence: `design/qa/iteration22-package-export/01-day10-basisu-shop.png` and `game/assets/icons/app/icon_1024.png`.

### Iteration 23 (Blender MCP mobile render performance)

- Added a real Day 10 stress harness with all ten upgrade levels and three customers. The first Mobile measurement exposed 155,236 visible triangles, 346 mesh surfaces and 730 draw calls—well above the GDD triangle ceiling and too costly for a mobile target.
- Rebuilt the classic Blender customer from 40,980 Godot triangles / 20 meshes / 917,912 B to 3,228 / 8 / 114,972 B while preserving the hair/clothing tint contract, glasses and expression. Twenty-five source parts remain independently editable.
- Rebuilt and material-batched all eight operation props. The repeated Day 10 prop subtree fell from 68,988 triangles / 111 surfaces to 17,916 / 71; every individual device now stays at ≤2,128 triangles and ≤8 runtime meshes.
- Added a non-destructive shop export script that batches the 135 editable objects into 32 material/semantic runtime meshes without changing its 17,748 triangles or embedded textures. Four QA semantic node names remain exact, and three unrelated historical Blender scenes no longer enter the GLB.
- Forward Mobile now skips unsupported SSAO and only removes directional-shadow submission from small props/upgrades. The shop shell, customers and cup retain shadows; Forward+ keeps full SSAO/glow/prop shadows.
- Final Mobile reference result: 58,780 visible triangles, 191 surfaces, 316 draw calls and 120.23 MiB video memory—reductions of 62.1%, 44.8% and 56.7% for triangles, surfaces and draw calls respectively. Static and rendered budgets are enforced by `mobile_render_check.tscn`.
- Full audit: `design/qa/mobile-render-performance-iteration23.md`. Evidence: `design/qa/iteration23-mobile-performance/01-before-mobile-day10.png` through `04-final-forwardplus-day10.png`, plus `assets_src/renders/customer_classic_mobile_preview.png`.

### Iteration 24 (endless contracts and save v10)

- Closed the post-Day-14 economy gap with three optional paid contracts: streak, zero-complaint precision and revenue sprint. Each exposes its fee, pressure modifier, exact requirement, partial refund, inspiration and failure loss before signing; tomorrow preview, day HUD, briefing, settlement and main-menu resume all preserve the same target.
- Contract success grants a persistent shop-sign stamp/rank but still removes 78–122 coins; failure removes the full 120–190+ signing fee. Resolution is idempotent and cannot duplicate refunds or stamps after resume.
- Capped the ordinary endless star goal at 380 from Day 17. The former unbounded formula would have required 620 coins on Day 30 and kept rising despite fixed shift duration/queue throughput.
- Rejected an easy first balance pass after the fully-upgraded newbie bot cleared every contract. Final Day 16 results separate cadence cleanly: newbie 25 cups / 446 revenue fails all three; regular 34–37 cups / 601–652 revenue clears them. Regular profiles also cleared all nine sampled contract combinations across light-drink, critic and group days.
- Added explicit save v10 plus pure-memory v5/current/corrupt migration fixtures. The same audit fixed a pre-existing night-budget resume exploit: 23 available inspiration spent to 21 now resumes at exactly 21 instead of being lost or recomputed. Full regression passed and the real save SHA-256 remained unchanged.
- Full audit: `design/qa/endless-contracts-iteration24.md`. Evidence: `design/qa/iteration24-endless-contracts/01-contract-selection.png` through `03-contract-success.png`.

### Iteration 25 (bilingual release copy and layout)

- Added persistent Simplified Chinese / English selection through Godot-native translation resources. Static controls auto-translate while one formatting service covers dynamic day/night copy and data-table names.
- Migrated the full loop: title/settings/tutorial, day HUD/orders/service/settlement, night recipes/market tests, upgrades, staff traits, endless contracts and campaign/New Shop+ reporting. Ingredient props in the 3D shop now switch language with the 2D interface.
- English screenshot QA found and fixed three layout defects that Chinese copy had hidden: eight toppings overflowing the day context bar, night shelf captions colliding and long contract reward lines widening the panel. The accepted layouts use a two-row topping grid, compact localized shelf/HUD names and wrapped fixed-width contract cards.
- Added required-key/data-table/fallback/static-Control assertions, English font coverage and export translation-resource checks. All 18 regression scenes passed; the real player save hash remained unchanged.
- Full audit: `design/qa/localization-iteration25.md`. Evidence: `design/qa/iteration25-localization/01-main-menu-en.png` through `15-night-lab-zh.png`.

### Iteration 26 (recipe journal and directed research)

- Replaced the passive night `3/10 · 1/3` counter with a complete 10-legendary / 3-dark recipe journal opened from the same stable top HUD pill.
- Discovered recipes now expose exact localized formulas. Unknown recipes keep names and ingredients hidden behind authored bilingual clues; locked ingredients show the exact future day and prevent premature target selection.
- Added one persistent research target that is repeated above the current trial and automatically clears with explicit feedback when the real recipe hit path succeeds. Save v11 validates the stored recipe ID and safely clears missing or corrupt values.
- Original-resolution visual QA corrected inverted tab-state color and low-contrast clear-target copy. Accepted 1280 × 720 layouts cover Chinese legendary/dark tabs and the longer English formulas and clues.
- Added `recipe_book_check.tscn` and extended night/save/localization coverage. All 19 regression scenes passed and the real player save SHA-256 remained unchanged.
- Full audit: `design/qa/recipe-journal-iteration26.md`. Evidence: `design/qa/iteration26-recipe-journal/01-recipe-book-zh.png` through `03-dark-legends-zh.png`.

### Iteration 27 (featured menu operating loop)

- Closed the largest remaining day/night disconnect: approved recipes no longer create invisible passive settlement income. Up to three selected recipes now become named daytime customer orders and use their researched menu price.
- Added normalized formula tier price heat and lifetime-sales records for legendary and player-named recipes. Fresh features add a two-coin launch premium and 4% arrival pressure each; evergreen recipes remain orderable at a slower cadence.
- Added a bilingual night menu board with three-slot/full/minimum guards exact formulas launch heat sales history and clear tomorrow-impact copy. Long English order names use a wider two-line daytime card.
- Save v12 reconstructs legacy legendary formulas and preserves unrecoverable legacy custom drinks for collection credit without creating impossible orders. Market-test candidates now retain their full formula through all three nights.
- Deterministic A/B runs show +15–38 coins from three fresh features without rescuing the unupgraded Day 12 newbie or granting the Day 12 regular a free third star. All 20 regression scenes passed and the real save hash remained unchanged.
- Full audit: `design/qa/featured-menu-iteration27.md`. Evidence: `design/qa/iteration27-featured-menu/01-menu-board-zh.png` through `05-featured-settlement-zh.png`.

### Iteration 28 (research growth and affinity notebook)

- Turned hidden ingredient XP into a visible 14-card mastery collection. Every card exposes Lv1–5 progress, current 0–8 XP and the real Lv3+ main-flavor bonus already used by recipe scoring.
- Added a 3×4 tea/milk affinity matrix to the existing recipe journal. A valid night trial reveals each cell once; static data rules produce Perfect/Good/Neutral/Clash plus a signed affinity score without adding a second balance table.
- Completing all 12 pairings permanently grants +2 inspiration at the start of each new night. Revealing the final cell immediately refunds two inspiration so the completion moment is felt in the same session.
- Save v13 validates and deduplicates discovered pair keys. Accepted Chinese/English 1280 × 720 layouts keep the complete matrix and first mastery row visible together; the full 21-scene regression passed and the real save SHA-256 remained unchanged.
- Full audit: `design/qa/research-growth-iteration28.md`. Evidence: `design/qa/iteration28-research-growth/01-research-notebook-zh.png` and `02-research-notebook-en.png`.

### Iteration 29 (persistent lab briefs)

- Added one contextual short-term lab brief that turns the long affinity/mastery collections into an immediately executable experiment. Odd days prefer an unlocked unseen tea/milk pair; even days prefer two uses of the most-practiced under-Lv3 ingredient; a 75+ quality challenge takes over after both collections mature.
- Incomplete progress persists across nights. Completion immediately refunds the two-inspiration trial cost, records its completion day and refuses to issue or reward a second brief that day.
- A fixed left-side task card exposes objective, progress and exact reward without covering the cup, flavor radar or tomorrow preview. Completion switches from gold to mint and the trial feedback carries the same result.
- Screenshot QA also found two unrelated night defects: invisible cream-on-cream journal/menu buttons and unbounded feedback text overlapping Close Lab. Explicit dark button copy plus a fixed auto-scrolling feedback viewport resolved both.
- Save v14 validates brief type, ingredient/pair IDs, progress, reward and completion day. All 22 regression scenes passed and the real player save SHA-256 remained unchanged.
- Full audit: `design/qa/research-briefs-iteration29.md`. Evidence: `design/qa/iteration29-research-briefs/01-active-zh.png` through `03-complete-zh.png`.

### Iteration 30 (market-test payoff and locked settlement)

- Replaced the dense sleep text block with a bilingual two-column market-test panel. Each drink now exposes score, night 1/3–3/3, progress bar, running average, trend and a text-plus-color outcome; final cards show tier, menu price/listing or the three-inspiration failure refund.
- Preserved the authored ±8 variation while deriving it deterministically from drink, quality, day and stage. A 300-sample guard reaches both -8/+8 endpoints with a centered mean.
- Made close-lab settlement a persisted idempotent transaction. Repeated calls return the original result, final registration/refunds cannot duplicate, and reopening a saved night restores the locked panel instead of rerolling or allowing more trials.
- Original-resolution QA caught an off-screen anchor assumption in the first build. The accepted panel centers from the actual viewport and follows viewport resize; two active cards and three final cards fit at 1280 × 720 in both languages.
- Save v15 validates up to 16 settlement result cards and clears stale/non-night data. All 23 regression scenes passed and the real player save SHA-256 remained unchanged.
- Full audit: `design/qa/market-settlement-iteration30.md`. Evidence: `design/qa/iteration30-market-settlement/01-testing-zh.png` through `04-final-en.png`.

Current deterministic progression reference (Iteration 27; “max” means all ten shop levels plus three fresh featured recipes):

| Day / profile | No progression | Max first-shop progression |
| --- | --- | --- |
| 5 / Newbie | 100% · 221 · 2★ | 100% · 418 · 3★ |
| 9 / Newbie | 100% · 166 · 0★ | 100% · 363 · 3★ |
| 9 / Regular | 100% · 262 · 2★ | 100% · 593 · 3★ |
| 12 / Newbie | 67% · 125 · 0★ | 100% · 385 · 2★ |
| 12 / Regular | 100% · 311 · 2★ | 100% · 623 · 3★ |
| 12 / Skilled | 100% · 525 · 3★ | 100% · 760 · 3★ |

## Findings

No P0/P1/P2 defect currently blocks the implemented vertical slice: launch, resume, day serving, settlement, night research, three-slot featured-menu planning, real researched-recipe orders, upgrades, save migration, safe return, six daily events, three special-customer types, the first employee slot, the 14-day campaign ending, post-campaign contracts, bilingual Chinese/English copy, scene audio, keyboard/touch/gamepad input, expanded-aspect layout and desktop release settings are all usable. Desktop packages and a signed iOS development IPA now exist, and the project-side Mobile render budget passes. The next P1 is five human 14-day sessions for campaign pacing/listening fatigue, menu-rotation behavior and contract-loss feel plus Android/iOS hardware frame-time/thermal profiling; Android export still requires the external SDK toolchain.

## Follow-up roadmap

See `design/qa/steam-quality-roadmap.md`. Daily modifiers, special customers, staff, campaign ending, Blender environments/upgrades, audio identity, gamepad input, expanded-aspect composition, desktop settings and project-side four-platform export configuration are complete. The next milestone combines human campaign validation with Android/iOS device performance evidence.

## Verification

- Godot startup / script validation: passed.
- Night recipe-lab smoke test (T1 discover / T2 dark recipe / T3 sleep settle): passed with clean shutdown and no resource/RID warnings.
- Blender MCP runtime asset pass: 10 replacement GLBs imported successfully; no missing material, parser, or scene errors.
- Day 10 density acceptance: three complete customer silhouettes, no queue overlap, stable HUD width, and no prop-label collisions.
- Shop-upgrade regression: purchase price, balance deduction, maximum level, patience multiplier, shake count, smart sugar, and tip bonus all passed.
- Onboarding/settings regression: four-step completion, gameplay resume, numeric recipe selection, true pause-time freeze, 35% volume persistence, reduced-motion state, and resume behavior all passed.
- Main-menu regression: phase-aware continue copy, destructive confirmation, settings return, new-game reset, and settings preservation all passed.
- Night-lab visual acceptance: high-contrast shelf groups, color-independent recipe summary, selected state, refined settings copy, and emoji-free persistent controls all passed at 1280 × 720.
- Settlement visual acceptance: goal bar, three metric cards, reward/unlock lines, balance guidance, and primary research CTA all fit without clipping at 1280 × 720.
- Daily-event regression: six-event rotation, low-sugar/pure-tea bias, brown-sugar order bias, all three special-customer cadences, dynamic group ticket progression, exact coin/inspiration/buzz rewards, HUD copy, settlement attribution, and next-day preview all passed.
- Real save isolation: post-test save remained at day 9 / 306 coins / no purchased upgrades; automation no longer mutates player progress.
- Special-customer autoplay: Day 7 influencer newbie 100% / 206 / 2★; Day 8 group newbie 93% / 194 / 1★; Day 8 group skilled 100% / 604 / 3★; Day 14 group newbie with full upgrades 100% / 360 / 2★.
- Campaign-ending regression: C/A/S grade profiles, exact 100-point S case, Day 14 gate copy, old-save tracking migration, idempotent ledger/completion, campaign resume phase, Day 15 continuation, and grade-based New Shop+ inheritance all passed.
- Endless-contract regression: three Day 16+ offers, signing deduction, bounded target/cost scaling, daily-event modifier composition, live HUD/preview/UI, success/failure attribution, partial refund, stamp/rank progression, idempotent resolution and the Day 17+ 380-coin star-goal cap passed. Save v13 fixtures cover legacy missing fields, split-audio defaults, active contracts, exact night-budget resume, validated research targets, featured-menu reconstruction, affinity-key validation and corrupt state without touching the real save.
- Recipe-journal regression: 10 legendary + 3 dark entries, exact unlock days, formula localization, non-spoiler rumors, invalid/locked target guards, tab population, bilingual refresh and real-trial target completion all passed. Chinese legendary/dark and English layouts fit the 1280 × 720 safe frame.
- Featured-menu regression: legacy formula recovery, three-slot and minimum-one guards, hot/evergreen cadence, researched pricing, actual daytime sale attribution, zero passive settlement income, idempotent heat decay, custom formula preservation and bilingual panel refresh all passed. Day 9/12 A/B automation verifies a +15–38 coin effect without erasing late-game growth pressure.
- Research-growth regression: 12 deterministic pair ratings, first-use discovery, duplicate/invalid guards, all-pairs completion, +2 new-night budget, +2 same-night completion refund, Lv1/Lv3/Lv5 mastery states, 12 visible matrix cells, bilingual refresh and v13 migration all passed.
- Research-brief regression: deterministic unlocked-pair selection, two-use mastery practice, 75-quality fallback, cross-night progress, same-day issuance/reward lock, exact +2 refund, bilingual copy and v14 corrupt-field migration all passed. Night visual QA additionally covers visible top navigation and bounded latest-first feedback.
- Market-test regression: centered ±8 deterministic distribution, same-day idempotency, three-stage thresholds, menu registration/formula retention, failure refund, save-resume settlement lock, bilingual card population and v15 migration all passed.
- Employee regression: Day 8 unlock, three candidate hooks, hire/dismiss economics, trait revelation, Slacker wake interaction, Perfectionist error rescue, wages, staff resume, exact employee-ID/model binding, GLB import, and Day 8/14 bot balance all passed. Staff assets: 3,024–3,290 triangles, 9 meshes and 144–156 KiB each.
- Blender model regression: revised shop nodes 4/4, operation props 8/8, regular customers 4/4, special customers 3/3, staff models 3/3, upgrade models 4/4, deterministic regular rotation, event/staff/upgrade binding, tint and level naming contracts, mesh/triangle/GLB budgets, Day 10/special queue density renders, staff interaction, onboarding, and skilled Day 10 autoplay all passed. Revised shop: 32 meshes / 17,748 triangles; regular customer roles: 3,228–3,518 triangles; operation props: 312–2,128 triangles; visible upgrades: 1,712–1,816 triangles and 8–13 runtime meshes each.
- Night-lab Blender regression: five semantic nodes, 26 runtime meshes, 24,332 triangles, 1.4 MiB, selected-recipe density capture, legendary/dark/sleep recipe logic and campaign transition all passed.
- Audio regression: 19/19 SFX, 4/4 scene themes, two dynamic buses, 40%/65% test mix accuracy, 0.8-second two-deck crossfade, 12-voice burst ceiling, finished-player cleanup, scene routing and warning-free shutdown all passed.
- Audio settings visual acceptance: menu/day/night variants expose independent music and SFX values, preserve reduced-motion access, retain one primary action and fit without clipping at 1280 × 720.
- Input regression: three gameplay mappings, A/B/X/Y/Menu prompt switching, keyboard restoration, 4 px focus ring, D-pad ingredient navigation, controller shake, order-card focus selection and menu/day/night/campaign focus entry all passed.
- Expanded-aspect acceptance: exact 320 px 21:9 and 40 px 16:10 logical safe offsets, full-bleed 3D backgrounds, full-viewport modal dimming and unclipped menu/day/night/campaign/upgrade compositions all passed.
- Release-settings regression: three display modes, five safe resolutions, test-mode side-effect isolation, Space→R InputMap remap, duplicate conflict guard, Escape cancellation, default restoration, 640 × 540 layout lock and reset preservation all passed.
- Font/package regression: 505,004-byte runtime subset, 45 critical glyphs, system fallback and the 1 MiB ceiling passed; full source remains untouched outside the runtime tree.
- Export-config regression: four compiled-script presets, shared exclusions, Android arm64 identity, 15 exact iOS icon assets, ETC2/ASTC support and Basis Universal shop-image embedding passed.
- Localization regression: two-way locale switching, persistence/fallback, static Control translation, formatted keys, full/compact ingredient names, all recipe/staff/upgrade/event/contract data, critical Latin glyphs and both exported translation resources passed. Fifteen bilingual 1280 × 720 captures verify title, settings, tutorial, day/night, growth, staff, contracts and campaign layouts without mixed-language text or clipping.
- Package smoke: macOS universal exported startup/shutdown passed cleanly; Windows x86-64 package structure passed; iOS arm64 archive/export, strict signing, bundle/version/provisioning and platform icons passed. Android is environment-blocked pending JDK/SDK installation.
- Mobile-render regression: Day 10 max-pressure scene passed ≤120k visible triangles, ≤200 mesh surfaces, one shadow light, ≤360 measured Mobile draw calls and ≤160 MiB reference video memory; Mobile SSAO emits no unsupported-feature warning.
- Difficulty curve after tuning (autoplay, serve rate / earnings, incl. streak & tips):

| Day | Newbie | Skilled |
| --- | --- | --- |
| 1 | 100% / 166 | 100% / 160 |
| 5 | 100% / 204 | 100% / 322 |
| 9 | 73% / 140 | 100% / 456 |
| 12 | 57% / 112 | 100% / 454 |

- Days 1–5 remain a full-clear learning window for both profiles; real pressure lands from day ~8 for slower play while skilled play stays at 100% with roughly 3–4× late-game earnings, so speed has a visible payoff.
- HUD icon alpha validation: all five PNGs are 128 × 128 with alpha and transparent corners.
- Customer serve/leave animation paths were exercised by all eight autoplay runs without script or gameplay failure.

final result: passed

### Iteration 52 (release-quality hardening)

- Closed a rendered gamepad focus race that could exhaust Godot's message queue after sealing a cup. Deferred order focus now resolves the latest active card, avoids redundant rebuilds and is guarded by a stale-request regression.
- Reworked the day interaction hierarchy and contrast: Cocoa copy/focus, Cream idle ingredient tiles, Coral selection, outlined utility/destructive actions, semantic order-card accessibility text, a two-level HUD and synchronous first-frame metric population.
- Added validated temporary save writes, last-known-good rotation, truncated-primary recovery and an explicit recovered-save message. Save v21 also caps the active night lab at 16 inspiration while preserving unused performance inspiration across close/resume and older saves.
- Replaced the frame-delta-dependent fourteen-day strategy harness with a fixed 1/30-second logical clock, reproducible craft-error RNG and non-zero A/S/S grade, upgrade-day, stars, cash, wage and angry-customer assertions.
- Added mobile display-safe-area fitting, full-viewport modal overscan under safe-frame scaling and both-landscape orientation; added the full LXGW WenKai OFL and third-party notice to every export preset.
- Added `tools/run_godot_checks.sh`, including strict log-error detection because Godot can exit 0 after a script/assertion failure. Final result: 23/23 core checks, three asserted campaign routes and Forward Mobile Day 10 pressure pass at 58,228 triangles / 194 surfaces / 335 draw calls / 130.61 MiB.
- Regenerated the final nine-screen baseline in `design/qa/iteration52-audit`. Full evidence and external release gates: `design/qa/iteration52-quality-pass.md`.

Project-side quality result: passed. Public release remains blocked by macOS signing/notarization, Android production toolchain/signing, iOS distribution plus physical-device validation, and five independent fourteen-day human campaigns.

### Iteration 53 (code polish and per-frame performance)

- Fixed a night-lab integrity bug: after a >=80 trial, changing any ingredient kept the pending score; shelving then recorded the new formula with the old quality, marketing an untested cup as a premium item (also usable as a score-then-shelve exploit). Ingredient changes now invalidate the pending shelf note, `_on_shelf` refuses to run without a live pending quality, and `night_check` covers the blocked path.
- Fixed a viewport-coordinate defect: the shake progress bar consumed SubViewport coordinates and the served-coin flight tweened to window coordinates, both assigned into the SafeFrame's authored local space, so on 16:10, 21:9 or safe-area-inset viewports both drifted far from their anchors. A shared `_window_to_frame` conversion now anchors them; `input_check` asserts the offset and scaling inversion.
- Removed per-frame waste from the day-shop `_process` chain: order cards shared four cached StyleBoxFlats instead of allocating two per customer per frame; patience labels, the HUD and both prep stations rebuild only when their derived inputs change (progress bars stay per-frame); the customers array is no longer duplicated every frame. Locale switches invalidate the caches so bilingual copy still hot-swaps.
- Made card-action refreshes safe in the menu board, recipe journal and staff panel: pressed handlers no longer `free()` the card that owns the emitting button (deferred refresh, matching the upgrade/contract convention), and a refresh that destroys the focused control re-grabs the close button so keyboard/gamepad navigation never dead-ends (worst case was staff confirm-dismiss needing a mouse).
- Hardened save loading: wrong-typed nested `legacy`/`settings`/`key_bindings` values now fall back to defaults instead of aborting the load; `save_migration_check` gained the fixture.
- Debounced pause-panel settings writes: volume slider drags previously ran the full save pipeline (temp write, parse-back validation, backup rotation) on every tick; settings now apply to memory/audio immediately, with disk writes merged over 0.6s and flushed on panel close or destruction.
- Art/modeling note: no 3D model, texture, GLB or Blender source was modified in this pass; existing mesh/triangle/file budgets remain guarded by `model_asset_check.tscn` and `mobile_render_check.tscn` and still pass unchanged.
- Verification: full 25/25 check suite, a windowed Day-10 screenshot review (order cards, prep stations, HUD), and Day-9 autoplay bots (newbie 86%/147, skilled 100%/501) matching the documented difficulty curve.

### Iteration 54 (economy integrity and release hardening)

- Closed a farmable income-duplication path: day income banks to persistent state on every serve while full saves occur mid-day (settings sliders, locale switch, trait reveal), so returning to menu or killing the app reloaded banked coins and restarted the same shift for full re-earning. `GameState` now records a day-open economy snapshot at every legitimate day transition (night rollover, campaign continue, new game, New Shop+ after its grade bonus), persists it, and rolls banked fields back when resuming an unsettled day. `save_migration_check` covers same-day rollback, missing snapshot, stale snapshot and night-phase no-op; old saves migrate by re-marking on the next fresh day.
- Closed an end-of-day ledger leak: the in-flight (sealed or half-built) cup at the buzzer was never costed, letting each day end holding free ingredients. `_end_day` now charges it as stock+waste exactly like a manual discard; `operating_cost_check` pins the charge. The fourteen-day growth campaign absorbs the previously leaked costs (42/42 stars, S grade, cash 3,990 vs 4,002 before).
- Hardened startup and data-table loading: a corrupt or missing `ingredients.json` now logs an explicit error and exits cleanly instead of null-crashing (release templates strip the old `assert`); secondary tables fall back to empty arrays. `build_props` clears hover-hint sources so a source recorded on a freed prop cannot leak into the next day's world labels.
- Localization audit: all 803 CSV keys verified for format-argument parity and non-empty values, and every `GameLocale.text` key referenced by game code (484) exists in both languages.
- Release gates re-run: 25/25 core checks plus all three campaign strategy routes (careful/balanced/growth) pass. No 3D model, texture or GLB source was modified.
- Design note (not changed, pending an authoring decision): swapping the tea base mid-cup consumes a brewed portion that is never charged to the day ledger; only the final cup's ingredient cost settles. Charging the discarded portion would be a balance change and is recorded here instead.
- Product note: export presets still carry version `0.1.0`; choosing the shipping version string is a release-management decision outside this pass.
- Android gate closed: installed JDK 17 (Homebrew `openjdk@17`) and the Android SDK (`~/android-sdk`: cmdline-tools, platform-tools, build-tools 34.0.0, platforms;android-34, licenses accepted), generated a debug keystore, and wired both into Godot's editor settings. `--export-debug "Android"` builds the 41,119,320-byte arm64 `MilkTeaHouse-debug.apk`; `apksigner verify` (debug certificate), `aapt dump badging` (`com.milkteahouse.game`, 0.1.0, minSdk 24 / targetSdk 36, arm64-v8a only) and an install-and-run pass on an Android 14 arm64 Pixel-6 AVD all succeed — title, new game, day shop and tutorial render cleanly on the Mobile renderer with zero logcat fatals across input interaction. Evidence: `design/qa/iteration54-android/01-android-title.png` through `03-android-play.png`. Store release still needs a production keystore and physical-device profiling.

### Iteration 55 (contrarian review loop toward Steam-recommended quality)

- Ran a formal review loop (`docs/contrarian-loop/`): three independent Steam-reviewer audit agents (first-hour, core-feel, depth-replay) each gathered real evidence — autoplay bots across days/profiles, windowed screenshots, campaign sim, code reads — and ranked weaknesses with file:line citations (`docs/contrarian-loop/reports/`).
- S1 (feel/legibility, evaluator PASS): the 1.4x three-star line is now visible on the HUD and settlement goal bars with a goal tick and star-target copy; 1-2 star verdicts disclose net operating income; patience bars/labels use three bands matching the service-tip tiers with a band-drop cue for the head customer; prep fills recolor by batch state with GOLDEN/SPOILED transition cues; wrong delivery names the mismatched component(s) and tossed-cup cost in both languages; the reward flash wraps within 760px/2 lines and kills its predecessor tween; shake decay pauses 0.5s after each registered shake with a ceili counter; the streak pill pulses (reduced-motion gated). New regressions pin the goal bar, flash copy and ceili counter.
- S1 side effect, evaluator-verified: the shake grace lifts the low-skill serve loop deterministically (newbie day-3 bot 185/2★ → 222/3★; seals cost 5 presses instead of ~7), so the campaign strategy gate was re-baselined with a dated migration note (careful route now S/33★/500-550 cash, balanced ceiling 2360); the gate remains item-exact.
- S3 (endless depth, evaluator PASS): endless mode no longer freezes — contract targets creep +1 per 6 days past day 46 to a cap of 40, signing costs scale to +210, the star goal climbs from 380 to 420 past day 30, and two rank tiers (City Legend at 15 stamps, Milk-Tea Legend at 20) extend past Golden-Cup. Day-16 economics and the pure goal function through day 30 are asserted unchanged.
- A catch-up goal relief (yesterday ≤1★ → today ×0.85) was built, measured and deliberately reverted: it works mechanically (careful route 30→33★, A→S) but compresses the authored A/S/S mastery spread — adopting it is a recorded product decision, not a unilateral change.
- Deferred with evidence (product/art decisions or gate re-baselines needed): interactive tutorial steps, reset-cup misclick grace, week-2 event identity/late ingredients (icon art), premium upgrade tiers, route structural rules, brief quality ladder, market price choice.
- Verification: 25/25 core checks and 3/3 campaign routes green after both sprints; two independent evaluator rounds PASS with reports in `docs/contrarian-loop/evaluations/`.

### Iteration 58 (final code-drawn topping icons + balance-table cleanup)

- Closed the last release-art debt from the Batch-2 week-2 toppings: osmanthus jelly and cheese foam no longer ship recolored placeholder squares. `tools/gen_ingredient_icons.py` draws both icons fully deterministically in the existing topping-icon family style (measured contract from pudding/coconut_jelly: 128×128 RGBA, ~33% opaque footprint, white ceramic bowl x14–108/y43–105 with rim gradient and bottom shadow, subject on top, three-tone soft shading, specular, no dark outline). Shapes are authored as pixel-space signed-distance fields on a 4× supersample and downscaled with LANCZOS; subject hues anchor to each topping's `color` field in `ingredients.json` (the same single source of truth the in-cup liquid and 3D topping bins use). Osmanthus jelly renders as an amber three-cube stack with pressed osmanthus petal specks; cheese foam as a three-swirl cream cap with a salt-golden drizzle.
- Objective acceptance beyond eyeballing: shipped footprints match the family (x-extent identical at 14–108; y 28–107 vs 31–105), subject-color signatures sit in family space and distinct from neighbors at the 28px in-game size (osmanthus h≈40/l≈0.62 vs brown-sugar h32/l0.57 and pudding h49/l0.85; cheese-foam l≈0.73 with a golden drizzle vs near-white coconut jelly), and a windowed Day-12 `SHOT_DEMO` capture shows both icons rendering in the live topping chooser with no layout or style regression. menu/localization/menu_catalog/night regressions green after the swap; full 25/25 core suite green.
- Balance-table cleanup (companion to Iteration 57's metrics): two parallel agent sessions briefly ran the matrix into the same CSV, leaving 27 byte-identical duplicate newbie rows (both writers use the same zero-upgrade newbie config and autoplay is deterministic, so the data stayed semantically pure). Deduped 132→105 rows; the committed calibrated gates re-verified on the pure table — PASSED (DD median ≥1 every regular day, tension d8-14 has 2+ days in [1.00,1.45], no regular 3-day boredom band). Note for the record: the first-draft gates ([0.9,1.15] band, min-DD, skilled included in the boredom clause) failed 8 checks by contradicting authored pass criteria (Iteration 56 #4 skilled 2.1× mastery payoff; Batch-2 premium sinks deliberately zeroing late idle cash); the in-script recalibration documented 2026-08-15 encodes the design-anchored thresholds.
- Housekeeping: removed stray session artifacts (`brief_view.png`, `.playwright-mcp/`) and gitignored browser-automation/venv paths; icon generator venv lives at `tools/.venv` (Pillow+NumPy only).


### Iteration 57 (1.0 product plan: batches 1-4 + layer-2 metrics)

Executed the full owner-approved 1.0 plan in four dependency-ordered batches; every batch re-ran the 25/25 core suite, and the two balance-touching batches each performed exactly one campaign-gate re-baseline with dated migration notes inside the sims.

- **Batch 1 (zero-gate)**: all export presets at 1.0.0 (pinned, stale 0.1.0 rejected); tutorial grows to six steps with the goal-and-stars teaching and step-1 spotlight on the HUD goal row; the eight playtest small items (settlement formula lines + 88/78/62 tier cutoffs as shared constants, dark-menu slot counter, disabled-try tooltip, full-name sugar tiles, currency unification, event-copy polish, gamepad order-card wording); endless career stats line.
- **Batch 2 (campaign re-baseline #1)**: the upgrade tree grows to 14 levels with day-11-14 premium tiers (+3,180 - the careful route's idle cash drops from 525 to 44) plus the day-11 exclusive positioning pair (Flavor vs Craft, one-time pick, shown on the report); week-2 identity (trend-ordered days 9-14, second-pass 0.94/0.96 bend, six gameplay-changing modifiers from delivery rush to office-party 3-cup tickets) and two late toppings (Day-10 osmanthus jelly, Day-12 cheese foam, recolored placeholder icons pending hot-swap); capped recovery relief (goal x0.85 with a visible badge, stars capped at 2 that day, report footnote - careful returns to grade A, preserving the mastery spread). New baselines: careful A/10-of-14/34 stars/44 coins, balanced S/42/2400, growth S/42/4555 with 9,299 gross.
- **Batch 3 (endless re-anchor)**: contract fees compound uncapped at +15%/day past day 16 (day-58 streak fee 120 -> 876); the adaptive star goal T = clamp(max(base, 0.85xMA5), 0.94xT', 1.06xT') replaces the linear creep with revenue history persisted - strong shops climb 6%/day, collapsed shops fall only 6%/day (shock math pinned); the seventh rank tier (Immortal at 30 stamps, legend-defense copy) ships bound to the fee curve with 1.05-per-stamp requirements past 20; structural route identity (rush: two featured slots + x0.85 arrivals + +2 per third cup; precision: critic rewards x1.25; trend: nightly auto-pin of the best event match into slot one) with per-route stat lines on the report.
- **Batch 4**: tutorial steps 3/4 now gate on really selecting a tea base and sealing a cup (clock frozen, customer spawned); two failed attempts auto-release the gate with a replay hint - softlock-free by construction and pinned in onboarding_check.
- **Layer-2 metrics** (`tools/balance_metrics.sh`, 132 deterministic runs -> `design/qa/balance_table.csv` + p50 table): decision density median >= 1 affordable tier for every regular day; tension band [1.00,1.45] hit on 2+ of days 8-14; no 3-day boredom band for regular (tau 1.68 -> 1.40 -> 1.26 across days 9/12/14 - declining pressure as intended). Gate calibration is documented in-script: skilled's tau above 1.4 is the 42/42-star mastery design, and the zero-upgrade hoarding flow measured the wrong condition. Per the verification plan section 10, every future re-baseline PR attaches a balance-table diff.
- Verification: 25/25 core + 3/3 campaign routes green after every batch; six new/extended behavior suites (upgrade positioning exclusivity, adaptive-goal fixed-point and shock cases, second-pass modifiers, capped relief, route parameters, tutorial gates).

### Iteration 59 (polish batch: recorded CF/FH backlog closure)

Closed the four highest-evidence items still open on the contrarian-loop deferred list, each with a regression pin; 25/25 core + 3/3 campaign gates green after the batch (growth route reproduces its baseline numbers exactly, proving the bot change is behavior-neutral).

- Pause is reachable during the tutorial and event briefings (CF): `_toggle_pause` no longer early-returns behind those overlays — settings, safe-quit and volume control can no longer be locked out by a teaching card. The day-end settlement scrim stays exclusively modal. The pause panel gained `z_index=32` because the event-briefing layer is parented above `ui_frame` and would otherwise cover a paused panel (invisible panel + paused tree = softlock). onboarding_check pins open/resume during the tutorial and the z-order guard.
- Reset-cup misclick protection (FH#6): discards costing ≥3 coins now require a second press within a 2s window; the first press charges nothing, keeps the cup and flashes the exact pending loss. Below the threshold one press still discards (no friction on cheap resets). operating_cost_check pins the armed path, the exact single charge, immediate small-discard behavior; autoplay and the campaign sim double-press their planned discards.
- Slacker pre-warning (CF): once the trait is revealed, a working slacker flashes one gentle warning 3s before dropping idle (name + wake key + soft alert at half volume); the first cycle stays silent so the reveal beat keeps its surprise. Waking re-arms the warning for the next cycle. staff_check pins fire-once, no-repeat, and re-arm-after-wake.
- Tutorial buttons (P3): "跳过教学" was a hard-coded Chinese string on an unstyled button that the global theme rendered as a coral primary — making Skip visually equal to Next (and leaking CJK on EN). Skip is now a localized secondary (cream + cocoa outline, mint focus ring) while Next keeps the coral primary; pixel inspection of zh/en captures shows exactly one coral blob in the action row. onboarding_check pins the localized copy and the non-primary stylebox. [Correction from the Iteration 61 adversarial review: the original “CJK leak on EN” claim was a false positive — the value-as-key entry (跳过教学 → Skip Tutorial) translated the button all along; the styling fix and the explicit key remain the real value.]
- Localization: three new keys (TUTORIAL_SKIP, DAY_RESET_CONFIRM, DAY_STAFF_SLACKING_SOON) in both languages with matching format arguments; translation resources regenerated and localization_check green.

### Iteration 60 (DP#4: night depth — brief quality ladder + market pricing)

Closed the last open item on the contrarian-loop deferred list (audit-depth-replay #4: "night loop degrades into checkbox busywork once collections mature"), implemented as the audit's minimal fix with default-behavior compatibility so no campaign gate moved.

- Brief quality ladder: once the affinity and mastery pools empty, the nightly brief was permanently "make one 75+ cup" — a guaranteed +2 refund with zero skill expression. The balanced brief now climbs an authored ladder 75 → 82 → 88 (advance on completion, cap at 88, failed nights retry the current rung, never regress). The rung persists as `brief_quality_step` in save v23 (v22 saves default to rung 0, out-of-range values clamp). research_brief_check pins generation at each rung, promotion on completion, the 88 cap, and reward stability; save_migration_check pins the v22 default, persistence and clamping.
- Market pricing on the menu board: market-tested drinks now expose three authored price points per tier (爆款 16/18/21, 招牌 13/15/17, 普通 10/12/14) as a compact exclusive toggle row on the card — budget speeds featured arrivals 2%/cup, premium slows them 3%/cup, standard is a no-op. Legends keep authored prices. The effect composes into the existing forecast strip (traffic %), and interacts with lunch_rush's price≤13 match, making pricing a real frequency-vs-margin decision that can be re-made nightly against tomorrow's event. `set_item_price` rejects anything outside the authored points; the traffic term only counts featured custom items, so default saves reproduce old behavior exactly (pinned: standard=1.0, budget=0.98, premium=1.03, legends excluded) and the 25/25 + 3/3 gates run unchanged.
- Board evidence: the screenshot harness fixture gained a signature-tier custom card; zh/en captures show the pricing row with even button widths, coral selected state and zero CJK leakage on EN. Eight new bilingual keys; translations regenerated and localization_check green.
- Verification: 25/25 core checks + 3/3 campaign routes green (campaign numbers identical to the pre-change baseline — pricing defaults are no-ops for the sims).

### Iteration 61 (adversarial review pass on the 1.0 build)

Ran the contrarian-review loop against HEAD `cecd685` (report: `docs/contrarian-review/1.0-adversarial-pass.md`); stopped at 3 noise events with no 5-streak, review converged. Two real S3s found and fixed with regressions; one prior claim corrected.

- Fixed: the reset-confirm window could freeze across days (`_process` stops ticking when the shift ends) — `_reset_cup()` now disarms it on every system-level clear; pinned in operating_cost_check.
- Fixed: "Replay Tutorial" from the pause panel during an event briefing started the tutorial under the briefing layer (the briefing parents above `ui_frame`) — replay now dismisses the briefing first; pinned in onboarding_check, and the new `SHOT_EVENT_PAUSE` harness mode captured the pause panel correctly stacked above the briefing.
- Corrected: Iteration 59's "CJK leak on EN" for the tutorial skip was a false positive — the value-as-key row `跳过教学 → Skip Tutorial` localized the literal all along. Note appended to that entry; the secondary-style and explicit-key fixes stand.
- Determinism re-probe: a calibrated regular day-12 bot run on the current tree reproduces the balance-table baseline bit-for-bit (365 / tau 1.23 / dd 1), re-confirming default-pricing no-op compatibility.
- Verification: onboarding + operating_cost regressions green after the fixes; full 25/25 core + 3/3 campaign gates re-run green.

### Iteration 62 (compat layer removed: new title, zero legacy saves)

Owner decision: the game ships as a new project — there are no historical player saves, so the entire version-migration compatibility layer was dead weight. Removed it wholesale while keeping every corruption/data-loss defense.

- Removed version migration: SAVE_VERSION resets to 1 (the v5→v23 development history and its ladder fixtures are gone). save_migration_check is replaced by save_integrity_check — same runner slot, fixtures now cover only corrupt-save defense (wrong-typed nested fields, staff wage/trait forgery rebuild, dark-menu kind/formula/serial validation with the 3-slot cap, market-settlement stale/worst-case round-trips, same-day economy rollback, atomic writes, backup rotation, truncated-primary recovery).
- Removed old-format recovery: MenuCatalog no longer scans recipes by item *name* to rebuild legends (the R4-era recovery) — legend resolution is id-based only, and a malformed no-id item stays an inert non-orderable collectible; the dark menu no longer accepts raw string entries or `legacy` kind (legend/mystery dictionaries only); the settings loader no longer merges the old single sound slider, and the mirrored `sound_volume` key is gone end-to-end (accessor, defaults, panel writes, all test fixtures now set `sfx_volume`/`music_volume` directly).
- Localization: dropped the now-redundant value-as-key row for the tutorial skip (the explicit TUTORIAL_SKIP key owns that string); translations regenerated. The remaining value-as-key rows are the live mechanism for hard-coded literals and are unchanged.
- Verification: 25/25 core + 3/3 campaign routes green after the sweep. The careful/balanced/growth asserts pin A/34★/56, S/42★/2377 and S/42★/4555 — verified bit-identical on the pre-change HEAD (the 56-vs-44 delta vs the older docs is the Batch 3-4 endless re-anchor, not this pass).

### Iteration 63 (value-as-key localization eliminated; malformed menu items dropped)

Second half of the new-project compat cleanup: the remaining 55 value-as-key CSV rows (hard-coded Chinese literals translated by matching the literal as a translation key) are gone.

- All 52 live display strings migrated to explicit keys (TITLE_*, MENU_*, PAUSE_*, SETTINGS_*, DAY_PAUSE, EVENT_BRIEF_*, LAB_*, PANEL_BACK_LAB, UPGRADES_/STAFF_HIRE_/CONTRACT_INTRO_*, NIGHT_*). Static Controls now carry the bare key (`pause_button.text = "DAY_PAUSE"`) so Godot's auto-translate resolves it — identical rendering and free live locale switching, no per-panel refresh wiring needed. recipe_lab's 茶底/奶基 tokens stay internal: they are semantic near-miss markers already localized through `slot_name()` data keys.
- Three rows were dead (no code site) and deleted outright; the CSV now has zero CJK-keyed rows (905 → 902 keys, verified programmatically).
- localization_check now pins every bare key in both languages (a typo'd key would otherwise render the raw key on screen) and its static auto-translate probe uses TITLE_NAME.
- Malformed menu items (no id, no formula) are now dropped at normalization instead of becoming `legacy:` collectibles — with no old saves to preserve, an id-less entry is corruption, not history. campaign_check fixtures upgraded to the well-formed items a fresh save actually contains.
- Verification: 25/25 core + 3/3 campaign routes green with bit-identical campaign numbers (56/2377/4555); EN title and night-lab captures confirm every migrated surface renders translated copy with zero raw-key or CJK leakage.

### Iteration 64 (twelve-user full-flow playtest: multi-agent find → verify → fix)

Ran the largest simulated playtest round yet: 12 persona agents (first-hour, mastery, gamepad-only, English, night-research, pressure, New Shop+, endless, pricing-economist, mobile/touch, speedrun, accessibility) each gathered real evidence via autoplay bots, campaign sims, headless regressions, windowed captures with pixel checks and code tracing (reports: `docs/contrarian-playtest/12users/p01-p12`, tally in `_stats.md`). 81 raw findings → 78 after cross-agent dedup (18 S1 / 32 S2 / 28 S3). Three adversarial verifier agents then re-proved every S1/S2 against code: 54 confirmed, 0 refuted wholesale (two scope corrections, one sub-item dropped).

Fix waves (file-ownership separated, every fix regression-pinned by the fixing agent):
- Interaction/UI-code (fix1-report.md): tutorial practice gates now completable with REAL input on every modality (mask lets clicks through during gated steps, `_tutorial_practice_active` guards exempt keyboard/shake while the clock stays frozen; onboarding_check pins the input-path route); tutorial focus steal double-guarded; night modal panels + day pause get unified focus confinement (D-pad can no longer act on covered controls); naming LineEdit shows the OS virtual keyboard and rejects empty submits visibly; upgrade/contract panels restore focus after purchase; cup-status line wraps (worst-case 1112px → fits); rush slot copy uses `featured_limit()` in all four surfaces (2/2 not 2/3); tutorial spotlight punches a real hole with a compliant border; patience seconds labels recolored to ≥4.5:1; promotion-after-leave requires review before delivering; reduced-motion now stops existing actors; touch-mode copy branches added; Android VIBRATE permission; orientation locked; rebind reserved-key guard extended; tutorial replay resets gate state; menu-board saves debounced; dead customer_avatar code removed.
- Economy/systems (fix2-report.md): positioning dead-purchase guarded both directions with panel notes; pricing re-anchored from a global spawn-interval modifier to per-item featured cadence (budget ordered more, premium less; legends excluded — kills the strict-premium dominance), campaign sims re-baselined with dated notes; endless cup targets clamped to a winnable envelope (WINNABLE_TARGET_CAP=36); revenue-sprint coefficient 1.35→1.15 with a 5-day-best clamp so the converged state is winnable; next-rank text fixed for 20-29 stamps + immortal tier wired with a defend counter; positioning counts toward the campaign grade (denominator 14→16, campaign_check re-pinned); main menu shows the legacy best line; New Shop+ routes now apply their calendar from day 3; market-test failure line 62→76 makes the refund a real (~6%) outcome; settlement cards carry the actual formula fields end-to-end; rent amounts preview in the HUD cost pill; sprint refunds scale with day.
- Localization batch (fix3-report.md + main-session wiring): 14 new bilingual keys, the pricing family translated to zh with per-tier tooltips, 11 comma omissions fixed, route-calendar event names aligned (en), tutorial star-copy corrected to the real 0★ floor, Stock/Rent spacing, quote/plural/separator consistency, rush copy corrected (+2 coins / +15% arrivals), lunch-rush price hook surfaced on the menu board, forecast sign renders "-9%" not "+-9%".

Gates after integration: 25/25 core + 3/3 campaign routes green (careful A/35★/118, balanced S/42★/2295, growth S/42★/4478 — dated re-baseline notes in the sims). Recorded as product decisions with evidence: quality-ladder pacing (V2 options in fix2-report), touch-target density on small phones beyond the bounded fix, per-tier pricing tooltip precision.

### Iteration 65 (sustained single-reviewer sweep: 10 consecutive noise)

Per owner directive, ran a continuous review-fix loop on HEAD `7d889f5` without sub-agents, stopping at 10 consecutive noise findings (record: `docs/contrarian-review/1.0-sustained-sweep.md`). Ten directed hypotheses over the freshest fix surfaces — tutorial practice guards, pricing cadence edges, the endless winnable envelope, cross-domain reserved-key/orientation edits, save-debounce teardown, focus confinement vs naming, placeholder i18n, night_check output format, plus an economy regression spot-check — all verified clean; the spot-check reproduced the pre-fix balance table bit-for-bit. No new defects; no code changes required; gates remain green from `7d889f5`. Convergence pattern across Iterations 61 → 64 → 65 (adversarial loop, 12-user verified playtest, sustained sweep) indicates automated review is now noise-dominated; human/device evidence is the next tier.

### Iteration 66 (day-shop reference alignment)

- Source of truth: `design/mockups/coral_mint/full-set-v3/01-day-shop.png` (1672×941), normalized to the authored 1280×720 game viewport. Implementation state: zh_CN, `SHOT_DEMO=1`, Day Shop topping-selection step. Final implementation capture: `design/mockups/coral_mint/full-set-v3/00-current-implementation-final.png`.
- Same-input full-view comparison: `design/mockups/coral_mint/full-set-v3/qa/day-layout-comparison-final.png`. Focused left-queue/workbench comparison: `design/mockups/coral_mint/full-set-v3/qa/day-layout-focus-final.png`.
- Comparison history: baseline → v1 raised side camera → v2 closer counter/vertical queue → v3 cleared central prep obstruction → v4 restored reference-scale work mat and pickup zone → v5-v9 replaced the mismatched regular-customer render with the existing transparent reference-guided cutout and tuned scale/placement → final mint context and coral station labels.
- Required surfaces: top-left day/currency/inspiration HUD and top-right pause are separated; order cards and customers form the left vertical queue; tea/milk/toppings/sugar/shaker read as the rear station band; the cup/work mat owns the lower center; pickup tray/bell occupy the right; cup status and one next-step action remain bottom-centered. No P0/P1/P2 clipping, overlap, hierarchy, or interaction defect remains. The compact top-right preparation strip is an intentional gameplay extension absent from the concept, and stays subordinate to the reference composition (P3).
- Functional verification: `tools/run_godot_checks.sh` passed 25/25 core scenes; final screenshot rendered through the real Metal Forward+ path. `git diff --check` clean.

Final result:
passed

### Iteration 67 (day-shop reference alignment, exact-detail rebuild)

- Source of truth: `design/mockups/coral_mint/full-set-v3/01-day-shop.png`, normalized to 1280×720. Final implementation: `design/mockups/coral_mint/full-set-v3/00-current-implementation-final.png`. Same-input comparison: `design/mockups/coral_mint/full-set-v3/qa/day-layout-comparison-final.png`; focused comparison: `design/mockups/coral_mint/full-set-v3/qa/day-layout-focus-final.png`.
- P0: none. P1 fixes: rebuilt the left order/customer slots to the reference dimensions and 210px rhythm; unified regular/special customers into the fixed side queue; moved the context panel to the measured lower rear-band position; restored the side queue rail; removed the foreground prep tier that occluded pickup; re-centered the work mat/cup; rebuilt the pickup tray and bell placement; restored the order-ticket and pickup-arrow flow.
- P2 fixes: matched HUD/pause geometry and station-label baselines; moved tea, milk, topping, sugar and shaker props onto the rear tier; removed the oversized menu-board/lamp visual noise while retaining required semantic GLB nodes; changed lighting from low-exposure ACES + heavy SSAO/glow to warm matte cream light; added transparent reference-guided pause, next-hand, reset-sign, order-ticket and pickup-arrow assets.
- Interaction remains live: station tags still trigger their actions, the tea tag toggles preparation, order cards remain selectable, the order ticket follows the active customer, reset remains available through the A-frame sign, and the primary action continues to reflect the current recipe step.
- Verification: Metal Forward+ final screenshot review; Day 9 three-customer layout review; `tools/run_godot_checks.sh` passed 25/25; `mobile_render_check.tscn` passed with shop 28 meshes / 13,240 triangles and full scene 44,392 triangles; `git diff --check` clean.

Final result:
passed

### Iteration 68 (day-shop structure and material convergence)

- Source visual truth: `design/mockups/coral_mint/full-set-v3/01-day-shop.png` (1672×941). Implementation: `design/mockups/coral_mint/full-set-v3/00-current-implementation-final.png` (1280×720, CSS/game viewport 1280×720, density 1). State: zh_CN, Day 1, two-customer queue, valid sugar-selection step after tea/milk/topping. The source was normalized to 1280×720 before comparison.
- Full-view evidence: `design/mockups/coral_mint/full-set-v3/qa/day-layout-comparison-final.png`. Focused queue/workbench evidence: `design/mockups/coral_mint/full-set-v3/qa/day-layout-focus-final.png`. Day 9 three-customer resilience evidence: `design/mockups/coral_mint/full-set-v3/qa/day9-three-customer-final.png`.
- Earlier P1 findings and fixes: the rear station was a flat shelf instead of the reference's enveloping cabinetry, the queue rail ran diagonally through the foreground, and the dark-teal counter fascia dominated the lower half. The revised GLB adds a cream cabinet/apron/divider structure and centered jar cubby, projects the rail vertically at the measured left divider, and removes the oversized inset fascia while retaining the mint kick and warm wood top. Post-fix evidence shows the same left queue / rear station / center mat / right pickup hierarchy as the source.
- Earlier P2 findings and fixes: rear props were undersized and too low, the pickup tray was left of its source slot, the cup guide was a continuous ring, the second customer sat too high, and three-option panels could overflow their teal shell. Props and jar dressing were enlarged and raised, tray/bell were re-aligned, the guide is now a thin dashed mint ring, customer slots fit the 720px queue, and context sizing now covers 2/3/5-option states without overflow.
- Required fidelity surfaces: WenKai typography and app copy retain the established game system; spacing/layout follows the normalized source regions; coral/mint/cream tokens are warmer and slightly more saturated without restoring glossy glow; generated transparent pause/arrow/ticket/sign assets retain clean alpha; app-specific text and all controls remain live. The source's painterly ingredient detail is denser than the runtime's existing low-poly 3D prop family; keeping the real interactive props is an intentional P3 product constraint, not a layout substitute.
- Verification: 25/25 core checks passed; Forward Mobile Day 10 three-customer/full-upgrade pressure passed at 161 visible meshes, 42,700 triangles, 276 draw calls and 123.84 MiB; `git diff --check` passed.

Final result:
passed

### Iteration 69 (six-region crop alignment)

- Source and viewport: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` and `design/mockups/coral_mint/full-set-v3/00-current-implementation-region-aligned.png`, both 1280×720. The six same-coordinate comparisons are `qa/regions/01-hud-comparison-final.png` through `06-bottom-comparison-final.png`.
- Region 1 — HUD: restored the measured 205/75/75px pill widths, 42px height and source pause-button bounds; the mobile HUD keeps a 12px minimum value width.
- Region 2 — queue: aligned both order cards and customer cutouts to the source's vertical rhythm; resized and lowered the A-frame reset sign to the reference slot.
- Region 3 — rear station: removed the unrelated overhead jar rack, enlarged the live tea/milk/topping/sugar/shaker props, and redistributed the groups across the source station band. The real Day-1 data exposes more choices than the concept, so the interactive props remain denser while their group bounds align.
- Region 4 — workbench: matched the prep-mat rectangle, cup guide, cup and active-order ticket bounds. The five-choice sugar panel is centered on the same axis as the source's three-choice topping panel.
- Region 5 — pickup: flipped and aligned the dashed flow arrow, then matched the pickup sign, tray and bell bounds independently.
- Region 6 — lower counter: added the missing cream/mint front fascia at the measured depth and aligned the single bottom action bar. No extra bottom controls were introduced.
- Verification: `tools/run_godot_checks.sh` passed 25/25; Forward+ mobile pressure passed at 154 meshes / 154 surfaces / 37,844 triangles; shop GLB passed at 24 meshes / 5,660 triangles; `git diff --check` passed.

Final result:
passed

### Iteration 70 (rear-station asset and motion convergence)

- Visual truth and normalization: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` (1280×720, density 1) and final implementation `design/mockups/coral_mint/full-set-v3/00-current-implementation-station-art-final.png` (1280×720, density 1). The focused rear-station comparison uses `qa/regions/03-rear-station-comparison-art-final.png`; the implementation half is the same topping-selection interaction state with three unlocked topping choices, cropped to the same `(250,40,1030,260)` rectangle.
- Earlier P1: the runtime's duplicated low-poly kettles, cartons, bins, pumps and shaker no longer matched the source's soft painterly equipment family. Fix: generated five reference-grounded transparent groups (tea/milk, toppings, sugar, shaker and equal-width twin cabinet), placed them at measured bounds, and hid only the old mesh renderers while leaving their physics hotspots and ingredient handlers active. Post-fix evidence shows matching object count, silhouettes, palette and group density.
- Earlier P2: the source's cabinet enclosure and top `小料` sign were absent, five physical sugar labels spilled into the shaker slot, and static equipment had no tactile feedback. Fix: added the twin cream/light-wood cabinet and measured sign, limited the physical pump labels to the source's four bottles while keeping all five sugar choices in the functional chooser, added 70–230ms squash/recover feedback per ingredient group and a three-beat shaker wiggle, and preserved reduced-motion suppression. Motion evidence: `qa/animation/station-topping-pulse-contact-final.png`.
- Required fidelity surfaces: WenKai text, weight and label scale remain consistent; rear-group margins, cabinet divider, top/bottom rails and context-panel axis match the normalized source; coral/mint/cream tokens and matte highlights come from the source crops; final images have real alpha and no runtime placeholders; app copy remains localized and all visible station/order controls remain functional.
- Interaction and accessibility: transparent art uses `MOUSE_FILTER_IGNORE`, so mouse/touch/gamepad paths still reach the live controls; the complete base → milk → topping → sugar → shake → seal → review/deliver flow is exercised by `input_check.tscn`; reduced motion skips station tweens.
- Verification: 25/25 core checks passed; Forward+ mobile pressure passed at 62 meshes / 62 surfaces / 15,340 triangles; shop GLB passed at 21 meshes / 3,856 triangles; `git diff --check` passed. No actionable P0/P1/P2 finding remains in this iteration.

Final result:
passed

### Iteration 71 (central cup state and motion convergence)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png`; implementation: `design/mockups/coral_mint/full-set-v3/00-current-implementation-cup-final.png`, both 1280×720 at density 1 in the same zh_CN topping/sugar flow. Full-view evidence: `qa/regions/00-full-comparison-cup-final.png`; focused same-scale workbench evidence: `qa/regions/04-workbench-comparison-cup-final.png`; sealed-state evidence: `qa/regions/04-cup-sealed-final.png`.
- Earlier P1 (image quality): the work cup was a low-poly cylinder with red rings and a dark horizontal meter across its center. Fix: replaced only its renderer with five pixel-aligned transparent painterly states—empty, tea, milk tea, topping and sealed—while retaining the real cup hotspot and gameplay state. The meter now appears only after sugar confirmation and sits below the cup.
- Earlier P2 (behavior): cup contents changed numerically but had no readable preparation beat. Fix: tea/milk use a restrained 180ms settle, toppings a 200ms drop/bounce, shake a 220ms three-beat wiggle, and seal a 220ms squash/recover; reduced motion resets directly to the stable transform. Motion contact evidence: `qa/animation/cup-topping-bounce-contact-final.png`.
- Required surfaces: typography and app copy are unchanged; the cup now matches the source's warm amber/ivory palette, soft matte highlights, clean alpha, double rim and pearl scale; its focused size, top/bottom baseline and dashed guide relationship match the source crop; no placeholder geometry remains visible; all five state transitions and the complete serve flow are asserted.
- Correction from the next same-coordinate grid audit: the earlier 120px workbench-offset finding was caused by reading the right half of an `hstack` comparison as if it retained the left half's global x origin. Direct 100px-grid overlays prove the mat, dashed guide, cup, ticket, bell and pickup tray already occupy the reference coordinates. The trial group translation made fidelity worse and was fully reverted; no absolute-layout P1 remains from this iteration.
- Verification: 25/25 core checks passed before the final 10px cup-height trim; the focused `input_check.tscn` passed afterward, including all five textures, hidden 3D cup, below-cup shake meter and reduced-motion stability. Built-in imagegen prompt set and workspace assets are recorded in `assets-transparent/cup/README.md`.

Final result:
passed

### Iteration 72 (context-card hierarchy and coordinate audit)

- Visual truth and state: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region72-final.png`, both 1280×720/density 1. The new `SHOT_WORKBENCH=1` harness holds a real pearl-added cup in the still-selecting-toppings step so the reference panel and runtime panel can be compared at the same interaction phase.
- P1 corrected, not shipped: a trial translation moved the complete workbench left after an `hstack` half-offset was mistaken for global x drift. A direct 100px grid proved the source/runtime work mat, cup and pickup coordinates already coincide; the trial was reverted before final capture. This prevents an apparent numerical improvement from degrading the real layout.
- P2 image/hierarchy fix: runtime ingredient choices were horizontal text buttons with 20–30px icon subjects, while the reference uses large product bowls above the labels. Each live choice now reuses its real ingredient PNG in a 66px image slot above a centered 15px label, retains the keyboard number only for keyboard mode, and exposes the same display text through the button accessibility name. The focused comparison is `qa/regions/03-context-comparison-region72-final.png`.
- P2 spacing fix: ingredient panels were 32px above the reference baseline. Standard ingredient states now start at y=227 and finish on the reference lower edge; the panel's internal top/bottom margins and gap were tightened so the larger imagery does not inflate the shell. The action bar moved 8px right and gained 2px height; the pickup arrow moved 16px right; the reset sign was shortened and lowered to the source bounds.
- Motion and accessibility: choice cards reveal in a restrained 25ms stagger plus 120ms fade, with no positional jump. `qa/animation/context-card-reveal-contact-final.png` captures the mid-transition contact state. Reduced motion skips the reveal and leaves every card at alpha 1; existing focus ring, pointer, keyboard, gamepad and touch handlers remain on the parent Button.
- Required surfaces: WenKai typography, coral/mint/cream tokens and localized copy remain unchanged; layout baselines, button image scale and workbench/pickup spacing were compared at equal pixels; all imagery uses existing real PNG assets; the source concept shows three unlocked toppings while the real Day-1 data correctly exposes two, an intentional content difference with the same panel center and tile geometry.

Final result:
passed

### Iteration 73 (left queue and order-card convergence)

- Visual truth and state: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region73-final.png`, both 1280×720/density 1. The focused same-coordinate crop is `qa/regions/07-queue-comparison-region73-final.png`; the full-view pair is `qa/regions/00-full-comparison-region73-final.png`.
- P1 position fix: order badges were 15px too high and 5px too far left, and the customer cutouts sat about 9px left of the reference. Badges now overlap the paper cards at the measured top-left corner, render above the card, and both regular customer cutouts share the reference queue centerline. Card bounds and the 210px vertical rhythm were already correct and were not moved.
- P2 hierarchy fix: the selected order used a heavy double coral frame, the drink image was undersized, the title truncated multi-topping recipes, and three static dots plus a long bar duplicated patience. Active and idle cards now share the source's light paper frame; the existing real drink PNG fills a 72px slot; the visible title is the localized primary-topping milk-tea name while the complete recipe remains in the button accessibility description; four 14px patience beats replace the redundant bar.
- Motion and game readability: patience beats drain from four to zero from the real patience ratio and inherit mint/amber/red warning bands. A changed beat uses a restrained 140ms scale recovery; reduced motion updates it instantly. The existing keyboard focus ring remains the explicit selection indicator, so matching the paper frame does not make gamepad focus ambiguous.
- Same-state harness fix: `SHOT_WORKBENCH=1` now rerenders the order card after setting its deterministic recipe, so the queue card, ticket and workbench all show the same drink during visual QA.

Final result:
passed

### Iteration 74 (top HUD scale and icon alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region74-final.png`. The equal-pixel top-band comparison is `qa/regions/08-hud-comparison-region74-final.png`; the full pair is `qa/regions/00-full-comparison-region74-final.png`.
- P2 scale fix: the 205px day pill and two 75px currency pills already matched the source widths, but their 42px bodies, 22px image slots and 18px labels produced visibly undersized content. The bodies are now 48px, the existing real HUD PNGs use 40px slots, and values use 20px type; moving the row down 2px matches the source's top and bottom baselines.
- Pause fix: the control is now 66px at the measured top-right position with a 38px icon slot. The existing transparent pause asset is tinted cocoa instead of bright gold, matching the reference while preserving hover, pressed, focus and touch behavior.
- Verification: 25/25 core checks passed before the final HUD-only scale trim; focused `input_check.tscn`, Forward Mobile `mobile_render_check.tscn` and `git diff --check` passed afterward.

Final result:
passed

### Iteration 75 (reset-sign silhouette and lower-left alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region75-final.png`. The equal-pixel lower-left comparison is `qa/regions/09-reset-sign-comparison-region75-final.png`; the full pair is `qa/regions/00-full-comparison-region75-final.png`.
- P2 asset fix: the prior blank A-frame asset had feet that splayed too far to match both the source's top rail and outside-foot bounds through uniform scaling. A reference-grounded ImageGen edit produced `assets-transparent/ui/ui-sign-reset-narrow.png`; the selected artifact was background-extracted, verified as a real-alpha 500×512 PNG, copied to the runtime asset directory, and recorded in the UI asset manifest.
- P2 coordinate fix: the sign slot is now 186×165 at `(199,527)` with its rotation pivot at center. Its visible top/bottom and outside-foot bounds align with the source crop, while the live button text remains localized reset/waste feedback instead of baking decorative concept copy into the image.
- Interaction: the transparent TextureRect remains mouse-ignoring behind the original Button, so pointer, touch, focus, tooltip, disabled state and reset-cost behavior are unchanged. `input_check.tscn` and `git diff --check` pass after the asset swap.

Final result:
passed

### Iteration 76 (pickup flow and right-side micro-alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region76-final.png`. The equal-pixel pickup crop is `qa/regions/10-pickup-comparison-region76-final.png`; the full pair is `qa/regions/00-full-comparison-region76-final.png`.
- Coordinate audit: the tray left edge, pickup-sign center and bell center were already on the reference axes, so the group was not translated. The dashed arrow alone moved down 19px and shortened to 102px, matching the source arc instead of floating above it.
- P2 hierarchy fixes: the pickup tag keeps its 140×50 bounds but now uses the source-like 18px corners and 26px label. The real 3D service bell was raised to the source baseline at world y=1.06; its interaction and render path remain unchanged.
- Intentional remaining material difference: the live 3D tray retains slightly stronger perspective than the concept's painterly top-down tray. Its measured bounds and pickup hit region match, so it stays real geometry rather than introducing a second visual-only interaction surface.
- Verification: Forward+ same-state capture and `git diff --check` pass; the earlier focused input and mobile-render checks cover the unchanged interaction path.

Final result:
passed

### Iteration 77 (bottom action bar and gamepad resilience)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region77-final.png`. The equal-pixel bottom comparison is `qa/regions/11-bottom-action-comparison-region77-final.png`; the full pair is `qa/regions/00-full-comparison-region77-final.png`.
- P2 visual fix: the outer 260px bar was already aligned, but the real hand PNG rendered at roughly 60% of the source subject and the label sat one optical size low. The hand slot is now 52px, pointer text 24px, vertical texture content margins 4px, and panel height 65px. The default bar retains the source width and bottom baseline; the live topping copy was shortened to `下一步：小料` / `Next: Toppings` to match the reference density.
- P1 responsive/gamepad fix: English gamepad copy previously expanded the fixed bar to about 400px. Gamepad prompts now use a 19px optical size, compact `· A` suffix, and ellipsis-safe expanding Label inside an explicitly fixed 260×65 panel. Evidence: `qa/regions/11-bottom-action-gamepad-en-region77-final.png`.
- Runtime fix: rapid input-scheme rebuilds previously left a deferred lambda holding a freed context Button, producing `Lambda capture ... was freed` in the real screenshot run. Deferred focus now passes the instance ID and resolves the Button at execution time; the same English/gamepad capture completes without errors.
- Verification: focused `input_check.tscn` asserts the 260px gamepad bound and visible accept hint; default and English gamepad Forward+ captures and `git diff --check` pass.

Final result:
passed

### Iteration 78 (real pickup-tray perspective correction)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region78-final.png`. The equal-pixel pickup comparison is `qa/regions/12-pickup-tray-comparison-region78-final.png`; the full pair is `qa/regions/00-full-comparison-region78-final.png`.
- Earlier P1: the real tray occupied the correct general slot but projected as a strongly slanted parallelogram, while the source tray is an almost screen-aligned rounded rectangle. Camera translation was ruled out because the shop camera is centered and changing it would regress every already-aligned region.
- Root fix: the Blender source now builds the tray from real rounded-prism meshes, widens only its rear edge by 16% to counter off-axis convergence, and exports the same two live mint/cream GLB meshes. The runtime instance keeps a calibrated x/z scale plus a fixed basis shear; post-fix evidence shows source/runtime outer bounds, inset bounds, corner radii and top/bottom baselines within a few pixels without adding a 2D overlay or duplicate hit surface.
- Image quality: the tray retains the runtime's matte cream/mint material and real scene lighting; the source carries slightly denser painterly grain, classified as P3 material polish rather than a geometry or interaction mismatch.
- Verification: 25/25 core checks pass. `model_asset_check.tscn` reports the tray at 2 meshes / 568 triangles, and Forward Mobile passes at 60 meshes / 12,956 triangles; `git diff --check` passes.

Final result:
passed

### Iteration 79 (ingredient-card vertical rhythm correction)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region79-final.png`. The equal-pixel panel comparison is `qa/regions/13-context-height-comparison-region79-final.png`; the full pair is `qa/regions/00-full-comparison-region79-final.png`.
- Earlier P2: the panel's center and lower edge were close, but each live ingredient card rendered about 10px shorter than the source, leaving a visibly heavy empty strip below the cards. This was hidden in full-view comparisons and became clear only in the focused crop.
- Fix: standard ingredient cards are now 100px and the shell baseline moves from y=227 to y=230. Post-fix card top/bottom, title region, shell top/bottom and lower padding match within a few pixels. The real Day-1 state still exposes two toppings while the concept shows three, so width differs intentionally but per-card geometry and center axis match.
- Accessibility/responsiveness: at the smallest authored mobile scale the 100px target remains above 44pt; keyboard/gamepad/touch handlers, real ingredient PNGs and reduced-motion reveal behavior are unchanged. Focused `input_check.tscn` and `git diff --check` pass.

Final result:
passed

### Iteration 80 (next-action transition cue)

- The bottom action bar keeps the exact Region-77 static bounds, but now responds once whenever its live step copy changes: 96% contact, 102% overshoot, then a 200ms return to rest. It reuses the existing panel and tween system; no parallel overlay or perpetual pulse was added.
- Motion evidence: `design/mockups/coral_mint/full-set-v3/qa/animation/next-action-rest-contact-region80-final.png`. Full-view evidence: `qa/regions/00-full-comparison-region80-final.png`.
- Accessibility: enabling reduced motion kills any in-flight cue and restores `Vector2.ONE` immediately. `input_check.tscn` asserts both the live contact state and reduced-motion rest state.

Final result:
passed

### Iteration 81 (customer-lane vertical spacing)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region81-final.png`. The same-coordinate queue crop is `qa/regions/14-customer-lane-comparison-region81-final.png`; the full pair is `qa/regions/00-full-comparison-region81-final.png`.
- The two live 3D customer slots now use z=0.20 and z=0.65, tightening their projected spacing around the reference's two character centers while leaving the already-aligned fixed order cards untouched. The third pressure-test slot remains unchanged.
- Remaining silhouette differences come from the real authored customer variants and their live idle gestures; their centerline and queue rhythm align, so those differences are retained as gameplay character variety rather than replaced by static cutouts.

Final result:
passed

### Iteration 82 (rear-station cabinet structure correction)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region82-final.png`. The equal-coordinate rear strip is `qa/regions/15-rear-station-comparison-region82-final.png`; the full pair is `qa/regions/00-full-comparison-region82-final.png`.
- Root structure fix: the twin cabinet had been placed behind the topping and sugar groups, but the reference cabinet encloses tea/milk and toppings while sugar remains independent on the right. The existing real-alpha cabinet moved from x=523 to x=298 and was calibrated to 672×220 at y=55, preserving the already-aligned live prop art.
- Post-fix evidence aligns the cabinet's left/right walls, center divider, top rail and lower rail with the reference. Mouse/touch/gamepad hotspots remain the original world controls because the cabinet stays mouse-ignoring behind the station art. Focused `input_check.tscn` and `git diff --check` pass.

Final result:
passed

### Iteration 83 (context-shell width stability)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region83-final.png`. The same-coordinate panel crop is `qa/regions/16-context-width-comparison-region83-final.png`; the full pair is `qa/regions/00-full-comparison-region83-final.png`.
- Earlier P2: two unlocked Day-1 toppings collapsed the teal shell to 260px, while the reference keeps a stable roughly 320px choice bubble. The shell now stays 320px on the measured x=714 center axis, and the live GridContainer shrink-centers the real number of cards inside it.
- This preserves reference geometry without inventing a third unlocked ingredient. Two-, three-, four- and five-choice states retain their real data, selection/focus behavior and 100px touch targets; only the outer frame no longer jumps between steps. Focused `input_check.tscn` and `git diff --check` pass.

Final result:
passed

### Iteration 84 (top-wall background completion)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region84-final.png`. The equal-coordinate top strip is `qa/regions/17-background-top-comparison-region84-final.png`; the full pair is `qa/regions/00-full-comparison-region84-final.png`.
- Earlier P2: the reference top wall contains a centered cream/mint wood window and a right two-tier oak shelf, while runtime showed blank wall and unrelated tilted frames. Two new real-alpha painterly assets were generated with the built-in image-generation path using the reference as style/material/perspective input, then saved in `assets-transparent/background/` and copied to the runtime asset tree.
- The window subject now projects at approximately x=602–797/y=0–31 and the shelf at x=819–1164/y=0–63, matching the reference strip. The old source `Frame*` meshes are excluded during the existing optimized GLB export rather than hidden after material batching; shop geometry drops from 3,856 to 3,784 triangles.
- Prompt set and authored slots are recorded in `assets-transparent/background/README.md`. Both TextureRects ignore pointer input. Focused input, model-budget and Forward+ mobile pressure checks pass; mobile reports 60 meshes / 12,884 triangles.

Final result:
passed

### Iteration 85 (left entrance color-block alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region85-final.png`. The equal-coordinate upper-left crop is `qa/regions/18-entrance-comparison-region85-final.png`; the full pair is `qa/regions/00-full-comparison-region85-final.png`.
- Earlier P3: the source's deep-teal entrance block created a strong left counterweight behind the HUD, while runtime continued the cream wall to the edge. A new real-alpha entrance prop was generated from the same reference; v2 narrows the cream jamb and projects the teal/jamb boundary at approximately x=100/120, matching the reference crop.
- The decorative TextureRect is behind HUD/order controls and ignores pointer input. Focused `input_check.tscn` and `git diff --check` pass. Prompt intent and runtime slot are recorded in `assets-transparent/background/README.md`.

Final result:
passed

### Iteration 86 (queue-floor color-temperature correction)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region86-final.png`. The equal-coordinate customer/floor crop is `qa/regions/19-queue-floor-comparison-region86-final.png`; the full pair is `qa/regions/00-full-comparison-region86-final.png`.
- Earlier P3: the live queue floor rendered noticeably yellower than the source, making the already-aligned customers and paper order cards appear pasted over a different color temperature. The existing batched `grey_cartago` material is duplicated once at runtime and tinted with `D9D4D6`, preserving its geometry, lighting and texture rather than adding a screen-space floor patch.
- The concept has denser painted plank seams than the runtime material; this remains a P3 texture-density difference. Focused `input_check.tscn`, Forward+ capture and `git diff --check` pass.

Final result:
passed

### Iteration 87 (complete preparation-motion regression)

- Four same-state Forward+ contact captures were regenerated after the layout/material passes: station response, cup topping bounce, context-card reveal and next-action transition. Combined evidence: `design/mockups/coral_mint/full-set-v3/qa/animation/00-motion-contact-grid-region86-final.png`.
- Each cue remains scoped to one gameplay meaning: station art confirms the selected work area, cup motion confirms ingredient transfer, card fade explains choice-set replacement, and the bottom bar marks the next step. None is a perpetual loop; reduced-motion gates remain in the shared runtime paths.
- The grid confirms customer, station, workbench, pickup and bottom-action geometry stay fixed across all four contact states. The full input suite continues to cover base → milk → topping → sugar → shake → seal → review/deliver, wrong-order loss, pointer/touch/keyboard/gamepad paths and reduced-motion settling.

Final result:
passed

### Iteration 88 (front-counter fascia alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region88-final.png`. The equal-coordinate lower-counter crop is `qa/regions/20-front-counter-comparison-region88-final.png`; the full pair is `qa/regions/00-full-comparison-region88-final.png`.
- Earlier P2: the cream rail and mint inset projected about 20px below the reference, while the inset used a much brighter emerald material. The existing Blender export geometry was raised once at the shared source, and the inset now owns one matte grey-blue mint material instead of mutating the station mint used elsewhere.
- Post-fix evidence puts the rail and inset within roughly 5px of the reference baselines while preserving the real 3D counter depth, lighting and lower action-bar clearance. No screen-space patch or duplicate interaction layer was added.

Final result:
passed

### Iteration 89 (late-game ingredient-panel confinement)

- Pressure state: zh_CN, Day 10, three live customers and nine unlocked toppings. Before/after evidence is `design/mockups/coral_mint/full-set-v3/qa/regions/21-day10-high-choice-comparison-region89-final.png`.
- Earlier P1: the shared four-column cap forced nine 100px ingredient cards into three rows, growing the choice panel over the cup, order ticket and lower counter. The shared layout function now keeps the reference's 320×132 shell for ordinary one-to-three-choice states and expands later unlock sets horizontally on the same y=230 baseline.
- The final nine-choice state keeps every real ingredient visible in one row while leaving the cup, active ticket, pickup tray, customers and bottom action bar readable. Existing card reveal stagger, focus, keyboard shortcuts, touch targets and reduced-motion behavior are unchanged.
- Verification: `input_check.tscn` asserts the nine-column confinement and passed the complete preparation/delivery flow; the full 25/25 core suite, Forward+ mobile pressure (61 meshes / 12,884 triangles) and `git diff --check` also pass.

Final result:
passed

### Iteration 90 (rear-cabinet structural correction)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region90-final.png`. Focused evidence: `qa/regions/22-rear-cabinet-comparison-region90-final.png`.
- A same-coordinate crop disproved Iteration 82's cabinet reading: the source keeps tea/milk outside and encloses toppings/sugar. The existing transparent cabinet moved from x=298 to x=550 and was calibrated to 608×258, placing its visible left/right bounds at approximately x=568/1155 versus the source's x=570/1159.
- The correction changes only the decorative, pointer-ignoring cabinet layer; every live station hotspot and selection handler remains in place.

Final result:
passed

### Iteration 93 (sugar and shaker subregion alignment)

- Equal-coordinate evidence: `design/mockups/coral_mint/full-set-v3/qa/regions/25-sugar-shaker-comparison-region93-final.png`; full pair: `qa/regions/00-full-comparison-region93-final.png`.
- The four sugar pumps were narrowed, moved into the corrected cabinet and lowered to the source baseline. Their labels now use the source's cream-paper treatment, 52px width and measured spacing instead of coral primary-action styling.
- The shaker renderer and label were moved independently until cap, body and tag centerlines matched the source. Its existing three-beat feedback and reduced-motion gate are unchanged.

Final result:
passed

### Iteration 96 (topping cabinet internal alignment)

- Focused evidence: `design/mockups/coral_mint/full-set-v3/qa/regions/27-toppings-comparison-region96-final.png`; full pair: `qa/regions/00-full-comparison-region96-final.png`.
- The topping art was reduced from 292×154 to 278×140 and moved to `(575,92)`, aligning all three front-bin edges, rear jars and the `小料` sign inside the corrected cabinet rather than touching its upper rail.
- A trial work-mat extension was rejected by the required equal-coordinate crop and fully reverted before this iteration: the original mat already matched the source, while the apparent 120px gap was the surrounding wood counter.

Final result:
passed

### Iteration 101 (order-ticket paper/content calibration)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region101-final.png`. Focused evidence: `qa/regions/32-order-ticket-comparison-region101-final.png`; full pair: `qa/regions/00-full-comparison-region101-final.png`.
- The ticket now matches the source's paper-stack width and top/bottom baselines without stretching its live drink preview: the control uses independent x/y calibration while the background alone receives the remaining horizontal paper-width compensation.
- The active customer's real drink art, localized name and ticket synchronization remain live. Focused `input_check.tscn` passes after the final geometry trim.

Final result:
passed

### Iteration 105 (reset-sign asset and silhouette correction)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/source-reset-sign-original.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region105-final.png`. Equal-coordinate evidence: `qa/regions/36-reset-sign-comparison-region105-final.png`; full pair: `qa/regions/00-full-comparison-region105-final.png`.
- Coordinate-only trials were rejected because the old square asset's board and rear brace remained offset after its outer bounds aligned. Built-in ImageGen rebuilt a near-front, blank-board A-frame from the source crop, then a focused proportion pass widened/shortened the board; a separate extraction pass produced verified real alpha.
- The selected `ui-sign-reset-front-v3.png` is placed at 161×203 with a restrained -0.06 rad lean and horizontal presentation flip. Its visible outer bounds finish within roughly 2px of the source while the live localized reset/waste text, Button hit target, tooltip and disabled behavior remain unchanged.

Final result:
passed

### Iteration 121 (pickup handoff same-coordinate alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region121-final.png`. Equal-coordinate evidence: `qa/regions/37-pickup-handoff-comparison-region121-final.png` and `qa/regions/38-pickup-arrow-comparison-region121-final.png`; full pair: `qa/regions/00-full-comparison-region121-final.png`.
- The live tray keeps its two real GLB meshes, but its authored rear edge now widens 10% with a 0.013 world-unit offset; the calibrated runtime scale/shear puts its outer and inset edges within roughly 0–8px of the source across the full depth.
- Built-in ImageGen rebuilt the arrow as a lower-left head plus five rounded mint dashes, removed highlights, and extracted true alpha. The high-resolution master is `assets-transparent/ui/ui-arrow-pickup-v3.png`; the runtime copy is resized to its actual 195×125 slot at `(829,305)`, preserving the same visible bounds without retaining a 1672×941 texture in memory or intercepting pointer input.
- The real 3D service bell is independently calibrated to `(1.38,1.02,1.39)` and `(2.30,2.55,2.30)`, matching the source bell center, base and button while leaving the already-aligned tray and pickup tag untouched.
- Delivery remains functional: the sealed-state capture is `qa/regions/39-pickup-sealed-region120-final.png`; correct service uses the existing customer-to-pickup exit animation, while reduced-motion takes the static branch. Input and model checks pass; Forward Mobile passes at 61 meshes / 12,884 triangles / 151.77 MiB, and `git diff --check` is clean.

Final result:
passed

### Iteration 125 (customer lane and front-fascia alignment)

- The comparison state now matches the reference's two-customer preparation scene instead of relying on the default one-customer spawn timing. Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region125-final.png`; equal-coordinate customer evidence: `qa/regions/40-customer-order-comparison-region125-final.png`.
- Both visible customer portraits were calibrated independently. The mint customer uses `(0.55,0.48)` at x=185 and the yellow customer `(0.418,0.451)` at x=184; their head, feet and left/right silhouette bounds now land within roughly 0–3px of the source while preserving the fixed live order-card controls.
- The earlier front fascia spanned into the customer lane from x≈0. Its existing real Blender boxes were shortened and right-anchored: the cream fascia now begins around x=205 and the mint inset around x=330, matching `qa/regions/41-front-fascia-comparison-region125-final.png` without adding a screen-space patch. Runtime shop geometry remains 22 meshes / 3,784 triangles.
- Motion root fix: visible customers are 2D portrait sprites while the previous departure tween only moved their hidden 3D actors. The real portrait now receives a short arrival slide/fade and served/angry directional exit; reduced motion still removes it immediately. `input_check.tscn` pins the visible served departure lifecycle.
- Verification: focused input and model checks pass; Forward Mobile passes at 61 meshes / 12,884 triangles / 152.31 MiB, and `git diff --check` is clean.

Final result:
passed

### Iteration 136 (entrance floor and reset-sign material alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region136-final.png`. Both are 1280×720 pixels at the authored 1280×720 viewport and density 1. Full evidence: `qa/regions/00-full-comparison-region136-final.png`; focused evidence: `qa/regions/43-entrance-floor-comparison-region136-final.png` and `qa/regions/42-reset-sign-comparison-region136-final.png`.
- Earlier P1 layout/material finding: the entrance floor mixed a beige plane, mint quadrilateral and triangular stipple instead of the source's continuous cool-grey planks. The mint/triangle pieces were traced to obsolete `SignFrame`/`SignBoard` meshes duplicated underneath the live reset button and removed from the shared Blender runtime export. A built-in ImageGen material pass produced `background-floor-greige-v1.png`; the 512×512 runtime albedo reuses the real 3D floor and preserves scene shadows.
- Color verification samples the same unobstructed floor rectangle: source averages RGB `(195.62,184.62,177.43)` and runtime `(194.55,184.32,177.28)`. Plank spacing, horizontal seams and matte grain now match; the generated material master and final prompt are recorded in `assets-transparent/background/README.md`.
- Earlier P2 image-quality finding: the reset sign's orange glossy rails caused the oily look even after its bounds aligned. Built-in ImageGen rebuilt the frame as pale matte cream wood; black-background extraction produced true-alpha `ui-sign-reset-front-v4.png`. The live Button remains localized and clickable, with its outer sign bounds within roughly 0–4px of the reference and an enlarged readable reset-cost label.
- Typography/copy, spacing, coral/mint tokens, source image assets, pointer behavior and reduced-motion behavior remain intact. Residual inner-board proportion drift is P3 and does not affect the live hit target or copy. Input and model checks pass; the runtime shop is 22 meshes / 3,760 triangles, Forward Mobile passes at 61 meshes / 12,860 triangles / 146.88 MiB, and `git diff --check` is clean.

Final result:
passed

### Iteration 140 (entry railing and succulent handoff)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region140-final.png`, both at 1280×720 and density 1. Focused equal-coordinate evidence: `qa/regions/44-succulent-railing-comparison-region140-final.png`; full pair: `qa/regions/00-full-comparison-region140-final.png`.
- Earlier P2 structural gap: the source's entry handrail, muted-teal side panel and potted succulent were absent behind the reset sign. Built-in ImageGen generated two true-alpha props from the measured source crops: `background-entry-railing-v1.png` and `background-succulent-v1.png`. The railing's second pass preserves the source's unusual post spacing and is gently desaturated to its matte pale-oak palette.
- Layering is explicit and non-interactive: the succulent stays behind customers and sign, the railing is z=1 in front of customers/plant, and the live A-frame Button is z=2. The final crop aligns the plant crown, rail diagonal, three post centers and sign overlap; the remaining rail-shaft thickness difference is P3.
- Verification: `input_check.tscn` and `model_asset_check.tscn` pass; Forward Mobile passes at 61 meshes / 12,860 triangles / 176 maximum draw calls / 146.73 MiB, and `git diff --check` is clean.

Final result:
passed

### Iteration 142 (yellow-customer waiting-pose alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/source-yellow-customer-original.png` and the full `reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region142-final.png`, all normalized to the authored 1280×720 viewport at density 1. Focused equal-coordinate evidence: `qa/regions/45-yellow-customer-comparison-region142-final.png`; full evidence: `qa/regions/00-full-comparison-region142-final.png`.
- Earlier P1 image/pose mismatch: the second customer used a cheering sprite with both arms raised, open mouth and a diagonal body, contradicting the source's calm waiting silhouette and breaking the railing overlap. Built-in ImageGen reconstructed a matte, neutral waiting pose from the source crop; a dedicated extraction pass produced verified real alpha. The selected master is `assets-transparent/character-yellow-customer-waiting-v1.png`, with a 270×512 runtime copy.
- The runtime sprite uses independent `(0.51,0.49)` calibration at `(173,434)` for the second slot. Head top/width, body center, foot baseline and right-side railing occlusion now match the source crop; the visible left hand remains approximately 10px high and is classified P3 because the overall waiting gesture, hit-free decorative layer and silhouette are correct.
- The existing arrival and served/angry departure tweens continue to act on the real visible portrait, including the reduced-motion branch. `input_check.tscn`, `model_asset_check.tscn`, Forward Mobile (61 meshes / 12,860 triangles / 176 maximum draw calls / 146.84 MiB) and `git diff --check` pass.

Final result:
passed

### Iteration 149 (topping hold state and explicit sugar advance)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region149-final.png`, both 1280×720 at density 1. Equal-coordinate evidence: `qa/regions/46-topping-next-action-comparison-region149-final.png`; full evidence: `qa/regions/00-full-comparison-region149-final.png`.
- Earlier P1 behavior/state mismatch: selecting the requested topping immediately replaced the three-card topping chooser with sugar controls, while the source keeps toppings visible and changes the bottom action to `下一步：糖度`. The cup now holds that state until the player activates the real bottom Button; the action is pointer-clickable, focusable, reachable from every topping card by D-pad, available through the existing number-shortcut list, and preserves reduced-motion behavior.
- Earlier P2 content/layout drift: Day 1 exposed only two topping cards. Pudding now joins boba and coconut jelly on Day 1, restoring the source's three 90px cards and 320px panel. Campaign strategy still passes at S grade across all 14 simulated days.
- Earlier P2 color/copy drift: selected tiles used a solid coral fill and keyboard labels leaked `1/2/3` into the card faces. Built-in ImageGen produced real-alpha `ui-button-selected-frame-v1.png`, a blank cream nine-slice skin with the source's strong coral double outline. Card faces now show only ingredient names, while keyboard shortcuts remain active; icon slots were enlarged to match the source bowls.
- Fidelity surfaces: font family/weight and centered labels remain shared with the existing theme; panel/card/button spacing and baselines align in the focused crop; mint/coral/cream tokens and selected-state contrast match; generated frame alpha has no halo or content-area decoration; copy is now `选择小料` and `下一步：糖度` in the exact source state. Remaining P3: the runtime bowl illustrations are slightly simpler than the painted source bowls.
- Verification: `input_check.tscn` covers the held topping state, focus reachability and explicit transition; localization and 14-day strategy checks pass; Forward Mobile passes at 61 meshes / 12,860 triangles / 176 maximum draw calls / 146.22 MiB; `git diff --check` is clean.

Final result:
passed

### Iteration 150 (central counter wood material alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region150-final.png`, both 1280×720 at density 1. Focused equal-coordinate evidence: `qa/regions/50-central-wood-comparison-region150-final.png`; full evidence: `qa/regions/00-full-comparison-region150-final.png`.
- Earlier P1 material mismatch: the central counter used the packed raw wood diffuse under warm scene lighting, producing a saturated orange slab unlike the source's matte, low-saturation greige oak. The existing Blender hue node was not a valid fix because glTF does not preserve that unsupported shader graph.
- The export now swaps only `fine_grained_wood` for the baked source texture `assets_src/textures/shop_counter_wood_cool.jpg`; counters, lighting, UI, customers and other aligned materials remain untouched. The same unobstructed 30×30 sample moved from `#c39761` to `#c7a788`, against source `#caaa8f`.
- Fidelity surfaces: grain remains real raster detail rather than a flat color; the counter keeps its original UVs, roughness, geometry and shadows; the focused pair verifies color, edge contrast and surrounding coral/mint/cream relationships together. Remaining P2 within this region is plank direction/seam spacing, which will be handled as geometry/UV alignment rather than another color change.
- Verification: `input_check.tscn`, `model_asset_check.tscn` and Forward Mobile pass; runtime shop remains 22 meshes / 3,760 triangles, the Mobile stress scene is 61 meshes / 12,860 triangles, and `git diff --check` is clean.

Final result:
passed

### Iteration 151 (central counter plank direction and seams)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region151-final.png`, both 1280×720 at density 1 and captured in the same selected-boba / `下一步：糖度` state. Focused equal-coordinate evidence: `qa/regions/53-counter-planks-comparison-region151-final.png`; full evidence: `qa/regions/00-full-comparison-region151-final.png`.
- Earlier P2 texture/structure drift: the calibrated wood still read as one uninterrupted slab with screen-horizontal streaks, while the source uses long front-to-back boards with narrow perspective seams. The baked wood raster is rotated into the source direction, and the single top slab is exported as four contiguous real 3D planks separated by three 0.006-unit grooves.
- The visible first seam lands at the same left work-surface division as the source and keeps a continuous perspective line without a screen-space overlay. A rejected rounded-plank draft raised the shop from 3,760 to 4,180 triangles; the accepted square-edge version is 3,796 triangles and retains one batched wood surface.
- Fidelity surfaces: typography and copy are unchanged and the comparison state is now exact; panel/workmat spacing is unchanged; wood color remains within `#c6a786` versus source `#caaa8f`; the real raster grain stays sharp with no alpha/compression halo; selected topping, arrow and bottom action remain live. Remaining grain-frequency variation is P3.
- Verification: `input_check.tscn` and `model_asset_check.tscn` pass; Forward Mobile passes at 61 meshes / 12,896 triangles, and `git diff --check` is clean.

Final result:
passed

### Iteration 152 (live topping cup cleanup)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against `design/mockups/coral_mint/full-set-v3/00-current-implementation-region152-final.png`, both 1280×720 at density 1 in the same selected-boba / `下一步：糖度` state. Focused evidence: `qa/regions/57-cup-ticket-wide-comparison-region152-final.png`; full evidence: `qa/regions/00-full-comparison-region152-final.png`.
- Earlier P2 image-quality drift: `cup-topping-v1.png` had a noisy white extraction fringe, heavy multi-line rim, high liquid highlight and oversized dense pearls. Built-in ImageGen used the isolated source cup and live transparent sprite to rebuild `assets-transparent/cup/cup-topping-v2.png`; the 296×332 runtime copy keeps the previously aligned outer bounds while using a clean alpha edge, thinner rim, softer/lower liquid and smaller pearls.
- The accepted cup remains exactly inside the existing 140×160 live `TextureRect`; no workmat, order, arrow or interaction geometry moved. Pearl count remains a P3 density difference, but particle scale, cup silhouette, liquid palette and edge cleanliness now match the reference direction.
- A blank ticket-stack replacement was also generated and compared. It reduced the pin/glow but lengthened the front sheet and broke the previously accepted paper baseline, so it was rejected to `qa/rejected/region152-ticket/` and the existing runtime ticket asset was restored. The final evidence therefore changes only the cup root asset.
- Fidelity surfaces: typography/copy and live ticket content are unchanged; workbench spacing and dashed guide ring remain fixed; the cup's cream/caramel/black palette is less saturated; final alpha is genuine with no halo or stray pixels; selected topping, order synchronization, bottom action and cup bounce/shake states remain functional.
- Verification: `input_check.tscn` and `model_asset_check.tscn` pass; Forward Mobile passes at 61 meshes / 12,896 triangles, and `git diff --check` is clean.

Final result:
passed

### Iteration 153 (prep-to-pickup motion continuity)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` against the 1280×720 mid-motion render `design/mockups/coral_mint/full-set-v3/00-current-implementation-region153-handoff.png`. Focused equal-coordinate evidence is `qa/regions/58-cup-handoff-comparison-region153-final.png`; the full pair is `qa/regions/00-full-comparison-region153-handoff.png`.
- Earlier P1 feedback gaps: changing a second topping and confirming sugar could leave the cup visually still because the artwork state did not change. Those actions now reuse the existing restrained cup bounce/compression cues; shake and seal retain their existing stage and cup motion, sound and haptics.
- Earlier P1 delivery discontinuity: a correct sealed drink disappeared from the workmat before the customer exit/reward cue. A duplicate of the real sealed-cup asset now follows a 360ms, two-segment shrink-and-fade path from the live cup through the order/pickup gap. It is inserted beside the cup layer so the ingredient chooser remains legible and ends small enough not to obscure the bell or tray.
- Accessibility and behavior: the handoff is feedback-only, pointer-ignoring and never delays scoring, customer removal or cup reset. Enabling reduced motion kills and removes an in-flight handoff immediately; the focused input check pins both the sealed texture and reduced-motion cleanup.
- Verification: `input_check.tscn`, `model_asset_check.tscn` and `autoplay.tscn` pass. Forward Mobile remains at 61 meshes / 12,896 triangles with a 9.232ms average process time, and `git diff --check` is clean.

Final result:
passed

### Iteration 154 (three-customer queue safe-frame alignment)

- Visual truth: the Day 1 source `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with the Day 9 three-order pressure render `design/mockups/coral_mint/full-set-v3/00-current-implementation-region154-pressure-final.png`, both at 1280×720 and density 1. The first two source-backed queue slots are paired in `qa/regions/59-customer-queue-comparison-region154-final.png`; the pressure-only third slot is proven by `qa/regions/60-third-customer-before-after-region154-final.png`; full context is `qa/regions/00-full-comparison-region154-pressure-final.png`.
- Earlier P2 layout/crop drift: the third mint portrait retained the first two slots' vertical interval and ended at authored y=743, leaving about 23px outside the frame. The third slot center moves from y=620 to y=596, preserving its source-matched x position, scale, art, order-card geometry and layer order while bringing the complete portrait to y=719.
- Fidelity surfaces: the first two portrait head tops, widths and card coordinates remain aligned with the source; the third card stays at the same 210px queue rhythm. Typography, drink copy, coral/mint/cream tokens, raster sharpness and customer artwork are unchanged. The extra third order and eight unlocked topping choices are intentional Day 9 gameplay content absent from the Day 1 source, not a source-state substitution.
- Behavior/accessibility: arrival and served/angry departure tweens still act on the real portrait; pointer, touch, gamepad order selection and card numbering are unchanged. `mobile_render_check.tscn` now fails if any of the three live portrait texture bounds crosses the 720px authored safe frame.
- Verification: `input_check.tscn` and Forward Mobile pass; the pressure scene remains at 61 meshes / 12,896 triangles with a 9.437ms average process time, and `git diff --check` is clean.

Final result:
passed

### Iteration 155 (late-game osmanthus icon completion)

- Visual truth: the source topping-card family in `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with the Day 10 nine-choice render `design/mockups/coral_mint/full-set-v3/00-current-implementation-region155-late-choice-final.png`, both 1280×720 at density 1. Exact before/after evidence is `qa/regions/61-osmanthus-before-after-region155-final.png`; family comparison is `qa/regions/62-topping-icon-family-comparison-region155-final.png`; full context is `qa/regions/00-full-comparison-region155-late-choice-final.png`.
- Earlier P1 image-quality mismatch: the final unlocked topping displayed an unfinished black-outlined white oval with a cap, unlike every painted ingredient bowl. Built-in ImageGen produced real honey-gold osmanthus jelly and flower flecks in the existing cream bowl language; the accepted solid-background pass was locally matted, contrast-checked and normalized to the adjacent 128×128 icons.
- The prior nine-column, y=230 layout remains intentional: it keeps all live choices visible and keyboard-addressable in one row without covering the cup, ticket or pickup tray. A three-card pager was rejected because it would add hidden state and extra touch/gamepad actions to the core timed loop.
- Fidelity surfaces: the new sprite matches the source family's soft painted lighting, cream ceramic, centered subject, transparent padding and low-saturation palette; card typography, 8px rhythm, mint/coral tokens and localized `桂花冻` copy are unchanged. The data-driven `icon` field selects v3 consistently in day choices, order progress and the night recipe lab while preserving id-based fallback for every existing ingredient.
- Accessibility/verification: the icon remains decorative inside the semantic Button; pointer, touch, focus, tooltip and number-key behavior are unchanged. `input_check.tscn` pins the final transparent corner, `night_check.tscn` passes, Forward Mobile remains at 61 meshes / 12,896 triangles with a 9.193ms average process time, and `git diff --check` is clean.

Final result:
passed

### Iteration 156 (late-game topping optical alignment)

- Visual truth: the Day 1 topping family in `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with the Day 10 nine-choice render `design/mockups/coral_mint/full-set-v3/00-current-implementation-region156-topping-alignment-final.png`, both 1280×720 at density 1. Full evidence is `qa/regions/00-full-comparison-region156-topping-alignment-final.png`; focused reference/implementation evidence is `qa/regions/64-topping-reference-implementation-region156-final.png`.
- Earlier P2 image/spacing finding: the first eight runtime topping PNGs already shared the exact `(12,30)–(110,107)` visible box, but the osmanthus art occupied `(12,33)–(116,102)`. It therefore read wider, 8px shorter and 5px above the common bowl baseline even though every card used the same 76×72 slot.
- The source-backed transparent master was resampled once into the existing runtime file at the family's exact 98×77px optical box. The before/after pair `qa/regions/63-topping-before-after-region156-final.png` verifies the corrected bowl rim, subject height and lower edge while leaving the already-aligned eight sprites unchanged.
- Fidelity surfaces: the shared font, 15px labels and localized copy are unchanged; panel/card spacing, cream paper and mint/coral tokens still reuse the accepted source skins; the real painted PNG keeps soft edges and transparent corners; the selected first card continues to use the source's strong double-coral frame, with pointer, touch, focus, tooltip and number-key behavior intact. The nine-item width is intentional unlocked Day 10 content; the source's three-item Day 1 width remains unchanged.
- Verification: `input_check.tscn` pins the final raw-PNG optical bounds and passes the preparation flow; Forward Mobile passes at 61 meshes / 12,896 triangles with an 8.407ms average process time; `git diff --check` is clean. No actionable P0/P1/P2 findings remain in this region.

Final result:
passed

### Iteration 157 (workmat and cup-guide alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region157-workmat-final.png`, both 1280×720 at density 1. Equal-coordinate evidence is `qa/regions/65-workmat-reference-implementation-region157-final.png`; before/after evidence is `qa/regions/66-workmat-before-after-region157-final.png`; the full pair is `qa/regions/00-full-comparison-region157-workmat-final.png`.
- Earlier P2 layout finding: the workmat's width matched, but its front-to-back projection was about 20px too shallow, leaving the top edge below the source and making the cup guide read small and high. The cup, ticket and pickup tray were already close, so moving that whole cluster would have broken accepted alignment.
- The existing real 3D `prep_mat.glb` is now presented at `(4.00,4.00,4.60)` with its depth anchor adjusted from z=0.98 to z=0.92. The merged mint guide mesh is independently calibrated inside that prop, matching the source oval's center, width and lower baseline without moving the live cup or ticket.
- Fidelity surfaces: typography, localized copy and all UI controls are unchanged; the mat's cream/wood/mint materials remain the existing source family; the real mesh keeps perspective, shadows and beveled edges rather than adding a screen-space patch; cup and ticket PNG quality is unchanged. The focused crop leaves only a P3 difference in individual dash thickness and the late-game nine-card panel remains intentional content.
- Verification: `input_check.tscn` pins the final mat and guide proportions and passes the full preparation path; Forward Mobile passes at 61 meshes / 12,896 triangles with an 8.841ms average process time; `git diff --check` is clean. No actionable P0/P1/P2 findings remain in this region.

Final result:
passed

### Iteration 158 (context-choice motion hierarchy)

- Visual truth: the stable Day 10 implementation is `design/mockups/coral_mint/full-set-v3/00-current-implementation-region158-context-motion-final.png`, compared with the 1280×720 density-1 source `qa/regions/reference-1280x720.png` in `qa/regions/00-full-comparison-region158-context-motion-final.png`. Motion evidence is `qa/animation/context-stage-reveal-region158-final.png`; the focused stable/stage-entry pair is `qa/animation/67-context-repeat-vs-stage-reveal-region158-final.png`.
- Earlier P2 behavior finding: every topping selection rebuilt the nine live buttons and replayed their staggered fade, even though the choice set had not changed. The full panel repeatedly dimmed during the timed core loop, competing with the selected coral frame and cup response instead of confirming the chosen ingredient.
- The refresh path now reuses the shop stage's existing active ingredient kind. Same-stage updates—selection changes, readiness copy, focus/input prompts and locale refreshes—rebuild instantly at full opacity; only real base → milk → topping → sugar replacement sets receive the existing 25ms stagger and 120ms fade. Reduced motion still skips both paths.
- Fidelity surfaces: card typography, localized copy, panel/card spacing, mint/coral/cream tokens and all real ingredient PNGs are unchanged; the source-backed selected double-coral frame remains the static confirmation surface. Pointer, touch, keyboard/gamepad focus, numeric shortcuts, next-step navigation, cup bounce, sound and haptics remain intact. The source is static, so motion fidelity is classified by hierarchy and continuity rather than invented source timing.
- Verification: `input_check.tscn` asserts that a repeated topping refresh starts fully opaque while the topping → sugar transition starts at alpha 0; the 25/25 core suite, a real newbie autoplay day, and Forward Mobile (61 meshes / 12,896 triangles / 9.157ms average process time) pass. `git diff --check` is clean and no actionable P0/P1/P2 finding remains in this interaction region.

Final result:
passed

### Iteration 159 (three-customer pressure-lane separation)

- Visual truth: the two-customer source is `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png`; the intentional Day 10 three-customer pressure state is `design/mockups/coral_mint/full-set-v3/00-current-implementation-region159-customer-pressure-final.png`, both 1280×720 at density 1. Equal-coordinate lane evidence is `qa/regions/69-customer-reference-pressure-region159-final.png`; exact pressure-state before/after evidence is `qa/regions/68-customer-pressure-before-after-region159-final.png`; full context is `qa/regions/00-full-comparison-region159-customer-pressure-final.png`.
- Earlier P2 layout/imagery finding: the first two source-backed portraits remained aligned, but the extra third mint portrait reused the 0.55×0.48 foreground scale at y=596. Its real alpha silhouette began at y=479.36 while the second yellow portrait ended at y=556.99, producing 77.63px of opaque overlap and covering the second customer's legs and the third customer's face.
- Only slot 3 changes. It now uses a restrained rear-waiting presentation: mint `(0.46,0.40)` at y=628 and yellow `(0.39,0.37)` at y=625. In the captured mint pressure state its visible range is y=530.8–717.2, reducing overlap to 26.19px while preserving a small depth cue, the full face, feet and the source's shared vertical lane. Slot 1/2 positions, scales, order cards, rail and reset-sign occlusion remain unchanged.
- Fidelity surfaces: customer and order-card typography/copy are unchanged; the first two portrait bounds still match the source; real transparent painterly assets, mint/yellow/coral tokens and edge quality are preserved; the third card remains the intentional gameplay-only pressure item absent from the Day 1 source. Arrival, served/angry departure, pointer order selection, focus and promotion review still operate on the same live portrait nodes.
- Verification: `mobile_render_check.tscn` now measures alpha-visible portrait bounds, fails above 720px, and caps slot-2/slot-3 visible overlap at 30px. Focused input and a full newbie autoplay day pass; Forward Mobile passes at 61 meshes / 12,896 triangles / 9.974ms average process time, and `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this pressure-lane region.

Final result:
passed

### Iteration 160 (Day 1 workbench projection alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region160-workbench-final.png`, both 1280×720 at density 1 in the exact same Day 1 state: two customers, three topping cards, selected boba and `下一步：糖度`. Equal-coordinate evidence is `qa/regions/region160/75-workbench-day1-final.png`; full context is `qa/regions/00-full-comparison-region160-workbench-final.png`.
- The strict same-state crop exposed a P2 projection error hidden by the earlier late-game comparison: the workmat top began near y=337 instead of the source's y=356, while the independently placed order ticket was already aligned. The real 3D mat now uses `(4.00,4.00,3.93)` at z=0.97, bringing its top and side edges within about 1–2px of the source without moving the ticket or pickup tray.
- The imported mint guide is rotated 90° around Y, so its visible depth is controlled by local X. Compensating that real transform with local scale `(0.91,1.00,1.01)` and z offset `+0.026` produces a measured teal envelope of `(483,397)–(678,523)` against source `(483,400)–(676,527)`. The live cup baseline moves from y=365 to y=359, placing its center within about 2px of the reference.
- Fidelity surfaces: typography and localized copy are unchanged; topping panel, ticket, customer cards and pickup spacing remain fixed; cream/wood/mint materials remain the accepted real assets; the 3D mat keeps native perspective, bevels and shadows; the live cup, selection, explicit sugar advance, bounce, shake and handoff behavior remain functional. Remaining dash-thickness and cup-paint differences are P3 imagery differences, not layout drift.
- Verification: the focused input check pins the final real mesh transforms; the 25/25 core suite, a full newbie autoplay day and Forward Mobile pass at 61 meshes / 12,896 triangles / 176 maximum draw calls / 146.09 MiB. `git diff --check` is clean.

Final result:
passed

### Iteration 161 (Day 1 rear tea-and-milk station alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region161-rear-stations-final.png`, both 1280×720 at density 1 in the same Day 1 selected-boba / `下一步：糖度` state. Focused evidence is `qa/regions/region161/79-tea-milk-day1-final.png`; the full five-station strip is `qa/regions/region161/80-rear-stations-day1-final.png`; full context is `qa/regions/00-full-comparison-region161-rear-stations-final.png`.
- Earlier P2 proportion finding: the tea/milk art shared the correct lower baseline but was presented at 225×158 from y=76, stretching the kettle and carton roughly 35–40px above the source. The neighboring topping, sugar and shaker stations were already source-aligned and therefore remain untouched.
- The existing real transparent asset now renders at `(333,104,225,128)`. The coral kettle mask moves from `(343,79)–(433,204)` to `(349,106)–(439,208)`, against source `(350,106)–(437,209)`; the milk cow mark moves from `(486,163)–(515,193)` to `(492,175)–(521,199)`, against source `(492,175)–(520,199)`. No replacement image or approximate code drawing was introduced.
- The live tea and milk Buttons were calibrated independently rather than moving the whole rear band. Tea now occupies the exact sampled coral envelope `(356,220)–(435,254)`; milk is `(477,220)–(548,254)` against source `(477,219)–(548,253)`. Their larger real hit areas preserve the source silhouette while improving pointer/touch reachability.
- Fidelity surfaces: the WenKai typography and station copy stay localized and centered; tea/milk prop, base and tag spacing now match the source rhythm; coral/mint/cream tokens and painterly alpha assets are unchanged; no halo, crop or placeholder was introduced; the tea tag still toggles the real batch panel and the preparation flow remains keyboard/gamepad/touch reachable. Remaining station-art brush-detail differences are P3.
- Verification: `input_check.tscn` pins the final art frame; the sequential 25/25 core suite passes. Forward Mobile passes at 61 meshes / 12,896 triangles / 176 maximum draw calls / 146.16 MiB, and `git diff --check` is clean.

Final result:
passed

### Iteration 162 (Day 1 left queue and order-card alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region162-customer-final.png`, both 1280×720 at density 1 in the same Day 1 two-customer selected-boba state. Equal-coordinate evidence is `qa/regions/region162/89-left-queue-day1-final.png`; full context is `qa/regions/00-full-comparison-region162-customer-final.png`.
- Earlier P2 imagery/layout finding: the generated mint portrait was visibly wider through the head but narrower and shorter through the sweater, while the yellow portrait was roughly 20px too high/tall. The order cards were close but began 2px left and ended 2–4px short of the source frame.
- The selected genuine-alpha mint v3 master is stored at `assets-transparent/character-mint-customer-v3.png` and its 512px runtime copy at `game/assets/ui/full_set_v3/illustrations/character-mint-customer-v3.png`. Built-in ImageGen created the full-body matte mint-bob/lavender-sweater customer and a broader, longer-sweater revision; built-in background-removal/edit mode produced the alpha master. A later glossy/glow-heavy revision was rejected. The final first portrait uses `(195,221.5)` at `(0.515,0.5035)`; the yellow portrait uses `(175,447)` at `(0.538,0.452)`.
- The source-backed final crop aligns both head tops, horizontal centers and foot baselines within about 0–3px. The order cards now begin at x=18 and use a 108×134 authored frame, matching the source outer bounds without moving the 32px numbered badges or altering the live drink, name and patience-dot content.
- Fidelity surfaces: WenKai drink names and localized copy remain live; card/portrait spacing and queue rhythm now match the same-coordinate source; mint/lavender/yellow/coral/cream tokens stay within the accepted family; only real transparent raster art is used; pointer/touch/gamepad selection, arrival/exit tweens, promotion and reduced-motion paths still target the same portrait and card nodes. Remaining face/brush-model differences are P3 imagery differences.
- Verification: the sequential 25/25 core suite passes after one isolated onboarding timing retry; a full newbie Day 1 autoplay passes at 100% serve rate; Forward Mobile passes at 61 meshes / 12,896 triangles / 176 maximum draw calls / 146.16 MiB and validates all three alpha-visible portrait bounds. `git diff --check` is clean.

Final result:
passed

### Iteration 163 (Day 1 front-counter fascia and deck alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region163-counter-final.png`, both 1280×720 at density 1 in the same Day 1 two-customer selected-boba state. Equal-coordinate evidence is `qa/regions/region163/96-lower-counter-day1-final.png`; full context is `qa/regions/00-full-comparison-region163-counter-final.png`.
- Earlier P1 structural finding: the runtime export added one cream block centered at x=1.05 and a narrower dark-teal inset centered at x=1.25. The pair covered only the right side of the shop, turned the lower third into a heavy rectangular slab, and omitted the reference's shallow wood deck. The pickup tray, service bell and `取餐` tag were already aligned, so they remain untouched.
- The export now authors the source's full-width three-layer rhythm on one front plane: a cream lip at `(-0.675,-1.25,0.57)` / `(4.75,0.12,0.18)`, a muted mint band at `(-0.675,-1.32,0.36)` / `(4.71,0.035,0.24)`, a shallow wood sill, and a horizontal wood deck at `(-0.675,-1.35,0.04)` / `(4.79,0.32,0.08)`. The deck supplies the missing perspective depth instead of stretching a vertical panel below the floor plane.
- Post-fix evidence puts the cream/mint boundary and mint/wood boundary within about 0–5px of the source; the deck's near edge is within about 4px and the right extent within about 10px. The old right-heavy dark rectangle is gone. Remaining source curvature and subtle wood-grain density are P3 asset-detail differences.
- Fidelity surfaces: typography and localized copy are unchanged; lower-counter spacing and layer rhythm now match the source; cream, muted mint and warm wood tokens replace the blue-black slab; the real Blender meshes retain bevels, perspective and native lighting; drink art, pickup assets and copy remain live. The rebuilt meshes are decorative and do not intercept pointer, touch, keyboard or gamepad input.
- Gameplay/verification: the full preparation flow, pickup and reduced-motion paths pass. A random-order flaw in `onboarding_check` was also removed: the real numeric shortcut now activates the visible next-step button when a topping order requires explicit confirmation, instead of repeatedly toggling topping 1. The onboarding path passes 5/5 consecutive runs; the sequential core suite passes 25/25; Day 1 newbie autoplay serves 11/11; the shop model passes at 23 meshes / 4,012 triangles; Forward Mobile passes at 62 meshes / 13,112 triangles / 178 maximum draw calls / 146.34 MiB. `git diff --check` is clean.

Final result:
passed

### Iteration 164 (Day 1 central worktop material alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region164-worktop-final.png`, both 1280×720 at density 1 in the same Day 1 two-customer selected-boba state. Equal-coordinate evidence is `qa/regions/region164/101-central-worktop-day1-final.png`; full context is `qa/regions/00-full-comparison-region164-worktop-final.png`.
- Earlier P1 color/image-quality finding: the four real counter planks used `shop_counter_wood_cool.jpg`, a gray-brown reclaimed texture with dense scratches and high contrast. Across the full center band it made the shop substantially darker and rougher than the reference's clean, low-contrast pale oak, even though the plank geometry and seams were already aligned.
- Built-in ImageGen produced a seamless pale-oak game-material tile from the Day 1 reference, then performed one targeted value/hue edit while preserving the tile and fine grain. The selected master is `assets-material/wood/shop-counter-wood-pale-v3-master.png`; the 1024px export source is `assets_src/textures/shop_counter_wood_pale_v3.png`. Prompt history and mode are recorded in `assets-material/wood/README.md`.
- Only the existing `fine_grained_wood` image input changes. The four authored 0.9455×0.70×0.06 planks, their seams, bevel-free shared plane, counter projection, cup, workmat, ticket, pickup tray and bell stay fixed. The final crop restores the source's light wood hierarchy without flattening the visible grain; residual hue and seam-density variation are P3.
- Fidelity surfaces: typography/copy and all controls are unchanged; worktop spacing and projection remain source-aligned; the palette moves from charcoal gray-brown to muted warm beige oak; the 1024px tile is clean, matte and free of compression, halo, vignette or fake board seams; all visible props remain real raster/3D assets. The material is interaction-neutral and keeps all pointer, touch, keyboard/gamepad, motion and reduced-motion behavior intact.
- Verification: Iteration 163's sequential 25/25 core suite and 5/5 deterministic onboarding runs cover the unchanged behavior. After the final texture swap, the model check passes at 23 meshes / 4,012 triangles and Forward Mobile passes at 62 meshes / 13,112 triangles / 178 maximum draw calls / 146.28 MiB. `git diff --check` is clean.

Final result:
passed

### Iteration 165 (Day 1 bottom primary-action alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region165-bottom-action-final.png`, both 1280×720 at density 1 in the same Day 1 two-customer selected-boba / `下一步：糖度` state. Equal-coordinate evidence is `qa/regions/region165/105-bottom-action-day1-final.png`; full context is `qa/regions/00-full-comparison-region165-bottom-action-final.png`.
- The strict crop showed that the panel's `(518,638)` position and `260×65` bounds already matched the source. The P2 mismatch was asset hierarchy: the action used the thin teal/gray secondary frame and presented the hand too lightly, making the only primary action read like a utility control.
- The panel now reuses the existing genuine-alpha `BUTTON_SELECTED_SKIN`, rendered with its stronger coral double outline at divider 3, while the existing source-backed hand slot increases from 52×52 to 56×56. Geometry, label copy, WenKai 24px typography and the live full-panel Button stay fixed. Two ImageGen frame/icon candidates were rejected after same-coordinate capture because their opaque preview canvas or changed silhouette reduced fidelity; they are isolated under `assets-transparent/ui/rejected/` and are not imported by the game.
- Fidelity surfaces: the button now restores the source's cream/coral primary hierarchy without adding gloss or gray weight; the real hand PNG retains genuine alpha and its original silhouette; no text, emoji, SVG or code-drawn substitute is used. Remaining hand-shadow and border-paint differences are P3 raster detail. Pointer, touch, keyboard/gamepad focus, numeric shortcut, disabled-state gating, pulse animation, reduced motion and haptic feedback still target the same live control.
- Verification: `input_check.tscn` passes the full preparation and accessibility/input paths; Forward Mobile passes at 62 meshes / 13,112 triangles with a 9.065ms average process time; `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 166 (Day 1 reset-sign alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region166-reset-sign-final.png`, both 1280×720 at density 1 in the same Day 1 two-customer selected-boba state. Equal-coordinate evidence is `qa/regions/region166/111-reset-sign-day1-final.png`; full context is `qa/regions/00-full-comparison-region166-reset-sign-final.png`.
- Earlier P2 visual finding: the interactive sign occupied the right envelope but its board was much darker, its frame proportions drifted, and live `重置 / 损耗 3 金币` copy replaced the source's quiet `奶茶 / 物语` brand lockup. The source silhouette spans about x=229–361 and y=509–704.
- The selected genuine-alpha v4 sign keeps its real wood geometry but receives a selective teal-only color lift as `ui-sign-reset-front-v6.png`; the control now uses `(211,525)`, rotation `-0.05` and scale `(0.92,0.86)`, placing its top, feet and horizontal center within about 0–3px of the source. Built-in ImageGen supplied the 64×64 cream cup-line master `ui-icon-sign-cup-v1.png`; its solid-black generation background was extracted to genuine alpha and it is rendered at a measured 22×22 slot below the live localized brand label.
- Fidelity surfaces: the sign's wood stays matte and cream, the board moves from blue-black teal to muted mint, and the reference brand/cup hierarchy is restored without code-drawn art. `DAY_RESET_SIGN` localizes the visible lockup; the dynamic reset/waste copy remains available through `accessibility_name` and tooltip, so the full sign is still the same live Button. Pointer/touch press, keyboard/gamepad focus, two-step destructive confirmation, disabled state and haptics are unchanged. Remaining frame-perspective and brush-texture differences are P3.
- Verification: `input_check.tscn` pins the visible brand and accessible reset name; `localization_check.tscn` passes both locales; Forward Mobile passes at 62 meshes / 13,112 triangles with a 9.520ms average process time; `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 167 (Day 1 top HUD alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region167-top-hud-final.png`, both 1280×720 at density 1 in the same Day 1 state. Equal-coordinate evidence is `qa/regions/region167/113-top-hud-day1-final.png`; full context is `qa/regions/00-full-comparison-region167-top-hud-final.png`.
- The strict crop confirmed that the three pill positions, 48–50px heights and horizontal gaps already matched. The P2 mismatch was surface hierarchy: all core metrics used the coral/teal tabbed HUD skin and glossy 40px icon slots, while the source uses quiet cream chips with a fine neutral inner line and smaller marks. The timer also used `108s`, breaking the source's compact colon rhythm.
- Day, coin and inspiration now reuse the existing cream `BUTTON_SECONDARY_SKIN` at the same 9-slice margins; icon slots reduce from 40×40 to 36×36 without moving the pill bounds. `DAY_HUD_TIME` now formats the live countdown as localized `m:ss` (`1:49` in the final capture) instead of seconds plus `s`, preserving the real countdown while matching the source's typographic structure.
- Fidelity surfaces: WenKai live labels, cocoa text, cream fill, neutral border and original genuine-alpha metric icons remain intact; no screenshot crop or code-drawn icon was introduced. Remaining icon illustration/model and subtle outer-shadow differences are P3. Tooltip semantics, late-game hidden/visible metrics, event row, upgrades, input focus and pause remain unchanged.
- Verification: `input_check.tscn` pins the colon timer format; `localization_check.tscn` passes both locales and format strings; Forward Mobile passes at 62 meshes / 13,112 triangles with a 9.700ms average process time; `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 168 (Day 1 pickup-zone color and hierarchy alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region168-pickup-final.png`, both 1280×720 at density 1 in the same Day 1 selected-boba state. Equal-coordinate evidence is `qa/regions/region168/121-pickup-zone-day1-final.png` and `qa/regions/region168/122-pickup-tray-day1-final.png`; full context is `qa/regions/00-full-comparison-region168-pickup-final.png`.
- The strict crops proved that the arrow envelope, tray projection, bell anchor and 140px pickup-tag width were already aligned within roughly 0–4px. The P2 mismatch was color/image hierarchy: arrow, tray and bell all used the global saturated gameplay mint, the inset read cold white, and the pickup tag was about 6px visually too short and brighter than the source.
- The selected genuine-alpha arrow keeps its 195×125 canvas and exact dash/head silhouette as `ui-arrow-pickup-v5.png`, with an alpha-preserving pale-mint grade. Only pickup-tray/service-bell material overrides change: `Mint/Tint_Mint #86BDB8`, `MintDark #568D89`, `Cream #F4EBDD`; the source GLBs, transforms, mesh topology and other props remain untouched. The pickup tag keeps x/y/width but grows from 50px to 56px and uses restrained coral normal/hover/pressed colors.
- Fidelity surfaces: WenKai `取餐` copy and 26px size remain live; spacing and perspective stay fixed; mint/coral/cream tokens now match the quieter source hierarchy; the arrow remains a real transparent raster and tray/bell remain real 3D meshes with native light and shadow. Remaining tray wood-grain, bell brush detail and tiny arrow hue differences are P3. The handoff animation, reduced-motion cleanup, sealed-cup delivery, tag states and all pointer/touch/keyboard/gamepad paths are unchanged.
- Verification: `input_check.tscn` pins the scoped pickup material and passes the full delivery/reduced-motion path; `model_asset_check.tscn` passes at pickup tray 2 meshes / 568 triangles and service bell 5 / 1,236; Forward Mobile passes at 62 meshes / 13,112 triangles with a 9.596ms average process time; `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 169 (Day 1 rear wall/floor transition alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region169-back-wall-final.png`, both 1280×720 at density 1 in the same Day 1 selected-boba state. Equal-coordinate evidence is `qa/regions/region169/127-wall-floor-day1-final.png`; full context is `qa/regions/00-full-comparison-region169-back-wall-final.png`.
- The first horizontal comparison was misread because the second image begins 700px into the composed strip. Rechecking each crop in its own coordinate system proved the window and wall shelf were already within roughly 4–10px of the source, so neither was moved. The actual P2 structural mismatch was the missing diagonal wall/floor transition: runtime showed a flat cream band where the reference has a pale molding over a cool-greige floor wedge.
- Built-in ImageGen `precise-object-edit` isolated the long matte cream perspective molding, then `background-extraction` preserved that molding and the cool-greige plane below while removing only the wall above to genuine transparency. The selected source is `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-6282ba4f-5841-4d34-955c-e4e3590b8e06.png`; the fitted, restrained-color export is `assets-transparent/background/background-wall-floor-v2.png` and its runtime copy is `game/assets/ui/full_set_v3/background/background-wall-floor-v2.png`.
- The existing background slot presents the real 650×160 alpha asset at `(0,42)`, before the entrance, succulent, window and shelf layers. This restores the source's diagonal molding and cool floor plane without covering later decor or changing the already-aligned station/customer/UI coordinates. Remaining fine grain and sub-pixel perspective variation are P3 raster detail.
- Fidelity and behavior: typography, localized copy, live controls, customer lane, rear stations and all 3D props are unchanged; the asset stays matte, low-saturation and free of opaque checkerboard/background residue. `input_check.tscn` pins the slot and passes the full interaction path; Forward Mobile passes at 62 meshes / 13,112 triangles; `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 170 (Day 1 topping-card density and spacing alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region170-topping-panel-final.png`, both 1280×720 at density 1 in the same Day 1 selected-boba state. Equal-coordinate evidence is `qa/regions/region170/134-topping-panel-day1-final.png`; full context is `qa/regions/00-full-comparison-region170-topping-panel-final.png`.
- The strict crop proved the panel baseline and title were already aligned. The P2 imagery mismatch was inside the three live cards: each old icon showed only three sparse round pieces in a deep bowl, while the source uses a broad shallow bowl densely filled with distinct pearls, coconut-jelly cubes or pudding cubes. The card row also used an ignored generic `separation` theme override, leaving visible gaps about 4px tighter than the source.
- Built-in ImageGen `precise-object-edit` produced three isolated genuine-alpha bowl assets from the same reference. Selected sources are `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-149a9edb-0cfd-4a51-8e90-6e5f5c171874.png`, `exec-d6395603-724e-4781-8d47-b46f8a6f3780.png` and `exec-be591671-0f7c-4554-bb9c-580f1252c35b.png`; fitted masters are `assets-transparent/ingredient/topping-{boba,coconut-jelly,pudding}-v4.png`, with runtime copies in `game/assets/icons/`.
- Each 128×128 icon now uses the same `(5,22)–(123,104)` optical box, producing the source's dense 66×46px visible bowl family in the existing 76×72 slot. The GridContainer now uses its real `h_separation` theme constant at 12px; three-card width is 87px and the panel is 314px, aligning the first, middle and last card envelopes within about 0–2px of the source. Late-game width calculation uses the same live spacing so nine choices remain one row.
- Fidelity and behavior: WenKai labels and localized ingredient names remain live; the mint/cream/coral card skins and selected outline are unchanged; generated bowls are restrained, clean alpha rasters with no card, text or baked checkerboard. Pointer, touch, numeric shortcuts, keyboard/gamepad focus, selected-state motion and reduced-motion behavior still target the same Buttons. Remaining pearl highlight and ceramic brush differences are P3 raster detail.
- Verification: `input_check.tscn` pins the panel width and all three raw-PNG optical boxes; Forward Mobile passes at 62 meshes / 13,112 triangles and keeps the Day 10 nine-card row inside the safe frame; `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 171 (Day 1 sugar and shaker station alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region171-sugar-shaker-final.png`, both 1280×720 at density 1 in the same Day 1 selected-boba state. Equal-coordinate evidence is `qa/regions/region171/138-sugar-shaker-day1-final.png`; full context is `qa/regions/00-full-comparison-region171-sugar-shaker-final.png`.
- The strict crop showed that all four sugar labels and the station baseline were already aligned, but the sugar raster was vertically stretched about 20px below the source. The shaker art reused a narrow 145×200 slot about 20px left of the reference; its coral tag was likewise about 8px left, 10px narrower and 10px shorter.
- The existing real station assets are reused. Sugar keeps its x/width and top anchor but renders at 235×140 instead of 235×160. The shaker uses the source asset's actual alpha ratio at `(1130,98)` / `168×162`, placing its teal lid and base envelopes at the reference bounds; the live tag moves to `(1164,228)` and grows to 84×44. No replacement art or screen-space patch was added.
- Fidelity and behavior: the four localized sugar labels, bottle colors, cream/coral/mint palette and raster edge quality remain unchanged. Sugar selection, shaker hold/gesture, pulse/compression feedback, sound, haptics, keyboard/gamepad input and reduced-motion paths still act on the same live controls. Remaining bottle-paint and canister-grain differences are P3 asset detail.
- Verification: `input_check.tscn` pins both final station-art transforms and passes the full preparation path; Forward Mobile passes at 62 meshes / 13,112 triangles and keeps the late-game controls in the safe frame; `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 172 (Day 1 top-right shelf and pause alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region172-top-right-final.png`, both 1280×720 at density 1 in the same Day 1 selected-boba state. Equal-coordinate evidence is `qa/regions/region172/143-top-right-day1-final.png`; full context is `qa/regions/00-full-comparison-region172-top-right-final.png`.
- The first strict crop found a P1 region-proportion mismatch: the v1 shelf ended near x=1166 instead of continuing behind the pause control to the right edge. Stretching v1 proved the coordinate target but exposed a P2 structural mismatch: its two compressed cubbies read as three narrow rails, whereas the source has one broad open cubby, one lower base slab and short hanging supports. The pause circle itself was already within about 1px and remained untouched.
- Built-in ImageGen `precise-object-edit` changed only the existing shelf structure while preserving its pale-oak material, rounded bevels and diffuse painterly light. The selected source is `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-4b3a51e1-ca72-467b-8e1a-5c9f3370b41f.png`; the genuine-alpha project master and runtime copy are `assets-transparent/background/background-shelf-v2.png` and `game/assets/ui/full_set_v3/background/background-shelf-v2.png`.
- The final 2090×414 alpha bounds render at `(830,-21)` / `480×95`. The left cheek, top slab, open-cubby baseline and lower supports now land within about 0–3px of the source; the shelf continues beyond x=1280 behind the unchanged live pause button. Remaining wood-grain/contrast variation is P3 raster detail.
- Fidelity surfaces: WenKai labels and app copy are unaffected; upper-right spacing and region density now match; cream/pale-oak/cocoa colors remain in the source family; v2 is a clean real raster with no wall, UI, text, checkerboard or placeholder geometry; pause hover/press/focus, keyboard/gamepad activation and reduced-motion behavior remain on the same Button. `input_check.tscn` pins the v2 texture slot; Forward Mobile passes at 62 meshes / 13,112 triangles; `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 173 (Day 1 customer order-card drink fidelity)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region173-order-drinks-final.png`, both 1280×720 at density 1 in the same frozen Day 1 selected-boba state. Equal-coordinate evidence is `qa/regions/region173/147-left-customer-lane-day1-final.png`; full context is `qa/regions/00-full-comparison-region173-order-drinks-final.png`.
- The strict customer-lane crop confirmed that both card envelopes, numbered badges and portrait head/foot bounds were already aligned within about 0–3px. The actionable P1 was content fidelity: `椰果奶茶` displayed a bright green fruit-tea sprite with green spheres, contradicting both the live label and the source's warm milk tea with white coconut jelly. The classic-boba sprite was also glossy, ice-heavy and optically narrow compared with the source thumbnail.
- Built-in ImageGen `precise-object-edit` created compact matte versions, then `background-extraction` removed baked checkerboards to genuine alpha. Selected sources are `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-627961b2-0f7c-4bf2-930a-684afd2fa6c7.png` and `exec-f7b02784-f0de-49bf-a1f8-cf6cebbca8ea.png`; project masters are `assets-transparent/drink/drink-classic-boba-v2.png` and `drink-coconut-milk-v2.png`, with versioned runtime copies under `game/assets/ui/full_set_v3/illustrations/`.
- Both 512×512 sprites use the same `(66,55)–(446,455)` optical box, producing source-sized 45×50px card cups. The card's real VBox separation is 5px and patience dots are 16px, aligning the image/name/dot rhythm and three-filled-dot state within about 0–2px. The screenshot harness now freezes Day 1 at `1:17` and 78% patience so source and implementation are compared in the same stable state; production countdown and patience behavior are unchanged.
- Fidelity surfaces: WenKai drink labels stay live and localized; customer/card positions remain fixed; warm tan/cream/cocoa/teal tokens replace the incorrect green content; both cups are clean real alpha rasters with no card, text, checkerboard or placeholder art. Card selection, delivery, patience state changes, pointer/touch, focus, numeric shortcuts, sound and reduced-motion paths remain on the same controls. Remaining cup-brush and portrait-pose differences are P3 imagery details.
- Verification: `input_check.tscn` pins both raw-PNG optical boxes, the coconut drink's warm-tan content and the 16px patience beats; Forward Mobile passes at 62 meshes / 13,112 triangles and validates the three-customer pressure lane; `git diff --check` is clean. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 174 (Day 1 front-counter fascia and deck correction)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region174-front-counter-final.png`, both 1280×720 at density 1 in the same frozen Day 1 state. Equal-coordinate evidence is `qa/regions/region174/155-front-counter-day1-final.png`; full context is `qa/regions/00-full-comparison-region174-front-counter-final.png`.
- The full view had previously hidden a P1 structural error. A dedicated y=500–720 crop proved the front group was centered about 220px too far left: cream/mint/wood layers ran under the order cards and stopped before the right edge, while the source begins behind the A-frame sign and continues beyond x=1280. The cream lip was also about 20px too tall, although the cream/mint boundary itself was close.
- The deterministic Blender export changes only the four existing front meshes. Their shared x center moves from `-0.675` to `0.75`, preserving widths and right-edge continuation. `PD_FrontCreamLip` now uses z center `0.53` and height `0.10`, keeping its lower boundary attached to the mint band while reducing the visible cream face to the source's roughly 40px. The wood deck grows from y depth `0.32` to `0.48` at y=`-1.39`, bringing the near edge to the bottom of the frame without moving the workmat, ticket, tray, bell or action button.
- Post-fix evidence places the cream top, cream/mint boundary, mint/wood boundary and deck top within about 0–3px vertically. The left edges now begin behind the source-matched sign/rail overlap and all four layers continue beyond the right frame. Remaining pale-oak grain density and the hidden off-frame deck edge are P3 material details.
- Fidelity surfaces: live copy and WenKai typography are unchanged; foreground spacing and full-width hierarchy now match; cream/muted-teal/warm-wood materials reuse the established palette; the counter stays real beveled 3D geometry rather than a screen-space patch. All pointer/touch/focus controls, customer layering, cup preparation, handoff motion and reduced-motion behavior are unchanged. `input_check.tscn`, `model_asset_check.tscn` (23 meshes / 4,012 triangles), Forward Mobile (62 meshes / 13,112 triangles) and `git diff --check` pass. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 175 (Day 1 center cup, placement guide and order ticket alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region175-center-final3.png`, both 1280×720 at density 1 in the same frozen Day 1 selected-boba state. Full evidence is `qa/regions/00-full-comparison-region175-center-final3.png`; equal-coordinate focused evidence is `qa/regions/region175/170-center-day1-final3.png`, with the ticket checked at 2× in `qa/regions/region175/171-ticket-day1-final3-2x.png`.
- The first crop found three actionable mismatches: the 3D cup guide used thick raised rectangular pieces instead of the source's flat painterly dashes; the cup was about 5px too high, 6px too narrow and 9px too tall; and the ticket's 1.10×1.16 outer transform made the front sheet roughly 20% too wide and 11% too tall. A later equal-coordinate pass also exposed the workmat's saturated brown rim/cool inset against the source's quiet cream-on-cream surface. The first generated guide draft was rejected because its dashes were oversized; later comparisons verified the exact source-coordinate guide, corrected paper envelope, cup width and scoped workmat material fix.
- The hidden `Mint` guide mesh is replaced visually by the genuine-alpha `ui-cup-guide-v1.png`, extracted from the source's exact `(480,390)–(680,530)` pixels and rendered at that unchanged 200×140 slot behind the live cup. The cup now uses `(503,364)` / `150×150`; `OrderTicket` uses `(712,381)` / `0.90×1.04`; the existing workmat meshes use scoped `F6E4D0` base and `FFF8ED` inset materials. Pin, front paper, cup and guide land within roughly 0–3px of the source while the rim no longer dominates the center region.
- Fidelity surfaces: WenKai title/name copy remains live; workmat, cup, guide and ticket spacing now matches; cream/muted-mint/caramel tokens are preserved; the guide is a real source-derived raster rather than code-drawn art. Built-in ImageGen `background-extraction` / `precise-object-edit` variants were inspected; outputs with photoreal cup treatment, glow, baked checkerboard or altered paper proportions were rejected rather than shipped. Remaining cup pearl brush detail, ticket under-sheet length and material grain are P3.
- Behavior and verification: cup empty/tea/milk/topping/sealed states, bounce/shake/seal/handoff animation, shake-bar following, ticket live drink/name updates and all pointer/touch/keyboard/gamepad paths are unchanged. `input_check.tscn`, `model_asset_check.tscn` (shop 23 meshes / 4,012 triangles), Forward Mobile (61 meshes / 11,384 triangles), `localization_check.tscn` and `git diff --check` pass. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 176 (Day 1 pickup tray, service bell and handoff feedback alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region176-pickup-final2.png`, both 1280×720 at density 1 in the same frozen Day 1 selected-boba state. Full evidence is `qa/regions/00-full-comparison-region176-pickup-final2.png`; equal-coordinate pickup evidence is `qa/regions/region176/187-pickup-zone-day1-final2.png`, with the bell checked at 2× in `qa/regions/region176/188-service-bell-day1-final2-2x.png`.
- The baseline crop showed that the arrow and 140×56 pickup tag geometry were already aligned, while the scoped colors were materially darker than the source: the tray inset was flat gray-beige, its mint rim was dark/green, and the coral tag sampled near `#E98572` against the source's quiet `#F1AA90`. The smooth 3D bell also lacked the source's six radial ribs and used a brown/chrome base. An early horizontal transform trial over-corrected both tray and bell; row-by-row equal-coordinate evidence proved the original tray transform was already within about 0–5px, so it was restored rather than preserving a false fix.
- The live tray keeps its verified `(1.903,0.982,1.0)` transform and real 2-mesh GLB, with only scoped `#95C9C7` mint, `#69A4A0` dark mint and `#FFF3E1` cream materials. The pickup tag keeps its position/size and now uses source-sampled coral states. Built-in ImageGen `background-extraction` created the real transparent `service-bell-v2.png` from the exact bell crop; the selected source is `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-1d16c1c2-bfb2-47bf-ad0d-65941bda8172.png`, fitted at `(956,459)` / `105×118`. Its six-rib mint dome, warm-gray ring and charcoal base replace the hidden featureless 3D bell visually.
- Fidelity surfaces: live WenKai `取餐` copy and 26px hierarchy remain unchanged; tray/sign/bell spacing and perspective match; cream/mint/coral tokens now share the source's quieter balance; the bell is a genuine-alpha raster with no tray, text, checkerboard or background residue. Remaining tray wood-grain density and sub-pixel bell brush softness are P3. The source has no extra app-specific copy in this region.
- Behavior and verification: successful service still flies the sealed cup along the source arrow and now rings the visible bell with a restrained 0.22s rotate/compress/settle cue; reduced motion kills and resets that tween. `input_check.tscn` exercises both animated and reduced-motion paths; `model_asset_check.tscn` passes (pickup tray 2 meshes / 568 triangles, hidden service bell 5 / 1,236); Forward Mobile passes at 56 visible meshes / 10,148 triangles; `localization_check.tscn` and `git diff --check` pass. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 177 (Day 1 left customer lane, order-card token and queue-rail alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region177-left-lane-final2.png`, both 1280×720 at CSS-equivalent density 1 in the same frozen Day 1 / `1:17` / two-customer / selected-boba state. Full evidence is `design/mockups/coral_mint/full-set-v3/qa/regions/00-full-comparison-region177-left-lane-final2.png`; equal-coordinate focused evidence is `qa/regions/region177/left-lane-final2-comparison-2x.png`, `order-cards-final2-comparison-2x.png` and `figures-rail-final2-comparison-2x.png`.
- The exact crops disproved the suspected card/portrait coordinate error: both 108×134 card envelopes, 32px badges, portrait head centers and foot baselines were already within about 0–3px of the source and remain unmoved. The actionable P2 differences were token and imagery fidelity: healthy patience dots used bright `#27B9A7` instead of the source's sampled `#4D948F`, order badges were overly red, and the v1 queue rail omitted the source's coral upper post while starting about 80px too low.
- Built-in ImageGen `background-extraction`, grounded by the full source plus the v1 cutout, produced the real v2 rail. Selected source: `/Users/apple/.codex/generated_images/01a027e4-69d8-71e2-9933-ed9707afa3e6/exec-99b01b1e-51ef-4e1c-aeb8-cff9f76b85d0.png`; its neutral checkerboard was locally matted and checked on a contrasting teal field before the genuine-alpha runtime export. The rail now renders at `(197,72)` / `132×680`, restoring the coral top, pale-oak handrail, three cream caps and muted-teal inset at the source's visible top/turn/bottom anchors.
- A generated mint-customer repaint was tested and rejected after same-state capture because it enlarged the head/body and regressed the already-proven bounds; it remains isolated under `qa/rejected/region177-mint-v4/` and is not used. The selected v4 character preserves the exact v3 alpha, pose, crop and 358×464 optical box, applying only a restrained mint/lavender desaturation and warm-taupe foot grade. This keeps layout stable while removing the current sprite's darkest shoe contrast.
- Required fidelity surfaces: WenKai drink names, weights, wrapping and copy remain live and aligned; card/portrait/rail spacing now matches the same-coordinate source rhythm; healthy/empty patience tokens and badge coral are source-calibrated; the rail and portraits are real clean-alpha rasters with no SVG/CSS/placeholder art, matte residue or visible halo. Card selection, patience countdown/drop animation, arrival/exit tweens, pointer/touch/keyboard/gamepad paths and reduced-motion behavior still target the same nodes. Remaining sleeve pose, subtle hair hue, rail brush texture and paper-corner accents are P3 asset polish, not actionable layout drift.
- Comparison history: the first post-fix rail capture restored the missing coral top but proved an attempted ImageGen portrait repaint was too large; that repaint was rejected, the geometry-preserving grade was substituted, and the final focused comparison re-established the original 0–3px portrait/card bounds. Verification passes `input_check.tscn`, `model_asset_check.tscn` (shop 23 meshes / 4,012 triangles), Forward Mobile (56 visible meshes / 10,148 triangles / 9.510ms average process time), `localization_check.tscn` and `git diff --check`. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 178 (Day 1 central worktop depth and rear-station transition alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region178-worktop-final2.png`, both 1280×720 at density 1 in the same frozen Day 1 / `1:17` / two-customer / selected-boba state. Full evidence is `qa/regions/00-full-comparison-region178-worktop-final2.png`; equal-coordinate focused evidence is `qa/regions/region178/full-worktop-final2-comparison-2x.png`, and the three-way history is `qa/regions/region178/worktop-reference-before-after-2x.png`.
- The baseline crop exposed a P1 region-proportion error hidden behind the cup and ticket: the four pale-oak worktop planks used only `0.70` world units of depth. Their rear edge began about 25–30px below the source, exposing a cool-gray strip directly under the rear stations, while the front edge ended roughly 35–45px early and produced a conspicuous horizontal seam across the playfield. This compressed the main preparation surface and made the cup, ticket and tray appear to sit on separate slabs.
- The root fix changes only the existing four `PD_CounterPlank_*` boxes in `assets_src/blend/optimize_shop_export.py`, increasing their Y depth from `0.70` to `1.40` while preserving each x position, shared y/z center, width, thickness, pale-oak material and four-plank topology. The deterministic Blender export keeps the same 23 shop meshes / 4,012 triangles. Post-fix, the rear wood edge tucks directly beneath the cream/mint station apron and the front edge reaches the source's counter-lip transition; cup, guide, workmat, order ticket, topping panel, arrow, pickup tray and customer lane remain unmoved.
- Required fidelity surfaces: no typography, copy, icon or live-control changes were made; the spacing/layout correction restores the source's continuous rear-to-front preparation plane; the accepted pale-oak color/texture remains unchanged; the result uses the existing real beveled 3D geometry and texture rather than a raster patch or code-drawn surface. Pointer/touch/keyboard/gamepad preparation, shake/handoff animation, focus, reduced motion and all customer systems remain on the same nodes. Remaining individual plank-seam placement and subtle grain contrast are P3 material polish.
- Comparison history: the 1.04-depth trial removed the rear gray strip but still ended visibly early at the front; the 1.40-depth pass preserved the corrected rear boundary and brought the front boundary to the source transition without covering the rear station or foreground fascia. Verification passes `input_check.tscn`, `model_asset_check.tscn`, Forward Mobile (56 visible meshes / 10,148 triangles / 8.987ms average process time), `localization_check.tscn` and `git diff --check`. No actionable P0/P1/P2 finding remains in this region.

Final result:
passed

### Iteration 179 (Day 1 top-HUD source state and icon fidelity)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region179-top-hud-icons-final.png`, both 1280×720 at density 1 in the same frozen Day 1 / `11:17` / two-customer / selected-boba state. Full evidence is `qa/regions/00-full-comparison-region179-top-hud-icons-final.png`; equal-coordinate 2× evidence is `qa/regions/region179/222-top-hud-icons-final-comparison-2x.png`.
- Exact-grid checks rejected an apparent rear-station offset: cabinet, topping, sugar, shaker and contextual topping panel were already at the source envelopes, so the trial move was reverted. The real P2 top-HUD mismatch was state width plus icon language: the harness showed `1:17`, shifting later chips, and the 128px glossy sun/bag/bulb set conflicted with the source's small matte ochre line icons.
- The screenshot harness alone now freezes `time_left = 677.0` to reproduce `11:17`; production keeps the real 120-second countdown. The three 36×36 icons are exact-coordinate source crops from `(29,19)–(65,55)`, `(248,19)–(284,55)` and `(332,19)–(368,55)`, matted against each chip scanline into genuine alpha and stored in `assets-transparent/hud-*.png` plus the existing runtime HUD paths. No generative repaint, code drawing or layout move was introduced.
- Required fidelity surfaces: live WenKai copy and localized values stay unchanged; three chip envelopes, gaps and baselines now align; saturated glossy highlights are replaced by the source's restrained ochre/cocoa marks; all assets are clean 36px RGBA and remain crisp at the native slot. Countdown behavior, pause, tooltips, late-game metric visibility, keyboard/gamepad/touch paths and reduced motion are unchanged.
- Verification passes `input_check.tscn` with exact PNG size/alpha checks, `model_asset_check.tscn` (shop 23 meshes / 4,012 triangles), Forward Mobile (56 visible meshes / 10,148 triangles / 9.253ms average process time), `localization_check.tscn` and `git diff --check`. No actionable P0/P1/P2 finding remains in the top-HUD region.

Final result:
passed

### Iteration 180 (Day 1 reset-sign perspective and content alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region180-reset-sign-final.png`, both 1280×720 at density 1 in the same frozen Day 1 / `11:17` / two-customer / selected-boba state. Full evidence is `qa/regions/00-full-comparison-region180-reset-sign-final.png`; exact-coordinate 2× evidence is `qa/regions/region180/230-reset-sign-final-comparison-2x.png`.
- The dedicated lower-left crop exposed a remaining P2 perspective mismatch hidden by the full view: the live A-frame was almost upright, about 15px left/11px low at its optical center, and its brand lockup read smaller than the reference's strongly tilted sidewalk sign. The surrounding rail, succulent and front fascia were already aligned and remain unmoved.
- The existing real transparent `ui-sign-reset-front-v6.png` stays in place. Only its live control transform changes to `(211,509)`, rotation `-0.22` and scale `(0.75,0.92)`, matching the source's top-left/top-right/bottom-foot envelope; the localized brand label moves to 20px and the existing source-backed cup mark moves 5px upward. A generated customer-proportion edit and a generated source-cutout trial were inspected during the adjacent left-lane audit but rejected because they enlarged the face/body or baked a checkerboard; neither entered the project.
- Required fidelity surfaces: the WenKai two-line brand now matches the source weight and remains live/localized; the sign's spacing, angle and foreground overlap follow the source; cream wood, muted teal and warm-white line tokens are unchanged; the accepted asset remains genuine alpha with no new halo, background or code-drawn substitute. The entire sign is still the same accessible reset Button with pointer/touch/focus, two-step confirmation, tooltip and haptic behavior intact.
- Verification passes `input_check.tscn` with exact transform and accessibility assertions, `model_asset_check.tscn` (shop 23 meshes / 4,012 triangles), Forward Mobile (56 visible meshes / 10,148 triangles / 9.609ms average process time), `localization_check.tscn` and `git diff --check`. No actionable P0/P1/P2 finding remains in the reset-sign region.

Final result:
passed

### Iteration 181 (Day 1 mint-customer internal proportion alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region181-mint-proportion-final.png`, both 1280×720 at density 1 in the same frozen Day 1 / `11:17` / two-customer / selected-boba state. Full evidence is `qa/regions/00-full-comparison-region181-mint-proportion-final.png`; the exact-coordinate reference/v4/v5 history is `qa/regions/region181/233-mint-reference-before-after-2x.png`.
- The strict customer crop confirmed that the portrait container, head top, horizontal center, card and rail overlap were already aligned. The remaining P2 was internal raster proportion: v4's mint side locks stopped around y=209 against source y=220, while its lavender region began around y=203 against source y=212, making the face/hair transition too short and the sweater read too tall/high even though the foot baseline was correct.
- V5 preserves every v4 pixel and the real 512×512 alpha canvas but applies one continuous measured row fit: rows 0–190 remain unchanged, source rows 190–230 expand into 190–248, and rows 230–512 compress into 248–512. The in-scene mint region now ends around y=218 and the lavender region spans y=209–305, versus source y=220 and y=212–304, without moving the proven head top or foot baseline. No generative repaint, rescaled whole sprite or layout move was used.
- Required fidelity surfaces: no text or copy changes occur in this image-only region; card/portrait/rail spacing remains fixed; the accepted mint/lavender/cream grade is byte-preserved; the 512px genuine-alpha raster keeps sharp hair, face and garment edges with no seam, checkerboard, halo or background. Arrival/exit tweens, selection/focus, patience, delivery, reduced motion and the hidden 3D fallback continue to use the same live portrait node.
- Comparison history: a naive lower-body split was rejected immediately because it produced a visible collar seam; the continuous three-band fit removed that seam and aligned the measured hair/sweater endpoints. Verification passes `input_check.tscn` with the selected v5 runtime-path assertion, `model_asset_check.tscn`, Forward Mobile (56 visible meshes / 10,148 triangles / 9.700ms average process time), `localization_check.tscn` and `git diff --check`. Remaining cheek/arm brush-shape variation is P3 asset polish.

Final result:
passed

### Iteration 182 (Day 1 yellow-customer head and baseline alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region182-yellow-proportion-final.png`, both 1280×720 at density 1 in the same frozen Day 1 / `11:17` / two-customer / selected-boba state. Full evidence is `qa/regions/00-full-comparison-region182-yellow-proportion-final.png`; the exact-coordinate reference/v1/v2 history is `qa/regions/region182/239-yellow-reference-before-after-2x.png`.
- The focused crop confirmed that the card, rail overlap and horizontal portrait envelope were already aligned. The remaining P2 was the yellow sprite's internal vertical rhythm: its connected brown-hair component occupied `(125,335)–(240,425)` while the source occupies `(126,332)–(240,429)`, making the head read slightly flattened and low before the yellow body.
- V2 preserves the selected v1 pixels and genuine 270×512 alpha canvas. It maps source rows 0–210 to 0–226 and rows 210–512 to 226–512, then uses the unchanged `0.538×0.452` slot scale at y=444. The final connected hair component is `(125,332)–(240,429)` with 8,438 classified pixels against the source's 8,444; the source and implementation now share the exact vertical envelope and differ by only one x pixel at the left antialias edge.
- Required fidelity surfaces: no typography or copy changes occur; the customer/card/rail spacing and z-order remain fixed; brown/caramel/cream/pink tokens and original brush pixels are preserved; the transparent raster keeps clean antialiasing with no seam, halo, checkerboard or background. Arrival/exit motion, order selection, patience, delivery, reduced motion and the hidden 3D fallback remain on the same node and behavior paths.
- Comparison history: a whole-sprite y-scale trial matched the head height but pushed the feet visibly below the source baseline, so it was rejected and the proven slot scale restored. Verification passes `input_check.tscn` with the selected v2 runtime-path assertion, `model_asset_check.tscn`, Forward Mobile (56 visible meshes / 10,148 triangles / 10.118ms average process time), `localization_check.tscn` and `git diff --check`. Remaining arm/body brush-shape variation is P3 asset polish.

Final result:
passed

### Iteration 183 (Day 1 left-entry railing perspective alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region183-entry-railing-final.png`, both 1280×720 at density 1 in the same frozen Day 1 / `11:17` / two-customer / selected-boba state. Full evidence is `qa/regions/00-full-comparison-region183-entry-railing-final.png`; the exact-coordinate reference/v2/v6 crop is `qa/regions/region183/249-rail-reference-before-after-2x.png`.
- The crop disproved a whole-rect offset: v2's middle anchor was already close while its coral top was about 35px too high and its near-field end followed the wrong perspective. The selected v6 keeps the authored paint, maps the upper rows down, preserves the top/middle anchors, and applies the stronger horizontal correction toward the lower end.
- Runtime uses the genuine-alpha 200×570 `background-entry-railing-v6.png` in `(126, 72, 220, 680)` at z=1. Customer/card behavior, arrival/exit motion, selection, reduced motion and input remain unchanged; customers stay behind the rail and the reset sign remains in front.
- Comparison history: v4 over-sheared the middle; v5 corrected the upper and middle line but left the bottom endpoint too far right; v6 retains those anchors and closes the lower endpoint. Verification covers the selected texture/slot/z-order plus the standard rendering, asset, localization and diff checks.

Final result:
passed

### Iteration 184 (Day 1 curved front-counter alignment)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region184-front-counter-final.png`, both 1280×720 at density 1 in the frozen Day 1 / `11:17` / two-customer / selected-boba state. Full evidence is `qa/regions/00-full-comparison-region184-front-counter-final.png`; focused reference/before/final evidence is `qa/region184/14-front-reference-before-after.png`.
- Earlier P1: the runtime front counter was authored as four straight boxes, so the cream lip, teal fascia and lower wood plane remained horizontal while the source uses one shallow, continuous near-field arc. The root fix adds one UV-mapped curved-strip mesh path to the existing Blender export and reuses it for the front wood top, cream lip/apron, teal band, sill and deck. The central curve depth is `0.08` world units (`0.07` on the deck), while the proven cup, workmat, ticket, bell, pickup tray and CTA transforms remain unchanged.
- Comparison history: the first `0.35`-depth trial exaggerated the curve and exposed the floor; the `0.08` trial established the correct silhouette; subsequent passes extended the real wood worktop, restored the warm apron, aligned the band transitions and added real UV texture. The final focused crop now matches the source's wood → cream → warm apron → muted teal → wood order and shallow arc. No P0/P1/P2 mismatch remains in the scoped front-counter region. The remaining cream-highlight brightness and exact grain softness are P3.
- Required fidelity surfaces: WenKai CTA typography/copy, icon, size and position are unchanged; spacing/layout now follows the source curve without moving live controls; scoped cream/wood/teal tokens are source-calibrated; the result is real beveled 3D geometry with UV-mapped wood rather than a screenshot overlay, CSS/SVG substitute or generated placeholder. Input, focus, touch, keyboard/gamepad, haptics, reduced motion and preparation state behavior remain on the same paths.
- Verification passes `input_check.tscn`, `model_asset_check.tscn` (shop 23 meshes / 6,308 triangles), Forward Mobile (56 visible meshes / 12,444 triangles / 11.187ms average process time), `localization_check.tscn`, Blender export and `git diff --check`.

Final result:
passed

### Iteration 189 (Day 1 full-screen regional closure)

- Visual truth: `design/mockups/coral_mint/full-set-v3/qa/regions/reference-1280x720.png` is compared with `design/mockups/coral_mint/full-set-v3/00-current-implementation-region189-final.png`, both 1280×720 in the frozen Day 1 / `11:17` / two-customer / selected-boba state. The authoritative side-by-side is `qa/regions/00-full-comparison-region189-final.png`.
- Left lane: the genuine-alpha v7 entry rail delays its near-field bend, the reset sign uses the corrected envelope, the succulent returns to the source baseline, the mint portrait rises 6px, and both portraits use a transparent generated contact-shadow sprite that follows arrival, departure and reduced-motion cleanup.
- Center: the four gapped worktop planks collapse into one UV-mapped pale-oak top, eliminating the dark seams. A generated transparent warm fabric mat with stitched perimeter is carried by a dedicated Blender plane above the real prep-mat geometry; the ticket background, live title, cup and drink name keep independent runtime nodes and source-fit proportions.
- Pickup: a generated transparent tray surface with muted mint rim and pale wood inset is carried by the existing Blender tray model; the real bell art, handoff arrow, localized pickup label and delivery animation remain independent and interactive. Runtime texture sources are reduced to 512px before GLB export, keeping `prep_mat.glb` at 249 KiB and `pickup_tray.glb` at 155 KiB.
- Built-in ImageGen produced the three missing raster surfaces from the supplied reference: empty stitched prep mat, empty pickup tray and isolated contact shadow. Final project masters are `assets-transparent/station/station-prep-mat-fabric-v1.png`, `assets-transparent/station/station-pickup-tray-v1.png` and `assets-transparent/character/customer-contact-shadow-v1.png`; each runtime asset preserves genuine alpha.
- Verification passes `input_check.tscn`, including customer-shadow lifecycle, bell motion, reduced motion, focus, touch safety and panel confinement; `model_asset_check.tscn` passes at shop 23 meshes / 6,272 triangles; Forward Mobile passes at 58 visible meshes / 12,412 triangles / 10.663ms average process time; `localization_check.tscn` and `git diff --check` pass. No actionable P0/P1/P2 mismatch remains in the supplied Day 1 reference state.

Final result:
passed
