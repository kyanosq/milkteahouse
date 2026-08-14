## 夜间店铺升级面板：金币消费入口与四条清晰的成长路线。
extends ColorRect
class_name UpgradePanel

signal closed

const AppTheme := preload("res://ui/app_theme.gd")
const CoinIcon := preload("res://assets/icons/hud/coin.png")
const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")

var _cards: HBoxContainer
var _coin_label: Label
var _reserve_label: Label
var _feedback: Label
var _close_button: Button
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
	_panel.position = Vector2(92, 108)
	_panel.custom_minimum_size = Vector2(1096, 500)
	add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	_panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var title := Label.new()
	title.text = "店铺升级"
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
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(coin_icon)
	_coin_label = Label.new()
	_coin_label.add_theme_font_size_override("font_size", 22)
	header.add_child(_coin_label)
	_close_button = Button.new()
	_close_button.text = "返回研发室"
	_close_button.custom_minimum_size = Vector2(152, 48)
	_close_button.pressed.connect(hide_panel)
	header.add_child(_close_button)

	var subtitle := Label.new()
	subtitle.text = "把白天赚到的金币变成效率：每项升级都会直接改变下一次营业。"
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.72)
	root.add_child(subtitle)
	_reserve_label = Label.new()
	_reserve_label.add_theme_font_size_override("font_size", 15)
	_reserve_label.add_theme_color_override("font_color", Color(COCOA.r, COCOA.g, COCOA.b, 0.68))
	root.add_child(_reserve_label)

	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 12)
	root.add_child(_cards)

	_feedback = Label.new()
	_feedback.custom_minimum_size = Vector2(0, 26)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.add_theme_font_size_override("font_size", 17)
	root.add_child(_feedback)


func show_panel() -> void:
	_layout_overscan()
	visible = true
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
	var reserve := UpgradeCatalog.next_day_reserve()
	_reserve_label.text = GameLocale.text("UPGRADE_RESERVE_SUMMARY", [
		int(reserve["day"]), int(reserve["wage"]), int(reserve["rent"]), int(reserve["investable"])])
	for child in _cards.get_children():
		child.free()
	for data in UpgradeCatalog.items():
		_cards.add_child(_upgrade_card(data))


func _upgrade_card(data: Dictionary) -> PanelContainer:
	var current := UpgradeCatalog.level(data["id"])
	var max_level := int(data["max_level"])
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(254, 316)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.985, 0.955, 1.0)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = MINT if current > 0 else Color(COCOA.r, COCOA.g, COCOA.b, 0.14)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", sb)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	card.add_child(box)
	var name := Label.new()
	name.text = String(data["name"])
	name.add_theme_font_size_override("font_size", 22)
	box.add_child(name)
	var level_label := Label.new()
	level_label.text = GameLocale.text("UPGRADE_LEVEL", [current, max_level])
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", MINT if current > 0 else COCOA)
	box.add_child(level_label)
	var progress := ProgressBar.new()
	progress.max_value = max_level
	progress.value = current
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 9)
	box.add_child(progress)
	var description := Label.new()
	description.text = String(data["description"])
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(0, 76)
	description.add_theme_font_size_override("font_size", 15)
	description.modulate = Color(COCOA.r, COCOA.g, COCOA.b, 0.76)
	box.add_child(description)
	var effect := Label.new()
	if current >= max_level:
		effect.text = GameLocale.text("UPGRADE_CURRENT_EFFECT", [String(data["effects"][max_level - 1])])
	else:
		effect.text = GameLocale.text("UPGRADE_NEXT_EFFECT", [String(data["effects"][current])])
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.custom_minimum_size = Vector2(0, 48)
	effect.add_theme_font_size_override("font_size", 16)
	effect.add_theme_color_override("font_color", MINT)
	box.add_child(effect)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grow)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(0, 50)
	if current >= max_level:
		buy.text = GameLocale.text("UPGRADE_MAXED")
		buy.disabled = true
	else:
		var cost := UpgradeCatalog.next_cost(data["id"])
		buy.text = GameLocale.text("UPGRADE_BUY", [cost])
		buy.disabled = GameState.coins < cost
		var reserve := UpgradeCatalog.next_day_reserve()
		var remaining := GameState.coins - cost
		if not buy.disabled and remaining < int(reserve["total"]):
			buy.tooltip_text = GameLocale.text("UPGRADE_RESERVE_RISK", [remaining, int(reserve["total"])])
			buy.add_theme_color_override("font_color", CORAL)
		buy.pressed.connect(_on_buy.bind(String(data["id"])))
	box.add_child(buy)
	return card


func _on_buy(item_id: String) -> void:
	var data := UpgradeCatalog.item(item_id)
	if UpgradeCatalog.buy(item_id):
		_feedback.text = GameLocale.text("UPGRADE_SUCCESS", [String(data["name"])])
		_feedback.add_theme_color_override("font_color", MINT)
		call_deferred("_refresh")
	else:
		_feedback.text = GameLocale.text("UPGRADE_NOT_ENOUGH")
		_feedback.add_theme_color_override("font_color", CORAL)


func _layout_overscan() -> void:
	var geometry := SafeFrame.overscan_geometry(self)
	_safe_offset = geometry["offset"]
	position = -_safe_offset
	size = geometry["size"]
	if _panel != null:
		_panel.position = _safe_offset + Vector2(92, 108)


func _on_locale_changed(_locale: String) -> void:
	if visible:
		_refresh()
