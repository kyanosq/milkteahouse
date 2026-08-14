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

var _names: Dictionary = {}


func _ready() -> void:
	var ing: Dictionary = _load_json("res://data/ingredients.json")
	bases = ing["bases"]
	milks = ing["milks"]
	toppings = ing["toppings"]
	sugar_levels = ing["sugar_levels"]
	affinities = ing["affinities"]
	balance_bands = ing["balance_bands"]
	recipes = _load_json("res://data/recipes.json")
	dark_recipes = _load_json("res://data/dark_recipes.json")
	traits_list = _load_json("res://data/traits.json")
	staff_list = _load_json("res://data/staff.json")
	for item in bases + milks + toppings:
		_names[item["id"]] = item["name"]


func _load_json(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	assert(data != null, "数据表解析失败: " + path)
	return data


## 按天数过滤已解锁原料
func unlocked(list: Array, day: int) -> Array:
	var out: Array = []
	for item in list:
		if int(item.get("unlock_day", 1)) <= day:
			out.append(item)
	return out


func name_of(id: String) -> String:
	for item in bases + milks + toppings:
		if String(item.get("id", "")) == id:
			return GameLocale.ingredient_name(item)
	return _names.get(id, id)


## 当日新解锁的原料名（结算演出用）
func newly_unlocked(day: int) -> Array:
	var out: Array = []
	for item in bases + milks + toppings:
		if int(item.get("unlock_day", 1)) == day:
			out.append(GameLocale.ingredient_name(item))
	return out
