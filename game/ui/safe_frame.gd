## 将 1280×720 作者界面放进系统安全区；3D 背景仍铺满完整视口。
extends Control
class_name SafeFrame

const AUTHORED_SIZE := Vector2(1280, 720)


func _ready() -> void:
	name = "SafeFrame"
	size = AUTHORED_SIZE
	custom_minimum_size = AUTHORED_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var visible_size := get_viewport_rect().size
	size = AUTHORED_SIZE
	var fitted := _fit_layout(visible_size, _logical_safe_rect(visible_size))
	scale = Vector2.ONE * float(fitted["scale"])
	position = fitted["position"]


func _logical_safe_rect(visible_size: Vector2) -> Rect2:
	var full_rect := Rect2(Vector2.ZERO, visible_size)
	if not OS.has_feature("mobile"):
		return full_rect
	var window_size := Vector2(DisplayServer.window_get_size())
	var native_safe := Rect2(DisplayServer.get_display_safe_area())
	if window_size.x <= 0.0 or window_size.y <= 0.0 \
			or native_safe.size.x <= 0.0 or native_safe.size.y <= 0.0:
		return full_rect
	var ratio := visible_size / window_size
	var logical := Rect2(native_safe.position * ratio, native_safe.size * ratio)
	return logical.intersection(full_rect)


## Kept deterministic and display-independent so cutout/home-indicator layouts
## can be guarded in the headless input suite.
func _fit_layout(visible_size: Vector2, safe_rect: Rect2) -> Dictionary:
	var full_rect := Rect2(Vector2.ZERO, visible_size)
	var usable := safe_rect.intersection(full_rect)
	if usable.size.x <= 0.0 or usable.size.y <= 0.0:
		usable = full_rect
	var fit_scale := minf(1.0, minf(usable.size.x / AUTHORED_SIZE.x,
		usable.size.y / AUTHORED_SIZE.y))
	var rendered_size := AUTHORED_SIZE * fit_scale
	return {
		"scale": fit_scale,
		"position": (usable.position + (usable.size - rendered_size) * 0.5).floor(),
	}


## Full-screen modals live inside the authored frame. This converts the real
## viewport back into that frame's local space so scrims still reach every edge
## when a phone cutout makes the frame smaller than 1×.
static func overscan_geometry(owner: Control) -> Dictionary:
	var visible_size := owner.get_viewport_rect().size
	var frame := owner.get_parent() as Control
	if frame == null:
		return {"offset": Vector2.ZERO, "size": visible_size}
	var frame_scale := maxf(frame.scale.x, 0.001)
	return {
		"offset": frame.position / frame_scale,
		"size": visible_size / frame_scale,
	}
