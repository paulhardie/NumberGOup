class_name IconGlyph
extends Control

## Minimal monoline vector icons drawn on a 24x24 grid, scaled to fit this
## Control's size. Avoids shipping icon image assets for a handful of shapes
## that only ever need to be a single flat color.
enum Kind { HOME, GEAR, FLASK, DIAMOND, SLIDERS, LOCK, CHART, BOLT, DICE, CHIP, CHECK, CLOSE, SPARKLE, COIN, SHIELD }

var kind: int = Kind.HOME
var glyph_color: Color = Color.WHITE
var line_width: float = 1.8

func _init(icon_kind: int = Kind.HOME, color: Color = Color.WHITE, box_size: float = 20.0) -> void:
	kind = icon_kind
	glyph_color = color
	custom_minimum_size = Vector2(box_size, box_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(icon_kind: int, color: Color) -> void:
	kind = icon_kind
	glyph_color = color
	queue_redraw()

func set_glyph_color(color: Color) -> void:
	glyph_color = color
	queue_redraw()

func _draw() -> void:
	var box := minf(size.x, size.y)
	if box <= 0.0:
		return
	var scale := box / 24.0
	var origin := (size - Vector2(box, box)) * 0.5
	var w := line_width * scale
	match kind:
		Kind.HOME:
			_p(origin, scale, Vector2(12, 12), 7.2, w)
			draw_circle(origin + Vector2(12, 12) * scale, 2.3 * scale, glyph_color)
		Kind.GEAR:
			_p(origin, scale, Vector2(12, 12), 3.1, w)
			_p(origin, scale, Vector2(12, 12), 7.6, w)
			for i in range(8):
				var angle: float = i * PI / 4.0
				var dir := Vector2(cos(angle), sin(angle))
				var from: Vector2 = origin + (Vector2(12, 12) + dir * 5.3) * scale
				var to: Vector2 = origin + (Vector2(12, 12) + dir * 7.6) * scale
				draw_line(from, to, glyph_color, w, true)
		Kind.FLASK:
			var body := PackedVector2Array([
				Vector2(10, 3), Vector2(10, 9), Vector2(5, 19), Vector2(19, 19), Vector2(14, 9), Vector2(14, 3)
			])
			_poly(origin, scale, body, w, false)
			_line(origin, scale, Vector2(9, 3), Vector2(15, 3), w)
			_line(origin, scale, Vector2(7.5, 15), Vector2(16.5, 15), w)
		Kind.COIN:
			_p(origin, scale, Vector2(12, 12), 8.2, w)
			_p(origin, scale, Vector2(12, 12), 3.4, w)
		Kind.DIAMOND:
			var outline := PackedVector2Array([
				Vector2(4, 9.5), Vector2(8, 4), Vector2(16, 4), Vector2(20, 9.5), Vector2(12, 21)
			])
			_poly(origin, scale, outline, w, true)
			_line(origin, scale, Vector2(4, 9.5), Vector2(20, 9.5), w)
			_line(origin, scale, Vector2(9, 4), Vector2(12, 21), w)
			_line(origin, scale, Vector2(15, 4), Vector2(12, 21), w)
		Kind.SLIDERS:
			_line(origin, scale, Vector2(4, 8), Vector2(20, 8), w)
			_line(origin, scale, Vector2(4, 16), Vector2(20, 16), w)
			draw_circle(origin + Vector2(9, 8) * scale, 2.4 * scale, glyph_color)
			draw_circle(origin + Vector2(16, 16) * scale, 2.4 * scale, glyph_color)
		Kind.LOCK:
			draw_rect(Rect2(origin + Vector2(6, 10) * scale, Vector2(12, 9) * scale), glyph_color, true)
			draw_arc(origin + Vector2(12, 10) * scale, 4.0 * scale, PI, TAU, 16, glyph_color, w, true)
		Kind.CHART:
			var line := PackedVector2Array([Vector2(3, 17), Vector2(9, 10.5), Vector2(13.5, 14.5), Vector2(21, 5.5)])
			_poly(origin, scale, line, w, false)
			_line(origin, scale, Vector2(14.5, 5.5), Vector2(21, 5.5), w)
			_line(origin, scale, Vector2(21, 5.5), Vector2(21, 12), w)
		Kind.BOLT:
			var bolt := PackedVector2Array([
				Vector2(13, 2), Vector2(4, 14), Vector2(10, 14), Vector2(9, 22), Vector2(18, 10), Vector2(12, 10)
			])
			var scaled := PackedVector2Array()
			for point in bolt:
				scaled.append(origin + point * scale)
			draw_colored_polygon(scaled, glyph_color)
		Kind.DICE:
			draw_rect(Rect2(origin + Vector2(4, 4) * scale, Vector2(16, 16) * scale), glyph_color, false, w)
			for pip in [Vector2(8.3, 8.3), Vector2(15.7, 8.3), Vector2(12, 12), Vector2(8.3, 15.7), Vector2(15.7, 15.7)]:
				draw_circle(origin + pip * scale, 1.1 * scale, glyph_color)
		Kind.CHIP:
			draw_rect(Rect2(origin + Vector2(7, 7) * scale, Vector2(10, 10) * scale), glyph_color, false, w)
			_line(origin, scale, Vector2(12, 2), Vector2(12, 7), w)
			_line(origin, scale, Vector2(12, 17), Vector2(12, 22), w)
			_line(origin, scale, Vector2(2, 12), Vector2(7, 12), w)
			_line(origin, scale, Vector2(17, 12), Vector2(22, 12), w)
		Kind.CHECK:
			var mark := PackedVector2Array([Vector2(4, 12.5), Vector2(9.5, 18), Vector2(20, 5.5)])
			_poly(origin, scale, mark, w * 1.2, false)
		Kind.CLOSE:
			_line(origin, scale, Vector2(5, 5), Vector2(19, 19), w)
			_line(origin, scale, Vector2(19, 5), Vector2(5, 19), w)
		Kind.SHIELD:
			var crest := PackedVector2Array([
				Vector2(12, 2.5), Vector2(20, 6), Vector2(20, 12), Vector2(12, 21.5), Vector2(4, 12), Vector2(4, 6)
			])
			_poly(origin, scale, crest, w, true)
		Kind.SPARKLE:
			# Concave four-point star: the plain diamond read as a sliver at the
			# 15-18px sizes the tabs draw it at.
			var star := PackedVector2Array([
				Vector2(12, 2), Vector2(13.7, 10.3), Vector2(22, 12), Vector2(13.7, 13.7),
				Vector2(12, 22), Vector2(10.3, 13.7), Vector2(2, 12), Vector2(10.3, 10.3)
			])
			var scaled_star := PackedVector2Array()
			for point in star:
				scaled_star.append(origin + point * scale)
			draw_colored_polygon(scaled_star, glyph_color)

func _p(origin: Vector2, scale: float, center: Vector2, radius: float, w: float) -> void:
	draw_arc(origin + center * scale, radius * scale, 0, TAU, 32, glyph_color, w, true)

func _line(origin: Vector2, scale: float, from: Vector2, to: Vector2, w: float) -> void:
	draw_line(origin + from * scale, origin + to * scale, glyph_color, w, true)

func _poly(origin: Vector2, scale: float, points: PackedVector2Array, w: float, closed: bool) -> void:
	var scaled := PackedVector2Array()
	for point in points:
		scaled.append(origin + point * scale)
	if closed and scaled.size() > 0:
		scaled.append(scaled[0])
	draw_polyline(scaled, glyph_color, w, true)
