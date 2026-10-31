class_name HouseBuilder
extends RefCounted
## The rest of the house, east of the living room:
##
##            z=0.5 +----------------+  stair hall: stairs UP to the attic (east half),
##                  |  stairwell     |  stairs DOWN to the basement (west half)
##   z=2.3  +-------+--------+       |
##          | HALLWAY  bath/laundry/parents doors on the north wall
##   z=3.8  +--[door]-------+--------+  kitchen door on the stair hall's south wall
##          | BEDROOM       |
##   z=8.45 +---------------+
##        x=8.15       x=12.65  x=14.3  x=16.2
##
## Locked doors are painted onto the wall (they never open, so they need no
## opening). The bedroom door is a real door in a real opening.

const T := 0.15            # wall thickness
const HX0 := 8.15          # hallway: west end (living room's right wall)
const HX1 := 14.3          # hallway meets the stair hall
const HZ0 := 2.3           # hallway north face
const HZ1 := 3.8           # hallway south face
const SX1 := 16.2          # stair hall east face
const SZ0 := 0.5           # stair hall north face
const STAIR_H := 4.1       # the stairwell is taller (room to stand at the attic door)
const RAIL_X := 15.3       # the half wall between the up and down flights
const UP_Z0 := 3.35        # bottom step of the up flight (it climbs north)
const LANDING_Y := 2.24    # top landing, at the attic door
const PIT_Y := -2.1        # bottom of the basement stairs
const BX1 := 12.65         # bedroom east face
const BZ0 := 3.95          # bedroom north face
const BZ1 := 8.45          # bedroom south face
const BED_DOOR_X := 9.3
## The north wing (behind the hallway): bathroom, laundry room, Mom & Dad's room.
const WZ0 := -4.0          # the wing's north (inside) face
const BATH_X := 9.3        # door centers on the hallway's north wall
const LAUNDRY_X := 11.1
const PARENTS_X := 12.95


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2],
		free: Array[Rect2], doorways: Array[Rect2], buildings: Array[Rect2]) -> void:
	var objects: Dictionary = out["objects"]
	var walls: Array = out["walls"]
	var glass_mat: StandardMaterial3D = out["window_mat"]
	var H := RoomBuilder.H

	# ================================================================ HALLWAY
	var hall_carpet := Color("8E4E26")
	RoomBuilder.make_floor(root, Rect2(HX0, HZ0, SX1 - 0.85 - HX0, HZ1 - HZ0), hall_carpet, tex["carpet"])
	RoomBuilder.make_floor(root, Rect2(SX1 - 0.85, SZ0, 0.85, HZ1 - SZ0), hall_carpet, tex["carpet"])
	free.append(Rect2(HX0, HZ0, SX1 - 0.85 - HX0, HZ1 - HZ0))

	var hall_n := RoomBuilder.make_wall(root, "HallNorth", Vector3((HX0 + HX1 - T) / 2, 0, HZ0 - T / 2), Vector3(HX1 - T - HX0, H, T),
		Vector3(0, 0, -1), tex, [{"c": BATH_X, "w": 0.9, "h": 2.1}, {"c": LAUNDRY_X, "w": 0.9, "h": 2.1}, {"c": PARENTS_X, "w": 0.9, "h": 2.1}],
		true, Color.WHITE, "hall")
	var hall_s := RoomBuilder.make_wall(root, "HallSouth", Vector3((HX0 + HX1) / 2, 0, HZ1 + T / 2), Vector3(HX1 - HX0, H, T),
		Vector3(0, 0, 1), tex, [{"c": BED_DOOR_X, "w": 0.9, "h": 2.1}], true, Color.WHITE, "hall")
	walls.append_array([hall_n, hall_s])
	RoomBuilder.make_ceiling(root, out, Rect2(HX0, HZ0, HX1 - HX0, HZ1 - HZ0), H)
	# The bedroom side of the hallway wall gets wallpaper (doorway left open)
	var bd0 := BED_DOOR_X - 0.45
	var bd1 := BED_DOOR_X + 0.45
	RoomBuilder.add_skin(hall_s, 1.0, HX0, bd0, 0.18, H - 0.08, tex, "wallpaper")
	RoomBuilder.add_skin(hall_s, 1.0, bd1, BX1, 0.18, H - 0.08, tex, "wallpaper")
	RoomBuilder.add_skin(hall_s, 1.0, bd0, bd1, 2.1, H - 0.08, tex, "wallpaper")

	# Runner rug and family photos
	RoomBuilder.box(root, Vector3(5.8, 0.02, 0.8), Vector3(11.3, 0.01, (HZ0 + HZ1) / 2), Palette.RUST)
	RoomBuilder.box(root, Vector3(5.6, 0.03, 0.6), Vector3(11.3, 0.015, (HZ0 + HZ1) / 2), Color("C2572F"), tex["plaid"], 4.0)
	var photo_colors := [Palette.ROSE, Palette.CRT, Palette.GOLD]
	var photo_x := [10.2, 12.05, 13.75]
	# The photos hang on the wall (and hide with it); this invisible object makes them usable.
	var photos := SmartObject.new()
	photos.name = "FamilyPhotos"
	photos.display_name = "Family Photos"
	root.add_child(photos)
	for i in 3:
		photos.add_material(RoomBuilder.box_at(hall_n["full"], Vector3(0.44, 0.52, 0.03), Vector3(photo_x[i], 1.6, HZ0 + 0.015), Palette.WOOD_DARK).material_override)
		photos.add_material(RoomBuilder.box_at(hall_n["full"], Vector3(0.34, 0.42, 0.035), Vector3(photo_x[i], 1.6, HZ0 + 0.02), photo_colors[i]).material_override)
	# (one small shape per photo: a single long one used to block the doorways between them)
	for i in 3:
		RoomBuilder.add_shape(photos, Vector3(0.44, 0.52, 0.04), Vector3(photo_x[i], 1.6, HZ0 + 0.03))
	photos.approach_point = Vector3(12.05, 0, HZ0 + 0.85)
	photos.use_point = photos.approach_point
	photos.look_point = Vector3(12.05, 1.6, HZ0)
	hall_n["attached"] = [photos]
	objects["photos"] = photos

	# The doors to the bathroom, the laundry room and Mom & Dad's room (see _build_wing)
	for d in [[BATH_X, Palette.CREAM], [LAUNDRY_X, Palette.CREAM], [PARENTS_X, Color("7A4A2E")]]:
		RoomBuilder.make_casing(hall_n, d[0], 0.9, 2.1, Palette.CREAM)
		(out["swing_doors"] as Array).append(make_swing_door(hall_n, d[0], 0.9, 2.1, d[1], Vector3(0, 0, -1), false))
		RoomBuilder.make_floor(root, Rect2(d[0] - 0.45, HZ0 - T / 2.0, 0.9, T / 2.0), Palette.WOOD_DARK)
		doorways.append(Rect2(d[0] - 0.35, HZ0 - 0.6, 0.7, 1.2))
	_build_wing(root, out, tex, solids, free, doorways, objects)

	# Hallway lights (no windows here, so they're always on)
	var hall_light := _light(root, Vector3(11.0, 2.3, (HZ0 + HZ1) / 2), Palette.LAMP, 4.5)
	RoomBuilder.add_lamp(out, hall_light, _fixture(root, Vector3(11.0, H - 0.12, (HZ0 + HZ1) / 2), out), 0.8, 1.1)

	# ================================================================ STAIR HALL
	var st_w := RoomBuilder.make_wall(root, "StairWest", Vector3(HX1 - T / 2, 0, (SZ0 - T + HZ0) / 2), Vector3(T, STAIR_H, HZ0 - SZ0 + T),
		Vector3(-1, 0, 0), tex, [], false, Color.WHITE, "hall")
	var st_n := RoomBuilder.make_wall(root, "StairNorth", Vector3((HX1 - T + SX1 + T) / 2, 0, SZ0 - T / 2), Vector3(SX1 - HX1 + 2 * T, STAIR_H, T),
		Vector3(0, 0, -1), tex, [], false, Color.WHITE, "hall")
	var st_e := RoomBuilder.make_wall(root, "StairEast", Vector3(SX1 + T / 2, 0, (SZ0 - T + HZ1 + T) / 2), Vector3(T, STAIR_H, HZ1 - SZ0 + 2 * T),
		Vector3(1, 0, 0), tex, [], false, Color.WHITE, "hall")
	var st_s := RoomBuilder.make_wall(root, "StairSouth", Vector3((HX1 + SX1 + T) / 2, 0, HZ1 + T / 2), Vector3(SX1 - HX1 + T, STAIR_H, T),
		Vector3(0, 0, 1), tex, [{"c": KitchenBuilder.DOOR_X, "w": 0.9, "h": 2.1}], true, Color.WHITE, "hall")
	walls.append_array([st_w, st_n, st_e, st_s])
	RoomBuilder.make_ceiling(root, out, Rect2(HX1, SZ0, SX1 - HX1, HZ1 - SZ0), STAIR_H)
	# The wall above the hallway ceiling, where the hallway opens into the tall stairwell
	var header := RoomBuilder.box(root, Vector3(T, STAIR_H - H, HZ1 - HZ0), Vector3(HX1 - T / 2, (H + STAIR_H) / 2, (HZ0 + HZ1) / 2),
		Color.WHITE, tex["hall"])
	(out["ceilings"] as Array).append(header)
	_build_stairs(root, out, objects, st_n, tex, doorways)
	var st_light := _light(root, Vector3(15.0, 3.75, 2.4), Palette.LAMP, 6.5)
	RoomBuilder.add_lamp(out, st_light, _fixture(root, Vector3(15.0, STAIR_H - 0.12, 2.4), out), 0.8, 1.1)

	# ================================================================ BEDROOM
	RoomBuilder.make_floor(root, Rect2(HX0, BZ0, BX1 - HX0, BZ1 - BZ0), Color.WHITE, tex["teal_shag"])
	RoomBuilder.make_floor(root, Rect2(BED_DOOR_X - 0.45, HZ1, 0.9, BZ0 - HZ1), Palette.WOOD_DARK)
	free.append(Rect2(HX0, BZ0, BX1 - HX0, BZ1 - BZ0))
	doorways.append(Rect2(BED_DOOR_X - 0.35, 3.25, 0.7, 1.25))

	var bw := RoomBuilder.make_wall(root, "BedWest", Vector3(HX0 - T / 2, 0, (6.0 + BZ1 + T) / 2), Vector3(T, H, BZ1 + T - 6.0),
		Vector3(-1, 0, 0), tex, [], false, Color.WHITE, "wallpaper")
	var bs := RoomBuilder.make_wall(root, "BedSouth", Vector3((HX0 - T + BX1 + T) / 2, 0, BZ1 + T / 2), Vector3(BX1 - HX0 + 2 * T, H, T),
		Vector3(0, 0, 1), tex, [], false, Color.WHITE, "wallpaper")
	var be := RoomBuilder.make_wall(root, "BedEast", Vector3(BX1 + T / 2, 0, (BZ0 + BZ1 + T) / 2), Vector3(T, H, BZ1 + T - BZ0),
		Vector3(1, 0, 0), tex, [], false, Color.WHITE, "wallpaper")
	walls.append_array([bw, bs, be])
	RoomBuilder.make_ceiling(root, out, Rect2(HX0, BZ0, BX1 - HX0, BZ1 - BZ0), H)

	# The bedroom door: the only one that opens. It swings into the bedroom.
	RoomBuilder.make_casing(hall_s, BED_DOOR_X, 0.9, 2.1, Palette.CREAM)
	(out["swing_doors"] as Array).append(make_swing_door(hall_s, BED_DOOR_X, 0.9, 2.1, Palette.PAPER, Vector3(0, 0, 1)))

	_build_bedroom(root, out, tex, solids, objects, bw, be, hall_s, glass_mat)
	KitchenBuilder.build(root, out, tex, solids, free, doorways, buildings, hall_s, st_s, be)
	var bed_light := _light(root, Vector3(10.4, 2.35, 6.2), Palette.LAMP, 6.0)
	RoomBuilder.add_lamp(out, bed_light, _fixture(root, Vector3(10.4, H - 0.12, 6.2), out), 0.45, 0.9, "bedroom")

	# ================================================================ OUTSIDE
	buildings.append(Rect2(HX0 - T, WZ0 - T, SX1 + T - (HX0 - T), BZ1 + T - (WZ0 - T)))
	RoomBuilder.add_siding(st_n, -1.0, STAIR_H, tex)
	RoomBuilder.add_siding(st_e, 1.0, STAIR_H, tex, -INF, HZ1 + T)
	RoomBuilder.add_siding(bw, -1.0, H, tex, RoomBuilder.D + T, INF)
	RoomBuilder.add_siding(bs, 1.0, H, tex, -INF, BX1, true, false)
	RoomBuilder.add_ext_window(bw["full"], Vector3(HX0 - T - 0.02, 1.55, 6.8), Vector3(0.04, 0.92, 1.12), out)
	RoomBuilder.add_ext_window(st_e["full"], Vector3(SX1 + T + 0.02, 2.6, 2.0), Vector3(0.04, 0.7, 0.7), out)
	# Roofs (the kitchen has its own). None of them reaches into the tall stairwell.
	RoomBuilder.make_roof(root, out, Rect2(HX0 - T, WZ0 - T, BX1 - (HX0 - T), BZ1 + T - (WZ0 - T)), H, 0.5,
		RoomBuilder.ROOF, true, 0.0, 0.0)
	RoomBuilder.make_roof(root, out, Rect2(BX1, WZ0 - T, HX1 - BX1, HZ1 + T - (WZ0 - T)), H, 0.5,
		RoomBuilder.ROOF, true, 0.0, 0.0, 0.35, 0.0)
	RoomBuilder.make_roof(root, out, Rect2(HX1 - T, SZ0 - T, SX1 - HX1 + 2 * T, HZ1 - SZ0 + 2 * T), STAIR_H, 0.6)


# ================================================================ the north wing

##   z=-4.0  +--------------------------------------+
##           |        MOM & DAD'S ROOM               |
##   z=-0.4  +----------+                            |
##           | BATHROOM |---------+  (it wraps       |
##   z=0.55  |          | LAUNDRY |   round to its   |
##           |          |         |   door)          |
##   z=2.15  +--[door]--+--[door]-+----[door]--------+  (the hallway)
##          x=8.15    10.25  10.4  12.0  12.15       14.15
static func _build_wing(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], objects: Dictionary) -> void:
	var H := RoomBuilder.H
	var walls: Array = out["walls"]
	var x0 := HX0
	var x1 := HX1 - T
	var z1 := HZ0 - T          # the hallway wall's north face
	# Outside walls
	var wn := RoomBuilder.make_wall(root, "WingNorth", Vector3((x0 - T + x1 + T) / 2.0, 0, WZ0 - T / 2.0), Vector3(x1 - x0 + 2 * T, H, T),
		Vector3(0, 0, -1), tex, [], false, Color.WHITE, "wallpaper")
	var ww := RoomBuilder.make_wall(root, "WingWest", Vector3(x0 - T / 2.0, 0, (WZ0 - 0.15) / 2.0), Vector3(T, H, -0.15 - WZ0),
		Vector3(-1, 0, 0), tex, [], false, Color.WHITE, "wallpaper")
	var we := RoomBuilder.make_wall(root, "WingEast", Vector3(x1 + T / 2.0, 0, (WZ0 + SZ0 - T) / 2.0), Vector3(T, H, SZ0 - T - WZ0),
		Vector3(1, 0, 0), tex, [], false, Color.WHITE, "wallpaper")
	walls.append_array([wn, ww, we])
	RoomBuilder.add_siding(wn, -1.0, H, tex)
	RoomBuilder.add_siding(ww, -1.0, H, tex, -INF, INF, true, false)
	RoomBuilder.add_siding(we, 1.0, H, tex, -INF, INF, true, false)
	# Inside walls
	var bath_n := RoomBuilder.make_wall(root, "BathNorth", Vector3((x0 + 10.4) / 2.0, 0, -0.475), Vector3(10.4 - x0, H, T),
		Vector3(0, 0, -1), tex, [], true, Color.WHITE, "wallpaper")
	var bath_e := RoomBuilder.make_wall(root, "BathEast", Vector3(10.325, 0, (-0.4 + z1) / 2.0), Vector3(T, H, z1 + 0.4),
		Vector3(1, 0, 0), tex, [], true, Color.WHITE, "wallpaper")
	var ldry_n := RoomBuilder.make_wall(root, "LaundryNorth", Vector3((10.4 + 12.15) / 2.0, 0, 0.475), Vector3(12.15 - 10.4, H, T),
		Vector3(0, 0, -1), tex, [], true, Color.WHITE, "wallpaper")
	var ldry_e := RoomBuilder.make_wall(root, "LaundryEast", Vector3(12.075, 0, (0.55 + z1) / 2.0), Vector3(T, H, z1 - 0.55),
		Vector3(1, 0, 0), tex, [], true, Color.WHITE, "wallpaper")
	walls.append_array([bath_n, bath_e, ldry_n, ldry_e])
	# Floors (they meet under the middle of each wall), ceilings, walkable areas
	var parents_floor := Color("C9A88A")
	for f in [Rect2(x0 - T / 2.0, WZ0 - T / 2.0, x1 - x0 + T, -0.475 - (WZ0 - T / 2.0)),
			Rect2(10.325, -0.475, x1 + T / 2.0 - 10.325, 0.95), Rect2(12.075, 0.475, x1 + T / 2.0 - 12.075, HZ0 - T / 2.0 - 0.475)]:
		RoomBuilder.make_floor(root, f, parents_floor, tex["carpet"])
	RoomBuilder.make_floor(root, Rect2(x0 - T / 2.0, -0.475, 10.325 - (x0 - T / 2.0), HZ0 - T / 2.0 + 0.475), Color.WHITE, tex["lino"])
	RoomBuilder.make_floor(root, Rect2(10.325, 0.475, 12.075 - 10.325, HZ0 - T / 2.0 - 0.475), Color("D9D2C2"), tex["lino"])
	for cr in [Rect2(x0, WZ0, x1 - x0, -0.55 - WZ0), Rect2(10.4, -0.55, x1 - 10.4, 0.95), Rect2(12.15, 0.4, x1 - 12.15, z1 - 0.4),
			Rect2(x0, -0.4, 10.25 - x0, z1 + 0.4), Rect2(10.4, 0.55, 12.0 - 10.4, z1 - 0.55)]:
		RoomBuilder.make_ceiling(root, out, cr, H)
		free.append(cr)
	doorways.append(Rect2(10.6, -0.95, 3.4, 0.8))     # the parents' room wraps round: join its parts
	doorways.append(Rect2(12.4, -0.3, 1.6, 1.1))
	out["wing_rooms"] = {"jamie|Parents Room": Rect2(x0, WZ0, x1 - x0, -0.4 - WZ0), "jamie|Bathroom": Rect2(x0, -0.4, 10.25 - x0, z1 + 0.4),
		"jamie|Laundry Room": Rect2(10.4, 0.55, 1.6, z1 - 0.55)}
	# Windows: two in Mom & Dad's room, one on the east side
	var glass: StandardMaterial3D = out["window_mat"]
	for wx in [9.6, 12.7]:
		RoomBuilder.add_ext_window(wn["full"], Vector3(wx, 1.5, WZ0 - T - 0.02), Vector3(1.1, 1.0, 0.04), out)
		RoomBuilder.add_int_window(wn["full"], Vector3(wx, 1.55, WZ0), 1.0, 0.95, true, 1.0, glass)
	RoomBuilder.add_ext_window(we["full"], Vector3(x1 + T + 0.02, 1.5, -2.3), Vector3(0.04, 1.0, 1.0), out)
	RoomBuilder.add_int_window(we["full"], Vector3(x1, 1.55, -2.3), 0.9, 0.95, false, -1.0, glass)

	var c := {"root": root, "out": out, "tex": tex, "solids": solids, "objects": objects, "home": "jamie", "level": 0}
	# ---- Mom & Dad's room
	Furnish.bed(c, "jamie_parents_bed", "Mom & Dad's Bed", "parents_bed", Vector3(11.2, 0, WZ0 + 1.05), 0, Color("6B4A6A"), true)
	Furnish.nightstand(c, Vector3(10.05, 0, WZ0 + 0.25), 0)
	Furnish.nightstand(c, Vector3(12.35, 0, WZ0 + 0.25), 0)
	Furnish.closet(c, "jamie_closet", Vector3(x0 + 0.31, 0, -2.2), 90)
	Furnish.vanity(c, "jamie_vanity", Vector3(x1 - 0.24, 0, -2.3), -90)
	Furnish.dresser(c, "jamie_parents_dresser", Vector3(9.3, 0, -0.85), 180, Palette.WOOD_DARK)
	Furnish.rug(c, Vector3(11.2, 0, -1.6), Vector2(2.2, 1.4), Color("6B4A6A"), "plaid")
	_room_light(root, out, Vector3(11.2, 0, -2.2))
	# ---- the bathroom
	Furnish.tub(c, "jamie_tub", Vector3(9.2, 0, -0.04), 0, Color("BFE0EE"))
	Furnish.toilet(c, "jamie_toilet", Vector3(9.94, 0, 0.9), -90)
	Furnish.bath_sink(c, "jamie_bath_sink", Vector3(x0 + 0.24, 0, 1.0), 90, Color("F2A0B5"))
	_room_light(root, out, Vector3(9.2, 0, 0.9))
	# ---- the laundry room
	Furnish.washer(c, "jamie_washer", Vector3(11.2, 0, 0.86), 0)
	_room_light(root, out, Vector3(11.2, 0, 1.4))
	(out["npc_spots"] as Dictionary)["jamie"] = {
		"kitchen": [Vector3(15.05, 0, 6.2), -90.0],
		"living": [Vector3(6.6, 0, 2.5), -120.0],
		"bed": [Vector3(12.9, 0, -2.1), 0.0],
		"backyard": [Vector3(6.2, 0, -3.4), 180.0],
	}


static func _room_light(root: Node3D, out: Dictionary, at: Vector3) -> void:
	var l := _light(root, at + Vector3(0, 2.3, 0), Palette.LAMP, 4.5, false)
	RoomBuilder.add_lamp(out, l, _fixture(root, at + Vector3(0, RoomBuilder.H - 0.12, 0), out), 0.4, 1.3)


# ================================================================ bedroom

static func _build_bedroom(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], objects: Dictionary,
		bw: Dictionary, be: Dictionary, hall_s: Dictionary, glass_mat: StandardMaterial3D) -> void:
	# ---- Bed: head against the east wall, a Memphis-pattern comforter ----
	var bed := SmartObject.new()
	bed.name = "Bed"
	bed.display_name = "Your Bed"
	root.add_child(bed)
	var bz := 7.625
	bed.add_material(RoomBuilder.box(bed, Vector3(2.2, 0.28, 1.45), Vector3(11.55, 0.2, bz), Palette.WOOD_DARK).material_override)
	RoomBuilder.box(bed, Vector3(2.05, 0.2, 1.36), Vector3(11.5, 0.44, bz), Palette.PAPER)
	bed.add_material(RoomBuilder.box(bed, Vector3(1.55, 0.07, 1.48), Vector3(11.0, 0.56, bz), Color.WHITE, tex["memphis"], 3.0).material_override)
	RoomBuilder.box(bed, Vector3(0.12, 0.08, 1.48), Vector3(10.2, 0.5, bz), Color.WHITE, tex["memphis"], 3.0)
	RoomBuilder.box(bed, Vector3(0.42, 0.14, 0.95), Vector3(12.25, 0.61, bz), Palette.PAPER)                 # pillow
	bed.add_material(RoomBuilder.box(bed, Vector3(0.1, 1.1, 1.55), Vector3(12.6, 0.55, bz), Palette.NAVY).material_override)  # headboard
	RoomBuilder.box(bed, Vector3(0.12, 0.06, 1.57), Vector3(12.6, 1.12, bz), Palette.GOLD)
	RoomBuilder.add_shape(bed, Vector3(2.2, 0.65, 1.45), Vector3(11.55, 0.32, bz))
	solids.append(Rect2(10.45, bz - 0.725, 2.2, 1.45))
	bed.approach_point = Vector3(11.55, 0, 6.45)
	bed.use_point = Vector3(11.55, 0, bz)
	bed.look_point = Vector3(8.0, 0.5, bz)
	objects["bed"] = bed

	# ---- Nightstand with a lava lamp and a clock radio ----
	var stand := StaticBody3D.new()
	stand.collision_layer = 2
	root.add_child(stand)
	RoomBuilder.box(stand, Vector3(0.5, 0.55, 0.45), Vector3(12.35, 0.275, 6.6), Palette.WOOD)
	RoomBuilder.add_shape(stand, Vector3(0.5, 0.55, 0.45), Vector3(12.35, 0.275, 6.6))
	solids.append(Rect2(12.1, 6.375, 0.5, 0.45))
	RoomBuilder.box(root, Vector3(0.13, 0.08, 0.13), Vector3(12.22, 0.59, 6.6), Palette.GOLD)
	var lava := RoomBuilder.box(root, Vector3(0.1, 0.3, 0.1), Vector3(12.22, 0.78, 6.6), Palette.CORAL)
	var lava_mat: StandardMaterial3D = lava.material_override
	lava_mat.emission_enabled = true
	lava_mat.emission = Palette.CORAL
	RoomBuilder.box(root, Vector3(0.08, 0.05, 0.08), Vector3(12.22, 0.955, 6.6), Palette.GOLD)
	RoomBuilder.box(root, Vector3(0.22, 0.1, 0.14), Vector3(12.45, 0.6, 6.6), Palette.INK)
	var digits := RoomBuilder.box(root, Vector3(0.12, 0.04, 0.01), Vector3(12.45, 0.61, 6.525), Palette.CORAL)
	var dmat: StandardMaterial3D = digits.material_override
	dmat.emission_enabled = true
	dmat.emission = Palette.CORAL
	dmat.emission_energy_multiplier = 0.5
	var lava_light := _light(root, Vector3(12.0, 0.9, 6.4), Palette.CORAL, 2.2, false)
	RoomBuilder.add_lamp(out, lava_light, lava_mat, 0.2, 0.7)

	# ---- Desk with the diary, a desk lamp and a puzzle cube ----
	var desk := SmartObject.new()
	desk.name = "Desk"
	desk.display_name = "Desk & Diary"
	root.add_child(desk)
	var dz := 6.8
	desk.add_material(RoomBuilder.box(desk, Vector3(0.7, 0.05, 1.4), Vector3(8.5, 0.76, dz), Palette.WOOD).material_override)
	desk.add_material(RoomBuilder.box(desk, Vector3(0.62, 0.73, 0.42), Vector3(8.5, 0.37, dz - 0.45), Palette.WOOD_DARK).material_override)
	RoomBuilder.box(desk, Vector3(0.05, 0.73, 0.05), Vector3(8.8, 0.37, dz + 0.65), Palette.WOOD_DARK)
	RoomBuilder.box(desk, Vector3(0.05, 0.73, 0.05), Vector3(8.2, 0.37, dz + 0.65), Palette.WOOD_DARK)
	desk.add_material(RoomBuilder.box(desk, Vector3(0.26, 0.045, 0.32), Vector3(8.62, 0.805, dz + 0.1), Color("7B2D3A")).material_override)  # the diary
	RoomBuilder.box(desk, Vector3(0.03, 0.05, 0.08), Vector3(8.76, 0.81, dz + 0.1), Palette.GOLD)                      # its little lock
	RoomBuilder.box(desk, Vector3(0.18, 0.012, 0.24), Vector3(8.6, 0.79, dz - 0.25), Palette.PAPER)                     # notebook paper
	RoomBuilder.box(desk, Vector3(0.06, 0.12, 0.06), Vector3(8.35, 0.84, dz - 0.5), Palette.TEAL)                       # pencil cup
	var cube_cols := [Palette.CORAL, Palette.GOLD, Palette.TEAL, Palette.PAPER, Palette.NAVY, Palette.AVOCADO, Palette.CORAL, Palette.ROSE]
	for i in 8:
		var o := Vector3(i % 2, (i / 2) % 2, i / 4) * 0.035
		RoomBuilder.box(desk, Vector3(0.034, 0.034, 0.034), Vector3(8.35, 0.8, dz + 0.45) + o, cube_cols[i])          # puzzle cube
	RoomBuilder.box(desk, Vector3(0.14, 0.03, 0.14), Vector3(8.3, 0.795, dz + 0.55), Palette.INK)                       # desk lamp
	RoomBuilder.box(desk, Vector3(0.025, 0.4, 0.025), Vector3(8.3, 1.0, dz + 0.55), Palette.INK)
	var dl := RoomBuilder.box(desk, Vector3(0.18, 0.1, 0.14), Vector3(8.4, 1.2, dz + 0.55), Palette.LAMP)
	var dl_mat: StandardMaterial3D = dl.material_override
	dl_mat.emission_enabled = true
	dl_mat.emission = Palette.LAMP
	var desk_light := _light(root, Vector3(8.5, 1.15, dz + 0.4), Palette.LAMP, 2.5)
	RoomBuilder.add_lamp(out, desk_light, dl_mat, 0.1, 1.2, "bedroom")
	RoomBuilder.add_shape(desk, Vector3(0.7, 0.85, 1.4), Vector3(8.5, 0.42, dz))
	solids.append(Rect2(HX0, dz - 0.7, 0.7, 1.4))
	# Chair
	var chair := StaticBody3D.new()
	chair.collision_layer = 2
	root.add_child(chair)
	RoomBuilder.box(chair, Vector3(0.42, 0.06, 0.42), Vector3(9.1, 0.45, dz), Palette.ROSE)
	RoomBuilder.box(chair, Vector3(0.06, 0.5, 0.42), Vector3(9.33, 0.73, dz), Palette.ROSE)
	for lx in [8.92, 9.28]:
		for lz in [dz - 0.18, dz + 0.18]:
			RoomBuilder.box(chair, Vector3(0.035, 0.43, 0.035), Vector3(lx, 0.21, lz), Palette.INK)
	solids.append(Rect2(8.89, dz - 0.21, 0.42, 0.42))
	desk.approach_point = Vector3(9.8, 0, dz)
	desk.use_point = Vector3(9.1, 0, dz)
	desk.look_point = Vector3(8.0, 0.95, dz)
	objects["desk"] = desk

	# ---- Window over the desk ----
	var wd: Node3D = bw["full"]
	RoomBuilder.add_int_window(wd, Vector3(HX0, 1.55, dz), 1.12, 0.92, false, 1.0, glass_mat)
	RoomBuilder.box_at(wd, Vector3(0.12, 1.4, 0.24), Vector3(HX0 + 0.06, 1.45, dz - 0.78), Palette.ROSE, tex["plaid"], 4.0)
	RoomBuilder.box_at(wd, Vector3(0.12, 1.4, 0.24), Vector3(HX0 + 0.06, 1.45, dz + 0.78), Palette.ROSE, tex["plaid"], 4.0)

	# ---- Posters: a synth band and a synthwave sunset ----
	RoomBuilder.box_at(wd, Vector3(0.03, 0.85, 0.6), Vector3(HX0 + 0.015, 1.55, 8.05), Palette.NAVY)
	RoomBuilder.box_at(wd, Vector3(0.035, 0.3, 0.3), Vector3(HX0 + 0.02, 1.7, 8.0), Palette.ROSE)
	RoomBuilder.box_at(wd, Vector3(0.04, 0.2, 0.2), Vector3(HX0 + 0.025, 1.6, 8.12), Palette.CRT)
	RoomBuilder.box_at(wd, Vector3(0.035, 0.08, 0.5), Vector3(HX0 + 0.02, 1.25, 8.05), Palette.GOLD)
	var ed: Node3D = be["full"]
	RoomBuilder.box_at(ed, Vector3(0.03, 0.8, 1.0), Vector3(BX1 - 0.015, 1.75, 7.6), Palette.INK)
	var sun_cols := [Palette.GOLD, Color("F2A65A"), Palette.CORAL, Palette.ROSE]
	for i in 4:
		RoomBuilder.box_at(ed, Vector3(0.035, 0.07, 0.56 - i * 0.1), Vector3(BX1 - 0.02, 1.92 - i * 0.1, 7.6), sun_cols[i])
	for i in 3:
		RoomBuilder.box_at(ed, Vector3(0.035, 0.012, 0.9), Vector3(BX1 - 0.02, 1.5 - i * 0.07, 7.6), Palette.CRT)

	# ---- Dresser with a mirror, a boombox and tapes ----
	var dresser := SmartObject.new()
	dresser.name = "Dresser"
	dresser.display_name = "Dresser"
	root.add_child(dresser)
	var dx := 11.4
	dresser.add_material(RoomBuilder.box(dresser, Vector3(1.4, 1.0, 0.55), Vector3(dx, 0.5, BZ0 + 0.275), Palette.CREAM).material_override)
	for row in 3:
		var y := 0.22 + row * 0.3
		RoomBuilder.box(dresser, Vector3(1.3, 0.012, 0.01), Vector3(dx, y + 0.14, BZ0 + 0.555), Palette.INK2)
		for side in [-0.3, 0.3]:
			RoomBuilder.box(dresser, Vector3(0.12, 0.03, 0.03), Vector3(dx + side, y, BZ0 + 0.565), Palette.GOLD)
	RoomBuilder.box(dresser, Vector3(0.52, 0.22, 0.15), Vector3(dx - 0.3, 1.11, BZ0 + 0.2), Palette.INK2)             # boombox
	for s in [-0.17, 0.17]:
		RoomBuilder.box(dresser, Vector3(0.14, 0.14, 0.01), Vector3(dx - 0.3 + s, 1.1, BZ0 + 0.28), Palette.MUTED)
	RoomBuilder.box(dresser, Vector3(0.36, 0.03, 0.03), Vector3(dx - 0.3, 1.25, BZ0 + 0.2), Palette.MUTED)
	for i in 4:
		RoomBuilder.box(dresser, Vector3(0.11, 0.07, 0.016), Vector3(dx + 0.35, 1.035, BZ0 + 0.15 + i * 0.03), [Palette.CORAL, Palette.PAPER, Palette.TEAL, Palette.GOLD][i])
	var md: Node3D = hall_s["full"]
	RoomBuilder.box_at(md, Vector3(0.8, 0.95, 0.03), Vector3(dx, 1.75, BZ0 + 0.015), Palette.GOLD)                   # mirror frame
	var mirror := RoomBuilder.box_at(md, Vector3(0.7, 0.85, 0.035), Vector3(dx, 1.75, BZ0 + 0.02), Color("C9D9E3"))
	(mirror.material_override as StandardMaterial3D).roughness = 0.05
	(mirror.material_override as StandardMaterial3D).metallic = 0.6
	RoomBuilder.add_shape(dresser, Vector3(1.4, 1.0, 0.55), Vector3(dx, 0.5, BZ0 + 0.275))
	solids.append(Rect2(dx - 0.7, BZ0, 1.4, 0.55))
	dresser.approach_point = Vector3(dx, 0, 5.0)
	dresser.use_point = dresser.approach_point
	dresser.look_point = Vector3(dx, 1.3, BZ0)
	objects["dresser"] = dresser

	# ---- Bean bag and a round rug ----
	var bag := SmartObject.new()
	bag.name = "BeanBag"
	bag.display_name = "Bean Bag"
	root.add_child(bag)
	bag.add_material(RoomBuilder.box(bag, Vector3(0.8, 0.32, 0.8), Vector3(8.6, 0.16, 5.5), Color("7B4FA0")).material_override)
	bag.add_material(RoomBuilder.box(bag, Vector3(0.6, 0.18, 0.6), Vector3(8.62, 0.38, 5.55), Color("8E62B3")).material_override)
	RoomBuilder.box(bag, Vector3(0.2, 0.05, 0.28), Vector3(8.95, 0.345, 5.2), Palette.CORAL).rotation.y = 0.5   # a comic book
	RoomBuilder.add_shape(bag, Vector3(0.8, 0.5, 0.8), Vector3(8.6, 0.25, 5.5))
	solids.append(Rect2(8.2, 5.1, 0.8, 0.8))
	bag.approach_point = Vector3(9.35, 0, 5.5)
	bag.use_point = Vector3(8.62, 0, 5.5)
	bag.look_point = Vector3(10.6, 0.6, 5.5)
	objects["bean_bag"] = bag
	RoomBuilder.box(root, Vector3(2.2, 0.015, 1.7), Vector3(10.6, 0.008, 5.6), Palette.NAVY)
	RoomBuilder.box(root, Vector3(2.0, 0.02, 1.5), Vector3(10.6, 0.01, 5.6), Palette.ROSE)

	# ---- Glow-in-the-dark stars on the ceiling (close-up cameras only) ----
	var stars := Node3D.new()
	root.add_child(stars)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1986
	var star_mat := StandardMaterial3D.new()
	star_mat.albedo_color = Color("D8F5C8")
	star_mat.emission_enabled = true
	star_mat.emission = Color("C8F7B0")
	star_mat.emission_energy_multiplier = 0.6
	for i in 26:
		var s := RoomBuilder.box(stars, Vector3(0.07, 0.01, 0.07), Vector3(rng.randf_range(9.0, 12.4), RoomBuilder.H - 0.086, rng.randf_range(4.3, 8.2)), Color.WHITE)
		s.material_override = star_mat
		s.rotation.y = rng.randf() * PI
	(out["ceilings"] as Array).append(stars)


# ================================================================ stairs

## Walkable stairs: UP to the attic door (east half) and DOWN into a stairwell
## to the basement door (west half). Jamie's height on them comes from
## floor_height(); the steps are clickable floor but not solid.
static func _build_stairs(root: Node3D, out: Dictionary, objects: Dictionary, st_n: Dictionary, tex: Dictionary,
		doorways: Array[Rect2]) -> void:
	var tread := Color("8E4E26")
	var steps := StaticBody3D.new()       # clickable, so you can click a step to walk there
	steps.collision_layer = RoomBuilder.LAYER_FLOOR
	steps.collision_mask = 0
	steps.add_to_group("floor")
	root.add_child(steps)

	# ---- UP: 7 steps north to a landing at the attic door
	var ux0 := RAIL_X + 0.05
	var ux := (ux0 + SX1) / 2.0
	var uw := SX1 - ux0
	for i in 7:
		var top := 0.32 * (i + 1)
		var z0 := UP_Z0 - 0.35 * (i + 1)
		RoomBuilder.box(root, Vector3(uw, top, 0.35), Vector3(ux, top / 2.0, z0 + 0.175), Palette.WOOD)
		RoomBuilder.box(root, Vector3(uw - 0.25, 0.012, 0.35), Vector3(ux, top + 0.006, z0 + 0.175), tread, tex["carpet"], 3.0)
		RoomBuilder.add_shape(steps, Vector3(uw, 0.05, 0.35), Vector3(ux, top - 0.025, z0 + 0.175))
	var land_z1 := UP_Z0 - 0.35 * 7
	RoomBuilder.box(root, Vector3(uw, LANDING_Y, land_z1 - SZ0), Vector3(ux, LANDING_Y / 2.0, (SZ0 + land_z1) / 2.0), Palette.WOOD)
	RoomBuilder.box(root, Vector3(uw - 0.1, 0.012, land_z1 - SZ0 - 0.05), Vector3(ux, LANDING_Y + 0.006, (SZ0 + land_z1) / 2.0), tread, tex["carpet"], 3.0)
	RoomBuilder.add_shape(steps, Vector3(uw, 0.05, land_z1 - SZ0), Vector3(ux, LANDING_Y - 0.025, (SZ0 + land_z1) / 2.0))

	# The attic door, at the top of the landing
	var attic := _door_object(root, "Attic Door", st_n, ux, 0.75, 1.6, LANDING_Y, Color("7A4A2E"), true)
	attic.approach_point = Vector3(ux, 0, SZ0 + 0.35)
	attic.use_point = attic.approach_point
	objects["attic_door"] = attic

	# ---- The half wall between the flights, with balusters and a handrail
	RoomBuilder.box(root, Vector3(0.1, 3.2, HZ0 - SZ0), Vector3(RAIL_X, -0.65, (SZ0 + HZ0) / 2.0), Palette.CREAM)
	RoomBuilder.box(root, Vector3(0.1, 0.05, HZ0 - SZ0 - 0.004), Vector3(RAIL_X, 0.975, (SZ0 + HZ0) / 2.0), Palette.WOOD_DARK)
	for i in 7:
		var z := UP_Z0 - 0.35 * i - 0.175
		if z > HZ0:
			RoomBuilder.box(root, Vector3(0.04, 0.9, 0.04), Vector3(RAIL_X + 0.03, 0.32 * (i + 1) + 0.45, z), Palette.CREAM)
	var rail := RoomBuilder.box(root, Vector3(0.06, 0.06, 3.0), Vector3(RAIL_X + 0.03, 2.36, (UP_Z0 + SZ0) / 2.0), Palette.WOOD_DARK)
	rail.rotation_degrees.x = 42.4
	# Solid, so Jamie can't hop from one flight to the other
	_wall_block(root, Vector3(0.1, 6.4, UP_Z0 - 0.35 - SZ0), Vector3(RAIL_X, 0.9, (SZ0 + UP_Z0 - 0.35) / 2.0))

	# ---- DOWN: 7 steps north into the stairwell, to the basement door
	var dx0 := HX1
	var dx1 := RAIL_X - 0.05
	var dx := (dx0 + dx1) / 2.0
	var dw := dx1 - dx0
	var bottom_z := HZ0 - 0.2 * 7
	for i in 7:
		var top := -0.3 * (i + 1)
		var z1 := HZ0 - 0.2 * i
		RoomBuilder.box(root, Vector3(dw, top - PIT_Y + 0.1, 0.2), Vector3(dx, (top + PIT_Y - 0.1) / 2.0, z1 - 0.1), Palette.WOOD)
		RoomBuilder.box(root, Vector3(dw - 0.2, 0.012, 0.2), Vector3(dx, top + 0.006, z1 - 0.1), tread, tex["carpet"], 3.0)
		RoomBuilder.add_shape(steps, Vector3(dw, 0.05, 0.2), Vector3(dx, top - 0.025, z1 - 0.1))
	RoomBuilder.box(root, Vector3(dw, 0.1, bottom_z - SZ0), Vector3(dx, PIT_Y - 0.05, (SZ0 + bottom_z) / 2.0), Palette.WOOD_DARK)
	# The riser under the hallway floor's edge (no peeking under the floor from the stairwell)
	RoomBuilder.box(root, Vector3(dw, -0.012 - (PIT_Y - 0.1), 0.098), Vector3(dx, (-0.012 + PIT_Y - 0.1) / 2.0, HZ0 + 0.051), Palette.WOOD)
	RoomBuilder.add_shape(steps, Vector3(dw, 0.05, bottom_z - SZ0), Vector3(dx, PIT_Y - 0.025, (SZ0 + bottom_z) / 2.0))
	# Stairwell walls below the floor (west and north), wood paneled like a basement
	RoomBuilder.box(root, Vector3(0.1, 2.25, HZ0 - SZ0), Vector3(dx0 - 0.05, -1.125, (SZ0 + HZ0) / 2.0), Palette.WOOD, tex["panel"])
	RoomBuilder.box(root, Vector3(dw + 0.2, 2.25, 0.1), Vector3(dx, -1.125, SZ0 - 0.05), Palette.WOOD, tex["panel"])
	_wall_block(root, Vector3(0.1, 2.4, HZ0 - SZ0), Vector3(dx0 - 0.05, PIT_Y / 2.0, (SZ0 + HZ0) / 2.0))
	_wall_block(root, Vector3(dw, 2.4, 0.1), Vector3(dx, PIT_Y / 2.0, SZ0 - 0.05))
	RoomBuilder.box(root, Vector3(dw, 0.05, 0.05), Vector3(dx, -0.02, HZ0 + 0.02), Palette.WOOD_DARK)      # nosing at the top
	var pit := Node3D.new()
	pit.position = Vector3(0, PIT_Y, 0)
	root.add_child(pit)
	var basement := _door_object(root, "Basement Door", {"full": pit, "along_x": true, "plane": SZ0 - 0.05, "thick": 0.1},
		dx, 0.78, 1.9, 0.0, Color("7A4A2E"), true, PIT_Y)
	basement.approach_point = Vector3(dx, 0, SZ0 + 0.32)
	basement.use_point = basement.approach_point
	objects["basement_door"] = basement
	var pit_light := _light(root, Vector3(dx, -0.6, 1.3), Palette.LAMP, 3.2, false)
	RoomBuilder.add_lamp(out, pit_light, null, 0.45, 0.6)

	# Walking lanes for click-to-walk: up the stairs, down into the stairwell,
	# and the bit of hallway floor that joins them.
	doorways.append(Rect2(15.75, 0.75, 0.25, 2.75))     # up flight + landing
	doorways.append(Rect2(15.0, 3.25, 1.0, 0.25))      # hallway -> bottom of the up flight
	doorways.append(Rect2(14.5, 0.75, 0.5, 1.75))      # down flight + bottom


## Stairs in the other houses: [{"rect", "z0", "dir", "len", "h"}]. The floor rises
## from 0 (at z0) to h over len meters along z (dir = +1/-1).
static var RAMPS: Array = []


static func add_ramp(rect: Rect2, z0: float, dir: float, length: float, h: float) -> void:
	RAMPS.append({"rect": rect, "z0": z0, "dir": dir, "len": length, "h": h})


## Floor height at (x, z): 0 almost everywhere, sloping on the stairs.
static func floor_height(x: float, z: float) -> float:
	for r in RAMPS:
		if (r["rect"] as Rect2).has_point(Vector2(x, z)):
			return clampf((z - float(r["z0"])) * float(r["dir"]) / float(r["len"]), 0.0, 1.0) * float(r["h"])
	if x >= RAIL_X and x <= SX1 and z >= SZ0 and z <= UP_Z0 + 0.175:
		return clampf((UP_Z0 + 0.175 - z) / 2.45, 0.0, 1.0) * LANDING_Y
	if x >= HX1 - 0.2 and x < RAIL_X and z >= SZ0 - 0.2 and z < HZ0:
		return clampf((HZ0 - z) / 1.4, 0.0, 1.0) * PIT_Y
	return 0.0


## An invisible solid box (stops first-person walking; not clickable).
static func _wall_block(root: Node3D, size: Vector3, center: Vector3) -> void:
	var b := StaticBody3D.new()
	b.collision_layer = 2
	b.collision_mask = 0
	root.add_child(b)
	RoomBuilder.add_shape(b, size, center)


## A locked door drawn on a wall (at height `bottom`), with a clickable object in front.
static func _door_object(root: Node3D, title: String, wall: Dictionary, c: float, width: float, height: float,
		bottom: float, color: Color, panels: bool, world_bottom := INF, facing := Vector3(0, 0, 1)) -> SmartObject:
	var wb := bottom if world_bottom == INF else world_bottom
	var obj := SmartObject.new()
	obj.name = title.replace(" ", "")
	obj.display_name = title
	root.add_child(obj)
	var slab := _painted_door(wall, c, width, height, bottom, color, Palette.CREAM, facing, panels)
	for m in slab.get_children():
		if m is MeshInstance3D and String(m.name).begins_with("slab"):
			obj.add_material((m as MeshInstance3D).material_override)
	obj.door_rattle = slab
	obj.rattle_dir = Vector3(0.012, 0, 0)
	var face: float = float(wall["plane"]) + facing.z * float(wall["thick"]) / 2.0
	RoomBuilder.add_shape(obj, Vector3(width, height, 0.14), Vector3(c, wb + height / 2.0, face + facing.z * 0.07))
	obj.look_point = Vector3(c, wb + 1.1, face)
	return obj


# ================================================================ doors

## A locked door painted onto a wall, plus a clickable SmartObject in front of it.
## `side` = +1 or -1: which face of the wall it's on (along the wall's own axis).
static func make_fake_door(root: Node3D, wall: Dictionary, c: float, width: float, height: float, door_name: String,
		slab_color: Color, trim: Color, side: float, panels := false) -> SmartObject:
	var along_x: bool = wall["along_x"]
	var sd := Vector3(0, 0, side) if along_x else Vector3(side, 0, 0)
	var obj := SmartObject.new()
	obj.name = door_name.replace(" ", "").replace("&", "And").replace("'", "")
	obj.display_name = door_name
	root.add_child(obj)
	var slab := _painted_door(wall, c, width, height, 0.0, slab_color, trim, sd, panels)
	for m in slab.get_children():
		if m is MeshInstance3D and m.name.begins_with("slab"):
			obj.add_material((m as MeshInstance3D).material_override)
	obj.door_rattle = slab
	obj.rattle_dir = (Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)) * 0.012
	var face: float = float(wall["plane"]) + side * float(wall["thick"]) / 2.0
	var at := Vector3(c, 0, face) if along_x else Vector3(face, 0, c)
	var size := Vector3(width, height, 0.14) if along_x else Vector3(0.14, height, width)
	RoomBuilder.add_shape(obj, size, at + Vector3(0, height / 2.0, 0) + sd * 0.07)
	# A threshold strip on the floor that stays visible when the wall is lowered
	RoomBuilder.box(root, Vector3(width, 0.012, 0.12) if along_x else Vector3(0.12, 0.012, width), at + sd * 0.06 + Vector3(0, 0.006, 0), Palette.WOOD_DARK)
	obj.approach_point = at + sd * 0.7
	obj.use_point = obj.approach_point
	obj.look_point = at + Vector3(0, 1.1, 0)
	return obj


## Door slab, knob and casing drawn on a wall face. Returns the slab group.
static func _painted_door(wall: Dictionary, c: float, width: float, height: float, bottom: float,
		slab_color: Color, trim: Color, sd: Vector3, panels: bool) -> Node3D:
	var along_x: bool = wall["along_x"]
	var face: float = float(wall["plane"]) + (sd.z if along_x else sd.x) * float(wall["thick"]) / 2.0
	var full: Node3D = wall["full"]
	var p := func(a: float, y: float, o: float) -> Vector3:
		return (Vector3(a, y, face) if along_x else Vector3(face, y, a)) + sd * o
	var s := func(sa: float, sy: float, so: float) -> Vector3:
		return Vector3(sa, sy, so) if along_x else Vector3(so, sy, sa)
	var group := Node3D.new()
	full.add_child(group)
	var slab := RoomBuilder.box(group, s.call(width - 0.04, height - 0.02, 0.06), p.call(c, bottom + height / 2.0, 0.03), slab_color)
	slab.name = "slab"
	if panels:
		for py in [0.32, 0.72]:
			var pn := RoomBuilder.box(group, s.call(width - 0.26, height * 0.33, 0.02), p.call(c, bottom + height * py, 0.065), slab_color.darkened(0.18))
			pn.name = "slab_panel"
	var hx := 1.0 if along_x else 1.0
	RoomBuilder.box(group, Vector3(0.07, 0.07, 0.07), p.call(c + (width / 2.0 - 0.11) * hx, bottom + minf(1.0, height * 0.5), 0.1), Palette.GOLD)
	RoomBuilder.box(full, s.call(0.07, height + 0.07, 0.07), p.call(c - width / 2.0 - 0.035, bottom + (height + 0.07) / 2.0, 0.035), trim)
	RoomBuilder.box(full, s.call(0.07, height + 0.07, 0.07), p.call(c + width / 2.0 + 0.035, bottom + (height + 0.07) / 2.0, 0.035), trim)
	RoomBuilder.box(full, s.call(width, 0.07, 0.07), p.call(c, bottom + height + 0.035, 0.035), trim)
	return group


## A real door that swings open (the bedroom). main.gd opens it when Jamie comes near.
static func make_swing_door(wall: Dictionary, c: float, width: float, height: float, color: Color, swing_into: Vector3, sign := true) -> Dictionary:
	var along_x: bool = wall["along_x"]
	var plane: float = wall["plane"]
	var thick: float = wall["thick"]
	var axis := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var a := c - width / 2.0
	var hinge := Node3D.new()
	var inner := (Vector3(0, 0, plane) if along_x else Vector3(plane, 0, 0)) + swing_into * (thick / 2.0)
	hinge.position = inner + axis * (a + 0.01) - axis * axis.dot(inner)
	(wall["full"] as Node3D).add_child(hinge)
	var slab_w := width - 0.02
	var size := Vector3(slab_w, height - 0.03, 0.045) if along_x else Vector3(0.045, height - 0.03, slab_w)
	RoomBuilder.box(hinge, size, axis * (slab_w / 2.0) + Vector3(0, height / 2.0, 0) - swing_into * 0.03, color)
	RoomBuilder.box(hinge, Vector3(0.07, 0.07, 0.07), axis * (slab_w - 0.09) + Vector3(0, 1.0, 0) + swing_into * 0.02, Palette.GOLD)
	RoomBuilder.box(hinge, Vector3(0.07, 0.07, 0.07), axis * (slab_w - 0.09) + Vector3(0, 1.0, 0) - swing_into * 0.09, Palette.GOLD)
	# A little "KEEP OUT" sign on the hallway side, naturally
	if sign:
		RoomBuilder.box(hinge, Vector3(0.3, 0.12, 0.01) if along_x else Vector3(0.01, 0.12, 0.3), axis * (slab_w / 2.0) + Vector3(0, 1.55, 0) - swing_into * 0.066, Palette.CORAL)
	var angle := deg_to_rad(85.0)
	if (Basis(Vector3.UP, angle) * axis).dot(swing_into) < 0.0:
		angle = -angle
	var center := (Vector3(c, 0, plane) if along_x else Vector3(plane, 0, c))
	return {"hinge": hinge, "angle": angle, "center": center, "open": false}


## A pair of glass shop doors that swing apart into the shop (both open when
## someone comes near). Returns a swing-door entry with two hinges.
static func make_double_door(wall: Dictionary, c: float, width: float, height: float, frame: Color, swing_into: Vector3) -> Dictionary:
	var along_x: bool = wall["along_x"]
	var plane: float = wall["plane"]
	var thick: float = wall["thick"]
	var axis := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var inner := (Vector3(0, 0, plane) if along_x else Vector3(plane, 0, 0)) + swing_into * (thick / 2.0)
	var leaf_w := width / 2.0 - 0.015
	var hinges := []
	var angles := []
	for side: float in [-1.0, 1.0]:
		# Hinged at the outer edge of the opening; the leaf runs back toward the middle.
		var hinge := Node3D.new()
		var edge := c + side * (width / 2.0 - 0.01)
		hinge.position = inner + axis * edge - axis * axis.dot(inner)
		(wall["full"] as Node3D).add_child(hinge)
		var run := -side * axis       # from the hinge toward the middle
		var mid := run * (leaf_w / 2.0) - swing_into * 0.03
		var fsize := Vector3(leaf_w, height - 0.03, 0.05) if along_x else Vector3(0.05, height - 0.03, leaf_w)
		var gsize := Vector3(leaf_w - 0.16, height - 0.5, 0.07) if along_x else Vector3(0.07, height - 0.5, leaf_w - 0.16)
		RoomBuilder.box(hinge, fsize - (Vector3(0, 0, 0.0)), mid + Vector3(0, height / 2.0, 0), frame)
		var glass := RoomBuilder.box(hinge, gsize, mid + Vector3(0, height / 2.0 + 0.12, 0), Color("5E8798"))
		var gm: StandardMaterial3D = glass.material_override
		gm.metallic = 0.15
		gm.roughness = 0.2
		# a push bar on each side
		var bar := Vector3(leaf_w - 0.2, 0.05, 0.04) if along_x else Vector3(0.04, 0.05, leaf_w - 0.2)
		RoomBuilder.box(hinge, bar, mid + Vector3(0, 1.0, 0) + swing_into * 0.05, Palette.MUTED)
		RoomBuilder.box(hinge, bar, mid + Vector3(0, 1.0, 0) - swing_into * 0.05, Palette.MUTED)
		var ang := deg_to_rad(80.0)
		if (Basis(Vector3.UP, ang) * run).dot(swing_into) < 0.0:
			ang = -ang
		hinges.append(hinge)
		angles.append(ang)
	var center := (Vector3(c, 0, plane) if along_x else Vector3(plane, 0, c))
	return {"hinge": hinges[0], "angle": angles[0], "hinge2": hinges[1], "angle2": angles[1], "center": center, "open": false}


# ================================================================ small helpers

static func _light(root: Node3D, pos: Vector3, color: Color, rng: float, shadows := true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.omni_range = rng
	l.shadow_enabled = shadows   # so lights don't shine through walls into other rooms
	root.add_child(l)
	return l


## A small ceiling light fixture (hidden with the ceilings in the House Cam).
static func _fixture(root: Node3D, pos: Vector3, out: Dictionary) -> StandardMaterial3D:
	var f := RoomBuilder.box(root, Vector3(0.4, 0.06, 0.4), pos, Palette.PAPER)
	var m: StandardMaterial3D = f.material_override
	m.emission_enabled = true
	m.emission = Palette.LAMP
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(out["ceilings"] as Array).append(f)
	return m


