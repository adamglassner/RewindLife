class_name EventGrounds
extends RefCounted
## What sets up at the fairgrounds (north of the east end of Maple Street) when
## the carnival or the circus comes to town (see holidays.gd for when):
##
##   CARNIVAL: a Ferris wheel, a carousel, game booths, cotton candy and corn dogs
##   CIRCUS:   the big top (watch the show), a strongman bell, a popcorn cart, clowns
##
## Everything here belongs to Holidays: it's built once and shown only during the event.

const F := EastBuilder.FAIR
const WHEEL := Vector3(98.0, 0, -3.0)
const WHEEL_R := 6.0
const WHEEL_H := 7.4
const CAROUSEL := Vector3(112.0, 0, 1.0)
const CAROUSEL_R := 2.6
const TENT := Vector3(110.0, 0, -0.5)
const TENT_R := 8.5
const HOURS_CARNIVAL := Vector2(12.0, 23.0)
const HOURS_CIRCUS := Vector2(11.0, 21.0)


static func build(h: Holidays) -> void:
	var main: Node = h.main
	var objs: Dictionary = main.room["objects"]
	var solids: Array[Rect2] = main.room["grid_lists"][4]
	_carnival(h, objs, solids)
	_circus(h, objs, solids)


## A thing that's part of an event: shown and solid only while it's on.
static func _solid(h: Holidays, group: String, root: Node3D, pos: Vector3, yaw: float) -> StaticBody3D:
	var b := Props.solid(root, pos, yaw)
	h._register(group, b)
	return b


static func _item(h: Holidays, group: String, objs: Dictionary, key: String, title: String, kind: String, pos: Vector3, yaw: float) -> SmartObject:
	var o := Props.item(h, objs, key, title, pos, yaw)
	o.kind = kind
	o.home = "town"
	o.shared = true
	h._register(group, o)
	(h._objects[group] as Array).append(o)
	return o


static func _finish(h: Holidays, group: String, o: Node3D, solids: Array[Rect2], size: Vector3, approach: Vector3, use = null, look = null) -> void:
	Props.finish(o, solids, size, approach, use, look)
	h._register_solid(group, solids.size() - 1)


static func _act(o: SmartObject, title: String, mins: int, fx: Dictionary, pose: String, msgs: Array, money: float,
		hours: Vector2, group: String) -> Activity:
	var a := Activity.make(title, mins, fx, pose)
	a.messages = msgs
	a.money = money
	a.from_hour = hours.x
	a.to_hour = hours.y
	a.holidays = [group]
	a.autonomous = money == 0.0
	if money < 0.0:
		a.sound = "cash_register"
	o.activities.append(a)
	return a


# ================================================================ the carnival

static func _carnival(h: Holidays, objs: Dictionary, solids: Array[Rect2]) -> void:
	var g := "carnival"
	var hrs := HOURS_CARNIVAL
	# ---- the Ferris wheel
	var base := _solid(h, g, h, WHEEL, 0)
	for side in [-1.0, 1.0]:
		for lx in [-1.0, 1.0]:
			var leg := RoomBuilder.box(base, Vector3(0.3, WHEEL_H + 0.6, 0.3), Vector3(lx * 2.0, WHEEL_H / 2.0, side * 1.0), Color("C8CCD0"))
			leg.rotation.z = lx * 0.28
	RoomBuilder.box(base, Vector3(0.4, 0.4, 2.6), Vector3(0, WHEEL_H, 0), Color("8A8E94"))
	RoomBuilder.box(base, Vector3(3.0, 0.3, 3.4), Vector3(0, 0.15, 0), Color("6A6E74"))
	Props.finish(base, solids, Vector3(5.6, 1.0, 2.6), Vector3.ZERO)
	h._register_solid(g, solids.size() - 1)
	var wheel := Node3D.new()
	wheel.name = "FerrisWheel"
	wheel.position = WHEEL + Vector3(0, WHEEL_H, 0)
	h.add_child(wheel)
	h._register(g, wheel)
	h._spin["wheel"] = wheel
	var cols := [Color("FF4F4F"), Color("F7D046"), Color("4FC8FF"), Color("4FD84F"), Color("FF8AE0"), Color("F2F0E6")]
	for k in 16:
		var a := float(k) / 16.0 * TAU
		var rim := RoomBuilder.box(wheel, Vector3(0.18, 2.4, 0.18), Vector3(sin(a) * WHEEL_R, -cos(a) * WHEEL_R, 0), Color("F2F0E6"))
		rim.rotation.z = a
		var bulb := h._box(wheel, Vector3(0.16, 0.16, 0.16), Vector3(sin(a) * (WHEEL_R + 0.12), -cos(a) * (WHEEL_R + 0.12), 0.12), cols[k % cols.size()], 1.6)
		bulb.rotation.z = a
	for k in 8:
		var a := float(k) / 8.0 * TAU
		var spoke := RoomBuilder.box(wheel, Vector3(0.1, WHEEL_R, 0.1), Vector3(sin(a) * WHEEL_R / 2.0, -cos(a) * WHEEL_R / 2.0, 0), Color("C8CCD0"))
		spoke.rotation.z = a
	var gondolas := []
	for k in 8:
		var a := float(k) / 8.0 * TAU
		var gp := Node3D.new()
		gp.position = Vector3(sin(a) * WHEEL_R, -cos(a) * WHEEL_R, 0)
		wheel.add_child(gp)
		RoomBuilder.box(gp, Vector3(1.0, 0.7, 0.9), Vector3(0, -0.6, 0), cols[k % cols.size()])
		RoomBuilder.box(gp, Vector3(0.06, 0.5, 0.06), Vector3(0, -0.06, 0), Color("8A8E94"))
		gondolas.append(gp)
	h._spin["gondolas"] = gondolas
	var ride := _item(h, g, objs, "ferris_wheel", "Ferris Wheel", "carnival_ride", WHEEL + Vector3(0, 0, 1.9), 0)
	Props.part(ride, Vector3(1.4, 0.4, 0.6), Vector3(0, 0.2, 0), Color("C0322A"))
	_finish(h, g, ride, solids, Vector3(1.4, 0.4, 0.6), Vector3(0, 0, 1.0), null, Vector3(0, 3.0, -2.0))
	ride.use_point = WHEEL + Vector3(0, 0, 0.0)
	ride.look_point = WHEEL + Vector3(0, 1.0, 5.0)
	var a := _act(ride, "Ride the Ferris Wheel", 15, {"fun": 70.0}, "ride_wheel",
		["From the top you can see your whole house! And the mall! And... is that the school?", "The wheel stops with you right at the top. Don't look down. (You look down.)"],
		-1.0, hrs, g)
	a.memory_id = "carnival"
	# ---- the carousel
	var car := _solid(h, g, h, CAROUSEL, 0)
	var platform := Node3D.new()
	platform.position = CAROUSEL
	h.add_child(platform)
	h._register(g, platform)
	h._spin["carousel"] = platform
	RoomBuilder.box(car, Vector3(0.4, 3.2, 0.4), Vector3(0, 1.6, 0), Color("F7D046"))
	var roof := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2
	cm.bottom_radius = CAROUSEL_R + 0.7
	cm.height = 1.4
	cm.radial_segments = 12
	roof.mesh = cm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color("E85A7A")
	roof.material_override = rm
	roof.position = Vector3(0, 3.9, 0)
	car.add_child(roof)
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = CAROUSEL_R + 0.3
	dm.bottom_radius = CAROUSEL_R + 0.3
	dm.height = 0.3
	dm.radial_segments = 16
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color("D9D2C2")
	disc.material_override = dmat
	disc.position = Vector3(0, 0.15, 0)
	platform.add_child(disc)
	var horses := []
	for k in 8:
		var an := float(k) / 8.0 * TAU
		var hp := Node3D.new()
		hp.position = Vector3(cos(an) * CAROUSEL_R, 0, sin(an) * CAROUSEL_R)
		hp.rotation.y = -an
		platform.add_child(hp)
		RoomBuilder.box(hp, Vector3(0.05, 3.3, 0.05), Vector3(0, 1.95, 0), Palette.GOLD)
		var horse := Node3D.new()
		horse.position = Vector3(0, 0.95, 0)
		hp.add_child(horse)
		RoomBuilder.box(horse, Vector3(0.3, 0.38, 1.0), Vector3(0, 0.0, 0), [Color("F2F0E6"), Color("8A5A2A"), Color("2B2B30")][k % 3])
		RoomBuilder.box(horse, Vector3(0.24, 0.42, 0.3), Vector3(0, 0.3, 0.5), [Color("F2F0E6"), Color("8A5A2A"), Color("2B2B30")][k % 3])
		RoomBuilder.box(horse, Vector3(0.32, 0.08, 0.3), Vector3(0, 0.22, 0.0), Color("C0322A"))
		for lz in [-0.35, 0.35]:
			RoomBuilder.box(horse, Vector3(0.08, 0.4, 0.08), Vector3(0, -0.38, lz), Palette.INK2)
		horses.append(horse)
	h._spin["horses"] = horses
	Props.finish(car, solids, Vector3((CAROUSEL_R + 0.3) * 2.0, 4.0, (CAROUSEL_R + 0.3) * 2.0), Vector3.ZERO)
	h._register_solid(g, solids.size() - 1)
	var cr := _item(h, g, objs, "carousel", "Carousel", "carnival_ride", CAROUSEL + Vector3(0, 0, CAROUSEL_R + 0.55), 0)
	Props.part(cr, Vector3(1.0, 0.1, 0.4), Vector3(0, 0.05, 0), Color("C0322A"))
	_finish(h, g, cr, solids, Vector3(1.0, 0.1, 0.4), Vector3(0, 0, 0.9), null, Vector3(0, 1.0, -2.0))
	(solids as Array).pop_back()
	cr.use_point = CAROUSEL
	cr.look_point = CAROUSEL + Vector3(0, 1.0, -5.0)
	_act(cr, "Ride the Carousel", 10, {"fun": 50.0}, "ride_carousel", ["Round and round! The organ music is stuck in your head now. Forever.", "You pick the black horse. Obviously."], -0.75, hrs, g)
	# ---- game booths and food stands
	var booths := [["ring_toss", "Ring Toss", Color("C0322A"), Vector3(118.0, 0, 9.4), ["Play Ring Toss", 0.5]],
		["balloon_darts", "Balloon Darts", Color("2E5E9E"), Vector3(123.0, 0, 9.4), ["Throw Darts at the Balloons", 0.5]],
		["duck_pond", "Duck Pond", Color("2EB86A"), Vector3(128.0, 0, 9.4), ["Pick a Lucky Duck", 0.25]],
		["cotton_candy", "Cotton Candy", Color("FF8AE0"), Vector3(93.0, 0, 9.4), ["Buy Cotton Candy", 0.75]],
		["corn_dogs", "Corn Dogs", Color("F7D046"), Vector3(98.0, 0, 9.4), ["Buy a Corn Dog", 1.0]]]
	for b in booths:
		var o := _booth(h, g, objs, solids, b[0], b[1], b[2], b[3])
		var food: bool = b[0] in ["cotton_candy", "corn_dogs"]
		var fx := {"hunger": 90.0, "fun": 30.0} if food else {"fun": 46.0, "social": 10.0}
		var msgs: Array = ["Sweet, sticky, and gone in a minute.", "Best thing you've eaten all year."] if food else \
			["You win a giant stuffed banana!", "So close! The guy says you get one more try for a quarter.", "You win a goldfish in a bag! ...Mom's going to love this."]
		_act(o, b[4][0], 10, fx, "reach", msgs, -float(b[4][1]), hrs, g)
	# strings of lights between poles
	var poles := [94.0, 104.0, 116.0, 126.0]
	for pi in poles.size():
		var x: float = poles[pi]
		var pole := _solid(h, g, h, Vector3(x, 0, 6.2), 0)
		RoomBuilder.box(pole, Vector3(0.14, 4.2, 0.14), Vector3(0, 2.1, 0), Color("8A6A4A"))
		Props.finish(pole, solids, Vector3(0.2, 4.2, 0.2), Vector3.ZERO)
		h._register_solid(g, solids.size() - 1)
		if pi + 1 < poles.size():
			var span: float = float(poles[pi + 1]) - x
			for k in 12:
				var bx: float = x + 0.5 + k * (span - 1.0) / 11.0
				var sag := sin(float(k) / 11.0 * PI) * 0.6
				var bulb := h._box(h, Vector3(0.14, 0.18, 0.14), Vector3(bx, 4.0 - sag, 6.2), cols[k % cols.size()], 1.4)
				h._register(g, bulb)
	h._fair_music.append(["carnival", F.get_center()])


## A striped booth with a counter (and prizes or a food sign).
static func _booth(h: Holidays, g: String, objs: Dictionary, solids: Array[Rect2], key: String, title: String, col: Color, at: Vector3) -> SmartObject:
	var o := _item(h, g, objs, key, title, "carnival_booth", at, 180)
	Props.part(o, Vector3(2.6, 1.0, 0.7), Vector3(0, 0.5, 0), col)
	Props.part(o, Vector3(2.66, 0.05, 0.76), Vector3(0, 1.025, 0), Palette.PAPER)
	for px in [-1.22, 1.22]:
		Props.part(o, Vector3(0.08, 2.4, 0.08), Vector3(px, 1.2, -0.28), Palette.PAPER, null, false)
	for k in 6:
		Props.part(o, Vector3(0.45, 0.12, 1.2), Vector3(-1.125 + k * 0.45, 2.45, 0.1), col if k % 2 == 0 else Palette.PAPER, null, false)
	Props.part(o, Vector3(2.6, 1.4, 0.06), Vector3(0, 1.75, -0.36), col.darkened(0.3), null, false)
	for k in 5:
		Props.part(o, Vector3(0.24, 0.3, 0.12), Vector3(-1.0 + k * 0.5, 1.6, -0.28), [Color("F7D046"), Color("FF8AE0"), Color("4FC8FF"), Color("4FD84F"), Color("F2F0E6")][k], null, false)
	CivicBuilder._label(o, title.to_upper(), Vector3(0, 2.2, 0.72), 0.0, Palette.INK, 0.004, 48)
	_finish(h, g, o, solids, Vector3(2.6, 1.05, 0.7), Vector3(0, 0, 1.0), null, Vector3(0, 1.1, 0))
	return o


# ================================================================ the circus

static func _circus(h: Holidays, objs: Dictionary, solids: Array[Rect2]) -> void:
	var g := "circus"
	var hrs := HOURS_CIRCUS
	# ---- the big top: striped walls all the way around, a pointed roof, flags
	var tent := _solid(h, g, h, TENT, 0)
	var n := 16
	for k in n:
		var a := float(k) / n * TAU
		if k == 4:
			continue     # (the way in faces Maple Street)
		var sh := 3.4 + (k % 2) * 0.04        # (every other one a touch taller: their tops never line up)
		var seg := RoomBuilder.box(tent, Vector3(0.12, sh, TENT_R * TAU / n + 0.05), Vector3(cos(a) * TENT_R, sh / 2.0 - (k % 2) * 0.02, sin(a) * TENT_R),
			Color("C0322A") if k % 2 == 0 else Palette.PAPER)
		seg.rotation.y = -a
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.25
	tm.bottom_radius = TENT_R + 0.6
	tm.height = 5.0
	tm.radial_segments = 16
	top.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color("C0322A")
	top.material_override = tmat
	top.position = Vector3(0, 3.4 + 2.5, 0)
	tent.add_child(top)
	var stripe := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 2.6
	sm.bottom_radius = 4.4
	sm.height = 1.2
	sm.radial_segments = 16
	stripe.mesh = sm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Palette.PAPER
	stripe.material_override = smat
	stripe.position = Vector3(0, 6.2, 0)
	tent.add_child(stripe)
	RoomBuilder.box(tent, Vector3(0.12, 2.0, 0.12), Vector3(0, 9.4, 0), Color("8A8E94"))
	RoomBuilder.box(tent, Vector3(0.9, 0.5, 0.03), Vector3(0.45, 10.1, 0), Color("F7D046"))
	# inside: the ring and the bleachers
	var ring := MeshInstance3D.new()
	var rmesh := CylinderMesh.new()
	rmesh.top_radius = 3.0
	rmesh.bottom_radius = 3.0
	rmesh.height = 0.3
	rmesh.radial_segments = 24
	ring.mesh = rmesh
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color("C0322A")
	ring.material_override = rmat
	ring.position = Vector3(0, 0.15, -1.5)
	tent.add_child(ring)
	RoomBuilder.box(tent, Vector3(5.6, 0.02, 5.6), Vector3(0, 0.01, -1.5), Color("D9B07A"))
	for k in 3:
		RoomBuilder.box(tent, Vector3(10.0, 0.4 + k * 0.45, 0.8), Vector3(0, (0.4 + k * 0.45) / 2.0, -6.0 - k * 0.8), Color("2E5E9E").lightened(k * 0.1))
	Props.finish(tent, solids, Vector3(TENT_R * 2.0, 3.4, TENT_R * 2.0), Vector3.ZERO)
	h._register_solid(g, solids.size() - 1)
	CivicBuilder._label(h, "THE AMAZING ZAMBINI BROTHERS CIRCUS", TENT + Vector3(0, 4.0, TENT_R + 0.7), 0.0, Color("F7D046"), 0.006, 72)
	h._register(g, h.get_child(h.get_child_count() - 1))
	# the way in: buy a ticket and watch the show
	var tix := _item(h, g, objs, "circus_tickets", "Circus Ticket Stand", "circus", TENT + Vector3(-3.6, 0, TENT_R + 1.6), 180)
	Props.part(tix, Vector3(1.6, 1.1, 0.8), Vector3(0, 0.55, 0), Color("C0322A"))
	Props.part(tix, Vector3(1.8, 0.2, 1.0), Vector3(0, 2.3, 0), Color("F7D046"))
	for px in [-0.7, 0.7]:
		Props.part(tix, Vector3(0.08, 1.2, 0.08), Vector3(px, 1.7, 0), Palette.PAPER, null, false)
	CivicBuilder._label(tix, "TICKETS $2", Vector3(0, 2.3, -0.52), 180.0, Palette.INK, 0.004, 48)
	_finish(h, g, tix, solids, Vector3(1.6, 1.1, 0.8), Vector3(0, 0, -1.0), null, Vector3(0, 1.2, 0))
	var a := _act(tix, "Watch the Circus Show", 60, {"fun": 90.0, "social": 30.0}, "stand",
		["The lion tamer! The trapeze! A tiny car with SIXTEEN clowns in it!", "A man juggles flaming torches on a unicycle. You forget to blink."],
		-2.0, hrs, g)
	a.memory_id = "circus"
	a.loop_sound = "circus"
	a.loop_db = -8.0
	# the strongman bell, a popcorn cart
	var bell := _item(h, g, objs, "strongman_bell", "Strongman Bell", "carnival_booth", Vector3(96.0, 0, 6.0), 180)
	Props.part(bell, Vector3(0.6, 0.3, 0.6), Vector3(0, 0.15, 0), Color("C0322A"))
	Props.part(bell, Vector3(0.2, 5.0, 0.2), Vector3(0, 2.6, -0.1), Palette.PAPER)
	Props.part(bell, Vector3(0.4, 0.3, 0.4), Vector3(0, 5.2, -0.1), Palette.GOLD)
	for k in 5:
		Props.part(bell, Vector3(0.24, 0.04, 0.02), Vector3(0, 1.0 + k * 0.8, 0.0), [Color("2EB86A"), Color("F7D046"), Color("E4892E"), Color("C0322A"), Color("FF4FD8")][k], null, false)
	_finish(h, g, bell, solids, Vector3(0.6, 5.3, 0.6), Vector3(0, 0, -1.0), null, Vector3(0, 1.0, 0))
	_act(bell, "Ring the Strongman Bell", 5, {"fun": 40.0, "energy": -6.0}, "reach",
		["WHAM! The puck flies up... and stops at WIMP. Rats.", "DING! You ring the bell! Somebody gives you a cigar-shaped candy!"], -0.5, hrs, g)
	var pop := _booth(h, g, objs, solids, "circus_popcorn", "Popcorn", Color("F7D046"), Vector3(124.0, 0, 9.4))
	_act(pop, "Buy a Bag of Popcorn", 10, {"hunger": 70.0, "fun": 20.0}, "reach", ["Extra butter. Your fingers will never be the same."], -0.5, hrs, g)
	h._fair_music.append(["circus", F.get_center()])
	# where the clowns walk (TownFolk / Holidays)
	h._clown_route = [Vector3(95.0, 0, 10.6), Vector3(124.0, 0, 10.6), Vector3(127.0, 0, -4.0), Vector3(95.0, 0, -6.0)]
