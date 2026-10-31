class_name TownLife
extends Node
## The town going about its day (the host runs all of this; everyone else sees
## the results):
##   - Officer Dwyer's patrols, the fire engine's daily drill, the milk run
##   - townsfolk who bump into each other stopping for a chat
##   - and, once in a blue moon, a burglar in the night. Catch him and Officer
##     Dwyer takes him to jail for 30 days; let him get away and he'll be back.

## Odds per game minute, late at night, that the burglar tries a house.
const BURGLAR_CHANCE := 0.00012
const SENTENCE_DAYS := 30
const STEAL_MINUTES := 25
const REWARD := 10.0

const CHATS := [
	["Morning! Lovely weather.", "Isn't it? Hope it holds for the weekend."],
	["Did you see the price of gas? Ninety cents a gallon!", "Highway robbery, I tell you."],
	["How's the family?", "Oh, you know. The kids eat everything in the house.", "Ha! Ours too."],
	["Are you going to the drive-in Friday?", "Wouldn't miss it! It's a monster movie."],
	["Heard the new mall's opening this fall.", "About time! I'm tired of driving to Springfield."],
	["Your roses look wonderful this year.", "Thank you! It's the coffee grounds. Don't tell anyone."],
	["Did you catch the game last night?", "Don't remind me. Bottom of the ninth!"],
	["I read about that burglar in the Gazette.", "Scary! I've started locking the back door."],
	["Have you tried Pizza Peak's new pan pizza?", "Twice! Don't tell my doctor."],
	["The Hendersons got a VCR!", "Fancy! We're still renting one from Rewind Video."],
]
const KID_CHATS := [
	["Wanna play tag after lunch?", "Okay! You're it!"],
	["I got to level 8 on Dragon Tower!", "No way! Prove it!"],
	["Did you see the fire truck go by?", "It was SO loud! So cool."],
	["My mom says no swimming till an hour after lunch.", "Mine too! It's a conspiracy."],
]

var main: Node
var vehicles: Array = []           # NpcVehicles
var police: NpcVehicle
var engine1: NpcVehicle
var milk: NpcVehicle
## The burglar: state none / approach / inside / stealing / fleeing / caught / escort / jailed
var burglar := {"state": "none", "home": "", "release": 0, "next_ok": 0, "until": 0}
var _chat_t := 0.0
var _last_drill := -1
var _last_patrol := -1
var _last_milk := -1
var mail_truck: NpcVehicle
var _last_mail := -1
var _mail_day := {}               # home -> the day (unix days) the mail truck brought their mail
var _mail_taken := {}             # home -> the day somebody took it in
var traffic: Array = []            # the everyday cars (NpcVehicles), hidden when they're out of town
var _mall_spots_taken := {}        # spot index -> car key

## [paint, driver's shirt, title]
const TRAFFIC := [[Color("8A2A2A"), Color("F2C230"), "a maroon sedan"], [Color("2E6B4F"), Color("8FB3D6"), "a green station wagon"],
	[Color("C8B48A"), Color("C0322A"), "a tan hatchback"], [Color("2B3A6A"), Color("F2F0E6"), "a blue coupe"],
	[Color("D9D2C2"), Color("2E8C8A"), "a white sedan"]]
## Where the traffic waits out of town (far out on the highway, off the map).
const HIDE_AT := Vector3(214.0, 0, 51.15)
const ROAD_IN_X := 210.0
const MAIL_HIDE := Vector3(214.0, 0, 57.0)    # (out past the edge of town, where the mail truck waits)
const MAIL_HOUR := 10.0


func setup(p_main: Node) -> void:
	main = p_main
	var lot := CivicBuilder.POLICE_LOT
	police = NpcVehicle.make(main, "police_car", "police", Vector3(lot.get_center().x, 0, lot.position.y + 4.6), 180.0)
	police.driver_key = "npc_walker_7"
	var bays: Array = main.room.get("fire_bays", [])
	engine1 = NpcVehicle.make(main, "fire_engine_1", "fire", bays[0] if bays.size() > 0 else Vector3(27.2, 0, -20.3), 180.0)
	engine1.driver_key = "npc_fire_captain"
	var engine2 := NpcVehicle.make(main, "fire_engine_2", "fire", bays[1] if bays.size() > 1 else Vector3(31.4, 0, -20.3), 180.0)
	milk = NpcVehicle.make(main, "milk_truck", "milk", Vector3(66.0, 0, 46.9), -90.0)
	milk.driver_key = "npc_walker_10"
	# The mail truck comes in on the highway every morning but Sunday (parked out of town otherwise)
	mail_truck = NpcVehicle.make(main, "mail_truck", "mail", MAIL_HIDE, -90.0)
	mail_truck.visible = false
	vehicles = [police, engine1, engine2, milk, mail_truck]
	# Everyday traffic: cars that come into town on the highway (Main Street east)
	for i in TRAFFIC.size():
		var t: Array = TRAFFIC[i]
		var car := NpcVehicle.make(main, "traffic_%d" % (i + 1), "car", HIDE_AT + Vector3(i * 6.0, 0, 0), -90.0, t[0], t[1])
		car.title = t[2]
		car.visible = false
		traffic.append(car)
		vehicles.append(car)
	for v in vehicles:
		(v as NpcVehicle).main = main


func _npc(k: String) -> Npc:
	return main.room["objects"].get(k) as Npc


func _now() -> int:
	return main.clock.unix_time


# ================================================================ every game minute (host)

func on_minute(h: float, wd: int) -> void:
	var minute := int(h * 60.0 + 0.5)
	# The fire engine's drill at 11:00 and 4:00
	if (minute == 11 * 60 or minute == 16 * 60) and _last_drill != minute and not engine1.moving:
		_last_drill = minute
		_fire_drill()
	# Officer Dwyer's patrols (when he isn't busy with a burglar)
	if minute in [10 * 60 + 15, 14 * 60 + 30, 20 * 60 + 40] and _last_patrol != minute and not police.moving \
			and burglar["state"] in ["none", "jailed"]:
		_last_patrol = minute
		_patrol()
	# The milk run, early in the morning (not on Sundays)
	if minute == 5 * 60 + 50 and wd != 0 and _last_milk != minute and not milk.moving:
		_last_milk = minute
		_milk_run()
	# The mail truck, late morning (no mail on Sundays)
	if minute == int(MAIL_HOUR * 60.0) and wd != 0 and _last_mail != _today() and not mail_truck.moving:
		_last_mail = _today()
		_mail_run()
	_burglar_minute(h)
	_traffic_minute(h)
	_mall_leavers()


# ================================================================ drivers

## The driver climbs in (they're not walking around while it's out).
func _board(v: NpcVehicle) -> void:
	var d := _npc(v.driver_key)
	if d:
		d.driving = true
		d.set_away(true)


## ...and climbs out next to it when it's parked again.
func _alight(v: NpcVehicle) -> void:
	var d := _npc(v.driver_key)
	if d == null:
		return
	d.driving = false
	var side := v.global_basis.x * (v.width / 2.0 + 0.7)
	d.set_away(false)
	d._place_raw(d._snap(v.global_position + side), v.rotation.y + PI)
	if d.role == "vendor":
		if d.spots.has("post"):
			d.shift = "to_post"
			d._walk_to(d.spots["post"][0])
	else:
		d._next_leg()


func _fire_drill() -> void:
	var v := engine1
	_board(v)
	v.set_siren(true)
	var r := NpcVehicle.leave_depot(v, "lincoln", -1.0)
	var x0: float = (r[r.size() - 1][0] as Vector3).x
	r.append_array(NpcVehicle.plan("lincoln", x0, -1.0, "maple", 70.0))
	r.append_array(NpcVehicle.plan("maple", 70.0, 1.0, "lincoln", v.home_pos.x - 4.0))
	r.append_array(NpcVehicle.enter_depot("lincoln", 1.0, v.home_pos))
	v.drive(r, func():
		v.set_siren(false)
		_alight(v))
	_say_all("You hear a siren: the fire engine's out on its daily drill!")


func _patrol() -> void:
	var v := police
	_board(v)
	var r := NpcVehicle.leave_depot(v, "lincoln", -1.0)
	var x0: float = (r[r.size() - 1][0] as Vector3).x
	r.append_array(NpcVehicle.plan("lincoln", x0, -1.0, "maple", 76.0))
	r.append_array(NpcVehicle.plan("maple", 76.0, 1.0, "main", 74.0))
	r.append_array(NpcVehicle.plan("main", 74.0, 1.0, "lincoln", v.home_pos.x - 4.0))
	r.append_array(NpcVehicle.enter_depot("lincoln", 1.0, v.home_pos))
	v.drive(r, func(): _alight(v))


## Mr. Delgado's milk truck: up Oak to Maple Street, a stop at every house, then back.
func _milk_run() -> void:
	var v := milk
	_board(v)
	var r := [[v.global_position, false]]
	r.append([Vector3(v.global_position.x - 3.0, 0, NpcVehicle.lane_z("main", -1.0)), false])
	r.append_array(NpcVehicle.plan("main", v.global_position.x - 3.0, -1.0, "maple", -12.0))
	v.stops = {}
	var xs := []
	for home in Sim.PAPER_HOUSES:
		var porch: SmartObject = main.room["objects"].get(home + "_porch")
		if porch:
			xs.append(porch.approach_point.x)
	xs.sort()
	for x in xs:
		if x > -12.0:
			r.append([Vector3(x, 0, NpcVehicle.lane_z("maple", 1.0)), false])
			v.stops[r.size() - 1] = 3.0
	r.append_array(NpcVehicle.plan("maple", float(xs[xs.size() - 1]) if not xs.is_empty() else 60.0, 1.0, "main", 64.0))
	r.append_array(NpcVehicle.uturn("main", 66.0, 1.0))
	r.append([v.home_pos, false])
	v.on_stop = func(_i: int):
		main.audio.play_at("milk_clink", v.global_position + Vector3(0, 1.0, 0), -6.0)
	# (indexes shift when corners are rounded, so the stops are matched after smoothing)
	v.drive(r, func():
		v.stops = {}
		v.rotation.y = v.home_yaw
		_alight(v))
	v.stops = _remap_stops(v, r)


## Find the smoothed path index of each stop point.
func _remap_stops(v: NpcVehicle, raw: Array) -> Dictionary:
	var out := {}
	for idx in v.stops:
		var p: Vector3 = raw[idx][0]
		for k in v._pts.size():
			if (v._pts[k][0] as Vector3).distance_to(p) < 0.05:
				out[k] = v.stops[idx]
				break
	return out


# ================================================================ chats between townsfolk

func _process(delta: float) -> void:
	if main == null:
		return
	_boomboxes()
	if main.net.is_client():
		return
	_chat_t += delta
	if _chat_t < 1.5:
		return
	_chat_t = 0.0
	var now := Time.get_ticks_msec()
	var free := []
	for n: Npc in main.npcs:
		if n.role in ["parent", "kid", "walker"] and not n.away and not n.lying and not n.held() and not n.driving \
				and not n.scripted.is_valid() and n.chat_cooldown < now:
			free.append(n)
	for i in free.size():
		for j in range(i + 1, free.size()):
			var a: Npc = free[i]
			var b: Npc = free[j]
			if a.chat_cooldown >= now or b.chat_cooldown >= now:
				continue
			if Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length() > 2.2 or randf() > 0.35:
				continue
			var kids: bool = (a.role == "kid" or bool(a.look.get("kid", false))) and (b.role == "kid" or bool(b.look.get("kid", false)))
			var lines: Array = (KID_CHATS if kids else CHATS)[randi() % (KID_CHATS if kids else CHATS).size()]
			var dur := 2.8 * lines.size() + 1.5
			a.chat_with(b, dur)
			b.chat_with(a, dur)
			for k in lines.size():
				var who: Npc = a if k % 2 == 0 else b
				var text: String = lines[k]
				get_tree().create_timer(0.2 + k * 2.8).timeout.connect(func():
					if is_instance_valid(who) and not who.away:
						npc_say(who, text))


## Someone in town says something (a word bubble everyone online sees).
func npc_say(who: Npc, text: String) -> void:
	who.say(text, 2.7)
	if main.net.is_host():
		main.net.send_npc_say(main.obj_keys.get(who, ""), text)


func _say_all(text: String) -> void:
	for s: Sim in main.sims.values():
		main._sim_notice(s, text)


func _say_home(home: String, text: String) -> void:
	for s: Sim in main.sims.values():
		if s.home == home:
			main._sim_notice(s, text)


# ================================================================ the burglar

func _burglar_minute(h: float) -> void:
	var st: String = burglar["state"]
	var thief := _npc("npc_burglar")
	if thief == null:
		return
	thief.set_meta("state", st)
	match st:
		"none":
			if _now() >= int(burglar["next_ok"]) and (h >= 23.0 or h < 4.0) and randf() < BURGLAR_CHANCE:
				start_burglary()
		"stealing":
			if _now() >= int(burglar["until"]):
				_flee(thief)
		"jailed":
			if _now() >= int(burglar["release"]):
				burglar["state"] = "none"
				burglar["next_ok"] = _now() + 2 * 86400
				thief.set_away(true)
				thief.end_script()
				_say_all("The Gazette says the burglar got out of jail today. Lock your doors!")


## A burglar heads for one of the players' houses (dev: --burglar).
func start_burglary(home := "") -> void:
	var thief := _npc("npc_burglar")
	if thief == null or burglar["state"] not in ["none"]:
		return
	if home == "":
		var homes := []
		for s: Sim in main.sims.values():
			homes.append(s.home)
		home = homes[randi() % homes.size()] if not homes.is_empty() else "jamie"
	var porch: SmartObject = main.room["objects"].get(home + "_porch")
	if porch == null:
		return
	burglar["state"] = "approach"
	burglar["home"] = home
	thief.set_meta("state", "approach")
	thief.remove_meta("running")
	_show_sack(thief, false)
	var edge := _nearest_edge(porch.approach_point)
	thief.set_away(false)
	thief._place_raw(thief._snap(edge), 0.0)
	thief.go_to(porch.approach_point, func(): _break_in(thief))


func _nearest_edge(p: Vector3) -> Vector3:
	var best: Vector3 = TownFolk.EDGES[0]
	for e: Vector3 in TownFolk.EDGES:
		if e.distance_to(p) < best.distance_to(p):
			best = e
	return best


func _break_in(thief: Npc) -> void:
	var home: String = burglar["home"]
	burglar["state"] = "inside"
	thief.set_meta("state", "inside")
	main.audio.play_at("glass_break", thief.global_position + Vector3(0, 1.2, 0), 0.0)
	if main.net.is_host():
		main.net.send_sound("glass_break", thief.global_position + Vector3(0, 1.2, 0), 0.0)
	# Anyone asleep in that house wakes up
	for s: Sim in main.sims.values():
		if s.home == home:
			var a := s.current_activity()
			if a and a.until_rested:
				s.cancel(0)
	_say_home(home, "CRASH! Breaking glass downstairs... A BURGLAR! Find him and stop him before he gets away!")
	var loot: SmartObject = main.room["objects"].get("tv" if home == "jamie" else home + "_tv")
	var to := loot.approach_point if loot else thief.global_position
	thief.go_to(to, func():
		burglar["state"] = "stealing"
		burglar["until"] = _now() + STEAL_MINUTES * 60
		thief.set_meta("state", "stealing")
		if loot:
			thief._yaw = atan2(-(loot.look_point - thief.global_position).x, -(loot.look_point - thief.global_position).z)
		npc_say(thief, "Heh heh... nice VCR."))


func _flee(thief: Npc) -> void:
	burglar["state"] = "fleeing"
	thief.set_meta("state", "fleeing")
	thief.set_meta("running", true)
	_show_sack(thief, true)
	npc_say(thief, "Gotta run!")
	thief.go_to(_nearest_edge(thief.global_position), func(): _escaped(thief))


func _escaped(thief: Npc) -> void:
	var home: String = burglar["home"]
	burglar["state"] = "none"
	burglar["next_ok"] = _now() + 86400
	thief.set_away(true)
	thief.end_script()
	thief.remove_meta("running")
	_say_home(home, "The burglar got away with the VCR! Mom calls the police. (Next time, catch him!)")


## A kid stops the burglar (called when "Stop the Burglar!" starts).
func catch_burglar(who: Sim) -> void:
	var thief := _npc("npc_burglar")
	if thief == null or burglar["state"] not in ["approach", "inside", "stealing", "fleeing"]:
		return
	burglar["state"] = "caught"
	thief.set_meta("state", "caught")
	thief.end_script()
	thief.scripted = func(): pass
	thief.remove_meta("running")
	thief.hold(who, 9999.0)
	thief.set_meta("hands_up", true)
	npc_say(thief, "Aw, nuts! You got me!")
	_say_all("%s caught the burglar! Officer Dwyer's on his way, sirens and all." % who.character_name)
	main.award_memory(who, "burglar")
	who.money += REWARD
	main._sim_notice(who, "The town gives you a $%d reward for catching the burglar! + $%.2f" % [int(REWARD), REWARD])
	burglar["hero"] = who.character_name
	_dispatch(thief)


## Officer Dwyer drives over (siren on), walks the burglar to the car, and drives him to jail.
func _dispatch(thief: Npc) -> void:
	var v := police
	if v.moving:
		v.park()
	v.global_position = v.home_pos
	v.rotation.y = v.home_yaw
	_board(v)
	v.set_siren(true)
	var target := thief.global_position
	var street := "maple" if target.z < 40.0 else "main"
	if target.z < -10.0:
		street = "lincoln"
	var side := -1.0 if target.z < float(NpcVehicle.STREETS[street]) else 1.0
	var r := NpcVehicle.leave_depot(v, "lincoln", -1.0)
	var x0: float = (r[r.size() - 1][0] as Vector3).x
	r.append_array(NpcVehicle.plan("lincoln", x0, -1.0, street, target.x))
	burglar["state"] = "escort"
	v.drive(r, func(): _officer_arrives(thief, street, side))


func _officer_arrives(thief: Npc, _street: String, _side: float) -> void:
	var v := police
	var off := _npc(v.driver_key)
	if off == null:
		return
	off.driving = false
	off.set_away(false)
	off._place_raw(off._snap(v.global_position + v.global_basis.x * (v.width / 2.0 + 0.7)), 0.0)
	var door := off.global_position
	off.go_to(thief.global_position + thief.global_basis.x * 0.9, func():
		npc_say(off, "You're under arrest, pal! You have the right to remain silent.")
		get_tree().create_timer(2.5).timeout.connect(func():
			thief.release()
			thief.remove_meta("hands_up")
			thief._hold_until = 0
			var arrived := [0]
			var both := func():
				arrived[0] += 1
				if arrived[0] == 2:
					_drive_to_jail(thief, off)
			off.go_to(door, both)
			thief.go_to(door + Vector3(0.6, 0, 0.6), both)))


func _drive_to_jail(thief: Npc, off: Npc) -> void:
	var v := police
	thief.set_away(true)
	off.driving = true
	off.set_away(true)
	v.set_siren(false)
	var street := NpcVehicle.street_at(v.global_position)
	if street == "":
		street = "maple"
	var r := [[v.global_position, false]]
	r.append_array(NpcVehicle.plan(street, v.global_position.x, 1.0, "lincoln", v.home_pos.x - 4.0))
	r.append_array(NpcVehicle.enter_depot("lincoln", 1.0, v.home_pos))
	v.drive(r, func():
		_alight(v)
		_lock_up(thief))


func _lock_up(thief: Npc) -> void:
	burglar["state"] = "jailed"
	burglar["release"] = _now() + SENTENCE_DAYS * 86400
	thief.set_meta("state", "jailed")
	_jail(thief)
	_say_all("Officer Dwyer: \"This burglar's going away for %d days, thanks to %s!\" (Visit him at the police station.)" %
		[SENTENCE_DAYS, burglar.get("hero", "a brave kid")])


## Put the burglar in his cell (also when a saved game is loaded).
func _jail(thief: Npc) -> void:
	thief.end_script()
	thief.scripted = func(): pass       # (he stays put)
	_show_sack(thief, false)
	thief.set_away(false)
	thief.place(CivicBuilder.CELL_SPOT, 180.0)
	thief.set_meta("state", "jailed")


func _show_sack(thief: Npc, on: bool) -> void:
	var sack: Node3D = thief.get_node_or_null("Sack")
	if sack == null:
		sack = Node3D.new()
		sack.name = "Sack"
		thief.add_child(sack)
		RoomBuilder.box(sack, Vector3(0.45, 0.55, 0.35), Vector3(0, 1.2, 0.32), Color("D8C890"))
		RoomBuilder.box(sack, Vector3(0.12, 0.12, 0.12), Vector3(0, 1.52, 0.32), Color("B8A870"))
		var l := Label3D.new()
		l.text = "$"
		l.font_size = 64
		l.pixel_size = 0.004
		l.modulate = Color("2E6B4F")
		l.position = Vector3(0, 1.2, 0.495)
		l.double_sided = true
		sack.add_child(l)
	sack.visible = on


## After everyone's been put where they belong at this hour: the burglar stays in jail.
func resettle() -> void:
	_settle_mail()
	var thief := _npc("npc_burglar")
	if thief and burglar["state"] == "jailed":
		_jail(thief)


# ================================================================ the mail

func _today() -> int:
	return int(main.clock.unix_time / 86400)


## Up Maple Street on the south side, back down the north side: a stop at every mailbox.
func _mail_run() -> void:
	var v := mail_truck
	var south := []      # [x, home] (the eastbound lane is on the south side)
	var north := []
	for k in main.room["objects"]:
		var o: SmartObject = main.room["objects"][k]
		if o.kind == "mailbox" and o.home != "" and o.home != "town":
			var at := o.look_point
			(south if at.z > float(NpcVehicle.STREETS["maple"]) else north).append([at.x, o.home])
	south.sort_custom(func(a, b): return a[0] < b[0])
	north.sort_custom(func(a, b): return a[0] > b[0])
	if south.is_empty() and north.is_empty():
		return
	var xs: Array = south.map(func(e): return e[0]) + north.map(func(e): return e[0])
	var x0: float = xs.min() - 4.0
	var x1: float = xs.max() + 4.0
	v.global_position = Vector3(ROAD_IN_X, 0, NpcVehicle.lane_z("main", -1.0))
	v.rotation.y = -PI / 2.0
	v.visible = true
	var r := [[v.global_position, false]]
	r.append_array(NpcVehicle.plan("main", ROAD_IN_X, -1.0, "maple", x0))
	var homes := {}       # route index -> home
	for e in south:
		r.append([Vector3(float(e[0]), 0, NpcVehicle.lane_z("maple", 1.0)), false])
		homes[r.size() - 1] = e[1]
	r.append([Vector3(x1, 0, NpcVehicle.lane_z("maple", 1.0)), false])
	r.append_array(NpcVehicle.uturn("maple", x1, 1.0))
	for e in north:
		r.append([Vector3(float(e[0]), 0, NpcVehicle.lane_z("maple", -1.0)), false])
		homes[r.size() - 1] = e[1]
	r.append_array(NpcVehicle.plan("maple", x0, -1.0, "main", ROAD_IN_X))
	v.stops = {}
	for i in homes:
		v.stops[i] = 4.0
	v.on_stop = func(i: int):
		var home := String(v.get_meta("stop_homes", {}).get(i, ""))
		if home != "":
			_mail_day[home] = _today()
			_mail_taken.erase(home)
			main.audio.play_at("mailbox", v.global_position + Vector3(0, 1.0, 0), -8.0)
	v.drive(r, func():
		v.park()
		v.visible = false
		v.stops = {}
		v.global_position = MAIL_HIDE
		# (anyone it somehow missed gets their mail anyway)
		for e in south + north:
			if int(_mail_day.get(e[1], -1)) != _today():
				_mail_day[e[1]] = _today())
	var raw_stops := v.stops.duplicate()
	v.stops = _remap_stops(v, r)
	var stop_homes := {}
	for raw_i in raw_stops:
		var p: Vector3 = r[raw_i][0]
		for k in v._pts.size():
			if (v._pts[k][0] as Vector3).distance_to(p) < 0.05:
				stop_homes[k] = homes[raw_i]
				break
	v.set_meta("stop_homes", stop_homes)


## Can somebody get the mail at this house right now? "" = yes, otherwise why not.
func mail_status(home: String) -> String:
	if main.clock.weekday() == 0:
		return "There's no mail on Sundays."
	if int(_mail_day.get(home, -1)) != _today():
		return "The mail hasn't come yet today. (The mail truck comes by late in the morning.)"
	if int(_mail_taken.get(home, -1)) == _today():
		return "Somebody already got today's mail."
	return ""


func mail_taken(home: String) -> void:
	_mail_taken[home] = _today()


## A new or loaded game, or a jump in time: if it's past the mail run today, the mail has come.
func _settle_mail() -> void:
	if main.clock.weekday() != 0 and main.clock.hour_float() >= MAIL_HOUR + 2.5 and not mail_truck.moving:
		_last_mail = _today()
		for k in main.room["objects"]:
			var o: SmartObject = main.room["objects"][k]
			if o.kind == "mailbox" and o.home != "" and int(_mail_day.get(o.home, -1)) != _today():
				_mail_day[o.home] = _today()


# ================================================================ saving

func save_state() -> Dictionary:
	var st: String = burglar["state"]
	if st != "jailed":
		st = "none"
	return {"state": st, "release": burglar["release"], "next_ok": burglar["next_ok"], "hero": burglar.get("hero", ""),
		"mail_day": _mail_day, "mail_taken": _mail_taken}


func load_state(d: Dictionary) -> void:
	burglar["state"] = String(d.get("state", "none"))
	burglar["release"] = int(d.get("release", 0))
	burglar["next_ok"] = int(d.get("next_ok", 0))
	burglar["hero"] = String(d.get("hero", ""))
	_mail_day = {}
	_mail_taken = {}
	for k in d.get("mail_day", {}):
		_mail_day[String(k)] = int(d["mail_day"][k])
	for k in d.get("mail_taken", {}):
		_mail_taken[String(k)] = int(d["mail_taken"][k])
	var thief := _npc("npc_burglar")
	if thief == null:
		return
	if burglar["state"] == "jailed":
		_jail(thief)
	else:
		thief.end_script()
		thief.set_away(true)



# ================================================================ everyday traffic

## Now and then a car comes into town: through the Rocket Burger drive-thru, to
## the mall to shop for a while, or just for a drive around the block.
func _traffic_minute(h: float) -> void:
	if h < 6.5 or h > 22.5:
		return
	var busy := 0
	var idle: Array = []
	for car: NpcVehicle in traffic:
		if car.moving or car.visible:
			busy += 1
		else:
			idle.append(car)
	if idle.is_empty() or busy >= 3 or randf() > 0.09:
		return
	# (wait until the last car to come in has pulled away, so they don't pile up at the edge of town)
	var entry := Vector3(ROAD_IN_X, 0, NpcVehicle.lane_z("main", -1.0))
	for other: NpcVehicle in traffic + vehicles:
		if other.visible and other.global_position.distance_to(entry) < 12.0:
			return
	var car: NpcVehicle = idle[randi() % idle.size()]
	var roll := randf()
	var in_line := traffic.any(func(c: NpcVehicle): return c.has_meta("drive_thru"))
	if main.driving != null and EastBuilder.BURGER_LOT.grow(4.0).has_point(Vector2(main.driving.global_position.x, main.driving.global_position.z)):
		in_line = true       # (a player's going through the drive-thru)
	if roll < 0.45 and h >= 7.0 and h < 22.8 and not in_line:
		_drive_thru(car)     # (one car in the drive-thru lane at a time: it's only one car long between the menu and the window)
	elif roll < 0.75 and h >= 10.0 and h < 20.0:
		_to_mall(car)
	else:
		_cruise(car)


func _arrive(car: NpcVehicle) -> Array:
	car.global_position = Vector3(ROAD_IN_X, 0, NpcVehicle.lane_z("main", -1.0))
	car.rotation.y = -PI / 2.0
	car.visible = true
	return [[car.global_position, false]]


func _leave(car: NpcVehicle) -> void:
	car.remove_meta("drive_thru")
	car.park()
	car.visible = false
	car.stops = {}
	car.global_position = HIDE_AT + Vector3(traffic.find(car) * 6.0, 0, 0)


func _drive_thru(car: NpcVehicle) -> void:
	var w := NpcVehicle.lane_z("main", -1.0)
	var e := NpcVehicle.lane_z("main", 1.0)
	car.set_meta("drive_thru", true)
	var r := _arrive(car)
	var inx := EastBuilder.DT_IN_X
	var outx := EastBuilder.DT_OUT_X
	r.append([Vector3(inx + 4.0, 0, w), false])
	r.append([Vector3(inx, 0, w - 2.6), false])
	r.append([Vector3(inx, 0, EastBuilder.DT_BACK_Z), false])
	r.append([Vector3(outx, 0, EastBuilder.DT_BACK_Z), false])
	r.append([EastBuilder.DT_MENU, false])
	var menu_i := r.size() - 1
	r.append([EastBuilder.DT_WINDOW, false])
	var win_i := r.size() - 1
	r.append([Vector3(outx, 0, DowntownBuilder.Z0 - 2.0), false])
	r.append([Vector3(outx + 3.0, 0, e), false])
	r.append([Vector3(ROAD_IN_X, 0, e), false])
	car.stops = {menu_i: 5.0, win_i: 7.0}
	car.on_stop = func(i: int):
		if not car.stops.is_empty() and i == car.stops.keys().min():
			Props.bubble(car, ["One Rocket Meal, please!", "Two burgers and a shake!", "Fries. Lots of fries."][randi() % 3], 2.8, 2.2)
		else:
			main.audio.play_at("cash_register", car.global_position + Vector3(0, 1.0, 0), -10.0)
			var cook := _npc("npc_burger_cook")
			if cook and not cook.away:
				npc_say(cook, ["Here ya go! Have a stellar day!", "Thanks for flying Rocket Burger!", "Napkins are in the bag!"][randi() % 3])
	car.drive(r, func(): _leave(car))
	car.stops = _remap_stops(car, r)


func _cruise(car: NpcVehicle) -> void:
	var r := _arrive(car)
	var turn := randf_range(40.0, 120.0)
	r.append_array(NpcVehicle.plan("main", ROAD_IN_X, -1.0, "maple", turn))
	r.append_array(NpcVehicle.uturn("maple", turn, 1.0))
	r.append_array(NpcVehicle.plan("maple", turn, -1.0, "main", ROAD_IN_X))
	car.drive(r, func(): _leave(car))


func _to_mall(car: NpcVehicle) -> void:
	var spots: Array = main.room.get("mall_spots", [])
	var free := []
	for i in spots.size():
		if not _mall_spots_taken.has(i):
			free.append(i)
	if free.is_empty():
		_cruise(car)
		return
	var si: int = free[randi() % free.size()]
	_mall_spots_taken[si] = car.key
	var spot: Vector3 = spots[si][0]
	var aisle := EastBuilder.LOT.get_center().x
	var w := NpcVehicle.lane_z("main", -1.0)
	var r := _arrive(car)
	# (the aisle has two lanes: in on the west side, out on the east side, so cars don't meet head-on)
	var lane_in := aisle - 1.2
	r.append([Vector3(aisle + 5.0, 0, w), false])
	r.append([Vector3(lane_in, 0, DowntownBuilder.Z1 + 1.0), false])
	r.append([Vector3(lane_in, 0, spot.z), false])
	r.append([Vector3(spot.x + signf(aisle - spot.x) * 0.2, 0, spot.z), false])
	car.drive(r, func():
		car.set_meta("shop_until", _now() + randi_range(30, 100) * 60)
		car.set_meta("spot", si))


## (every minute) Cars at the mall head home when they're done shopping.
func _mall_leavers() -> void:
	for car: NpcVehicle in traffic:
		if car.moving or not car.has_meta("shop_until") or _now() < int(car.get_meta("shop_until")):
			continue
		var si := int(car.get_meta("spot"))
		car.remove_meta("shop_until")
		var aisle := EastBuilder.LOT.get_center().x
		var p := car.global_position
		var e := NpcVehicle.lane_z("main", 1.0)
		var lane_out := aisle + 1.2
		var r := [[p, false], [Vector3(aisle + signf(p.x - aisle) * 0.6, 0, p.z + 1.4), true], [Vector3(lane_out, 0, p.z - 2.5), false],
			[Vector3(lane_out, 0, DowntownBuilder.Z1 + 0.6), false], [Vector3(aisle + 4.0, 0, e), false], [Vector3(ROAD_IN_X, 0, e), false]]
		car.drive(r, func():
			_mall_spots_taken.erase(si)
			_leave(car))
		return


## Boombox music follows the kids carrying them.
func _boomboxes() -> void:
	for n: Npc in main.npcs:
		if not n.has_meta("boombox"):
			continue
		var key := "boombox_" + String(n.name)
		if n.away:
			if n.has_meta("playing"):
				n.remove_meta("playing")
				main.audio.stop_loop(key, 0.5)
			continue
		var at := n.global_position + Vector3(0, 1.4, 0)
		if not n.has_meta("playing"):
			n.set_meta("playing", true)
			main.audio.start_loop(key, "boombox", at, -6.0, 0.5)
		else:
			main.audio.move_loop(key, at)
