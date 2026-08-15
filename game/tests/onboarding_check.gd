## 首日教学、键盘快捷键、暂停和即时设置回归。
extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.test_mode = true
	GameState.menu = []
	GameState.featured_menu = []
	GameState.day = 1
	GameState.tutorial_completed = false
	GameState.settings = {"sound_volume": 0.75, "reduced_motion": false}
	var shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	assert(Sfx.current_music == "day")

	shop._show_tutorial(false)
	assert(shop.tutorial_overlay.visible)
	assert(not shop.running)
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
	shop._on_base(GameData.bases[0])
	assert(shop.tutorial_overlay._step_completed(), "selecting a tea base completes gate step 3")
	shop.tutorial_overlay._advance()
	assert(shop.tutorial_overlay._step == 3, "gate step 4 (shake) is next")
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
	assert(is_equal_approx(GameState.sound_volume(), 0.35))
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

	print("[ONBOARDING] passed tutorial=%s shortcut=%s volume=%.2f reduced_motion=%s paused=%s" % [
		str(GameState.tutorial_completed), String(shop.cup_base["id"]), GameState.sound_volume(),
		str(GameState.reduced_motion()), str(get_tree().paused)])
	Sfx.stop_all()
	shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
