## 桌面显示偏好：窗口化、无边框、全屏与安全分辨率列表。
extends Node

func apply_settings() -> void:
	if GameState.test_mode or DisplayServer.get_name() == "headless":
		return
	var mode := GameState.window_mode()
	var window_id := DisplayServer.MAIN_WINDOW_ID
	if mode == "fullscreen":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false, window_id)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, window_id)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
	if mode == "borderless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, window_id)
		var screen := DisplayServer.window_get_current_screen(window_id)
		DisplayServer.window_set_position(DisplayServer.screen_get_position(screen), window_id)
		DisplayServer.window_set_size(DisplayServer.screen_get_size(screen), window_id)
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false, window_id)
	var target := resolution_size(GameState.resolution())
	DisplayServer.window_set_size(target, window_id)
	var current_screen := DisplayServer.window_get_current_screen(window_id)
	var screen_position := DisplayServer.screen_get_position(current_screen)
	var screen_size := DisplayServer.screen_get_size(current_screen)
	DisplayServer.window_set_position(screen_position + (screen_size - target) / 2, window_id)


func set_window_mode(mode: String) -> void:
	GameState.settings["window_mode"] = mode if mode in GameState.VALID_WINDOW_MODES else "windowed"
	GameState.save_game()
	apply_settings()


func set_resolution(value: String) -> void:
	GameState.settings["resolution"] = value if value in GameState.VALID_RESOLUTIONS else "1280x720"
	GameState.save_game()
	apply_settings()


func resolution_size(value: String) -> Vector2i:
	var safe_value := value if value in GameState.VALID_RESOLUTIONS else "1280x720"
	var parts := safe_value.split("x")
	return Vector2i(int(parts[0]), int(parts[1]))


func mode_label(mode: String) -> String:
	var index := GameState.VALID_WINDOW_MODES.find(mode)
	var safe: String = GameState.VALID_WINDOW_MODES[index] if index >= 0 else GameState.VALID_WINDOW_MODES[0]
	return GameLocale.text("DISPLAY_MODE_%s" % safe.to_upper())
