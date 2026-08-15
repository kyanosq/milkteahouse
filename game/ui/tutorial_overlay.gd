## 首日五步引导：暂停营业计时，逐步解释订单、并行备料、制作、交付与成长闭环。
extends ColorRect
class_name TutorialOverlay

signal finished

const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")

const STEPS := [
	{
		# 第 1 步聚光灯指 HUD 目标行：玩家第一个要认识的是“今天要挣多少”（D2-A）。
		"focus": Rect2(8, 4, 400, 68),
		"card": Vector2(680, 128),
	},
	{
		"focus": Rect2(430, 190, 816, 100),
		"card": Vector2(680, 304),
	},
	{
		"focus": Rect2(426, 64, 824, 168),
		"card": Vector2(640, 248),
	},
	{
		"focus": Rect2(542, 286, 274, 292),
		# 卡片移到杯子左侧：原 (760,304) 与高亮区右缘 816 重叠约 56px（P3 试玩）。
		"card": Vector2(36, 330),
	},
	{
		"focus": Rect2(8, 4, 770, 68),
		"card": Vector2(390, 222),
	},
	{
		# 第 6 步：目标与星级规则（营收目标 / 1.4× 三星线 / 120 秒打烊）。
		"focus": Rect2(8, 4, 400, 68),
		"card": Vector2(390, 300),
	},
]

var _step := 0
var _replay := false
var _card: PanelContainer
var _focus: PanelContainer
var _progress: Label
var _title: Label
var _body: Label
var _hint: Label
var _next: Button
var _safe_offset := Vector2.ZERO


func _ready() -> void:
	color = Color(0.06, 0.055, 0.07, 0.58)
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
	_focus = PanelContainer.new()
	_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(1, 1, 1, 0.04)
	focus_style.set_corner_radius_all(16)
	focus_style.set_border_width_all(4)
	focus_style.border_color = MINT
	focus_style.shadow_size = 12
	focus_style.shadow_color = Color(MINT.r, MINT.g, MINT.b, 0.32)
	_focus.add_theme_stylebox_override("panel", focus_style)
	add_child(_focus)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(500, 272)
	add_child(_card)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.99)
	card_style.set_corner_radius_all(18)
	card_style.content_margin_left = 22
	card_style.content_margin_right = 22
	card_style.content_margin_top = 18
	card_style.content_margin_bottom = 18
	card_style.shadow_size = 14
	card_style.shadow_color = Color(0, 0, 0, 0.30)
	_card.add_theme_stylebox_override("panel", card_style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_card.add_child(box)
	_progress = Label.new()
	_progress.add_theme_font_size_override("font_size", 15)
	_progress.add_theme_color_override("font_color", MINT)
	box.add_child(_progress)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 28)
	box.add_child(_title)
	_body = Label.new()
	_body.custom_minimum_size = Vector2(456, 72)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 17)
	box.add_child(_body)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Color(COCOA.r, COCOA.g, COCOA.b, 0.68))
	box.add_child(_hint)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	var skip := Button.new()
	skip.text = "跳过教学"
	skip.custom_minimum_size = Vector2(140, 50)
	skip.pressed.connect(_finish)
	actions.add_child(skip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	_next = Button.new()
	_next.custom_minimum_size = Vector2(160, 50)
	_next.pressed.connect(_advance)
	actions.add_child(_next)


func start(replay := false) -> void:
	_replay = replay
	_step = 0
	visible = true
	_render_step()


func _render_step() -> void:
	var data: Dictionary = STEPS[_step]
	_progress.text = GameLocale.text("TUTORIAL_PROGRESS", [_step + 1, STEPS.size()])
	_title.text = GameLocale.text("TUTORIAL_%d_TITLE" % (_step + 1))
	_body.text = GameLocale.text("TUTORIAL_%d_BODY" % (_step + 1))
	_hint.text = _device_hint(_step, GameLocale.text("TUTORIAL_%d_HINT" % (_step + 1)))
	_focus.position = _safe_offset + data["focus"].position
	_focus.size = data["focus"].size
	_card.position = _safe_offset + data["card"]
	# Wrapped labels briefly report a taller minimum while their width is settling.
	# Refit after the container sort so later cards do not retain that transient size.
	_card.call_deferred("reset_size")
	_next.text = GameLocale.text("TUTORIAL_START" if _step == STEPS.size() - 1 else "TUTORIAL_NEXT")
	_next.grab_focus()


func _device_hint(step: int, keyboard_hint: String) -> String:
	if not InputPrompts.gamepad_mode:
		if step == 3:
			return GameLocale.text("TUTORIAL_SHAKE_HINT", [InputPrompts.shake_hint()])
		return keyboard_hint
	match step:
		0:
			return GameLocale.text("TUTORIAL_GAMEPAD_1", [InputPrompts.accept_hint()])
		1:
			return GameLocale.text("TUTORIAL_GAMEPAD_2", [InputPrompts.prep_tea_hint(), InputPrompts.prep_pearl_hint()])
		2:
			return GameLocale.text("TUTORIAL_GAMEPAD_3", [InputPrompts.accept_hint()])
		3:
			return GameLocale.text("TUTORIAL_GAMEPAD_4", [InputPrompts.shake_hint(), InputPrompts.accept_hint()])
		_:
			return GameLocale.text("TUTORIAL_GAMEPAD_5")


func _on_input_scheme_changed(_gamepad: bool) -> void:
	if visible:
		_render_step()


func _on_bindings_changed() -> void:
	if visible:
		_render_step()


func _on_locale_changed(_locale: String) -> void:
	if visible:
		_render_step()


func _layout_overscan() -> void:
	var geometry := SafeFrame.overscan_geometry(self)
	_safe_offset = geometry["offset"]
	position = -_safe_offset
	size = geometry["size"]
	if visible and _card != null:
		var data: Dictionary = STEPS[_step]
		_focus.position = _safe_offset + data["focus"].position
		_card.position = _safe_offset + data["card"]


func _advance() -> void:
	if _step < STEPS.size() - 1:
		_step += 1
		_render_step()
	else:
		_finish()


func _finish() -> void:
	visible = false
	if not _replay:
		GameState.tutorial_completed = true
		GameState.save_game()
	finished.emit()
