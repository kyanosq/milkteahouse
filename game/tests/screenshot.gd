## 自动截屏：加载场景 → 等待渲染稳定 → 存 PNG → 退出（需窗口模式运行）
## 用法: SHOT_NIGHT=0|1 [SHOT_DAY=N] godot --path game res://tests/screenshot.tscn
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.endless = GameState._new_endless_state()
	GameState.research_target = ""
	GameState.affinity_seen = []
	GameState.research_brief = {}
	GameState.market_settlement = {}
	GameState.menu = []
	GameState.featured_menu = []
	GameState.menu_last_hype_day = 0
	GameState.dark_menu = []
	GameState.new_shop_route = ""
	var route_override := OS.get_environment("SHOT_ROUTE")
	if LegacyRoutes.is_valid(route_override):
		GameState.new_shop_route = route_override
	var shot_locale := OS.get_environment("SHOT_LOCALE")
	if shot_locale != "":
		GameLocale.set_locale(shot_locale, false)
	var switch_locale := OS.get_environment("SHOT_SWITCH_LOCALE")
	var shot_gamepad := OS.get_environment("SHOT_GAMEPAD") == "1"
	var shot_gamepad_family := OS.get_environment("SHOT_GAMEPAD_FAMILY")
	if shot_gamepad and not shot_gamepad_family.is_empty():
		InputPrompts.set_test_controller_family(shot_gamepad_family)
	else:
		InputPrompts.set_test_gamepad_mode(shot_gamepad)
	var upgrades := OS.get_environment("SHOT_UPGRADES") == "1"
	var day_end := OS.get_environment("SHOT_END") == "1"
	var tutorial := OS.get_environment("SHOT_TUTORIAL") == "1"
	var tutorial_step := maxi(1, int(OS.get_environment("SHOT_TUTORIAL_STEP")))
	var pause := OS.get_environment("SHOT_PAUSE") == "1"
	var pause_confirm := OS.get_environment("SHOT_PAUSE_CONFIRM") == "1"
	var night_settings := OS.get_environment("SHOT_NIGHT_SETTINGS") == "1"
	var night_recipe := OS.get_environment("SHOT_NIGHT_RECIPE") == "1"
	var lab_brief_complete := OS.get_environment("SHOT_LAB_BRIEF_COMPLETE") == "1"
	var market_settlement := OS.get_environment("SHOT_MARKET_SETTLEMENT") == "1"
	var market_final := OS.get_environment("SHOT_MARKET_FINAL") == "1"
	var recipe_book_dark := OS.get_environment("SHOT_RECIPE_BOOK_DARK") == "1"
	var research_notebook := OS.get_environment("SHOT_RESEARCH_NOTEBOOK") == "1"
	var recipe_book := OS.get_environment("SHOT_RECIPE_BOOK") == "1" or recipe_book_dark or research_notebook
	var dark_board := OS.get_environment("SHOT_DARK_BOARD") == "1"
	var menu_board := OS.get_environment("SHOT_MENU_BOARD") == "1" or dark_board
	var menu_result := OS.get_environment("SHOT_MENU_RESULT") == "1"
	var menu_order := OS.get_environment("SHOT_MENU_ORDER") == "1" or menu_result
	var menu_confirm := OS.get_environment("SHOT_MENU_CONFIRM") == "1"
	var menu_settings := OS.get_environment("SHOT_MENU_SETTINGS") == "1"
	var display_settings := OS.get_environment("SHOT_DISPLAY_SETTINGS") == "1"
	var campaign_confirm := OS.get_environment("SHOT_CAMPAIGN_CONFIRM") == "1"
	var campaign := OS.get_environment("SHOT_CAMPAIGN") == "1" or campaign_confirm
	var campaign_menu := OS.get_environment("SHOT_CAMPAIGN_MENU") == "1"
	var campaign_night := OS.get_environment("SHOT_CAMPAIGN_NIGHT") == "1"
	var staff_recruit := OS.get_environment("SHOT_STAFF_RECRUIT") == "1"
	var staff_hired := OS.get_environment("SHOT_STAFF_HIRED") == "1"
	var staff_active := OS.get_environment("SHOT_STAFF_ACTIVE") == "1"
	var staff_idle := OS.get_environment("SHOT_STAFF_IDLE") == "1"
	var staff_end := OS.get_environment("SHOT_STAFF_END") == "1"
	var staff_shortfall_end := OS.get_environment("SHOT_STAFF_SHORTFALL_END") == "1"
	var staff_rest_day := OS.get_environment("SHOT_STAFF_REST_DAY") == "1"
	var staff_id_override := OS.get_environment("SHOT_STAFF_ID")
	var staff_menu := OS.get_environment("SHOT_STAFF_MENU") == "1"
	var contract_panel := OS.get_environment("SHOT_CONTRACT_PANEL") == "1"
	var contract_active := OS.get_environment("SHOT_CONTRACT_ACTIVE") == "1"
	var contract_end := OS.get_environment("SHOT_CONTRACT_END") == "1"
	var menu := OS.get_environment("SHOT_MENU") == "1" or menu_confirm or menu_settings or display_settings or campaign_menu or staff_menu
	var night := OS.get_environment("SHOT_NIGHT") == "1" or upgrades or night_settings or night_recipe or lab_brief_complete or market_settlement or market_final or recipe_book or menu_board or campaign_night or staff_recruit or staff_hired or contract_panel
	var demo := OS.get_environment("SHOT_DEMO") == "1"
	var topping_demo := OS.get_environment("SHOT_TOPPING") == "1"
	var workbench_demo := OS.get_environment("SHOT_WORKBENCH") == "1"
	var station_pulse_id := OS.get_environment("SHOT_STATION_PULSE")
	var cup_pulse_kind := OS.get_environment("SHOT_CUP_PULSE")
	var cup_handoff := OS.get_environment("SHOT_CUP_HANDOFF") == "1"
	var context_reveal := OS.get_environment("SHOT_CONTEXT_REVEAL") == "1"
	var next_action_pulse := OS.get_environment("SHOT_NEXT_ACTION_PULSE") == "1"
	var batch_demo := OS.get_environment("SHOT_BATCH") == "1"
	var dark_order_demo := OS.get_environment("SHOT_DARK_ORDER") == "1"
	var hud_demo := OS.get_environment("SHOT_HUD") == "1"
	var route_pulse := OS.get_environment("SHOT_ROUTE_PULSE") == "1"
	var sealed_review_demo := OS.get_environment("SHOT_SEALED_REVIEW") == "1"
	var sealed_wrong_demo := OS.get_environment("SHOT_SEALED_WRONG") == "1"
	var reworked_demo := OS.get_environment("SHOT_REWORKED") == "1"
	var mobile_gesture_demo := OS.get_environment("SHOT_MOBILE_GESTURE") == "1"
	var order_progress_wrong := OS.get_environment("SHOT_ORDER_WRONG") == "1" or sealed_wrong_demo
	var sealed_demo := OS.get_environment("SHOT_SEALED") == "1" or sealed_wrong_demo \
		or sealed_review_demo or reworked_demo
	var order_progress_match := OS.get_environment("SHOT_ORDER_MATCH") == "1" or sealed_demo or mobile_gesture_demo
	var order_progress := order_progress_wrong or order_progress_match
	var upgrade_visuals := OS.get_environment("SHOT_UPGRADE_VISUALS") == "1"
	var event_briefing := OS.get_environment("SHOT_EVENT") == "1"
	var event_active := OS.get_environment("SHOT_EVENT_ACTIVE") == "1"
	var event_end := OS.get_environment("SHOT_EVENT_END") == "1"
	var operating_hud := OS.get_environment("SHOT_OPERATING") == "1"
	var operating_end := OS.get_environment("SHOT_OPERATING_END") == "1"
	var group_progress := OS.get_environment("SHOT_GROUP_PROGRESS") == "1"
	var event_day := maxi(3, int(OS.get_environment("SHOT_EVENT_DAY")))
	var day_env := OS.get_environment("SHOT_DAY")
	var shop: Control
	if campaign:
		GameState.day = 14
		GameState.phase = "night"
		GameState.perfect_total = 110
		GameState.coins = 520
		GameState.buzz = 12
		GameState.inspiration = 7
		GameState.upgrades = {"comfort": 3, "shaker": 2, "smart_sugar": 1, "tip_jar": 1}
		GameState.discovered = ["classic_boba", "green_cloud", "brown_sugar"]
		GameState.dark_discovered = ["xiangcai_fantasy"]
		GameState.menu = [
			{"name": "经典珍珠", "tier": "招牌", "price": 15},
			{"name": "薄荷云", "tier": "爆款", "price": 18},
		]
		GameState.campaign_stats = {
			"revenue": 2864, "served": 196, "angry": 7, "stars": 28,
			"event_bonus": 164, "buzz_earned": 27, "special_served": 18,
			"days_completed": 14, "best_streak": 12,
			"recorded_days": range(1, 15),
		}
		GameState.campaign_summary = {}
		GameState.campaign_claimed = false
		GameState.legacy = {"campaigns_completed": 0, "best_grade": "-", "best_score": 0}
		var report: Control = load("res://scenes/campaign_summary/campaign_summary.tscn").instantiate()
		add_child(report)
		if campaign_confirm:
			await get_tree().create_timer(0.5).timeout
			report._request_new_shop()
	elif menu:
		GameState.day = 14 if campaign_menu else (10 if staff_menu else 9)
		GameState.phase = "campaign" if campaign_menu else "day"
		GameState.coins = 306
		GameState.inspiration = 8
		GameState.upgrades = {"comfort": 2, "shaker": 2, "smart_sugar": 1, "tip_jar": 1}
		GameState.staff = {}
		if staff_menu:
			GameState.staff = StaffCatalog.candidate("xiaoman").duplicate(true)
			GameState.staff["trait_revealed"] = true
			GameState.staff["days_worked"] = 2
		var main_menu: Control = load("res://scenes/main_menu/main_menu.tscn").instantiate()
		add_child(main_menu)
		if menu_confirm:
			await get_tree().create_timer(0.5).timeout
			main_menu._request_new_game()
		elif menu_settings or display_settings:
			await get_tree().create_timer(0.5).timeout
			main_menu._open_settings()
			if display_settings:
				main_menu.settings_panel._open_display_settings()
	elif night:
		var requested_night_day := int(day_env) if day_env != "" else 9
		GameState.day = 15 if contract_panel else (14 if campaign_night else (8 if staff_recruit or staff_hired else requested_night_day))
		GameState.inspiration = 10
		GameState.coins = 300
		GameState.staff = {}
		if lab_brief_complete:
			GameState.research_brief = {
				"type": "pair", "assigned_day": GameState.day, "base": "black_tea", "milk": "fresh_milk",
				"progress": 0, "target": 1, "reward": 2, "completed": false, "completed_day": 0,
			}
		if market_settlement:
			var active_names := ["Osmanthus Cloud", "Mint Green Isle"] if shot_locale == "en" else ["桂花云乳", "薄荷青岚"]
			GameState.tests = [
				{"name": active_names[0], "quality": 84, "scores": [], "base": "oolong", "milk": "fresh_milk", "toppings": ["pudding"], "sugar": 50},
				{"name": active_names[1], "quality": 80, "scores": [82], "base": "green_tea", "milk": "none", "toppings": ["coconut_jelly"], "sugar": 30},
			]
		elif market_final:
			var final_names := ["Starlit Osmanthus", "Oat Tea Aroma", "Twin Pepper Fantasy"] if shot_locale == "en" else ["星夜桂花乳", "燕麦茶香", "双椒奇想"]
			GameState.tests = [
				{"name": final_names[0], "quality": 91, "scores": [92, 94], "base": "oolong", "milk": "fresh_milk", "toppings": ["pudding"], "sugar": 50},
				{"name": final_names[1], "quality": 67, "scores": [70, 68], "base": "black_tea", "milk": "oat_milk", "toppings": ["boba"], "sugar": 50},
				{"name": final_names[2], "quality": 42, "scores": [45, 43], "base": "green_tea", "milk": "fresh_milk", "toppings": ["xiangcai"], "sugar": 100},
			]
		if staff_hired:
			GameState.staff = StaffCatalog.candidate("xiaoman").duplicate(true)
			GameState.staff["trait_revealed"] = true
			GameState.staff["days_worked"] = 2
		if menu_board:
			for recipe_id in ["jasmine_pure", "classic_boba", "jasmine_coco", "taro_boba", "oolong_pudding", "taro_coco"]:
				MenuCatalog.register_legend(RecipeJournal.recipe(recipe_id))
			# DP#4 定价行证据：自创饮品卡片展示三档价点（传说卡不显示）。
			MenuCatalog.register_custom({
				"name": "桂花乌龙鲜奶", "base": "oolong", "milk": "fresh_milk",
				"toppings": ["boba", "pudding"], "sugar": 50, "quality": 84,
			}, "招牌", 15)
		if dark_board:
			GameState.dark_discovered = ["xiangcai_fantasy", "zheergen_rage", "sweet_salt_horror"]
			GameState.dark_menu = [
				{"kind": "legend", "recipe_id": "xiangcai_fantasy", "sales": 7},
				{"kind": "legend", "recipe_id": "zheergen_rage", "sales": 4},
				{"kind": "legend", "recipe_id": "sweet_salt_horror", "sales": 2},
			]
		var lab: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
		add_child(lab)
		if menu_board:
			await get_tree().create_timer(0.5).timeout
			lab._open_menu_board()
			if dark_board:
				lab.menu_board_panel._switch_mode("dark")
		elif recipe_book:
			GameState.discovered = ["classic_boba", "jasmine_coco", "taro_boba"]
			GameState.dark_discovered = ["xiangcai_fantasy"]
			GameState.research_target = "oolong_pudding"
			if research_notebook:
				GameState.affinity_seen = [
					"black_tea|none", "black_tea|fresh_milk", "black_tea|oat_milk",
					"green_tea|none", "green_tea|fresh_milk", "oolong|fresh_milk", "oolong|coconut_milk",
				]
				GameState.xp = {
					"black_tea": 18, "green_tea": 7, "oolong": 32, "fresh_milk": 16,
					"coconut_milk": 9, "oat_milk": 0, "boba": 25, "pudding": 14,
					"taro": 17, "coconut_jelly": 5,
				}
			await get_tree().create_timer(0.5).timeout
			lab._open_recipe_book()
			if recipe_book_dark:
				lab.recipe_book_panel.show_dark_tab_for_test()
			elif research_notebook:
				lab.recipe_book_panel.show_research_tab_for_test()
		elif upgrades:
			GameState.coins = 460
			GameState.upgrades = {}
			await get_tree().create_timer(0.5).timeout
			lab._open_upgrades()
		elif night_settings:
			await get_tree().create_timer(0.5).timeout
			lab.settings_panel.show_panel(false, "night")
		elif night_recipe:
			await get_tree().create_timer(0.5).timeout
			lab._on_base(GameData.bases[0])
			lab._on_milk(GameData.milks[1])
			lab._on_topping(GameData.toppings[0])
			lab._on_sugar(GameData.sugar_levels[2])
		elif lab_brief_complete:
			await get_tree().create_timer(0.5).timeout
			lab._on_base(GameData.bases[0])
			lab._on_milk(GameData.milks[1])
			lab._on_topping(GameData.toppings[0])
			lab._on_sugar(GameData.sugar_levels[2])
			lab._on_try()
		elif market_settlement or market_final:
			await get_tree().create_timer(0.5).timeout
			lab._on_sleep()
		elif campaign_night:
			await get_tree().create_timer(0.5).timeout
			lab._on_sleep()
		elif staff_recruit or staff_hired:
			await get_tree().create_timer(0.5).timeout
			lab._open_staff()
		elif contract_panel:
			GameState.coins = 960
			await get_tree().create_timer(0.5).timeout
			lab._open_contracts()
	else:
		GameState.day = 10 if order_progress else (9 if menu_order else (16 if contract_active or contract_end else (8 if staff_active or staff_idle or staff_end else (event_day if event_briefing or event_active or event_end or group_progress else (int(day_env) if day_env != "" else 1)))))
		if batch_demo or dark_order_demo:
			GameState.day = 9
		if operating_hud or operating_end:
			GameState.day = 7
		if staff_shortfall_end:
			GameState.day = 9
		elif staff_rest_day:
			GameState.day = 10
		if contract_active or contract_end:
			GameState.coins = 960
			GameState.upgrades = {"comfort": 3, "shaker": 3, "smart_sugar": 1, "tip_jar": 3}
			assert(EndlessContracts.sign_contract("revenue_sprint", 16, false))
		if upgrade_visuals:
			GameState.upgrades = {"comfort": 3, "shaker": 3, "smart_sugar": 1, "tip_jar": 3}
		if staff_active or staff_idle or staff_end or staff_shortfall_end or staff_rest_day:
			var staff_id := "acheng" if staff_shortfall_end or staff_rest_day else (staff_id_override if staff_id_override != "" else ("xiaoman" if staff_idle or staff_end else "taozi"))
			GameState.staff = StaffCatalog.candidate(staff_id).duplicate(true)
			GameState.staff["trait_revealed"] = not staff_idle
			GameState.staff["days_worked"] = 1
			GameState.staff["rest_day"] = 10 if staff_rest_day else 0
			GameState.staff["wage_shortfall"] = 9 if staff_rest_day else 0
			GameState.staff["wage_shortfalls"] = 1 if staff_rest_day else 0
		if (event_active or event_end) and OS.get_environment("SHOT_EVENT_DAY") == "":
			GameState.day = 6
		if group_progress and OS.get_environment("SHOT_EVENT_DAY") == "":
			GameState.day = 8
		if menu_order:
			for recipe_id in ["classic_boba", "jasmine_coco", "taro_boba"]:
				MenuCatalog.register_legend(RecipeJournal.recipe(recipe_id))
		if dark_order_demo:
			GameState.dark_discovered = ["xiangcai_fantasy"]
			GameState.dark_menu = [{"kind": "legend", "recipe_id": "xiangcai_fantasy", "sales": 7}]
		shop = load("res://scenes/day_shop/day_shop.tscn").instantiate()
		add_child(shop)
		if menu_order:
			await get_tree().create_timer(0.5).timeout
			shop._spawn_customer()
			shop._spawn_customer()
			if menu_result:
				shop.earned = 276
				GameState.coins = 582
				GameState.inspiration = 18
				shop.served = 19
				shop.perfect = 18
				shop.angry = 1
				shop.best_streak = 7
				shop.menu_sales_count = 4
				shop.menu_sales_revenue = 56
				shop.menu_sales_by_id = {"legend:classic_boba": 4}
				shop._end_day()
			else:
				shop.running = false
		elif group_progress:
			await get_tree().create_timer(0.5).timeout
			shop._spawn_customer()
			var group: Dictionary = shop.customers[0]
			var first_order: Dictionary = group["order"]
			shop._on_base(first_order["base"])
			shop._on_milk(first_order["milk"])
			for topping in first_order["tops"]:
				shop._on_topping(topping)
			shop._on_sugar(first_order["sugar"])
			for i in shop._shakes_needed():
				shop._on_shake()
			shop._on_deliver(group)
			shop.running = false
		elif event_briefing:
			await get_tree().create_timer(0.5).timeout
			shop._show_event_briefing()
			if OS.get_environment("SHOT_EVENT_PAUSE") == "1":
				await get_tree().create_timer(0.3).timeout
				shop._toggle_pause()
		elif staff_idle:
			await get_tree().create_timer(0.5).timeout
			shop.staff_event_timer = 0.0
			shop._update_staff(0.1)
			shop.running = false
		elif staff_active:
			await get_tree().create_timer(0.5).timeout
			shop.running = false
		elif staff_rest_day:
			await get_tree().create_timer(0.5).timeout
			shop.running = false
		elif tutorial:
			GameState.tutorial_completed = false
			await get_tree().create_timer(0.5).timeout
			shop._show_tutorial(false)
			for i in tutorial_step - 1:
				shop.tutorial_overlay._advance()
		elif pause or pause_confirm:
			await get_tree().create_timer(0.5).timeout
			shop._resume_after_pause = true
			shop.running = false
			shop.pause_panel.show_panel(true)
			if pause_confirm:
				shop.pause_panel._request_menu()
		elif operating_hud:
			await get_tree().create_timer(1.25).timeout
			GameState.coins = 244
			shop.earned = 84
			shop.perfect = 6
			shop.streak = 3
			shop.best_streak = 4
			shop.stock_cost = 22
			shop.waste_cost = 3
			shop.running = false
			shop._update_info()
		if demo or topping_demo or workbench_demo:
			await get_tree().create_timer(1.25).timeout
			while shop.customers.size() < 2:
				shop._spawn_customer()
			if not shop.customers.is_empty():
				var find := func(list: Array, id: String) -> Dictionary:
					for item in list:
						if item["id"] == id:
							return item
					return {}
				shop.active_customer["order"]["base"] = find.call(GameData.bases, "black_tea")
				shop.active_customer["order"]["milk"] = find.call(GameData.milks, "fresh_milk")
				shop.active_customer["order"]["tops"] = [find.call(GameData.toppings, "boba")]
				if workbench_demo:
					shop.active_customer["order"]["tops"].append(find.call(GameData.toppings, "pudding"))
				shop.active_customer["order"]["sugar"] = GameData.sugar_levels[2]
				shop._render_order_card(shop.active_customer)
				var second_customer: Dictionary = shop.customers[1]
				second_customer["order"]["base"] = find.call(GameData.bases, "black_tea")
				second_customer["order"]["milk"] = find.call(GameData.milks, "fresh_milk")
				second_customer["order"]["tops"] = [find.call(GameData.toppings, "coconut_jelly")]
				second_customer["order"]["sugar"] = GameData.sugar_levels[2]
				shop._render_order_card(second_customer)
				for customer in shop.customers.slice(0, 2):
					customer["patience"] = float(customer["max_patience"]) * 0.78
					shop._style_order_card(customer, customer == shop.active_customer)
				shop._on_base(shop.active_customer["order"]["base"])
				shop._on_milk(shop.active_customer["order"]["milk"])
				if not topping_demo:
					shop._on_topping(shop.active_customer["order"]["tops"][0])
				shop._style_order_card(shop.active_customer, true)
				# The visual truth uses 11:17; keep the frozen QA state at that exact
				# width while production retains the real 120-second countdown.
				shop.time_left = 677.0
				shop.running = false
				shop._update_info()
		if batch_demo:
			await get_tree().create_timer(1.25).timeout
			shop.tea_batch.start("black_tea")
			shop.pearl_batch.start("boba")
			shop.tea_batch.advance(9.0)
			shop.pearl_batch.advance(10.0)
			shop._refresh_prep_ui()
			shop.running = false
		if dark_order_demo:
			await get_tree().create_timer(1.25).timeout
			while shop.customers.size() < 3:
				shop._spawn_customer()
			shop._set_active_customer(shop.customers[2])
			shop._render_order_card(shop.customers[2])
			shop.running = false
		if hud_demo:
			await get_tree().create_timer(1.25).timeout
			shop.earned = 68
			shop.perfect = 5
			shop.streak = 3
			shop.best_streak = 3
			match LegacyRoutes.active_id():
				"rush":
					shop.route_bonus_earned = 4
					shop.route_trigger_count = 4
					shop.streak = 5
				"precision":
					shop.route_bonus_earned = 3
					shop.route_trigger_count = 3
				"trend":
					shop.route_bonus_earned = 6
					shop.route_trigger_count = 2
			shop._update_info()
			shop.running = false
		if order_progress:
			await get_tree().create_timer(1.25).timeout
			while shop.customers.size() < 3:
				shop._spawn_customer()
			var find_item := func(list: Array, id: String) -> Dictionary:
				for item in list:
					if String(item["id"]) == id:
						return item
				return {}
			var target: Dictionary = shop.customers[0]
			target["order"] = {
				"base": find_item.call(GameData.bases, "black_tea"),
				"milk": find_item.call(GameData.milks, "fresh_milk"),
				"tops": [find_item.call(GameData.toppings, "boba"), find_item.call(GameData.toppings, "pudding")],
				"sugar": GameData.sugar_levels[2],
			}
			if sealed_review_demo:
				var review_target: Dictionary = shop.customers[1]
				review_target["order"] = {
					"base": find_item.call(GameData.bases, "green_tea"),
					"milk": find_item.call(GameData.milks, "oat_milk"),
					"tops": [find_item.call(GameData.toppings, "coconut_jelly")],
					"sugar": GameData.sugar_levels[1],
				}
				shop._render_order_card(review_target)
			shop._set_active_customer(target)
			shop._render_order_card(target)
			shop._reset_cup()
			if reworked_demo:
				shop._on_base(find_item.call(GameData.bases, "green_tea"))
			shop._on_base(find_item.call(GameData.bases, "green_tea") if order_progress_wrong else target["order"]["base"])
			shop._on_milk(find_item.call(GameData.milks, "oat_milk") if order_progress_wrong else target["order"]["milk"])
			shop._on_topping(find_item.call(GameData.toppings, "boba"))
			shop._on_topping(find_item.call(GameData.toppings, "coconut_jelly") if order_progress_wrong else find_item.call(GameData.toppings, "pudding"))
			shop._on_sugar(GameData.sugar_levels[1] if order_progress_wrong else target["order"]["sugar"])
			if mobile_gesture_demo:
				shop.next_action_label.text = shop._shake_next_action_text(true)
				if not shop._context_shortcuts.is_empty():
					shop._context_shortcuts[0].text = shop._shake_button_text(true)
			if sealed_demo:
				while not shop.cup_sealed:
					shop._on_shake()
				if sealed_review_demo:
					shop._on_order_card_pressed(shop.customers[1])
			shop.running = false
		if contract_active:
			await get_tree().create_timer(1.25).timeout
			shop.earned = 346
			shop.perfect = 21
			shop.streak = 17
			shop.best_streak = 21
			shop.running = false
			shop._update_info()
		if day_end or event_end or staff_end or staff_shortfall_end or contract_end or operating_end:
			await get_tree().create_timer(1.25).timeout
			shop.earned = 5 if staff_shortfall_end else (196 if operating_end else (620 if contract_end else (228 if event_end else 186)))
			shop.served = 0 if staff_shortfall_end else (15 if operating_end else (32 if contract_end else (16 if event_end else 14)))
			shop.perfect = 0 if staff_shortfall_end else (14 if operating_end else (32 if contract_end else (15 if event_end else 12)))
			shop.angry = 8 if staff_shortfall_end else (1 if operating_end else (0 if contract_end else 1))
			shop.best_streak = 0 if staff_shortfall_end else (6 if operating_end else (32 if contract_end else (8 if event_end else 7)))
			if staff_shortfall_end:
				GameState.coins = 5
				shop.stock_cost = 0
				shop.waste_cost = 0
				shop._update_info()
			if operating_end:
				GameState.coins = 316
				shop.stock_cost = 48
				shop.waste_cost = 4
			if staff_end:
				shop.staff_events = 3
				shop.staff_wakes = 2
			if event_end:
				match String(shop.day_event["id"]):
					"influencer_day":
						shop.event_bonus_earned = 15
						shop.event_buzz_earned = 9
						shop.special_served = 3
					"group_day":
						shop.event_bonus_earned = 20
						shop.special_served = 2
					_:
						shop.event_bonus_earned = 24
						shop.special_served = 3
			shop._end_day()
	if switch_locale in ["zh_CN", "en"]:
		await get_tree().create_timer(0.2).timeout
		GameLocale.set_locale(switch_locale, false)
		await get_tree().process_frame
	await get_tree().create_timer(3.0 if day_env == "" else 10.0).timeout
	if route_pulse and shop != null and is_instance_valid(shop):
		GameState.settings["reduced_motion"] = false
		shop.stage.pulse_route_sign()
		await get_tree().create_timer(0.08).timeout
	if not station_pulse_id.is_empty() and shop != null and is_instance_valid(shop):
		GameState.settings["reduced_motion"] = false
		shop._pulse_station_art(station_pulse_id)
		await get_tree().create_timer(0.06).timeout
	if not cup_pulse_kind.is_empty() and shop != null and is_instance_valid(shop):
		GameState.settings["reduced_motion"] = false
		shop._animate_cup_art(cup_pulse_kind)
		await get_tree().create_timer(0.06).timeout
	if cup_handoff and shop != null and is_instance_valid(shop):
		GameState.settings["reduced_motion"] = false
		shop._animate_cup_handoff()
		await get_tree().create_timer(0.16).timeout
	if context_reveal and shop != null and is_instance_valid(shop):
		GameState.settings["reduced_motion"] = false
		shop.stage._active_prop_kind = ""
		shop._refresh_context_controls()
		await get_tree().create_timer(0.06).timeout
	if next_action_pulse and shop != null and is_instance_valid(shop):
		GameState.settings["reduced_motion"] = false
		shop._last_next_action_text = ""
		shop._update_next_action_motion()
		await get_tree().create_timer(0.04).timeout
	var img := get_viewport().get_texture().get_image()
	var suffix := "day%s" % day_env
	if campaign_confirm:
		suffix = "campaign_confirm"
	elif campaign:
		suffix = "campaign"
	elif campaign_menu:
		suffix = "campaign_menu"
	elif campaign_night:
		suffix = "campaign_night"
	elif staff_recruit:
		suffix = "staff_recruit"
	elif staff_hired:
		suffix = "staff_hired"
	elif staff_idle:
		suffix = "staff_idle"
	elif staff_active:
		suffix = "staff_active"
	elif staff_end:
		suffix = "staff_end"
	elif staff_shortfall_end:
		suffix = "staff_shortfall_end"
	elif staff_rest_day:
		suffix = "staff_rest_day"
	elif staff_menu:
		suffix = "staff_menu"
	elif contract_panel:
		suffix = "contract_panel"
	elif contract_active:
		suffix = "contract_active"
	elif contract_end:
		suffix = "contract_end"
	elif menu_confirm:
		suffix = "menu_confirm"
	elif menu_settings:
		suffix = "menu_settings"
	elif display_settings:
		suffix = "display_settings"
	elif menu:
		suffix = "menu"
	elif upgrades:
		suffix = "upgrades"
	elif night_settings:
		suffix = "night_settings"
	elif menu_board:
		suffix = "dark_board" if dark_board else "menu_board"
	elif recipe_book:
		suffix = "research_notebook" if research_notebook else ("recipe_book_dark" if recipe_book_dark else "recipe_book")
	elif night_recipe:
		suffix = "night_recipe"
	elif lab_brief_complete:
		suffix = "lab_brief_complete"
	elif market_final:
		suffix = "market_final"
	elif market_settlement:
		suffix = "market_settlement"
	elif night:
		suffix = "night"
	elif tutorial:
		suffix = "tutorial%d" % tutorial_step
	elif event_briefing:
		suffix = "event_briefing"
	elif event_active:
		suffix = "event_active"
	elif event_end:
		suffix = "event_end"
	elif operating_end:
		suffix = "operating_end"
	elif operating_hud:
		suffix = "operating_hud"
	elif group_progress:
		suffix = "group_progress"
	elif menu_order:
		suffix = "menu_result" if menu_result else "menu_order"
	elif pause_confirm:
		suffix = "pause_confirm"
	elif pause:
		suffix = "pause"
	elif day_end:
		suffix = "day_end"
	elif hud_demo:
		suffix = "day_hud"
	elif reworked_demo:
		suffix = "reworked"
	elif mobile_gesture_demo:
		suffix = "mobile_gesture"
	elif sealed_review_demo:
		suffix = "sealed_review"
	elif sealed_wrong_demo:
		suffix = "sealed_wrong"
	elif order_progress_wrong:
		suffix = "order_wrong"
	elif sealed_demo:
		suffix = "sealed"
	elif cup_handoff:
		suffix = "cup_handoff"
	elif order_progress_match:
		suffix = "order_match"
	elif topping_demo:
		suffix = "day_topping"
	elif workbench_demo:
		suffix = "day_workbench"
	elif demo:
		suffix = "day_demo"
	elif batch_demo:
		suffix = "batch_parallel"
	elif dark_order_demo:
		suffix = "dark_order"
	var output_override := OS.get_environment("SHOT_OUTPUT")
	var default_path := ProjectSettings.globalize_path("res://../assets_src/renders/game_%s.png" % suffix)
	var path := output_override if output_override != "" else default_path
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("[SHOT] saved ", path)
	# Let controls, SubViewports and shaped-text caches leave the scene tree before
	# terminating the renderer; quitting immediately produces false-positive RID leaks.
	Sfx.stop_all()
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
