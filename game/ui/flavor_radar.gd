## 五维风味雷达（mockup 02 风味反馈面板）：香气/甜度/醇厚/清爽/嚼感
## 值域按平衡带上限归一化，薄荷多边形 + 灰网格；无数据时只画网格
extends Control

const DIMS := ["aroma", "sweet", "rich", "fresh", "chew"]
const NAME_KEYS := {"aroma": "FLAVOR_AROMA", "sweet": "FLAVOR_SWEET", "rich": "FLAVOR_RICH", "fresh": "FLAVOR_FRESH", "chew": "FLAVOR_CHEW"}
const MINT := Color("27B9A7")
const MAX_V := 9.0

var values: Dictionary = {}


func _ready() -> void:
	GameLocale.locale_changed.connect(_on_locale_changed)


func set_values(v: Dictionary) -> void:
	values = v
	queue_redraw()


func _axis_dir(i: int) -> Vector2:
	var ang := -PI / 2.0 + TAU * float(i) / 5.0
	return Vector2(cos(ang), sin(ang))


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 30.0
	var grid := Color(1, 1, 1, 0.22)

	# 网格环（50% / 100%）与轴线
	for frac in [0.5, 1.0]:
		var ring: PackedVector2Array = []
		for i in 6:
			ring.append(center + _axis_dir(i % 5) * radius * frac)
		draw_polyline(ring, grid, 1.5, true)
	for i in 5:
		draw_line(center, center + _axis_dir(i) * radius, grid, 1.0)

	# 维度标签
	var font := get_theme_default_font()
	var fsize := 15
	for i in 5:
		var pos := center + _axis_dir(i) * (radius + 16.0)
		var text: String = GameLocale.text(NAME_KEYS[DIMS[i]])
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		draw_string(font, pos + Vector2(-tw / 2.0, 6), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(1, 1, 1, 0.85))

	# 数据多边形
	if values.is_empty():
		return
	var pts: PackedVector2Array = []
	for i in 5:
		var v: float = clampf(float(values.get(DIMS[i], 0)) / MAX_V, 0.04, 1.0)
		pts.append(center + _axis_dir(i) * radius * v)
	draw_colored_polygon(pts, Color(MINT.r, MINT.g, MINT.b, 0.45))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, MINT, 2.5, true)
	for p in pts:
		draw_circle(p, 3.5, Color.WHITE)


func _on_locale_changed(_locale: String) -> void:
	queue_redraw()
