extends RefCounted
## The look (D049, the main-screen design of D095, premium minimal since D138):
## a near-black ground (D087), Inter for words and numbers alike with every
## digit the same width, one accent for good and one warning for bad, and
## cards that sit on the ground with a soft shadow and a lit top edge.

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
## The Protector is steel, the colour of what it does (D115); the elites are
## The Tower's invaders, each glowing in its own: the Vampire crimson, the
## Ray lemon, the Scatter blue.
const PROTECTOR := Color("8a9bb8")
const VAMPIRE := Color("d0204f")
const RAY := Color("f2ec6b")
const SCATTER := Color("5b7cff")
## The Lock (D133): an emerald =, in the Number's own typeface, since what it
## does is to the Number.
const LOCK := Color("34e3a0")

## Inter, the most neutral face going, with a plain 0 (D138). One file serves
## words and numbers; the two names stay so every caller reads as before.
const WORD_FONT := preload("res://assets/fonts/Inter.ttf")
const NUMBER_FONT := WORD_FONT
## A card's lit top edge, and the shadow it casts on the ground (D138).
const TOP_EDGE := Color(1, 1, 1, 0.09)
const SHADOW := Color(0, 0, 0, 0.45)
## A pressed button sinks to this scale and springs back (D138).
const PRESSED_SCALE := 0.96
## The crowd's typeface, cut by width and weight per enemy type, and the
## Divider's alone (D085). Both are variable fonts under the SIL OFL.
const CROWD_FONT := preload("res://assets/fonts/Anybody.ttf")
const DIVIDER_FONT := preload("res://assets/fonts/Fraunces.ttf")

const SUFFIXES := ["", "K", "M", "B", "T", "q", "Q", "s", "S", "O", "N", "D"]


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = weight(WORD_FONT, 400)
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


## A panel's box: a raised surface lit along its top, casting a soft shadow.
static func panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = SURFACE
	_lift(box, TOP_EDGE)
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


## An upgrade card's box: a quiet surface lit along its top by `edge` (at
## least TOP_EDGE), casting a soft shadow, rather than a web page's outline.
static func card_box(fill: Color = SURFACE, edge: Color = TOP_EDGE, radius: int = 14) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	_lift(box, edge if edge.a >= TOP_EDGE.a else TOP_EDGE)
	box.set_corner_radius_all(radius)
	box.corner_detail = 8
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


## Lifts a box off the ground: a lit top edge only, and a soft shadow below.
static func _lift(box: StyleBoxFlat, edge: Color) -> void:
	box.border_color = edge
	box.border_width_top = 1
	box.shadow_color = SHADOW
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 3)
	box.anti_aliasing = true


## A button sinks a little while held and springs back when let go, so a
## press feels like one (D138). Scaled about its centre, whatever its size.
static func press(button: BaseButton) -> void:
	button.resized.connect(func(): button.pivot_offset = button.size * 0.5)
	button.button_down.connect(func(): _spring(button, PRESSED_SCALE, 0.08))
	button.button_up.connect(func(): _spring(button, 1.0, 0.16))


static func _spring(button: BaseButton, to: float, seconds: float) -> void:
	if not button.is_inside_tree():
		return
	if button.has_meta("spring"):
		(button.get_meta("spring") as Tween).kill()
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * to, seconds) \
			.set_trans(Tween.TRANS_BACK if to == 1.0 else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.set_meta("spring", tween)


## A currency chip: a capsule on the ground holding a glyph and an amount in
## the currency's colour, "● 180" (D138). Returns {panel, label}.
static func chip(colour: Color, font_size: int = 15) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var box := pill_box(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.08), 12)
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.add_theme_font_override("font", weight(NUMBER_FONT, 600))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return {"panel": panel, "label": label}


## A price as a capsule (D142): "● 128", lit in its currency's colour when
## it can be paid and dim when it can't, so what's affordable reads at a
## glance. Returns {panel, label}; style_price_chip lights or dims it.
static func price_chip(font: Font, font_size: int = 13) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return {"panel": panel, "label": label}


static func style_price_chip(chip: Dictionary, lit: bool, colour: Color = COIN) -> void:
	var box := pill_box(Color(colour, 0.14) if lit else Color(1, 1, 1, 0.03), Color(colour, 0.45) if lit else Color(1, 1, 1, 0.06), 10)
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	(chip.panel as PanelContainer).add_theme_stylebox_override("panel", box)
	(chip.label as Label).add_theme_color_override("font_color", colour if lit else MUTED)


## A segmented switch's segment (D142): the chosen one raised on a capsule,
## the others quiet, in place of a web page's underlined tabs.
static func style_segment(button: Button) -> void:
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 34)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	var quiet := pill_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)
	var raised := pill_box(SURFACE_RAISED, TOP_EDGE, 12)
	for state in ["normal", "hover", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, quiet)
	button.add_theme_stylebox_override("pressed", raised)
	button.add_theme_stylebox_override("hover_pressed", raised)
	button.add_theme_color_override("font_color", MUTED)
	button.add_theme_color_override("font_hover_color", SOFT)
	button.add_theme_color_override("font_focus_color", MUTED)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_hover_pressed_color", TEXT)


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
	press(button)
	return button


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


## A screen's card button, with its height chosen by the layout.
static func card_button(height: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	style_card(button)
	press(button)
	return button


## A thin bar along a card's foot, filled towards a price or the next level.
static func progress_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 2)
	bar.max_value = 1.0
	# Exact, not rounded to hundredths.
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.05)
	bar.add_theme_stylebox_override("background", back)
	return bar


## Fills a bar to `share`, dimming the screen's colour unless lit.
static func fill_progress(bar: ProgressBar, share: float, lit: bool, colour: Color) -> void:
	bar.value = share
	var fill := StyleBoxFlat.new()
	fill.bg_color = colour if lit else Color(colour, 0.35)
	bar.add_theme_stylebox_override("fill", fill)


## A thin line across a screen.
static func hairline() -> ColorRect:
	var line := ColorRect.new()
	line.color = HAIRLINE
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


## Cash and Coins side by side as chips, as Home has its currencies (D138):
## "$ 155" in the text's colour, "● 0" in gold. Without Cash (the Workshop)
## it is Coins alone. The callers write each amount with its glyph. Returns
## {line, cash, coins}; the font is the one the amounts are written in.
static func money_line(font: Font, with_cash: bool = true) -> Dictionary:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var cash: Label = null
	if with_cash:
		var cash_chip := chip(TEXT, MONEY_PX - 2)
		cash = cash_chip.label
		cash.add_theme_font_override("font", font)
		line.add_child(cash_chip.panel)
	var coin_chip := chip(COIN, MONEY_PX - 2)
	coin_chip.label.add_theme_font_override("font", font)
	line.add_child(coin_chip.panel)
	return {"line": line, "cash": cash, "coins": coin_chip.label}


## A font at one weight of its variable axis, with every digit the same
## width, so a number changing its digits stays put (D138).
static func weight(base: Font, value: int) -> FontVariation:
	var cut := FontVariation.new()
	cut.base_font = base
	cut.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): value}
	cut.opentype_features = {TextServerManager.get_primary_interface().name_to_tag("tnum"): 1}
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
## (D100, D154): "1,234", "1,234,567", never shortened until FULL_BELOW, a
## trillion, so the digits keep ticking as it grows. Small amounts keep
## `number`'s decimals ("2.35"); past FULL_BELOW it shortens as `number` does.
const FULL_BELOW := 1000000000000.0


static func full(value: float, below := FULL_BELOW) -> String:
	var size := absf(value)
	if size < 1000.0 or size >= below:
		return number(value)
	var digits := "%d" % int(floorf(size))
	var grouped := ""
	while digits.length() > 3:
		grouped = "," + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0.0 else "") + digits + grouped


## Money without a decimal point (D105): Cash and Coins in full with commas,
## rounded down, so it never shows more than there is. A price rounds up
## instead (`up`), so it never looks affordable when it isn't.
static func money(value: float, up := false) -> String:
	return full(ceilf(value - 1e-6) if up else floorf(value + 1e-6))


## An amount of damage, loss or gain without a decimal point (D105): whole,
## in full with commas, rounded to the nearest, but something that happened
## never reads 0.
static func amount(value: float) -> String:
	var whole := roundf(value)
	if whole == 0.0 and value != 0.0:
		whole = signf(value)
	return full(whole)


## A row's value the way The Tower writes it.
static func row_value(id: String, value: float, compact_rates: bool = false) -> String:
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
			if compact_rates and absf(value) >= 1000.0:
				return "%s/s" % number(value)
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
		return symbol + money(next_price, true)
	var cost := symbol + money(float(buying.cost), true)
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
