# V1 对抗性核实报告：教学 / 焦点 / 移动 / 无障碍

验证代理 V1 · 日期 2026-08-17 · 基线 HEAD `c456b0b`（与试玩代理相同）。
方法：独立代码走读 + 4 个自研只读探针（未复用前代理脚本逻辑；探针与日志：`/tmp/v1_probe_d1.gd`→`/tmp/v1_d1.log`、`/tmp/v1_probe_p3.gd`→`/tmp/v1_p3.log`、`/tmp/v1_probe_p3b.gd`→`/tmp/v1_p3b.log`、`/tmp/v1_probe_misc.gd`→`/tmp/v1_misc.log`）+ Python WCAG/几何计算。未修改任何 `game/` 文件（探针中一处运行时改 `mouse_filter` 为归因实验，属探针内临时变更，进程退出即消失）。

判定统计：14 项中 **13 项 CONFIRMED**（其中 2 项带措辞修正建议）、**1 项 NEEDS-FIX-SCOPE**（P10-3 的 iOS 半段）、0 项 REFUTED。

---

## 1. [S1-D1] 教学门控练习步骤真实输入不可完成

**判定：CONFIRMED**（探针全链路独立复现，含归因实验与对照组）

独立证据（`/tmp/v1_d1.log`，窗口模式 1280x720，`Input.parse_input_event` 注入真实 GUI 事件）：

- 代码层：`game/ui/tutorial_overlay.gd:60-62` 根 ColorRect `Color(0.06,0.055,0.07,0.58)` + `mouse_filter = MOUSE_FILTER_STOP`；`game/scenes/day_shop/day_shop.gd:275-276` `_input` 的 `if not running: return`；`:703` `_show_tutorial` 置 `running = false`；`:1175` `_on_shake` 首行 `if cup_sealed or not running: return`；`:1196-1198` `_can_gesture_shake` 同样要求 `running`。
- 探针输出（关键行）：
  - `[D1] A) mouse-click during tut -> cup_base=<null>`（点击情境按钮中心 (643,137)，位于 STEPS[2] 聚光矩形 (426,64,824,168) 内，UI 看似可点）
  - `[D1] B) KEY_1 during tut -> cup_base=<null>`（键盘捷径被 `not running` 短路）
  - `[D1] C) click with overlay IGNORE (running=false) -> cup_base={black_tea...}`（**归因实验**：仅把覆盖层 mouse_filter 运行时改为 IGNORE、`running` 仍为 false，点击立即生效——证明鼠标路径的唯一阻断就是 STOP 过滤器）
  - `[D1] D) gamepad focus+ui_accept during tut -> cup_base={...} gate_done=true`（手柄是步骤 3 唯一可过模态）
  - `[D1] E1/E2) KEY_1/click after finish -> cup_base={...}`（对照组成立）
  - 步骤 4（index 3）：`F1 SPACE`、`F2 action game_shake`、`F3 点击 300x58 摇茶大按钮`、`F4 直调 _on_shake()` 四路全部 `sealed=false progress=0.0`；教学结束后同一 action `G) progress=1.0`——步骤 4 对所有模态（含手柄）必死。
- 回归缺口证实：`game/tests/onboarding_check.gd:39` 直调 `shop._on_base()`；`:101-105` 的 `_input(KEY_1)` 断言发生在教学结束 `running=true` 之后（`:52`），从未覆盖教学中的输入层。
- 附注（修复无关）：`_on_base`（day_shop.gd:1084）本身无 `running` 守卫，且日初茶库存已备（`:861-863` 每基料 [1,1,1]）——鼠标路径修好后无二次阻断。

**最小修复方案**：
1. `tutorial_overlay._render_step()`：`_step_is_gated()` 为真时把根节点 `mouse_filter = MOUSE_FILTER_IGNORE`（卡片 `_card` 是 PanelContainer 默认 STOP，自身区域不受影响；`_focus` 已是 IGNORE，:75），非门控步恢复 STOP。
2. `day_shop` 增加豁免标志（如 `func _tutorial_practice_active() -> bool: return tutorial_overlay.visible and (tutorial_overlay._step == 2 or tutorial_overlay._step == 3)`），`_input`(:275)、`_on_shake`(:1175)、`_can_gesture_shake`(:1197)、`_on_ingredient`(:1066) 四处守卫改为 `if X and not _tutorial_practice_active(): return`。
3. 回归钉子：onboarding_check 增加两组 GUI 级断言——门控步 3 期间 `Input.parse_input_event`（鼠标点按钮中心 + KEY_1）后 `cup_base != null`；门控步 4 期间注入 `game_shake` action 后 `cup_sealed == true`。测试需从 `get_global_rect()` 动态取坐标。

**预计改动面**：tutorial_overlay.gd 约 +6 行；day_shop.gd 4 处守卫 +1 个辅助函数（约 +10 行）；onboarding_check.gd +25 行断言。风险点：`_input` 豁免后需确认教学期间 `game_pause`（:269 在 `not running` 检查**之前**）与订单快捷键（:304）不受影响——建议豁免只覆盖 prep/shake/staff 分支与情境按钮数字捷径，订单交付分支维持 `cup_sealed and running` 语义。

---

## 2. [S1] P3-F4 教学 `_next` 焦点被同帧延迟 grab 偷走

**判定：CONFIRMED**（探针逐帧焦点轨迹）

独立证据（`/tmp/v1_p3.log`）：

- 同帧：`[F4] same-frame focus: .../SafeFrame/@ColorRect@130/@PanelContainer@132/.../@Button@141`（TutorialOverlay 内的 `_next`，位置正确）。
- frame+1 起：`focus: .../SafeFrame/@PanelContainer@96/@VBoxContainer@97/@GridContainer@99/@Button@280`（情境原料网格首按钮，遮罩下），`[F4] focus inside tutorial overlay: false`，且 4 帧内不归还。
- 代码链闭合：`day_shop.gd:700-701` `_show_tutorial` → `_spawn_customer()`（:1846-1847 首客 `_set_active_customer` → :2129 `_refresh_context_controls` → :1323 `_add_context_button`）→ `:1469-1470` `if InputPrompts.gamepad_mode and _context_shortcuts.size() == 1: btn.call_deferred("grab_focus")`；而 `tutorial_overlay.start()`(:706) → `_render_step` 的 `_next.grab_focus()`（tutorial_overlay.gd:163）是同步调用——延迟调用必然落在其后。注意 `day_shop._on_input_scheme_changed`(:1512) 也走 `_refresh_input_prompts` → `_refresh_context_controls`，教学可见期间族切换/语言切换同样会重偷。

**最小修复方案**：`_add_context_button` 的延迟 grab 加教学守卫：`if InputPrompts.gamepad_mode and _context_shortcuts.size() == 1 and not tutorial_overlay.visible:`；并在 `_on_tutorial_finished`（day_shop.gd:718）末尾对 gamepad 模式补一次 `_refresh_context_controls()`（其自带 deferred grab 会正确接管）。备选（更窄）：tutorial `_render_step` 改 `_next.call_deferred("grab_focus")`——因 spawn 的 deferred 排队在前、后入队者后执行，可赢回顺序；但挡不住教学中途 scheme_changed 重偷，故推荐前者。

**预计改动面**：day_shop.gd 2 处共 ~4 行；input_check 增加断言「`_show_tutorial` 后连续 5 帧焦点属主仍在 tutorial_overlay 子树内」（+8 行）。

---

## 3. [S1] P12-F2 教学聚光灯对比度（代码层）

**判定：CONFIRMED**（WCAG 公式独立计算；并发现 4% 白叠层**轻微降低**而非提升对比度）

独立证据（Python 按 WCAG 2.x 相对亮度公式计算，输入为代码常量）：

- `tutorial_overlay.gd:60` 暗层 `Color(0.06,0.055,0.07,0.58)`；`:77` 聚焦框 `bg_color = Color(1,1,1,0.04)`；`:80` 描边 `MINT=27B9A7`；`:104` 进度标签 MINT 15px。
- 计算（前景 COCOA #30201D / 底 CREAM #FFF8ED，即 HUD 文字典型对）：
  - 无覆盖层：**14.74:1**；经 0.58 暗层：**3.65:1**（P12 报 3.60，一致）；
  - 聚焦框内（暗层之上再叠 4% 白）：**3.59:1**——即「聚光灯」不仅没有恢复亮度，还把对比度又降了 0.06（4% 白同时提亮前景与背景，前景本就更暗、提亮比例上更吃亏）。真开洞应恢复到 14.74。
  - MINT 描边对暗化底（纯 CREAM 假设）：**1.73:1**；P12 截图实测（含真实场景底色 (114,111,109)）2.15:1——两者都远低于 WCAG 1.4.11 图形对象 3:1，结论不变。
  - `:104` 进度标签 MINT on CREAM：**2.32:1**（15px 正常文字需 4.5:1）。
- 结构证实：`_focus` 是 ColorRect 的**子节点**（:84 `add_child`），绘制在暗层填充之上，只加不改——代码里不存在任何「开洞」机制。

**最小修复方案**：真开洞——把单一大 ColorRect 换成围绕 `_focus` 矩形的 4 块 ColorRect（上/下/左/右，`_render_step` 里按 focus rect 更新 4 块几何），聚焦区透出原始场景（对比度回到 14.74:1）；描边换 COCOA（对 CREAM 14.74:1）或保留 MINT 但加宽到 5px 并加深（如 #0E7A6C）；`:104` 进度标签 MINT→COCOA。若要更小的改动：暗层 alpha 0.58→0.30（对比度约 5.9:1）+ 描边 COCOA——但达不到「焦点区原亮度」的教学语义，列为降级方案。

**预计改动面**：tutorial_overlay.gd `_build`/`_render_step`/`_layout_overscan` 三处几何逻辑（约 +30 行重构）；无新资源。回归：input_check 或新增 pixel 探针断言「聚焦框中心像素与无教学时同位置像素亮度差 < 5%」。

---

## 4. [S1] P3-F1 夜间五张模态面板无焦点圈禁

**判定：CONFIRMED**（探针：1 次 D-pad 逃逸 + A 键真实改配方）

独立证据（`/tmp/v1_p3.log`）：

- `[F1] menu_board focus: .../@ColorRect@529/@PanelContainer@530/...`（打开后焦点在面板内关闭按钮）。
- `[F1] ui_down #1 ESCAPED to /root/NightLab/SafeFrame/@HBoxContainer@299/@PanelContainer@385/...`——**一次** `ui_down` 即穿出面板到遮罩下货架瓦片。
- `[F1] after A-press: cup_sugar <null> -> { "value": 50.0, "name": "五分糖" } (changed=true) panel_still_open=true`——A 键真实改了配方而菜单板仍开着。
- 代码：五面板遮罩均只 `MOUSE_FILTER_STOP`（menu_board_panel.gd:32、upgrade_panel.gd:27、endless_contract_panel.gd:28、staff_panel.gd:26、recipe_book_panel.gd:35）——STOP 只挡鼠标不挡焦点遍历（ColorRect 默认 focus_mode NONE，不参与也不拦截导航）；`night_lab.gd:705` `_on_tile` 无面板可见性守卫，改料即触发 `_invalidate_pending_shelf()`（:756-768，作废待上架分数）。

**最小修复方案**：统一圈禁助手（五面板 + pause_panel 共用）：`show_panel()` 时把面板内焦点链首尾相连（为面板内每个可聚焦控件设置 focus_neighbor_* 指回面板环），`hide_panel()` 恢复；或更省事的做法——`night_lab._input` 顶部：任一面板可见且 `gui_get_focus_owner()` 不在该面板子树时，`ui_accept`/`ui_*` 导航事件一律 `set_input_as_handled()` 并把焦点拉回该面板 `_close_button`。后者约 15 行覆盖全部五面板。

**预计改动面**：night_lab.gd +15 行（或每面板 +8 行 × 5）；input_check 增加五面板循环断言「打开后 16×ui_down/ui_right 焦点仍在面板内 + A 键不改 cup_sugar」。

---

## 5. [S1] P3-F2 手柄无法命名上架（LineEdit 无输入 + 空名静默）

**判定：CONFIRMED**

独立证据（`/tmp/v1_p3b.log` + 代码）：

- `[F2] empty-name shelf: tests 0 -> 0 note_visible=true name_row_visible=true`——空名提交后 `GameState.tests` 不增、便签卡原样保留，零反馈（`night_lab.gd:1099-1104` `recipe_name.is_empty(): return`，无 flash/无颜色变化）。
- `[F2] name_edit focus_mode=2 editable=true`——导航可达但无文字输入手段：全仓 grep `virtual_keyboard` 0 命中（本次核实），`night_lab.gd:377-386` 是裸 `LineEdit(max_length=40)` + 上架按钮，无候选名/无系统键盘调用。

**最小修复方案**：分层——(a) 必修：`_on_shelf` 空名分支加可见反馈（复用 `_set_result`/`_flash` + 新 locale 键 `NIGHT_NAME_REQUIRED`，`name_edit.grab_focus()`）；便签出现时（`name_row.visible=true` 处）焦点交给 `name_edit`。(b) 手柄完整路径：gamepad 模式下命名行旁加「候选名轮选」按钮（`MenuCatalog` 或新助手生成 3 个随机店名，左右切换）或默认名一键确认；`DisplayServer.virtual_keyboard_show` 只救移动端不救桌面手柄，不能作为唯一方案。

**预计改动面**：(a) night_lab.gd +6 行 + ui.csv 1 键；(b) +30~50 行（候选名生成 + UI）。回归：night_check 断言空名提交后出现提示文本、tests 不增。

---

## 6. [S1] P3-F3 升级/合约面板购买后焦点丢失

**判定：CONFIRMED**（探针：购买 → 焦点 null → D-pad 全死 → Tab 恢复到面板外）

独立证据（`/tmp/v1_p3b.log`）：

- `[F3] buy button '购买 · 60 金币'` 按下后 `coins 900 -> 840`（真实购买），`[F3] +1 frame after buy: <null>`、`+3 frames: <null>`。
- `[F3] after 4x dpad: <null>`——ui_down/ui_right/ui_up 全部无效（方向导航需要焦点属主）。
- `[F3] after ui_focus_next: /root/NightLab/SafeFrame/@HBoxContainer@12/...@Button@15`——唯一恢复路径 `ui_focus_next`（手柄无默认绑定）落点在**面板外**。
- 代码：`upgrade_panel.gd:119-127` 与 `endless_contract_panel.gd:127-131` `_refresh` 直接 `child.free()` 全部卡片（含持焦按钮），无 `_restore_focus`；对照 menu_board_panel.gd:462-464 / staff_panel.gd:107-109 / recipe_book_panel.gd:209-210 三处都有恢复约定。

**最小修复方案**：照抄约定——两面板 `_refresh` 末尾加 `if visible and is_inside_tree() and get_viewport().gui_get_focus_owner() == null: _close_button.grab_focus()`；进阶（可选）：`_on_buy`/`_sign` 前记录被操作卡片在 `_cards` 的索引，`_refresh` 后 focus 到同索引卡的动作按钮（与 P3-F8 的修法同一套）。

**预计改动面**：两文件各 +3~10 行；input_check/upgrade_check 断言「购买后 5 帧内焦点非空且在面板内」。

---

## 7. [S2] P3-F5 手柄族切换焦点偷逃；P3-F6 日间暂停 D-pad 逃逸

**判定：两项均 CONFIRMED**（各自独立探针）

独立证据：

- F5（`/tmp/v1_p3b.log`）：员工面板打开（`[F5] inside panel: true`，焦点在面板关闭按钮）→ `set_test_controller_family("playstation")` → 3 帧后 `[F5] after switch focus: .../@HBoxContainer@19/... target inside night lab shelf (first tile): true`、`still inside staff panel: false panel_visible=true`。代码 `night_lab.gd:683-685` `_on_input_scheme_changed` 无条件 `_first_tile.call_deferred("grab_focus")`，不检查任何面板可见性。
- F6（`/tmp/v1_misc.log`）：暂停打开（`paused=true`，焦点在面板内）→ `[F6] ui_down #6 escaped to .../@PanelContainer@100/@HBoxContainer@101/...`（备料面板 RB 按钮，遮罩下）→ `[F6] A on escaped focus: pearl_batch.active false -> false`——A 键被 `day_shop.gd:1001-1004` 的 `not running` 守卫拦截，玩家感知为死键（与 P3 描述完全一致：逃逸成立 + 无反馈）。

**最小修复方案**：F5：`night_lab._on_input_scheme_changed` 加守卫（任一面板可见则只 return，不动焦点；day_shop 侧 `_refresh_input_prompts` 本就不抢焦，行为已正确）。F6：pause_panel 并入第 4 条的统一圈禁助手；最低限度在 `_on_pearl_batch_pressed` 等守卫分支加一声 `Sfx.play("deny")` 或 `_flash(已暂停)` 提示。

**预计改动面**：F5 night_lab.gd +3 行；F6 并入圈禁助手（见第 4 条）或 +5 行提示。回归：input_check 断言「面板可见时族切换后焦点仍在面板内」。

---

## 8. [S3] P3-F7/F8/F9/F10 焦点顺滑类

**判定：四项全部 CONFIRMED（代码层）**

独立证据：

- F7：`staff_panel.gd:276-284` `_dismiss` 首按仅置 `_dismiss_armed` + `call_deferred("_refresh")`；`_refresh`（:95-109）在焦点随卡片销毁丢失时恢复到 `_close_button`（:107-109）而非重建卡上的「确认解雇」——连按 A = 关面板。机制与 menu_board 同约定，确定性强。
- F8：`menu_board_panel.gd:427-443`（`_toggle_item`/`_on_price_pressed`）→ `call_deferred("_refresh")` → `:462-464` `_restore_focus` 回关闭按钮；`:407-453` 四个动作入口全走此路径——每次策展操作焦点重置到右上角。
- F9：`grep -c "ui_cancel\|_unhandled_input" tutorial_overlay.gd` = **0**；事件简报只有 `event_start_button`（day_shop.gd:629-632 按钮仅连 `_dismiss_event_briefing`，无 cancel 路径）。夜间五面板都有 ui_cancel（upgrade_panel.gd:108-111 等），唯独这两处 B 键无效。
- F10：`day_shop.gd:694`（`_dismiss_event_briefing`）与 `:739`（`_resume_from_pause`）均 `pause_button.grab_focus()`——恢复后焦点在右上角暂停按钮而非制杯主线。

**最小修复方案**：F7：`_dismiss` 武装后让 `_refresh` 完成时 focus 重建卡片里的确认按钮（按 `STAFF_DISMISS_CONFIRM` 文本查找）；F8：`_refresh` 前记 `_cards` 中被操作卡索引，重建后 focus 同索引卡动作钮；F9：tutorial_overlay 加 `_unhandled_input`（可见且 `ui_cancel` → `_finish()` + set_input_as_handled），事件简报 `ui_cancel` 等同开始；F10：两处按状态路由——未封杯走 `_refresh_context_controls()` 的 deferred grab，已封杯走 `_focus_active_order()`，仅无主线时兜底 pause_button。

**预计改动面**：四项各 +5~15 行，无结构改动；F9/F10 可合并一个 PR。S3 严重度合理，无升级必要。

---

## 9. [S1] P10-1 触控目标 ~29pt（几何推算）

**判定：CONFIRMED**（代码几何封闭计算）

独立证据：

- `project.godot:41-44`：作者分辨率 1280x720 + `canvas_items`/`expand`；`safe_frame.gd:5` `AUTHORED_SIZE := Vector2(1280, 720)`；`:47` `fit_scale := minf(1.0, minf(usable.x/1280, usable.y/720))`——UI 缩放完全由可见区逻辑高度决定，无移动下限。
- 按钮 authored 尺寸（逐一核对源码）：情境原料 `Vector2(button_width, 54)`（day_shop.gd:1429）、摇茶 `Vector2(300, 58)`（:1367）、暂停 `Vector2(96, 52)`（:381-382）、重置 `Vector2(196, 54)`（:425-426）。
- 计算：844x390 → scale = min(0.659, 0.5417) = **0.542** → 54px→**29.2pt**、58px→31.4pt、52px→**28.2pt**；915x412 → 0.572 → 30.9/33.2/29.8pt。均 < Apple HIG 44pt / Android 48dp，约标准的 2/3。960x600（平板窗口）也只有 40.5/43.5/39.0pt，仍略低于 44。

**最小修复方案**：`safe_frame.gd:_fit_layout` 在 `OS.has_feature("mobile")` 时给 `fit_scale` 设下限。注意算术：54px 按钮要达到 44pt 需 scale ≥ 0.815，远超手机可视高度能容纳的 1280x720 布局——**单纯 clamp 缩放会把 HUD 挤出屏**，必须配合布局改动：触屏模式情境网格改 2 列大按钮（authored 高度提到 ≥72px）+ 缩放下限 ~0.68 组合，或提供手机专用布局变体。回归：mobile_render_check 增加断言「触屏主操作有效高度 ≥44pt」（对每个主按钮计算 `authored_size * scale`）。

**预计改动面**：safe_frame.gd +3 行；day_shop 情境面板触屏分支 +20~40 行（这是该 S1 真正的成本所在）；测试 +10 行。

---

## 10. [S2] P10-3 触觉真机退化；P10-4 触屏键盘泄漏

**判定：P10-3 NEEDS-FIX-SCOPE（Android 半段 CONFIRMED，iOS 半段措辞需修正）；P10-4 CONFIRMED**

独立证据：

- P10-3 Android：`export_presets.cfg` preset.2 `[preset.2.options]`（:65-77）无任何 `permissions/*` 条目，`grep VIBRATE` 0 命中。Godot 4.4 官方文档（docs.godotengine.org Class Input → vibrate_handheld）："For Android, vibrate_handheld() requires enabling the `VIBRATE` permission in the export preset… Otherwise, vibrate_handheld() will have no effect."——Android 构建触觉**全静默**成立，且唯一落点 `haptics.gd:43` 无平台分支。
- P10-3 iOS：**对 P10 的措辞提出修正**。官方文档明确 "specifying the duration is only supported in iOS 13 and later"——即 iOS 13+ 上 **duration 是生效的**，18/22/46/76/112/148ms 六档在时长维度仍可区分；被忽略的是 amplitude（强度维度，iOS 平台不支持自定义）。P10 所述「iOS 后端忽略 duration/amplitude（AudioServicesPlaySystemSound 单一固定脉冲）全部变成同一下」是旧引擎/旧系统行为，对现代 iOS 不成立。**调整后严重度建议**：维持 S2（Android 无权限=整层功能静默已足够 S2），但修复描述改为「Android 补 VIBRATE 权限；iOS 损失的是强度维度而非全部差异，18-46ms 档位过近仍建议改节奏型编码」。
- P10-4 泄漏点逐一核实（4 处）：
  1. `day_shop.gd:1428` 情境按钮文案仅分支 `gamepad_mode`，触屏显示 `"%d  %s"` 键盘编号（探针 D1 输出 `target button='1  阿萨姆'` 直接证实）；
  2. `ui.csv:331` `TUTORIAL_3_HINT`「按钮前的数字对应键盘 1–9」无触屏分支；
  3. `tutorial_overlay.gd:168-170` 第 4 步非手柄提示注入 `shake_hint()`=键名（ui.csv:334/340 的 `%s键`）——**细微修正**：该文案本身含「手机：摇晃设备」分支语，键盘键只是并列泄漏，严重度略低于另两处；
  4. `pause_panel.gd:515-527` 三处 `SETTINGS_CONTROLS_*_KEYBOARD` 在非 gamepad（含触屏）一律输出 Q/E/空格/F/Esc 键名。
  - 反例坐实「不一致而非设计」：`_shake_button_text`（day_shop.gd:1392-1397）已有 `OS.has_feature("mobile")` 正确分支（DAY_SHAKE_BUTTON_MOBILE「点击 / 摇匀」）。

**最小修复方案**：P10-3：preset.2 options 增加 `permissions/vibrate=true`；`export_config_check.gd` 加断言（该测试已存在，是现成钉位）。P10-4：`_add_context_button` 编号前缀加 `not OS.has_feature("mobile")` 条件；ui.csv 增 `TUTORIAL_3_HINT_TOUCH` 与 `SETTINGS_CONTROLS_*_TOUCH`；tutorial 第 4 步触屏提示用无 `%s` 变体。

**预计改动面**：export_presets.cfg +1 行；day_shop.gd +2 行；ui.csv +4~6 键；pause_panel/tutorial_overlay 分支各 +2 行；input_check 补 mobile 文案断言（现有 :239 已有同类断言模式可循）。

---

## 11. [S3] P10-5 小料罐间距；P10-6 orientation 180° 翻转

**判定：两项均 CONFIRMED（配置/几何层）**

独立证据：

- P10-5：`shop_stage.gd:288`（本次核实实际行号 287-289）`Vector3(-0.95 + i * 0.24, COUNTER_TOP_Y, 0.48)`——罐心距 0.24；`:320`（实际 319-321）`CylinderShape3D radius = 0.11`——圆柱直径 0.22 < 间距 0.24，边隙 0.02 世界单位。乘手机 scale 0.542 后（投影比例近似）目标 ≈29pt、边隙 ≈1pt 量级，低于手指定位精度。低严重度认定合理（顶部情境按钮是冗余兜底）。
- P10-6：`project.godot:45` `window/handheld/orientation=4`（SENSOR_LANDSCAPE，允许两横朝向自动旋转）；export_presets.cfg 无任何平台朝向覆盖（grep 无果）；`input/shake_gesture.gd` 重力校准只在首样本（P10 已核）。配置证据确凿；翻转是否真的被甩动触发属真机系统行为，维持 S3 与「置信度中」的原判合理。

**最小修复方案**：P10-5：触屏模式罐体拾取半径乘 `1.0 / SafeFrame 缩放`（保证屏幕上有效目标 ≥44pt）或拉大罐距；P10-6：`orientation=4`→`0`（固定横屏）一行改动；若要保留传感器横屏，则 `_can_gesture_shake()` 为真期间 `DisplayServer.screen_set_orientation(...)` 锁定。

**预计改动面**：P10-5 shop_stage.gd +5 行；P10-6 project.godot 1 行。均为 S3 批次。

---

## 12. [S3] P11-F2 改键守卫只护 Q/E；P11-F3 教学重看不重置门控；P11-F4 菜单板每次点击全量落盘

**判定：三项全部 CONFIRMED**

独立证据：

- F2（`/tmp/v1_misc.log` 运行时实测）：`conflict_for(game_shake, KEY_1)=''`、`(game_shake, KEY_9)=''`、`(staff_interact, KEY_ENTER)=''`（全部放行）、`(game_shake, KEY_Q)='prep_tea'`（守卫本体有效）。代码 `input_prompts.gd:76-85` 仅查 DEFAULT_KEYS 互撞 + FIXED_KEYS(Q/E)，无数字/Enter/Tab。
- F3（`/tmp/v1_misc.log`）：首轮门控两连败后 `bypassed=true`→`_finish()`→重看 `_show_tutorial(true)` → `[P11F3] after replay start: bypassed=true fails=0 step=0`——**bypassed 跨重看持久**；`tutorial_overlay.gd:138-143` `start()` 只重置 `_replay`/`_step`；`:238` `_step_completed()` 对 `bypassed` 短路返回 true（免练习通过）；`:152-153` 附注常驻。次级残留同样成立：`_gate_fails` 仅在放行/通过时清零（:251），首轮败 1 次后跳过的玩家重看只剩 1 次机会。
- F4：`menu_catalog.gd` 四个写方法 `persist := true` 默认且内部 `GameState.save_game()`（`set_featured` :150-169、`set_item_price` :238-246、`install_dark_candidate` :433-448、`remove_dark_slot` :453-459）；`menu_board_panel.gd:407-453` 四处调用全部不传第三参。每次点击 = 全量原子写（临时文件+回读+备份+回读+双 rename）。

**最小修复方案**：F2：`conflict_for()` 增补保留集 `KEY_1..KEY_9`、`KEY_ENTER/KEY_KP_ENTER/KEY_TAB`（Space 已是 shake 默认、改绑时自然互撞），`game_state.gd` 加载端归一化（:597-614 一带）同步；release_settings_check 补三条断言。F3：`start()` 加 `_gate_fails = 0` 与 `_gate_bypassed = false` 两行；onboarding_check 补「重看后门控步 `_step_completed()` 为 false（未做练习时）」断言。F4：菜单板四处调用改 `persist=false`，面板 `hide_panel()` 与 `_return_to_menu` 路径强制落盘一次；或复用 pause_panel 的 generation 防抖（`pause_panel.gd:337-345` 已有注释与实现可抄）；menu_catalog_check 统计 `save_game` 调用次数断言 ≤1/次开关面板。

**预计改动面**：F2 input_prompts.gd +8 行 + game_state.gd +4 行；F3 tutorial_overlay.gd +2 行；F4 menu_board_panel.gd +8 行（或 +15 行带防抖）。三项均 S3，改动小、可合批。

---

## 13. [S2] P12-F3 减弱动态「创建时」门控（日内开启后存量动画不停）

**判定：CONFIRMED**（时间序列探针：开关后 bob 仍在动）

独立证据（`/tmp/v1_misc.log`）：

- 加店员与顾客后（reduced_motion=false）：`[P12F3] before toggle y=0.0053 (moved=true)`（StaffBob 节点 y 已离开 0）。
- `pause_panel._on_motion_toggled(true)` 后：`[P12F3] reduced_motion now=true` → 1.6 秒采样 `[P12F3] after toggle: bob keeps moving=true samples=[0.00560, 0.00576, 0.00592, 0.00609, 0.00626, 0.00643, 0.00660, 0.00678...]`——位置持续单调变化，**存量 loop 未被停止**。
- 代码：所有门控在创建点读一次 `GameState.reduced_motion()`（`shop_stage.gd:526-529` 店员 bob、`:609-629` 顾客 bob/look/hop 三个 `set_loops()` tween）；tween 引用是局部变量、无 kill 路径；`set_staff_state`（:538）只处理位移动画；**全仓不存在任何 reduced-motion 变更信号**（game_state.gd 只有 :569-570 的 getter，无 signal；shop_stage 无相关 connect）。

**最小修复方案**：`GameState` 增加 `reduced_motion_changed` 信号（pause_panel toggle 处 emit）；`shop_stage` 监听并在回调里 kill 存量 loop——创建时把 loop tween 存进节点 meta（如 `_staff_bob.set_meta("idle_tweens", [bob])`、顾客 `actor/BobRoot/GestureRoot` 同理），回调里遍历 `kill()`。或者更简单：toggle 回调里对店员 `remove_staff()` + `add_staff()`、对在场顾客 `remove_customer()` + `add_customer()`（重创建路径在 reduced_motion 下直接静态就位，:601-603 已有该分支）——代价是顾客位置瞬移，可接受性需产品判断；推荐 meta 方案。

**预计改动面**：game_state.gd +3 行；pause_panel.gd +1 行 emit；shop_stage.gd +15 行（meta 存取 + kill）。回归：input_check 或新探针断言「toggle 后 1 秒内 StaffBob.position.y 方差为 0」（本次探针代码可直接改造为断言）。

---

## 14. [S2] P12-F6 无字号缩放选项

**判定：CONFIRMED**（确认即可，未跑探针）

独立证据：`grep -rn "font_scale|ui_scale|text_size|font_size_scale|FONT_SCALE|UI_SCALE|TEXT_SIZE"` 于 game/（gd/csv/godot，排除 tests）**零命中**；ui.csv SETTINGS_* 键全集只有：音量×2（隐含）、SETTINGS_MOTION、SETTINGS_HAPTICS、SETTINGS_DISPLAY（窗口模式/分辨率/改键/重置键）——设置面板（pause_panel.gd）确无任何文字大小档。最小字号盘点与 P12 一致：`day_shop.gd:803` hud_cost 10px、`recipe_book_panel.gd:290` 11px 搭配格（:334 熟练度有 tooltip、:290 无）。

**最小修复方案**：设置加「文字大小」两档（100%/125%）：最小实现是对 SafeFrame 根控件的 `scale` 乘一个 `GameState.font_scale()`（SafeFrame._layout 已集中管理 scale，:18-24，是唯一改动点），并接受 125% 下 HUD 布局重排验证；或 AppTheme.build 接受 font_size 乘数。顺手项：11px 搭配格补 tooltip、hud_cost 10→12px。

**预计改动面**：safe_frame.gd +6 行 + pause_panel 设置行 +10 行 + ui.csv 2 键 + 布局回归（mobile_render_check 的重叠断言在 125% 下重跑）。S2 维持。

---

## 附：探针与日志清单

| 探针 | 覆盖条目 | 日志 |
|---|---|---|
| `/tmp/v1_probe_d1.gd`（窗口 1280x720） | D1 全链路 A-G | `/tmp/v1_d1.log` |
| `/tmp/v1_probe_p3.gd`（headless） | P3-F4、P3-F1 | `/tmp/v1_p3.log` |
| `/tmp/v1_probe_p3b.gd`（headless） | P3-F3、P3-F5、P3-F2 | `/tmp/v1_p3b.log` |
| `/tmp/v1_probe_misc.gd`（headless） | P3-F6、P11-F2、P11-F3、P12-F3 | `/tmp/v1_misc.log` |

对比度/触控目标计算：本次报告第 3、9 节内嵌 Python 计算结果（WCAG 2.x 相对亮度公式 + SafeFrame 等比缩放模型），未依赖前代理数据。
iOS vibrate_handheld 行为引据：[Godot 4.4 Class Input 文档](https://docs.godotengine.org/en/4.4/classes/class_input.html)（Android 需 VIBRATE 权限否则无效果；iOS duration 仅 iOS 13+ 支持）。
