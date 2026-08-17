## 夜间上新与白天经营的桥梁：三款主推、真实配方订单、定价和逐日热度。
extends Node

signal menu_changed

const FEATURED_LIMIT := 3
const DARK_LIMIT := 3
const FRESH_ORDER_INTERVAL := 4
const STALE_ORDER_INTERVAL := 6
const DARK_ORDER_INTERVAL := 5
## DP#4 市场检验定价：每分档三个作者化价点（让利/标准/溢价）。定价是真实的
## 频次-毛利取舍——让利每款提速 2% 到店，溢价每款放慢 3%；标准价保持原行为。
const PRICE_OPTIONS := {
	"爆款": [16, 18, 21],
	"招牌": [13, 15, 17],
	"普通": [10, 12, 14],
}
const PRICE_STANDARD := {"爆款": 18, "招牌": 15, "普通": 12}


func _ready() -> void:
	ensure_normalized()


func ensure_normalized() -> void:
	var normalized: Array = []
	var seen: Array[String] = []
	for index in GameState.menu.size():
		var raw: Variant = GameState.menu[index]
		if not raw is Dictionary:
			continue
		var item := _normalize_item(raw, index)
		var item_id := String(item.get("id", ""))
		if item_id.is_empty() or item_id in seen:
			continue
		seen.append(item_id)
		normalized.append(item)
	GameState.menu = normalized

	var selected: Array = []
	for item_id in GameState.featured_menu:
		var item := _find_in(GameState.menu, String(item_id))
		if not item.is_empty() and formula_available(item) and item_id not in selected:
			selected.append(String(item_id))
			if selected.size() >= featured_limit():
				break
	if selected.is_empty():
		for item in GameState.menu:
			if formula_available(item):
				selected.append(String(item["id"]))
				if selected.size() >= featured_limit():
					break
	GameState.featured_menu = selected


func items() -> Array:
	ensure_normalized()
	return GameState.menu


func featured_items() -> Array:
	ensure_normalized()
	var result: Array = []
	for item_id in GameState.featured_menu:
		var item := _find_in(GameState.menu, String(item_id))
		if not item.is_empty() and formula_available(item):
			result.append(item)
	return result


func item(item_id: String) -> Dictionary:
	ensure_normalized()
	return _find_in(GameState.menu, item_id)


func register_legend(recipe: Dictionary, persist := false) -> Dictionary:
	ensure_normalized()
	var item_id := "legend:%s" % String(recipe.get("id", ""))
	var existing := _find_in(GameState.menu, item_id)
	if not existing.is_empty():
		return existing
	var created := _legend_item(recipe)
	GameState.menu.append(created)
	_auto_feature(String(created["id"]))
	if persist:
		GameState.save_game()
	menu_changed.emit()
	return created


func register_custom(test: Dictionary, tier: String, price: int, persist := false) -> Dictionary:
	ensure_normalized()
	var item_id := _next_custom_id()
	var sugar_value := int(test.get("sugar", 50))
	var created := {
		"id": item_id, "type": "custom", "source_id": "",
		"name": String(test.get("name", GameLocale.text("NIGHT_MYSTERY_DRINK", [GameState.menu.size() + 1]))),
		"tier": tier, "price": price,
		"base": String(test.get("base", "")), "milk": String(test.get("milk", "")),
		"toppings": _string_array(test.get("toppings", [])), "sugar": [sugar_value, sugar_value],
		"quality": int(test.get("quality", 0)), "listed_day": GameState.day,
		"hype_days": _hype_days_for_tier(tier), "hype_remaining": _hype_days_for_tier(tier),
		"sales": 0,
	}
	GameState.menu.append(created)
	_auto_feature(item_id)
	if persist:
		GameState.save_game()
	menu_changed.emit()
	return created


func is_featured(item_id: String) -> bool:
	return item_id in GameState.featured_menu


## 返回 ok / full / minimum / invalid，供菜单面板给出明确反馈。
## 主推槽上限：周转区（D3）牺牲第三槽换 ×0.85 到店速度。
func featured_limit() -> int:
	return LegacyRoutes.featured_slot_limit()


## 潮流区夜间自动锁槽（D3）：把第一个主推位锁定为明日事件最佳匹配。
## 手动覆盖在当晚有效，次夜进入研发室时重新锁定。
func apply_trend_pin() -> void:
	if LegacyRoutes.active_id() != "trend":
		return
	ensure_normalized()
	if GameState.menu.is_empty():
		return
	var tomorrow := DailyEvents.next_event(GameState.day)
	var best_id := ""
	var best_bonus := -1
	for item_data in GameState.menu:
		if not formula_available(item_data):
			continue
		var bonus := int(event_match_bonus(item_data, String(tomorrow.get("id", "calm"))))
		if bonus > best_bonus:
			best_bonus = bonus
			best_id = String(item_data["id"])
	if best_id.is_empty() or best_id in GameState.featured_menu:
		return
	if not GameState.featured_menu.is_empty():
		GameState.featured_menu[0] = best_id
	else:
		GameState.featured_menu.append(best_id)
	menu_changed.emit()


func set_featured(item_id: String, active: bool, persist := true) -> String:
	ensure_normalized()
	var target := _find_in(GameState.menu, item_id)
	if target.is_empty() or not formula_available(target):
		return "invalid"
	if active:
		if item_id in GameState.featured_menu:
			return "ok"
		if GameState.featured_menu.size() >= featured_limit():
			return "full"
		GameState.featured_menu.append(item_id)
	else:
		if item_id not in GameState.featured_menu:
			return "ok"
		if GameState.featured_menu.size() <= 1:
			return "minimum"
		GameState.featured_menu.erase(item_id)
	if persist:
		GameState.save_game()
	menu_changed.emit()
	return "ok"


func formula_available(item_data: Dictionary) -> bool:
	if String(item_data.get("base", "")).is_empty() \
			or String(item_data.get("milk", "")).is_empty() \
			or not (item_data.get("toppings", []) is Array) \
			or not (item_data.get("sugar", []) is Array) \
			or item_data.get("sugar", []).size() < 2:
		return false
	# 结构有效还不够：配方里的每种原料都必须在当日已解锁，否则特色订单会
	# 要求玩家无法完成的配方（纵深防御：任何来源的越日配方都退回随机订单）。
	for ingredient_id in [String(item_data.get("base", "")), String(item_data.get("milk", ""))] \
			+ item_data.get("toppings", []):
		var ingredient := RecipeJournal.ingredient(String(ingredient_id))
		if ingredient.is_empty() or int(ingredient.get("unlock_day", 1)) > GameState.day:
			return false
	return true


func display_name(item_data: Dictionary) -> String:
	var source_id := String(item_data.get("source_id", ""))
	var recipe := RecipeJournal.recipe(source_id)
	return GameLocale.recipe_name(recipe) if not recipe.is_empty() else String(item_data.get("name", ""))


func formula_text(item_data: Dictionary) -> String:
	return RecipeJournal.formula(item_data) if formula_available(item_data) else GameLocale.text("MENU_BOARD_LEGACY_FORMULA")


func hot_featured_count() -> int:
	var count := 0
	for item_data in featured_items():
		if int(item_data.get("hype_remaining", 0)) > 0:
			count += 1
	return count


func traffic_multiplier() -> float:
	# [P9-1 2026-08-17] 定价不再作用全局到店间隔（三槽饱和区被 ±1 杯噪声淹没，
	# 全溢价事实占优）——让利/溢价改为只影响该款主推订单的出现节奏（pricing_spawn_slots）。
	return (1.0 - LegacyRoutes.menu_traffic_step() * float(hot_featured_count())) \
		* buzz_traffic_multiplier()


## [P9-1/P9-2 2026-08-17] 定价轮转权重：主推中的自创饮品按价点偏离标准价的幅度
## 改变“该款”被点单的频率——让利款占 3 个轮转位（更常被点），标准 2 位，
## 溢价款 1 位（更少被点）。传说保持作者定价，不参与调价（与 price_options 对齐）。
func pricing_spawn_slots(item_data: Dictionary) -> int:
	const SLOTS := { "budget": 3, "standard": 2, "premium": 1 }
	var tier := String(item_data.get("tier", ""))
	var standard := int(PRICE_STANDARD.get(tier, 0))
	if String(item_data.get("type", "")) != "custom" or standard == 0:
		return SLOTS["standard"]
	var diff := int(item_data.get("price", standard)) - standard
	if diff <= -2:
		return SLOTS["budget"]
	if diff >= 2:
		return SLOTS["premium"]
	return SLOTS["standard"]


## 自创饮品可选价点（让利/标准/溢价）；传说配方保持作者定价，不参与调价。
func price_options(item_data: Dictionary) -> Array:
	if String(item_data.get("type", "")) != "custom":
		return []
	var tier := String(item_data.get("tier", ""))
	return (PRICE_OPTIONS.get(tier, []) as Array).duplicate()


func set_item_price(item_id: String, price: int, persist := true) -> bool:
	ensure_normalized()
	var item := _find_in(GameState.menu, item_id)
	if item.is_empty() or price not in price_options(item):
		return false
	item["price"] = price
	if persist:
		GameState.save_game()
	menu_changed.emit()
	return true


func buzz_traffic_multiplier(day_number := -1) -> float:
	var target_day := GameState.day if day_number < 0 else day_number
	if GameState.buzz_traffic_day != target_day:
		return 1.0
	# Real completed dark orders create tomorrow's foot traffic. The cap keeps a
	# great novelty day exciting without turning the three-slot queue into a flood.
	return 1.0 - minf(0.12, float(GameState.buzz_traffic) * 0.02)


func should_offer(spawn_number: int, kind: String, _event_id := "") -> bool:
	if kind != "regular" or featured_items().is_empty():
		return false
	var interval := FRESH_ORDER_INTERVAL if hot_featured_count() > 0 else STALE_ORDER_INTERVAL
	return spawn_number >= 2 and (spawn_number - 2) % interval == 0


func featured_for_spawn(spawn_number: int, event_id := "") -> Dictionary:
	var featured := featured_items()
	if featured.is_empty():
		return {}
	var interval := FRESH_ORDER_INTERVAL if hot_featured_count() > 0 else STALE_ORDER_INTERVAL
	var sequence := maxi(0, (spawn_number - 2) / interval)
	# 当日风向匹配款获得双倍轮转权重，但不会挤掉其他主推。
	# 这让夜间换菜单成为可预判策略，而不是永远选择最高价三款。
	# [P9-1 2026-08-17] 每款占位数 = pricing_spawn_slots（标准 2 位与旧行为同比例；
	# 让利 3 位更常被点、溢价 1 位更少被点），匹配款位翻倍且优先入列。
	var rotation: Array = []
	for item_data in featured:
		if event_match_bonus(item_data, event_id) > 0:
			for _slot in range(pricing_spawn_slots(item_data) * 2):
				rotation.append(item_data)
	for item_data in featured:
		if event_match_bonus(item_data, event_id) <= 0:
			for _slot in range(pricing_spawn_slots(item_data)):
				rotation.append(item_data)
	return rotation[sequence % rotation.size()]


func order_for_item(item_data: Dictionary, spawn_number: int, event_id := "") -> Dictionary:
	if not formula_available(item_data):
		return {}
	var sugar_range: Array = item_data.get("sugar", [50, 50])
	var sugar_index := (spawn_number / FRESH_ORDER_INTERVAL) % mini(2, sugar_range.size())
	var sugar_value := int(sugar_range[sugar_index])
	var topping_items: Array = []
	for topping_id in item_data.get("toppings", []):
		var topping := RecipeJournal.ingredient(String(topping_id))
		if not topping.is_empty():
			topping_items.append(topping)
	var sugar_item := _sugar_item(sugar_value)
	var base := RecipeJournal.ingredient(String(item_data.get("base", "")))
	var milk := RecipeJournal.ingredient(String(item_data.get("milk", "")))
	if base.is_empty() or milk.is_empty() or sugar_item.is_empty():
		return {}
	var order := {
		"base": base, "milk": milk, "tops": topping_items, "sugar": sugar_item,
		"menu_item_id": String(item_data.get("id", "")),
	}
	var match_bonus := event_match_bonus(item_data, event_id)
	if match_bonus > 0:
		order["menu_event_bonus"] = match_bonus
	return order


# ---------------------------------------------------------------- Dark menu

func dark_items() -> Array:
	var result: Array = []
	for entry in GameState.dark_menu:
		if entry is Dictionary:
			result.append(entry)
	return result


func dark_order_items() -> Array:
	var result: Array = []
	for entry in dark_items():
		if dark_formula_available(entry):
			result.append(entry)
	return result


func dark_item_id(entry: Dictionary) -> String:
	match String(entry.get("kind", "")):
		"legend":
			return "legend:%s" % String(entry.get("recipe_id", ""))
		"mystery":
			return "mystery:%d" % int(entry.get("serial", 0))
	return ""


func dark_formula(entry: Dictionary) -> Dictionary:
	if String(entry.get("kind", "")) == "legend":
		return RecipeJournal.recipe(String(entry.get("recipe_id", "")))
	if String(entry.get("kind", "")) != "mystery":
		return {}
	var sugar_value := int(entry.get("sugar", -1))
	return {
		"id": dark_item_id(entry), "name": GameState.dark_menu_name(entry),
		"base": String(entry.get("base", "")), "milk": String(entry.get("milk", "")),
		"toppings": _string_array(entry.get("toppings", [])),
		"sugar": [sugar_value, sugar_value], "price": int(entry.get("price", 12)),
		"quality": int(entry.get("quality", 0)),
	}


func dark_formula_available(entry: Dictionary) -> bool:
	var formula := dark_formula(entry)
	if not formula_available(formula):
		return false
	if RecipeJournal.ingredient(String(formula.get("base", ""))).is_empty() \
			or RecipeJournal.ingredient(String(formula.get("milk", ""))).is_empty():
		return false
	for topping_id in formula.get("toppings", []):
		if RecipeJournal.ingredient(String(topping_id)).is_empty():
			return false
	return not _sugar_item(int(formula.get("sugar", [-1])[0])).is_empty()


func dark_display_name(entry: Dictionary) -> String:
	return GameState.dark_menu_name(entry)


func dark_formula_text(entry: Dictionary) -> String:
	var formula := dark_formula(entry)
	return RecipeJournal.formula(formula) if dark_formula_available(entry) \
		else GameLocale.text("MENU_BOARD_LEGACY_FORMULA")


func dark_sale_price(entry: Dictionary) -> int:
	var formula := dark_formula(entry)
	if formula.is_empty():
		return 12
	if formula.has("price"):
		return maxi(1, int(formula["price"]))
	return 12 + 2 * int(formula.get("toppings", []).size())


func dark_should_offer(spawn_number: int, kind: String) -> bool:
	return kind == "regular" and not dark_order_items().is_empty() \
		and spawn_number >= 3 and (spawn_number - 3) % DARK_ORDER_INTERVAL == 0


func dark_for_spawn(spawn_number: int) -> Dictionary:
	var available := dark_order_items()
	if available.is_empty():
		return {}
	var sequence := maxi(0, (spawn_number - 3) / DARK_ORDER_INTERVAL)
	return available[sequence % available.size()]


func dark_order_for_entry(entry: Dictionary, spawn_number: int) -> Dictionary:
	var formula := dark_formula(entry)
	if not dark_formula_available(entry):
		return {}
	var sugar_range: Array = formula.get("sugar", [50, 50])
	var sugar_value := int(sugar_range[spawn_number % mini(2, sugar_range.size())])
	var toppings: Array = []
	for topping_id in formula.get("toppings", []):
		toppings.append(RecipeJournal.ingredient(String(topping_id)))
	return {
		"base": RecipeJournal.ingredient(String(formula["base"])),
		"milk": RecipeJournal.ingredient(String(formula["milk"])),
		"tops": toppings, "sugar": _sugar_item(sugar_value),
		"dark_menu_id": dark_item_id(entry),
	}


func dark_candidate_for_legend(recipe_id: String) -> Dictionary:
	var recipe := RecipeJournal.recipe(recipe_id)
	if recipe.is_empty() or not RecipeJournal.is_dark(recipe):
		return {}
	return {"kind": "legend", "recipe_id": recipe_id}


func dark_candidate_for_trial(base_id: String, milk_id: String, topping_ids: Array,
		sugar_value: int, quality: int) -> Dictionary:
	var serial := 1
	for entry in GameState.dark_menu:
		if entry is Dictionary and String(entry.get("kind", "")) == "mystery":
			serial = maxi(serial, int(entry.get("serial", 0)) + 1)
	return {
		"kind": "mystery", "serial": clampi(serial, 1, 99),
		"base": base_id, "milk": milk_id, "toppings": _string_array(topping_ids),
		"sugar": clampi(sugar_value, 0, 100), "quality": clampi(quality, 0, 100),
		"price": 12 + 2 * topping_ids.size(),
	}


func install_dark_candidate(candidate: Dictionary, slot := -1, persist := true) -> bool:
	if candidate.is_empty() or not dark_formula_available(candidate):
		return false
	var existing_id := dark_item_id(candidate)
	for entry in GameState.dark_menu:
		if entry is Dictionary and dark_item_id(entry) == existing_id:
			return true
	var installed := candidate.duplicate(true)
	if slot >= 0 and slot < GameState.dark_menu.size():
		GameState.dark_menu[slot] = installed
	elif GameState.dark_menu.size() < DARK_LIMIT:
		GameState.dark_menu.append(installed)
	else:
		return false
	if persist:
		GameState.save_game()
	menu_changed.emit()
	return true


func remove_dark_slot(slot: int, persist := true) -> bool:
	if slot < 0 or slot >= GameState.dark_menu.size():
		return false
	GameState.dark_menu.remove_at(slot)
	if persist:
		GameState.save_game()
	menu_changed.emit()
	return true


func record_dark_sale(item_id: String) -> void:
	for entry in GameState.dark_menu:
		if entry is Dictionary and dark_item_id(entry) == item_id:
			entry["sales"] = maxi(0, int(entry.get("sales", 0))) + 1
			menu_changed.emit()
			return


## 每日风向与主推配方的可预告咬合。奖励只作用于真实售出的匹配主推杯。
func event_match_bonus(item_data: Dictionary, event_id: String) -> int:
	if item_data.is_empty() or not formula_available(item_data):
		return 0
	var toppings: Array = item_data.get("toppings", [])
	var sugars: Array = item_data.get("sugar", [])
	match event_id:
		"lunch_rush":
			return 4 if toppings.size() <= 1 and int(item_data.get("price", 99)) <= 13 else 0
		"light_drinks":
			var max_sugar := 100
			if not sugars.is_empty():
				max_sugar = int(sugars.max())
			return 6 if String(item_data.get("milk", "")) == "none" and max_sugar <= 30 else 0
		"brown_sugar_trend":
			return 2 if "brown_sugar" in toppings else 0
		"critic_day":
			return 4 if String(item_data.get("tier", "")) == "招牌" else 0
		"influencer_day":
			return 4 if String(item_data.get("tier", "")) == "爆款" else 0
		"group_day":
			return 4 if toppings.size() >= 2 else 0
	return 0


func event_match_count(event_id: String) -> int:
	var count := 0
	for item_data in featured_items():
		if event_match_bonus(item_data, event_id) > 0:
			count += 1
	return count


func sale_price(item_data: Dictionary) -> int:
	return int(item_data.get("price", 10)) + (2 if int(item_data.get("hype_remaining", 0)) > 0 else 0)


func advance_day(day: int, sales_by_id: Dictionary) -> void:
	ensure_normalized()
	if GameState.menu_last_hype_day >= day:
		return
	for item_data in GameState.menu:
		var item_id := String(item_data.get("id", ""))
		item_data["sales"] = maxi(0, int(item_data.get("sales", 0))) + maxi(0, int(sales_by_id.get(item_id, 0)))
		item_data["hype_remaining"] = maxi(0, int(item_data.get("hype_remaining", 0)) - 1)
	GameState.menu_last_hype_day = day
	menu_changed.emit()


func hype_text(item_data: Dictionary) -> String:
	var remaining := int(item_data.get("hype_remaining", 0))
	return GameLocale.text("MENU_BOARD_HOT_DAYS", [remaining]) if remaining > 0 else GameLocale.text("MENU_BOARD_EVERGREEN")


func _normalize_item(raw: Dictionary, _index: int) -> Dictionary:
	var legend := _legend_for_raw(raw)
	if not legend.is_empty():
		var normalized := _legend_item(legend)
		_copy_progress(raw, normalized)
		return normalized
	var item_id := String(raw.get("id", ""))
	if item_id.is_empty():
		# 残缺项（无 id、无配方）直接丢弃：新项目无旧档，不做收藏兜底。
		return {}
	var tier := String(raw.get("tier", "普通"))
	var hype_days := maxi(1, int(raw.get("hype_days", _hype_days_for_tier(tier))))
	var sugar: Variant = raw.get("sugar", [])
	if sugar is int or sugar is float:
		sugar = [int(sugar), int(sugar)]
	return {
		"id": item_id, "type": String(raw.get("type", "")), "source_id": "",
		"name": String(raw.get("name", GameLocale.text("NIGHT_MYSTERY_DRINK", [_index + 1]))),
		"tier": tier, "price": maxi(1, int(raw.get("price", 10))),
		"base": String(raw.get("base", "")), "milk": String(raw.get("milk", "")),
		"toppings": _string_array(raw.get("toppings", [])), "sugar": sugar,
		"quality": int(raw.get("quality", 0)), "listed_day": maxi(1, int(raw.get("listed_day", GameState.day))),
		"hype_days": hype_days, "hype_remaining": clampi(int(raw.get("hype_remaining", hype_days)), 0, hype_days),
		"sales": maxi(0, int(raw.get("sales", 0))),
	}


func _legend_item(recipe: Dictionary) -> Dictionary:
	return {
		"id": "legend:%s" % String(recipe.get("id", "")), "type": "legend",
		"source_id": String(recipe.get("id", "")), "name": String(recipe.get("name", "")),
		"tier": String(recipe.get("tier", "普通")), "price": int(recipe.get("price", 10)),
		"base": String(recipe.get("base", "")), "milk": String(recipe.get("milk", "")),
		"toppings": _string_array(recipe.get("toppings", [])), "sugar": recipe.get("sugar", [50, 50]).duplicate(),
		"quality": 100, "listed_day": GameState.day,
		"hype_days": int(recipe.get("hype_days", 4)), "hype_remaining": int(recipe.get("hype_days", 4)),
		"sales": 0,
	}


func _copy_progress(raw: Dictionary, target: Dictionary) -> void:
	target["listed_day"] = maxi(1, int(raw.get("listed_day", GameState.day)))
	target["hype_remaining"] = clampi(int(raw.get("hype_remaining", target["hype_days"])), 0, int(target["hype_days"]))
	target["sales"] = maxi(0, int(raw.get("sales", 0)))


func _legend_for_raw(raw: Dictionary) -> Dictionary:
	var source_id := String(raw.get("source_id", ""))
	var raw_id := String(raw.get("id", ""))
	if source_id.is_empty() and raw_id.begins_with("legend:"):
		source_id = raw_id.trim_prefix("legend:")
	if source_id.is_empty():
		return {}
	var direct := RecipeJournal.recipe(source_id)
	return direct if not direct.is_empty() and not RecipeJournal.is_dark(direct) else {}


func _find_in(collection: Array, item_id: String) -> Dictionary:
	for item_data in collection:
		if String(item_data.get("id", "")) == item_id:
			return item_data
	return {}


func _auto_feature(item_id: String) -> void:
	if GameState.featured_menu.size() < featured_limit() and item_id not in GameState.featured_menu:
		GameState.featured_menu.append(item_id)


func _next_custom_id() -> String:
	var suffix := GameState.menu.size() + 1
	var candidate := "custom:%d:%d" % [GameState.day, suffix]
	while not _find_in(GameState.menu, candidate).is_empty():
		suffix += 1
		candidate = "custom:%d:%d" % [GameState.day, suffix]
	return candidate


func _sugar_item(value: int) -> Dictionary:
	for sugar in GameData.sugar_levels:
		if int(sugar.get("value", -1)) == value:
			return sugar
	return {}


func _hype_days_for_tier(tier: String) -> int:
	if tier == "爆款":
		return 6
	if tier == "招牌":
		return 5
	return 4


func _string_array(values: Variant) -> Array:
	var result: Array = []
	if values is Array:
		for value in values:
			result.append(String(value))
	return result
