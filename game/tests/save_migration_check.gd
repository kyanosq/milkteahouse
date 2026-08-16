## 旧版缺字段与 v21 当前字段的纯内存迁移回归；不写入真实存档。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	var legacy_v5 := {
		"day": 9, "phase": "night", "coins": 321, "inspiration": 7,
		"settings": {"sound_volume": 0.42, "reduced_motion": true},
		"legacy": {"campaigns_completed": 2, "best_grade": "A", "best_score": 74},
	}
	GameState._apply_save_data(legacy_v5)
	assert(GameState.day == 9)
	assert(GameState.phase == "night")
	assert(GameState.coins == 321)
	assert(is_equal_approx(GameState.sfx_volume(), 0.42))
	assert(is_equal_approx(GameState.music_volume(), 0.55))
	assert(GameState.reduced_motion())
	assert(GameState.haptics_enabled(), "legacy saves default haptics on")
	assert(GameState.endless == GameState._new_endless_state())
	assert(GameState.night_budget == -1)
	assert(GameState.night_performance_remaining == 0)
	assert(GameState.new_shop_route.is_empty())
	assert(GameState.legacy.get("routes_cleared", []).is_empty())

	# v20 正好退出在研发室时，没有足够信息反推旧预算中多少来自
	# 持久灵感。保留整份旧预算，但不凭空标记可退回额。
	GameState._apply_save_data({
		"save_version": 20, "day": 12, "phase": "night", "inspiration": 4,
		"night_budget": 11, "night_budget_day": 12,
	})
	assert(GameState.night_budget == 11)
	assert(GameState.inspiration == 4)
	assert(GameState.night_performance_remaining == 0)

	var current_v14 := {
		"save_version": GameState.SAVE_VERSION,
		"day": 16, "phase": "night", "coins": 880,
		"new_shop_route": "trend",
		"legacy": {"campaigns_completed": 3, "best_grade": "S", "best_score": 91,
			"routes_cleared": ["rush", "rush", "missing", "trend"]},
		"night_budget": 17, "night_budget_day": 16,
		"night_performance_remaining": 6,
		"buzz_traffic": 7, "buzz_traffic_day": 17,
		"research_target": "oolong_pudding",
		"research_brief": {
			"type": "pair", "assigned_day": 16, "base": "oolong", "milk": "oat_milk",
			"progress": 0, "target": 1, "reward": 99, "completed": false,
		},
		"brief_quality_step": 1,
		"market_settlement": {
			"day": 16, "had_tests": true,
			"results": [{"name": "测试云", "stage": 2, "score": 84, "average": 82.5, "trend": 3, "outcome": "testing"}],
		},
		"staff": {
			"id": "acheng", "wage": 999, "trait_id": "unknown", "trait_revealed": true,
			"days_worked": 4, "rest_day": 17, "wage_shortfall": 999, "wage_shortfalls": 2,
		},
		"menu": [{"name": "经典珍珠奶茶", "tier": "普通", "price": 12}],
		"dark_menu": ["香菜狂想曲", "Mystery Drink #2", {"kind": "mystery", "serial": 7}, "discarded overflow"],
		"featured_menu": ["legend:classic_boba"], "menu_last_hype_day": 15,
		"affinity_seen": ["black_tea|fresh_milk", "green_tea|none", "green_tea|none", "missing|none"],
		"endless": {
			"stamps": 4, "completed": 4, "failed": 2, "streak": 2, "best_streak": 3,
			"active": {
				"id": "streak_stage", "name": "黄金连击擂台", "target_day": 16,
				"target": 28, "cost": 120, "refund": 42,
			},
		},
		"settings": {"sfx_volume": 0.8, "music_volume": 0.5, "haptics": false},
	}
	GameState._apply_save_data(current_v14)
	MenuCatalog.ensure_normalized()
	assert(int(GameState.endless["stamps"]) == 4)
	assert(int(GameState.endless["best_streak"]) == 3)
	assert(GameState.endless["active"]["id"] == "streak_stage")
	assert(EndlessContracts.active_for_day(16)["target"] == 28)
	assert(GameState.night_budget == 17)
	assert(GameState.night_performance_remaining == 6)
	assert(GameState.buzz_traffic == 7 and GameState.buzz_traffic_day == 17)
	assert(GameState.research_target == "oolong_pudding")
	assert(GameState.research_brief["type"] == "pair")
	assert(GameState.research_brief["reward"] == 2)
	assert(GameState.research_brief["assigned_day"] == 16)
	assert(GameState.brief_quality_step == 1, "the quality-ladder rung must persist")
	assert(GameState.market_settlement["day"] == 16)
	assert(GameState.market_settlement["results"][0]["score"] == 84)
	assert(GameState.staff["id"] == "acheng")
	assert(GameState.staff["wage"] == 14 and GameState.staff["trait_id"] == "perfectionist")
	assert(GameState.staff["rest_day"] == 17 and GameState.staff["wage_shortfall"] == 14)
	assert(GameState.staff["wage_shortfalls"] == 2)
	assert(GameState.featured_menu == ["legend:classic_boba"])
	assert(GameState.menu[0]["base"] == "black_tea")
	assert(GameState.dark_menu.size() == 3)
	assert(GameState.dark_menu[0] == {"kind": "legend", "recipe_id": "xiangcai_fantasy"})
	assert(GameState.dark_menu[1] == {"kind": "mystery", "serial": 2})
	assert(GameState.dark_menu[2] == {"kind": "mystery", "serial": 7})
	var recoverable_dark := GameState._normalize_dark_menu([{
		"kind": "mystery", "serial": 9, "base": "black_tea", "milk": "fresh_milk",
		"toppings": ["boba"], "sugar": 50, "quality": 18, "price": 14, "sales": 6,
	}])
	assert(recoverable_dark[0]["base"] == "black_tea")
	assert(recoverable_dark[0]["toppings"] == ["boba"])
	assert(int(recoverable_dark[0]["sales"]) == 6)
	assert(MenuCatalog.dark_formula_available(recoverable_dark[0]))
	assert(GameState.menu_last_hype_day == 15)
	assert(GameState.affinity_seen == ["black_tea|fresh_milk", "green_tea|none"])
	assert(GameState.new_shop_route == "trend")
	assert(GameState.legacy["routes_cleared"] == ["rush", "trend"])
	assert(not GameState.haptics_enabled())

	var corrupt := GameState._normalize_endless_state({
		"stamps": -9, "streak": 5, "best_streak": 1,
		"active": {"id": "unknown", "target_day": 99},
	})
	assert(int(corrupt["stamps"]) == 0)
	assert(int(corrupt["best_streak"]) == 5)
	assert(corrupt["active"].is_empty())
	GameState._apply_save_data({
		"research_target": "missing_recipe",
		"research_brief": {"type": "pair", "base": "missing", "milk": "none"},
		"night_budget": 4, "night_budget_day": 99,
		"night_performance_remaining": 999,
	})
	assert(GameState.research_target.is_empty())
	assert(GameState.research_brief.is_empty())
	assert(GameState.market_settlement.is_empty())
	assert(GameState.night_performance_remaining == 0)
	# v22 存档没有品质阶梯字段：默认最低档；越界值被夹回 [0, 2]。
	GameState._apply_save_data({"save_version": 22, "day": 3, "phase": "day"})
	assert(GameState.brief_quality_step == 0, "a v22 save must default to ladder rung 0")
	GameState._apply_save_data({"save_version": GameState.SAVE_VERSION, "day": 3, "phase": "day", "brief_quality_step": 9})
	assert(GameState.brief_quality_step == 2, "out-of-range rungs must clamp to the ladder top")
	assert(int(GameState.campaign_stats["operating_costs"]) == 0)
	assert(int(GameState.campaign_stats["rent_paid"]) == 0)
	assert(int(GameState.campaign_stats["cost_relief"]) == 0)
	assert(int(GameState.campaign_stats["staff_shortfalls"]) == 0)
	assert(int(GameState.campaign_stats["staff_rest_days"]) == 0)
	assert(int(GameState.campaign_stats["route_bonus"]) == 0)
	assert(GameState.new_shop_route.is_empty())
	assert(GameState.haptics_enabled(), "missing settings must restore safe haptics default")

	# 顶层能解析但嵌套结构类型错误时必须回退默认而不是在加载时崩溃。
	GameState._apply_save_data({
		"legacy": "corrupt", "settings": ["corrupt"], "key_bindings": "corrupt",
	})
	assert(GameState.legacy["routes_cleared"].is_empty())
	assert(int(GameState.legacy["best_score"]) == 0)
	assert(GameState.settings["sfx_volume"] == 0.75)
	assert(int(GameState.settings["key_bindings"]["game_pause"]) == KEY_ESCAPE)

	# 市场检验结算的合法最坏规模必须完整往返：8 试做/晚 × 3 晚 = 24 卡，
	# 40 字名称（写入侧上限）不允许被加载侧改写。
	var stress_results: Array = []
	for i in 24:
		stress_results.append({
			"name": "测试新品%02d" % i + "字".repeat(36), "score": 80 + i,
			"stage": (i % 3) + 1, "outcome": "testing",
			"quality": 84, "base": "black_tea", "milk": "fresh_milk",
			"toppings": [], "sugar": 50,
		})
	GameState.day = 16
	GameState.phase = "night"
	GameState._apply_save_data({
		"day": 16, "phase": "night", "market_settlement": {
			"day": 16, "settled": true, "results": stress_results,
		},
	})
	assert(GameState.market_settlement["results"].size() == 24,
		"the legal worst-case settlement must survive load without dropping cards")
	var roundtrip_name: String = GameState.market_settlement["results"][5]["name"]
	assert(roundtrip_name.length() == 40,
		"a writer-length name must round-trip unchanged")
	GameState.market_settlement = {}

	# 日中存档包含已入账收入；恢复未结算的白天必须回滚到开店快照，堵住重玩重复收入。
	GameState._apply_save_data({
		"day": 12, "phase": "day", "coins": 520, "buzz": 9, "inspiration": 14,
		"perfect_total": 27, "xp": {"black_tea": 9},
		"day_open": {"day": 12, "coins": 300, "buzz": 4, "inspiration": 6,
			"perfect_total": 22, "xp": {"black_tea": 3}},
	})
	assert(GameState.coins == 300 and GameState.buzz == 4, "same-day resume must roll back banked income")
	assert(GameState.inspiration == 6 and GameState.perfect_total == 22)
	assert(GameState.xp == {"black_tea": 3})
	GameState._apply_save_data({"day": 12, "phase": "day", "coins": 520})
	assert(GameState.coins == 520, "a save without a day-open snapshot must keep loaded values")
	GameState._apply_save_data({"day": 13, "phase": "day", "coins": 520,
		"day_open": {"day": 12, "coins": 300}})
	assert(GameState.coins == 520, "a stale day-open snapshot must not roll back a new day")
	GameState._apply_save_data({"day": 12, "phase": "night", "coins": 520,
		"day_open": {"day": 12, "coins": 300}})
	assert(GameState.coins == 520, "night-phase saves must never roll back economy")
	GameState.day_open = {}

	# Real-disk durability: every replacement is validated, the previous valid
	# snapshot becomes a backup, and a truncated primary restores automatically.
	var durability_path := "/private/tmp/milkteahouse_save_durability_test.json"
	var durability_backup := "/private/tmp/milkteahouse_save_durability_test.backup.json"
	for path in [durability_path, durability_path + ".tmp", durability_backup, durability_backup + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert(GameState._write_save_data({"day": 3, "phase": "night"}, durability_path, durability_backup),
		GameState.last_save_error)
	assert(GameState._write_save_data({"day": 4, "phase": "day"}, durability_path, durability_backup),
		GameState.last_save_error)
	assert(GameState._read_save_data(durability_backup)["day"] == 3)
	var truncated := FileAccess.open(durability_path, FileAccess.WRITE)
	assert(truncated != null)
	truncated.store_string("{ truncated")
	truncated.close()
	assert(GameState._read_save_data(durability_path) == null)
	GameState.save_recovered = false
	var recovered: Variant = GameState._load_save_data_with_backup(
		durability_path, durability_backup, true)
	assert(recovered is Dictionary and recovered["day"] == 3)
	assert(GameState.save_recovered)
	assert(GameState._read_save_data(durability_path)["day"] == 3)
	for path in [durability_path, durability_path + ".tmp", durability_backup, durability_backup + ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	print("[SAVE_MIGRATION] passed legacy=v5 current=v%d haptics=true dark_menu_formulas=true buzz_traffic=true affinity_seen=true research_brief=true brief_ladder=true market_settlement=true endless_defaults=true active_contract=true night_budget=true night_performance=true research_target=true featured_menu=true corrupt_guard=true atomic_backup=true truncated_recovery=true" % GameState.SAVE_VERSION)
	get_tree().quit()
