class_name AssetLibrary
extends RefCounted
## The game's look, as asset files you can open and edit in Godot.
##
##   assets/scenes/**.tscn   one scene per thing: every piece of furniture and usable object,
##                           each building's walls and floors ("structure"), every townsperson,
##                           every vehicle, each holiday's decorations
##   assets/models/**.glb    the same things as standard 3D models (for Blender etc.; Godot
##                           skips this folder, it's not used by the game)
##   assets/textures/*.png   the patterns (carpet, plaid, brick, asphalt...)
##   world.tscn              the whole town put together, to look around and edit in the 3D
##                           editor (made by tools/build_world_scene.gd)
##   assets/manifest.json    what was baked (a fingerprint of every file)
##
## The code still lays the town out and runs it (where things are, what you can do with them,
## who walks where). The asset files hold how things LOOK. When the game starts it checks every
## asset against its fingerprint, and anything you've changed in the editor (colors, textures,
## shapes, moving or adding or deleting parts) is put onto that thing in the game.
##
## To regenerate the assets from the code (after changing the code): see tools/bake_assets.gd.

const ROOT := "res://assets/"
const SCENES := "res://assets/scenes/"
const MODELS := "res://assets/models/"
const TEXTURES := "res://assets/textures/"
const MANIFEST := "res://assets/manifest.json"


# ================================================================ what's a "thing", and where it lives

## Every thing in the built world: [{path: "houses/jamie/fridge", single: true, node: Node}, or
## {path: "houses/jamie/structure", single: false, members: [Node, ...]}], always in the same order.
static func things(main: Node) -> Array:
	var places := _places(main)
	var keys: Dictionary = {}
	var objs: Dictionary = main.room.get("objects", {})
	for k in objs:
		keys[objs[k]] = k
	var out: Array = []
	var groups := {}       # path -> entry
	var used := {}         # path -> true
	var add_single := func(path: String, n: Node) -> void:
		var p := path
		var i := 2
		while used.has(p):
			p = "%s_%d" % [path, i]
			i += 1
		used[p] = true
		out.append({"path": p, "single": true, "node": n})
	var add_member := func(path: String, n: Node) -> void:
		if not groups.has(path):
			groups[path] = {"path": path, "single": false, "members": []}
			used[path] = true
			out.append(groups[path])
		(groups[path]["members"] as Array).append(n)
	var stack: Array = []
	for c in main.get_children():
		stack.append(c)
	var i := 0
	while i < stack.size():
		var n: Node = stack[i]
		i += 1
		if n.is_queued_for_deletion():
			continue                  # (built and then replaced while the town was being put together)
		if not (n is Node3D) or n is Sim or n is Camera3D or n is CameraRig or n is DirectionalLight3D \
				or n is WorldEnvironment or n is GPUParticles3D or n is CPUParticles3D or n is AudioStreamPlayer3D:
			continue
		if n is Npc:
			add_single.call("characters/" + _snake(String((n as Npc).name)).trim_prefix("npc_"), n)
			continue
		if n is NpcVehicle:
			add_single.call("vehicles/" + _snake((n as NpcVehicle).key), n)
			continue
		if n is Car:
			add_single.call("vehicles/" + _snake((n as Car).key), n)
			continue
		if n is Critters:
			add_single.call("creatures/critters", n)
			continue
		if n is BowlingLanes:
			add_single.call("buildings/bowling/lanes", n)
			continue
		if n is Holidays:
			var h := n as Holidays
			for c in h.get_children():
				if _has_visuals(c):
					add_member.call("decorations/" + _holiday_of(h, c), c)
			continue
		if n is Seasons or (n.get_class() == "Node3D" and n.get_script() == null and not _anon(n) and n.get_child_count() > 10):
			# (a container: what's inside it belongs to the places around town)
			for c in n.get_children():
				stack.append(c)
			continue
		if not _has_visuals(n):
			continue
		if n is MultiMeshInstance3D:
			add_member.call("outdoors/woods", n)
			continue
		var at := _center(n)
		var under := at.y < RoomBuilder.INTERIOR_Y / 2.0     # (attics and basements are built down there)
		var folder := _place_of(places, at, under)
		if n is SmartObject and keys.has(n):
			add_single.call(folder + "/" + _short(folder, String(keys[n])), n)
		elif not _anon(n):
			add_single.call(folder + "/" + _short(folder, String(n.name)), n)
		else:
			add_member.call(folder + ("/downstairs" if under and folder.begins_with("houses/") else "/structure"), n)
	return out


## The places around town: [[folder, Rect2, underground], ...] (the smallest one that holds a thing wins).
static func _places(main: Node) -> Array:
	var out: Array = []
	var rooms: Dictionary = main.room.get("rooms", {})
	var homes := ["jamie"]
	homes.append_array(NeighborBuilder.HOMES.keys())
	for h in homes:
		var ground := Rect2()
		for k in rooms:
			var parts := String(k).split("|")
			if parts.size() < 2 or parts[0] != h:
				continue
			var r: Rect2 = rooms[k]
			if parts[1].contains("Attic") or parts[1].contains("Basement"):
				out.append(["houses/" + h, r.grow(0.6), true])
			else:
				ground = r if ground.size == Vector2.ZERO else ground.merge(r)
		if ground.size != Vector2.ZERO:
			out.append(["houses/" + h, ground.grow(0.6), false])
	for e in main.room.get("shop_doors", []):
		out.append(["buildings/" + _snake(String(e["key"])), (e["rect"] as Rect2).grow(0.6), false])
	var extra := [
		["buildings/police", CivicBuilder.POLICE], ["buildings/police_lot", CivicBuilder.POLICE_LOT],
		["buildings/fire_station", CivicBuilder.FIRE], ["buildings/football_field", CivicBuilder.FIELD],
		["buildings/school", SchoolBuilder.WING], ["buildings/middle_school", SchoolBuilder.MIDDLE],
		["buildings/high_school", SchoolBuilder.HIGH], ["buildings/drive_in", DowntownBuilder.DRIVE_IN],
		["buildings/frostys", DowntownBuilder.FROSTYS], ["buildings/gazette", DowntownBuilder.GAZETTE],
		["buildings/skate_park", EastBuilder.SKATE], ["buildings/burger_lot", EastBuilder.BURGER_LOT],
		["buildings/burger", EastBuilder.BURGER], ["buildings/bowling", EastBuilder.BOWLING],
		["buildings/fairgrounds", EastBuilder.FAIR], ["buildings/mall_parking", EastBuilder.LOT],
		["buildings/mall/clothes", MallBuilder.CLOTHES], ["buildings/mall/toys", MallBuilder.TOYS],
		["buildings/mall/music", MallBuilder.MUSIC], ["buildings/mall/computers", MallBuilder.COMPUTERS],
		["buildings/mall/concourse", MallBuilder.CONCOURSE], ["buildings/mall/food_court", MallBuilder.FOOD],
	]
	for e in extra:
		out.append([e[0], (e[1] as Rect2).grow(0.6), false])
	out.append(["buildings/high_school", SchoolBuilder.HIGH_UP.grow(0.6), true])
	return out


static func _place_of(places: Array, at: Vector3, under: bool) -> String:
	var best := ""
	var best_area := INF
	var p := Vector2(at.x, at.z)
	for e in places:
		if bool(e[2]) != under:
			continue
		var r: Rect2 = e[1]
		if r.has_point(p) and r.get_area() < best_area:
			best = e[0]
			best_area = r.get_area()
	if best != "":
		return best
	if under:
		return "interiors"
	# outdoors: the town in 32-meter squares, named by compass from Jamie's house
	var ix := floori(at.x / 32.0)
	var iz := floori(at.z / 32.0)
	return "outdoors/%s%d_%s%d" % ["east" if ix >= 0 else "west", absi(ix), "south" if iz >= 0 else "north", absi(iz)]


static func _holiday_of(h: Holidays, n: Node) -> String:
	for g in h._groups:
		if (h._groups[g] as Array).has(n):
			return _snake(String(g))
	for g in h._objects:
		if (h._objects[g] as Array).has(n):
			return _snake(String(g))
	return "other"


# ================================================================ helpers

## A file name for a thing in a folder: "houses/jamie" + "jamie_closet" -> "closet";
## one-letter wall names ("N", "E"...) -> "wall_n".
static func _short(folder: String, nm: String) -> String:
	var s := _snake(nm)
	var place := folder.get_file()
	if s.begins_with(place + "_") and s.length() > place.length() + 1:
		s = s.substr(place.length() + 1)
	if s.length() == 1:
		s = "wall_" + s
	return s


static func _anon(n: Node) -> bool:
	return String(n.name).begins_with("@")


static func _snake(s: String) -> String:
	var out := ""
	var prev_lower := false
	for ch in s:
		var up := ch.to_upper() == ch and ch.to_lower() != ch
		if up and prev_lower:
			out += "_"
		if ch.is_valid_identifier() or ch.is_valid_int():
			out += ch.to_lower()
		elif not out.ends_with("_"):
			out += "_"
		prev_lower = ch.to_lower() == ch and ch.to_upper() != ch or ch.is_valid_int()
	return out.strip_edges().trim_suffix("_").trim_prefix("_")


static func _has_visuals(n: Node) -> bool:
	if n is VisualInstance3D and not (n is GPUParticles3D or n is CPUParticles3D):
		return true
	for c in n.get_children():
		if _has_visuals(c):
			return true
	return false


## Middle of everything you can see in it (where it is in town).
static func _center(n: Node) -> Vector3:
	var box := AABB()
	var first := true
	var stack: Array = [n]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D and (x as MeshInstance3D).mesh != null:
			var b: AABB = (x as MeshInstance3D).global_transform * (x as MeshInstance3D).mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		stack.append_array(x.get_children())
	if first:
		return (n as Node3D).global_position
	return box.get_center()


## A name for a node that stays the same from run to run: its own name if it has one,
## otherwise what it is, where it is (local to its parent, or in the world) and its size.
static func key_of(n: Node, world: bool) -> String:
	if not _anon(n):
		return String(n.name)
	var p := Vector3.ZERO
	if n is Node3D:
		p = (n as Node3D).global_position if world else (n as Node3D).position
	var extra := ""
	if n is MeshInstance3D and (n as MeshInstance3D).mesh is BoxMesh:
		var s: Vector3 = ((n as MeshInstance3D).mesh as BoxMesh).size
		extra = "%.3f,%.3f,%.3f" % [s.x, s.y, s.z]
	elif n is Label3D:
		extra = (n as Label3D).text.left(16)
	return "%s|%.2f,%.2f,%.2f|%s" % [n.get_class(), p.x, p.y, p.z, extra]


## Keys for a list of nodes (a second identical one gets "#2", and so on).
static func keys_for(nodes: Array, world: bool) -> Array:
	var seen := {}
	var out := []
	for n in nodes:
		var k := key_of(n, world)
		var c := int(seen.get(k, 0)) + 1
		seen[k] = c
		out.append(k if c == 1 else "%s#%d" % [k, c])
	return out


# ================================================================ startup: put edited assets onto the game

## Called once the town is built (main.gd). Only assets that were edited after the bake are
## loaded, so an unedited town costs almost nothing.
##   Run from the Godot editor: each file is checked against its fingerprint, and the list of
##   edited ones is written down (assets/edited.json) for exported copies of the game.
##   An exported game (where the files are packed and can't be checked): uses that list.
static func apply(main: Node, everything := false) -> int:
	if not FileAccess.file_exists(MANIFEST):
		return 0
	var mf = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not (mf is Dictionary):
		return 0
	var baked: Dictionary = mf.get("assets", {})
	var todo := {}
	var use_world := false
	if everything:
		for path in baked:
			todo[path] = true
	elif OS.has_feature("editor") or _can_check(baked):
		todo = _edited(mf)
		use_world = _world_edited(mf)
		var listed := todo.duplicate()
		if use_world:
			listed[WORLD_MARK] = true
		_write_edited(listed)
	else:
		var el = JSON.parse_string(FileAccess.get_file_as_string(EDITED)) if FileAccess.file_exists(EDITED) else null
		if el is Array:
			for p in el:
				todo[String(p)] = true
		else:
			for path in baked:          # (no list: play it safe and use every asset)
				todo[path] = true
		use_world = todo.has(WORLD_MARK)
		todo.erase(WORLD_MARK)
	_changed_tex = _changed_textures(mf)
	if use_world:
		return _apply_world(main)
	if todo.is_empty():
		return 0
	var n := 0
	for th in things(main):
		if not todo.has(th["path"]):
			continue
		var ps = load(SCENES + String(th["path"]) + ".tscn")
		if not (ps is PackedScene):
			continue
		var a: Node = (ps as PackedScene).instantiate()
		if th["single"]:
			_apply_node(a, th["node"], true, main)
		else:
			_apply_group(a, th["members"], main)
		a.free()
		n += 1
	print("Assets: %d edited asset%s applied" % [n, "" if n == 1 else "s"])
	return n


# ================================================================ the world scene (res://world.tscn)

## The whole town in one scene, for Godot's 3D editor (made by tools/build_world_scene.gd).
## Edits there reach the game too: changes inside the objects (the editor saves them in
## world.tscn), things added to the world, objects deleted from it. Hiding things (the eye
## icon) is only for looking while you edit: the game ignores it.
const WORLD := "res://world.tscn"
const WORLD_MARK := "@world"


static func _world_edited(mf: Dictionary) -> bool:
	if not mf.has("world") or not FileAccess.file_exists(WORLD):
		return false
	return FileAccess.get_md5(WORLD) != String(mf["world"])


## world.tscn was edited: the whole world scene is loaded (it already includes every edited
## asset file), and each object's changed parts are put onto the town.
static func _apply_world(main: Node) -> int:
	var ps = load(WORLD)
	if not (ps is PackedScene):
		return 0
	var world: Node3D = (ps as PackedScene).instantiate()
	var found := {}           # asset path -> [instance, its transform in the world]
	var extras := []          # things added straight into the world: [node, transform]
	_scan_world(world, Transform3D.IDENTITY, found, extras)
	var n := 0
	var moved := []
	for th in things(main):
		var path: String = th["path"]
		if not found.has(path):
			if OS.is_debug_build() and "--asset-log" in OS.get_cmdline_user_args():
				print("world.tscn doesn't have: ", path)
			# deleted from the world scene: it isn't drawn any more (it still works in the game)
			if th["single"]:
				_erase(th["node"])
			else:
				for m in th["members"]:
					_erase(m)
			n += 1
			continue
		var inst: Node3D = found[path][0]
		var xf: Transform3D = found[path][1]
		if th["single"]:
			var live := th["node"] as Node3D
			var home := _baked_root_transform(inst)
			if not xf.origin.is_equal_approx(home.origin) or not xf.basis.is_equal_approx(home.basis):
				moved.append(path)
			_apply_node(inst, live, true, main)
		else:
			var shell := inst.transform
			inst.transform = xf
			_apply_group(inst, th["members"], main)
			inst.transform = shell
		n += 1
	for e in extras:
		var d: Node3D = (e[0] as Node3D).duplicate()
		main.add_child(d)
		d.global_transform = e[1]
	world.free()
	for p in moved:
		push_warning("world.tscn: \"%s\" was moved as a whole. A usable object's spot in town comes from the code, so the move isn't used (move its parts instead, or change its position in the code)." % p)
	print("Assets: the world scene was edited; %d objects checked, %d new things added" % [n, extras.size()])
	return n


## Where an object stands in its own asset file (before anything in the world scene moved it).
static func _baked_root_transform(inst: Node) -> Transform3D:
	var ps = load(inst.scene_file_path)
	if ps is PackedScene:
		var st := (ps as PackedScene).get_state()
		for i in st.get_node_property_count(0):
			if st.get_node_property_name(0, i) == &"transform":
				return st.get_node_property_value(0, i)
	return Transform3D.IDENTITY


static func _scan_world(n: Node, xf: Transform3D, found: Dictionary, extras: Array) -> void:
	for c in n.get_children():
		if not (c is Node3D):
			continue
		var cx: Transform3D = xf * (c as Node3D).transform
		var sp := String(c.scene_file_path)
		if sp.begins_with(SCENES):
			found[sp.trim_prefix(SCENES).trim_suffix(".tscn")] = [c, cx]
		elif c.has_meta("rl_folder"):
			_scan_world(c, cx, found, extras)      # (hiding a folder is only for looking)
		elif not c.has_meta("rl_editor_only"):
			extras.append([c, cx])        # something new, added in the editor


const EDITED := "res://assets/edited.json"


static func _can_check(baked: Dictionary) -> bool:
	for path in baked:
		return FileAccess.get_md5(SCENES + String(path) + ".tscn") != ""
	return false


static func _changed_textures(mf: Dictionary) -> Dictionary:
	var changed_tex := {}
	var tex_md5: Dictionary = mf.get("textures", {})
	for t in tex_md5:
		var now := FileAccess.get_md5(ROOT + String(t))
		if now != "" and now != String(tex_md5[t]):
			changed_tex[t] = true
	return changed_tex


## The assets whose file (or one of whose textures) isn't what was baked.
static func _edited(mf: Dictionary) -> Dictionary:
	var baked: Dictionary = mf.get("assets", {})
	var changed_tex := _changed_textures(mf)
	var todo := {}
	for path in baked:
		var info: Dictionary = baked[path]
		var now := FileAccess.get_md5(SCENES + String(path) + ".tscn")
		if now == "":
			continue                      # (deleted: the code's version stays)
		var edited := now != String(info.get("md5", ""))
		for t in info.get("textures", []):
			if changed_tex.has(t):
				edited = true
		if edited:
			todo[path] = true
	return todo


static func _write_edited(todo: Dictionary) -> void:
	var list := todo.keys()
	list.sort()
	var text := JSON.stringify(list, "  ")
	if FileAccess.file_exists(EDITED) and FileAccess.get_file_as_string(EDITED) == text:
		return
	var f := FileAccess.open(EDITED, FileAccess.WRITE)
	if f:
		f.store_string(text)


static func _apply_group(a: Node, members: Array, main: Node) -> void:
	var live := {}
	var ks := keys_for(members, true)
	for i in members.size():
		live[ks[i]] = members[i]
	var present := {}
	var shell := (a as Node3D).transform if a is Node3D else Transform3D.IDENTITY
	for c in a.get_children():
		if c.has_meta("rl_src"):
			var k := String(c.get_meta("rl_src"))
			present[k] = true
			if live.has(k):
				_apply_node(c, live[k], false, main, true)
				if shell != Transform3D.IDENTITY and c is Node3D and live[k] is Node3D:
					(live[k] as Node3D).global_transform = shell * (c as Node3D).transform
		elif c is Node3D:
			var d: Node3D = (c as Node3D).duplicate()     # something new, added in the editor
			main.add_child(d)
			d.transform = shell * (c as Node3D).transform
	for k in a.get_meta("rl_kids", []):
		if not present.has(k) and live.has(k):
			_erase(live[k])               # deleted in the editor


static var _changed_tex := {}


static func _apply_node(a: Node, l: Node, root: bool, main: Node, world := false) -> void:
	var touched := not a.has_meta("rl_fp") or fingerprint(a) != String(a.get_meta("rl_fp")) or _uses_texture(a, _changed_tex)
	if touched:
		_apply_own(a, l, root, world)
	_apply_children(a, l, main)


static func _apply_own(a: Node, l: Node, root: bool, world: bool) -> void:
	if not root and a is Node3D and l is Node3D:
		if world:
			(l as Node3D).global_transform = (a as Node3D).transform     # (a building's loose parts are kept in world space)
		else:
			(l as Node3D).transform = (a as Node3D).transform
	if a is GeometryInstance3D and l is GeometryInstance3D:
		_copy_material(a as GeometryInstance3D, l as GeometryInstance3D)
		(l as GeometryInstance3D).cast_shadow = (a as GeometryInstance3D).cast_shadow
	if a is MeshInstance3D and l is MeshInstance3D:
		(l as MeshInstance3D).mesh = (a as MeshInstance3D).mesh
	elif a is MultiMeshInstance3D and l is MultiMeshInstance3D:
		var am := (a as MultiMeshInstance3D).multimesh
		var lm := (l as MultiMeshInstance3D).multimesh
		if am and lm and am.instance_count == lm.instance_count:
			lm.mesh = am.mesh
			lm.buffer = am.buffer
		elif am:
			(l as MultiMeshInstance3D).multimesh = am
	elif a is Label3D and l is Label3D:
		var al := a as Label3D
		var ll := l as Label3D
		ll.text = al.text
		ll.font_size = al.font_size
		ll.pixel_size = al.pixel_size
		ll.modulate = al.modulate
		ll.outline_modulate = al.outline_modulate
		ll.outline_size = al.outline_size
		if al.font:
			ll.font = al.font
	elif a is Light3D and l is Light3D:
		(l as Light3D).light_color = (a as Light3D).light_color
		if a is OmniLight3D and l is OmniLight3D:
			(l as OmniLight3D).omni_range = (a as OmniLight3D).omni_range
		elif a is SpotLight3D and l is SpotLight3D:
			(l as SpotLight3D).spot_range = (a as SpotLight3D).spot_range
			(l as SpotLight3D).spot_angle = (a as SpotLight3D).spot_angle


static func _apply_children(a: Node, l: Node, main: Node) -> void:
	var kids: Array = []
	for c in l.get_children():
		kids.append(c)
	var ks := keys_for(kids, false)
	var live := {}
	for i in kids.size():
		live[ks[i]] = kids[i]
	var present := {}
	for c in a.get_children():
		if c.has_meta("rl_src"):
			var k := String(c.get_meta("rl_src"))
			present[k] = true
			if live.has(k):
				_apply_node(c, live[k], false, main)
		elif c is Node3D:
			l.add_child((c as Node3D).duplicate())     # a part added in the editor
	for k in a.get_meta("rl_kids", []):
		if not present.has(k) and live.has(k):
			_erase(live[k])


## A fingerprint of how one part looks (its own settings, not its children). The baker stores it
## on every part ("rl_fp"); a part whose fingerprint still matches wasn't touched in the editor.
static func fingerprint(n: Node) -> String:
	var parts: Array = [n.get_class()]
	if n is Node3D:
		var t := (n as Node3D).transform
		parts.append(str(t.origin.snapped(Vector3(0.0001, 0.0001, 0.0001))))
		parts.append(str(t.basis.x.snapped(Vector3(0.0001, 0.0001, 0.0001))) + str(t.basis.y.snapped(Vector3(0.0001, 0.0001, 0.0001))) + str(t.basis.z.snapped(Vector3(0.0001, 0.0001, 0.0001))))
	if n is MeshInstance3D:
		var m := (n as MeshInstance3D).mesh
		parts.append("-" if m == null else (str((m as BoxMesh).size.snapped(Vector3(0.0001, 0.0001, 0.0001))) if m is BoxMesh else m.get_class() + m.resource_path))
	if n is GeometryInstance3D:
		var mat := (n as GeometryInstance3D).material_override
		parts.append(str((n as GeometryInstance3D).cast_shadow))
		if mat is BaseMaterial3D:
			for nm in MAT_PROPS:
				var v = mat.get(nm)
				parts.append((v as Resource).resource_path if v is Resource else str(v))
		elif mat != null:
			parts.append(mat.get_class() + mat.resource_path)
	if n is Label3D:
		var l := n as Label3D
		parts.append_array([l.text, l.font_size, l.pixel_size, l.modulate, l.outline_modulate, l.outline_size])
	if n is Light3D:
		parts.append(str((n as Light3D).light_color))
		if n is OmniLight3D:
			parts.append(str((n as OmniLight3D).omni_range))
	return str(hash(str(parts)))


static func _uses_texture(n: Node, changed_tex: Dictionary) -> bool:
	if changed_tex.is_empty() or not (n is GeometryInstance3D):
		return false
	var mat = (n as GeometryInstance3D).material_override
	if not (mat is BaseMaterial3D):
		return false
	for nm in ["albedo_texture", "emission_texture", "normal_texture"]:
		var t = mat.get(nm)
		if t is Resource and changed_tex.has(String((t as Resource).resource_path).trim_prefix(ROOT)):
			return true
	return false


## The settings that make up how a material looks (what's copied from an edited asset).
const MAT_PROPS := ["albedo_color", "albedo_texture", "emission_enabled", "emission", "emission_energy_multiplier",
	"emission_texture", "roughness", "metallic", "metallic_specular", "transparency", "uv1_scale", "uv1_offset",
	"uv1_triplanar", "uv1_world_triplanar", "texture_filter", "shading_mode", "cull_mode", "normal_enabled",
	"normal_texture", "rim_enabled", "vertex_color_use_as_albedo", "no_depth_test", "billboard_mode"]


## Copy a material's look onto the game's own material (other code holds on to that one:
## lamps that light up, things that glow when you point at them), unless it's a different kind.
static func _copy_material(a: GeometryInstance3D, l: GeometryInstance3D) -> void:
	var am := a.material_override
	var lm := l.material_override
	if am == null:
		return
	if lm == null or lm.get_class() != am.get_class() or not (am is BaseMaterial3D):
		l.material_override = am.duplicate()
		return
	for nm in MAT_PROPS:
		var v = am.get(nm)
		if lm.get(nm) != v:
			lm.set(nm, v)


## Deleted in the editor: it isn't drawn any more (the node stays, other code may know it).
static func _erase(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).mesh = null
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh:
		(n as MultiMeshInstance3D).multimesh.visible_instance_count = 0
	elif n is Label3D:
		(n as Label3D).text = ""
	elif n is Light3D:
		(n as Light3D).light_energy = 0.0
		(n as Light3D).light_color = Color.BLACK
	for c in n.get_children():
		_erase(c)
