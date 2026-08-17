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
	assert(lab.result_label.text.contains(GameLocale.text("NIGHT_SHELF_VOIDED")),
		"voiding the shelf score must be visible feedback, not a silent disappearance")
	lab._on_shelf()
	assert(GameState.tests.is_empty(), "shelving a changed formula must not record a stale-score test")
	# 空名提交必须有可见反馈（P3-F2）：不再静默 return，焦点回到命名行。
	lab.pending_quality = 88
	lab._show_note_state({"kind": "shelf", "score": 88})
	lab.name_edit.text = "   "
	lab._on_shelf()
	assert(GameState.tests.is_empty(), "an empty-name shelf submit must not record a test")
	assert(lab.result_label.text.contains(GameLocale.text("NIGHT_NAME_REQUIRED")),
		"an empty-name submit must flash visible feedback instead of silently returning")
	lab.pending_quality = 0
	# 手柄焦点环：货架瓦片必须像全项目其他按钮一样有可见 focus 样式（P3 试玩）。
	var any_tile_button: Button = lab._tiles.values()[0]["btn"]
	var tile_focus := any_tile_button.get_theme_stylebox("focus") as StyleBoxFlat
	assert(tile_focus != null and not tile_focus.draw_center and tile_focus.get_border_width(SIDE_LEFT) >= 3,
		"night shelf tiles need a visible gamepad focus ring")

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

	# rush 路线主推槽 = 2（P7-F1）：夜间药丸与菜单板分母不得再报 3 槽。
	GameState.new_shop_route = "rush"
	lab._refresh()
	assert(MenuCatalog.featured_limit() == 2, "the rush route must cap featured slots at 2")
	assert(lab.menu_button.text == GameLocale.text("NIGHT_MENU_PILL", [
		MenuCatalog.featured_items().size(), 2,
		MenuCatalog.hot_featured_count(), GameState.dark_menu.size(), lab.DARK_MENU_CAP]),
		"the night featured pill must report the route-aware slot limit")
	lab._open_menu_board()
	assert(lab.menu_board_panel.visible)
	assert(lab.menu_board_panel._progress_label.text.contains("1/2"),
		"the menu board progress must show 2 slots on the rush route")
	assert(lab.menu_board_panel._subtitle_label.text == GameLocale.text("MENU_BOARD_SUBTITLE_SLOTS", [2]),
		"the rush subtitle must use the slot-counted variant, not the hardcoded three-slot copy")
	# 批量策展的焦点保持（P3-F8）：操作哪张卡，刷新后焦点回到同索引卡，
	# 而不是每次都弹回右上角关闭按钮。
	var curate_index := -1
	var curate_button: Button = null
	for i in lab.menu_board_panel._cards.get_child_count():
		var candidate := _first_button(lab.menu_board_panel._cards.get_child(i))
		if candidate != null and not candidate.disabled:
			curate_index = i
			curate_button = candidate
			break
	assert(curate_button != null, "the menu board must expose an actionable card")
	curate_button.grab_focus()
	curate_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(curate_index < lab.menu_board_panel._cards.get_child_count())
	var refocused := get_viewport().gui_get_focus_owner() as Control
	assert(refocused != null and lab.menu_board_panel._cards.get_child(curate_index).is_ancestor_of(refocused),
		"curation must refocus the same card after the deferred rebuild")
	lab.menu_board_panel.hide_panel()
	GameState.new_shop_route = ""

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


func _first_button(root: Node) -> Button:
	for child in root.get_children():
		if child is Button and not child.disabled and child.focus_mode != Control.FOCUS_NONE:
			return child
		var nested := _first_button(child)
		if nested != null:
			return nested
	return null
