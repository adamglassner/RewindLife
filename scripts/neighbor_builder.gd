class_name NeighborBuilder
extends RefCounted
## The five neighbors' houses. Every one has the same rooms (so every kid has a
## real home): living room, dining room, kitchen, a hallway, a bathroom, the
## kid's bedroom, the parents' bedroom, and a stair hall with stairs UP to the
## attic and DOWN to the basement, plus a fenced backyard. They differ in size,
## which way round they are, the order of the bedrooms, colors, and the extras
## (a garage, the yard, what's in the attic and basement).
##
## Plan, as seen from the street (u = across, v = in from the front wall):
##
##   v=0   +----------+---------+---------+  front door into the living room
##         |  LIVING  | DINING  | KITCHEN |
##   v=4.4 +--arch----+---------+--arch---+
##         |              HALLWAY          |  side door at the u=0 end
##   v=5.6 +--door--+--door--+--door--+----+
##         |  room  |  room  |  room  |STAIRS (up to the attic, down to the basement)
##   v=D   +--------+--------+--------+----+
##
## The outside walls are taller than the ceilings (EH), with the roof on top,
## like a house with an attic floor upstairs.

const H := 2.6       # ceilings
const EH := 4.1      # outside walls and the stair hall
const T := 0.15
const FRONT_D := 4.4 # depth of the front rooms
const HALL_D := 1.2
const STAIR_W := 2.1

const HOMES := {
	"hendersons": {"title": "The Hendersons' House", "family": "Henderson", "r": Rect2(-14.6, -2.0, 10.0, 10.0),
		"face": 1.0, "mirror": false, "order": ["kid", "bath", "parents"], "garage": false, "chimney": true,
		"siding": Color("9EC1D9"), "trim": Color("F2F0E6"), "door": Color("A44A2A"), "roof": Color("4A4A52"),
		"walls": Color("C9A27A"), "carpet": Color("6E8F7A"), "kid_color": Color("2E5E9E"), "couch": Color("8A6A4A"),
		"yard": ["swing_set", "garden"], "basement": ["workbench", "pool_table"], "attic": ["trunk", "xmas", "rocking_horse"],
		"parents": [["Mrs. Henderson", "mom"], ["Mr. Henderson", "dad"]]},
	"garcias": {"title": "The Garcias' House", "family": "Garcia", "r": Rect2(22.2, -1.5, 11.0, 9.5),
		"face": 1.0, "mirror": false, "order": ["parents", "bath", "kid"], "garage": true, "chimney": false,
		"siding": Color("E3C46A"), "trim": Color("FBF1DC"), "door": Color("2E6B4F"), "roof": Color("6B4A3A"),
		"walls": Color("E8C3A0"), "carpet": Color("B5654A"), "kid_color": Color("8E5BB0"), "couch": Color("2E8C8A"),
		"yard": ["kiddie_pool", "picnic"], "basement": ["ping_pong", "console"], "attic": ["trunk", "telescope", "xmas"],
		"parents": [["Mrs. Garcia", "mom"], ["Mr. Garcia", "dad"]]},
	"kowalskis": {"title": "The Kowalskis' House", "family": "Kowalski", "r": Rect2(-14.0, 28.0, 11.0, 9.5),
		"face": -1.0, "mirror": true, "order": ["bath", "kid", "parents"], "garage": false, "chimney": true,
		"siding": Color("8FA06A"), "trim": Color("F4E6C8"), "door": Color("7A4A2E"), "roof": Color("5A4636"),
		"walls": Color("B8C9A0"), "carpet": Color("8A7A5A"), "kid_color": Color("F2A0B5"), "couch": Color("9A3A2A"),
		"yard": ["garden", "trampoline"], "basement": ["workbench", "console"], "attic": ["xmas", "trunk", "rocking_horse"],
		"parents": [["Mrs. Kowalski", "mom"], ["Mr. Kowalski", "dad"]]},
	"nguyens": {"title": "The Nguyens' House", "family": "Nguyen", "r": Rect2(1.0, 28.0, 11.0, 9.5),
		"face": -1.0, "mirror": false, "order": ["kid", "parents", "bath"], "garage": true, "chimney": true,
		"siding": Color("C99A7A"), "trim": Color("FBF1DC"), "door": Color("2B2F5A"), "roof": Color("4A3A3A"),
		"walls": Color("A8B8C8"), "carpet": Color("8E8C5A"), "kid_color": Color("3F8A7A"), "couch": Color("6A5A9A"),
		"yard": ["swing_set", "picnic"], "basement": ["weights", "ping_pong"], "attic": ["telescope", "trunk", "xmas"],
		"parents": [["Mrs. Nguyen", "mom"], ["Mr. Nguyen", "dad"]]},
	"parkers": {"title": "The Parkers' House", "family": "Parker", "r": Rect2(18.0, 28.0, 11.0, 9.5),
		"face": -1.0, "mirror": true, "order": ["parents", "kid", "bath"], "garage": false, "chimney": false,
		"siding": Color("D9D2C2"), "trim": Color("6B4429"), "door": Color("C2572F"), "roof": Color("3E4A5A"),
		"walls": Color("D9B870"), "carpet": Color("4A6A8A"), "kid_color": Color("E3B23C"), "couch": Color("5A4A3A"),
		"yard": ["lemonade", "trampoline"], "basement": ["arcade", "pool_table"], "attic": ["rocking_horse", "trunk", "xmas"],
		"parents": [["Mrs. Parker", "mom"], ["Mr. Parker", "dad"]]},
	# ---- three more families up the street (their kids aren't players: they're townsfolk)
	"millers": {"title": "The Millers' House", "family": "Miller", "r": Rect2(40.5, -1.5, 11.0, 9.5),
		"face": 1.0, "mirror": true, "order": ["kid", "bath", "parents"], "garage": false, "chimney": true,
		"siding": Color("E8B8A8"), "trim": Color("FBF1DC"), "door": Color("2E5E9E"), "roof": Color("5A4A4A"),
		"walls": Color("F2E2C8"), "carpet": Color("7A8AA8"), "kid_color": Color("E85A7A"), "couch": Color("7A5A3A"),
		"yard": ["swing_set", "garden"], "basement": ["ping_pong", "workbench"], "attic": ["trunk", "rocking_horse", "xmas"],
		"kid": "Becky", "kid_look": {"gender": "girl", "hair": "scrunchie", "hair_color": 3, "skin": 0, "outfit": 1, "kid": true},
		"parents": [["Mrs. Miller", "mom"], ["Mr. Miller", "dad"]], "fence_both": true},
	"obriens": {"title": "The O'Briens' House", "family": "O'Brien", "r": Rect2(55.5, -1.5, 11.0, 9.5),
		"face": 1.0, "mirror": false, "order": ["parents", "kid", "bath"], "garage": true, "chimney": false,
		"siding": Color("A8C8A0"), "trim": Color("F2F0E6"), "door": Color("C0322A"), "roof": Color("3E4A3E"),
		"walls": Color("E8E0C8"), "carpet": Color("A85A4A"), "kid_color": Color("4FB0E0"), "couch": Color("4A6A8A"),
		"yard": ["pool"], "basement": ["pool_table", "weights"], "attic": ["trunk", "xmas", "telescope"],
		"kid": "Sean", "kid_look": {"gender": "boy", "hair": "bowl", "hair_color": 4, "skin": 0, "outfit": 3, "kid": true},
		"parents": [["Mrs. O'Brien", "mom"], ["Mr. O'Brien", "dad"]], "fence_both": true},
	"brooks": {"title": "The Brooks' House", "family": "Brooks", "r": Rect2(71.0, -1.5, 11.0, 9.5),
		"face": 1.0, "mirror": true, "order": ["bath", "kid", "parents"], "garage": false, "chimney": true,
		"siding": Color("F2E2A0"), "trim": Color("6B4429"), "door": Color("2E6B4F"), "roof": Color("4A3A2A"),
		"walls": Color("D8E2E8"), "carpet": Color("6A8A6A"), "kid_color": Color("F7A040"), "couch": Color("8A3A5A"),
		"yard": ["trampoline", "picnic"], "basement": ["console", "workbench"], "attic": ["xmas", "trunk", "rocking_horse"],
		"kid": "Tyrone", "kid_look": {"gender": "boy", "hair": "high_top", "hair_color": 0, "skin": 5, "outfit": 2, "kid": true},
		"parents": [["Mrs. Brooks", "mom"], ["Mr. Brooks", "dad"]], "fence_both": true},
}


## The houses' outlines (the lawn is cut out under them).
static func home_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for k in HOMES:
		out.append((HOMES[k]["r"] as Rect2).grow(0.115))
	return out


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2]) -> void:
	out["home_rooms"] = {}
	if not out.has("npc_spots"):
		out["npc_spots"] = {}
	for key in HOMES:
		_build_home(root, out, tex, solids, free, doorways, buildings, key)


# ================================================================ coordinates

## A world position `u` across and `v` in from the front wall.
static func _p(c: Dictionary, u: float, v: float, y := 0.0) -> Vector3:
	return Vector3(_x(c, u), y, _z(c, v))


static func _x(c: Dictionary, u: float) -> float:
	var r: Rect2 = c["r"]
	return r.end.x - u if c["mirror"] else r.position.x + u


static func _z(c: Dictionary, v: float) -> float:
	return float(c["front_z"]) - float(c["face"]) * v


## Yaw (degrees) to face: "front" (toward the street), "back", "+u", "-u".
static func _yaw(c: Dictionary, dir: String) -> float:
	var front := 0.0 if float(c["face"]) > 0 else 180.0
	var plus_u := -90.0 if c["mirror"] else 90.0
	match dir:
		"front":
			return front
		"back":
			return front + 180.0
		"+u":
			return plus_u
		"-u":
			return plus_u + 180.0
	return 0.0


## A local rectangle (u0, v0)-(u1, v1) as a world Rect2.
static func _rect(c: Dictionary, u0: float, v0: float, u1: float, v1: float) -> Rect2:
	var a := _p(c, u0, v0)
	var b := _p(c, u1, v1)
	return Rect2(minf(a.x, b.x), minf(a.z, b.z), absf(b.x - a.x), absf(b.z - a.z))


## The world direction of +u and +v.
static func _du(c: Dictionary) -> Vector3:
	return Vector3(-1, 0, 0) if c["mirror"] else Vector3(1, 0, 0)


static func _dv(c: Dictionary) -> Vector3:
	return Vector3(0, 0, -float(c["face"]))


## A wall at constant v from u0 to u1. `ops` = [[u center, width, height], ...]
static func _wall_u(c: Dictionary, name: String, v: float, u0: float, u1: float, ops: Array, height: float,
		shared: bool, outward_v := 0.0) -> Dictionary:
	var xa := _x(c, u0)
	var xb := _x(c, u1)
	var openings := []
	for o in ops:
		openings.append({"c": _x(c, o[0]), "w": o[1], "h": o[2]})
	var normal := _dv(c) * outward_v if outward_v != 0.0 else Vector3(0, 0, 1)
	var w := RoomBuilder.make_wall(c["root"], c["key"] + name, Vector3((xa + xb) / 2.0, 0, _z(c, v)),
		Vector3(absf(xb - xa), height, T), normal, c["tex"], openings, shared, c["home_def"]["walls"], "panel")
	(c["out"]["walls"] as Array).append(w)
	return w


## A wall at constant u from v0 to v1.
static func _wall_v(c: Dictionary, name: String, u: float, v0: float, v1: float, ops: Array, height: float,
		shared: bool, outward_u := 0.0) -> Dictionary:
	var za := _z(c, v0)
	var zb := _z(c, v1)
	var openings := []
	for o in ops:
		openings.append({"c": _z(c, o[0]), "w": o[1], "h": o[2]})
	var normal := _du(c) * outward_u if outward_u != 0.0 else Vector3(1, 0, 0)
	var w := RoomBuilder.make_wall(c["root"], c["key"] + name, Vector3(_x(c, u), 0, (za + zb) / 2.0),
		Vector3(T, height, absf(zb - za)), normal, c["tex"], openings, shared, c["home_def"]["walls"], "panel")
	(c["out"]["walls"] as Array).append(w)
	return w


## Walkable grid cells through an opening in a wall.
static func _doorway(c: Dictionary, u: float, v: float, along_u: bool, w: float) -> void:
	var r := _rect(c, u - w / 2.0 + 0.1, v - 0.5, u + w / 2.0 - 0.1, v + 0.5) if along_u \
		else _rect(c, u - 0.5, v - w / 2.0 + 0.1, u + 0.5, v + w / 2.0 - 0.1)
	(c["doorways"] as Array).append(r)


static func _room(c: Dictionary, name: String, u0: float, v0: float, u1: float, v1: float, floor_color: Color,
		floor_tex: String, ceiling := H) -> Rect2:
	var r := _rect(c, u0, v0, u1, v1)
	RoomBuilder.make_floor(c["root"], r, floor_color, c["tex"].get(floor_tex))
	RoomBuilder.make_ceiling(c["root"], c["out"], r.grow(-T / 2.0), ceiling)
	(c["free"] as Array).append(r.grow(-T / 2.0))
	if name != "":
		(c["out"]["home_rooms"] as Dictionary)["%s|%s" % [c["key"], name]] = r
	return r


## A ceiling light (the fixture hides with the ceiling in the House Cam).
static func _ceiling_light(c: Dictionary, u: float, v: float, rng := 5.0, day := 0.25, night := 1.6, ceiling := H) -> void:
	var at := _p(c, u, v, ceiling - 0.11)
	var fx := RoomBuilder.box(c["root"], Vector3(0.5, 0.06, 0.5), at, Palette.LAMP)
	var m: StandardMaterial3D = fx.material_override
	m.emission_enabled = true
	m.emission = Palette.LAMP
	(c["out"]["ceilings"] as Array).append(fx)
	Props.light(c["root"], c["out"], _p(c, u, v, ceiling - 0.4), Palette.LAMP, rng, day, night, m, false)


# ================================================================ the house

static func _build_home(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2], key: String) -> void:
	var h: Dictionary = HOMES[key]
	var r: Rect2 = h["r"]
	var face: float = h["face"]
	var c := {"root": root, "out": out, "tex": tex, "solids": solids, "free": free, "doorways": doorways,
		"objects": out["objects"], "buildings": buildings, "key": key, "home": key, "home_def": h, "level": 0,
		"r": r, "face": face, "mirror": h["mirror"], "front_z": r.end.y if face > 0 else r.position.y}
	var W := r.size.x
	var D := r.size.y
	var F := FRONT_D
	var B0 := F + HALL_D
	var LW := snappedf(W * 0.44, 0.1)
	var DW := 2.9
	var K0 := LW + DW
	var KW := W - K0
	var S0 := W - STAIR_W
	var A := S0
	var widths := {"kid": A * 0.36, "bath": A * 0.27, "parents": A * 0.37}
	var back := {}         # room -> [u0, u1]
	var u := 0.0
	for name in h["order"]:
		back[name] = [u, u + float(widths[name])]
		u += float(widths[name])
	c["back"] = back
	buildings.append(r)
	var carpet: Color = h["carpet"]

	# ---- floors, ceilings, walkable rooms
	_room(c, "Living Room", 0, 0, LW, F, carpet, "carpet")
	_room(c, "Dining Room", LW, 0, K0, F, Palette.WOOD, "panel")
	_room(c, "Kitchen", K0, 0, W, F, Color.WHITE, "lino")
	_room(c, "Hallway", 0, F, W, B0, carpet.darkened(0.15), "carpet")
	_room(c, "Kid Room", back["kid"][0], B0, back["kid"][1], D, h["kid_color"].lightened(0.35), "carpet")
	_room(c, "Bathroom", back["bath"][0], B0, back["bath"][1], D, Color("BFE0EE"), "lino")
	_room(c, "Parents Room", back["parents"][0], B0, back["parents"][1], D, carpet.lightened(0.2), "carpet")
	# The stair hall: floor only at the foot of the up flight (the rest is steps and the pit)
	var sr := _rect(c, S0, B0, W, D)
	RoomBuilder.make_floor(root, _rect(c, S0 + 1.05, B0, W, B0 + 0.45), carpet.darkened(0.15), tex["carpet"])
	RoomBuilder.make_ceiling(root, out, sr.grow(-T / 2.0), EH)
	(out["home_rooms"] as Dictionary)["%s|Stairs" % key] = sr

	# ---- outside walls (taller, with the roof on top)
	var fd := LW / 2.0
	var front := _wall_u(c, "Front", 0, -T / 2.0, W + T / 2.0, [[fd, 0.95, 2.15]], EH, false, -1.0)
	var backw := _wall_u(c, "Back", D, -T / 2.0, W + T / 2.0, [], EH, false, 1.0)
	var left := _wall_v(c, "Left", 0, T / 2.0, D - T / 2.0, [[F + HALL_D / 2.0, 0.9, 2.1]], EH, false, -1.0)
	var right := _wall_v(c, "Right", W, T / 2.0, D - T / 2.0, [], EH, false, 1.0)
	var oc: Color = h["siding"]
	RoomBuilder.add_siding(front, face, EH, tex, -INF, INF, true, true, oc)
	RoomBuilder.add_siding(backw, -face, EH, tex, -INF, INF, true, true, oc)
	RoomBuilder.add_siding(left, -_du(c).x, EH, tex, -INF, INF, true, true, oc)
	RoomBuilder.add_siding(right, _du(c).x, EH, tex, -INF, INF, true, true, oc)

	# ---- inside walls
	var arch_l := fd
	var arch_k := K0 + KW / 2.0
	var wa := _wall_u(c, "HallFront", F, T / 2.0, W - T / 2.0, [[arch_l, 1.4, 2.2], [arch_k, 0.9, 2.1]], H, true)
	var door_ops := []
	for name in ["kid", "bath", "parents"]:
		door_ops.append([(back[name][0] + back[name][1]) / 2.0, 0.9, 2.1])
	door_ops.append([S0 + STAIR_W / 2.0, STAIR_W - 0.3, 2.4])
	var wb := _wall_u(c, "HallBack", B0, T / 2.0, W - T / 2.0, door_ops, H, true)
	_wall_v(c, "LivingDining", LW, T / 2.0, F - T / 2.0, [[F / 2.0, 2.0, 2.3]], H, true)
	_wall_v(c, "DiningKitchen", K0, T / 2.0, F - T / 2.0, [[F / 2.0, 1.2, 2.2]], H, true)
	var order: Array = h["order"]
	_wall_v(c, "Back1", back[order[0]][1], B0 + T / 2.0, D - T / 2.0, [], H, true)
	_wall_v(c, "Back2", back[order[1]][1], B0 + T / 2.0, D - T / 2.0, [], H, true)
	var stair_side := _wall_v(c, "StairSide", S0, B0 + T / 2.0, D - T / 2.0, [], EH, true)
	# The wall above the stair hall's opening, from the hall ceiling up to the stair ceiling
	var hx0 := _x(c, S0)
	var hx1 := _x(c, W - T / 2.0)
	var hdr := RoomBuilder.box(root, Vector3(absf(hx1 - hx0), EH - H, T), Vector3((hx0 + hx1) / 2.0, (H + EH) / 2.0, _z(c, B0)),
		h["walls"], tex["panel"])
	(out["ceilings"] as Array).append(hdr)

	# ---- doors
	var into_v := _dv(c)
	for o in [[fd, 0.95, 2.15, front, h["door"]]]:
		RoomBuilder.make_casing(o[3], _x(c, o[0]), o[1], o[2], h["trim"])
		var sw := HouseBuilder.make_swing_door(o[3], _x(c, o[0]), o[1], o[2], o[4], into_v, false)
		sw["home"] = c["home"]          # (an outside door: visitors knock first)
		(out["swing_doors"] as Array).append(sw)
	RoomBuilder.make_casing(left, _z(c, F + HALL_D / 2.0), 0.9, 2.1, h["trim"])
	var side_door := HouseBuilder.make_swing_door(left, _z(c, F + HALL_D / 2.0), 0.9, 2.1, h["door"], _du(c), false)
	side_door["home"] = c["home"]
	(out["swing_doors"] as Array).append(side_door)
	for name in ["kid", "bath", "parents"]:
		var cu: float = (back[name][0] + back[name][1]) / 2.0
		RoomBuilder.make_casing(wb, _x(c, cu), 0.9, 2.1, Palette.CREAM)
		(out["swing_doors"] as Array).append(HouseBuilder.make_swing_door(wb, _x(c, cu), 0.9, 2.1, Palette.PAPER, into_v, name == "kid"))
		_doorway(c, cu, B0, true, 0.9)
	RoomBuilder.make_casing(wa, _x(c, arch_l), 1.4, 2.2, Palette.CREAM)
	RoomBuilder.make_casing(wa, _x(c, arch_k), 0.9, 2.1, Palette.CREAM)
	_doorway(c, arch_l, F, true, 1.4)
	_doorway(c, arch_k, F, true, 0.9)
	_doorway(c, S0 + STAIR_W / 2.0, B0, true, STAIR_W - 0.3)
	_doorway(c, LW, F / 2.0, false, 2.0)
	_doorway(c, K0, F / 2.0, false, 1.2)
	_doorway(c, fd, 0, true, 0.95)
	_doorway(c, 0, F + HALL_D / 2.0, false, 0.9)

	# ---- windows (outside frames, and inside frames on the same walls)
	var glass: StandardMaterial3D = out["window_mat"]
	var win := func(wall: Dictionary, along_u: bool, at: float, y: float, w: float, hgt: float, outward: float, inside := true) -> void:
		var ov: Vector3
		var base: Vector3
		if along_u:
			ov = _dv(c) * outward
			base = Vector3(_x(c, at), y, _z(c, 0.0 if outward < 0 else D))
			RoomBuilder.add_ext_window(wall["full"], base + ov * 0.125, Vector3(w, hgt, 0.04), out)
			if inside:
				RoomBuilder.add_int_window(wall["full"], base - ov * (T / 2.0) + Vector3(0, 0.05, 0), w - 0.1, hgt - 0.05, true, -signf(ov.z), glass)
		else:
			ov = _du(c) * outward
			base = Vector3(_x(c, 0.0 if outward < 0 else W), y, _z(c, at))
			RoomBuilder.add_ext_window(wall["full"], base + ov * 0.125, Vector3(0.04, hgt, w), out)
			if inside:
				RoomBuilder.add_int_window(wall["full"], base - ov * (T / 2.0) + Vector3(0, 0.05, 0), w - 0.1, hgt - 0.05, false, -signf(ov.x), glass)
	win.call(front, true, fd * 0.4, 1.5, 1.0, 1.0, -1.0)
	win.call(front, true, fd + (LW - fd) * 0.6, 1.5, 1.0, 1.0, -1.0)
	win.call(front, true, LW + DW / 2.0, 1.5, 1.4, 1.0, -1.0)
	win.call(front, true, K0 + KW / 2.0, 1.6, 1.1, 0.8, -1.0)
	win.call(front, true, W * 0.27, 3.35, 0.8, 0.6, -1.0, false)     # the attic floor's windows
	win.call(front, true, W * 0.73, 3.35, 0.8, 0.6, -1.0, false)
	for name in ["kid", "parents"]:
		win.call(backw, true, (back[name][0] + back[name][1]) / 2.0, 1.5, 1.0, 1.0, 1.0)
	win.call(backw, true, (back["bath"][0] + back["bath"][1]) / 2.0, 1.85, 0.6, 0.45, 1.0)
	win.call(left, false, F / 2.0, 1.5, 1.2, 1.0, -1.0)
	win.call(left, false, (B0 + D) / 2.0, 1.5, 1.0, 1.0, -1.0)
	if not h["garage"]:
		win.call(right, false, F / 2.0, 1.55, 1.0, 0.9, 1.0)
	win.call(right, false, (B0 + D) / 2.0, 3.0, 0.7, 0.6, 1.0, false)

	# ---- roof, chimney, garage
	var roof := RoomBuilder.make_roof(root, out, r, EH, 0.5, h["roof"], true, 0.4, 0.4, 0.4, 0.4)
	if h["chimney"]:
		RoomBuilder.box(roof, Vector3(0.7, 3.0, 0.7), _p(c, 1.0, D * 0.62, EH + 1.4), Color("9A4A3A"))
	if h["garage"]:
		_garage(c)

	# ---- outside the front door: porch, light, the walk, a spot for the newspaper
	var door_w := _p(c, fd, 0)
	var outward := Vector3(0, 0, face)
	OutdoorBuilder._slab(root, Rect2(door_w.x - 1.0, door_w.z + 0.115 if face > 0 else door_w.z - 1.115, 2.0, 1.0),
		Color("B8AFA0"), tex["concrete"], 0.03)
	var lamp := RoomBuilder.box(front["full"], Vector3(0.12, 0.2, 0.1), door_w + Vector3(-0.62, 1.95, 0) + outward * 0.17, Palette.LAMP)
	lamp.material_override = out["night_windows"]
	var walk_z0 := door_w.z + face * 1.115
	var walk_z1 := 14.0 if face > 0 else OutdoorBuilder.STREET_Z1 + 1.6
	OutdoorBuilder._slab(root, Rect2(door_w.x - 0.5, minf(walk_z0, walk_z1), 1.0, absf(walk_z1 - walk_z0)), Color("CFC8BA"), tex["concrete"], 0.006)
	for sx in [-1.6, 1.6]:
		if absf(sx) > 0:
			OutdoorBuilder._shrub(root, solids, door_w + Vector3(sx * 1.4, 0, 0) + outward * 0.75, 0.7)
	var porch := Furnish.porch_spot(c, key + "_porch", door_w + Vector3(0, 0, 0), outward)
	# Where a kid on a bike can throw the paper from: the sidewalk out front
	porch.set_meta("toss_point", Vector3(door_w.x + 0.9, 0, 14.8 if face > 0 else 24.4))
	# A mailbox at the curb and trash cans by the side of the house (chores!)
	var mz := 13.65 if face > 0 else 25.35
	var mbx := OutdoorBuilder._mailbox(root, solids, Vector3(door_w.x + 1.6, 0, mz), -1.0 if face > 0 else 1.0)
	mbx.name = key + "_mailbox"
	mbx.kind = "mailbox"
	mbx.home = key
	c["objects"][key + "_mailbox"] = mbx
	var side_x := r.position.x - 0.9 if (not c["mirror"]) else r.end.x + 0.9
	if h["garage"] and not c["mirror"]:
		side_x = r.position.x - 0.9
	if side_x > OutdoorBuilder.WALK.end.x - 1.0:
		side_x = r.position.x - 0.9
	OutdoorBuilder.trash_cans(root, c["objects"], solids, key + "_trash", key, Vector3(side_x, 0, _z(c, 3.0)),
		Vector3(-1, 0, 0) if side_x < r.position.x else Vector3(1, 0, 0))

	_stairs(c, S0, B0, D)
	_furnish(c, LW, DW, K0, KW, F, B0, D, W)
	_backyard(c)


static func _kid_name(key: String) -> String:
	for ch in Sim.CHARACTERS:
		if ch["home"] == key:
			return ch["name"]
	return String(HOMES.get(key, {}).get("kid", "Kid"))


static func _garage(c: Dictionary) -> void:
	var h: Dictionary = c["home_def"]
	var r: Rect2 = c["r"]
	var face: float = c["face"]
	var gx0 := r.end.x + 0.12      # (garage houses are never mirrored: it's always on the right)
	var gx1 := gx0 + 3.2
	var gz0 := r.position.y + 0.6
	var gz1 := r.end.y - 0.1 if face > 0 else r.position.y + r.size.y - 0.6
	if face < 0:
		gz0 = r.position.y + 0.1
	var g := Rect2(minf(gx0, gx1), gz0, 3.2, gz1 - gz0)
	var gb := StaticBody3D.new()
	gb.collision_layer = 2
	(c["root"] as Node3D).add_child(gb)
	var gh := 2.7
	RoomBuilder.add_shape(gb, Vector3(g.size.x, gh, g.size.y), Vector3(g.get_center().x, gh / 2.0, g.get_center().y))
	RoomBuilder.box(gb, Vector3(g.size.x, gh + 0.03, g.size.y), Vector3(g.get_center().x, gh / 2.0 - 0.015, g.get_center().y), h["siding"], c["tex"]["siding"])
	RoomBuilder.box(gb, Vector3(g.size.x + 0.06, 0.25, g.size.y + 0.06), Vector3(g.get_center().x, 0.095, g.get_center().y), RoomBuilder.FOUNDATION)
	var gfront := g.end.y if face > 0 else g.position.y
	RoomBuilder.box(gb, Vector3(2.6, 2.1, 0.05), Vector3(g.get_center().x, 1.05, gfront + face * 0.02), Palette.PAPER, c["tex"]["siding"], 2.0)
	var groof := RoomBuilder.box(c["root"], Vector3(g.size.x + 0.4, 0.15, g.size.y + 0.4), Vector3(g.get_center().x, gh + 0.075, g.get_center().y), h["roof"])
	groof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	(c["solids"] as Array).append(g)
	(c["buildings"] as Array).append(g)
	var dz0 := gfront if face > 0 else OutdoorBuilder.STREET_Z1
	var dz1 := OutdoorBuilder.STREET_Z0 if face > 0 else gfront
	OutdoorBuilder._slab(c["root"], Rect2(g.get_center().x - 1.5, dz0, 3.0, dz1 - dz0), Color("BDB6A8"), c["tex"]["concrete"], 0.012)


# ================================================================ stairs

## Stairs UP to the attic door and DOWN to the basement door, side by side,
## both climbing/descending toward the back wall (like Jamie's).
static func _stairs(c: Dictionary, S0: float, B0: float, D: float) -> void:
	var root: Node3D = c["root"]
	var out: Dictionary = c["out"]
	var tex: Dictionary = c["tex"]
	var key: String = c["key"]
	var tread: Color = (c["home_def"]["carpet"] as Color).darkened(0.15)
	var steps := StaticBody3D.new()
	steps.collision_layer = RoomBuilder.LAYER_FLOOR
	steps.collision_mask = 0
	steps.add_to_group("floor")
	root.add_child(steps)
	var face: float = c["face"]
	var dz := -face                       # world z per unit of v
	var box_at := func(u0: float, u1: float, v0: float, v1: float, y0: float, y1: float, color: Color, t: Texture2D = null) -> MeshInstance3D:
		var a := _p(c, u0, v0)
		var b := _p(c, u1, v1)
		return RoomBuilder.box(root, Vector3(absf(b.x - a.x), y1 - y0, absf(b.z - a.z)), Vector3((a.x + b.x) / 2.0, (y0 + y1) / 2.0, (a.z + b.z) / 2.0), color, t, 3.0)
	var shape_at := func(body: CollisionObject3D, u0: float, u1: float, v0: float, v1: float, y0: float, y1: float) -> void:
		var a := _p(c, u0, v0)
		var b := _p(c, u1, v1)
		RoomBuilder.add_shape(body, Vector3(absf(b.x - a.x), y1 - y0, absf(b.z - a.z)), Vector3((a.x + b.x) / 2.0, (y0 + y1) / 2.0, (a.z + b.z) / 2.0))

	var down0 := S0 + T / 2.0
	var down1 := S0 + 1.0
	var rail_u := S0 + 1.05
	var up0 := S0 + 1.1
	var up1 := S0 + STAIR_W - T / 2.0
	var up_start := B0 + 0.45
	var back_in := D - T / 2.0

	# ---- UP
	for i in 7:
		var top := 0.32 * (i + 1)
		var v0 := up_start + 0.35 * i
		box_at.call(up0, up1, v0, v0 + 0.35, 0.0, top, Palette.WOOD)
		box_at.call(up0 + 0.12, up1 - 0.12, v0, v0 + 0.35, top, top + 0.012, tread, tex["carpet"])
		shape_at.call(steps, up0, up1, v0, v0 + 0.35, top - 0.05, top)
	var land0 := up_start + 2.45
	box_at.call(up0, up1, land0, back_in, 0.0, HouseBuilder.LANDING_Y, Palette.WOOD)
	box_at.call(up0 + 0.05, up1 - 0.05, land0, back_in - 0.03, HouseBuilder.LANDING_Y, HouseBuilder.LANDING_Y + 0.012, tread, tex["carpet"])
	shape_at.call(steps, up0, up1, land0, back_in, HouseBuilder.LANDING_Y - 0.05, HouseBuilder.LANDING_Y)
	HouseBuilder.add_ramp(_rect(c, up0, up_start - 0.1, up1, back_in), _z(c, up_start), dz, 2.45, HouseBuilder.LANDING_Y)

	# ---- the half wall between, with a handrail
	box_at.call(rail_u - 0.05, rail_u + 0.05, B0, back_in, HouseBuilder.PIT_Y - 0.15, 0.975, Palette.CREAM)
	box_at.call(rail_u - 0.05, rail_u + 0.05, B0 + 0.002, back_in - 0.002, 0.975, 1.025, Palette.WOOD_DARK)
	_block(c, rail_u - 0.05, rail_u + 0.05, B0 + 0.35, back_in, -2.5, 4.0)

	# ---- DOWN, into a pit, to the basement door
	for i in 7:
		var top := -0.3 * (i + 1)
		var v0 := B0 + 0.2 * i
		box_at.call(down0, down1, v0, v0 + 0.2, HouseBuilder.PIT_Y - 0.1, top, Palette.WOOD)
		box_at.call(down0 + 0.1, down1 - 0.1, v0, v0 + 0.2, top, top + 0.012, tread, tex["carpet"])
		shape_at.call(steps, down0, down1, v0, v0 + 0.2, top - 0.05, top)
	# The riser under the hallway floor's edge, so you can't see under the floor from the pit
	box_at.call(down0, down1, B0 - 0.1, B0 - 0.002, HouseBuilder.PIT_Y - 0.1, -0.012, Palette.WOOD)
	var bottom := B0 + 1.4
	box_at.call(down0, down1, bottom, back_in - 0.1, HouseBuilder.PIT_Y - 0.1, HouseBuilder.PIT_Y, Palette.WOOD_DARK)
	shape_at.call(steps, down0, down1, bottom, back_in, HouseBuilder.PIT_Y - 0.05, HouseBuilder.PIT_Y)
	HouseBuilder.add_ramp(_rect(c, down0 - 0.2, B0 - 0.2, rail_u - 0.05, back_in), _z(c, B0), dz, 1.4, HouseBuilder.PIT_Y)
	# Paneled pit walls below the floor (the side and the back)
	box_at.call(down0 - 0.1, down0, B0, back_in, HouseBuilder.PIT_Y - 0.1, 0.0, Palette.WOOD, tex["panel"])
	box_at.call(down0, rail_u - 0.05, back_in - 0.1, back_in, HouseBuilder.PIT_Y - 0.1, 0.0, Palette.WOOD, tex["panel"])
	_block(c, down0 - 0.1, down0, B0, back_in, HouseBuilder.PIT_Y, 0.0)
	box_at.call(down0, down1, B0 - 0.02, B0 + 0.02, -0.05, 0.005, Palette.WOOD_DARK)   # nosing (a little proud of the floor)

	# ---- the doors at the top and the bottom (to the attic and the basement)
	var back_plane := _z(c, D)
	var fdir := Vector3(0, 0, face)       # facing into the house from the back wall
	var wall_dict := {"full": root, "along_x": true, "plane": back_plane, "thick": T}
	var upc := (up0 + up1) / 2.0
	var attic := HouseBuilder._door_object(root, "Attic Door", wall_dict, _x(c, upc), 0.75, 1.6, HouseBuilder.LANDING_Y,
		Color("7A4A2E"), true, INF, fdir)
	attic.name = key + "_attic_door"
	attic.approach_point = Vector3(_x(c, upc), 0, _z(c, D - 0.65))
	attic.use_point = attic.approach_point
	attic.kind = "portal"
	attic.home = key
	c["objects"][key + "_attic_door"] = attic
	var pit := Node3D.new()
	pit.position = Vector3(0, HouseBuilder.PIT_Y, 0)
	root.add_child(pit)
	var dc := (down0 + down1) / 2.0
	var bwall := {"full": pit, "along_x": true, "plane": _z(c, D - T / 2.0 - 0.05), "thick": 0.1}
	var basement := HouseBuilder._door_object(root, "Basement Door", bwall, _x(c, dc), 0.78, 1.9, 0.0, Color("7A4A2E"), true,
		HouseBuilder.PIT_Y, fdir)
	basement.name = key + "_basement_door"
	basement.approach_point = Vector3(_x(c, dc), 0, _z(c, D - 0.65))
	basement.use_point = basement.approach_point
	basement.kind = "portal"
	basement.home = key
	c["objects"][key + "_basement_door"] = basement
	(out["portal_pairs"] as Array).append([key + "_attic_door", key + "_attic_exit"])
	(out["portal_pairs"] as Array).append([key + "_basement_door", key + "_basement_exit"])
	# lanes for click-to-walk
	(c["doorways"] as Array).append(_rect(c, upc - 0.3, B0 - 0.3, upc + 0.3, back_in - 0.2))
	(c["doorways"] as Array).append(_rect(c, dc - 0.3, B0 - 0.3, dc + 0.3, back_in - 0.2))
	# a light at the top, and one down in the pit
	_ceiling_light(c, S0 + STAIR_W / 2.0, (B0 + D) / 2.0, 6.0, 0.6, 1.2, EH)
	var pl := HouseBuilder._light(root, _p(c, dc, D - 1.0, -0.6), Palette.LAMP, 3.0, false)
	RoomBuilder.add_lamp(out, pl, null, 0.45, 0.6)


## Invisible solid (for first-person walking) over a local rectangle.
static func _block(c: Dictionary, u0: float, u1: float, v0: float, v1: float, y0: float, y1: float) -> void:
	var b := StaticBody3D.new()
	b.collision_layer = 2
	b.collision_mask = 0
	(c["root"] as Node3D).add_child(b)
	var a := _p(c, u0, v0)
	var e := _p(c, u1, v1)
	RoomBuilder.add_shape(b, Vector3(absf(e.x - a.x), y1 - y0, absf(e.z - a.z)), Vector3((a.x + e.x) / 2.0, (y0 + y1) / 2.0, (a.z + e.z) / 2.0))


# ================================================================ furniture

static func _furnish(c: Dictionary, LW: float, DW: float, K0: float, KW: float, F: float, B0: float, D: float, W: float) -> void:
	var h: Dictionary = c["home_def"]
	var key: String = c["key"]
	var back: Dictionary = c["back"]
	var front_side := 1.0 if (float(c["face"]) > 0) != bool(c["mirror"]) else -1.0   # local +x of a front-facing piece is +u?
	var spots := {}

	# ---- living room
	Furnish.tv(c, key + "_tv", _p(c, 0.4, F / 2.0), _yaw(c, "+u"))
	var couch := Furnish.couch(c, key + "_couch", _p(c, 2.43, F / 2.0), _yaw(c, "-u"), h["couch"])
	Furnish.rug(c, _p(c, 1.5, F / 2.0), Vector2(2.2, 2.6) if false else Vector2(1.0, 1.0), h["carpet"].lightened(0.3))
	Furnish.bookshelf(c, key + "_bookshelf", _p(c, 0.75, F - 0.28), _yaw(c, "front"), key.length())
	Furnish.armchair(c, _p(c, LW - 0.55, 0.6), _yaw(c, "back") + (45.0 if not c["mirror"] else -45.0), h["couch"].darkened(0.2))
	Furnish.floor_lamp(c, _p(c, 0.35, 0.35))
	_ceiling_light(c, LW / 2.0, F / 2.0, 6.0)
	spots["living"] = [_p(c, LW - 0.9, F - 1.1), _yaw(c, "-u")]

	# ---- dining room
	var table := Furnish.table(c, key + "_table", "Dining Table", _p(c, LW + DW / 2.0, F / 2.0 + 0.25), _yaw(c, "front"),
		Color("E85A4A") if key in ["garcias", "parkers"] else Palette.WOOD, Vector2(1.1, 0.8), key in ["garcias", "parkers"])
	Props.pizza_box(c["root"], c["objects"], key + "_pizza_box", table, Vector3(-0.2, 0.765, 0), key)
	Furnish.plant(c, _p(c, K0 - 0.4, 0.45))

	# ---- kitchen
	Furnish.sink(c, key + "_sink", _p(c, K0 + KW / 2.0, 0.39), _yaw(c, "back"), Palette.CREAM, h["trim"].darkened(0.1), minf(1.3, KW - 0.9))
	Furnish.stove(c, key + "_stove", _p(c, W - 0.39, 1.2), _yaw(c, "-u"))
	Furnish.counter(c, _p(c, W - 0.39, 2.25), _yaw(c, "-u"), 1.0)
	Furnish.fridge(c, key + "_fridge", _p(c, W - 0.43, F - 0.5), _yaw(c, "-u"),
		[Palette.AVOCADO, Color("D9C49E"), Palette.PAPER, Color("C8A250"), Palette.AVOCADO][HOMES.keys().find(key) % 5])
	Furnish.wall_phone(c, key + "_phone", _p(c, K0 + T / 2.0 + 0.006, F - 1.0), _yaw(c, "+u"))
	_ceiling_light(c, K0 + KW / 2.0, F / 2.0, 5.0)
	spots["kitchen"] = [_p(c, W - 1.25, 1.2), _yaw(c, "+u")]

	# ---- hallway
	Furnish.rug(c, _p(c, W / 2.0 - 0.6, F + HALL_D / 2.0), Vector2(W - 3.0, 0.7), Palette.RUST)
	_ceiling_light(c, W / 2.0, F + HALL_D / 2.0, 5.0, 0.6, 1.1)

	# ---- the kid's room: bed in the back corner, a desk and a dresser along the far wall
	var k0: float = back["kid"][0]
	var k1: float = back["kid"][1]
	Furnish.bed(c, key + "_bed", "%s's Bed" % _kid_name(key), "bed", _p(c, k0 + 0.6, D - 1.15), _yaw(c, "front"),
		h["kid_color"], false, front_side)
	Furnish.nightstand(c, _p(c, k0 + 1.35, D - 0.3), _yaw(c, "front"))
	Furnish.desk(c, key + "_desk", _p(c, k1 - 0.38, B0 + 1.0), _yaw(c, "-u"), h["kid_color"])
	Furnish.dresser(c, key + "_dresser", _p(c, k1 - 0.33, D - 1.05), _yaw(c, "-u"))
	Furnish.poster(c, _p(c, k0 + T / 2.0 + 0.002, B0 + 1.2, 1.6), _yaw(c, "+u"), h["kid_color"], Palette.GOLD)
	Furnish.rug(c, _p(c, (k0 + k1) / 2.0 + 0.1, B0 + 1.7), Vector2(1.2, 1.0), h["kid_color"].lightened(0.15))
	_ceiling_light(c, (k0 + k1) / 2.0, (B0 + D) / 2.0, 5.0)

	# ---- the parents' room: a big bed in the middle of the back wall, the closet and the vanity on the sides
	var p0: float = back["parents"][0]
	var p1: float = back["parents"][1]
	var pc := (p0 + p1) / 2.0
	Furnish.bed(c, key + "_parents_bed", "Mom & Dad's Bed", "parents_bed", _p(c, pc, D - 1.15), _yaw(c, "front"),
		h["siding"].darkened(0.25), true, front_side, true)
	for sd in [-1.0, 1.0]:
		Furnish.nightstand(c, _p(c, pc + sd * 1.0, D - 0.3), _yaw(c, "front"), sd > 0)
	Furnish.closet(c, key + "_closet", _p(c, p0 + 0.38, B0 + 0.95), _yaw(c, "+u"))
	Furnish.vanity(c, key + "_vanity", _p(c, p1 - 0.3, B0 + 0.8), _yaw(c, "-u"))
	_ceiling_light(c, pc, (B0 + D) / 2.0, 5.0)
	spots["bed"] = [_p(c, pc, D - 2.75), _yaw(c, "back")]
	spots["bedroom"] = [_p(c, (k0 + k1) / 2.0, B0 + 1.4), _yaw(c, "back")]

	# ---- the bathroom: the tub across the back, the toilet and the sink on the sides
	var b0: float = back["bath"][0]
	var b1: float = back["bath"][1]
	Furnish.tub(c, key + "_tub", _p(c, b0 + 0.86, D - 0.47), _yaw(c, "front"), [Palette.PAPER, Color("F2A0B5"), Color("BFE0EE"), Color("D9E8B0"), Palette.PAPER][HOMES.keys().find(key) % 5])
	Furnish.toilet(c, key + "_toilet", _p(c, b1 - 0.31, D - 1.55), _yaw(c, "-u"))
	Furnish.bath_sink(c, key + "_bath_sink", _p(c, b0 + 0.24, B0 + 0.9), _yaw(c, "+u"))
	_ceiling_light(c, (b0 + b1) / 2.0, (B0 + D) / 2.0, 4.0)

	(c["out"]["npc_spots"] as Dictionary)[key] = spots


# ================================================================ the backyard

static func _backyard(c: Dictionary) -> void:
	var h: Dictionary = c["home_def"]
	var r: Rect2 = c["r"]
	var face: float = c["face"]
	var root: Node3D = c["root"]
	var solids: Array[Rect2] = c["solids"]
	var key: String = c["key"]
	var back_z := r.position.y if face > 0 else r.end.y
	var yard_end := -12.0 if face > 0 else 43.0
	var depth := absf(yard_end - back_z)
	var x0 := r.position.x - 0.8
	var x1 := r.end.x + 0.8
	# The back fence, with a gate in the middle (and side fences where there's no neighbor fence)
	var gate := (x0 + x1) / 2.0
	if face < 0:
		OutdoorBuilder._fence(root, solids, Vector3(x0, 0, yard_end), Vector3(gate - 0.6, 0, yard_end))
		OutdoorBuilder._fence(root, solids, Vector3(gate + 0.6, 0, yard_end), Vector3(x1, 0, yard_end))
		OutdoorBuilder._fence(root, solids, Vector3(x0, 0, back_z + 1.0), Vector3(x0, 0, yard_end))
		OutdoorBuilder._fence(root, solids, Vector3(x1, 0, back_z + 1.0), Vector3(x1, 0, yard_end))
	else:
		var fx0 := maxf(x0, -15.3)
		var fx1 := minf(x1, -4.0) if key == "hendersons" else x1
		if key == "garcias":
			fx0 = 20.0
		OutdoorBuilder._fence(root, solids, Vector3(fx0, 0, yard_end), Vector3(fx1, 0, yard_end))
		if key == "hendersons":
			OutdoorBuilder._fence(root, solids, Vector3(fx0, 0, yard_end), Vector3(fx0, 0, back_z - 1.6))
		else:
			OutdoorBuilder._fence(root, solids, Vector3(fx1, 0, yard_end), Vector3(fx1, 0, back_z - 1.6))
		if h.get("fence_both", false):
			OutdoorBuilder._fence(root, solids, Vector3(fx0, 0, yard_end), Vector3(fx0, 0, back_z - 1.6))
	# A little patio by the house
	var pz := back_z - face * 1.2
	OutdoorBuilder._slab(root, Rect2(r.get_center().x - 2.0, minf(pz - 0.9, pz + 0.9), 4.0, 1.8), Color("B8AFA0"), c["tex"]["concrete"], 0.01)
	var cx := r.get_center().x
	var mid_z := back_z - face * depth * 0.55
	var spots := [Vector3(cx - r.size.x * 0.25, 0, mid_z), Vector3(cx + r.size.x * 0.25, 0, mid_z)]
	var items: Array = h["yard"]
	for i in items.size():
		var at: Vector3 = spots[i]
		match String(items[i]):
			"swing_set":
				_swing_set(c, key + "_swing_set", at)
			"kiddie_pool":
				_kiddie_pool(c, key + "_pool", at)
			"garden":
				_garden(c, key + "_garden", at)
			"trampoline":
				_trampoline(c, key + "_trampoline", at)
			"picnic":
				var pt := Furnish.table(c, key + "_picnic", "Picnic Table", at, 0, Color("9C6B45"), Vector2(1.6, 0.8), false, 2)
				pt.kind = "picnic"
			"lemonade":
				_lemonade_stand(c, Vector3(gate, 0, yard_end + face * 1.5) if face < 0 else at)
			"pool":
				_pool(c, key + "_swimming_pool", Vector3(cx, 0, mid_z + face * 0.6))
	# A push mower on the patio (for the chores) and the backyard spot for Mom and Dad
	var mower := Furnish.item(c, key + "_mower", "Lawn Mower", "mower", Vector3(r.get_center().x + 2.6, 0, pz), 180.0 if face > 0 else 0.0)
	_mower_model(mower)
	Props.finish(mower, solids, Vector3(0.55, 0.9, 0.9), Vector3(0, 0, 1.0), null, Vector3(0, 0.4, 0))
	c["out"]["npc_spots"][key]["backyard"] = [Vector3(r.get_center().x - 1.0, 0, pz - face * 1.4), 180.0 if face > 0 else 0.0]


static func _swing_set(c: Dictionary, key: String, at: Vector3) -> void:
	var o := Furnish.item(c, key, "Swing Set", "swing_set", at, 0)
	var metal := Color("C0322A")
	for x in [-1.2, 1.2]:
		for z in [-0.6, 0.6]:
			var leg := Props.part(o, Vector3(0.07, 2.2, 0.07), Vector3(x, 1.05, z * 0.6), metal)
			leg.rotation.x = z * 0.35
	Props.part(o, Vector3(2.5, 0.08, 0.08), Vector3(0, 2.1, 0), metal)
	for x in [-0.55, 0.55]:
		Props.part(o, Vector3(0.02, 1.5, 0.02), Vector3(x - 0.2, 1.35, 0), Palette.MUTED, null, false)
		Props.part(o, Vector3(0.02, 1.5, 0.02), Vector3(x + 0.2, 1.35, 0), Palette.MUTED, null, false)
		Props.part(o, Vector3(0.5, 0.04, 0.2), Vector3(x, 0.55, 0), Palette.INK2)
	Props.finish(o, c["solids"], Vector3(2.6, 2.2, 1.0), Vector3(0, 0, 1.1), Vector3(-0.55, 0, 0), Vector3(-0.55, 0.8, 3.0),
		Vector3(0, 1.1, 0))
	(c["solids"] as Array).pop_back()
	(c["solids"] as Array).append(Rect2(at.x - 1.3, at.z - 0.15, 0.2, 0.3))
	(c["solids"] as Array).append(Rect2(at.x + 1.1, at.z - 0.15, 0.2, 0.3))


static func _kiddie_pool(c: Dictionary, key: String, at: Vector3) -> void:
	var o := Furnish.item(c, key, "Kiddie Pool", "kiddie_pool", at, 0)
	Props.part(o, Vector3(1.8, 0.3, 1.8), Vector3(0, 0.15, 0), Color("4FB0E0"))
	Props.part(o, Vector3(1.6, 0.02, 1.6), Vector3(0, 0.28, 0), Color("BFE8F7"), null, false)
	Props.part(o, Vector3(0.3, 0.3, 0.3), Vector3(0.5, 0.42, 0.3), Palette.GOLD, null, false)   # beach ball
	Props.finish(o, c["solids"], Vector3(1.8, 0.3, 1.8), Vector3(0, 0, 1.4), Vector3(0, 0, 0.2), Vector3(0, 0.3, 0))


static func _garden(c: Dictionary, key: String, at: Vector3) -> void:
	var o := Furnish.item(c, key, "Vegetable Garden", "garden", at, 0)
	Props.part(o, Vector3(2.4, 0.18, 1.4), Vector3(0, 0.09, 0), Color("5C3A26"))
	var cols := [Color("C0322A"), Color("4F7A3A"), Color("E8C24A"), Color("6A9446")]
	for i in 8:
		Props.part(o, Vector3(0.22, 0.3, 0.22), Vector3(-0.9 + (i % 4) * 0.6, 0.33, -0.35 + (i / 4) * 0.7), cols[i % 4], null, false)
	Props.finish(o, c["solids"], Vector3(2.4, 0.4, 1.4), Vector3(0, 0, 1.1), null, Vector3(0, 0.3, 0))


static func _trampoline(c: Dictionary, key: String, at: Vector3) -> void:
	var o := Furnish.item(c, key, "Trampoline", "trampoline", at, 0)
	Props.part(o, Vector3(2.2, 0.08, 2.2), Vector3(0, 0.75, 0), Color("2B2B30"))
	Props.part(o, Vector3(2.4, 0.06, 2.4), Vector3(0, 0.72, 0), Color("2E5E9E"))
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			Props.part(o, Vector3(0.06, 0.72, 0.06), Vector3(x, 0.36, z), Palette.MUTED, null, false)
	Props.finish(o, c["solids"], Vector3(2.4, 0.8, 2.4), Vector3(0, 0, 1.6), Vector3(0, 0, 0), Vector3(0, 1.5, 3.0))


## A swimming pool, set into a concrete deck, with a diving board and a ladder.
static func _pool(c: Dictionary, key: String, at: Vector3) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var w := 6.0
	var d := 3.4
	var rim := 0.9
	# The deck: four slabs around the water (raised 4 cm, so the water sits below it)
	var deck := Color("D9D2C2")
	for r in [Rect2(at.x - w / 2.0 - rim, at.z - d / 2.0 - rim, w + 2.0 * rim, rim), Rect2(at.x - w / 2.0 - rim, at.z + d / 2.0, w + 2.0 * rim, rim),
			Rect2(at.x - w / 2.0 - rim, at.z - d / 2.0, rim, d), Rect2(at.x + w / 2.0, at.z - d / 2.0, rim, d)]:
		OutdoorBuilder._slab(root, r, deck, tex["concrete"], 0.04)
	# The coping, a bright blue liner and the water
	var water := RoomBuilder.box(root, Vector3(w, 0.06, d), Vector3(at.x, -0.01, at.z), Color("3FA8E0"))
	var wm: StandardMaterial3D = water.material_override
	wm.roughness = 0.05
	wm.metallic = 0.2
	wm.emission_enabled = true
	wm.emission = Color("2E88C8")
	wm.emission_energy_multiplier = 0.25
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side in [-1.0, 1.0]:
		RoomBuilder.box(root, Vector3(w - 0.01, 0.06, 0.05), Vector3(at.x, 0.0, at.z + side * (d / 2.0 - 0.02)), Color("BFE8F7"))
	# Diving board, ladder, an inner tube
	var o := Furnish.item(c, key, "Swimming Pool", "swim_pool", at, 0)
	Props.part(o, Vector3(0.5, 0.12, 1.8), Vector3(w / 2.0 - 0.3, 0.35, -d / 2.0 - 0.2), Palette.PAPER)
	Props.part(o, Vector3(0.4, 0.3, 0.3), Vector3(w / 2.0 - 0.3, 0.15, -d / 2.0 - 0.95), Palette.MUTED, null, false)
	for lx in [-w / 2.0 + 0.6, -w / 2.0 + 1.0]:
		Props.part(o, Vector3(0.05, 0.9, 0.05), Vector3(lx, 0.45, d / 2.0 - 0.05), Color("C8CCD0"), null, false)
	var tube := Props.part(o, Vector3(0.7, 0.14, 0.7), Vector3(-1.0, 0.04, 0.4), Color("F2A0B5"), null, false)
	tube.rotation.y = 0.5
	Props.finish(o, c["solids"], Vector3(w, 0.4, d), Vector3(0, 0, d / 2.0 + 0.55), Vector3(0, 0, 0), Vector3(0, 0, -4.0))
	o.set_meta("water_y", -0.04)
	var rail := Props.solid(root, at, 0)     # (keeps first-person walkers from wading in by accident)
	RoomBuilder.add_shape(rail, Vector3(w - 0.4, 0.5, d - 0.4), Vector3(0, 0.25, 0))


## A little red push mower.
static func _mower_model(o: SmartObject) -> void:
	Props.part(o, Vector3(0.5, 0.25, 0.6), Vector3(0, 0.22, 0), Color("C0322A"))
	Props.part(o, Vector3(0.2, 0.2, 0.25), Vector3(0, 0.42, 0.05), Palette.INK2)
	for wx in [-0.27, 0.27]:
		for wz in [-0.22, 0.22]:
			Props.part(o, Vector3(0.06, 0.16, 0.16), Vector3(wx, 0.08, wz), Palette.INK, null, false)
	for hx in [-0.2, 0.2]:
		var bar := Props.part(o, Vector3(0.04, 0.9, 0.04), Vector3(hx, 0.65, 0.42), Palette.MUTED, null, false)
		bar.rotation.x = 0.55
	Props.part(o, Vector3(0.5, 0.04, 0.04), Vector3(0, 1.02, 0.66), Palette.INK, null, false)


## Molly Parker's lemonade stand (Molly herself is added by main.gd as a person).
static func _lemonade_stand(c: Dictionary, at: Vector3) -> void:
	var b := Props.solid(c["root"], at, 0)
	RoomBuilder.box(b, Vector3(1.4, 0.85, 0.6), Vector3(0, 0.425, 0), Palette.PAPER)
	RoomBuilder.box(b, Vector3(1.5, 0.05, 0.7), Vector3(0, 0.875, 0), Color("F7D046"))
	for x in [-0.66, 0.66]:
		RoomBuilder.box(b, Vector3(0.05, 0.9, 0.05), Vector3(x, 1.35, 0.25), Palette.WOOD)
	RoomBuilder.box(b, Vector3(1.5, 0.35, 0.04), Vector3(0, 1.85, 0.25), Color("F7D046"))
	var sign := Label3D.new()
	sign.text = "LEMONADE 25¢"
	sign.font_size = 56
	sign.pixel_size = 0.004
	sign.modulate = Color("C0322A")
	sign.position = Vector3(0, 1.85, 0.28)
	b.add_child(sign)
	RoomBuilder.box(b, Vector3(0.2, 0.3, 0.2), Vector3(-0.35, 1.05, 0), Color("F7E99A"))   # the pitcher
	for i in 3:
		RoomBuilder.box(b, Vector3(0.07, 0.1, 0.07), Vector3(0.1 + i * 0.12, 0.95, 0.05), Palette.PAPER)
	Props.finish(b, c["solids"], Vector3(1.5, 1.0, 0.7), Vector3.ZERO)
	c["out"]["lemonade_spot"] = at
