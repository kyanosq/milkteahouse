## 市场检验的确定波动、三阶段定级、当日幂等与双语卡片回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	var original_settings := GameState.settings.duplicate(true)
	GameLocale.set_locale("zh_CN", false)
	GameState.day = 9
	GameState.phase = "night"
	GameState.menu = []
	GameState.featured_menu = []
	GameState.market_settlement = {}
	var base_test := _test_item(82, [])
	GameState.tests = [base_test.duplicate(true)]
	var expected := MarketTests.deterministic_score(GameState.tests[0], 9, 1)
	assert(expected >= 74 and expected <= 90)
	var min_offset := 99
	var max_offset := -99
	var offset_total := 0
	var offset_count := 0
	for sample in 100:
		for stage in range(1, 4):
			var sample_test := _test_item(50, [])
			sample_test["name"] = "sample_%d" % sample
			var offset := MarketTests.deterministic_score(sample_test, 9, stage) - 50
			min_offset = mini(min_offset, offset)
			max_offset = maxi(max_offset, offset)
			offset_total += offset
			offset_count += 1
	assert(min_offset == -8 and max_offset == 8)
	assert(absf(float(offset_total) / float(offset_count)) < 1.0, "deterministic variance must remain approximately centered")
	var first := MarketTests.advance(9)
	assert(first["results"].size() == 1)
	assert(first["results"][0]["score"] == expected)
	assert(first["results"][0]["stage"] == 1)
	assert(first["results"][0]["outcome"] == "testing")
	# [P5-1 2026-08-17] 结算结果随行配方字段：结算卡的配方行据此渲染。
	assert(String(first["results"][0].get("base", "")) == "black_tea")
	assert(String(first["results"][0].get("milk", "")) == "fresh_milk")
	assert(first["results"][0].get("toppings", []) == ["boba"])
	assert(int(first["results"][0].get("sugar", -1)) == 50)
	assert(GameState.tests[0]["scores"].size() == 1)
	var repeated := MarketTests.advance(9)
	assert(repeated == first)
	assert(GameState.tests[0]["scores"].size() == 1, "same-day settlement must not append a second score")

	GameState.market_settlement = {}
	GameState.tests = [base_test.duplicate(true)]
	assert(MarketTests.advance(9)["results"][0]["score"] == expected, "same inputs must reproduce the same variance")

	GameState.day = 10
	GameState.market_settlement = {}
	GameState.tests = [_test_item(91, [92, 94])]
	var final := MarketTests.advance(10)
	var final_result: Dictionary = final["results"][0]
	assert(final_result["stage"] == 3)
	assert(final_result["outcome"] == "hit")
	assert(final_result["price"] == 18)
	assert(GameState.tests.is_empty())
	assert(GameState.menu.size() == 1)
	assert(MenuCatalog.formula_available(GameState.menu[0]))

	GameState.day = 11
	GameState.market_settlement = {}
	GameState.tests = [_test_item(30, [30, 30])]
	var inspiration_before := GameState.inspiration
	var failed: Dictionary = MarketTests.advance(11)["results"][0]
	assert(failed["outcome"] == "failed")
	assert(failed["refund"] == 3)
	assert(GameState.inspiration == inspiration_before + 3)

	# [P5-3 2026-08-17] 失败线 62 → 76：deterministic_score 三晚偏移强相关（和 ≥ -14），
	# 上架最低 80 分杯的可达最差均分 = 75.33 —— 搜索和 = -14 的最差样本钉「failed」可达。
	assert(int(MarketTests.TIER_REGULAR) == 76)
	GameState.day = 12
	GameState.market_settlement = {}
	var fail_name := ""
	for sample in range(4000):
		var candidate := "fail_%d" % sample
		var offset_sum := 0
		for stage in range(1, 4):
			var probe := _test_item(80, [])
			probe["name"] = candidate
			offset_sum += MarketTests.deterministic_score(probe, 9 + stage, stage) - 80
		if offset_sum <= -14:
			fail_name = candidate
			break
	assert(not fail_name.is_empty(),
		"quality-80 cups must have reachable failing variance under the 76 tier line")
	var shelf_test := _test_item(80, [])
	shelf_test["name"] = fail_name
	shelf_test["scores"] = [
		MarketTests.deterministic_score(shelf_test, 9, 1),
		MarketTests.deterministic_score(shelf_test, 10, 2),
	]
	GameState.tests = [shelf_test]
	var failed_shelf: Dictionary = MarketTests.advance(12)["results"][0]
	assert(failed_shelf["stage"] == 3)
	assert(failed_shelf["outcome"] == "failed",
		"a shelfed 80-quality cup can now fail the three-night average")
	assert(failed_shelf["refund"] == 3)

	var panel: NightSettlementPanel = load("res://ui/night_settlement_panel.gd").new()
	add_child(panel)
	panel.show_results(9, first)
	assert(panel.result_card_count() == 1)
	assert(_panel_contains_prefix(panel, GameLocale.text("MARKET_SETTLEMENT_FORMULA", ["\uFFFF"]).split("\uFFFF")[0]),
		"settlement cards must show each drink's formula for post-hoc review")
	assert(_panel_contains(panel, GameLocale.ingredient_name(RecipeJournal.ingredient("black_tea"))),
		"the formula row must render the drink's real recipe (P5-1)")
	assert(panel._subtitle.text.contains(str(int(MarketTests.TIER_HIT))),
		"the tier cutoff numbers must be visible in the panel header")
	assert(panel._subtitle.text.contains(str(int(MarketTests.TIER_REGULAR))),
		"the raised 74 failure line must be disclosed in the panel header")
	assert(panel._continue.text.contains("10"))
	GameLocale.set_locale("en", false)
	panel.show_results(9, first)
	assert(panel._title.text == "Day 9 · Market Test")
	assert(not panel._subtitle.text.contains("MARKET_"))
	panel.queue_free()

	# 退出后重进研发室必须直接恢复已锁定结算，不能回到可试作状态。
	GameState.day = 9
	GameState.phase = "night"
	GameState.market_settlement = first.duplicate(true)
	GameState.night_budget = 8
	GameState.night_budget_day = 9
	GameState.research_brief = {}
	var resumed_lab: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(resumed_lab)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(resumed_lab.overlay.visible)
	assert(_find_settlement_panel(resumed_lab.overlay) != null)
	resumed_lab.queue_free()
	GameState.settings = original_settings
	TranslationServer.set_locale(GameState.locale())
	print("[MARKET_TEST] passed deterministic=true variance=8 stages=3 idempotent=true tiers=true tier_regular=76 refund=3 failed_reachable=true panel=true formula_row=true bilingual=true")
	get_tree().quit()


func _test_item(quality: int, scores: Array) -> Dictionary:
	return {
		"name": "测试云", "quality": quality, "scores": scores.duplicate(),
		"base": "black_tea", "milk": "fresh_milk", "toppings": ["boba"], "sugar": 50,
	}


func _find_settlement_panel(node: Node) -> NightSettlementPanel:
	if node is NightSettlementPanel:
		return node
	for child in node.get_children():
		var found := _find_settlement_panel(child)
		if found != null:
			return found
	return null


func _panel_contains_prefix(node: Node, prefix: String) -> bool:
	if node is Label and String(node.text).begins_with(prefix):
		return true
	for child in node.get_children():
		if _panel_contains_prefix(child, prefix):
			return true
	return false


func _panel_contains(node: Node, needle: String) -> bool:
	if node is Label and String(node.text).contains(needle):
		return true
	for child in node.get_children():
		if _panel_contains(child, needle):
			return true
	return false
