class_name SmartObject
extends StaticBody3D
## A piece of furniture that advertises things to do (the Sims "smart object"
## idea). The resident walks to approach_point, sits or stands at use_point,
## and faces look_point while busy.

var display_name := ""
## What kind of thing it is, for sounds and effects ("fridge", "phone", "tv", "bed"...).
var kind := ""
## Whose house it's in ("jamie", "hendersons"...), or "" for outdoors. Free Will
## only picks things at home or outside.
var home := ""
## The Sim using it right now (one at a time), or null.
var user: Node = null
## Which level it's on (0 = the neighborhood, 1 = attics and basements, underground).
var level := 0
## Doors between levels: where you come out.
var portal_to: SmartObject = null
## Several people can use it at once (a person you can talk to, a big table).
var shared := false
var activities: Array[Activity] = []
var approach_point := Vector3.ZERO
var use_point := Vector3.ZERO
var look_point := Vector3.ZERO
## Doors only: the hinge to swing and how far it opens.
var door_hinge: Node3D = null
var door_open_angle := 0.0
## Doors only: what you see beyond (shown when the door opens).
var door_message := ""
## Locked doors: the door panel that rattles, and which way it rattles.
var door_rattle: Node3D = null
var rattle_dir := Vector3.ZERO

var _mats: Array[StandardMaterial3D] = []
var _base: Array[Color] = []
var _lit := false


func add_material(m: Material) -> void:
	var sm := m as StandardMaterial3D
	if sm == null:
		return
	_mats.append(sm)
	_base.append(sm.albedo_color)


func set_highlight(on: bool) -> void:
	if on == _lit:
		return
	_lit = on
	for i in _mats.size():
		_mats[i].albedo_color = _base[i].lerp(Palette.GOLD, 0.4) if on else _base[i]
