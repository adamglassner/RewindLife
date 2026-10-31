class_name PayPhones
extends RefCounted
## Payphones: a quarter a call. On the wall in a few stores and the civic
## buildings, a bank of them in the mall's food court, and outdoor booths by the
## bus stop and the skate park.

const PRICE := 0.25

## [key, wall-face position, yaw (the way the phone faces, into the room), hours] for the wall phones.
## (Each spot is on the inside face of a wall.)
const SPOTS := [
	["payphone_diner", Vector3(2.075, 0, 63.6), 90.0, Vector2(6.0, 15.0)],
	["payphone_pizza", Vector3(14.075, 0, 64.2), 90.0, Vector2(11.0, 23.0)],
	["payphone_arcade", Vector3(47.925, 0, 58.6), -90.0, Vector2(11.0, 23.0)],
	["payphone_grocery", Vector3(70.925, 0, 58.2), -90.0, Vector2(8.0, 20.0)],
	["payphone_police", Vector3(1.075, 0, -20.6), 90.0, Vector2(0.0, 24.0)],
	["payphone_cityhall", Vector3(-13.925, 0, -44.2), 90.0, Vector2(8.5, 17.0)],
	["payphone_school", Vector3(7.075, 0, -43.6), 90.0, Vector2(7.5, 17.0)],
]


static func place_all(root: Node3D, out: Dictionary, solids: Array[Rect2]) -> void:
	var c := {"root": root, "objects": out["objects"], "solids": solids, "home": "town", "level": 0, "out": out}
	for s in SPOTS:
		add(c, s[0], s[1], s[2], s[3])


## A phone on the wall at `at` (on the wall's face), facing `yaw`.
static func add(c: Dictionary, key: String, at: Vector3, yaw: float, hours: Vector2) -> SmartObject:
	var o := Furnish.item(c, key, "Payphone", "payphone", at, yaw)
	o.home = "town"
	Props.part(o, Vector3(0.38, 0.62, 0.16), Vector3(0, 1.38, 0.09), Color("A8ACB0"))
	Props.part(o, Vector3(0.24, 0.2, 0.02), Vector3(0, 1.48, 0.179), Color("4A4A52"), null, false)         # the keypad
	Props.part(o, Vector3(0.08, 0.32, 0.08), Vector3(-0.25, 1.36, 0.11), Palette.INK, null, false)          # the handset
	Props.part(o, Vector3(0.02, 0.36, 0.02), Vector3(-0.22, 1.02, 0.14), Palette.INK, null, false)          # its cord
	Props.part(o, Vector3(0.3, 0.12, 0.012), Vector3(0, 1.82, 0.016), Color("2E5E9E"), null, false)
	CivicBuilder._label(o, "PHONE", Vector3(0, 1.82, 0.026), 0.0, Palette.PAPER, 0.0018, 40)
	Props.finish(o, c["solids"], Vector3(0.5, 0.8, 0.3), Vector3(0, 0, 0.75), null, Vector3(0, 1.4, 0.1), Vector3(0, 1.4, 0.15))
	(c["solids"] as Array).pop_back()        # (on the wall: it doesn't take up floor space)
	_calls(o, hours)
	return o


## An outdoor phone booth (a phone on a post under a little hood).
static func booth(c: Dictionary, key: String, at: Vector3, yaw: float) -> SmartObject:
	var o := Furnish.item(c, key, "Phone Booth", "payphone", at, yaw)
	o.home = "town"
	Props.part(o, Vector3(0.12, 2.1, 0.12), Vector3(0, 1.05, -0.2), Color("8A8E94"))
	Props.part(o, Vector3(0.7, 0.9, 0.5), Vector3(0, 1.55, -0.04), Color("C8CCD0"))
	Props.part(o, Vector3(0.6, 0.78, 0.02), Vector3(0, 1.5, 0.21), Color("3A3E44"), null, false)
	Props.part(o, Vector3(0.3, 0.46, 0.12), Vector3(0, 1.42, 0.15), Color("A8ACB0"), null, false)
	Props.part(o, Vector3(0.07, 0.28, 0.07), Vector3(-0.21, 1.4, 0.19), Palette.INK, null, false)
	Props.part(o, Vector3(0.74, 0.14, 0.52), Vector3(0, 2.08, -0.04), Color("2E5E9E"))
	CivicBuilder._label(o, "PHONE", Vector3(0, 2.08, 0.226), 0.0, Palette.PAPER, 0.0025, 40)
	Props.finish(o, c["solids"], Vector3(0.7, 2.2, 0.5), Vector3(0, 0, 0.8), null, Vector3(0, 1.45, 0.1), Vector3(0, 1.1, -0.04))
	_calls(o, Vector2(0.0, 24.0))
	return o


static func _calls(o: SmartObject, hours: Vector2) -> void:
	var list := [
		["Make a Prank Call", 5, {"fun": 36.0}, ["\"Is your refrigerator running? Then you'd better go catch it!\"", "You can't stop laughing long enough to say anything. Click."]],
		["Call Time & Temperature", 2, {"fun": 8.0}, ["\"At the tone, the time will be...\" Good to know!"]],
	]
	for l in list:
		var a := Activity.make(l[0], int(l[1]), l[2], "phone")
		a.money = -PRICE
		a.sound = "coin"
		a.messages = l[3]
		a.autonomous = l[0] != "Make a Prank Call"
		a.from_hour = hours.x
		a.to_hour = hours.y
		o.activities.append(a)
	# (the calls to people are added by Phonebook.apply)
