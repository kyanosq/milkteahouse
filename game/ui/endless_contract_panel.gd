## 无尽模式经营委托：三种技能取向、明确签约费、明确失败损失与店招进度。
extends ColorRect
class_name EndlessContractPanel

signal closed
signal contract_changed

const CoinIcon := preload("res://assets/icons/hud/coin.png")
const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const GOLD := Color("D99A43")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")

var _panel: PanelContainer
var _cards: HBoxContainer
var _coin_label: Label
var _stats_label: Label
var _rank_label: Label
var _feedback: Label
var _close_button: Button
var _safe_offset := Vector2.ZERO


func _ready() -> void:
	color = Color(0.06, 0.055, 0.075, 0.94)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	GameLocale.locale_changed.connect(_on_locale_changed)
	get_viewport().size_changed.connect(_layout_overscan)
	_layout_overscan()
	visible = false


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(92, 90)
	_panel.custom_minimum_size = Vector2(1096, 540)
	add_child(_panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var title := Label.new()
	title.text = "CONTRACT_INTRO_TITLE"
	title.add_theme_font_size_override("font_size", 30)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var coin_icon := TextureRect.new()
	coin_icon.texture = CoinIcon
	coin_icon.custom_minimum_size = Vector2(30, 30)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(coin_icon)
	_coin_label = Label.new()
	_coin_label.add_theme_font_size_override("font_size", 21)
	header.add_child(_coin_label)
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 14)
	_stats_label.add_theme_color_override("font_color", Color(0.30, 0.22, 0.18, 0.72))
	_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(_stats_label)
	_close_button = Button.new()
	_close_button.text = "PANEL_BACK_LAB"
	_close_button.custom_minimum_size = Vector2(152, 48)
	_close_button.pressed.connect(hide_panel)
	header.add_child(_close_button)

	var subtitle := Label.new()
	subtitle.text = "CONTRACT_INTRO_BODY"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.72)
	root.add_child(subtitle)

	_rank_label = Label.new()
	_rank_label.add_theme_font_size_override("font_size", 17)
	_rank_label.add_theme_color_override("font_color", MINT)
	root.add_child(_rank_label)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 12)
	root.add_child(_cards)

	_feedback = Label.new()
	_feedback.custom_minimum_size = Vector2(0, 25)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_font_size_override("font_size", 16)
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


func _refresh() -> void:
	_coin_label.text = GameLocale.text("COMMON_COINS", [GameState.coins])
	var stamps := int(GameState.endless.get("stamps", 0))
	_rank_label.text = GameLocale.text("ENDLESS_SIGN_RANK", [
		EndlessContracts.rank_name(stamps), stamps, EndlessContracts.next_rank_text(stamps)])
	# 生涯统计行（D6-A）：连胜/完成/失败早已记录，现在让玩家看得见。
	_stats_label.text = GameLocale.text("ENDLESS_CAREER_STATS", [
		int(GameState.endless.get("best_streak", 0)),
		int(GameState.endless.get("completed", 0)),
		int(GameState.endless.get("failed", 0)), stamps])
	for child in _cards.get_children():
		child.free()
	var target_day := GameState.day + 1
	for offer in EndlessContracts.available_for_day(target_day):
		_cards.add_child(_contract_card(offer))


func _contract_card(data: Dictionary) -> PanelContainer:
	var accent := Color(String(data["color"]))
	var active := EndlessContracts.active_contract()
	var chosen := String(active.get("id", "")) == String(data["id"])
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(328, 340)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.985, 0.955, 1.0)
	style.set_corner_radius_all(15)
	style.set_border_width_all(4 if chosen else 2)
	style.border_color = accent if chosen else Color(accent.r, accent.g, accent.b, 0.48)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	card.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	var name := Label.new()
	name.text = String(data["name"])
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size = Vector2(0, 54)
	name.add_theme_font_size_override("font_size", 23)
	name.add_theme_color_override("font_color", accent)
	box.add_child(name)
	var day_copy := Label.new()
	day_copy.text = GameLocale.text("ENDLESS_TARGET_DAY", [int(data["target_day"]), String(data["target_text"])])
	day_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_copy.custom_minimum_size = Vector2(0, 40)
	day_copy.add_theme_font_size_override("font_size", 16)
	box.add_child(day_copy)
	var description := Label.new()
	description.text = String(data["description"])
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(0, 74)
	description.add_theme_font_size_override("font_size", 15)
	description.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.74)
	box.add_child(description)
	var pressure := Label.new()
	pressure.text = _pressure_text(data)
	pressure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pressure.custom_minimum_size = Vector2(0, 38)
	pressure.add_theme_font_size_override("font_size", 14)
	pressure.add_theme_color_override("font_color", CORAL)
	box.add_child(pressure)
	var reward := PanelContainer.new()
	var reward_style := StyleBoxFlat.new()
	reward_style.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
	reward_style.set_corner_radius_all(10)
	reward_style.content_margin_left = 10
	reward_style.content_margin_right = 10
	reward_style.content_margin_top = 8
	reward_style.content_margin_bottom = 8
	reward.add_theme_stylebox_override("panel", reward_style)
	box.add_child(reward)
	var reward_copy := Label.new()
	reward_copy.text = GameLocale.text("ENDLESS_REWARD", [
		int(data["inspiration"]), int(data["refund"])])
	reward_copy.add_theme_font_size_override("font_size", 14)
	reward_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_copy.custom_minimum_size = Vector2(0, 40)
	reward.add_child(reward_copy)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grow)
	var sign := Button.new()
	sign.custom_minimum_size = Vector2(0, 50)
	if chosen:
		sign.text = GameLocale.text("ENDLESS_SIGNED")
		sign.disabled = true
	elif not active.is_empty():
		sign.text = GameLocale.text("ENDLESS_OTHER_SIGNED")
		sign.disabled = true
	else:
		sign.text = GameLocale.text("ENDLESS_SIGN_COST", [int(data["cost"])])
		sign.disabled = GameState.coins < int(data["cost"])
		sign.pressed.connect(_sign.bind(String(data["id"]), int(data["target_day"])))
	box.add_child(sign)
	return card


func _pressure_text(data: Dictionary) -> String:
	var spawn_pct := roundi((1.0 - float(data.get("spawn_mult", 1.0))) * 100.0)
	var patience_delta := roundi((float(data.get("patience_mult", 1.0)) - 1.0) * 100.0)
	var spawn_copy := GameLocale.text("ENDLESS_TRAFFIC_DELTA", [spawn_pct]) if spawn_pct > 0 else GameLocale.text("ENDLESS_TRAFFIC_NORMAL")
	var patience_copy := GameLocale.text("ENDLESS_PATIENCE_DELTA", [patience_delta]) if patience_delta != 0 else GameLocale.text("ENDLESS_PATIENCE_NORMAL")
	return GameLocale.text("ENDLESS_PRESSURE", [spawn_copy, patience_copy])


func _sign(contract_id: String, target_day: int) -> void:
	if EndlessContracts.sign_contract(contract_id, target_day):
		_feedback.text = GameLocale.text("ENDLESS_SIGN_SUCCESS")
		_feedback.add_theme_color_override("font_color", MINT)
		Sfx.play("coin")
		contract_changed.emit()
		call_deferred("_refresh")
	else:
		_feedback.text = GameLocale.text("ENDLESS_SIGN_FAILED")
		_feedback.add_theme_color_override("font_color", CORAL)


func _layout_overscan() -> void:
	var geometry := SafeFrame.overscan_geometry(self)
	_safe_offset = geometry["offset"]
	position = -_safe_offset
	size = geometry["size"]
	if _panel != null:
		_panel.position = _safe_offset + Vector2(92, 90)


func _on_locale_changed(_locale: String) -> void:
	if visible:
		_refresh()
