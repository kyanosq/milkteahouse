## 游戏入口：提供继续、新游戏确认、设置与退出，避免直接坠入计时营业。
extends Control

const AppTheme := preload("res://ui/app_theme.gd")
const ShopStageScene := preload("res://ui/shop_stage.gd")
const PausePanelScene := preload("res://ui/pause_panel.gd")
const SafeFrameScene := preload("res://ui/safe_frame.gd")
const DayIcon := preload("res://assets/icons/hud/day.png")
const CoinIcon := preload("res://assets/icons/hud/coin.png")

const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")

var continue_button: Button
var new_game_button: Button
var confirm_overlay: ColorRect
var confirm_button: Button
var settings_panel: PausePanel
var has_existing_save := false
var ui_frame: SafeFrame
var input_hint_label: Label
var summary_text: Label


func _ready() -> void:
	var export_smoke := OS.get_cmdline_user_args().has("--export-smoke")
	if export_smoke:
		GameState.test_mode = true
	DisplayPrefs.apply_settings()
	Sfx.play_music("menu")
	theme = AppTheme.build()
	has_existing_save = GameState.has_save()
	_build_background()
	ui_frame = SafeFrameScene.new()
	add_child(ui_frame)
	_build_menu()
	_build_confirmation()
	_build_settings()
	InputPrompts.scheme_changed.connect(_on_input_scheme_changed)
	GameLocale.locale_changed.connect(_on_locale_changed)
	_update_input_hint()
	if _can_continue():
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()
	if export_smoke:
		Sfx.finish_export_smoke()


func _build_background() -> void:
	var stage = ShopStageScene.new()
	add_child(stage)
	stage.build_props(clampi(GameState.day, 1, 5), GameData.sugar_levels[2])
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.085, 0.075, 0.43)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)


func _build_menu() -> void:
	var card := PanelContainer.new()
	card.position = Vector2(74, 70)
	card.custom_minimum_size = Vector2(510, 580)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.985)
	card_style.set_corner_radius_all(24)
	card_style.content_margin_left = 30
	card_style.content_margin_right = 30
	card_style.content_margin_top = 26
	card_style.content_margin_bottom = 24
	card_style.shadow_size = 22
	card_style.shadow_color = Color(0.08, 0.05, 0.04, 0.38)
	card.add_theme_stylebox_override("panel", card_style)
	ui_frame.add_child(card)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	card.add_child(root)

	var eyebrow := Label.new()
	eyebrow.text = "TITLE_TAGLINE"
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", MINT)
	root.add_child(eyebrow)

	var title := Label.new()
	title.text = "TITLE_NAME"
	title.add_theme_font_size_override("font_size", 52)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "TITLE_BLURB"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.72)
	root.add_child(subtitle)

	var summary := PanelContainer.new()
	summary.custom_minimum_size = Vector2(0, 112)
	var summary_style := StyleBoxFlat.new()
	summary_style.bg_color = Color(MINT.r, MINT.g, MINT.b, 0.10)
	summary_style.set_corner_radius_all(14)
	summary_style.set_border_width_all(2)
	summary_style.border_color = Color(MINT.r, MINT.g, MINT.b, 0.36)
	summary_style.content_margin_left = 14
	summary_style.content_margin_right = 14
	summary_style.content_margin_top = 10
	summary_style.content_margin_bottom = 10
	summary.add_theme_stylebox_override("panel", summary_style)
	root.add_child(summary)
	var summary_box := VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 4)
	summary.add_child(summary_box)
	var summary_title := Label.new()
	summary_title.text = "MENU_PROGRESS" if has_existing_save else "MENU_WELCOME"
	summary_title.add_theme_font_size_override("font_size", 16)
	summary_title.add_theme_color_override("font_color", MINT)
	summary_box.add_child(summary_title)
	summary_text = Label.new()
	_refresh_summary_copy()
	summary_text.add_theme_font_size_override("font_size", 18)
	summary_box.add_child(summary_text)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	continue_button = Button.new()
	_refresh_continue_copy()
	continue_button.custom_minimum_size = Vector2(0, 62)
	continue_button.disabled = not _can_continue()
	continue_button.pressed.connect(_continue_game)
	root.add_child(continue_button)

	new_game_button = Button.new()
	new_game_button.text = "MENU_RESTART" if has_existing_save else "MENU_NEW_GAME"
	new_game_button.custom_minimum_size = Vector2(0, 54)
	_style_secondary(new_game_button, MINT)
	new_game_button.pressed.connect(_request_new_game)
	root.add_child(new_game_button)

	var settings := Button.new()
	settings.text = "SETTINGS_BUTTON"
	settings.custom_minimum_size = Vector2(0, 52)
	_style_secondary(settings, Color("D99A43"))
	settings.pressed.connect(_open_settings)
	root.add_child(settings)

	var quit := Button.new()
	quit.text = "MENU_QUIT"
	quit.custom_minimum_size = Vector2(0, 46)
	_style_quiet(quit)
	quit.pressed.connect(func(): get_tree().quit())
	root.add_child(quit)

	input_hint_label = Label.new()
	input_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_hint_label.add_theme_font_size_override("font_size", 14)
	input_hint_label.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.58)
	root.add_child(input_hint_label)

	var version := Label.new()
	version.text = "STEAM PLAYTEST BUILD"
	version.position = Vector2(1038, 680)
	version.add_theme_font_size_override("font_size", 13)
	version.add_theme_color_override("font_color", Color(CREAM.r, CREAM.g, CREAM.b, 0.72))
	ui_frame.add_child(version)


func _build_confirmation() -> void:
	confirm_overlay = ColorRect.new()
	confirm_overlay.color = Color(0.05, 0.04, 0.05, 0.82)
	confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_overlay.visible = false
	add_child(confirm_overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(540, 310)
	confirm_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.text = "MENU_RESTART_CONFIRM"
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	var body := Label.new()
	body.text = GameLocale.text("MENU_RESET_BODY", [GameState.day])
	body.custom_minimum_size = Vector2(500, 88)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	box.add_child(body)
	var note := Label.new()
	note.text = "MENU_RESTART_BODY"
	note.add_theme_color_override("font_color", MINT)
	box.add_child(note)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	var cancel := Button.new()
	cancel.text = "MENU_RESTART_KEEP"
	cancel.custom_minimum_size = Vector2(238, 54)
	_style_secondary(cancel, MINT)
	cancel.pressed.connect(_close_confirmation)
	actions.add_child(cancel)
	confirm_button = Button.new()
	confirm_button.text = "MENU_RESTART_DO"
	confirm_button.custom_minimum_size = Vector2(250, 54)
	confirm_button.pressed.connect(_start_new_game)
	actions.add_child(confirm_button)


func _build_settings() -> void:
	settings_panel = PausePanelScene.new()
	settings_panel.resume_requested.connect(_close_settings)
	ui_frame.add_child(settings_panel)


func _style_secondary(button: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.96)
	normal.set_corner_radius_all(12)
	normal.set_border_width_all(2)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.72)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(accent.r, accent.g, accent.b, 0.13)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.24)
	var focus: StyleBoxFlat = normal.duplicate()
	focus.set_border_width_all(4)
	focus.border_color = COCOA
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, COCOA)


func _style_quiet(button: Button) -> void:
	_style_secondary(button, Color(COCOA.r, COCOA.g, COCOA.b, 0.26))
	button.add_theme_font_size_override("font_size", 16)


func _continue_game() -> void:
	get_tree().change_scene_to_file(_continue_target())


func _can_continue() -> bool:
	return has_existing_save and not GameState.save_write_blocked


func _continue_target() -> String:
	var target := "res://scenes/day_shop/day_shop.tscn"
	if GameState.phase == "night":
		target = "res://scenes/night_lab/night_lab.tscn"
	elif GameState.phase == "campaign":
		target = "res://scenes/campaign_summary/campaign_summary.tscn"
	return target


func _request_new_game() -> void:
	if has_existing_save:
		confirm_overlay.visible = true
		confirm_button.grab_focus()
	else:
		_start_new_game()


func _close_confirmation() -> void:
	confirm_overlay.visible = false
	new_game_button.grab_focus()


func _start_new_game() -> void:
	GameState.reset_progress()
	get_tree().change_scene_to_file("res://scenes/day_shop/day_shop.tscn")


func _open_settings() -> void:
	settings_panel.show_menu_settings()


func _close_settings() -> void:
	settings_panel.hide_panel()
	new_game_button.grab_focus()


func _input(event: InputEvent) -> void:
	if not confirm_overlay.visible:
		return
	var focus := get_viewport().gui_get_focus_owner() as Control
	if focus != null and confirm_overlay.is_ancestor_of(focus):
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_up") \
			or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") \
			or event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		confirm_button.grab_focus()


func _on_input_scheme_changed(_gamepad: bool) -> void:
	_update_input_hint()


func _on_locale_changed(_locale: String) -> void:
	_refresh_continue_state()
	_update_input_hint()


func _refresh_continue_state() -> void:
	if continue_button != null:
		continue_button.disabled = not _can_continue()
	_refresh_summary_copy()
	_refresh_continue_copy()


func _refresh_summary_copy() -> void:
	if summary_text == null:
		return
	if not has_existing_save:
		summary_text.text = GameLocale.text("MENU_WELCOME_BODY")
		return
	if GameState.save_write_blocked:
		summary_text.text = GameLocale.text("MENU_SAVE_UNSUPPORTED")
		return
	var phase_text := GameLocale.text("PHASE_CAMPAIGN") if GameState.phase == "campaign" else (GameLocale.text("PHASE_NIGHT") if GameState.phase == "night" else String(DailyEvents.event_for_day(GameState.day)["name"]))
	var staff_text := GameLocale.staff_name(StaffCatalog.current()) if StaffCatalog.has_staff() else GameLocale.text("STAFF_SOLO")
	summary_text.text = GameLocale.text("MENU_SAVE_SUMMARY", [
		GameState.day, phase_text, GameState.coins, GameState.inspiration,
		UpgradeCatalog.total_levels(), UpgradeCatalog.total_max_levels(), GameState.menu.size(), staff_text])
	if GameState.day >= 15:
		var stamps := int(GameState.endless.get("stamps", 0))
		summary_text.text += GameLocale.text("MENU_SIGN_SUMMARY", [EndlessContracts.rank_name(stamps), stamps])
	if LegacyRoutes.is_active():
		summary_text.text += GameLocale.text("MENU_ROUTE_SUMMARY", [String(LegacyRoutes.route().get("name", ""))])
	# [P2-F4 2026-08-17] 历史成绩常驻主菜单：best_grade/best_score 此前只在收官
	# 报告页脚出现一次；通关过的存档在进度卡追加历史最佳与 3/3 路线进度。
	# 键未进本地化表前静默跳过（带参 % 格式化未翻译键会报错）。
	if int(GameState.legacy.get("campaigns_completed", 0)) > 0 \
			and TranslationServer.translate("MENU_LEGACY_SUMMARY") != "MENU_LEGACY_SUMMARY":
		summary_text.text += GameLocale.text("MENU_LEGACY_SUMMARY", [
			String(GameState.legacy.get("best_grade", "-")),
			int(GameState.legacy.get("best_score", 0)),
			LegacyRoutes.completed_count(), GameState.VALID_NEW_SHOP_ROUTES.size()])
	if GameState.save_recovered:
		summary_text.text += GameLocale.text("MENU_SAVE_RECOVERED")


func _refresh_continue_copy() -> void:
	if continue_button == null:
		return
	if GameState.save_write_blocked:
		continue_button.text = GameLocale.text("MENU_SAVE_UNSUPPORTED_ACTION")
		return
	var continue_action := GameLocale.text("ACTION_VIEW_REPORT") if GameState.phase == "campaign" else (GameLocale.text("ACTION_CONTINUE_RESEARCH") if GameState.phase == "night" else GameLocale.text("ACTION_CONTINUE_SHIFT"))
	continue_button.text = GameLocale.text("MENU_CONTINUE_DAY", [continue_action, GameState.day]) if has_existing_save else GameLocale.text("MENU_NO_SAVE")


func _update_input_hint() -> void:
	if input_hint_label == null:
		return
	input_hint_label.text = GameLocale.text("MENU_INPUT_GAMEPAD", [InputPrompts.accept_hint(),
		InputPrompts.cancel_hint()]) if InputPrompts.gamepad_mode else GameLocale.text("MENU_INPUT_KEYBOARD")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and confirm_overlay.visible:
		_close_confirmation()
		get_viewport().set_input_as_handled()
