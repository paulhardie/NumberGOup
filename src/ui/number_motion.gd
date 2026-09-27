extends RefCounted
## How the Number moves and how its light behaves, frame to frame (D087, D096,
## D099, D103): it rolls to new values, eases its size as digits arrive, sits
## on a spring that hits knock and gains lift, shakes when a ÷ lands, and
## marks each new digit a run reaches; its light breathes and flares. Drawing
## only: it reads the sim and never changes it. The arena draws with it.

const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")

## The Number reached a new digit this run (D099): 10, 100, 1K and on. `power`
## is how many noughts, 1 for 10.
signal digit_reached(power: int)

## The light breathes over this many seconds (D096).
const GLOW_BREATH_SECONDS := 5.5
## A new digit (D099): the light flares white this much stronger, a ring
## spreads from the Number to near the range's edge, and the Number swells by
## DIGIT_SWELL and settles, all over DIGIT_SECONDS.
const DIGIT_FLARE := 2.0
const DIGIT_SECONDS := 1.4
const DIGIT_SWELL := 0.14
## How long the Number shakes after a ÷, in seconds, and by how many pixels.
const SHAKE_SECONDS := 0.3
const SHAKE_PX := 4.0
## The Number rolls to its new value rather than jumping, quickly: rising at
## ROLL_RISE a second, falling faster, at ROLL_FALL, so a hit lands at once.
const ROLL_RISE := 10.0
const ROLL_FALL := 22.0
## Its size eases to fit as its digits grow rather than stepping.
const SIZE_EASE := 8.0
## A spring holds the Number in place: a hit knocks it away from the enemy
## by up to NUDGE_PX, more the bigger the hit is against the Number, and a
## gain lifts it by up to LIFT; it springs back with one soft overshoot.
const SPRING := 170.0
const SPRING_DAMPING := 13.0
const NUDGE_PX := 7.0
const LIFT := 0.06

## The Number as drawn, rolling towards the true one, and the size it's drawn
## at, easing; below zero until the first frame of a run.
var shown_number := -1.0
var shown_size := 0.0
## The spring's offset and velocity in points, and its swell and the swell's
## velocity.
var nudge := Vector2.ZERO
var nudge_speed := Vector2.ZERO
var lift := 0.0
var lift_speed := 0.0
## Seconds left of a new digit's moment, and of a ÷'s shake.
var digit_left := 0.0
var divide_left := 0.0
## What's flaring the light: {colour, strength, seconds, left}, or empty.
var flare_state := {}
var _glow_time := 0.0
## The run whose digits are being watched, and the most it has reached.
var _watched: BattleSim
var _best_power := 0


## Moves everything on by `delta` for `sim`. `fit_size` gives the size the
## Number's text fits at, which only the arena can measure. True when `sim` is
## a run not seen before, so the arena can start it afresh too.
func update(sim: BattleSim, delta: float, fit_size: Callable) -> bool:
	_glow_time += delta
	if not flare_state.is_empty():
		flare_state.left -= delta
		if flare_state.left <= 0.0:
			flare_state = {}
	divide_left = maxf(0.0, divide_left - delta)
	digit_left = maxf(0.0, digit_left - delta)
	var fresh := _watch_digits(sim)
	_settle(sim, delta, fit_size)
	return fresh


## Flares the light behind the Number: `colour`, `strength` stronger, easing
## back to white over `seconds`. A ÷ uses it; anything else that should light
## the Number (a hit, an Ultimate Weapon) can too. A new flare replaces one
## still fading.
func flare(colour: Color, strength: float, seconds: float) -> void:
	flare_state = {"colour": colour, "strength": strength, "seconds": seconds, "left": seconds}


## A ÷ has landed: the Number shakes.
func shake() -> void:
	divide_left = SHAKE_SECONDS


## A hit knocks the Number away from the enemy that landed it, harder the
## bigger the hit is against the Number.
func knock(angle: float, damage: float) -> void:
	var share := clampf(damage / maxf(shown_number, 1.0), 0.0, 1.0)
	nudge_speed -= Vector2.from_angle(angle) * NUDGE_PX * SPRING_DAMPING * sqrt(share)


## A gain lifts the Number a little, more the bigger it is against the Number.
func raise(gain: float) -> void:
	lift_speed += LIFT * SPRING_DAMPING * sqrt(clampf(gain / maxf(shown_number, 1.0), 0.0, 1.0))


## Where the Number stands off its centre this frame: the ÷'s shake and the
## spring's offset.
func offset() -> Vector2:
	var shake_by := Vector2.ZERO
	if divide_left > 0.0:
		var strength := divide_left / SHAKE_SECONDS
		shake_by = Vector2(sin(divide_left * 90.0), cos(divide_left * 70.0)) * SHAKE_PX * strength
	return shake_by + nudge


## How much larger than its fitting size the Number is drawn: a new digit
## swells it at once and it eases back as the moment passes, and a gain's
## lift adds to it.
func swell() -> float:
	return (1.0 + DIGIT_SWELL * pow(digit_left / DIGIT_SECONDS, 2.0)) * (1.0 + lift)


## The light for this frame: {tint, strength, breath}. It breathes slowly,
## tinted and brightened by a flare while one fades.
func light() -> Dictionary:
	var tint := Palette.LIGHT
	var strength := 1.0
	if not flare_state.is_empty():
		var left: float = flare_state.left / flare_state.seconds
		strength += flare_state.strength * left
		tint = Palette.LIGHT.lerp(flare_state.colour, left)
	# Eased in and out, as the design's breathing is.
	return {"tint": tint, "strength": strength, "breath": 0.5 - 0.5 * cos(_glow_time * TAU / GLOW_BREATH_SECONDS)}


## How many noughts a Number has as it's shown whole: 1 for 10 to 99.
static func power_of(value: float) -> int:
	var whole := roundf(value)
	if whole < 1.0:
		return 0
	return int(floorf(log(whole) / log(10.0) + 1e-9))


## A new digit is a moment only the first time a run reaches it: a Number
## knocked back below 100 and climbing past it again has done that already.
## A new run, or one resumed, starts from where its Number already stands.
func _watch_digits(sim: BattleSim) -> bool:
	if sim == null:
		return false
	if sim != _watched:
		_watched = sim
		_best_power = power_of(sim.peak_number)
		digit_left = 0.0
		shown_number = -1.0
		shown_size = 0.0
		return true
	var power := power_of(sim.peak_number)
	if power > _best_power:
		_best_power = power
		digit_left = DIGIT_SECONDS
		flare(Palette.NUMBER, DIGIT_FLARE, DIGIT_SECONDS)
		digit_reached.emit(power)
	return false


## The spring, the roll and the size ease, a frame at a time.
func _settle(sim: BattleSim, delta: float, fit_size: Callable) -> void:
	if delta <= 0.0:
		return
	# Small steps, so a slow frame can't make the spring overshoot wildly.
	var left := delta
	while left > 0.0:
		var step := minf(left, 1.0 / 120.0)
		left -= step
		nudge_speed += (-SPRING * nudge - SPRING_DAMPING * nudge_speed) * step
		nudge += nudge_speed * step
		lift_speed += (-SPRING * lift - SPRING_DAMPING * lift_speed) * step
		lift += lift_speed * step
	if sim == null:
		return
	var truth := Palette.number_shown(sim.health, sim.max_health(), sim.alive)
	if shown_number < 0.0:
		shown_number = truth
	else:
		var rate := ROLL_RISE if truth > shown_number else ROLL_FALL
		shown_number = lerpf(shown_number, truth, 1.0 - exp(-delta * rate))
		if absf(truth - shown_number) < 0.5:
			shown_number = truth
	var target := float(fit_size.call(Palette.full(maxf(roundf(shown_number), 1.0))))
	shown_size = target if shown_size <= 0.0 else lerpf(shown_size, target, 1.0 - exp(-delta * SIZE_EASE))
