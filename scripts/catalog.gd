class_name Catalog
extends RefCounted
## Everything you can buy and keep: toys from the Toy Box, clothes from Trend
## Setters, records and CDs from Spin City, computers and gadgets from Circuit
## Hut, and a skateboard from the skate shop at the park. Once you own something
## it stays yours (sim.owned), and the things you can do with it show up at home:
## on your bed, your desk, the stereo or the couch.
##
## Every item: name, price, shop (where it's sold), group (owning any item of a
## group counts, e.g. any record), use (things to do with it at home:
## [title, minutes, effects, pose, where]), and an optional line for when you buy it.

const ITEMS := {
	# ---- the Toy Box (mall)
	"sketch": {"name": "Sketch-O-Screen", "price": 9.0, "shop": "toys",
		"use": [["Draw on Your Sketch-O-Screen", 30, {"fun": 36.0}, "sit", "bed"]],
		"bought": "Twist the knobs, shake to erase. Your masterpiece awaits."},
	"spring": {"name": "Stair Spring", "price": 3.0, "shop": "toys",
		"use": [["Play with Your Stair Spring", 15, {"fun": 30.0}, "reach", "bed"]],
		"bought": "It walks down stairs! (Don't stretch it out.)"},
	"gamekid": {"name": "Game Kid Handheld", "price": 45.0, "shop": "toys", "memory": "gamekid",
		"use": [["Play Your Game Kid", 40, {"fun": 60.0, "energy": -4.0}, "sit", "bed"],
			["Play Your Game Kid", 40, {"fun": 60.0, "energy": -4.0}, "sit", "couch"]],
		"bought": "A Game Kid! Four AA batteries and you're off. Falling Blocks is SO addictive."},
	"furbit": {"name": "Furbit", "price": 25.0, "shop": "toys",
		"use": [["Talk to Your Furbit", 15, {"social": 30.0, "fun": 20.0}, "sit", "bed"]],
		"bought": "\"Doo-moh!\" It blinks at you. It's a little creepy. You love it."},
	"litepegs": {"name": "Lite-Pegs", "price": 12.0, "shop": "toys",
		"use": [["Make a Lite-Pegs Picture", 30, {"fun": 34.0}, "sit", "desk"]],
		"bought": "Glowing pegs! Making pictures with light!"},
	"walktunes": {"name": "Walk-Tunes Cassette Player", "price": 30.0, "shop": "toys",
		"use": [["Listen to Your Walk-Tunes", 40, {"fun": 40.0, "energy": 10.0}, "lie", "bed"]],
		"bought": "Headphones on, world off. Now you need a mixtape."},
	"teddy": {"name": "Story-Time Teddy", "price": 20.0, "shop": "toys",
		"use": [["Listen to Story-Time Teddy", 20, {"fun": 22.0, "energy": 12.0}, "lie", "bed"]],
		"bought": "Put a tape in his back and he reads you a story. His mouth moves and everything."},
	"pogs": {"name": "Milk Cap Game Set", "price": 4.0, "shop": "toys",
		"use": [["Play Milk Caps", 20, {"fun": 30.0, "social": 6.0}, "sit", "desk"]],
		"bought": "Slammers and caps. Playing for keeps? Your call."},
	# ---- Spin City Records (mall): records play on the stereo, CDs need a CD player
	"lp_neon": {"name": "Neon Hearts: Midnight Arcade (LP)", "price": 7.0, "shop": "music", "group": "records"},
	"lp_rewind": {"name": "The Cassettes: Rewind (LP)", "price": 7.0, "shop": "music", "group": "records"},
	"lp_maple": {"name": "Maple Avenue Boys: Summer Daze (LP)", "price": 7.0, "shop": "music", "group": "records"},
	"lp_laser": {"name": "Laser Kitten: Synth City (LP)", "price": 8.0, "shop": "music", "group": "records"},
	"cd_grunge": {"name": "Flannel Theory: Static (CD)", "price": 13.0, "shop": "music", "group": "cds"},
	"cd_pop": {"name": "Starr Jenkins: Totally Yours (CD)", "price": 13.0, "shop": "music", "group": "cds"},
	"cd_rap": {"name": "MC Boombox: Fresh Off the Bus (CD)", "price": 14.0, "shop": "music", "group": "cds"},
	# ---- Circuit Hut (mall): computers end up on your desk
	"computer_color": {"name": "Color Computer II", "price": 90.0, "shop": "computers", "group": "computer", "memory": "computer",
		"bought": "It's yours! Two delivery men carry the Color Computer II up to your desk."},
	"computer_64": {"name": "Micro-Pal 64", "price": 140.0, "shop": "computers", "group": "computer", "memory": "computer",
		"bought": "The Micro-Pal 64! 64 kilobytes of pure power, now on your desk."},
	"computer_tower": {"name": "Turbo 386 Tower", "price": 250.0, "shop": "computers", "group": "computer", "memory": "computer",
		"bought": "A tower computer with a COLOR monitor. Mom says it better be for homework."},
	"modem": {"name": "2400-Baud Modem", "price": 35.0, "shop": "computers",
		"bought": "Screeeech-beep-kshhhh. You can dial into BBSes now (if somebody's not on the phone)."},
	"cdplayer": {"name": "Disc Spinner CD Player", "price": 50.0, "shop": "computers",
		"bought": "Anti-skip! (Mostly.) Now you need some CDs."},
	"calcwatch": {"name": "Calculator Watch", "price": 10.0, "shop": "computers",
		"use": [["Do Math on Your Calculator Watch", 10, {"fun": 12.0}, "sit", "desk"]],
		"bought": "Type 5318008 and turn it upside down. Classic."},
	"rccar": {"name": "Radio-Control Racer", "price": 28.0, "shop": "computers",
		"use": [["Race Your RC Car Around the Room", 25, {"fun": 44.0, "energy": -6.0}, "stand", "bed"]],
		"bought": "VRRRRRM. The cat is not going to like this."},
	# ---- the skate shop (at the skate park)
	"skateboard": {"name": "Skateboard", "price": 35.0, "shop": "skate", "memory": "skate",
		"bought": "Grip tape, urethane wheels, a dragon on the bottom. Now go shred."},
}

## Clothes from Trend Setters (Looks.OUTFITS index -> price). The first six
## outfits are the ones you start with.
const OUTFIT_PRICES := {6: 18.0, 7: 22.0, 8: 25.0, 9: 20.0, 10: 16.0, 11: 15.0, 12: 24.0, 13: 14.0, 14: 19.0, 15: 21.0, 16: 17.0}
const FREE_OUTFITS := 6

## The computer you'd see on your desk (the best one you own).
const COMPUTER_ORDER := ["computer_tower", "computer_64", "computer_color"]


static func title(id: String) -> String:
	if id.begins_with("outfit_"):
		var i := int(id.substr(7))
		return String(Looks.OUTFITS[i]["name"]) if i < Looks.OUTFITS.size() else id
	return String(ITEMS.get(id, {}).get("name", id))


static func price(id: String) -> float:
	if id.begins_with("outfit_"):
		return float(OUTFIT_PRICES.get(int(id.substr(7)), 15.0))
	return float(ITEMS.get(id, {}).get("price", 0.0))


static func group(id: String) -> String:
	return String(ITEMS.get(id, {}).get("group", ""))


## Does this kid own `want` (an item id, or a group like "records")?
static func owns(owned: Dictionary, want: String) -> bool:
	if owned.has(want):
		return true
	for id in owned:
		if group(String(id)) == want:
			return true
	return false


## Outfits a kid can wear (the six you start with, plus any you bought).
static func outfits_for(owned: Dictionary) -> Array:
	var out := []
	for i in Looks.OUTFITS.size():
		if i < FREE_OUTFITS or owned.has("outfit_%d" % i):
			out.append(i)
	return out


static func best_computer(owned: Dictionary) -> String:
	for id in COMPUTER_ORDER:
		if owned.has(id):
			return id
	return ""


## A "Buy ..." activity for a shop counter or display.
static func buy_activity(id: String, hours := Vector2(10, 21)) -> Activity:
	var p := price(id)
	var a := Activity.make("Buy %s" % title(id), 5, {"fun": 30.0}, "reach")
	a.money = -p
	a.buys = id
	a.autonomous = false
	a.sound = "cash_register"
	a.from_hour = hours.x
	a.to_hour = hours.y
	return a


## Add what you can do with the things you own to every kid's bed, desk, stereo
## and couch (they only show up once you own the thing).
static func apply(objects: Dictionary) -> void:
	for key in objects:
		var o: SmartObject = objects[key]
		if o.home == "" or o.home == "town":
			continue
		var where := ""
		match o.kind:
			"bed":
				where = "bed"
			"desk":
				where = "desk"
			"stereo":
				where = "stereo"
			"couch":
				where = "couch"
		if where == "":
			continue
		for id in ITEMS:
			for u in ITEMS[id].get("use", []):
				if u[4] != where:
					continue
				var a := Activity.make(u[0], int(u[1]), u[2], u[3])
				a.needs_owned = id
				if u[3] == "lie":
					a.surface = 0.55 if where == "bed" else 0.45
				elif u[3] == "sit" and where == "bed":
					a.surface = 0.55
				o.activities.append(a)
		var a2: Activity
		match where:
			"stereo":
				a2 = Activity.make("Play One of Your Records", 40, {"fun": 50.0, "energy": 4.0}, "stand")
				a2.needs_owned = "records"
				a2.loop_sound = "vinyl"
				a2.loop_db = -9.0
				a2.messages = ["You drop the needle. Crackle... and then the bass kicks in.", "Side B is better. Everyone knows side B is better."]
				o.activities.append(a2)
			"desk":
				a2 = Activity.make("Play a Computer Game", 45, {"fun": 64.0, "energy": -6.0}, "sit")
				a2.needs_owned = "computer"
				a2.loop_sound = "arcade_game"
				a2.loop_db = -16.0
				a2.messages = ["You're in a dungeon. There's a lamp here. >GET LAMP", "Beep boop bloop. High score!", "You died of dysentery."]
				o.activities.append(a2)
				a2 = Activity.make("Type in a BASIC Program", 40, {"fun": 40.0}, "sit")
				a2.needs_owned = "computer"
				a2.messages = ["10 PRINT \"HELLO\"  20 GOTO 10. It works! Forever!", "Syntax error in line 340. Of course."]
				o.activities.append(a2)
				a2 = Activity.make("Do Homework on the Computer", 40, {"fun": -4.0}, "sit")
				a2.needs_owned = "computer"
				a2.money = 1.5
				a2.autonomous = false
				a2.message = "Typed up and printed on the dot-matrix printer. Dad pays $1.50 for it."
				o.activities.append(a2)
				a2 = Activity.make("Dial Into a BBS", 30, {"social": 50.0, "fun": 20.0}, "sit")
				a2.needs_owned = "modem"
				a2.messages = ["Screeeech... CONNECT 2400. You post on the message board: \"anybody here?\"", "Somebody picked up the phone and you got disconnected. MOM!"]
				o.activities.append(a2)
			"bed":
				a2 = Activity.make("Listen to a CD", 40, {"fun": 46.0, "energy": 10.0}, "lie")
				a2.surface = 0.55
				a2.needs_owned = "cds"
				a2.messages = ["Track 4 on repeat. Again.", "You read the whole lyric booklet. Twice."]
				o.activities.append(a2)


## Kids can only use what they own: the CD needs the CD player too.
static func can_use(owned: Dictionary, act: Activity) -> bool:
	if act.needs_owned == "":
		return true
	if not owns(owned, act.needs_owned):
		return false
	if act.needs_owned == "cds" and not owned.has("cdplayer"):
		return false
	if act.needs_owned == "modem" and best_computer(owned) == "":
		return false
	return true


## A computer for every kid's desk (hidden until somebody in that house buys one:
## main.gd's update_computers shows the best one).
static func add_desk_models(objects: Dictionary) -> void:
	for key in objects:
		var d: SmartObject = objects[key]
		if d.kind != "desk" or d.home == "" or d.home == "town":
			continue
		var models := {}
		for id in COMPUTER_ORDER:
			var g := Node3D.new()
			g.scale = Vector3(0.62, 0.62, 0.62)
			if key == "desk":
				# Jamie's desk (built along the wall, the chair on its +x side)
				d.get_parent().add_child(g)
				g.position = Vector3(8.322, 0.785, 6.8)
				g.rotation.y = PI / 2.0
			else:
				d.add_child(g)
				g.position = Vector3(-0.1, 0.755, -0.06)
			MallBuilder.computer_model(g, id)
			if key == "desk" and id == "computer_tower":
				# (Jamie's desk is against the window: the tower sits forward, beside the monitor)
				(g.get_child(3) as Node3D).position.z = -0.08
				(g.get_child(4) as Node3D).position.z = 0.093
			g.visible = false
			models[id] = g
		d.set_meta("computers", models)
