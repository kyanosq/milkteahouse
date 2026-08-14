# First-Hour Audit — Milk-Tea Shop (Godot 4.6)

Reviewer stance: demanding Steam player, first ~60 minutes (days 1–7 plus night phases). All evidence collected on 2026-08-15 from the real game: 4 headless autoplay bots (`res://tests/autoplay.tscn`) and 3 windowed screenshots (`res://tests/screenshot.tscn`), plus code reading. No game files were modified.

## Raw evidence collected

### Autoplay RESULT lines (headless)

```
[BOT] profile=newbie day=1 sample=0 rework_rate=28% discard_rate=8%   (from /tmp/au_n1.log)

n1: [RESULT] earned=119 net=90 operating_net=90 stock=29 waste=5 rent=0/0 relief=0 goal=98 stars=2 served=10 perfect=7 perfect_rate=70% reworks=6 discards=0 inspiration=11 angry=0 serve_rate=100% event=calm event_bonus=0 ... upgrades={  }
n3: [RESULT] earned=185 net=136 operating_net=136 stock=49 waste=0 rent=0/0 relief=0 goal=134 stars=2 served=16 perfect=13 perfect_rate=81% reworks=3 discards=0 inspiration=23 angry=0 serve_rate=100% event=lunch_rush event_bonus=0 ... upgrades={  }
n5: [RESULT] earned=204 net=144 operating_net=144 stock=60 waste=2 rent=0/0 relief=0 goal=170 stars=2 served=13 perfect=10 perfect_rate=77% reworks=3 discards=2 inspiration=15 angry=0 serve_rate=100% event=brown_sugar_trend event_bonus=40 ... upgrades={  }
r3: [RESULT] earned=280 net=223 operating_net=223 stock=57 waste=4 rent=0/0 relief=0 goal=134 stars=3 served=20 perfect=18 perfect_rate=90% reworks=2 discards=1 inspiration=37 angry=0 serve_rate=100% event=lunch_rush event_bonus=0 ... upgrades={  }
```

Derived numbers (goal = `80 + 18*day`, endless_contracts.gd:95; 3-star = `earned >= goal*1.4`, day_shop.gd:2264):

| Day | Goal | 3-star needs | Newbie earned | Newbie net | Stars |
|-----|------|--------------|---------------|------------|-------|
| 1   | 98   | 137          | 119 (121%)    | 90         | 2 |
| 3   | 134  | 188          | 185 (138%)    | 136        | 2 |
| 5   | 170  | 238          | 204 (120%)    | 144        | 2 |
| 3 (regular) | 134 | 188 | 280 (209%) | 223 | 3 |

### Screenshots (1280x720 windowed)

- `/tmp/tut.png` — day-1 tutorial step 1/5, dimmed backdrop, mint focus ring on the order card, cream text card, "跳过教学 / 下一步".
- `/tmp/day1.png` — live day-1 shop: HUD "第 1 天", goal counter `0/98` with mini progress bar, one order card (icon slots + sugar label + patience bar), center context panel, next-action hint, prep stations with `Q`/`E` shortcuts.
- `/tmp/pause.png` — pause menu: 继续 / 重看教学 / 返回主菜单, plus "今日进度已自动保存" (autosave note).

---

## Ranked weaknesses

### 1. [P1] The 3-star bar (1.4x goal) is invisible all shift — the goal bar saturates at 100%

**Evidence**
- `day_shop.gd:2564` — HUD goal bar: `hud_goal_bar.value = clampf(earned/goal*100, 0, 100)`; once earned ≥ goal the bar is full and stops moving for the rest of the day.
- `day_shop.gd:2353` — settlement bar: `result_goal.value = mini(earned, goal)` — also clamps.
- No key, tooltip, or HUD element anywhere states the 140% threshold (grep of `TUTORIAL_*`/`DAY_*` copy confirms; the tutorial's step-5 hint even frames the goal itself as the target: "让下一天比今天更顺手").
- Bot evidence: the newbie profile served 100% of customers with 0 angry on days 1/3/5 and still got 2 stars every time — on day 3 it missed 3 stars by **3 coins** (185 vs 188) with zero indication anything was close.

**Why a Steam reviewer dings it**
"I hit the goal with half the clock left and stood there. 40 hours later I learn from a wiki that the real score was 40% higher." Hitting the displayed goal feels like completion, so the last ~40–60 seconds of every shift have no pull; then the settlement suddenly grades you against a number you never saw. Perceived as hidden rules / unfair scoring, not challenge.

**Minimal fix**
One line of copy plus one bar change: let the HUD/settlement goal bar keep filling to 140% and put a 3-star tick at the 100% and 140% marks (`hud_goal_text` already shows `earned/goal`; add "★3 at N" to `DAY_RESULT_GOAL`). No economy change required.

### 2. [P1] Goal curve (+18/day) outruns a realistic new-player income; the wall lands at day 5–7, exactly when rent starts

**Evidence**
- `endless_contracts.gd:95` — `goal = 80 + 18*day`; 3-star needs 1.4x that (137/162/188/213/238/263/288 for days 1–7).
- Newbie bot net income: 90 (d1) → 136 (d3) → 144 (d5). Day 5 net (144) is already **below** the day-5 goal (170); only gross-revenue scoring keeps it at 2 stars. Extrapolating the +18/day goal against a net curve that gained 8 coins between day 3 and day 5, a player who doesn't rapidly improve falls into 1-star territory around day 6–8.
- Day 7 adds the first rent (40; `operating_costs.gd:5-7`) and tier-2 upgrades cost 220–260 (`upgrade_catalog.gd:10,18,34`) ≈ two full newbie days. The catalog comment on `comfort` ("首级维持新手首日可买") concedes only tier-1 (60) is day-1 affordable — and 60 of a 90-coin day-1 net is exactly one purchase, once.
- No catch-up mechanic exists in day 1–7: stars give nothing below 3 (day_shop.gd:2262-2271), and relief only prevents debt, not stagnation.

**Why a Steam reviewer dings it**
The regular profile (day 3: 280 earned, 3 stars) proves skill beats the curve, so the curve is "fair" — but the median new buyer is the 28%-rework player, and their first-hour arc is "2 stars, 2 stars, 2 stars, then slipping". Reviews will say "difficulty spikes after day 5 and the grind wall hits at day 7".

**Minimal fix**
Flatten the first week only: `80 + 12*day` through day 7 (goal 92→164) then resume `+18`, or subtract 15% from the goal the day after any ≤1-star day (a one-line change in `goal_for_day` reading `GameState.campaign_stats`). Either keeps late-game pressure identical.

### 3. [P2] The 4-second golden window is a small-text-only cue; spoiled batches quietly poison the next 4 drinks

**Evidence**
- `day_shop.gd:72-73` — tea: brew 8s, golden 4s, late 6s, then spoiled (`prep_batch.gd:47-56`). Pearls: 10s/4s/6s.
- The only golden/spoiled signal is the 12px state label and the prep button text (`day_shop.gd:463,846-864`); there is no `Sfx.play` on window transitions (the game has full Sfx/Haptics infra used everywhere else).
- Consequence chain: spoiled batch = 4 servings at quality 0 → −2 price per cup (day_shop.gd:2033-2034) **and** the cup can no longer be "flawless" (day_shop.gd:2022) → no tips-tier streak, no combo, no perfect count, for the next 4 customers — none of which is explained at the moment it happens.
- Bot evidence: day-5 newbie perfect_rate 77% vs regular 90%; discards=2, waste=2 on a 3-customer day.

**Why a Steam reviewer dings it**
By day 5 (brown_sugar_trend: most orders demand one specific topping, `daily_events.gd:37-45`) you are reading three order cards, two prep timers and a sugar prompt. A mechanic that punishes 4 future sales for looking away from a 12px label for ~10 seconds reads as "gotcha", especially when the tutorial (which does explain windows, ui.csv:309) was 4 days ago.

**Minimal fix**
Play a one-shot sound + button pulse when a batch enters GOLDEN and when it enters SPOILED (`_update_prep_batches` already knows the transition), and flash "−2/杯" on the spoiled collect label. Pure feedback, no balance change.

### 4. [P2] "Goal Reached" verdict on a day where net income is below the goal

**Evidence**
- Newbie day 1: earned 119 ≥ goal 98 → verdict "Goal Reached" (DAY_RESULT_VERDICT_2, ui.csv:264), but the ledger two panels below shows stock 29, net 90 < 98. Stars use gross; the ledger title discloses it ("经营账本 · 星级仍按毛营收计算", ui.csv:275), but the headline verdict + full goal bar say success while the wallet says miss.
- HUD compounds it during play: the coin pill's cost sub-line is 10px (`day_shop.gd:723`), so restock cost is near-invisible mid-shift.

**Why a Steam reviewer dings it**
First-session confusion: "I reached the goal every day and still can't afford anything / rent scared me." It feels like two scoreboards disagreeing, and players assume a bug rather than reading the disclosure line.

**Minimal fix**
On the settlement goal row, add a second, thinner marker at the net value (data already exists in `ledger`/`net_operating` when `_end_day` builds the panel), or change VERDICT_2 to "Goal Reached · %d net". One panel edit.

### 5. [P2] Tutorial is read-only; its two densest steps are exactly the ones players must act out

**Evidence**
- `tutorial_overlay.gd` — five static cards; the only interactions are Next/Skip. Step 2 (prep windows) and step 5 (meta loop) are 3–4 sentence bodies at 17px (ui.csv:309,318); the screenshot confirms a text wall over a paused shop.
- The shop conveniently spawns a customer and freezes the clock before the tutorial (`day_shop.gd:632-639`) — the setup for a guided first cup already exists but is unused.
- Newbie day-1 rework rate 28% (bot profile) is precisely the skill (read card → context panel → seal) the tutorial describes but never makes you perform once.

**Why a Steam reviewer dings it**
"Wall-of-text tutorial, then trial by fire." Management players specifically review badly against text tutorials that could have been 30 seconds of doing.

**Minimal fix**
Gate step 3 and step 4's Next button until the player has selected the base of the live order and shaken/sealed one cup (the clock is already frozen; `_can_gesture_shake`/`cup_sealed` are readable from the overlay). No new scenes needed.

### 6. [P2] Reset Cup charges full ingredient cost instantly, with no undo or grace period

**Evidence**
- `day_shop.gd:1107-1117` — one press adds the whole cup cost to `stock_cost`+`waste_cost` immediately; the only warning is the cost embedded in the button label (`DAY_RESET_CUP_WASTE`, day_shop.gd:1154), which sits next to the coral danger styling at the bottom-left.
- Bot evidence is small in expert hands (waste 0–5, discards ≤2), but the bot's 8% discard profile exists because mis-picks happen; a panicking new player mid-rush mashing reset (it's placed right of the order cards at 28,650) digs a quiet hole that only shows up in the night ledger.

**Why a Steam reviewer dings it**
Minor on its own, but it stacks with #4: money leaks (waste, restock) are charged silently during play and only explained after closing. "Where did my money go" is the classic first-hour complaint for shop sims.

**Minimal fix**
Make the first reset within ~2 seconds of the last ingredient add free (misclick grace — `_mark_cup_correction` already timestamps nothing, but `cup_corrections`/input timing suffice), or move the cost into a confirm tooltip when cost ≥ 3.

---

## Genuinely good (keep as-is)

1. **Queue forgiveness architecture.** Rear customers drain patience at half speed (day_shop.gd:185), a wrong delivery gives a second chance instead of a leave (patience ×0.65, day_shop.gd:2150, with copy that says so: "顾客皱着眉再给你一次机会"), and result: even the 28%-rework newbie bot has serve_rate=100%, angry=0 across days 1/3/5. The first hour never hard-fails a fumbler — that's the right call for this genre.
2. **The pre-day event briefing panel.** Every non-calm day pauses before opening with a structured "challenge / opportunity" card pair, tomorrow's event preview, and the active-route line (day_shop.gd:602-629; ui.csv:30-33). Day 3's lunch_rush is announced ("arrive 28% faster") before it pressures you. This is better briefing copy than most sims ship.
3. **Multi-channel legibility under pressure.** Order cards are icon-based with per-ingredient ✓/! match badges (day_shop.gd:1882-1912) — not color-only; patience has a bar **plus** a numeric seconds countdown (DAY_SECONDS_SHORT); prep states golden/late/spoiled carry words + seconds + color (ui.csv:784-786); the single "next action" line and numbered 1–9 shortcuts are always present. A colorblind player can play this fully by text. The pause menu replaying the tutorial and stating autosave ("今日进度已自动保存") is also exactly right.

## Screenshot appendix

- Tutorial (step 1/5): clean dimmed spotlight, skippable, focus ring lands on the real order card — layout solid; the weakness is content density (#5), not presentation.
- Day-1 gameplay: HUD day+goal (`0/98`), one order card, context panel and next-action hint are all present and non-overlapping at 1280x720; max 2 customers on days 1–2 (day_shop.gd:1515) keeps the left rail readable.
- Pause: resume / replay tutorial / return to menu, autosave note; no restart-day option (acceptable — days are 120s).
