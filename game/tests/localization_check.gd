## 本地化目录、动态格式化、数据名映射与静态 Control 自动翻译回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	var original_settings := GameState.settings.duplicate(true)
	GameLocale.set_locale("en", false)
	assert(GameLocale.text("TEST_FORMAT", [16, 98]) == "Day 16 · 98s")
	assert(GameLocale.ingredient_name(GameData.bases[0]) == "Assam Black Tea")
	assert(GameLocale.ingredient_short_name(GameData.bases[0]) == "Assam")
	_assert_required_keys()
	_assert_data_tables()
	var label := Label.new()
	label.text = "TITLE_NAME"
	add_child(label)
	await get_tree().process_frame
	assert(label.get_total_character_count() == "Milk Tea Story".length(), "static Control did not auto-translate")
	GameLocale.set_locale("zh_CN", false)
	assert(GameLocale.text("TEST_FORMAT", [16, 98]) == "第 16 天 · 98秒")
	assert(GameLocale.ingredient_name(GameData.bases[0]) == "阿萨姆红茶")
	await get_tree().process_frame
	assert(label.get_total_character_count() == "奶茶物语".length(), "static Control did not return to Chinese")
	GameLocale.set_locale("unsupported", false)
	assert(GameLocale.current() == "zh_CN", "unsupported locale must fall back safely")
	GameState.settings = original_settings
	TranslationServer.set_locale(GameState.locale())
	print("[LOCALIZATION] passed locales=2 static=true format=true data=true required_keys=true fallback=true")
	get_tree().quit()


func _assert_required_keys() -> void:
	var required := [
		"LANGUAGE_CURRENT", "MENU_SAVE_SUMMARY", "MENU_SAVE_RECOVERED", "MENU_INPUT_GAMEPAD", "SETTINGS_TITLE_DAY",
		"SETTINGS_CONTROLS_MENU_GAMEPAD", "SETTINGS_CONTROLS_NIGHT_GAMEPAD", "SETTINGS_CONTROLS_DAY_GAMEPAD",
		"DAY_HUD_TIME", "DAY_CONTEXT_TOPPING", "DAY_RESULT_TITLE",
		"DAY_NEXT_DELIVER_GAMEPAD", "DAY_CONFIRM_SUFFIX",
		"DAY_ORDER_DELIVER_GAMEPAD", "DAY_ORDER_DELIVER_POINTER",
		"DAY_ORDER_REVIEW_GAMEPAD", "DAY_ORDER_REVIEW_POINTER",
		"DAY_CUP_REWORKED", "DAY_CUP_CLEAN", "DAY_RESET_CUP_WASTE", "DAY_REWARD_REWORKED",
		"DAY_RESULT_CRAFT_DETAIL",
		"TUTORIAL_1_TITLE", "TUTORIAL_GAMEPAD_1", "TUTORIAL_GAMEPAD_2", "TUTORIAL_GAMEPAD_3", "NIGHT_HUD", "NIGHT_BUDGET_TOOLTIP", "NIGHT_SELECTION",
		"NIGHT_MARKET_TEST_STARTED", "UPGRADE_BUY", "UPGRADE_RESERVE_SUMMARY", "UPGRADE_RESERVE_RISK", "STAFF_HIRE",
		"ENDLESS_SIGN_RANK", "CAMPAIGN_EYEBROW", "CAMPAIGN_CONFIRM_BODY",
		"LEGACY_ROUTE_SELECT_TITLE", "LEGACY_ROUTE_RUSH_NAME", "LEGACY_ROUTE_TREND_REWARD",
		"LEGACY_ROUTE_RUSH_CALENDAR", "LEGACY_ROUTE_PRECISION_CALENDAR", "LEGACY_ROUTE_TREND_CALENDAR",
		"DAY_HUD_ROUTE", "DAY_ROUTE_ACTIVE", "DAY_RESULT_ROUTE_BONUS",
		"DAY_ROUTE_PROGRESS_RUSH", "DAY_ROUTE_PROGRESS_PRECISION", "DAY_ROUTE_PROGRESS_TREND",
		"DAY_SECONDS_ROUTE_READY", "DAY_ROUTE_PATIENCE_TOOLTIP",
		"RECIPE_BOOK_TITLE", "RECIPE_BOOK_SET_TARGET", "RECIPE_OOLONG_PUDDING_HINT",
		"MENU_BOARD_TITLE", "NIGHT_MENU_PILL", "ORDER_HINT_MENU",
		"MENU_BOARD_FORECAST", "MENU_BOARD_EVENT_MATCH", "ORDER_HINT_MENU_MATCH",
		"RECIPE_BOOK_TAB_RESEARCH", "RESEARCH_PAIR_MATRIX", "RESEARCH_MASTERY_TITLE",
		"NIGHT_PAIR_DISCOVERED", "NIGHT_PAIR_MASTERY",
		"LAB_BRIEF_TITLE_ACTIVE", "LAB_BRIEF_PAIR", "LAB_BRIEF_REWARD",
		"MARKET_SETTLEMENT_TITLE", "MARKET_SETTLEMENT_TESTING", "MARKET_SETTLEMENT_HIT",
		"DAY_HUD_COSTS_NEXT", "DAY_LEDGER_TITLE", "DAY_LEDGER_NEXT_RENT",
		"DAY_STAFF_RESTING", "DAY_RESULT_WAGE_SHORTFALL", "STAFF_REST_SCHEDULED",
		# 值作键条目已全部迁移为显式键（Iteration 63）：静态 Control 直接携带键名，
		# 拼错的键会原样显示，必须显式钉住每个裸键存在于双语表。
		"TITLE_NAME", "TITLE_TAGLINE", "TITLE_BLURB",
		"MENU_PROGRESS", "MENU_WELCOME", "MENU_RESTART", "MENU_NEW_GAME", "MENU_QUIT",
		"MENU_RESTART_CONFIRM", "MENU_RESTART_BODY", "MENU_RESTART_KEEP", "MENU_RESTART_DO",
		"SETTINGS_BUTTON", "PAUSE_HEADING", "PAUSE_CONTROLS_HINT",
		"SETTINGS_MOTION", "SETTINGS_MOTION_DESC", "SETTINGS_HAPTICS", "SETTINGS_HAPTICS_DESC",
		"SETTINGS_DISPLAY", "SETTINGS_DISPLAY_NOTE", "SETTINGS_WINDOW_MODE", "SETTINGS_RESOLUTION",
		"SETTINGS_KEYS", "SETTINGS_KEYS_RESET", "SETTINGS_BACK",
		"PAUSE_TUTORIAL", "PAUSE_MENU", "PAUSE_RESUME",
		"PAUSE_MENU_CONFIRM", "PAUSE_MENU_STAY", "PAUSE_MENU_DO",
		"DAY_PAUSE", "EVENT_BRIEF_TITLE", "EVENT_BRIEF_START",
		"EVENT_BRIEF_CHALLENGE", "EVENT_BRIEF_OPPORTUNITY",
		"LAB_UPGRADES", "PANEL_BACK_LAB", "UPGRADES_INTRO",
		"STAFF_HIRE_TITLE", "STAFF_HIRE_BODY", "CONTRACT_INTRO_TITLE", "CONTRACT_INTRO_BODY",
		"LAB_GROUP_BASE", "LAB_GROUP_MILK", "LAB_GROUP_TOPS", "LAB_GROUP_SUGAR",
		"NIGHT_TOMORROW_TITLE", "NIGHT_FLAVOR", "NIGHT_SLEEP", "NIGHT_NAME_HINT", "NIGHT_SUBMIT",
	]
	for key in required:
		assert(TranslationServer.translate(key) != key, "missing English localization key: " + key)


func _assert_data_tables() -> void:
	for group in [GameData.bases, GameData.milks, GameData.toppings, GameData.sugar_levels]:
		for item in group:
			assert(GameLocale.ingredient_name(item) != str(item.get("name", "")), "ingredient name not localized: " + str(item.get("id", item.get("value", ""))))
			assert(not GameLocale.ingredient_short_name(item).is_empty())
	for recipe in GameData.recipes + GameData.dark_recipes:
		assert(GameLocale.recipe_name(recipe) != str(recipe["name"]), "recipe name not localized: " + str(recipe["id"]))
		assert(GameLocale.recipe_description(recipe) != str(recipe["desc"]), "recipe description not localized: " + str(recipe["id"]))
	for staff in GameData.staff_list:
		assert(GameLocale.staff_name(staff) != str(staff["name"]), "staff name not localized: " + str(staff["id"]))
		assert(GameLocale.staff_intro(staff) != str(staff["intro"]), "staff intro not localized: " + str(staff["id"]))
	for item in UpgradeCatalog.items():
		assert(not String(item["name"]).begins_with("UPGRADE_"))
		assert(not String(item["description"]).begins_with("UPGRADE_"))
	for day in range(1, 10):
		var event := DailyEvents.event_for_day(day)
		assert(not String(event["name"]).begins_with("EVENT_"))
		assert(not String(event["hud_name"]).begins_with("EVENT_"))
	for offer in EndlessContracts.available_for_day(16):
		assert(not String(offer["name"]).begins_with("CONTRACT_"))
