## 摇茶体感检测器：把连续传感器/鼠标事件折叠为离散、可测试的摇动次数。
extends RefCounted
class_name ShakeGesture

const MOUSE_MIN_SPEED := 900.0
const MOUSE_HORIZONTAL_RATIO := 1.25
const MOUSE_MAX_REVERSAL_GAP_MS := 460
const MOUSE_TRIGGER_COOLDOWN_MS := 85
const ACCEL_DELTA_THRESHOLD := 7.5
const ACCEL_TRIGGER_COOLDOWN_MS := 150

var _mouse_direction := 0
var _mouse_sample_at := -100000
var _mouse_trigger_at := -100000
var _last_accel := Vector3.ZERO
var _has_accel_sample := false
var _accel_trigger_at := -100000


func sample_mouse(relative: Vector2, velocity: Vector2, now_ms: int) -> bool:
	var motion := velocity if velocity.length_squared() > 0.01 else relative * 60.0
	if absf(motion.x) < MOUSE_MIN_SPEED:
		return false
	if absf(motion.x) < absf(motion.y) * MOUSE_HORIZONTAL_RATIO:
		return false
	var direction := 1 if motion.x > 0.0 else -1
	if _mouse_direction == 0 or now_ms - _mouse_sample_at > MOUSE_MAX_REVERSAL_GAP_MS:
		_mouse_direction = direction
		_mouse_sample_at = now_ms
		return false
	_mouse_sample_at = now_ms
	if direction == _mouse_direction:
		return false
	_mouse_direction = direction
	if now_ms - _mouse_trigger_at < MOUSE_TRIGGER_COOLDOWN_MS:
		return false
	_mouse_trigger_at = now_ms
	return true


func sample_accelerometer(acceleration: Vector3, now_ms: int) -> bool:
	# Desktop builds normally report Vector3.ZERO. Treat the first real sample as
	# calibration so gravity/orientation alone never creates a free shake.
	if acceleration.length_squared() < 0.01:
		_has_accel_sample = false
		_last_accel = Vector3.ZERO
		return false
	if not _has_accel_sample:
		_has_accel_sample = true
		_last_accel = acceleration
		return false
	var impulse := (acceleration - _last_accel).length()
	_last_accel = acceleration
	if impulse < ACCEL_DELTA_THRESHOLD:
		return false
	if now_ms - _accel_trigger_at < ACCEL_TRIGGER_COOLDOWN_MS:
		return false
	_accel_trigger_at = now_ms
	return true


func reset() -> void:
	_mouse_direction = 0
	_mouse_sample_at = -100000
	_mouse_trigger_at = -100000
	_last_accel = Vector3.ZERO
	_has_accel_sample = false
	_accel_trigger_at = -100000
