## Day 15+ 委托的签约、难度修正、结算幂等、UI 入口与无尽目标封顶回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.research_brief = {}
	GameState.market_settlement = {}
	GameState.settings = {"sfx_volume": 0.0, "music_volume": 0.0, "reduced_motion": true}
	GameState.reset_progress()
	GameState.day = 15
	GameState.phase = "night"
	GameState.coins = 1000
	GameState.inspiration = 0
	GameState.endless = GameState._new_endless_state()

	assert(EndlessContracts.goal_for_day(14) == 332)
	assert(EndlessContracts.goal_for_day(16) == 368)
	assert(EndlessContracts.goal_for_day(17) == 380)
	assert(EndlessContracts.goal_for_day(30) == 380, "the 380 cap must hold through day 30")
	assert(EndlessContracts.goal_for_day(40) == 380, "1.0: the linear creep is gone; adaptive takes over")
	assert(EndlessContracts.goal_for_day(99) == 380)
	# 自适应星目标（D1③）：无历史退回 base；有历史走 max(base, 0.85×MA5) 双向 ±6% 限速。
	GameState.endless["revenue_history"] = []
	GameState.endless["goal_state"] = 0
	assert(EndlessContracts.adaptive_goal_for_day(40) == 380, "no history falls back to base")
	GameState.endless["revenue_history"] = [778, 778, 778, 778, 778]
	GameState.endless["goal_state"] = 600
	assert(EndlessContracts.adaptive_goal_for_day(40) == clampi(661, ceili(600 * 0.94), ceili(600 * 1.06)),
		"adaptive target = clamp(max(base, 0.85*MA5), prev±6%)")
	GameState.endless["goal_state"] = 700
	assert(EndlessContracts.adaptive_goal_for_day(40) == 661,
		"a target inside the ±6% band passes through unchanged")
	GameState.endless["goal_state"] = 1000
	assert(EndlessContracts.adaptive_goal_for_day(40) == ceili(1000 * 0.94),
		"a goal far above the shop's rate only falls 6% per day")
	GameState.endless["revenue_history"] = [100, 100, 100, 100, 100]
	GameState.endless["goal_state"] = 700
	assert(EndlessContracts.adaptive_goal_for_day(40) == ceili(700 * 0.94),
		"a collapsed shop only falls 6% per day - no death spiral")
	GameState.endless["revenue_history"] = []
	EndlessContracts.record_day_performance(778, 661)
	assert(GameState.endless["revenue_history"].size() == 1 and int(GameState.endless["goal_state"]) == 661)
	EndlessContracts.record_day_performance(700, 662)
	assert(GameState.endless["revenue_history"].size() == 2)
	GameState.endless = GameState._new_endless_state()
	assert(EndlessContracts.target_for("streak_stage", 40) == 30, "targets keep the legacy curve through day 40")
	assert(EndlessContracts.target_for("streak_stage", 46) == 31, "targets creep +1 per 6 days past day 40")
	# [P8-F1 2026-08-17] 可赢包络：杯数目标封顶 36（满配 skilled 实测极限 38-42 的 0.9 折）。
	assert(EndlessContracts.target_for("precision_shift", 100) == 36,
		"creeping cup targets clamp to the winnable envelope, not 40")
	var offers := EndlessContracts.available_for_day(16)
	assert(offers.size() == 3)
	assert(int(offers[0]["cost"]) == 120, "day-16 anchor stays at the base fee")
	assert(int(offers[0]["refund"]) == 42)
	assert(String(offers[0]["target_text"]) == "最高连击 ≥ x28")
	# [P8-F2 2026-08-17] 冲刺系数 1.35 → 1.15：无历史回退 368×1.15 = 424。
	assert(int(offers[2]["target"]) == 424)
	# 1.0（D1①）：签约费无上限复利——每天 +15%，后期金币重新有用途。
	assert(EndlessContracts.cost_for({"base_cost": 120}, 20) == 192,
		"fee grows 15% per day past day 16")
	assert(EndlessContracts.cost_for({"base_cost": 120}, 58) == 876,
		"late-game fees keep compounding without a cap")
	var late_offer := EndlessContracts.available_for_day(58)[0]
	assert(int(late_offer["cost"]) == EndlessContracts.cost_for({"base_cost": int(offers[0]["cost"])}, 58))
	assert(EndlessContracts.rank_name(14) == GameLocale.text("CONTRACT_RANK_GOLD"))
	assert(EndlessContracts.rank_name(15) == GameLocale.text("CONTRACT_RANK_CITY_PLUS"))
	assert(EndlessContracts.rank_name(20) == GameLocale.text("CONTRACT_RANK_LEGEND"))
	assert(EndlessContracts.rank_name(30) == GameLocale.text("CONTRACT_RANK_IMMORTAL"),
		"the seventh rank tier exists (D6B)")
	# [P8-F3/P8-F5 2026-08-17] 30+ 接入 CONTRACT_RANK_MAX 并带守擂计数（完成/失败）；
	# 计数键未上本地化表前退回无参数的 CONTRACT_RANK_DEFEND。
	GameState.endless["completed"] = 3
	GameState.endless["failed"] = 2
	var defend_line := EndlessContracts.next_rank_text(30)
	assert(defend_line.contains(GameLocale.text("CONTRACT_RANK_MAX")))
	if TranslationServer.translate("CONTRACT_RANK_DEFEND_COUNT") != "CONTRACT_RANK_DEFEND_COUNT":
		assert(defend_line.contains("3") and defend_line.contains("2"))
	else:
		assert(defend_line.contains(GameLocale.text("CONTRACT_RANK_DEFEND")))
	GameState.endless["completed"] = 0
	GameState.endless["failed"] = 0
	assert(EndlessContracts.next_rank_text(13).contains("2"))
	# [P8-F3 2026-08-17] 20-29 段显示距不朽档（30）的枚数——不再出现 -2/-5 负数。
	assert(EndlessContracts.next_rank_text(22) == GameLocale.text("CONTRACT_RANK_NEXT", [8]))
	assert(EndlessContracts.next_rank_text(25) == GameLocale.text("CONTRACT_RANK_NEXT", [5]))
	assert(not EndlessContracts.next_rank_text(25).contains("-"))
	# 不朽章节：20 章后每个印章要求 ×1.05（D6B）。
	GameState.endless["stamps"] = 22
	assert(EndlessContracts.target_for("streak_stage", 46) == roundi(31.0 * 1.05 * 1.05),
		"stamps past 20 scale the requirement by 1.05 each")
	# [P8-F1 2026-08-17] 包络断言：stamps 25/30 的杯数目标仍钳在可赢包络内。
	GameState.endless["stamps"] = 25
	assert(EndlessContracts.target_for("precision_shift", 58) == EndlessContracts.WINNABLE_TARGET_CAP,
		"stamps=25 must clamp the D58 precision target to the winnable envelope")
	GameState.endless["stamps"] = 30
	assert(EndlessContracts.target_for("streak_stage", 100) == EndlessContracts.WINNABLE_TARGET_CAP,
		"stamps=30 must clamp even the day-100 creeped target")
	# [P8-F2 2026-08-17] 收敛态可赢：MA5=900 → 目标 = 1.15×0.85×900 = 880，
	# 落在冲刺弹性带（+6~15%）内可重复达成；印章缩放后钳到历史最佳×1.10 = 990。
	GameState.endless["revenue_history"] = [900, 900, 900, 900, 900]
	GameState.endless["goal_state"] = 765
	GameState.endless["stamps"] = 0
	assert(EndlessContracts.target_for("revenue_sprint", 58) == 880,
		"converged sprint target = 1.15 * 0.85 * MA5")
	assert(EndlessContracts.target_for("revenue_sprint", 58) < 945,
		"converged target must stay below MA5 + 5% headroom")
	GameState.endless["stamps"] = 30
	assert(EndlessContracts.target_for("revenue_sprint", 58) == 990,
		"stamps escalation clamps the sprint target to best revenue x1.10")
	GameState.endless["stamps"] = 0
	# [P8-F4 2026-08-17] 退款比例随天数上调（+0.002/天，封顶 0.55）：day16 锚点不变，
	# D58 净成本从 ≈888 币/印章回落到约一半。
	assert(absf(EndlessContracts.refund_ratio_for(EndlessContracts.item("streak_stage"), 16) - 0.35) < 0.0001)
	assert(absf(EndlessContracts.refund_ratio_for(EndlessContracts.item("streak_stage"), 58) - 0.434) < 0.0001)
	var late_streak := EndlessContracts.available_for_day(58)[0]
	assert(int(late_streak["refund"]) == roundi(876 * 0.434))
	GameState.endless = GameState._new_endless_state()

	assert(EndlessContracts.sign_contract("streak_stage", 16, false))
	assert(GameState.coins == 880)
	assert(not EndlessContracts.sign_contract("precision_shift", 16, false))
	var active := EndlessContracts.active_for_day(16)
	assert(active["id"] == "streak_stage")
	var base_event := DailyEvents.event_for_day(16)
	var modified := EndlessContracts.apply_to_event(base_event, 16)
	assert(is_equal_approx(float(modified["spawn_mult"]), float(base_event["spawn_mult"]) * 0.92))
	assert(is_equal_approx(float(modified["patience_mult"]), float(base_event["patience_mult"]) * 0.94))
	assert(not EndlessContracts.requirement_met(active, {"best_streak": 27}))
	var success := EndlessContracts.resolve(16, {"best_streak": 28}, false)
	assert(success["success"])
	assert(GameState.coins == 922)
	assert(GameState.inspiration == 2)
	assert(int(GameState.endless["stamps"]) == 1)
	assert(int(GameState.endless["completed"]) == 1)
	assert(EndlessContracts.resolve(16, {"best_streak": 99}, false).is_empty())

	GameState.day = 16
	assert(EndlessContracts.sign_contract("precision_shift", 17, false))
	var precision := EndlessContracts.active_for_day(17)
	assert(not EndlessContracts.requirement_met(precision, {"perfect": 20, "angry": 1}))
	var failed := EndlessContracts.resolve(17, {"perfect": 20, "angry": 1}, false)
	assert(not failed["success"])
	assert(int(GameState.endless["failed"]) == 1)
	assert(int(GameState.endless["streak"]) == 0)

	# Night UI exposes the system only after the campaign and writes the selection into tomorrow's preview.
	GameState.day = 15
	GameState.coins = 1000
	GameState.endless = GameState._new_endless_state()
	var lab: Control = load("res://scenes/night_lab/night_lab.tscn").instantiate()
	add_child(lab)
	await get_tree().process_frame
	assert(lab.contract_button.visible)
	assert(lab.contract_button.text.contains("选择明日挑战"))
	lab._open_contracts()
	assert(lab.contract_panel.visible)
	lab.contract_panel._sign("revenue_sprint", 16)
	await get_tree().process_frame
	assert(EndlessContracts.active_for_day(16)["id"] == "revenue_sprint")
	assert(lab.contract_button.text.contains("营收冲刺"))
	assert(lab.tomorrow_contract_label.text.contains("营业营收"))
	lab.queue_free()
	await get_tree().process_frame

	print("[ENDLESS_CONTRACT] passed offers=3 cap=380 success_refund=42 stamps=1 failure_sink=true ui=true")
	Sfx.stop_all()
	await get_tree().process_frame
	get_tree().quit()
