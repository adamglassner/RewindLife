extends SceneTree
## FLICKER CHECK: finds every place two surfaces lie in (almost) the same plane
## and overlap, so the GPU can't decide which one is in front and they flash
## ("z-fighting"). Checks every box in the world, at any angle, and every sign
## (Label3D) against the surface behind it. Run it before every release:
##
##   godot --headless --path . -s res://tools/flicker_check.gd
##
## Two passes: close-up (all walls up, ceilings on) and House Cam (walls cut
## down, ceilings hidden). Reports:
##   SAME PLANE  two different-looking faces in exactly the same place (always flickers)
##   TOO CLOSE   faces less than 1.5 mm apart (can flicker from far away)
##   SIGN        a sign flat against a surface (flickers)
## and ends with "TOTAL n". 0 = all clear.

const NEAR := 0.0015
const MIN_SIDE := 0.012
var main: Node
var frame := 0
var total := 0


func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	main.skip_title = true
	root.add_child(main)


func _process(_d: float) -> bool:
	frame += 1
	if frame == 5:
		main.settle_npcs()
		main.rig.set_mode(CameraRig.Mode.FIRST)
		main._update_walls()
		_scan("CLOSE-UP")
		main.rig.set_mode(CameraRig.Mode.HOUSE)
		for w in main.room["walls"]:
			(w["full"] as Node3D).visible = false
			(w["stub"] as Node3D).visible = true
		for c in main.room["ceilings"]:
			(c as Node3D).visible = false
		_scan("HOUSE-CAM")
		print("TOTAL %d" % total)
		return true
	return false


func _look(mi: MeshInstance3D) -> String:
	var m = mi.material_override
	if m == null:
		return "none"
	if m is StandardMaterial3D:
		var sm := m as StandardMaterial3D
		var t := sm.albedo_texture
		return "%s|%s|%s|%s|%s" % [sm.albedo_color.to_html(), str(t.get_instance_id()) if t else "-", str(sm.uv1_scale) if t else "",
			str(sm.get_instance_id()) if sm.emission_enabled else "", str(sm.transparency)]
	return str(m.get_instance_id())


func _where(n: Node) -> String:
	var p := []
	var x := n
	while x and x != main and p.size() < 3:
		p.push_front(String(x.name).substr(0, 20))
		x = x.get_parent()
	return "/".join(p) + " @" + str((n as Node3D).global_position.snapped(Vector3(0.01, 0.01, 0.01)))


func _scan(label: String) -> void:
	var faces := {}      # bucket -> [face]
	var boxes: Array = []
	for mi in main.find_children("*", "MeshInstance3D", true, false):
		if not mi.is_visible_in_tree() or not (mi.mesh is BoxMesh):
			continue
		var t: Transform3D = mi.global_transform
		var s: Vector3 = (mi.mesh as BoxMesh).size
		var look := _look(mi)
		boxes.append([t, s, mi])
		for ax in 3:
			var n: Vector3 = t.basis[ax]
			var len_n := n.length()
			if len_n < 0.0001:
				continue
			var half := s[ax] / 2.0 * len_n
			n = n / len_n
			var a1 := (ax + 1) % 3
			var a2 := (ax + 2) % 3
			var u: Vector3 = t.basis[a1]
			var v: Vector3 = t.basis[a2]
			var hu := s[a1] / 2.0 * u.length()
			var hv := s[a2] / 2.0 * v.length()
			if hu * 2.0 < MIN_SIDE or hv * 2.0 < MIN_SIDE:
				continue
			u = u.normalized()
			v = v.normalized()
			for sg in [-1.0, 1.0]:
				var nn: Vector3 = n * sg
				var c: Vector3 = t.origin + nn * half
				var d := nn.dot(c)
				# Bottoms sitting on a floor can't be seen.
				if nn.y < -0.99 and (absf(c.y) < 0.02 or absf(c.y - RoomBuilder.INTERIOR_Y) < 0.02):
					continue
				# Nor anything under the ground (except down in the stairwells).
				var top_y := c.y + absf(u.y) * hu + absf(v.y) * hv
				if top_y < -0.024 and top_y > -10.0 and not _in_pit(c):
					continue
				var nk := "%d,%d,%d" % [roundi(nn.x * 200.0), roundi(nn.y * 200.0), roundi(nn.z * 200.0)]
				var dk := floori(d / NEAR)
				var f := {"n": nn, "d": d, "c": c, "u": u, "v": v, "hu": hu, "hv": hv, "mi": mi, "look": look}
				var key := nk + "|" + str(dk)
				if not faces.has(key):
					faces[key] = []
				(faces[key] as Array).append(f)
	var hits := 0
	var seen := {}
	var lines: Array = []
	for key in faces:
		var parts: PackedStringArray = (key as String).split("|")
		var lst: Array = faces[key]
		var nxt: Array = faces.get(parts[0] + "|" + str(int(parts[1]) + 1), [])
		for i in lst.size():
			var p: Dictionary = lst[i]
			for j in range(i + 1, lst.size() + nxt.size()):
				var q: Dictionary = lst[j] if j < lst.size() else nxt[j - lst.size()]
				if p["mi"] == q["mi"]:
					continue
				var gap := absf(float(p["d"]) - float(q["d"]))
				if gap >= NEAR:
					continue
				var same_plane := gap < 0.0006
				if p["look"] == q["look"]:
					continue     # (identical surfaces: nothing to see even if they fight)
				var ov := _overlap(p, q)
				if ov.x < MIN_SIDE or ov.y < MIN_SIDE:
					continue
				var mid := _overlap_mid(p, q)
				if _buried(mid + (p["n"] as Vector3) * 0.001, boxes, p["mi"], q["mi"]):
					continue
				var id := "%d-%d" % [mini(p["mi"].get_instance_id(), q["mi"].get_instance_id()), maxi(p["mi"].get_instance_id(), q["mi"].get_instance_id())]
				if seen.has(id):
					continue
				seen[id] = true
				hits += 1
				lines.append([ov.x * ov.y, "  %s %s  %.2fx%.2f m%s  %s  <->  %s" % [label, "SAME PLANE" if same_plane else "TOO CLOSE", ov.x, ov.y,
					"" if same_plane else " (%.1f mm apart)" % (gap * 1000.0), _where(p["mi"]), _where(q["mi"])]])
	lines.sort_custom(func(x, y): return x[0] > y[0])     # biggest first
	for l in lines:
		print(l[1])
	# Signs flat against a surface
	for l in main.find_children("*", "Label3D", true, false):
		var lb := l as Label3D
		if not lb.is_visible_in_tree() or lb.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
			continue
		var ln: Vector3 = lb.global_basis.z.normalized()
		var lc: Vector3 = lb.global_position
		for b in boxes:
			var t: Transform3D = b[0]
			var s: Vector3 = b[1]
			var local := t.affine_inverse() * lc
			if absf(local.x) > s.x / 2.0 + 0.01 or absf(local.y) > s.y / 2.0 + 0.01 or absf(local.z) > s.z / 2.0 + 0.01:
				continue
			for ax in 3:
				var n: Vector3 = t.basis[ax].normalized()
				if absf(n.dot(ln)) < 0.98:
					continue
				var dist := absf(absf(local[ax]) - s[ax] / 2.0) * t.basis[ax].length()
				if dist < 0.0025:
					hits += 1
					print("  %s SIGN  \"%s\" %.1f mm from  %s" % [label, lb.text.replace("\n", " ").substr(0, 24), dist * 1000.0, _where(b[2])])
	print("%s: %d boxes, %d flicker spots" % [label, boxes.size(), hits])
	total += hits


var _pits: Array[Rect2] = []


func _in_pit(p: Vector3) -> bool:
	if _pits.is_empty():
		for k in main.room["rooms"]:
			if String(k).ends_with("Stairs"):
				_pits.append((main.room["rooms"][k] as Rect2).grow(0.3))
		_pits.append(Rect2(13.8, -0.5, 3.0, 4.5))     # Jamie's stairwell
	for r in _pits:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false


## Size of the overlap of q's face with p's face (in p's plane).
func _overlap(p: Dictionary, q: Dictionary) -> Vector2:
	var r := _rect_in(p, q)
	var w := minf(r[1], p["hu"]) - maxf(r[0], -float(p["hu"]))
	var h := minf(r[3], p["hv"]) - maxf(r[2], -float(p["hv"]))
	return Vector2(w, h)


func _overlap_mid(p: Dictionary, q: Dictionary) -> Vector3:
	var r := _rect_in(p, q)
	var a := (minf(r[1], p["hu"]) + maxf(r[0], -float(p["hu"]))) / 2.0
	var b := (minf(r[3], p["hv"]) + maxf(r[2], -float(p["hv"]))) / 2.0
	return (p["c"] as Vector3) + (p["u"] as Vector3) * a + (p["v"] as Vector3) * b


## q's face corners in p's (u, v) frame, as [u0, u1, v0, v1].
func _rect_in(p: Dictionary, q: Dictionary) -> Array:
	var u0 := INF
	var u1 := -INF
	var v0 := INF
	var v1 := -INF
	for su in [-1.0, 1.0]:
		for sv in [-1.0, 1.0]:
			var corner: Vector3 = (q["c"] as Vector3) + (q["u"] as Vector3) * float(q["hu"]) * su + (q["v"] as Vector3) * float(q["hv"]) * sv
			var rel := corner - (p["c"] as Vector3)
			var cu := rel.dot(p["u"])
			var cv := rel.dot(p["v"])
			u0 = minf(u0, cu)
			u1 = maxf(u1, cu)
			v0 = minf(v0, cv)
			v1 = maxf(v1, cv)
	return [u0, u1, v0, v1]


## Is this point inside some other solid box (so nobody can see it)?
func _buried(pt: Vector3, boxes: Array, a: Node, b: Node) -> bool:
	for bx in boxes:
		if bx[2] == a or bx[2] == b:
			continue
		var t: Transform3D = bx[0]
		var s: Vector3 = bx[1]
		var local := t.affine_inverse() * pt
		if absf(local.x) < s.x / 2.0 - 0.0005 and absf(local.y) < s.y / 2.0 - 0.0005 and absf(local.z) < s.z / 2.0 - 0.0005:
			return true
	return false
