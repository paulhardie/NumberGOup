extends Control
## Draws a BattleSim: the Number in the centre (the tower, D080), its range
## and the Wall's brackets, enemies walking in, shots in flight, land mines
## and orbs. What fades around them lives in ArenaEffects, and how the Number
## moves and its light in NumberMotion. It reads the sim and never changes it.

const TowerData = preload("res://src/tower/tower_data.gd")
const Guesses = preload("res://src/tower/guesses.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")
const NumberMotion = preload("res://src/ui/number_motion.gd")
const ArenaEffects = preload("res://src/ui/arena_effects.gd")

## The Number reached a new digit this run (D099): 10, 100, 1K and on. `power`
## is how many noughts, 1 for 10.
signal digit_reached(power: int)

## The range circle's radius as a share of half the view's width, as on The
## Tower's screen (292 px of 460 in the owner's screenshots).
const RANGE_SHARE := 0.64
## As Range is bought the circle grows, until its edge, or the orbs' circle
## when they're further out (D108), would pass this share of the room around
## the Number (half the width, or the space above or below it); from there the
## view zooms out instead (D101), so the range, the ranged enemies standing on
## it and the orbs never leave the screen. The zoom eases over
## about 1 / ZOOM_EASE seconds rather than jumping when Range is bought.
const MAX_RANGE_SHARE := 0.92
const ZOOM_EASE := 4.0
## The Number is the biggest thing on screen (D085), large and thin as the
## owner's main-screen design has it: this size, shrinking to fit
## NUMBER_FIT_PX as its digits grow, never below NUMBER_MIN_PX.
const NUMBER_FONT_PX := 96
const NUMBER_FIT_PX := 230.0
const NUMBER_MIN_PX := 36
## The range as the design draws its ring: a hairline, barely there.
const RANGE_LINE := Color(1, 1, 1, 0.06)
## Enemies at the tower are drawn this clear of the Number's digits, which is
## only drawing: the sim's contact distance is unchanged.
const CONTACT_GAP_PX := 3.0
## A shot's trail in points, longer on a critical (D090).
const TRAIL_PX := 9.0
const CRIT_TRAIL_PX := 15.0
## The game's own things are drawn as notation (D106). An orb is a 0, since it
## sets what it touches to zero: ORB_PX tall in the shots' mint, with an arc of
## trail ORB_TRAIL_PX long behind it round the range.
const ORB_PX := 16
const ORB_TRAIL_PX := 28.0
const ORB_TRAIL_ALPHA := 0.35
## The Wall is a pair of brackets round the Number, since brackets are worked
## out first and the Wall is hit first: BRACKET_SCALE times the Number's size,
## in Geist at its thinnest, WALL_GAP_PX clear of its digits. When it falls
## they tip outward and drop in the warning colour over WALL_FALL_SECONDS;
## rebuilt, they slide back in over WALL_RISE_SECONDS.
const BRACKET_SCALE := 1.1
const WALL_GAP_PX := 4.0
const WALL_FALL_SECONDS := 0.7
const WALL_RISE_SECONDS := 0.4

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
## A new enemy fades in over its first metres.
const FADE_IN_M := 2.0
## The damage dealt so far, under an enemy that has lived through a shot (D102).
const DEALT_PX := 9
## A hit lights the outline this colour, unless the type says otherwise.
const FLASH := Color("f4f3ef")

var sim: BattleSim
## How far between the sim's last tick and its current one to draw things.
var blend := 1.0
## Where the tower stands, in the view.
var centre := Vector2.ZERO

## The fonts each enemy type is drawn in, built once from LOOKS, and the
## Number's and the floats' (shared with ArenaEffects).
var cuts := {}
var _number_cut := _cut(Palette.WORD_FONT, {"wght": 200})
var mono_cut := _cut(Palette.NUMBER_FONT, {"wght": 500})
var hit_cut := _cut(Palette.NUMBER_FONT, {"wght": 400})
var divide_cut := _cut(Palette.DIVIDER_FONT, LOOKS.divider.axes)
var _bracket_cut := _cut(Palette.WORD_FONT, {"wght": 100})
## The light behind the Number, drawn by its shader.
var _glow := ColorRect.new()
## How the Number moves and its light behaves, and what fades around the battle.
var motion := NumberMotion.new()
var effects := ArenaEffects.new(self)
## The scale drawn now, in points per metre, easing towards the target; 0
## until the first frame, and set outright when a new run starts.
var _zoom := 0.0
## Half the Number's drawn width and height this frame: the box enemies at
## the tower stand clear of, and floats start from.
var _number_half := Vector2.ZERO
## The box enemies at the tower stand clear of: the Number's, widened to take
## in the Wall's brackets while it stands.
var _clear_half := Vector2.ZERO
## The brackets' size in points this frame.
var _bracket_px := 0


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
		cuts[kind] = _cut(base, look.axes, look.get("slant", 0.0), look.get("spacing", 0))
	motion.digit_reached.connect(func(power: int): digit_reached.emit(power))


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
	# Every digit the same width (D103), where the font has them, so a number
	# changing its digits stays put rather than shuffling from side to side.
	cut.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("tnum"): 1}
	if slant != 0.0:
		cut.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(slant, 1.0), Vector2.ZERO)
	cut.spacing_glyph = spacing
	return cut


func px_per_metre() -> float:
	return _zoom if _zoom > 0.0 else target_px_per_metre()


## The scale the view is easing towards: The Tower's, until the range's edge
## would reach MAX_RANGE_SHARE of the room around the Number, then smaller.
func target_px_per_metre() -> float:
	var towers := size.x * 0.5 * RANGE_SHARE / TowerData.value("range", 0)
	if sim == null:
		return towers
	var room := minf(size.x * 0.5, minf(centre.y, size.y - centre.y)) * MAX_RANGE_SHARE
	# Orbs circle outside a small Range (D108), so they're kept in view too.
	var reach := sim.stat("range")
	if sim.stat("orbs") > 0.0:
		reach = maxf(reach, sim.defences.orb_radius())
	return minf(towers, room / maxf(reach, 0.001))


func to_view(world: Vector2) -> Vector2:
	return centre + world * px_per_metre()


## Takes the sim's events for this frame: the Number's motion and the view's
## zoom move on, and what fades around the battle ages and takes them in.
func absorb(events: Array[Dictionary], delta: float) -> void:
	if motion.update(sim, delta, _fit_size):
		_zoom = 0.0
	var target := target_px_per_metre()
	_zoom = target if _zoom <= 0.0 else lerpf(_zoom, target, 1.0 - exp(-delta * ZOOM_EASE))
	effects.absorb(events, delta)


## Flares the light behind the Number (NumberMotion.flare): for a ÷, and for
## anything else that should light it, such as a hit or an Ultimate Weapon.
func flare(colour: Color, strength: float, seconds: float) -> void:
	motion.flare(colour, strength, seconds)


## "2", "1.5", "1.25", "1.38": at most two decimals, none trailing.
static func divisor_text(divisor: float) -> String:
	return String.num(snappedf(divisor, 0.01), 2)


## Where a float at the Number starts: just above its digits, or out beside
## its upper right. Anything else starts where it happened, in metres.
func float_start(item: Dictionary) -> Vector2:
	match item.get("anchor", ""):
		"above":
			return centre + Vector2(0, -_number_half.y - 8.0)
		"beside":
			return centre + Vector2(_float_side(), -_number_half.y * 0.55)
		"growing":
			return centre + Vector2(-_float_side(), -_number_half.y * 0.55)
	return to_view(item.at)


## How far out beside the Number a float starts: clear of its digits, and of
## the Wall's brackets while they stand.
func _float_side() -> float:
	return maxf(_number_half.x + 48.0, _clear_half.x + 16.0)


func _draw() -> void:
	if sim == null:
		return
	var reach_px := sim.stat("range") * px_per_metre()
	_light_glow()
	if motion.digit_left > 0.0:
		# The new digit's ring: out from the Number towards the range's edge,
		# fading as it goes.
		var spread := 1.0 - motion.digit_left / NumberMotion.DIGIT_SECONDS
		var from := _number_half.length()
		var eased := 1.0 - pow(1.0 - spread, 3.0)
		draw_arc(centre, lerpf(from, reach_px * 0.95, eased), 0.0, TAU, 128, Color(Palette.NUMBER, 0.5 * (1.0 - spread)), 1.5, true)
	draw_arc(centre, reach_px, 0.0, TAU, 128, RANGE_LINE, 1.0, true)
	effects.draw_shockwave(reach_px)
	for mine in sim.defences.mines:
		draw_circle(to_view(mine), 3.0, Palette.WARNING)
	effects.draw_blasts(sim.stat("land_mine_radius") * px_per_metre())
	var number := _number_layout()
	_draw_wall()
	effects.draw_ranged_shots(_number_half)
	for enemy in sim.enemies:
		_draw_enemy(enemy)
	effects.draw_pops()
	effects.draw_sparks()
	_draw_orbs()
	for shot in sim.shots:
		_draw_shot(shot)
	effects.draw_chips()
	_draw_tower(number)
	effects.draw_glints()
	_draw_divider_preview()
	effects.draw_floats()


## The Number's text and size this frame: whole, as Palette.number_shown has
## it (a standing tower never reads 0), a size larger while Rapid Fire runs,
## shrinking to fit as its digits grow. Sets the box enemies stand clear of.
func _number_layout() -> Dictionary:
	var shown := motion.shown_number if motion.shown_number >= 0.0 else Palette.number_shown(sim.health, sim.max_health(), sim.alive)
	# Rolling, it's whole, and a standing tower still never reads 0.
	var text := Palette.full(maxf(roundf(shown), 1.0) if sim.alive else roundf(shown))
	var font_size := _fit_size(text)
	# Drawn at the fitting size and scaled to the eased one, so the Number
	# shrinks smoothly as digits arrive rather than stepping (D103).
	var scale := motion.shown_size / float(font_size) if motion.shown_size > 0.0 else 1.0
	var width := _number_cut.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# Digits stand about 0.7 of the font size tall.
	_number_half = Vector2(width * 0.5, font_size * 0.35) * scale
	_bracket_px = maxi(1, roundi(float(font_size) * scale * BRACKET_SCALE))
	_clear_half = _number_half
	if sim.defences.wall_up():
		# Enemies held at the Wall stand clear of its brackets, not in them.
		var bracket := _bracket_cut.get_string_size("(", HORIZONTAL_ALIGNMENT_LEFT, -1, _bracket_px).x
		_clear_half = Vector2(_number_half.x + WALL_GAP_PX + bracket, maxf(_number_half.y, _bracket_px * 0.5))
	return {"text": text, "size": font_size, "width": width, "scale": scale}


## The size the Number's text fits at: NUMBER_FONT_PX, a size larger while
## Rapid Fire runs, shrinking as its digits grow.
func _fit_size(text: String) -> int:
	var font_size := NUMBER_FONT_PX + (6 if sim.rapid_fire_left > 0.0 else 0)
	while font_size > NUMBER_MIN_PX and _number_cut.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > NUMBER_FIT_PX:
		font_size -= 2
	return font_size


## The tower is the Number (D084), drawn over everything but the floats: the
## most important thing on screen (D085). White and thin, with a soft light of
## its own inside the one behind it (D096); it shakes when a ÷ lands.
func _draw_tower(number: Dictionary) -> void:
	var at := centre + motion.offset()
	var font_size: int = number.size
	# A new digit's swell and a gain's lift, and the eased size, scale it.
	var swell := motion.swell() * float(number.scale)
	draw_set_transform(at, 0.0, Vector2(swell, swell))
	at = Vector2.ZERO
	var baseline := at + Vector2(-number.width * 0.5, font_size * 0.35)
	# The design's text-shadow, faked with wide faint outlines rather than a blur.
	for glow in [[22, 0.025], [12, 0.04], [5, 0.06]]:
		draw_string_outline(_number_cut, baseline, number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, glow[0], Color(1.0, 0.98, 0.94, glow[1]))
	draw_string(_number_cut, baseline, number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.NUMBER)
	draw_set_transform(Vector2.ZERO)


## The Wall as brackets round the Number (D106), brighter the more of its
## health it has left. They hold still while the Number is nudged and shaken,
## as a wall would. Falling, they tip outward and drop in the warning colour;
## rebuilt, they slide back in.
func _draw_wall() -> void:
	var since: float = effects.wall_changed_age
	var falling: bool = not sim.defences.wall_up() and effects.wall_fell and since < WALL_FALL_SECONDS
	if not sim.defences.wall_up() and not falling:
		return
	var standing: float = sim.defences.wall_health / maxf(sim.defences.wall_max_health(), 0.001)
	var colour := Color(Palette.TEXT, 0.25 + 0.5 * standing)
	var out := 0.0
	var tip := 0.0
	var drop := 0.0
	if falling:
		var done := since / WALL_FALL_SECONDS
		colour = Color(Palette.WARNING, 0.6 * (1.0 - done))
		out = 10.0 * done
		tip = 0.5 * done
		drop = 28.0 * done * done
	elif not effects.wall_fell and since < WALL_RISE_SECONDS:
		var done := since / WALL_RISE_SECONDS
		colour.a *= done
		out = 12.0 * (1.0 - done)
	for side in [-1.0, 1.0]:
		var glyph := "(" if side < 0.0 else ")"
		var width := _bracket_cut.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, _bracket_px).x
		var middle := centre + Vector2(side * (_number_half.x + WALL_GAP_PX + out + width * 0.5), drop)
		draw_set_transform(middle, side * tip, Vector2.ONE)
		# A bracket's middle sits about 0.3 of its size above the baseline.
		draw_string(_bracket_cut, Vector2(-width * 0.5, _bracket_px * 0.3), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, _bracket_px, colour)
	draw_set_transform(Vector2.ZERO)


## Orbs as a mint 0 each on the range's edge (D106), with a short arc of trail
## fading behind as they turn.
func _draw_orbs() -> void:
	var radius_px: float = sim.defences.orb_radius() * px_per_metre()
	if radius_px <= 0.0:
		return
	var zero := mono_cut.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, ORB_PX)
	# The trail stops short of the 0 rather than running through it.
	var gap: float = zero.x * 0.7 / radius_px
	var span: float = ORB_TRAIL_PX / radius_px
	for angle in sim.defences.orb_angles():
		var points := PackedVector2Array()
		var colours := PackedColorArray()
		for step in range(9):
			var along := step / 8.0
			points.append(centre + Vector2.from_angle(angle - gap - span * (1.0 - along)) * radius_px)
			colours.append(Color(Palette.ACCENT, ORB_TRAIL_ALPHA * along))
		draw_polyline_colors(points, colours, 1.2, true)
		var at: Vector2 = centre + Vector2.from_angle(angle) * radius_px
		draw_string(mono_cut, at + Vector2(-zero.x * 0.5, ORB_PX * 0.35), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, ORB_PX, Palette.ACCENT)


## Sets the light behind the Number for this frame, as NumberMotion has it.
func _light_glow() -> void:
	var now := motion.light()
	var light := _glow.material as ShaderMaterial
	light.set_shader_parameter("centre_px", centre)
	light.set_shader_parameter("rect_px", size)
	light.set_shader_parameter("tint", now.tint)
	light.set_shader_parameter("strength", now.strength)
	light.set_shader_parameter("breath", now.breath)


## An enemy is drawn as its one number (D085, D102): what it does to the
## Number, in its type's typeface and colour, with the damage dealt so far
## under it once it has lived through a shot. It rocks as it's shot and lunges
## as it hits (D103), and fades in as it arrives.
func _draw_enemy(enemy: BattleSim.Enemy) -> void:
	var look: Dictionary = LOOKS[enemy.kind]
	var text := shown_text(sim, enemy)
	var half := enemy_half(enemy.kind, text)
	var at := enemy_at(enemy.angle, _shown_metres(enemy), half)
	# A shot rocks it back, landing a hit it lunges in (D103).
	at += Vector2.from_angle(enemy.angle) * float(effects.recoil.get(enemy.id, 0.0))
	# A new enemy fades in over its first metres.
	var shade := clampf((Guesses.SPAWN_DISTANCE_M - enemy.distance) / FADE_IN_M, 0.0, 1.0)
	var font: Font = cuts[enemy.kind]
	var font_size: int = look.size
	var baseline := at + Vector2(-half.x, font_size * 0.35)
	if look.has("glow"):
		# A soft glow, faked with two wide faint outlines rather than a blur.
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, Color(look.glow, 0.08 * shade))
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(look.glow, 0.12 * shade))
	if effects.flashes.has(enemy.id):
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, look.get("flash", FLASH))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(look.colour, shade))
	var dealt := dealt_text(enemy)
	if dealt != "":
		# The Tower's way: the damage so far, small and white, under the enemy.
		var dealt_width := hit_cut.get_string_size(dealt, HORIZONTAL_ALIGNMENT_LEFT, -1, DEALT_PX).x
		draw_string(hit_cut, at + Vector2(-dealt_width * 0.5, half.y + DEALT_PX + 1.0), dealt, HORIZONTAL_ALIGNMENT_LEFT, -1, DEALT_PX, Color(Palette.NUMBER, 0.8))


## The nearest Divider inside the range shows what it will do above the
## Number, "÷1.5 → 301", so a ÷ never lands unseen (D085). It makes way while
## a ÷ that has just landed floats up from the same spot.
func _draw_divider_preview() -> void:
	if effects.operator_float_rising():
		return
	var preview := divider_preview(sim)
	if preview.is_empty():
		return
	var parts := [[preview.sign, divide_cut, 13], ["  → " + preview.after, mono_cut, 11]]
	var width := 0.0
	for part in parts:
		width += (part[1] as Font).get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x
	# Where the ÷ float starts, so the landing turns one into the other.
	var at := float_start({"anchor": "above"}) + Vector2(-width * 0.5, -14.0)
	for part in parts:
		var font: Font = part[1]
		draw_string(font, at, part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2], Color(Palette.DIVIDER, 0.85))
		at.x += font.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, part[2]).x


## A shot with a short trail fading behind it along its path: longer and
## white on a critical, so a crit reads as a harder shot.
func _draw_shot(shot: BattleSim.Shot) -> void:
	var at := to_view(shot.last_position.lerp(shot.position, blend))
	# The Number's shots are white (D109); a critical is larger, with a halo.
	var colour := Palette.NUMBER
	var offset := at - centre
	var direction := offset.normalized() if offset.length() > 0.001 else Vector2.RIGHT
	var edge := edge_px(direction)
	# Leaving the Number, a shot shows only once it's clear of the digits, and
	# its trail never reaches back inside them.
	if offset.length() < edge:
		return
	var heading := shot.position - shot.last_position
	if heading.length() > 0.001:
		var tail := at - heading.normalized() * (CRIT_TRAIL_PX if shot.critical else TRAIL_PX)
		if (tail - centre).dot(direction) < edge and offset.length() < edge + CRIT_TRAIL_PX:
			tail = centre + direction * edge
		draw_polyline_colors(PackedVector2Array([tail, at]), PackedColorArray([Color(colour, 0.0), Color(colour, 0.75)]), 2.0 if shot.critical else 1.4, true)
	if shot.critical:
		draw_circle(at, 4.5, Color(colour, 0.18))
	draw_circle(at, 2.4 if shot.critical else 1.6, colour)


## How far from the centre the Number's digits reach along `direction`: the
## edge of its box, where shots leave it and enemies stand clear of it.
func edge_px(direction: Vector2) -> float:
	var reach := INF
	if absf(direction.x) > 0.001:
		reach = _number_half.x / absf(direction.x)
	if absf(direction.y) > 0.001:
		reach = minf(reach, _number_half.y / absf(direction.y))
	return reach if reach != INF else 0.0


## How far out to draw an enemy: where it is, or where a knockback's slide has got to.
func _shown_metres(enemy: BattleSim.Enemy) -> float:
	return effects.shown_metres(enemy)


## Half an enemy's drawn width and height.
func enemy_half(kind: String, text: String) -> Vector2:
	var font_size: int = LOOKS[kind].size
	var width: float = (cuts[kind] as Font).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return Vector2(width, font_size * 0.7) * 0.5


## Where an enemy is drawn: where it stands, or, at the tower, just clear of
## the Number's digits on its own side, and of the Wall's brackets while it
## stands.
func enemy_at(angle: float, distance_m: float, half: Vector2) -> Vector2:
	var toward := Vector2.from_angle(angle)
	var clear := _clear_half + half + Vector2(CONTACT_GAP_PX, CONTACT_GAP_PX)
	# The nearest it can come along its line without the two boxes touching.
	var nearest := INF
	if absf(toward.x) > 0.001:
		nearest = clear.x / absf(toward.x)
	if absf(toward.y) > 0.001:
		nearest = minf(nearest, clear.y / absf(toward.y))
	return centre + toward * maxf(distance_m * px_per_metre(), nearest)


## The number an enemy shows is what it does to the Number (D102), from the
## moment it appears until it dies: "−2.4" for a hit after the tower's
## defences, "÷1.5" for a Divider. It doesn't count down as it's shot; the
## damage dealt so far shows under it instead.
static func shown_text(battle: BattleSim, enemy: BattleSim.Enemy) -> String:
	return operation_text(battle, enemy)


## The damage dealt to an enemy so far, for the small white line under it
## (D102): empty until a shot has landed and it has lived through it, so an
## enemy killed in one shot never shows one.
static func dealt_text(enemy: BattleSim.Enemy) -> String:
	var dealt := enemy.max_health - enemy.health
	if dealt <= 0.0 or enemy.health <= 0.0:
		return ""
	return Palette.amount(dealt)


## What an enemy does: its next hit off the Number, after the tower's
## defences and growing 4% a hit (so it ticks up while it stands there), or a
## Divider's ÷.
static func operation_text(battle: BattleSim, enemy: BattleSim.Enemy) -> String:
	if enemy.kind == "divider":
		return "÷" + divisor_text(enemy.divisor)
	return "−" + Palette.amount(battle.landed_damage(enemy.attack * pow(Guesses.HEAT_UP_PER_HIT, enemy.hits)))


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
	if not battle.defences.wall_up():
		var left := battle.health - battle.divide_loss(nearest.divisor)
		after = Palette.full(Palette.number_shown(left, battle.max_health(), true))
	return {"sign": operation_text(battle, nearest), "after": after}
