## 首日五步引导：暂停营业计时，逐步解释订单、并行备料、制作、交付与成长闭环。
extends Control
class_name TutorialOverlay

signal finished

const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
## 深薄荷：描边/强调色。MINT 本体对奶油底只有 2.3:1，聚光描边与进度文字
## 改用加深档（≈4.9:1），保留色相语义（P12 试玩对比度核实）。
const MINT_DEEP := Color("0E7A6C")
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
## D2-B 交互门控：由 day_shop 注入 (step) -> bool；步骤 3/4 需真实选料/封杯。
var progress_provider: Callable
var final_step_values: Array = []
var _gate_fails := 0
var _gate_bypassed := false
# 聚光灯“开洞”：四块暗幕围出聚焦区，洞内透出原始场景（对比度不被压暗）。
var _dim_top: ColorRect
var _dim_bottom: ColorRect
var _dim_left: ColorRect
var _dim_right: ColorRect
var _card: PanelContainer
var _focus: PanelContainer
var _progress: Label
var _title: Label
var _body: Label
var _hint: Label
var _next: Button
var _skip: Button
var _safe_offset := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	# 拦截点击由四块暗幕负责：根节点保持穿透，门控练习期整层放行。
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	InputPrompts.scheme_changed.connect(_on_input_scheme_changed)
	InputPrompts.bindings_changed.connect(_on_bindings_changed)
	GameLocale.locale_changed.connect(_on_locale_changed)
	get_viewport().size_changed.connect(_layout_overscan)
	_layout_overscan()
	visible = false


func _build() -> void:
	_dim_top = ColorRect.new()
	_dim_bottom = ColorRect.new()
	_dim_left = ColorRect.new()
	_dim_right = ColorRect.new()
	_dim_top.color = Color(0.06, 0.055, 0.07, 0.58)
	_dim_bottom.color = _dim_top.color
	_dim_left.color = _dim_top.color
	_dim_right.color = _dim_top.color
	add_child(_dim_top)
	add_child(_dim_bottom)
	add_child(_dim_left)
	add_child(_dim_right)

	_focus = PanelContainer.new()
	_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var focus_style := StyleBoxFlat.new()
	# 开洞后聚焦区不再叠 4% 白（那会同时提亮前景与底色、反而降低对比度）；
	# 描边加深加宽到 5px，对奶油底 ≈4.9:1，越过图形对象 3:1 线。
	focus_style.bg_color = Color(0, 0, 0, 0)
	focus_style.draw_center = false
	focus_style.set_corner_radius_all(16)
	focus_style.set_border_width_all(5)
	focus_style.border_color = MINT_DEEP
	focus_style.shadow_size = 12
	focus_style.shadow_color = Color(MINT_DEEP.r, MINT_DEEP.g, MINT_DEEP.b, 0.30)
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
	_progress.add_theme_color_override("font_color", COCOA)
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
	_skip = Button.new()
	_skip.custom_minimum_size = Vector2(140, 50)
	_skip.pressed.connect(_finish)
	# 跳过是次级操作：主题默认会把 Button 渲染成珊瑚主按钮，与“下一步”抢主 CTA
	# 的视觉权重（P3 试玩）。降级为奶油底 + 可可描边的次级样式。
	_style_secondary(_skip)
	actions.add_child(_skip)
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
	# 重看必须重新过门控：上一轮的 bypass/失败计数跨重看保留会让练习步
	# 直接放行或只剩一次机会（P11 试玩）。
	_gate_fails = 0
	_gate_bypassed = false
	visible = true
	_render_step()


func _render_step() -> void:
	var data: Dictionary = STEPS[_step]
	_progress.text = GameLocale.text("TUTORIAL_PROGRESS", [_step + 1, STEPS.size()])
	_title.text = GameLocale.text("TUTORIAL_%d_TITLE" % (_step + 1))
	_body.text = GameLocale.text("TUTORIAL_%d_BODY" % (_step + 1),
		final_step_values if _step == STEPS.size() - 1 else [])
	_hint.text = _device_hint(_step, GameLocale.text("TUTORIAL_%d_HINT" % (_step + 1)))
	_skip.text = GameLocale.text("TUTORIAL_SKIP")
	if _gate_bypassed:
		_hint.text += "\n" + GameLocale.text("TUTORIAL_GATE_RELEASED_NOTE")
	elif _step_is_gated() and _gate_fails > 0:
		_hint.text += "\n" + GameLocale.text("TUTORIAL_GATE_HINT", [2 - _gate_fails])
	_focus.position = _safe_offset + data["focus"].position
	_focus.size = data["focus"].size
	_card.position = _safe_offset + data["card"]
	_apply_gate_mouse_rules()
	_update_dim_geometry()
	# Wrapped labels briefly report a taller minimum while their width is settling.
	# Refit after the container sort so later cards do not retain that transient size.
	_card.call_deferred("reset_size")
	_next.text = GameLocale.text("TUTORIAL_START" if _step == STEPS.size() - 1 else "TUTORIAL_NEXT")
	# 延迟 grab：_show_tutorial 里顾客生成排队的 deferred grab 在前、本请求在后，
	# 后入队者后执行——教程必然赢回焦点（P3-F4 同帧竞争路径）。
	_next.call_deferred("grab_focus")


## 门控练习期（步骤 3/4）：点击必须真实到达店铺控件，教学遮罩整体放行；
## 观察步骤恢复全屏拦截的模态语义（聚焦框此时也参与拦截洞口）。
func _apply_gate_mouse_rules() -> void:
	var blocking := not _step_is_gated()
	var filter := Control.MOUSE_FILTER_STOP if blocking else Control.MOUSE_FILTER_IGNORE
	for dim in [_dim_top, _dim_bottom, _dim_left, _dim_right]:
		dim.mouse_filter = filter
	_focus.mouse_filter = filter


## 四块暗幕围出聚焦矩形：洞内透出原始场景，洞外保持 0.58 暗层。
func _update_dim_geometry() -> void:
	if _dim_top == null:
		return
	var hole := Rect2(_focus.position, _focus.size)
	var full := Rect2(Vector2.ZERO, size)
	_dim_top.position = Vector2.ZERO
	_dim_top.size = Vector2(full.size.x, maxf(0.0, hole.position.y))
	_dim_bottom.position = Vector2(0.0, hole.end.y)
	_dim_bottom.size = Vector2(full.size.x, maxf(0.0, full.size.y - hole.end.y))
	_dim_left.position = Vector2(0.0, hole.position.y)
	_dim_left.size = Vector2(maxf(0.0, hole.position.x), maxf(0.0, hole.size.y))
	_dim_right.position = Vector2(hole.end.x, hole.position.y)
	_dim_right.size = Vector2(maxf(0.0, full.size.x - hole.end.x), maxf(0.0, hole.size.y))


## day_shop 的输入豁免入口：门控练习步骤进行中（可见 + 步骤 3/4）。
func gated_practice_active() -> bool:
	return visible and _step_is_gated()


## 聚焦洞口是否被某个暗幕覆盖（回归钉位用：True = 没有真开洞）。
func hole_covers_point(point: Vector2) -> bool:
	for dim in [_dim_top, _dim_bottom, _dim_left, _dim_right]:
		if dim == null:
			continue
		if Rect2(dim.position, dim.size).has_point(point):
			return true
	return false


func _device_hint(step: int, keyboard_hint: String, touch_override: Variant = null) -> String:
	var touch := OS.has_feature("mobile") if touch_override == null else bool(touch_override)
	if touch and not InputPrompts.gamepad_mode:
		# 触屏没有键盘：第 3 步不讲数字键，第 4 步不给“%s 键”变体（P10 试玩）。
		match step:
			2:
				return GameLocale.text("TUTORIAL_3_HINT_TOUCH")
			3:
				return GameLocale.text("TUTORIAL_SHAKE_HINT_TOUCH")
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


## 次级按钮：奶油底 + 可可描边（与暂停面板/升级面板的次级操作同款）。
func _style_secondary(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.96)
	normal.set_corner_radius_all(12)
	normal.set_border_width_all(2)
	normal.border_color = Color(COCOA.r, COCOA.g, COCOA.b, 0.34)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(COCOA.r, COCOA.g, COCOA.b, 0.10)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(COCOA.r, COCOA.g, COCOA.b, 0.20)
	var focus: StyleBoxFlat = normal.duplicate()
	focus.set_border_width_all(4)
	focus.border_color = MINT_DEEP
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, COCOA)


func _layout_overscan() -> void:
	var geometry := SafeFrame.overscan_geometry(self)
	_safe_offset = geometry["offset"]
	position = -_safe_offset
	size = geometry["size"]
	if visible and _card != null:
		var data: Dictionary = STEPS[_step]
		_focus.position = _safe_offset + data["focus"].position
		_card.position = _safe_offset + data["card"]
		_update_dim_geometry()


## B 键退出教学：与夜间五面板的 ui_cancel 行为对齐（P3-F9）。
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_finish()
		get_viewport().set_input_as_handled()


## 门控步骤：3（选茶基）与 4（摇杯封杯）。时钟冻结、顾客已就位——学过就要做一遍。
func _step_is_gated() -> bool:
	return _step == 2 or _step == 3


func _step_completed() -> bool:
	if _gate_bypassed or not _step_is_gated() or not progress_provider.is_valid():
		return true
	return bool(progress_provider.call(_step))


func _advance() -> void:
	if not _step_completed():
		# 防软锁：连续失败 2 次自动放行（本次即通过），并提示可从暂停菜单重看。
		_gate_fails += 1
		if _gate_fails < 2:
			_render_step()
			return
		_gate_bypassed = true
	_gate_fails = 0
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
