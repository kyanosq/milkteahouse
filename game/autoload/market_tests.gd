## 市场检验结算：同一天只生成一次，评分有波动但不可通过退出重进刷新。
extends Node

const STAGES := 3
const VARIANCE := 8


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
		}
		if scores.size() >= STAGES:
			if average >= 88.0:
				result["outcome"] = "hit"
				result["price"] = 18
				MenuCatalog.register_custom(test, "爆款", 18)
			elif average >= 78.0:
				result["outcome"] = "signature"
				result["price"] = 15
				MenuCatalog.register_custom(test, "招牌", 15)
			elif average >= 62.0:
				result["outcome"] = "regular"
				result["price"] = 12
				MenuCatalog.register_custom(test, "普通", 12)
			else:
				result["outcome"] = "failed"
				result["refund"] = 3
				GameState.inspiration += 3
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
