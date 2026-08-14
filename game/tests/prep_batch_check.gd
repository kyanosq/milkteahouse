## Tea-vat/pearl-pot vertical slice: independent clocks, collection windows,
## per-serving inventory and the final cup reward all have hard assertions.
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameLocale.set_locale("zh_CN", false)
	GameState.day = 9
	GameState.phase = "day"
	GameState.menu = []
	GameState.featured_menu = []
	GameState.dark_menu = []
	GameState.staff = {}
	GameState.upgrades = {}
	GameState.tutorial_completed = true

	var model = load("res://systems/prep_batch.gd").new("tea", 8.0, 4.0, 6.0, 4)
	assert(model.state() == "empty")
	assert(model.start("black_tea"))
	model.advance(7.9)
	assert(model.state() == "brewing" and model.collect().is_empty())
	model.advance(0.1)
	assert(model.state() == "golden")
	var golden: Dictionary = model.collect()
	assert(int(golden["quality"]) == 2 and int(golden["servings"]) == 4)
	model.start("green_tea")
	model.advance(18.1)
	assert(model.state() == "spoiled" and int(model.collect()["quality"]) == 0)

	var shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	await get_tree().process_frame
	var black := _ingredient(GameData.bases, "black_tea")
	var milk := _ingredient(GameData.milks, "fresh_milk")
	var boba := _ingredient(GameData.toppings, "boba")

	# Empty inventory blocks pouring and directs the player back to the station.
	shop.tea_stock["black_tea"] = []
	shop._on_base(black)
	assert(shop.cup_base == null)

	# Both stations run together. Tea reaches golden first while pearls keep cooking.
	shop.tea_batch.start("black_tea")
	shop._on_pearl_batch_pressed()
	shop._update_prep_batches(8.0)
	assert(shop.tea_batch.state() == "golden")
	assert(shop.pearl_batch.state() == "brewing")
	shop._on_tea_batch_pressed()
	shop._update_prep_batches(2.0)
	assert(shop.pearl_batch.state() == "golden")
	shop._on_pearl_batch_pressed()
	assert(shop._tea_stock_count("black_tea") == 4)
	assert(shop.pearl_stock.size() == 7)

	# A golden tea serving plus a golden pearl serving reaches the sale outcome:
	# clean perfect credit and the visible +2 batch bonus.
	shop.tea_stock["black_tea"] = [2]
	shop.pearl_stock = [2]
	shop._spawn_customer()
	var customer: Dictionary = shop.customers.back()
	customer["order"] = {
		"base": black, "milk": milk, "tops": [boba], "sugar": GameData.sugar_levels[2],
	}
	shop._render_order_card(customer)
	shop._reset_cup()
	shop._on_base(black)
	shop._on_milk(milk)
	shop._on_topping(boba)
	shop._on_sugar(GameData.sugar_levels[2])
	assert(shop._cup_batch_quality() == 2)
	while not shop.cup_sealed:
		shop._on_shake()
	var earned_before: int = shop.earned
	shop._on_deliver(customer)
	assert(shop.golden_batches_served == 1)
	assert(shop.perfect == 1)
	assert(shop.earned >= earned_before + 2)

	shop.queue_free()
	Sfx.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	print("[PREP_BATCH] passed parallel=true golden_window=true spoiled=true inventory=true sale_bonus=true")
	get_tree().quit()


func _ingredient(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if String(item.get("id", "")) == item_id:
			return item
	return {}
