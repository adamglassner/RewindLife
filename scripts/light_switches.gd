class_name LightSwitches
extends RefCounted
## A light switch on the wall of every room that has lights, right beside its
## door (or on its longest wall if it has none). Walk up to it and flip it, like
## anything else you use; floor lamps work the same way. main.gd does the
## switching, for the whole room.
##
## In the House Cam the walls come down, so each switch hangs on the low wall
## stub instead (main.gd moves it).

const PLATE_Y := 1.2       # up on a full wall
const STUB_Y := 0.22       # on the low stub the House Cam shows


static func build(root: Node3D, out: Dictionary) -> void:
	out["light_switches"] = []
	var rooms: Dictionary = out["rooms"]
	var level1: Dictionary = out.get("interior_rooms", {})
	# Which rooms have lights?
	var lit := {}
	for lamp in out["lamps"]:
		var l = lamp["light"]
		if l == null:
			continue
		var p := (l as Node3D).global_position
		var key := room_for(rooms, level1, p)
		if key != "":
			lit[key] = true
	var keys := lit.keys()
	keys.sort()
	for key in keys:
		if String(key).ends_with("Jail Cell"):
			continue      # (no switch inside the cell)
		var r: Rect2 = rooms[key]
		var lv := 1 if level1.has(key) else 0
		var spot := _place(out, r, lv)
		if spot.is_empty():
			continue
		_make(root, out, key, r, spot, lv)


## The room (key) a point is in, on its own level.
static func room_for(rooms: Dictionary, level1: Dictionary, p: Vector3) -> String:
	var under := p.y < RoomBuilder.INTERIOR_Y * 0.5
	var best := ""
	var best_area := INF
	for k in rooms:
		if level1.has(k) != under:
			continue
		var r: Rect2 = rooms[k]
		if r.grow(0.05).has_point(Vector2(p.x, p.z)) and r.get_area() < best_area:
			best = k
			best_area = r.get_area()
	return best


## Find a wall of the room (by a door, if it has one) for the switch.
## Returns {"wall", "along_x", "at" (along the wall), "plane" (switch face), "inward"}.
static func _place(out: Dictionary, r: Rect2, lv: int) -> Dictionary:
	var best := {}
	var best_score := -INF
	for w in out["walls"]:
		var full: Node3D = w["full"]
		var wy := (w["body"] as Node3D).global_position.y if (w["body"] as Node3D).is_inside_tree() else 0.0
		if (lv == 1) != (wy < RoomBuilder.INTERIOR_Y * 0.5):
			continue
		var ax: bool = w["along_x"]
		var plane: float = w["plane"]
		var lo := r.position.x if ax else r.position.y
		var hi := r.end.x if ax else r.end.y
		var e0 := r.position.y if ax else r.position.x
		var e1 := r.end.y if ax else r.end.x
		if absf(plane - e0) > 0.2 and absf(plane - e1) > 0.2:
			continue
		var inward := 1.0 if absf(plane - e0) <= 0.2 else -1.0
		var spans: Array = w["spans"]
		var candidates := []
		for o in w["openings"]:
			var oc: float = o["c"]
			if oc < lo - 0.2 or oc > hi + 0.2:
				continue
			for s in [1.0, -1.0]:
				candidates.append([oc + s * (float(o["w"]) / 2.0 + 0.28), 10.0])
		for sp in spans:
			candidates.append([float(sp[0]) + 0.6, 1.0])
			candidates.append([float(sp[1]) - 0.6, 1.0])
			if lv == 1:
				var t := float(sp[0]) + 0.9
				while t < float(sp[1]) - 0.9:
					candidates.append([t, 0.0])
					t += 0.5
		for cand in candidates:
			var at: float = cand[0]
			if at < lo + 0.3 or at > hi - 0.3:
				continue
			var in_span := false
			for sp in spans:
				if at > float(sp[0]) + 0.12 and at < float(sp[1]) - 0.12:
					in_span = true
			if not in_span:
				continue
			# (down in an attic or basement, keep clear of the stairs and boxes)
			if lv == 1 and _blocked1(out, ax, at, plane + inward * 0.65):
				continue
			var score: float = cand[1] + (hi - lo) * 0.01
			if score > best_score:
				best_score = score
				best = {"wall": w, "along_x": ax, "at": at, "plane": plane + inward * (float(w["thick"]) / 2.0 + 0.008),
					"inward": inward}
	return best


static func _make(root: Node3D, out: Dictionary, key: String, r: Rect2, spot: Dictionary, lv: int) -> void:
	var home := key.get_slice("|", 0)
	var o := SmartObject.new()
	var skey := "switch_" + key.replace("|", "_").replace(" ", "_").replace("'", "").to_lower()
	o.name = skey
	o.display_name = "Light Switch"
	o.kind = "light_switch"
	o.home = home
	o.level = lv
	o.set_meta("room", key)
	root.add_child(o)
	var ax: bool = spot["along_x"]
	var at: float = spot["at"]
	var plane: float = spot["plane"]
	var inward: float = spot["inward"]
	var base_y := RoomBuilder.INTERIOR_Y if lv == 1 else 0.0
	var pos := Vector3(at, base_y, plane) if ax else Vector3(plane, base_y, at)
	var n := Vector3(0, 0, inward) if ax else Vector3(inward, 0, 0)
	o.position = pos
	o.rotation.y = atan2(n.x, n.z)
	# The switch plate (local +z faces into the room)
	var plate := Node3D.new()
	plate.name = "Plate"
	plate.position = Vector3(0, PLATE_Y, 0)
	o.add_child(plate)
	o.add_material(RoomBuilder.box(plate, Vector3(0.085, 0.13, 0.012), Vector3(0, 0, 0.006), Palette.CREAM).material_override)
	RoomBuilder.box(plate, Vector3(0.022, 0.045, 0.014), Vector3(0, 0.012, 0.019), Color("D8D0C0"))
	RoomBuilder.add_shape(o, Vector3(0.3, 0.36, 0.14), Vector3(0, PLATE_Y, 0.07))
	o.approach_point = pos + n * 0.65
	o.approach_point.y = 0.0
	if lv == 1:
		o.approach_point.y = 0.0
	o.use_point = o.approach_point
	o.look_point = pos + Vector3(0, PLATE_Y, 0)
	(out["objects"] as Dictionary)[skey] = o
	(out["light_switches"] as Array).append({"obj": o, "wall": spot["wall"]})


static func _blocked1(out: Dictionary, ax: bool, at: float, off: float) -> bool:
	var p := Vector2(at, off) if ax else Vector2(off, at)
	for r: Rect2 in out.get("solids1", []):
		if r.grow(0.2).has_point(p):
			return true
	return false
