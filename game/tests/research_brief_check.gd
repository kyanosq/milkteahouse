## 研究单的确定生成、跨日持久、单日防刷与三种目标回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	var original_settings := GameState.settings.duplicate(true)
	GameLocale.set_locale("zh_CN", false)
	GameState.day = 1
	GameState.affinity_seen = []
	GameState.xp = {}
	GameState.research_brief = {}

	var pair := ResearchBriefs.ensure_for_day(1)
	assert(pair["type"] == "pair")
	assert(int(pair["assigned_day"]) == 1)
	assert(not ResearchProgress.is_seen(String(pair["base"]), String(pair["milk"])))
	assert(int(RecipeJournal.ingredient(String(pair["base"]))["unlock_day"]) <= 1)
	assert(int(RecipeJournal.ingredient(String(pair["milk"]))["unlock_day"]) <= 1)
	assert(not ResearchBriefs.record_trial("missing", "missing", [], 100)["completed"])
	var pair_done := ResearchBriefs.record_trial(String(pair["base"]), String(pair["milk"]), [], 0)
	assert(pair_done["completed"] and pair_done["reward"] == 2)
	assert(ResearchBriefs.ensure_for_day(1)["completed"], "same day must not issue a second brief")

	GameState.day = 2
	var mastery := ResearchBriefs.ensure_for_day(2)
	assert(mastery["type"] == "mastery")
	var ingredient_id := String(mastery["ingredient"])
	assert(not ResearchBriefs.record_trial("", "", [ingredient_id], 0)["completed"])
	assert(int(GameState.research_brief["progress"]) == 1)
	GameState.day = 3
	assert(ResearchBriefs.ensure_for_day(3)["assigned_day"] == 2, "unfinished brief must persist across nights")
	var mastery_done := ResearchBriefs.record_trial("", "", [ingredient_id], 0)
	assert(mastery_done["completed"] and mastery_done["reward"] == 2)
	assert(int(GameState.research_brief["completed_day"]) == 3)

	GameState.affinity_seen = ResearchProgress.all_pair_keys()
	for ingredient in ResearchProgress.ingredients():
		GameState.xp[String(ingredient["id"])] = 16
	GameState.day = 4
	GameState.brief_quality_step = 0
	var balanced := ResearchBriefs.ensure_for_day(4)
	assert(balanced["type"] == "balanced")
	assert(int(balanced["quality"]) == 75, "ladder rung 0 must ask for the legacy 75 target")
	assert(not ResearchBriefs.record_trial("", "", [], 74)["completed"])
	assert(ResearchBriefs.record_trial("", "", [], 75)["completed"])

	# DP#4 品质阶梯：完成 75 晋升 82，完成 82 晋升 88，88 封顶不再上涨。
	GameState.day = 5
	GameState.research_brief = {}
	var rung_two := ResearchBriefs.ensure_for_day(5)
	assert(int(rung_two["quality"]) == 82, "completing rung 0 must promote the next brief to 82")
	assert(not ResearchBriefs.record_trial("", "", [], 81)["completed"])
	assert(ResearchBriefs.record_trial("", "", [], 82)["completed"])
	GameState.day = 6
	GameState.research_brief = {}
	var rung_three := ResearchBriefs.ensure_for_day(6)
	assert(int(rung_three["quality"]) == 88, "completing rung 1 must promote the next brief to 88")
	assert(ResearchBriefs.record_trial("", "", [], 88)["completed"])
	GameState.day = 7
	GameState.research_brief = {}
	var capped := ResearchBriefs.ensure_for_day(7)
	assert(int(capped["quality"]) == 88, "the ladder must cap at 88")
	assert(GameState.brief_quality_step == 2)

	assert(ResearchBriefs.title().contains("+2"))
	GameLocale.set_locale("en", false)
	assert(ResearchBriefs.objective_text().contains("quality"))
	assert(not ResearchBriefs.description().contains("LAB_BRIEF"))
	GameState.settings = original_settings
	TranslationServer.set_locale(GameState.locale())
	print("[RESEARCH_BRIEF] passed pair=true mastery=true balanced=true persistent=true once_per_day=true reward=2 ladder=75/82/88 bilingual=true")
	get_tree().quit()
