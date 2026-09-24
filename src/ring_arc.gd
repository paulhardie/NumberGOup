class_name RingArc
extends Control

## A progress ring. On the run stage the outer arc is how much of the wave's
## Liability is cleared and a thin inner ring drains with the time left before
## its hit (D049), so both encounter axes read in one glance around the Number.
## On the hub the same ring shows the highest wave against the next goal, with
## a dot for each milestone on the way.

const TRACK_COLOUR := Color(0.925, 0.925, 0.918, 0.08)
const INNER_TRACK_COLOUR := Color(0.925, 0.925, 0.918, 0.04)
## How far inside the outer ring the inner one runs.
const INNER_GAP := 9.0
const MARKER_RADIUS := 3.0

enum Marker { CLAIMED, NEXT, AHEAD }

var radius_ratio := 0.32
var progress := 0.0
var arc_colour := Color.WHITE
var thickness := 7.0
## Zero hides the inner ring.
var inner_thickness := 0.0
var inner_progress := 0.0
var inner_colour := Color.WHITE
## Each entry is {"at": 0..1 around the ring, "state": Marker}.
var markers: Array = []
var marker_colour := Color.WHITE
var marker_next_colour := Color.WHITE
var marker_ahead_colour := Color(0.925, 0.925, 0.918, 0.18)
## Painted under each dot so it cuts the arc rather than sitting on it.
var cutout_colour := Color.BLACK

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Radius in pixels at the node's current size, so callers can size the number
## to fit inside the ring rather than guessing.
func radius() -> float:
	return minf(size.x, size.y) * radius_ratio

func set_arc(new_progress: float, new_colour: Color) -> void:
	var clamped := clampf(new_progress, 0.0, 1.0)
	if is_equal_approx(clamped, progress) and new_colour.is_equal_approx(arc_colour):
		return
	progress = clamped
	arc_colour = new_colour
	queue_redraw()

func set_inner(new_progress: float, new_colour: Color) -> void:
	var clamped := clampf(new_progress, 0.0, 1.0)
	if is_equal_approx(clamped, inner_progress) and new_colour.is_equal_approx(inner_colour):
		return
	inner_progress = clamped
	inner_colour = new_colour
	queue_redraw()

func set_markers(new_markers: Array) -> void:
	if new_markers == markers:
		return
	markers = new_markers
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var centre := size / 2.0
	var r := radius()
	if r <= 0.0:
		return
	_draw_ring(centre, r, thickness, TRACK_COLOUR, progress, arc_colour, true)
	if inner_thickness > 0.0:
		_draw_ring(centre, r - INNER_GAP, inner_thickness, INNER_TRACK_COLOUR, inner_progress, inner_colour, false)
	for marker in markers:
		var angle := -PI / 2.0 + TAU * clampf(float(marker.at), 0.0, 1.0)
		var point := centre + Vector2(cos(angle), sin(angle)) * r
		draw_circle(point, MARKER_RADIUS + 2.0, cutout_colour)
		match int(marker.state):
			Marker.CLAIMED:
				draw_circle(point, MARKER_RADIUS, marker_colour)
			Marker.NEXT:
				draw_arc(point, MARKER_RADIUS + 0.5, 0.0, TAU, 16, marker_next_colour, 1.5, true)
			_:
				draw_circle(point, MARKER_RADIUS, marker_ahead_colour)

func _draw_ring(centre: Vector2, r: float, width: float, track: Color, amount: float, colour: Color, round_caps: bool) -> void:
	draw_arc(centre, r, 0.0, TAU, 128, track, width, true)
	if amount <= 0.0:
		return
	var start := -PI / 2.0
	var finish := start + TAU * amount
	draw_arc(centre, r, start, finish, 128, colour, width, true)
	if round_caps:
		# draw_arc has no round cap of its own, so the two ends get a dot each.
		var cap := width / 2.0
		draw_circle(centre + Vector2(cos(start), sin(start)) * r, cap, colour)
		draw_circle(centre + Vector2(cos(finish), sin(finish)) * r, cap, colour)
