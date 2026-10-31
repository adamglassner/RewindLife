class_name KitchenBuilder
extends RefCounted
## The kitchen and dining room, south of the stairwell and east of the bedroom:
##
##   z=3.95  +---[door from the stairwell]------+
##           | phone            fridge  |  east wall:
##           | calendar     cookie jar  |  counter, microwave,
##           |                microwave |  sink (under the window),
##           |                   sink   |  stove with a hood
##           |                  stove   |
##   z=7.8   |      DINING              |
##           |   chair  table  chair    |
##   z=10.5  +-------[window]-----------+
##        x=12.8                     x=16.2

const T := 0.15
const KX0 := 12.8     # kitchen inside: west face (the bedroom's east wall)
const KX1 := 16.2     # inside east face
const KZ0 := 3.95     # inside north face (the stairwell's south wall)
const KZ1 := 10.5     # inside south face
const DOOR_X := 14.85 # the door from the stairwell


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2], hall_s: Dictionary, st_s: Dictionary, be: Dictionary) -> void:
	var objects: Dictionary = out["objects"]
	var walls: Array = out["walls"]
	var glass_mat: StandardMaterial3D = out["window_mat"]
	var H := RoomBuilder.H
	var BX1 := HouseBuilder.BX1

	# ---------------------------------------------------------------- the room
	RoomBuilder.make_floor(root, Rect2(KX0, KZ0, KX1 - KX0, KZ1 - KZ0), Color.WHITE, tex["lino"])
	RoomBuilder.make_floor(root, Rect2(DOOR_X - 0.45, KZ0 - T, 0.9, T), Palette.WOOD_DARK)   # threshold
	free.append(Rect2(KX0, KZ0, KX1 - KX0, KZ1 - KZ0))
	doorways.append(Rect2(DOOR_X - 0.35, 3.4, 0.7, 1.0))
	buildings.append(Rect2(BX1, HouseBuilder.BZ1 + T, KX1 + T - BX1, KZ1 + T - (HouseBuilder.BZ1 + T)))

	var ke := RoomBuilder.make_wall(root, "KitEast", Vector3(KX1 + T / 2, 0, (KZ0 + KZ1 + T) / 2), Vector3(T, H, KZ1 + T - KZ0),
		Vector3(1, 0, 0), tex, [], false, Color.WHITE, "kitchen")
	var ks := RoomBuilder.make_wall(root, "KitSouth", Vector3((BX1 + KX1 + T) / 2, 0, KZ1 + T / 2), Vector3(KX1 + T - BX1, H, T),
		Vector3(0, 0, 1), tex, [], false, Color.WHITE, "kitchen")
	var bz := HouseBuilder.BZ1 + T
	var kw := RoomBuilder.make_wall(root, "KitWest", Vector3(BX1 + T / 2, 0, (bz + KZ1 + T) / 2), Vector3(T, H, KZ1 + T - bz),
		Vector3(-1, 0, 0), tex, [], false, Color.WHITE, "kitchen")
	walls.append_array([ke, ks, kw])
	RoomBuilder.make_ceiling(root, out, Rect2(KX0, KZ0, KX1 - KX0, KZ1 - KZ0), H)

	# The kitchen sides of the walls it shares with the hallway, stairwell and bedroom
	var d0 := DOOR_X - 0.45
	var d1 := DOOR_X + 0.45
	RoomBuilder.add_skin(hall_s, 1.0, KX0, HouseBuilder.HX1, 0.18, H - 0.08, tex, "kitchen")
	for seg in [[HouseBuilder.HX1, d0], [d1, KX1]]:
		RoomBuilder.add_skin(st_s, 1.0, seg[0], seg[1], 0.18, H - 0.08, tex, "kitchen")
	RoomBuilder.add_skin(st_s, 1.0, d0, d1, 2.1, H - 0.08, tex, "kitchen")
	_baseboard(be, 1.0, KZ0, bz)
	RoomBuilder.add_skin(be, 1.0, KZ0, bz, 0.18, H - 0.08, tex, "kitchen")

	# The door in from the stairwell (a real one, swinging into the kitchen)
	RoomBuilder.make_casing(st_s, DOOR_X, 0.9, 2.1, Palette.CREAM)
	(out["swing_doors"] as Array).append(HouseBuilder.make_swing_door(st_s, DOOR_X, 0.9, 2.1, Palette.CREAM, Vector3(0, 0, 1), false))

	# Windows: over the sink, and two in the dining room
	RoomBuilder.add_int_window(ke["full"], Vector3(KX1, 1.55, 6.05), 1.0, 0.8, false, -1.0, glass_mat)
	RoomBuilder.add_ext_window(ke["full"], Vector3(KX1 + T + 0.02, 1.55, 6.05), Vector3(0.04, 0.8, 1.0), out)
	RoomBuilder.add_int_window(ks["full"], Vector3(14.3, 1.5, KZ1), 1.4, 1.0, true, -1.0, glass_mat)
	RoomBuilder.add_ext_window(ks["full"], Vector3(14.3, 1.5, KZ1 + T + 0.02), Vector3(1.4, 1.0, 0.04), out)
	RoomBuilder.add_int_window(kw["full"], Vector3(KX0, 1.5, 9.65), 0.9, 0.9, false, 1.0, glass_mat)
	RoomBuilder.add_ext_window(kw["full"], Vector3(BX1 - 0.02, 1.5, 9.65), Vector3(0.04, 0.9, 0.9), out)

	# Outside: siding and a roof (ridge running north-south)
	RoomBuilder.add_siding(ke, 1.0, H, tex)
	RoomBuilder.add_siding(ks, 1.0, H, tex)
	RoomBuilder.add_siding(kw, -1.0, H, tex, -INF, INF, false, true)
	_roof(root, out, BX1, KX1 + T + 0.35, KZ0, KZ1 + T + 0.35, H)

	# Lights: a fluorescent panel in the kitchen, a hanging lamp over the table
	var panel := RoomBuilder.box(root, Vector3(1.0, 0.06, 0.4), Vector3(14.6, H - 0.11, 5.9), Palette.PAPER)
	var fl: StandardMaterial3D = panel.material_override
	fl.emission_enabled = true
	fl.emission = Color("FFF1D6")
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(out["ceilings"] as Array).append(panel)   # hidden in the House Cam, like the ceiling
	Props.light(root, out, Vector3(14.6, 2.2, 5.9), Color("FFF1D6"), 6.5, 0.7, 1.2, fl)
	RoomBuilder.box(root, Vector3(0.02, 0.5, 0.02), Vector3(14.3, H - 0.33, 9.0), Palette.INK)
	var shade := Props.glowing(root, Vector3(0.46, 0.22, 0.46), Vector3(14.3, 1.97, 9.0), Palette.LAMP, 0.3)
	Props.light(root, out, Vector3(14.3, 1.7, 9.0), Palette.LAMP, 5.0, 0.3, 1.3, shade)

	_build_kitchen(root, out, tex, solids, objects)
	_build_dining(root, out, tex, solids, objects)


## A baseboard strip on one face of a wall (side +1/-1), from a to b along it.
static func _baseboard(wall: Dictionary, side: float, a: float, b: float) -> void:
	var pl: float = float(wall["plane"]) + side * (float(wall["thick"]) / 2.0 + 0.008)
	RoomBuilder._span(wall["full"], null, wall["along_x"], pl, a + 0.003, b - 0.003, 0.0, 0.18, 0.016, Palette.WOOD_DARK)


## A gable roof whose ridge runs north-south (along z).
static func _roof(root: Node3D, out: Dictionary, x0: float, x1: float, z0: float, z1: float, eave: float) -> void:
	var g := Node3D.new()
	root.add_child(g)
	var rise := (x1 - x0) / 2.0 * 0.5
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(x1 - x0, rise, z1 - z0)
	mi.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = RoomBuilder.ROOF
	mat.roughness = 0.95
	mi.material_override = mat
	mi.position = Vector3((x0 + x1) / 2.0, eave + rise / 2.0, (z0 + z1) / 2.0)
	g.add_child(mi)
	RoomBuilder.box(g, Vector3(0.06, 0.12, z1 - z0), Vector3(x1 - 0.03, eave - 0.02, (z0 + z1) / 2.0), RoomBuilder.TRIM)
	(out["ceilings"] as Array).append(g)


# ---------------------------------------------------------------- kitchen

static func _build_kitchen(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], objects: Dictionary) -> void:
	var cab := Color("8A5A3B")          # wood cabinets
	var top := Color("E9DCC0")          # almond countertop

	# ---- Fridge (moved in from the living room), front facing the room (-x)
	var fr := Props.item(root, objects, "fridge", "Fridge", Vector3(KX1 - 0.36, 0, 4.45), -90)
	Props.part(fr, Vector3(0.8, 1.8, 0.72), Vector3(0, 0.9, 0), Palette.GOLD)
	Props.part(fr, Vector3(0.82, 0.025, 0.02), Vector3(0, 1.3, 0.37), Palette.INK, null, false)
	Props.part(fr, Vector3(0.04, 0.28, 0.05), Vector3(0.33, 1.55, 0.385), Palette.MUTED, null, false)
	Props.part(fr, Vector3(0.04, 0.28, 0.05), Vector3(0.33, 0.95, 0.385), Palette.MUTED, null, false)
	Props.part(fr, Vector3(0.08, 0.08, 0.012), Vector3(-0.2, 1.62, 0.366), Palette.CORAL, null, false)   # magnets
	Props.part(fr, Vector3(0.08, 0.08, 0.012), Vector3(-0.04, 1.5, 0.366), Palette.CRT, null, false)
	Props.part(fr, Vector3(0.22, 0.28, 0.006), Vector3(-0.15, 0.95, 0.363), Palette.PAPER, null, false)  # a drawing
	Props.part(fr, Vector3(0.12, 0.08, 0.008), Vector3(-0.17, 0.98, 0.37), Palette.ROSE, null, false)
	Props.finish(fr, solids, Vector3(0.8, 1.8, 0.72), Vector3(0, 0, 0.95), null, Vector3(0, 1.1, 0))

	# ---- Counter run along the east wall
	for seg in [[4.9, 6.6], [7.36, 7.8]]:
		var length: float = seg[1] - seg[0]
		var c := Props.solid(root, Vector3(KX1 - 0.31, 0, (seg[0] + seg[1]) / 2.0), -90)
		Props.part(c, Vector3(length, 0.86, 0.6), Vector3(0, 0.43, -0.01), cab, tex["panel"])
		Props.part(c, Vector3(length + 0.04, 0.04, 0.64), Vector3(0, 0.88, 0), top)
		var doors := int(round(length / 0.42))
		for i in doors:
			var x := -length / 2.0 + (i + 0.5) * length / doors
			Props.part(c, Vector3(length / doors - 0.04, 0.62, 0.012), Vector3(x, 0.44, 0.296), cab.darkened(0.15))
			Props.part(c, Vector3(0.03, 0.08, 0.03), Vector3(x + 0.12, 0.66, 0.31), Palette.GOLD)
		Props.finish(c, solids, Vector3(length, 0.9, 0.62), Vector3.ZERO)
	# Upper cabinets (around the window), and over the stove's hood
	for seg in [[4.9, 5.42, 1.45], [7.36, 7.8, 1.45], [6.6, 7.36, 1.95]]:
		var zc: float = (seg[0] + seg[1]) / 2.0
		var zl: float = seg[1] - seg[0]
		var y0: float = seg[2]
		var hgt := 2.15 - y0 if y0 < 1.9 else 0.5
		RoomBuilder.box(root, Vector3(0.33, hgt, zl), Vector3(KX1 - 0.165, y0 + hgt / 2.0, zc), cab, tex["panel"], 2.0)
		RoomBuilder.box(root, Vector3(0.012, hgt - 0.08, zl - 0.06), Vector3(KX1 - 0.336, y0 + hgt / 2.0, zc), cab.darkened(0.15))

	# ---- Microwave on the counter
	var mw := Props.item(root, objects, "microwave", "Microwave", Vector3(KX1 - 0.34, 0, 5.2), -90)
	Props.part(mw, Vector3(0.52, 0.3, 0.36), Vector3(0, 1.05, 0), Color("D9D2C2"))
	Props.part(mw, Vector3(0.528, 0.034, 0.36), Vector3(0, 1.186, 0.012), Palette.WOOD, null, false)   # faux woodgrain trim
	var window := Props.glowing(mw, Vector3(0.32, 0.19, 0.012), Vector3(-0.07, 1.04, 0.186), Color("2A2A2A"), 0.0)
	out["microwave_mat"] = window
	Props.part(mw, Vector3(0.12, 0.22, 0.012), Vector3(0.18, 1.04, 0.186), Palette.INK2, null, false)
	Props.glowing(mw, Vector3(0.09, 0.03, 0.006), Vector3(0.18, 1.12, 0.195), Color("7FE07A"), 0.4)
	Props.finish(mw, solids, Vector3(0.52, 0.3, 0.36), Vector3(0, 0, 0.85), null, Vector3(0, 1.05, 0), Vector3(0, 1.05, 0))

	# ---- Sink, under the window
	var sk := Props.item(root, objects, "sink", "Kitchen Sink", Vector3(KX1 - 0.31, 0, 6.05), -90)
	Props.part(sk, Vector3(0.56, 0.02, 0.4), Vector3(0, 0.905, 0.02), Color("9AA3A8"))
	Props.part(sk, Vector3(0.48, 0.012, 0.32), Vector3(0, 0.914, 0.02), Color("6E777C"), null, false)
	Props.part(sk, Vector3(0.04, 0.26, 0.04), Vector3(0, 1.03, -0.2), Palette.MUTED)
	Props.part(sk, Vector3(0.04, 0.04, 0.18), Vector3(0, 1.15, -0.12), Palette.MUTED)
	Props.part(sk, Vector3(0.06, 0.16, 0.06), Vector3(0.22, 0.98, -0.2), Color("7FC97F"), null, false)  # dish soap
	Props.finish(sk, solids, Vector3(0.6, 0.3, 0.5), Vector3(0, 0, 0.95), null, Vector3(0, 0.95, 0), Vector3(0, 1.05, 0))

	# ---- Stove with a range hood
	var st := Props.item(root, objects, "stove", "Stove", Vector3(KX1 - 0.32, 0, 6.98), -90)
	Props.part(st, Vector3(0.76, 0.89, 0.62), Vector3(0, 0.445, -0.01), Palette.GOLD)
	Props.part(st, Vector3(0.5, 0.25, 0.012), Vector3(0, 0.45, 0.306), Palette.INK, null, false)
	Props.part(st, Vector3(0.55, 0.03, 0.04), Vector3(0, 0.66, 0.32), Palette.MUTED, null, false)
	Props.part(st, Vector3(0.74, 0.012, 0.6), Vector3(0, 0.906, -0.01), Palette.INK, null, false)
	for bx in [-0.18, 0.18]:
		for bzz in [-0.15, 0.12]:
			Props.part(st, Vector3(0.18, 0.012, 0.18), Vector3(bx, 0.918, bzz), Color("3A3A3A"), null, false)
	out["burner_mat"] = Props.glowing(st, Vector3(0.12, 0.004, 0.12), Vector3(0.18, 0.926, 0.12), Palette.CORAL, 0.0)
	Props.part(st, Vector3(0.2, 0.14, 0.2), Vector3(-0.18, 0.994, 0.12), Palette.MUTED, null, false)       # a pot
	Props.part(st, Vector3(0.76, 0.14, 0.05), Vector3(0, 0.98, -0.295), Palette.GOLD)                     # backsplash
	for kx in [-0.27, -0.09, 0.09, 0.27]:
		Props.part(st, Vector3(0.04, 0.04, 0.02), Vector3(kx, 0.98, -0.26), Palette.INK, null, false)
	Props.part(st, Vector3(0.76, 0.22, 0.5), Vector3(0, 1.78, -0.06), Palette.GOLD, null, false)          # hood
	Props.finish(st, solids, Vector3(0.76, 0.92, 0.62), Vector3(0, 0, 0.95), null, Vector3(0, 0.95, 0))

	# ---- Cookie jar
	var cj := Props.item(root, objects, "cookie_jar", "Cookie Jar", Vector3(KX1 - 0.36, 0, 7.6), -90)
	Props.part(cj, Vector3(0.18, 0.22, 0.18), Vector3(0, 1.01, 0), Palette.ROSE)
	Props.part(cj, Vector3(0.2, 0.04, 0.2), Vector3(0, 1.14, 0), Palette.CREAM)
	Props.part(cj, Vector3(0.05, 0.04, 0.05), Vector3(0, 1.18, 0), Palette.CREAM)
	Props.finish(cj, solids, Vector3(0.2, 0.3, 0.2), Vector3(0, 0, 1.0), null, Vector3(0, 1.0, 0), Vector3(0, 1.05, 0))

	# ---- The wall phone (moved in from the living room) and a 1986 calendar
	var ph := Props.item(root, objects, "phone", "Kitchen Wall Phone", Vector3(KX0 + 0.006, 0, 5.0), 90)
	Props.part(ph, Vector3(0.26, 0.42, 0.1), Vector3(0, 1.35, 0.05), Palette.GOLD)
	Props.part(ph, Vector3(0.34, 0.1, 0.12), Vector3(0, 1.6, 0.09), Color("F2C25E"))
	Props.part(ph, Vector3(0.14, 0.14, 0.02), Vector3(0, 1.32, 0.11), Palette.WOOD_DARK, null, false)
	Props.part(ph, Vector3(0.02, 0.7, 0.02), Vector3(0.06, 0.85, 0.12), Color("A8714A"), null, false)
	Props.finish(ph, solids, Vector3(0.34, 0.6, 0.16), Vector3(0, 0, 0.6), null, Vector3(0, 1.4, 0), Vector3(0, 1.38, 0.08))
	RoomBuilder.box(root, Vector3(0.008, 0.5, 0.36), Vector3(KX0 + 0.01, 1.45, 5.75), Palette.PAPER)
	RoomBuilder.box(root, Vector3(0.012, 0.09, 0.34), Vector3(KX0 + 0.0135, 1.64, 5.75), Palette.CORAL)
	for i in 4:
		RoomBuilder.box(root, Vector3(0.012, 0.012, 0.3), Vector3(KX0 + 0.0135, 1.3 + i * 0.07, 5.75), Palette.MUTED)

	# A wall clock by the door
	RoomBuilder.box(root, Vector3(0.012, 0.3, 0.3), Vector3(KX0 + 0.012, 2.0, 4.4), Palette.PAPER)
	RoomBuilder.box(root, Vector3(0.006, 0.12, 0.02), Vector3(KX0 + 0.021, 2.04, 4.4), Palette.INK)
	RoomBuilder.box(root, Vector3(0.006, 0.02, 0.09), Vector3(KX0 + 0.021, 2.0, 4.44), Palette.INK)


# ---------------------------------------------------------------- dining room

static func _build_dining(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], objects: Dictionary) -> void:
	var c := Vector3(14.3, 0, 9.0)
	var tb := Props.item(root, objects, "dining_table", "Dining Table", c, 0)
	Props.part(tb, Vector3(0.95, 0.05, 0.95), Vector3(0, 0.74, 0), Palette.WOOD)
	Props.part(tb, Vector3(0.88, 0.008, 0.88), Vector3(0, 0.769, 0), Color.WHITE, tex["plaid"], false)
	for lx in [-0.4, 0.4]:
		for lz in [-0.4, 0.4]:
			Props.part(tb, Vector3(0.06, 0.715, 0.06), Vector3(lx, 0.3575, lz), Palette.WOOD_DARK, null, false)
	Props.part(tb, Vector3(0.26, 0.07, 0.26), Vector3(0, 0.808, 0), Palette.CREAM, null, false)       # fruit bowl
	Props.part(tb, Vector3(0.08, 0.08, 0.08), Vector3(-0.05, 0.86, 0.03), Palette.CORAL, null, false)
	Props.part(tb, Vector3(0.08, 0.08, 0.08), Vector3(0.06, 0.865, -0.04), Palette.GOLD, null, false)
	for p in [Vector3(0, 0, -0.32), Vector3(0, 0, 0.32), Vector3(-0.32, 0, 0), Vector3(0.32, 0, 0)]:
		Props.part(tb, Vector3(0.2, 0.012, 0.2), Vector3(p.x, 0.779, p.z), Palette.PAPER, null, false)   # plates
	Props.finish(tb, solids, Vector3(0.95, 0.78, 0.95), Vector3(0, 0, -1.3), Vector3(0, 0, -0.7), Vector3(0, 0.8, 0))
	Props.pizza_box(root, objects, "pizza_box", tb, Vector3(0.2, 0.775, -0.24), "jamie")

	# Four chairs, each facing the table
	for ch in [[Vector3(0, 0, -0.7), 0.0], [Vector3(0, 0, 0.7), 180.0], [Vector3(-0.7, 0, 0), 90.0], [Vector3(0.7, 0, 0), -90.0]]:
		var b := Props.solid(root, c + ch[0], ch[1])
		Props.part(b, Vector3(0.42, 0.05, 0.42), Vector3(0, 0.45, 0), Palette.WOOD)
		Props.part(b, Vector3(0.38, 0.03, 0.38), Vector3(0, 0.49, 0.01), Palette.GOLD)
		Props.part(b, Vector3(0.42, 0.5, 0.05), Vector3(0, 0.72, -0.185), Palette.WOOD)
		for lx in [-0.18, 0.18]:
			for lz in [-0.18, 0.18]:
				Props.part(b, Vector3(0.035, 0.425, 0.035), Vector3(lx, 0.2125, lz), Palette.WOOD_DARK)
		Props.finish(b, solids, Vector3(0.42, 0.95, 0.42), Vector3.ZERO)

	# A plant in the corner
	var pl := Props.solid(root, Vector3(15.85, 0, 10.15), 0)
	Props.part(pl, Vector3(0.38, 0.4, 0.38), Vector3(0, 0.2, 0), Color("C2572F"))
	Props.part(pl, Vector3(0.6, 0.45, 0.6), Vector3(0, 0.62, 0), Palette.AVOCADO)
	Props.part(pl, Vector3(0.36, 0.3, 0.36), Vector3(0, 0.98, 0), Color("8FA246"))
	Props.finish(pl, solids, Vector3(0.4, 0.9, 0.4), Vector3.ZERO)
