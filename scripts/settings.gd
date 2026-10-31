class_name Settings
extends RefCounted
## Player options, kept in user://settings.cfg between sessions.

const PATH := "user://settings.cfg"

static var music_volume := 0.8     # 0..1
static var sound_volume := 0.9
static var fullscreen := false
static var look_sensitivity := 1.0 # 0.3..2.5
static var invert_y := false


static func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	music_volume = cf.get_value("audio", "music", music_volume)
	sound_volume = cf.get_value("audio", "sound", sound_volume)
	fullscreen = cf.get_value("video", "fullscreen", fullscreen)
	look_sensitivity = cf.get_value("controls", "look_sensitivity", look_sensitivity)
	invert_y = cf.get_value("controls", "invert_y", invert_y)


static func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "music", music_volume)
	cf.set_value("audio", "sound", sound_volume)
	cf.set_value("video", "fullscreen", fullscreen)
	cf.set_value("controls", "look_sensitivity", look_sensitivity)
	cf.set_value("controls", "invert_y", invert_y)
	cf.save(PATH)


## Push the settings to the audio buses and the window.
static func apply() -> void:
	_bus_volume("Music", music_volume)
	_bus_volume("SFX", sound_volume)
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)


static func _bus_volume(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(i, v <= 0.001)
