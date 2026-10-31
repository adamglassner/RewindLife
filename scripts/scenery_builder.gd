class_name SceneryBuilder
extends RefCounted
## Everything past the edge of town, so the world doesn't just stop: the
## streets end at DEAD END barricades, and beyond them are woods, fields and
## rolling hills all the way to the horizon.

## The streets end here (cars can't drive past the barricades).
const ROAD_W := -63.4
const ROAD_E := OutdoorBuilder.EAST_END - 2.6   # (Lincoln Avenue: now out past the middle and high schools)
const ROAD_E2 := OutdoorBuilder.EAST_END - 2.6   # (Maple Street and Main Street)
const OAK_N := -73.4
const OAK_S := 73.4
## The town (with its own lawn); everything outside this is countryside.
const TOWN := Rect2(-70, -82, 212, 180)


static func build(root: Node3D, out: Dictionary, tex: Dictionary) -> void:
	_countryside_ground(root, tex)
	# Barricades where each street ends
	for z in [OutdoorBuilder.STREET_Z0, DowntownBuilder.Z0, CivicBuilder.Z0]:
		var z1: float = z + 8.0
		_barricade(root, Vector3(ROAD_W, 0, (z + z1) / 2.0), 90.0, 8.0)
		if z != DowntownBuilder.Z0:      # (Main Street keeps going out of town: that's the highway the traffic comes in on)
			_barricade(root, Vector3(ROAD_E if z == CivicBuilder.Z0 else ROAD_E2, 0, (z + z1) / 2.0), -90.0, 8.0)
	var oak := (OutdoorBuilder.OAK_X0 + OutdoorBuilder.OAK_X1) / 2.0
	_barricade(root, Vector3(oak, 0, OAK_N), 0.0, 7.0)
	_barricade(root, Vector3(oak, 0, OAK_S), 180.0, 7.0)
	_woods(root, out)
	_hills(root)


## Fields and lawns beyond the town (a little lower than the town's lawn, so they never overlap).
static func _countryside_ground(root: Node3D, tex: Dictionary) -> void:
	var holes: Array[Rect2] = [TOWN]
	for piece in OutdoorBuilder.rect_minus(Rect2(-420, -420, 840, 840), holes):
		RoomBuilder.make_floor(root, piece, Color("C8D8B0"), tex["grass"], -0.06).add_to_group("lawn")


## A striped wooden barricade across the road with a DEAD END sign. `yaw` = which way it faces (toward town).
static func _barricade(root: Node3D, at: Vector3, yaw: float, width: float) -> void:
	var g := StaticBody3D.new()
	g.collision_layer = 2 | 16
	g.collision_mask = 0
	g.position = at
	g.rotation_degrees.y = yaw
	root.add_child(g)
	var stripes := int(width / 0.6)
	for row in 2:
		var y := 0.62 + row * 0.42
		for i in stripes:
			var col := Color("F2F0E6") if (i + row) % 2 == 0 else Color("E4572E")
			RoomBuilder.box(g, Vector3(width / stripes - 0.004, 0.24, 0.06), Vector3(-width / 2.0 + (i + 0.5) * width / stripes, y, 0), col)
	for x in [-width / 2.0 + 0.3, 0.0, width / 2.0 - 0.3]:
		RoomBuilder.box(g, Vector3(0.12, 1.2, 0.12), Vector3(x, 0.6, -0.12), Palette.WOOD_DARK)
	# Little amber lamps on top
	for x in [-width / 2.0 + 0.3, width / 2.0 - 0.3]:
		var lamp := RoomBuilder.box(g, Vector3(0.14, 0.14, 0.14), Vector3(x, 1.27, -0.12), Color("F7B03A"))
		var m: StandardMaterial3D = lamp.material_override
		m.emission_enabled = true
		m.emission = Color("F7B03A")
		m.emission_energy_multiplier = 0.6
	RoomBuilder.add_shape(g, Vector3(width, 1.3, 0.4), Vector3(0, 0.65, 0))
	# The DEAD END sign (a yellow diamond) on its own post, off to one side
	var sx := width / 2.0 + 0.9
	RoomBuilder.box(g, Vector3(0.08, 2.2, 0.08), Vector3(sx, 1.1, -0.1), Palette.MUTED)
	var plate := RoomBuilder.box(g, Vector3(0.75, 0.75, 0.03), Vector3(sx, 2.15, -0.04), Color("F2C230"))
	plate.rotation.z = PI / 4.0
	var label := Label3D.new()
	label.text = "DEAD\nEND"
	label.font_size = 48
	label.pixel_size = 0.004
	label.modulate = Palette.INK
	label.position = Vector3(sx, 2.15, -0.02)
	label.double_sided = false
	label.rotation_degrees.y = 0.0
	g.add_child(label)
	var back := RoomBuilder.box(g, Vector3(0.6, 0.6, 0.012), Vector3(sx, 2.15, -0.062), Palette.MUTED)
	back.rotation.z = PI / 4.0


## Woods all around the town: a thick band of trees past the ends of the streets
## and behind the backyards, thinning out into the fields. (One MultiMesh per part,
## so hundreds of trees cost almost nothing.)
static func _woods(root: Node3D, out: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1986
	var inner := Rect2(-67, -81, 208, 178)        # just outside where you can drive
	# Inside town, trees fill the empty lots too, but never the streets, the yards or anywhere you can walk.
	var keep_clear: Array[Rect2] = [OutdoorBuilder.WALK.grow(2.5),
		Rect2(OutdoorBuilder.OAK_X0 - 2.5, -200, OutdoorBuilder.OAK_X1 - OutdoorBuilder.OAK_X0 + 5.0, 400),
		Rect2(-200, OutdoorBuilder.STREET_Z0 - 4.0, 400, OutdoorBuilder.STREET_Z1 - OutdoorBuilder.STREET_Z0 + 8.0),
		Rect2(-200, DowntownBuilder.Z0 - 4.0, 400, DowntownBuilder.Z1 - DowntownBuilder.Z0 + 8.0),
		Rect2(-200, CivicBuilder.Z0 - 4.0, 400, CivicBuilder.Z1 - CivicBuilder.Z0 + 8.0)]
	var spots: Array[Vector3] = []
	var tries := 0
	while spots.size() < 1100 and tries < 30000:
		tries += 1
		var p := Vector2(rng.randf_range(-170, 240), rng.randf_range(-160, 180))
		var blocked := false
		for r in keep_clear:
			if r.has_point(p):
				blocked = true
		if blocked:
			continue
		if inner.has_point(p):
			if rng.randf() < 0.45:
				spots.append(Vector3(p.x, 0, p.y))
			continue
		# distance outside the town edge: dense close in, sparse far out
		var dx := maxf(maxf(inner.position.x - p.x, p.x - inner.end.x), 0.0)
		var dz := maxf(maxf(inner.position.y - p.y, p.y - inner.end.y), 0.0)
		var d := Vector2(dx, dz).length()
		if rng.randf() > clampf(1.15 - d / 70.0, 0.08, 1.0):
			continue
		spots.append(Vector3(p.x, 0, p.y))
	var trunk := _multi(root, Vector3(0.45, 3.2, 0.45), Palette.WOOD_DARK, spots.size())
	var crown_a := _multi(root, Vector3(4.2, 1.7, 4.2), Color.WHITE, spots.size(), true)
	var crown_b := _multi(root, Vector3(3.2, 1.3, 3.4), Color.WHITE, spots.size(), true)
	var crown_c := _multi(root, Vector3(1.4, 2.6, 1.4), Color.WHITE, spots.size(), true)   # (pines get a pointy top)
	out["woods"] = {"crowns": [crown_a, crown_b, crown_c], "pine": []}
	# The trunks are solid (you can't drive or walk through them): one body, a shape per trunk,
	# for the trees anywhere a car could get to (in town and along the highway).
	var trunks := StaticBody3D.new()
	trunks.name = "WoodsTrunks"
	trunks.collision_layer = 2
	trunks.collision_mask = 0
	root.add_child(trunks)
	var reach := TOWN.grow(12.0).merge(Rect2(OutdoorBuilder.EAST_END, DowntownBuilder.Z0 - 14.0, 100.0, DowntownBuilder.Z1 - DowntownBuilder.Z0 + 28.0))
	for i in spots.size():
		var p: Vector3 = spots[i]
		var s := rng.randf_range(0.75, 1.35)
		if reach.has_point(Vector2(p.x, p.z)):
			RoomBuilder.add_shape(trunks, Vector3(0.5, 3.2, 0.5) * s, p + Vector3(0, 1.6 * s, 0))
		var yaw := rng.randf() * TAU
		var pine := rng.randf() < 0.35
		var green: Color = OutdoorBuilder.GREENS[rng.randi() % OutdoorBuilder.GREENS.size()]
		if pine:
			green = Color("2F5A34").lerp(Color("3F6B3A"), rng.randf())
		var b := Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s))
		trunk.multimesh.set_instance_transform(i, Transform3D(b, p + Vector3(0, 1.6 * s, 0)))
		if pine:
			var pb := Basis(Vector3.UP, yaw).scaled(Vector3(s * 0.8, s * 1.3, s * 0.8))
			crown_a.multimesh.set_instance_transform(i, Transform3D(pb, p + Vector3(0, 3.2 * s, 0)))
			crown_b.multimesh.set_instance_transform(i, Transform3D(pb.scaled(Vector3(0.8, 1.0, 0.8)), p + Vector3(0, 4.6 * s, 0)))
			crown_c.multimesh.set_instance_transform(i, Transform3D(b, p + Vector3(0, 6.2 * s, 0)))
		else:
			crown_a.multimesh.set_instance_transform(i, Transform3D(b, p + Vector3(0, 3.7 * s, 0)))
			crown_b.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw + 0.4).scaled(Vector3(s, s, s)), p + Vector3(0.3, 4.9 * s, -0.2)))
			crown_c.multimesh.set_instance_transform(i, Transform3D(b.scaled(Vector3(0.0001, 0.0001, 0.0001)), p))   # (no pointy top)
		(out["woods"]["pine"] as Array).append(pine)
		crown_a.multimesh.set_instance_color(i, green)
		crown_b.multimesh.set_instance_color(i, green.lightened(0.08))
		crown_c.multimesh.set_instance_color(i, green.darkened(0.05))


static func _multi(root: Node3D, size: Vector3, color: Color, count: int, colors := false) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors
	var bm := BoxMesh.new()
	bm.size = size
	mm.mesh = bm
	mm.instance_count = count
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.vertex_color_use_as_albedo = colors
	mi.material_override = mat
	root.add_child(mi)
	return mi


## Low rolling hills and a water tower on the horizon.
static func _hills(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	for i in 18:
		var a := float(i) / 18.0 * TAU + rng.randf_range(-0.1, 0.1)
		var dist := rng.randf_range(230.0, 300.0)
		var c := Vector3(10 + cos(a) * dist, 0, 10 + sin(a) * dist)
		var w := rng.randf_range(80.0, 140.0)
		var h := rng.randf_range(10.0, 26.0) + i * 0.13
		var hill := RoomBuilder.box(root, Vector3(w, h, w * 0.6), c + Vector3(0, h / 2.0 - 4.0, 0),
			Color("6E8F5A").lerp(Color("8FA878"), rng.randf()))
		hill.rotation.y = -a + PI / 2.0
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var top := RoomBuilder.box(root, Vector3(w * 0.6, h * 0.5, w * 0.4), c + Vector3(0, h - 4.0 + h * 0.2, 0),
			Color("7E9F64").lerp(Color("9AB284"), rng.randf()))
		top.rotation.y = -a + PI / 2.0 + 0.2
		top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The town water tower, peeking over the trees
	var wt := Vector3(-95, 0, 95)
	for x in [-2.0, 2.0]:
		for z in [-2.0, 2.0]:
			RoomBuilder.box(root, Vector3(0.4, 18, 0.4), wt + Vector3(x, 9, z), Palette.MUTED)
	RoomBuilder.box(root, Vector3(7, 5, 7), wt + Vector3(0, 20.5, 0), Color("B8C4C8"))
	RoomBuilder.box(root, Vector3(5, 1.6, 5), wt + Vector3(0, 23.8, 0), Color("A0ACB0"))
	var name := Label3D.new()
	name.text = "MAPLE GROVE"
	name.font_size = 220
	name.pixel_size = 0.01
	name.modulate = Color("2E5E9E")
	name.position = wt + Vector3(0, 20.5, -3.52)
	name.rotation_degrees.y = 180.0
	name.double_sided = false
	root.add_child(name)
