## 每日经营事件：按天固定轮换，改变订单结构与风险/收益，而非隐藏随机惩罚。
extends Node

const CALM := {
	"id": "calm",
	"name": "平稳营业",
	"headline": "熟悉基础操作，按自己的节奏完成订单。",
	"challenge": "没有额外规则",
	"benefit": "适合建立连击与熟悉配方",
	"color": "27B9A7",
	"spawn_mult": 1.0,
	"patience_mult": 1.0,
}

const ROTATION := [
	{
		"id": "lunch_rush",
		"name": "午间热浪",
		"headline": "午休人潮一起涌进店里，队列会更快补满。",
		"challenge": "顾客到店间隔缩短 28%",
		"benefit": "更多订单，也有更多冲击三星的机会",
		"color": "FF6259",
		"spawn_mult": 0.72,
		"patience_mult": 1.08,
	},
	{
		"id": "light_drinks",
		"name": "轻饮风向",
		"headline": "今天流行低糖纯茶，熟悉的订单比例会发生变化。",
		"challenge": "纯茶、低糖与无小料订单明显增多",
		"benefit": "无小料订单正确出杯额外 +2 金币",
		"color": "55A889",
		"spawn_mult": 1.0,
		"patience_mult": 1.08,
	},
	{
		"id": "brown_sugar_trend",
		"name": "黑糖热搜",
		"headline": "黑糖冻突然刷屏，多数客人都指名要这一口。",
		"challenge": "多数订单会指定黑糖冻",
		"benefit": "含黑糖冻的正确出杯额外 +4 金币",
		"color": "D99A43",
		"spawn_mult": 0.94,
		"patience_mult": 1.0,
	},
	{
		"id": "critic_day",
		"name": "探店日",
		"headline": "匿名评论家混进队伍，认出并服务好他们。",
		"challenge": "评论家耐心 -22%，且会点两种小料",
		"benefit": "正确服务额外 +8 金币和 +1 灵感",
		"color": "8C67B5",
		"spawn_mult": 0.96,
		"patience_mult": 1.0,
	},
	{
		"id": "influencer_day",
		"name": "镜头来访",
		"headline": "探店网红要一杯上镜的猎奇特调，围观客人也在等结果。",
		"challenge": "网红偏爱猎奇小料，耐心 -10%",
		"benefit": "正确服务额外 +5 金币和 +3 话题度",
		"color": "F083A2",
		"spawn_mult": 0.98,
		"patience_mult": 1.0,
	},
	{
		"id": "group_day",
		"name": "结伴到店",
		"headline": "朋友们成群来喝奶茶，一张订单需要连续完成两杯。",
		"challenge": "团体订单占用队列更久，需要连续完成 2 杯",
		"benefit": "整单完成额外 +10 金币和 +2 灵感",
		"color": "3AAE9F",
		"spawn_mult": 0.92,
		"patience_mult": 1.12,
	},
]

# 首轮事件按原料解锁顺序教学；Day 9 起无路线的首战役借 trend 表重排（D4-B），
# 店招路线（New Shop+）从 Day 3 起即用各自的路线表（P2-F5），
# 第二遍统一叠加强度弯与修饰词（仍只从 Day 9 起）。
# 每条路线每六天仍恰好出现一次所有事件，避免某条路线因奖励事件更多而占优。
const ROUTE_ROTATIONS := {
	"rush": ["group_day", "lunch_rush", "influencer_day", "critic_day", "light_drinks", "brown_sugar_trend"],
	"precision": ["critic_day", "light_drinks", "group_day", "brown_sugar_trend", "influencer_day", "lunch_rush"],
	"trend": ["influencer_day", "brown_sugar_trend", "light_drinks", "lunch_rush", "critic_day", "group_day"],
}

## 二遍修饰词（D4）：Day9+ 每个事件的第二轮换一种玩法——数值等价带内改规则，
## 不做纯数值皮肤。参数由 day_shop/order_bonus 消费。
const SECOND_PASS := {
	"lunch_rush": {
		"per_order_bonus": 1, "spawn_mult": 0.90,
	},
	"light_drinks": {
		"notopping_bonus": 4,
	},
	"brown_sugar_trend": {
		"golden_window_mult": 0.75, "brown_bonus": 5,
	},
	"critic_day": {
		"editor_patience_mult": 0.65, "editor_reward_mult": 2.0,
	},
	"influencer_day": {
		"live_second_bonus": 7,
	},
	"group_day": {
		"triple_ticket": true, "group_refill": 0.40, "group_bonus": 18,
	},
}


func event_for_day(day: int) -> Dictionary:
	if day <= 2:
		return _localized_event(CALM.duplicate(true))
	var slot := (day - 3) % ROTATION.size()
	var base_event: Dictionary = {}
	# [P2-F5 2026-08-17] 路线激活即用路线日历（day>=3），不再等 Day9——
	# 否则 NG+ 首周与首战役第一周完全同序，「选路线」到第二周才生效。
	# 首周目（无路线）仍只在 Day9+ 借 trend 表重排（D4-B）。
	if day >= 9 or LegacyRoutes.is_active():
		var schedule: Array = ROUTE_ROTATIONS.get(LegacyRoutes.active_id(),
			ROUTE_ROTATIONS["trend"])
		if schedule.size() == ROTATION.size():
			base_event = _event_by_id(String(schedule[slot]))
	if base_event.is_empty():
		base_event = ROTATION[slot]
	var event: Dictionary = base_event.duplicate(true)
	if day >= 9:
		_apply_second_pass(event)
	return _localized_event(event)


## 二遍强度弯（D4-A）+ 修饰词合并（D4-修饰词）：换玩法不改总强度带。
func _apply_second_pass(event: Dictionary) -> void:
	event["spawn_mult"] = float(event.get("spawn_mult", 1.0)) * 0.94
	event["patience_mult"] = float(event.get("patience_mult", 1.0)) * 0.96
	var mod: Dictionary = SECOND_PASS.get(String(event.get("id", "")), {})
	if mod.is_empty():
		return
	event["second_pass"] = true
	var patch := mod.duplicate(true)
	# 修饰词倍率是“再”乘（规格：到店再 −10%），不能覆盖强度弯。
	for mult_key in ["spawn_mult", "patience_mult"]:
		if patch.has(mult_key):
			event[mult_key] = float(event.get(mult_key, 1.0)) * float(patch[mult_key])
			patch.erase(mult_key)
	event.merge(patch, true)


func next_event(day: int) -> Dictionary:
	return event_for_day(day + 1)


func customer_kind(event: Dictionary, spawn_number: int) -> String:
	match String(event.get("id", "")):
		"critic_day":
			return "critic" if (spawn_number - 1) % 4 == 0 else "regular"
		"influencer_day":
			return "influencer" if (spawn_number - 1) % 5 == 0 else "regular"
		"group_day":
			return "group" if (spawn_number - 1) % 6 == 0 else "regular"
	return "regular"


func is_special_customer(event: Dictionary, spawn_number: int) -> bool:
	return customer_kind(event, spawn_number) != "regular"


func modify_order(event: Dictionary, order: Dictionary, unlocked_toppings: Array,
		spawn_number: int, forced_kind := "") -> Dictionary:
	var changed := order.duplicate(true)
	var kind := forced_kind if forced_kind != "" else customer_kind(event, spawn_number)
	match String(event.get("id", "calm")):
		"light_drinks":
			if randf() < 0.72:
				changed["milk"] = GameData.milks[0]
			changed["sugar"] = [GameData.sugar_levels[0], GameData.sugar_levels[1]].pick_random()
			if randf() < 0.62:
				changed["tops"] = []
			elif changed["tops"].size() > 1:
				changed["tops"] = [changed["tops"][0]]
		"brown_sugar_trend":
			var brown_sugar := _find_item(unlocked_toppings, "brown_sugar")
			if not brown_sugar.is_empty() and randf() < 0.78:
				var tops: Array = changed["tops"].duplicate()
				var already_added := false
				for topping in tops:
					if topping["id"] == "brown_sugar":
						already_added = true
				if not already_added:
					if tops.size() >= 2:
						tops[tops.size() - 1] = brown_sugar
					else:
						tops.append(brown_sugar)
				changed["tops"] = tops
		"critic_day":
			if kind == "critic":
				var pool := unlocked_toppings.duplicate()
				pool.shuffle()
				changed["tops"] = pool.slice(0, mini(2, pool.size()))
		"influencer_day":
			if kind == "influencer":
				var viral_pool: Array = []
				for topping in unlocked_toppings:
					if topping["id"] in ["xiangcai", "zheergen"]:
						viral_pool.append(topping)
				if viral_pool.is_empty():
					var fallback := _find_item(unlocked_toppings, "brown_sugar")
					if not fallback.is_empty():
						viral_pool.append(fallback)
				if not viral_pool.is_empty():
					changed["tops"] = [viral_pool.pick_random()]
		"group_day":
			if kind == "group" and not unlocked_toppings.is_empty():
				changed["tops"] = [unlocked_toppings.pick_random()]
	return changed


func order_bonus(event: Dictionary, customer: Dictionary) -> Dictionary:
	var kind := String(customer.get("kind", "regular"))
	if kind == "critic":
		# 主编亲临（二遍修饰词）：首位评论家奖励 ×2，其余评论家不变。
		if bool(customer.get("editor", false)):
			var mult := float(event.get("editor_reward_mult", 2.0))
			return {"coins": int(8.0 * mult), "inspiration": int(1.0 * mult),
				"buzz": 0, "reason": GameLocale.text("REWARD_EDITOR_REVIEW")}
		return {"coins": 8, "inspiration": 1, "buzz": 0, "reason": GameLocale.text("REWARD_CRITIC_REVIEW")}
	if kind == "influencer":
		if bool(customer.get("live_second", false)):
			return {"coins": 5 + int(event.get("live_second_bonus", 7)), "inspiration": 0,
				"buzz": 3, "reason": GameLocale.text("REWARD_LIVE_SECOND")}
		return {"coins": 5, "inspiration": 0, "buzz": 3, "reason": GameLocale.text("REWARD_INFLUENCER_POST")}
	if kind == "group" and int(customer.get("group_index", 0)) >= int(customer.get("group_total", 1)) - 1:
		return {"coins": int(event.get("group_bonus", 10)), "inspiration": 2, "buzz": 0,
			"reason": GameLocale.text("REWARD_GROUP_COMPLETE")}
	var menu_bonus := int(customer["order"].get("menu_event_bonus", 0))
	var event_coins := int(event.get("per_order_bonus", 0))
	var reason := GameLocale.text("REWARD_MENU_EVENT_MATCH") if menu_bonus > 0 else ""
	match String(event.get("id", "calm")):
		"light_drinks":
			if customer["order"]["tops"].is_empty():
				event_coins += int(event.get("notopping_bonus", 2))
				reason = GameLocale.text("REWARD_LIGHT_BONUS")
		"brown_sugar_trend":
			for topping in customer["order"]["tops"]:
				if topping["id"] == "brown_sugar":
					event_coins += int(event.get("brown_bonus", 4))
					reason = GameLocale.text("REWARD_TREND_BONUS")
					break
	if event_coins > 0 and reason.is_empty() and int(event.get("per_order_bonus", 0)) > 0:
		reason = GameLocale.text("REWARD_DELIVERY_BONUS")
	return {"coins": event_coins + menu_bonus, "inspiration": 0, "buzz": 0, "reason": reason}


func order_hint(event: Dictionary, customer: Dictionary) -> String:
	var kind := String(customer.get("kind", "regular"))
	if kind == "critic":
		return GameLocale.text("ORDER_HINT_CRITIC")
	if kind == "influencer":
		return GameLocale.text("ORDER_HINT_INFLUENCER")
	if kind == "group":
		return GameLocale.text("ORDER_HINT_GROUP", [
			int(customer.get("group_index", 0)) + 1, int(customer.get("group_total", 2))])
	match String(event.get("id", "calm")):
		"light_drinks":
			if customer["order"]["tops"].is_empty():
				return GameLocale.text("ORDER_HINT_LIGHT")
		"brown_sugar_trend":
			for topping in customer["order"]["tops"]:
				if topping["id"] == "brown_sugar":
					return GameLocale.text("ORDER_HINT_TREND")
	# 手柄模式下“点按”措辞不成立：聚焦即设为当前订单（P3 试玩）。
	return GameLocale.text("ORDER_HINT_DEFAULT_GAMEPAD") if InputPrompts.gamepad_mode \
		else GameLocale.text("ORDER_HINT_DEFAULT")


func _localized_event(event: Dictionary) -> Dictionary:
	var prefix := "EVENT_%s_" % String(event.get("id", "calm")).to_upper()
	if bool(event.get("second_pass", false)):
		prefix += "SP_"
		# 修饰词变体沿用事件色相，仅换文案与规则参数。
	event["name"] = GameLocale.text(prefix + "NAME")
	event["hud_name"] = GameLocale.text(prefix + "HUD")
	event["headline"] = GameLocale.text(prefix + "HEADLINE")
	event["challenge"] = GameLocale.text(prefix + "CHALLENGE")
	event["benefit"] = GameLocale.text(prefix + "BENEFIT")
	return event


func _event_by_id(event_id: String) -> Dictionary:
	for event in ROTATION:
		if String(event.get("id", "")) == event_id:
			return event.duplicate(true)
	return {}


func _find_item(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if item["id"] == item_id:
			return item
	return {}
