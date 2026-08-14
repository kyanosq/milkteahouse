## 夜间研发室用的 3D 杯预览包装器：SubViewport + 相机灯光 + CupRig
## （白天舞台直接把 CupRig 放进世界，不经过本包装器）
extends SubViewportContainer

const CupRigScene := preload("res://ui/cup_rig.gd")

var _vp: SubViewport
var _rig: Node3D


func _ready() -> void:
	custom_minimum_size = Vector2(320, 380)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.size = Vector2i(320, 380)
	add_child(_vp)

	var cam := Camera3D.new()
	_vp.add_child(cam)
	cam.look_at_from_position(Vector3(0.2, 0.2, 0.2), Vector3(0, 0.085, 0))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, 35, 0)
	key.light_energy = 1.4
	_vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -140, 0)
	fill.light_energy = 0.5
	_vp.add_child(fill)

	_rig = CupRigScene.new()
	_vp.add_child(_rig)


func update_cup(base: Variant, milk: Variant, tops: Array, sugar: Variant,
		shake_ratio: float, sealed: bool) -> void:
	if _rig:
		_rig.update_cup(base, milk, tops, sugar, shake_ratio, sealed)


func clear_cup() -> void:
	if _rig:
		_rig.clear_cup()


func play_shake() -> void:
	if _rig:
		_rig.play_shake()


func play_serve() -> void:
	if _rig:
		_rig.play_serve()
