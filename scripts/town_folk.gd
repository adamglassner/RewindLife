class_name TownFolk
extends RefCounted
## Everyone in Maple Grove who isn't a player: every family's mom and dad (and
## the kids in the houses nobody plays), folks out for a walk, the shopkeepers,
## the people at City Hall, the school and the fire station, the family pets,
## and (once in a blue moon) a burglar. They're added to room["objects"] with
## the same keys on every computer, so online players can talk to them too.
##
## Parents keep a daily routine: breakfast, errands downtown, the mail, chatting
## on the sidewalk, Dad off to work on the bus on weekdays, the yard on weekends,
## and bed at night. Shopkeepers walk in from the edge of town before opening
## and walk home after closing (TownLife and main.gd do the rest).

const PARENT_LINES := [
	"Did you clean your room like I asked?",
	"Back before dark, okay? And don't talk to strangers.",
	"When I was your age, we didn't HAVE video games. We had a stick. And we LIKED it.",
	"Your Aunt Carol called. She says hi.",
	"Don't forget to say thank you to the Hendersons for the casserole.",
	"Turn that music down! ...Actually, is that Hall & Oates? Turn it up.",
	"Shoes off on the carpet, please!",
	"Are you hungry? There's tuna casserole in the fridge.",
	"Have you seen the remote? It was RIGHT here.",
	"Money doesn't grow on trees, you know.",
	"The trash won't take itself out. Hint, hint.",
]

const KID_LINES := [
	"Wanna trade baseball cards? I've got a Mattingly!",
	"My mom says I can't have Nintendo till Christmas. CHRISTMAS!",
	"Race you to the end of the block!",
	"Did you see the burglar story in the Gazette? Creepy!",
	"I'm gonna be a BMX champion. Watch me pop a wheelie. ...Okay, later.",
]

const WALKER_LINES := [
	["Mrs. Albright", ["Lovely day for a stroll!", "My Petunias are winning a ribbon this year, mark my words.", "You kids be careful crossing the street."]],
	["Mrs. Lopez", ["I'm the crossing guard at the school. Look both ways!", "My grandson just got a Walkman. I don't get it.", "The grocery store has Cheerios on sale. Tell your mother."]],
	["Dale the Mailman", ["Nothing for you today. Sorry, kiddo.", "A dog chased me three blocks this morning. Three!", "Postcard from Florida for the Kowalskis. Don't tell 'em I read it."]],
	["Brenda", ["Like, totally tubular day, right?", "When's the mall gonna open? I NEED an Orange Julius.", "Have you heard the new Madonna song? It's SO good."]],
	["Mr. Ortega", ["Going to get the paper. Then going to complain about the paper.", "This neighborhood sure is quiet in the summer.", "I used to have a car like that station wagon. Wood paneling and everything!"]],
	["Gina from the Salon", ["Your hair's got great volume, hon. Think about a perm.", "Aqua Net. The answer is always more Aqua Net.", "Tell your mom her appointment's Thursday!"]],
	["Officer Dwyer", ["Keep it under 25 on Maple, okay?", "Saw a raccoon in the Parkers' trash cans again.", "You kids stay out of trouble. And lock your doors at night!"]],
	["Skater Rick", ["Totally radical day, dude.", "I just landed a kickflip. Probably.", "Somebody beat my Dragon Tower score. I'm in mourning."]],
	["Grandma Rose", ["You look just like your father did at your age.", "Want a butterscotch? I always have butterscotch.", "In my day, a movie cost a nickel!"]],
	["Mr. Delgado the Milkman", ["Fresh milk! Well, it was fresh this morning.", "Two quarts on every porch, rain or shine.", "Same milk route since 1962, kid. Same truck, too."]],
	["Jenny Sparks", ["Are you going to the drive-in tonight? It's a monster movie!", "I'm saving up for a Walkman.", "Wanna trade stickers? I've got scratch-n-sniffs."]],
	["Tommy Two-Shoes", ["Race you to the corner!", "My brother says the Hendersons' attic is haunted.", "I've got a whole pack of Bazooka. Want a piece?"]],
]

## [home, name, "dog"/"cat", fur, accent]
const PETS := [
	["jamie", "Biscuit", "dog", Color("C8924A"), Color("F2E2C0")],
	["hendersons", "Whiskers", "cat", Color("7A7A80"), Color("E8E4DA")],
	["garcias", "Bandit", "dog", Color("2B2420"), Color("F2F0E6")],
	["nguyens", "Mittens", "cat", Color("E8A050"), Color("F2F0E6")],
	["parkers", "Duke", "dog", Color("8A6A4A"), Color("3A2A22")],
	["obriens", "Rusty", "dog", Color("A8502A"), Color("C8783A")],
	["brooks", "Pepper", "cat", Color("2B2B30"), Color("8A8A90")],
	["town", "Sparky", "dog", Color("F2F0E6"), Color("1A1A1A")],      # the firehouse Dalmatian
]

const PET_LINES := {
	"dog": ["Woof!", "*wags tail*", "Arf! Arf!", "*rolls over for a belly rub*"],
	"cat": ["Meow.", "*purrs*", "Mrrrp?", "*ignores you, then headbutts your hand*"],
}

const CLERK_LINES := {
	"library": ["Shh! ...Sorry, habit. Hello, dear.", "The new Choose Your Own Adventure books came in.", "Late fees are ten cents a day. I don't make the rules. Well, I do."],
	"diner": ["Order up! Oh, that's not you.", "Best pancakes in Maple Grove. Only pancakes in Maple Grove, too.", "Coffee's for grown-ups, kid. How about a cocoa?"],
	"pizza": ["Pan pizza, comin' right up!", "The jukebox only plays 'Take On Me' now. Nobody knows why.", "We deliver! Just call from home."],
	"video": ["Be kind, rewind.", "The horror section's in the back. If you dare.", "We're all out of the new one. We're ALWAYS all out of the new one."],
	"arcade": ["Need change? I've got quarters.", "Tickets go at the prize counter. The slap bracelets are hot right now.", "No jumping on the machines!"],
	"drivein": ["Popcorn's fresh! Butter's real! Mostly.", "Tonight's a double feature. Bring a blanket.", "Turn the speaker up. The monster's the best part."],
	"bikes": ["That red BMX in the window? Sixty bucks. She's a beauty.", "Pegs, pads, a bell. Accessorize, little dude.",
		"Paper route? A bike'll double your speed. Just sayin'.", "Don't forget to pump up your tires!"],
	"grocery": ["Paper or plastic? ...Okay, we only have paper.", "Need a job? I pay a couple bucks to bag groceries.",
		"Your mom was in this morning. She bought the generic cereal. Sorry, kid."],
}

const MOLLY_LINES := [
	"Twenty-five cents a cup! I'm saving up for a Cabbage Patch Kid.",
	"My brother Marcus says I'm a business tycoon. What's a tycoon?",
	"I put extra sugar in this batch. Don't tell my mom.",
	"Business is slow. Tell all your friends!",
]

const FROSTY_LINES := [
	"Soft-serve so cold it'll make your teeth sing!",
	"Banana split's the house special. Three scoops, kid. THREE.",
	"Best part of summer? Me. I'm the best part of summer.",
]

const GRUBER_LINES := [
	"The news never sleeps, kid. Well. I do. But the news doesn't.",
	"Papers go on the porch. Not the bushes, not the roof. The PORCH.",
	"A paper route builds character! And a little pocket money.",
	"Back in my day, I delivered papers uphill both ways. In the snow.",
]

const THIEF_LINES := [
	"I'm innocent! ...Mostly innocent.",
	"Thirty days for a VCR? It wasn't even a GOOD VCR.",
	"The food in here is terrible. Can you sneak me a Pizza Peak slice?",
	"You were lucky, kid. Next time I'm wearing sneakers.",
]

## Where people come from when they walk into town (and go back to).
const EDGES := [Vector3(-16.2, 0, 66.0), Vector3(-16.2, 0, -68.0), Vector3(131.0, 0, 55.4), Vector3(131.0, 0, 24.4), Vector3(131.0, 0, 14.8)]
## The bus stop on Main Street (Dad takes the bus to work).
const BUS_STOP := Vector3(4.8, 0, 45.2)


static func spawn(main: Node3D, room: Dictionary) -> Array:
	var objs: Dictionary = room["objects"]
	var grid: AStarGrid2D = room["grid"]
	var out := []
	# ---- the families: two parents per house (and a kid where nobody plays)
	var homes := ["jamie"]
	homes.append_array(NeighborBuilder.HOMES.keys())
	var spots_all: Dictionary = room["npc_spots"]
	for hi in homes.size():
		var home: String = homes[hi]
		var fam := Families.family(home)
		var kid_skin := 1
		for ch in Sim.CHARACTERS:
			if ch["home"] == home:
				kid_skin = int(ch["look"]["skin"])
		var hd: Dictionary = NeighborBuilder.HOMES.get(home, {})
		if hd.has("kid_look"):
			kid_skin = int(hd["kid_look"]["skin"])
		var spots: Dictionary = (spots_all.get(home, {}) as Dictionary).duplicate()
		_outdoor_spots(spots, home, hi, objs)
		var bed: SmartObject = objs.get(home + "_parents_bed")
		var mom_look := {"gender": "girl", "hair": ["perm", "teased", "feathered", "layered", "perm", "teased", "bun", "feathered", "perm"][hi],
			"hair_color": [2, 1, 0, 4, 0, 3, 5, 3, 0][hi], "skin": kid_skin, "outfit": 0, "adult": true, "top_style": "plain",
			"top": [Color("C2572F"), Color("6A5A9A"), Color("2E8C8A"), Color("E85A7A"), Color("E3B23C"), Color("4A6FA5"), Color("8FA06A"), Color("C8A2C8"), Color("E4704F")][hi],
			"pants": [Color("3B4E6E"), Color("2B2B30"), Color("D9C49E"), Color("3B4E6E"), Color("6B4429"), Color("2B2B30"), Color("4A3A2A"), Color("2B3A5A"), Color("3B4E6E")][hi],
			"shoes": Color("5A3A22")}
		var dad_look := {"gender": "boy", "hair": ["feathered", "buzz", "curtains", "feathered", "buzz", "high_top", "mullet", "curtains", "high_top"][hi],
			"hair_color": [1, 2, 0, 4, 0, 0, 2, 4, 0][hi], "skin": kid_skin, "outfit": 0, "adult": true, "top_style": "plain",
			"top": [Color("8FA06A"), Color("C8A250"), Color("9EC1D9"), Color("A44A2A"), Color("F2F0E6"), Color("7A4FB0"), Color("5A7A9A"), Color("2E6B4F"), Color("C0322A")][hi],
			"pants": [Color("6B5A45"), Color("3B4E6E"), Color("2B2B30"), Color("8A7A5A"), Color("3B4E6E"), Color("2B2B30"), Color("6B5A45"), Color("2B2B30"), Color("3B4E6E")][hi],
			"shoes": Color("2B2020")}
		var mom := _make(main, objs, "npc_%s_mom" % home, "Mrs. " + fam, "parent", mom_look, PARENT_LINES, home, grid)
		mom.set_meta("mom", true)
		mom.spots = spots.duplicate()
		_offset_town_spots(mom.spots, hi, 0)
		if bed:
			mom.spots["sleep"] = [bed.to_global(Vector3(-0.35, 0, 0.95)), bed.global_rotation_degrees.y + 180.0]
		mom.schedule = [
			[22.5, 6.5, "asleep", []],
			[6.5, 9.0, "kitchen", []],
			[9.0, 10.0, "living", []],
			[10.0, 11.5, "grocery", [1, 3, 5]],      # errands downtown (Mon, Wed, Fri)
			[10.0, 11.5, "yard", [2, 4]],            # gardening out front (Tue, Thu)
			[9.5, 11.0, "diner", [0]],               # Sunday breakfast at the diner
			[9.0, 11.5, "grocery", [6]],             # Saturday shopping
			[11.5, 13.0, "kitchen", []],
			[13.0, 13.3, "mailbox", [1, 2, 3, 4, 5, 6]],   # the mail comes around noon (not on Sundays)
			[13.0, 13.3, "kitchen", [0]],
			[13.3, 14.5, "sidewalk", []],            # ...and a chat with the neighbors
			[14.5, 17.0, "living", [1, 2, 3, 4, 5]],
			[14.5, 17.0, "backyard", [0, 6]],
			[17.0, 19.0, "kitchen", []],
			[19.0, 22.5, "living", []],
		]
		var dad := _make(main, objs, "npc_%s_dad" % home, "Mr. " + fam, "parent", dad_look, PARENT_LINES, home, grid)
		dad.set_meta("mom", false)
		dad.spots = spots.duplicate()
		_offset_town_spots(dad.spots, hi, 1)
		if bed:
			dad.spots["sleep"] = [bed.to_global(Vector3(0.35, 0, 0.95)), bed.global_rotation_degrees.y + 180.0]
		dad.schedule = [
			[23.0, 6.5, "asleep", []],
			[6.5, 7.4, "dining", []],
			[7.4, 17.3, "bus", [1, 2, 3, 4, 5]],     # off to work on the bus, home by dinner
			[9.0, 11.0, "yard", [6]],                # Saturday: mow the lawn
			[9.5, 11.0, "diner", [0]],               # Sunday: breakfast out with Mom
			[11.0, 13.0, "living2", [0, 6]],
			[13.0, 16.0, "backyard", [0, 6]],        # the grill, the hammock, the game on the radio
			[16.0, 17.3, "sidewalk", [0, 6]],
			[17.3, 18.5, "living2", []],
			[18.5, 19.5, "dining", []],
			[19.5, 23.0, "living2", []],
			[0.0, 24.0, "living2", []],
		]
		out.append(mom)
		out.append(dad)
		# The kids in the houses nobody plays live here too
		if hd.has("kid"):
			var kid := _make(main, objs, "npc_%s_kid" % home, "%s %s" % [hd["kid"], fam], "kid", hd["kid_look"], KID_LINES, home, grid)
			kid.spots = spots.duplicate()
			_offset_town_spots(kid.spots, hi, 2)
			var kb: SmartObject = objs.get(home + "_bed")
			if kb:
				kid.spots["sleep"] = [kb.to_global(Vector3(0, 0, 0.6)), kb.global_rotation_degrees.y + 180.0]
				kid.spots["kidbed"] = [kb.approach_point, kb.global_rotation_degrees.y]
			kid.schedule = [
				[21.0, 7.5, "asleep", []],
				[7.5, 9.0, "bedroom", []],
				[9.0, 11.0, "yard", []],
				[11.0, 12.0, "sidewalk", []],
				[12.0, 13.0, "dining", []],
				[13.0, 16.0, "field", [1, 3, 5]],
				[13.0, 16.0, "arcade", [2, 4]],
				[13.0, 16.0, "pool", [0, 6]],
				[16.0, 18.0, "backyard", []],
				[18.0, 19.0, "dining", []],
				[19.0, 21.0, "bedroom", []],
			]
			out.append(kid)
	# ---- the family pets (and Sparky, the firehouse dog)
	var rooms: Dictionary = room["rooms"]
	for pd in PETS:
		var wander := []
		for k in rooms:
			var kind := String(k).get_slice("|", 1)
			if String(k).begins_with(pd[0] + "|") and (kind in ["Living Room", "Kitchen", "Hallway", "Dining Room", "Kid Room", "Fire Station", "Firehouse Kitchen"]):
				wander.append(rooms[k])
		var pet := _make(main, objs, "pet_" + String(pd[0]) if pd[0] != "town" else "pet_firehouse", pd[1], "pet",
			{"species": pd[2], "color": pd[3], "accent": pd[4]}, PET_LINES[pd[2]], pd[0], grid)
		pet.kind = "pet_" + String(pd[2])
		pet.talk_dist = 0.75
		if pd[0] == "town":
			# (Sparky keeps to the kitchen side, out from under the fire engines)
			wander = wander.filter(func(r: Rect2): return rooms.get("town|Firehouse Kitchen") == r)
			if not wander.is_empty():
				var kr: Rect2 = wander[0]
				pet.global_position = Vector3(kr.get_center().x, 0, kr.get_center().y)
		pet.wander = wander
		out.append(pet)
	# ---- folks out for a walk (Maple Street, the path, Main Street, Lincoln Avenue)
	var maple_n := 14.8
	var maple_s := 24.4
	var main_n := 45.2
	var main_s := 54.8
	var linc_n := -36.8
	var linc_s := -27.2
	var routes := [
		[Vector3(-18, 0, maple_n), Vector3(38, 0, maple_n)],
		[Vector3(-16.2, 0, linc_s), Vector3(30, 0, linc_s), Vector3(30, 0, linc_n), Vector3(-16.2, 0, linc_n)],
		[Vector3(-0.9, 0, maple_s), Vector3(-0.9, 0, 42.0), Vector3(30, 0, main_n), Vector3(-0.9, 0, 42.0)],
		[Vector3(-16, 0, main_s), Vector3(70, 0, main_s)],
		[Vector3(44, 0, main_n), Vector3(-17, 0, main_n)],
		[Vector3(20, 0, maple_n), Vector3(-15, 0, maple_n), Vector3(-0.9, 0, maple_s), Vector3(30, 0, maple_s)],
		[Vector3(-18, 0, maple_s), Vector3(62, 0, maple_s), Vector3(37.9, 0, maple_n), Vector3(37.9, 0, linc_s), Vector3(10, 0, linc_s)],
		[Vector3(64, 0, main_n), Vector3(0, 0, main_n), Vector3(-0.9, 0, 42.0), Vector3(-0.9, 0, maple_s)],
		[Vector3(55, 0, maple_s), Vector3(55, 0, 40.0), Vector3(62, 0, 40.0), Vector3(62, 0, maple_s)],
		[Vector3(-16, 0, maple_n), Vector3(78, 0, maple_n)],
		[Vector3(30, 0, main_s), Vector3(78, 0, main_s), Vector3(30, 0, main_s), Vector3(-10, 0, main_s)],
		[Vector3(-0.9, 0, maple_s), Vector3(-0.9, 0, 42.0), Vector3(-14, 0, main_n), Vector3(-0.9, 0, 42.0)],
	]
	var walker_looks := [
		{"gender": "girl", "hair": "teased", "hair_color": 5, "skin": 0, "top": Color("B5654A"), "pants": Color("6B5A45"), "top_style": "plain"},
		{"gender": "girl", "hair": "bun", "hair_color": 1, "skin": 3, "top": Color("F2C230"), "pants": Color("2E4A8A"), "top_style": "plain"},
		{"gender": "boy", "hair": "feathered", "hair_color": 2, "skin": 3, "top": Color("8FB3D6"), "pants": Color("2B2F5A"), "top_style": "plain"},
		{"gender": "girl", "hair": "side_pony", "hair_color": 4, "skin": 0, "outfit": 0},
		{"gender": "boy", "hair": "curtains", "hair_color": 0, "skin": 2, "top": Color("C8A250"), "pants": Color("6B4429"), "top_style": "plain"},
		{"gender": "girl", "hair": "perm", "hair_color": 3, "skin": 4, "outfit": 5},
		{"gender": "boy", "hair": "buzz", "hair_color": 0, "skin": 1, "top": Color("2B3A6A"), "pants": Color("2B3A6A"), "top_style": "plain", "shoes": Palette.INK},
		{"gender": "boy", "hair": "spiky", "hair_color": 4, "skin": 0, "outfit": 3, "kid": true},
		{"gender": "girl", "hair": "perm", "hair_color": 5, "skin": 2, "top": Color("C8A2C8"), "pants": Color("6E6A80"), "top_style": "plain"},
		{"gender": "boy", "hair": "feathered", "hair_color": 1, "skin": 3, "top": Palette.PAPER, "pants": Palette.PAPER, "top_style": "plain"},
		{"gender": "girl", "hair": "scrunchie", "hair_color": 4, "skin": 0, "outfit": 4, "kid": true},
		{"gender": "boy", "hair": "bowl", "hair_color": 2, "skin": 5, "outfit": 2, "kid": true},
	]
	for i in WALKER_LINES.size():
		var lk: Dictionary = walker_looks[i].duplicate()
		lk["adult"] = not lk.get("kid", false)
		var w := _make(main, objs, "npc_walker_%d" % (i + 1), WALKER_LINES[i][0], "walker", lk, WALKER_LINES[i][1], "town", grid)
		w.route = routes[i]
		w.hours = Vector2(7.0 + (i % 6) * 0.5, 20.0 + (i % 3) * 0.5) if lk["adult"] else Vector2(9.0, 19.5)
		out.append(w)
	# ---- Molly at the lemonade stand (she walks over from home), Frosty, and Mr. Gruber
	if room.has("lemonade_spot"):
		var at: Vector3 = room["lemonade_spot"]
		var molly := _make(main, objs, "npc_molly", "Molly Parker", "vendor",
			{"gender": "girl", "hair": "side_pony", "hair_color": 0, "skin": 4, "outfit": 4}, MOLLY_LINES, "town", grid)
		molly.kind = "npc_lemonade"
		molly.talk_dist = 1.35
		molly.spots = {"post": [at + Vector3(0, 0, -0.62), 0.0]}
		molly.hours = Vector2(9.5, 18.5)
		var pp: SmartObject = objs.get("parkers_porch")
		_commuter(molly, pp.approach_point if pp else EDGES[3], at + Vector3(0, 0, -1.4), "", 0.3)
		out.append(molly)
	var fs: Array = room["frostys_spot"]
	var frosty := _make(main, objs, "npc_frosty", "Frosty", "vendor",
		{"gender": "boy", "hair": "buzz", "hair_color": 4, "skin": 0, "adult": true, "top_style": "plain",
		"top": Palette.PAPER, "pants": Color("F2A0B5"), "shoes": Palette.PAPER}, FROSTY_LINES, "town", grid)
	frosty.kind = "npc_icecream"
	frosty.talk_dist = 1.3
	frosty.spots = {"post": fs}
	frosty.hours = Vector2(11.5, 21.5)
	_commuter(frosty, EDGES[3], (fs[0] as Vector3) + Vector3(0, 0, -0.9), "")
	out.append(frosty)
	var gs: Array = room["gazette_spot"]
	var gruber := _make(main, objs, "npc_gruber", "Mr. Gruber", "vendor",
		{"gender": "boy", "hair": "buzz", "hair_color": 5, "skin": 1, "adult": true, "top_style": "plain",
		"top": Color("D9D2C2"), "pants": Color("4A4A52"), "shoes": Color("2B2020")}, GRUBER_LINES, "town", grid)
	gruber.kind = "npc_gazette"
	gruber.talk_dist = 1.4
	gruber.spots = {"post": gs}
	gruber.hours = Vector2(5.5, 18.0)
	_commuter(gruber, EDGES[3], _outside(DowntownBuilder.GAZETTE, true), "gazette")
	out.append(gruber)
	# ---- the shopkeepers on Main Street, and Lou at the drive-in's snack bar
	var ei := 0
	for ck in room.get("clerks", []):
		var shop := String(ck["shop"])
		var cl := _make(main, objs, "npc_clerk_" + shop, ck["title"], "vendor", ck["look"],
			CLERK_LINES.get(shop, []), "town", grid)
		cl.kind = "npc_clerk"
		cl.talk_dist = float(ck["talk"])
		cl.spots = {"post": [ck["pos"], 180.0]}
		cl.hours = ck["hours"]
		cl.days = DowntownBuilder.SHOP_DAYS.get(shop, [])
		_commuter(cl, EDGES[[0, 2, 0, 2, 2, 2, 2][ei % 7]], _outside(DowntownBuilder.shop_rect(shop), false), shop)
		ei += 1
		out.append(cl)
	var lou := _make(main, objs, "npc_lou", "Lou", "vendor",
		{"gender": "boy", "hair": "curtains", "hair_color": 2, "skin": 2, "adult": true, "top_style": "plain",
		"top": Color("C0322A"), "pants": Color("2B2B30")}, CLERK_LINES["drivein"], "town", grid)
	lou.kind = "npc_snackbar"
	lou.talk_dist = 1.3
	lou.spots = {"post": room["snackbar_spot"]}
	lou.hours = Vector2(19.5, 1.0)
	_commuter(lou, EDGES[3], (room["snackbar_spot"][0] as Vector3) + Vector3(0, 0, 1.2), "")
	out.append(lou)
	# ---- City Hall, the school, the football field, the police and fire stations
	for st in room.get("staff", []):
		var sn := _make(main, objs, "npc_" + String(st["id"]), st["title"], "vendor", st["look"], st["lines"], "town", grid)
		sn.kind = String(st.get("kind", "npc_clerk" if st["id"] != "coach" else "npc_coach"))
		sn.talk_dist = float(st["talk"])
		sn.spots = {"post": [st["pos"], float(st["yaw"])]}
		sn.hours = st["hours"]
		sn.days = st["days"]
		sn.months = st.get("months", [])
		if st.get("seated", false):
			sn.set_meta("seated", true)
		if st.get("stay", false):
			# (students: they're just at their desks during class, and gone otherwise)
			ei += 1
			out.append(sn)
			continue
		var work: String = st["work"]
		var bld: Rect2 = {"police": CivicBuilder.POLICE, "fire": CivicBuilder.FIRE, "city_hall": CivicBuilder.CITY_HALL,
			"school": CivicBuilder.SCHOOL}.get(work, Rect2())
		var door: Vector3 = st.get("door", (st["pos"] as Vector3) + Vector3(0, 0, 2.0))
		if bld.size != Vector2.ZERO:
			door = _civic_door(work)
		var edge: Vector3 = st.get("edge", EDGES[1] if ei % 2 == 0 else EDGES[0])
		# (the shop's door locks while it's closed: the workplace key is its shop door)
		_commuter(sn, edge, door, String(st.get("lock", work if work in ["city_hall", "school"] else "")))
		ei += 1
		out.append(sn)
	# ---- teens at the mall (the goth kids, the emo kid, the preps) and punks at the skate park
	out.append_array(_teens(main, objs, room, grid))
	# ---- a burglar (he only shows up once in a blue moon: see TownLife)
	var thief := _make(main, objs, "npc_burglar", "The Burglar", "thief",
		{"gender": "boy", "hair": "cap", "hair_color": 0, "skin": 1, "adult": true, "top_style": "plain",
		"top": Color("2B2B30"), "pants": Color("2B2B30"), "shoes": Palette.INK, "hair_rgb": Color("1A1A1A")}, THIEF_LINES, "town", grid)
	thief.kind = "npc_thief"
	thief.talk_dist = 1.0
	out.append(thief)
	return out


## Parents and kids: where they go when they're out of the house.
static func _outdoor_spots(spots: Dictionary, home: String, hi: int, objs: Dictionary) -> void:
	var porch: SmartObject = objs.get(home + "_porch")
	if porch:
		var outward := (porch.approach_point - porch.look_point)
		outward.y = 0.0
		outward = outward.normalized()
		spots["door"] = [porch.approach_point, 180.0]
		var across := Vector3(outward.z, 0, -outward.x)
		spots["yard"] = [porch.approach_point + outward * 2.2 + across * 2.0, rad_to_deg(atan2(outward.x, outward.z)) + 180.0]
		var sz := 14.8 if outward.z > 0 else 24.4
		spots["sidewalk"] = [Vector3(porch.approach_point.x + 1.2, 0, sz), 90.0]
	var table: SmartObject = objs.get("dining_table" if home == "jamie" else home + "_table")
	if table:
		spots["dining"] = [table.approach_point, 0.0]
	if spots.has("living"):
		spots["living2"] = [(spots["living"][0] as Vector3) + Vector3(0.9, 0, 0.7), spots["living"][1]]
	var mb: SmartObject = objs.get("mailbox" if home == "jamie" else home + "_mailbox")
	if mb:
		spots["mailbox"] = [mb.approach_point, 0.0]
	var gr := DowntownBuilder.shop_rect("grocery")
	spots["grocery"] = [Vector3(gr.position.x + 5.0, 0, gr.position.y + 3.6), 180.0]
	var dn := DowntownBuilder.shop_rect("diner")
	spots["diner"] = [Vector3(dn.position.x + 2.2, 0, dn.position.y + 4.0), -90.0]
	spots["bus"] = [BUS_STOP, 0.0, "away"]
	var fld := CivicBuilder.FIELD
	spots["field"] = [Vector3(fld.get_center().x - 6.0, 0, fld.get_center().y), 90.0]
	var ar := DowntownBuilder.shop_rect("arcade")
	spots["arcade"] = [Vector3(ar.get_center().x, 0, ar.position.y + 5.0), 180.0]
	var pool: SmartObject = objs.get("obriens_swimming_pool")
	if pool:
		spots["pool"] = [pool.approach_point, 180.0]


## Spread people out at shared places (the bus stop, the grocery store...) so they don't stand in each other.
static func _offset_town_spots(spots: Dictionary, hi: int, who: int) -> void:
	var off := Vector3((hi % 5) * 0.75 - 1.5, 0, (who - 1) * 0.7 + (hi / 5) * 0.4)
	for k in ["grocery", "diner", "bus", "field", "arcade", "pool"]:
		if spots.has(k):
			var e: Array = (spots[k] as Array).duplicate()
			e[0] = (e[0] as Vector3) + off
			spots[k] = e


## Shopkeepers walk in from `from` to `door` (just outside the shop) before opening.
static func _commuter(n: Npc, from: Vector3, door: Vector3, workplace: String, lead := 0.9) -> void:
	n.commute = true
	n.edge = from
	n.door_out = door
	n.workplace = workplace
	n.lead = lead


## The spot just outside a shop's front door (Main Street side).
static func _outside(r: Rect2, north_side: bool) -> Vector3:
	if north_side:
		return Vector3(r.get_center().x, 0, r.end.y + 0.9)
	return Vector3(r.get_center().x, 0, r.position.y - 0.9)


static func _civic_door(work: String) -> Vector3:
	match work:
		"police":
			return Vector3(5.0, 0, CivicBuilder.POLICE.position.y - 0.9)
		"fire":
			return Vector3(37.3, 0, CivicBuilder.FIRE.position.y - 0.9)
		"city_hall":
			return Vector3(CivicBuilder.CITY_HALL.get_center().x, 0, CivicBuilder.CITY_HALL.end.y + 0.9)
		"school":
			return Vector3(20.5, 0, CivicBuilder.SCHOOL.end.y + 0.9)
	return Vector3.ZERO


static func _make(main: Node3D, objs: Dictionary, key: String, title: String, role: String, look: Dictionary,
		lines: Array, home: String, grid: AStarGrid2D) -> Npc:
	var n := Npc.new()
	n.setup(title, role, look, lines, home, grid)
	n.name = key
	main.add_child(n)
	objs[key] = n
	return n


## Put everyone where they'd be at this hour (a new game, a loaded game).
static func settle(npcs: Array, hour: float, weekday: int) -> void:
	for n: Npc in npcs:
		n.settle(hour, weekday)


## The kids who hang out at the mall and the skate park. They walk a loop and
## stop to talk to each other (TownLife); a couple carry boomboxes.
const TEENS := [
	# key, name, look, lines, where, extra ("skater", "boombox")
	["goth_1", "Raven", {"gender": "girl", "hair": "layered", "hair_color": 0, "skin": 0, "outfit": 12, "kid": true},
		["Everything's so... bright in here.", "I only wear black. Until they invent something darker.", "The food court is a metaphor. For what? Exactly."], "mall", ""],
	["goth_2", "Damien", {"gender": "boy", "hair": "emo", "hair_color": 0, "skin": 0, "outfit": 12, "kid": true},
		["Spin City got the new Midnight Static import. Finally.", "Sunlight is overrated.", "We're not sad. We're just... observant."], "mall", ""],
	["emo_1", "Ashley", {"gender": "girl", "hair": "emo", "hair_color": 0, "skin": 1, "outfit": 11, "kid": true},
		["Nobody understands my poetry.", "This song is literally about my life.", "I'm fine. Totally fine. Whatever."], "mall", ""],
	["emo_2", "Jesse", {"gender": "boy", "hair": "emo", "hair_color": 4, "skin": 2, "outfit": 11, "kid": true},
		["I wrote a song about the fountain. It's sad.", "My mom says it's a phase. It's NOT a phase.", "Want to hear my band's demo? It's mostly feelings."], "mall", ""],
	["prep_1", "Brittany", {"gender": "girl", "hair": "scrunchie", "hair_color": 4, "skin": 0, "outfit": 7, "kid": true},
		["Oh my gosh, that's SO last season.", "Daddy said I could get the sweater AND the shoes.", "We're going to the club this weekend. The country club."], "mall", ""],
	["prep_2", "Chad", {"gender": "boy", "hair": "feathered", "hair_color": 4, "skin": 0, "outfit": 7, "kid": true},
		["Lacrosse practice was brutal, bro.", "Collar up. Always collar up.", "My dad's getting a car phone. A PHONE. In the CAR."], "mall", ""],
	["prep_3", "Muffy", {"gender": "girl", "hair": "side_pony", "hair_color": 2, "skin": 3, "outfit": 15, "kid": true},
		["Tennis at four, then the mall. Obviously.", "Like, could you not stand so close to my bags?", "I have, like, nine of these sweaters."], "mall", ""],
	["punk_1", "Spike Jr.", {"gender": "boy", "hair": "mohawk", "hair_color": 3, "skin": 0, "outfit": 8, "kid": true},
		["Skate or die, man!", "The man can't stop us from shredding.", "Did you see that kickflip? DID YOU SEE IT?"], "skate", "skater"],
	["punk_2", "Roxy", {"gender": "girl", "hair": "mohawk", "hair_color": 5, "skin": 1, "outfit": 8, "kid": true},
		["Anarchy! ...After dinner. My mom's making tacos.", "This half-pipe is the only place that gets me.", "Safety pins are a fashion statement."], "skate", "skater"],
	["punk_3", "Vinnie", {"gender": "boy", "hair": "spiky", "hair_color": 0, "skin": 4, "outfit": 8, "kid": true},
		["I'm starting a band. We're called Unpaid Parking Ticket.", "Wanna see me grind the rail? Watch this. ...Ow.", "Mohawk Mike sold me this board. It's legendary."], "skate", "skater"],
	["boombox_1", "DJ Dwayne", {"gender": "boy", "hair": "high_top", "hair_color": 0, "skin": 4, "outfit": 2, "kid": true},
		["Check this beat, it's FRESH!", "Batteries cost me a fortune. Worth it.", "You can't stop the music, you can only turn it up."], "skate", "boombox"],
	["boombox_2", "Kiki", {"gender": "girl", "hair": "perm", "hair_color": 1, "skin": 3, "outfit": 16, "kid": true},
		["This mixtape took me ALL weekend.", "Dance break! Come on!", "My boombox has a double tape deck. Jealous?"], "skate", "boombox"],
]


static func _teens(main: Node3D, objs: Dictionary, room: Dictionary, grid: AStarGrid2D) -> Array:
	var out := []
	var mall: Array = room.get("mall_route", [])
	var skate: Array = room.get("skate_route", [])
	var i := 0
	for t in TEENS:
		var where: String = t[4]
		var base: Array = mall if where == "mall" else skate
		if base.is_empty():
			continue
		var n := _make(main, objs, "npc_teen_" + String(t[0]), t[1], "walker", t[2], t[3], "town", grid)
		# (each walks the loop starting at a different point, a little to one side)
		var r := []
		for k in base.size():
			var p: Vector3 = base[(k + i) % base.size()]
			r.append(p + Vector3((i % 3) * 0.45 - 0.45, 0, ((i / 3) % 2) * 0.5))
		n.route = r
		n.hours = Vector2(11.0, 20.5) if where == "mall" else Vector2(10.0, 20.0)
		match t[5]:
			"skater":
				n.add_skateboard([Color("F7D046"), Color("4FC8FF"), Color("FF4FD8")][i % 3])
			"boombox":
				n.add_boombox()
		out.append(n)
		i += 1
	return out
