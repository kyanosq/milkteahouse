## 店铺升级逻辑回归：价格、满级、派生效率效果与余额扣除。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.coins = 2000
	GameState.upgrades = {}
	GameState.staff = {}

	assert(UpgradeCatalog.next_cost("comfort") == 60)
	assert(UpgradeCatalog.total_tree_cost() == 2930)
	var reserve := UpgradeCatalog.next_day_reserve(6)
	assert(int(reserve["day"]) == 7 and int(reserve["rent"]) == 40)
	assert(int(reserve["wage"]) == 0 and int(reserve["investable"]) == 1960)
	assert(UpgradeCatalog.buy("comfort", false))
	assert(UpgradeCatalog.level("comfort") == 1)
	assert(is_equal_approx(UpgradeCatalog.patience_multiplier(), 1.18))
	assert(GameState.coins == 1940)
	assert(UpgradeCatalog.next_cost("comfort") == 220)

	assert(UpgradeCatalog.buy("shaker", false))
	assert(UpgradeCatalog.shakes_needed() == 4)
	assert(UpgradeCatalog.buy("smart_sugar", false))
	assert(UpgradeCatalog.has_smart_sugar())
	assert(UpgradeCatalog.buy("tip_jar", false))
	assert(UpgradeCatalog.tip_bonus() == 1)

	GameState.upgrades["comfort"] = 3
	assert(UpgradeCatalog.next_cost("comfort") == -1)
	assert(not UpgradeCatalog.buy("comfort", false))
	GameState.upgrades["shaker"] = 2
	assert(UpgradeCatalog.next_cost("shaker") == 600)
	print("[UPGRADE] passed coins=%d levels=%d/%d patience=%.2f shakes=%d auto_sugar=%s tip=%d" % [
		GameState.coins, UpgradeCatalog.total_levels(), UpgradeCatalog.total_max_levels(),
		UpgradeCatalog.patience_multiplier(), UpgradeCatalog.shakes_needed(),
		str(UpgradeCatalog.has_smart_sugar()), UpgradeCatalog.tip_bonus()])
	get_tree().quit()
