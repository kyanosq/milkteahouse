## Dark menu depth gate: recoverable formulas, explicit replacement, real orders,
## sale-only buzz and next-day traffic must work as one continuous loop.
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameLocale.set_locale("zh_CN", false)
	GameState.day = 9
	GameState.phase = "day"
	GameState.coins = 0
	GameState.inspiration = 0
	GameState.buzz = 0
	GameState.buzz_traffic = 0
	GameState.buzz_traffic_day = 0
	GameState.night_budget = -1
	GameState.night_budget_day = 0
	GameState.night_performance_remaining = 0
	GameState.menu = []
	GameState.featured_menu = []
	GameState.menu_last_hype_day = 0
	GameState.staff = {}
	GameState.upgrades = {}
	GameState.tutorial_completed = true
	GameState.dark_discovered = ["xiangcai_fantasy", "zheergen_rage", "sweet_salt_horror"]
	GameState.dark_menu = [
		{"kind": "legend", "recipe_id": "xiangcai_fantasy"},
		{"kind": "legend", "recipe_id": "zheergen_rage"},
		{"kind": "legend", "recipe_id": "sweet_salt_horror"},
	]
	assert(MenuCatalog.dark_order_items().size() == 3)
	assert(MenuCatalog.dark_should_offer(3, "regular"))
	assert(not MenuCatalog.dark_should_offer(3, "critic"))
	var offered := MenuCatalog.dark_order_for_entry(MenuCatalog.dark_for_spawn(3), 3)
	assert(String(offered["dark_menu_id"]) == "legend:xiangcai_fantasy")

	var panel: MenuBoardPanel = load("res://ui/menu_board_panel.gd").new()
	add_child(panel)
	panel.show_panel()
	panel._switch_mode("dark")
	assert(panel.visible_card_count() == 3)
	var candidate := MenuCatalog.dark_candidate_for_trial(
		"black_tea", "fresh_milk", ["boba"], 50, 18)
	panel.show_dark_candidate(candidate)
	panel._replace_dark(1)
	assert(MenuCatalog.dark_item_id(GameState.dark_menu[1]).begins_with("mystery:"))
	assert(MenuCatalog.dark_formula_available(GameState.dark_menu[1]))
	panel.hide_panel()

	var shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	shop._spawn_customer()
	shop._spawn_customer()
	shop._spawn_customer()
	var dark_customer: Dictionary = shop.customers.back()
	assert(dark_customer["order"].has("dark_menu_id"))
	var order: Dictionary = dark_customer["order"]
	shop._reset_cup()
	shop._on_base(order["base"])
	shop._on_milk(order["milk"])
	for topping in order["tops"]:
		shop._on_topping(topping)
	shop._on_sugar(order["sugar"])
	while not shop.cup_sealed:
		shop._on_shake()
	shop._on_deliver(dark_customer)
	assert(shop.dark_sales_count == 1)
	assert(shop.dark_buzz_earned == 2 and GameState.buzz == 2)
	assert(int(GameState.dark_menu[0].get("sales", 0)) == 1)
	var buzz_before_end := GameState.buzz
	shop._end_day()
	assert(GameState.buzz == buzz_before_end,
		"occupying dark slots must never award passive end-of-day buzz")

	var lab: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(lab)
	await get_tree().process_frame
	assert(GameState.buzz == 0)
	assert(GameState.buzz_traffic == 2 and GameState.buzz_traffic_day == 10)
	assert(is_equal_approx(MenuCatalog.buzz_traffic_multiplier(10), 0.96))

	panel.queue_free()
	shop.queue_free()
	lab.queue_free()
	Sfx.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	print("[DARK_MENU] passed replace=true real_order=true sale_buzz=2 passive=false traffic=4%")
	get_tree().quit()
