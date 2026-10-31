class_name Needs
extends RefCounted
## Hunger, Energy, Fun and Social, from 0 (empty) to 100 (full).

const NAMES := ["hunger", "energy", "fun", "social"]
## Points each need loses per game hour.
const DECAY := {"hunger": 6.0, "energy": 4.0, "fun": 5.0, "social": 3.0}

var values := {"hunger": 62.0, "energy": 78.0, "fun": 31.0, "social": 54.0}
## Temporary boost from Memory Moments; fades over a few game hours.
var mood_bonus := 0.0
## Late at night, Energy drains twice as fast.
var sleepy := false


## Called once per game minute. `effects` = points gained per game hour from
## whatever the resident is doing right now.
func tick_minute(effects: Dictionary) -> void:
	for n in NAMES:
		var change: float = -float(DECAY[n]) / 60.0
		if sleepy and n == "energy":
			change *= 2.0
		if effects.has(n):
			change += float(effects[n]) / 60.0
		values[n] = clampf(float(values[n]) + change, 0.0, 100.0)
	mood_bonus = maxf(0.0, mood_bonus - 0.05)


func value(n: String) -> float:
	return float(values[n])


func mood() -> float:
	var total := 0.0
	var lowest := 100.0
	for n in NAMES:
		total += value(n)
		lowest = minf(lowest, value(n))
	# One empty need drags the mood down more than a plain average would.
	return clampf(total / NAMES.size() * 0.7 + lowest * 0.3 + mood_bonus, 0.0, 100.0)


func mood_label() -> String:
	var m := mood()
	if m >= 72.0:
		return "GREAT"
	if m >= 52.0:
		return "CONTENT"
	if m >= 36.0:
		return "OKAY"
	if m >= 20.0:
		return "DOWN"
	return "MISERABLE"
