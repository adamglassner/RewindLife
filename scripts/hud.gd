class_name Hud
extends CanvasLayer
## The pixel-style interface from the mockups: clock, speed, cameras, needs,
## up-next queue, object menus and Memory Moment cards. The HUD only shows
## state and sends requests; it never changes game data itself.

signal speed_requested(level: int)
signal camera_requested(mode: int)
signal free_will_toggled(on: bool)
signal music_toggled(on: bool)
signal lights_toggled
signal activity_chosen(obj: SmartObject, act: Activity)
signal emote_chosen(kind: String)
signal cancel_requested(index: int)
signal menu_closed
signal diary_saved(text: String)
signal diary_closed

const NEED_COLORS := {"hunger": Palette.GOLD, "energy": Palette.CRT, "fun": Palette.CORAL, "social": Palette.ROSE}

var clock: GameClock
var sim: Sim
var font: Font
var menu_open := false
var diary_open := false
var notify_last := ""
var memories := 0

var _root: Control
var _date: Label
var _time: Label
var _ampm: Label
var _period: Label
var _day_bar: Control
var _day_fill: ColorRect
var _day_sun: ColorRect
var _speed_btns: Array[Button] = []
var _cam_btns: Array[Button] = []
var _free_will: Button
var _music: Button
var _lights: Button
var _location: Label
var _holiday: Label
var _need_ui := {}
var _mood_face: TextureRect
var _mood_lbl: Label
var _faces: Array[ImageTexture] = []
var _queue_box: VBoxContainer
var _hint: Label
var _prompt: PanelContainer
var _prompt_lbl: Label
var _crosshair: Control
var _toast: PanelContainer
var _toast_title: Label
var _toast_body: Label
var _notice: PanelContainer
var _notice_lbl: Label
var _menu: PanelContainer
var _menu_box: VBoxContainer
var _scrapbook: Label
var _toast_tween: Tween
var _notice_tween: Tween
var _wallet: Label
var _carrying: Label
var _drive_panel: PanelContainer
var _drive_title: Label
var _drive_mph: Label
var _drive_hint: Label
var _cursor: Control
var _cam_mode := 0
var _hint_panel: PanelContainer
## True when the player's last input came from a gamepad (changes the button hints).
var using_pad := false


func setup(p_clock: GameClock, p_sim: Sim) -> void:
	clock = p_clock
	sim = p_sim
	layer = 5
	_load_font()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	_faces = [_face_tex(0), _face_tex(1), _face_tex(2)]
	_build_clock()
	_build_camera_bar()
	_build_top_right()
	_build_queue()
	_build_needs()
	_build_center()
	_build_toast()
	_build_menu()
	_build_diary()
	_build_driving()
	_build_cursor()
	set_money(sim.money)
	sim.queue_changed.connect(refresh_queue)
	refresh_clock()
	refresh_needs()
	refresh_queue()


# ================================================================ style

func _load_font() -> void:
	if ResourceLoader.exists("res://fonts/VT323-Regular.ttf"):
		font = load("res://fonts/VT323-Regular.ttf")
	else:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["VT323", "Courier New", "DejaVu Sans Mono", "Consolas", "Menlo", "monospace"])
		sf.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font = sf


func _size(base: int) -> int:
	# VT323 is drawn small for its size; system monospace fonts need less.
	if font is FontFile:
		return base
	return int(round(base * 0.78))


func _style(bg: Color, border: Color, width := 3, shadow := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_content_margin_all(10)
	s.anti_aliasing = false
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 1
		s.shadow_offset = Vector2(5, 5)
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = _size(22)
	var normal := _style(Palette.INK, Palette.CREAM, 3, false)
	normal.set_content_margin_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Palette.INK2
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Palette.GOLD
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.border_color = Palette.INK2
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	var focus := _style(Color(0, 0, 0, 0), Palette.GOLD, 3, false)   # gamepad selection
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", Palette.CREAM)
	t.set_color("font_hover_color", "Button", Palette.PAPER)
	t.set_color("font_pressed_color", "Button", Palette.INK)
	t.set_color("font_hover_pressed_color", "Button", Palette.INK)
	t.set_color("font_disabled_color", "Button", Color("8C7B6B"))
	t.set_color("font_color", "Label", Palette.PAPER)
	t.set_stylebox("panel", "PanelContainer", _style(Palette.INK, Palette.CREAM))
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Palette.INK2
	t.set_stylebox("background", "ProgressBar", bar_bg)
	return t


func _label(text: String, size: int, color: Color = Palette.PAPER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", _size(size))
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, min_size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


func _bar(color: Color, min_size: Vector2) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.max_value = 100.0
	p.custom_minimum_size = min_size
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	p.add_theme_stylebox_override("fill", fill)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _vbox(sep := 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


func _hbox(sep := 6) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## 13x13 pixel mood faces: 0 happy, 1 neutral, 2 sad.
func _face_tex(kind: int) -> ImageTexture:
	var img := Image.create(13, 13, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 13:
		for x in 13:
			var inside := (x >= 1 and x <= 11 and y >= 1 and y <= 11) \
				or (x >= 2 and x <= 10 and (y == 0 or y == 12)) \
				or (y >= 2 and y <= 10 and (x == 0 or x == 12))
			if inside:
				img.set_pixel(x, y, Color.WHITE)
	var ink := Color(0.16, 0.12, 0.1)
	for p in [Vector2i(4, 4), Vector2i(4, 5), Vector2i(8, 4), Vector2i(8, 5)]:
		img.set_pixelv(p, ink)
	for x in range(4, 9):
		img.set_pixel(x, 9, ink)
	if kind == 0:
		img.set_pixel(3, 8, ink)
		img.set_pixel(9, 8, ink)
	elif kind == 2:
		img.set_pixel(3, 10, ink)
		img.set_pixel(9, 10, ink)
	return ImageTexture.create_from_image(img)


# ================================================================ build

func _build_clock() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	panel.custom_minimum_size = Vector2(320, 0)
	_root.add_child(panel)
	var v := _vbox(6)
	panel.add_child(v)
	_date = _label("", 22, Palette.CREAM)
	v.add_child(_date)
	var row := _hbox(10)
	v.add_child(row)
	_time = _label("", 60, Palette.GOLD)
	_time.add_theme_color_override("font_shadow_color", Color("6E2F1A"))
	_time.add_theme_constant_override("shadow_offset_x", 3)
	_time.add_theme_constant_override("shadow_offset_y", 3)
	row.add_child(_time)
	_ampm = _label("", 26, Palette.GOLD)
	_ampm.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(_ampm)
	row.add_child(_spacer())
	_period = _label("", 20, Palette.CRT)
	_period.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(_period)
	_day_bar = Control.new()
	_day_bar.custom_minimum_size = Vector2(0, 14)
	_day_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_day_bar)
	var bg := ColorRect.new()
	bg.color = Palette.INK2
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_day_bar.add_child(bg)
	_day_fill = ColorRect.new()
	_day_fill.color = Palette.CORAL
	_day_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_day_bar.add_child(_day_fill)
	_day_sun = ColorRect.new()
	_day_sun.color = Color("FBE3A0")
	_day_sun.size = Vector2(14, 22)
	_day_sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_day_bar.add_child(_day_sun)
	var speeds := _hbox(6)
	v.add_child(speeds)
	var labels := ["II", ">", ">>", ">>>"]
	for i in 4:
		var b := _button(labels[i], Vector2(68, 44), func(): speed_requested.emit(i))
		b.toggle_mode = true
		b.tooltip_text = ["Pause (P)", "Normal speed (1)", "Fast (2)", "Fastest (3)"][i]
		speeds.add_child(b)
		_speed_btns.append(b)
	var toggles := _hbox(6)
	v.add_child(toggles)
	_free_will = _button("FREE WILL: ON", Vector2(0, 40), func(): free_will_toggled.emit(_free_will.button_pressed))
	_free_will.toggle_mode = true
	_free_will.button_pressed = true
	_free_will.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_free_will.tooltip_text = "When on, Jamie picks things to do alone"
	_free_will.toggled.connect(func(on: bool): _free_will.text = "FREE WILL: ON" if on else "FREE WILL: OFF")
	toggles.add_child(_free_will)
	_music = _button("MUSIC: ON", Vector2(0, 40), func(): music_toggled.emit(_music.button_pressed))
	_music.toggle_mode = true
	_music.button_pressed = true
	_music.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_music.tooltip_text = "The house radio (M)"
	_music.toggled.connect(func(on: bool): _music.text = "MUSIC: ON" if on else "MUSIC: OFF")
	toggles.add_child(_music)
	# Where you are, and the room's light switch
	var where := _hbox(6)
	v.add_child(where)
	_location = _label("", 18, Palette.CREAM)
	_location.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_location.clip_text = true
	_location.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	where.add_child(_location)
	# (lights are switched at the light switch by the door, or a lamp: walk up and use it)
	_lights = _button("LIGHTS", Vector2(110, 36), func(): lights_toggled.emit())
	_lights.visible = false
	_holiday = _label("", 18, Palette.ROSE)
	_holiday.visible = false
	v.add_child(_holiday)
	clock.speed_changed.connect(_on_speed_changed)
	_on_speed_changed(clock.speed_level)


## Where the player is ("Kitchen", "Mr. & Mrs. Nguyen's Room"...) and whether
## that room has lights you can switch (and if they're on).
func set_location(text: String, has_lights: bool, lights_on: bool) -> void:
	_location.text = text.to_upper() + ("" if not has_lights or lights_on else "  ·  LIGHTS OFF")


## Today's holiday ("" for none).
func set_holiday(text: String) -> void:
	_holiday.text = text
	_holiday.visible = text != ""


## Used when the M key toggles music, so the button stays in sync.
func set_music_button(on: bool) -> void:
	_music.set_pressed_no_signal(on)
	_music.text = "MUSIC: ON" if on else "MUSIC: OFF"


func _on_speed_changed(level: int) -> void:
	for i in _speed_btns.size():
		_speed_btns[i].set_pressed_no_signal(i == level)


func _build_camera_bar() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.offset_top = 20
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	var v := _vbox(4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	var row := _hbox(0)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(row)
	for i in 3:
		var b := _button(CameraRig.MODE_NAMES[i], Vector2(0, 44), func(): camera_requested.emit(i))
		b.toggle_mode = true
		row.add_child(b)
		_cam_btns.append(b)
	var tip_panel := PanelContainer.new()
	var tip_style := _style(Color(Palette.INK, 0.85), Palette.INK2, 2, false)
	tip_style.set_content_margin_all(4)
	tip_style.content_margin_left = 10
	tip_style.content_margin_right = 10
	tip_panel.add_theme_stylebox_override("panel", tip_style)
	tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint = _label("", 18, Palette.CREAM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_panel.add_child(_hint)
	_hint_panel = tip_panel
	v.add_child(tip_panel)
	_notice = PanelContainer.new()
	_notice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_notice.modulate.a = 0.0
	_notice_lbl = _label("", 22, Palette.PAPER)
	_notice_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_lbl.custom_minimum_size = Vector2(500, 0)
	_notice_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.add_child(_notice_lbl)
	_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_notice)


func set_camera_mode(mode: int) -> void:
	_cam_mode = mode
	for i in _cam_btns.size():
		_cam_btns[i].set_pressed_no_signal(i == mode)
	_refresh_hint()
	_crosshair.visible = mode == CameraRig.Mode.FIRST
	_cursor.visible = mode == CameraRig.Mode.HOUSE and using_pad and visible
	if mode == CameraRig.Mode.HOUSE:
		set_prompt(null)


func _refresh_hint() -> void:
	_hint_panel.visible = true
	match _cam_mode:
		CameraRig.Mode.HOUSE:
			_hint.text = "(L) move cursor · (A) use or walk · (R) turn/zoom · (Y) camera · (X) cancel" if using_pad \
				else "Click to use or walk · Q/E rotate · wheel zoom · C camera · Esc menu"
		CameraRig.Mode.DRIVE:
			_hint.text = ""
			_hint_panel.visible = false
			return
		_:
			_hint.text = "(L) walk · (R) look · (A) use · (Y) camera · (X) cancel" if using_pad \
				else "WASD walk · E use · Tab free mouse · C camera · Esc menu"


## Switch the on-screen button hints between keyboard and gamepad.
func set_using_pad(on: bool) -> void:
	if on == using_pad:
		return
	using_pad = on
	_refresh_hint()
	_cursor.visible = _cam_mode == CameraRig.Mode.HOUSE and on
	if _drive_panel.visible:
		_drive_hint.text = _drive_hint_text()
	if _prompt.visible and _prompt_lbl.text.length() > 4:
		_prompt_lbl.text = ("(A)  " if on else "[E]  ") + _prompt_lbl.text.substr(5)


## Show a different character's needs and plans (online players).
## Split screen: Player 1's HUD keeps to its own half of the screen (a bit
## smaller, without the camera buttons: first person is off and Y / C still
## switch cameras).
var _half := false
const HALF_SCALE := 0.74


func set_area(from: float, to: float) -> void:
	_half = to - from < 0.99
	close_menu()
	if not get_viewport().size_changed.is_connected(_fit):
		get_viewport().size_changed.connect(_fit)
	(_cam_btns[0].get_parent() as Control).visible = not _half
	_hint_panel.visible = not _half
	_fit()


func _fit() -> void:
	if not _half:
		_root.scale = Vector2.ONE
		_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return
	var vp := get_viewport().get_visible_rect().size
	_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_root.position = Vector2.ZERO
	_root.scale = Vector2(HALF_SCALE, HALF_SCALE)
	_root.size = Vector2(vp.x * 0.5, vp.y) / HALF_SCALE


func set_sim(s: Sim) -> void:
	if sim and sim.queue_changed.is_connected(refresh_queue):
		sim.queue_changed.disconnect(refresh_queue)
	sim = s
	sim.queue_changed.connect(refresh_queue)
	set_free_will_button(s.free_will)
	set_memory_count(s.memories.size())
	set_money(s.money)
	set_items(s.items)
	refresh_needs()
	refresh_queue()


## Online: no speed buttons (time runs in real time), and a list of who's here.
func set_online(on: bool) -> void:
	for b in _speed_btns:
		b.visible = not on


func set_free_will_button(on: bool) -> void:
	_free_will.set_pressed_no_signal(on)
	_free_will.text = "FREE WILL: ON" if on else "FREE WILL: OFF"


func set_memory_count(n: int) -> void:
	memories = n
	_scrapbook.text = "%d %s" % [memories, "MEMORY" if memories == 1 else "MEMORIES"]


## What you're carrying: a rented tape, a library book.
func set_items(items: Dictionary) -> void:
	var names := []
	if items.has("tape"):
		names.append("1 TAPE")
	if items.has("book"):
		names.append("1 BOOK")
	if items.has("papers"):
		names.append("%d PAPERS" % (items["papers"].get("left", []) as Array).size())
	_carrying.text = "NOTHING" if names.is_empty() else " · ".join(names)
	var tips := []
	for k in items:
		tips.append("%s: \"%s\"" % [Sim.ITEM_NAMES.get(k, k).capitalize(), items[k].get("title", "")])
	_carrying.get_parent().get_parent().tooltip_text = "\n".join(tips)


func set_money(v: float) -> void:
	_wallet.text = "$%.2f" % v


func _build_top_right() -> void:
	var row := _hbox(10)
	row.anchor_left = 1.0
	row.anchor_right = 1.0
	row.offset_right = -20
	row.offset_left = -20
	row.offset_top = 20
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_root.add_child(row)
	var items := [["CARRYING", "NOTHING", Palette.CRT], ["SCRAPBOOK", "0 MEMORIES", Palette.ROSE], ["WALLET", "$42.50", Palette.GOLD]]
	for it in items:
		var p := PanelContainer.new()
		var v := _vbox(0)
		p.add_child(v)
		var a := _label(it[0], 18, Palette.MUTED)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.add_child(a)
		var b := _label(it[1], 26, it[2])
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.add_child(b)
		if it[0] == "SCRAPBOOK":
			_scrapbook = b
		if it[0] == "WALLET":
			_wallet = b
		if it[0] == "CARRYING":
			_carrying = b
		row.add_child(p)


func _build_queue() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_right = -20
	panel.offset_left = -20
	panel.offset_top = 124
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.custom_minimum_size = Vector2(290, 0)
	_root.add_child(panel)
	var v := _vbox(8)
	panel.add_child(v)
	v.add_child(_label("UP NEXT", 22, Palette.GOLD))
	_queue_box = _vbox(6)
	v.add_child(_queue_box)


func refresh_queue() -> void:
	if _queue_box == null:
		return
	for c in _queue_box.get_children():
		c.queue_free()
	var jobs := sim.jobs()
	if jobs.is_empty():
		var l := _label("Nothing planned.", 20, Palette.MUTED)
		_queue_box.add_child(l)
		return
	for i in jobs.size():
		var j: Dictionary = jobs[i]
		var p := PanelContainer.new()
		var st := _style(Palette.INK2 if j["active"] else Palette.INK, Palette.INK2 if j["active"] else Color("8C7B6B"), 2, false)
		st.set_content_margin_all(6)
		p.add_theme_stylebox_override("panel", st)
		_queue_box.add_child(p)
		var row := _hbox(8)
		p.add_child(row)
		var v := _vbox(3)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		var t := _label(j["title"], 22, Palette.PAPER)
		t.custom_minimum_size = Vector2(190, 0)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)
		if j["active"]:
			var bar := _bar(Palette.CRT, Vector2(0, 8))
			bar.value = float(j["progress"]) * 100.0
			v.add_child(bar)
			v.add_child(_label(j["ends"], 18, Palette.MUTED))
		var idx := i
		var x := _button("X", Vector2(40, 40), func(): cancel_requested.emit(idx))
		x.tooltip_text = "Cancel"
		x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(x)


func _build_needs() -> void:
	var panel := PanelContainer.new()
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 20
	panel.offset_top = -20
	panel.offset_bottom = -20
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_root.add_child(panel)
	var row := _hbox(16)
	panel.add_child(row)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(grid)
	for n in Needs.NAMES:
		var v := _vbox(3)
		var top := _hbox(4)
		top.add_child(_label(String(n).to_upper(), 20))
		top.add_child(_spacer())
		var val := _label("", 20, Palette.MUTED)
		top.add_child(val)
		v.add_child(top)
		var bar := _bar(NEED_COLORS[n], Vector2(170, 14))
		v.add_child(bar)
		grid.add_child(v)
		_need_ui[n] = {"bar": bar, "val": val}
	var sep := ColorRect.new()
	sep.color = Palette.INK2
	sep.custom_minimum_size = Vector2(2, 0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sep)
	var mood := _vbox(4)
	mood.alignment = BoxContainer.ALIGNMENT_CENTER
	mood.custom_minimum_size = Vector2(96, 0)
	row.add_child(mood)
	_mood_face = TextureRect.new()
	_mood_face.custom_minimum_size = Vector2(52, 52)
	_mood_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mood_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mood_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mood_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mood.add_child(_mood_face)
	_mood_lbl = _label("", 20, Palette.GOLD)
	_mood_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mood.add_child(_mood_lbl)


func _build_center() -> void:
	_crosshair = Control.new()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_crosshair)
	for r in [Rect2(-2, -11, 4, 22), Rect2(-11, -2, 22, 4)]:
		var c := ColorRect.new()
		c.color = Palette.PAPER
		c.position = r.position
		c.size = r.size
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_crosshair.add_child(c)
	_crosshair.visible = false

	_prompt = PanelContainer.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.offset_top = 60
	_prompt.offset_bottom = 60
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_lbl = _label("", 24, Palette.PAPER)
	_prompt.add_child(_prompt_lbl)
	_prompt.visible = false
	_root.add_child(_prompt)


func set_prompt(obj: SmartObject) -> void:
	if obj == null or menu_open:
		_prompt.visible = false
		return
	_prompt_lbl.text = "%s  %s" % ["(A)" if using_pad else "[E]", obj.display_name]
	_prompt.visible = true


func _build_toast() -> void:
	_toast = PanelContainer.new()
	var st := _style(Palette.PAPER, Palette.INK)
	st.set_content_margin_all(14)
	_toast.add_theme_stylebox_override("panel", st)
	_toast.anchor_left = 1.0
	_toast.anchor_right = 1.0
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_left = -24
	_toast.offset_right = -24
	_toast.offset_top = -24
	_toast.offset_bottom = -24
	_toast.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.custom_minimum_size = Vector2(340, 0)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	_root.add_child(_toast)
	var v := _vbox(6)
	_toast.add_child(v)
	v.add_child(_label("* MEMORY MOMENT", 20, Palette.RUST))
	_toast_title = _label("", 32, Palette.INK)
	_toast_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_title.custom_minimum_size = Vector2(310, 0)
	v.add_child(_toast_title)
	_toast_body = _label("", 21, Palette.WOOD_DARK)
	_toast_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_body.custom_minimum_size = Vector2(310, 0)
	v.add_child(_toast_body)
	v.add_child(_label("+15 Mood  ·  Saved to Scrapbook", 20, Color("2E6B69")))


func show_memory(title: String, body: String) -> void:
	memories += 1
	_scrapbook.text = "%d %s" % [memories, "MEMORY" if memories == 1 else "MEMORIES"]
	_toast_title.text = title
	_toast_body.text = body
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.6)
	_toast_tween.tween_interval(7.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 1.2)


func notify(text: String) -> void:
	notify_last = text
	_notice_lbl.text = text
	if _notice_tween:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_property(_notice, "modulate:a", 1.0, 0.25)
	_notice_tween.tween_interval(3.5)
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, 0.6)


func _build_menu() -> void:
	_menu = PanelContainer.new()
	_menu.visible = false
	_menu.custom_minimum_size = Vector2(320, 0)
	_root.add_child(_menu)
	_menu_box = _vbox(6)
	_menu.add_child(_menu_box)


func open_menu(obj: SmartObject, at: Vector2) -> void:
	at /= _root.scale.x
	for c in _menu_box.get_children():
		c.queue_free()
	_menu_box.add_child(_label(obj.display_name.to_upper(), 22, Palette.GOLD))
	for act in obj.activities:
		if not Catalog.can_use(sim.owned, act) or not Phonebook.listed(act, sim.home, obj) or act.hidden_now(clock):
			continue    # (things you don't own yet, or calling yourself, don't clutter the menu)
		var ok := act.available(clock)
		var text := "%s  ·  %s" % [act.title, act.duration_label()]
		if act.money < 0.0:
			text += "  ·  $%.2f" % -act.money
		if not ok:
			text = "%s  (%s)" % [act.title, act.when_label()]
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
		var b := _button(text, Vector2(0, 44), func():
			close_menu()
			activity_chosen.emit(obj, a))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not ok
		b.focus_mode = Control.FOCUS_ALL if ok else Control.FOCUS_NONE
		_menu_box.add_child(b)
	var nm := _button("Never mind", Vector2(0, 40), close_menu)
	nm.focus_mode = Control.FOCUS_ALL
	_menu_box.add_child(nm)
	_menu.reset_size()
	var vp := _root.size
	_menu.position = Vector2(clampf(at.x + 12, 10, vp.x - 340), clampf(at.y - 20, 10, vp.y - 60 - 50 * obj.activities.size()))
	_menu.visible = true
	menu_open = true
	_prompt.visible = false
	if using_pad:
		_focus_first.call_deferred(_menu_box)


## The emote menu (G, or click the right stick): wave, dance, cheer...
func open_emotes(at: Vector2) -> void:
	for c in _menu_box.get_children():
		c.queue_free()
	_menu_box.add_child(_label("EMOTES", 22, Palette.GOLD))
	for k in Sim.EMOTE_ORDER:
		var kind: String = k
		var b := _button(String(Sim.EMOTES[kind][0]), Vector2(0, 40), func():
			close_menu()
			emote_chosen.emit(kind))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_ALL
		_menu_box.add_child(b)
	var nm := _button("Never mind", Vector2(0, 40), close_menu)
	nm.focus_mode = Control.FOCUS_ALL
	_menu_box.add_child(nm)
	_menu.reset_size()
	at /= _root.scale.x
	var vp := _root.size
	_menu.position = Vector2(clampf(at.x + 12, 10, vp.x - 340), clampf(at.y - 20, 10, vp.y - 520))
	_menu.visible = true
	menu_open = true
	_prompt.visible = false
	if using_pad:
		_focus_first.call_deferred(_menu_box)


func _focus_first(box: Control) -> void:
	for c in box.get_children():
		if c is Button and c.focus_mode != Control.FOCUS_NONE and not c.is_queued_for_deletion():
			(c as Button).grab_focus()
			return


func close_menu() -> void:
	if not menu_open:
		return
	_menu.visible = false
	menu_open = false
	var f := _root.get_viewport().gui_get_focus_owner()
	if f:
		f.release_focus()
	menu_closed.emit()


# ================================================================ refresh

func refresh_clock() -> void:
	_date.text = clock.date_label()
	_time.text = clock.time_label()
	_ampm.text = clock.ampm()
	_period.text = clock.period_label()
	var w := _day_bar.size.x
	if w <= 0.0:
		w = 296.0
	var frac := clock.hour_float() / 24.0
	_day_fill.size = Vector2(w * frac, 14)
	_day_sun.position = Vector2(w * frac - 7, -4)


func refresh_needs() -> void:
	for n in Needs.NAMES:
		var v := sim.needs.value(n)
		var ui: Dictionary = _need_ui[n]
		(ui["bar"] as ProgressBar).value = v
		var lbl: Label = ui["val"]
		if v < 30.0:
			lbl.text = "LOW · %d" % int(v)
			lbl.add_theme_color_override("font_color", Color("F29A7A"))
		else:
			lbl.text = "%d" % int(v)
			lbl.add_theme_color_override("font_color", Palette.MUTED)
	var m := sim.needs.mood()
	_mood_lbl.text = sim.needs.mood_label()
	_mood_face.texture = _faces[0] if m >= 52.0 else (_faces[1] if m >= 30.0 else _faces[2])
	var tint := Palette.GOLD if m >= 52.0 else (Palette.MUTED if m >= 30.0 else Palette.CORAL)
	_mood_face.modulate = tint
	_mood_lbl.add_theme_color_override("font_color", tint)


func on_minute() -> void:
	refresh_clock()
	refresh_needs()
	set_money(sim.money)
	set_items(sim.items)
	if sim.state == Sim.State.DOING:
		refresh_queue()


# ================================================================ diary

var _diary: Control
var _diary_entries: Array = []
var _diary_index := 0
var _d_old_date: Label
var _d_old_text: Label
var _d_page: Label
var _d_prev: Button
var _d_next: Button
var _d_today: Label
var _d_edit: TextEdit
var _d_pad_note: Label
var _d_close: Button


func _paper(margin := 18) -> StyleBoxFlat:
	var st := _style(Palette.PAPER, Color("D9C9A6"), 2, false)
	st.set_content_margin_all(margin)
	return st


func _build_diary() -> void:
	_diary = Control.new()
	_diary.set_anchors_preset(Control.PRESET_FULL_RECT)
	_diary.visible = false
	_root.add_child(_diary)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.06, 0.08, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_diary.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_diary.add_child(center)

	var book := PanelContainer.new()       # the burgundy cover around the pages
	var cover := _style(Color("7B2D3A"), Color("4E1A24"), 3)
	cover.set_content_margin_all(14)
	book.add_theme_stylebox_override("panel", cover)
	center.add_child(book)
	var spread := _hbox(0)
	book.add_child(spread)

	# --- left page: past entries
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", _paper())
	left.custom_minimum_size = Vector2(420, 500)
	spread.add_child(left)
	var lv := _vbox(8)
	left.add_child(lv)
	lv.add_child(_label("PAST ENTRIES", 20, Palette.RUST))
	_d_old_date = _label("", 22, Palette.INK)
	lv.add_child(_d_old_date)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lv.add_child(scroll)
	_d_old_text = _label("", 21, Palette.WOOD_DARK)
	_d_old_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_old_text.custom_minimum_size = Vector2(370, 0)
	_d_old_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_d_old_text)
	var nav := _hbox(8)
	lv.add_child(nav)
	_d_prev = _button("< Older", Vector2(100, 40), func(): _show_entry(_diary_index - 1))
	nav.add_child(_d_prev)
	_d_page = _label("", 20, Palette.WOOD_DARK)
	_d_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_d_page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(_d_page)
	_d_next = _button("Newer >", Vector2(100, 40), func(): _show_entry(_diary_index + 1))
	nav.add_child(_d_next)

	# --- the spine
	var spine := ColorRect.new()
	spine.color = Color("4E1A24")
	spine.custom_minimum_size = Vector2(14, 0)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spread.add_child(spine)

	# --- right page: today's entry
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", _paper())
	right.custom_minimum_size = Vector2(420, 500)
	spread.add_child(right)
	var rv := _vbox(8)
	right.add_child(rv)
	_d_today = _label("", 22, Palette.INK)
	rv.add_child(_d_today)
	rv.add_child(_label("Dear Diary,", 24, Palette.RUST))
	_d_edit = TextEdit.new()
	_d_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_d_edit.placeholder_text = "Write about your day..."
	_d_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	var edit_style := StyleBoxFlat.new()
	edit_style.bg_color = Color("FFF8E8")
	edit_style.border_color = Color("E4704F")   # the red margin line
	edit_style.border_width_left = 3
	edit_style.set_content_margin_all(8)
	_d_edit.add_theme_stylebox_override("normal", edit_style)
	_d_edit.add_theme_stylebox_override("focus", edit_style)
	_d_edit.add_theme_color_override("font_color", Palette.INK)
	_d_edit.add_theme_color_override("font_placeholder_color", Color("A8977F"))
	_d_edit.add_theme_color_override("caret_color", Palette.INK)
	_d_edit.add_theme_color_override("selection_color", Color(Palette.GOLD, 0.5))
	_d_edit.add_theme_font_size_override("font_size", _size(24))
	rv.add_child(_d_edit)
	var buttons := _hbox(10)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	rv.add_child(buttons)
	_d_pad_note = _label("Writing needs a keyboard. (B) to close.", 18, Color("A8977F"))
	_d_pad_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_d_pad_note)
	_d_close = _button("Close", Vector2(110, 44), close_diary)
	_d_close.focus_mode = Control.FOCUS_ALL
	buttons.add_child(_d_close)
	var save := _button("Save Entry", Vector2(140, 44), _save_entry)
	buttons.add_child(save)


func open_diary(entries: Array, today: String) -> void:
	close_menu()
	_diary_entries = entries
	_d_today.text = today
	_d_edit.text = ""
	_show_entry(entries.size() - 1)
	_diary.visible = true
	diary_open = true
	_prompt.visible = false
	_d_pad_note.visible = using_pad
	_d_prev.focus_mode = Control.FOCUS_ALL if using_pad else Control.FOCUS_NONE
	_d_next.focus_mode = _d_prev.focus_mode
	if using_pad:
		_d_close.grab_focus()
	else:
		_d_edit.grab_focus()


func close_diary() -> void:
	if not diary_open:
		return
	_diary.visible = false
	diary_open = false
	_d_edit.release_focus()
	var f := _root.get_viewport().gui_get_focus_owner()
	if f:
		f.release_focus()
	diary_closed.emit()


func _save_entry() -> void:
	var text := _d_edit.text.strip_edges()
	if text == "":
		notify("Write something first!")
		return
	diary_saved.emit(text)
	_d_edit.text = ""
	_show_entry(_diary_entries.size() - 1)
	notify("Saved to your diary.")


func _show_entry(i: int) -> void:
	var n := _diary_entries.size()
	if n == 0:
		_d_old_date.text = ""
		_d_old_text.text = "No entries yet.\n\nToday is the first page!"
		_d_page.text = ""
		_d_prev.disabled = true
		_d_next.disabled = true
		return
	_diary_index = clampi(i, 0, n - 1)
	var e: Dictionary = _diary_entries[_diary_index]
	_d_old_date.text = "%s · %s" % [e.get("date", ""), e.get("time", "")]
	_d_old_text.text = String(e.get("text", ""))
	_d_page.text = "%d of %d" % [_diary_index + 1, n]
	_d_prev.disabled = _diary_index <= 0
	_d_next.disabled = _diary_index >= n - 1


# ================================================================ driving

func _build_driving() -> void:
	_drive_panel = PanelContainer.new()
	_drive_panel.anchor_left = 0.5
	_drive_panel.anchor_right = 0.5
	_drive_panel.offset_top = 84      # under the camera bar (its tip line is hidden while driving)
	_drive_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_drive_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drive_panel.visible = false
	_root.add_child(_drive_panel)
	var row := _hbox(22)
	_drive_panel.add_child(row)
	var left := _vbox(0)
	row.add_child(left)
	_drive_title = _label("", 22, Palette.CREAM)
	left.add_child(_drive_title)
	_drive_hint = _label("", 18, Palette.MUTED)
	left.add_child(_drive_hint)
	var sp := _hbox(4)
	row.add_child(sp)
	_drive_mph = _label("0", 56, Palette.CRT)
	_drive_mph.custom_minimum_size = Vector2(70, 0)
	_drive_mph.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sp.add_child(_drive_mph)
	var unit := _label("MPH", 22, Palette.CRT)
	unit.size_flags_vertical = Control.SIZE_SHRINK_END
	sp.add_child(unit)


func _drive_hint_text() -> String:
	if using_pad:
		return "RT gas · LT brake/back · (L) steer\n(X) horn · (A) get out when stopped (or order at a drive-thru)"
	return "W gas · S brake/back · A/D steer\nH horn · E get out when stopped (or order at a drive-thru)"


## The speedometer while driving. `title` is the car's name, or "" to hide it.
func set_driving(title: String) -> void:
	_drive_panel.visible = title != ""
	_drive_title.text = title.to_upper()
	_drive_hint.text = _drive_hint_text()
	_drive_mph.text = "0"
	# The needs and queue stay up; the object prompt doesn't make sense in a car.
	_prompt.visible = false
	_crosshair.visible = false


func set_mph(v: int) -> void:
	_drive_mph.text = str(v)


# ================================================================ gamepad cursor

func _build_cursor() -> void:
	_cursor = Control.new()
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.visible = false
	_root.add_child(_cursor)
	# A chunky pixel arrow: a dark outline with a cream fill.
	var rows := ["X", "XX", "XOX", "XOOX", "XOOOX", "XOOOOX", "XOOOOOX", "XOOOOXXX", "XOXOOX", "XX XOOX", "X  XOOX", "    XX"]
	for y in rows.size():
		var r: String = rows[y]
		for x in r.length():
			if r[x] == " ":
				continue
			var c := ColorRect.new()
			c.color = Palette.INK if r[x] == "X" else Palette.PAPER
			c.position = Vector2(x, y) * 3.0
			c.size = Vector2(3, 3)
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_cursor.add_child(c)


func set_cursor(pos: Vector2) -> void:
	_cursor.position = pos / _root.scale.x
