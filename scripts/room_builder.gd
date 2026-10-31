class_name RoomBuilder
extends RefCounted
## Builds the 1986 house out of simple boxes (stand-ins for real Blender models
## later). The living room is 8 m wide (x) and 6 m deep (z), with its back wall
## at z = 0 and left wall at x = 0. The hallway runs east from its right wall,
## with the bedroom south of the hallway and the staircase at its far end
## (see house_builder.gd).
##
## Collision layers: 1 = clickable (floor, smart objects), 2 = walls and
## plain furniture, 4 = the resident.

const W := 8.0
const D := 6.0
const H := 2.6
const CELL := 0.25
## Collision layer for floors and stair treads: clickable, but not solid
## (Jamie's height comes from HouseBuilder.floor_height instead).
const LAYER_FLOOR := 8
const FRONT_DOOR_X := 1.3   # front door: front wall, facing the street
const HALL_DOOR_Z := 3.05   # hallway door: right wall


static func build(root: Node3D) -> Dictionary:
	var out := {}
	HouseBuilder.RAMPS.clear()
	Furnish._lamps = 0
	out["portal_pairs"] = [["attic_door", "jamie_attic_exit"], ["basement_door", "jamie_basement_exit"]]
	out["npc_spots"] = {}
	var tex := {
		"carpet": make_tex("carpet"),
		"panel": make_tex("panel"),
		"scan": make_tex("scan"),
		"plaid": make_tex("plaid"),
		"memphis": make_ctex("memphis"),
		"wallpaper": make_ctex("wallpaper"),
		"hall": make_ctex("hall"),
		"teal_shag": make_ctex("teal_shag"),
		"siding": make_tex("siding"),
		"asphalt": make_tex("asphalt"),
		"concrete": make_tex("concrete"),
		"brick": make_tex("brick"),
		"grass": make_ctex("grass"),
		"lino": make_ctex("lino"),
		"kitchen": make_ctex("kitchen"),
	}
	out["tex"] = tex      # (the asset baker saves these as PNGs: assets/textures/)
	var solids: Array[Rect2] = []

	out["walls"] = []
	out["ceilings"] = []
	out["lamps"] = []
	out["swing_doors"] = []

	# ---- Floor (clickable) ----
	make_floor(root, Rect2(0, 0, W, D), Palette.SHAG, tex["carpet"])

	# ---- Walls: full height + a low stub shown when the camera cuts them away ----
	var walls := []
	walls.append(make_wall(root, "BackWall", Vector3(W / 2, 0, -0.075), Vector3(W + 0.3, H, 0.15), Vector3(0, 0, -1), tex))
	walls.append(make_wall(root, "LeftWall", Vector3(-0.075, 0, D / 2), Vector3(0.15, H, D + 0.3), Vector3(-1, 0, 0), tex))
	walls.append(make_wall(root, "FrontWall", Vector3((W - 0.15) / 2, 0, D + 0.075), Vector3(W + 0.15, H, 0.15), Vector3(0, 0, 1), tex,
		[{"c": FRONT_DOOR_X, "w": 0.92, "h": 2.1}]))
	walls.append(make_wall(root, "RightWall", Vector3(W + 0.075, 0, (D - 0.15) / 2), Vector3(0.15, H, D + 0.15), Vector3(1, 0, 0), tex,
		[{"c": HALL_DOOR_Z, "w": 0.9, "h": 2.1}], true))
	(out["walls"] as Array).append_array(walls)
	var back_decor: Node3D = walls[0]["full"]
	var right_decor: Node3D = walls[3]["full"]

	make_ceiling(root, out, Rect2(0, 0, W, D), H)

	# ---- Window on the back wall (an emissive "sky" pane) ----
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color("BFE0EE")
	glass_mat.emission_enabled = true
	glass_mat.emission = Color("BFE0EE")
	glass_mat.emission_energy_multiplier = 1.0
	out["window_mat"] = glass_mat
	add_int_window(back_decor, Vector3(2.1, 1.5, 0.0), 1.58, 1.08, true, 1.0, glass_mat)
	box_at(back_decor, Vector3(0.26, 1.6, 0.12), Vector3(1.08, 1.45, 0.08), Palette.GOLD, tex["plaid"], 4.0)
	box_at(back_decor, Vector3(0.26, 1.6, 0.12), Vector3(3.12, 1.45, 0.08), Palette.GOLD, tex["plaid"], 4.0)
	box_at(back_decor, Vector3(2.4, 0.06, 0.1), Vector3(2.1, 2.3, 0.1), Palette.WOOD_DARK)
	var beam := SpotLight3D.new()
	beam.position = Vector3(2.1, 2.2, 0.35)
	beam.rotation_degrees = Vector3(-130, 0, 0)
	beam.spot_angle = 32.0
	beam.spot_range = 7.0
	beam.light_color = Palette.LAMP
	beam.shadow_enabled = true
	root.add_child(beam)
	out["sunbeam"] = beam

	# ---- Poster (right wall) ----
	box_at(right_decor, Vector3(0.04, 1.26, 0.96), Vector3(7.97, 1.6, 4.45), Palette.NAVY)
	box_at(right_decor, Vector3(0.05, 0.42, 0.42), Vector3(7.96, 1.82, 4.45), Palette.CORAL)
	box_at(right_decor, Vector3(0.05, 0.08, 0.6), Vector3(7.96, 1.15, 4.45), Palette.CRT)

	# ---- Front door (front wall): a real door out to the front yard ----
	make_casing(walls[2], FRONT_DOOR_X, 0.92, 2.1, Palette.CREAM)
	var jfd := HouseBuilder.make_swing_door(walls[2], FRONT_DOOR_X, 0.92, 2.1, Color("7A4A2E"), Vector3(0, 0, -1), false)
	jfd["home"] = "jamie"          # (an outside door: visitors knock first)
	(out["swing_doors"] as Array).append(jfd)
	make_floor(root, Rect2(FRONT_DOOR_X - 0.46, D, 0.92, 0.15), Palette.WOOD_DARK)

	# ---- The living room from outside: siding, windows, roof ----
	add_siding(walls[0], -1.0, H, tex, -INF, HouseBuilder.HX0 - HouseBuilder.T, true, false)   # (the east end meets the north wing)
	add_siding(walls[1], -1.0, H, tex)
	add_siding(walls[2], 1.0, H, tex, -INF, INF, true, false)
	out["night_windows"] = make_night_window_mat(out)
	add_ext_window(walls[0]["full"], Vector3(2.1, 1.5, -0.17), Vector3(1.7, 1.2, 0.04), out)
	# A front window over the couch, looking out at the street
	var fd: Node3D = walls[2]["full"]
	add_int_window(fd, Vector3(5.6, 1.65, D), 1.7, 0.9, true, -1.0, glass_mat)
	box_at(fd, Vector3(0.26, 1.4, 0.12), Vector3(4.55, 1.6, D - 0.08), Palette.GOLD, tex["plaid"], 4.0)
	box_at(fd, Vector3(0.26, 1.4, 0.12), Vector3(6.65, 1.6, D - 0.08), Palette.GOLD, tex["plaid"], 4.0)
	add_ext_window(fd, Vector3(5.6, 1.65, D + 0.17), Vector3(1.7, 0.9, 0.04), out)
	make_roof(root, out, Rect2(-0.15, -0.15, W + 0.3, D + 0.3), H, 0.55, ROOF, true, 0.35, 0.0)

	# ---- Open archway into the hallway ----
	make_casing(walls[3], HALL_DOOR_Z, 0.9, 2.1, Palette.CREAM)
	make_floor(root, Rect2(W, HALL_DOOR_Z - 0.45, 0.15, 0.9), Palette.WOOD_DARK)
	# The other sides of the living room's right wall: hallway stripes and bedroom wallpaper
	var hz0 := HALL_DOOR_Z - 0.45
	var hz1 := HALL_DOOR_Z + 0.45
	add_skin(walls[3], 1.0, HouseBuilder.HZ0, hz0, 0.18, H - 0.08, tex, "hall")
	add_skin(walls[3], 1.0, hz1, HouseBuilder.HZ1, 0.18, H - 0.08, tex, "hall")
	add_skin(walls[3], 1.0, hz0, hz1, 2.1, H - 0.08, tex, "hall")
	add_skin(walls[3], 1.0, HouseBuilder.BZ0, D, 0.18, H - 0.08, tex, "wallpaper")

	# ---- Rug ----
	box(root, Vector3(3.4, 0.02, 2.2), Vector3(4.1, 0.01, 3.1), Palette.ROSE)
	box(root, Vector3(3.0, 0.03, 1.9), Vector3(4.1, 0.015, 3.1), Color("E9A7A3"))

	# ---- TV ----
	var tv := SmartObject.new()
	tv.name = "TV"
	tv.display_name = "Living Room TV"
	root.add_child(tv)
	tv.add_material(box(tv, Vector3(1.7, 0.6, 0.8), Vector3(4.05, 0.3, 0.5), Palette.WOOD_DARK).material_override)
	tv.add_material(box(tv, Vector3(1.4, 1.04, 0.75), Vector3(4.05, 1.12, 0.52), Color("5A3A24")).material_override)
	var screen := box(tv, Vector3(1.04, 0.8, 0.03), Vector3(3.92, 1.12, 0.905), Palette.CRT, tex["scan"], 12.0)
	var screen_mat: StandardMaterial3D = screen.material_override
	screen_mat.emission_enabled = true
	screen_mat.emission = Palette.CRT
	screen_mat.emission_texture = tex["scan"]
	out["screen_mat"] = screen_mat
	box(tv, Vector3(0.12, 0.12, 0.04), Vector3(4.6, 1.32, 0.9), Palette.MUTED)
	box(tv, Vector3(0.12, 0.12, 0.04), Vector3(4.6, 1.06, 0.9), Palette.MUTED)
	var ear1 := box(tv, Vector3(0.025, 0.6, 0.025), Vector3(3.92, 1.9, 0.5), Palette.MUTED)
	ear1.rotation_degrees.z = 25.0
	var ear2 := box(tv, Vector3(0.025, 0.6, 0.025), Vector3(4.18, 1.9, 0.5), Palette.MUTED)
	ear2.rotation_degrees.z = -25.0
	box(tv, Vector3(1.2, 0.18, 0.06), Vector3(4.05, 0.3, 0.92), Palette.INK)
	var vcr_clock := box(tv, Vector3(0.14, 0.05, 0.02), Vector3(4.45, 0.3, 0.955), Palette.CORAL)
	var vcr_mat: StandardMaterial3D = vcr_clock.material_override
	vcr_mat.emission_enabled = true
	vcr_mat.emission = Palette.CORAL
	vcr_mat.emission_energy_multiplier = 0.6   # the blinking 12:00
	add_shape(tv, Vector3(1.7, 1.64, 0.8), Vector3(4.05, 0.82, 0.5))
	solids.append(Rect2(3.2, 0.1, 1.7, 0.8))
	tv.approach_point = Vector3(4.1, 0, 3.55)
	tv.use_point = Vector3(4.1, 0, 4.45)
	tv.look_point = Vector3(4.1, 1.1, 0.5)
	var tv_light := OmniLight3D.new()
	tv_light.position = Vector3(3.92, 1.12, 1.3)
	tv_light.light_color = Palette.CRT
	tv_light.omni_range = 4.0
	tv_light.light_energy = 0.0
	root.add_child(tv_light)
	out["tv_light"] = tv_light

	# ---- Couch ----
	var couch := SmartObject.new()
	couch.name = "Couch"
	couch.display_name = "Couch"
	root.add_child(couch)
	couch.add_material(box(couch, Vector3(2.6, 0.45, 0.9), Vector3(4.1, 0.225, 4.45), Color("C2572F"), tex["plaid"], 3.0).material_override)
	couch.add_material(box(couch, Vector3(2.6, 1.0, 0.3), Vector3(4.1, 0.5, 5.05), Palette.RUST).material_override)
	couch.add_material(box(couch, Vector3(0.22, 0.7, 1.1), Vector3(2.69, 0.35, 4.6), Palette.RUST).material_override)
	couch.add_material(box(couch, Vector3(0.22, 0.7, 1.1), Vector3(5.51, 0.35, 4.6), Palette.RUST).material_override)
	var pillow := box(couch, Vector3(0.42, 0.36, 0.2), Vector3(3.15, 0.62, 4.8), Palette.GOLD)
	pillow.rotation_degrees.z = -8.0
	add_shape(couch, Vector3(3.04, 1.0, 1.2), Vector3(4.1, 0.5, 4.6))
	solids.append(Rect2(2.58, 4.0, 3.04, 1.2))
	couch.approach_point = tv.approach_point
	couch.use_point = tv.use_point
	couch.look_point = tv.look_point

	# ---- Coffee table ----
	var table := StaticBody3D.new()
	table.collision_layer = 2
	root.add_child(table)
	box(table, Vector3(1.6, 0.06, 0.7), Vector3(4.1, 0.38, 2.7), Palette.WOOD)
	for lx in [3.38, 4.82]:
		for lz in [2.42, 2.98]:
			box(table, Vector3(0.06, 0.35, 0.06), Vector3(lx, 0.175, lz), Palette.WOOD_DARK)
	box(table, Vector3(0.24, 0.1, 0.24), Vector3(4.5, 0.46, 2.65), Palette.CREAM)
	for i in 3:
		box(table, Vector3(0.2, 0.03, 0.11), Vector3(3.7, 0.425 + i * 0.032, 2.7), Palette.CORAL if i == 1 else Palette.INK)
	add_shape(table, Vector3(1.6, 0.41, 0.7), Vector3(4.1, 0.205, 2.7))
	solids.append(Rect2(3.3, 2.35, 1.6, 0.7))

	var objects := {}

	# ---- Stereo console with a record player (where the kitchen corner used to be)
	var st := Props.item(root, objects, "stereo", "Stereo & Records", Vector3(6.25, 0, 0.3), 0)
	Props.part(st, Vector3(1.3, 0.62, 0.48), Vector3(0, 0.31, 0), Palette.WOOD_DARK, tex["panel"])
	Props.part(st, Vector3(1.26, 0.02, 0.44), Vector3(0, 0.63, 0), Palette.WOOD)
	for gx in [-0.42, 0.42]:
		Props.part(st, Vector3(0.36, 0.44, 0.012), Vector3(gx, 0.3, 0.246), Color("3A2A22"), null, false)   # speaker grilles
	Props.part(st, Vector3(0.36, 0.08, 0.3), Vector3(-0.05, 0.68, 0.0), Palette.INK2)                   # turntable
	out["record_mat"] = Props.glowing(st, Vector3(0.26, 0.012, 0.26), Vector3(-0.05, 0.726, 0.0), Palette.INK, 0.0)
	Props.part(st, Vector3(0.03, 0.03, 0.18), Vector3(0.09, 0.735, 0.04), Palette.MUTED, null, false)    # tone arm
	Props.part(st, Vector3(0.34, 0.1, 0.26), Vector3(0.4, 0.69, 0.0), Palette.INK)                       # receiver
	Props.glowing(st, Vector3(0.2, 0.025, 0.006), Vector3(0.4, 0.7, 0.133), Color("E3A93B"), 0.35)
	for k in 6:   # a stack of LPs leaning against the console (staggered so no two sleeves share a face)
		var lp_h := 0.31 - k * 0.006
		Props.part(st, Vector3(0.31 - k * 0.004, lp_h, 0.012), Vector3(0.66 + k * 0.011, 0.006 + lp_h / 2.0, 0.12 + k * 0.016),
			[Palette.CORAL, Palette.NAVY, Palette.GOLD, Palette.TEAL, Palette.ROSE, Palette.INK][k], null, false)
	Props.finish(st, solids, Vector3(1.3, 0.75, 0.48), Vector3(0, 0, 0.95), null, Vector3(0, 0.7, 0))

	# ---- Dad's recliner, angled toward the TV
	var rc := Props.item(root, objects, "recliner", "Dad's Recliner", Vector3(7.25, 0, 1.55), -125)
	Props.part(rc, Vector3(0.82, 0.42, 0.78), Vector3(0, 0.21, 0), Color("6B4429"), tex["plaid"])
	Props.part(rc, Vector3(0.8, 0.62, 0.22), Vector3(0, 0.71, -0.3), Color("7A4F33"), tex["plaid"])
	Props.part(rc, Vector3(0.16, 0.24, 0.76), Vector3(-0.336, 0.54, 0), Color("6B4429"))
	Props.part(rc, Vector3(0.16, 0.24, 0.76), Vector3(0.336, 0.54, 0), Color("6B4429"))
	Props.part(rc, Vector3(0.48, 0.08, 0.5), Vector3(0, 0.45, 0.08), Color("8A5A3B"))                   # seat cushion
	Props.finish(rc, solids, Vector3(0.82, 1.02, 0.8), Vector3(0, 0, 0.95), Vector3(0, 0, 0.05), Vector3(0, 0.8, 2.0))

	# ---- Bookshelf ----
	var shelf := SmartObject.new()
	shelf.name = "Bookshelf"
	shelf.display_name = "Bookshelf"
	root.add_child(shelf)
	objects["bookshelf"] = shelf
	shelf.approach_point = Vector3(1.05, 0, 1.85)
	shelf.use_point = shelf.approach_point
	shelf.look_point = Vector3(0.2, 1.2, 1.85)
	shelf.add_material(box(shelf, Vector3(0.46, 1.9, 1.7), Vector3(0.23, 0.95, 1.85), Palette.WOOD_DARK).material_override)
	var rows := [Palette.GOLD, Palette.TEAL, Palette.CORAL]
	for i in 3:
		box(shelf, Vector3(0.42, 0.34, 1.54), Vector3(0.26, 0.32 + i * 0.56, 1.85), rows[i], tex["plaid"], 5.0)
	add_shape(shelf, Vector3(0.46, 1.9, 1.7), Vector3(0.23, 0.95, 1.85))
	solids.append(Rect2(0.0, 1.0, 0.46, 1.7))

	# ---- Floor lamp (switch it on and off: it does the whole room) ----
	var lamp_body := SmartObject.new()
	lamp_body.name = "living_lamp"
	lamp_body.display_name = "Floor Lamp"
	lamp_body.kind = "lamp"
	lamp_body.home = "jamie"
	root.add_child(lamp_body)
	lamp_body.approach_point = Vector3(5.22, 0, 1.15)
	lamp_body.use_point = lamp_body.approach_point
	lamp_body.look_point = Vector3(5.22, 1.6, 0.5)
	box(lamp_body, Vector3(0.36, 0.04, 0.36), Vector3(5.22, 0.02, 0.5), Palette.WOOD_DARK)
	box(lamp_body, Vector3(0.06, 1.6, 0.06), Vector3(5.22, 0.82, 0.5), Palette.WOOD_DARK)
	var shade := box(lamp_body, Vector3(0.48, 0.36, 0.48), Vector3(5.22, 1.75, 0.5), Palette.LAMP)
	var shade_mat: StandardMaterial3D = shade.material_override
	lamp_body.add_material(shade_mat)
	shade_mat.emission_enabled = true
	shade_mat.emission = Palette.LAMP
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_shape(lamp_body, Vector3(0.3, 1.9, 0.3), Vector3(5.22, 0.95, 0.5))
	solids.append(Rect2(5.04, 0.32, 0.36, 0.36))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(5.22, 1.55, 0.6)
	lamp.light_color = Palette.LAMP
	lamp.omni_range = 7.0
	lamp.shadow_enabled = true
	root.add_child(lamp)
	add_lamp(out, lamp, shade_mat, 0.3, 2.4)

	# ---- Plant ----
	var plant := StaticBody3D.new()
	plant.collision_layer = 2
	root.add_child(plant)
	box(plant, Vector3(0.5, 0.48, 0.5), Vector3(7.5, 0.24, 5.4), Color("C2572F"))
	box(plant, Vector3(0.7, 0.4, 0.7), Vector3(7.5, 0.68, 5.4), Palette.AVOCADO)
	box(plant, Vector3(0.4, 0.32, 0.4), Vector3(7.5, 1.02, 5.4), Color("8FA246"))
	add_shape(plant, Vector3(0.5, 0.9, 0.5), Vector3(7.5, 0.45, 5.4))
	solids.append(Rect2(7.25, 5.15, 0.5, 0.5))

	objects.merge({"tv": tv, "couch": couch, "living_lamp": lamp_body})
	out["objects"] = objects

	# ---- The rest of the house: hallway, staircase, bedroom ----
	var free: Array[Rect2] = [Rect2(0, 0, W, D)]
	var doorways: Array[Rect2] = [Rect2(W - 0.4, HALL_DOOR_Z - 0.3, 1.0, 0.6),
		Rect2(FRONT_DOOR_X - 0.35, D - 0.45, 0.7, 1.2)]
	var outdoor: Array[Rect2] = []
	var buildings: Array[Rect2] = [Rect2(-0.15, -0.15, W + 0.3, D + 0.3)]
	HouseBuilder.build(root, out, tex, solids, free, doorways, buildings)
	Furnish.porch_spot({"root": root, "objects": objects, "home": "jamie"}, "jamie_porch", Vector3(FRONT_DOOR_X, 0, D), Vector3(0, 0, 1), false)

	# ---- The neighborhood: yards, street, neighbors ----
	OutdoorBuilder.build(root, out, tex, solids, outdoor, buildings)
	NeighborBuilder.build(root, out, tex, solids, free, doorways, buildings)
	DowntownBuilder.build(root, out, tex, solids, free, doorways, buildings)
	CivicBuilder.build(root, out, tex, solids, free, doorways, buildings)
	MallBuilder.build(root, out, tex, solids, free, doorways, buildings)
	EastBuilder.build(root, out, tex, solids, free, doorways, buildings)
	SchoolBuilder.build(root, out, tex, solids, free, doorways, buildings)
	PayPhones.place_all(root, out, solids)
	SceneryBuilder.build(root, out, tex)
	# Every attic and basement, on their own level underground
	var solids1: Array[Rect2] = []
	var free1: Array[Rect2] = []
	InteriorBuilder.build(root, out, tex, solids1, free1)
	SchoolBuilder.build_upstairs(root, out, tex, solids1, free1)
	for pair in out["portal_pairs"]:
		var a: SmartObject = out["objects"].get(pair[0])
		var b: SmartObject = out["objects"].get(pair[1])
		if a and b:
			a.portal_to = b
			b.portal_to = a
			a.level = 0
			b.level = 1
			a.kind = "portal"
			b.kind = "portal"
	out["grid1"] = _make_grid([], [], free1, [], solids1, INTERIOR_WORLD)
	out["solids1"] = solids1

	out["rooms"] = {
		"jamie|Living Room": Rect2(0, 0, W, D),
		"jamie|Hallway": Rect2(W, 0.5, 8.2, 3.3),
		"jamie|Kid Room": Rect2(W, 3.95, 4.5, 4.5),
		"jamie|Kitchen": Rect2(KitchenBuilder.KX0, KitchenBuilder.KZ0, KitchenBuilder.KX1 - KitchenBuilder.KX0, KitchenBuilder.KZ1 - KitchenBuilder.KZ0),
	}
	(out["rooms"] as Dictionary).merge(out["home_rooms"])
	(out["rooms"] as Dictionary).merge(out["town_rooms"])
	(out["rooms"] as Dictionary).merge(out["interior_rooms"])
	(out["rooms"] as Dictionary).merge(out["wing_rooms"])
	out["indoor_rects"] = (out["rooms"] as Dictionary).values()
	# A light switch in every room with lights (and the lamps switch their rooms)
	LightSwitches.build(root, out)
	for k in out["objects"]:
		var lo: SmartObject = out["objects"][k]
		if lo.kind == "lamp":
			lo.set_meta("room", LightSwitches.room_for(out["rooms"], out["interior_rooms"], lo.look_point))
	out["grid"] = _make_grid(outdoor, buildings, free, doorways, solids)
	out["grid_lists"] = [outdoor, buildings, free, doorways, solids]   # to rebuild the grid when a car moves
	_fix_approaches(out)
	return out


## Anything whose "walk up to it" spot landed on a blocked cell (a light switch
## behind a chair, a lamp in a corner) gets the nearest open spot instead.
static func _fix_approaches(out: Dictionary) -> void:
	for k in out["objects"]:
		var o: SmartObject = out["objects"][k]
		if o is Car:
			continue
		var g: AStarGrid2D = out["grid"] if o.level == 0 else out["grid1"]
		var ap := o.approach_point
		var c := Vector2i(floori(ap.x / CELL), floori(ap.z / CELL))
		if not g.is_in_boundsv(c) or not g.is_point_solid(c):
			continue
		var best := Vector2i(-99999, 0)
		var bd := INF
		for dx in range(-5, 6):
			for dy in range(-5, 6):
				var n := c + Vector2i(dx, dy)
				if not g.is_in_boundsv(n) or g.is_point_solid(n):
					continue
				var p := Vector3((n.x + 0.5) * CELL, 0, (n.y + 0.5) * CELL)
				# (prefer spots close to the thing itself, too)
				var d := p.distance_to(ap) + 0.3 * Vector2(p.x - o.look_point.x, p.z - o.look_point.z).length()
				if d < bd:
					bd = d
					best = n
		if best.x == -99999:
			continue
		var np := Vector3((best.x + 0.5) * CELL, 0, (best.y + 0.5) * CELL)
		if o.use_point.is_equal_approx(o.approach_point):
			o.use_point = np
		o.approach_point = np


## Rebuild the walking grid (after a car parks somewhere new).
static func rebuild_grid(out: Dictionary) -> AStarGrid2D:
	var l: Array = out["grid_lists"]
	out["grid"] = _make_grid(l[0], l[1], l[2], l[3], l[4])
	return out["grid"]


## What the plain walking grid has in the cells under `area` (cell -> solid),
## worked out the same way _make_grid does (used to unlock a shop door).
static func rebuild_grid_region(out: Dictionary, area: Rect2) -> Dictionary:
	var l: Array = out["grid_lists"]
	var res := {}
	for x in range(floori(area.position.x / CELL), ceili(area.end.x / CELL)):
		for y in range(floori(area.position.y / CELL), ceili(area.end.y / CELL)):
			var cell := Rect2(x * CELL, y * CELL, CELL, CELL)
			var solid := true
			for r: Rect2 in l[0]:
				if r.grow(-0.2).encloses(cell):
					solid = false
			for r: Rect2 in l[1]:
				if r.grow(0.2).intersects(cell):
					solid = true
			for r: Rect2 in l[2]:
				if r.grow(-0.2).encloses(cell):
					solid = false
			for r: Rect2 in l[3]:
				if r.encloses(cell):
					solid = false
			for r: Rect2 in l[4]:
				if r.grow(0.2).intersects(cell):
					solid = true
			res[Vector2i(x, y)] = solid
	return res


# ---------------------------------------------------------------- helpers

## The whole neighborhood the walking grid covers (x, z).
const WORLD := Rect2(-26, -74, 164, 170)
## Attics and basements: built this far underground, over this area (level 1).
const INTERIOR_Y := -30.0
const INTERIOR_WORLD := Rect2(-24, -64, 162, 22)   # (x to 138: the high school's upstairs is out east)


## The walking grid (0.25 m cells) for the whole neighborhood. Built in layers:
## outdoors walkable -> buildings blocked -> rooms walkable -> doorways -> furniture blocked.
## Rooms keep 0.2 m away from walls; furniture and buildings get 0.2 m of space around them.
static func _make_grid(outdoor: Array[Rect2], buildings: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], solids: Array[Rect2], world := WORLD) -> AStarGrid2D:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(int(world.position.x / CELL), int(world.position.y / CELL), int(world.size.x / CELL), int(world.size.y / CELL))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL / 2, CELL / 2)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	grid.fill_solid_region(grid.region, true)
	for r in outdoor:
		_set_cells(grid, r.grow(-0.2), false, true)
	for r in buildings:
		_set_cells(grid, r.grow(0.2), true, false)
	for r in free:
		_set_cells(grid, r.grow(-0.2), false, true)
	for r in doorways:
		_set_cells(grid, r, false, true)
	for r in solids:
		_set_cells(grid, r.grow(0.2), true, false)
	return grid


## Mark cells solid or walkable. `enclose` = only cells fully inside r (else: touching r).
static func _set_cells(grid: AStarGrid2D, r: Rect2, solid: bool, enclose: bool) -> void:
	for x in range(floori(r.position.x / CELL), ceili(r.end.x / CELL)):
		for y in range(floori(r.position.y / CELL), ceili(r.end.y / CELL)):
			var p := Vector2i(x, y)
			if not grid.is_in_boundsv(p):
				continue
			var cell := Rect2(x * CELL, y * CELL, CELL, CELL)
			if (enclose and r.encloses(cell)) or (not enclose and r.intersects(cell)):
				grid.set_point_solid(p, solid)


## A clickable floor (group "floor": clicking it walks Jamie there).
static func make_floor(root: Node3D, r: Rect2, color: Color, tex: Texture2D = null, y := 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = LAYER_FLOOR
	body.collision_mask = 0
	body.add_to_group("floor")
	root.add_child(body)
	var size := Vector3(r.size.x, 0.1, r.size.y)
	var center := Vector3(r.position.x + r.size.x / 2.0, y - 0.05, r.position.y + r.size.y / 2.0)
	box(body, size, center, color, tex, 3.0)
	add_shape(body, size, center)
	return body


## A ceiling, only shown in the close-up cameras.
## The ceiling sits just under the wall tops (height - 0.08 .. height), inside the
## room, so it never shares a surface with the roof or the walls.
static func make_ceiling(root: Node3D, out: Dictionary, r: Rect2, height: float) -> MeshInstance3D:
	var c := box(root, Vector3(r.size.x, 0.08, r.size.y), Vector3(r.position.x + r.size.x / 2.0, height - 0.04, r.position.y + r.size.y / 2.0), Color("EFE2C4"))
	c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(out["ceilings"] as Array).append(c)
	return c


## A light that main.gd dims or brightens with the time of day.
## `group` "bedroom" = switched off when Jamie goes to sleep.
static func add_lamp(out: Dictionary, light: Light3D, mat: StandardMaterial3D, day: float, night: float, group := "") -> void:
	(out["lamps"] as Array).append({"light": light, "mat": mat, "day": day, "night": night, "group": group})


## Door trim around an opening, on both sides of the wall.
static func make_casing(wall: Dictionary, c: float, width: float, height: float, trim_color: Color) -> void:
	var full: Node3D = wall["full"]
	# Thicker than the wall plus siding, and reaching 6 mm into the opening, so the
	# trim covers every edge in the doorway (no two surfaces in the same place).
	var casing: float = wall["thick"] + 0.15
	var ax: bool = wall["along_x"]
	var pl: float = wall["plane"]
	var a := c - width / 2.0
	var b := c + width / 2.0
	_span(full, null, ax, pl, a - 0.08, a + 0.006, 0.0, height + 0.08, casing, trim_color)
	_span(full, null, ax, pl, b - 0.006, b + 0.08, 0.0, height + 0.08, casing, trim_color)
	_span(full, null, ax, pl, a + 0.006, b - 0.006, height - 0.006, height + 0.08, casing, trim_color)


## A wall, optionally with door openings: [{"c": center along the wall, "w": width, "h": height}].
## "full" is the whole wall; "stub" is the low version shown when the camera cuts it away.
## `shared` = an inside wall between two rooms (always lowered in the House Cam).
## `normal` points away from the room this wall belongs to.
static func make_wall(root: Node3D, wall_name: String, base_center: Vector3, size: Vector3, normal: Vector3, tex: Dictionary,
		openings: Array = [], shared := false, color: Color = Palette.WOOD, surface: String = "panel") -> Dictionary:
	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = 2
	body.collision_mask = 0
	root.add_child(body)
	var full := Node3D.new()
	body.add_child(full)
	var stub := Node3D.new()
	stub.visible = false
	body.add_child(stub)

	var along_x := absf(normal.z) > 0.5
	var length := size.x if along_x else size.z
	var thick := size.z if along_x else size.x
	var plane := base_center.z if along_x else base_center.x
	var start := (base_center.x if along_x else base_center.z) - length / 2.0
	var inward := -normal * 0.03

	# Solid spans between the openings.
	var sorted := openings.duplicate()
	sorted.sort_custom(func(p, q): return p["c"] < q["c"])
	var spans := []
	var cursor := start
	for o in sorted:
		spans.append([cursor, float(o["c"]) - float(o["w"]) / 2.0])
		cursor = float(o["c"]) + float(o["w"]) / 2.0
	spans.append([cursor, start + length])

	for s in spans:
		var a: float = s[0]
		var b: float = s[1]
		if b - a < 0.01:
			continue
		_span(full, body, along_x, plane, a, b, 0.0, size.y, thick, color, tex[surface])
		_span(full, null, along_x, plane, a + 0.003, b - 0.003, 0.0, 0.18, thick + 0.02, Palette.WOOD_DARK, null, inward if not shared else Vector3.ZERO)
		_span(stub, null, along_x, plane, a, b, 0.0, 0.35, thick, color, tex[surface])
		_span(stub, null, along_x, plane, a - 0.02, b + 0.02, 0.35, 0.4, thick + 0.04, Palette.WOOD_DARK)
	for o in sorted:
		var a2: float = float(o["c"]) - float(o["w"]) / 2.0
		var b2: float = float(o["c"]) + float(o["w"]) / 2.0
		_span(full, body, along_x, plane, a2, b2, float(o["h"]), size.y, thick, color, tex[surface])
	return {"body": body, "full": full, "stub": stub, "normal": normal, "center": base_center,
		"along_x": along_x, "plane": plane, "thick": thick, "shared": shared,
		"spans": spans, "openings": sorted}


## One box running along a wall from a to b, between heights y0 and y1.
## Also adds a matching collision shape when `body` is given.
static func _span(parent: Node3D, body: CollisionObject3D, along_x: bool, plane: float, a: float, b: float,
		y0: float, y1: float, thick: float, color: Color, tex: Texture2D = null, offset := Vector3.ZERO) -> MeshInstance3D:
	var mid := (a + b) / 2.0
	var center := Vector3(mid, (y0 + y1) / 2.0, plane) if along_x else Vector3(plane, (y0 + y1) / 2.0, mid)
	var sz := Vector3(b - a, y1 - y0, thick) if along_x else Vector3(thick, y1 - y0, b - a)
	if body != null:
		add_shape(body, sz, center)
	return box(parent, sz, center + offset, color, tex, 1.0)


## A door in a wall opening, swinging into the room on a hinge.
## The door panel hangs on the wall so it disappears with it in the cutaway view;
## the clickable SmartObject stays in the doorway and also blocks the way through.
static func make_door(root: Node3D, wall: Dictionary, c: float, width: float, height: float, door_name: String,
		slab_color: Color, trim_color: Color, panels: bool) -> SmartObject:
	var full: Node3D = wall["full"]
	var along_x: bool = wall["along_x"]
	var plane: float = wall["plane"]
	var thick: float = wall["thick"]
	var normal: Vector3 = wall["normal"]
	var room_dir := -normal
	var axis := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var a := c - width / 2.0
	var b := c + width / 2.0

	# Casing around the opening
	var casing := thick + 0.05
	_span(full, null, along_x, plane, a - 0.08, a, 0.0, height + 0.08, casing, trim_color)
	_span(full, null, along_x, plane, b, b + 0.08, 0.0, height + 0.08, casing, trim_color)
	_span(full, null, along_x, plane, a - 0.08, b + 0.08, height, height + 0.08, casing, trim_color)
	_span(full, null, along_x, plane, a, b, 0.0, 0.02, thick, Palette.WOOD_DARK)  # threshold

	# Hinge at the room-side face of the wall
	var hinge := Node3D.new()
	var inner := (Vector3(0, 0, plane) if along_x else Vector3(plane, 0, 0)) + room_dir * (thick / 2.0)
	hinge.position = inner
	if along_x:
		hinge.position.x = a + 0.01
	else:
		hinge.position.z = a + 0.01
	full.add_child(hinge)
	var slab_w := width - 0.02
	var slab_size := Vector3(slab_w, height - 0.03, 0.05) if along_x else Vector3(0.05, height - 0.03, slab_w)
	var obj := SmartObject.new()
	obj.name = door_name.replace(" ", "")
	obj.display_name = door_name
	root.add_child(obj)
	var slab := box(hinge, slab_size, axis * (slab_w / 2.0) + Vector3(0, height / 2.0, 0) - room_dir * 0.03, slab_color)
	obj.add_material(slab.material_override)
	if panels:
		for py in [0.55, 1.45]:
			var p_size := Vector3(slab_w - 0.25, 0.7, 0.02) if along_x else Vector3(0.02, 0.7, slab_w - 0.25)
			var panel := box(hinge, p_size, axis * (slab_w / 2.0) + Vector3(0, py, 0) + room_dir * 0.0, slab_color.darkened(0.18))
			obj.add_material(panel.material_override)
	box(hinge, Vector3(0.07, 0.07, 0.07), axis * (slab_w - 0.09) + Vector3(0, 1.0, 0) + room_dir * 0.03, Palette.GOLD)
	box(hinge, Vector3(0.07, 0.07, 0.07), axis * (slab_w - 0.09) + Vector3(0, 1.0, 0) - room_dir * 0.09, Palette.GOLD)

	# Which way is "into the room" for this hinge?
	var open_angle := deg_to_rad(80.0)
	if (Basis(Vector3.UP, open_angle) * axis).dot(room_dir) < 0.0:
		open_angle = -open_angle
	obj.door_hinge = hinge
	obj.door_open_angle = open_angle

	# Clickable doorway (also stops Jamie walking into the unbuilt beyond)
	var sz := Vector3(width, height, thick) if along_x else Vector3(thick, height, width)
	var center := (Vector3(c, height / 2.0, plane) if along_x else Vector3(plane, height / 2.0, c))
	add_shape(obj, sz, center)
	var doorway := Vector3(c, 0, plane) if along_x else Vector3(plane, 0, c)
	obj.approach_point = doorway + room_dir * 0.7
	obj.use_point = obj.approach_point
	obj.look_point = doorway + Vector3(0, 1.0, 0)
	return obj


## A colored box mesh centered at `center` (in the parent's space).
static func box(parent: Node3D, size: Vector3, center: Vector3, color: Color, tex: Texture2D = null, tex_scale: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	if tex != null:
		mat.albedo_texture = tex
		# Smooth filtering: the little stripe textures shimmer badly with pixel-sharp filtering.
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true   # wall pieces line up seamlessly
		mat.uv1_scale = Vector3.ONE * tex_scale
	mi.material_override = mat
	mi.position = center
	parent.add_child(mi)
	return mi


## Same as box(), but `world_center` is given in world space even when the
## parent is offset (used for decorations hung on walls).
static func box_at(parent: Node3D, size: Vector3, world_center: Vector3, color: Color, tex: Texture2D = null, tex_scale: float = 1.0) -> MeshInstance3D:
	return box(parent, size, world_center - parent.position, color, tex, tex_scale)


static func add_shape(body: CollisionObject3D, size: Vector3, center: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = center
	body.add_child(cs)


## Tiny 32x32 pixel textures, generated so the project has no image files.
static func make_tex(kind: String) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	for y in 32:
		for x in 32:
			var v := 1.0
			match kind:
				"carpet":
					v = 1.0 - rng.randf() * 0.22
				"panel":
					v = 0.62 if x % 8 == 0 else (0.97 - rng.randf() * 0.05 - (0.04 if x % 8 > 4 else 0.0))
				"scan":
					v = 0.72 if y % 2 == 0 else 1.0
				"plaid":
					v = 0.82 if (x % 8 < 2 or y % 8 < 2) else 1.0
				"siding":
					v = 0.7 if y % 4 == 0 else (0.9 if y % 4 == 1 else 1.0)
				"asphalt":
					v = 0.82 + rng.randf() * 0.18
				"concrete":
					v = 0.8 if (x == 0 or y == 0) else 0.93 + rng.randf() * 0.07
				"brick":
					var row := y / 8
					var off := 8 if row % 2 == 1 else 0
					v = 0.72 if (y % 8 == 0 or (x + off) % 16 == 0) else 0.92 + rng.randf() * 0.08
			img.set_pixel(x, y, Color(v, v, v))
	# Mipmaps: without them the fine stripes (siding, brick, paneling) shimmer
	# and flash at a distance, because the texture is sampled too sparsely.
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Small full-color textures for the 80s patterns (use with a white albedo).
static func make_ctex(kind: String) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	match kind:
		"memphis":
			# The classic: cream with a teal zigzag, coral squiggle, navy dots, gold confetti.
			img.fill(Palette.PAPER)
			for x in 32:
				var z := x % 8
				var zig := z if z < 4 else 8 - z
				img.set_pixel(x, 4 + zig, Palette.TEAL)
				img.set_pixel(x, 5 + zig, Palette.TEAL)
				var sq := int(round(2.0 * sin(x / 32.0 * TAU * 2.0)))
				img.set_pixel(x, 20 + sq, Palette.CORAL)
				img.set_pixel(x, 21 + sq, Palette.CORAL)
			for p in [Vector2i(3, 14), Vector2i(19, 13), Vector2i(27, 28), Vector2i(11, 29)]:
				img.fill_rect(Rect2i(p, Vector2i(2, 2)), Palette.NAVY)
			for p in [Vector2i(24, 15), Vector2i(8, 26), Vector2i(15, 1)]:
				img.fill_rect(Rect2i(p, Vector2i(3, 1)), Palette.GOLD)
				img.fill_rect(Rect2i(p + Vector2i(1, -1), Vector2i(1, 3)), Palette.GOLD)
		"wallpaper":
			# Pastel lavender with pinstripes and little teal diamonds.
			img.fill(Color("CDB8DD"))
			for y in 32:
				img.set_pixel(0, y, Color("B7A0CB"))
				img.set_pixel(16, y, Color("B7A0CB"))
			for c in [Vector2i(8, 8), Vector2i(24, 24)]:
				for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]:
					img.set_pixelv(c + d, Color("6FB7AE"))
		"hall":
			# Beige with soft vertical stripes.
			img.fill(Color("E6D6B4"))
			for y in 32:
				for x in [0, 1, 16, 17]:
					img.set_pixel(x, y, Color("D8C49C"))
		"grass":
			for y in 32:
				for x in 32:
					var g := Color("4A6A30").lerp(Color("5E7E38"), rng.randf())
					if rng.randf() < 0.05:
						g = Color("6E8A3E")
					img.set_pixel(x, y, g)
		"lino":
			# Checkerboard linoleum: cream and mustard
			for y in 32:
				for x in 32:
					var on := ((x / 16) + (y / 16)) % 2 == 0
					img.set_pixel(x, y, Color("F2E8CF") if on else Color("D9B45A"))
		"kitchen":
			# Cream wallpaper with a soft avocado-and-gold check
			img.fill(Color("F3E9CC"))
			for i in 32:
				for k in [0, 16]:
					img.set_pixel(k, i, Color("D8D3A4"))
					img.set_pixel(i, k, Color("D8D3A4"))
				for k in [8, 24]:
					img.set_pixel(k, i, Color("EBD39A"))
					img.set_pixel(i, k, Color("EBD39A"))
		"teal_shag":
			for y in 32:
				for x in 32:
					img.set_pixel(x, y, Color("2E8C8A").darkened(rng.randf() * 0.22))
	# Mipmaps: without them the fine stripes (siding, brick, paneling) shimmer
	# and flash at a distance, because the texture is sampled too sparsely.
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ================================================================ outside of the house

const SIDING := Color("D9C49E")        # 80s tan lap siding
const TRIM := Color("6B4429")          # dark brown trim
const ROOF := Color("5A4636")          # brown asphalt shingles
const FOUNDATION := Color("8F877C")


## Lap siding on the outside face of a wall (side = +1/-1: which face), up to `height`.
## `lo`..`hi` limits it to the part of the wall (along its length) that faces outdoors.
## `wrap_lo`/`wrap_hi` = false where that end of the wall meets another part of the house.
static func add_siding(wall: Dictionary, side: float, height: float, tex: Dictionary, lo := -INF, hi := INF,
		wrap_lo := true, wrap_hi := true, color: Color = SIDING, tex_key := "siding") -> void:
	var full: Node3D = wall["full"]
	var ax: bool = wall["along_x"]
	var pl: float = float(wall["plane"]) + side * (float(wall["thick"]) / 2.0 + 0.02)
	var spans: Array = wall["spans"]
	var first: float = spans[0][0]
	var last: float = spans[spans.size() - 1][1]
	for s in spans:
		var a: float = maxf(s[0], lo)
		var b: float = minf(s[1], hi)
		if b - a < 0.01:
			continue
		# At the wall's own ends (the house's corners) wrap past the corner, so the
		# siding of the two walls meets cleanly instead of edge-on.
		var wa := 0.04 if a == first and wrap_lo else 0.0
		var wb := 0.04 if b == last and wrap_hi else 0.0
		_span(full, null, ax, pl, a - wa, b + wb, -0.03, height, 0.04, color, tex[tex_key])
		# (where it doesn't wrap, the foundation stops just short, so its end never lines up with the siding's)
		var fa := a - wa * 1.5 if wa > 0.0 else a + 0.004
		var fb := b + wb * 1.5 if wb > 0.0 else b - 0.004
		_span(full, null, ax, pl + side * 0.008, fa, fb, -0.036, 0.22, 0.064, FOUNDATION)   # (its back sinks 4 mm into the wall)
	for o in wall["openings"]:
		var a2: float = maxf(float(o["c"]) - float(o["w"]) / 2.0, lo)
		var b2: float = minf(float(o["c"]) + float(o["w"]) / 2.0, hi)
		if b2 - a2 > 0.01:
			_span(full, null, ax, pl, a2, b2, float(o["h"]), height, 0.04, color, tex[tex_key])


## A thin layer of a different wall finish on one face of a wall (side +1/-1), from
## `a` to `b` along it and `y0` to `y1` up it. Used where one wall faces two rooms.
## Thinner than the baseboard, so the baseboard still shows below it.
static func add_skin(wall: Dictionary, side: float, a: float, b: float, y0: float, y1: float, tex: Dictionary,
		surface: String) -> void:
	if b - a < 0.01:
		return
	var pl: float = float(wall["plane"]) + side * (float(wall["thick"]) / 2.0 + 0.003)
	_span(wall["full"], null, wall["along_x"], pl, a, b, y0, y1, 0.006, Color.WHITE, tex[surface])


## Window glass that glows warm at night (main.gd dims it by day).
static func make_night_window_mat(out: Dictionary) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("34405A")
	m.roughness = 0.15
	m.emission_enabled = true
	m.emission = Color("F2C27A")
	(out["lamps"] as Array).append({"light": null, "mat": m, "day": 0.0, "night": 2.2, "group": ""})
	return m


## An outside window: white frame, glass, and a cross of muntins.
## `size` = (width, height, thickness) laid out along whichever horizontal axis is larger.
static func add_ext_window(parent: Node3D, center: Vector3, size: Vector3, out: Dictionary) -> void:
	var along_x := size.x > size.z
	var grow := Vector3(0.16, 0.16, 0.0) if along_x else Vector3(0.0, 0.16, 0.16)
	var proud := Vector3(0.0, 0.0, 0.012) if along_x else Vector3(0.012, 0.0, 0.0)
	# Each layer sticks out a little further than the one behind it (siding, frame,
	# glass, bars), so no two surfaces ever sit in the same spot.
	box(parent, size + grow + proud, center, Palette.PAPER)
	var glass := box(parent, size + 2.0 * proud, center, Color.WHITE)
	glass.material_override = out["night_windows"]
	var bar := 3.0 * proud + (Vector3(0, 0, size.z) if along_x else Vector3(size.x, 0, 0))
	box(parent, (Vector3(0.05, size.y - 0.004, 0) if along_x else Vector3(0, size.y - 0.004, 0.05)) + bar, center, Palette.PAPER)
	box(parent, (Vector3(size.x - 0.004, 0.05, 0) if along_x else Vector3(0, 0.05, size.z - 0.004)) + bar, center, Palette.PAPER)


## An inside window on a wall: frame pieces, a sill, glass set back, and a cross of
## bars. `face_center` is on the wall's room-side face; `into` = which way the room is
## (+1/-1 along the wall's normal axis). The glass shows the sky (main.gd colors it).
static func add_int_window(parent: Node3D, face_center: Vector3, w: float, h: float, along_x: bool, into: float,
		glass_mat: Material) -> void:
	var n := Vector3(0, 0, into) if along_x else Vector3(into, 0, 0)
	var t := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var sz := func(a: float, y: float, d: float) -> Vector3:
		return Vector3(a, y, d) if along_x else Vector3(d, y, a)
	var fw := 0.1
	box_at(parent, sz.call(w + 2 * fw, fw, 0.06), face_center + Vector3(0, h / 2 + fw / 2, 0) + n * 0.03, Palette.CREAM)
	box_at(parent, sz.call(w + 2 * fw + 0.1, fw, 0.1), face_center - Vector3(0, h / 2 + fw / 2, 0) + n * 0.05, Palette.CREAM)
	box_at(parent, sz.call(fw, h, 0.06), face_center + t * (w / 2 + fw / 2) + n * 0.03, Palette.CREAM)
	box_at(parent, sz.call(fw, h, 0.06), face_center - t * (w / 2 + fw / 2) + n * 0.03, Palette.CREAM)
	var glass := box_at(parent, sz.call(w, h, 0.012), face_center + n * 0.02, Color.WHITE)
	glass.material_override = glass_mat
	box_at(parent, sz.call(0.05, h, 0.03), face_center + n * 0.035, Palette.CREAM)
	box_at(parent, sz.call(w, 0.05, 0.03), face_center + n * 0.035, Palette.CREAM)


## A gable roof over a rectangle (ridge along x), resting at height `eave`.
## Roofs are hidden in the House Cam, like ceilings.
## `hide_in_house_cam` = false for neighbors' roofs, which always stay on.
## `ox0`/`ox1`/`oz0`/`oz1` = how far the roof overhangs on the west/east/north/south
## (0 where it meets a taller part of the house).
static func make_roof(root: Node3D, out: Dictionary, r: Rect2, eave: float, pitch: float, color := ROOF,
		hide_in_house_cam := true, ox0 := 0.35, ox1 := 0.35, oz0 := 0.35, oz1 := 0.35) -> Node3D:
	var g := Node3D.new()
	root.add_child(g)
	var x0 := r.position.x - ox0
	var x1 := r.end.x + ox1
	var z0 := r.position.y - oz0
	var z1 := r.end.y + oz1
	var depth := z1 - z0
	var rise := depth / 2.0 * pitch
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(depth, rise, x1 - x0)
	mi.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mi.material_override = mat
	mi.rotation_degrees.y = 90.0
	mi.position = Vector3((x0 + x1) / 2.0, eave + rise / 2.0, (z0 + z1) / 2.0)
	g.add_child(mi)
	# fascia board along the eaves (only where the roof overhangs)
	if oz0 > 0.0:
		box(g, Vector3(x1 - x0, 0.12, 0.06), Vector3((x0 + x1) / 2.0, eave - 0.02, z0 + 0.03), TRIM)
	if oz1 > 0.0:
		box(g, Vector3(x1 - x0, 0.12, 0.06), Vector3((x0 + x1) / 2.0, eave - 0.02, z1 - 0.03), TRIM)
	if hide_in_house_cam:
		(out["ceilings"] as Array).append(g)
	return g
