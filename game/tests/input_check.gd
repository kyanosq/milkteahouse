## 手柄、提示切换、焦点可见性与超宽安全框回归。
extends Node

const SafeFrameScene := preload("res://ui/safe_frame.gd")
const ShakeGestureDetector := preload("res://input/shake_gesture.gd")
const AppTheme := preload("res://ui/app_theme.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.test_mode = true
	GameState.menu = []
	GameState.featured_menu = []
	GameState.day = 1
	GameState.tutorial_completed = true
	GameState.staff = {}
	GameState.settings = {"sfx_volume": 0.0, "music_volume": 0.0, "reduced_motion": true, "haptics": true}
	GameLocale.set_locale("zh_CN", false)

	for action_name in ["game_pause", "game_shake", "staff_interact", "prep_tea", "prep_pearl"]:
		assert(InputMap.has_action(action_name), "缺少输入动作：%s" % action_name)
	var slow_mouse := ShakeGestureDetector.new()
	assert(not slow_mouse.sample_mouse(Vector2(24, 0), Vector2(520, 0), 100))
	assert(not slow_mouse.sample_mouse(Vector2(-24, 0), Vector2(-520, 0), 180),
		"slow horizontal cursor movement must never count as a shake")
	var mouse_gesture := ShakeGestureDetector.new()
	assert(not mouse_gesture.sample_mouse(Vector2(24, 1), Vector2(1300, 40), 100))
	assert(not mouse_gesture.sample_mouse(Vector2(1, 24), Vector2(40, 1300), 130),
		"vertical cursor movement must never count as a shake")
	assert(mouse_gesture.sample_mouse(Vector2(-24, 0), Vector2(-1300, 20), 180),
		"fast horizontal reversal must count once")
	assert(not mouse_gesture.sample_mouse(Vector2(24, 0), Vector2(1300, 20), 220),
		"mouse reversals inside cooldown must coalesce")
	assert(not mouse_gesture.sample_mouse(Vector2(-24, 0), Vector2(-1300, 20), 900),
		"a stale stroke must only re-arm the detector")
	var device_gesture := ShakeGestureDetector.new()
	assert(not device_gesture.sample_accelerometer(Vector3(0, -9.8, 0), 100),
		"first sensor sample must calibrate gravity")
	assert(device_gesture.sample_accelerometer(Vector3(10, -2, 0), 180),
		"a real acceleration impulse must count")
	assert(not device_gesture.sample_accelerometer(Vector3(-10, 2, 0), 230),
		"sensor impulses inside cooldown must coalesce")
	assert(device_gesture.sample_accelerometer(Vector3(10, -2, 0), 350),
		"a later opposite impulse must count")
	assert(InputPrompts.detect_controller_family("Xbox Wireless Controller", "__XINPUT_DEVICE__") == "xbox")
	assert(InputPrompts.detect_controller_family("DualSense Wireless Controller", "", {"vendor_id": 0x054C}) == "playstation")
	assert(InputPrompts.detect_controller_family("Nintendo Switch Pro Controller", "", {"vendor_id": 0x057E}) == "nintendo")
	assert(InputPrompts.detect_controller_family("Arcade Controller") == "generic")
	InputPrompts.set_test_controller_family("xbox")
	assert(InputPrompts.accept_hint() == "A")
	assert(InputPrompts.cancel_hint() == "B")
	assert(InputPrompts.shake_hint() == "X")
	assert(InputPrompts.staff_hint() == "Y")
	assert(InputPrompts.prep_tea_hint() == "LB" and InputPrompts.prep_pearl_hint() == "RB")
	assert(InputPrompts.pause_hint() == "Menu")
	InputPrompts.set_test_controller_family("playstation")
	assert(InputPrompts.accept_hint() == "×" and InputPrompts.cancel_hint() == "○")
	assert(InputPrompts.shake_hint() == "□" and InputPrompts.staff_hint() == "△")
	assert(InputPrompts.prep_tea_hint() == "L1" and InputPrompts.prep_pearl_hint() == "R1")
	assert(InputPrompts.pause_hint() == "Options")
	InputPrompts.set_test_controller_family("nintendo")
	assert(InputPrompts.accept_hint() == "B" and InputPrompts.cancel_hint() == "A")
	assert(InputPrompts.shake_hint() == "Y" and InputPrompts.staff_hint() == "X")
	assert(InputPrompts.prep_tea_hint() == "L" and InputPrompts.prep_pearl_hint() == "R")
	assert(InputPrompts.pause_hint() == "+")
	InputPrompts.set_test_controller_family("generic")
	assert(InputPrompts.accept_hint() == "South" and InputPrompts.cancel_hint() == "East")
	assert(InputPrompts.shake_hint() == "West" and InputPrompts.staff_hint() == "North")
	assert(InputPrompts.pause_hint() == "Start")
	InputPrompts.set_test_controller_family("xbox")

	# SafeFrame must center authored UI while leaving its scene background full-bleed.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 720)
	add_child(viewport)
	var frame: SafeFrame = SafeFrameScene.new()
	viewport.add_child(frame)
	await get_tree().process_frame
	assert(frame.position == Vector2(320, 0))
	viewport.size = Vector2i(1280, 800)
	await get_tree().process_frame
	assert(frame.position == Vector2(0, 40))
	var inset_layout := frame._fit_layout(Vector2(1280, 720), Rect2(64, 20, 1152, 680))
	assert(is_equal_approx(float(inset_layout["scale"]), 0.9),
		"safe-area cutouts must scale the authored frame to fit")
	assert(inset_layout["position"] == Vector2(64, 36),
		"safe-area frame must remain centered between cutout and home indicator")
	viewport.size = Vector2i(1280, 720)
	await get_tree().process_frame
	frame.position = inset_layout["position"]
	frame.scale = Vector2.ONE * float(inset_layout["scale"])
	var modal_probe := Control.new()
	frame.add_child(modal_probe)
	var modal_geometry := SafeFrame.overscan_geometry(modal_probe)
	assert((frame.position - modal_geometry["offset"] * frame.scale).is_equal_approx(Vector2.ZERO))
	assert((modal_geometry["size"] * frame.scale).is_equal_approx(Vector2(1280, 720)),
		"safe-area scaling must not shrink full-viewport modal scrims")
	viewport.queue_free()

	# 夜间货架必须按 SafeFrame 作者宽度（而非裸视口）预算缩放：宽于 16:9 的
	# 视口下，按视口预算会让货架保持 1.0 溢出安全框（评审 R11-S3）。
	var prev_day := GameState.day
	GameState.day = 9
	var wide_viewport := SubViewport.new()
	wide_viewport.size = Vector2i(1558, 720)
	add_child(wide_viewport)
	var night_lab_wide: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	wide_viewport.add_child(night_lab_wide)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(night_lab_wide._shelf.size.x > SafeFrame.AUTHORED_SIZE.x - night_lab_wide._shelf.position.x * 2.0,
		"day-9 shelf must overflow the authored budget for this test to discriminate")
	assert(night_lab_wide._shelf.scale.x < 1.0,
		"the shelf must scale to the SafeFrame width even on wider-than-16:9 viewports")
	assert(night_lab_wide._shelf.scale.x * night_lab_wide._shelf.size.x
		<= SafeFrame.AUTHORED_SIZE.x - night_lab_wide._shelf.position.x * 2.0 + 0.5,
		"the scaled shelf must stay inside the authored frame")
	night_lab_wide.queue_free()
	wide_viewport.queue_free()
	await get_tree().process_frame
	GameState.day = prev_day

	var shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	var root_size: Vector2 = shop.get_viewport_rect().size
	var expected_root_offset := Vector2(maxf((root_size.x - 1280.0) * 0.5, 0.0),
		maxf((root_size.y - 720.0) * 0.5, 0.0)).floor()
	assert(shop.ui_frame.position == expected_root_offset)
	# 跟随元素（摇杯条、金币飞行）必须把窗口坐标换算回 SafeFrame 局部坐标，
	# 否则超宽/安全区偏移下会错位到作者框架之外。
	var probe_window := Vector2(960.0, 360.0)
	shop.ui_frame.position = Vector2(320, 0)
	await get_tree().process_frame
	assert(shop._window_to_frame(probe_window) == Vector2(640, 360),
		"window→frame conversion must apply the safe-frame offset")
	shop.ui_frame.scale = Vector2.ONE * 0.5
	await get_tree().process_frame
	assert(shop._window_to_frame(probe_window) == Vector2(1280, 720),
		"window→frame conversion must invert safe-frame scaling")
	shop.ui_frame.position = Vector2.ZERO
	shop.ui_frame.scale = Vector2.ONE
	await get_tree().process_frame
	assert(not shop._context_shortcuts[0].text.begins_with("1"))
	var focus_style := shop._context_shortcuts[0].get_theme_stylebox("focus") as StyleBoxFlat
	assert(focus_style != null and focus_style.get_border_width(SIDE_LEFT) == 4)
	assert(focus_style.border_color == AppTheme.COCOA,
		"default focus needs a high-contrast cocoa ring against coral")
	assert(shop.theme.get_color("font_color", "Button") == AppTheme.COCOA,
		"default coral buttons need readable cocoa copy")
	assert(get_viewport().gui_get_focus_owner() == shop._context_shortcuts[0])
	assert(shop.stage.visible_prop_label_ids() == [String(GameData.bases[0]["id"])])
	var prep_tea := InputEventAction.new()
	prep_tea.action = "prep_tea"
	prep_tea.pressed = true
	shop._input(prep_tea)
	assert(shop.tea_batch.active)
	var prep_pearl := InputEventAction.new()
	prep_pearl.action = "prep_pearl"
	prep_pearl.pressed = true
	shop._input(prep_pearl)
	assert(shop.pearl_batch.active)
	var navigate := InputEventAction.new()
	navigate.action = "ui_right"
	navigate.pressed = true
	Input.parse_input_event(navigate)
	await get_tree().process_frame
	assert(get_viewport().gui_get_focus_owner() == shop._context_shortcuts[1])
	assert(shop.stage.visible_prop_label_ids() == [String(GameData.bases[1]["id"])])

	# Switching back to keyboard restores the numbered efficiency shortcuts.
	var keyboard := InputEventKey.new()
	keyboard.keycode = KEY_K
	keyboard.pressed = true
	InputPrompts._input(keyboard)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(not InputPrompts.gamepad_mode)
	assert(shop._context_shortcuts[0].text.begins_with("1"))
	shop._context_shortcuts[0].release_focus()
	await get_tree().process_frame
	assert(shop.stage.visible_prop_label_ids().is_empty())

	var joy_scheme := InputEventJoypadButton.new()
	joy_scheme.button_index = JOY_BUTTON_A
	joy_scheme.pressed = true
	InputPrompts._input(joy_scheme)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(InputPrompts.gamepad_mode)
	assert(not shop._context_shortcuts[0].text.begins_with("1"))

	# The active order compares against the current cup without marking the correct
	# choice buttons. Wrong selections turn only the target slots red; corrections
	# settle into a complete mint checklist.
	if shop.active_customer == null:
		shop._spawn_customer()
	var progress_customer: Dictionary = shop.active_customer
	var stable_context_button: Button = shop._context_shortcuts[0]
	shop._set_active_customer(progress_customer)
	await get_tree().process_frame
	assert(shop._context_shortcuts[0] == stable_context_button,
		"reselecting the active order must not rebuild controls or schedule a focus loop")
	progress_customer["order"] = {
		"base": GameData.bases[0], "milk": GameData.milks[0],
		"tops": [GameData.toppings[0]], "sugar": GameData.sugar_levels[2],
	}
	shop._render_order_card(progress_customer)
	shop._reset_cup()
	Haptics.reset_test_state()
	assert(shop.order_progress_states(progress_customer) == ["pending", "pending", "pending", "pending"])
	shop._on_base(GameData.bases[1])
	assert(shop.order_progress_states(progress_customer)[0] == "wrong")
	assert(progress_customer["order_progress"].text.begins_with("!"))
	shop._on_base(GameData.bases[0])
	assert(shop.cup_corrections == 1)
	assert(shop.status_label.text.contains(GameLocale.text("DAY_CUP_REWORKED", [1])))
	shop._on_milk(GameData.milks[0])
	shop._on_topping(GameData.toppings[0])
	shop._on_sugar(GameData.sugar_levels[2])
	assert(Haptics.event_count("tap") == 1, "same-frame ingredient taps must be rate limited")
	assert(Haptics.test_events[0]["input_mode"] == "gamepad")
	assert(shop.order_progress_states(progress_customer) == ["match", "match", "match", "match"])
	assert(progress_customer["order_progress"].text == "✓ 4/4")
	progress_customer["order"]["tops"] = []
	shop._render_order_card(progress_customer)
	shop._update_all_order_progress()
	assert(progress_customer["order_progress"].text.begins_with("!"), "extra topping must keep the order incomplete")
	progress_customer["order"]["tops"] = [GameData.toppings[0]]
	shop._render_order_card(progress_customer)
	shop._update_all_order_progress()
	assert(progress_customer["order_progress"].text == "✓ 4/4")

	shop._on_base(GameData.bases[0])
	shop._on_milk(GameData.milks[0])
	shop._on_sugar(GameData.sugar_levels[2])
	InputPrompts.set_test_gamepad_mode(false)
	assert(shop._shake_next_action_text(true) == GameLocale.text("DAY_NEXT_SHAKE_MOBILE", [0, shop._shakes_needed()]),
		"mobile action copy must not expose the desktop shortcut")
	assert(shop._shake_button_text(true) == GameLocale.text("DAY_SHAKE_BUTTON_MOBILE", [0, shop._shakes_needed()]))
	InputPrompts.set_test_gamepad_mode(true)
	var gesture_before: float = shop.shake_progress
	var mouse_right := InputEventMouseMotion.new()
	mouse_right.relative = Vector2(28, 0)
	mouse_right.velocity = Vector2(1400, 0)
	shop._input(mouse_right)
	assert(shop.shake_progress == gesture_before, "first mouse flick only arms the gesture")
	var mouse_left := InputEventMouseMotion.new()
	mouse_left.relative = Vector2(-28, 0)
	mouse_left.velocity = Vector2(-1400, 0)
	shop._input(mouse_left)
	assert(shop.shake_progress == gesture_before + 1.0, "mouse reversal must advance the real cup")
	Haptics.reset_test_state()
	var shake_event := InputEventJoypadButton.new()
	shake_event.button_index = JOY_BUTTON_X
	shake_event.pressed = true
	assert(shake_event.is_action_pressed("game_shake"))
	var before_shake: float = shop.shake_progress
	shop._input(shake_event)
	assert(shop.shake_progress == before_shake + 1.0)
	while shop.customers.size() < 2:
		shop._spawn_customer()
	var review_customer: Dictionary = shop.customers[1]
	while not shop.cup_sealed:
		shop._on_shake()
	assert(Haptics.event_count("shake") == 1, "rapid shake taps must coalesce")
	assert(Haptics.event_count("confirm") == 1, "seal completion needs a distinct confirmation pulse")
	assert(progress_customer["hint"].text == GameLocale.text("DAY_ORDER_DELIVER_GAMEPAD", [InputPrompts.accept_hint()]),
		"sealed order cards must describe the A-button delivery action")
	assert(review_customer["hint"].text == GameLocale.text("DAY_ORDER_REVIEW_GAMEPAD"),
		"inactive sealed cards must advertise review rather than immediate delivery")
	var order_focus_style := progress_customer["btn"].get_theme_stylebox("focus") as StyleBoxFlat
	assert(order_focus_style != null and not order_focus_style.draw_center)
	assert(order_focus_style.get_border_width(SIDE_LEFT) == 4)
	assert(order_focus_style.border_color == AppTheme.COCOA,
		"order cards need the same high-contrast focus language as other controls")
	assert(not progress_customer["btn"].tooltip_text.is_empty(),
		"transparent order-card buttons need a semantic text alternative")
	assert(not progress_customer["btn"].accessibility_name.is_empty())
	assert(progress_customer["btn"].accessibility_description.contains("·"),
		"order-card accessibility description must expose the complete formula")
	# Review another order before the seal's deferred focus request drains. Every
	# queued request must resolve the latest active card instead of oscillating
	# between stale concrete buttons and exhausting the rendered message queue.
	shop._on_order_card_pressed(review_customer)
	for focus_frame in 3:
		await get_tree().process_frame
	assert(not shop.context_panel.visible, "sealed cup must hand visual focus back to the order cards")
	assert(shop.active_customer == review_customer)
	assert(get_viewport().gui_get_focus_owner() == review_customer["btn"])
	progress_customer["btn"].grab_focus()
	await get_tree().process_frame
	review_customer["btn"].grab_focus()
	await get_tree().process_frame
	assert(shop.active_customer == review_customer)
	assert(shop.cup_sealed, "moving gamepad focus must only review the order")
	assert(review_customer["hint"].text == GameLocale.text("DAY_ORDER_DELIVER_GAMEPAD", [InputPrompts.accept_hint()]))
	assert(progress_customer["hint"].text == GameLocale.text("DAY_ORDER_REVIEW_GAMEPAD"))
	progress_customer["btn"].grab_focus()
	await get_tree().process_frame
	assert(shop.active_customer == progress_customer)
	InputPrompts.set_test_gamepad_mode(false)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(progress_customer["hint"].text == GameLocale.text("DAY_ORDER_DELIVER_POINTER"),
		"sealed order cards must update when the input scheme changes")
	assert(review_customer["hint"].text == GameLocale.text("DAY_ORDER_REVIEW_POINTER"))
	shop._on_order_card_pressed(review_customer)
	assert(shop.active_customer == review_customer)
	assert(shop.cup_sealed, "first pointer press on another order must review without delivering")
	assert(review_customer["hint"].text == GameLocale.text("DAY_ORDER_DELIVER_POINTER"))
	var first_order_shortcut := InputEventKey.new()
	first_order_shortcut.keycode = KEY_1
	first_order_shortcut.pressed = true
	shop._input(first_order_shortcut)
	assert(shop.active_customer == progress_customer)
	assert(shop.cup_sealed, "first number-key press on another order must review without delivering")
	shop._reset_cup()
	assert(shop.context_panel.visible, "new cup must restore the preparation controls")
	assert(shop.cup_corrections == 0)
	assert(progress_customer["hint"].text == GameLocale.text("ORDER_HINT_DEFAULT"),
		"resetting the cup must restore the customer-specific order hint")
	shop._on_base(GameData.bases[1])
	shop._on_milk(GameData.milks[0])
	shop._on_topping(GameData.toppings[0])
	shop._on_sugar(GameData.sugar_levels[2])
	while not shop.cup_sealed:
		shop._on_shake()
	assert(progress_customer["order_progress"].text.begins_with("!"))
	assert(progress_customer["hint"].text == GameLocale.text("DAY_ORDER_DELIVER_POINTER"),
		"a sealed wrong cup still needs an honest delivery action hint")
	# 暂停/结算期间，焦点驱动的订单按键必须被拒绝：语言或设备方案切换可能把
	# 焦点偷到被遮挡的订单卡上，A 键不得在暂停中送杯（评审 R3-F2）。
	var served_before_paused_press: int = shop.served
	var focus_owner_before_pause := get_viewport().gui_get_focus_owner()
	shop.running = false
	shop._on_order_card_pressed(progress_customer)
	assert(shop.served == served_before_paused_press,
		"order-card presses outside a running shift must be inert")
	shop._on_reset_cup_pressed()
	assert(shop._cup_has_contents(), "reset must be inert while the shift is paused")
	shop._focus_active_order()
	assert(get_viewport().gui_get_focus_owner() == focus_owner_before_pause,
		"deferred focus must not move while the shift is paused")
	shop.running = true
	var patience_before_wrong_delivery: float = progress_customer["patience"]
	shop._on_order_card_pressed(progress_customer)
	assert(Haptics.event_count("warning") >= 1, "wrong delivery must emit warning haptics")
	assert(not shop.cup_sealed, "confirming the reviewed order must perform delivery")
	assert(float(progress_customer["patience"]) < patience_before_wrong_delivery,
		"a deliberately wrong confirmed delivery must keep its gameplay consequence")
	assert(progress_customer["hint"].text == GameLocale.text("ORDER_HINT_DEFAULT"))
	InputPrompts.set_test_gamepad_mode(true)
	await get_tree().process_frame
	await get_tree().process_frame

	while shop.customers.size() < 2:
		shop._spawn_customer()
	var second_customer: Dictionary = shop.customers[1]
	second_customer["btn"].grab_focus()
	await get_tree().process_frame
	assert(shop.active_customer == second_customer)

	InputPrompts.set_test_controller_family("playstation")
	await get_tree().process_frame
	await get_tree().process_frame
	var pause_event := InputEventJoypadButton.new()
	pause_event.button_index = JOY_BUTTON_START
	pause_event.pressed = true
	assert(pause_event.is_action_pressed("game_pause"))
	shop._input(pause_event)
	assert(get_tree().paused)
	assert(shop.pause_panel._controls.text.contains("× 确认"))
	assert(shop.pause_panel._controls.text.contains("□ 摇茶"))
	assert(shop.pause_panel._controls.text.contains("Options 暂停"))
	shop._resume_from_pause()
	assert(not get_tree().paused)

	InputPrompts.set_test_controller_family("nintendo")
	shop._show_tutorial(true)
	# 本段只验证提示字形切换；门控行为由 onboarding_check 覆盖。
	shop.tutorial_overlay._gate_bypassed = true
	assert(shop.tutorial_overlay._hint.text.contains("手柄"))
	assert(shop.tutorial_overlay._hint.text.contains("B"))
	shop.tutorial_overlay._advance()
	assert(shop.tutorial_overlay._hint.text.contains("L") and shop.tutorial_overlay._hint.text.contains("R"))
	shop.tutorial_overlay._advance()
	shop.tutorial_overlay._advance()
	assert(shop.tutorial_overlay._hint.text.contains("Y 快速摇茶"))
	assert(shop.tutorial_overlay._hint.text.contains("B 交付"))
	shop.tutorial_overlay._finish()
	InputPrompts.set_test_controller_family("xbox")

	# ---- 教学 _next 焦点不被同帧延迟 grab 偷走（P3-F4）----
	shop._reset_cup()
	shop._show_tutorial(true)
	for focus_frame in 5:
		await get_tree().process_frame
	var tutorial_focus := get_viewport().gui_get_focus_owner() as Control
	assert(tutorial_focus != null and shop.tutorial_overlay.is_ancestor_of(tutorial_focus),
		"tutorial focus must stay on the overlay while deferred context grabs drain")
	# 聚光灯真开洞（P12-F2）：聚焦区中心不被任何暗幕覆盖（透出原始场景对比度），
	# 洞外仍被暗层盖住；进度文字不再用 2.3:1 的 MINT。
	var hole_center: Vector2 = shop.tutorial_overlay._focus.position \
		+ shop.tutorial_overlay._focus.size * 0.5
	assert(not shop.tutorial_overlay.hole_covers_point(hole_center),
		"the spotlight must punch a real hole through the dim layer")
	assert(shop.tutorial_overlay.hole_covers_point(Vector2(8, 700)),
		"the dim layer must still cover regions outside the spotlight")
	assert(shop.tutorial_overlay._progress.get_theme_color("font_color") == AppTheme.COCOA,
		"tutorial progress copy needs full-contrast cocoa, not 2.3:1 mint")
	shop.tutorial_overlay._finish()

	# ---- 耐心秒数三档色对比（P12-F1）：16px 常规字需 ≥4.5:1 ----
	for band_color in shop.PATIENCE_BAND_COLORS:
		assert(_contrast_ratio(band_color, Color(1.0, 0.973, 0.929)) >= 4.5,
			"patience band color must reach 4.5:1 on the order card background: %s" % band_color.to_html())

	# ---- 触屏文案与触控目标（P10-4 / P10-1）----
	InputPrompts.set_test_gamepad_mode(false)
	assert(shop._context_button_label(1, "Assam") == "1  Assam")
	assert(shop._context_button_label(1, "Assam", true) == "Assam",
		"touch context buttons must not leak the keyboard number prefix")
	assert(shop.tutorial_overlay._device_hint(2, "x", true) == GameLocale.text("TUTORIAL_3_HINT_TOUCH"))
	assert(shop.tutorial_overlay._device_hint(3, "x", true) == GameLocale.text("TUTORIAL_SHAKE_HINT_TOUCH"))
	shop.pause_panel._update_controls_copy(true)
	assert(shop.pause_panel._controls.text == GameLocale.text("SETTINGS_CONTROLS_DAY_TOUCH"),
		"touch devices must not see Q/E/Space/F/Esc keyboard copy in the pause panel")
	assert(shop._context_button_height(true) * 0.542 >= 44.0,
		"mobile primary buttons must keep >=44pt at the worst-phone SafeFrame scale")
	assert(shop._context_button_height(false) == 54.0, "desktop context buttons stay unchanged")
	InputPrompts.set_test_gamepad_mode(true)

	# ---- 离场自动晋升的新队首先核对再交付（P11-F1）----
	while shop.customers.size() < 2:
		shop._spawn_customer()
	var leaving_head: Dictionary = shop.active_customer
	var promoted_head: Dictionary = shop.customers[1] if shop.customers[0] == leaving_head else shop.customers[0]
	shop.cup_base = promoted_head["order"]["base"]
	shop.cup_milk = promoted_head["order"]["milk"]
	shop.cup_tops = promoted_head["order"]["tops"].duplicate()
	shop.cup_sugar = promoted_head["order"]["sugar"]
	shop.sugar_confirmed = true
	shop.cup_sealed = true
	shop._remove_customer(leaving_head, true)
	assert(shop.active_customer == promoted_head)
	assert(shop._promoted_needs_review == promoted_head,
		"an auto-promoted head must be flagged for review while a cup is sealed")
	var served_before_promotion: int = shop.served
	shop._on_order_card_pressed(promoted_head)
	assert(shop.served == served_before_promotion,
		"the first press on an auto-promoted head must review, not deliver")
	shop._on_order_card_pressed(promoted_head)
	assert(shop.served == served_before_promotion + 1,
		"the second press must deliver the reviewed cup")

	# ---- 减弱动态开启后存量动画停（P12-F3）：舞台演员重建为静态 ----
	var stale_actors: Array = []
	for c in shop.customers:
		stale_actors.append(c["node"])
	GameState.settings["reduced_motion"] = true
	shop._on_reduced_motion_toggled(true)
	assert(shop.customers.size() == stale_actors.size())
	for i in shop.customers.size():
		assert(shop.customers[i]["node"] != stale_actors[i],
			"enabling reduced motion must rebuild live actors so idle loops stop")
		assert(float(shop.customers[i]["node"].get_node("BobRoot").position.y) == 0.0,
			"rebuilt actors must be placed statically with no bob loop")

	# ---- 日间暂停面板圈禁（P3-F6）：逃逸后的 D-pad 不落遮罩下控件 ----
	shop._toggle_pause()
	assert(get_tree().paused and shop.pause_panel.visible)
	shop._context_shortcuts[0].grab_focus()
	await get_tree().process_frame
	var pause_nav := InputEventAction.new()
	pause_nav.action = "ui_down"
	pause_nav.pressed = true
	Input.parse_input_event(pause_nav)
	await get_tree().process_frame
	var clamped_focus := get_viewport().gui_get_focus_owner() as Control
	assert(clamped_focus != null and shop.pause_panel.is_ancestor_of(clamped_focus),
		"ui_down with escaped focus must clamp back into the pause panel")
	shop._resume_from_pause()
	assert(not get_tree().paused)
	# 恢复后的焦点落点（P3-F10）：未封杯时回到制杯主线的情境按钮，
	# 而不是右上角的暂停按钮。
	await get_tree().process_frame
	assert(not shop.cup_sealed)
	assert(get_viewport().gui_get_focus_owner() == shop._context_shortcuts[0],
		"resuming with an unsealed cup must refocus the prep mainline, not the pause button")
	Sfx.stop_all()
	shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	# ---- 夜间模态面板：圈禁（P3-F1/F5）与购买/签约后焦点恢复（P3-F3）----
	# （日间店铺先释放：真实游戏里两场景不共存，店铺的合法延迟 grab
	# 不应与本节的焦点断言互相干扰。）
	var prev_day_for_night := GameState.day
	GameState.day = 16
	GameState.coins = 900
	GameState.endless = {"stamps": 0, "best_streak": 0, "completed": 0, "failed": 0}
	var night_lab: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(night_lab)
	await get_tree().process_frame
	await get_tree().process_frame

	var focus_inside_panel := func(panel: Control) -> bool:
		var owner_ctrl := get_viewport().gui_get_focus_owner() as Control
		return owner_ctrl != null and panel.is_ancestor_of(owner_ctrl)

	night_lab._open_upgrades()
	await get_tree().process_frame
	assert(night_lab.upgrade_panel.visible and focus_inside_panel.call(night_lab.upgrade_panel))
	var buy_button := _first_enabled_button(night_lab.upgrade_panel._cards)
	assert(buy_button != null, "day-16 upgrade panel must expose an affordable buy button")
	buy_button.grab_focus()
	var coins_before_buy := GameState.coins
	buy_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(GameState.coins < coins_before_buy, "the buy press must perform a real purchase")
	assert(focus_inside_panel.call(night_lab.upgrade_panel),
		"focus must return inside the upgrade panel after the purchase rebuilds cards")
	night_lab.upgrade_panel.hide_panel()

	night_lab._open_contracts()
	await get_tree().process_frame
	assert(night_lab.contract_panel.visible)
	var sign_button := _first_enabled_button(night_lab.contract_panel._cards)
	if sign_button != null:
		sign_button.grab_focus()
		sign_button.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		assert(focus_inside_panel.call(night_lab.contract_panel),
			"focus must return inside the contract panel after signing rebuilds cards")
	night_lab.contract_panel.hide_panel()
	GameState.endless = {"stamps": 0, "best_streak": 0, "completed": 0, "failed": 0}

	# 圈禁：焦点被偷到面板外的货架瓦片后，D-pad/A 不得改配方（P3-F1）。
	night_lab._open_upgrades()
	await get_tree().process_frame
	var sugar_before_escape: Variant = night_lab.cup_sugar
	night_lab._first_tile.grab_focus()
	await get_tree().process_frame
	var escaped_nav := InputEventAction.new()
	escaped_nav.action = "ui_down"
	escaped_nav.pressed = true
	Input.parse_input_event(escaped_nav)
	await get_tree().process_frame
	assert(focus_inside_panel.call(night_lab.upgrade_panel),
		"ui_down with escaped focus must clamp back into the modal panel")
	var escaped_accept := InputEventAction.new()
	escaped_accept.action = "ui_accept"
	escaped_accept.pressed = true
	Input.parse_input_event(escaped_accept)
	await get_tree().process_frame
	assert(night_lab.cup_sugar == sugar_before_escape,
		"A on an escaped-to shelf tile must not change the recipe while a panel is open")
	night_lab.upgrade_panel.hide_panel()
	await get_tree().process_frame

	# 族切换时面板打开的焦点偷逃（P3-F5）：切族后焦点仍在面板内。
	GameState.day = 9
	night_lab._open_staff()
	await get_tree().process_frame
	assert(night_lab.staff_panel.visible and focus_inside_panel.call(night_lab.staff_panel))
	InputPrompts.set_test_controller_family("playstation")
	await get_tree().process_frame
	await get_tree().process_frame
	assert(focus_inside_panel.call(night_lab.staff_panel),
		"a controller-family switch while a panel is open must not steal focus to the shelf")
	night_lab.staff_panel.hide_panel()
	GameState.day = prev_day_for_night
	night_lab.queue_free()
	await get_tree().process_frame
	InputPrompts.set_test_controller_family("xbox")

	print("[INPUT] passed actions=5 families=4 prep_shoulders=true device_glyphs=true focus_ring=4px safe=320x/40y+cutout mouse_gesture=true sensor_gate=true gamepad_shake=true haptics=true tutorial_focus=true spotlight_hole=true patience_contrast=true panel_confinement=true buy_refocus=true promotion_review=true reduced_motion_refresh=true")
	get_tree().quit()


## WCAG 2.x 相对亮度（P12-F1 断言用）。
func _relative_luminance(c: Color) -> float:
	var lin := func(channel: float) -> float:
		return channel / 12.92 if channel <= 0.04045 else pow((channel + 0.055) / 1.055, 2.4)
	return 0.2126 * lin.call(c.r) + 0.7152 * lin.call(c.g) + 0.0722 * lin.call(c.b)


func _contrast_ratio(a: Color, b: Color) -> float:
	var la := _relative_luminance(a)
	var lb := _relative_luminance(b)
	var lighter := maxf(la, lb)
	var darker := minf(la, lb)
	return (lighter + 0.05) / (darker + 0.05)


func _first_enabled_button(root: Node) -> Button:
	for child in root.get_children():
		if child is Button and not child.disabled and child.focus_mode != Control.FOCUS_NONE:
			return child
		var nested := _first_enabled_button(child)
		if nested != null:
			return nested
	return null
