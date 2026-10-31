class_name CameraRig
extends Node3D
## Three ways to see the world:
##   HOUSE    - Sims-style orbit camera, walls facing you are cut away.
##   SHOULDER - follows Jamie from behind and to the right.
##   FIRST    - Jamie's own eyes.
##   DRIVE    - a chase camera behind the car (only while driving).
##   TITLE    - a slow orbit over the neighborhood behind the main menu.

enum Mode { HOUSE, SHOULDER, FIRST, DRIVE, TITLE }

signal mode_changed(mode: int)

const MODE_NAMES := ["HOUSE CAM", "OVER SHOULDER", "FIRST PERSON", "DRIVING", ""]

var mode := Mode.HOUSE
var cam := Camera3D.new()
var sim: Sim
var target := Vector3(4.2, 0.4, 3.0)
var house_yaw := deg_to_rad(40.0)
var house_pitch := deg_to_rad(46.0)
var house_dist := 10.5
var look_yaw := 0.0
var look_pitch := -0.12
var dragging := false
## Off while typing in the diary, so WASD/Q/E don't move the camera.
var input_enabled := true
var owns_mouse := true             # (Player 2's camera leaves the mouse alone)
static var allow_first := true     # first person is off while two players share the screen
var _target_tween: Tween
var _last_input_ms := -100000
var car: Car = null                 # the car being driven (DRIVE mode)
var _chase_pos := Vector3.ZERO
var _chase_look := Vector3.ZERO
var _chase_yaw := 0.0              # extra look-around from the mouse / right stick


func setup(p_sim: Sim) -> void:
	sim = p_sim
	add_child(cam)
	cam.current = true
	cam.near = 0.06      # (a little further than the default, for finer depth far away)
	cam.far = 900.0
	set_mode(Mode.HOUSE)


func set_mode(m: int) -> void:
	mode = m
	# The near plane sets how finely depth is measured: the further out it is, the
	# less two close surfaces fight far away. The House Cam never gets close to
	# anything, so it can push it well out; first person needs it close.
	cam.near = {Mode.HOUSE: 0.5, Mode.TITLE: 0.5, Mode.DRIVE: 0.2, Mode.SHOULDER: 0.1}.get(m, 0.06)
	if mode == Mode.HOUSE or mode == Mode.TITLE:
		cam.fov = 45.0
		if owns_mouse:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif mode == Mode.DRIVE:
		cam.fov = 66.0
		_chase_yaw = 0.0
		if car:
			_chase_pos = _chase_goal()
			_chase_look = car.global_position + Vector3(0, 1.0, 0)
		if owns_mouse:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		cam.fov = 72.0 if mode == Mode.FIRST else 62.0
		look_yaw = sim.rotation.y
		look_pitch = -0.12
		if owns_mouse:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	sim.set_view_mode(mode == Mode.FIRST, mode == Mode.HOUSE)
	mode_changed.emit(mode)


func cycle() -> void:
	var m := (mode + 1) % 3
	if m == Mode.FIRST and not allow_first:
		m = (m + 1) % 3
	set_mode(m)


func mouse_look(rel: Vector2) -> void:
	var k := 0.0035 * Settings.look_sensitivity
	if mode == Mode.DRIVE:
		_chase_yaw = clampf(_chase_yaw - rel.x * k, -2.4, 2.4)
		return
	look_yaw -= rel.x * k
	look_pitch = clampf(look_pitch - rel.y * k * (-1.0 if Settings.invert_y else 1.0), -1.3, 1.2)


## Right stick look (first person / shoulder / driving). `v` is -1..1 per axis.
func stick_look(v: Vector2, delta: float) -> void:
	if v.length() < 0.01:
		if mode == Mode.DRIVE:
			_chase_yaw = move_toward(_chase_yaw, 0.0, delta * 2.0)
		return
	var k := 2.6 * Settings.look_sensitivity * delta
	if mode == Mode.DRIVE:
		_chase_yaw = clampf(-v.x * 2.0, -2.0, 2.0)
		return
	look_yaw -= v.x * k
	look_pitch = clampf(look_pitch - v.y * k * 0.7 * (-1.0 if Settings.invert_y else 1.0), -1.3, 1.2)


## Left stick / edge pan for the House Cam (gamepad). `v` is -1..1 per axis.
func pan_house(v: Vector2, delta: float) -> void:
	if v.length() < 0.01:
		return
	_last_input_ms = Time.get_ticks_msec()
	var fwd := Vector3(-sin(house_yaw), 0, -cos(house_yaw))
	var right := Vector3(cos(house_yaw), 0, -sin(house_yaw))
	target += (right * v.x - fwd * v.y) * 6.0 * delta
	_clamp_target()
	if _target_tween:
		_target_tween.kill()


## Keep the House Cam over the world (or over the attics and basements, underground).
func _clamp_target() -> void:
	var w := RoomBuilder.INTERIOR_WORLD if target.y < RoomBuilder.INTERIOR_Y * 0.5 else RoomBuilder.WORLD
	target.x = clampf(target.x, w.position.x, w.end.x)
	target.z = clampf(target.z, w.position.y, w.end.y)


## Jump straight to a point (after going up or down the stairs).
func snap_to(point: Vector3) -> void:
	if _target_tween:
		_target_tween.kill()
	target = point


## Turn the view toward what Jamie is doing (first person / shoulder).
func face_yaw(yaw: float, pitch := -0.12) -> void:
	look_yaw = yaw
	look_pitch = pitch


## Glide the House Cam over to a room.
func focus(point: Vector3) -> void:
	if _target_tween:
		_target_tween.kill()
	_target_tween = create_tween()
	_target_tween.tween_property(self, "target", Vector3(point.x, point.y + 0.4, point.z), 1.2) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func zoom(steps: float) -> void:
	house_dist = clampf(house_dist + steps, 4.5, 28.0)


## Seconds since the player last panned the House Cam.
func idle_seconds() -> float:
	return (Time.get_ticks_msec() - _last_input_ms) / 1000.0


func rotate_house(amount: float) -> void:
	house_yaw += amount


## Flat forward / right vectors for moving Jamie with WASD.
func move_basis() -> Array:
	var f := Vector3(-sin(look_yaw), 0, -cos(look_yaw))
	var r := Vector3(cos(look_yaw), 0, -sin(look_yaw))
	return [f, r]


func _process(delta: float) -> void:
	match mode:
		Mode.HOUSE:
			_update_house(delta)
		Mode.SHOULDER:
			_update_shoulder()
		Mode.FIRST:
			_update_first()
		Mode.DRIVE:
			_update_drive(delta)
		Mode.TITLE:
			house_yaw += delta * 0.05
			var off := Vector3(sin(house_yaw) * cos(house_pitch), sin(house_pitch), cos(house_yaw) * cos(house_pitch)) * house_dist
			cam.global_position = target + off
			cam.look_at(target, Vector3.UP)


func _update_house(delta: float) -> void:
	var pan := Vector2.ZERO
	if input_enabled:
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			pan.y += 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			pan.y -= 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			pan.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			pan.x += 1.0
	if pan != Vector2.ZERO:
		_last_input_ms = Time.get_ticks_msec()
		var fwd := Vector3(-sin(house_yaw), 0, -cos(house_yaw))
		var right := Vector3(cos(house_yaw), 0, -sin(house_yaw))
		target += (right * pan.x + fwd * pan.y) * 5.0 * delta
		_clamp_target()
		if _target_tween:
			_target_tween.kill()
	if input_enabled and Input.is_physical_key_pressed(KEY_Q) and not Input.is_key_pressed(KEY_CTRL):
		house_yaw += 1.6 * delta
	if input_enabled and Input.is_physical_key_pressed(KEY_E):
		house_yaw -= 1.6 * delta
	var off := Vector3(sin(house_yaw) * cos(house_pitch), sin(house_pitch), cos(house_yaw) * cos(house_pitch)) * house_dist
	cam.global_position = target + off
	cam.look_at(target, Vector3.UP)


func _look_basis() -> Basis:
	return Basis.from_euler(Vector3(look_pitch, look_yaw, 0.0))


func _update_shoulder() -> void:
	var head := sim.eye_point()
	var b := _look_basis()
	var desired := head + b * Vector3(0.75, 0.3, 2.7)
	# Pull the camera in if a wall is between it and Jamie.
	var q := PhysicsRayQueryParameters3D.create(head, desired, 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		desired = hit["position"] + (head - desired).normalized() * 0.25
	cam.global_position = desired
	cam.global_basis = b


func _update_first() -> void:
	var b := _look_basis()
	cam.global_position = sim.eye_point() + b * Vector3(0, 0, -0.12)
	cam.global_basis = b


func _chase_goal() -> Vector3:
	var back := -car.global_basis.z.rotated(Vector3.UP, _chase_yaw)
	return car.global_position + back * (car.length * 0.5 + 4.6) + Vector3(0, 2.3, 0)


func _update_drive(delta: float) -> void:
	if car == null:
		return
	var goal := _chase_goal()
	# Don't let the camera end up inside a wall or a house.
	var head := car.global_position + Vector3(0, 1.6, 0)
	var q := PhysicsRayQueryParameters3D.create(head, goal, 2)
	q.exclude = [car.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		goal = hit["position"] + (head - goal).normalized() * 0.3
	var t := minf(1.0, delta * 5.0)
	_chase_pos = _chase_pos.lerp(goal, t)
	_chase_look = _chase_look.lerp(car.global_position + car.global_basis.z * 3.0 + Vector3(0, 0.9, 0), minf(1.0, delta * 8.0))
	cam.global_position = _chase_pos
	cam.look_at(_chase_look, Vector3.UP)
	cam.fov = lerpf(cam.fov, 64.0 + absf(car.speed) * 0.7, t)
