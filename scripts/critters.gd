class_name Critters
extends Node3D
## Birds and squirrels, just for life. Birds hop and peck on the lawns and fly
## off when someone comes close (then land somewhere else); squirrels dash
## between the trees and scramble up the trunks. (Each computer has its own:
## they aren't sent online.)

const BIRD_LAWNS := [
	Rect2(3.0, 8.0, 10.0, 4.5), Rect2(-1.0, -11.0, 11.0, 5.0), Rect2(-13.0, 9.5, 7.0, 3.5),
	Rect2(24.0, 9.5, 7.0, 3.5), Rect2(3.0, 38.5, 8.0, 3.5), Rect2(-12.0, 38.5, 8.0, 3.5),
Rect2(36.0, 27.5, 12.0, 5.5), Rect2(-12.0, -10.0, 7.0, 4.0),
]
const TREES := [Vector3(-2.4, 0, 11.8), Vector3(13.0, 0, -8.0), Vector3(-1.2, 0, 26.6), Vector3(16.6, 0, 26.6),
	Vector3(30.5, 0, 26.6), Vector3(15.0, 0, 41.5), Vector3(33.0, 0, 41.5)]
const BIRD_COLORS := [Color("C0322A"), Color("4A6FA5"), Color("6B4A3A"), Color("2B2B30"), Color("8A7A5A")]

var main: Node
var birds: Array = []       # {node, wings, state, vel, timer, target}
var squirrels: Array = []   # {node, tail, state, from, to, t, timer}


func setup(p_main: Node) -> void:
	main = p_main
	var rng := RandomNumberGenerator.new()
	rng.seed = 6141986
	for i in 22:
		var b := _make_bird(BIRD_COLORS[rng.randi() % BIRD_COLORS.size()])
		var d := {"node": b, "state": "ground", "vel": Vector3.ZERO, "timer": rng.randf_range(0.5, 3.0), "target": Vector3.ZERO}
		b.position = _lawn_spot()
		b.rotation.y = rng.randf() * TAU
		birds.append(d)
	for i in 5:
		var s := _make_squirrel()
		var tree: Vector3 = TREES[i % TREES.size()]
		s.position = tree + Vector3(0.6, 0, 0.4)
		squirrels.append({"node": s, "state": "wait", "from": s.position, "to": s.position, "t": 0.0, "timer": rng.randf_range(1.0, 6.0)})


func _lawn_spot() -> Vector3:
	var r: Rect2 = BIRD_LAWNS[randi() % BIRD_LAWNS.size()]
	return Vector3(randf_range(r.position.x, r.end.x), 0, randf_range(r.position.y, r.end.y))


func _make_bird(c: Color) -> Node3D:
	var b := Node3D.new()
	add_child(b)
	_box(b, Vector3(0.09, 0.08, 0.16), Vector3(0, 0.08, 0), c)
	_box(b, Vector3(0.07, 0.07, 0.07), Vector3(0, 0.14, -0.08), c.darkened(0.1))     # head
	_box(b, Vector3(0.02, 0.02, 0.04), Vector3(0, 0.13, -0.13), Color("E8B83A"))      # beak
	_box(b, Vector3(0.05, 0.02, 0.08), Vector3(0, 0.08, 0.1), c.darkened(0.2))         # tail
	var wings := Node3D.new()
	wings.name = "Wings"
	wings.position = Vector3(0, 0.1, 0)
	b.add_child(wings)
	for x in [-1.0, 1.0]:
		var w := Node3D.new()
		w.name = "L" if x < 0 else "R"
		wings.add_child(w)
		_box(w, Vector3(0.12, 0.012, 0.09), Vector3(x * 0.07, 0, 0), c.darkened(0.15))
	return b


func _make_squirrel() -> Node3D:
	var s := Node3D.new()
	add_child(s)
	var fur := Color("8A5A3A")
	_box(s, Vector3(0.12, 0.12, 0.26), Vector3(0, 0.1, 0), fur)
	_box(s, Vector3(0.1, 0.1, 0.1), Vector3(0, 0.17, -0.15), fur.lightened(0.05))
	_box(s, Vector3(0.02, 0.02, 0.02), Vector3(0.035, 0.19, -0.2), Palette.INK)
	_box(s, Vector3(0.02, 0.02, 0.02), Vector3(-0.035, 0.19, -0.2), Palette.INK)
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.12, 0.13)
	s.add_child(tail)
	_box(tail, Vector3(0.1, 0.24, 0.08), Vector3(0, 0.12, 0.04), fur.lightened(0.15))
	return s


func _box(p: Node3D, size: Vector3, at: Vector3, c: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	mi.material_override = m
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.add_child(mi)


## Another tree a squirrel can run to without going through a house, a shop or a
## fence-high hedge (Vector3.INF if none).
func _next_tree(from: Vector3) -> Vector3:
	var options: Array[Vector3] = []
	for t: Vector3 in TREES:
		if Vector2(t.x - from.x, t.z - from.z).length() < 1.5:
			continue
		if _clear_run(from, t):
			options.append(t)
	if options.is_empty():
		return Vector3.INF
	return options[randi() % options.size()]


var _blockers: Array[Rect2] = []


## True if the straight line from a to b doesn't cross any building.
func _clear_run(a: Vector3, b: Vector3) -> bool:
	if _blockers.is_empty():
		for r: Rect2 in main.room["grid_lists"][1]:     # every building (houses, garages, shops...)
			_blockers.append(r.grow(0.3))
	var dist := Vector2(b.x - a.x, b.z - a.z).length()
	var steps := int(dist / 0.25) + 1
	for i in steps + 1:
		var p := a.lerp(b, float(i) / steps)
		for r in _blockers:
			if r.has_point(Vector2(p.x, p.z)):
				return false
	return true


## Where people (and cars) are, to scare the birds.
func _scarers() -> Array:
	var out := []
	for s in get_tree().get_nodes_in_group("sims"):
		if (s as Node3D).visible:
			out.append((s as Node3D).global_position)
	for n in main.npcs:
		if not (n as Npc).away:
			out.append((n as Node3D).global_position)
	for c in main.room.get("cars", []):
		if (c as Car).driving:
			out.append((c as Node3D).global_position)
	return out


func _process(delta: float) -> void:
	if not visible:
		return
	var h: float = main.clock.hour_float()
	var day := h > 5.5 and h < 20.5
	var people := _scarers()
	var t := Time.get_ticks_msec() * 0.001
	for d in birds:
		var b: Node3D = d["node"]
		b.visible = day
		if not day:
			continue
		var wings: Node3D = b.get_node("Wings")
		match d["state"]:
			"ground":
				d["timer"] -= delta
				# peck, peck, hop
				b.get_child(1).position.y = 0.14 - maxf(0.0, sin(t * 6.0 + b.position.x)) * 0.04
				if d["timer"] <= 0.0:
					d["timer"] = randf_range(0.8, 3.5)
					var hop := Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
					b.position += hop
					b.rotation.y = atan2(-hop.x, -hop.z)
				for p: Vector3 in people:
					if Vector2(p.x - b.position.x, p.z - b.position.z).length() < 3.2:
						# Scared! Fly off to another lawn.
						d["state"] = "fly"
						d["target"] = _lawn_spot()
						var away := (b.position - p)
						away.y = 0.0
						d["vel"] = away.normalized() * 3.0 + Vector3(0, 3.5, 0)
						break
			"fly":
				var flap := sin(t * 30.0) * 0.9
				(wings.get_node("L") as Node3D).rotation.z = -flap
				(wings.get_node("R") as Node3D).rotation.z = flap
				var to: Vector3 = d["target"] + Vector3(0, 6.0, 0)
				var steer: Vector3 = (to - b.position).normalized() * 5.0
				d["vel"] = (d["vel"] as Vector3).lerp(steer, delta * 0.8)
				b.position += d["vel"] * delta
				b.rotation.y = atan2(-d["vel"].x, -d["vel"].z)
				if Vector2(to.x - b.position.x, to.z - b.position.z).length() < 1.5:
					d["state"] = "land"
			"land":
				var flap2 := sin(t * 22.0) * 0.6
				(wings.get_node("L") as Node3D).rotation.z = -flap2
				(wings.get_node("R") as Node3D).rotation.z = flap2
				b.position = b.position.move_toward(d["target"], delta * 3.0)
				if b.position.distance_to(d["target"]) < 0.05:
					b.position = d["target"]
					d["state"] = "ground"
					(wings.get_node("L") as Node3D).rotation.z = 0.0
					(wings.get_node("R") as Node3D).rotation.z = 0.0
	for d in squirrels:
		var s: Node3D = d["node"]
		s.visible = day
		if not day:
			continue
		(s.get_node("Tail") as Node3D).rotation.x = -0.3 + sin(t * 5.0 + s.position.z) * 0.25
		match d["state"]:
			"wait":
				d["timer"] -= delta
				var scared := false
				for p: Vector3 in people:
					if p.distance_to(s.position) < 2.5:
						scared = true
				if d["timer"] <= 0.0 or scared:
					var tree := _next_tree(s.position)
					if tree == Vector3.INF:
						d["timer"] = randf_range(2.0, 5.0)
						continue
					d["from"] = s.position
					d["to"] = tree + Vector3(randf_range(-0.5, 0.5), 0, 0.35)
					d["t"] = 0.0
					d["state"] = "run"
			"run":
				var dist: float = (d["from"] as Vector3).distance_to(d["to"])
				d["t"] += delta * 4.5 / maxf(dist, 0.5)
				var p: Vector3 = (d["from"] as Vector3).lerp(d["to"], minf(1.0, d["t"]))
				p.y = absf(sin(d["t"] * dist * 3.0)) * 0.08        # bounding
				s.position = p
				var dir: Vector3 = d["to"] - d["from"]
				s.rotation = Vector3(0, atan2(-dir.x, -dir.z), 0)
				if d["t"] >= 1.0:
					d["state"] = "climb"
					d["timer"] = 0.0
			"climb":
				# up the trunk, pause in the branches, then back down
				d["timer"] += delta
				var up: float = minf(d["timer"] * 1.5, 2.6)
				if d["timer"] > 6.0:
					up = maxf(0.0, 2.6 - (d["timer"] - 6.0) * 1.5)
				s.position.y = up
				s.rotation = Vector3(-PI / 2.0 if (d["timer"] < 2.0 or d["timer"] > 6.0) else 0.0, s.rotation.y, 0)
				if d["timer"] > 6.0 and up <= 0.0:
					s.rotation.x = 0.0
					d["state"] = "wait"
					d["timer"] = randf_range(2.0, 8.0)
