class_name Npc
extends SmartObject
## Someone who lives in Maple Grove but isn't played by anyone: the parents at
## home, the folks out for a walk, Molly at her lemonade stand, the ice cream
## man and Mr. Gruber at the Gazette. You click them to talk (content.gd gives
## them their activities by `kind`).
##
## They walk the same grid the kids do. Whoever's on their way to talk to them
## makes them stop and wait (and turn to face them).
##
## Online, the host moves everyone; friends' computers just show them where the
## host says (`puppet`).

const SPEED := 1.05
## Everyone walks faster when time is sped up (main.gd sets this, like it does for the kids).
static var time_scale := 1.0

signal staff_door(npc: Npc, arrived: bool)     # a shopkeeper got to the shop door (to open up, or after locking up)

var role := ""                  # "parent", "kid", "walker", "vendor", "pet", "thief"
var look := {}
var lines: Array = []           # what they say when you chat
var spots := {}                 # parents: name -> [Vector3, yaw degrees] ("kitchen", "living", "bed", "door")
var schedule: Array = []        # parents: [[from hour, to hour, spot, weekdays or []], ...]
var route: Array = []           # walkers: points to walk between, in a loop
var hours := Vector2(0, 24)     # vendors: when they're at work (otherwise they're not there)
var days: Array = []            # vendors: which days they work (empty = every day)
var months: Array = []          # ...and which months (empty = all year: teachers get the summer off)
static var month_now := 6       # (main.gd keeps this up to date)
var commute := false            # vendors: walk in from the edge of town before opening, and home after closing
var edge := Vector3.ZERO        # ...where they come from (and go back to)
var door_out := Vector3.ZERO    # ...just outside their shop's door
var workplace := ""             # ...which shop door they open (see main.gd shop doors)
var shift := "home"             # home, to_door, to_post, working, leaving, to_edge
var lead := 0.75                # hours before opening they set off
var driving := false            # off driving a car or truck (see NpcVehicle): not here
var chat_cooldown := 0          # (ms) no new chats until then
var scripted: Callable          # TownLife: called when they get where it sent them
var grid: AStarGrid2D
var walking := false
var lying := false              # asleep in bed (parents, at night)
var talk_dist := 0.85           # how far in front of them you stand (farther across a counter)
var away := false               # not here right now (at work, asleep, gone home)
var puppet := false
var net_pos := Vector3.ZERO
var net_yaw := 0.0

var _path := PackedVector2Array()
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _body: Node3D
var _tag: Label3D
var _yaw := 0.0
var _phase := 0.0
var _route_i := 0
var _rest_until := 0.0          # (ms) a pause at the end of a walk
var _hold_until := 0
var _talker: Node3D = null
var _spot := ""
var _goal_spot := ""


func setup(p_name: String, p_role: String, p_look: Dictionary, p_lines: Array, p_home: String, p_grid: AStarGrid2D) -> void:
	display_name = p_name
	name = p_name.replace(" ", "_").replace(".", "").replace("'", "")
	role = p_role
	look = p_look
	lines = p_lines
	home = p_home
	grid = p_grid
	kind = "npc_" + role
	shared = true


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var parts: Dictionary
	if role == "pet":
		parts = Pets.build(self, look)
		RoomBuilder.add_shape(self, Vector3(0.4, 0.6, 0.7), Vector3(0, 0.3, 0))
	else:
		RoomBuilder.add_shape(self, Vector3(0.55, 1.75, 0.45), Vector3(0, 0.88, 0))
		parts = Looks.build(self, look)
	_legs.assign(parts["legs"])
	_arms.assign(parts["arms"])
	_body = parts["body"]
	for mi in _body.find_children("*", "MeshInstance3D", true, false):
		add_material((mi as MeshInstance3D).material_override)
	_tag = Label3D.new()
	_tag.text = display_name
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.font_size = 30
	_tag.outline_size = 10
	_tag.modulate = Palette.PAPER.darkened(0.08)
	_tag.outline_modulate = Palette.INK
	_tag.position = Vector3(0, 2.05 if look.get("adult", false) else (0.95 if role == "pet" else 1.85), 0)
	_tag.visible = false
	add_child(_tag)
	_yaw = rotation.y
	refresh_points()


## Where you stand to talk to them: right in front.
func refresh_points() -> void:
	var fwd := -global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var p := global_position + fwd * talk_dist
	approach_point = Vector3(p.x, 0, p.z)
	use_point = approach_point
	look_point = global_position + Vector3(0, 0.35 if role == "pet" else 1.45, 0)


var _tag_always := false
var _lit_tag := false


func set_highlight(on: bool) -> void:
	super.set_highlight(on)
	_lit_tag = on
	if _tag:
		_tag.visible = on or _tag_always


## Keep the name tag showing (family members, when you're near them).
func set_tag_always(on: bool) -> void:
	if on == _tag_always:
		return
	_tag_always = on
	if _tag:
		_tag.visible = on or _lit_tag


## `sub` = a second line under the name ("Kevin's mom"); `own` = your own
## family (the tag shows in gold).
func set_title(t: String, sub := "", own := false) -> void:
	display_name = t
	if _tag:
		_tag.text = t if sub == "" else "%s\n%s" % [t, sub]
		_tag.modulate = Palette.GOLD if own else Palette.PAPER.darkened(0.08)
		_tag.font_size = 34 if own else 30


## Put them somewhere right away (no walking).
## (`yaw_deg` the way furniture is turned: 0 = facing +z, like the spots in the builders.)
func place(pos: Vector3, yaw_deg: float) -> void:
	_place_raw(pos, deg_to_rad(yaw_deg) + PI)


func _place_raw(pos: Vector3, yaw: float) -> void:
	global_position = pos
	rotation.y = yaw
	_yaw = rotation.y
	_path.clear()
	walking = false
	refresh_points()


## Into bed for the night: lie on the bed at `pos` (the foot of their side), head toward the headboard.
func lie_down(pos: Vector3, yaw_deg: float) -> void:
	place(pos, yaw_deg)
	lying = true
	_body.rotation.x = -PI / 2.0
	_body.position = Vector3(0, 0.66, 0)
	for i in 2:
		_legs[i].rotation.x = 0.0
		_arms[i].rotation.x = 0.0


func get_up() -> void:
	if not lying:
		return
	lying = false
	_body.rotation.x = 0.0
	_body.position = Vector3.ZERO
	if spots.has("bed"):
		place(spots["bed"][0], float(spots["bed"][1]))


## Somewhere to stand that isn't inside the furniture.
func _snap(p: Vector3) -> Vector3:
	if grid == null:
		return p
	var c := _cell(p)
	if not grid.is_point_solid(c):
		return p
	var f := _free_near(c)
	return Vector3((f.x + 0.5) * grid.cell_size.x, p.y, (f.y + 0.5) * grid.cell_size.y)


func set_away(on: bool) -> void:
	if on == away:
		return
	away = on
	visible = not on
	collision_layer = 0 if on else 1
	if on:
		_path.clear()
		walking = false


## Someone's coming over to talk: stop and wait for them (and look at them).
func hold(by: Node3D, seconds := 25.0) -> void:
	_talker = by
	_hold_until = Time.get_ticks_msec() + int(seconds * 1000.0)
	if walking:
		_path.clear()
		walking = false
	refresh_points()


func release() -> void:
	_hold_until = mini(_hold_until, Time.get_ticks_msec() + 1500)


func held() -> bool:
	return Time.get_ticks_msec() < _hold_until


## Something to say when you chat.
func line() -> String:
	if lines.is_empty():
		return "Nice day, isn't it?"
	return String(lines[randi() % lines.size()])


## Once a game minute (host / offline): follow the schedule.
func on_minute(hour: float, weekday: int) -> void:
	if puppet or driving or scripted.is_valid():
		return
	match role:
		"parent", "kid":
			var want := _want(hour, weekday)
			if want != _goal_spot:
				_goal_spot = want
				_go_spot(want)
		"vendor":
			_vendor_minute(hour, weekday)
		"walker":
			var out := Activity.in_window(hour, hours.x, hours.y)
			if not out and not away and not walking and not held():
				set_away(true)
			elif out and away:
				set_away(false)
				_next_leg()


func _want(hour: float, weekday: int) -> String:
	for e in schedule:
		var on_days: Array = e[3]
		if Activity.in_window(hour, float(e[0]), float(e[1])) and (on_days.is_empty() or on_days.has(weekday)):
			return e[2]
	return "living"


## Is this shopkeeper due at work now (counting the walk in)?
func on_shift(hour: float, weekday: int, early := 0.0) -> bool:
	var start := fposmod(hours.x - early, 24.0)
	if not Activity.in_window(hour, start, hours.y):
		return false
	if not months.is_empty() and not months.has(month_now):
		return false
	return days.is_empty() or days.has(weekday)


## Shopkeepers: walk in from the edge of town before opening (and open the door),
## stand at their post, and walk home after closing (locking up behind them).
func _vendor_minute(hour: float, weekday: int) -> void:
	var due := on_shift(hour, weekday, lead if commute else 0.0)
	if not commute:
		set_away(not due)
		shift = "working" if due else "home"
		return
	match shift:
		"home":
			if due:
				set_away(false)
				_place_raw(_snap(edge), _yaw)
				shift = "to_door"
				_walk_to(door_out)
		"working", "to_post":
			if not due and not held():
				shift = "leaving"
				_walk_to(door_out)
		"to_door":
			if not due:
				shift = "to_edge"
				_walk_to(edge)


## Jump straight to where they'd be at this hour (a new or loaded game).
func settle(hour: float, weekday: int) -> void:
	_hold_until = 0
	match role:
		"parent", "kid":
			var want := _want(hour, weekday)
			_goal_spot = want
			_spot = want
			set_away(false)
			if want == "asleep" and spots.has("sleep"):
				lie_down(spots["sleep"][0], float(spots["sleep"][1]))
			elif spots.has(want):
				lying = false
				_body.rotation.x = 0.0
				_body.position = Vector3.ZERO
				place(_snap(spots[want][0]), float(spots[want][1]))
				if (spots[want] as Array).size() > 2:
					set_away(true)       # (off at work, on the bus)
		"thief":
			if not scripted.is_valid():
				set_away(true)
		"pet":
			if not wander.is_empty():
				var r: Rect2 = wander[0]
				_place_raw(_snap(Vector3(r.get_center().x, 0, r.get_center().y)), randf() * TAU)
			_rest_until = Time.get_ticks_msec() + randf_range(1000.0, 6000.0)
		"vendor":
			var due := on_shift(hour, weekday)
			if spots.has("post"):
				place(spots["post"][0], float(spots["post"][1]))
			set_away(not due)
			shift = "working" if due else "home"
		"walker":
			if route.is_empty():
				return
			_route_i = randi() % route.size()
			var a: Vector3 = route[_route_i]
			var b: Vector3 = route[(_route_i + 1) % route.size()]
			var p := a.lerp(b, randf_range(0.1, 0.8))
			_place_raw(p, atan2(-(b - a).x, -(b - a).z))
			set_away(not Activity.in_window(hour, hours.x, hours.y))
			if not away:
				_walk_to(b)
				_route_i = (_route_i + 1) % route.size()


func _go_spot(spot: String) -> void:
	# "asleep": walk to the foot of the bed, then get in (see _arrived).
	var target := "bed" if spot == "asleep" else spot
	if not spots.has(target):
		return
	get_up()
	if away:
		set_away(false)          # back from work: off the bus, and walk home from there
	_spot = spot
	_walk_to(_snap(spots[target][0]))


## Walk somewhere for TownLife (the burglar, the officer...). `done` is called on arrival.
func go_to(p: Vector3, done: Callable = Callable()) -> void:
	scripted = done if done.is_valid() else func(): pass
	_hold_until = 0
	_walk_to(p)


## Stop following a script and go back to the usual routine.
func end_script() -> void:
	scripted = Callable()
	_goal_spot = ""


## Two townsfolk stop and talk for a while (TownLife picks who and what they say).
func chat_with(other: Node3D, seconds: float) -> void:
	_talker = other
	_hold_until = Time.get_ticks_msec() + int(seconds * 1000.0)
	if walking:
		_path.clear()
		walking = false
		_resume = true
	chat_cooldown = Time.get_ticks_msec() + int((seconds + 50.0) * 1000.0)


var wander: Array = []          # pets: the rooms they roam (Rect2s)


func _next_leg() -> void:
	if role == "pet":
		if wander.is_empty():
			return
		# (somewhere on the flat floor: not halfway down the basement stairs)
		var p := global_position
		for _try in 8:
			var r: Rect2 = wander[randi() % wander.size()]
			p = Vector3(randf_range(r.position.x + 0.5, r.end.x - 0.5), 0, randf_range(r.position.y + 0.5, r.end.y - 0.5))
			if absf(HouseBuilder.floor_height(p.x, p.z)) < 0.01:
				break
		_walk_to(_snap(p))
		return
	if route.is_empty():
		return
	_route_i = (_route_i + 1) % route.size()
	_walk_to(route[_route_i])


func _walk_to(p: Vector3) -> void:
	if grid == null:
		_place_raw(p, _yaw)
		return
	var from := _cell(global_position)
	var to := _cell(p)
	if grid.is_point_solid(from):
		from = _free_near(from)
	if grid.is_point_solid(to):
		to = _free_near(to)
	_path = grid.get_point_path(from, to)
	if _path.size() > 0:
		_path[_path.size() - 1] = Vector2(p.x, p.z)
		walking = true
	else:
		_place_raw(p, _yaw)
		_arrived()


func _cell(p: Vector3) -> Vector2i:
	var c := Vector2i(floori(p.x / grid.cell_size.x), floori(p.z / grid.cell_size.y))
	c.x = clampi(c.x, grid.region.position.x, grid.region.end.x - 1)
	c.y = clampi(c.y, grid.region.position.y, grid.region.end.y - 1)
	return c


func _free_near(c: Vector2i) -> Vector2i:
	for r in range(1, 10):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if grid.is_in_boundsv(n) and not grid.is_point_solid(n):
					return n
	return c


func _arrived() -> void:
	walking = false
	if scripted.is_valid():
		var cb := scripted
		refresh_points()
		cb.call()
		return
	match role:
		"parent", "kid":
			if _spot == "asleep" and spots.has("sleep"):
				lie_down(spots["sleep"][0], float(spots["sleep"][1]))
			elif spots.has(_spot):
				_yaw = deg_to_rad(float(spots[_spot][1])) + PI
				if (spots[_spot] as Array).size() > 2:
					set_away(true)       # got on the bus to work
		"vendor":
			match shift:
				"to_door":
					staff_door.emit(self, true)
					shift = "to_post"
					if spots.has("post"):
						_walk_to(spots["post"][0])
				"to_post":
					shift = "working"
					if spots.has("post"):
						_yaw = deg_to_rad(float(spots["post"][1])) + PI
				"leaving":
					staff_door.emit(self, false)
					shift = "to_edge"
					_walk_to(edge)
				"to_edge":
					shift = "home"
					set_away(true)
		"walker":
			_rest_until = Time.get_ticks_msec() + randf_range(1500.0, 6000.0)
		"pet":
			_rest_until = Time.get_ticks_msec() + randf_range(4000.0, 14000.0)
	refresh_points()


func _physics_process(delta: float) -> void:
	if away:
		return
	var moving := false
	if not puppet:
		_check_talkers()
	if puppet:
		var to := net_pos - global_position
		to.y = 0.0
		if to.length() > 4.0:
			global_position = Vector3(net_pos.x, global_position.y, net_pos.z)
		else:
			global_position += to * minf(1.0, delta * 8.0)
		moving = to.length() > 0.03
		_yaw = net_yaw
		if moving:
			refresh_points()
	elif held():
		if _talker != null and is_instance_valid(_talker) and not lying:
			var d := _talker.global_position - global_position
			if Vector2(d.x, d.z).length() > 0.2:
				_yaw = atan2(-d.x, -d.z)
	elif walking:
		if _blocked() and Time.get_ticks_msec() - _blocked_since < 3000.0 / maxf(time_scale, 1.0):
			pass   # wait for the kid in the way to pass (but not forever: then squeeze past)
		else:
			var step := SPEED * delta * time_scale * (2.0 if role == "thief" and has_meta("running") else (1.7 if has_meta("skater") else 1.0))
			# (use the whole step, even past several path points: at top speed one step is longer than a grid cell)
			while step > 0.0 and walking and not _path.is_empty():
				var p := _path[0]
				var goal := Vector3(p.x, global_position.y, p.y)
				var to := goal - global_position
				to.y = 0.0
				if to.length() <= step:
					step -= to.length()
					global_position = goal
					_path.remove_at(0)
					if to.length() > 0.001:
						_yaw = atan2(-to.x, -to.z)
					if _path.is_empty():
						_arrived()
				else:
					global_position += to.normalized() * step
					_yaw = atan2(-to.x, -to.z)
					step = 0.0
			moving = true
			refresh_points()
	elif (role == "walker" or role == "pet") and Time.get_ticks_msec() > _rest_until and _rest_until > 0.0:
		_rest_until = 0.0
		_next_leg()
	global_position.y = HouseBuilder.floor_height(global_position.x, global_position.z)
	rotation.y = lerp_angle(rotation.y, _yaw, minf(1.0, delta * 8.0))
	_animate(delta, moving)


var _resume := false


## Is a kid on their way over to talk (or talking)? Then wait for them.
func _check_talkers() -> void:
	if role == "thief":
		return       # (a burglar doesn't stop to chat)
	for s in get_tree().get_nodes_in_group("sims"):
		var sim := s as Sim
		if sim._walk_goal.get("obj") == self or sim.current.get("obj") == self:
			_talker = sim
			_hold_until = Time.get_ticks_msec() + 1200
			if walking:
				walking = false
				_path.clear()
				_resume = true
				refresh_points()
			return
	if _resume and not held():
		_resume = false
		if scripted.is_valid():
			pass
		elif role == "walker" and not route.is_empty():
			_walk_to(route[_route_i])
		elif role == "parent" or role == "kid":
			_go_spot(_spot)
		elif role == "vendor":
			match shift:
				"to_door", "leaving":
					_walk_to(door_out)
				"to_post":
					if spots.has("post"):
						_walk_to(spots["post"][0])
				"to_edge":
					_walk_to(edge)


## A kid standing right in front: wait (they don't walk through people).
var _blocked_since := 0


func _blocked() -> bool:
	var fwd := Vector3(-sin(_yaw), 0, -cos(_yaw))
	for s in get_tree().get_nodes_in_group("sims"):
		var d: Vector3 = (s as Node3D).global_position - global_position
		d.y = 0.0
		if d.length() < 0.75 and d.normalized().dot(fwd) > 0.5:
			if _blocked_since == 0:
				_blocked_since = Time.get_ticks_msec()
			return true
	_blocked_since = 0
	return false


func _animate(delta: float, moving: bool) -> void:
	if lying:
		return
	if has_meta("skater"):
		# Riding a skateboard: knees bent, arms out, a little sway
		var tt := Time.get_ticks_msec() * 0.001
		_legs[0].rotation.x = -0.25
		_legs[1].rotation.x = 0.35
		_arms[0].rotation = Vector3(0.2, 0, -0.6)
		_arms[1].rotation = Vector3(0.2, 0, 0.6)
		_body.position.y = 0.11 + (sin(tt * 3.0) * 0.015 if moving else 0.0)
		_body.rotation.z = sin(tt * 1.6) * 0.06 if moving else 0.0
		return
	if has_meta("boombox"):
		_arms[1].rotation = Vector3(PI * 0.88, 0, -0.25)       # holding the boombox up on the shoulder
	if role == "pet" and has_meta("tail"):
		(get_meta("tail") as Node3D).rotation.y = sin(Time.get_ticks_msec() * (0.016 if held() else 0.005)) * 0.5
	if moving:
		_phase += delta * 8.0
		var s := sin(_phase) * 0.5
		_legs[0].rotation.x = s
		_legs[1].rotation.x = -s
		_arms[0].rotation.x = -s * 0.7
		_arms[1].rotation.x = s * 0.7
		_body.position.y = absf(cos(_phase)) * 0.025
	else:
		var t := minf(1.0, delta * 8.0)
		for i in 2:
			_legs[i].rotation.x = lerpf(_legs[i].rotation.x, 0.0, t)
			_arms[i].rotation.x = lerpf(_arms[i].rotation.x, 0.0, t)
		_body.position.y = 0.0
		if has_meta("seated"):
			# sitting at a desk: knees forward, a little lower (and a hand up now and then)
			for i in 2:
				_legs[i].rotation.x = PI / 2.0
			_body.position.y = -0.36
			_arms[0].rotation.x = 0.9
			_arms[1].rotation.x = (PI * 0.92 if fmod(Time.get_ticks_msec() * 0.001 + float(get_instance_id() % 7), 11.0) < 1.2 else 0.9)
		if has_meta("hands_up"):
			_arms[0].rotation.x = PI * 0.95
			_arms[1].rotation.x = PI * 0.95
		elif held() and role != "pet":
			# Talking with their hands a little.
			_arms[1].rotation.x = 0.35 + sin(Time.get_ticks_msec() * 0.006) * 0.25


## A punk on a skateboard (the skate park).
func add_skateboard(color := Color("F7D046")) -> void:
	set_meta("skater", true)
	var b := Node3D.new()
	b.name = "Skateboard"
	add_child(b)
	RoomBuilder.box(b, Vector3(0.24, 0.025, 0.82), Vector3(0, 0.075, 0), color)
	for wz in [-0.28, 0.28]:
		RoomBuilder.box(b, Vector3(0.26, 0.05, 0.06), Vector3(0, 0.035, wz), Color("F2F0E6"))


## A boombox up on the shoulder (TownLife plays the music where they are).
func add_boombox() -> void:
	set_meta("boombox", true)
	var b := Node3D.new()
	b.name = "Boombox"
	_body.add_child(b)
	b.position = Vector3(0.36, 1.32, 0.02)
	RoomBuilder.box(b, Vector3(0.18, 0.28, 0.5), Vector3.ZERO, Color("2B2B30"))
	for sz in [-0.13, 0.13]:
		RoomBuilder.box(b, Vector3(0.02, 0.14, 0.14), Vector3(0.1, 0, sz), Color("8A8E94"))
	RoomBuilder.box(b, Vector3(0.02, 0.05, 0.1), Vector3(0.1, 0.1, 0), Color("C0322A"))


# ---------------------------------------------------------------- online

func net_state() -> Array:
	return [snappedf(global_position.x, 0.01), snappedf(global_position.z, 0.01), snappedf(_yaw, 0.01), away, lying]


func net_apply(d: Array) -> void:
	net_pos = Vector3(float(d[0]), 0, float(d[1]))
	net_yaw = float(d[2])
	set_away(bool(d[3]))
	var l: bool = d.size() > 4 and bool(d[4])
	if l != lying:
		if l:
			lie_down(net_pos, rad_to_deg(net_yaw) - 180.0)
		else:
			lying = false
			_body.rotation.x = 0.0
			_body.position = Vector3.ZERO


# ---------------------------------------------------------------- speech

## A word bubble over their head for a moment ("Ouch!").
func say(text: String, seconds := 2.5) -> void:
	Props.bubble(self, text, seconds, 2.35 if look.get("adult", false) else 2.1)
