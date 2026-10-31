class_name GameAudio
extends Node
## Music and sound effects. Effects play from the object that makes them
## (3D sound), so they're louder up close in first person and softer from the
## House Cam. All sounds live in res://audio and are made by tools/make_audio.py.

const MUSIC_DB := -9.0
const MUSIC_DUCKED_DB := -19.0   # while the TV is on
const OUTSIDE_DB := -8.0
const SILENT_DB := -50.0
const AMBIENCE_DB := -14.0

var music := AudioStreamPlayer.new()            # the house music
var music_outside := AudioStreamPlayer.new()    # the Outside Theme
var ambience := AudioStreamPlayer.new()         # birds by day, crickets at night (outside only)
var music_on := true
var outside := false

var _ducked := false
var _zone_tween: Tween
var _ambience_name := ""

var _streams := {}
var _loops := {}       # key -> AudioStreamPlayer3D (can be stopped later)
var _duck_tween: Tween


## Two audio buses, so the Options menu can set music and sound volumes apart.
static func ensure_buses() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")


func _ready() -> void:
	ensure_buses()
	music.bus = "Music"
	music_outside.bus = "Music"
	ambience.bus = "SFX"
	music.stream = _stream("music_house", true)
	music.volume_db = MUSIC_DB
	add_child(music)
	if music.stream:
		music.play()
	music_outside.stream = _stream("music_outside", true)
	music_outside.volume_db = SILENT_DB
	add_child(music_outside)
	if music_outside.stream:
		music_outside.play()
		music_outside.stream_paused = true
	ambience.volume_db = SILENT_DB
	add_child(ambience)


func _stream(sound: String, loop := false) -> AudioStream:
	var key := sound + ("#loop" if loop else "")
	if _streams.has(key):
		return _streams[key]
	var path := "res://audio/%s.ogg" % sound
	if not ResourceLoader.exists(path):
		push_warning("Missing sound: " + path)
		_streams[key] = null
		return null
	var s: AudioStream = load(path)
	if loop and s is AudioStreamOggVorbis:
		s = s.duplicate() as AudioStream
		(s as AudioStreamOggVorbis).loop = true
	_streams[key] = s
	return s


## Move a looping sound (e.g. the engine follows the car).
func move_loop(key: String, pos: Vector3) -> void:
	var p = _loops.get(key)
	if p != null and is_instance_valid(p):
		(p as AudioStreamPlayer3D).global_position = pos


func _player(pos: Vector3, db: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.unit_size = 7.0
	p.max_db = 3.0
	p.volume_db = db
	p.panning_strength = 0.6
	p.bus = "SFX"
	add_child(p)
	p.global_position = pos
	return p


## A one-shot sound at a place in the room.
func play_at(sound: String, pos: Vector3, db := 0.0) -> void:
	var s := _stream(sound)
	if s == null:
		return
	var p := _player(pos, db)
	p.name = sound
	p.stream = s
	p.finished.connect(p.queue_free)
	p.play()


## A one-shot sound that isn't in the room (interface, chimes).
func play_ui(sound: String, db := 0.0) -> void:
	var s := _stream(sound)
	if s == null:
		return
	var p := AudioStreamPlayer.new()
	p.name = sound
	p.stream = s
	p.volume_db = db
	p.bus = "SFX"
	p.process_mode = Node.PROCESS_MODE_ALWAYS   # menu clicks play while paused
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


## A sound that keeps going until stop_loop(key). `loop` = repeat it.
func start_loop(key: String, sound: String, pos: Vector3, db := 0.0, delay := 0.0, loop := true) -> void:
	stop_loop(key, 0.05)
	var s := _stream(sound, loop)
	if s == null:
		return
	var p := _player(pos, db)
	p.name = sound
	p.stream = s
	_loops[key] = p
	if not loop:
		p.finished.connect(func(): stop_loop(key, 0.0))
	if delay <= 0.0:
		p.play()
	else:
		# Look the player up by id when the timer fires: it may have been
		# stopped (and freed) in the meantime.
		var id := p.get_instance_id()
		get_tree().create_timer(delay).timeout.connect(func():
			var node := instance_from_id(id) as AudioStreamPlayer3D
			if node != null and _loops.get(key) == node:
				node.play())


func has_loop(key: String) -> bool:
	return _loops.has(key)


func stop_loop(key: String, fade := 0.25) -> void:
	if not _loops.has(key):
		return
	var p: AudioStreamPlayer3D = _loops[key]
	_loops.erase(key)
	if not is_instance_valid(p):
		return
	if fade <= 0.0:
		p.queue_free()
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", -40.0, fade)
	tw.tween_callback(p.queue_free)


## Pausing the game pauses ongoing sounds (the music keeps playing).
func set_paused(on: bool) -> void:
	for p in _loops.values():
		if is_instance_valid(p):
			p.stream_paused = on


func set_music(on: bool) -> void:
	music_on = on
	music.stream_paused = not on or outside
	music_outside.stream_paused = not on or not outside


## Turn the house music down while the TV is on (or Jamie is asleep).
func duck(on: bool) -> void:
	_ducked = on
	if outside:
		return
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(music, "volume_db", _house_db(), 0.8)


func _house_db() -> float:
	return MUSIC_DUCKED_DB if _ducked else MUSIC_DB


## Crossfade between the house music and the Outside Theme. Each track pauses
## while silent, so it picks up where it left off when Jamie comes back.
func set_outside(on: bool) -> void:
	if on == outside:
		return
	outside = on
	var fade_in: AudioStreamPlayer = music_outside if on else music
	var fade_out: AudioStreamPlayer = music if on else music_outside
	if _zone_tween:
		_zone_tween.kill()
	if _duck_tween:
		_duck_tween.kill()
	if music_on:
		fade_in.stream_paused = false
	_zone_tween = create_tween().set_parallel(true)
	_zone_tween.tween_property(fade_in, "volume_db", OUTSIDE_DB if on else _house_db(), 1.6)
	_zone_tween.tween_property(fade_out, "volume_db", SILENT_DB, 1.6)
	_zone_tween.chain().tween_callback(func(): fade_out.stream_paused = true)


## Outdoor background sound: "birds", "crickets" or "" (none). Fades between them.
func set_ambience(sound: String) -> void:
	if sound == _ambience_name:
		return
	_ambience_name = sound
	var tw := create_tween()
	tw.tween_property(ambience, "volume_db", SILENT_DB, 1.0)
	if sound == "":
		tw.tween_callback(ambience.stop)
		return
	tw.tween_callback(func():
		ambience.stream = _stream(sound, true)
		ambience.play())
	tw.tween_property(ambience, "volume_db", AMBIENCE_DB, 1.5)
