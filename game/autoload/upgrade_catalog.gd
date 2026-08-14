## 店铺成长系统：把白天赚到的金币转化为可感知的操作效率与容错。
extends Node

const ITEMS := [
	{
		"id": "comfort",
		"name": "等候区软装",
		"max_level": 3,
		# 首级维持新手首日可买；中后级按跨天复利后的真实现金流定价。
		"costs": [60, 220, 520],
		"description": "舒适座椅和柔光装饰，让排队顾客更有耐心。",
		"effects": ["耐心 +18%", "耐心 +36%", "耐心 +54%"],
	},
	{
		"id": "shaker",
		"name": "自动摇茶机",
		"max_level": 3,
		"costs": [80, 260, 600],
		"description": "升级电机和封口模组，减少每杯需要的摇茶操作。",
		"effects": ["每杯摇 4 次", "每杯摇 3 次", "每杯摇 2 次"],
	},
	{
		"id": "smart_sugar",
		"name": "智能糖控台",
		"max_level": 1,
		"costs": [360],
		"description": "选好奶基后自动匹配当前订单糖度，少一步也少一次失误。",
		"effects": ["自动匹配糖度"],
	},
	{
		"id": "tip_jar",
		"name": "招牌小费罐",
		"max_level": 3,
		"costs": [70, 240, 520],
		"description": "提升服务仪式感，正确出杯会获得额外小费。",
		"effects": ["每杯额外 +1 金币", "每杯额外 +2 金币", "每杯额外 +3 金币"],
	},
]


func item(item_id: String) -> Dictionary:
	for data in ITEMS:
		if data["id"] == item_id:
			return _localized_item(data)
	return {}


func items() -> Array:
	var result: Array = []
	for data in ITEMS:
		result.append(_localized_item(data))
	return result


func _localized_item(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	var prefix := "UPGRADE_%s" % String(data["id"]).to_upper()
	data["name"] = GameLocale.text(prefix + "_NAME")
	data["description"] = GameLocale.text(prefix + "_DESCRIPTION")
	var effects: Array = []
	for index in range(data["effects"].size()):
		effects.append(GameLocale.text("%s_EFFECT_%d" % [prefix, index + 1]))
	data["effects"] = effects
	return data


func level(item_id: String) -> int:
	return int(GameState.upgrades.get(item_id, 0))


func next_cost(item_id: String) -> int:
	var data := item(item_id)
	var current := level(item_id)
	if data.is_empty() or current >= int(data["max_level"]):
		return -1
	return int(data["costs"][current])


func buy(item_id: String, persist := true) -> bool:
	var cost := next_cost(item_id)
	if cost < 0 or GameState.coins < cost:
		return false
	GameState.coins -= cost
	GameState.upgrades[item_id] = level(item_id) + 1
	if persist:
		GameState.save_game()
	return true


func patience_multiplier() -> float:
	return 1.0 + 0.18 * float(level("comfort"))


func shakes_needed() -> int:
	return maxi(2, 5 - level("shaker"))


func has_smart_sugar() -> bool:
	return level("smart_sugar") > 0


func tip_bonus() -> int:
	return level("tip_jar")


func total_levels() -> int:
	var total := 0
	for data in ITEMS:
		total += level(data["id"])
	return total


func total_max_levels() -> int:
	var total := 0
	for data in ITEMS:
		total += int(data["max_level"])
	return total


func total_tree_cost() -> int:
	var total := 0
	for data in ITEMS:
		for cost in data["costs"]:
			total += int(cost)
	return total


func next_day_reserve(day_number := -1) -> Dictionary:
	var current_day := GameState.day if day_number < 0 else day_number
	var tomorrow := current_day + 1
	var wage_due := StaffCatalog.wage() if StaffCatalog.is_on_duty(tomorrow) else 0
	var rent_due := OperatingCosts.rent_base(tomorrow)
	return {
		"day": tomorrow,
		"wage": wage_due,
		"rent": rent_due,
		"total": wage_due + rent_due,
		"investable": maxi(0, GameState.coins - wage_due - rent_due),
	}
