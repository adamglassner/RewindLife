class_name InteriorBuilder
extends RefCounted
## Every house's attic and basement. They're built deep underground, out of the
## way (at RoomBuilder.INTERIOR_Y), with their own walking grid: going through
## the attic door or the basement door takes you there, and the stairs or door
## inside brings you back. (A trick lots of games use: rooms on other floors don't
## need to be stacked above and below to feel like they are.)
##
## Each room has the portal back to its house: key "<home>_attic_exit" or
## "<home>_basement_exit", paired with "<home>_attic_door" / "<home>_basement_door".

const T := 0.15
const HOMES := ["jamie", "hendersons", "garcias", "kowalskis", "nguyens", "parkers", "millers", "obriens", "brooks"]


static func attic_rect(i: int) -> Rect2:
	return Rect2(-20.0 + i * 12.0, -62.0, 9.0, 6.5)


static func basement_rect(i: int) -> Rect2:
	return Rect2(-20.0 + i * 12.0, -52.0, 10.0, 7.5)


## Other rooms on the underground level (the high school's upstairs).
static var extra_rooms: Array[Rect2] = []


## Which attic or basement (or other upstairs room) a point is in (Rect2() if none).
static func room_at(p: Vector3) -> Rect2:
	for r in extra_rooms:
		if r.grow(0.3).has_point(Vector2(p.x, p.z)):
			return r
	for i in HOMES.size():
		for r: Rect2 in [attic_rect(i), basement_rect(i)]:
			if r.grow(0.3).has_point(Vector2(p.x, p.z)):
				return r
	return Rect2()


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2]) -> void:
	extra_rooms = []
	var level := Node3D.new()
	level.name = "AtticsAndBasements"
	level.position = Vector3(0, RoomBuilder.INTERIOR_Y, 0)
	root.add_child(level)
	out["interior_rooms"] = {}
	# A lid over all of them that only casts shadows: no sunshine underground.
	var w := RoomBuilder.INTERIOR_WORLD
	var lid := RoomBuilder.box(level, Vector3(w.size.x, 0.4, w.size.y), Vector3(w.get_center().x, 3.4, w.get_center().y), Palette.INK)
	lid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	for i in HOMES.size():
		var home: String = HOMES[i]
		var c := {"root": level, "out": out, "tex": tex, "solids": solids, "objects": out["objects"], "home": home, "level": 1}
		_attic(c, attic_rect(i), free, i)
		_basement(c, basement_rect(i), free, i)


## Four walls around a room (all of them get cut away in the House Cam on the camera side).
static func _shell(c: Dictionary, r: Rect2, height: float, color: Color, surface: String) -> Array:
	var root: Node3D = c["root"]
	var walls := []
	var cx := r.get_center().x
	var cz := r.get_center().y
	walls.append(RoomBuilder.make_wall(root, "N", Vector3(cx, 0, r.position.y), Vector3(r.size.x + T, height, T), Vector3(0, 0, -1), c["tex"], [], false, color, surface))
	walls.append(RoomBuilder.make_wall(root, "S", Vector3(cx, 0, r.end.y), Vector3(r.size.x + T, height, T), Vector3(0, 0, 1), c["tex"], [], false, color, surface))
	walls.append(RoomBuilder.make_wall(root, "W", Vector3(r.position.x, 0, cz), Vector3(T, height, r.size.y - T), Vector3(-1, 0, 0), c["tex"], [], false, color, surface))
	walls.append(RoomBuilder.make_wall(root, "E", Vector3(r.end.x, 0, cz), Vector3(T, height, r.size.y - T), Vector3(1, 0, 0), c["tex"], [], false, color, surface))
	for w in walls:
		(c["out"]["walls"] as Array).append(w)
	return walls


static func _light(c: Dictionary, at: Vector3, height: float, rng: float, energy: float, color := Palette.LAMP) -> void:
	var fx := RoomBuilder.box(c["root"], Vector3(0.18, 0.18, 0.18), at + Vector3(0, height - 0.35, 0), color)
	var m: StandardMaterial3D = fx.material_override
	m.emission_enabled = true
	m.emission = color
	var cord := RoomBuilder.box(c["root"], Vector3(0.02, 0.25, 0.02), at + Vector3(0, height - 0.13, 0), Palette.INK2)   # the cord
	(c["out"]["ceilings"] as Array).append(fx)      # (hidden with the ceiling in the House Cam)
	(c["out"]["ceilings"] as Array).append(cord)
	Props.light(c["root"], c["out"], at + Vector3(0, height - 0.5, 0), color, rng, energy, energy, m, true)


# ================================================================ attics

static func _attic(c: Dictionary, r: Rect2, free: Array[Rect2], i: int) -> void:
	var home: String = c["home"]
	var hgt := 2.5
	var name := home + "|Attic"
	(c["out"]["interior_rooms"] as Dictionary)[name] = r
	RoomBuilder.make_floor(c["root"], r, Color("B08A5A"), c["tex"]["panel"])
	RoomBuilder.make_ceiling(c["root"], c["out"], r.grow(-T / 2.0), hgt)
	free.append(r.grow(-T / 2.0))
	var walls := _shell(c, r, hgt, Color("C8A878"), "panel")
	# Rafters and pink insulation overhead (they hide with the ceiling in the House Cam)
	for k in int(r.size.x / 1.2):
		var rx := r.position.x + 0.6 + k * 1.2
		var raf := RoomBuilder.box(c["root"], Vector3(0.1, 0.16, r.size.y - 0.2), Vector3(rx, hgt - 0.2, r.get_center().y), Color("8A6A4A"))
		(c["out"]["ceilings"] as Array).append(raf)
	# A round-topped window in the gable (the south wall), with the sky in it
	RoomBuilder.add_int_window(walls[1]["full"], Vector3(r.get_center().x, 1.5, r.end.y - T / 2.0), 0.8, 0.8, true, -1.0, c["out"]["window_mat"])
	_light(c, Vector3(r.get_center().x, 0, r.get_center().y), hgt, 7.0, 1.0, Color("F2D58A"))
	# The stairs back down (in the north-west corner)
	var exit := Furnish.portal_back(c, home + "_attic_exit", "Stairs Down", Vector3(r.position.x + 1.0, 0, r.position.y + 1.55), 180, true)
	# What's up here
	var defs: Array = ["trunk", "xmas", "telescope"] if home == "jamie" else NeighborBuilder.HOMES[home]["attic"]
	var spots := [[Vector3(r.end.x - 1.3, 0, r.position.y + 0.45), 0.0], [Vector3(r.end.x - 0.45, 0, r.get_center().y + 0.4), -90.0],
		[Vector3(r.get_center().x, 0, r.end.y - 0.9), 180.0]]
	for k in defs.size():
		var at: Vector3 = spots[k][0]
		var yaw: float = spots[k][1]
		match String(defs[k]):
			"trunk":
				Furnish.trunk(c, home + "_trunk", at, yaw)
			"xmas":
				Furnish.xmas_boxes(c, home + "_xmas", at, yaw)
			"rocking_horse":
				Furnish.rocking_horse(c, home + "_rocking_horse", at, yaw)
			"telescope":
				Furnish.telescope(c, home + "_telescope", at, yaw)
	Furnish.boxes(c, Vector3(r.position.x + 0.5, 0, r.end.y - 0.5), 0, i * 7 + 1)
	Furnish.boxes(c, Vector3(r.position.x + 1.3, 0, r.end.y - 0.45), 20, i * 7 + 2)
	# An old dress form and a lamp with no shade
	var form := Props.solid(c["root"], Vector3(r.end.x - 0.5, 0, r.end.y - 0.5), 0)
	RoomBuilder.box(form, Vector3(0.05, 1.0, 0.05), Vector3(0, 0.5, 0), Palette.INK2)
	RoomBuilder.box(form, Vector3(0.4, 0.6, 0.28), Vector3(0, 1.3, 0), Palette.CREAM)
	Props.finish(form, c["solids"], Vector3(0.4, 1.6, 0.3), Vector3.ZERO)


# ================================================================ basements

static func _basement(c: Dictionary, r: Rect2, free: Array[Rect2], i: int) -> void:
	var home: String = c["home"]
	var hgt := 2.5
	var name := home + "|Basement"
	(c["out"]["interior_rooms"] as Dictionary)[name] = r
	var floor_col: Color = [Color("6A5A9A"), Color("7A5A3A"), Color("4A6A5A"), Color("8A4A3A"), Color("4A5A7A"), Color("5A5A5A"), Color("7A4A6A"), Color("3A6A7A"), Color("6A6A3A")][i % 9]
	RoomBuilder.make_floor(c["root"], r, floor_col, c["tex"]["carpet"])
	RoomBuilder.make_ceiling(c["root"], c["out"], r.grow(-T / 2.0), hgt)
	free.append(r.grow(-T / 2.0))
	var walls := _shell(c, r, hgt, Color("8A6A4A"), "panel")
	# Little windows up high, at ground level outside
	for k in 2:
		RoomBuilder.add_int_window(walls[0]["full"], Vector3(r.position.x + r.size.x * (0.3 + k * 0.4), 2.05, r.position.y + T / 2.0),
			0.7, 0.3, true, 1.0, c["out"]["window_mat"])
	_light(c, Vector3(r.position.x + r.size.x * 0.3, 0, r.get_center().y), hgt, 6.0, 1.3)
	_light(c, Vector3(r.position.x + r.size.x * 0.72, 0, r.get_center().y), hgt, 6.0, 1.3)
	# The door back up the stairs
	var exit := Furnish.portal_back(c, home + "_basement_exit", "Stairs Up", Vector3(r.position.x + 1.0, 0, r.position.y + 0.12), 0, false)
	# The furnace and water heater in the corner, and a washer & dryer
	Furnish.furnace(c, Vector3(r.end.x - 1.1, 0, r.position.y + 0.45), 0)
	if home != "jamie":
		Furnish.washer(c, home + "_washer", Vector3(r.end.x - 0.4, 0, r.get_center().y + 0.6), -90)
	# A cozy old couch and a rug
	Furnish.couch(c, home + "_basement_couch", Vector3(r.position.x + 0.55, 0, r.end.y - 2.2), 90, Color("8A5A3B"), 1.8)
	Furnish.rug(c, Vector3(r.position.x + 2.6, 0, r.end.y - 2.2), Vector2(2.0, 1.6), Color("C2572F"), "plaid")
	# The fun stuff (what it is depends on the family)
	var defs: Array = ["pool_table", "console", "workbench"] if home == "jamie" else NeighborBuilder.HOMES[home]["basement"]
	# The big table (pool or ping-pong) goes in the middle; everything else against the south wall.
	var depth := {"workbench": 0.65, "console": 0.45, "weights": 1.2, "arcade": 0.75}
	var wall_x := [r.position.x + 2.7, r.end.x - 1.1]
	var wi := 0
	for k in defs.size():
		var d := String(defs[k])
		var at: Vector3
		var yaw := 180.0
		if d == "pool_table" or d == "ping_pong":
			at = Vector3(r.get_center().x + 0.9, 0, r.get_center().y - 0.5)
			yaw = 0.0
		else:
			at = Vector3(wall_x[mini(wi, 1)], 0, r.end.y - T / 2.0 - float(depth.get(d, 0.6)) / 2.0 - 0.03)
			wi += 1
		match d:
			"workbench":
				Furnish.workbench(c, home + "_workbench", at, yaw)
			"pool_table":
				Furnish.pool_table(c, home + "_pool_table", at, yaw)
			"ping_pong":
				Furnish.ping_pong(c, home + "_ping_pong", at, yaw)
			"console":
				Furnish.game_console(c, home + "_console", at, yaw)
			"weights":
				Furnish.weights(c, home + "_weights", at, yaw)
			"arcade":
				Furnish.arcade_cabinet(c, home + "_arcade", "Space Blasters (Arcade Game)", at, yaw, Color("4FD8FF"))
