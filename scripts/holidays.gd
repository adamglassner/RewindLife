class_name Holidays
extends Node3D
## The holidays, and how the town dresses up for them:
##   New Year's Day (Jan 1)   party hats on TV, fireworks just after midnight
##   Memorial Day (May 25)    flags on every porch, cookouts
##   Independence Day (Jul 4) flags and red-white-and-blue bunting, a cookout, fireworks at 9 PM
##   Labor Day (Sep 7)        flags, the last cookout of summer
##   Thanksgiving (4th Thursday of November) a turkey on every dining table
##   Christmas (Dec 25)       lights on every house all December, a tree with presents in the living room
##   Valentine's Day (Feb 14) hearts on the houses, valentines in the mailbox, a box of candy hearts
##   Easter (a Sunday in spring) an egg hunt in the front yards, an Easter basket in the living room
##   Halloween (Oct 31)       jack-o'-lanterns on every porch, trick-or-treating at night, costumes
##   The CARNIVAL and the CIRCUS come to town for a few days each year, on dates
##   picked at random for each year (see event_days): the carnival in summer, the
##   circus in spring or fall. They set up at the fairgrounds (event_grounds.gd).
##
## As a node it builds the decorations and shows the ones for today, and sets
## off the fireworks.

const NAMES := {
	"newyear": "New Year's Day", "memorial": "Memorial Day", "july4": "Independence Day",
	"labor": "Labor Day", "thanksgiving": "Thanksgiving", "christmas": "Christmas",
	"valentine": "Valentine's Day", "easter": "Easter", "halloween": "Halloween",
	"carnival": "The Carnival", "circus": "The Circus",
}
const GREETINGS := {
	"newyear": "Happy New Year! Fireworks light up the sky just after midnight.",
	"memorial": "It's Memorial Day. Flags are out on every porch, and somebody's firing up a grill.",
	"july4": "Happy 4th of July! Cookouts all day, and fireworks over Maple Street at 9 PM.",
	"labor": "It's Labor Day: the last cookout of summer. School starts soon...",
	"thanksgiving": "Happy Thanksgiving! There's a turkey on the table. Go eat!",
	"christmas": "Merry Christmas! Check under the tree.",
	"valentine": "Happy Valentine's Day! Check the mailbox. Somebody might like you...",
	"easter": "Happy Easter! There are eggs hidden in the front yards. Go find them!",
	"halloween": "Happy Halloween! Put on a costume and go trick-or-treating after 6 PM.",
	"carnival": "The carnival is in town! Rides and games at the fairgrounds (east end of Maple Street), noon to 11 PM.",
	"circus": "The circus is in town! The big top is up at the fairgrounds (east end of Maple Street).",
}


## Today's holiday key (or the carnival or the circus), or "".
static func today(clock: GameClock) -> String:
	var h := on_date(clock.month(), clock.day(), clock.year())
	if h != "":
		return h
	return event_on(clock.month(), clock.day(), clock.year())


## The carnival or the circus, if one of them is in town that day.
static func event_on(m: int, d: int, y: int) -> String:
	for ev in ["carnival", "circus"]:
		var e := event_days(ev, y)
		if m == e[0] and d >= e[1] and d < e[1] + e[2]:
			return ev
	return ""


## When the carnival / circus comes to town in year `y`: [month, first day, how many days].
## Picked at random for each year (the same for everyone playing that year): the
## carnival sometime from mid-June to August, the circus in April, May, September or October.
static func event_days(ev: String, y: int) -> Array:
	var rng := RandomNumberGenerator.new()
	if ev == "carnival":
		rng.seed = y * 7919 + 13
		var m := rng.randi_range(6, 8)
		var d := rng.randi_range(18 if m == 6 else 1, 25)
		return [m, d, 4]
	rng.seed = y * 104729 + 7
	var m2: int = [4, 5, 9, 10][rng.randi_range(0, 3)]
	return [m2, rng.randi_range(1, 24), 3]


## Easter Sunday: [month, day] (the "anonymous Gregorian" method).
static func easter_date(y: int) -> Array:
	var a := y % 19
	var b := y / 100
	var c := y % 100
	var d := b / 4
	var e := b % 4
	var f := (b + 8) / 25
	var g := (b - f + 1) / 3
	var h := (19 * a + b - d - g + 15) % 30
	var i := c / 4
	var k := c % 4
	var l := (32 + 2 * e + 2 * i - h - k) % 7
	var m := (a + 11 * h + 22 * l) / 451
	var month := (h + l - 7 * m + 114) / 31
	var day := ((h + l - 7 * m + 114) % 31) + 1
	return [month, day]


static func on_date(m: int, d: int, y: int) -> String:
	if m == 1 and d == 1:
		return "newyear"
	if m == 5 and d == 25:
		return "memorial"
	if m == 7 and d == 4:
		return "july4"
	if m == 9 and d == 7:
		return "labor"
	if m == 12 and d == 25:
		return "christmas"
	if m == 11 and d == thanksgiving_day(y):
		return "thanksgiving"
	if m == 2 and d == 14:
		return "valentine"
	if m == 10 and d == 31:
		return "halloween"
	var ea := easter_date(y)
	if m == ea[0] and d == ea[1]:
		return "easter"
	return ""


## The day of the month of the 4th Thursday in November.
static func thanksgiving_day(y: int) -> int:
	var first := Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_dict(
		{"year": y, "month": 11, "day": 1, "hour": 12, "minute": 0, "second": 0}))
	var wd := int(first["weekday"])           # 0 = Sunday
	var first_thu := 1 + posmod(4 - wd, 7)
	return first_thu + 21


## Which decorations are up (a bit longer than the day itself for some).
static func decor_up(clock: GameClock) -> Dictionary:
	var m := clock.month()
	var d := clock.day()
	var h := today(clock)
	return {
		"flags": h in ["memorial", "july4", "labor"] or (m == 7 and d >= 1 and d <= 5),
		"bunting": m == 7 and d >= 1 and d <= 5,
		"christmas": m == 12 or (m == 1 and d == 1),
		"thanksgiving": h == "thanksgiving",
		"valentine": m == 2 and d >= 7 and d <= 14,
		"easter": h == "easter",
		"halloween": (m == 10 and d >= 20) or (m == 11 and d == 1),
		"carnival": h == "carnival",
		"circus": h == "circus",
	}


# ================================================================ decorations

var main: Node
var _groups := {}            # "flags" / "bunting" / "christmas" / "thanksgiving" -> Array of nodes
var _objects := {}           # group -> usable things that only exist then
var _last_key := "-"
var _bursts: Array = []      # fireworks: {node, parts, t}
var _next_burst := 0.0
var _tree_solid := -1
var _tree_rect := Rect2()
var _solid_slots := {}       # group -> [[index in the solids list, its Rect2]] (floor space taken only while it's up)
var _spin := {}              # the Ferris wheel, its gondolas, the carousel and its horses (turning while they're up)
var _fair_music: Array = []  # [sound, where] for the carnival and the circus
var _clown_route: Array = []
var _clowns_list: Array = []
var _found_eggs := {}        # egg key -> the year it was found
var _lanterns: Array = []    # jack-o'-lantern glow materials


func setup(p_main: Node) -> void:
	main = p_main
	name = "Holidays"
	for g in ["flags", "bunting", "christmas", "thanksgiving", "valentine", "easter", "halloween", "carnival", "circus"]:
		_groups[g] = []
		_objects[g] = []
		_solid_slots[g] = []
	var fronts := _house_fronts()
	for f in fronts:
		_flag(f[0], f[1])
		_bunting(f[0], f[1], f[2])
		_lights(f[0], f[1], f[2])
		_hearts(f[0], f[1], f[2])
	_tree_and_presents()
	_turkeys()
	_fireworks_blanket()
	_jack_o_lanterns()
	_easter_eggs()
	EventGrounds.build(self)
	_clowns()


## [door position on the outside wall, outward direction, front wall width] for every house.
func _house_fronts() -> Array:
	var out := [[Vector3(RoomBuilder.FRONT_DOOR_X, 0, RoomBuilder.D), Vector3(0, 0, 1), 8.0]]
	for k in NeighborBuilder.HOMES:
		var h: Dictionary = NeighborBuilder.HOMES[k]
		var r: Rect2 = h["r"]
		var face: float = h["face"]
		var lw := snappedf(r.size.x * 0.44, 0.1)
		var u := lw / 2.0
		var x := r.end.x - u if h["mirror"] else r.position.x + u
		var z := r.end.y if face > 0 else r.position.y
		out.append([Vector3(x, 0, z), Vector3(0, 0, face), r.size.x])
	return out


func _add(group: String, n: Node3D) -> void:
	add_child(n)
	(_groups[group] as Array).append(n)


func _box(p: Node3D, size: Vector3, at: Vector3, c: Color, glow := 0.0) -> MeshInstance3D:
	var mi := RoomBuilder.box(p, size, at, c)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if glow > 0.0:
		var m: StandardMaterial3D = mi.material_override
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return mi


## A flag on a short pole leaning out from beside the front door.
func _flag(door: Vector3, out: Vector3) -> void:
	var g := Node3D.new()
	g.position = door + out * 0.25 + Vector3(1.05, 0, 0)
	g.rotation.y = 0.0 if out.z > 0 else PI
	_add("flags", g)
	var pole := _box(g, Vector3(0.04, 1.5, 0.04), Vector3(0, 2.2, 0.35), Palette.PAPER)
	pole.rotation.x = 0.6
	var cloth := Node3D.new()
	cloth.position = Vector3(0, 2.75, 0.75)
	g.add_child(cloth)
	for i in 7:
		_box(cloth, Vector3(0.01, 0.07, 0.75), Vector3(0, -i * 0.07, 0.38), Color("C0322A") if i % 2 == 0 else Palette.PAPER)
	_box(cloth, Vector3(0.016, 0.28, 0.32), Vector3(0, -0.105, 0.16), Color("2B3A7A"))
	for i in 6:
		_box(cloth, Vector3(0.02, 0.03, 0.03), Vector3(0, -0.04 - (i % 3) * 0.07, 0.07 + (i / 3) * 0.13), Palette.PAPER)


## Red, white and blue bunting along the front of the house.
func _bunting(door: Vector3, out: Vector3, width: float) -> void:
	var g := Node3D.new()
	g.position = door + out * 0.2
	_add("bunting", g)
	var x0 := -width * 0.42
	var cols := [Color("C0322A"), Palette.PAPER, Color("2B3A7A")]
	var n := int(width * 0.84 / 0.45)
	for i in n:
		var x := x0 + i * 0.45
		var sag := sin(float(i % 4) / 3.0 * PI) * 0.18
		var flap := _box(g, Vector3(0.36, 0.3, 0.01), Vector3(x, 2.45 - sag, 0), cols[i % 3])
		flap.rotation.z = PI / 4.0
		flap.scale = Vector3(1, 1, 1)


## Strings of colored Christmas lights along the front, and a wreath on the door.
func _lights(door: Vector3, out: Vector3, width: float) -> void:
	var g := Node3D.new()
	g.position = door + out * 0.3
	_add("christmas", g)
	var cols := [Color("FF4F4F"), Color("4FD84F"), Color("4F8AFF"), Color("FFD84F"), Color("FF8AE0")]
	var n := int(width * 0.9 / 0.3)
	for i in n:
		var x := -width * 0.45 + i * 0.3
		var y := 2.55 - absf(sin(float(i % 5) / 4.0 * PI)) * 0.05
		if _in_crown(g.position + g.basis * Vector3(x, y, 0), 0.12):
			continue
		_box(g, Vector3(0.07, 0.1, 0.07), Vector3(x, y, 0), cols[i % cols.size()], 1.4)
	# the wreath
	var w := Node3D.new()
	w.position = Vector3(0, 1.62, 0.04)
	g.add_child(w)
	for i in 10:
		var a := float(i) / 10.0 * TAU
		_box(w, Vector3(0.12, 0.12, 0.06), Vector3(cos(a) * 0.2, sin(a) * 0.2, 0), Color("2E6B3A"))
	_box(w, Vector3(0.14, 0.1, 0.07), Vector3(0, -0.22, 0.01), Color("C0322A"))


## True if a point is inside (or within `pad` of) a tree crown, so lights don't poke through leaves.
func _in_crown(p: Vector3, pad: float) -> bool:
	for n in get_tree().get_nodes_in_group("leaves"):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_inside_tree():
			continue
		var bb: AABB = mi.global_transform * mi.mesh.get_aabb()
		if bb.grow(pad).has_point(p):
			return true
	return false


## The Christmas tree in Jamie's living room, with presents under it (December).
func _tree_and_presents() -> void:
	var objs: Dictionary = main.room["objects"]
	var tree := Props.item(self, objs, "xmas_tree", "Christmas Tree", Vector3(6.3, 0, 5.2), 180)
	tree.kind = "xmas_tree"
	tree.home = "jamie"
	Props.part(tree, Vector3(0.4, 0.3, 0.4), Vector3(0, 0.15, 0), Color("C0322A"))
	for i in 4:
		var w := 1.3 - i * 0.28
		Props.part(tree, Vector3(w, 0.45, w), Vector3(0, 0.5 + i * 0.4, 0), Color("2E6B3A").lightened(i * 0.04))
	Props.part(tree, Vector3(0.18, 0.18, 0.18), Vector3(0, 2.15, 0), Color("F7D046"))
	var cols := [Color("FF4F4F"), Color("4F8AFF"), Color("FFD84F"), Color("FF8AE0")]
	for i in 14:
		var a := float(i) * 2.4
		var lvl := i % 4
		var rr := (1.3 - lvl * 0.28) / 2.0 + 0.01
		_box(tree, Vector3(0.055, 0.055, 0.055), Vector3(cos(a) * (rr + 0.007), 0.55 + lvl * 0.4, sin(a) * (rr + 0.007)), cols[i % 4], 1.2)
	for i in 4:
		Props.part(tree, Vector3(0.3, 0.22, 0.3), Vector3(-0.55 + i * 0.36, 0.11, 0.62), [Color("C0322A"), Color("2E8C8A"), Color("F7D046"), Color("7A4FB0")][i])
		_box(tree, Vector3(0.31, 0.04, 0.06), Vector3(-0.55 + i * 0.36, 0.205, 0.62), Palette.PAPER)
	var solids: Array[Rect2] = main.room["grid_lists"][4]
	Props.finish(tree, solids, Vector3(1.3, 2.2, 1.3), Vector3(0, 0, 1.25), null, Vector3(0, 0.6, 0))
	_tree_solid = solids.size() - 1
	_tree_rect = solids[_tree_solid]
	solids[_tree_solid] = Rect2()
	(_groups["christmas"] as Array).append(tree)
	(_objects["christmas"] as Array).append(tree)


## A roast turkey on every family's dining table (Thanksgiving).
func _turkeys() -> void:
	var objs: Dictionary = main.room["objects"]
	var tables := ["dining_table"]
	for k in NeighborBuilder.HOMES:
		tables.append(k + "_table")
	for tk in tables:
		var t: SmartObject = objs.get(tk)
		if t == null:
			continue
		var g := Node3D.new()
		_add("thanksgiving", g)
		g.global_transform = t.global_transform
		g.position = t.to_global(Vector3(0.18, 0.78, 0))
		_box(g, Vector3(0.44, 0.03, 0.32), Vector3(0, 0.015, 0), Palette.PAPER)                 # the platter
		_box(g, Vector3(0.32, 0.16, 0.22), Vector3(0, 0.11, 0), Color("B8743A"))                # the bird
		_box(g, Vector3(0.05, 0.05, 0.14), Vector3(-0.1, 0.1, 0.14), Color("C8844A"))           # drumsticks
		_box(g, Vector3(0.05, 0.05, 0.14), Vector3(0.1, 0.1, 0.14), Color("C8844A"))
		_box(g, Vector3(0.12, 0.06, 0.12), Vector3(-0.32, 0.03, 0), Color("E4704F"))            # cranberry and pie
		_box(g, Vector3(0.2, 0.05, 0.2), Vector3(0.36, 0.025, 0), Color("D9963A"))


## A picnic blanket in Jamie's front yard for watching the fireworks (July 4th).
func _fireworks_blanket() -> void:
	var objs: Dictionary = main.room["objects"]
	var b := Props.item(self, objs, "fireworks_blanket", "Picnic Blanket", Vector3(6.5, 0, 11.0), 180)
	b.kind = "fireworks_blanket"
	b.home = ""
	b.shared = true
	for i in 4:
		Props.part(b, Vector3(0.4, 0.02, 1.6), Vector3(-0.6 + i * 0.4, 0.02, 0), Color("C0322A") if i % 2 == 0 else Palette.PAPER)
	var none: Array[Rect2] = []
	Props.finish(b, none, Vector3(1.6, 0.05, 1.6), Vector3(0, 0, 1.2), Vector3(0, 0, 0), Vector3(3.0, 25.0, -20.0))
	(_groups["bunting"] as Array).append(b)
	(_objects["bunting"] as Array).append(b)


## Show what's up for today.
func refresh() -> void:
	var up := decor_up(main.clock)
	var grid_dirty := false
	var solids_list: Array = main.room["grid_lists"][4]
	for g in _groups:
		var on: bool = up.get(g, false)
		for n in _groups[g]:
			if is_instance_valid(n):
				(n as Node3D).visible = on
		for o in _objects[g]:
			(o as CollisionObject3D).collision_layer = 1 if on else 0
			if o is SmartObject and (o as SmartObject).kind == "easter_egg":
				var found: bool = _found_eggs.get(String(o.name), -1) == main.clock.year()
				(o as Node3D).visible = on and not found
				(o as CollisionObject3D).collision_layer = 1 if on and not found else 0
		for slot in _solid_slots.get(g, []):
			var want: Rect2 = slot[1] if on else Rect2()
			if solids_list[slot[0]] != want:
				solids_list[slot[0]] = want
				grid_dirty = true
	if grid_dirty:
		main.rebuild_grid()
	# the clowns are only around while the circus is in town; the fairgrounds sign says what's next
	for c: Npc in _clowns_list:
		c.hours = EventGrounds.HOURS_CIRCUS if up.get("circus", false) else Vector2(0, 0)
	_update_fair_board()
	for m in _fair_music:
		var on2: bool = up.get(m[0], false) and Activity.in_window(main.clock.hour_float(), 11.0, 23.0)
		var key := "fair_" + String(m[0])
		if on2 and not main.audio.has_loop(key):
			main.audio.start_loop(key, m[0], Vector3((m[1] as Vector2).x, 3.0, (m[1] as Vector2).y), -4.0, 1.0)
		elif not on2 and main.audio.has_loop(key):
			main.audio.stop_loop(key, 1.0)
	var night: bool = main.clock.hour_float() >= 18.0 or main.clock.hour_float() < 6.5
	for lm: StandardMaterial3D in _lanterns:
		lm.emission_energy_multiplier = 2.2 if night else 0.3
	# the Christmas tree takes up floor space while it's up
	var solids: Array = main.room["grid_lists"][4]
	var want := _tree_rect if up.get("christmas", false) else Rect2()
	if _tree_solid >= 0 and solids[_tree_solid] != want:
		solids[_tree_solid] = want
		main.rebuild_grid()
	var key := today(main.clock)
	if key != _last_key:
		var first := _last_key == "-"
		_last_key = key
		main.hud.set_holiday(("★ %s ★" % NAMES[key].to_upper()) if key != "" else "")
		if key != "" and not first:
			main.hud.notify(GREETINGS[key])


## Fireworks: July 4th 9-11 PM, and New Year's 12-1 AM.
func fireworks_now() -> bool:
	var key := today(main.clock)
	var h: float = main.clock.hour_float()
	return (key == "july4" and h >= 21.0 and h < 23.0) or (key == "newyear" and h < 1.0)


func _process(delta: float) -> void:
	# The rides turn while the carnival's in town
	if _spin.has("wheel") and (_spin["wheel"] as Node3D).visible:
		var th := Time.get_ticks_msec() * 0.001 * WHEEL_SPEED
		(_spin["wheel"] as Node3D).rotation.z = th
		for gp: Node3D in _spin["gondolas"]:
			gp.rotation.z = -th
		var ph := Time.get_ticks_msec() * 0.001 * CAROUSEL_SPEED
		(_spin["carousel"] as Node3D).rotation.y = ph
		var k := 0
		for hz: Node3D in _spin["horses"]:
			hz.position.y = 0.95 + sin(ph * 3.0 + k * 1.3) * 0.2
			k += 1
	if fireworks_now() and main.clock.speed_level > 0:
		_next_burst -= delta
		if _next_burst <= 0.0:
			_next_burst = randf_range(0.6, 1.8)
			_burst()
	for b in _bursts.duplicate():
		b["t"] += delta
		var t: float = b["t"]
		for p in b["parts"]:
			var mi: MeshInstance3D = p[0]
			mi.position = (p[1] as Vector3) * (1.0 - exp(-t * 2.2)) * 7.0 + Vector3(0, -t * t * 0.8, 0)
			var m: StandardMaterial3D = mi.material_override
			m.emission_energy_multiplier = maxf(0.0, 3.0 * (1.0 - t / 2.2))
			m.albedo_color.a = 1.0
		(b["light"] as OmniLight3D).light_energy = maxf(0.0, 2.5 * (1.0 - t / 0.9))
		if t > 2.2:
			(b["node"] as Node3D).queue_free()
			_bursts.erase(b)


func _burst() -> void:
	var g := Node3D.new()
	g.position = Vector3(randf_range(-4.0, 26.0), randf_range(13.0, 21.0), randf_range(34.0, 48.0))
	add_child(g)
	var col: Color = [Color("FF4F4F"), Color("4F8AFF"), Color("FFD84F"), Color("4FD84F"), Color("FF8AE0"), Palette.PAPER][randi() % 6]
	var parts := []
	for i in 26:
		var dir := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var mi := _box(g, Vector3(0.35, 0.35, 0.35), Vector3.ZERO, col, 3.0)
		parts.append([mi, dir])
	var l := OmniLight3D.new()
	l.light_color = col
	l.omni_range = 60.0
	l.light_energy = 2.5
	l.shadow_enabled = false
	g.add_child(l)
	_bursts.append({"node": g, "parts": parts, "t": 0.0, "light": l})
	main.audio.play_at("firework", g.global_position, 4.0)



# ================================================================ more holidays (and the events)

const WHEEL_SPEED := 0.25      # radians a second
const CAROUSEL_SPEED := 0.6


## Something that only shows during `group` (built by EventGrounds and below).
func _register(group: String, n: Node) -> void:
	if not (_groups[group] as Array).has(n):
		(_groups[group] as Array).append(n)


## A footprint in the solids list that only blocks the way while `group` is up.
func _register_solid(group: String, index: int) -> void:
	var solids: Array = main.room["grid_lists"][4]
	(_solid_slots[group] as Array).append([index, solids[index]])
	solids[index] = Rect2()


## Hearts on every house for Valentine's week.
func _hearts(door: Vector3, out: Vector3, width: float) -> void:
	var g := Node3D.new()
	g.position = door + out * 0.12
	g.rotation.y = 0.0 if out.z > 0 else PI
	_add("valentine", g)
	for k in 5:
		var x := -width * 0.36 + k * width * 0.18
		var heart := Node3D.new()
		heart.position = Vector3(x, 2.35 + (0.1 if k % 2 == 0 else -0.05), 0)
		g.add_child(heart)
		var col: Color = [Color("E8385A"), Color("FF8AB0"), Palette.PAPER][k % 3]
		var l := _box(heart, Vector3(0.2, 0.2, 0.03), Vector3(-0.07, 0.03, 0), col)
		l.rotation.z = PI / 4.0
		var r := _box(heart, Vector3(0.2, 0.2, 0.034), Vector3(0.07, 0.03, 0), col)
		r.rotation.z = -PI / 4.0
	# a big heart wreath on the door
	var w := Node3D.new()
	w.position = Vector3(0, 1.62, 0.04)
	g.add_child(w)
	var a := _box(w, Vector3(0.3, 0.3, 0.04), Vector3(-0.1, 0.05, 0), Color("E8385A"))
	a.rotation.z = PI / 4.0
	var b := _box(w, Vector3(0.3, 0.3, 0.044), Vector3(0.1, 0.05, 0), Color("E8385A"))
	b.rotation.z = -PI / 4.0


## A jack-o'-lantern on every porch (they glow after dark).
func _jack_o_lanterns() -> void:
	var objs: Dictionary = main.room["objects"]
	for k in objs:
		var p: SmartObject = objs[k]
		if p.kind != "porch":
			continue
		var out := p.approach_point - p.look_point
		out.y = 0.0
		out = out.normalized()
		var side := Vector3(out.z, 0, -out.x)
		var g := Node3D.new()
		g.position = Vector3(p.look_point.x, 0, p.look_point.z) + side * 1.05 + out * 0.15
		g.rotation.y = atan2(out.x, out.z)
		_add("halloween", g)
		_box(g, Vector3(0.42, 0.34, 0.42), Vector3(0, 0.17, 0), Color("E4782E"))
		_box(g, Vector3(0.06, 0.1, 0.06), Vector3(0, 0.39, 0), Color("4A6A2A"))
		var face := Node3D.new()
		face.position = Vector3(0, 0.18, 0.211)
		g.add_child(face)
		var glow := Color("FFD24A")
		var parts := [[Vector3(0.08, 0.07, 0.01), Vector3(-0.09, 0.05, 0)], [Vector3(0.08, 0.07, 0.01), Vector3(0.09, 0.05, 0)],
			[Vector3(0.24, 0.05, 0.01), Vector3(0, -0.07, 0)]]
		for fp in parts:
			var mi := _box(face, fp[0], fp[1], glow, 0.3)
			_lanterns.append(mi.material_override)
		# a little cobweb-y ghost hanging from the porch light
		var gh := Node3D.new()
		gh.position = Vector3(p.look_point.x, 0, p.look_point.z) - side * 0.9 + out * 0.2
		_add("halloween", gh)
		_box(gh, Vector3(0.26, 0.4, 0.26), Vector3(0, 1.95, 0), Palette.PAPER)
		_box(gh, Vector3(0.02, 0.3, 0.02), Vector3(0, 2.3, 0), Palette.INK2)


## Easter eggs in the front yards, and a basket in Jamie's living room.
func _easter_eggs() -> void:
	var objs: Dictionary = main.room["objects"]
	var cols := [Color("FF8AB0"), Color("8AD8FF"), Color("F7E26A"), Color("A8E88A"), Color("C8A2F2"), Color("FFB46A")]
	var n := 0
	var homes := ["jamie_porch"]
	for k in NeighborBuilder.HOMES:
		homes.append(k + "_porch")
	for hk in homes:
		var p: SmartObject = objs.get(hk)
		if p == null:
			continue
		var out := p.approach_point - p.look_point
		out.y = 0.0
		out = out.normalized()
		var side := Vector3(out.z, 0, -out.x)
		for e in 2:
			n += 1
			var at := Vector3(p.look_point.x, 0, p.look_point.z) + out * (3.2 + e * 1.6) + side * (2.6 if e == 0 else -3.0)
			var egg := Props.item(self, objs, "easter_egg_%d" % n, "Easter Egg", at, randf() * 360.0)
			egg.kind = "easter_egg"
			egg.home = "town"
			egg.shared = true
			Props.part(egg, Vector3(0.12, 0.16, 0.12), Vector3(0, 0.08, 0), cols[n % cols.size()])
			Props.part(egg, Vector3(0.124, 0.03, 0.124), Vector3(0, 0.09, 0), Palette.PAPER, null, false)
			var none: Array[Rect2] = []
			Props.finish(egg, none, Vector3(0.3, 0.3, 0.3), Vector3(0, 0, 0.7), null, Vector3(0, 0.1, 0))
			var a := Activity.make("Pick Up the Easter Egg", 2, {"fun": 30.0}, "reach")
			a.holidays = ["easter"]
			a.memory_id = "easter"
			a.messages = ["Found one! There's a jelly bean inside.", "A golden egg! ...It's painted. Still counts.", "Another one for the basket!"]
			egg.activities.append(a)
			_register("easter", egg)
			(_objects["easter"] as Array).append(egg)
	# the basket by the couch
	var b := Props.item(self, objs, "easter_basket", "Easter Basket", Vector3(1.6, 0, 4.9), 0)
	b.kind = "easter_basket"
	b.home = "jamie"
	Props.part(b, Vector3(0.5, 0.26, 0.36), Vector3(0, 0.13, 0), Color("C8A250"))
	Props.part(b, Vector3(0.44, 0.04, 0.3), Vector3(0, 0.27, 0), Color("8AE87A"))
	for k in 4:
		Props.part(b, Vector3(0.09, 0.12, 0.09), Vector3(-0.15 + k * 0.1, 0.33, 0.02 * (k % 2)), cols[k], null, false)
	Props.part(b, Vector3(0.04, 0.3, 0.04), Vector3(-0.23, 0.42, 0), Color("C8A250"), null, false)
	Props.part(b, Vector3(0.04, 0.3, 0.04), Vector3(0.23, 0.42, 0), Color("C8A250"), null, false)
	Props.part(b, Vector3(0.5, 0.04, 0.04), Vector3(0, 0.58, 0), Color("C8A250"), null, false)
	var none2: Array[Rect2] = []
	Props.finish(b, none2, Vector3(0.5, 0.6, 0.36), Vector3(0, 0, 0.7), null, Vector3(0, 0.3, 0))
	var ab := Activity.make("Dig Into Your Easter Basket", 10, {"hunger": 60.0, "fun": 40.0}, "reach")
	ab.holidays = ["easter"]
	ab.messages = ["A chocolate bunny! You bite the ears off first. Everybody does.", "Peeps! Marshmallow chicks!"]
	b.activities.append(ab)
	_register("easter", b)
	(_objects["easter"] as Array).append(b)


## The clowns (they walk around the fairgrounds while the circus is in town).
func _clowns() -> void:
	if _clown_route.is_empty():
		return
	var grid: AStarGrid2D = main.room["grid"]
	var looks := [{"gender": "boy", "hair": "perm", "hair_color": 0, "skin": 0, "adult": true, "hair_rgb": Color("FF5A1F"),
			"top_style": "colorblock", "top": Color("F7D046"), "stripe": Color("C0322A"), "pants": Color("2E5E9E"), "shoes": Color("C0322A")},
		{"gender": "girl", "hair": "teased", "hair_color": 0, "skin": 0, "adult": true, "hair_rgb": Color("4FD84F"),
			"top_style": "colorblock", "top": Color("FF8AB0"), "stripe": Color("4FC8FF"), "pants": Color("7A4FB0"), "shoes": Color("F7D046")}]
	var names := ["Bingo the Clown", "Giggles the Clown"]
	var lines := [["Honk honk! Want a balloon animal? It's a giraffe. Or a snake.", "I'm not scared of kids. Kids are scared of ME."],
		["Did you see the sixteen clowns get out of one car? I was the driver!", "Pull my finger! ...It's a flower!"]]
	for i in 2:
		var r := []
		for k in _clown_route.size():
			r.append(_clown_route[(k + i * 2) % _clown_route.size()])
		var c := TownFolk._make(main, main.room["objects"], "npc_clown_%d" % (i + 1), names[i], "walker", looks[i], lines[i], "town", grid)
		c.route = r
		c.hours = Vector2(0, 0)
		var nose := RoomBuilder.box(c._body, Vector3(0.07, 0.07, 0.06), Vector3(0, 1.29, -0.15), Color("E8203A"))
		nose.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		main.npcs.append(c)
		_clowns_list.append(c)


## The sign at the fairgrounds: what's coming next.
func _update_fair_board() -> void:
	var l: Label3D = main.room.get("fair_board_label")
	if l == null:
		return
	var y: int = main.clock.year()
	var now := Holidays.today(main.clock)
	var lines := []
	if now == "carnival" or now == "circus":
		lines.append("NOW: %s!" % NAMES[now].to_upper())
	for ev in ["carnival", "circus"]:
		var e := event_days(ev, y)
		var md: int = main.clock.month() * 100 + main.clock.day()
		var yy := y if md <= int(e[0]) * 100 + int(e[1]) + int(e[2]) - 1 else y + 1
		if yy != y:
			e = event_days(ev, yy)
		lines.append("%s: %s %d-%d" % [ev.to_upper(), ["", "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"][int(e[0])],
			int(e[1]), int(e[1]) + int(e[2]) - 1])
	l.text = "\n".join(lines)
	var o: SmartObject = main.room["objects"].get("fair_board")
	if o and not o.activities.is_empty():
		o.activities[0].messages = ["The sign says: " + " · ".join(lines)]


## An egg was found: it's gone until next Easter.
func found_egg(egg: SmartObject) -> void:
	_found_eggs[String(egg.name)] = main.clock.year()
	egg.visible = false
	egg.collision_layer = 0


## Holiday things to do on what every house already has (after content.gd).
static func add_activities(objects: Dictionary) -> void:
	for k in objects:
		var o: SmartObject = objects[k]
		var a: Activity
		match o.kind:
			"porch":
				a = Activity.make("Trick-or-Treat!", 5, {"fun": 50.0, "hunger": 20.0, "social": 20.0}, "stand")
				a.holidays = ["halloween"]
				a.from_hour = 17.5
				a.to_hour = 21.5
				a.memory_id = "halloween"
				a.messages = ["\"Trick or treat!\" You get a full-size candy bar. JACKPOT.", "Raisins. Ugh. Somebody always gives out raisins.",
					"\"Oh, what a scary costume!\" Two handfuls of candy corn.", "Nobody answers. There's a bowl that says TAKE ONE. You take two."]
				o.activities.append(a)
			"mailbox":
				a = Activity.make("Check for Valentines", 3, {"social": 40.0, "fun": 10.0}, "reach")
				a.holidays = ["valentine"]
				a.messages = ["A card with a cartoon bee: \"BEE MINE.\" No name. WHO?!", "Three valentines! One is from your grandma, but still.",
					"A valentine that says \"You're DINO-mite!\" with a dinosaur on it."]
				a.memory_id = "valentine"
				o.activities.append(a)
			"desk":
				if o.home != "town":
					a = Activity.make("Make Valentine Cards", 30, {"fun": 30.0, "social": 10.0}, "sit")
					a.holidays = ["valentine"]
					a.messages = ["Doilies, glitter and glue. Mostly glue.", "You write \"BE MINE\" on twelve of them. Your hand hurts."]
					o.activities.append(a)
			"dresser":
				for c in [["Dress Up as a Ghost", 17], ["Dress Up as a Vampire", 18]]:
					a = Activity.make(c[0], 10, {"fun": 40.0}, "reach")
					a.holidays = ["halloween"]
					a.buys = "outfit_%d" % c[1]
					a.money = 0.0
					a.autonomous = false
					o.activities.append(a)
			"fridge":
				a = Activity.make("Eat Candy Hearts", 5, {"hunger": 20.0, "fun": 20.0}, "reach")
				a.holidays = ["valentine"]
				a.messages = ["\"TEXT ME\"? \"UR CUTE\"? These candy hearts taste like chalk. You eat ten."]
				o.activities.append(a)
		if String(k).begins_with("npc_clown"):
			a = Activity.make("Get a Balloon Animal", 5, {"fun": 40.0}, "stand")
			a.holidays = ["circus"]
			a.messages = ["Squeak squeak squeak... a poodle! (It looks like a snake.)", "A balloon sword! En garde!"]
			o.activities.append(a)
