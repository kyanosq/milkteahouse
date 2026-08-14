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
	assert(shop.tutorial_overlay.STEPS.size() == 5)
	for i in 5:
		shop.tutorial_overlay._advance()
	assert(GameState.tutorial_completed)
	assert(not shop.tutorial_overlay.visible)
	assert(shop.running)

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
