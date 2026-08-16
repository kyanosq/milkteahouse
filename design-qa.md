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
