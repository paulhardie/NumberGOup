extends Control
## Draws a BattleSim: the Number in the centre (the tower, D080), its range
## and wall, enemies walking in, shots in flight, land mines and shockwaves,
## and what each contact did to the Number. It reads the sim and never
## changes it.

const TowerData = preload("res://src/tower/tower_data.gd")
const Guesses = preload("res://src/tower/guesses.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")

## The range circle's radius as a share of half the view's width, as on The
## Tower's screen (292 px of 460 in the owner's screenshots).
const RANGE_SHARE := 0.64
## The Number is the biggest thing on screen (D085): this size, shrinking to
## fit NUMBER_FIT_PX as its digits grow, never below NUMBER_MIN_PX.
const NUMBER_FONT_PX := 34
const NUMBER_FIT_PX := 100.0
const NUMBER_MIN_PX := 18
## Enemies at the tower are drawn this clear of the Number's digits, which is
## only drawing: the sim's contact distance is unchanged.
const CONTACT_GAP_PX := 3.0
## How long the Number shakes after a ÷, in seconds, and by how many pixels.
const SHAKE_SECONDS := 0.3
const SHAKE_PX := 4.0
const FLOAT_SECONDS := 0.9
const FLASH_SECONDS := 0.2
const SHOCKWAVE_SECONDS := 0.4
## A shot enemy's outline lights for about a frame.
const HIT_FLASH_SECONDS := 0.05
## A killed enemy's "0" swells and fades over this long.
const POP_SECONDS := 0.12
## A ranged enemy's shot shows as a line to the Number for this long.
const RANGED_SHOT_SECONDS := 0.2
## A ÷ float lasts longer and rises further than the others.
const DIVIDE_FLOAT_SECONDS := 1.2
const DIVIDE_FLOAT_RISE_PX := 30.0

## How each enemy type is drawn (D085): its cut of the crowd's typeface
## (Anybody's width and weight; the Divider has Fraunces to itself), its size
## in points, and its colour.
const LOOKS := {
	"basic": {"axes": {"wdth": 100, "wght": 650}, "size": 14, "colour": Palette.ENEMY},
	"fast": {"axes": {"wdth": 62, "wght": 720}, "slant": 0.21, "size": 13, "colour": Palette.FAST},
	"tank": {"axes": {"wdth": 150, "wght": 900}, "size": 18, "colour": Palette.TANK},
	"ranged": {"axes": {"wdth": 125, "wght": 380}, "spacing": 1, "size": 14, "colour": Palette.RANGED},
	"boss": {"axes": {"wdth": 150, "wght": 900}, "size": 24, "colour": Palette.BOSS, "glow": Palette.BOSS_GLOW, "flash": Palette.BOSS_GLOW},
	"divider": {"axes": {"opsz": 48, "wght": 640, "WONK": 0, "SOFT": 0}, "divider": true, "size": 18, "colour": Palette.DIVIDER,
		"glow": Palette.DIVIDER},
}
## A hit lights the outline this colour, unless the type says otherwise.
const FLASH := Color("f4f3ef")

var sim: BattleSim
## How far between the sim's last tick and its current one to draw things.
var blend := 1.0
## Where the tower stands, in the view.
var centre := Vector2.ZERO

var _floats: Array[Dictionary] = []
var _tower_flash := 0.0
## Seconds left of the flash and shake a ÷ sets off.
var _divide_left := 0.0
## Seconds since the last shockwave went out, while its ring is drawn.
var _shockwave_age := SHOCKWAVE_SECONDS
## Mine blasts fading: {at, age}.
var _blasts: Array[Dictionary] = []
## Enemies shot this frame, by id: seconds left of their lit outline.
var _flashes := {}
## Killed enemies' last "0", swelling as it fades: {kind, angle, distance, age}.
var _pops: Array[Dictionary] = []
## Ranged enemies' shots at the Number: {enemy, age}.
var _ranged_shots: Array[Dictionary] = []
## The fonts each enemy type is drawn in, built once from LOOKS.
var _cuts := {}
var _number_cut := _cut(Palette.NUMBER_FONT, {"wght": 600})
var _hit_cut := _cut(Palette.NUMBER_FONT, {"wght": 500})
var _divide_cut := _cut(Palette.DIVIDER_FONT, LOOKS.divider.axes)
## Half the Number's drawn width and height this frame, which enemies at the
## tower stand clear of.
var _number_half := Vector2.ZERO


func _init() -> void:
	for kind in LOOKS:
		var look: Dictionary = LOOKS[kind]
		var base: Font = Palette.DIVIDER_FONT if look.get("divider", false) else Palette.CROWD_FONT
		_cuts[kind] = _cut(base, look.axes, look.get("slant", 0.0), look.get("spacing", 0))


## One cut of a variable font: its axes, a synthetic slant for Fast (no
## italic file needed), and extra space between glyphs.
static func _cut(base: Font, axes: Dictionary, slant := 0.0, spacing := 0) -> FontVariation:
	var cut := FontVariation.new()
	cut.base_font = base
	# Axes must be given as OpenType tags: Godot 4.7 ignores their names.
	var tagged := {}
	for axis in axes:
		tagged[TextServerManager.get_primary_interface().name_to_tag(axis)] = axes[axis]
	cut.variation_opentype = tagged
	if slant != 0.0:
		cut.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(slant, 1.0), Vector2.ZERO)
	cut.spacing_glyph = spacing
	return cut


func px_per_metre() -> float:
	return size.x * 0.5 * RANGE_SHARE / TowerData.value("range", 0)


func to_view(world: Vector2) -> Vector2:
	return centre + world * px_per_metre()


## Takes the sim's events for this frame and turns them into what fades.
func absorb(events: Array[Dictionary], delta: float) -> void:
	_tower_flash = maxf(0.0, _tower_flash - delta)
	_divide_left = maxf(0.0, _divide_left - delta)
	_shockwave_age += delta
	for blast in _blasts:
		blast.age += delta
	_blasts = _blasts.filter(func(blast): return blast.age < FLASH_SECONDS * 2.0)
	for item in _floats:
		item.age += delta
	_floats = _floats.filter(func(item): return item.age < item.get("life", FLOAT_SECONDS))
	for id in _flashes.keys():
		_flashes[id] -= delta
		if _flashes[id] <= 0.0:
			_flashes.erase(id)
	for pop in _pops:
		pop.age += delta
	_pops = _pops.filter(func(pop): return pop.age < POP_SECONDS)
	for shot in _ranged_shots:
		shot.age += delta
	_ranged_shots = _ranged_shots.filter(func(shot): return shot.age < RANGED_SHOT_SECONDS)
	# Flat hits in one frame show as one "−" at the Number, not a pile.
	var hit_total := 0.0
	for event in events:
		match event.type:
			"kill":
				_floats.append({"text": "$" + Palette.number(event.cash), "at": event.enemy.position(), "age": 0.0, "colour": Palette.ACCENT,
					"font": _number_cut})
				_pops.append({"kind": event.enemy.kind, "angle": event.enemy.angle, "distance": event.enemy.distance, "age": 0.0})
				_flashes.erase(event.enemy.id)
			"enemy_hit":
				_flashes[event.enemy.id] = HIT_FLASH_SECONDS
			"tower_hit":
				_tower_flash = FLASH_SECONDS
				hit_total += float(event.damage)
				if event.enemy.kind == "ranged":
					_ranged_shots.append({"enemy": event.enemy, "age": 0.0})
			"divided":
				# The ÷ in the Divider's own typeface, what it took in the Number's (D085).
				var sign := "÷" + _divisor_text(event.divisor)
				if event.at_wall:
					_floats.append({"parts": [[sign, _divide_cut, 16], [" Wall", Palette.NUMBER_FONT, 13]], "at": event.enemy.position(), "age": 0.0,
						"colour": Palette.DIVIDER})
				else:
					_divide_left = SHAKE_SECONDS
					_floats.append({"parts": [[sign, _divide_cut, 22], ["  −" + Palette.number(float(event.damage)), _number_cut, 15]], "at": Vector2(0, -6),
						"age": 0.0, "colour": Palette.DIVIDER, "life": DIVIDE_FLOAT_SECONDS, "rise": DIVIDE_FLOAT_RISE_PX, "divide": true})
			"free_upgrade":
				var name := String(TowerData.upgrade(event.id).title).capitalize()
				_floats.append({"text": "Free: " + name, "at": Vector2(0, -8), "age": 0.0, "colour": Palette.COIN})
			"rapid_fire":
				_tower_note("Rapid Fire", Palette.TEXT)
			"package":
				_tower_note("Recovery", Palette.ACCENT)
			"death_defy":
				_tower_note("Death Defied", Palette.COIN)
			"wall_down":
				_tower_note("Wall down", Palette.WARNING)
			"wall_up":
				_tower_note("Wall rebuilt", Palette.ACCENT)
			"shockwave":
				_shockwave_age = 0.0
			"mine":
				_blasts.append({"at": event.at, "age": 0.0})
	if hit_total > 0.0:
		# Starts below the Number and rises into its lower edge, never over its digits.
		_floats.append({"text": "−" + Palette.number(hit_total), "at": Vector2(0, 10), "age": 0.0, "colour": Palette.WARNING, "size": 14,
			"font": _hit_cut})


## "2", "1.5", "1.25", "1.38": at most two decimals, none trailing.
static func _divisor_text(divisor: float) -> String:
	return String.num(snappedf(divisor, 0.01), 2)


## A word that rises from the tower.
func _tower_note(text: String, colour: Color) -> void:
	_floats.append({"text": text, "at": Vector2(0, -8), "age": 0.0, "colour": colour})


func _draw() -> void:
	if sim == null:
		return
	var reach_px := sim.stat("range") * px_per_metre()
	draw_circle(centre, reach_px, Palette.SURFACE)
	draw_arc(centre, reach_px, 0.0, TAU, 96, Color(Palette.ACCENT, 0.28), 2.0, true)
	if _shockwave_age < SHOCKWAVE_SECONDS:
		# The ring runs out to the edge of range and fades as it goes.
		var spread := _shockwave_age / SHOCKWAVE_SECONDS
		draw_arc(centre, reach_px * spread, 0.0, TAU, 96, Color(Palette.TEXT, 0.6 * (1.0 - spread)), 3.0, true)
	for mine in sim.mines:
		draw_circle(to_view(mine), 3.0, Palette.WARNING)
	var blast_px := sim.stat("land_mine_radius") * px_per_metre()
	for blast in _blasts:
		var fade: float = 1.0 - blast.age / (FLASH_SECONDS * 2.0)
		draw_circle(to_view(blast.at), blast_px, Color(Palette.WARNING, 0.35 * fade))
	if sim.wall_up():
		# Brighter the more of its health it has left.
		var standing := sim.wall_health / maxf(sim.wall_max_health(), 0.001)
		draw_arc(centre, Guesses.WALL_DISTANCE_M * px_per_metre(), 0.0, TAU, 64, Color(Palette.TEXT, 0.25 + 0.5 * standing), 3.0, true)
	var number := _number_layout()
	for shot in _ranged_shots:
		# The ranged enemy's shot: a dotted line in its colour to the Number.
		var from := _enemy_at(shot.enemy.angle, shot.enemy.distance, _enemy_half(shot.enemy.kind, "0"))
		var toward := Vector2.from_angle(shot.enemy.angle)
		draw_dashed_line(from - toward * 12.0, centre + toward * _number_half.x, Color(Palette.RANGED, 0.45 * (1.0 - shot.age / RANGED_SHOT_SECONDS)), 1.0, 2.0)
	for enemy in sim.enemies:
		_draw_enemy(enemy)
	for pop in _pops:
		_draw_pop(pop)
	var orb_radius_px := sim.orb_radius() * px_per_metre()
	for angle in sim.orb_angles():
		draw_circle(centre + Vector2.from_angle(angle) * orb_radius_px, 5.0, Palette.ACCENT)
	for shot in sim.shots:
		draw_circle(to_view(shot.last_position.lerp(shot.position, blend)), 3.0 if shot.critical else 2.0, Palette.TEXT if shot.critical else Palette.ACCENT)
	_draw_tower(number)
	_draw_divider_preview()
	for item in _floats:
		var rise: float = item.age / item.get("life", FLOAT_SECONDS)
		var at: Vector2 = to_view(item.at) + Vector2(0, -14.0 - item.get("rise", 18.0) * rise)
		# A float is one or more runs of text, each in its own font and size.
		var parts: Array = item.get("parts", [[item.get("text", ""), item.get("font", Palette.NUMBER_FONT), item.get("size", 12)]])
		var width := 0.0
		for part in parts:
			width += (part[1] as Font).get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x
		var x := at.x - width * 0.5
		for part in parts:
			var font: Font = part[1]
			draw_string(font, Vector2(x, at.y), part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2], Color(item.colour, 1.0 - rise))
			x += font.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x


## The Number's text and size this frame: whole, as Palette.number_shown has
## it (a standing tower never reads 0), a size larger while Rapid Fire runs,
## shrinking to fit as its digits grow. Sets the half-size enemies stand clear of.
func _number_layout() -> Dictionary:
	var text := Palette.number(Palette.number_shown(sim.health, sim.max_health(), sim.alive))
	var font_size := NUMBER_FONT_PX + (3 if sim.rapid_fire_left > 0.0 else 0)
	while font_size > NUMBER_MIN_PX and _number_cut.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > NUMBER_FIT_PX:
		font_size -= 1
	var width := _number_cut.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# Digits stand about 0.7 of the font size tall.
	_number_half = Vector2(width, font_size * 0.7) * 0.5
	return {"text": text, "size": font_size, "width": width}


## The tower is the Number, on its own with no ring (the owner, D084), drawn
## over everything but the floats: the most important thing on screen (D085).
## It is the Coin colour while it stands at a new peak (D083: it has no
## ceiling), the warning colour below a quarter of its peak, and flashes and
## shakes when a ÷ lands.
func _draw_tower(number: Dictionary) -> void:
	var shake := Vector2.ZERO
	if _divide_left > 0.0:
		var strength := _divide_left / SHAKE_SECONDS
		shake = Vector2(sin(_divide_left * 90.0), cos(_divide_left * 70.0)) * SHAKE_PX * strength
	var at := centre + shake
	var peak := maxf(sim.peak_number, 0.001)
	var colour := Palette.ACCENT
	if sim.health >= peak * 0.999:
		colour = Palette.COIN
	elif sim.health < peak * 0.25:
		colour = Palette.WARNING
	if _tower_flash > 0.0:
		colour = Palette.WARNING.lerp(colour, 1.0 - _tower_flash / FLASH_SECONDS)
	if _divide_left > 0.0:
		colour = Palette.DIVIDER.lerp(colour, 1.0 - _divide_left / SHAKE_SECONDS)
	# The arena's own floor behind the digits, unseen, so shots never draw across them.
	draw_circle(at, _number_half.x + 4.0, Palette.SURFACE)
	var font_size: int = number.size
	draw_string(_number_cut, at + Vector2(-number.width * 0.5, font_size * 0.35), number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


## An enemy is one number (D085): its health, counting down as it's shot,
## until it reaches the Number and starts hitting, when it shows what each hit
## takes instead. Its type shows in its typeface and colour.
func _draw_enemy(enemy: BattleSim.Enemy) -> void:
	var look: Dictionary = LOOKS[enemy.kind]
	var text := shown_text(sim, enemy)
	var half := _enemy_half(enemy.kind, text)
	var at := _enemy_at(enemy.angle, enemy.drawn_at(blend).length(), half)
	var font: Font = _cuts[enemy.kind]
	var font_size: int = look.size
	var baseline := at + Vector2(-half.x, font_size * 0.35)
	if look.has("glow"):
		# A soft glow, faked with two wide faint outlines rather than a blur.
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, Color(look.glow, 0.08))
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(look.glow, 0.12))
	if _flashes.has(enemy.id):
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, look.get("flash", FLASH))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, look.colour)


## The nearest Divider inside the range shows what it will do above the
## Number, "÷1.5 → 301", so a ÷ never lands unseen (D085). It makes way while
## a ÷ that has just landed floats up from the same spot.
func _draw_divider_preview() -> void:
	if _floats.any(func(item): return item.get("divide", false) and item.age < DIVIDE_FLOAT_SECONDS * 0.5):
		return
	var preview := divider_preview(sim)
	if preview.is_empty():
		return
	var parts := [[preview.sign, _divide_cut, 13], ["  → " + preview.after, _number_cut, 11]]
	var width := 0.0
	for part in parts:
		width += (part[1] as Font).get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x
	# Where the ÷ float starts, so the landing turns one into the other.
	var at := to_view(Vector2(0, -6)) + Vector2(-width * 0.5, -14.0)
	for part in parts:
		var font: Font = part[1]
		draw_string(font, at, part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2], Color(Palette.DIVIDER, 0.85))
		at.x += font.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x


## A killed enemy's "0" swells to 1.3× and fades.
func _draw_pop(pop: Dictionary) -> void:
	var look: Dictionary = LOOKS[pop.kind]
	var half := _enemy_half(pop.kind, "0")
	var at := _enemy_at(pop.angle, pop.distance, half)
	var done: float = pop.age / POP_SECONDS
	var grow := 1.0 + 0.3 * done
	draw_set_transform(at, 0.0, Vector2(grow, grow))
	draw_string(_cuts[pop.kind], Vector2(-half.x, look.size * 0.35), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, look.size, Color(look.colour, 0.35 * (1.0 - done)))
	draw_set_transform(Vector2.ZERO)


## Half an enemy's drawn width and height.
func _enemy_half(kind: String, text: String) -> Vector2:
	var font_size: int = LOOKS[kind].size
	var width: float = (_cuts[kind] as Font).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return Vector2(width, font_size * 0.7) * 0.5


## Where an enemy is drawn: where it stands, or, at the tower, just clear of
## the Number's digits on its own side.
func _enemy_at(angle: float, distance_m: float, half: Vector2) -> Vector2:
	var toward := Vector2.from_angle(angle)
	var clear := _number_half + half + Vector2(CONTACT_GAP_PX, CONTACT_GAP_PX)
	# The nearest it can come along its line without the two boxes touching.
	var nearest := INF
	if absf(toward.x) > 0.001:
		nearest = clear.x / absf(toward.x)
	if absf(toward.y) > 0.001:
		nearest = minf(nearest, clear.y / absf(toward.y))
	return centre + toward * maxf(distance_m * px_per_metre(), nearest)


## The one number an enemy shows (D085): its health while it walks in, and
## what each hit takes once it has arrived and is hitting. A Divider never
## stands and hits, so it always shows its health; the preview carries its ÷.
static func shown_text(battle: BattleSim, enemy: BattleSim.Enemy) -> String:
	if enemy.kind != "divider" and enemy.arrived():
		return operation_text(battle, enemy)
	return Palette.enemy_health(enemy.health)


## What an enemy does: its next hit off the Number, after the tower's
## defences and growing 4% a hit (so it ticks up while it stands there), or a
## Divider's ÷.
static func operation_text(battle: BattleSim, enemy: BattleSim.Enemy) -> String:
	if enemy.kind == "divider":
		return "÷" + _divisor_text(enemy.divisor)
	return "−" + Palette.short(battle.landed_damage(enemy.attack * pow(Guesses.HEAT_UP_PER_HIT, enemy.hits)))


## The nearest Divider inside the range and what it will leave: {sign, after},
## where after is the Number as it will read, or "Wall" while the Wall stands
## to take it. Empty when none is in range.
static func divider_preview(battle: BattleSim) -> Dictionary:
	var nearest: BattleSim.Enemy = null
	for enemy in battle.enemies:
		if enemy.kind == "divider" and enemy.distance <= battle.stat("range") and (nearest == null or enemy.distance < nearest.distance):
			nearest = enemy
	if nearest == null:
		return {}
	var after := "Wall"
	if not battle.wall_up():
		var left := battle.health - battle.divide_loss(nearest.divisor)
		after = Palette.number(Palette.number_shown(left, battle.max_health(), true))
	return {"sign": operation_text(battle, nearest), "after": after}
