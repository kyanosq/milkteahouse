## 夜间主推菜单管理：最多三款，至少保留一款，让研发结果成为次日经营选择。
extends ColorRect
class_name MenuBoardPanel

signal closed
signal menu_changed

const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")
const GOLD := Color("D99A43")

var _panel: PanelContainer
var _title_label: Label
var _progress_label: Label
var _subtitle_label: Label
var _impact_label: Label
var _close_button: Button
var _featured_tab: Button
var _dark_tab: Button
var _cards: GridContainer
var _feedback: Label
var _safe_offset := Vector2.ZERO
var _mode := "featured"
var _dark_candidate: Dictionary = {}


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
	root.add_theme_constant_override("separation", 10)
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
	_subtitle_label.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.74)
	root.add_child(_subtitle_label)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	_featured_tab = Button.new()
	_featured_tab.custom_minimum_size = Vector2(190, 38)
	_featured_tab.pressed.connect(_switch_mode.bind("featured"))
	tabs.add_child(_featured_tab)
	_dark_tab = Button.new()
	_dark_tab.custom_minimum_size = Vector2(190, 38)
	_dark_tab.pressed.connect(_switch_mode.bind("dark"))
	tabs.add_child(_dark_tab)

	var impact_panel := PanelContainer.new()
	var impact_style := StyleBoxFlat.new()
	impact_style.bg_color = Color(MINT.r, MINT.g, MINT.b, 0.09)
	impact_style.set_corner_radius_all(11)
	impact_style.set_border_width_all(1)
	impact_style.border_color = Color(MINT.r, MINT.g, MINT.b, 0.40)
	impact_style.content_margin_left = 12
	impact_style.content_margin_right = 12
	impact_style.content_margin_top = 7
	impact_style.content_margin_bottom = 7
	impact_panel.add_theme_stylebox_override("panel", impact_style)
	root.add_child(impact_panel)
	_impact_label = Label.new()
	_impact_label.add_theme_font_size_override("font_size", 15)
	impact_panel.add_child(_impact_label)

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
	_mode = "featured"
	_feedback.text = ""
	_refresh()
	_close_button.grab_focus()


func show_dark_candidate(candidate: Dictionary) -> void:
	if candidate.is_empty():
		return
	_layout_overscan()
	_dark_candidate = candidate.duplicate(true)
	_mode = "dark"
	visible = true
	_feedback.text = ""
	_refresh()
	_dark_tab.grab_focus()


func hide_panel() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide_panel()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	_close_button.text = GameLocale.text("MENU_BOARD_CLOSE")
	_featured_tab.text = GameLocale.text("MENU_BOARD_TAB_FEATURED")
	_dark_tab.text = GameLocale.text("MENU_BOARD_TAB_DARK")
	_featured_tab.disabled = _mode == "featured"
	_dark_tab.disabled = _mode == "dark"
	for child in _cards.get_children():
		child.free()
	if _mode == "dark":
		_refresh_dark()
	else:
		_refresh_featured()
	_restore_focus()


func _refresh_featured() -> void:
	var featured := MenuCatalog.featured_items()
	var tomorrow := DailyEvents.next_event(GameState.day)
	var tomorrow_id := String(tomorrow.get("id", "calm"))
	_title_label.text = GameLocale.text("MENU_BOARD_TITLE")
	_progress_label.text = GameLocale.text("MENU_BOARD_PROGRESS", [
		featured.size(), MenuCatalog.FEATURED_LIMIT, MenuCatalog.hot_featured_count()])
	_subtitle_label.text = GameLocale.text("MENU_BOARD_SUBTITLE")
	_impact_label.text = GameLocale.text("MENU_BOARD_FORECAST", [
		String(tomorrow.get("name", "")), MenuCatalog.event_match_count(tomorrow_id),
		roundi((1.0 - MenuCatalog.traffic_multiplier()) * 100.0)])
	for item_data in MenuCatalog.items():
		_cards.add_child(_menu_card(item_data))


func _refresh_dark() -> void:
	var dark_items := MenuCatalog.dark_items()
	var available := MenuCatalog.dark_order_items().size()
	_title_label.text = GameLocale.text("DARK_BOARD_TITLE")
	_progress_label.text = GameLocale.text("DARK_BOARD_PROGRESS", [dark_items.size(), MenuCatalog.DARK_LIMIT, available])
	_subtitle_label.text = GameLocale.text("DARK_BOARD_SUBTITLE")
	if _dark_candidate.is_empty():
		_impact_label.text = GameLocale.text("DARK_BOARD_IMPACT", [
			MenuCatalog.DARK_ORDER_INTERVAL, roundi((1.0 - MenuCatalog.buzz_traffic_multiplier(GameState.day + 1)) * 100.0)])
	else:
		_impact_label.text = GameLocale.text("DARK_BOARD_CANDIDATE", [
			MenuCatalog.dark_display_name(_dark_candidate), MenuCatalog.dark_formula_text(_dark_candidate)])
	for slot in MenuCatalog.DARK_LIMIT:
		if slot < dark_items.size():
			_cards.add_child(_dark_card(slot, dark_items[slot]))
		else:
			_cards.add_child(_empty_dark_card(slot))


func _switch_mode(mode: String) -> void:
	_mode = mode
	_feedback.text = ""
	_refresh()


func _menu_card(item_data: Dictionary) -> PanelContainer:
	var item_id := String(item_data.get("id", ""))
	var selected := MenuCatalog.is_featured(item_id)
	var available := MenuCatalog.formula_available(item_data)
	var hot := int(item_data.get("hype_remaining", 0)) > 0
	var tomorrow_id := String(DailyEvents.next_event(GameState.day).get("id", "calm"))
	var match_bonus := MenuCatalog.event_match_bonus(item_data, tomorrow_id)
	var accent := CORAL if selected else (GOLD if hot else MINT)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(342, 226)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.985, 0.955, 1.0) if available else Color(0.89, 0.88, 0.86, 1.0)
	style.set_corner_radius_all(13)
	style.set_border_width_all(4 if selected else 2)
	style.border_color = accent
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var status := Label.new()
	status.text = GameLocale.text("MENU_BOARD_FEATURED" if selected else (
		"MENU_BOARD_AVAILABLE" if available else "MENU_BOARD_LEGACY"))
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", accent)
	box.add_child(status)
	var name := Label.new()
	name.text = MenuCatalog.display_name(item_data)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.tooltip_text = name.text
	name.add_theme_font_size_override("font_size", 21)
	box.add_child(name)
	var meta := Label.new()
	meta.text = GameLocale.text("MENU_BOARD_META", [
		GameLocale.tier_name(String(item_data.get("tier", "普通"))),
		MenuCatalog.sale_price(item_data), MenuCatalog.hype_text(item_data)])
	meta.add_theme_font_size_override("font_size", 14)
	meta.add_theme_color_override("font_color", accent)
	box.add_child(meta)
	var event_fit := Label.new()
	event_fit.text = GameLocale.text("MENU_BOARD_EVENT_MATCH", [match_bonus]) if match_bonus > 0 \
		else GameLocale.text("MENU_BOARD_EVENT_NEUTRAL")
	event_fit.add_theme_font_size_override("font_size", 13)
	event_fit.add_theme_color_override("font_color", GOLD if match_bonus > 0 else Color(COCOA.r, COCOA.g, COCOA.b, 0.52))
	box.add_child(event_fit)
	var formula := Label.new()
	formula.text = MenuCatalog.formula_text(item_data)
	formula.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	formula.custom_minimum_size = Vector2(0, 58)
	formula.add_theme_font_size_override("font_size", 13)
	formula.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.72 if available else 0.50)
	box.add_child(formula)
	var sales := Label.new()
	sales.text = GameLocale.text("MENU_BOARD_SALES", [int(item_data.get("sales", 0))])
	sales.add_theme_font_size_override("font_size", 13)
	sales.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.62)
	box.add_child(sales)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grow)
	var action := Button.new()
	action.custom_minimum_size = Vector2(0, 39)
	action.text = GameLocale.text("MENU_BOARD_REMOVE" if selected else "MENU_BOARD_FEATURE")
	action.disabled = not available
	action.pressed.connect(_toggle_item.bind(item_id, not selected))
	box.add_child(action)
	return card


func _dark_card(slot: int, entry: Dictionary) -> PanelContainer:
	var available := MenuCatalog.dark_formula_available(entry)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(342, 226)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.115, 0.18, 0.98)
	style.set_corner_radius_all(13)
	style.set_border_width_all(3 if not _dark_candidate.is_empty() else 2)
	style.border_color = Color("8C67B5") if available else Color("7B6E6A")
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var status := Label.new()
	status.text = GameLocale.text("DARK_BOARD_SLOT", [slot + 1])
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color("C6A7E2"))
	box.add_child(status)
	var name := Label.new()
	name.text = MenuCatalog.dark_display_name(entry)
	name.add_theme_font_size_override("font_size", 21)
	name.add_theme_color_override("font_color", CREAM)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.tooltip_text = name.text
	box.add_child(name)
	var meta := Label.new()
	meta.text = GameLocale.text("DARK_BOARD_META", [MenuCatalog.dark_sale_price(entry), int(entry.get("sales", 0))])
	meta.add_theme_font_size_override("font_size", 14)
	meta.add_theme_color_override("font_color", GOLD)
	box.add_child(meta)
	var formula := Label.new()
	formula.text = MenuCatalog.dark_formula_text(entry)
	formula.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	formula.custom_minimum_size = Vector2(0, 70)
	formula.add_theme_font_size_override("font_size", 13)
	formula.add_theme_color_override("font_color", Color(1.0, 0.97, 0.91, 0.78))
	box.add_child(formula)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grow)
	var action := Button.new()
	action.custom_minimum_size = Vector2(0, 39)
	if not _dark_candidate.is_empty():
		action.text = GameLocale.text("DARK_BOARD_REPLACE")
		action.disabled = not MenuCatalog.dark_formula_available(_dark_candidate)
		action.pressed.connect(_replace_dark.bind(slot))
	else:
		action.text = GameLocale.text("DARK_BOARD_UNLIST")
		action.pressed.connect(_remove_dark.bind(slot))
	box.add_child(action)
	return card


func _empty_dark_card(slot: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(342, 226)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.15, 0.18, 0.72)
	style.set_corner_radius_all(13)
	style.set_border_width_all(2)
	style.border_color = Color(0.55, 0.46, 0.60, 0.55)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var title := Label.new()
	title.text = GameLocale.text("DARK_BOARD_EMPTY_SLOT", [slot + 1])
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", CREAM)
	box.add_child(title)
	var body := Label.new()
	body.text = GameLocale.text("DARK_BOARD_EMPTY_HINT")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(1.0, 0.97, 0.91, 0.68))
	box.add_child(body)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grow)
	if not _dark_candidate.is_empty():
		var add := Button.new()
		add.custom_minimum_size = Vector2(0, 39)
		add.text = GameLocale.text("DARK_BOARD_ADD_CANDIDATE")
		add.pressed.connect(_replace_dark.bind(slot))
		box.add_child(add)
	return card


func _replace_dark(slot: int) -> void:
	if MenuCatalog.install_dark_candidate(_dark_candidate, slot):
		_dark_candidate = {}
		_feedback.text = GameLocale.text("DARK_BOARD_REPLACED")
		_feedback.add_theme_color_override("font_color", MINT)
		menu_changed.emit()
	else:
		_feedback.text = GameLocale.text("MENU_BOARD_INVALID")
		_feedback.add_theme_color_override("font_color", CORAL)
	call_deferred("_refresh")


func _remove_dark(slot: int) -> void:
	if MenuCatalog.remove_dark_slot(slot):
		_feedback.text = GameLocale.text("DARK_BOARD_REMOVED")
		_feedback.add_theme_color_override("font_color", MINT)
		menu_changed.emit()
	call_deferred("_refresh")


func _toggle_item(item_id: String, active: bool) -> void:
	var result := MenuCatalog.set_featured(item_id, active)
	match result:
		"ok":
			_feedback.text = GameLocale.text("MENU_BOARD_UPDATED")
			_feedback.add_theme_color_override("font_color", MINT)
			menu_changed.emit()
		"full":
			_feedback.text = GameLocale.text("MENU_BOARD_FULL")
			_feedback.add_theme_color_override("font_color", CORAL)
		"minimum":
			_feedback.text = GameLocale.text("MENU_BOARD_MINIMUM")
			_feedback.add_theme_color_override("font_color", CORAL)
		_:
			_feedback.text = GameLocale.text("MENU_BOARD_INVALID")
			_feedback.add_theme_color_override("font_color", CORAL)
	call_deferred("_refresh")


func visible_card_count() -> int:
	return _cards.get_child_count()


## 卡片按钮的 pressed 回调里不能同步 free 自己所在的卡片；动作后用延迟刷新，
## 并在焦点随卡片销毁丢失时回到关闭按钮，保住手柄/键盘导航。
func _restore_focus() -> void:
	if visible and is_inside_tree() and get_viewport().gui_get_focus_owner() == null:
		_close_button.grab_focus()


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
