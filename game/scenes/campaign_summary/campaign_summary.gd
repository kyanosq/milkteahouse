## 第一家店的 14 天终局：把经营结果转成可读评级，并给出无限经营或新周目选择。
extends Control

const AppTheme := preload("res://ui/app_theme.gd")
const ShopStageScene := preload("res://ui/shop_stage.gd")
const SafeFrameScene := preload("res://ui/safe_frame.gd")
const PerfectIcon := preload("res://assets/icons/hud/perfect.png")
const CoinIcon := preload("res://assets/icons/hud/coin.png")
const InspirationIcon := preload("res://assets/icons/hud/inspiration.png")
const DayIcon := preload("res://assets/icons/hud/day.png")

const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")
const GOLD := Color("D99A43")

var summary: Dictionary
var grade_label: Label
var score_label: Label
var continue_button: Button
var new_shop_button: Button
var confirm_overlay: ColorRect
var confirm_button: Button
var ui_frame: SafeFrame
var selected_route := "rush"
var route_buttons: Dictionary = {}
var route_detail_label: Label


func _ready() -> void:
	Sfx.play_music("campaign")
	theme = AppTheme.build()
	summary = GameState.finalize_campaign()
	_localize_summary()
	_build_background()
	ui_frame = SafeFrameScene.new()
	add_child(ui_frame)
	_build_report()
	_build_confirmation()
	continue_button.grab_focus()


func _build_background() -> void:
	var stage = ShopStageScene.new()
	add_child(stage)
	stage.build_props(5, GameData.sugar_levels[2])
	var tint := ColorRect.new()
	tint.color = Color(0.10, 0.075, 0.07, 0.70)
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)


func _build_report() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(90, 42)
	panel.custom_minimum_size = Vector2(1100, 636)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.99)
	style.set_corner_radius_all(26)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 24
	style.content_margin_bottom = 22
	style.shadow_size = 24
	style.shadow_color = Color(0.06, 0.035, 0.03, 0.46)
	panel.add_theme_stylebox_override("panel", style)
	ui_frame.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var eyebrow := Label.new()
	eyebrow.text = GameLocale.text("CAMPAIGN_EYEBROW")
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", MINT)
	root.add_child(eyebrow)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 122)
	header.add_theme_constant_override("separation", 22)
	root.add_child(header)
	var headline := VBoxContainer.new()
	headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headline.add_theme_constant_override("separation", 3)
	header.add_child(headline)
	var title := Label.new()
	title.text = String(summary["title"])
	title.add_theme_font_size_override("font_size", 38)
	headline.add_child(title)
	var verdict := Label.new()
	verdict.text = String(summary["verdict"])
	verdict.custom_minimum_size = Vector2(760, 52)
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	verdict.add_theme_font_size_override("font_size", 17)
	verdict.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.72)
	headline.add_child(verdict)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(218, 116)
	var badge_style := StyleBoxFlat.new()
	var accent := _grade_color(String(summary["grade"]))
	badge_style.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
	badge_style.set_corner_radius_all(18)
	badge_style.set_border_width_all(3)
	badge_style.border_color = accent
	badge.add_theme_stylebox_override("panel", badge_style)
	header.add_child(badge)
	var badge_row := HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_row.add_theme_constant_override("separation", 12)
	badge.add_child(badge_row)
	grade_label = Label.new()
	grade_label.text = String(summary["grade"])
	grade_label.add_theme_font_size_override("font_size", 68)
	grade_label.add_theme_color_override("font_color", accent)
	badge_row.add_child(grade_label)
	var score_box := VBoxContainer.new()
	badge_row.add_child(score_box)
	var rating_copy := Label.new()
	rating_copy.text = GameLocale.text("CAMPAIGN_RATING")
	rating_copy.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.64)
	score_box.add_child(rating_copy)
	score_label = Label.new()
	score_label.text = "%d / 100" % int(summary["score"])
	score_label.add_theme_font_size_override("font_size", 21)
	score_box.add_child(score_label)

	var division_title := Label.new()
	division_title.text = GameLocale.text("CAMPAIGN_DIMENSIONS")
	division_title.add_theme_font_size_override("font_size", 18)
	root.add_child(division_title)
	var dimensions := HBoxContainer.new()
	dimensions.add_theme_constant_override("separation", 10)
	root.add_child(dimensions)
	_dimension_card(dimensions, GameLocale.text("CAMPAIGN_DIM_CRAFT"), int(summary["craft"]), 35,
		GameLocale.text("CAMPAIGN_DIM_CRAFT_DETAIL", [int(summary["perfect"]), int(summary["upgrade_levels"]), UpgradeCatalog.total_max_levels()]), CORAL)
	_dimension_card(dimensions, GameLocale.text("CAMPAIGN_DIM_CREATIVITY"), int(summary["creativity"]), 30,
		GameLocale.text("CAMPAIGN_DIM_CREATIVITY_DETAIL", [int(summary["discoveries"]), int(summary["menu_count"])]), MINT)
	_dimension_card(dimensions, GameLocale.text("CAMPAIGN_DIM_MOMENTUM"), int(summary["momentum"]), 20,
		GameLocale.text("CAMPAIGN_DIM_MOMENTUM_DETAIL", [int(summary["coins"]), int(summary["buzz"])]), GOLD)
	var stats: Dictionary = summary.get("stats", {})
	var expected_days := maxi(1, 15 - int(stats.get("tracking_start_day", 1)))
	_dimension_card(dimensions, GameLocale.text("CAMPAIGN_DIM_JOURNEY"), int(summary["journey"]), 15,
		GameLocale.text("CAMPAIGN_DIM_JOURNEY_DETAIL", [int(stats.get("days_completed", 0)), expected_days, int(stats.get("stars", 0))]), Color("6F79C9"))

	var highlights := HBoxContainer.new()
	highlights.add_theme_constant_override("separation", 10)
	highlights.custom_minimum_size = Vector2(0, 78)
	root.add_child(highlights)
	_highlight(highlights, PerfectIcon, GameLocale.text("CAMPAIGN_HIGHLIGHT_SERVED"), GameLocale.text("COMMON_CUPS", [int(stats.get("served", 0))]))
	_highlight(highlights, CoinIcon, GameLocale.text("CAMPAIGN_HIGHLIGHT_REVENUE"), "%d" % int(stats.get("revenue", 0)))
	_highlight(highlights, InspirationIcon, GameLocale.text("CAMPAIGN_HIGHLIGHT_SPECIAL"), GameLocale.text("COMMON_TIMES", [int(stats.get("special_served", 0))]))
	_highlight(highlights, DayIcon, GameLocale.text("CAMPAIGN_HIGHLIGHT_COMBO"), "x%d" % int(stats.get("best_streak", 0)))

	var legacy_line := Label.new()
	var staff_name := String(summary.get("staff_name", GameLocale.text("STAFF_SOLO")))
	var team_text := GameLocale.text("CAMPAIGN_TEAM", [staff_name, int(stats.get("staff_days", 0))]) if not String(summary.get("staff_id", "")).is_empty() else ""
	legacy_line.text = team_text + GameLocale.text("CAMPAIGN_LEGACY", [
		int(GameState.legacy.get("campaigns_completed", 0)), String(GameState.legacy.get("best_grade", "-")), int(GameState.legacy.get("best_score", 0))]) \
		+ GameLocale.text("CAMPAIGN_ROUTES_CLEARED", [LegacyRoutes.completed_count(), LegacyRoutes.IDS.size()])
	# 回暖日脚注（D5）：用了几天宽限一目了然，评级语境透明。
	var relief_days := int(GameState.campaign_stats.get("relief_days", 0))
	if relief_days > 0:
		legacy_line.text += GameLocale.text("CAMPAIGN_RELIEF_DAYS", [relief_days])
	# 店铺定位（D1②）：收官报告展示互斥选择。
	# 路线专属统计（D3）：每条路线一行最引以为傲的数字。
	match LegacyRoutes.active_id():
		"trend":
			legacy_line.text += GameLocale.text("CAMPAIGN_ROUTE_STAT_TREND", [
				int(GameState.campaign_stats.get("matched_served", 0))])
		"precision":
			legacy_line.text += GameLocale.text("CAMPAIGN_ROUTE_STAT_PRECISION", [
				int(GameState.campaign_stats.get("critic_served", 0))])
		"rush":
			legacy_line.text += GameLocale.text("CAMPAIGN_ROUTE_STAT_RUSH", [
				int(GameState.campaign_stats.get("served", 0))])
	var positioning_id := UpgradeCatalog.positioning()
	if not positioning_id.is_empty():
		var positioning_name := ""
		for source in UpgradeCatalog.positionings():
			if String(source["id"]) == positioning_id:
				positioning_name = String(source["name"])
		legacy_line.text += GameLocale.text("CAMPAIGN_POSITIONING", [positioning_name])
	legacy_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legacy_line.add_theme_font_size_override("font_size", 15)
	legacy_line.add_theme_color_override("font_color", MINT)
	root.add_child(legacy_line)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)
	continue_button = Button.new()
	continue_button.text = GameLocale.text("CAMPAIGN_CONTINUE")
	continue_button.custom_minimum_size = Vector2(430, 54)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.pressed.connect(_continue_endless)
	actions.add_child(continue_button)
	new_shop_button = Button.new()
	new_shop_button.text = GameLocale.text("CAMPAIGN_NEW_SHOP")
	new_shop_button.custom_minimum_size = Vector2(310, 54)
	_style_secondary(new_shop_button, MINT)
	new_shop_button.pressed.connect(_request_new_shop)
	actions.add_child(new_shop_button)
	var menu_button := Button.new()
	menu_button.text = GameLocale.text("CAMPAIGN_RETURN_TITLE")
	menu_button.custom_minimum_size = Vector2(190, 54)
	_style_secondary(menu_button, GOLD)
	menu_button.pressed.connect(_return_menu)
	actions.add_child(menu_button)

	var challenge := PanelContainer.new()
	challenge.custom_minimum_size = Vector2(0, 52)
	var challenge_style := StyleBoxFlat.new()
	challenge_style.bg_color = Color(MINT.r, MINT.g, MINT.b, 0.075)
	challenge_style.set_corner_radius_all(12)
	challenge_style.set_border_width_all(1)
	challenge_style.border_color = Color(MINT.r, MINT.g, MINT.b, 0.28)
	challenge_style.content_margin_left = 14
	challenge_style.content_margin_right = 14
	challenge_style.content_margin_top = 10
	challenge_style.content_margin_bottom = 10
	challenge.add_theme_stylebox_override("panel", challenge_style)
	root.add_child(challenge)
	var challenge_text := Label.new()
	challenge_text.text = _next_challenge()
	challenge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge_text.add_theme_font_size_override("font_size", 15)
	challenge_text.add_theme_color_override("font_color", MINT)
	challenge.add_child(challenge_text)


func _dimension_card(parent: HBoxContainer, title_text: String, value: int, maximum: int,
		detail_text: String, accent: Color) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(252, 126)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.075)
	style.set_corner_radius_all(14)
	style.set_border_width_all(1)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.34)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var title := Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	row.add_child(title)
	var score := Label.new()
	score.text = "%d / %d" % [value, maximum]
	score.add_theme_font_size_override("font_size", 20)
	score.add_theme_color_override("font_color", accent)
	row.add_child(score)
	# 精通玩家要一眼看到“每维还差几分”（P2 试玩）——报告直接量化到满分差距。
	if value < maximum:
		var deficit := Label.new()
		deficit.text = GameLocale.text("CAMPAIGN_DIM_DEFICIT", [maximum - value])
		deficit.add_theme_font_size_override("font_size", 12)
		deficit.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.85))
		deficit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		box.add_child(deficit)
	var progress := ProgressBar.new()
	progress.max_value = maximum
	progress.value = value
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 11)
	box.add_child(progress)
	var detail := Label.new()
	detail.text = detail_text
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 13)
	detail.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.66)
	box.add_child(detail)


func _highlight(parent: HBoxContainer, texture: Texture2D, title_text: String, value_text: String) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.92, 0.86, 0.80)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var box := VBoxContainer.new()
	row.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 13)
	title.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.62)
	box.add_child(title)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 19)
	box.add_child(value)


func _build_confirmation() -> void:
	confirm_overlay = ColorRect.new()
	confirm_overlay.color = Color(0.04, 0.03, 0.03, 0.84)
	confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_overlay.visible = false
	add_child(confirm_overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(900, 520)
	confirm_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	panel.add_child(box)
	var title := Label.new()
	title.text = GameLocale.text("CAMPAIGN_CONFIRM_TITLE")
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var body := Label.new()
	var bonus := _legacy_bonus(String(summary["grade"]))
	body.text = GameLocale.text("CAMPAIGN_CONFIRM_BODY", [String(summary["grade"]), int(bonus["coins"]), int(bonus["inspiration"])])
	body.custom_minimum_size = Vector2(850, 76)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 17)
	box.add_child(body)
	var route_title := Label.new()
	route_title.text = GameLocale.text("LEGACY_ROUTE_SELECT_TITLE")
	route_title.add_theme_font_size_override("font_size", 18)
	route_title.add_theme_color_override("font_color", MINT)
	box.add_child(route_title)
	var route_row := HBoxContainer.new()
	route_row.add_theme_constant_override("separation", 10)
	box.add_child(route_row)
	for route_data in LegacyRoutes.routes():
		var route_id := String(route_data["id"])
		var route_button := Button.new()
		route_button.toggle_mode = true
		route_button.custom_minimum_size = Vector2(276, 106)
		route_button.add_theme_font_size_override("font_size", 15)
		route_button.pressed.connect(_select_route.bind(route_id))
		_style_secondary(route_button, Color(String(route_data["color"])))
		route_row.add_child(route_button)
		route_buttons[route_id] = route_button
	route_detail_label = Label.new()
	route_detail_label.custom_minimum_size = Vector2(850, 42)
	route_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_detail_label.add_theme_font_size_override("font_size", 15)
	route_detail_label.add_theme_color_override("font_color", COCOA)
	box.add_child(route_detail_label)
	var note := Label.new()
	note.text = GameLocale.text("CAMPAIGN_CONFIRM_NOTE")
	note.add_theme_color_override("font_color", MINT)
	box.add_child(note)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)
	var cancel := Button.new()
	cancel.text = GameLocale.text("CAMPAIGN_CANCEL")
	cancel.custom_minimum_size = Vector2(248, 54)
	_style_secondary(cancel, MINT)
	cancel.pressed.connect(_close_confirmation)
	actions.add_child(cancel)
	confirm_button = Button.new()
	confirm_button.text = GameLocale.text("CAMPAIGN_CONFIRM")
	confirm_button.custom_minimum_size = Vector2(260, 54)
	confirm_button.pressed.connect(_start_new_shop)
	actions.add_child(confirm_button)
	_refresh_route_selection()


func _grade_color(grade: String) -> Color:
	return {"S": GOLD, "A": CORAL, "B": MINT, "C": Color("80635A")}.get(grade, COCOA)


func _legacy_bonus(grade: String) -> Dictionary:
	return {
		"S": {"coins": 80, "inspiration": 3},
		"A": {"coins": 60, "inspiration": 2},
		"B": {"coins": 40, "inspiration": 1},
		"C": {"coins": 20, "inspiration": 0},
	}.get(grade, {"coins": 20, "inspiration": 0})


func _next_challenge() -> String:
	var gaps := [
		{"score": int(summary["craft"]) / 35.0, "text": GameLocale.text("CAMPAIGN_CHALLENGE_CRAFT")},
		{"score": int(summary["creativity"]) / 30.0, "text": GameLocale.text("CAMPAIGN_CHALLENGE_CREATIVITY")},
		{"score": int(summary["momentum"]) / 20.0, "text": GameLocale.text("CAMPAIGN_CHALLENGE_MOMENTUM")},
		{"score": int(summary["journey"]) / 15.0, "text": GameLocale.text("CAMPAIGN_CHALLENGE_JOURNEY")},
	]
	gaps.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["score"]) < float(b["score"]))
	return GameLocale.text("CAMPAIGN_NEXT_CHALLENGE", [String(gaps[0]["text"])])


func _localize_summary() -> void:
	var grade := String(summary.get("grade", "C"))
	summary["title"] = GameLocale.text("CAMPAIGN_TITLE_%s" % grade)
	summary["verdict"] = GameLocale.text("CAMPAIGN_VERDICT_%s" % grade)
	var staff_id := String(summary.get("staff_id", ""))
	if not staff_id.is_empty():
		for item in GameData.staff_list:
			if String(item.get("id", "")) == staff_id:
				summary["staff_name"] = GameLocale.staff_name(item)
				break
	else:
		summary["staff_name"] = GameLocale.text("STAFF_SOLO")


func _style_secondary(button: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.96)
	normal.set_corner_radius_all(12)
	normal.set_border_width_all(2)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.68)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(accent.r, accent.g, accent.b, 0.13)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.24)
	var focus: StyleBoxFlat = normal.duplicate()
	focus.set_border_width_all(4)
	focus.border_color = accent
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, COCOA)


# 同帧双设备（手柄+键盘）可双击一次性按钮：第二次调用会读已清空的
# campaign_summary，把 S 级奖金降级成 C 或直接跳过第 15 天（评审 R9）。
var _transition_started := false


func _continue_endless() -> void:
	if _transition_started:
		return
	_transition_started = true
	GameState.continue_after_campaign()
	get_tree().change_scene_to_file("res://scenes/day_shop/day_shop.tscn")


func _request_new_shop() -> void:
	_refresh_route_selection()
	confirm_overlay.visible = true
	var selected_button: Button = route_buttons.get(selected_route)
	if selected_button != null:
		selected_button.grab_focus()


func _close_confirmation() -> void:
	confirm_overlay.visible = false
	new_shop_button.grab_focus()


func _start_new_shop() -> void:
	if _transition_started:
		return
	_transition_started = true
	GameState.start_new_shop_plus(selected_route)
	get_tree().change_scene_to_file("res://scenes/day_shop/day_shop.tscn")


func _select_route(route_id: String) -> void:
	if not LegacyRoutes.is_valid(route_id):
		return
	selected_route = route_id
	_refresh_route_selection()
	confirm_button.grab_focus()


func _refresh_route_selection() -> void:
	if not LegacyRoutes.is_valid(selected_route):
		selected_route = "rush"
	for route_id in route_buttons:
		var button: Button = route_buttons[route_id]
		var data := LegacyRoutes.route(String(route_id))
		var selected := String(route_id) == selected_route
		button.button_pressed = selected
		button.text = GameLocale.text("LEGACY_ROUTE_CARD", [
			"✓" if selected else "○", String(data["name"]),
			String(data["risk"]), String(data["reward"])])
	var chosen := LegacyRoutes.route(selected_route)
	if route_detail_label != null:
		route_detail_label.text = "%s\n%s" % [
			String(chosen.get("summary", "")), String(chosen.get("calendar", ""))]


func _return_menu() -> void:
	GameState.phase = "campaign"
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and confirm_overlay.visible:
		_close_confirmation()
		get_viewport().set_input_as_handled()
