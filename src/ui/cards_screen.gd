extends Control
## Cards between runs: a draw, the active slots, then the inventory.
## A tap on either an active card or an inventory tile opens its details,
## where it is equipped or taken off. A run takes the cards equipped when
## it starts. The rules are Progression's and Cards'; this only shows and asks.

const Cards = preload("res://src/tower/cards.gd")
const Palette = preload("res://src/ui/palette.gd")
const CARD_ART := {
	"damage": preload("res://assets/cards/damage.svg"),
	"health": preload("res://assets/cards/health.svg"),
	"cash": preload("res://assets/cards/cash.svg"),
}
const MAXED_SHEEN = preload("res://src/ui/shaders/maxed_card_sheen.gdshader")
const NavBar = preload("res://src/ui/nav_bar.gd")
const Overlay = preload("res://src/ui/overlay.gd")
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
var _active_grid: GridContainer
var _inventory_heading: Label
## Cards across, in the grid.
const GRID_COLUMNS := 3
## Refreshed after each change: [{id, button, refresh: Callable}].
var rows: Array[Dictionary] = []
## The card just drawn, over the screen until closed.
var drawn_panel: Overlay
## A card's details, over the screen until closed, and its Equip button. Only
## one sheet is up at a time, so one replaces the other.
var info_panel: Overlay
var info_equip: Button
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
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	screen.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
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
	_active_grid = GridContainer.new()
	_active_grid.columns = GRID_COLUMNS
	_active_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_active_grid.add_theme_constant_override("h_separation", 8)
	_active_grid.add_theme_constant_override("v_separation", 8)
	_list.add_child(_active_grid)
	var note := _small("Tap a card to equip or remove it for your next run", Palette.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_list.add_child(note)
	_inventory_heading = _small("", Palette.SOFT)
	_inventory_heading.add_theme_font_size_override("font_size", 11)
	_list.add_child(_inventory_heading)
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
	Palette.fill_progress(_draw_bar, toward(progression.gems, Cards.price()), affordable, Palette.ACCENT)
	_slot_line.text = "ACTIVE  %d / %d" % [cards.equipped.size(), cards.slots]
	var slot_price := cards.slot_price()
	_slot_button.visible = slot_price >= 0
	if slot_price >= 0:
		var can_slot := progression.can_buy_card_slot()
		_slot_price.label.text = "+ slot  ◆ %d" % slot_price
		Palette.style_price_chip(_slot_price, can_slot, Palette.ACCENT)
		_slot_button.disabled = not can_slot
	_refresh_active()
	var found := Cards.built_ids().filter(func(id): return cards.owned(id)).size()
	_inventory_heading.text = "INVENTORY  ·  %d / %d found" % [found, Cards.built_ids().size()]
	for row in rows:
		row.refresh.call()


## The compact draw control: its odds, price chip and affordability bar.
func _draw_card() -> Button:
	_draw_button = Palette.card_button(64)
	var column := _inside(_draw_button, 12)
	var heading := _small("BUY NEW CARD", Palette.MUTED)
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
	_draw_bar = Palette.progress_bar()
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


## Every bought slot is visible, including empty ones. Active cards open
## the same details as their inventory tiles; this is no second loadout.
func _refresh_active() -> void:
	for child in _active_grid.get_children():
		_active_grid.remove_child(child)
		child.queue_free()
	var cards := progression.cards
	for index in range(cards.slots):
		var button := Palette.card_button(64)
		var column := _inside(button, 8)
		column.offset_left = 8
		column.offset_right = -8
		column.add_theme_constant_override("separation", 3)
		var title := _small("Empty slot", Palette.MUTED)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		var value := _small("—", Palette.MUTED)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
		column.add_child(value)
		if index < cards.equipped.size():
			var id: String = cards.equipped[index]
			title.text = card_name(id)
			title.add_theme_color_override("font_color", Palette.TEXT)
			value.text = describe(id, cards.level(id))
			value.add_theme_color_override("font_color", Palette.ACCENT)
			if CARD_ART.has(id):
				var art := _art_region(id, 24)
				art.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
				art.offset_left = 6
				art.offset_right = 34
				art.offset_top = -12
				art.offset_bottom = 12
				button.add_child(art)
				column.offset_left = 34
			button.tooltip_text = "%s · tap for details or Remove" % title.text
			button.pressed.connect(func(): show_card(id))
			_style_row(button, true, cards.maxed(id))
		else:
			button.disabled = true
			_style_row(button, false)
		_active_grid.add_child(button)


## Inventory: name first, the current effect, seven level dots, and the
## exact copies towards the next level. Equipped cards carry a visible tick.
func _card_tile(id: String) -> Button:
	var button := Palette.card_button(176)
	var card: Dictionary = Cards.card(id)
	button.tooltip_text = card_name(id) + " · tap for details"
	var inside := _inside(button, 8)
	inside.offset_left = 8
	inside.offset_right = -8
	inside.add_theme_constant_override("separation", 4)
	var heading := _small(card_name(id), RARITY_COLOURS[card.rarity])
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	heading.custom_minimum_size = Vector2(0, 30)
	heading.add_theme_font_size_override("font_size", 11)
	inside.add_child(heading)
	var art := _art_region(id, 56)
	inside.add_child(art)
	var value := _number(16 if id == "free_upgrades" else 20, Palette.TEXT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inside.add_child(value)
	var dots := _small("", Palette.ACCENT)
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.add_theme_font_size_override("font_size", 8)
	inside.add_child(dots)
	var copies := _small("", Palette.MUTED)
	copies.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copies.add_theme_font_size_override("font_size", 9)
	inside.add_child(copies)
	var bar := Palette.progress_bar()
	inside.add_child(bar)
	button.pressed.connect(func(): show_card(id))
	rows.append({"id": id, "button": button, "refresh": func():
		var cards := progression.cards
		var found := cards.owned(id)
		var on := cards.is_equipped(id)
		button.modulate.a = 1.0 if found else 0.7
		for image in art.get_children():
			image.visible = found
		value.text = describe(id, cards.level(id)) if found else "?"
		dots.text = level_dots(cards.level(id))
		var toward_next := cards.progress(id)
		copies.text = ("✓  " if on else "") + ("MAX" if cards.maxed(id) else ("%d / %d" % toward_next if found else "Not found"))
		var maxed := cards.maxed(id)
		dots.add_theme_color_override("font_color", Palette.COIN if maxed else Palette.ACCENT)
		copies.add_theme_color_override("font_color", Palette.COIN if maxed else Palette.MUTED)
		_style_row(button, on, maxed)
		Palette.fill_progress(bar, 1.0 if maxed else (float(toward_next[0]) / maxf(1.0, float(toward_next[1])) if found else 0.0), on or maxed, Palette.COIN if maxed else Palette.ACCENT)})
	return button


## Art is decorative and leaves button input to the existing card action.
## Reserving the same space keeps names and values aligned across each row.
func _art_region(id: String, height: float) -> Control:
	var region := Control.new()
	region.custom_minimum_size = Vector2(0, height)
	region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if CARD_ART.has(id):
		var art := TextureRect.new()
		art.texture = CARD_ART[id]
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		region.add_child(art)
	return region


## A card's level as seven dots, filled up to it: "●●○○○○○".
static func level_dots(level: int) -> String:
	return "●".repeat(level) + "○".repeat(Cards.max_level() - level)


## Over the screen: a card's details, as The Tower's card popup has them:
## its rarity, name and value, what it does, its level and copies, every
## level's value with this one lit, and Equip or Remove. Unfound, it says so
## and can't be equipped.
func show_card(id: String) -> void:
	var sheet := Overlay.new()
	info_panel = sheet
	sheet.closed.connect(func(): if info_panel == sheet: info_panel = null)
	var column := sheet.column
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
	info_equip = sheet.action(label, Palette.ACCENT, func(): toggle(id))
	info_equip.disabled = not (on or cards.can_equip(id))
	sheet.done()
	sheet.show_over(self)


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
## A card's name and description, The Tower's, or with the Number as Cash
## (D156) the Cash card's written about the Number.
static func card_name(id: String) -> String:
	return "Number Income" if Palette.number_cash and id == "cash" else String(Cards.card(id).name)


static func card_description(id: String) -> String:
	return "Increase all Number earned by [x]" if Palette.number_cash and id == "cash" else String(Cards.card(id).description)


static func describe(id: String, level: int) -> String:
	var card: Dictionary = Cards.definition(id)
	var amount := Cards.value_at(id, level)
	match String(card.unit):
		"multiplier":
			return "×%.2f" % amount
		"share":
			var percent := snappedf(amount * 100.0, 0.01)
			var text := "+%s%%" % (str(roundi(percent)) if is_equal_approx(percent, roundf(percent)) else str(percent))
			return text + (" each" if id == "free_upgrades" else "")
		"count":
			return "+%s" % Palette.number(amount)
	return Palette.number(amount)


## Over the screen: the card just drawn, its rarity, and whether it is new or
## a copy towards its next level.
func show_drawn(id: String) -> void:
	var sheet := Overlay.new()
	drawn_panel = sheet
	sheet.closed.connect(func(): if drawn_panel == sheet: drawn_panel = null)
	var cards := progression.cards
	_card_heading(sheet.column, id, cards.level(id))
	var count := int(cards.copies[id])
	var note := "A copy: %d/%d to level %d" % [cards.progress(id)[0], cards.progress(id)[1], cards.level(id) + 1]
	if count == 1:
		note = "New card"
	elif Cards.level_for(count - 1) < cards.level(id):
		note = "Up to level %d" % cards.level(id)
	var status := _small(note, Palette.ACCENT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.column.add_child(status)
	sheet.done("Got it")
	sheet.show_over(self)


## A card's rarity, name, value at `level` and what it does, centred.
func _card_heading(column: VBoxContainer, id: String, level: int) -> void:
	var card: Dictionary = Cards.card(id)
	var rarity := _small(String(card.rarity).to_upper(), RARITY_COLOURS[card.rarity])
	rarity.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 500), 3))
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(rarity)
	if CARD_ART.has(id) and progression.cards.owned(id):
		column.add_child(_art_region(id, 124))
	var name_label := Label.new()
	name_label.text = card_name(id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	column.add_child(name_label)
	var value := _number(28, Palette.TEXT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.text = describe(id, level)
	column.add_child(value)
	var about := _small(card_description(id).replace("[x]%", "[x]").replace("[x]", describe(id, level)), Palette.SOFT)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about.custom_minimum_size = Vector2(240, 0)
	column.add_child(about)


## How far `have` has come towards `target`, 0 to 1.
static func toward(have: float, target: float) -> float:
	if target <= 0.0:
		return 1.0
	return clampf(have / target, 0.0, 1.0)


func _style_row(button: Button, on: bool, maxed: bool = false) -> void:
	var edge := Color(Palette.COIN, 0.75 if on else 0.5) if maxed else (Color(Palette.ACCENT, 0.5) if on else Palette.HAIRLINE)
	for state in ["normal", "disabled", "hover", "pressed"]:
		var hover := Color(Palette.COIN if maxed else Palette.ACCENT, 0.9 if maxed else 0.7)
		var box := Palette.card_box(Color("1c1911") if maxed else Palette.SURFACE, hover if state == "hover" else edge, 6)
		box.set_border_width_all(1)
		button.add_theme_stylebox_override(state, box)
	var sheen := button.get_node_or_null("MaxedSheen") as ColorRect
	if maxed and sheen == null:
		sheen = ColorRect.new()
		sheen.name = "MaxedSheen"
		sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sheen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var material := ShaderMaterial.new()
		material.shader = MAXED_SHEEN
		material.set_shader_parameter("card_size", button.size)
		sheen.material = material
		button.resized.connect(func(): material.set_shader_parameter("card_size", button.size))
		button.add_child(sheen)
		button.move_child(sheen, 0)
	if sheen != null:
		sheen.visible = maxed


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


static func _spaced(font: FontVariation, spacing: int) -> FontVariation:
	font.spacing_glyph = spacing
	return font
