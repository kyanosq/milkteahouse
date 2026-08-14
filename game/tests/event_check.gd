## 每日事件轮换、订单偏置、特殊顾客与奖励回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.menu = []
	GameState.featured_menu = []
	GameState.menu_last_hype_day = 0
	GameState.settings = {"sound_volume": 0.0, "reduced_motion": true}
	GameState.new_shop_route = ""
	assert(DailyEvents.event_for_day(1)["id"] == "calm")
	assert(DailyEvents.event_for_day(3)["id"] == "lunch_rush")
	assert(DailyEvents.event_for_day(4)["id"] == "light_drinks")
	assert(DailyEvents.event_for_day(5)["id"] == "brown_sugar_trend")
	assert(DailyEvents.event_for_day(6)["id"] == "critic_day")
	assert(DailyEvents.event_for_day(7)["id"] == "influencer_day")
	assert(DailyEvents.event_for_day(8)["id"] == "group_day")
	assert(DailyEvents.event_for_day(9)["id"] == "lunch_rush")
	var expected_routes := {
		"rush": ["group_day", "lunch_rush", "influencer_day", "critic_day", "light_drinks", "brown_sugar_trend"],
		"precision": ["critic_day", "light_drinks", "group_day", "brown_sugar_trend", "influencer_day", "lunch_rush"],
		"trend": ["influencer_day", "brown_sugar_trend", "light_drinks", "lunch_rush", "critic_day", "group_day"],
	}
	for route_id in expected_routes:
		GameState.new_shop_route = route_id
		var actual: Array[String] = []
		for day in range(9, 15):
			actual.append(String(DailyEvents.event_for_day(day)["id"]))
		assert(actual == expected_routes[route_id])
		for event_id in actual:
			assert(actual.count(event_id) == 1)
	GameState.new_shop_route = ""
	assert(DailyEvents.is_special_customer(DailyEvents.event_for_day(6), 1))
	assert(not DailyEvents.is_special_customer(DailyEvents.event_for_day(6), 2))
	assert(DailyEvents.is_special_customer(DailyEvents.event_for_day(6), 5))
	assert(DailyEvents.customer_kind(DailyEvents.event_for_day(7), 1) == "influencer")
	assert(DailyEvents.customer_kind(DailyEvents.event_for_day(8), 1) == "group")

	seed(4804)
	var light_count := 0
	var trend_count := 0
	var top_pool: Array = GameData.unlocked(GameData.toppings, 6)
	for i in 40:
		var base_order := {
			"base": GameData.bases[0], "milk": GameData.milks[1],
			"tops": [GameData.toppings[0], GameData.toppings[1]],
			"sugar": GameData.sugar_levels[4],
		}
		var light := DailyEvents.modify_order(DailyEvents.event_for_day(4), base_order, top_pool, i + 1)
		if light["milk"]["id"] == "none" and int(light["sugar"]["value"]) <= 30:
			light_count += 1
		var trend := DailyEvents.modify_order(DailyEvents.event_for_day(5), base_order, top_pool, i + 1)
		for topping in trend["tops"]:
			if topping["id"] == "brown_sugar":
				trend_count += 1
				break
	assert(light_count >= 20)
	assert(trend_count >= 24)
	var viral_order := {
		"base": GameData.bases[0], "milk": GameData.milks[1], "tops": [],
		"sugar": GameData.sugar_levels[2],
	}
	var viral := DailyEvents.modify_order(DailyEvents.event_for_day(7), viral_order,
		GameData.unlocked(GameData.toppings, 7), 1, "influencer")
	assert(viral["tops"].size() == 1)
	assert(viral["tops"][0]["id"] == "xiangcai")
	var viral_reward := DailyEvents.order_bonus(DailyEvents.event_for_day(7),
		{"kind": "influencer", "order": viral})
	assert(int(viral_reward["coins"]) == 5)
	assert(int(viral_reward["buzz"]) == 3)

	GameState.day = 6
	GameState.phase = "day"
	GameState.coins = 0
	GameState.inspiration = 0
	GameState.upgrades = {}
	var shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	assert(shop.day_event["id"] == "critic_day")
	shop._spawn_customer()
	var critic: Dictionary = shop.customers[0]
	assert(critic["special"])
	assert(critic["order"]["tops"].size() == 2)
	shop._on_base(critic["order"]["base"])
	shop._on_milk(critic["order"]["milk"])
	for topping in critic["order"]["tops"]:
		shop._on_topping(topping)
	shop._on_sugar(critic["order"]["sugar"])
	for i in shop._shakes_needed():
		shop._on_shake()
	shop._on_deliver(critic)
	assert(shop.event_bonus_earned == 8)
	assert(shop.special_served == 1)
	assert(GameState.inspiration == 2)
	shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	GameState.day = 8
	GameState.coins = 0
	GameState.inspiration = 0
	var group_shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(group_shop)
	await get_tree().process_frame
	group_shop._spawn_customer()
	var group: Dictionary = group_shop.customers[0]
	assert(group["kind"] == "group")
	assert(group["orders"].size() == 2)
	for cup_index in 2:
		var group_order: Dictionary = group["order"]
		group_shop._on_base(group_order["base"])
		group_shop._on_milk(group_order["milk"])
		for topping in group_order["tops"]:
			group_shop._on_topping(topping)
		group_shop._on_sugar(group_order["sugar"])
		for i in group_shop._shakes_needed():
			group_shop._on_shake()
		group_shop._on_deliver(group)
		if cup_index == 0:
			assert(group_shop.customers.has(group))
			assert(group["group_index"] == 1)
	assert(not group_shop.customers.has(group))
	assert(group_shop.served == 2)
	assert(group_shop.event_bonus_earned == 10)
	assert(group_shop.special_served == 1)
	assert(GameState.inspiration == 4)

	print("[EVENT] passed rotation=6 routed_calendars=3 light=%d/40 trend=%d/40 critic=8 influencer=5/+3buzz group=2cups/+10" % [
		light_count, trend_count])
	Sfx.stop_all()
	group_shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
