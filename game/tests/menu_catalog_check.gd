## 夜间主推选择、菜单规范化、真实白天菜单订单、定价和热度衰减回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	var original_settings := GameState.settings.duplicate(true)
	GameLocale.set_locale("zh_CN", false)
	GameState.day = 9
	# 无 id/配方的残缺菜单项直接丢弃：新项目无旧档、不做收藏兜底（Iteration 62）。
	GameState.menu = [{"name": "经典珍珠奶茶", "tier": "普通", "price": 12}]
	GameState.featured_menu = []
	GameState.menu_last_hype_day = 0
	MenuCatalog.ensure_normalized()
	assert(GameState.menu.is_empty(), "malformed items without ids must be dropped")
	assert(GameState.featured_menu.is_empty())
	var legend_entry := MenuCatalog.register_legend(RecipeJournal.recipe("classic_boba"))
	assert(String(legend_entry["id"]) == "legend:classic_boba")
	assert(MenuCatalog.formula_available(MenuCatalog.item("legend:classic_boba")))
	assert(GameState.featured_menu == ["legend:classic_boba"])

	# 自定义饮品永远保持自身 id：规范化不得把 custom 改写成传说（丢真实配方）。
	GameState.menu = [{
		"id": "custom:3:1", "type": "custom", "name": "经典珍珠奶茶",
		"tier": "招牌", "price": 15, "quality": 84,
		"base": "black_tea", "milk": "fresh_milk", "toppings": ["boba"],
		"sugar": [50, 50],
	}]
	GameState.featured_menu = ["custom:3:1"]
	MenuCatalog.ensure_normalized()
	assert(GameState.menu[0]["id"] == "custom:3:1", "custom ids must never rewrite to legends")
	assert(GameState.menu[0]["base"] == "black_tea")
	assert(GameState.featured_menu == ["custom:3:1"])
	# 越日配方纵深防御：未解锁原料使特色订单退回随机订单而非不可能订单。
	var locked := MenuCatalog.register_legend(RecipeJournal.recipe("brown_sugar_boba"))
	GameState.day = 4
	assert(not MenuCatalog.formula_available(locked),
		"a formula with day-5 toppings must be unavailable on day 4")
	assert(MenuCatalog.order_for_item(locked, 2).is_empty(),
		"locked formulas must fall back to random orders")
	GameState.day = 9

	GameState.menu = []
	GameState.featured_menu = []
	for recipe_id in ["classic_boba", "jasmine_coco", "taro_boba", "oolong_pudding"]:
		MenuCatalog.register_legend(RecipeJournal.recipe(recipe_id))
	assert(GameState.menu.size() == 4)
	assert(GameState.featured_menu.size() == 3)
	assert(MenuCatalog.set_featured("legend:oolong_pudding", true, false) == "full")
	assert(MenuCatalog.set_featured("legend:jasmine_coco", false, false) == "ok")
	assert(MenuCatalog.set_featured("legend:oolong_pudding", true, false) == "ok")
	assert(MenuCatalog.hot_featured_count() == 3)
	assert(is_equal_approx(MenuCatalog.traffic_multiplier(), 0.88))

	GameState.featured_menu = ["legend:classic_boba"]
	assert(MenuCatalog.set_featured("legend:classic_boba", false, false) == "minimum")
	assert(MenuCatalog.should_offer(2, "regular"))
	assert(not MenuCatalog.should_offer(2, "critic"))
	var item := MenuCatalog.featured_for_spawn(2)
	var order := MenuCatalog.order_for_item(item, 2)
	assert(order["base"]["id"] == "black_tea")
	assert(order["milk"]["id"] == "fresh_milk")
	assert(order["tops"][0]["id"] == "boba")
	assert(order["menu_item_id"] == "legend:classic_boba")
	assert(MenuCatalog.sale_price(item) == 14)

	var jasmine_pure := MenuCatalog.register_legend(RecipeJournal.recipe("jasmine_pure"))
	var brown_sugar := MenuCatalog.register_legend(RecipeJournal.recipe("brown_sugar_boba"))
	assert(MenuCatalog.event_match_bonus(item, "lunch_rush") == 4)
	assert(MenuCatalog.event_match_bonus(jasmine_pure, "light_drinks") == 6)
	assert(MenuCatalog.event_match_bonus(brown_sugar, "brown_sugar_trend") == 2)
	assert(MenuCatalog.event_match_bonus(MenuCatalog.item("legend:taro_boba"), "critic_day") == 4)
	assert(MenuCatalog.event_match_bonus(MenuCatalog.item("legend:taro_boba"), "group_day") == 4)
	GameState.featured_menu = ["legend:classic_boba", "legend:brown_sugar_boba", "legend:jasmine_pure"]
	assert(MenuCatalog.featured_for_spawn(2, "light_drinks")["id"] == "legend:jasmine_pure",
		"a matching drink must receive the first weighted demand slot")
	# 用一周目事件日（day4 轻饮 / day5 黑糖）钉定叠加语义；Day10/11 已是二遍修饰词局。
	var light_order := MenuCatalog.order_for_item(jasmine_pure, 2, "light_drinks")
	assert(int(light_order.get("menu_event_bonus", 0)) == 6)
	assert(int(DailyEvents.order_bonus(DailyEvents.event_for_day(4), {
		"kind": "regular", "order": light_order})["coins"]) == 6)
	var trend_order := MenuCatalog.order_for_item(brown_sugar, 2, "brown_sugar_trend")
	assert(int(DailyEvents.order_bonus(DailyEvents.event_for_day(5), {
		"kind": "regular", "order": trend_order})["coins"]) == 6,
		"trend formula and featured match bonuses must stack visibly")

	var custom := MenuCatalog.register_custom({
		"name": "测试云朵", "quality": 90, "base": "green_tea", "milk": "coconut_milk",
		"toppings": ["coconut_jelly"], "sugar": 30,
	}, "爆款", 18)
	assert(MenuCatalog.formula_available(custom))
	assert(custom["sugar"] == [30, 30])

	var panel: MenuBoardPanel = load("res://ui/menu_board_panel.gd").new()
	add_child(panel)
	panel.show_panel()
	assert(panel.visible_card_count() == 7)
	GameLocale.set_locale("en", false)
	await get_tree().process_frame
	assert(panel._title_label.text == "Tomorrow's Featured Menu")
	panel.hide_panel()

	GameLocale.set_locale("zh_CN", false)
	GameState.featured_menu = ["legend:classic_boba"]
	GameState.menu_last_hype_day = 0
	var shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	shop._spawn_customer()
	shop._spawn_customer()
	var featured_customer: Dictionary = shop.customers[1]
	assert(featured_customer["order"].has("menu_item_id"))
	var featured_order: Dictionary = featured_customer["order"]
	shop._on_base(featured_order["base"])
	shop._on_milk(featured_order["milk"])
	for topping in featured_order["tops"]:
		shop._on_topping(topping)
	shop._on_sugar(featured_order["sugar"])
	for i in shop._shakes_needed():
		shop._on_shake()
	shop._on_deliver(featured_customer)
	assert(shop.menu_sales_count == 1)
	assert(shop.menu_sales_revenue == 14)
	var earned_before_end: int = shop.earned
	shop._end_day()
	assert(shop.earned == earned_before_end, "day end must not add passive menu income")
	var classic := MenuCatalog.item("legend:classic_boba")
	assert(int(classic["sales"]) == 1)
	assert(int(classic["hype_remaining"]) == 3)
	MenuCatalog.advance_day(9, {"legend:classic_boba": 99})
	assert(int(MenuCatalog.item("legend:classic_boba")["sales"]) == 1, "same day must be idempotent")
	for menu_item in GameState.menu:
		menu_item["hype_remaining"] = 0
	assert(is_equal_approx(MenuCatalog.traffic_multiplier(), 1.0))
	assert(MenuCatalog.sale_price(MenuCatalog.item("legend:classic_boba")) == 12)
	assert(MenuCatalog.should_offer(2, "regular"))
	assert(not MenuCatalog.should_offer(6, "regular"), "evergreen orders must use the slower cadence")

	# DP#4 定价（P9-1/P9-2 2026-08-17 重钉）：定价只改“该款”主推订单的轮转权重
	# （让利 3 槽 / 标准 2 槽 / 溢价 1 槽），不再作用全局到店间隔；传说不参与调价。
	for legend_id in ["legend:classic_boba", "legend:oolong_pudding", "legend:taro_boba"]:
		assert(MenuCatalog.price_options(MenuCatalog.item(legend_id)).is_empty(),
			"legend recipes must keep authored prices")
		assert(MenuCatalog.pricing_spawn_slots(MenuCatalog.item(legend_id)) == 2,
			"legends must not participate in pricing weights even at authored price gaps (P9-2)")
	var priced := MenuCatalog.register_custom({
		"name": "定价测试", "base": "black_tea", "milk": "fresh_milk",
		"toppings": ["boba"], "sugar": 50, "quality": 90,
	}, "爆款", 18, false)
	assert(MenuCatalog.price_options(priced) == [16, 18, 21])
	assert(MenuCatalog.set_item_price(String(priced["id"]), 19, false) == false,
		"prices outside the authored points must be rejected")
	assert(MenuCatalog.set_item_price(String(priced["id"]), 16, false) == true)
	assert(int(MenuCatalog.item(String(priced["id"]))["price"]) == 16)
	# 让利只对"主推中的自创饮品"生效：腾出一个主推位后依次验证标准/让利/溢价方向。
	assert(MenuCatalog.set_featured("legend:classic_boba", false, false) == "ok")
	assert(MenuCatalog.set_featured(String(priced["id"]), true, false) == "ok")
	MenuCatalog.set_item_price(String(priced["id"]), 18, false)
	assert(MenuCatalog.pricing_spawn_slots(MenuCatalog.item(String(priced["id"]))) == 2,
		"standard pricing must keep the neutral rotation cadence")
	MenuCatalog.set_item_price(String(priced["id"]), 16, false)
	assert(MenuCatalog.pricing_spawn_slots(MenuCatalog.item(String(priced["id"]))) == 3,
		"budget pricing must win more featured order slots")
	# P9-1：定价摆动不再拉动全局到店间隔（旧 ±2%/3% 在三槽饱和区被噪声淹没）。
	var traffic_at_budget := MenuCatalog.traffic_multiplier()
	MenuCatalog.set_item_price(String(priced["id"]), 21, false)
	assert(is_equal_approx(MenuCatalog.traffic_multiplier(), traffic_at_budget),
		"pricing must no longer touch the global arrival interval")
	assert(MenuCatalog.pricing_spawn_slots(MenuCatalog.item(String(priced["id"]))) == 1,
		"premium pricing must win fewer featured order slots")
	# 轮转分布钉：让利款 3 槽 vs 溢价款 1 槽（同为爆款热度，FRESH 节奏）。
	MenuCatalog.set_item_price(String(priced["id"]), 16, false)
	var premium_item := MenuCatalog.register_custom({
		"name": "溢价测试", "base": "black_tea", "milk": "fresh_milk",
		"toppings": ["boba"], "sugar": 50, "quality": 90,
	}, "爆款", 21, false)
	assert(MenuCatalog.set_featured(String(premium_item["id"]), true, false) == "ok")
	var slot_counts := {}
	for sequence in range(8):
		var picked := String(MenuCatalog.featured_for_spawn(
			2 + sequence * MenuCatalog.FRESH_ORDER_INTERVAL).get("id", ""))
		slot_counts[picked] = int(slot_counts.get(picked, 0)) + 1
	assert(int(slot_counts.get(String(priced["id"]), 0)) == 6,
		"budget pricing must hold 3/4 rotation slots")
	assert(int(slot_counts.get(String(premium_item["id"]), 0)) == 2,
		"premium pricing must hold 1/4 rotation slots")
	MenuCatalog.set_item_price(String(priced["id"]), 18, false)

	panel.queue_free()
	shop.queue_free()
	GameState.settings = original_settings
	TranslationServer.set_locale(GameState.locale())
	Sfx.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	print("[MENU_CATALOG] passed normalize=true slots=3 order=true price=14 hype=true passive_income=false bilingual=true")
	get_tree().quit()
