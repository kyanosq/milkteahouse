# P3 Gamepad Playtest — 2026-08-15

Player profile: gamepad-only couch player (D-pad + A/B, no mouse/keyboard). Method: 7 windowed screenshots via tests/screenshot.tscn with SHOT_GAMEPAD=1 (day shop d1/d7, tutorial, pause, night lab d9, sealed-review, nintendo family), each read via vision + cross-checked in source.

## Findings

1. **[手柄不可用] Night R&D lab: gamepad focus is completely invisible on ingredient tiles.**
   Evidence: p3_night.png — every shelf tile (阿萨姆/茉莉/乌龙, 纯茶/鲜奶/生椰/燕麦, toppings) shows identical thin borders; two independent vision passes found no highlight ring, glow, or outline anywhere. Code confirms why: `scenes/night_lab/night_lab.gd` `_shelf_group()` overrides only normal/hover/pressed styleboxes and never "focus"; only footer `_style_secondary_action` (:609-616) gets one. Focus IS grabbed on the first tile (`_on_input_scheme_changed`, :118, :672-674), so A presses act on a target the player cannot see — blind navigation through the core nightly crafting loop.
   Fix: give shelf tiles the same focus stylebox day_shop uses (`scenes/day_shop/day_shop.gd:1403-1411` — 4px COCOA border, draw_center=false).

2. **[挫败] Night lab: zero controller prompts on the whole screen.**
   Evidence: p3_night.png — no A/B/X/Y/L/R/十字键 glyph anywhere (searched explicitly); footer buttons 试做一杯/收工睡觉 carry no button-letter prefix. `night_lab.gd` references InputPrompts only to connect the scheme signal and grab focus (:95, :118) — it never renders accept/cancel hints. A couch player must guess that A selects a tile and how to fire 试做.
   Fix: one legend line like the pause panel's ("十字键选择 · A 确认 · Menu 设置") plus an A prefix on 试做.

3. **[挫败] Tutorial buttons have no visible focus ring, and body copy is mouse-first.**
   Evidence: p3_tut.png — 跳过教学/下一步 are unstyled default-theme buttons; vision sees no highlight on either. `ui/tutorial_overlay.gd:105-121` creates them with zero stylebox overrides (only the spotlight/card panels are styled), even though `_next.grab_focus()` runs (:144) so A does work. Step-1 body says "点击其他卡片即可切换" while the gamepad mapping ("十字键切换焦点，A 选择订单") is demoted to a smaller 68%-alpha hint line (:100-103). This is the first screen a couch player meets.
   Fix: apply the shared focus stylebox to 跳过/下一步; in gamepad mode promote the D-pad/A sentence to the body and drop the click wording.

4. **[打磨] Idle order cards keep mouse wording ("点按设为当前订单") in gamepad mode.**
   Evidence: p3_day.png and p3_sealed.png — every non-active card reads 点按设为当前订单; `localization/ui.csv:59` ORDER_HINT_DEFAULT has no gamepad variant, and `day_shop.gd` only swaps the deliver hint for gamepads (:1900). The action is D-pad+A operable, but the on-card text denies that.
   Fix: gamepad variant "十字键聚焦 · A 设为当前订单" built from `InputPrompts.accept_hint()`.

5. **[打磨] Focus ring and active-order border are two competing dark/colored outlines with low salience difference.**
   Evidence: p3_day.png — the focused tea tile (阿萨姆) shows only a thin dark border that reads as "unstyled black edge" at couch distance; on p3_sealed.png the focused card carries a 4px dark ring (`day_shop.gd:1737-1742`, color 30201D) while "active order" is a coral border — same weight, different hue, easy to conflate which one A will act on.
   Fix: make focus visually distinct from selection: thicker ring (5-6px) with white outer glow or a slow pulse; keep coral strictly for active order.

6. **[打磨] Time-critical numbers are the smallest text on screen.**
   Evidence: p3_day.png/p3_sealed.png — order countdowns ("14秒", "18秒") are ~13px amber on cream; top-bar goals ("3★需288", "银金<40") are dense and small. Everything a player must read under time pressure is the least legible.
   Fix: bold + enlarge countdowns (or pill background behind them); raise top-bar stat contrast.

## Strengths

1. **Per-family glyph remapping is complete and correct in both directions.** Xbox-mode shots show "· A 确认" on the action bar, "LB・煮当前茶底 / RB・煮一锅珍珠" prep hints (p3_day.png) and a full pause legend "手柄：十字键导航・A 确认・LB 茶桶・RB 珍珠锅・X 摇茶・Y 店员・Menu 暂停" (p3_pause.png); the nintendo shot swaps to "B 确认" + "L·/R·" with zero Xbox leftovers (p3_nin.png). Backed by `autoload/input_prompts.gd:19-24` CONTROLLER_LABELS and hint call sites throughout.

2. **Sealed-cup review→deliver flow is genuinely gamepad-first.** p3_sealed.png: bottom bar reads "下一步：聚焦订单核对 · A 交付", the focused card shows "A · 交付到此" plus per-row checkmarks comparing sealed cup vs order. `day_shop.gd:1256/1900` use the dedicated _GAMEPAD strings, `_focus_active_order` (:2055-2067) auto-jumps focus to the active card after sealing (with pause/running guards), and the order-card focus stylebox sets draw_center=false so the ring never covers the recipe (:1735-1742).
