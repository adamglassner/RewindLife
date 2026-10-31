class_name Changelog
extends RefCounted
## The game's version, and what changed in each one (shown on the WHAT'S NEW
## screen from the title screen and the pause menu). Newest first.

const VERSION := "1.9.0"
const YEAR := 2026          # (for the copyright line on the CREDITS screen)

const ENTRIES := [
	["1.9.0", "The whole town in Godot's 3D editor", [
		"world.tscn: open it in Godot to see the whole town in the 3D editor, in folders (Houses > Jamie > Fridge ...).",
		"Click walls, floors, trees and decorations one by one; select a fridge, a car or a townsperson as a whole.",
		"Change colors, shapes and parts, add things, delete things there: the game uses your changes.",
	]],
	["1.8.1", "Credits", [
		"CREDITS on the title screen and the pause menu: Rewind Life is a game by Ironite.",
	]],
	["1.8.0", "The town is made of assets", [
		"Every piece of furniture, building, townsperson, vehicle and decoration is now an asset file (assets/scenes) you can open and edit in Godot: change colors and patterns, reshape, move, add or delete parts, and the game uses your version.",
		"The same things as .glb 3D models (assets/models) for Blender and other programs, and the patterns as .png pictures (assets/textures).",
		"assets/town.tscn: the whole town put together, to look around in the editor.",
	]],
	["1.7.0", "School's in session, the mail truck, and real shows on TV", [
		"Two new schools out past the football field (Lincoln Avenue goes all the way out there now): Maple Grove Middle School and the two-story Maple Grove High School (take the stairs up to typing class, the computer lab and the library).",
		"The elementary school has a new wing: a second classroom, the library and the music room.",
		"Classes from September to May (with teachers and classmates); summer school in June, July and August.",
		"What's on TV is really on the TV: cartoons, a game show, the news, a sitcom, a soap, a cop show, music videos, ballgames, the parade, and every movie at Rewind Video, each with its own music.",
		"The mail truck comes by every morning but Sunday. No mail on Sundays, and none before the truck has been by.",
		"Knock on the neighbors' doors: their doors stay shut until somebody lets you in (and they might say not right now).",
		"Drive through the Rocket Burger drive-thru yourself: order at the menu board (E or A), pick it up at the window.",
		"Jump with Space (X on a controller). Pausing time moved to P.",
		"The debug menu can set the time too.",
		"Clearer messages when something isn't on: \"School's out for the summer!\", or too early for class.",
		"Trees in the woods are solid now (no more driving through them).",
	]],
	["1.6.2", "A debug menu, and menus that fit", [
		"The title and pause menus are laid out in two columns, so QUIT isn't cut off in a small (not full screen) window.",
		"DEBUG in the pause menu (password: password): change the date and how much money you have.",
	]],
	["1.6.1", "Glitch fixes", [
		"Posters, signs and window trim no longer float in mid-air when the House Cam lowers a wall: they go down with it.",
		"Cars watch the road they're about to drive (round corners and U-turns too), so they don't pile up where they come into town, back up looking the wrong way, or swing into the side of the fire engine or milk truck.",
		"One car at a time in the Rocket Burger drive-thru lane (it's only one car long), so cars don't end up inside each other at the menu board.",
		"Two cars waiting on each other (like two neighbors pulling out of mall parking spots at once) no longer wait forever.",
		"At top speed, townspeople walk as fast as the clock runs (shopkeepers aren't still walking home at 4 AM), and cars don't sit at the drive-thru for an hour.",
		"The tower computer no longer pokes through the diary on the kids' desks or Jamie's window.",
		"The snowman is solid: nobody walks through it.",
		"Pets don't settle down halfway down the basement stairs.",
		"A loaded game shows the computer you bought right away.",
	]],
	["1.6.0", "The mall opens, the east end of town, holidays and seasons", [
		"The Maple Grove Mall is open (10 AM - 9 PM): Trend Setters (11 new outfits to buy), the Toy Box, Spin City Records (records and CDs), Circuit Hut (computers and gadgets) and a food court with four places to eat.",
		"Teens hang out at the mall: goth kids, emo kids and preps.",
		"Main Street keeps going east: a skate park (with punks and kids with boomboxes, and the Shred Shack for a skateboard), Rocket Burger with a drive-thru, and Strike Zone Lanes for bowling.",
		"Townspeople drive their own cars around town, through the drive-thru and to the mall.",
		"Payphones in shops, civic buildings, the mall and two phone booths. Call any kid in town, Grandma, or Mom & Dad.",
		"Things you buy are yours to keep: play your Game Kid on your bed, records on the stereo, games on your new computer.",
		"New holidays: Valentine's Day, Easter (egg hunt), Halloween (costumes, trick-or-treating). The carnival and the circus come to the fairgrounds on random dates each year.",
		"Seasons: snow in winter (build a snowman), fall leaves (jump in the leaf pile), rainy spring days, summer sprinklers.",
		"Emotes: wave, dance, cheer and more (G, or click the right stick). Everyone online sees them.",
		"An in-game changelog (you're reading it), the version number on the menus, and a game icon.",
	]],
	["1.5.0", "Lincoln Avenue, chores, and two players on one screen", [
		"A civic street: police station with a jail, fire station with two engines, City Hall, the elementary school and its football field.",
		"A bike shop, a grocery store, three more houses (one with a pool).",
		"Shops open and close for real; doors lock after hours.",
		"Parents leave the house again; townspeople drive the police car, fire engines and milk truck, and chat with each other.",
		"Chores for Mom and Dad, a rare burglar at night, light switches by every door.",
		"2-player split screen with two controllers.",
	]],
	["1.4.0", "A town that's alive", [
		"Townspeople walking the sidewalks, a mom and dad in every house, pets, birds and squirrels.",
		"The Starlite Drive-In, six cars, the edge of town with woods and hills.",
		"Holidays: New Year's, Memorial Day, the 4th of July (fireworks), Labor Day, Thanksgiving, Christmas.",
	]],
	["1.3.0", "The whole neighborhood", [
		"Every house is a real house, with an attic and a basement.",
		"Parents (ask for your allowance), the paper route, Frosty's and Molly's lemonade stand.",
		"Make your kid: 12 hairstyles, 6 outfits, hair colors and skin tones. Pick who you play online, and chat.",
	]],
	["1.2.0", "Main Street", [
		"The library, the Sunrise Diner, Pizza Peak, Rewind Video and the Pixel Palace arcade.",
		"Rent movies, check out books, order pizza delivery.",
	]],
	["1.1.0", "Online play", [
		"Up to 4 players online: host or join, visit each other's houses.",
	]],
	["1.0.5", "Menus, saving and controllers", [
		"Title screen, pause menu, options, saving.",
		"Controller support, the kitchen and dining room, lots more to do.",
	]],
	["1.0.4", "The first neighborhood", [
		"Jamie's house, the street, the clock, four needs, Free Will and Memory Moments.",
	]],
]


## The whole list as text (for the WHAT'S NEW screen).
static func text() -> String:
	var lines := []
	for e in ENTRIES:
		lines.append("v%s  —  %s" % [e[0], e[1]])
		for b in e[2]:
			lines.append("  • " + String(b))
		lines.append("")
	return "\n".join(lines)
