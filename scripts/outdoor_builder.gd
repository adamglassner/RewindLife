class_name OutdoorBuilder
extends RefCounted
## The neighborhood around Jamie's house (Maple Street, 1986):
##
##   z = -12   +--- privacy fence -------------------------+
##             |  BACKYARD: picnic table, grill, tree swing, |
##             |  clothesline, lawn chairs, flower bed       |
##   z = 0     |        [ JAMIE'S HOUSE ]                   |   neighbors on both sides
##             |  FRONT YARD: walk, tree, flamingos, wagon  |
##   z = 14    ======== sidewalk ================================
##   z = 15.6  ========  MAPLE STREET  ====  (Oak Ave crosses at x = -20)
##   z = 23.6  ======== sidewalk ================================
##   z = 28     [ house ]      [ house ]      [ house ]   across the street
##
## The Kowalskis' and Parkers' houses are just outsides; the other three neighbors
## (NeighborBuilder) have insides, for online players.

const STREET_Z0 := 15.6
const STREET_Z1 := 23.6
const OAK_X0 := -24.0     # the cross street, Oak Avenue
const OAK_X1 := -17.0
## Where you can walk outdoors (it's also where the invisible edge walls go).
const WALK := Rect2(-22, -70, 154.0, 162)
## Maple Street and Main Street run east to here (Lincoln Avenue stops at x = 86).
const EAST_END := 136.0
const GREENS := [Color("4F7A3A"), Color("5E8A3E"), Color("3F6B34"), Color("6A9446")]


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2],
		outdoor: Array[Rect2], buildings: Array[Rect2]) -> void:
	var objects: Dictionary = out["objects"]
	outdoor.append(WALK)                        # everywhere Jamie can walk outside (down to Main Street and the drive-in)
	out["outdoor_lights"] = []

	# ---------------------------------------------------------------- ground
	# The lawn stops at the walls of our house: nothing grows indoors (or in the stairwell).
	var holes: Array[Rect2] = buildings.duplicate()
	holes.append_array(NeighborBuilder.home_rects())   # the neighbors' houses have floors
	holes.append_array(DowntownBuilder.shop_rects())   # and so do the shops on Main Street
	for cr in CivicBuilder.rects() + MallBuilder.rects() + EastBuilder.rects() + SchoolBuilder.rects() + [SchoolBuilder.WING]:   # and the buildings on Lincoln Avenue and out east
		holes.append(cr.grow(0.12))
	for piece in rect_minus(SceneryBuilder.TOWN, holes):
		RoomBuilder.make_floor(root, piece, Color.WHITE, tex["grass"], -0.025).add_to_group("lawn")   # (Seasons: snow, fall)
	# A foundation slab under every building, a little wider than the hole in the
	# lawn: when the House Cam lowers the walls, there's no slit to see through
	# between the lawn and the wall.
	for h in holes:
		var fr := h.grow(0.25)
		var fm := RoomBuilder.box(root, Vector3(fr.size.x, 0.1, fr.size.y), Vector3(fr.get_center().x, -0.082, fr.get_center().y), RoomBuilder.FOUNDATION)
		fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var asphalt := Color("4A4950")
	var concrete := Color("CFC8BA")
	_slab(root, Rect2(-66, STREET_Z0 + 0.15, EAST_END + 66.0, STREET_Z1 - STREET_Z0 - 0.3), asphalt, tex["asphalt"], -0.015)
	_slab(root, Rect2(OAK_X0, -76, OAK_X1 - OAK_X0, 152), asphalt, tex["asphalt"], -0.012)
	for x in range(-64, int(EAST_END) - 2, 4):       # dashed yellow center line
		if x + 2 < OAK_X0 or x > OAK_X1:
			_slab(root, Rect2(x, (STREET_Z0 + STREET_Z1) / 2.0 - 0.06, 2.0, 0.12), Color("E8C24A"), null, -0.008)
	for z in [STREET_Z0, STREET_Z1 - 0.15]:          # curbs (with a gap where Oak Avenue crosses)
		for seg in [[-66.0, OAK_X0 - 0.01], [OAK_X1 + 0.01, EAST_END]]:
			var len: float = seg[1] - seg[0]
			RoomBuilder.box(root, Vector3(len, 0.12, 0.15), Vector3(seg[0] + len / 2.0, 0.04, z + 0.075), Color("B9B2A5"))
	_slab(root, Rect2(-66, 14.0, EAST_END + 66.0, 1.6), concrete, tex["concrete"], 0.004)        # sidewalks
	_slab(root, Rect2(-66, STREET_Z1, EAST_END + 66.0, 1.6), concrete, tex["concrete"], 0.004)
	_slab(root, Rect2(OAK_X1, -76, 1.6, 152), concrete, tex["concrete"], 0.004)    # (same height as the sidewalks it crosses)
	for x in [OAK_X1 - 7.0, OAK_X1 - 4.5, OAK_X1 - 2.0]:                            # crosswalk stripes
		_slab(root, Rect2(x - 0.3, STREET_Z0, 0.6 + 0.0, STREET_Z1 - STREET_Z0), Palette.PAPER, null, -0.006)

	# ---------------------------------------------------------------- our front yard
	_slab(root, Rect2(0.8, 6.4, 1.0, 7.6), concrete, tex["concrete"], 0.006)           # front walk
	_slab(root, Rect2(0.2, 6.15, 2.2, 1.0), Color("B8AFA0"), tex["concrete"], 0.03)    # porch
	_slab(root, Rect2(0.85, 6.3, 0.9, 0.5), Palette.RUST, null, 0.04)                  # doormat
	var porch_lamp := RoomBuilder.box(root, Vector3(0.14, 0.24, 0.12), Vector3(0.45, 1.95, 6.25), Palette.LAMP)
	var pl_mat: StandardMaterial3D = porch_lamp.material_override
	pl_mat.emission_enabled = true
	pl_mat.emission = Palette.LAMP
	RoomBuilder.add_lamp(out, _omni(root, Vector3(0.6, 2.0, 6.7), Palette.LAMP, 4.5), pl_mat, 0.0, 1.3)
	_slab(root, Rect2(16.5, 7.4, 5.4, 6.6), Color("BDB6A8"), tex["concrete"], 0.007)  # the driveway (two cars wide)
	_slab(root, Rect2(16.5, 14.0, 5.4, 1.6), Color("C4BDB0"), tex["concrete"], 0.011)  # (where it crosses the sidewalk)
	for x in [2.6, 3.8, 5.0, 6.2, 7.4]:
		_shrub(root, solids, Vector3(x, 0, 6.65), 0.75)
	for x in [9.0, 10.4, 11.8]:
		_shrub(root, solids, Vector3(x, 0, 9.1), 0.8)
	for z in range(0, 13):
		_shrub(root, solids, Vector3(-4.0, 0, 1.0 + z * 1.0), 0.95, true)   # hedge along the lot line
	_tree(root, solids, Vector3(-2.4, 0, 11.8), 0.9)
	_flamingo(root, Vector3(-1.5, 0, 9.8), 20.0)
	_flamingo(root, Vector3(-0.7, 0, 10.5), -35.0)
	var cars: Array = []
	# Both cars parked side by side in the driveway, with their driver's doors
	# facing each other across the middle (the wagon backed in, the hatchback nose-in)
	cars.append(_station_wagon(root, solids, objects, Vector3(17.65, 0, 11.2)))
	cars.append(_hatchback(root, solids, objects, Vector3(20.68, 0, 11.4), 180.0))
	objects["hoop"] = _hoop(root, solids, Vector3(21.45, 0, 7.75))
	# The neighbors' cars: a pickup in the Garcias' driveway, and cars parked along the curbs
	cars.append(_pickup(root, solids, objects, Vector3(34.92, 0, 11.3)))
	cars.append(_sedan(root, solids, objects, "sedan", "Mr. Nguyen's Sedan", Vector3(6.5, 0, 22.8), 90.0, Color("2E4A7A")))
	cars.append(_van(root, solids, objects, Vector3(-9.0, 0, 16.5), -90.0))
	cars.append(_convertible(root, solids, objects, Vector3(27.8, 0, 22.85), 90.0))
	trash_cans(root, objects, solids, "trash", "jamie", Vector3(15.8, 0, 13.55), Vector3(0, 0, -1))
	objects["mailbox"] = _mailbox(root, solids, Vector3(2.4, 0, 13.65))
	(objects["mailbox"] as SmartObject).home = "jamie"
	var jm := Props.item(root, objects, "mower", "Lawn Mower", Vector3(14.95, 0, -2.2), 180)
	jm.kind = "mower"
	jm.home = "jamie"
	NeighborBuilder._mower_model(jm)
	Props.finish(jm, solids, Vector3(0.55, 0.9, 0.9), Vector3(0, 0, 1.0), null, Vector3(0, 0.4, 0))
	_hydrant(root, solids, Vector3(8.5, 0, 13.7))
	_flowers(root, Rect2(1.9, 7.4, 0.5, 6.4), 18, 5)

	# ---------------------------------------------------------------- our backyard
	_fence(root, solids, Vector3(-4.0, 0, -12.0), Vector3(20.0, 0, -12.0))
	_fence(root, solids, Vector3(-4.0, 0, -12.0), Vector3(-4.0, 0, -0.5))
	_fence(root, solids, Vector3(20.0, 0, -12.0), Vector3(20.0, 0, -0.5))
	objects["picnic"] = _picnic_table(root, solids, Vector3(4.5, 0, -6.5), tex)
	objects["grill"] = _grill(root, solids, out, Vector3(7.6, 0, -4.8))
	objects["lawn_chair"] = _lawn_chair(root, solids, Vector3(1.9, 0, -5.0), 30.0, [Palette.TEAL, Palette.PAPER])
	objects["lawn_chair_2"] = _lawn_chair(root, solids, Vector3(2.3, 0, -8.1), 150.0, [Palette.CORAL, Palette.GOLD])
	objects["tire_swing"] = _tree(root, solids, Vector3(13.0, 0, -8.0), 1.25, true)
	_clothesline(root, solids, Vector3(15.2, 0, -3.2), Vector3(19.0, 0, -3.2))
	_slab(root, Rect2(-3.5, -11.8, 23.0, 0.8), Color("5C3A26"), null, 0.01)
	_flowers(root, Rect2(-3.4, -11.7, 22.8, 0.6), 70, 11)
	_shrub(root, solids, Vector3(-3.2, 0, -1.5), 0.9)
	_shrub(root, solids, Vector3(17.5, 0, -0.8), 0.9)

	# ---------------------------------------------------------------- the street
	_streetlight(root, solids, out, Vector3(-10.0, 0, 13.75), 1.0)
	_streetlight(root, solids, out, Vector3(11.0, 0, 13.75), 1.0)
	_streetlight(root, solids, out, Vector3(31.0, 0, 13.75), 1.0)
	_streetlight(root, solids, out, Vector3(1.0, 0, 25.45), -1.0)
	_streetlight(root, solids, out, Vector3(24.0, 0, 25.45), -1.0)
	_corner_signs(root, solids, Vector3(-15.0, 0, 14.25))
	_sign(root, solids, Vector3(26.0, 0, 13.6), "SPEED\nLIMIT\n25", Palette.PAPER, Palette.INK, Vector2(0.6, 0.75), 0.0)
	_sign(root, solids, Vector3(-14.6, 0, 25.6), "NEIGHBORHOOD\nWATCH", Color("2E5E9E"), Palette.PAPER, Vector2(0.9, 0.55), 180.0)
	_hydrant(root, solids, Vector3(14.0, 0, 25.75))
	out["cars"] = cars
	_kid_bikes(root, objects)

	# ---------------------------------------------------------------- the neighbors
	# (the Hendersons, Garcias and Nguyens are built by NeighborBuilder: players can live there)
	for x in [-1.2, 16.6, 30.5]:
		_tree(root, solids, Vector3(x, 0, 26.6), 0.85)

	# ---------------------------------------------------------------- edges
	# Invisible walls so first-person walking can't wander off the map.
	# (Their own layer, 32: cars ignore them and can drive further along the streets.)
	var edge := StaticBody3D.new()
	edge.collision_layer = 32
	root.add_child(edge)
	var w := WALK
	RoomBuilder.add_shape(edge, Vector3(w.size.x, 4, 0.5), Vector3(w.get_center().x, 2, w.position.y))
	RoomBuilder.add_shape(edge, Vector3(w.size.x, 4, 0.5), Vector3(w.get_center().x, 2, w.end.y))
	RoomBuilder.add_shape(edge, Vector3(0.5, 4, w.size.y), Vector3(w.position.x, 2, w.get_center().y))
	RoomBuilder.add_shape(edge, Vector3(0.5, 4, w.size.y), Vector3(w.end.x, 2, w.get_center().y))

	# The edge of the drivable area: the length of Maple Street and Oak Avenue.
	var car_edge := StaticBody3D.new()
	car_edge.collision_layer = 16
	root.add_child(car_edge)
	var cw := Rect2(-64, -76, EAST_END + 62.0, 150)
	RoomBuilder.add_shape(car_edge, Vector3(cw.size.x, 4, 0.5), Vector3(cw.get_center().x, 2, cw.position.y))
	RoomBuilder.add_shape(car_edge, Vector3(cw.size.x, 4, 0.5), Vector3(cw.get_center().x, 2, cw.end.y))
	RoomBuilder.add_shape(car_edge, Vector3(0.5, 4, cw.size.y), Vector3(cw.position.x, 2, cw.get_center().y))
	RoomBuilder.add_shape(car_edge, Vector3(0.5, 4, cw.size.y), Vector3(cw.end.x, 2, cw.get_center().y))


# ================================================================ helpers

## `r` with the `holes` cut out, as a list of rectangles.
static func rect_minus(r: Rect2, holes: Array[Rect2]) -> Array[Rect2]:
	var pieces: Array[Rect2] = [r]
	for h in holes:
		var next: Array[Rect2] = []
		for p in pieces:
			if not p.intersects(h):
				next.append(p)
				continue
			var cut := p.intersection(h)
			if cut.position.y > p.position.y:      # strip above the hole
				next.append(Rect2(p.position.x, p.position.y, p.size.x, cut.position.y - p.position.y))
			if cut.end.y < p.end.y:                # strip below
				next.append(Rect2(p.position.x, cut.end.y, p.size.x, p.end.y - cut.end.y))
			if cut.position.x > p.position.x:      # left of the hole
				next.append(Rect2(p.position.x, cut.position.y, cut.position.x - p.position.x, cut.size.y))
			if cut.end.x < p.end.x:                # right of the hole
				next.append(Rect2(cut.end.x, cut.position.y, p.end.x - cut.end.x, cut.size.y))
		pieces = next
	return pieces


## A flat surface (sidewalk, street, path) lying on the grass. Not clickable
## itself: clicks pass through to the ground, so Jamie can still walk on it.
static func _slab(root: Node3D, r: Rect2, color: Color, tex: Texture2D, top: float) -> void:
	var mi := RoomBuilder.box(root, Vector3(r.size.x, 0.04, r.size.y), Vector3(r.get_center().x, top - 0.02, r.get_center().y), color, tex, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Something solid: blocks walking (grid) and first-person movement (collision).
static func _solid(root: Node3D, solids: Array[Rect2], center: Vector3, size: Vector3) -> void:
	var b := StaticBody3D.new()
	b.collision_layer = 2
	root.add_child(b)
	RoomBuilder.add_shape(b, size, center + Vector3(0, size.y / 2.0, 0))
	solids.append(Rect2(center.x - size.x / 2.0, center.z - size.z / 2.0, size.x, size.z))


static func _omni(root: Node3D, pos: Vector3, color: Color, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.omni_range = rng
	root.add_child(l)
	return l


static func _shrub(root: Node3D, solids: Array[Rect2], at: Vector3, size: float, hedge := false) -> void:
	var c: Color = GREENS[int(absf(at.x * 7.0 + at.z * 3.0)) % GREENS.size()]
	var w := size * (1.05 if hedge else 0.9)
	var a := RoomBuilder.box(root, Vector3(w, size * 0.7, w), at + Vector3(0, size * 0.35, 0), c)
	if not hedge:
		a.rotation.y = fmod(at.x * 1.7 + at.z, 1.5)
		RoomBuilder.box(root, Vector3(w * 0.7, size * 0.35, w * 0.7), at + Vector3(0, size * 0.82, 0), c.lightened(0.08)).rotation.y = 0.6
	else:
		RoomBuilder.box(root, Vector3(w * 0.94, size * 0.25, w * 0.8), at + Vector3(0, size * 0.82, 0), c.lightened(0.06))
	_solid(root, solids, at, Vector3(w * 0.8, size, w * 0.8))


static func _tree(root: Node3D, solids: Array[Rect2], at: Vector3, s: float, swing := false) -> SmartObject:
	RoomBuilder.box(root, Vector3(0.45, 3.2, 0.45) * s, at + Vector3(0, 1.6 * s, 0), Palette.WOOD_DARK)
	# (the crowns are in the "leaves" group: Seasons turns them orange in the fall and bare in winter)
	RoomBuilder.box(root, Vector3(4.2, 1.7, 4.2) * s, at + Vector3(0, 3.7 * s, 0), Color("4F7A3A")).add_to_group("leaves")
	var c2 := RoomBuilder.box(root, Vector3(3.2, 1.3, 3.4) * s, at + Vector3(0.3, 4.9 * s, -0.2), Color("5E8A3E"))
	c2.rotation.y = 0.4
	c2.add_to_group("leaves")
	var c3 := RoomBuilder.box(root, Vector3(2.0, 1.0, 2.2) * s, at + Vector3(-0.4, 5.8 * s, 0.3), Color("6A9446"))
	c3.rotation.y = 0.9
	c3.add_to_group("leaves")
	_solid(root, solids, at, Vector3(0.5, 3, 0.5) * s)
	if swing:   # a tire swing on a low branch
		RoomBuilder.box(root, Vector3(1.9, 0.25, 0.25) * s, at + Vector3(1.0 * s, 2.9 * s, 0), Palette.WOOD_DARK)
		RoomBuilder.box(root, Vector3(0.03, 1.8, 0.03), at + Vector3(1.75 * s, 2.0, 0), Palette.CREAM)
		# The tire hangs from a pivot at the branch, so it can swing.
		var sw := SmartObject.new()
		sw.name = "TireSwing"
		sw.display_name = "Tire Swing"
		root.add_child(sw)
		var pivot := Node3D.new()
		pivot.name = "Pivot"
		pivot.position = at + Vector3(1.75 * s, 2.9 * s, 0)
		sw.add_child(pivot)
		var t := Vector3(0, 0.85 - 2.9 * s, 0)
		RoomBuilder.box(pivot, Vector3(0.03, 2.9 * s - 1.13, 0.03), Vector3(0, (2.9 * s + 1.13) / 2.0 - 2.9 * s, 0), Palette.CREAM)
		for b in [[Vector3(0.7, 0.14, 0.18), Vector3(0, 0.28, 0)], [Vector3(0.7, 0.14, 0.18), Vector3(0, -0.28, 0)],
				[Vector3(0.14, 0.56, 0.18), Vector3(0.28, 0, 0)], [Vector3(0.14, 0.56, 0.18), Vector3(-0.28, 0, 0)]]:
			sw.add_material(RoomBuilder.box(pivot, b[0], t + b[1], Palette.INK).material_override)
		var tc := at + Vector3(1.75 * s, 0.85, 0)
		RoomBuilder.add_shape(sw, Vector3(0.75, 0.75, 0.3), tc)
		solids.append(Rect2(tc.x - 0.38, tc.z - 0.15, 0.76, 0.3))
		sw.approach_point = Vector3(tc.x, 0, tc.z + 0.8)
		sw.use_point = Vector3(tc.x, 0, tc.z)
		sw.look_point = Vector3(tc.x, 0.8, tc.z + 3.0)
		return sw
	return null


static func _flowers(root: Node3D, r: Rect2, count: int, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var cols := [Palette.CORAL, Palette.GOLD, Palette.ROSE, Palette.PAPER, Color("B07CC6")]
	for i in count:
		var p := Vector3(rng.randf_range(r.position.x, r.end.x), 0, rng.randf_range(r.position.y, r.end.y))
		var hgt := rng.randf_range(0.24, 0.34)     # varied, so neighboring flowers never line up exactly
		RoomBuilder.box(root, Vector3(0.025, hgt, 0.025), p + Vector3(0, hgt / 2.0, 0), Color("4F7A3A"))
		var head := RoomBuilder.box(root, Vector3(0.11, 0.08, 0.11), p + Vector3(0, hgt + 0.02, 0), cols[rng.randi() % cols.size()])
		head.rotation.y = rng.randf() * PI


static func _flamingo(root: Node3D, at: Vector3, yaw: float) -> void:
	var g := Node3D.new()
	g.position = at
	g.rotation_degrees.y = yaw
	root.add_child(g)
	var pink := Color("F28DB2")
	RoomBuilder.box(g, Vector3(0.015, 0.45, 0.015), Vector3(0.02, 0.22, 0), Palette.INK)
	RoomBuilder.box(g, Vector3(0.015, 0.45, 0.015), Vector3(-0.02, 0.22, 0), Palette.INK)
	RoomBuilder.box(g, Vector3(0.14, 0.14, 0.32), Vector3(0, 0.52, 0), pink)
	RoomBuilder.box(g, Vector3(0.04, 0.3, 0.04), Vector3(0, 0.72, -0.14), pink)
	RoomBuilder.box(g, Vector3(0.07, 0.07, 0.12), Vector3(0, 0.88, -0.18), pink)
	RoomBuilder.box(g, Vector3(0.03, 0.03, 0.08), Vector3(0, 0.87, -0.27), Palette.INK)


## Every kid's own bike (bought at Spoke & Pedal): hidden until it's bought,
## then parked wherever its owner hops off.
static func _kid_bikes(root: Node3D, objects: Dictionary) -> void:
	var cols := [Color("C0322A"), Color("2E5E9E"), Color("F7D046"), Color("2E8C8A"), Color("FF4FD8"), Color("4F9A3A")]
	for i in Sim.CHARACTERS.size():
		var ch: Dictionary = Sim.CHARACTERS[i]
		var b := Props.item(root, objects, "bike_" + String(ch["home"]), "%s's Bike" % ch["name"], Vector3(51.0 + i * 1.0, 0, 54.9), 90)
		b.kind = "bike"
		b.home = ch["home"]
		b.shared = false
		DowntownBuilder._bike_model(b, Vector3.ZERO, cols[i], true)
		for mi in b.find_children("*", "MeshInstance3D", true, false):
			b.add_material((mi as MeshInstance3D).material_override)
		RoomBuilder.add_shape(b, Vector3(0.4, 0.9, 1.2), Vector3(0, 0.45, 0))
		b.visible = false
		b.collision_layer = 0
		place_bike(b, b.position, b.rotation.y)


## Park a bike at `at` (turned `yaw`), and update where you use it from.
static func place_bike(b: SmartObject, at: Vector3, yaw: float) -> void:
	b.global_position = Vector3(at.x, 0, at.z)
	b.rotation = Vector3(0, yaw, 0)
	var side := b.global_basis.x * 0.6
	b.approach_point = b.global_position + side
	b.use_point = b.approach_point
	b.look_point = b.global_position + Vector3(0, 0.6, 0)


static func _bike(root: Node3D, at: Vector3) -> void:
	var g := Node3D.new()
	g.position = at
	g.rotation_degrees.y = 25.0
	root.add_child(g)
	for x in [-0.45, 0.45]:
		RoomBuilder.box(g, Vector3(0.55, 0.05, 0.55), Vector3(x, 0.03, 0), Palette.INK).rotation.y = 0.785
		RoomBuilder.box(g, Vector3(0.12, 0.06, 0.12), Vector3(x, 0.04, 0), Palette.MUTED)
	RoomBuilder.box(g, Vector3(0.95, 0.05, 0.05), Vector3(0, 0.06, 0), Palette.CORAL)
	RoomBuilder.box(g, Vector3(0.5, 0.05, 0.05), Vector3(0.15, 0.06, 0.15), Palette.CORAL).rotation.y = 0.9
	RoomBuilder.box(g, Vector3(0.06, 0.05, 0.45), Vector3(0.45, 0.07, 0), Palette.MUTED)


static func _new_car(root: Node3D, solids: Array[Rect2], objects: Dictionary, key: String, title: String,
		at: Vector3, yaw: float, length: float, width: float) -> Car:
	var c := Car.new()
	c.name = key
	c.key = key
	c.display_name = title
	c.length = length
	c.width = width
	root.add_child(c)
	c.position = at
	c.rotation_degrees.y = yaw
	objects[key] = c
	return c


static func _finish_car(c: Car, solids: Array[Rect2], body_h: float) -> void:
	RoomBuilder.add_shape(c, Vector3(c.width, body_h, c.length), Vector3(0, body_h / 2.0 + 0.15, 0))
	solids.append(c.footprint())
	c.solid_index = solids.size() - 1
	c.refresh_points()


## The family's wood-paneled station wagon (forward = +z, toward the street).
static func _station_wagon(root: Node3D, solids: Array[Rect2], objects: Dictionary, at: Vector3) -> Car:
	var c := _new_car(root, solids, objects, "wagon", "Family Station Wagon", at, 0.0, 5.1, 1.9)
	var body := Color("D9C9A6")
	Props.part(c, Vector3(1.9, 0.62, 5.1), Vector3(0, 0.58, 0), body)
	Props.part(c, Vector3(1.94, 0.3, 4.0), Vector3(0, 0.62, -0.3), Palette.WOOD)
	Props.part(c, Vector3(1.75, 0.58, 3.2), Vector3(0, 1.18, -0.55), body)
	Props.part(c, Vector3(1.8, 0.4, 2.9), Vector3(0, 1.2, -0.55), Color("33405A"), null, false)    # windows
	Props.part(c, Vector3(1.5, 0.42, 0.06), Vector3(0, 1.18, 1.07), Color("33405A"), null, false)  # windshield
	Props.part(c, Vector3(1.95, 0.12, 0.12), Vector3(0, 0.38, 2.58), Palette.MUTED, null, false)  # bumpers
	Props.part(c, Vector3(1.95, 0.12, 0.12), Vector3(0, 0.38, -2.58), Palette.MUTED, null, false)
	for x in [-0.62, 0.62]:
		Props.part(c, Vector3(0.3, 0.16, 0.05), Vector3(x, 0.66, 2.56), Palette.PAPER, null, false)  # headlights
		Props.part(c, Vector3(0.3, 0.14, 0.05), Vector3(x, 0.66, -2.56), Palette.CORAL, null, false) # taillights
		c.add_headlight(Vector3(x, 0.66, 2.62))
	for x in [-0.87, 0.87]:
		for z in [-1.6, 1.6]:
			c.add_wheel(Vector3(x * 1.0, 0.31, z), z > 0)
	_finish_car(c, solids, 1.35)
	return c


## The little red hatchback (forward = +z).
static func _hatchback(root: Node3D, solids: Array[Rect2], objects: Dictionary, at: Vector3, yaw := 0.0) -> Car:
	var c := _new_car(root, solids, objects, "hatchback", "Little Red Hatchback", at, yaw, 3.9, 1.65)
	var red := Color("B8322A")
	Props.part(c, Vector3(1.65, 0.6, 3.9), Vector3(0, 0.56, 0), red)
	Props.part(c, Vector3(1.5, 0.55, 2.4), Vector3(0, 1.12, -0.3), red)
	Props.part(c, Vector3(1.55, 0.38, 2.2), Vector3(0, 1.14, -0.3), Color("33405A"), null, false)
	Props.part(c, Vector3(1.7, 0.1, 0.1), Vector3(0, 0.36, 1.96), Palette.MUTED, null, false)
	Props.part(c, Vector3(1.7, 0.1, 0.1), Vector3(0, 0.36, -1.96), Palette.MUTED, null, false)
	for x in [-0.55, 0.55]:
		Props.part(c, Vector3(0.28, 0.14, 0.05), Vector3(x, 0.66, 1.96), Palette.PAPER, null, false)
		Props.part(c, Vector3(0.26, 0.12, 0.05), Vector3(x, 0.66, -1.96), Palette.CORAL, null, false)
		c.add_headlight(Vector3(x, 0.66, 2.0))
	for x in [-0.76, 0.76]:
		for z in [-1.25, 1.25]:
			c.add_wheel(Vector3(x, 0.31, z), z > 0)
	_finish_car(c, solids, 1.25)
	return c


static func _hoop(root: Node3D, solids: Array[Rect2], at: Vector3) -> SmartObject:
	var h := SmartObject.new()
	h.name = "Hoop"
	h.display_name = "Basketball Hoop"
	root.add_child(h)
	h.add_material(RoomBuilder.box(h, Vector3(0.12, 3.0, 0.12), at + Vector3(0, 1.5, 0), Palette.INK2).material_override)
	h.add_material(RoomBuilder.box(h, Vector3(0.06, 0.9, 1.2), at + Vector3(-0.25, 3.0, 0), Palette.PAPER).material_override)
	RoomBuilder.box(h, Vector3(0.07, 0.35, 0.45), at + Vector3(-0.26, 2.85, 0), Palette.CORAL)
	RoomBuilder.box(h, Vector3(0.45, 0.03, 0.45), at + Vector3(-0.5, 2.75, 0), Palette.CORAL)
	RoomBuilder.add_shape(h, Vector3(0.3, 3.0, 0.3), at + Vector3(0, 1.5, 0))
	solids.append(Rect2(at.x - 0.15, at.z - 0.15, 0.3, 0.3))
	h.approach_point = Vector3(at.x - 2.2, 0, at.z - 1.35)
	h.use_point = h.approach_point
	h.look_point = at + Vector3(-0.5, 2.75, 0)
	return h


static func _trash_can(root: Node3D, solids: Array[Rect2], at: Vector3) -> void:
	RoomBuilder.box(root, Vector3(0.5, 0.75, 0.5), at + Vector3(0, 0.375, 0), Color("A9ADB0"))
	RoomBuilder.box(root, Vector3(0.56, 0.06, 0.56), at + Vector3(0, 0.78, 0), Color("8E9296"))
	RoomBuilder.box(root, Vector3(0.16, 0.04, 0.04), at + Vector3(0, 0.83, 0), Color("8E9296"))
	_solid(root, solids, at, Vector3(0.55, 0.85, 0.55))


static func _hydrant(root: Node3D, solids: Array[Rect2], at: Vector3) -> void:
	var red := Color("C63B2B")
	RoomBuilder.box(root, Vector3(0.34, 0.1, 0.34), at + Vector3(0, 0.05, 0), red)
	RoomBuilder.box(root, Vector3(0.24, 0.55, 0.24), at + Vector3(0, 0.37, 0), red)
	RoomBuilder.box(root, Vector3(0.3, 0.08, 0.3), at + Vector3(0, 0.66, 0), Palette.PAPER)
	RoomBuilder.box(root, Vector3(0.16, 0.1, 0.16), at + Vector3(0, 0.75, 0), Palette.PAPER)
	RoomBuilder.box(root, Vector3(0.44, 0.1, 0.1), at + Vector3(0, 0.45, 0), red)
	RoomBuilder.box(root, Vector3(0.1, 0.12, 0.2), at + Vector3(0, 0.45, 0.13), Palette.PAPER)
	_solid(root, solids, at, Vector3(0.4, 0.8, 0.4))


## Two garbage cans to take out to the curb (a chore), as one thing you can use.
static func trash_cans(root: Node3D, objects: Dictionary, solids: Array[Rect2], key: String, home: String, at: Vector3, toward: Vector3) -> SmartObject:
	var o := SmartObject.new()
	o.name = key
	o.display_name = "Trash Cans"
	o.kind = "trash_cans"
	o.home = home
	root.add_child(o)
	var across := Vector3(toward.z, 0, -toward.x)
	for k in [-0.31, 0.31]:
		var p: Vector3 = at + across * k
		o.add_material(RoomBuilder.box(o, Vector3(0.5, 0.75, 0.5), p + Vector3(0, 0.375, 0), Color("A9ADB0")).material_override)
		RoomBuilder.box(o, Vector3(0.56, 0.06, 0.56), p + Vector3(0, 0.78, 0), Color("8E9296"))
		RoomBuilder.box(o, Vector3(0.16, 0.04, 0.04), p + Vector3(0, 0.83, 0), Color("8E9296"))
	var size := Vector3(1.15, 0.85, 0.55) if absf(across.x) > 0.5 else Vector3(0.55, 0.85, 1.15)
	RoomBuilder.add_shape(o, size, at + Vector3(0, 0.425, 0))
	solids.append(Rect2(at.x - size.x / 2.0, at.z - size.z / 2.0, size.x, size.z))
	o.approach_point = at + toward * 0.75
	o.use_point = o.approach_point
	o.look_point = at + Vector3(0, 0.6, 0)
	objects[key] = o
	return o


static func _mailbox(root: Node3D, solids: Array[Rect2], at: Vector3, toward := -1.0) -> SmartObject:
	var mb := SmartObject.new()
	mb.name = "Mailbox"
	mb.display_name = "Mailbox"
	root.add_child(mb)
	RoomBuilder.box(mb, Vector3(0.09, 1.05, 0.09), at + Vector3(0, 0.52, 0), Palette.WOOD)
	mb.add_material(RoomBuilder.box(mb, Vector3(0.24, 0.24, 0.48), at + Vector3(0, 1.17, 0), Color("2B2F3A")).material_override)
	RoomBuilder.box(mb, Vector3(0.24, 0.1, 0.48), at + Vector3(0, 1.32, 0), Color("2B2F3A"))
	RoomBuilder.box(mb, Vector3(0.03, 0.22, 0.06), at + Vector3(0.14, 1.32, -0.1), Palette.CORAL)     # the flag
	RoomBuilder.box(mb, Vector3(0.025, 0.06, 0.2), at + Vector3(0.14, 1.42, -0.04), Palette.CORAL)
	RoomBuilder.add_shape(mb, Vector3(0.3, 1.4, 0.5), at + Vector3(0, 0.7, 0))
	solids.append(Rect2(at.x - 0.15, at.z - 0.25, 0.3, 0.5))
	mb.approach_point = at + Vector3(0, 0, 0.75 * toward)
	mb.use_point = mb.approach_point
	mb.look_point = at + Vector3(0, 1.1, 0)
	return mb


static func _fence(root: Node3D, solids: Array[Rect2], a: Vector3, b: Vector3) -> void:
	# A 6-foot cedar privacy fence with posts every 2.4 m.
	var cedar := Color("9C6B45")
	var along_x := absf(b.x - a.x) > absf(b.z - a.z)
	var length := (b - a).length()
	var mid := (a + b) / 2.0
	var size := Vector3(length, 1.8, 0.05) if along_x else Vector3(0.05, 1.8, length)
	var planks := RoomBuilder.box(root, size, mid + Vector3(0, 0.95, 0), cedar, RoomBuilder.make_tex("panel"), 3.0)
	planks.name = "fence"
	var dir := (b - a).normalized()
	var n := int(length / 2.4)
	for i in n + 1:
		RoomBuilder.box(root, Vector3(0.12, 2.0, 0.12), a + dir * (i * length / n) + Vector3(0, 1.0, 0), Color("7A4F33"))
	var cap := Vector3(length, 0.06, 0.12) if along_x else Vector3(0.12, 0.06, length)
	RoomBuilder.box(root, cap, mid + Vector3(0, 1.88, 0), Color("7A4F33"))
	_solid(root, solids, mid, size + (Vector3(0, 0, 0.1) if along_x else Vector3(0.1, 0, 0)))


static func _picnic_table(root: Node3D, solids: Array[Rect2], at: Vector3, tex: Dictionary) -> SmartObject:
	var pt := SmartObject.new()
	pt.name = "PicnicTable"
	pt.display_name = "Picnic Table"
	root.add_child(pt)
	var wood := Color("9A4A2E")
	pt.add_material(RoomBuilder.box(pt, Vector3(1.9, 0.06, 0.82), at + Vector3(0, 0.75, 0), wood).material_override)
	RoomBuilder.box(pt, Vector3(1.7, 0.012, 0.86), at + Vector3(0, 0.785, 0), Palette.CORAL, tex["plaid"], 5.0)   # checkered cloth
	for z in [-0.64, 0.64]:
		pt.add_material(RoomBuilder.box(pt, Vector3(1.9, 0.05, 0.28), at + Vector3(0, 0.44, z), wood).material_override)
	for x in [-0.72, 0.72]:
		RoomBuilder.box(pt, Vector3(0.08, 0.75, 0.08), at + Vector3(x, 0.37, -0.25), wood.darkened(0.2))
		RoomBuilder.box(pt, Vector3(0.08, 0.75, 0.08), at + Vector3(x, 0.37, 0.25), wood.darkened(0.2))
		RoomBuilder.box(pt, Vector3(0.08, 0.06, 1.5), at + Vector3(x, 0.4, 0), wood.darkened(0.2))
	RoomBuilder.box(pt, Vector3(0.36, 0.22, 0.24), at + Vector3(-0.45, 0.9, 0.05), Color("C9A878"))   # picnic basket
	RoomBuilder.box(pt, Vector3(0.3, 0.04, 0.04), at + Vector3(-0.45, 1.06, 0.05), Palette.WOOD_DARK)
	RoomBuilder.box(pt, Vector3(0.12, 0.24, 0.12), at + Vector3(0.3, 0.91, -0.1), Color("F2DC6E"))    # lemonade pitcher
	RoomBuilder.box(pt, Vector3(0.07, 0.11, 0.07), at + Vector3(0.5, 0.85, 0.15), Palette.PAPER)
	RoomBuilder.box(pt, Vector3(0.07, 0.11, 0.07), at + Vector3(0.6, 0.85, -0.2), Palette.PAPER)
	RoomBuilder.add_shape(pt, Vector3(1.9, 0.8, 1.6), at + Vector3(0, 0.4, 0))
	solids.append(Rect2(at.x - 1.0, at.z - 0.8, 2.0, 1.6))
	pt.approach_point = at + Vector3(0, 0, 1.45)
	pt.use_point = at + Vector3(0, 0, 0.62)
	pt.look_point = at + Vector3(0, 0.8, -1.0)
	return pt


static func _grill(root: Node3D, solids: Array[Rect2], out: Dictionary, at: Vector3) -> SmartObject:
	var g := SmartObject.new()
	g.name = "Grill"
	g.display_name = "Charcoal Grill"
	root.add_child(g)
	for a in [0.0, 2.1, 4.2]:
		RoomBuilder.box(g, Vector3(0.04, 0.7, 0.04), at + Vector3(cos(a) * 0.2, 0.35, sin(a) * 0.2), Palette.INK)
	g.add_material(RoomBuilder.box(g, Vector3(0.58, 0.3, 0.58), at + Vector3(0, 0.78, 0), Palette.INK).material_override)
	g.add_material(RoomBuilder.box(g, Vector3(0.5, 0.22, 0.5), at + Vector3(0, 1.02, 0), Palette.INK).material_override)
	RoomBuilder.box(g, Vector3(0.14, 0.05, 0.05), at + Vector3(0, 1.17, 0), Palette.MUTED)
	# Glowing coals, seen through the vents (lit while grilling)
	out["coals_mat"] = Props.glowing(g, Vector3(0.4, 0.02, 0.4), at + Vector3(0, 0.935, 0), Color("E4572E"), 0.0)
	RoomBuilder.add_shape(g, Vector3(0.6, 1.2, 0.6), at + Vector3(0, 0.6, 0))
	solids.append(Rect2(at.x - 0.3, at.z - 0.3, 0.6, 0.6))
	g.approach_point = at + Vector3(0, 0, 0.8)
	g.use_point = g.approach_point
	g.look_point = at + Vector3(0, 1.0, 0)
	return g


static func _lawn_chair(root: Node3D, solids: Array[Rect2], at: Vector3, yaw: float, stripes: Array) -> SmartObject:
	var g := SmartObject.new()
	g.name = "LawnChair"
	g.display_name = "Lawn Chair"
	g.position = at
	g.rotation_degrees.y = yaw
	root.add_child(g)
	var alu := Color("C8CCD0")
	for x in [-0.27, 0.27]:
		RoomBuilder.box(g, Vector3(0.04, 0.04, 0.6), Vector3(x, 0.38, 0), alu)
		RoomBuilder.box(g, Vector3(0.04, 0.4, 0.04), Vector3(x, 0.2, -0.25), alu)
		RoomBuilder.box(g, Vector3(0.04, 0.4, 0.04), Vector3(x, 0.2, 0.25), alu)
		RoomBuilder.box(g, Vector3(0.04, 0.6, 0.04), Vector3(x, 0.65, 0.3), alu)
	for i in 5:
		g.add_material(RoomBuilder.box(g, Vector3(0.52, 0.015, 0.1), Vector3(0, 0.39, -0.24 + i * 0.12), stripes[i % 2]).material_override)
		g.add_material(RoomBuilder.box(g, Vector3(0.52, 0.1, 0.015), Vector3(0, 0.48 + i * 0.1, 0.31), stripes[i % 2]).material_override)
	# The seat faces local -z (the back is at +z).
	Props.finish(g, solids, Vector3(0.6, 0.9, 0.6), Vector3(0, 0, -0.8), Vector3(0, 0, 0.02), Vector3(0, 0.7, -3.0))
	return g


static func _clothesline(root: Node3D, solids: Array[Rect2], a: Vector3, b: Vector3) -> void:
	for p in [a, b]:
		RoomBuilder.box(root, Vector3(0.08, 1.9, 0.08), p + Vector3(0, 0.95, 0), Palette.MUTED)
		RoomBuilder.box(root, Vector3(0.06, 0.06, 0.9), p + Vector3(0, 1.85, 0), Palette.MUTED)
		_solid(root, solids, p, Vector3(0.2, 1.9, 0.2))
	for z in [-0.3, 0.3]:
		RoomBuilder.box(root, Vector3((b - a).length(), 0.015, 0.015), (a + b) / 2.0 + Vector3(0, 1.84, z), Palette.PAPER)
	var items := [[0.5, Vector3(0.6, 0.7, 0.02), Palette.TEAL], [1.3, Vector3(0.5, 0.55, 0.02), Palette.PAPER],
		[2.0, Vector3(0.65, 0.75, 0.02), Palette.CORAL], [2.8, Vector3(0.25, 0.3, 0.02), Palette.GOLD],
		[3.2, Vector3(0.25, 0.3, 0.02), Palette.GOLD]]
	for it in items:
		var s: Vector3 = it[1]
		RoomBuilder.box(root, s, a + Vector3(float(it[0]), 1.84 - s.y / 2.0, 0.3), it[2])


static func _streetlight(root: Node3D, solids: Array[Rect2], out: Dictionary, at: Vector3, toward: float) -> void:
	RoomBuilder.box(root, Vector3(0.14, 4.6, 0.14), at + Vector3(0, 2.3, 0), Color("5A5E63"))
	RoomBuilder.box(root, Vector3(0.08, 0.08, 1.4), at + Vector3(0, 4.55, 0.7 * toward), Color("5A5E63"))
	var head := RoomBuilder.box(root, Vector3(0.4, 0.14, 0.55), at + Vector3(0, 4.48, 1.35 * toward), Palette.LAMP)
	var m: StandardMaterial3D = head.material_override
	m.emission_enabled = true
	m.emission = Color("FFD9A0")
	var l := _omni(root, at + Vector3(0, 4.2, 1.35 * toward), Color("FFC982"), 13.0)
	l.omni_attenuation = 0.8
	RoomBuilder.add_lamp(out, l, m, 0.0, 4.0)
	_solid(root, solids, at, Vector3(0.25, 4, 0.25))


static func _label(parent: Node3D, text: String, pos: Vector3, yaw: float, color: Color, px := 0.006) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.rotation_degrees.y = yaw
	l.pixel_size = px
	l.font_size = 64
	l.outline_size = 0
	l.modulate = color
	l.double_sided = false
	parent.add_child(l)
	return l


## A sign on a pole. `yaw` turns its face (0 = facing the street, +z).
static func _sign(root: Node3D, solids: Array[Rect2], at: Vector3, text: String, bg: Color, fg: Color, size: Vector2, yaw: float) -> void:
	RoomBuilder.box(root, Vector3(0.07, 2.4, 0.07), at + Vector3(0, 1.2, 0), Color("8E9296"))
	var g := Node3D.new()
	g.position = at + Vector3(0, 2.1, 0)
	g.rotation_degrees.y = yaw
	root.add_child(g)
	RoomBuilder.box(g, Vector3(size.x, size.y, 0.03), Vector3(0, 0, 0.05), bg)
	_label(g, text, Vector3(0, 0, 0.07), 0.0, fg, 0.0035)
	_solid(root, solids, at, Vector3(0.15, 2.4, 0.15))


## The corner of Maple St and Oak Ave: green street-name blades and a stop sign.
static func _corner_signs(root: Node3D, solids: Array[Rect2], at: Vector3) -> void:
	RoomBuilder.box(root, Vector3(0.08, 3.1, 0.08), at + Vector3(0, 1.55, 0), Color("8E9296"))
	var green := Color("1F6B45")
	RoomBuilder.box(root, Vector3(1.3, 0.24, 0.03), at + Vector3(0, 3.0, 0), green)            # MAPLE ST (along x)
	_label(root, "MAPLE ST", at + Vector3(0, 3.0, 0.02), 0.0, Palette.PAPER, 0.004)
	_label(root, "MAPLE ST", at + Vector3(0, 3.0, -0.02), 180.0, Palette.PAPER, 0.004)
	RoomBuilder.box(root, Vector3(0.03, 0.24, 1.3), at + Vector3(0, 2.72, 0), green)          # OAK AVE (along z)
	_label(root, "OAK AVE", at + Vector3(0.02, 2.72, 0), 90.0, Palette.PAPER, 0.004)
	_label(root, "OAK AVE", at + Vector3(-0.02, 2.72, 0), -90.0, Palette.PAPER, 0.004)
	var red := Color("C0322B")                                                     # stop sign, facing the street
	var stop := Node3D.new()
	stop.position = at + Vector3(0, 2.15, 0.06)
	root.add_child(stop)
	RoomBuilder.box(stop, Vector3(0.62, 0.62, 0.025), Vector3.ZERO, red)
	RoomBuilder.box(stop, Vector3(0.62, 0.62, 0.025), Vector3.ZERO, red).rotation.z = PI / 4.0   # two squares = an octagon
	_label(stop, "STOP", Vector3(0, 0, 0.02), 0.0, Palette.PAPER, 0.004)
	_solid(root, solids, at, Vector3(0.2, 3, 0.2))





# ================================================================ more cars

## A two-tone pickup truck (forward = +z).
static func _pickup(root: Node3D, solids: Array[Rect2], objects: Dictionary, at: Vector3) -> Car:
	var c := _new_car(root, solids, objects, "pickup", "Mr. Garcia's Pickup", at, 0.0, 5.2, 1.95)
	var body := Color("7A2E2A")
	Props.part(c, Vector3(1.95, 0.62, 5.2), Vector3(0, 0.6, 0), body)
	Props.part(c, Vector3(1.97, 0.18, 5.22), Vector3(0, 0.72, 0), Palette.CREAM, null, false)       # the stripe
	Props.part(c, Vector3(1.8, 0.62, 1.7), Vector3(0, 1.2, 0.6), body)                            # cab
	Props.part(c, Vector3(1.84, 0.4, 1.4), Vector3(0, 1.24, 0.6), Color("33405A"), null, false)
	Props.part(c, Vector3(1.6, 0.4, 0.05), Vector3(0, 1.22, 1.46), Color("33405A"), null, false)
	for x in [-0.9, 0.9]:
		Props.part(c, Vector3(0.12, 0.35, 2.3), Vector3(x, 1.07, -1.35), body.darkened(0.1))          # the bed's sides
	Props.part(c, Vector3(1.9, 0.35, 0.1), Vector3(0, 1.07, -2.5), body.darkened(0.1))
	_bumpers(c, 1.99, 2.62, Palette.MUTED)
	_lamps(c, 0.65, 0.7, 2.62)
	_wheels4(c, 0.88, 1.7)
	_finish_car(c, solids, 1.5)
	return c


## A four-door sedan.
static func _sedan(root: Node3D, solids: Array[Rect2], objects: Dictionary, key: String, title: String, at: Vector3,
		yaw: float, color: Color) -> Car:
	var c := _new_car(root, solids, objects, key, title, at, yaw, 4.6, 1.8)
	Props.part(c, Vector3(1.8, 0.58, 4.6), Vector3(0, 0.56, 0), color)
	Props.part(c, Vector3(1.66, 0.5, 2.4), Vector3(0, 1.1, -0.15), color.lightened(0.05))
	Props.part(c, Vector3(1.7, 0.36, 2.2), Vector3(0, 1.12, -0.15), Color("33405A"), null, false)
	_bumpers(c, 1.84, 2.33, Palette.MUTED)
	_lamps(c, 0.6, 0.64, 2.33)
	_wheels4(c, 0.82, 1.5)
	_finish_car(c, solids, 1.3)
	return c


## A boxy family van with wood trim.
static func _van(root: Node3D, solids: Array[Rect2], objects: Dictionary, at: Vector3, yaw: float) -> Car:
	var c := _new_car(root, solids, objects, "van", "The Hendersons' Van", at, yaw, 4.8, 1.9)
	var body := Color("E8E0C8")
	Props.part(c, Vector3(1.9, 1.3, 4.8), Vector3(0, 0.95, 0), body)
	Props.part(c, Vector3(1.94, 0.3, 4.0), Vector3(0, 0.7, -0.2), Palette.WOOD)
	Props.part(c, Vector3(1.94, 0.42, 3.4), Vector3(0, 1.3, -0.4), Color("33405A"), null, false)
	Props.part(c, Vector3(1.6, 0.5, 0.05), Vector3(0, 1.3, 2.41), Color("33405A"), null, false)
	_bumpers(c, 1.95, 2.42, Palette.MUTED)
	_lamps(c, 0.65, 0.66, 2.42)
	_wheels4(c, 0.87, 1.6)
	_finish_car(c, solids, 1.7)
	return c


## A little red convertible, top down.
static func _convertible(root: Node3D, solids: Array[Rect2], objects: Dictionary, at: Vector3, yaw: float) -> Car:
	var c := _new_car(root, solids, objects, "convertible", "Mr. Parker's Convertible", at, yaw, 4.3, 1.75)
	var red := Color("D23A2E")
	Props.part(c, Vector3(1.75, 0.5, 4.3), Vector3(0, 0.55, 0), red)
	Props.part(c, Vector3(1.5, 0.08, 1.6), Vector3(0, 0.84, -0.2), Color("2B2020"), null, false)    # the seats, inside
	for x in [-0.4, 0.4]:
		Props.part(c, Vector3(0.6, 0.45, 0.15), Vector3(x, 1.0, -0.55), Color("F2F0E6"), null, false)  # white seatbacks
	Props.part(c, Vector3(1.6, 0.32, 0.05), Vector3(0, 1.0, 0.65), Color("A8C8D8"), null, false)        # windshield
	_bumpers(c, 1.79, 2.18, Palette.MUTED)
	_lamps(c, 0.55, 0.62, 2.18)
	_wheels4(c, 0.78, 1.4)
	_finish_car(c, solids, 1.1)
	return c


static func _bumpers(c: Car, w: float, z: float, color: Color) -> void:
	Props.part(c, Vector3(w, 0.12, 0.12), Vector3(0, 0.38, z), color, null, false)
	Props.part(c, Vector3(w, 0.12, 0.12), Vector3(0, 0.38, -z), color, null, false)


static func _lamps(c: Car, x: float, y: float, z: float) -> void:
	for sx in [-x, x]:
		Props.part(c, Vector3(0.3, 0.15, 0.05), Vector3(sx, y, z - 0.03), Palette.PAPER, null, false)
		Props.part(c, Vector3(0.28, 0.13, 0.05), Vector3(sx, y, -z + 0.03), Palette.CORAL, null, false)
		c.add_headlight(Vector3(sx, y, z + 0.05))


static func _wheels4(c: Car, x: float, z: float) -> void:
	for sx in [-x, x]:
		for sz in [-z, z]:
			c.add_wheel(Vector3(sx, 0.31, sz), sz > 0)
