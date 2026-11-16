## Run headless for gait/queue regression, or WALK_CAPTURE=1 with --write-movie.
extends Node


func _ready() -> void:
	GameState.test_mode = true
	GameState.day = 1
	GameState.upgrades = {}
	GameState.staff = {}
	if OS.get_environment("WALK_STAFF") == "1":
		GameState.day = 8
		GameState.staff = StaffCatalog.candidate("taozi").duplicate(true)
	GameState.new_shop_route = ""
	GameState.settings = {"reduced_motion": false, "music_volume": 0.0, "sfx_volume": 0.0}
	var shop: Control = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(shop)
	shop.running = false
	shop._spawn_customer()
	if OS.get_environment("WALK_CAPTURE") == "1":
		await get_tree().create_timer(2.0).timeout
		shop._spawn_customer()
		await get_tree().create_timer(2.0).timeout
		shop._spawn_customer()
		await get_tree().create_timer(4.5).timeout
		shop._remove_customer(shop.customers[0], true)
		await get_tree().create_timer(4.5).timeout
		shop._spawn_customer()
		await get_tree().create_timer(5.0).timeout
	else:
		var actor: Node3D = shop.customers[0]["actor"]
		actor.set_process(false)
		assert(actor.skeleton.get_bone_count() == 13)
		assert(actor.animation.has_animation("Walk") and actor.animation.has_animation("Idle"))
		actor.animation.play("Walk")
		actor.animation.speed_scale = 0.0
		var left: int = actor.skeleton.find_bone("Foot_L")
		var right: int = actor.skeleton.find_bone("Foot_R")
		actor.animation.seek(0.10, true)
		var foot_a: Vector3 = actor.skeleton.get_bone_global_pose(left).origin
		actor.animation.seek(0.25, true)
		var foot_b: Vector3 = actor.skeleton.get_bone_global_pose(left).origin
		assert(absf(foot_a.y - 0.040) < 0.002 and absf(foot_b.y - 0.040) < 0.002,
			"stance foot must stay on the floor")
		assert(absf(foot_b.z - foot_a.z + actor.STRIDE * 0.15) < 0.002,
			"stance foot must cancel forward root travel")
		assert(actor.skeleton.get_bone_global_pose(right).origin.y > 0.065,
			"the swing foot must lift clear of the floor")
		actor.settle()
		shop._spawn_customer()
		var follower: Node3D = shop.customers[1]["actor"]
		follower.settle()
		shop._remove_customer(shop.customers[0], true)
		assert(actor.departing and not actor.path.is_empty())
		assert(shop.customers[0]["slot"] == 0 and shop.customers[0]["order_badge"].text == "1")
		assert(follower.path.back().is_equal_approx(shop.stage.QUEUE_SPOTS[0]),
			"the second customer must walk into the vacated first slot")
		follower.wait_time = 0.0
		var before: Vector3 = follower.position
		follower._process(0.10)
		assert(follower.position.distance_to(before) > 0.0
			and follower.position.distance_to(before) <= follower.WALK_SPEED * 0.10,
			"queue movement must walk at a bounded speed, not teleport")
		before = follower.position
		get_tree().paused = true
		await get_tree().create_timer(0.10).timeout
		assert(follower.position.is_equal_approx(before), "pausing must freeze locomotion")
		get_tree().paused = false
		GameState.settings["reduced_motion"] = true
		shop._on_reduced_motion_toggled(true)
		assert(follower.path.is_empty() and follower.position.is_equal_approx(shop.stage.QUEUE_SPOTS[0]))
		await get_tree().process_frame
		assert(not is_instance_valid(actor), "reduced motion must clean up departed actors")
		print("[CUSTOMER_WALK] passed skeleton=13 clips=2 planted_feet=true queue_reflow=true pause=true reduced_motion=true")
	Sfx.stop_all()
	shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
