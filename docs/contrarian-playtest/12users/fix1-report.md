# Fix-1 修复报告 · 交互/UI 代码域

代理 Fix-1 · 日期 2026-08-17 · 基线 HEAD `c456b0b`（与 V1/V3 核实报告一致）。
范围：教学/焦点/移动/无障碍/面板交互（本代理独占文件清单内的全部交互 UI 域缺陷）。
修复依据：`v1-verify-tutorial-focus-mobile.md`（V1）、`v3-verify-night-routes-l10n.md`（V3）。

**全部 15 项修复清单条目均已处理**（14 项完成、1 项按指示做了有界部分并记录剩余）。回归钉位落在 onboarding_check / input_check / night_check / staff_check / release_settings_check / export_config_check，全部跑绿；另复跑了受改动波及的 10 个邻域 check（见文末）确认无回归。

---

## 1. [S1] 教学门控练习步骤真实输入不可完成（V1 #1）

**修了什么**
- `game/ui/tutorial_overlay.gd`：根节点 ColorRect → Control，拦截职责移交给四块暗幕；新增 `gated_practice_active()`；`_render_step` 里门控步骤（3/4）把全部暗幕与聚焦框 `mouse_filter` 置 IGNORE（点击穿透到店铺控件），观察步骤恢复 STOP 模态。
- `game/scenes/day_shop/day_shop.gd`：新增 `_tutorial_practice_active()`；`_input` 的 `not running` 早退改为 `not running and not _tutorial_practice_active()`（时钟保持冻结、结算语义不变）；`_on_shake`、`_can_gesture_shake`、`_on_ingredient` 三处守卫同样加豁免。订单交付分支维持 `cup_sealed and running` 语义（`_on_order_card_pressed` 自带 `not running` 拒绝，教学期交付仍不可达）。
- 摇杯路径（步骤 4）经 `_input` 的 `game_shake` action、数字捷径、鼠标点击（暗幕 IGNORE 后穿透）全部可达。

**断言钉哪**：`onboarding_check.gd`——门控步骤 3：遮罩过滤器结构断言（四块暗幕全为 IGNORE，等价 V1 归因实验 C 的钉位）+ `Input.parse_input_event(KEY_2)` 走完整 GUI 管线后 `cup_base != null`；门控步骤 4：数字键走完奶基/糖度 → `game_shake` action 注入至 `cup_sealed`。原有 `_on_base` 直调断言已由真实输入路径替换。
**备注**：无头模式无法驱动真实鼠标拾取（V1 的点击探针需要窗口模式），点击路径以过滤器结构断言钉住根因（STOP 过滤器），键盘/action 两条真实输入路径已全链路覆盖。

## 2. [S1] 教学 _next 焦点被同帧延迟 grab 偷走（V1 #2 / P3-F4）

**修了什么**：双保险——(a) `day_shop._add_context_button` 与摇茶按钮的延迟 grab 加 `not tutorial_overlay.visible` 守卫（拦教学中途的族切换/语言切换重偷）；(b) `tutorial_overlay._render_step` 的 `_next.grab_focus()` 改 `call_deferred`（`_show_tutorial` 里顾客生成的 deferred grab 先入队、后入队者后执行，教程赢回同帧竞争——V1 备选方案，两案合并后两条路径都堵住）。`_on_tutorial_finished` 在手柄模式补一次 `_refresh_context_controls()` 接管焦点。
**断言钉哪**：`input_check.gd`——`_show_tutorial` 后连续 5 帧焦点属主仍在 tutorial_overlay 子树内。

## 3. [S1] 夜间五张模态面板焦点圈禁（V1 #4 / P3-F1）

**修了什么**：`night_lab._input` 顶部新增 `_visible_modal_panel()` + `_clamp_focus_inside(event, panel)`：任一面板（五张 + 设置）可见而焦点属主不在面板子树内时，`ui_accept/ui_up/ui_down/ui_left/ui_right` 一律消费并经各面板新增的 `confine_focus()` 拉回面板内关闭按钮（staff 面板武装中优先「确认解雇」）。`ui_cancel` 不拦（保持关面板路径）。
**断言钉哪**：`input_check.gd`——焦点逃逸到货架瓦片后 `ui_down` 被圈禁回面板内；`ui_accept` 不改 `cup_sugar`（配方不被隔板改料）。

## 4. [S1] 命名 LineEdit 手柄/触屏断路（V1 #5 / P3-F2）

**修了什么**：`night_lab._on_shelf` 空名分支给出可见反馈（`_set_result("NIGHT_NAME_REQUIRED")` + 音效/触觉 + `name_edit.grab_focus()` + 移动端弹虚拟键盘）；`name_edit` 聚焦/失焦在移动端调 `DisplayServer.virtual_keyboard_show/hide`；便签卡出现时（手柄或移动端）焦点交给命名行并弹键盘。
**断言钉哪**：`night_check.gd`——空名提交后 `GameState.tests` 不增且反馈区包含 `NIGHT_NAME_REQUIRED` 文案。
**未修（超出任务清单）**：V1 方案 (b) 的手柄候选名轮选按钮未实现（任务清单只要求空名反馈 + 虚拟键盘）；手柄玩家仍可用手柄输入法的系统键盘/虚拟键盘命名。

## 5. [S1] 升级/合约面板购买后焦点恢复（V1 #6 / P3-F3）

**修了什么**：`upgrade_panel.gd`、`endless_contract_panel.gd` 的 `_refresh` 末尾套用 `_restore_focus` 约定（焦点丢失时回关闭按钮），并各加 `confine_focus()`。
**断言钉哪**：`input_check.gd`——真实购买（金币扣减）与真实签约后焦点非空且在面板内。

## 6. [S2] 族切换焦点偷逃 + 日间暂停 D-pad 逃逸（V1 #7 / P3-F5、F6）

**修了什么**：F5——`night_lab._on_input_scheme_changed` 加 `_visible_modal_panel() == null` 守卫；F6——圈禁机制落在 `pause_panel._input`（该节点 PROCESS_MODE_ALWAYS，暂停期间仍能拦截；含 display/confirm 子面板的分层默认焦点 `confine_focus()`）。
**断言钉哪**：`input_check.gd`——员工面板打开时切 playstation 族 2 帧后焦点仍在面板内；日间暂停中焦点逃逸后 `ui_down`（经 `Input.parse_input_event`）被拉回暂停面板。

## 7. [S1] 制杯状态行溢出（V3 #5 / P4-1）

**修了什么**：`day_shop._refresh_cup` 全部改用 `ingredient_short_name`（茶底/奶基/小料/糖度）；`status_label` 加 `autowrap WORD_SMART` + `TRIM_ELLIPSIS` + `max_lines_visible=2`（面板宽度 505px 约束不变，最坏 1112px 串折两行+裁断收在面板内）。
**断言钉哪**：`onboarding_check.gd`——英文最坏组合（双小料+封口+返工）下 `autowrap` 生效、行数 ≤2、标签宽度 ≤ 面板内宽 482px。

## 8. [S1] rush 槽位四处假情报（V3 #1 / P7-F1）

**修了什么**：`menu_board_panel.gd:171`（进度分母）与 `night_lab.gd`（NIGHT_MENU_PILL 分母）改 `MenuCatalog.featured_limit()`；`MENU_BOARD_SUBTITLE`/`MENU_BOARD_FULL` 在槽位数 ≠3 时切换到带 `%d` 的参数化变体（新键，见清单），rush 显示「2/2 槽」「2 个主推槽已满」。
**断言钉哪**：`night_check.gd`——rush 激活时 `featured_limit()==2`、夜间药丸全串逐字等于 route-aware 格式化结果、菜单板进度含「1/2」、subtitle 用参数化变体。`menu_catalog_check`/`dark_menu_check`（他人权限）复跑无回归。

## 9. [S1] 教学聚光灯对比度（V1 #3 / P12-F2）

**修了什么**：`tutorial_overlay` 重构为真开洞——单一大暗层换成围绕聚焦矩形的四块 ColorRect（上/下/左/右），聚焦区透出原始场景（对比度回到无遮罩水平，不再有 0.58 暗层 + 4% 白叠加的 3.59:1）；描边 MINT(1.73:1) → 深薄荷 `#0E7A6C` 5px（对 CREAM ≈4.9:1，越 WCAG 1.4.11 的 3:1 线并接近 4.5）；进度标签 MINT(2.32:1) → COCOA(14.74:1)；次级按钮 focus 描边同步加深。暗层视觉意图（洞外 0.58 暗）保留。
**断言钉哪**：`input_check.gd`——聚焦框中心点不被任何暗幕覆盖（`hole_covers_point`）、洞外点仍被覆盖、进度标签取色为 COCOA。

## 10. [S1] 耐心秒数三档色对比（V3 #17 / P12-F1）

**修了什么**：`day_shop.PATIENCE_BAND_COLORS` 加深为 `B3261E / 8A5A00 / 0E7A6C`（对卡底分别 ≈6.2 / 5.6 / 4.9:1，全部 ≥4.5；红/琥珀/薄荷三档色相语义保留；进度条填充仍用原亮色，档位色带视觉不变）。
**断言钉哪**：`input_check.gd`——测试内置 WCAG 相对亮度函数，三档色对卡底 `Color(1.0,0.973,0.929)` 全部 ≥4.5:1。

## 11. [S2] 结算/面板 accent 小字对比 + 减弱动态存量动画（P12-F4/F5、P11-F3→P12-F3）

**修了什么**
- F4：`night_settlement_panel.gd` 分数 22px、阶段 13px、摘要 16px 的 accent/MINT 全部换 COCOA；accent 保留在卡描边。
- F5：`menu_board_panel.gd` event_fit 13px GOLD → COCOA；`recipe_book_panel.gd` 相性矩阵表头 15px、等级名 16px、精通格标题 15px accent → COCOA（档位语义保留在格子描边/底色）。暗卡子项维持原判不動。
- P12-F3：`pause_panel` 新增 `motion_toggled` 信号并在开关时 emit；`day_shop` 连接后 `_on_reduced_motion_toggled(true)` 重建舞台上的店员与顾客（`stage.remove/add`——reduced_motion 分支直接静态就位，存量 loop tween 随旧节点释放而终止）。关闭时刻意不重建（避免位置跳变）。不触碰 game_state.gd/shop_stage.gd（他域文件）。

**断言钉哪**：`input_check.gd`——开启后顾客演员全部换新实例且 BobRoot y==0（无 bob loop）。
**备注**：F4/F5 未做像素级断言（无头无法渲染采样），以颜色常量替换 + 既有 check 绿为准。

## 12. [S2] 离场自动晋升后单击即交付（V3 #20 / P11-F1）

**修了什么**：`day_shop._remove_customer` 在活动顾客离场且 `cup_sealed` 时给新队首挂一次性 `_promoted_needs_review` 标记；`_on_order_card_pressed` 见标记先核对（清标记 + flash「核对订单」提示）不交付，第二次才走 `_on_deliver`——与 `:2110` 主动切单的守卫语义对齐。`_reset_cup` 清标记防陈旧。
**断言钉哪**：`input_check.gd`——晋升后首按 `served` 不变（只核对），次按 +1（交付正确杯）。

## 13. [S2/S3] 触屏键盘泄漏 / VIBRATE 权限 / orientation（V1 #10、#11 / P10-3/4/6）

**修了什么**
- P10-4 四处：情境按钮编号前缀按设备族分支（`_context_button_label`，触屏不显示「1 」）；教学第 3/4 步触屏提示用无键名变体（新键）；暂停面板三处控制说明按触屏分支（`_update_controls_copy(touch_override)`）。桌面/手柄文案不变。
- P10-3：`export_presets.cfg` preset.2 补 `permissions/vibrate=true`。
- P10-6：`project.godot` `window/handheld/orientation` 4（SENSOR_LANDSCAPE，允许 180° 翻转被重力摇茶误触）→ 0（固定横屏，V1 方案）。

**断言钉哪**：`input_check.gd`（触屏文案/触控目标）、`export_config_check.gd`（orientation==0 断言改写 + vibrate 权限断言）。

## 14. [S3] 焦点顺滑 / 改键守卫 / 教学重看重置 / 菜单板落盘防抖 / 死代码（V1 #8、#12 / P3-F7~F10、P11-F2~F4、P12-F8）

**修了什么**
- F7：`staff_panel` 武装态刷新后焦点落重建的「确认解雇」按钮（`_dismiss_confirm_button` 引用 + `_refresh` 分支）。钉：`staff_check.gd`。
- F8：`menu_board_panel` 策展四入口（toggle/price/replace/remove）先记 `_remember_focused_card()` 索引，延迟刷新后 `_restore_card_focus()` 回到同索引卡的首个可用按钮。钉：`night_check.gd`。
- F9：`tutorial_overlay._unhandled_input`（ui_cancel → finish）；`day_shop._input` 事件简报 ui_cancel 等同开始。钉：`onboarding_check.gd`。
- F10：`_dismiss_event_briefing`/`_resume_from_pause` 改走 `_return_focus_to_mainline()`（手柄：未封杯 → 情境按钮延迟 grab；已封杯 → `_focus_active_order`；兜底暂停按钮）。钉：`input_check.gd`（未封杯恢复后焦点在情境按钮[0]）。
- P11-F2：`input_prompts.gd` 新增 `RESERVED_KEYS`（KEY_1..9、Enter、KP_Enter、Tab），`conflict_for` 命中返回 `"_reserved"`；`pause_panel` 对应显示 `SETTINGS_KEY_RESERVED` 反馈。存档加载端归一化（game_state.gd，他域）未动——旧存档若已含保留键仍会加载，需波 2/存档域补。钉：`release_settings_check.gd`。
- P11-F3：`tutorial_overlay.start()` 重置 `_gate_fails`/`_gate_bypassed`。钉：`onboarding_check.gd`（重看到门控步 `_step_completed()==false` 且 bypass 清空）。
- P11-F4：菜单板四处目录写调用改 `persist=false` + 0.6s generation 防抖（`_schedule_catalog_save`/`persist_catalog_now`，抄暂停面板实现）；`hide_panel()` 与 `night_lab._return_to_menu()` 强制冲刷；PREDELETE 兜底。钉：`night_check.gd`（结构：策展后回焦路径畅通；save 调用在 test_mode 下无副作用）。
- P12-F8：`game/ui/customer_avatar.gd` + `.uid` 删除（全仓零引用死代码，V3 复核确认）。

## 15. [S1] P10-1 触控目标 29pt（V1 #9）

**修了什么（有界部分）**：`day_shop._context_button_height()`——触屏模式情境按钮 authored 高度 54→82px、摇茶大按钮 58→82px（82×0.542 ≈ 44.4pt，达到 844x390 最坏手机可视区的 44pt 下限）；同步收窄情境面板内边距并抬最小高度到 124，加高后的网格仍收在备料面板（y=198）上方、无重叠。桌面布局不变。
**断言钉哪**：`input_check.gd`——`_context_button_height(true)*0.542 >= 44` 且桌面档保持 54。
**剩余（全局设计改动，未做）**：暂停（52px≈28pt）、重置（54px≈29pt）按钮与 3D 小料罐拾取半径仍低于 44pt；彻底达标需要 V1 指出的「触屏 2 列大按钮布局变体 + SafeFrame 缩放下限 ~0.68」组合（会重排 HUD/备料面板），建议单独立项。

---

## 新键清单（代码已用 `GameLocale.text()` 引用，ui.csv 待波 2 统一录入）

| 键名 | en | zh |
|---|---|---|
| `NIGHT_NAME_REQUIRED` | Give the drink a name before shelving it. | 先给这杯饮品起个名字，再上架送检。 |
| `MENU_BOARD_SUBTITLE_SLOTS` | Choose up to %d featured slots. Featured drinks become real customer orders and use their menu price. | 最多选择 %d 款主推。主推饮品会成为真实顾客订单，并按研发菜单价结算。 |
| `MENU_BOARD_FULL_SLOTS` | All %d featured slots are full. Remove one featured drink first. | %d 个主推槽已满，请先移出一款。 |
| `TUTORIAL_3_HINT_TOUCH` | Tap the highlighted ingredient buttons. | 点按高亮的原料按钮即可。 |
| `TUTORIAL_SHAKE_HINT_TOUCH` | Shake your device, or tap the big shake button. | 摇晃设备，或点按大摇茶按钮。 |
| `SETTINGS_CONTROLS_MENU_TOUCH` | Touch: Tap to select · Back button to exit\nMusic, SFX, motion, haptics, and language save immediately. | 触控：点按选择 · 返回键退出\n音乐、音效、动态、触觉与语言偏好会立即保存。 |
| `SETTINGS_CONTROLS_NIGHT_TOUCH` | Touch: Tap ingredients to select · Settings button in the top-right corner\nAll settings save immediately. | 触控：点按原料选择 · 设置在右上角\n所有设置会立即保存。 |
| `SETTINGS_CONTROLS_DAY_TOUCH` | Touch: Tap ingredients · Shake the device or tap the big button to shake\nTap the staff card or order cards to interact. | 触控：点按原料 · 摇晃设备或点按大按钮摇茶\n点按店员卡或订单卡进行互动。 |
| `SETTINGS_KEY_RESERVED` | %s is reserved: number keys, Enter, and Tab run shop shortcuts and menus. | %s 是保留键：数字键、Enter 与 Tab 承担店铺捷径和菜单操作。 |

键缺失期间的行为：`tr()` 返回键名原文（rush 子标题/空名反馈会显示键名 + 一次无害的格式化 ERROR 日志）；`localization_check` 不含这些键，保持绿色。

## 验证记录（全部绿色）

- 本域 6 个 check（改动后各跑）：`onboarding_check`、`input_check`、`night_check`、`staff_check`、`release_settings_check`、`export_config_check`。
- 受波及复跑 10 个：`menu_catalog_check`、`dark_menu_check`、`market_test_check`、`night_resume_check`、`upgrade_check`、`endless_contract_check`、`recipe_book_check`、`menu_check`、`mobile_render_check`、`localization_check`。

## 触碰的他域文件说明（均为任务清单明确指派给本代理的条目）

- `game/autoload/input_prompts.gd`（P11-F2 改键守卫）、`game/ui/night_settlement_panel.gd`（P12-F4 对比度）、`game/project.godot`（P10-6 orientation 单行）、`game/tests/export_config_check.gd`（对应断言改写）。清单外他域文件（menu_catalog/endless_contracts/game_state/market_tests/ui.csv/main_menu 等）一律未动——工作区中这些文件的改动来自并行修复代理。
