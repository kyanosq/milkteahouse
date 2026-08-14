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

	var panel: NightSettlementPanel = load("res://ui/night_settlement_panel.gd").new()
	add_child(panel)
	panel.show_results(9, first)
	assert(panel.result_card_count() == 1)
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
	print("[MARKET_TEST] passed deterministic=true variance=8 stages=3 idempotent=true tiers=true refund=3 panel=true bilingual=true")
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
