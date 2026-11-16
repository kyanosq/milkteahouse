## A skinned customer. Walk phase follows distance, keeping stance feet planted.
extends Node3D

const MODEL := preload("res://assets/glb/customer_walk.glb")
const SHADOW := preload("res://assets/ui/full_set_v3/illustrations/customer-contact-shadow-v1.png")
const STRIDE := 0.36
const WALK_SPEED := 0.78
const WAIT_FACING := 0.50

var appearance := 0
var departing := false
var path: Array[Vector3] = []
var speed := 0.0
var walk_phase := 0.0
var wait_time := 0.0
var animation: AnimationPlayer
var skeleton: Skeleton3D


func _ready() -> void:
	var model := MODEL.instantiate()
	add_child(model)
	animation = model.find_child("AnimationPlayer", true, false)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	var palette := {"HairMint": Color("8ABAB4"), "Lavender": Color("A296C6"),
		"Skin": Color("F6D7BD"), "Mint": Color("608F88")}
	if appearance % 2 == 1:
		palette["HairMint"] = Color("655746")
		palette["Lavender"] = Color("E7C57A")
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 2
		var material: StandardMaterial3D = ShopToon.material(mesh.get_active_material(0))
		material.disable_receive_shadows = true
		if palette.has(String(mesh.name)):
			material.albedo_color = palette[String(mesh.name)]
		mesh.material_override = material
	var shadow := Sprite3D.new()
	shadow.texture = SHADOW
	shadow.pixel_size = 0.00085
	shadow.rotation_degrees.x = -90
	shadow.position.y = 0.006
	shadow.modulate.a = 0.40
	shadow.layers = 2
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	animation.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
	_idle()


func walk_to(points: Array, delay := 0.0) -> void:
	path.assign(points)
	wait_time = delay
	if GameState.reduced_motion():
		settle()


func leave() -> void:
	departing = true
	walk_to([position + Vector3(-0.65, 0, 0.10), Vector3(-2.55, 0, 2.80)])


func settle() -> void:
	if departing:
		visible = false
		queue_free()
		return
	if not path.is_empty():
		position = path.back()
	path.clear()
	speed = 0.0
	wait_time = 0.0
	rotation.y = WAIT_FACING
	_idle()


func _idle() -> void:
	animation.speed_scale = 1.0
	animation.play("Idle", 0.12)
	if GameState.reduced_motion():
		animation.seek(0.0, true)
		animation.pause()


func _process(delta: float) -> void:
	if path.is_empty():
		if not GameState.reduced_motion():
			rotation.y = lerp_angle(rotation.y, WAIT_FACING, minf(1.0, delta * 6.0))
		return
	if wait_time > 0.0:
		wait_time -= delta
		return
	var offset := path[0] - position
	var distance := offset.length()
	if distance < 0.001:
		position = path.pop_front()
		if path.is_empty():
			speed = 0.0
			if departing:
				queue_free()
			else:
				_idle()
		return
	var desired_speed := minf(WALK_SPEED, sqrt(3.0 * distance)) if path.size() == 1 else WALK_SPEED
	speed = move_toward(speed, desired_speed, delta * 2.0)
	var step := minf(distance, speed * delta)
	position += offset / distance * step
	rotation.y = lerp_angle(rotation.y, atan2(offset.x, offset.z), minf(1.0, delta * 9.0))
	walk_phase = fmod(walk_phase + step / (STRIDE * scale.x), 1.0)
	if animation.current_animation != "Walk":
		animation.play("Walk")
	animation.speed_scale = 0.0
	animation.seek(walk_phase * animation.current_animation_length, true)
