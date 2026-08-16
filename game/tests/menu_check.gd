## 标题页、破坏性确认和新存档初始化回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.day = 7
	GameState.phase = "night"
	GameState.coins = 222
	GameState.inspiration = 9
	GameState.upgrades = {"comfort": 2, "shaker": 1}
	GameState.discovered = ["classic_boba"]
	GameState.tutorial_completed = true
	GameState.settings = {"sfx_volume": 0.35, "music_volume": 0.55, "reduced_motion": true}

	var menu: Control = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	assert(Sfx.current_music == "menu")
	assert(menu.continue_button.text.contains("继续研发"))
	assert(menu.continue_button.text.contains("第 7 天"))

	menu._open_settings()
	assert(menu.settings_panel.visible)
	assert(menu.settings_panel._title.text == "设置")
	menu._close_settings()
	assert(not menu.settings_panel.visible)

	# The confirmation behavior must not depend on a developer machine having a save.
	menu.has_existing_save = true
	menu._request_new_game()
	assert(menu.confirm_overlay.visible)
	menu._close_confirmation()
	assert(not menu.confirm_overlay.visible)
	GameState.phase = "campaign"
	assert(menu._continue_target() == "res://scenes/campaign_summary/campaign_summary.tscn")

	GameState.reset_progress()
	assert(GameState.day == 1)
	assert(GameState.phase == "day")
	assert(GameState.coins == 0)
	assert(GameState.inspiration == 0)
	assert(GameState.upgrades.is_empty())
	assert(GameState.staff.is_empty())
	assert(GameState.discovered.is_empty())
	assert(not GameState.tutorial_completed)
	assert(is_equal_approx(GameState.sfx_volume(), 0.35))
	assert(GameState.reduced_motion())

	print("[MENU] passed continue=day7 confirm=true reset=day1 settings_preserved=true")
	Sfx.stop_all()
	menu.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
