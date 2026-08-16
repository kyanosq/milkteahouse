## 暂停与即时设置：音量、减少动态、触觉反馈、教学重播和输入提示。
extends ColorRect
class_name PausePanel

signal resume_requested
signal tutorial_requested
signal menu_requested

const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")
const MINT := Color("27B9A7")

var _music_label: Label
var _music: HSlider
var _sfx_label: Label
var _sfx: HSlider
var _settings_dirty := false
var _settings_save_generation := 0
# 兼容旧自动化接口；从本轮起“总音量”明确等同于音效音量。
var _volume_label: Label
var _volume: HSlider
var _motion: CheckButton
var _haptics: CheckButton
var _resume: Button
var _tutorial: Button
var _menu: Button
var _panel: PanelContainer
var _confirm_panel: PanelContainer
var _confirm_body: Label
var _confirm_cancel: Button
var _title: Label
var _controls: Label
var _motion_help: Label
var _advanced: Button
var _language: Button
var _display_panel: PanelContainer
var _window_mode: OptionButton
var _resolution: OptionButton
var _binding_buttons: Dictionary = {}
var _rebind_action := ""
var _rebind_feedback: Label
var _context := "day"
var _panel_authored_position := Vector2(370, 105)
var _safe_offset := Vector2.ZERO


func _ready() -> void:
	color = Color(0.05, 0.045, 0.06, 0.82)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	InputPrompts.scheme_changed.connect(_on_input_scheme_changed)
	InputPrompts.bindings_changed.connect(_on_bindings_changed)
	GameLocale.locale_changed.connect(_on_locale_changed)
	get_viewport().size_changed.connect(_layout_overscan)
	_layout_overscan()
	visible = false


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = _panel_authored_position
	_panel.custom_minimum_size = Vector2(540, 510)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	_title = Label.new()
	_title.text = "PAUSE_HEADING"
	_title.add_theme_font_size_override("font_size", 30)
	box.add_child(_title)
	_controls = Label.new()
	_controls.text = "PAUSE_CONTROLS_HINT"
	_controls.custom_minimum_size = Vector2(480, 0)
	_controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_controls.add_theme_font_size_override("font_size", 16)
	_controls.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.72)
	box.add_child(_controls)
	_music_label = Label.new()
	_music_label.add_theme_font_size_override("font_size", 18)
	box.add_child(_music_label)
	_music = _audio_slider()
	_music.value_changed.connect(_on_music_volume_changed)
	box.add_child(_music)
	_sfx_label = Label.new()
	_sfx_label.add_theme_font_size_override("font_size", 18)
	box.add_child(_sfx_label)
	_sfx = _audio_slider()
	_sfx.value_changed.connect(_on_sfx_volume_changed)
	box.add_child(_sfx)
	_volume_label = _sfx_label
	_volume = _sfx
	var feedback_row := HBoxContainer.new()
	feedback_row.add_theme_constant_override("separation", 14)
	box.add_child(feedback_row)
	_motion = CheckButton.new()
	_motion.text = "SETTINGS_MOTION"
	_motion.flat = true
	_motion.custom_minimum_size = Vector2(240, 48)
	_motion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_motion.add_theme_color_override("font_color", COCOA)
	_motion.add_theme_color_override("font_hover_color", COCOA)
	_motion.add_theme_color_override("font_pressed_color", COCOA)
	_motion.toggled.connect(_on_motion_toggled)
	feedback_row.add_child(_motion)
	_haptics = CheckButton.new()
	_haptics.text = "SETTINGS_HAPTICS"
	_haptics.tooltip_text = "SETTINGS_HAPTICS_DESC"
	_haptics.flat = true
	_haptics.custom_minimum_size = Vector2(240, 48)
	_haptics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_haptics.add_theme_color_override("font_color", COCOA)
	_haptics.add_theme_color_override("font_hover_color", COCOA)
	_haptics.add_theme_color_override("font_pressed_color", COCOA)
	_haptics.toggled.connect(_on_haptics_toggled)
	feedback_row.add_child(_haptics)
	_motion_help = Label.new()
	_motion_help.text = "SETTINGS_MOTION_DESC"
	_motion_help.add_theme_font_size_override("font_size", 15)
	_motion_help.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.66)
	box.add_child(_motion_help)
	_language = Button.new()
	_language.custom_minimum_size = Vector2(0, 44)
	_style_secondary(_language, Color("D99A43"))
	_language.pressed.connect(GameLocale.toggle)
	box.add_child(_language)
	_advanced = Button.new()
	_advanced.text = "SETTINGS_DISPLAY"
	_advanced.custom_minimum_size = Vector2(0, 44)
	_style_secondary(_advanced, MINT)
	_advanced.pressed.connect(_open_display_settings)
	box.add_child(_advanced)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_tutorial = Button.new()
	_tutorial.text = "PAUSE_TUTORIAL"
	_tutorial.custom_minimum_size = Vector2(0, 50)
	_style_secondary(_tutorial, MINT)
	_tutorial.pressed.connect(func(): tutorial_requested.emit())
	box.add_child(_tutorial)
	_menu = Button.new()
	_menu.text = "PAUSE_MENU"
	_menu.custom_minimum_size = Vector2(0, 48)
	_style_secondary(_menu, Color(COCOA.r, COCOA.g, COCOA.b, 0.48))
	_menu.pressed.connect(_request_menu)
	box.add_child(_menu)
	_resume = Button.new()
	_resume.text = "PAUSE_RESUME"
	_resume.custom_minimum_size = Vector2(0, 54)
	_resume.pressed.connect(func(): resume_requested.emit())
	box.add_child(_resume)

	_confirm_panel = PanelContainer.new()
	_confirm_panel.position = Vector2(370, 235)
	_confirm_panel.custom_minimum_size = Vector2(540, 250)
	_confirm_panel.visible = false
	add_child(_confirm_panel)
	var confirm_box := VBoxContainer.new()
	confirm_box.add_theme_constant_override("separation", 16)
	_confirm_panel.add_child(confirm_box)
	var confirm_title := Label.new()
	confirm_title.text = "PAUSE_MENU_CONFIRM"
	confirm_title.add_theme_font_size_override("font_size", 30)
	confirm_box.add_child(confirm_title)
	_confirm_body = Label.new()
	_confirm_body.custom_minimum_size = Vector2(500, 88)
	_confirm_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_body.add_theme_font_size_override("font_size", 17)
	confirm_box.add_child(_confirm_body)
	var confirm_actions := HBoxContainer.new()
	confirm_actions.add_theme_constant_override("separation", 12)
	confirm_box.add_child(confirm_actions)
	_confirm_cancel = Button.new()
	_confirm_cancel.text = "PAUSE_MENU_STAY"
	_confirm_cancel.custom_minimum_size = Vector2(238, 54)
	_style_secondary(_confirm_cancel, MINT)
	_confirm_cancel.pressed.connect(_cancel_menu)
	confirm_actions.add_child(_confirm_cancel)
	var leave := Button.new()
	leave.text = "PAUSE_MENU_DO"
	leave.custom_minimum_size = Vector2(250, 54)
	leave.pressed.connect(func(): menu_requested.emit())
	confirm_actions.add_child(leave)
	_build_display_panel()


func _build_display_panel() -> void:
	_display_panel = PanelContainer.new()
	_display_panel.position = Vector2(320, 90)
	_display_panel.custom_minimum_size = Vector2(640, 540)
	_display_panel.visible = false
	add_child(_display_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_display_panel.add_child(box)
	var title := Label.new()
	title.text = "SETTINGS_DISPLAY"
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "SETTINGS_DISPLAY_NOTE"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.68)
	box.add_child(subtitle)
	var display_grid := GridContainer.new()
	display_grid.columns = 2
	display_grid.add_theme_constant_override("h_separation", 14)
	display_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(display_grid)
	var mode_label := Label.new()
	mode_label.text = "SETTINGS_WINDOW_MODE"
	mode_label.custom_minimum_size = Vector2(170, 42)
	display_grid.add_child(mode_label)
	_window_mode = OptionButton.new()
	_window_mode.custom_minimum_size = Vector2(410, 42)
	_rebuild_mode_options()
	_window_mode.item_selected.connect(_on_window_mode_selected)
	display_grid.add_child(_window_mode)
	var resolution_label := Label.new()
	resolution_label.text = "SETTINGS_RESOLUTION"
	resolution_label.custom_minimum_size = Vector2(170, 42)
	display_grid.add_child(resolution_label)
	_resolution = OptionButton.new()
	_resolution.custom_minimum_size = Vector2(410, 42)
	for value in DisplayPrefs.RESOLUTIONS:
		_resolution.add_item(value.replace("x", " × "))
	_resolution.item_selected.connect(_on_resolution_selected)
	display_grid.add_child(_resolution)
	var binding_title := Label.new()
	binding_title.text = "SETTINGS_KEYS"
	binding_title.add_theme_font_size_override("font_size", 19)
	binding_title.add_theme_color_override("font_color", MINT)
	box.add_child(binding_title)
	for action_name in ["game_pause", "game_shake", "staff_interact"]:
		box.add_child(_binding_row(action_name, _binding_name(action_name)))
	_rebind_feedback = Label.new()
	_rebind_feedback.custom_minimum_size = Vector2(0, 28)
	_rebind_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rebind_feedback.add_theme_font_size_override("font_size", 15)
	box.add_child(_rebind_feedback)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	var reset := Button.new()
	reset.text = "SETTINGS_KEYS_RESET"
	reset.custom_minimum_size = Vector2(294, 50)
	_style_secondary(reset, MINT)
	reset.pressed.connect(_reset_bindings)
	actions.add_child(reset)
	var back := Button.new()
	back.text = "SETTINGS_BACK"
	back.custom_minimum_size = Vector2(300, 50)
	back.pressed.connect(_close_display_settings)
	actions.add_child(back)


func _binding_row(action_name: String, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var button := Button.new()
	button.custom_minimum_size = Vector2(270, 42)
	_style_secondary(button, Color("D99A43"))
	button.pressed.connect(_start_rebind.bind(action_name))
	row.add_child(button)
	_binding_buttons[action_name] = button
	return row


func show_panel(allow_tutorial := true, context := "day") -> void:
	_context = context
	_title.text = GameLocale.text("SETTINGS_TITLE_NIGHT" if context == "night" else "SETTINGS_TITLE_DAY")
	_update_controls_copy()
	_resume.text = GameLocale.text("SETTINGS_RESUME_NIGHT" if context == "night" else "SETTINGS_RESUME_DAY")
	_tutorial.visible = allow_tutorial
	_menu.visible = true
	_confirm_panel.visible = false
	_display_panel.visible = false
	_panel.visible = true
	_panel_authored_position = Vector2(370, 55) if allow_tutorial else Vector2(370, 98)
	_panel.custom_minimum_size = Vector2(540, 660 if allow_tutorial else 575)
	_panel.size = _panel.custom_minimum_size
	_layout_overscan()
	_sync_settings()
	Sfx.play("ui_open")


func show_menu_settings() -> void:
	_context = "menu"
	_title.text = GameLocale.text("SETTINGS_TITLE_MENU")
	_update_controls_copy()
	_resume.text = GameLocale.text("SETTINGS_RETURN_MENU")
	_tutorial.visible = false
	_menu.visible = false
	_confirm_panel.visible = false
	_display_panel.visible = false
	_panel.visible = true
	_panel_authored_position = Vector2(370, 106)
	_panel.custom_minimum_size = Vector2(540, 505)
	_panel.size = _panel.custom_minimum_size
	_layout_overscan()
	_sync_settings()
	Sfx.play("ui_open")


func _sync_settings() -> void:
	_music.set_value_no_signal(GameState.music_volume() * 100.0)
	_sfx.set_value_no_signal(GameState.sfx_volume() * 100.0)
	_motion.set_pressed_no_signal(GameState.reduced_motion())
	_haptics.set_pressed_no_signal(GameState.haptics_enabled())
	_language.text = GameLocale.text("LANGUAGE_CURRENT")
	_update_audio_labels()
	visible = true
	_resume.grab_focus()


func hide_panel() -> void:
	if visible:
		Sfx.play("ui_close")
	visible = false
	_confirm_panel.visible = false
	_display_panel.visible = false
	_rebind_action = ""
	_panel.visible = true
	_persist_settings_now()


## 设置写盘包含临时文件、回读校验与备份轮换；滑条拖动每 tick 都触发
## 一次完整落盘会在移动端造成卡顿。内存立即生效，磁盘写入防抖合并。
func _schedule_settings_save() -> void:
	_settings_dirty = true
	_settings_save_generation += 1
	var generation := _settings_save_generation
	await get_tree().create_timer(0.6).timeout
	if _settings_save_generation == generation:
		_persist_settings_now()


func _persist_settings_now() -> void:
	_settings_save_generation += 1
	if not _settings_dirty:
		return
	_settings_dirty = false
	GameState.save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _settings_dirty:
		GameState.save_game()
		_settings_dirty = false


func _request_menu() -> void:
	_confirm_body.text = GameLocale.text("SETTINGS_CONFIRM_NIGHT" if _context == "night" else "SETTINGS_CONFIRM_DAY")
	_panel.visible = false
	_confirm_panel.visible = true
	_confirm_cancel.grab_focus()


func _cancel_menu() -> void:
	_confirm_panel.visible = false
	_panel.visible = true
	_menu.grab_focus()


func _open_display_settings() -> void:
	_rebind_action = ""
	_rebind_feedback.text = ""
	_panel.visible = false
	_confirm_panel.visible = false
	_display_panel.visible = true
	_refresh_display_settings()
	call_deferred("_refit_display_panel")
	_window_mode.grab_focus()
	Sfx.play("ui_open", 1.08)


func _close_display_settings() -> void:
	_rebind_action = ""
	_display_panel.visible = false
	_panel.visible = true
	_advanced.grab_focus()
	Sfx.play("ui_close", 1.08)


func _refresh_display_settings() -> void:
	var mode_index := DisplayPrefs.MODES.find(GameState.window_mode())
	_window_mode.select(maxi(mode_index, 0))
	var resolution_index := DisplayPrefs.RESOLUTIONS.find(GameState.resolution())
	_resolution.select(maxi(resolution_index, 0))
	_resolution.disabled = GameState.window_mode() != "windowed"
	_refresh_binding_buttons()


func _rebuild_mode_options() -> void:
	if _window_mode == null:
		return
	var selected_mode := GameState.window_mode()
	_window_mode.clear()
	for mode in DisplayPrefs.MODES:
		_window_mode.add_item(GameLocale.text("DISPLAY_MODE_%s" % mode.to_upper()))
	_window_mode.select(maxi(DisplayPrefs.MODES.find(selected_mode), 0))


func _refit_display_panel() -> void:
	_display_panel.reset_size()
	_display_panel.size = Vector2(640, 540)
	_display_panel.position = _safe_offset + Vector2(320, 90)


func _refresh_binding_buttons() -> void:
	for action_name in _binding_buttons:
		var button: Button = _binding_buttons[action_name]
		button.text = GameLocale.text("SETTINGS_REBIND_BUTTON", [InputPrompts.key_label(action_name)])


func _on_window_mode_selected(index: int) -> void:
	if index < 0 or index >= DisplayPrefs.MODES.size():
		return
	DisplayPrefs.set_window_mode(DisplayPrefs.MODES[index])
	_resolution.disabled = GameState.window_mode() != "windowed"
	_rebind_feedback.text = GameLocale.text("SETTINGS_MODE_CHANGED", [GameLocale.text("DISPLAY_MODE_%s" % GameState.window_mode().to_upper())])


func _on_resolution_selected(index: int) -> void:
	if index < 0 or index >= DisplayPrefs.RESOLUTIONS.size():
		return
	DisplayPrefs.set_resolution(DisplayPrefs.RESOLUTIONS[index])
	_rebind_feedback.text = GameLocale.text("SETTINGS_RESOLUTION_CHANGED", [GameState.resolution().replace("x", " × ")])


func _start_rebind(action_name: String) -> void:
	_rebind_action = action_name
	_rebind_feedback.text = GameLocale.text("SETTINGS_PRESS_NEW_KEY")
	var button: Button = _binding_buttons[action_name]
	button.text = GameLocale.text("SETTINGS_WAITING_INPUT")


func _reset_bindings() -> void:
	_rebind_action = ""
	InputPrompts.reset_keyboard_bindings()
	_rebind_feedback.text = GameLocale.text("SETTINGS_BINDINGS_RESET")
	_refresh_binding_buttons()


func _on_volume_changed(value: float) -> void:
	_on_sfx_volume_changed(value)


func _on_music_volume_changed(value: float) -> void:
	GameState.settings["music_volume"] = value / 100.0
	_update_audio_labels()
	Sfx.apply_settings()
	_schedule_settings_save()


func _on_sfx_volume_changed(value: float) -> void:
	GameState.settings["sfx_volume"] = value / 100.0
	_update_audio_labels()
	Sfx.apply_settings()
	_schedule_settings_save()


func _on_motion_toggled(enabled: bool) -> void:
	GameState.settings["reduced_motion"] = enabled
	_schedule_settings_save()


func _on_haptics_toggled(enabled: bool) -> void:
	GameState.settings["haptics"] = enabled
	if enabled:
		Haptics.play("confirm")
	_schedule_settings_save()


func _on_input_scheme_changed(_gamepad: bool) -> void:
	_update_controls_copy()


func _on_bindings_changed() -> void:
	_update_controls_copy()
	_refresh_binding_buttons()


func _on_locale_changed(_locale: String) -> void:
	_language.text = GameLocale.text("LANGUAGE_CURRENT")
	_rebuild_mode_options()
	_update_controls_copy()
	_update_audio_labels()
	_refresh_binding_buttons()
	if _context == "night":
		_title.text = GameLocale.text("SETTINGS_TITLE_NIGHT")
		_resume.text = GameLocale.text("SETTINGS_RESUME_NIGHT")
	elif _context == "menu":
		_title.text = GameLocale.text("SETTINGS_TITLE_MENU")
		_resume.text = GameLocale.text("SETTINGS_RETURN_MENU")
	else:
		_title.text = GameLocale.text("SETTINGS_TITLE_DAY")
		_resume.text = GameLocale.text("SETTINGS_RESUME_DAY")


func _update_controls_copy() -> void:
	if _controls == null:
		return
	if _context == "menu":
		_controls.text = GameLocale.text("SETTINGS_CONTROLS_MENU_GAMEPAD", [InputPrompts.accept_hint(),
			InputPrompts.cancel_hint()]) if InputPrompts.gamepad_mode else GameLocale.text("SETTINGS_CONTROLS_MENU_KEYBOARD")
	elif _context == "night":
		_controls.text = GameLocale.text("SETTINGS_CONTROLS_NIGHT_GAMEPAD", [InputPrompts.accept_hint(),
			InputPrompts.cancel_hint()]) if InputPrompts.gamepad_mode else GameLocale.text("SETTINGS_CONTROLS_NIGHT_KEYBOARD", [InputPrompts.pause_hint()])
	else:
		_controls.text = GameLocale.text("SETTINGS_CONTROLS_DAY_GAMEPAD", [InputPrompts.accept_hint(),
			InputPrompts.prep_tea_hint(), InputPrompts.prep_pearl_hint(), InputPrompts.shake_hint(),
			InputPrompts.staff_hint(), InputPrompts.pause_hint()]) \
			if InputPrompts.gamepad_mode else GameLocale.text("SETTINGS_CONTROLS_DAY_KEYBOARD", [
				InputPrompts.prep_tea_hint(), InputPrompts.prep_pearl_hint(), InputPrompts.shake_hint(),
				InputPrompts.staff_hint(), InputPrompts.pause_hint()])


func _layout_overscan() -> void:
	var geometry := SafeFrame.overscan_geometry(self)
	_safe_offset = geometry["offset"]
	position = -_safe_offset
	size = geometry["size"]
	if _panel != null:
		_panel.position = _safe_offset + _panel_authored_position
	if _confirm_panel != null:
		_confirm_panel.position = _safe_offset + Vector2(370, 235)
	if _display_panel != null:
		_display_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_display_panel.position = _safe_offset + Vector2(320, 90)
		_display_panel.size = Vector2(640, 540)


func _update_volume_label() -> void:
	_update_audio_labels()


func _update_audio_labels() -> void:
	_music_label.text = GameLocale.text("SETTINGS_MUSIC", [int(_music.value)])
	_sfx_label.text = GameLocale.text("SETTINGS_SFX", [int(_sfx.value)])


func _audio_slider() -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.custom_minimum_size = Vector2(0, 38)
	return slider


func _style_secondary(button: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.96)
	normal.set_corner_radius_all(12)
	normal.set_border_width_all(2)
	normal.border_color = accent
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.22)
	var focus: StyleBoxFlat = normal.duplicate()
	focus.set_border_width_all(4)
	focus.border_color = MINT
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, COCOA)


func _input(event: InputEvent) -> void:
	if not visible or _rebind_action.is_empty():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	if event.keycode == KEY_ESCAPE:
		_rebind_feedback.text = GameLocale.text("SETTINGS_REBIND_CANCELLED")
		_rebind_action = ""
		_refresh_binding_buttons()
		return
	if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		_rebind_feedback.text = GameLocale.text("SETTINGS_MODIFIER_REJECTED")
		return
	var conflict := InputPrompts.conflict_for(_rebind_action, event.keycode)
	if conflict != "":
		_rebind_feedback.text = GameLocale.text("SETTINGS_KEY_CONFLICT", [
			InputPrompts.key_label(conflict), _binding_name(conflict)])
		return
	var changed_action := _rebind_action
	if InputPrompts.rebind_keyboard(changed_action, event.keycode):
		_rebind_action = ""
		_rebind_feedback.text = GameLocale.text("SETTINGS_KEY_CHANGED", [_binding_name(changed_action), InputPrompts.key_label(changed_action)])
		_refresh_binding_buttons()


func _binding_name(action_name: String) -> String:
	match action_name:
		"game_pause":
			return GameLocale.text("BINDING_PAUSE")
		"game_shake":
			return GameLocale.text("BINDING_SHAKE")
		"staff_interact":
			return GameLocale.text("BINDING_STAFF")
		_:
			return action_name


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if not _rebind_action.is_empty():
			_rebind_action = ""
			_rebind_feedback.text = GameLocale.text("SETTINGS_REBIND_CANCELLED")
			_refresh_binding_buttons()
		elif _display_panel.visible:
			_close_display_settings()
		elif _confirm_panel.visible:
			_cancel_menu()
		else:
			resume_requested.emit()
		get_viewport().set_input_as_handled()
