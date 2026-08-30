## 市场检验结算：同一天只生成一次，评分有波动但不可通过退出重进刷新。
extends Node

const STAGES := 3
const VARIANCE := 8
const FAILURE_REFUND := 3
## 三晚均分分档线：结算面板与判定共用，避免显示与规则漂移。
## [P5-3 2026-08-17] 失败线 62 → 76：deterministic_score 对同名三晚的偏移强相关
## （键共享长前缀，实测三晚偏移和的下界 ≈ -14 → 上架最低 80 分杯的可达最差均分
## 75.33），62 分线让「failed」退款分支正常游玩不可达。76 使最低品质的上架杯
## 仍有 ≈6% 落败风险，退款成为真实安全网；regular 档变为 [76, 78) 窄带。
const TIER_HIT := 88.0
const TIER_SIGNATURE := 78.0
const TIER_REGULAR := 76.0


func has_settlement(day_number: int = GameState.day) -> bool:
	return int(GameState.market_settlement.get("day", 0)) == day_number


func current() -> Dictionary:
	return GameState.market_settlement.duplicate(true)


func advance(day_number: int = GameState.day) -> Dictionary:
	if has_settlement(day_number):
		return current()
	var results: Array = []
	var done: Array = []
	var had_tests := not GameState.tests.is_empty()
	for value_test in GameState.tests:
		if not value_test is Dictionary:
			continue
		var test: Dictionary = value_test
		var scores: Array = test.get("scores", []) if test.get("scores", []) is Array else []
		var stage := mini(STAGES, scores.size() + 1)
		var score := deterministic_score(test, day_number, stage)
		var previous := int(scores[-1]) if not scores.is_empty() else score
		scores.append(score)
		test["scores"] = scores
		var average := _average(scores)
		var result := {
			"name": String(test.get("name", "")), "stage": stage, "score": score,
			"average": average, "trend": score - previous,
			"outcome": "testing", "price": 0, "refund": 0,
			# [P5-1 2026-08-17] 配方字段随行：结算卡据此复盘“这是哪杯饮品”
			# （_normalize_market_settlement 白名单同步保留）。
			"base": String(test.get("base", "")), "milk": String(test.get("milk", "")),
			"toppings": _string_array(test.get("toppings", [])),
			"sugar": clampi(int(test.get("sugar", 50)), 0, 100),
		}
		if scores.size() >= STAGES:
			if average >= TIER_HIT:
				result["outcome"] = "hit"
				result["price"] = int(MenuCatalog.PRICE_STANDARD["爆款"])
				MenuCatalog.register_custom(test, "爆款", int(result["price"]))
			elif average >= TIER_SIGNATURE:
				result["outcome"] = "signature"
				result["price"] = int(MenuCatalog.PRICE_STANDARD["招牌"])
				MenuCatalog.register_custom(test, "招牌", int(result["price"]))
			elif average >= TIER_REGULAR:
				result["outcome"] = "regular"
				result["price"] = int(MenuCatalog.PRICE_STANDARD["普通"])
				MenuCatalog.register_custom(test, "普通", int(result["price"]))
			else:
				result["outcome"] = "failed"
				result["refund"] = FAILURE_REFUND
				GameState.inspiration += FAILURE_REFUND
			done.append(test)
		results.append(result)
	for test in done:
		GameState.tests.erase(test)
	GameState.market_settlement = {
		"day": day_number, "had_tests": had_tests, "results": results,
	}
	return current()


func deterministic_score(test: Dictionary, day_number: int, stage: int) -> int:
	var key := "%s|%d|%d|%d" % [
		String(test.get("name", "")), int(test.get("quality", 0)), day_number, stage,
	]
	var accumulator: int = 17
	for index in key.length():
		accumulator = posmod(accumulator * 131 + key.unicode_at(index), 2147483629)
	var offset := posmod(accumulator, VARIANCE * 2 + 1) - VARIANCE
	return clampi(int(test.get("quality", 0)) + offset, 0, 100)


func _average(scores: Array) -> float:
	if scores.is_empty():
		return 0.0
	var total := 0.0
	for score in scores:
		total += float(score)
	return total / float(scores.size())


func _string_array(values: Variant) -> Array:
	var result: Array = []
	if values is Array:
		for value in values:
			result.append(String(value))
	return result
