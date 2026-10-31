extends SceneTree
## ASSET BAKER: builds the town the way the game does, then saves how everything looks as
## asset files (see scripts/asset_library.gd for what goes where).
##
## Run from the project folder (it takes two passes, because Godot has to import the
## pattern PNGs before the scenes can point at them). The second pass needs a real renderer
## (not --headless: the headless one doesn't keep where the trees in the woods are):
##   godot --headless --path . -s res://tools/bake_assets.gd -- --pass=textures
##   godot --headless --path . --import
##   godot --path . -s res://tools/bake_assets.gd -- --pass=scenes
## Add --no-glb to skip the .glb models.
##
## This overwrites assets/scenes, assets/models, assets/textures and assets/manifest.json:
## re-baking throws away edits made to those files in the editor. So it stops if any asset (or
## the world scene, world.tscn) has been edited, and lists them; add --force to bake anyway.
## It doesn't touch world.tscn (tools/build_world_scene.gd makes that, when you ask it to).

var main: Node
var f := 0
var pass_name := "scenes"
var glb := true
var force := false
var _tex_by_id := {}          # live texture instance id -> res:// path
var _tex_res := {}            # res:// path -> loaded Texture2D
var _count := 0
var _names := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pass="):
			pass_name = a.get_slice("=", 1)
		elif a == "--no-glb":
			glb = false
		elif a == "--force":
			force = true
	main = load("res://main.tscn").instantiate()
	main.skip_title = true
	root.add_child(main)


func _process(_d: float) -> bool:
	f += 1
	if f < 6:
		return false
	if not force and FileAccess.file_exists(AssetLibrary.MANIFEST):
		var mf = JSON.parse_string(FileAccess.get_file_as_string(AssetLibrary.MANIFEST))
		if mf is Dictionary:
			var edited := AssetLibrary._edited(mf)
			if AssetLibrary._world_edited(mf):
				edited["world.tscn (the whole-town scene)"] = true
			if not edited.is_empty():
				printerr("Not baking: these assets were edited in the editor, and baking would replace them:")
				for e in edited:
					printerr("   ", e)
				printerr("Copy your changes somewhere safe (or into the code), then run again with --force.")
				return true
	if pass_name == "textures":
		_bake_textures()
	else:
		_bake_scenes()
	return true


# ================================================================ pass 1: the patterns, as PNGs

## Every texture the town uses, in the same order every run: the named ones first. Copies of
## the same picture (some are made again for every house) share one file.
func _textures_in_order() -> Array:
	var out: Array = []          # [[name, Texture2D], ...]  (copies come out with the same name)
	var seen := {}
	var by_pixels := {}          # md5 of the pixels -> name
	var add := func(nm: String, t: Texture2D) -> String:
		var img := t.get_image()
		var key := "" if img == null else str(img.get_size()) + img.get_data().hex_encode().md5_text()
		if key != "" and by_pixels.has(key):
			nm = by_pixels[key]
		elif key != "":
			by_pixels[key] = nm
		out.append([nm, t])
		return nm
	var named: Dictionary = main.room.get("tex", {})
	for k in named:
		var t: Texture2D = named[k]
		seen[t.get_instance_id()] = true
		add.call(String(k), t)
	var n := 0
	var stack: Array = [main]
	while not stack.is_empty():
		var x: Node = stack.pop_front()
		if x is GeometryInstance3D and (x as GeometryInstance3D).material_override is BaseMaterial3D:
			var m := (x as GeometryInstance3D).material_override as BaseMaterial3D
			for t in [m.albedo_texture, m.emission_texture, m.normal_texture, m.roughness_texture]:
				if t != null and t.resource_path == "" and not seen.has(t.get_instance_id()):
					seen[t.get_instance_id()] = true
					if add.call("pattern_%02d" % (n + 1), t) == "pattern_%02d" % (n + 1):
						n += 1
		stack.append_array(x.get_children())
	return out


func _bake_textures() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AssetLibrary.TEXTURES))
	var list := _textures_in_order()
	for f0 in DirAccess.get_files_at(AssetLibrary.TEXTURES):
		if f0.ends_with(".png") or f0.ends_with(".png.import"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(AssetLibrary.TEXTURES + f0))
	var done := {}
	for e in list:
		if done.has(e[0]):
			continue
		done[e[0]] = true
		var img: Image = (e[1] as Texture2D).get_image()
		if img == null:
			continue
		img = img.duplicate()
		if img.is_compressed():
			img.decompress()
		img.clear_mipmaps()
		img.save_png(AssetLibrary.TEXTURES + String(e[0]) + ".png")
	print("textures: saved ", done.size(), " (", list.size(), " in the town)")


func _load_textures() -> void:
	for e in _textures_in_order():
		var path := AssetLibrary.TEXTURES + String(e[0]) + ".png"
		if ResourceLoader.exists(path):
			_tex_by_id[(e[1] as Texture2D).get_instance_id()] = path
			_tex_res[path] = load(path)
	print("textures: using ", _tex_res.size())


# ================================================================ pass 2: the scenes (and models)

func _bake_scenes() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("The scenes pass needs a real renderer: run it without --headless.")
		return
	_load_textures()
	var things := AssetLibrary.things(main)
	print("things: ", things.size())
	for d in ["scenes", "models"]:
		_wipe(AssetLibrary.ROOT + d)
	var manifest := {"version": 1, "baked_from": Changelog.VERSION, "assets": {}, "textures": {}}
	var holder := Node3D.new()      # (models are exported from inside the tree)
	root.add_child(holder)
	var total_nodes := 0
	for th in things:
		var path: String = th["path"]
		_names.clear()
		var a: Node3D
		if th["single"]:
			var live: Node = th["node"]
			a = _convert(live, AssetLibrary.key_of(live, true))
			if a == null:
				continue
			a.transform = (live as Node3D).global_transform
			a.name = _title(path.get_file())
		else:
			a = Node3D.new()
			a.name = _title(path.get_file())
			var members: Array = th["members"]
			var ks := AssetLibrary.keys_for(members, true)
			var kids := []
			for i in members.size():
				var c := _convert(members[i], ks[i])
				if c == null:
					continue
				(c as Node3D).transform = (members[i] as Node3D).global_transform
				a.add_child(c)
				kids.append(ks[i])
			a.set_meta("rl_kids", kids)
			if a.get_child_count() == 0:
				a.free()
				continue
		var used_tex := {}
		_share_resources(a, used_tex)
		_own(a, a)
		_stamp(a)
		total_nodes += _node_count(a)
		var scene_path := AssetLibrary.SCENES + path + ".tscn"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scene_path.get_base_dir()))
		var ps := PackedScene.new()
		ps.pack(a)
		var err := ResourceSaver.save(ps, scene_path)
		if err != OK:
			push_error("couldn't save %s (%d)" % [scene_path, err])
			continue
		manifest["assets"][path] = {"md5": FileAccess.get_md5(scene_path), "textures": used_tex.keys()}
		if glb:
			holder.add_child(a)
			var model_path := AssetLibrary.MODELS + path + ".glb"
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(model_path.get_base_dir()))
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			if doc.append_from_scene(a, state) == OK:
				doc.write_to_filesystem(state, ProjectSettings.globalize_path(model_path))
			holder.remove_child(a)
		a.free()
		_count += 1
	for t in _tex_res:
		manifest["textures"][String(t).trim_prefix(AssetLibrary.ROOT)] = FileAccess.get_md5(t)
	# (the asset list stores texture paths relative to assets/ too)
	for p in manifest["assets"]:
		var tl: Array = manifest["assets"][p]["textures"]
		for i in tl.size():
			tl[i] = String(tl[i]).trim_prefix(AssetLibrary.ROOT)
	# (keep the world scene's fingerprint: baking doesn't touch world.tscn)
	if FileAccess.file_exists(AssetLibrary.MANIFEST):
		var old_mf = JSON.parse_string(FileAccess.get_file_as_string(AssetLibrary.MANIFEST))
		if old_mf is Dictionary and old_mf.has("world"):
			manifest["world"] = old_mf["world"]
	var fe := FileAccess.open(AssetLibrary.EDITED, FileAccess.WRITE)     # (nothing's been edited yet)
	fe.store_string("[]")
	fe.close()
	var fm := FileAccess.open(AssetLibrary.MANIFEST, FileAccess.WRITE)
	fm.store_string(JSON.stringify(manifest, "  "))
	fm.close()
	# Godot leaves the models folder alone (they're for other programs, not the game)
	var gi := FileAccess.open(AssetLibrary.MODELS + ".gdignore", FileAccess.WRITE)
	gi.close()
	print("baked: %d asset scenes, %d nodes%s" % [_count, total_nodes, ", with .glb models" if glb else ""])


## A look-only copy of a node: meshes, signs, lights and how they're arranged. No scripts,
## no collision, no sound; plain Node3D stands in for bodies and other gameplay nodes.
func _convert(live: Node, key: String) -> Node3D:
	var n: Node3D = null
	if live is MeshInstance3D:
		var m := MeshInstance3D.new()
		m.mesh = (live as MeshInstance3D).mesh
		m.material_override = (live as MeshInstance3D).material_override
		m.cast_shadow = (live as MeshInstance3D).cast_shadow
		n = m
	elif live is MultiMeshInstance3D:
		var mm := MultiMeshInstance3D.new()
		var src := (live as MultiMeshInstance3D).multimesh
		if src:
			var copy := MultiMesh.new()
			copy.transform_format = src.transform_format
			copy.use_colors = src.use_colors
			copy.use_custom_data = src.use_custom_data
			copy.mesh = src.mesh
			copy.instance_count = src.instance_count
			copy.buffer = src.buffer
			mm.multimesh = copy
		mm.material_override = (live as MultiMeshInstance3D).material_override
		n = mm
	elif live is Label3D or live is Light3D:
		n = (live as Node3D).duplicate(0)
		for c in n.get_children():
			n.remove_child(c)
			c.free()
		n.set_script(null)
		n.visible = true
	elif live is GPUParticles3D or live is CPUParticles3D or live is CollisionShape3D or live is AudioStreamPlayer3D \
			or live is Camera3D or not (live is Node3D):
		return null
	else:
		n = Node3D.new()
	if not (live is Label3D or live is Light3D):
		n.transform = (live as Node3D).transform
	n.name = _readable(live)
	n.set_meta("rl_src", key)
	var kids: Array = []
	for c in live.get_children():
		kids.append(c)
	var ks := AssetLibrary.keys_for(kids, false)
	var kept := []
	for i in kids.size():
		var c := _convert(kids[i], ks[i])
		if c != null:
			n.add_child(c)
			kept.append(ks[i])
	if not kept.is_empty():
		n.set_meta("rl_kids", kept)
	if n.get_class() == "Node3D" and n.get_child_count() == 0:
		n.free()
		return null
	return n


func _readable(live: Node) -> String:
	if not AssetLibrary._anon(live):
		return String(live.name)
	var base := "Part"
	if live is MeshInstance3D:
		base = "Box" if (live as MeshInstance3D).mesh is BoxMesh else "Mesh"
	elif live is MultiMeshInstance3D:
		base = "Many"
	elif live is Label3D:
		base = "Sign"
	elif live is Light3D:
		base = "Light"
	elif live is StaticBody3D or live is AnimatableBody3D or live is CharacterBody3D:
		base = "Solid"
	var c := int(_names.get(base, 0)) + 1
	_names[base] = c
	return "%s%d" % [base, c]


func _title(file: String) -> String:
	return file.capitalize().replace(" ", "")


## Within one scene: identical boxes share one mesh, identical materials share one material, and
## the patterns point at the PNG files (so the scene files stay small and easy to edit).
func _share_resources(a: Node, used_tex: Dictionary) -> void:
	var meshes := {}
	var mats := {}
	var stack: Array = [a]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D and (x as MeshInstance3D).mesh is BoxMesh:
			var bm := (x as MeshInstance3D).mesh as BoxMesh
			var mk := str(bm.size.snapped(Vector3(0.0001, 0.0001, 0.0001)))
			if not meshes.has(mk):
				var nb := BoxMesh.new()
				nb.size = bm.size
				meshes[mk] = nb
			(x as MeshInstance3D).mesh = meshes[mk]
		if x is GeometryInstance3D and (x as GeometryInstance3D).material_override != null:
			var m: Material = (x as GeometryInstance3D).material_override
			var sig := _mat_sig(m)
			if not mats.has(sig):
				var c: Material = m.duplicate()
				if c is BaseMaterial3D:
					for prop in ["albedo_texture", "emission_texture", "normal_texture", "roughness_texture"]:
						var t = c.get(prop)
						if t is Texture2D:
							var id: int = (t as Texture2D).get_instance_id()
							if _tex_by_id.has(id):
								c.set(prop, _tex_res[_tex_by_id[id]])
								used_tex[_tex_by_id[id]] = true
							elif (t as Texture2D).resource_path != "":
								pass
				mats[sig] = c
			(x as GeometryInstance3D).material_override = mats[sig]
		if x is MultiMeshInstance3D and (x as MultiMeshInstance3D).multimesh:
			var mmesh := (x as MultiMeshInstance3D).multimesh.mesh
			if mmesh is BoxMesh:
				var nb2 := BoxMesh.new()
				nb2.size = (mmesh as BoxMesh).size
				(x as MultiMeshInstance3D).multimesh.mesh = nb2
		stack.append_array(x.get_children())


func _mat_sig(m: Material) -> String:
	var parts := [m.get_class()]
	for p in m.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_STORAGE):
			continue
		var nm := String(p["name"])
		if nm.begins_with("resource_"):
			continue
		var v = m.get(nm)
		if v is Object:
			parts.append(str(v.get_instance_id()) if v else "-")
		else:
			parts.append(str(v))
	return "|".join(parts)


## Every part's fingerprint, so the game can tell which parts were changed in the editor.
func _stamp(n: Node) -> void:
	n.set_meta("rl_fp", AssetLibrary.fingerprint(n))
	for c in n.get_children():
		_stamp(c)


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


func _node_count(n: Node) -> int:
	var c := 1
	for k in n.get_children():
		c += _node_count(k)
	return c


func _wipe(dir: String) -> void:
	var abs_dir := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(abs_dir):
		return
	var d := DirAccess.open(abs_dir)
	for sub in d.get_directories():
		_wipe(dir + "/" + sub)
		DirAccess.remove_absolute(abs_dir + "/" + sub)
	for file in d.get_files():
		DirAccess.remove_absolute(abs_dir + "/" + file)
