extends RefCounted
## What fades around the battle, drawn over the sim's own picture: the numbers
## that float up, a killed enemy's number fading, chips a hit knocks off, lit
## outlines, mine blasts, the shockwave's ring, a ranged enemy's shot line,
## and how a shot rocks an enemy or a knockback slides it (D085, D090, D102,
## D103). It turns the sim's events into these, and tells the Number's motion
## about the hits and gains that move it. Drawing only: it never changes the
## sim. `view` is the arena, whose geometry, fonts and canvas it uses.

const TowerData = preload("res://src/tower/tower_data.gd")
const EnemyKinds = preload("res://src/tower/enemy_kinds.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")

const FLOAT_SECONDS := 0.9
## A mine's blast fades over twice this.
const FLASH_SECONDS := 0.2
const SHOCKWAVE_SECONDS := 0.4
## A shot enemy's outline lights for about a frame.
const HIT_FLASH_SECONDS := 0.05
## A killed enemy's number swells and fades over this long.
const POP_SECONDS := 0.12
## A ranged enemy's shot shows as a line to the Number for this long.
const RANGED_SHOT_SECONDS := 0.2
## A ÷ or × flares the light in its colour, this much stronger, fading over
## this long.
const DIVIDE_FLARE := 1.5
const DIVIDE_FLARE_SECONDS := 0.8
## A ÷ or × float lasts longer and rises further than the others.
const DIVIDE_FLOAT_SECONDS := 1.2
const DIVIDE_FLOAT_RISE_PX := 30.0
## A landed ÷ peels the Number it cut away (D145): the Number as it stood,
## in the Divider's colour, dropping this far as it fades over this long.
const PEEL_SECONDS := 0.6
const PEEL_DROP_PX := 26.0
## Shot feel (D090): the chips a hit knocks off an enemy's number, how many,
## how fast in points a second and for how long; and how quickly a
## knocked-back enemy slides to where it was pushed, rather than jumping there
## in one tick.
const CHIPS := 3
const CRIT_CHIPS := 6
const CHIP_SPEED_PX := 70.0
const CHIP_SECONDS := 0.25
const MAX_CHIPS := 240
const SHOVE_EASE := 14.0
## A shot pushes an enemy back along its path by RECOIL_PX over the square
## root of its mass, so a tank barely rocks and a boss hardly at all; landing
## a hit, it lunges in by LUNGE_PX the same way. Both settle in about 1 /
## RECOIL_EASE seconds (D103).
## A kill bursts into sparks in the enemy's colour, more the heavier it is,
## flying out and slowing to a stop over about SPARK_SECONDS, with a thin ring
## where it died (D109). MAX_SPARKS caps them in a crowd.
const SPARKS := {"basic": 10, "fast": 10, "ranged": 12, "tank": 20, "boss": 40, "divider": 16, "lock": 16, "protector": 14, "vampire": 20, "ray": 20,
	"scatter": 12}
const SPARK_SPEED_PX := Vector2(50.0, 170.0)
const SPARK_SECONDS := 0.6
const MAX_SPARKS := 600
const DEATH_RING_SECONDS := 0.25
## A shot leaving the Number flashes where it crosses the edge of its digits.
const GLINT_SECONDS := 0.09
const RECOIL_PX := 3.5
const LUNGE_PX := 4.0
const RECOIL_EASE := 14.0

var view
## Rising numbers: {text or parts, at or anchor, age, colour, and maybe font,
## size, life, rise, divide}.
var floats: Array[Dictionary] = []
## Seconds since the last shockwave went out, while its ring is drawn.
var shockwave_age := SHOCKWAVE_SECONDS
## Mine blasts fading: {at, age}.
var blasts: Array[Dictionary] = []
## Enemies shot this frame, by id: seconds left of their lit outline.
var flashes := {}
## Killed enemies' numbers, swelling as they fade: {kind, angle, distance, age, text}.
var pops: Array[Dictionary] = []
## The Numbers landed ÷s cut away, peeling off under it: {value, age}.
var peels: Array[Dictionary] = []
## Chips knocked off enemies by hits, in view points: {at, velocity, colour, age}.
var chips: Array[Dictionary] = []
## Where each enemy is drawn, in metres out, while a knockback eases it back.
var eased := {}
## Each enemy's recoil in points along its path, outward positive, by id.
var recoil := {}
## Ranged enemies' shots at the Number: {enemy, age}.
var ranged_shots: Array[Dictionary] = []
## A kill's sparks {at, velocity, colour, age, life, size} and rings {at, colour, age}.
var sparks: Array[Dictionary] = []
var death_rings: Array[Dictionary] = []
## Flashes on the Number's edge where shots left it: {at, age}; and the shots
## already seen, by instance id, so each flashes once.
var glints: Array[Dictionary] = []
var _seen_shots := {}
## Seconds since the Wall last fell or was rebuilt, and whether it fell, so
## its brackets can fall away or slide back in (D106).
var wall_changed_age := INF
var wall_fell := false
## Chips scatter at random; only the look, never the battle, draws on this.
var _look_rng := RandomNumberGenerator.new()


func _init(arena) -> void:
	view = arena


## Ages what's fading by `delta`, then turns this frame's events into new
## effects.
func absorb(events: Array[Dictionary], delta: float) -> void:
	shockwave_age += delta
	wall_changed_age += delta
	for blast in blasts:
		blast.age += delta
	blasts = blasts.filter(func(blast): return blast.age < FLASH_SECONDS * 2.0)
	for item in floats:
		item.age += delta
	floats = floats.filter(func(item): return item.age < item.get("life", FLOAT_SECONDS))
	for id in flashes.keys():
		flashes[id] -= delta
		if flashes[id] <= 0.0:
			flashes.erase(id)
	for peel in peels:
		peel.age += delta
	peels = peels.filter(func(peel): return peel.age < PEEL_SECONDS)
	for pop in pops:
		pop.age += delta
	pops = pops.filter(func(pop): return pop.age < POP_SECONDS)
	for shot in ranged_shots:
		shot.age += delta
	for chip in chips:
		chip.age += delta
		chip.at += chip.velocity * delta
		chip.velocity *= exp(-delta * 6.0)
	chips = chips.filter(func(chip): return chip.age < CHIP_SECONDS)
	for spark in sparks:
		spark.age += delta
		spark.at += spark.velocity * delta
		spark.velocity *= exp(-delta * 5.0)
	sparks = sparks.filter(func(spark): return spark.age < spark.life)
	for ring in death_rings:
		ring.age += delta
	death_rings = death_rings.filter(func(ring): return ring.age < DEATH_RING_SECONDS)
	for glint in glints:
		glint.age += delta
	glints = glints.filter(func(glint): return glint.age < GLINT_SECONDS)
	_watch_shots()
	if delta > 0.0:
		for id in recoil.keys():
			recoil[id] = lerpf(float(recoil[id]), 0.0, 1.0 - exp(-delta * RECOIL_EASE))
			if absf(float(recoil[id])) < 0.05:
				recoil.erase(id)
	_ease_shoves(delta)
	ranged_shots = ranged_shots.filter(func(shot): return shot.age < RANGED_SHOT_SECONDS)
	_take(events)


## How far out to draw an enemy: where it is, or where a knockback's slide has got to.
func shown_metres(enemy: BattleSim.Enemy) -> float:
	return eased.get(enemy.id, enemy.drawn_at(view.blend).length())


## True while a ÷ or × float that has just appeared is still rising from
## above the Number, where the Divider's preview would sit.
func operator_float_rising() -> bool:
	return floats.any(func(item): return item.get("divide", false) and item.age < DIVIDE_FLOAT_SECONDS * 0.5)


func draw_shockwave(reach_px: float) -> void:
	if shockwave_age < SHOCKWAVE_SECONDS:
		# The ring runs out to the edge of range and fades as it goes.
		var spread := shockwave_age / SHOCKWAVE_SECONDS
		view.draw_arc(view.centre, reach_px * spread, 0.0, TAU, 96, Color(Palette.TEXT, 0.6 * (1.0 - spread)), 3.0, true)


func draw_blasts(blast_px: float) -> void:
	for blast in blasts:
		var fade: float = 1.0 - blast.age / (FLASH_SECONDS * 2.0)
		view.draw_circle(view.to_view(blast.at), blast_px, Color(Palette.WARNING, 0.35 * fade))


## The ranged enemy's shot: a dotted line in its colour to the Number, or to
## the Wall's brackets (`wall_half`) when the Wall took it. A Ray's is solid
## and heavier, its charge let go.
func draw_ranged_shots(number_half: Vector2, wall_half: Vector2) -> void:
	for shot in ranged_shots:
		var from: Vector2 = view.enemy_at(shot.enemy.angle, shot.enemy.distance, view.enemy_half(shot.enemy.kind, "0"))
		var toward := Vector2.from_angle(shot.enemy.angle)
		var fade: float = 1.0 - shot.age / RANGED_SHOT_SECONDS
		var to: Vector2 = view.centre + toward * (wall_half.x if shot.get("at_wall", false) else number_half.x)
		if shot.enemy.kind == "ray":
			view.draw_line(from - toward * 12.0, to, Color(Palette.RAY, 0.8 * fade), 3.0, true)
		else:
			view.draw_dashed_line(from - toward * 12.0, to, Color(Palette.RANGED, 0.45 * fade), 1.0, 2.0)


## A killed enemy's number swells to 1.3× and fades where it died.
func draw_pops() -> void:
	for pop in pops:
		var look: Dictionary = view.LOOKS[pop.kind]
		var half: Vector2 = view.enemy_half(pop.kind, pop.text)
		var at: Vector2 = view.enemy_at(pop.angle, pop.distance, half)
		var done: float = pop.age / POP_SECONDS
		var grow := 1.0 + 0.3 * done
		view.draw_set_transform(at, 0.0, Vector2(grow, grow))
		# A tank has been shot thin by the time it dies (D145).
		var cut: Font = view.tank_cuts[0] if pop.kind == "tank" else view.cuts[pop.kind]
		view.draw_string(cut, Vector2(-half.x, look.size * 0.35), pop.text, HORIZONTAL_ALIGNMENT_LEFT, -1, look.size, Color(look.colour, 0.35 * (1.0 - done)))
		view.draw_set_transform(Vector2.ZERO)


## A kill's sparks, small squares shrinking as they fade, and its ring.
func draw_sparks() -> void:
	for ring in death_rings:
		var done: float = ring.age / DEATH_RING_SECONDS
		view.draw_arc(ring.at, lerpf(6.0, 26.0, done), 0.0, TAU, 32, Color(ring.colour, 0.5 * (1.0 - done)), 1.2, true)
	for spark in sparks:
		var left: float = 1.0 - spark.age / spark.life
		var side: float = spark.size * (0.4 + 0.6 * left)
		view.draw_rect(Rect2(spark.at - Vector2(side, side) * 0.5, Vector2(side, side)), Color(spark.colour, 0.9 * left))


## Where a shot left the Number: a small white flash on its edge, quickly gone.
func draw_glints() -> void:
	for glint in glints:
		var left: float = 1.0 - glint.age / GLINT_SECONDS
		view.draw_circle(glint.at, 1.5 + 3.0 * left, Color(Palette.NUMBER, 0.35 * left))
		view.draw_circle(glint.at, 1.2, Color(Palette.NUMBER, 0.9 * left))


func draw_chips() -> void:
	for chip in chips:
		var fade: float = 1.0 - chip.age / CHIP_SECONDS
		var at: Vector2 = chip.at
		view.draw_line(at, at - (chip.velocity as Vector2) * 0.03, Color(chip.colour, 0.8 * fade), 1.2, true)


func draw_floats() -> void:
	for item in floats:
		var rise: float = item.age / item.get("life", FLOAT_SECONDS)
		var at: Vector2 = view.float_start(item) + Vector2(0, -14.0 - item.get("rise", 18.0) * rise)
		# A float is one or more runs of text, each in its own font and size.
		var parts: Array = item.get("parts", [[item.get("text", ""), item.get("font", Palette.NUMBER_FONT), item.get("size", 12)]])
		var width := 0.0
		for part in parts:
			width += (part[1] as Font).get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x
		var x := at.x - width * 0.5
		for part in parts:
			var font: Font = part[1]
			# A part may carry its own colour, as a kill's Coins do.
			var colour: Color = part[3] if part.size() > 3 else item.colour
			# The same dark halo as the enemies' numbers (D127), so a float
			# crossing one stays readable.
			view.draw_string_outline(font, Vector2(x, at.y), part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2], view.HALO_PX, Color(view.HALO, view.HALO.a * (1.0 - rise)))
			view.draw_string(font, Vector2(x, at.y), part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2], Color(colour, 1.0 - rise))
			x += font.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x


func _take(events: Array[Dictionary]) -> void:
	var motion = view.motion
	# Flat hits in one frame show as one "−" at the Number, not a pile, and
	# growth from kills (D098) as one "+".
	var hit_total := 0.0
	var grown_total := 0.0
	for event in events:
		match event.type:
			"kill":
				# What it paid, beside where it died: Cash, and Coins when it paid any.
				# With the Number as Cash (D156) the Cash is Number: a "+" in its colour.
				var as_number: bool = view.sim != null and view.sim.number_cash
				var paid: Array = [[("+" if as_number else "$") + Palette.money(event.cash), view.mono_cut, 12, Palette.NUMBER if as_number else Palette.ACCENT]]
				if float(event.get("coins", 0.0)) > 0.0:
					paid.append(["  ● " + Palette.money(float(event.coins)), view.mono_cut, 12, Palette.COIN])
				floats.append({"parts": paid, "at": event.enemy.position(), "age": 0.0, "colour": Palette.ACCENT})
				_burst(event.enemy)
				# The killed enemy's own number swells and fades where it died; an
				# orb's kill reads 0, since an orb sets it to zero (D106).
				var last: String = "0" if event.get("by", "") == "orb" else (view.shown_text(view.sim, event.enemy) if view.sim != null else "")
				pops.append({"kind": event.enemy.kind, "angle": event.enemy.angle, "distance": event.enemy.distance, "age": 0.0,
					"text": last})
				flashes.erase(event.enemy.id)
			"enemy_hit":
				flashes[event.enemy.id] = HIT_FLASH_SECONDS
				_chip(event.enemy, event.critical)
				recoil[event.enemy.id] = RECOIL_PX / sqrt(_mass_of(event.enemy.kind))
			"tower_hit":
				hit_total += float(event.damage)
				recoil[event.enemy.id] = -LUNGE_PX / sqrt(_mass_of(event.enemy.kind))
				motion.knock(event.enemy.angle, float(event.damage))
				if event.enemy.kind == "ranged" or event.enemy.kind == "ray":
					ranged_shots.append({"enemy": event.enemy, "age": 0.0})
			"wall_hit":
				# A standing Wall takes ranged shots too (D116): theirs end at it.
				if event.enemy.kind == "ranged" or event.enemy.kind == "ray":
					ranged_shots.append({"enemy": event.enemy, "age": 0.0, "at_wall": true})
			"divided":
				# The ÷ in the Divider's own typeface, what it took in the Number's (D085).
				var sign: String = "÷" + view.divisor_text(event.divisor)
				if event.at_wall:
					floats.append({"parts": [[sign, view.divide_cut, 16], [" Wall", Palette.NUMBER_FONT, 13]], "at": event.enemy.position(), "age": 0.0,
						"colour": Palette.DIVIDER})
				else:
					motion.shake()
					motion.flare(Palette.DIVIDER, DIVIDE_FLARE, DIVIDE_FLARE_SECONDS)
					peels.append({"value": float(event.get("before", 0.0)), "age": 0.0})
					floats.append({"parts": [[sign, view.divide_cut, 22], ["  −" + Palette.amount(float(event.damage)), view.mono_cut, 15]], "anchor": "above",
						"age": 0.0, "colour": Palette.DIVIDER, "life": DIVIDE_FLOAT_SECONDS, "rise": DIVIDE_FLOAT_RISE_PX, "divide": true})
			"grown":
				grown_total += float(event.gain)
				motion.raise(float(event.gain))
			"free_upgrade":
				var name := String(TowerData.upgrade(event.id).title).capitalize()
				floats.append({"text": "Free: " + name, "anchor": "above", "age": 0.0, "colour": Palette.COIN})
			"rapid_fire":
				_tower_note("Rapid Fire", Palette.TEXT)
			"package":
				_tower_note("Recovery", Palette.ACCENT)
			"death_defy":
				_tower_note("Death Defied", Palette.COIN)
			"wall_down":
				_tower_note("Wall down", Palette.WARNING)
				wall_changed_age = 0.0
				wall_fell = true
			"wall_up":
				_tower_note("Wall rebuilt", Palette.ACCENT)
				wall_changed_age = 0.0
				wall_fell = false
			"shockwave":
				shockwave_age = 0.0
			"mine":
				blasts.append({"at": event.at, "age": 0.0})
	# Kills' growth shows once it's worth a whole one; smaller, the Number's
	# roll shows it (D105).
	if grown_total >= 0.5:
		floats.append({"text": "+" + Palette.amount(grown_total), "anchor": "growing", "age": 0.0, "colour": Palette.ACCENT, "size": 12,
			"font": view.hit_cut})
	if hit_total > 0.0:
		# Beside the Number's shoulder, as the design has it, never over its digits.
		floats.append({"text": "−" + Palette.amount(hit_total), "anchor": "beside", "age": 0.0, "colour": Palette.HIT, "size": 12,
			"font": view.hit_cut})


## A kill bursts into sparks where the enemy was drawn, all in its colour,
## flying out from its number, and a ring swells there (D109).
func _burst(enemy) -> void:
	if not view.LOOKS.has(enemy.kind) or view.sim == null:
		return
	var look: Dictionary = view.LOOKS[enemy.kind]
	var at: Vector2 = view.enemy_at(enemy.angle, shown_metres(enemy), view.enemy_half(enemy.kind, "0"))
	death_rings.append({"at": at, "colour": look.colour, "age": 0.0})
	var count: int = mini(int(SPARKS.get(enemy.kind, 10)), MAX_SPARKS - sparks.size())
	for _spark in range(count):
		# Mostly away from the tower, the way the shot was going.
		var heading := Vector2.from_angle(enemy.angle + _look_rng.randf_range(-1.6, 1.6))
		sparks.append({"at": at, "velocity": heading * _look_rng.randf_range(SPARK_SPEED_PX.x, SPARK_SPEED_PX.y),
			"colour": look.colour, "age": 0.0,
			"life": SPARK_SECONDS * _look_rng.randf_range(0.6, 1.2), "size": _look_rng.randf_range(1.5, 3.5)})


## Each shot new this frame that starts near the Number flashes on its edge
## where it leaves; a bounce, starting at an enemy, doesn't.
func _watch_shots() -> void:
	if view.sim == null:
		return
	var now := {}
	for shot in view.sim.shots:
		var id: int = shot.get_instance_id()
		now[id] = true
		if _seen_shots.has(id):
			continue
		var offset: Vector2 = view.to_view(shot.position) - view.centre
		# A shot still at the centre heads for its target.
		var toward: Vector2 = offset
		if toward.length() < 0.001 and shot.target != null:
			toward = view.to_view(shot.target.position()) - view.centre
		if toward.length() < 0.001:
			toward = Vector2.RIGHT
		var edge: float = view.edge_px(toward.normalized())
		if offset.length() <= edge + 12.0:
			glints.append({"at": view.centre + toward.normalized() * edge, "age": 0.0})
	_seen_shots = now


## A word that rises from the tower.
func _tower_note(text: String, colour: Color) -> void:
	floats.append({"text": text, "anchor": "above", "age": 0.0, "colour": colour})


## A hit knocks a few chips off the enemy's number, in its colour (white on a
## critical, and more of them), flying outward, away from the tower.
func _chip(enemy: BattleSim.Enemy, critical: bool) -> void:
	if chips.size() >= MAX_CHIPS or not view.LOOKS.has(enemy.kind):
		return
	var look: Dictionary = view.LOOKS[enemy.kind]
	var at: Vector2 = view.enemy_at(enemy.angle, shown_metres(enemy), view.enemy_half(enemy.kind, view.shown_text(view.sim, enemy)))
	for n in range(CRIT_CHIPS if critical else CHIPS):
		var heading := Vector2.from_angle(enemy.angle + _look_rng.randf_range(-0.9, 0.9))
		chips.append({"at": at, "velocity": heading * CHIP_SPEED_PX * _look_rng.randf_range(0.5, 1.3),
			"colour": Palette.TEXT if critical else look.colour, "age": 0.0})


## A knockback moves an enemy back in one tick. Drawn, it slides back over a
## few frames instead; walking in, it is drawn exactly where it is.
func _ease_shoves(delta: float) -> void:
	if view.sim == null:
		return
	var now := {}
	for enemy in view.sim.enemies:
		var metres: float = enemy.drawn_at(view.blend).length()
		var was: float = eased.get(enemy.id, metres)
		now[enemy.id] = lerpf(was, metres, 1.0 - exp(-delta * SHOVE_EASE)) if metres > was else metres
	eased = now


func _mass_of(kind: String) -> float:
	return EnemyKinds.mass_ratio(kind)
