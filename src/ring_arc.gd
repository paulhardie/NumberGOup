class_name RingArc
extends Control

## The stage ring. Its length is how much of the wave's Liability is cleared,
## its colour is how close the Collection hit is, so one element carries both
## encounter axes and the player reads progress and threat in a single glance.

const RADIUS_RATIO := 0.32
const TRACK_COLOUR := Color(0.925, 0.925, 0.918, 0.08)

var progress := 0.0
var arc_colour := Color.WHITE
var thickness := 7.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Radius in pixels at the node's current size, so callers can size the number
## to fit inside the ring rather than guessing.
func radius() -> float:
	return minf(size.x, size.y) * RADIUS_RATIO

func set_arc(new_progress: float, new_colour: Color) -> void:
	var clamped := clampf(new_progress, 0.0, 1.0)
	if is_equal_approx(clamped, progress) and new_colour.is_equal_approx(arc_colour):
		return
	progress = clamped
	arc_colour = new_colour
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var centre := size / 2.0
	var r := radius()
	if r <= 0.0:
		return
	draw_arc(centre, r, 0.0, TAU, 128, TRACK_COLOUR, thickness, true)
	if progress <= 0.0:
		return
	var start := -PI / 2.0
	var finish := start + TAU * progress
	draw_arc(centre, r, start, finish, 128, arc_colour, thickness, true)
	# draw_arc has no round cap of its own, so the two ends get a dot each.
	var cap := thickness / 2.0
	draw_circle(centre + Vector2(cos(start), sin(start)) * r, cap, arc_colour)
	draw_circle(centre + Vector2(cos(finish), sin(finish)) * r, cap, arc_colour)
