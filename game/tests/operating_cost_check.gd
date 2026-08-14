## 批发补货、错杯损耗、周租保护、战役累计与双语 HUD 回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	var original_settings := GameState.settings.duplicate(true)
	GameLocale.set_locale("zh_CN", false)

	var classic := [GameData.bases[0], GameData.milks[1], GameData.toppings[0]]
	assert(OperatingCosts.cup_cost(classic) == 3, "6-point ingredient basket should settle at half-price wholesale cost")
	assert(OperatingCosts.cup_cost([GameData.bases[0], GameData.milks[0]]) == 1)
	assert(OperatingCosts.rent_base(6) == 0)
	assert(OperatingCosts.rent_base(7) == 40)
	assert(OperatingCosts.rent_base(14) == 60)
	assert(OperatingCosts.rent_base(21) == 80)
	assert(OperatingCosts.rent_base(49) == 120)
	assert(OperatingCosts.next_rent_day(1) == 7)
	assert(OperatingCosts.next_rent_day(7) == 7)
	assert(OperatingCosts.next_rent_day(8) == 14)

	GameState.coins = 200
	var normal := OperatingCosts.settle(7, 30, 5)
	assert(normal["stock_paid"] == 30)
	assert(normal["waste_due"] == 5)
	assert(normal["rent_paid"] == 40)
	assert(normal["relief"] == 0)
	assert(GameState.coins == 130)
	assert(normal["next_rent_day"] == 14)

	# Low cash pays stock first, then at most 25% of the remaining balance as rent.
	GameState.coins = 50
	var protected := OperatingCosts.settle(7, 30, 0)
	assert(protected["stock_paid"] == 30)
	assert(protected["rent_paid"] == 5)
	assert(protected["rent_relief"] == 35)
	assert(GameState.coins == 15)

	# No debt: an empty till receives explicit relief instead of becoming negative.
	GameState.coins = 10
	var assisted := OperatingCosts.settle(7, 30, 7)
	assert(assisted["stock_paid"] == 10)
	assert(assisted["rent_paid"] == 0)
	assert(assisted["relief"] == 60)
	assert(GameState.coins == 0)

	GameState.campaign_stats = GameState._new_campaign_stats()
	GameState.record_campaign_day(7, {
		"earned": 180, "served": 14, "stars": 2,
		"operating_cost": 70, "rent_paid": 40, "cost_relief": 0,
	})
	GameState.record_campaign_day(7, {"earned": 999, "operating_cost": 999})
	assert(GameState.campaign_stats["revenue"] == 180)
	assert(GameState.campaign_stats["operating_costs"] == 70)
	assert(GameState.campaign_stats["rent_paid"] == 40)

	GameState.day = 7
	GameState.phase = "day"
	GameState.coins = 210
	GameState.upgrades = {}
	GameState.staff = {}
	GameState.endless = GameState._new_endless_state()
	var shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	shop.running = false
	shop.stock_cost = 18
	shop._update_info()
	assert(shop.hud_cost.text.contains("租金"))
	GameLocale.set_locale("en", false)
	shop._update_info()
	assert(shop.hud_cost.text.contains("Rent"))

	# A corrected-but-matching drink sells, yet cannot inflate Perfect, inspiration,
	# or the clean-execution combo. Internal cup resets remain free.
	shop.day_event = DailyEvents.event_for_day(1)
	shop.running = true
	shop._spawn_customer()
	var corrected_customer: Dictionary = shop.customers[0]
	corrected_customer["order"] = {
		"base": GameData.bases[0], "milk": GameData.milks[1],
		"tops": [], "sugar": GameData.sugar_levels[2],
	}
	shop._render_order_card(corrected_customer)
	GameState.inspiration = 0
	GameState.perfect_total = 0
	shop.perfect = 0
	shop.served = 0
	shop.streak = 2
	shop._on_base(GameData.bases[1])
	shop._on_base(GameData.bases[0])
	shop._on_milk(GameData.milks[1])
	shop._on_sugar(GameData.sugar_levels[2])
	assert(shop.cup_corrections == 1)
	for _shake in shop._shakes_needed():
		shop._on_shake()
	shop._on_deliver(corrected_customer)
	assert(shop.served == 1 and shop.perfect == 0)
	assert(GameState.perfect_total == 0 and GameState.inspiration == 0)
	assert(shop.streak == 0, "a reworked correct cup must break the Perfect combo")
	assert(shop.cup_corrections == 0, "the post-delivery system reset must start a clean cup")

	# Player-initiated discard pays the visible wholesale loss exactly once.
	shop._on_base(GameData.bases[0])
	shop._on_milk(GameData.milks[1])
	shop._on_topping(GameData.toppings[0])
	var discard_cost: int = shop._current_cup_cost()
	var stock_before_discard: int = shop.stock_cost
	var waste_before_discard: int = shop.waste_cost
	shop._refresh_cup()
	assert(shop.reset_button.text.contains(str(discard_cost)))
	shop._on_reset_cup_pressed()
	assert(shop.stock_cost == stock_before_discard + discard_cost)
	assert(shop.waste_cost == waste_before_discard + discard_cost)
	assert(shop.reset_button.disabled and not shop._cup_has_contents())

	# 打烊瞬间在制的杯子必须与手动弃杯一样计入成本/损耗。
	shop._on_base(GameData.bases[0])
	shop._on_milk(GameData.milks[1])
	var leftover_cost: int = shop._current_cup_cost()
	var stock_before_end: int = shop.stock_cost
	var waste_before_end: int = shop.waste_cost
	shop._end_day()
	assert(shop.stock_cost == stock_before_end + leftover_cost,
		"end-of-day must charge the in-flight cup as stock")
	assert(shop.waste_cost == waste_before_end + leftover_cost,
		"end-of-day must charge the in-flight cup as waste")
	assert(not shop.running)
	shop.queue_free()
	GameState.settings = original_settings
	TranslationServer.set_locale(GameState.locale())
	Sfx.stop_all()
	await get_tree().process_frame
	print("[OPERATING_COST] passed wholesale=50% discard=true rework_breaks_perfect=true rent=7d/capped relief=true no_debt=true campaign=true bilingual=true")
	get_tree().quit()
