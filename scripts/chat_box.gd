class_name ChatBox
extends CanvasLayer
## Online chat: the last few lines in the lower left (they fade after a while),
## and a line to type in. T or Enter to talk, Enter to send, Esc to cancel.

signal sent(text: String)
signal closed

const KEEP := 7
const SHOW_SECONDS := 14.0

var _box: VBoxContainer
var _input: LineEdit
var _lines: Array = []          # [Label, time added (ms)]
var _font: Font
var _hint: Label


func setup(font: Font) -> void:
	_font = font
	layer = 6
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_box.position = Vector2(28, -420)
	_box.custom_minimum_size = Vector2(560, 0)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 2)
	root.add_child(_box)
	_input = LineEdit.new()
	_input.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_input.position = Vector2(28, -200)
	_input.custom_minimum_size = Vector2(560, 44)
	_input.max_length = 120
	_input.placeholder_text = "Say something... (Enter sends)"
	_input.add_theme_font_override("font", font)
	_input.add_theme_font_size_override("font_size", 20)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(Palette.INK, 0.92)
	st.border_color = Palette.GOLD
	st.set_border_width_all(3)
	st.set_content_margin_all(8)
	_input.add_theme_stylebox_override("normal", st)
	_input.add_theme_stylebox_override("focus", st)
	_input.add_theme_color_override("font_color", Palette.PAPER)
	_input.add_theme_color_override("font_placeholder_color", Palette.MUTED)
	_input.add_theme_color_override("caret_color", Palette.GOLD)
	_input.visible = false
	_input.text_submitted.connect(func(t: String):
		close()
		if t.strip_edges() != "":
			sent.emit(t))
	_input.gui_input.connect(func(e: InputEvent):
		if e is InputEventKey and e.pressed and (e as InputEventKey).keycode == KEY_ESCAPE:
			close()
			_input.accept_event())
	root.add_child(_input)
	_hint = _label("Press T to chat", Palette.MUTED)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.position = Vector2(30, -196)
	_hint.visible = false
	root.add_child(_hint)


func is_open() -> bool:
	return _input.visible


func open() -> void:
	_input.text = ""
	_input.visible = true
	_hint.visible = false
	_input.grab_focus()
	_show_all()


func close() -> void:
	if not _input.visible:
		return
	_input.visible = false
	_input.release_focus()
	closed.emit()


## Show the "Press T to chat" reminder (online only).
func set_hint(on: bool) -> void:
	_hint.visible = on and not is_open()


## A chat line. `who` = "" for game news ("Rosa joined the game!").
func add_line(who: String, text: String) -> void:
	var l := _label((("%s: " % who) if who != "" else "* ") + text, Palette.PAPER if who != "" else Palette.CRT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(560, 0)
	_box.add_child(l)
	_lines.append([l, Time.get_ticks_msec()])
	while _lines.size() > KEEP:
		(_lines.pop_front()[0] as Label).queue_free()


func _show_all() -> void:
	var now := Time.get_ticks_msec()
	for e in _lines:
		e[1] = maxi(int(e[1]), now - int(SHOW_SECONDS * 500.0))


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	for e in _lines:
		var age := (now - int(e[1])) / 1000.0
		var a := 1.0 if is_open() else clampf((SHOW_SECONDS - age) / 2.0, 0.0, 1.0)
		(e[0] as Label).modulate.a = a


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", 20)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(Palette.INK, 0.6)
	bg.content_margin_left = 8
	bg.content_margin_right = 8
	bg.content_margin_top = 2
	bg.content_margin_bottom = 2
	l.add_theme_stylebox_override("normal", bg)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
