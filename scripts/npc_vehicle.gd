class_name NpcVehicle
extends AnimatableBody3D
## A car or truck the townsfolk drive: Officer Dwyer's police car, the fire
## engines, Mr. Delgado's milk truck. It drives a route of points along the
## streets (right-hand lanes, rounded corners), slows for corners, and stops for
## anyone in the way. Built facing local +z, like the player's cars.
##
## Online, the host drives them; everyone else's copy just follows (`puppet`).
##
## RoadNet (the static functions at the bottom) plans routes: every street runs
## east-west and joins Oak Avenue at its west end, so getting anywhere means
## "along this street to Oak, along Oak, then along that street".

const CRUISE := 6.5
const CORNER := 3.0
const LANE := 1.15                # lanes are this far either side of the center line
const OAK_X := -20.5              # Oak Avenue's center line
const STREETS := {"maple": 19.6, "main": 50.0, "lincoln": -32.0}

var key := ""
var kind := ""                    # "police", "fire", "milk"
var title := ""
var length := 4.8
var width := 1.9
var driver_key := ""              # the townsperson at the wheel
var home_pos := Vector3.ZERO
var home_yaw := 0.0
var moving := false
var siren := false
var speed := 0.0
var puppet := false
var net_pos := Vector3.ZERO
var net_yaw := 0.0
var stops := {}                   # point index -> seconds to wait there (the milk truck at each house)
var on_stop: Callable             # called when it pauses at one of those stops
var main: Node

var _pts: Array = []              # [[Vector3, reverse], ...]
var _i := 0
var _done: Callable
var _wait := 0.0
var _blocked_t := 0.0
var _flash: Array[StandardMaterial3D] = []
var _cab: Node3D
var _wheels: Array[Node3D] = []
var _engine := AudioStreamPlayer3D.new()
var last_block := ""              # (for testing: what it last stopped for)
var _stuck_t := 0.0               # how long it's been held up (no honk reset)
var _yield_until := 0             # (ms) ignoring other town vehicles until then, to get unstuck


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = false
	var s: AudioStream = load("res://audio/engine.ogg")
	if s is AudioStreamOggVorbis:
		s = s.duplicate() as AudioStream
		(s as AudioStreamOggVorbis).loop = true
	_engine.stream = s
	_engine.bus = "SFX"
	_engine.unit_size = 10.0
	_engine.volume_db = -8.0
	_engine.pitch_scale = 0.8 if kind == "fire" else 1.0
	add_child(_engine)


# ---------------------------------------------------------------- building

static func make(parent: Node3D, p_key: String, p_kind: String, at: Vector3, yaw_deg: float, paint := Color("2E4A7A"),
		shirt := Color("C8A250")) -> NpcVehicle:
	var v := NpcVehicle.new()
	v.name = p_key
	v.key = p_key
	v.kind = p_kind
	parent.add_child(v)
	v.position = at
	v.rotation_degrees.y = yaw_deg
	v.home_pos = at
	v.home_yaw = v.rotation.y
	match p_kind:
		"police":
			v._police()
		"fire":
			v._fire_engine()
		"milk":
			v._milk_truck()
		"mail":
			v._mail_truck()
		"car":
			v._car(paint, shirt)
	RoomBuilder.add_shape(v, Vector3(v.width, 1.6, v.length), Vector3(0, 0.95, 0))
	return v


func _b(size: Vector3, at: Vector3, c: Color) -> MeshInstance3D:
	return RoomBuilder.box(self, size, at, c)


func _wheel_set(x: float, zs: Array, r := 0.34) -> void:
	for z in zs:
		for side in [-1.0, 1.0]:
			var hub := Node3D.new()
			hub.position = Vector3(side * x, r, z)
			add_child(hub)
			Car._cyl(hub, r, 0.26, Palette.INK, 16)
			Car._cyl(hub, r * 0.5, 0.27, Palette.MUTED, 10)
			_wheels.append(hub)


## A flashing light on the roof (red/blue for the police, red for the fire engine).
func _beacon(at: Vector3, size: Vector3, c: Color) -> void:
	var m := _b(size, at, c).material_override as StandardMaterial3D
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.0
	_flash.append(m)


## Someone in the driver's seat (shown while it's out driving).
func _driver_seat(at: Vector3, shirt: Color, hat := Color.TRANSPARENT) -> void:
	_cab = Node3D.new()
	_cab.position = at
	add_child(_cab)
	RoomBuilder.box(_cab, Vector3(0.42, 0.45, 0.28), Vector3(0, 0.22, 0), shirt)
	RoomBuilder.box(_cab, Vector3(0.28, 0.3, 0.26), Vector3(0, 0.62, 0), Color("E2B98F"))
	if hat.a > 0.0:
		RoomBuilder.box(_cab, Vector3(0.32, 0.1, 0.3), Vector3(0, 0.8, 0.02), hat)
	_cab.visible = false


func _police() -> void:
	title = "Police Car"
	length = 4.9
	width = 1.9
	var black := Color("1E1E24")
	var white := Color("F2F0E6")
	_b(Vector3(1.9, 0.6, 4.9), Vector3(0, 0.62, 0), black)
	_b(Vector3(1.92, 0.42, 2.0), Vector3(0, 0.66, 0.05), white)              # the white doors
	_b(Vector3(1.72, 0.5, 2.4), Vector3(0, 1.16, -0.15), white)
	_b(Vector3(1.76, 0.36, 2.2), Vector3(0, 1.18, -0.15), Color("33405A"))
	_b(Vector3(1.94, 0.14, 4.94), Vector3(0, 0.36, 0), Palette.MUTED)        # bumpers & trim
	_beacon(Vector3(-0.38, 1.5, -0.2), Vector3(0.5, 0.14, 0.26), Color("E83A3A"))
	_beacon(Vector3(0.38, 1.5, -0.2), Vector3(0.5, 0.14, 0.26), Color("3A6AE8"))
	_b(Vector3(0.24, 0.12, 0.24), Vector3(0, 1.48, -0.2), Palette.MUTED)
	for side in [-1.0, 1.0]:
		var l := Label3D.new()
		l.text = "POLICE"
		l.font_size = 64
		l.pixel_size = 0.004
		l.modulate = black
		l.position = Vector3(side * 0.964, 0.68, 0.05)
		l.rotation_degrees.y = 90.0 * side
		l.double_sided = false
		add_child(l)
	_wheel_set(0.82, [-1.5, 1.5], 0.33)
	_driver_seat(Vector3(0.42, 0.7, 0.2), Color("2B3A6A"), Color("1E2A4A"))


func _fire_engine() -> void:
	title = "Fire Engine"
	length = 7.4
	width = 2.3
	var red := Color("C0322A")
	_b(Vector3(2.3, 1.2, 7.4), Vector3(0, 1.1, 0), red)
	_b(Vector3(2.32, 0.18, 7.42), Vector3(0, 0.62, 0), Palette.PAPER)           # the stripe
	_b(Vector3(2.2, 0.9, 2.0), Vector3(0, 2.1, 2.5), red)                       # the cab
	_b(Vector3(2.24, 0.5, 1.6), Vector3(0, 2.2, 2.6), Color("33405A"))
	_b(Vector3(1.9, 0.5, 0.05), Vector3(0, 2.15, 3.52), Color("33405A"))
	_b(Vector3(2.0, 0.12, 5.0), Vector3(0, 2.0, -1.2), Color("C8CCD0"))         # the ladder on top
	for k in 9:
		_b(Vector3(1.9, 0.06, 0.06), Vector3(0, 2.1, -3.4 + k * 0.55), Color("C8CCD0"))
	for side in [-1.0, 1.0]:
		_b(Vector3(0.1, 0.5, 4.0), Vector3(side * 1.18, 1.3, -1.2), Color("A8A8A0"))   # compartments
	_b(Vector3(2.4, 0.3, 0.2), Vector3(0, 0.55, 3.75), Palette.MUTED)
	_beacon(Vector3(-0.7, 2.62, 2.6), Vector3(0.4, 0.16, 0.3), Color("FF3A2A"))
	_beacon(Vector3(0.7, 2.62, 2.6), Vector3(0.4, 0.16, 0.3), Color("FF3A2A"))
	for side in [-1.0, 1.0]:
		var l := Label3D.new()
		l.text = "MAPLE GROVE F.D."
		l.font_size = 64
		l.pixel_size = 0.0045
		l.modulate = Palette.GOLD
		l.position = Vector3(side * 1.164, 1.25, 0.4)
		l.rotation_degrees.y = 90.0 * side
		l.double_sided = false
		add_child(l)
	_wheel_set(1.0, [-2.6, -1.6, 2.4], 0.45)
	_driver_seat(Vector3(0.55, 1.65, 2.5), Color("2B3A5A"), Color("E8C24A"))


## An ordinary family car (the traffic around town).
func _car(paint: Color, shirt: Color) -> void:
	title = "Car"
	length = 4.4
	width = 1.8
	_b(Vector3(1.8, 0.55, 4.4), Vector3(0, 0.6, 0), paint)
	_b(Vector3(1.6, 0.48, 2.2), Vector3(0, 1.11, -0.25), paint.darkened(0.08))
	_b(Vector3(1.64, 0.34, 2.0), Vector3(0, 1.13, -0.25), Color("33405A"))           # windows
	_b(Vector3(1.84, 0.14, 4.46), Vector3(0, 0.36, 0), Palette.MUTED)               # bumpers & trim
	for sx in [-0.62, 0.62]:
		var hl := _b(Vector3(0.3, 0.14, 0.04), Vector3(sx, 0.7, 2.21), Color("F2F0D6"))
		(hl.material_override as StandardMaterial3D).emission_enabled = true
		(hl.material_override as StandardMaterial3D).emission = Color("F2F0D6")
		(hl.material_override as StandardMaterial3D).emission_energy_multiplier = 0.4
		_b(Vector3(0.3, 0.12, 0.04), Vector3(sx, 0.7, -2.21), Color("C0322A"))
	_wheel_set(0.78, [-1.35, 1.35], 0.32)
	_driver_seat(Vector3(0.4, 0.75, -0.1), shirt)


## The mail truck: a boxy little white truck, right-hand drive, red and blue stripes.
func _mail_truck() -> void:
	title = "Mail Truck"
	length = 4.2
	width = 1.85
	var white := Color("F4F4EE")
	_b(Vector3(1.85, 1.95, 2.6), Vector3(0, 1.25, -0.75), white)                 # the box in back
	_b(Vector3(1.8, 1.1, 1.5), Vector3(0, 0.9, 1.3), white)                       # the cab
	_b(Vector3(1.84, 0.55, 1.1), Vector3(0, 1.6, 1.2), white)
	_b(Vector3(1.86, 0.42, 0.9), Vector3(0, 1.62, 1.32), Color("33405A"))         # windows
	_b(Vector3(1.88, 0.14, 4.22), Vector3(0, 0.95, 0.0), Color("C0322A"))         # a red stripe...
	_b(Vector3(1.88, 0.14, 4.22), Vector3(0, 0.78, 0.0), Color("2E5E9E"))         # ...over a blue one
	_b(Vector3(1.9, 0.3, 4.24), Vector3(0, 0.35, 0.0), Palette.MUTED)             # bumpers & trim
	for side in [-1.0, 1.0]:
		var l := Label3D.new()
		l.text = "MAPLE GROVE\nPOST OFFICE"
		l.font_size = 56
		l.pixel_size = 0.0042
		l.modulate = Color("2E5E9E")
		l.position = Vector3(side * 0.93, 1.55, -0.75)
		l.rotation_degrees.y = 90.0 * side
		l.double_sided = false
		add_child(l)
		_b(Vector3(0.02, 0.3, 0.46), Vector3(side * 0.94, 2.0, -0.75), Color("2E5E9E"))   # (an envelope painted on)
	_wheel_set(0.82, [-1.4, 1.3], 0.31)
	_driver_seat(Vector3(-0.42, 1.0, 1.15), Color("5A7AA8"), Color("5A7AA8"))       # (the mail carrier's blue shirt; right-hand drive)


func _milk_truck() -> void:
	title = "Milk Truck"
	length = 4.6
	width = 1.95
	var white := Color("F2F0E6")
	_b(Vector3(1.95, 2.0, 3.2), Vector3(0, 1.3, -0.6), white)
	_b(Vector3(1.9, 1.1, 1.4), Vector3(0, 0.95, 1.6), white)
	_b(Vector3(1.94, 0.5, 1.2), Vector3(0, 1.75, 1.5), Color("33405A"))
	_b(Vector3(1.97, 0.3, 4.62), Vector3(0, 0.6, 0.0), Color("4A8AC8"))           # a blue stripe
	_b(Vector3(1.98, 0.3, 1.44), Vector3(0, 0.3, 1.6), Palette.MUTED)
	for side in [-1.0, 1.0]:
		var l := Label3D.new()
		l.text = "MAPLE GROVE\nDAIRY"
		l.font_size = 64
		l.pixel_size = 0.0045
		l.modulate = Color("2E5E9E")
		l.position = Vector3(side * 0.98, 1.6, -0.6)
		l.rotation_degrees.y = 90.0 * side
		l.double_sided = false
		add_child(l)
		_b(Vector3(0.02, 0.45, 0.3), Vector3(side * 0.985, 1.1, -0.6), Palette.PAPER)   # (a bottle painted on)
	_wheel_set(0.85, [-1.5, 1.4], 0.32)
	_driver_seat(Vector3(0.45, 1.1, 1.4), Palette.PAPER, Palette.PAPER)


# ---------------------------------------------------------------- driving

## Drive a route of [[point, reverse], ...]; `done` is called at the end.
func drive(points: Array, done: Callable = Callable()) -> void:
	_pts = _smooth(points)
	_i = 0
	_done = done
	_wait = 0.0
	moving = true
	if _cab:
		_cab.visible = true
	_engine.play()


func set_siren(on: bool) -> void:
	siren = on
	if not on:
		for m in _flash:
			m.emission_energy_multiplier = 0.0
	if main and main.audio:
		if on:
			main.audio.start_loop("siren_" + key, "siren", global_position + Vector3(0, 1.5, 0), -6.0)
		else:
			main.audio.stop_loop("siren_" + key, 0.6)


func park() -> void:
	moving = false
	speed = 0.0
	if _cab:
		_cab.visible = false
	_engine.stop()


func _physics_process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	if siren:
		for k in _flash.size():
			_flash[k].emission_energy_multiplier = 2.5 if int(t * 6.0 + k) % 2 == 0 else 0.1
		if main and main.audio:
			main.audio.move_loop("siren_" + key, global_position + Vector3(0, 1.5, 0))
	if puppet:
		var to := net_pos - global_position
		to.y = 0.0
		if to.length() > 8.0:
			global_position = Vector3(net_pos.x, 0, net_pos.z)
		else:
			global_position += to * minf(1.0, delta * 8.0)
		rotation.y = lerp_angle(rotation.y, net_yaw, minf(1.0, delta * 8.0))
		_spin(to.length() / maxf(delta, 0.001), delta)
		return
	if not moving:
		return
	if _wait > 0.0:
		_wait -= delta * clampf(Npc.time_scale, 1.0, 3.0)    # (shorter stops when the clock runs fast, like the driving)
		return
	if _i >= _pts.size():
		park()
		var cb := _done
		_done = Callable()
		if cb.is_valid():
			cb.call()
		return
	var target: Vector3 = _pts[_i][0]
	var rev: bool = _pts[_i][1]
	var to := target - global_position
	to.y = 0.0
	var dist := to.length()
	# Slow down for corners (how much the road turns over the next few points)
	var want := CRUISE * clampf(Npc.time_scale, 1.0, 3.0)
	if rev:
		want = 2.0
	elif _i + 2 < _pts.size():
		var d0: Vector3 = (_pts[mini(_i + 2, _pts.size() - 1)][0] - target)
		if to.length() > 0.01 and d0.length() > 0.01 and to.normalized().dot(d0.normalized()) < 0.8:
			want = CORNER
	# (look where the car is actually going: behind it when it's backing up)
	if _blocked(to.normalized() if dist > 0.01 else global_basis.z, minf(5.5, dist + 1.5) if rev else maxf(5.5, 2.5 + speed * speed / (2.0 * _brake()))) \
			or _path_blocked(minf(3.0, dist + 1.5) if rev else 3.0 + speed * speed / (2.0 * _brake())):
		want = 0.0
		_blocked_t += delta
		_stuck_t += delta
		if _blocked_t > 3.0:
			_blocked_t = -4.0
			honk()
		if _stuck_t > 8.0 and _in_standoff():
			# two cars waiting on each other: this one squeezes past (instead of waiting forever)
			_stuck_t = 0.0
			_yield_until = Time.get_ticks_msec() + 3500
	else:
		_blocked_t = 0.0
		_stuck_t = 0.0
	speed = move_toward(speed, want, delta * (_brake() if want < speed else 3.0 * clampf(Npc.time_scale, 1.0, 3.0)))
	var step := speed * delta
	if dist <= maxf(step, 0.05):
		global_position = Vector3(target.x, 0, target.z)
		if stops.has(_i):
			_wait = float(stops[_i])
			speed = 0.0
			if on_stop.is_valid():
				on_stop.call(_i)
		_i += 1
	else:
		global_position += to / dist * step
		var face := to if not rev else -to
		rotation.y = lerp_angle(rotation.y, atan2(face.x, face.z), minf(1.0, delta * 5.0))
	_spin(speed * (-1.0 if rev else 1.0), delta)
	_engine.pitch_scale = (0.8 if kind == "fire" else 1.0) + speed / CRUISE * 0.6


func _spin(spd: float, delta: float) -> void:
	for w in _wheels:
		if w.get_child_count() > 0:
			(w.get_child(0) as Node3D).rotate_x(spd * delta / 0.34)


## Is someone (or something) right in front?
func _blocked(dir: Vector3, reach := 5.5) -> bool:
	if main == null:
		return false
	var fwd := dir
	fwd.y = 0.0
	if fwd.length() < 0.01:
		return false
	fwd = fwd.normalized()
	var me := global_position + fwd * (length / 2.0)
	var check := func(p: Vector3, half_w: float) -> bool:
		var d := p - me
		d.y = 0.0
		var ahead := d.dot(fwd)
		var side := absf(d.cross(fwd).y)
		return ahead > -0.5 and ahead < reach and side < width / 2.0 + half_w - 0.35
	for s in main.sims.values():
		var sim := s as Sim
		if sim.visible and sim.level == 0 and check.call(sim.global_position, 0.35):
			last_block = sim.character_name
			return true
	for n in main.npcs:
		var npc := n as Npc
		if not npc.away and npc.role != "pet" and check.call(npc.global_position, 0.35):
			last_block = npc.display_name
			return true
	for c in main.room.get("cars", []):
		var car := c as Car
		if check.call(car.global_position, car.width / 2.0) and (car.global_position - me).length() < 6.5:
			last_block = car.key
			return true
	if main.town_life and Time.get_ticks_msec() >= _yield_until:
		var facing := global_basis.z
		facing.y = 0.0
		facing = facing.normalized()
		for v in main.town_life.vehicles:
			var o := v as NpcVehicle
			if o == self or not o.visible:
				continue
			# the whole length of the other vehicle (a fire engine crossing in front is more than its middle)
			var oc := o.global_position
			var of := o.global_basis.z
			of.y = 0.0
			of = of.normalized() * maxf(0.0, o.length / 2.0 - 0.6)
			if check.call(oc, o.width / 2.0) or check.call(oc + of, o.width / 2.0) or check.call(oc - of, o.width / 2.0):
				last_block = o.key
				return true
			# already nosing into one that's just ahead: stay put until it pulls away
			var d := oc - global_position
			d.y = 0.0
			var along := d.dot(facing)
			if along > 0.0 and along < (length + o.length) / 2.0 - 0.2 and absf(d.cross(facing).y) < (width + o.width) / 2.0 - 0.2 \
					and (fwd.dot(facing) > 0.0):
				last_block = o.key
				return true
	return false


## How hard it brakes (harder when the clock runs fast and it's driving faster, so it can still stop in time).
func _brake() -> float:
	return 6.0 * clampf(Npc.time_scale, 1.0, 3.0)


## The stretch of road this vehicle is about to drive (its own path, round corners and U-turns
## too): is another town vehicle's body on it? Checks the other's whole length, front to back.
func _path_blocked(reach: float) -> bool:
	if main == null or main.town_life == null or Time.get_ticks_msec() < _yield_until:
		return false
	# points along the path ahead, every half meter, starting just past the front bumper
	var samples: Array[Vector3] = []
	var prev := global_position
	var travelled := 0.0
	var k := _i
	var lead := length / 2.0
	while k < _pts.size() and travelled < reach + lead:
		var p: Vector3 = _pts[k][0]
		p.y = 0.0
		var seg := p - Vector3(prev.x, 0, prev.z)
		var sl := seg.length()
		var u := 0.0
		while u < sl:
			var q := Vector3(prev.x, 0, prev.z) + seg * (u / maxf(sl, 0.001))
			if travelled + u > lead * 0.5:
				samples.append(q)
			u += 0.5
		travelled += sl
		prev = p
		k += 1
	if samples.is_empty():
		return false
	for v in main.town_life.vehicles:
		var o := v as NpcVehicle
		if o == self or not o.visible:
			continue
		var oc := o.global_position
		oc.y = 0.0
		if oc.distance_to(global_position) > reach + lead + o.length:
			continue
		# (one that's behind this one isn't in its way, even if they're tangled up: the front one drives on)
		var back := Vector3(_pts[mini(_i, _pts.size() - 1)][0].x, 0, _pts[mini(_i, _pts.size() - 1)][0].z) - Vector3(global_position.x, 0, global_position.z)
		if back.length() > 0.05 and (oc - Vector3(global_position.x, 0, global_position.z)).dot(back.normalized()) < -0.5:
			continue
		var of := o.global_basis.z
		of.y = 0.0
		of = of.normalized()
		var near := (width + o.width) / 2.0 - 0.15
		var half := maxf(0.0, o.length / 2.0 - o.width / 2.0)
		for q in samples:
			# distance from the sample to the other's center line (a capsule, front to back)
			var rel := q - oc
			var along := clampf(rel.dot(of), -half, half)
			if (rel - of * along).length() < near:
				last_block = o.key
				return true
	return false


## A ring of vehicles each waiting on the next (two head-on, or three at a junction): follow who's
## waiting for whom; if it comes back round to this one, the one with the last name in the ring
## squeezes through (just one of them, so the ring breaks).
func _in_standoff() -> bool:
	if main == null or main.town_life == null:
		return false
	var ring: Array = [self]
	var cur: NpcVehicle = self
	for _hop in 6:
		var nxt: NpcVehicle = null
		for v in main.town_life.vehicles:
			if (v as NpcVehicle).key == cur.last_block:
				nxt = v
				break
		if nxt == null or not nxt.moving or nxt._wait > 0.0 or nxt._stuck_t < 2.0:
			return false
		if nxt == self:
			for o: NpcVehicle in ring:
				if o.key > key:
					return false
			return true
		if ring.has(nxt):
			return false
		ring.append(nxt)
		cur = nxt
	return false


func honk() -> void:
	if main and main.audio:
		main.audio.play_at("horn", global_position + Vector3(0, 1.0, 0), -6.0)


## Rounded corners: each sharp turn becomes a short curve.
func _smooth(points: Array) -> Array:
	if points.size() < 3:
		return points.duplicate()
	var out := [points[0]]
	for k in range(1, points.size() - 1):
		var a: Vector3 = points[k - 1][0]
		var b: Vector3 = points[k][0]
		var c: Vector3 = points[k + 1][0]
		var rev: bool = points[k][1]
		var la := (b - a).length()
		var lc := (c - b).length()
		var r := minf(4.0, minf(la, lc) * 0.45)
		if rev or bool(points[k + 1][1]) != rev or r < 0.3 or la < 0.01 or lc < 0.01:
			out.append(points[k])
			continue
		var p0 := b + (a - b).normalized() * r
		var p2 := b + (c - b).normalized() * r
		for s in 7:
			var t := float(s) / 6.0
			var q := p0.lerp(b, t).lerp(b.lerp(p2, t), t)
			out.append([q, false])
	out.append(points[points.size() - 1])
	return out


# ---------------------------------------------------------------- online

func net_state() -> Array:
	return [global_position.x, global_position.z, rotation.y, (1.0 if moving else 0.0) + (2.0 if siren else 0.0) + (4.0 if not visible else 0.0)]


func net_apply(x: float, z: float, yaw: float, flags: int) -> void:
	puppet = true
	net_pos = Vector3(x, 0, z)
	net_yaw = yaw
	visible = flags & 4 == 0
	var mv := flags & 1 != 0
	if mv != moving:
		moving = mv
		if _cab:
			_cab.visible = mv
		if mv:
			_engine.play()
		else:
			_engine.stop()
	var sr := flags & 2 != 0
	if sr != siren:
		set_siren(sr)


# ================================================================ RoadNet

static func lane_z(street: String, dir: float) -> float:
	return float(STREETS[street]) + dir * LANE


## Oak Avenue's lane: heading south (+z) keeps to the west side.
static func oak_x(south: bool) -> float:
	return OAK_X - LANE if south else OAK_X + LANE


## A U-turn on `street` at x, from heading `dir` to heading -dir.
static func uturn(street: String, x: float, dir: float) -> Array:
	var zc: float = STREETS[street]
	var out := []
	for s in range(1, 8):
		var t := float(s) / 8.0
		out.append([Vector3(x + dir * 3.0 * sin(PI * t), 0, zc + dir * LANE * cos(PI * t)), false])
	out.append([Vector3(x, 0, zc - dir * LANE), false])
	return out


## From (street, x, heading dir) to (street2, x2): lane points to follow. Ends
## heading east on the new street (or whichever way it needed to go on the same street).
static func plan(street: String, x: float, dir: float, street2: String, x2: float) -> Array:
	var out := []
	if street == street2:
		var need := signf(x2 - x)
		if need == 0.0:
			return out
		if need != dir:
			out.append_array(uturn(street, x + dir * 2.0, dir))
		out.append([Vector3(x2, 0, lane_z(street2, need)), false])
		return out
	if dir > 0.0:
		out.append_array(uturn(street, x + 2.0, dir))
	var south := float(STREETS[street2]) > float(STREETS[street])
	var ox := oak_x(south)
	out.append([Vector3(ox, 0, lane_z(street, -1.0)), false])
	out.append([Vector3(ox, 0, lane_z(street2, 1.0)), false])
	out.append([Vector3(x2, 0, lane_z(street2, 1.0)), false])
	return out


## Out of a garage, a lot or a parking space onto `street`, to head `dir`.
## Parked nose-in (facing away from the street), it backs out first.
static func leave_depot(v: NpcVehicle, street: String, dir: float) -> Array:
	var p := v.global_position
	var lz := lane_z(street, dir)
	var to_street := signf(lz - p.z)
	var facing := v.global_basis.z
	var out := [[p, false]]
	if facing.z * to_street < 0.0 and absf(facing.z) > 0.5:
		out.append([Vector3(p.x, 0, lz - to_street * 0.5), true])       # back out into the street
		out.append([Vector3(p.x + dir * 4.0, 0, lz), false])
	else:
		out.append([Vector3(p.x, 0, lz), false])
		out.append([Vector3(p.x + dir * 4.0, 0, lz), false])
	return out


## Back into a spot at (x, z) off `street`, coming along it heading `dir`: pull
## past it, then reverse in (so it's parked nose-out, ready to go).
static func enter_depot(street: String, dir: float, at: Vector3) -> Array:
	var lz := lane_z(street, dir)
	var side := signf(at.z - lz)
	return [[Vector3(at.x - dir * 3.0, 0, lz), false], [Vector3(at.x + dir * 4.5, 0, lz - side * 0.6), false],
		[Vector3(at.x + dir * 1.2, 0, lz + side * 1.6), true], [Vector3(at.x, 0, lz + side * 4.0), true], [at, true]]


## Which street a point is on (or "" if none), and which way along it.
static func street_at(p: Vector3) -> String:
	for s in STREETS:
		if absf(p.z - float(STREETS[s])) < 5.5:
			return s
	return ""
