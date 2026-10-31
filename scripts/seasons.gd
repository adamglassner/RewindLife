class_name Seasons
extends Node3D
## The seasons, from the calendar:
##   WINTER (Dec-Feb)  snow on the ground, frosted trees, snow falling some days,
##                     a snow drift in the front yard (build a snowman, make snow angels)
##   SPRING (Mar-May)  fresh green, and rainy days now and then
##   SUMMER (Jun-Aug)  sprinklers going in some front yards (run through them!)
##   FALL (Sep-Nov)    orange, red and gold leaves, and a leaf pile to jump in
## The weather for each day is picked from the date, so it's the same for
## everyone playing online.

const WINTER := [12, 1, 2]
const SPRING := [3, 4, 5]
const SUMMER := [6, 7, 8]
const FALL := [9, 10, 11]
const FALL_COLORS := [Color("D9822E"), Color("C0402A"), Color("E8B23A"), Color("B8602A"), Color("9A8A30")]

var main: Node
var season := ""
var weather := ""                 # "", "rain", "snow"
var _leaves: Array = []           # [material, its summer color]
var _woods := {}
var _wood_colors: Array = []      # [[multimesh, [colors]], ...]
var _lawns: Array = []            # [material, its texture]
var _snow_tex: ImageTexture
var _precip: CPUParticles3D
var _sprinklers: Array = []       # [{"node", "parts"}]
var _snowman: Node3D
var _drift: SmartObject
var _leaf_piles: Array = []
var _snowman_slot := -1
var _snowman_body: StaticBody3D
var _snowman_rect := Rect2()
var snowman_built := -1           # the year (of the winter) the snowman went up
var _applied := ""


func setup(p_main: Node) -> void:
	main = p_main
	name = "Seasons"
	for mi in get_tree().get_nodes_in_group("leaves"):
		var m: StandardMaterial3D = (mi as MeshInstance3D).material_override
		_leaves.append([m, m.albedo_color])
	for body in get_tree().get_nodes_in_group("lawn"):
		for ch in (body as Node).get_children():
			if ch is MeshInstance3D:
				var m2: StandardMaterial3D = (ch as MeshInstance3D).material_override
				_lawns.append([m2, m2.albedo_texture, m2.albedo_color])
	_woods = main.room.get("woods", {})
	for mmi in _woods.get("crowns", []):
		var mm: MultiMesh = (mmi as MultiMeshInstance3D).multimesh
		var cols := []
		for i in mm.instance_count:
			cols.append(mm.get_instance_color(i))
		_wood_colors.append([mm, cols])
	_snow_tex = _make_snow_tex()
	_build_precip()
	_build_yard_things()


func _make_snow_tex() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for y in 32:
		for x in 32:
			var v := rng.randf_range(0.9, 1.0)
			img.set_pixel(x, y, Color(v * 0.97, v * 0.98, v, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func season_of(month: int) -> String:
	if month in WINTER:
		return "winter"
	if month in SPRING:
		return "spring"
	if month in SUMMER:
		return "summer"
	return "fall"


## Today's weather (the same for everyone: it comes from the date).
static func weather_on(y: int, m: int, d: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = y * 1000 + m * 40 + d
	var r := rng.randf()
	if m in SPRING:
		return "rain" if r < 0.35 else ""
	if m in WINTER:
		return "snow" if r < 0.45 else ""
	if m in FALL:
		return "rain" if r < 0.12 else ""
	return ""


# ================================================================ every hour

func refresh() -> void:
	var c: GameClock = main.clock
	season = season_of(c.month())
	weather = weather_on(c.year(), c.month(), c.day())
	var h := c.hour_float()
	# (it rains or snows from late morning into the evening)
	var falling := weather != "" and h >= 9.0 and h < 21.0
	main.overcast = 1.0 if falling else (0.45 if weather != "" else 0.0)
	_precip.emitting = falling
	_set_precip(weather)
	if season != _applied:
		_applied = season
		_apply_colors()
	var summer_on := season == "summer" and h >= 9.0 and h < 18.0 and weather == ""
	for sp in _sprinklers:
		(sp["node"] as Node3D).visible = season == "summer"
		(sp["water"] as CPUParticles3D).emitting = summer_on
		if summer_on and not main.audio.has_loop(sp["key"]):
			main.audio.start_loop(sp["key"], "sprinkler", (sp["node"] as Node3D).global_position + Vector3(0, 0.5, 0), -14.0, randf())
		elif not summer_on and main.audio.has_loop(sp["key"]):
			main.audio.stop_loop(sp["key"], 0.6)
	if falling and weather == "rain":
		if not main.audio.has_loop("rain"):
			main.audio.start_loop("rain", "rain", _cam_spot(), -10.0)
	elif main.audio.has_loop("rain"):
		main.audio.stop_loop("rain", 1.5)
	# winter: the snow drift; the snowman stays up once it's built (until spring)
	var winter := season == "winter"
	var wy := c.year() if c.month() == 12 else c.year() - 1
	_drift.visible = winter
	_drift.collision_layer = 1 if winter else 0
	_snowman.visible = winter and snowman_built == wy
	_snowman_solid(_snowman.visible)
	for lp: SmartObject in _leaf_piles:
		lp.visible = season == "fall"
		lp.collision_layer = 1 if season == "fall" else 0
	# the chalkboards say Summer School in June, July and August
	for lbl in main.room.get("school_boards", []):
		var l := lbl as Label3D
		if is_instance_valid(l):
			l.text = String(l.get_meta("summer_text" if c.month() in SchoolBuilder.SUMMER else "year_text", l.text))
	if main.env != null:
		main._update_lighting()


func _apply_colors() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for l in _leaves:
		var m: StandardMaterial3D = l[0]
		var base: Color = l[1]
		match season:
			"fall":
				m.albedo_color = FALL_COLORS[rng.randi() % FALL_COLORS.size()].lerp(base, 0.15)
			"winter":
				m.albedo_color = Color("E8ECEE").lerp(base, 0.12)      # bare branches under the snow
			"spring":
				m.albedo_color = base.lightened(0.18)
			_:
				m.albedo_color = base
	for wc in _wood_colors:
		var mm: MultiMesh = wc[0]
		var cols: Array = wc[1]
		var pines: Array = _woods.get("pine", [])
		for i in mm.instance_count:
			var base2: Color = cols[i]
			var pine: bool = i < pines.size() and pines[i]
			var col := base2
			match season:
				"fall":
					col = base2 if pine else FALL_COLORS[(i * 7) % FALL_COLORS.size()].lerp(base2, 0.2)
				"winter":
					col = base2.lerp(Color("F2F4F6"), 0.45 if pine else 0.85)
				"spring":
					col = base2.lightened(0.15) if not pine else base2
			mm.set_instance_color(i, col)
	for lw in _lawns:
		var m3: StandardMaterial3D = lw[0]
		match season:
			"winter":
				m3.albedo_texture = _snow_tex
				m3.albedo_color = Color.WHITE
			"fall":
				m3.albedo_texture = lw[1]
				m3.albedo_color = (lw[2] as Color) * Color(1.0, 0.92, 0.7)
			_:
				m3.albedo_texture = lw[1]
				m3.albedo_color = lw[2]


# ================================================================ rain and snow

func _build_precip() -> void:
	_precip = CPUParticles3D.new()
	_precip.name = "Precipitation"
	_precip.amount = 1400
	_precip.local_coords = false
	_precip.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_precip.emission_box_extents = Vector3(22, 0.5, 22)
	_precip.emitting = false
	add_child(_precip)
	_set_precip("rain")


func _set_precip(kind: String) -> void:
	if _precip.has_meta("kind") and _precip.get_meta("kind") == kind:
		return
	_precip.set_meta("kind", kind)
	var mesh := BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if kind == "snow":
		mesh.size = Vector3(0.07, 0.07, 0.07)
		mat.albedo_color = Color(1, 1, 1, 0.95)
		_precip.lifetime = 6.0
		_precip.gravity = Vector3(0, -1.6, 0)
		_precip.initial_velocity_min = 0.2
		_precip.initial_velocity_max = 0.8
		_precip.direction = Vector3(0.3, -1, 0.1)
		_precip.spread = 40.0
	else:
		mesh.size = Vector3(0.015, 0.45, 0.015)
		mat.albedo_color = Color(0.75, 0.82, 0.95, 0.6)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_precip.lifetime = 0.75
		_precip.gravity = Vector3(0, -20.0, 0)
		_precip.initial_velocity_min = 8.0
		_precip.initial_velocity_max = 10.0
		_precip.direction = Vector3(0.05, -1, 0)
		_precip.spread = 3.0
	mesh.material = mat
	_precip.mesh = mesh


func _cam_spot() -> Vector3:
	var cam: Camera3D = main.rig.cam
	var p: Vector3 = main.rig.target if main.rig.mode == CameraRig.Mode.HOUSE else cam.global_position
	return Vector3(p.x, maxf(0.0, p.y) + 2.0, p.z)


func _process(_delta: float) -> void:
	if main == null or main.rig == null:
		return
	var p := _cam_spot()
	_precip.global_position = p + Vector3(0, 12.0, 0)
	# (no rain indoors, or down in the attics and basements)
	_precip.visible = main._outdoors or main.rig.mode == CameraRig.Mode.HOUSE
	if p.y < RoomBuilder.INTERIOR_Y * 0.5 + 2.0:
		_precip.visible = false
	if main.audio.has_loop("rain"):
		main.audio.move_loop("rain", p)


# ================================================================ in the yards

func _build_yard_things() -> void:
	var objs: Dictionary = main.room["objects"]
	var none: Array[Rect2] = []
	# Sprinklers in a few front yards (summer)
	for home in ["jamie", "garcias", "nguyens", "millers", "brooks"]:
		var porch: SmartObject = objs.get(home + "_porch")
		if porch == null:
			continue
		var out := porch.approach_point - porch.look_point
		out.y = 0.0
		out = out.normalized()
		var side := Vector3(out.z, 0, -out.x)
		var at := Vector3(porch.look_point.x, 0, porch.look_point.z) + out * 5.0 + side * (4.5 if home == "jamie" else 1.5)
		var o := Props.item(self, objs, home + "_sprinkler", "Sprinkler", at, 0)
		o.kind = "sprinkler"
		o.home = home
		o.shared = true
		Props.part(o, Vector3(0.3, 0.06, 0.3), Vector3(0, 0.03, 0), Color("2E8C5A"))
		Props.part(o, Vector3(0.06, 0.16, 0.06), Vector3(0, 0.14, 0), Color("C8CCD0"))
		Props.part(o, Vector3(0.34, 0.04, 0.04), Vector3(0, 0.23, 0), Color("C8CCD0"))
		Props.finish(o, none, Vector3(0.5, 0.4, 0.5), Vector3(0, 0, 1.4), Vector3(0, 0, 0.5), Vector3(0, 0.4, 0))
		var water := CPUParticles3D.new()
		water.amount = 160
		water.lifetime = 1.2
		water.position = Vector3(0, 0.25, 0)
		water.direction = Vector3(0, 1, 0)
		water.spread = 55.0
		water.initial_velocity_min = 3.0
		water.initial_velocity_max = 4.5
		water.gravity = Vector3(0, -9.8, 0)
		water.emitting = false
		var wm := BoxMesh.new()
		wm.size = Vector3(0.04, 0.04, 0.04)
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.75, 0.9, 1.0, 0.75)
		wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wm.material = wmat
		water.mesh = wm
		o.add_child(water)
		var a := Activity.make("Run Through the Sprinkler", 15, {"fun": 60.0, "energy": -6.0}, "dance")
		a.months = SUMMER
		a.from_hour = 9.0
		a.to_hour = 18.0
		a.memory_id = "sprinkler"
		a.messages = ["EEEEEE! It's freezing! Do it again!", "You get completely soaked. That was the plan."]
		o.activities.append(a)
		_sprinklers.append({"node": o, "water": water, "key": "sprinkler_" + home})
	# Jamie's front yard: a snow drift (and the snowman you build from it), and a leaf pile
	var jp: SmartObject = objs.get("jamie_porch")
	var base := Vector3(jp.look_point.x, 0, jp.look_point.z) if jp else Vector3(1.3, 0, 6.6)
	_drift = Props.item(self, objs, "snow_drift", "Snow Drift", base + Vector3(3.0, 0, 4.0), 0)
	_drift.kind = "snow_drift"
	_drift.home = "jamie"
	_drift.shared = true
	Props.part(_drift, Vector3(1.6, 0.35, 1.2), Vector3(0, 0.175, 0), Color("F2F4F6"))
	Props.part(_drift, Vector3(1.0, 0.25, 0.8), Vector3(0.2, 0.42, 0.05), Color("E8ECEE"))
	Props.finish(_drift, none, Vector3(1.6, 0.6, 1.2), Vector3(0, 0, 1.2), null, Vector3(0, 0.3, 0))
	var b := Activity.make("Build a Snowman", 40, {"fun": 60.0, "energy": -10.0, "social": 10.0}, "reach")
	b.months = WINTER
	b.memory_id = "snowman"
	b.messages = ["Roll, roll, roll... the bottom ball is as big as you are!", "A carrot nose, two buttons, Dad's old scarf. Perfect."]
	_drift.activities.append(b)
	var sa := Activity.make("Make Snow Angels", 15, {"fun": 40.0}, "lie")
	sa.surface = 0.05
	sa.months = WINTER
	sa.messages = ["Flap, flap, flap. Your snow angel is the best one on the block."]
	_drift.activities.append(sa)
	var sb := Activity.make("Have a Snowball Fight", 20, {"fun": 54.0, "social": 20.0, "energy": -8.0}, "reach")
	sb.months = WINTER
	sb.messages = ["You get one right down the back of your coat. WAR.", "Direct hit! You run before they can reload."]
	_drift.activities.append(sb)
	_snowman = Node3D.new()
	_snowman.position = base + Vector3(4.6, 0, 3.4)
	add_child(_snowman)
	RoomBuilder.box(_snowman, Vector3(0.8, 0.7, 0.8), Vector3(0, 0.35, 0), Color("F4F6F8"))
	RoomBuilder.box(_snowman, Vector3(0.58, 0.52, 0.58), Vector3(0, 0.95, 0), Color("F4F6F8"))
	RoomBuilder.box(_snowman, Vector3(0.4, 0.38, 0.4), Vector3(0, 1.4, 0), Color("F4F6F8"))
	RoomBuilder.box(_snowman, Vector3(0.06, 0.06, 0.2), Vector3(0, 1.42, 0.28), Color("E4782E"))     # carrot
	RoomBuilder.box(_snowman, Vector3(0.46, 0.1, 0.46), Vector3(0, 1.17, 0), Color("C0322A"))         # scarf
	for sx in [-0.09, 0.09]:
		RoomBuilder.box(_snowman, Vector3(0.05, 0.05, 0.02), Vector3(sx, 1.5, 0.205), Palette.INK)
	_snowman.visible = false
	# (its footprint only blocks the way while it's up, so nobody walks through it)
	var sl: Array = main.room["grid_lists"][4]
	sl.append(Rect2())
	_snowman_slot = sl.size() - 1
	_snowman_rect = Rect2(_snowman.position.x - 0.45, _snowman.position.z - 0.45, 0.9, 0.9)
	_snowman_body = StaticBody3D.new()     # (and in first person)
	_snowman_body.collision_layer = 0
	_snowman_body.collision_mask = 0
	_snowman.add_child(_snowman_body)
	RoomBuilder.add_shape(_snowman_body, Vector3(0.8, 1.6, 0.8), Vector3(0, 0.8, 0))
	var lp := Props.item(self, objs, "leaf_pile", "Leaf Pile", base + Vector3(6.2, 0, 5.2), 0)
	lp.kind = "leaf_pile"
	lp.home = "jamie"
	lp.shared = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 9:
		Props.part(lp, Vector3(rng.randf_range(0.4, 0.7), rng.randf_range(0.15, 0.35), rng.randf_range(0.4, 0.7)),
			Vector3(rng.randf_range(-0.45, 0.45), 0.12 + k * 0.012, rng.randf_range(-0.45, 0.45)), FALL_COLORS[k % FALL_COLORS.size()], null, false)
	Props.finish(lp, none, Vector3(1.4, 0.5, 1.4), Vector3(0, 0, 1.2), Vector3(0, 0, 0.0), Vector3(0, 0.3, 0))
	var j := Activity.make("Jump in the Leaf Pile", 10, {"fun": 56.0}, "lie")
	j.surface = 0.2
	j.months = FALL
	j.memory_id = "leafpile"
	j.messages = ["CRUNCH! Leaves in your hair, your shirt, your shoes...", "You disappear completely. Nobody can find you. Perfect."]
	lp.activities.append(j)
	var r := Activity.make("Rake the Leaves", 30, {"fun": -6.0, "energy": -8.0}, "reach")
	r.months = FALL
	r.chore = "rake"
	r.autonomous = false
	lp.activities.append(r)
	_leaf_piles.append(lp)


## (main.gd) Somebody finished building the snowman.
func built_snowman() -> void:
	var c: GameClock = main.clock
	snowman_built = c.year() if c.month() == 12 else c.year() - 1
	_snowman.visible = true
	_snowman_solid(true)


func _snowman_solid(on: bool) -> void:
	if _snowman_slot < 0:
		return
	var sl: Array = main.room["grid_lists"][4]
	_snowman_body.collision_layer = 2 if on else 0
	var want := _snowman_rect if on else Rect2()
	if sl[_snowman_slot] != want:
		sl[_snowman_slot] = want
		main.rebuild_grid()
