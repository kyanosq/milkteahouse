## 窗口模式、分辨率和键盘重映射回归；test_mode 下不触碰真实桌面窗口。
extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.test_mode = true
	GameState.settings = {
		"sfx_volume": 0.75,
		"music_volume": 0.55,
		"reduced_motion": false,
		"haptics": true,
		"window_mode": "windowed",
		"resolution": "1280x720",
		"key_bindings": {
			"game_pause": int(KEY_ESCAPE),
			"game_shake": int(KEY_SPACE),
			"staff_interact": int(KEY_F),
		},
	}
	InputPrompts.apply_bindings()
	assert(DisplayPrefs.resolution_size("1440x900") == Vector2i(1440, 900))
	assert(DisplayPrefs.resolution_size("invalid") == Vector2i(1280, 720))

	var menu: Control = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	menu._open_settings()
	assert(menu.settings_panel._haptics.button_pressed)
	Haptics.reset_test_state()
	menu.settings_panel._haptics.set_pressed(false)
	assert(not GameState.haptics_enabled())
	assert(not Haptics.play("tap"), "disabled haptics must suppress gameplay feedback")
	menu.settings_panel._haptics.set_pressed(true)
	assert(GameState.haptics_enabled())
	assert(Haptics.event_count("confirm") == 1, "enabling haptics must provide one preview pulse")
	menu.settings_panel._open_display_settings()
	await get_tree().process_frame
	assert(menu.settings_panel._display_panel.size == Vector2(640, 540))
	assert(menu.settings_panel._display_panel.visible)
	assert(not menu.settings_panel._panel.visible)
	assert(menu.settings_panel._window_mode.selected == 0)
	assert(not menu.settings_panel._resolution.disabled)

	menu.settings_panel._on_window_mode_selected(1)
	assert(GameState.window_mode() == "borderless")
	assert(menu.settings_panel._resolution.disabled)
	menu.settings_panel._on_window_mode_selected(0)
	menu.settings_panel._on_resolution_selected(3)
	assert(GameState.window_mode() == "windowed")
	assert(GameState.resolution() == "1920x1080")
	assert(not menu.settings_panel._resolution.disabled)

	menu.settings_panel._start_rebind("game_shake")
	var new_key := InputEventKey.new()
	new_key.keycode = KEY_R
	new_key.pressed = true
	menu.settings_panel._input(new_key)
	assert(InputPrompts.key_for("game_shake") == KEY_R)
	var action_event := InputEventKey.new()
	action_event.keycode = KEY_R
	action_event.pressed = true
	assert(action_event.is_action_pressed("game_shake"))
	assert(menu.settings_panel._binding_buttons["game_shake"].text.contains("R"))

	menu.settings_panel._start_rebind("staff_interact")
	menu.settings_panel._input(new_key)
	assert(menu.settings_panel._rebind_action == "staff_interact")
	assert(menu.settings_panel._rebind_feedback.text.contains("已用于"))

	# 备料固定键 Q/E 不可被改键占用：撞键会让其中一个动作被静默废掉（评审 R8）。
	assert(InputPrompts.conflict_for("game_pause", KEY_E) != "")
	assert(not InputPrompts.rebind_keyboard("game_pause", KEY_E),
		"rebinding onto the fixed prep keys must be rejected")
	assert(InputPrompts.key_for("game_pause") == KEY_ESCAPE,
		"a rejected rebind must leave the binding untouched")
	# 保留键扩展（P11-F2）：数字 1–9 是情境选择捷径，Enter/Tab 是 UI 确认与
	# 焦点遍历——改键占用会让对应功能静默失效。
	assert(InputPrompts.conflict_for("game_shake", KEY_1) != "",
		"the number shortcuts must be reserved")
	assert(InputPrompts.conflict_for("game_shake", KEY_9) != "")
	assert(InputPrompts.conflict_for("staff_interact", KEY_ENTER) != "",
		"Enter must stay reserved for UI confirm")
	assert(not InputPrompts.rebind_keyboard("game_shake", KEY_1),
		"rebinding onto a number shortcut must be rejected")
	assert(InputPrompts.key_for("game_shake") == KEY_R,
		"a rejected number-key rebind must leave the binding untouched (still R from above)")
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	menu.settings_panel._input(cancel)
	assert(menu.settings_panel._rebind_action.is_empty())

	menu.settings_panel._reset_bindings()
	assert(InputPrompts.key_for("game_pause") == KEY_ESCAPE)
	assert(InputPrompts.key_for("game_shake") == KEY_SPACE)
	assert(InputPrompts.key_for("staff_interact") == KEY_F)
	menu.settings_panel._close_display_settings()
	assert(menu.settings_panel._panel.visible)
	assert(not menu.settings_panel._display_panel.visible)

	# New-game reset preserves release preferences alongside accessibility/audio.
	GameState.settings["window_mode"] = "borderless"
	GameState.settings["resolution"] = "1440x900"
	GameState.settings["key_bindings"]["game_pause"] = int(KEY_P)
	GameState.settings["haptics"] = false
	GameState.reset_progress()
	assert(GameState.window_mode() == "borderless")
	assert(GameState.resolution() == "1440x900")
	assert(GameState.key_binding("game_pause", KEY_ESCAPE) == KEY_P)
	assert(not GameState.haptics_enabled())

	print("[RELEASE_SETTINGS] passed modes=3 resolutions=5 rebind=true conflict_guard=true haptics_toggle=true reset_preserves=true")
	Sfx.stop_all()
	menu.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
