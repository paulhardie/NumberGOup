extends Control
## Cards between runs (D146), premium minimal: Gems along the top, a draw as
## the hero (a card for Gems, by The Tower's odds), the equipped count and the
## next slot, then every built card as a tile in a grid of three, as The
## Tower lays them out (D147). A tap opens a card's details, where it is
## equipped or taken off. A run takes the cards equipped when it starts.
## The rules are Progression's and Cards'; this only shows and asks.

const Cards = preload("res://src/tower/cards.gd")
const Palette = preload("res://src/ui/palette.gd")
const NavBar = preload("res://src/ui/nav_bar.gd")
const Progression = preload("res://src/tower/progression.gd")
const Workshop = preload("res://src/tower/workshop.gd")

## A draw, a slot or a change of what's equipped, so the game can save.
signal changed
## What was drawn, bought or equipped, for the activity log (D077).
signal activity(entry: Dictionary)
signal home_pressed
signal workshop_pressed

## Each rarity's colour: quiet, then cool, then warm violet, so a rare draw
## reads at a glance without a loud frame.
const RARITY_COLOURS := {"common": Palette.SOFT, "rare": Color("8fb4ff"), "epic": Color("d3a6ff")}

var workshop: Workshop
var progression: Progression
## Draws use this; the game's is seeded from the clock, tests seed their own.
var rng := RandomNumberGenerator.new()
var _gems: Label
var _draw_price: Dictionary
var _draw_bar: ProgressBar
var _draw_button: Button
var _odds: Label
var _slot_line: Label
var _slot_button: Button
var _slot_price: Dictionary
var _list: VBoxContainer
## Cards across, in the grid.
const GRID_COLUMNS := 3
## Refreshed after each change: [{id, button, refresh: Callable}].
var rows: Array[Dictionary] = []
## The card just drawn, over the screen until closed.
var drawn_panel: PanelContainer
## A card's details, over the screen until closed, and its Equip button.
var info_panel: PanelContainer
var info_equip: Button
## Whichever of the two is up, and what closing it clears.
var _shade: PanelContainer
var _on_close: Callable
var _mono := Palette.weight(Palette.NUMBER_FONT, 400)
var _mono_bold := Palette.weight(Palette.NUMBER_FONT, 500)


func _ready() -> void:
	rng.randomize()
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

	# The top line, as the Workshop's: Gems, and the name small in the middle.
	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0, 40)
	column.add_child(top)
	var gems := Palette.chip(Palette.ACCENT, Palette.MONEY_PX - 2)
	gems.label.add_theme_font_override("font", _mono_bold)
	var left := HBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(gems.panel)
	top.add_child(left)
	_gems = gems.label
	var title := Label.new()
	title.text = "CARDS"
	title.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 400), 4))
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Palette.MUTED)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	var right := Control.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(right)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_list)
	_list.add_child(_draw_card())
	_list.add_child(_slots_line())
	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(grid)
	for id in Cards.built_ids():
		grid.add_child(_card_tile(id))

	var nav := NavBar.new("cards", workshop.runs, workshop.best_wave, progression)
	nav.chosen.connect(func(id: String):
		if id == "battle":
			home_pressed.emit()
		elif id == "workshop":
			workshop_pressed.emit())
	screen.add_child(Palette.hairline())
	screen.add_child(nav)
	refresh()


## Only this screen changes what it shows (Gems come in on Home and in
## battle), so it refreshes after each change rather than every frame.
func refresh() -> void:
	var cards := progression.cards
	_gems.text = "◆ %d" % progression.gems
	var can_draw := cards.can_draw()
	var affordable := progression.can_draw_card()
	_draw_button.disabled = not affordable
	_odds.text = odds_text(cards.odds()) if can_draw else "Every card found"
	_draw_price.label.text = "◆ %d" % Cards.price() if can_draw else "All found"
	Palette.style_price_chip(_draw_price, affordable, Palette.ACCENT)
	_fill(_draw_bar, toward(progression.gems, Cards.price()), affordable)
	_slot_line.text = "EQUIPPED  %d / %d" % [cards.equipped.size(), cards.slots]
	var slot_price := cards.slot_price()
	_slot_button.visible = slot_price >= 0
	if slot_price >= 0:
		var can_slot := progression.can_buy_card_slot()
		_slot_price.label.text = "+ slot  ◆ %d" % slot_price
		Palette.style_price_chip(_slot_price, can_slot, Palette.ACCENT)
		_slot_button.disabled = not can_slot
	for row in rows:
		row.refresh.call()


## The draw as the hero, as the Workshop's next unlock: what it is, The
## Tower's odds, its price chip and a bar filling towards it.
func _draw_card() -> Button:
	_draw_button = _card_button(78)
	var column := _inside(_draw_button, 12)
	var heading := _small("DRAW A CARD", Palette.MUTED)
	heading.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 500), 3))
	heading.add_theme_font_size_override("font_size", 10)
	column.add_child(heading)
	var line := _line(column)
	var chances := Label.new()
	_odds = chances
	chances.add_theme_font_size_override("font_size", 14)
	chances.add_theme_color_override("font_color", Palette.TEXT)
	chances.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chances.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chances.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(chances)
	_draw_price = Palette.price_chip(_mono_bold, 14)
	line.add_child(_draw_price.panel)
	_draw_bar = _bar()
	column.add_child(_draw_bar)
	_draw_button.pressed.connect(draw)
	return _draw_button


## Draws a card for its Gems and shows what came.
func draw() -> String:
	var gems_before := progression.gems
	var id := progression.draw_card(rng)
	if id == "":
		return ""
	activity.emit({"kind": "card_draw", "id": id, "copies": int(progression.cards.copies[id]), "level": progression.cards.level(id),
		"gems": gems_before - progression.gems, "gems_left": progression.gems})
	changed.emit()
	show_drawn(id)
	refresh()
	return id


## The equipped count and the next slot's price.
func _slots_line() -> HBoxContainer:
	var line := HBoxContainer.new()
	line.custom_minimum_size = Vector2(0, 36)
	_slot_line = _small("", Palette.MUTED)
	_slot_line.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 500), 3))
	_slot_line.add_theme_font_size_override("font_size", 10)
	_slot_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(_slot_line)
	_slot_button = Button.new()
	_slot_button.flat = true
	_slot_button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		_slot_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_slot_price = Palette.price_chip(_mono_bold, 12)
	_slot_button.add_child(_slot_price.panel)
	_slot_price.panel.resized.connect(func(): _slot_button.custom_minimum_size = _slot_price.panel.size)
	Palette.press(_slot_button)
	_slot_button.pressed.connect(buy_slot)
	line.add_child(_slot_button)
	return line


func buy_slot() -> bool:
	var gems_before := progression.gems
	if not progression.buy_card_slot():
		return false
	activity.emit({"kind": "card_slot", "slots": progression.cards.slots, "gems": gems_before - progression.gems, "gems_left": progression.gems})
	changed.emit()
	refresh()
	return true


## One card as a tile in the grid, as The Tower lays its cards out: a thin
## line in its rarity's colour along the top, its value at its level large,
## its name, its level as seven dots and a bar of copies towards the next.
## Lit with the accent's edge while equipped; dimmed, with a "?", until it is
## found. A tap opens the card (show_card), where it is equipped.
func _card_tile(id: String) -> Button:
	var button := _card_button(118)
	var card: Dictionary = Cards.card(id)
	var inside := VBoxContainer.new()
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = 10
	inside.offset_right = -10
	inside.offset_top = 0
	inside.offset_bottom = -10
	inside.add_theme_constant_override("separation", 4)
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inside)
	var edge := ColorRect.new()
	edge.custom_minimum_size = Vector2(0, 2)
	edge.color = Color(RARITY_COLOURS[card.rarity], 0.7)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(edge)
	# "Equipped", small in the accent, while it is.
	var worn := _small("EQUIPPED", Palette.ACCENT)
	worn.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 500), 2))
	worn.add_theme_font_size_override("font_size", 8)
	worn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	worn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	worn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inside.add_child(worn)
	var value := _number(20, Palette.TEXT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inside.add_child(value)
	var name_label := _small(String(card.name), RARITY_COLOURS[card.rarity])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	inside.add_child(name_label)
	var dots := _small("", Palette.ACCENT)
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.add_theme_font_size_override("font_size", 8)
	inside.add_child(dots)
	var bar := _bar()
	inside.add_child(bar)
	button.pressed.connect(func(): show_card(id))
	rows.append({"id": id, "button": button, "refresh": func():
		var cards := progression.cards
		var found := cards.owned(id)
		var on := cards.is_equipped(id)
		button.modulate.a = 1.0 if found else 0.55
		worn.modulate.a = 1.0 if on else 0.0
		value.text = describe(id, cards.level(id)) if found else "?"
		dots.text = level_dots(cards.level(id))
		var toward_next := cards.progress(id)
		_style_row(button, on)
		_fill(bar, 1.0 if cards.maxed(id) else (float(toward_next[0]) / maxf(1.0, float(toward_next[1])) if found else 0.0), on)})
	return button


## A card's level as seven dots, filled up to it: "●●○○○○○".
static func level_dots(level: int) -> String:
	return "●".repeat(level) + "○".repeat(Cards.max_level() - level)


## Over the screen: a card's details, as The Tower's card popup has them:
## its rarity, name and value, what it does, its level and copies, every
## level's value with this one lit, and Equip or Remove. Unfound, it says so
## and can't be equipped.
func show_card(id: String) -> void:
	var column := _overlay(func(): info_panel = null)
	info_panel = _shade
	var card: Dictionary = Cards.card(id)
	var cards := progression.cards
	var found := cards.owned(id)
	var level := cards.level(id)
	_card_heading(column, id, maxi(1, level))
	var status := _small("", Palette.MUTED)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not found:
		status.text = "Not found yet: draw cards to find it"
	elif cards.maxed(id):
		status.text = "Level %d · max" % level
	else:
		status.text = "Level %d · %d/%d copies to level %d" % [level, cards.progress(id)[0], cards.progress(id)[1], level + 1]
	column.add_child(status)
	# Every level's value, this one lit.
	var ladder := GridContainer.new()
	ladder.columns = Cards.max_level()
	ladder.add_theme_constant_override("h_separation", 6)
	ladder.add_theme_constant_override("v_separation", 2)
	ladder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for step in range(1, Cards.max_level() + 1):
		var at := _small(str(step), Palette.ACCENT if step == level else Palette.MUTED)
		at.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		at.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		at.add_theme_font_size_override("font_size", 9)
		ladder.add_child(at)
	for step in range(1, Cards.max_level() + 1):
		var worth := _small(describe(id, step).trim_suffix(" each"), Palette.TEXT if step == level else Palette.MUTED)
		worth.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		worth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		worth.add_theme_font_size_override("font_size", 10)
		ladder.add_child(worth)
	column.add_child(ladder)
	var on := cards.is_equipped(id)
	var label := "Remove" if on else ("Equip" if cards.can_equip(id) else ("Not found" if not found else "No free slot"))
	info_equip = Palette.pill(label, Palette.ACCENT, null, 38)
	info_equip.disabled = not (on or cards.can_equip(id))
	info_equip.pressed.connect(func():
		toggle(id)
		_close_overlay())
	column.add_child(info_equip)
	var close := Palette.pill("Close", Palette.SOFT, null, 36)
	close.pressed.connect(_close_overlay)
	column.add_child(close)


## Equips `id`, or takes it off if it is equipped.
func toggle(id: String) -> bool:
	var cards := progression.cards
	var done := cards.unequip(id) if cards.is_equipped(id) else cards.equip(id)
	if done:
		activity.emit({"kind": "card_equip", "id": id, "equipped": cards.is_equipped(id), "loadout": cards.equipped.duplicate()})
		changed.emit()
	refresh()
	return done


## The chances a draw has now, as "Common 82% · Rare 18%": The Tower's odds
## among the rarities with a card left to give (Cards.odds).
static func odds_text(odds: Dictionary) -> String:
	var parts: Array[String] = []
	for rarity in odds:
		parts.append("%s %d%%" % [String(rarity).capitalize(), roundi(float(odds[rarity]) * 100.0)])
	return " · ".join(parts)


## What a card does at `level`, written as The Tower writes its value: "×1.50",
## "+5%", "+4% each".
static func describe(id: String, level: int) -> String:
	var card: Dictionary = Cards.card(id)
	var amount := Cards.value_at(id, level)
	match String(card.unit):
		"multiplier":
			return "×%.2f" % amount
		"share":
			var percent := snappedf(amount * 100.0, 0.01)
			var text := "+%s%%" % (str(roundi(percent)) if is_equal_approx(percent, roundf(percent)) else str(percent))
			return text + (" each" if id == "free_upgrades" else "")
	return Palette.number(amount)


## Over the screen: the card just drawn, its rarity, and whether it is new or
## a copy towards its next level.
func show_drawn(id: String) -> void:
	var column := _overlay(func(): drawn_panel = null)
	drawn_panel = _shade
	var cards := progression.cards
	_card_heading(column, id, cards.level(id))
	var count := int(cards.copies[id])
	var note := "A copy: %d/%d to level %d" % [cards.progress(id)[0], cards.progress(id)[1], cards.level(id) + 1]
	if count == 1:
		note = "New card"
	elif Cards.level_for(count - 1) < cards.level(id):
		note = "Up to level %d" % cards.level(id)
	var status := _small(note, Palette.ACCENT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)
	var close := Palette.pill("Got it", Palette.SOFT, null, 36)
	close.pressed.connect(_close_overlay)
	column.add_child(close)


## A card's rarity, name, value at `level` and what it does, centred.
func _card_heading(column: VBoxContainer, id: String, level: int) -> void:
	var card: Dictionary = Cards.card(id)
	var rarity := _small(String(card.rarity).to_upper(), RARITY_COLOURS[card.rarity])
	rarity.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 500), 3))
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(rarity)
	var name_label := Label.new()
	name_label.text = String(card.name)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	column.add_child(name_label)
	var value := _number(28, Palette.TEXT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.text = describe(id, level)
	column.add_child(value)
	var about := _small(String(card.description).replace("[x]%", "[x]").replace("[x]", describe(id, level)), Palette.SOFT)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about.custom_minimum_size = Vector2(240, 0)
	column.add_child(about)


## A panel over a darkened screen, replacing any other; returns its column.
## `on_close` runs when it closes.
func _overlay(on_close: Callable) -> VBoxContainer:
	_close_overlay()
	_shade = PanelContainer.new()
	_on_close = on_close
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0, 0, 0, 0.6)
	_shade.add_theme_stylebox_override("panel", shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	var centre := CenterContainer.new()
	_shade.add_child(centre)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.panel_box())
	panel.custom_minimum_size = Vector2(300, 0)
	centre.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	return column


func _close_overlay() -> void:
	if _shade == null:
		return
	_shade.queue_free()
	_shade = null
	if _on_close.is_valid():
		_on_close.call()


## How far `have` has come towards `target`, 0 to 1.
static func toward(have: float, target: float) -> float:
	if target <= 0.0:
		return 1.0
	return clampf(have / target, 0.0, 1.0)


func _style_row(button: Button, on: bool) -> void:
	var edge := Color(Palette.ACCENT, 0.5) if on else Palette.TOP_EDGE
	button.add_theme_stylebox_override("normal", Palette.card_box(Palette.SURFACE, edge))
	button.add_theme_stylebox_override("disabled", Palette.card_box(Palette.SURFACE, edge))


func _card_button(height: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	Palette.style_card(button)
	Palette.press(button)
	return button


func _inside(button: Button, top: int) -> VBoxContainer:
	var inside := VBoxContainer.new()
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = 16
	inside.offset_right = -14
	inside.offset_top = top
	inside.offset_bottom = -8
	inside.add_theme_constant_override("separation", 6)
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inside)
	return inside


func _line(parent: Control) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
	return line


func _small(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", colour)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _number(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", _mono)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## A thin bar along a row's foot (D142).
func _bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 2)
	bar.max_value = 1.0
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.05)
	bar.add_theme_stylebox_override("background", back)
	return bar


func _fill(bar: ProgressBar, share: float, lit: bool) -> void:
	bar.value = share
	var fill := StyleBoxFlat.new()
	fill.bg_color = Palette.ACCENT if lit else Color(Palette.ACCENT, 0.35)
	bar.add_theme_stylebox_override("fill", fill)


static func _spaced(font: FontVariation, spacing: int) -> FontVariation:
	font.spacing_glyph = spacing
	return font
