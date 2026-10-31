class_name Net
extends Node
## Online play for up to 4 people (Godot's built-in networking over ENet/UDP).
##
## One player HOSTS: their computer runs the whole game (the clock, every
## character's needs and activities, Free Will, the townspeople). Up to three
## friends JOIN by typing the host's IP address. Everyone picks which of the six
## Maple Street kids to play (one each) and how they look, and can chat.
##
##   friend's computer  --- requests --->  host   (do this, walk there, cancel...)
##   friend's computer  <--- updates ----  host   (where everyone is, 15 times a second;
##                                                 needs, money and plans twice a second;
##                                                 "X started/stopped doing Y" events)
##
## Two things run on the player's own computer so they feel instant, and are
## sent to the host: walking your own character with WASD/stick, and driving.
## Online, time always runs at normal speed (no pausing or fast-forward), except
## that nights fly by once everyone is asleep.

const PORT := 24886
const MAX_PLAYERS := 4
const PROTOCOL := 6            # bump when these messages change; old copies can't join
const SNAPSHOT_HZ := 15.0
const STATUS_HZ := 2.0
const SEND_HZ := 20.0          # how often a player sends their walking / driving

signal joined(slot: int)                 # (friend) the host let us in
signal join_failed(reason: String)       # (friend) couldn't get in
signal lost(reason: String)              # (friend) the connection ended

enum Mode { OFFLINE, HOST, CLIENT }

## Survives going back to the title screen, to say why (e.g. "The host left").
static var last_message := ""

var mode := Mode.OFFLINE
var main: Node
var peer_slot := {}            # host: peer id -> character slot
var slot_store := {}           # host: "slot" -> saved progress of a player who isn't here
var my_slot := 0
var _snap_t := 0.0
var _status_t := 0.0
var _send_t := 0.0
var _last_jobs := {}           # host: slot -> last Up Next list sent
var host_slot := 0             # which kid the host plays
var _npc_t := 0.0
const NPC_HZ := 6.0


func is_online() -> bool:
	return mode != Mode.OFFLINE


func is_host() -> bool:
	return mode == Mode.HOST


func is_client() -> bool:
	return mode == Mode.CLIENT


## This computer's addresses on the local network (to tell friends).
static func local_ips() -> Array:
	var out := []
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254."):
			out.append(a)
	return out


# ================================================================ starting and stopping

func host(port := PORT) -> int:
	var p := ENetMultiplayerPeer.new()
	var err := p.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = p
	mode = Mode.HOST
	my_slot = 0
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return OK


func join(address: String, port := PORT) -> int:
	var p := ENetMultiplayerPeer.new()
	var err := p.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = p
	mode = Mode.CLIENT
	if not multiplayer.connected_to_server.is_connected(_on_connected):
		multiplayer.connected_to_server.connect(_on_connected)
		multiplayer.connection_failed.connect(func():
			join_failed.emit("Couldn't reach the host. Check the IP address, and that the host's router lets port %d through." % PORT))
		multiplayer.server_disconnected.connect(func(): lost.emit("The host ended the game."))
	return OK


func leave() -> void:
	if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = Mode.OFFLINE
	peer_slot.clear()


## The names of everyone here, for the pause menu.
func player_list() -> Array:
	var out := []
	for slot in main.sims:
		var ch: Dictionary = Sim.CHARACTERS[slot]
		var who := "you" if main.sims[slot] == main.sim else ("host" if slot == host_slot else "")
		out.append("%s%s" % [ch.get("full", ch["name"]), (" (%s)" % who) if who != "" else ""])
	return out


# ================================================================ host: players coming and going

func _on_peer_connected(_id: int) -> void:
	pass   # we wait for their hello (with the version) before letting them in


func _on_peer_disconnected(id: int) -> void:
	if not peer_slot.has(id):
		return
	var slot: int = peer_slot[id]
	peer_slot.erase(id)
	var s: Sim = main.sims.get(slot)
	if s:
		slot_store[str(slot)] = SaveGame.sim_state(s)
	main.remove_sim(slot)
	sim_removed.rpc(slot)
	main.hud.notify("%s went home. (Left the game)" % Sim.CHARACTERS[slot]["name"])
	main.chat.add_line("", "%s left the game." % Sim.CHARACTERS[slot]["name"])


@rpc("any_peer", "call_remote", "reliable")
func rq_hello(protocol: int) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if protocol != PROTOCOL:
		kicked.rpc_id(id, "Your copy of Rewind Life is a different version from the host's (the host has v%s). Use the same version." % Changelog.VERSION)
		_drop_later(id)
		return
	if main.sims.size() >= MAX_PLAYERS:
		kicked.rpc_id(id, "The game is full (4 players).")
		_drop_later(id)
		return
	_offer_choice(id, "Pick a kid! (The host is playing %s.)" % Sim.CHARACTERS[host_slot]["full"])


## Tell a friend who's still free to play, and how the saved kids look.
func _offer_choice(id: int, note: String) -> void:
	var looks := {}
	for k in slot_store:
		looks[int(k)] = (slot_store[k] as Dictionary).get("look", {})
	choose.rpc_id(id, main.sims.keys(), looks, note)


@rpc("any_peer", "call_remote", "reliable")
func rq_pick(slot: int, look: Dictionary) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if peer_slot.has(id):
		return
	if slot < 0 or slot >= Sim.CHARACTERS.size() or main.sims.has(slot):
		_offer_choice(id, "Someone just picked %s. Pick another kid!" % Sim.CHARACTERS[clampi(slot, 0, 5)]["full"])
		return
	if main.sims.size() >= MAX_PLAYERS:
		kicked.rpc_id(id, "The game is full (4 players).")
		_drop_later(id)
		return
	peer_slot[id] = slot
	var s: Sim = main.add_sim(slot, false)
	if slot_store.has(str(slot)):
		SaveGame.apply_sim_state(s, slot_store[str(slot)])
		slot_store.erase(str(slot))
	s.set_look(clean_look(look))
	welcome.rpc_id(id, slot, world_state())
	for other in peer_slot:
		if other != id:
			sim_added.rpc_id(other, slot, _sim_full(s))
	var msg := "%s joined the game!" % Sim.CHARACTERS[slot].get("full", "")
	main.hud.notify(msg)
	main.chat.add_line("", msg)


## Only the keys a look should have (and sane numbers).
static func clean_look(l: Dictionary) -> Dictionary:
	var out := Looks.normalized({})
	out["gender"] = "girl" if String(l.get("gender", "boy")) == "girl" else "boy"
	out["hair"] = Looks.HAIR_STYLES[Looks.hair_index(String(l.get("hair", "mullet")))][0]
	out["hair_color"] = clampi(int(l.get("hair_color", 1)), 0, Looks.HAIR_COLORS.size() - 1)
	out["skin"] = clampi(int(l.get("skin", 1)), 0, Looks.SKIN_TONES.size() - 1)
	out["outfit"] = clampi(int(l.get("outfit", 0)), 0, Looks.OUTFITS.size() - 1)
	return out


func _drop_later(id: int) -> void:
	get_tree().create_timer(1.0).timeout.connect(func():
		if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
			(multiplayer.multiplayer_peer as ENetMultiplayerPeer).disconnect_peer(id))


## Everything a new player needs to see the world as it is right now.
func world_state() -> Dictionary:
	var people := {}
	for slot in main.sims:
		people[slot] = _sim_full(main.sims[slot])
	var cars := []
	for c: Car in main.room.get("cars", []):
		cars.append([c.key, c.global_position.x, c.global_position.z, c.global_rotation.y])
	var pizzas := []
	for k in main.room["objects"]:
		var o: SmartObject = main.room["objects"][k]
		if o.kind == "pizza_box" and o.visible:
			pizzas.append(o.home)
	return {"time": main.clock.unix_time, "boost": main.clock.boost, "sims": people, "cars": cars, "pizzas": pizzas,
		"host_slot": host_slot, "npcs": _npc_states(), "family": Families.jamie, "lights": main.lights_off.keys(),
		"doors": main.locked_doors(), "bikes": _bike_states(), "vehicles": _vehicle_states()}


func _sim_full(s: Sim) -> Dictionary:
	var d := SaveGame.sim_state(s)
	d["net"] = s.net_state()
	d["jobs"] = s.jobs()
	if not s.current.is_empty():
		var obj: SmartObject = s.current["obj"]
		d["doing"] = [main.obj_keys.get(obj, ""), obj.activities.find(s.current["act"]),
			s.current.get("busy", false), s.current.get("player", false)]
	return d


# ================================================================ friend: getting in

func _on_connected() -> void:
	rq_hello.rpc_id(1, PROTOCOL)


@rpc("authority", "call_remote", "reliable")
func choose(taken: Array, looks: Dictionary, note: String) -> void:
	main.on_choose(taken, looks, note)


@rpc("authority", "call_remote", "reliable")
func welcome(slot: int, world: Dictionary) -> void:
	my_slot = slot
	host_slot = int(world.get("host_slot", 0))
	main.start_as_guest(slot, world)
	joined.emit(slot)


@rpc("authority", "call_remote", "reliable")
func kicked(reason: String) -> void:
	lost.emit(reason)


@rpc("authority", "call_remote", "reliable")
func sim_added(slot: int, d: Dictionary) -> void:
	var s: Sim = main.add_sim(slot, true)
	_apply_full(s, d)
	main.hud.notify("%s joined the game!" % Sim.CHARACTERS[slot].get("full", ""))
	main.chat.add_line("", "%s joined the game!" % Sim.CHARACTERS[slot].get("full", ""))


@rpc("authority", "call_remote", "reliable")
func sim_removed(slot: int) -> void:
	if main.sims.has(slot):
		main.hud.notify("%s went home. (Left the game)" % Sim.CHARACTERS[slot]["name"])
		main.chat.add_line("", "%s left the game." % Sim.CHARACTERS[slot]["name"])
	main.remove_sim(slot)


func _apply_full(s: Sim, d: Dictionary) -> void:
	SaveGame.apply_sim_state(s, d)
	s.net_apply(d["net"])
	s.global_position = Vector3(s.net_pos.x, s.global_position.y, s.net_pos.z)
	s.net_jobs = d.get("jobs", [])


# ================================================================ host -> everyone: updates

func _process(delta: float) -> void:
	if not is_host() or peer_slot.is_empty():
		return
	_snap_t += delta
	_status_t += delta
	_npc_t += delta
	if _npc_t >= 1.0 / NPC_HZ:
		_npc_t = 0.0
		npc_snapshot.rpc(_npc_packed())
	if _snap_t >= 1.0 / SNAPSHOT_HZ:
		_snap_t = 0.0
		var people := []
		for slot in main.sims:
			var st: Array = (main.sims[slot] as Sim).net_state()
			st.push_front(slot)
			people.append(st)
		var cars := []
		for c: Car in main.room.get("cars", []):
			if c.driver != null:
				cars.append([c.key, c.global_position.x, c.global_position.z, c.global_rotation.y, c.speed, c.steer])
		snapshot.rpc(main.clock.unix_time, main.clock.boost, people, cars)
	if _status_t >= 1.0 / STATUS_HZ:
		_status_t = 0.0
		for slot in main.sims:
			var s: Sim = main.sims[slot]
			status.rpc(slot, s.needs.values, s.needs.mood_bonus, s.money, s.jobs(), s.free_will, s.items, s.owned)


@rpc("authority", "call_remote", "unreliable_ordered")
func snapshot(time: int, boost: float, people: Array, cars: Array) -> void:
	var clock: GameClock = main.clock
	if absi(clock.unix_time - time) > 45:
		clock.unix_time = time
		main._update_lighting()
	clock.boost = boost
	for st in people:
		var s: Sim = main.sims.get(int(st[0]))
		if s:
			s.net_apply(st.slice(1))
	for cd in cars:
		var c: Car = main.room["objects"].get(cd[0])
		if c and c != main.driving:
			c.remote_update(Vector3(cd[1], 0, cd[2]), cd[3], cd[4], cd[5])


@rpc("authority", "call_remote", "reliable")
func status(slot: int, needs: Dictionary, mood_bonus: float, money: float, jobs: Array, free_will: bool, items: Dictionary, owned: Dictionary = {}) -> void:
	var s: Sim = main.sims.get(slot)
	if s == null:
		return
	for n in needs:
		s.needs.values[n] = float(needs[n])
	s.needs.mood_bonus = mood_bonus
	s.money = money
	s.free_will = free_will
	s.items = items
	s.owned = owned
	if s == main.sim:
		main.hud.set_free_will_button(free_will)
		main.hud.set_money(money)
		main.hud.set_items(items)
	if jobs != s.net_jobs:
		s.net_jobs = jobs
		s.queue_changed.emit()


## Called by main.gd on the host when anyone starts / stops an activity.
func send_started(who: Sim, obj: SmartObject, act: Activity) -> void:
	if peer_slot.is_empty():
		return
	ev_started.rpc(who.slot, main.obj_keys.get(obj, ""), obj.activities.find(act),
		{"busy": who.current.get("busy", false), "player": who.current.get("player", false)})


func send_finished(who: Sim, obj: SmartObject, act: Activity) -> void:
	if peer_slot.is_empty():
		return
	ev_finished.rpc(who.slot, main.obj_keys.get(obj, ""), obj.activities.find(act))


@rpc("authority", "call_remote", "reliable")
func ev_started(slot: int, key: String, idx: int, info: Dictionary) -> void:
	var s: Sim = main.sims.get(slot)
	var obj: SmartObject = main.room["objects"].get(key)
	if s and obj and idx >= 0 and idx < obj.activities.size():
		main._on_activity_started(obj.activities[idx], obj, s, info)


@rpc("authority", "call_remote", "reliable")
func ev_finished(slot: int, key: String, idx: int) -> void:
	var s: Sim = main.sims.get(slot)
	var obj: SmartObject = main.room["objects"].get(key)
	if s and obj and idx >= 0 and idx < obj.activities.size():
		main._on_activity_finished(obj.activities[idx], obj, s)


## A message for one player only (e.g. "Too late for that").
func send_notice(slot: int, text: String) -> void:
	for id in peer_slot:
		if peer_slot[id] == slot:
			notice.rpc_id(id, text)


@rpc("authority", "call_remote", "reliable")
func notice(text: String) -> void:
	main.hud.notify(text)


func send_car_parked(c: Car) -> void:
	if peer_slot.is_empty():
		return
	car_parked.rpc(c.key, c.global_position.x, c.global_position.z, c.global_rotation.y)


@rpc("authority", "call_remote", "reliable")
func car_parked(key: String, x: float, z: float, yaw: float) -> void:
	var c: Car = main.room["objects"].get(key)
	if c == null or c == main.driving:
		return
	c.global_position = Vector3(x, 0, z)
	c.rotation.y = yaw
	c.remote = false
	c.speed = 0.0
	main.park_car(c, true)


@rpc("authority", "call_remote", "reliable")
func pizza(home: String, on: bool) -> void:
	main.set_pizza(home, on)


@rpc("authority", "call_remote", "reliable")
func ring_doorbell(at: Vector3) -> void:
	main.audio.play_at("doorbell", at, 0.0)


@rpc("any_peer", "call_remote", "reliable")
func horn(key: String) -> void:
	var c: Car = main.room["objects"].get(key)
	if c:
		c.honk()
	if is_host():
		var from := multiplayer.get_remote_sender_id()
		for id in peer_slot:
			if id != from:
				horn.rpc_id(id, key)


func send_horn(key: String) -> void:
	if is_host():
		horn.rpc(key)
	elif is_client():
		horn.rpc_id(1, key)


# ================================================================ friend -> host: requests

func _sender_sim() -> Sim:
	var id := multiplayer.get_remote_sender_id()
	if not is_host() or not peer_slot.has(id):
		return null
	return main.sims.get(peer_slot[id])


@rpc("any_peer", "call_remote", "reliable")
func rq_enqueue(key: String, idx: int) -> void:
	var s := _sender_sim()
	var obj: SmartObject = main.room["objects"].get(key)
	if s and obj and idx >= 0 and idx < obj.activities.size():
		s.enqueue(obj, obj.activities[idx], true)


@rpc("any_peer", "call_remote", "reliable")
func rq_walk(x: float, z: float) -> void:
	var s := _sender_sim()
	if s:
		s.walk_here(Vector3(x, 0, z))


@rpc("any_peer", "call_remote", "reliable")
func rq_cancel(i: int) -> void:
	var s := _sender_sim()
	if s:
		s.cancel(i)


@rpc("any_peer", "call_remote", "reliable")
func rq_free_will(on: bool) -> void:
	var s := _sender_sim()
	if s:
		s.free_will = on


@rpc("any_peer", "call_remote", "unreliable_ordered")
func rq_move(x: float, z: float, yaw: float) -> void:
	var s := _sender_sim()
	if s and not s.hidden:
		s.remote_move(Vector3(x, 0, z), yaw)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func rq_car(key: String, x: float, z: float, yaw: float, spd: float, st: float) -> void:
	var s := _sender_sim()
	var c: Car = main.room["objects"].get(key)
	if s and c and c.driver == s:
		c.remote_update(Vector3(x, 0, z), yaw, spd, st)
		s.global_position = Vector3(x, 0, z)   # rides along (for saving)


@rpc("any_peer", "call_remote", "reliable")
func rq_exit_car(key: String, cx: float, cz: float, cyaw: float, sx: float, sz: float, syaw: float) -> void:
	var s := _sender_sim()
	var c: Car = main.room["objects"].get(key)
	if s and c and c.driver == s:
		main.exit_car_remote(s, c, Vector3(cx, 0, cz), cyaw, Vector3(sx, 0, sz), syaw)


## (friend) Where I'm walking, a few times a second.
func send_my_move(s: Sim) -> void:
	_send_t += get_physics_process_delta_time()
	if _send_t < 1.0 / SEND_HZ:
		return
	_send_t = 0.0
	rq_move.rpc_id(1, s.global_position.x, s.global_position.z, s._face_yaw)


## (friend) Where my car is.
func send_my_car(c: Car) -> void:
	_send_t += get_physics_process_delta_time()
	if _send_t < 1.0 / SEND_HZ:
		return
	_send_t = 0.0
	rq_car.rpc_id(1, c.key, c.global_position.x, c.global_position.z, c.global_rotation.y, c.speed, c.steer)


# ================================================================ townspeople, memories, looks, chat

func _npc_states() -> Array:
	var out := []
	for n: Npc in main.npcs:
		out.append(n.net_state())
	return out


## Everyone in town (and the trucks they drive), packed small (4 numbers each)
## so it fits in one network packet.
func _npc_packed() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for n: Npc in main.npcs:
		var st := n.net_state()
		out.append_array([st[0], st[1], st[2], (1.0 if st[3] else 0.0) + (2.0 if st[4] else 0.0) + (4.0 if n.has_meta("hands_up") else 0.0)
			+ (8.0 if n.has_meta("running") else 0.0)])
	for v: NpcVehicle in main.town_life.vehicles:
		out.append_array(v.net_state())
	return out


@rpc("authority", "call_remote", "unreliable_ordered")
func npc_snapshot(packed: PackedFloat32Array) -> void:
	var states := []
	var n_npc: int = main.npcs.size()
	for i in range(0, mini(packed.size(), n_npc * 4) - 3, 4):
		var f := int(packed[i + 3])
		states.append([packed[i], packed[i + 1], packed[i + 2], f & 1 != 0, f & 2 != 0, f & 4 != 0])
	apply_npcs(states)
	var vs: Array = main.town_life.vehicles
	var k := n_npc * 4
	for v: NpcVehicle in vs:
		if k + 3 < packed.size():
			v.net_apply(packed[k], packed[k + 1], packed[k + 2], int(packed[k + 3]))
		k += 4


func _vehicle_states() -> Array:
	var out := []
	for v: NpcVehicle in main.town_life.vehicles:
		out.append(v.net_state())
	return out


func _bike_states() -> Dictionary:
	var out := {}
	for ch in Sim.CHARACTERS:
		var b: SmartObject = main.room["objects"].get("bike_" + String(ch["home"]))
		if b and b.visible:
			out[ch["home"]] = [b.global_position.x, b.global_position.z, b.rotation.y]
	return out


func apply_npcs(states: Array) -> void:
	var list: Array = main.npcs
	for i in mini(states.size(), list.size()):
		var n := list[i] as Npc
		n.puppet = true
		n.net_apply(states[i])
		if states[i].size() > 5:
			if bool(states[i][5]):
				n.set_meta("hands_up", true)
			elif n.has_meta("hands_up"):
				n.remove_meta("hands_up")


## Someone in town said something (a word bubble).
func send_npc_say(key: String, text: String) -> void:
	if peer_slot.is_empty() or key == "":
		return
	npc_say.rpc(key, text)


@rpc("authority", "call_remote", "reliable")
func npc_say(key: String, text: String) -> void:
	var n = main.room["objects"].get(key)
	if n is Npc:
		(n as Npc).say(text, 2.7)


## A sound everyone hears (breaking glass...).
func send_sound(name: String, at: Vector3, db: float) -> void:
	if peer_slot.is_empty():
		return
	sound.rpc(name, at, db)


@rpc("authority", "call_remote", "reliable")
func sound(name: String, at: Vector3, db: float) -> void:
	main.audio.play_at(name, at, db)


## Which shop doors are locked right now.
func send_door_locks(keys: Array) -> void:
	if peer_slot.is_empty():
		return
	door_locks.rpc(keys)


@rpc("authority", "call_remote", "reliable")
func door_locks(keys: Array) -> void:
	main.apply_door_locks(keys)


## A kid's bike was bought, ridden off or parked.
func send_bike(home: String, shown: bool, at: Vector3, yaw: float) -> void:
	if peer_slot.is_empty():
		return
	bike.rpc(home, shown, at.x, at.z, yaw)


@rpc("authority", "call_remote", "reliable")
func bike(home: String, shown: bool, x: float, z: float, yaw: float) -> void:
	main.set_bike(home, shown, Vector3(x, 0, z), yaw)


## (host) A Memory Moment for a friend's kid that happened on the host (the paper route...).
func send_memory(slot: int, id: String) -> void:
	for pid in peer_slot:
		if peer_slot[pid] == slot:
			memory.rpc_id(pid, id)


@rpc("authority", "call_remote", "reliable")
func memory(id: String) -> void:
	main.award_memory(main.sim, id)


## Change how your kid looks (the dresser / the mirror).
func send_look(look: Dictionary) -> void:
	if is_client():
		rq_look.rpc_id(1, look)
	elif is_host():
		look_changed.rpc(main.sim.slot, look)


@rpc("any_peer", "call_remote", "reliable")
func rq_look(look: Dictionary) -> void:
	var s := _sender_sim()
	if s:
		var l := clean_look(look)
		s.set_look(l)
		look_changed.rpc(s.slot, l)


## (host) Someone's look changed on the host's side (they bought new clothes at the mall).
func send_look_for(slot: int, look: Dictionary) -> void:
	if is_host():
		look_changed.rpc(slot, look)


@rpc("authority", "call_remote", "reliable")
func look_changed(slot: int, look: Dictionary) -> void:
	var s: Sim = main.sims.get(slot)
	if s and (s != main.sim or not s.look.has("outfit") or int(s.look["outfit"]) != int(look.get("outfit", -1))):
		s.set_look(look)


## Chat: friends send to the host, the host tells everyone.
func send_chat(text: String) -> void:
	text = text.strip_edges().substr(0, 120)
	if text == "":
		return
	if is_client():
		rq_chat.rpc_id(1, text)
	elif is_host():
		var who: String = main.sim.character_name
		main.chat.add_line(who, text)
		chat_line.rpc(who, text)


@rpc("any_peer", "call_remote", "reliable")
func rq_chat(text: String) -> void:
	var s := _sender_sim()
	if s == null:
		return
	text = text.strip_edges().substr(0, 120)
	if text == "":
		return
	main.chat.add_line(s.character_name, text)
	chat_line.rpc(s.character_name, text)


@rpc("authority", "call_remote", "reliable")
func chat_line(who: String, text: String) -> void:
	main.chat.add_line(who, text)


## Someone flipped a light switch.
func send_lights(key: String, on: bool) -> void:
	if is_host():
		lights.rpc(key, on)
	elif is_client():
		rq_lights.rpc_id(1, key, on)


@rpc("any_peer", "call_remote", "reliable")
func rq_lights(key: String, on: bool) -> void:
	if _sender_sim() == null:
		return
	main.set_lights(key, on)
	lights.rpc(key, on)


@rpc("authority", "call_remote", "reliable")
func lights(key: String, on: bool) -> void:
	main.set_lights(key, on)


## Someone got bumped by a car.
func send_ouch(key: String, text: String) -> void:
	if is_host():
		ouch.rpc(key, text)
	elif is_client():
		rq_ouch.rpc_id(1, key, text)


@rpc("any_peer", "call_remote", "reliable")
func rq_ouch(key: String, text: String) -> void:
	if _sender_sim() == null:
		return
	_show_ouch(key, text)
	ouch.rpc(key, text)


@rpc("authority", "call_remote", "reliable")
func ouch(key: String, text: String) -> void:
	_show_ouch(key, text)


func _show_ouch(key: String, text: String) -> void:
	var who: Node3D = null
	if key.begins_with("sim:"):
		who = main.sims.get(int(key.substr(4)))
	else:
		who = main.room["objects"].get(key)
	if who:
		Props.bubble(who, text, 2.5, 2.3)
		main.audio.play_at("car_bump", who.global_position + Vector3(0, 1.0, 0), -8.0)


# ================================================================ emotes

## Wave, dance, cheer... everyone sees it.
func send_emote(slot: int, kind: String) -> void:
	if is_host():
		emote_done.rpc(slot, kind)
	elif is_client():
		rq_emote.rpc_id(1, kind)


@rpc("any_peer", "call_remote", "reliable")
func rq_emote(kind: String) -> void:
	var s := _sender_sim()
	if s and s.emote(kind):
		emote_done.rpc(s.slot, kind)


@rpc("authority", "call_remote", "reliable")
func emote_done(slot: int, kind: String) -> void:
	var s: Sim = main.sims.get(slot)
	if s:
		s.emote(kind)
