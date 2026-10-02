extends Control
## The Workshop between runs: Attack, Defense and Utility of permanent
## levels bought with Coins. As in The Tower, a category shows only the next
## group it opens, never the ones after it. The rules are the Workshop's; this
## only shows and asks. Premium minimal, in our own layout (D142): the Coins
## chip and the buy multiplier along the top as Home has them, a segmented
## switch for the category, the next unlock as the hero at the top, then one
## slim row per upgrade whose price lights up when it can be paid, over a bar
## filling towards it; the dock along the bottom. Opening a group says what
## its rows do, as The Tower's info popups do when an upgrade unlocks (D125).

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
signal cards_pressed

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

	# The top line, as Home's: Coins, the name small in the middle, and the
	# buy multiplier (D142).
	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0, 40)
	column.add_child(top)
	var money := Palette.money_line(_mono_bold, false)
	money.line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(money.line)
	_coins = money.coins
	var title := Label.new()
	title.text = "WORKSHOP"
	title.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 400), 4))
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Palette.MUTED)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	var right := HBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(right)
	_amount_button = Palette.amount_pill(_mono)
	_amount_button.pressed.connect(_next_amount)
	Palette.press(_amount_button)
	right.add_child(_amount_button)

	# The category as a segmented switch, not a web page's tabs (D142).
	var switch := PanelContainer.new()
	var track := Palette.pill_box(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.05), 3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	switch.add_theme_stylebox_override("panel", track)
	column.add_child(switch)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	switch.add_child(tabs)
	for tab in TABS:
		var button := Button.new()
		button.text = tab[0]
		Palette.style_segment(button)
		button.pressed.connect(show_tab.bind(tab[1]))
		tabs.add_child(button)
		_tab_buttons[tab[1]] = button

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)

	var nav := NavBar.new("workshop", workshop.runs, workshop.best_wave, progression)
	nav.chosen.connect(func(id: String):
		if id == "battle":
			home_pressed.emit()
		elif id == "cards":
			cards_pressed.emit())
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
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	_list.add_child(rows)
	for group in TowerData.groups():
		var id := String(group.id)
		if String(group.workshop_category) == tab and workshop.is_group_open(id):
			for row in TowerData.group_rows(id):
				rows.add_child(_row_card(row))
	# The next unlock leads on screen, as what the Coins are heading for
	# (D142); its card comes after the rows' in _cards.
	var next := workshop.next_group(tab)
	if next != "":
		var unlock := _unlock_card(next)
		_list.add_child(unlock)
		_list.move_child(unlock, 0)
	refresh()


func _next_amount() -> void:
	_amount = AMOUNTS[(AMOUNTS.find(_amount) + 1) % AMOUNTS.size()]
	refresh()


func refresh() -> void:
	_coins.text = "● " + Palette.money(workshop.coins)
	_amount_button.text = "buy max" if _amount == 0 else "buy ×%d" % _amount
	for card in _cards:
		card.refresh.call()


## One row, one line (D142): its name over its value, its level, and a
## price chip lit when the multiplier's press can be paid, over a thin bar
## filling as the Coins come towards it. A buy makes the value pop.
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
			_pop(parts.value)
		refresh())
	_cards.append({"id": id, "button": button, "price": parts.price, "bar": parts.bar, "refresh": func():
		var maxed := workshop.level(id) >= TowerData.max_level(id)
		var affordable := workshop.can_buy(id, _amount)
		parts.value.text = Palette.row_value(id, TowerData.value(id, workshop.level(id)))
		parts.level.text = "Lv %d" % workshop.level(id)
		parts.price.label.text = "MAX" if maxed else Palette.quote(workshop.plan(id, _amount), workshop.price(id), "● ")
		Palette.style_price_chip(parts.price, affordable)
		button.disabled = not affordable
		_fill(parts.bar, 1.0 if maxed else toward(workshop.coins, _row_target(id)), affordable or maxed)})
	return button


## The Coins the multiplier's press on `id` costs now, or the next level's
## price when the press can't be planned; INF once it's maxed.
func _row_target(id: String) -> float:
	var buying := workshop.plan(id, _amount)
	return float(buying.cost) if int(buying.levels) > 0 else workshop.price(id)


## How far `coins` have come towards `target`, 0 to 1.
static func toward(coins: float, target: float) -> float:
	if target <= 0.0:
		return 1.0
	if not is_finite(target):
		return 0.0
	return clampf(coins / target, 0.0, 1.0)


## The category's next group as the hero (D142): what it opens, its price
## chip, and a bar filling towards it. The groups after it stay hidden until
## it is open, as in The Tower.
func _unlock_card(group: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 78)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	Palette.style_card(button)
	Palette.press(button)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 16
	column.offset_right = -16
	column.offset_top = 12
	column.offset_bottom = -12
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	var names: Array[String] = []
	for row in TowerData.group_rows(group):
		names.append(Palette.row_title(row))
	var next := Label.new()
	next.text = "NEXT"
	next.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 500), 3))
	next.add_theme_font_size_override("font_size", 10)
	next.add_theme_color_override("font_color", Palette.MUTED)
	next.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(next)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(line)
	var opens := Label.new()
	opens.text = " · ".join(names)
	opens.add_theme_font_size_override("font_size", 16)
	opens.add_theme_color_override("font_color", Palette.TEXT)
	opens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opens.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	opens.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	opens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(opens)
	var price := Palette.price_chip(_mono_bold, 14)
	price.label.text = "Unlock  ● " + Palette.money(TowerData.group_price(group), true)
	line.add_child(price.panel)
	var bar := _bar()
	column.add_child(bar)
	button.pressed.connect(func():
		var coins_before := workshop.coins
		if workshop.open_group(group):
			activity.emit({"kind": "workshop_open", "group": group, "cost": coins_before - workshop.coins, "coins_left": workshop.coins})
			changed.emit()
			show_tab(_tab)
			show_opened(group))
	_cards.append({"group": group, "button": button, "price": price, "bar": bar, "refresh": func():
		var open := workshop.can_open(group)
		button.disabled = not open
		Palette.style_price_chip(price, open)
		_fill(bar, toward(workshop.coins, TowerData.group_price(group)), open)})
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
	button.custom_minimum_size = Vector2(0, 66)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	Palette.style_card(button)
	Palette.press(button)
	return button


## Lays out a row (D142): its name small over its value on the left, its
## level and price chip on the right, and a thin bar along the bottom.
func _card_parts(button: Button, title: String) -> Dictionary:
	var inside := VBoxContainer.new()
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = 16
	inside.offset_right = -14
	inside.offset_top = 10
	inside.offset_bottom = -8
	inside.add_theme_constant_override("separation", 6)
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inside)
	var line := HBoxContainer.new()
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line.add_theme_constant_override("separation", 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(line)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(words)
	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Palette.SOFT)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(name_label)
	var value := _number_label(19, Palette.TEXT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(value)
	var level := _number_label(11, Palette.MUTED)
	level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(level)
	var price := Palette.price_chip(_mono_bold)
	price.panel.custom_minimum_size = Vector2(76, 0)
	line.add_child(price.panel)
	var bar := _bar()
	inside.add_child(bar)
	return {"value": value, "price": price, "level": level, "bar": bar}


## A thin bar that fills towards a price (D142).
func _bar() -> ProgressBar:
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


## Fills a bar to `share`, gold once the price can be paid.
func _fill(bar: ProgressBar, share: float, lit: bool) -> void:
	bar.value = share
	var fill := StyleBoxFlat.new()
	fill.bg_color = Palette.COIN if lit else Color(Palette.COIN, 0.35)
	bar.add_theme_stylebox_override("fill", fill)


## A value that just went up springs a little, so a buy is felt.
func _pop(label: Label) -> void:
	if not label.is_inside_tree():
		return
	label.pivot_offset = label.size * 0.5
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * 1.08, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _spaced(font: FontVariation, spacing: int) -> FontVariation:
	font.spacing_glyph = spacing
	return font


func _number_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", _mono)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
