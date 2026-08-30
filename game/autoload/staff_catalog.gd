## 员工候选、招聘成本与有限特质钩子。特质效果数值由 traits.json 驱动。
extends Node

const UNLOCK_DAY := 8
const HIRE_COST := 45
const DISMISS_COST := 20


func candidates() -> Array:
	return GameData.staff_list


func candidate(candidate_id: String) -> Dictionary:
	for item in GameData.staff_list:
		if String(item.get("id", "")) == candidate_id:
			return item
	return {}


func trait_data(trait_id: String) -> Dictionary:
	for item in GameData.traits_list:
		if String(item.get("id", "")) == trait_id:
			return item
	return {}


func current() -> Dictionary:
	return GameState.staff


func has_staff() -> bool:
	return not GameState.staff.is_empty()


func rests_on(day_number: int) -> bool:
	return has_staff() and int(GameState.staff.get("rest_day", 0)) == day_number


func is_on_duty(day_number := -1) -> bool:
	var target_day := GameState.day if day_number < 0 else day_number
	return has_staff() and not rests_on(target_day)


func wage_shortfall() -> int:
	return maxi(0, int(GameState.staff.get("wage_shortfall", 0)))


func trait_id() -> String:
	return String(GameState.staff.get("trait_id", ""))


func hire(candidate_id: String, persist := true) -> bool:
	if GameState.day < UNLOCK_DAY or has_staff() or GameState.coins < HIRE_COST:
		return false
	var data := candidate(candidate_id)
	if data.is_empty():
		return false
	GameState.coins -= HIRE_COST
	GameState.staff = data.duplicate(true)
	GameState.staff["trait_revealed"] = false
	GameState.staff["days_worked"] = 0
	GameState.staff["rest_day"] = 0
	GameState.staff["wage_shortfall"] = 0
	GameState.staff["wage_shortfalls"] = 0
	if persist:
		GameState.save_game()
	return true


func dismiss(persist := true) -> bool:
	if not has_staff() or GameState.coins < DISMISS_COST:
		return false
	GameState.coins -= DISMISS_COST
	GameState.staff = {}
	if persist:
		GameState.save_game()
	return true


func reveal_trait(persist := true) -> void:
	if not has_staff() or bool(GameState.staff.get("trait_revealed", false)):
		return
	GameState.staff["trait_revealed"] = true
	if persist:
		GameState.save_game()


func trait_revealed() -> bool:
	return bool(GameState.staff.get("trait_revealed", false))


func trait_name() -> String:
	var data := trait_data(trait_id())
	var key := "TRAIT_%s_NAME" % trait_id().to_upper()
	var fallback := String(data.get("name", GameLocale.text("TRAIT_UNKNOWN_NAME")))
	var translated := GameLocale.text(key)
	return fallback if translated == key else translated


func wage() -> int:
	return maxi(0, int(GameState.staff.get("wage", 0)))


func trait_effect(key: String, fallback: Variant) -> Variant:
	var effects: Dictionary = trait_data(trait_id()).get("effects", {})
	return effects.get(key, fallback)


func _active_effect(key: String, fallback: Variant) -> Variant:
	if not is_on_duty():
		return fallback
	return trait_effect(key, fallback)


func patience_multiplier() -> float:
	return float(_active_effect("patience_mult", 1.0))


func spawn_multiplier() -> float:
	return float(_active_effect("spawn_mult", 1.0))


func waiting_drain_multiplier(working := true) -> float:
	return float(_active_effect("waiting_drain_mult", 1.0)) if working else 1.0


func extra_shakes() -> int:
	return int(_active_effect("extra_shakes", 0))


func quality_coin_bonus() -> int:
	return int(_active_effect("quality_coin_bonus", 0))


func has_wrong_cup_guard() -> bool:
	return bool(_active_effect("wrong_cup_guard", false))


func effect_summary(revealed := true) -> String:
	if not revealed:
		return GameLocale.text("STAFF_TRAIT_HIDDEN_SUMMARY")
	match trait_id():
		"slacker":
			return GameLocale.text("TRAIT_SLACKER_EFFECT", [
				roundi((1.0 - float(trait_effect("waiting_drain_mult", 1.0))) * 100.0)])
		"social_king":
			return GameLocale.text("TRAIT_SOCIAL_KING_EFFECT", [
				roundi((float(trait_effect("patience_mult", 1.0)) - 1.0) * 100.0),
				roundi((1.0 - float(trait_effect("spawn_mult", 1.0))) * 100.0)])
		"perfectionist":
			return GameLocale.text("TRAIT_PERFECTIONIST_EFFECT", [
				int(trait_effect("quality_coin_bonus", 0)),
				1 if bool(trait_effect("wrong_cup_guard", false)) else 0,
				int(trait_effect("extra_shakes", 0))])
	return GameLocale.text("STAFF_TRAIT_UNKNOWN_EFFECT")


func charge_daily_wage(day_number := -1) -> Dictionary:
	var target_day := GameState.day if day_number < 0 else day_number
	var result := {
		"status": "none", "worked": false, "due": 0, "paid": 0,
		"shortfall": 0, "rest_day": 0,
	}
	if not has_staff():
		return result
	if not is_on_duty(target_day):
		result["status"] = "rest"
		result["rest_day"] = target_day
		return result
	var due := wage()
	var paid := mini(GameState.coins, due)
	var shortfall := due - paid
	GameState.coins -= paid
	GameState.staff["days_worked"] = int(GameState.staff.get("days_worked", 0)) + 1
	result.merge({"status": "paid", "worked": true, "due": due, "paid": paid, "shortfall": shortfall}, true)
	if shortfall > 0:
		var next_day := target_day + 1
		GameState.staff["rest_day"] = next_day
		GameState.staff["wage_shortfall"] = shortfall
		GameState.staff["wage_shortfalls"] = int(GameState.staff.get("wage_shortfalls", 0)) + 1
		result["status"] = "shortfall"
		result["rest_day"] = next_day
	elif int(GameState.staff.get("rest_day", 0)) < target_day:
		GameState.staff["rest_day"] = 0
		GameState.staff["wage_shortfall"] = 0
	return result
