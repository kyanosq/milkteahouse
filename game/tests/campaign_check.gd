## 14 天战役结局、评级幂等、无限经营与新周目继承回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.research_brief = {}
	GameState.market_settlement = {}
	GameState.settings = {"sound_volume": 0.0, "reduced_motion": true}
	GameState.legacy = {"campaigns_completed": 0, "best_grade": "-", "best_score": 0}
	GameState.day = 9
	assert(int(GameState._normalize_campaign_stats({})["tracking_start_day"]) == 9)
	GameState.reset_progress()
	assert(GameState.build_campaign_summary()["grade"] == "C")
	GameState.perfect_total = 110
	GameState.coins = 520
	GameState.buzz = 0
	GameState.upgrades = {"comfort": 3, "shaker": 2, "smart_sugar": 1, "tip_jar": 1}
	GameState.discovered = ["classic_boba", "green_cloud", "brown_sugar"]
	GameState.dark_discovered = ["xiangcai_fantasy"]
	GameState.menu = [{"name": "经典珍珠"}, {"name": "薄荷云"}]
	GameState.campaign_stats = {
		"revenue": 2864, "served": 196, "angry": 7, "stars": 28,
		"event_bonus": 164, "buzz_earned": 27, "special_served": 18,
		"days_completed": 14, "best_streak": 12, "recorded_days": range(1, 15),
	}
	var mid := GameState.build_campaign_summary()
	assert(mid["grade"] == "A")
	assert(int(mid["score"]) == 71,
		"1.0 tree (14 levels) re-scales the upgrade subscore: 7/14*15=8 vs 7/10*15=11")
	GameState.campaign_stats = GameState._new_campaign_stats()
	GameState.day = 14
	GameState.phase = "night"
	GameState.perfect_total = 154
	GameState.coins = 900
	GameState.buzz = 20
	# 1.0 树满配（14 级）才能拿满升级分。 
	GameState.upgrades = {"comfort": 4, "shaker": 4, "smart_sugar": 2, "tip_jar": 4}
	GameState.discovered = ["classic_boba", "green_cloud", "brown_sugar"]
	GameState.dark_discovered = ["xiangcai_fantasy", "zheergen_storm"]
	GameState.menu = [
		{"name": "经典珍珠", "tier": "招牌", "price": 15},
		{"name": "薄荷云", "tier": "爆款", "price": 18},
		{"name": "黑糖乌龙", "tier": "普通", "price": 12},
	]
	var lab: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(lab)
	await get_tree().process_frame
	assert(Sfx.current_music == "night")
	lab._on_sleep()
	await get_tree().process_frame
	assert(_find_button(lab.overlay, "查看首店评级") != null)
	lab.queue_free()
	await get_tree().process_frame
	for day_number in range(1, 15):
		GameState.record_campaign_day(day_number, {
			"earned": 220, "served": 16, "angry": 0, "stars": 3,
			"event_bonus": 10, "event_buzz": 3, "special_served": 2,
			"best_streak": 9,
		})
	# Settlement must be idempotent even if a caller retries the same day.
	GameState.record_campaign_day(14, {"earned": 9999, "served": 99, "stars": 3})
	assert(int(GameState.campaign_stats["days_completed"]) == 14)
	assert(int(GameState.campaign_stats["revenue"]) == 3080)

	var result := GameState.finalize_campaign()
	assert(result["grade"] == "S")
	assert(int(result["score"]) == 100)
	assert(GameState.phase == "campaign")
	assert(int(GameState.legacy["campaigns_completed"]) == 1)
	GameState.finalize_campaign()
	assert(int(GameState.legacy["campaigns_completed"]) == 1)

	var report: Control = load("res://scenes/campaign_summary/campaign_summary.tscn").instantiate()
	add_child(report)
	await get_tree().process_frame
	assert(Sfx.current_music == "campaign")
	assert(report.grade_label.text == "S")
	assert(report.score_label.text == "100 / 100")
	report._request_new_shop()
	assert(report.confirm_overlay.visible)
	report._close_confirmation()
	assert(not report.confirm_overlay.visible)
	report.queue_free()
	await get_tree().process_frame

	GameState.day = 14
	GameState.continue_after_campaign()
	assert(GameState.day == 15)
	assert(GameState.phase == "day")
	GameState.day = 14
	GameState.phase = "campaign"
	var bonus := GameState.start_new_shop_plus("precision")
	assert(int(bonus["coins"]) == 80)
	assert(int(bonus["inspiration"]) == 3)
	assert(GameState.day == 1)
	assert(GameState.phase == "day")
	assert(GameState.coins == 80)
	assert(GameState.inspiration == 3)
	assert(String(bonus["route"]) == "precision")
	assert(GameState.new_shop_route == "precision")
	assert(is_equal_approx(LegacyRoutes.goal_multiplier(), 1.08))
	assert(is_equal_approx(LegacyRoutes.patience_multiplier(), 0.88))
	assert(LegacyRoutes.sale_bonus({}, 0.75, 1) == 1)
	assert(LegacyRoutes.sale_bonus({}, 0.65, 1) == 0)
	assert(LegacyRoutes.progress_text(1, 3, 3).contains("3"))
	GameState.new_shop_route = "rush"
	assert(is_equal_approx(LegacyRoutes.spawn_multiplier(), 0.88))
	assert(LegacyRoutes.sale_bonus({}, 0.2, 2) == 0)
	assert(LegacyRoutes.sale_bonus({}, 0.2, 3) == 1)
	assert(LegacyRoutes.progress_text(5, 4, 4).contains("2/3"))
	GameState.new_shop_route = "trend"
	assert(is_equal_approx(LegacyRoutes.menu_traffic_step(), 0.06))
	assert(LegacyRoutes.sale_bonus({"menu_event_bonus": 4}, 0.2) == 3)
	assert(LegacyRoutes.sale_bonus({}, 0.9) == 0)
	assert(LegacyRoutes.progress_text(1, 2, 6).contains("6"))
	assert(GameState.tutorial_completed)
	assert(int(GameState.legacy["campaigns_completed"]) == 1)
	assert(String(GameState.legacy["best_grade"]) == "S")

	GameState.campaign_claimed = false
	GameState.campaign_summary = {"score": 88, "grade": "S"}
	GameState.finalize_campaign()
	assert(GameState.legacy.get("routes_cleared", []) == ["trend"])
	GameState.finalize_campaign()
	assert(GameState.legacy.get("routes_cleared", []) == ["trend"], "route clears must be idempotent")

	print("[CAMPAIGN] passed grades=C/A/S score=100 idempotent=true endless=day15 new_game_plus=3routes/80/+3")
	Sfx.stop_all()
	await get_tree().process_frame
	get_tree().quit()


func _find_button(node: Node, expected_text: String) -> Button:
	if node is Button and node.text == expected_text:
		return node
	for child in node.get_children():
		var found := _find_button(child, expected_text)
		if found != null:
			return found
	return null
