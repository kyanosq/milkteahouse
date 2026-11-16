## Native renderer close-up for inspecting the editable staff models and work clips.
extends Node

func _ready() -> void:
	GameState.test_mode = true
	GameState.upgrades = {}
	GameState.new_shop_route = ""
	var stage: SubViewportContainer = load("res://ui/shop_stage.gd").new()
	add_child(stage)
	for child in stage._vp.get_children():
		if child is Node3D and not child is Light3D and not child is Camera3D:
			child.visible = false
	stage._cam.position = Vector3(0, 1.28, 3.6)
	stage._cam.look_at(Vector3(0, 0.45, 0))
	stage._cam.fov = 31
	stage._vp.msaa_3d = Viewport.MSAA_4X
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(20, 20)
	floor_mesh.position.y = -0.008
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("D1DFDA")
	floor_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	floor_mesh.material_override = floor_material
	stage._vp.add_child(floor_mesh)
	for node in stage._vp.get_children():
		if node is WorldEnvironment:
			node.environment.background_color = Color("E7EFEE")
	for index in 3:
		var id: String = ["xiaoman", "taozi", "acheng"][index]
		var model: Node3D = load(stage.STAFF_MODELS[id]).instantiate()
		model.position.x = (index - 1) * 0.88
		model.rotation_degrees.y = -10
		ShopToon.apply(model)
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			mesh.get_active_material(0).disable_receive_shadows = true
		stage._vp.add_child(model)
		var animation: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
		animation.get_animation("Work").loop_mode = Animation.LOOP_LINEAR
		animation.play("Work")
		var label := Label.new()
		label.text = ["小满 · 薄荷工装", "桃子 · 珊瑚围裙", "阿澄 · 靛蓝制服"][index]
		label.position = Vector2(184 + index * 307, 584)
		label.size = Vector2(300, 44)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", load("res://assets/fonts/LXGWWenKai-Regular.ttf"))
		label.add_theme_font_size_override("font_size", 25)
		label.add_theme_color_override("font_color", Color("425D68"))
		add_child(label)
	await get_tree().create_timer(2.0).timeout
	var output := OS.get_environment("SHOWCASE_OUTPUT")
	if not output.is_empty():
		get_viewport().get_texture().get_image().save_png(output)
	if OS.get_environment("SHOWCASE_MOVIE") == "1":
		await get_tree().create_timer(4.0).timeout
	stage.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
