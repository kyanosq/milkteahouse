## 夜间主推选择、旧档迁移、真实白天菜单订单、定价和热度衰减回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	var original_settings := GameState.settings.duplicate(true)
	GameLocale.set_locale("zh_CN", false)
	GameState.day = 9
	GameState.menu = [{"name": "经典珍珠奶茶", "tier": "普通", "price": 12}]
	GameState.featured_menu = []
	GameState.menu_last_hype_day = 0
	MenuCatalog.ensure_normalized()
	assert(GameState.menu.size() == 1)
	assert(GameState.menu[0]["id"] == "legend:classic_boba")
	assert(MenuCatalog.formula_available(GameState.menu[0]))
	assert(GameState.featured_menu == ["legend:classic_boba"])

	# 自定义饮品即使与传说配方撞名也不能被改写：名字回退只服务旧档迁移（R4）。
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
	var light_order := MenuCatalog.order_for_item(jasmine_pure, 2, "light_drinks")
	assert(int(light_order.get("menu_event_bonus", 0)) == 6)
	assert(int(DailyEvents.order_bonus(DailyEvents.event_for_day(10), {
		"kind": "regular", "order": light_order})["coins"]) == 6)
	var trend_order := MenuCatalog.order_for_item(brown_sugar, 2, "brown_sugar_trend")
	assert(int(DailyEvents.order_bonus(DailyEvents.event_for_day(11), {
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

	panel.queue_free()
	shop.queue_free()
	GameState.settings = original_settings
	TranslationServer.set_locale(GameState.locale())
	Sfx.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	print("[MENU_CATALOG] passed migration=true slots=3 order=true price=14 hype=true passive_income=false bilingual=true")
	get_tree().quit()
