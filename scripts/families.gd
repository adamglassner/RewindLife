class_name Families
extends RefCounted
## Last names, and what rooms and things are called depending on whose house
## it is. At home it's "Mom & Dad's Room"; at a friend's it's "Mr. & Mrs.
## Nguyen's Room". Jamie's family gets a random last name each new game (saved,
## and sent to friends online).

const SURNAMES := ["Abernathy", "Bishop", "Callahan", "Delgado", "Ellison", "Fitzgerald", "Gallagher", "Hartley",
	"Iverson", "Jablonski", "Keller", "Lindqvist", "McAllister", "Novak", "O'Brien", "Petrakis", "Quinlan", "Russo",
	"Sorensen", "Tanaka", "Underwood", "Valdez", "Whitaker", "Yamamoto", "Zielinski", "Brennan", "Castillo", "Donnelly"]

## Jamie's family's last name (this game).
static var jamie := "Keller"


static func pick_new() -> void:
	jamie = SURNAMES[randi() % SURNAMES.size()]


static func family(home: String) -> String:
	if home == "jamie":
		return jamie
	if NeighborBuilder.HOMES.has(home):
		return String(NeighborBuilder.HOMES[home]["family"])
	return ""


## "the Kellers" / "the Garcias"
static func plural(home: String) -> String:
	var f := family(home)
	return "the %s" % (f + "es" if f.ends_with("s") or f.ends_with("z") else f + "s")


## "the Garcias' house"
static func house_title(home: String) -> String:
	var p := plural(home)
	return "%s' house" % p


static func kid_name(home: String) -> String:
	for ch in Sim.CHARACTERS:
		if ch["home"] == home:
			return ch["name"]
	return String(NeighborBuilder.HOMES.get(home, {}).get("kid", "Kid"))


## A room's name as `viewer_home`'s kid sees it. `key` = "home|Kind".
static func room_label(key: String, viewer_home: String) -> String:
	if not "|" in key:
		return key
	var home := key.get_slice("|", 0)
	var kind := key.get_slice("|", 1)
	if home == "town":
		return kind
	var mine := home == viewer_home
	var f := family(home)
	match kind:
		"Parents Room":
			return "Mom & Dad's Room" if mine else "Mr. & Mrs. %s's Room" % f
		"Kid Room":
			return "Your Room" if mine else "%s's Room" % kid_name(home)
	if mine:
		return kind
	var p := plural(home)
	return "T%s' %s" % [p.substr(1), kind]


## The parents' names as your kid says them: "Mom" at home, "Mrs. Nguyen" elsewhere.
static func parent_name(home: String, mom: bool, viewer_home: String) -> String:
	if home == viewer_home:
		return "Mom" if mom else "Dad"
	return ("Mrs. " if mom else "Mr. ") + family(home)


static func parents_bed(home: String, viewer_home: String) -> String:
	return "Mom & Dad's Bed" if home == viewer_home else "Mr. & Mrs. %s's Bed" % family(home)
