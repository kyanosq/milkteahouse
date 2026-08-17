## 输入设备路由：补齐手柄动作，并让界面提示在键鼠与手柄间即时切换。
extends Node

signal scheme_changed(gamepad: bool)
signal bindings_changed

const DEFAULT_KEYS := {
	"game_pause": KEY_ESCAPE,
	"game_shake": KEY_SPACE,
	"staff_interact": KEY_F,
}
const JOY_BUTTONS := {
	"game_pause": JOY_BUTTON_START,
	"game_shake": JOY_BUTTON_X,
	"staff_interact": JOY_BUTTON_Y,
}
const FIXED_KEYS := {"prep_tea": KEY_Q, "prep_pearl": KEY_E}
## 保留键（P11-F2）：数字 1–9 是情境选择的效率捷径，Enter 是 UI 确认，
## Tab 是焦点遍历——改键占用会让对应功能静默失效。
const RESERVED_KEYS := [
	KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9,
	KEY_ENTER, KEY_KP_ENTER, KEY_TAB,
]
const FIXED_JOY_BUTTONS := {"prep_tea": JOY_BUTTON_LEFT_SHOULDER, "prep_pearl": JOY_BUTTON_RIGHT_SHOULDER}
const CONTROLLER_LABELS := {
	"xbox": {"accept": "A", "cancel": "B", "shake": "X", "staff": "Y", "tea": "LB", "pearl": "RB", "pause": "Menu"},
	"playstation": {"accept": "×", "cancel": "○", "shake": "□", "staff": "△", "tea": "L1", "pearl": "R1", "pause": "Options"},
	"nintendo": {"accept": "B", "cancel": "A", "shake": "Y", "staff": "X", "tea": "L", "pearl": "R", "pause": "+"},
	"generic": {"accept": "South", "cancel": "East", "shake": "West", "staff": "North", "tea": "L1", "pearl": "R1", "pause": "Start"},
}

var gamepad_mode := false
var controller_family := "xbox"
var active_joypad_id := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	var connected := Input.get_connected_joypads()
	if not connected.is_empty():
		_select_controller_device(int(connected[0]))
	apply_bindings()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_activate_gamepad(int(event.device))
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.55:
		_activate_gamepad(int(event.device))
	elif event is InputEventKey and event.pressed:
		_set_gamepad_mode(false)
	elif event is InputEventMouseButton and event.pressed:
		_set_gamepad_mode(false)


func apply_bindings() -> void:
	for action_name in DEFAULT_KEYS:
		_configure_action(action_name, key_for(action_name), JOY_BUTTONS[action_name])
	for action_name in FIXED_KEYS:
		_configure_action(action_name, FIXED_KEYS[action_name], FIXED_JOY_BUTTONS[action_name])


func _configure_action(action_name: StringName, keycode: Key, joy_button: JoyButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey or event is InputEventJoypadButton:
			InputMap.action_erase_event(action_name, event)
	var key := InputEventKey.new()
	key.keycode = keycode
	InputMap.action_add_event(action_name, key)
	var button := InputEventJoypadButton.new()
	button.button_index = joy_button
	InputMap.action_add_event(action_name, button)


func key_for(action_name: String) -> Key:
	return GameState.key_binding(action_name, DEFAULT_KEYS.get(action_name, KEY_NONE))


func conflict_for(action_name: String, keycode: Key) -> String:
	for other_action in DEFAULT_KEYS:
		if other_action != action_name and key_for(other_action) == keycode:
			return other_action
	# Q/E 是不可改绑的备料固定键；改绑到它们会让 _input 的先到先得消费
	# 静默废掉其中一个动作（评审 R8）。
	for fixed_action in FIXED_KEYS:
		if FIXED_KEYS[fixed_action] == keycode:
			return fixed_action
	if keycode in RESERVED_KEYS:
		return "_reserved"
	return ""


func rebind_keyboard(action_name: String, keycode: Key) -> bool:
	if not DEFAULT_KEYS.has(action_name) or keycode == KEY_NONE:
		return false
	if conflict_for(action_name, keycode) != "":
		return false
	var bindings: Dictionary = GameState.settings.get("key_bindings", {}).duplicate(true)
	bindings[action_name] = int(keycode)
	GameState.settings["key_bindings"] = bindings
	_configure_action(action_name, keycode, JOY_BUTTONS[action_name])
	GameState.save_game()
	bindings_changed.emit()
	return true


func reset_keyboard_bindings() -> void:
	var bindings := {}
	for action_name in DEFAULT_KEYS:
		bindings[action_name] = int(DEFAULT_KEYS[action_name])
	GameState.settings["key_bindings"] = bindings
	apply_bindings()
	GameState.save_game()
	bindings_changed.emit()


func key_label(action_name: String) -> String:
	var keycode := key_for(action_name)
	match keycode:
		KEY_ESCAPE:
			return "Esc"
		KEY_SPACE:
			return GameLocale.text("KEY_SPACE")
		KEY_ENTER, KEY_KP_ENTER:
			return "Enter"
		_:
			var label := OS.get_keycode_string(keycode)
			return label if not label.is_empty() else GameLocale.text("KEY_UNSET")


func _set_gamepad_mode(enabled: bool) -> void:
	if gamepad_mode == enabled:
		return
	gamepad_mode = enabled
	scheme_changed.emit(gamepad_mode)


func set_test_gamepad_mode(enabled: bool) -> void:
	_set_gamepad_mode(enabled)


func set_test_controller_family(family: String) -> void:
	var normalized := family if CONTROLLER_LABELS.has(family) else "generic"
	var changed := controller_family != normalized
	controller_family = normalized
	active_joypad_id = -1
	if not gamepad_mode:
		_set_gamepad_mode(true)
	elif changed:
		scheme_changed.emit(true)


func detect_controller_family(name: String, guid := "", info := {}) -> String:
	var raw_name := String(info.get("raw_name", "")) if info is Dictionary else ""
	var signature := (name + " " + raw_name).to_lower()
	var vendor := int(info.get("vendor_id", 0)) if info is Dictionary else 0
	if vendor == 0x057E or signature.contains("nintendo") or signature.contains("switch") \
			or signature.contains("joy-con") or signature.contains("joycon") \
			or signature.strip_edges() == "pro controller":
		return "nintendo"
	if vendor == 0x054C or signature.contains("playstation") or signature.contains("dualshock") \
			or signature.contains("dualsense") or signature.contains("ps3 controller") \
			or signature.contains("ps4 controller") or signature.contains("ps5 controller") \
			or signature.contains("sony") or signature.strip_edges() == "wireless controller":
		return "playstation"
	if vendor == 0x045E or guid == "__XINPUT_DEVICE__" or signature.contains("xbox") \
			or signature.contains("xinput") or signature.contains("microsoft"):
		return "xbox"
	return "generic"


func _activate_gamepad(device: int) -> void:
	var family_changed := false
	if device in Input.get_connected_joypads():
		family_changed = _select_controller_device(device)
	if not gamepad_mode:
		gamepad_mode = true
		scheme_changed.emit(true)
	elif family_changed:
		scheme_changed.emit(true)


func _select_controller_device(device: int) -> bool:
	active_joypad_id = device
	var detected := detect_controller_family(Input.get_joy_name(device), Input.get_joy_guid(device),
		Input.get_joy_info(device))
	var changed := controller_family != detected
	controller_family = detected
	return changed


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		if active_joypad_id < 0:
			var changed := _select_controller_device(device)
			if gamepad_mode and changed:
				scheme_changed.emit(true)
		return
	if device != active_joypad_id:
		return
	var remaining := Input.get_connected_joypads()
	if not remaining.is_empty():
		var changed := _select_controller_device(int(remaining[0]))
		if gamepad_mode and changed:
			scheme_changed.emit(true)
	else:
		active_joypad_id = -1
		_set_gamepad_mode(false)


func active_joypad() -> int:
	var connected := Input.get_connected_joypads()
	if active_joypad_id in connected:
		return active_joypad_id
	return int(connected[0]) if not connected.is_empty() else -1


func controller_label(action: String) -> String:
	var labels: Dictionary = CONTROLLER_LABELS.get(controller_family, CONTROLLER_LABELS["generic"])
	return String(labels.get(action, "?"))


func accept_hint() -> String:
	return controller_label("accept") if gamepad_mode else GameLocale.text("INPUT_CLICK_ENTER")


func cancel_hint() -> String:
	return controller_label("cancel") if gamepad_mode else "Esc"


func pause_hint() -> String:
	return controller_label("pause") if gamepad_mode else key_label("game_pause")


func shake_hint() -> String:
	return controller_label("shake") if gamepad_mode else key_label("game_shake")


func staff_hint() -> String:
	return controller_label("staff") if gamepad_mode else key_label("staff_interact")


func prep_tea_hint() -> String:
	return controller_label("tea") if gamepad_mode else OS.get_keycode_string(FIXED_KEYS["prep_tea"])


func prep_pearl_hint() -> String:
	return controller_label("pearl") if gamepad_mode else OS.get_keycode_string(FIXED_KEYS["prep_pearl"])
