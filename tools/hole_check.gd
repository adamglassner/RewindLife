extends SceneTree
## HOLE CHECK: flies the House Cam over the whole town (and the attics and
## basements) with the background painted bright magenta, and reports every spot
## where magenta shows through, i.e. a gap in the world (a missing floor, a
## missing stair riser, a slit between two walls).
##
## Needs a real renderer (not --headless). Run from the project folder:
##   godot --path . -s res://tools/hole_check.gd -- --out=/tmp/holes
## Prints one line per hole (world position, how many pixels) and saves a
## close-up picture of each to the --out folder. "0 holes" means all clear.

const MAGENTA := Color(1, 0, 1)
var main: Node
var out_dir := ""
var step := 11.0
var only := Rect2()


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.get_slice("=", 1)
		elif a.begins_with("--step="):
			step = float(a.get_slice("=", 1))
		elif a.begins_with("--only="):
			var v := a.get_slice("=", 1).split(",")
			only = Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://main.tscn").instantiate()
	main.skip_title = true
	root.add_child(main)
	_run.call_deferred()


func _run() -> void:
	for i in 6:
		await process_frame
	main.clock.unix_time += 4 * 3600      # noon
	main.settle_npcs()
	main.clock.set_speed(0)
	var env: Environment = main.env
	env.background_color = MAGENTA
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.adjustment_enabled = false
	env.glow_enabled = false
	env.fog_enabled = false
	env.ssao_enabled = false
	main.post_mat.set_shader_parameter("enabled", false)
	main.hud.visible = false
	main._current_room = "(fixed)"
	var rig: CameraRig = main.rig
	rig.set_mode(CameraRig.Mode.HOUSE)
	root.size = Vector2i(960, 540)
	var views: Array = []
	var w: Rect2 = RoomBuilder.WORLD
	var x := w.position.x + step / 2.0
	while x < w.end.x:
		var z := w.position.y + step / 2.0
		while z < w.end.y:
			if only.size == Vector2.ZERO or only.has_point(Vector2(x, z)):
				for yaw in [40.0, 130.0, 220.0, 310.0]:
					views.append([Vector3(x, 0.4, z), yaw])
			z += step
		x += step
	# The attics and basements float in the dark underground: look at each one
	# (only holes inside the rooms count there).
	var under: Array[Rect2] = []
	for i in InteriorBuilder.HOMES.size():
		under.append(InteriorBuilder.attic_rect(i))
		under.append(InteriorBuilder.basement_rect(i))
	if only.size == Vector2.ZERO:
		for r in under:
			for yaw in [40.0, 220.0]:
				views.append([Vector3(r.get_center().x, RoomBuilder.INTERIOR_Y + 0.4, r.get_center().y), yaw])
	print("hole check: %d views" % views.size())
	var found := {}      # rounded world spot -> [pixels, picture]
	var n := 0
	for v in views:
		n += 1
		rig.target = v[0]
		rig.house_yaw = deg_to_rad(v[1])
		rig.house_pitch = deg_to_rad(46.0)
		rig.house_dist = 13.0
		rig._update_house(0.0)
		main._update_walls()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var hits := _magenta(img)
		if hits.is_empty():
			continue
		# Cluster the magenta pixels by where they'd be in the world (on the floor plane).
		var cam: Camera3D = rig.cam
		var groups := {}
		var plane_y: float = float(v[0].y) - 0.4
		for px: Vector2i in hits:
			var o := cam.project_ray_origin(Vector2(px) * (Vector2(main.get_viewport().get_visible_rect().size) / Vector2(img.get_size())))
			var d := cam.project_ray_normal(Vector2(px) * (Vector2(main.get_viewport().get_visible_rect().size) / Vector2(img.get_size())))
			if absf(d.y) < 0.01:
				continue
			var t := (plane_y - o.y) / d.y
			var wp := o + d * t
			if plane_y < -10.0:
				var inside := false
				for r in under:
					if r.grow(-0.1).has_point(Vector2(wp.x, wp.z)):
						inside = true
				if not inside:
					continue
			var key := Vector3(roundf(wp.x), plane_y, roundf(wp.z))
			if not groups.has(key):
				groups[key] = []
			(groups[key] as Array).append(px)
		for key in groups:
			var pxs: Array = groups[key]
			if pxs.size() < 3:
				continue
			if found.has(key) and int(found[key][0]) >= pxs.size():
				continue
			var pic := ""
			if out_dir != "":
				var c: Vector2i = pxs[pxs.size() / 2]
				var r := Rect2i(c - Vector2i(120, 90), Vector2i(240, 180)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
				pic = "%s/hole_%d_%d_%d.png" % [out_dir, int(key.x), int(key.z), int(v[1])]
				img.get_region(r).save_png(pic)
			found[key] = [pxs.size(), pic, v[1]]
	var keys := found.keys()
	keys.sort_custom(func(a, b): return a.z < b.z or (a.z == b.z and a.x < b.x))
	for k in keys:
		print("  HOLE near (%.0f, %.0f, %.0f)  %d px  yaw %d  %s" % [k.x, k.y, k.z, found[k][0], found[k][2], found[k][1]])
	print("hole check: %d holes in %d views" % [keys.size(), n])
	quit()


func _magenta(img: Image) -> Array:
	var out := []
	var w := img.get_width()
	var h := img.get_height()
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			var c := img.get_pixel(x, y)
			if c.r > 0.8 and c.g < 0.25 and c.b > 0.8:
				out.append(Vector2i(x, y))
	return out
