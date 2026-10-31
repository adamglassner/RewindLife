class_name TvShow
extends Node2D
## What's on TV: a little animated picture (drawn into a SubViewport that's shown on the
## TV's screen), with the show's theme music. Every show and movie here is made up.
##
##   TvShow.pick(activity, clock, tape_title) -> {"show": id, "title": "...", "sound": "tv_..."}
##   TvShow.make_screen(tv) -> puts a picture panel over a TV's screen (main.gd does this)

const W := 160
const H := 120

## id -> [title, sound]
const SHOWS := {
	"cartoon": ["The Blooper Bunch", "tv_show"],
	"cartoon2": ["Captain Kaboom", "tv_show"],
	"gameshow": ["Spin 'n' Win!", "tv_gameshow"],
	"news": ["Channel 6 News", "tv_news"],
	"sitcom": ["Meet the Muldoons", "tv_sitcom"],
	"soap": ["Harbor Bay Hearts", "tv_soap"],
	"cops": ["Highway Heat", "tv_cops"],
	"music": ["Video Countdown", "tv_music"],
	"sports": ["Saturday Ballgame", "tv_sports"],
	"parade": ["The New Year's Parade", "tv_parade"],
	"m_action": ["", "tv_action"],
	"m_horror": ["", "tv_horror"],
	"m_scifi": ["", "tv_scifi"],
	"m_comedy": ["", "tv_comedy"],
}

## The movies at Rewind Video (content.gd MOVIES) and what kind of movie each one is.
const MOVIE_KIND := {
	"Laser Ninjas II": "m_action", "Mall Monster": "m_horror", "The Time Racer": "m_scifi", "Summer Camp Panic": "m_horror",
	"Robo Partner": "m_scifi", "Neon Knights": "m_action", "Grandma's Got a Jetpack": "m_comedy", "Planet of the Pets": "m_scifi",
	"Revenge of the Lunch Lady": "m_comedy", "Space Cadets 3": "m_scifi",
}
const LATE_MOVIES := [["Midnight at the Drive-In", "m_horror"], ["Robot Rebellion", "m_scifi"], ["Dragon Street", "m_action"],
	["My Uncle the Alien", "m_comedy"], ["The Swamp Thing That Ate Ohio", "m_horror"]]

var show := "cartoon"
var title := ""
var t := 0.0
var _rng := RandomNumberGenerator.new()


## What's on for this activity right now (TV channels change with the time of day).
static func pick(act: Activity, clock: GameClock, tape_title: String) -> Dictionary:
	var id := ""
	var ttl := ""
	if act.needs_item == "tape":
		id = String(MOVIE_KIND.get(tape_title, "m_comedy"))
		ttl = tape_title
	elif act.title.contains("Cartoons"):
		id = "cartoon" if clock.day() % 2 == 0 else "cartoon2"
	elif act.title.contains("Parade"):
		id = "parade"
	elif act.title.contains("Late Movie"):
		var lm: Array = LATE_MOVIES[clock.day() % LATE_MOVIES.size()]
		id = lm[1]
		ttl = lm[0]
	else:
		var h := clock.hour_float()
		var wd := clock.weekday()
		var slot := int(h * 2.0) + clock.day()       # (a different channel every half hour, and day to day)
		if h < 6.0:
			id = ["music", "m_horror", "news"][slot % 3]
		elif h < 9.0:
			id = ["news", "cartoon", "cartoon2"][slot % 3]
		elif h < 12.0:
			id = (["cartoon", "cartoon2", "gameshow"] if wd in [0, 6] else ["gameshow", "soap", "news"])[slot % 3]
		elif h < 15.0:
			id = (["sports", "gameshow", "music"] if wd in [0, 6] else ["soap", "gameshow", "soap"])[slot % 3]
		elif h < 18.0:
			id = ["cartoon", "cartoon2", "music", "gameshow"][slot % 4]
		elif h < 19.0:
			id = "news"
		elif h < 22.0:
			id = ["sitcom", "cops", "sitcom", "gameshow"][slot % 4]
		else:
			id = ["cops", "music", "news"][slot % 3]
	var def: Array = SHOWS[id]
	if ttl == "":
		ttl = def[0]
	return {"show": id, "title": ttl, "sound": def[1]}


## A picture panel over the TV's screen, showing a SubViewport. Returns [viewport, show, panel].
static func make_screen(tv: SmartObject, what: Dictionary) -> Array:
	var screen_mat: StandardMaterial3D = tv.get_meta("screen_mat")
	var screen: MeshInstance3D = null
	for n in tv.find_children("*", "MeshInstance3D", true, false):
		if (n as MeshInstance3D).material_override == screen_mat:
			screen = n
			break
	if screen == null or not (screen.mesh is BoxMesh):
		return []
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var sh := TvShow.new()
	sh.show = String(what["show"])
	sh.title = String(what["title"])
	vp.add_child(sh)
	tv.add_child(vp)
	var size: Vector3 = (screen.mesh as BoxMesh).size
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(size.x * 0.94, size.y * 0.92)
	q.mesh = qm
	q.position = Vector3(0, 0, size.z / 2.0 + 0.004)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = vp.get_texture()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	screen.add_child(q)
	return [vp, sh, q]


func _ready() -> void:
	_rng.seed = hash(show + title)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


# ---------------------------------------------------------------- drawing helpers

func _txt(s: String, pos: Vector2, size: int, color: Color, center := false) -> void:
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	# (long titles get smaller so they fit on the screen)
	var room := (W - 8.0) if center else (W - 4.0 - pos.x)
	while w > room and size > 6:
		size -= 1
		w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := pos - Vector2(w / 2.0, 0) if center else pos
	draw_string(f, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.6))
	draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _person(at: Vector2, scale: float, shirt: Color, hair: Color, skin := Color("E8B58C"), talk := 0.0) -> void:
	draw_rect(Rect2(at + Vector2(-9, -2) * scale, Vector2(18, 22) * scale), shirt)
	draw_circle(at + Vector2(0, -10) * scale, 8.0 * scale, skin)
	draw_rect(Rect2(at + Vector2(-8.5, -19) * scale, Vector2(17, 6) * scale), hair)
	draw_rect(Rect2(at + Vector2(-4, -12) * scale, Vector2(2, 2) * scale), Color.BLACK)
	draw_rect(Rect2(at + Vector2(2, -12) * scale, Vector2(2, 2) * scale), Color.BLACK)
	var mouth := 1.0 + absf(sin(talk)) * 2.5 if talk > 0.0 else 1.0
	draw_rect(Rect2(at + Vector2(-3, -6) * scale, Vector2(6, mouth) * scale), Color("7A2E2E"))


# ---------------------------------------------------------------- the shows

func _draw() -> void:
	match show:
		"cartoon":
			_cartoon(false)
		"cartoon2":
			_cartoon(true)
		"gameshow":
			_gameshow()
		"news":
			_news()
		"sitcom":
			_sitcom()
		"soap":
			_soap()
		"cops":
			_cops()
		"music":
			_music()
		"sports":
			_sports()
		"parade":
			_parade()
		"m_action":
			_action()
		"m_horror":
			_horror()
		"m_scifi":
			_scifi()
		_:
			_comedy()
	# the title card for the first few seconds
	if t < 3.2 and title != "":
		draw_rect(Rect2(0, H / 2.0 - 16, W, 30), Color(0, 0, 0, 0.65))
		_txt(title, Vector2(W / 2.0, H / 2.0 + 4), 14, Color("F7D046"), true)
	# CRT scanlines and a little roll
	for y in range(0, H, 3):
		draw_line(Vector2(0, y), Vector2(W, y), Color(0, 0, 0, 0.18))
	var roll := fmod(t * 18.0, float(H + 20)) - 10.0
	draw_rect(Rect2(0, roll, W, 6), Color(1, 1, 1, 0.05))


func _cartoon(captain: bool) -> void:
	draw_rect(Rect2(0, 0, W, H), Color("6EC8F2"))
	draw_circle(Vector2(132, 22), 12, Color("FFE14A"))
	# rolling green hills scrolling by
	var off := fmod(t * 30.0, 80.0)
	for k in range(-1, 4):
		draw_circle(Vector2(k * 80 - off + 40, 120), 52, Color("58B848"))
	draw_rect(Rect2(0, 96, W, 24), Color("4FA03E"))
	for k in range(-1, 6):
		var tx := k * 40 - fmod(t * 30.0, 40.0)
		draw_rect(Rect2(tx + 14, 70, 6, 26), Color("8A5A2B"))
		draw_circle(Vector2(tx + 17, 64), 13, Color("2F8A3A"))
	if not captain:
		# a round orange critter bouncing after a little blue bird
		var hop := absf(sin(t * 4.0)) * 26.0
		var cx := 50.0 + sin(t * 0.7) * 18.0
		draw_circle(Vector2(cx, 88 - hop), 14, Color("F28A2A"))
		draw_circle(Vector2(cx + 5, 84 - hop), 5, Color.WHITE)
		draw_circle(Vector2(cx + 6, 84 - hop), 2.4, Color.BLACK)
		draw_rect(Rect2(cx + 2, 92 - hop, 9, 2), Color("7A2E2E"))
		var bx := cx + 46 + sin(t * 3.0) * 8
		var by := 52 + sin(t * 6.0) * 6
		draw_circle(Vector2(bx, by), 7, Color("2E6AC8"))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 2, by - 1), Vector2(bx - 12, by - 8 + sin(t * 20) * 6), Vector2(bx - 6, by + 3)]), Color("4F8AE0"))
		draw_colored_polygon(PackedVector2Array([Vector2(bx + 6, by), Vector2(bx + 12, by + 2), Vector2(bx + 6, by + 3)]), Color("F7D046"))
		if fmod(t, 4.0) > 3.2:
			_txt("BOING!", Vector2(cx - 10, 50 - hop), 13, Color("E8385A"))
	else:
		# a little superhero flying across the sky, cape flapping
		var fx := fmod(t * 40.0, W + 60.0) - 30.0
		var fy := 40.0 + sin(t * 2.0) * 10.0
		draw_colored_polygon(PackedVector2Array([Vector2(fx - 6, fy - 4), Vector2(fx - 26, fy - 8 + sin(t * 12) * 5), Vector2(fx - 24, fy + 6), Vector2(fx - 6, fy + 4)]), Color("C0322A"))
		draw_rect(Rect2(fx - 8, fy - 5, 16, 10), Color("2E5E9E"))
		draw_circle(Vector2(fx + 11, fy), 6, Color("E8B58C"))
		draw_rect(Rect2(fx + 6, fy - 4, 10, 3), Color("2B2B30"))
		draw_rect(Rect2(fx - 2, fy - 3, 5, 5), Color("F7D046"))
		if fmod(t, 5.0) > 4.0:
			_txt("KA-BOOM!", Vector2(60, 28), 13, Color("F7D046"))


func _gameshow() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("3A1A6A"))
	for k in 16:
		var on := (int(t * 6.0) + k) % 2 == 0
		draw_circle(Vector2(k * 10 + 5, 4), 2.5, Color("FFE14A") if on else Color("8A6A20"))
		draw_circle(Vector2(k * 10 + 5, H - 4), 2.5, Color("FFE14A") if not on else Color("8A6A20"))
	# the big wheel
	var c := Vector2(54, 54)
	var spin := t * 3.0 * maxf(0.2, 1.0 - fmod(t, 8.0) / 8.0)
	var cols := [Color("E8385A"), Color("F7D046"), Color("2E8CE0"), Color("4FC04F"), Color("F28A2A"), Color("B04FE0")]
	for k in 12:
		var a0 := spin + k * TAU / 12.0
		var a1 := a0 + TAU / 12.0
		draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * 36, c + Vector2(cos((a0 + a1) / 2.0), sin((a0 + a1) / 2.0)) * 37, c + Vector2(cos(a1), sin(a1)) * 36]), cols[k % 6])
	draw_circle(c, 6, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([c + Vector2(36, -4), c + Vector2(44, 0), c + Vector2(36, 4)]), Color.WHITE)
	# three contestants at their podiums
	for k in 3:
		var px := 104 + k * 18
		_person(Vector2(px, 74), 0.6, [Color("E8385A"), Color("2E8CE0"), Color("4FC04F")][k], [Color("4A2A1A"), Color("D9B060"), Color("1F1716")][k])
		draw_rect(Rect2(px - 8, 84, 16, 22), Color("C8A040"))
		_txt("$" + str([450, 1200, 800][k] + ((int(t) % 5) * 50 if k == 1 else 0)), Vector2(px - 8, 96), 7, Color.WHITE)
	_txt("SPIN 'N' WIN!", Vector2(W / 2.0, H - 10), 11, Color("FFE14A"), true)


func _news() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("1E3A6A"))
	draw_rect(Rect2(0, 0, W, 60), Color("2E5A9A"))
	# the box over the anchor's shoulder: the weather, or a picture of the story
	draw_rect(Rect2(96, 14, 52, 38), Color("0F1F3A"))
	if fmod(t, 10.0) < 5.0:
		draw_circle(Vector2(114, 30), 9, Color("FFE14A"))
		draw_circle(Vector2(130, 36), 9, Color("E8E8E8"))
		draw_circle(Vector2(138, 34), 7, Color("E8E8E8"))
		_txt("78°", Vector2(100, 49), 9, Color.WHITE)
	else:
		draw_rect(Rect2(102, 26, 40, 20), Color("C0322A"))
		draw_rect(Rect2(110, 18, 24, 10), Color("8A3A2A"))
		_txt("TOWN NEWS", Vector2(98, 22), 7, Color.WHITE)
	_person(Vector2(50, 66), 1.4, Color("2B2B30"), Color("4A2A1A"), Color("E8B58C"), t * 9.0)
	draw_rect(Rect2(10, 82, 100, 20), Color("6A4A2A"))
	# the ticker along the bottom
	draw_rect(Rect2(0, 100, W, 14), Color("C0322A"))
	var news := "  MAPLE GROVE: Mall sale this weekend  *  School bake sale Friday  *  Rocket Burger: new shake flavor  *  Weather: sunny and warm  "
	var x := W - fmod(t * 30.0, 700.0)
	_txt(news, Vector2(x, 111), 9, Color.WHITE)
	_txt("6", Vector2(144, 12), 12, Color("F7D046"))


func _sitcom() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("E8D8B0"))
	for x in range(0, W, 12):
		draw_line(Vector2(x, 0), Vector2(x, 70), Color("D8C090"), 2.0)
	draw_rect(Rect2(0, 70, W, 50), Color("8A6A4A"))
	draw_rect(Rect2(20, 62, 120, 24), Color("6A8AB0"))        # the couch
	draw_rect(Rect2(20, 52, 120, 12), Color("5A7AA0"))
	draw_rect(Rect2(124, 24, 10, 30), Color("F2E8C8"))        # a lamp
	draw_rect(Rect2(118, 18, 22, 8), Color("F7D046"))
	var turn := int(t / 2.5) % 2
	_person(Vector2(56, 50), 1.0, Color("C0322A"), Color("4A2A1A"), Color("E8B58C"), t * 10.0 if turn == 0 else 0.0)
	_person(Vector2(96, 50), 1.0, Color("2E8C8A"), Color("D9B060"), Color("D49A6A"), t * 10.0 if turn == 1 else 0.0)
	if fmod(t, 7.0) > 5.5:
		_txt("(audience laughs)", Vector2(W / 2.0, 112), 9, Color.WHITE, true)


func _soap() -> void:
	var zoom := 1.6 + fmod(t, 8.0) * 0.12
	draw_rect(Rect2(0, 0, W, H), Color("6A2A4A"))
	draw_rect(Rect2(0, 0, W, H), Color(1, 0.6, 0.8, 0.15 + 0.1 * sin(t)))
	var who := int(t / 4.0) % 2
	_person(Vector2(W / 2.0, 92), zoom, Color("F2F0E6") if who == 0 else Color("2B2B30"), Color("1F1716") if who == 0 else Color("8A5A2B"),
		Color("E8B58C"), t * 4.0 if fmod(t, 4.0) < 2.5 else 0.0)
	if fmod(t, 4.0) > 3.0:
		draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.3))
		_txt("\"...You're not my sister!\"" if who == 0 else "\"I've always been your sister.\"", Vector2(W / 2.0, 112), 9, Color.WHITE, true)


func _cops() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("0E0E24"))
	for k in 30:
		draw_circle(Vector2(fmod(k * 37.0, W), fmod(k * 13.0, 40.0)), 0.8, Color.WHITE)
	# the road racing toward you
	draw_colored_polygon(PackedVector2Array([Vector2(70, 50), Vector2(90, 50), Vector2(150, H), Vector2(10, H)]), Color("2B2B30"))
	for k in 5:
		var d := fmod(t * 1.5 + k * 0.2, 1.0)
		var y := 50 + d * d * 70.0
		draw_rect(Rect2(79 - d * 2, y, 2 + d * 4, 2 + d * 8), Color("F7D046"))
	for k in 4:
		var d := fmod(t * 1.5 + k * 0.25, 1.0)
		var y := 50 + d * d * 70.0
		draw_rect(Rect2(70 - d * 70 - 4, y - 20 * d, 3, 22 * d), Color("8A8A8A"))
		draw_circle(Vector2(70 - d * 70 - 2, y - 20 * d), 2 + d * 2, Color("FFE8A0"))
	# the patrol car, light bar flashing red and blue
	var cx := 80 + sin(t * 1.3) * 12
	draw_rect(Rect2(cx - 22, 82, 44, 18), Color("F2F2EE"))
	draw_rect(Rect2(cx - 16, 72, 32, 12), Color("2B2B30"))
	var red := int(t * 8.0) % 2 == 0
	draw_rect(Rect2(cx - 12, 68, 12, 4), Color("FF2020") if red else Color("400000"))
	draw_rect(Rect2(cx, 68, 12, 4), Color("2050FF") if not red else Color("000040"))
	draw_rect(Rect2(0, 0, W, H), Color(1, 0, 0, 0.08) if red else Color(0, 0, 1, 0.08))


func _music() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("14082A"))
	var hue := fmod(t * 0.15, 1.0)
	for k in 8:
		var y := 70 + k * k * 1.0
		draw_line(Vector2(0, y), Vector2(W, y), Color.from_hsv(fmod(hue + 0.5, 1.0), 0.9, 1.0, 0.8), 1.0)
	for k in 9:
		draw_line(Vector2(80, 70), Vector2(k * 20 - 0, H), Color.from_hsv(fmod(hue + 0.5, 1.0), 0.9, 1.0, 0.8), 1.0)
	draw_circle(Vector2(80, 50), 30, Color.from_hsv(hue, 0.8, 1.0))
	for k in 6:
		var a := t * 1.2 + k * TAU / 6.0
		var p := Vector2(80 + cos(a) * 60, 40 + sin(a * 1.3) * 22)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -6), p + Vector2(6, 5), p + Vector2(-6, 5)]), Color.from_hsv(fmod(hue + k * 0.15, 1.0), 0.9, 1.0))
	# the singer (a silhouette with big hair), a mic stand
	var bop := sin(t * 8.0) * 2.0
	draw_circle(Vector2(80, 54 + bop), 9, Color.BLACK)
	draw_circle(Vector2(80, 50 + bop), 12, Color(0, 0, 0, 0.85))
	draw_rect(Rect2(72, 62 + bop, 16, 30), Color.BLACK)
	draw_line(Vector2(92, 100), Vector2(88, 62), Color("C8C8C8"), 1.5)
	_txt("#1 THIS WEEK", Vector2(6, 112), 8, Color("F7D046"))


func _sports() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("4F9A3A"))
	draw_rect(Rect2(0, 0, W, 26), Color("2B3A4A"))
	for k in 60:
		draw_rect(Rect2(fmod(k * 11.0, W), 8 + (k % 3) * 6, 3, 3), Color.from_hsv(fmod(k * 0.13, 1.0), 0.6, 0.9))
	# the infield diamond
	draw_colored_polygon(PackedVector2Array([Vector2(80, 50), Vector2(120, 80), Vector2(80, 110), Vector2(40, 80)]), Color("C89A5A"))
	for p in [Vector2(80, 52), Vector2(118, 80), Vector2(42, 80), Vector2(80, 106)]:
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color.WHITE)
	var c := fmod(t, 6.0)
	var ball := Vector2(80, 100).lerp(Vector2(30 + c * 20, 20), clampf(c / 4.0, 0, 1)) - Vector2(0, sin(clampf(c / 4.0, 0, 1) * PI) * 30)
	draw_circle(ball, 2, Color.WHITE)
	for p in [Vector2(80, 98), Vector2(80, 76), Vector2(112, 76), Vector2(48, 76), Vector2(100, 60)]:
		_person(p, 0.35, Color("F2F2EE"), Color("2E5E9E"))
	draw_rect(Rect2(4, 28, 60, 12), Color(0, 0, 0, 0.6))
	_txt("MAV 3  ·  OWL 2", Vector2(6, 37), 8, Color.WHITE)


func _parade() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("8AC8F2"))
	draw_rect(Rect2(0, 80, W, 40), Color("8A8A8A"))
	draw_rect(Rect2(0, 76, W, 4), Color("C8C8C8"))
	# the crowd on the far curb
	for k in 40:
		draw_circle(Vector2(k * 4 + 2, 74 + (k % 2)), 2.2, Color.from_hsv(fmod(k * 0.21, 1.0), 0.5, 0.9))
	# a giant balloon floating along
	var bx := fmod(t * 14.0, W + 80.0) - 40.0
	draw_circle(Vector2(bx, 34), 18, Color("E8385A"))
	draw_circle(Vector2(bx + 14, 22), 9, Color("E8385A"))
	draw_circle(Vector2(bx + 17, 20), 2, Color.WHITE)
	for k in 3:
		draw_line(Vector2(bx - 8 + k * 8, 52), Vector2(bx - 12 + k * 10, 90), Color.WHITE, 1.0)
	# a float, and the marching band
	var fx := fmod(t * 20.0 + 60.0, W + 100.0) - 50.0
	draw_rect(Rect2(fx - 30, 84, 60, 16), Color("4FC04F"))
	draw_circle(Vector2(fx, 80), 10, Color("F7D046"))
	for k in 6:
		var mx := fmod(t * 20.0 + k * 10.0, W + 40.0) - 20.0
		_person(Vector2(mx, 106 + sin(t * 8.0 + k) * 1.0), 0.35, Color("C0322A"), Color("2B2B30"))
	for k in 20:
		var cy := fmod(t * 25.0 + k * 17.0, float(H))
		draw_rect(Rect2(fmod(k * 29.0, W), cy, 2, 2), Color.from_hsv(fmod(k * 0.17, 1.0), 0.8, 1.0))


func _action() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("1A0A2A"))
	for k in 10:
		var bx := k * 17
		var bh := 30 + (k * 23) % 40
		draw_rect(Rect2(bx, H - 30 - bh, 15, bh), Color("2A1A4A"))
		for wy in range(int(H - 26 - bh), H - 34, 6):
			if (k + wy) % 3 == 0:
				draw_rect(Rect2(bx + 4, wy, 3, 2), Color("F7D046"))
	draw_rect(Rect2(0, H - 30, W, 30), Color("101018"))
	# two ninjas with laser swords
	var clash := sin(t * 5.0)
	var a := Vector2(60 + clash * 6, 76)
	var b := Vector2(100 - clash * 6, 76)
	for p in [a, b]:
		draw_rect(Rect2(p + Vector2(-5, -6), Vector2(10, 18)), Color("101010"))
		draw_circle(p + Vector2(0, -10), 5, Color("101010"))
		draw_rect(Rect2(p + Vector2(-4, -11), Vector2(8, 2)), Color("C0322A"))
	draw_line(a + Vector2(4, -2), Vector2(80, 50 + clash * 6), Color("40E0FF"), 2.0)
	draw_line(b + Vector2(-4, -2), Vector2(80, 50 - clash * 6), Color("FF40C0"), 2.0)
	if absf(clash) < 0.15:
		draw_circle(Vector2(80, 50), 8, Color(1, 1, 1, 0.8))


func _horror() -> void:
	var flash := fmod(t, 6.0) > 5.6
	draw_rect(Rect2(0, 0, W, H), Color("C8D0FF") if flash else Color("0A0A14"))
	draw_circle(Vector2(124, 26), 14, Color("E8E8C8"))
	for k in 8:
		var tx := k * 22 + 6
		draw_colored_polygon(PackedVector2Array([Vector2(tx, H), Vector2(tx + 10, 40 + (k * 7) % 20), Vector2(tx + 20, H)]), Color("05050A"))
	# eyes in the dark, blinking
	if fmod(t, 3.0) < 2.6:
		var ex := 60 + sin(t * 0.5) * 30
		draw_circle(Vector2(ex, 80), 3, Color("FF3020"))
		draw_circle(Vector2(ex + 10, 80), 3, Color("FF3020"))
	draw_rect(Rect2(0, 100, W, 20), Color("08080C"))


func _scifi() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("02020A"))
	for k in 50:
		var d := fmod(t * 0.6 + k * 0.137, 1.0)
		var dir := Vector2(cos(k * 2.4), sin(k * 2.4))
		var p := Vector2(80, 60) + dir * d * d * 120.0
		draw_line(p, p + dir * d * 6.0, Color(1, 1, 1, d), 1.0)
	draw_circle(Vector2(30, 90), 22, Color("4A6AC8"))
	draw_circle(Vector2(24, 84), 20, Color("6A8AE0"))
	var sx := 90 + sin(t * 0.9) * 30
	var sy := 50 + sin(t * 1.4) * 12
	draw_colored_polygon(PackedVector2Array([Vector2(sx + 16, sy), Vector2(sx - 12, sy - 9), Vector2(sx - 6, sy), Vector2(sx - 12, sy + 9)]), Color("C8C8D0"))
	draw_circle(Vector2(sx - 10, sy), 2.5 + randf() * 1.5, Color("FF8A2A"))
	if fmod(t, 2.0) < 0.3:
		draw_line(Vector2(sx + 16, sy), Vector2(W, sy - 6), Color("40FF60"), 2.0)


func _comedy() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("8AD0FF"))
	for k in 4:
		var cx := fmod(k * 50.0 - t * 10.0, W + 40.0) - 20.0
		draw_circle(Vector2(cx, 20 + k * 6), 9, Color.WHITE)
		draw_circle(Vector2(cx + 10, 22 + k * 6), 7, Color.WHITE)
	draw_rect(Rect2(0, 100, W, 20), Color("4FA03E"))
	# Grandma, zooming around on a jetpack
	var gx := 80 + sin(t * 1.1) * 50
	var gy := 56 + sin(t * 2.3) * 18
	draw_rect(Rect2(gx - 8, gy - 2, 16, 18), Color("B04FE0"))
	draw_circle(Vector2(gx, gy - 8), 7, Color("E8B58C"))
	draw_circle(Vector2(gx, gy - 13), 6, Color("E8E8E8"))
	draw_circle(Vector2(gx - 3, gy - 8), 2, Color("6A6A6A"))
	draw_circle(Vector2(gx + 3, gy - 8), 2, Color("6A6A6A"))
	draw_rect(Rect2(gx - 12, gy, 4, 12), Color("8A8A8A"))
	for k in 3:
		draw_circle(Vector2(gx - 10, gy + 15 + k * 4 + randf() * 2), 3 - k * 0.6, [Color("FFE14A"), Color("F28A2A"), Color("E8385A")][k])
	if fmod(t, 5.0) > 4.0:
		_txt("WHEEEE!", Vector2(gx + 10, gy - 16), 11, Color("E8385A"))
