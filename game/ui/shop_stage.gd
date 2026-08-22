## 白天全屏 3D 舞台：店铺世界 + 可点击原料道具 + 顾客进出场 + 台面工作杯
## “世界即界面”：原料罐/茶壶本身就是按钮（物理拾取），屏幕级 UI 只留 HUD
extends SubViewportContainer

signal ingredient_clicked(kind: String, item: Dictionary)
signal cup_clicked
signal staff_clicked

const CupRigScene := preload("res://ui/cup_rig.gd")
const CUSTOMER_MODELS: Array[PackedScene] = [
	preload("res://assets/glb/customer.glb"),
	preload("res://assets/glb/customer_bob.glb"),
	preload("res://assets/glb/customer_cap.glb"),
	preload("res://assets/glb/customer_buns.glb"),
]
const SPECIAL_CUSTOMER_MODELS: Dictionary = {
	"critic": preload("res://assets/glb/customer_critic.glb"),
	"influencer": preload("res://assets/glb/customer_influencer.glb"),
	"group": preload("res://assets/glb/customer_group.glb"),
}
const DEFAULT_STAFF_MODEL := preload("res://assets/glb/staff_barista.glb")
const STAFF_MODELS: Dictionary = {
	"xiaoman": preload("res://assets/glb/staff_xiaoman.glb"),
	"taozi": preload("res://assets/glb/staff_taozi.glb"),
	"acheng": preload("res://assets/glb/staff_acheng.glb"),
}
const ROUTE_SIGN_MODELS: Dictionary = {
	"rush": preload("res://assets/glb/props/routes/route_rush.glb"),
	"precision": preload("res://assets/glb/props/routes/route_precision.glb"),
	"trend": preload("res://assets/glb/props/routes/route_trend.glb"),
}

const COUNTER_TOP_Y := 0.985
const CUP_SPOT := Vector3(0.14, 0.985, 1.02)
# 柜台前横向错位排队：侧前方镜头下顾客站在台前走廊左段，越靠前越近，
# 与左侧订单卡列对齐但保留间距；三人都保留完整轮廓。
const QUEUE_SLOTS := [Vector3(-1.30, 0, 1.22), Vector3(-0.82, 0, 1.32), Vector3(-0.34, 0, 1.42)]
const PROP_SCALE := 1.25
const STAFF_SPOT := Vector3(1.62, 0.80, 0.10)
const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
# 糖泵瓶色梯度（无糖→全糖：白→珊瑚，对齐参考图）
const PUMP_COLORS := [Color("FFFFFF"), Color("EDEBD7"), Color("F5DEC9"), Color("F2A69B"), Color("FF6259")]

var cup: Node3D                     # CupRig，玩法层直接调用 update_cup 等
var _vp: SubViewport
var _cam: Camera3D
var _props_root: Node3D
var _prop_nodes: Dictionary = {}    # item_id -> 道具根节点（选中态抬升用）
var _sugar_key := ""
var _font: FontFile
var _staff_actor: Node3D
var _staff_bob: Node3D
var _customer_variant_serial := 0
var _upgrade_visuals: Dictionary = {}
var _route_sign: Node3D
var _route_sign_base_scale := Vector3.ONE * 0.68
var _route_sign_tween: Tween
var _active_prop_kind := ""
var _prop_hint_sources: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.size = Vector2i(1280, 720)
	_vp.physics_object_picking = true
	add_child(_vp)
	_font = load("res://assets/fonts/LXGWWenKai-Regular.ttf")
	GameLocale.locale_changed.connect(_on_locale_changed)

	# 店铺模型（旧设备已在 Blender 源文件中移除，后场陈设为建模内容）
	var model: Node3D = (load("res://assets/glb/shop_scene.glb") as PackedScene).instantiate()
	_vp.add_child(model)
	_build_route_sign()

	# 方案 3：更俯视、更宽的空间站点构图，顾客在左、制杯垫居中、原料沿后方展开。
	# Coral Mint V3：机位压低到侧前方（full-set-v3/01-day-shop.png）——
	# 柜台立面、后区原料带与顾客全身都进入画面，地板只留底部窄条。
	_cam = Camera3D.new()
	_vp.add_child(_cam)
	# 侧前方机位（full-set-v3/01-day-shop.png）：俯角 ~32°，后区原料带贴着
	# HUD 下方展开，工作台杯子落在画面竖直中段，顾客全身收进底部走廊。
	_cam.position = Vector3(0.06, 2.75, 3.85)
	_cam.look_at(Vector3(0.02, 0.70, 0.55))
	_cam.fov = 45

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -20, 0)
	sun.light_energy = 0.72
	sun.light_color = Color(1.0, 0.96, 0.90)
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.46
	sun.light_angular_distance = 1.0           # 软阴影半影（小尺度场景保留阴影存在感）
	sun.shadow_blur = 1.0
	sun.directional_shadow_max_distance = 12.0
	_vp.add_child(sun)
	var warm := OmniLight3D.new()
	warm.position = Vector3(0, 2.1, 0.8)
	warm.omni_range = 7.0
	warm.light_energy = 0.18
	warm.light_color = Color(1.0, 0.94, 0.88)
	_vp.add_child(warm)
	# 薄荷反杈补光：抬亮暖色阴影，呼应珊瑚薄荷色板
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.6, 1.6, 2.0)
	fill.omni_range = 6.0
	fill.light_energy = 0.14
	fill.light_color = Color(0.82, 0.95, 0.92)
	_vp.add_child(fill)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.57, 0.53, 0.49)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.36, 0.35)
	env.ambient_light_energy = 0.46
	# Steam 品质基线：ACES + SSAO 接触阴影 + 克制的 Glow；色彩矫正抑制 ACES 去饱和
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 4.0
	env.adjustment_enabled = true
	env.adjustment_brightness = 0.84
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.10
	# Forward Mobile does not implement SSAO; setting it there only emits a warning.
	# Keep the authored effect on desktop and let the mobile ambient/fill rig carry depth.
	env.ssao_enabled = RenderingServer.get_current_rendering_method() != "mobile"
	env.ssao_intensity = 1.35
	env.ssao_radius = 0.5
	env.ssao_power = 1.8
	env.glow_enabled = true
	env.glow_intensity = 0.14
	env.glow_bloom = 0.015
	env.glow_hdr_threshold = 1.25
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)

	# 台面工作杯是视觉中心；俯视镜头下略放大保证液体分层仍然清楚。
	cup = CupRigScene.new()
	cup.position = CUP_SPOT
	cup.scale = Vector3(2.20, 2.20, 2.20)
	_vp.add_child(cup)
	var cup_hit := StaticBody3D.new()
	cup_hit.position = CUP_SPOT + Vector3(0, 0.14, 0)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.1
	cyl.height = 0.3
	cs.shape = cyl
	cup_hit.add_child(cs)
	cup_hit.input_event.connect(func(_c, ev, _p, _n, _s):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			cup_clicked.emit())
	_vp.add_child(cup_hit)

	_props_root = Node3D.new()
	_vp.add_child(_props_root)
	_build_dressing()


## 新店+路线进入实体店铺：独立浮雕只加载当前路线，首周目保持原场景。
func _build_route_sign() -> void:
	var route_id := LegacyRoutes.active_id()
	var scene: PackedScene = ROUTE_SIGN_MODELS.get(route_id)
	if scene == null:
		return
	_route_sign = scene.instantiate()
	_route_sign.name = "RouteSign_%s" % route_id
	_route_sign.position = Vector3(-0.30, 1.02, 1.23)
	_route_sign.scale = _route_sign_base_scale
	_route_sign.set_meta("route_id", route_id)
	_disable_small_prop_shadows_on_mobile(_route_sign)
	_vp.add_child(_route_sign)


func get_route_sign() -> Node3D:
	return _route_sign


## 路线加成不只写进 HUD：实体店招在实际发放路线金币时轻微响应。
## 减弱动态模式完全跳过位移动画，并恢复稳定基准比例。
func pulse_route_sign() -> bool:
	if not is_instance_valid(_route_sign):
		return false
	if _route_sign_tween != null and _route_sign_tween.is_valid():
		_route_sign_tween.kill()
	_route_sign.scale = _route_sign_base_scale
	if GameState.reduced_motion():
		return false
	_route_sign_tween = _route_sign.create_tween()
	_route_sign_tween.tween_property(_route_sign, "scale", _route_sign_base_scale * 1.10, 0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_route_sign_tween.tween_property(_route_sign, "scale", _route_sign_base_scale, 0.16) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return true


## 静态陈设与成长可视化：升级不只改数值，也会在下一次营业出现在店里。
func _build_dressing() -> void:
	_upgrade_visuals.clear()
	var shaker_level := UpgradeCatalog.level("shaker")
	var dressing := [
		["prep_mat.glb", Vector3(0.14, 0.982, 1.02), 1.5],
		["pickup_tray.glb", Vector3(1.50, 0.982, 1.05), 1.2],
		["service_bell.glb", Vector3(1.84, 0.982, 0.95), 1.4],
	]
	for d in dressing:
		var node := _load_prop(d[0])
		node.position = d[1]
		node.scale = Vector3.ONE * d[2]
		_vp.add_child(node)
	if shaker_level > 0:
		_add_upgrade_visual("shaker", "auto_shaker.glb", shaker_level,
			Vector3(1.92, 0.982, 0.55), 0.72)
	else:
		var manual_shaker := _load_prop("shaker.glb")
		manual_shaker.name = "ManualShaker"
		# 摇匀站在糖泵右侧、同一条原料带上（参考图最右站点），不再占用操作台。
		manual_shaker.position = Vector3(1.78, 0.982, 0.22)
		manual_shaker.scale = Vector3.ONE * 1.1
		_vp.add_child(manual_shaker)
	var comfort_level := UpgradeCatalog.level("comfort")
	if comfort_level > 0:
		var comfort := _add_upgrade_visual("comfort", "comfort.glb", comfort_level,
			Vector3(-1.72, 0.01, 1.58), 0.58)
		comfort.rotation_degrees.y = -12.0
	if UpgradeCatalog.auto_sugar_after_milk():
		_add_upgrade_visual("smart_sugar", "smart_sugar.glb", 1,
			Vector3(1.49, 0.985, 0.48), 0.72)
	var tip_level := UpgradeCatalog.level("tip_jar")
	if tip_level > 0:
		_add_upgrade_visual("tip_jar", "tip_jar.glb", tip_level,
			Vector3(1.70, 0.982, 0.76), 0.66)


func _add_upgrade_visual(id: String, filename: String, level: int,
		position: Vector3, scale_value: float) -> Node3D:
	var scene := load("res://assets/glb/props/upgrades/" + filename) as PackedScene
	var node := scene.instantiate()
	node.name = "Upgrade_%s" % id
	node.position = position
	node.scale = Vector3.ONE * scale_value
	node.set_meta("upgrade_id", id)
	node.set_meta("upgrade_level", level)
	_set_upgrade_visual_level(node, level)
	_disable_small_prop_shadows_on_mobile(node)
	_upgrade_visuals[id] = node
	_vp.add_child(node)
	return node


func _set_upgrade_visual_level(root: Node, level: int) -> void:
	if root is VisualInstance3D:
		var node_name := String(root.name)
		if node_name.begins_with("L2_"):
			root.visible = level >= 2
		elif node_name.begins_with("L3_"):
			root.visible = level >= 3
	for child in root.get_children():
		_set_upgrade_visual_level(child, level)


func get_upgrade_visual(id: String) -> Node3D:
	return _upgrade_visuals.get(id) as Node3D


# ---------------------------------------------------------------- 可点击原料道具

func build_props(day: int, sugar_item: Dictionary) -> void:
	for c in _props_root.get_children():
		c.queue_free()
	_prop_nodes.clear()
	# 旧道具销毁后不会再发 mouse_exited；清掉悬停来源，避免残留 id 影响新一天的世界标签。
	_prop_hint_sources.clear()

	var teas := GameData.unlocked(GameData.bases, day)
	for i in teas.size():
		_add_prop(_make_kettle(teas[i]), teas[i], "base",
			Vector3(-0.96 + i * 0.48, COUNTER_TOP_Y, 0.12), 0.36)
	var milks := GameData.unlocked(GameData.milks, day)
	for i in milks.size():
		_add_prop(_make_milk(milks[i]), milks[i], "milk",
			Vector3(0.08 + i * 0.30, COUNTER_TOP_Y, 0.12), 0.34)
		var milk_lbl: Label3D = _prop_nodes[milks[i]["id"]].get_node("NameLabel")
		milk_lbl.font_size = 28
	var tops := GameData.unlocked(GameData.toppings, day)
	for i in tops.size():
		# 后期最多 8 罐：容器压缩间距避开糖泵区；标签改为单项焦点提示后，
		# 直接落在罐体正面，不再上浮到后排茶壶轮廓里。
		_add_prop(_make_bin(tops[i]), tops[i], "topping",
			Vector3(-0.95 + i * 0.24, COUNTER_TOP_Y, 0.48), 0.03)
		var bin_lbl: Label3D = _prop_nodes[tops[i]["id"]].get_node("NameLabel")
		bin_lbl.font_size = 34
	# 智能糖控启用后糖度会自动匹配；移除五个手动泵，避免视觉冗余和错误交互暗示。
	if not UpgradeCatalog.auto_sugar_after_milk():
		for i in GameData.sugar_levels.size():
			var lv: Dictionary = GameData.sugar_levels[i].duplicate()
			lv["id"] = "sugar_%d" % int(lv["value"])
			lv["name"] = _short_sugar_name(String(lv["name"]))
			var pump := _load_prop("sugar_pump.glb", PUMP_COLORS[mini(i, PUMP_COLORS.size() - 1)])
			_add_prop(pump, lv, "sugar",
				Vector3(1.02 + i * 0.18, COUNTER_TOP_Y, 0.52), 0.26)
			var pump_lbl: Label3D = _prop_nodes[lv["id"]].get_node("NameLabel")
			pump_lbl.font_size = 26
	set_sugar_label(sugar_item)


func _short_sugar_name(name: String) -> String:
	return name.replace("三分糖", "3分").replace("五分糖", "5分") \
		.replace("七分糖", "7分")


func _add_prop(root: Node3D, item: Dictionary, kind: String, pos: Vector3, label_y := 0.30) -> void:
	root.position = pos
	root.scale = Vector3(PROP_SCALE, PROP_SCALE, PROP_SCALE)
	root.set_meta("ingredient_kind", kind)
	root.set_meta("ingredient_item", item.duplicate(true))
	_props_root.add_child(root)
	_prop_nodes[String(item.get("id", kind))] = root
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.11
	shape.height = 0.3
	cs.shape = shape
	cs.position = Vector3(0, 0.13, 0)
	body.add_child(cs)
	root.add_child(body)
	var item_id := String(item.get("id", kind))
	body.input_event.connect(func(_c, ev, _p, _n, _s):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_bounce(root)
			ingredient_clicked.emit(kind, item))
	body.mouse_entered.connect(set_prop_hint.bind(item_id, "world_hover"))
	body.mouse_exited.connect(clear_prop_hint.bind(item_id, "world_hover"))
	# 名称标签
	var lbl := Label3D.new()
	lbl.name = "NameLabel"
	lbl.text = GameLocale.ingredient_short_name(item)
	lbl.font = _font
	lbl.font_size = 36
	lbl.pixel_size = 0.00115
	lbl.position = Vector3(0, label_y, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# A focused hint must remain legible above the prop it describes. Screen-space
	# Control UI still draws later, so this cannot leak through the context panel.
	lbl.no_depth_test = true
	lbl.modulate = Color(0.30, 0.19, 0.11)
	lbl.outline_size = 7
	lbl.outline_modulate = Color(0.99, 0.96, 0.90, 0.9)
	lbl.visible = false
	root.add_child(lbl)


## 世界标签只提示当前悬停/手柄焦点。上下文面板负责完整清单，避免同一组
## 名称同时出现在屏幕按钮、茶壶和小料罐上，也不再让远处标签被 HUD 截断。
func set_active_prop_kind(kind: String) -> void:
	_active_prop_kind = kind
	_prop_hint_sources.clear()
	_refresh_prop_labels()


func set_prop_hint(item_id: String, source := "manual") -> void:
	var root := _prop_nodes.get(item_id) as Node3D
	if root == null or String(root.get_meta("ingredient_kind", "")) != _active_prop_kind:
		return
	_prop_hint_sources[source] = item_id
	_refresh_prop_labels()


func clear_prop_hint(item_id := "", source := "manual") -> void:
	if not _prop_hint_sources.has(source):
		return
	if not item_id.is_empty() and String(_prop_hint_sources[source]) != item_id:
		return
	_prop_hint_sources.erase(source)
	_refresh_prop_labels()


func _refresh_prop_labels() -> void:
	var target_id := ""
	for source in ["button_focus", "button_hover", "world_hover", "manual"]:
		if _prop_hint_sources.has(source):
			target_id = String(_prop_hint_sources[source])
			break
	for root in _props_root.get_children():
		var lbl := root.get_node_or_null("NameLabel") as Label3D
		if lbl:
			var item: Dictionary = root.get_meta("ingredient_item", {})
			lbl.visible = not target_id.is_empty() \
				and String(root.get_meta("ingredient_kind", "")) == _active_prop_kind \
				and String(item.get("id", "")) == target_id


func visible_prop_label_ids() -> Array[String]:
	var result: Array[String] = []
	for root in _props_root.get_children():
		var lbl := root.get_node_or_null("NameLabel") as Label3D
		if lbl != null and lbl.visible:
			var item: Dictionary = root.get_meta("ingredient_item", {})
			result.append(String(item.get("id", "")))
	return result


func _on_locale_changed(_locale: String) -> void:
	for root in _props_root.get_children():
		var lbl := root.get_node_or_null("NameLabel") as Label3D
		var item: Variant = root.get_meta("ingredient_item", {})
		if lbl != null and item is Dictionary:
			lbl.text = GameLocale.ingredient_short_name(item)


func _mat(color: Color, rough := 0.5, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.roughness = rough
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _mesh(root: Node3D, mesh: Mesh, mat: StandardMaterial3D, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	root.add_child(mi)


## 从道具库加载 GLB，并对 Tint 命名部件染色（数据驱动换色）
func _load_prop(fname: String, tint := Color.TRANSPARENT) -> Node3D:
	var node: Node3D = (load("res://assets/glb/props/" + fname) as PackedScene).instantiate()
	if tint.a > 0.0:
		for child in node.get_children():
			if child is MeshInstance3D and String(child.name).begins_with("Tint"):
				var m: StandardMaterial3D = child.get_active_material(0).duplicate()
				m.albedo_color = tint
				child.set_surface_override_material(0, m)
	_disable_small_prop_shadows_on_mobile(node)
	return node


## Small counter props already receive baked/ambient contact shading. On Forward
## Mobile, submitting every one to the directional shadow pass nearly doubles the
## draw count; keep structural shop/customer/cup shadows and skip only these props.
func _disable_small_prop_shadows_on_mobile(root: Node) -> void:
	if RenderingServer.get_current_rendering_method() != "mobile":
		return
	if root is GeometryInstance3D:
		root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in root.get_children():
		_disable_small_prop_shadows_on_mobile(child)


func _make_kettle(item: Dictionary) -> Node3D:
	return _load_prop("kettle.glb", Color.html(item["color"]))


func _make_milk(item: Dictionary) -> Node3D:
	var col_s := String(item.get("color", ""))
	var tint := Color.html(col_s) if col_s != "" else Color(0.75, 0.85, 0.88)
	return _load_prop("milk_carton.glb", tint)


func _make_bin(item: Dictionary) -> Node3D:
	return _load_prop("topping_bin.glb", Color.html(item["color"]))


## 糖泵选中态：抬起当前档，其余归位
func set_sugar_label(sugar_item: Dictionary) -> void:
	var sel := "sugar_%d" % int(sugar_item.get("value", -1))
	for key in _prop_nodes:
		if String(key).begins_with("sugar_"):
			set_prop_selected(key, key == sel)


## 小料选中态：抬升
func set_prop_selected(item_id: String, selected: bool) -> void:
	var root: Node3D = _prop_nodes.get(item_id)
	if root:
		if GameState.reduced_motion():
			root.position.y = COUNTER_TOP_Y + (0.045 if selected else 0.0)
			return
		var tw := create_tween()
		tw.tween_property(root, "position:y",
			COUNTER_TOP_Y + (0.045 if selected else 0.0), 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _bounce(root: Node3D) -> void:
	if GameState.reduced_motion():
		return
	var tw := create_tween()
	tw.tween_property(root, "scale",
		Vector3(PROP_SCALE * 1.12, PROP_SCALE * 0.92, PROP_SCALE * 1.12), 0.06)
	tw.tween_property(root, "scale", Vector3.ONE * PROP_SCALE, 0.14) \
		.set_trans(Tween.TRANS_BOUNCE)


# ---------------------------------------------------------------- 店员角色

func add_staff(staff_id := "") -> Node3D:
	remove_staff()
	var staff_key := staff_id if STAFF_MODELS.has(staff_id) else "generic"
	var model_scene: PackedScene = STAFF_MODELS[staff_key] if staff_key != "generic" else DEFAULT_STAFF_MODEL
	var model: Node3D = model_scene.instantiate()
	_staff_actor = Node3D.new()
	_staff_actor.name = "StaffActor"
	_staff_actor.set_meta("staff_model", staff_key)
	_staff_actor.position = STAFF_SPOT
	_staff_actor.scale = Vector3.ONE * 0.92
	_staff_bob = Node3D.new()
	_staff_bob.name = "StaffBob"
	_staff_actor.add_child(_staff_bob)
	_staff_bob.add_child(model)
	_vp.add_child(_staff_actor)
	var hit := StaticBody3D.new()
	var shape_node := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.24
	shape.height = 0.72
	shape_node.shape = shape
	shape_node.position = Vector3(0, 0.25, 0)
	hit.add_child(shape_node)
	hit.input_event.connect(func(_c, ev, _p, _n, _s):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			staff_clicked.emit())
	_staff_actor.add_child(hit)
	if not GameState.reduced_motion():
		var bob := _staff_bob.create_tween().set_loops()
		bob.tween_property(_staff_bob, "position:y", 0.018, 1.1).set_trans(Tween.TRANS_SINE)
		bob.tween_property(_staff_bob, "position:y", 0.0, 1.1).set_trans(Tween.TRANS_SINE)
	return _staff_actor


func set_staff_state(state: String) -> void:
	if not is_instance_valid(_staff_actor):
		return
	var target_y := STAFF_SPOT.y - (0.11 if state == "idle" else 0.0)
	var target_z := -11.0 if state == "idle" else 0.0
	if GameState.reduced_motion():
		_staff_actor.position.y = target_y
		_staff_actor.rotation_degrees.z = target_z
		return
	var tween := _staff_actor.create_tween().set_parallel(true)
	tween.tween_property(_staff_actor, "position:y", target_y, 0.22).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_staff_actor, "rotation_degrees:z", target_z, 0.22).set_trans(Tween.TRANS_SINE)


func remove_staff() -> void:
	if is_instance_valid(_staff_actor):
		_staff_actor.queue_free()
	_staff_actor = null
	_staff_bob = null


# ---------------------------------------------------------------- 顾客进出场

func add_customer(slot: int, tint: Color, kind := "regular") -> Node3D:
	# Gameplay-significant visitors use authored silhouettes. Regular visitors keep a
	# stable rotation, and specials do not disturb that sequence.
	var kind_key := kind if SPECIAL_CUSTOMER_MODELS.has(kind) else "regular"
	var variant_index := -1
	var model_scene: PackedScene
	if kind_key == "regular":
		variant_index = _customer_variant_serial % CUSTOMER_MODELS.size()
		_customer_variant_serial += 1
		model_scene = CUSTOMER_MODELS[variant_index]
	else:
		model_scene = SPECIAL_CUSTOMER_MODELS[kind_key]
	var model: Node3D = model_scene.instantiate()
	var actor := Node3D.new()
	actor.name = "CustomerActor"
	actor.set_meta("model_variant", variant_index)
	actor.set_meta("customer_kind", kind_key)
	actor.set_meta("special_model", kind_key if kind_key != "regular" else "")
	var bob_root := Node3D.new()
	bob_root.name = "BobRoot"
	var gesture_root := Node3D.new()
	gesture_root.name = "GestureRoot"
	actor.add_child(bob_root)
	bob_root.add_child(gesture_root)
	gesture_root.add_child(model)
	var cloth: StandardMaterial3D = null
	var hair_mat: StandardMaterial3D = null
	for child in model.get_children():
		if child is MeshInstance3D:
			var n := String(child.name)
			if n.begins_with("Body") or n.begins_with("Arm"):
				if cloth == null:
					cloth = child.get_active_material(0).duplicate()
					cloth.albedo_color = tint
				child.set_surface_override_material(0, cloth)
			elif n.begins_with("Hair") and kind_key == "regular":
				if hair_mat == null:
					hair_mat = child.get_active_material(0).duplicate()
					hair_mat.albedo_color = Color(0.22, 0.15, 0.12).lerp(Color(0.55, 0.4, 0.28), randf())
				child.set_surface_override_material(0, hair_mat)
	var target: Vector3 = QUEUE_SLOTS[clampi(slot, 0, QUEUE_SLOTS.size() - 1)]
	actor.position = target + Vector3(-1.6, 0, 0)
	var actor_scale := 0.67 if kind_key == "group" else 0.62
	actor.scale = Vector3.ONE * actor_scale   # 双人组合略放大，仍守住队列槽宽。
	_vp.add_child(actor)
	if GameState.reduced_motion():
		actor.position = target
		return actor

	# 行走、呼吸、张望、小跳分属不同父节点，避免多个 Tween 争夺同一个属性。
	var walk := actor.create_tween()
	walk.tween_property(actor, "position", target, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var bob := bob_root.create_tween().set_loops()
	var dur := randf_range(0.9, 1.3)
	bob.tween_property(bob_root, "position:y", 0.018, dur) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(bob_root, "position:y", 0.0, dur) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var look := gesture_root.create_tween().set_loops()
	look.tween_interval(randf_range(1.0, 2.3))
	look.tween_property(gesture_root, "rotation_degrees:y", randf_range(-12.0, -6.0), 0.45) \
		.set_trans(Tween.TRANS_SINE)
	look.tween_interval(randf_range(0.5, 1.2))
	look.tween_property(gesture_root, "rotation_degrees:y", randf_range(6.0, 12.0), 0.55) \
		.set_trans(Tween.TRANS_SINE)
	look.tween_property(gesture_root, "rotation_degrees:y", 0.0, 0.35) \
		.set_trans(Tween.TRANS_SINE)
	var hop := gesture_root.create_tween().set_loops()
	hop.tween_interval(randf_range(2.8, 5.0))
	hop.tween_property(gesture_root, "position:y", 0.045, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(gesture_root, "position:y", 0.0, 0.16) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	return actor


func remove_customer(actor: Node3D, served := false) -> void:
	if not is_instance_valid(actor):
		return
	if GameState.reduced_motion():
		actor.queue_free()
		return
	var tw := actor.create_tween()
	if served:
		# 正确出杯：先走向右侧取餐牌，再从右侧离场，强化“完成交付”的空间叙事。
		var pickup := Vector3(1.62, 0.0, 1.02)
		tw.set_parallel(true)
		tw.tween_property(actor, "position", pickup, 0.72) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(actor, "rotation_degrees:y", -55.0, 0.35)
		tw.set_parallel(false)
		tw.tween_interval(0.08)
		tw.tween_property(actor, "position:x", pickup.x + 1.25, 0.42) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		# 等太久或日终清场：沿来路离开。
		tw.tween_property(actor, "position:x", actor.position.x - 1.8, 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(actor.queue_free)


## 世界坐标 → 屏幕坐标（订单气泡/摇茶条跟随用）
func screen_pos(world: Vector3) -> Vector2:
	return _cam.unproject_position(world)


func cup_screen_pos() -> Vector2:
	return _cam.unproject_position(CUP_SPOT + Vector3(0, 0.42, 0))
