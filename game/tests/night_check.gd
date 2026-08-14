## 夜间研发室逻辑冒烟：做出传说配方 + 一杯翻车黑暗料理，验证发现/菜单/话题度链路
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameLocale.set_locale("zh_CN", false)
	GameState.day = 9
	GameState.inspiration = 5
	GameState.buzz = 0
	GameState.night_budget = -1
	GameState.night_budget_day = 0
	GameState.night_performance_remaining = 0
	GameState.discovered = []
	GameState.dark_discovered = []
	GameState.menu = []
	GameState.featured_menu = []
	GameState.menu_last_hype_day = 0
	GameState.dark_menu = []
	GameState.tests = []
	GameState.market_settlement = {}
	GameState.research_target = "classic_boba"
	GameState.affinity_seen = []
	GameState.research_brief = {
		"type": "pair", "assigned_day": 9, "base": "black_tea", "milk": "fresh_milk",
		"progress": 0, "target": 1, "reward": 2, "completed": false, "completed_day": 0,
	}
	var lab: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(lab)
	await get_tree().process_frame
	assert(Sfx.current_music == "night")

	var find := func(list: Array, id: String) -> Dictionary:
		for it in list:
			if it["id"] == id:
				return it
		return {}

	# 1) 传说配方：经典珍珠奶茶
	lab._on_base(find.call(GameData.bases, "black_tea"))
	lab._on_milk(find.call(GameData.milks, "fresh_milk"))
	lab._on_topping(find.call(GameData.toppings, "boba"))
	lab._on_sugar(GameData.sugar_levels[3])  # 七分糖
	lab._on_try()
	assert(lab.budget == 13, "brief completion must refund the two-point trial cost")
	assert(GameState.research_brief["completed"])
	assert(lab.result_label.text.contains(GameLocale.text("LAB_BRIEF_REWARD", [2, ResearchBriefs.objective_text()])))
	assert(ResearchProgress.is_seen("black_tea", "fresh_milk"))
	assert(lab.result_label.text.contains(GameLocale.text("RESEARCH_RANK_NEUTRAL")))
	assert(GameState.research_target.is_empty(), "matching a trial must complete the research target")
	assert(lab.result_label.text.contains(GameLocale.text("NIGHT_TARGET_COMPLETE", [GameLocale.recipe_name(RecipeJournal.recipe("classic_boba"))])))
	assert(GameState.menu[0]["id"] == "legend:classic_boba")
	assert(GameState.menu[0]["base"] == "black_tea")
	assert(int(GameState.menu[0]["hype_remaining"]) == 4)
	assert(GameState.featured_menu == ["legend:classic_boba"])
	print("[T1] discovered=%s menu=%d" % [str(GameState.discovered), GameState.menu.size()])
	print(lab.result_label.text.split("\n")[-2])

	# Persistent trial feedback and discovery notes must hot-switch languages without
	# replaying the trial or mutating its rewards.
	var budget_after_trial: int = lab.budget
	var discovered_after_trial: Array = GameState.discovered.duplicate()
	GameLocale.set_locale("en", false)
	await get_tree().process_frame
	var classic := RecipeJournal.recipe("classic_boba")
	assert(lab.result_label.text.contains(GameLocale.recipe_name(classic)))
	assert(lab.result_label.text.contains(GameLocale.text("NIGHT_TARGET_COMPLETE", [GameLocale.recipe_name(classic)])))
	assert(_visible_copy_contains(lab.note_box, GameLocale.recipe_name(classic)))
	assert(lab.try_btn.text == GameLocale.text("NIGHT_TRY", [lab.ATTEMPT_COST]))
	assert(lab.budget == budget_after_trial and GameState.discovered == discovered_after_trial,
		"locale switching must not replay a trial or its rewards")
	GameLocale.set_locale("zh_CN", false)
	await get_tree().process_frame
	assert(lab.result_label.text.contains(GameLocale.recipe_name(classic)))
	assert(lab.try_btn.text == GameLocale.text("NIGHT_TRY", [lab.ATTEMPT_COST]))

	# The shelf-ready note rebuild keeps the player's typed custom name.
	lab._show_note_state({"kind": "shelf", "score": 88})
	lab.name_edit.text = "Cloud Test"
	GameLocale.set_locale("en", false)
	await get_tree().process_frame
	assert(lab.name_edit.text == "Cloud Test")
	assert(_visible_copy_contains(lab.note_box, GameLocale.text("NIGHT_NAME_NEW")))
	GameLocale.set_locale("zh_CN", false)
	await get_tree().process_frame

	# 上架必须记录试做得分的那一杯：改料后旧分数失效，命名上架被拒绝。
	lab.pending_quality = 88
	lab._show_note_state({"kind": "shelf", "score": 88})
	assert(lab.note_card.visible)
	lab.name_edit.text = "Stale Formula"
	lab._on_tile("topping", find.call(GameData.toppings, "boba"))
	assert(lab.pending_quality == 0, "changing ingredients must invalidate the pending shelf score")
	assert(not lab.note_card.visible)
	lab._on_shelf()
	assert(GameState.tests.is_empty(), "shelving a changed formula must not record a stale-score test")

	# 2) 黑暗传说：香菜狂想曲
	lab.cup_tops = []
	lab._on_base(find.call(GameData.bases, "green_tea"))
	lab._on_milk(find.call(GameData.milks, "fresh_milk"))
	lab._on_topping(find.call(GameData.toppings, "boba"))
	lab._on_topping(find.call(GameData.toppings, "xiangcai"))
	lab._on_sugar(GameData.sugar_levels[2])
	lab._on_try()
	assert(ResearchProgress.is_seen("green_tea", "fresh_milk"))
	assert(ResearchProgress.seen_count() == 2)
	assert(GameState.dark_menu[0] == {"kind": "legend", "recipe_id": "xiangcai_fantasy"})
	GameLocale.set_locale("en", false)
	assert(GameState.dark_menu_name(GameState.dark_menu[0]) == GameLocale.recipe_name(RecipeJournal.recipe("xiangcai_fantasy")))
	var mystery_entry := {"kind": "mystery", "serial": 2}
	lab._set_result("NIGHT_DARK_MENU_ADDED", [lab._localized_arg("dark_menu", mystery_entry)])
	assert(lab.result_label.text.contains(GameState.dark_menu_name(mystery_entry)))
	GameLocale.set_locale("zh_CN", false)
	assert(lab.result_label.text.contains(GameState.dark_menu_name(mystery_entry)))
	print("[T2] dark=%s buzz=%d dark_menu=%s" %
		[str(GameState.dark_discovered), GameState.buzz, str(GameState.dark_menu)])

	# 3) 收工结算不崩
	lab._on_sleep()
	assert(GameState.inspiration == 5, "unused earned inspiration must return to reserve")
	assert(GameState.night_performance_remaining == 0)
	print("[T3] sleep ok, tests=%d" % GameState.tests.size())
	Sfx.stop_all()
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


func _visible_copy_contains(root: Node, needle: String) -> bool:
	if root is Label and root.visible and String(root.text).contains(needle):
		return true
	if root is Button and root.visible and String(root.text).contains(needle):
		return true
	for child in root.get_children():
		if _visible_copy_contains(child, needle):
			return true
	return false
