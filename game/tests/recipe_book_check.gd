## 配方图鉴、分阶段线索、研究目标与双语布局的纯内存回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	var original_settings := GameState.settings.duplicate(true)
	GameLocale.set_locale("zh_CN", false)
	GameState.day = 4
	GameState.discovered = ["classic_boba", "jasmine_coco"]
	GameState.dark_discovered = ["xiangcai_fantasy"]
	GameState.research_target = ""
	GameState.affinity_seen = ["black_tea|fresh_milk", "green_tea|none"]

	assert(RecipeJournal.recipes(false).size() == 10)
	assert(RecipeJournal.recipes(true).size() == 3)
	assert(RecipeJournal.unlock_day(RecipeJournal.recipe("taro_boba")) == 5)
	assert(RecipeJournal.unlock_day(RecipeJournal.recipe("zheergen_rage")) == 8)
	assert(not RecipeJournal.is_available(RecipeJournal.recipe("taro_boba")))
	assert(RecipeJournal.clue(RecipeJournal.recipe("taro_boba")).contains("第 5 天"))
	assert(not RecipeJournal.set_target("taro_boba", false), "locked recipe cannot become a target")

	var formula := RecipeJournal.formula(RecipeJournal.recipe("classic_boba"))
	assert(formula.contains("阿萨姆红茶"))
	assert(formula.contains("鲜奶"))
	assert(formula.contains("珍珠"))
	assert(formula.contains("五分糖"))

	GameState.day = 9
	assert(RecipeJournal.set_target("oolong_pudding", false))
	assert(GameState.research_target == "oolong_pudding")
	assert(RecipeJournal.target_display_name().contains("#9"), "undiscovered target must remain non-spoiler")
	assert(not RecipeJournal.set_target("missing_recipe", false))

	var panel: RecipeBookPanel = load("res://ui/recipe_book_panel.gd").new()
	add_child(panel)
	panel.show_panel()
	assert(panel.visible_card_count() == 10)
	panel.show_dark_tab_for_test()
	assert(panel.visible_card_count() == 3)
	panel.show_research_tab_for_test()
	assert(panel.visible_pair_count() == 12)
	assert(panel._research_tab.text.contains("2/12"))
	GameLocale.set_locale("en", false)
	await get_tree().process_frame
	assert(panel._title_label.text == "Recipe Journal")
	assert(not panel._target_label.text.contains("RECIPE_"))

	assert(RecipeJournal.complete_if_target("oolong_pudding", false))
	assert(GameState.research_target.is_empty())
	assert(not RecipeJournal.complete_if_target("oolong_pudding", false))
	panel.queue_free()
	GameState.settings = original_settings
	TranslationServer.set_locale(GameState.locale())
	print("[RECIPE_BOOK] passed regular=10 dark=3 pairings=12 clues=true formula=true target=true bilingual=true")
	get_tree().quit()
