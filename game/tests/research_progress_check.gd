## 相性 3×4 图鉴、完成奖励与原料熟练度的纯内存回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	var original_settings := GameState.settings.duplicate(true)
	GameLocale.set_locale("zh_CN", false)
	GameState.affinity_seen = []
	GameState.xp = {}

	assert(ResearchProgress.total_count() == 12)
	assert(ResearchProgress.all_pair_keys().size() == 12)
	_assert_pair("green_tea", "none", "perfect", 6)
	_assert_pair("oolong", "fresh_milk", "perfect", 6)
	_assert_pair("black_tea", "oat_milk", "good", 5)
	_assert_pair("oolong", "coconut_milk", "clash", 0)
	_assert_pair("black_tea", "fresh_milk", "neutral", 0)

	var first := ResearchProgress.record_pair("black_tea", "fresh_milk")
	assert(first["new"] and not first["complete"])
	assert(not ResearchProgress.record_pair("black_tea", "fresh_milk")["new"])
	assert(not ResearchProgress.record_pair("missing", "none")["new"])
	var completion := {}
	for key in ResearchProgress.all_pair_keys():
		var ids := key.split("|")
		var result := ResearchProgress.record_pair(ids[0], ids[1])
		if result["complete"]:
			completion = result
	assert(not completion.is_empty())
	assert(ResearchProgress.seen_count() == 12)
	assert(ResearchProgress.is_complete())
	assert(ResearchProgress.night_budget_bonus() == 2)

	var initial := ResearchProgress.level_progress("boba")
	assert(initial["level"] == 1 and initial["value"] == 0 and initial["max"] == 8)
	GameState.xp["boba"] = 16
	var level_three := ResearchProgress.level_progress("boba")
	assert(level_three["level"] == 3 and level_three["value"] == 0)
	assert(ResearchProgress.level_effect("boba") == GameLocale.text("RESEARCH_MASTERY_EFFECT_ACTIVE"))
	GameState.xp["boba"] = 100
	var capped := ResearchProgress.level_progress("boba")
	assert(capped["level"] == 5 and capped["value"] == 8 and capped["remaining"] == 0)

	var panel: RecipeBookPanel = load("res://ui/recipe_book_panel.gd").new()
	add_child(panel)
	panel.show_panel()
	panel.show_research_tab_for_test()
	assert(panel.visible_pair_count() == 12)
	assert(panel._target_label.text.contains("+2"))
	GameLocale.set_locale("en", false)
	await get_tree().process_frame
	assert(panel._research_tab.text == "Pairings 12/12")
	assert(not panel._target_label.text.contains("RESEARCH_"))
	panel.queue_free()
	GameState.settings = original_settings
	TranslationServer.set_locale(GameState.locale())
	print("[RESEARCH_PROGRESS] passed pairings=12 ratings=true mastery=true permanent_bonus=2 bilingual=true")
	get_tree().quit()


func _assert_pair(base_id: String, milk_id: String, rank: String, score: int) -> void:
	var result := ResearchProgress.pairing(base_id, milk_id)
	assert(result["rank"] == rank, "%s|%s rank mismatch" % [base_id, milk_id])
	assert(result["score"] == score, "%s|%s score mismatch" % [base_id, milk_id])
