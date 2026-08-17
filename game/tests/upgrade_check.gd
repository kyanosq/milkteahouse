## 店铺升级逻辑回归：价格、满级、派生效率效果与余额扣除。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.coins = 2000
	GameState.upgrades = {}
	GameState.staff = {}

	assert(UpgradeCatalog.next_cost("comfort") == 60)
	assert(UpgradeCatalog.total_tree_cost() == 6110, "1.0 tree: 2930 base + 3180 premium tiers")
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
	assert(UpgradeCatalog.auto_sugar_after_milk())
	assert(UpgradeCatalog.buy("tip_jar", false))
	assert(UpgradeCatalog.tip_bonus() == 1)

	# 高级档（D1②）：四级定价/效果/递减曲线。
	GameState.upgrades["comfort"] = 3
	assert(UpgradeCatalog.next_cost("comfort") == 700)
	assert(UpgradeCatalog.buy("comfort", false))
	assert(absf(UpgradeCatalog.patience_multiplier() - 1.66) < 0.001,
		"tier IV adds a diminished +12% on top of +54%")
	GameState.upgrades["shaker"] = 3
	assert(UpgradeCatalog.next_cost("shaker") == 760)
	GameState.upgrades["shaker"] = 4
	assert(UpgradeCatalog.shakes_needed() == 1, "tier IV shakes once per cup")
	GameState.upgrades["smart_sugar"] = 2
	assert(UpgradeCatalog.auto_sugar_after_base(), "tier II matches sugar right after the base")
	GameState.upgrades["tip_jar"] = 4
	assert(UpgradeCatalog.tip_bonus() == 4)

	# 互斥定位对：Day11 门 + 二选一 + 效果钩子。
	GameState.day = 10
	assert(not UpgradeCatalog.buy_positioning("positioning_flavor", false),
		"positionings must stay locked before day 11")
	GameState.day = 11
	GameState.coins = 700
	# [S1-D2 2026-08-17] 死档守卫：已购智能糖台（≥1 级）时「风味」与其效果在
	# auto_sugar_after_milk 完全同源——禁购（600 币不得买 0 效果）并暴露冗余钩子。
	assert(UpgradeCatalog.positioning_redundant("positioning_flavor"))
	assert(not UpgradeCatalog.buy_positioning("positioning_flavor", false),
		"flavor must be blocked when smart sugar is owned (identical effect)")
	GameState.upgrades.erase("smart_sugar")
	assert(not UpgradeCatalog.positioning_redundant("positioning_flavor"))
	assert(UpgradeCatalog.buy_positioning("positioning_flavor", false))
	assert(GameState.coins == 100)
	assert(UpgradeCatalog.positioning() == "positioning_flavor")
	assert(UpgradeCatalog.perfect_bonus() == 0)
	assert(not UpgradeCatalog.buy_positioning("positioning_craft", false),
		"the opposite positioning must be permanently unavailable")
	# 反向冗余（S1-D2）：先风味后糖台一级——不禁购（糖台二级的必经前置），
	# 但 smart_sugar_redundant() 让面板能给警告性标注。
	GameState.coins = 700
	assert(UpgradeCatalog.smart_sugar_redundant())
	assert(UpgradeCatalog.buy("smart_sugar", false))
	assert(not UpgradeCatalog.smart_sugar_redundant())
	GameState.upgrades.erase("positioning_flavor")
	GameState.coins = 700
	assert(UpgradeCatalog.buy_positioning("positioning_craft", false))
	assert(UpgradeCatalog.perfect_bonus() == 1)
	assert(UpgradeCatalog.auto_sugar_after_milk(), "smart sugar I alone still automates sugar")
	# [P2-F2 2026-08-17] 定位按等价等级（各 1 级）计入评级分母/分子：14+2=16。
	assert(UpgradeCatalog.total_max_levels() == 16)
	GameState.upgrades["smart_sugar"] = 2
	assert(UpgradeCatalog.total_levels() == 15,
		"full item tree + one positioning = 15/16 equivalent levels")

	print("[UPGRADE] passed coins=%d levels=%d/%d patience=%.2f shakes=%d auto_sugar=%s tip=%d positioning=%s" % [
		GameState.coins, UpgradeCatalog.total_levels(), UpgradeCatalog.total_max_levels(),
		UpgradeCatalog.patience_multiplier(), UpgradeCatalog.shakes_needed(),
		str(UpgradeCatalog.auto_sugar_after_milk()), UpgradeCatalog.tip_bonus(),
		UpgradeCatalog.positioning()])
	get_tree().quit()
