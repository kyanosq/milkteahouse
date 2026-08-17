# P3 手柄专注

视角：全流程只用手柄（Xbox/PS/Switch Pro）的玩家。审查面：导航、焦点、按键提示的真实手柄体验——日间制杯/交付双确认、封口焦点跳转、夜间货架/图鉴/菜单板 D-pad 导航、模态面板焦点圈禁、手柄族切换时提示与焦点的即时刷新、夜间试做→上架命名对话框（LineEdit）的可达性与确认路径、合约/员工/升级面板焦点入口。引擎 Godot 4.6.3，仓库 `game/`。

方法：无头 `input_check.tscn` 全绿（`passed actions=5 families=4 … focus_ring=4px`）；4 个只读运行时探针（`-s /tmp/p3_probe*.gd`，SceneTree 驱动真实场景 + `InputEventAction` 模拟 D-pad/A 键，逐帧读 `gui_get_focus_owner()`）；3 张窗口模式截图（sealed-review/xbox、menu-board/playstation、tutorial-step3/nintendo，`/tmp/p3_*.png`）+ PIL 像素定位焦点环（#30201D 4px；纯色采样被可可色文字污染，改用长行程/垂直边扫描）。手柄族字形与动作映射由 input_check 断言背书。

## 发现（证据/复现/期望vs实际/修复方向/置信度，S0-S3）

### F1 (S1) 夜间模态面板没有焦点圈禁：D-pad 一次就穿到遮罩下的控件，A 键真实生效

- 证据：`game/ui/menu_board_panel.gd:32`、`upgrade_panel.gd:27`、`endless_contract_panel.gd:28`、`staff_panel.gd:27`、`recipe_book_panel.gd` 全屏 `ColorRect` 只设 `mouse_filter = STOP`（挡鼠标不挡焦点导航）；`night_lab.gd` 打开面板时不暂停、`_on_tile`（:705）无"面板可见"守卫。
- 复现（探针 3）：gamepad 模式夜间 → `_open_menu_board()` → 焦点在关闭按钮 → 按 1 次 `ui_down` → 焦点落到遮罩下货架"五分糖"瓦片 → 按 A → `cup_sugar` null→50（配方被改），菜单板仍打开。探针 1：升级面板 12×down 逃逸到"五分糖"；探针 2：合约面板 14×down 逃逸到底部"经营委托"按钮。
- 期望 vs 实际：期望模态期间 D-pad 只在面板内移动、A 只作用于面板；实际遮罩下的研发室控件可被聚焦且可被 A 激活——改配方会连带作废待上架分数（`_invalidate_pending_shelf`），试做按钮甚至能在面板后扣灵感。玩家视角是"看不见的焦点环在动、按 A 出现灵异结果"。
- 修复方向：面板打开时做焦点圈禁（把面板内一个控件设为整组 focus 邻居的环，或临时把背景控件 focus_mode 置 NONE / 面板独占式 `set_focus_owner` 方案）；或在 `night_lab._input` 里对 `ui_accept`/`ui_*` 做面板可见性门控。五张面板共用一套圈禁助手即可。
- 置信度：高（三个面板复现 + 后果实证）。

### F2 (S1) 纯手柄无法完成"试做→上架"命名：LineEdit 无文本输入手段，空名提交完全静默

- 证据：`game/scenes/night_lab/night_lab.gd:377-388` 命名行是裸 `LineEdit`（`max_length=40`）+ 上架按钮；全仓库无 `virtual_keyboard` 调用，桌面 `FEATURE_VIRTUAL_KEYBOARD=false`（探针 2 实测）；`_on_shelf`（:1099-1104）空名 `return` 无任何反馈。
- 复现（探针 2）：手柄模式试做达上架分 → 便签卡出现命名行，焦点仍留在试做按钮（无 handoff）；D-pad 可走到 LineEdit（`focus_mode=2`，导航本身可达，探针轨迹命中 `LineEdit` 与上架按钮）——但手柄没有任何输入文字的手段；把焦点放上架按钮按 A：便签卡原样保留、反馈文本不变、`GameState.tests` 不增加（静默失败）。
- 期望 vs 实际：期望"手柄与键鼠拥有相同的完整经营流程"（TUTORIAL_GAMEPAD_5 文案原话）；实际自创配方/市场检验这条成长循环在纯手柄下断路——分数作废倒计时内既打不出名字也得不到任何错误提示。
- 修复方向：任选其一——(a) 手柄模式下命名改为候选名轮选（随机生成 3 个可 D-pad 选择的店名）或"确认使用默认名"；(b) 接系统虚拟键盘；(c) 至少先做空名提交的可见提示（闪现"请输入名字"）。另建议命名行出现时把焦点交给 LineEdit/上架按钮。
- 置信度：高（导航可达 + 输入不可达 + 静默失败三段实证）。与 P5"定价未本地化/结算卡断裂"不同题。

### F3 (S1) 升级/合约面板购买后焦点丢失，手柄 D-pad 随即完全失效

- 证据：`game/ui/upgrade_panel.gd:119-127` 与 `endless_contract_panel.gd:127-131` 的 `_refresh` 直接 `child.free()` 全部卡片——含持有焦点的购买/签约按钮，且这两个面板没有 menu_board（:462-464）/staff（:107-109）/recipe_book（:209-210）都有的 `_restore_focus` 约定。`_on_buy`/`_sign` 都走 `call_deferred("_refresh")`。
- 复现（探针 1/2/4）：gamepad 打开升级面板 → 焦点第一张卡购买键 → A 购买（金币 500→440）→ 5 帧后 `gui_get_focus_owner()==null`；随后 `ui_down`×2、`ui_right`、`ui_up` 全部无效（方向导航需要焦点属主），只有 `ui_focus_next` 能恢复——而手柄上该动作无默认绑定，且恢复后焦点落在**面板外**的货架瓦片。合约面板签约后同样 owner=null（探针 2 C3）。
- 期望 vs 实际：期望连买多条升级时焦点留在卡片网格（菜单板的约定行为）；实际买一次后 D-pad 全死，纯手柄只能按 B 关面板重开再买一条。
- 修复方向：给两个面板补 `_restore_focus()`（照抄 menu_board 的 `visible and focus_owner==null → close_button.grab_focus()`），最好恢复到被操作卡片的重建对应按钮。
- 置信度：高（丢失 + 死锁 + 面板外恢复三段实证；与既有 `_restore_focus` 约定的缺失直接对应）。

### F4 (S1) 首日教学打开时"下一步"的焦点被延迟 grab 偷走，落到遮罩下的原料按钮

- 证据：`game/scenes/day_shop/day_shop.gd:697-706` `_show_tutorial` 在队列为空时 `_spawn_customer()` → `_set_active_customer` → `_refresh_context_controls` → `_add_context_button`（:1469-1470）`call_deferred("grab_focus")`；该延迟调用在 `tutorial_overlay._render_step` 的 `_next.grab_focus()`（`tutorial_overlay.gd:163`）**之后**落地。
- 复现（探针 3）：gamepad 模式、空队列 `_show_tutorial(true)` → 同帧焦点正确在"下一步"；3 帧后被偷到 `@GridContainer@526/@Button@685`（茶基"阿萨姆"，遮罩下）；教学可见，但连按 6 次 `ui_up` 也回不到"下一步"。
- 期望 vs 实际：期望教学卡打开即焦点"下一步"、A 前进；实际首日/重看教学的第一帧起焦点埋在 58% 暗层下，A 键无效（`running=false` 守卫），玩家要在看不见的控件间摸索找回按钮。
- 修复方向：`_show_tutorial` 里把 spawn 提前、把 `_next.grab_focus()` 改为 `call_deferred`（保证排序在 context grab 之后）；或教学可见期间抑制情境按钮的 deferred grab。
- 置信度：高（同帧 vs 3 帧后对比 + 偷焦点控件路径）。注意与 P1/P10"门控步骤输入不可完成"不同题：这是非门控步骤的"下一步"可达性/焦点管理，任何教学步骤都受影响。
- 佐证边界：截图 harness 因逐步 `_advance()` 会重新 grab，`tutorial3 nintendo` 截图中情境网格区无焦点环（探针才反映真实首开状态）。

### F5 (S2) 手柄族切换在夜间面板打开时把焦点偷到面板外（与 F1 叠加即"焦点已在遮罩下"）

- 证据：`game/scenes/night_lab/night_lab.gd:683-685` `_on_input_scheme_changed(gamepad)` 无条件 `_first_tile.call_deferred("grab_focus")`，不检查面板可见性；`input_prompts.gd:167-175` 家族变化（第二只手柄按键、或摇杆漂移 >0.55 触发 `_activate_gamepad`）也会 emit `scheme_changed(true)`。
- 复现（探针 1 U2）：升级面板打开、焦点在关闭按钮 → `set_test_controller_family("nintendo")`（等价第二只手柄按键）→ 3 帧后焦点移到面板遮罩下的货架首瓦片。
- 期望 vs 实际：期望族切换只刷新提示字形、不动焦点；实际模态打开中焦点被移到被遮挡控件，叠加 F1 后 A 键直接生效于背景。
- 修复方向：`night_lab._on_input_scheme_changed` 加"无面板可见"守卫（与 day_shop 的 `_refresh_input_prompts` 对齐——日间只刷文案不抢焦，行为正确可照抄）。
- 置信度：高。

### F6 (S2) 日间暂停面板 D-pad 可逃逸到遮罩下按钮：A 键被守卫挡住，表现为"按键失灵"

- 证据：`pause_panel.gd` 无焦点圈禁；探针 3：暂停打开 → 6×down + 2×right → 焦点落"RB · 煮一锅珍珠"（遮罩下）→ A：`pearl_batch.active` false→false（`_on_pearl_batch_pressed` 的 `if not running` 守卫生效，day_shop.gd:1001-1004）。
- 期望 vs 实际：期望暂停中 D-pad 只在面板内；实际可以走丢到暗层下（82% 黑遮罩下焦点环几乎不可见），随后按 A 无任何反应也无提示，玩家感知为死键。
- 修复方向：与 F1 同一套圈禁方案覆盖 pause_panel；至少在守卫分支加一声提示音/闪现"已暂停"。
- 置信度：高（逃逸实证；后果为守卫拦截后的纯体验问题，故 S2 而非 S1）。

### F7 (S3) 员工解雇二次确认武装后焦点回到"关闭"：连按 A 会关面板而不是确认

- 证据：`game/ui/staff_panel.gd:277-284` `_dismiss` 首按仅武装 `_dismiss_armed` 并 `call_deferred("_refresh")`；`_refresh`（:107-109）在焦点丢失时恢复到 `_close_button`（而非重建卡上的"确认解雇"按钮）。
- 复现路径：手柄 A 解雇 → 按钮文案变"确认解雇"但焦点已在"关闭" → 再按 A → 面板关闭，解雇未执行。无损失但流程反直觉。
- 修复方向：武装后 `_refresh` 完成时把焦点交给重建卡片里的确认按钮（可按按钮文本查找）。
- 置信度：中高（代码路径明确，未单独跑探针）。

### F8 (S3) 菜单板/图鉴批量操作：每次选择后焦点都回"关闭"，策展要反复重新导航

- 证据：`menu_board_panel.gd:427-443` `_toggle_item`/`_on_price_pressed` → `call_deferred("_refresh")` → 卡片 `free()` → `_restore_focus`（:462-464）回关闭按钮。recipe_book 同约定。
- 复现：手柄设 3 次主推/调 3 档定价，每按一次 A 焦点都跳回右上关闭，需要 D-pad 重新走回滚动网格里的目标卡。
- 期望 vs 实际：期望连续策展时焦点留在"刚才那张卡"或下一张；实际每步都重置。这是 `_restore_focus` 约定的保守取舍（防死锁优先），功能可用，属摩擦。
- 修复方向：`_refresh` 前记录被操作卡片索引，重建后 focus 到同索引卡的动作按钮。
- 置信度：高（代码+约定；严重度低）。

### F9 (S3) 教学覆盖层与事件简报不响应 B（ui_cancel）：只有 A/Start 两条路

- 证据：`tutorial_overlay.gd` 无 `_unhandled_input`/ui_cancel 处理（grep 为空）；事件简报（day_shop `_show_event_briefing`）同样只有 `event_start_button`。夜间五张面板都有 ui_cancel 关闭、pause_panel 的 ui_cancel 能恢复（`pause_panel.gd:621-633`），唯独这两处 B 完全无效。
- 期望 vs 实际：手柄惯例"B=返回/关闭"；教学卡上焦点丢失（F4）时玩家最本能的 B 也无法退场，只能 Start 暂停或摸索 A。
- 修复方向：教学可见时 ui_cancel 触发 `_finish`（跳过）；事件简报 ui_cancel 等同开始。
- 置信度：高（代码缺失明确，影响小）。

### F10 (S3) 事件简报关闭/暂停恢复后焦点落在右上"暂停"按钮，而非当前操作主线

- 证据：`day_shop.gd:694`（`_dismiss_event_briefing`）与 `:739`（`_resume_from_pause`）都 `pause_button.grab_focus()`。手柄玩家简报后的下一步是制杯（情境按钮）或订单卡，需从右上角导航回来。
- 修复方向：恢复时按当前状态交给 `_refresh_context_controls` 的既有 deferred grab（制杯中）/`_focus_active_order`（已封口），暂停按钮仅在无主线时兜底。
- 置信度：高（代码明确，摩擦级）。

## 检查过无问题的面

- **动作映射**：5 个游戏动作 + 备料 LB/RB 肩键齐备且可改绑（`input_prompts.gd:12-18`），`input_check.tscn` 无头全绿（`passed actions=5 families=4 prep_shoulders=true`）。
- **族字形即时刷新**：xbox/PS/任天堂/generic 四族在日间情境提示、订单卡 hint、教学 `_device_hint`、暂停面板 controls 行、主菜单 footer 均随 `scheme_changed` 重渲染（`day_shop._refresh_input_prompts`、`tutorial_overlay._on_input_scheme_changed`、`pause_panel._update_controls_copy`、`main_menu.gd:331`；input_check 364-392/305-307 断言）。切换到键鼠时数字快捷键前缀恢复（input_check 171-191）。
- **交付双确认手柄路径**：封口后情境面板收起、焦点经 `_focus_active_order` 跳到当前订单卡；D-pad 移焦即"核对"（focus_entered 切换 active 订单），A 即"交付"；指针/数字键首按只核对（`_on_order_card_pressed`，day_shop.gd:2101-2115）——焦点流与提示文案（"A · 交付到此"/"选择 · 核对订单"）一致，input_check 268-317 全断言通过。订单卡焦点环 4px #30201D 描边不填充、不遮挡配方（input_check 272-276）。
- **暂停/结算中的越权按键**：暂停中订单卡 A、倒杯、延迟焦点均被 `running`/`paused` 守卫拒绝（R3-F2 修复保持，input_check 332-344 复证）；打烊结算"去研发室"按钮即时接管焦点（R3-F1 修复保持，day_shop.gd:2706-2710）。
- **菜单板/合约/员工/图鉴打开焦点入口**：四面板 `show_panel` 均同步 `close_button.grab_focus()`（菜单板暗方候选走 `_dark_tab`）；菜单板关闭按钮焦点环经截图像素验证（/tmp/p3_ps_menuboard.png 垂直边 x1045/x1192、y81-116）。
- **夜间货架导航与布局**：四组瓦片单行横排，D-pad 左右可跨组移动、上下通向顶部药丸（探针轨迹实证）；day-9 货架按 SafeFrame 作者宽预算缩放不溢出（input_check R11-S3 断言）；瓦片焦点环 3px cocoa 不填充（night_lab.gd:656-665）。
- **B 键关闭惯例**：夜间五张面板与两处设置均有 `ui_cancel` 关闭且 `set_input_as_handled`；夜间 `game_pause`(Start) 还能逐层关面板（night_lab.gd:128-143）。
- **`_restore_focus` 约定本身**：menu_board/staff/recipe_book 三处在卡片销毁后焦点回到关闭按钮，手柄导航不丢（代码 + 探针 M1）；升级/合约缺失已列为 F3。
- **日间情境按钮焦点**：手柄模式下每步重建后首个原料按钮 deferred grab（`_add_context_button`），摇杯大按钮同（day_shop.gd:1374-1375）；键鼠模式不抢焦（`release_focus` 分支，:1312-1313）。
