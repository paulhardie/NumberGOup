extends VBoxContainer
## The run's upgrades: Attack, Defense and Utility tabs of the rows this run
## may buy, each a card with its value and the Cash the buy multiplier's press
## costs (×1, ×5, ×10 or Max, D018). It
## asks BattleSim what can be bought and what it costs; it decides nothing.

const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")

const TABS := [["Attack", "attack"], ["Defense", "defense"], ["Utility", "utility"]]
const CARD_HEIGHT := 58
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


func _init() -> void:
	add_theme_constant_override("separation", 8)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	add_child(tabs)
	for tab in TABS:
		var button := Button.new()
		button.text = tab[0]
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(show_tab.bind(tab[1]))
		tabs.add_child(button)
		_tab_buttons[tab[1]] = button
	_amount_button = Button.new()
	_amount_button.custom_minimum_size = Vector2(88, 0)
	_amount_button.add_theme_font_override("font", Palette.NUMBER_FONT)
	_amount_button.text = "Buy ×1"
	_amount_button.pressed.connect(func():
		_amount = AMOUNTS[(AMOUNTS.find(_amount) + 1) % AMOUNTS.size()]
		_amount_button.text = "Buy Max" if _amount == 0 else "Buy ×%d" % _amount
		refresh())
	tabs.add_child(_amount_button)
	# A fixed height that scrolls, so a tab with many rows never pushes the
	# arena off the screen: three rows of cards show at once.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, ROWS_SHOWN * CARD_HEIGHT + (ROWS_SHOWN - 1) * 8)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
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


func _card(id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func():
		sim.buy(id, _amount)
		refresh())
	var line := HBoxContainer.new()
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 12
	line.offset_right = -12
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(line)
	var title := Label.new()
	title.text = String(TowerData.upgrade(id).title).capitalize()
	title.add_theme_font_size_override("font_size", 13)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(title)
	var numbers := VBoxContainer.new()
	numbers.alignment = BoxContainer.ALIGNMENT_CENTER
	numbers.add_theme_constant_override("separation", 0)
	numbers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(numbers)
	var value := _number_label(15, Palette.TEXT)
	var price := _number_label(13, Palette.ACCENT)
	numbers.add_child(value)
	numbers.add_child(price)
	_cards[id] = {"button": button, "value": value, "price": price}
	return button


func _number_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", Palette.NUMBER_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
