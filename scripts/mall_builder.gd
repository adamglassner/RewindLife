class_name MallBuilder
extends RefCounted
## The Maple Grove Mall, at the east end of Main Street (open 10 AM - 9 PM). One big building: walk in the glass doors and the
## concourse runs straight back to the food court, with two stores on each side.
##
##   z = 56  ===== front (Main Street) ======= [doors x = 94] ==================
##           [TREND SETTERS clothes]  |  concourse  |  [SPIN CITY RECORDS]
##   z = 66  [TOY BOX toys]           |  fountain   |  [CIRCUIT HUT electronics]
##   z = 76  ------------------------ +             + -------------------------
##           FOOD COURT: tables, payphones
##   z = 90  [Slice of Napoli] [Taco Loco] [Golden Dragon Wok] [Cluck Shack]
##           x 74 ............................................................ 114
##
## Everything you can buy here is listed in catalog.gd (and the clothes in looks.gd).

const M := Rect2(74.0, 56.0, 40.0, 34.0)
const HGT := 4.4
const DOOR_X := 94.0
const T := 0.15
const HOURS := Vector2(10.0, 21.0)

const CLOTHES := Rect2(74.0, 56.0, 14.0, 10.0)
const TOYS := Rect2(74.0, 66.0, 14.0, 10.0)
const MUSIC := Rect2(100.0, 56.0, 14.0, 10.0)
const COMPUTERS := Rect2(100.0, 66.0, 14.0, 10.0)
const CONCOURSE := Rect2(88.0, 56.0, 12.0, 20.0)
const FOOD := Rect2(74.0, 76.0, 40.0, 14.0)

const FOOD_PLACES := [
	# key, title, sign color, x, foods [title, price, hunger, extra fun]
	["napoli", "SLICE OF NAPOLI", Color("C0322A"), 79.0, [["Buy a Pepperoni Slice", 1.50, 160.0, 20.0], ["Buy a Calzone", 2.75, 260.0, 20.0]]],
	["taco", "TACO LOCO", Color("E4892E"), 89.0, [["Buy Two Tacos", 1.75, 180.0, 20.0], ["Buy a Burrito Grande", 2.50, 260.0, 24.0], ["Buy Nachos with Cheese", 1.25, 120.0, 30.0]]],
	["wok", "GOLDEN DRAGON WOK", Color("2E8C5A"), 99.0, [["Buy Orange Chicken & Rice", 2.75, 260.0, 20.0], ["Buy an Egg Roll", 0.75, 80.0, 14.0], ["Try a Free Sample", 0.0, 20.0, 16.0]]],
	["cluck", "CLUCK SHACK", Color("F2C230"), 109.0, [["Buy a Bucket of Chicken Strips", 2.25, 220.0, 20.0], ["Buy a Biscuit & Honey", 0.75, 90.0, 12.0], ["Buy a Lemonade", 0.75, 30.0, 16.0]]],
]


static func rects() -> Array[Rect2]:
	return [M]


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2]) -> void:
	var c := {"root": root, "out": out, "tex": tex, "solids": solids, "free": free, "doorways": doorways,
		"buildings": buildings, "objects": out["objects"], "home": "town", "level": 0, "x0": 0.0}
	var b := CivicBuilder._building(c, "mall", "Maple Grove Mall", M, HGT, -1.0, DOOR_X, Color("F2ECDD"), "hall",
		Color("D8C0A0"), "brick", Color("EDE6D6"), "lino", [], true, Color("6A8AA8"), DowntownBuilder.Z1 + 1.6)
	_front(c, b)
	_inside_walls(c)
	_clothes(c)
	_toys(c)
	_music(c)
	_computers(c)
	_concourse(c)
	_food_court(c)
	# The doors: open 10-9 (Sundays 12-6)
	DowntownBuilder._register_door(out, "mall", "The Maple Grove Mall", M, HOURS, [])


# ================================================================ the outside

static func _front(c: Dictionary, b: Dictionary) -> void:
	var root: Node3D = c["root"]
	var fw: Dictionary = b["front"]
	var fz := M.position.y
	# Shop windows for the four stores
	CivicBuilder._windows(c, fw, [77.5, 84.5, 103.5, 110.5], 1.7, 2.6, 1.8, fz, -1.0)
	# Glass panels either side of the doors
	for gx in [92.2, 95.8]:
		RoomBuilder.add_ext_window(fw["full"], Vector3(gx, 1.5, fz - 0.125), Vector3(1.4, 2.2, 0.04), c["out"])
	# A tall entrance frame around the doors, with the sign on top
	var tan := Color("C8A880")
	for px in [DOOR_X - 3.1, DOOR_X + 3.1]:
		var p := Props.solid(root, Vector3(px, 0, fz - 0.55), 0)
		RoomBuilder.box(p, Vector3(0.8, 6.6, 0.8), Vector3(0, 3.3, 0), tan)
		Props.finish(p, c["solids"], Vector3(0.8, 6.6, 0.8), Vector3.ZERO)
	var lintel := RoomBuilder.box(root, Vector3(7.04, 1.66, 0.9), Vector3(DOOR_X, 5.75, fz - 0.55), tan.darkened(0.08))
	lintel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	(c["out"]["ceilings"] as Array).append(lintel)
	var sign := CivicBuilder._label(root, "MAPLE GROVE MALL", Vector3(DOOR_X, 5.8, fz - 0.985), 180.0, Color("E85A7A"), 0.0055, 96)
	sign.outline_size = 12
	sign.outline_modulate = Palette.PAPER
	(c["out"]["ceilings"] as Array).append(sign)
	var banner := RoomBuilder.box(fw["full"], Vector3(4.2, 0.5, 0.02), Vector3(DOOR_X, 3.25, fz - 0.21), Color("F7D046"))
	banner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	CivicBuilder._label(fw["full"], "NOW OPEN! 10 AM - 9 PM", Vector3(DOOR_X, 3.25, fz - 0.225), 180.0, Color("C0322A"), 0.0042, 56)
	# Shop signs on the front, over each store's windows
	for s in [["TREND SETTERS", 81.0, Color("F2509A")], ["SPIN CITY", 107.0, Color("4FC8FF")]]:
		CivicBuilder._label(fw["full"], s[0], Vector3(s[1], 3.35, fz - 0.21), 180.0, s[2], 0.004, 64)
	# Planters and a bench out front
	for x in [80.0, 108.0]:
		var pl := Props.solid(root, Vector3(x, 0, fz - 1.2), 0)
		RoomBuilder.box(pl, Vector3(2.4, 0.5, 0.8), Vector3(0, 0.25, 0), Color("B8A890"))
		RoomBuilder.box(pl, Vector3(2.2, 0.06, 0.6), Vector3(0, 0.52, 0), Color("4A3020"))
		for i in 4:
			RoomBuilder.box(pl, Vector3(0.36, 0.4, 0.36), Vector3(-0.8 + i * 0.53, 0.75, 0), OutdoorBuilder.GREENS[i % 4])
		Props.finish(pl, c["solids"], Vector3(2.4, 0.5, 0.8), Vector3.ZERO)


# ================================================================ inside walls

static func _inside_walls(c: Dictionary) -> void:
	var wall := Color("F2ECDD")
	var x0 := M.position.x + T / 2.0
	var x1 := M.end.x - T / 2.0
	# the storefronts face the concourse, with a wide opening each
	CivicBuilder._partition(c, "mallWestFront", false, CONCOURSE.position.x, M.position.y + T / 2.0, FOOD.position.y,
		[[61.0, 5.0, 3.2], [71.0, 5.0, 3.2]], HGT, wall, "hall")
	CivicBuilder._partition(c, "mallEastFront", false, CONCOURSE.end.x, M.position.y + T / 2.0, FOOD.position.y,
		[[61.0, 5.0, 3.2], [71.0, 5.0, 3.2]], HGT, wall, "hall")
	CivicBuilder._partition(c, "mallWestMid", true, 66.0, x0, CONCOURSE.position.x, [], HGT, wall, "hall")
	CivicBuilder._partition(c, "mallEastMid", true, 66.0, CONCOURSE.end.x, x1, [], HGT, wall, "hall")
	CivicBuilder._partition(c, "mallWestBack", true, FOOD.position.y, x0, CONCOURSE.position.x, [], HGT, wall, "hall")
	CivicBuilder._partition(c, "mallEastBack", true, FOOD.position.y, CONCOURSE.end.x, x1, [], HGT, wall, "hall")
	CivicBuilder._room(c, "Trend Setters", CLOTHES)
	CivicBuilder._room(c, "Toy Box", TOYS)
	CivicBuilder._room(c, "Spin City Records", MUSIC)
	CivicBuilder._room(c, "Circuit Hut", COMPUTERS)
	CivicBuilder._room(c, "Food Court", FOOD)
	(c["free"] as Array).append(CONCOURSE.grow(-T / 2.0))
	# the concourse runs straight into the food court
	(c["doorways"] as Array).append(Rect2(CONCOURSE.position.x + 0.2, FOOD.position.y - 0.6, CONCOURSE.size.x - 0.4, 1.2))
	# Floors: carpet in the stores (a hair above the mall's tile)
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	RoomBuilder.make_floor(root, CLOTHES.grow(-T / 2.0), Color("C86A9A"), tex["carpet"], 0.004)
	RoomBuilder.make_floor(root, TOYS.grow(-T / 2.0), Color.WHITE, tex["memphis"], 0.004)
	RoomBuilder.make_floor(root, MUSIC.grow(-T / 2.0), Color("3A3050"), tex["carpet"], 0.004)
	RoomBuilder.make_floor(root, COMPUTERS.grow(-T / 2.0), Color("8A8A96"), tex["carpet"], 0.004)
	RoomBuilder.make_floor(root, FOOD.grow(-T / 2.0), Color("E8D8B8"), tex["kitchen"], 0.004)
	# Store signs over the openings, on the concourse side
	var west := CONCOURSE.position.x + T / 2.0 + 0.02
	var east := CONCOURSE.end.x - T / 2.0 - 0.02
	_store_sign(c, "TREND SETTERS", Vector3(west, 3.7, 61.0), 90.0, Color("F2509A"), Color("2A1A2E"))
	_store_sign(c, "TOY BOX", Vector3(west, 3.7, 71.0), 90.0, Color("F7D046"), Color("2E5E9E"))
	_store_sign(c, "SPIN CITY RECORDS", Vector3(east, 3.7, 61.0), -90.0, Color("4FC8FF"), Color("1A1C3A"))
	_store_sign(c, "CIRCUIT HUT", Vector3(east, 3.7, 71.0), -90.0, Color("F2F0E6"), Color("C0322A"))


static func _store_sign(c: Dictionary, text: String, at: Vector3, yaw: float, ink: Color, board: Color) -> void:
	var g := Node3D.new()
	g.position = at
	g.rotation_degrees.y = yaw
	(c["root"] as Node3D).add_child(g)
	var bd := RoomBuilder.box(g, Vector3(4.6, 0.6, 0.06), Vector3(0, 0, 0.03), board)
	bd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := CivicBuilder._label(g, text, Vector3(0, 0, 0.075), 0.0, ink, 0.0042, 64)
	l.outline_size = 6
	l.outline_modulate = Color(0, 0, 0, 0.4)


# ================================================================ helpers

static func _obj(c: Dictionary, key: String, title: String, kind: String, pos: Vector3, yaw: float) -> SmartObject:
	return CivicBuilder._usable(c, key, title, kind, pos, yaw)


static func _act(o: SmartObject, title: String, mins: int, fx: Dictionary, pose := "stand", msgs: Array = [], money := 0.0,
		hours := HOURS) -> Activity:
	var a := Activity.make(title, mins, fx, pose)
	a.messages = msgs
	a.money = money
	a.from_hour = hours.x
	a.to_hour = hours.y
	if money < 0.0:
		a.sound = "cash_register"
		a.autonomous = false
	o.activities.append(a)
	return a


## A sales counter with a register; the clerk stands behind it (at +z of `at` when yaw is 180).
static func _counter(c: Dictionary, at: Vector3, yaw: float, w: float, color: Color) -> void:
	var b := Props.solid(c["root"], at, yaw)
	RoomBuilder.box(b, Vector3(w, 1.0, 0.6), Vector3(0, 0.5, 0), color)
	RoomBuilder.box(b, Vector3(w + 0.06, 0.05, 0.66), Vector3(0, 1.025, 0), Palette.WOOD_DARK)
	RoomBuilder.box(b, Vector3(0.36, 0.24, 0.3), Vector3(w / 2.0 - 0.35, 1.17, -0.05), Color("4A4A52"))   # the register
	RoomBuilder.box(b, Vector3(0.3, 0.08, 0.02), Vector3(w / 2.0 - 0.35, 1.26, 0.111), Color("2EB86A"))
	Props.finish(b, c["solids"], Vector3(w, 1.05, 0.6), Vector3.ZERO)


## Somebody who works at the mall (they walk in from the bus stop each morning).
static func _worker(c: Dictionary, id: String, title: String, pos: Vector3, yaw: float, look: Dictionary, lines: Array,
		hours := Vector2(9.7, 21.2), days: Array = []) -> void:
	CivicBuilder._staff(c, id, title, pos, yaw, look, 1.6, hours, days, lines, "mall")
	var st: Dictionary = (c["out"]["staff"] as Array).back()
	st["door"] = Vector3(DOOR_X, 0, M.position.y - 1.4)
	st["edge"] = TownFolk.EDGES[2]


static func _poster(c: Dictionary, at: Vector3, yaw: float, text: String, paper: Color, ink: Color) -> void:
	CivicBuilder._poster(c, at, yaw, text, paper, ink)


# ================================================================ Trend Setters (clothes)

static func _clothes(c: Dictionary) -> void:
	var r := CLOTHES
	var racks := [[Vector3(78.0, 0, 59.6), [6, 7, 8, 9]], [Vector3(83.0, 0, 59.6), [10, 11, 12, 13]], [Vector3(79.5, 0, 63.4), [14, 15, 16]]]
	for i in racks.size():
		var at: Vector3 = racks[i][0]
		var ids: Array = racks[i][1]
		var o := _obj(c, "clothes_rack_%d" % (i + 1), "Clothes Rack", "clothes_rack", at, 0)
		Props.part(o, Vector3(0.7, 0.05, 0.7), Vector3(0, 0.025, 0), Color("C8CCD0"))
		Props.part(o, Vector3(0.06, 1.3, 0.06), Vector3(0, 0.7, 0), Color("C8CCD0"))
		Props.part(o, Vector3(1.24, 0.04, 0.04), Vector3(0, 1.33, 0), Color("C8CCD0"))
		Props.part(o, Vector3(0.04, 0.04, 1.24), Vector3(0, 1.37, 0), Color("C8CCD0"))
		var hang := [[Vector3(-0.5, 0.95, 0), Vector3(0.08, 0.7, 0.42)], [Vector3(0.5, 0.95, 0), Vector3(0.08, 0.7, 0.42)],
			[Vector3(0, 0.99, -0.5), Vector3(0.42, 0.7, 0.08)], [Vector3(0, 0.99, 0.5), Vector3(0.42, 0.7, 0.08)]]
		for k in ids.size():
			var outfit: Dictionary = Looks.OUTFITS[int(ids[k])]
			Props.part(o, hang[k][1], hang[k][0], outfit["top"], null, false)
		Props.finish(o, c["solids"], Vector3(1.3, 1.4, 1.3), Vector3(0, 0, 1.15), null, Vector3(0, 1.0, 0))
		for id in ids:
			o.activities.append(Catalog.buy_activity("outfit_%d" % int(id), HOURS))
		_act(o, "Browse the Clothes", 15, {"fun": 22.0}, "reach",
			["So many shoulder pads.", "This one's totally rad. And totally out of your allowance."])
	var mir := _obj(c, "trend_mirror", "Three-Way Mirror", "mirror", Vector3(r.position.x + T / 2.0 + 0.06, 0, 63.2), 90)
	Props.part(mir, Vector3(1.0, 1.8, 0.04), Vector3(0, 1.1, 0.02), Color("BFE0EE"))
	Props.part(mir, Vector3(1.08, 1.88, 0.03), Vector3(0, 1.1, -0.005), Palette.GOLD, null, false)
	Props.finish(mir, c["solids"], Vector3(1.08, 1.9, 0.08), Vector3(0, 0, 1.1), null, Vector3(0, 1.2, 0))
	_act(mir, "Strike a Pose in the Mirror", 10, {"fun": 26.0}, "dance", ["Looking GOOD.", "Vogue! Strike a pose!"])
	_counter(c, Vector3(84.6, 0, 64.6), 180.0, 2.4, Color("2A1A2E"))
	_worker(c, "clerk_clothes", "Tiffany", Vector3(84.6, 0, 65.45), 180.0,
		{"gender": "girl", "hair": "teased", "hair_color": 4, "skin": 0, "adult": true, "top_style": "plain",
		"top": Color("F2509A"), "pants": Color("2A1A2E"), "shoes": Color("F2F0E6")},
		["Like, that would look totally awesome on you.", "Shoulder pads are SO in right now.",
		"We just got the new jackets in. Fer sure check 'em out.", "Gag me with a spoon, did you see what she was wearing?"])
	_poster(c, Vector3(81.0, 2.2, r.position.y + T / 2.0 + 0.01), 0.0, "NEW\nFALL\nLOOKS", Color("F2509A"), Palette.PAPER)


# ================================================================ the Toy Box

static func _toys(c: Dictionary) -> void:
	var r := TOYS
	var shelf_x := r.position.x + T / 2.0 + 0.24
	var shelves := [[69.0, ["sketch", "spring", "litepegs", "pogs"]], [73.0, ["gamekid", "furbit", "walktunes", "teddy"]]]
	for i in shelves.size():
		var o := _obj(c, "toy_shelf_%d" % (i + 1), "Toy Shelf", "toy_shelf", Vector3(shelf_x, 0, shelves[i][0]), 90)
		Props.part(o, Vector3(3.2, 2.0, 0.45), Vector3(0, 1.0, 0), Color("2E5E9E"))
		var cols := [Color("C0322A"), Color("F7D046"), Color("2EB86A"), Color("F2509A"), Color("7A4FB0"), Color("4FC8FF")]
		for row in 3:
			for k in 6:
				var bx := Vector3(0.36, 0.3, 0.06)
				Props.part(o, bx, Vector3(-1.3 + k * 0.52, 0.45 + row * 0.6, 0.25), cols[(k + row * 2 + i) % cols.size()], null, false)
		Props.finish(o, c["solids"], Vector3(3.2, 2.0, 0.45), Vector3(0, 0, 0.95), null, Vector3(0, 1.0, 0))
		for id in shelves[i][1]:
			o.activities.append(Catalog.buy_activity(id, HOURS))
	# The demo table: try the Game Kid
	var dt := _obj(c, "toy_demo", "Game Kid Demo Table", "toy_demo", Vector3(81.0, 0, 71.0), 0)
	Props.part(dt, Vector3(1.6, 0.85, 0.9), Vector3(0, 0.425, 0), Color("F7D046"))
	Props.part(dt, Vector3(0.22, 0.32, 0.06), Vector3(-0.3, 0.92, 0.1), Color("B8B8B0"), null, false)
	Props.part(dt, Vector3(0.12, 0.1, 0.02), Vector3(-0.3, 0.98, 0.135), Color("8AA830"), null, false)
	Props.part(dt, Vector3(0.5, 0.2, 0.4), Vector3(0.4, 0.95, 0.0), Color("C0322A"), null, false)
	Props.finish(dt, c["solids"], Vector3(1.6, 0.9, 0.9), Vector3(0, 0, 1.0), null, Vector3(0, 0.95, 0))
	_act(dt, "Try the Game Kid Demo", 15, {"fun": 40.0}, "reach",
		["Falling blocks! Line them up! ...Line clear!", "A kid behind you is waiting. You pretend not to notice."])
	# a giant teddy bear in the corner
	var bear := Props.solid(c["root"], Vector3(86.6, 0, 67.0), 200)
	RoomBuilder.box(bear, Vector3(0.9, 0.9, 0.7), Vector3(0, 0.45, 0), Color("A8743A"))
	RoomBuilder.box(bear, Vector3(0.7, 0.62, 0.6), Vector3(0, 1.21, 0), Color("A8743A"))
	for sx in [-0.28, 0.28]:
		RoomBuilder.box(bear, Vector3(0.2, 0.2, 0.12), Vector3(sx, 1.58, 0), Color("8A5A2A"))
	RoomBuilder.box(bear, Vector3(0.26, 0.18, 0.08), Vector3(0, 1.14, -0.33), Color("D9B07A"))
	Props.finish(bear, c["solids"], Vector3(0.9, 1.6, 0.7), Vector3.ZERO)
	_counter(c, Vector3(84.6, 0, 74.6), 180.0, 2.4, Color("2E5E9E"))
	_worker(c, "clerk_toys", "Mr. Kringle", Vector3(84.6, 0, 75.45), 180.0,
		{"gender": "boy", "hair": "bowl", "hair_color": 5, "skin": 0, "adult": true, "top_style": "plain",
		"top": Color("C0322A"), "pants": Color("2E5E9E"), "shoes": Palette.INK},
		["The Game Kid is flying off the shelves. Better grab one!", "No running in the store. ...Okay, a LITTLE running.",
		"Every kid needs a Stair Spring. It's the law.", "Furbits talk. Nobody knows what they're saying. Not even Furbits."])
	_poster(c, Vector3(r.position.x + 7.0, 2.2, r.end.y - T / 2.0 - 0.01), 180.0, "GAME\nKID!\n$45", Color("F7D046"), Color("2E5E9E"))


# ================================================================ Spin City Records

static func _music(c: Dictionary) -> void:
	var r := MUSIC
	var bins := [[Vector3(104.2, 0, 59.4), "Record Bins", ["lp_neon", "lp_rewind", "lp_maple", "lp_laser"], Color("6A4A2E")],
		[Vector3(108.6, 0, 59.4), "CD Racks", ["cd_grunge", "cd_pop", "cd_rap"], Color("3A3A44")]]
	for i in bins.size():
		var o := _obj(c, "music_bin_%d" % (i + 1), bins[i][1], "record_bin", bins[i][0], 0)
		Props.part(o, Vector3(2.0, 0.8, 0.8), Vector3(0, 0.4, 0), bins[i][3])
		var cols := [Color("FF4FD8"), Color("4FC8FF"), Color("F7D046"), Color("2EB86A"), Color("F2F0E6"), Color("C0322A")]
		for k in 8:
			var sleeve := Props.part(o, Vector3(0.3 if i == 0 else 0.14, 0.3 if i == 0 else 0.13, 0.02),
				Vector3(-0.78 + k * 0.22, 0.92 if i == 0 else 0.87, -0.2 + (k % 2) * 0.12), cols[k % cols.size()], null, false)
			sleeve.rotation.x = -0.35
		Props.finish(o, c["solids"], Vector3(2.0, 0.85, 0.8), Vector3(0, 0, 1.0), null, Vector3(0, 0.9, 0))
		for id in bins[i][2]:
			o.activities.append(Catalog.buy_activity(id, HOURS))
		_act(o, "Flip Through the %s" % ("Records" if i == 0 else "CDs"), 15, {"fun": 24.0}, "reach",
			["You find a weird album cover with a cat in space. Respect.", "Everything's sorted by genre. And by vibe."])
	var ls := _obj(c, "listening_station", "Listening Station", "listening", Vector3(r.end.x - T / 2.0 - 0.215, 0, 63.2), -90)
	Props.part(ls, Vector3(1.2, 1.1, 0.4), Vector3(0, 0.55, 0), Color("1A1C3A"))
	Props.part(ls, Vector3(0.3, 0.2, 0.12), Vector3(-0.3, 1.2, 0.0), Palette.INK)
	Props.part(ls, Vector3(0.3, 0.2, 0.12), Vector3(0.3, 1.2, 0.0), Palette.INK)
	Props.finish(ls, c["solids"], Vector3(1.2, 1.3, 0.4), Vector3(0, 0, 0.9), null, Vector3(0, 1.2, 0))
	var a := _act(ls, "Listen at the Listening Station", 20, {"fun": 40.0}, "stand",
		["The new Neon Hearts single. You bob your head. You can't help it.", "The headphones are huge. The bass is huger."])
	a.loop_sound = "music_house"
	a.loop_db = -14.0
	_counter(c, Vector3(105.0, 0, 64.6), 180.0, 2.4, Color("1A1C3A"))
	_worker(c, "clerk_music", "Dave", Vector3(105.0, 0, 65.45), 180.0,
		{"gender": "boy", "hair": "layered", "hair_color": 0, "skin": 1, "adult": true, "top_style": "plain",
		"top": Color("2B2B30"), "pants": Color("3E5C8A"), "shoes": Color("141414")},
		["Vinyl's never gonna die, man. Never.", "CDs? They skip. I'm just saying.", "You like Laser Kitten? Dude. DUDE.",
		"Ask me about the import section. Actually, don't. I'll talk for an hour."])
	for i in 3:
		_poster(c, Vector3([101.6, 108.4, 111.6][i], 2.3, r.end.y - T / 2.0 - 0.01), 180.0,
			["NEON\nHEARTS\nLIVE!", "THE\nCASSETTES", "LASER\nKITTEN"][i], [Color("FF4FD8"), Color("F7D046"), Color("4FC8FF")][i], Palette.INK)


# ================================================================ Circuit Hut (electronics)

static func _computers(c: Dictionary) -> void:
	var r := COMPUTERS
	var comps := ["computer_color", "computer_64", "computer_tower"]
	for i in comps.size():
		var at := Vector3(r.end.x - T / 2.0 - 0.45, 0, 69.0 + i * 2.6)
		var o := _obj(c, "computer_display_%d" % (i + 1), Catalog.title(comps[i]), "computer_display", at, -90)
		Props.part(o, Vector3(1.4, 0.75, 0.7), Vector3(0, 0.375, 0), Color("D9D2C2"))
		var model := Node3D.new()
		model.position = Vector3(0, 0.75, -0.1)
		o.add_child(model)
		computer_model(model, comps[i])
		Props.finish(o, c["solids"], Vector3(1.4, 0.8, 0.7), Vector3(0, 0, 1.0), null, Vector3(0, 1.0, 0))
		o.activities.append(Catalog.buy_activity(comps[i], HOURS))
		var a := _act(o, "Try the Demo", 15, {"fun": 34.0}, "reach",
			["READY.  You type 10 PRINT \"JAMIE RULES\" 20 GOTO 10. The salesman sighs.", "A demo of a flight simulator. Your plane crashes into a mountain. Wicked."])
		a.loop_sound = "arcade_game"
		a.loop_db = -18.0
	var sh := _obj(c, "gadget_shelf", "Gadget Wall", "gadget_shelf", Vector3(106.5, 0, r.end.y - T / 2.0 - 0.24), 180)
	Props.part(sh, Vector3(3.6, 2.0, 0.45), Vector3(0, 1.0, 0), Color("C0322A"))
	for row in 3:
		for k in 5:
			Props.part(sh, Vector3(0.4, 0.26, 0.06), Vector3(-1.4 + k * 0.7, 0.45 + row * 0.6, 0.25),
				[Color("4A4A52"), Color("C8CCD0"), Color("2B2B30"), Color("D9D2C2")][(k + row) % 4], null, false)
	Props.finish(sh, c["solids"], Vector3(3.6, 2.0, 0.45), Vector3(0, 0, 0.95), null, Vector3(0, 1.0, 0))
	for id in ["modem", "cdplayer", "calcwatch", "rccar"]:
		sh.activities.append(Catalog.buy_activity(id, HOURS))
	_counter(c, Vector3(104.0, 0, 67.4), 0.0, 2.4, Color("C0322A"))
	_worker(c, "clerk_computers", "Gary", Vector3(104.0, 0, 66.55), 0.0,
		{"gender": "boy", "hair": "buzz", "hair_color": 1, "skin": 2, "adult": true, "top_style": "plain",
		"top": Color("F2F0E6"), "pants": Color("2B2B30"), "shoes": Palette.INK},
		["Can I interest you in a battery-of-the-month club card?", "That Micro-Pal 64 has SIXTY-FOUR kilobytes. That's more than you'll ever need.",
		"You'll want a modem. Trust me, the future's online.", "Batteries not included. They never are."])
	_poster(c, Vector3(r.position.x + 7.0, 2.3, r.position.y + T / 2.0 + 0.01), 0.0, "THE\nFUTURE\nIS HERE", Color("C0322A"), Palette.PAPER)


## A home computer, built facing +z on top of a desk (y = 0 is the desktop).
static func computer_model(g: Node3D, id: String) -> void:
	match id:
		"computer_color":
			RoomBuilder.box(g, Vector3(0.44, 0.07, 0.24), Vector3(0, 0.035, 0.12), Color("C8CCD0"))         # keyboard unit
			RoomBuilder.box(g, Vector3(0.38, 0.012, 0.12), Vector3(0, 0.076, 0.13), Color("4A4A52"))
			RoomBuilder.box(g, Vector3(0.34, 0.28, 0.26), Vector3(0, 0.14, -0.14), Color("8A7A6A"))         # a little TV
			RoomBuilder.box(g, Vector3(0.24, 0.18, 0.01), Vector3(0, 0.15, -0.006), Color("4FC8A0"))
		"computer_64":
			RoomBuilder.box(g, Vector3(0.42, 0.06, 0.18), Vector3(0, 0.03, 0.15), Color("B8A888"))          # the breadbox keyboard
			RoomBuilder.box(g, Vector3(0.34, 0.012, 0.1), Vector3(0, 0.066, 0.15), Color("5A4A3A"))
			RoomBuilder.box(g, Vector3(0.36, 0.3, 0.28), Vector3(0, 0.15, -0.12), Color("C8BCA0"))
			RoomBuilder.box(g, Vector3(0.27, 0.2, 0.01), Vector3(0, 0.165, 0.025), Color("5A6AE8"))
		"computer_tower":
			RoomBuilder.box(g, Vector3(0.4, 0.03, 0.15), Vector3(-0.05, 0.015, 0.17), Color("E2DCC8"))
			RoomBuilder.box(g, Vector3(0.36, 0.33, 0.3), Vector3(-0.05, 0.165, -0.12), Color("E2DCC8"))
			RoomBuilder.box(g, Vector3(0.28, 0.22, 0.01), Vector3(-0.05, 0.18, 0.035), Color("2E6AC8"))
			RoomBuilder.box(g, Vector3(0.14, 0.32, 0.34), Vector3(0.26, 0.16, -0.2), Color("D8D2BE"))        # the tower (set back, clear of the diary)
			RoomBuilder.box(g, Vector3(0.1, 0.02, 0.01), Vector3(0.26, 0.26, -0.027), Color("2EB86A"))
	for mi in g.get_children():
		if mi is MeshInstance3D:
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var screen := g.get_child(3) as MeshInstance3D
	if screen:
		var m: StandardMaterial3D = screen.material_override
		m.emission_enabled = true
		m.emission = m.albedo_color
		m.emission_energy_multiplier = 0.6


# ================================================================ the concourse

static func _concourse(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var cx := CONCOURSE.get_center().x
	# The fountain
	var f := _obj(c, "mall_fountain", "Fountain", "mall_fountain", Vector3(cx, 0, 66.0), 0)
	Props.part(f, Vector3(3.0, 0.5, 3.0), Vector3(0, 0.25, 0), Color("C8BCA8"))
	var water := Props.part(f, Vector3(2.7, 0.04, 2.7), Vector3(0, 0.5, 0), Color("4FB8E8"), null, false)
	var wm: StandardMaterial3D = water.material_override
	wm.emission_enabled = true
	wm.emission = Color("2E88C8")
	wm.emission_energy_multiplier = 0.3
	Props.part(f, Vector3(0.4, 1.24, 0.4), Vector3(0, 0.62, 0), Color("D9D2C2"), null, false)
	Props.part(f, Vector3(0.9, 0.12, 0.9), Vector3(0, 1.26, 0), Color("D9D2C2"), null, false)
	var spray := Props.part(f, Vector3(0.18, 0.5, 0.18), Vector3(0, 1.56, 0), Color("BFE8F7"), null, false)
	(spray.material_override as StandardMaterial3D).emission_enabled = true
	(spray.material_override as StandardMaterial3D).emission = Color("BFE8F7")
	Props.finish(f, c["solids"], Vector3(3.0, 0.6, 3.0), Vector3(0, 0, 2.1), null, Vector3(0, 0.5, 0))
	var a := _act(f, "Toss a Penny and Make a Wish", 3, {"fun": 20.0}, "reach",
		["Plink. You wish for a Game Kid. (Shh, don't tell.)", "Plink! It lands next to about a thousand other pennies."], -0.01)
	a.autonomous = true
	a.memory_id = "mall"
	_act(f, "Sit on the Fountain's Edge", 20, {"energy": 12.0, "social": 14.0}, "sit", ["The splashing is weirdly relaxing."]).surface = 0.5
	# Benches along the sides, facing in
	var benches := [[Vector3(CONCOURSE.position.x + 0.75, 0, 65.6), 90.0], [Vector3(CONCOURSE.end.x - 0.75, 0, 65.6), -90.0],
		[Vector3(CONCOURSE.position.x + 0.75, 0, 74.6), 90.0], [Vector3(CONCOURSE.end.x - 0.75, 0, 74.6), -90.0]]
	for i in benches.size():
		var b := _obj(c, "mall_bench_%d" % (i + 1), "Bench", "mall_bench", benches[i][0], benches[i][1])
		Props.part(b, Vector3(1.8, 0.08, 0.5), Vector3(0, 0.45, 0), Palette.WOOD)
		Props.part(b, Vector3(1.8, 0.45, 0.06), Vector3(0, 0.72, -0.24), Palette.WOOD)
		for lx in [-0.8, 0.8]:
			Props.part(b, Vector3(0.08, 0.42, 0.44), Vector3(lx, 0.21, 0), Color("4A4A52"), null, false)
		Props.finish(b, c["solids"], Vector3(1.8, 0.95, 0.5), Vector3(0, 0, 0.8), Vector3(0, 0, 0.2), Vector3(0, 0.9, 1.5))
		var s := _act(b, "Sit and People-Watch", 30, {"energy": 16.0, "social": 18.0, "fun": 10.0}, "sit",
			["A mall walker power-walks past for the third time.", "Somebody's mom is carrying SIX shopping bags."])
		s.surface = 0.49
		s.autonomous = true
	# Planters at the corners
	for p in [Vector3(CONCOURSE.position.x + 0.7, 0, 57.3), Vector3(CONCOURSE.end.x - 0.7, 0, 57.3)]:
		var pl := Props.solid(root, p, 0)
		RoomBuilder.box(pl, Vector3(1.0, 0.7, 1.0), Vector3(0, 0.35, 0), Color("C8A880"))
		RoomBuilder.box(pl, Vector3(0.24, 1.1, 0.24), Vector3(0, 1.25, 0), Palette.WOOD_DARK)
		RoomBuilder.box(pl, Vector3(1.2, 0.9, 1.2), Vector3(0, 2.1, 0), OutdoorBuilder.GREENS[1])
		Props.finish(pl, c["solids"], Vector3(1.0, 0.7, 1.0), Vector3.ZERO)
	# The directory by the doors
	var d := _obj(c, "mall_directory", "Mall Directory", "mall_directory", Vector3(CONCOURSE.position.x + 3.2, 0, 57.4), 0)
	Props.part(d, Vector3(1.1, 1.7, 0.16), Vector3(0, 0.85, 0), Color("2E5E9E"))
	Props.part(d, Vector3(0.9, 1.1, 0.02), Vector3(0, 1.05, 0.09), Palette.PAPER, null, false)
	CivicBuilder._label(d, "YOU ARE\nHERE ★", Vector3(0, 1.05, 0.104), 0.0, Color("C0322A"), 0.003, 40)
	Props.finish(d, c["solids"], Vector3(1.1, 1.7, 0.2), Vector3(0, 0, 0.9), null, Vector3(0, 1.2, 0))
	_act(d, "Read the Directory", 3, {"fun": 4.0}, "stand",
		["Trend Setters, Toy Box, Spin City Records, Circuit Hut, and the Food Court out back. YOU ARE HERE."])
	# Teens hang out here (TownFolk): their walking loop
	c["out"]["mall_route"] = [Vector3(cx - 3.4, 0, 58.5), Vector3(cx - 3.4, 0, 74.0), Vector3(cx, 0, 80.5),
		Vector3(cx + 3.4, 0, 74.0), Vector3(cx + 3.4, 0, 58.5)]


# ================================================================ the food court

static func _food_court(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var back := FOOD.end.y - T / 2.0
	for i in FOOD_PLACES.size():
		var fp: Array = FOOD_PLACES[i]
		var x: float = fp[3]
		var col: Color = fp[2]
		# the counter, a menu board and the sign
		var o := _obj(c, "food_" + String(fp[0]), String(fp[1]).capitalize(), "food_counter", Vector3(x, 0, back - 1.9), 180)
		Props.part(o, Vector3(5.2, 1.0, 0.7), Vector3(0, 0.5, 0), col.darkened(0.25))
		Props.part(o, Vector3(5.26, 0.05, 0.76), Vector3(0, 1.025, 0), Palette.PAPER)
		Props.part(o, Vector3(0.36, 0.22, 0.3), Vector3(1.9, 1.16, 0.0), Color("4A4A52"), null, false)
		for t in 3:
			Props.part(o, Vector3(0.36, 0.03, 0.26), Vector3(-1.6 + t * 0.6, 1.065, 0.05), Color("8A6A4A"), null, false)   # trays
		Props.finish(o, c["solids"], Vector3(5.2, 1.05, 0.7), Vector3(0, 0, 1.1), null, Vector3(0, 1.1, 0))
		var g := Node3D.new()
		g.position = Vector3(x, 0, back - 0.01)
		g.rotation_degrees.y = 180.0
		root.add_child(g)
		var board := RoomBuilder.box(g, Vector3(4.8, 1.2, 0.04), Vector3(0, 2.4, 0.02), Palette.INK)
		board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var menu := []
		for f in fp[4]:
			menu.append("%s  $%.2f" % [String(f[0]).replace("Buy ", "").replace("Try ", ""), float(f[1])])
		CivicBuilder._label(g, "\n".join(menu), Vector3(0, 2.35, 0.05), 0.0, Palette.PAPER, 0.003, 44)
		var sb := RoomBuilder.box(g, Vector3(5.0, 0.7, 0.08), Vector3(0, 3.5, 0.3), col)
		sb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var sl := CivicBuilder._label(g, fp[1], Vector3(0, 3.5, 0.345), 0.0, Palette.PAPER, 0.0045, 64)
		sl.outline_size = 8
		sl.outline_modulate = Color(0, 0, 0, 0.45)
		for f in fp[4]:
			var a := _act(o, f[0], 20, {"hunger": float(f[2]), "fun": float(f[3])}, "stand", [], -float(f[1]))
			if float(f[1]) == 0.0:
				a.minutes = 3
				a.autonomous = true
				a.messages = ["A toothpick with a piece of chicken on it. Free! You go around again."]
			else:
				a.messages = ["You grab a tray and eat at one of the tables. Mmm.", "Food court food just tastes better. Science."]
		_worker(c, "cook_" + String(fp[0]), ["Gino", "Rosa M.", "Mr. Chen", "Bobbi"][i], Vector3(x + 0.8, 0, back - 1.1), 180.0,
			{"gender": ["boy", "girl", "boy", "girl"][i], "hair": ["cap", "bun", "buzz", "scrunchie"][i], "hair_color": [0, 1, 0, 3][i],
			"skin": [1, 3, 1, 4][i], "adult": true, "top_style": "plain", "top": col, "pants": Palette.INK2, "shoes": Palette.INK},
			[["You want extra cheese? Everybody wants extra cheese.", "Slice of Napoli: almost like being in Italy. Almost."],
			["Hot sauce is on the counter. Careful, it's LOCO.", "Taco Tuesday is every day here."],
			["Free sample? Here, try the orange chicken.", "Egg roll, fresh out of the fryer."],
			["Cluck cluck! What can I get ya?", "Our biscuits are made with love. And butter. Mostly butter."]][i])
	# Tables and chairs
	var spots := [80.0, 86.0, 102.0, 108.0]
	var n := 0
	for z in [80.0, 83.6]:
		for x in spots:
			n += 1
			var t := _obj(c, "fc_table_%d" % n, "Food Court Table", "fc_table", Vector3(x, 0, z), 0)
			Props.part(t, Vector3(1.1, 0.05, 0.8), Vector3(0, 0.74, 0), Palette.PAPER)
			Props.part(t, Vector3(0.1, 0.72, 0.1), Vector3(0, 0.36, 0), Palette.INK2, null, false)
			for sx in [-0.85, 0.85]:
				Props.part(t, Vector3(0.42, 0.45, 0.42), Vector3(sx, 0.225, 0), [Color("C0322A"), Color("2E8C8A"), Color("F7D046")][n % 3], null, false)
				Props.part(t, Vector3(0.06, 0.45, 0.42), Vector3(sx + signf(sx) * 0.2, 0.67, 0), [Color("C0322A"), Color("2E8C8A"), Color("F7D046")][n % 3], null, false)
			Props.finish(t, c["solids"], Vector3(1.1, 0.78, 0.8), Vector3(-1.45, 0, 0), Vector3(-0.85, 0, 0), Vector3(0, 0.8, 0))
			var s := _act(t, "Hang Out at a Table", 30, {"social": 30.0, "energy": 10.0}, "sit",
				["Somebody's playing a Walk-Tunes so loud you can hear it from here.", "You split a pretzel with nobody. More for you."])
			s.surface = 0.45
			s.autonomous = true
	# Payphones on the west wall, and a trash can or two
	PayPhones.add(c, "payphone_mall_1", Vector3(FOOD.position.x + T / 2.0, 0, 79.5), 90.0, HOURS)
	PayPhones.add(c, "payphone_mall_2", Vector3(FOOD.position.x + T / 2.0, 0, 80.6), 90.0, HOURS)
	for x in [93.0, 95.0]:
		var tc := Props.solid(root, Vector3(x, 0, 87.6), 0)
		RoomBuilder.box(tc, Vector3(0.5, 0.9, 0.5), Vector3(0, 0.45, 0), Color("6A5A4A"))
		RoomBuilder.box(tc, Vector3(0.54, 0.06, 0.54), Vector3(0, 0.93, 0), Color("4A4A52"))
		Props.finish(tc, c["solids"], Vector3(0.5, 0.95, 0.5), Vector3.ZERO)
