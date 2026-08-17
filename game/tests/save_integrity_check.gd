## 存档完整性回归：损坏防护与经济防复制，不做版本迁移（新项目，无历史存档）。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.day = 12
	GameState.phase = "day"

	# 顶层能解析但嵌套结构类型错误时必须回退默认而不是在加载时崩溃。
	GameState._apply_save_data({
		"legacy": "corrupt", "settings": ["corrupt"], "key_bindings": "corrupt",
	})
	assert(GameState.legacy["routes_cleared"].is_empty())
	assert(int(GameState.legacy["best_score"]) == 0)
	assert(GameState.settings["sfx_volume"] == 0.75)
	assert(GameState.settings["music_volume"] == 0.55)
	assert(int(GameState.settings["key_bindings"]["game_pause"]) == KEY_ESCAPE)

	# 员工动态字段从作者候选表重建：坏档不能伪造工资或特质身份。
	GameState._apply_save_data({
		"day": 12, "phase": "day",
		"staff": {
			"id": "acheng", "wage": 999, "trait_id": "unknown", "trait_revealed": true,
			"days_worked": 4, "rest_day": 13, "wage_shortfall": 999, "wage_shortfalls": 2,
		},
	})
	assert(GameState.staff["id"] == "acheng")
	assert(GameState.staff["wage"] == 14 and GameState.staff["trait_id"] == "perfectionist")
	assert(GameState.staff["rest_day"] == 13 and GameState.staff["wage_shortfall"] == 14)
	assert(GameState.staff["wage_shortfalls"] == 2)

	# 黑暗菜单：未知类型丢弃、序号夹取、可恢复公式完整保留、上限 3 格。
	var dark: Array = GameState._normalize_dark_menu([
		{"kind": "unknown", "name": "垃圾"},
		{"kind": "legend", "recipe_id": "xiangcai_fantasy", "sales": 7},
		{"kind": "mystery", "serial": 404},
		"raw string entry",
		{"kind": "mystery", "serial": 9, "base": "black_tea", "milk": "fresh_milk",
			"toppings": ["boba"], "sugar": 50, "quality": 18, "price": 14, "sales": 6},
	])
	assert(dark.size() == 3, "unknown kinds and raw strings must be dropped, cap at 3")
	assert(dark[0] == {"kind": "legend", "recipe_id": "xiangcai_fantasy", "sales": 7})
	assert(int(dark[1]["serial"]) == 99, "out-of-range serials must clamp")
	assert(dark[2]["base"] == "black_tea" and dark[2]["toppings"] == ["boba"])
	assert(int(dark[2]["sales"]) == 6)
	assert(MenuCatalog.dark_formula_available(dark[2]))

	# 无尽状态：负数清零、合法字段保留、未知合约丢弃。
	var endless: Dictionary = GameState._normalize_endless_state({
		"stamps": -9, "streak": 5, "best_streak": 1,
		"active": {"id": "unknown", "target_day": 99},
	})
	assert(int(endless["stamps"]) == 0)
	assert(int(endless["best_streak"]) == 5)
	assert(endless["active"].is_empty())

	# 相性格点：去重 + 未知原料丢弃。
	GameState._apply_save_data({
		"day": 12, "phase": "day",
		"affinity_seen": ["black_tea|fresh_milk", "green_tea|none", "green_tea|none", "missing|none"],
	})
	assert(GameState.affinity_seen == ["black_tea|fresh_milk", "green_tea|none"])

	# 研究单：损坏字段回安全形态；品质阶梯缺省为最低档、越界夹取。
	GameState._apply_save_data({
		"day": 12, "phase": "day",
		"research_target": "missing_recipe",
		"research_brief": {"type": "pair", "base": "missing", "milk": "none"},
	})
	assert(GameState.research_target.is_empty())
	assert(GameState.research_brief.is_empty())
	assert(GameState.brief_quality_step == 0, "a missing ladder rung must default to 0")
	GameState._apply_save_data({"day": 12, "phase": "day", "brief_quality_step": 9})
	assert(GameState.brief_quality_step == 2, "out-of-range rungs must clamp to the ladder top")

	# 市场检验：非当夜/陈旧数据清空；合法最坏规模（24 卡）完整往返。
	GameState._apply_save_data({
		"day": 12, "phase": "day",
		"market_settlement": {"day": 11, "results": [{"outcome": "testing"}]},
	})
	assert(GameState.market_settlement.is_empty(), "stale settlement must clear")
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
	assert(String(GameState.market_settlement["results"][5]["name"]).length() == 40,
		"a writer-length name must round-trip unchanged")
	# [P5-1 2026-08-17] 配方字段白名单同步：结算卡配方行重进夜间不丢。
	assert(String(GameState.market_settlement["results"][5].get("base", "")) == "black_tea")
	assert(String(GameState.market_settlement["results"][5].get("milk", "")) == "fresh_milk")
	assert(GameState.market_settlement["results"][5].get("toppings", []) == [])
	assert(int(GameState.market_settlement["results"][5].get("sugar", -1)) == 50)
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

	print("[SAVE_INTEGRITY] passed version=v%d corrupt_guard=true staff_forgery=true dark_menu=true endless_clamps=true affinity=true research_brief=true brief_ladder=true market_settlement=true day_open_rollback=true atomic_backup=true truncated_recovery=true" % GameState.SAVE_VERSION)
	get_tree().quit()
