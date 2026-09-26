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
## The Number's body. Wider than the tower's 3 m contact edge so the Number
## can be read; enemies are drawn touching this edge, which is only drawing:
## the sim's contact distance is unchanged.
const BODY_RADIUS_PX := 30.0
const NUMBER_FONT_PX := 26
## How long the Number shakes after a ÷, in seconds, and by how many pixels.
const SHAKE_SECONDS := 0.3
const SHAKE_PX := 4.0
const FLOAT_SECONDS := 0.9
const FLASH_SECONDS := 0.2
const SHOCKWAVE_SECONDS := 0.4

const ENEMY_SIZE := {"basic": 9.0, "fast": 7.0, "ranged": 9.0, "tank": 13.0, "boss": 20.0, "divider": 12.0}

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
	_floats = _floats.filter(func(item): return item.age < FLOAT_SECONDS)
	# Flat hits in one frame show as one "−" at the Number, not a pile.
	var hit_total := 0.0
	for event in events:
		match event.type:
			"kill":
				_floats.append({"text": "$" + Palette.number(event.cash), "at": event.enemy.position(), "age": 0.0, "colour": Palette.ACCENT})
			"tower_hit":
				_tower_flash = FLASH_SECONDS
				hit_total += float(event.damage)
			"divided":
				if event.at_wall:
					_floats.append({"text": "÷%s Wall" % _divisor_text(event.divisor), "at": event.enemy.position(), "age": 0.0, "colour": Palette.DIVIDER, "size": 16})
				else:
					_divide_left = SHAKE_SECONDS
					_floats.append({"text": "÷%s  −%s" % [_divisor_text(event.divisor), Palette.number(float(event.damage))], "at": Vector2(0, -6), "age": 0.0,
						"colour": Palette.DIVIDER, "size": 20})
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
		_floats.append({"text": "−" + Palette.number(hit_total), "at": Vector2(0, 10), "age": 0.0, "colour": Palette.WARNING, "size": 14})


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
	_draw_tower()
	for enemy in sim.enemies:
		_draw_enemy(enemy)
	var orb_radius_px := sim.orb_radius() * px_per_metre()
	for angle in sim.orb_angles():
		draw_circle(centre + Vector2.from_angle(angle) * orb_radius_px, 5.0, Palette.ACCENT)
	for shot in sim.shots:
		draw_circle(to_view(shot.last_position.lerp(shot.position, blend)), 3.0 if shot.critical else 2.0, Palette.TEXT if shot.critical else Palette.ACCENT)
	for item in _floats:
		var rise: float = item.age / FLOAT_SECONDS
		var at: Vector2 = to_view(item.at) + Vector2(0, -14.0 - 18.0 * rise)
		var font_size: int = item.get("size", 12)
		var width := Palette.NUMBER_FONT.get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(Palette.NUMBER_FONT, at - Vector2(width * 0.5, 0), item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(item.colour, 1.0 - rise))


## The tower is the Number: whole, as Palette.number_shown has it (a standing
## tower never reads 0), on its own with no ring (the owner, D084). It is the
## Coin colour while it stands at a new peak (D083: it has no ceiling), the
## warning colour below a quarter of its peak, a size larger while Rapid Fire
## runs, and flashes and shakes when a ÷ lands.
func _draw_tower() -> void:
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
	# The arena's own floor behind the digits, unseen, so shots and enemies never
	# draw across them.
	draw_circle(at, BODY_RADIUS_PX, Palette.SURFACE)
	var text := Palette.number(Palette.number_shown(sim.health, sim.max_health(), sim.alive))
	# Shrink to fit the body as the digits grow.
	var font_size := NUMBER_FONT_PX + (3 if sim.rapid_fire_left > 0.0 else 0)
	while font_size > 10 and Palette.NUMBER_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > BODY_RADIUS_PX * 1.9:
		font_size -= 1
	var size := Palette.NUMBER_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(Palette.NUMBER_FONT, at + Vector2(-size.x * 0.5, font_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


func _draw_enemy(enemy: BattleSim.Enemy) -> void:
	var half: float = ENEMY_SIZE[enemy.kind] * 0.5
	# Enemies close to the tower are drawn touching the Number's body.
	var toward := Vector2.from_angle(enemy.angle)
	var distance_px := maxf(enemy.drawn_at(blend).length() * px_per_metre(), BODY_RADIUS_PX + half)
	var at := centre + toward * distance_px
	if enemy.kind == "divider":
		_draw_divider(at, half, enemy.divisor)
	else:
		_draw_square(enemy, at, half)
	if enemy.health < enemy.max_health:
		var width := half * 2.0
		var top := at + Vector2(-half, -half - 6.0)
		var colour := Palette.DIVIDER if enemy.kind == "divider" else Palette.ENEMY
		draw_rect(Rect2(top, Vector2(width, 2.0)), Color(Palette.LINE, 0.9))
		draw_rect(Rect2(top, Vector2(width * enemy.health / enemy.max_health, 2.0)), colour)


## The Divider: a diamond with its ÷ on it, always readable (THE_NUMBER.md 2.10).
func _draw_divider(at: Vector2, half: float, divisor: float) -> void:
	var corners := PackedVector2Array()
	for corner in range(5):
		corners.append(at + Vector2.from_angle(TAU * corner / 4.0) * half * 1.3)
	draw_polyline(corners, Palette.DIVIDER, 2.0, true)
	# The divisor sits under the diamond, where it has room to be read.
	var label := "÷" + _divisor_text(divisor)
	var size := Palette.NUMBER_FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_string(Palette.NUMBER_FONT, at + Vector2(-size.x * 0.5, half * 1.3 + 12.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.DIVIDER)


## The Tower's launch enemies: squares that subtract.
func _draw_square(enemy: BattleSim.Enemy, at: Vector2, half: float) -> void:
	var colour := Palette.BOSS if enemy.kind == "boss" else (Palette.WARNING if enemy.kind == "fast" else Palette.ENEMY)
	var turn := enemy.angle + PI * 0.25
	var corners := PackedVector2Array()
	for corner in range(5):
		corners.append(at + Vector2.from_angle(turn + TAU * corner / 4.0) * half * sqrt(2.0))
	if enemy.kind == "ranged":
		corners = PackedVector2Array()
		for corner in range(4):
			corners.append(at + Vector2.from_angle(enemy.angle + PI + TAU * corner / 3.0) * half * 1.2)
	draw_polyline(corners, colour, 3.0 if enemy.kind in ["tank", "boss"] else 2.0, true)
