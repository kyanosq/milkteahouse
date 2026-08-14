## Blender MCP 资产回归：环境关键节点、四种普通顾客轮转与三种特殊顾客模型。
extends Node

const CUSTOMER_PATHS := [
	"res://assets/glb/customer.glb",
	"res://assets/glb/customer_bob.glb",
	"res://assets/glb/customer_cap.glb",
	"res://assets/glb/customer_buns.glb",
]
const SPECIAL_CUSTOMER_PATHS := {
	"critic": "res://assets/glb/customer_critic.glb",
	"influencer": "res://assets/glb/customer_influencer.glb",
	"group": "res://assets/glb/customer_group.glb",
}
const STAFF_MODEL_PATHS := {
	"xiaoman": "res://assets/glb/staff_xiaoman.glb",
	"taozi": "res://assets/glb/staff_taozi.glb",
	"acheng": "res://assets/glb/staff_acheng.glb",
}
const UPGRADE_MODEL_PATHS := {
	"comfort": "res://assets/glb/props/upgrades/comfort.glb",
	"shaker": "res://assets/glb/props/upgrades/auto_shaker.glb",
	"smart_sugar": "res://assets/glb/props/upgrades/smart_sugar.glb",
	"tip_jar": "res://assets/glb/props/upgrades/tip_jar.glb",
}
const PROP_MODEL_PATHS := {
	"kettle": "res://assets/glb/props/kettle.glb",
	"milk_carton": "res://assets/glb/props/milk_carton.glb",
	"pickup_tray": "res://assets/glb/props/pickup_tray.glb",
	"prep_mat": "res://assets/glb/props/prep_mat.glb",
	"service_bell": "res://assets/glb/props/service_bell.glb",
	"shaker": "res://assets/glb/props/shaker.glb",
	"sugar_pump": "res://assets/glb/props/sugar_pump.glb",
	"topping_bin": "res://assets/glb/props/topping_bin.glb",
}
const ROUTE_SIGN_PATHS := {
	"rush": "res://assets/glb/props/routes/route_rush.glb",
	"precision": "res://assets/glb/props/routes/route_precision.glb",
	"trend": "res://assets/glb/props/routes/route_trend.glb",
}


func _ready() -> void:
	GameState.test_mode = true
	GameState.settings = {"sound_volume": 0.0, "reduced_motion": true}
	GameState.upgrades = {}
	GameState.new_shop_route = ""

	var shop_resource := load("res://assets/glb/shop_scene.glb") as PackedScene
	assert(shop_resource != null)
	var shop_model := shop_resource.instantiate()
	for required in ["PD_Fascia_Base", "PD_JarFill_0", "PD_LampShade_0", "PD_MenuCup"]:
		assert(shop_model.find_child(required, true, false) != null, "missing Blender node: " + required)
	var shop_meshes := _mesh_count(shop_model)
	var shop_triangles := _triangle_count(shop_model)
	assert(shop_meshes <= 40, "shop runtime mesh budget exceeded")
	assert(shop_triangles <= 20_000, "shop runtime triangle budget exceeded")
	shop_model.free()
	assert(_file_size("res://assets/glb/shop_scene.glb") < 5 * 1024 * 1024)

	var lab_resource := load("res://assets/glb/night_lab_scene.glb") as PackedScene
	assert(lab_resource != null)
	var lab_model := lab_resource.instantiate()
	for required in ["NL_BackWall", "NL_DeskTop", "NL_MatTop", "NL_LampShade", "NL_UpperShelf"]:
		assert(lab_model.find_child(required, true, false) != null, "missing night-lab Blender node: " + required)
	assert(_mesh_count(lab_model) <= 30)
	lab_model.free()
	assert(_file_size("res://assets/glb/night_lab_scene.glb") < 2 * 1024 * 1024)

	var regular_stats: Array[String] = []
	for path in CUSTOMER_PATHS:
		var resource := load(path) as PackedScene
		assert(resource != null, "customer model failed to load: " + path)
		var model := resource.instantiate()
		assert(_has_mesh_prefix(model, "Body"))
		assert(_has_mesh_prefix(model, "Hair"))
		var mesh_count := _mesh_count(model)
		var triangles := _triangle_count(model)
		assert(mesh_count >= 8 and mesh_count <= 13, "%s has %d runtime meshes" % [path, mesh_count])
		assert(triangles >= 1500 and triangles <= 3600, "%s has %d triangles" % [path, triangles])
		regular_stats.append("%s=%d/%d" % [path.get_file().get_basename(), mesh_count, triangles])
		model.free()
		assert(_file_size(path) < 2 * 1024 * 1024)
	var prop_stats: Array[String] = []
	for prop_id in PROP_MODEL_PATHS:
		var path: String = PROP_MODEL_PATHS[prop_id]
		var resource := load(path) as PackedScene
		assert(resource != null, "prop model failed to load: " + path)
		var model := resource.instantiate()
		assert(_mesh_count(model) <= 8, "%s exceeds 8 runtime meshes" % prop_id)
		var triangles := _triangle_count(model)
		assert(triangles <= 2500, "%s has %d triangles" % [prop_id, triangles])
		prop_stats.append("%s=%d/%d" % [prop_id, _mesh_count(model), triangles])
		model.free()
		assert(_file_size(path) < 256 * 1024)
	for kind in SPECIAL_CUSTOMER_PATHS:
		var path: String = SPECIAL_CUSTOMER_PATHS[kind]
		var resource := load(path) as PackedScene
		assert(resource != null, "special customer model failed to load: " + path)
		var model := resource.instantiate()
		assert(_has_mesh_prefix(model, "Body"))
		assert(_has_mesh_prefix(model, "Hair"))
		assert(_mesh_count(model) <= 10)
		model.free()
		assert(_file_size(path) < 256 * 1024)
	for staff_id in STAFF_MODEL_PATHS:
		var path: String = STAFF_MODEL_PATHS[staff_id]
		var resource := load(path) as PackedScene
		assert(resource != null, "staff model failed to load: " + path)
		var model := resource.instantiate()
		assert(_has_mesh_prefix(model, "Body"))
		assert(_has_mesh_prefix(model, "Hair"))
		assert(_mesh_count(model) <= 9)
		model.free()
		assert(_file_size(path) < 256 * 1024)
	for upgrade_id in UPGRADE_MODEL_PATHS:
		var path: String = UPGRADE_MODEL_PATHS[upgrade_id]
		var resource := load(path) as PackedScene
		assert(resource != null, "upgrade model failed to load: " + path)
		var model := resource.instantiate()
		assert(_has_mesh_prefix(model, "Base_"))
		var runtime_meshes := _mesh_count(model)
		assert(runtime_meshes <= 14, "%s has %d runtime meshes" % [upgrade_id, runtime_meshes])
		model.free()
		assert(_file_size(path) < 256 * 1024)
	var route_sign_stats: Array[String] = []
	for route_id in ROUTE_SIGN_PATHS:
		var path: String = ROUTE_SIGN_PATHS[route_id]
		var resource := load(path) as PackedScene
		assert(resource != null, "route sign failed to load: " + path)
		var sign_model := resource.instantiate()
		assert(_has_mesh_prefix(sign_model, "Route_"))
		var sign_meshes := _mesh_count(sign_model)
		var sign_triangles := _triangle_count(sign_model)
		assert(sign_meshes <= 5, "%s sign has %d runtime meshes" % [route_id, sign_meshes])
		assert(sign_triangles <= 1000, "%s sign has %d triangles" % [route_id, sign_triangles])
		assert(_file_size(path) < 64 * 1024)
		route_sign_stats.append("%s=%d/%d" % [route_id, sign_meshes, sign_triangles])
		sign_model.free()

	var stage: SubViewportContainer = load("res://ui/shop_stage.gd").new()
	add_child(stage)
	await get_tree().process_frame
	assert(stage.get_route_sign() == null, "first campaign must not show a route sign")
	var variants: Array[int] = []
	for i in CUSTOMER_PATHS.size():
		var actor: Node3D = stage.add_customer(i % 3, Color.from_hsv(float(i) / 4.0, 0.55, 0.85))
		variants.append(int(actor.get_meta("model_variant", -1)))
	assert(variants == [0, 1, 2, 3])
	for kind in SPECIAL_CUSTOMER_PATHS:
		var actor: Node3D = stage.add_customer(0, Color.WHITE, kind)
		assert(String(actor.get_meta("customer_kind", "")) == kind)
		assert(String(actor.get_meta("special_model", "")) == kind)
		assert(int(actor.get_meta("model_variant", 0)) == -1)
	var next_regular: Node3D = stage.add_customer(0, Color.WHITE)
	assert(int(next_regular.get_meta("model_variant", -1)) == 0)
	for staff_id in STAFF_MODEL_PATHS:
		var staff_actor: Node3D = stage.add_staff(staff_id)
		assert(String(staff_actor.get_meta("staff_model", "")) == staff_id)
	stage.remove_staff()
	stage.queue_free()
	await get_tree().process_frame
	for route_id in ROUTE_SIGN_PATHS:
		GameState.new_shop_route = route_id
		var route_stage: SubViewportContainer = load("res://ui/shop_stage.gd").new()
		add_child(route_stage)
		await get_tree().process_frame
		var route_sign: Node3D = route_stage.get_route_sign()
		assert(route_sign != null, "missing in-shop route sign: " + route_id)
		assert(String(route_sign.get_meta("route_id", "")) == route_id)
		assert(not route_stage.pulse_route_sign(), "reduced motion must suppress route-sign pulse")
		assert(route_sign.scale.is_equal_approx(Vector3.ONE * 0.68))
		route_stage.queue_free()
		await get_tree().process_frame
		var route_lab: SubViewportContainer = load("res://ui/night_lab_backdrop.gd").new()
		add_child(route_lab)
		await get_tree().process_frame
		var night_sign: Node3D = route_lab.get_route_sign()
		assert(night_sign != null, "missing night-lab route sign: " + route_id)
		assert(String(night_sign.get_meta("route_id", "")) == route_id)
		route_lab.queue_free()
		await get_tree().process_frame
	GameState.new_shop_route = ""
	var first_lab: SubViewportContainer = load("res://ui/night_lab_backdrop.gd").new()
	add_child(first_lab)
	await get_tree().process_frame
	assert(first_lab.get_route_sign() == null, "first campaign night lab must not show a route sign")
	first_lab.queue_free()
	await get_tree().process_frame
	GameState.new_shop_route = "trend"
	GameState.settings["reduced_motion"] = false
	var animated_stage: SubViewportContainer = load("res://ui/shop_stage.gd").new()
	add_child(animated_stage)
	await get_tree().process_frame
	var animated_sign: Node3D = animated_stage.get_route_sign()
	assert(animated_stage.pulse_route_sign(), "route-sign pulse should run when motion is enabled")
	await get_tree().create_timer(0.09).timeout
	assert(animated_sign.scale.x > 0.68, "route-sign pulse never left its base scale")
	await get_tree().create_timer(0.20).timeout
	assert(animated_sign.scale.is_equal_approx(Vector3.ONE * 0.68), "route-sign pulse did not settle")
	animated_stage.queue_free()
	await get_tree().process_frame
	GameState.new_shop_route = ""
	GameState.settings["reduced_motion"] = true

	GameState.upgrades = {"comfort": 3, "shaker": 3, "smart_sugar": 1, "tip_jar": 3}
	var upgraded_stage: SubViewportContainer = load("res://ui/shop_stage.gd").new()
	add_child(upgraded_stage)
	await get_tree().process_frame
	for upgrade_id in UPGRADE_MODEL_PATHS:
		var visual: Node3D = upgraded_stage.get_upgrade_visual(upgrade_id)
		assert(visual != null, "missing in-shop upgrade visual: " + upgrade_id)
		assert(String(visual.get_meta("upgrade_id", "")) == upgrade_id)
		assert(int(visual.get_meta("upgrade_level", 0)) == int(GameState.upgrades[upgrade_id]))
	for upgrade_id in ["comfort", "shaker", "tip_jar"]:
		var visual: Node3D = upgraded_stage.get_upgrade_visual(upgrade_id)
		assert(_has_visible_prefix(visual, "L2_"), "level 2 parts hidden: " + upgrade_id)
		assert(_has_visible_prefix(visual, "L3_"), "level 3 parts hidden: " + upgrade_id)
		upgraded_stage._set_upgrade_visual_level(visual, 1)
		assert(not _has_visible_prefix(visual, "L2_"), "level 2 parts leaked into level 1: " + upgrade_id)
		assert(not _has_visible_prefix(visual, "L3_"), "level 3 parts leaked into level 1: " + upgrade_id)
	upgraded_stage.queue_free()
	await get_tree().process_frame
	GameState.upgrades = {}

	print("[MODELS] passed environments=2 shop_meshes<=40 regular_customers=4 props=8 special_customers=3 staff_models=3 upgrade_models=4 route_signs=3 runtime_glb_under_budget")
	print("[MODEL_BUDGET] shop=%d/%d regular=[%s] props=[%s] route_signs=[%s]" % [
		shop_meshes, shop_triangles, ", ".join(regular_stats), ", ".join(prop_stats),
		", ".join(route_sign_stats)])
	Sfx.stop_all()
	await get_tree().process_frame
	get_tree().quit()


func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null)
	var size := file.get_length()
	file.close()
	return size


func _has_mesh_prefix(root: Node, prefix: String) -> bool:
	if root is MeshInstance3D and String(root.name).begins_with(prefix):
		return true
	for child in root.get_children():
		if _has_mesh_prefix(child, prefix):
			return true
	return false


func _has_visible_prefix(root: Node, prefix: String) -> bool:
	if root is VisualInstance3D and String(root.name).begins_with(prefix) and root.visible:
		return true
	for child in root.get_children():
		if _has_visible_prefix(child, prefix):
			return true
	return false


func _mesh_count(root: Node) -> int:
	var count := 1 if root is MeshInstance3D else 0
	for child in root.get_children():
		count += _mesh_count(child)
	return count


func _triangle_count(root: Node) -> int:
	var count := 0
	if root is MeshInstance3D and root.mesh != null:
		for surface in root.mesh.get_surface_count():
			if root.mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var arrays: Array = root.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if not indices.is_empty():
				count += indices.size() / 3
			else:
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				count += vertices.size() / 3
	for child in root.get_children():
		count += _triangle_count(child)
	return count
