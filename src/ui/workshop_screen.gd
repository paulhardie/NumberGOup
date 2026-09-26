extends Control
## The Workshop between runs: Attack, Defense and Utility tabs of permanent
## levels bought with Coins. As in The Tower, a tab shows only the next group
## it opens, as one big Unlock card, never the ones after it. The rules are
## the Workshop's; this only shows and asks.

const TowerData = preload("res://src/tower/tower_data.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const Palette = preload("res://src/ui/palette.gd")

## A purchase or an opened group, so the game can save.
signal changed
signal home_pressed

const TABS := [["Attack", "attack"], ["Defense", "defense"], ["Utility", "utility"]]
## The buy multiplier's steps; 0 is Max. Presentation only, never saved (D018).
const AMOUNTS := [1, 5, 10, 0]

var workshop: Workshop
var _tab := "attack"
var _tab_buttons: Dictionary = {}
var _amount := 1
var _amount_button: Button
var _coins: Label
var _list: VBoxContainer
## Refreshed every frame: [{button, refresh: Callable}].
var _cards: Array[Dictionary] = []


func _ready() -> void:
	theme = Palette.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var home := Button.new()
	home.text = "Home"
	home.pressed.connect(func(): home_pressed.emit())
	header.add_child(home)
	var title := Label.new()
	title.text = "Workshop"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_coins = Label.new()
	_coins.add_theme_font_override("font", Palette.NUMBER_FONT)
	_coins.add_theme_font_size_override("font_size", 18)
	_coins.add_theme_color_override("font_color", Palette.COIN)
	header.add_child(_coins)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	column.add_child(tabs)
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
	_amount_button.pressed.connect(_next_amount)
	tabs.add_child(_amount_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	show_tab(_tab)


func _process(_delta: float) -> void:
	refresh()


func show_tab(tab: String) -> void:
	_tab = tab
	for id in _tab_buttons:
		_tab_buttons[id].set_pressed_no_signal(id == tab)
	for child in _list.get_children():
		child.queue_free()
	_cards.clear()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_list.add_child(grid)
	for group in TowerData.groups():
		var id := String(group.id)
		if String(group.workshop_category) == tab and workshop.is_group_open(id):
			for row in TowerData.group_rows(id):
				grid.add_child(_row_card(row))
	var next := workshop.next_group(tab)
	if next != "":
		_list.add_child(_unlock_card(next))
	refresh()


func _next_amount() -> void:
	_amount = AMOUNTS[(AMOUNTS.find(_amount) + 1) % AMOUNTS.size()]
	refresh()


func refresh() -> void:
	_coins.text = "● " + Palette.number(workshop.coins)
	_amount_button.text = "Buy Max" if _amount == 0 else "Buy ×%d" % _amount
	for card in _cards:
		card.refresh.call()


## One row: its value, its level and the Coins the multiplier's press costs.
func _row_card(id: String) -> Button:
	var button := _card_button()
	var parts := _card_parts(button, String(TowerData.upgrade(id).title).capitalize())
	button.pressed.connect(func():
		if workshop.buy(id, _amount):
			changed.emit()
		refresh())
	_cards.append({"button": button, "refresh": func():
		var maxed := workshop.level(id) >= TowerData.max_level(id)
		var affordable := workshop.can_buy(id, _amount)
		parts.value.text = Palette.row_value(id, TowerData.value(id, workshop.level(id)))
		parts.detail.text = "Lv %d · %s" % [workshop.level(id), "MAX" if maxed else Palette.quote(workshop.plan(id, _amount), workshop.price(id), "● ")]
		button.disabled = not affordable
		parts.detail.add_theme_color_override("font_color", Palette.COIN if affordable else Palette.MUTED)})
	return button


## The tab's next group, The Tower's big Unlock card: what it opens and its
## Coins. The groups after it stay hidden until it is open.
func _unlock_card(group: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	var names: Array[String] = []
	for row in TowerData.group_rows(group):
		names.append(String(TowerData.upgrade(row).title).capitalize())
	var opens := Label.new()
	opens.text = " · ".join(names)
	opens.add_theme_color_override("font_color", Palette.MUTED)
	opens.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opens.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(opens)
	var unlock := Label.new()
	unlock.add_theme_font_override("font", Palette.NUMBER_FONT)
	unlock.add_theme_font_size_override("font_size", 22)
	unlock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unlock.text = "Unlock  ● " + Palette.number(TowerData.group_price(group))
	column.add_child(unlock)
	button.pressed.connect(func():
		if workshop.open_group(group):
			changed.emit()
			show_tab(_tab))
	_cards.append({"button": button, "refresh": func():
		button.disabled = not workshop.can_open(group)
		unlock.add_theme_color_override("font_color", Palette.COIN if workshop.can_open(group) else Palette.MUTED)})
	return button


func _card_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 62)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


## Lays out a card's name on the left and its two numbers on the right.
func _card_parts(button: Button, title: String) -> Dictionary:
	var line := HBoxContainer.new()
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 12
	line.offset_right = -12
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(line)
	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(name_label)
	var numbers := VBoxContainer.new()
	numbers.alignment = BoxContainer.ALIGNMENT_CENTER
	numbers.add_theme_constant_override("separation", 0)
	numbers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(numbers)
	var value := _number_label(15, Palette.TEXT)
	var detail := _number_label(12, Palette.MUTED)
	numbers.add_child(value)
	numbers.add_child(detail)
	return {"value": value, "detail": detail}


func _number_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", Palette.NUMBER_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
