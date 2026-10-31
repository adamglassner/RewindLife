class_name InputSetup
extends RefCounted
## Every control in the game, for keyboard/mouse AND gamepad (Xbox or PlayStation
## layouts; Godot calls the buttons by their Xbox names):
##
##                 Keyboard / mouse          Gamepad
##   Move          WASD / arrows             Left stick
##   Look          Mouse                     Right stick
##   Use / select  E, left click             A  (Cross)
##   Back / close  Esc                       B  (Circle)
##   Camera        C                         Y  (Triangle)
##   Pause menu    Esc                       Start / Options
##   Pause time    P                         Back / Share
##   Jump          Space                     X  (Square)
##   Speed - / +   1 2 3                     LB / RB
##   Zoom          Mouse wheel               D-pad up / down
##   Free Will     F                         D-pad left
##   Music         M                         D-pad right
##   Run           hold Shift                click the left stick
##   Emotes        G                         click the right stick
##   Driving:      W/S gas & brake, A/D steer, H horn, E get out
##                 RT gas, LT brake/reverse, left stick steer, X horn, A get out

const DEADZONE := 0.25


static func setup() -> void:
	_action("move_forward", [KEY_W, KEY_UP], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_action("move_back", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_action("move_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("move_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("look_left", [], [], [[JOY_AXIS_RIGHT_X, -1.0]])
	_action("look_right", [], [], [[JOY_AXIS_RIGHT_X, 1.0]])
	_action("look_up", [], [], [[JOY_AXIS_RIGHT_Y, -1.0]])
	_action("look_down", [], [], [[JOY_AXIS_RIGHT_Y, 1.0]])
	_action("pad_use", [], [JOY_BUTTON_A], [])
	_action("pad_back", [], [JOY_BUTTON_B], [])
	_action("camera_cycle", [KEY_C], [JOY_BUTTON_Y], [])
	_action("pause_menu", [KEY_ESCAPE], [JOY_BUTTON_START], [])
	_action("time_pause", [KEY_P], [JOY_BUTTON_BACK], [])
	_action("jump", [KEY_SPACE], [JOY_BUTTON_X], [])
	_action("speed_down", [], [JOY_BUTTON_LEFT_SHOULDER], [])
	_action("speed_up", [], [JOY_BUTTON_RIGHT_SHOULDER], [])
	_action("zoom_in", [], [JOY_BUTTON_DPAD_UP], [])
	_action("zoom_out", [], [JOY_BUTTON_DPAD_DOWN], [])
	_action("free_will", [KEY_F], [JOY_BUTTON_DPAD_LEFT], [])
	_action("music", [KEY_M], [JOY_BUTTON_DPAD_RIGHT], [])
	_action("accelerate", [KEY_W, KEY_UP], [], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_action("brake", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	_action("steer_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("steer_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("horn", [KEY_H], [JOY_BUTTON_X], [])
	_action("run", [KEY_SHIFT], [JOY_BUTTON_LEFT_STICK], [])
	_action("lights", [], [], [])
	_action("emote", [KEY_G], [JOY_BUTTON_RIGHT_STICK], [])
	# Menus: make sure the sticks and D-pad move between buttons, and A/B work
	_add_joy("ui_up", [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add_joy("ui_down", [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add_joy("ui_left", [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add_joy("ui_right", [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add_joy("ui_accept", [JOY_BUTTON_A], [])
	_add_joy("ui_cancel", [JOY_BUTTON_B], [])
	# Space shouldn't press menu buttons (it jumps); Enter still does.
	for e in InputMap.action_get_events("ui_accept"):
		if e is InputEventKey and (e as InputEventKey).keycode == KEY_SPACE:
			InputMap.action_erase_event("ui_accept", e)


static func _action(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	_add_joy(action, buttons, axes)


static func _add_joy(action: String, buttons: Array, axes: Array) -> void:
	var existing := InputMap.action_get_events(action)
	for b in buttons:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		if not _has(existing, e):
			InputMap.action_add_event(action, e)
	for a in axes:
		var e := InputEventJoypadMotion.new()
		e.axis = a[0]
		e.axis_value = a[1]
		if not _has(existing, e):
			InputMap.action_add_event(action, e)


static func _has(events: Array, e: InputEvent) -> bool:
	for x in events:
		if x is InputEventJoypadButton and e is InputEventJoypadButton and x.button_index == e.button_index:
			return true
		if x is InputEventJoypadMotion and e is InputEventJoypadMotion and x.axis == e.axis and signf(x.axis_value) == signf(e.axis_value):
			return true
	return false


## True for gamepad input (ignoring tiny stick drift).
static func is_pad(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return true
	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) > 0.4
	return false


## True for keyboard or real mouse movement.
static func is_keyboard_mouse(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventMouseButton:
		return true
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).relative.length() > 2.0
	return false


## Split screen: the game's controls answer only to Player 1's controller
## (`device`), so Player 2's doesn't move Jamie too. -1 = any controller.
static func set_pad_device(device: int) -> void:
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				if e.device == device:
					continue
				var d: InputEvent = e.duplicate()
				d.device = device
				InputMap.action_erase_event(action, e)
				InputMap.action_add_event(action, d)
