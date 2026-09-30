extends Control
## Between runs (D096, premium minimal since D138): the currencies as chips
## along the top, the best Number in its light inside a ring filling towards
## its next digit, a line with the tier and the best wave, the one lit Battle
## button, and the dock below. Tapping the Number opens the milestones (D107).
## The dock shows Cards and Labs, locked, once a run reaches The Tower's wave
## for them (D125); the tier chooser comes back with Tier 2 (1.4). Settings
## (Music, Export report and the build) open over the screen. A first run's end opens the Workshop's welcome (D125).

const Workshop = preload("res://src/tower/workshop.gd")
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
const EMBLEM_HEIGHT := 250
const EMBLEM_NUMBER_PX := 72

var workshop: Workshop
var progression: Progression
var _gems: Label
var _daily: Button
var _daily_day := -1
## The player's settings, changed in place; fresh ones if not set.
var settings: Settings
var _coins: Label
var _best_number: Label
## The ring round the best Number, and the next digit's reward under it.
var _ring: DigitRing
var _emblem: Button
var _next_digit: Label
var _battle: Button
## The Battle button's box, whose glow breathes with the Number's light.
var _battle_box: StyleBoxFlat
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

	# One line along the top: the currencies as chips, the daily Gems beside
	# them while there are some to claim, the name small in the middle, and
	# Settings as a glyph (D138).
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.custom_minimum_size = Vector2(0, 40)
	screen.add_child(_margined(top, 20, 12))
	var coins := Palette.chip(Palette.COIN)
	top.add_child(coins.panel)
	_coins = coins.label
	if progression != null:
		var gems := Palette.chip(Palette.ACCENT)
		top.add_child(gems.panel)
		_gems = gems.label
		_daily = Palette.pill("+◆ %d" % Progression.DAILY_GEMS, Palette.ACCENT, Palette.weight(Palette.NUMBER_FONT, 600), 30)
		_daily.pressed.connect(func(): daily_pressed.emit())
		top.add_child(_daily)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	var open_settings := Palette.pill("•••", Palette.SOFT, null, 36)
	open_settings.tooltip_text = "Settings"
	open_settings.custom_minimum_size = Vector2(44, 36)
	open_settings.pressed.connect(func(): _settings_panel.visible = true)
	top.add_child(open_settings)

	var body := VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	var body_margin := _margined(body, 0, 20)
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(body_margin)

	var title := Label.new()
	title.text = "NUMBER GO UP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _spaced(Palette.weight(Palette.WORD_FONT, 400), 4))
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Palette.MUTED)
	body.add_child(title)
	var lift := Control.new()
	lift.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(lift)

	# The emblem: the best Number, in the same light as the battle's, inside a
	# ring filling towards its next digit's milestone. Tapping it opens the
	# milestones (D138).
	var emblem := Button.new()
	emblem.flat = true
	emblem.custom_minimum_size = Vector2(0, EMBLEM_HEIGHT)
	emblem.clip_contents = true
	emblem.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus"]:
		emblem.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	emblem.pressed.connect(_open_milestones)
	_emblem = emblem
	Palette.press(emblem)
	body.add_child(emblem)
	_light = ColorRect.new()
	_light.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_light.material = ShaderMaterial.new()
	(_light.material as ShaderMaterial).shader = preload("res://src/ui/number_glow.gdshader")
	emblem.add_child(_light)
	_ring = DigitRing.new()
	_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem.add_child(_ring)
	_best_number = Label.new()
	_best_number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_best_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_best_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var thin := Palette.weight(Palette.WORD_FONT, 200)
	thin.variation_opentype[TextServerManager.get_primary_interface().name_to_tag("opsz")] = 32
	_best_number.add_theme_font_override("font", thin)
	_best_number.add_theme_font_size_override("font_size", EMBLEM_NUMBER_PX)
	_best_number.add_theme_color_override("font_color", Palette.NUMBER)
	emblem.add_child(_best_number)
	body.add_child(_caption("best Number"))
	_next_digit = _caption("")
	_next_digit.add_theme_color_override("font_color", Color(Palette.COIN, 0.85))
	body.add_child(_next_digit)

	var drop := Control.new()
	drop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(drop)
	# Tier 1 is all there is until 1.4 (D079), so the tier rides on the
	# Battle button and this line; the chooser comes back with Tier 2.
	_best_wave = _caption("")
	body.add_child(_best_wave)

	# Battle: the one filled, lit button, its glow breathing with the
	# Number's light (D138).
	_battle = Button.new()
	_battle.custom_minimum_size = Vector2(0, 66)
	_battle.focus_mode = Control.FOCUS_NONE
	_battle_box = _battle_box_for(Palette.ACCENT)
	_battle.add_theme_stylebox_override("normal", _battle_box)
	_battle.add_theme_stylebox_override("hover", _battle_box_for(Palette.ACCENT.lightened(0.08)))
	_battle.add_theme_stylebox_override("pressed", _battle_box_for(Palette.ACCENT.darkened(0.12)))
	_battle.add_theme_stylebox_override("disabled", _battle_box_for(Color(Palette.ACCENT, 0.25)))
	_battle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_battle.pressed.connect(func(): battle_pressed.emit())
	_battle.disabled = progression != null and not progression.writable
	Palette.press(_battle)
	body.add_child(_battle)
	var words := VBoxContainer.new()
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_battle.add_child(words)
	var go := Label.new()
	go.text = "▶  Battle"
	go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go.add_theme_font_override("font", Palette.weight(Palette.WORD_FONT, 600))
	go.add_theme_font_size_override("font_size", 19)
	go.add_theme_color_override("font_color", Palette.GROUND)
	go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(go)
	var tier := Label.new()
	tier.text = "Tier 1"
	tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier.add_theme_font_size_override("font_size", 11)
	tier.add_theme_color_override("font_color", Color(Palette.GROUND, 0.7))
	tier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(tier)
	_note = Label.new()
	_note.add_theme_color_override("font_color", Palette.MUTED)
	_note.add_theme_font_size_override("font_size", 12)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_note)

	var nav := NavBar.new("battle", workshop.runs, workshop.best_wave, progression)
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
	var breath := 0.5 - 0.5 * cos(_light_time * TAU / 5.5)
	light.set_shader_parameter("breath", breath)
	_battle_box.shadow_size = roundi(lerpf(8.0, 20.0, breath))


func refresh() -> void:
	if progression != null:
		_gems.text = "◆ %d" % progression.gems
		_daily_day = floori(Time.get_unix_time_from_system() / 86400.0)
		var available := progression.workshop.runs > 0 and _daily_day > progression.last_daily_day and progression.writable
		# The claim sits beside the Gems only while there is one to take.
		_daily.disabled = not available
		_daily.visible = available
		_daily.tooltip_text = "Today's free Gems. One claim per UTC day; Gems stay between runs for Cards and Labs."
	_coins.text = "● " + Palette.money(workshop.coins)
	_best_number.text = Palette.full(ceilf(workshop.best_number))
	_ring.fill = digit_progress(workshop)
	_ring.queue_redraw()
	var next := workshop.next_milestone()
	_next_digit.text = "next digit  ● %s" % Palette.money(float(next.coins)) if not next.is_empty() else "every digit reached"
	_best_wave.text = "Tier 1  ·  best wave %d  ·  %d run%s" % [progression.best_wave(1) if progression != null and progression.records.has("1") else workshop.best_wave, workshop.runs, "" if workshop.runs == 1 else "s"]


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


## How far the best Number has come from its last milestone towards the
## next, 0 to 1; 1 once every milestone is reached. The ring shows it.
static func digit_progress(from: Workshop) -> float:
	var next := from.next_milestone()
	if next.is_empty():
		return 1.0
	var floor_number := 0.0
	for milestone in Guesses.MILESTONES:
		if float(milestone.number) < float(next.number):
			floor_number = float(milestone.number)
	return clampf((from.best_number - floor_number) / (float(next.number) - floor_number), 0.0, 1.0)


func _open_milestones() -> void:
	_fill_milestones()
	_milestones_panel.visible = true


## The Battle button's box: filled in the accent, rounded, glowing.
static func _battle_box_for(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(18)
	box.corner_detail = 10
	box.anti_aliasing = true
	box.shadow_color = Color(fill, 0.35)
	box.shadow_size = 12
	return box


## A thin ring round the best Number: a faint track, and an arc in the
## accent from the top, clockwise, as far as `fill` has come.
class DigitRing extends Control:
	const Palette = preload("res://src/ui/palette.gd")
	const WIDTH := 2.0
	var fill := 0.0

	func _draw() -> void:
		# Just outside the light's halo, so the ring frames it rather than
		# cutting it off.
		var radius := minf(size.x, size.y) * 0.5 - 6.0
		var centre := size * 0.5
		draw_arc(centre, radius, 0.0, TAU, 128, Color(1, 1, 1, 0.07), WIDTH, true)
		if fill > 0.0:
			draw_arc(centre, radius, -PI * 0.5, -PI * 0.5 + TAU * fill, maxi(8, roundi(128 * fill)), Color(Palette.ACCENT, 0.8), WIDTH, true)


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
