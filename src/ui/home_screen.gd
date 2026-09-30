extends Control
## Between runs, laid out after The Tower's home (D096): Coins and the top
## pills, the game's name over the best Number in its light, the Coin bonus
## and the tier, and the Battle button, with the bar to the Workshop below.
## Milestones open over the screen (D107). Placeholders stand where the
## roadmap's later pieces will go (tiers past 1, and in the bar Cards and Labs
## once a run reaches The Tower's wave for them, D125); they are shown,
## locked, and do nothing. Settings (Music, Export report and the build) open
## over the screen. A first run's end opens the Workshop's welcome (D125).

const Workshop = preload("res://src/tower/workshop.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const Guesses = preload("res://src/tower/guesses.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")
const Palette = preload("res://src/ui/palette.gd")
const Settings = preload("res://src/settings.gd")
const NavBar = preload("res://src/ui/nav_bar.gd")
const Progression = preload("res://src/tower/progression.gd")

signal battle_pressed
signal workshop_pressed
## The owner wants the activity log as a report file (D077).
signal export_pressed
## A setting was changed here, to be written.
signal settings_changed
## Testing (D097): free Coins for the Workshop, and a fresh start.
signal test_coins_pressed(amount: float)
signal reset_pressed
signal daily_pressed

## The free Coins the testing buttons give.
const TEST_COINS := [1000.0, 100000.0]

## The best Number, large and thin in the light, as the battle draws the Number.
const EMBLEM_HEIGHT := 190
const EMBLEM_NUMBER_PX := 64

var workshop: Workshop
var progression: Progression
var _gems: Label
var _daily: Button
var _daily_day := -1
## The player's settings, changed in place; fresh ones if not set.
var settings: Settings
var _coins: Label
var _best_number: Label
var _coin_bonus: Label
var _best_wave: Label
var _settings_panel: PanelContainer
var _milestones_panel: PanelContainer
var _milestones_list: VBoxContainer
## The Workshop's welcome after a first run (D125), and the Coins it announces.
var _gift_panel: PanelContainer
var _gift := 0.0
var _reset: Button
## Reset asks twice: the first press arms it, the second resets.
var _reset_armed := false
## A line under the Battle button: where a report went, or what happened to a run.
var _note: Label
var _light: ColorRect
var _light_time := 0.0
var _mono := Palette.weight(Palette.NUMBER_FONT, 400)
var _mono_bold := Palette.weight(Palette.NUMBER_FONT, 500)


func _ready() -> void:
	theme = Palette.make_theme()
	if settings == null:
		settings = Settings.new()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)

	var screen := VBoxContainer.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_theme_constant_override("separation", 0)
	add_child(screen)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.custom_minimum_size = Vector2(0, 36)
	screen.add_child(_margined(top, 20, 20))
	var money := Palette.money_line(_mono_bold, false)
	top.add_child(money.line)
	_coins = money.coins
	if progression != null:
		_gems = _figure(14, Palette.ACCENT)
		top.add_child(_gems)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	var open_settings := Palette.pill("Settings", Palette.SOFT)
	open_settings.pressed.connect(func(): _settings_panel.visible = true)
	top.add_child(open_settings)

	var body := VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	var body_margin := _margined(body, 24, 20)
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(body_margin)

	var title := Label.new()
	title.text = "NUMBER GO UP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 300), 3))
	title.add_theme_font_size_override("font_size", 24)
	body.add_child(title)

	# The emblem: the best Number, in the same light as the battle's.
	var emblem := Control.new()
	emblem.custom_minimum_size = Vector2(0, EMBLEM_HEIGHT)
	emblem.clip_contents = true
	body.add_child(emblem)
	_light = ColorRect.new()
	_light.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_light.material = ShaderMaterial.new()
	(_light.material as ShaderMaterial).shader = preload("res://src/ui/number_glow.gdshader")
	emblem.add_child(_light)
	_best_number = Label.new()
	_best_number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_best_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_best_number.add_theme_font_override("font", Palette.weight(Palette.WORD_FONT, 200))
	_best_number.add_theme_font_size_override("font_size", EMBLEM_NUMBER_PX)
	_best_number.add_theme_color_override("font_color", Palette.NUMBER)
	emblem.add_child(_best_number)

	var milestones := Palette.pill("Milestones", Palette.SOFT, null, 40)
	milestones.pressed.connect(func():
		_fill_milestones()
		_milestones_panel.visible = true)
	milestones.custom_minimum_size = Vector2(200, 40)
	milestones.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(milestones)
	if progression != null:
		_daily = Palette.pill("Daily Gems", Palette.ACCENT, null, 36)
		_daily.pressed.connect(func(): daily_pressed.emit())
		_daily.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		body.add_child(_daily)

	var bonus := _card()
	body.add_child(bonus.panel)
	bonus.column.add_child(_caption("Coin bonus"))
	_coin_bonus = _figure(20, Palette.COIN)
	bonus.column.add_child(_coin_bonus)

	var tier := _card()
	body.add_child(tier.panel)
	tier.column.add_child(_caption("Difficulty"))
	var chooser := HBoxContainer.new()
	chooser.alignment = BoxContainer.ALIGNMENT_CENTER
	chooser.add_theme_constant_override("separation", 18)
	tier.column.add_child(chooser)
	# Tier 1 is all there is until 1.4 (D079); the arrows stand ready, locked.
	var lower := Palette.pill("‹", Palette.SOFT, null, 32)
	lower.disabled = true
	chooser.add_child(lower)
	var tier_name := Label.new()
	tier_name.text = "Tier 1"
	tier_name.add_theme_font_size_override("font_size", 18)
	chooser.add_child(tier_name)
	var higher := Palette.pill("›", Palette.SOFT, null, 32)
	higher.disabled = true
	higher.tooltip_text = "Tier 2 comes in 1.4"
	chooser.add_child(higher)
	# The Tower's gate (D107): Tier 2 opens once Tier 1's wave 100 is cleared.
	var gate := _figure(12, Palette.MUTED)
	gate.add_theme_font_override("font", Palette.WORD_FONT)
	gate.text = "Tier 2 opens after wave 100"
	tier.column.add_child(gate)
	_best_wave = _figure(13, Palette.MUTED)
	_best_wave.add_theme_font_override("font", _mono)
	tier.column.add_child(_best_wave)

	var stretch := Control.new()
	stretch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(stretch)
	var battle := Button.new()
	battle.text = "Battle"
	battle.custom_minimum_size = Vector2(0, 56)
	battle.add_theme_font_size_override("font_size", 17)
	for state in ["normal", "hover", "pressed"]:
		var fill := Color(Palette.ACCENT, 0.16 if state == "hover" else (0.06 if state == "pressed" else 0.1))
		battle.add_theme_stylebox_override(state, Palette.card_box(fill, Color(Palette.ACCENT, 0.7), 16))
	battle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	battle.pressed.connect(func(): battle_pressed.emit())
	battle.disabled = progression != null and not progression.writable
	body.add_child(battle)
	_note = Label.new()
	_note.add_theme_color_override("font_color", Palette.MUTED)
	_note.add_theme_font_size_override("font_size", 12)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_note)

	var nav := NavBar.new("battle", workshop.runs, workshop.best_wave)
	nav.chosen.connect(func(id: String):
		if id == "workshop":
			workshop_pressed.emit())
	screen.add_child(Palette.hairline())
	screen.add_child(nav)

	_build_settings()
	_build_milestones()
	if _gift > 0.0:
		_build_gift()
	refresh()


func _process(delta: float) -> void:
	if progression != null and floori(Time.get_unix_time_from_system() / 86400.0) != _daily_day:
		refresh()
	_light_time += delta
	var light := _light.material as ShaderMaterial
	light.set_shader_parameter("centre_px", _light.size * 0.5)
	light.set_shader_parameter("rect_px", _light.size)
	light.set_shader_parameter("tint", Palette.LIGHT)
	light.set_shader_parameter("strength", 1.0)
	# Small enough to fade out inside the emblem, never cut off at its edges.
	light.set_shader_parameter("halo_px", 110.0)
	light.set_shader_parameter("breath", 0.5 - 0.5 * cos(_light_time * TAU / 5.5))


func refresh() -> void:
	if progression != null:
		_gems.text = "◆ %d" % progression.gems
		_daily_day = floori(Time.get_unix_time_from_system() / 86400.0)
		var available := progression.workshop.runs > 0 and _daily_day > progression.last_daily_day and progression.writable
		_daily.disabled = not available
		_daily.text = "+◆ %d daily" % Progression.DAILY_GEMS if available else ("Daily Gems after your first run" if workshop.runs == 0 else "Daily Gems claimed")
		_daily.tooltip_text = "One free claim per UTC day. Gems stay between runs for Cards and Labs."
	_coins.text = Palette.money(workshop.coins)
	_best_number.text = Palette.full(ceilf(workshop.best_number))
	_coin_bonus.text = "×%.2f" % TowerData.value("coins_per_kill", workshop.level("coins_per_kill"))
	_best_wave.text = "Best wave %d · %d run%s" % [progression.best_wave(1) if progression != null and progression.records.has("1") else workshop.best_wave, workshop.runs, "" if workshop.runs == 1 else "s"]


## Says where the report went, from ActivityLog.export_report's result.
func show_exported(result: Dictionary) -> void:
	if result.is_empty():
		show_note("Couldn't write the report.")
		return
	show_note("Saved %s (%d runs). Drop it into the chat.\n%s" % [
		String(result.path).get_file(), int(result.runs), ProjectSettings.globalize_path(String(result.path)).get_base_dir()])


## The Workshop's welcome, over Home, after a new player's first run (D125):
## what the Workshop is, the Coins given to start it, and the way in.
func show_gift(coins: float) -> void:
	_gift = coins
	if is_node_ready():
		_build_gift()


func _build_gift() -> void:
	_gift_panel = _overlay()
	var column: VBoxContainer = _gift_panel.get_meta("column")
	var heading := Label.new()
	heading.text = "The Workshop"
	heading.add_theme_font_size_override("font_size", 16)
	column.add_child(heading)
	var about := Label.new()
	about.text = "Coins you earn in battle stay between runs. Spend them in the Workshop on upgrades every run starts with."
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size = Vector2(260, 0)
	about.add_theme_font_size_override("font_size", 13)
	about.add_theme_color_override("font_color", Palette.SOFT)
	column.add_child(about)
	var given := _figure(20, Palette.COIN)
	given.text = "+● %s to get you started" % Palette.money(_gift)
	column.add_child(given)
	var go := Palette.pill("Open the Workshop", Palette.ACCENT, null, 40)
	go.pressed.connect(func():
		_gift_panel.visible = false
		workshop_pressed.emit())
	column.add_child(go)
	_gift_panel.visible = true


func show_note(text: String) -> void:
	_note.text = text


## Milestones, over the screen (D107): each new digit the best Number reaches
## for the first time pays its Coins once. Reached ones are ticked, and the
## next shows how far the best Number has come towards it.
func _build_milestones() -> void:
	_milestones_panel = _overlay()
	var column: VBoxContainer = _milestones_panel.get_meta("column")
	var head := HBoxContainer.new()
	column.add_child(head)
	var heading := Label.new()
	heading.text = "Milestones"
	heading.add_theme_font_size_override("font_size", 16)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(heading)
	var close := Palette.pill("Close", Palette.SOFT, null, 30)
	close.pressed.connect(func(): _milestones_panel.visible = false)
	head.add_child(close)
	var about := Label.new()
	about.text = "Number and wave rewards pay once." if progression != null else "Your best Number's first new digit pays once."
	about.add_theme_font_size_override("font_size", 12)
	about.add_theme_color_override("font_color", Palette.MUTED)
	column.add_child(about)
	column.add_child(Palette.hairline())
	_milestones_list = VBoxContainer.new()
	_milestones_list.add_theme_constant_override("separation", 10)
	if progression != null:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(300, 350)
		_milestones_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(_milestones_list)
		column.add_child(scroll)
	else:
		column.add_child(_milestones_list)
	_fill_milestones()


func _fill_milestones() -> void:
	for child in _milestones_list.get_children():
		_milestones_list.remove_child(child)
		child.queue_free()
	if progression != null:
		_milestones_list.add_child(_caption("Tier 1 waves · best %d" % progression.best_wave(1)))
		for milestone in Progression.MILESTONES:
			if int(milestone.tier) != 1: continue
			var claimed := "%d:%d" % [int(milestone.tier), int(milestone.wave)] in progression.claimed
			var text := "Wave %d · " % int(milestone.wave)
			if int(milestone.coins) > 0: text += "● %d" % int(milestone.coins)
			elif int(milestone.gems) > 0: text += "◆ %d" % int(milestone.gems)
			else: text += {30: "Labs gate · comes in 1.2", 100: "Tier 2 gate · comes in 1.4"}.get(int(milestone.wave), "Unlock")
			var label := _caption(("✓  " if claimed else "") + text)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			label.add_theme_color_override("font_color", Palette.MUTED if claimed else Palette.TEXT)
			_milestones_list.add_child(label)
		_milestones_list.add_child(Palette.hairline())
		_milestones_list.add_child(_caption("Best Number"))
	var next := workshop.next_milestone()
	for milestone in Guesses.MILESTONES:
		var reached := workshop.best_number >= float(milestone.number)
		var row := HBoxContainer.new()
		_milestones_list.add_child(row)
		var number := _figure(16, Palette.TEXT if reached or milestone == next else Palette.MUTED)
		# Written out whole, however big: a milestone is a round number.
		number.text = Palette.full(float(milestone.number), INF)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(number)
		var reward := _figure(13, Palette.COIN if not reached else Palette.MUTED)
		reward.text = ("✓  " if reached else "") + "● " + Palette.money(float(milestone.coins))
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(reward)
		if milestone == next:
			var progress := ProgressBar.new()
			progress.show_percentage = false
			progress.custom_minimum_size = Vector2(0, 3)
			progress.max_value = float(milestone.number)
			progress.value = workshop.best_number
			var back := StyleBoxFlat.new()
			back.bg_color = Palette.HAIRLINE
			var fill := StyleBoxFlat.new()
			fill.bg_color = Palette.ACCENT
			progress.add_theme_stylebox_override("background", back)
			progress.add_theme_stylebox_override("fill", fill)
			_milestones_list.add_child(progress)


## A panel over the whole screen, shaded, with a card in the middle; its
## column is kept as the panel's "column" meta.
func _overlay() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0, 0, 0, 0.6)
	panel.add_theme_stylebox_override("panel", shade)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var centre := CenterContainer.new()
	panel.add_child(centre)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Palette.panel_box())
	card.custom_minimum_size = Vector2(300, 0)
	centre.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)
	panel.set_meta("column", column)
	return panel


## Settings, over the screen: the music, the report, and which build this is.
func _build_settings() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.visible = false
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0, 0, 0, 0.6)
	_settings_panel.add_theme_stylebox_override("panel", shade)
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_settings_panel)
	var centre := CenterContainer.new()
	_settings_panel.add_child(centre)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Palette.panel_box())
	card.custom_minimum_size = Vector2(300, 0)
	centre.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	card.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	var heading := Label.new()
	heading.text = "Settings"
	heading.add_theme_font_size_override("font_size", 16)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(heading)
	var close := Palette.pill("Close", Palette.SOFT, null, 30)
	close.pressed.connect(func():
		_settings_panel.visible = false
		_reset_armed = false
		_reset.text = "Reset progress")
	head.add_child(close)
	column.add_child(Palette.hairline())
	var music_toggle := CheckButton.new()
	music_toggle.text = "Music"
	music_toggle.button_pressed = settings.music
	music_toggle.add_theme_color_override("font_color", Palette.TEXT)
	music_toggle.add_theme_color_override("font_hover_color", Palette.TEXT)
	music_toggle.add_theme_color_override("font_pressed_color", Palette.TEXT)
	music_toggle.toggled.connect(func(on: bool):
		settings.music = on
		settings_changed.emit())
	column.add_child(music_toggle)
	var export := Button.new()
	export.text = "Export report"
	export.custom_minimum_size = Vector2(0, 44)
	export.pressed.connect(func():
		_settings_panel.visible = false
		export_pressed.emit())
	column.add_child(export)
	_build_testing(column)
	# The roadmap version and the commit (D079), so a screenshot or a report
	# says which build it came from.
	var build := Label.new()
	build.text = "v%s · %s" % [ActivityLog.version(), ActivityLog.game_version().left(7)]
	build.add_theme_font_override("font", _mono)
	build.add_theme_font_size_override("font_size", 11)
	build.add_theme_color_override("font_color", Palette.MUTED)
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(build)


## Testing, for the owner and the agents while the game is built (D097): free
## Coins and a reset to a fresh Workshop. None of it is meant to ship as it is.
func _build_testing(column: VBoxContainer) -> void:
	column.add_child(Palette.hairline())
	var heading := Label.new()
	heading.text = "Testing"
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Palette.MUTED)
	column.add_child(heading)
	var gifts := HBoxContainer.new()
	gifts.add_theme_constant_override("separation", 8)
	column.add_child(gifts)
	for amount in TEST_COINS:
		var gift := Palette.pill("+● " + Palette.money(amount), Palette.COIN, _mono, 32)
		gift.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gift.pressed.connect(func():
			test_coins_pressed.emit(amount)
			refresh())
		gifts.add_child(gift)
	_reset = Palette.pill("Reset progress", Palette.WARNING, null, 32)
	_reset.pressed.connect(_press_reset)
	column.add_child(_reset)


## The first press asks; the second, while it's asking, resets.
func _press_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset.text = "Press again to wipe all progress"
		return
	_reset_armed = false
	_reset.text = "Reset progress"
	_settings_panel.visible = false
	reset_pressed.emit()


## A card of the home column: a quiet panel with its lines centred.
func _card() -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.card_box())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	return {"panel": panel, "column": column}


func _caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Palette.MUTED)
	return label


func _figure(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _mono_bold)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	return label


static func _spaced(font: FontVariation, spacing: int) -> FontVariation:
	font.spacing_glyph = spacing
	return font


func _margined(child: Control, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(child)
	return margin
