class_name Content
extends RefCounted
## Game content as data: what each object offers, and the Memory Moments.
## To add an activity, copy one of the blocks below.

const MEMORIES := {
	"cartoons": ["Saturday Morning Cartoons",
		"Cereal in your lap, the house still asleep, and a theme song you'll hum for thirty years."],
	"cereal": ["The Prize at the Bottom",
		"You dig past the flakes for the little plastic toy. Totally worth it."],
	"phone_cord": ["The Long Phone Cord",
		"Stretched all the way around the corner for a little privacy."],
	"stars": ["Glow-in-the-Dark Stars",
		"You count the plastic stars on the ceiling until you drift off."],
	"summer": ["Summer Afternoon",
		"Lemonade, a lawn mower somewhere down the street, and nowhere you have to be."],
	"diary": ["Dear Diary",
		"Some things you can only tell a little book with a tiny lock."],
	"mixtape": ["The Perfect Mixtape",
		"Finger on PAUSE, waiting for the DJ to stop talking so you can catch the song clean."],
	"popcorn": ["Microwave Popcorn",
		"Standing guard at the microwave, counting the seconds between pops."],
	"dinner": ["Family Dinner",
		"Elbows off the table. Dad tells the same story again, and everybody laughs anyway."],
	"drive": ["Behind the Wheel",
		"Windows down, the radio up, and the whole neighborhood rolling by."],
	"pancakes": ["Weekend Pancakes",
		"Mickey Mouse pancakes that come out looking more like a cloud. Still perfect."],
	"hoops": ["Driveway Hoops",
		"Three... two... one... at the buzzer! The crowd (you) goes wild."],
	"arcade": ["A Quarter on the Glass",
		"You line your quarter up on the screen. That means you've got next."],
	"pizza": ["Pizza Night",
		"Red cups, a red-checked tablecloth, and the pizza arrives still sizzling in its pan."],
	"diner": ["Breakfast at the Diner",
		"A stack of pancakes, the bacon sizzling behind the counter, and a waitress who calls you \"hon.\""],
	"library": ["Your First Library Card",
		"Your name, typed on a little card. Now every book in here is yours to borrow."],
	"video": ["Friday Night at the Video Store",
		"Wandering the aisles, judging every movie by its cover. The new releases are always checked out."],
	"attic": ["Treasures in the Attic",
		"Mom's old prom dress, Dad's baseball cards, and a photo of Grandpa with a whole lot of hair."],
	"presents": ["The Hidden Presents",
		"Wrapped boxes behind the shoes in the closet. You didn't see anything. Nope."],
	"paperroute": ["Your First Paycheck",
		"Up before the sun, ink on your fingers, and four whole dollars that are all yours."],
	"lemonade": ["Lemonade on a Hot Day",
		"Too much sugar, not enough lemon, served in a paper cup. Perfect."],
	"icecream": ["Brain Freeze",
		"Soft-serve dripping down the cone faster than you can lick it."],
	"allowance": ["Allowance Day",
		"A crumpled dollar bill and a lecture about saving. You're rich!"],
	"basement": ["The Rec Room",
		"Wood paneling, a buzzing light, and the best hangout in the whole house."],
	"drivein": ["Under the Stars", "A double feature at the Starlite Drive-In. The speaker crackled and the popcorn was perfect."],
	"pets": ["Best Friend", "The family pet, curled up next to you like you're the best thing in the world."],
	"christmas": ["Christmas Morning", "Paper everywhere, the tree lights blinking, and the best present ever."],
	"fireworks": ["The Fourth of July", "Red, white and blue fireworks booming over Maple Street, everyone on their blankets."],
	"newyear": ["Happy New Year!", "Staying up past midnight for the very first time, fireworks popping in the cold."],
	"thanksgiving": ["Thanksgiving Dinner", "Turkey, stuffing, cranberry from a can, and pie. You're so full."],
	"burglar": ["Caught Red-Handed", "A burglar, in YOUR house, and you stopped him. The Gazette's going to want an interview."],
	"bike": ["Your Very Own Bike", "Saved every quarter, and now it's yours: chrome, pegs and a bell that goes ring-ring."],
	"cannonball": ["CANNONBALL!", "Knees up, eyes shut, and the biggest splash Maple Street has ever seen."],
	"gamekid": ["Falling Blocks Forever", "You play under the covers until the batteries die. Then you borrow the ones from the remote."],
	"computer": ["Your Very Own Computer", "A blinking cursor, a whole world inside a beige box, and Mom asking if it's for homework."],
	"skate": ["Drop In", "Your heart pounds at the top of the ramp. Then you go. And you land it."],
	"payphone": ["A Quarter and a Payphone", "\"Mom? Can you come get me?\" The world before cell phones."],
	"bowling": ["Rented Shoes", "Gutter, gutter, STRIKE. The ugly shoes were worth it."],
	"burger": ["The Toy in the Meal", "A burger, fries, a shake, and a tiny plastic rocket you'll keep for years."],
	"carnival": ["Top of the Ferris Wheel", "The whole town spread out below you, lit up like a birthday cake."],
	"circus": ["Under the Big Top", "The lights go down, the drumroll starts, and a man flies through the air."],
	"easter": ["The Egg Hunt", "Plastic grass everywhere, a basket full of eggs, and chocolate before breakfast."],
	"halloween": ["Trick or Treat", "A pillowcase full of candy and a costume your mom made out of a bedsheet."],
	"valentine": ["Be Mine", "A valentine with no name on it. You think about it for WEEKS."],
	"snowman": ["Snow Day", "Carrot nose, button eyes, and mittens soaked through. Best day ever."],
	"sprinkler": ["Through the Sprinkler", "Shrieking, soaked, and the grass stuck to your feet."],
	"leafpile": ["The Leaf Pile", "Crunch! You disappear into the pile Dad spent all afternoon raking."],
	"mall": ["Mall Rat", "The fountain, the food court, and nowhere to be. The mall is the center of the universe."],
	"football": ["Under the Friday Lights", "The field smells like cut grass, and for a second you can hear the crowd."],
	"school": ["Summer School", "Sharpened pencils, the hum of the lights, and the clock that never moves."],
	"school_year": ["A School Day", "The bell, the hallway rush, and the smell of a brand-new box of crayons."],
	"middle_school": ["Middle School", "Lockers with combinations, changing classes, and feeling very grown up."],
	"high_school": ["The Big Kids' School", "You sat in on a high school class. Nobody even asked who you were."],
	"band": ["The School Band", "A drum solo nobody asked for. Everybody clapped anyway."],
	"computer_lab": ["Computer Class", "Green letters on a black screen, and you made it say HELLO a thousand times."],
	"typing": ["Typing Class", "Clack clack clack DING. Home row, never look at the keys."],
	"firehouse": ["Down the Fire Pole", "Whoosh! The firefighters let you slide down the pole. Just like the real thing."],
	"cookout": ["Backyard Cookout", "Hot dogs off the grill, a paper plate that's too floppy, and fireflies at dusk."],
	"stargazing": ["Stars Through the Telescope",
		"You find the Big Dipper, then Saturn's rings, tiny and perfect."],
	"delivery": ["Pizza Delivery",
		"The doorbell rings, and the whole house smells like pizza before the box is even open."],
}

## Things townspeople tell you when you ask what's new.
const TIPS := [
	"The Gazette is looking for a paper carrier. Go see Mr. Gruber on Main Street, early in the morning.",
	"Frosty's ice cream stand opens at noon. The banana split is worth every penny.",
	"Rewind Video got a new shipment of tapes in. Bring 'em back on time, or it's late fees!",
	"Molly Parker's selling lemonade in her backyard. Quarter a cup!",
	"Somebody got the high score on Astro Blaster at Pixel Palace. Was it you?",
	"The library's got a summer reading list. Free books, kid. FREE.",
	"Pizza Peak delivers now. Just call 'em from your kitchen phone.",
	"The Sunrise Diner does pancakes till 11. Get there early on Saturdays.",
	"Ask your folks for your allowance. A dollar buys a lot of candy.",
]

const MOVIES := ["Laser Ninjas II", "Mall Monster", "The Time Racer", "Summer Camp Panic", "Robo Partner",
	"Neon Knights", "Grandma's Got a Jetpack", "Planet of the Pets", "Revenge of the Lunch Lady", "Space Cadets 3"]
const BOOKS := ["The Haunted Lighthouse", "Robots of Mars", "Horse Camp Summer", "The Secret Club Mysteries #4",
	"Dinosaur Detectives", "The Boy Who Shrank the School", "Treasure of Skull Cove", "My Brother the Werewolf"]


static func fill(objects: Dictionary) -> void:
	var a: Activity

	# --- TV (you watch it from the couch) ---
	var tv: SmartObject = objects["tv"]
	a = Activity.make("Watch Saturday Cartoons", 90, {"fun": 46.0, "energy": -1.0}, "sit")
	a.from_hour = 7.0
	a.to_hour = 11.0
	a.weekdays = [6]
	a.memory_id = "cartoons"
	a.tv_on = true
	tv.activities.append(a)
	a = Activity.make("Watch TV", 60, {"fun": 32.0, "energy": -1.0}, "sit")
	a.tv_on = true
	tv.activities.append(a)
	a = Activity.make("Catch the Late Movie", 120, {"fun": 38.0, "energy": -3.0}, "sit")
	a.from_hour = 21.0
	a.tv_on = true
	tv.activities.append(a)

	# --- Couch ---
	var couch: SmartObject = objects["couch"]
	couch.activities.append(Activity.make("Take a Nap", 60, {"energy": 44.0}, "lie"))
	couch.activities.append(Activity.make("Sit and Daydream", 20, {"fun": 8.0, "energy": 10.0}, "sit"))

	# --- Fridge ---
	var fridge: SmartObject = objects["fridge"]
	fridge.activities.append(Activity.make("Grab a Snack", 15, {"hunger": 120.0}, "reach"))
	a = Activity.make("Bowl of Cereal", 20, {"hunger": 150.0, "fun": 10.0}, "reach")
	a.from_hour = 6.0
	a.to_hour = 11.0
	a.memory_id = "cereal"
	fridge.activities.append(a)
	fridge.activities.append(Activity.make("Make a Sandwich", 30, {"hunger": 140.0}, "reach"))

	# --- Wall phone ---
	var phone: SmartObject = objects["phone"]
	a = Activity.make("Call Danny", 30, {"social": 72.0, "fun": 12.0}, "phone")
	a.busy_after_hour = 19.0
	a.memory_id = "phone_cord"
	phone.activities.append(a)
	a = Activity.make("Call Grandma", 20, {"social": 55.0}, "phone")
	a.from_hour = 9.0
	a.to_hour = 20.0
	phone.activities.append(a)

	# --- Outside: the picnic table, the mailbox, the neighbors ---
	var picnic: SmartObject = objects["picnic"]
	a = Activity.make("Sit and Relax", 30, {"fun": 24.0, "energy": 10.0}, "sit")
	a.surface = 0.44
	picnic.activities.append(a)
	a = Activity.make("Watch the Clouds", 45, {"fun": 30.0, "energy": 6.0}, "sit")
	a.surface = 0.44
	a.memory_id = "summer"
	a.bonus_from = 13.0      # a nice afternoon pulls Jamie outside
	a.bonus_to = 17.5
	a.bonus_amount = 9.0
	a.from_hour = 8.0
	a.to_hour = 19.5
	picnic.activities.append(a)
	var mailbox: SmartObject = objects["mailbox"]
	a = Activity.make("Check the Mail", 4, {"fun": 40.0}, "reach")
	a.sound = "mailbox"
	a.bonus_from = 11.0      # the mail comes around noon
	a.bonus_to = 14.0
	a.bonus_amount = 7.0
	a.messages = [
		"A department store catalog and a coupon for two-for-one pizza.",
		"A postcard from Grandma in Florida! She says it's hot.",
		"Just bills for Mom and Dad. Boring.",
		"The new issue of your video game magazine came!",
		"A chain letter. Mom says don't bother.",
	]
	mailbox.activities.append(a)
	fill_by_kind(objects)
	_fill_holidays(objects)

	# --- Doors between levels: the attics and basements (every house) ---
	for key in objects:
		var o: SmartObject = objects[key]
		if o.portal_to == null:
			continue
		var going_up := String(key).ends_with("attic_door") or String(key).ends_with("basement_exit")
		var where := ""
		if String(key).ends_with("stairs_up"):
			where = "Go Upstairs"
		elif String(key).ends_with("stairs_down"):
			where = "Go Downstairs"
		elif String(key).ends_with("attic_door"):
			where = "Go Up to the Attic"
		elif String(key).ends_with("basement_door"):
			where = "Go Down to the Basement"
		else:
			where = "Go Back Downstairs" if going_up == false else "Go Back Upstairs"
		a = Activity.make(where, 1, {}, "stand")
		a.teleport = true
		a.autonomous = false
		a.sound = "door_open"
		o.activities.append(a)

	# --- Bedroom: bed ---
	var bed: SmartObject = objects["bed"]
	a = Activity.make("Go to Sleep", 600, {"energy": 14.0, "fun": 4.5, "social": 2.5}, "lie")
	a.surface = 0.55
	a.until_rested = true
	a.from_hour = 19.0
	a.to_hour = 6.0
	a.bonus_from = 22.0
	a.bonus_to = 5.0
	a.memory_id = "stars"
	bed.activities.append(a)
	a = Activity.make("Take a Nap", 60, {"energy": 44.0}, "lie")
	a.surface = 0.55
	bed.activities.append(a)

	# --- Bedroom: desk and diary ---
	var desk: SmartObject = objects["desk"]
	a = Activity.make("Write in Your Diary", 30, {"fun": 30.0, "social": 10.0}, "sit")
	a.ui = "diary"
	a.memory_id = "diary"
	desk.activities.append(a)
	a = Activity.make("Read Old Diary Entries", 15, {"fun": 24.0}, "sit")
	a.ui = "diary"
	a.autonomous = false
	desk.activities.append(a)

	# --- Bedroom: dresser ---
	var dresser: SmartObject = objects["dresser"]
	a = Activity.make("Change Your Clothes & Hair", 5, {"fun": 10.0}, "reach")
	a.autonomous = false
	a.customize = true
	dresser.activities.append(a)

	_fill_more(objects)
	_fill_town(objects)

	# The couch nap lies along the couch, head on the pillow.
	var nap: Activity = (objects["couch"] as SmartObject).activities[0]
	nap.face_point = Vector3(6.5, 0.5, 4.45)



## Everything added in v1.0.5: the kitchen and dining room, the stereo,
## records and books, backyard games, and the cars.
static func _fill_more(objects: Dictionary) -> void:
	var a: Activity

	# --- Kitchen: microwave ---
	if objects.has("microwave"):
		var mw: SmartObject = objects["microwave"]
		a = Activity.make("Heat Up Leftovers", 15, {"hunger": 130.0}, "reach")
		a.loop_sound = "microwave"
		a.loop_db = -10.0
		a.end_sound = "microwave_beep"
		a.glow = "microwave_mat"
		mw.activities.append(a)
		a = Activity.make("Make Microwave Popcorn", 20, {"hunger": 70.0, "fun": 40.0}, "reach")
		a.loop_sound = "popcorn"
		a.loop_db = -8.0
		a.end_sound = "microwave_beep"
		a.glow = "microwave_mat"
		a.memory_id = "popcorn"
		a.bonus_from = 19.0
		a.bonus_to = 23.0
		a.bonus_amount = 4.0
		mw.activities.append(a)

	# --- Kitchen: sink ---
	if objects.has("sink"):
		var sk: SmartObject = objects["sink"]
		a = Activity.make("Get a Glass of Water", 5, {"hunger": 60.0, "energy": 30.0}, "reach")
		a.loop_sound = "water"
		a.loop_db = -12.0
		sk.activities.append(a)
		a = Activity.make("Wash the Dishes", 30, {"fun": -6.0}, "reach")
		a.loop_sound = "water"
		a.loop_db = -12.0
		a.money = 1.5
		a.message = "Mom said she'd pay you $1.50 to do the dishes."
		a.autonomous = false
		sk.activities.append(a)

	# --- Kitchen: stove ---
	if objects.has("stove"):
		var stv: SmartObject = objects["stove"]
		a = Activity.make("Cook Mac & Cheese", 30, {"hunger": 170.0, "fun": 8.0}, "reach")
		a.loop_sound = "sizzle"
		a.loop_db = -14.0
		a.glow = "burner_mat"
		a.from_hour = 11.0
		a.to_hour = 22.0
		stv.activities.append(a)
		a = Activity.make("Make Pancakes", 35, {"hunger": 180.0, "fun": 20.0}, "reach")
		a.loop_sound = "sizzle"
		a.loop_db = -12.0
		a.glow = "burner_mat"
		a.from_hour = 7.0
		a.to_hour = 12.0
		a.weekdays = [0, 6]
		a.memory_id = "pancakes"
		stv.activities.append(a)

	# --- Kitchen: cookie jar ---
	if objects.has("cookie_jar"):
		a = Activity.make("Sneak a Cookie", 3, {"hunger": 220.0, "fun": 120.0}, "reach")
		a.messages = [
			"Chocolate chip. Nobody saw a thing.",
			"Oatmeal raisin... the cookie jar's way of saying no.",
			"Mom's voice from somewhere: \"That better not be the cookie jar!\"",
			"Last one! Better put the lid back quietly.",
		]
		(objects["cookie_jar"] as SmartObject).activities.append(a)

	# --- Dining room table ---
	if objects.has("dining_table"):
		var tb: SmartObject = objects["dining_table"]
		a = Activity.make("Eat Dinner with the Family", 45, {"hunger": 160.0, "social": 70.0}, "sit")
		a.from_hour = 17.0
		a.to_hour = 20.0
		a.memory_id = "dinner"
		a.bonus_from = 17.5
		a.bonus_to = 19.0
		a.bonus_amount = 12.0
		tb.activities.append(a)
		a = Activity.make("Play a Board Game", 60, {"fun": 40.0, "social": 30.0}, "sit")
		tb.activities.append(a)
		a = Activity.make("Work on a Jigsaw Puzzle", 45, {"fun": 30.0}, "sit")
		tb.activities.append(a)
		a = Activity.make("Do Homework", 40, {"fun": -10.0, "energy": -4.0}, "sit")
		a.money = 1.0
		a.message = "Dad pays a dollar for finished homework. Fractions, ugh."
		a.autonomous = false
		tb.activities.append(a)

	# --- Living room: stereo, recliner, bookshelf ---
	if objects.has("stereo"):
		var st: SmartObject = objects["stereo"]
		a = Activity.make("Listen to Records", 45, {"fun": 40.0, "energy": 4.0}, "stand")
		a.loop_sound = "vinyl"
		a.loop_db = -9.0
		a.glow = "record_mat"
		st.activities.append(a)
		a = Activity.make("Make a Mixtape off the Radio", 60, {"fun": 44.0}, "reach")
		a.loop_sound = "vinyl"
		a.loop_db = -12.0
		a.glow = "record_mat"
		a.memory_id = "mixtape"
		st.activities.append(a)
		a = Activity.make("Dance Like Nobody's Watching", 20, {"fun": 60.0, "energy": -20.0}, "dance")
		a.loop_sound = "vinyl"
		a.loop_db = -8.0
		a.glow = "record_mat"
		st.activities.append(a)
	if objects.has("recliner"):
		var rc: SmartObject = objects["recliner"]
		a = Activity.make("Kick Back in Dad's Chair", 30, {"energy": 26.0, "fun": 14.0}, "sit")
		a.surface = 0.48
		rc.activities.append(a)
		a = Activity.make("Doze Off", 45, {"energy": 46.0}, "sit")
		a.surface = 0.48
		rc.activities.append(a)
	if objects.has("bookshelf"):
		var bk: SmartObject = objects["bookshelf"]
		a = Activity.make("Read a Choose-Your-Own-Adventure", 40, {"fun": 34.0}, "stand")
		a.messages = [
			"Turn to page 47 if you open the door. You opened the door. You died. Back to page 46...",
			"You find the secret passage on the first try. Nice.",
			"You keep a finger in four different pages, just in case.",
		]
		bk.activities.append(a)
		a = Activity.make("Look Something Up in the Encyclopedia", 20, {"fun": 16.0}, "stand")
		a.messages = ["Volume D: Dinosaurs. You lose an hour to the pictures.",
			"Volume S: Space Shuttle. Someday!",
			"Volume B: Bermuda Triangle. Creepy."]
		bk.activities.append(a)

	# --- Bedroom ---
	if objects.has("dresser"):
		var dr: SmartObject = objects["dresser"]
		a = Activity.make("Play a Mixtape on the Boombox", 30, {"fun": 34.0}, "stand")
		a.loop_sound = "music_house"
		a.loop_db = -10.0
		dr.activities.append(a)
		a = Activity.make("Dance in Front of the Mirror", 20, {"fun": 56.0, "energy": -18.0}, "dance")
		a.loop_sound = "music_house"
		a.loop_db = -8.0
		dr.activities.append(a)
	if objects.has("desk"):
		a = Activity.make("Solve the Puzzle Cube", 30, {"fun": 28.0}, "sit")
		a.messages = ["One side done! Only five to go.",
			"You peel off a sticker. It's not cheating if nobody knows.",
			"Almost... almost... nope."]
		(objects["desk"] as SmartObject).activities.append(a)
	if objects.has("bean_bag"):
		var bb: SmartObject = objects["bean_bag"]
		a = Activity.make("Read Comic Books", 40, {"fun": 38.0, "energy": 8.0}, "read")
		a.surface = 0.3
		bb.activities.append(a)
		a = Activity.make("Play a Handheld LCD Game", 30, {"fun": 42.0}, "read")
		a.surface = 0.3
		a.messages = ["Beep boop. New high score: 0347!", "Game over. One more try...", "The batteries are almost dead."]
		bb.activities.append(a)
	if objects.has("photos"):
		a = Activity.make("Look at Family Photos", 5, {"social": 30.0}, "stand")
		a.messages = [
			"Your school picture. The laser background was a choice.",
			"Mom and Dad's wedding. Dad had so much hair!",
			"The family trip to the lake. Everyone's squinting.",
		]
		(objects["photos"] as SmartObject).activities.append(a)

	# --- Backyard and driveway ---
	if objects.has("grill"):
		a = Activity.make("Grill Burgers", 40, {"hunger": 170.0, "social": 20.0}, "reach")
		a.loop_sound = "sizzle"
		a.loop_db = -6.0
		a.glow = "coals_mat"
		a.from_hour = 11.0
		a.to_hour = 20.5
		(objects["grill"] as SmartObject).activities.append(a)
	if objects.has("tire_swing"):
		a = Activity.make("Swing on the Tire Swing", 25, {"fun": 44.0}, "sit")
		a.surface = 0.6
		a.from_hour = 7.0
		a.to_hour = 20.5
		(objects["tire_swing"] as SmartObject).activities.append(a)
	if objects.has("hoop"):
		a = Activity.make("Shoot Hoops", 40, {"fun": 46.0, "energy": -14.0}, "hoops")
		a.loop_sound = "basketball"
		a.loop_db = -6.0
		a.memory_id = "hoops"
		a.from_hour = 7.0
		a.to_hour = 21.0
		(objects["hoop"] as SmartObject).activities.append(a)
	for key in ["lawn_chair", "lawn_chair_2"]:
		if objects.has(key):
			a = Activity.make("Sunbathe", 40, {"energy": 30.0, "fun": 18.0}, "sit")
			a.surface = 0.39
			a.from_hour = 9.0
			a.to_hour = 18.0
			(objects[key] as SmartObject).activities.append(a)
			a = Activity.make("Sit and Relax", 20, {"energy": 16.0, "fun": 8.0}, "sit")
			a.surface = 0.39
			(objects[key] as SmartObject).activities.append(a)

	# --- The cars ---
	for key in ["wagon", "hatchback"]:
		if objects.has(key):
			a = Activity.make("Go for a Drive", 60, {"fun": 30.0}, "stand")
			a.drive = true
			a.autonomous = false
			a.memory_id = "drive"
			(objects[key] as SmartObject).activities.append(a)
			a = Activity.make("Wash the Car", 40, {"fun": 6.0}, "reach")
			a.loop_sound = "water"
			a.loop_db = -10.0
			a.money = 3.0
			a.message = "Dad pays $3 for a car wash. Don't miss the hubcaps!"
			a.autonomous = false
			a.from_hour = 8.0
			a.to_hour = 19.0
			(objects[key] as SmartObject).activities.append(a)


## Everything to do in a neighbor's house (an online player's home).
## Everything in the houses, by kind of thing. (Only for things that don't have
## their own activities already, like Jamie's original rooms.)
static func fill_by_kind(objects: Dictionary) -> void:
	for key in objects:
		var o: SmartObject = objects[key]
		if not o.activities.is_empty():
			continue
		var acts := _kind_activities(o, String(key))
		for act in acts:
			o.activities.append(act)


static func _family_of(home: String) -> String:
	return NeighborBuilder.HOMES[home]["family"] if NeighborBuilder.HOMES.has(home) else ""


static func _kind_activities(o: SmartObject, key: String) -> Array:
	var out := []
	var a: Activity
	match o.kind:
		"tv":
			a = Activity.make("Watch Saturday Cartoons", 90, {"fun": 46.0, "energy": -1.0}, "sit")
			a.from_hour = 7.0
			a.to_hour = 11.0
			a.weekdays = [6]
			a.memory_id = "cartoons"
			a.tv_on = true
			out.append(a)
			a = Activity.make("Watch TV", 60, {"fun": 32.0, "energy": -1.0}, "sit")
			a.tv_on = true
			out.append(a)
			a = Activity.make("Catch the Late Movie", 120, {"fun": 38.0, "energy": -3.0}, "sit")
			a.from_hour = 21.0
			a.tv_on = true
			out.append(a)
		"couch":
			a = Activity.make("Take a Nap", 60, {"energy": 44.0}, "lie")
			if o.has_meta("nap_face"):
				a.face_point = o.get_meta("nap_face")
			out.append(a)
			out.append(Activity.make("Sit and Daydream", 20, {"fun": 8.0, "energy": 10.0}, "sit"))
		"fridge":
			out.append(Activity.make("Grab a Snack", 15, {"hunger": 120.0}, "reach"))
			a = Activity.make("Bowl of Cereal", 20, {"hunger": 150.0, "fun": 10.0}, "reach")
			a.from_hour = 6.0
			a.to_hour = 11.0
			a.memory_id = "cereal"
			out.append(a)
			out.append(Activity.make("Make a Sandwich", 30, {"hunger": 140.0}, "reach"))
		"sink":
			a = Activity.make("Get a Glass of Water", 5, {"hunger": 60.0, "energy": 30.0}, "reach")
			a.loop_sound = "water"
			a.loop_db = -12.0
			out.append(a)
			a = Activity.make("Wash the Dishes", 30, {"fun": -6.0}, "reach")
			a.loop_sound = "water"
			a.loop_db = -12.0
			a.money = 1.5
			a.autonomous = false
			out.append(a)
		"stove":
			a = Activity.make("Cook Mac & Cheese", 30, {"hunger": 170.0, "fun": 8.0}, "reach")
			a.loop_sound = "sizzle"
			a.loop_db = -14.0
			a.glow = key + "_mat"
			a.from_hour = 11.0
			a.to_hour = 22.0
			out.append(a)
			a = Activity.make("Make Pancakes", 35, {"hunger": 180.0, "fun": 20.0}, "reach")
			a.loop_sound = "sizzle"
			a.loop_db = -12.0
			a.glow = key + "_mat"
			a.from_hour = 7.0
			a.to_hour = 12.0
			a.weekdays = [0, 6]
			a.memory_id = "pancakes"
			out.append(a)
		"table":
			var fam := _family_of(o.home)
			a = Activity.make("Eat Dinner with the %s" % ("Family" if fam == "" else fam + "s"), 45, {"hunger": 160.0, "social": 70.0}, "sit")
			a.from_hour = 17.0
			a.to_hour = 20.0
			a.memory_id = "dinner"
			a.bonus_from = 17.5
			a.bonus_to = 19.0
			a.bonus_amount = 12.0
			out.append(a)
			out.append(Activity.make("Play a Board Game", 60, {"fun": 40.0, "social": 30.0}, "sit"))
			a = Activity.make("Do Homework", 40, {"fun": -10.0, "energy": -4.0}, "sit")
			a.money = 1.0
			a.autonomous = false
			out.append(a)
		"picnic":
			a = Activity.make("Have a Picnic Lunch", 30, {"hunger": 120.0, "fun": 20.0}, "sit")
			a.from_hour = 11.0
			a.to_hour = 18.0
			out.append(a)
			out.append(Activity.make("Sit and Relax", 30, {"fun": 20.0, "energy": 10.0}, "sit"))
		"bed":
			a = Activity.make("Go to Sleep", 600, {"energy": 14.0, "fun": 4.5, "social": 2.5}, "lie")
			a.surface = 0.55
			a.until_rested = true
			a.from_hour = 19.0
			a.to_hour = 6.0
			a.bonus_from = 22.0
			a.bonus_to = 5.0
			out.append(a)
			a = Activity.make("Take a Nap", 60, {"energy": 44.0}, "lie")
			a.surface = 0.55
			out.append(a)
		"parents_bed":
			a = Activity.make("Jump on Mom & Dad's Bed", 10, {"fun": 60.0, "energy": -10.0}, "stand")
			a.messages = ["Boing! Boing! ...Was that the door?", "You bounce so high you almost touch the ceiling fan."]
			a.autonomous = false
			out.append(a)
			a = Activity.make("Snuggle Up After a Bad Dream", 30, {"energy": 30.0, "social": 40.0}, "lie")
			a.surface = 0.55
			a.from_hour = 21.0
			a.to_hour = 6.0
			a.autonomous = false
			out.append(a)
		"desk":
			a = Activity.make("Write in Your Diary", 30, {"fun": 30.0, "social": 10.0}, "sit")
			a.ui = "diary"
			a.memory_id = "diary"
			out.append(a)
			a = Activity.make("Solve the Puzzle Cube", 30, {"fun": 28.0}, "sit")
			a.messages = ["One side done! Only five to go.", "Almost... almost... nope."]
			out.append(a)
		"dresser":
			a = Activity.make("Change Your Clothes & Hair", 5, {"fun": 10.0}, "reach")
			a.customize = true
			a.autonomous = false
			out.append(a)
			a = Activity.make("Dance in Front of the Mirror", 20, {"fun": 56.0, "energy": -18.0}, "dance")
			a.loop_sound = "music_house"
			a.loop_db = -10.0
			out.append(a)
		"bookshelf":
			out.append(Activity.make("Read a Book", 40, {"fun": 34.0}, "stand"))
		"stereo":
			a = Activity.make("Listen to Records", 45, {"fun": 40.0, "energy": 4.0}, "stand")
			a.loop_sound = "vinyl"
			a.loop_db = -9.0
			out.append(a)
		"phone":
			a = Activity.make("Call a Friend", 30, {"social": 72.0, "fun": 12.0}, "phone")
			a.busy_after_hour = 19.0
			a.memory_id = "phone_cord"
			out.append(a)
			a = Activity.make("Call Grandma", 20, {"social": 55.0}, "phone")
			a.from_hour = 9.0
			a.to_hour = 20.0
			out.append(a)
		"tub":
			a = Activity.make("Take a Bubble Bath", 30, {"energy": 30.0, "fun": 20.0}, "lie")
			a.surface = 0.2
			a.loop_sound = "water"
			a.loop_db = -16.0
			out.append(a)
			a = Activity.make("Take a Shower", 15, {"energy": 40.0}, "stand")
			a.loop_sound = "water"
			a.loop_db = -10.0
			a.from_hour = 6.0
			a.to_hour = 11.0
			a.bonus_from = 6.5
			a.bonus_to = 9.0
			a.bonus_amount = 6.0
			out.append(a)
		"toilet":
			a = Activity.make("Use the Bathroom", 5, {"fun": 6.0}, "sit")
			a.surface = 0.45
			a.messages = ["You read the back of the shampoo bottle. Twice.", "Flush! And wash your hands."]
			out.append(a)
		"bath_sink":
			a = Activity.make("Brush Your Teeth", 5, {"energy": 6.0, "fun": 4.0}, "reach")
			a.loop_sound = "water"
			a.loop_db = -14.0
			a.bonus_from = 20.5
			a.bonus_to = 23.0
			a.bonus_amount = 5.0
			out.append(a)
			a = Activity.make("Fix Your Hair in the Mirror", 5, {"fun": 12.0}, "reach")
			a.customize = true
			a.autonomous = false
			out.append(a)
		"washer":
			a = Activity.make("Do the Laundry", 30, {"fun": -4.0}, "reach")
			a.loop_sound = "microwave"
			a.loop_db = -16.0
			a.money = 1.0
			a.autonomous = false
			a.messages = ["One red sock in with the whites. Uh-oh.", "Everything smells like dryer sheets now."]
			out.append(a)
		"closet":
			a = Activity.make("Snoop in the Closet", 10, {"fun": 40.0}, "reach")
			a.memory_id = "presents"
			a.autonomous = false
			a.messages = ["Dad's bowling shirts. So many bowling shirts.", "A box marked DO NOT OPEN. You don't. (You want to.)"]
			out.append(a)
		"vanity":
			a = Activity.make("Try On Mom's Makeup", 15, {"fun": 40.0}, "sit")
			a.surface = 0.42
			a.autonomous = false
			a.messages = ["Blue eye shadow. A LOT of blue eye shadow.", "You spray the hair spray and it fogs the whole room."]
			out.append(a)
		"trunk":
			a = Activity.make("Dig Through the Old Trunk", 20, {"fun": 44.0}, "reach")
			a.memory_id = "attic"
			a.messages = ["Old yearbooks! Mom had BIG hair.", "A tin of buttons and a pocket watch that doesn't tick.",
				"Grandpa's army jacket. It smells like mothballs."]
			out.append(a)
		"xmas":
			a = Activity.make("Look Through the Holiday Decorations", 15, {"fun": 30.0}, "reach")
			a.messages = ["Tangled lights. Why is it always tangled lights?", "The ornament you made in kindergarten!"]
			out.append(a)
		"rocking_horse":
			out.append(Activity.make("Ride the Old Rocking Horse", 15, {"fun": 30.0}, "sit"))
		"telescope":
			a = Activity.make("Look at the Stars", 30, {"fun": 50.0}, "stand")
			a.from_hour = 20.0
			a.to_hour = 4.0
			a.memory_id = "stargazing"
			out.append(a)
			out.append(Activity.make("Spy on the Neighborhood", 15, {"fun": 26.0}, "stand"))
		"pool_table":
			a = Activity.make("Shoot Pool", 40, {"fun": 50.0, "social": 10.0}, "stand")
			a.memory_id = "basement"
			out.append(a)
		"ping_pong":
			a = Activity.make("Play Ping-Pong", 30, {"fun": 56.0, "energy": -8.0}, "stand")
			a.memory_id = "basement"
			out.append(a)
		"workbench":
			a = Activity.make("Tinker at the Workbench", 40, {"fun": 36.0}, "reach")
			a.messages = ["You build a birdhouse. It's a little crooked.", "You take apart an old radio. Putting it back together is harder."]
			out.append(a)
		"console":
			a = Activity.make("Play the Old Game System", 45, {"fun": 66.0, "energy": -4.0}, "sit")
			a.surface = 0.0
			a.glow = key + "_mat"
			a.loop_sound = "arcade_game"
			a.loop_db = -14.0
			a.memory_id = "basement"
			out.append(a)
		"weights":
			out.append(Activity.make("Lift Weights", 30, {"energy": -20.0, "fun": 20.0}, "reach"))
		"home_arcade":
			a = Activity.make("Play Space Blasters", 20, {"fun": 80.0}, "stand")
			a.glow = key + "_mat"
			a.loop_sound = "arcade_game"
			a.loop_db = -12.0
			out.append(a)
		"swing_set":
			out.append(Activity.make("Swing on the Swing Set", 25, {"fun": 46.0}, "sit"))
		"kiddie_pool":
			a = Activity.make("Splash in the Kiddie Pool", 25, {"fun": 50.0, "energy": 10.0}, "stand")
			a.from_hour = 10.0
			a.to_hour = 19.0
			out.append(a)
		"garden":
			a = Activity.make("Help in the Garden", 30, {"fun": 10.0}, "reach")
			a.money = 0.5
			a.autonomous = false
			a.messages = ["You pull weeds. And maybe a carrot or two.", "A worm! Gross. Cool. Gross."]
			out.append(a)
		"trampoline":
			a = Activity.make("Jump on the Trampoline", 20, {"fun": 60.0, "energy": -14.0}, "hoops")
			out.append(a)
		"npc_parent":
			a = Activity.make("Ask for Your Allowance", 3, {"social": 20.0}, "stand")
			a.talk = "allowance"
			a.autonomous = false
			out.append(a)
			a = Activity.make("Ask What Chores Need Doing", 2, {"social": 10.0}, "stand")
			a.talk = "chores"
			a.autonomous = false
			out.append(a)
			a = Activity.make("Chat", 10, {"social": 45.0}, "stand")
			a.talk = "chat"
			out.append(a)
			a = Activity.make("Get a Hug", 2, {"social": 40.0, "fun": 6.0}, "stand")
			a.messages = ["A big squeeze. You pretend to hate it.", "\"You're getting so big!\""]
			out.append(a)
		"npc_walker":
			a = Activity.make("Say Hi", 5, {"social": 30.0}, "stand")
			a.talk = "chat"
			out.append(a)
			a = Activity.make("Ask What's New in Town", 10, {"social": 40.0, "fun": 6.0}, "stand")
			a.talk = "tip"
			a.autonomous = false
			out.append(a)
		"npc_lemonade":
			a = Activity.make("Buy a Cup of Lemonade", 10, {"hunger": 30.0, "fun": 14.0, "social": 20.0}, "stand")
			a.money = -0.25
			a.from_hour = 10.0
			a.to_hour = 18.0
			a.memory_id = "lemonade"
			a.sound = "cash_register"
			a.messages = ["Molly pours it with great ceremony. It's very sour. It's perfect.",
				"\"Fresh squeezed! Well... fresh from the can.\""]
			out.append(a)
			a = Activity.make("Chat with Molly", 10, {"social": 40.0}, "stand")
			a.talk = "chat"
			out.append(a)
		"npc_icecream":
			for f in [["Get a Soft-Serve Cone", 0.75, 50.0], ["Get a Push-Up Pop", 0.5, 35.0], ["Get a Banana Split", 2.25, 80.0]]:
				a = Activity.make(f[0], 15, {"hunger": f[2], "fun": 24.0}, "stand")
				a.money = -float(f[1])
				a.from_hour = 12.0
				a.to_hour = 21.0
				a.memory_id = "icecream"
				a.sound = "cash_register"
				out.append(a)
			a = Activity.make("Chat with Frosty", 5, {"social": 30.0}, "stand")
			a.talk = "chat"
			out.append(a)
		"npc_clerk":
			a = Activity.make("Chat", 8, {"social": 35.0}, "stand")
			a.talk = "chat"
			out.append(a)
			a = Activity.make("Ask What's New in Town", 10, {"social": 30.0, "fun": 5.0}, "stand")
			a.talk = "tip"
			a.autonomous = false
			out.append(a)
		"npc_snackbar":
			for f in [["Buy a Bucket of Popcorn", 0.75, 45.0], ["Buy a Soda", 0.5, 20.0], ["Buy a Box of Candy", 0.5, 25.0]]:
				a = Activity.make(f[0], 8, {"hunger": f[2], "fun": 10.0}, "stand")
				a.money = -float(f[1])
				a.from_hour = 19.5
				a.to_hour = 1.0
				a.sound = "cash_register"
				a.autonomous = false
				out.append(a)
			a = Activity.make("Chat with Lou", 5, {"social": 30.0}, "stand")
			a.talk = "chat"
			out.append(a)
		"drivein_speaker":
			a = Activity.make("Watch the Double Feature", 150, {"fun": 60.0, "social": 20.0, "energy": -4.0}, "sit")
			a.surface = 0.02
			a.money = -2.0
			a.from_hour = 20.0
			a.to_hour = 1.0
			a.memory_id = "drivein"
			a.messages = ["The monster rises out of the lake. Somebody in a station wagon screams.",
				"Intermission! The dancing hot dog wants you to visit the snack bar.",
				"The speaker crackles. It's the scariest movie ever made. Probably."]
			out.append(a)
			a = Activity.make("Look at the Stars Before the Show", 20, {"fun": 25.0}, "lie")
			a.surface = 0.02
			a.from_hour = 19.5
			a.to_hour = 21.0
			out.append(a)
		"xmas_tree":
			a = Activity.make("Open Your Presents", 30, {"fun": 90.0, "social": 30.0}, "reach")
			a.holidays = ["christmas"]
			a.memory_id = "christmas"
			a.messages = ["A Walkman! With headphones! This is the best Christmas ever.",
				"A Cabbage Patch Kid AND a Nerf ball. Mom and Dad came through.",
				"Socks. ...And under the socks, a Nintendo!"]
			out.append(a)
			a = Activity.make("Admire the Tree", 10, {"fun": 20.0, "social": 10.0}, "stand")
			out.append(a)
			a = Activity.make("Shake the Presents", 5, {"fun": 25.0}, "reach")
			a.autonomous = false
			a.messages = ["It rattles. Definitely a board game.", "Soft. Ugh, clothes."]
			out.append(a)
		"fireworks_blanket":
			a = Activity.make("Watch the Fireworks", 90, {"fun": 70.0, "social": 30.0}, "sit")
			a.surface = 0.03
			a.holidays = ["july4"]
			a.from_hour = 21.0
			a.to_hour = 23.0
			a.memory_id = "fireworks"
			out.append(a)
			a = Activity.make("Watch the New Year's Fireworks", 40, {"fun": 60.0, "social": 20.0}, "sit")
			a.surface = 0.03
			a.holidays = ["newyear"]
			a.from_hour = 0.0
			a.to_hour = 1.0
			a.memory_id = "newyear"
			out.append(a)
			a = Activity.make("Lie on the Blanket", 20, {"energy": 15.0, "fun": 10.0}, "lie")
			a.surface = 0.03
			out.append(a)
		"pet_dog", "pet_cat":
			var nm := o.display_name
			var dog := o.kind == "pet_dog"
			a = Activity.make("Pet %s" % nm, 5, {"social": 30.0, "fun": 20.0}, "reach")
			a.talk = "chat"
			out.append(a)
			if dog:
				a = Activity.make("Play Fetch with %s" % nm, 20, {"fun": 50.0, "energy": -8.0}, "stand")
				a.messages = ["You throw the ball. %s brings back a sock instead." % nm, "Good dog! Who's a good dog?"]
				a.memory_id = "pets"
				out.append(a)
				a = Activity.make("Feed %s" % nm, 5, {"social": 10.0}, "reach")
				a.money = 0.5
				a.autonomous = false
				a.messages = ["Kibble! %s acts like it's the best thing that's ever happened." % nm]
				out.append(a)
			else:
				a = Activity.make("Dangle a String for %s" % nm, 15, {"fun": 40.0}, "reach")
				a.messages = ["%s pounces! Misses. Pretends that was on purpose." % nm]
				a.memory_id = "pets"
				out.append(a)
				a = Activity.make("Feed %s" % nm, 5, {"social": 10.0}, "reach")
				a.money = 0.5
				a.autonomous = false
				a.messages = ["%s eats three bites and walks away." % nm]
				out.append(a)
		"npc_gazette":
			a = Activity.make("Apply for the Paper Route", 10, {"social": 15.0}, "stand")
			a.paper = "apply"
			a.autonomous = false
			out.append(a)
			a = Activity.make("Pick Up Today's Papers", 5, {}, "reach")
			a.paper = "pickup"
			a.from_hour = 6.0
			a.to_hour = 10.0
			a.autonomous = false
			out.append(a)
			a = Activity.make("Quit the Paper Route", 5, {}, "stand")
			a.paper = "quit"
			a.autonomous = false
			out.append(a)
			a = Activity.make("Chat with Mr. Gruber", 10, {"social": 30.0}, "stand")
			a.talk = "chat"
			out.append(a)
		"light_switch":
			a = Activity.make("Flip the Light Switch", 1, {}, "reach")
			a.autonomous = false
			out.append(a)
		"lamp":
			a = Activity.make("Switch the Lamp On or Off", 1, {}, "reach")
			a.autonomous = false
			out.append(a)
		"bike":
			a = Activity.make("Ride Your Bike", 1, {"fun": 10.0}, "reach")
			a.ride = true
			a.autonomous = false
			out.append(a)
		"bike_shop":
			a = Activity.make("Buy a BMX Bike", 10, {"fun": 40.0}, "stand")
			a.money = -60.0
			a.buys = "bike"
			a.autonomous = false
			a.sound = "cash_register"
			a.memory_id = "bike"
			a.from_hour = 10.0
			a.to_hour = 18.0
			out.append(a)
			a = Activity.make("Look at the Bikes", 10, {"fun": 20.0}, "stand")
			a.messages = ["Chrome pegs, mag wheels, a number plate... you NEED this.", "The red one. It's got to be the red one."]
			out.append(a)
		"bike_repair":
			a = Activity.make("Watch Spike Fix a Bike", 15, {"fun": 22.0, "social": 10.0}, "stand")
			a.from_hour = 10.0
			a.to_hour = 18.0
			out.append(a)
		"swim_pool":
			a = Activity.make("Swim in the Pool", 40, {"fun": 60.0, "energy": -10.0}, "swim")
			a.months = [5, 6, 7, 8, 9]
			a.from_hour = 9.0
			a.to_hour = 20.0
			a.loop_sound = "water"
			a.loop_db = -18.0
			out.append(a)
			a = Activity.make("Do a Cannonball!", 5, {"fun": 50.0}, "swim")
			a.months = [5, 6, 7, 8, 9]
			a.from_hour = 9.0
			a.to_hour = 20.0
			a.sound = "splash"
			a.memory_id = "cannonball"
			a.autonomous = false
			out.append(a)
			a = Activity.make("Float on the Inner Tube", 30, {"energy": 30.0, "fun": 30.0}, "lie")
			a.surface = -0.15
			a.months = [5, 6, 7, 8, 9]
			out.append(a)
		"football_field":
			a = Activity.make("Toss the Football Around", 30, {"fun": 44.0, "energy": -12.0, "social": 10.0}, "hoops")
			a.memory_id = "football"
			a.messages = ["A perfect spiral! ...Into the bleachers.", "You go long. LONGER. You trip over the 30-yard line."]
			out.append(a)
			a = Activity.make("Run Laps", 25, {"fun": 10.0, "energy": -20.0}, "stand")
			a.messages = ["Coach blows his whistle. \"Pick up those knees!\""]
			a.sound = "whistle"
			out.append(a)
		"goalpost":
			a = Activity.make("Kick a Field Goal", 10, {"fun": 40.0, "energy": -6.0}, "stand")
			a.messages = ["It's up... it's good! The crowd (one squirrel) goes wild.", "Wide right. Way, WAY wide right.", "Off the upright! So close!"]
			out.append(a)
		"bleachers":
			a = Activity.make("Sit in the Bleachers", 30, {"energy": 20.0, "fun": 12.0}, "sit")
			a.surface = 0.46
			out.append(a)
			a = Activity.make("Cheer for the Mavericks", 15, {"fun": 30.0, "social": 20.0}, "dance")
			a.messages = ["GO, MAVERICKS! ...Nobody's playing, but still!"]
			out.append(a)
		"npc_coach":
			a = Activity.make("Run Drills with Coach", 30, {"fun": 30.0, "energy": -16.0, "social": 30.0}, "stand")
			a.talk = "chat"
			a.sound = "whistle"
			a.memory_id = "football"
			a.from_hour = 8.0
			a.to_hour = 18.0
			out.append(a)
			a = Activity.make("Chat with Coach", 8, {"social": 30.0}, "stand")
			a.talk = "chat"
			out.append(a)
		"chalkboard":
			a = Activity.make("Doodle on the Chalkboard", 15, {"fun": 30.0}, "reach")
			a.messages = ["You draw a dinosaur. It's a pretty good dinosaur.", "You write SCHOOL'S OUT FOR SUMMER in big letters."]
			out.append(a)
		"school_desk":
			# School days September to May; summer school June to August (mornings, Monday to Thursday)
			a = Activity.make("Go to Class", 120, {"fun": -6.0, "social": 40.0, "energy": -6.0}, "sit")
			a.weekdays = [1, 2, 3, 4, 5]
			a.months = SchoolBuilder.SCHOOL_YEAR
			a.from_hour = SchoolBuilder.CLASS_HOURS.x
			a.to_hour = SchoolBuilder.CLASS_HOURS.y
			a.memory_id = "school_year"
			a.autonomous = false
			a.messages = ["Spelling test! You spell 'necessary' right. Finally.", "Show and tell: somebody brought a real snake. Best day ever.",
				"Reading time on the rug. Mrs. Fenwick does all the voices."]
			out.append(a)
			a = Activity.make("Go to Summer School", 120, {"fun": -8.0, "social": 40.0, "energy": -6.0}, "sit")
			a.weekdays = [1, 2, 3, 4]
			a.months = SchoolBuilder.SUMMER
			a.from_hour = SchoolBuilder.SUMMER_HOURS.x
			a.to_hour = SchoolBuilder.SUMMER_HOURS.y
			a.memory_id = "school"
			a.autonomous = false
			a.messages = ["Fractions. In SUMMER. You learn them anyway.", "Mrs. Fenwick lets you out five minutes early. Best day ever."]
			out.append(a)
		"lockers":
			a = Activity.make("Open Your Locker", 5, {"fun": 16.0}, "reach")
			a.messages = ["Half a sandwich from May. GROSS.", "Your missing Trapper Keeper! It was here the whole time.", "A note: \"Do you like me? Check yes or no.\""]
			out.append(a)
		"trophy_case":
			out.append(Activity.make("Admire the Trophy Case", 5, {"fun": 10.0}, "stand"))
		"fountain":
			out.append(Activity.make("Get a Drink of Water", 3, {"hunger": 30.0, "energy": 10.0}, "reach"))
		"easel":
			a = Activity.make("Paint a Picture", 30, {"fun": 44.0}, "reach")
			a.messages = ["A sunset over Maple Street. Mrs. Fenwick says it's \"very expressive.\"", "It's either a horse or a dog. You'll decide later."]
			out.append(a)
		"art_table":
			a = Activity.make("Make a Clay Pot", 30, {"fun": 38.0}, "sit")
			a.messages = ["It's lopsided. It's a masterpiece. Mom's going to love it."]
			out.append(a)
		"gym_hoop":
			a = Activity.make("Shoot Hoops in the Gym", 30, {"fun": 46.0, "energy": -14.0}, "hoops")
			a.loop_sound = "basketball"
			a.loop_db = -8.0
			out.append(a)
		"gym_rope":
			a = Activity.make("Climb the Rope", 10, {"fun": 30.0, "energy": -18.0}, "reach")
			a.messages = ["You make it all the way to the top! (Halfway. You make it halfway.)"]
			out.append(a)
		"gym_floor":
			a = Activity.make("Play Dodgeball", 30, {"fun": 50.0, "energy": -16.0, "social": 20.0}, "hoops")
			a.messages = ["You dodge, you duck, you dip, you dive... BONK."]
			out.append(a)
		"bulletin":
			a = Activity.make("Read the Town Bulletin Board", 10, {"fun": 10.0, "social": 6.0}, "stand")
			a.talk = "tip"
			out.append(a)
		"town_map":
			out.append(Activity.make("Study the Map of Maple Grove", 10, {"fun": 12.0}, "stand"))
		"wanted_board":
			a = Activity.make("Read the Wanted Posters", 5, {"fun": 18.0}, "stand")
			a.messages = ["WANTED: The Cul-de-Sac Bandit. Last seen eating the Parkers' pie.", "WANTED: A guy with a mustache. (That's... a lot of guys.)",
				"The town reward for catching a burglar is ten whole dollars!"]
			out.append(a)
		"cell_door":
			a = Activity.make("Rattle the Cell Door", 2, {"fun": 10.0}, "reach")
			a.locked = true
			a.message = "Locked tight. The key's on Sergeant Kowal's belt."
			out.append(a)
		"npc_thief":
			a = Activity.make("Stop the Burglar!", 3, {"fun": 60.0, "social": 20.0}, "stand")
			a.talk = "stop_thief"
			a.autonomous = false
			out.append(a)
			a = Activity.make("Talk to the Prisoner", 8, {"social": 20.0, "fun": 10.0}, "stand")
			a.talk = "chat"
			a.autonomous = false
			out.append(a)
		"fire_pole":
			a = Activity.make("Slide Down the Fire Pole", 5, {"fun": 50.0}, "reach")
			a.memory_id = "firehouse"
			a.messages = ["Wheeee! Captain Riley says that's how the pros do it."]
			out.append(a)
		"firehouse_table":
			a = Activity.make("Eat Firehouse Chili", 25, {"hunger": 160.0, "social": 40.0}, "sit")
			a.from_hour = 11.0
			a.to_hour = 20.0
			a.messages = ["Captain Riley's famous five-alarm chili. Your eyes water. Delicious!"]
			out.append(a)
		"fire_bunk":
			a = Activity.make("Take a Nap on a Bunk", 45, {"energy": 44.0}, "lie")
			a.surface = 0.55
			out.append(a)
		"mall_doors":
			a = Activity.make("Try the Mall Doors", 1, {}, "reach")
			a.message = "Locked! A sign says: GRAND OPENING THIS FALL! 40 STORES! A FOOD COURT!"
			a.autonomous = false
			out.append(a)
		"freezer":
			a = Activity.make("Buy a Popsicle", 5, {"hunger": 40.0, "fun": 16.0}, "reach")
			a.money = -0.25
			a.sound = "cash_register"
			a.from_hour = 8.0
			a.to_hour = 20.0
			out.append(a)
		"produce":
			a = Activity.make("Sample a Grape", 2, {"hunger": 10.0, "fun": 8.0}, "reach")
			a.messages = ["Gloria gives you a look. You eat it anyway."]
			out.append(a)
		"checkout":
			a = Activity.make("Bag Groceries for Tips", 60, {"fun": -10.0, "social": 30.0, "energy": -8.0}, "reach")
			a.money = 2.0
			a.weekdays = [1, 2, 3, 4, 5, 6]
			a.from_hour = 9.0
			a.to_hour = 19.0
			a.autonomous = false
			a.messages = ["Eggs on top. EGGS ON TOP.", "Mrs. Albright tips you a whole quarter!"]
			out.append(a)
			a = Activity.make("Buy a Candy Bar", 3, {"hunger": 60.0, "fun": 20.0}, "reach")
			a.money = -0.35
			a.sound = "cash_register"
			a.from_hour = 8.0
			a.to_hour = 20.0
			out.append(a)
			a = Activity.make("Buy a Pack of Baseball Cards", 5, {"fun": 40.0}, "reach")
			a.money = -0.5
			a.sound = "cash_register"
			a.from_hour = 8.0
			a.to_hour = 20.0
			a.messages = ["A Don Mattingly! And a stick of gum that tastes like cardboard.", "Three of the same guy. Typical."]
			out.append(a)
		"porch":
			a = Activity.make("Toss the Newspaper", 1, {}, "reach")
			a.paper = "deliver"
			a.autonomous = false
			a.memory_id = "paperroute"
			out.append(a)
	return out


static func _fill_town(objects: Dictionary) -> void:
	var a: Activity
	var add := func(key: String, act: Activity) -> void:
		if objects.has(key):
			(objects[key] as SmartObject).activities.append(act)
	var hours := func(act: Activity, from: float, to: float) -> Activity:
		act.from_hour = from
		act.to_hour = to
		act.autonomous = false
		return act

	# ---- Maple Grove Public Library (9 AM - 8 PM). Books are free; late ones cost a dime a day.
	for key in ["library_fiction", "library_science", "library_kids"]:
		a = hours.call(Activity.make("Check Out a Book", 10, {"fun": 12.0}, "reach"), 9.0, 20.0)
		a.gives_item = "book"
		a.gives_titles = BOOKS
		a.gives_days = 7
		a.done_message = "You checked out \"%s\". It's due back in a week. Read it anywhere you can sit."
		a.sound = "page_flip"
		add.call(key, a)
		a = hours.call(Activity.make("Browse the Shelves", 20, {"fun": 26.0}, "reach"), 9.0, 20.0)
		a.messages = ["You find a book about sharks with really gross pictures. Perfect.",
			"Somebody dog-eared every page of this joke book.", "Shhh!"]
		add.call(key, a)
	a = hours.call(Activity.make("Return Your Book", 3, {}, "reach"), 9.0, 20.0)
	a.needs_item = "book"
	a.takes_item = "book"
	a.late_fee = 0.10
	a.done_message = "You returned \"%s\". The librarian stamps it with a satisfying thunk."
	add.call("library_desk", a)
	a = hours.call(Activity.make("Get a Library Card", 5, {"fun": 20.0}, "reach"), 9.0, 20.0)
	a.memory_id = "library"
	a.message = "The librarian types your name on a brand-new card."
	add.call("library_desk", a)
	a = hours.call(Activity.make("Browse the Card Catalog", 15, {"fun": 14.0}, "reach"), 9.0, 20.0)
	a.messages = ["Dinosaurs: 567.9. Of course you memorize it.", "You pull the drawer out too far. Cards everywhere."]
	add.call("card_catalog", a)
	for key in ["reading_table_1", "reading_table_2"]:
		add.call(key, hours.call(Activity.make("Read at the Library", 45, {"fun": 32.0, "energy": 6.0}, "read"), 9.0, 20.0))
		a = hours.call(Activity.make("Do Homework at the Library", 40, {"fun": -6.0}, "sit"), 9.0, 20.0)
		a.money = 1.0
		add.call(key, a)

	# ---- Food Fair Grocery (8 AM - 8 PM)
	a = hours.call(Activity.make("Buy a Bag of Chips", 3, {"hunger": 70.0, "fun": 14.0}, "reach"), 8.0, 20.0)
	a.money = -0.6
	a.sound = "cash_register"
	add.call("grocery_snacks", a)
	a = hours.call(Activity.make("Buy a Soda Pop", 3, {"hunger": 30.0, "energy": 16.0, "fun": 10.0}, "reach"), 8.0, 20.0)
	a.money = -0.5
	a.sound = "cash_register"
	add.call("grocery_snacks", a)
	a = hours.call(Activity.make("Read the Cereal Boxes", 10, {"fun": 16.0}, "reach"), 8.0, 20.0)
	a.messages = ["There's a decoder ring in this one. You NEED it.", "Sugar Bombs: Now With MORE Sugar!"]
	add.call("grocery_canned", a)

	# ---- Sunrise Diner (6 AM - 3 PM)
	for key in ["diner_counter", "diner_booth_1", "diner_booth_2"]:
		a = hours.call(Activity.make("Eat a Big Breakfast", 40, {"hunger": 240.0, "social": 20.0}, "sit"), 6.0, 11.0)
		a.money = -3.50
		a.memory_id = "diner"
		a.sound = "cash_register"
		a.loop_sound = "sizzle"
		a.loop_db = -20.0
		add.call(key, a)
		a = hours.call(Activity.make("Have a Stack of Pancakes", 30, {"hunger": 220.0, "fun": 20.0}, "sit"), 6.0, 12.0)
		a.money = -2.75
		a.sound = "cash_register"
		add.call(key, a)
		a = hours.call(Activity.make("Hot Cocoa & a Donut", 20, {"hunger": 120.0, "fun": 30.0}, "sit"), 6.0, 15.0)
		a.money = -1.25
		a.sound = "cash_register"
		add.call(key, a)
		a = hours.call(Activity.make("Order a Milkshake", 20, {"hunger": 90.0, "fun": 50.0}, "sit"), 10.0, 15.0)
		a.money = -1.75
		a.sound = "cash_register"
		add.call(key, a)
	for key in objects.keys():
		if String(key).begins_with("diner_booth") or key == "diner_counter":
			(objects[key] as SmartObject).activities[0].messages = ["Two eggs, bacon, hash browns and toast. You clean the plate.",
				"The waitress refills your juice without even asking."]

	# ---- Pizza Peak (11 AM - 11 PM)
	for i in range(1, 5):
		var key := "pizza_table_%d" % i
		a = hours.call(Activity.make("Eat a Pan Pizza", 45, {"hunger": 260.0, "social": 30.0, "fun": 20.0}, "sit"), 11.0, 23.0)
		a.money = -5.99
		a.memory_id = "pizza"
		a.sound = "cash_register"
		add.call(key, a)
		a = hours.call(Activity.make("Grab a Slice", 15, {"hunger": 300.0}, "sit"), 11.0, 23.0)
		a.money = -1.50
		a.sound = "cash_register"
		add.call(key, a)
		a = hours.call(Activity.make("Root Beer Float", 15, {"fun": 80.0, "hunger": 60.0}, "sit"), 11.0, 23.0)
		a.money = -1.00
		a.sound = "cash_register"
		add.call(key, a)
	a = hours.call(Activity.make("Hit the Salad Bar", 15, {"hunger": 300.0}, "reach"), 11.0, 23.0)
	a.money = -2.50
	a.messages = ["Mostly croutons and bacon bits. That counts as salad.", "You build a tower of cherry tomatoes."]
	add.call("salad_bar", a)
	a = hours.call(Activity.make("Play the Jukebox", 15, {"fun": 60.0}, "dance"), 11.0, 23.0)
	a.money = -0.25
	a.loop_sound = "music_house"
	a.loop_db = -6.0
	a.glow = "jukebox_mat"
	add.call("jukebox", a)

	# ---- Rewind Video (10 AM - 10 PM). Rentals are $2.99 for two days; $1 a day late.
	for key in ["new_releases", "horror_aisle"]:
		a = hours.call(Activity.make("Rent a Movie", 10, {"fun": 16.0}, "reach"), 10.0, 22.0)
		a.money = -2.99
		a.gives_item = "tape"
		a.gives_titles = MOVIES
		a.gives_days = 2
		a.memory_id = "video"
		a.sound = "cash_register"
		a.done_message = "You rented \"%s\". It's due back in 2 days. Watch it on any TV!"
		add.call(key, a)
	a = hours.call(Activity.make("Browse the New Releases", 15, {"fun": 24.0}, "reach"), 10.0, 22.0)
	a.messages = ["Every copy of the new one is checked out. Again.", "You read the back of a box for way too long."]
	add.call("new_releases", a)
	a = hours.call(Activity.make("Dare Yourself in the Horror Aisle", 10, {"fun": 34.0}, "reach"), 10.0, 22.0)
	a.messages = ["That cover is going to give you nightmares.", "You could watch this one... with the lights on."]
	add.call("horror_aisle", a)
	a = hours.call(Activity.make("Return Your Tape", 3, {}, "reach"), 10.0, 22.0)
	a.needs_item = "tape"
	a.takes_item = "tape"
	a.late_fee = 1.0
	a.sound = "tape_rewind"
	a.done_message = "You returned \"%s\". Be kind, rewind!"
	add.call("video_counter", a)
	a = hours.call(Activity.make("Buy Candy", 3, {"hunger": 200.0, "fun": 100.0}, "reach"), 10.0, 22.0)
	a.money = -0.50
	a.sound = "cash_register"
	add.call("video_counter", a)

	# ---- Pixel Palace Arcade (11 AM - 11 PM). A quarter a game.
	for i in DowntownBuilder.GAMES.size():
		var game: String = DowntownBuilder.GAMES[i][0]
		a = hours.call(Activity.make("Play %s" % game, 15, {"fun": 80.0, "energy": -4.0}, "stand"), 11.0, 23.0)
		a.money = -0.25
		a.loop_sound = "arcade_game"
		a.loop_db = -10.0
		a.glow = "arcade_%d_mat" % (i + 1)
		a.memory_id = "arcade"
		a.messages = ["New high score! You enter your initials: A-A-A.", "Game over. Just one more quarter...",
			"You make it to level 7. A crowd of little kids watches.", "Your thumb has a blister now. Worth it."]
		add.call("arcade_%d" % (i + 1), a)
	a = hours.call(Activity.make("Play Pinball", 20, {"fun": 80.0}, "stand"), 11.0, 23.0)
	a.money = -0.50
	a.loop_sound = "arcade_game"
	a.loop_db = -12.0
	a.glow = "pinball_mat"
	a.messages = ["TILT! You bumped it too hard.", "Multiball!", "Free game! The machine knocks loudly."]
	add.call("pinball", a)
	a = hours.call(Activity.make("Trade Tickets for a Prize", 5, {"fun": 40.0}, "reach"), 11.0, 23.0)
	a.messages = ["A plastic spider ring. Totally worth 200 tickets.", "Pixie sticks!", "A slap bracelet!"]
	add.call("prize_counter", a)

	# ---- At home: rented movies, library books, and pizza delivery
	for key in objects:
		var o: SmartObject = objects[key]
		match o.kind:
			"tv":
				a = Activity.make("Watch Your Rented Movie", 100, {"fun": 50.0, "energy": -2.0}, "sit")
				a.tv_on = true
				a.needs_item = "tape"
				a.item_message = "You pop \"%s\" into the VCR. Popcorn would be nice."
				o.activities.append(a)
			"bed", "couch":
				a = Activity.make("Read Your Library Book", 45, {"fun": 36.0, "energy": 6.0}, "read")
				a.surface = 0.55 if o.kind == "bed" else 0.45
				a.needs_item = "book"
				a.item_message = "You open \"%s\" and get lost in it."
				o.activities.append(a)
			"phone":
				a = Activity.make("Order Pizza Delivery", 6, {"hunger": 0.0}, "phone")
				a.money = -8.99
				a.delivery = "pizza"
				a.autonomous = false
				a.from_hour = 11.0
				a.to_hour = 22.5
				a.done_message = "Pizza Peak says it'll be there in 30 minutes or less!"
				o.activities.append(a)
			"pizza_box":
				a = Activity.make("Eat the Delivery Pizza", 30, {"hunger": 300.0, "social": 30.0, "fun": 30.0}, "sit")
				a.memory_id = "delivery"
				o.activities.append(a)
	if objects.has("bean_bag"):
		a = Activity.make("Read Your Library Book", 45, {"fun": 36.0, "energy": 6.0}, "read")
		a.surface = 0.3
		a.needs_item = "book"
		a.item_message = "You open \"%s\" and get lost in it."
		(objects["bean_bag"] as SmartObject).activities.append(a)



## Holiday extras on things every house has: Thanksgiving dinner at the dining
## table, cookouts at the grill, the parade on TV on New Year's morning.
static func _fill_holidays(objects: Dictionary) -> void:
	for k in objects:
		var o: SmartObject = objects[k]
		var a: Activity
		if k == "dining_table" or (o.kind == "table" and o.home != "" and o.home != "town"):
			a = Activity.make("Eat Thanksgiving Dinner", 60, {"hunger": 140.0, "social": 70.0}, "sit")
			a.holidays = ["thanksgiving"]
			a.from_hour = 12.0
			a.to_hour = 20.0
			a.memory_id = "thanksgiving"
			a.messages = ["Grandpa falls asleep in his chair. Again.", "You get the drumstick! Victory."]
			o.activities.push_front(a)
		if o.kind == "tv" or k == "tv":
			a = Activity.make("Watch the New Year's Parade", 60, {"fun": 40.0}, "sit")
			a.holidays = ["newyear"]
			a.from_hour = 8.0
			a.to_hour = 13.0
			a.tv_on = true
			o.activities.push_front(a)
		if k == "grill":
			a = Activity.make("Have a Holiday Cookout", 60, {"hunger": 110.0, "fun": 40.0, "social": 40.0}, "stand")
			a.holidays = ["memorial", "july4", "labor"]
			a.from_hour = 11.0
			a.to_hour = 20.0
			a.memory_id = "cookout"
			a.loop_sound = "sizzle"
			a.loop_db = -12.0
			o.activities.push_front(a)
