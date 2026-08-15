## Day 15 后的商圈经营委托：把富余金币换成可读的主动挑战与长期店招进度。
extends Node

const UNLOCK_NIGHT := 15
const FIRST_TARGET_DAY := 16
const MAX_COST_STEP := 6

const ITEMS := [
	{
		"id": "streak_stage",
		"name": "黄金连击擂台",
		"short_name": "连击擂台",
		"color": "FF6259",
		"base_cost": 120,
		"refund_ratio": 0.35,
		"inspiration": 2,
		"description": "商圈直播全程盯场。客流与耐心都会收紧，靠稳定连击拿下店招印章。",
		"challenge": "最高连击达到指定次数",
		"spawn_mult": 0.92,
		"patience_mult": 0.94,
	},
	{
		"id": "precision_shift",
		"name": "零差评品鉴场",
		"short_name": "零差评",
		"color": "27B9A7",
		"base_cost": 150,
		"refund_ratio": 0.34,
		"inspiration": 2,
		"description": "社区评审集中到店。必须保持零气走并完成足够多的完美出杯。",
		"challenge": "零气走并完成指定完美杯数",
		"spawn_mult": 0.96,
		"patience_mult": 0.88,
	},
	{
		"id": "revenue_sprint",
		"name": "商圈营收冲刺",
		"short_name": "营收冲刺",
		"color": "D99A43",
		"base_cost": 190,
		"refund_ratio": 0.36,
		"inspiration": 3,
		"description": "联名推广带来密集客流。订单更多，但只有达到签约营收才算履约。",
		"challenge": "营业营收达到签约目标",
		"spawn_mult": 0.82,
		"patience_mult": 1.04,
	},
]


func item(contract_id: String) -> Dictionary:
	for data in ITEMS:
		if String(data["id"]) == contract_id:
			return data
	return {}


func is_unlocked(night_day: int = GameState.day) -> bool:
	return night_day >= UNLOCK_NIGHT


func available_for_day(target_day: int) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	if target_day < FIRST_TARGET_DAY:
		return offers
	for source in ITEMS:
		var offer: Dictionary = _localized_contract(source)
		offer["target_day"] = target_day
		offer["cost"] = cost_for(source, target_day)
		offer["refund"] = roundi(float(offer["cost"]) * float(source["refund_ratio"]))
		offer["target"] = target_for(String(source["id"]), target_day)
		offer["target_text"] = target_text(offer)
		offers.append(offer)
	return offers


func cost_for(data: Dictionary, target_day: int) -> int:
	# 1.0（D1①）：签约费随天数无上限复利爬升——day16 锚点不变（×1.0），
	# 之后每天 +15%，让“点确认”重新变回真实决策；退款比例沿用。
	var growth := 1.0 + 0.15 * float(maxi(0, target_day - FIRST_TARGET_DAY))
	return roundi(float(data["base_cost"]) * growth)


func target_for(contract_id: String, target_day: int) -> int:
	# 现有曲线在 day 40 饱和于 30；day 46 起每 6 天 +1，上限 40（审计 DP#2）。
	var elapsed := maxi(0, target_day - FIRST_TARGET_DAY)
	var base_target := 0
	match contract_id:
		"streak_stage":
			base_target = 28 + mini(2, elapsed / 12) + clampi((elapsed - 24) / 6, 0, 10)
		"precision_shift":
			base_target = 28 + mini(2, elapsed / 12) + clampi((elapsed - 24) / 6, 0, 10)
		"revenue_sprint":
			base_target = ceili(float(adaptive_goal_for_day(target_day)) * LegacyRoutes.goal_multiplier() * 1.35)
	# 不朽章节（D6B）：20 章后每个印章使要求 ×1.05——传奇之后仍有爬升。
	var stamps := int(GameState.endless.get("stamps", 0))
	if stamps > 20:
		base_target = roundi(float(base_target) * pow(1.05, float(mini(stamps, 30) - 20)))
	return base_target


func goal_for_day(day_number: int) -> int:
	# Day 17 后封顶 380 防止无尽必然 0 星；1.0 起不再线性爬 420——
	# Day31+ 的压力由自适应目标（D1③）接管。
	return mini(380, 80 + 18 * day_number)


## 自适应星目标（D1③）：T = clamp( max(base, 0.85×MA5(revenue)),
## 0.94×T(d-1), 1.06×T(d-1) )。双向 ±6% 限速：变强目标缓涨、变弱缓降，
## 恒定收入 I 下不动点 0.85I < I，目标永远可达；无历史时退回 base。
func adaptive_goal_for_day(day_number: int) -> int:
	var base := goal_for_day(day_number)
	if day_number < 16:
		return base
	var history: Array = GameState.endless.get("revenue_history", [])
	var previous := int(GameState.endless.get("goal_state", 0))
	if history.is_empty() or previous <= 0:
		return base
	var total := 0
	for entry in history:
		total += int(entry)
	var moving_average := float(total) / float(history.size())
	var target := maxi(base, int(0.85 * moving_average))
	return clampi(target, ceili(float(previous) * 0.94), ceili(float(previous) * 1.06))


## 每个无尽日结算后记录营收与当日目标，驱动下一日的自适应目标。
func record_day_performance(earned: int, goal_used: int) -> void:
	var history: Array = (GameState.endless.get("revenue_history", []) as Array).duplicate()
	history.append(maxi(0, earned))
	GameState.endless["revenue_history"] = history.slice(maxi(0, history.size() - 5))
	GameState.endless["goal_state"] = maxi(0, goal_used)


func target_text(contract: Dictionary) -> String:
	match String(contract.get("id", "")):
		"streak_stage":
			return GameLocale.text("CONTRACT_TARGET_STREAK", [int(contract.get("target", 28))])
		"precision_shift":
			return GameLocale.text("CONTRACT_TARGET_PRECISION", [int(contract.get("target", 28))])
		"revenue_sprint":
			return GameLocale.text("CONTRACT_TARGET_REVENUE", [int(contract.get("target", 500))])
	return GameLocale.text("CONTRACT_TARGET_DEFAULT")


func sign_contract(contract_id: String, target_day: int, persist := true) -> bool:
	if target_day < FIRST_TARGET_DAY or not active_contract().is_empty():
		return false
	var chosen: Dictionary = {}
	for offer in available_for_day(target_day):
		if String(offer["id"]) == contract_id:
			chosen = offer
			break
	if chosen.is_empty() or GameState.coins < int(chosen["cost"]):
		return false
	GameState.coins -= int(chosen["cost"])
	GameState.endless["active"] = chosen
	GameState.endless["last_result"] = {}
	if persist:
		GameState.save_game()
	return true


func active_contract() -> Dictionary:
	var active: Variant = GameState.endless.get("active", {})
	return _localized_contract(active) if active is Dictionary and not active.is_empty() else {}


func active_for_day(day_number: int) -> Dictionary:
	var active := active_contract()
	if int(active.get("target_day", -1)) != day_number:
		return {}
	return active


func apply_to_event(event: Dictionary, day_number: int) -> Dictionary:
	var result := event.duplicate(true)
	var active := active_for_day(day_number)
	if active.is_empty():
		return result
	result["spawn_mult"] = float(result.get("spawn_mult", 1.0)) * float(active.get("spawn_mult", 1.0))
	result["patience_mult"] = float(result.get("patience_mult", 1.0)) * float(active.get("patience_mult", 1.0))
	return result


func progress_text(contract: Dictionary, stats: Dictionary) -> String:
	match String(contract.get("id", "")):
		"streak_stage":
			return GameLocale.text("CONTRACT_PROGRESS_STREAK", [mini(int(stats.get("best_streak", 0)), int(contract["target"])), int(contract["target"])])
		"precision_shift":
			return GameLocale.text("CONTRACT_PROGRESS_PRECISION", [mini(int(stats.get("perfect", 0)), int(contract["target"])), int(contract["target"]), int(stats.get("angry", 0))])
		"revenue_sprint":
			return GameLocale.text("CONTRACT_PROGRESS_REVENUE", [mini(int(stats.get("earned", 0)), int(contract["target"])), int(contract["target"])])
	return GameLocale.text("CONTRACT_PROGRESS_DEFAULT")


func requirement_met(contract: Dictionary, stats: Dictionary) -> bool:
	match String(contract.get("id", "")):
		"streak_stage":
			return int(stats.get("best_streak", 0)) >= int(contract.get("target", 28))
		"precision_shift":
			return int(stats.get("angry", 0)) == 0 and int(stats.get("perfect", 0)) >= int(contract.get("target", 28))
		"revenue_sprint":
			return int(stats.get("earned", 0)) >= int(contract.get("target", 500))
	return false


func resolve(day_number: int, stats: Dictionary, persist := false) -> Dictionary:
	var contract := active_for_day(day_number)
	if contract.is_empty():
		return {}
	var success := requirement_met(contract, stats)
	var result := {
		"day": day_number,
		"id": String(contract["id"]),
		"name": String(contract["name"]),
		"success": success,
		"cost": int(contract["cost"]),
		"refund": int(contract["refund"]) if success else 0,
		"inspiration": int(contract["inspiration"]) if success else 0,
		"target_text": String(contract["target_text"]),
	}
	if success:
		GameState.coins += int(result["refund"])
		GameState.inspiration += int(result["inspiration"])
		GameState.endless["stamps"] = int(GameState.endless.get("stamps", 0)) + 1
		GameState.endless["completed"] = int(GameState.endless.get("completed", 0)) + 1
		GameState.endless["streak"] = int(GameState.endless.get("streak", 0)) + 1
		GameState.endless["best_streak"] = maxi(int(GameState.endless.get("best_streak", 0)), int(GameState.endless["streak"]))
	else:
		GameState.endless["failed"] = int(GameState.endless.get("failed", 0)) + 1
		GameState.endless["streak"] = 0
	GameState.endless["active"] = {}
	GameState.endless["last_result"] = result
	if persist:
		GameState.save_game()
	return result


func rank_name(stamps: int = int(GameState.endless.get("stamps", 0))) -> String:
	if stamps >= 30:
		return GameLocale.text("CONTRACT_RANK_IMMORTAL")
	if stamps >= 20:
		return GameLocale.text("CONTRACT_RANK_LEGEND")
	if stamps >= 15:
		return GameLocale.text("CONTRACT_RANK_CITY_PLUS")
	if stamps >= 12:
		return GameLocale.text("CONTRACT_RANK_GOLD")
	if stamps >= 7:
		return GameLocale.text("CONTRACT_RANK_CITY")
	if stamps >= 3:
		return GameLocale.text("CONTRACT_RANK_DISTRICT")
	return GameLocale.text("CONTRACT_RANK_BLOCK")


func next_rank_text(stamps: int = int(GameState.endless.get("stamps", 0))) -> String:
	if stamps >= 30:
		return GameLocale.text("CONTRACT_RANK_DEFEND")
	var next := 3 if stamps < 3 else (7 if stamps < 7 else (12 if stamps < 12 else (15 if stamps < 15 else 20)))
	return GameLocale.text("CONTRACT_RANK_NEXT", [next - stamps])


func _localized_contract(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	var prefix := "CONTRACT_%s_" % String(source.get("id", "")).to_upper()
	result["name"] = GameLocale.text(prefix + "NAME")
	result["short_name"] = GameLocale.text(prefix + "SHORT")
	result["description"] = GameLocale.text(prefix + "DESCRIPTION")
	result["challenge"] = GameLocale.text(prefix + "CHALLENGE")
	if result.has("target"):
		result["target_text"] = target_text(result)
	return result
