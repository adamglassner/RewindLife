class_name Menus
extends CanvasLayer
## The title screen (with the live neighborhood turning slowly behind it), the
## pause menu, options, the controls list, and a yes/no box.
## Works with mouse, keyboard (arrows + Enter) and gamepad (D-pad/stick + A/B).

signal continue_pressed
signal new_game_pressed
signal resume_pressed
signal save_pressed
signal quit_to_title_pressed
signal quit_pressed
signal settings_changed
signal sound(name: String)
signal host_pressed(new_world: bool)
signal join_pressed(address: String)
signal character_chosen(slot: int)
signal characters_back
signal local_coop_pressed
signal debug_set_date(year: int, month: int, day: int)
signal debug_set_money(amount: float)
signal debug_set_time(hour: int, minute: int)

enum Mode { HIDDEN, TITLE, PAUSE }

var mode := Mode.HIDDEN
var has_save := false
var font: Font

var _root: Control
var _dim: ColorRect
var _title: Control
var _osd_play: Label
var _osd_date: Label
var _panels := {}            # name -> Control
var _current := ""
var _back_to := ""
var _confirm_yes: Callable
var _confirm_label: Label
var _blink := 0.0
var _focus_ok := false       # don't click on the very first focus
var _online_status: Label
var _address: LineEdit
var _message: Label
var _pause_info: Label
var _logo: Control
var _sub: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_font()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = _make_theme()
	add_child(_root)
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.08, 0.05, 0.08, 0.55)
	_root.add_child(_dim)
	_build_title()
	_panels["main"] = _menu_panel("", [
		["CONTINUE", func(): _press(continue_pressed)],
		["NEW GAME", _on_new_game],
		["PLAY ONLINE", func():
			_online_status.text = ""
			_show("online", "main")],
		["OPTIONS", func(): _show("options", "main")],
		["CONTROLS", func(): _show("controls", "main")],
		["WHAT'S NEW", func(): _show("changelog", "main")],
		["CREDITS", func(): _show("credits", "main")],
		["QUIT", func(): _press(quit_pressed)],
	])
	_panels["pause"] = _menu_panel("PAUSED", [
		["RESUME", func(): _press(resume_pressed)],
		["SAVE GAME", func(): _press(save_pressed)],
		["2 PLAYERS", func(): _press(local_coop_pressed)],
		["OPTIONS", func(): _show("options", "pause")],
		["CONTROLS", func(): _show("controls", "pause")],
		["WHAT'S NEW", func(): _show("changelog", "pause")],
		["CREDITS", func(): _show("credits", "pause")],
		["DEBUG", func(): _open_debug()],
		["QUIT TO TITLE", func(): _ask("Quit to the title screen?\nYour game will be saved.", func(): _press(quit_to_title_pressed), "pause")],
		["QUIT GAME", func(): _ask("Quit the game?\nYour game will be saved.", func(): _press(quit_pressed), "pause")],
	])
	_panels["options"] = _build_options()
	_panels["controls"] = _build_controls()
	_panels["changelog"] = _build_changelog()
	_panels["credits"] = _build_credits()
	_panels["confirm"] = _build_confirm()
	_panels["debug_lock"] = _build_debug_lock()
	_panels["debug"] = _build_debug()
	_panels["online"] = _build_online()
	_panels["who"] = _build_who()
	_pause_info = _label("", 22, Palette.CRT)
	_pause_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pause_info.custom_minimum_size = Vector2(560, 0)
	(_panels["pause"] as VBoxContainer).add_child(_pause_info)
	(_panels["pause"] as VBoxContainer).move_child(_pause_info, 1)
	(_panels["pause"] as VBoxContainer).add_child(_label("Rewind Life · Prototype v" + Changelog.VERSION, 18, Palette.MUTED))
	_message = _label("", 24, Palette.CORAL)
	_message.position = Vector2(76, 640)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(900, 0)
	_title.add_child(_message)
	for p in _panels.values():
		p.visible = false
	visible = false


# ================================================================ showing

func show_title(save_exists: bool) -> void:
	has_save = save_exists
	mode = Mode.TITLE
	visible = true
	_title.visible = true
	_dim.color = Color(0.06, 0.04, 0.07, 0.35)
	(_panels["main"].get_meta("buttons")[0] as Button).visible = has_save
	_show("main", "")


## `info` = who's here when playing online ("" offline). `can_save` = false for
## friends who joined (the host saves the online world).
## `coop` = the split-screen button's text ("" hides it: it needs two controllers).
func show_pause(info := "", can_save := true, coop := "") -> void:
	mode = Mode.PAUSE
	visible = true
	_title.visible = false
	_dim.color = Color(0.08, 0.05, 0.08, 0.6)
	_pause_info.text = info
	_pause_info.visible = info != ""
	(_panels["pause"].get_meta("buttons")[1] as Button).visible = can_save
	var cb: Button = _panels["pause"].get_meta("buttons")[2]
	cb.visible = coop != ""
	cb.text = coop
	_show("pause", "")


## A message on the title screen (e.g. why you were disconnected).
func show_message(text: String) -> void:
	_message.text = text


func set_online_status(text: String) -> void:
	_online_status.text = text
	if mode == Mode.TITLE and _current != "online":
		_show("online", "main")


func hide_menus() -> void:
	mode = Mode.HIDDEN
	visible = false
	for p in _panels.values():
		p.visible = false


func is_open() -> bool:
	return mode != Mode.HIDDEN


func _show(panel: String, back_to: String) -> void:
	for p in _panels.values():
		p.visible = false
	_current = panel
	_back_to = back_to
	var c: Control = _panels[panel]
	c.visible = true
	# (the big logo would sit behind the framed panels, so it steps aside)
	_logo.visible = panel == "main"
	_sub.visible = panel == "main"
	_message.visible = panel == "main"
	_focus_ok = false
	var buttons: Array = c.get_meta("buttons", [])
	for b in buttons:
		if (b as Control).visible:
			(b as Control).grab_focus()
			break
	_focus_ok = true


## B / Esc: back out of a sub-menu, or resume from the pause menu.
func go_back() -> void:
	if _current == "online":
		sound.emit("ui_move")
		_show("main", "")
	elif _current == "who":
		sound.emit("ui_move")
		characters_back.emit()
	elif _current in ["options", "controls", "confirm", "changelog", "credits", "debug_lock", "debug"]:
		sound.emit("ui_move")
		_show(_back_to if _back_to != "" else ("pause" if mode == Mode.PAUSE else "main"),
			"" if _back_to in ["main", "pause"] else _back_to)
	elif mode == Mode.PAUSE:
		_press(resume_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu") or event.is_action_pressed("pad_back"):
		get_viewport().set_input_as_handled()
		if mode == Mode.TITLE and _current == "main":
			return
		go_back()


func _process(delta: float) -> void:
	if not is_open() or not _title.visible:
		return
	_blink += delta
	_osd_play.visible = fmod(_blink, 1.2) < 0.8


func _press(sig: Signal) -> void:
	sound.emit("ui_select")
	sig.emit()


func _on_new_game() -> void:
	if has_save:
		_ask("Start a new game?\nYour saved game will be replaced.", func(): _press(new_game_pressed), "main")
	else:
		_press(new_game_pressed)


func _ask(text: String, yes: Callable, back_to: String) -> void:
	sound.emit("ui_select")
	_confirm_label.text = text
	_confirm_yes = yes
	_show("confirm", back_to)
	_back_to = back_to


# ================================================================ building

func _load_font() -> void:
	if ResourceLoader.exists("res://fonts/VT323-Regular.ttf"):
		font = load("res://fonts/VT323-Regular.ttf")
	else:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["VT323", "Courier New", "DejaVu Sans Mono", "Consolas", "Menlo", "monospace"])
		sf.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font = sf


func _size(base: int) -> int:
	return base if font is FontFile else int(round(base * 0.78))


func _style(bg: Color, border: Color, width := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_content_margin_all(10)
	s.anti_aliasing = false
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = _size(28)
	var normal := _style(Palette.INK, Palette.CREAM)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Palette.INK2
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Palette.GOLD
	focus.border_color = Palette.PAPER
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", focus)
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", Palette.CREAM)
	t.set_color("font_hover_color", "Button", Palette.PAPER)
	t.set_color("font_focus_color", "Button", Palette.INK)
	t.set_color("font_pressed_color", "Button", Palette.INK)
	t.set_color("font_hover_pressed_color", "Button", Palette.INK)
	t.set_color("font_color", "Label", Palette.PAPER)
	t.set_color("font_color", "CheckButton", Palette.CREAM)
	t.set_color("font_focus_color", "CheckButton", Palette.GOLD)
	t.set_color("font_hover_color", "CheckButton", Palette.PAPER)
	t.set_stylebox("focus", "CheckButton", _style(Color(0, 0, 0, 0), Palette.GOLD, 2))
	t.set_stylebox("focus", "HSlider", _style(Color(0, 0, 0, 0), Palette.GOLD, 2))
	var track := StyleBoxFlat.new()
	track.bg_color = Palette.INK2
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Palette.CORAL
	fill.content_margin_top = 6
	fill.content_margin_bottom = 6
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_stylebox("panel", "PanelContainer", _style(Color(Palette.INK, 0.94), Palette.CREAM))
	return t


func _label(text: String, size: int, color: Color = Palette.PAPER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", _size(size))
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(340, 52)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(cb)
	b.focus_entered.connect(func():
		if _focus_ok:
			sound.emit("ui_move"))
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


func _build_title() -> void:
	_title = Control.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_title)
	# The logo, with a chunky two-color drop shadow
	var logo := Control.new()
	logo.position = Vector2(70, 70)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_child(logo)
	for layer_def in [[Vector2(10, 10), Palette.PLUM], [Vector2(5, 5), Palette.CORAL], [Vector2(0, 0), Palette.GOLD]]:
		var l := _label("REWIND\nLIFE", 120, layer_def[1])
		l.position = layer_def[0]
		l.add_theme_constant_override("line_spacing", -30)
		logo.add_child(l)
	var sub := _label("Saturday, June 14, 1986.  Summer vacation starts now.", 26, Palette.CRT)
	sub.position = Vector2(76, 330)
	_title.add_child(sub)
	_logo = logo
	_sub = sub
	# A VHS on-screen display, like pressing PLAY on the VCR
	_osd_play = _label("PLAY  >", 34, Palette.PAPER)
	_osd_play.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_osd_play.position = Vector2(-220, 34)
	_title.add_child(_osd_play)
	_osd_date = _label("SP   JUN.14 1986", 30, Palette.PAPER)
	_osd_date.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_osd_date.position = Vector2(-330, -70)
	_title.add_child(_osd_date)
	var ver := _label("Prototype v" + Changelog.VERSION, 20, Palette.MUTED)
	ver.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ver.position = Vector2(-250, 86)
	_title.add_child(ver)
	for l in [_osd_play, _osd_date]:
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		l.add_theme_constant_override("shadow_offset_x", 3)
		l.add_theme_constant_override("shadow_offset_y", 3)


## The buttons for the title menu and the pause menu, in two columns (so the whole menu fits
## in a small window too: one long column ran off the bottom of a 720-pixel-tall window).
func _menu_panel(heading: String, items: Array) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	if heading != "":
		box.set_anchors_preset(Control.PRESET_CENTER)
		box.position = Vector2(-347, -210)
		box.add_child(_label(heading, 56, Palette.GOLD))
	else:
		# the title menu: under the logo and the "Saturday, June 14" line
		box.set_anchors_preset(Control.PRESET_TOP_LEFT)
		box.position = Vector2(76, 378)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	var buttons := []
	for it in items:
		var b := _button(it[0], it[1])
		grid.add_child(b)
		buttons.append(b)
	box.set_meta("buttons", buttons)
	_root.add_child(box)
	return box


func _framed(heading: String) -> Array:
	var wrap := CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(wrap)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	wrap.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	v.add_child(_label(heading, 40, Palette.GOLD))
	return [wrap, v]


func _build_options() -> Control:
	var fr := _framed("OPTIONS")
	var v: VBoxContainer = fr[1]
	var focusables := []
	var rows := [
		["Music volume", Settings.music_volume, 0.0, 1.0, func(x): Settings.music_volume = x],
		["Sound volume", Settings.sound_volume, 0.0, 1.0, func(x): Settings.sound_volume = x],
		["Look sensitivity", Settings.look_sensitivity, 0.3, 2.5, func(x): Settings.look_sensitivity = x],
	]
	for r in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		var l := _label(r[0], 26)
		l.custom_minimum_size = Vector2(240, 0)
		h.add_child(l)
		var s := HSlider.new()
		s.min_value = r[2]
		s.max_value = r[3]
		s.step = 0.05
		s.value = r[1]
		s.custom_minimum_size = Vector2(300, 40)
		s.focus_mode = Control.FOCUS_ALL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var setter: Callable = r[4]
		s.value_changed.connect(func(x: float):
			setter.call(x)
			Settings.apply()
			settings_changed.emit())
		s.focus_entered.connect(func():
			if _focus_ok:
				sound.emit("ui_move"))
		s.set_meta("sync", r[0])
		h.add_child(s)
		v.add_child(h)
		focusables.append(s)
	for c in [["Fullscreen", Settings.fullscreen, func(on): Settings.fullscreen = on],
			["Invert look up/down", Settings.invert_y, func(on): Settings.invert_y = on]]:
		var cb := CheckButton.new()
		cb.text = c[0]
		cb.button_pressed = c[1]
		cb.focus_mode = Control.FOCUS_ALL
		cb.add_theme_font_size_override("font_size", _size(26))
		var setter2: Callable = c[2]
		cb.toggled.connect(func(on: bool):
			setter2.call(on)
			Settings.apply()
			settings_changed.emit()
			sound.emit("ui_select"))
		v.add_child(cb)
		focusables.append(cb)
	var back := _button("BACK", func():
		Settings.save_settings()
		go_back())
	v.add_child(back)
	focusables.append(back)
	fr[0].set_meta("buttons", focusables)
	return fr[0]


## WHAT'S NEW: every version, newest first (changelog.gd).
func _build_changelog() -> Control:
	var fr := _framed("WHAT'S NEW  ·  v" + Changelog.VERSION)
	var v: VBoxContainer = fr[1]
	var t := RichTextLabel.new()
	t.text = Changelog.text()
	t.custom_minimum_size = Vector2(900, 470)
	t.scroll_active = true
	t.focus_mode = Control.FOCUS_ALL
	t.add_theme_font_size_override("normal_font_size", _size(22))
	t.add_theme_color_override("default_color", Palette.PAPER)
	v.add_child(t)
	var tip := _label("Scroll with the mouse wheel, or the arrow keys / D-pad.", 18, Palette.CRT)
	v.add_child(tip)
	var back := _button("BACK", go_back)
	v.add_child(back)
	fr[0].set_meta("buttons", [t, back])
	return fr[0]


## CREDITS: who made the game.
func _build_credits() -> Control:
	var fr := _framed("CREDITS")
	var v: VBoxContainer = fr[1]
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	if ResourceLoader.exists("res://assets/branding/ironite_logo.png"):
		var logo := TextureRect.new()
		logo.texture = load("res://assets/branding/ironite_logo.png")
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(480, 220)
		v.add_child(logo)
	var lines := [
		["REWIND LIFE", 44, Palette.GOLD],
		["A game by Ironite", 30, Palette.PAPER],
		["Design, programming, art, music and sound: Ironite", 22, Palette.PAPER],
		["Every show, movie, store and song in Maple Grove is made up.", 20, Palette.CRT],
		["Made with the Godot Engine (godotengine.org), MIT license.", 20, Palette.CRT],
		["Prototype v%s  ·  © %d Ironite. All rights reserved." % [Changelog.VERSION, Changelog.YEAR], 20, Palette.MUTED],
	]
	for l in lines:
		var lb := _label(String(l[0]), int(l[1]), l[2])
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.custom_minimum_size = Vector2(760, 0)
		v.add_child(lb)
	var back := _button("BACK", go_back)
	v.add_child(back)
	fr[0].set_meta("buttons", [back])
	return fr[0]


func _build_controls() -> Control:
	var fr := _framed("CONTROLS")
	var v: VBoxContainer = fr[1]
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	var rows := [
		["", "KEYBOARD & MOUSE", "CONTROLLER"],
		["Move / pan", "WASD, arrows", "Left stick"],
		["Look / turn camera", "Mouse, Q/E", "Right stick"],
		["Use / select", "Click, E", "A  (Cross)"],
		["Back / close", "Esc", "B  (Circle)"],
		["Switch camera", "C", "Y  (Triangle)"],
		["Pause menu", "Esc", "Start / Options"],
		["Pause time", "P", "Back / Share"],
		["Jump", "Space", "X / Square"],
		["Game speed", "1  2  3", "LB / RB"],
		["Zoom", "Mouse wheel", "D-pad up / down"],
		["Free Will", "F", "D-pad left"],
		["Music on/off", "M", "D-pad right"],
		["Stop what Jamie's doing", "X on Up Next", "X  (Square)"],
		["Drive: gas / brake", "W / S", "RT / LT"],
		["Drive: steer", "A / D", "Left stick"],
		["Drive: horn", "H", "X  (Square)"],
		["Get out of the car", "E", "A  (Cross)"],
		["Chat (online)", "T or Enter", "-"],
		["Run (first person / shoulder)", "Hold Shift", "Click left stick"],
		["Room lights on/off", "Use the light switch", "(by the door, or a lamp)"],
		["Hop off your bike", "X on Up Next", "X  (Square)"],
		["Emotes (wave, dance...)", "G", "Click right stick"],
		["2 players (split screen)", "Pause menu", "Start on the 2nd controller"],
	]
	for i in rows.size():
		for j in 3:
			var col := Palette.GOLD if i == 0 else (Palette.CREAM if j == 0 else Palette.PAPER)
			grid.add_child(_label(rows[i][j], 22 if i > 0 else 20, col))
	var tip := _label("In the House Cam, the left stick moves a pointer: press A to use\nwhat it's over, or to walk there.", 20, Palette.CRT)
	v.add_child(tip)
	var back := _button("BACK", go_back)
	v.add_child(back)
	fr[0].set_meta("buttons", [back])
	return fr[0]


func _build_online() -> Control:
	var fr := _framed("PLAY ONLINE")
	var v: VBoxContainer = fr[1]
	var intro := _label("Up to 4 players. One person hosts; friends join with the host's IP address. Everyone " +
		"picks which kid on Maple Street to play, and how they look.", 22, Palette.PAPER)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(600, 0)
	v.add_child(intro)
	var host := _button("HOST GAME", func(): _press_host(false))
	host.custom_minimum_size = Vector2(600, 52)
	v.add_child(host)
	var fresh := _button("HOST A NEW WORLD", func():
		_ask("Start a new online world?\nThe old one (and your friends' progress in it) will be replaced.",
			func(): _press_host(true), "online"))
	fresh.custom_minimum_size = Vector2(600, 52)
	v.add_child(fresh)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_address = LineEdit.new()
	_address.placeholder_text = "Host's IP address"
	_address.custom_minimum_size = Vector2(380, 52)
	_address.focus_mode = Control.FOCUS_ALL
	_address.add_theme_font_size_override("font_size", _size(24))
	var st := _style(Palette.PAPER, Palette.CREAM, 3)
	st.set_content_margin_all(8)
	_address.add_theme_stylebox_override("normal", st)
	_address.add_theme_stylebox_override("focus", _style(Palette.PAPER, Palette.GOLD, 3))
	_address.add_theme_color_override("font_color", Palette.INK)
	_address.add_theme_color_override("font_placeholder_color", Color("8C7B6B"))
	_address.add_theme_color_override("caret_color", Palette.INK)
	_address.text_submitted.connect(func(t: String): _press_join())
	row.add_child(_address)
	var join := _button("JOIN GAME", _press_join)
	join.custom_minimum_size = Vector2(208, 52)
	row.add_child(join)
	_online_status = _label("", 22, Palette.CRT)
	_online_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_online_status.custom_minimum_size = Vector2(600, 0)
	v.add_child(_online_status)
	var tip := _label("Same Wi-Fi: use the host's local IP (it's shown when they host). Over the internet, the " +
		"host must forward UDP port %d on their router to their computer, and friends use the host's public IP." % Net.PORT,
		18, Palette.MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(600, 0)
	v.add_child(tip)
	var back := _button("BACK", go_back)
	v.add_child(back)
	fr[0].set_meta("buttons", [host, fresh, _address, join, back])
	return fr[0]


func _press_host(new_world: bool) -> void:
	sound.emit("ui_select")
	_online_status.text = "Starting..."
	host_pressed.emit(new_world)


func _press_join() -> void:
	sound.emit("ui_select")
	var a := _address.text.strip_edges()
	if a == "":
		_online_status.text = "Type the host's IP address first."
		_address.grab_focus()
		return
	_online_status.text = "Connecting to %s..." % a
	join_pressed.emit(a)


func _build_confirm() -> Control:
	var fr := _framed("ARE YOU SURE?")
	var v: VBoxContainer = fr[1]
	_confirm_label = _label("", 26, Palette.PAPER)
	v.add_child(_confirm_label)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var no := _button("NO", go_back)
	no.custom_minimum_size = Vector2(200, 52)
	var yes := _button("YES", func():
		var cb := _confirm_yes
		cb.call())
	yes.custom_minimum_size = Vector2(200, 52)
	h.add_child(no)
	h.add_child(yes)
	fr[0].set_meta("buttons", [no, yes])
	return fr[0]


# ================================================================ who do you want to play?

var _who_buttons: Array = []
var _who_note: Label


func _build_who() -> Control:
	var fr := _framed("WHO DO YOU WANT TO PLAY?")
	var v: VBoxContainer = fr[1]
	_who_note = _label("", 22, Palette.CRT)
	_who_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_who_note.custom_minimum_size = Vector2(640, 0)
	v.add_child(_who_note)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	var focus := []
	for i in Sim.CHARACTERS.size():
		var ch: Dictionary = Sim.CHARACTERS[i]
		var b := _button("", func():
			sound.emit("ui_select")
			character_chosen.emit(i))
		b.custom_minimum_size = Vector2(330, 64)
		b.set_meta("base", "%s\n%s" % [String(ch["full"]).to_upper(), _house_name(ch["home"])])
		b.add_theme_font_size_override("font_size", _size(22))
		grid.add_child(b)
		_who_buttons.append(b)
		focus.append(b)
	var back := _button("BACK", go_back)
	v.add_child(back)
	focus.append(back)
	fr[0].set_meta("buttons", focus)
	return fr[0]


static func _house_name(home: String) -> String:
	return Families.plural(home) + "' House"


## Pick a kid. `taken` = slots other players already have.
func show_characters(taken: Array, note: String) -> void:
	mode = Mode.TITLE if mode == Mode.HIDDEN else mode
	visible = true
	_who_note.text = note
	for i in _who_buttons.size():
		var b: Button = _who_buttons[i]
		var t: bool = taken.has(i)
		b.disabled = t
		b.text = String(b.get_meta("base")) + ("  (taken)" if t else "")
	_show("who", "online")
	for b in _who_buttons:
		if not (b as Button).disabled:
			(b as Button).grab_focus()
			break


# ================================================================ debug (password: "password")

const DEBUG_PASSWORD := "password"
var debug_unlocked := false        # stays open for the rest of this run once the password is right
var debug_allowed := true          # main.gd: false for a friend who joined someone else's game
var _debug_pass: LineEdit
var _debug_lock_msg: Label
var _debug_month: SpinBox
var _debug_day: SpinBox
var _debug_year: SpinBox
var _debug_money: SpinBox
var _debug_hour: SpinBox
var _debug_minute: SpinBox
var _debug_ampm: Button
var _debug_msg: Label
var get_debug_state: Callable      # main.gd: returns {"year", "month", "day", "money"}


func _open_debug() -> void:
	if debug_unlocked and debug_allowed:
		_fill_debug()
		_show("debug", "pause")
	else:
		_debug_pass.text = ""
		_debug_lock_msg.text = "" if debug_allowed else "Only the host can use the debug menu."
		_show("debug_lock", "pause")
		_debug_pass.grab_focus()


func _text_field(placeholder: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.custom_minimum_size = Vector2(380, 52)
	e.focus_mode = Control.FOCUS_ALL
	e.add_theme_font_size_override("font_size", _size(24))
	var st := _style(Palette.PAPER, Palette.CREAM, 3)
	st.set_content_margin_all(8)
	e.add_theme_stylebox_override("normal", st)
	e.add_theme_stylebox_override("focus", _style(Palette.PAPER, Palette.GOLD, 3))
	e.add_theme_color_override("font_color", Palette.INK)
	return e


func _build_debug_lock() -> Control:
	var fr := _framed("DEBUG")
	var v: VBoxContainer = fr[1]
	v.add_child(_label("Password:", 26, Palette.PAPER))
	_debug_pass = _text_field("password")
	_debug_pass.secret = true
	v.add_child(_debug_pass)
	_debug_lock_msg = _label("", 22, Palette.CORAL)
	v.add_child(_debug_lock_msg)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var back := _button("BACK", go_back)
	back.custom_minimum_size = Vector2(200, 52)
	var ok := _button("UNLOCK", _try_debug_password)
	ok.custom_minimum_size = Vector2(200, 52)
	h.add_child(back)
	h.add_child(ok)
	_debug_pass.text_submitted.connect(func(_t: String): _try_debug_password())
	fr[0].set_meta("buttons", [ok, back])
	return fr[0]


func _try_debug_password() -> void:
	if not debug_allowed:
		_debug_lock_msg.text = "Only the host can use the debug menu."
		return
	if _debug_pass.text == DEBUG_PASSWORD:
		sound.emit("ui_select")
		debug_unlocked = true
		_fill_debug()
		_show("debug", "pause")
	else:
		sound.emit("ui_move")
		_debug_lock_msg.text = "Wrong password."
		_debug_pass.text = ""
		_debug_pass.grab_focus()


func _spin(lo: float, hi: float, step: float, w := 150.0) -> SpinBox:
	var sb := SpinBox.new()
	sb.min_value = lo
	sb.max_value = hi
	sb.step = step
	sb.custom_minimum_size = Vector2(w, 52)
	sb.get_line_edit().add_theme_font_size_override("font_size", _size(24))
	sb.focus_mode = Control.FOCUS_NONE
	sb.get_line_edit().focus_mode = Control.FOCUS_ALL
	return sb


func _build_debug() -> Control:
	var fr := _framed("DEBUG")
	var v: VBoxContainer = fr[1]
	# the date (the time of day stays the same)
	v.add_child(_label("Date  (month / day / year)", 24, Palette.CRT))
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 10)
	v.add_child(dh)
	_debug_month = _spin(1, 12, 1, 120)
	_debug_day = _spin(1, 31, 1, 120)
	_debug_year = _spin(1980, 1999, 1, 160)
	dh.add_child(_debug_month)
	dh.add_child(_debug_day)
	dh.add_child(_debug_year)
	var set_date := _button("SET DATE", func():
		var y := int(_debug_year.value)
		var m := int(_debug_month.value)
		var d := mini(int(_debug_day.value), _days_in(y, m))
		_debug_day.value = d
		sound.emit("ui_select")
		debug_set_date.emit(y, m, d)
		_debug_msg.text = "Date set to %d/%d/%d." % [m, d, y])
	set_date.custom_minimum_size = Vector2(260, 52)
	dh.add_child(set_date)
	# the time of day
	v.add_child(_label("Time  (hour : minute)", 24, Palette.CRT))
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 10)
	v.add_child(th)
	_debug_hour = _spin(1, 12, 1, 120)
	_debug_minute = _spin(0, 59, 1, 120)
	th.add_child(_debug_hour)
	th.add_child(_debug_minute)
	_debug_ampm = _button("AM", func():
		_debug_ampm.text = "PM" if _debug_ampm.text == "AM" else "AM")
	_debug_ampm.custom_minimum_size = Vector2(80, 52)
	_debug_ampm.alignment = HORIZONTAL_ALIGNMENT_CENTER
	th.add_child(_debug_ampm)
	var set_time := _button("SET TIME", func():
		var h12 := int(_debug_hour.value) % 12
		var h := h12 + (12 if _debug_ampm.text == "PM" else 0)
		var mi := int(_debug_minute.value)
		sound.emit("ui_select")
		debug_set_time.emit(h, mi)
		_debug_msg.text = "Time set to %d:%02d %s." % [int(_debug_hour.value), mi, _debug_ampm.text])
	set_time.custom_minimum_size = Vector2(180, 52)
	th.add_child(set_time)
	# money
	v.add_child(_label("Money ($)", 24, Palette.CRT))
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 10)
	v.add_child(mh)
	_debug_money = _spin(0, 99999, 0.25, 240)
	mh.add_child(_debug_money)
	var set_money := _button("SET MONEY", func():
		sound.emit("ui_select")
		debug_set_money.emit(float(_debug_money.value))
		_debug_msg.text = "Money set to $%.2f." % _debug_money.value)
	set_money.custom_minimum_size = Vector2(260, 52)
	mh.add_child(set_money)
	_debug_msg = _label("", 22, Palette.GOLD)
	v.add_child(_debug_msg)
	var back := _button("BACK", go_back)
	back.custom_minimum_size = Vector2(200, 52)
	v.add_child(back)
	fr[0].set_meta("buttons", [set_date, set_time, set_money, back])
	return fr[0]


func _fill_debug() -> void:
	_debug_msg.text = ""
	if get_debug_state.is_valid():
		var st: Dictionary = get_debug_state.call()
		_debug_year.value = int(st.get("year", 1986))
		_debug_month.value = int(st.get("month", 6))
		_debug_day.value = int(st.get("day", 14))
		_debug_money.value = float(st.get("money", 0.0))
		var h := int(st.get("hour", 8))
		var mi := int(st.get("minute", 0))
		_debug_hour.value = 12 if h % 12 == 0 else h % 12
		_debug_minute.value = mi
		_debug_ampm.text = "PM" if h >= 12 else "AM"


static func _days_in(y: int, m: int) -> int:
	if m == 2:
		return 29 if (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)) else 28
	return 30 if m in [4, 6, 9, 11] else 31
