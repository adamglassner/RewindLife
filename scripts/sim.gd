class_name Sim
extends CharacterBody3D
## A resident: Jamie, or (online) one of the neighbor kids. Walks a grid path,
## works through an activity queue, and picks things to do alone when Free Will is on.
##
## Online, the host runs every Sim. On the other players' computers each Sim is a
## "puppet" that just follows what the host sends (see net.gd); a player's own
## puppet is moved locally while they walk it with WASD or a stick.

signal queue_changed
signal activity_started(act: Activity, obj: SmartObject)
signal activity_finished(act: Activity, obj: SmartObject)
signal notice(text: String)
signal delivery_ordered(kind: String)
signal teleported
signal paid(amount: float, reason: String)
signal bike_event(what: String)        # "bought", "mount", "park"
signal called(home: String)           # a phone call to this home's kid went through
signal bought(id: String)              # something from Catalog (main.gd puts it where it goes)

## What the items are called in messages.
const ITEM_NAMES := {"tape": "a rented tape", "book": "a library book", "papers": "the newspapers"}

enum State { IDLE, WALKING, DOING }

const WALK_SPEED := 1.7
const BUSY_MINUTES := 4  # how long Jamie listens to a busy signal
const K := 0.0105  # body-part units from the mockup -> meters

## The six kids. Alone you play Jamie; online, everyone picks who to play.
## "look" is each one's starting appearance (see looks.gd); players can change it.
const CHARACTERS := [
	{"name": "Jamie", "full": "Jamie", "home": "jamie", "spawn": Vector3(6.4, 0, 3.2), "yaw": 60.0,
		"look": {"gender": "girl", "hair": "mullet", "hair_color": 1, "skin": 1, "outfit": 0}},
	{"name": "Danny", "full": "Danny Henderson", "home": "hendersons", "spawn": Vector3(-9.0, 0, 3.0), "yaw": 0.0,
		"look": {"gender": "boy", "hair": "curtains", "hair_color": 2, "skin": 0, "outfit": 2}},
	{"name": "Rosa", "full": "Rosa Garcia", "home": "garcias", "spawn": Vector3(26.5, 0, 3.0), "yaw": 0.0,
		"look": {"gender": "girl", "hair": "side_pony", "hair_color": 0, "skin": 3, "outfit": 5}},
	{"name": "Kevin", "full": "Kevin Nguyen", "home": "nguyens", "spawn": Vector3(5.0, 0, 31.0), "yaw": 180.0,
		"look": {"gender": "boy", "hair": "bowl", "hair_color": 0, "skin": 1, "outfit": 4}},
	{"name": "Stacy", "full": "Stacy Kowalski", "home": "kowalskis", "spawn": Vector3(-9.0, 0, 31.0), "yaw": 180.0,
		"look": {"gender": "girl", "hair": "teased", "hair_color": 4, "skin": 0, "outfit": 1}},
	{"name": "Marcus", "full": "Marcus Parker", "home": "parkers", "spawn": Vector3(23.0, 0, 31.0), "yaw": 180.0,
		"look": {"gender": "boy", "hair": "high_top", "hair_color": 0, "skin": 4, "outfit": 3}},
]

var state := State.IDLE
var needs := Needs.new()
var queue: Array = []            # [{"obj": SmartObject, "act": Activity}, ...]
var current: Dictionary = {}     # the job being done right now
var minutes_done := 0
var idle_minutes := 0
var free_will := true
var money := 42.5                # allowance, in dollars
var hidden := false              # true while driving (in the car)
var slot := 0                    # which character (CHARACTERS index)
var character_name := "Jamie"
var home := "jamie"
var look := {}                   # appearance (see looks.gd)
var level := 0                   # 0 = the neighborhood, 1 = the attics and basements (built underground)
var grids: Array = []            # one walking grid per level
var portals: Array = []          # doors between the levels (SmartObjects with portal_to)
var job := ""                    # "paper" = has the paper route
var paper_day := -1              # the day the papers were last picked up
var allowance_given := false     # this play session (it resets every time you start playing)
var memories := {}               # Memory Moments found (memory id -> true)
var owned := {}                  # things you bought and keep (Catalog ids -> true)
var items := {}                  # things you're carrying: "tape"/"book" -> {"title", "due" (game time)}
var bike := false                # owns a bike (from Spoke & Pedal)
var riding := false              # ...and is riding it right now
var chores_done := {}            # chore id -> the day it was last done (see chores.gd)
## Online, on a player's computer: true for every Sim (the host runs them).
var puppet := false
var net_pos := Vector3.ZERO      # where the host says this Sim is
var net_yaw := 0.0
var net_jobs: Array = []         # the host's Up Next list for this Sim
var local_control := false       # a player is walking their own puppet right now
var _ignore_net_until := 0
var _remote_manual_until := 0    # host: a remote player is walking this Sim
var objects: Array = []
var grid: AStarGrid2D
var clock: GameClock
var visual: Node3D

var _path := PackedVector2Array()
var _walk_goal: Dictionary = {}
var _pose := "stand"
var _walk_phase := 0.0
var _bored_minutes := 0
var _surface := 0.45
var _cooldown := {}   # Activity -> game time (unix seconds) when Free Will may pick it again
var _moving := false
var _manual := false
var _face_yaw := 0.0
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _name_tag: Label3D


func setup(p_grid: AStarGrid2D, p_clock: GameClock, p_objects: Array, p_slot := 0) -> void:
	grid = p_grid
	clock = p_clock
	objects = p_objects
	slot = p_slot
	var ch: Dictionary = CHARACTERS[slot]
	character_name = ch["name"]
	home = ch["home"]
	name = character_name
	if look.is_empty():
		look = (ch["look"] as Dictionary).duplicate()


func _ready() -> void:
	add_to_group("sims")
	collision_layer = 4
	collision_mask = 1 | 2 | 32 | 64   # 32 = the invisible edge of the walkable world, 64 = neighbors' doors (knock first)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.24
	cap.height = 1.5
	shape.shape = cap
	shape.position.y = 0.85
	add_child(shape)
	_build_body()
	_face_yaw = rotation.y


# ---------------------------------------------------------------- body

func _build_body() -> void:
	visual = Node3D.new()
	add_child(visual)
	var parts := Looks.build(visual, look)
	_legs.assign(parts["legs"])
	_arms.assign(parts["arms"])

	_name_tag = Label3D.new()
	_name_tag.text = character_name
	_name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_tag.font_size = 40
	_name_tag.outline_size = 12
	_name_tag.modulate = Palette.PAPER
	_name_tag.outline_modulate = Palette.INK
	_name_tag.position = Vector3(0, 1.95, 0)
	_name_tag.no_depth_test = true
	add_child(_name_tag)


## Change how this kid looks (hair, clothes...) and rebuild the body.
func set_look(new_look: Dictionary) -> void:
	look = Looks.normalized(new_look)
	if visual == null:
		return
	var was_visible := visual.visible
	for c in visual.get_children():
		c.queue_free()
	_legs.clear()
	_arms.clear()
	var parts := Looks.build(visual, look)
	_legs.assign(parts["legs"])
	_arms.assign(parts["arms"])
	visual.visible = was_visible
	_set_pose(_pose, _surface)


func set_view_mode(first_person: bool, show_tag: bool) -> void:
	visual.visible = not first_person and not hidden
	_name_tag.visible = show_tag and not hidden


## Jamie gets in (or out of) a car: hidden and not solid while driving.
func set_hidden(on: bool) -> void:
	hidden = on
	visible = not on
	collision_layer = 0 if on else 4
	if on:
		_path.clear()
		_walk_goal = {}
		_manual = false


## Put Jamie down somewhere and forget any walk in progress.
func place(pos: Vector3, yaw: float) -> void:
	global_position = pos
	_face_yaw = yaw
	rotation.y = yaw
	_path.clear()
	_walk_goal = {}
	state = State.IDLE
	_set_pose("stand")


func eye_height() -> float:
	match _pose:
		"sit", "read":
			return _surface + 0.7
		"lie":
			return _surface + 0.25
	return 1.55


## Where Jamie's eyes are, for the first-person camera. Lying down, the head is
## behind the body's center (Jamie faces her feet).
func eye_point() -> Vector3:
	if _pose == "lie":
		return global_position + global_basis.z * 0.7 + Vector3(0, _surface + 0.3, 0)
	return global_position + Vector3(0, eye_height(), 0)


## True if Jamie is about to walk through `point` (used to open doors in time).
func heading_through(point: Vector3, radius := 0.45) -> bool:
	if _manual:
		return true
	for i in mini(5, _path.size()):
		if Vector2(_path[i].x - point.x, _path[i].y - point.z).length() < radius:
			return true
	return false


func is_lying() -> bool:
	return _pose == "lie"


# ---------------------------------------------------------------- queue

## `by_player` = the player chose this (Free Will passes false).
func enqueue(obj: SmartObject, act: Activity, by_player := true) -> void:
	queue.append({"obj": obj, "act": act, "player": by_player})
	queue_changed.emit()
	if state == State.IDLE and not _manual:
		_start_next()


func walk_here(target: Vector3) -> void:
	if state == State.DOING:
		_stop_current(false)
	_walk_goal = {}
	_go(target)


## Entries for the UI: the active job first, then the queue.
func jobs() -> Array:
	if puppet:
		return net_jobs
	var out := []
	if not current.is_empty():
		var act: Activity = current["act"]
		if act.until_rested:
			out.append({"title": act.title, "progress": needs.value("energy") / 100.0, "active": true,
				"ends": "until rested"})
		elif act.drive:
			out.append({"title": act.title, "progress": 1.0, "active": true, "ends": "behind the wheel"})
		else:
			var total := BUSY_MINUTES if current.get("busy", false) else act.minutes
			out.append({"title": act.title, "progress": float(minutes_done) / total, "active": true,
				"ends": _ends_label(total - minutes_done)})
	elif not _walk_goal.is_empty():
		out.append({"title": (_walk_goal["act"] as Activity).title, "progress": 0.0, "active": true, "ends": "on the way"})
	elif riding:
		out.append({"title": "Riding Your Bike", "progress": 1.0, "active": true, "ends": "X to hop off"})
	for j in queue:
		out.append({"title": (j["act"] as Activity).title, "progress": 0.0, "active": false, "ends": ""})
	return out


func _ends_label(minutes_left: int) -> String:
	var t := clock.unix_time + minutes_left * 60
	var d := Time.get_datetime_dict_from_unix_time(t)
	var h := int(d["hour"])
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "until %d:%02d %s" % [h12, int(d["minute"]), "AM" if h < 12 else "PM"]


func cancel(index: int) -> void:
	var has_active := not current.is_empty() or not _walk_goal.is_empty() or riding
	if has_active and index == 0:
		if not current.is_empty():
			_stop_current(false)
		elif _walk_goal.is_empty() and riding:
			dismount()
		else:
			_walk_goal = {}
			_path.clear()
			state = State.IDLE
		idle_minutes = -20  # give the player a moment before Free Will kicks in
	else:
		var qi := index - (1 if has_active else 0)
		if qi >= 0 and qi < queue.size():
			queue.remove_at(qi)
	queue_changed.emit()


## The floor height here, on this Sim's level (stairs slope; attics and
## basements are built underground, at RoomBuilder.INTERIOR_Y).
func floor_at(x: float, z: float) -> float:
	if level == 1:
		return RoomBuilder.INTERIOR_Y
	return HouseBuilder.floor_height(x, z)


func set_level(l: int) -> void:
	level = l
	if grids.size() > l and grids[l] != null:
		grid = grids[l]


## Go through a door to another level (the attic, the basement, or back).
func teleport_to(dest: SmartObject) -> void:
	set_level(dest.level)
	_path.clear()
	var p := dest.approach_point
	global_position = Vector3(p.x, floor_at(p.x, p.z), p.z)
	net_pos = global_position
	_face_point(dest.approach_point * 2.0 - dest.look_point)
	rotation.y = _face_yaw
	teleported.emit()


## The door to go through first, if `obj` is on another level (or in a different
## attic or basement than the one we're in).
func _hop_for(obj: SmartObject) -> SmartObject:
	if obj.portal_to != null and obj.level == level:
		return null   # it's a door itself, right here
	var there := Vector2(obj.approach_point.x, obj.approach_point.z)
	if level == 0:
		if obj.level == 0:
			return null
		var target := InteriorBuilder.room_at(obj.approach_point)
		for p: SmartObject in portals:
			if p.level == 0 and target.has_point(Vector2(p.portal_to.approach_point.x, p.portal_to.approach_point.z)):
				return p
		return null
	var mine := InteriorBuilder.room_at(global_position)
	if obj.level == 1 and mine.has_point(there):
		return null
	for p: SmartObject in portals:
		if p.level == 1 and mine.has_point(Vector2(p.approach_point.x, p.approach_point.z)):
			return p
	return null


func _start_next() -> void:
	if queue.is_empty():
		return
	var job: Dictionary = queue.pop_front()
	var hop := _hop_for(job["obj"])
	if hop != null and not hop.activities.is_empty():
		queue.push_front(job)
		job = {"obj": hop, "act": hop.activities[0], "player": false, "hop": true}
	idle_minutes = 0
	_walk_goal = job
	queue_changed.emit()
	var o: SmartObject = job["obj"]
	if riding and (job["act"] as Activity).paper == "deliver" and o.has_meta("toss_point"):
		_go(o.get_meta("toss_point"))      # on a bike, throw it from the sidewalk!
		return
	_go(o.approach_point)


# ---------------------------------------------------------------- walking

func _cell(p: Vector3) -> Vector2i:
	var c := Vector2i(floori(p.x / grid.cell_size.x), floori(p.z / grid.cell_size.y))
	c.x = clampi(c.x, grid.region.position.x, grid.region.end.x - 1)
	c.y = clampi(c.y, grid.region.position.y, grid.region.end.y - 1)
	return c


func _nearest_free(c: Vector2i) -> Vector2i:
	if not grid.is_point_solid(c):
		return c
	for r in range(1, 12):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if grid.is_in_boundsv(n) and not grid.is_point_solid(n):
					return n
	return c


func _go(target: Vector3) -> void:
	if entry_check.is_valid() and level == 0:
		var why := String(entry_check.call(target))
		if why != "":
			notice.emit(why)
			_path.clear()
			_walk_goal = {}
			state = State.IDLE
			queue_changed.emit()
			if not queue.is_empty():
				_start_next.call_deferred()
			return
	var from := _nearest_free(_cell(global_position))
	var to := _nearest_free(_cell(target))
	_path = grid.get_point_path(from, to)
	if _path.size() > 0 and not grid.is_point_solid(_cell(target)):
		_path[_path.size() - 1] = Vector2(target.x, target.z)
	if _path.is_empty() and Vector2(target.x - global_position.x, target.z - global_position.z).length() > 0.8:
		# No way to get there (e.g. clicked somewhere outside the house).
		if not _walk_goal.is_empty():
			var why := String(why_unreachable.call(target)) if why_unreachable.is_valid() else ""
			notice.emit(why if why != "" else "%s can't get there." % character_name)
			_walk_goal = {}
			queue_changed.emit()
		state = State.IDLE
		return
	if _path.size() > 0 and global_position.distance_to(Vector3(_path[0].x, 0, _path[0].y)) < 0.2:
		_path.remove_at(0)
	state = State.WALKING
	if _path.is_empty():
		_arrive()


func _follow_path(step: float) -> void:
	if _path.is_empty():
		_arrive()
		return
	var move := WALK_SPEED * step * (BIKE_MULT if riding else 1.0)
	_moving = true
	# (use the whole step, even past several path points: at top speed it's longer than a grid cell)
	while move > 0.0 and not _path.is_empty():
		var p := _path[0]
		var goal := Vector3(p.x, global_position.y, p.y)
		var to := goal - global_position
		to.y = 0.0
		var dist := to.length()
		if dist <= move:
			global_position = goal
			move -= dist
			_path.remove_at(0)
			if dist > 0.001:
				_face_dir(to)
			if _path.is_empty():
				_arrive()
				return
		else:
			global_position += to / dist * move
			_face_dir(to)
			move = 0.0


func _arrive() -> void:
	state = State.IDLE
	if _walk_goal.is_empty():
		return
	var job := _walk_goal
	_walk_goal = {}
	_begin(job)


## Running (hold Shift): how much faster than walking.
const RUN_MULT := 2.0
## Riding a bike: how much faster than walking.
const BIKE_MULT := 2.4
var running := false
var why_unreachable: Callable     # (main.gd: "The bike shop is closed...")
var mail_status: Callable         # (main.gd: home -> "" if the mail's here to get, or why not)
var entry_check: Callable         # (main.gd: a point -> "" if we may go there, or why not: somebody else's house)
var let_in := {}                  # home -> until when (unix time) that family said come on in


## Direct control in first person / over the shoulder.
func drive(dir: Vector3, delta: float) -> void:
	if puppet:
		_drive_puppet(dir)
		return
	if dir.length() < 0.01:
		if _remote_manual_until == 0:
			_manual = false
		return
	if clock.speed_factor() == 0.0:
		return
	if state == State.DOING:
		_stop_current(false)
	if state == State.WALKING:
		_path.clear()
		_walk_goal = {}
		state = State.IDLE
		queue_changed.emit()
	_manual = true
	idle_minutes = -10
	velocity = dir.normalized() * WALK_SPEED * 1.15 * (BIKE_MULT if (riding or _pose == "bike") else (RUN_MULT if running else 1.0))
	var before := global_position
	move_and_slide()
	# No hopping between floors: block a step that would change Jamie's height
	# suddenly (e.g. off the side of the stairs, or into the stairwell).
	var h0 := floor_at(before.x, before.z)
	var h1 := floor_at(global_position.x, global_position.z)
	if absf(h1 - h0) > 0.35:
		global_position = before
	_face_dir(dir)
	_moving = true


## A player walking their own Sim on their own computer (online): move right
## away, and tell the host where we are (main.gd sends it).
func _drive_puppet(dir: Vector3) -> void:
	if dir.length() < 0.01:
		if local_control:
			local_control = false
			_ignore_net_until = Time.get_ticks_msec() + 700   # until the host has caught up
		return
	if hidden:
		return
	if not local_control:
		local_control = true
		_set_pose("stand")
	velocity = dir.normalized() * WALK_SPEED * 1.15 * (BIKE_MULT if (riding or _pose == "bike") else (RUN_MULT if running else 1.0))
	var before := global_position
	move_and_slide()
	var h0 := floor_at(before.x, before.z)
	var h1 := floor_at(global_position.x, global_position.z)
	if absf(h1 - h0) > 0.35:
		global_position = before
	_face_dir(dir)
	_moving = true


## Host: a remote player is walking this Sim (their computer sends where it is).
func remote_move(pos: Vector3, yaw: float) -> void:
	if state == State.DOING:
		_stop_current(false)
	if state == State.WALKING or not _walk_goal.is_empty():
		_path.clear()
		_walk_goal = {}
		state = State.IDLE
		queue_changed.emit()
	_manual = true
	_remote_manual_until = Time.get_ticks_msec() + 400
	idle_minutes = -10
	var moved := Vector2(pos.x - global_position.x, pos.z - global_position.z).length() > 0.005
	global_position = Vector3(pos.x, global_position.y, pos.z)
	_face_yaw = yaw
	_moving = moved


## Puppets: take what the host sent. `d` = [x, z, yaw, pose, surface, hidden, state].
func net_apply(d: Array) -> void:
	if Time.get_ticks_msec() >= _ignore_net_until and not local_control:
		net_pos = Vector3(float(d[0]), 0, float(d[1]))
		net_yaw = float(d[2])
	var p: String = d[3]
	if p != _pose and not local_control:
		_set_pose(p, float(d[4]))
	if bool(d[5]) != hidden:
		set_hidden(bool(d[5]))
	state = int(d[6]) as State
	if d.size() > 7 and int(d[7]) != level and not local_control:
		set_level(int(d[7]))
		global_position = Vector3(net_pos.x, floor_at(net_pos.x, net_pos.z), net_pos.z)
		teleported.emit()


func net_state() -> Array:
	return [snappedf(global_position.x, 0.001), snappedf(global_position.z, 0.001), snappedf(_face_yaw, 0.001),
		_pose, _surface, hidden, int(state), level]


# ---------------------------------------------------------------- doing

func _begin(job: Dictionary) -> void:
	var obj: SmartObject = job["obj"]
	var act: Activity = job["act"]
	if not act.available(clock):
		notice.emit(act.why_not(clock))
		queue_changed.emit()
		return
	if act.needs_item != "" and not items.has(act.needs_item):
		notice.emit("You need %s for that." % ITEM_NAMES.get(act.needs_item, act.needs_item))
		queue_changed.emit()
		return
	if act.needs_mail and mail_status.is_valid():
		var why := String(mail_status.call(obj.home))
		if why != "":
			notice.emit(why)
			queue_changed.emit()
			return
	if not Catalog.can_use(owned, act):
		notice.emit("You don't have what you need for \"%s\"." % act.title)
		queue_changed.emit()
		return
	if act.buys != "" and act.buys != "bike" and owned.has(act.buys):
		notice.emit("You already have the %s!" % Catalog.title(act.buys))
		queue_changed.emit()
		return
	if act.gives_item != "" and items.has(act.gives_item):
		notice.emit("You already have %s (\"%s\"). Return it first!" % [ITEM_NAMES.get(act.gives_item, ""),
			items[act.gives_item].get("title", "")])
		queue_changed.emit()
		return
	if act.money < 0.0 and money + act.money < 0.0:
		notice.emit("Jamie can't afford \"%s\" — it costs $%.2f." % [act.title, -act.money])
		queue_changed.emit()
		return
	if act.paper == "deliver" and not items.has("papers"):
		notice.emit("You don't have any newspapers. Pick them up at the Gazette in the morning.")
		queue_changed.emit()
		return
	if act.paper == "deliver" and not (items["papers"].get("left", []) as Array).has(obj.home):
		notice.emit("This house already got its paper today.")
		queue_changed.emit()
		return
	if obj.kind == "npc_thief":
		var st := String(obj.get_meta("state", "none"))
		if act.talk == "stop_thief" and st not in ["approach", "inside", "stealing", "fleeing"]:
			notice.emit("He's already behind bars." if st == "jailed" else "There's nobody to stop.")
			state = State.IDLE
			queue_changed.emit()
			return
		if act.talk == "chat" and st != "jailed":
			notice.emit("Talk? He's a BURGLAR! Stop him!")
			state = State.IDLE
			queue_changed.emit()
			return
	if act.ride and not obj.visible:
		notice.emit("You don't have a bike yet. Spoke & Pedal on Main Street sells them!")
		state = State.IDLE
		queue_changed.emit()
		return
	if act.ride and obj.home != home:
		notice.emit("That's %s. Get your own at Spoke & Pedal!" % obj.display_name)
		state = State.IDLE
		queue_changed.emit()
		return
	if obj is Npc and (obj as Npc).lying:
		notice.emit("%s is asleep. Shh!" % obj.display_name)
		state = State.IDLE
		queue_changed.emit()
		return
	if obj is Npc and (obj as Npc).away:
		notice.emit("%s isn't around right now." % obj.display_name)
		state = State.IDLE
		queue_changed.emit()
		return
	if obj.user != null and obj.user != self and is_instance_valid(obj.user) and not obj.shared:
		notice.emit("%s is using the %s right now." % [(obj.user as Sim).character_name, obj.display_name])
		state = State.IDLE
		queue_changed.emit()
		return
	var tossing := riding and act.paper == "deliver" and obj.has_meta("toss_point")
	if riding and not tossing:
		dismount()
	if not obj.shared:
		obj.user = self
	current = job
	minutes_done = 0
	state = State.DOING
	if act.busy_after_hour >= 0.0 and clock.hour_float() >= act.busy_after_hour and randf() < 0.5:
		current["busy"] = true
		notice.emit("Busy signal. Somebody at %s's house is on the line again." % Families.kid_name(act.call_home)
			if act.call_home != "" and act.call_home != "parents" else "Busy signal. Somebody's hogging the line.")
	if tossing:
		_face_point(obj.look_point)
		rotation.y = _face_yaw
		current["tossed"] = true
		queue_changed.emit()
		activity_started.emit(act, obj)
		return
	global_position = obj.use_point
	_face_point(act.face_point if act.face_point != Vector3.ZERO else obj.look_point)
	rotation.y = _face_yaw
	_set_pose(act.pose, act.surface)
	queue_changed.emit()
	activity_started.emit(act, obj)


func _stop_current(completed: bool) -> void:
	if current.is_empty():
		return
	var obj: SmartObject = current["obj"]
	var act: Activity = current["act"]
	if completed and act.money != 0.0 and not current.get("busy", false):
		money = maxf(0.0, money + act.money)
		notice.emit("%s $%.2f" % ["+" if act.money > 0 else "−", absf(act.money)])
	if completed:
		_finish_items(act, obj)
	if completed and act.teleport and obj.portal_to != null:
		current = {}
		if obj.user == self:
			obj.user = null
		_set_pose("stand")
		state = State.IDLE
		teleport_to(obj.portal_to)
		activity_finished.emit(act, obj)
		queue_changed.emit()
		return
	# Free Will won't pick the same thing again for a while (longer after a busy signal).
	_cooldown[act] = clock.unix_time + (150 if current.get("busy", false) else 90) * 60
	if obj.user == self:
		obj.user = null
	var tossed: bool = current.get("tossed", false)
	current = {}
	var ap := obj.approach_point if not tossed else global_position
	global_position = Vector3(ap.x, floor_at(ap.x, ap.z), ap.z)
	_set_pose("stand")
	rotation.y = _face_yaw
	state = State.IDLE
	activity_finished.emit(act, obj)
	queue_changed.emit()


const PAPER_HOUSES := ["jamie", "hendersons", "garcias", "kowalskis", "nguyens", "parkers", "millers", "obriens", "brooks"]
const PAPER_PAY := 6.0


## Rentals, library books, deliveries, allowance and the paper route, when an
## activity is done.
func _finish_items(act: Activity, obj: SmartObject = null) -> void:
	if act.talk == "chat" and obj is Npc:
		notice.emit("%s: \"%s\"" % [obj.display_name, (obj as Npc).line()])
	elif act.talk == "tip" and obj != null:
		notice.emit("%s: \"%s\"" % [obj.display_name, Content.TIPS[randi() % Content.TIPS.size()]])
	if act.chore != "" and obj != null:
		_do_chore(act.chore, obj)
	if act.talk == "chores" and obj != null:
		notice.emit(chores_left(obj))
	if act.ride and obj != null and obj.home == home:
		riding = true
		_set_pose("bike")
		bike_event.emit("mount")
	if act.buys == "bike":
		if bike:
			money += 60.0
			notice.emit("Spike laughs. \"You've already got one, little dude!\" (Refunded.)")
		else:
			bike = true
			notice.emit("It's all yours! Your new BMX is parked right outside. Click it to ride. (Faster paper route!)")
			bike_event.emit("bought")
	if act.call_home != "" and not current.get("busy", false):
		var callee := act.call_home if act.call_home != "parents" else home
		notice.emit(Phonebook.reply(home, act.call_home, clock.hour_float()))
		called.emit(callee)
	if act.buys != "" and act.buys != "bike":
		owned[act.buys] = true
		var line := String(Catalog.ITEMS.get(act.buys, {}).get("bought", ""))
		if act.money == 0.0 and act.buys.begins_with("outfit_"):
			notice.emit("You put on the %s. BOO!" % Catalog.title(act.buys).to_lower())
		else:
			notice.emit("You bought the %s!%s" % [Catalog.title(act.buys), "  " + line if line != "" else ""])
		bought.emit(act.buys)
	if act.talk == "allowance" and obj != null:
		var who := obj.display_name
		if obj.home != home:
			notice.emit("%s laughs. \"Nice try! Go ask your own folks, kiddo.\"" % who)
		elif allowance_given:
			notice.emit("%s: \"You already got your dollar today. Don't push it!\"" % who)
		else:
			allowance_given = true
			money += 1.0
			notice.emit("%s hands you a crisp dollar bill. \"Don't spend it all in one place!\"  + $1.00" % who)
			paid.emit(1.0, "allowance")
	match act.paper:
		"apply":
			if job == "paper":
				notice.emit("You already have the paper route!")
			else:
				job = "paper"
				notice.emit("You got the job! Pick up your papers at the Gazette between 6 and 10 AM, then deliver one to each house on Maple Street. $%.2f a route." % PAPER_PAY)
		"quit":
			job = ""
			items.erase("papers")
			notice.emit("You quit the paper route. Mr. Gruber looks sad.")
		"pickup":
			var day := int(clock.unix_time / 86400)
			if job != "paper":
				notice.emit("\"Sorry kid, those are for my paper carriers. Want the job?\"")
			elif paper_day == day:
				notice.emit("You already picked up today's papers.")
			else:
				paper_day = day
				items["papers"] = {"title": "The Maple Grove Gazette", "due": clock.unix_time + 86400,
					"left": PAPER_HOUSES.duplicate()}
				notice.emit("You stuff %d papers into your bag. Deliver one to every house on Maple Street!" % PAPER_HOUSES.size())
		"deliver":
			if items.has("papers") and obj != null:
				var left: Array = items["papers"]["left"]
				left.erase(obj.home)
				if left.is_empty():
					items.erase("papers")
					money += PAPER_PAY
					notice.emit("Route finished! The Gazette pays you $%.2f." % PAPER_PAY)
					paid.emit(PAPER_PAY, "paper")
				else:
					notice.emit("Thwack! Right on the porch. %d to go." % left.size())
	if act.gives_item != "":
		var title: String = act.gives_titles[randi() % act.gives_titles.size()] if not act.gives_titles.is_empty() else ""
		items[act.gives_item] = {"title": title, "due": clock.unix_time + act.gives_days * 86400}
		if act.done_message != "":
			notice.emit(act.done_message % title)
	if act.takes_item != "" and items.has(act.takes_item):
		var it: Dictionary = items[act.takes_item]
		items.erase(act.takes_item)
		var late := ceili((clock.unix_time - int(it.get("due", 0))) / 86400.0)
		var msg: String = act.done_message % it.get("title", "") if act.done_message != "" else ""
		if late > 0 and act.late_fee > 0.0:
			var fee := minf(5.0, late * act.late_fee)
			money = maxf(0.0, money - fee)
			msg += "  It was %d day%s late: −$%.2f late fee." % [late, "" if late == 1 else "s", fee]
		if msg != "":
			notice.emit(msg)
	if act.delivery != "":
		delivery_ordered.emit(act.delivery)
		if act.done_message != "":
			notice.emit(act.done_message)


## A chore's done: Mom or Dad pay up (once a day for each one, at home only).
func _do_chore(chore: String, obj: SmartObject) -> void:
	var where := String(obj.get_meta("family", obj.home))
	if where != home:
		notice.emit("%s says thanks for %s! (Chores only pay at your own house.)" % [Families.parent_name(where, randi() % 2 == 0, home) if where != "" else "Somebody", Chores.title(chore)])
		return
	var day := int(clock.unix_time / 86400)
	if int(chores_done.get(chore, -1)) == day:
		notice.emit("You already did that today. Mom says thanks anyway!")
		return
	chores_done[chore] = day
	var pay := Chores.pay(chore)
	money += pay
	notice.emit("%s gives you $%.2f for %s!  + $%.2f" % ["Mom" if randi() % 2 == 0 else "Dad", pay, Chores.title(chore), pay])
	paid.emit(pay, "chore")


## What a parent says when you ask what needs doing.
func chores_left(parent: SmartObject) -> String:
	if parent.home != home:
		return "%s smiles. \"That's sweet, but ask your own folks!\"" % parent.display_name
	var day := int(clock.unix_time / 86400)
	var left := []
	for c in Chores.LIST:
		if c == "mail" and mail_status.is_valid() and String(mail_status.call(home)) != "":
			continue      # (no mail to get yet, or it's Sunday)
		if int(chores_done.get(c, -1)) != day:
			left.append("%s ($%.2f)" % [Chores.title(c), Chores.pay(c)])
	if left.is_empty():
		return "%s: \"You did EVERY chore today? Who are you, and what have you done with my kid?\"" % parent.display_name
	return "%s: \"Let's see... %s.\"" % [parent.display_name, ", ".join(left.slice(0, 5))]


## Hop off the bike: it's parked right here.
func dismount() -> void:
	if not riding:
		return
	riding = false
	bike_event.emit("park")
	if _pose == "bike":
		_set_pose("stand")
	queue_changed.emit()


## The title of something you're carrying ("" if you don't have it).
func item_title(item: String) -> String:
	return String(items[item].get("title", "")) if items.has(item) else ""


func facing_yaw() -> float:
	return _face_yaw


func current_activity() -> Activity:
	if current.is_empty():
		return null
	return current["act"]


## Called by the clock once per game minute.
func on_minute() -> void:
	if puppet:
		return
	var fx := {}
	if state == State.DOING and not current.is_empty():
		var act: Activity = current["act"]
		var busy: bool = current.get("busy", false)
		if not busy:
			fx = act.effects
		minutes_done += 1
		var done := minutes_done >= (BUSY_MINUTES if busy else act.minutes)
		if act.until_rested:
			# Sleep until Energy is full and it's morning (or after ~11 hours).
			var h := clock.hour_float()
			done = (needs.value("energy") >= 99.0 and h >= 6.0 and h < 14.0) or minutes_done >= 660
		if act.drive:
			done = false   # you drive until you park and get out
		if done:
			needs.tick_minute(fx)
			_stop_current(true)
			if not queue.is_empty():
				_start_next()
			return
	# Late at night Jamie gets sleepy faster (unless she's already asleep).
	var h2 := clock.hour_float()
	var asleep := state == State.DOING and not current.is_empty() and (current["act"] as Activity).pose == "lie"
	needs.sleepy = (h2 >= 21.0 or h2 < 6.0) and not asleep
	needs.tick_minute(fx)
	if state == State.IDLE and not _manual and not hidden:
		idle_minutes += 1
		if not queue.is_empty():
			_start_next()
		elif free_will and idle_minutes >= 6:
			_choose_for_myself()


## Utility AI: score every available activity by how much it would help the
## needs that are lowest right now, with a little randomness.
func _choose_for_myself() -> void:
	var best_score := 0.0
	var best := {}
	for obj: SmartObject in objects:
		if obj.home != "" and obj.home != home:
			continue   # other people's houses (and the shops downtown) are off limits to Free Will
		if not obj.is_visible_in_tree():
			continue   # e.g. no pizza delivered yet
		if obj.user != null and obj.user != self and not obj.shared:
			continue   # someone else is using it
		for act: Activity in obj.activities:
			if not act.available(clock) or not act.autonomous:
				continue
			if (act.needs_item != "" and not items.has(act.needs_item)) or (act.gives_item != "" and items.has(act.gives_item)):
				continue
			if not Catalog.can_use(owned, act) or not Phonebook.listed(act, home, obj):
				continue
			if act.needs_mail and mail_status.is_valid() and String(mail_status.call(obj.home)) != "":
				continue
			if _cooldown.get(act, 0) > clock.unix_time:
				continue  # did this recently (or the line was busy): try something else
			var s := 0.0
			for n in act.effects:
				var gain: float = float(act.effects[n]) * act.minutes / 60.0
				var v := needs.value(n)
				if gain > 0.0:
					var urgency := pow((100.0 - v) / 100.0, 2.0)
					s += minf(gain, 100.0 - v) * urgency
				else:
					s += gain * 0.3
			if act.bonus_active(clock):
				s += act.bonus_amount   # e.g. bedtime, or the mail arriving
			s *= randf_range(0.85, 1.15)
			if s > best_score:
				best_score = s
				best = {"obj": obj, "act": act, "player": false}
	idle_minutes = 0
	# The longer Jamie stands around, the less it takes to get her off her feet.
	_bored_minutes += 6
	var threshold := maxf(1.0, 4.0 - _bored_minutes / 12.0)
	if best_score > threshold:
		_bored_minutes = 0
		queue.append(best)
		queue_changed.emit()
		_start_next()


# ---------------------------------------------------------------- poses & animation

func _set_pose(p: String, surface := 0.45) -> void:
	if p == "stand" and riding:
		p = "bike"
	_pose = p
	_surface = surface
	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	_show_ride_bike(p == "bike")
	_show_skateboard(p.begins_with("skate"))
	for leg in _legs:
		leg.rotation = Vector3.ZERO
	for arm in _arms:
		arm.rotation = Vector3.ZERO
	match p:
		"sit":
			visual.position.y = surface + 0.02 - 54 * K
			for leg in _legs:
				leg.rotation.x = deg_to_rad(85.0)
			for arm in _arms:
				arm.rotation.x = deg_to_rad(30.0)
		"lie":
			# On her back, head behind (Jamie "faces" her feet), body centered on the spot.
			visual.rotation.x = deg_to_rad(90.0)
			visual.position = Vector3(0.0, surface + 0.15, -0.84)
			for arm in _arms:
				arm.rotation.z = deg_to_rad(8.0)
		"phone":
			_arms[1].rotation.x = deg_to_rad(150.0)
			_arms[1].rotation.z = deg_to_rad(-25.0)
		"reach":
			_arms[0].rotation.x = deg_to_rad(80.0)
			_arms[1].rotation.x = deg_to_rad(80.0)
		"bike":
			# On the seat, hands on the handlebars
			visual.position.y = 0.3
			for arm in _arms:
				arm.rotation.x = deg_to_rad(70.0)
			for leg in _legs:
				leg.rotation.x = deg_to_rad(40.0)
		"swim":
			# In the water up to the shoulders
			visual.position.y = -1.0
			for arm in _arms:
				arm.rotation.z = deg_to_rad(10.0)
		"skate_pipe", "skate_ramp":
			visual.position.y = 0.11
			for arm in _arms:
				arm.rotation.z = 0.0
			_arms[0].rotation.z = deg_to_rad(-40.0)
			_arms[1].rotation.z = deg_to_rad(40.0)
		"bowl":
			_arms[1].rotation.x = deg_to_rad(20.0)
		"ride_wheel", "ride_carousel":
			for leg in _legs:
				leg.rotation.x = deg_to_rad(85.0)
			for arm in _arms:
				arm.rotation.x = deg_to_rad(40.0)
		"read":
			# Sitting, holding a book (or a game) up in front of her face.
			visual.position.y = surface + 0.02 - 54 * K
			for leg in _legs:
				leg.rotation.x = deg_to_rad(85.0)
			for arm in _arms:
				arm.rotation.x = deg_to_rad(65.0)
			_arms[0].rotation.z = deg_to_rad(-18.0)
			_arms[1].rotation.z = deg_to_rad(18.0)


var _ride_bike: Node3D
var _skateboard: Node3D


## A skateboard under the kid's feet (the skate park).
func _show_skateboard(on: bool) -> void:
	if _skateboard == null:
		if not on:
			return
		_skateboard = Node3D.new()
		_skateboard.name = "Skateboard"
		visual.add_child(_skateboard)
		RoomBuilder.box(_skateboard, Vector3(0.24, 0.025, 0.82), Vector3(0, -0.035, 0), Color("C0322A"))
		RoomBuilder.box(_skateboard, Vector3(0.2, 0.004, 0.6), Vector3(0, -0.0205, 0), Color("2B2B30"))
		for wz in [-0.28, 0.28]:
			RoomBuilder.box(_skateboard, Vector3(0.26, 0.05, 0.06), Vector3(0, -0.075, wz), Color("F2F0E6"))
	_skateboard.visible = on


# ---------------------------------------------------------------- emotes

const EMOTES := {
	"wave": ["Wave", "Hey!"], "dance": ["Dance", "♪ ♫ ♪"], "laugh": ["Laugh", "HA HA HA!"], "cheer": ["Cheer", "WOOO!"],
	"shrug": ["Shrug", "Whatever."], "airguitar": ["Air Guitar", "*air guitar solo*"], "thumbsup": ["Thumbs Up", "Totally!"],
	"facepalm": ["Facepalm", "Ugh. Seriously?"], "point": ["Point & Laugh", "Gotcha!"], "bow": ["Take a Bow", "Thank you, thank you!"],
}
const EMOTE_ORDER := ["wave", "dance", "laugh", "cheer", "thumbsup", "shrug", "airguitar", "facepalm", "point", "bow"]
var _emote := ""
var _emote_until := 0


var _hop_t := -1.0                # seconds into a jump (-1 = on the ground)
const HOP_TIME := 0.55
const HOP_HEIGHT := 0.45


## Jump! (standing or walking; not sitting, lying, riding or hidden)
func jump() -> bool:
	if hidden or riding or _hop_t >= 0.0 or (_pose != "stand" and _pose != "walk"):
		return false
	_hop_t = 0.0
	return true


## How high off the ground a jump has us right now.
func _hop(delta: float) -> float:
	if _hop_t < 0.0:
		return 0.0
	_hop_t += delta
	if _hop_t >= HOP_TIME:
		_hop_t = -1.0
		return 0.0
	return sin(_hop_t / HOP_TIME * PI) * HOP_HEIGHT


## Do an emote (only standing around, not in the middle of something).
func emote(kind: String) -> bool:
	if kind == "jump":
		return jump()
	if not EMOTES.has(kind) or hidden or _pose != "stand" or riding:
		return false
	_emote = kind
	_emote_until = Time.get_ticks_msec() + 3200
	Props.bubble(self, EMOTES[kind][1], 2.8, 2.5)
	return true


func _animate_emote(t: float) -> bool:
	if _emote == "" or Time.get_ticks_msec() > _emote_until or _pose != "stand":
		if _emote != "":
			_emote = ""
			visual.position = Vector3.ZERO
			visual.rotation = Vector3.ZERO
			for i in 2:
				_arms[i].rotation = Vector3.ZERO
				_legs[i].rotation = Vector3.ZERO
		return false
	for i in 2:
		_legs[i].rotation = Vector3.ZERO
	visual.position = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	match _emote:
		"wave":
			_arms[0].rotation = Vector3.ZERO
			_arms[1].rotation = Vector3(deg_to_rad(165.0), 0, deg_to_rad(-20.0) + sin(t * 10.0) * 0.35)
		"dance":
			var b := sin(t * 7.0)
			visual.position.y = absf(b) * 0.06
			visual.rotation.y = sin(t * 3.5) * 0.35
			_arms[0].rotation = Vector3(deg_to_rad(150.0) * (0.5 + 0.5 * sin(t * 7.0)), 0, 0)
			_arms[1].rotation = Vector3(deg_to_rad(150.0) * (0.5 + 0.5 * cos(t * 7.0)), 0, 0)
			_legs[0].rotation.x = b * 0.35
			_legs[1].rotation.x = -b * 0.35
		"laugh":
			visual.rotation.x = -0.15 + sin(t * 14.0) * 0.06
			visual.position.y = absf(sin(t * 14.0)) * 0.03
			_arms[0].rotation = Vector3(deg_to_rad(40.0), 0, deg_to_rad(30.0))
			_arms[1].rotation = Vector3(deg_to_rad(40.0), 0, deg_to_rad(-30.0))
		"cheer":
			var j := absf(sin(t * 6.0))
			visual.position.y = j * 0.25
			_arms[0].rotation = Vector3(deg_to_rad(170.0), 0, deg_to_rad(15.0))
			_arms[1].rotation = Vector3(deg_to_rad(170.0), 0, deg_to_rad(-15.0))
		"shrug":
			var k := clampf(sin(t * 3.0) * 1.5, 0.0, 1.0)
			_arms[0].rotation = Vector3(deg_to_rad(30.0) * k, 0, deg_to_rad(-45.0) * k)
			_arms[1].rotation = Vector3(deg_to_rad(30.0) * k, 0, deg_to_rad(45.0) * k)
			visual.position.y = 0.03 * k
		"airguitar":
			visual.rotation.x = 0.12
			_arms[0].rotation = Vector3(deg_to_rad(70.0), 0, deg_to_rad(-25.0))
			_arms[1].rotation = Vector3(deg_to_rad(45.0) + sin(t * 18.0) * 0.4, 0, deg_to_rad(25.0))
			_legs[0].rotation.x = -0.3
			_legs[1].rotation.x = 0.3
			visual.position.y = absf(sin(t * 6.0)) * 0.04
		"thumbsup":
			_arms[1].rotation = Vector3(deg_to_rad(90.0), 0, 0)
		"facepalm":
			_arms[1].rotation = Vector3(deg_to_rad(150.0), 0, deg_to_rad(25.0))
			visual.rotation.x = 0.15
		"point":
			_arms[1].rotation = Vector3(deg_to_rad(90.0), 0, 0)
			_arms[0].rotation = Vector3(deg_to_rad(30.0), 0, deg_to_rad(30.0))
			visual.rotation.x = -0.12 + sin(t * 14.0) * 0.05
		"bow":
			var k2 := clampf(sin(t * 2.0) * 1.4, 0.0, 1.0)
			visual.rotation.x = 0.7 * k2
			_arms[0].rotation = Vector3(deg_to_rad(-20.0) * k2, 0, 0)
			_arms[1].rotation = Vector3(deg_to_rad(60.0) * k2, 0, deg_to_rad(-30.0) * k2)
	return true


## The bike under a kid who's riding (built the first time it's needed).
func _show_ride_bike(on: bool) -> void:
	if _ride_bike == null:
		if not on:
			return
		_ride_bike = Node3D.new()
		_ride_bike.name = "RideBike"
		add_child(_ride_bike)
		var col: Color = [Color("C0322A"), Color("2E5E9E"), Color("F7D046"), Color("2E8C8A"), Color("FF4FD8"), Color("4F9A3A")][slot % 6]
		for wz in [-0.48, 0.48]:
			var hub := Node3D.new()
			hub.name = "Front" if wz < 0 else "Back"
			hub.position = Vector3(0, 0.3, wz)
			_ride_bike.add_child(hub)
			Car._cyl(hub, 0.3, 0.05, Palette.INK, 14)
			Car._cyl(hub, 0.08, 0.06, Palette.MUTED, 8)
			RoomBuilder.box(hub, Vector3(0.012, 0.5, 0.03), Vector3(0, 0, 0), Palette.MUTED)
		RoomBuilder.box(_ride_bike, Vector3(0.038, 0.05, 0.95), Vector3(0, 0.55, 0), col)
		RoomBuilder.box(_ride_bike, Vector3(0.038, 0.45, 0.05), Vector3(0, 0.45, -0.46), col).rotation.x = -0.25
		RoomBuilder.box(_ride_bike, Vector3(0.038, 0.3, 0.05), Vector3(0, 0.55, 0.12), col)
		RoomBuilder.box(_ride_bike, Vector3(0.1, 0.06, 0.24), Vector3(0, 0.72, 0.14), Palette.INK)       # the seat
		RoomBuilder.box(_ride_bike, Vector3(0.56, 0.04, 0.04), Vector3(0, 0.82, -0.52), Palette.MUTED)   # handlebars
	_ride_bike.visible = on


func _face_dir(d: Vector3) -> void:
	if Vector2(d.x, d.z).length() < 0.001:
		return
	_face_yaw = atan2(-d.x, -d.z)


func _face_point(p: Vector3) -> void:
	_face_dir(p - global_position)


func _physics_process(delta: float) -> void:
	if hidden:
		return
	if puppet:
		_puppet_physics(delta)
		return
	if _remote_manual_until > 0 and Time.get_ticks_msec() > _remote_manual_until:
		_remote_manual_until = 0
		_manual = false
	var spd := clock.speed_factor()
	var mult := 0.0 if spd == 0.0 else clampf(spd, 1.0, 15.0)   # walk faster at fast-forward, as fast as the clock (there and back to the schools adds up)
	if state == State.WALKING and not _manual:
		_follow_path(delta * mult)
	# Stand on whatever floor is here (it's only not 0 on the stairs), plus a jump.
	var hop := _hop(delta)
	var fh := floor_at(global_position.x, global_position.z)
	if hop > 0.0:
		global_position.y = fh + hop
	elif state == State.DOING or absf(global_position.y - fh) > 1.0:
		global_position.y = fh
	else:
		global_position.y = lerpf(global_position.y, fh, minf(1.0, delta * 14.0))
	_animate(delta, mult)


func _puppet_physics(delta: float) -> void:
	if not local_control:
		var to := net_pos - global_position
		to.y = 0.0
		if to.length() > 4.0:
			global_position = Vector3(net_pos.x, global_position.y, net_pos.z)
		else:
			global_position += to * minf(1.0, delta * 10.0)
		if to.length() > 0.04 and _pose == "stand":
			_moving = true
		_face_yaw = net_yaw
	var hop := _hop(delta)
	var fh := floor_at(global_position.x, global_position.z)
	if hop > 0.0:
		global_position.y = fh + hop
	elif state == State.DOING or absf(global_position.y - fh) > 1.0:
		global_position.y = fh
	else:
		global_position.y = lerpf(global_position.y, fh, minf(1.0, delta * 14.0))
	_animate(delta, 1.0)


func _animate(delta: float, mult: float) -> void:
	var moving := _moving
	_moving = false
	rotation.y = lerp_angle(rotation.y, _face_yaw, minf(1.0, delta * 12.0))
	var t0 := Time.get_ticks_msec() * 0.001
	if _pose == "dance":
		# Big 80s moves in front of the mirror.
		var b := sin(t0 * 7.0)
		visual.position.y = absf(b) * 0.06
		visual.rotation.y = sin(t0 * 3.5) * 0.35
		_arms[0].rotation.x = deg_to_rad(150.0) * (0.5 + 0.5 * sin(t0 * 7.0))
		_arms[1].rotation.x = deg_to_rad(150.0) * (0.5 + 0.5 * cos(t0 * 7.0))
		_legs[0].rotation.x = b * 0.35
		_legs[1].rotation.x = -b * 0.35
		return
	if _pose == "hoops":
		# Dribble, dribble, jump shot.
		var c := fmod(t0, 2.2)
		if c < 1.4:
			_arms[1].rotation.x = deg_to_rad(40.0) + sin(c * 18.0) * 0.35
			_arms[0].rotation.x = 0.0
			visual.position.y = 0.0
		else:
			var j := sin((c - 1.4) / 0.8 * PI)
			visual.position.y = j * 0.3
			_arms[0].rotation.x = deg_to_rad(165.0)
			_arms[1].rotation.x = deg_to_rad(165.0)
		return
	if _pose == "bike":
		# Pedal while moving
		if moving:
			_walk_phase += delta * 7.0 * maxf(mult, 1.0)
		var pd := sin(_walk_phase) * 0.55
		_legs[0].rotation.x = deg_to_rad(40.0) + pd
		_legs[1].rotation.x = deg_to_rad(40.0) - pd
		if _ride_bike:
			(_ride_bike.get_node("Front") as Node3D).rotation.x -= delta * (8.0 if moving else 0.0)
			(_ride_bike.get_node("Back") as Node3D).rotation.x -= delta * (8.0 if moving else 0.0)
		return
	if _pose == "swim":
		visual.position.y = -1.0 + sin(t0 * 2.0) * 0.04
		_arms[0].rotation.x = sin(t0 * 3.0) * 0.8
		_arms[1].rotation.x = -sin(t0 * 3.0) * 0.8
		return
	if _pose == "skate_pipe":
		# Back and forth on the half-pipe, up each ramp, turning around at the top
		var ph := t0 * 1.15
		var zz := sin(ph) * 4.4
		var a := absf(zz)
		var up := clampf((a - 2.4) * 0.8, 0.0, 2.0)
		visual.position = Vector3(0, 0.11 + up, -zz)
		visual.rotation.y = 0.0 if cos(ph) > 0.0 else PI
		visual.rotation.x = (0.675 if a > 2.4 else 0.0) * signf(zz) * (1.0 if cos(ph) > 0.0 else -1.0)
		return
	if _pose == "skate_ramp":
		var c2 := fmod(t0, 2.6)
		var hop := maxf(0.0, sin((c2 - 1.6) / 0.6 * PI)) if c2 > 1.6 and c2 < 2.2 else 0.0
		visual.position = Vector3(0, 0.11 + hop * 0.45, -sin(t0 * 2.4) * 0.8)
		visual.rotation.y = sin(t0 * 1.2) * 0.3
		if _skateboard:
			_skateboard.rotation.z = hop * 0.6
		return
	if _pose == "ride_wheel":
		# Around and around in a gondola (in step with the wheel: see holidays.gd)
		var th := t0 * Holidays.WHEEL_SPEED
		var r := EventGrounds.WHEEL_R
		visual.position = Vector3(-r * sin(th), r - r * cos(th) + 0.85 - 54 * K, 0)
		return
	if _pose == "ride_carousel":
		var ph := t0 * Holidays.CAROUSEL_SPEED
		var off := Vector3(cos(ph) * EventGrounds.CAROUSEL_R, 1.15 - 54 * K + sin(ph * 3.0) * 0.2, -sin(ph) * EventGrounds.CAROUSEL_R)
		visual.position = global_basis.inverse() * off
		visual.rotation.y = ph - rotation.y + PI
		return
	if _pose == "bowl":
		# Step, swing back, release
		var c3 := fmod(t0, 4.0)
		if c3 < 1.2:
			visual.position.z = -c3 * 0.5
			_arms[1].rotation.x = deg_to_rad(20.0) - c3 * 1.6
		elif c3 < 1.8:
			visual.position.z = -0.6
			_arms[1].rotation.x = lerpf(-1.7, 1.2, (c3 - 1.2) / 0.6)
			_legs[0].rotation.x = 0.5
			_legs[1].rotation.x = -0.4
		else:
			visual.position.z = lerpf(-0.6, 0.0, clampf((c3 - 2.6) / 1.2, 0.0, 1.0))
			_arms[1].rotation.x = lerpf(1.2, 0.3, clampf((c3 - 1.8) / 0.6, 0.0, 1.0))
			_legs[0].rotation.x = lerpf(_legs[0].rotation.x, 0.0, 0.1)
			_legs[1].rotation.x = lerpf(_legs[1].rotation.x, 0.0, 0.1)
		return
	if _pose == "read":
		# Turn a page now and then.
		_arms[1].rotation.z = deg_to_rad(18.0) + maxf(0.0, sin(t0 * 0.9) - 0.9) * 4.0
		return
	if _pose != "stand":
		return
	if not moving and _animate_emote(t0):
		return
	if moving and _emote != "":
		_emote_until = 0
		_animate_emote(t0)
	if moving:
		_walk_phase += delta * 9.0 * maxf(mult, 1.0) * (1.6 if running else 1.0)
		var s := sin(_walk_phase) * 0.6
		_legs[0].rotation.x = s
		_legs[1].rotation.x = -s
		_arms[0].rotation.x = -s * 0.8
		_arms[1].rotation.x = s * 0.8
		visual.position.y = absf(cos(_walk_phase)) * 0.03
	else:
		var t := minf(1.0, delta * 10.0)
		for i in 2:
			_legs[i].rotation.x = lerpf(_legs[i].rotation.x, 0.0, t)
			_arms[i].rotation.x = lerpf(_arms[i].rotation.x, 0.0, t)
		visual.position.y = sin(Time.get_ticks_msec() * 0.002) * 0.006
