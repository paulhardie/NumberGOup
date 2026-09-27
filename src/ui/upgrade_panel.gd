extends VBoxContainer
## The run's upgrades: Attack, Defense and Utility tabs of the rows this run
## may buy, each a card with its value and the Cash the buy multiplier's press
## costs (×1, ×5, ×10 or Max, D018). It
## asks BattleSim what can be bought and what it costs; it decides nothing.

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
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 14)
		for state in ["normal", "hover", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, _underline(Color(0, 0, 0, 0)))
		button.add_theme_stylebox_override("pressed", _underline(Palette.ACCENT))
		button.add_theme_stylebox_override("hover_pressed", _underline(Palette.ACCENT))
		button.add_theme_color_override("font_color", Palette.MUTED)
		button.add_theme_color_override("font_hover_color", Palette.SOFT)
		button.add_theme_color_override("font_pressed_color", Palette.TEXT)
		button.add_theme_color_override("font_hover_pressed_color", Palette.TEXT)
		button.add_theme_color_override("font_focus_color", Palette.MUTED)
		button.pressed.connect(show_tab.bind(tab[1]))
		tabs.add_child(button)
		_tab_buttons[tab[1]] = button
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(gap)
	_amount_button = Button.new()
	_amount_button.custom_minimum_size = Vector2(0, 30)
	_amount_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_amount_button.add_theme_font_override("font", _mono)
	_amount_button.add_theme_font_size_override("font_size", 12)
	for state in ["normal", "hover", "pressed", "focus"]:
		_amount_button.add_theme_stylebox_override(state, Palette.pill_box(Color(1, 1, 1, 0.09 if state == "hover" else 0.05), Color(0, 0, 0, 0), 12))
	for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_amount_button.add_theme_color_override(colour, Palette.SOFT)
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


func show_tab(tab: String) -> void:
	_tab = tab
	# While a saved run is being resumed there is no run to show yet.
	if sim == null:
		return
	for id in _tab_buttons:
		_tab_buttons[id].set_pressed_no_signal(id == tab)
	for child in _grid.get_children():
		child.queue_free()
	_cards.clear()
	for id in TowerData.rows():
		if TowerData.category(id) == tab and sim.is_open(id):
			_grid.add_child(_card(id))
	_empty.visible = _cards.is_empty()
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
	button.add_theme_stylebox_override("normal", Palette.card_box())
	button.add_theme_stylebox_override("disabled", Palette.card_box())
	button.add_theme_stylebox_override("focus", Palette.card_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	button.add_theme_stylebox_override("hover", Palette.card_box(Palette.SURFACE, Color(1, 1, 1, 0.12)))
	button.add_theme_stylebox_override("pressed", Palette.card_box(Color("101012"), Color(1, 1, 1, 0.12)))
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


## A tab's box: nothing but a line under it, in `colour`.
static func _underline(colour: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = colour
	box.border_width_bottom = 2
	box.content_margin_left = 0
	box.content_margin_right = 0
	return box


func _number_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", _mono)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
