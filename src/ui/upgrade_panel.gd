extends VBoxContainer
## The run's upgrades: Attack, Defense and Utility tabs of the rows this run
## may buy, each a card with its value and the Cash the buy multiplier's press
## costs (×1, ×5, ×10 or Max, D018). It
## asks BattleSim what can be bought and what it costs; it decides nothing.
## As The Tower's, tapping the tab that's already open folds the cards away,
## so the battle takes the screen, and tapping any tab brings them back
## (D129).

const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")

const TABS := [["Attack", "attack"], ["Defense", "defense"], ["Utility", "utility"]]
const CARD_HEIGHT := 76
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
	# The tabs are words underlined when chosen, with the buy multiplier as a
	# pill at the far end.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 22)
	add_child(tabs)
	for tab in TABS:
		var button := Button.new()
		button.text = tab[0]
		Palette.style_tab(button)
		button.pressed.connect(_tab_pressed.bind(tab[1]))
		tabs.add_child(button)
		_tab_buttons[tab[1]] = button
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(gap)
	_amount_button = Palette.amount_pill(_mono)
	_amount_button.text = "buy ×1"
	_amount_button.pressed.connect(func():
		_amount = AMOUNTS[(AMOUNTS.find(_amount) + 1) % AMOUNTS.size()]
		_amount_button.text = "buy max" if _amount == 0 else "buy ×%d" % _amount
		refresh())
	tabs.add_child(_amount_button)
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
	_empty.text = "Cash upgrades open in the Workshop."
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
		if TowerData.category(id) == tab and sim.is_open(id):
			_grid.add_child(_card(id))
	_empty.visible = _cards.is_empty() and not collapsed
	refresh()


func refresh() -> void:
	for id in _cards:
		var card: Dictionary = _cards[id]
		card.value.text = Palette.row_value(id, sim.stat(id))
		card.price.text = "MAX" if sim.at_max(id) else Palette.quote(sim.plan(id, _amount), sim.price(id), "$")
		var affordable := sim.can_buy(id, _amount)
		card.button.disabled = not affordable
		card.price.add_theme_color_override("font_color", Palette.ACCENT if affordable else Palette.MUTED)


## A card: the row's name small at the top, its value large at the bottom
## left and the Cash the press costs at the bottom right.
func _card(id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Palette.style_card(button)
	button.pressed.connect(func():
		sim.buy(id, _amount)
		refresh())
	var inside := VBoxContainer.new()
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = 14
	inside.offset_right = -14
	inside.offset_top = 12
	inside.offset_bottom = -12
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inside)
	var title := Label.new()
	title.text = Palette.row_title(id)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Palette.MUTED)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(title)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(line)
	var value := _number_label(18, Palette.TEXT)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var price := _number_label(12, Palette.ACCENT)
	line.add_child(value)
	line.add_child(price)
	_cards[id] = {"button": button, "value": value, "price": price}
	return button


func _number_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", _mono)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
