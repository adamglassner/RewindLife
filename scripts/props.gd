class_name Props
extends RefCounted
## Helpers for building furniture and other things you can use.
##
## An item is built in its own little space: its FRONT faces local +z, its width
## runs along local x, and y = 0 is the floor. Then it's placed and turned (yaw)
## as a whole, so the same code works facing any wall.


## A new SmartObject placed at `pos`, turned by `yaw` degrees (0 = front faces +z,
## -90 = front faces -x, 90 = faces +x, 180 = faces -z).
static func item(root: Node3D, objects: Dictionary, key: String, title: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := SmartObject.new()
	o.name = key
	o.display_name = title
	root.add_child(o)
	o.position = pos
	o.rotation_degrees.y = yaw
	if key != "":
		objects[key] = o
	return o


## A plain solid (not usable) piece of furniture, placed the same way.
static func solid(root: Node3D, pos: Vector3, yaw: float) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 2
	b.collision_mask = 0
	root.add_child(b)
	b.position = pos
	b.rotation_degrees.y = yaw
	return b


## A box in the item's own space. `glow` = lights up gold when hovered.
static func part(o: Node3D, size: Vector3, center: Vector3, color: Color, tex: Texture2D = null, glow := true) -> MeshInstance3D:
	var mi := RoomBuilder.box(o, size, center, color, tex, 2.0)
	if glow and o is SmartObject:
		(o as SmartObject).add_material(mi.material_override)
	return mi


## Something that glows (a screen, a lamp shade, an oven light).
static func glowing(o: Node3D, size: Vector3, center: Vector3, color: Color, energy := 0.3) -> StandardMaterial3D:
	var mi := RoomBuilder.box(o, size, center, color)
	var m: StandardMaterial3D = mi.material_override
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


## Finish an item: its solid footprint (`size` in local space, centered on the
## item), where Jamie walks to (`approach`), where she stands/sits while using it
## (`use`, defaults to approach) and what she looks at (`look`), all in local space.
static func finish(o: Node3D, solids: Array[Rect2], size: Vector3, approach: Vector3, use = null, look = null,
		shape_center := Vector3.INF) -> void:
	var c := Vector3(0, size.y / 2.0, 0) if shape_center == Vector3.INF else shape_center
	RoomBuilder.add_shape(o as CollisionObject3D, size, c)
	solids.append(footprint(o, size, c))
	if o is SmartObject:
		var so := o as SmartObject
		so.approach_point = _flat(o.to_global(approach))
		so.use_point = _flat(o.to_global(use if use != null else approach))
		so.look_point = o.to_global(look if look != null else Vector3(0, 1.0, 0))


## The rectangle on the floor (world x/z) that a local box covers.
static func footprint(o: Node3D, size: Vector3, center: Vector3) -> Rect2:
	var r := Rect2()
	var first := true
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			var p := o.to_global(center + Vector3(size.x * sx, 0, size.z * sz))
			if first:
				r = Rect2(p.x, p.z, 0, 0)
				first = false
			else:
				r = r.expand(Vector2(p.x, p.z))
	return r


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)


## A light that main.gd dims or brightens with the time of day.
static func light(root: Node3D, out: Dictionary, pos: Vector3, color: Color, rng: float, day: float, night: float,
		mat: StandardMaterial3D = null, shadows := true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.omni_range = rng
	l.shadow_enabled = shadows
	root.add_child(l)
	RoomBuilder.add_lamp(out, l, mat, day, night)
	return l


## A shopkeeper standing behind a counter (just for looks: they don't move).
## `hair_style`: "short", "bun", "cap", "ponytail", "mullet".
static func person(root: Node3D, pos: Vector3, yaw: float, top: Color, hair: Color, skin: Color, hair_style := "short") -> Node3D:
	var k := 0.0105
	var p := Node3D.new()
	p.position = pos
	p.rotation_degrees.y = yaw
	root.add_child(p)
	var parts := [
		[Vector3(14, 46, 18), Vector3(-9, 31, 0), Color("3B4E6E")], [Vector3(14, 46, 18), Vector3(9, 31, 0), Color("3B4E6E")],
		[Vector3(46, 50, 26), Vector3(0, 79, 0), top],
		[Vector3(12, 44, 18), Vector3(-29, 79, 0), top], [Vector3(12, 44, 18), Vector3(29, 79, 0), top],
		[Vector3(12, 10, 18), Vector3(-29, 52, 0), skin], [Vector3(12, 10, 18), Vector3(29, 52, 0), skin],
		[Vector3(12, 4, 12), Vector3(0, 106, 0), skin], [Vector3(30, 32, 24), Vector3(0, 124, 0), skin],
		[Vector3(5, 5, 1), Vector3(-7.5, 124.5, 12.5), Palette.INK], [Vector3(5, 5, 1), Vector3(7.5, 124.5, 12.5), Palette.INK],
		[Vector3(10, 2, 1), Vector3(0, 114, 12.5), Palette.RUST],
		[Vector3(34, 12, 28), Vector3(0, 140, 0), hair], [Vector3(34, 20, 6), Vector3(0, 130, -10), hair],
	]
	match hair_style:
		"bun":
			parts.append([Vector3(14, 14, 14), Vector3(0, 146, -10), hair])
		"cap":
			parts.append([Vector3(36, 8, 30), Vector3(0, 146, 0), Color("C0322A")])
			parts.append([Vector3(30, 3, 14), Vector3(0, 142, 18), Color("C0322A")])
		"ponytail":
			parts.append([Vector3(9, 30, 9), Vector3(0, 120, -17), hair])
		"mullet":
			parts.append([Vector3(34, 40, 10), Vector3(0, 118, -9), hair])
	for d in parts:
		RoomBuilder.box(p, d[0] * k, d[1] * k, d[2])
	return p


## A word bubble over someone's head for a few seconds ("Ouch!").
static func bubble(who: Node3D, text: String, seconds := 2.5, height := 2.35) -> void:
	var b: Label3D = who.get_node_or_null("Bubble")
	if b == null:
		b = Label3D.new()
		b.name = "Bubble"
		b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		b.font_size = 46
		b.outline_size = 14
		b.modulate = Palette.PAPER
		b.outline_modulate = Palette.CORAL.darkened(0.3)
		b.no_depth_test = true
		b.position = Vector3(0, height, 0)
		who.add_child(b)
	b.text = text
	b.visible = true
	b.set_meta("until", Time.get_ticks_msec() + int(seconds * 1000.0))
	who.get_tree().create_timer(seconds).timeout.connect(func():
		if is_instance_valid(b) and Time.get_ticks_msec() >= int(b.get_meta("until", 0)):
			b.visible = false)


## A delivered pizza, sitting on a table (hidden until one is delivered). You sit
## at the table to eat it. `offset` is where on the table, in the table's space.
static func pizza_box(root: Node3D, objects: Dictionary, key: String, table: SmartObject, offset: Vector3, home: String) -> SmartObject:
	var o := SmartObject.new()
	o.name = key
	o.display_name = "Pizza Peak Delivery"
	o.kind = "pizza_box"
	o.home = home
	root.add_child(o)
	o.global_transform = table.global_transform
	o.position = table.to_global(offset)
	o.add_material(RoomBuilder.box(o, Vector3(0.42, 0.05, 0.42), Vector3(0, 0.025, 0), Palette.PAPER).material_override)
	RoomBuilder.box(o, Vector3(0.43, 0.012, 0.08), Vector3(0, 0.03, -0.1), Color("C0322A"))
	RoomBuilder.box(o, Vector3(0.2, 0.004, 0.12), Vector3(0, 0.0525, 0.08), Color("C0322A"))
	RoomBuilder.add_shape(o, Vector3(0.45, 0.12, 0.45), Vector3(0, 0.05, 0))
	o.approach_point = table.approach_point
	o.use_point = table.use_point
	o.look_point = o.global_position + Vector3(0, 0.05, 0)
	o.visible = false
	o.collision_layer = 0
	objects[key] = o
	return o
