extends Control
## The Workshop between runs: Attack, Defense and Utility tabs of permanent
## levels bought with Coins. As in The Tower, a tab shows only the next group
## it opens, as one big Unlock card, never the ones after it. The rules are
## the Workshop's; this only shows and asks. It wears the main screen's look
## (D095, D096): Coins over a title, underlined tabs, quiet cards, and the bar
## back to Home along the bottom. Opening a group says what its rows do, as
## The Tower's info popups do when an upgrade unlocks (D125).

const TowerData = preload("res://src/tower/tower_data.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const Palette = preload("res://src/ui/palette.gd")
const NavBar = preload("res://src/ui/nav_bar.gd")
const Progression = preload("res://src/tower/progression.gd")

## A purchase or an opened group, so the game can save.
signal changed
## What was bought or opened, for the activity log (D077).
signal activity(entry: Dictionary)
signal home_pressed

const TABS := [["Attack", "attack"], ["Defense", "defense"], ["Utility", "utility"]]
## The buy multiplier's steps; 0 is Max. Presentation only, never saved (D018).
const AMOUNTS := [1, 5, 10, 0]

var workshop: Workshop
var progression: Progression
var _tab := "attack"
var _tab_buttons: Dictionary = {}
var _amount := 1
var _amount_button: Button
var _coins: Label
var _list: VBoxContainer
## Refreshed every frame: [{button, refresh: Callable}].
var _cards: Array[Dictionary] = []
## What a group just opened does (D125), over the screen until closed.
var _opened_panel: PanelContainer
var _mono := Palette.weight(Palette.NUMBER_FONT, 400)
var _mono_bold := Palette.weight(Palette.NUMBER_FONT, 500)


func _ready() -> void:
	theme = Palette.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)
	var screen := VBoxContainer.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_theme_constant_override("separation", 0)
	add_child(screen)
	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_bottom", 12)
	screen.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0, 36)
	column.add_child(top)
	var money := Palette.money_line(_mono_bold, false)
	top.add_child(money.line)
	_coins = money.coins
	var title := Label.new()
	title.text = "Workshop"
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)
	column.add_child(Palette.hairline())

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 22)
	column.add_child(tabs)
	for tab in TABS:
		var button := Button.new()
		button.text = tab[0]
		Palette.style_tab(button)
		button.pressed.connect(show_tab.bind(tab[1]))
		tabs.add_child(button)
		_tab_buttons[tab[1]] = button
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(gap)
	_amount_button = Palette.amount_pill(_mono)
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

	var nav := NavBar.new("workshop", workshop.runs, workshop.best_wave, progression)
	nav.chosen.connect(func(id: String):
		if id == "battle":
			home_pressed.emit())
	screen.add_child(Palette.hairline())
	screen.add_child(nav)
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
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	_coins.text = Palette.money(workshop.coins)
	_amount_button.text = "buy max" if _amount == 0 else "buy ×%d" % _amount
	for card in _cards:
		card.refresh.call()


## One row: its value, its level and the Coins the multiplier's press costs.
func _row_card(id: String) -> Button:
	var button := _card_button()
	var parts := _card_parts(button, Palette.row_title(id))
	button.pressed.connect(func():
		var coins_before := workshop.coins
		var from := workshop.level(id)
		if workshop.buy(id, _amount):
			activity.emit({"kind": "workshop_buy", "id": id, "from": from, "to": workshop.level(id),
				"cost": coins_before - workshop.coins, "coins_left": workshop.coins})
			changed.emit()
		refresh())
	_cards.append({"button": button, "refresh": func():
		var maxed := workshop.level(id) >= TowerData.max_level(id)
		var affordable := workshop.can_buy(id, _amount)
		parts.value.text = Palette.row_value(id, TowerData.value(id, workshop.level(id)))
		parts.level.text = "Lv %d" % workshop.level(id)
		parts.detail.text = "MAX" if maxed else Palette.quote(workshop.plan(id, _amount), workshop.price(id), "● ")
		button.disabled = not affordable
		parts.detail.add_theme_color_override("font_color", Palette.COIN if affordable else Palette.MUTED)})
	return button


## The tab's next group, The Tower's big Unlock card: what it opens and its
## Coins. The groups after it stay hidden until it is open.
func _unlock_card(group: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 88)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Palette.style_card(button)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 14
	column.offset_right = -14
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	var names: Array[String] = []
	for row in TowerData.group_rows(group):
		names.append(Palette.row_title(row))
	var opens := Label.new()
	opens.text = " · ".join(names)
	opens.add_theme_font_size_override("font_size", 12)
	opens.add_theme_color_override("font_color", Palette.MUTED)
	opens.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opens.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(opens)
	var unlock := Label.new()
	unlock.add_theme_font_override("font", _mono)
	unlock.add_theme_font_size_override("font_size", 18)
	unlock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unlock.text = "Unlock  ● " + Palette.money(TowerData.group_price(group), true)
	column.add_child(unlock)
	button.pressed.connect(func():
		var coins_before := workshop.coins
		if workshop.open_group(group):
			activity.emit({"kind": "workshop_open", "group": group, "cost": coins_before - workshop.coins, "coins_left": workshop.coins})
			changed.emit()
			show_tab(_tab)
			show_opened(group))
	_cards.append({"button": button, "refresh": func():
		button.disabled = not workshop.can_open(group)
		unlock.add_theme_color_override("font_color", Palette.COIN if workshop.can_open(group) else Palette.MUTED)})
	return button


## Over the screen: the rows a group just opened, each with what it does, as
## The Tower explains an upgrade the first time it unlocks (D125).
func show_opened(group: String) -> void:
	if _opened_panel != null:
		_opened_panel.queue_free()
	_opened_panel = PanelContainer.new()
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0, 0, 0, 0.6)
	_opened_panel.add_theme_stylebox_override("panel", shade)
	_opened_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_opened_panel)
	var centre := CenterContainer.new()
	_opened_panel.add_child(centre)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Palette.panel_box())
	card.custom_minimum_size = Vector2(300, 0)
	centre.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)
	var heading := Label.new()
	heading.text = "Unlocked"
	heading.add_theme_font_size_override("font_size", 16)
	column.add_child(heading)
	for row in TowerData.group_rows(group):
		var name_label := Label.new()
		name_label.text = Palette.row_title(row)
		name_label.add_theme_font_size_override("font_size", 14)
		column.add_child(name_label)
		var about := Label.new()
		about.text = String(TowerData.upgrade(row).description)
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		about.custom_minimum_size = Vector2(260, 0)
		about.add_theme_font_size_override("font_size", 12)
		about.add_theme_color_override("font_color", Palette.SOFT)
		column.add_child(about)
	var close := Palette.pill("Got it", Palette.SOFT, null, 36)
	close.pressed.connect(func():
		_opened_panel.queue_free()
		_opened_panel = null)
	column.add_child(close)


func _card_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 76)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Palette.style_card(button)
	return button


## Lays out a card as the battle's are: the row's name small at the top, its
## value large at the bottom left, and its level over the Coins its press
## costs at the bottom right.
func _card_parts(button: Button, title: String) -> Dictionary:
	var inside := VBoxContainer.new()
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = 14
	inside.offset_right = -14
	inside.offset_top = 12
	inside.offset_bottom = -12
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inside)
	var head := HBoxContainer.new()
	head.size_flags_vertical = Control.SIZE_EXPAND_FILL
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(head)
	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Palette.MUTED)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(name_label)
	var level := _number_label(11, Palette.MUTED)
	level.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	head.add_child(level)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(line)
	var value := _number_label(18, Palette.TEXT)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var detail := _number_label(12, Palette.COIN)
	line.add_child(value)
	line.add_child(detail)
	return {"value": value, "detail": detail, "level": level}


func _number_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", _mono)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
