## 夜间招聘面板：三名有线索但隐藏特质的候选人与单员工位管理。
extends ColorRect
class_name StaffPanel

signal closed
signal roster_changed

const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")
const GOLD := Color("D99A43")

var _content: VBoxContainer
var _coin_label: Label
var _feedback: Label
var _close_button: Button
var _dismiss_armed := false
var _panel: PanelContainer
var _safe_offset := Vector2.ZERO


func _ready() -> void:
	color = Color(0.08, 0.07, 0.09, 0.92)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	GameLocale.locale_changed.connect(_on_locale_changed)
	get_viewport().size_changed.connect(_layout_overscan)
	_layout_overscan()
	visible = false


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(92, 94)
	_panel.custom_minimum_size = Vector2(1096, 526)
	add_child(_panel)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 13)
	_panel.add_child(_content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_content.add_child(header)
	var title := Label.new()
	title.text = "员工招聘 · 1 个岗位"
	title.add_theme_font_size_override("font_size", 30)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_coin_label = Label.new()
	_coin_label.add_theme_font_size_override("font_size", 21)
	_coin_label.add_theme_color_override("font_color", GOLD)
	header.add_child(_coin_label)
	_close_button = Button.new()
	_close_button.text = "返回研发室"
	_close_button.custom_minimum_size = Vector2(152, 48)
	_close_button.pressed.connect(hide_panel)
	header.add_child(_close_button)

	var subtitle := Label.new()
	subtitle.text = "数值决定基本能力；性格特质入职后由真实事件揭晓。每种好处都有看得见的代价。"
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.72)
	_content.add_child(subtitle)

	_feedback = Label.new()
	_feedback.custom_minimum_size = Vector2(0, 26)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_font_size_override("font_size", 16)
	_content.add_child(_feedback)


func show_panel() -> void:
	_layout_overscan()
	visible = true
	_dismiss_armed = false
	_refresh()
	_close_button.grab_focus()


func hide_panel() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide_panel()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	_coin_label.text = GameLocale.text("COMMON_COINS", [GameState.coins])
	while _content.get_child_count() > 3:
		_content.get_child(3).free()
	if StaffCatalog.has_staff():
		_content.add_child(_current_staff_card())
	else:
		var cards := HBoxContainer.new()
		cards.add_theme_constant_override("separation", 12)
		_content.add_child(cards)
		for data in StaffCatalog.candidates():
			cards.add_child(_candidate_card(data))


func _candidate_card(data: Dictionary) -> PanelContainer:
	var card := _card_shell(MINT)
	card.custom_minimum_size = Vector2(338, 330)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var name := Label.new()
	name.text = GameLocale.staff_name(data)
	name.add_theme_font_size_override("font_size", 26)
	box.add_child(name)
	var role := Label.new()
	role.text = GameLocale.text("STAFF_CANDIDATE_WAGE", [int(data["wage"])])
	role.add_theme_color_override("font_color", GOLD)
	box.add_child(role)
	box.add_child(_stats_row(data))
	var intro_title := Label.new()
	intro_title.text = GameLocale.text("STAFF_INTRO_TITLE")
	intro_title.add_theme_font_size_override("font_size", 14)
	intro_title.add_theme_color_override("font_color", MINT)
	box.add_child(intro_title)
	var intro := Label.new()
	intro.text = GameLocale.text("STAFF_QUOTE", [GameLocale.staff_intro(data)])
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(0, 66)
	intro.add_theme_font_size_override("font_size", 16)
	box.add_child(intro)
	var hidden := Label.new()
	hidden.text = GameLocale.text("STAFF_TRAIT_HIDDEN")
	hidden.add_theme_color_override("font_color", CORAL)
	box.add_child(hidden)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grow)
	var hire := Button.new()
	hire.text = GameLocale.text("STAFF_HIRE", [StaffCatalog.HIRE_COST])
	hire.custom_minimum_size = Vector2(0, 50)
	hire.disabled = GameState.coins < StaffCatalog.HIRE_COST
	hire.pressed.connect(_hire.bind(String(data["id"])))
	box.add_child(hire)
	return card


func _current_staff_card() -> PanelContainer:
	var data := StaffCatalog.current()
	var card := _card_shell(CORAL)
	card.custom_minimum_size = Vector2(0, 330)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	card.add_child(row)
	var identity := VBoxContainer.new()
	identity.custom_minimum_size = Vector2(310, 0)
	identity.add_theme_constant_override("separation", 8)
	row.add_child(identity)
	var state := Label.new()
	var rests_today := StaffCatalog.rests_on(GameState.day)
	var rests_next := StaffCatalog.rests_on(GameState.day + 1)
	if rests_next:
		state.text = GameLocale.text("STAFF_REST_SCHEDULED", [GameState.day + 1])
		state.add_theme_color_override("font_color", CORAL)
	elif rests_today:
		state.text = GameLocale.text("STAFF_REST_COMPLETE", [GameState.day + 1])
		state.add_theme_color_override("font_color", MINT)
	else:
		state.text = GameLocale.text("STAFF_ON_DUTY")
		state.add_theme_color_override("font_color", MINT)
	identity.add_child(state)
	var name := Label.new()
	name.text = GameLocale.staff_name(data)
	name.add_theme_font_size_override("font_size", 34)
	identity.add_child(name)
	var wage := Label.new()
	if rests_next:
		wage.text = GameLocale.text("STAFF_WAGE_SHORTFALL_STATUS", [
			StaffCatalog.wage_shortfall(), GameState.day + 1])
	elif rests_today:
		wage.text = GameLocale.text("STAFF_WAGE_REST_STATUS", [GameState.day + 1])
	else:
		wage.text = GameLocale.text("STAFF_WAGE_DAYS", [StaffCatalog.wage(), int(data.get("days_worked", 0))])
	wage.add_theme_color_override("font_color", GOLD)
	identity.add_child(wage)
	identity.add_child(_stats_row(data))

	var effect_box := VBoxContainer.new()
	effect_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_box.add_theme_constant_override("separation", 10)
	row.add_child(effect_box)
	var trait_title := Label.new()
	trait_title.text = GameLocale.text("STAFF_TRAIT_REVEALED", [StaffCatalog.trait_name()]) \
		if StaffCatalog.trait_revealed() else GameLocale.text("STAFF_TRAIT_UNREVEALED")
	trait_title.add_theme_font_size_override("font_size", 24)
	trait_title.add_theme_color_override("font_color", CORAL if StaffCatalog.trait_revealed() else MINT)
	effect_box.add_child(trait_title)
	var effect := Label.new()
	effect.text = StaffCatalog.effect_summary(StaffCatalog.trait_revealed())
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.custom_minimum_size = Vector2(0, 68)
	effect.add_theme_font_size_override("font_size", 18)
	effect_box.add_child(effect)
	var intro := Label.new()
	intro.text = GameLocale.text("STAFF_JOINED_QUOTE", [GameLocale.staff_intro(data)])
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 16)
	intro.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.68)
	effect_box.add_child(intro)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	effect_box.add_child(grow)
	var dismiss := Button.new()
	dismiss.text = GameLocale.text("STAFF_DISMISS_CONFIRM") if _dismiss_armed \
		else GameLocale.text("STAFF_DISMISS", [StaffCatalog.DISMISS_COST])
	dismiss.custom_minimum_size = Vector2(0, 50)
	dismiss.disabled = GameState.coins < StaffCatalog.DISMISS_COST
	dismiss.pressed.connect(_dismiss)
	effect_box.add_child(dismiss)
	return card


func _stats_row(data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for stat in [[GameLocale.text("STAFF_STAT_SPEED"), data["speed"]], [GameLocale.text("STAFF_STAT_CARE"), data["care"]], [GameLocale.text("STAFF_STAT_CHARM"), data["charm"]]]:
		var chip := PanelContainer.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = Color(MINT.r, MINT.g, MINT.b, 0.09)
		style.set_corner_radius_all(9)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		chip.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = "%s %s" % [stat[0], stat[1]]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(label)
		row.add_child(chip)
	return row


func _card_shell(accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.985, 0.955, 1.0)
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", style)
	return card


func _hire(candidate_id: String) -> void:
	if StaffCatalog.hire(candidate_id):
		_feedback.text = GameLocale.text("STAFF_HIRE_SUCCESS", [GameLocale.staff_name(StaffCatalog.current())])
		_feedback.add_theme_color_override("font_color", MINT)
		roster_changed.emit()
		call_deferred("_refresh")
	else:
		_feedback.text = GameLocale.text("STAFF_HIRE_FAILED")
		_feedback.add_theme_color_override("font_color", CORAL)


func _dismiss() -> void:
	if not _dismiss_armed:
		_dismiss_armed = true
		_feedback.text = GameLocale.text("STAFF_DISMISS_WARNING")
		_feedback.add_theme_color_override("font_color", CORAL)
		_refresh()
		return
	if StaffCatalog.dismiss():
		_dismiss_armed = false
		_feedback.text = GameLocale.text("STAFF_DISMISS_SUCCESS")
		_feedback.add_theme_color_override("font_color", MINT)
		roster_changed.emit()
		call_deferred("_refresh")


func _layout_overscan() -> void:
	var geometry := SafeFrame.overscan_geometry(self)
	_safe_offset = geometry["offset"]
	position = -_safe_offset
	size = geometry["size"]
	if _panel != null:
		_panel.position = _safe_offset + Vector2(92, 94)


func _on_locale_changed(_locale: String) -> void:
	if visible:
		_refresh()
