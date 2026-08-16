## 夜间预算必须跨场景/保存点精确恢复，不能因升级、委托或退出重进而丢失/刷新。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.settings = {"sfx_volume": 0.0, "music_volume": 0.0, "reduced_motion": true}
	GameState.day = 9
	GameState.phase = "night"
	GameState.inspiration = 10
	GameState.buzz = 3
	GameState.menu = []
	GameState.featured_menu = []
	GameState.affinity_seen = []
	GameState.xp = {}
	GameState.research_brief = _completed_brief(9)
	GameState.market_settlement = {}
	MenuCatalog.register_legend(RecipeJournal.recipe("classic_boba"))
	GameState.night_budget = -1
	GameState.night_budget_day = 0
	GameState.night_performance_remaining = 0

	var first: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(first)
	await get_tree().process_frame
	assert(first.budget == 16) # base/menu 10 + 持久库装入 6，最多 8 次试作
	assert(GameState.inspiration == 7)
	assert(GameState.buzz == 0)
	assert(GameState.night_budget == 16)
	assert(GameState.night_budget_day == 9)
	assert(GameState.night_performance_remaining == 6)
	assert(first.info_label.text == GameLocale.text("NIGHT_HUD", [9, 16, 7]))
	first._on_base(GameData.bases[0])
	first._on_milk(GameData.milks[0])
	first._on_sugar(GameData.sugar_levels[0])
	first._on_try()
	assert(first.budget == 14)
	assert(GameState.night_budget == 14)
	assert(GameState.night_performance_remaining == 6,
		"nightly free budget must be consumed before saved inspiration")
	var buzz_after_try := GameState.buzz
	first.queue_free()
	await get_tree().process_frame

	var resumed: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(resumed)
	await get_tree().process_frame
	assert(resumed.budget == 14)
	assert(GameState.night_budget == 14)
	assert(GameState.inspiration == 7)
	assert(GameState.buzz == buzz_after_try)
	assert(GameState.night_performance_remaining == 6)
	resumed._on_sleep()
	assert(GameState.inspiration == 13,
		"all unused earned inspiration must survive closing and the following day")
	assert(GameState.night_performance_remaining == 0)
	resumed._bank_unspent_performance()
	assert(GameState.inspiration == 13, "closing refund must be idempotent")
	resumed.queue_free()
	await get_tree().process_frame

	GameState.day = 10
	GameState.inspiration = 0
	GameState.buzz = 0
	GameState.night_budget = -1
	GameState.night_budget_day = 0
	GameState.night_performance_remaining = 0
	GameState.affinity_seen = ResearchProgress.all_pair_keys()
	GameState.research_brief = _completed_brief(10)
	var completed: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(completed)
	await get_tree().process_frame
	assert(completed.budget == 12) # base 8 + featured menu 2 + completed notebook 2
	completed.queue_free()
	await get_tree().process_frame

	GameState.day = 11
	GameState.night_budget = -1
	GameState.night_budget_day = 0
	GameState.night_performance_remaining = 0
	GameState.affinity_seen = ResearchProgress.all_pair_keys()
	GameState.affinity_seen.erase("black_tea|none")
	GameState.research_brief = _completed_brief(11)
	var finishing: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(finishing)
	await get_tree().process_frame
	var before_finish: int = finishing.budget
	finishing._on_base(GameData.bases[0])
	finishing._on_milk(GameData.milks[0])
	finishing._on_sugar(GameData.sugar_levels[0])
	finishing._on_try()
	assert(finishing.budget == before_finish) # 试作 -2，全图鉴完成即时 +2
	assert(finishing.result_label.text.contains(GameLocale.text("NIGHT_PAIR_MASTERY", [2])))
	finishing.queue_free()
	await get_tree().process_frame

	print("[NIGHT_RESUME] passed capped=16 spent=14 resumed=14 banked=13 completed_bonus=2 instant_refund=2 no_refresh=true")
	Sfx.stop_all()
	await get_tree().process_frame
	get_tree().quit()


func _completed_brief(day_number: int) -> Dictionary:
	return {
		"type": "balanced", "assigned_day": day_number, "quality": 75,
		"progress": 1, "target": 1, "reward": 2,
		"completed": true, "completed_day": day_number,
	}
