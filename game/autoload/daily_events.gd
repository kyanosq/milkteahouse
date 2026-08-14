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

# 首轮事件按原料解锁顺序教学；从 Day 9 起，新店+店招重排同一组六事件。
# 每条路线每六天仍恰好出现一次所有事件，避免某条路线因奖励事件更多而占优。
const ROUTE_ROTATIONS := {
	"rush": ["group_day", "lunch_rush", "influencer_day", "critic_day", "light_drinks", "brown_sugar_trend"],
	"precision": ["critic_day", "light_drinks", "group_day", "brown_sugar_trend", "influencer_day", "lunch_rush"],
	"trend": ["influencer_day", "brown_sugar_trend", "light_drinks", "lunch_rush", "critic_day", "group_day"],
}


func event_for_day(day: int) -> Dictionary:
	if day <= 2:
		return _localized_event(CALM.duplicate(true))
	var slot := (day - 3) % ROTATION.size()
	if day >= 9 and LegacyRoutes.is_active():
		var schedule: Array = ROUTE_ROTATIONS.get(LegacyRoutes.active_id(), [])
		if schedule.size() == ROTATION.size():
			var routed := _event_by_id(String(schedule[slot]))
			if not routed.is_empty():
				return _localized_event(routed)
	return _localized_event(ROTATION[slot].duplicate(true))


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
		return {"coins": 8, "inspiration": 1, "reason": GameLocale.text("REWARD_CRITIC_REVIEW")}
	if kind == "influencer":
		return {"coins": 5, "inspiration": 0, "buzz": 3, "reason": GameLocale.text("REWARD_INFLUENCER_POST")}
	if kind == "group" and int(customer.get("group_index", 0)) >= int(customer.get("group_total", 1)) - 1:
		return {"coins": 10, "inspiration": 2, "buzz": 0, "reason": GameLocale.text("REWARD_GROUP_COMPLETE")}
	var menu_bonus := int(customer["order"].get("menu_event_bonus", 0))
	var event_coins := 0
	var reason := GameLocale.text("REWARD_MENU_EVENT_MATCH") if menu_bonus > 0 else ""
	match String(event.get("id", "calm")):
		"light_drinks":
			if customer["order"]["tops"].is_empty():
				event_coins = 2
				reason = GameLocale.text("REWARD_LIGHT_BONUS")
		"brown_sugar_trend":
			for topping in customer["order"]["tops"]:
				if topping["id"] == "brown_sugar":
					event_coins = 4
					reason = GameLocale.text("REWARD_TREND_BONUS")
					break
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
	return GameLocale.text("ORDER_HINT_DEFAULT")


func _localized_event(event: Dictionary) -> Dictionary:
	var prefix := "EVENT_%s_" % String(event.get("id", "calm")).to_upper()
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
