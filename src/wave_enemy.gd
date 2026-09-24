class_name WaveEnemy
extends Control

## The wave drawn as a body (D050): a pill carrying the wave's remaining HP that
## closes on the Number over the wave's 15-second clock. Presentation only; the
## clock, the HP and the Hit all belong to GameState, and main.gd moves this.
## The same node plays the two outcome beats as a short-lived copy: a clean
## clear shatters it, and a Hit slams it into the Number.

enum Beat { NONE, SHATTER, SLAM }

const PAD := Vector2(10.0, 5.0)
const FRAGMENTS := 8
const FILL := Color("1c1d20")

var font: Font
var font_size := 15
var text := ""
var tint := Color.WHITE
## 0 at rest, rising to 1 across a beat; drives the fragments and the fade.
var beat_progress := 0.0:
	set(value):
		beat_progress = value
		queue_redraw()
var beat: int = Beat.NONE
var _style := StyleBoxFlat.new()

func _init(number_font: Font) -> void:
	font = number_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Sets what the body reads and its colour; resizes only when the text's width
## changes, so a steadily falling HP does not reflow every frame.
func show_value(new_text: String, new_tint: Color, new_size: int) -> void:
	if new_text == text and new_tint.is_equal_approx(tint) and new_size == font_size:
		return
	text = new_text
	tint = new_tint
	font_size = new_size
	var measured := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size) + PAD * 2.0
	if not measured.is_equal_approx(size):
		size = measured
		pivot_offset = size / 2.0
	queue_redraw()

## Places the body's centre on a point in its parent's space.
func centre_on(point: Vector2) -> void:
	position = point - size / 2.0

func _draw() -> void:
	var fade := 1.0 - beat_progress
	if beat == Beat.SHATTER:
		# The pieces fly outward as the pill itself fades, so a clean clear reads
		# as the wave breaking apart before it reached you.
		var centre := size / 2.0
		for index in range(FRAGMENTS):
			var angle := TAU * float(index) / float(FRAGMENTS) + 0.4
			var reach := size.x * 0.5 + beat_progress * 30.0
			draw_circle(centre + Vector2(cos(angle), sin(angle)) * reach, 2.0 * fade + 0.5, Color(tint, fade))
		fade *= fade
	_style.bg_color = Color(FILL, fade)
	_style.border_color = Color(tint, 0.55 * fade)
	_style.set_border_width_all(1)
	_style.set_corner_radius_all(int(size.y / 2.0))
	draw_style_box(_style, Rect2(Vector2.ZERO, size))
	var baseline := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	draw_string(font, Vector2(0.0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color(tint, fade))
