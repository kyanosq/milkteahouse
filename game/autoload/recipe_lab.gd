## 配方判定与评分：从 prototype/recipe_lab.py 1:1 移植的纯逻辑单例
## cup 结构: { "base": Dict, "milk": Dict, "toppings": Array[Dict], "sugar": Dict }
extends Node

const DIMS := ["aroma", "sweet", "rich", "fresh", "chew"]
const SHELF_SCORE := 80   # 上架门槛（v0.3 评审定稿）
const DARK_SCORE := 40    # 黑暗菜单线


func main_dim(item: Dictionary) -> String:
	var best := DIMS[0]
	for d in DIMS:
		if int(item["flavor"][d]) > int(item["flavor"][best]):
			best = d
	return best


## 返回 { "flavor": Dict, "triggered": Array[规则] }
func compute_flavor(cup: Dictionary) -> Dictionary:
	var items: Array = [cup["base"], cup["milk"]] + cup["toppings"]
	var flavor := {}
	for d in DIMS:
		flavor[d] = 0
	for it in items:
		for d in DIMS:
			flavor[d] += int(it["flavor"][d])
		# 熟练度 Lv3+ 主维度 +1（§6.1）
		if GameState.level_of(it["id"]) >= 3:
			flavor[main_dim(it)] += 1
	flavor["sweet"] += int(cup["sugar"]["sweet_mod"])

	var triggered: Array = []
	for rule in GameData.affinities:
		var a: String = rule["tags"][0]
		var b: String = rule["tags"][1]
		var hit: bool
		if a == b:
			var count := 0
			for it in items:
				if a in it["tags"]:
					count += 1
			hit = count >= 2
		else:
			var has_a := false
			var has_b := false
			for it in items:
				if a in it["tags"]:
					has_a = true
				if b in it["tags"]:
					has_b = true
			hit = has_a and has_b
		if hit:
			triggered.append(rule)
			for d in rule.get("bonus", {}):
				flavor[d] += int(rule["bonus"][d])
	return {"flavor": flavor, "triggered": triggered}


## 返回 { "score": int, "worst_dim": String("" 表示均衡) }
func score_cup(flavor: Dictionary, triggered: Array) -> Dictionary:
	var score := 60
	var worst_dim := ""
	var worst_dev := 0
	for d in DIMS:
		var lo: int = int(GameData.balance_bands[d][0])
		var hi: int = int(GameData.balance_bands[d][1])
		var v: int = int(flavor[d])
		if lo <= v and v <= hi:
			score += 6
		else:
			var dev: int = (lo - v) if v < lo else (v - hi)
			score -= 5 * dev
			if dev > worst_dev:
				worst_dim = d
				worst_dev = dev
	for rule in triggered:
		score += int(rule["score"])
	return {"score": clampi(score, 0, 100), "worst_dim": worst_dim}


## 与配方表匹配。返回 { "hit": Dict|null, "near": String("" 无提示 / "sugar" / 槽位名) }
func match_recipe(cup: Dictionary, recipe_list: Array) -> Dictionary:
	var cup_top: Array = []
	for t in cup["toppings"]:
		cup_top.append(t["id"])
	cup_top.sort()
	var near := ""
	for r in recipe_list:
		var miss: Array = []
		if r["base"] != cup["base"]["id"]:
			miss.append("茶底")
		if r["milk"] != cup["milk"]["id"]:
			miss.append("奶基")
		var r_top: Array = r["toppings"].duplicate()
		r_top.sort()
		if r_top != cup_top:
			miss.append("小料")
		var sugar_ok: bool = int(r["sugar"][0]) <= int(cup["sugar"]["value"]) \
			and int(cup["sugar"]["value"]) <= int(r["sugar"][1])
		if miss.is_empty() and sugar_ok:
			return {"hit": r, "near": ""}
		if miss.is_empty() and not sugar_ok:
			near = "sugar"
		elif miss.size() == 1 and sugar_ok and near == "":
			near = miss[0]
	return {"hit": null, "near": near}
