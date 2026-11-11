class_name Achievements
extends RefCounted
## Memory Moments are Rewind Life's achievements.
##
## Once you've found one in any saved game on this computer, it stays found here. They're kept in
##   %APPDATA%\Ironite\Achievements\rewindlife.json   (icons in ...\Achievements\rewindlife\)
## which is also where the Ironite Launcher reads them for its Achievements page.
## (On Linux and macOS: the same folders under Godot's user data folder's parent, see DIR.)

const GAME_ID := "rewindlife"
const TITLE := "Rewind Life"
const ICONS := "res://assets/achievements/"

## Which group each Memory Moment is listed under (the Achievements screen, and the launcher).
const CATEGORY := {
	"cartoons": "At Home",
	"cereal": "At Home",
	"phone_cord": "At Home",
	"stars": "At Home",
	"diary": "At Home",
	"mixtape": "At Home",
	"popcorn": "At Home",
	"dinner": "At Home",
	"pancakes": "At Home",
	"attic": "At Home",
	"presents": "At Home",
	"allowance": "At Home",
	"basement": "At Home",
	"pets": "At Home",
	"burglar": "At Home",
	"gamekid": "At Home",
	"computer": "At Home",
	"summer": "Around Town",
	"drive": "Around Town",
	"hoops": "Around Town",
	"arcade": "Around Town",
	"pizza": "Around Town",
	"diner": "Around Town",
	"library": "Around Town",
	"video": "Around Town",
	"paperroute": "Around Town",
	"lemonade": "Around Town",
	"icecream": "Around Town",
	"drivein": "Around Town",
	"bike": "Around Town",
	"cannonball": "Around Town",
	"skate": "Around Town",
	"payphone": "Around Town",
	"bowling": "Around Town",
	"burger": "Around Town",
	"mall": "Around Town",
	"firehouse": "Around Town",
	"cookout": "Around Town",
	"stargazing": "Around Town",
	"delivery": "Around Town",
	"sprinkler": "Around Town",
	"christmas": "Holidays & Seasons",
	"fireworks": "Holidays & Seasons",
	"newyear": "Holidays & Seasons",
	"thanksgiving": "Holidays & Seasons",
	"carnival": "Holidays & Seasons",
	"circus": "Holidays & Seasons",
	"easter": "Holidays & Seasons",
	"halloween": "Holidays & Seasons",
	"valentine": "Holidays & Seasons",
	"snowman": "Holidays & Seasons",
	"leafpile": "Holidays & Seasons",
	"football": "School",
	"school": "School",
	"school_year": "School",
	"middle_school": "School",
	"high_school": "School",
	"band": "School",
	"computer_lab": "School",
	"typing": "School",
}

const ORDER := ["At Home", "Around Town", "Holidays & Seasons", "School"]


## The shared Ironite folder (IRONITE_ACHIEVEMENTS_DIR overrides it, for tests).
static func dir() -> String:
	var env := OS.get_environment("IRONITE_ACHIEVEMENTS_DIR")
	if env != "":
		return env
	var appdata := OS.get_environment("APPDATA")
	if appdata != "":
		return appdata.path_join("Ironite").path_join("Achievements")
	# (not Windows: next to Godot's own user data folder)
	return OS.get_data_dir().path_join("Ironite").path_join("Achievements")


static func file_path() -> String:
	return dir().path_join(GAME_ID + ".json")


## What's been found so far: memory id -> unix time it was first found.
static func unlocked() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(file_path()):
		return out
	var d = JSON.parse_string(FileAccess.get_file_as_string(file_path()))
	if d is Dictionary:
		for a in d.get("achievements", []):
			if a is Dictionary and bool(a.get("unlocked", false)):
				out[String(a.get("id", ""))] = int(a.get("unlocked_at", 0))
	return out


## Adds these memories (a saved game's, or one just found) to what's been found, and writes the
## file again if anything's new. Returns how many were new.
static func save(memories: Dictionary) -> int:
	var have := unlocked()
	var now := int(Time.get_unix_time_from_system())
	var added := 0
	for id in memories:
		if Content.MEMORIES.has(id) and not have.has(id):
			have[id] = now
			added += 1
	if added > 0 or not FileAccess.file_exists(file_path()):
		_write(have)
	return added


static func _write(have: Dictionary) -> void:
	var d := dir()
	if DirAccess.make_dir_recursive_absolute(d.path_join(GAME_ID)) != OK and not DirAccess.dir_exists_absolute(d.path_join(GAME_ID)):
		return
	_copy_icon("locked", d)
	var list := []
	for cat in ORDER:
		for id in Content.MEMORIES:
			if String(CATEGORY.get(id, "Around Town")) != cat:
				continue
			var m: Array = Content.MEMORIES[id]
			var got := have.has(id)
			if got:
				_copy_icon(id, d)
			list.append({
				"id": id, "name": m[0], "description": m[1], "category": cat, "hidden": false,
				"unlocked": got, "unlocked_at": int(have.get(id, 0)), "progress": 1 if got else 0, "target": 1,
				"icon": GAME_ID + "/" + id + ".png", "icon_locked": GAME_ID + "/locked.png",
			})
	var doc := {"schema": 1, "game": GAME_ID, "title": TITLE, "updated": int(Time.get_unix_time_from_system()),
		"icon_hidden": GAME_ID + "/locked.png", "achievements": list}
	# (write a new file, then swap it in, so the launcher never reads half a file)
	var tmp := file_path() + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(doc, "  "))
	f.close()
	DirAccess.rename_absolute(tmp, file_path())


static func _copy_icon(id: String, d: String) -> void:
	var out := d.path_join(GAME_ID).path_join(id + ".png")
	if FileAccess.file_exists(out):
		return
	var path := ICONS + id + ".png"
	if not ResourceLoader.exists(path):
		return
	var t: Texture2D = load(path)
	if t:
		var img := t.get_image()
		if img:
			img.save_png(out)


static func icon(id: String, got: bool) -> Texture2D:
	var path := ICONS + (id if got else "locked") + ".png"
	return load(path) if ResourceLoader.exists(path) else null
