## 连续十四天策略仿真：真实日间场景/结算 + 夜间购买、招聘与配方上架决策。
## 用法: CAMPAIGN_STRATEGY=careful|balanced|growth godot --headless --path game res://tests/campaign_strategy_sim.tscn
extends Node

## The real shop is advanced by a fixed logical clock instead of the host frame
## delta.  This keeps the long balance gate reproducible on fast and slow CI
## machines while the rendered scene and all production gameplay code stay real.
const SIM_STEP := 1.0 / 30.0
const DEFAULT_TICKS_PER_FRAME := 30

var shop: Control
var target: Variant = null
var step := 0
var cooldown := 0.0
var shake_acc := 0.0
var settling := false
var strategy := "balanced"
var profile := "regular"
var manage_staff := false
var hire_id := "taozi"
var act_delay := 0.60
var read_delay := 1.4
var shake_rate := 4.2
var upgrade_plan: Array[String] = []
var research_plan: Array[String] = []
var upgrade_index := 0
var upgrade_finish_day := 0
var menu_rotations := 0
var history: Array[Dictionary] = []
var ticks_per_frame := DEFAULT_TICKS_PER_FRAME
var rework_rate := 0.12
var discard_rate := 0.03
var craft_error := ""
var craft_error_started := false
var craft_rng := RandomNumberGenerator.new()


func _ready() -> void:
	GameState.test_mode = true
	Engine.time_scale = 1.0
	var ticks_env := OS.get_environment("CAMPAIGN_TICKS_PER_FRAME")
	if ticks_env.is_valid_int():
		ticks_per_frame = clampi(int(ticks_env), 1, 120)
	strategy = OS.get_environment("CAMPAIGN_STRATEGY")
	if strategy not in ["careful", "balanced", "growth"]:
		strategy = "balanced"
	_configure_strategy()
	var kept_settings := GameState.settings.duplicate(true)
	GameState.reset_progress()
	GameState.settings = kept_settings
	var legacy_route := OS.get_environment("CAMPAIGN_ROUTE")
	if LegacyRoutes.is_valid(legacy_route):
		GameState.new_shop_route = legacy_route
		GameState.coins = 80
		GameState.inspiration = 3
	GameState.settings["sound_volume"] = 0.0
	GameState.settings["sfx_volume"] = 0.0
	GameState.settings["music_volume"] = 0.0
	GameState.settings["reduced_motion"] = true
	GameState.legacy = {"campaigns_completed": 0, "best_grade": "-", "best_score": 0}
	GameState.tutorial_completed = true
	GameLocale.set_locale("en", false)
	EventBus.day_ended.connect(_on_day_end)
	call_deferred("_start_shift")


func _configure_strategy() -> void:
	match strategy:
		"careful":
			profile = "newbie"
			manage_staff = true
			hire_id = "xiaoman"
			upgrade_plan = ["comfort", "shaker", "tip_jar", "comfort", "shaker", "smart_sugar", "tip_jar", "comfort", "shaker", "tip_jar"]
			research_plan = ["classic_boba", "jasmine_pure", "oolong_pudding", "jasmine_coco", "oat_boba_black"]
		"growth":
			profile = "skilled"
			manage_staff = false
			hire_id = "acheng"
			upgrade_plan = ["tip_jar", "shaker", "tip_jar", "shaker", "smart_sugar", "tip_jar", "comfort", "shaker", "comfort", "comfort"]
			research_plan = ["classic_boba", "brown_sugar_boba", "taro_boba", "jasmine_coco", "oat_boba_black"]
		_:
			profile = "regular"
			manage_staff = false
			hire_id = "taozi"
			upgrade_plan = ["shaker", "comfort", "tip_jar", "shaker", "smart_sugar", "tip_jar", "comfort", "shaker", "tip_jar", "comfort"]
			research_plan = ["classic_boba", "jasmine_coco", "oolong_pudding", "taro_boba", "red_bean_pudding"]
	if profile == "newbie":
		act_delay = 0.9
		read_delay = 2.2
		shake_rate = 3.0
		rework_rate = 0.28
		discard_rate = 0.08
	elif profile == "skilled":
		act_delay = 0.35
		read_delay = 0.8
		shake_rate = 6.0
		rework_rate = 0.03
		discard_rate = 0.0


func _start_shift() -> void:
	settling = false
	target = null
	step = 0
	cooldown = 0.0
	shake_acc = 0.0
	seed(1000 + GameState.day)
	craft_rng.seed = 80_000 + GameState.day * 101 \
		+ ["newbie", "regular", "skilled"].find(profile) * 10_000
	shop = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	# DayShop normally advances from SceneTree::_process().  The harness owns its
	# clock so no host-frame delta can leak into arrivals, patience, staff or time.
	shop.set_process(false)
	print("[STRATEGY_START] route=%s profile=%s day=%d coins=%d upgrades=%d staff=%s menu=%d" % [
		strategy, profile, GameState.day, GameState.coins, UpgradeCatalog.total_levels(),
		String(GameState.staff.get("id", "none")), GameState.menu.size()])


func _process(_delta: float) -> void:
	if settling or shop == null or not is_instance_valid(shop) or not shop.running:
		return
	for _tick in range(ticks_per_frame):
		if settling or shop == null or not is_instance_valid(shop) or not shop.running:
			break
		_drive_bot_tick(SIM_STEP)
		if shop != null and is_instance_valid(shop) and shop.running:
			shop._process(SIM_STEP)


func _drive_bot_tick(delta: float) -> void:
	if manage_staff and shop.staff_state == "idle":
		shop._on_staff_clicked()
	cooldown -= delta
	if shop.customers.is_empty():
		target = null
		return
	if target == null or not shop.customers.has(target):
		target = shop.customers[0]
		step = 0
		shake_acc = 0.0
		shop._reset_cup()
		_plan_craft_error()
		cooldown = read_delay
		return
	if shop.cup_sealed:
		if cooldown <= 0.0:
			shop._on_deliver(target)
			target = null
			cooldown = act_delay
		return
	var order: Dictionary = target["order"]
	var tops: Array = order["tops"]
	_manage_prep(order)
	if step == 0:
		if cooldown <= 0.0:
			if not craft_error.is_empty() and not craft_error_started:
				shop._on_base(_alternate_base(order["base"]))
				craft_error_started = true
				cooldown = act_delay
			elif craft_error == "discard":
				shop._on_reset_cup_pressed()
				craft_error = ""
				craft_error_started = false
				cooldown = read_delay * 0.4
			else:
				shop._on_base(order["base"])
				if shop.cup_base != null:
					craft_error = ""
					craft_error_started = false
					step = 1
				cooldown = act_delay
	elif step == 1:
		if cooldown <= 0.0:
			shop._on_milk(order["milk"])
			step = 2
			cooldown = act_delay
	elif step - 2 < tops.size():
		if cooldown <= 0.0:
			shop._on_topping(tops[step - 2])
			if shop._has_topping(tops[step - 2]):
				step += 1
			cooldown = act_delay
	elif step == 2 + tops.size():
		if shop.sugar_confirmed:
			step += 1
		elif cooldown <= 0.0:
			shop._on_sugar(order["sugar"])
			step += 1
			cooldown = act_delay
	else:
		shake_acc += shake_rate * delta
		while shake_acc >= 1.0 and not shop.cup_sealed:
			shake_acc -= 1.0
			shop._on_shake()


func _manage_prep(order: Dictionary) -> void:
	if shop.tea_batch.active and shop.tea_batch.state() != "brewing":
		shop._on_tea_batch_pressed()
	var tea_id := String(order["base"]["id"])
	if not shop.tea_batch.active and shop._tea_stock_count(tea_id) <= 1:
		shop._on_tea_batch_pressed()
	var needs_pearls := false
	for topping in order["tops"]:
		if String(topping["id"]) == "boba":
			needs_pearls = true
			break
	if shop.pearl_batch.active and shop.pearl_batch.state() != "brewing":
		shop._on_pearl_batch_pressed()
	if needs_pearls and not shop.pearl_batch.active and shop.pearl_stock.size() <= 1:
		shop._on_pearl_batch_pressed()


func _plan_craft_error() -> void:
	craft_error = ""
	craft_error_started = false
	var roll := craft_rng.randf()
	if roll < discard_rate:
		craft_error = "discard"
	elif roll < discard_rate + rework_rate:
		craft_error = "rework"


func _alternate_base(target_base: Dictionary) -> Dictionary:
	for item in GameData.unlocked(GameData.bases, GameState.day):
		if String(item["id"]) != String(target_base["id"]):
			return item
	return target_base


func _on_day_end(stats: Dictionary) -> void:
	if settling:
		return
	settling = true
	call_deferred("_finish_shift", stats.duplicate(true))


func _finish_shift(stats: Dictionary) -> void:
	var day_number := GameState.day
	var action_parts: Array[String] = []
	if shop != null and is_instance_valid(shop):
		shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	action_parts.append_array(_night_strategy(day_number))
	var record := {
		"day": day_number, "gross": int(stats.get("earned", 0)),
		"net": int(stats.get("net_operating", 0)), "stars": int(stats.get("stars", 0)),
		"served": int(stats.get("served", 0)), "angry": int(stats.get("angry", 0)),
		"golden_batches": int(stats.get("golden_batches", 0)),
		"poor_batches": int(stats.get("poor_batches", 0)),
		"stock": int(stats.get("stock_cost", 0)), "rent": int(stats.get("rent_paid", 0)),
		"wage": int(stats.get("staff_wage", 0)), "coins": GameState.coins,
	}
	history.append(record)
	print("[STRATEGY_DAY] route=%s day=%d gross=%d net=%d stars=%d served=%d angry=%d stock=%d wage=%d rent=%d coins=%d actions=%s" % [
		strategy, day_number, record["gross"], record["net"], record["stars"], record["served"],
		record["angry"], record["stock"], record["wage"], record["rent"], record["coins"],
		"+".join(action_parts) if not action_parts.is_empty() else "hold"])
	if day_number >= 14:
		_finish_campaign()
		return
	GameState.day += 1
	GameState.phase = "day"
	GameState.night_budget = -1
	GameState.night_budget_day = 0
	GameState.market_settlement = {}
	call_deferred("_start_shift")


func _night_strategy(day_number: int) -> Array[String]:
	var actions: Array[String] = []
	var reserve := int(UpgradeCatalog.next_day_reserve(day_number)["total"])
	if day_number >= StaffCatalog.UNLOCK_DAY and not StaffCatalog.has_staff():
		var hire_reserve := reserve + StaffCatalog.HIRE_COST
		if GameState.coins >= hire_reserve and StaffCatalog.hire(hire_id, false):
			actions.append("hire:%s" % hire_id)
			reserve = int(UpgradeCatalog.next_day_reserve(day_number)["total"])
	if upgrade_index < upgrade_plan.size():
		var item_id := upgrade_plan[upgrade_index]
		var cost := UpgradeCatalog.next_cost(item_id)
		if cost >= 0 and GameState.coins - cost >= reserve and UpgradeCatalog.buy(item_id, false):
			upgrade_index += 1
			actions.append("upgrade:%s%d" % [item_id, UpgradeCatalog.level(item_id)])
			if UpgradeCatalog.total_levels() == UpgradeCatalog.total_max_levels():
				upgrade_finish_day = day_number
	for recipe_id in research_plan:
		if recipe_id in GameState.discovered:
			continue
		var recipe := RecipeJournal.recipe(recipe_id)
		if recipe.is_empty() or not RecipeJournal.is_available(recipe, day_number) or GameState.inspiration < 2:
			continue
		GameState.inspiration -= 2
		GameState.discovered.append(recipe_id)
		MenuCatalog.register_legend(recipe)
		actions.append("research:%s" % recipe_id)
		break
	var menu_action := _optimize_featured(day_number + 1)
	if not menu_action.is_empty():
		actions.append(menu_action)
	return actions


func _optimize_featured(target_day: int) -> String:
	var available := MenuCatalog.items()
	if available.is_empty():
		return ""
	var event_id := String(DailyEvents.event_for_day(target_day).get("id", "calm"))
	var chosen: Array[String] = []
	while chosen.size() < mini(MenuCatalog.FEATURED_LIMIT, available.size()):
		var best_id := ""
		var best_value := -100000
		for item_data in available:
			var item_id := String(item_data.get("id", ""))
			if item_id in chosen or not MenuCatalog.formula_available(item_data):
				continue
			var value := _menu_value(item_data, event_id)
			if value > best_value:
				best_value = value
				best_id = item_id
		if best_id.is_empty():
			break
		chosen.append(best_id)
	if chosen == GameState.featured_menu:
		return ""
	GameState.featured_menu = chosen
	menu_rotations += 1
	var names: Array[String] = []
	for item_id in chosen:
		names.append(item_id.trim_prefix("legend:"))
	return "feature:%s" % ",".join(names)


func _menu_value(item_data: Dictionary, event_id: String) -> int:
	var price := MenuCatalog.sale_price(item_data)
	var match_bonus := MenuCatalog.event_match_bonus(item_data, event_id)
	var topping_data: Array = item_data.get("toppings", [])
	var complexity: int = topping_data.size()
	match strategy:
		"careful":
			return match_bonus * 8 + price - complexity * 5
		"growth":
			return match_bonus * 6 + price * 2 - complexity
	return match_bonus * 10 + price - complexity * 3


func _finish_campaign() -> void:
	var summary := GameState.build_campaign_summary()
	var total_net := 0
	for record in history:
		total_net += int(record["net"])
	print("[STRATEGY_RESULT] route=%s legacy_route=%s profile=%s gross=%d operating_net=%d coins=%d upgrades=%d/%d staff=%s staff_days=%d wages=%d shortfalls=%d rest_days=%d menu=%d rotations=%d discoveries=%d stars=%d/42 served=%d angry=%d rent=%d costs=%d route_bonus=%d score=%d grade=%s" % [
		strategy, LegacyRoutes.active_id() if LegacyRoutes.is_active() else "none", profile,
		int(GameState.campaign_stats["revenue"]), total_net, GameState.coins,
		UpgradeCatalog.total_levels(), UpgradeCatalog.total_max_levels(), String(GameState.staff.get("id", "none")),
		int(GameState.campaign_stats["staff_days"]), int(GameState.campaign_stats["staff_wages"]),
		int(GameState.campaign_stats["staff_shortfalls"]), int(GameState.campaign_stats["staff_rest_days"]),
		GameState.menu.size(), menu_rotations, GameState.discovered.size() + GameState.dark_discovered.size(),
		int(GameState.campaign_stats["stars"]), int(GameState.campaign_stats["served"]),
		int(GameState.campaign_stats["angry"]), int(GameState.campaign_stats["rent_paid"]),
		int(GameState.campaign_stats["operating_costs"]), int(GameState.campaign_stats["route_bonus"]),
		int(summary["score"]), String(summary["grade"])])
	if not _validate_campaign(summary):
		Sfx.stop_all()
		get_tree().quit(1)
		return
	Sfx.stop_all()
	await get_tree().process_frame
	get_tree().quit()


func _validate_campaign(summary: Dictionary) -> bool:
	var expected: Dictionary = {
		"careful": {"grade": "A", "levels": 9, "finish_day": 0, "stars": 30, "cash_min": 80, "cash_max": 180},
		"balanced": {"grade": "S", "levels": 10, "finish_day": 10, "stars": 42, "cash_min": 1900, "cash_max": 2300},
		"growth": {"grade": "S", "levels": 10, "finish_day": 10, "stars": 42, "cash_min": 3500, "cash_max": 4200},
	}[strategy]
	var failures: Array[String] = []
	var golden_total := 0
	for record in history:
		golden_total += int(record.get("golden_batches", 0))
	if history.size() != 14:
		failures.append("expected 14 settled days, got %d" % history.size())
	if int(GameState.campaign_stats.get("served", 0)) <= 0:
		failures.append("served no customers")
	if golden_total <= 0:
		failures.append("never collected or sold a golden preparation batch")
	if int(GameState.campaign_stats.get("angry", 0)) != 0:
		failures.append("expected no angry customers, got %d" % int(GameState.campaign_stats.get("angry", 0)))
	if int(GameState.campaign_stats.get("staff_shortfalls", 0)) != 0:
		failures.append("staff wage shortfall occurred")
	if String(summary.get("grade", "")) != String(expected["grade"]):
		failures.append("expected grade %s, got %s" % [String(expected["grade"]), String(summary.get("grade", ""))])
	if UpgradeCatalog.total_levels() != int(expected["levels"]):
		failures.append("expected %d upgrade levels, got %d" % [int(expected["levels"]), UpgradeCatalog.total_levels()])
	if upgrade_finish_day != int(expected["finish_day"]):
		failures.append("expected upgrade completion day %d, got %d" % [int(expected["finish_day"]), upgrade_finish_day])
	if int(GameState.campaign_stats.get("stars", 0)) != int(expected["stars"]):
		failures.append("expected %d stars, got %d" % [int(expected["stars"]), int(GameState.campaign_stats.get("stars", 0))])
	if GameState.coins < int(expected["cash_min"]) or GameState.coins > int(expected["cash_max"]):
		failures.append("cash %d outside %d..%d" % [GameState.coins, int(expected["cash_min"]), int(expected["cash_max"])])
	if not failures.is_empty():
		for failure in failures:
			push_error("[STRATEGY_ASSERT] %s: %s" % [strategy, failure])
		return false
	print("[STRATEGY_ASSERT] route=%s days=14 grade=%s upgrades=%d finish_day=%d stars=%d angry=0 cash=%d" % [
		strategy, String(summary.get("grade", "")), UpgradeCatalog.total_levels(), upgrade_finish_day,
		int(GameState.campaign_stats.get("stars", 0)), GameState.coins])
	return true
