## 原生本地化入口：语言持久化、格式化消息和数据表名称映射。
extends Node

signal locale_changed(locale: String)

func _ready() -> void:
	TranslationServer.set_locale(current())


func current() -> String:
	var value := String(GameState.settings.get("locale", "zh_CN"))
	return value if value in GameState.VALID_LOCALES else "zh_CN"


func set_locale(locale: String, persist := true) -> void:
	var safe := locale if locale in GameState.VALID_LOCALES else "zh_CN"
	GameState.settings["locale"] = safe
	TranslationServer.set_locale(safe)
	if persist:
		GameState.save_game()
	locale_changed.emit(safe)


func toggle() -> void:
	set_locale("en" if current() == "zh_CN" else "zh_CN")


func text(key: String, values: Array = []) -> String:
	var translated := tr(key)
	return translated % values if not values.is_empty() else translated


func ingredient_name(item: Variant) -> String:
	if not item is Dictionary:
		return ""
	var key := ""
	if item.has("value"):
		key = "SUGAR_%d" % int(item["value"])
	elif item.has("id"):
		key = "INGREDIENT_%s" % String(item["id"]).to_upper()
	return _data_text(key, String(item.get("name", "")))


func ingredient_short_name(item: Variant) -> String:
	if not item is Dictionary:
		return ""
	var key := ""
	if item.has("value"):
		key = "SUGAR_%d_SHORT" % int(item["value"])
	elif item.has("id"):
		key = "INGREDIENT_%s_SHORT" % String(item["id"]).to_upper()
	return _data_text(key, ingredient_name(item))


func recipe_name(item: Dictionary) -> String:
	return _data_text("RECIPE_%s_NAME" % String(item.get("id", "")).to_upper(), String(item.get("name", "")))


func recipe_description(item: Dictionary) -> String:
	return _data_text("RECIPE_%s_DESC" % String(item.get("id", "")).to_upper(), String(item.get("desc", "")))


func recipe_hint(item: Dictionary) -> String:
	return _data_text("RECIPE_%s_HINT" % String(item.get("id", "")).to_upper(), String(item.get("desc", "")))


func staff_name(item: Dictionary) -> String:
	return _data_text("STAFF_%s_NAME" % String(item.get("id", "")).to_upper(), String(item.get("name", "")))


func staff_intro(item: Dictionary) -> String:
	return _data_text("STAFF_%s_INTRO" % String(item.get("id", "")).to_upper(), String(item.get("intro", "")))


func tier_name(value: String) -> String:
	return _data_text("TIER_%s" % value.to_upper(), value)


func affinity_note(rule: Dictionary) -> String:
	var tags: Array = rule.get("tags", [])
	if tags.size() < 2:
		return String(rule.get("note", ""))
	var key := "AFFINITY_%s_%s" % [String(tags[0]).to_upper(), String(tags[1]).to_upper()]
	return _data_text(key, String(rule.get("note", "")))


func slot_name(value: String) -> String:
	var aliases := {"茶底": "BASE", "奶基": "MILK", "小料": "TOPPING", "sugar": "SUGAR"}
	var suffix := String(aliases.get(value, value.to_upper()))
	return _data_text("SLOT_%s" % suffix, value)


func _data_text(key: String, fallback: String) -> String:
	if key.is_empty():
		return fallback
	var translated := tr(key)
	return fallback if translated == key else translated
