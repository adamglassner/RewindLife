class_name GameClock
extends Node
## The heartbeat of the game. Everything that changes over time listens to
## minute_passed. The game starts on Saturday, June 14, 1986 at 8:00 AM.

signal minute_passed
signal hour_changed(hour: int)
signal speed_changed(level: int)

const DAY_NAMES := ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
const MONTH_NAMES := ["JAN", "FEB", "MAR", "APR", "MAY", "JUNE", "JULY", "AUG", "SEPT", "OCT", "NOV", "DEC"]
## Game minutes per real second at each speed: pause, normal, fast, fastest.
const SPEEDS := [0.0, 1.0, 4.0, 15.0]

var speed_level := 1
var unix_time := 0
## Extra time multiplier while Jamie sleeps, so nights fly by.
var boost := 1.0
var _accum := 0.0


func _init() -> void:
	unix_time = Time.get_unix_time_from_datetime_dict(
		{"year": 1986, "month": 6, "day": 14, "hour": 8, "minute": 0, "second": 0})


func set_speed(level: int) -> void:
	speed_level = clampi(level, 0, SPEEDS.size() - 1)
	speed_changed.emit(speed_level)


func speed_factor() -> float:
	return SPEEDS[speed_level]


func _process(delta: float) -> void:
	_accum += delta * float(SPEEDS[speed_level]) * boost
	var steps := 0
	# Emit one signal per game minute so no system ever has to handle a time jump.
	while _accum >= 1.0 and steps < 60:
		_accum -= 1.0
		steps += 1
		var before := hour()
		unix_time += 60
		minute_passed.emit()
		var after := hour()
		if after != before:
			hour_changed.emit(after)


func _dt() -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(unix_time)


func hour() -> int:
	return int(_dt()["hour"])


func hour_float() -> float:
	var d := _dt()
	return float(d["hour"]) + float(d["minute"]) / 60.0


func weekday() -> int:
	return int(_dt()["weekday"])


func year() -> int:
	return int(_dt()["year"])


func month() -> int:
	return int(_dt()["month"])


func day() -> int:
	return int(_dt()["day"])


func date_label() -> String:
	var d := _dt()
	return "%s · %s %d · %d" % [DAY_NAMES[int(d["weekday"])], MONTH_NAMES[int(d["month"]) - 1], int(d["day"]), int(d["year"])]


func time_label() -> String:
	var d := _dt()
	var h := int(d["hour"]) % 12
	if h == 0:
		h = 12
	return "%d:%02d" % [h, int(d["minute"])]


func ampm() -> String:
	return "AM" if hour() < 12 else "PM"


func period_label() -> String:
	var h := hour_float()
	if h >= 5.0 and h < 12.0:
		return "MORNING"
	if h >= 12.0 and h < 17.0:
		return "AFTERNOON"
	if h >= 17.0 and h < 21.0:
		return "EVENING"
	return "NIGHT"


const DAY_FULL := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const MONTH_FULL := ["January", "February", "March", "April", "May", "June", "July", "August",
	"September", "October", "November", "December"]


## e.g. "Saturday, June 14, 1986"
func long_date() -> String:
	var d := _dt()
	return "%s, %s %d, %d" % [DAY_FULL[int(d["weekday"])], MONTH_FULL[int(d["month"]) - 1], int(d["day"]), int(d["year"])]


static func fmt_hour(h: float) -> String:
	var hh := int(h) % 24
	var suffix := "am" if hh < 12 else "pm"
	var h12 := hh % 12
	if h12 == 0:
		h12 = 12
	return "%d%s" % [h12, suffix]
