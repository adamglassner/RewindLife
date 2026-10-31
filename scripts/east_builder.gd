class_name EastBuilder
extends RefCounted
## The east end of town (Maple Street and Main Street both run out here):
##
##   z = -8..12  [MAPLE GROVE FAIRGROUNDS x 90..130] (the carnival and the circus set up here)
##   z = 14      ====== Maple Street (east end) ==========================
##   z = 27..43  [SKATE PARK x 67..86] [ROCKET BURGER + drive-thru x 87..109] [STRIKE ZONE LANES x 111..131]
##   z = 46      ====== MAIN STREET (east end: out of town it becomes the highway) ======
##   z = 56..90  [THE MALL x 74..114, see mall_builder.gd]  [mall parking x 116..132]
##
## The drive-thru lane runs up the east side of Rocket Burger, along the back and
## down the west side past the menu board and the window (TownLife sends cars through).

const SKATE := Rect2(67.0, 27.5, 19.0, 15.0)
const BURGER_LOT := Rect2(87.0, 26.5, 21.6, 17.9)
const BURGER := Rect2(91.0, 31.0, 12.0, 8.0)
const BOWLING := Rect2(111.0, 29.0, 20.0, 14.0)
const FAIR := Rect2(90.0, -8.0, 40.0, 20.0)
const LOT := Rect2(116.0, 58.0, 16.0, 30.0)
const T := 0.15

## The drive-thru: in from Main Street at x = 106, up, along the back, down past the window.
const DT_IN_X := 106.0
const DT_BACK_Z := 28.4
const DT_OUT_X := 89.2
const DT_MENU := Vector3(DT_OUT_X, 0, 30.6)
const DT_WINDOW := Vector3(DT_OUT_X, 0, 35.0)

const BOWL_LANES := [113.6, 116.0, 118.4, 120.8]
const FOUL_Z := 38.4
const PIN_Z := 30.6


static func rects() -> Array[Rect2]:
	return [BURGER, BOWLING]


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2]) -> void:
	var c := {"root": root, "out": out, "tex": tex, "solids": solids, "free": free, "doorways": doorways,
		"buildings": buildings, "objects": out["objects"], "home": "town", "level": 0, "x0": 0.0}
	_streets(c)
	_skate_park(c)
	_burger(c)
	_bowling(c)
	_fairgrounds(c)
	_parking(c)
	_trees(c)


static func _act(o: SmartObject, title: String, mins: int, fx: Dictionary, pose := "stand", msgs: Array = [], money := 0.0,
		hours := Vector2(0, 24)) -> Activity:
	return MallBuilder._act(o, title, mins, fx, pose, msgs, money, hours)


static func _worker(c: Dictionary, id: String, title: String, pos: Vector3, yaw: float, look: Dictionary, lines: Array,
		hours: Vector2, door: Vector3, lock: String) -> void:
	CivicBuilder._staff(c, id, title, pos, yaw, look, 1.6, hours, [], lines, lock)
	var st: Dictionary = (c["out"]["staff"] as Array).back()
	st["door"] = door
	st["edge"] = TownFolk.EDGES[2]
	st["lock"] = lock


# ================================================================ the streets out here

static func _streets(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var out: Dictionary = c["out"]
	var asphalt := Color("4A4950")
	var e := OutdoorBuilder.EAST_END
	# Main Street keeps going east out of town (the highway): the traffic comes and goes this way
	OutdoorBuilder._slab(root, Rect2(e, DowntownBuilder.Z0 + 0.15, 90.0, DowntownBuilder.Z1 - DowntownBuilder.Z0 - 0.3), asphalt, tex["asphalt"], -0.015)
	for x in range(int(e) + 2, int(e) + 88, 4):
		OutdoorBuilder._slab(root, Rect2(x, (DowntownBuilder.Z0 + DowntownBuilder.Z1) / 2.0 - 0.06, 2.0, 0.12), Color("E8C24A"), null, -0.008)
	OutdoorBuilder._sign(root, solids, Vector3(e - 1.0, 0, DowntownBuilder.Z1 + 1.0), "THANKS FOR\nVISITING\nMAPLE GROVE!", Color("2E6B4F"), Palette.PAPER, Vector2(1.5, 0.8), 0.0)
	OutdoorBuilder._sign(root, solids, Vector3(e - 1.0, 0, DowntownBuilder.Z0 - 1.0), "ROUTE 9\nSPRINGFIELD 12", Color("2E6B4F"), Palette.PAPER, Vector2(1.3, 0.6), 180.0)
	# Streetlights along both streets
	for x in [90.0, 110.0, 128.0]:
		OutdoorBuilder._streetlight(root, solids, out, Vector3(x, 0, DowntownBuilder.Z1 + 1.3), -1.0)
		OutdoorBuilder._streetlight(root, solids, out, Vector3(x - 8.0, 0, OutdoorBuilder.STREET_Z0 - 1.25), 1.0)
	for x in [66.5, 100.0, 120.0]:
		OutdoorBuilder._streetlight(root, solids, out, Vector3(x, 0, DowntownBuilder.Z0 - 1.3), 1.0)
	OutdoorBuilder._sign(root, solids, Vector3(64.6, 0, DowntownBuilder.Z0 - 0.6), "SPEED\nLIMIT\n30", Palette.PAPER, Palette.INK, Vector2(0.6, 0.75), 180.0)
	# The phone booth by the skate park
	var pc := {"root": root, "objects": c["objects"], "solids": solids, "home": "town", "level": 0}
	PayPhones.booth(pc, "phone_booth_skate", Vector3(65.8, 0, 43.3), 180.0)
	PayPhones.booth(pc, "phone_booth_busstop", Vector3(9.4, 0, DowntownBuilder.Z0 - 0.8), 180.0)


# ================================================================ the skate park

static func _skate_park(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var r := SKATE
	var concrete := Color("B8B4AC")
	OutdoorBuilder._slab(root, r, concrete, tex["concrete"], 0.012)
	# A low wall all the way around, with a way in from Main Street
	var wall := Color("9A968E")
	var gap0 := 74.5
	var gap1 := 78.5
	for seg in [[Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), Vector2(gap0, r.end.y)],
			[Vector2(gap1, r.end.y), Vector2(r.end.x, r.end.y)], [Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y)],
			[Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y)]]:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var along_x := absf(a.y - b.y) < 0.01
		var len := (b - a).length()
		var mid := (a + b) / 2.0
		var hgt := 1.9 if along_x and a.y == r.position.y else 0.55
		var size := Vector3(len + 0.3, hgt, 0.3) if along_x else Vector3(0.3, hgt, len - 0.3)
		var w := Props.solid(root, Vector3(mid.x, 0, mid.y), 0)
		RoomBuilder.box(w, size, Vector3(0, hgt / 2.0, 0), wall, tex["concrete"], 1.0)
		Props.finish(w, solids, size, Vector3.ZERO)
	# Graffiti on the back wall
	var tags := [["SKATE OR DIE", Color("FF4FD8"), 70.5], ["RAD!", Color("4FD84F"), 74.6], ["MAPLE GROVE RIPPERS", Color("F7D046"), 79.2], ["SHRED", Color("4FC8FF"), 84.0]]
	for t in tags:
		var l := CivicBuilder._label(root, t[0], Vector3(t[2], 1.1, r.position.y + 0.17), 0.0, t[1], 0.006, 64)
		l.outline_size = 10
		l.outline_modulate = Color(0.1, 0.1, 0.1)
	var sign := CivicBuilder._label(root, "SKATE PARK", Vector3((gap0 + gap1) / 2.0, 1.75, r.end.y + 0.05), 0.0, Palette.PAPER, 0.006, 64)
	sign.outline_size = 10
	sign.outline_modulate = Color("C0322A")
	for px in [gap0 - 0.15, gap1 + 0.15]:
		var post := Props.solid(root, Vector3(px, 0, r.end.y), 0)
		RoomBuilder.box(post, Vector3(0.16, 2.0, 0.16), Vector3(0, 1.0, 0), Color("5A5E63"))
		Props.finish(post, solids, Vector3(0.2, 2.0, 0.2), Vector3.ZERO)
	var bar := RoomBuilder.box(root, Vector3(gap1 - gap0 + 0.5, 0.5, 0.06), Vector3((gap0 + gap1) / 2.0, 1.72, r.end.y), Color("2B2B30"))
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The half-pipe (along z, at the west end)
	var hp := CivicBuilder._usable(c, "half_pipe", "Half-Pipe", "half_pipe", Vector3(71.5, 0, 34.5), 0)
	var hw := 6.0
	for side in [-1.0, 1.0]:
		var z0: float = side * 5.0
		Props.part(hp, Vector3(hw, 2.0, 0.8), Vector3(0, 1.0, z0 + side * 0.4), concrete.darkened(0.12))           # the deck
		Props.part(hp, Vector3(hw + 0.1, 0.06, 0.06), Vector3(0, 2.0, z0), Color("C8CCD0"), null, false)            # coping
		var ramp := Props.part(hp, Vector3(hw - 0.02, 0.16, 3.25), Vector3(0, 1.0, z0 - side * 1.25), Color("C8B48A"))
		ramp.rotation.x = side * -0.675
		for k in 3:
			var h := 2.0 - 0.48 * (k + 1) - 0.05     # (just under the ramp)
			for sx in [-1.0, 1.0]:
				Props.part(hp, Vector3(0.1, h, 0.6), Vector3(sx * (hw / 2.0 - 0.07), h / 2.0, z0 - side * (0.3 + k * 0.6)), concrete.darkened(0.2), null, false)
		# rails up on the deck
		Props.part(hp, Vector3(hw, 0.06, 0.06), Vector3(0, 2.9, z0 + side * 0.78), Color("5A5E63"), null, false)
		for px in [-hw / 2.0 + 0.1, 0.0, hw / 2.0 - 0.1]:
			Props.part(hp, Vector3(0.06, 0.92, 0.06), Vector3(px, 2.44, z0 + side * 0.78), Color("5A5E63"), null, false)
	Props.part(hp, Vector3(hw - 0.02, 0.04, 5.0), Vector3(0, 0.03, 0), Color("C8B48A"))
	Props.finish(hp, solids, Vector3(hw, 2.2, 11.6), Vector3(hw / 2.0 + 0.9, 0, 0), Vector3(0, 0, 0), Vector3(0, 1.0, 0))
	hp.use_point = Vector3(71.5, 0, 34.5)
	var a := _act(hp, "Skate the Half-Pipe", 30, {"fun": 70.0, "energy": -14.0}, "skate_pipe",
		["Drop in! ...You land it! Your knees are shaking.", "Back and forth, higher and higher. TOTALLY gnarly.", "You eat it on the third pass. Walk it off."])
	a.needs_owned = "skateboard"
	a.memory_id = "skate"
	a.from_hour = 7.0
	a.to_hour = 21.0
	_act(hp, "Watch the Skaters", 20, {"fun": 26.0, "social": 14.0}, "stand",
		["A kid with a mohawk pulls a 360. Everybody yells.", "Somebody's boombox is playing the best song ever."]).from_hour = 7.0
	# A quarter pipe on the east side, a fun box and a grind rail in the middle
	var qp := CivicBuilder._usable(c, "quarter_pipe", "Quarter Pipe", "half_pipe", Vector3(84.4, 0, 33.0), -90)
	Props.part(qp, Vector3(5.0, 1.6, 0.8), Vector3(0, 0.8, -0.4), concrete.darkened(0.12))
	var qr := Props.part(qp, Vector3(4.98, 0.16, 2.5), Vector3(0, 0.8, 0.95), Color("C8B48A"))
	qr.rotation.x = 0.7
	Props.finish(qp, solids, Vector3(5.0, 1.7, 3.0), Vector3(0, 0, 2.6), Vector3(0, 0, 1.6), Vector3(0, 0.8, 0))
	(solids as Array).pop_back()
	solids.append(Rect2(82.9, 30.5, 2.95, 5.0))
	a = _act(qp, "Skate the Quarter Pipe", 20, {"fun": 50.0, "energy": -10.0}, "skate_ramp",
		["Up, kick-turn, down. Up, kick-turn, down.", "You try an air. You get... some air."])
	a.needs_owned = "skateboard"
	a.from_hour = 7.0
	a.to_hour = 21.0
	var fb := CivicBuilder._usable(c, "fun_box", "Fun Box", "fun_box", Vector3(78.5, 0, 34.0), 0)
	Props.part(fb, Vector3(2.4, 0.5, 1.6), Vector3(0, 0.25, 0), concrete.darkened(0.1))
	for side in [-1.0, 1.0]:
		var rp := Props.part(fb, Vector3(2.38, 0.12, 1.1), Vector3(0, 0.25, side * 1.25), Color("C8B48A"))
		rp.rotation.x = side * 0.44
	Props.part(fb, Vector3(2.42, 0.05, 0.05), Vector3(0, 0.5, 0.8), Color("C8CCD0"), null, false)
	Props.finish(fb, solids, Vector3(2.4, 0.55, 3.6), Vector3(1.9, 0, 0), Vector3(0, 0, 0), Vector3(0, 0.4, 0))
	a = _act(fb, "Ollie the Fun Box", 20, {"fun": 46.0, "energy": -8.0}, "skate_ramp",
		["Pop! You clear it! (Barely.)", "Kickflip attempt number 12. So close."])
	a.needs_owned = "skateboard"
	a.from_hour = 7.0
	a.to_hour = 21.0
	var rail := CivicBuilder._usable(c, "grind_rail", "Grind Rail", "fun_box", Vector3(78.5, 0, 39.0), 0)
	Props.part(rail, Vector3(3.2, 0.06, 0.06), Vector3(0, 0.46, 0), Color("C8CCD0"))
	for px in [-1.4, 1.4]:
		Props.part(rail, Vector3(0.06, 0.43, 0.06), Vector3(px, 0.215, 0), Color("5A5E63"), null, false)
	Props.finish(rail, solids, Vector3(3.2, 0.5, 0.2), Vector3(0, 0, 0.8), Vector3(0, 0, 0), Vector3(0, 0.4, 0))
	a = _act(rail, "Grind the Rail", 15, {"fun": 40.0, "energy": -6.0}, "skate_ramp", ["Ksssssshhhh. A perfect 50-50!", "You slip off halfway. Still counts."])
	a.needs_owned = "skateboard"
	# Benches to sit and watch
	for bx in [69.6, 83.4]:
		var b := CivicBuilder._usable(c, "skate_bench_%d" % int(bx), "Bench", "mall_bench", Vector3(bx, 0, r.end.y - 0.85), 180)
		Props.part(b, Vector3(1.8, 0.08, 0.5), Vector3(0, 0.45, 0), Palette.WOOD)
		for lx in [-0.8, 0.8]:
			Props.part(b, Vector3(0.08, 0.42, 0.44), Vector3(lx, 0.21, 0), Color("4A4A52"), null, false)
		Props.finish(b, solids, Vector3(1.8, 0.5, 0.5), Vector3(0, 0, 0.8), Vector3(0, 0, 0.1), Vector3(0, 0.9, 3.0))
		var s := _act(b, "Sit and Watch the Skaters", 30, {"fun": 24.0, "social": 16.0, "energy": 8.0}, "sit",
			["Somebody bails, gets up, and goes again. Respect."])
		s.surface = 0.49
	# The Shred Shack (a little skate shop in a shed)
	var sh := CivicBuilder._usable(c, "shred_shack", "Shred Shack", "skate_shop", Vector3(84.2, 0, 40.0), -90)
	Props.part(sh, Vector3(2.2, 1.0, 0.7), Vector3(0, 0.5, 0), Color("2B2B30"))
	Props.part(sh, Vector3(2.3, 0.05, 0.8), Vector3(0, 1.025, 0), Color("C0322A"))
	Props.part(sh, Vector3(2.2, 2.4, 0.1), Vector3(0, 1.2, -1.1), Color("2B2B30"))
	Props.part(sh, Vector3(2.4, 0.1, 1.6), Vector3(0, 2.45, -0.45), Color("C0322A"))
	for k in 3:
		var deck := Props.part(sh, Vector3(0.22, 0.8, 0.03), Vector3(-0.6 + k * 0.6, 1.6, -1.035), [Color("F7D046"), Color("4FC8FF"), Color("FF4FD8")][k], null, false)
		deck.rotation.z = 0.15
	CivicBuilder._label(sh, "SHRED SHACK", Vector3(0, 2.45, 0.36), 0.0, Palette.PAPER, 0.0035, 48)
	Props.finish(sh, solids, Vector3(2.2, 1.05, 0.7), Vector3(0, 0, 0.9), null, Vector3(0, 1.1, 0))
	(solids as Array).pop_back()
	solids.append(Rect2(84.2 - 1.3, 40.0 - 1.1, 1.9, 2.2))
	sh.activities.append(Catalog.buy_activity("skateboard", Vector2(11.0, 20.0)))
	_act(sh, "Look at the Skateboards", 10, {"fun": 18.0}, "stand", ["The one with the flaming skull. Obviously."], 0.0, Vector2(11.0, 20.0))
	_worker(c, "skate_shop", "Mohawk Mike", Vector3(84.9, 0, 40.0), -90.0,
		{"gender": "boy", "hair": "mohawk", "hair_color": 3, "skin": 0, "adult": true, "top_style": "leather",
		"top": Color("1E1C22"), "stripe": Color("C8CCD0"), "pants": Color("2B2B30"), "shoes": Color("141414")},
		["Skating's not a crime, little dude.", "Wax the coping, not the deck. Rookie mistake.", "That half-pipe? I built it. Well, I helped. I held the hammer.",
		"Thirty-five bucks gets you a board AND my respect."], Vector2(11.0, 20.0), Vector3(84.0, 0, 44.6), "")
	# Where the punks and the boombox kids hang out (TownFolk)
	c["out"]["skate_route"] = [Vector3(76.2, 0, 39.8), Vector3(80.8, 0, 37.0), Vector3(81.0, 0, 30.4), Vector3(76.0, 0, 29.8), Vector3(76.2, 0, 36.6)]
	c["out"]["skate_spots"] = [Vector3(71.5, 0, 34.5), Vector3(78.5, 0, 31.8), Vector3(81.4, 0, 33.0)]


# ================================================================ Rocket Burger (with a drive-thru)

static func _burger(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var r := BURGER
	# The lot (with the building cut out)
	var holes: Array[Rect2] = [r.grow(0.1)]
	for piece in OutdoorBuilder.rect_minus(BURGER_LOT, holes):
		OutdoorBuilder._slab(root, piece, Color("55545A"), tex["asphalt"], 0.003)
	# painted arrows along the drive-thru lane
	for p in [[Vector3(DT_IN_X, 0, 40.0), 0.0], [Vector3(DT_IN_X, 0, 33.0), 0.0], [Vector3(98.0, 0, DT_BACK_Z), 90.0], [Vector3(DT_OUT_X, 0, 40.5), 180.0]]:
		var g := Node3D.new()
		g.position = p[0] + Vector3(0, 0.009, 0)
		g.rotation_degrees.y = p[1]
		root.add_child(g)
		RoomBuilder.box(g, Vector3(0.18, 0.01, 1.2), Vector3(0, 0, 0.3), Palette.PAPER)
		var h1 := RoomBuilder.box(g, Vector3(0.16, 0.01, 0.7), Vector3(-0.2, 0, -0.42), Palette.PAPER)
		h1.rotation.y = -0.7
		var h2 := RoomBuilder.box(g, Vector3(0.16, 0.01, 0.7), Vector3(0.2, 0, -0.42), Palette.PAPER)
		h2.rotation.y = 0.7
	CivicBuilder._label(root, "DRIVE\nTHRU", Vector3(DT_IN_X, 0.015, 42.6), 0.0, Palette.PAPER, 0.008, 64).rotation_degrees = Vector3(-90, 0, 0)
	var b := CivicBuilder._building(c, "burger", "Rocket Burger", r, 3.6, 1.0, 97.0, Color("F2EEE2"), "kitchen",
		Color("E8E2D6"), "siding", Color.WHITE, "lino", [], true, Color("C0322A"), DowntownBuilder.Z0 - 1.6)
	CivicBuilder._windows(c, b["front"], [93.6, 100.4], 1.55, 2.6, 1.4, r.end.y, 1.0)
	CivicBuilder._room(c, "Rocket Burger", r)
	# A red-and-white stripe and the rocket sign on the roof
	for k in 4:
		var st := RoomBuilder.box(root, Vector3(r.size.x + 0.62, 0.18, r.size.y + 0.62), Vector3(r.get_center().x, 3.95 + k * 0.2, r.get_center().y), Color("C0322A") if k % 2 == 0 else Palette.PAPER)
		(c["out"]["ceilings"] as Array).append(st)
	var rk := Node3D.new()
	rk.position = Vector3(r.get_center().x, 4.7, r.get_center().y)
	root.add_child(rk)
	(c["out"]["ceilings"] as Array).append(rk)
	RoomBuilder.box(rk, Vector3(0.8, 3.0, 0.8), Vector3(0, 1.5, 0), Palette.PAPER)
	RoomBuilder.box(rk, Vector3(0.5, 0.8, 0.5), Vector3(0, 3.4, 0), Color("C0322A"))
	for sx in [-1.0, 1.0]:
		RoomBuilder.box(rk, Vector3(0.5, 0.9, 0.12), Vector3(sx * 0.6, 0.5, 0), Color("C0322A"))
	var rs := CivicBuilder._label(rk, "ROCKET BURGER", Vector3(0, 1.5, 0.43), 0.0, Color("C0322A"), 0.005, 72)
	rs.outline_size = 10
	rs.outline_modulate = Palette.PAPER
	var rs2 := CivicBuilder._label(rk, "ROCKET BURGER", Vector3(0, 1.5, -0.43), 180.0, Color("C0322A"), 0.005, 72)
	rs2.outline_size = 10
	rs2.outline_modulate = Palette.PAPER
	# The drive-thru window (west side), the menu board and the speaker
	var ww := RoomBuilder.box(root, Vector3(0.06, 1.0, 1.2), Vector3(r.position.x - 0.12, 1.3, DT_WINDOW.z), Color("9FC4CC"))
	ww.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shelf := RoomBuilder.box(root, Vector3(0.36, 0.05, 1.3), Vector3(r.position.x - 0.26, 0.78, DT_WINDOW.z), Color("5A5E63"))
	shelf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	CivicBuilder._label(root, "PAY HERE", Vector3(r.position.x - 0.16, 2.0, DT_WINDOW.z), -90.0, Color("C0322A"), 0.004, 48)
	var mb := Props.solid(root, Vector3(DT_OUT_X + 1.55, 0, DT_MENU.z - 0.4), -90)
	RoomBuilder.box(mb, Vector3(1.6, 1.4, 0.16), Vector3(0, 1.5, 0), Color("2B2B30"))
	RoomBuilder.box(mb, Vector3(0.12, 0.85, 0.12), Vector3(-0.5, 0.42, 0), Color("5A5E63"))
	RoomBuilder.box(mb, Vector3(0.12, 0.85, 0.12), Vector3(0.5, 0.42, 0), Color("5A5E63"))
	CivicBuilder._label(mb, "BURGER .99\nFRIES .69\nSHAKE .89\nROCKET MEAL 2.49", Vector3(0, 1.5, 0.095), 0.0, Color("F7D046"), 0.003, 44)
	Props.finish(mb, solids, Vector3(1.6, 2.2, 0.2), Vector3.ZERO)
	var spk := Props.solid(root, Vector3(DT_OUT_X + 1.3, 0, DT_MENU.z + 0.9), -90)
	RoomBuilder.box(spk, Vector3(0.1, 1.0, 0.1), Vector3(0, 0.5, 0), Color("5A5E63"))
	RoomBuilder.box(spk, Vector3(0.36, 0.42, 0.2), Vector3(0, 1.2, 0), Color("C0322A"))
	Props.finish(spk, solids, Vector3(0.36, 1.4, 0.2), Vector3.ZERO)
	# Inside: the counter, the grill, booths
	var ct := CivicBuilder._usable(c, "burger_counter", "Rocket Burger Counter", "food_counter", Vector3(97.0, 0, 33.6), 0)
	Props.part(ct, Vector3(5.0, 1.0, 0.7), Vector3(0, 0.5, 0), Color("C0322A"))
	Props.part(ct, Vector3(5.06, 0.05, 0.76), Vector3(0, 1.025, 0), Color("F2F0E6"))
	Props.part(ct, Vector3(0.36, 0.22, 0.3), Vector3(1.8, 1.16, 0.0), Color("4A4A52"), null, false)
	Props.finish(ct, solids, Vector3(5.0, 1.05, 0.7), Vector3(0, 0, 1.1), null, Vector3(0, 1.1, 0))
	var hrs := Vector2(7.0, 23.0)
	for f in [["Buy a Rocket Burger", 0.99, 200.0, 20.0], ["Buy a Rocket Meal (Burger, Fries & Shake)", 2.49, 320.0, 34.0],
			["Buy Fries", 0.69, 100.0, 16.0], ["Buy a Chocolate Shake", 0.89, 70.0, 30.0]]:
		var fa := _act(ct, f[0], 20, {"hunger": float(f[2]), "fun": float(f[3])}, "stand",
			["You find a toy rocket in your meal!", "Hot, salty, perfect.", "Brain freeze! Worth it."], -float(f[1]), hrs)
		if f[0].begins_with("Buy a Rocket Meal"):
			fa.memory_id = "burger"
	var grill := Props.solid(root, Vector3(97.0, 0, r.position.y + T / 2.0 + 0.4), 0)
	RoomBuilder.box(grill, Vector3(3.2, 0.9, 0.7), Vector3(0, 0.45, 0), Color("C8CCD0"))
	RoomBuilder.box(grill, Vector3(1.4, 0.04, 0.6), Vector3(-0.6, 0.92, 0), Color("2B2B30"))
	RoomBuilder.box(grill, Vector3(0.9, 0.3, 0.5), Vector3(1.0, 1.05, 0), Color("B8B8B0"))   # the fryer
	Props.finish(grill, solids, Vector3(3.2, 0.95, 0.7), Vector3.ZERO)
	var menu := RoomBuilder.box(root, Vector3(4.0, 1.0, 0.04), Vector3(97.0, 2.5, r.position.y + T / 2.0 + 0.03), Color("2B2B30"))
	menu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	CivicBuilder._label(root, "ROCKET BURGER .99   ROCKET MEAL 2.49\nFRIES .69   SHAKE .89", Vector3(97.0, 2.5, r.position.y + T / 2.0 + 0.06), 0.0, Color("F7D046"), 0.003, 44)
	for bx in [92.6, 101.4]:
		var bt := CivicBuilder._usable(c, "burger_booth_%d" % int(bx), "Booth", "fc_table", Vector3(bx, 0, 36.6), 90 if bx < 97 else -90)
		Props.part(bt, Vector3(1.2, 0.05, 0.8), Vector3(0, 0.74, 0), Palette.PAPER)
		Props.part(bt, Vector3(0.1, 0.72, 0.1), Vector3(0, 0.36, 0), Palette.INK2, null, false)
		for sz in [-0.75, 0.75]:
			Props.part(bt, Vector3(1.2, 0.45, 0.45), Vector3(0, 0.225, sz), Color("C0322A"), null, false)
			Props.part(bt, Vector3(1.2, 0.5, 0.12), Vector3(0, 0.72, sz + signf(sz) * 0.17), Color("C0322A"), null, false)
		Props.finish(bt, solids, Vector3(1.2, 0.95, 2.0), Vector3(0, 0, 1.6), Vector3(0, 0, 0.75), Vector3(0, 0.8, 0))
		var s := _act(bt, "Sit in a Booth", 30, {"social": 26.0, "energy": 10.0}, "sit", ["The jukebox is playing something with a saxophone solo."])
		s.surface = 0.45
	var pc := {"root": root, "objects": c["objects"], "solids": solids, "home": "town", "level": 0}
	PayPhones.add(pc, "payphone_burger", Vector3(r.end.x - T / 2.0, 0, 38.1), -90.0, hrs)
	_worker(c, "burger_cook", "Rocket Ray", Vector3(97.6, 0, 32.75), 0.0,
		{"gender": "boy", "hair": "cap", "hair_color": 2, "skin": 3, "adult": true, "top_style": "plain",
		"top": Palette.PAPER, "pants": Color("C0322A"), "shoes": Palette.INK},
		["Welcome to Rocket Burger, can I take your order? ...Out of this world, right?", "The shake machine works today! Big day.",
		"Drive-thru's been nuts. Everybody wants a Rocket Meal.", "Would you like to Rocket-size that?"],
		Vector2(6.6, 23.2), Vector3(97.0, 0, r.end.y + 1.2), "burger")
	DowntownBuilder._register_door(c["out"], "burger", "Rocket Burger", r, hrs, [])
	# a parked car or two out front
	c["out"]["burger_parking"] = [Vector3(93.4, 0, 41.8), Vector3(101.0, 0, 41.8)]


# ================================================================ Strike Zone Lanes (bowling)

static func _bowling(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var r := BOWLING
	var hrs := Vector2(10.0, 24.0)
	var b := CivicBuilder._building(c, "bowling", "Strike Zone Lanes", r, 4.0, 1.0, 126.0, Color("2A2440"), "panel",
		Color("3A3060"), "brick", Color("3A3060"), "carpet", [], true, Color("2E5E9E"), DowntownBuilder.Z0 - 1.6)
	CivicBuilder._sign(c, b["front"], 121.0, 3.3, r.end.y, 1.0, "STRIKE ZONE LANES", Color("1A1C3A"), Color("FF4FD8"), 8.0, 80)
	CivicBuilder._windows(c, b["front"], [128.8], 1.6, 1.6, 1.4, r.end.y, 1.0)
	CivicBuilder._room(c, "Strike Zone Lanes", r)
	DowntownBuilder._register_door(c["out"], "bowling", "Strike Zone Lanes", r, hrs, [])
	var lanes := BowlingLanes.new()
	lanes.name = "BowlingLanes"
	root.add_child(lanes)
	c["out"]["bowling_lanes"] = lanes
	var wood := Color("D8B078")
	# The pinsetter wall across the back, with the name on it
	var back := RoomBuilder.box(root, Vector3(11.0, 1.6, 0.8), Vector3(117.2, 2.4, r.position.y + T / 2.0 + 0.42), Color("1A1C3A"))
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	CivicBuilder._label(root, "★ STRIKE ZONE ★", Vector3(117.2, 2.4, r.position.y + T / 2.0 + 0.83), 0.0, Color("FF4FD8"), 0.006, 72)
	for i in BOWL_LANES.size():
		var x: float = BOWL_LANES[i]
		OutdoorBuilder._slab(root, Rect2(x - 0.53, PIN_Z - 0.8, 1.06, FOUL_Z - PIN_Z + 0.8), wood, null, 0.03)
		for gx in [-0.66, 0.66]:
			OutdoorBuilder._slab(root, Rect2(x + gx - 0.12, PIN_Z - 0.8, 0.24, FOUL_Z - PIN_Z + 0.8), Color("2B2B30"), null, 0.012)
		OutdoorBuilder._slab(root, Rect2(x - 0.8, FOUL_Z, 1.6, 2.0), wood.lightened(0.1), null, 0.02)         # the approach
		OutdoorBuilder._slab(root, Rect2(x - 0.78, FOUL_Z - 0.03, 1.56, 0.06), Color("C0322A"), null, 0.024)  # the foul line
		# the lane is one usable thing: walk up to the approach and bowl
		var o := CivicBuilder._usable(c, "bowling_lane_%d" % (i + 1), "Lane %d" % (i + 1), "bowling_lane", Vector3(x + 0.95, 0, FOUL_Z + 1.1), 180)
		Props.part(o, Vector3(0.36, 0.5, 0.9), Vector3(0, 0.25, 0), Color("2B2B30"))           # the ball return
		for k in 3:
			Props.part(o, Vector3(0.2, 0.2, 0.2), Vector3(0, 0.6, -0.3 + k * 0.3), [Color("C0322A"), Color("2E5E9E"), Color("2EB86A")][k], null, false)
		Props.finish(o, solids, Vector3(0.36, 0.7, 0.9), Vector3(-0.95, 0, -0.6), null, Vector3(-0.95, 0.3, 8.0))
		o.approach_point = Vector3(x, 0, FOUL_Z + 1.6)
		o.use_point = Vector3(x, 0, FOUL_Z + 0.9)
		o.look_point = Vector3(x, 0.3, PIN_Z)
		o.set_meta("lane", i)
		var a := _act(o, "Bowl a Game", 45, {"fun": 64.0, "social": 24.0, "energy": -8.0}, "bowl",
			["You bowled a 96! Two gutter balls, but who's counting.", "STRIKE! You do a little dance.", "You bowled a 142! Personal best!",
			"Spare! Then a split. Then another split. 118.", "Your ball goes in the gutter. And the next. Bumpers next time?"], -1.50, hrs)
		a.memory_id = "bowling"
		a.loop_sound = "bowling"
		a.loop_db = -10.0
		lanes.add_lane(x, FOUL_Z, PIN_Z)
		# the bench and the scoring table behind each lane
		var bench := Props.solid(root, Vector3(x, 0, FOUL_Z + 3.0), 0)
		RoomBuilder.box(bench, Vector3(1.4, 0.45, 0.5), Vector3(0, 0.225, 0), Color("FF4FD8").darkened(0.3))
		RoomBuilder.box(bench, Vector3(1.4, 0.4, 0.1), Vector3(0, 0.65, 0.2), Color("FF4FD8").darkened(0.3))
		Props.finish(bench, solids, Vector3(1.4, 0.85, 0.55), Vector3.ZERO)
		var score := RoomBuilder.box(root, Vector3(0.8, 0.5, 0.06), Vector3(x, 3.0, FOUL_Z - 0.4), Color("1A1C3A"))
		score.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		CivicBuilder._label(root, "LANE %d" % (i + 1), Vector3(x, 3.0, FOUL_Z - 0.36), 0.0, Color("4FD84F"), 0.003, 48)
	# Lane dividers
	for k in BOWL_LANES.size() + 1:
		var dx: float = BOWL_LANES[0] - 1.2 + k * 2.4
		var dv := Props.solid(root, Vector3(dx, 0, (PIN_Z + FOUL_Z) / 2.0 - 0.4), 0)
		RoomBuilder.box(dv, Vector3(0.12, 0.2, FOUL_Z - PIN_Z + 0.8), Vector3(0, 0.1, 0), Color("4A3A2E"))
		Props.finish(dv, solids, Vector3(0.12, 0.2, FOUL_Z - PIN_Z + 0.8), Vector3.ZERO)
	# The lanes area is off limits (except the approach): no walking down the lane
	solids.append(Rect2(BOWL_LANES[0] - 1.2, r.position.y + T, 2.4 * BOWL_LANES.size(), FOUL_Z - r.position.y - T))
	# The front desk (shoe rental), the snack bar, an arcade cabinet
	var desk := CivicBuilder._usable(c, "bowling_desk", "Shoe Rental", "bowling_desk", Vector3(127.6, 0, 40.0), -90)
	Props.part(desk, Vector3(2.4, 1.05, 0.7), Vector3(0, 0.525, 0), Color("2E5E9E"))
	Props.part(desk, Vector3(2.46, 0.05, 0.76), Vector3(0, 1.075, 0), Palette.WOOD_DARK)
	for k in 4:
		Props.part(desk, Vector3(0.3, 0.14, 0.18), Vector3(-0.8 + k * 0.5, 1.17, 0.05), [Color("C0322A"), Color("2E5E9E")][k % 2], null, false)
	Props.finish(desk, solids, Vector3(2.4, 1.1, 0.7), Vector3(0, 0, 1.0), null, Vector3(0, 1.1, 0))
	_act(desk, "Rent Bowling Shoes", 3, {"fun": 8.0}, "reach", ["Size 5. They're red and blue and smell like a gym bag. Perfect."], -0.50, hrs)
	_act(desk, "Ask About Leagues", 5, {"social": 18.0}, "stand", ["\"Tuesday nights, Thunder Alley league. We could use a ringer, kid.\""], 0.0, hrs)
	var snack := CivicBuilder._usable(c, "bowling_snack", "Snack Bar", "food_counter", Vector3(127.6, 0, 33.0), -90)
	Props.part(snack, Vector3(3.0, 1.05, 0.7), Vector3(0, 0.525, 0), Color("C0322A"))
	Props.part(snack, Vector3(3.06, 0.05, 0.76), Vector3(0, 1.075, 0), Palette.PAPER)
	Props.part(snack, Vector3(0.5, 0.5, 0.4), Vector3(-1.0, 1.35, -0.05), Color("F7D046"), null, false)    # a popcorn machine
	Props.finish(snack, solids, Vector3(3.0, 1.1, 0.7), Vector3(0, 0, 1.0), null, Vector3(0, 1.1, 0))
	for f in [["Buy a Hot Dog", 0.75, 160.0, 14.0], ["Buy a Basket of Nachos", 1.25, 140.0, 24.0], ["Buy a Root Beer Float", 0.85, 60.0, 30.0]]:
		_act(snack, f[0], 15, {"hunger": float(f[2]), "fun": float(f[3])}, "stand", ["Bowling alley food. It just hits different."], -float(f[1]), hrs)
	var arc := CivicBuilder._usable(c, "bowling_arcade", "Pinball Machine", "pinball", Vector3(130.2, 0, 36.6), -90)
	Props.part(arc, Vector3(0.7, 0.9, 1.3), Vector3(0, 0.45, 0), Color("1A1C3A"))
	var glass := Props.part(arc, Vector3(0.62, 0.04, 1.2), Vector3(0, 0.93, 0), Color("FF4FD8"), null, false)
	(glass.material_override as StandardMaterial3D).emission_enabled = true
	(glass.material_override as StandardMaterial3D).emission = Color("FF4FD8")
	Props.part(arc, Vector3(0.7, 0.9, 0.12), Vector3(0, 1.35, -0.6), Color("2E5E9E"), null, false)
	Props.finish(arc, solids, Vector3(0.7, 1.8, 1.3), Vector3(0, 0, 1.1), null, Vector3(0, 1.0, 0))
	var pa := _act(arc, "Play Pinball", 15, {"fun": 44.0}, "reach", ["TILT! You nudged it too hard.", "Multiball! MULTIBALL!"], -0.25, hrs)
	pa.loop_sound = "arcade_game"
	pa.loop_db = -14.0
	var pc := {"root": root, "objects": c["objects"], "solids": solids, "home": "town", "level": 0}
	PayPhones.add(pc, "payphone_bowling", Vector3(r.end.x - T / 2.0, 0, 41.6), -90.0, hrs)
	_worker(c, "bowling_desk", "Big Earl", Vector3(128.4, 0, 40.0), -90.0,
		{"gender": "boy", "hair": "feathered", "hair_color": 1, "skin": 1, "adult": true, "top_style": "plain",
		"top": Color("2E5E9E"), "pants": Color("2B2B30"), "shoes": Color("C0322A")},
		["Shoes are fifty cents. Socks are your problem.", "I bowled a 300 once. In 1971. Ask anybody.", "Lane 3 pulls left. Don't tell the league.",
		"Cosmic bowling on Fridays! Okay, it's just the lights off."], Vector2(9.7, 24.0), Vector3(126.0, 0, r.end.y + 1.2), "bowling")


# ================================================================ the fairgrounds

static func _fairgrounds(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var f := FAIR
	OutdoorBuilder._slab(root, f, Color("C8B48A"), tex["concrete"], 0.004)
	# the entrance arch from Maple Street
	var ax := f.get_center().x
	for px in [ax - 3.4, ax + 3.4]:
		var post := Props.solid(root, Vector3(px, 0, f.end.y + 0.6), 0)
		RoomBuilder.box(post, Vector3(0.3, 4.2, 0.3), Vector3(0, 2.1, 0), Color("C0322A"))
		Props.finish(post, solids, Vector3(0.3, 4.2, 0.3), Vector3.ZERO)
	var arch := RoomBuilder.box(root, Vector3(7.4, 0.9, 0.2), Vector3(ax, 4.0, f.end.y + 0.6), Color("F7D046"))
	arch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	CivicBuilder._label(root, "MAPLE GROVE FAIRGROUNDS", Vector3(ax, 4.0, f.end.y + 0.715), 0.0, Color("C0322A"), 0.0045, 64)
	CivicBuilder._label(root, "MAPLE GROVE FAIRGROUNDS", Vector3(ax, 4.0, f.end.y + 0.485), 180.0, Color("C0322A"), 0.0045, 64)
	OutdoorBuilder._slab(root, Rect2(ax - 3.0, f.end.y, 6.0, 14.0 - f.end.y), Color("CFC8BA"), tex["concrete"], 0.006)
	# a notice board: what's coming
	var nb := CivicBuilder._usable(c, "fair_board", "Fairgrounds Sign", "fair_board", Vector3(ax + 5.4, 0, f.end.y + 0.7), 0)
	Props.part(nb, Vector3(1.6, 1.1, 0.08), Vector3(0, 1.4, 0), Palette.WOOD)
	Props.part(nb, Vector3(1.4, 0.9, 0.012), Vector3(0, 1.4, 0.046), Palette.PAPER, null, false)
	for px in [-0.7, 0.7]:
		Props.part(nb, Vector3(0.08, 0.9, 0.06), Vector3(px, 0.45, 0), Palette.WOOD_DARK, null, false)
	Props.finish(nb, solids, Vector3(1.6, 1.9, 0.2), Vector3(0, 0, 0.8), null, Vector3(0, 1.4, 0))
	var l := CivicBuilder._label(nb, "COMING SOON", Vector3(0, 1.4, 0.06), 0.0, Palette.INK, 0.0028, 40)
	c["out"]["fair_board_label"] = l
	_act(nb, "Read the Sign", 2, {"fun": 4.0}, "stand", ["The carnival and the circus set up here when they come to town."])
	# picnic tables
	for p in [Vector3(92.6, 0, -5.0), Vector3(127.6, 0, -5.0)]:
		OutdoorBuilder._picnic_table(root, solids, p, tex)
	c["out"]["fairgrounds"] = f


# ================================================================ the mall parking lot

static func _parking(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var p := LOT
	OutdoorBuilder._slab(root, p, Color("55545A"), tex["asphalt"], 0.003)
	# the driveway across the sidewalk
	OutdoorBuilder._slab(root, Rect2(121.0, DowntownBuilder.Z1, 6.0, p.position.y - DowntownBuilder.Z1), Color("C4BDB0"), tex["concrete"], 0.011)
	for row in [[p.position.x + 0.2, 1.0], [p.end.x - 5.2, -1.0]]:
		for k in 9:
			var z := p.position.y + 4.0 + k * 2.8
			OutdoorBuilder._slab(root, Rect2(row[0], z - 0.05, 5.0, 0.1), Palette.PAPER, null, 0.008)
	c["out"]["mall_spots"] = []
	for k in 8:
		var z := p.position.y + 5.4 + k * 2.8
		(c["out"]["mall_spots"] as Array).append([Vector3(p.position.x + 2.7, 0, z), 90.0])
		(c["out"]["mall_spots"] as Array).append([Vector3(p.end.x - 2.7, 0, z), -90.0])
	for z in [66.0, 80.0]:
		var lp := Props.solid(root, Vector3(p.get_center().x, 0, z), 0)
		RoomBuilder.box(lp, Vector3(0.18, 6.0, 0.18), Vector3(0, 3.0, 0), Color("5A5E63"))
		var hm: StandardMaterial3D
		for sx in [-1.0, 1.0]:
			var hd := RoomBuilder.box(lp, Vector3(0.7, 0.16, 0.4), Vector3(sx * 0.5, 5.9, 0), Palette.LAMP)
			hm = hd.material_override
			hm.emission_enabled = true
			hm.emission = Color("FFD9A0")
		Props.finish(lp, solids, Vector3(0.3, 6.0, 0.3), Vector3.ZERO)
		var ol := OutdoorBuilder._omni(root, Vector3(p.get_center().x, 5.6, z), Color("FFC982"), 14.0)
		RoomBuilder.add_lamp(c["out"], ol, hm, 0.0, 3.0)


# ================================================================ trees in the open spaces

static func _trees(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var solids: Array[Rect2] = c["solids"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1987
	# where they may go, and what to keep clear
	var areas := [Rect2(86.0, -68.0, 44.0, 56.0), Rect2(-20.0, 68.5, 92.0, 22.0), Rect2(84.0, 18.0, 4.0, 6.0), Rect2(116.0, 89.0, 14.0, 2.0)]
	var keep: Array[Rect2] = [FAIR.grow(2.0), LOT.grow(1.5), MallBuilder.M.grow(2.0), Rect2(OutdoorBuilder.OAK_X0 - 3.0, -100, 12.0, 200),
		CivicBuilder.FIELD.grow(3.0), Rect2(36.0, -46.0, 4.0, 60.0),
		# (v1.7: Lincoln Avenue runs out here now, past the middle school and the high school)
		Rect2(80.0, CivicBuilder.Z0 - 3.5, 70.0, CivicBuilder.Z1 - CivicBuilder.Z0 + 7.0), SchoolBuilder.MIDDLE.grow(3.0), SchoolBuilder.HIGH.grow(3.5)]
	for k in NeighborBuilder.HOMES:
		keep.append((NeighborBuilder.HOMES[k]["r"] as Rect2).grow(6.0))
	var placed: Array[Vector2] = []
	for area: Rect2 in areas:
		var want := int(area.get_area() / 70.0)
		var tries := 0
		while want > 0 and tries < 600:
			tries += 1
			var p := Vector2(rng.randf_range(area.position.x + 1.5, area.end.x - 1.5), rng.randf_range(area.position.y + 1.5, area.end.y - 1.5))
			var ok := true
			for kr in keep:
				if kr.has_point(p):
					ok = false
			for q in placed:
				if q.distance_to(p) < 5.5:
					ok = false
			if not ok:
				continue
			placed.append(p)
			OutdoorBuilder._tree(root, solids, Vector3(p.x, 0, p.y), rng.randf_range(0.75, 1.1))
			want -= 1
