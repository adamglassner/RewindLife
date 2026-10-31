class_name Furnish
extends RefCounted
## A kit of furniture shared by every house (Jamie's new rooms, the neighbors'
## houses, and all the attics and basements). Each piece is built in its own
## space (front facing +z, see props.gd), placed at `pos` (in the context's root
## space) and turned by `yaw`. Usable pieces get a `kind`; content.gd gives every
## kind its activities, so a new house needs no new content code.
##
## The context `c` is a Dictionary:
##   root (Node3D), objects (Dictionary), solids (Array[Rect2]), out (Dictionary),
##   tex (Dictionary), home (String: whose house), level (int)


static func item(c: Dictionary, key: String, title: String, kind: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := Props.item(c["root"], c["objects"], key, title, pos, yaw)
	o.kind = kind
	o.home = c["home"]
	o.level = c.get("level", 0)
	return o


static func solid(c: Dictionary, pos: Vector3, yaw: float) -> StaticBody3D:
	return Props.solid(c["root"], pos, yaw)


static func _tex(c: Dictionary, k: String) -> Texture2D:
	return c["tex"].get(k)


# ================================================================ living room

static func tv(c: Dictionary, key: String, pos: Vector3, yaw: float, wood := Palette.WOOD_DARK) -> SmartObject:
	var o := item(c, key, "TV", "tv", pos, yaw)
	Props.part(o, Vector3(1.0, 0.55, 0.5), Vector3(0, 0.275, 0), wood, _tex(c, "panel"))
	Props.part(o, Vector3(0.72, 0.56, 0.46), Vector3(0, 0.83, 0), Color("4A3B30"))
	var screen := Props.glowing(o, Vector3(0.52, 0.4, 0.012), Vector3(-0.05, 0.84, 0.236), Color("3B3F3A"), 0.0)
	Props.part(o, Vector3(0.1, 0.3, 0.012), Vector3(0.27, 0.84, 0.236), Palette.INK2, null, false)
	Props.part(o, Vector3(0.02, 0.35, 0.02), Vector3(0.1, 1.27, -0.05), Palette.MUTED, null, false)
	Props.part(o, Vector3(0.34, 0.08, 0.3), Vector3(-0.25, 0.595, 0.05), Palette.INK, null, false)   # VCR
	var l := OmniLight3D.new()
	l.position = Vector3(0, 0.9, 0.9)
	l.light_energy = 0.0
	l.omni_range = 3.5
	l.light_color = Palette.CRT
	o.add_child(l)
	o.set_meta("screen_mat", screen)
	o.set_meta("tv_light", l)
	# watched from 1.9 m away (where the couch goes)
	Props.finish(o, c["solids"], Vector3(1.0, 1.1, 0.5), Vector3(0, 0, 1.15), Vector3(0, 0, 1.95), Vector3(0, 0.84, 0))
	return o


static func couch(c: Dictionary, key: String, pos: Vector3, yaw: float, color: Color, length := 1.9) -> SmartObject:
	var o := item(c, key, "Couch", "couch", pos, yaw)
	Props.part(o, Vector3(length, 0.42, 0.85), Vector3(0, 0.21, 0), color, _tex(c, "plaid"))
	Props.part(o, Vector3(length - 0.04, 0.5, 0.22), Vector3(0, 0.62, -0.305), color.darkened(0.1), _tex(c, "plaid"))
	for ax in [-1.0, 1.0]:
		Props.part(o, Vector3(0.2, 0.62, 0.87), Vector3(ax * (length / 2.0 - 0.08), 0.31, 0), color.darkened(0.15))
	Props.finish(o, c["solids"], Vector3(length, 0.9, 0.85), Vector3(0, 0, 0.95), Vector3(0, 0, 0.08), Vector3(0, 0.9, 3.0))
	o.set_meta("nap_face", o.to_global(Vector3(-length - 0.6, 0.5, 0.08)))
	return o


static func armchair(c: Dictionary, pos: Vector3, yaw: float, color: Color) -> void:
	var b := solid(c, pos, yaw)
	RoomBuilder.box(b, Vector3(0.8, 0.42, 0.8), Vector3(0, 0.21, 0), color)
	RoomBuilder.box(b, Vector3(0.76, 0.5, 0.2), Vector3(0, 0.62, -0.305), color.darkened(0.12))
	for ax in [-0.338, 0.338]:      # (the arms stick out past the seat a little, so no faces line up)
		RoomBuilder.box(b, Vector3(0.14, 0.6, 0.82), Vector3(ax, 0.3, 0), color.darkened(0.2))
	Props.finish(b, c["solids"], Vector3(0.8, 0.9, 0.8), Vector3.ZERO)


static func coffee_table(c: Dictionary, pos: Vector3, yaw: float) -> void:
	var b := solid(c, pos, yaw)
	RoomBuilder.box(b, Vector3(1.0, 0.05, 0.5), Vector3(0, 0.4, 0), Palette.WOOD)
	RoomBuilder.box(b, Vector3(0.9, 0.38, 0.4), Vector3(0, 0.19, 0), Palette.WOOD_DARK)
	RoomBuilder.box(b, Vector3(0.25, 0.03, 0.18), Vector3(0.2, 0.44, 0.04), Palette.CORAL)    # a magazine
	Props.finish(b, c["solids"], Vector3(1.0, 0.45, 0.5), Vector3.ZERO)


static func bookshelf(c: Dictionary, key: String, pos: Vector3, yaw: float, seed := 1) -> SmartObject:
	var o := item(c, key, "Bookshelf", "bookshelf", pos, yaw)
	Props.part(o, Vector3(1.0, 1.8, 0.4), Vector3(0, 0.9, 0), Palette.WOOD)
	var cols := [Palette.CORAL, Palette.TEAL, Palette.GOLD, Palette.NAVY, Palette.ROSE, Palette.RUST]
	for row in 4:
		for b in 6:
			Props.part(o, Vector3(0.12, 0.3 - ((b + seed) % 3) * 0.03, 0.02), Vector3(-0.38 + b * 0.15, 0.2 + row * 0.42, 0.205),
				cols[(b + row + seed) % 6], null, false)
	Props.finish(o, c["solids"], Vector3(1.0, 1.8, 0.4), Vector3(0, 0, 0.9), null, Vector3(0, 1.0, 0))
	return o


static func stereo(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Stereo", "stereo", pos, yaw)
	Props.part(o, Vector3(1.1, 0.6, 0.45), Vector3(0, 0.3, 0), Palette.WOOD_DARK, _tex(c, "panel"))
	Props.part(o, Vector3(0.36, 0.08, 0.3), Vector3(-0.2, 0.64, 0), Palette.INK2)
	Props.part(o, Vector3(0.3, 0.1, 0.25), Vector3(0.28, 0.65, 0), Palette.INK)
	for gx in [-0.36, 0.36]:
		Props.part(o, Vector3(0.3, 0.4, 0.012), Vector3(gx, 0.28, 0.23), Color("3A2A22"), null, false)
	Props.finish(o, c["solids"], Vector3(1.1, 0.75, 0.45), Vector3(0, 0, 0.95), null, Vector3(0, 0.7, 0))
	return o


static func plant(c: Dictionary, pos: Vector3, pot := Color("C2572F")) -> void:
	var b := solid(c, pos, 0)
	RoomBuilder.box(b, Vector3(0.4, 0.4, 0.4), Vector3(0, 0.2, 0), pot)
	RoomBuilder.box(b, Vector3(0.6, 0.5, 0.6), Vector3(0, 0.65, 0), Palette.AVOCADO)
	RoomBuilder.box(b, Vector3(0.36, 0.3, 0.36), Vector3(0.04, 1.02, -0.03), Color("8FA246"))
	Props.finish(b, c["solids"], Vector3(0.5, 0.9, 0.5), Vector3.ZERO)


static func rug(c: Dictionary, pos: Vector3, size: Vector2, color: Color, pattern := "") -> void:
	var r := RoomBuilder.box(c["root"], Vector3(size.x, 0.012, size.y), pos + Vector3(0, 0.006, 0),
		Color.WHITE if pattern != "" else color, _tex(c, pattern) if pattern != "" else null, 3.0)
	if pattern != "":
		(r.material_override as StandardMaterial3D).albedo_color = color
	r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static var _lamps := 0


## A floor lamp you can switch on and off (it switches the room's lights).
static func floor_lamp(c: Dictionary, pos: Vector3, day := 0.2, night := 1.2) -> void:
	_lamps += 1
	var b := item(c, "%s_floor_lamp_%d" % [c["home"], _lamps], "Floor Lamp", "lamp", pos, 0)
	Props.part(b, Vector3(0.3, 0.04, 0.3), Vector3(0, 0.02, 0), Palette.INK2, null, false)
	Props.part(b, Vector3(0.04, 1.4, 0.04), Vector3(0, 0.72, 0), Palette.GOLD)
	var shade := Props.glowing(b, Vector3(0.38, 0.3, 0.38), Vector3(0, 1.55, 0), Color("F2D58A"), 0.2)
	Props.finish(b, c["solids"], Vector3(0.35, 1.7, 0.35), Vector3(0, 0, 0.6), null, Vector3(0, 1.5, 0))
	Props.light(c["root"], c["out"], pos + Vector3(0, 1.5, 0), Palette.LAMP, 4.5, day, night, shade, false)


# ================================================================ kitchen & dining

static func fridge(c: Dictionary, key: String, pos: Vector3, yaw: float, color := Palette.AVOCADO) -> SmartObject:
	var o := item(c, key, "Fridge", "fridge", pos, yaw)
	Props.part(o, Vector3(0.75, 1.75, 0.7), Vector3(0, 0.875, 0), color)
	Props.part(o, Vector3(0.03, 0.4, 0.04), Vector3(0.28, 1.3, 0.37), Palette.PAPER, null, false)
	Props.part(o, Vector3(0.03, 0.3, 0.04), Vector3(0.28, 0.6, 0.37), Palette.PAPER, null, false)
	Props.part(o, Vector3(0.7, 0.012, 0.03), Vector3(0, 1.02, 0.365), Palette.INK2, null, false)
	Props.part(o, Vector3(0.12, 0.16, 0.01), Vector3(-0.15, 1.4, 0.355), Palette.PAPER, null, false)   # a drawing on the door
	Props.finish(o, c["solids"], Vector3(0.75, 1.75, 0.7), Vector3(0, 0, 1.1), null, Vector3(0, 1.1, 0))
	return o


static func sink(c: Dictionary, key: String, pos: Vector3, yaw: float, cab := Palette.CREAM, top := Palette.GOLD, w := 1.3) -> SmartObject:
	var o := item(c, key, "Kitchen Sink", "sink", pos, yaw)
	Props.part(o, Vector3(w, 0.86, 0.6), Vector3(0, 0.43, 0), cab.darkened(0.08), _tex(c, "panel"))
	Props.part(o, Vector3(w + 0.04, 0.04, 0.64), Vector3(0, 0.88, 0), top)
	Props.part(o, Vector3(0.5, 0.012, 0.36), Vector3(0, 0.906, 0.02), Color("9AA3A8"), null, false)
	Props.part(o, Vector3(0.04, 0.26, 0.04), Vector3(0, 1.03, -0.22), Palette.MUTED, null, false)
	Props.finish(o, c["solids"], Vector3(w, 0.9, 0.62), Vector3(0, 0, 1.0), null, Vector3(0, 0.95, 0))
	return o


static func stove(c: Dictionary, key: String, pos: Vector3, yaw: float, color := Palette.CREAM) -> SmartObject:
	var o := item(c, key, "Stove", "stove", pos, yaw)
	Props.part(o, Vector3(0.76, 0.89, 0.62), Vector3(0, 0.445, 0), color)
	Props.part(o, Vector3(0.74, 0.012, 0.6), Vector3(0, 0.896, 0), Palette.INK, null, false)
	c["out"][key + "_mat"] = Props.glowing(o, Vector3(0.14, 0.006, 0.14), Vector3(0.17, 0.905, 0.12), Palette.CORAL, 0.0)
	Props.part(o, Vector3(0.5, 0.25, 0.012), Vector3(0, 0.45, 0.316), Palette.INK, null, false)
	Props.part(o, Vector3(0.2, 0.12, 0.2), Vector3(-0.17, 0.96, -0.1), Palette.MUTED, null, false)   # a pot
	Props.finish(o, c["solids"], Vector3(0.76, 0.92, 0.62), Vector3(0, 0, 0.95), null, Vector3(0, 0.95, 0))
	return o


## A plain run of counter (with cabinets above it on a wall when `upper`).
static func counter(c: Dictionary, pos: Vector3, yaw: float, w: float, cab := Palette.CREAM, top := Palette.GOLD) -> void:
	var b := solid(c, pos, yaw)
	RoomBuilder.box(b, Vector3(w, 0.86, 0.6), Vector3(0, 0.43, 0), cab.darkened(0.08), _tex(c, "panel"), 2.0)
	RoomBuilder.box(b, Vector3(w + 0.04, 0.04, 0.64), Vector3(0, 0.88, 0), top)
	RoomBuilder.box(b, Vector3(0.26, 0.2, 0.2), Vector3(-w / 2.0 + 0.25, 1.0, -0.1), Palette.PAPER)   # a toaster
	Props.finish(b, c["solids"], Vector3(w, 0.9, 0.62), Vector3.ZERO)


## A table you sit at (one seat, on its front side), with chairs around it.
static func table(c: Dictionary, key: String, title: String, pos: Vector3, yaw: float, top: Color, size := Vector2(1.1, 0.8),
		cloth := false, chairs := 4) -> SmartObject:
	var o := item(c, key, title, "table", pos, yaw)
	Props.part(o, Vector3(size.x, 0.05, size.y), Vector3(0, 0.74, 0), Color.WHITE if cloth else top, _tex(c, "plaid") if cloth else null)
	if cloth:
		(o.get_child(o.get_child_count() - 1) as MeshInstance3D).material_override.albedo_color = top
	for lx in [-1.0, 1.0]:
		for lz in [-1.0, 1.0]:
			Props.part(o, Vector3(0.06, 0.72, 0.06), Vector3(lx * (size.x / 2.0 - 0.08), 0.36, lz * (size.y / 2.0 - 0.08)),
				Palette.WOOD_DARK, null, false)
	var seats := [Vector3(0, 0, size.y / 2.0 + 0.32), Vector3(0, 0, -size.y / 2.0 - 0.32),
		Vector3(size.x / 2.0 + 0.32, 0, 0), Vector3(-size.x / 2.0 - 0.32, 0, 0)]
	for i in mini(chairs, 4):
		var s: Vector3 = seats[i]
		var back := -s.normalized() * -0.2
		Props.part(o, Vector3(0.4, 0.45, 0.4), s + Vector3(0, 0.225, 0), Palette.WOOD, null, false)
		Props.part(o, Vector3(0.4 if absf(s.z) > 0.01 else 0.06, 0.45, 0.06 if absf(s.z) > 0.01 else 0.4),
			s + back + Vector3(0, 0.67, 0), Palette.WOOD, null, false)
	Props.part(o, Vector3(0.2, 0.012, 0.2), Vector3(0, 0.771, size.y / 2.0 - 0.18), Palette.PAPER, null, false)   # a plate
	Props.finish(o, c["solids"], Vector3(size.x, 0.78, size.y), Vector3(0, 0, size.y / 2.0 + 0.95),
		Vector3(0, 0, size.y / 2.0 + 0.32), Vector3(0, 0.8, 0))
	o.shared = true
	return o


static func wall_phone(c: Dictionary, key: String, pos: Vector3, yaw: float, color := Palette.CORAL) -> SmartObject:
	var o := item(c, key, "Wall Phone", "phone", pos, yaw)
	Props.part(o, Vector3(0.2, 0.32, 0.08), Vector3(0, 1.45, 0.04), color)
	Props.part(o, Vector3(0.06, 0.26, 0.05), Vector3(-0.065, 1.47, 0.1), color.darkened(0.15))
	Props.finish(o, c["solids"], Vector3(0.24, 0.4, 0.1), Vector3(0, 0, 0.75), null, Vector3(0, 1.45, 0), Vector3(0, 1.45, 0.05))
	return o


# ================================================================ bedrooms

static func bed(c: Dictionary, key: String, title: String, kind: String, pos: Vector3, yaw: float, blanket: Color,
		double := false, side := 1.0, foot := false) -> SmartObject:
	var w := 1.5 if double else 1.05
	var o := item(c, key, title, kind, pos, yaw)
	Props.part(o, Vector3(w, 0.3, 2.05), Vector3(0, 0.2, 0), Palette.WOOD_DARK)
	Props.part(o, Vector3(w - 0.07, 0.2, 1.95), Vector3(0, 0.45, 0), Palette.PAPER, null, false)
	Props.part(o, Vector3(w - 0.02, 0.06, 1.4), Vector3(0, 0.575, 0.3), blanket)
	for px in ([-0.35, 0.35] if double else [0.0]):
		Props.part(o, Vector3(0.6 if double else 0.7, 0.12, 0.35), Vector3(px, 0.6, -0.75), Palette.PAPER, null, false)
	Props.part(o, Vector3(w + 0.1, 1.0, 0.08), Vector3(0, 0.5, -1.04), Palette.WOOD)
	# (walk up to the side, or to the foot of the bed when the sides are against things)
	var approach := Vector3(0.25 * side, 0, 1.6) if foot else Vector3(side * (w / 2.0 + 0.45), 0, 0.2)
	Props.finish(o, c["solids"], Vector3(w, 0.65, 2.05), approach, Vector3.ZERO, Vector3(0, 0.5, 4.0))
	return o


static func nightstand(c: Dictionary, pos: Vector3, yaw: float, lamp := true) -> void:
	var b := solid(c, pos, yaw)
	RoomBuilder.box(b, Vector3(0.45, 0.5, 0.4), Vector3(0, 0.25, 0), Palette.WOOD)
	if lamp:
		RoomBuilder.box(b, Vector3(0.06, 0.25, 0.06), Vector3(0, 0.625, 0), Palette.GOLD)
		var shade := RoomBuilder.box(b, Vector3(0.24, 0.18, 0.24), Vector3(0, 0.83, 0), Color("F2D58A"))
		var m: StandardMaterial3D = shade.material_override
		m.emission_enabled = true
		m.emission = Color("F2D58A")
		m.emission_energy_multiplier = 0.3
	Props.finish(b, c["solids"], Vector3(0.45, 0.6, 0.4), Vector3.ZERO)


static func desk(c: Dictionary, key: String, pos: Vector3, yaw: float, chair := Palette.TEAL) -> SmartObject:
	var o := item(c, key, "Desk", "desk", pos, yaw)
	Props.part(o, Vector3(1.1, 0.05, 0.6), Vector3(0, 0.73, 0), Palette.WOOD)
	for lx in [-0.5, 0.5]:
		Props.part(o, Vector3(0.06, 0.7, 0.56), Vector3(lx, 0.35, 0), Palette.WOOD_DARK)
	Props.part(o, Vector3(0.18, 0.04, 0.24), Vector3(0.15, 0.775, 0.05), Color("7B2D3A"))   # diary
	Props.part(o, Vector3(0.08, 0.08, 0.08), Vector3(-0.3, 0.795, -0.1), Palette.CORAL, null, false)
	Props.part(o, Vector3(0.45, 0.45, 0.42), Vector3(0, 0.225, 0.62), chair, null, false)
	Props.part(o, Vector3(0.45, 0.45, 0.06), Vector3(0, 0.67, 0.83), chair, null, false)
	Props.finish(o, c["solids"], Vector3(1.1, 0.8, 0.6), Vector3(0, 0, 1.3), Vector3(0, 0, 0.6), Vector3(0, 0.8, 0))
	return o


static func dresser(c: Dictionary, key: String, pos: Vector3, yaw: float, color := Palette.WOOD) -> SmartObject:
	var o := item(c, key, "Dresser", "dresser", pos, yaw)
	Props.part(o, Vector3(0.9, 1.0, 0.5), Vector3(0, 0.5, 0), color)
	for i in 3:
		Props.part(o, Vector3(0.8, 0.26, 0.012), Vector3(0, 0.2 + i * 0.3, 0.256), color.darkened(0.2), null, false)
	Props.part(o, Vector3(0.6, 0.7, 0.04), Vector3(0, 1.4, -0.2), Color("9FC4CC"))
	Props.finish(o, c["solids"], Vector3(0.9, 1.0, 0.5), Vector3(0, 0, 0.95), null, Vector3(0, 1.2, 0))
	return o


static func closet(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Closet", "closet", pos, yaw)
	Props.part(o, Vector3(1.4, 2.1, 0.6), Vector3(0, 1.05, 0), Palette.CREAM)
	for dx in [-0.35, 0.35]:
		Props.part(o, Vector3(0.66, 2.0, 0.02), Vector3(dx, 1.03, 0.31), Palette.WOOD, null, false)
		for sl in 8:
			Props.part(o, Vector3(0.6, 0.02, 0.03), Vector3(dx, 0.3 + sl * 0.2, 0.33), Palette.WOOD_DARK, null, false)
	Props.finish(o, c["solids"], Vector3(1.4, 2.1, 0.6), Vector3(0, 0, 0.9), null, Vector3(0, 1.2, 0))
	return o


static func vanity(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Vanity", "vanity", pos, yaw)
	Props.part(o, Vector3(1.0, 0.75, 0.45), Vector3(0, 0.375, 0), Palette.PAPER)
	Props.part(o, Vector3(0.7, 0.8, 0.04), Vector3(0, 1.25, -0.2), Color("9FC4CC"))
	Props.part(o, Vector3(0.78, 0.88, 0.03), Vector3(0, 1.25, -0.225), Palette.GOLD, null, false)
	for i in 3:
		Props.part(o, Vector3(0.05, 0.12, 0.05), Vector3(-0.3 + i * 0.12, 0.81, 0.05), [Palette.ROSE, Palette.CRT, Palette.GOLD][i], null, false)
	Props.part(o, Vector3(0.4, 0.42, 0.36), Vector3(0, 0.21, 0.55), Palette.ROSE, null, false)   # stool
	Props.finish(o, c["solids"], Vector3(1.0, 0.8, 0.45), Vector3(0, 0, 1.0), Vector3(0, 0, 0.55), Vector3(0, 1.2, 0))
	return o


static func poster(c: Dictionary, wall_pos: Vector3, yaw: float, color: Color, accent: Color) -> void:
	var g := Node3D.new()
	g.position = wall_pos
	g.rotation_degrees.y = yaw
	(c["root"] as Node3D).add_child(g)
	RoomBuilder.box(g, Vector3(0.55, 0.75, 0.01), Vector3(0, 0, 0.006), color)
	RoomBuilder.box(g, Vector3(0.4, 0.25, 0.012), Vector3(0, 0.12, 0.0105), accent)
	RoomBuilder.box(g, Vector3(0.36, 0.06, 0.012), Vector3(0, -0.22, 0.0105), Palette.PAPER)


# ================================================================ bathroom & laundry

static func tub(c: Dictionary, key: String, pos: Vector3, yaw: float, color := Palette.PAPER) -> SmartObject:
	var o := item(c, key, "Bathtub", "tub", pos, yaw)
	Props.part(o, Vector3(1.55, 0.55, 0.72), Vector3(0, 0.275, 0), color)
	Props.part(o, Vector3(1.4, 0.02, 0.58), Vector3(0, 0.555, 0), Color("BFE0EE"), null, false)    # water
	Props.part(o, Vector3(0.05, 0.3, 0.05), Vector3(-0.7, 1.7, -0.3), Palette.MUTED, null, false)   # shower head
	Props.part(o, Vector3(1.6, 0.03, 0.03), Vector3(0, 1.95, 0.35), Palette.MUTED, null, false)     # curtain rod
	Props.part(o, Vector3(1.0, 1.3, 0.02), Vector3(0.3, 1.28, 0.35), Color("F2A0B5"), null, false)  # curtain
	Props.finish(o, c["solids"], Vector3(1.55, 0.55, 0.72), Vector3(0, 0, 0.85), Vector3(0, 0, 0.0), Vector3(-0.8, 0.8, 0))
	return o


static func toilet(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Toilet", "toilet", pos, yaw)
	Props.part(o, Vector3(0.4, 0.42, 0.5), Vector3(0, 0.21, 0.05), Palette.PAPER)
	Props.part(o, Vector3(0.42, 0.06, 0.52), Vector3(0, 0.45, 0.05), Palette.PAPER.darkened(0.06))
	Props.part(o, Vector3(0.44, 0.4, 0.18), Vector3(0, 0.62, -0.22), Palette.PAPER)
	Props.part(o, Vector3(0.36, 0.06, 0.4), Vector3(0, 0.08, 0.05), Color("BFE0EE"), null, false)   # fuzzy rug
	Props.finish(o, c["solids"], Vector3(0.45, 0.85, 0.62), Vector3(0, 0, 0.75), Vector3(0, 0, 0.2), Vector3(0, 0.5, 2.0))
	return o


static func bath_sink(c: Dictionary, key: String, pos: Vector3, yaw: float, cab := Palette.CREAM) -> SmartObject:
	var o := item(c, key, "Bathroom Mirror", "bath_sink", pos, yaw)
	Props.part(o, Vector3(0.8, 0.8, 0.45), Vector3(0, 0.4, 0), cab)
	Props.part(o, Vector3(0.82, 0.04, 0.48), Vector3(0, 0.82, 0), Palette.PAPER)
	Props.part(o, Vector3(0.36, 0.012, 0.26), Vector3(0, 0.846, 0.02), Color("9AA3A8"), null, false)
	Props.part(o, Vector3(0.6, 0.7, 0.03), Vector3(0, 1.45, -0.21), Color("9FC4CC"))
	Props.part(o, Vector3(0.66, 0.06, 0.04), Vector3(0, 1.83, -0.2), Palette.GOLD, null, false)
	Props.finish(o, c["solids"], Vector3(0.8, 0.85, 0.48), Vector3(0, 0, 0.85), null, Vector3(0, 1.45, 0))
	return o


static func washer(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Washer & Dryer", "washer", pos, yaw)
	for x in [-0.35, 0.35]:
		Props.part(o, Vector3(0.66, 0.9, 0.62), Vector3(x, 0.45, 0), Palette.PAPER)
		Props.part(o, Vector3(0.6, 0.14, 0.04), Vector3(x, 0.86, -0.27), Palette.MUTED, null, false)   # control panel
	Props.part(o, Vector3(0.36, 0.36, 0.012), Vector3(0.35, 0.45, 0.316), Color("6E777C"), null, false)  # dryer door
	Props.part(o, Vector3(0.4, 0.3, 0.3), Vector3(-0.3, 1.05, 0.05), Color("C8A878"), null, false)      # laundry basket
	Props.finish(o, c["solids"], Vector3(1.36, 0.95, 0.62), Vector3(0, 0, 0.95), null, Vector3(0, 0.9, 0))
	return o


# ================================================================ attics & basements

static func trunk(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Old Trunk", "trunk", pos, yaw)
	Props.part(o, Vector3(1.0, 0.5, 0.55), Vector3(0, 0.25, 0), Color("6B4429"))
	Props.part(o, Vector3(1.02, 0.12, 0.57), Vector3(0, 0.56, 0), Color("5A3A22"))
	for x in [-0.35, 0.35]:
		Props.part(o, Vector3(0.06, 0.64, 0.58), Vector3(x, 0.32, 0), Palette.GOLD, null, false)
	Props.finish(o, c["solids"], Vector3(1.0, 0.65, 0.55), Vector3(0, 0, 0.9), null, Vector3(0, 0.5, 0))
	return o


static func boxes(c: Dictionary, pos: Vector3, yaw: float, seed := 1) -> void:
	var b := solid(c, pos, yaw)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var y := 0.0
	for i in 3:
		var s := Vector3(rng.randf_range(0.45, 0.7), rng.randf_range(0.3, 0.45), rng.randf_range(0.4, 0.6))
		var m := RoomBuilder.box(b, s, Vector3(rng.randf_range(-0.06, 0.06), y + s.y / 2.0, 0), Color("C8A878").darkened(rng.randf() * 0.15))
		m.rotation.y = rng.randf_range(-0.15, 0.15)
		y += s.y
	RoomBuilder.box(b, Vector3(0.3, 0.012, 0.05), Vector3(0, y / 3.0, 0.31), Palette.INK)   # "XMAS" scrawled on it
	Props.finish(b, c["solids"], Vector3(0.75, y, 0.65), Vector3.ZERO)


static func xmas_boxes(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Holiday Decorations", "xmas", pos, yaw)
	Props.part(o, Vector3(0.7, 0.4, 0.5), Vector3(-0.3, 0.2, 0), Color("C8A878"))
	Props.part(o, Vector3(0.6, 0.35, 0.45), Vector3(0.35, 0.175, 0.02), Color("B89868"))
	Props.part(o, Vector3(0.3, 0.12, 0.3), Vector3(-0.3, 0.46, 0), Color("4F7A3A"), null, false)   # tinsel
	Props.part(o, Vector3(0.12, 0.12, 0.12), Vector3(0.3, 0.41, 0), Color("C0322A"), null, false)  # an ornament
	Props.finish(o, c["solids"], Vector3(1.3, 0.5, 0.55), Vector3(0, 0, 0.9), null, Vector3(0, 0.4, 0))
	return o


static func rocking_horse(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Old Rocking Horse", "rocking_horse", pos, yaw)
	Props.part(o, Vector3(0.9, 0.06, 0.1), Vector3(0, 0.03, -0.15), Palette.WOOD_DARK, null, false)
	Props.part(o, Vector3(0.9, 0.06, 0.1), Vector3(0, 0.03, 0.15), Palette.WOOD_DARK, null, false)
	Props.part(o, Vector3(0.7, 0.3, 0.25), Vector3(0, 0.5, 0), Color("C2572F"))
	Props.part(o, Vector3(0.18, 0.35, 0.18), Vector3(0.38, 0.75, 0), Color("C2572F"))
	Props.part(o, Vector3(0.06, 0.3, 0.27), Vector3(0.3, 0.75, 0), Palette.CREAM, null, false)    # mane
	Props.finish(o, c["solids"], Vector3(0.95, 0.9, 0.4), Vector3(0, 0, 0.8), null, Vector3(0, 0.6, 0))
	return o


static func telescope(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Telescope", "telescope", pos, yaw)
	for a in [0.0, 2.1, 4.2]:
		Props.part(o, Vector3(0.03, 1.0, 0.03), Vector3(cos(a) * 0.18, 0.5, sin(a) * 0.18), Palette.INK2, null, false)
	var tube := Props.part(o, Vector3(0.12, 0.12, 0.8), Vector3(0, 1.1, -0.1), Palette.PAPER)
	tube.rotation.x = 0.5
	Props.finish(o, c["solids"], Vector3(0.45, 1.3, 0.45), Vector3(0, 0, 0.75), null, Vector3(0, 1.3, -2.0))
	return o


static func pool_table(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Pool Table", "pool_table", pos, yaw)
	Props.part(o, Vector3(2.2, 0.75, 1.2), Vector3(0, 0.375, 0), Palette.WOOD_DARK)
	Props.part(o, Vector3(2.0, 0.02, 1.0), Vector3(0, 0.76, 0), Color("2E7A4A"))
	for i in 5:
		Props.part(o, Vector3(0.06, 0.06, 0.06), Vector3(-0.4 + i * 0.12, 0.8, (i % 2) * 0.1), [Palette.GOLD, Palette.CORAL, Palette.NAVY, Palette.PAPER, Palette.INK][i], null, false)
	Props.finish(o, c["solids"], Vector3(2.2, 0.8, 1.2), Vector3(0, 0, 1.25), null, Vector3(0, 0.8, 0))
	o.shared = true
	return o


static func ping_pong(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Ping-Pong Table", "ping_pong", pos, yaw)
	Props.part(o, Vector3(2.4, 0.04, 1.3), Vector3(0, 0.74, 0), Color("2E5E9E"))
	Props.part(o, Vector3(0.02, 0.14, 1.36), Vector3(0, 0.83, 0), Palette.PAPER, null, false)
	for x in [-1.0, 1.0]:
		Props.part(o, Vector3(0.08, 0.72, 1.0), Vector3(x, 0.36, 0), Palette.INK2, null, false)
	Props.finish(o, c["solids"], Vector3(2.4, 0.8, 1.3), Vector3(1.6, 0, 0), null, Vector3(0, 0.8, 0))
	o.shared = true
	return o


static func workbench(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Workbench", "workbench", pos, yaw)
	Props.part(o, Vector3(1.6, 0.06, 0.65), Vector3(0, 0.9, 0), Palette.WOOD)
	for x in [-0.72, 0.72]:
		Props.part(o, Vector3(0.08, 0.88, 0.6), Vector3(x, 0.44, 0), Palette.WOOD_DARK)
	Props.part(o, Vector3(1.6, 1.0, 0.04), Vector3(0, 1.5, -0.3), Color("C8A878"), null, false)   # pegboard
	for i in 5:
		Props.part(o, Vector3(0.05, 0.3, 0.04), Vector3(-0.6 + i * 0.3, 1.5, -0.26), [Palette.CORAL, Palette.MUTED, Palette.GOLD, Palette.INK2, Palette.TEAL][i], null, false)
	Props.part(o, Vector3(0.4, 0.2, 0.25), Vector3(0.4, 1.03, 0), Color("C0322A"), null, false)   # toolbox
	Props.finish(o, c["solids"], Vector3(1.6, 1.0, 0.65), Vector3(0, 0, 0.95), null, Vector3(0, 1.0, 0))
	return o


static func game_console(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Old TV & Game System", "console", pos, yaw)
	Props.part(o, Vector3(0.9, 0.5, 0.45), Vector3(0, 0.25, 0), Palette.WOOD_DARK)
	Props.part(o, Vector3(0.6, 0.48, 0.42), Vector3(0, 0.74, 0), Color("6B5A4A"))
	c["out"][key + "_mat"] = Props.glowing(o, Vector3(0.44, 0.34, 0.012), Vector3(0, 0.75, 0.216), Color("3B3F3A"), 0.3)
	Props.part(o, Vector3(0.36, 0.06, 0.2), Vector3(0, 0.53, 0.12), Palette.INK, null, false)
	Props.part(o, Vector3(0.1, 0.05, 0.07), Vector3(0.36, 0.525, 0.16), Palette.INK, null, false)   # joystick (on the table, beside the TV)
	Props.finish(o, c["solids"], Vector3(0.9, 1.0, 0.45), Vector3(0, 0, 1.2), Vector3(0, 0, 1.3), Vector3(0, 0.75, 0))
	return o


static func weights(c: Dictionary, key: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := item(c, key, "Weight Bench", "weights", pos, yaw)
	Props.part(o, Vector3(0.35, 0.45, 1.2), Vector3(0, 0.225, 0), Color("2B2B30"))
	Props.part(o, Vector3(1.4, 0.04, 0.04), Vector3(0, 0.95, -0.4), Palette.MUTED, null, false)
	for x in [-0.6, 0.6]:
		Props.part(o, Vector3(0.06, 0.3, 0.3), Vector3(x, 0.95, -0.4), Palette.INK, null, false)
		Props.part(o, Vector3(0.05, 0.95, 0.05), Vector3(x * 0.5, 0.47, -0.4), Palette.INK2, null, false)
	Props.finish(o, c["solids"], Vector3(1.4, 1.0, 1.2), Vector3(1.05, 0, 0.3), null, Vector3(0, 0.6, 0))
	return o


static func arcade_cabinet(c: Dictionary, key: String, title: String, pos: Vector3, yaw: float, col: Color) -> SmartObject:
	var o := item(c, key, title, "home_arcade", pos, yaw)
	Props.part(o, Vector3(0.7, 1.8, 0.75), Vector3(0, 0.9, 0), Color("1A1424"))
	c["out"][key + "_mat"] = Props.glowing(o, Vector3(0.5, 0.42, 0.012), Vector3(0, 1.35, 0.381), col, 0.9)
	Props.glowing(o, Vector3(0.66, 0.16, 0.05), Vector3(0, 1.88, 0.36), col, 0.8)
	Props.part(o, Vector3(0.66, 0.06, 0.25), Vector3(0, 1.0, 0.45), Palette.INK2, null, false)
	Props.finish(o, c["solids"], Vector3(0.7, 1.95, 0.75), Vector3(0, 0, 0.95), Vector3(0, 0, 0.8), Vector3(0, 1.35, 0))
	return o


static func furnace(c: Dictionary, pos: Vector3, yaw: float) -> void:
	var b := solid(c, pos, yaw)
	RoomBuilder.box(b, Vector3(0.8, 1.6, 0.7), Vector3(0, 0.8, 0), Color("8C8C84"))
	RoomBuilder.box(b, Vector3(0.3, 0.8, 0.3), Vector3(0, 2.0, -0.1), Color("A8A89E"))
	RoomBuilder.box(b, Vector3(0.5, 1.4, 0.5), Vector3(0.75, 0.7, 0), Color("D9D2C2"))    # water heater
	Props.finish(b, c["solids"], Vector3(1.4, 1.6, 0.7), Vector3(0.35, 0, 0), Vector3(0.35, 0, 0))


# ================================================================ doors between levels

## The door you came through, on the other side (attic stairs going down, the
## basement steps going up). `pair` is the door on the main level.
static func portal_back(c: Dictionary, key: String, title: String, pos: Vector3, yaw: float, up: bool) -> SmartObject:
	var o := item(c, key, title, "portal", pos, yaw)
	if up:   # a staircase coming up from below, with a railing
		for i in 4:
			Props.part(o, Vector3(0.9, 0.06, 0.3), Vector3(0, -0.06 - i * 0.18, 0.2 + i * 0.3), Palette.WOOD, null, false)
		Props.part(o, Vector3(1.1, 0.9, 0.06), Vector3(0, 0.45, -0.1), Palette.WOOD_DARK)
		Props.part(o, Vector3(0.06, 0.9, 1.3), Vector3(-0.52, 0.45, 0.55), Palette.WOOD_DARK)
		Props.part(o, Vector3(0.06, 0.9, 1.3), Vector3(0.52, 0.45, 0.55), Palette.WOOD_DARK)
		Props.finish(o, c["solids"], Vector3(1.1, 0.9, 1.4), Vector3(0, 0, -0.75), Vector3(0, 0, -0.55), Vector3(0, 0.5, 0.6),
			Vector3(0, 0.45, 0.55))
	else:    # a door at the top of the basement steps
		Props.part(o, Vector3(0.9, 2.1, 0.08), Vector3(0, 1.05, -0.04), Color("7A4A2E"))
		Props.part(o, Vector3(1.06, 2.2, 0.06), Vector3(0, 1.1, -0.08), Palette.CREAM, null, false)
		Props.part(o, Vector3(0.07, 0.07, 0.07), Vector3(0.32, 1.0, 0.03), Palette.GOLD, null, false)
		for i in 3:
			Props.part(o, Vector3(0.9, 0.2 + i * 0.2, 0.3), Vector3(0, 0.1 + i * 0.1, 0.15 + (2 - i) * 0.3), Palette.WOOD, null, false)
		Props.finish(o, c["solids"], Vector3(1.0, 2.2, 0.2), Vector3(0, 0, 1.25), Vector3(0, 0, 1.1), Vector3(0, 1.2, 0),
			Vector3(0, 1.1, -0.04))
	return o


## Where the newspaper goes (and where you knock): just outside a front door.
static func porch_spot(c: Dictionary, key: String, door_pos: Vector3, outward: Vector3, mat := true) -> SmartObject:
	var o := SmartObject.new()
	o.name = key
	o.display_name = "Front Porch"
	o.kind = "porch"
	o.home = c["home"]
	(c["root"] as Node3D).add_child(o)
	# A doormat to click (flat, so nobody trips on it walking in)
	var mat_at := Vector3(door_pos.x, 0, door_pos.z) + outward * 0.6
	var across := Vector3(absf(outward.z), 0, absf(outward.x))
	var mat_size := across * 0.8 + Vector3(absf(outward.x), 0, absf(outward.z)) * 0.5 + Vector3(0, 0.018, 0)
	if mat:
		o.add_material(RoomBuilder.box(o, mat_size, mat_at + Vector3(0, 0.036, 0), Color("8A5A3B")).material_override)
	RoomBuilder.add_shape(o, mat_size + Vector3(0, 0.01, 0), mat_at + Vector3(0, 0.03, 0))
	o.approach_point = Vector3(door_pos.x, 0, door_pos.z) + outward * 1.5
	o.use_point = o.approach_point
	o.look_point = door_pos + outward * 0.6
	o.shared = true
	(c["objects"] as Dictionary)[key] = o
	return o
