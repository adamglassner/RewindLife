extends Node3D
## Wires the systems together:
##   GameClock ticks -> Sim updates needs and activities -> HUD and lighting follow.

const POST_SHADER := """
shader_type canvas_item;
// The "memory look": warm grade, soft vignette, light film grain.
// `memory` briefly adds soft focus and a faded-print tint during Memory Moments.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float memory : hint_range(0.0, 1.0) = 0.0;
uniform float grain = 0.035;
uniform bool enabled = true;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_tex, uv).rgb;
	vec3 blur = textureLod(screen_tex, uv, 3.0).rgb;
	col = mix(col, blur, memory * 0.55);
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col *= mix(vec3(1.0), vec3(1.05, 0.99, 0.92), 0.7);          // warm highlights
	col += vec3(0.045, 0.012, 0.04) * (1.0 - l) * 0.7;            // plum shadows
	col = mix(col, vec3(l) * vec3(1.12, 1.0, 0.82) + 0.05, memory * 0.35);
	col += blur * memory * 0.22;                                  // halation
	vec2 d = uv - 0.5;
	col *= mix(0.7, 1.0, smoothstep(0.85, 0.3, length(d * vec2(1.0, 0.8))));
	col += (rand(uv * 900.0 + TIME) - 0.5) * grain;
	COLOR = enabled ? vec4(col, 1.0) : vec4(texture(screen_tex, uv).rgb, 1.0);
}
"""

var clock: GameClock
var audio: GameAudio
var sim: Sim
var rig: CameraRig
var hud: Hud
var room: Dictionary
var env: Environment
var sun: DirectionalLight3D
var post_mat: ShaderMaterial
var objects: Array = []
var sims := {}                     # slot -> Sim (everyone in the game)
var net: Net
var obj_keys := {}                 # SmartObject -> its key in room["objects"]
var _tv_users := {}                # TV SmartObject -> how many Sims are watching it
var _tv_screens := {}              # TV SmartObject -> [SubViewport, TvShow, the picture panel] (what's on)
var _glow_users := {}              # material -> how many Sims have it lit
var _duckers := 0                  # TVs and record players playing (house music turns down)
var hovered: SmartObject = null
var last_speed := 1
var tv_on := false
var diary := Diary.new()
var _diary_speed := 1
var _current_room := ""
var lights_out := false
var sky_mat: ProceduralSkyMaterial
var _sky_mode := -1
var _outdoors := false
var menus: Menus
## Tests and dev shots set this before adding the scene, to skip the title screen.
var skip_title := false
var in_title := false
var driving: Car = null            # the car the player is driving, if any
var _pre_drive_cam := 0
var _menu_speed := 1
var _cursor := Vector2(-1, -1)     # the gamepad cursor in the House Cam
var _glow_base := {}               # material -> its normal glow, while an activity lights it up
var _start_time := 0
var holidays: Holidays
var customizer: Customizer
var chat: ChatBox
var npcs: Array = []               # parents, the lemonade kid, shopkeepers and folks out for a walk
var town_life: TownLife            # the police car, fire engine and milk truck, chats, the burglar
var split: SplitScreen             # two players, one screen (needs two controllers)
var local_store := {}              # saved progress of the other kids (for Player 2)
var seasons: Seasons               # snow, fall leaves, rainy days, sprinklers
var overcast := 0.0                # 0..1: how gray the sky is today (Seasons sets it)
var portals: Array = []            # the doors up to the attics and down to the basements (and back)


func _ready() -> void:
	randomize()
	Settings.load_settings()
	GameAudio.ensure_buses()
	Settings.apply()
	InputSetup.setup()
	clock = GameClock.new()
	add_child(clock)
	_start_time = clock.unix_time
	audio = GameAudio.new()
	add_child(audio)
	clock.speed_changed.connect(func(level: int): audio.set_paused(level == 0))

	Families.pick_new()
	room = RoomBuilder.build(self)
	for k in ["fridge", "phone", "tv", "bed", "couch", "desk", "stereo", "dresser", "mailbox"]:
		(room["objects"][k] as SmartObject).kind = k
	npcs = TownFolk.spawn(self, room)
	town_life = TownLife.new()
	town_life.name = "TownLife"
	add_child(town_life)
	town_life.setup(self)
	if room.has("bowling_lanes"):
		(room["bowling_lanes"] as BowlingLanes).main = self
	for n: Npc in npcs:
		n.staff_door.connect(_on_staff_door)
	_setup_shop_doors()
	_hang_wall_decor()
	seasons = Seasons.new()
	add_child(seasons)
	seasons.setup(self)
	holidays = Holidays.new()
	add_child(holidays)
	holidays.setup(self)
	Content.fill(room["objects"])
	Chores.apply(room["objects"])
	objects = (room["objects"] as Dictionary).values()
	for o: SmartObject in objects:
		if o.portal_to != null:
			portals.append(o)
	_tag_objects()
	# (after _tag_objects: Jamie's things know they're Jamie's now)
	Catalog.apply(room["objects"])
	Catalog.add_desk_models(room["objects"])
	Phonebook.apply(room["objects"])
	Holidays.add_activities(room["objects"])
	# Every porch: knock on the door (somebody might let you in)
	for k in room["objects"]:
		var po: SmartObject = room["objects"][k]
		if po.kind == "porch" and po.home != "" and po.home != "town":
			var ka := Activity.make("Knock on the Door", 1, {"social": 4.0}, "reach")
			ka.sound = "knock"
			ka.autonomous = false
			ka.talk = "knock"
			po.activities.push_front(ka)
	_setup_house_doors()
	_setup_drive_thru()
	# Everything you do at a mailbox needs the mail to have come (and there's none on Sundays)
	for k in room["objects"]:
		var mo: SmartObject = room["objects"][k]
		if mo.kind == "mailbox":
			for ma: Activity in mo.activities:
				ma.needs_mail = true

	net = Net.new()
	net.name = "Net"
	add_child(net)
	net.main = self

	sim = add_sim(0, false)
	relabel()

	rig = CameraRig.new()
	add_child(rig)
	rig.setup(sim)

	_setup_environment()
	_setup_post()
	var critters := Critters.new()
	critters.name = "Critters"
	add_child(critters)
	critters.setup(self)

	hud = Hud.new()
	add_child(hud)
	hud.setup(clock, sim)
	split = SplitScreen.new()
	split.name = "SplitScreen"
	add_child(split)
	split.setup(self)

	clock.minute_passed.connect(_on_minute)
	clock.hour_changed.connect(func(_h: int):
		holidays.refresh()
		seasons.refresh())
	holidays.refresh()
	seasons.refresh()
	hud.speed_requested.connect(func(level: int):
		if not net.is_online():
			clock.set_speed(level))
	hud.camera_requested.connect(func(m: int):
		if driving == null:
			rig.set_mode(m))
	hud.free_will_toggled.connect(_set_free_will)
	hud.music_toggled.connect(audio.set_music)
	hud.activity_chosen.connect(_choose)
	hud.emote_chosen.connect(do_emote)
	hud.cancel_requested.connect(func(i: int):
		if driving and i == 0:
			_try_exit_car()
		else:
			_cancel(i))
	hud.menu_closed.connect(_on_menu_closed)
	hud.diary_saved.connect(_on_diary_saved)
	hud.diary_closed.connect(_on_diary_closed)
	diary.load_entries()
	rig.mode_changed.connect(_on_camera_mode)
	_on_camera_mode(rig.mode)
	_update_lighting()
	# The arcade is never quiet.
	var arc := DowntownBuilder.shop_rect("arcade")
	audio.start_loop("arcade_room", "arcade_game", Vector3(arc.get_center().x, 1.5, arc.get_center().y), -22.0)
	for c in room.get("cars", []):
		(c as Car).hit_someone.connect(func(who: Node3D): ouch(who))
		(c as Car).bumped.connect(func(strength: float):
			audio.play_at("car_bump", (c as Car).global_position + Vector3(0, 0.6, 0), clampf(-12.0 + strength, -10.0, 0.0)))

	menus = Menus.new()
	add_child(menus)
	menus.sound.connect(func(n: String): audio.play_ui(n, -8.0))
	menus.new_game_pressed.connect(_on_new_game)
	menus.continue_pressed.connect(_on_continue)
	menus.resume_pressed.connect(_resume)
	menus.save_pressed.connect(func():
		hud.notify(("Online world saved." if net.is_online() else "Game saved.") if SaveGame.save(self) \
			else "Couldn't save the game.")
		_resume())
	menus.quit_to_title_pressed.connect(func():
		split.stop()
		if not net.is_client():
			SaveGame.save(self)
		net.leave()
		get_tree().reload_current_scene())
	menus.quit_pressed.connect(func():
		if not in_title and not net.is_client():
			SaveGame.save(self)
		net.leave()
		get_tree().quit())
	# DEBUG menu (pause menu, password "password"): change the date or your money
	menus.get_debug_state = func() -> Dictionary:
		var hf := clock.hour_float()
		return {"year": clock.year(), "month": clock.month(), "day": clock.day(), "money": sim.money,
			"hour": int(hf), "minute": int(round((hf - int(hf)) * 60.0)) % 60}
	menus.debug_set_time.connect(_debug_set_time)
	menus.debug_set_date.connect(_debug_set_date)
	menus.debug_set_money.connect(func(amount: float):
		sim.money = snappedf(amount, 0.01)
		hud.set_money(sim.money))
	menus.local_coop_pressed.connect(func():
		_resume()
		if split.active:
			split.stop("Back to one player.")
		else:
			split.start())
	menus.host_pressed.connect(_on_host)
	menus.join_pressed.connect(_on_join)
	menus.character_chosen.connect(_on_character_chosen)
	menus.characters_back.connect(_on_characters_back)
	customizer = Customizer.new()
	add_child(customizer)
	customizer.setup(menus)
	customizer.sound.connect(func(n: String): audio.play_ui(n, -8.0))
	customizer.done.connect(_on_customized)
	customizer.cancelled.connect(_on_customize_cancelled)
	chat = ChatBox.new()
	add_child(chat)
	chat.setup(menus.font)
	chat.sent.connect(func(t: String): net.send_chat(t))
	chat.closed.connect(func(): rig.input_enabled = true)
	net.join_failed.connect(func(reason: String):
		net.leave()
		menus.set_online_status(reason))
	net.lost.connect(func(reason: String):
		Net.last_message = reason
		net.leave()
		get_tree().reload_current_scene.call_deferred())

	# The town's look comes from the asset files (assets/scenes): anything edited there in the
	# Godot editor goes onto the town now (see asset_library.gd)
	var t0 := Time.get_ticks_msec()
	var n_assets := AssetLibrary.apply(self, "--all-assets" in OS.get_cmdline_user_args())
	if n_assets > 0:
		print("Assets applied in %d ms" % (Time.get_ticks_msec() - t0))

	if not skip_title and not _has_dev_args():
		_show_title()
	_dev_hooks()


# ================================================================ people

## Mark what each object is and whose house it's in.
func _tag_objects() -> void:
	var objs: Dictionary = room["objects"]
	for k in objs:
		obj_keys[objs[k]] = k
	for k in ["fridge", "phone", "tv", "bed", "couch", "desk", "stereo", "dresser", "mailbox"]:
		(objs[k] as SmartObject).kind = k
	(objs["tv"] as SmartObject).set_meta("screen_mat", room["screen_mat"])
	(objs["tv"] as SmartObject).set_meta("tv_light", room["tv_light"])
	_set_tv(objs["tv"], false)
	var ours := ["jamie|Living Room", "jamie|Hallway", "jamie|Kid Room", "jamie|Kitchen"]
	for o: SmartObject in objects:
		if o.home != "" or o is Car:
			continue
		for rn in ours:
			if (room["rooms"][rn] as Rect2).grow(0.3).has_point(Vector2(o.approach_point.x, o.approach_point.z)):
				o.home = "jamie"
				break


## Bring a character into the world. `puppet` = the host runs them (we're online, not the host).
func add_sim(slot: int, puppet: bool) -> Sim:
	if sims.has(slot):
		return sims[slot]
	var s := Sim.new()
	s.setup(room["grid"], clock, objects, slot)
	s.grids = [room["grid"], room["grid1"]]
	s.portals = portals
	s.puppet = puppet
	add_child(s)
	var ch: Dictionary = Sim.CHARACTERS[slot]
	s.global_position = ch["spawn"]
	s.rotation.y = deg_to_rad(float(ch["yaw"]))
	s._face_yaw = s.rotation.y
	s.net_pos = s.global_position
	s.net_yaw = s._face_yaw
	s.activity_started.connect(func(a: Activity, o: SmartObject): _on_activity_started(a, o, s))
	s.activity_finished.connect(func(a: Activity, o: SmartObject): _on_activity_finished(a, o, s))
	s.notice.connect(func(t: String): _sim_notice(s, t))
	s.delivery_ordered.connect(func(kind: String): _order_delivery(s, kind))
	s.teleported.connect(func(): _on_teleported(s))
	s.bike_event.connect(func(what: String): _on_bike_event(s, what))
	s.why_unreachable = _why_unreachable
	s.mail_status = func(h: String) -> String: return town_life.mail_status(h)
	s.entry_check = func(p: Vector3) -> String: return _entry_check(s, p)
	_update_door_access.call_deferred(s)
	s.bought.connect(func(id: String): _on_bought(s, id))
	s.called.connect(func(h: String): _on_called(s, h))
	s.paid.connect(func(_amount: float, reason: String):
		if reason == "paper":
			award_memory(s, "paperroute")
		elif reason == "allowance":
			award_memory(s, "allowance"))
	sims[slot] = s
	if slot != 0 or sim != null:
		s.set_view_mode(false, true)
	return s


func remove_sim(slot: int) -> void:
	if not sims.has(slot) or sims[slot] == sim:
		return
	var s: Sim = sims[slot]
	if not s.current.is_empty():
		s.cancel(0)
	for o: SmartObject in objects:
		if o.user == s:
			o.user = null
	for c in room.get("cars", []):
		if (c as Car).driver == s:
			(c as Car).driver = null
			(c as Car).set_driving(false, false)
			park_car(c, true)
	sims.erase(slot)
	s.queue_free()


static func dist_xz(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Names depend on whose house it is: at home it's "Mom" and "Mom & Dad's Room",
## at a friend's it's "Mrs. Nguyen" and "Mr. & Mrs. Nguyen's Room".
func relabel() -> void:
	if sim == null:
		return
	for n: Npc in npcs:
		if n.role == "parent":
			var mom := bool(n.get_meta("mom", true))
			var own := n.home == sim.home
			n.set_title(Families.parent_name(n.home, mom, sim.home),
				"" if own else "%s's %s" % [Families.kid_name(n.home), "mom" if mom else "dad"], own)
	for k in room["objects"]:
		var o: SmartObject = room["objects"][k]
		if o.kind == "parents_bed":
			o.display_name = Families.parents_bed(o.home, sim.home)
	_current_room = ""


## How high the floor is under a point: the attics and basements are built
## underground (see InteriorBuilder), everything else is at ground level.
static func floor_y(p: Vector3) -> float:
	return RoomBuilder.INTERIOR_Y if p.y < RoomBuilder.INTERIOR_Y * 0.5 else 0.0


func cam_point(p: Vector3) -> Vector3:
	return Vector3(p.x, floor_y(p) + 0.4, p.z)


## Someone went up to an attic or down to a basement (or came back).
func _on_teleported(s: Sim) -> void:
	audio.play_at("door_open", s.global_position + Vector3(0, 1.0, 0), -6.0)
	if s != sim:
		return
	_fade()
	rig.snap_to(cam_point(s.global_position))
	_current_room = ""
	if rig.mode != CameraRig.Mode.HOUSE:
		rig.face_yaw(s.rotation.y)


var _fade_rect: ColorRect


## A quick dip to black (going up or down the stairs).
func _fade() -> void:
	if _fade_rect == null:
		var layer := CanvasLayer.new()
		layer.layer = 2
		add_child(layer)
		_fade_rect = ColorRect.new()
		_fade_rect.color = Color(0.05, 0.03, 0.07, 0.0)
		_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_fade_rect)
	_fade_rect.anchor_right = 0.5 if split.active else 1.0
	_fade_rect.offset_right = 0
	_fade_rect.color.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_property(_fade_rect, "color:a", 0.0, 0.45)


## Swap which character this computer controls (online players).
func bind_local(s: Sim) -> void:
	if sim and sim != s:
		sim.set_view_mode(false, true)
	sim = s
	rig.sim = s
	hud.set_sim(s)
	relabel()
	rig.set_mode(rig.mode)
	rig.target = cam_point(s.global_position)
	_current_room = ""


func _sim_notice(s: Sim, text: String) -> void:
	if s == sim:
		hud.notify(text)
	elif split.is_p2(s):
		split.notify(text)
	elif net.is_host():
		net.send_notice(s.slot, text)


## The player picked something to do.
func _choose(obj: SmartObject, act: Activity) -> void:
	if obj == _dt_speaker:
		_drive_thru_order(act)
		return
	if net.is_client():
		net.rq_enqueue.rpc_id(1, obj_keys.get(obj, ""), obj.activities.find(act))
	else:
		sim.enqueue(obj, act)


func _walk_to(p: Vector3) -> void:
	if net.is_client():
		net.rq_walk.rpc_id(1, p.x, p.z)
	else:
		sim.walk_here(p)


func _cancel(i: int) -> void:
	if net.is_client():
		net.rq_cancel.rpc_id(1, i)
	else:
		sim.cancel(i)


func _set_free_will(on: bool) -> void:
	sim.free_will = on
	if net.is_client():
		net.rq_free_will.rpc_id(1, on)


# ================================================================ pizza delivery

var _deliveries: Array = []        # [{"home", "due"}]


func _order_delivery(who: Sim, kind: String) -> void:
	if net.is_client() or kind != "pizza":
		return
	_deliveries.append({"home": who.home, "due": clock.unix_time + 30 * 60})


func _check_deliveries() -> void:
	for d in _deliveries.duplicate():
		if clock.unix_time < int(d["due"]):
			continue
		_deliveries.erase(d)
		var home: String = d["home"]
		set_pizza(home, true)
		var door := Vector3(RoomBuilder.FRONT_DOOR_X, 1.2, RoomBuilder.D)
		var porch: SmartObject = room["objects"].get(home + "_porch")
		if porch:
			door = porch.look_point
		audio.play_at("doorbell", door, 0.0)
		if net.is_host():
			net.ring_doorbell.rpc(door)
		for s: Sim in sims.values():
			if s.home == home:
				_sim_notice(s, "Ding-dong! The pizza's here. It's waiting on the table.")


## Show (or clear away) the delivered pizza box on a home's table.
func set_pizza(home: String, on: bool) -> void:
	var key := "pizza_box" if home == "jamie" else home + "_pizza_box"
	var box: SmartObject = room["objects"].get(key)
	if box == null:
		return
	box.visible = on
	box.collision_layer = 1 if on else 0
	if net.is_host():
		net.pizza.rpc(home, on)


## Overnight time speeds up only when everyone is asleep.
func _update_boost() -> void:
	if net.is_client():
		return
	var all_asleep := not sims.is_empty()
	for s: Sim in sims.values():
		var a := s.current_activity()
		if a == null or not a.until_rested:
			all_asleep = false
	clock.boost = 10.0 if all_asleep else 1.0


# ================================================================ title, pause, saving

func _has_dev_args() -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a != "--title" and not a.begins_with("--wait") and not a.begins_with("--shot"):
			return true
	return false


## The title screen: the game waits (time stopped) while the camera circles the
## neighborhood at golden hour.
func _show_title() -> void:
	in_title = true
	clock.set_speed(0)
	clock.unix_time = _start_time + int(10.4 * 3600)   # 6:24 PM for the backdrop
	_update_lighting()
	hud.visible = false
	rig.set_mode(CameraRig.Mode.TITLE)
	rig.target = Vector3(9.0, 0.0, 5.0)
	rig.house_dist = 24.0
	rig.house_pitch = deg_to_rad(28.0)
	rig.house_yaw = deg_to_rad(20.0)
	_current_room = "(fixed)"
	settle_npcs()
	menus.show_title(SaveGame.exists())
	if Net.last_message != "":
		menus.show_message(Net.last_message)
		Net.last_message = ""


func _start_game() -> void:
	in_title = false
	menus.hide_menus()
	hud.visible = true
	clock.unix_time = _start_time
	rig.house_dist = 10.5
	rig.house_pitch = deg_to_rad(46.0)
	rig.house_yaw = deg_to_rad(40.0)
	rig.target = cam_point(sim.global_position)
	rig.set_mode(CameraRig.Mode.HOUSE)
	_current_room = ""
	clock.set_speed(1)
	settle_npcs()


func settle_npcs() -> void:
	Npc.month_now = clock.month()
	TownFolk.settle(npcs, clock.hour_float(), clock.weekday())
	if town_life:
		town_life.resettle()     # (puts a jailed burglar back in his cell)
	_update_shop_doors(true)
	holidays.refresh()
	seasons.refresh()
	update_computers()      # (a loaded game shows the computers you bought right away)


## NEW GAME: first, how does Jamie look?
func _on_new_game() -> void:
	_pending = "new"
	_pending_slot = 0
	menus.visible = false
	customizer.open(Sim.CHARACTERS[0]["look"], "WHO'S JAMIE?",
		"Saturday, June 14, 1986. Summer vacation starts now! Pick Jamie's look.", true)


func _begin_new_game(look: Dictionary) -> void:
	SaveGame.delete()
	Families.pick_new()
	relabel()
	_start_game()
	sim.set_look(look)
	_update_lighting()
	hud.refresh_clock()
	hud.notify("Saturday, June 14, 1986. Summer vacation starts now!")


# ---------------------------------------------------------------- picking who to play, and how they look

var _pending := ""        # what the look screen is for: "new", "host", "join", "ingame"
var _pending_slot := 0
var _pending_new_world := false
var _choice_looks := {}


func _on_customized(look: Dictionary) -> void:
	match _pending:
		"new":
			_begin_new_game(look)
		"host":
			_do_host(_pending_new_world, _pending_slot, look)
		"join":
			menus.visible = true
			menus.show_characters([], "Joining as %s..." % Sim.CHARACTERS[_pending_slot]["full"])
			net.rq_pick.rpc_id(1, _pending_slot, look)
		"ingame":
			sim.set_look(look)
			if net.is_online():
				net.send_look(look)
			rig.input_enabled = true
			if rig.mode != CameraRig.Mode.HOUSE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			hud.notify("Looking good!")
	_pending = "" if _pending != "join" else "join"


func _on_customize_cancelled() -> void:
	match _pending:
		"new":
			menus.visible = true
			menus._show("main", "")
		"host", "join":
			menus.visible = true
			menus._show("who", "online")
		"ingame":
			rig.input_enabled = true
			if rig.mode != CameraRig.Mode.HOUSE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _pending in ["new", "ingame"]:
		_pending = ""


func _on_character_chosen(slot: int) -> void:
	_pending_slot = slot
	var ch: Dictionary = Sim.CHARACTERS[slot]
	var look: Dictionary = ch["look"]
	if _pending == "host":
		var d := SaveGame.read(true) if not _pending_new_world else {}
		var saved: Dictionary = d.get("sims", {}).get(str(slot), {})
		if saved.get("look", {}) is Dictionary and not (saved.get("look", {}) as Dictionary).is_empty():
			look = Net.clean_look(saved["look"])
	elif _choice_looks.has(slot) and not (_choice_looks[slot] as Dictionary).is_empty():
		look = Net.clean_look(_choice_looks[slot])
	menus.visible = false
	customizer.open(look, "WHO'S %s?" % String(ch["name"]).to_upper(),
		"%s lives in %s. Pick a look!" % [ch["full"], Menus._house_name(ch["home"])], true)


func _on_characters_back() -> void:
	if _pending == "join":
		net.leave()
		menus.set_online_status("You left before picking a kid.")
	_pending = ""
	menus._show("online", "main")


## (friend) The host asked who we want to play.
func on_choose(taken: Array, looks: Dictionary, note: String) -> void:
	_joining = ""
	_pending = "join"
	_choice_looks = looks
	if customizer.is_open():
		customizer.close()
	menus.visible = true
	menus.show_characters(taken, note)


## Play as someone other than Jamie (online): swap the kid this computer controls.
func _switch_local(slot: int) -> void:
	if sim.slot == slot:
		return
	var old := sim
	var s := add_sim(slot, false)
	bind_local(s)
	sims.erase(old.slot)
	old.queue_free()


func _on_continue() -> void:
	var d := SaveGame.read()
	_start_game()
	if d.is_empty():
		hud.notify("Couldn't read the saved game, so here's a new one.")
	else:
		SaveGame.apply(self, d)
		settle_npcs()
		rig.target = cam_point(sim.global_position)
		hud.set_free_will_button(sim.free_will)
		hud.set_memory_count(sim.memories.size())
		hud.notify("Welcome back!")
	_update_lighting()
	hud.refresh_clock()
	hud.refresh_needs()
	hud.set_money(sim.money)
	hud.set_items(sim.items)


func _open_pause() -> void:
	hud.close_menu()
	if net.is_online():
		var info := "ONLINE · "
		if net.is_host():
			var ips := Net.local_ips()
			info += "Hosting. Friends join with %s (port %d)." % [", ".join(ips) if not ips.is_empty() else "your IP address", Net.PORT]
		else:
			info += "Connected to the host."
		info += "\nHere: " + ", ".join(net.player_list())
		info += "\n(The game keeps going while this menu is open.)"
		menus.debug_allowed = not net.is_client()
		menus.show_pause(info, not net.is_client())
		_menu_speed = 1
		rig.input_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	_menu_speed = clock.speed_level if clock.speed_level > 0 else last_speed
	_set_speed(0)
	rig.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var coop := ""
	if split.active:
		coop = "END 2 PLAYERS"
	elif SplitScreen.pads().size() >= 2:
		coop = "2 PLAYERS (SPLIT SCREEN)"
	menus.debug_allowed = true
	menus.show_pause("", true, coop)


func _resume() -> void:
	menus.hide_menus()
	rig.input_enabled = true
	_set_speed(maxi(1, _menu_speed))
	if rig.mode != CameraRig.Mode.HOUSE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ================================================================ online

## HOST GAME: first pick who to play.
func _on_host(new_world: bool) -> void:
	_pending = "host"
	_pending_new_world = new_world
	menus.show_characters([], "You're the host. Pick your kid; friends pick from the rest.")


func _do_host(new_world: bool, slot: int, look: Dictionary) -> void:
	if new_world:
		SaveGame.delete(true)
	var err := net.host()
	if err != OK:
		menus.visible = true
		menus._show("online", "main")
		menus.set_online_status("Couldn't start hosting (error %d). Is another copy of the game already hosting on this computer?" % err)
		return
	net.host_slot = slot
	net.my_slot = slot
	_switch_local(slot)
	_start_game()
	hud.set_online(true)
	var d := SaveGame.read(true)
	if not d.is_empty():
		SaveGame.apply(self, d)
		settle_npcs()
		rig.target = cam_point(sim.global_position)
	sim.set_look(look)
	hud.set_sim(sim)
	_update_lighting()
	hud.refresh_clock()
	chat.set_hint(true)
	var ips := Net.local_ips()
	hud.notify("You're hosting as %s! Friends join with %s" % [sim.character_name, ips[0] if not ips.is_empty() else "your IP address"])
	chat.add_line("", "Hosting! Friends join with %s. Press T to chat." % (ips[0] if not ips.is_empty() else "your IP address"))
	print("Hosting on port %d. Local addresses: %s" % [Net.PORT, ips])


var _joining := ""


func _on_join(address: String) -> void:
	var err := net.join(address)
	if err != OK:
		net.leave()
		menus.set_online_status("Couldn't connect to \"%s\" (error %d)." % [address, err])
		return
	_joining = address
	get_tree().create_timer(12.0).timeout.connect(func():
		if in_title and _joining == address and net.is_client():
			net.leave()
			_joining = ""
			menus.set_online_status("No answer from %s. Check the address, that the host is in the game, and their router's port %d." % [address, Net.PORT]))


## A friend got in: everyone (Jamie too) is now run by the host, and we play
## the neighbor kid in `slot`.
func start_as_guest(slot: int, w: Dictionary) -> void:
	_joining = ""
	_pending = ""
	_start_game()
	hud.set_online(true)
	chat.set_hint(true)
	clock.unix_time = int(w["time"])
	clock.boost = float(w["boost"])
	Families.jamie = String(w.get("family", Families.jamie))
	for r in w.get("lights", []):
		lights_off[r] = true
	var people: Dictionary = w["sims"]
	for k in people:
		var s := add_sim(int(k), true)
		s.puppet = true
		net._apply_full(s, people[k])
	bind_local(sims[slot])
	# Jamie only stays if someone's playing her.
	for k in sims.keys():
		if not people.has(k) and not people.has(str(k)):
			var gone: Sim = sims[k]
			sims.erase(k)
			gone.queue_free()
	net.apply_npcs(w.get("npcs", []))
	apply_door_locks(w.get("doors", []))
	var bikes: Dictionary = w.get("bikes", {})
	for h in bikes:
		set_bike(String(h), true, Vector3(bikes[h][0], 0, bikes[h][1]), bikes[h][2])
	var vs: Array = w.get("vehicles", [])
	for i in mini(vs.size(), town_life.vehicles.size()):
		var vd: Array = vs[i]
		var v: NpcVehicle = town_life.vehicles[i]
		v.net_apply(vd[0], vd[1], vd[2], int(vd[3]))
		v.global_position = Vector3(vd[0], 0, vd[1])
	for cd in w["cars"]:
		var c: Car = room["objects"].get(cd[0])
		if c:
			c.global_position = Vector3(cd[1], 0, cd[2])
			c.rotation.y = cd[3]
			park_car(c, false)
	rebuild_grid()
	for home in w.get("pizzas", []):
		set_pizza(home, true)
	# Pick up whatever everyone's in the middle of (a TV on, someone asleep...).
	for k in people:
		var d: Array = people[k].get("doing", [])
		var obj: SmartObject = room["objects"].get(d[0]) if d.size() == 4 else null
		if obj and int(d[1]) >= 0 and int(d[1]) < obj.activities.size():
			_on_activity_started(obj.activities[int(d[1])], obj, sims[int(k)], {"busy": d[2], "player": false})
	_update_lighting()
	hud.refresh_clock()
	var ch: Dictionary = Sim.CHARACTERS[slot]
	hud.notify("You're %s! Your house is %s. Press T to chat." % [ch["full"], Menus._house_name(ch["home"])])


func _notification(what: int) -> void:
	# Closing the window saves the game too.
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not in_title and sim != null and not net.is_client():
		SaveGame.save(self)


# ================================================================ cars

## Update the walking grid after a car moved (Jamie walks around where it's parked now).
func park_car(c: Car, rebuild := true) -> void:
	var solids: Array = room["grid_lists"][4]
	if c.solid_index >= 0 and c.solid_index < solids.size():
		solids[c.solid_index] = c.footprint()
	c.refresh_points()
	if rebuild:
		rebuild_grid()


func rebuild_grid() -> void:
	var g := RoomBuilder.rebuild_grid(room)
	room["grid"] = g
	for e in shop_doors:
		if e.get("locked", false):
			_apply_door_grid(e)
	for n: Npc in npcs:
		n.grid = g
	for s: Sim in sims.values():
		s.grids[0] = g
		if s.level == 0:
			s.grid = g


func _start_driving(c: Car) -> void:
	driving = c
	_pre_drive_cam = rig.mode if rig.mode <= CameraRig.Mode.FIRST else CameraRig.Mode.HOUSE
	hud.close_menu()
	_set_hovered(null)
	audio.play_at("car_door", c.door_point() + Vector3(0, 0.8, 0), -2.0)
	sim.set_hidden(true)
	c.driver = sim
	c.remote = false
	rig.car = c
	rig.set_mode(CameraRig.Mode.DRIVE)
	c.set_driving(true, _is_night())
	hud.set_driving(c.display_name)
	if clock.speed_level == 0:
		clock.set_speed(1)


## Get out (only when nearly stopped, and only where there's room to stand).
func _try_exit_car() -> void:
	var c := driving
	if absf(c.speed) > 1.5:
		hud.notify("Slow down and stop the car first!")
		return
	park_car(c, true)
	var spot := find_exit_spot(c)
	if spot == Vector3.INF:
		hud.notify("There's no room to get out here. Park somewhere else!")
		return
	driving = null
	c.set_driving(false, false)
	c.driver = null
	audio.play_at("car_door", spot + Vector3(0, 0.8, 0), -2.0)
	rig.car = null
	sim.set_hidden(false)
	var away := spot - c.global_position
	var yaw := atan2(-away.x, -away.z)
	if net.is_client():
		net.rq_exit_car.rpc_id(1, c.key, c.global_position.x, c.global_position.z, c.global_rotation.y, spot.x, spot.z, yaw)
		sim.place(spot, yaw)
		sim.net_pos = spot
		sim._ignore_net_until = Time.get_ticks_msec() + 1500
	else:
		sim.cancel(0)
		sim.place(spot, yaw)
		if net.is_host():
			net.send_car_parked(c)
	hud.set_driving("")
	rig.set_mode(_pre_drive_cam)
	if rig.mode != CameraRig.Mode.HOUSE:
		rig.face_yaw(sim.rotation.y)
	else:
		rig.focus(spot)


## A free place to stand next to a parked car, or Vector3.INF.
func find_exit_spot(c: Car) -> Vector3:
	var world := OutdoorBuilder.WALK.grow(-0.4)   # (where you can walk outdoors)
	var g: AStarGrid2D = room["grid"]
	for p: Vector3 in c.exit_spots():
		if not world.has_point(Vector2(p.x, p.z)):
			continue
		var cell := Vector2i(floori(p.x / g.cell_size.x), floori(p.z / g.cell_size.y))
		if g.is_in_boundsv(cell) and not g.is_point_solid(cell):
			return p
	return Vector3.INF


## Host: an online player parked and got out of a car.
func exit_car_remote(who: Sim, c: Car, pos: Vector3, yaw: float, spot: Vector3, spot_yaw: float) -> void:
	c.global_position = pos
	c.rotation.y = yaw
	c.speed = 0.0
	park_car(c, true)
	who.set_hidden(false)
	who.cancel(0)
	who.place(spot, spot_yaw)
	audio.play_at("car_door", spot + Vector3(0, 0.8, 0), -2.0)
	net.send_car_parked(c)


func _set_speed(level: int) -> void:
	if net.is_online():
		return   # online, time always runs in real time
	clock.set_speed(level)


func _is_night() -> bool:
	var h := clock.hour_float()
	return h >= 19.75 or h < 6.25


func _drive_physics(delta: float) -> void:
	var c := driving
	if menus.is_open() or clock.speed_level == 0:
		return
	var throttle := Input.get_action_strength("accelerate")
	var brake := Input.get_action_strength("brake")
	var turn := Input.get_axis("steer_left", "steer_right")
	c.drive_step(delta, throttle, brake, turn)
	hud.set_mph(c.mph())
	_drive_thru_tick(c)
	if net.is_client():
		net.send_my_car(c)
	# Jamie rides along (so the music, rooms and saving know where she is).
	sim.global_position = Vector3(c.global_position.x, 0, c.global_position.z)
	rig.stick_look(Input.get_vector("look_left", "look_right", "look_up", "look_down"), delta)


# ================================================================ world look

func _setup_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("241A2C")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Glow makes screens and lamps bloom. The Compatibility renderer (older
	# GPUs) brightens the whole frame with it, so it's only used on Forward+.
	# (Compatibility has no RenderingDevice; Forward+ and Mobile do.)
	var forward_plus := RenderingServer.get_rendering_device() != null
	env.glow_enabled = forward_plus
	env.glow_intensity = 0.6
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.0
	env.ssao_enabled = forward_plus
	env.ssao_intensity = 1.2
	env.ssao_radius = 0.6
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.05
	env.adjustment_contrast = 1.04
	# A sky for the close-up cameras (the House Cam keeps the dark backdrop).
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sun_angle_max = 8.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.fog_density = 0.012
	env.fog_sky_affect = 0.35
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0   # sharper shadows close up
	sun.shadow_blur = 1.5
	sun.shadow_bias = 0.08
	sun.shadow_normal_bias = 1.6       # (no shadow "acne" stripes crawling over the floors and lawns)
	sun.directional_shadow_blend_splits = true
	add_child(sun)


func _setup_post() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = POST_SHADER
	post_mat = ShaderMaterial.new()
	post_mat.shader = sh
	rect.material = post_mat
	layer.add_child(rect)


func _update_lighting() -> void:
	var h := clock.hour_float()
	var day := 0.0
	if h > 6.0 and h < 20.0:
		day = clampf(sin((h - 6.0) / 14.0 * PI) * 1.3, 0.0, 1.0)
	var golden := clampf(1.0 - absf(h - 18.3) / 2.2, 0.0, 1.0)
	var morning := clampf(1.0 - absf(h - 8.0) / 2.5, 0.0, 1.0)

	var sun_col := Color("FFF1D6").lerp(Color("F2A65A"), golden).lerp(Color("FBE3A0"), morning * 0.5)
	sun.light_energy = day * 0.85 * (1.0 - 0.6 * overcast)     # (gray, rainy or snowy days: see Seasons)
	sun.visible = day > 0.01   # no dark sun disk in the night sky
	sun.light_color = sun_col
	sun.rotation_degrees = Vector3(lerpf(-12.0, -62.0, day), 40.0 + (h - 12.0) * 5.0, 0.0)

	env.ambient_light_color = Palette.NAVY.lerp(Palette.CREAM, day).lerp(Color("E58A5E"), golden * 0.5)
	env.ambient_light_energy = lerpf(0.35, 0.6, day)

	var sky := Palette.NAVY.lerp(Color("BFE0EE"), day).lerp(Color("E58A5E"), golden * 0.8)
	var top := Color("0E1024").lerp(Color("5E9FD6"), day).lerp(Color("6A5A9A"), golden * 0.7)
	sky = sky.lerp(Color("8E989E"), overcast * 0.75 * day)
	top = top.lerp(Color("6E787E"), overcast * 0.8 * day)
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = sky
	sky_mat.ground_horizon_color = sky
	sky_mat.ground_bottom_color = Color("2E3A2A").lerp(Color("4F6A3A"), day)
	env.fog_light_color = sky.lerp(top, 0.3)
	var win: StandardMaterial3D = room["window_mat"]
	win.albedo_color = sky
	win.emission = sky
	win.emission_energy_multiplier = 0.15 + day * 0.3

	if driving:
		for l in driving.headlights:
			l.visible = _is_night()

	var beam: SpotLight3D = room["sunbeam"]
	beam.light_energy = day * 2.0
	beam.light_color = sun_col

	# Room lights: dimmer by day, brighter in the evening and at night.
	var night := 1.0 if (h >= 17.5 or h < 6.5) else 0.0
	_index_lamps()
	var li := -1
	for lamp in room["lamps"]:
		li += 1
		var e: float = lerpf(float(lamp["day"]), float(lamp["night"]), night)
		if lamp["light"] == null:
			(lamp["mat"] as StandardMaterial3D).emission_energy_multiplier = e * 0.5   # glowing windows
			continue
		if lights_out and lamp["group"] == "bedroom":
			e *= 0.04   # lights out: just the lava lamp and the stars
		if not lights_off.is_empty() and lights_off.has(_lamp_rooms.get(li, "")):
			e = 0.0
		(lamp["light"] as Light3D).light_energy = e
		if lamp["mat"] != null:
			(lamp["mat"] as StandardMaterial3D).emission_energy_multiplier = 0.06 + e * 0.18


## Turn a TV on or off (any TV: ours or a neighbor's).
func _set_tv(tv: SmartObject, on: bool) -> void:
	var m: StandardMaterial3D = tv.get_meta("screen_mat")
	if on:
		# Dark glass + colored emission, so the picture glows instead of washing out.
		m.albedo_color = Color("1F2A26")
		m.emission_energy_multiplier = 0.22
	else:
		m.albedo_color = Color("3B3F3A")
		m.emission_energy_multiplier = 0.0
	(tv.get_meta("tv_light") as OmniLight3D).light_energy = 0.9 if on else 0.0
	tv_on = not _tv_users.is_empty()


var _tag_t := 0.0


func _process(_delta: float) -> void:
	Npc.time_scale = 0.0 if clock.speed_level == 0 else clampf(clock.speed_factor(), 1.0, 15.0)
	_tag_t += _delta
	if _tag_t > 0.3:
		_tag_t = 0.0
		_update_family_tags()
	if not _tv_users.is_empty():
		# A little cartoon flicker: the screens and their glow shift colors.
		var t := Time.get_ticks_msec() * 0.001
		var c := Palette.CRT.lerp(Palette.ROSE, 0.5 + 0.5 * sin(t * 1.7)).lerp(Palette.GOLD, 0.3 * (0.5 + 0.5 * sin(t * 4.3)))
		for tv: SmartObject in _tv_users:
			(tv.get_meta("screen_mat") as StandardMaterial3D).emission = c
			var l: OmniLight3D = tv.get_meta("tv_light")
			l.light_color = c
			l.light_energy = 0.8 + 0.15 * sin(t * 9.0) + randf() * 0.08
	_update_walls()
	_update_swing_doors()
	_update_drive_in()
	_follow_jamie()
	_pad_house_cam(_delta)


## Moms, dads and the kids in the neighborhood always show who they are when
## you're near them ("Mom", "Mrs. Nguyen · Kevin's mom"), so you can tell
## them apart from the folks out for a walk.
func _update_family_tags() -> void:
	if sim == null:
		return
	for n: Npc in npcs:
		if n.role != "parent" and n.role != "kid":
			continue
		var near := not n.away and dist_xz(n.global_position, sim.global_position) < 11.0 and absf(n.global_position.y - sim.global_position.y) < 5.0
		n.set_tag_always(near)


## A car bumped into someone: "Ouch!" (everyone online sees it).
func ouch(who: Node3D, from_net := false) -> void:
	var lines := ["Ouch!", "OUCH!", "Hey! Watch it!", "Ow! My foot!", "Ouch! Learn to drive!"]
	var text: String = lines[randi() % lines.size()]
	Props.bubble(who, text, 2.5, 2.3)
	audio.play_at("car_bump", who.global_position + Vector3(0, 1.0, 0), -8.0)
	if not from_net and net.is_online():
		var key := ""
		if who is Npc:
			key = obj_keys.get(who, "")
		elif who is Sim:
			key = "sim:%d" % (who as Sim).slot
		net.send_ouch(key, text)


## The drive-in's screen shows the movie every night from 8 PM to 1 AM.
func _update_drive_in() -> void:
	var m: StandardMaterial3D = room.get("drivein_screen_mat")
	if m == null:
		return
	var showing := Activity.in_window(clock.hour_float(), 20.0, 1.0)
	var l: OmniLight3D = room["drivein_light"]
	if not showing:
		m.emission_energy_multiplier = 0.0
		l.light_energy = 0.0
		return
	var t := Time.get_ticks_msec() * 0.001
	var scene := int(t / 4.0) % 5
	var c: Color = [Color("BFD8FF"), Color("FFB37A"), Color("9AE59A"), Color("FF7A9A"), Color("E8E4DA")][scene]
	c = c.lerp(Color.WHITE, 0.3 + 0.2 * sin(t * 3.1))
	m.emission = c
	m.emission_energy_multiplier = 0.9 + 0.15 * sin(t * 7.0)
	l.light_color = c
	l.light_energy = 1.2


## The House Cam on a gamepad: the left stick moves a cursor (and pans at the
## screen edge), the right stick turns and zooms.
func _pad_house_cam(delta: float) -> void:
	if rig.mode != CameraRig.Mode.HOUSE or not hud.using_pad or menus.is_open() or hud.diary_open:
		return
	var vp := split.p1_size()
	if _cursor.x < 0.0:
		_cursor = vp / 2.0
	if not hud.menu_open:
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if v.length() > 0.0:
			_cursor += v * v.length() * 900.0 * delta
			_cursor = _cursor.clamp(Vector2(4, 4), vp - Vector2(4, 4))
			var edge := Vector2.ZERO
			if _cursor.x < 40.0 or _cursor.x > vp.x - 40.0:
				edge.x = signf(v.x)
			if _cursor.y < 40.0 or _cursor.y > vp.y - 40.0:
				edge.y = signf(v.y)
			rig.pan_house(edge, delta)
			_hover(_cursor)
		hud.set_cursor(_cursor)
	var r := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if absf(r.x) > 0.0:
		rig.rotate_house(-r.x * 1.8 * delta)
	if absf(r.y) > 0.3:
		rig.zoom(r.y * 9.0 * delta)


## Signs, posters and trim built onto a wall hang from that wall, so they go down with it in the
## House Cam's cutaway (instead of floating in mid-air over the low wall stub). Things you can
## click (phones, light switches) stay put so you can still use them.
func _hang_wall_decor() -> void:
	var walls := []
	for w in room["walls"]:
		var full := w["full"] as Node3D
		var box := _mesh_box(full)
		if box.size != Vector3.ZERO:
			walls.append([full, box, bool(w["along_x"]), float(w["plane"]), float(w["thick"])])
	var moved := 0
	for n in get_children():
		if not (n is Node3D) or n is SmartObject or n is CollisionObject3D or n is Npc or n is Sim or n is Camera3D:
			continue
		if n in [holidays, seasons, town_life, audio, hud, rig] or (n as Node3D).is_in_group("leaves"):
			continue
		var has_mesh := n is MeshInstance3D
		for c in n.get_children():
			if c is MeshInstance3D:
				has_mesh = true
			if c is CollisionObject3D:
				has_mesh = false     # (part of something solid or clickable)
				break
		if not has_mesh:
			continue
		var b := _mesh_box(n)
		if b.size == Vector3.ZERO or b.position.y < 0.9:
			continue
		for w in walls:
			var wb: AABB = w[1]
			var thin: float = b.size.z if w[2] else b.size.x
			var mid: float = b.get_center().z if w[2] else b.get_center().x
			if thin > 0.25 or absf(mid - float(w[3])) > float(w[4]) / 2.0 + 0.12:
				continue
			if b.end.y > wb.end.y + 0.05:
				continue
			var lo: float = wb.position.x if w[2] else wb.position.z
			var hi: float = wb.end.x if w[2] else wb.end.z
			var c2: float = b.get_center().x if w[2] else b.get_center().z
			if c2 < lo or c2 > hi:
				continue
			(n as Node3D).reparent(w[0] as Node3D, true)
			moved += 1
			break
	if OS.is_debug_build() and "--verbose-build" in OS.get_cmdline_user_args():
		print("wall decor hung on walls: ", moved)


func _mesh_box(n: Node) -> AABB:
	var a := AABB()
	var first := true
	var stack: Array = [n]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D and (x as MeshInstance3D).mesh != null:
			var m := x as MeshInstance3D
			var bb: AABB = m.global_transform * m.mesh.get_aabb()
			a = bb if first else a.merge(bb)
			first = false
		stack.append_array(x.get_children())
	return a


func _update_walls() -> void:
	var house := rig.mode == CameraRig.Mode.HOUSE
	# Which way the camera looks from, flattened onto the floor.
	var d := rig.cam.global_position - rig.target
	d.y = 0.0
	d = d.normalized()
	for w in room["walls"]:
		# Inside walls are always lowered; outside walls only on the camera's side.
		var cut := house and (bool(w["shared"]) or (w["normal"] as Vector3).dot(d) > 0.2)
		(w["full"] as Node3D).visible = not cut
		(w["stub"] as Node3D).visible = cut
		# Hidden walls must not block clicks or the camera.
		(w["body"] as StaticBody3D).collision_layer = 0 if cut else 2
		for a in w.get("attached", []):
			(a as CollisionObject3D).collision_layer = 0 if cut else 1   # e.g. the family photos
	for c in room["ceilings"]:
		(c as Node3D).visible = not house
	# Light switches hang on the low wall stub when the wall is cut away
	for ls in room.get("light_switches", []):
		var plate: Node3D = (ls["obj"] as Node3D).get_node("Plate")
		plate.position.y = LightSwitches.STUB_Y if not (ls["wall"]["full"] as Node3D).visible else LightSwitches.PLATE_Y
	var mode := (0 if house else 1) + (2 if rig.mode == CameraRig.Mode.TITLE else 0)
	if mode != _sky_mode:
		_sky_mode = mode
		env.background_mode = Environment.BG_COLOR if house else Environment.BG_SKY
		env.fog_enabled = not house and rig.mode != CameraRig.Mode.TITLE


## DEBUG: jump to another day (same time of day); the town, holidays and seasons catch up.
func _debug_set_date(y: int, m: int, d: int, minute_of_day := -1) -> void:
	var h := clock.hour_float()
	var mins := minute_of_day if minute_of_day >= 0 else int(h) * 60 + int((h - int(h)) * 60.0)
	clock.unix_time = int(Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": d,
		"hour": mins / 60, "minute": mins % 60, "second": 0}))
	settle_npcs()          # (also redoes the holidays, the season and the shop doors)
	_update_lighting()
	hud.refresh_clock()


## DEBUG: set the clock to another time today; the town catches up.
func _debug_set_time(h: int, mi: int) -> void:
	clock.unix_time = int(Time.get_unix_time_from_datetime_dict({"year": clock.year(), "month": clock.month(), "day": clock.day(),
		"hour": h, "minute": mi, "second": 0}))
	settle_npcs()
	_update_lighting()
	hud.refresh_clock()


# ================================================================ the Rocket Burger drive-thru (in your car)

var _dt_speaker: SmartObject       # the menu board's "object" (just for the order menu)
var _dt_order: Activity = null     # what you ordered, waiting at the window
var _dt_order_time := 0
var _dt_hinted := false


func _setup_drive_thru() -> void:
	var counter: SmartObject = room["objects"].get("burger_counter")
	if counter == null:
		return
	_dt_speaker = SmartObject.new()
	_dt_speaker.name = "DriveThruSpeaker"
	_dt_speaker.display_name = "Rocket Burger Drive-Thru"
	_dt_speaker.collision_layer = 0
	add_child(_dt_speaker)
	for a: Activity in counter.activities:
		if not a.title.begins_with("Buy"):
			continue
		var o := Activity.make(a.title.replace("Buy", "Order"), a.minutes, a.effects.duplicate(), "stand")
		o.money = a.money
		o.from_hour = a.from_hour
		o.to_hour = a.to_hour
		o.memory_id = a.memory_id
		o.autonomous = false
		_dt_speaker.activities.append(o)


func _at_drive_thru(spot: Vector3) -> bool:
	return driving != null and absf(driving.speed) < 1.6 and dist_xz(driving.global_position, spot) < 2.6


func _open_drive_thru_menu() -> void:
	if net.is_client():
		hud.notify("The drive-thru only takes orders from the host's car for now. Park and go inside!")
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.open_menu(_dt_speaker, get_viewport().get_visible_rect().size / 2.0 - Vector2(160, 120))
	audio.play_at("phone_talk", EastBuilder.DT_MENU + Vector3(0, 1.0, 0), -14.0)


func _drive_thru_order(act: Activity) -> void:
	if driving == null:
		return
	if not act.available(clock):
		hud.notify("Rocket Burger is closed. (Open %s.)" % act.when_label())
		return
	if sim.money + act.money < 0.0:
		hud.notify("You can't afford that. It's $%.2f." % -act.money)
		return
	sim.money += act.money
	hud.set_money(sim.money)
	_dt_order = act
	_dt_order_time = clock.unix_time
	var item := act.title.replace("Order ", "").replace("a ", "").replace("Rocket Meal (Burger, Fries & Shake)", "Rocket Meal")
	Props.bubble(driving, "\"%s, please!\"" % item.capitalize(), 2.5, 2.2)
	hud.notify("\"One %s, comin' right up! That'll be $%.2f. Pull up to the window!\"" % [item, -act.money])
	if rig.mode != CameraRig.Mode.HOUSE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Every frame while driving: a hint at the menu board, and your food at the window.
func _drive_thru_tick(c: Car) -> void:
	if _dt_speaker == null:
		return
	var at_menu := _at_drive_thru(EastBuilder.DT_MENU)
	if at_menu and not _dt_hinted and _dt_order == null:
		_dt_hinted = true
		hud.notify("Rocket Burger drive-thru! Press %s to order." % ("(A)" if hud.using_pad else "E"))
	elif not at_menu and dist_xz(c.global_position, EastBuilder.DT_MENU) > 5.0:
		_dt_hinted = false
	if _dt_order != null and _at_drive_thru(EastBuilder.DT_WINDOW):
		var act := _dt_order
		_dt_order = null
		for n in act.effects:
			sim.needs.values[n] = clampf(float(sim.needs.values[n]) + float(act.effects[n]) * act.minutes / 60.0, 0.0, 100.0)
		hud.refresh_needs()
		audio.play_at("cash_register", EastBuilder.DT_WINDOW + Vector3(0, 1.0, 0), -8.0)
		var cook := town_life._npc("npc_burger_cook")
		hud.notify("%s hands you a warm paper bag through the window. \"Thanks for flying Rocket Burger!\" You eat in the car." % \
			(cook.display_name if cook and not cook.away else "The cook"))
		if act.memory_id != "":
			award_memory(sim, act.memory_id)
	elif _dt_order != null and clock.unix_time - _dt_order_time > 45 * 60:
		_dt_order = null
		hud.notify("You drove off and never picked up your order! (There goes your money.)")


# ================================================================ visiting the neighbors

var _house_rects := {}        # home -> [Rect2, ...] (the rooms on the ground floor)
var _door_blockers := []      # [StaticBody3D, home]


## Every house's ground floor, and an invisible block in each outside door that only
## lets in the family (and anybody they've invited in).
func _setup_house_doors() -> void:
	for rn in room["rooms"]:
		var parts := String(rn).split("|")
		if parts.size() != 2 or parts[0] == "town" or parts[1] in ["Attic", "Basement"]:
			continue
		if not _house_rects.has(parts[0]):
			_house_rects[parts[0]] = []
		(_house_rects[parts[0]] as Array).append(room["rooms"][rn])
	for d in room["swing_doors"]:
		if not d.has("home"):
			continue
		var b := StaticBody3D.new()
		b.collision_layer = 64
		b.collision_mask = 0
		add_child(b)
		RoomBuilder.add_shape(b, Vector3(0.95, 2.0, 0.95), (d["center"] as Vector3) + Vector3(0, 1.0, 0))
		_door_blockers.append([b, String(d["home"])])


## Which house (ground floor) a point is in, or "".
func house_at(p: Vector3) -> String:
	for h in _house_rects:
		for r: Rect2 in _house_rects[h]:
			if r.has_point(Vector2(p.x, p.z)):
				return h
	return ""


## May this kid go into this family's house? (Their own, an invitation, or they're already inside.)
func visit_ok(s: Sim, home: String) -> bool:
	if home == "" or home == s.home or home == "town":
		return true
	if int(s.let_in.get(home, 0)) > clock.unix_time:
		return true
	return s.level == 0 and house_at(s.global_position) == home


func _entry_check(s: Sim, p: Vector3) -> String:
	var h := house_at(p)
	if h == "" or visit_ok(s, h):
		return ""
	return "That's %s. Knock on the front door first! (Click their front porch.)" % Families.house_title(h)


## The invisible door blocks: a kid walks through the ones they're allowed through.
func _update_door_access(s: Sim) -> void:
	if not is_instance_valid(s):
		return
	for e in _door_blockers:
		var b: StaticBody3D = e[0]
		# (a friend's own copy of the game doesn't know who's been invited: the host checks)
		if net.is_client() or visit_ok(s, String(e[1])):
			s.add_collision_exception_with(b)
		else:
			s.remove_collision_exception_with(b)


## Somebody knocked: is anybody home, and will they let you in?
func _answer_door(who: Sim, porch: SmartObject) -> void:
	var home := porch.home
	if home == who.home:
		_tell(who, "It's your own house! Just walk right in.")
		return
	var h := clock.hour_float()
	var family := Families.house_title(home)
	# Who's home to answer? (a parent who's here and awake, or a friend playing that family's kid)
	var answer: Node3D = null
	var who_name := ""
	for n: Npc in npcs:
		if n.home == home and n.role == "parent" and not n.away and not n.lying \
				and (house_at(n.global_position) == home or dist_xz(n.global_position, porch.look_point) < 16.0):   # (in the yard counts)
			answer = n
			who_name = n.display_name
			break
	var player_home := false
	for o: Sim in sims.values():
		if o != who and o.home == home and not o.hidden and house_at(o.global_position) == home:
			player_home = true
			if answer == null:
				answer = o
				who_name = o.character_name
	if answer == null:
		_tell(who, "Knock knock... Nobody answers. Nobody's home at %s right now." % family)
		Props.bubble(porch, "(nobody's home)", 2.5, 2.2)
		return
	var yes := true
	var line := ""
	if h >= 21.0 or h < 7.5:
		yes = player_home
		line = "\"It's way too late to come over, sweetie. Go on home!\""
	elif randf() < 0.2 and not player_home:
		yes = false
		line = ["\"Sorry, kiddo, we're just sitting down to eat. Maybe later!\"", "\"Not right now, hon. The house is a mess!\"",
			"\"We're headed out in a minute. Come back another time!\""][randi() % 3]
	if yes:
		line = ["\"Oh, hi %s! Come on in!\"", "\"Well, look who it is! Come in, come in. Wipe your feet!\"",
			"\"Hi there! Come on in. There's lemonade in the fridge.\""][randi() % 3]
		if line.contains("%s"):
			line = line % who.character_name
		who.let_in[home] = mini(clock.unix_time + 4 * 3600, _today_at(21.0))
		_update_door_access(who)
	_tell(who, "%s opens the door. %s" % [who_name, line])
	Props.bubble(porch, line.replace("\"", ""), 3.5, 2.3)
	audio.play_at("door_open" if yes else "door_close", porch.look_point, -6.0)


func _today_at(hour: float) -> int:
	return int(Time.get_unix_time_from_datetime_dict({"year": clock.year(), "month": clock.month(), "day": clock.day(),
		"hour": int(hour), "minute": int((hour - int(hour)) * 60.0), "second": 0}))


## The bedroom and kitchen doors (and the neighbors' front doors) swing open by
## themselves when someone comes close.
func _update_swing_doors() -> void:
	for d in room["swing_doors"]:
		var near := false
		var locked: bool = d.get("locked", false)
		for s: Sim in sims.values():
			if s.hidden or s.level != 0 or locked:
				continue
			if d.has("home") and not visit_ok(s, String(d["home"])):
				continue      # (somebody else's house: it stays shut until they let you in)
			var dist := Vector2(s.global_position.x - d["center"].x, s.global_position.z - d["center"].z).length()
			if dist < 0.5 or (dist < 1.3 and (s.heading_through(d["center"]) or (s.puppet and s._moving))):
				near = true
				break
		for n in npcs:
			if not locked and dist_xz(n.global_position, d["center"]) < 1.1 and (n as Npc).walking:
				near = true
				break
		if near == d["open"]:
			continue
		d["open"] = near
		var tw := create_tween()
		tw.tween_property(d["hinge"], "rotation:y", float(d["angle"]) if near else 0.0, 0.5 if near else 0.4) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if near else Tween.EASE_IN)
		if d.has("hinge2"):
			tw.parallel().tween_property(d["hinge2"], "rotation:y", float(d["angle2"]) if near else 0.0, 0.5 if near else 0.4) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if near else Tween.EASE_IN)
		var pos: Vector3 = d["center"] + Vector3(0, 1.0, 0)
		if near:
			audio.play_at("door_open", pos, -3.0)
		else:
			tw.parallel().tween_callback(func(): audio.play_at("door_close", pos, -4.0)).set_delay(0.24)


## Music and background sound follow Jamie in and out of the house.
func _set_outdoors(on: bool) -> void:
	var h := clock.hour_float()
	audio.set_ambience(("birds" if h >= 5.5 and h < 20.5 else "crickets") if on else "")
	if on == _outdoors:
		return
	_outdoors = on
	audio.set_outside(on)


## In the House Cam, glide over to whichever room Jamie walks into.
func _follow_jamie() -> void:
	if _current_room == "(fixed)":
		return
	var here := room_at(sim.global_position)
	_set_outdoors(here == "Outside")
	if here == "Outside" and rig.mode == CameraRig.Mode.HOUSE and rig.idle_seconds() > 2.5:
		# Outside there are no rooms to frame, so the camera drifts along with Jamie.
		var goal := cam_point(sim.global_position)
		rig.target = rig.target.lerp(goal, minf(1.0, get_process_delta_time() * 1.5))
	if here == _current_room:
		return
	var first := _current_room == ""
	_current_room = here
	_update_location()
	if not first and rig.mode == CameraRig.Mode.HOUSE and here != "Outside":
		var r: Rect2 = room["rooms"][here]
		rig.focus(Vector3(r.get_center().x, floor_y(sim.global_position), r.get_center().y))


## Which room a point is in ("home|Kind" keys, see Families), or "Outside".
## The smallest room that holds it wins; a doorway counts as the room nearby.
func room_at(at: Vector3) -> String:
	var p := Vector2(at.x, at.z)
	var best := "Outside"
	var best_area := INF
	var under := at.y < RoomBuilder.INTERIOR_Y * 0.5
	var level1: Dictionary = room.get("interior_rooms", {})
	for grow in [0.0, 0.35]:
		for room_name in room["rooms"]:
			if level1.has(room_name) != under:
				continue        # (the attics and basements are underground, under Lincoln Avenue)
			var r: Rect2 = room["rooms"][room_name]
			if r.grow(grow).has_point(p) and r.get_area() < best_area:
				best = room_name
				best_area = r.get_area()
		if best != "Outside":
			break
	return best


func _update_location() -> void:
	var here := _current_room
	var text := "Outside"
	if here == "Outside" or here == "" or here == "(fixed)":
		var z := sim.global_position.z
		if z > 13.5 and z < 25.5:
			text = "Maple Street"
		elif z > -38.0 and z < -26.0:
			text = "Lincoln Avenue"
		elif CivicBuilder.FIELD.grow(4.0).has_point(Vector2(sim.global_position.x, z)):
			text = "Maverick Field"
		elif z > 43.0 and z < 56.0 and sim.global_position.x < 52.0:
			text = "Main Street"
		elif DowntownBuilder.DRIVE_IN.has_point(Vector2(sim.global_position.x, z)):
			text = "Starlite Drive-In"
		else:
			var home := _yard_of(sim.global_position)
			text = ("Your Yard" if home == sim.home else "%s' Yard" % Families.plural(home).capitalize()) if home != "" else "Outside"
		hud.set_location(text, false, true)
		return
	text = Families.room_label(here, sim.home)
	hud.set_location(text, _room_has_lights(here), not lights_off.has(here))


## Whose yard a point outside is in ("" if nobody's).
func _yard_of(at: Vector3) -> String:
	for k in NeighborBuilder.HOMES:
		var r: Rect2 = NeighborBuilder.HOMES[k]["r"]
		if r.grow(5.0).has_point(Vector2(at.x, at.z)):
			return k
	if Rect2(-4, -12, 25, 26).has_point(Vector2(at.x, at.z)):
		return "jamie"
	return ""


# ================================================================ light switches

var lights_off := {}            # room key -> true while its lights are switched off
var _lamp_rooms := {}           # lamp entry index -> room key


func _room_has_lights(key: String) -> bool:
	_index_lamps()
	return _lamp_rooms.values().has(key)


func _index_lamps() -> void:
	if not _lamp_rooms.is_empty():
		return
	var lamps: Array = room["lamps"]
	for i in lamps.size():
		var l = lamps[i]["light"]
		if l == null:
			continue
		var r := room_at((l as Node3D).global_position)
		if r != "Outside":
			_lamp_rooms[i] = r


## Flip the light switch in the room you're in (or `key`'s).
## Flip the lights in a room (a light switch or a lamp was used: this runs on
## every computer, from the activity starting).
func toggle_lights(key := "", at := Vector3.INF) -> void:
	if key == "":
		key = _current_room
	if not _room_has_lights(key):
		return
	set_lights(key, lights_off.has(key), at)


func set_lights(key: String, on: bool, at := Vector3.INF) -> void:
	if on:
		lights_off.erase(key)
	else:
		lights_off[key] = true
	audio.play_at("light_switch", (sim.global_position if at == Vector3.INF else at) + Vector3(0, 1.2, 0), -4.0)
	_update_lighting()
	if key == _current_room:
		_update_location()


# ================================================================ shop doors: locked when closed

var shop_doors: Array = []        # see DowntownBuilder._register_door; each gets "locked", "staff", "blocker"


func _setup_shop_doors() -> void:
	shop_doors = room.get("shop_doors", [])
	for e in shop_doors:
		e["locked"] = false
		e["staff"] = false
		var d: Dictionary = e["door"]
		if d.is_empty():
			continue
		# A "closed" door you can click (and bump into) while it's locked
		var c: Vector3 = d["center"]
		var r: Rect2 = e["rect"]
		var along_x := absf(c.z - r.position.y) < 0.4 or absf(c.z - r.end.y) < 0.4
		var b := SmartObject.new()
		b.name = "closed_" + String(e["key"])
		b.display_name = "%s (Closed)" % e["title"]
		b.kind = "closed_door"
		b.home = "town"
		b.shared = true
		add_child(b)
		RoomBuilder.add_shape(b, Vector3(1.7, 2.4, 0.35) if along_x else Vector3(0.35, 2.4, 1.7), c + Vector3(0, 1.2, 0))
		var outward := Vector3(0, 0, -1 if c.z < r.get_center().y else 1) if along_x else Vector3(-1 if c.x < r.get_center().x else 1, 0, 0)
		b.approach_point = c + outward * 0.9
		b.use_point = b.approach_point
		b.look_point = c + Vector3(0, 1.2, 0)
		var hrs: Vector2 = e["hours"]
		var a := Activity.make("Try the Door", 1, {}, "reach")
		a.locked = true
		a.autonomous = false
		var days := ""
		if not (e["days"] as Array).is_empty():
			days = " (closed %s)" % ("Sundays" if (e["days"] as Array).size() == 6 else "weekends")
		a.message = "Locked! The sign says OPEN %s–%s%s." % [GameClock.fmt_hour(hrs.x), GameClock.fmt_hour(hrs.y), days]
		b.activities.append(a)
		b.collision_layer = 0
		e["blocker"] = b
		e["doorway"] = Rect2(c.x - 0.9, c.z - 0.6, 1.8, 1.2) if along_x else Rect2(c.x - 0.6, c.z - 0.9, 1.2, 1.8)
		room["objects"]["closed_" + String(e["key"])] = b


## Is a shop open right now? (Its door unlocks as soon as the shopkeeper gets there.)
## Why a spot can't be reached: a shop that's locked up for the night.
func _why_unreachable(p: Vector3) -> String:
	for e in shop_doors:
		if bool(e.get("locked", false)) and (e["rect"] as Rect2).has_point(Vector2(p.x, p.z)):
			var hrs: Vector2 = e["hours"]
			return "%s is closed right now. (Open %s to %s.)" % [e["title"], _hour_label(hrs.x), _hour_label(hrs.y)]
	return ""


static func _hour_label(h: float) -> String:
	var hh := int(h) % 24
	var h12 := hh % 12
	if h12 == 0:
		h12 = 12
	var m := int(round((h - floorf(h)) * 60.0))
	return ("%d" % h12 if m == 0 else "%d:%02d" % [h12, m]) + (" AM" if hh < 12 else " PM")


func shop_open(e: Dictionary) -> bool:
	var hrs: Vector2 = e["hours"]
	var days: Array = e["days"]
	return bool(e.get("staff", false)) or (Activity.in_window(clock.hour_float(), hrs.x, hrs.y) and (days.is_empty() or days.has(clock.weekday())))


func _update_shop_doors(force := false) -> void:
	if net.is_client():
		return
	var changed := false
	for e in shop_doors:
		if not e.has("blocker"):
			continue
		var want := not shop_open(e)
		if want and not e["locked"]:
			# Nobody gets locked in: wait until the kids inside have left.
			var inside := []
			for s: Sim in sims.values():
				if s.level == 0 and (e["rect"] as Rect2).has_point(Vector2(s.global_position.x, s.global_position.z)):
					inside.append(s)
			if not inside.is_empty():
				if not e.get("warned", false):
					e["warned"] = true
					for s in inside:
						_sim_notice(s, "%s is closing! Time to head out." % e["title"])
				continue
		e["warned"] = false
		if want != e["locked"] or force:
			_set_door_locked(e, want)
			changed = true
	if changed and net.is_host():
		net.send_door_locks(locked_doors())


func _set_door_locked(e: Dictionary, on: bool) -> void:
	e["locked"] = on
	(e["door"] as Dictionary)["locked"] = on
	var b: SmartObject = e["blocker"]
	b.collision_layer = (1 | 2) if on else 0
	_apply_door_grid(e)


func _apply_door_grid(e: Dictionary) -> void:
	var g: AStarGrid2D = room["grid"]
	var r: Rect2 = e["doorway"]
	for x in range(floori(r.position.x / RoomBuilder.CELL), ceili(r.end.x / RoomBuilder.CELL)):
		for y in range(floori(r.position.y / RoomBuilder.CELL), ceili(r.end.y / RoomBuilder.CELL)):
			var p := Vector2i(x, y)
			if not g.is_in_boundsv(p):
				continue
			if e["locked"]:
				g.set_point_solid(p, true)
	if not e["locked"]:
		# (unlocking: put back exactly what the plain grid has there)
		var fresh := RoomBuilder.rebuild_grid_region(room, r)
		for p: Vector2i in fresh:
			g.set_point_solid(p, fresh[p])


func locked_doors() -> Array:
	var out := []
	for e in shop_doors:
		if e.get("locked", false):
			out.append(e["key"])
	return out


## (friend) The host says which doors are locked.
func apply_door_locks(keys: Array) -> void:
	for e in shop_doors:
		if not e.has("blocker"):
			continue
		var on := keys.has(e["key"])
		if on != e.get("locked", false):
			_set_door_locked(e, on)


## A shopkeeper reached the shop door: opening up (or locking up after closing).
func _on_staff_door(n: Npc, arrived: bool) -> void:
	for e in shop_doors:
		if e["key"] == n.workplace:
			e["staff"] = arrived
	_update_shop_doors()


# ================================================================ game events

func _on_minute() -> void:
	Npc.month_now = clock.month()
	if int(clock.unix_time / 60) % 5 == 0:
		for s: Sim in sims.values():
			var changed := false
			for h in s.let_in.keys():
				if int(s.let_in[h]) < clock.unix_time and house_at(s.global_position) != h:
					s.let_in.erase(h)
					changed = true
			if changed:
				_update_door_access(s)
	if int(clock.unix_time / 60) % 5 == 0:
		update_computers()
	for s: Sim in sims.values():
		s.on_minute()
	if not net.is_client():
		var h := clock.hour_float()
		var wd := clock.weekday()
		for n: Npc in npcs:
			n.on_minute(h, wd)
	if not net.is_client():
		_check_deliveries()
		town_life.on_minute(clock.hour_float(), clock.weekday())
		_update_shop_doors()
	hud.on_minute()
	_update_lighting()


## Someone started doing something. Runs on every computer (online, the host
## sends these as events), so sounds, TVs, doors and lights look the same for
## everyone. `info` comes from the host online: {"busy", "player"}.
func _on_activity_started(act: Activity, obj: SmartObject, who: Sim, info := {}) -> void:
	var objs: Dictionary = room["objects"]
	var at := obj.look_point
	var local := who == sim
	var tag := str(who.slot)
	var busy: bool = info.get("busy", who.current.get("busy", false))
	var by_player: bool = info.get("player", who.current.get("player", false))
	if net.is_host():
		net.send_started(who, obj, act)
	if obj.kind == "light_switch" or obj.kind == "lamp":
		toggle_lights(String(obj.get_meta("room", "")), obj.look_point)
	if obj.kind == "bowling_lane" and room.has("bowling_lanes"):
		(room["bowling_lanes"] as BowlingLanes).set_bowling(int(obj.get_meta("lane", 0)), true)
	if act.talk == "stop_thief" and not net.is_client():
		town_life.catch_burglar(who)
	if act.paper == "deliver":
		_throw_paper(who, obj)
	if act.tv_on and obj.has_meta("screen_mat"):
		_tv_users[obj] = int(_tv_users.get(obj, 0)) + 1
		if _tv_users[obj] == 1:
			_set_tv(obj, true)
			audio.play_at("tv_on", at, -5.0)
			# what's on: a picture on the screen, and its theme music
			var tape := String((who.items.get("tape", {}) as Dictionary).get("title", "")) if act.needs_item == "tape" else ""
			var what := TvShow.pick(act, clock, tape)
			_tv_screens[obj] = TvShow.make_screen(obj, what)
			audio.start_loop("tv%d" % obj.get_instance_id(), String(what["sound"]), at, -12.0, 0.8)
			if who == sim or split.is_p2(who):
				_tell(who, "On TV: %s" % what["title"])
		_duck(1)
	if act.pose == "lie":
		audio.start_loop("snore" + tag, "snore", who.global_position + Vector3(0, 0.6, 0), -3.0, 1.5)
	if obj.kind == "pet_dog":
		audio.play_at("bark", at, -4.0)
	elif obj.kind == "pet_cat":
		audio.play_at("meow", at, -6.0)
	if obj.kind == "fridge":
		audio.play_at("fridge_open", at, -2.0)
	if obj.kind == "phone":
		if busy:
			audio.start_loop("phone" + tag, "phone_busy", at, -10.0, 0.0, false)
		else:
			audio.start_loop("phone" + tag, "phone_dial", at, -5.0, 0.0, false)
			audio.start_loop("phone_talk" + tag, "phone_talk", at, -16.0, 9.4)
	if obj.door_hinge:
		_open_door(obj)
		audio.play_at("door_open", at, -1.0)
		_tell(who, obj.door_message)
	if act.locked and obj.door_rattle:
		_rattle(obj)
		audio.play_at("door_locked", at, -2.0)
	if act.message != "":
		_tell(who, act.message)
	if act.item_message != "" and act.needs_item != "":
		_tell(who, act.item_message % who.item_title(act.needs_item))
	if not act.messages.is_empty():
		_tell(who, act.messages[randi() % act.messages.size()])
	if act.sound != "":
		audio.play_at(act.sound, at, -2.0)
	if act.until_rested:
		# Bedtime: crickets outside, music down. In Jamie's room the lights go out.
		if obj == objs.get("bed"):
			lights_out = true
			_update_lighting()
		audio.start_loop("night" + tag, "crickets", who.global_position + Vector3(-3.0, 1.5, 0), -12.0)
		_duck(1)
		_update_boost()
		if local:
			hud.notify("Sweet dreams! Time speeds up while %s sleeps." % who.character_name if sims.size() == 1 \
				else "Sweet dreams! Time speeds up once everyone is asleep.")
	if act.ui == "diary":
		audio.start_loop("pencil" + tag, "pencil", at, -10.0)
		if local and by_player:
			_open_diary()
	if act.customize and local and by_player:
		_pending = "ingame"
		rig.input_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		customizer.open(who.look, "NEW LOOK?", "Try a different hairstyle or outfit. The 80s or the 90s, your call!", true,
			Catalog.outfits_for(who.owned))
	if act.loop_sound != "":
		audio.start_loop("activity" + tag, act.loop_sound, at, act.loop_db, 0.3)
		if act.loop_sound in ["vinyl", "music_house"]:
			_duck(1)
	if act.glow != "" and room.has(act.glow):
		var gm: StandardMaterial3D = room[act.glow]
		if not _glow_base.has(gm):
			_glow_base[gm] = gm.emission_energy_multiplier
		_glow_users[gm] = int(_glow_users.get(gm, 0)) + 1
		gm.emission_energy_multiplier = maxf(1.2, float(_glow_base[gm]) * 4.0)
	if act.drive and obj is Car and split.is_p2(who):
		who.cancel(0)
		split.notify("Player 1 does the driving!")
	elif act.drive and obj is Car:
		var car := obj as Car
		if local:
			if by_player or net.is_client():
				_start_driving(car)
			else:
				who.cancel(0)
		else:
			# Someone else is driving: their computer moves the car; we hear it.
			car.driver = who
			car.remote = true
			car.set_driving(true, _is_night())
			if net.is_host():
				who.set_hidden(true)
	if local and rig.mode != CameraRig.Mode.HOUSE:
		# Lying down, look up at the ceiling (and the glow-in-the-dark stars).
		rig.face_yaw(sim.facing_yaw(), 1.15 if act.pose == "lie" else -0.12)
	if act.memory_id != "":
		award_memory(who, act.memory_id)


## A message for whoever did it (Player 1's HUD, or Player 2's half).
func _tell(who: Sim, text: String) -> void:
	if text == "":
		return
	if who == sim:
		hud.notify(text)
	elif split.is_p2(who):
		split.notify(text)


## A Memory Moment: the first time someone does something special.
func award_memory(who: Sim, id: String) -> void:
	if who.memories.has(id) or not Content.MEMORIES.has(id):
		return
	if who == sim:
		who.memories[id] = true
		var m: Array = Content.MEMORIES[id]
		hud.show_memory(m[0], m[1])
		hud.set_memory_count(who.memories.size())
		audio.play_ui("memory_chime", -6.0)
		var tw := create_tween()
		tw.tween_method(func(v: float): post_mat.set_shader_parameter("memory", v), 0.0, 1.0, 1.2)
		tw.tween_interval(2.5)
		tw.tween_method(func(v: float): post_mat.set_shader_parameter("memory", v), 1.0, 0.0, 2.0)
	elif split.is_p2(who):
		split.memory(String(Content.MEMORIES[id][0]))
	elif net.is_host():
		net.send_memory(who.slot, id)
	if not who.puppet:
		who.memories[id] = true
		who.needs.mood_bonus += 15.0


func _duck(delta: int) -> void:
	_duckers = maxi(0, _duckers + delta)
	audio.duck(_duckers > 0)


func _on_activity_finished(act: Activity, obj: SmartObject, who: Sim) -> void:
	if act.talk == "knock" and not net.is_client():
		_answer_door(who, obj)
	if act.needs_mail and not net.is_client():
		town_life.mail_taken(obj.home)
	var at := obj.look_point
	var local := who == sim
	var tag := str(who.slot)
	if net.is_host():
		net.send_finished(who, obj, act)
	if act.tv_on and _tv_users.has(obj):
		_tv_users[obj] = int(_tv_users[obj]) - 1
		if _tv_users[obj] <= 0:
			_tv_users.erase(obj)
			_set_tv(obj, false)
			for n in _tv_screens.get(obj, []):
				if is_instance_valid(n):
					(n as Node).queue_free()
			_tv_screens.erase(obj)
			audio.stop_loop("tv%d" % obj.get_instance_id(), 0.08)
			audio.play_at("tv_off", at, -5.0)
		_duck(-1)
	if act.pose == "lie":
		audio.stop_loop("snore" + tag, 0.8)
	if obj.kind == "fridge":
		audio.play_at("fridge_close", at, -2.0)
	if obj.kind == "phone":
		audio.stop_loop("phone" + tag, 0.05)
		audio.stop_loop("phone_talk" + tag, 0.05)
		audio.play_at("phone_hangup", at, -3.0)
	if obj.door_hinge:
		_close_door(obj)
	if act.until_rested:
		if obj == room["objects"].get("bed"):
			lights_out = false
			_update_lighting()
		audio.stop_loop("night" + tag, 1.5)
		_duck(-1)
		_update_boost()
		var h := clock.hour_float()
		if h >= 5.0 and h < 12.0:
			if obj == room["objects"].get("bed"):
				audio.play_at("alarm_clock", Vector3(12.45, 0.65, 6.6), -6.0)   # the clock radio
			else:
				audio.play_at("alarm_clock", at, -8.0)
			if local:
				hud.notify("Good morning! Rise and shine.")
		# Wake-up autosave (whoever saves this game: the host, or you offline)
		if local and not net.is_client() and SaveGame.save(self):
			hud.notify("Good morning! (Game saved.)")
	if act.ui == "diary":
		audio.stop_loop("pencil" + tag, 0.2)
	if act.loop_sound != "":
		audio.stop_loop("activity" + tag, 0.3)
		if act.loop_sound in ["vinyl", "music_house"]:
			_duck(-1)
	if act.end_sound != "":
		audio.play_at(act.end_sound, at, -4.0)
	if act.glow != "" and room.has(act.glow):
		var gm: StandardMaterial3D = room[act.glow]
		_glow_users[gm] = int(_glow_users.get(gm, 1)) - 1
		if _glow_users[gm] <= 0:
			_glow_users.erase(gm)
			gm.emission_energy_multiplier = float(_glow_base.get(gm, 0.0))
	if obj.kind == "pizza_box":
		set_pizza(obj.home, false)
	if obj.kind == "bowling_lane" and room.has("bowling_lanes"):
		(room["bowling_lanes"] as BowlingLanes).set_bowling(int(obj.get_meta("lane", 0)), false)
	if obj.kind == "easter_egg" and not net.is_client():
		holidays.found_egg(obj)
	if obj.kind == "snow_drift" and act.title == "Build a Snowman":
		seasons.built_snowman()
	if local:
		hud.set_items(who.items)
	if act.drive and obj is Car and not local:
		var car := obj as Car
		car.driver = null
		car.remote = false
		car.set_driving(false, false)
	if local and rig.mode != CameraRig.Mode.HOUSE and act.pose == "lie":
		rig.face_yaw(sim.facing_yaw())


## Wave, dance, cheer: your kid does it, and everyone else (online) sees it.
## Space / X: hop (everyone online sees it).
func do_jump() -> void:
	if net.is_client():
		if sim.jump():
			net.send_emote(sim.slot, "jump")
		return
	if sim.jump() and net.is_online():
		net.send_emote(sim.slot, "jump")


func do_emote(kind: String) -> void:
	if net.is_client():
		net.send_emote(sim.slot, kind)
		sim.emote(kind)
		return
	if not sim.emote(kind):
		hud.notify("Stand still (and stop what you're doing) to do that.")
		return
	if net.is_online():
		net.send_emote(sim.slot, kind)
	if rig.mode != CameraRig.Mode.HOUSE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Something from the mall (or the skate shop) is yours now.
func _on_bought(who: Sim, id: String) -> void:
	if id.begins_with("outfit_"):
		var lk := who.look.duplicate()
		lk["outfit"] = int(id.substr(7))
		who.set_look(lk)
		if net.is_online():
			net.send_look_for(who.slot, lk)
		if Catalog.OUTFIT_PRICES.has(int(id.substr(7))):
			_tell(who, "You put it on right away. Looking sharp! (Change outfits any time at your dresser.)")
	if Catalog.group(id) == "computer":
		update_computers()
	var mem := String(Catalog.ITEMS.get(id, {}).get("memory", ""))
	if mem != "":
		award_memory(who, mem)


## Someone called a kid on the phone: if a player is that kid, their phone rings.
func _on_called(caller: Sim, callee_home: String) -> void:
	for s: Sim in sims.values():
		if s != caller and s.home == callee_home:
			var text := "Ring ring! %s called you on the phone." % caller.character_name
			if s == sim:
				hud.notify(text)
				audio.play_ui("phone_ring", -8.0)
			elif split.is_p2(s):
				split.notify(text)
			elif net.is_host():
				net.send_notice(s.slot, text)


## The computer on each kid's desk: the best one anybody in that house owns.
func update_computers() -> void:
	for k in room["objects"]:
		var d: SmartObject = room["objects"][k]
		if d.kind != "desk" or not d.has_meta("computers"):
			continue
		var best := ""
		for s: Sim in sims.values():
			if s.home == d.home:
				var b := Catalog.best_computer(s.owned)
				if b != "" and (best == "" or Catalog.COMPUTER_ORDER.find(b) < Catalog.COMPUTER_ORDER.find(best)):
					best = b
		var models: Dictionary = d.get_meta("computers")
		for id in models:
			(models[id] as Node3D).visible = id == best


## A newspaper flies from the kid's hand to the porch (and stays there a while).
func _throw_paper(who: Sim, porch: SmartObject) -> void:
	var p := Node3D.new()
	add_child(p)
	RoomBuilder.box(p, Vector3(0.28, 0.08, 0.1), Vector3.ZERO, Palette.PAPER)
	RoomBuilder.box(p, Vector3(0.29, 0.02, 0.11), Vector3(0, 0.0, 0), Palette.CORAL)
	var from := who.global_position + Vector3(0, 1.1, 0)
	var to := porch.look_point
	to.y = 0.08
	p.global_position = from
	var tw := create_tween()
	tw.tween_method(func(t: float):
		if is_instance_valid(p):
			p.global_position = from.lerp(to, t) + Vector3(0, sin(t * PI) * 1.4, 0)
			p.rotation.y = t * 9.0, 0.0, 1.0, 0.7)
	tw.tween_interval(20.0)
	tw.tween_callback(p.queue_free)


## A kid bought a bike, got on it, or hopped off (the host / offline decides; everyone sees it).
func _on_bike_event(s: Sim, what: String) -> void:
	var b: SmartObject = room["objects"].get("bike_" + s.home)
	if b == null:
		return
	match what:
		"bought":
			var shop := DowntownBuilder.shop_rect("bikes")
			set_bike(s.home, true, Vector3(shop.position.x + 1.2 + s.slot * 0.9, 0, 54.9), PI / 2.0)
		"mount":
			set_bike(s.home, false, b.global_position, b.rotation.y)
		"park":
			var at := s.global_position + s.global_basis.x * 0.7
			set_bike(s.home, true, at, s.rotation.y)


func set_bike(home: String, shown: bool, at: Vector3, yaw: float) -> void:
	var b: SmartObject = room["objects"].get("bike_" + home)
	if b == null:
		return
	b.visible = shown
	b.collision_layer = 1 if shown else 0
	OutdoorBuilder.place_bike(b, at, yaw)
	if net.is_host():
		net.send_bike(home, shown, at, yaw)


## Jiggle a locked door's handle.
func _rattle(d: SmartObject) -> void:
	var base := d.door_rattle.position
	var tw := create_tween()
	for i in 4:
		tw.tween_property(d.door_rattle, "position", base + d.rattle_dir * (1.0 if i % 2 == 0 else -1.0), 0.06)
	tw.tween_property(d.door_rattle, "position", base, 0.06)


# ================================================================ diary

func _open_diary() -> void:
	_diary_speed = clock.speed_level if clock.speed_level > 0 else 1
	_set_speed(0)                   # time stops while you write (offline)
	rig.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	audio.play_ui("page_flip", -4.0)
	hud.open_diary(diary.entries, "%s · %s %s" % [clock.long_date(), clock.time_label(), clock.ampm()])


func _on_diary_saved(text: String) -> void:
	diary.add(clock.long_date(), "%s %s" % [clock.time_label(), clock.ampm()], text)
	audio.play_ui("page_flip", -6.0)


func _on_diary_closed() -> void:
	audio.play_ui("page_flip", -6.0)
	_set_speed(_diary_speed)
	rig.input_enabled = true
	if rig.mode != CameraRig.Mode.HOUSE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


var _door_opened_at := {}


func _open_door(d: SmartObject) -> void:
	_door_opened_at[d] = Time.get_ticks_msec()
	var tw := create_tween()
	tw.tween_property(d.door_hinge, "rotation:y", d.door_open_angle, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Keeps the door open at least ~2.5 real seconds, even at top speed.
func _close_door(d: SmartObject) -> void:
	var held := (Time.get_ticks_msec() - int(_door_opened_at.get(d, 0))) / 1000.0
	var tw := create_tween()
	tw.tween_interval(maxf(0.0, 2.5 - held))
	tw.tween_property(d.door_hinge, "rotation:y", 0.0, 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# The sound's whoosh lasts ~0.16 s before the thud, so start it just before the door shuts.
	tw.parallel().tween_callback(func(): audio.play_at("door_close", d.look_point, -1.0)).set_delay(0.29)


func _on_camera_mode(mode: int) -> void:
	hud.set_camera_mode(mode)
	if hovered:
		hovered.set_highlight(false)
		hovered = null


func _on_menu_closed() -> void:
	if rig.mode != CameraRig.Mode.HOUSE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ================================================================ input

func _unhandled_input(event: InputEvent) -> void:
	# Show gamepad or keyboard hints, whichever was used last.
	if InputSetup.is_pad(event):
		hud.set_using_pad(true)
	elif InputSetup.is_keyboard_mouse(event):
		hud.set_using_pad(false)
	if menus.is_open() or in_title or customizer.is_open() or chat.is_open():
		return
	if net.is_online() and event is InputEventKey and event.pressed and not event.echo \
			and ((event as InputEventKey).physical_keycode == KEY_T or (event as InputEventKey).physical_keycode == KEY_ENTER) \
			and not hud.menu_open and driving == null:
		chat.open()
		rig.input_enabled = false
		get_viewport().set_input_as_handled()
		return
	if hud.diary_open:
		if event.is_action_pressed("pause_menu") or event.is_action_pressed("pad_back"):
			hud.close_diary()
		return

	if event.is_action_pressed("pause_menu"):
		if hud.menu_open:
			hud.close_menu()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pad_back"):
		hud.close_menu()
		return
	if driving:
		_driving_input(event)
		return
	if event.is_action_pressed("camera_cycle"):
		hud.close_menu()
		rig.cycle()
	elif event.is_action_pressed("music"):
		hud.set_music_button(not audio.music_on)
		audio.set_music(not audio.music_on)
	elif event.is_action_pressed("emote") and not hud.menu_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.open_emotes(split.p1_size() / 2.0 + Vector2(30, -200))
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("free_will"):
		sim.free_will = not sim.free_will
		hud.set_free_will_button(sim.free_will)
		hud.notify("Free Will is %s." % ("on" if sim.free_will else "off"))
	elif event.is_action_pressed("time_pause"):
		_toggle_time()
	elif event.is_action_pressed("jump") and not hud.menu_open:
		do_jump()
	elif event.is_action_pressed("speed_up"):
		_set_speed(mini(3, clock.speed_level + 1))
	elif event.is_action_pressed("speed_down"):
		_set_speed(maxi(1, clock.speed_level - 1) if clock.speed_level > 0 else 0)
	elif event.is_action_pressed("zoom_in"):
		rig.zoom(-1.5)
	elif event.is_action_pressed("zoom_out"):
		rig.zoom(1.5)
	elif event.is_action_pressed("horn") and InputSetup.is_pad(event):
		_cancel(0)   # (X) on a gamepad: stop what Jamie is doing
	elif event.is_action_pressed("pad_use") and not hud.menu_open:
		if rig.mode == CameraRig.Mode.HOUSE:
			if _cursor.x >= 0.0:
				_click(_cursor)
		else:
			_interact_center()

	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				_set_speed(1)
			KEY_2:
				_set_speed(2)
			KEY_3:
				_set_speed(3)
			KEY_TAB:
				if rig.mode != CameraRig.Mode.HOUSE:
					var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED
			KEY_E:
				if rig.mode != CameraRig.Mode.HOUSE and not hud.menu_open:
					_interact_center()
		return

	if split.active and event is InputEventMouse and (event as InputEventMouse).position.x > split.p1_size().x:
		return
	if rig.mode == CameraRig.Mode.HOUSE:
		if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if event.pressed:
						if hud.menu_open:
							hud.close_menu()
						else:
							_click(event.position)
				MOUSE_BUTTON_RIGHT:
					rig.dragging = event.pressed
				MOUSE_BUTTON_WHEEL_UP:
					rig.zoom(-0.8)
				MOUSE_BUTTON_WHEEL_DOWN:
					rig.zoom(0.8)
		elif event is InputEventMouseMotion:
			if rig.dragging:
				rig.rotate_house(-event.relative.x * 0.01)
			else:
				_hover(event.position)
	else:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rig.mouse_look(event.relative)
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				_interact_center()
			elif not hud.menu_open:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _toggle_time() -> void:
	if net.is_online():
		hud.notify("Online, time can't be paused.")
		return
	if clock.speed_level == 0:
		clock.set_speed(last_speed)
	else:
		last_speed = clock.speed_level
		clock.set_speed(0)


func _driving_input(event: InputEvent) -> void:
	if event.is_action_pressed("horn"):
		driving.honk()
		if net.is_online():
			net.send_horn(driving.key)
	elif event.is_action_pressed("pad_use") or (event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_E):
		if hud.menu_open:
			return
		if _at_drive_thru(EastBuilder.DT_MENU) and _dt_order == null:
			_open_drive_thru_menu()
		else:
			_try_exit_car()
	elif event.is_action_pressed("music"):
		hud.set_music_button(not audio.music_on)
		audio.set_music(not audio.music_on)
	elif event.is_action_pressed("time_pause"):
		_toggle_time()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rig.mouse_look(event.relative)


func _physics_process(delta: float) -> void:
	if driving:
		_drive_physics(delta)
		return
	if rig.mode == CameraRig.Mode.HOUSE or rig.mode == CameraRig.Mode.TITLE:
		return
	var dir := Vector3.ZERO
	if not hud.menu_open and not hud.diary_open and not menus.is_open() and not chat.is_open() and not customizer.is_open():
		var mb := rig.move_basis()
		var f: Vector3 = mb[0]
		var r: Vector3 = mb[1]
		var v := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		dir = f * v.y + r * v.x
		rig.stick_look(Input.get_vector("look_left", "look_right", "look_up", "look_down"), delta)
	sim.running = Input.is_action_pressed("run") and dir.length() > 0.0
	sim.drive(dir, delta)
	if net.is_client() and sim.local_control:
		net.send_my_move(sim)
	var obj := _ray_center()
	_set_hovered(obj)
	hud.set_prompt(obj)


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | RoomBuilder.LAYER_FLOOR)
	return get_world_3d().direct_space_state.intersect_ray(q)


func _ray_center() -> SmartObject:
	var reach := 3.2 if rig.mode == CameraRig.Mode.FIRST else 5.4
	var from := rig.cam.global_position
	var hit := _ray(from, from - rig.cam.global_basis.z * reach)
	if hit.is_empty():
		return null
	return hit["collider"] as SmartObject


func _set_hovered(obj: SmartObject) -> void:
	if obj == hovered:
		return
	if hovered:
		hovered.set_highlight(false)
	hovered = obj
	if hovered:
		hovered.set_highlight(true)


func _hover(pos: Vector2) -> void:
	var from := rig.cam.project_ray_origin(pos)
	var hit := _ray(from, from + rig.cam.project_ray_normal(pos) * 100.0)
	_set_hovered(null if hit.is_empty() else hit["collider"] as SmartObject)


func _click(pos: Vector2) -> void:
	var from := rig.cam.project_ray_origin(pos)
	var hit := _ray(from, from + rig.cam.project_ray_normal(pos) * 100.0)
	if hit.is_empty():
		return
	var obj := hit["collider"] as SmartObject
	if obj:
		hud.open_menu(obj, pos)
	elif (hit["collider"] as Node).is_in_group("floor"):
		_walk_to(hit["position"])


func _interact_center() -> void:
	var obj := _ray_center()
	if obj == null:
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var vp := split.p1_size()
	hud.open_menu(obj, vp / 2.0 + Vector2(30, -40))


# ================================================================ dev hooks

## Command-line helpers for testing, e.g.:
##   godot --path . -- --cam=first --hour=19 --shot=user://shot.png
func _dev_hooks() -> void:
	var shot := ""
	var wait := 4.0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--wait="):
			wait = float(arg.get_slice("=", 1))
		if arg.begins_with("--cam="):
			rig.set_mode(["house", "shoulder", "first"].find(arg.get_slice("=", 1)))
		elif arg.begins_with("--split"):
			SplitScreen.fake = true
			var go := arg.get_slice("=", 1) if arg.contains("=") else ""
			get_tree().create_timer(0.5).timeout.connect(func():
				split.start(1)
				if go != "" and go != "pick":
					split.debug_pick(int(go)))
		elif arg.begins_with("--hour="):
			clock.unix_time += int(float(arg.get_slice("=", 1)) * 3600.0) - 8 * 3600
			_update_lighting()
		elif arg.begins_with("--speed="):
			clock.set_speed(int(arg.get_slice("=", 1)))
		elif arg.begins_with("--shot="):
			shot = arg.get_slice("=", 1)
		elif arg.begins_with("--env:"):
			# e.g. --env:glow_enabled=false
			var kv := arg.substr(6).split("=")
			env.set(kv[0], str_to_var(kv[1]))
		elif arg.begins_with("--menu="):
			var o: SmartObject = room["objects"].get(arg.get_slice("=", 1))
			if o:
				hud.open_menu(o, Vector2(700, 300))
		elif arg.begins_with("--do="):
			# e.g. --do=front_door:0 queues that object's first activity
			var parts := arg.get_slice("=", 1).split(":")
			var o2: SmartObject = room["objects"].get(parts[0])
			if o2:
				sim.enqueue(o2, o2.activities[int(parts[1]) if parts.size() > 1 else 0])
		elif arg.begins_with("--view="):
			# House Cam aim: --view=x,z,distance[,yaw degrees]
			var v := arg.get_slice("=", 1).split(",")
			# (add ",down" for the attics and basements: they're built underground)
			rig.target = Vector3(float(v[0]), (RoomBuilder.INTERIOR_Y if v[v.size() - 1] == "down" else 0.0) + 0.4, float(v[1]))
			rig.house_dist = float(v[2])
			if v.size() > 3 and v[3] != "down":
				rig.house_yaw = deg_to_rad(float(v[3]))
			_current_room = "(fixed)"
		elif arg.begins_with("--yaw="):
			sim.rotation.y = deg_to_rad(float(arg.get_slice("=", 1)))
			sim._face_yaw = sim.rotation.y
			rig.face_yaw(sim.rotation.y)
		elif arg.begins_with("--pos="):
			var p := arg.get_slice("=", 1).split(",")
			sim.set_level(1 if p[p.size() - 1] == "down" else 0)
			sim.global_position = Vector3(float(p[0]), sim.floor_at(float(p[0]), float(p[1])), float(p[1]))
			rig.target = cam_point(sim.global_position)
		elif arg.begins_with("--drive="):
			var car = room["objects"].get(arg.get_slice("=", 1))
			if car is Car:
				sim.enqueue(car, car.activities[0])
		elif arg == "--host":
			_on_host(false)
		elif arg.begins_with("--join="):
			_on_join(arg.get_slice("=", 1))
		elif arg == "--pad":
			hud.set_using_pad(true)
		elif arg == "--pause":
			_open_pause.call_deferred()
		elif arg.begins_with("--date="):
			# e.g. --date=7-4 (keeps the time of day)
			var md := arg.get_slice("=", 1).split("-")
			var h := clock.hour_float()
			clock.unix_time = int(Time.get_unix_time_from_datetime_dict({"year": 1986, "month": int(md[0]), "day": int(md[1]),
				"hour": int(h), "minute": int((h - int(h)) * 60.0), "second": 0}))
			_update_lighting()
			holidays.refresh()
			seasons.refresh()
		elif arg == "--newgame":
			_on_new_game()
		elif arg.begins_with("--burglar"):
			# --burglar (at your house) or --burglar=nguyens
			var bh := arg.get_slice("=", 1) if "=" in arg else sim.home
			town_life.start_burglary(bh)
		elif arg.begins_with("--goto="):
			# stand next to an object: --goto=police_car or --goto=bleachers
			var gk := arg.get_slice("=", 1)
			var go: Node3D = room["objects"].get(gk)
			if go == null:
				for v in town_life.vehicles:
					if (v as NpcVehicle).key == gk:
						go = v
			if go:
				var gp: Vector3 = (go as SmartObject).approach_point if go is SmartObject else go.global_position + Vector3(2.5, 0, 0)
				sim.place(Vector3(gp.x, 0, gp.z), sim.rotation.y)
				rig.target = cam_point(sim.global_position)
		elif arg.begins_with("--bike"):
			sim.bike = true
			_on_bike_event(sim, "bought")
			if arg == "--bike=ride":
				sim.riding = true
				sim._set_pose("bike")
				_on_bike_event(sim, "mount")
		elif arg == "--who":
			_on_host(false)
		elif arg == "--chat":
			net.mode = Net.Mode.HOST
			chat.add_line("", "Rosa Garcia joined the game!")
			chat.add_line("Rosa", "hey!! meet me at the arcade")
			chat.add_line("Danny", "omw, gotta get my allowance first lol")
			chat.open()
		elif arg == "--nopost":
			post_mat.set_shader_parameter("enabled", false)
	if _has_dev_args():
		settle_npcs()
	if shot != "":
		await get_tree().create_timer(wait).timeout
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot)
		print("Saved screenshot to ", shot)
		get_tree().quit()
