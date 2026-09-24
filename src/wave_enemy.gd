class_name WaveEnemy
extends Control

## The wave drawn as a number (D050, D051): its remaining HP in Geist Mono,
## with a small caption for its Hit, closing on the Number over the wave's
## 15-second clock. Presentation only; the clock, the HP and the Hit belong to
## GameState, and main.gd moves this. The same node plays the two outcome
## beats as a short-lived copy: a clean clear scatters its digits, and a Hit
## swells it into the Number.

enum Beat { NONE, SHATTER, SLAM }

const CAPTION_SIZE := 10
const CAPTION_GAP := 3.0

var font: Font
var font_size := 18
var text := ""
var tint := Color.WHITE
var caption := ""
var caption_tint := Color.WHITE
## 0 at rest, rising to 1 across a beat; drives the scatter and the fade.
var beat_progress := 0.0:
	set(value):
		beat_progress = value
		queue_redraw()
var beat: int = Beat.NONE

func _init(number_font: Font) -> void:
	font = number_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Sets what the number and its caption read; resizes only when their widths
## change, so a steadily falling HP does not reflow every frame.
func show_value(new_text: String, new_tint: Color, new_size: int, new_caption: String = "", new_caption_tint: Color = Color.WHITE) -> void:
	if new_text == text and new_tint.is_equal_approx(tint) and new_size == font_size and new_caption == caption and new_caption_tint.is_equal_approx(caption_tint):
		return
	text = new_text
	tint = new_tint
	font_size = new_size
	caption = new_caption
	caption_tint = new_caption_tint
	var value_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var measured := value_size
	if caption != "":
		var caption_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, CAPTION_SIZE)
		measured = Vector2(maxf(value_size.x, caption_size.x), value_size.y + CAPTION_GAP + caption_size.y)
	if not measured.is_equal_approx(size):
		size = measured
		pivot_offset = Vector2(size.x / 2.0, _value_height() / 2.0)
	queue_redraw()

## Places the number's own centre (not the caption's) on a point in its
## parent's space, so the path is the number's path.
func centre_on(point: Vector2) -> void:
	position = point - Vector2(size.x / 2.0, _value_height() / 2.0)

## Where the number's centre is now, in its parent's space.
func value_centre() -> Vector2:
	return position + Vector2(size.x / 2.0, _value_height() / 2.0)

func _value_height() -> float:
	return font.get_height(font_size)

func _draw() -> void:
	var fade := 1.0 - beat_progress
	var baseline := font.get_ascent(font_size)
	if beat == Beat.SHATTER:
		# The number breaks into its digits, each flying out and turning, so a
		# clean clear reads as the wave coming apart before it reached you.
		var advance := 0.0
		var total := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var start := (size.x - total) / 2.0
		for index in range(text.length()):
			var glyph := text[index]
			var width := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var spread := float(index) - float(text.length() - 1) / 2.0
			var drift := Vector2(spread * 14.0, -18.0 - absf(spread) * 4.0) * beat_progress
			draw_set_transform(Vector2(start + advance + width / 2.0, baseline) + drift, spread * 0.35 * beat_progress, Vector2.ONE)
			draw_string(font, Vector2(-width / 2.0, 0.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(tint, fade))
			advance += width
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_string(font, Vector2(0.0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color(tint, fade))
	if caption != "" and beat == Beat.NONE:
		var caption_baseline := _value_height() + CAPTION_GAP + font.get_ascent(CAPTION_SIZE)
		draw_string(font, Vector2(0.0, caption_baseline), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, CAPTION_SIZE, caption_tint)
