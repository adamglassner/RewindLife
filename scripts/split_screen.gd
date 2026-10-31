class_name SplitScreen
extends Node
## Two players on one screen (local co-op), side by side. Only offered when two
## controllers are plugged in: press START on the second one to join in.
##
##   Player 1 (left):  keyboard / mouse and the FIRST controller, as always
##   Player 2 (right): the SECOND controller
##      left stick  walk            right stick  look around
##      A           use / pick      B            back
##      X           stop what you're doing       click left stick  run
##      Y           emotes (wave, dance, cheer...)
##      RB          jump
##      START       Player 2 menu (keep playing / leave)
##
## Both kids share the same world and the same clock. Player 1 keeps the time
## controls, the driving and the House Cam; first person is off while you share
## the screen (you'd vanish from your friend's half).

signal changed(on: bool)

const DEAD := 0.22

var main: Node
var active := false
var p1_pad := -1
var p2_pad := -1
var sim: Sim = null                 # Player 2's kid
var rig: CameraRig = null           # Player 2's camera

var _views: CanvasLayer
var _vp1: SubViewport
var _vp2: SubViewport
var _pick_cam: Camera3D
var _picking := false
var _pick_list: Array = []
var _pick_i := 0
var _pick_yaw := 0.0

# Player 2's HUD (right half)
var _ui: CanvasLayer
var _root: Control
var _name: Label
var _money: Label
var _mood: Label
var _bars := {}
var _doing: Label
var _prompt: Label
var _prompt_panel: PanelContainer
var _dot: ColorRect
var _notice: Label
var _notice_panel: PanelContainer
var _notice_tw: Tween
var _menu: PanelContainer
var _menu_box: VBoxContainer
var _menu_rows: Array = []          # [{"label", "ok", "do": Callable}]
var _menu_i := 0
var _menu_open := false
var _pick_panel: PanelContainer
var _pick_name: Label
var _pick_note: Label
var _stick_held := 0                # -1 / 1 while the stick is pushed (menus step once per push)
var _stick_x_held := 0
var _hint_shown := false
var _hover: SmartObject = null
var _refresh_t := 0.0


func setup(p_main: Node) -> void:
	main = p_main
	Input.joy_connection_changed.connect(_on_joy)


## How many controllers are plugged in.
static var fake := false            # (testing without controllers: --split)


static func pads() -> Array[int]:
	var out: Array[int] = []
	if fake:
		out.assign([0, 1])
		return out
	out.assign(Input.get_connected_joypads())
	out.sort()
	return out


func can_start() -> bool:
	return not active and pads().size() >= 2 and not main.net.is_online() and not main.in_title


func is_p2(s: Sim) -> bool:
	return active and s != null and s == sim


# ================================================================ start / stop

func start(pad := -1) -> void:
	if not can_start():
		return
	var list := pads()
	p2_pad = pad if pad >= 0 and list.has(pad) else list[1]
	p1_pad = list[0] if list[0] != p2_pad else list[1]
	active = true
	InputSetup.set_pad_device(p1_pad)
	CameraRig.allow_first = false
	if main.rig.mode == CameraRig.Mode.FIRST:
		main.rig.set_mode(CameraRig.Mode.SHOULDER)
	_build_views()
	_build_ui()
	main.hud.set_area(0.0, 0.5)
	# Pick a kid
	_pick_list = []
	for i in Sim.CHARACTERS.size():
		if not main.sims.has(i):
			_pick_list.append(i)
	_pick_i = 0
	_picking = true
	_pick_cam = Camera3D.new()
	_pick_cam.fov = 50.0
	_pick_cam.near = 0.2
	_pick_cam.far = 900.0
	_vp2.add_child(_pick_cam)
	_pick_cam.current = true
	_show_pick()
	main.audio.play_ui("memory_chime", -10.0)
	main.hud.notify("Player 2 is joining in!")
	changed.emit(true)


func stop(reason := "") -> void:
	if not active:
		return
	active = false
	_picking = false
	if sim:
		var slot := sim.slot
		(main.local_store as Dictionary)[str(slot)] = SaveGame.sim_state(sim, main)
		main.remove_sim(slot)
	sim = null
	if rig:
		rig.queue_free()
		rig = null
	# Player 1's camera goes back on the whole screen
	var cam: Camera3D = main.rig.cam
	cam.reparent(main.rig, false)
	cam.current = true
	_views.queue_free()
	_ui.queue_free()
	_views = null
	_ui = null
	main.hud.set_area(0.0, 1.0)
	InputSetup.set_pad_device(-1)
	CameraRig.allow_first = true
	if reason != "":
		main.hud.notify(reason)
	changed.emit(false)


func _build_views() -> void:
	_views = CanvasLayer.new()
	_views.name = "SplitViews"
	_views.layer = -1
	main.add_child(_views)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_views.add_child(row)
	var rootvp := main.get_viewport()
	var px := float(DisplayServer.window_get_size().x) / maxf(1.0, rootvp.get_visible_rect().size.x)
	var vps: Array[SubViewport] = []
	for i in 2:
		var c := SubViewportContainer.new()
		c.stretch = true
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.set_process_input(false)
		c.set_process_unhandled_input(false)
		row.add_child(c)
		var v := SubViewport.new()
		v.gui_disable_input = true
		v.msaa_3d = rootvp.msaa_3d
		v.screen_space_aa = rootvp.screen_space_aa
		v.use_debanding = rootvp.use_debanding
		v.scaling_3d_scale = clampf(px, 1.0, 2.0)
		v.audio_listener_enable_3d = i == 0
		v.positional_shadow_atlas_size = 4096
		c.add_child(v)
		vps.append(v)
		if i == 0:
			# a thin divider between the halves
			pass
	_vp1 = vps[0]
	_vp2 = vps[1]
	var line := ColorRect.new()
	line.color = Palette.INK
	line.anchor_left = 0.5
	line.anchor_right = 0.5
	line.anchor_bottom = 1.0
	line.offset_left = -2
	line.offset_right = 2
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_views.add_child(line)
	# Player 1's camera moves into the left half
	var cam: Camera3D = main.rig.cam
	cam.reparent(_vp1, false)
	cam.current = true


## The size Player 1's view has on screen (for the mouse and the pad cursor).
func p1_size() -> Vector2:
	var s: Vector2 = main.get_viewport().get_visible_rect().size
	return Vector2(s.x * 0.5, s.y) if active else s


## (testing) Pick the kid now.
func debug_pick(i := 0) -> void:
	if _picking:
		_pick_i = clampi(i, 0, _pick_list.size() - 1)
		_choose_kid()


func _choose_kid() -> void:
	var slot: int = _pick_list[_pick_i]
	_picking = false
	_pick_panel.visible = false
	if _pick_cam:
		_pick_cam.queue_free()
		_pick_cam = null
	sim = main.add_sim(slot, false)
	sim.set_look(Sim.CHARACTERS[slot]["look"])
	var saved: Dictionary = (main.local_store as Dictionary).get(str(slot), {})
	if not saved.is_empty():
		SaveGame.apply_sim_state(sim, saved)
	sim.set_view_mode(false, true)
	rig = CameraRig.new()
	rig.owns_mouse = false
	rig.name = "Player2Rig"
	main.add_child(rig)
	rig.setup(sim)
	rig.cam.reparent(_vp2, false)
	rig.cam.current = true
	rig.set_mode(CameraRig.Mode.SHOULDER)
	rig.face_yaw(sim.rotation.y)
	sim.set_view_mode(false, false)
	sim.queue_changed.connect(_refresh)
	_name.text = sim.character_name.to_upper() + "  ·  PLAYER 2"
	_refresh()
	notify("Hi, %s! A = use, X = stop, Y = emotes, START = menu." % sim.character_name)
	main.hud.notify("%s is playing too!" % sim.character_name)


# ================================================================ input

func _on_joy(device: int, connected: bool) -> void:
	if active:
		if not connected and (device == p2_pad):
			stop("Player 2's controller was unplugged.")
		elif not connected and device == p1_pad:
			stop("Player 1's controller was unplugged.")
		return
	if connected and pads().size() >= 2 and not main.net.is_online() and not main.in_title:
		main.hud.notify("A second controller! Press START on it to play together (split screen).")


func _process(delta: float) -> void:
	if not active:
		if not _hint_shown and not main.in_title and pads().size() >= 2 and not main.net.is_online() \
				and main.hud != null and Engine.get_process_frames() > 30:
			_hint_shown = true
			main.hud.notify("Two controllers are plugged in: press START on the second one to play together!")
		return
	if _picking:
		_pick_yaw += delta * 0.25
		var ch: Dictionary = Sim.CHARACTERS[_pick_list[_pick_i]]
		var at: Vector3 = ch["spawn"]
		_pick_cam.global_position = at + Vector3(sin(_pick_yaw) * 7.0, 4.5, cos(_pick_yaw) * 7.0)
		_pick_cam.look_at(at + Vector3(0, 0.8, 0), Vector3.UP)
		return
	if sim == null:
		return
	_refresh_t += delta
	if _refresh_t > 0.5:
		_refresh_t = 0.0
		_refresh()
	# What's in front of Player 2?
	var obj: SmartObject = null
	if not _menu_open:
		var from := rig.cam.global_position
		var reach := 5.4
		var hit: Dictionary = main._ray(from, from - rig.cam.global_basis.z * reach)
		if not hit.is_empty():
			obj = hit["collider"] as SmartObject
	_hover = obj
	_prompt_panel.visible = obj != null and not _menu_open
	if obj:
		_prompt.text = "(A)  %s" % obj.display_name


func _physics_process(delta: float) -> void:
	if not active or sim == null or rig == null:
		return
	var dir := Vector3.ZERO
	if not _menu_open and not _picking and not main.menus.is_open():
		var v := _stick(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y)
		var mb := rig.move_basis()
		dir = (mb[0] as Vector3) * -v.y + (mb[1] as Vector3) * v.x
		rig.stick_look(_stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y), delta)
	sim.running = Input.is_joy_button_pressed(p2_pad, JOY_BUTTON_LEFT_STICK) and dir.length() > 0.0
	sim.drive(dir, delta)


func _stick(ax: JoyAxis, ay: JoyAxis) -> Vector2:
	var v := Vector2(Input.get_joy_axis(p2_pad, ax), Input.get_joy_axis(p2_pad, ay))
	if v.length() < DEAD:
		return Vector2.ZERO
	return v.normalized() * inverse_lerp(DEAD, 1.0, minf(1.0, v.length()))


func _input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	if not active:
		# START on a second controller: join in
		if event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START:
			var list := pads()
			if list.size() >= 2 and event.device != list[0] and can_start() and not main.menus.is_open() \
					and not main.customizer.is_open() and main.driving == null:
				get_viewport().set_input_as_handled()
				start(event.device)
		return
	if event.device != p2_pad:
		return
	get_viewport().set_input_as_handled()
	if main.menus.is_open():
		return
	var up := 0
	var side := 0
	if event is InputEventJoypadMotion:
		var m := event as InputEventJoypadMotion
		if m.axis == JOY_AXIS_LEFT_Y:
			var s := 0 if absf(m.axis_value) < 0.6 else int(signf(m.axis_value))
			if s != _stick_held:
				_stick_held = s
				up = s
		elif m.axis == JOY_AXIS_LEFT_X:
			var s := 0 if absf(m.axis_value) < 0.6 else int(signf(m.axis_value))
			if s != _stick_x_held:
				_stick_x_held = s
				side = s
		if not _menu_open and not _picking:
			return
	var b := -1
	if event is InputEventJoypadButton and event.pressed:
		b = (event as InputEventJoypadButton).button_index
		match b:
			JOY_BUTTON_DPAD_UP:
				up = -1
			JOY_BUTTON_DPAD_DOWN:
				up = 1
			JOY_BUTTON_DPAD_LEFT:
				side = -1
			JOY_BUTTON_DPAD_RIGHT:
				side = 1
	if _picking:
		if side != 0 or up != 0:
			_pick_i = posmod(_pick_i + (side if side != 0 else up), _pick_list.size())
			main.audio.play_ui("ui_move", -12.0)
			_show_pick()
		elif b == JOY_BUTTON_A:
			main.audio.play_ui("ui_select", -8.0)
			_choose_kid()
		elif b == JOY_BUTTON_B:
			stop("Player 2 changed their mind.")
		return
	if _menu_open:
		if up != 0 and not _menu_rows.is_empty():
			_menu_i = posmod(_menu_i + up, _menu_rows.size())
			main.audio.play_ui("ui_move", -12.0)
			_draw_menu()
		elif b == JOY_BUTTON_A and not _menu_rows.is_empty():
			var row: Dictionary = _menu_rows[_menu_i]
			if row["ok"]:
				main.audio.play_ui("ui_select", -8.0)
				close_menu()
				(row["do"] as Callable).call()
		elif b == JOY_BUTTON_B or b == JOY_BUTTON_START:
			close_menu()
		return
	match b:
		JOY_BUTTON_A:
			if _hover:
				_open_object(_hover)
		JOY_BUTTON_X:
			sim.cancel(0)
		JOY_BUTTON_RIGHT_SHOULDER:
			sim.jump()
		JOY_BUTTON_START:
			_open_pause()
		JOY_BUTTON_Y, JOY_BUTTON_RIGHT_STICK:
			var rows := []
			for k in Sim.EMOTE_ORDER:
				var kind: String = k
				rows.append({"label": String(Sim.EMOTES[kind][0]), "ok": true, "do": func():
					if not sim.emote(kind):
						notify("Stand still to do that.")})
			_show_menu("EMOTES", rows)


# ================================================================ Player 2's menus

func _open_object(obj: SmartObject) -> void:
	var rows := []
	for act: Activity in obj.activities:
		if not Catalog.can_use(sim.owned, act) or not Phonebook.listed(act, sim.home, obj) or act.hidden_now(main.clock):
			continue
		var ok := act.available(main.clock)
		var text := "%s  ·  %s" % [act.title, act.duration_label()]
		if act.money < 0.0:
			text += "  ·  $%.2f" % -act.money
		if not ok:
			text = "%s  (%s)" % [act.title, act.when_label()]
		elif act.drive:
			ok = false
			text = "%s  (Player 1 drives)" % act.title
		elif act.customize or act.ui == "diary":
			ok = false
			text = "%s  (Player 1 only)" % act.title
		elif act.needs_item != "" and not sim.items.has(act.needs_item):
			ok = false
			text = "%s  (needs %s)" % [act.title, Sim.ITEM_NAMES.get(act.needs_item, act.needs_item)]
		elif act.buys != "" and act.buys != "bike" and sim.owned.has(act.buys):
			ok = false
			text = "%s  (you have it)" % act.title
		elif act.money < 0.0 and sim.money + act.money < 0.0:
			ok = false
			text = "%s  (costs $%.2f)" % [act.title, -act.money]
		var a := act
		rows.append({"label": text, "ok": ok, "do": func(): sim.enqueue(obj, a)})
	rows.append({"label": "Never mind", "ok": true, "do": func(): pass})
	_show_menu(obj.display_name.to_upper(), rows)


func _open_pause() -> void:
	_show_menu("PLAYER 2", [
		{"label": "Keep Playing", "ok": true, "do": func(): pass},
		{"label": "Free Will: %s" % ("On" if sim.free_will else "Off"), "ok": true, "do": func():
			sim.free_will = not sim.free_will
			notify("Free Will is %s." % ("on" if sim.free_will else "off"))},
		{"label": "Leave the Game", "ok": true, "do": func(): stop("%s went home. (Press START on the second controller to play again.)" % sim.character_name)},
	])


func _show_menu(title: String, rows: Array) -> void:
	_menu_rows = rows
	_menu_i = 0
	for i in rows.size():
		if rows[i]["ok"]:
			_menu_i = i
			break
	_menu_open = true
	_menu.visible = true
	_menu.set_meta("title", title)
	_draw_menu()


func _draw_menu() -> void:
	for c in _menu_box.get_children():
		c.queue_free()
	_menu_box.add_child(_label(String(_menu.get_meta("title", "")), 24, Palette.GOLD))
	for i in _menu_rows.size():
		var r: Dictionary = _menu_rows[i]
		var sel := i == _menu_i
		var l := _label(("> " if sel else "   ") + String(r["label"]), 22,
			Palette.GOLD if sel else (Palette.PAPER if r["ok"] else Color(Palette.MUTED, 0.55)))
		_menu_box.add_child(l)
	_menu.reset_size()


func close_menu() -> void:
	_menu_open = false
	_menu.visible = false


# ================================================================ Player 2's HUD

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", main.hud.font)
	l.add_theme_font_size_override("font_size", main.hud._size(size))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _panel(alpha := 0.88) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", main.hud._style(Color(Palette.INK, alpha), Palette.GOLD, 3, true))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "Player2Hud"
	_ui.layer = 5
	main.add_child(_ui)
	_root = Control.new()
	_root.anchor_left = 0.5
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_root)
	# Top left of the right half: who, money, mood and needs
	var card := _panel(0.8)
	card.position = Vector2(14, 14)
	_root.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	_name = _label("PLAYER 2", 24, Palette.GOLD)
	v.add_child(_name)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	_money = _label("$0.00", 22, Palette.CRT)
	h.add_child(_money)
	_mood = _label("", 22, Palette.PAPER)
	h.add_child(_mood)
	for n in Needs.NAMES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		v.add_child(row)
		var l := _label(String(n).capitalize(), 18, Palette.MUTED)
		l.custom_minimum_size = Vector2(70, 0)
		row.add_child(l)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(150, 12)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(Palette.INK2, 0.9)
		var fg := StyleBoxFlat.new()
		fg.bg_color = Palette.CRT
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fg)
		row.add_child(bar)
		_bars[n] = [bar, fg]
	_doing = _label("", 20, Palette.PAPER)
	_doing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_doing.custom_minimum_size = Vector2(240, 0)
	v.add_child(_doing)
	# The dot in the middle, and what you're looking at
	_dot = ColorRect.new()
	_dot.color = Color(Palette.PAPER, 0.85)
	_dot.size = Vector2(6, 6)
	_dot.anchor_left = 0.5
	_dot.anchor_right = 0.5
	_dot.anchor_top = 0.5
	_dot.anchor_bottom = 0.5
	_dot.offset_left = -3
	_dot.offset_top = -3
	_dot.offset_right = 3
	_dot.offset_bottom = 3
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dot)
	_prompt_panel = _panel()
	_prompt_panel.anchor_left = 0.5
	_prompt_panel.anchor_right = 0.5
	_prompt_panel.anchor_top = 0.5
	_prompt_panel.anchor_bottom = 0.5
	_prompt_panel.offset_top = 30
	_prompt_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_panel.visible = false
	_root.add_child(_prompt_panel)
	_prompt = _label("", 22, Palette.PAPER)
	_prompt_panel.add_child(_prompt)
	# Notices along the bottom
	_notice_panel = _panel()
	_notice_panel.anchor_left = 0.08
	_notice_panel.anchor_right = 0.92
	_notice_panel.anchor_top = 1.0
	_notice_panel.anchor_bottom = 1.0
	_notice_panel.offset_top = -110
	_notice_panel.offset_bottom = -24
	_notice_panel.modulate.a = 0.0
	_root.add_child(_notice_panel)
	_notice = _label("", 22, Palette.PAPER)
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice_panel.add_child(_notice)
	# Menus
	_menu = _panel(0.94)
	_menu.anchor_left = 0.5
	_menu.anchor_right = 0.5
	_menu.anchor_top = 0.5
	_menu.anchor_bottom = 0.5
	_menu.offset_left = -40
	_menu.offset_top = -60
	_menu.visible = false
	_root.add_child(_menu)
	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 6)
	_menu.add_child(_menu_box)
	# Picking a kid
	_pick_panel = _panel(0.92)
	_pick_panel.anchor_left = 0.12
	_pick_panel.anchor_right = 0.88
	_pick_panel.anchor_top = 1.0
	_pick_panel.anchor_bottom = 1.0
	_pick_panel.offset_top = -200
	_pick_panel.offset_bottom = -30
	_root.add_child(_pick_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 4)
	_pick_panel.add_child(pv)
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	var head := _label("PLAYER 2: WHO ARE YOU?", 24, Palette.GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(head)
	_pick_name = _label("", 34, Palette.PAPER)
	_pick_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(_pick_name)
	_pick_note = _label("", 20, Palette.MUTED)
	_pick_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(_pick_note)
	var keys := _label("<  >  pick     (A) play     (B) cancel", 20, Palette.CRT)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(keys)
	_show_pick()


func _show_pick() -> void:
	if _pick_name == null or _pick_list.is_empty():
		return
	var ch: Dictionary = Sim.CHARACTERS[_pick_list[_pick_i]]
	_pick_name.text = "<  %s  >" % String(ch["full"])
	_pick_note.text = "Lives in %s" % Menus._house_name(ch["home"])
	_pick_panel.visible = true


func _refresh() -> void:
	if sim == null or _money == null:
		return
	_money.text = "$%.2f" % sim.money
	_mood.text = sim.needs.mood_label()
	for n in Needs.NAMES:
		var val := sim.needs.value(n)
		(_bars[n][0] as ProgressBar).value = val
		(_bars[n][1] as StyleBoxFlat).bg_color = Palette.CORAL if val < 30.0 else Palette.CRT
	var jobs := sim.jobs()
	if jobs.is_empty():
		_doing.text = ""
	else:
		var j: Dictionary = jobs[0]
		_doing.text = "%s  %s\n(X) stop" % [j["title"], String(j["ends"])] if j["active"] else ""


func notify(text: String) -> void:
	if _notice == null:
		return
	_notice.text = text
	if _notice_tw:
		_notice_tw.kill()
	_notice_panel.modulate.a = 1.0
	_notice_tw = create_tween()
	_notice_tw.tween_interval(3.2 + text.length() * 0.03)
	_notice_tw.tween_property(_notice_panel, "modulate:a", 0.0, 0.6)


func memory(title: String) -> void:
	notify("* MEMORY: %s *" % title)
	main.audio.play_ui("memory_chime", -8.0)
