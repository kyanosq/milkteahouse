## 玩家存档状态（user://save.json，与静态数据表分离）
extends Node

const SAVE_PATH := "user://save.json"
const SAVE_BACKUP_PATH := "user://save.backup.json"
const SAVE_VERSION := 22
const VALID_RESOLUTIONS := ["1280x720", "1440x900", "1600x900", "1920x1080", "2560x1440"]
const VALID_LOCALES := ["zh_CN", "en"]
const VALID_NEW_SHOP_ROUTES := ["rush", "precision", "trend"]

var day: int = 1
var phase := "day"               # day | night | campaign；主菜单继续时回到正确循环阶段
var coins: int = 0
var inspiration: int = 0
var buzz: int = 0
var buzz_traffic: int = 0       # 上一晚结转到当前营业日的真实黑暗菜单/事件热度
var buzz_traffic_day: int = 0   # 仅在对应营业日影响到店节奏，防止旧热度永久叠加
var night_budget: int = -1       # 当前夜间可用灵感；-1 表示尚未把日间资源结转
var night_budget_day: int = 0
var night_performance_remaining: int = 0 # 当晚装入、但尚未被试作消耗的持久灵感
var perfect_total: int = 0
var xp: Dictionary = {}          # 原料熟练度 { id: xp }
var day_open: Dictionary = {}    # 未结算白天的开店经济快照（防重玩重复收入）
var affinity_seen: Array = []    # 已在夜间试作过的 茶底|奶基 组合
var discovered: Array = []       # 传说配方 id
var dark_discovered: Array = []  # 黑暗传说 id
var menu: Array = []             # 已上架配方 [{name,tier,price,...formula/hype}]
var featured_menu: Array = []    # 次日营业主推配方 id，最多 3 项
var menu_last_hype_day := 0      # 热度只在每个营业日结算一次
var dark_menu: Array = []        # 黑暗菜单稳定条目 [{kind, recipe_id|serial|name}]，上限 3 格
var tests: Array = []            # 市场检验中 [{name,quality,scores}]
var market_settlement: Dictionary = {} # 当日已生成的夜间检验结算；重进可恢复且不重投
var research_target := ""       # 夜间图鉴中锁定的配方 id；发现/复现后自动清除
var research_brief: Dictionary = {} # 跨场景持久的短期研究单；每个营业日最多结算一份
var upgrades: Dictionary = {}    # 店铺升级 { upgrade_id: level }
var staff: Dictionary = {}       # 当前员工；候选人静态数据来自 res://data/staff.json
var campaign_stats: Dictionary = {
	"revenue": 0, "served": 0, "angry": 0, "stars": 0,
	"event_bonus": 0, "buzz_earned": 0, "special_served": 0,
	"staff_wages": 0, "staff_interactions": 0, "staff_days": 0,
	"staff_shortfalls": 0, "staff_rest_days": 0,
	"operating_costs": 0, "rent_paid": 0, "cost_relief": 0,
	"route_bonus": 0,
	"days_completed": 0, "best_streak": 0, "recorded_days": [], "tracking_start_day": 1,
}
var campaign_summary: Dictionary = {}
var campaign_claimed := false
var new_shop_route := ""          # 新店+选择的店招路线；首周目为空
var legacy: Dictionary = {"campaigns_completed": 0, "best_grade": "-", "best_score": 0, "routes_cleared": []}
var endless: Dictionary = _new_endless_state()
var tutorial_completed := false
var settings: Dictionary = {
	"sound_volume": 0.75,
	"sfx_volume": 0.75,
	"music_volume": 0.55,
	"reduced_motion": false,
	"haptics": true,
	"window_mode": "windowed",
	"resolution": "1280x720",
	"locale": "zh_CN",
	"key_bindings": {
		"game_pause": int(KEY_ESCAPE),
		"game_shake": int(KEY_SPACE),
		"staff_interact": int(KEY_F),
	},
}
var test_mode := false           # 自动截图/仿真不得覆盖真实玩家存档
var save_recovered := false      # 本次启动是否从 last-known-good 自动恢复
var last_save_error := ""


func _ready() -> void:
	load_save()


func gain_xp(ids: Array) -> void:
	for id in ids:
		if id == "none":
			continue
		xp[id] = int(xp.get(id, 0)) + 1


func level_of(id: String) -> int:
	return mini(5, int(xp.get(id, 0)) / 8 + 1)


func save_game() -> void:
	if test_mode:
		return
	_write_save_data(_save_snapshot(), SAVE_PATH, SAVE_BACKUP_PATH)


func _save_snapshot() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"day": day, "phase": phase, "coins": coins, "inspiration": inspiration,
		"buzz": buzz, "buzz_traffic": buzz_traffic, "buzz_traffic_day": buzz_traffic_day,
		"night_budget": night_budget, "night_budget_day": night_budget_day,
		"night_performance_remaining": night_performance_remaining,
		"perfect_total": perfect_total, "xp": xp, "affinity_seen": affinity_seen,
		"discovered": discovered, "dark_discovered": dark_discovered,
		"menu": menu, "featured_menu": featured_menu, "menu_last_hype_day": menu_last_hype_day,
		"dark_menu": dark_menu, "tests": tests, "market_settlement": market_settlement,
		"research_target": research_target,
		"research_brief": research_brief,
		"upgrades": upgrades, "staff": staff, "campaign_stats": campaign_stats,
		"campaign_summary": campaign_summary, "campaign_claimed": campaign_claimed,
		"new_shop_route": new_shop_route,
		"legacy": legacy, "endless": endless,
		"tutorial_completed": tutorial_completed, "settings": settings,
		"day_open": day_open,
	}


func _read_save_data(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var source := FileAccess.get_file_as_string(path)
	if source.is_empty():
		return null
	var parser := JSON.new()
	if parser.parse(source) != OK:
		return null
	var parsed: Variant = parser.data
	return parsed if parsed is Dictionary else null


func _write_save_data(data: Dictionary, target_path: String, backup_path: String) -> bool:
	last_save_error = ""
	var temp_path := target_path + ".tmp"
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(absolute_temp)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		last_save_error = "open:%d" % FileAccess.get_open_error()
		return false
	file.store_string(JSON.stringify(data, "  "))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK or _read_save_data(temp_path) == null:
		last_save_error = "write_or_validate:%d" % write_error
		DirAccess.remove_absolute(absolute_temp)
		return false

	# Refresh the last-known-good copy only from a parseable primary. A corrupt
	# current file must never overwrite the recovery copy on the next save.
	if _read_save_data(target_path) != null:
		var backup_temp_path := backup_path + ".tmp"
		var absolute_backup_temp := ProjectSettings.globalize_path(backup_temp_path)
		if FileAccess.file_exists(backup_temp_path):
			DirAccess.remove_absolute(absolute_backup_temp)
		var copy_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(target_path), absolute_backup_temp)
		if copy_error == OK and _read_save_data(backup_temp_path) != null:
			var rotate_error := DirAccess.rename_absolute(
				absolute_backup_temp, ProjectSettings.globalize_path(backup_path))
			if rotate_error != OK:
				# Some backends do not replace an existing destination. The verified
				# temporary copy keeps this fallback safe.
				DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
				rotate_error = DirAccess.rename_absolute(
					absolute_backup_temp, ProjectSettings.globalize_path(backup_path))
			if rotate_error != OK:
				last_save_error = "backup_rotate:%d" % rotate_error
		else:
			DirAccess.remove_absolute(absolute_backup_temp)
			last_save_error = "backup_copy:%d" % copy_error

	var replace_error := DirAccess.rename_absolute(
		absolute_temp, ProjectSettings.globalize_path(target_path))
	if replace_error != OK:
		last_save_error = "replace:%d" % replace_error
		return false
	if _read_save_data(target_path) == null:
		last_save_error = "post_replace_validation"
		return false
	return true


func _load_save_data_with_backup(target_path: String, backup_path: String, restore_primary := true) -> Variant:
	var primary: Variant = _read_save_data(target_path)
	if primary != null:
		return primary
	var backup: Variant = _read_save_data(backup_path)
	if backup == null:
		return null
	save_recovered = true
	if restore_primary:
		_write_save_data(backup as Dictionary, target_path, backup_path)
	return backup


func has_save() -> bool:
	return _read_save_data(SAVE_PATH) != null or _read_save_data(SAVE_BACKUP_PATH) != null


## 白天收入实时入账，而设置/语言切换会在日中写完整存档；记录开店时的经济
## 快照，恢复未结算的白天时回滚到快照，保证“重玩当天”不能重复赚取已入账收入。
func mark_day_open() -> void:
	day_open = {
		"day": day, "coins": coins, "buzz": buzz,
		"inspiration": inspiration, "perfect_total": perfect_total,
		"xp": xp.duplicate(true),
	}


func reset_progress() -> void:
	# A fresh shop should not erase accessibility/audio preferences.
	var kept_settings := settings.duplicate(true)
	var kept_legacy := legacy.duplicate(true)
	day = 1
	phase = "day"
	coins = 0
	inspiration = 0
	buzz = 0
	buzz_traffic = 0
	buzz_traffic_day = 0
	night_budget = -1
	night_budget_day = 0
	night_performance_remaining = 0
	perfect_total = 0
	xp = {}
	affinity_seen = []
	discovered = []
	dark_discovered = []
	menu = []
	featured_menu = []
	menu_last_hype_day = 0
	dark_menu = []
	tests = []
	market_settlement = {}
	research_target = ""
	research_brief = {}
	upgrades = {}
	staff = {}
	campaign_stats = _new_campaign_stats()
	campaign_summary = {}
	campaign_claimed = false
	new_shop_route = ""
	legacy = kept_legacy
	endless = _new_endless_state()
	tutorial_completed = false
	day_open = {}
	settings = kept_settings
	mark_day_open()
	save_game()


func load_save() -> void:
	save_recovered = false
	var data: Variant = _load_save_data_with_backup(SAVE_PATH, SAVE_BACKUP_PATH)
	if data == null:
		return
	_apply_save_data(data)


func _apply_save_data(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	phase = String(data.get("phase", "day"))
	if phase not in ["day", "night", "campaign"]:
		phase = "day"
	coins = int(data.get("coins", 0))
	inspiration = int(data.get("inspiration", 0))
	buzz = int(data.get("buzz", 0))
	buzz_traffic = maxi(0, int(data.get("buzz_traffic", 0)))
	buzz_traffic_day = maxi(0, int(data.get("buzz_traffic_day", 0)))
	night_budget = int(data.get("night_budget", -1))
	night_budget_day = int(data.get("night_budget_day", 0))
	night_performance_remaining = maxi(0, int(data.get("night_performance_remaining", 0)))
	if night_budget < 0 or night_budget_day != day or phase != "night":
		night_budget = -1
		night_budget_day = 0
		night_performance_remaining = 0
	else:
		# v20 及更早的夜间存档没有资源来源记录。缺省为 0 可以
		# 原样保留旧预算，又不会在收工时凭空退回一份灵感。
		night_performance_remaining = mini(night_performance_remaining, night_budget)
	perfect_total = int(data.get("perfect_total", 0))
	xp = data.get("xp", {})
	affinity_seen = []
	for pair_key in data.get("affinity_seen", []):
		var safe_pair := String(pair_key)
		if _is_valid_affinity_pair(safe_pair) and safe_pair not in affinity_seen:
			affinity_seen.append(safe_pair)
	discovered = data.get("discovered", [])
	dark_discovered = data.get("dark_discovered", [])
	menu = data.get("menu", [])
	featured_menu = []
	for item_id in data.get("featured_menu", []):
		var safe_id := String(item_id)
		if not safe_id.is_empty() and safe_id not in featured_menu and featured_menu.size() < 3:
			featured_menu.append(safe_id)
	menu_last_hype_day = maxi(0, int(data.get("menu_last_hype_day", 0)))
	dark_menu = _normalize_dark_menu(data.get("dark_menu", []))
	tests = data.get("tests", [])
	market_settlement = _normalize_market_settlement(data.get("market_settlement", {}))
	var loaded_target := String(data.get("research_target", ""))
	research_target = loaded_target if _is_valid_recipe_id(loaded_target) else ""
	research_brief = _normalize_research_brief(data.get("research_brief", {}))
	upgrades = data.get("upgrades", {})
	staff = _normalize_staff(data.get("staff", {}))
	campaign_stats = _normalize_campaign_stats(data.get("campaign_stats", {}))
	campaign_summary = data.get("campaign_summary", {})
	campaign_claimed = bool(data.get("campaign_claimed", false))
	var loaded_route := String(data.get("new_shop_route", ""))
	new_shop_route = loaded_route if loaded_route in VALID_NEW_SHOP_ROUTES else ""
	# 存档只保证了顶层是字典；嵌套字段损坏时退回默认而不是在加载时崩溃。
	var legacy_value: Variant = data.get("legacy", {})
	var loaded_legacy: Dictionary = legacy_value if legacy_value is Dictionary else {}
	var routes_cleared: Array[String] = []
	for route_id in loaded_legacy.get("routes_cleared", []):
		var safe_route := String(route_id)
		if safe_route in VALID_NEW_SHOP_ROUTES and safe_route not in routes_cleared:
			routes_cleared.append(safe_route)
	legacy = {
		"campaigns_completed": maxi(0, int(loaded_legacy.get("campaigns_completed", 0))),
		"best_grade": String(loaded_legacy.get("best_grade", "-")),
		"best_score": clampi(int(loaded_legacy.get("best_score", 0)), 0, 100),
		"routes_cleared": routes_cleared,
	}
	endless = _normalize_endless_state(data.get("endless", {}))
	tutorial_completed = bool(data.get("tutorial_completed", false))
	var settings_value: Variant = data.get("settings", {})
	var loaded_settings: Dictionary = settings_value if settings_value is Dictionary else {}
	# v0.5 and earlier used a single sound slider. Keep that value as the SFX
	# default so existing players hear the same mix after the split migration.
	var legacy_sound := clampf(float(loaded_settings.get("sound_volume", 0.75)), 0.0, 1.0)
	settings["sfx_volume"] = clampf(float(loaded_settings.get("sfx_volume", legacy_sound)), 0.0, 1.0)
	settings["music_volume"] = clampf(float(loaded_settings.get("music_volume", 0.55)), 0.0, 1.0)
	settings["sound_volume"] = settings["sfx_volume"]
	settings["reduced_motion"] = bool(loaded_settings.get("reduced_motion", false))
	settings["haptics"] = bool(loaded_settings.get("haptics", true))
	var loaded_mode := String(loaded_settings.get("window_mode", "windowed"))
	settings["window_mode"] = loaded_mode if loaded_mode in ["windowed", "borderless", "fullscreen"] else "windowed"
	var loaded_resolution := String(loaded_settings.get("resolution", "1280x720"))
	settings["resolution"] = loaded_resolution if loaded_resolution in VALID_RESOLUTIONS else "1280x720"
	var loaded_locale := String(loaded_settings.get("locale", "zh_CN"))
	settings["locale"] = loaded_locale if loaded_locale in VALID_LOCALES else "zh_CN"
	var bindings_value: Variant = loaded_settings.get("key_bindings", {})
	var loaded_bindings: Dictionary = bindings_value if bindings_value is Dictionary else {}
	settings["key_bindings"] = _normalize_key_bindings(loaded_bindings)
	# 未结算白天的存档包含日中已入账收入；回到开店快照，重玩当天只能重新赚取。
	var open_value: Variant = data.get("day_open", {})
	day_open = open_value if open_value is Dictionary else {}
	if phase == "day" and int(day_open.get("day", 0)) == day:
		coins = maxi(0, int(day_open.get("coins", coins)))
		buzz = maxi(0, int(day_open.get("buzz", buzz)))
		inspiration = maxi(0, int(day_open.get("inspiration", inspiration)))
		perfect_total = maxi(0, int(day_open.get("perfect_total", perfect_total)))
		var open_xp: Variant = day_open.get("xp", {})
		xp = open_xp.duplicate(true) if open_xp is Dictionary else xp


func _new_endless_state() -> Dictionary:
	return {
		"stamps": 0, "completed": 0, "failed": 0,
		"streak": 0, "best_streak": 0, "active": {}, "last_result": {},
	}


func _is_valid_recipe_id(recipe_id: String) -> bool:
	if recipe_id.is_empty():
		return false
	for recipe in GameData.recipes + GameData.dark_recipes:
		if String(recipe.get("id", "")) == recipe_id:
			return true
	return false


func _normalize_dark_menu(value: Variant) -> Array:
	if not value is Array:
		return []
	var result: Array = []
	for raw_entry in value:
		if result.size() >= 3:
			break
		var entry: Dictionary = {}
		if raw_entry is Dictionary:
			var kind := String(raw_entry.get("kind", ""))
			if kind == "legend":
				var recipe_id := String(raw_entry.get("recipe_id", ""))
				var recipe := _dark_recipe_by_id(recipe_id)
				if not recipe.is_empty():
					entry = {"kind": "legend", "recipe_id": recipe_id}
			elif kind == "mystery":
				entry = {"kind": "mystery", "serial": clampi(int(raw_entry.get("serial", result.size() + 1)), 1, 99)}
				# v22 keeps the exact failed trial formula. Older mystery slots remain
				# visible as legacy collectibles, but only recoverable formulas can
				# become real customer orders.
				var base_id := String(raw_entry.get("base", ""))
				var milk_id := String(raw_entry.get("milk", ""))
				var topping_ids: Array = []
				if raw_entry.get("toppings", []) is Array:
					for topping_id in raw_entry.get("toppings", []):
						topping_ids.append(String(topping_id))
				if not base_id.is_empty() and not milk_id.is_empty():
					entry["base"] = base_id
					entry["milk"] = milk_id
					entry["toppings"] = topping_ids
					entry["sugar"] = clampi(int(raw_entry.get("sugar", 50)), 0, 100)
					entry["quality"] = clampi(int(raw_entry.get("quality", 0)), 0, 100)
					entry["price"] = maxi(1, int(raw_entry.get("price", 12 + topping_ids.size() * 2)))
			elif kind == "legacy":
				var legacy_name := String(raw_entry.get("name", "")).strip_edges().left(40)
				if not legacy_name.is_empty():
					entry = {"kind": "legacy", "name": legacy_name}
		elif raw_entry is String:
			var old_name := String(raw_entry).strip_edges().left(40)
			for recipe in GameData.dark_recipes:
				if old_name == String(recipe.get("name", "")):
					entry = {"kind": "legend", "recipe_id": String(recipe["id"])}
					break
			if entry.is_empty():
				var number_match := RegEx.create_from_string("(\\d+)$").search(old_name)
				if number_match != null:
					entry = {"kind": "mystery", "serial": clampi(int(number_match.get_string(1)), 1, 99)}
				elif not old_name.is_empty():
					entry = {"kind": "legacy", "name": old_name}
		if not entry.is_empty():
			if raw_entry is Dictionary and int(raw_entry.get("sales", 0)) > 0:
				entry["sales"] = maxi(0, int(raw_entry.get("sales", 0)))
			result.append(entry)
	return result


func dark_menu_name(entry: Variant) -> String:
	if not entry is Dictionary:
		return String(entry)
	match String(entry.get("kind", "")):
		"legend":
			var recipe := _dark_recipe_by_id(String(entry.get("recipe_id", "")))
			return GameLocale.recipe_name(recipe) if not recipe.is_empty() else ""
		"mystery":
			return GameLocale.text("NIGHT_MYSTERY_DRINK", [int(entry.get("serial", 1))])
		"legacy":
			return String(entry.get("name", ""))
	return ""


func _dark_recipe_by_id(recipe_id: String) -> Dictionary:
	for recipe in GameData.dark_recipes:
		if String(recipe.get("id", "")) == recipe_id:
			return recipe
	return {}


func _is_valid_affinity_pair(pair_key: String) -> bool:
	var parts := pair_key.split("|")
	if parts.size() != 2:
		return false
	var base_valid := false
	var milk_valid := false
	for item in GameData.bases:
		if String(item.get("id", "")) == String(parts[0]):
			base_valid = true
			break
	for item in GameData.milks:
		if String(item.get("id", "")) == String(parts[1]):
			milk_valid = true
			break
	return base_valid and milk_valid


func _normalize_research_brief(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var source: Dictionary = value
	var brief_type := String(source.get("type", ""))
	if brief_type not in ["pair", "mastery", "balanced"]:
		return {}
	var assigned_day := clampi(int(source.get("assigned_day", day)), 1, maxi(1, day))
	var target := clampi(int(source.get("target", 1)), 1, 3)
	var result := {
		"type": brief_type,
		"assigned_day": assigned_day,
		"progress": clampi(int(source.get("progress", 0)), 0, target),
		"target": target,
		"reward": 2,
		"completed": bool(source.get("completed", false)),
		"completed_day": clampi(int(source.get("completed_day", 0)), 0, maxi(1, day)),
	}
	if brief_type == "pair":
		var pair := "%s|%s" % [String(source.get("base", "")), String(source.get("milk", ""))]
		if not _is_valid_affinity_pair(pair):
			return {}
		result["base"] = String(source.get("base", ""))
		result["milk"] = String(source.get("milk", ""))
		result["target"] = 1
		result["progress"] = clampi(int(result["progress"]), 0, 1)
	elif brief_type == "mastery":
		var ingredient_id := String(source.get("ingredient", ""))
		if ingredient_id == "none" or not _is_valid_ingredient_id(ingredient_id):
			return {}
		result["ingredient"] = ingredient_id
		result["target"] = 2
		result["progress"] = clampi(int(result["progress"]), 0, 2)
	else:
		result["quality"] = clampi(int(source.get("quality", 75)), 60, 90)
		result["target"] = 1
		result["progress"] = clampi(int(result["progress"]), 0, 1)
	if int(result["progress"]) >= int(result["target"]):
		result["completed"] = true
	if bool(result["completed"]):
		result["progress"] = int(result["target"])
		if int(result["completed_day"]) <= 0:
			result["completed_day"] = assigned_day
	return result


func _normalize_market_settlement(value: Variant) -> Dictionary:
	if not value is Dictionary or phase != "night":
		return {}
	var source: Dictionary = value
	if int(source.get("day", 0)) != day:
		return {}
	var loaded_results: Variant = source.get("results", [])
	if not loaded_results is Array:
		return {}
	var results: Array = []
	for value_result in loaded_results:
		# 合法上限：每晚预算 16 / 试做 2 点 = 8 次，每张检验卡存活 3 晚 → 24 张。
		# 超出部分只可能是损坏数据；正常游玩写入永不被丢弃。
		if not value_result is Dictionary or results.size() >= 24:
			continue
		var item: Dictionary = value_result
		var outcome := String(item.get("outcome", "testing"))
		if outcome not in ["testing", "hit", "signature", "regular", "failed"]:
			continue
		results.append({
			"name": String(item.get("name", "")).left(40),
			"stage": clampi(int(item.get("stage", 1)), 1, 3),
			"score": clampi(int(item.get("score", 0)), 0, 100),
			"average": clampf(float(item.get("average", 0.0)), 0.0, 100.0),
			"trend": clampi(int(item.get("trend", 0)), -100, 100),
			"outcome": outcome,
			"price": clampi(int(item.get("price", 0)), 0, 18),
			"refund": clampi(int(item.get("refund", 0)), 0, 3),
		})
	return {
		"day": day,
		"had_tests": bool(source.get("had_tests", not results.is_empty())),
		"results": results,
	}


func _is_valid_ingredient_id(ingredient_id: String) -> bool:
	for item in GameData.bases + GameData.milks + GameData.toppings:
		if String(item.get("id", "")) == ingredient_id:
			return true
	return false


func _normalize_endless_state(value: Variant) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	var result := _new_endless_state()
	for key in ["stamps", "completed", "failed", "streak", "best_streak"]:
		result[key] = maxi(0, int(source.get(key, 0)))
	result["best_streak"] = maxi(int(result["best_streak"]), int(result["streak"]))
	var active: Variant = source.get("active", {})
	if active is Dictionary and int(active.get("target_day", 0)) >= 16 \
			and String(active.get("id", "")) in ["streak_stage", "precision_shift", "revenue_sprint"]:
		result["active"] = active.duplicate(true)
	var last_result: Variant = source.get("last_result", {})
	if last_result is Dictionary:
		result["last_result"] = last_result.duplicate(true)
	return result


func sound_volume() -> float:
	return sfx_volume()


func sfx_volume() -> float:
	return clampf(float(settings.get("sfx_volume", settings.get("sound_volume", 0.75))), 0.0, 1.0)


func music_volume() -> float:
	return clampf(float(settings.get("music_volume", 0.55)), 0.0, 1.0)


func reduced_motion() -> bool:
	return bool(settings.get("reduced_motion", false))


func haptics_enabled() -> bool:
	return bool(settings.get("haptics", true))


func window_mode() -> String:
	var value := String(settings.get("window_mode", "windowed"))
	return value if value in ["windowed", "borderless", "fullscreen"] else "windowed"


func resolution() -> String:
	var value := String(settings.get("resolution", "1280x720"))
	return value if value in VALID_RESOLUTIONS else "1280x720"


func locale() -> String:
	var value := String(settings.get("locale", "zh_CN"))
	return value if value in VALID_LOCALES else "zh_CN"


func key_binding(action_name: String, fallback: Key) -> Key:
	var bindings: Dictionary = settings.get("key_bindings", {})
	return int(bindings.get(action_name, fallback))


func _normalize_key_bindings(source: Dictionary) -> Dictionary:
	var result := {
		"game_pause": int(source.get("game_pause", KEY_ESCAPE)),
		"game_shake": int(source.get("game_shake", KEY_SPACE)),
		"staff_interact": int(source.get("staff_interact", KEY_F)),
	}
	var values := result.values()
	var unique := {}
	# 备料固定键 Q/E 与其他动作撞键同样回到默认（与冲突守卫一致，评审 R8）。
	var fixed_gameplay_keys := [KEY_Q, KEY_E]
	for value in values:
		unique[value] = true
		if int(value) <= 0 or int(value) in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META] \
				or int(value) in fixed_gameplay_keys:
			return {"game_pause": int(KEY_ESCAPE), "game_shake": int(KEY_SPACE), "staff_interact": int(KEY_F)}
	if unique.size() != result.size():
		return {"game_pause": int(KEY_ESCAPE), "game_shake": int(KEY_SPACE), "staff_interact": int(KEY_F)}
	return result


func _normalize_staff(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var source: Dictionary = value
	var staff_id := String(source.get("id", ""))
	var candidate: Dictionary = {}
	for item in GameData.staff_list:
		if String(item.get("id", "")) == staff_id:
			candidate = item
			break
	if candidate.is_empty():
		return {}
	var result := candidate.duplicate(true)
	result["trait_revealed"] = bool(source.get("trait_revealed", false))
	result["days_worked"] = maxi(0, int(source.get("days_worked", 0)))
	result["wage_shortfalls"] = maxi(0, int(source.get("wage_shortfalls", 0)))
	var rest_day := clampi(int(source.get("rest_day", 0)), 0, day + 1)
	if rest_day < day:
		rest_day = 0
	result["rest_day"] = rest_day
	result["wage_shortfall"] = clampi(int(source.get("wage_shortfall", 0)), 0, int(candidate.get("wage", 0))) \
		if rest_day > 0 else 0
	return result


func _new_campaign_stats() -> Dictionary:
	return {
		"revenue": 0, "served": 0, "angry": 0, "stars": 0,
		"event_bonus": 0, "buzz_earned": 0, "special_served": 0,
		"staff_wages": 0, "staff_interactions": 0, "staff_days": 0,
		"staff_shortfalls": 0, "staff_rest_days": 0,
		"operating_costs": 0, "rent_paid": 0, "cost_relief": 0,
		"route_bonus": 0,
		"days_completed": 0, "best_streak": 0, "recorded_days": [], "tracking_start_day": 1,
		"day_stars": {}, "relief_days": 0,
	}


func _normalize_campaign_stats(value: Variant) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	var result := _new_campaign_stats()
	result["tracking_start_day"] = clampi(int(source.get("tracking_start_day", day)), 1, 14)
	for key in ["revenue", "served", "angry", "stars", "event_bonus", "buzz_earned", "special_served", "staff_wages", "staff_interactions", "staff_days", "staff_shortfalls", "staff_rest_days", "operating_costs", "rent_paid", "cost_relief", "route_bonus", "days_completed", "best_streak"]:
		result[key] = maxi(0, int(source.get(key, result[key])))
	var days: Array = source.get("recorded_days", []) if source.get("recorded_days", []) is Array else []
	for value_day in days:
		var number := int(value_day)
		if number >= 1 and number <= 14 and not result["recorded_days"].has(number):
			result["recorded_days"].append(number)
	result["days_completed"] = result["recorded_days"].size()
	return result


func yesterday_stars(day_number: int) -> int:
	## 前一战役日的星数；未记录（新档/无尽/跨战役）返回 -1。
	var day_stars: Dictionary = campaign_stats.get("day_stars", {})
	return int(day_stars.get(day_number - 1, -1))


func record_campaign_day(day_number: int, stats: Dictionary) -> void:
	if day_number < 1 or day_number > 14:
		return
	var days: Array = campaign_stats.get("recorded_days", [])
	if days.has(day_number):
		return
	days.append(day_number)
	# 逐日星数与回暖日计数：封顶宽限（D5）据此判定与统计。
	var day_stars: Dictionary = campaign_stats.get("day_stars", {})
	day_stars[day_number] = int(stats.get("stars", 0))
	campaign_stats["day_stars"] = day_stars
	if bool(stats.get("relief", false)):
		campaign_stats["relief_days"] = int(campaign_stats.get("relief_days", 0)) + 1
	campaign_stats["recorded_days"] = days
	campaign_stats["days_completed"] = days.size()
	campaign_stats["revenue"] = int(campaign_stats.get("revenue", 0)) + int(stats.get("earned", 0))
	campaign_stats["served"] = int(campaign_stats.get("served", 0)) + int(stats.get("served", 0))
	campaign_stats["angry"] = int(campaign_stats.get("angry", 0)) + int(stats.get("angry", 0))
	campaign_stats["stars"] = int(campaign_stats.get("stars", 0)) + int(stats.get("stars", 0))
	campaign_stats["event_bonus"] = int(campaign_stats.get("event_bonus", 0)) + int(stats.get("event_bonus", 0))
	campaign_stats["buzz_earned"] = int(campaign_stats.get("buzz_earned", 0)) + int(stats.get("buzz_earned", stats.get("event_buzz", 0)))
	campaign_stats["special_served"] = int(campaign_stats.get("special_served", 0)) + int(stats.get("special_served", 0))
	campaign_stats["staff_wages"] = int(campaign_stats.get("staff_wages", 0)) + int(stats.get("staff_wage", 0))
	campaign_stats["staff_shortfalls"] = int(campaign_stats.get("staff_shortfalls", 0)) + (1 if int(stats.get("staff_wage_shortfall", 0)) > 0 else 0)
	campaign_stats["staff_rest_days"] = int(campaign_stats.get("staff_rest_days", 0)) + (1 if bool(stats.get("staff_rest_day", false)) else 0)
	campaign_stats["operating_costs"] = int(campaign_stats.get("operating_costs", 0)) + int(stats.get("operating_cost", 0))
	campaign_stats["rent_paid"] = int(campaign_stats.get("rent_paid", 0)) + int(stats.get("rent_paid", 0))
	campaign_stats["cost_relief"] = int(campaign_stats.get("cost_relief", 0)) + int(stats.get("cost_relief", 0))
	campaign_stats["route_bonus"] = int(campaign_stats.get("route_bonus", 0)) + int(stats.get("route_bonus", 0))
	campaign_stats["staff_interactions"] = int(campaign_stats.get("staff_interactions", 0)) + int(stats.get("staff_wakes", 0)) + int(stats.get("staff_rescues", 0))
	if bool(stats.get("staff_on_duty", false)):
		campaign_stats["staff_days"] = int(campaign_stats.get("staff_days", 0)) + 1
	campaign_stats["best_streak"] = maxi(int(campaign_stats.get("best_streak", 0)), int(stats.get("best_streak", 0)))


func build_campaign_summary() -> Dictionary:
	var perfect_score := clampi(roundi(float(perfect_total) / 140.0 * 20.0), 0, 20)
	var upgrade_score := clampi(roundi(float(UpgradeCatalog.total_levels()) / float(UpgradeCatalog.total_max_levels()) * 15.0), 0, 15)
	var craft_score := perfect_score + upgrade_score
	var discoveries := discovered.size() + dark_discovered.size()
	var discovery_score := clampi(roundi(float(discoveries) / 5.0 * 15.0), 0, 15)
	var menu_score := clampi(roundi(float(menu.size()) / 3.0 * 15.0), 0, 15)
	var creativity_score := discovery_score + menu_score
	var coin_score := clampi(roundi(float(coins) / 900.0 * 10.0), 0, 10)
	# Night research intentionally consumes live buzz, so campaign grading uses the
	# earned-across-days ledger rather than the usually-zero current balance.
	var cumulative_buzz := int(campaign_stats.get("buzz_earned", 0))
	var buzz_score := clampi(roundi(float(cumulative_buzz) / 36.0 * 10.0), 0, 10)
	var momentum_score := coin_score + buzz_score
	var completed_days := int(campaign_stats.get("days_completed", 0))
	var expected_days := maxi(1, 15 - int(campaign_stats.get("tracking_start_day", 1)))
	var star_score := 0
	if completed_days > 0:
		star_score = clampi(roundi(float(campaign_stats.get("stars", 0)) / float(completed_days * 3) * 12.0), 0, 12)
	var journey_score := clampi(star_score + roundi(float(mini(completed_days, expected_days)) / float(expected_days) * 3.0), 0, 15)
	var score := craft_score + creativity_score + momentum_score + journey_score
	var grade := "C"
	var title := GameLocale.text("CAMPAIGN_TITLE_C")
	var verdict := GameLocale.text("CAMPAIGN_VERDICT_C")
	if score >= 85:
		grade = "S"
		title = GameLocale.text("CAMPAIGN_TITLE_S")
		verdict = GameLocale.text("CAMPAIGN_VERDICT_S")
	elif score >= 70:
		grade = "A"
		title = GameLocale.text("CAMPAIGN_TITLE_A")
		verdict = GameLocale.text("CAMPAIGN_VERDICT_A")
	elif score >= 55:
		grade = "B"
		title = GameLocale.text("CAMPAIGN_TITLE_B")
		verdict = GameLocale.text("CAMPAIGN_VERDICT_B")
	return {
		"score": score, "grade": grade, "title": title, "verdict": verdict,
		"craft": craft_score, "creativity": creativity_score,
		"momentum": momentum_score, "journey": journey_score,
		"perfect": perfect_total, "upgrade_levels": UpgradeCatalog.total_levels(),
		"discoveries": discoveries, "menu_count": menu.size(), "coins": coins,
		"buzz": cumulative_buzz, "stats": campaign_stats.duplicate(true),
		"staff_id": String(staff.get("id", "")), "staff_name": GameLocale.staff_name(staff) if not staff.is_empty() else GameLocale.text("STAFF_SOLO"),
	}


func finalize_campaign() -> Dictionary:
	if campaign_summary.is_empty():
		campaign_summary = build_campaign_summary()
	if not campaign_claimed:
		campaign_claimed = true
		legacy["campaigns_completed"] = int(legacy.get("campaigns_completed", 0)) + 1
		if new_shop_route in VALID_NEW_SHOP_ROUTES:
			var cleared: Array = legacy.get("routes_cleared", [])
			if new_shop_route not in cleared:
				cleared.append(new_shop_route)
			legacy["routes_cleared"] = cleared
		var score := int(campaign_summary.get("score", 0))
		if score > int(legacy.get("best_score", 0)):
			legacy["best_score"] = score
			legacy["best_grade"] = String(campaign_summary.get("grade", "C"))
	phase = "campaign"
	save_game()
	return campaign_summary


func continue_after_campaign() -> void:
	day = maxi(day + 1, 15)
	phase = "day"
	mark_day_open()
	save_game()


func start_new_shop_plus(route_id := "rush") -> Dictionary:
	var grade := String(campaign_summary.get("grade", "C"))
	var bonus_by_grade := {
		"S": {"coins": 80, "inspiration": 3},
		"A": {"coins": 60, "inspiration": 2},
		"B": {"coins": 40, "inspiration": 1},
		"C": {"coins": 20, "inspiration": 0},
	}
	var bonus: Dictionary = bonus_by_grade.get(grade, bonus_by_grade["C"])
	var safe_route := route_id if route_id in VALID_NEW_SHOP_ROUTES else "rush"
	reset_progress()
	coins = int(bonus["coins"])
	inspiration = int(bonus["inspiration"])
	new_shop_route = safe_route
	tutorial_completed = true
	# 重标记：New Shop+ 的起步奖金属于合法开店余额，不能被快照回滚抹掉。
	mark_day_open()
	save_game()
	var result := bonus.duplicate(true)
	result["route"] = safe_route
	return result
