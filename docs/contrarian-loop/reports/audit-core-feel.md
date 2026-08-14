# Core Loop Feel Audit — milkteahouse (Godot 4.6.3)

Date: 2026-08-15 · Scope: game feel / juice / feedback legibility of the day-shop core loop · No game files were modified.

## Evidence gathered

- Windowed captures: `/tmp/feel_a.png` (SHOT_DAY=10, live mid-day sim), `/tmp/feel_b.png` (SHOT_DAY=10 SHOT_END=1 settlement), `/tmp/feel_c.png` (SHOT_STAFF_ACTIVE=1). Note: the vision backend rejected `feel_c.png` three times (HTTP 1210 "image parse error", also after JPEG/downscale conversion); its staged state was verified from `game/tests/screenshot.gd:243,258-264,318-320` instead — day 8, staff "taozi" hired, trait revealed, on duty, live sim frozen after 0.5s.
- Autoplay feel metrics (`BOT_PROFILE=regular BOT_DAY=7`, from `/tmp/feel.log`):
  `earned=307 net=175 goal=206 stars=3 served=21 perfect=17 perfect_rate=81% reworks=5 waste=4 angry=0 serve_rate=100%`
- Code read: `game/scenes/day_shop/day_shop.gd` (all 2660 lines), `game/autoload/sfx.gd`, `game/autoload/haptics.gd`, `game/input/shake_gesture.gd`, `game/systems/prep_batch.gd`, `game/ui/pause_panel.gd`, `game/ui/tutorial_overlay.gd`, `game/ui/cup_rig.gd`, `game/autoload/upgrade_catalog.gd`, `game/localization/ui.csv`.
- Screenshot observations used below: in `feel_a` all three order cards showed teal patience bars ("9秒/15秒/17秒") with no group markers, and the two prep stations showed plain progress bars with no visible window zones; `feel_b` settlement is dense but legible (star badge, 3 metric cards, ledger row).

## Verdict

No P0s — nothing blocks play and the bones of the loop are unusually strong (input ladder, diegetic cup, guarded delivery confirm). The dings cluster on the exact moments that define feel: the **payoff flash**, the **two clocks** (patience, golden window), and the **default shake tuning**. A Steam reviewer would summarize: "cute and readable, but I never knew when the tea was perfect, customers leave without warning, and the result text vanishes before I can read it."

---

## Ranked weaknesses (fix sprint order)

### 1. [P1] Golden prep window is invisible unless you are already staring at the station

- **Evidence:** `game/scenes/day_shop/day_shop.gd:813-864` — `_configure_prep_controls` sets only `progress.value` (line 815); the window state lives in a 12px text label (state colors at 857-864) and button text. The ProgressBar has no zone markers and its fill never changes color. No SFX/haptic/pulse fires when `PrepBatch` state flips to GOLDEN or SPOILED — SFX only plays on button press (`day_shop.gd:867-916`). Window math: tea 8s brew → **4s** golden → 6s late (`day_shop.gd:72`, `game/systems/prep_batch.gd:47-56`). Confirmed visually in `/tmp/feel_a.png` (plain bars). The prep strip also sits top-center (y≈198) while player attention is on the cup/ingredients at bottom-center.
- **Why a reviewer dings it:** the golden window is the only skill-based timing in the loop, and it is communicated by a small text swap on a side panel. Mid-pressure you collect "whenever" — the 81% perfect rate of the regular bot shows the loop forgives ignoring it entirely, which makes the system feel like noise rather than skill.
- **Minimal fix:** track previous state in `_update_prep_batches` (`day_shop.gd:775-778`); on flip to GOLDEN play a soft chime (reuse `Sfx.play("coin", 1.3)` or add a cue) + recolor the bar fill via `add_theme_stylebox_override("fill", …)` per state (teal/amber/red), and render the golden/late zones as background `ColorRect` bands on the bar — the exact pattern already exists for the route threshold marker at `day_shop.gd:1622-1632`.

### 2. [P1] Patience bar is binary teal→red at 35%, then silence — walkouts feel like ambushes

- **Evidence:** `game/scenes/day_shop/day_shop.gd:1995-1998` — two styles only: `ratio > 0.35 ? teal : red`. The seconds label never recolors (189-195, only text rebuild). There is no sound, pulse, or haptic when a card crosses into red or counts under ~5s; the only patience audio is the post-hoc `customer_leave` (line 2177). In `/tmp/feel_a.png` a card at 9s remaining (~45% drained) is still fully calm-teal; the first red appears with roughly 5s left. Autoplay regular finished day 7 with `angry=0 serve_rate=100%` — the system rarely bites, and when it does, the warning runway is one binary flip.
- **Why a reviewer dings it:** triage is the core pressure skill and it has no gradient. Losing a customer "unfairly" is the single most rage-inducing event in service games, and here it lands with no buildup. Bonus inconsistency: the tip payout already has three tiers at ratio 0.7/0.4 (`day_shop.gd:2036-2037`) but the bar's two colors don't hint at them — the player can't see the money they're losing as time drains.
- **Minimal fix:** make the fill three-band using the existing tip thresholds (teal >0.70, amber >0.40, red below — matches `service_tip` tiers), recolor `patience_label` with the same band, pulse the card border under 0.25, and play one soft tick when a card crosses 0.35 and each whole second under 5. All state already exists in `_process` at 183-198.

### 3. [P1] The reward flash — the loop's payoff — can overflow the screen and gets cut short by overlapping flashes

- **Evidence:** message composition `game/scenes/day_shop/day_shop.gd:2095-2119` concatenates up to 9 segments (coins · tip · event reason · buzz · dark buzz · golden batch · staff · route · combo · featured menu · reworked · group next). `feedback_label` is built at `day_shop.gd:382-386` with **no width, no autowrap**, font 26, anchored at x=438 — a realistic worst case ("+16金币 · 小费3 · 活动加成+5 · +2话题 · 黄金批次+2 · 店员复核+1 · 店招+3（精准出杯） · 6连击 · 主推《桂花云乳》") is ~55 CJK-width chars ≈ 1400px from x=438, i.e. clipped past the 1280 viewport. Separately, `_flash` (2621-2629) does **not** kill the previous tween: a second flash within 0.9s (routine: collect batch → seal → deliver) gets faded out early by the first tween's schedule. Contrast: `cup_rig.gd:228-229` correctly kills its stored tween.
- **Why a reviewer dings it:** the payoff moment of the entire loop is the one text you can't read — half the string is off-screen and it fades mid-read. Players also can't attribute earnings ("why did I get 16?") when the breakdown is a clipped run-on line.
- **Minimal fix:** give `feedback_label` `custom_minimum_size ≈ (760, 0)` + `autowrap_mode = WORD_SMART`, `max_lines_visible = 2`, put the biggest number first; store the tween in a `var _flash_tween` and `kill()` it at the top of `_flash` (copy the `_shake_tw` pattern from `cup_rig.gd`).

### 4. [P1] Wrong delivery silently destroys the cup, its cost, and the evidence of what you got wrong

- **Evidence:** `game/scenes/day_shop/day_shop.gd:2137-2156` — wrong branch adds `consumed_cost` to `waste_cost` (2138-2139) then `_reset_cup()` (2156) wipes the build; `_refresh_cup → _update_all_order_progress` then sees an empty cup, so the per-slot "!" wrong markers (`day_shop.gd:1882-1912`) that existed pre-deliver vanish in the same frame. The flash copy `DAY_FEEDBACK_WRONG` (`game/localization/ui.csv:244` — "做错了！顾客皱着眉再给你一次机会……连击中断") never mentions the cup was discarded or the ¥N lost. Compare the manual discard path, which does flash the cost (`day_shop.gd:1114`).
- **Why a reviewer dings it:** triple punishment (patience ×0.65 at 2150, streak reset, ingredients wasted) with zero explanation of *which* component mismatched or that money was destroyed. Players read it as "the game ate my coins"; the waste only surfaces later as a ledger footnote (`_build_finance_ledger`, 2519-2520). This is the #1 source of "unfair" reviews in crafting games.
- **Minimal fix:** before `_reset_cup()`, snapshot the wrong component names from `_order_component_state` (already computed per slot) and flash e.g. "做错了：奶基不对 · 已倒杯 ¥3" — extend `DAY_FEEDBACK_WRONG` with two params; or defer the cup reset one frame so the "!" markers linger ~0.6s.

### 5. [P1] Default shake is a leaky bucket: 5 needed, 1.2/s decay — taps visibly don't count

- **Evidence:** `game/autoload/upgrade_catalog.gd:94-95` — `shakes_needed = max(2, 5 - level("shaker"))` → **5 at level 0**; `day_shop.gd:19` `SHAKE_DECAY := 1.2` drains continuously between presses (167-171). Net math: at the regular bot's 4.2 presses/s (`game/tests/autoplay.gd:24,41-44`) each press nets +0.71 → a "5-shake" seal takes ~7 presses; even skilled 6/s needs 7. Below 1.2 presses/s net progress is **zero** — press, wait ~1s, press shows the same counter. The counter copy uses `int(shake_progress)` (`day_shop.gd:1246-1259`, `ui.csv:202-206`) so it can regress ("2/5" after a pause), and the following shake bar drains in real time (line 171). Mouse-gesture shakes are further capped at one per reversal + 85ms cooldown (`game/input/shake_gesture.gd:5-8`), making the decay bite hardest on the most physical input.
- **Why a reviewer dings it:** every single cup ends in this interaction, and on default tuning it feels like dropped inputs — "I shook 5 times and it says 3/5". Decay is a fair anti-cheese idea, but interleaving it with the visible counter reads as a bug.
- **Minimal fix:** grace window — skip decay for 0.5s after each registered shake (decay only after ~1s idle), and display `ceili(shake_progress)` in the `DAY_NEXT_SHAKE`/`DAY_SHAKE_BUTTON` strings. Two-line change in `_process` (167-171) + `_shake_next_action_text`.

### 6. [P2] Streak/combo feedback doesn't escalate — the x3 moment reads like any other serve

- **Evidence:** streak HUD is a static pill "x%d" whose only state change is alpha 0.48 vs 1.0 (`day_shop.gd:2571-2573`). Combo bonus fires every 3rd flawless cup (2047-2049): it plays a dedicated cue + music duck (`day_shop.gd:2125-2126`, `sfx.gd:28-33`) and appends "· 6 连击" as the **9th segment** of the same-size flash string (2113). Nothing differentiates x3 from x9; the pill never pulses/scales.
- **Why a reviewer dings it:** the combo is the loop's skill reward, but visually it's a substring. Players discover they had a streak only when it breaks ("完美连击中断", ui.csv:243).
- **Minimal fix:** tween-scale the streak pill on increment (kill-and-restart pattern), and when `combo_bonus > 0` emit a second short dedicated flash ("x6 连击!") in a bigger font near the cup or reuse `_fly_coin` at the pill; optionally pitch the combo cue up with `streak/3`.

---

## Genuinely good feel aspects (keep and protect)

1. **A real accessibility ladder for the shake.** Dedicated 300×58 shake button, rebindable keyboard action (`game/ui/pause_panel.gd:237-238,441-607`), mouse-flick gesture with sane thresholds (900px/s + direction reversal + 85ms cooldown — `game/input/shake_gesture.gd:5-38`), and accelerometer with gravity calibration so holding the phone never free-shakes (41-51). The next-action copy always names the current method per device ("空格 或左右快速甩动 · 0/5" / "摇晃设备或点击 · 0/5", `day_shop.gd:1246-1259`, `ui.csv:202-206`). Few mobile ports do this.
2. **The cup itself is the feedback.** Numeric-driven shader blends tea/milk proportionally to shake progress with tiger stripes for caramel (`game/ui/cup_rig.gd:180-193`), ten Jolt-physics pearls that take real impulses on every shake (220-227), a wobble tween on shake and squash-stretch bounce on seal/serve (228-243), plus screen `_punch` and a coin label that flies from the order card to the HUD coin pill (`day_shop.gd:2121-2122, 2632-2659`). All of it correctly gates behind `reduced_motion`. This is the juiciest object in the game.
3. **Delivery is legible and guarded by design.** Per-component ✓/! slots update live on the active order card while you build (`day_shop.gd:1744-1796, 1882-1912`), and the review-then-confirm card press (1928-1938) prevents accidental misdelivery to the wrong customer — pressing a different card only switches active target. The audio/haptic stack is coherent and throttled: 6 haptic profiles with amplitude/duration ladders (`game/autoload/haptics.gd:4-11`), per-cue SFX cooldowns, music ducking on combo/bad/staff-alert (`game/autoload/sfx.gd:21-33`), so spam never turns into mud.

Honorable mentions: the settlement panel (verified in `/tmp/feel_b.png`) with star badge, three metric cards and a gross→net ledger incl. next-rent warning (`day_shop.gd:2305-2541`); the pause panel's depth (inline volumes, reduced-motion, haptics toggle, rebinding, debounced disk saves, menu confirm). Caveats worth a backlog ticket: the pause action is unreachable while the tutorial or event briefing overlay is up (`day_shop.gd:214`), and staff slacker events have no pre-warning timer (only post-hoc alert, `day_shop.gd:1444-1455`).

## Suggested sprint order

1, 3, 2, 4, 5, 6 — the flash fix (3) is the cheapest and de-risks reading every other message; 1 and 2 give the loop its skill legibility; 4 removes the "unfair" trap; 5 is a two-line tuning change; 6 is polish.
