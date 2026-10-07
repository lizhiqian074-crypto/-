class_name InputSetup
extends RefCounted
static func install() -> void:
	var keys = {"move_forward": KEY_W, "move_backward": KEY_S, "move_left": KEY_A,
		"move_right": KEY_D, "move_up": KEY_E, "move_down": KEY_Q, "pause": KEY_ESCAPE,
		"debug_event_1": KEY_F1, "debug_event_2": KEY_F2, "debug_event_3": KEY_F3,
		"debug_reset_save": KEY_F4}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key = InputEventKey.new()
			key.physical_keycode = keys[action]
			InputMap.action_add_event(action, key)
	if not InputMap.has_action("camera_rotate"):
		InputMap.add_action("camera_rotate")
		var mouse = InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("camera_rotate", mouse)
