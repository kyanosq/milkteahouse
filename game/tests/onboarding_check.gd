## 首日教学、键盘快捷键、暂停和即时设置回归。
extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.test_mode = true
	GameState.menu = []
	GameState.featured_menu = []
	GameState.day = 1
	GameState.tutorial_completed = false
	GameState.settings = {"sfx_volume": 0.75, "music_volume": 0.55, "reduced_motion": false}
	var shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	assert(Sfx.current_music == "day")

	shop._show_tutorial(false)
	assert(shop.tutorial_overlay.visible)
	assert(not shop.running)
	# 跳过必须是本地化的次级按钮：文案来自翻译表，且不与主按钮同抢珊瑚主样式。
	assert(shop.tutorial_overlay._skip.text == GameLocale.text("TUTORIAL_SKIP"),
		"skip copy must come from the localization table")
	var skip_normal: StyleBoxFlat = shop.tutorial_overlay._skip.get_theme_stylebox("normal")
	assert(skip_normal is StyleBoxFlat and skip_normal.bg_color != Color("FF6259"),
		"skip must be styled secondary, not the theme-default primary coral")
	assert(shop.tutorial_overlay.STEPS.size() == 6,
		"the tutorial must include the goal-and-stars step")
	assert(shop.tutorial_overlay.STEPS[0]["focus"].position.x <= 8.0 and shop.tutorial_overlay.STEPS[0]["focus"].position.y <= 8.0,
		"step 1 must spotlight the HUD goal row")
	# D2-B 门控：步骤 3 在选过茶基前不得前进；完成动作后放行。
	shop.tutorial_overlay._advance()
	assert(shop.tutorial_overlay._step == 1)
	shop.tutorial_overlay._advance()
	assert(shop.tutorial_overlay._step == 2, "step 3 (index 2) is the first gated step")
	shop.tutorial_overlay._advance()
	assert(shop.tutorial_overlay._step == 2 and shop.tutorial_overlay._gate_fails == 1,
		"a gated step must refuse to advance until the action is done")
	# 门控步骤 3 必须经真实输入路径完成（P3-D1/V1 归因：遮罩 STOP + not running
	# 双重阻断）——不是直调 _on_base。先走完整 GUI 管线（parse_input_event）。
	var gate_gui_key := InputEventKey.new()
	gate_gui_key.keycode = KEY_2
	gate_gui_key.pressed = true
	shop._reset_cup()
	# 鼠标路径的归因是遮罩的 STOP 过滤器（V1 实验 C）：无头模式无法驱动真实
	# 点击拾取，改为钉住过滤器本身——门控期教学层整体 IGNORE、观察期恢复 STOP。
	assert(shop.tutorial_overlay.gated_practice_active())
	for dim in [shop.tutorial_overlay._dim_top, shop.tutorial_overlay._dim_bottom,
			shop.tutorial_overlay._dim_left, shop.tutorial_overlay._dim_right]:
		assert(dim.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"gated practice must let clicks pass the tutorial scrim to the shop controls")
	Input.parse_input_event(gate_gui_key)
	await get_tree().process_frame
	assert(shop.cup_base != null,
		"KEY_2 through the real GUI pipeline must reach the context button during gate step 3")
	assert(shop.tutorial_overlay._step_completed(), "selecting a tea base completes gate step 3")
	shop.tutorial_overlay._advance()
	assert(shop.tutorial_overlay._step == 3, "gate step 4 (shake) is next")
	# 门控步骤 4 的摇杯路径同样必须可达：奶基/糖度走数字捷径，封杯走 game_shake
	# action 注入（V1 复现：四路输入在修复前全部 0 进度）。
	var press_key := func(key: Key) -> void:
		var ev := InputEventKey.new()
		ev.keycode = key
		ev.pressed = true
		shop._input(ev)
	var ready_guard := 0
	while not shop._can_gesture_shake() and ready_guard < 8:
		press_key.call(KEY_1)
		ready_guard += 1
	assert(shop._can_gesture_shake(),
		"real number-key input during the gated tutorial must walk the prep flow")
	var gate_shake := InputEventAction.new()
	gate_shake.action = "game_shake"
	gate_shake.pressed = true
	while not shop.cup_sealed:
		shop._input(gate_shake)
	assert(shop.cup_sealed, "a real game_shake action during gate step 4 must seal the cup")
	assert(shop.tutorial_overlay._step_completed(), "sealing the cup completes gate step 4")
	shop._reset_cup()
	# 防软锁：步骤 4 连续失败 2 次自动放行。
	shop.tutorial_overlay._advance()
	shop.tutorial_overlay._advance()
	assert(shop.tutorial_overlay._gate_bypassed and shop.tutorial_overlay._step == 4,
		"two failed attempts must auto-release the gate")
	for i in 2:
		shop.tutorial_overlay._advance()
	assert(GameState.tutorial_completed)
	assert(not shop.tutorial_overlay.visible)
	assert(shop.running)

	# 教程/事件简报期间暂停必须可达（CF 待办）：面板盖在覆盖层上，恢复不偷走教学。
	shop._show_tutorial(true)
	assert(shop.tutorial_overlay.visible)
	# 重看必须重置门控（P11-F3）：上一轮的 bypass 与失败计数不得跨重看保留。
	assert(not shop.tutorial_overlay._gate_bypassed, "replay must clear the gate bypass flag")
	shop.tutorial_overlay._advance()
	shop.tutorial_overlay._advance()
	assert(shop.tutorial_overlay._step == 2, "replay reaches the gated practice step")
	assert(not shop.tutorial_overlay._step_completed(),
		"a replayed gated step must demand real practice again")
	shop._reset_cup()
	# B 键退出教学（P3-F9）：教程可见时 ui_cancel 等同完成/跳过，不再死键。
	var tutorial_cancel := InputEventAction.new()
	tutorial_cancel.action = "ui_cancel"
	tutorial_cancel.pressed = true
	shop.tutorial_overlay._unhandled_input(tutorial_cancel)
	assert(not shop.tutorial_overlay.visible, "ui_cancel must dismiss the tutorial overlay")
	# 重新拉起教程，继续「暂停期间教学可见」的原有断言流。
	shop._show_tutorial(true)
	shop.running = false
	shop._toggle_pause()
	assert(get_tree().paused and shop.pause_panel.visible,
		"pause must open while the tutorial overlay is showing")
	assert(shop.pause_panel.z_index > 0,
		"the pause panel must render above root-level overlays")
	shop._resume_from_pause()
	assert(not get_tree().paused and not shop.pause_panel.visible)
	assert(shop.tutorial_overlay.visible and not shop.running,
		"resuming must return to the tutorial with the clock still frozen")
	shop.tutorial_overlay._finish()
	assert(not shop.tutorial_overlay.visible)

	# 简报期间从暂停面板重看教学：简报必须先收起，教程不得被简报层盖住
	#（对抗审查发现：简报层挂在 ui_frame 之上）。Day1 是平静日，用 Day3 事件驱动。
	GameState.day = 3
	shop.day_event = DailyEvents.event_for_day(3)
	shop._show_event_briefing()
	assert(shop.event_overlay.visible)
	# 简报 B 键等同开始（P3-F9）：夜间五面板都有 ui_cancel，简报不能再是死键。
	var briefing_cancel := InputEventAction.new()
	briefing_cancel.action = "ui_cancel"
	briefing_cancel.pressed = true
	shop._input(briefing_cancel)
	assert(not shop.event_overlay.visible, "ui_cancel must dismiss the event briefing")
	assert(shop.running, "a cancel-dismissed briefing must resume the shift")
	shop._show_event_briefing()
	assert(shop.event_overlay.visible)
	shop._toggle_pause()
	assert(shop.pause_panel.visible, "pause must open behind the event briefing")
	shop._replay_tutorial()
	assert(not shop.event_overlay.visible,
		"replaying the tutorial must dismiss the briefing first")
	assert(shop.tutorial_overlay.visible and not shop.running)
	shop.tutorial_overlay._finish()

	# 三星拉伸必须可见：HUD 目标条延伸到 140%，目标线留刻度，文案披露 3★ 数字。
	assert(is_equal_approx(float(shop.hud_goal_bar.max_value), 140.0),
		"goal bar must stretch to the 1.4x star line")
	assert(shop.hud_goal_bar.get_child_count() == 1,
		"goal bar must carry the 100% goal tick")
	shop._update_info()
	assert(shop.hud_goal_text.text.contains("3★"))
	# 术语药丸必须有悬停说明：首次玩家无法从裸数字猜出含义（P1 试玩）。
	assert(String(shop.hud_perfect.get_parent().tooltip_text).length() > 0,
		"the perfect-serve pill needs a tooltip")
	assert(String(shop.hud_streak.get_parent().tooltip_text).length() > 0,
		"the streak pill needs a tooltip")
	# 摇杯计数向上取整：一次有效摇动立刻 +1，衰减中不倒退。
	shop.shake_progress = 1.2
	assert(shop._shake_count_display() == 2)
	shop.shake_progress = 0.0

	var shortcut := InputEventKey.new()
	shortcut.keycode = KEY_1
	shortcut.pressed = true
	shop._input(shortcut)
	assert(shop.cup_base != null)

	shop._toggle_pause()
	assert(get_tree().paused)
	assert(shop.pause_panel.visible)
	assert(not shop.running)
	var paused_time: float = shop.time_left
	await get_tree().create_timer(0.12, true).timeout
	assert(is_equal_approx(shop.time_left, paused_time))
	shop.pause_panel._on_volume_changed(35.0)
	shop.pause_panel._on_motion_toggled(true)
	assert(is_equal_approx(GameState.sfx_volume(), 0.35))
	assert(GameState.reduced_motion())
	shop.pause_panel._request_menu()
	assert(shop.pause_panel._confirm_panel.visible)
	assert(not shop.pause_panel._panel.visible)
	shop.pause_panel._cancel_menu()
	assert(not shop.pause_panel._confirm_panel.visible)
	assert(shop.pause_panel._panel.visible)
	shop._resume_from_pause()
	assert(not get_tree().paused)
	assert(not shop.pause_panel.visible)
	assert(shop.running)

	# 制杯状态行（P4-1）：最坏英文配方串实测 1112px > 505px 面板。
	# 短名 + 自动换行 + 裁断保证状态行永远停在面板内。
	shop.cup_base = GameData.bases[0]
	shop.cup_milk = GameData.milks[0]
	shop.cup_tops = [GameData.toppings[0], GameData.toppings[1]]
	shop.cup_sugar = GameData.sugar_levels[4]
	shop.cup_sealed = true
	shop.cup_corrections = 1
	GameLocale.set_locale("en", false)
	shop._refresh_cup()
	await get_tree().process_frame
	assert(shop.status_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART,
		"cup status line must autowrap inside its panel")
	assert(shop.status_label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS)
	assert(shop.status_label.get_line_count() <= 2,
		"the worst-case status string must wrap within two lines, not run off-screen")
	assert(shop.status_label.size.x <= 482.0,
		"the status label must stay inside the 505px panel (minus theme margins)")
	GameLocale.set_locale("zh_CN", false)
	var shortcut_id := String(shop.cup_base["id"])
	shop._reset_cup()

	print("[ONBOARDING] passed tutorial=%s shortcut=%s volume=%.2f reduced_motion=%s paused=%s" % [
		str(GameState.tutorial_completed), shortcut_id, GameState.sfx_volume(),
		str(GameState.reduced_motion()), str(get_tree().paused)])
	Sfx.stop_all()
	shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
