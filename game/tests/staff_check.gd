## 招聘、三种双刃剑钩子、场景角色、拍醒互动、错杯保护与工资回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.settings = {"sfx_volume": 0.0, "music_volume": 0.0, "reduced_motion": true}
	GameState.reset_progress()
	GameState.day = 7
	GameState.coins = 300
	assert(not StaffCatalog.hire("xiaoman", false))
	GameState.day = 8
	assert(StaffCatalog.hire("xiaoman", false))
	assert(GameState.coins == 255)
	assert(StaffCatalog.wage() == 6)
	assert(is_equal_approx(StaffCatalog.waiting_drain_multiplier(true), 0.70))
	assert(is_equal_approx(StaffCatalog.waiting_drain_multiplier(false), 1.0))
	StaffCatalog.reveal_trait(false)
	assert(StaffCatalog.trait_revealed())
	assert(StaffCatalog.dismiss(false))
	assert(GameState.coins == 235)

	assert(StaffCatalog.hire("taozi", false))
	assert(is_equal_approx(StaffCatalog.patience_multiplier(), 1.20))
	assert(is_equal_approx(StaffCatalog.spawn_multiplier(), 0.88))
	GameState.staff = {}
	assert(StaffCatalog.hire("acheng", false))
	assert(StaffCatalog.extra_shakes() == 1)
	assert(StaffCatalog.quality_coin_bonus() == 2)
	GameState.staff = {}

	# 摸鱼事件必须真实进入可点击状态并能被拍醒。
	GameState.staff = StaffCatalog.candidate("xiaoman").duplicate(true)
	GameState.staff["trait_revealed"] = false
	GameState.staff["days_worked"] = 0
	var slacker_shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(slacker_shop)
	await get_tree().process_frame
	assert(String(slacker_shop.stage._staff_actor.get_meta("staff_model", "")) == "xiaoman")
	slacker_shop.staff_event_timer = 0.0
	slacker_shop._update_staff(0.1)
	assert(slacker_shop.staff_state == "idle")
	assert(StaffCatalog.trait_revealed())
	assert(not slacker_shop.staff_action_button.disabled)
	slacker_shop._on_staff_clicked()
	assert(slacker_shop.staff_state == "working")
	assert(slacker_shop.staff_wakes == 1)

	# 已揭示特质后，掉线前 3 秒必须有一次温和预警；预警只发一次，拍醒后重新武装。
	slacker_shop.staff_event_timer = 2.9
	slacker_shop._update_staff(0.2)
	assert(slacker_shop._slacker_warned, "3s pre-warning must arm within the warning window")
	assert(slacker_shop.feedback_label.text == GameLocale.text("DAY_STAFF_SLACKING_SOON",
		[GameLocale.staff_name(StaffCatalog.current()), InputPrompts.staff_hint()]),
		"pre-warning must flash the wake hint copy")
	assert(slacker_shop.staff_state == "working")
	slacker_shop._update_staff(0.2)
	assert(slacker_shop.feedback_label.text == GameLocale.text("DAY_STAFF_SLACKING_SOON",
		[GameLocale.staff_name(StaffCatalog.current()), InputPrompts.staff_hint()]),
		"the pre-warning must not repeat within one slacking cycle")
	slacker_shop.staff_event_timer = 0.0
	slacker_shop._update_staff(0.1)
	assert(slacker_shop.staff_state == "idle")
	slacker_shop._on_staff_clicked()
	assert(not slacker_shop._slacker_warned, "waking the staff must re-arm the pre-warning")
	slacker_shop.queue_free()
	await get_tree().process_frame

	# 强迫症每天拦下一次错杯；顾客、耐心与连击不受罚。
	GameState.staff = StaffCatalog.candidate("acheng").duplicate(true)
	GameState.staff["trait_revealed"] = true
	GameState.staff["days_worked"] = 0
	var guard_shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(guard_shop)
	await get_tree().process_frame
	assert(String(guard_shop.stage._staff_actor.get_meta("staff_model", "")) == "acheng")
	guard_shop._spawn_customer()
	var customer: Dictionary = guard_shop.customers[0]
	var order: Dictionary = customer["order"]
	guard_shop.cup_base = _different_base(order["base"])
	guard_shop.cup_milk = order["milk"]
	guard_shop.cup_tops = order["tops"].duplicate()
	guard_shop.cup_sugar = order["sugar"]
	guard_shop.cup_sealed = true
	var before_patience: float = customer["patience"]
	guard_shop._on_deliver(customer)
	assert(guard_shop.staff_guard_used)
	assert(guard_shop.staff_rescues == 1)
	assert(guard_shop.customers.has(customer))
	assert(is_equal_approx(float(customer["patience"]), before_patience))
	assert(guard_shop.angry == 0)
	guard_shop.queue_free()
	await get_tree().process_frame

	GameState.coins = 50
	var wage := StaffCatalog.charge_daily_wage()
	assert(wage["paid"] == 14)
	assert(wage["status"] == "paid")
	assert(GameState.coins == 36)
	assert(int(GameState.staff["days_worked"]) == 1)

	# 工资不足不再免费保留效果：实付后次日休整，后天自动复工且不滚存债务。
	GameState.day = 9
	GameState.coins = 5
	var short := StaffCatalog.charge_daily_wage()
	assert(short["status"] == "shortfall")
	assert(short["paid"] == 5 and short["due"] == 14 and short["shortfall"] == 9)
	assert(short["rest_day"] == 10)
	assert(GameState.coins == 0)
	assert(StaffCatalog.is_on_duty(9))
	assert(not StaffCatalog.is_on_duty(10))
	GameState.phase = "night"
	var staff_panel: StaffPanel = load("res://ui/staff_panel.gd").new()
	add_child(staff_panel)
	staff_panel.show_panel()
	assert(_find_label_contains(staff_panel, "第 10 天休整"))
	GameLocale.set_locale("en", false)
	assert(_find_label_contains(staff_panel, "Rest Day 10"))
	GameLocale.set_locale("zh_CN", false)
	staff_panel.queue_free()
	await get_tree().process_frame
	GameState.day = 10
	GameState.phase = "day"
	assert(StaffCatalog.extra_shakes() == 0)
	assert(StaffCatalog.quality_coin_bonus() == 0)
	var rest_shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(rest_shop)
	await get_tree().process_frame
	assert(rest_shop.staff_state == "resting")
	assert(rest_shop.stage._staff_actor == null)
	assert(rest_shop.staff_card.visible)
	assert(rest_shop.staff_status_label.text.contains("少发工资"))
	rest_shop.running = false
	rest_shop.queue_free()
	await get_tree().process_frame
	var rest_wage := StaffCatalog.charge_daily_wage()
	assert(rest_wage["status"] == "rest")
	assert(rest_wage["paid"] == 0 and GameState.coins == 0)
	GameState.day = 11
	assert(StaffCatalog.is_on_duty())
	assert(StaffCatalog.extra_shakes() == 1)
	assert(StaffCatalog.quality_coin_bonus() == 2)
	GameState.campaign_stats = GameState._new_campaign_stats()
	GameState.record_campaign_day(9, {
		"earned": 5, "staff_wage": 5, "staff_wage_shortfall": 9,
		"staff_on_duty": true, "staff_rest_day": false,
	})
	GameState.record_campaign_day(10, {
		"earned": 120, "staff_wage": 0, "staff_wage_shortfall": 0,
		"staff_on_duty": false, "staff_rest_day": true,
	})
	assert(GameState.campaign_stats["staff_wages"] == 5)
	assert(GameState.campaign_stats["staff_days"] == 1)
	assert(GameState.campaign_stats["staff_shortfalls"] == 1)
	assert(GameState.campaign_stats["staff_rest_days"] == 1)
	print("[STAFF] passed hire=3 traits=3 models=3 slacker_wake=1 perfection_rescue=1 wage=14 shortfall=9 rest_day=true auto_return=true")
	Sfx.stop_all()
	await get_tree().process_frame
	get_tree().quit()


func _different_base(current: Dictionary) -> Dictionary:
	for item in GameData.bases:
		if item["id"] != current["id"]:
			return item
	return current


func _find_label_contains(node: Node, fragment: String) -> bool:
	if node is Label and String(node.text).contains(fragment):
		return true
	for child in node.get_children():
		if _find_label_contains(child, fragment):
			return true
	return false
