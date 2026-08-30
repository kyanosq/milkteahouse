## 店铺成长系统：把白天赚到的金币转化为可感知的操作效率与容错。
## 1.0 结构（D1②）：四线各 4 级（第四级为第二周高级档，刻意吃掉 Day11-14 闲钱），
## 外加 Day11 解锁、二选一的互斥“店铺定位”。
extends Node

const POSITIONING_UNLOCK_DAY := 11
const POSITIONING_COST := 600

const ITEMS := [
	{
		"id": "comfort",
		# 首级维持新手首日可买；中后级按跨天复利后的真实现金流定价；IV 为高级档。
		"costs": [60, 220, 520, 700],
	},
	{
		"id": "shaker",
		"costs": [80, 260, 600, 760],
	},
	{
		"id": "smart_sugar",
		"costs": [360, 820],
	},
	{
		"id": "tip_jar",
		"costs": [70, 240, 520, 900],
	},
]

## 互斥定位对：Day11 解锁，600 币二选一，收官报告展示所选定位。
const POSITIONINGS := [
	{
		"id": "positioning_flavor",
	},
	{
		"id": "positioning_craft",
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
	data["max_level"] = data["costs"].size()
	var prefix := "UPGRADE_%s" % String(data["id"]).to_upper()
	data["name"] = GameLocale.text(prefix + "_NAME")
	data["description"] = GameLocale.text(prefix + "_DESCRIPTION")
	var effects: Array = []
	for index in range(int(data["max_level"])):
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


# ---------------------------------------------------------------- 店铺定位

func positionings() -> Array:
	var result: Array = []
	for source: Dictionary in POSITIONINGS:
		var data: Dictionary = source.duplicate(true)
		data["cost"] = POSITIONING_COST
		data["unlock_day"] = POSITIONING_UNLOCK_DAY
		data["name"] = GameLocale.text("POSITIONING_%s_NAME" % String(source["id"]).to_upper())
		data["description"] = GameLocale.text("POSITIONING_%s_DESCRIPTION" % String(source["id"]).to_upper())
		data["effect"] = GameLocale.text("POSITIONING_%s_EFFECT" % String(source["id"]).to_upper())
		result.append(data)
	return result


func positioning() -> String:
	for source in POSITIONINGS:
		if level(String(source["id"])) > 0:
			return String(source["id"])
	return ""


func positioning_unlocked() -> bool:
	return GameState.day >= POSITIONING_UNLOCK_DAY


## [S1-D2 死档守卫 2026-08-17] 「风味」与智能糖台一级在 auto_sugar_after_milk()
## 完全同源（全仓唯一消费点），已购糖台后再买风味 = 600 币买 0。买键前置拦截。
func positioning_redundant(positioning_id: String) -> bool:
	return positioning_id == "positioning_flavor" and level("smart_sugar") >= 1


## 反向冗余：已持「风味」时糖台一级无新增效果（但它是糖台二级的必经前置，
## 不禁购，只给面板警告钩子——upgrade_panel 据 UPGRADE_SMART_SUGAR_REDUNDANT 标注）。
func smart_sugar_redundant() -> bool:
	return positioning() == "positioning_flavor" and level("smart_sugar") == 0


func buy_positioning(positioning_id: String, persist := true) -> bool:
	if not positioning_unlocked() or not positioning().is_empty():
		return false
	if positioning_redundant(positioning_id):
		return false
	for source in POSITIONINGS:
		if String(source["id"]) == positioning_id and GameState.coins >= POSITIONING_COST:
			GameState.coins -= POSITIONING_COST
			GameState.upgrades[positioning_id] = 1
			if persist:
				GameState.save_game()
			return true
	return false


# ---------------------------------------------------------------- 效果钩子

func patience_multiplier() -> float:
	# IV 级增益递减：前三级各 +18%，第四级 +12%。
	var current := level("comfort")
	return 1.0 + 0.18 * float(mini(current, 3)) + 0.12 * float(maxi(0, current - 3))


func shakes_needed() -> int:
	return maxi(1, 5 - level("shaker"))


## 选奶基后自动匹配糖度：智能糖台一级，或“风味”定位。
func auto_sugar_after_milk() -> bool:
	return level("smart_sugar") >= 1 or positioning() == "positioning_flavor"


## 选茶基后即匹配糖度：智能糖台二级（高级档）。
func auto_sugar_after_base() -> bool:
	return level("smart_sugar") >= 2


func tip_bonus() -> int:
	return level("tip_jar")


func perfect_bonus() -> int:
	return 1 if positioning() == "positioning_craft" else 0


## [P2-F2 2026-08-17] 定位按等价等级（各 1 级）计入评级分母/分子：14→16。
## 未购定位时分子不变、分母变大，评级对「买不买定位」保持中性而不是惩罚买方。
func total_levels() -> int:
	var total := 0
	for data in ITEMS:
		total += level(data["id"])
	if not positioning().is_empty():
		total += 1
	return total


func total_max_levels() -> int:
	var total := 0
	for data in ITEMS:
		total += data["costs"].size()
	return total + POSITIONINGS.size()


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
