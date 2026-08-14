## 可见研发成长层：茶底×奶基相性发现与原料熟练度进度。
extends Node

signal pair_discovered(pair_key: String)

const NIGHT_MASTERY_BONUS := 2
const XP_PER_LEVEL := 8
const MAX_LEVEL := 5


func pair_key(base_id: String, milk_id: String) -> String:
	return "%s|%s" % [base_id, milk_id]


func all_pair_keys() -> Array[String]:
	var result: Array[String] = []
	for base in GameData.bases:
		for milk in GameData.milks:
			result.append(pair_key(String(base["id"]), String(milk["id"])))
	return result


func seen_count() -> int:
	var count := 0
	for key in all_pair_keys():
		if key in GameState.affinity_seen:
			count += 1
	return count


func total_count() -> int:
	return GameData.bases.size() * GameData.milks.size()


func is_seen(base_id: String, milk_id: String) -> bool:
	return pair_key(base_id, milk_id) in GameState.affinity_seen


func is_complete() -> bool:
	return total_count() > 0 and seen_count() >= total_count()


func night_budget_bonus() -> int:
	return NIGHT_MASTERY_BONUS if is_complete() else 0


## 返回 new / complete / rating；重复试作不会重复触发完成奖励。
func record_pair(base_id: String, milk_id: String) -> Dictionary:
	var key := pair_key(base_id, milk_id)
	if key not in all_pair_keys():
		return {"new": false, "complete": false, "rating": {}}
	var newly_seen := key not in GameState.affinity_seen
	if newly_seen:
		GameState.affinity_seen.append(key)
		pair_discovered.emit(key)
	return {
		"new": newly_seen,
		"complete": newly_seen and is_complete(),
		"rating": pairing(base_id, milk_id),
	}


func pairing(base_id: String, milk_id: String) -> Dictionary:
	var base := RecipeJournal.ingredient(base_id)
	var milk := RecipeJournal.ingredient(milk_id)
	if base.is_empty() or milk.is_empty():
		return {}
	var items := [base, milk]
	var synergy := 0
	var clash := 0
	var notes: Array[String] = []
	for rule in GameData.affinities:
		if _rule_hits(rule, items):
			var score := int(rule.get("score", 0))
			if score > 0:
				synergy += score
			elif score < 0:
				clash += absi(score)
			notes.append(GameLocale.affinity_note(rule))
	var rank := "neutral"
	if clash > 0 and clash >= synergy:
		rank = "clash"
	elif synergy >= 6:
		rank = "perfect"
	elif synergy > 0:
		rank = "good"
	return {
		"key": pair_key(base_id, milk_id), "base": base, "milk": milk,
		"rank": rank, "score": synergy - clash, "synergy": synergy, "clash": clash,
		"notes": notes,
	}


func rank_name(rank: String) -> String:
	return GameLocale.text("RESEARCH_RANK_%s" % rank.to_upper())


func rank_color(rank: String) -> Color:
	match rank:
		"perfect":
			return Color("FF6259")
		"good":
			return Color("27B9A7")
		"clash":
			return Color("8C67B5")
		_:
			return Color("D99A43")


func pairing_note(result: Dictionary) -> String:
	var notes: Array = result.get("notes", [])
	return GameLocale.text("RESEARCH_PAIR_NEUTRAL_NOTE") if notes.is_empty() \
		else GameLocale.text("LIST_SEPARATOR").join(notes)


func ingredients() -> Array:
	var result: Array = []
	for item in GameData.bases + GameData.milks + GameData.toppings:
		if String(item.get("id", "")) != "none":
			result.append(item)
	return result


func xp_value(ingredient_id: String) -> int:
	return maxi(0, int(GameState.xp.get(ingredient_id, 0)))


func level(ingredient_id: String) -> int:
	return GameState.level_of(ingredient_id)


func level_progress(ingredient_id: String) -> Dictionary:
	var current_level := level(ingredient_id)
	var value := xp_value(ingredient_id)
	if current_level >= MAX_LEVEL:
		return {"level": MAX_LEVEL, "value": XP_PER_LEVEL, "max": XP_PER_LEVEL, "remaining": 0}
	var within := value % XP_PER_LEVEL
	return {
		"level": current_level, "value": within, "max": XP_PER_LEVEL,
		"remaining": XP_PER_LEVEL - within,
	}


func level_effect(ingredient_id: String) -> String:
	var current_level := level(ingredient_id)
	if current_level >= 3:
		return GameLocale.text("RESEARCH_MASTERY_EFFECT_ACTIVE")
	return GameLocale.text("RESEARCH_MASTERY_EFFECT_LOCKED", [3])


func mastered_ingredients() -> int:
	var count := 0
	for item in ingredients():
		if level(String(item["id"])) >= 3:
			count += 1
	return count


func _rule_hits(rule: Dictionary, items: Array) -> bool:
	var tags: Array = rule.get("tags", [])
	if tags.size() < 2:
		return false
	var a := String(tags[0])
	var b := String(tags[1])
	if a == b:
		var count := 0
		for item in items:
			if a in item.get("tags", []):
				count += 1
		return count >= 2
	var has_a := false
	var has_b := false
	for item in items:
		if a in item.get("tags", []):
			has_a = true
		if b in item.get("tags", []):
			has_b = true
	return has_a and has_b
