## 移动端渲染预算：Day 10 满升级、三顾客压力场景。
## 可视运行：PERF_CAPTURE=1 PERF_OUTPUT=/absolute/path.png Godot --rendering-method mobile ...
extends Node

const DAY := 10
const MAX_VISIBLE_TRIANGLES := 120_000
const MAX_VISIBLE_SURFACES := 200
const MAX_VISIBLE_MESHES := 200
const MAX_SHADOW_LIGHTS := 1
const MAX_MOBILE_DRAW_CALLS := 360
const MAX_VIDEO_MEMORY_BYTES := 160 * 1024 * 1024

var _shop: Control


func _ready() -> void:
	GameState.test_mode = true
	GameState.menu = []
	GameState.featured_menu = []
	GameState.day = DAY
	GameState.settings = {"sfx_volume": 0.0, "music_volume": 0.0, "reduced_motion": true}
	GameState.upgrades = {"comfort": 3, "shaker": 3, "smart_sugar": 1, "tip_jar": 3}
	GameState.staff = {}
	GameState.new_shop_route = "trend"
	_shop = load("res://scenes/day_shop/day_shop.tscn").instantiate()
	add_child(_shop)
	await get_tree().process_frame
	while _shop.customers.size() < 3:
		_shop._spawn_customer()
	_shop.running = false

	# Let imported meshes, labels and the SubViewport settle before counting/sampling.
	for _frame in 90:
		await get_tree().process_frame
	var static_metrics := _measure_tree(_shop.stage._vp)
	var frame_metrics := await _measure_frames(60)
	var renderer := RenderingServer.get_current_rendering_method()
	print("[MOBILE_RENDER] renderer=%s meshes=%d surfaces=%d triangles=%d lights=%d shadow_lights=%d subviewports=%d draw_calls_max=%d primitives_max=%d process_ms_avg=%.3f video_mem_mib=%.2f" % [
		renderer,
		static_metrics["meshes"], static_metrics["surfaces"], static_metrics["triangles"],
		static_metrics["lights"], static_metrics["shadow_lights"], _count_type(_shop, SubViewport),
		frame_metrics["draw_calls"], frame_metrics["primitives"], frame_metrics["process_ms"],
		float(frame_metrics["video_mem"]) / 1048576.0,
	])
	for line in _subtree_breakdown(_shop.stage._vp):
		print("[MOBILE_RENDER_PART] ", line)

	var failures: Array[String] = []
	var hud_labels := {
		"day": _shop.hud_day,
		"coins": _shop.hud_coin,
		"inspiration": _shop.hud_insp,
		"event": _shop.hud_event,
	}
	for label_name in hud_labels:
		var label: Label = hud_labels[label_name]
		print("[MOBILE_HUD] %s text='%s' size=%s pos=%s" % [
			label_name, label.text, label.size, label.global_position])
		if label.text.is_empty() or label.size.x < 12.0:
			failures.append("collapsed HUD label: %s width=%.1f" % [label_name, label.size.x])
	if _shop.hud_status.global_position.x + _shop.hud_status.size.x > 432.0:
		failures.append("status HUD overlaps the preparation panel")
	var portrait_visible_bounds := {}
	for customer in _shop.customers:
		var portrait := customer["portrait"] as Sprite2D
		var alpha_rect := _visible_alpha_rect(portrait.texture)
		portrait_visible_bounds[int(customer["slot"])] = Vector2(
			portrait.position.y + (alpha_rect.position.y - portrait.texture.get_height() * 0.5) * portrait.scale.y,
			portrait.position.y + (alpha_rect.end.y - portrait.texture.get_height() * 0.5) * portrait.scale.y)
		var portrait_bottom: float = portrait_visible_bounds[int(customer["slot"])].y
		if portrait_bottom > 720.0:
			failures.append("customer portrait leaves authored frame: slot=%d bottom=%.1f" % [
				int(customer["slot"]), portrait_bottom])
	if portrait_visible_bounds.has(1) and portrait_visible_bounds.has(2):
		var rear_overlap: float = maxf(0.0,
			portrait_visible_bounds[1].y - portrait_visible_bounds[2].x)
		if rear_overlap > 30.0:
			failures.append("rear customer obscures second portrait: overlap=%.1f" % rear_overlap)
	if int(static_metrics["triangles"]) > MAX_VISIBLE_TRIANGLES:
		failures.append("visible triangle budget exceeded: %d" % static_metrics["triangles"])
	if int(static_metrics["surfaces"]) > MAX_VISIBLE_SURFACES:
		failures.append("visible surface budget exceeded: %d" % static_metrics["surfaces"])
	if int(static_metrics["meshes"]) > MAX_VISIBLE_MESHES:
		failures.append("visible mesh budget exceeded: %d" % static_metrics["meshes"])
	if int(static_metrics["shadow_lights"]) > MAX_SHADOW_LIGHTS:
		failures.append("too many shadow-casting lights: %d" % static_metrics["shadow_lights"])
	if renderer == "mobile" and int(frame_metrics["draw_calls"]) > 0 \
			and int(frame_metrics["draw_calls"]) > MAX_MOBILE_DRAW_CALLS:
		failures.append("mobile draw-call budget exceeded: %d" % frame_metrics["draw_calls"])
	if int(frame_metrics["video_mem"]) > MAX_VIDEO_MEMORY_BYTES:
		failures.append("video-memory budget exceeded: %.2f MiB" % (float(frame_metrics["video_mem"]) / 1048576.0))

	var output := OS.get_environment("PERF_OUTPUT")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output.get_base_dir())
		get_viewport().get_texture().get_image().save_png(output)
		print("[MOBILE_RENDER] screenshot=", output)

	var enforce := OS.get_environment("PERF_ENFORCE") != "0"
	if failures.is_empty():
		print("[MOBILE_RENDER] passed day=10 customers=3 upgrades=10 static_budget=true")
	else:
		for failure in failures:
			push_error(failure)
		print("[MOBILE_RENDER] over_budget=", failures)
	Sfx.stop_all()
	_shop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(1 if enforce and not failures.is_empty() else 0)


func _visible_alpha_rect(texture: Texture2D) -> Rect2i:
	var image := texture.get_image()
	var first := Vector2i(image.get_width(), image.get_height())
	var last := Vector2i.ZERO
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 16.0 / 255.0:
				continue
			first = first.min(Vector2i(x, y))
			last = last.max(Vector2i(x + 1, y + 1))
	return Rect2i(first, last - first)


func _measure_tree(root: Node) -> Dictionary:
	var metrics := {"meshes": 0, "surfaces": 0, "triangles": 0, "lights": 0, "shadow_lights": 0}
	_accumulate_tree(root, metrics)
	return metrics


func _accumulate_tree(node: Node, metrics: Dictionary) -> void:
	if node is MeshInstance3D and node.is_visible_in_tree() and node.mesh != null:
		metrics["meshes"] += 1
		metrics["surfaces"] += node.mesh.get_surface_count()
		metrics["triangles"] += _mesh_triangles(node.mesh)
	elif node is Light3D and node.visible:
		metrics["lights"] += 1
		if node.shadow_enabled:
			metrics["shadow_lights"] += 1
	for child in node.get_children():
		_accumulate_tree(child, metrics)


func _mesh_triangles(mesh: Mesh) -> int:
	var triangles := 0
	for surface in mesh.get_surface_count():
		if mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays := mesh.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if not indices.is_empty():
			triangles += indices.size() / 3
		else:
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			triangles += vertices.size() / 3
	return triangles


func _measure_frames(frame_count: int) -> Dictionary:
	var result := {"draw_calls": 0, "primitives": 0, "process_ms": 0.0, "video_mem": 0}
	for _frame in frame_count:
		await get_tree().process_frame
		result["draw_calls"] = maxi(int(result["draw_calls"]), int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		result["primitives"] = maxi(int(result["primitives"]), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		result["process_ms"] += float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
		result["video_mem"] = maxi(int(result["video_mem"]), int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))
	result["process_ms"] /= float(frame_count)
	return result


func _subtree_breakdown(viewport: SubViewport) -> Array[String]:
	var rows: Array[String] = []
	for child in viewport.get_children():
		var metrics := _measure_tree(child)
		if int(metrics["meshes"]) == 0:
			continue
		rows.append("%s meshes=%d surfaces=%d triangles=%d" % [
			child.name, metrics["meshes"], metrics["surfaces"], metrics["triangles"]])
	return rows


func _count_type(root: Node, type: Variant) -> int:
	var count := 1 if is_instance_of(root, type) else 0
	for child in root.get_children():
		count += _count_type(child, type)
	return count
