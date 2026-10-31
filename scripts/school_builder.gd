class_name SchoolBuilder
extends RefCounted
## v1.7: school's in session.
##   - Maple Grove Elementary gets a new wing out back: a second classroom, the library
##     and the music room (doors through from the classroom, the art room and the gym).
##   - Lincoln Avenue now runs all the way to the east edge of town, past the football
##     field to two new schools on the north side:
##       Maple Grove Middle School (homeroom, science lab, band room)
##       Maple Grove High School, two stories: downstairs the cafeteria, the chemistry lab
##       and a classroom; upstairs (the stairs at the end of the hall) typing class, the
##       computer lab and the library.
## Classes run September through May, Monday to Friday; in June, July and August it's
## summer school instead (at the elementary and the high school; the middle school
## closes for the summer). The teachers and students come and go with the school year.
##
## The high school's upstairs is built like the attics: on the underground level
## (RoomBuilder.INTERIOR_Y), with the stairs as the doors between the two.

const T := 0.15
const SCHOOL_YEAR := [1, 2, 3, 4, 5, 9, 10, 11, 12]
const SUMMER := [6, 7, 8]
const CLASS_HOURS := Vector2(8.0, 15.0)
const SUMMER_HOURS := Vector2(9.0, 12.0)

const WING := Rect2(7.0, -68.0, 27.0, 10.0)            # behind the elementary school
const MIDDLE := Rect2(86.0, -60.0, 22.0, 21.5)
const HIGH := Rect2(110.0, -62.0, 24.0, 23.5)
const HIGH_UP := Rect2(110.0, -63.5, 24.0, 20.0)      # the upstairs (on the underground level)
const HALL_D := 4.0                                    # the front hallway's depth (middle and high school)
const HIGH_H := 8.4                                    # two stories, from the outside


static func rects() -> Array[Rect2]:
	return [MIDDLE, HIGH]


## A school-day class at a desk.
static func class_act(o: SmartObject, title: String, months: Array, hours: Vector2, days: Array, mins: int,
		fx: Dictionary, msgs: Array, memory := "") -> Activity:
	var a := Activity.make(title, mins, fx, "sit")
	a.months = months
	a.from_hour = hours.x
	a.to_hour = hours.y
	a.weekdays = days
	a.autonomous = false
	a.messages = msgs
	a.memory_id = memory
	o.activities.append(a)
	return a


static func build(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2],
		doorways: Array[Rect2], buildings: Array[Rect2]) -> void:
	var c := {"root": root, "out": out, "tex": tex, "solids": solids, "free": free, "doorways": doorways,
		"buildings": buildings, "objects": out["objects"], "home": "town", "level": 0}
	_lincoln_east(c)
	_wing(c)
	_middle(c)
	_high(c)
	DowntownBuilder._register_door(out, "middle_school", "Maple Grove Middle School", MIDDLE, Vector2(7.5, 16.5), [1, 2, 3, 4, 5])
	DowntownBuilder._register_door(out, "high_school", "Maple Grove High School", HIGH, Vector2(7.5, 16.5), [1, 2, 3, 4, 5])


# ================================================================ Lincoln Avenue, east of the field

static func _lincoln_east(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var out: Dictionary = c["out"]
	var z0 := CivicBuilder.Z0
	var z1 := CivicBuilder.Z1
	var x0 := 86.0
	var x1 := OutdoorBuilder.EAST_END
	var concrete := Color("CFC8BA")
	OutdoorBuilder._slab(root, Rect2(x0, z0 + 0.15, x1 - x0, z1 - z0 - 0.3), Color("4A4950"), tex["asphalt"], -0.015)
	var x := x0 + 2.0
	while x + 2.0 <= x1:
		OutdoorBuilder._slab(root, Rect2(x, (z0 + z1) / 2.0 - 0.06, 2.0, 0.12), Color("E8C24A"), null, -0.008)
		x += 4.0
	for z in [z0, z1 - 0.15]:
		RoomBuilder.box(root, Vector3(x1 - x0, 0.12, 0.15), Vector3((x0 + x1) / 2.0, 0.04, z + 0.075), Color("B9B2A5"))
	OutdoorBuilder._slab(root, Rect2(x0, z0 - 1.6, x1 - x0, 1.6), concrete, tex["concrete"], 0.004)
	OutdoorBuilder._slab(root, Rect2(x0, z1, x1 - x0, 1.6), concrete, tex["concrete"], 0.004)
	for lx in [94.0, 114.0, 130.0]:
		OutdoorBuilder._streetlight(root, solids, out, Vector3(lx, 0, z0 - 1.3), 1.0)
	for lx in [102.0, 122.0]:
		OutdoorBuilder._streetlight(root, solids, out, Vector3(lx, 0, z1 + 1.3), -1.0)
	OutdoorBuilder._sign(root, solids, Vector3(84.6, 0, z0 - 0.6), "SCHOOL\nZONE", Color("F2C230"), Palette.INK, Vector2(0.6, 0.6), 180.0)
	# A crosswalk between the two new schools
	for cx in [108.0, 109.0, 110.0]:
		OutdoorBuilder._slab(root, Rect2(cx - 0.3, z0, 0.6, z1 - z0), Palette.PAPER, null, -0.006)


# ================================================================ the elementary school's new wing

static func _wing(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var solids: Array[Rect2] = c["solids"]
	var out: Dictionary = c["out"]
	var r := WING
	var hgt := 4.0
	var wall := Color("F2E8C8")
	RoomBuilder.make_floor(root, Rect2(r.position.x, r.position.y, 9.0, r.size.y), Color("C8B08A"), tex["lino"])
	RoomBuilder.make_floor(root, Rect2(r.position.x + 9.0, r.position.y, 9.0, r.size.y), Color("8A6A4A"), tex["panel"])
	RoomBuilder.make_floor(root, Rect2(r.position.x + 18.0, r.position.y, 9.0, r.size.y), Color("B88A6A"), tex["panel"])
	RoomBuilder.make_ceiling(root, out, r.grow(-T / 2.0), hgt)
	(c["buildings"] as Array).append(r)
	var nw := RoomBuilder.make_wall(root, "wingN", Vector3(r.get_center().x, 0, r.position.y), Vector3(r.size.x + T, hgt, T), Vector3(0, 0, -1),
		tex, [], false, wall, "panel")
	var lw := RoomBuilder.make_wall(root, "wingW", Vector3(r.position.x, 0, r.get_center().y), Vector3(T, hgt, r.size.y - T), Vector3(-1, 0, 0),
		tex, [], false, wall, "panel")
	var rw := RoomBuilder.make_wall(root, "wingE", Vector3(r.end.x, 0, r.get_center().y), Vector3(T, hgt, r.size.y - T), Vector3(1, 0, 0),
		tex, [], false, wall, "panel")
	RoomBuilder.add_siding(nw, -1.0, hgt, tex, -INF, INF, true, true, Color("B5654A"), "brick")
	RoomBuilder.add_siding(lw, -1.0, hgt, tex, -INF, INF, true, true, Color("B5654A"), "brick")
	RoomBuilder.add_siding(rw, 1.0, hgt, tex, -INF, INF, true, true, Color("B5654A"), "brick")
	for w in [nw, lw, rw]:
		(out["walls"] as Array).append(w)
	var roof := RoomBuilder.box(root, Vector3(r.size.x + 0.4, 0.22, r.size.y + 0.2), Vector3(r.get_center().x, hgt + 0.11, r.get_center().y - 0.1), Color("5A5550"))
	(out["ceilings"] as Array).append(roof)
	CivicBuilder._windows(c, nw, [r.position.x + 4.5, r.position.x + 13.5, r.position.x + 22.5], 1.6, 1.6, 1.3, r.position.y, -1.0)
	var xa := r.position.x + 9.0
	var xb := r.position.x + 18.0
	CivicBuilder._partition(c, "wingA", false, xa, r.position.y + T / 2.0, r.end.y - T / 2.0, [], hgt, wall)
	CivicBuilder._partition(c, "wingB", false, xb, r.position.y + T / 2.0, r.end.y - T / 2.0, [], hgt, Color("E8D8B8"))
	CivicBuilder._room(c, "Classroom 2", Rect2(r.position.x, r.position.y, 9.0, r.size.y))
	CivicBuilder._room(c, "School Library", Rect2(xa, r.position.y, 9.0, r.size.y))
	CivicBuilder._room(c, "Music Room", Rect2(xb, r.position.y, 9.0, r.size.y))
	# ---- Classroom 2: Mr. Pemberton's 5th grade
	_classroom(c, "elem2", Rect2(r.position.x, r.position.y, 9.0, r.size.y), -1.0, "Long Division\nTest FRIDAY!", "elementary",
		"Mr. Pemberton", {"gender": "boy", "hair": "curtains", "hair_color": 2, "skin": 0, "adult": true, "top_style": "plain",
		"top": Color("8A6A4A"), "pants": Color("4A4038"), "shoes": Palette.INK},
		["Who can tell me the capital of Nebraska? ...Anyone? It's Lincoln. Like the street!", "Eyes on your own paper, please.",
		"Pencils down! Time's up."], CivicBuilder.SCHOOL, "school", 3)
	# ---- the library: shelves, a reading rug, the librarian's desk
	for k in 3:
		var sh := CivicBuilder._usable(c, "elem_bookshelf_%d" % (k + 1), "Library Shelf", "library_shelf", Vector3(xa + 1.6 + k * 2.9, 0, r.position.y + T / 2.0 + 0.25), 0)
		Props.part(sh, Vector3(2.4, 2.0, 0.45), Vector3(0, 1.0, 0), Palette.WOOD_DARK)
		for row in 4:
			for bk in 8:
				Props.part(sh, Vector3(0.22, 0.32, 0.3), Vector3(-1.0 + bk * 0.28, 0.3 + row * 0.46, 0.08),
					[Color("C0322A"), Color("2E5E9E"), Color("F7D046"), Color("4F9A3A"), Color("7A4FB0")][(bk + row * 3 + k) % 5], null, false)
		Props.finish(sh, solids, Vector3(2.4, 2.0, 0.45), Vector3(0, 0, 0.9), null, Vector3(0, 1.2, 0))
		_act(sh, "Check Out a Library Book", 10, {"fun": 20.0}, "reach",
			["A mystery with a spooky lighthouse on the cover. Perfect.", "A book about dinosaurs. The good kind of dinosaur book."], CLASS_HOURS)
		_act(sh, "Read in the Library", 30, {"fun": 26.0, "energy": 6.0}, "read",
			["Shhh! You read three whole chapters.", "You get so into the book that you miss the bell."], Vector2(8.0, 16.5))
	var rug := Props.solid(root, Vector3(xa + 4.5, 0, r.end.y - 3.0), 0)
	RoomBuilder.box(rug, Vector3(3.0, 0.02, 2.0), Vector3(0, 0.012, 0), Color("4FB0E0"))
	(rug as StaticBody3D).collision_layer = 0
	Props.light(root, out, Vector3(xa + 4.5, hgt - 0.5, r.get_center().y), Color("F2F4FF"), 8.0, 0.9, 1.6, null, false)
	# ---- the music room: chairs in a half circle, a piano, a xylophone
	var piano := CivicBuilder._usable(c, "elem_piano", "Piano", "piano", Vector3(xb + 1.6, 0, r.position.y + 1.2), 0)
	Props.part(piano, Vector3(1.5, 1.2, 0.6), Vector3(0, 0.6, 0), Color("2B2020"))
	Props.part(piano, Vector3(1.4, 0.06, 0.24), Vector3(0, 0.78, 0.4), Palette.PAPER, null, false)
	Props.finish(piano, solids, Vector3(1.5, 1.2, 0.85), Vector3(0, 0, 1.0), null, Vector3(0, 0.9, 0))
	_act(piano, "Play the Piano", 20, {"fun": 34.0}, "sit", ["Chopsticks! The only song anybody knows.", "You play the opening of a famous song. Badly. Proudly."],
		Vector2(8.0, 16.5)).sound = "piano"
	var xylo := CivicBuilder._usable(c, "elem_xylophone", "Xylophone", "xylophone", Vector3(xb + 6.0, 0, r.position.y + 2.2), 0)
	Props.part(xylo, Vector3(1.0, 0.7, 0.4), Vector3(0, 0.35, 0), Palette.WOOD)
	for k in 8:
		Props.part(xylo, Vector3(0.09, 0.03, 0.3 - k * 0.02), Vector3(-0.42 + k * 0.12, 0.72, 0), [Color("C0322A"), Color("E4782E"), Color("F7D046"), Color("4F9A3A"), Color("2E8C8A"), Color("2E5E9E"), Color("7A4FB0"), Color("E85A7A")][k], null, false)
	Props.finish(xylo, solids, Vector3(1.0, 0.75, 0.4), Vector3(0, 0, 0.8), null, Vector3(0, 0.8, 0))
	_act(xylo, "Play the Xylophone", 10, {"fun": 30.0}, "reach", ["Bonk, bink, BONK. Music!"], Vector2(8.0, 16.5)).sound = "xylophone"
	for k in 5:
		var a := -0.9 + k * 0.45
		var ch := Props.solid(root, Vector3(xb + 4.5 + sin(a) * 2.6, 0, r.end.y - 2.2 - cos(a) * 1.4), rad_to_deg(a) + 180.0)
		RoomBuilder.box(ch, Vector3(0.42, 0.45, 0.42), Vector3(0, 0.225, 0), [Color("C0322A"), Color("2E5E9E"), Color("F7D046")][k % 3])
		RoomBuilder.box(ch, Vector3(0.42, 0.42, 0.06), Vector3(0, 0.66, 0.18), [Color("C0322A"), Color("2E5E9E"), Color("F7D046")][k % 3])
		Props.finish(ch, solids, Vector3(0.42, 0.9, 0.48), Vector3.ZERO)
	Props.light(root, out, Vector3(xb + 4.5, hgt - 0.5, r.get_center().y), Color("F2F4FF"), 8.0, 0.9, 1.6, null, false)
	CivicBuilder._staff(c, "music_teacher", "Ms. Lindqvist", Vector3(xb + 2.8, 0, r.position.y + 1.2), 0.0,
		{"gender": "girl", "hair": "layered", "hair_color": 0, "skin": 0, "adult": true, "top_style": "plain",
		"top": Color("2E8C8A"), "pants": Color("2B3A44"), "shoes": Palette.INK}, 1.2, Vector2(8.0, 15.0), [1, 2, 3, 4, 5],
		["Recorders out! From the top. ...From the TOP.", "Music is math you can hear!", "Somebody's been playing Chopsticks on my piano again."], "school")
	(out["staff"] as Array).back()["months"] = SCHOOL_YEAR


# ================================================================ a classroom (any of the schools)

## Desks in rows facing a chalkboard on the `board_side` wall (-1 = north, +1 = south), a teacher,
## and (during the school year) a few students. One desk is yours.
static func _classroom(c: Dictionary, key: String, r: Rect2, board_side: float, board_text: String, level_name: String,
		teacher: String, look: Dictionary, lines: Array, bld: Rect2, work: String, rows := 3, summer := false) -> SmartObject:
	var root: Node3D = c["root"]
	var solids: Array[Rect2] = c["solids"]
	# (9 cm out from the wall: clear of the window trim, which stands out from the wall a little)
	var bz := (r.position.y + T / 2.0 + 0.09) if board_side < 0 else (r.end.y - T / 2.0 - 0.09)
	var face := 0.0 if board_side < 0 else 180.0
	var chalk := CivicBuilder._usable(c, key + "_chalkboard", "Chalkboard", "chalkboard", Vector3(r.get_center().x, 0, bz), face)
	Props.part(chalk, Vector3(3.6, 1.3, 0.05), Vector3(0, 1.6, 0), Color("2E4A3A"))
	Props.part(chalk, Vector3(3.8, 0.08, 0.12), Vector3(0, 0.92, 0.04), Palette.WOOD, null, false)
	var lbl := CivicBuilder._label(chalk, board_text, Vector3(-0.6, 1.75, 0.03), 0.0, Color("E8E8E0"), 0.0035, 48)
	if summer:
		lbl.set_meta("summer_text", "Summer School\n" + board_text.get_slice("\n", 0))
		lbl.set_meta("year_text", board_text)
		if not c["out"].has("school_boards"):
			c["out"]["school_boards"] = []
		(c["out"]["school_boards"] as Array).append(lbl)
	Props.finish(chalk, solids, Vector3(3.6, 1.3, 0.1), Vector3(0, 0, 1.0), null, Vector3(0, 1.6, 0), Vector3(0, 1.6, 0))
	(solids as Array).pop_back()
	_act(chalk, "Doodle on the Chalkboard", 15, {"fun": 30.0}, "reach",
		["You draw a robot. Its name is Gary.", "You write NO HOMEWORK TONIGHT. Nobody believes you."])
	var into := -board_side          # (the desks face the board: rows go away from it)
	var front := bz + into * 2.6
	var td := Props.solid(root, Vector3(r.position.x + 1.6, 0, bz + into * 1.3), face + 180.0)
	RoomBuilder.box(td, Vector3(1.4, 0.76, 0.7), Vector3(0, 0.38, 0), Palette.WOOD)
	RoomBuilder.box(td, Vector3(0.18, 0.2, 0.18), Vector3(0.4, 0.86, 0), Color("C0322A"))
	Props.finish(td, solids, Vector3(1.4, 0.9, 0.7), Vector3.ZERO)
	var mine: SmartObject = null
	var cols := 3
	var x0 := r.get_center().x - 2.2
	var n := 0
	for row in rows:
		for col in cols:
			var p := Vector3(x0 + col * 2.2, 0, front + into * (0.9 + row * 1.9))
			if row == rows - 1 and col == 2:
				mine = CivicBuilder._usable(c, key + "_desk", "Student Desk", "class_desk", p, face + 180.0)
				Props.part(mine, Vector3(0.7, 0.05, 0.5), Vector3(0, 0.7, 0), Color("C8A070"))
				Props.part(mine, Vector3(0.06, 0.68, 0.06), Vector3(0, 0.34, 0), Palette.MUTED, null, false)
				Props.part(mine, Vector3(0.45, 0.45, 0.42), Vector3(0, 0.225, -0.5), Color("2E5E9E"), null, false)
				Props.finish(mine, solids, Vector3(0.7, 0.75, 0.5), Vector3(0, 0, -1.1), Vector3(0, 0, -0.5), Vector3(0, 0.8, 4.0))
				mine.set_meta("school", level_name)
			else:
				var d := Props.solid(root, p, face + 180.0)
				RoomBuilder.box(d, Vector3(0.7, 0.05, 0.5), Vector3(0, 0.7, 0), Color("C8A070"))
				RoomBuilder.box(d, Vector3(0.06, 0.68, 0.06), Vector3(0, 0.34, 0), Palette.MUTED)
				RoomBuilder.box(d, Vector3(0.45, 0.45, 0.42), Vector3(0, 0.225, -0.5), [Color("2E5E9E"), Color("C0322A"), Color("2E8C8A")][n % 3])
				Props.finish(d, solids, Vector3(0.7, 0.75, 1.0), Vector3.ZERO, null, null, Vector3(0, 0.375, -0.25))
				# a classmate at about half the desks (during the school year)
				if (row + col) % 2 == 0 and n < 6:
					_student(c, "%s_student_%d" % [key, n], d.to_global(Vector3(0, 0, -0.5)), face, level_name, bld, work)
			n += 1
	CivicBuilder._staff(c, key + "_teacher", teacher, Vector3(r.position.x + 1.6 + 1.2, 0, bz + into * 1.0), face, look, 1.2,
		CLASS_HOURS, [1, 2, 3, 4, 5], lines, work)
	var st: Dictionary = (c["out"]["staff"] as Array).back()
	if not summer:
		st["months"] = SCHOOL_YEAR
	if work != "school":
		st["door"] = Vector3(bld.get_center().x if work == "middle_school" else bld.position.x + 6.0, 0, bld.end.y + 0.9)
		st["edge"] = TownFolk.EDGES[2]
		st["lock"] = work
	Props.light(root, c["out"], Vector3(r.get_center().x, 3.5, r.get_center().y), Color("F2F4FF"), 9.0, 0.9, 1.6, null, false)
	return mine


## A classmate: at a desk during class (September to May), gone otherwise.
static func _student(c: Dictionary, id: String, seat: Vector3, face: float, level_name: String, bld: Rect2, work: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var girl := rng.randf() < 0.5
	var teen := level_name == "high"
	var look := {"gender": "girl" if girl else "boy", "hair": (["scrunchie", "layered", "feathered", "side_pony"] if girl else ["buzz", "spiky", "curtains", "mullet"])[rng.randi() % 4],
		"hair_color": rng.randi() % 5, "skin": rng.randi() % 4, "kid": not teen, "adult": teen,
		"top": Color.from_hsv(rng.randf(), 0.55, 0.85), "pants": [Color("2E4A7A"), Color("3B3A50"), Color("6A5A4A")][rng.randi() % 3]}
	var names := ["Kevin", "Tracy", "Brian", "Melissa", "Scott", "Heather", "Jason", "Amy", "Chris", "Stacy", "Eric", "Nicole", "Josh", "Kelly"]
	var nm: String = names[rng.randi() % names.size()]
	var lines := ["Psst! Did you do the homework?", "Can I borrow a pencil? Mine broke. Again.", "Only " + str(rng.randi_range(2, 5)) + " more hours till the bell.",
		"I'm gonna be an astronaut. Or a ninja. Still deciding."]
	CivicBuilder._staff(c, id, nm, seat, face, look, 0.9, CLASS_HOURS, [1, 2, 3, 4, 5], lines, work)
	var st: Dictionary = (c["out"]["staff"] as Array).back()
	st["months"] = SCHOOL_YEAR
	st["seated"] = true
	st["stay"] = true
	st["kind"] = "npc_student"


static func _act(o: SmartObject, title: String, mins: int, fx: Dictionary, pose := "stand", msgs: Array = [],
		hours := Vector2(7.5, 16.5)) -> Activity:
	var a := Activity.make(title, mins, fx, pose)
	a.messages = msgs
	a.from_hour = hours.x
	a.to_hour = hours.y
	o.activities.append(a)
	return a


## The front hallway every school has: lockers, a water fountain, a trophy case.
static func _hallway_things(c: Dictionary, key: String, r: Rect2, hz: float, locker_color: Color) -> void:
	var solids: Array[Rect2] = c["solids"]
	# (between the classroom doors: one at the middle of each room)
	var lk := CivicBuilder._usable(c, key + "_lockers", "Lockers", "lockers", Vector3(r.position.x + r.size.x / 3.0, 0, hz + T / 2.0 + 0.25), 0)
	for i in 10:
		Props.part(lk, Vector3(0.38, 1.8, 0.45), Vector3(-1.9 + i * 0.4 + 0.2, 0.9, 0), [locker_color, locker_color.lightened(0.12)][i % 2])
		Props.part(lk, Vector3(0.2, 0.03, 0.01), Vector3(-1.9 + i * 0.4 + 0.2, 1.55, 0.23), Palette.INK2, null, false)
	Props.finish(lk, solids, Vector3(4.0, 1.8, 0.45), Vector3(0, 0, 0.85), null, Vector3(0, 1.3, 0))
	var ftn := CivicBuilder._usable(c, key + "_fountain", "Water Fountain", "fountain", Vector3(r.position.x + r.size.x * 2.0 / 3.0, 0, hz + T / 2.0 + 0.2), 0)
	Props.part(ftn, Vector3(0.5, 0.9, 0.35), Vector3(0, 0.45, 0), Color("C8CCD0"))
	Props.finish(ftn, solids, Vector3(0.5, 0.9, 0.35), Vector3(0, 0, 0.7), null, Vector3(0, 0.9, 0))


# ================================================================ Maple Grove Middle School

static func _middle(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var solids: Array[Rect2] = c["solids"]
	var out: Dictionary = c["out"]
	var r := MIDDLE
	var hgt := 4.0
	var hz := r.end.y - HALL_D
	var wall := Color("E8E0D0")
	var b := CivicBuilder._building(c, "middle", "Middle School Hallway", Rect2(r.position.x, hz, r.size.x, HALL_D), hgt, 1.0, r.get_center().x,
		wall, "panel", Color("8A5A4A"), "brick", Color("C8C0A8"), "lino", [], true, Color("7A2E2E"))
	# (the building is the whole rect: the hallway's back wall becomes the inside wall, the rooms go behind it)
	var back_r := Rect2(r.position.x, r.position.y, r.size.x, hz - r.position.y)
	_back_rooms(c, "middle", r, back_r, hz, hgt, b, wall, Color("8A5A4A"), [Color("B8A888"), Color("C8C8C0"), Color("A87858")])
	var w3 := r.size.x / 3.0
	CivicBuilder._room(c, "Middle School Hallway", Rect2(r.position.x, hz, r.size.x, HALL_D))
	CivicBuilder._room(c, "Homeroom", Rect2(r.position.x, r.position.y, w3, back_r.size.y))
	CivicBuilder._room(c, "Science Lab", Rect2(r.position.x + w3, r.position.y, w3, back_r.size.y))
	CivicBuilder._room(c, "Band Room", Rect2(r.position.x + 2.0 * w3, r.position.y, w3, back_r.size.y))
	CivicBuilder._sign(c, b["front"], r.get_center().x, 3.45, b["fz"], 1.0, "MAPLE GROVE MIDDLE SCHOOL", Color("7A2E2E"), Palette.PAPER, 9.0)
	CivicBuilder._windows(c, b["front"], [r.position.x + 3.0, r.position.x + 7.0, r.end.x - 7.0, r.end.x - 3.0], 1.6, 1.6, 1.3, b["fz"], 1.0)
	_hallway_things(c, "middle", r, hz, Color("7A2E2E"))
	# ---- homeroom
	var desk := _classroom(c, "middle_home", Rect2(r.position.x, r.position.y, w3, back_r.size.y), -1.0, "Pre-Algebra\n3x + 2 = 11", "middle",
		"Mr. Dobbs", {"gender": "boy", "hair": "curtains", "hair_color": 1, "skin": 2, "adult": true, "top_style": "vest",
		"top": Color("C8B890"), "pants": Color("4A4038"), "shoes": Palette.INK},
		["Solve for x. No, x doesn't stand for 'xcuse me, I forgot.'", "Gum. Out. Now.", "Who threw that? Nobody? Nobody threw it. Okay."],
		r, "middle_school", 3)
	class_act(desk, "Go to Class (Middle School)", SCHOOL_YEAR, CLASS_HOURS, [1, 2, 3, 4, 5], 120,
		{"fun": -6.0, "social": 40.0, "energy": -6.0},
		["Pre-algebra. The letters are getting into the numbers now.", "A pop quiz! You know... most of it.", "You pass a note. It gets intercepted. Mortifying."], "middle_school")
	# ---- the science lab: lab tables with Bunsen burners, a skeleton, a model volcano
	var lx := r.position.x + w3
	for k in 2:
		var lt := CivicBuilder._usable(c, "middle_lab_%d" % (k + 1), "Lab Table", "lab_table", Vector3(lx + w3 / 2.0, 0, r.position.y + 4.5 + k * 4.5), 0)
		Props.part(lt, Vector3(2.6, 0.9, 1.0), Vector3(0, 0.45, 0), Color("2B2B30"))
		Props.part(lt, Vector3(2.62, 0.04, 1.02), Vector3(0, 0.92, 0), Color("1A1A1E"))
		Props.part(lt, Vector3(0.12, 0.2, 0.12), Vector3(-0.8, 1.04, 0), Color("4A8AC8"), null, false)
		Props.part(lt, Vector3(0.14, 0.24, 0.14), Vector3(0.6, 1.06, 0.1), Color("7AE07A"), null, false)
		Props.finish(lt, solids, Vector3(2.6, 0.95, 1.0), Vector3(0, 0, 1.0), null, Vector3(0, 1.0, 0))
		var e := class_act(lt, "Do a Science Experiment", SCHOOL_YEAR, CLASS_HOURS, [1, 2, 3, 4, 5], 45, {"fun": 34.0, "social": 10.0},
			["Baking soda + vinegar = VOLCANO. Science is the best.", "You grow a crystal. It's tiny. You love it.", "Safety goggles on! You look like a bug."])
		e.pose = "reach"
	var vol := Props.solid(root, Vector3(lx + w3 - 1.2, 0, r.position.y + 1.2), 0)
	RoomBuilder.box(vol, Vector3(0.9, 0.75, 0.6), Vector3(0, 0.375, 0), Palette.WOOD)
	RoomBuilder.box(vol, Vector3(0.6, 0.35, 0.5), Vector3(0, 0.92, 0), Color("7A5A3A"))
	RoomBuilder.box(vol, Vector3(0.2, 0.06, 0.2), Vector3(0, 1.12, 0), Color("E4572E"))
	Props.finish(vol, solids, Vector3(0.9, 1.2, 0.6), Vector3.ZERO)
	var skel := Props.solid(root, Vector3(lx + 1.0, 0, r.position.y + 1.0), 30)
	RoomBuilder.box(skel, Vector3(0.08, 1.7, 0.08), Vector3(0, 0.85, 0), Palette.MUTED)
	RoomBuilder.box(skel, Vector3(0.36, 0.5, 0.12), Vector3(0, 1.25, 0), Color("F2EEE2"))
	RoomBuilder.box(skel, Vector3(0.24, 0.26, 0.24), Vector3(0, 1.72, 0), Color("F2EEE2"))
	Props.finish(skel, solids, Vector3(0.4, 1.9, 0.4), Vector3.ZERO)
	CivicBuilder._staff(c, "science_teacher", "Ms. Okafor", Vector3(lx + w3 / 2.0, 0, r.position.y + 1.6), 0.0,
		{"gender": "girl", "hair": "feathered", "hair_color": 0, "skin": 3, "adult": true, "top_style": "coat",
		"top": Color("F2F2EE"), "pants": Color("2E3A4A"), "shoes": Palette.INK}, 1.2, CLASS_HOURS, [1, 2, 3, 4, 5],
		["Goggles ON, people!", "A hypothesis is just a guess wearing a lab coat.", "Do NOT lick the crystals."], "middle_school")
	var st: Dictionary = (out["staff"] as Array).back()
	st["months"] = SCHOOL_YEAR
	st["door"] = Vector3(r.get_center().x, 0, r.end.y + 0.9)
	st["edge"] = TownFolk.EDGES[2]
	st["lock"] = "middle_school"
	# ---- the band room: music stands, a drum set, chairs
	var bx := r.position.x + 2.0 * w3
	var drums := CivicBuilder._usable(c, "middle_drums", "Drum Set", "drums", Vector3(bx + w3 / 2.0, 0, r.position.y + 1.6), 0)
	Props.part(drums, Vector3(0.6, 0.45, 0.6), Vector3(0, 0.3, 0), Color("C0322A"))
	for dx in [-0.55, 0.55]:
		Props.part(drums, Vector3(0.36, 0.25, 0.36), Vector3(dx, 0.62, 0.1), Color("C0322A"), null, false)
		Props.part(drums, Vector3(0.04, 0.9, 0.04), Vector3(dx * 1.4, 0.45, -0.2), Palette.MUTED, null, false)
		Props.part(drums, Vector3(0.4, 0.02, 0.4), Vector3(dx * 1.4, 0.92, -0.2), Palette.GOLD, null, false)
	Props.finish(drums, solids, Vector3(1.6, 1.0, 0.8), Vector3(0, 0, 1.0), null, Vector3(0, 0.8, 0))
	var bd := class_act(drums, "Play in the Band", SCHOOL_YEAR, CLASS_HOURS, [1, 2, 3, 4, 5], 40, {"fun": 40.0, "social": 24.0},
		["Ba-dum-TSS! The band teacher says you've got rhythm.", "You play the school song. Mostly in the right key."], "band")
	bd.pose = "dance"
	bd.loop_sound = "band"
	bd.loop_db = -6.0
	for k in 6:
		var ms := Props.solid(root, Vector3(bx + 1.2 + (k % 3) * 2.2, 0, r.position.y + 6.0 + int(k / 3) * 3.0), 180)
		RoomBuilder.box(ms, Vector3(0.04, 1.1, 0.04), Vector3(0, 0.55, 0), Palette.INK2)
		RoomBuilder.box(ms, Vector3(0.5, 0.36, 0.03), Vector3(0, 1.15, 0), Palette.INK2).rotation.x = -0.4
		Props.finish(ms, solids, Vector3(0.5, 1.3, 0.3), Vector3.ZERO)
	CivicBuilder._staff(c, "middle_principal", "Principal Vargas", Vector3(r.end.x - 4.0, 0, b["fz"] - 1.4), 180.0,
		{"gender": "boy", "hair": "buzz", "hair_color": 0, "skin": 1, "adult": true, "top_style": "plain",
		"top": Color("3A4A6A"), "pants": Color("2B2B30"), "shoes": Palette.INK}, 1.0, Vector2(7.5, 16.0), [1, 2, 3, 4, 5],
		["Walk, don't run!", "Middle school: the best three years of your life. Allegedly.", "Your locker combination is not a suggestion."], "middle_school")
	st = (out["staff"] as Array).back()
	st["months"] = SCHOOL_YEAR
	st["door"] = Vector3(r.get_center().x, 0, r.end.y + 0.9)
	st["edge"] = TownFolk.EDGES[2]
	st["lock"] = "middle_school"


## The back half of a school: three rooms side by side, each with a door from the hallway.
static func _back_rooms(c: Dictionary, key: String, r: Rect2, back_r: Rect2, hz: float, hgt: float, b: Dictionary, wall: Color,
		outside: Color, floors: Array, top := -1.0) -> void:
	var root: Node3D = c["root"]
	var tex: Dictionary = c["tex"]
	var out: Dictionary = c["out"]
	var w3 := r.size.x / 3.0
	for k in 3:
		RoomBuilder.make_floor(root, Rect2(r.position.x + k * w3, back_r.position.y, w3, back_r.size.y), floors[k], tex["lino"] if k != 2 else tex["panel"])
	RoomBuilder.make_ceiling(root, out, back_r.grow(-T / 2.0), hgt)
	(c["buildings"] as Array).append(back_r)
	var wh := hgt if top < 0.0 else top
	var bw := RoomBuilder.make_wall(root, key + "Rear", Vector3(r.get_center().x, 0, r.position.y), Vector3(r.size.x + T, wh, T), Vector3(0, 0, -1),
		tex, [], false, wall, "panel")
	var lw := RoomBuilder.make_wall(root, key + "RearL", Vector3(r.position.x, 0, back_r.get_center().y + T / 2.0), Vector3(T, wh, back_r.size.y),
		Vector3(-1, 0, 0), tex, [], false, wall, "panel")
	var rw := RoomBuilder.make_wall(root, key + "RearR", Vector3(r.end.x, 0, back_r.get_center().y + T / 2.0), Vector3(T, wh, back_r.size.y),
		Vector3(1, 0, 0), tex, [], false, wall, "panel")
	RoomBuilder.add_siding(bw, -1.0, wh, tex, -INF, INF, true, true, outside, "brick")
	RoomBuilder.add_siding(lw, -1.0, wh, tex, -INF, INF, true, true, outside, "brick")
	RoomBuilder.add_siding(rw, 1.0, wh, tex, -INF, INF, true, true, outside, "brick")
	for w in [bw, lw, rw]:
		(out["walls"] as Array).append(w)
	var broof := RoomBuilder.box(root, Vector3(back_r.size.x + 0.4, 0.22, back_r.size.y + 0.2), Vector3(r.get_center().x, wh + 0.11, back_r.get_center().y - 0.1), Color("5A5550"))
	(out["ceilings"] as Array).append(broof)
	var old: Dictionary = b["back"]
	(old["body"] as Node).queue_free()
	(out["walls"] as Array).erase(old)
	CivicBuilder._windows(c, bw, [r.position.x + w3 / 2.0, r.get_center().x, r.end.x - w3 / 2.0], 1.6, 1.6, 1.3, r.position.y, -1.0)
	var ops := []
	for k in 3:
		ops.append([r.position.x + k * w3 + w3 / 2.0, 0.95, 2.2])
	CivicBuilder._partition(c, key + "Mid", true, hz, r.position.x + T / 2.0, r.end.x - T / 2.0, ops, hgt, wall)
	for k in [1, 2]:
		CivicBuilder._partition(c, key + "Div%d" % k, false, r.position.x + k * w3, r.position.y + T / 2.0, hz - T / 2.0, [], hgt - 0.03, wall.darkened(0.06))   # (just under the ceiling's top face)


# ================================================================ Maple Grove High School (two stories)

static func _high(c: Dictionary) -> void:
	var root: Node3D = c["root"]
	var solids: Array[Rect2] = c["solids"]
	var out: Dictionary = c["out"]
	var tex: Dictionary = c["tex"]
	var r := HIGH
	var hgt := 4.0
	var hz := r.end.y - HALL_D
	var wall := Color("E2E6EA")
	var b := CivicBuilder._building(c, "high", "High School Hallway", Rect2(r.position.x, hz, r.size.x, HALL_D), HIGH_H, 1.0, r.position.x + 6.0,
		wall, "panel", Color("A8A29A"), "brick", Color("C8C8C0"), "lino", [], true, Color("2E3A6A"))
	var back_r := Rect2(r.position.x, r.position.y, r.size.x, hz - r.position.y)
	_back_rooms(c, "high", r, back_r, hz, hgt, b, wall, Color("A8A29A"), [Color("C8B898"), Color("C8C8C0"), Color("B8C0C8")], HIGH_H)
	var w3 := r.size.x / 3.0
	CivicBuilder._room(c, "High School Hallway", Rect2(r.position.x, hz, r.size.x, HALL_D))
	CivicBuilder._room(c, "Cafeteria", Rect2(r.position.x, r.position.y, w3, back_r.size.y))
	CivicBuilder._room(c, "Chemistry Lab", Rect2(r.position.x + w3, r.position.y, w3, back_r.size.y))
	CivicBuilder._room(c, "High School Classroom", Rect2(r.position.x + 2.0 * w3, r.position.y, w3, back_r.size.y))
	# the ceiling of the ground floor is at 4 m; the second floor's slab shows between the two rows of windows outside
	CivicBuilder._sign(c, b["front"], r.position.x + 6.0, 3.3, b["fz"], 1.0, "MAPLE GROVE HIGH SCHOOL", Color("2E3A6A"), Palette.GOLD, 9.5)
	CivicBuilder._windows(c, b["front"], [r.position.x + 12.0, r.position.x + 16.0, r.end.x - 3.5], 1.6, 1.6, 1.3, b["fz"], 1.0)
	CivicBuilder._windows(c, b["front"], [r.position.x + 2.5, r.position.x + 6.0, r.position.x + 9.5, r.position.x + 13.0,
		r.position.x + 16.5, r.end.x - 3.5], 5.8, 1.6, 1.4, b["fz"], 1.0)
	for side in [b["front"]]:
		var band := RoomBuilder.box(side["full"], Vector3(r.size.x + 0.2, 0.25, 0.06), Vector3(r.get_center().x, 4.3, b["fz"] + 0.16), Color("8A847C"))
		band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a flagpole out front
	var fp := Props.solid(root, Vector3(r.end.x - 2.0, 0, r.end.y + 2.2), 0)
	RoomBuilder.box(fp, Vector3(0.1, 7.0, 0.1), Vector3(0, 3.5, 0), Palette.MUTED)
	RoomBuilder.box(fp, Vector3(1.2, 0.7, 0.02), Vector3(0.62, 6.4, 0), Color("2E3A6A"))
	RoomBuilder.box(fp, Vector3(0.5, 0.3, 0.025), Vector3(0.62, 6.4, 0), Palette.GOLD)
	Props.finish(fp, solids, Vector3(0.3, 7.0, 0.3), Vector3.ZERO)
	_hallway_things(c, "high", r, hz, Color("2E3A6A"))
	# ---- the stairs up (at the east end of the hall)
	var stairs := CivicBuilder._usable(c, "high_stairs_up", "Stairs to the Second Floor", "stairs", Vector3(r.end.x - 1.0, 0, hz + 1.8), 90)
	for k in 6:
		Props.part(stairs, Vector3(1.6, 0.2 + k * 0.2, 0.3), Vector3(0, (0.2 + k * 0.2) / 2.0, -0.75 + k * 0.3), Color("B8B0A0"))
	Props.part(stairs, Vector3(0.06, 0.9, 1.8), Vector3(-0.83, 1.4, 0.0), Palette.MUTED, null, false)
	Props.finish(stairs, solids, Vector3(1.6, 1.2, 1.8), Vector3(0, 0, -1.4), null, Vector3(0, 1.0, 0))
	# ---- the cafeteria: long tables, the lunch counter
	var cx := r.position.x
	for k in 2:
		var tb := CivicBuilder._usable(c, "cafeteria_table_%d" % (k + 1), "Cafeteria Table", "cafeteria_table", Vector3(cx + w3 / 2.0, 0, r.position.y + 6.0 + k * 5.0), 90)
		Props.part(tb, Vector3(4.0, 0.06, 1.0), Vector3(0, 0.74, 0), Color("D8D0C0"))
		Props.part(tb, Vector3(3.8, 0.7, 0.1), Vector3(0, 0.37, 0), Palette.MUTED, null, false)
		for sz in [-0.8, 0.8]:
			Props.part(tb, Vector3(4.0, 0.05, 0.36), Vector3(0, 0.45, sz), Color("2E3A6A"), null, false)
		Props.finish(tb, solids, Vector3(4.0, 0.8, 2.0), Vector3(0, 0, 1.4), Vector3(0, 0, 0.8), Vector3(0, 0.9, 0))
		var lunch := _act(tb, "Eat Lunch with Everybody", 30, {"hunger": 60.0, "social": 50.0}, "sit",
			["Mystery meat Monday. You eat it. It's a mystery.", "Somebody trades you a pudding cup for your carrots. Legendary trade.",
			"FOOD FIGHT! (Okay, one tater tot. But still.)"], Vector2(11.0, 13.5))
		lunch.surface = 0.45
		lunch.weekdays = [1, 2, 3, 4, 5]
		lunch.months = SCHOOL_YEAR
	var lc := CivicBuilder._usable(c, "lunch_counter", "Lunch Counter", "lunch_counter", Vector3(cx + w3 / 2.0, 0, r.position.y + 1.4), 0)
	Props.part(lc, Vector3(5.0, 1.0, 0.7), Vector3(0, 0.5, 0), Color("C8CCD0"))
	Props.part(lc, Vector3(5.0, 0.05, 0.9), Vector3(0, 1.02, 0.05), Color("A8ACB0"))
	for k in 4:
		Props.part(lc, Vector3(0.5, 0.1, 0.4), Vector3(-1.6 + k * 1.05, 1.1, 0.0), [Color("E8C870"), Color("7AB050"), Color("C86A4A"), Color("E8E0C8")][k], null, false)
	Props.finish(lc, solids, Vector3(5.0, 1.05, 0.7), Vector3(0, 0, 1.1), null, Vector3(0, 1.1, 0))
	var bl := _act(lc, "Buy a School Lunch", 20, {"hunger": 220.0, "fun": 4.0}, "stand",
		["Pizza day! Rectangle pizza, the best pizza.", "Sloppy joe, tater tots and a carton of chocolate milk."], Vector2(10.5, 13.5))
	bl.money = -0.75
	bl.sound = "cash_register"
	bl.weekdays = [1, 2, 3, 4, 5]
	bl.autonomous = false
	CivicBuilder._staff(c, "lunch_lady", "Mrs. Hupp", Vector3(cx + w3 / 2.0, 0, r.position.y + 0.6), 0.0,
		{"gender": "girl", "hair": "perm", "hair_color": 4, "skin": 1, "adult": true, "top_style": "plain",
		"top": Color("F2F2EE"), "pants": Color("4A4A52"), "shoes": Palette.INK}, 1.4, Vector2(10.0, 14.0), [1, 2, 3, 4, 5],
		["Tater tots are a vegetable. Sort of.", "No cutting in line!", "You want extra gravy, hon? Everybody wants extra gravy."], "high_school")
	var st: Dictionary = (out["staff"] as Array).back()
	st["door"] = Vector3(r.position.x + 6.0, 0, r.end.y + 0.9)
	st["edge"] = TownFolk.EDGES[2]
	st["lock"] = "high_school"
	# ---- the chemistry lab
	var chx := r.position.x + w3
	for k in 2:
		var lt := CivicBuilder._usable(c, "high_lab_%d" % (k + 1), "Lab Bench", "lab_table", Vector3(chx + w3 / 2.0, 0, r.position.y + 5.0 + k * 5.0), 0)
		Props.part(lt, Vector3(3.0, 0.9, 1.1), Vector3(0, 0.45, 0), Color("2B2B30"))
		Props.part(lt, Vector3(3.02, 0.04, 1.12), Vector3(0, 0.92, 0), Color("1A1A1E"))
		for t in 3:
			Props.part(lt, Vector3(0.1, 0.22, 0.1), Vector3(-1.0 + t * 0.8, 1.05, 0), [Color("E85A7A"), Color("4FB0E0"), Color("7AE07A")][t], null, false)
		Props.finish(lt, solids, Vector3(3.0, 0.95, 1.1), Vector3(0, 0, 1.05), null, Vector3(0, 1.0, 0))
		var ce := class_act(lt, "Do a Chemistry Experiment", SCHOOL_YEAR, CLASS_HOURS, [1, 2, 3, 4, 5], 45, {"fun": 36.0, "social": 10.0},
			["It turned PURPLE. It was supposed to turn blue. Science!", "Mr. Brennan says you have a future in chemistry. Or demolition."])
		ce.pose = "reach"
	var ptable := Props.solid(root, Vector3(chx + w3 / 2.0, 0, r.position.y + T / 2.0 + 0.09), 0)
	RoomBuilder.box(ptable, Vector3(3.0, 1.6, 0.04), Vector3(0, 1.8, 0), Color("F2EEE2"))
	CivicBuilder._label(ptable, "H  He  Li  Be  B  C  N  O\nNa  Mg  Al  Si  P  S  Cl  Ar", Vector3(0, 1.85, 0.03), 0.0, Color("2E3A6A"), 0.003, 40)
	Props.finish(ptable, solids, Vector3(3.0, 1.6, 0.06), Vector3.ZERO, null, null, Vector3(0, 1.8, 0))
	(solids as Array).pop_back()
	CivicBuilder._staff(c, "chem_teacher", "Mr. Brennan", Vector3(chx + 1.6, 0, r.position.y + 1.6), 0.0,
		{"gender": "boy", "hair": "buzz", "hair_color": 1, "skin": 0, "adult": true, "top_style": "coat",
		"top": Color("F2F2EE"), "pants": Color("4A4A52"), "shoes": Palette.INK}, 1.2, CLASS_HOURS, [1, 2, 3, 4, 5],
		["Never, EVER mix those two.", "Chemistry is just cooking you can't eat.", "Who turned the sink blue? ...Honestly, nice work."], "high_school")
	st = (out["staff"] as Array).back()
	st["months"] = SCHOOL_YEAR
	st["door"] = Vector3(r.position.x + 6.0, 0, r.end.y + 0.9)
	st["edge"] = TownFolk.EDGES[2]
	st["lock"] = "high_school"
	# ---- the classroom (summer school here too)
	var desk := _classroom(c, "high_class", Rect2(r.position.x + 2.0 * w3, r.position.y, w3, back_r.size.y), -1.0, "U.S. History\nThe Constitution", "high",
		"Mrs. Delgado", {"gender": "girl", "hair": "teased", "hair_color": 0, "skin": 2, "adult": true, "top_style": "plain",
		"top": Color("7A2E5A"), "pants": Color("2B2B30"), "shoes": Palette.INK},
		["Chapter twelve, everybody. Yes, the WHOLE chapter.", "This WILL be on the final.", "Summer school isn't a punishment. It's an opportunity!"],
		r, "high_school", 3, true)
	class_act(desk, "Go to Class (High School)", SCHOOL_YEAR, CLASS_HOURS, [1, 2, 3, 4, 5], 120,
		{"fun": -8.0, "social": 36.0, "energy": -8.0},
		["U.S. History. You learn about the Constitution. It's surprisingly dramatic.", "You sit with the big kids. Nobody notices. Perfect.",
		"A filmstrip! The projector beeps every time you turn the frame."], "high_school")
	class_act(desk, "Go to Summer School (High School)", SUMMER, SUMMER_HOURS, [1, 2, 3, 4], 120,
		{"fun": -10.0, "social": 30.0, "energy": -6.0},
		["Summer school. The air conditioner is broken. Of course it is.", "Mrs. Delgado brings popsicles. Summer school: saved."], "school")
	# ---- the principal's spot in the hallway
	CivicBuilder._staff(c, "high_principal", "Principal Okonkwo", Vector3(r.position.x + 9.0, 0, b["fz"] - 1.4), 180.0,
		{"gender": "boy", "hair": "high_top", "hair_color": 0, "skin": 3, "adult": true, "top_style": "plain",
		"top": Color("2E3A6A"), "pants": Color("2B2B30"), "shoes": Palette.INK}, 1.0, Vector2(7.5, 16.0), [1, 2, 3, 4, 5],
		["Hall pass?", "Go Mavericks!", "The upstairs is for juniors and seniors... and you, I guess."], "high_school")
	st = (out["staff"] as Array).back()
	st["door"] = Vector3(r.position.x + 6.0, 0, r.end.y + 0.9)
	st["edge"] = TownFolk.EDGES[2]
	st["lock"] = "high_school"
	# The second floor's slab, between the two stories (seen in the windows from outside)
	var slab := RoomBuilder.box(root, Vector3(r.size.x - 0.2, 0.3, r.size.y - 0.2), Vector3(r.get_center().x, hgt + 0.25, r.get_center().y), Color("6A665E"))
	(out["ceilings"] as Array).append(slab)
	if not out.has("portal_pairs"):
		out["portal_pairs"] = []
	(out["portal_pairs"] as Array).append(["high_stairs_up", "high_stairs_down"])


# ================================================================ the high school's upstairs (on the underground level)

static func build_upstairs(root: Node3D, out: Dictionary, tex: Dictionary, solids: Array[Rect2], free: Array[Rect2]) -> void:
	var level := Node3D.new()
	level.name = "HighSchoolUpstairs"
	level.position = Vector3(0, RoomBuilder.INTERIOR_Y, 0)
	root.add_child(level)
	var c := {"root": level, "out": out, "tex": tex, "solids": solids, "objects": out["objects"], "home": "town", "level": 1,
		"free": free, "doorways": [], "buildings": []}
	var r := HIGH_UP
	var hgt := 3.4
	var wall := Color("E2E6EA")
	var hz := r.end.y - HALL_D
	RoomBuilder.make_floor(level, Rect2(r.position.x, hz, r.size.x, HALL_D), Color("C8C8C0"), tex["lino"])
	var w3 := r.size.x / 3.0
	for k in 3:
		RoomBuilder.make_floor(level, Rect2(r.position.x + k * w3, r.position.y, w3, hz - r.position.y),
			[Color("B8A888"), Color("A8B0B8"), Color("8A6A4A")][k], tex["lino"] if k < 2 else tex["panel"])
	RoomBuilder.make_ceiling(level, out, r.grow(-T / 2.0), hgt)
	InteriorBuilder._shell(c, r, hgt, wall, "panel")
	# windows on the outside walls (it's upstairs: you can see out)
	var glass: StandardMaterial3D = out["window_mat"]
	for wx in [r.position.x + 4.0, r.get_center().x, r.end.x - 4.0]:
		var win := RoomBuilder.box(level, Vector3(1.6, 1.2, 0.04), Vector3(wx, 1.7, r.position.y + T / 2.0 + 0.03), Color("9FC4DA"))
		win.material_override = glass
	var ops := []
	for k in 3:
		ops.append([r.position.x + k * w3 + w3 / 2.0, 0.95, 2.2])
	var cc := c.duplicate()
	CivicBuilder._partition(cc, "highUpMid", true, hz, r.position.x + T / 2.0, r.end.x - T / 2.0, ops, hgt, wall)
	for k in [1, 2]:
		CivicBuilder._partition(cc, "highUpDiv%d" % k, false, r.position.x + k * w3, r.position.y + T / 2.0, hz - T / 2.0, [], hgt, wall.darkened(0.06))
	free.append(Rect2(r.position.x, hz, r.size.x, HALL_D).grow(-T / 2.0))
	for k in 3:
		free.append(Rect2(r.position.x + k * w3, r.position.y, w3, hz - r.position.y).grow(-T / 2.0))
	for d in cc["doorways"]:
		free.append((d as Rect2).grow(0.25))      # (free areas get shrunk a little when the grid is made: doorways don't)
	out["interior_rooms"]["town|High School Upstairs Hall"] = Rect2(r.position.x, hz, r.size.x, HALL_D)
	out["interior_rooms"]["town|Typing Class"] = Rect2(r.position.x, r.position.y, w3, hz - r.position.y)
	out["interior_rooms"]["town|Computer Lab"] = Rect2(r.position.x + w3, r.position.y, w3, hz - r.position.y)
	out["interior_rooms"]["town|High School Library"] = Rect2(r.position.x + 2.0 * w3, r.position.y, w3, hz - r.position.y)
	InteriorBuilder.extra_rooms.append(r)
	# ---- the stairs back down
	var down := CivicBuilder._usable(c, "high_stairs_down", "Stairs Down", "stairs", Vector3(r.end.x - 1.0, 0, hz + 1.8), 90)
	for k in 4:
		Props.part(down, Vector3(1.6, 0.06, 0.3), Vector3(0, 0.03, -0.45 + k * 0.3), Color("8A847C"))
	Props.part(down, Vector3(0.06, 0.9, 1.4), Vector3(-0.83, 0.45, 0.0), Palette.MUTED, null, false)
	Props.finish(down, solids, Vector3(1.6, 0.9, 1.4), Vector3(0, 0, -1.3), null, Vector3(0, 0.6, 0))
	(solids as Array).pop_back()
	solids.append(Rect2(r.end.x - 1.0 - 0.7, hz + 1.1, 1.4, 1.4))
	for k in 3:
		InteriorBuilder._light(c, Vector3(r.position.x + k * w3 + w3 / 2.0, 0, r.position.y + (hz - r.position.y) / 2.0), hgt, 9.0, 1.0, Color("F2F4FF"))
	InteriorBuilder._light(c, Vector3(r.get_center().x, 0, hz + HALL_D / 2.0), hgt, 10.0, 0.9, Color("F2F4FF"))
	# ---- typing class: rows of typewriters
	for k in 6:
		var p := Vector3(r.position.x + 1.6 + (k % 3) * 2.4, 0, r.position.y + 3.0 + int(k / 3) * 3.2)
		if k == 4:
			var tw := CivicBuilder._usable(c, "typewriter", "Typewriter", "typewriter", p, 180)
			Props.part(tw, Vector3(0.9, 0.72, 0.6), Vector3(0, 0.36, 0), Color("8A6A4A"))
			Props.part(tw, Vector3(0.45, 0.16, 0.35), Vector3(0, 0.8, 0), Color("4A6A5A"))
			Props.part(tw, Vector3(0.36, 0.2, 0.02), Vector3(0, 0.95, 0.12), Palette.PAPER, null, false)
			Props.finish(tw, solids, Vector3(0.9, 0.9, 0.6), Vector3(0, 0, -1.0), Vector3(0, 0, -0.55), Vector3(0, 0.85, 0))
			var ty := class_act(tw, "Practice Typing", SCHOOL_YEAR + SUMMER, CLASS_HOURS, [1, 2, 3, 4, 5], 30, {"fun": 16.0, "social": 6.0},
				["The quick brown fox jumps over the lazy dog. 22 words a minute!", "DING! You hit the return. So satisfying."], "typing")
			ty.loop_sound = "typing"
			ty.loop_db = -8.0
		else:
			var d := Props.solid(level, p, 180)
			RoomBuilder.box(d, Vector3(0.9, 0.72, 0.6), Vector3(0, 0.36, 0), Color("8A6A4A"))
			RoomBuilder.box(d, Vector3(0.45, 0.16, 0.35), Vector3(0, 0.8, 0), Color("4A6A5A"))
			Props.finish(d, solids, Vector3(0.9, 0.9, 0.6), Vector3.ZERO)
	# ---- the computer lab: big beige computers (the same kind Circuit Hut sells)
	var cx := r.position.x + w3
	for k in 4:
		var p := Vector3(cx + 1.6 + (k % 2) * 4.0, 0, r.position.y + 3.0 + int(k / 2) * 3.6)
		var tbl := CivicBuilder._usable(c, "lab_computer_%d" % (k + 1), "School Computer", "lab_computer", p, 180)
		Props.part(tbl, Vector3(1.4, 0.74, 0.7), Vector3(0, 0.37, 0), Color("D8D0C0"))
		var g := Node3D.new()
		g.position = Vector3(0, 0.74, 0)
		g.scale = Vector3(0.7, 0.7, 0.7)
		tbl.add_child(g)
		MallBuilder.computer_model(g, "computer_color")
		Props.finish(tbl, solids, Vector3(1.4, 1.1, 0.7), Vector3(0, 0, -1.1), Vector3(0, 0, -0.6), Vector3(0, 1.0, 0))
		var ca := class_act(tbl, "Computer Class", SCHOOL_YEAR, CLASS_HOURS, [1, 2, 3, 4, 5], 45, {"fun": 38.0},
			["10 PRINT \"HELLO\" / 20 GOTO 10. The screen fills up with HELLO. You are a programmer now.",
			"You play a game about a wagon trail. Your whole wagon gets sick. Classic."], "computer_lab")
		ca.pose = "sit"
		ca.surface = 0.45
	# ---- the library: shelves and a big study table
	var lx := r.position.x + 2.0 * w3
	for k in 2:
		var sh := CivicBuilder._usable(c, "high_bookshelf_%d" % (k + 1), "Library Shelf", "library_shelf", Vector3(lx + 2.0 + k * 3.6, 0, r.position.y + T / 2.0 + 0.25), 0)
		Props.part(sh, Vector3(2.8, 2.2, 0.45), Vector3(0, 1.1, 0), Palette.WOOD_DARK)
		for row in 4:
			for bk in 9:
				Props.part(sh, Vector3(0.22, 0.34, 0.3), Vector3(-1.15 + bk * 0.29, 0.3 + row * 0.5, 0.08),
					[Color("7A2E2E"), Color("2E3A6A"), Color("4F6A3A"), Color("8A6A3A"), Color("4A4A52")][(bk + row * 2 + k) % 5], null, false)
		Props.finish(sh, solids, Vector3(2.8, 2.2, 0.45), Vector3(0, 0, 0.9), null, Vector3(0, 1.2, 0))
		_act(sh, "Study in the Library", 45, {"fun": 10.0, "energy": -4.0, "social": 6.0}, "read",
			["You study for a test you don't even have. Ahead of the game!", "The encyclopedia has a whole page about dinosaurs. Two, actually."], Vector2(7.5, 16.5))
	var stbl := Props.solid(level, Vector3(lx + w3 / 2.0, 0, r.position.y + 8.5), 0)
	RoomBuilder.box(stbl, Vector3(3.2, 0.76, 1.4), Vector3(0, 0.38, 0), Palette.WOOD)
	Props.finish(stbl, solids, Vector3(3.2, 0.8, 1.4), Vector3.ZERO)
