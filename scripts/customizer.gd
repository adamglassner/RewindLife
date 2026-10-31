class_name Customizer
extends CanvasLayer
## The look screen: boy or girl, an 80s or 90s hairstyle, hair color, skin tone
## and one of six outfits, with the kid turning on a little stage. Shown when you
## start a new game (or pick who to play online), and from the dresser and the
## bathroom mirror.

signal done(look: Dictionary)
signal cancelled
signal sound(name: String)

var look := {}
var _menus: Menus
var _root: Control
var _title: Label
var _sub: Label
var _values := {}               # row key -> Label
var _stage: Node3D
var _figure: Node3D
var _viewport: SubViewport
var _back: Button
var _ok: Button
var _first: Button
var _can_cancel := true


func setup(menus: Menus) -> void:
	_menus = menus
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func is_open() -> bool:
	return visible


## Show it. `heading` e.g. "WHO'S JAMIE?"; `can_cancel` = a BACK button.
## Which outfits the arrows step through (Catalog.outfits_for: the starting six plus what you bought).
var allowed_outfits: Array = [0, 1, 2, 3, 4, 5]


func open(start_look: Dictionary, heading: String, subtitle: String, can_cancel := true, outfits: Array = []) -> void:
	allowed_outfits = outfits if not outfits.is_empty() else range(Catalog.FREE_OUTFITS)
	look = Looks.normalized(start_look.duplicate())
	_title.text = heading
	_sub.text = subtitle
	_can_cancel = can_cancel
	_back.visible = can_cancel
	visible = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_refresh()
	_first.grab_focus()


func close() -> void:
	visible = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu") or event.is_action_pressed("pad_back"):
		get_viewport().set_input_as_handled()
		if _can_cancel:
			sound.emit("ui_move")
			close()
			cancelled.emit()


func _process(delta: float) -> void:
	if visible and _figure:
		# turn a little to one side and the other, always facing the camera
		_figure.rotation.y = PI + sin(Time.get_ticks_msec() * 0.0009) * 0.7


# ================================================================ choices

const ROWS := ["gender", "hair", "hair_color", "skin", "outfit"]


func _step(key: String, d: int) -> void:
	sound.emit("ui_move")
	match key:
		"gender":
			look["gender"] = "girl" if look["gender"] == "boy" else "boy"
		"hair":
			look["hair"] = Looks.HAIR_STYLES[posmod(Looks.hair_index(look["hair"]) + d, Looks.HAIR_STYLES.size())][0]
		"hair_color":
			look["hair_color"] = posmod(int(look["hair_color"]) + d, Looks.HAIR_COLORS.size())
		"skin":
			look["skin"] = posmod(int(look["skin"]) + d, Looks.SKIN_TONES.size())
		"outfit":
			# (only the outfits you have: the six you start with, plus any you bought at the mall)
			var at := allowed_outfits.find(int(look["outfit"]))
			look["outfit"] = allowed_outfits[posmod(at + d, allowed_outfits.size())] if at >= 0 else allowed_outfits[0]
	_refresh()


func _refresh() -> void:
	var h: Array = Looks.HAIR_STYLES[Looks.hair_index(look["hair"])]
	var o: Dictionary = Looks.OUTFITS[int(look["outfit"])]
	(_values["gender"] as Label).text = "GIRL" if look["gender"] == "girl" else "BOY"
	(_values["hair"] as Label).text = "%s  ('%s)" % [h[1], String(h[2]).substr(0, 2)]
	(_values["hair_color"] as Label).text = Looks.HAIR_COLOR_NAMES[int(look["hair_color"])]
	(_values["skin"] as Label).text = "Tone %d of %d" % [int(look["skin"]) + 1, Looks.SKIN_TONES.size()]
	(_values["outfit"] as Label).text = "%s  ('%s)" % [o["name"], String(o["era"]).substr(0, 2)]
	if _figure:
		_figure.queue_free()
	_figure = Node3D.new()
	_stage.add_child(_figure)
	Looks.build(_figure, look)
	_figure.rotation.y = PI


# ================================================================ building

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = _menus._root.theme
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.06, 0.04, 0.07, 0.72)
	_root.add_child(dim)
	var wrap := CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(wrap)
	var panel := PanelContainer.new()
	wrap.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	_title = _menus._label("", 44, Palette.GOLD)
	v.add_child(_title)
	_sub = _menus._label("", 22, Palette.CRT)
	v.add_child(_sub)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	v.add_child(h)

	# The little stage: the kid turning slowly under a spotlight
	var frame := PanelContainer.new()
	var st := _menus._style(Color("2B2236"), Palette.CREAM, 3)
	st.set_content_margin_all(0)
	frame.add_theme_stylebox_override("panel", st)
	h.add_child(frame)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(340, 440)
	frame.add_child(svc)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = false
	_viewport.msaa_3d = Viewport.MSAA_4X
	svc.add_child(_viewport)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("2B2236")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("D8C8E8")
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	_viewport.add_child(we)
	_stage = Node3D.new()
	_viewport.add_child(_stage)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 3.0)
	cam.fov = 34.0
	_viewport.add_child(cam)
	cam.look_at(Vector3(0, 0.82, 0))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 30, 0)
	key.light_energy = 1.1
	key.light_color = Color("FFF1D6")
	_viewport.add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-1.2, 1.8, -1.2)
	rim.light_color = Palette.ROSE
	rim.light_energy = 1.6
	rim.omni_range = 4.0
	_viewport.add_child(rim)
	var floor := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.62
	cyl.height = 0.08
	floor.mesh = cyl
	floor.position.y = -0.04
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Palette.CORAL
	floor.material_override = fm
	_stage.add_child(floor)

	# The choices
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	h.add_child(col)
	var names := {"gender": "BOY OR GIRL", "hair": "HAIRSTYLE", "hair_color": "HAIR COLOR", "skin": "SKIN TONE", "outfit": "OUTFIT"}
	var focus := []
	for k in ROWS:
		col.add_child(_menus._label(names[k], 22, Palette.CREAM))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		col.add_child(row)
		var prev := _arrow("<", func(): _step(k, -1))
		row.add_child(prev)
		var val := _menus._label("", 28, Palette.PAPER)
		val.custom_minimum_size = Vector2(330, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(val)
		_values[k] = val
		var next := _arrow(">", func(): _step(k, 1))
		row.add_child(next)
		focus.append(prev)
		focus.append(next)
		if _first == null:
			_first = next
	var tip := _menus._label("The 80s: big, bold and bright. The 90s: baggy, grungy and cool.", 18, Palette.MUTED)
	col.add_child(tip)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	v.add_child(buttons)
	_back = _menus._button("BACK", func():
		sound.emit("ui_move")
		close()
		cancelled.emit())
	_back.custom_minimum_size = Vector2(200, 52)
	buttons.add_child(_back)
	_ok = _menus._button("LOOKS GOOD!", func():
		sound.emit("ui_select")
		close()
		done.emit(look.duplicate()))
	_ok.custom_minimum_size = Vector2(300, 52)
	buttons.add_child(_ok)


func _arrow(t: String, cb: Callable) -> Button:
	var b := _menus._button(t, cb)
	b.custom_minimum_size = Vector2(56, 48)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return b
