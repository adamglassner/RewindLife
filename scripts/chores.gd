class_name Chores
extends RefCounted
## Chores: little jobs around the house that Mom and Dad pay for, once a day
## each, and only at your own house. (Ask Mom or Dad "What Chores Need Doing?")

## chore id -> [what it's called, pay in dollars]
const LIST := {
	"mail": ["getting the mail", 0.25],
	"trash": ["taking out the trash", 0.50],
	"dishes": ["washing the dishes", 0.75],
	"laundry": ["doing the laundry", 0.75],
	"bed": ["making your bed", 0.25],
	"table": ["setting the table", 0.25],
	"vacuum": ["vacuuming the living room", 0.75],
	"mow": ["mowing the lawn", 2.00],
	"walk_dog": ["walking the dog", 1.00],
	"feed_pet": ["feeding the pet", 0.25],
	"garden": ["weeding the garden", 0.50],
	"car_wash": ["washing the car", 3.00],
	"rake": ["raking the leaves", 1.50],
}

## Which family each car belongs to (for "Wash the Car").
const CAR_FAMILY := {"wagon": "jamie", "hatchback": "jamie", "pickup": "garcias", "sedan": "nguyens", "van": "hendersons",
	"convertible": "parkers"}


static func pay(chore: String) -> float:
	return float(LIST.get(chore, ["", 0.0])[1])


static func title(chore: String) -> String:
	return String(LIST.get(chore, ["a chore", 0.0])[0])


## Turn the household jobs into chores (after content.gd filled everything in).
static func apply(objects: Dictionary) -> void:
	for key in objects:
		var o: SmartObject = objects[key]
		var k := o.kind
		if o is Car and CAR_FAMILY.has(String(key)):
			o.set_meta("family", CAR_FAMILY[key])
		for a: Activity in o.activities:
			match a.title:
				"Wash the Dishes":
					_make(a, "dishes")
				"Do the Laundry":
					_make(a, "laundry")
				"Wash the Car":
					_make(a, "car_wash")
				"Help in the Garden":
					_make(a, "garden")
				"Check the Mail":
					a.title = "Get the Mail"
					_make(a, "mail")
			if a.title.begins_with("Feed "):
				_make(a, "feed_pet")
		if o.home == "town" or o.home == "":
			if k != "mailbox" and k != "trash_cans" and k != "mower":
				continue
		var a2: Activity
		match k:
			"mailbox":
				if o.activities.is_empty():
					a2 = Activity.make("Get the Mail", 4, {"fun": 30.0}, "reach")
					a2.sound = "mailbox"
					a2.from_hour = 11.0
					a2.to_hour = 20.0
					a2.messages = ["A catalog, a coupon book and a bill. Mostly bills.", "A postcard from Niagara Falls!", "Your magazine came!"]
					_make(a2, "mail")
					o.activities.append(a2)
			"trash_cans":
				a2 = Activity.make("Take Out the Trash", 10, {"fun": -4.0}, "reach")
				a2.sound = "trash"
				a2.messages = ["You drag the cans down to the curb. Something in there smells like old tuna.", "Clang! The lid falls off. Classic."]
				_make(a2, "trash")
				o.activities.append(a2)
			"mower":
				a2 = Activity.make("Mow the Lawn", 45, {"fun": -8.0, "energy": -10.0}, "reach")
				a2.loop_sound = "mower"
				a2.loop_db = -10.0
				a2.from_hour = 9.0
				a2.to_hour = 19.0
				a2.messages = ["Back and forth, back and forth. You make stripes like a baseball field.", "The mower coughs, sputters... and starts!"]
				_make(a2, "mow")
				o.activities.append(a2)
			"bed":
				a2 = Activity.make("Make Your Bed", 5, {"fun": -2.0}, "reach")
				a2.from_hour = 6.0
				a2.to_hour = 14.0
				_make(a2, "bed")
				o.activities.append(a2)
			"table":
				a2 = Activity.make("Set the Table", 5, {"social": 6.0}, "reach")
				a2.from_hour = 16.5
				a2.to_hour = 19.0
				_make(a2, "table")
				o.activities.append(a2)
			"couch":
				a2 = Activity.make("Vacuum the Living Room", 20, {"fun": -6.0}, "reach")
				a2.loop_sound = "microwave"
				a2.loop_db = -12.0
				a2.messages = ["You find 35 cents in the couch cushions. Finders keepers!", "Vrrrrrm. The cat runs for its life."]
				_make(a2, "vacuum")
				o.activities.append(a2)
			"pet_dog":
				a2 = Activity.make("Take %s for a Walk" % o.display_name, 30, {"fun": 24.0, "energy": -6.0, "social": 10.0}, "stand")
				a2.messages = ["%s sniffs every single mailbox on the block." % o.display_name, "%s tries to chase a squirrel. You hold on tight!" % o.display_name]
				_make(a2, "walk_dog")
				o.activities.append(a2)
	# Jamie's own bed and dining table were set up by hand: give them chores too
	for key in ["bed", "dining_table", "couch"]:
		var jo: SmartObject = objects.get(key)
		if jo == null:
			continue
		var a3: Activity
		match key:
			"bed":
				a3 = Activity.make("Make Your Bed", 5, {"fun": -2.0}, "reach")
				a3.from_hour = 6.0
				a3.to_hour = 14.0
				_make(a3, "bed")
			"dining_table":
				a3 = Activity.make("Set the Table", 5, {"social": 6.0}, "reach")
				a3.from_hour = 16.5
				a3.to_hour = 19.0
				_make(a3, "table")
			"couch":
				a3 = Activity.make("Vacuum the Living Room", 20, {"fun": -6.0}, "reach")
				a3.loop_sound = "microwave"
				a3.loop_db = -12.0
				_make(a3, "vacuum")
		jo.activities.append(a3)


static func _make(a: Activity, chore: String) -> void:
	a.chore = chore
	a.money = 0.0
	a.autonomous = false
