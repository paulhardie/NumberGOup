class_name ArenaFx
extends Control

## What moves across the run arena besides the wave itself (D051): the faint
## trail behind the wave, and the motes that carry the player's damage from
## the Number to it. Presentation only. The damage is already dealt in
## GameState when a mote leaves; a mote only decides when the wave's shown HP
## catches up, so the number drops as each one lands.

## Seconds a mote takes to reach the wave.
const FLIGHT := 0.32
## How far behind a mote its fading tail dots sit, in shares of its flight.
const TAIL := [0.06, 0.12, 0.19]
const BITE_SECONDS := 0.25

var accent := Color.WHITE
var critical := Color.WHITE
## Where motes fly to: the wave's number, moved by main.gd every frame.
var target := Vector2.ZERO
var trail_from := Vector2.ZERO
var trail_to := Vector2.ZERO
var trail_colour := Color.TRANSPARENT
## The Number's reach, The Tower's range circle (D067), set by main.gd.
var ring_points := PackedVector2Array()
var ring_colour := Color.TRANSPARENT
## The orbs circling the Number (D068), set by main.gd every frame.
var orb_points := PackedVector2Array()
var orb_colour := Color.TRANSPARENT
## Each mote is {from, t (0..1, below 0 while it waits to leave), amount,
## crit, tap}; each bite {at, age}.
var _motes: Array = []
var _bites: Array = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## `delay` holds a mote at the Number for that many seconds first, so a
## Multishot's second shot follows the first rather than hiding under it.
func fire(from: Vector2, amount: ScientificNumber, crit: bool, tap: bool = false, delay: float = 0.0) -> void:
	if amount.is_zero():
		return
	_motes.append({"from": from, "t": -delay / FLIGHT, "amount": amount, "crit": crit, "tap": tap})

## Drops every mote in flight, for a wave that is gone or a run that ended.
func clear_motes() -> void:
	_motes.clear()
	queue_redraw()

## The damage already dealt but not yet shown landing.
func in_flight() -> ScientificNumber:
	var total := ScientificNumber.new()
	for mote in _motes:
		total = total.add(mote.amount)
	return total

## Advances every mote and bite, and returns the motes that landed this step,
## so main.gd can show their damage coming off the wave.
func step(delta: float) -> Array:
	for mote in _motes:
		mote.t += delta / FLIGHT
	var landed := _motes.filter(func(mote): return mote.t >= 1.0)
	for mote in landed:
		_bites.append({"at": target, "age": 0.0, "crit": mote.crit})
	_motes = _motes.filter(func(mote): return mote.t < 1.0)
	for bite in _bites:
		bite.age += delta
	_bites = _bites.filter(func(bite): return bite.age < BITE_SECONDS)
	queue_redraw()
	return landed

func _point(mote: Dictionary, t: float) -> Vector2:
	# Eased out, so a mote leaves the Number briskly and settles into the wave.
	var eased := 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 2.0)
	return (mote.from as Vector2).lerp(target, eased)

func _draw() -> void:
	if ring_colour.a > 0.0 and ring_points.size() > 1:
		draw_polyline(ring_points, ring_colour, 1.0, true)
	for orb in orb_points:
		draw_circle(orb, 4.0, orb_colour)
	if trail_colour.a > 0.0:
		draw_polyline_colors(PackedVector2Array([trail_from, trail_to]), PackedColorArray([Color(trail_colour, 0.0), trail_colour]), 1.0, true)
	for mote in _motes:
		if mote.t < 0.0:
			continue
		var colour: Color = critical if mote.crit else accent
		var radius := 2.6 if mote.crit else 2.1
		draw_circle(_point(mote, mote.t), radius, Color(colour, 0.9))
		for index in range(TAIL.size()):
			var behind: float = mote.t - TAIL[index]
			if behind > 0.0:
				draw_circle(_point(mote, behind), radius * (0.75 - 0.15 * index), Color(colour, 0.5 - 0.14 * index))
	for bite in _bites:
		var share: float = bite.age / BITE_SECONDS
		var colour: Color = critical if bite.crit else accent
		draw_circle(bite.at, 5.0 + 7.0 * share, Color(colour, 0.16 * (1.0 - share)))
