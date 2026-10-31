class_name DowntownBuilder
extends RefCounted
## Main Street: the shopping street a block south of Maple Street (walk between
## the houses across the street, or drive down Oak Avenue).
##
##   z = 36    backs of the Kowalskis', Nguyens' and Parkers' houses
##   z = 44.4  ======= sidewalk (bus stop bench, trees, the town sign) =========
##   z = 46    =======              MAIN STREET              =================
##   z = 55.6  ======= sidewalk ===============================================
##   z = 56     [LIBRARY]  [SUNRISE DINER] [PIZZA PEAK] [REWIND VIDEO] [PIXEL PALACE]
##   z = 66      x -14..0      x 2..12        x 14..25     x 27..36       x 38..48
##
## Every shop is one room with an open front doorway and big shop windows.
## Its things to do (and their prices and opening hours) are in content.gd.

const Z0 := 46.0          # Main Street's north curb
const Z1 := 54.0          # south curb
const FRONT := 56.0       # the shop fronts (wall centers)
const BACK := 66.0
const H := 3.6
const T := 0.15

const SHOPS := {
	"library": {"title": "Maple Grove Public Library", "x0": -14.0, "x1": 0.0, "outside": Color("9A4A3A"),
		"skin": "brick", "inside": Color("C8A878"), "surface": "panel", "floor": Color("4F6A4A"), "floor_tex": "carpet",
		"sign": "MAPLE GROVE\nPUBLIC LIBRARY", "sign_color": Color("F2D58A"), "board": Color("2E4A3A")},
	"diner": {"title": "Sunrise Diner", "x0": 2.0, "x1": 12.0, "outside": Color("DDE6E2"),
		"skin": "siding", "inside": Color.WHITE, "surface": "kitchen", "floor": Color.WHITE, "floor_tex": "lino",
		"sign": "SUNRISE DINER", "sign_color": Color("FF7A8A"), "board": Color("2E8C8A")},
	"pizza": {"title": "Pizza Peak", "x0": 14.0, "x1": 25.0, "outside": Color("B8865A"),
		"skin": "brick", "inside": Color("8A5A3B"), "surface": "panel", "floor": Color("A04A3A"), "floor_tex": "concrete",
		"sign": "PIZZA PEAK", "sign_color": Color("FFF1D6"), "board": Color("B5322A")},
	"video": {"title": "Rewind Video", "x0": 27.0, "x1": 36.0, "outside": Color("2B2F5A"),
		"skin": "siding", "inside": Color("E8E2F2"), "surface": "panel", "floor": Color("3A4A8A"), "floor_tex": "carpet",
		"sign": "REWIND VIDEO", "sign_color": Color("F7D046"), "board": Color("1A1C3A")},
	"arcade": {"title": "Pixel Palace Arcade", "x0": 38.0, "x1": 48.0, "outside": Color("26202E"),
		"skin": "brick", "inside": Color("3A3050"), "surface": "panel", "floor": Color.WHITE, "floor_tex": "memphis",
		"sign": "PIXEL PALACE", "sign_color": Color("FF4FD8"), "board": Color("120E18")},
	"bikes": {"title": "Spoke & Pedal Bikes", "x0": 50.0, "x1": 58.5, "outside": Color("2E8C8A"),
		"skin": "siding", "inside": Color("F2F0E6"), "surface": "panel", "floor": Color("C8C0A8"), "floor_tex": "lino",
		"sign": "SPOKE & PEDAL", "sign_color": Color("F7D046"), "board": Color("1F5A58")},
	"grocery": {"title": "Food Fair Grocery", "x0": 60.5, "x1": 71.0, "outside": Color("C8A250"),
		"skin": "brick", "inside": Color("F2F0E6"), "surface": "kitchen", "floor": Color.WHITE, "floor_tex": "lino",
		"sign": "FOOD FAIR", "sign_color": Color("C0322A"), "board": Color("F2F0E6")},
}


static func shop_rect(key: String) -> Rect2:
	var s: Dictionary = SHOPS[key]
	return Rect2(s["x0"], FRONT, float(s["x1"]) - float(s["x0"]), BACK - FRONT)


static func shop_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for k in SHOPS:
		out.append(shop_rect(k).grow(0.12))
	out.append(GAZETTE.grow(0.12))
	return out


## The Maple Grove Gazette's office (north side of Main Street, facing it), and
## Frosty's ice cream stand next door.
const GAZETTE := Rect2(43.6, 37.4, 6.0, 5.6)
## The Starlite Drive-In, at the east end of town between Maple Street and Main Street.
const DRIVE_IN := Rect2(52.0, 27.0, 13.0, 15.5)
const FROSTYS := Rect2(38.6, 40.4, 3.6, 2.6)


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2]) -> void:
	out["town_rooms"] = {}
	_street(root, out, tex, solids)
	for key in SHOPS:
		var c := _shop(root, out, tex, solids, free, doorways, buildings, key)
		match key:
			"library":
				_library(c)
			"diner":
				_diner(c)
			"pizza":
				_pizza(c)
			"video":
				_video(c)
			"arcade":
				_arcade(c)
			"bikes":
				_bikes(c)
			"grocery":
				_grocery(c)
		var hrs: Vector2 = SHOP_HOURS.get(key, Vector2(9, 21))
		_register_door(out, key, String(SHOPS[key]["title"]), shop_rect(key), hrs, SHOP_DAYS.get(key, []))
	_gazette(root, out, tex, solids, free, doorways, buildings)
	_register_door(out, "gazette", "The Maple Grove Gazette", GAZETTE, Vector2(5.0, 18.0), [])
	_frostys(root, out, tex, solids)
	_drive_in(root, out, tex, solids)


# ================================================================ the street

static func _street(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2]) -> void:
	var asphalt := Color("4A4950")
	var concrete := Color("CFC8BA")
	OutdoorBuilder._slab(root, Rect2(-66, Z0 + 0.15, OutdoorBuilder.EAST_END + 66.0, Z1 - Z0 - 0.3), asphalt, tex["asphalt"], -0.015)
	for x in range(-64, int(OutdoorBuilder.EAST_END) - 2, 4):
		if x + 2 < OutdoorBuilder.OAK_X0 or x > OutdoorBuilder.OAK_X1:
			OutdoorBuilder._slab(root, Rect2(x, (Z0 + Z1) / 2.0 - 0.06, 2.0, 0.12), Color("E8C24A"), null, -0.008)
	for z in [Z0, Z1 - 0.15]:
		for seg in [[-66.0, OutdoorBuilder.OAK_X0 - 0.01], [OutdoorBuilder.OAK_X1 + 0.01, OutdoorBuilder.EAST_END]]:
			var len: float = seg[1] - seg[0]
			RoomBuilder.box(root, Vector3(len, 0.12, 0.15), Vector3(seg[0] + len / 2.0, 0.04, z + 0.075), Color("B9B2A5"))
	OutdoorBuilder._slab(root, Rect2(-66, Z0 - 1.6, OutdoorBuilder.EAST_END + 66.0, 1.6), concrete, tex["concrete"], 0.004)
	OutdoorBuilder._slab(root, Rect2(-66, Z1, OutdoorBuilder.EAST_END + 66.0, 1.6), concrete, tex["concrete"], 0.004)
	OutdoorBuilder._slab(root, Rect2(-14.5, Z1 + 1.6, 88.5, FRONT - Z1 - 1.6 - 0.12), Color("BDB6A8"), tex["concrete"], 0.005)
	for x in [5.0, 6.0, 7.0]:   # a crosswalk to the bus stop
		OutdoorBuilder._slab(root, Rect2(x - 0.3, Z0, 0.6, Z1 - Z0), Palette.PAPER, null, -0.006)
	# Streetlights, trees, a bus stop and the town sign on the north side
	for x in [-10.0, 10.0, 30.0, 46.0, 59.5, 76.0]:
		OutdoorBuilder._streetlight(root, solids, out, Vector3(x, 0, Z1 + 1.3), -1.0)
	for x in [-6.0, 20.0, 38.0]:
		OutdoorBuilder._streetlight(root, solids, out, Vector3(x, 0, Z0 - 1.3), 1.0)
	for x in [15.0, 33.0]:
		OutdoorBuilder._tree(root, solids, Vector3(x, 0, 41.5), 0.8)
	var bench := Props.solid(root, Vector3(6.0, 0, Z0 - 1.0), 0)
	RoomBuilder.box(bench, Vector3(1.6, 0.06, 0.45), Vector3(0, 0.45, 0), Palette.WOOD)
	RoomBuilder.box(bench, Vector3(1.6, 0.4, 0.06), Vector3(0, 0.7, -0.2), Palette.WOOD)
	RoomBuilder.box(bench, Vector3(0.08, 0.45, 0.4), Vector3(-0.7, 0.225, 0), Palette.INK2)
	RoomBuilder.box(bench, Vector3(0.08, 0.45, 0.4), Vector3(0.7, 0.225, 0), Palette.INK2)
	Props.finish(bench, solids, Vector3(1.6, 0.9, 0.5), Vector3.ZERO)
	OutdoorBuilder._sign(root, solids, Vector3(7.4, 0, Z0 - 0.7), "BUS\nSTOP", Color("2E5E9E"), Palette.PAPER, Vector2(0.5, 0.5), 0.0)
	OutdoorBuilder._sign(root, solids, Vector3(-16.0, 0, 42.5), "MAIN ST", Color("2E6B4F"), Palette.PAPER, Vector2(0.9, 0.25), 0.0)
	OutdoorBuilder._sign(root, solids, Vector3(-1.0, 0, 41.0), "WELCOME TO\nDOWNTOWN\nMAPLE GROVE", Color("7A4A2E"), Color("F2D58A"),
		Vector2(1.8, 0.9), 0.0)
	# A path through from Maple Street, between the Kowalskis' and the Nguyens'
	OutdoorBuilder._slab(root, Rect2(-1.5, 25.2, 1.2, Z0 - 1.6 - 25.2), concrete, tex["concrete"], 0.003)


# ================================================================ a shop

static func _shop(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2], key: String) -> Dictionary:
	var s: Dictionary = SHOPS[key]
	var r := shop_rect(key)
	var dx := r.get_center().x
	RoomBuilder.make_floor(root, r, s["floor"], tex[s["floor_tex"]])
	RoomBuilder.make_ceiling(root, out, r.grow(-T / 2.0), H)
	buildings.append(r)
	free.append(r.grow(-T / 2.0))
	doorways.append(Rect2(dx - 0.6, FRONT - 0.6, 1.2, 1.2))
	(out["town_rooms"] as Dictionary)["town|" + String(s["title"])] = r

	var col: Color = s["inside"]
	var surf: String = s["surface"]
	var front := RoomBuilder.make_wall(root, key + "Front", Vector3(dx, 0, FRONT), Vector3(r.size.x + T, H, T), Vector3(0, 0, -1),
		tex, [{"c": dx, "w": 1.6, "h": 2.4}], false, col, surf)
	var back := RoomBuilder.make_wall(root, key + "Back", Vector3(dx, 0, BACK), Vector3(r.size.x + T, H, T), Vector3(0, 0, 1),
		tex, [], false, col, surf)
	var left := RoomBuilder.make_wall(root, key + "Left", Vector3(r.position.x, 0, r.get_center().y), Vector3(T, H, r.size.y - T),
		Vector3(-1, 0, 0), tex, [], false, col, surf)
	var right := RoomBuilder.make_wall(root, key + "Right", Vector3(r.end.x, 0, r.get_center().y), Vector3(T, H, r.size.y - T),
		Vector3(1, 0, 0), tex, [], false, col, surf)
	var oc: Color = s["outside"]
	var sk: String = s["skin"]
	RoomBuilder.add_siding(front, -1.0, H, tex, -INF, INF, true, true, oc, sk)
	RoomBuilder.add_siding(back, 1.0, H, tex, -INF, INF, true, true, oc, sk)
	RoomBuilder.add_siding(left, -1.0, H, tex, -INF, INF, true, true, oc, sk)
	RoomBuilder.add_siding(right, 1.0, H, tex, -INF, INF, true, true, oc, sk)
	for w in [front, back, left, right]:
		(out["walls"] as Array).append(w)
	RoomBuilder.make_casing(front, dx, 1.6, 2.4, Palette.INK2)
	(out["swing_doors"] as Array).append(HouseBuilder.make_double_door(front, dx, 1.6, 2.4, s["board"], Vector3(0, 0, 1)))
	RoomBuilder.make_floor(root, Rect2(dx - 0.8, FRONT - 0.12, 1.6, 0.12), Palette.INK2)   # the threshold

	# Big shop windows on both sides of the door
	var glass: StandardMaterial3D = out["window_mat"]
	var half := r.size.x / 2.0
	var ww := minf(2.6, half - 1.6)
	for side in [-1.0, 1.0]:
		var wx: float = dx + side * (0.8 + 0.5 + ww / 2.0)
		RoomBuilder.add_ext_window(front["full"], Vector3(wx, 1.45, FRONT - 0.125), Vector3(ww, 1.5, 0.04), out)
		RoomBuilder.add_int_window(front["full"], Vector3(wx, 1.5, FRONT + T / 2.0), ww - 0.1, 1.45, true, 1.0, glass)

	# The sign over the door, and an awning
	var board := RoomBuilder.box(front["full"], Vector3(minf(r.size.x - 1.0, 7.5), 0.85, 0.08), Vector3(dx, 3.05, FRONT - 0.17), s["board"])
	board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label := Label3D.new()
	label.text = s["sign"]
	label.font_size = 96 if "\n" not in String(s["sign"]) else 64
	label.pixel_size = 0.0045
	label.outline_size = 10
	label.modulate = s["sign_color"]
	label.outline_modulate = Color(0, 0, 0, 0.6)
	label.position = Vector3(dx, 3.05, FRONT - 0.215)
	label.rotation_degrees.y = 180.0
	label.double_sided = false
	(front["full"] as Node3D).add_child(label)
	var awning := RoomBuilder.box(front["full"], Vector3(2.4, 0.08, 0.9), Vector3(dx, 2.62, FRONT - 0.6), s["board"])
	awning.rotation_degrees.x = -12.0

	# A flat roof (hidden in the House Cam, like the houses' roofs)
	var roof := RoomBuilder.box(root, Vector3(r.size.x + 0.5, 0.2, r.size.y + 0.5), Vector3(dx, H + 0.1, r.get_center().y), Color("5A5550"))
	(out["ceilings"] as Array).append(roof)

	# Lights
	var lamp_mesh := RoomBuilder.box(root, Vector3(1.2, 0.06, 0.3), Vector3(dx, H - 0.11, r.get_center().y), Palette.PAPER)
	var lm: StandardMaterial3D = lamp_mesh.material_override
	lm.emission_enabled = true
	lm.emission = Palette.PAPER
	(out["ceilings"] as Array).append(lamp_mesh)
	Props.light(root, out, Vector3(dx, H - 0.5, r.get_center().y - 1.5), Color("FFF1D6"), 9.0, 1.0, 2.2, lm, false)
	Props.light(root, out, Vector3(dx, H - 0.5, r.get_center().y + 2.5), Color("FFF1D6"), 7.0, 0.8, 1.8, null, false)
	return {"root": root, "out": out, "solids": solids, "objects": out["objects"], "key": key, "r": r, "tex": tex,
		"x0": float(s["x0"])}


## World position `u` from the shop's left wall and `d` in from its front wall.
static func _p(c: Dictionary, u: float, d: float, y := 0.0) -> Vector3:
	return Vector3(float(c["x0"]) + u, y, FRONT + d)


## A shopkeeper (TownFolk makes them a person you can talk to). They stand at
## `pos` facing the front of the shop.
static func _clerk(c: Dictionary, shop: String, title: String, pos: Vector3, look: Dictionary, talk_dist: float, hours: Vector2) -> void:
	if not c["out"].has("clerks"):
		c["out"]["clerks"] = []
	(c["out"]["clerks"] as Array).append({"shop": shop, "title": title, "pos": pos, "look": look, "talk": talk_dist, "hours": hours})


static func _item(c: Dictionary, name: String, title: String, kind: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := Props.item(c["root"], c["objects"], name, title, pos, yaw)
	o.kind = kind
	o.home = "town"
	return o


## A plain counter (not usable), facing the front.
static func _counter(c: Dictionary, u: float, d: float, w: float, color: Color, top: Color) -> void:
	var b := Props.solid(c["root"], _p(c, u, d), 180)
	RoomBuilder.box(b, Vector3(w, 1.0, 0.6), Vector3(0, 0.5, 0), color)
	RoomBuilder.box(b, Vector3(w + 0.06, 0.05, 0.66), Vector3(0, 1.025, 0), top)
	Props.finish(b, c["solids"], Vector3(w, 1.05, 0.6), Vector3.ZERO)


## A shelf full of colored spines (books or tapes). Returns it as a usable object
## when `name` is given, else a plain solid.
static func _shelf(c: Dictionary, name: String, title: String, u: float, d: float, yaw: float, w: float, h: float,
		spine_h: float, colors: Array, seed: int) -> Node3D:
	var o: Node3D
	if name != "":
		o = _item(c, name, title, "shelf", _p(c, u, d), yaw)
	else:
		o = Props.solid(c["root"], _p(c, u, d), yaw)
	Props.part(o, Vector3(w, h, 0.45), Vector3(0, h / 2.0, 0), Palette.WOOD_DARK)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rows := int(h / 0.42)
	for row in rows:
		var x := -w / 2.0 + 0.06
		while x < w / 2.0 - 0.1:
			var bw := rng.randf_range(0.04, 0.09)
			var bh := spine_h * rng.randf_range(0.75, 1.0)
			Props.part(o, Vector3(bw - 0.008, bh, 0.03), Vector3(x + bw / 2.0, 0.12 + row * 0.42 + bh / 2.0, 0.235),
				colors[rng.randi() % colors.size()], null, false)
			x += bw
	Props.finish(o, c["solids"], Vector3(w, h, 0.45), Vector3(0, 0, 0.95), null, Vector3(0, 1.1, 0))
	return o


## A table with chairs; sit on the chair at local -x (or +x).
static func _table(c: Dictionary, name: String, title: String, u: float, d: float, cloth: Color, round := false) -> SmartObject:
	var o := _item(c, name, title, "table", _p(c, u, d), 0)
	Props.part(o, Vector3(0.9, 0.05, 0.9) if not round else Vector3(0.8, 0.05, 0.8), Vector3(0, 0.74, 0), cloth,
		c["tex"]["plaid"] if cloth != Palette.WOOD else null)
	Props.part(o, Vector3(0.1, 0.72, 0.1), Vector3(0, 0.36, 0), Palette.INK2, null, false)
	for sx in [-0.75, 0.75]:
		Props.part(o, Vector3(0.42, 0.45, 0.42), Vector3(sx, 0.225, 0), Palette.INK2, null, false)
		Props.part(o, Vector3(0.06, 0.45, 0.42), Vector3(sx + signf(sx) * 0.2, 0.67, 0), Palette.INK2, null, false)
	Props.finish(o, c["solids"], Vector3(0.9, 0.78, 0.9), Vector3(-1.4, 0, 0), Vector3(-0.75, 0, 0), Vector3(0, 0.8, 0))
	return o


# ================================================================ the library

static func _library(c: Dictionary) -> void:
	var books := [Palette.CORAL, Palette.TEAL, Palette.GOLD, Palette.NAVY, Palette.ROSE, Palette.RUST, Color("4F7A3A"), Palette.PAPER]
	# Front desk, with the librarian
	var desk := _item(c, "library_desk", "Front Desk", "desk", _p(c, 3.5, 2.4), 180)
	Props.part(desk, Vector3(2.6, 1.0, 0.6), Vector3(0, 0.5, 0), Palette.WOOD)
	Props.part(desk, Vector3(2.66, 0.05, 0.66), Vector3(0, 1.025, 0), Palette.WOOD_DARK)
	Props.part(desk, Vector3(0.3, 0.06, 0.22), Vector3(0.6, 1.08, 0.05), Palette.PAPER, null, false)   # date stamp & cards
	Props.part(desk, Vector3(0.4, 0.3, 0.3), Vector3(-0.8, 1.2, -0.05), Color("D9D2C2"), null, false)  # book drop
	Props.finish(desk, c["solids"], Vector3(2.6, 1.05, 0.6), Vector3(0, 0, 1.0), null, Vector3(0, 1.1, 0))
	_clerk(c, "library", "Mrs. Pennington", _p(c, 3.5, 3.1), {"gender": "girl", "hair": "bun", "adult": true, "top_style": "plain", "top": Color("6A5A9A"), "hair_rgb": Color("B8B0A8"), "skin_rgb": Color("F1CBA8"), "pants": Color("3B4E6E")}, 1.35, Vector2(9.0, 20.0))
	# Shelves
	_shelf(c, "library_fiction", "Fiction Shelves", 9.6, 4.2, 180, 4.0, 2.0, 0.3, books, 11)
	_shelf(c, "library_science", "Science & Nature", 9.6, 6.6, 180, 4.0, 2.0, 0.3, books, 12)
	_shelf(c, "library_kids", "Kids' Books", 13.55, 8.0, -90, 3.0, 1.3, 0.24, books, 13)
	_shelf(c, "", "", 6.0, 9.55, 180, 6.0, 2.2, 0.3, books, 14)
	# Card catalog
	var cat := _item(c, "card_catalog", "Card Catalog", "catalog", _p(c, 0.45, 4.0), 90)
	Props.part(cat, Vector3(1.0, 1.1, 0.5), Vector3(0, 0.55, 0), Palette.WOOD)
	for i in 4:
		for j in 3:
			Props.part(cat, Vector3(0.2, 0.2, 0.012), Vector3(-0.36 + i * 0.24, 0.3 + j * 0.27, 0.256), Palette.WOOD_DARK, null, false)
	Props.finish(cat, c["solids"], Vector3(1.0, 1.1, 0.5), Vector3(0, 0, 0.9), null, Vector3(0, 0.9, 0))
	# Reading tables
	_table(c, "reading_table_1", "Reading Table", 3.2, 6.0, Palette.WOOD)
	_table(c, "reading_table_2", "Reading Table", 3.2, 8.4, Palette.WOOD)
	var poster := Label3D.new()
	poster.text = "READ!"
	poster.font_size = 120
	poster.pixel_size = 0.004
	poster.modulate = Palette.CORAL
	poster.outline_size = 8
	poster.position = _p(c, 0.1, 7.2, 1.9)
	poster.rotation_degrees.y = 90.0
	c["root"].add_child(poster)


# ================================================================ the diner

static func _diner(c: Dictionary) -> void:
	# The counter with stools, and a cook behind it
	var ct := _item(c, "diner_counter", "Diner Counter", "counter", _p(c, 5.5, 7.4), 180)
	Props.part(ct, Vector3(6.0, 1.0, 0.6), Vector3(0, 0.5, 0), Color("E4704F"))
	Props.part(ct, Vector3(6.06, 0.05, 0.7), Vector3(0, 1.025, 0), Color("C8CCD0"))
	Props.part(ct, Vector3(0.5, 0.35, 0.4), Vector3(2.2, 1.22, -0.05), Color("BFE0EE"), null, false)   # pie case
	Props.part(ct, Vector3(0.35, 0.08, 0.35), Vector3(2.2, 1.16, -0.05), Palette.GOLD, null, false)
	for i in 5:
		Props.part(ct, Vector3(0.08, 0.7, 0.08), Vector3(-2.2 + i * 1.1, 0.35, 0.75), Color("C8CCD0"), null, false)
		Props.part(ct, Vector3(0.38, 0.1, 0.38), Vector3(-2.2 + i * 1.1, 0.72, 0.75), Palette.CORAL, null, false)
	Props.finish(ct, c["solids"], Vector3(6.0, 1.05, 0.6), Vector3(0, 0, 1.45), Vector3(0, 0, 0.75), Vector3(0, 1.1, 0))
	_clerk(c, "diner", "Sal the Cook", _p(c, 6.5, 8.3), {"gender": "boy", "hair": "buzz", "adult": true, "top_style": "plain", "top": Palette.PAPER, "hair_rgb": Color("3A2A22"), "skin_rgb": Color("C68B5F"), "pants": Color("3B4E6E")}, 1.55, Vector2(6.0, 15.0))
	# Order window to the kitchen
	RoomBuilder.box(c["root"], Vector3(2.0, 0.8, 0.05), _p(c, 5.5, 9.89, 1.6), Palette.INK2)
	# Booths along the left wall
	for i in 2:
		var b := _item(c, "diner_booth_%d" % (i + 1), "Booth", "booth", _p(c, 1.1, 2.8 + i * 2.6), 90)
		Props.part(b, Vector3(0.8, 0.05, 0.75), Vector3(0, 0.74, 0), Color("F2E8D8"))
		Props.part(b, Vector3(0.1, 0.72, 0.1), Vector3(0, 0.36, 0), Color("C8CCD0"), null, false)
		for sz in [-0.85, 0.85]:
			Props.part(b, Vector3(1.4, 0.45, 0.5), Vector3(0, 0.225, sz), Palette.TEAL)
			Props.part(b, Vector3(1.4, 0.6, 0.15), Vector3(0, 0.75, sz + signf(sz) * 0.2), Palette.TEAL.darkened(0.15))
		Props.finish(b, c["solids"], Vector3(1.4, 1.05, 2.2), Vector3(0, 0, -1.55), Vector3(0.1, 0, -0.85), Vector3(0, 0.8, 0))
	# Black-and-white clock on the back wall
	RoomBuilder.box(c["root"], Vector3(0.5, 0.5, 0.04), _p(c, 8.8, 9.9, 2.5), Palette.PAPER)


# ================================================================ the pizza place

static func _pizza(c: Dictionary) -> void:
	var r: Rect2 = c["r"]
	# The tall red roof that makes the place easy to spot from down the street
	var roof := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 1.0
	cm.height = 1.0
	cm.radial_segments = 4
	cm.rings = 1
	roof.mesh = cm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color("C0322A")
	rm.roughness = 0.8
	roof.material_override = rm
	roof.rotation_degrees.y = 45.0
	var g := Node3D.new()
	g.position = Vector3(r.get_center().x, H + 1.0, r.get_center().y)
	g.scale = Vector3((r.size.x + 1.2) / 1.414, 2.0, (r.size.y + 1.2) / 1.414)
	g.add_child(roof)
	c["root"].add_child(g)
	(c["out"]["ceilings"] as Array).append(g)
	var roof_sign := Label3D.new()
	roof_sign.text = "PIZZA PEAK"
	roof_sign.font_size = 110
	roof_sign.pixel_size = 0.006
	roof_sign.modulate = Palette.PAPER
	roof_sign.outline_size = 12
	roof_sign.outline_modulate = Color("7A1A14")
	# Painted right onto the front slope of the roof (it runs from 0.6 m out at the
	# eaves to halfway in at the top, over 2 m of height).
	var run := (r.size.y + 1.2) / 4.0
	var n := Vector3(0, run, -2.0).normalized()        # the slope's outward normal
	var sy := 0.95                                      # how far up the slope
	roof_sign.position = Vector3(r.get_center().x, H + sy, FRONT - 0.6 + run * sy / 2.0) + n * 0.03
	roof_sign.basis = Basis.looking_at(-n, Vector3.UP)
	roof_sign.double_sided = false
	g.get_parent().add_child(roof_sign)
	(c["out"]["ceilings"] as Array).append(roof_sign)
	# Order counter and the cook
	_counter(c, 8.6, 9.0, 3.4, Palette.WOOD_DARK, Palette.CORAL)
	_clerk(c, "pizza", "Tony", _p(c, 8.6, 9.6), {"gender": "boy", "hair": "cap", "adult": true, "top_style": "plain", "top": Color("C0322A"), "hair_rgb": Color("2A1A12"), "skin_rgb": Color("E2B98F"), "pants": Color("3B4E6E")}, 1.3, Vector2(11.0, 23.0))
	RoomBuilder.box(c["root"], Vector3(1.2, 0.8, 0.3), _p(c, 9.6, 9.75, 0.4), Color("8C8C8C"))     # pizza oven
	# Tables with red-checked cloths
	var check := Color("E85A4A")
	_table(c, "pizza_table_1", "Table", 2.4, 2.6, check)
	_table(c, "pizza_table_2", "Table", 2.4, 5.2, check)
	_table(c, "pizza_table_3", "Table", 2.4, 7.8, check)
	_table(c, "pizza_table_4", "Table", 6.0, 3.0, check)
	# Salad bar under a sneeze guard
	var sb := _item(c, "salad_bar", "Salad Bar", "salad_bar", _p(c, 6.2, 6.2), 180)
	Props.part(sb, Vector3(2.2, 0.9, 0.8), Vector3(0, 0.45, 0), Palette.WOOD)
	for i in 5:
		Props.part(sb, Vector3(0.32, 0.06, 0.5), Vector3(-0.8 + i * 0.4, 0.93, 0), [Color("6A9446"), Palette.CORAL, Palette.GOLD, Palette.PAPER, Color("B5322A")][i], null, false)
	Props.part(sb, Vector3(2.2, 0.03, 0.6), Vector3(0, 1.35, 0), Color("CFE8F0"), null, false)
	Props.finish(sb, c["solids"], Vector3(2.2, 1.0, 0.8), Vector3(0, 0, 1.0), null, Vector3(0, 1.0, 0))
	# Jukebox against the right wall
	var jb := _item(c, "jukebox", "Jukebox", "jukebox", _p(c, 10.55, 4.5), -90)
	Props.part(jb, Vector3(0.8, 1.4, 0.55), Vector3(0, 0.7, 0), Color("7A4A2E"))
	Props.glowing(jb, Vector3(0.6, 0.5, 0.012), Vector3(0, 1.1, 0.28), Palette.GOLD, 0.6)
	c["out"]["jukebox_mat"] = Props.glowing(jb, Vector3(0.7, 0.08, 0.012), Vector3(0, 0.6, 0.28), Palette.ROSE, 0.2)
	Props.finish(jb, c["solids"], Vector3(0.8, 1.4, 0.55), Vector3(0, 0, 0.95), null, Vector3(0, 1.0, 0))


# ================================================================ the video store

static func _video(c: Dictionary) -> void:
	var tapes := [Color("1A1C3A"), Color("2B2B2B"), Palette.CORAL, Palette.TEAL, Color("F7D046"), Palette.PAPER, Palette.ROSE]
	_shelf(c, "", "", 0.3, 4.5, 90, 6.0, 2.0, 0.19, tapes, 21)
	_shelf(c, "", "", 8.7, 4.5, -90, 6.0, 2.0, 0.19, tapes, 22)
	_shelf(c, "new_releases", "New Releases Wall", 4.5, 9.65, 180, 5.0, 2.1, 0.19, tapes, 23)
	_shelf(c, "horror_aisle", "Horror & Sci-Fi Aisle", 4.5, 5.6, 180, 3.0, 1.6, 0.19, tapes, 24)
	var label := Label3D.new()
	label.text = "NEW RELEASES"
	label.font_size = 64
	label.pixel_size = 0.004
	label.modulate = Color("F7D046")
	label.outline_size = 8
	label.position = _p(c, 4.5, 9.85, 2.5)
	label.rotation_degrees.y = 180.0
	c["root"].add_child(label)
	# The counter and the clerk, by the door
	var ct := _item(c, "video_counter", "Checkout Counter", "counter", _p(c, 7.2, 2.0), 180)
	Props.part(ct, Vector3(2.0, 1.0, 0.6), Vector3(0, 0.5, 0), Color("2B2F5A"))
	Props.part(ct, Vector3(2.06, 0.05, 0.66), Vector3(0, 1.025, 0), Color("F7D046"))
	Props.part(ct, Vector3(0.4, 0.2, 0.3), Vector3(-0.5, 1.15, 0), Palette.INK2, null, false)      # register
	Props.part(ct, Vector3(0.5, 0.3, 0.25), Vector3(0.55, 1.2, 0.1), Palette.CORAL, null, false)    # candy rack
	Props.finish(ct, c["solids"], Vector3(2.0, 1.05, 0.6), Vector3(0, 0, 1.0), null, Vector3(0, 1.1, 0))
	_clerk(c, "video", "Kyle", _p(c, 7.2, 2.7), {"gender": "boy", "hair": "mullet", "adult": true, "top_style": "plain", "top": Color("F7D046"), "hair_rgb": Color("6E3B22"), "skin_rgb": Color("F2C9A0"), "pants": Color("3B4E6E")}, 1.35, Vector2(10.0, 22.0))
	# A TV up on the wall playing trailers
	var tv := RoomBuilder.box(c["root"], Vector3(0.7, 0.5, 0.4), _p(c, 1.0, 9.6, 2.6), Palette.INK)
	var screen := Props.glowing(c["root"], Vector3(0.56, 0.4, 0.012), _p(c, 1.0, 9.395, 2.6), Palette.CRT, 0.5)
	c["out"]["trailer_mat"] = screen
	tv.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ================================================================ the arcade

const GAMES := [
	["Astro Blaster", Color("4FD8FF")], ["Ghost Maze", Color("F7D046")], ["Turbo Racer", Color("FF4F4F")],
	["Kung Fu Alley", Color("7FE07A")], ["Frog Crossing", Color("FF9A4F")], ["Dragon Tower", Color("C77DFF")],
]


static func _arcade(c: Dictionary) -> void:
	for i in GAMES.size():
		var left := i < 3
		var u := 0.5 if left else 9.5
		var d := 2.5 + (i % 3) * 2.2
		var g := _item(c, "arcade_%d" % (i + 1), GAMES[i][0], "arcade", _p(c, u, d), 90 if left else -90)
		var col: Color = GAMES[i][1]
		Props.part(g, Vector3(0.7, 1.8, 0.75), Vector3(0, 0.9, 0), Color("1A1424"))
		Props.part(g, Vector3(0.72, 1.0, 0.6), Vector3(0, 0.95, 0.01), col.darkened(0.55))            # side art
		c["out"]["arcade_%d_mat" % (i + 1)] = Props.glowing(g, Vector3(0.5, 0.42, 0.012), Vector3(0, 1.35, 0.31), col, 0.9)
		Props.glowing(g, Vector3(0.66, 0.16, 0.05), Vector3(0, 1.88, 0.32), col, 0.8)               # marquee
		Props.part(g, Vector3(0.66, 0.06, 0.25), Vector3(0, 1.0, 0.45), Palette.INK2, null, false)    # controls
		Props.part(g, Vector3(0.05, 0.08, 0.05), Vector3(-0.15, 1.07, 0.47), Palette.CORAL, null, false)
		var lbl := Label3D.new()
		lbl.text = String(GAMES[i][0]).to_upper()
		lbl.font_size = 40
		lbl.pixel_size = 0.0035
		lbl.modulate = Palette.PAPER
		lbl.outline_size = 6
		lbl.position = Vector3(0, 1.88, 0.35)
		g.add_child(lbl)
		Props.finish(g, c["solids"], Vector3(0.7, 1.95, 0.75), Vector3(0, 0, 0.95), Vector3(0, 0, 0.8), Vector3(0, 1.35, 0))
	# Pinball in the back
	var pb := _item(c, "pinball", "Space Cadet Pinball", "arcade", _p(c, 5.0, 9.2), 180)
	Props.part(pb, Vector3(0.7, 0.85, 1.3), Vector3(0, 0.6, 0), Color("2E2A6A"))
	c["out"]["pinball_mat"] = Props.glowing(pb, Vector3(0.6, 0.012, 1.15), Vector3(0, 1.03, 0), Color("4F6AFF"), 0.25)
	Props.glowing(pb, Vector3(0.66, 0.7, 0.08), Vector3(0, 1.35, -0.6), Color("FF4FD8"), 0.6)
	Props.finish(pb, c["solids"], Vector3(0.7, 1.7, 1.3), Vector3(0, 0, 1.2), Vector3(0, 0, 0.95), Vector3(0, 1.0, 0))
	# The change machine and the prize counter
	var cm := _item(c, "prize_counter", "Prize Counter", "counter", _p(c, 7.6, 9.4), 180)
	Props.part(cm, Vector3(1.8, 1.0, 0.6), Vector3(0, 0.5, 0), Color("1A1424"))
	Props.part(cm, Vector3(1.7, 0.85, 0.5), Vector3(0, 0.45, 0.03), Color("BFE0EE"))
	for i in 6:
		Props.part(cm, Vector3(0.14, 0.14, 0.14), Vector3(-0.6 + i * 0.24, 1.12, 0), [Palette.CORAL, Palette.GOLD, Palette.TEAL, Palette.ROSE, Palette.PAPER, Color("7FE07A")][i], null, false)
	Props.finish(cm, c["solids"], Vector3(1.8, 1.05, 0.6), Vector3(0, 0, 1.0), null, Vector3(0, 1.1, 0))
	_clerk(c, "arcade", "Tina", _p(c, 7.6, 9.85), {"gender": "girl", "hair": "side_pony", "adult": true, "top_style": "plain", "top": Color("FF4FD8"), "hair_rgb": Color("141212"), "skin_rgb": Color("C68B5F"), "pants": Color("3B4E6E")}, 1.15, Vector2(11.0, 23.0))
	# Colored lights
	Props.light(c["root"], c["out"], _p(c, 2.0, 5.0, 2.8), Color("FF4FD8"), 6.0, 0.6, 0.9, null, false)
	Props.light(c["root"], c["out"], _p(c, 8.0, 5.0, 2.8), Color("4FD8FF"), 6.0, 0.6, 0.9, null, false)


# ================================================================ opening hours

## When each shop is open (its door is locked the rest of the time). The clerk
## walks in a little before opening and goes home at closing time.
const SHOP_HOURS := {"library": Vector2(9.0, 20.0), "diner": Vector2(6.0, 15.0), "pizza": Vector2(11.0, 23.0),
	"video": Vector2(10.0, 22.0), "arcade": Vector2(11.0, 23.0), "bikes": Vector2(10.0, 18.0), "grocery": Vector2(8.0, 20.0)}
const SHOP_DAYS := {"bikes": [1, 2, 3, 4, 5, 6], "library": [1, 2, 3, 4, 5, 6]}


## A door main.gd locks outside opening hours: [{key, title, rect (the room), door (which
## swing door), doorway (Rect2 on the walking grid), hours, days}].
static func _register_door(out: Dictionary, key: String, title: String, r: Rect2, hours: Vector2, days: Array) -> void:
	if not out.has("shop_doors"):
		out["shop_doors"] = []
	var door: Dictionary = {}
	for d in out["swing_doors"]:
		if r.grow(0.3).has_point(Vector2((d["center"] as Vector3).x, (d["center"] as Vector3).z)):
			door = d
	(out["shop_doors"] as Array).append({"key": key, "title": title, "rect": r, "door": door, "hours": hours, "days": days})


# ================================================================ the bike shop

static func _bikes(c: Dictionary) -> void:
	var cols := [Color("C0322A"), Color("2E5E9E"), Color("F7D046"), Color("2E8C8A"), Color("FF4FD8")]
	# Bikes on display along the left wall, and the one in the window you can buy
	var disp := _item(c, "bike_display", "BMX Bikes", "bike_shop", _p(c, 2.2, 5.0), 90)
	for i in 3:
		_bike_model(disp, Vector3(0, 0, -1.6 + i * 1.6), cols[i], true)
	Props.finish(disp, c["solids"], Vector3(0.6, 1.0, 4.4), Vector3(0, 0, 1.3), null, Vector3(0, 0.7, 0))
	# Tires and tubes hanging on the back wall
	for i in 5:
		var t := RoomBuilder.box(c["root"], Vector3(0.6, 0.6, 0.06), _p(c, 1.5 + i * 1.3, 9.88, 2.4), Palette.INK)
		t.rotation.z = PI / 4.0
	# The repair stand, with a bike up on it
	var rs := _item(c, "bike_repair", "Repair Stand", "bike_repair", _p(c, 6.5, 6.5), 180)
	Props.part(rs, Vector3(0.08, 1.2, 0.08), Vector3(0, 0.6, 0), Palette.MUTED)
	Props.part(rs, Vector3(0.5, 0.06, 0.5), Vector3(0, 0.03, 0), Palette.INK2, null, false)
	_bike_model(rs, Vector3(0, 0.5, 0), cols[3], false)
	Props.finish(rs, c["solids"], Vector3(0.5, 1.4, 1.2), Vector3(0, 0, 1.1), null, Vector3(0, 1.0, 0))
	# Counter and the bike guy
	var ct := _item(c, "bike_counter", "Bike Shop Counter", "counter", _p(c, 6.2, 2.2), 180)
	Props.part(ct, Vector3(2.2, 1.0, 0.6), Vector3(0, 0.5, 0), Color("1F5A58"))
	Props.part(ct, Vector3(2.26, 0.05, 0.66), Vector3(0, 1.025, 0), Palette.WOOD)
	Props.part(ct, Vector3(0.4, 0.2, 0.3), Vector3(-0.6, 1.15, 0), Palette.INK2, null, false)
	Props.part(ct, Vector3(0.3, 0.12, 0.2), Vector3(0.5, 1.11, 0.05), Color("C0322A"), null, false)     # a bell for your handlebars
	Props.finish(ct, c["solids"], Vector3(2.2, 1.05, 0.6), Vector3(0, 0, 1.0), null, Vector3(0, 1.1, 0))
	_clerk(c, "bikes", "Spike", _p(c, 6.2, 2.9), {"gender": "boy", "hair": "spiky", "adult": true, "top_style": "plain",
		"top": Color("2E8C8A"), "hair_rgb": Color("D8B060"), "skin_rgb": Color("F2C9A0"), "pants": Color("2B2B30")}, 1.35, Vector2(10.0, 18.0))
	var poster := Label3D.new()
	poster.text = "BMX\nRAD!"
	poster.font_size = 96
	poster.pixel_size = 0.004
	poster.modulate = Color("FF4FD8")
	poster.outline_size = 8
	poster.position = _p(c, 8.31, 6.0, 1.9)
	poster.rotation_degrees.y = -90.0
	poster.double_sided = false
	c["root"].add_child(poster)


## A little BMX bike model (for the shop), built along local z.
static func _bike_model(o: Node3D, at: Vector3, col: Color, upright: bool) -> void:
	var g := Node3D.new()
	g.position = at
	if not upright:
		g.rotation_degrees.y = 90.0
	o.add_child(g)
	for wz in [-0.42, 0.42]:
		RoomBuilder.box(g, Vector3(0.05, 0.5, 0.5), Vector3(0, 0.27, wz), Palette.INK).rotation.x = PI / 4.0
		RoomBuilder.box(g, Vector3(0.06, 0.12, 0.12), Vector3(0, 0.27, wz), Palette.MUTED)
	RoomBuilder.box(g, Vector3(0.036, 0.05, 0.86), Vector3(0, 0.5, 0), col)
	RoomBuilder.box(g, Vector3(0.036, 0.4, 0.05), Vector3(0, 0.35, -0.42), col).rotation.x = -0.3
	RoomBuilder.box(g, Vector3(0.06, 0.06, 0.2), Vector3(0, 0.72, 0.18), Palette.INK)      # the seat
	RoomBuilder.box(g, Vector3(0.5, 0.04, 0.04), Vector3(0, 0.8, -0.44), Palette.MUTED)   # handlebars


# ================================================================ the grocery store

static func _grocery(c: Dictionary) -> void:
	var cans := [Color("C0322A"), Color("2E5E9E"), Color("F7D046"), Color("4F9A3A"), Palette.PAPER, Color("E4704F")]
	_shelf(c, "grocery_snacks", "Snack Aisle", 3.0, 5.2, 180, 4.0, 1.7, 0.2, cans, 31)
	_shelf(c, "grocery_canned", "Canned Goods", 3.0, 7.6, 180, 4.0, 1.7, 0.2, cans, 32)
	_shelf(c, "", "", 8.0, 9.6, 180, 4.0, 1.9, 0.2, cans, 33)
	# The freezer case, the produce stand and the checkout
	var fz := _item(c, "grocery_freezer", "Freezer Case", "freezer", _p(c, 10.05, 6.0), -90)
	Props.part(fz, Vector3(3.0, 0.9, 0.8), Vector3(0, 0.45, 0), Palette.PAPER)
	Props.part(fz, Vector3(2.9, 0.03, 0.7), Vector3(0, 0.915, 0), Color("BFE0EE"), null, false)
	for i in 6:
		Props.part(fz, Vector3(0.3, 0.12, 0.2), Vector3(-1.2 + i * 0.48, 0.82, 0.0), cans[i], null, false)
	Props.finish(fz, c["solids"], Vector3(3.0, 0.95, 0.8), Vector3(0, 0, 1.0), null, Vector3(0, 0.9, 0))
	var pr := _item(c, "grocery_produce", "Produce Stand", "produce", _p(c, 7.6, 4.6), 180)
	Props.part(pr, Vector3(2.0, 0.8, 1.0), Vector3(0, 0.4, 0), Palette.WOOD)
	for i in 8:
		Props.part(pr, Vector3(0.4, 0.14, 0.4), Vector3(-0.75 + (i % 4) * 0.5, 0.87, -0.22 + (i / 4) * 0.45),
			[Color("C0322A"), Color("F7D046"), Color("4F9A3A"), Color("E4704F")][i % 4], null, false)
	Props.finish(pr, c["solids"], Vector3(2.0, 0.95, 1.0), Vector3(0, 0, 1.1), null, Vector3(0, 0.9, 0))
	var ct := _item(c, "grocery_checkout", "Checkout Lane", "checkout", _p(c, 7.4, 2.0), 180)
	Props.part(ct, Vector3(2.4, 0.9, 0.7), Vector3(0, 0.45, 0), Color("C8A250"))
	Props.part(ct, Vector3(1.6, 0.03, 0.5), Vector3(0.3, 0.915, 0), Palette.INK2, null, false)   # the belt
	Props.part(ct, Vector3(0.4, 0.3, 0.35), Vector3(-0.8, 1.05, 0), Palette.INK2, null, false)  # register
	Props.part(ct, Vector3(0.5, 0.6, 0.06), Vector3(1.0, 1.2, 0.3), Color("F7D046"), null, false)   # the candy rack
	Props.finish(ct, c["solids"], Vector3(2.4, 1.0, 0.7), Vector3(0, 0, 1.05), null, Vector3(0, 1.0, 0))
	_clerk(c, "grocery", "Gloria", _p(c, 6.8, 2.75), {"gender": "girl", "hair": "perm", "adult": true, "top_style": "plain",
		"top": Color("C0322A"), "hair_rgb": Color("7A3A22"), "skin_rgb": Color("D9A07A"), "pants": Color("2B2B30")}, 1.45, Vector2(8.0, 20.0))
	# Shopping carts by the door
	for i in 3:
		var cart := Props.solid(c["root"], _p(c, 1.0 + i * 0.12, 1.0 + i * 0.05), 90)
		RoomBuilder.box(cart, Vector3(0.5, 0.45, 0.8), Vector3(0, 0.75, 0), Color("C8CCD0"))
		RoomBuilder.box(cart, Vector3(0.04, 0.6, 0.04), Vector3(0, 0.3, 0.3), Palette.MUTED)
		if i == 0:
			Props.finish(cart, c["solids"], Vector3(0.8, 1.0, 1.0), Vector3.ZERO)
	var sale := Label3D.new()
	sale.text = "SALE! CHEERIOS 99¢"
	sale.font_size = 64
	sale.pixel_size = 0.004
	sale.modulate = Color("C0322A")
	sale.outline_size = 8
	sale.outline_modulate = Palette.PAPER
	sale.position = _p(c, 5.25, 9.9, 2.6)
	sale.rotation_degrees.y = 180.0
	sale.double_sided = false
	c["root"].add_child(sale)


# ================================================================ the mall (not open yet)

# ================================================================ the Gazette

static func _gazette(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2]) -> void:
	var r := GAZETTE
	var hgt := 3.2
	var fz := r.end.y                 # the front, facing Main Street (+z)
	var dx := r.get_center().x
	RoomBuilder.make_floor(root, r, Color("8A7A6A"), tex["lino"])
	RoomBuilder.make_ceiling(root, out, r.grow(-T / 2.0), hgt)
	buildings.append(r)
	free.append(r.grow(-T / 2.0))
	doorways.append(Rect2(dx - 0.6, fz - 0.6, 1.2, 1.2))
	(out["town_rooms"] as Dictionary)["town|The Maple Grove Gazette"] = r
	var inside := Color("D9D2C2")
	var front := RoomBuilder.make_wall(root, "gazetteFront", Vector3(dx, 0, fz), Vector3(r.size.x + T, hgt, T), Vector3(0, 0, 1),
		tex, [{"c": dx, "w": 1.6, "h": 2.4}], false, inside, "panel")
	var back := RoomBuilder.make_wall(root, "gazetteBack", Vector3(dx, 0, r.position.y), Vector3(r.size.x + T, hgt, T), Vector3(0, 0, -1),
		tex, [], false, inside, "panel")
	var left := RoomBuilder.make_wall(root, "gazetteLeft", Vector3(r.position.x, 0, r.get_center().y), Vector3(T, hgt, r.size.y - T),
		Vector3(-1, 0, 0), tex, [], false, inside, "panel")
	var right := RoomBuilder.make_wall(root, "gazetteRight", Vector3(r.end.x, 0, r.get_center().y), Vector3(T, hgt, r.size.y - T),
		Vector3(1, 0, 0), tex, [], false, inside, "panel")
	var brick := Color("8A3A2E")
	RoomBuilder.add_siding(front, 1.0, hgt, tex, -INF, INF, true, true, brick, "brick")
	RoomBuilder.add_siding(back, -1.0, hgt, tex, -INF, INF, true, true, brick, "brick")
	RoomBuilder.add_siding(left, -1.0, hgt, tex, -INF, INF, true, true, brick, "brick")
	RoomBuilder.add_siding(right, 1.0, hgt, tex, -INF, INF, true, true, brick, "brick")
	for w in [front, back, left, right]:
		(out["walls"] as Array).append(w)
	RoomBuilder.make_casing(front, dx, 1.6, 2.4, Palette.INK2)
	(out["swing_doors"] as Array).append(HouseBuilder.make_double_door(front, dx, 1.6, 2.4, Color("2E4A3A"), Vector3(0, 0, -1)))
	RoomBuilder.make_floor(root, Rect2(dx - 0.8, fz, 1.6, 0.12), Palette.INK2)
	# a front step down to the sidewalk
	OutdoorBuilder._slab(root, Rect2(dx - 1.0, fz + 0.12, 2.0, Z0 - 1.6 - fz - 0.12), Color("CFC8BA"), tex["concrete"], 0.006)
	var glass: StandardMaterial3D = out["window_mat"]
	for side in [-1.0, 1.0]:
		var wx: float = dx + side * 1.85
		RoomBuilder.add_ext_window(front["full"], Vector3(wx, 1.45, fz + 0.125), Vector3(1.4, 1.3, 0.04), out)
		RoomBuilder.add_int_window(front["full"], Vector3(wx, 1.5, fz - T / 2.0), 1.3, 1.25, true, -1.0, glass)
	# The sign
	var board := RoomBuilder.box(front["full"], Vector3(5.2, 0.6, 0.08), Vector3(dx, 2.75, fz + 0.17), Color("1F1A1A"))
	board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label := Label3D.new()
	label.text = "THE MAPLE GROVE GAZETTE"
	label.font_size = 64
	label.pixel_size = 0.0042
	label.outline_size = 8
	label.modulate = Color("F2E8D8")
	label.position = Vector3(dx, 2.75, fz + 0.215)
	label.double_sided = false
	(front["full"] as Node3D).add_child(label)
	var roof := RoomBuilder.box(root, Vector3(r.size.x + 0.5, 0.2, r.size.y + 0.5), Vector3(dx, hgt + 0.1, r.get_center().y), Color("5A5550"))
	(out["ceilings"] as Array).append(roof)
	# Inside: the counter, Mr. Gruber's desk, bundles of papers, a press poster
	var ct := Props.solid(root, Vector3(dx + 0.6, 0, r.position.y + 2.6), 0)
	RoomBuilder.box(ct, Vector3(3.2, 1.0, 0.55), Vector3(0, 0.5, 0), Color("6B4429"))
	RoomBuilder.box(ct, Vector3(3.26, 0.05, 0.61), Vector3(0, 1.025, 0), Palette.WOOD_DARK)
	for i in 3:
		RoomBuilder.box(ct, Vector3(0.4, 0.14 + i * 0.002, 0.3), Vector3(-1.0 + i * 0.5, 1.12 + i * 0.001, 0.0), Palette.PAPER)   # paper bundles
	Props.finish(ct, solids, Vector3(3.2, 1.05, 0.55), Vector3.ZERO)
	var desk := Props.solid(root, Vector3(r.position.x + 1.0, 0, r.position.y + 0.8), 0)
	RoomBuilder.box(desk, Vector3(1.4, 0.75, 0.7), Vector3(0, 0.375, 0), Palette.WOOD)
	RoomBuilder.box(desk, Vector3(0.45, 0.3, 0.35), Vector3(0.2, 0.9, 0), Color("4A4A52"))   # typewriter
	Props.finish(desk, solids, Vector3(1.4, 1.0, 0.7), Vector3.ZERO)
	for i in 4:
		var stack := Props.solid(root, Vector3(r.end.x - 0.45, 0, r.position.y + 0.5 + i * 0.55), 0)
		RoomBuilder.box(stack, Vector3(0.5, 0.35 + (i % 2) * 0.15, 0.4), Vector3(0, 0.2 + (i % 2) * 0.075, 0), Palette.PAPER)
		RoomBuilder.box(stack, Vector3(0.52, 0.02, 0.06), Vector3(0, 0.3 + (i % 2) * 0.1, 0), Palette.CORAL)
		Props.finish(stack, solids, Vector3(0.5, 0.5, 0.4), Vector3.ZERO)
	var poster := Label3D.new()
	poster.text = "EXTRA! EXTRA!\nREAD ALL ABOUT IT"
	poster.font_size = 56
	poster.pixel_size = 0.004
	poster.modulate = Palette.INK
	poster.position = Vector3(r.position.x + 0.09, 1.8, r.get_center().y + 1.2)
	poster.rotation_degrees.y = 90.0
	root.add_child(poster)
	Props.light(root, out, Vector3(dx, hgt - 0.5, r.get_center().y), Color("FFF1D6"), 7.0, 0.9, 1.8, null, false)
	# Kids' bikes parked out front
	for i in 2:
		var bike := Props.solid(root, Vector3(r.position.x + 0.7 + i * 1.0, 0, fz + 0.9), 90)
		RoomBuilder.box(bike, Vector3(0.05, 0.5, 0.5), Vector3(0, 0.3, -0.35), Palette.INK)
		RoomBuilder.box(bike, Vector3(0.05, 0.5, 0.5), Vector3(0, 0.3, 0.35), Palette.INK)
		RoomBuilder.box(bike, Vector3(0.06, 0.06, 0.8), Vector3(0, 0.55, 0), [Palette.CORAL, Palette.TEAL][i])
		RoomBuilder.box(bike, Vector3(0.4, 0.05, 0.05), Vector3(0, 0.85, 0.35), Palette.MUTED)
		Props.finish(bike, solids, Vector3(0.2, 0.9, 1.2), Vector3.ZERO)
	out["gazette_spot"] = [Vector3(dx + 0.6, 0, r.position.y + 1.95), 0.0]


## Frosty's: a little walk-up ice cream stand with a giant cone on the roof.
static func _frostys(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2]) -> void:
	var r := FROSTYS
	var cx := r.get_center().x
	var hgt := 2.5
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	root.add_child(body)
	var pink := Color("F2A0B5")
	var white := Palette.PAPER
	# Back and side walls, and the front below and above the serving window
	var parts := [
		[Vector3(r.size.x, hgt, 0.12), Vector3(cx, hgt / 2.0, r.position.y + 0.06), pink],
		[Vector3(0.12, hgt, r.size.y - 0.24), Vector3(r.position.x + 0.06, hgt / 2.0, r.get_center().y), white],
		[Vector3(0.12, hgt, r.size.y - 0.24), Vector3(r.end.x - 0.06, hgt / 2.0, r.get_center().y), white],
		[Vector3(r.size.x, 1.0, 0.12), Vector3(cx, 0.5, r.end.y - 0.06), pink],
		[Vector3(r.size.x, 0.45, 0.12), Vector3(cx, hgt - 0.225, r.end.y - 0.06), pink],
	]
	for p in parts:
		RoomBuilder.box(body, p[0], p[1], p[2])
		RoomBuilder.add_shape(body, p[0], p[1])
	# A floor inside, the roof and the counter ledge
	RoomBuilder.box(body, Vector3(r.size.x - 0.24, 0.04, r.size.y - 0.24), Vector3(cx, 0.02, r.get_center().y), Color("D9D2C2"))
	var roof := RoomBuilder.box(root, Vector3(r.size.x + 0.4, 0.15, r.size.y + 0.4), Vector3(cx, hgt + 0.075, r.get_center().y), white)
	(out["ceilings"] as Array).append(roof)
	RoomBuilder.box(body, Vector3(r.size.x - 0.4, 0.06, 0.4), Vector3(cx, 1.03, r.end.y + 0.08), Color("C8CCD0"))
	# A striped awning over the window
	for i in 6:
		var stripe := RoomBuilder.box(body, Vector3((r.size.x + 0.2) / 6.0 - 0.004, 0.05, 0.9), Vector3(r.position.x - 0.1 + (i + 0.5) * (r.size.x + 0.2) / 6.0, hgt - 0.35, r.end.y + 0.4),
			pink if i % 2 == 0 else white)
		stripe.rotation_degrees.x = 14.0
	# The giant cone on the roof
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.42
	cm.bottom_radius = 0.02
	cm.height = 1.1
	cone.mesh = cm
	var wafer := StandardMaterial3D.new()
	wafer.albedo_color = Color("D9A35A")
	cone.material_override = wafer
	cone.position = Vector3(cx, hgt + 0.7, r.get_center().y)
	body.add_child(cone)
	var scoop := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 0.85
	scoop.mesh = sm
	var cream := StandardMaterial3D.new()
	cream.albedo_color = pink
	scoop.material_override = cream
	scoop.position = Vector3(cx, hgt + 1.45, r.get_center().y)
	body.add_child(scoop)
	(out["ceilings"] as Array).append(cone)
	(out["ceilings"] as Array).append(scoop)
	var label := Label3D.new()
	label.text = "FROSTY'S"
	label.font_size = 64
	label.pixel_size = 0.004
	label.outline_size = 10
	label.modulate = Color("2E8C8A")
	label.outline_modulate = Palette.PAPER
	label.position = Vector3(cx, hgt - 0.1, r.end.y + 0.005)
	body.add_child(label)
	var menu := Label3D.new()
	menu.text = "SOFT-SERVE 75¢   PUSH-UP POP 50¢   BANANA SPLIT $2.25"
	menu.font_size = 28
	menu.pixel_size = 0.0035
	menu.modulate = Palette.INK
	menu.position = Vector3(cx, 0.75, r.end.y + 0.005)
	body.add_child(menu)
	# A freezer and a light inside
	RoomBuilder.box(body, Vector3(1.4, 0.9, 0.6), Vector3(cx - 0.6, 0.45, r.position.y + 0.45), Color("BFE0EE"))
	Props.light(root, out, Vector3(cx, hgt - 0.4, r.get_center().y), Color("FFF1D6"), 4.5, 0.6, 1.6, null, false)
	solids.append(r)
	out["frostys_spot"] = [Vector3(cx + 0.5, 0, r.end.y - 0.55), 0.0]
	# A bench out front
	var bench := Props.solid(root, Vector3(r.end.x + 1.4, 0, r.end.y + 0.3), 0)
	RoomBuilder.box(bench, Vector3(1.4, 0.06, 0.42), Vector3(0, 0.45, 0), pink)
	RoomBuilder.box(bench, Vector3(0.08, 0.45, 0.38), Vector3(-0.6, 0.225, 0), Palette.INK2)
	RoomBuilder.box(bench, Vector3(0.08, 0.45, 0.38), Vector3(0.6, 0.225, 0), Palette.INK2)
	Props.finish(bench, solids, Vector3(1.4, 0.5, 0.42), Vector3.ZERO)


# ================================================================ the drive-in

static func _drive_in(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2]) -> void:
	var r := DRIVE_IN
	var objects: Dictionary = out["objects"]
	OutdoorBuilder._slab(root, r, Color("9A9184"), tex["asphalt"], 0.012)          # the gravel lot
	# The big screen at the south end, facing the lot (north)
	var sz := r.end.y - 0.6
	var sx0 := r.position.x + 1.0
	var sx1 := r.end.x - 1.0
	var cx := (sx0 + sx1) / 2.0
	var frame := Props.solid(root, Vector3(cx, 0, sz), 0)
	for x in [sx0 + 0.4 - cx, 0.0, sx1 - 0.4 - cx]:
		RoomBuilder.box(frame, Vector3(0.4, 8.6, 0.4), Vector3(x, 4.3, 0.45), Palette.WOOD_DARK)          # the legs behind
		RoomBuilder.box(frame, Vector3(0.25, 0.25, 2.2), Vector3(x, 3.0, 1.2), Palette.WOOD_DARK).rotation.x = 0.6   # braces
	RoomBuilder.box(frame, Vector3(sx1 - sx0 + 0.4, 6.3, 0.2), Vector3(0, 5.3, 0.15), Color("3A3A40"))    # the back
	var screen := RoomBuilder.box(frame, Vector3(sx1 - sx0, 5.7, 0.04), Vector3(0, 5.3, 0.03), Color("E8E4DA"))
	var sm: StandardMaterial3D = screen.material_override
	sm.emission_enabled = true
	sm.emission = Color("E8E4DA")
	sm.emission_energy_multiplier = 0.0
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	out["drivein_screen_mat"] = sm
	Props.finish(frame, solids, Vector3(sx1 - sx0 + 0.6, 8.6, 0.8), Vector3.ZERO, null, null, Vector3(0, 4.3, 0.3))
	var glow := OmniLight3D.new()
	glow.position = Vector3(cx, 4.5, sz - 4.0)
	glow.omni_range = 16.0
	glow.light_energy = 0.0
	glow.shadow_enabled = false
	root.add_child(glow)
	out["drivein_light"] = glow
	# The marquee by the entrance, facing Maple Street
	var mq := Props.solid(root, Vector3(r.position.x + 6.5, 0, r.position.y + 0.4), 0)
	RoomBuilder.box(mq, Vector3(0.2, 4.4, 0.2), Vector3(-1.7, 2.2, 0), Palette.MUTED)
	RoomBuilder.box(mq, Vector3(0.2, 4.4, 0.2), Vector3(1.7, 2.2, 0), Palette.MUTED)
	var board := RoomBuilder.box(mq, Vector3(4.2, 1.6, 0.25), Vector3(0, 4.4, 0), Color("1A1C3A"))
	var bm: StandardMaterial3D = board.material_override
	bm.emission_enabled = true
	bm.emission = Color("2B2F5A")
	bm.emission_energy_multiplier = 0.4
	for side in [-1.0, 1.0]:
		var lbl := Label3D.new()
		lbl.text = "STARLITE\nDRIVE-IN"
		lbl.font_size = 96
		lbl.pixel_size = 0.0055
		lbl.outline_size = 12
		lbl.modulate = Color("FF7AC8")
		lbl.outline_modulate = Color("4FD8FF")
		lbl.position = Vector3(0, 4.45, side * 0.14)
		lbl.rotation_degrees.y = 0.0 if side > 0 else 180.0
		lbl.double_sided = false
		mq.add_child(lbl)
	var tonight := Label3D.new()
	tonight.text = "SHOWS NIGHTLY 8 PM - 1 AM"
	tonight.font_size = 44
	tonight.pixel_size = 0.004
	tonight.modulate = Color("F7D046")
	tonight.position = Vector3(0, 3.42, -0.14)
	tonight.rotation_degrees.y = 180.0
	tonight.double_sided = false
	mq.add_child(tonight)
	Props.finish(mq, solids, Vector3(3.8, 4.4, 0.3), Vector3.ZERO)
	# Two rows of parking spaces, each one wide and long enough for a car, with a
	# speaker post at its left. (No car? Spread a blanket in the space and watch.)
	var i := 0
	var slot_w := 3.1
	var slot_l := 5.2
	for z in [r.position.y + 6.6, r.position.y + 12.0]:
		for k in 4:
			if k == 0 and z < r.position.y + 7.0:
				continue     # (the snack bar's in that corner)
			i += 1
			var x0 := r.position.x + 0.3 + k * slot_w
			var post := Props.item(root, objects, "drivein_speaker_%d" % i, "Speaker Post", Vector3(x0, 0, z), 0)
			post.kind = "drivein_speaker"
			post.home = "town"
			post.shared = true
			Props.part(post, Vector3(0.1, 1.0, 0.1), Vector3(0, 0.5, 0), Palette.MUTED)
			Props.part(post, Vector3(0.3, 0.22, 0.16), Vector3(0, 1.05, 0), Color("6A6A70"))
			Props.part(post, Vector3(0.22, 0.14, 0.02), Vector3(0, 1.05, 0.085), Palette.INK2, null, false)
			# the painted lines of the space (it runs from the post back toward Maple Street)
			for lx in [x0 + 0.12, x0 + slot_w - 0.12]:
				OutdoorBuilder._slab(root, Rect2(lx - 0.05, z - slot_l + 0.3, 0.1, slot_l - 0.3), Palette.PAPER, null, 0.016)
			Props.finish(post, solids, Vector3(0.3, 1.2, 0.2), Vector3(1.4, 0, -1.2), Vector3(1.4, 0, -0.6), Vector3(cx - x0, 5.0, sz - z))
			post.set_meta("car_spot", Vector3(x0 + slot_w / 2.0, 0, z - slot_l / 2.0))
	# The snack bar (Lou sells popcorn), in the north-west corner
	var sb := Props.solid(root, Vector3(r.position.x + 1.6, 0, r.position.y + 1.4), 0)
	RoomBuilder.box(sb, Vector3(2.6, 2.4, 2.0), Vector3(0, 1.2, -0.3), Color("E4704F"))
	RoomBuilder.box(sb, Vector3(3.0, 0.15, 2.6), Vector3(0, 2.47, -0.2), Palette.PAPER)
	RoomBuilder.box(sb, Vector3(2.6, 1.0, 0.5), Vector3(0, 0.5, 1.45), Color("C2572F"))          # the counter
	RoomBuilder.box(sb, Vector3(2.7, 0.06, 0.6), Vector3(0, 1.03, 1.45), Palette.PAPER)
	var pop := Label3D.new()
	pop.text = "POPCORN · SODA · CANDY"
	pop.font_size = 40
	pop.pixel_size = 0.004
	pop.modulate = Palette.PAPER
	pop.outline_size = 8
	pop.outline_modulate = Color("7A2E2A")
	pop.position = Vector3(0, 2.0, 0.705)
	sb.add_child(pop)
	Props.finish(sb, solids, Vector3(2.7, 2.4, 2.9), Vector3.ZERO, null, null, Vector3(0, 1.2, 0.2))
	out["snackbar_spot"] = [Vector3(r.position.x + 1.6, 0, r.position.y + 1.4 + 0.95), 0.0]
