## 配方图鉴：已发现配方给出完整复现公式，未知配方只给研究线索。
extends ColorRect
class_name RecipeBookPanel

signal closed
signal target_changed(recipe_id: String)

const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")
const PLUM := Color("4B2948")
const GOLD := Color("D99A43")

var _panel: PanelContainer
var _title_label: Label
var _progress_label: Label
var _subtitle_label: Label
var _target_label: Label
var _clear_button: Button
var _regular_tab: Button
var _dark_tab: Button
var _research_tab: Button
var _close_button: Button
var _cards: GridContainer
var _feedback: Label
var _show_dark := false
var _show_research := false
var _safe_offset := Vector2.ZERO


func _ready() -> void:
	color = Color(0.055, 0.05, 0.075, 0.94)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	GameLocale.locale_changed.connect(_on_locale_changed)
	get_viewport().size_changed.connect(_layout_overscan)
	_layout_overscan()
	visible = false


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(72, 66)
	_panel.custom_minimum_size = Vector2(1136, 588)
	add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	_panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 30)
	header.add_child(_title_label)
	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 17)
	_progress_label.add_theme_color_override("font_color", MINT)
	header.add_child(_progress_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_close_button = Button.new()
	_close_button.custom_minimum_size = Vector2(154, 46)
	_close_button.pressed.connect(hide_panel)
	header.add_child(_close_button)

	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_size_override("font_size", 15)
	_subtitle_label.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.72)
	root.add_child(_subtitle_label)

	var target_panel := PanelContainer.new()
	var target_style := StyleBoxFlat.new()
	target_style.bg_color = Color(MINT.r, MINT.g, MINT.b, 0.09)
	target_style.set_corner_radius_all(11)
	target_style.set_border_width_all(1)
	target_style.border_color = Color(MINT.r, MINT.g, MINT.b, 0.38)
	target_style.content_margin_left = 12
	target_style.content_margin_right = 8
	target_style.content_margin_top = 5
	target_style.content_margin_bottom = 5
	target_panel.add_theme_stylebox_override("panel", target_style)
	root.add_child(target_panel)
	var target_row := HBoxContainer.new()
	target_panel.add_child(target_row)
	_target_label = Label.new()
	_target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_label.add_theme_font_size_override("font_size", 16)
	target_row.add_child(_target_label)
	_clear_button = Button.new()
	_clear_button.flat = true
	_clear_button.custom_minimum_size = Vector2(132, 34)
	_clear_button.add_theme_color_override("font_color", CORAL)
	_clear_button.add_theme_color_override("font_hover_color", CORAL)
	_clear_button.add_theme_color_override("font_pressed_color", CORAL)
	_clear_button.add_theme_color_override("font_focus_color", CORAL)
	_clear_button.pressed.connect(_clear_target)
	target_row.add_child(_clear_button)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	root.add_child(tab_row)
	_regular_tab = Button.new()
	_regular_tab.custom_minimum_size = Vector2(250, 42)
	_regular_tab.pressed.connect(_switch_tab.bind(false))
	tab_row.add_child(_regular_tab)
	_dark_tab = Button.new()
	_dark_tab.custom_minimum_size = Vector2(250, 42)
	_dark_tab.pressed.connect(_switch_tab.bind(true))
	tab_row.add_child(_dark_tab)
	_research_tab = Button.new()
	_research_tab.custom_minimum_size = Vector2(250, 42)
	_research_tab.pressed.connect(_switch_research_tab)
	tab_row.add_child(_research_tab)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 355)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_cards = GridContainer.new()
	_cards.columns = 3
	_cards.add_theme_constant_override("h_separation", 10)
	_cards.add_theme_constant_override("v_separation", 10)
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_cards)

	_feedback = Label.new()
	_feedback.custom_minimum_size = Vector2(0, 24)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_font_size_override("font_size", 15)
	root.add_child(_feedback)


func show_panel() -> void:
	_layout_overscan()
	visible = true
	_feedback.text = ""
	_refresh()
	_close_button.grab_focus()


func hide_panel() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide_panel()
		get_viewport().set_input_as_handled()


func _switch_tab(dark: bool) -> void:
	_show_dark = dark
	_show_research = false
	_feedback.text = ""
	_refresh()


func _switch_research_tab() -> void:
	_show_dark = false
	_show_research = true
	_feedback.text = ""
	_refresh()


func _refresh() -> void:
	_title_label.text = GameLocale.text("RECIPE_BOOK_TITLE")
	_progress_label.text = GameLocale.text("RECIPE_BOOK_PROGRESS", [
		RecipeJournal.discovery_count(false), RecipeJournal.recipes(false).size(),
		RecipeJournal.discovery_count(true), RecipeJournal.recipes(true).size()])
	_subtitle_label.text = GameLocale.text("RESEARCH_SUBTITLE") if _show_research else GameLocale.text("RECIPE_BOOK_SUBTITLE")
	_close_button.text = GameLocale.text("RECIPE_BOOK_CLOSE")
	_clear_button.text = GameLocale.text("RECIPE_BOOK_CLEAR_TARGET")
	var target_name := RecipeJournal.target_display_name()
	if _show_research:
		_target_label.text = GameLocale.text("RESEARCH_STATUS_COMPLETE", [ResearchProgress.NIGHT_MASTERY_BONUS]) \
			if ResearchProgress.is_complete() else GameLocale.text("RESEARCH_STATUS_PROGRESS", [
				ResearchProgress.seen_count(), ResearchProgress.total_count(), ResearchProgress.NIGHT_MASTERY_BONUS])
		_clear_button.visible = false
	else:
		_target_label.text = GameLocale.text("RECIPE_BOOK_NO_TARGET") if target_name.is_empty() \
			else GameLocale.text("RECIPE_BOOK_TARGET", [target_name])
		_clear_button.visible = not target_name.is_empty()
	_regular_tab.text = GameLocale.text("RECIPE_BOOK_TAB_REGULAR", [
		RecipeJournal.discovery_count(false), RecipeJournal.recipes(false).size()])
	_dark_tab.text = GameLocale.text("RECIPE_BOOK_TAB_DARK", [
		RecipeJournal.discovery_count(true), RecipeJournal.recipes(true).size()])
	_research_tab.text = GameLocale.text("RECIPE_BOOK_TAB_RESEARCH", [
		ResearchProgress.seen_count(), ResearchProgress.total_count()])
	_style_tab(_regular_tab, not _show_dark and not _show_research)
	_style_tab(_dark_tab, _show_dark and not _show_research)
	_style_tab(_research_tab, _show_research)
	for child in _cards.get_children():
		child.free()
	if _show_research:
		_build_research_page()
	else:
		_cards.columns = 3
		_cards.add_theme_constant_override("v_separation", 10)
		var collection := RecipeJournal.recipes(_show_dark)
		for index in collection.size():
			_cards.add_child(_recipe_card(collection[index], index))
	# 卡片动作会销毁持有焦点的按钮；焦点丢失时回到关闭按钮保住键盘/手柄导航。
	if visible and is_inside_tree() and get_viewport().gui_get_focus_owner() == null:
		_close_button.grab_focus()


func _build_research_page() -> void:
	_cards.columns = 5
	_cards.add_theme_constant_override("v_separation", 7)
	_cards.add_child(_matrix_header(GameLocale.text("RESEARCH_PAIR_MATRIX"), CORAL))
	for milk in GameData.milks:
		_cards.add_child(_matrix_header(GameLocale.ingredient_short_name(milk), MINT))
	for base in GameData.bases:
		_cards.add_child(_matrix_header(GameLocale.ingredient_short_name(base), GOLD))
		for milk in GameData.milks:
			_cards.add_child(_pairing_cell(base, milk))
	_cards.add_child(_matrix_header(GameLocale.text("RESEARCH_MASTERY_TITLE", [
		ResearchProgress.mastered_ingredients(), ResearchProgress.ingredients().size()]), CORAL))
	for i in 4:
		var blank := Control.new()
		blank.custom_minimum_size = Vector2(200, 1)
		_cards.add_child(blank)
	for ingredient in ResearchProgress.ingredients():
		_cards.add_child(_mastery_cell(ingredient))


func _matrix_header(copy: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 38)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
	style.set_corner_radius_all(9)
	style.set_border_width_all(1)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.42)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = copy
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = copy
	label.add_theme_font_size_override("font_size", 15)
	# 15px 表头小字不用 CORAL/MINT/GOLD（2.3–2.9:1，P12-F5）；色相语义
	# 保留在格子描边与底色上。
	label.add_theme_color_override("font_color", COCOA)
	panel.add_child(label)
	return panel


func _pairing_cell(base: Dictionary, milk: Dictionary) -> PanelContainer:
	var seen := ResearchProgress.is_seen(String(base["id"]), String(milk["id"]))
	var result := ResearchProgress.pairing(String(base["id"]), String(milk["id"]))
	var rank := String(result.get("rank", "neutral"))
	var accent := ResearchProgress.rank_color(rank) if seen else Color(COCOA.r, COCOA.g, COCOA.b, 0.28)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 58)
	panel.set_meta("pair_cell", true)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.985, 0.955, 1.0) if seen else Color(0.89, 0.88, 0.86, 0.84)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = accent
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	panel.tooltip_text = ResearchProgress.pairing_note(result) if seen else GameLocale.text("RESEARCH_PAIR_UNKNOWN_TOOLTIP")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var rank_label := Label.new()
	rank_label.text = ResearchProgress.rank_name(rank) if seen else "?"
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 16)
	# 等级名 16px 不用档位 accent（对浅格 2.35–2.85:1，P12-F5）；档位色
	# 由格子描边表达。
	rank_label.add_theme_color_override("font_color", COCOA)
	box.add_child(rank_label)
	var detail := Label.new()
	detail.text = GameLocale.text("RESEARCH_PAIR_SCORE", [_signed_score(int(result.get("score", 0)))]) \
		if seen else GameLocale.text("RESEARCH_PAIR_UNTRIED")
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 11)
	detail.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.68)
	box.add_child(detail)
	return panel


func _mastery_cell(ingredient: Dictionary) -> PanelContainer:
	var ingredient_id := String(ingredient["id"])
	var progress := ResearchProgress.level_progress(ingredient_id)
	var active := int(progress["level"]) >= 3
	var accent := MINT if active else GOLD
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 75)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.985, 0.955, 1.0)
	style.set_corner_radius_all(10)
	style.set_border_width_all(1)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.48)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var title := Label.new()
	title.text = GameLocale.text("RESEARCH_MASTERY_LEVEL", [
		GameLocale.ingredient_short_name(ingredient), int(progress["level"])])
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", COCOA)
	box.add_child(title)
	var bar := ProgressBar.new()
	bar.max_value = int(progress["max"])
	bar.value = int(progress["value"])
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	box.add_child(bar)
	var detail := Label.new()
	detail.text = GameLocale.text("RESEARCH_MASTERY_XP", [int(progress["value"]), int(progress["max"])]) \
		+ " · " + ResearchProgress.level_effect(ingredient_id)
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.tooltip_text = detail.text
	detail.add_theme_font_size_override("font_size", 11)
	detail.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.68)
	box.add_child(detail)
	return panel


func _signed_score(value: int) -> String:
	return "+%d" % value if value > 0 else "%d" % value


func _style_tab(button: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = CORAL if active else Color(CREAM.r, CREAM.g, CREAM.b, 0.92)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = CORAL if active else Color(MINT.r, MINT.g, MINT.b, 0.38)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", Color.WHITE if active else COCOA)
	button.add_theme_color_override("font_hover_color", Color.WHITE if active else COCOA)
	button.add_theme_color_override("font_pressed_color", Color.WHITE if active else COCOA)


func _recipe_card(item: Dictionary, index: int) -> PanelContainer:
	var discovered := RecipeJournal.is_discovered(item)
	var available := RecipeJournal.is_available(item)
	var selected := GameState.research_target == String(item.get("id", ""))
	var accent := PLUM if _show_dark else MINT
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(342, 212)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.985, 0.955, 1.0) if available else Color(0.89, 0.88, 0.86, 1.0)
	style.set_corner_radius_all(13)
	style.set_border_width_all(4 if selected else 2)
	style.border_color = CORAL if selected else Color(accent.r, accent.g, accent.b, 0.46)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var status := Label.new()
	status.text = GameLocale.text("RECIPE_BOOK_DISCOVERED") if discovered else GameLocale.text("RECIPE_BOOK_RUMOR")
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", accent)
	box.add_child(status)
	var name := Label.new()
	name.text = GameLocale.recipe_name(item) if discovered else GameLocale.text(
		"RECIPE_BOOK_DARK_UNKNOWN" if _show_dark else "RECIPE_BOOK_UNKNOWN", [index + 1])
	name.add_theme_font_size_override("font_size", 20)
	name.add_theme_color_override("font_color", PLUM if _show_dark else COCOA)
	box.add_child(name)
	var detail := Label.new()
	if discovered:
		if _show_dark:
			detail.text = GameLocale.text("RECIPE_BOOK_DARK_BADGE", [int(item.get("buzz", 0))])
		else:
			detail.text = GameLocale.text("RECIPE_BOOK_TIER", [GameLocale.tier_name(String(item.get("tier", "")))])
		detail.text += "\n" + RecipeJournal.formula(item)
	else:
		detail.text = RecipeJournal.clue(item)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(0, 72)
	detail.add_theme_font_size_override("font_size", 14)
	detail.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.76 if available else 0.52)
	box.add_child(detail)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grow)
	var target_button := Button.new()
	target_button.custom_minimum_size = Vector2(0, 38)
	target_button.text = GameLocale.text("RECIPE_BOOK_TARGET_SET" if selected else "RECIPE_BOOK_SET_TARGET")
	target_button.disabled = selected or not available
	target_button.pressed.connect(_set_target.bind(String(item.get("id", ""))))
	box.add_child(target_button)
	return card


func _set_target(recipe_id: String) -> void:
	if RecipeJournal.set_target(recipe_id):
		_feedback.text = GameLocale.text("RECIPE_BOOK_TARGET_SUCCESS", [RecipeJournal.target_display_name()])
		_feedback.add_theme_color_override("font_color", MINT)
		target_changed.emit(recipe_id)
		# 按钮在将销毁的卡片内：延迟刷新，避免在 pressed 回调里 free 自身。
		call_deferred("_refresh")


func _clear_target() -> void:
	RecipeJournal.clear_target()
	_feedback.text = GameLocale.text("RECIPE_BOOK_TARGET_CLEARED")
	_feedback.add_theme_color_override("font_color", CORAL)
	target_changed.emit("")
	_refresh()


func visible_card_count() -> int:
	return _cards.get_child_count()


## 焦点圈禁入口（P3-F1）：把焦点拉回面板内的关闭按钮。
func confine_focus() -> void:
	_close_button.grab_focus()


func show_dark_tab_for_test() -> void:
	_switch_tab(true)


func show_research_tab_for_test() -> void:
	_switch_research_tab()


func visible_pair_count() -> int:
	var count := 0
	for child in _cards.get_children():
		if child.has_meta("pair_cell"):
			count += 1
	return count


func _layout_overscan() -> void:
	var geometry := SafeFrame.overscan_geometry(self)
	_safe_offset = geometry["offset"]
	position = -_safe_offset
	size = geometry["size"]
	if _panel != null:
		_panel.position = _safe_offset + Vector2(72, 66)


func _on_locale_changed(_locale: String) -> void:
	if visible:
		_refresh()
