# P4 Playtest — English Locale (2026-08-15)

Player: EN-only. 8 prescribed screenshots + bonus main-menu shot, all SHOT_LOCALE=en.
CJK sweep: every shot cross-checked visually and against `game/localization/ui.csv` + `game/data/*.json`.
No 破损-level issues found: zero Chinese glyphs on any screen, no real overflow/truncation.

## Findings

1. [难读] Comma-less enumerations (systemic, 5 strings). EN drops the Chinese 、 without adding commas.
   Shot: /tmp/p4_tut.png (tutorial body). Exact strings (ui.csv keys):
   - `TUTORIAL_1_BODY` "Order cards on the left list tea milk toppings and sugar."
   - `TUTORIAL_3_BODY` "Choose tea milk toppings and sugar in order."
   - `TUTORIAL_1_HINT` "Keyboard players can press 1 2 or 3 to switch orders."
   - `NIGHT_INCOMPLETE` "Select a tea base milk and sugar level before making a trial cup."
   - `DAY_FEEDBACK_INCOMPLETE` "Choose a tea base milk and sugar level first!"
   Fix: "list tea, milk, toppings, and sugar" / "press 1, 2, or 3" / "select a tea base, milk, and sugar level".

2. [打磨] HUD costs chip "Stock0 · Rent D7" — no space between label and number; "Rent D7" is cryptic.
   Shot: /tmp/p4_menu.png, /tmp/p4_day10.png (top bar). String: `DAY_HUD_COSTS_NEXT` "Stock%d · Rent D%d"
   (also `DAY_HUD_COSTS_TODAY` "Stock%d · Rent≤%d").
   Fix: "Stock %d · Rent day %d" / "Rent ≤%d" (add tooltip explaining rent cadence).

3. [打磨] Machine-flavored event copy: "More pure tea low-sugar and topping-free orders".
   Shot: /tmp/p4_night.png (Tomorrow's Business card, Light-Drink Trend). String: `EVENT_LIGHT_DRINKS_CHALLENGE`.
   Fix: "More orders for plain tea, low sugar, and no toppings." Sibling `EVENT_LIGHT_DRINKS_HEADLINE`
   "Low-sugar pure tea is trending today." is fine — just this one line reads like MT.

4. [打磨] Night-lab sugar tiles show two-letter fragments: "No", "Fu".
   Shot: /tmp/p4_night.png (Sugar shelf; Full Sugar tile reads "Fu"). Cause: night_lab.gd icon fallback
   `btn.text = short_name.left(2)` (sugar levels have no icon PNG); "None"→"No", "Full"→"Fu".
   Fix: give sugar tiles numeric labels ("0%/30/50/70/100%") or the full short name; never `.left(2)` words.

5. [打磨] Currency unit inconsistency: prices in "¥" but rewards/targets in "coins".
   Shots: /tmp/p4_board.png ("Classic Boba Milk Tea · ¥15 …") vs /tmp/p4_contract.png
   ("Operating revenue ≥ %d coins", "CONTRACT_TARGET_REVENUE") and night panel "+2 coins" lines.
   Same wallet, two names; an EN player can't tell if 1 coin = ¥1.
   Fix: pick one — "¥15 … +¥8" everywhere (keeps the Chinese street-shop flavor), or "coins" everywhere.

6. [打磨] "Day 7 Closed" title reads like "the day is closed", not closing time.
   Shot: /tmp/p4_end.png (results panel). String: `DAY_RESULT_TITLE` "Day %d Closed".
   Fix: "Day 7 Complete" or "Closing Time — Day 7".

7. [打磨] Prep-station titles inconsistent casing/grammar: "Tea Vat · Assam stock 3" vs "Pearl Pot · stock 3".
   Shot: /tmp/p4_day10.png (center stations). Strings: `DAY_PREP_TEA_TITLE` "Tea Vat · %s stock %d",
   `DAY_PREP_PEARL_TITLE` "Pearl Pot · stock %d".
   Fix: "Tea Vat · Assam: 3 in stock" / "Pearl Pot: 3 in stock", or "Assam ×3".

## Strengths

- Copy tone is genuinely good English, not MT: recipe flavor text like "a green boba tea that feels like
  nature slapped you awake" (Cilantro Rhapsody) and "turn three good things into one crime"
  (Sweet-Savory Horror); names "Fish-Mint Revenge", "Brown-Sugar Boba Milk" land naturally on a café menu.
- Localization plumbing is airtight: no CJK leakage anywhere (data names resolve by id →
  INREDIENT_/RECIPE_/TIER_ keys; even 3D shelf labels refresh on locale change), and HUD number formats
  ("Day 10 · 117s", "0/98 · 3★ at 137", "Best combo ≥ x3") are consistent and readable.
