## 方案 3：空间站点式直接操作
## 店铺世界仍是主界面；固定订单队列、情境原料选择和“下一步”提示负责降低读单成本。
extends Control

const ShopStageScene := preload("res://ui/shop_stage.gd")
const AppTheme := preload("res://ui/app_theme.gd")
const TutorialOverlayScene := preload("res://ui/tutorial_overlay.gd")
const PausePanelScene := preload("res://ui/pause_panel.gd")
const SafeFrameScene := preload("res://ui/safe_frame.gd")
const ShakeGestureDetector := preload("res://input/shake_gesture.gd")
const PrepBatchModel := preload("res://systems/prep_batch.gd")
const HudDayIcon := preload("res://assets/icons/hud/day.png")
const HudCoinIcon := preload("res://assets/icons/hud/coin.png")
const HudInspirationIcon := preload("res://assets/icons/hud/inspiration.png")
const HudPerfectIcon := preload("res://assets/icons/hud/perfect.png")
const HudStreakIcon := preload("res://assets/icons/hud/streak.png")

const DAY_LENGTH := 120.0
const SHAKE_DECAY := 1.2
const SHAKE_GRACE_SECONDS := 0.5
## 三星线 = 目标的 1.4 倍（与 _end_day 判星共用，显示与判定不会漂移）。
const STAR_GOAL_MULT := 1.4
## 耐心秒数标签的色档（与条填充、小费档位共用阈值 0.7/0.4）。
const PATIENCE_BAND_COLORS := [Color("E5484D"), Color("D99A43"), Color("27B9A7")]

var time_left := DAY_LENGTH
var running := false
var customers: Array = []
var active_customer: Variant = null
var spawn_timer := 1.0

var earned := 0
var served := 0
var perfect := 0
var angry := 0
var streak := 0            # 当前连击：连续完美出杯，做错/气走顾客归零
var best_streak := 0
var goal := 0              # 今日营收目标（星级结算用）
var day_event: Dictionary = {}
var active_contract: Dictionary = {}
var spawned_count := 0
var event_bonus_earned := 0
var event_buzz_earned := 0
var route_bonus_earned := 0
var route_trigger_count := 0
var special_served := 0
var menu_sales_count := 0
var menu_sales_revenue := 0
var menu_sales_by_id: Dictionary = {}
var dark_sales_count := 0
var dark_buzz_earned := 0
var golden_batches_served := 0
var poor_batches_served := 0
var stock_cost := 0
var waste_cost := 0
var staff_state := "working"
var staff_event_timer := 0.0
var staff_reveal_timer := 0.0
var staff_events := 0
var staff_wakes := 0
var staff_rescues := 0
var staff_bonus_earned := 0
var staff_guard_used := false

var cup_base: Variant = null
var cup_milk: Variant = null
var cup_tops: Array = []
var cup_sugar: Variant = null
var sugar_index := 2           # 默认五分糖
var sugar_confirmed := false
var shake_progress := 0.0
var _shake_grace_left := 0.0
var cup_sealed := false
var cup_corrections := 0
var cup_tea_quality := 1
var cup_pearl_quality := -1
var _shake_gesture := ShakeGestureDetector.new()
var tea_batch = PrepBatchModel.new("tea", 8.0, 4.0, 6.0, 4)
var pearl_batch = PrepBatchModel.new("pearl", 10.0, 4.0, 6.0, 4)
var tea_stock: Dictionary = {} # tea id -> quality queue; each serving keeps its own timing result
var pearl_stock: Array = []

var stage                      # ShopStage（动态访问 cup 等成员，不加类型标注）
var hud_day: Label
var hud_coin: Label
var hud_cost: Label
var hud_insp: Label
var hud_perfect: Label
var hud_streak: Label
var hud_upgrade: Label
var hud_event: Label
var event_pill: PanelContainer
var hud_contract: Label
var contract_pill: PanelContainer
var hud_goal_bar: ProgressBar
var hud_goal_text: Label
var coin_pill: Control
var hud_primary: HBoxContainer
var hud_status: HBoxContainer
var status_label: Label
var shake_bar: ProgressBar
var feedback_label: Label
var overlay: ColorRect
var context_panel: PanelContainer
var context_title: Label
var context_choices: GridContainer
var next_action_panel: PanelContainer
var next_action_label: Label
var reset_button: Button
var prep_panel: PanelContainer
var tea_prep_title: Label
var tea_prep_state: Label
var tea_prep_progress: ProgressBar
var tea_prep_button: Button
var pearl_prep_title: Label
var pearl_prep_state: Label
var pearl_prep_progress: ProgressBar
var pearl_prep_button: Button
var pause_button: Button
var tutorial_overlay: TutorialOverlay
var pause_panel: PausePanel
var event_overlay: ColorRect
var event_name_label: Label
var event_headline_label: Label
var event_challenge_label: Label
var event_benefit_label: Label
var event_next_label: Label
var event_route_label: Label
var event_start_button: Button
var staff_card: PanelContainer
var staff_title: Label
var staff_trait_label: Label
var staff_status_label: Label
var staff_action_button: Button
var _resume_after_pause := false
var _context_shortcuts: Array[Button] = []
var ui_frame: SafeFrame
var _order_progress_styles: Dictionary = {}
var _card_panel_active: StyleBoxFlat
var _card_panel_idle: StyleBoxFlat
var _card_fill_healthy: StyleBoxFlat
var _card_fill_warn: StyleBoxFlat
var _card_fill_low: StyleBoxFlat
var _info_inputs: Array = []
var _flash_tween: Tween
var _streak_tween: Tween
var _prep_tea_title_inputs: Array = [-1]
var _prep_pearl_title_inputs: Array = [-1]
var _prep_tea_inputs: Array = []
var _prep_pearl_inputs: Array = []
var _prep_fill_styles: Dictionary = {}


func _prep_fill_style(state: String) -> StyleBoxFlat:
	# 进度条填充随批次状态换色：煮制青、黄金金、过晚琥珀、变质红——
	# 技巧窗口用颜色读，不必盯住 12px 状态文本。
	if _prep_fill_styles.has(state):
		return _prep_fill_styles[state]
	var style := StyleBoxFlat.new()
	match state:
		PrepBatchModel.STATE_GOLDEN:
			style.bg_color = Color("F5C351")
		PrepBatchModel.STATE_LATE:
			style.bg_color = Color("D99A43")
		PrepBatchModel.STATE_SPOILED:
			style.bg_color = Color("E5484D")
		_:
			style.bg_color = Color("8C67B5")
	_prep_fill_styles[state] = style
	return style
var _context_panel_target_visible := true
var _context_panel_tween: Tween


func _ready() -> void:
	GameState.phase = "day"
	Sfx.play_music("day")
	InputPrompts.scheme_changed.connect(_on_input_scheme_changed)
	InputPrompts.bindings_changed.connect(_on_bindings_changed)
	GameLocale.locale_changed.connect(_on_locale_changed)
	_build_ui()
	_start_day()
	if GameState.day == 1 and not GameState.tutorial_completed and not GameState.test_mode:
		call_deferred("_show_tutorial", false)
	elif day_event.get("id", "calm") != "calm" and not GameState.test_mode:
		call_deferred("_show_event_briefing")


func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	_update_staff(delta)
	_update_prep_batches(delta)
	# 摇茶衰减：每次有效摇动后有短暂宽限，衰减只在停顿后才生效。
	if not cup_sealed and shake_progress > 0.0:
		if _shake_grace_left > 0.0:
			_shake_grace_left = maxf(0.0, _shake_grace_left - delta)
		else:
			shake_progress = maxf(0.0, shake_progress - SHAKE_DECAY * delta)
		stage.cup.update_cup(cup_base, cup_milk, cup_tops, cup_sugar,
			shake_progress / float(_shakes_needed()), cup_sealed)
	shake_bar.value = shake_progress
	shake_bar.visible = not cup_sealed and cup_base != null
	shake_bar.position = _window_to_frame(stage.cup_screen_pos()) - Vector2(shake_bar.size.x / 2.0, 0)
	# 手机传感器连续采样，但检测器只在有效冲击与冷却窗口后发出一次语义摇动。
	if _can_gesture_shake() and _shake_gesture.sample_accelerometer(
		Input.get_accelerometer(), Time.get_ticks_msec()):
		_on_shake()
	# 顾客耐心：固定订单卡比随 3D 头像漂移更容易扫读，也便于移动端点击。
	# 排队宽容：只有队首满速掉耐心，后排顾客更能等，避免后期队列雪崩。
	var rear_drain_mult := StaffCatalog.waiting_drain_multiplier(staff_state == "working")
	var route_ready := LegacyRoutes.active_id() == "precision"
	var leavers: Array[Dictionary] = []
	for i in customers.size():
		var c: Dictionary = customers[i]
		c["patience"] -= delta * (1.0 if i == 0 else 0.5) * (1.0 if i == 0 else rear_drain_mult)
		var ratio: float = c["patience"] / c["max_patience"]
		c["patience_bar"].value = ratio * 100.0
		var band := 2 if ratio > 0.70 else (1 if ratio > 0.40 else 0)
		var prev_band := int(c.get("patience_band", 2))
		if band != prev_band:
			c["patience_band"] = band
			# 注意：这是“转换门控”而非时间冷却——耐心单调递减时两者等价；
			# 若未来引入耐心回复机制，需改为时间冷却防止提示音连发。
			if band < prev_band and i == 0:
				# 队首掉档给一次听觉预警：琥珀档轻响、红档提醒——离场不再是突然袭击。
				if band == 1:
					Sfx.play("select", 0.72)
				else:
					Sfx.play("customer_leave", 1.4)
					Haptics.play("warning")
		# 秒数文本只在整数秒、就绪状态或色档切换时重建，避免逐帧本地化格式化。
		var seconds_left := ceili(c["patience"])
		var ready_flag := route_ready and ratio > 0.70
		if seconds_left != int(c.get("label_second", -1)) or ready_flag != bool(c.get("label_route", false)) \
				or band != prev_band:
			c["label_second"] = seconds_left
			c["label_route"] = ready_flag
			c["patience_label"].text = GameLocale.text("DAY_SECONDS_ROUTE_READY", [seconds_left]) \
				if ready_flag else GameLocale.text("DAY_SECONDS_SHORT", [seconds_left])
			c["patience_label"].add_theme_color_override("font_color", PATIENCE_BAND_COLORS[band])
		_style_order_card(c, c == active_customer)
		if c["patience"] <= 0.0:
			leavers.append(c)
	for c in leavers:
		_customer_leave(c, GameLocale.text("DAY_CUSTOMER_LEFT"))
	# 生成顾客
	spawn_timer -= delta
	if spawn_timer <= 0.0 and customers.size() < _max_customers():
		_spawn_customer()
		spawn_timer = _spawn_interval()
	_update_info()
	if time_left <= 0.0:
		_end_day()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("game_pause") and not tutorial_overlay.visible and not event_overlay.visible:
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if not running:
		return
	if event.is_action_pressed("prep_tea"):
		_on_tea_batch_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("prep_pearl"):
		_on_pearl_batch_pressed()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _can_gesture_shake():
		var mouse_motion := event as InputEventMouseMotion
		if _shake_gesture.sample_mouse(mouse_motion.relative, mouse_motion.velocity,
			Time.get_ticks_msec()):
			_on_shake()
			return
	if event.is_action_pressed("game_shake"):
		_on_shake()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("staff_interact") and StaffCatalog.has_staff():
		_on_staff_clicked()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed:
		return
	var shortcut := int(event.keycode) - int(KEY_1)
	if shortcut < 0 or shortcut > 8:
		return
	if cup_sealed and shortcut < 3:
		for customer in customers:
			if int(customer["slot"]) == shortcut:
				_on_order_card_pressed(customer)
				get_viewport().set_input_as_handled()
				return
	elif shortcut < _context_shortcuts.size():
		var target := _context_shortcuts[shortcut]
		if target is Button and not target.disabled:
			target.pressed.emit()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	theme = AppTheme.build()
	stage = ShopStageScene.new()
	add_child(stage)
	stage.ingredient_clicked.connect(_on_ingredient)
	stage.cup_clicked.connect(_on_shake)
	stage.staff_clicked.connect(_on_staff_clicked)
	ui_frame = SafeFrameScene.new()
	add_child(ui_frame)

	# 药丸 HUD
	hud_primary = HBoxContainer.new()
	hud_primary.position = Vector2(14, 10)
	hud_primary.size = Vector2(850, 54)
	hud_primary.custom_minimum_size = Vector2(850, 54)
	hud_primary.add_theme_constant_override("separation", 10)
	ui_frame.add_child(hud_primary)
	hud_day = _day_goal_pill(hud_primary)
	hud_coin = _cash_pill(hud_primary)
	hud_insp = _pill(hud_primary, HudInspirationIcon)
	hud_perfect = _pill(hud_primary, HudPerfectIcon)
	hud_streak = _pill(hud_primary, HudStreakIcon)
	var upgrade_pill := PanelContainer.new()
	hud_primary.add_child(upgrade_pill)
	hud_upgrade = Label.new()
	hud_upgrade.add_theme_font_size_override("font_size", 17)
	upgrade_pill.add_child(hud_upgrade)
	# Event/contract copy has a separate compact row above the order queue. Keeping
	# it out of the primary metric HBox prevents late-game two-line route copy from
	# squeezing every core value down to an icon on 1280x720/mobile layouts.
	hud_status = HBoxContainer.new()
	hud_status.position = Vector2(14, 70)
	hud_status.custom_minimum_size = Vector2(414, 40)
	hud_status.add_theme_constant_override("separation", 8)
	ui_frame.add_child(hud_status)
	event_pill = PanelContainer.new()
	event_pill.custom_minimum_size = Vector2(246, 40)
	event_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_status.add_child(event_pill)
	hud_event = Label.new()
	hud_event.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_event.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_event.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_event.max_lines_visible = 2
	hud_event.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hud_event.add_theme_font_size_override("font_size", 14)
	event_pill.add_child(hud_event)
	contract_pill = PanelContainer.new()
	contract_pill.custom_minimum_size = Vector2(160, 40)
	hud_status.add_child(contract_pill)
	hud_contract = Label.new()
	hud_contract.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_contract.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_contract.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_contract.max_lines_visible = 2
	hud_contract.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hud_contract.add_theme_font_size_override("font_size", 12)
	contract_pill.add_child(hud_contract)
	contract_pill.visible = false
	pause_button = Button.new()
	pause_button.text = "暂停"
	pause_button.position = Vector2(1170, 10)
	pause_button.custom_minimum_size = Vector2(96, 52)
	_style_utility_button(pause_button, AppTheme.CORAL)
	pause_button.pressed.connect(_toggle_pause)
	ui_frame.add_child(pause_button)

	# 当前杯状态：贴着制杯区底边，避免盖住可点击的 3D 原料。
	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(388, 612)
	status_panel.custom_minimum_size = Vector2(505, 46)
	ui_frame.add_child(status_panel)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 17)
	status_panel.add_child(status_label)

	# 情境原料选择：只显示当前步骤，世界道具和大触控按钮都可以操作。
	context_panel = PanelContainer.new()
	context_panel.position = Vector2(438, 72)
	context_panel.custom_minimum_size = Vector2(800, 118)
	ui_frame.add_child(context_panel)
	var context_box := VBoxContainer.new()
	context_box.add_theme_constant_override("separation", 6)
	context_panel.add_child(context_box)
	context_title = Label.new()
	context_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_title.add_theme_font_size_override("font_size", 18)
	context_box.add_child(context_title)
	context_choices = GridContainer.new()
	context_choices.columns = 4
	context_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_choices.add_theme_constant_override("separation", 8)
	context_box.add_child(context_choices)
	_build_prep_panel()

	# 底部唯一主提示 + 可恢复的重置操作。
	next_action_panel = PanelContainer.new()
	next_action_panel.position = Vector2(462, 664)
	next_action_panel.custom_minimum_size = Vector2(356, 48)
	ui_frame.add_child(next_action_panel)
	next_action_label = Label.new()
	next_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_action_label.add_theme_font_size_override("font_size", 20)
	next_action_panel.add_child(next_action_label)
	reset_button = Button.new()
	reset_button.position = Vector2(28, 650)
	reset_button.custom_minimum_size = Vector2(196, 54)
	reset_button.text = GameLocale.text("DAY_RESET_CUP")
	_style_utility_button(reset_button, Color("C83E49"), true)
	reset_button.pressed.connect(_on_reset_cup_pressed)
	ui_frame.add_child(reset_button)

	# 摇茶进度（跟随杯子）
	shake_bar = ProgressBar.new()
	shake_bar.max_value = _shakes_needed()
	shake_bar.show_percentage = false
	shake_bar.size = Vector2(120, 14)
	shake_bar.visible = false
	ui_frame.add_child(shake_bar)

	feedback_label = Label.new()
	feedback_label.position = Vector2(438, 290)
	# 奖励明细最多拼 9 段；限定宽度+两行换行，避免从 438px 起跑的长句被视口截断。
	feedback_label.custom_minimum_size = Vector2(760, 0)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.max_lines_visible = 2
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 26)
	feedback_label.modulate.a = 0.0
	ui_frame.add_child(feedback_label)
	_build_staff_card()

	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)

	tutorial_overlay = TutorialOverlayScene.new()
	tutorial_overlay.finished.connect(_on_tutorial_finished)
	ui_frame.add_child(tutorial_overlay)
	pause_panel = PausePanelScene.new()
	pause_panel.resume_requested.connect(_resume_from_pause)
	pause_panel.tutorial_requested.connect(_replay_tutorial)
	pause_panel.menu_requested.connect(_return_to_menu)
	ui_frame.add_child(pause_panel)
	_build_event_overlay()


func _build_prep_panel() -> void:
	prep_panel = PanelContainer.new()
	prep_panel.position = Vector2(438, 198)
	prep_panel.custom_minimum_size = Vector2(800, 84)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.095, 0.075, 0.072, 0.92)
	panel_style.set_corner_radius_all(13)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color("D99A43")
	panel_style.content_margin_left = 9
	panel_style.content_margin_right = 9
	panel_style.content_margin_top = 7
	panel_style.content_margin_bottom = 7
	prep_panel.add_theme_stylebox_override("panel", panel_style)
	ui_frame.add_child(prep_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	prep_panel.add_child(row)
	var tea_controls := _prep_station(row, true)
	tea_prep_title = tea_controls["title"]
	tea_prep_state = tea_controls["state"]
	tea_prep_progress = tea_controls["progress"]
	tea_prep_button = tea_controls["button"]
	tea_prep_button.pressed.connect(_on_tea_batch_pressed)
	var pearl_controls := _prep_station(row, false)
	pearl_prep_title = pearl_controls["title"]
	pearl_prep_state = pearl_controls["state"]
	pearl_prep_progress = pearl_controls["progress"]
	pearl_prep_button = pearl_controls["button"]
	pearl_prep_button.pressed.connect(_on_pearl_batch_pressed)


func _prep_station(parent: HBoxContainer, tea_station: bool) -> Dictionary:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(385, 68)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.975, 0.91, 0.98)
	style.set_corner_radius_all(9)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	card.add_child(stack)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	stack.add_child(header)
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 14)
	header.add_child(title)
	var state := Label.new()
	state.add_theme_font_size_override("font_size", 12)
	state.add_theme_color_override("font_color", Color("8C67B5"))
	header.add_child(state)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	stack.add_child(action_row)
	var progress := ProgressBar.new()
	progress.max_value = 100.0
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(132, 10)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(progress)
	var button := Button.new()
	button.custom_minimum_size = Vector2(172, 34)
	button.add_theme_font_size_override("font_size", 13)
	button.accessibility_name = GameLocale.text("DAY_PREP_START_TEA" if tea_station else "DAY_PREP_START_PEARL")
	action_row.add_child(button)
	return {"title": title, "state": state, "progress": progress, "button": button}


func _build_staff_card() -> void:
	staff_card = PanelContainer.new()
	# 右下安全区不遮挡顶部情境原料按钮，也避开中央杯状态与主操作按钮。
	staff_card.position = Vector2(984, 500)
	staff_card.custom_minimum_size = Vector2(272, 146)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.975, 0.92, 0.96)
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.border_color = Color("27B9A7")
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	staff_card.add_theme_stylebox_override("panel", style)
	ui_frame.add_child(staff_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	staff_card.add_child(box)
	staff_title = Label.new()
	staff_title.add_theme_font_size_override("font_size", 19)
	box.add_child(staff_title)
	staff_trait_label = Label.new()
	staff_trait_label.add_theme_font_size_override("font_size", 14)
	staff_trait_label.add_theme_color_override("font_color", Color("FF6259"))
	box.add_child(staff_trait_label)
	staff_status_label = Label.new()
	staff_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	staff_status_label.custom_minimum_size = Vector2(232, 34)
	staff_status_label.add_theme_font_size_override("font_size", 13)
	box.add_child(staff_status_label)
	staff_action_button = Button.new()
	staff_action_button.custom_minimum_size = Vector2(0, 36)
	staff_action_button.pressed.connect(_on_staff_clicked)
	box.add_child(staff_action_button)
	staff_card.visible = false


func _build_event_overlay() -> void:
	event_overlay = ColorRect.new()
	event_overlay.color = Color(0.05, 0.04, 0.05, 0.78)
	event_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	event_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	event_overlay.visible = false
	add_child(event_overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(680, 430)
	event_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var eyebrow := Label.new()
	eyebrow.text = "今日经营事件"
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", Color("27B9A7"))
	box.add_child(eyebrow)
	event_name_label = Label.new()
	event_name_label.add_theme_font_size_override("font_size", 34)
	box.add_child(event_name_label)
	event_headline_label = Label.new()
	event_headline_label.custom_minimum_size = Vector2(640, 48)
	event_headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_headline_label.add_theme_font_size_override("font_size", 18)
	box.add_child(event_headline_label)
	var effects := HBoxContainer.new()
	effects.add_theme_constant_override("separation", 12)
	box.add_child(effects)
	event_challenge_label = _event_effect_card(effects, "今天的挑战", Color("FF6259"))
	event_benefit_label = _event_effect_card(effects, "今天的机会", Color("27B9A7"))
	event_route_label = Label.new()
	event_route_label.custom_minimum_size = Vector2(640, 34)
	event_route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_route_label.add_theme_font_size_override("font_size", 15)
	event_route_label.add_theme_color_override("font_color", Color("8C67B5"))
	box.add_child(event_route_label)
	event_next_label = Label.new()
	event_next_label.add_theme_font_size_override("font_size", 15)
	event_next_label.modulate = Color(0.19, 0.13, 0.11, 0.62)
	box.add_child(event_next_label)
	event_start_button = Button.new()
	event_start_button.text = "知道了 · 开门营业"
	event_start_button.custom_minimum_size = Vector2(0, 58)
	event_start_button.pressed.connect(_dismiss_event_briefing)
	box.add_child(event_start_button)


func _event_effect_card(parent: HBoxContainer, title_text: String, accent: Color) -> Label:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(314, 104)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
	style.set_corner_radius_all(12)
	style.set_border_width_all(2)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.54)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 5)
	card.add_child(copy)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", accent)
	copy.add_child(title)
	var body := Label.new()
	body.custom_minimum_size = Vector2(282, 48)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	copy.add_child(body)
	return body


func _show_event_briefing() -> void:
	if day_event.is_empty() or day_event.get("id", "calm") == "calm":
		return
	running = false
	event_name_label.text = String(day_event["name"])
	event_name_label.add_theme_color_override("font_color", Color(String(day_event["color"])))
	event_headline_label.text = String(day_event["headline"])
	event_challenge_label.text = String(day_event["challenge"])
	event_benefit_label.text = String(day_event["benefit"])
	event_route_label.visible = LegacyRoutes.is_active()
	if event_route_label.visible:
		event_route_label.text = GameLocale.text("DAY_ROUTE_ACTIVE", [
			String(LegacyRoutes.route().get("name", "")), String(LegacyRoutes.route().get("summary", ""))])
	if active_contract.is_empty():
		var tomorrow := DailyEvents.next_event(GameState.day)
		event_next_label.text = GameLocale.text("DAY_TOMORROW_EVENT", [String(tomorrow["name"])])
	else:
		event_next_label.text = GameLocale.text("DAY_ACTIVE_CONTRACT", [
			String(active_contract.get("name", GameLocale.text("DAY_CONTRACT_FALLBACK"))),
			String(active_contract.get("target_text", GameLocale.text("CONTRACT_TARGET_DEFAULT")))])
	event_overlay.visible = true
	event_start_button.grab_focus()


func _dismiss_event_briefing() -> void:
	event_overlay.visible = false
	running = time_left > 0.0
	pause_button.grab_focus()


func _show_tutorial(replay := false) -> void:
	if tutorial_overlay.visible:
		return
	if customers.is_empty():
		_spawn_customer()
	_resume_after_pause = running
	running = false
	tutorial_overlay.start(replay)


func _on_tutorial_finished() -> void:
	if time_left > 0.0 and not overlay.visible:
		running = true


func _toggle_pause() -> void:
	if tutorial_overlay.visible or event_overlay.visible or overlay.visible:
		return
	if pause_panel.visible:
		_resume_from_pause()
		return
	_resume_after_pause = running
	running = false
	pause_panel.show_panel(true)
	get_tree().paused = true


func _resume_from_pause() -> void:
	get_tree().paused = false
	pause_panel.hide_panel()
	running = _resume_after_pause and time_left > 0.0 and not overlay.visible
	pause_button.grab_focus()


func _replay_tutorial() -> void:
	get_tree().paused = false
	pause_panel.hide_panel()
	_show_tutorial(true)


func _return_to_menu() -> void:
	get_tree().paused = false
	if GameState.has_save():
		GameState.load_save()
	else:
		GameState.reset_progress()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _pill(hud: HBoxContainer, icon_texture: Texture2D) -> Label:
	var p := PanelContainer.new()
	hud.add_child(p)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	p.add_child(row)
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 19)
	row.add_child(l)
	return l


func _cash_pill(hud: HBoxContainer) -> Label:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(152, 0)
	hud.add_child(p)
	coin_pill = p
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	p.add_child(row)
	var icon := TextureRect.new()
	icon.texture = HudCoinIcon
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stack)
	var value := Label.new()
	value.add_theme_font_size_override("font_size", 19)
	stack.add_child(value)
	hud_cost = Label.new()
	hud_cost.add_theme_font_size_override("font_size", 10)
	hud_cost.add_theme_color_override("font_color", Color(0.30, 0.22, 0.18, 0.68))
	hud_cost.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(hud_cost)
	return value


func _day_goal_pill(hud: HBoxContainer) -> Label:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(250, 0)
	hud.add_child(p)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 1)
	p.add_child(stack)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	stack.add_child(row)
	var icon := TextureRect.new()
	icon.texture = HudDayIcon
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 19)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	hud_goal_text = Label.new()
	hud_goal_text.add_theme_font_size_override("font_size", 15)
	hud_goal_text.modulate = Color(0.30, 0.22, 0.18, 0.72)
	row.add_child(hud_goal_text)
	hud_goal_bar = ProgressBar.new()
	# 条宽到 140%：三星线就是条的尽头，目标线留一个刻度——打烊前仍有冲刺牵引。
	hud_goal_bar.max_value = STAR_GOAL_MULT * 100.0
	hud_goal_bar.show_percentage = false
	hud_goal_bar.custom_minimum_size = Vector2(0, 7)
	var goal_tick := ColorRect.new()
	goal_tick.color = Color(0.19, 0.13, 0.11, 0.45)
	goal_tick.anchor_left = 1.0 / STAR_GOAL_MULT
	goal_tick.anchor_right = 1.0 / STAR_GOAL_MULT
	goal_tick.anchor_top = 0.0
	goal_tick.anchor_bottom = 1.0
	goal_tick.offset_left = -1.0
	goal_tick.offset_right = 1.0
	goal_tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_goal_bar.add_child(goal_tick)
	stack.add_child(hud_goal_bar)
	return label


# ---------------------------------------------------------------- 直接操纵

func _init_prep_inventory() -> void:
	tea_batch = PrepBatchModel.new("tea", 8.0, 4.0, 6.0, 4)
	pearl_batch = PrepBatchModel.new("pearl", 10.0, 4.0, 6.0, 4)
	tea_stock = {}
	for base in GameData.unlocked(GameData.bases, GameState.day):
		tea_stock[String(base["id"])] = [1, 1, 1]
	pearl_stock = [1, 1, 1]
	_refresh_prep_ui()


func _update_prep_batches(delta: float) -> void:
	var prev_tea_state: String = tea_batch.state()
	var prev_pearl_state: String = pearl_batch.state()
	tea_batch.advance(delta)
	pearl_batch.advance(delta)
	# 黄金窗开启与变质是需要立刻注意的转换：一声轻响/一声提醒，不再只靠 12px 文本。
	_play_prep_transition_cue(tea_batch.state(), prev_tea_state)
	_play_prep_transition_cue(pearl_batch.state(), prev_pearl_state)
	_refresh_prep_ui()


func _play_prep_transition_cue(state: String, prev: String) -> void:
	if state == prev:
		return
	if state == PrepBatchModel.STATE_GOLDEN:
		Sfx.play("coin", 1.3)
		Haptics.play("confirm")
	elif state == PrepBatchModel.STATE_SPOILED:
		Sfx.play("bad", 0.9)
		Haptics.play("warning")


func _active_tea_id() -> String:
	if tea_batch.active:
		return String(tea_batch.item_id)
	if active_customer != null and customers.has(active_customer):
		return String(active_customer["order"]["base"]["id"])
	var bases := GameData.unlocked(GameData.bases, GameState.day)
	return String(bases[0]["id"]) if not bases.is_empty() else ""


func _tea_stock_count(base_id: String) -> int:
	var portions: Variant = tea_stock.get(base_id, [])
	return portions.size() if portions is Array else 0


func _refresh_prep_ui() -> void:
	if tea_prep_button == null:
		return
	var tea_id := _active_tea_id()
	var tea_title_inputs := [tea_id, _tea_stock_count(tea_id)]
	if tea_title_inputs != _prep_tea_title_inputs:
		_prep_tea_title_inputs = tea_title_inputs
		var tea_item := RecipeJournal.ingredient(tea_id)
		var tea_name := GameLocale.ingredient_short_name(tea_item) if not tea_item.is_empty() else "—"
		tea_prep_title.text = GameLocale.text("DAY_PREP_TEA_TITLE", [tea_name, tea_title_inputs[1]])
	_configure_prep_controls(tea_batch, tea_prep_state, tea_prep_progress, tea_prep_button, true, tea_id)
	var pearl_title_inputs := [pearl_stock.size()]
	if pearl_title_inputs != _prep_pearl_title_inputs:
		_prep_pearl_title_inputs = pearl_title_inputs
		pearl_prep_title.text = GameLocale.text("DAY_PREP_PEARL_TITLE", [pearl_title_inputs[0]])
	_configure_prep_controls(pearl_batch, pearl_prep_state, pearl_prep_progress, pearl_prep_button, false, "")


func _configure_prep_controls(batch, state_label: Label, progress: ProgressBar,
		button: Button, tea_station: bool, active_tea_id: String) -> void:
	progress.value = batch.progress() * 100.0
	# 进度条逐帧更新；状态文本/主题只在状态、剩余秒数或按键提示变化时重建。
	var shortcut := InputPrompts.prep_tea_hint() if tea_station else InputPrompts.prep_pearl_hint()
	var seconds := 0
	var state: String = batch.state()
	match state:
		PrepBatchModel.STATE_BREWING:
			seconds = batch.seconds_to_ready()
		PrepBatchModel.STATE_GOLDEN, PrepBatchModel.STATE_LATE:
			seconds = batch.window_seconds_left()
	var stock_blocked := tea_station and active_tea_id.is_empty()
	var inputs := [state, seconds, shortcut, stock_blocked]
	if tea_station:
		if inputs == _prep_tea_inputs:
			return
		_prep_tea_inputs = inputs
	else:
		if inputs == _prep_pearl_inputs:
			return
		_prep_pearl_inputs = inputs
	button.disabled = false
	progress.add_theme_stylebox_override("fill", _prep_fill_style(state))
	match state:
		PrepBatchModel.STATE_EMPTY:
			state_label.text = GameLocale.text("DAY_PREP_EMPTY")
			button.text = GameLocale.text("DAY_PREP_START_TEA" if tea_station else "DAY_PREP_START_PEARL")
			button.disabled = stock_blocked
		PrepBatchModel.STATE_BREWING:
			state_label.text = GameLocale.text("DAY_PREP_BREWING", [seconds])
			button.text = GameLocale.text("DAY_PREP_WAIT")
			button.disabled = true
		PrepBatchModel.STATE_GOLDEN:
			state_label.text = GameLocale.text("DAY_PREP_GOLDEN", [seconds])
			button.text = GameLocale.text("DAY_PREP_COLLECT_GOLDEN")
		PrepBatchModel.STATE_LATE:
			state_label.text = GameLocale.text("DAY_PREP_LATE", [seconds])
			button.text = GameLocale.text("DAY_PREP_COLLECT_LATE")
		_:
			state_label.text = GameLocale.text("DAY_PREP_SPOILED")
			button.text = GameLocale.text("DAY_PREP_COLLECT_SPOILED")
	button.text = "%s · %s" % [shortcut, button.text]
	button.accessibility_name = button.text
	button.tooltip_text = "%s · %s" % [state_label.text, button.text]
	var state_color := Color("8C67B5")
	if state == PrepBatchModel.STATE_GOLDEN:
		state_color = Color("27B9A7")
	elif state == PrepBatchModel.STATE_LATE:
		state_color = Color("D99A43")
	elif state == PrepBatchModel.STATE_SPOILED:
		state_color = Color("E5484D")
	state_label.add_theme_color_override("font_color", state_color)


func _on_tea_batch_pressed() -> void:
	if not running:
		return
	if not tea_batch.active:
		var tea_id := _active_tea_id()
		if tea_id.is_empty():
			return
		tea_batch.start(tea_id)
		var tea := RecipeJournal.ingredient(tea_id)
		_flash(GameLocale.text("DAY_PREP_TEA_STARTED", [GameLocale.ingredient_name(tea)]), Color("D99A43"))
		Sfx.play("pour_tea", 0.86)
		Haptics.play("tap")
	else:
		var result: Dictionary = tea_batch.collect()
		if result.is_empty():
			return
		var portions: Array = tea_stock.get(String(result["item_id"]), [])
		for _serving in int(result["servings"]):
			portions.append(int(result["quality"]))
		tea_stock[String(result["item_id"])] = portions
		_on_batch_collected(result)
	_refresh_prep_ui()


func _on_pearl_batch_pressed() -> void:
	if not running:
		return
	if not pearl_batch.active:
		pearl_batch.start("boba")
		_flash(GameLocale.text("DAY_PREP_PEARL_STARTED"), Color("8C67B5"))
		Sfx.play("topping", 0.82)
		Haptics.play("tap")
	else:
		var result: Dictionary = pearl_batch.collect()
		if result.is_empty():
			return
		for _serving in int(result["servings"]):
			pearl_stock.append(int(result["quality"]))
		_on_batch_collected(result)
	_refresh_prep_ui()


func _on_batch_collected(result: Dictionary) -> void:
	var key := "DAY_PREP_COLLECTED_GOLDEN" if int(result["quality"]) == 2 else (
		"DAY_PREP_COLLECTED_LATE" if int(result["quality"]) == 1 else "DAY_PREP_COLLECTED_SPOILED")
	var color := Color("27B9A7") if int(result["quality"]) == 2 else (
		Color("D99A43") if int(result["quality"]) == 1 else Color("E5484D"))
	_flash(GameLocale.text(key, [int(result["servings"])]), color)
	Sfx.play("coin", 0.82 if int(result["quality"]) == 2 else 0.68)
	Haptics.play("confirm" if int(result["quality"]) == 2 else "tap")


func _consume_tea_portion(base_id: String) -> int:
	var portions: Array = tea_stock.get(base_id, [])
	if portions.is_empty():
		return -1
	var quality := int(portions.pop_front())
	tea_stock[base_id] = portions
	_refresh_prep_ui()
	return quality


func _consume_pearl_portion() -> int:
	if pearl_stock.is_empty():
		return -1
	var quality := int(pearl_stock.pop_front())
	_refresh_prep_ui()
	return quality


func _cup_batch_quality() -> int:
	var quality := cup_tea_quality
	for topping in cup_tops:
		if String(topping.get("id", "")) == "boba":
			quality = mini(quality, cup_pearl_quality if cup_pearl_quality >= 0 else 1)
	return quality


func _batch_quality_text() -> String:
	if cup_base == null:
		return ""
	match _cup_batch_quality():
		2:
			return GameLocale.text("DAY_BATCH_GOLDEN")
		0:
			return GameLocale.text("DAY_BATCH_POOR")
	return GameLocale.text("DAY_BATCH_STANDARD")

func _on_ingredient(kind: String, item: Dictionary) -> void:
	if not running or cup_sealed:
		return
	match kind:
		"base":
			_on_base(item)
		"milk":
			_on_milk(item)
		"topping":
			_on_topping(item)
		"sugar":
			# 糖泵直选档位（item 即糖度条目）
			for i in GameData.sugar_levels.size():
				if int(GameData.sugar_levels[i]["value"]) == int(item.get("value", -1)):
					sugar_index = i
			_on_sugar(GameData.sugar_levels[sugar_index])
			stage.set_sugar_label(cup_sugar)


func _on_base(item: Dictionary) -> void:
	if cup_sealed:
		return
	var base_id := String(item["id"])
	var changes_base := cup_base == null or String(cup_base["id"]) != base_id
	if changes_base:
		var batch_quality := _consume_tea_portion(base_id)
		if batch_quality < 0:
			_flash(GameLocale.text("DAY_PREP_TEA_EMPTY", [GameLocale.ingredient_name(item)]), Color("E5484D"))
			Haptics.play("warning")
			return
		cup_tea_quality = batch_quality
	if cup_base != null and String(cup_base["id"]) != base_id:
		_mark_cup_correction()
	cup_base = item
	if cup_sugar == null:
		cup_sugar = GameData.sugar_levels[sugar_index]
	Sfx.play("pour_tea")
	Haptics.play("tap")
	_refresh_cup()


func _on_milk(item: Dictionary) -> void:
	if cup_sealed:
		return
	if cup_milk != null and String(cup_milk["id"]) != String(item["id"]):
		_mark_cup_correction()
	cup_milk = item
	Sfx.play("pour_milk")
	Haptics.play("tap")
	if UpgradeCatalog.has_smart_sugar() and not sugar_confirmed \
			and active_customer != null and customers.has(active_customer):
		_on_sugar(active_customer["order"]["sugar"])
		_flash(GameLocale.text("DAY_SMART_SUGAR_MATCHED", [GameLocale.ingredient_name(active_customer["order"]["sugar"])]), Color("27B9A7"))
		return
	_refresh_cup()


func _on_topping(item: Dictionary) -> void:
	if cup_sealed:
		return
	for t in cup_tops:
		if t["id"] == item["id"]:
			_mark_cup_correction()
			cup_tops.erase(t)
			if String(item["id"]) == "boba":
				cup_pearl_quality = -1
			stage.set_prop_selected(item["id"], false)
			Sfx.play("topping", 0.88)
			Haptics.play("tap")
			_refresh_cup()
			return
	if cup_tops.size() < 2:
		if String(item["id"]) == "boba":
			var batch_quality := _consume_pearl_portion()
			if batch_quality < 0:
				_flash(GameLocale.text("DAY_PREP_PEARL_EMPTY"), Color("E5484D"))
				Haptics.play("warning")
				return
			cup_pearl_quality = batch_quality
		cup_tops.append(item)
		stage.set_prop_selected(item["id"], true)
		Sfx.play("topping")
		Haptics.play("tap")
	_refresh_cup()


func _on_sugar(item: Dictionary) -> void:
	if cup_sealed:
		return
	if sugar_confirmed and cup_sugar != null and int(cup_sugar["value"]) != int(item["value"]):
		_mark_cup_correction()
	cup_sugar = item
	sugar_confirmed = true
	for i in GameData.sugar_levels.size():
		if int(GameData.sugar_levels[i]["value"]) == int(item["value"]):
			sugar_index = i
			break
	stage.set_sugar_label(cup_sugar)
	Sfx.play("sugar")
	Haptics.play("tap")
	_refresh_cup()


func _on_shake() -> void:
	if cup_sealed or not running:
		return
	if cup_base == null or cup_milk == null or cup_sugar == null or not sugar_confirmed:
		_flash(GameLocale.text("DAY_FEEDBACK_INCOMPLETE"), Color.ORANGE)
		Haptics.play("warning")
		return
	shake_progress += 1.0
	# 衰减宽限：刚摇过的半秒内不衰减，避免连点时“按了计数却没涨”的漏桶手感。
	_shake_grace_left = SHAKE_GRACE_SECONDS
	stage.cup.play_shake()
	Sfx.play("shake", randf_range(0.9, 1.15))
	Haptics.play("shake")
	if shake_progress >= _shakes_needed():
		cup_sealed = true
		stage.cup.play_serve()
		Sfx.play("seal")
		Haptics.play("confirm")
		_flash(GameLocale.text("DAY_FEEDBACK_SEALED"), Color.GREEN_YELLOW)
	_refresh_cup()


func _can_gesture_shake() -> bool:
	return running and not cup_sealed and cup_base != null and cup_milk != null \
		and cup_sugar != null and sugar_confirmed


func _mark_cup_correction() -> void:
	cup_corrections += 1
	_flash(GameLocale.text("DAY_FEEDBACK_REWORK", [cup_corrections]), Color("E88B32"))


func _current_cup_ingredients() -> Array:
	var ingredients: Array = []
	if cup_base != null:
		ingredients.append(cup_base)
	if cup_milk != null:
		ingredients.append(cup_milk)
	ingredients.append_array(cup_tops)
	return ingredients


func _current_cup_cost() -> int:
	return OperatingCosts.cup_cost(_current_cup_ingredients())


func _cup_has_contents() -> bool:
	return cup_base != null or cup_milk != null or not cup_tops.is_empty() \
		or sugar_confirmed or shake_progress > 0.0 or cup_sealed


func _on_reset_cup_pressed() -> void:
	if not running:
		return
	if not _cup_has_contents():
		return
	var discarded_cost := _current_cup_cost()
	if discarded_cost > 0:
		stock_cost += discarded_cost
		waste_cost += discarded_cost
		_flash(GameLocale.text("DAY_FEEDBACK_DISCARDED", [discarded_cost]), Color("E88B32"))
		Sfx.play("bad", 0.82)
		Haptics.play("warning")
	_reset_cup()


func _reset_cup() -> void:
	_shake_gesture.reset()
	_shake_grace_left = 0.0
	cup_base = null
	cup_milk = null
	for t in cup_tops:
		stage.set_prop_selected(t["id"], false)
	cup_tops = []
	cup_sugar = GameData.sugar_levels[sugar_index]
	sugar_confirmed = false
	shake_progress = 0.0
	cup_sealed = false
	cup_corrections = 0
	cup_tea_quality = 1
	cup_pearl_quality = -1
	_refresh_cup()


func _refresh_cup() -> void:
	stage.cup.update_cup(cup_base, cup_milk, cup_tops, cup_sugar,
		shake_progress / float(_shakes_needed()), cup_sealed)
	var parts: Array = []
	parts.append(GameLocale.ingredient_name(cup_base) if cup_base else GameLocale.text("DAY_MISSING_BASE"))
	parts.append(GameLocale.ingredient_name(cup_milk) if cup_milk else GameLocale.text("DAY_MISSING_MILK"))
	for t in cup_tops:
		parts.append(GameLocale.ingredient_name(t))
	var sugar_name: String = GameLocale.ingredient_name(cup_sugar) if cup_sugar else "?"
	var state := GameLocale.text("DAY_CUP_SEALED") if cup_sealed else ""
	if cup_corrections > 0:
		state += GameLocale.text("DAY_CUP_REWORKED", [cup_corrections])
	elif cup_sealed:
		state += GameLocale.text("DAY_CUP_CLEAN")
	status_label.text = GameLocale.text("DAY_CUP_STATUS", [" + ".join(parts), sugar_name, state + _batch_quality_text()])
	var discarded_cost := _current_cup_cost()
	reset_button.disabled = not _cup_has_contents()
	reset_button.text = GameLocale.text("DAY_RESET_CUP_WASTE", [discarded_cost]) \
		if discarded_cost > 0 else GameLocale.text("DAY_RESET_CUP")
	_refresh_context_controls()
	_update_all_order_progress()
	_refresh_all_order_action_hints()


func _refresh_context_controls() -> void:
	if context_choices == null:
		return
	_context_shortcuts.clear()
	for child in context_choices.get_children():
		child.queue_free()

	if cup_sealed:
		stage.set_active_prop_kind("")
		context_title.text = GameLocale.text("DAY_CONTEXT_SEALED")
		next_action_label.text = GameLocale.text("DAY_NEXT_DELIVER_GAMEPAD", [InputPrompts.accept_hint()]) \
			if InputPrompts.gamepad_mode else GameLocale.text("DAY_NEXT_DELIVER_TOUCH")
		_set_context_panel_visible(false)
		if active_customer != null and customers.has(active_customer):
			if InputPrompts.gamepad_mode:
				# Resolve the target when the deferred call runs. Capturing a concrete
				# button here lets stale requests from rapid order review bounce focus
				# between cards until Godot's message queue is exhausted.
				call_deferred("_focus_active_order")
			elif active_customer["btn"].has_focus():
				active_customer["btn"].release_focus()
		return
	_set_context_panel_visible(true)
	if cup_base == null:
		stage.set_active_prop_kind("base")
		context_title.text = GameLocale.text("DAY_CONTEXT_BASE")
		next_action_label.text = GameLocale.text("DAY_NEXT_BASE") + _confirm_suffix()
		var items := GameData.unlocked(GameData.bases, GameState.day)
		_set_context_columns(items.size())
		for item in items:
			_add_context_button(item, _on_base, false, _context_button_width(items.size()))
		return
	if cup_milk == null:
		stage.set_active_prop_kind("milk")
		context_title.text = GameLocale.text("DAY_CONTEXT_MILK")
		next_action_label.text = GameLocale.text("DAY_NEXT_MILK") + _confirm_suffix()
		var items := GameData.unlocked(GameData.milks, GameState.day)
		_set_context_columns(items.size())
		for item in items:
			_add_context_button(item, _on_milk, false, _context_button_width(items.size()))
		return

	var desired_tops := 0
	if active_customer != null and customers.has(active_customer):
		desired_tops = active_customer["order"]["tops"].size()
	if cup_tops.size() < desired_tops:
		stage.set_active_prop_kind("topping")
		context_title.text = GameLocale.text("DAY_CONTEXT_TOPPING", [cup_tops.size(), desired_tops])
		next_action_label.text = GameLocale.text("DAY_NEXT_TOPPING") + _confirm_suffix()
		var items := GameData.unlocked(GameData.toppings, GameState.day)
		_set_context_columns(items.size())
		for item in items:
			_add_context_button(item, _on_topping, _has_topping(item), _context_button_width(items.size()))
		return
	if not sugar_confirmed:
		stage.set_active_prop_kind("sugar")
		context_title.text = GameLocale.text("DAY_CONTEXT_SUGAR")
		next_action_label.text = GameLocale.text("DAY_NEXT_SUGAR") + _confirm_suffix()
		_set_context_columns(GameData.sugar_levels.size())
		for item in GameData.sugar_levels:
			_add_context_button(item, _on_sugar,
				int(item["value"]) == int(cup_sugar["value"]), _context_button_width(GameData.sugar_levels.size()))
		return

	stage.set_active_prop_kind("")
	context_title.text = GameLocale.text("DAY_CONTEXT_SHAKE")
	next_action_label.text = _shake_next_action_text()
	context_choices.columns = 3
	var left_space := Control.new()
	left_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_choices.add_child(left_space)
	var shake := Button.new()
	shake.text = _shake_button_text()
	shake.tooltip_text = GameLocale.text("DAY_SHAKE_GESTURE_HINT")
	shake.custom_minimum_size = Vector2(300, 58)
	shake.pressed.connect(_on_shake)
	context_choices.add_child(shake)
	var right_space := Control.new()
	right_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_choices.add_child(right_space)
	_context_shortcuts.append(shake)
	if InputPrompts.gamepad_mode:
		shake.call_deferred("grab_focus")


func _shake_count_display() -> int:
	# 向上取整显示：一次有效摇动后立即 +1，衰减中也不会出现“倒退”的计数。
	return mini(ceili(shake_progress), _shakes_needed())


func _shake_next_action_text(mobile_override: Variant = null) -> String:
	if InputPrompts.gamepad_mode:
		return GameLocale.text("DAY_NEXT_SHAKE", [InputPrompts.shake_hint(), _shake_count_display(), _shakes_needed()])
	var mobile := OS.has_feature("mobile") if mobile_override == null else bool(mobile_override)
	if mobile:
		return GameLocale.text("DAY_NEXT_SHAKE_MOBILE", [_shake_count_display(), _shakes_needed()])
	return GameLocale.text("DAY_NEXT_SHAKE_POINTER", [InputPrompts.shake_hint(), _shake_count_display(), _shakes_needed()])


func _shake_button_text(mobile_override: Variant = null) -> String:
	var mobile := OS.has_feature("mobile") if mobile_override == null else bool(mobile_override)
	if mobile and not InputPrompts.gamepad_mode:
		return GameLocale.text("DAY_SHAKE_BUTTON_MOBILE", [_shake_count_display(), _shakes_needed()])
	return GameLocale.text("DAY_SHAKE_BUTTON", [InputPrompts.shake_hint(), _shake_count_display(), _shakes_needed()])


func _set_context_panel_visible(show_panel: bool) -> void:
	if _context_panel_target_visible == show_panel:
		return
	_context_panel_target_visible = show_panel
	if _context_panel_tween != null and _context_panel_tween.is_valid():
		_context_panel_tween.kill()
	if GameState.reduced_motion():
		context_panel.modulate.a = 1.0
		context_panel.visible = show_panel
		return
	if show_panel:
		context_panel.visible = true
		context_panel.modulate.a = 0.0
		_context_panel_tween = context_panel.create_tween()
		_context_panel_tween.tween_property(context_panel, "modulate:a", 1.0, 0.12) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_context_panel_tween = context_panel.create_tween()
		_context_panel_tween.tween_property(context_panel, "modulate:a", 0.0, 0.10) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_context_panel_tween.tween_callback(func():
			if not _context_panel_target_visible:
				context_panel.visible = false
				context_panel.modulate.a = 1.0)


func _add_context_button(item: Dictionary, handler: Callable, selected := false, button_width := 106.0) -> void:
	var btn := Button.new()
	var item_name := GameLocale.ingredient_short_name(item).replace("（纯茶）", "")
	btn.text = item_name if InputPrompts.gamepad_mode else "%d  %s" % [_context_shortcuts.size() + 1, item_name]
	btn.custom_minimum_size = Vector2(button_width, 54)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 16)
	btn.tooltip_text = GameLocale.ingredient_name(item)
	var icon_path := "res://assets/icons/%s.png" % String(item.get("id", ""))
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
		btn.add_theme_constant_override("icon_max_width", 30)
	# Ingredient tiles are choices, not six simultaneous primary actions. Coral is
	# reserved for the selected state while the default stays calm and scannable.
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("FFE4DC") if selected else AppTheme.CREAM
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(3 if selected else 2)
	normal.border_color = AppTheme.CORAL if selected else Color(AppTheme.COCOA.r, AppTheme.COCOA.g, AppTheme.COCOA.b, 0.20)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("FFF0E8")
	hover.border_color = AppTheme.CORAL
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color("FFD3C9")
	pressed.border_color = AppTheme.CORAL
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_corner_radius_all(10)
	focus.set_border_width_all(4)
	focus.border_color = AppTheme.COCOA
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", focus)
	for color_state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(color_state, AppTheme.COCOA)
	btn.pressed.connect(handler.bind(item))
	var item_id := String(item.get("id", ""))
	btn.focus_entered.connect(stage.set_prop_hint.bind(item_id, "button_focus"))
	btn.focus_exited.connect(stage.clear_prop_hint.bind(item_id, "button_focus"))
	btn.mouse_entered.connect(stage.set_prop_hint.bind(item_id, "button_hover"))
	btn.mouse_exited.connect(stage.clear_prop_hint.bind(item_id, "button_hover"))
	context_choices.add_child(btn)
	_context_shortcuts.append(btn)
	if InputPrompts.gamepad_mode and _context_shortcuts.size() == 1:
		btn.call_deferred("grab_focus")


func _style_utility_button(button: Button, accent: Color, danger_copy := false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(AppTheme.CREAM.r, AppTheme.CREAM.g, AppTheme.CREAM.b, 0.96)
	normal.set_corner_radius_all(12)
	normal.set_border_width_all(2)
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.76)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(accent.r, accent.g, accent.b, 0.12)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.22)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.55, 0.51, 0.48, 0.46)
	disabled.border_color = Color(AppTheme.COCOA.r, AppTheme.COCOA.g, AppTheme.COCOA.b, 0.22)
	var focus: StyleBoxFlat = normal.duplicate()
	focus.set_border_width_all(4)
	focus.border_color = AppTheme.COCOA
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", focus)
	var copy_color := accent if danger_copy else AppTheme.COCOA
	for color_state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_state, copy_color)
	button.add_theme_color_override("font_disabled_color", Color(AppTheme.COCOA.r, AppTheme.COCOA.g, AppTheme.COCOA.b, 0.42))


func _context_button_width(count: int) -> float:
	return 120.0 if count >= 5 else 132.0


func _set_context_columns(count: int) -> void:
	context_choices.columns = 5 if count == 5 else mini(maxi(count, 1), 4)


func _confirm_suffix() -> String:
	return GameLocale.text("DAY_CONFIRM_SUFFIX", [InputPrompts.accept_hint()]) if InputPrompts.gamepad_mode else ""


func _on_input_scheme_changed(_gamepad: bool) -> void:
	call_deferred("_refresh_input_prompts")


func _on_bindings_changed() -> void:
	call_deferred("_refresh_input_prompts")


func _refresh_input_prompts() -> void:
	_refresh_context_controls()
	_refresh_prep_ui()
	_refresh_all_order_action_hints()


func _on_locale_changed(_locale: String) -> void:
	active_contract = EndlessContracts.active_for_day(GameState.day)
	day_event = EndlessContracts.apply_to_event(DailyEvents.event_for_day(GameState.day), GameState.day)
	_refresh_event_pill()
	# HUD/备料文本按输入缓存跳过重复重建；语言切换后必须强制重译。
	_info_inputs = []
	_prep_tea_title_inputs = [-1]
	_prep_pearl_title_inputs = [-1]
	_prep_tea_inputs = []
	_prep_pearl_inputs = []
	_refresh_cup()
	_refresh_prep_ui()
	_refresh_staff_ui()
	for customer in customers:
		_render_order_card(customer)
	_update_all_order_progress()
	_update_info()


# ---------------------------------------------------------------- 店员状态与双刃剑事件

func _setup_staff_for_day() -> void:
	staff_state = "working"
	staff_events = 0
	staff_wakes = 0
	staff_rescues = 0
	staff_bonus_earned = 0
	staff_guard_used = false
	staff_event_timer = 16.0
	staff_reveal_timer = 4.5
	if StaffCatalog.has_staff():
		staff_card.visible = true
		if StaffCatalog.is_on_duty():
			stage.add_staff(String(StaffCatalog.current().get("id", "")))
			stage.set_staff_state("working")
		else:
			staff_state = "resting"
			stage.remove_staff()
	else:
		stage.remove_staff()
		staff_card.visible = false
	_refresh_staff_ui()


func _update_staff(delta: float) -> void:
	if not StaffCatalog.is_on_duty():
		return
	if not StaffCatalog.trait_revealed() and StaffCatalog.trait_id() != "slacker":
		staff_reveal_timer -= delta
		if staff_reveal_timer <= 0.0:
			match StaffCatalog.trait_id():
				"social_king":
					_reveal_staff_trait(GameLocale.text("DAY_STAFF_REVEAL_SOCIAL"))
				"perfectionist":
					_reveal_staff_trait(GameLocale.text("DAY_STAFF_REVEAL_PERFECTIONIST"))
	if StaffCatalog.trait_id() == "slacker" and staff_state == "working":
		staff_event_timer -= delta
		if staff_event_timer <= 0.0:
			staff_state = "idle"
			staff_events += 1
			stage.set_staff_state("idle")
			Sfx.play("staff_alert")
			if not StaffCatalog.trait_revealed():
				_reveal_staff_trait(GameLocale.text("DAY_STAFF_REVEAL_SLACKER"))
			else:
				_flash(GameLocale.text("DAY_STAFF_SLACKING_ALERT", [GameLocale.staff_name(StaffCatalog.current())]), Color("FF6259"))
			_refresh_staff_ui()


func _reveal_staff_trait(detail: String) -> void:
	StaffCatalog.reveal_trait()
	staff_events += 1
	_flash(GameLocale.text("DAY_STAFF_TRAIT_REVEALED", [StaffCatalog.trait_name(), detail]), Color("FF6259"))
	_refresh_staff_ui()


func _on_staff_clicked() -> void:
	if not StaffCatalog.is_on_duty() or not running:
		return
	if staff_state == "idle":
		staff_state = "working"
		staff_wakes += 1
		staff_event_timer = randf_range(20.0, 28.0)
		stage.set_staff_state("working")
		Sfx.play("staff_wake")
		_flash(GameLocale.text("DAY_STAFF_WAKE_SUCCESS", [GameLocale.staff_name(StaffCatalog.current())]), Color("27B9A7"))
		_refresh_staff_ui()
	else:
		_flash(GameLocale.text("DAY_STAFF_ALREADY_WORKING", [GameLocale.staff_name(StaffCatalog.current())]), Color("27B9A7"))


func _refresh_staff_ui() -> void:
	if not StaffCatalog.has_staff() or staff_card == null:
		return
	if not StaffCatalog.is_on_duty():
		staff_title.text = GameLocale.text("DAY_STAFF_RESTING", [GameLocale.staff_name(StaffCatalog.current())])
		staff_trait_label.text = GameLocale.text("DAY_STAFF_TRAIT", [StaffCatalog.trait_name()]) if StaffCatalog.trait_revealed() else GameLocale.text("DAY_STAFF_TRAIT_HIDDEN")
		staff_status_label.text = GameLocale.text("DAY_STAFF_RESTING_STATUS", [StaffCatalog.wage_shortfall()])
		staff_action_button.disabled = true
		staff_action_button.text = GameLocale.text("DAY_STAFF_RETURNS", [GameState.day + 1])
		return
	staff_title.text = GameLocale.text("DAY_STAFF_ON_DUTY", [GameLocale.staff_name(StaffCatalog.current())])
	staff_trait_label.text = GameLocale.text("DAY_STAFF_TRAIT", [StaffCatalog.trait_name()]) if StaffCatalog.trait_revealed() else GameLocale.text("DAY_STAFF_TRAIT_HIDDEN")
	match StaffCatalog.trait_id():
		"slacker":
			staff_status_label.text = GameLocale.text("DAY_STAFF_SLACKER_IDLE" if staff_state == "idle" else "DAY_STAFF_SLACKER_WORKING")
		"social_king":
			staff_status_label.text = GameLocale.text("DAY_STAFF_SOCIAL")
		"perfectionist":
			staff_status_label.text = GameLocale.text("DAY_STAFF_PERFECTIONIST", [GameLocale.text("STATE_USED" if staff_guard_used else "STATE_READY")])
		_:
			staff_status_label.text = GameLocale.text("DAY_STAFF_ADAPTING")
	staff_action_button.disabled = staff_state != "idle"
	staff_action_button.text = GameLocale.text("DAY_STAFF_WAKE", [GameLocale.staff_name(StaffCatalog.current())]) if staff_state == "idle" else GameLocale.text("DAY_STAFF_INTERACT")


func _has_topping(item: Dictionary) -> bool:
	for topping in cup_tops:
		if topping["id"] == item["id"]:
			return true
	return false


# ---------------------------------------------------------------- 难度曲线

func _max_customers() -> int:
	return 2 if GameState.day <= 2 else 3


func _spawn_interval() -> float:
	var base := clampf(randf_range(10.0, 14.0) - float(GameState.day) * 1.3, 4.0, 14.0)
	return base * float(day_event.get("spawn_mult", 1.0)) * StaffCatalog.spawn_multiplier() \
		* MenuCatalog.traffic_multiplier() * LegacyRoutes.spawn_multiplier()


func _patience_for_day() -> float:
	var base := clampf(34.0 - float(GameState.day) * 2.0, 16.0, 32.0)
	return base * UpgradeCatalog.patience_multiplier() * float(day_event.get("patience_mult", 1.0)) \
		* StaffCatalog.patience_multiplier() * LegacyRoutes.patience_multiplier()


func _shakes_needed() -> int:
	return UpgradeCatalog.shakes_needed() + StaffCatalog.extra_shakes()


func _topping_count() -> int:
	if GameState.day <= 1:
		return [0, 0, 1].pick_random()
	if GameState.day <= 3:
		return [0, 1, 1].pick_random()
	if GameState.day <= 5:
		return [0, 1, 1, 2].pick_random()
	return [1, 1, 2, 2].pick_random()


# ---------------------------------------------------------------- 顾客与固定订单队列

func _free_slot() -> int:
	var used: Array = []
	for c in customers:
		used.append(c["slot"])
	for i in 3:
		if not i in used:
			return i
	return 0


func _spawn_customer() -> void:
	var day := GameState.day
	spawned_count += 1
	var kind := DailyEvents.customer_kind(day_event, spawned_count)
	var order := _generate_order(day, spawned_count, kind)
	var orders: Array = [order]
	if kind == "group":
		orders.append(_generate_order(day, spawned_count + 1000, kind))
	var special := kind != "regular"
	var featured_order := order.has("menu_item_id")
	var dark_order := order.has("dark_menu_id")
	var named_order := featured_order or dark_order

	var slot := _free_slot()
	var customer_color := Color.from_hsv(randf(), 0.55, 0.85)
	match kind:
		"critic":
			customer_color = Color("8C67B5")
		"influencer":
			customer_color = Color("F083A2")
		"group":
			customer_color = Color("3AAE9F")
	if dark_order:
		customer_color = Color("8C67B5")
	var node: Node3D = stage.add_customer(slot, customer_color, kind)
	Sfx.play("customer_arrive", randf_range(0.96, 1.06))

	# 固定订单卡：位置不再追随 3D 头像，信息更稳、触控目标更大；压窄给顾客让出站位。
	var bubble := PanelContainer.new()
	bubble.position = Vector2(14, 112 + slot * 158)
	bubble.custom_minimum_size = Vector2(248 if special or featured_order or dark_order else 212, 138)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 5)
	bubble.add_child(card_box)
	var header := HBoxContainer.new()
	card_box.add_child(header)
	var order_title := Label.new()
	order_title.add_theme_font_size_override("font_size", 16 if named_order else 20)
	order_title.custom_minimum_size = Vector2(160, 38) if named_order else Vector2(112, 0)
	order_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	order_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if named_order else TextServer.AUTOWRAP_OFF
	order_title.max_lines_visible = 2 if named_order else 1
	header.add_child(order_title)
	var order_progress := Label.new()
	order_progress.custom_minimum_size = Vector2(42, 0)
	order_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	order_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	order_progress.add_theme_font_size_override("font_size", 13)
	header.add_child(order_progress)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var patience_label := Label.new()
	patience_label.add_theme_font_size_override("font_size", 16)
	header.add_child(patience_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	card_box.add_child(row)
	var patience_bar := ProgressBar.new()
	patience_bar.max_value = 100.0
	patience_bar.show_percentage = false
	patience_bar.custom_minimum_size = Vector2(0, 12)
	patience_bar.tooltip_text = GameLocale.text("DAY_ROUTE_PATIENCE_TOOLTIP") \
		if LegacyRoutes.active_id() == "precision" else ""
	card_box.add_child(patience_bar)
	var patience_threshold := ColorRect.new()
	patience_threshold.color = Color("8C67B5")
	patience_threshold.anchor_left = 0.70
	patience_threshold.anchor_right = 0.70
	patience_threshold.anchor_top = 0.0
	patience_threshold.anchor_bottom = 1.0
	patience_threshold.offset_left = -2.0
	patience_threshold.offset_right = 2.0
	patience_threshold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patience_threshold.visible = LegacyRoutes.active_id() == "precision"
	patience_bar.add_child(patience_threshold)
	var hint := Label.new()
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(0.42, 0.30, 0.22)
	card_box.add_child(hint)
	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	# This transparent button sits above all order-card content. The global button
	# focus fill would cover the recipe when gamepad focus moves here after sealing,
	# so order cards use a border-only ring and leave their information visible.
	var order_focus := StyleBoxFlat.new()
	order_focus.draw_center = false
	order_focus.set_corner_radius_all(14)
	order_focus.set_border_width_all(4)
	order_focus.border_color = Color("30201D")
	btn.add_theme_stylebox_override("focus", order_focus)
	bubble.add_child(btn)
	ui_frame.add_child(bubble)

	var patience_mult := 1.0
	if kind == "critic":
		patience_mult = 0.78
	elif kind == "influencer":
		patience_mult = 0.90
	elif dark_order:
		patience_mult = 0.86
	var patience := _patience_for_day() * patience_mult
	var c := {
		"order": order, "orders": orders, "group_index": 0, "group_total": orders.size(),
		"patience": patience, "max_patience": patience,
		"node": node, "bubble": bubble, "btn": btn, "slot": slot,
		"patience_bar": patience_bar, "patience_label": patience_label,
		"order_title": order_title, "order_progress": order_progress,
		"order_row": row, "hint": hint,
		"special": special, "dark": dark_order, "kind": kind,
	}
	_render_order_card(c)
	btn.pressed.connect(_on_order_card_pressed.bind(c))
	btn.focus_entered.connect(_set_active_customer.bind(c))
	customers.append(c)
	if active_customer == null:
		_set_active_customer(c)
	else:
		_style_order_card(c, false)


func _generate_order(day: int, spawn_number: int, kind := "regular") -> Dictionary:
	var event_id := String(day_event.get("id", "calm"))
	if MenuCatalog.dark_should_offer(spawn_number, kind):
		var dark_entry := MenuCatalog.dark_for_spawn(spawn_number)
		var dark_order := MenuCatalog.dark_order_for_entry(dark_entry, spawn_number)
		if not dark_order.is_empty():
			return dark_order
	if MenuCatalog.should_offer(spawn_number, kind, event_id):
		var menu_item := MenuCatalog.featured_for_spawn(spawn_number, event_id)
		var menu_order := MenuCatalog.order_for_item(menu_item, spawn_number, event_id)
		if not menu_order.is_empty():
			return menu_order
	var order := {
		"base": GameData.unlocked(GameData.bases, day).pick_random(),
		"milk": GameData.unlocked(GameData.milks, day).pick_random(),
		"tops": [],
		"sugar": GameData.sugar_levels.pick_random(),
	}
	var top_pool: Array = GameData.unlocked(GameData.toppings, day).duplicate()
	top_pool.shuffle()
	for i in mini(_topping_count(), top_pool.size()):
		order["tops"].append(top_pool[i])
	return DailyEvents.modify_order(day_event, order, top_pool, spawn_number, kind)


func _render_order_card(c: Dictionary) -> void:
	c["patience_bar"].tooltip_text = GameLocale.text("DAY_ROUTE_PATIENCE_TOOLTIP") \
		if LegacyRoutes.active_id() == "precision" else ""
	var kind := String(c.get("kind", "regular"))
	var menu_item_id := String(c["order"].get("menu_item_id", ""))
	var menu_item := MenuCatalog.item(menu_item_id) if not menu_item_id.is_empty() else {}
	var dark_menu_id := String(c["order"].get("dark_menu_id", ""))
	var dark_entry: Dictionary = {}
	for entry in MenuCatalog.dark_items():
		if MenuCatalog.dark_item_id(entry) == dark_menu_id:
			dark_entry = entry
			break
	if not dark_entry.is_empty():
		c["order_title"].text = GameLocale.text("DAY_ORDER_DARK", [MenuCatalog.dark_display_name(dark_entry)])
	else:
		match kind:
			"critic":
				c["order_title"].text = GameLocale.text("DAY_ORDER_CRITIC", [int(c["slot"]) + 1])
			"influencer":
				c["order_title"].text = GameLocale.text("DAY_ORDER_INFLUENCER", [int(c["slot"]) + 1])
			"group":
				c["order_title"].text = GameLocale.text("DAY_ORDER_GROUP", [int(c["group_index"]) + 1, int(c["group_total"])])
			_:
				c["order_title"].text = GameLocale.text("DAY_ORDER_MENU", [MenuCatalog.display_name(menu_item)]) \
					if not menu_item.is_empty() else GameLocale.text("DAY_ORDER_REGULAR", [int(c["slot"]) + 1])
	c["order_title"].tooltip_text = c["order_title"].text
	c["btn"].tooltip_text = c["order_title"].text
	c["btn"].accessibility_name = c["order_title"].text
	c["order_title"].add_theme_font_size_override("font_size", 16 if not menu_item.is_empty() or not dark_entry.is_empty() else 20)
	var row: HBoxContainer = c["order_row"]
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	var order: Dictionary = c["order"]
	var components: Array[Dictionary] = [
		{"kind": "base", "item": order["base"]},
		{"kind": "milk", "item": order["milk"]},
	]
	for topping in order["tops"]:
		components.append({"kind": "topping", "item": topping})
	var progress_slots: Array[Dictionary] = []
	var icon_size := 34 if order["tops"].size() >= 2 else 38
	for component in components:
		var ingredient: Dictionary = component["item"]
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(icon_size, icon_size)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = load("res://assets/icons/%s.png" % ingredient["id"])
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		var badge := Label.new()
		badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		badge.add_theme_font_size_override("font_size", 13)
		badge.add_theme_constant_override("outline_size", 4)
		badge.add_theme_color_override("font_outline_color", Color("FFF8ED"))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(badge)
		row.add_child(slot)
		progress_slots.append({
			"kind": String(component["kind"]), "id": String(ingredient["id"]),
			"panel": slot, "badge": badge,
		})
	var sugar_slot := PanelContainer.new()
	sugar_slot.custom_minimum_size = Vector2(58 if order["tops"].size() >= 2 else 68, icon_size)
	sugar_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sugar_label := Label.new()
	sugar_label.text = GameLocale.text("DAY_ORDER_SUGAR", [GameLocale.ingredient_short_name(order["sugar"])])
	sugar_label.add_theme_font_size_override("font_size", 13 if order["tops"].size() >= 2 else 15)
	sugar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sugar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sugar_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sugar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sugar_slot.add_child(sugar_label)
	row.add_child(sugar_slot)
	progress_slots.append({
		"kind": "sugar", "id": str(int(order["sugar"]["value"])),
		"panel": sugar_slot, "badge": null,
	})
	var accessible_parts: Array[String] = [
		GameLocale.ingredient_name(order["base"]),
		GameLocale.ingredient_name(order["milk"]),
	]
	for topping in order["tops"]:
		accessible_parts.append(GameLocale.ingredient_name(topping))
	accessible_parts.append(GameLocale.text("DAY_ORDER_SUGAR", [GameLocale.ingredient_short_name(order["sugar"])]))
	c["btn"].accessibility_description = " · ".join(accessible_parts)
	c["progress_slots"] = progress_slots
	_refresh_order_action_hint(c)
	_update_order_progress(c, c == active_customer)


func _refresh_order_action_hint(c: Dictionary) -> void:
	if not is_instance_valid(c.get("hint")):
		return
	if cup_sealed:
		if c == active_customer:
			c["hint"].text = GameLocale.text("DAY_ORDER_DELIVER_GAMEPAD", [InputPrompts.accept_hint()]) \
				if InputPrompts.gamepad_mode else GameLocale.text("DAY_ORDER_DELIVER_POINTER")
		else:
			c["hint"].text = GameLocale.text("DAY_ORDER_REVIEW_GAMEPAD" \
				if InputPrompts.gamepad_mode else "DAY_ORDER_REVIEW_POINTER")
		return
	var order: Dictionary = c["order"]
	var menu_item_id := String(order.get("menu_item_id", ""))
	var menu_item := MenuCatalog.item(menu_item_id) if not menu_item_id.is_empty() else {}
	if not menu_item.is_empty():
		var match_bonus := int(order.get("menu_event_bonus", 0))
		c["hint"].text = GameLocale.text("ORDER_HINT_MENU_MATCH", [
			MenuCatalog.sale_price(menu_item), match_bonus, MenuCatalog.hype_text(menu_item)]) \
			if match_bonus > 0 else GameLocale.text("ORDER_HINT_MENU", [
				MenuCatalog.sale_price(menu_item), MenuCatalog.hype_text(menu_item)])
	else:
		c["hint"].text = DailyEvents.order_hint(day_event, c)


func _refresh_all_order_action_hints() -> void:
	for customer in customers:
		_refresh_order_action_hint(customer)


func _order_progress_style(state: String) -> StyleBox:
	if _order_progress_styles.has(state):
		return _order_progress_styles[state]
	if state == "neutral":
		var empty := StyleBoxEmpty.new()
		_order_progress_styles[state] = empty
		return empty
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(1 if state == "pending" else 2)
	match state:
		"match":
			style.bg_color = Color(0.15, 0.73, 0.65, 0.18)
			style.border_color = Color("27B9A7")
		"wrong":
			style.bg_color = Color(1.0, 0.38, 0.35, 0.18)
			style.border_color = Color("E5484D")
		_:
			style.bg_color = Color(1.0, 1.0, 1.0, 0.06)
			style.border_color = Color(0.19, 0.13, 0.11, 0.16)
	_order_progress_styles[state] = style
	return style


func _order_component_state(kind: String, target_id: String, order: Dictionary) -> String:
	match kind:
		"base":
			if cup_base == null:
				return "pending"
			return "match" if String(cup_base["id"]) == target_id else "wrong"
		"milk":
			if cup_milk == null:
				return "pending"
			return "match" if String(cup_milk["id"]) == target_id else "wrong"
		"topping":
			for topping in cup_tops:
				if String(topping["id"]) == target_id:
					return "match"
			var ordered_ids: Array[String] = []
			for topping in order["tops"]:
				ordered_ids.append(String(topping["id"]))
			for topping in cup_tops:
				if String(topping["id"]) not in ordered_ids:
					return "wrong"
			return "wrong" if cup_tops.size() >= order["tops"].size() else "pending"
		"sugar":
			if not sugar_confirmed:
				return "pending"
			return "match" if cup_sugar != null and str(int(cup_sugar["value"])) == target_id else "wrong"
	return "pending"


func _update_order_progress(c: Dictionary, active: bool) -> void:
	if not c.has("progress_slots"):
		return
	var matched := 0
	var wrong := false
	var total: int = c["progress_slots"].size()
	for slot_data in c["progress_slots"]:
		var state := "neutral"
		if active:
			state = _order_component_state(String(slot_data["kind"]), String(slot_data["id"]), c["order"])
			matched += 1 if state == "match" else 0
			wrong = wrong or state == "wrong"
		var panel: PanelContainer = slot_data["panel"]
		if String(panel.get_meta("progress_state", "")) != state:
			panel.set_meta("progress_state", state)
			panel.add_theme_stylebox_override("panel", _order_progress_style(state))
		var badge: Variant = slot_data["badge"]
		if badge is Label:
			badge.text = "✓" if state == "match" else ("!" if state == "wrong" else "")
			badge.add_theme_color_override("font_color", Color("168C80") if state == "match" else Color("C83E49"))
	var ordered_top_ids: Array[String] = []
	for topping in c["order"]["tops"]:
		ordered_top_ids.append(String(topping["id"]))
	for topping in cup_tops:
		if String(topping["id"]) not in ordered_top_ids:
			wrong = true
	var progress: Label = c["order_progress"]
	progress.text = "" if not active else ("! %d/%d" % [matched, total] if wrong \
		else ("✓ %d/%d" % [matched, total] if matched == total else "%d/%d" % [matched, total]))
	progress.add_theme_color_override("font_color", Color("C83E49") if wrong \
		else (Color("168C80") if matched > 0 else Color(0.30, 0.22, 0.18, 0.62)))


func _update_all_order_progress() -> void:
	for customer in customers:
		_update_order_progress(customer, customer == active_customer)


func order_progress_states(c: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for slot_data in c.get("progress_slots", []):
		var panel := slot_data["panel"] as PanelContainer
		result.append(String(panel.get_meta("progress_state", "")))
	return result


func _on_order_card_pressed(c: Dictionary) -> void:
	# 焦点驱动的按键可能在暂停/结算覆盖层下触达此入口（语言或设备方案切换会
	# 把焦点偷走，评审 R3-F2）；营业外一律拒绝，防止暂停中送杯。
	if not running:
		return
	if cup_sealed:
		# The focused/active card is already reviewed, so confirm it immediately.
		# A different pointer or number-key target gets one non-destructive review
		# step first, matching the focus-then-A flow used by gamepads.
		if c == active_customer:
			_on_deliver(c)
		else:
			_set_active_customer(c)
	else:
		_set_active_customer(c)


func _set_active_customer(c: Dictionary) -> void:
	if not customers.has(c):
		return
	# Focus entering the already-active order must be a no-op. Rebuilding the
	# sealed-cup controls schedules another grab_focus(), which can feed back into
	# focus_entered indefinitely on rendered builds and exhaust the message queue.
	if active_customer == c:
		return
	active_customer = c
	for item in customers:
		_style_order_card(item, item == active_customer)
	_refresh_context_controls()
	_update_all_order_progress()
	_refresh_all_order_action_hints()


func _focus_active_order() -> void:
	if not cup_sealed or not InputPrompts.gamepad_mode \
			or active_customer == null or not customers.has(active_customer):
		return
	# 暂停或结算覆盖层打开时不把焦点移到被遮挡的订单卡上，
	# 防止 A 键在暂停中激活隐藏按钮（评审 R3-F2）。
	if get_tree().paused or not running:
		return
	var button := active_customer.get("btn") as Button
	if button != null and is_instance_valid(button) and not button.has_focus():
		button.grab_focus()


func _style_order_card(c: Dictionary, active: bool) -> void:
	if not is_instance_valid(c.get("bubble")):
		return
	# 四种组合的样式在建卡后不再变化；共享缓存实例，避免逐帧分配与主题失效。
	if _card_panel_active == null:
		_card_panel_active = StyleBoxFlat.new()
		_card_panel_active.bg_color = Color(1.0, 0.973, 0.929, 0.97)
		_card_panel_active.set_corner_radius_all(14)
		_card_panel_active.set_border_width_all(4)
		_card_panel_active.border_color = Color("FF6259")
		_card_panel_active.content_margin_left = 10
		_card_panel_active.content_margin_right = 10
		_card_panel_active.content_margin_top = 8
		_card_panel_active.content_margin_bottom = 8
		_card_panel_idle = StyleBoxFlat.new()
		_card_panel_idle.bg_color = Color(1.0, 0.973, 0.929, 0.97)
		_card_panel_idle.set_corner_radius_all(14)
		_card_panel_idle.set_border_width_all(2)
		_card_panel_idle.border_color = Color(0.19, 0.13, 0.11, 0.34)
		_card_panel_idle.content_margin_left = 10
		_card_panel_idle.content_margin_right = 10
		_card_panel_idle.content_margin_top = 8
		_card_panel_idle.content_margin_bottom = 8
		_card_fill_healthy = StyleBoxFlat.new()
		_card_fill_healthy.bg_color = Color("27B9A7")
		_card_fill_healthy.set_corner_radius_all(6)
		_card_fill_warn = StyleBoxFlat.new()
		_card_fill_warn.bg_color = Color("D99A43")
		_card_fill_warn.set_corner_radius_all(6)
		_card_fill_low = StyleBoxFlat.new()
		_card_fill_low.bg_color = Color("E5484D")
		_card_fill_low.set_corner_radius_all(6)
	var ratio: float = c["patience"] / c["max_patience"]
	c["bubble"].add_theme_stylebox_override("panel", _card_panel_active if active else _card_panel_idle)
	# 三档色带与服务费档位一致（>0.7 满小费 / >0.4 低小费 / 以下无小费）：
	# 掉档即可读出正在损失的钱，而不是 35% 处一次性红转。
	c["patience_bar"].add_theme_stylebox_override("fill",
		_card_fill_healthy if ratio > 0.70 else (_card_fill_warn if ratio > 0.40 else _card_fill_low))


func _on_deliver(c: Dictionary) -> void:
	if not cup_sealed:
		_flash(GameLocale.text("DAY_NOT_SEALED"), Color.ORANGE)
		Haptics.play("warning")
		return
	var order: Dictionary = c["order"]
	var ok: bool = cup_base["id"] == order["base"]["id"] \
		and cup_milk["id"] == order["milk"]["id"] \
		and int(cup_sugar["value"]) == int(order["sugar"]["value"]) \
		and _same_tops(order["tops"])
	var used: Array = [cup_base["id"], cup_milk["id"]]
	for t in cup_tops:
		used.append(t["id"])
	GameState.gain_xp(used)
	var used_ingredients: Array = [cup_base, cup_milk] + cup_tops
	var consumed_cost := OperatingCosts.cup_cost(used_ingredients)

	if ok:
		stock_cost += consumed_cost
		var batch_quality := _cup_batch_quality()
		var clean_build := cup_corrections == 0
		var flawless := clean_build and batch_quality > 0
		var menu_item_id := String(order.get("menu_item_id", ""))
		var menu_item := MenuCatalog.item(menu_item_id) if not menu_item_id.is_empty() else {}
		var dark_menu_id := String(order.get("dark_menu_id", ""))
		var dark_item: Dictionary = {}
		for entry in MenuCatalog.dark_items():
			if MenuCatalog.dark_item_id(entry) == dark_menu_id:
				dark_item = entry
				break
		var price: int = MenuCatalog.dark_sale_price(dark_item) if not dark_item.is_empty() else (
			MenuCatalog.sale_price(menu_item) if not menu_item.is_empty() else 8 + 2 * cup_tops.size())
		var poor_batch_penalty := 2 if batch_quality == 0 else 0
		price = maxi(1, price - poor_batch_penalty)
		# 小费分层：手速快慢直接拉开收入差距，后期高压下熟练度才有回报
		var ratio: float = c["patience"] / c["max_patience"]
		var service_tip: int = 3 if ratio > 0.7 else (1 if ratio > 0.4 else 0)
		var upgrade_tip := UpgradeCatalog.tip_bonus()
		var tip := service_tip + upgrade_tip
		# 连击只认可无返工的干净制作；返工杯仍能正常售出，但不再把
		# “最终配方正确”伪装成“完美操作”。
		if flawless:
			streak += 1
			best_streak = maxi(best_streak, streak)
			_pulse_streak_pill()
		else:
			streak = 0
		var combo_bonus := 0
		if flawless and streak > 0 and streak % 3 == 0:
			combo_bonus = 3
		var event_reward := DailyEvents.order_bonus(day_event, c)
		var event_coins := int(event_reward["coins"])
		var event_inspiration := int(event_reward["inspiration"])
		var event_buzz := int(event_reward.get("buzz", 0))
		var staff_coins := StaffCatalog.quality_coin_bonus()
		var route_coins := LegacyRoutes.sale_bonus(order, ratio, streak)
		var golden_batch_bonus := 2 if clean_build and batch_quality == 2 else 0
		var total_coins := price + tip + combo_bonus + event_coins + staff_coins + route_coins \
			+ golden_batch_bonus
		var inspiration_gain := (1 if flawless else 0) \
			+ (1 if combo_bonus > 0 else 0) + (1 if golden_batch_bonus > 0 else 0) + event_inspiration
		event_bonus_earned += event_coins
		staff_bonus_earned += staff_coins
		route_bonus_earned += route_coins
		if route_coins > 0:
			route_trigger_count += 1
			stage.pulse_route_sign()
		event_buzz_earned += event_buzz
		GameState.buzz += event_buzz
		var dark_buzz := 0
		if not dark_item.is_empty():
			dark_buzz = 2 if flawless else 1
			dark_sales_count += 1
			dark_buzz_earned += dark_buzz
			GameState.buzz += dark_buzz
			MenuCatalog.record_dark_sale(dark_menu_id)
		if batch_quality == 2:
			golden_batches_served += 1
		elif batch_quality == 0:
			poor_batches_served += 1
		var group_continues := String(c.get("kind", "regular")) == "group" \
			and int(c.get("group_index", 0)) < int(c.get("group_total", 1)) - 1
		if bool(c.get("special", false)) and not group_continues:
			special_served += 1
		earned += total_coins
		GameState.coins += total_coins
		if not menu_item.is_empty():
			menu_sales_count += 1
			menu_sales_revenue += price
			menu_sales_by_id[menu_item_id] = int(menu_sales_by_id.get(menu_item_id, 0)) + 1
		GameState.inspiration += inspiration_gain
		if flawless:
			GameState.perfect_total += 1
			perfect += 1
		served += 1
		var msg := GameLocale.text("DAY_REWARD_COINS", [total_coins])
		if tip > 0:
			msg += GameLocale.text("DAY_REWARD_TIP", [tip])
		if event_coins > 0:
			msg += GameLocale.text("DAY_REWARD_REASON", [String(event_reward["reason"])])
		if event_buzz > 0:
			msg += GameLocale.text("DAY_REWARD_BUZZ", [event_buzz])
		if dark_buzz > 0:
			msg += GameLocale.text("DAY_REWARD_DARK", [dark_buzz])
		if golden_batch_bonus > 0:
			msg += GameLocale.text("DAY_REWARD_BATCH_GOLDEN", [golden_batch_bonus])
		elif poor_batch_penalty > 0:
			msg += GameLocale.text("DAY_REWARD_BATCH_POOR", [poor_batch_penalty])
		if staff_coins > 0:
			msg += GameLocale.text("DAY_REWARD_STAFF", [staff_coins])
		if route_coins > 0:
			msg += GameLocale.text("DAY_REWARD_ROUTE", [route_coins, String(LegacyRoutes.route().get("short_name", ""))])
		if combo_bonus > 0:
			msg += GameLocale.text("DAY_REWARD_COMBO", [streak])
		if not menu_item.is_empty():
			msg += GameLocale.text("DAY_REWARD_MENU", [MenuCatalog.display_name(menu_item)])
		if not flawless:
			msg += GameLocale.text("DAY_REWARD_REWORKED")
		if group_continues:
			msg += GameLocale.text("DAY_REWARD_GROUP_NEXT")
		_flash(msg, Color.ORANGE_RED if combo_bonus > 0 else Color.GREEN_YELLOW)
		_fly_coin("+%d" % total_coins, c["bubble"].position)
		_punch(Vector2(0, -6))
		Sfx.play("serve")
		Haptics.play("success")
		if combo_bonus > 0:
			Sfx.play("combo")
		EventBus.customer_served.emit(true, total_coins)
		if group_continues:
			c["group_index"] = int(c["group_index"]) + 1
			c["order"] = c["orders"][c["group_index"]]
			c["patience"] = minf(float(c["max_patience"]),
				float(c["patience"]) + float(c["max_patience"]) * 0.48)
			_render_order_card(c)
			_style_order_card(c, c == active_customer)
		else:
			_remove_customer(c, true)
	else:
		stock_cost += consumed_cost
		waste_cost += consumed_cost
		if StaffCatalog.is_on_duty() and StaffCatalog.trait_id() == "perfectionist" and not staff_guard_used:
			Haptics.play("warning")
			staff_guard_used = true
			staff_rescues += 1
			if not StaffCatalog.trait_revealed():
				_reveal_staff_trait(GameLocale.text("DAY_STAFF_REVEAL_GUARD"))
			_flash(GameLocale.text("DAY_STAFF_GUARD_SAVED", [GameLocale.staff_name(StaffCatalog.current())]), Color("27B9A7"))
			_refresh_staff_ui()
			_reset_cup()
			return
		c["patience"] = c["patience"] * 0.65
		streak = 0
		_flash(GameLocale.text("DAY_FEEDBACK_WRONG",
			[_wrong_component_names(order), consumed_cost]), Color.ORANGE)
		_punch(Vector2(8, 0))
		Sfx.play("bad")
		Haptics.play("warning")
	_reset_cup()


## 送错时指明错在哪个组件：顾客重做的代价（倒杯损失）当场可读，而不是只在夜间账本出现。
func _wrong_component_names(order: Dictionary) -> String:
	var parts: Array[String] = []
	if String(cup_base["id"]) != String(order["base"]["id"]):
		parts.append(GameLocale.text("DAY_COMPONENT_BASE"))
	if String(cup_milk["id"]) != String(order["milk"]["id"]):
		parts.append(GameLocale.text("DAY_COMPONENT_MILK"))
	if int(cup_sugar["value"]) != int(order["sugar"]["value"]):
		parts.append(GameLocale.text("DAY_COMPONENT_SUGAR"))
	if not _same_tops(order["tops"]):
		parts.append(GameLocale.text("DAY_COMPONENT_TOPPING"))
	if parts.is_empty():
		parts.append(GameLocale.text("DAY_COMPONENT_BASE"))
	return GameLocale.text("DAY_FEEDBACK_WRONG_PARTS_SEP").join(parts)


func _same_tops(order_tops: Array) -> bool:
	if order_tops.size() != cup_tops.size():
		return false
	var a: Array = []
	var b: Array = []
	for t in order_tops:
		a.append(t["id"])
	for t in cup_tops:
		b.append(t["id"])
	a.sort()
	b.sort()
	return a == b


func _customer_leave(c: Dictionary, msg: String) -> void:
	angry += 1
	streak = 0
	_flash(msg, Color.ORANGE_RED)
	Sfx.play("customer_leave")
	EventBus.customer_left_angry.emit()
	_remove_customer(c)


func _remove_customer(c: Dictionary, served := false) -> void:
	var was_active: bool = active_customer == c
	customers.erase(c)
	stage.remove_customer(c["node"], served)
	c["bubble"].queue_free()
	if was_active:
		active_customer = customers[0] if not customers.is_empty() else null
	for item in customers:
		_style_order_card(item, item == active_customer)
	_refresh_context_controls()
	_update_all_order_progress()
	_refresh_all_order_action_hints()


# ---------------------------------------------------------------- 日循环

func _start_day() -> void:
	MenuCatalog.ensure_normalized()
	# 恢复未结算的白天时 GameState 已回滚到开店快照；新的一天才重新标记。
	if int(GameState.day_open.get("day", 0)) != GameState.day:
		GameState.mark_day_open()
	active_contract = EndlessContracts.active_for_day(GameState.day)
	day_event = EndlessContracts.apply_to_event(DailyEvents.event_for_day(GameState.day), GameState.day)
	time_left = DAY_LENGTH
	earned = 0
	served = 0
	perfect = 0
	angry = 0
	streak = 0
	best_streak = 0
	spawned_count = 0
	event_bonus_earned = 0
	event_buzz_earned = 0
	route_bonus_earned = 0
	route_trigger_count = 0
	special_served = 0
	menu_sales_count = 0
	menu_sales_revenue = 0
	menu_sales_by_id = {}
	dark_sales_count = 0
	dark_buzz_earned = 0
	golden_batches_served = 0
	poor_batches_served = 0
	stock_cost = 0
	waste_cost = 0
	# 目标仍随天数增长，但不再超过成长系统能追回的范围。
	goal = ceili(float(EndlessContracts.goal_for_day(GameState.day)) * LegacyRoutes.goal_multiplier())
	shake_bar.max_value = _shakes_needed()
	spawn_timer = 1.0
	running = true
	active_customer = null
	overlay.visible = false
	for child in overlay.get_children():
		child.queue_free()
	stage.build_props(GameState.day, GameData.sugar_levels[sugar_index])
	_init_prep_inventory()
	_setup_staff_for_day()
	_refresh_event_pill()
	_reset_cup()
	# Populate every metric before the first process tick. Render/performance
	# harnesses and an immediate pause can legitimately freeze the shift in the
	# same frame it is created; leaving labels empty made those states look broken.
	_update_info()
	EventBus.day_started.emit(GameState.day)


func _end_day() -> void:
	running = false
	pause_button.visible = false
	for c in customers.duplicate():
		_remove_customer(c)
	# 打烊瞬间在制的杯子与手动弃杯同样计入成本/损耗，不能白拿一杯原料。
	if _cup_has_contents():
		var leftover_cost := _current_cup_cost()
		if leftover_cost > 0:
			stock_cost += leftover_cost
			waste_cost += leftover_cost
	var menu_income := menu_sales_revenue
	MenuCatalog.advance_day(GameState.day, menu_sales_by_id)
	var dark_orders := dark_sales_count
	# 星级结算：目标达成度换算 0-3 星，3 星额外奖励灵感
	var stars := 0
	if earned >= int(goal * STAR_GOAL_MULT):
		stars = 3
	elif earned >= goal:
		stars = 2
	elif earned >= int(goal * 0.7):
		stars = 1
	if stars == 3:
		GameState.inspiration += 3
	var wage_result := StaffCatalog.charge_daily_wage(GameState.day)
	var staff_wage := int(wage_result["paid"])
	var ledger := OperatingCosts.settle(GameState.day, stock_cost, waste_cost)
	var operating_paid := int(ledger["paid_total"])
	var net_operating := earned - staff_wage - operating_paid
	var stats := {"earned": earned, "served": served, "perfect": perfect, "angry": angry,
		"stars": stars, "best_streak": best_streak, "event_id": day_event.get("id", "calm"),
		"event_bonus": event_bonus_earned, "event_buzz": event_buzz_earned,
		"route_bonus": route_bonus_earned,
		"menu_sales": menu_sales_count, "menu_revenue": menu_sales_revenue,
		"buzz_earned": event_buzz_earned + dark_buzz_earned,
		"dark_sales": dark_sales_count, "dark_buzz": dark_buzz_earned,
		"golden_batches": golden_batches_served, "poor_batches": poor_batches_served,
		"special_served": special_served, "staff_wage": staff_wage,
		"staff_wage_due": int(wage_result["due"]),
		"staff_wage_shortfall": int(wage_result["shortfall"]),
		"staff_rest_scheduled": String(wage_result["status"]) == "shortfall",
		"staff_rest_day": String(wage_result["status"]) == "rest",
		"staff_on_duty": bool(wage_result["worked"]),
		"staff_events": staff_events, "staff_wakes": staff_wakes,
		"staff_rescues": staff_rescues, "staff_bonus": staff_bonus_earned,
		"stock_cost": int(ledger["stock_paid"]), "stock_due": int(ledger["stock_due"]),
		"waste_cost": int(ledger["waste_due"]), "rent_due": int(ledger["rent_due"]),
		"rent_paid": int(ledger["rent_paid"]), "cost_relief": int(ledger["relief"]),
		"operating_cost": operating_paid, "net_operating": net_operating}
	var contract_result := EndlessContracts.resolve(GameState.day, stats)
	if not contract_result.is_empty():
		stats["contract"] = contract_result
	GameState.record_campaign_day(GameState.day, stats)
	EventBus.day_ended.emit(stats)
	GameState.phase = "night"
	GameState.save_game()

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(700, 540)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	v.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var title := Label.new()
	title.text = GameLocale.text("DAY_RESULT_TITLE", [GameState.day])
	title.add_theme_font_size_override("font_size", 30)
	title_box.add_child(title)
	var verdict := Label.new()
	# 1-2 星判定附带净经营入：星级按毛收入，钱包另算——两个记分牌不再互相矛盾。
	if stars == 1 or stars == 2:
		verdict.text = GameLocale.text("DAY_RESULT_VERDICT_%d" % stars, [net_operating])
	else:
		verdict.text = GameLocale.text("DAY_RESULT_VERDICT_%d" % stars)
	verdict.add_theme_font_size_override("font_size", 17)
	verdict.add_theme_color_override("font_color", Color("27B9A7"))
	title_box.add_child(verdict)
	var rating := PanelContainer.new()
	var rating_style := StyleBoxFlat.new()
	rating_style.bg_color = Color("FF6259")
	rating_style.set_corner_radius_all(12)
	rating_style.content_margin_left = 18
	rating_style.content_margin_right = 18
	rating_style.content_margin_top = 9
	rating_style.content_margin_bottom = 9
	rating.add_theme_stylebox_override("panel", rating_style)
	header.add_child(rating)
	var rating_label := Label.new()
	rating_label.text = GameLocale.text("DAY_RESULT_STARS", [stars])
	rating_label.add_theme_font_size_override("font_size", 20)
	rating_label.add_theme_color_override("font_color", Color("30201D"))
	rating.add_child(rating_label)

	var goal_row := HBoxContainer.new()
	goal_row.add_theme_constant_override("separation", 10)
	v.add_child(goal_row)
	var goal_label := Label.new()
	goal_label.text = GameLocale.text("DAY_RESULT_GOAL")
	goal_label.custom_minimum_size = Vector2(88, 0)
	goal_row.add_child(goal_label)
	var star_goal := int(goal * STAR_GOAL_MULT)
	var result_goal := ProgressBar.new()
	result_goal.max_value = maxi(goal + 1, star_goal)
	result_goal.value = earned
	result_goal.show_percentage = false
	result_goal.custom_minimum_size = Vector2(440, 14)
	result_goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 结算条同样拉到三星线：目标处留刻度，条尾即 3★——判定不再不可见。
	var result_goal_tick := ColorRect.new()
	result_goal_tick.color = Color(0.19, 0.13, 0.11, 0.45)
	result_goal_tick.anchor_left = float(goal) / float(maxi(goal + 1, star_goal))
	result_goal_tick.anchor_right = float(goal) / float(maxi(goal + 1, star_goal))
	result_goal_tick.anchor_top = 0.0
	result_goal_tick.anchor_bottom = 1.0
	result_goal_tick.offset_left = -1.0
	result_goal_tick.offset_right = 1.0
	result_goal_tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_goal.add_child(result_goal_tick)
	goal_row.add_child(result_goal)
	var goal_numbers := Label.new()
	goal_numbers.text = GameLocale.text("DAY_RESULT_GOAL_NUMBERS", [earned, goal, star_goal])
	goal_numbers.add_theme_font_size_override("font_size", 16)
	goal_row.add_child(goal_numbers)

	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 10)
	v.add_child(metrics)
	_result_metric(metrics, HudCoinIcon, GameLocale.text("DAY_RESULT_REVENUE"), "%d" % earned,
		GameLocale.text("DAY_RESULT_REVENUE_DETAIL", [menu_income, event_bonus_earned]))
	var clean_rate := roundi(float(perfect) / float(served) * 100.0) if served > 0 else 0
	_result_metric(metrics, HudPerfectIcon, GameLocale.text("DAY_RESULT_PERFECT"), "%d / %d" % [perfect, served],
		GameLocale.text("DAY_RESULT_CRAFT_DETAIL", [clean_rate, served - perfect, angry]))
	_result_metric(metrics, HudStreakIcon, GameLocale.text("DAY_RESULT_COMBO"), "x%d" % best_streak,
		GameLocale.text("DAY_RESULT_INSPIRATION", [perfect]))
	_build_finance_ledger(v, earned, staff_wage, ledger, net_operating)

	var rewards := Label.new()
	var reward_lines: Array[String] = []
	if stars == 3:
		reward_lines.append(GameLocale.text("DAY_RESULT_THREE_STAR"))
	if dark_orders > 0:
		reward_lines.append(GameLocale.text("DAY_RESULT_DARK_MENU", [dark_orders, dark_buzz_earned]))
	if menu_sales_count > 0:
		reward_lines.append(GameLocale.text("DAY_RESULT_MENU_SALES", [menu_sales_count, menu_sales_revenue]))
	if event_bonus_earned > 0:
		reward_lines.append(GameLocale.text("DAY_RESULT_EVENT_COINS", [day_event["name"], event_bonus_earned]))
	if route_bonus_earned > 0:
		reward_lines.append(GameLocale.text("DAY_RESULT_ROUTE_BONUS", [
			String(LegacyRoutes.route().get("name", "")), route_bonus_earned]))
	if event_buzz_earned > 0:
		reward_lines.append(GameLocale.text("DAY_RESULT_BUZZ", [event_buzz_earned]))
	if special_served > 0:
		var special_result: String = String({
			"critic_day": GameLocale.text("REWARD_CRITIC_REVIEW"),
			"influencer_day": GameLocale.text("REWARD_INFLUENCER_POST"),
			"group_day": GameLocale.text("REWARD_GROUP_COMPLETE"),
		}.get(String(day_event.get("id", "")), GameLocale.text("REWARD_SPECIAL_COMPLETE")))
		reward_lines.append(GameLocale.text("DAY_RESULT_SPECIAL", [special_result, special_served]))
	if String(wage_result["status"]) == "shortfall":
		reward_lines.append(GameLocale.text("DAY_RESULT_WAGE_SHORTFALL", [
			GameLocale.staff_name(StaffCatalog.current()), staff_wage, int(wage_result["due"]),
			int(wage_result["rest_day"])]))
	elif String(wage_result["status"]) == "rest":
		reward_lines.append(GameLocale.text("DAY_RESULT_STAFF_REST_COMPLETE", [
			GameLocale.staff_name(StaffCatalog.current()), GameState.day + 1]))
	if staff_bonus_earned > 0:
		reward_lines.append(GameLocale.text("DAY_RESULT_STAFF_BONUS", [staff_bonus_earned]))
	if staff_wakes > 0:
		reward_lines.append(GameLocale.text("DAY_RESULT_STAFF_WAKES", [staff_wakes]))
	if staff_rescues > 0:
		reward_lines.append(GameLocale.text("DAY_RESULT_STAFF_RESCUES", [staff_rescues]))
	if not contract_result.is_empty():
		if bool(contract_result["success"]):
			reward_lines.append(GameLocale.text("DAY_RESULT_CONTRACT_SUCCESS", [
				int(contract_result["inspiration"]), int(contract_result["refund"])]))
		else:
			reward_lines.append(GameLocale.text("DAY_RESULT_CONTRACT_FAILED", [int(contract_result["cost"])]))
	rewards.text = "  ·  ".join(reward_lines) if not reward_lines.is_empty() else GameLocale.text("DAY_RESULT_NO_REWARDS")
	rewards.add_theme_font_size_override("font_size", 16)
	v.add_child(rewards)
	var unlocks := GameData.newly_unlocked(GameState.day + 1)
	if not unlocks.is_empty():
		var u := Label.new()
		u.text = GameLocale.text("DAY_RESULT_UNLOCKS", [GameLocale.text("LIST_SEPARATOR").join(unlocks)])
		u.add_theme_color_override("font_color", Color("D99A43"))
		v.add_child(u)
	var upgrade_hint := Label.new()
	upgrade_hint.text = GameLocale.text("DAY_RESULT_ENDLESS_HINT", [
		GameState.coins, EndlessContracts.rank_name(), int(GameState.endless.get("stamps", 0))]) \
		if GameState.day >= 15 else GameLocale.text("DAY_RESULT_UPGRADE_HINT", [GameState.coins])
	upgrade_hint.add_theme_color_override("font_color", Color("27B9A7"))
	v.add_child(upgrade_hint)
	var next := Button.new()
	next.text = GameLocale.text("DAY_RESULT_TO_LAB")
	next.custom_minimum_size = Vector2(0, 52)
	next.pressed.connect(_go_night)
	v.add_child(next)
	overlay.add_child(panel)
	overlay.visible = true
	# 顾客扫场会释放持焦点的订单卡按钮；结算按钮必须立即接管焦点，
	# 否则手柄/键盘在打烊面板上死路（评审 R3-F1）。
	next.grab_focus()


func _result_metric(parent: HBoxContainer, icon_texture: Texture2D, label_text: String,
		value_text: String, detail_text: String) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(216, 108)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.96, 0.94, 0.89, 0.92)
	card_style.set_corner_radius_all(12)
	card_style.set_border_width_all(1)
	card_style.border_color = Color(0.19, 0.13, 0.11, 0.15)
	card_style.content_margin_left = 12
	card_style.content_margin_right = 12
	card_style.content_margin_top = 9
	card_style.content_margin_bottom = 9
	card.add_theme_stylebox_override("panel", card_style)
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 1)
	row.add_child(copy)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 15)
	label.modulate = Color(0.19, 0.13, 0.11, 0.66)
	copy.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 24)
	copy.add_child(value)
	var detail := Label.new()
	detail.text = detail_text
	detail.add_theme_font_size_override("font_size", 14)
	detail.modulate = Color(0.19, 0.13, 0.11, 0.62)
	copy.add_child(detail)


func _build_finance_ledger(parent: VBoxContainer, gross: int, wage_paid: int,
		ledger: Dictionary, net_operating: int) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.73, 0.65, 0.10)
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(0.15, 0.73, 0.65, 0.42)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	card.add_child(stack)
	var title := Label.new()
	title.text = GameLocale.text("DAY_LEDGER_TITLE")
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("168C80"))
	stack.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	stack.add_child(row)
	_ledger_metric(row, GameLocale.text("DAY_LEDGER_GROSS"), gross, true)
	_ledger_metric(row, GameLocale.text("DAY_LEDGER_STOCK"), int(ledger["stock_paid"]), false)
	_ledger_metric(row, GameLocale.text("DAY_LEDGER_WAGE"), wage_paid, false)
	_ledger_metric(row, GameLocale.text("DAY_LEDGER_RENT"), int(ledger["rent_paid"]), false)
	_ledger_metric(row, GameLocale.text("DAY_LEDGER_NET"), net_operating, true)
	var note := Label.new()
	note.add_theme_font_size_override("font_size", 13)
	note.modulate = Color(0.19, 0.13, 0.11, 0.68)
	note.text = GameLocale.text("DAY_LEDGER_NEXT_RENT", [
		int(ledger["next_rent_day"]), int(ledger["next_rent_base"])])
	if int(ledger["waste_due"]) > 0:
		note.text += GameLocale.text("DAY_LEDGER_WASTE", [int(ledger["waste_due"])])
	if int(ledger["relief"]) > 0:
		note.text += GameLocale.text("DAY_LEDGER_RELIEF", [int(ledger["relief"])])
	stack.add_child(note)


func _ledger_metric(parent: HBoxContainer, label_text: String, amount: int, positive: bool) -> void:
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(copy)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = Color(0.19, 0.13, 0.11, 0.68)
	copy.add_child(label)
	var value := Label.new()
	value.text = "—" if amount == 0 else "%s%d" % ["+" if positive and amount > 0 else "-", abs(amount)]
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color("168C80") if positive and amount >= 0 else Color("C85B52"))
	copy.add_child(value)


func _go_night() -> void:
	get_tree().change_scene_to_file("res://scenes/night_lab/night_lab.tscn")


# ---------------------------------------------------------------- HUD 与反馈

func _update_info() -> void:
	# HUD 展示值全部由这组输入派生；输入不变时跳过十多次本地化格式化
	# 与主题覆盖，逐帧只在倒计时秒数真正变化时才重建文本。
	var inputs := [
		GameState.day, int(time_left), earned, goal, GameState.coins, stock_cost,
		GameState.inspiration, perfect, streak, angry, best_streak,
		route_trigger_count, route_bonus_earned, LegacyRoutes.active_id(),
		UpgradeCatalog.total_levels(), active_contract.get("id", ""),
	]
	if inputs == _info_inputs:
		return
	_info_inputs = inputs
	hud_day.text = GameLocale.text("DAY_HUD_TIME", [GameState.day, int(time_left)])
	hud_goal_text.text = GameLocale.text("DAY_HUD_GOAL", [earned, goal, int(goal * STAR_GOAL_MULT)])
	hud_goal_bar.value = clampf(float(earned) / maxf(float(goal), 1.0) * 100.0, 0.0, STAR_GOAL_MULT * 100.0)
	hud_coin.text = "%d" % GameState.coins
	var rent_today := OperatingCosts.rent_base(GameState.day)
	hud_cost.text = GameLocale.text("DAY_HUD_COSTS_TODAY", [stock_cost, rent_today]) if rent_today > 0 \
		else GameLocale.text("DAY_HUD_COSTS_NEXT", [stock_cost, OperatingCosts.next_rent_day(GameState.day)])
	hud_insp.text = "%d" % GameState.inspiration
	hud_perfect.text = GameLocale.text("DAY_HUD_PERFECT", [perfect])
	hud_streak.text = "x%d" % streak
	hud_streak.get_parent().get_parent().visible = true
	hud_streak.get_parent().get_parent().modulate.a = 1.0 if streak >= 2 else 0.48
	hud_upgrade.text = GameLocale.text("DAY_HUD_SHOP", [UpgradeCatalog.total_levels(), UpgradeCatalog.total_max_levels()])
	hud_event.add_theme_font_size_override("font_size", 12 if LegacyRoutes.is_active() else 14)
	hud_event.text = _event_hud_text()
	contract_pill.visible = not active_contract.is_empty()
	if contract_pill.visible:
		hud_contract.text = EndlessContracts.progress_text(active_contract, {
			"earned": earned, "perfect": perfect, "angry": angry, "best_streak": best_streak})


func _refresh_event_pill() -> void:
	var accent := Color(String(day_event.get("color", "27B9A7")))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.14)
	style.set_corner_radius_all(12)
	style.set_border_width_all(2)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.62)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	event_pill.add_theme_stylebox_override("panel", style)
	hud_event.add_theme_color_override("font_color", Color("30201D"))
	hud_event.text = _event_hud_text()
	if not active_contract.is_empty():
		var contract_accent := Color(String(active_contract.get("color", "FF6259")))
		var contract_style := StyleBoxFlat.new()
		contract_style.bg_color = Color(contract_accent.r, contract_accent.g, contract_accent.b, 0.16)
		contract_style.set_corner_radius_all(12)
		contract_style.set_border_width_all(2)
		contract_style.border_color = Color(contract_accent.r, contract_accent.g, contract_accent.b, 0.72)
		contract_style.content_margin_left = 9
		contract_style.content_margin_right = 9
		contract_style.content_margin_top = 4
		contract_style.content_margin_bottom = 4
		contract_pill.add_theme_stylebox_override("panel", contract_style)


func _event_hud_text() -> String:
	var event_text := String(day_event.get("hud_name", day_event.get("name", GameLocale.text("EVENT_CALM_HUD"))))
	if LegacyRoutes.is_active():
		return "%s\n%s" % [
			GameLocale.text("DAY_HUD_ROUTE", [event_text, String(LegacyRoutes.route().get("short_name", ""))]),
			LegacyRoutes.progress_text(streak, route_trigger_count, route_bonus_earned),
		]
	return event_text


func _flash(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	feedback_label.add_theme_constant_override("outline_size", 6)
	feedback_label.modulate.a = 1.0
	# 上一条闪现的补间必须先杀掉，否则新消息会被旧时间表提前淡出。
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.9)
	_flash_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.6)


func _fly_coin(text: String, from_pos: Vector2) -> void:
	if GameState.reduced_motion():
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.modulate = Color.GOLD
	lbl.position = from_pos
	ui_frame.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", _window_to_frame(coin_pill.global_position) + Vector2(20, 0), 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(lbl.queue_free)


## 3D 舞台铺满整个视口，而 HUD 位于 SafeFrame 的作者坐标系（非 1280×720
## 视口或存在安全区时二者不重合）。此函数把视口/窗口坐标换算回 SafeFrame
## 局部坐标，保证跟随元素在任何窗口尺寸与移动端安全区下都对齐。
func _window_to_frame(window_pos: Vector2) -> Vector2:
	return ui_frame.get_global_transform().affine_inverse() * window_pos


## 连击是核心技巧回报；每次 +1 让 HUD 药丸弹一下，x3 的时刻不再只是一段子串。
func _pulse_streak_pill() -> void:
	if GameState.reduced_motion():
		return
	var pill := hud_streak.get_parent().get_parent() as Control
	if pill == null:
		return
	if _streak_tween != null and _streak_tween.is_valid():
		_streak_tween.kill()
	pill.scale = Vector2.ONE * 1.0
	_streak_tween = create_tween()
	_streak_tween.tween_property(pill, "scale", Vector2.ONE * 1.22, 0.09)
	_streak_tween.tween_property(pill, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _punch(offset: Vector2) -> void:
	if GameState.reduced_motion():
		return
	var tw := create_tween()
	tw.tween_property(self, "position", offset, 0.05)
	tw.tween_property(self, "position", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BOUNCE)
