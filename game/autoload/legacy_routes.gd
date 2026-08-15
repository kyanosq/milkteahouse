## 新店+店招路线：用明确的风险/回报改变真实白天循环，并记录三路线通关。
extends Node

const IDS := ["rush", "precision", "trend"]
const GOAL_MULTIPLIER := 1.08

const ROUTES := [
	{"id": "rush", "color": "FF6259"},
	{"id": "precision", "color": "8C67B5"},
	{"id": "trend", "color": "D99A43"},
]


func is_valid(route_id: String) -> bool:
	return route_id in IDS


func active_id() -> String:
	return GameState.new_shop_route if is_valid(GameState.new_shop_route) else ""


func is_active() -> bool:
	return not active_id().is_empty()


func route(route_id := "") -> Dictionary:
	var target := active_id() if route_id.is_empty() else route_id
	for source in ROUTES:
		if String(source["id"]) != target:
			continue
		var data: Dictionary = source.duplicate(true)
		var prefix := "LEGACY_ROUTE_%s_" % target.to_upper()
		data["name"] = GameLocale.text(prefix + "NAME")
		data["short_name"] = GameLocale.text(prefix + "SHORT")
		data["risk"] = GameLocale.text(prefix + "RISK")
		data["reward"] = GameLocale.text(prefix + "REWARD")
		data["summary"] = GameLocale.text(prefix + "SUMMARY")
		data["calendar"] = GameLocale.text(prefix + "CALENDAR")
		return data
	return {}


func routes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for route_id in IDS:
		result.append(route(route_id))
	return result


func goal_multiplier() -> float:
	return GOAL_MULTIPLIER if is_active() else 1.0


func spawn_multiplier() -> float:
	# 1.0（D3）：周转区提速到 ×0.85，与牺牲第三主推槽的可感知回报配套。
	return 0.85 if active_id() == "rush" else 1.0


func patience_multiplier() -> float:
	return 0.88 if active_id() == "precision" else 1.0


func menu_traffic_step() -> float:
	return 0.06 if active_id() == "trend" else 0.04


func sale_bonus(order: Dictionary, patience_ratio: float, streak := 0) -> int:
	match active_id():
		"rush":
			return 2 if streak > 0 and streak % 3 == 0 else 0
		"precision":
			return 1 if patience_ratio > 0.70 else 0
		"trend":
			return 3 if int(order.get("menu_event_bonus", 0)) > 0 else 0
	return 0


## 评论家接待奖励 ×1.25（D3-口碑：事件日高风险高回报的主编级待遇）。
func critic_bonus_multiplier() -> float:
	return 1.25 if active_id() == "precision" else 1.0


## 周转区封印第三主推槽（D3）：两槽换速度，牺牲可感知。
func featured_slot_limit() -> int:
	return 2 if active_id() == "rush" else 3


func progress_text(streak: int, trigger_count: int, earned_coins: int) -> String:
	match active_id():
		"rush":
			return GameLocale.text("DAY_ROUTE_PROGRESS_RUSH", [earned_coins, posmod(streak, 3)])
		"precision":
			return GameLocale.text("DAY_ROUTE_PROGRESS_PRECISION", [earned_coins, trigger_count])
		"trend":
			return GameLocale.text("DAY_ROUTE_PROGRESS_TREND", [earned_coins, trigger_count])
	return ""


func completed_count() -> int:
	var cleared: Array = GameState.legacy.get("routes_cleared", [])
	var count := 0
	for route_id in IDS:
		if route_id in cleared:
			count += 1
	return count
