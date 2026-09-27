extends RefCounted
## The look (D049, the main-screen design of D095): a near-black ground (D087), Geist for
## words and Geist Mono for numbers, one accent for good and one warning for
## bad, hairlines and quiet cards.

const TowerData = preload("res://src/tower/tower_data.gd")

## Black, a breath off pure (the owner's main-screen design), so the light
## behind the Number reads as light and the cards read against it.
const GROUND := Color("0a0a0b")
const SURFACE := Color("141416")
const SURFACE_RAISED := Color("1c1d20")
const LINE := Color("2a2b2f")
## Dividing lines and card edges: white, faint.
const HAIRLINE := Color(1, 1, 1, 0.08)
const CARD_EDGE := Color(1, 1, 1, 0.05)
const TEXT := Color("ededed")
## Secondary words on buttons (End run, the buy multiplier).
const SOFT := Color("a8a8a8")
## The light behind the Number: the design's warm white (D096).
const LIGHT := Color("fff4e6")
## The Number in the centre is white, always (D087).
const NUMBER := Color("ffffff")
const MUTED := Color("8c8c8c")
const ACCENT := Color("9cc5ae")
const WARNING := Color("d68e5c")
## What a hit takes from the Number, floating beside it.
const HIT := Color("e08a7a")
const COIN := Color("d4b25c")
## Cash and Coins in a top bar share this size, so they read as a pair.
const MONEY_PX := 18
## Each enemy type's colour (D085): one hue apiece, spread in lightness too so
## they stay apart for colour-blind players. None is the player's mint, gold
## or orange. ENEMY is the basic enemy's red.
const ENEMY := Color("e0625a")
const FAST := Color("4dd6e8")
const TANK := Color("ff7ac0")
const RANGED := Color("c8e05a")
## The boss is the crowd's red burnt white: a white-hot number in a red glow.
const BOSS := Color("fff0ea")
const BOSS_GLOW := Color("ff4a3d")
## The Divider (D082): its own colour, so a ÷ reads apart from the enemies
## that subtract.
const DIVIDER := Color("b48cf2")
## The Multiplier (D097), the Divider's mirror: a bright mint, the player's
## colour for good, lifted clear of the shots' softer mint.
const MULTIPLIER := Color("a8f0c6")

const WORD_FONT := preload("res://assets/fonts/Geist.ttf")
const NUMBER_FONT := preload("res://assets/fonts/GeistMono.ttf")
## The crowd's typeface, cut by width and weight per enemy type, and the
## Divider's alone (D085). Both are variable fonts under the SIL OFL.
const CROWD_FONT := preload("res://assets/fonts/Anybody.ttf")
const DIVIDER_FONT := preload("res://assets/fonts/Fraunces.ttf")

const SUFFIXES := ["", "K", "M", "B", "T", "q", "Q", "s", "S", "O", "N", "D"]


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = WORD_FONT
	theme.default_font_size = 14
	theme.set_color("font_color", "Label", TEXT)
	# A plain button is a quiet card, as the design's are (D095).
	theme.set_stylebox("normal", "Button", card_box(SURFACE, CARD_EDGE, 12))
	theme.set_stylebox("hover", "Button", card_box(SURFACE, Color(1, 1, 1, 0.12), 12))
	theme.set_stylebox("pressed", "Button", card_box(Color("101012"), Color(1, 1, 1, 0.12), 12))
	theme.set_stylebox("disabled", "Button", card_box(SURFACE, CARD_EDGE, 12))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", TEXT)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_color("font_disabled_color", "Button", MUTED)
	return theme


## A panel's box: raised surface, a hairline border.
static func panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = SURFACE
	box.border_color = CARD_EDGE
	box.set_border_width_all(1)
	box.set_corner_radius_all(14)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


## A pill button's box: rounded right off, a hairline edge or a faint fill.
static func pill_box(fill: Color, edge: Color, pad: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(1 if edge.a > 0.0 else 0)
	box.set_corner_radius_all(999)
	box.content_margin_left = pad
	box.content_margin_right = pad
	box.corner_detail = 12
	box.anti_aliasing = true
	return box


## An upgrade card's box: a quiet surface with a faint edge.
static func card_box(fill: Color = SURFACE, edge: Color = CARD_EDGE, radius: int = 14) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.corner_detail = 8
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


## A pill button: a hairline edge on the ground, as the design's top corner has.
static func pill(text: String, colour: Color, font: Font = null, height: int = 36) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 13)
	if font != null:
		button.add_theme_font_override("font", font)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var edge := Color(1, 1, 1, 0.24 if state == "hover" else 0.12)
		button.add_theme_stylebox_override(state, pill_box(Color(1, 1, 1, 0.05) if state == "pressed" else Color(0, 0, 0, 0), edge, 14))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, colour)
	button.add_theme_color_override("font_disabled_color", Color(colour, 0.4))
	return button


## A tab: a word, underlined in the accent when chosen.
static func style_tab(button: Button) -> void:
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 14)
	for state in ["normal", "hover", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, _underline(Color(0, 0, 0, 0)))
	button.add_theme_stylebox_override("pressed", _underline(ACCENT))
	button.add_theme_stylebox_override("hover_pressed", _underline(ACCENT))
	button.add_theme_color_override("font_color", MUTED)
	button.add_theme_color_override("font_hover_color", SOFT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_hover_pressed_color", TEXT)
	button.add_theme_color_override("font_focus_color", MUTED)


static func _underline(colour: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = colour
	box.border_width_bottom = 2
	return box


## The buy multiplier: a quiet filled pill, "buy ×1".
static func amount_pill(font: Font) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 30)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 12)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, pill_box(Color(1, 1, 1, 0.09 if state == "hover" else 0.05), Color(0, 0, 0, 0), 12))
	for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(colour, SOFT)
	return button


## An upgrade card's looks, for each of its states.
static func style_card(button: Button) -> void:
	button.add_theme_stylebox_override("normal", card_box())
	button.add_theme_stylebox_override("disabled", card_box())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", card_box(SURFACE, Color(1, 1, 1, 0.12)))
	button.add_theme_stylebox_override("pressed", card_box(Color("101012"), Color(1, 1, 1, 0.12)))


## A thin line across a screen.
static func hairline() -> ColorRect:
	var line := ColorRect.new()
	line.color = HAIRLINE
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


## Cash and Coins side by side at one size, as a top bar has them: a muted
## "$" before Cash, a gold dot before Coins. Without Cash (Home, the Workshop)
## it is Coins alone. Returns {line, cash, coins}.
static func money_line(font: Font, with_cash: bool = true) -> Dictionary:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 18)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cash: Label = null
	if with_cash:
		var cash_part := HBoxContainer.new()
		cash_part.add_theme_constant_override("separation", 6)
		line.add_child(cash_part)
		cash_part.add_child(_money_label(font, MUTED, "$"))
		cash = _money_label(font, TEXT, "0")
		cash_part.add_child(cash)
	var coin_part := HBoxContainer.new()
	coin_part.add_theme_constant_override("separation", 8)
	line.add_child(coin_part)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(7, 7)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.add_theme_stylebox_override("panel", pill_box(COIN, Color(0, 0, 0, 0), 0))
	coin_part.add_child(dot)
	var coins := _money_label(font, COIN, "0")
	coin_part.add_child(coins)
	return {"line": line, "cash": cash, "coins": coins}


static func _money_label(font: Font, colour: Color, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", MONEY_PX)
	label.add_theme_color_override("font_color", colour)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


## A font at one weight of its variable axis.
static func weight(base: Font, value: int) -> FontVariation:
	var cut := FontVariation.new()
	cut.base_font = base
	cut.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): value}
	return cut


## A row's title in sentence case, "Damage / meter", as the main screen writes it.
static func row_title(id: String) -> String:
	var title := String(TowerData.upgrade(id).title).to_lower()
	return title.left(1).to_upper() + title.substr(1)


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


## The Number, and what's added to it or taken from it, written out in full
## (D100): "1,234", "999,999", never shortened to "1.23K" until FULL_BELOW,
## so watching it grow feels like the number going up. Small amounts keep
## `number`'s decimals ("2.35"); past FULL_BELOW it shortens as `number` does.
const FULL_BELOW := 1000000.0


static func full(value: float) -> String:
	var size := absf(value)
	if size < 1000.0 or size >= FULL_BELOW:
		return number(value)
	var digits := "%d" % int(floorf(size))
	var grouped := ""
	while digits.length() > 3:
		grouped = "," + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0.0 else "") + digits + grouped


## An enemy's numbers, kept short for a crowd (D085): one decimal under 10
## ("1.6", "4"), whole from there ("14"), then as `number` writes them ("1.08K").
static func short(value: float) -> String:
	if absf(value) >= 1000.0:
		return number(value)
	if absf(value) >= 9.95:
		return "%d" % int(roundf(value))
	return String.num(snappedf(value, 0.1), 1).trim_suffix(".0")


## An enemy's health as it shows: `short`, but rounded up while small, so a
## living enemy never reads 0.
static func enemy_health(value: float) -> String:
	if value <= 0.0:
		return "0"
	return short(ceilf(value * 10.0 - 1e-6) / 10.0) if value < 9.95 else short(value)


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
		"seconds":
			return "%.2fs" % value
	return number(value)


## What a multi-buy press buys and costs, after `symbol`: "+3 $539" when it
## lands more than one level, a bare price for one. A Max that can't afford a
## level quotes the next one's price.
static func quote(buying: Dictionary, next_price: float, symbol: String) -> String:
	var bought := int(buying.levels)
	if bought == 0:
		return symbol + number(next_price)
	var cost := symbol + number(float(buying.cost))
	return cost if bought == 1 else "+%d %s" % [bought, cost]


## The Number as it's shown, the same in the centre and the panel: whole, as
## The Tower shows Health; a standing tower never reads 0, and full health
## never reads more than the most, unless a package has healed it past.
static func number_shown(now: float, most: float, standing: bool) -> float:
	var shown := roundf(now) if now > most else minf(roundf(now), roundf(most))
	return maxf(shown, 1.0) if standing else maxf(shown, 0.0)


static func clock(seconds: float) -> String:
	var whole := int(seconds)
	if whole >= 3600:
		return "%d:%02d:%02d" % [whole / 3600, (whole / 60) % 60, whole % 60]
	return "%d:%02d" % [whole / 60, whole % 60]
