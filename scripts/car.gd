class_name Car
extends SmartObject
## A car Jamie can drive. Built facing local +z (the front), so the driver's
## door is on local +x (the left side, US-style).
##
## While parked it's an ordinary usable object ("Go for a Drive"). While driving,
## main.gd calls drive_step() every physics frame with the player's input.

const MAX_SPEED := 15.0      # m/s, about 34 mph
const MAX_REVERSE := 4.5
const ACCEL := 6.5
const BRAKE := 11.0
const WHEELBASE := 2.8
## Only things on these layers stop a car: walls & furniture (2), usable objects
## (1) and the invisible edge of the drivable area (16).
const MASK := 1 | 2 | 4 | 16   # (4 = the kids: nobody gets driven through)

var key := ""
var length := 4.5
var width := 1.9
var driving := false
var speed := 0.0
var steer := 0.0
var solid_index := -1        # this car's rectangle in the walking-grid obstacle list
var wheels: Array[Node3D] = []
var front_wheels: Array[Node3D] = []
var headlights: Array[SpotLight3D] = []
var engine := AudioStreamPlayer3D.new()
var _bump_cooldown := 0.0
var _ouch_cooldown := 0.0
## Online: who's driving, and whether another computer is moving this car
## (then it just follows the positions that arrive: see remote_update).
var driver: Node = null
var remote := false
var _net_pos := Vector3.INF
var _net_yaw := 0.0

signal bumped(strength: float)
signal hit_someone(who: Node3D)     # a townsperson or a kid


func _ready() -> void:
	collision_mask = MASK
	var s: AudioStream = load("res://audio/engine.ogg")
	if s is AudioStreamOggVorbis:
		s = s.duplicate() as AudioStream
		(s as AudioStreamOggVorbis).loop = true
	engine.stream = s
	engine.bus = "SFX"
	engine.unit_size = 9.0
	engine.volume_db = -6.0
	engine.position = Vector3(0, 0.6, length * 0.35)
	add_child(engine)


# ---------------------------------------------------------------- building

## A wheel at local `at`; it spins around x and (front wheels) steers around y.
func add_wheel(at: Vector3, front: bool) -> void:
	var hub := Node3D.new()
	hub.position = at
	add_child(hub)
	var spin := Node3D.new()
	hub.add_child(spin)
	# A round tire (a cylinder turned on its side), a hubcap, and two spokes so you can see it roll
	_cyl(spin, 0.31, 0.22, Palette.INK, 20)
	_cyl(spin, 0.15, 0.236, Palette.MUTED, 14)
	var side := signf(at.x)
	for a in [0.0, PI / 2.0]:
		var sp := RoomBuilder.box(spin, Vector3(0.012, 0.26, 0.05), Vector3(side * 0.12, 0, 0), Palette.INK2)
		sp.rotation.x = a
	wheels.append(spin)
	if front:
		front_wheels.append(hub)


static func _cyl(parent: Node3D, radius: float, width: float, color: Color, segs: int) -> void:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = width
	m.radial_segments = segs
	m.rings = 1
	mi.mesh = m
	mi.rotation.z = PI / 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	parent.add_child(mi)


func add_headlight(at: Vector3) -> void:
	var l := SpotLight3D.new()
	l.position = at
	l.rotation_degrees = Vector3(-6, 180, 0)    # spotlights shine along -z, so turn it to face the front (+z)
	l.spot_range = 22.0
	l.spot_angle = 28.0
	l.light_color = Color("FFF1C8")
	l.light_energy = 3.0
	l.visible = false
	add_child(l)
	headlights.append(l)


## Where Jamie stands to get in: beside the driver's door.
func door_point() -> Vector3:
	var p := to_global(Vector3(width / 2.0 + 0.55, 0, 0.35))
	return Vector3(p.x, 0, p.z)


func refresh_points() -> void:
	approach_point = door_point()
	use_point = approach_point
	look_point = to_global(Vector3(0, 1.0, 0.35))


## The car's rectangle on the floor (for the walking grid), with a little room around it.
func footprint() -> Rect2:
	return Props.footprint(self, Vector3(width, 1.0, length), Vector3.ZERO)


## Places Jamie could get out, best first: beside the driver's door, the
## passenger side, behind, in front, then the same a little farther out (a car
## parked at an angle blocks a wider square on the walking grid).
func exit_spots() -> Array:
	var out := []
	for extra in [0.0, 0.7, 1.4, 2.2]:
		for local in [Vector3(width / 2.0 + 0.6 + extra, 0, 0.35), Vector3(-width / 2.0 - 0.6 - extra, 0, 0.35),
				Vector3(0, 0, -length / 2.0 - 0.7 - extra), Vector3(0, 0, length / 2.0 + 0.7 + extra)]:
			var p := to_global(local)
			out.append(Vector3(p.x, 0, p.z))
	return out


# ---------------------------------------------------------------- driving

func set_driving(on: bool, night: bool) -> void:
	driving = on
	if not on:
		_net_pos = Vector3.INF
	speed = 0.0
	steer = 0.0
	for l in headlights:
		l.visible = on and night
	if on:
		engine.play()
	else:
		engine.stop()


## One physics step. throttle and brake are 0..1, turn is -1 (left) .. 1 (right).
func drive_step(delta: float, throttle: float, brake: float, turn: float) -> void:
	_bump_cooldown = maxf(0.0, _bump_cooldown - delta)
	_ouch_cooldown = maxf(0.0, _ouch_cooldown - delta)
	# Gas, brakes and reverse
	if throttle > 0.05:
		speed += ACCEL * throttle * delta * (1.0 if speed >= -0.2 else 2.0)
	if brake > 0.05:
		if speed > 0.3:
			speed -= BRAKE * brake * delta
		else:
			speed -= ACCEL * 0.6 * brake * delta
	if throttle <= 0.05 and brake <= 0.05:
		speed = move_toward(speed, 0.0, (1.5 + absf(speed) * 0.08) * delta)
	speed = clampf(speed, -MAX_REVERSE, MAX_SPEED)

	# Steering: the wheels turn less at speed, so it stays controllable
	var max_angle := lerpf(0.6, 0.16, clampf(absf(speed) / MAX_SPEED, 0.0, 1.0))
	steer = move_toward(steer, turn * max_angle, delta * 2.5)
	var yaw_rate := speed / WHEELBASE * tan(steer)
	rotate_y(-yaw_rate * delta)

	# Move; on hitting something, slide along it (a head-on hit stops the car,
	# a glancing one just scrapes along and loses a little speed).
	var motion := global_basis.z * speed * delta
	var hit := move_and_collide(motion)
	if hit:
		var who := hit.get_collider()
		if (who is Npc or who is Sim) and absf(speed) > 0.6 and _ouch_cooldown <= 0.0:
			_ouch_cooldown = 1.2
			hit_someone.emit(who)
		var n := hit.get_normal()
		n.y = 0.0
		if n.length() > 0.01:
			n = n.normalized()
			var dir := motion.normalized()
			var head_on := absf(dir.dot(n))
			var strength := absf(speed) * head_on
			speed *= clampf(1.0 - head_on * 1.2, 0.0, 0.9)
			if head_on > 0.85 and absf(speed) < 0.5:
				speed = 0.0
			var rest := hit.get_remainder().slide(n)
			rest.y = 0.0
			if rest.length() > 0.0005:
				move_and_collide(rest)
			if strength > 1.5 and _bump_cooldown <= 0.0:
				_bump_cooldown = 0.5
				bumped.emit(strength)
	global_position.y = 0.0

	# Wheels spin and steer; engine pitch follows the speed
	for w in wheels:
		w.rotate_x(speed * delta / 0.31)
	for f in front_wheels:
		f.rotation.y = -steer
	engine.pitch_scale = 0.75 + absf(speed) / MAX_SPEED * 1.1 + throttle * 0.1


## Online: where the car is on the driver's computer.
func remote_update(pos: Vector3, yaw: float, spd: float, st: float) -> void:
	_net_pos = pos
	_net_yaw = yaw
	speed = spd
	steer = st


func _physics_process(delta: float) -> void:
	if not remote or _net_pos == Vector3.INF:
		return
	var t := minf(1.0, delta * 12.0)
	if global_position.distance_to(_net_pos) > 6.0:
		global_position = _net_pos
	else:
		global_position = global_position.lerp(_net_pos, t)
	rotation.y = lerp_angle(rotation.y, _net_yaw, t)
	for w in wheels:
		w.rotate_x(speed * delta / 0.31)
	for f in front_wheels:
		f.rotation.y = -steer
	engine.pitch_scale = 0.75 + absf(speed) / MAX_SPEED * 1.1


func honk() -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = load("res://audio/horn.ogg")
	p.bus = "SFX"
	p.unit_size = 12.0
	p.position = Vector3(0, 0.7, length / 2.0)
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func mph() -> int:
	return int(round(absf(speed) * 2.237))
