## 3D 顾客头像：四种 Blender 轮廓 + 运行时衣服/发色组合。
extends SubViewportContainer

const CUSTOMER_MODELS: Array[PackedScene] = [
	preload("res://assets/glb/customer.glb"),
	preload("res://assets/glb/customer_bob.glb"),
	preload("res://assets/glb/customer_cap.glb"),
	preload("res://assets/glb/customer_buns.glb"),
]

var tint := Color(0.85, 0.45, 0.4)
var _vp: SubViewport
var variant := 0


func _init(color := Color(0.85, 0.45, 0.4), model_variant := 0) -> void:
	tint = color
	variant = posmod(model_variant, CUSTOMER_MODELS.size())


func _ready() -> void:
	custom_minimum_size = Vector2(88, 88)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.size = Vector2i(88, 88)
	add_child(_vp)

	var model: Node3D = CUSTOMER_MODELS[variant].instantiate()
	_vp.add_child(model)
	# 染衣服（Cloth 材质实例化），发色随机深浅
	var cloth: StandardMaterial3D = null
	var hair: StandardMaterial3D = null
	for child in model.get_children():
		if child is MeshInstance3D:
			var n := String(child.name)
			if n.begins_with("Body") or n.begins_with("Arm"):
				if cloth == null:
					cloth = child.get_active_material(0).duplicate()
					cloth.albedo_color = tint
				child.set_surface_override_material(0, cloth)
			elif n.begins_with("Hair"):
				if hair == null:
					hair = child.get_active_material(0).duplicate()
					hair.albedo_color = Color(0.22, 0.15, 0.12).lerp(
						Color(0.55, 0.4, 0.28), randf())
				child.set_surface_override_material(0, hair)
	model.rotation_degrees.y = randf_range(-14, 14)
	# 待机动画：呼吸起伏 + 轻微摆动（相位随机，多人不同步）
	var bob := create_tween().set_loops()
	var dur := randf_range(0.9, 1.3)
	bob.tween_property(model, "position:y", 0.012, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(model, "position:y", 0.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var sway := create_tween().set_loops()
	var base_rot: float = model.rotation_degrees.y
	sway.tween_property(model, "rotation_degrees:y", base_rot + 5.0, dur * 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(model, "rotation_degrees:y", base_rot - 5.0, dur * 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var cam := Camera3D.new()
	_vp.add_child(cam)
	cam.position = Vector3(0, 0.44, 0.72)
	cam.look_at(Vector3(0, 0.36, 0))
	cam.fov = 42

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.3
	_vp.add_child(sun)
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.55, 0.5)
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
