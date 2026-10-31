class_name Activity
extends RefCounted
## One thing the resident can do with an object: "Watch TV", "Make a Sandwich"...
## Activities are plain data, so adding content never means writing new logic.

var title := ""
var minutes := 30
var effects := {}             # need name -> points gained per game hour
var pose := "stand"           # stand, sit, lie, phone, reach, read, dance, hoops
var surface := 0.45           # seat or mattress height for sit / lie
var face_point := Vector3.ZERO  # look here instead of the object's look_point (if set)
var from_hour := 0.0          # available from this hour...
var to_hour := 24.0           # ...until this hour (can wrap past midnight, e.g. 20 -> 5)
var weekdays: Array = []      # 0 = Sunday ... 6 = Saturday. Empty = every day
var memory_id := ""           # first time doing this triggers a Memory Moment
var busy_after_hour := -1.0   # phone calls: the line may be busy after this hour
var tv_on := false            # turns the TV on while doing it
var autonomous := true        # false = only when the player asks (Free Will skips it)
var message := ""             # shown when it starts (e.g. "coming soon" places)
var messages: Array = []      # ...or one of these, picked at random
var sound := ""               # a sound to play when it starts (from res://audio)
var locked := false           # a locked door: it rattles instead of opening
var until_rested := false     # sleep: keeps going until Energy is full and it's morning
var bonus_from := -1.0        # Free Will likes this more between these hours...
var bonus_to := -1.0
var bonus_amount := 25.0      # ...by this much
var ui := ""                  # opens a screen when the player chooses it ("diary")
var loop_sound := ""          # a sound that repeats while doing it (record player, running water...)
var loop_db := -8.0
var end_sound := ""           # a sound when it's done (the microwave's beep)
var glow := ""                # a light/material in the room that glows while doing it ("burner_mat")
var money := 0.0              # dollars earned (or spent, if negative) when it's finished
var drive := false            # "Go for a Drive": the player takes the wheel
var needs_item := ""          # only if you have this ("tape", "book")
var gives_item := ""          # you get one when it's done (rent a tape, check out a book)
var gives_titles: Array = []  # ...picked from these titles
var gives_days := 0           # ...due back in this many days
var takes_item := ""          # you give it back when it's done (return the tape)
var late_fee := 0.0           # ...and pay this much per day it's late (up to $5)
var item_message := ""        # shown when starting; %s = the item's title
var done_message := ""        # shown when finished; %s = the item's title
var delivery := ""            # "pizza": order a delivery to your house
var teleport := false         # a door to another level: go through it (to the object's portal_to)
var talk := ""                # talking to someone: "chat", "allowance"
var needs_mail := false      # getting the mail: only after the mail truck has been by (and never on Sundays)
var paper := ""               # paper route: "apply", "quit", "pickup", "deliver"
var customize := false        # opens the look screen (the dresser and mirrors)
var holidays: Array = []      # only on these holidays (see holidays.gd), e.g. ["july4"]
var months: Array = []        # only in these months (1-12), e.g. the pool in summer
var chore := ""               # a chore for Mom and Dad (see chores.gd): pays once a day, at home
var ride := false             # "Ride Your Bike": hop on
var buys := ""                # buying something you keep ("bike", or a Catalog id: toys, clothes, records...)
var call_home := ""           # a phone call to this home's kid ("parents" = your own Mom & Dad); see phonebook.gd
var needs_owned := ""         # only if you own this (a Catalog id or group, e.g. "gamekid", "records")


static func make(t: String, mins: int, fx: Dictionary, p: String = "stand") -> Activity:
	var a := Activity.new()
	a.title = t
	a.minutes = mins
	a.effects = fx
	a.pose = p
	return a


## Holiday and seasonal things don't show up in the menu at all the rest of the year.
func hidden_now(clock: GameClock) -> bool:
	if not holidays.is_empty() and not holidays.has(Holidays.today(clock)):
		return true
	return not months.is_empty() and not months.has(clock.month())


static func in_window(h: float, from: float, to: float) -> bool:
	if from <= to:
		return h >= from and h < to
	return h >= from or h < to   # wraps past midnight


func available(clock: GameClock) -> bool:
	if not in_window(clock.hour_float(), from_hour, to_hour):
		return false
	if not weekdays.is_empty() and not weekdays.has(clock.weekday()):
		return false
	if not holidays.is_empty() and not holidays.has(Holidays.today(clock)):
		return false
	if not months.is_empty() and not months.has(clock.month()):
		return false
	return true


## Why it can't be done right now (for the notice), e.g. out of season or the wrong day.
func why_not(clock: GameClock) -> String:
	if not months.is_empty() and not months.has(clock.month()):
		if title.contains("Summer School"):
			return "Summer school is only in June, July and August."
		if title.contains("Class") or months == SchoolBuilder.SCHOOL_YEAR:
			return "School's out for the summer! Classes start again in September."
		return "\"%s\" isn't on this time of year." % title
	if not weekdays.is_empty() and not weekdays.has(clock.weekday()):
		return "Not today: \"%s\" is only %s." % [title, when_label()]
	var h := clock.hour_float()
	if from_hour <= to_hour and h < from_hour and from_hour - h < 4.0:
		return "Too early for \"%s\": it starts at %s (%s)." % [title, GameClock.fmt_hour(from_hour), when_label()]
	return "Too late for \"%s\" — it's only %s." % [title, when_label()]


func bonus_active(clock: GameClock) -> bool:
	return bonus_from >= 0.0 and in_window(clock.hour_float(), bonus_from, bonus_to)


## Short text explaining when this can be done, e.g. "SAT 7am–11am".
func when_label() -> String:
	var days := PackedStringArray()
	for d in weekdays:
		days.append(GameClock.DAY_NAMES[int(d)])
	var prefix := ("/".join(days) + " ") if days.size() > 0 else ""
	if not holidays.is_empty():
		var names := PackedStringArray()
		for k in holidays:
			names.append(Holidays.NAMES.get(k, k))
		prefix = " / ".join(names) + ", "
	return "%s%s–%s" % [prefix, GameClock.fmt_hour(from_hour), GameClock.fmt_hour(to_hour)]


func duration_label() -> String:
	if until_rested:
		return "until morning"
	if minutes >= 60:
		var h := minutes / 60.0
		if is_equal_approx(h, roundf(h)):
			return "%d hr" % int(h)
		return "%.1f hr" % h
	return "%d min" % minutes
