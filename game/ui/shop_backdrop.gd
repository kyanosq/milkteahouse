## 全屏 3D 店铺背景（shop_scene.glb），支持日/夜灯光氛围
extends SubViewportContainer

var night := false
var _vp: SubViewport


func _init(is_night := false) -> void:
	night = is_night


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.size = Vector2i(1280, 720)
	add_child(_vp)

	var model: Node3D = (load("res://assets/glb/shop_scene.glb") as PackedScene).instantiate()
	_vp.add_child(model)

	var cam := Camera3D.new()
	_vp.add_child(cam)
	cam.position = Vector3(0, 1.9, 3.6)
	cam.look_at(Vector3(0, 0.9, -1.15))
	cam.fov = 40

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -20, 0)
	_vp.add_child(sun)
	var warm := OmniLight3D.new()
	warm.position = Vector3(0, 2.1, 0.4)
	warm.omni_range = 6.0
	_vp.add_child(warm)

	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var we := WorldEnvironment.new()
	if night:
		sun.light_energy = 0.15
		sun.light_color = Color(0.6, 0.65, 0.9)
		warm.light_energy = 1.6
		warm.light_color = Color(1.0, 0.75, 0.45)
		env.ambient_light_color = Color(0.16, 0.18, 0.30)
		env.ambient_light_energy = 0.9
	else:
		sun.light_energy = 1.1
		warm.light_energy = 1.2
		warm.light_color = Color(1.0, 0.9, 0.75)
		env.ambient_light_color = Color(0.55, 0.5, 0.46)
		env.ambient_light_energy = 1.0
	we.environment = env
	_vp.add_child(we)
