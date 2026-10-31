class_name Looks
extends RefCounted
## How people look: hair (80s and 90s styles), outfits, skin and hair colors,
## and the blocky body every character and townsperson is built from.
##
## A "look" is a small Dictionary, saved with the game:
##   {"gender": "boy"/"girl", "hair": "mullet", "hair_color": 2, "skin": 1, "outfit": 0}
## Townspeople can also pass colors directly: "top", "stripe", "pants", "shoes",
## "hair_rgb", "skin_rgb", and "adult": true (a bit taller).

const K := 0.0105   # body-part units from the mockups -> meters

const HAIR_STYLES := [
	# [key, name, era]
	["mullet", "Mullet", "80s"], ["perm", "Big Perm", "80s"], ["feathered", "Feathered", "80s"],
	["side_pony", "Side Ponytail", "80s"], ["high_top", "High-Top Fade", "80s"], ["teased", "Teased & Sprayed", "80s"],
	["curtains", "Curtains", "90s"], ["bowl", "Bowl Cut", "90s"], ["spiky", "Frosted Spikes", "90s"],
	["layered", "Layered & Long", "90s"], ["scrunchie", "Scrunchie Ponytail", "90s"], ["buzz", "Buzz Cut", "90s"],
	["mohawk", "Mohawk", "80s"], ["emo", "Swoopy Fringe", "90s"],
]

const OUTFITS := [
	# name, era, top, accent, pants, shoes, style
	{"name": "Neon Windbreaker", "era": "80s", "top": Color("2E8C8A"), "accent": Color("F2509A"), "accent2": Color("F7D046"),
		"pants": Color("8FB3D6"), "shoes": Color("F2F0E6"), "style": "windbreaker"},
	{"name": "Acid-Wash Jacket", "era": "80s", "top": Color("9DBCD9"), "accent": Color("F2F0E6"), "accent2": Color("E4704F"),
		"pants": Color("2B2B30"), "shoes": Color("C2412F"), "style": "jacket"},
	{"name": "Track Suit", "era": "80s", "top": Color("C2412F"), "accent": Color("F2F0E6"), "accent2": Color("F2F0E6"),
		"pants": Color("C2412F"), "shoes": Color("F2F0E6"), "style": "track"},
	{"name": "Grunge Flannel", "era": "90s", "top": Color("A8322A"), "accent": Color("1F1A1A"), "accent2": Color("3A2020"),
		"pants": Color("3E5C8A"), "shoes": Color("5A3A22"), "style": "flannel"},
	{"name": "Overalls & Stripes", "era": "90s", "top": Color("F7D046"), "accent": Color("4A6FA5"), "accent2": Color("F2F0E6"),
		"pants": Color("4A6FA5"), "shoes": Color("F2F0E6"), "style": "overalls"},
	{"name": "Color Block & Baggy Jeans", "era": "90s", "top": Color("7A4FB0"), "accent": Color("2EB8A8"), "accent2": Color("F7D046"),
		"pants": Color("5A7AB0"), "shoes": Color("1F1A1A"), "style": "colorblock"},
	# ---- sold at Trend Setters in the mall (Catalog.OUTFIT_PRICES)
	{"name": "Members' Club Jacket", "era": "80s", "top": Color("C8A878"), "accent": Color("F2F0E6"), "accent2": Color("8A6A4A"),
		"pants": Color("2B2B30"), "shoes": Color("5A3A22"), "style": "jacket"},
	{"name": "Preppy Polo & Sweater", "era": "80s", "top": Color("F29AB5"), "accent": Color("2E4A7A"), "accent2": Color("F2F0E6"),
		"pants": Color("C8B48A"), "shoes": Color("6A4A2A"), "style": "polo"},
	{"name": "Leather & Studs", "era": "80s", "top": Color("1E1C22"), "accent": Color("C8CCD0"), "accent2": Color("C0322A"),
		"pants": Color("2B2B30"), "shoes": Color("141414"), "style": "leather"},
	{"name": "Varsity Jacket", "era": "80s", "top": Color("A8322A"), "accent": Color("F2F0E6"), "accent2": Color("F7D046"),
		"pants": Color("3E5C8A"), "shoes": Color("F2F0E6"), "style": "varsity"},
	{"name": "Hawaiian Shirt", "era": "80s", "top": Color("2EB8A8"), "accent": Color("F2509A"), "accent2": Color("F7D046"),
		"pants": Color("C8B48A"), "shoes": Color("F2F0E6"), "style": "hawaiian"},
	{"name": "Hypercolor Tee", "era": "90s", "top": Color("FF4FD8"), "accent": Color("4FC8FF"), "accent2": Color("7A4FB0"),
		"pants": Color("3E5C8A"), "shoes": Color("F2F0E6"), "style": "hyper"},
	{"name": "Striped Hoodie", "era": "90s", "top": Color("1F1A1E"), "accent": Color("8A2A4A"), "accent2": Color("2A2228"),
		"pants": Color("26262C"), "shoes": Color("1A1A1A"), "style": "hoodie"},
	{"name": "Velvet Long Coat", "era": "90s", "top": Color("2A1A2E"), "accent": Color("5A1A2A"), "accent2": Color("C8CCD0"),
		"pants": Color("18161C"), "shoes": Color("101010"), "style": "coat"},
	{"name": "Denim on Denim", "era": "90s", "top": Color("4A6FA5"), "accent": Color("9DBCD9"), "accent2": Color("F2F0E6"),
		"pants": Color("4A6FA5"), "shoes": Color("F2F0E6"), "style": "jacket"},
	{"name": "Sweater Vest & Tie", "era": "80s", "top": Color("F2F0E6"), "accent": Color("2E6B3A"), "accent2": Color("A8322A"),
		"pants": Color("5A4A3A"), "shoes": Color("3A2A1A"), "style": "vest"},
	{"name": "Aerobics & Leg Warmers", "era": "80s", "top": Color("F2509A"), "accent": Color("7A4FB0"), "accent2": Color("4FD8C8"),
		"pants": Color("7A4FB0"), "shoes": Color("F2F0E6"), "style": "aerobics"},
	# ---- Halloween costumes (from the dresser on Halloween)
	{"name": "Ghost Costume", "era": "80s", "top": Color("F2F0E6"), "accent": Color("141414"), "accent2": Color("F2F0E6"),
		"pants": Color("F2F0E6"), "shoes": Color("F2F0E6"), "style": "ghost"},
	{"name": "Vampire Costume", "era": "80s", "top": Color("1A1A1E"), "accent": Color("A8202A"), "accent2": Color("F2F0E6"),
		"pants": Color("1A1A1E"), "shoes": Color("101010"), "style": "vampire"},
]

const HAIR_COLORS := [Color("1F1716"), Color("4A2A1A"), Color("8A5A2B"), Color("9A3A1E"), Color("D9B060"), Color("EDE0B0")]
const HAIR_COLOR_NAMES := ["Black", "Dark Brown", "Brown", "Auburn", "Blonde", "Platinum"]
const SKIN_TONES := [Color("F5D2B3"), Color("E8B58C"), Color("D49A6A"), Color("B87A4B"), Color("8A5530"), Color("5E3A22")]


static func hair_index(key: String) -> int:
	for i in HAIR_STYLES.size():
		if HAIR_STYLES[i][0] == key:
			return i
	return 0


static func normalized(look: Dictionary) -> Dictionary:
	var l := {"gender": "boy", "hair": "mullet", "hair_color": 1, "skin": 1, "outfit": 0}
	l.merge(look, true)
	return l


## Build a body under `parent` (facing -z, feet at y = 0). Returns the leg and
## arm pivots, for walking and poses: {"legs": [l, r], "arms": [l, r]}.
static func build(parent: Node3D, look_in: Dictionary) -> Dictionary:
	var look := normalized(look_in)
	var o: Dictionary = OUTFITS[clampi(int(look["outfit"]), 0, OUTFITS.size() - 1)]
	var top: Color = look.get("top", o["top"])
	var accent: Color = look.get("stripe", o["accent"])
	var accent2: Color = o["accent2"]
	var pants: Color = look.get("pants", o["pants"])
	var shoes: Color = look.get("shoes", o["shoes"])
	var style: String = look.get("top_style", o["style"])
	var skin: Color = look.get("skin_rgb", SKIN_TONES[clampi(int(look["skin"]), 0, SKIN_TONES.size() - 1)])
	var hair: Color = look.get("hair_rgb", HAIR_COLORS[clampi(int(look["hair_color"]), 0, HAIR_COLORS.size() - 1)])
	var girl: bool = look["gender"] == "girl"
	var body := Node3D.new()
	body.name = "Body"
	if look.get("adult", false):
		body.scale = Vector3(1.08, 1.16, 1.08)
	parent.add_child(body)
	var legs: Array[Node3D] = []
	var arms: Array[Node3D] = []
	var tw := 38.5 if girl else 48.0          # torso width (boys a bit broader in the shoulders)
	var leg_w := 15.0 if style == "colorblock" else 14.0
	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(side * 9, 54, 0) * K
		body.add_child(hip)
		_p(hip, Vector3(leg_w, 46, 18), Vector3(0, -23, 0), pants)
		if style == "track":
			_p(hip, Vector3(2, 44, 18.4), Vector3(side * leg_w / 2.0, -23, 0), accent)
		if style == "aerobics":
			_p(hip, Vector3(leg_w + 1.2, 16, 19.2), Vector3(0, -36, 0), accent2)               # leg warmers
		if (style == "flannel" or style == "leather") and side > 0:
			_p(hip, Vector3(10, 4, 18.6), Vector3(0, -30, 0), skin.lerp(Color.WHITE, 0.3))   # ripped knee
		_p(hip, Vector3(16, 8, 24), Vector3(0, -50, -2), shoes)
		legs.append(hip)
		var shoulder := Node3D.new()
		shoulder.position = Vector3(side * (tw / 2.0 + 6), 100, 0) * K
		body.add_child(shoulder)
		var sleeve := top
		match style:
			"windbreaker":
				sleeve = accent if side < 0 else top
			"overalls":
				sleeve = skin
			"colorblock":
				sleeve = accent if side > 0 else accent2
			"varsity":
				sleeve = accent
		var short_sleeves: bool = style in ["overalls", "hawaiian", "polo", "aerobics", "hyper"]
		var sleeve_len := 20.0 if short_sleeves else 44.0
		_p(shoulder, Vector3(12, sleeve_len, 18), Vector3(0, -sleeve_len / 2.0, 0), sleeve)
		if style == "overalls":
			_p(shoulder, Vector3(12.4, 6, 18.4), Vector3(0, -4, 0), accent2)        # striped tee sleeve
			_p(shoulder, Vector3(11.4, 24, 17.4), Vector3(0, -32, 0), skin)
		elif short_sleeves:
			_p(shoulder, Vector3(11.4, 24, 17.4), Vector3(0, -32, 0), skin)
		if style == "track":
			_p(shoulder, Vector3(12.4, 40, 2), Vector3(0, -21, 9.2), accent)
		if style == "leather":
			_p(shoulder, Vector3(4, 4, 4), Vector3(0, -2, -7), accent)                        # studs
			_p(shoulder, Vector3(4, 4, 4), Vector3(0, -2, 5), accent)
		if style == "varsity":
			_p(shoulder, Vector3(12.6, 4, 18.6), Vector3(0, -40, 0), top)                     # cuff stripe
		_p(shoulder, Vector3(11.4, 10, 17.4), Vector3(0, -48, 0), skin)   # (a hair narrower than the sleeve: no shared faces)
		arms.append(shoulder)
	# Torso, by outfit
	_p(body, Vector3(tw, 50, 26), Vector3(0, 79, 0), top)
	match style:
		"windbreaker":
			_p(body, Vector3(tw + 1, 10, 27), Vector3(0, 86, 0), accent)
			_p(body, Vector3(tw + 1, 5, 27), Vector3(0, 78, 0), accent2)
		"jacket":
			_p(body, Vector3(12, 46, 1), Vector3(0, 80, -13.3), accent)            # the tee, under the open jacket
			_p(body, Vector3(tw + 1, 6, 27), Vector3(0, 102, 0), top.lightened(0.15))   # collar
		"track":
			_p(body, Vector3(tw + 1, 6, 27), Vector3(0, 92, 0), accent)
			_p(body, Vector3(2, 46, 1), Vector3(0, 79, -13.3), accent)            # zipper
		"flannel":
			_p(body, Vector3(16, 46, 1), Vector3(0, 79, -13.3), accent)            # band tee
			for y in [64, 76, 88, 100]:
				_p(body, Vector3(tw + 0.6, 2, 26.6), Vector3(0, y, 0), accent2)    # plaid lines
		"overalls":
			for y in [62, 72, 82, 92, 102]:
				_p(body, Vector3(tw + 0.4, 4, 26.4), Vector3(0, y, 0), accent2)    # striped tee
			_p(body, Vector3(tw - 10, 26, 27), Vector3(0, 67, 0), accent)          # bib
			_p(body, Vector3(5, 26, 27), Vector3(-12, 93.5, 0), accent)            # one strap up...
			_p(body, Vector3(5, 14, 27.2), Vector3(12, 74, 0), accent)             # ...one strap down
		"colorblock":
			_p(body, Vector3(tw + 0.6, 16, 26.6), Vector3(0, 96, 0), accent)
			_p(body, Vector3(tw * 0.5, 14, 26.8), Vector3(tw * 0.25, 70, 0), accent2)
		"polo":
			_p(body, Vector3(tw * 0.55, 6, 27), Vector3(0, 101.6, 0), accent2)                 # the popped collar
			_p(body, Vector3(tw + 3, 7, 28.4), Vector3(0, 97, 0.3), accent)                    # a sweater tied on the shoulders
			_p(body, Vector3(9, 14, 2.4), Vector3(-4, 88, -14.6), accent)                      # ...knotted in front
		"leather":
			_p(body, Vector3(13, 46, 1), Vector3(0, 80, -13.3), accent2)                       # the tee under the jacket
			_p(body, Vector3(tw + 1, 6, 27), Vector3(0, 102, 0), top.lightened(0.1))           # collar
			for i in 4:
				_p(body, Vector3(3, 3, 1.4), Vector3([-16, -9, 9, 16][i], 94, -13.6), accent)        # studs
		"varsity":
			_p(body, Vector3(9, 11, 1.2), Vector3(-10, 88, -13.5), accent2)                    # the big letter
			_p(body, Vector3(tw + 1, 5, 27), Vector3(0, 102, 0), accent)                       # collar ribbing
		"hawaiian":
			var spots := [[-12, 92], [6, 96], [12, 80], [-4, 72], [-14, 66], [10, 64], [-2, 86]]
			for k in spots.size():
				_p(body, Vector3(6, 6, 1.2), Vector3(spots[k][0], spots[k][1], -13.5), accent if k % 2 == 0 else accent2)
		"hyper":
			_p(body, Vector3(tw + 0.6, 20, 26.6), Vector3(0, 64, 0), accent)                  # the color change
			_p(body, Vector3(tw + 0.4, 6, 26.4), Vector3(0, 77.5, 0), accent.lerp(top, 0.5))
		"hoodie":
			for y in [66, 80, 94]:
				_p(body, Vector3(tw + 0.6, 4, 26.6), Vector3(0, y, 0), accent)               # stripes
			_p(body, Vector3(28, 12, 8), Vector3(0, 106, 14), accent2)                         # the hood, down
			_p(body, Vector3(20, 9, 1.4), Vector3(0, 66, -13.5), accent2)                      # pocket
		"coat":
			_p(body, Vector3(tw + 2.4, 26, 28.4), Vector3(0, 48, 0), top)                     # the long skirt of the coat
			_p(body, Vector3(tw + 1, 6, 27), Vector3(0, 102, 0), accent)                      # collar
			for y in [92, 82, 72]:
				_p(body, Vector3(3, 3, 1.4), Vector3(4, y, -13.6), accent2)                  # buttons
		"vest":
			_p(body, Vector3(tw + 0.6, 36, 26.6), Vector3(0, 72, 0), accent)                  # the vest
			_p(body, Vector3(5, 28, 1.6), Vector3(0, 88, -13.7), accent2)                     # the tie
		"aerobics":
			_p(body, Vector3(tw + 0.6, 5, 26.6), Vector3(0, 62, 0), accent)                   # a belt
		"ghost":
			_p(body, Vector3(tw + 8, 74, 32), Vector3(0, 72, 0), top)                         # the sheet
			_p(body, Vector3(38, 40, 30), Vector3(0, 126, 0), top)                            # over the head
			for sx in [-1.0, 1.0]:
				_p(body, Vector3(6, 8, 1), Vector3(sx * 7.5, 127, -15.4), accent)               # eye holes
		"vampire":
			_p(body, Vector3(tw + 10, 76, 3), Vector3(0, 68, 15.0), accent)                   # the cape (red inside)
			_p(body, Vector3(tw + 10.4, 76.4, 1), Vector3(0, 68, 16.9), top)                  # (black outside)
			_p(body, Vector3(tw + 6, 14, 6), Vector3(0, 106, 12), accent)                     # the tall collar
			_p(body, Vector3(10, 30, 1), Vector3(0, 84, -13.4), accent2)                      # shirt front
	if style != "overalls":
		_p(body, Vector3(tw + 2, 6, 28), Vector3(0, 56, 0), pants.darkened(0.2))   # waistband
	# Head and face
	_p(body, Vector3(12, 4, 12), Vector3(0, 106, 0), skin)
	_p(body, Vector3(30, 32, 24), Vector3(0, 124, 0), skin)
	_p(body, Vector3(5, 5, 1), Vector3(-7.5, 124.5, -12.5), Palette.INK)
	_p(body, Vector3(5, 5, 1), Vector3(7.5, 124.5, -12.5), Palette.INK)
	if girl:
		# lashes, pink lips, rosy cheeks and little gold earrings
		_p(body, Vector3(10, 2.5, 1), Vector3(0, 114, -12.5), Color("D2505F"))
		for sx in [-1.0, 1.0]:
			_p(body, Vector3(2.5, 3, 1), Vector3(sx * 10.8, 127.5, -12.6), Palette.INK)
			_p(body, Vector3(5, 3, 0.6), Vector3(sx * 10.0, 118.5, -12.3), Color("F29AA0"))
			_p(body, Vector3(2, 3, 2), Vector3(sx * 15.6, 116, 1), Palette.GOLD)
	else:
		# eyebrows, and a plain mouth
		_p(body, Vector3(10, 2, 1), Vector3(0, 114, -12.5), Palette.RUST)
		for sx in [-1.0, 1.0]:
			_p(body, Vector3(7, 2, 1), Vector3(sx * 7.5, 130.5, -12.6), hair.darkened(0.25))
	if style != "ghost":
		_hair(body, String(look["hair"]), hair)
	if style == "vampire":
		for sx in [-1.0, 1.0]:
			_p(body, Vector3(2, 3, 1), Vector3(sx * 2.5, 112, -13.2), Palette.PAPER)         # fangs
	return {"legs": legs, "arms": arms, "body": body}


static func _p(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size * K
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos * K
	parent.add_child(mi)
	return mi


## Hair, built around a head whose top is at y = 140 and front at z = -12.
static func _hair(b: Node3D, style: String, c: Color) -> void:
	match style:
		"mullet":   # business in the front, party in the back
			_p(b, Vector3(34, 14, 28), Vector3(0, 139, 0), c)
			_p(b, Vector3(34, 44, 10), Vector3(0, 118, 9), c)
			_p(b, Vector3(3, 22, 16), Vector3(-15.5, 129, 4), c)
			_p(b, Vector3(3, 22, 16), Vector3(15.5, 129, 4), c)
		"perm":     # big and curly
			_p(b, Vector3(44, 22, 36), Vector3(0, 140, 2), c)
			_p(b, Vector3(46, 34, 14), Vector3(0, 122, 10), c)
			for side in [-1.0, 1.0]:
				_p(b, Vector3(8, 32, 26), Vector3(side * 19, 124, 3), c)
				_p(b, Vector3(6, 8, 8), Vector3(side * 21, 112, -6), c)
		"feathered":
			_p(b, Vector3(36, 12, 28), Vector3(0, 141, 1), c)
			for side in [-1.0, 1.0]:
				_p(b, Vector3(5, 30, 22), Vector3(side * 16.5, 126, 2), c)
				_p(b, Vector3(8, 10, 6), Vector3(side * 13, 135, -12), c)   # feathered wings back from the face
			_p(b, Vector3(34, 28, 8), Vector3(0, 121, 10), c)
		"side_pony":
			_p(b, Vector3(34, 13, 28), Vector3(0, 139, 0), c)
			_p(b, Vector3(34, 22, 8), Vector3(0, 129, 10), c)
			_p(b, Vector3(10, 10, 10), Vector3(17, 136, 4), Palette.ROSE)            # scrunchie
			_p(b, Vector3(10, 34, 10), Vector3(21, 117, 4), c)
		"high_top":
			_p(b, Vector3(30, 26, 24), Vector3(0, 153, 1), c)
			_p(b, Vector3(32, 6, 25.4), Vector3(0, 137, 1), c)
			_p(b, Vector3(31, 14, 4), Vector3(0, 127, 11), c)
		"teased":
			_p(b, Vector3(40, 18, 32), Vector3(0, 146, 1), c)
			_p(b, Vector3(38, 20, 6), Vector3(0, 140, -12), c)                        # big bangs
			_p(b, Vector3(40, 40, 12), Vector3(0, 120, 9), c)
			for side in [-1.0, 1.0]:
				_p(b, Vector3(6, 36, 24), Vector3(side * 18.5, 122, 2), c)
		"curtains": # parted down the middle
			for side in [-1.0, 1.0]:
				_p(b, Vector3(16, 12, 28), Vector3(side * 8.5, 140, 0), c)
				_p(b, Vector3(10, 16, 4), Vector3(side * 9.8, 131, -12.5), c)
				_p(b, Vector3(3, 20, 18), Vector3(side * 15.5, 128, 3), c)
			_p(b, Vector3(32, 22, 6), Vector3(0, 126, 10), c)
		"bowl":
			_p(b, Vector3(35, 15, 29), Vector3(0, 138, 0), c)
			_p(b, Vector3(35, 8, 29), Vector3(0, 131, 0.5), c)
			_p(b, Vector3(3, 14, 22), Vector3(-16, 126, 2), c)
			_p(b, Vector3(3, 14, 22), Vector3(16, 126, 2), c)
		"spiky":    # gelled up, frosted tips
			_p(b, Vector3(32, 8, 26), Vector3(0, 141, 0), c)
			var tip := c.lerp(Color("F2E6B0"), 0.7)
			for i in 5:
				_p(b, Vector3(6, 9, 6), Vector3(-12 + i * 6, 148, -6 + (i % 2) * 8), tip)
			_p(b, Vector3(31, 16, 4), Vector3(0, 130, 11), c)
		"layered":  # long and layered, past the shoulders
			_p(b, Vector3(36, 12, 30), Vector3(0, 140, 0), c)
			_p(b, Vector3(36, 52, 10), Vector3(0, 114, 10), c)
			for side in [-1.0, 1.0]:
				_p(b, Vector3(5, 44, 20), Vector3(side * 17, 118, 3), c)
				_p(b, Vector3(7, 14, 5), Vector3(side * 12, 130, -12), c)
		"scrunchie":
			_p(b, Vector3(34, 13, 28), Vector3(0, 140, 0), c)
			_p(b, Vector3(34, 18, 6), Vector3(0, 131, 11), c)
			_p(b, Vector3(12, 8, 12), Vector3(0, 147, 10), Palette.TEAL)             # scrunchie up top
			_p(b, Vector3(10, 26, 10), Vector3(0, 136, 17), c)
		"bun":      # (the librarian's)
			_p(b, Vector3(34, 12, 28), Vector3(0, 140, 0), c)
			_p(b, Vector3(32, 18, 6), Vector3(0, 130, 10), c)
			_p(b, Vector3(14, 14, 14), Vector3(0, 142, 15), c)
		"cap":      # a red ball cap (the pizza cook)
			_p(b, Vector3(34, 10, 26), Vector3(0, 136, 1.5), c)
			_p(b, Vector3(36, 9, 30), Vector3(0, 145, 0), Color("C0322A"))
			_p(b, Vector3(30, 3, 14), Vector3(0, 141.5, -20), Color("C0322A"))
		"buzz":
			_p(b, Vector3(31, 4, 25), Vector3(0, 141, 0), c)
			_p(b, Vector3(31, 12, 2), Vector3(0, 134, 12), c)
		"mohawk":   # shaved sides, a tall crest down the middle
			_p(b, Vector3(31, 3, 25), Vector3(0, 140.5, 0), c.darkened(0.45))
			_p(b, Vector3(7, 18, 31), Vector3(0, 148, 0.5), c)
			_p(b, Vector3(6, 8, 6), Vector3(0, 145, 16), c)
		"emo":      # a long sideways fringe over one eye
			_p(b, Vector3(34, 12, 28), Vector3(0, 140, 0), c)
			_p(b, Vector3(20, 16, 3.4), Vector3(-5, 129, -14.2), c)
			_p(b, Vector3(34, 26, 8), Vector3(0, 124, 10), c)
			for side in [-1.0, 1.0]:
				_p(b, Vector3(3, 22, 18), Vector3(side * 15.3, 127, 3), c)
		_:
			_p(b, Vector3(34, 12, 28), Vector3(0, 140, 0), c)
