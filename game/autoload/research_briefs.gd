## 短期研究单：把长期相性/熟练度成长拆成当晚可完成的一步，每日最多奖励一次。
extends Node

const REWARD := 2
const MASTERY_TRIALS := 2
## 成熟期（相性/熟练度池枯竭后）的品质挑战阶梯（DP#4）：完成当前档位后晋升，
## 让"每晚顺手一杯"随进度变成真实的配方功课题，而不是永远 75 分的白给。
const QUALITY_LADDER := [75, 82, 88]
const QUALITY_TARGET := 75 # 兼容旧存档/文档的最低档


func quality_target() -> int:
	return int(QUALITY_LADDER[clampi(GameState.brief_quality_step, 0, QUALITY_LADDER.size() - 1)])


func ensure_for_day(day_number: int = GameState.day) -> Dictionary:
	var current: Dictionary = GameState.research_brief
	if not current.is_empty():
		if not bool(current.get("completed", false)):
			return current
		if int(current.get("completed_day", 0)) >= day_number:
			return current
	GameState.research_brief = _generate(day_number)
	return GameState.research_brief


func record_trial(base_id: String, milk_id: String, used_ids: Array, quality: int) -> Dictionary:
	var brief := ensure_for_day()
	if brief.is_empty() or bool(brief.get("completed", false)):
		return {"completed": false, "reward": 0}
	match String(brief.get("type", "")):
		"pair":
			if base_id == String(brief.get("base", "")) and milk_id == String(brief.get("milk", "")):
				brief["progress"] = 1
		"mastery":
			if String(brief.get("ingredient", "")) in used_ids:
				brief["progress"] = mini(int(brief.get("target", MASTERY_TRIALS)), int(brief.get("progress", 0)) + 1)
		"balanced":
			if quality >= int(brief.get("quality", QUALITY_TARGET)):
				brief["progress"] = 1
	var completed_now := int(brief.get("progress", 0)) >= int(brief.get("target", 1))
	if completed_now:
		brief["completed"] = true
		brief["completed_day"] = GameState.day
		# 完成品质挑战即晋升下一档（封顶 88）：阶梯只升不降，失败的夜晚重试当前档。
		if String(brief.get("type", "")) == "balanced":
			GameState.brief_quality_step = mini(GameState.brief_quality_step + 1, QUALITY_LADDER.size() - 1)
	GameState.research_brief = brief
	return {"completed": completed_now, "reward": REWARD if completed_now else 0, "brief": brief}


func is_complete() -> bool:
	return not GameState.research_brief.is_empty() and bool(GameState.research_brief.get("completed", false))


func title() -> String:
	var brief := ensure_for_day()
	if brief.is_empty():
		return GameLocale.text("LAB_BRIEF_TITLE")
	return GameLocale.text("LAB_BRIEF_TITLE_COMPLETE" if bool(brief.get("completed", false)) else "LAB_BRIEF_TITLE_ACTIVE", [REWARD])


func description() -> String:
	var brief := ensure_for_day()
	if brief.is_empty():
		return GameLocale.text("LAB_BRIEF_NONE")
	if bool(brief.get("completed", false)):
		return GameLocale.text("LAB_BRIEF_COMPLETE")
	var objective := objective_text(brief)
	return GameLocale.text("LAB_BRIEF_PROGRESS", [objective, int(brief.get("progress", 0)), int(brief.get("target", 1))])


func objective_text(brief: Dictionary = GameState.research_brief) -> String:
	match String(brief.get("type", "")):
		"pair":
			return GameLocale.text("LAB_BRIEF_PAIR", [
				GameLocale.ingredient_short_name(RecipeJournal.ingredient(String(brief.get("base", "")))),
				GameLocale.ingredient_short_name(RecipeJournal.ingredient(String(brief.get("milk", "")))),
			])
		"mastery":
			return GameLocale.text("LAB_BRIEF_MASTERY", [
				GameLocale.ingredient_short_name(RecipeJournal.ingredient(String(brief.get("ingredient", "")))),
			])
		"balanced":
			return GameLocale.text("LAB_BRIEF_BALANCED", [int(brief.get("quality", QUALITY_TARGET))])
	return GameLocale.text("LAB_BRIEF_NONE")


func _generate(day_number: int) -> Dictionary:
	var unseen := _available_unseen_pairs(day_number)
	var practice := _practice_candidates(day_number)
	# 奇数日优先探索相性，偶数日优先练习原料；对应集合空时自动降级到另一类。
	if not unseen.is_empty() and (day_number % 2 == 1 or practice.is_empty()):
		var pair: Dictionary = unseen[posmod(day_number + ResearchProgress.seen_count(), unseen.size())]
		return {
			"type": "pair", "assigned_day": day_number,
			"base": String(pair["base"]), "milk": String(pair["milk"]),
			"progress": 0, "target": 1, "reward": REWARD,
			"completed": false, "completed_day": 0,
		}
	if not practice.is_empty():
		var ingredient_id := String(practice[0])
		return {
			"type": "mastery", "assigned_day": day_number, "ingredient": ingredient_id,
			"progress": 0, "target": MASTERY_TRIALS, "reward": REWARD,
			"completed": false, "completed_day": 0,
		}
	if not unseen.is_empty():
		var pair: Dictionary = unseen[posmod(day_number + ResearchProgress.seen_count(), unseen.size())]
		return {
			"type": "pair", "assigned_day": day_number,
			"base": String(pair["base"]), "milk": String(pair["milk"]),
			"progress": 0, "target": 1, "reward": REWARD,
			"completed": false, "completed_day": 0,
		}
	return {
		"type": "balanced", "assigned_day": day_number, "quality": quality_target(),
		"progress": 0, "target": 1, "reward": REWARD,
		"completed": false, "completed_day": 0,
	}


func _available_unseen_pairs(day_number: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for base in GameData.unlocked(GameData.bases, day_number):
		for milk in GameData.unlocked(GameData.milks, day_number):
			if not ResearchProgress.is_seen(String(base["id"]), String(milk["id"])):
				result.append({"base": String(base["id"]), "milk": String(milk["id"])})
	return result


func _practice_candidates(day_number: int) -> Array[String]:
	var result: Array[String] = []
	var unlocked: Array = GameData.unlocked(GameData.bases, day_number) \
		+ GameData.unlocked(GameData.milks, day_number) \
		+ GameData.unlocked(GameData.toppings, day_number)
	for ingredient in unlocked:
		var ingredient_id := String(ingredient.get("id", ""))
		if ingredient_id != "none" and ResearchProgress.level(ingredient_id) < 3:
			result.append(ingredient_id)
	result.sort_custom(func(a: String, b: String) -> bool:
		var xp_a := ResearchProgress.xp_value(a)
		var xp_b := ResearchProgress.xp_value(b)
		return xp_a > xp_b if xp_a != xp_b else a < b)
	return result
