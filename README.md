# REWIND LIFE: Prototype 1

A first playable slice of the game: Maple Grove in 1986, with nine complete
houses (every one with a living room, dining room, kitchen, bathroom, a kid's
bedroom, the parents' bedroom, an attic, a basement and a backyard), Main
Street's shops, **the mall**, a skate park, a burger drive-thru, a bowling
alley, a civic street with a school, police station, firehouse and city hall,
the people who live there (and drive around town), a running clock, four
needs, things to use and things to buy, chores, holidays, the carnival and the
circus, seasons and weather, a diary, cars you can drive, a paper route (and a
bike for it), character customization, a title screen with saving, gamepad
support, **online play for up to 4 with chat and emotes, and 2-player split
screen**, music and sound effects. **WHAT'S NEW** on the title screen lists
every version's changes. **Everything in town is an asset file you can edit in
Godot** (see v1.8.0 below). It exists to answer one question: **is the core
daily-life loop fun before we invest in art?**

## How to run it

1. Install **Godot 4.3 or newer** (the standard version, not .NET): https://godotengine.org/download
   (Tested with Godot 4.7.2.)
2. Unzip this folder somewhere.
3. Open Godot, click **Import**, and pick the `project.godot` file in this folder.
4. Press **F5** (or the ▶ Play button, top right).

The first time it opens, Godot takes a few seconds to import. That's normal.

> Older or low-end graphics card? If the game window is black or slow, go to
> **Project → Project Settings → Rendering → Renderer** and choose
> **gl_compatibility**, then restart Godot.

## What's new in v1.9.0: the whole town in Godot's 3D editor

`main.tscn` is empty in the editor because the town is built by code when the game runs.
Now there's **`world.tscn`**: the whole town as a normal Godot scene, to look around in
and edit with Godot's own 3D tools.

### Opening it

1. Open the project in Godot.
2. In the **FileSystem** panel (bottom left), double-click **`world.tscn`**.
   (The first time, give it a few seconds: it's the whole town.)
3. The 3D view starts inside Jamie's house (it's in the middle of town). To get the
   overview: in the **Scene** panel, click a folder like **Houses** and press **F** (frame
   the selection), then fly around: hold the **right mouse button** and use **W A S D**
   (Q/E for down/up, the mouse wheel changes the flying speed).

### What's in it

    World
      EditorLighting    a sky and a sun, only for the editor (the game has its own)
      Buildings         Arcade, Diner, Library, Mall/Clothes ... School, HighSchool ...
      Characters        every townsperson, standing where they start the day
      Creatures         the birds and squirrels
      Decorations       every holiday at once (hidden to start: click the eye to see them)
      Houses            Jamie, Hendersons, Garcias ... (each with Fridge, Couch, Bed,
                        Structure for the walls and floors, Downstairs for the attic
                        and basement)
      Interiors         the ground under the attics and basements
      Outdoors          the yards, streets and trees in 32-meter squares, and the Woods
      Vehicles          cars, the police car, fire engines, the milk and mail trucks

Every object is one of the asset scenes in `assets/scenes` (nothing is copied).

### Selecting and editing

- **Click** in the 3D view to select. Walls, floors, trim, trees, yard things and
  decorations select **one piece at a time**. A usable object (a fridge, a car, a
  townsperson) selects **as a whole**; to get at its parts, right-click it in the Scene
  panel and tick **Editable Children**, or click the **clapperboard icon** next to it to
  open its own scene.
- **Change** colors and textures (the Material in the Inspector), sizes and shapes (the
  Mesh), and **move, turn or scale parts** with the usual tools (W/E/R).
- **Add** new things (a box, a light, a model you've imported) into any folder or inside
  an object: they appear in the game too, just to look at.
- **Delete** an object from the world (select it, press Delete) and it's gone from the
  game (it still works in the code, you just can't see it). To remove one *part* of an
  object, open the object's own scene and delete the part there.
- **Hiding** (the eye icon) is only for looking while you edit, and the game ignores it:
  hide a roof to see inside a house.
- Press **Ctrl+S** to save, then **F5** to play: your changes are in the game.

### What isn't carried over

- **Moving a usable object as a whole** (the fridge, a car, a person): where it stands, and
  where you walk to use it, comes from the code. The game says so (in the Output panel)
  and keeps it where the code puts it. Move its parts instead, or change its position in
  the code.
- **Townspeople and cars move around** in the game; here they stand where they start.
- The player kids aren't here (their looks come from the character maker).

### Nothing gets overwritten by itself

`world.tscn` is made by a tool, **only when you run it**:

    godot --headless --path . -s res://tools/build_world_scene.gd

It won't replace a `world.tscn` you've edited (add `--force` to do it anyway, which
throws your edits away). The asset baker (`tools/bake_assets.gd`) won't run while the
world or any asset has been edited, and it never touches `world.tscn`.

## What was new in v1.8.1: credits

**CREDITS** on the title screen and in the pause menu, next to **WHAT'S NEW** (the
changelog): Rewind Life is a game by **Ironite**, with the Ironite logo
(`assets/branding/`).

## What was new in v1.8.0: the town is made of assets

Everything you see in Maple Grove is now an **asset file you can open and edit in
Godot**: every piece of furniture and usable thing, each building's walls and floors,
every townsperson, every vehicle, each holiday's decorations, and the patterns
(carpet, plaid, brick, asphalt...). Edit one, press Play, and the game uses your
version.

    assets/
      scenes/            one Godot scene (.tscn) per thing, filed by where it is:
        houses/<family>/     fridge.tscn, couch.tscn, bed.tscn ... structure.tscn (walls,
                             floors, trim), downstairs.tscn (attic and basement)
        buildings/<place>/   diner/, library/, school/, mall/clothes/, bowling/ ...
        outdoors/<area>/     yards, streets, trees (the town in 32-meter squares),
                             outdoors/woods.tscn (the woods around town)
        characters/          every townsperson (clerk_diner.tscn, hendersons_mom.tscn ...)
        vehicles/            cars, the police car, fire engines, milk and mail trucks
        decorations/         christmas.tscn, halloween.tscn, easter.tscn ...
      models/            the same things as .glb 3D models, for Blender and other
                         programs (Godot skips this folder; the game doesn't use it)
      textures/          the patterns, as .png pictures
      (world.tscn, at the top of the project: the whole town, see v1.9.0)
      manifest.json      a fingerprint of every file as it was made (don't edit)
      edited.json        which assets you've changed (the game keeps this up to date)

**What you can change in an asset**, and see in the game:
- colors, textures and other material settings (shine, glow, see-through...);
- shapes: resize a box, or swap a box for any other mesh;
- move, turn or scale any part;
- add parts (new boxes, or drag in a model you've imported, like a .glb from Blender);
- delete parts;
- signs' text, lights' colors and range;
- edit a pattern .png in any paint program, and every asset using it changes.

**What stays in the code**: where each thing stands in town and what you can do with
it (moving a whole fridge asset moves its look, not the spot where you open it), who
walks where, and the player kids (their looks come from the character maker).

**How it works**: the game still lays the town out from the code, then checks every
asset file against its fingerprint (about a twentieth of a second) and puts anything
you've changed onto the town. Only the parts you actually changed are used, so
everything else keeps working exactly as before. Running the game from the Godot
editor writes down which assets you've edited (`assets/edited.json`); an exported copy
of the game (a .exe) reads that list, so **press Play once after editing, before you
export**.

**Making the assets again from the code** (after changing the code, say):

    godot --headless --path . -s res://tools/bake_assets.gd -- --pass=textures
    godot --headless --path . --import
    godot --path . -s res://tools/bake_assets.gd -- --pass=scenes

(The last step needs a window, not `--headless`.) This replaces every asset file, so
it stops and lists any asset you've edited; copy your changes somewhere first, then
add `--force`.

## What was new in v1.7.0: school's in session, the mail truck, and real shows on TV

**New schools.** Lincoln Avenue now runs all the way to the east edge of town, past
the football field, to two new schools on the north side:
- **Maple Grove Middle School**: homeroom (Mr. Dobbs), the science lab (Ms. Okafor:
  baking-soda volcanoes) and the band room (play the drums in the school band).
- **Maple Grove High School**, two stories. Downstairs: the cafeteria (buy a school
  lunch, eat with everybody), the chemistry lab and a classroom. Take the **stairs** at
  the end of the hall up to typing class, the computer lab and the library.

**Maple Grove Elementary** has a new wing out back: Classroom 2, the school library
and the music room (piano, xylophone), through doors from the classroom, the art room
and the gym.

**The school year.** Classes run **September to May**, Monday to Friday, 8 AM to 3 PM,
with teachers and classmates at their desks. In **June, July and August** it's **summer
school** instead (mornings, Monday to Thursday, at the elementary and the high school);
the middle school closes for the summer, and the chalkboards say so.

**What's on TV.** The TV shows a real picture now, with its own theme music: Saturday
cartoons, a game show, the news, a sitcom, a soap opera, a cop show, music videos, a
ballgame, the New Year's parade, the late movie, and every tape at Rewind Video (action,
horror, sci-fi or comedy, depending on the movie). What's on depends on the time of day
and the day of the week. (All made-up shows.)

**The mail truck** comes up Maple Street late every morning except Sunday, stopping at
every mailbox. There's no mail to get on Sundays, or before the truck has been by, and
once somebody's taken it in, that's today's mail.

**Knock on the door.** The neighbors' doors stay shut until you knock (click their front
porch) and somebody lets you in. Mostly they do; sometimes it's not a good time, it's
too late at night, or nobody's home. An invitation lasts a few hours.

**The drive-thru.** Drive up to Rocket Burger's menu board, press **E** (or **A**) to
order, and pull up to the window to get your food.

**Jump** with **Space** (**X** on a controller; Player 2: **RB**). **Pausing time moved to P.**

**The debug menu** can set the time of day too. **Every tree is solid**: the yard and street trees already were, and now the trees in the woods are too (no walking or driving through them).

## What was new in v1.6.2: a debug menu, and menus that fit

- **Menus fit a small window**: the title and pause menus are two columns of buttons, so
  QUIT is no longer cut off when the game isn't full screen.
- **DEBUG** (in the pause menu): type the password **password** to open it. For now it
  can set the **date** (month / day / year; the time of day stays the same, and the
  holidays, season and townspeople catch up) and your **money**. It stays unlocked
  until you quit the game. Playing online, only the host can use it.

## What was new in v1.6.1: glitch fixes

- **Wall decorations** (posters, store signs, window trim) hang on their wall, so they go
  down with it in the House Cam's cutaway instead of floating in the air. (Things you
  click, like wall phones and light switches, stay where you can reach them.)
- **Traffic**: cars check the stretch of road they're about to drive (round corners and
  U-turns too) against the whole body of every other vehicle, so they don't drive into a
  fire engine or a milk truck; they wait their turn coming into town; backing up, they look
  behind them; two cars blocking each other sort it out instead of waiting forever; and the
  drive-thru takes one car at a time (the lane is only one car long).
- **Top speed**: townspeople keep up with the clock, and cars don't idle at the
  drive-thru for an hour of game time.
- **Smaller things**: the tower computer sits clear of the kids' diaries and Jamie's
  window, the snowman is solid, pets don't nap on the basement stairs, and a loaded game
  shows the computer you bought right away.

**Still being worked on:** now and then two cars at a busy junction (like the mall lot
entrance) can still briefly drive through each other while they sort out who goes first.

**How it was checked:** two-day runs of the whole town on 11 dates (every season and
holiday) watching for anyone or anything stuck, overlapping or under the floor; a
traffic stress test (61 trips through the mall lot and the drive-thru); an online
test (a friend waves, buys a toy and calls home); the flicker, hole and reach checks.

## What was new in v1.6.0: the mall opens, the east end of town, holidays and seasons

**The Maple Grove Mall is open** (east end of Main Street, 10 AM to 9 PM). Walk in
the glass doors: a fountain (toss a penny), benches, the directory, and four stores:
- **Trend Setters** (clothes): **11 new outfits** to buy ($14 to $25): Members' Club
  Jacket, Preppy Polo & Sweater, Leather & Studs, Varsity Jacket, Hawaiian Shirt,
  Hypercolor Tee, Striped Hoodie, Velvet Long Coat, Denim on Denim, Sweater Vest &
  Tie, Aerobics & Leg Warmers. You wear it right away; after that it's in your
  dresser with the others. Plus two new hairstyles for everyone: Mohawk and
  Swoopy Fringe.
- **The Toy Box**: Sketch-O-Screen, Stair Spring, Game Kid Handheld, Furbit,
  Lite-Pegs, Walk-Tunes Cassette Player, Story-Time Teddy and a Milk Cap Game Set.
  (Made-up names, like the real ones from back then.) Try the Game Kid demo.
- **Spin City Records**: four records and three CDs from made-up bands, and a
  listening station.
- **Circuit Hut** (the electronics store): three home computers (the Color
  Computer II, the Micro-Pal 64 and the Turbo 386 Tower), a modem, a CD player,
  a calculator watch and an RC car.
- **The food court**: Slice of Napoli (pizza), Taco Loco (Mexican), Golden Dragon
  Wok (with free samples) and Cluck Shack (chicken), tables, and a bank of payphones.
- **Teens hang out at the mall**: the goth kids, the emo kids and the preps.

**What you buy is yours to keep.** The things you can do with it show up at home:
play your Game Kid on your bed or the couch, play your records on the stereo, a
CD on your bed (you need the CD player), and your new computer sits **on your
desk**: play games, type in BASIC, do homework for $1.50, or dial into a BBS
(with the modem).

**The east end of town** (Main Street runs further east now, and keeps going out
of town as the highway):
- **The skate park**: a half-pipe, a quarter pipe, a fun box and a grind rail.
  Buy a skateboard at the **Shred Shack** ($35) to skate them. **Punks** skate
  there, and **kids walk around with boomboxes** (you hear the music as they go by).
- **Rocket Burger**, with a **drive-thru**: burgers, fries, shakes and the Rocket Meal.
- **Strike Zone Lanes**: four lanes. **Bowl a game** ($1.50) and watch the ball
  roll and the pins fly. Shoe rental, a snack bar and a pinball machine.
- **The fairgrounds** (north of the east end of Maple Street), where the carnival
  and the circus set up.
- **Townspeople drive their own cars.** Now and then a car comes into town on the
  highway: through the Rocket Burger drive-thru (it stops at the menu board and
  the window), to the mall to shop for a while, or around the block.

**Payphones** (a quarter a call) at the diner, Pizza Peak, the arcade, the grocery
store, the police station, City Hall, the school, Rocket Burger, the bowling
alley, the mall, and phone booths by the bus stop and the skate park.
**Call anybody**: every kid in town, Grandma, and your own **Mom & Dad** (from a
payphone or a friend's phone). Call too late and a parent answers. If the kid
you call is being played (online or split screen), their phone rings.

**New holidays:**

| Holiday | Date | What happens |
|---|---|---|
| Valentine's Day | Feb 14 | Hearts on the houses all week, valentines in the mailbox, candy hearts, make valentine cards at your desk |
| Easter | a Sunday in spring (Mar 30 in 1986) | An **egg hunt** in the front yards, an Easter basket by the couch |
| Halloween | Oct 31 | Jack-o'-lanterns on every porch (from the 20th), **dress up** as a ghost or a vampire at your dresser, **trick-or-treat** at the porches after 5:30 PM |
| **The Carnival** | 4 days each summer, picked at random each year (**June 21-24 in 1986**) | A Ferris wheel and a carousel you can ride, ring toss, balloon darts, the duck pond, cotton candy, corn dogs |
| **The Circus** | 3 days each spring or fall, picked at random (**Oct 11-13 in 1986**) | The big top (watch the show), the strongman bell, popcorn, clowns with balloon animals |

The sign at the fairgrounds always says when they're coming next.

**Seasons:**
- **Winter** (Dec-Feb): snow on the ground, frosted trees, snow falling some days.
  A snow drift in your front yard: **build a snowman** (it stays up until spring),
  make snow angels, have a snowball fight.
- **Spring** (Mar-May): fresh green leaves, and **rainy days** now and then (gray
  skies, rain, the sound of it).
- **Summer** (Jun-Aug): **sprinklers** going in some front yards. Run through them!
- **Fall** (Sep-Nov): orange, red and gold leaves, and a **leaf pile** to jump in
  (or rake, for Mom and Dad: $1.50).

The weather comes from the date, so it's the same for everyone playing online.

**Emotes**: wave, dance, laugh, cheer, thumbs up, shrug, air guitar, facepalm,
point & laugh, take a bow. Press **G** (or click the right stick); Player 2
presses **Y**. Everyone online sees them.

**Version numbers and a changelog in the game**: the version is on the title
screen and the pause menu, and **WHAT'S NEW** (on both) lists every version.

**A game icon**: an 80s sunset and a cassette with a rewind symbol
(`assets/icon.png`, plus `assets/icon.ico` for the Windows .exe). It's set in
`project.godot`, so it shows in the Godot project list, the window's title bar
and the taskbar.

**Checks before this release:** the flicker check and the hole check (below) both
came back clean, and every usable thing in the world can be walked to.

Online players need the same version: v1.6.x can't join a v1.5.0 game (v1.6.0 and v1.6.1 can play together).

## What was new in v1.5.0: Lincoln Avenue, chores, and two players on one screen

**A new street: Lincoln Avenue** (north of the houses; walk up Oak Avenue or
the footpath past the Millers' house)
- **Maple Grove Police**, with Sergeant Kowal at the desk, a wanted board and
  a **jail cell** (with a cot and bars).
- **Fire Station No. 1**: two **fire engines** in the bays, a brass pole, the
  bunks, the kitchen table, Captain Riley, and Sparky the Dalmatian.
- **City Hall**: columns, a clock cupola, the flag, the clerk's counter, the
  records room and the mayor's office.
- **Maple Grove Elementary**: a classroom with desks and a chalkboard, the art
  room, the gym (hoop and climbing rope), lockers, the trophy case and the
  principal. Out back: **Maverick Field**, with goalposts, bleachers, a
  scoreboard, lights, Coach Dumbrowski and the school bus.
- Everything on Lincoln keeps business hours: the school and City Hall are
  open on weekdays and lock up at night; the police and firehouse never close.

**Main Street grows**
- **Spoke & Pedal**, the bike shop: save up **$60 for a BMX**. It's parked right
  outside the shop; click it to **ride** (2.4x faster than walking). **On the paper route,
  you toss papers from the bike** without walking up to each porch.
- **Corner Grocery**: snacks, canned goods, produce, a freezer case, and the
  checkout (bag groceries for tips).
- **The Maple Grove Mall** at the east end. *Grand opening soon*: the doors are
  locked for now.
- **Shops open and close for real.** Each shopkeeper walks in to open up in the
  morning and walks out and heads home at closing time, and **the doors are
  locked while a shop is closed** (if you're inside at closing, they wait for
  you to leave). Try to get in after hours and you're told when it opens.

**More neighbors:** three new houses on Maple Street (the Millers, the O'Briens
and the Brooks), each with a family and a kid. **The O'Briens have a pool**
(swim, cannonball off the diving board).

**The town moves**
- **Parents leave the house again**: Mom runs errands to the grocery store,
  checks the mail, chats on the sidewalk and works in the yard; Dad takes the
  bus to work on weekdays and does yard work on Saturdays. You can always tell
  who's who: **your own mom and dad have a gold name tag**, and other parents
  show whose parents they are ("Mrs. Nguyen · Kevin's mom") whenever you're near.
- **Townspeople drive**: the milkman makes his rounds before dawn in the milk
  truck (stopping at every house), Officer Dwyer patrols in the police car,
  and the firefighters take the engines out for drills (sirens and all). They
  park back where they started.
- **People talk to each other.** Neighbors stop on the sidewalk and chat (you
  can see what they say), and kids talk with kids.

**Chores:** ask Mom or Dad **"What Chores Need Doing?"** Get the mail, take out
the trash, do the dishes, the laundry, make your bed, set the table, vacuum,
mow the lawn, weed the garden, wash the car, walk the dog, feed the pet. Each
pays a little, once a day.

**A burglar (rarely!).** Late at night there's a very small chance a burglar
sneaks into your house. Get to him and press **Stop the Burglar!** The police
come, put him in the jail cell for **30 days**, and you get a reward. If he
gets away, he may try again some other night; after his 30 days, he's back on
the streets and might try again too.

**Lights work like everything else:** walk up to the **light switch** by the
door (or a floor lamp) and use it, the same way you use anything else. (The L
key is gone.)

**2 players on one screen.** Plug in **two controllers**, and press **START on
the second one** (or choose **2 PLAYERS** in the pause menu) to split the
screen. Player 2 picks a kid and plays on the right half with the second
controller; Player 1 keeps the keyboard and mouse and the first controller on
the left. Player 2's controls: left stick walk, right stick look, **A** use,
**X** stop, click the left stick to run, **START** for Player 2's menu (Free
Will, or leave). Player 1 does the driving and the time controls; first
person is off while you share the screen. Split screen is for playing on one
computer; it can't be combined with online play.

**Fixes**
- **No more holes in the world.** The thin gaps around the houses' foundations
  are filled, and the missing faces between the stair steps are closed.
- **No more flickering surfaces**, again: everything that sat in the same
  place as something else was separated (the chairs' arms, the curtains, the
  calendar, the stair railings, the curbs, the new buildings, the bikes, the
  mowers, the pool and more).
- **Squirrels stay outside** instead of running through houses.
- **Pizza Peak has one sign** sitting on the roof, not a second one floating.
- **The drive-in's slots fit a car**: two rows of wide, painted spaces.

**Checking for problems before every release:** two tools now scan the whole
world for these. Run them before each update:

```
godot --headless --path . -s res://tools/flicker_check.gd     # surfaces that would flicker; "TOTAL 0" = all clear
godot --rendering-driver opengl3 --path . -s res://tools/hole_check.gd -- --out=holes   # holes you can see through
```

Online players need the same version: v1.5.0 can't join a v1.4.0 game.

## What was new in v1.4.0: a town that's alive

**People and pets**
- **Twelve townspeople walk the sidewalks** now (kids too), all over Maple
  Street, Main Street and the drive-in. **Everyone can be talked to**, including
  the shopkeepers on Main Street (the librarian, the diner cook, the pizza guy,
  the video clerk and the arcade attendant), who now stand and turn to face you.
- **Every house has a mom and a dad, and they stay home**: the kitchen in the
  morning, the living room, the dinner table, their room, and **asleep in their
  own bed at night**.
- **Names depend on whose house it is.** At home it's "Mom", "Dad" and "Mom &
  Dad's Room". At a friend's house it's "Mrs. Nguyen" and "Mr. & Mrs. Nguyen's
  Room". The room you're in now shows under the clock.
- **Jamie's family gets a random last name** with each new game (no more
  Glassman). Online, everyone sees the same one.
- **Pets:** Biscuit the dog (Jamie's), Whiskers the cat (the Hendersons'), Bandit
  the dog (the Garcias'), Mittens the cat (the Nguyens') and Duke the dog (the
  Parkers') wander their houses. Pet them, play fetch, dangle a string, feed them.
- **Birds** hop and peck on the lawns and fly off when you get close. **Squirrels**
  dash between the trees and scramble up the trunks.
- **Hit someone with a car and they'll let you know** ("Ouch!"). The cars no
  longer drive through the kids, either.

**Places**
- **The Starlite Drive-In** at the east end of town: a big screen, speaker posts
  with picnic blankets, and Lou's snack bar. **Shows nightly 8 PM to 1 AM**
  ($2.00 for the double feature; popcorn, soda and candy).
- **Six cars** now: the wagon and the hatchback in Jamie's driveway, Mr. Garcia's
  pickup in his driveway, and a sedan, the Hendersons' van and a red convertible
  parked along the curbs. Any of them can be driven.
- **The edge of town:** each street ends at a striped barricade with a DEAD END
  sign, with woods beyond. Trees fill the empty lots, and there are fields,
  rolling hills and the Maple Grove water tower on the horizon.

**Holidays**

| Holiday | Date | What happens |
|---|---|---|
| New Year's Day | Jan 1 | Fireworks just after midnight, the parade on TV in the morning |
| Memorial Day | May 25 | Flags on every porch, a cookout at the grill |
| Independence Day | July 4 | Flags and bunting all week, a cookout, **fireworks 9-11 PM** (watch from the blanket in the front yard) |
| Labor Day | Sept 7 | Flags, the last cookout of summer |
| Thanksgiving | 4th Thursday in November | A turkey on every family's dining table: sit down for dinner |
| Christmas | Dec 25 | Lights and a wreath on every house all December, a tree in the living room, **open your presents** Christmas morning |

**Controls**
- **Run:** hold **Shift** in first person or over the shoulder (or click the left stick).
- **Lights:** press **L** (or click the right stick, or the **LIGHTS** button under
  the clock) to switch the lights in the room you're in on or off. Online,
  everyone sees it.

**Clearer boys and girls:** girls have eyelashes, pink lips, rosy cheeks, little
gold earrings and a slimmer build; boys have eyebrows and broader shoulders.

**Fixes**
- **You can walk into the laundry room and Mom & Dad's room in Jamie's house**
  in first person. The family photos' invisible frame was blocking both doorways.
- **Flickering, flashing textures:** the stripe and brick textures had no
  mipmaps, so they shimmered and flashed in the distance. They're smooth now. I
  also softened the sun's shadows on the floors and lawns, separated a few
  surfaces that sat too close together (the driveways and sidewalks, the
  hallway rug), and fixed the drive-in sign.
- Shopkeepers, Molly and Frosty were facing the wrong way. They now face you.

Online players need the same version: v1.4.0 can't join a v1.3.0 game.

## What was new in v1.3.0: the whole neighborhood

**Every house is a real house now.** Jamie's house and all five neighbors'
houses (the Hendersons, Garcias, Kowalskis, Nguyens and Parkers) have the same
rooms, each with walls, working doors, windows, lights and furniture:

| Room | What's in it |
|---|---|
| Living room | TV, couch, armchair, bookshelf, floor lamp |
| Dining room | A table to eat at (where delivered pizza shows up) |
| Kitchen | Fridge, stove, sink and counter, wall phone |
| Bathroom | Bathtub (bath or shower), toilet, sink with a mirror |
| The kid's bedroom | Bed, desk with a diary, dresser with a mirror, a poster |
| Mom & Dad's room | A big bed, nightstands, the closet (snoop for presents!), Mom's vanity |
| Attic (up the stairs) | Old trunks, holiday decorations, a rocking horse or a telescope, boxes |
| Basement (down the stairs) | A pool or ping-pong table, an old game system, a workbench, weights or an arcade cabinet, the furnace |
| Backyard | Fenced, with a swing set, kiddie pool, garden, trampoline or picnic table |

The houses are all a little different: sizes, which way round they are, the
order of the bedrooms, colors, a garage or a chimney, what's in the attic and
basement, and the yard. Jamie's house got its north wing (the bathroom, laundry
room and Mom & Dad's room) and its attic and basement too. Go through the attic
door or the basement door and you're there; the stairs inside bring you back.
Ask for something in another room and your kid walks there on their own,
stairs and all.

**People.** Every family has a **mom and dad** who go about their day (the
kitchen in the morning, the living room, out in the yard, off to work on
weekdays, to bed at night). **Talk to your own parents and ask for your
allowance: a dollar, once each time you play.** Six townspeople **walk the
sidewalks** of Maple Street and Main Street; click one to say hi or ask what's
new in town. People stop and turn to talk to you.

**Jobs and treats:**
- **The paper route.** Go to **The Maple Grove Gazette** on Main Street and ask
  Mr. Gruber for the job. Pick up your papers between 6 and 10 AM, then toss one
  on every porch on Maple Street (click a house's doormat). Finish the route
  for **$4.00**.
- **Frosty's**, the ice cream stand next to the Gazette (noon to 9 PM):
  soft-serve 75¢, a push-up pop 50¢, a banana split $2.25.
- **Molly Parker's lemonade stand** in the Parkers' backyard (10 AM to 6 PM): 25¢ a cup.

**Make your kid.** New Game starts with the look screen: **girl or boy**, twelve
**80s and 90s hairstyles** (mullet, big perm, feathered, side ponytail, high-top
fade, teased & sprayed, curtains, bowl cut, frosted spikes, layered, scrunchie
ponytail, buzz cut), six hair colors, six skin tones and **six outfits**
(neon windbreaker, acid-wash jacket, track suit, grunge flannel, overalls &
stripes, color block & baggy jeans). Change your look any time at your dresser
or the bathroom mirror.

**Online:**
- **Choose who you play.** The host and each friend pick one of the six Maple
  Street kids (Jamie, Danny, Rosa, Kevin, Stacy or Marcus), then make their look.
  Up to 4 players, one kid each.
- **Chat.** Press **T** (or **Enter**) to type, **Enter** to send.
- The townspeople, parents and everyone's looks are the same on every screen.

**Cars and fixes:**
- Both cars are parked in Jamie's driveway, side by side, and the driveway is
  wide enough for both. Round wheels. The cars slide along walls and curbs
  instead of bouncing off them, and you can get out anywhere you can drive,
  Main Street too.
- The shops on Main Street have **real glass double doors** that swing open.
- **Fixed flickering ("z-fighting") textures** everywhere we could find them: a
  scan of every surface in the game, in first person and from all sides of the
  House Cam, found and fixed the spots (walls meeting the new wing, the kiddie
  pool, stair pits, porch lights, posters, a hairstyle).

Online players need the same version: v1.3.0 can't join a v1.2.0 game. Saved
games from v1.2.0 still load (the cars go back to the driveway).

## What was new in v1.2.0: Main Street

A block south of Maple Street (walk between the Kowalskis' and the Nguyens'
houses, or drive down Oak Avenue) is **Main Street**, with five places to go.
Prices come out of your wallet, and each place keeps its own hours.

| Place | Hours | What to do |
|---|---|---|
| **Maple Grove Public Library** | 9 AM - 8 PM | Get a library card, **check out a book** (free, due in a week, 10¢ a day late), browse the shelves and card catalog, read or do homework at the tables, return your book |
| **Sunrise Diner** | 6 AM - 3 PM | **Breakfast** ($3.50, until 11), pancakes ($2.75), hot cocoa & a donut ($1.25), milkshakes ($1.75), at the counter or in a booth |
| **Pizza Peak** (the one with the big red roof) | 11 AM - 11 PM | A pan pizza ($5.99), a slice ($1.50), a root beer float ($1.00), the salad bar ($2.50), the jukebox (25¢) |
| **Rewind Video** | 10 AM - 10 PM | **Rent a movie** ($2.99 for 2 days, $1 a day late), browse new releases and the horror aisle, buy candy, return your tape ("Be kind, rewind!") |
| **Pixel Palace Arcade** | 11 AM - 11 PM | Six arcade games (25¢ each): Astro Blaster, Ghost Maze, Turbo Racer, Kung Fu Alley, Frog Crossing, Dragon Tower; pinball (50¢); the prize counter |

**Back home:**
- A rented movie plays on any TV ("Watch Your Rented Movie").
- A library book can be read on any bed or couch, or the bean bag.
- **Order pizza delivery** on any wall phone ($8.99, 11 AM - 10:30 PM). About 30
  minutes later the doorbell rings and the pizza is waiting on your table.

What you're carrying (a tape, a book) shows at the top right where the Era used
to be. You can only have one of each at a time. Free Will never goes shopping
on its own, so Jamie won't spend your money without you. Walking is faster on
fast-forward now, so trips downtown don't eat the whole day. The cars are the
quickest way to get there, though. Six new Memory Moments.

New sounds: a cash register, the arcade's chiptune music, the doorbell, and a
VCR rewinding.

Online players need the same version: v1.2.0 can't join a v1.1.0 game.

## What was new in v1.1.0: online play

- **Up to 4 players online.** One player hosts and plays Jamie. Up to three
  friends join and play the kids next door: **Danny Henderson**, **Rosa Garcia**
  (both next door) and **Kevin Nguyen** (across the street). Everyone has their
  own needs, money, Up Next list, Free Will and Memory Moments.
- **The neighbors' houses have insides now.** The Hendersons', Garcias' and
  Nguyens' houses each have a living area (TV, couch, bookshelf), a bedroom
  corner (bed, desk with a diary, dresser and mirror) and a kitchen (fridge,
  stove, sink, table and a wall phone). A house's front door opens when its kid
  is in the game; otherwise it's locked and you can only knock.
- **Visit each other.** Walk over and watch TV together, eat at each other's
  tables, take turns driving the cars, and honk at each other. Only one person
  can use a thing at a time ("Danny is using the couch right now").
- **Time runs in real time online** (no pausing or fast-forward), but nights fly
  by once *everyone* is asleep.
- **The host's computer saves the online world**, including each friend's
  progress, which is waiting for them when they come back. It's a separate save
  from your single-player game.

## What was new in v1.0.5

- **Title screen and pause menu.** The game opens on a VHS-style title screen
  over the neighborhood: Continue, New Game, Options (music and sound volume,
  look sensitivity, invert look, fullscreen), Controls and Quit. **Esc** (or
  **Start**) opens the pause menu: Resume, Save Game, Options, Controls, Quit.
- **Saving.** One save slot: the time, Jamie's needs, money, Memory Moments,
  where she is and where the cars are parked. The game also saves when Jamie
  wakes up, when you quit to the title, and when you close the window.
- **Controller support** (Xbox, PlayStation and most others). Every menu works
  with the D-pad/stick and A/B. In the House Cam the left stick moves a pointer
  (press A to use what's under it or walk there), and the right stick turns and
  zooms. The on-screen hints switch to controller buttons when you pick one up.
- **The kitchen and dining room** (through the door at the east end of the
  hallway): fridge, microwave, sink, stove with a range hood, a cookie jar, the
  wall phone, and a dining table with four chairs.
- **Lots more to do.** Microwave popcorn, leftovers, a glass of water, washing
  the dishes (+$1.50), mac & cheese, weekend pancakes, sneaking cookies, family
  dinner, board games, jigsaw puzzles, homework (+$1.00); records, mixtapes and
  dancing at the new living-room stereo; Dad's recliner; books; comic books and a
  handheld game on the bean bag; the puzzle cube; the boombox and the mirror;
  family photos; grilling burgers; the tire swing; shooting hoops; sunbathing on
  the lawn chairs; washing the car (+$3.00). Six new Memory Moments.
- **The Wallet works.** Chores pay, and the wallet updates.
- **Drivable cars.** Use the station wagon in the driveway or the hatchback
  across the street and choose **Go for a Drive**. A chase camera follows; drive
  up and down Maple Street and Oak Avenue, honk, bump into things, and park
  anywhere. Stop, then press **E** (or **A**) to get out. Headlights come on at night.
- **Fixed:** the last flickering spots: the stereo's record stack, the microwave
  trim, the calendar, the stove beside the counters, and the car wheels.

## What was new in v1.0.4

- **Fixed:** flickering and "fighting" textures inside the house. Ceilings and
  roofs, overlapping wall corners, and the doorway floor strips no longer sit in
  the same spot. Each room now shows its own wall finish where a wall is shared
  (no more living-room paneling inside the bedroom).
- **Fixed:** grass growing through the basement stairs. The lawn now stops at the
  house walls.
- **New:** the stairs are walkable. Jamie climbs to the attic door and walks down
  to the basement door, by clicking or in first person. The half wall between the
  flights keeps her from hopping between them.

## Playing online

**To host:** on the title screen choose **PLAY ONLINE → HOST GAME** (or
**HOST A NEW WORLD** to start the online world over), pick your kid and your
look. The pause menu (**Esc**) shows the addresses your friends should type.

**To join:** choose **PLAY ONLINE**, type the host's IP address, and press
**JOIN GAME**. Pick one of the kids nobody's playing yet, and your look.

**Chat:** press **T** or **Enter**, type, and press **Enter** to send (**Esc** to cancel).

- **Same Wi-Fi / home network:** use the host's local address (it looks like
  `192.168.x.x` and is shown in the host's pause menu).
- **Over the internet:** the host has to forward **UDP port 24886** on their
  router to their computer, and friends type the host's *public* IP address
  (search "what is my IP" on the host's computer). Without port forwarding,
  friends far away can't connect; a "join with a code" option would need an
  online relay service, which this prototype doesn't have.
- **Windows** may ask whether to let the game use the network the first time you
  host. Allow it (at least for private networks).
- Everyone needs the **same version** of the game; a different version is told
  so and can't join.
- **Trying it on one computer:** in Godot choose **Debug → Customize Run
  Instances**, turn on multiple instances and set 2 (or more), then press F5. Host
  in one window and join `127.0.0.1` in the other.

While online, the pause menu doesn't stop the game (everyone else keeps
playing), only the host can save, and closing the game as the host ends it for
everyone (it's saved first).

## Controls

| | House Cam (default) | Over Shoulder / First Person |
|---|---|---|
| Use an object | Click it, pick an activity | Look at it, press **E** (or click) |
| Move Jamie | Click the floor | **WASD** |
| Camera | **WASD** pan · **Q/E** or right-drag rotate · wheel zoom | Mouse look |
| Anywhere | **C** switch camera · **Space** jump · **P** pause time · **1/2/3** speed · **F** Free Will · **M** music on/off · **Esc** close / pause menu · **Tab** free mouse · **T** chat (online) |
| Walking yourself | hold **Shift** to run | |
| Lights | Use the light switch by the door, or a lamp | |
| Emotes | **G** (wave, dance, cheer...) | |
| Driving | **W** gas · **S** brake/reverse · **A/D** steer · **H** horn · **E** get out (when stopped) | |

**Controller:**

| | |
|---|---|
| Left stick | Walk (first person / shoulder) · move the pointer (House Cam) · steer |
| Right stick | Look · turn and zoom the House Cam |
| A | Use / select / get out of the car |
| B | Back / close |
| X | Stop what Jamie's doing · horn while driving |
| Y | Switch camera |
| RT / LT | Gas / brake and reverse |
| LB / RB | Slower / faster |
| D-pad | Up/down zoom · left Free Will · right music |
| Start | Pause menu |
| Back (View/Share) | Pause time |
| Click the right stick | Emotes |
| Start on a 2nd controller | 2 players, split screen |

Writing in the diary needs a keyboard; with a controller you can still read it.

The **X** next to anything in *Up Next* cancels it. **Free Will** lets Jamie
choose for herself when nothing is queued.

## Things to try

- **Just watch.** Leave Free Will on and press **3**. Jamie heads for Saturday
  morning cartoons and triggers your first **Memory Moment** (the screen goes soft
  and a scrapbook card appears).
- **Ask Mom for your allowance.** She's in the kitchen or the living room. Then
  spend it: walk to Main Street (between the Kowalskis' and the Nguyens'),
  get a cone at Frosty's, or a lemonade from Molly out back at the Parkers'.
- **Get the paper route.** Be at the Gazette between 6 and 10 AM, pick up your
  papers, and hit all six porches.
- **Explore upstairs and down.** Click the attic door at the top of the stairs
  or the basement door at the bottom. Dig through the old trunk, shoot pool in
  the basement, look at the stars through a telescope at night.
- **Snoop in Mom & Dad's closet** (there might be presents in there), try on
  Mom's makeup, take a bubble bath, do the laundry for a dollar.
- **Change your look** at your dresser. Go full 90s.
- **Switch cameras** while doing something. First person puts you on the couch
  watching the TV.
- **Stay up past 9 PM.** The lamps come on, the windows go navy, the Late Movie
  unlocks, and the parents head to bed around 10:30.
- **Take the car out.** Click the station wagon or the hatchback in the
  driveway, choose "Go for a Drive", and cruise down Maple Street. Stop and press
  **E** (or **A**) to get out wherever you parked.
- **Go to sleep.** The lights go out, the glow-in-the-dark stars glow, and time
  speeds up overnight.
- **Write in the diary** at your desk. The game pauses while the notebook is open.

## How the code is organized

The town is laid out and run from code; how everything looks is in the asset files
(`assets/`, see v1.8.0 above), which the baker makes from the code.

| File | What it does |
|---|---|
| `scripts/asset_library.gd` | The assets: what counts as one thing and where its file goes, and putting edited assets onto the town at startup. |
| `tools/bake_assets.gd` | Makes the asset files (scenes, .glb models, .png patterns) from the code. |
| `tools/build_world_scene.gd` | Puts the asset scenes together into `world.tscn`, the whole town for the 3D editor. |
| `scripts/game_clock.gd` | The heartbeat. Starts Sat June 14, 1986, 8 AM. Emits `minute_passed` once per game minute. |
| `scripts/needs.gd` | Hunger, Energy, Fun, Social: decay over time, mood calculation. |
| `scripts/activity.gd` | One thing to do: duration, need effects, time window, pose, Memory Moment. Pure data. |
| `scripts/smart_object.gd` | Furniture that *advertises* activities (the Sims "smart object" idea). |
| `scripts/content.gd` | **All game content lives here.** Add an activity by copying a block. |
| `scripts/sim.gd` | A character (one of the six kids, listed at the top): grid pathfinding, going up and down to the attic and basement, activity queue, poses, Free Will (utility AI), allowance and the paper route. |
| `scripts/looks.gd` | Hairstyles, outfits, hair colors and skin tones, and the blocky body everyone is built from. |
| `scripts/customizer.gd` | The look screen. |
| `scripts/npc.gd` | Townspeople: walking, schedules, stopping to talk. |
| `scripts/town_folk.gd` | Who lives in Maple Grove: the parents, the walkers, Molly, Frosty and Mr. Gruber, and what they say. |
| `scripts/chat_box.gd` | Online chat. |
| `scripts/families.gd` | Last names, and what rooms and people are called depending on whose house it is. |
| `scripts/pets.gd` | The dogs and cats. |
| `scripts/critters.gd` | Birds and squirrels. |
| `scripts/holidays.gd` | The holidays: dates, decorations and fireworks. |
| `scripts/civic_builder.gd` | Lincoln Avenue: the police station and jail, the firehouse, City Hall, the school and the football field (a map is drawn at the top). |
| `scripts/town_life.gd` | What happens around town: the milk run, police patrols, fire drills, people chatting, and the burglar. |
| `scripts/npc_vehicle.gd` | The police car, fire engines and milk truck, driven by townspeople along the streets. |
| `scripts/chores.gd` | Chores and what they pay. |
| `scripts/light_switches.gd` | A light switch by the door of every room with lights. |
| `scripts/split_screen.gd` | 2 players on one screen (needs two controllers). |
| `scripts/mall_builder.gd` | The mall: its four stores, the concourse and the food court (a map is drawn at the top). |
| `scripts/east_builder.gd` | The east end: the skate park, Rocket Burger and its drive-thru, the bowling alley, the fairgrounds, the mall parking lot (map at the top). |
| `scripts/catalog.gd` | Everything you can buy and keep (toys, records, computers...), and what you can do with it at home. |
| `scripts/payphones.gd`, `scripts/phonebook.gd` | Payphones and phone booths; who you can call and what they say. |
| `scripts/event_grounds.gd` | The carnival and the circus at the fairgrounds. |
| `scripts/seasons.gd` | Seasons and weather: snow, fall leaves, rain, sprinklers, the snowman and the leaf pile. |
| `scripts/bowling_lanes.gd` | The balls and pins at the bowling alley. |
| `scripts/changelog.gd` | The version number and the WHAT'S NEW list. |
| `tools/flicker_check.gd`, `tools/hole_check.gd` | Scan the world for flickering surfaces and holes. Run before every release. |
| `scripts/scenery_builder.gd` | The edge of town: barricades, woods, fields and hills. |
| `scripts/camera_rig.gd` | House Cam (with wall cutaway), Over Shoulder, First Person. |
| `scripts/hud.gd` | The pixel UI from the mockups. Shows state and sends requests; never changes game data. |
| `scripts/room_builder.gd` | Builds the living room from boxes, the shared building helpers (walls, doors, floors, lights), and the whole-house walking grid. |
| `scripts/house_builder.gd` | The hallway, the north wing (bathroom, laundry, Mom & Dad's room), the split staircase and Jamie's bedroom. A floor plan is drawn at the top of the file. |
| `scripts/kitchen_builder.gd` | The kitchen and dining room. |
| `scripts/neighbor_builder.gd` | The five neighbors' houses, inside and out. The floor plan they share is drawn at the top. |
| `scripts/interior_builder.gd` | Every house's attic and basement (built underground, with their own walking grid). |
| `scripts/furnish.gd` | The furniture kit every house is furnished from. |
| `scripts/downtown_builder.gd` | Main Street, its shops (including the bike shop and the grocery), the Gazette, Frosty's, the drive-in and the mall (a map is drawn at the top). |
| `scripts/net.gd` | Online play: hosting, joining, and keeping everyone's game in step. How it works is explained at the top. |
| `scripts/props.gd` | Helpers for building furniture you can use (built facing +z, then placed and turned). |
| `scripts/car.gd` | A drivable car: steering, speed, bumping, wheels, headlights, engine sound. |
| `scripts/menus.gd` | The title screen, pause menu, options, controls list. |
| `scripts/save_game.gd` | Saving and loading (`user://save.json`, with a version number). |
| `scripts/settings.gd` | Options, kept in `user://settings.cfg`. |
| `scripts/input_setup.gd` | Every control, for keyboard/mouse and gamepad, in one place. |
| `scripts/diary.gd` | Jamie's diary entries, saved to `user://diary.json`. |
| `scripts/outdoor_builder.gd` | The yards, street, signs, streetlights and the cars. A map is drawn at the top of the file. |
| `scripts/game_audio.gd` | Music and sound effects. Effects play in 3D from the object that makes them. |
| `audio/` | The music loop and sound effects (Ogg Vorbis). |
| `tools/make_audio.py` | The script that composed and synthesized every sound. |
| `scripts/palette.gd` | The style-guide colors. |
| `scripts/main.gd` | Wires it together; time-of-day lighting; the warm "memory look" screen filter. |

Data flows one way: **Clock → Sim (needs, activities) → HUD and lighting.**

## Adding things

**A new activity:** in `content.gd`, copy any block, e.g.

```gdscript
a = Activity.make("Do Homework", 45, {"fun": -10.0, "energy": -4.0}, "sit")
a.from_hour = 15.0
a.to_hour = 22.0
couch.activities.append(a)
```

Effects are *points per game hour*. Poses: `stand`, `sit`, `lie`, `phone`,
`reach`, `read`, `dance`, `hoops`.

Other things an activity can do: `a.loop_sound = "water"` (a sound that repeats
while doing it), `a.end_sound = "microwave_beep"`, `a.glow = "burner_mat"` (light
something up while doing it), `a.money = 1.5` (pay Jamie when it's done; negative
costs money), and `a.messages = [...]` (one picked at random).

**A new Memory Moment:** add an entry to `MEMORIES` in `content.gd` and set
`a.memory_id` on the activity that should trigger it.

Set `a.autonomous = false` on activities Jamie shouldn't pick on her own (the
doors use this).

## The music and sounds

Every sound was synthesized from scratch by `tools/make_audio.py` (no samples),
so it's all original and yours to use.

- **Outside Theme** (`music_outside.ogg`): your track, played whenever Jamie
  is outdoors. It's the only sound not made by `make_audio.py`; replace the
  file to change it.
- **House music** (`music_house.ogg`, ~69 s, loops seamlessly): an original
  112 BPM synth-pop track in A minor. Drum machine with the classic 80s gated
  snare, pumping synth bass, detuned pads, a 16th-note arpeggio, a lead melody,
  and DX7-style electric-piano bells. Four sections: intro, verse, chorus and a
  breakdown that leads back to the top.
- **TV:** power-on thunk with CRT whine and static, a bouncy cartoon theme
  through a little TV speaker while it's on, and a zap when it turns off.
- **Doors:** latch click and creak opening, whoosh and thud closing.
- **Fridge:** seal pop, bottles clinking in the door, the hum; a thump closing.
- **Phone:** rotary dialing, the ringback tone, Danny chattering through the
  handset, the busy signal, and the clunk-and-ding of hanging up.
- **Sleep:** snoring, crickets outside at night, and an 80s clock-radio alarm in the morning.
- **Locked doors:** the handle rattling.
- **Diary:** page flips and pencil scratching.
- **Memory Moments:** a soft chime.
- **Outside:** birdsong by day, knocking on doors, the mailbox creaking open.
- **Kitchen:** the microwave's hum and beep, popping popcorn, running water,
  sizzling pans.
- **Fun:** a crackly record player, a bouncing basketball.
- **Cars:** the engine (its pitch follows your speed), the horn, the door, bumps.
- **Menus:** little blips when you move and select.

To change them, edit `tools/make_audio.py` (tempo, chords and melody are near the
top) and run `python3 tools/make_audio.py`. It needs Python 3 with `numpy` and
`scipy`, plus `ffmpeg`. Volumes in the game are set in `scripts/main.gd` where
each sound is played.

## The pixel font

The mockups use **VT323**, a free pixel font. It couldn't be bundled here, so the
game uses your system's monospace font for now. To get the real look:
download VT323 from https://fonts.google.com/specimen/VT323, then put
`VT323-Regular.ttf` into a `fonts` folder in this project. The game picks it up
automatically.

## Developer flags

For testing, you can pass options after `--` when launching from the command line:

```
godot --path . -- --cam=first --hour=19.5 --speed=2
godot --path . -- --menu=tv --wait=3 --shot=user://screenshot.png
```

`--cam` (house/shoulder/first), `--hour` (start time), `--speed` (0–3),
`--menu` (tv/couch/fridge/phone), `--shot` (save a screenshot and quit),
`--wait` (seconds before the screenshot), `--nopost` (turn off the screen filter),
`--do=front_door:0` (queue an object's activity), `--pos=x,z` (where Jamie starts),
`--yaw=degrees` (which way Jamie faces), `--view=x,z,distance[,yaw]` (aim the House Cam),
`--drive=wagon` (go for a drive), `--pad` (show controller hints), `--pause`
(open the pause menu), `--title` (show the title screen with other flags).
`--host` (host an online game), `--join=127.0.0.1` (join one), `--newgame` (the look
screen), `--who` (pick who to play), `--chat` (show the chat box).
`--date=7-4` (jump to a date, e.g. a holiday). `--goto=police` (start somewhere: a
room or place key), `--burglar[=home]` (start a burglary now), `--bike[=ride]` (own
a bike, or start riding it), `--split[=slot]` (split screen without controllers;
with a slot, Player 2 is that kid right away). `--date=6-21` shows the carnival in
1986 and `--date=10-11` the circus; `--date=1-10` is winter. `--pos` and `--view` work underground too: add `,down` (e.g. `--pos=4,-58,down`; the attics are at z -62..-55, the basements at z -52..-44).
Any flag except `--title`, `--shot` and `--wait` skips the title screen.

## Known limits (on purpose, for now)

- Boxes instead of models, and no animations beyond simple poses and a walk cycle.
- The parents are there to talk to, but they don't sit down to dinner with you yet.
- Cars can drive Maple Street, Oak Avenue and Main Street, but there are no other cars on the road yet.
- Only some of the mall's stores (four, plus the food court) are open.
- In split screen, only Player 1 can drive, write in the diary or change their look.
- One save slot for playing alone, and one online world (kept by the host).
- Online: joining is by IP address only, and the host has to stay in the game for the others to keep playing.
- Chat needs a keyboard.

## Good next steps

1. **Play it for 15 minutes and take notes.** Is managing the needs fun? Too
   slow? Too fast? Tune the numbers in `needs.gd` and `content.gd`.
2. **Family dinner with Mom and Dad** at the table.
3. **Era progression:** when the year changes, unlock new objects, hairstyles and outfits.
4. **Replace boxes with low-poly Blender models**, one object at a time. The
   code won't need to change.
5. **More of Main Street:** a mall, a record store, a movie theater, and a bus to get there.

## Credits

**Rewind Life** is a game by **Ironite**: design, programming, art, music and sound.
© 2026 Ironite. All rights reserved.

Made with the [Godot Engine](https://godotengine.org) (MIT license).

## Demo releases (Ironite Launcher)

Rewind Life is available as a **demo** in [Ironite Launcher](https://github.com/adamglassner/launcher),
which downloads it from this repository's releases and keeps it updated.

To publish a new demo: bump `VERSION` in `scripts/changelog.gd` (and add its WHAT'S NEW entry), then
push to `main`. The [Release workflow](.github/workflows/release.yml) exports the Windows build with
Godot 4.7 and publishes `v<version>` with `RewindLife-<version>-windows.zip`; the launcher picks it up
automatically. Pushes that don't change the version don't publish anything.
