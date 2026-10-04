extends Control
## Between runs (D096, premium minimal since D138): the currencies as chips
## along the top, the best Number in its light with its next digit's reward
## under it, a line with the tier and the best wave, the one lit Battle
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
const Overlay = preload("res://src/ui/overlay.gd")
const Progression = preload("res://src/tower/progression.gd")

signal battle_pressed
signal workshop_pressed
signal cards_pressed
## The owner wants the activity log as a report file (D077).
signal export_pressed
## A setting was changed here, to be written.
signal settings_changed
## Testing (D097): free Coins for the Workshop, and a fresh start.
signal test_coins_pressed(amount: float)
signal test_gems_pressed(amount: int)
signal reset_pressed
signal daily_pressed

## The free Coins the testing buttons give.
const TEST_COINS := [1000.0, 100000.0]
## Testing's free Gems, for trying Cards (D146).
const TEST_GEMS := 500

## The best Number, large and thin in the light, as the battle draws the Number.
const EMBLEM_HEIGHT := 250
const EMBLEM_NUMBER_PX := 72
## Written in full to a trillion (D154), a long best shrinks to fit the
## emblem's width rather than being cut off, down to this size.
const EMBLEM_NUMBER_MIN_PX := 28
## The Coins count-up (D141): its shortest and longest, the extra for each
## digit of the gain, and the chip's pop as it lands.
const COUNT_SECONDS := 0.6
const COUNT_SECONDS_MOST := 1.6
const COUNT_SECONDS_PER_DIGIT := 0.25
const COUNT_POP := 1.06

var workshop: Workshop
var progression: Progression
var _gems: Label
var _daily: Button
var _daily_day := -1
## The player's settings, changed in place; fresh ones if not set.
var settings: Settings
var _coins: Label
## Coins counting up after a run (D141): the tween, while it runs.
var _coin_count: Tween
var _best_number: Label
## The best Number's emblem, and the next digit's reward under it.
var _emblem: Button
var _next_digit: Label
var _battle: Button
## The Battle button's box, whose glow breathes with the Number's light.
var _battle_box: StyleBoxFlat
var _best_wave: Label
## The milestones sheet while it's up, and the list inside it.
var _milestones_panel: Overlay
var _milestones_list: VBoxContainer
## The Workshop's welcome after a first run (D125), and the Coins it announces.
var _gift_panel: Overlay
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
	open_settings.pressed.connect(_open_settings)
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

	# The emblem: the best Number, in the same light as the battle's, with no
	# ring round it (the owner, D138). Tapping it opens the milestones.
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
	_best_number.resized.connect(_fit_best_number)
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
			workshop_pressed.emit()
		elif id == "cards":
			cards_pressed.emit())
	screen.add_child(Palette.hairline())
	screen.add_child(nav)

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
	if _coin_count == null or not _coin_count.is_running():
		_coins.text = "● " + Palette.money(workshop.coins)
	_best_number.text = Palette.full(ceilf(workshop.best_number))
	_fit_best_number()
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
	# Answered, not dismissed: it's the way into the Workshop.
	var sheet := Overlay.new(Overlay.Kind.SHEET, false)
	_gift_panel = sheet
	sheet.closed.connect(func(): if _gift_panel == sheet: _gift_panel = null)
	sheet.heading("The Workshop")
	sheet.text("Coins you earn in battle stay between runs. Spend them in the Workshop on upgrades every run starts with.", Palette.SOFT, 13)
	var given := _figure(20, Palette.COIN)
	given.text = "+● %s to get you started" % Palette.money(_gift)
	sheet.column.add_child(given)
	sheet.action("Open the Workshop", Palette.ACCENT, func(): workshop_pressed.emit(), true, 40)
	sheet.show_over(self)


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


## Back from a battle, the Coins chip counts up from what it read when the
## player left Home to what they have now (D141), then gives a small pop.
## Longer for a bigger haul, from 0.6 s to 1.6 s.
func count_coins_from(start: float) -> void:
	var gain := workshop.coins - start
	if gain <= 0.0:
		return
	var seconds := clampf(COUNT_SECONDS + COUNT_SECONDS_PER_DIGIT * log(gain + 1.0) / log(10.0), COUNT_SECONDS, COUNT_SECONDS_MOST)
	_show_coins(start)
	if _coin_count != null:
		_coin_count.kill()
	_coin_count = create_tween()
	_coin_count.tween_method(_show_coins, start, workshop.coins, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var chip: Control = _coins.get_parent()
	_coin_count.tween_callback(func(): chip.pivot_offset = chip.size * 0.5)
	_coin_count.tween_property(chip, "scale", Vector2.ONE * COUNT_POP, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_coin_count.tween_property(chip, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_coins(value: float) -> void:
	_coins.text = "● " + Palette.money(floorf(value))


func show_note(text: String) -> void:
	_note.text = text


## Milestones, over the screen (D107): each new digit the best Number reaches
## for the first time pays its Coins once. Reached ones are ticked, and the
## next shows how far the best Number has come towards it.
func _open_milestones() -> void:
	var sheet := Overlay.new()
	_milestones_panel = sheet
	sheet.closed.connect(func(): if _milestones_panel == sheet: _milestones_panel = null)
	sheet.heading("Milestones", true)
	sheet.text("Number and wave rewards pay once." if progression != null else "Your best Number's first new digit pays once.", Palette.MUTED)
	sheet.rule()
	_milestones_list = VBoxContainer.new()
	_milestones_list.add_theme_constant_override("separation", 10)
	if progression != null:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(300, 350)
		_milestones_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(_milestones_list)
		sheet.column.add_child(scroll)
	else:
		sheet.column.add_child(_milestones_list)
	_fill_milestones()
	sheet.show_over(self)


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


## Settings, over the screen: the music, the report, and which build this is.
func _open_settings() -> void:
	var sheet := Overlay.new()
	# Reset asks twice, and asks again from scratch the next time Settings opens.
	sheet.closed.connect(func(): _reset_armed = false)
	sheet.heading("Settings", true)
	sheet.rule()
	var music_toggle := CheckButton.new()
	music_toggle.text = "Music"
	music_toggle.button_pressed = settings.music
	music_toggle.add_theme_color_override("font_color", Palette.TEXT)
	music_toggle.add_theme_color_override("font_hover_color", Palette.TEXT)
	music_toggle.add_theme_color_override("font_pressed_color", Palette.TEXT)
	music_toggle.toggled.connect(func(on: bool):
		settings.music = on
		settings_changed.emit())
	sheet.column.add_child(music_toggle)
	var export := Button.new()
	export.text = "Export report"
	export.custom_minimum_size = Vector2(0, 44)
	export.pressed.connect(func():
		sheet.dismiss()
		export_pressed.emit())
	sheet.column.add_child(export)
	_build_testing(sheet)
	# The roadmap version and the commit (D079), so a screenshot or a report
	# says which build it came from.
	var build := Label.new()
	build.text = "v%s · %s" % [ActivityLog.version(), ActivityLog.game_version().left(7)]
	build.add_theme_font_override("font", _mono)
	build.add_theme_font_size_override("font_size", 11)
	build.add_theme_color_override("font_color", Palette.MUTED)
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet.column.add_child(build)
	sheet.show_over(self)


## Testing, for the owner and the agents while the game is built (D097): free
## Coins and Gems (D146) and a reset to a fresh Workshop. None of it is meant to ship as it is.
func _build_testing(sheet: Overlay) -> void:
	sheet.rule()
	sheet.text("Testing", Palette.MUTED)
	var gifts := HBoxContainer.new()
	gifts.add_theme_constant_override("separation", 8)
	sheet.column.add_child(gifts)
	for amount in TEST_COINS:
		var gift := Palette.pill("+● " + Palette.money(amount), Palette.COIN, _mono, 32)
		gift.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gift.pressed.connect(func():
			test_coins_pressed.emit(amount)
			refresh())
		gifts.add_child(gift)
	if progression != null:
		var gems := Palette.pill("+◆ %d" % TEST_GEMS, Palette.ACCENT, _mono, 32)
		gems.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gems.pressed.connect(func():
			test_gems_pressed.emit(TEST_GEMS)
			refresh())
		gifts.add_child(gems)
	_reset = Palette.pill("Reset progress", Palette.WARNING, null, 32)
	_reset.pressed.connect(_press_reset)
	sheet.column.add_child(_reset)


## The first press asks; the second, while it's asking, resets.
func _press_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset.text = "Press again to wipe all progress"
		return
	_reset_armed = false
	_reset.text = "Reset progress"
	Overlay.close_current(self)
	reset_pressed.emit()


## Shrinks the best Number until it fits the emblem's width. Before the
## emblem has a size it stays at full size, so it never starts small and grows.
func _fit_best_number() -> void:
	var font := _best_number.get_theme_font("font")
	var width := _best_number.size.x
	var font_size := EMBLEM_NUMBER_PX
	while width > 0.0 and font_size > EMBLEM_NUMBER_MIN_PX and font.get_string_size(_best_number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		font_size -= 2
	_best_number.add_theme_font_size_override("font_size", font_size)


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
