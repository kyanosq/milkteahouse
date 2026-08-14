## 集中式触觉反馈：玩法只发送语义事件，由这里统一限频并路由到手机或手柄。
extends Node

const PROFILES := {
	"tap": {"duration_ms": 18, "amplitude": 0.18, "weak": 0.10, "strong": 0.0, "cooldown_ms": 42},
	"shake": {"duration_ms": 22, "amplitude": 0.22, "weak": 0.14, "strong": 0.04, "cooldown_ms": 58},
	"confirm": {"duration_ms": 46, "amplitude": 0.46, "weak": 0.26, "strong": 0.18, "cooldown_ms": 90},
	"success": {"duration_ms": 76, "amplitude": 0.66, "weak": 0.30, "strong": 0.54, "cooldown_ms": 130},
	"warning": {"duration_ms": 112, "amplitude": 0.92, "weak": 0.46, "strong": 0.82, "cooldown_ms": 180},
	"discover": {"duration_ms": 148, "amplitude": 0.78, "weak": 0.34, "strong": 0.68, "cooldown_ms": 220},
}

var test_events: Array[Dictionary] = []
var _last_at: Dictionary = {}


func play(profile_name: String) -> bool:
	if not GameState.haptics_enabled():
		return false
	var profile: Dictionary = PROFILES.get(profile_name, PROFILES["tap"])
	var now := Time.get_ticks_msec()
	var last := int(_last_at.get(profile_name, -100000))
	if now - last < int(profile["cooldown_ms"]):
		return false
	_last_at[profile_name] = now

	var joypad_id := _active_joypad()
	var route := "gamepad" if joypad_id >= 0 else "handheld"
	if GameState.test_mode:
		test_events.append({
			"profile": profile_name,
			"route": route,
			"input_mode": "gamepad" if InputPrompts.gamepad_mode else "pointer",
			"duration_ms": int(profile["duration_ms"]),
			"amplitude": float(profile["amplitude"]),
		})
		return true

	if joypad_id >= 0:
		Input.start_joy_vibration(joypad_id, float(profile["weak"]),
			float(profile["strong"]), float(profile["duration_ms"]) / 1000.0)
	else:
		Input.vibrate_handheld(int(profile["duration_ms"]), float(profile["amplitude"]))
	return true


func _active_joypad() -> int:
	if not InputPrompts.gamepad_mode:
		return -1
	return InputPrompts.active_joypad()


func reset_test_state() -> void:
	test_events.clear()
	_last_at.clear()


func event_count(profile_name := "") -> int:
	if profile_name.is_empty():
		return test_events.size()
	var count := 0
	for event in test_events:
		if String(event.get("profile", "")) == profile_name:
			count += 1
	return count
