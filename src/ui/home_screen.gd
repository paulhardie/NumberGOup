extends Control
## Between runs, laid out after The Tower's home (D096): Coins and the top
## pills, the game's name over the best Number in its light, the Coin bonus
## and the tier, and the Battle button, with the bar to the Workshop below.
## Placeholders stand where the roadmap's later pieces will go (Milestones,
## Missions, tiers past 1, and Cards, Labs and Weapons in the bar); they are
## shown, locked, and do nothing. Settings (Music, Export report and the
## build) open over the screen.

const Workshop = preload("res://src/tower/workshop.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")
const Palette = preload("res://src/ui/palette.gd")
const Settings = preload("res://src/settings.gd")
const NavBar = preload("res://src/ui/nav_bar.gd")

signal battle_pressed
signal workshop_pressed
## The owner wants the activity log as a report file (D077).
signal export_pressed
## A setting was changed here, to be written.
signal settings_changed

## The best Number, large and thin in the light, as the battle draws the Number.
const EMBLEM_HEIGHT := 230
const EMBLEM_NUMBER_PX := 64

var workshop: Workshop
## The player's settings, changed in place; fresh ones if not set.
var settings: Settings
var _coins: Label
var _best_number: Label
var _coin_bonus: Label
var _best_wave: Label
var _settings_panel: PanelContainer
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
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	var missions := Palette.pill("Missions", Palette.SOFT)
	missions.disabled = true
	missions.tooltip_text = "Coming later"
	top.add_child(missions)
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
	milestones.disabled = true
	milestones.tooltip_text = "Coming later"
	milestones.custom_minimum_size = Vector2(200, 40)
	milestones.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(milestones)

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
	body.add_child(battle)
	_note = Label.new()
	_note.add_theme_color_override("font_color", Palette.MUTED)
	_note.add_theme_font_size_override("font_size", 12)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_note)

	var nav := NavBar.new("battle")
	nav.chosen.connect(func(id: String):
		if id == "workshop":
			workshop_pressed.emit())
	screen.add_child(Palette.hairline())
	screen.add_child(nav)

	_build_settings()
	refresh()


func _process(delta: float) -> void:
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
	_coins.text = Palette.number(workshop.coins)
	_best_number.text = Palette.number(ceilf(workshop.best_number))
	_coin_bonus.text = "×%.2f" % TowerData.value("coins_per_kill", workshop.level("coins_per_kill"))
	_best_wave.text = "Best wave %d · %d run%s" % [workshop.best_wave, workshop.runs, "" if workshop.runs == 1 else "s"]


## Says where the report went, from ActivityLog.export_report's result.
func show_exported(result: Dictionary) -> void:
	if result.is_empty():
		show_note("Couldn't write the report.")
		return
	show_note("Saved %s (%d runs). Drop it into the chat.\n%s" % [
		String(result.path).get_file(), int(result.runs), ProjectSettings.globalize_path(String(result.path)).get_base_dir()])


func show_note(text: String) -> void:
	_note.text = text


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
	close.pressed.connect(func(): _settings_panel.visible = false)
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
	# The roadmap version and the commit (D079), so a screenshot or a report
	# says which build it came from.
	var build := Label.new()
	build.text = "v%s · %s" % [ActivityLog.version(), ActivityLog.game_version().left(7)]
	build.add_theme_font_override("font", _mono)
	build.add_theme_font_size_override("font_size", 11)
	build.add_theme_color_override("font_color", Palette.MUTED)
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(build)


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
