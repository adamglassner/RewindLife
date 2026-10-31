class_name BowlingLanes
extends Node3D
## The pins and balls at Strike Zone Lanes. While somebody is bowling on a lane,
## a ball rolls down it every few seconds and knocks the pins over (sometimes all
## of them), then the pinsetter puts them back up.

const PIN_SPOTS := [Vector2(0, 0), Vector2(-0.15, -0.26), Vector2(0.15, -0.26), Vector2(-0.3, -0.52), Vector2(0, -0.52),
	Vector2(0.3, -0.52), Vector2(-0.45, -0.78), Vector2(-0.15, -0.78), Vector2(0.15, -0.78), Vector2(0.45, -0.78)]

var lanes: Array = []        # {x, foul, pin_z, pins: [MeshInstance3D], ball, users, t, phase, knocked}
var main: Node


func add_lane(x: float, foul_z: float, pin_z: float) -> void:
	var g := Node3D.new()
	g.position = Vector3(x, 0.03, 0)
	add_child(g)
	var pins: Array = []
	for p: Vector2 in PIN_SPOTS:
		var pin := Node3D.new()
		pin.position = Vector3(p.x, 0, pin_z + 0.8 + p.y)
		g.add_child(pin)
		RoomBuilder.box(pin, Vector3(0.1, 0.34, 0.1), Vector3(0, 0.17, 0), Palette.PAPER)
		RoomBuilder.box(pin, Vector3(0.104, 0.04, 0.104), Vector3(0, 0.25, 0), Color("C0322A"))
		pins.append(pin)
	var ball := RoomBuilder.box(g, Vector3(0.22, 0.22, 0.22), Vector3(0, 0.11, foul_z), Color("2E5E9E"))
	ball.visible = false
	lanes.append({"x": x, "foul": foul_z, "pin_z": pin_z + 0.8, "pins": pins, "ball": ball, "users": 0, "t": 0.0,
		"phase": "idle", "knocked": []})


## Somebody started (or stopped) bowling on lane `i`.
func set_bowling(i: int, on: bool) -> void:
	if i < 0 or i >= lanes.size():
		return
	var l: Dictionary = lanes[i]
	l["users"] = maxi(0, int(l["users"]) + (1 if on else -1))
	if int(l["users"]) > 0 and l["phase"] == "idle":
		l["phase"] = "wait"
		l["t"] = 0.6


func _process(delta: float) -> void:
	for l: Dictionary in lanes:
		match l["phase"]:
			"idle":
				continue
			"wait":
				l["t"] = float(l["t"]) - delta
				if float(l["t"]) <= 0.0:
					if int(l["users"]) <= 0:
						l["phase"] = "idle"
						continue
					l["phase"] = "roll"
					l["t"] = 0.0
					var ball: MeshInstance3D = l["ball"]
					ball.visible = true
					ball.position = Vector3(randf_range(-0.12, 0.12), 0.11, float(l["foul"]))
					l["aim"] = randf_range(-0.35, 0.35)
			"roll":
				l["t"] = float(l["t"]) + delta
				var k := clampf(float(l["t"]) / 2.2, 0.0, 1.0)
				var ball: MeshInstance3D = l["ball"]
				ball.position.z = lerpf(float(l["foul"]), float(l["pin_z"]) - 0.6, k)
				ball.position.x = lerpf(ball.position.x, float(l["aim"]), delta * 0.8)
				ball.rotate_x(-delta * 12.0)
				if k >= 0.86 and (l["knocked"] as Array).is_empty():
					_knock(l)
				if k >= 1.0:
					ball.visible = false
					l["phase"] = "down"
					l["t"] = 1.6
			"down":
				l["t"] = float(l["t"]) - delta
				if float(l["t"]) <= 0.0:
					for pin: Node3D in l["pins"]:
						pin.rotation = Vector3.ZERO
						pin.visible = true
					l["knocked"] = []
					l["phase"] = "wait"
					l["t"] = randf_range(2.5, 5.0)


func _knock(l: Dictionary) -> void:
	var strike := randf() < 0.25
	var aim: float = l["aim"]
	var knocked := []
	for pin: Node3D in l["pins"]:
		var near := absf(pin.position.x - aim) < 0.32
		if strike or (near and randf() < 0.85) or randf() < 0.2:
			knocked.append(pin)
			pin.rotation = Vector3(randf_range(1.2, 1.5) * (1.0 if randf() < 0.5 else -1.0), randf() * TAU, 0)
	if knocked.is_empty():
		knocked.append(l["pins"][0])
	l["knocked"] = knocked
	if main and main.audio:
		main.audio.play_at("bowling_strike" if knocked.size() == 10 else "bowling_pins", Vector3(float(l["x"]), 0.5, float(l["pin_z"])), -4.0)
