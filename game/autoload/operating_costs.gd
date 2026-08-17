## 日间经营账本：把真实原料消耗与可预告周租结算为净利润，同时用扶持上限避免负债死循环。
extends Node

const WHOLESALE_RATE := 0.5
const FIRST_RENT_DAY := 7
const RENT_INTERVAL := 7
const FIRST_RENT := 40
const RENT_STEP := 20
const MAX_RENT := 120
const RENT_BALANCE_CAP := 0.25


func cup_cost(ingredients: Array) -> int:
	var retail_cost := 0
	for ingredient in ingredients:
		if ingredient is Dictionary:
			retail_cost += maxi(0, int(ingredient.get("cost", 0)))
	if retail_cost <= 0:
		return 0
	return maxi(1, ceili(float(retail_cost) * WHOLESALE_RATE))


func rent_base(day_number: int) -> int:
	if day_number < FIRST_RENT_DAY or day_number % RENT_INTERVAL != 0:
		return 0
	var rent_cycle := maxi(0, (day_number - FIRST_RENT_DAY) / RENT_INTERVAL)
	return mini(MAX_RENT, FIRST_RENT + rent_cycle * RENT_STEP)


func next_rent_day(day_number: int) -> int:
	var safe_day := maxi(1, day_number)
	if safe_day <= FIRST_RENT_DAY:
		return FIRST_RENT_DAY
	var elapsed := safe_day - FIRST_RENT_DAY
	var cycles := ceili(float(elapsed) / float(RENT_INTERVAL))
	return FIRST_RENT_DAY + cycles * RENT_INTERVAL


func next_rent_base(day_number: int) -> int:
	return rent_base(next_rent_day(day_number))


## [P6-F3 2026-08-17] HUD 成本胶囊的租金预告：白天即可看到下一次租金的“天数+金额”。
## 接线点（day_shop.gd:2858-2859，主会话接一行）：
##   var rent := OperatingCosts.rent_preview()
##   hud_cost.text = ... GameLocale.text("DAY_HUD_COSTS_NEXT", [stock_cost, rent["day"], rent["amount"]])
## DAY_HUD_COSTS_NEXT 需在 ui.csv 增加第三个参数（“补货%d · 租金D%d·%d”）。
func rent_preview(day_number := -1) -> Dictionary:
	var target_day := GameState.day if day_number < 0 else maxi(1, day_number)
	var rent_day := next_rent_day(target_day)
	var due_today := rent_day == target_day and rent_base(target_day) > 0
	return {
		"day": rent_day,
		"amount": rent_base(rent_day),
		"due_today": due_today,
	}


## 工资应先由 StaffCatalog 结算；周租保护上限基于补货后仍可用的现金。
func settle(day_number: int, stock_due: int, waste_due: int) -> Dictionary:
	var safe_stock := maxi(0, stock_due)
	var safe_waste := mini(maxi(0, waste_due), safe_stock)
	var stock_paid := mini(GameState.coins, safe_stock)
	GameState.coins -= stock_paid
	var stock_relief := safe_stock - stock_paid

	var rent_due := rent_base(day_number)
	var protected_limit := maxi(0, floori(float(GameState.coins) * RENT_BALANCE_CAP))
	var rent_paid := mini(rent_due, protected_limit)
	GameState.coins -= rent_paid
	var rent_relief := rent_due - rent_paid
	return {
		"day": day_number,
		"stock_due": safe_stock,
		"stock_paid": stock_paid,
		"waste_due": safe_waste,
		"rent_due": rent_due,
		"rent_paid": rent_paid,
		"stock_relief": stock_relief,
		"rent_relief": rent_relief,
		"relief": stock_relief + rent_relief,
		"paid_total": stock_paid + rent_paid,
		"next_rent_day": next_rent_day(day_number + 1),
		"next_rent_base": next_rent_base(day_number + 1),
	}
