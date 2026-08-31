## 静态数据表加载（唯一真相源：res://data/*.json，与存档严格分离）
extends Node

var bases: Array = []
var milks: Array = []
var toppings: Array = []
var sugar_levels: Array = []
var affinities: Array = []
var balance_bands: Dictionary = {}
var recipes: Array = []
var dark_recipes: Array = []
var traits_list: Array = []
var staff_list: Array = []

func _ready() -> void:
	var ing: Variant = _load_json("res://data/ingredients.json")
	# assert 在发布模板中会被剥离；主表损坏时给出明确错误并干净退出，
	# 而不是在 null 上崩溃。其余列表退回空数组保持启动存活。
	if not (ing is Dictionary):
		push_error("ingredients.json 缺失或损坏，游戏无法启动")
		get_tree().quit(1)
		return
	bases = ing["bases"]
	milks = ing["milks"]
	toppings = ing["toppings"]
	sugar_levels = ing["sugar_levels"]
	affinities = ing["affinities"]
	balance_bands = ing["balance_bands"]
	recipes = _json_array("res://data/recipes.json")
	dark_recipes = _json_array("res://data/dark_recipes.json")
	traits_list = _json_array("res://data/traits.json")
	staff_list = _json_array("res://data/staff.json")


func _load_json(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	return JSON.parse_string(text)


func _json_array(path: String) -> Array:
	var data: Variant = _load_json(path)
	if data is Array:
		return data
	push_error("数据表缺失或损坏: " + path)
	return []


## 按天数过滤已解锁原料
func unlocked(list: Array, day: int) -> Array:
	var out: Array = []
	for item in list:
		if int(item.get("unlock_day", 1)) <= day:
			out.append(item)
	return out


## 当日新解锁的原料名（结算演出用）
func newly_unlocked(day: int) -> Array:
	var out: Array = []
	for item in bases + milks + toppings:
		if int(item.get("unlock_day", 1)) == day:
			out.append(GameLocale.ingredient_name(item))
	return out
