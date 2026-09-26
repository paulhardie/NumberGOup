extends Control
## The Workshop between runs: Attack, Defense and Utility tabs of permanent
## levels bought with Coins, and the next group of rows each tab opens, in The
## Tower's order. The rules are the Workshop's; this only shows and asks.

const TowerData = preload("res://src/tower/tower_data.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const Palette = preload("res://src/ui/palette.gd")

## A purchase or an opened group, so the game can save.
signal changed
signal home_pressed

const TABS := [["Attack", "attack"], ["Defense", "defense"], ["Utility", "utility"]]

var workshop: Workshop
var _tab := "attack"
var _tab_buttons: Dictionary = {}
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
	var grid: GridContainer = null
	for group in TowerData.groups():
		var id := String(group.id)
		if String(group.workshop_category) != tab:
			continue
		if workshop.is_group_open(id):
			if grid == null:
				grid = GridContainer.new()
				grid.columns = 2
				grid.add_theme_constant_override("h_separation", 8)
				grid.add_theme_constant_override("v_separation", 8)
				_list.add_child(grid)
			for row in TowerData.group_rows(id):
				grid.add_child(_row_card(row))
		else:
			_list.add_child(_group_card(id))
	refresh()


func refresh() -> void:
	_coins.text = "● " + Palette.number(workshop.coins)
	for card in _cards:
		card.refresh.call()


## One row: its value, its level and the Coins for the next level.
func _row_card(id: String) -> Button:
	var button := _card_button()
	var parts := _card_parts(button, String(TowerData.upgrade(id).title).capitalize())
	button.pressed.connect(func():
		if workshop.buy(id):
			changed.emit()
		refresh())
	_cards.append({"button": button, "refresh": func():
		var maxed := workshop.level(id) >= TowerData.max_level(id)
		parts.value.text = Palette.row_value(id, TowerData.value(id, workshop.level(id)))
		parts.detail.text = "Lv %d · %s" % [workshop.level(id), "MAX" if maxed else "● " + Palette.number(workshop.price(id))]
		button.disabled = not workshop.can_buy(id)
		parts.detail.add_theme_color_override("font_color", Palette.COIN if workshop.can_buy(id) else Palette.MUTED)})
	return button


## A group not yet open: the next in line can be opened for its Coins; the
## ones after it wait their turn, and groups the battle can't use yet say so.
func _group_card(group: String) -> Button:
	var button := _card_button()
	var names: Array[String] = []
	for row in TowerData.group_rows(group):
		names.append(String(TowerData.upgrade(row).title).capitalize())
	var parts := _card_parts(button, " · ".join(names))
	button.pressed.connect(func():
		if workshop.open_group(group):
			changed.emit()
			show_tab(_tab))
	_cards.append({"button": button, "refresh": func():
		var built: bool = group in Workshop.BUILT_GROUPS
		var next := workshop.next_group(TowerData.group_category(group)) == group
		parts.value.text = "● " + Palette.number(TowerData.group_price(group))
		parts.detail.text = "Open" if built and next else ("Coming soon" if not built else "Opens after the one above")
		button.disabled = not workshop.can_open(group)
		parts.value.add_theme_color_override("font_color", Palette.COIN if workshop.can_open(group) else Palette.MUTED)})
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
