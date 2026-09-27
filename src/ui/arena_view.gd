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
## The Number is the biggest thing on screen (D085), large and thin as the
## owner's main-screen design has it: this size, shrinking to fit
## NUMBER_FIT_PX as its digits grow, never below NUMBER_MIN_PX.
const NUMBER_FONT_PX := 96
const NUMBER_FIT_PX := 150.0
const NUMBER_MIN_PX := 40
## The range as the design draws its ring: a hairline, barely there.
const RANGE_LINE := Color(1, 1, 1, 0.06)
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
## The light behind the Number, as the design draws it (D096): a halo that
## breathes over this many seconds, and a ÷ flaring it violet, this much
## stronger, fading over DIVIDE_FLARE_SECONDS.
const GLOW_BREATH_SECONDS := 5.5
## A ÷ flares the light violet, this much stronger, fading over this long.
const DIVIDE_FLARE := 1.5
const DIVIDE_FLARE_SECONDS := 0.8
## Shot feel (D090), drawing only: a shot's trail in points, longer on a
## critical; the chips a hit knocks off an enemy's number, how many, how fast
## in points a second and for how long; and how quickly a knocked-back enemy
## slides to where it was pushed, rather than jumping there in one tick.
const TRAIL_PX := 9.0
const CRIT_TRAIL_PX := 15.0
const CHIPS := 3
const CRIT_CHIPS := 6
const CHIP_SPEED_PX := 70.0
const CHIP_SECONDS := 0.25
const MAX_CHIPS := 240
const SHOVE_EASE := 14.0
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
	"multiplier": {"axes": {"opsz": 48, "wght": 640, "WONK": 0, "SOFT": 0}, "divider": true, "size": 18, "colour": Palette.MULTIPLIER,
		"glow": Palette.MULTIPLIER},
}
## A hit lights the outline this colour, unless the type says otherwise.
const FLASH := Color("f4f3ef")

var sim: BattleSim
## How far between the sim's last tick and its current one to draw things.
var blend := 1.0
## Where the tower stands, in the view.
var centre := Vector2.ZERO

var _floats: Array[Dictionary] = []
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
## Chips knocked off enemies by hits, in view points: {at, velocity, colour, age}.
var _chips: Array[Dictionary] = []
## Where each enemy is drawn, in metres out, while a knockback eases it back.
var _eased := {}
## Chips scatter at random; only the look, never the battle, draws on this.
var _look_rng := RandomNumberGenerator.new()
## Ranged enemies' shots at the Number: {enemy, age}.
var _ranged_shots: Array[Dictionary] = []
## The fonts each enemy type is drawn in, built once from LOOKS.
var _cuts := {}
var _number_cut := _cut(Palette.WORD_FONT, {"wght": 200})
var _mono_cut := _cut(Palette.NUMBER_FONT, {"wght": 500})
var _hit_cut := _cut(Palette.NUMBER_FONT, {"wght": 400})
var _divide_cut := _cut(Palette.DIVIDER_FONT, LOOKS.divider.axes)
## The light behind the Number, and what's flaring it: {colour, strength,
## seconds, left}, or empty.
var _glow := ColorRect.new()
var _flare := {}
var _glow_time := 0.0
## Half the Number's drawn width and height this frame: the box enemies at
## the tower stand clear of, and floats start from.
var _number_half := Vector2.ZERO


func _init() -> void:
	# Drawn behind the arena's own drawing, over the black ground.
	_glow.show_behind_parent = true
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow.material = ShaderMaterial.new()
	(_glow.material as ShaderMaterial).shader = preload("res://src/ui/number_glow.gdshader")
	add_child(_glow)
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
	_glow_time += delta
	if not _flare.is_empty():
		_flare.left -= delta
		if _flare.left <= 0.0:
			_flare = {}
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
	for chip in _chips:
		chip.age += delta
		chip.at += chip.velocity * delta
		chip.velocity *= exp(-delta * 6.0)
	_chips = _chips.filter(func(chip): return chip.age < CHIP_SECONDS)
	_ease_shoves(delta)
	_ranged_shots = _ranged_shots.filter(func(shot): return shot.age < RANGED_SHOT_SECONDS)
	# Flat hits in one frame show as one "−" at the Number, not a pile.
	var hit_total := 0.0
	for event in events:
		match event.type:
			"kill":
				_floats.append({"text": "$" + Palette.number(event.cash), "at": event.enemy.position(), "age": 0.0, "colour": Palette.ACCENT,
					"font": _mono_cut})
				_pops.append({"kind": event.enemy.kind, "angle": event.enemy.angle, "distance": event.enemy.distance, "age": 0.0})
				_flashes.erase(event.enemy.id)
			"enemy_hit":
				_flashes[event.enemy.id] = HIT_FLASH_SECONDS
				_chip(event.enemy, event.critical)
			"tower_hit":
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
					flare(Palette.DIVIDER, DIVIDE_FLARE, DIVIDE_FLARE_SECONDS)
					_floats.append({"parts": [[sign, _divide_cut, 22], ["  −" + Palette.number(float(event.damage)), _mono_cut, 15]], "anchor": "above",
						"age": 0.0, "colour": Palette.DIVIDER, "life": DIVIDE_FLOAT_SECONDS, "rise": DIVIDE_FLOAT_RISE_PX, "divide": true})
			"multiplied":
				# The × in the operators' typeface, what it added in the Number's.
				flare(Palette.MULTIPLIER, DIVIDE_FLARE, DIVIDE_FLARE_SECONDS)
				_floats.append({"parts": [["×" + _divisor_text(event.factor), _divide_cut, 22], ["  +" + Palette.number(float(event.gain)), _mono_cut, 15]],
					"anchor": "above", "age": 0.0, "colour": Palette.MULTIPLIER, "life": DIVIDE_FLOAT_SECONDS, "rise": DIVIDE_FLOAT_RISE_PX, "divide": true})
			"free_upgrade":
				var name := String(TowerData.upgrade(event.id).title).capitalize()
				_floats.append({"text": "Free: " + name, "anchor": "above", "age": 0.0, "colour": Palette.COIN})
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
		# Beside the Number's shoulder, as the design has it, never over its digits.
		_floats.append({"text": "−" + Palette.number(hit_total), "anchor": "beside", "age": 0.0, "colour": Palette.HIT, "size": 12,
			"font": _hit_cut})


## Flares the light behind the Number: `colour`, `strength` stronger, easing
## back to white over `seconds`. A ÷ uses it; anything else that should light
## the Number (a hit, an Ultimate Weapon) can too. A new flare replaces one
## still fading.
func flare(colour: Color, strength: float, seconds: float) -> void:
	_flare = {"colour": colour, "strength": strength, "seconds": seconds, "left": seconds}


## "2", "1.5", "1.25", "1.38": at most two decimals, none trailing.
static func _divisor_text(divisor: float) -> String:
	return String.num(snappedf(divisor, 0.01), 2)


## A word that rises from the tower.
func _tower_note(text: String, colour: Color) -> void:
	_floats.append({"text": text, "anchor": "above", "age": 0.0, "colour": colour})


## Where a float at the Number starts: just above its digits, or out beside
## its upper right. Anything else starts where it happened, in metres.
func _float_start(item: Dictionary) -> Vector2:
	match item.get("anchor", ""):
		"above":
			return centre + Vector2(0, -_number_half.y - 8.0)
		"beside":
			return centre + Vector2(_number_half.x + 48.0, -_number_half.y * 0.55)
	return to_view(item.at)


func _draw() -> void:
	if sim == null:
		return
	var reach_px := sim.stat("range") * px_per_metre()
	_light_glow()
	draw_arc(centre, reach_px, 0.0, TAU, 128, RANGE_LINE, 1.0, true)
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
	var number := _number_layout()
	if sim.wall_up():
		# Brighter the more of its health it has left. Drawn clear of a large
		# Number rather than through its digits, as the enemies stopped at it are.
		var standing := sim.wall_health / maxf(sim.wall_max_health(), 0.001)
		var wall_px := maxf(Guesses.WALL_DISTANCE_M * px_per_metre(), _number_half.length() + 6.0)
		draw_arc(centre, wall_px, 0.0, TAU, 64, Color(Palette.TEXT, 0.25 + 0.5 * standing), 3.0, true)
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
		_draw_shot(shot)
	for chip in _chips:
		var fade: float = 1.0 - chip.age / CHIP_SECONDS
		var at: Vector2 = chip.at
		draw_line(at, at - (chip.velocity as Vector2) * 0.03, Color(chip.colour, 0.8 * fade), 1.2, true)
	_draw_tower(number)
	_draw_divider_preview()
	for item in _floats:
		var rise: float = item.age / item.get("life", FLOAT_SECONDS)
		var at: Vector2 = _float_start(item) + Vector2(0, -14.0 - item.get("rise", 18.0) * rise)
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
## shrinking to fit as its digits grow. Sets the box enemies stand clear of.
func _number_layout() -> Dictionary:
	var text := Palette.number(Palette.number_shown(sim.health, sim.max_health(), sim.alive))
	var font_size := NUMBER_FONT_PX + (6 if sim.rapid_fire_left > 0.0 else 0)
	while font_size > NUMBER_MIN_PX and _number_cut.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > NUMBER_FIT_PX:
		font_size -= 2
	var width := _number_cut.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# Digits stand about 0.7 of the font size tall.
	_number_half = Vector2(width * 0.5, font_size * 0.35)
	return {"text": text, "size": font_size, "width": width}


## The tower is the Number (D084), drawn over everything but the floats: the
## most important thing on screen (D085). White and thin, with a soft light of
## its own inside the one behind it (D096); it shakes when a ÷ lands.
func _draw_tower(number: Dictionary) -> void:
	var shake := Vector2.ZERO
	if _divide_left > 0.0:
		var strength := _divide_left / SHAKE_SECONDS
		shake = Vector2(sin(_divide_left * 90.0), cos(_divide_left * 70.0)) * SHAKE_PX * strength
	var at := centre + shake
	var font_size: int = number.size
	var baseline := at + Vector2(-number.width * 0.5, font_size * 0.35)
	# The design's text-shadow, faked with wide faint outlines rather than a blur.
	for glow in [[22, 0.025], [12, 0.04], [5, 0.06]]:
		draw_string_outline(_number_cut, baseline, number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, glow[0], Color(1.0, 0.98, 0.94, glow[1]))
	draw_string(_number_cut, baseline, number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.NUMBER)


## Sets the light behind the Number for this frame: breathing slowly, tinted
## and brightened by a flare while one fades.
func _light_glow() -> void:
	var tint := Palette.LIGHT
	var strength := 1.0
	if not _flare.is_empty():
		var left: float = _flare.left / _flare.seconds
		strength += _flare.strength * left
		tint = Palette.LIGHT.lerp(_flare.colour, left)
	var light := _glow.material as ShaderMaterial
	light.set_shader_parameter("centre_px", centre)
	light.set_shader_parameter("rect_px", size)
	light.set_shader_parameter("tint", tint)
	light.set_shader_parameter("strength", strength)
	# Eased in and out, as the design's breathing is.
	light.set_shader_parameter("breath", 0.5 - 0.5 * cos(_glow_time * TAU / GLOW_BREATH_SECONDS))


## An enemy is one number (D085): its health, counting down as it's shot,
## until it reaches the Number and starts hitting, when it shows what each hit
## takes instead. Its type shows in its typeface and colour.
func _draw_enemy(enemy: BattleSim.Enemy) -> void:
	var look: Dictionary = LOOKS[enemy.kind]
	var text := shown_text(sim, enemy)
	var half := _enemy_half(enemy.kind, text)
	var at := _enemy_at(enemy.angle, _shown_metres(enemy), half)
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
	var parts := [[preview.sign, _divide_cut, 13], ["  → " + preview.after, _mono_cut, 11]]
	var width := 0.0
	for part in parts:
		width += (part[1] as Font).get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x
	# Where the ÷ float starts, so the landing turns one into the other.
	var at := _float_start({"anchor": "above"}) + Vector2(-width * 0.5, -14.0)
	for part in parts:
		var font: Font = part[1]
		draw_string(font, at, part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2], Color(Palette.DIVIDER, 0.85))
		at.x += font.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x


## A shot with a short trail fading behind it along its path: longer and
## white on a critical, so a crit reads as a harder shot.
func _draw_shot(shot: BattleSim.Shot) -> void:
	var at := to_view(shot.last_position.lerp(shot.position, blend))
	var colour := Palette.TEXT if shot.critical else Palette.ACCENT
	var heading := shot.position - shot.last_position
	if heading.length() > 0.001:
		var tail := at - heading.normalized() * (CRIT_TRAIL_PX if shot.critical else TRAIL_PX)
		draw_polyline_colors(PackedVector2Array([tail, at]), PackedColorArray([Color(colour, 0.0), Color(colour, 0.7)]), 2.0 if shot.critical else 1.5, true)
	draw_circle(at, 2.5 if shot.critical else 1.8, colour)


## A hit knocks a few chips off the enemy's number, in its colour (white on a
## critical, and more of them), flying outward, away from the tower.
func _chip(enemy: BattleSim.Enemy, critical: bool) -> void:
	if _chips.size() >= MAX_CHIPS or not LOOKS.has(enemy.kind):
		return
	var look: Dictionary = LOOKS[enemy.kind]
	var at := _enemy_at(enemy.angle, _shown_metres(enemy), _enemy_half(enemy.kind, shown_text(sim, enemy)))
	for n in range(CRIT_CHIPS if critical else CHIPS):
		var heading := Vector2.from_angle(enemy.angle + _look_rng.randf_range(-0.9, 0.9))
		_chips.append({"at": at, "velocity": heading * CHIP_SPEED_PX * _look_rng.randf_range(0.5, 1.3),
			"colour": Palette.TEXT if critical else look.colour, "age": 0.0})


## A knockback moves an enemy back in one tick. Drawn, it slides back over a
## few frames instead; walking in, it is drawn exactly where it is.
func _ease_shoves(delta: float) -> void:
	if sim == null:
		return
	var now := {}
	for enemy in sim.enemies:
		var metres := enemy.drawn_at(blend).length()
		var eased: float = _eased.get(enemy.id, metres)
		now[enemy.id] = lerpf(eased, metres, 1.0 - exp(-delta * SHOVE_EASE)) if metres > eased else metres
	_eased = now


## How far out to draw an enemy: where it is, or where a knockback's slide has got to.
func _shown_metres(enemy: BattleSim.Enemy) -> float:
	return _eased.get(enemy.id, enemy.drawn_at(blend).length())


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
	# A Multiplier shows what killing it is worth, the reason to.
	if enemy.kind == "multiplier":
		return "×" + _divisor_text(enemy.factor)
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
