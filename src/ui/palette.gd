extends RefCounted
## The look (D049): a near-black ground, Geist for words and Geist Mono for
## numbers, one accent for good and one warning for bad.

const TowerData = preload("res://src/tower/tower_data.gd")

const GROUND := Color("111213")
const SURFACE := Color("17181a")
const SURFACE_RAISED := Color("1c1d20")
const LINE := Color("2a2b2f")
const TEXT := Color("ececea")
const MUTED := Color("8b8c88")
const ACCENT := Color("8fbfa8")
const WARNING := Color("d68e5c")
const COIN := Color("d4b04e")
const ENEMY := Color("e0625a")
const BOSS := Color("ff4a3d")

const WORD_FONT := preload("res://assets/fonts/Geist.ttf")
const NUMBER_FONT := preload("res://assets/fonts/GeistMono.ttf")

const SUFFIXES := ["", "K", "M", "B", "T", "q", "Q", "s", "S", "O", "N", "D"]


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = WORD_FONT
	theme.default_font_size = 14
	theme.set_color("font_color", "Label", TEXT)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = SURFACE_RAISED if state != "pressed" else SURFACE
		box.border_color = ACCENT if state == "focus" else LINE
		box.set_border_width_all(1)
		box.set_corner_radius_all(6)
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		theme.set_stylebox(state, "Button", box)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	return theme


## A panel's box: raised surface, a hairline border.
static func panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = SURFACE
	box.border_color = LINE
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


## The Tower's way of writing numbers: two decimals while small, whole past
## 100, then K, M, B and on.
static func number(value: float) -> String:
	var size := absf(value)
	if size < 100.0:
		return "%.2f" % value if not is_equal_approx(value, roundf(value)) else "%d" % int(roundf(value))
	if size < 1000.0:
		return "%d" % int(floorf(value))
	var tier := mini(int(floorf(log(size) / log(1000.0))), SUFFIXES.size() - 1)
	return "%.2f%s" % [value / pow(1000.0, tier), SUFFIXES[tier]]


## A row's value the way The Tower writes it.
static func row_value(id: String, value: float) -> String:
	match id:
		"attack_speed":
			return "%.2f" % value
		"damage", "health":
			# The Tower shows the tower's own Damage and Health whole.
			return number(roundf(value))
	match String(TowerData.upgrade(id).unit):
		"percent":
			return "%.2f%%" % (value * 100.0)
		"multiplier":
			return "×%.2f" % value
		"per_second":
			return "%.2f/s" % value
		"metres":
			return "%s m" % number(value)
		"per_metre":
			return "%.2f%%/m" % (value * 100.0)
	return number(value)


static func clock(seconds: float) -> String:
	var whole := int(seconds)
	if whole >= 3600:
		return "%d:%02d:%02d" % [whole / 3600, (whole / 60) % 60, whole % 60]
	return "%d:%02d" % [whole / 60, whole % 60]
