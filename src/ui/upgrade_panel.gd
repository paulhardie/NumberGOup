extends VBoxContainer
## The run's upgrades: Attack, Defense and Utility of the rows this run may
## buy, two to a row (D143), each a tile with its value and a price chip lit
## in the accent when the buy multiplier's press (×1, ×5, ×10 or Max, D018)
## can be paid, over a bar filling as the Cash comes towards it. A segmented
## switch picks the category. It asks BattleSim what can be bought and what it
## costs; it decides nothing. As The Tower's, tapping the chosen category again
## folds the tiles away, so the battle takes the screen, and tapping any
## category brings them back (D129). Holding a tile asks the screen to read
## it (D151) instead of buying it.

const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")
const HoldToRead = preload("res://src/ui/hold_to_read.gd")

## A tile was held: show what `id` does.
signal info_requested(id: String)

const TABS := [["Attack", "attack"], ["Defense", "defense"], ["Utility", "utility"]]
const CARD_HEIGHT := 74
const CARD_GAP := 8
const ROWS_SHOWN := 3
## The buy multiplier's steps; 0 is Max. Presentation only, never saved.
const AMOUNTS := [1, 5, 10, 0]

var sim: BattleSim
var _tab := "attack"
## Whether the cards are folded away (D129); the tabs stay to bring them back.
var collapsed := false
var _scroll: ScrollContainer
var _tab_buttons: Dictionary = {}
var _amount := 1
var _amount_button: Button
var _grid: GridContainer
var _empty: Label
## Row id → {button, value, price}, for the cards on the current tab.
var _cards: Dictionary = {}
var _mono := Palette.weight(Palette.NUMBER_FONT, 400)


func _init() -> void:
	add_theme_constant_override("separation", 14)
	# A segmented switch for the category, as the Workshop's (D142), with the
	# buy multiplier as a pill beside it.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	add_child(head)
	var switch := PanelContainer.new()
	switch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var track := Palette.pill_box(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.05), 3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	switch.add_theme_stylebox_override("panel", track)
	head.add_child(switch)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	switch.add_child(tabs)
	for tab in TABS:
		var button := Button.new()
		button.text = tab[0]
		Palette.style_segment(button)
		button.pressed.connect(_tab_pressed.bind(tab[1]))
		tabs.add_child(button)
		_tab_buttons[tab[1]] = button
	_amount_button = Palette.amount_pill(_mono)
	Palette.press(_amount_button)
	_amount_button.text = "buy ×1"
	_amount_button.pressed.connect(func():
		_amount = AMOUNTS[(AMOUNTS.find(_amount) + 1) % AMOUNTS.size()]
		_amount_button.text = "buy max" if _amount == 0 else "buy ×%d" % _amount
		refresh())
	head.add_child(_amount_button)
	# A fixed height that scrolls, so a tab with many rows never pushes the
	# arena off the screen: three rows of cards show at once.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, ROWS_SHOWN * CARD_HEIGHT + (ROWS_SHOWN - 1) * CARD_GAP)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_scroll = scroll
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", CARD_GAP)
	_grid.add_theme_constant_override("v_separation", CARD_GAP)
	scroll.add_child(_grid)
	_empty = Label.new()
	_empty.text = "Run upgrades open in the Workshop."
	_empty.add_theme_color_override("font_color", Palette.MUTED)
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_empty)


func set_sim(run: BattleSim) -> void:
	sim = run
	show_tab(_tab)


## The open tab tapped again folds the cards away; any tab tapped while
## they're folded, or another tab, opens it.
func _tab_pressed(tab: String) -> void:
	if tab == _tab and not collapsed:
		set_collapsed(true)
	else:
		set_collapsed(false)
		show_tab(tab)


func set_collapsed(folded: bool) -> void:
	collapsed = folded
	_scroll.visible = not folded
	_empty.visible = not folded and _cards.is_empty() and sim != null
	for id in _tab_buttons:
		_tab_buttons[id].set_pressed_no_signal(id == _tab and not folded)


func show_tab(tab: String) -> void:
	_tab = tab
	# While a saved run is being resumed there is no run to show yet.
	if sim == null:
		return
	for id in _tab_buttons:
		_tab_buttons[id].set_pressed_no_signal(id == tab and not collapsed)
	for child in _grid.get_children():
		child.queue_free()
	_cards.clear()
	for id in TowerData.rows():
		if TowerData.category(id) == tab and sim.is_open(id) and sim.in_shop(id):
			_grid.add_child(_card(id))
	_empty.text = "Run upgrades are off this run." if sim.upgrades_off else "Run upgrades open in the Workshop."
	_empty.visible = _cards.is_empty() and not collapsed
	refresh()


func refresh() -> void:
	for id in _cards:
		var card: Dictionary = _cards[id]
		var maxed := sim.at_max(id)
		card.value.text = Palette.row_value(id, sim.stat(id))
		card.price.text = "MAX" if maxed else Palette.quote(sim.plan(id, _amount), sim.price(id), price_symbol(sim))
		var affordable := sim.can_buy(id, _amount)
		card.button.disabled = not affordable
		Palette.style_price_chip(card.chip, affordable, Palette.ACCENT)
		card.bar.value = 1.0 if maxed else toward(sim.spendable(), _target(id))
		(card.bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Palette.ACCENT if affordable or maxed else Color(Palette.ACCENT, 0.35)


## What a price is written with: "$" for Cash, or "−" with the Number as Cash
## (D156), since a purchase takes that much off the Number.
static func price_symbol(battle: BattleSim) -> String:
	return "−" if battle.number_cash else "$"


## The Cash the multiplier's press on `id` costs now, or the next level's
## price when it can't be planned.
func _target(id: String) -> float:
	var buying := sim.plan(id, _amount)
	return float(buying.cost) if int(buying.levels) > 0 else sim.price(id)


## How far `cash` has come towards `target`, 0 to 1.
static func toward(cash: float, target: float) -> float:
	if target <= 0.0:
		return 1.0
	if not is_finite(target):
		return 0.0
	return clampf(cash / target, 0.0, 1.0)


## A tile (D143): the row's name small at the top, its value large at the
## bottom left with the price chip at the bottom right, and a thin bar along
## the foot filling towards the price. A buy pops the value.
func _card(id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	Palette.style_card(button)
	Palette.press(button)
	var inside := VBoxContainer.new()
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = 14
	inside.offset_right = -12
	inside.offset_top = 10
	inside.offset_bottom = -8
	inside.add_theme_constant_override("separation", 5)
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inside)
	var title := Label.new()
	title.text = Palette.row_title(id)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Palette.SOFT)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(title)
	var line := HBoxContainer.new()
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(line)
	var value := _number_label(18, Palette.TEXT)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(value)
	var chip := Palette.price_chip(Palette.weight(Palette.NUMBER_FONT, 600), 12)
	line.add_child(chip.panel)
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
	bar.add_theme_stylebox_override("fill", StyleBoxFlat.new())
	inside.add_child(bar)
	HoldToRead.attach(button, func(): info_requested.emit(id), func():
		if sim.buy(id, _amount):
			_pop(value)
		refresh())
	_cards[id] = {"button": button, "value": value, "price": chip.label, "chip": chip, "bar": bar}
	return button


## A value that just went up springs a little, so a buy is felt.
func _pop(label: Label) -> void:
	if not label.is_inside_tree():
		return
	label.pivot_offset = label.size * 0.5
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * 1.08, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _number_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", _mono)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
