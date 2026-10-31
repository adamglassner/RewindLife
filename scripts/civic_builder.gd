class_name CivicBuilder
extends RefCounted
## Lincoln Avenue: the civic street behind the houses on Maple Street (take Oak
## Avenue north, or the footpath past the Garcias' garage).
##
##   z = -66  [ FOOTBALL FIELD x 38..78, goal posts, scoreboard ]
##   z = -58  [CITY HALL x -14..3] [MAPLE GROVE ELEMENTARY x 7..34]   bleachers
##   z = -41   portico, flagpole       front doors                      school bus
##   z = -37.6 ======= sidewalk ==============================================
##   z = -36   =======              LINCOLN AVENUE              ==============
##   z = -28   ======= sidewalk ==============================================
##   z = -25.4 [POLICE STATION x 1..15 + jail] [lot] [FIRE STATION x 25..41]
##   z = -12    backyard fences of Maple Street
##
## Every building is a real place you can walk into (in the House Cam the walls
## facing the camera come down, like the houses).

const Z0 := -36.0         # Lincoln Avenue's north curb
const Z1 := -28.0         # south curb
const T := 0.15

const POLICE := Rect2(1.0, -25.4, 14.0, 10.0)
const POLICE_LOT := Rect2(16.0, -25.4, 6.0, 9.0)
const FIRE := Rect2(25.0, -25.4, 16.0, 10.6)
const CITY_HALL := Rect2(-14.0, -54.0, 17.0, 13.0)
const SCHOOL := Rect2(7.0, -58.0, 27.0, 16.5)
const FIELD := Rect2(38.0, -66.0, 40.0, 20.0)
## The jail cell (the burglar sits out his 30 days in here).
const CELL := Rect2(9.5, -20.4, 5.5, 5.0)
const CELL_SPOT := Vector3(12.6, 0, -19.55)

## Opening hours of the civic buildings: [from, to, weekdays (empty = every day)].
const HOURS := {
	"police": [0.0, 24.0, []],
	"fire": [0.0, 24.0, []],
	"city_hall": [8.5, 17.0, [1, 2, 3, 4, 5]],
	"school": [7.5, 17.0, [1, 2, 3, 4, 5]],
}


static func rects() -> Array[Rect2]:
	return [POLICE, FIRE, CITY_HALL, SCHOOL]


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2]) -> void:
	var c := {"root": root, "out": out, "tex": tex, "solids": solids, "free": free, "doorways": doorways,
		"buildings": buildings, "objects": out["objects"], "home": "town", "level": 0}
	_street(c)
	_police(c)
	_fire(c)
	_city_hall(c)
	_school(c)
	_field(c)
	var h: Array = HOURS["city_hall"]
	DowntownBuilder._register_door(out, "city_hall", "City Hall", CITY_HALL, Vector2(h[0], h[1]), h[2])
	h = HOURS["school"]
	DowntownBuilder._register_door(out, "school", "Maple Grove Elementary", SCHOOL, Vector2(h[0], h[1]), h[2])


# ================================================================ the street

static func _street(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var out: Dictionary = c["out"]
	var asphalt := Color("4A4950")
	var concrete := Color("CFC8BA")
	OutdoorBuilder._slab(root, Rect2(-66, Z0 + 0.15, 152, Z1 - Z0 - 0.3), asphalt, tex["asphalt"], -0.015)
	for x in range(-64, 84, 4):
		if x + 2 < OutdoorBuilder.OAK_X0 or x > OutdoorBuilder.OAK_X1:
			OutdoorBuilder._slab(root, Rect2(x, (Z0 + Z1) / 2.0 - 0.06, 2.0, 0.12), Color("E8C24A"), null, -0.008)
	for z in [Z0, Z1 - 0.15]:
		for seg in [[-66.0, OutdoorBuilder.OAK_X0 - 0.01], [OutdoorBuilder.OAK_X1 + 0.01, 86.0]]:
			var len: float = seg[1] - seg[0]
			RoomBuilder.box(root, Vector3(len, 0.12, 0.15), Vector3(seg[0] + len / 2.0, 0.04, z + 0.075), Color("B9B2A5"))
	OutdoorBuilder._slab(root, Rect2(-66, Z0 - 1.6, 152, 1.6), concrete, tex["concrete"], 0.004)
	OutdoorBuilder._slab(root, Rect2(-66, Z1, 152, 1.6), concrete, tex["concrete"], 0.004)
	# A crosswalk from the school to the police station
	for x in [19.0, 20.0, 21.0]:
		OutdoorBuilder._slab(root, Rect2(x - 0.3, Z0, 0.6, Z1 - Z0), Palette.PAPER, null, -0.006)
	# The footpath from Maple Street, past the Garcias' garage
	OutdoorBuilder._slab(root, Rect2(37.2, Z1 + 1.6, 1.4, 14.0 - Z1 - 1.6), concrete, tex["concrete"], 0.003)
	for x in [-6.0, 14.0, 34.0, 54.0, 74.0]:
		OutdoorBuilder._streetlight(root, solids, out, Vector3(x, 0, Z0 - 1.3), 1.0)
	for x in [-10.0, 10.0, 46.0, 66.0]:
		OutdoorBuilder._streetlight(root, solids, out, Vector3(x, 0, Z1 + 1.3), -1.0)
	OutdoorBuilder._sign(root, solids, Vector3(-15.6, 0, Z1 + 0.9), "LINCOLN AVE", Color("2E6B4F"), Palette.PAPER, Vector2(1.1, 0.25), 0.0)
	OutdoorBuilder._sign(root, solids, Vector3(4.6, 0, Z0 - 0.6), "SCHOOL\nZONE", Color("F2C230"), Palette.INK, Vector2(0.6, 0.6), 180.0)
	OutdoorBuilder._sign(root, solids, Vector3(36.0, 0, Z1 + 0.7), "SCHOOL\nZONE", Color("F2C230"), Palette.INK, Vector2(0.6, 0.6), 0.0)
	OutdoorBuilder._hydrant(root, solids, Vector3(23.5, 0, Z1 + 1.35))
	OutdoorBuilder._hydrant(root, solids, Vector3(-2.0, 0, Z0 - 1.35))
	for x in [-1.0, 36.5, 44.0, 80.0]:
		OutdoorBuilder._tree(root, solids, Vector3(x, 0, Z0 - 3.2), 0.85)
	# The blue mailbox outside City Hall
	var mb := Props.solid(root, Vector3(-1.2, 0, Z0 - 1.0), 180)
	RoomBuilder.box(mb, Vector3(0.5, 0.75, 0.45), Vector3(0, 0.7, 0), Color("2E4A8A"))
	RoomBuilder.box(mb, Vector3(0.52, 0.12, 0.47), Vector3(0, 1.13, 0), Color("27407A"))
	for lx in [-0.2, 0.2]:
		RoomBuilder.box(mb, Vector3(0.05, 0.32, 0.05), Vector3(lx, 0.16, 0), Palette.INK2)
	Props.finish(mb, solids, Vector3(0.5, 1.2, 0.45), Vector3.ZERO)


# ================================================================ a public building

## Floor, ceiling, outside walls (with siding), a front door and a flat roof.
## `front` = -1: the front wall is the north side (r.position.y), facing -z;
## +1: the south side (r.end.y), facing +z. `ops` = more openings in the front wall.
static func _building(c: Dictionary, key: String, room_title: String, r: Rect2, hgt: float, front: float,
		door_x: float, inside: Color, surface: String, outside: Color, skin: String, floor_col: Color, floor_tex: String,
		ops: Array = [], double_door := true, door_color := Color("2E4A3A"), walk_end := INF) -> Dictionary:
	var root: Node3D = c["root"]
	var out: Dictionary = c["out"]
	var tex: Dictionary = c["tex"]
	RoomBuilder.make_floor(root, r, floor_col, tex.get(floor_tex))
	RoomBuilder.make_ceiling(root, out, r.grow(-T / 2.0), hgt)
	(c["buildings"] as Array).append(r)
	var fz := r.end.y if front > 0 else r.position.y
	var bz := r.position.y if front > 0 else r.end.y
	var dx := r.get_center().x
	var openings: Array = [{"c": door_x, "w": 1.6 if double_door else 1.0, "h": 2.4 if double_door else 2.2}]
	for o in ops:
		openings.append(o)
	var fw := RoomBuilder.make_wall(root, key + "Front", Vector3(dx, 0, fz), Vector3(r.size.x + T, hgt, T), Vector3(0, 0, front),
		tex, openings, false, inside, surface)
	var bw := RoomBuilder.make_wall(root, key + "Back", Vector3(dx, 0, bz), Vector3(r.size.x + T, hgt, T), Vector3(0, 0, -front),
		tex, [], false, inside, surface)
	var lw := RoomBuilder.make_wall(root, key + "Left", Vector3(r.position.x, 0, r.get_center().y), Vector3(T, hgt, r.size.y - T),
		Vector3(-1, 0, 0), tex, [], false, inside, surface)
	var rw := RoomBuilder.make_wall(root, key + "Right", Vector3(r.end.x, 0, r.get_center().y), Vector3(T, hgt, r.size.y - T),
		Vector3(1, 0, 0), tex, [], false, inside, surface)
	RoomBuilder.add_siding(fw, front, hgt, tex, -INF, INF, true, true, outside, skin)
	RoomBuilder.add_siding(bw, -front, hgt, tex, -INF, INF, true, true, outside, skin)
	RoomBuilder.add_siding(lw, -1.0, hgt, tex, -INF, INF, true, true, outside, skin)
	RoomBuilder.add_siding(rw, 1.0, hgt, tex, -INF, INF, true, true, outside, skin)
	for w in [fw, bw, lw, rw]:
		(out["walls"] as Array).append(w)
	var dw := 1.6 if double_door else 1.0
	var dh := 2.4 if double_door else 2.2
	RoomBuilder.make_casing(fw, door_x, dw, dh, Palette.INK2 if double_door else Palette.CREAM)
	var door: Dictionary
	if double_door:
		door = HouseBuilder.make_double_door(fw, door_x, dw, dh, door_color, Vector3(0, 0, -front))
	else:
		door = HouseBuilder.make_swing_door(fw, door_x, dw, dh, door_color, Vector3(0, 0, -front), false)
	(out["swing_doors"] as Array).append(door)
	# the threshold, and the doorway for the walking grid
	RoomBuilder.make_floor(root, Rect2(door_x - dw / 2.0, fz - 0.12 if front < 0 else fz, dw, 0.12), Palette.INK2)
	(c["doorways"] as Array).append(Rect2(door_x - 0.6, fz - 0.6, 1.2, 1.2))
	# a concrete walk out to the sidewalk
	var walk_to := (Z1 + 1.6 if front < 0 else Z0 - 1.6) if walk_end == INF else walk_end
	var w0 := minf(fz + front * 0.12, walk_to)
	var w1 := maxf(fz + front * 0.12, walk_to)
	if w1 - w0 > 0.05:
		OutdoorBuilder._slab(root, Rect2(door_x - 0.9, w0, 1.8, w1 - w0), Color("CFC8BA"), tex["concrete"], 0.006)
	# a flat roof with a little parapet (hidden in the House Cam, like every roof)
	var roof := RoomBuilder.box(root, Vector3(r.size.x + 0.4, 0.22, r.size.y + 0.4), Vector3(dx, hgt + 0.11, r.get_center().y), Color("5A5550"))
	(out["ceilings"] as Array).append(roof)
	var cap := RoomBuilder.box(root, Vector3(r.size.x + 0.5, 0.3, 0.12), Vector3(dx, hgt + 0.37, fz + front * 0.19), outside.darkened(0.15))
	(out["ceilings"] as Array).append(cap)
	(out["town_rooms"] as Dictionary)["town|" + room_title] = r
	return {"front": fw, "back": bw, "left": lw, "right": rw, "fz": fz, "door": door}


## An inside wall along x (constant z) or along z (constant x), with openings [[c, w, h], ...].
static func _partition(c: Dictionary, name: String, along_x: bool, plane: float, a: float, b: float, ops: Array, hgt: float,
		color: Color, surface := "panel") -> Dictionary:
	var openings := []
	for o in ops:
		openings.append({"c": o[0], "w": o[1], "h": o[2]})
	var center := Vector3((a + b) / 2.0, 0, plane) if along_x else Vector3(plane, 0, (a + b) / 2.0)
	var size := Vector3(b - a, hgt, T) if along_x else Vector3(T, hgt, b - a)
	var w := RoomBuilder.make_wall(c["root"], name, center, size, Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0), c["tex"],
		openings, true, color, surface)
	(c["out"]["walls"] as Array).append(w)
	for o in ops:
		RoomBuilder.make_casing(w, o[0], o[1], o[2], Palette.CREAM)
		if along_x:
			(c["doorways"] as Array).append(Rect2(float(o[0]) - float(o[1]) / 2.0 + 0.1, plane - 0.5, float(o[1]) - 0.2, 1.0))
		else:
			(c["doorways"] as Array).append(Rect2(plane - 0.5, float(o[0]) - float(o[1]) / 2.0 + 0.1, 1.0, float(o[1]) - 0.2))
	return w


static func _room(c: Dictionary, title: String, r: Rect2) -> void:
	(c["free"] as Array).append(r.grow(-T / 2.0))
	(c["out"]["town_rooms"] as Dictionary)["town|" + title] = r


## A sign over the door: a board and its lettering, on the front wall.
static func _sign(c: Dictionary, wall: Dictionary, x: float, y: float, fz: float, front: float, text: String, board: Color,
		ink: Color, w: float, font := 64) -> void:
	var b := RoomBuilder.box(wall["full"], Vector3(w, 0.7, 0.08), Vector3(x, y, fz + front * 0.17), board)
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := Label3D.new()
	l.text = text
	l.font_size = font
	l.pixel_size = 0.0045
	l.outline_size = 8
	l.modulate = ink
	l.outline_modulate = Color(0, 0, 0, 0.5)
	l.position = Vector3(x, y, fz + front * 0.216)
	l.rotation_degrees.y = 0.0 if front > 0 else 180.0
	l.double_sided = false
	(wall["full"] as Node3D).add_child(l)


static func _windows(c: Dictionary, wall: Dictionary, xs: Array, y: float, w: float, h: float, fz: float, front: float) -> void:
	var glass: StandardMaterial3D = c["out"]["window_mat"]
	for wx in xs:
		RoomBuilder.add_ext_window(wall["full"], Vector3(wx, y, fz + front * 0.125), Vector3(w, h, 0.04), c["out"])
		RoomBuilder.add_int_window(wall["full"], Vector3(wx, y + 0.05, fz - front * T / 2.0), w - 0.1, h - 0.05, true, -front, glass)


static func _label(parent: Node3D, text: String, pos: Vector3, yaw: float, color: Color, px := 0.004, font := 48) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font
	l.pixel_size = px
	l.modulate = color
	l.position = pos
	l.rotation_degrees.y = yaw
	l.double_sided = false
	parent.add_child(l)
	return l


## Someone who works here (TownFolk turns them into a person you can talk to).
static func _staff(c: Dictionary, id: String, title: String, pos: Vector3, yaw: float, look: Dictionary, talk: float,
		hours: Vector2, days: Array, lines: Array, workplace: String) -> void:
	if not c["out"].has("staff"):
		c["out"]["staff"] = []
	(c["out"]["staff"] as Array).append({"id": id, "title": title, "pos": pos, "yaw": yaw, "look": look, "talk": talk,
		"hours": hours, "days": days, "lines": lines, "work": workplace})


static func _usable(c: Dictionary, key: String, title: String, kind: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := Furnish.item(c, key, title, kind, pos, yaw)
	o.home = "town"
	return o


## A person-sized wall poster (Label3D on a paper box), on a wall face.
static func _poster(c: Dictionary, at: Vector3, yaw: float, text: String, paper := Palette.PAPER, ink := Palette.INK) -> void:
	var g := Node3D.new()
	g.position = at
	g.rotation_degrees.y = yaw
	(c["root"] as Node3D).add_child(g)
	RoomBuilder.box(g, Vector3(0.5, 0.7, 0.012), Vector3(0, 0, 0.006), paper)
	_label(g, text, Vector3(0, 0, 0.016), 0.0, ink, 0.0028, 40)


# ================================================================ police station

static func _police(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var r := POLICE
	var hgt := 3.4
	var px := 9.5                              # the wall between the front office and the jail
	var b := _building(c, "police", "Police Station", Rect2(r.position.x, r.position.y, px - r.position.x, r.size.y), hgt, -1.0,
		5.0, Color("D8DDE2"), "panel", Color("7A8A9A"), "brick", Color("5A6A7A"), "lino", [], true, Color("1F2A44"))
	# (the jail half shares the same outside shell, built as its own box next door)
	var jr := Rect2(px, r.position.y, r.end.x - px, r.size.y)
	RoomBuilder.make_floor(root, jr, Color("7A7A80"), tex["concrete"])
	RoomBuilder.make_ceiling(root, c["out"], jr.grow(-T / 2.0), hgt)
	(c["buildings"] as Array).append(jr)
	var jf := RoomBuilder.make_wall(root, "jailFront", Vector3(jr.get_center().x, 0, jr.position.y), Vector3(jr.size.x + T, hgt, T), Vector3(0, 0, -1),
		tex, [], false, Color("D8DDE2"), "panel")
	var jb := RoomBuilder.make_wall(root, "jailBack", Vector3(jr.get_center().x, 0, jr.end.y), Vector3(jr.size.x + T, hgt, T), Vector3(0, 0, 1),
		tex, [], false, Color("D8DDE2"), "panel")
	var je := RoomBuilder.make_wall(root, "jailRight", Vector3(jr.end.x, 0, jr.get_center().y), Vector3(T, hgt, jr.size.y - T),
		Vector3(1, 0, 0), tex, [], false, Color("D8DDE2"), "panel")
	for w in [jf, jb, je]:
		RoomBuilder.add_siding(w, (w["normal"] as Vector3).z if absf((w["normal"] as Vector3).z) > 0.5 else (w["normal"] as Vector3).x,
			hgt, tex, -INF, INF, true, true, Color("7A8A9A"), "brick")
		(c["out"]["walls"] as Array).append(w)
	var jroof := RoomBuilder.box(root, Vector3(jr.size.x + 0.2, 0.22, jr.size.y + 0.4), Vector3(jr.get_center().x + 0.1, hgt + 0.11, jr.get_center().y), Color("5A5550"))
	(c["out"]["ceilings"] as Array).append(jroof)
	# The wall between the office and the jail (b["right"] is it: the office's east wall), with a doorway
	var mid: Dictionary = b["right"]
	# (re-make it with an opening: hide the plain one)
	(mid["body"] as Node).queue_free()
	(c["out"]["walls"] as Array).erase(mid)
	_partition(c, "policeMid", false, px, r.position.y + T / 2.0, r.end.y - T / 2.0, [[r.position.y + 1.3, 1.0, 2.1]], hgt, Color("D8DDE2"))
	_room(c, "Police Station", Rect2(r.position.x, r.position.y, px - r.position.x, r.size.y))
	_room(c, "Jail", Rect2(px, r.position.y, jr.size.x, CELL.position.y - r.position.y))
	(c["free"] as Array).append(CELL.grow(-T / 2.0))
	(c["out"]["town_rooms"] as Dictionary)["town|Jail Cell"] = CELL
	_sign(c, b["front"], 5.0, 2.85, b["fz"], -1.0, "MAPLE GROVE POLICE", Color("1F2A44"), Color("F2F0E6"), 5.6)
	_windows(c, b["front"], [2.6, 7.4], 1.5, 1.3, 1.1, b["fz"], -1.0)
	# A blue lamp over the door
	var lamp := RoomBuilder.box(b["front"]["full"], Vector3(0.22, 0.3, 0.22), Vector3(5.0, 2.7, r.position.y - 0.32), Color("4A7AE8"))
	var lm: StandardMaterial3D = lamp.material_override
	lm.emission_enabled = true
	lm.emission = Color("4A7AE8")
	lm.emission_energy_multiplier = 0.8
	# ---- the front office
	var cc := {"root": root, "objects": c["objects"], "solids": solids, "out": c["out"], "tex": tex, "home": "town", "level": 0}
	var ct := Props.solid(root, Vector3(5.0, 0, r.position.y + 4.2), 0)
	RoomBuilder.box(ct, Vector3(3.2, 1.05, 0.6), Vector3(0, 0.525, 0), Color("3B4E6E"), tex["panel"], 2.0)
	RoomBuilder.box(ct, Vector3(3.26, 0.05, 0.66), Vector3(0, 1.075, 0), Palette.WOOD_DARK)
	RoomBuilder.box(ct, Vector3(0.3, 0.22, 0.2), Vector3(1.1, 1.21, 0.0), Palette.INK2)       # a radio
	RoomBuilder.box(ct, Vector3(0.24, 0.02, 0.32), Vector3(-0.6, 1.11, 0.05), Palette.PAPER)    # a report
	Props.finish(ct, solids, Vector3(3.2, 1.1, 0.6), Vector3.ZERO)
	_staff(c, "police_desk", "Sergeant Kowal", Vector3(5.6, 0, r.position.y + 4.95), 180.0,
		{"gender": "boy", "hair": "buzz", "hair_color": 2, "skin": 1, "adult": true, "top_style": "plain",
		"top": Color("2B3A6A"), "pants": Color("2B3A6A"), "shoes": Palette.INK}, 1.5, Vector2(7.0, 21.0), [],
		["Need to report something? Fill out form 27-B.", "Quiet night last night. I like quiet.",
		"Officer Dwyer's out on patrol. Want some advice? Lock your doors at night.",
		"We caught a cat burglar once. It was an actual cat. Long story."], "police")
	var bench := Props.solid(root, Vector3(r.position.x + 0.45, 0, r.position.y + 2.2), 90)
	RoomBuilder.box(bench, Vector3(1.8, 0.06, 0.45), Vector3(0, 0.45, 0), Palette.WOOD)
	RoomBuilder.box(bench, Vector3(1.8, 0.45, 0.06), Vector3(0, 0.7, -0.2), Palette.WOOD)
	for lx in [-0.8, 0.8]:
		RoomBuilder.box(bench, Vector3(0.06, 0.45, 0.4), Vector3(lx, 0.225, 0), Palette.INK2)
	Props.finish(bench, solids, Vector3(1.8, 0.9, 0.5), Vector3.ZERO)
	var wanted := _usable(c, "wanted_board", "Wanted Posters", "wanted_board", Vector3(px - T / 2.0 - 0.02, 0, r.position.y + 6.2), -90)
	Props.part(wanted, Vector3(1.6, 1.0, 0.03), Vector3(0, 1.55, 0.0), Color("8A6A4A"))
	for i in 3:
		Props.part(wanted, Vector3(0.42, 0.56, 0.012), Vector3(-0.5 + i * 0.5, 1.55, 0.021), Color("E8DCC0"), null, false)
		_label(wanted, "WANTED", Vector3(-0.5 + i * 0.5, 1.75, 0.031), 0.0, Color("8A2A1A"), 0.0022, 40)
		Props.part(wanted, Vector3(0.2, 0.22, 0.004), Vector3(-0.5 + i * 0.5, 1.5, 0.029), Color("6A5A4A"), null, false)
	Props.finish(wanted, solids, Vector3(1.6, 1.0, 0.06), Vector3(0, 0, 0.8), null, Vector3(0, 1.55, 0), Vector3(0, 1.55, 0))
	(solids as Array).pop_back()
	var desk := Props.solid(root, Vector3(r.position.x + 1.6, 0, r.end.y - 1.0), 180)
	RoomBuilder.box(desk, Vector3(1.4, 0.75, 0.7), Vector3(0, 0.375, 0), Palette.WOOD)
	RoomBuilder.box(desk, Vector3(0.45, 0.28, 0.35), Vector3(0.2, 0.89, 0), Color("4A4A52"))    # typewriter
	RoomBuilder.box(desk, Vector3(0.2, 0.1, 0.12), Vector3(-0.45, 0.8, 0.1), Palette.PAPER)    # coffee mug
	Props.finish(desk, solids, Vector3(1.4, 1.0, 0.7), Vector3.ZERO)
	var cooler := Props.solid(root, Vector3(px - 0.5, 0, r.end.y - 0.5), 0)
	RoomBuilder.box(cooler, Vector3(0.35, 1.0, 0.35), Vector3(0, 0.5, 0), Palette.PAPER)
	RoomBuilder.box(cooler, Vector3(0.28, 0.4, 0.28), Vector3(0, 1.2, 0), Color("8FC8E8"))
	Props.finish(cooler, solids, Vector3(0.35, 1.4, 0.35), Vector3.ZERO)
	Props.light(root, c["out"], Vector3(5.0, hgt - 0.4, r.get_center().y), Color("F2F4FF"), 8.0, 0.9, 1.8, null, false)
	# ---- the jail: a hallway, then the cell behind bars
	var bars := StaticBody3D.new()
	bars.collision_layer = 2
	bars.collision_mask = 0
	root.add_child(bars)
	var bz := CELL.position.y
	var door_c := px + 1.4
	var x := px + 0.15
	while x < r.end.x - 0.1:
		if absf(x - door_c) > 0.5:
			RoomBuilder.box(bars, Vector3(0.035, 2.4, 0.035), Vector3(x, 1.2, bz), Color("4A4A52"))
		x += 0.16
	RoomBuilder.box(bars, Vector3(jr.size.x - 0.16, 0.08, 0.06), Vector3(jr.get_center().x, 2.42, bz), Color("3A3A40"))
	RoomBuilder.box(bars, Vector3(jr.size.x - 0.16, 0.06, 0.06), Vector3(jr.get_center().x, 0.03, bz), Color("3A3A40"))
	RoomBuilder.add_shape(bars, Vector3(jr.size.x, 2.5, 0.12), Vector3(jr.get_center().x, 1.25, bz))
	solids.append(Rect2(px, bz - 0.06, jr.size.x, 0.12))
	var cd := _usable(c, "cell_door", "Cell Door", "cell_door", Vector3(door_c, 0, bz), 180)
	for i in 6:
		Props.part(cd, Vector3(0.035, 2.3, 0.035), Vector3(-0.4 + i * 0.16, 1.18, 0), Color("4A4A52"))
	Props.part(cd, Vector3(0.9, 0.06, 0.05), Vector3(0, 1.1, 0), Color("3A3A40"))
	Props.part(cd, Vector3(0.12, 0.16, 0.08), Vector3(0.36, 1.1, 0.0), Palette.GOLD)            # the lock
	Props.finish(cd, solids, Vector3(0.95, 2.4, 0.1), Vector3(0, 0, 0.8), null, Vector3(0, 1.2, 0))
	(solids as Array).pop_back()
	cd.door_rattle = cd.get_child(0)
	cd.rattle_dir = Vector3(0.01, 0, 0)
	# inside the cell: a cot, a toilet and a tiny barred window
	var cot := Props.solid(root, Vector3(r.end.x - 0.55, 0, CELL.get_center().y + 0.5), -90)
	RoomBuilder.box(cot, Vector3(1.9, 0.3, 0.75), Vector3(0, 0.35, 0), Color("6A6A70"))
	RoomBuilder.box(cot, Vector3(1.8, 0.1, 0.7), Vector3(0, 0.55, 0), Color("8A8A7A"))
	Props.finish(cot, solids, Vector3(1.9, 0.6, 0.75), Vector3.ZERO)
	var wc := Props.solid(root, Vector3(px + 0.45, 0, r.end.y - 0.45), 90)
	RoomBuilder.box(wc, Vector3(0.4, 0.42, 0.55), Vector3(0, 0.21, 0), Color("C8CCD0"))
	Props.finish(wc, solids, Vector3(0.4, 0.45, 0.55), Vector3.ZERO)
	for i in 4:
		RoomBuilder.box(jb["full"], Vector3(0.03, 0.6, 0.06), Vector3(12.0 + i * 0.15, 2.0, r.end.y - 0.1), Color("4A4A52"))
	RoomBuilder.box(jb["full"], Vector3(0.7, 0.66, 0.02), Vector3(12.22, 2.0, r.end.y - 0.084), Color("BFE0EE"))
	Props.light(root, c["out"], Vector3(jr.get_center().x, hgt - 0.4, CELL.get_center().y), Color("F2F4FF"), 5.0, 0.5, 0.9, null, false)
	Props.light(root, c["out"], Vector3(jr.get_center().x, hgt - 0.4, r.position.y + 2.5), Color("F2F4FF"), 5.0, 0.6, 1.2, null, false)
	c["out"]["cell_spot"] = CELL_SPOT
	# ---- the parking lot, with Officer Dwyer's car (see NpcVehicle)
	OutdoorBuilder._slab(root, POLICE_LOT, Color("55545C"), tex["asphalt"], 0.008)
	OutdoorBuilder._slab(root, Rect2(POLICE_LOT.position.x + 0.5, Z1, 5.0, 2.6), Color("C4BDB0"), tex["concrete"], 0.011)
	for lx in [16.5, 21.5]:
		OutdoorBuilder._slab(root, Rect2(lx - 0.05, POLICE_LOT.position.y + 2.5, 0.1, 5.5), Palette.PAPER, null, 0.011)
	_label(root, "POLICE\nONLY", Vector3(19.0, 0.012, POLICE_LOT.end.y - 1.0), 0.0, Palette.PAPER, 0.006, 64).rotation_degrees = Vector3(-90, 180, 0)


# ================================================================ fire station

static func _fire(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var r := FIRE
	var hgt := 4.4
	var mx := 33.6
	var bays := [{"c": 27.2, "w": 3.6, "h": 3.5}, {"c": 31.4, "w": 3.6, "h": 3.5}]
	var b := _building(c, "fire", "Fire Station", r, hgt, -1.0, 37.3, Color("E8E0D2"), "panel", Color("A83A2A"), "brick",
		Color("8A8A8A"), "concrete", bays, false, Color("C0322A"))
	for bay in bays:
		RoomBuilder.make_casing(b["front"], bay["c"], bay["w"], bay["h"], Palette.PAPER)
		(c["doorways"] as Array).append(Rect2(float(bay["c"]) - 1.6, r.position.y - 0.6, 3.2, 1.2))
		# the rolled-up door at the top of each bay
		RoomBuilder.box(b["front"]["full"], Vector3(3.5, 0.5, 0.3), Vector3(bay["c"], 3.3, r.position.y + 0.25), Color("D9D2C2"))
	_partition(c, "fireMid", false, mx, r.position.y + T / 2.0, r.end.y - T / 2.0, [[r.end.y - 2.2, 0.9, 2.1]], hgt, Color("E8E0D2"))
	(c["free"] as Array).append(Rect2(r.position.x, r.position.y, mx - r.position.x, r.size.y).grow(-T / 2.0))
	(c["free"] as Array).append(Rect2(mx, r.position.y, r.end.x - mx, r.size.y).grow(-T / 2.0))
	(c["out"]["town_rooms"] as Dictionary)["town|Fire Station"] = Rect2(r.position.x, r.position.y, mx - r.position.x, r.size.y)
	(c["out"]["town_rooms"] as Dictionary)["town|Firehouse Kitchen"] = Rect2(mx, r.position.y, r.end.x - mx, r.size.y)
	_sign(c, b["front"], 33.0, 3.95, b["fz"], -1.0, "MAPLE GROVE FIRE DEPT.   ENGINE CO. 1", Color("F2F0E6"), Color("A83A2A"), 9.0, 56)
	_windows(c, b["front"], [39.4], 1.5, 1.2, 1.1, b["fz"], -1.0)
	# The aprons in front of the bays, across the sidewalk to the street
	OutdoorBuilder._slab(root, Rect2(r.position.x + 0.2, Z1, mx - r.position.x - 0.4, r.position.y - Z1), Color("C4BDB0"), tex["concrete"], 0.011)
	# ---- inside the bays: hoses, helmets, the fire pole
	for i in 4:
		var hk := Props.solid(root, Vector3(r.position.x + 0.3, 0, r.position.y + 3.0 + i * 1.6), 90)
		RoomBuilder.box(hk, Vector3(0.9, 1.8, 0.4), Vector3(0, 0.9, 0), Color("6B4429"))
		RoomBuilder.box(hk, Vector3(0.4, 0.3, 0.38), Vector3(0.2, 1.9, 0.02), Color("E8C24A") if i % 2 == 0 else Color("C0322A"))   # a helmet
		RoomBuilder.box(hk, Vector3(0.7, 0.9, 0.3), Vector3(0, 0.75, 0.15), Color("B8A070"))       # turnout coat
		Props.finish(hk, solids, Vector3(0.9, 2.1, 0.5), Vector3.ZERO)
	var pole := _usable(c, "fire_pole", "Fire Pole", "fire_pole", Vector3(mx - 1.2, 0, r.end.y - 1.3), 0)
	Props.part(pole, Vector3(0.08, hgt, 0.08), Vector3(0, hgt / 2.0, 0), Color("D8D8D0"))
	Props.part(pole, Vector3(0.9, 0.08, 0.9), Vector3(0, 0.04, 0), Color("2B2B30"), null, false)
	Props.finish(pole, solids, Vector3(0.3, hgt, 0.3), Vector3(0, 0, 0.6), Vector3(0, 0, 0.22), Vector3(0, 2.0, 0))
	var hose := Props.solid(root, Vector3(mx - 0.5, 0, r.position.y + 1.4), -90)
	for i in 3:
		RoomBuilder.box(hose, Vector3(0.6, 0.6, 0.2), Vector3(0, 0.3 + i * 0.62, -0.1 + i * 0.002), Color("D8C890"))
	Props.finish(hose, solids, Vector3(0.6, 1.9, 0.3), Vector3.ZERO)
	# ---- the kitchen and bunk room, on the east side
	var cc := {"root": root, "objects": c["objects"], "solids": solids, "out": c["out"], "tex": tex, "home": "town", "level": 0}
	var tb := Furnish.table(cc, "firehouse_table", "Firehouse Table", Vector3(37.0, 0, r.position.y + 4.6), 0, Color("8A5A3B"), Vector2(1.6, 0.9))
	tb.kind = "firehouse_table"
	tb.home = "town"
	Furnish.counter(cc, Vector3(r.end.x - 0.4, 0, r.position.y + 2.2), -90, 2.0)
	var stove := Props.solid(root, Vector3(r.end.x - 0.4, 0, r.position.y + 3.7), -90)
	RoomBuilder.box(stove, Vector3(0.76, 0.9, 0.62), Vector3(0, 0.45, 0), Palette.PAPER)
	RoomBuilder.box(stove, Vector3(0.4, 0.3, 0.4), Vector3(0, 1.05, 0), Color("8C8C8C"))     # the chili pot
	Props.finish(stove, solids, Vector3(0.76, 1.2, 0.62), Vector3.ZERO)
	for i in 2:
		var bunk := Furnish.bed(cc, "fire_bunk_%d" % (i + 1), "Bunk", "fire_bunk", Vector3(mx + 1.0 + i * 3.4, 0, r.end.y - 1.2), 90,
			Color("6A7A4A"), false, 1.0, true)
		bunk.home = "town"
		bunk.add_material(RoomBuilder.box(bunk, Vector3(1.05, 0.25, 2.05), Vector3(0, 1.45, 0), Palette.WOOD_DARK).material_override)
		RoomBuilder.box(bunk, Vector3(0.98, 0.15, 1.95), Vector3(0, 1.65, 0), Color("6A7A4A"))
		for lz in [-0.95, 0.95]:
			RoomBuilder.box(bunk, Vector3(0.06, 1.7, 0.06), Vector3(-0.5, 0.85, lz), Palette.WOOD_DARK)
	var bell := Props.solid(root, Vector3(mx + 0.16, 0, r.position.y + 2.0), 90)
	RoomBuilder.box(bell, Vector3(0.36, 0.36, 0.2), Vector3(0, 2.0, 0.1), Palette.GOLD)
	Props.finish(bell, solids, Vector3(0.4, 0.4, 0.3), Vector3.ZERO, null, null, Vector3(0, 2.0, 0.1))
	(solids as Array).pop_back()
	Props.light(root, c["out"], Vector3(29.3, hgt - 0.5, r.get_center().y), Color("FFF1D6"), 9.0, 0.8, 1.8, null, false)
	Props.light(root, c["out"], Vector3(37.3, hgt - 0.5, r.get_center().y), Color("FFF1D6"), 7.0, 0.7, 1.6, null, false)
	_staff(c, "fire_captain", "Captain Riley", Vector3(36.0, 0, r.position.y + 5.9), 180.0,
		{"gender": "boy", "hair": "feathered", "hair_color": 2, "skin": 0, "adult": true, "top_style": "plain",
		"top": Color("2B3A5A"), "pants": Color("2B2B30"), "shoes": Palette.INK}, 1.0, Vector2(7.0, 22.0), [],
		["Stop, drop and roll! That's the only drill you need, kid.", "We run a drill every day at eleven and four. Listen for the siren!",
		"Sparky's the best firedog in the county. Don't tell the other firedogs.", "Want to slide down the pole? Everybody wants to slide down the pole."],
		"fire")
	c["out"]["fire_bays"] = [Vector3(27.2, 0, r.position.y + 5.1), Vector3(31.4, 0, r.position.y + 5.1)]


# ================================================================ city hall

static func _city_hall(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var r := CITY_HALL
	var hgt := 4.6
	var dx := r.get_center().x
	var bz := -48.0
	var b := _building(c, "cityhall", "City Hall", Rect2(r.position.x, bz, r.size.x, r.end.y - bz), hgt, 1.0, dx,
		Color("EDE6D6"), "panel", Color("D9D2C2"), "brick", Color("8A6A4A"), "panel", [], true, Color("4A2E1E"))
	# (the back offices: built as one more box behind the lobby)
	var back_r := Rect2(r.position.x, r.position.y, r.size.x, bz - r.position.y)
	RoomBuilder.make_floor(root, back_r, Color("6B2E2E"), tex["carpet"])
	RoomBuilder.make_ceiling(root, c["out"], back_r.grow(-T / 2.0), hgt)
	(c["buildings"] as Array).append(back_r)
	var bw := RoomBuilder.make_wall(root, "cityhallRear", Vector3(dx, 0, r.position.y), Vector3(r.size.x + T, hgt, T), Vector3(0, 0, -1),
		tex, [], false, Color("EDE6D6"), "panel")
	var lw := RoomBuilder.make_wall(root, "cityhallRearL", Vector3(r.position.x, 0, back_r.get_center().y + T / 2.0), Vector3(T, hgt, back_r.size.y),
		Vector3(-1, 0, 0), tex, [], false, Color("EDE6D6"), "panel")
	var rw := RoomBuilder.make_wall(root, "cityhallRearR", Vector3(r.end.x, 0, back_r.get_center().y + T / 2.0), Vector3(T, hgt, back_r.size.y),
		Vector3(1, 0, 0), tex, [], false, Color("EDE6D6"), "panel")
	RoomBuilder.add_siding(bw, -1.0, hgt, tex, -INF, INF, true, true, Color("D9D2C2"), "brick")
	RoomBuilder.add_siding(lw, -1.0, hgt, tex, -INF, INF, true, true, Color("D9D2C2"), "brick")
	RoomBuilder.add_siding(rw, 1.0, hgt, tex, -INF, INF, true, true, Color("D9D2C2"), "brick")
	for w in [bw, lw, rw]:
		(c["out"]["walls"] as Array).append(w)
	var broof := RoomBuilder.box(root, Vector3(back_r.size.x + 0.4, 0.22, back_r.size.y + 0.2), Vector3(dx, hgt + 0.11, back_r.get_center().y - 0.1), Color("5A5550"))
	(c["out"]["ceilings"] as Array).append(broof)
	# The lobby's back wall becomes the wall between the lobby and the offices, with two doors
	var old: Dictionary = b["back"]
	(old["body"] as Node).queue_free()
	(c["out"]["walls"] as Array).erase(old)
	var mayor_x := -9.5
	var rec_x := -1.0
	_partition(c, "cityhallMid", true, bz, r.position.x + T / 2.0, r.end.x - T / 2.0, [[mayor_x, 0.95, 2.2], [rec_x, 0.95, 2.2]], hgt, Color("EDE6D6"))
	_partition(c, "cityhallOffices", false, -5.0, r.position.y + T / 2.0, bz - T / 2.0, [], hgt, Color("EDE6D6"))
	_room(c, "City Hall", Rect2(r.position.x, bz, r.size.x, r.end.y - bz))
	_room(c, "Mayor's Office", Rect2(r.position.x, r.position.y, -5.0 - r.position.x, bz - r.position.y))
	_room(c, "Town Records", Rect2(-5.0, r.position.y, r.end.x + 5.0, bz - r.position.y))
	_sign(c, b["front"], dx, 3.9, b["fz"], 1.0, "MAPLE GROVE CITY HALL", Color("EDE6D6"), Color("4A3A2A"), 7.0)
	_windows(c, b["front"], [r.position.x + 2.2, r.position.x + 5.0, r.end.x - 5.0, r.end.x - 2.2], 1.7, 1.1, 1.6, b["fz"], 1.0)
	# The portico: columns, a pediment and wide steps
	var fz: float = b["fz"]
	for cx in [r.position.x + 1.0, r.position.x + 4.0, dx - 1.6, dx + 1.6, r.end.x - 4.0, r.end.x - 1.0]:
		var col := Props.solid(root, Vector3(cx, 0, fz + 1.35), 0)
		RoomBuilder.box(col, Vector3(0.5, 4.1, 0.5), Vector3(0, 2.15, 0), Color("F2EEE2"))
		RoomBuilder.box(col, Vector3(0.7, 0.2, 0.7), Vector3(0, 0.1, 0), Color("E2DCCC"))
		RoomBuilder.box(col, Vector3(0.66, 0.22, 0.66), Vector3(0, 4.3, 0), Color("E2DCCC"))
		Props.finish(col, solids, Vector3(0.6, 4.4, 0.6), Vector3.ZERO)
	var portico := RoomBuilder.box(root, Vector3(r.size.x + 0.6, 0.4, 2.0), Vector3(dx, hgt + 0.0, fz + 1.05), Color("E2DCCC"))
	(c["out"]["ceilings"] as Array).append(portico)
	var ped := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(r.size.x + 0.6, 1.3, 0.3)
	ped.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color("F2EEE2")
	ped.material_override = pmat
	ped.position = Vector3(dx, hgt + 0.85, fz + 1.9)
	root.add_child(ped)
	(c["out"]["ceilings"] as Array).append(ped)
	OutdoorBuilder._slab(root, Rect2(r.position.x - 0.3, fz, r.size.x + 0.6, 2.2), Color("D9D2C2"), tex["concrete"], 0.03)
	OutdoorBuilder._slab(root, Rect2(dx - 3.0, fz + 2.2, 6.0, 0.6), Color("D9D2C2"), tex["concrete"], 0.015)
	# A clock tower cupola on the roof
	var cup := RoomBuilder.box(root, Vector3(2.4, 2.2, 2.4), Vector3(dx, hgt + 1.3, bz + 1.0), Color("F2EEE2"))
	(c["out"]["ceilings"] as Array).append(cup)
	var face := RoomBuilder.box(root, Vector3(1.3, 1.3, 0.06), Vector3(dx, hgt + 1.4, bz + 2.23), Palette.PAPER)
	(c["out"]["ceilings"] as Array).append(face)
	var hand := RoomBuilder.box(root, Vector3(0.06, 0.5, 0.02), Vector3(dx, hgt + 1.55, bz + 2.27), Palette.INK)
	(c["out"]["ceilings"] as Array).append(hand)
	var dome := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 1.5
	cm.height = 1.6
	cm.radial_segments = 4
	dome.mesh = cm
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color("3E6A5A")
	dome.material_override = dm
	dome.rotation_degrees.y = 45.0
	dome.position = Vector3(dx, hgt + 3.2, bz + 1.0)
	root.add_child(dome)
	(c["out"]["ceilings"] as Array).append(dome)
	# The flagpole out front
	var fp := Props.solid(root, Vector3(r.position.x + 1.5, 0, Z0 - 2.4), 0)
	RoomBuilder.box(fp, Vector3(0.1, 7.0, 0.1), Vector3(0, 3.5, 0), Palette.MUTED)
	for i in 7:
		RoomBuilder.box(fp, Vector3(0.01, 0.12, 1.4), Vector3(0.06, 6.7 - i * 0.12, 0.75), Color("C0322A") if i % 2 == 0 else Palette.PAPER)
	RoomBuilder.box(fp, Vector3(0.02, 0.48, 0.6), Vector3(0.062, 6.52, 0.35), Color("2E3A6A"))
	Props.finish(fp, solids, Vector3(0.3, 7.0, 0.3), Vector3.ZERO)
	# ---- the lobby: the clerk's counter, the bulletin board, the founder's portrait
	var ct := Props.solid(root, Vector3(r.end.x - 3.0, 0, bz + 2.4), 180)
	RoomBuilder.box(ct, Vector3(3.6, 1.05, 0.6), Vector3(0, 0.525, 0), Palette.WOOD_DARK, tex["panel"], 2.0)
	RoomBuilder.box(ct, Vector3(3.66, 0.05, 0.66), Vector3(0, 1.075, 0), Color("5A3A24"))
	RoomBuilder.box(ct, Vector3(0.3, 0.06, 0.4), Vector3(-1.0, 1.13, 0.0), Palette.PAPER)
	Props.finish(ct, solids, Vector3(3.6, 1.1, 0.6), Vector3.ZERO)
	_staff(c, "town_clerk", "Mrs. Pruitt", Vector3(r.end.x - 3.0, 0, bz + 1.65), 0.0,
		{"gender": "girl", "hair": "bun", "hair_color": 5, "skin": 0, "adult": true, "top_style": "plain",
		"top": Color("8A5A7A"), "pants": Color("4A3A4A"), "shoes": Color("2B2020")}, 1.5, Vector2(8.5, 17.0), [1, 2, 3, 4, 5],
		["Dog license? Building permit? Complaint about the Hendersons' hedge?", "City Hall was built in 1911. The plumbing was built in 1911, too.",
		"The Mayor's in a meeting. The Mayor is always in a meeting."], "city_hall")
	var board := _usable(c, "town_bulletin", "Town Bulletin Board", "bulletin", Vector3(r.position.x + T / 2.0 + 0.02, 0, bz + 3.5), 90)
	Props.part(board, Vector3(1.8, 1.1, 0.04), Vector3(0, 1.6, 0.0), Color("B88A5A"))
	for i in 5:
		Props.part(board, Vector3(0.3, 0.4, 0.008), Vector3(-0.66 + i * 0.33, 1.6 + (0.15 if i % 2 == 0 else -0.15), 0.024),
			[Palette.PAPER, Color("F7E99A"), Color("BFE0EE"), Palette.PAPER, Color("F2A0B5")][i], null, false)
	_label(board, "TOWN NEWS", Vector3(0, 2.05, 0.03), 0.0, Palette.INK, 0.0028, 48)
	Props.finish(board, solids, Vector3(1.8, 1.1, 0.06), Vector3(0, 0, 0.8), null, Vector3(0, 1.6, 0), Vector3(0, 1.6, 0))
	(solids as Array).pop_back()
	var portrait := RoomBuilder.box(root, Vector3(0.9, 1.2, 0.05), Vector3(dx, 2.3, bz + T / 2.0 + 0.03), Color("6B4429"))
	portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	RoomBuilder.box(root, Vector3(0.7, 1.0, 0.02), Vector3(dx, 2.3, bz + T / 2.0 + 0.065), Color("5A4A3A"))
	RoomBuilder.box(root, Vector3(0.8, 0.3, 0.02), Vector3(dx, 1.55, bz + T / 2.0 + 0.012), Color("3A2A1A"))
	_label(root, "EZRA MAPLE\nFOUNDER, 1852", Vector3(dx, 1.55, bz + T / 2.0 + 0.026), 0.0, Palette.GOLD, 0.0025, 40)
	var bench := Props.solid(root, Vector3(r.position.x + 3.5, 0, r.end.y - 0.6), 180)
	RoomBuilder.box(bench, Vector3(1.8, 0.06, 0.45), Vector3(0, 0.45, 0), Palette.WOOD)
	RoomBuilder.box(bench, Vector3(1.8, 0.45, 0.06), Vector3(0, 0.7, -0.2), Palette.WOOD)
	for lx in [-0.8, 0.8]:
		RoomBuilder.box(bench, Vector3(0.06, 0.45, 0.4), Vector3(lx, 0.225, 0), Palette.INK2)
	Props.finish(bench, solids, Vector3(1.8, 0.9, 0.5), Vector3.ZERO)
	Props.light(root, c["out"], Vector3(dx, hgt - 0.5, bz + 3.5), Color("FFF1D6"), 10.0, 0.9, 1.8, null, false)
	# ---- the Mayor's office
	var cc := {"root": root, "objects": c["objects"], "solids": solids, "out": c["out"], "tex": tex, "home": "town", "level": 0}
	var md := Props.solid(root, Vector3(-9.5, 0, r.position.y + 2.0), 0)
	RoomBuilder.box(md, Vector3(2.2, 0.8, 0.95), Vector3(0, 0.4, 0), Color("5A3A24"))
	RoomBuilder.box(md, Vector3(2.26, 0.05, 1.01), Vector3(0, 0.825, 0), Color("3A2A1A"))
	RoomBuilder.box(md, Vector3(0.36, 0.06, 0.26), Vector3(0.5, 0.88, 0.1), Palette.PAPER)
	RoomBuilder.box(md, Vector3(0.12, 0.2, 0.12), Vector3(-0.7, 0.95, -0.2), Palette.GOLD)     # a pen stand
	Props.finish(md, solids, Vector3(2.2, 0.9, 0.95), Vector3.ZERO)
	_staff(c, "mayor", "Mayor Thornton", Vector3(-9.5, 0, r.position.y + 1.1), 0.0,
		{"gender": "boy", "hair": "feathered", "hair_color": 5, "skin": 1, "adult": true, "top_style": "plain",
		"top": Color("2B2B30"), "pants": Color("2B2B30"), "shoes": Palette.INK}, 1.6, Vector2(10.0, 16.0), [1, 2, 3, 4, 5],
		["Vote Thornton! ...Oh, you're a kid. Tell your parents. Vote Thornton!", "Maple Grove: the friendliest town in the state. I had a banner made.",
		"The new mall's going to put us on the map. Grand opening soon!", "A burglar? In MY town? Not on my watch!"], "city_hall")
	Furnish.bookshelf(cc, "mayor_books", Vector3(r.position.x + 0.4, 0, r.position.y + 2.6), 90, 7)
	var mflag := Props.solid(root, Vector3(-6.0, 0, r.position.y + 0.6), 0)
	RoomBuilder.box(mflag, Vector3(0.05, 2.3, 0.05), Vector3(0, 1.15, 0), Palette.GOLD)
	RoomBuilder.box(mflag, Vector3(0.6, 0.4, 0.01), Vector3(0.32, 2.0, 0), Color("2E3A6A"))
	Props.finish(mflag, solids, Vector3(0.3, 2.3, 0.3), Vector3.ZERO)
	for cx in [-10.2, -8.8]:
		var chair := Props.solid(root, Vector3(cx, 0, r.position.y + 3.4), 180)
		RoomBuilder.box(chair, Vector3(0.5, 0.45, 0.5), Vector3(0, 0.225, 0), Color("6B2E2E"))
		RoomBuilder.box(chair, Vector3(0.5, 0.5, 0.1), Vector3(0, 0.7, -0.2), Color("6B2E2E"))
		Props.finish(chair, solids, Vector3(0.5, 0.95, 0.5), Vector3.ZERO)
	Props.light(root, c["out"], Vector3(-9.5, hgt - 0.5, r.position.y + 3.0), Color("FFF1D6"), 6.0, 0.8, 1.5, null, false)
	# ---- town records: file cabinets and a big map of Maple Grove
	for i in 5:
		var fc := Props.solid(root, Vector3(-4.3 + i * 0.75, 0, r.position.y + 0.4), 0)
		RoomBuilder.box(fc, Vector3(0.6, 1.35, 0.6), Vector3(0, 0.675, 0), Color("7A8A7A"))
		for d in 4:
			RoomBuilder.box(fc, Vector3(0.12, 0.03, 0.03), Vector3(0, 0.25 + d * 0.32, 0.31), Palette.MUTED)
		Props.finish(fc, solids, Vector3(0.6, 1.35, 0.6), Vector3.ZERO)
	var map := _usable(c, "town_map", "Map of Maple Grove", "town_map", Vector3(r.end.x - T / 2.0 - 0.02, 0, r.position.y + 3.0), -90)
	Props.part(map, Vector3(2.0, 1.3, 0.03), Vector3(0, 1.6, 0), Color("E8DCC0"))
	Props.part(map, Vector3(1.8, 0.06, 0.006), Vector3(0, 1.85, 0.018), Color("4A4950"), null, false)
	Props.part(map, Vector3(1.8, 0.06, 0.006), Vector3(0, 1.35, 0.018), Color("4A4950"), null, false)
	Props.part(map, Vector3(0.06, 1.1, 0.006), Vector3(-0.8, 1.6, 0.018), Color("4A4950"), null, false)
	_label(map, "MAPLE GROVE, U.S.A.", Vector3(0, 2.15, 0.024), 0.0, Palette.INK, 0.0025, 40)
	Props.finish(map, solids, Vector3(2.0, 1.3, 0.06), Vector3(0, 0, 0.8), null, Vector3(0, 1.6, 0), Vector3(0, 1.6, 0))
	(solids as Array).pop_back()
	Props.light(root, c["out"], Vector3(-1.0, hgt - 0.5, r.position.y + 3.0), Color("FFF1D6"), 6.0, 0.8, 1.5, null, false)


# ================================================================ the school

static func _school(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var r := SCHOOL
	var hgt := 4.0
	var hz := -45.5           # the hallway's back wall
	var b := _building(c, "school", "School Hallway", Rect2(r.position.x, hz, r.size.x, r.end.y - hz), hgt, 1.0, 20.5,
		Color("F2E8C8"), "panel", Color("B5654A"), "brick", Color("C8C0A8"), "lino", [], true, Color("2E5E9E"))
	var back_r := Rect2(r.position.x, r.position.y, r.size.x, hz - r.position.y)
	RoomBuilder.make_floor(root, Rect2(back_r.position.x, back_r.position.y, 18.0, back_r.size.y), Color("C8B08A"), tex["lino"])
	RoomBuilder.make_floor(root, Rect2(back_r.position.x + 18.0, back_r.position.y, back_r.size.x - 18.0, back_r.size.y), Color("C89A5A"), tex["panel"])
	RoomBuilder.make_ceiling(root, c["out"], back_r.grow(-T / 2.0), hgt)
	(c["buildings"] as Array).append(back_r)
	# (v1.7: doors through the back wall into the new wing: SchoolBuilder)
	var wing_doors := [r.position.x + 1.2, r.position.x + 13.5, r.end.x - 1.5]
	var wops := []
	for wx in wing_doors:
		wops.append({"c": wx, "w": 0.95, "h": 2.2})
	var bw := RoomBuilder.make_wall(root, "schoolRear", Vector3(r.get_center().x, 0, r.position.y), Vector3(r.size.x + T, hgt, T), Vector3(0, 0, -1),
		tex, wops, true, Color("F2E8C8"), "panel")
	for wx in wing_doors:
		RoomBuilder.make_casing(bw, wx, 0.95, 2.2, Palette.CREAM)
		(c["doorways"] as Array).append(Rect2(wx - 0.38, r.position.y - 0.5, 0.76, 1.0))
	var lw := RoomBuilder.make_wall(root, "schoolRearL", Vector3(r.position.x, 0, back_r.get_center().y + T / 2.0), Vector3(T, hgt, back_r.size.y),
		Vector3(-1, 0, 0), tex, [], false, Color("F2E8C8"), "panel")
	var rw := RoomBuilder.make_wall(root, "schoolRearR", Vector3(r.end.x, 0, back_r.get_center().y + T / 2.0), Vector3(T, hgt, back_r.size.y),
		Vector3(1, 0, 0), tex, [], false, Color("F2E8C8"), "panel")
	RoomBuilder.add_siding(lw, -1.0, hgt, tex, -INF, INF, true, true, Color("B5654A"), "brick")
	RoomBuilder.add_siding(rw, 1.0, hgt, tex, -INF, INF, true, true, Color("B5654A"), "brick")
	for w in [bw, lw, rw]:
		(c["out"]["walls"] as Array).append(w)
	var broof := RoomBuilder.box(root, Vector3(back_r.size.x + 0.4, 0.22, back_r.size.y + 0.2), Vector3(r.get_center().x, hgt + 0.11, back_r.get_center().y - 0.1), Color("5A5550"))
	(c["out"]["ceilings"] as Array).append(broof)
	var old: Dictionary = b["back"]
	(old["body"] as Node).queue_free()
	(c["out"]["walls"] as Array).erase(old)
	var x1 := r.position.x + 9.0
	var x2 := r.position.x + 18.0
	_partition(c, "schoolMid", true, hz, r.position.x + T / 2.0, r.end.x - T / 2.0,
		[[r.position.x + 4.5, 0.95, 2.2], [r.position.x + 13.5, 0.95, 2.2], [r.position.x + 22.5, 2.0, 2.6]], hgt, Color("F2E8C8"))
	_partition(c, "schoolA", false, x1, r.position.y + T / 2.0, hz - T / 2.0, [], hgt, Color("F2E8C8"))
	_partition(c, "schoolB", false, x2, r.position.y + T / 2.0, hz - T / 2.0, [], hgt, Color("E8D8B8"))
	_room(c, "School Hallway", Rect2(r.position.x, hz, r.size.x, r.end.y - hz))
	_room(c, "Classroom", Rect2(r.position.x, r.position.y, 9.0, hz - r.position.y))
	_room(c, "Art Room", Rect2(x1, r.position.y, 9.0, hz - r.position.y))
	_room(c, "Gym", Rect2(x2, r.position.y, r.end.x - x2, hz - r.position.y))
	_sign(c, b["front"], 20.5, 3.45, b["fz"], 1.0, "MAPLE GROVE ELEMENTARY", Color("2E5E9E"), Palette.PAPER, 7.5)
	_windows(c, b["front"], [10.0, 14.0, 27.0, 31.0], 1.6, 1.6, 1.3, b["fz"], 1.0)
	var cc := {"root": root, "objects": c["objects"], "solids": solids, "out": c["out"], "tex": tex, "home": "town", "level": 0}
	# ---- the hallway: lockers, a trophy case, a water fountain
	var lockers := _usable(c, "school_lockers", "Lockers", "lockers", Vector3(r.position.x + 9.0, 0, hz + T / 2.0 + 0.25), 0)
	for i in 10:
		Props.part(lockers, Vector3(0.38, 1.8, 0.45), Vector3(-1.9 + i * 0.4 + 0.2, 0.9, 0), [Color("2E5E9E"), Color("3A6AAE")][i % 2])
		Props.part(lockers, Vector3(0.2, 0.03, 0.01), Vector3(-1.9 + i * 0.4 + 0.2, 1.55, 0.23), Palette.INK2, null, false)
	Props.finish(lockers, solids, Vector3(4.0, 1.8, 0.45), Vector3(0, 0, 0.85), null, Vector3(0, 1.3, 0))
	var trophy := _usable(c, "trophy_case", "Trophy Case", "trophy_case", Vector3(r.end.x - 3.5, 0, hz + T / 2.0 + 0.25), 0)
	Props.part(trophy, Vector3(2.2, 0.8, 0.45), Vector3(0, 0.4, 0), Palette.WOOD_DARK)
	Props.part(trophy, Vector3(2.2, 1.0, 0.43), Vector3(0, 1.3, -0.01), Color("BFE0EE"), null, false)
	for i in 5:
		Props.part(trophy, Vector3(0.14, 0.3, 0.14), Vector3(-0.8 + i * 0.4, 1.0, 0.0), Palette.GOLD, null, false)
	Props.finish(trophy, solids, Vector3(2.2, 1.8, 0.45), Vector3(0, 0, 0.85), null, Vector3(0, 1.2, 0))
	var ftn := _usable(c, "water_fountain", "Water Fountain", "fountain", Vector3(r.position.x + 15.6, 0, hz + T / 2.0 + 0.2), 0)
	Props.part(ftn, Vector3(0.5, 0.9, 0.35), Vector3(0, 0.45, 0), Color("C8CCD0"))
	Props.finish(ftn, solids, Vector3(0.5, 0.9, 0.35), Vector3(0, 0, 0.7), null, Vector3(0, 0.9, 0))
	_staff(c, "principal", "Principal Hartwell", Vector3(r.position.x + 5.0, 0, b["fz"] - 1.6), 180.0,
		{"gender": "girl", "hair": "layered", "hair_color": 1, "skin": 2, "adult": true, "top_style": "plain",
		"top": Color("6A5A9A"), "pants": Color("3B3A50"), "shoes": Color("2B2020")}, 1.0, Vector2(7.5, 16.5), [1, 2, 3, 4, 5],
		["No running in the halls! ...Unless it's a fire drill.", "Summer school is optional. Fun is mandatory. Well, encouraged.",
		"Your permanent record is very important. Very permanent."], "school")
	# ---- the classroom: a chalkboard, the teacher's desk, rows of desks
	var chalk := _usable(c, "chalkboard", "Chalkboard", "chalkboard", Vector3(r.position.x + 4.5, 0, r.position.y + T / 2.0 + 0.04), 0)
	Props.part(chalk, Vector3(4.0, 1.3, 0.05), Vector3(0, 1.6, 0), Color("2E4A3A"))
	Props.part(chalk, Vector3(4.2, 0.08, 0.12), Vector3(0, 0.92, 0.04), Palette.WOOD, null, false)
	var board := _label(chalk, "Summer School\n2 + 2 = 4", Vector3(-0.8, 1.75, 0.03), 0.0, Color("E8E8E0"), 0.0035, 48)
	board.set_meta("summer_text", "Summer School\n2 + 2 = 4")
	board.set_meta("year_text", "Spelling Test\nFriday!")
	if not c["out"].has("school_boards"):
		c["out"]["school_boards"] = []
	(c["out"]["school_boards"] as Array).append(board)
	Props.finish(chalk, solids, Vector3(4.0, 1.3, 0.1), Vector3(0, 0, 1.0), null, Vector3(0, 1.6, 0), Vector3(0, 1.6, 0))
	(solids as Array).pop_back()
	var td := Props.solid(root, Vector3(r.position.x + 2.0, 0, r.position.y + 2.2), 180)
	RoomBuilder.box(td, Vector3(1.5, 0.76, 0.75), Vector3(0, 0.38, 0), Palette.WOOD)
	RoomBuilder.box(td, Vector3(0.18, 0.2, 0.18), Vector3(0.4, 0.86, 0), Color("C0322A"))   # an apple
	Props.finish(td, solids, Vector3(1.5, 0.9, 0.75), Vector3.ZERO)
	_staff(c, "teacher", "Mrs. Fenwick", Vector3(r.position.x + 3.6, 0, r.position.y + 1.5), 0.0,
		{"gender": "girl", "hair": "teased", "hair_color": 3, "skin": 3, "adult": true, "top_style": "plain",
		"top": Color("C8A2C8"), "pants": Color("4A3A5A"), "shoes": Color("2B2020")}, 1.2, Vector2(8.0, 15.0), [1, 2, 3, 4, 5],
		["Spit out your gum, please.", "Today we're learning about the solar system. Pluto is my favorite.",
		"Raise your hand before you speak! ...That was very nice. Thank you."], "school")
	var i := 0
	for row in 3:
		for col in 3:
			var p := Vector3(r.position.x + 2.5 + col * 2.2, 0, r.position.y + 5.0 + row * 2.2)
			if row == 1 and col == 1:
				var sd := _usable(c, "school_desk", "Student Desk", "school_desk", p, 180)
				Props.part(sd, Vector3(0.7, 0.05, 0.5), Vector3(0, 0.7, 0), Color("C8A070"))
				Props.part(sd, Vector3(0.06, 0.68, 0.06), Vector3(0, 0.34, 0), Palette.MUTED, null, false)
				Props.part(sd, Vector3(0.45, 0.45, 0.42), Vector3(0, 0.225, -0.5), Color("2E5E9E"), null, false)
				Props.finish(sd, solids, Vector3(0.7, 0.75, 0.5), Vector3(0, 0, -1.1), Vector3(0, 0, -0.5), Vector3(0, 0.8, 4.0))
			else:
				var d := Props.solid(root, p, 180)
				RoomBuilder.box(d, Vector3(0.7, 0.05, 0.5), Vector3(0, 0.7, 0), Color("C8A070"))
				RoomBuilder.box(d, Vector3(0.06, 0.68, 0.06), Vector3(0, 0.34, 0), Palette.MUTED)
				RoomBuilder.box(d, Vector3(0.45, 0.45, 0.42), Vector3(0, 0.225, -0.5), [Color("2E5E9E"), Color("C0322A"), Color("2E8C8A")][i % 3])
				Props.finish(d, solids, Vector3(0.7, 0.75, 1.0), Vector3.ZERO, null, null, Vector3(0, 0.375, -0.25))
			i += 1
	var globe := Props.solid(root, Vector3(r.position.x + 8.2, 0, r.position.y + 1.0), 0)
	RoomBuilder.box(globe, Vector3(0.3, 0.8, 0.3), Vector3(0, 0.4, 0), Palette.WOOD)
	RoomBuilder.box(globe, Vector3(0.45, 0.45, 0.45), Vector3(0, 1.05, 0), Color("4A8AC8")).rotation.y = 0.5
	Props.finish(globe, solids, Vector3(0.45, 1.3, 0.45), Vector3.ZERO)
	Props.light(root, c["out"], Vector3(r.position.x + 4.5, hgt - 0.5, r.position.y + 6.0), Color("F2F4FF"), 9.0, 0.9, 1.6, null, false)
	# ---- the art room: easels and a big messy table
	for k in 3:
		var e := _usable(c, "easel_%d" % (k + 1), "Easel", "easel", Vector3(x1 + 2.0 + k * 2.6, 0, r.position.y + 3.0), 180)
		for lx in [-0.3, 0.3]:
			Props.part(e, Vector3(0.05, 1.6, 0.05), Vector3(lx, 0.8, 0), Palette.WOOD, null, false)
		Props.part(e, Vector3(0.7, 0.9, 0.03), Vector3(0, 1.35, 0.04), Palette.PAPER)
		Props.part(e, Vector3(0.3, 0.3, 0.006), Vector3(0.1, 1.4, 0.058), [Color("E85A7A"), Color("4FB0E0"), Color("F7D046")][k], null, false)
		Props.finish(e, solids, Vector3(0.7, 1.6, 0.4), Vector3(0, 0, 0.8), null, Vector3(0, 1.3, 0))
	var at := Furnish.table(cc, "art_table", "Art Table", Vector3(x1 + 4.5, 0, r.position.y + 7.5), 0, Color("D8C8A8"), Vector2(2.4, 1.0))
	at.kind = "art_table"
	at.home = "town"
	for k in 4:
		RoomBuilder.box(at, Vector3(0.12, 0.08, 0.12), Vector3(-0.9 + k * 0.6, 0.81, -0.2), [Color("C0322A"), Color("2E5E9E"), Color("F7D046"), Color("4F9A3A")][k])
	Furnish.sink(cc, "art_sink", Vector3(x2 - 0.45, 0, r.position.y + 2.0), -90, Palette.CREAM, Palette.MUTED, 1.0).home = "town"
	Props.light(root, c["out"], Vector3(x1 + 4.5, hgt - 0.5, r.position.y + 6.0), Color("F2F4FF"), 9.0, 0.9, 1.6, null, false)
	# ---- the gym: a hoop, a climbing rope, mats and the bleachers
	var hoop := _usable(c, "gym_hoop", "Gym Basketball Hoop", "gym_hoop", Vector3(x2 + 4.5, 0, r.position.y + T / 2.0 + 0.2), 0)
	Props.part(hoop, Vector3(1.6, 1.1, 0.06), Vector3(0, 3.1, 0.05), Palette.PAPER)
	Props.part(hoop, Vector3(0.5, 0.04, 0.5), Vector3(0, 2.75, 0.35), Color("E4572E"))
	Props.part(hoop, Vector3(0.1, 0.1, 0.4), Vector3(0, 2.75, 0.18), Palette.MUTED, null, false)
	Props.finish(hoop, solids, Vector3(1.6, 1.1, 0.4), Vector3(0, 0, 3.0), null, Vector3(0, 2.75, 0.35), Vector3(0, 3.1, 0.15))
	(solids as Array).pop_back()
	var rope := _usable(c, "gym_rope", "Climbing Rope", "gym_rope", Vector3(r.end.x - 1.4, 0, r.position.y + 6.5), 0)
	Props.part(rope, Vector3(0.06, hgt - 0.1, 0.06), Vector3(0, (hgt - 0.1) / 2.0, 0), Color("D8C890"))
	Props.part(rope, Vector3(1.2, 0.08, 1.2), Vector3(0, 0.04, 0), Color("2E5E9E"), null, false)
	Props.finish(rope, solids, Vector3(0.3, hgt, 0.3), Vector3(0, 0, 0.7), Vector3(0, 0, 0.22), Vector3(0, 2.0, 0))
	var gym := _usable(c, "gym_floor", "Gym Floor", "gym_floor", Vector3(x2 + 4.5, 0, r.position.y + 7.0), 0)
	Props.part(gym, Vector3(6.0, 0.006, 0.08), Vector3(0, 0.003, 0), Palette.PAPER, null, false)
	Props.part(gym, Vector3(0.6, 0.6, 0.6), Vector3(1.2, 0.3, 1.5), Color("C0322A"))       # a big red ball
	Props.finish(gym, solids, Vector3(0.6, 0.6, 0.6), Vector3(0, 0, 0.5), null, Vector3(0, 0.5, -4.0), Vector3(1.2, 0.3, 1.5))
	var gb := Props.solid(root, Vector3(r.end.x - 0.9, 0, r.position.y + 10.0), -90)
	for t in 3:
		RoomBuilder.box(gb, Vector3(3.0, 0.35 + t * 0.35, 0.5), Vector3(0, (0.35 + t * 0.35) / 2.0, -0.5 + t * 0.5), Color("B88A5A"))
	Props.finish(gb, solids, Vector3(3.0, 1.1, 1.5), Vector3.ZERO, null, null, Vector3(0, 0.55, 0))
	Props.light(root, c["out"], Vector3(x2 + 4.5, hgt - 0.5, r.position.y + 6.0), Color("F2F4FF"), 10.0, 0.9, 1.6, null, false)


# ================================================================ the football field

static func _field(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var out: Dictionary = c["out"]
	var f := FIELD
	OutdoorBuilder._slab(root, f, Color("4F9A3A"), tex["grass"], 0.006)
	OutdoorBuilder._slab(root, Rect2(f.position.x + 0.02, f.position.y + 0.02, 3.98, f.size.y - 0.04), Color("2E5E9E"), null, 0.008)
	OutdoorBuilder._slab(root, Rect2(f.end.x - 4.0, f.position.y + 0.02, 3.98, f.size.y - 0.04), Color("C0322A"), null, 0.008)
	var x := f.position.x + 4.0
	while x <= f.end.x - 3.9:
		OutdoorBuilder._slab(root, Rect2(x - 0.06, f.position.y + 0.3, 0.12, f.size.y - 0.6), Palette.PAPER, null, 0.011)
		x += 4.0
	for z in [f.position.y + 0.15, f.end.y - 0.27]:
		OutdoorBuilder._slab(root, Rect2(f.position.x + 0.2, z, f.size.x - 0.4, 0.12), Palette.PAPER, null, 0.011)
	var mid := f.get_center()
	_label(root, "MAVERICKS", Vector3(mid.x, 0.016, mid.y), 0.0, Palette.GOLD, 0.02, 96).rotation_degrees = Vector3(-90, 0, 0)
	# Goal posts
	for gx in [f.position.x + 1.0, f.end.x - 1.0]:
		var gp := _usable(c, "goalpost_%s" % ("w" if gx < mid.x else "e"), "Goal Post", "goalpost", Vector3(gx, 0, mid.y), 90 if gx < mid.x else -90)
		var yel := Color("F2C230")
		Props.part(gp, Vector3(0.18, 3.0, 0.18), Vector3(0, 1.5, 0), yel)
		Props.part(gp, Vector3(5.6, 0.16, 0.16), Vector3(0, 3.0, 0), yel)
		for ux in [-2.75, 2.75]:
			Props.part(gp, Vector3(0.12, 3.2, 0.12), Vector3(ux, 4.6, 0), yel)
		Props.finish(gp, solids, Vector3(0.4, 3.0, 0.4), Vector3(0, 0, 9.0), null, Vector3(0, 3.5, 0))
	# The field itself (toss a football, run laps)
	var fo := _usable(c, "football_field", "Football Field", "football_field", Vector3(mid.x, 0, mid.y), 0)
	fo.shared = true
	Props.part(fo, Vector3(0.3, 0.18, 0.18), Vector3(0, 0.09, 0), Color("7A4A2E"))           # a football on the 50
	Props.finish(fo, solids, Vector3(0.6, 0.3, 0.6), Vector3(0, 0, 1.2), Vector3(0, 0, 3.0), Vector3(0, 0.3, -6.0))
	(solids as Array).pop_back()
	# Bleachers on the south side, facing the field
	var bl := _usable(c, "bleachers", "Bleachers", "bleachers", Vector3(mid.x, 0, f.end.y + 2.1), 180)
	for t in 4:
		Props.part(bl, Vector3(20.0, 0.08, 0.5), Vector3(0, 0.42 + t * 0.4, -0.9 + t * 0.62), Color("B8C0C8"))
		Props.part(bl, Vector3(20.0, 0.38 + t * 0.4, 0.06), Vector3(0, (0.38 + t * 0.4) / 2.0, -1.12 + t * 0.62), Color("8A9298"), null, false)
	for lx in [-9.8, -3.3, 3.3, 9.8]:
		Props.part(bl, Vector3(0.1, 2.2, 0.1), Vector3(lx, 1.1, 1.05), Palette.MUTED, null, false)
	Props.part(bl, Vector3(20.0, 0.06, 0.06), Vector3(0, 2.2, 1.05), Palette.MUTED, null, false)
	Props.finish(bl, solids, Vector3(20.0, 2.2, 2.6), Vector3(0, 0, -1.9), Vector3(0, 0, -0.9), Vector3(0, 0.5, -12.0), Vector3(0, 1.1, 0.1))
	# The scoreboard behind the north end
	var sb := Props.solid(root, Vector3(mid.x, 0, f.position.y - 1.4), 0)
	for lx in [-2.0, 2.0]:
		RoomBuilder.box(sb, Vector3(0.25, 4.0, 0.25), Vector3(lx, 2.0, 0), Palette.MUTED)
	RoomBuilder.box(sb, Vector3(5.6, 2.2, 0.3), Vector3(0, 5.0, 0), Color("1F2A26"))
	_label(sb, "HOME 21   GUEST 14", Vector3(0, 5.35, 0.16), 0.0, Color("F7B03A"), 0.006, 64)
	_label(sb, "MAPLE GROVE MAVERICKS", Vector3(0, 4.6, 0.16), 0.0, Palette.PAPER, 0.005, 48)
	Props.finish(sb, solids, Vector3(4.4, 6.1, 0.4), Vector3.ZERO)
	# Field lights at the corners (on at night)
	for corner in [Vector2(f.position.x - 1.0, f.position.y - 1.0), Vector2(f.end.x + 1.0, f.position.y - 1.0),
			Vector2(f.position.x - 1.0, f.end.y + 0.6), Vector2(f.end.x + 1.0, f.end.y + 0.6)]:
		var lp := Props.solid(root, Vector3(corner.x, 0, corner.y), 0)
		RoomBuilder.box(lp, Vector3(0.3, 9.0, 0.3), Vector3(0, 4.5, 0), Palette.MUTED)
		var head := RoomBuilder.box(lp, Vector3(1.6, 0.6, 0.36), Vector3(0, 9.2, 0), Color("F2F0E6"))
		var hm: StandardMaterial3D = head.material_override
		hm.emission_enabled = true
		hm.emission = Color("F2F0E6")
		Props.finish(lp, solids, Vector3(0.5, 9.0, 0.5), Vector3.ZERO)
		var l := OmniLight3D.new()
		l.position = Vector3(corner.x + (4.0 if corner.x < mid.x else -4.0), 8.0, corner.y + (4.0 if corner.y < mid.y else -4.0))
		l.omni_range = 22.0
		l.light_color = Color("FFF6E0")
		root.add_child(l)
		RoomBuilder.add_lamp(out, l, hm, 0.0, 1.4)
	_staff(c, "coach", "Coach Dumbrowski", Vector3(mid.x - 6.0, 0, f.end.y - 1.2), 180.0,
		{"gender": "boy", "hair": "buzz", "hair_color": 1, "skin": 1, "adult": true, "outfit": 2,
		"top": Color("2E5E9E"), "pants": Color("2E5E9E")}, 1.0, Vector2(8.0, 18.0), [1, 2, 3, 4, 5, 6],
		["Hustle, hustle! Pick up those feet!", "Twenty more laps and then I'll get a hot dog.", "You'd make a heck of a shortstop, kid.",
		"Football's a game of inches. And laps. Mostly laps."], "field")
	# A school bus parked by the field
	var bus := Props.solid(root, Vector3(55.0, 0, Z0 - 3.4), 90)
	OutdoorBuilder._slab(root, Rect2(48.5, Z0 - 5.0, 13.0, 3.2), Color("55545C"), tex["asphalt"], 0.008)
	RoomBuilder.box(bus, Vector3(2.4, 2.2, 9.6), Vector3(0, 1.45, 0), Color("F2B32A"))
	RoomBuilder.box(bus, Vector3(2.42, 0.12, 9.62), Vector3(0, 1.3, 0), Palette.INK)
	RoomBuilder.box(bus, Vector3(2.3, 0.7, 1.4), Vector3(0, 0.95, -5.4), Color("F2B32A"))     # the hood
	for side in [-1.0, 1.0]:
		for k in 7:
			RoomBuilder.box(bus, Vector3(0.02, 0.55, 0.9), Vector3(side * 1.215, 1.95, -3.6 + k * 1.15), Color("34405A"))
	for wz in [-3.8, 3.4]:
		for side in [-1.0, 1.0]:
			RoomBuilder.box(bus, Vector3(0.3, 0.7, 0.7), Vector3(side * 1.0, 0.35, wz), Palette.INK)
	var bl2 := Label3D.new()
	bl2.text = "SCHOOL BUS"
	bl2.font_size = 64
	bl2.pixel_size = 0.005
	bl2.modulate = Palette.INK
	bl2.position = Vector3(1.214, 2.45, 0)
	bl2.rotation_degrees.y = 90.0
	bl2.double_sided = false
	bus.add_child(bl2)
	Props.finish(bus, solids, Vector3(2.4, 2.6, 11.0), Vector3.ZERO, null, null, Vector3(0, 1.3, -0.5))
