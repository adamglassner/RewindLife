class_name Phonebook
extends RefCounted
## Who you can call: every kid in town (from any phone), Grandma, and your own
## Mom & Dad (from a payphone, or a friend's phone). What they say back depends on
## the time: call too late and a parent answers and tells you to call tomorrow.
## If the kid you call is being played (online or split screen), they hear it ring.

const KID_LINES := [
	"\"Dude! What's up? Wanna come over later?\"",
	"\"I just beat the second level! Okay, okay, I'll tell you how.\"",
	"\"Did you see what was on TV last night? SO rad.\"",
	"\"My mom says I can't talk long. ...Okay, a little long.\"",
	"\"Meet me at the arcade? Bring quarters.\"",
	"\"No WAY. She said that? No WAY!\"",
	"\"I'm totally bored. Let's go to the mall.\"",
]
const MOM_LINES := [
	"Mom: \"Where ARE you? ...Okay. Be home before the streetlights come on!\"",
	"Mom: \"Did you remember your jacket? You didn't, did you.\"",
	"Dad: \"Hey, kiddo. Your mom's at the store. Need a ride?\" (You don't.)",
	"Mom: \"Dinner's at six. Don't spoil it with junk food!\"",
]
const GRANDMA_LINES := [
	"Grandma: \"Oh, it's so nice to hear your voice! Are you eating enough?\"",
	"Grandma tells you all about her bridge club. It takes a while. You don't mind.",
	"Grandma: \"I'm sending you a card with five dollars in it. Don't tell your mother.\"",
]


## Every home with a kid in it (the six you can play, and the three NPC kids).
static func kid_homes() -> Array:
	var out := []
	for ch in Sim.CHARACTERS:
		out.append(ch["home"])
	for h in NeighborBuilder.HOMES:
		if NeighborBuilder.HOMES[h].has("kid") and not out.has(h):
			out.append(h)
	return out


## Replace the phones' old fixed calls with the whole phonebook.
static func apply(objects: Dictionary) -> void:
	for key in objects:
		var o: SmartObject = objects[key]
		if o.kind != "phone" and o.kind != "payphone":
			continue
		var pay := o.kind == "payphone"
		for a in o.activities.duplicate():
			if a.title in ["Call Danny", "Call a Friend", "Call Home"] or (pay and a.title == "Call Grandma"):
				o.activities.erase(a)
		var at := 0
		for i in o.activities.size():
			if o.activities[i].title.begins_with("Call"):
				at = i
				break
		var calls := []
		var home := Activity.make("Call Home (Mom & Dad)", 10, {"social": 40.0}, "phone")
		home.call_home = "parents"
		home.from_hour = 7.0
		home.to_hour = 22.0
		calls.append(home)
		for h in kid_homes():
			var a := Activity.make("Call %s" % Families.kid_name(h), 25, {"social": 66.0, "fun": 12.0}, "phone")
			a.call_home = h
			a.busy_after_hour = 19.0
			a.memory_id = "phone_cord"
			calls.append(a)
		if pay:
			var g := Activity.make("Call Grandma", 20, {"social": 55.0}, "phone")
			g.from_hour = 9.0
			g.to_hour = 20.0
			g.messages = GRANDMA_LINES
			calls.append(g)
			home.memory_id = "payphone"
		for a in o.activities:
			if a.title == "Call Grandma":
				a.messages = GRANDMA_LINES
		for a in calls:
			if pay:
				a.money = -PayPhones.PRICE
				a.sound = "coin"
			a.autonomous = a.call_home != "parents"
			o.activities.insert(at, a)
			at += 1


## Should this call show up for this kid on this phone? (Not yourself, and not
## "call home" from your own kitchen.)
static func listed(act: Activity, caller_home: String, phone: SmartObject) -> bool:
	if act.call_home == "":
		return true
	if act.call_home == caller_home:
		return false
	if act.call_home == "parents" and phone != null and phone.home == caller_home:
		return false
	return true


## What you hear when the call goes through.
static func reply(caller_home: String, callee: String, hour: float) -> String:
	if callee == "parents":
		return MOM_LINES[randi() % MOM_LINES.size()]
	var name := Families.kid_name(callee)
	if hour >= 21.5 or hour < 7.0:
		var mom := Families.parent_name(callee, true, caller_home)
		return "%s answers: \"%s's asleep, sweetie. Call tomorrow, okay?\"" % [mom, name]
	return "%s: %s" % [name, KID_LINES[randi() % KID_LINES.size()]]
