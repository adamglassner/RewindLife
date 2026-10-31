class_name SaveGame
extends RefCounted
## Saved games: the time, where the cars are parked, and for each character their
## needs, money, Memory Moments, where they are and Free Will.
##   user://save.json         - playing alone (just Jamie)
##   user://save_online.json  - the host's online world (all four characters; the
##                              neighbor kids' progress waits there for their players)
## (The diary has its own file, so it's never lost with a new game.)

const PATH := "user://save.json"
const ONLINE_PATH := "user://save_online.json"
const VERSION := 2
const LAYOUT := 4      # the neighborhood's layout (v1.3 moved the cars into the driveway; v1.5 to the curbs)


static func path_for(online: bool) -> String:
	return ONLINE_PATH if online else PATH


static func exists(online := false) -> bool:
	return FileAccess.file_exists(path_for(online))


static func delete(online := false) -> void:
	if exists(online):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path_for(online)))


## One character's progress.
static func sim_state(s: Sim, main: Node = null) -> Dictionary:
	var pos := s.global_position
	if main != null and s == main.sim and main.driving != null:
		pos = main.driving.exit_spots()[0]   # saved standing beside the car, not inside it
	return {
		"needs": s.needs.values.duplicate(),
		"mood_bonus": s.needs.mood_bonus,
		"money": s.money,
		"memories": s.memories.keys(),
		"pos": [snappedf(pos.x, 0.01), snappedf(pos.z, 0.01)],
		"yaw": s.rotation.y,
		"free_will": s.free_will,
		"items": s.items.duplicate(true),
		"look": s.look.duplicate(),
		"level": s.level,
		"job": s.job,
		"paper_day": s.paper_day,
		"bike": s.bike,
		"owned": s.owned.keys(),
		"chores": s.chores_done.duplicate(),
	}


static func apply_sim_state(s: Sim, d: Dictionary) -> void:
	var needs: Dictionary = d.get("needs", {})
	for n in needs:
		if s.needs.values.has(n):
			s.needs.values[n] = float(needs[n])
	s.needs.mood_bonus = float(d.get("mood_bonus", 0.0))
	s.money = float(d.get("money", s.money))
	for m in d.get("memories", []):
		s.memories[m] = true
	s.set_level(int(d.get("level", 0)))
	var p: Array = d.get("pos", [])
	if p.size() == 2:
		s.global_position = Vector3(float(p[0]), s.floor_at(float(p[0]), float(p[1])), float(p[1]))
		s.net_pos = s.global_position
	s.rotation.y = float(d.get("yaw", s.rotation.y))
	s._face_yaw = s.rotation.y
	s.net_yaw = s._face_yaw
	s.free_will = bool(d.get("free_will", true))
	var it = d.get("items", {})
	if it is Dictionary:
		s.items = it.duplicate(true)
	var lk = d.get("look", {})
	if lk is Dictionary and not lk.is_empty():
		var l2 := (lk as Dictionary).duplicate()
		for k in ["hair_color", "skin", "outfit"]:
			if l2.has(k):
				l2[k] = int(l2[k])     # (JSON brings numbers back as floats)
		s.set_look(l2)
	s.job = String(d.get("job", s.job))
	s.paper_day = int(d.get("paper_day", s.paper_day))
	s.bike = bool(d.get("bike", false))
	s.owned = {}
	for k in d.get("owned", []):
		s.owned[String(k)] = true
	s.riding = false
	var ch = d.get("chores", {})
	if ch is Dictionary:
		s.chores_done = {}
		for k in ch:
			s.chores_done[k] = int(ch[k])


static func save(main: Node) -> bool:
	var online: bool = main.net.is_online()
	var cars := []
	for c in main.room.get("cars", []):
		cars.append({"key": c.key, "x": c.global_position.x, "z": c.global_position.z, "yaw": c.global_rotation.y})
	var people := {}
	if online:
		people = (main.net.slot_store as Dictionary).duplicate()   # players who left keep their spot
	for slot in main.sims:
		people[str(slot)] = sim_state(main.sims[slot], main)
	var data := {
		"version": VERSION,
		"time": main.clock.unix_time,
		"sims": people,
		"camera": main.rig.mode if main.rig.mode <= CameraRig.Mode.FIRST else CameraRig.Mode.HOUSE,
		"cars": cars,
		"layout": LAYOUT,
		"family": Families.jamie,
		"town": main.town_life.save_state(),
		"bikes": main.net._bike_states(),
	}
	var f := FileAccess.open(path_for(online), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "  "))
	return true


## Read a save file, or {} if there isn't a usable one. Version 1 saves (Jamie
## only, before online play) are read too.
static func read(online := false) -> Dictionary:
	if not exists(online):
		return {}
	var f := FileAccess.open(path_for(online), FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		return {}
	var v := int(d.get("version", 0))
	if v == 1:
		d["sims"] = {"0": {"needs": d.get("needs", {}), "mood_bonus": d.get("mood_bonus", 0.0),
			"money": d.get("money", 42.5), "memories": d.get("memories", []), "pos": d.get("pos", []),
			"yaw": d.get("yaw", 0.0), "free_will": d.get("free_will", true)}}
	elif v != VERSION:
		return {}
	return d


## Load the world and Jamie (and, for the host, everyone else's saved progress).
static func apply(main: Node, d: Dictionary) -> void:
	main.clock.unix_time = int(d.get("time", main.clock.unix_time))
	Families.jamie = String(d.get("family", Families.jamie))
	main.relabel()
	var people: Dictionary = d.get("sims", {})
	var mine := str(main.sim.slot)
	if people.has(mine):
		apply_sim_state(main.sim, people[mine])
	if main.net.is_host():
		for k in people:
			if k != mine:
				main.net.slot_store[k] = people[k]
	else:
		main.local_store = {}
		for k in people:
			if k != mine:
				main.local_store[k] = people[k]
	var moved := false
	for cd in (d.get("cars", []) if int(d.get("layout", 0)) == LAYOUT else []):
		for c in main.room.get("cars", []):
			if c.key == cd.get("key", ""):
				c.global_position = Vector3(float(cd["x"]), 0, float(cd["z"]))
				c.rotation.y = float(cd["yaw"])
				main.park_car(c, false)
				moved = true
	if moved:
		main.rebuild_grid()
	main.town_life.load_state(d.get("town", {}))
	var bikes: Dictionary = d.get("bikes", {})
	for h in bikes:
		var bd: Array = bikes[h]
		main.set_bike(String(h), true, Vector3(float(bd[0]), 0, float(bd[1])), float(bd[2]))
	main.rig.set_mode(clampi(int(d.get("camera", CameraRig.Mode.HOUSE)), 0, 2))
