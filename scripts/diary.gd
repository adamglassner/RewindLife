class_name Diary
extends RefCounted
## Jamie's diary. Entries are saved to disk (user://diary.json) so they're still
## there next time you play. On Windows that's in
## %APPDATA%\Godot\app_userdata\Rewind Life (Prototype)\.

const PATH := "user://diary.json"

var entries: Array = []   # [{"date": "...", "time": "...", "text": "..."}], oldest first


func load_entries() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Array:
		entries = data


func add(date: String, time: String, text: String) -> void:
	entries.append({"date": date, "time": time, "text": text})
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(entries, "  "))
