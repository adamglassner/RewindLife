extends SceneTree
## WORLD SCENE BUILDER: puts every asset scene (assets/scenes) together into res://world.tscn,
## the whole town for Godot's 3D editor: folders by place (Houses > Jamie > Fridge ...), preview
## lighting, and the walls, floors, trees and decorations clickable one by one.
##
## Run from the project folder:
##   godot --headless --path . -s res://tools/build_world_scene.gd
##
## It never runs by itself, and it won't overwrite a world.tscn that's been edited (it says so
## and stops; add --force to replace it anyway, which throws those edits away).

const OUT := "res://world.tscn"

var force := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--force":
			force = true
	_build()
	quit()


func _build() -> void:
	if not FileAccess.file_exists(AssetLibrary.MANIFEST):
		printerr("No assets yet: run tools/bake_assets.gd first.")
		return
	var mf: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AssetLibrary.MANIFEST))
	if FileAccess.file_exists(OUT) and not force:
		if not mf.has("world") or FileAccess.get_md5(OUT) != String(mf["world"]):
			printerr("Not building: world.tscn has been edited (or wasn't made by this tool), and this would replace it.")
			printerr("Run again with --force to replace it anyway (the edits in it are lost).")
			return
	var world := Node3D.new()
	world.name = "World"
	world.editor_description = """REWIND LIFE: the whole town, for looking around and editing.
Every object here is one of the asset scenes in assets/scenes.
- Click things in the 3D view to select them. Walls, floors, trees and decorations are clickable one by one; a usable object (a fridge, a car, a townsperson) is selected whole: tick Editable Children (right-click it in the Scene panel) to get at its parts, or open its own scene with the clapperboard icon.
- Change colors, textures, shapes, move or add parts: the game uses your changes.
- Add new things to any folder: they appear in the game (just to look at).
- Delete an object here and it's gone from the game too (it still works in the code). To remove one part of an object, open the object's own scene and delete it there.
- Hiding things (the eye icon) is only for looking while you edit, the game ignores it: hide roofs to see inside the houses. Decorations (every holiday at once) start hidden.
- A usable object's spot in town comes from the code: moving one as a whole isn't used.
- Lighting and Sky are only for the editor (the game has its own day and night).
This scene is made by tools/build_world_scene.gd, which won't overwrite it once you've edited it."""
	_add_lighting(world)
	var folders := {}
	var n := 0
	var editable := 0
	var paths: Array = (mf.get("assets", {}) as Dictionary).keys()
	paths.sort()
	for path in paths:
		var scene_path := AssetLibrary.SCENES + String(path) + ".tscn"
		if not ResourceLoader.exists(scene_path):
			continue
		var ps: PackedScene = load(scene_path)
		var inst: Node = ps.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		var parent := _folder(world, folders, String(path).get_base_dir())
		inst.name = String(path).get_file().capitalize().replace(" ", "")
		parent.add_child(inst, true)
		inst.owner = world
		if String(path).begins_with("decorations/"):
			parent.visible = false     # (every holiday's decorations at once: click the eye to see them)
		# A building's loose parts, a yard, the woods, a holiday's decorations: one click, one part
		if not inst.has_meta("rl_src"):
			world.set_editable_instance(inst, true)
			editable += 1
		n += 1
	var out := PackedScene.new()
	out.pack(world)
	var err := ResourceSaver.save(out, OUT)
	world.free()
	if err != OK:
		printerr("Couldn't save world.tscn (%d)" % err)
		return
	mf["world"] = FileAccess.get_md5(OUT)
	var fm := FileAccess.open(AssetLibrary.MANIFEST, FileAccess.WRITE)
	fm.store_string(JSON.stringify(mf, "  "))
	fm.close()
	print("world.tscn: %d objects in %d folders (%d with their parts clickable)" % [n, folders.size(), editable])


## Houses > Jamie, Buildings > Mall > Clothes ... (made as needed)
func _folder(world: Node3D, folders: Dictionary, dir: String) -> Node3D:
	if dir == "":
		return world
	if folders.has(dir):
		return folders[dir]
	var parent := _folder(world, folders, dir.get_base_dir())
	var f := Node3D.new()
	f.name = dir.get_file().capitalize().replace(" ", "")
	f.set_meta("rl_folder", true)
	parent.add_child(f, true)
	f.owner = world
	folders[dir] = f
	return f


## A sky and a sun, so the town isn't flat grey in the editor (the game has its own).
func _add_lighting(world: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "EditorLighting"
	holder.set_meta("rl_editor_only", true)
	holder.editor_description = "Only for looking at the town in the editor; the game doesn't use it."
	world.add_child(holder)
	holder.owner = world
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("4F8FD8")
	sm.sky_horizon_color = Color("BFD9EE")
	sm.ground_horizon_color = Color("BFD9EE")
	sm.ground_bottom_color = Color("6B7A55")
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.name = "Sky"
	we.environment = env
	holder.add_child(we)
	we.owner = world
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	holder.add_child(sun)
	sun.owner = world
