class_name Pets
extends RefCounted
## The family dogs and cats: blocky little bodies (facing -z, like people) for
## Npc to walk around the house. A pet's "look" is {"species": "dog"/"cat",
## "color", "accent", "size"}.


static func build(parent: Node3D, look: Dictionary) -> Dictionary:
	var dog: bool = look.get("species", "dog") == "dog"
	var c: Color = look.get("color", Color("B8864A"))
	var a: Color = look.get("accent", c.lightened(0.3))
	var s: float = look.get("size", 1.0 if dog else 0.8)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3(s, s, s)
	parent.add_child(body)
	var legs: Array[Node3D] = []
	var arms: Array[Node3D] = []
	var bw := 0.26 if dog else 0.2
	var bl := 0.62 if dog else 0.46
	var hip_y := 0.3 if dog else 0.22
	# Body, chest patch
	_p(body, Vector3(bw, 0.24, bl), Vector3(0, hip_y + 0.1, 0), c)
	_p(body, Vector3(bw * 0.7, 0.14, 0.02), Vector3(0, hip_y + 0.06, -bl / 2.0 - 0.005), a)
	# Head
	var hz := -bl / 2.0 - 0.1
	var hy := hip_y + (0.3 if dog else 0.24)
	_p(body, Vector3(0.24 if dog else 0.2, 0.22 if dog else 0.18, 0.22 if dog else 0.18), Vector3(0, hy, hz), c)
	_p(body, Vector3(0.012, 0.035, 0.035), Vector3(-0.06, hy + 0.03, hz - 0.11 if dog else hz - 0.09), Palette.INK)   # eyes
	_p(body, Vector3(0.012, 0.035, 0.035), Vector3(0.06, hy + 0.03, hz - 0.11 if dog else hz - 0.09), Palette.INK)
	if dog:
		_p(body, Vector3(0.13, 0.1, 0.14), Vector3(0, hy - 0.05, hz - 0.17), a)          # snout
		_p(body, Vector3(0.06, 0.05, 0.04), Vector3(0, hy - 0.02, hz - 0.25), Palette.INK) # nose
		for x in [-0.13, 0.13]:
			_p(body, Vector3(0.05, 0.16, 0.1), Vector3(x, hy - 0.02, hz + 0.02), c.darkened(0.25))   # floppy ears
		var tail := Node3D.new()
		tail.position = Vector3(0, hip_y + 0.18, bl / 2.0)
		body.add_child(tail)
		var t := _p(tail, Vector3(0.05, 0.05, 0.22), Vector3(0, 0.05, 0.1), c)
		t.rotation.x = -0.6
		tail.set_meta("wag", true)
		parent.set_meta("tail", tail)
		_p(body, Vector3(bw + 0.01, 0.04, 0.05), Vector3(0, hy - 0.12, hz + 0.1), Palette.CORAL)   # collar
	else:
		_p(body, Vector3(0.07, 0.05, 0.03), Vector3(0, hy - 0.04, hz - 0.095), Color("F2A0B5"))     # pink nose
		for x in [-0.06, 0.06]:
			var ear := _p(body, Vector3(0.06, 0.08, 0.03), Vector3(x, hy + 0.12, hz), c)
			ear.rotation.z = -signf(x) * 0.3
		var tail := Node3D.new()
		tail.position = Vector3(0, hip_y + 0.12, bl / 2.0)
		body.add_child(tail)
		_p(tail, Vector3(0.04, 0.32, 0.04), Vector3(0, 0.16, 0.02), c)                   # tail straight up
		parent.set_meta("tail", tail)
	# Four legs: the front left and back right swing together (legs), and the other two (arms)
	var lx := bw / 2.0 - 0.04
	var lz := bl / 2.0 - 0.07
	for d in [[Vector3(-lx, hip_y, -lz), true], [Vector3(lx, hip_y, lz), true], [Vector3(lx, hip_y, -lz), false], [Vector3(-lx, hip_y, lz), false]]:
		var hip := Node3D.new()
		hip.position = d[0]
		body.add_child(hip)
		_p(hip, Vector3(0.07, hip_y, 0.07), Vector3(0, -hip_y / 2.0, 0), c.darkened(0.08))
		_p(hip, Vector3(0.075, 0.04, 0.09), Vector3(0, -hip_y + 0.02, -0.012), a)            # paws
		if d[1]:
			legs.append(hip)
		else:
			arms.append(hip)
	return {"legs": legs, "arms": arms, "body": body}


static func _p(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
