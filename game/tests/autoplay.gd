## 自动试玩机器人：模拟真人操作节奏跑完一整天，输出难度指标
## 用法: BOT_PROFILE=newbie|regular|skilled BOT_DAY=1 godot --headless res://tests/autoplay.tscn
extends Node

var shop: Control
var target = null
var step := 0
var cooldown := 0.0
var shake_acc := 0.0
var manage_staff := false
var profile := "newbie"
var sample_id := 0
var rework_rate := 0.28
var discard_rate := 0.08
var craft_error := ""
var craft_error_started := false
var reworks_made := 0
var discards_made := 0
var craft_rng := RandomNumberGenerator.new()

# 画像参数
var act_delay := 0.9    # 每次点按间隔（含找按钮时间）
var read_delay := 2.2   # 接到新订单的读单时间
var shake_rate := 3.0   # 摇茶连点速度（次/秒）


func _ready() -> void:
	GameState.test_mode = true
	var speed_env := OS.get_environment("BOT_TIME_SCALE")
	Engine.time_scale = float(speed_env) if speed_env != "" else 6.0
	profile = OS.get_environment("BOT_PROFILE")
	if profile.is_empty():
		profile = "newbie"
	manage_staff = OS.get_environment("BOT_MANAGE_STAFF") == "1"
	if profile == "skilled":
		act_delay = 0.35
		read_delay = 0.8
		shake_rate = 6.0
		rework_rate = 0.03
		discard_rate = 0.0
	elif profile == "regular":
		act_delay = 0.60
		read_delay = 1.4
		shake_rate = 4.2
		rework_rate = 0.12
		discard_rate = 0.03
	var day_env := OS.get_environment("BOT_DAY")
	GameState.day = int(day_env) if day_env != "" else 1
	sample_id = int(OS.get_environment("BOT_SAMPLE")) if OS.get_environment("BOT_SAMPLE") != "" else 0
	seed(1000 + GameState.day)
	craft_rng.seed = 80_000 + GameState.day * 101 \
		+ ["newbie", "regular", "skilled"].find(profile) * 10_000 + sample_id * 1_009
	GameState.coins = int(OS.get_environment("BOT_COINS")) if OS.get_environment("BOT_COINS") != "" else 0
	GameState.inspiration = 0
	GameState.menu = []
	GameState.featured_menu = []
	GameState.menu_last_hype_day = 0
	GameState.dark_menu = []
	GameState.upgrades = {}
	GameState.staff = {}
	GameState.endless = GameState._new_endless_state()
	GameState.new_shop_route = ""
	var route_env := OS.get_environment("BOT_ROUTE")
	if LegacyRoutes.is_valid(route_env):
		GameState.new_shop_route = route_env
	var upgrades_env := OS.get_environment("BOT_UPGRADES")
	if upgrades_env != "":
		for entry in upgrades_env.split(","):
			var pair := entry.split(":")
			if pair.size() == 2:
				GameState.upgrades[pair[0]] = int(pair[1])
	var staff_env := OS.get_environment("BOT_STAFF")
	if staff_env != "":
		var staff_data := StaffCatalog.candidate(staff_env)
		if not staff_data.is_empty():
			GameState.staff = staff_data.duplicate(true)
			GameState.staff["trait_revealed"] = true
			GameState.staff["days_worked"] = 0
			GameState.staff["rest_day"] = GameState.day if OS.get_environment("BOT_STAFF_REST") == "1" else 0
			GameState.staff["wage_shortfall"] = StaffCatalog.wage() if OS.get_environment("BOT_STAFF_REST") == "1" else 0
			GameState.staff["wage_shortfalls"] = 1 if OS.get_environment("BOT_STAFF_REST") == "1" else 0
	var contract_env := OS.get_environment("BOT_CONTRACT")
	if contract_env != "":
		assert(EndlessContracts.sign_contract(contract_env, GameState.day, false))
	var menu_env := OS.get_environment("BOT_MENU")
	if menu_env != "":
		for recipe_id in menu_env.split(","):
			var recipe := RecipeJournal.recipe(recipe_id)
			if not recipe.is_empty() and not RecipeJournal.is_dark(recipe):
				MenuCatalog.register_legend(recipe)
		if OS.get_environment("BOT_MENU_STALE") == "1":
			for item_data in GameState.menu:
				item_data["hype_remaining"] = 0
	EventBus.day_ended.connect(_on_day_end)
	shop = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	print("[BOT] profile=%s day=%d sample=%d rework_rate=%.0f%% discard_rate=%.0f%%" % [
		profile, GameState.day, sample_id, rework_rate * 100.0, discard_rate * 100.0])


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


func _process(delta: float) -> void:
	if shop == null or not shop.running:
		return
	if manage_staff and shop.staff_state == "idle":
		shop._on_staff_clicked()
	cooldown -= delta
	if shop.customers.is_empty():
		target = null
		return
	# 选定/换目标
	if target == null or not shop.customers.has(target):
		target = shop.customers[0]
		step = 0
		shake_acc = 0.0
		shop._reset_cup()
		_plan_craft_error()
		cooldown = read_delay
		return
	# 已封口 → 递出
	if shop.cup_sealed:
		if cooldown <= 0.0:
			shop._on_deliver(target)
			target = null
			cooldown = act_delay
		return
	# 按序点配料
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
				discards_made += 1
				craft_error = ""
				craft_error_started = false
				cooldown = read_delay * 0.4
			else:
				shop._on_base(order["base"])
				if shop.cup_base != null:
					if craft_error == "rework":
						reworks_made += 1
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
		# 摇茶连点
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


func _on_day_end(stats: Dictionary) -> void:
	var total: int = stats["served"] + stats["angry"]
	var rate: float = (float(stats["served"]) / float(total) * 100.0) if total > 0 else 0.0
	var contract: Dictionary = stats.get("contract", {})
	var perfect_rate := (float(stats["perfect"]) / float(stats["served"]) * 100.0) if int(stats["served"]) > 0 else 0.0
	print("[RESULT] earned=%d net=%d operating_net=%d stock=%d waste=%d rent=%d/%d relief=%d goal=%d stars=%d served=%d perfect=%d perfect_rate=%.0f%% reworks=%d discards=%d inspiration=%d angry=%d serve_rate=%.0f%% event=%s event_bonus=%d buzz=%d special=%d menu_sales=%d menu_revenue=%d menu_hot=%d route=%s route_bonus=%d route_triggers=%d staff=%s wakes=%d rescues=%d staff_bonus=%d wage=%d contract=%s/%s stamps=%d upgrades=%s" %
		[stats["earned"], GameState.coins,
		int(stats.get("net_operating", 0)), int(stats.get("stock_cost", 0)), int(stats.get("waste_cost", 0)),
		int(stats.get("rent_paid", 0)), int(stats.get("rent_due", 0)), int(stats.get("cost_relief", 0)),
		shop.goal, stats["stars"], stats["served"], stats["perfect"], perfect_rate,
		reworks_made, discards_made, GameState.inspiration,
		stats["angry"], rate, String(stats.get("event_id", "calm")),
		int(stats.get("event_bonus", 0)), int(stats.get("event_buzz", 0)),
		int(stats.get("special_served", 0)), int(shop.menu_sales_count), int(shop.menu_sales_revenue),
		MenuCatalog.hot_featured_count(), LegacyRoutes.active_id() if LegacyRoutes.is_active() else "none",
		int(stats.get("route_bonus", 0)), int(shop.route_trigger_count), String(GameState.staff.get("id", "none")),
		int(stats.get("staff_wakes", 0)), int(stats.get("staff_rescues", 0)),
		int(stats.get("staff_bonus", 0)), int(stats.get("staff_wage", 0)),
		String(contract.get("id", "none")), "success" if bool(contract.get("success", false)) else ("failed" if not contract.is_empty() else "none"),
		int(GameState.endless.get("stamps", 0)), str(GameState.upgrades)])
	Sfx.stop_all()
	shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
