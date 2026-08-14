## 夜间研发室独立 3D 背景：Blender-authored experiment desk + practical lights.
extends SubViewportContainer

const ROUTE_SIGN_MODELS: Dictionary = {
	"rush": preload("res://assets/glb/props/routes/route_rush.glb"),
	"precision": preload("res://assets/glb/props/routes/route_precision.glb"),
	"trend": preload("res://assets/glb/props/routes/route_trend.glb"),
}

var _vp: SubViewport
var _route_sign: Node3D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.size = Vector2i(1280, 720)
	_vp.msaa_3d = Viewport.MSAA_2X
	add_child(_vp)

	var model: Node3D = (load("res://assets/glb/night_lab_scene.glb") as PackedScene).instantiate()
	_vp.add_child(model)
	_build_route_sign()

	# Blender (x, y, z) maps to Godot (x, z, -y). Vertical FOV 27° matches
	# the 44 mm Blender acceptance camera at 16:9.
	var cam := Camera3D.new()
	_vp.add_child(cam)
	cam.position = Vector3(0.0, 3.62, 6.65)
	cam.look_at(Vector3(0.0, 1.17, 0.02))
	cam.fov = 27.0

	var cool := DirectionalLight3D.new()
	cool.rotation_degrees = Vector3(-48, -24, 0)
	cool.light_color = Color(0.50, 0.64, 0.95)
	cool.light_energy = 0.56
	cool.shadow_enabled = true
	cool.shadow_opacity = 0.42
	cool.light_angular_distance = 1.2
	_vp.add_child(cool)

	var lamp := OmniLight3D.new()
	lamp.position = Vector3(1.88, 1.98, 0.35)
	lamp.light_color = Color(1.0, 0.68, 0.46)
	lamp.light_energy = 0.86
	lamp.omni_range = 4.2
	lamp.shadow_enabled = true
	lamp.shadow_opacity = 0.34
	_vp.add_child(lamp)

	var candle := OmniLight3D.new()
	candle.position = Vector3(-2.43, 1.08, 0.38)
	candle.light_color = Color(1.0, 0.52, 0.30)
	candle.light_energy = 0.28
	candle.omni_range = 2.2
	candle.shadow_enabled = true
	candle.shadow_opacity = 0.28
	_vp.add_child(candle)

	# Camera-side readability fill: lifts the desk and small props without adding
	# another shadow direction, while the practical lights keep the night mood.
	var readability := OmniLight3D.new()
	readability.position = Vector3(0.0, 3.2, 4.3)
	readability.light_color = Color(0.72, 0.82, 1.0)
	readability.light_energy = 1.15
	readability.omni_range = 11.0
	readability.shadow_enabled = false
	_vp.add_child(readability)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# On ultrawide screens the authored room ends before the viewport edge; a
	# deliberate indigo overscan reads as atmosphere instead of black pillarbox.
	env.background_color = Color("141F3A")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.26, 0.34, 0.55)
	env.ambient_light_energy = 0.96
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 4.0
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.96
	env.adjustment_saturation = 1.02
	env.adjustment_contrast = 1.06
	# Forward Mobile does not implement SSAO. The three-light night rig is authored
	# to remain legible without it, so avoid the unsupported renderer state entirely.
	env.ssao_enabled = RenderingServer.get_current_rendering_method() != "mobile"
	env.ssao_intensity = 1.2
	env.ssao_radius = 0.45
	env.glow_enabled = true
	env.glow_intensity = 0.12
	env.glow_bloom = 0.012
	env.glow_hdr_threshold = 1.3
	var world := WorldEnvironment.new()
	world.environment = env
	_vp.add_child(world)


## 新店+身份延续到夜间决策场景：同一块实体店招挂在实验桌后墙。
## 首周目没有路线，保持原始研发室构图。
func _build_route_sign() -> void:
	var route_id := LegacyRoutes.active_id()
	var scene: PackedScene = ROUTE_SIGN_MODELS.get(route_id)
	if scene == null:
		return
	_route_sign = scene.instantiate()
	_route_sign.name = "NightRouteSign_%s" % route_id
	_route_sign.position = Vector3(0.68, 1.32, 0.05)
	_route_sign.scale = Vector3.ONE * 0.62
	_route_sign.set_meta("route_id", route_id)
	_disable_small_prop_shadows_on_mobile(_route_sign)
	_vp.add_child(_route_sign)


func get_route_sign() -> Node3D:
	return _route_sign


func _disable_small_prop_shadows_on_mobile(root: Node) -> void:
	if RenderingServer.get_current_rendering_method() != "mobile":
		return
	if root is GeometryInstance3D:
		root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in root.get_children():
		_disable_small_prop_shadows_on_mobile(child)
