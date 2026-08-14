## Day 15+ 委托的签约、难度修正、结算幂等、UI 入口与无尽目标封顶回归。
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.research_brief = {}
	GameState.market_settlement = {}
	GameState.settings = {"sound_volume": 0.0, "sfx_volume": 0.0, "music_volume": 0.0, "reduced_motion": true}
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
	assert(EndlessContracts.goal_for_day(40) == 400, "day 40 goal creeps +2/day past day 30")
	assert(EndlessContracts.goal_for_day(50) == 420)
	assert(EndlessContracts.goal_for_day(99) == 420, "the late-game goal ceiling stays bounded")
	assert(EndlessContracts.target_for("streak_stage", 40) == 30, "targets keep the legacy curve through day 40")
	assert(EndlessContracts.target_for("streak_stage", 46) == 31, "targets creep +1 per 6 days past day 40")
	assert(EndlessContracts.target_for("precision_shift", 100) == 40, "creeping targets cap at 40")
	var offers := EndlessContracts.available_for_day(16)
	assert(offers.size() == 3)
	assert(int(offers[0]["cost"]) == 120)
	assert(int(offers[0]["refund"]) == 42)
	assert(String(offers[0]["target_text"]) == "最高连击 ≥ x28")
	assert(int(offers[2]["target"]) == 497)
	var late_offer := EndlessContracts.available_for_day(58)[0]
	assert(int(late_offer["cost"]) == int(offers[0]["cost"]) + 210,
		"signing costs keep consuming late-game coins up to +210")
	assert(EndlessContracts.rank_name(14) == GameLocale.text("CONTRACT_RANK_GOLD"))
	assert(EndlessContracts.rank_name(15) == GameLocale.text("CONTRACT_RANK_CITY_PLUS"))
	assert(EndlessContracts.rank_name(20) == GameLocale.text("CONTRACT_RANK_LEGEND"))
	assert(EndlessContracts.next_rank_text(13).contains("2"))

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
