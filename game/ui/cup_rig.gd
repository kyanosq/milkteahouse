## 世界内奶茶杯（Node3D）：可放进任意 3D 场景的完整杯体
## 数值驱动液体 shader + Jolt 滚珠（仅视觉），从原 cup_view 拆出以便白天舞台直接复用
class_name CupRig
extends Node3D

const CUP_H := 0.16
const R_BOTTOM := 0.032
const R_TOP := 0.0425

const LIQUID_SHADER := """
shader_type spatial;
uniform vec4 tea_color : source_color = vec4(0.4, 0.25, 0.1, 1.0);
uniform vec4 milk_color : source_color = vec4(0.95, 0.9, 0.8, 1.0);
uniform float milk_line = 0.72;
uniform float blend_soft = 0.03;
uniform float tiger = 0.0;
uniform float half_h = 0.05;
varying vec3 vpos;
varying vec3 mnormal;
void vertex() {
	vpos = VERTEX;
	mnormal = NORMAL;
}
void fragment() {
	float t = clamp((vpos.y + half_h) / (2.0 * half_h), 0.0, 1.0);
	float m = smoothstep(milk_line - blend_soft, milk_line + blend_soft, t);
	vec3 col = mix(tea_color.rgb, milk_color.rgb, m);
	float wallness = 1.0 - abs(mnormal.y);
	float ang = atan(vpos.z, vpos.x);
	float stripe = smoothstep(0.45, 0.95, sin(ang * 9.0 + t * 5.0) * 0.5 + 0.5);
	col = mix(col, col * 0.3, stripe * tiger * wallness * (0.4 + 0.6 * t));
	ALBEDO = col;
	ROUGHNESS = 0.3;
}
"""

var _wob: Node3D          # 晃动动画载体
var _liquid: MeshInstance3D
var _liq_mat: ShaderMaterial
var _pearl_bodies: Array = []
var _pearl_start: Array = []
var _pearl_mat: StandardMaterial3D
var _straw_parts: Array[Node3D] = []
var _film_parts: Array[Node3D] = []
var _shake_tw: Tween


func _ready() -> void:
	_wob = Node3D.new()
	add_child(_wob)
	var model: Node3D = (load("res://assets/glb/milk_tea_cup.glb") as PackedScene).instantiate()
	_wob.add_child(model)

	var pearl_mesh: Mesh = null
	for child in model.get_children():
		var n := String(child.name)
		if n == "LiquidTea" or n == "LiquidMilk":
			child.visible = false
		elif n == "Cup" or n == "CupRim":
			var cm: StandardMaterial3D = child.get_active_material(0).duplicate()
			cm.albedo_color.a = 0.32
			child.set_surface_override_material(0, cm)
		elif n.begins_with("Pearl_"):
			if pearl_mesh == null:
				pearl_mesh = child.mesh
				_pearl_mat = child.get_active_material(0).duplicate()
			child.queue_free()
		elif n.begins_with("Straw"):
			_straw_parts.append(child)
			child.visible = false
		elif n.begins_with("SealFilm"):
			_film_parts.append(child)
			child.visible = false
	if pearl_mesh:
		_build_pearl_physics(pearl_mesh)
	_build_liquid()
	clear_cup()


func _build_pearl_physics(pearl_mesh: Mesh) -> void:
	# 碰撞体与刚体挂在根节点（不进 _wob）：避免挤压动画的非均匀缩放传导给 Jolt 球体
	var cup_body := StaticBody3D.new()
	add_child(cup_body)
	var floor_shape := CollisionShape3D.new()
	var fs := CylinderShape3D.new()
	fs.radius = 0.032
	fs.height = 0.004
	floor_shape.shape = fs
	floor_shape.position = Vector3(0, 0.002, 0)
	cup_body.add_child(floor_shape)
	var lid_shape := CollisionShape3D.new()
	lid_shape.shape = fs.duplicate()
	lid_shape.position = Vector3(0, 0.075, 0)
	cup_body.add_child(lid_shape)
	for i in 8:
		var ang := TAU * float(i) / 8.0
		var wall := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.028, 0.075, 0.003)
		wall.shape = bs
		wall.position = Vector3(cos(ang) * 0.031, 0.038, sin(ang) * 0.031)
		wall.rotation = Vector3(0, -ang + PI / 2.0, 0)
		cup_body.add_child(wall)

	for i in 10:
		var body := RigidBody3D.new()
		body.mass = 0.002
		body.gravity_scale = 0.5
		body.linear_damp = 2.5
		body.angular_damp = 3.0
		body.input_ray_pickable = false
		var cs := CollisionShape3D.new()
		var ss := SphereShape3D.new()
		ss.radius = 0.0075
		cs.shape = ss
		body.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = pearl_mesh
		mi.scale = Vector3(1.25, 1.25, 1.25)
		mi.set_surface_override_material(0, _pearl_mat)
		body.add_child(mi)
		var ang := TAU * float(i) / 10.0
		var r := 0.018 if i % 2 == 0 else 0.009
		var pos := Vector3(cos(ang) * r, 0.012 + 0.012 * float(i % 3), sin(ang) * r)
		body.position = pos
		body.freeze = true
		body.visible = false
		add_child(body)
		_pearl_bodies.append(body)
		_pearl_start.append(pos)


func _set_pearls_active(active: bool) -> void:
	for i in _pearl_bodies.size():
		var b: RigidBody3D = _pearl_bodies[i]
		if active and not b.visible:
			b.position = _pearl_start[i]
			b.linear_velocity = Vector3.ZERO
		b.visible = active
		b.freeze = not active


func _build_liquid() -> void:
	_liquid = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 24
	_liquid.mesh = mesh
	var sh := Shader.new()
	sh.code = LIQUID_SHADER
	_liq_mat = ShaderMaterial.new()
	_liq_mat.shader = sh
	_liquid.set_surface_override_material(0, _liq_mat)
	_wob.add_child(_liquid)


func _radius_at(h: float) -> float:
	return R_BOTTOM + (h / CUP_H) * (R_TOP - R_BOTTOM)


func update_cup(base: Variant, milk: Variant, tops: Array, sugar: Variant,
		shake_ratio: float, sealed: bool) -> void:
	if base == null:
		clear_cup()
		return
	var tea_h: float = 0.075 + 0.008 * tops.size()
	var has_milk: bool = milk != null and String(milk.get("color", "")) != ""
	var milk_h: float = 0.035 if has_milk else 0.0
	var total_h: float = tea_h + milk_h

	var tea_c := Color.html(base["color"])
	var has_tiger := false
	for t in tops:
		tea_c = tea_c.lerp(Color.html(t["color"]), 0.22)
		if "caramel" in t["tags"]:
			has_tiger = true
	if sugar != null:
		tea_c = tea_c.darkened(float(sugar["value"]) / 100.0 * 0.12)
	var milk_c := Color.html(milk["color"]) if has_milk else tea_c
	var blend := tea_c.lerp(milk_c, 0.5)
	tea_c = tea_c.lerp(blend, shake_ratio * 0.55)
	milk_c = milk_c.lerp(blend, shake_ratio * 0.55)

	var mesh: CylinderMesh = _liquid.mesh
	mesh.height = total_h
	mesh.bottom_radius = _radius_at(0.004)
	mesh.top_radius = _radius_at(0.004 + total_h)
	_liquid.position = Vector3(0, 0.004 + total_h / 2.0, 0)
	_liq_mat.set_shader_parameter("tea_color", tea_c)
	_liq_mat.set_shader_parameter("milk_color", milk_c)
	_liq_mat.set_shader_parameter("milk_line", (tea_h / total_h) if has_milk else 1.1)
	_liq_mat.set_shader_parameter("blend_soft", 0.03 + shake_ratio * 0.45)
	_liq_mat.set_shader_parameter("tiger", 0.9 if has_tiger else 0.0)
	_liq_mat.set_shader_parameter("half_h", total_h / 2.0)
	_liquid.visible = true

	var chewy: Variant = null
	for t in tops:
		if int(t["flavor"]["chew"]) >= 2:
			chewy = t
			break
	_set_pearls_active(chewy != null)
	if chewy != null and _pearl_mat:
		_pearl_mat.albedo_color = Color.html(chewy["color"])

	for part in _straw_parts:
		part.visible = sealed
	for part in _film_parts:
		part.visible = sealed


func clear_cup() -> void:
	_liquid.visible = false
	_set_pearls_active(false)
	for part in _straw_parts:
		part.visible = false
	for part in _film_parts:
		part.visible = false


func play_shake() -> void:
	if GameState.reduced_motion():
		_wob.rotation = Vector3.ZERO
		return
	for b in _pearl_bodies:
		if b.visible:
			b.apply_central_impulse(Vector3(
				randf_range(-1.0, 1.0), randf_range(0.6, 1.4), randf_range(-1.0, 1.0)) * 0.0007)
	if _shake_tw and _shake_tw.is_valid():
		_shake_tw.kill()
	_wob.rotation = Vector3.ZERO
	_shake_tw = create_tween()
	_shake_tw.tween_property(_wob, "rotation:z", 0.18, 0.05)
	_shake_tw.tween_property(_wob, "rotation:z", -0.15, 0.09)
	_shake_tw.tween_property(_wob, "rotation:z", 0.0, 0.08)


func play_serve() -> void:
	if GameState.reduced_motion():
		_wob.scale = Vector3.ONE
		return
	var tw := create_tween()
	tw.tween_property(_wob, "scale", Vector3(1.15, 0.9, 1.15), 0.08)
	tw.tween_property(_wob, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)
