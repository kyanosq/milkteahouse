## 夜间配方图鉴与研究目标：把试错变成有方向的收藏循环，但不直接泄露未知配方。
extends Node

signal target_changed(recipe_id: String)


func recipes(dark := false) -> Array:
	return GameData.dark_recipes if dark else GameData.recipes


func all_recipes() -> Array:
	return GameData.recipes + GameData.dark_recipes


func recipe(recipe_id: String) -> Dictionary:
	for item in all_recipes():
		if String(item.get("id", "")) == recipe_id:
			return item
	return {}


func is_dark(item: Dictionary) -> bool:
	return GameData.dark_recipes.has(item)


func is_discovered(item: Dictionary) -> bool:
	var discovered: Array = GameState.dark_discovered if is_dark(item) else GameState.discovered
	return String(item.get("id", "")) in discovered


func discovery_count(dark := false) -> int:
	return GameState.dark_discovered.size() if dark else GameState.discovered.size()


func unlock_day(item: Dictionary) -> int:
	var result := 1
	for ingredient_id in [String(item.get("base", "")), String(item.get("milk", ""))] + item.get("toppings", []):
		var ingredient := ingredient(ingredient_id)
		result = maxi(result, int(ingredient.get("unlock_day", 1)))
	return result


func is_available(item: Dictionary, day := -1) -> bool:
	var current_day := GameState.day if day < 0 else day
	return current_day >= unlock_day(item)


func clue(item: Dictionary, day := -1) -> String:
	var current_day := GameState.day if day < 0 else day
	var required_day := unlock_day(item)
	if current_day < required_day:
		return GameLocale.text("RECIPE_BOOK_LOCKED_DAY", [required_day])
	return GameLocale.recipe_hint(item)


func ingredient(ingredient_id: String) -> Dictionary:
	for item in GameData.bases + GameData.milks + GameData.toppings:
		if String(item.get("id", "")) == ingredient_id:
			return item
	return {}


func formula(item: Dictionary) -> String:
	var topping_names: Array[String] = []
	for topping_id in item.get("toppings", []):
		topping_names.append(GameLocale.ingredient_name(ingredient(String(topping_id))))
	var topping_text := GameLocale.text("NIGHT_NO_TOPPINGS") if topping_names.is_empty() \
		else GameLocale.text("LIST_SEPARATOR").join(topping_names)
	# 菜单项存 [低,高] 数组，市场检验结果存单一 int——中枢处归一。
	var sugar_value: Variant = item.get("sugar", [])
	if sugar_value is int or sugar_value is float:
		sugar_value = [int(sugar_value), int(sugar_value)]
	var sugar: Array = sugar_value if sugar_value is Array else []
	var sugar_text := ""
	if sugar.size() >= 2:
		var low := _sugar_name(int(sugar[0]))
		var high := _sugar_name(int(sugar[1]))
		sugar_text = low if low == high else GameLocale.text("RECIPE_BOOK_SUGAR_RANGE", [low, high])
	return GameLocale.text("RECIPE_BOOK_FORMULA", [
		GameLocale.ingredient_name(ingredient(String(item.get("base", "")))),
		GameLocale.ingredient_name(ingredient(String(item.get("milk", "")))),
		topping_text, sugar_text])


func set_target(recipe_id: String, persist := true) -> bool:
	var item := recipe(recipe_id)
	if item.is_empty() or not is_available(item):
		return false
	GameState.research_target = recipe_id
	if persist:
		GameState.save_game()
	target_changed.emit(recipe_id)
	return true


func clear_target(persist := true) -> void:
	if GameState.research_target.is_empty():
		return
	GameState.research_target = ""
	if persist:
		GameState.save_game()
	target_changed.emit("")


func target_recipe() -> Dictionary:
	return recipe(GameState.research_target)


func target_display_name() -> String:
	var item := target_recipe()
	if item.is_empty():
		return ""
	if is_discovered(item):
		return GameLocale.recipe_name(item)
	var collection := recipes(is_dark(item))
	var index := collection.find(item) + 1
	return GameLocale.text("RECIPE_BOOK_DARK_UNKNOWN" if is_dark(item) else "RECIPE_BOOK_UNKNOWN", [index])


func complete_if_target(recipe_id: String, persist := false) -> bool:
	if recipe_id.is_empty() or GameState.research_target != recipe_id:
		return false
	clear_target(persist)
	return true


func _sugar_name(value: int) -> String:
	for item in GameData.sugar_levels:
		if int(item.get("value", -1)) == value:
			return GameLocale.ingredient_name(item)
	return "%d%%" % value
