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
# 批量策展的落盘防抖（P11-F4）：面板内改动 0.6s 合并一次写盘，关闭时冲掉。
var _catalog_dirty := false
var _catalog_save_generation := 0
# 策展操作的焦点保持（P3-F8）：记录被操作卡在网格中的索引，刷新后回到同卡。
var _focus_card_index := -1


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
	persist_catalog_now()
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
	# 批量策展（P3-F8）：优先回到被操作的那张卡，其次才是关闭按钮兜底。
	if not _restore_card_focus():
		_restore_focus()


func _refresh_featured() -> void:
	var featured := MenuCatalog.featured_items()
	var tomorrow := DailyEvents.next_event(GameState.day)
	var tomorrow_id := String(tomorrow.get("id", "calm"))
	# 槽位分母走路线感知入口（P7-F1）：rush 只有 2 个主推槽，写死 3 会把
	# 「2/3 槽」「三个槽已满」变成假情报。
	var slot_limit := MenuCatalog.featured_limit()
	_title_label.text = GameLocale.text("MENU_BOARD_TITLE")
	_progress_label.text = GameLocale.text("MENU_BOARD_PROGRESS", [
		featured.size(), slot_limit, MenuCatalog.hot_featured_count()])
	_subtitle_label.text = GameLocale.text("MENU_BOARD_SUBTITLE_SLOTS", [slot_limit]) \
		if slot_limit != GameState.FEATURED_MENU_LIMIT else GameLocale.text("MENU_BOARD_SUBTITLE")
	# 客流百分比带符号（P5-5）：溢价减速为负值时不得渲染成 "+-9%"。
	var traffic_delta := roundi((1.0 - MenuCatalog.traffic_multiplier()) * 100.0)
	_impact_label.text = GameLocale.text("MENU_BOARD_FORECAST", [
		String(tomorrow.get("name", "")), MenuCatalog.event_match_count(tomorrow_id),
		("+" if traffic_delta >= 0 else "") + str(traffic_delta)])
	# 快手风向的定价咬合提示（P5-4）：让 ≤13 币匹配规则在菜单板上可发现。
	if tomorrow_id == "lunch_rush":
		_impact_label.text += " " + GameLocale.text("LUNCH_RUSH_PRICE_HINT", [13])
	for item_data in MenuCatalog.items():
		_cards.add_child(_menu_card(item_data))


func _refresh_dark() -> void:
	var dark_items := MenuCatalog.dark_items()
	var available := MenuCatalog.dark_order_items().size()
	_title_label.text = GameLocale.text("DARK_BOARD_TITLE")
	_progress_label.text = GameLocale.text("DARK_BOARD_PROGRESS", [dark_items.size(), GameState.DARK_MENU_LIMIT, available])
	_subtitle_label.text = GameLocale.text("DARK_BOARD_SUBTITLE")
	if _dark_candidate.is_empty():
		_impact_label.text = GameLocale.text("DARK_BOARD_IMPACT", [
			MenuCatalog.DARK_ORDER_INTERVAL, roundi((1.0 - MenuCatalog.buzz_traffic_multiplier(GameState.day + 1)) * 100.0)])
	else:
		_impact_label.text = GameLocale.text("DARK_BOARD_CANDIDATE", [
			MenuCatalog.dark_display_name(_dark_candidate), MenuCatalog.dark_formula_text(_dark_candidate)])
	for slot in GameState.DARK_MENU_LIMIT:
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
	# DP#4 定价：自创饮品可在三档作者价点间切换（让利提速/标准/溢价减速），
	# 传说配方保持作者定价不参与。选定态用珊瑚主色，互斥同组。
	var price_options := MenuCatalog.price_options(item_data)
	if not price_options.is_empty():
		var price_row := HBoxContainer.new()
		price_row.add_theme_constant_override("separation", 6)
		box.add_child(price_row)
		var price_caption := Label.new()
		price_caption.text = GameLocale.text("MENU_BOARD_PRICE")
		price_caption.add_theme_font_size_override("font_size", 13)
		price_caption.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.62)
		price_row.add_child(price_caption)
		var group := ButtonGroup.new()
		var standard := int(MenuCatalog.PRICE_STANDARD.get(String(item_data.get("tier", "")), 0))
		var current_price := int(item_data.get("price", standard))
		for price in price_options:
			var delta := int(price) - standard
			var style_key := "MENU_BOARD_PRICE_STANDARD" if delta == 0 \
				else "MENU_BOARD_PRICE_BUDGET" if delta < 0 else "MENU_BOARD_PRICE_PREMIUM"
			var option_button := Button.new()
			option_button.text = GameLocale.text(style_key, [int(price)])
			option_button.tooltip_text = GameLocale.text(style_key + "_TIP")
			option_button.toggle_mode = true
			option_button.button_group = group
			option_button.set_pressed_no_signal(int(price) == current_price)
			option_button.custom_minimum_size = Vector2(0, 30)
			option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option_button.add_theme_font_size_override("font_size", 13)
			if int(price) == current_price:
				for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
					option_button.add_theme_color_override(state, CORAL)
			option_button.pressed.connect(_on_price_pressed.bind(item_id, int(price)))
			price_row.add_child(option_button)
	var event_fit := Label.new()
	event_fit.text = GameLocale.text("MENU_BOARD_EVENT_MATCH", [match_bonus]) if match_bonus > 0 \
		else GameLocale.text("MENU_BOARD_EVENT_NEUTRAL")
	event_fit.add_theme_font_size_override("font_size", 13)
	# 13px 小字不用 GOLD/半透明（对卡底 2.35:1，P12-F5）：契合与否由文案本身
	# （+N / 常规）表达，颜色保持全对比可可。
	event_fit.add_theme_color_override("font_color", COCOA)
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
	_remember_focused_card()
	if MenuCatalog.install_dark_candidate(_dark_candidate, slot, false):
		_dark_candidate = {}
		_feedback.text = GameLocale.text("DARK_BOARD_REPLACED")
		_feedback.add_theme_color_override("font_color", MINT)
		menu_changed.emit()
		_schedule_catalog_save()
	else:
		_feedback.text = GameLocale.text("MENU_BOARD_INVALID")
		_feedback.add_theme_color_override("font_color", CORAL)
	call_deferred("_refresh")


func _remove_dark(slot: int) -> void:
	_remember_focused_card()
	if MenuCatalog.remove_dark_slot(slot, false):
		_feedback.text = GameLocale.text("DARK_BOARD_REMOVED")
		_feedback.add_theme_color_override("font_color", MINT)
		menu_changed.emit()
		_schedule_catalog_save()
	call_deferred("_refresh")


func _toggle_item(item_id: String, active: bool) -> void:
	_remember_focused_card()
	var result := MenuCatalog.set_featured(item_id, active, false)
	match result:
		"ok":
			_feedback.text = GameLocale.text("MENU_BOARD_UPDATED")
			_feedback.add_theme_color_override("font_color", MINT)
			menu_changed.emit()
			_schedule_catalog_save()
		"full":
			_feedback.text = _slots_full_text()
			_feedback.add_theme_color_override("font_color", CORAL)
		"minimum":
			_feedback.text = GameLocale.text("MENU_BOARD_MINIMUM")
			_feedback.add_theme_color_override("font_color", CORAL)
		_:
			_feedback.text = GameLocale.text("MENU_BOARD_INVALID")
			_feedback.add_theme_color_override("font_color", CORAL)
	call_deferred("_refresh")


func _on_price_pressed(item_id: String, price: int) -> void:
	_remember_focused_card()
	if MenuCatalog.set_item_price(item_id, price, false):
		_feedback.text = GameLocale.text("MENU_BOARD_PRICE_SET", [price])
		_feedback.add_theme_color_override("font_color", MINT)
		_schedule_catalog_save()
	else:
		_feedback.text = GameLocale.text("MENU_BOARD_INVALID")
		_feedback.add_theme_color_override("font_color", CORAL)
	call_deferred("_refresh")


## 「已满」文案按实际槽位数（P7-F1）：rush 是 2 槽，不能说「三个槽已满」。
func _slots_full_text() -> String:
	var slot_limit := MenuCatalog.featured_limit()
	return GameLocale.text("MENU_BOARD_FULL_SLOTS", [slot_limit]) \
		if slot_limit != GameState.FEATURED_MENU_LIMIT else GameLocale.text("MENU_BOARD_FULL")


## 记录持焦控件所在的卡片索引，供刷新后回焦（P3-F8）。
func _remember_focused_card() -> void:
	_focus_card_index = -1
	var focus := get_viewport().gui_get_focus_owner() as Control
	if focus == null:
		return
	for i in _cards.get_child_count():
		if _cards.get_child(i).is_ancestor_of(focus):
			_focus_card_index = i
			return


func _restore_card_focus() -> bool:
	if _focus_card_index < 0 or _focus_card_index >= _cards.get_child_count():
		_focus_card_index = -1
		return false
	var card: Control = _cards.get_child(_focus_card_index)
	_focus_card_index = -1
	if not visible or not is_inside_tree():
		return false
	return _grab_first_action_button(card)


func _grab_first_action_button(root: Node) -> bool:
	for child in root.get_children():
		if child is Button and not child.disabled and child.focus_mode != Control.FOCUS_NONE:
			(child as Button).grab_focus()
			return true
		if _grab_first_action_button(child):
			return true
	return false


## 批量策展的写盘防抖（P11-F4）：目录写方法 persist=false，面板内 0.6s 合并
## 一次完整落盘；关闭面板/离开夜间时立即冲掉（参考暂停面板的 generation 防抖）。
func _schedule_catalog_save() -> void:
	_catalog_dirty = true
	_catalog_save_generation += 1
	var generation := _catalog_save_generation
	await get_tree().create_timer(0.6).timeout
	if _catalog_save_generation == generation:
		persist_catalog_now()


func persist_catalog_now() -> void:
	_catalog_save_generation += 1
	if not _catalog_dirty:
		return
	_catalog_dirty = false
	GameState.save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _catalog_dirty:
		GameState.save_game()
		_catalog_dirty = false


## 焦点圈禁入口（P3-F1）：把焦点拉回面板内的关闭按钮。
func confine_focus() -> void:
	_close_button.grab_focus()


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
