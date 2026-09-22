extends Control

const SAVE_INTERVAL_SECONDS := 20.0
const BACKGROUND_TOP := Color("212224")
const BACKGROUND_BOTTOM := Color("18191b")
const BACKGROUND := BACKGROUND_BOTTOM
const SURFACE := Color("232426")
const SURFACE_HOVER := Color("2b2c2f")
const TEXT := Color("ececea")
const MUTED_TEXT := Color(0.925, 0.925, 0.918, 0.45)
const FAINT_TEXT := Color(0.925, 0.925, 0.918, 0.3)
const DIVIDER := Color(0.925, 0.925, 0.918, 0.08)

# One accent carries every positive state, and a single warning carries every
# negative one. Severity inside a valence (routine tax against a boss hit) is
# motion and duration, never an extra hue: more colours on this HUD read as
# noise rather than as meaning.
const ACCENT := Color("8fbfa8")
const WARNING := Color("d68e5c")
# A critical tick is the one moment worth lifting above the accent, so it
# brightens towards white instead of introducing a third colour.
const CRITICAL := Color("f5f5f3")
const DANGER := WARNING
const BOSS_DANGER := WARNING
const COIN_ACCENT := ACCENT
const WORKSHOP_ACCENT := ACCENT
const LABS_ACCENT := ACCENT
const CARDS_ACCENT := ACCENT

const CATEGORY_ICON := {
	"attack": 6, # IconGlyph.Kind.CHART
	"defense": 9, # IconGlyph.Kind.CHIP
	"utility": 13, # IconGlyph.Kind.COIN
	"ultimates": 12, # IconGlyph.Kind.SPARKLE
}

## The category strip's height. It sits above the nav dock between runs, and a
## run has no dock, so the same strip can sit flush there later.
const CATEGORY_STRIP_HEIGHT := 64

const TAB_IDS: Array[String] = ["number", "workshop"]
const TAB_NAMES := {"number": "RUN", "workshop": "WORKSHOP", "settings": "SETTINGS"}
## Lifetime Number required before a row inside the Knowledge sheet can be used.
## These were the Labs and Cards dock gates before D016 moved them inside.
const RESEARCH_UNLOCK := 1000.0

var state := GameState.new()
# Lifetime Number required before a dock icon even appears tappable. Each
# tab's own feature may still gate further inside itself (e.g. Labs needs
# Workshop level 12). "settings" gates the stats/settings sheet the same way
# the old top-right MENU button used to appear only once the player was in.
var tab_unlock_lifetime := {"number": 0.0, "workshop": 10.0, "settings": 10.0}
var save_elapsed := 0.0
var refresh_elapsed := 0.0

var number_button: Button
var number_label: Label
var number_col: VBoxContainer
var rate_label: Label
var tap_hint: Label
var coins_label: Label
var knowledge_label: Label
var floating_text_layer: Control
var ring: RingArc
var stage_glow: TextureRect
var tracked_font: FontVariation
var number_flash_tween: Tween
# Smoothed log10 of the displayed Number (log10(mantissa) + exponent), eased
# toward the true value every frame instead of snapping to it. -INF means 0.
var display_log_value := -INF

const NUMBER_SMOOTH_RATE := 12.0

var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween

var wave_label: Label
var tier_button: Button
var boss_label: Label
var boss_separator: Label
var encounter_label: Label
var brace_button: Button
var run_button: Button

var died_screen: Control
var died_wave_label: Label
var died_coins_label: Label
var died_knowledge_label: Label
var died_peak_label: Label
var died_cause_label: Label
var died_knowledge_door: Button

var nav_dock: NavDock
var drawer: Control
var drawer_content: VBoxContainer
var stats_grid: GridContainer

var workshop_header: Label
var workshop_board_row: HBoxContainer
var workshop_detail: VBoxContainer
var workshop_category_header: Label
var workshop_purpose: Label
var workshop_buy_when: Label
var workshop_multiplier_label: Label
## Which multi-buy step each category is set to, by index into
## GameState.BUY_STEPS. Presentation only: it is not worth a save key until a
## player would miss it across sessions.
var buy_step_index: Dictionary = {}
var stat_info_screen: Control
var stat_info_title: Label
var stat_info_body: Label
var stat_info_level: Label
var stat_info_max: Label
var workshop_tab_buttons: Dictionary = {}
var workshop_tab_icons: Dictionary = {}
var workshop_tab_labels: Dictionary = {}
var workshop_lock_badges: Dictionary = {}

var labs_content: VBoxContainer
var cards_content: VBoxContainer
var cards_knowledge_label: Label
var knowledge_sheet: Control
var knowledge_research_header: Control
var knowledge_insight_header: Control
var coins_button: Button
var knowledge_button: Button

var screens: Dictionary = {}
# The content root inside each slide-up screen, kept separately so it (not
# the screen wrapper) is what tweens into place on selection.
var tab_panels: Dictionary = {}
var current_tab := "number"
var offline_message := ""
var drawer_elapsed := 0.0
var dock_signature := ""
var audio_feedback: AudioFeedback
var background_rect: TextureRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	var offline := state.load()
	if not offline.amount.is_zero():
		offline_message = "WELCOME BACK  +" + offline.amount.format_value() + "  /  " + _format_duration(offline.seconds)
		if offline.capped:
			offline_message += " (12H CAP)"
	_snap_number_display()
	_refresh_number_display()
	_sync_ambience()
	_refresh_all()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		state.save()

func _process(delta: float) -> void:
	var events := state.advance(delta)
	for event in events:
		if event.is_critical:
			_spawn_floating_text(_production_feedback_text(event.amount, true, state.is_output_banking()), CRITICAL, floating_text_layer.size * Vector2(0.5, 0.42))
			_pulse_number(1.06)
			_flash_number(CRITICAL)
		elif event.type == "tax_collection":
			_show_toast("HIT  -" + event.amount.format_value(), DANGER)
			_flash_number(DANGER)
			_pulse_stage_impact(DANGER)
		elif event.type == "boss_collection":
			_show_toast("BOSS HIT  -" + event.amount.format_value(), BOSS_DANGER)
			_flash_number(BOSS_DANGER, 0.5)
			_pulse_stage_impact(BOSS_DANGER)
			_shake_number()
			if state.settings.haptics:
				Input.vibrate_handheld(35)
		elif event.type == "boss_clear":
			_show_toast("BOSS CLEARED  ·  +" + event.amount.format_value() + " COINS", CRITICAL)
		elif event.type == "tier_unlock":
			_show_toast("TIER " + event.amount.format_value() + " UNLOCKED", CRITICAL)
		elif event.type == "second_wind":
			_show_toast("SECOND WIND  ·  " + event.amount.format_value() + " LEFT", CRITICAL)
			_flash_number(CRITICAL, 0.6)
			_pulse_stage_impact(CRITICAL)
			_shake_number()
		elif event.type == "wave_death":
			_show_died_screen(state.last_run_summary)
			_snap_number_display()
			state.save()
	_advance_display_number(delta)
	_refresh_number_display()
	_update_stage_colour()
	save_elapsed += delta
	refresh_elapsed += delta
	drawer_elapsed += delta
	if save_elapsed >= SAVE_INTERVAL_SECONDS:
		save_elapsed = 0.0
		state.save()
	if refresh_elapsed >= 0.12:
		refresh_elapsed = 0.0
		_refresh_all()
	if drawer.visible and drawer_elapsed >= 0.5:
		drawer_elapsed = 0.0
		_refresh_drawer()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tap_number") and not drawer.visible and not died_screen.visible and current_tab == "number":
		_tap_number()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	# A flat fill underneath so High Contrast can simply hide the gradient.
	var base := ColorRect.new()
	base.color = Color.BLACK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	background_rect = TextureRect.new()
	background_rect.texture = _make_vertical_gradient(BACKGROUND_TOP, BACKGROUND_BOTTOM)
	background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)

	var content_area := Control.new()
	content_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content_area)
	_build_number_screen(content_area)
	_build_workshop_screen(content_area)

	_build_toast()

	nav_dock = NavDock.new()
	nav_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nav_dock.offset_top = -92
	add_child(nav_dock)
	nav_dock.tab_selected.connect(_on_dock_tab_selected)

	_build_drawer()
	_build_knowledge_sheet()
	_build_stat_info()
	_build_died_screen()

	audio_feedback = AudioFeedback.new()
	add_child(audio_feedback)

	_select_tab("number")

## Registers a tab's screen and its fade/slide tween target together, since
## every other builder in this file works through _build_flat_screen instead.
func _register_screen(tab_id: String, screen: Control) -> void:
	screens[tab_id] = screen
	tab_panels[tab_id] = screen

## The run screen, staged top to bottom: permanent currency, the run's state
## line, the ring stage, then the run's own controls sitting above the tab bar.
## Every control is added after the tap target so it takes input first.
func _build_number_screen(parent: Control) -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(screen)
	_register_screen("number", screen)

	number_button = Button.new()
	number_button.flat = true
	number_button.focus_mode = Control.FOCUS_NONE
	number_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	number_button.tooltip_text = "Tap to make Number go up"
	number_button.pressed.connect(_tap_number)
	screen.add_child(number_button)

	_build_currency_stack(screen)
	_build_wave_line(screen)
	_build_stage(screen)
	_build_run_controls(screen)

	floating_text_layer = Control.new()
	floating_text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_text_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(floating_text_layer)

## Permanent currency only: what survives the run, so it reads as a different
## class of thing from the run state below it.
## A currency is the door to its own spend (D016): Coins open the Workshop and
## Knowledge opens the Knowledge sheet, which is why neither needs a dock seat.
func _build_currency_stack(parent: Control) -> void:
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	stack.offset_left = 22
	stack.offset_top = 26
	stack.add_theme_constant_override("separation", 4)
	parent.add_child(stack)
	coins_button = _make_currency_row(stack, IconGlyph.Kind.COIN, ACCENT, 17.0, 16, TEXT)
	coins_label = coins_button.get_meta("value_label")
	coins_button.tooltip_text = "Open the Workshop"
	coins_button.pressed.connect(func(): _on_dock_tab_selected("workshop"))
	knowledge_button = _make_currency_row(stack, IconGlyph.Kind.DIAMOND, MUTED_TEXT, 15.0, 15, Color(0.925, 0.925, 0.918, 0.7))
	knowledge_label = knowledge_button.get_meta("value_label")
	knowledge_button.tooltip_text = "Spend Knowledge"
	knowledge_button.pressed.connect(_open_knowledge_sheet)

func _make_currency_row(parent: Control, icon_kind: int, icon_colour: Color, icon_size: float, font_size: int, text_colour: Color) -> Button:
	var button := Button.new()
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(96, 30)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(button)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.add_theme_constant_override("separation", 7)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var icon_wrap := CenterContainer.new()
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_wrap.add_child(IconGlyph.new(icon_kind, icon_colour, icon_size))
	row.add_child(icon_wrap)
	var value_wrap := CenterContainer.new()
	value_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value_wrap)
	var label := _make_label("", font_size, HORIZONTAL_ALIGNMENT_LEFT, text_colour)
	value_wrap.add_child(label)
	button.set_meta("value_label", label)
	return button

## Wave, tier and the boss warning on one line. Tier doubles as the selector:
## between runs it cycles to the next unlocked tier.
func _build_wave_line(parent: Control) -> void:
	var line := HBoxContainer.new()
	line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	line.offset_top = 112
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 10)
	parent.add_child(line)

	wave_label = _make_tracked_label("WAVE 1", 14, Color(0.925, 0.925, 0.918, 0.8))
	line.add_child(wave_label)
	line.add_child(_make_tracked_label("·", 14, Color(0.925, 0.925, 0.918, 0.25)))
	tier_button = Button.new()
	tier_button.flat = true
	tier_button.focus_mode = Control.FOCUS_NONE
	tier_button.add_theme_font_size_override("font_size", 14)
	tier_button.add_theme_constant_override("outline_size", 0)
	tier_button.add_theme_color_override("font_color", MUTED_TEXT)
	tier_button.add_theme_color_override("font_hover_color", ACCENT)
	tier_button.add_theme_color_override("font_pressed_color", ACCENT)
	tier_button.add_theme_color_override("font_disabled_color", MUTED_TEXT)
	tier_button.pressed.connect(_on_tier_pressed)
	line.add_child(tier_button)
	boss_separator = _make_tracked_label("·", 14, Color(0.925, 0.925, 0.918, 0.25))
	line.add_child(boss_separator)
	boss_label = _make_tracked_label("", 14, WARNING)
	line.add_child(boss_label)

## The ring stage. The arc is Liability cleared and its colour is time until
## the Collection hit, so both encounter axes land in one read.
func _build_stage(parent: Control) -> void:
	# A centring frame rather than a box: only the ring and the number draw in
	# it, and the ring's own radius keeps them clear of the controls below.
	var stage := Control.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_top = 150
	stage.offset_bottom = -250
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stage)

	# Built white and tinted through modulate, so the ring's colour can drive
	# the glow every frame without rebuilding the gradient texture.
	stage_glow = TextureRect.new()
	stage_glow.texture = _make_radial_glow(Color.WHITE, 340)
	stage_glow.modulate = ACCENT
	stage_glow.custom_minimum_size = Vector2(340, 340)
	stage_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_glow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stage.add_child(stage_glow)

	ring = RingArc.new()
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(ring)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(centre)
	number_col = VBoxContainer.new()
	number_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_col.alignment = BoxContainer.ALIGNMENT_CENTER
	number_col.add_theme_constant_override("separation", 6)
	number_col.resized.connect(func(): number_col.pivot_offset = number_col.size / 2.0)
	centre.add_child(number_col)
	number_label = Label.new()
	number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.add_theme_font_size_override("font_size", 80)
	number_label.add_theme_color_override("font_color", Color("f5f5f3"))
	number_col.add_child(number_label)
	rate_label = _make_label("", 15, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	number_col.add_child(rate_label)

## The run's own controls: what the encounter is asking for, the two answers to
## it, and the way out. All text, no panels, so the stage stays the loud thing.
func _build_run_controls(parent: Control) -> void:
	encounter_label = _make_tracked_label("", 12, MUTED_TEXT)
	encounter_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	encounter_label.offset_top = -295
	encounter_label.offset_bottom = -270
	encounter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(encounter_label)

	var actions := HBoxContainer.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	actions.offset_top = -258
	actions.offset_bottom = -200
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 60)
	parent.add_child(actions)
	brace_button = _make_text_action("BRACE", "30% OF NUMBER")
	brace_button.tooltip_text = "Spend 30% of Number to block the next Hit."
	brace_button.pressed.connect(_on_brace_pressed)
	actions.add_child(brace_button)

	# Deliberately the quietest control on the screen: ending a run is
	# destructive and rare, so it should never be the thing a thumb finds first.
	run_button = Button.new()
	run_button.flat = true
	run_button.focus_mode = Control.FOCUS_NONE
	run_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	run_button.offset_top = -188
	run_button.offset_bottom = -154
	run_button.add_theme_font_size_override("font_size", 11)
	run_button.add_theme_constant_override("outline_size", 0)
	run_button.pressed.connect(_on_run_button_pressed)
	parent.add_child(run_button)

	tap_hint = _make_tracked_label("TAP TO PRODUCE", 11, FAINT_TEXT)
	tap_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tap_hint.offset_top = -134
	tap_hint.offset_bottom = -110
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(tap_hint)

## A borderless action: the verb, and under it what it costs.
func _make_text_action(verb: String, cost: String) -> Button:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(140, 46)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 5)
	button.add_child(column)
	var verb_label := _make_tracked_label(verb, 13, ACCENT)
	verb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(verb_label)
	var cost_label := _make_label(cost, 10, HORIZONTAL_ALIGNMENT_CENTER, FAINT_TEXT)
	column.add_child(cost_label)
	button.set_meta("verb_label", verb_label)
	button.set_meta("cost_label", cost_label)
	return button

## Uppercase micro-copy is the HUD's voice, and it only reads as deliberate
## with the letter spacing on. Godot has no letter-spacing on Label itself, so
## the tracking comes from a shared FontVariation.
func _make_tracked_label(content: String, font_size: int, colour: Color) -> Label:
	var label := _make_label(content, font_size, HORIZONTAL_ALIGNMENT_CENTER, colour)
	label.add_theme_font_override("font", _tracked_font())
	return label

func _tracked_font() -> FontVariation:
	if tracked_font == null:
		tracked_font = FontVariation.new()
		tracked_font.base_font = ThemeDB.fallback_font
		tracked_font.spacing_glyph = 2
	return tracked_font

func _make_vertical_gradient(top: Color, bottom: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([top, bottom])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.width = 8
	texture.height = 256
	return texture

func _make_radial_glow(colour: Color, diameter: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(colour.r, colour.g, colour.b, 0.18), Color(colour.r, colour.g, colour.b, 0.0)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = diameter
	texture.height = diameter
	return texture

## Builds a full-bleed screen with a padded VBox content root: the shared
## shape behind Workshop, Labs and Cards. The Number screen is custom-built
## above since its tap zone needs full-rect layering instead of a stack.
func _build_flat_screen(parent: Control, tab_id: String) -> VBoxContainer:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(screen)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 4)
	screen.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_child(content)
	_register_screen(tab_id, screen)
	tab_panels[tab_id] = content
	return content

## Header, then the open category's rows, then the four category buttons pinned
## above the nav dock. The strip stays put while the rows scroll, so switching
## shelf is always one thumb reach away.
func _build_workshop_screen(parent: Control) -> void:
	var content := _build_flat_screen(parent, "workshop")
	var margin := content.get_parent() as MarginContainer
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", CATEGORY_STRIP_HEIGHT + int(NavDock.BAR_HEIGHT))

	var header_row := HBoxContainer.new()
	content.add_child(header_row)
	var title := _make_label("WORKSHOP", 19, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _chip_style(SURFACE))
	workshop_header = _make_label("", 12, HORIZONTAL_ALIGNMENT_RIGHT, MUTED_TEXT)
	chip.add_child(workshop_header)
	header_row.add_child(chip)
	content.add_child(_make_label("PERMANENT · APPLIES TO EVERY RUN", 10, HORIZONTAL_ALIGNMENT_LEFT, WORKSHOP_ACCENT))
	var permanence_copy := _make_label("Spend Coins between runs to raise the starting stats used by every future attempt.", 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	permanence_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(permanence_copy)

	content.add_child(_make_label("CHOOSE A CATEGORY", 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	workshop_board_row = HBoxContainer.new()
	workshop_board_row.add_theme_constant_override("separation", 8)
	content.add_child(workshop_board_row)
	for category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
		workshop_board_row.add_child(_make_category_tab(category))
	content.add_child(HSeparator.new())

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(detail_scroll)
	workshop_detail = VBoxContainer.new()
	workshop_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workshop_detail.add_theme_constant_override("separation", 8)
	detail_scroll.add_child(workshop_detail)

func _make_category_tab(category: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var layout := _tile_layout(button, 4, 4)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon_wrap := CenterContainer.new()
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := IconGlyph.new(CATEGORY_ICON[category], MUTED_TEXT, 18.0)
	icon_wrap.add_child(icon)
	layout.add_child(icon_wrap)
	var label := _make_label(ProgressionTaxonomy.category_name(category), 9, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	layout.add_child(label)
	var lock_badge := IconGlyph.new(IconGlyph.Kind.LOCK, MUTED_TEXT, 10.0)
	lock_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lock_badge.position += Vector2(-4, 4)
	button.add_child(lock_badge)
	button.pressed.connect(func(selected: String = category):
		state.workshop.selected_category = selected
		_refresh_workshop()
	)
	workshop_tab_buttons[category] = button
	workshop_tab_icons[category] = icon
	workshop_tab_labels[category] = label
	workshop_lock_badges[category] = lock_badge
	return button

func _build_labs_screen(parent: Control) -> void:
	var content := _build_flat_screen(parent, "labs")
	content.add_child(_make_label("Labs", 19, HORIZONTAL_ALIGNMENT_LEFT, TEXT))
	content.add_child(_make_label("RESEARCH FOCUS", 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	var description := _make_label("Pick one Workshop category to discount by 25%. It locks in until your next Prestige.", 13, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)
	content.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	labs_content = VBoxContainer.new()
	labs_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labs_content.add_theme_constant_override("separation", 10)
	scroll.add_child(labs_content)

	var header_row := HBoxContainer.new()
	column.add_child(header_row)
	var title := _make_label("Knowledge", 19, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _chip_style(SURFACE))
	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 6)
	chip.add_child(chip_row)
	chip_row.add_child(IconGlyph.new(IconGlyph.Kind.DIAMOND, CARDS_ACCENT, 13.0))
	cards_knowledge_label = _make_label("", 12, HORIZONTAL_ALIGNMENT_LEFT, CARDS_ACCENT)
	chip_row.add_child(cards_knowledge_label)
	header_row.add_child(chip)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 10)
	scroll.add_child(inner)

	knowledge_research_header = VBoxContainer.new()
	knowledge_research_header.add_theme_constant_override("separation", 4)
	inner.add_child(knowledge_research_header)
	knowledge_research_header.add_child(_make_label("RESEARCH FOCUS", 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	var focus_copy := _make_label("Pick one Workshop category to discount by 25%. It locks in until your next Prestige.", 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	focus_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	knowledge_research_header.add_child(focus_copy)
	labs_content = VBoxContainer.new()
	labs_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labs_content.add_theme_constant_override("separation", 10)
	inner.add_child(labs_content)

	knowledge_insight_header = VBoxContainer.new()
	knowledge_insight_header.add_theme_constant_override("separation", 4)
	inner.add_child(knowledge_insight_header)
	knowledge_insight_header.add_child(HSeparator.new())
	knowledge_insight_header.add_child(_make_label("INSIGHTS", 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	cards_content = VBoxContainer.new()
	cards_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_content.add_theme_constant_override("separation", 10)
	inner.add_child(cards_content)

func _open_knowledge_sheet() -> void:
	if knowledge_sheet == null:
		return
	if drawer != null and drawer.visible:
		drawer.visible = false
	knowledge_sheet.visible = true
	_refresh_knowledge()

## The two gates that used to decide whether a dock icon appeared now decide
## whether a row inside the sheet does (D016).
func _refresh_knowledge() -> void:
	if knowledge_sheet == null or not knowledge_sheet.visible:
		return
	cards_knowledge_label.text = str(state.knowledge)
	var research_open := state.highest_number.compare_to(ScientificNumber.from_float(RESEARCH_UNLOCK)) >= 0
	knowledge_research_header.visible = research_open
	labs_content.visible = research_open
	_clear_children(labs_content)
	if research_open:
		_refresh_labs()
	var insight_open := state.highest_number.compare_to(ScientificNumber.from_float(GameState.PRESTIGE_TEASER_UNLOCK)) >= 0
	knowledge_insight_header.visible = insight_open
	cards_content.visible = insight_open
	_clear_children(cards_content)
	if insight_open:
		_refresh_cards()
	elif not research_open:
		labs_content.visible = true
		labs_content.add_child(_make_locked_panel("REACH " + ScientificNumber.from_float(RESEARCH_UNLOCK).format_value() + " NUMBER", "Research Focus opens first, then Insight once a run has earned Knowledge."))

func _build_toast() -> void:
	var toast_wrap := Control.new()
	toast_wrap.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast_wrap.custom_minimum_size = Vector2(0, 90)
	toast_wrap.offset_top = 56
	toast_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_wrap)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_wrap.add_child(center)
	# Bare text rather than a pill: a panel here would be the only card on the
	# screen, and it would land right on top of the stage.
	toast_panel = PanelContainer.new()
	toast_panel.modulate.a = 0.0
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	center.add_child(toast_panel)
	toast_label = _make_tracked_label("", 12, ACCENT)
	toast_panel.add_child(toast_label)

func _build_drawer() -> void:
	drawer = Control.new()
	drawer.visible = false
	drawer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(drawer)

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_toggle_drawer()
	)
	drawer.add_child(scrim)

	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_top = 200
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = Color("111722")
	sheet_style.corner_radius_top_left = 24
	sheet_style.corner_radius_top_right = 24
	sheet.add_theme_stylebox_override("panel", sheet_style)
	drawer.add_child(sheet)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 24)
	sheet.add_child(margin)
	drawer_content = VBoxContainer.new()
	drawer_content.add_theme_constant_override("separation", 14)
	margin.add_child(drawer_content)

	var handle := Panel.new()
	handle.custom_minimum_size = Vector2(36, 4)
	var handle_style := StyleBoxFlat.new()
	handle_style.bg_color = Color(1, 1, 1, 0.16)
	handle_style.set_corner_radius_all(2)
	handle.add_theme_stylebox_override("panel", handle_style)
	var handle_wrap := CenterContainer.new()
	handle_wrap.add_child(handle)
	drawer_content.add_child(handle_wrap)

	var top := HBoxContainer.new()
	drawer_content.add_child(top)
	var title := _make_label("Stats & Settings", 16, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := Button.new()
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(30, 30)
	close.add_theme_stylebox_override("normal", _panel_style(Color(1, 1, 1, 0.06), 15))
	close.add_theme_stylebox_override("hover", _panel_style(Color(1, 1, 1, 0.12), 15))
	var close_center := CenterContainer.new()
	close_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close.add_child(close_center)
	close_center.add_child(IconGlyph.new(IconGlyph.Kind.CLOSE, TEXT, 12.0))
	close.pressed.connect(_toggle_drawer)
	top.add_child(close)

	var stats_scroll := ScrollContainer.new()
	stats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer_content.add_child(stats_scroll)
	var stats_column := VBoxContainer.new()
	stats_column.add_theme_constant_override("separation", 18)
	stats_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_scroll.add_child(stats_column)

	var knowledge_route := _make_row_button()
	knowledge_route.custom_minimum_size = Vector2(0, 62)
	knowledge_route.add_theme_stylebox_override("normal", _panel_style(SURFACE, 14, Color(CARDS_ACCENT.r, CARDS_ACCENT.g, CARDS_ACCENT.b, 0.35)))
	knowledge_route.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 14, CARDS_ACCENT))
	var route_row := _row_layout(knowledge_route, 14, 10)
	route_row.add_child(IconGlyph.new(IconGlyph.Kind.DIAMOND, CARDS_ACCENT, 16.0))
	var route_label := _make_label("Spend Knowledge", 14, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	route_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_row.add_child(route_label)
	route_row.add_child(_make_label("RESEARCH · INSIGHT · RESET", 9, HORIZONTAL_ALIGNMENT_RIGHT, MUTED_TEXT))
	knowledge_route.pressed.connect(func():
		_toggle_drawer()
		_open_knowledge_sheet()
	)
	stats_column.add_child(knowledge_route)
	stats_column.add_child(HSeparator.new())

	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 14)
	stats_grid.add_theme_constant_override("v_separation", 14)
	stats_column.add_child(stats_grid)
	stats_column.add_child(HSeparator.new())

	var toggle_box := VBoxContainer.new()
	toggle_box.add_theme_constant_override("separation", 14)
	stats_column.add_child(toggle_box)
	for setting in [["muted", "Mute sound"], ["ambience", "Ambient music"], ["haptics", "Haptics"], ["reduce_motion", "Reduce motion"], ["high_contrast", "High contrast"]]:
		var row := HBoxContainer.new()
		var label := _make_label(setting[1], 14, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var toggle := CheckButton.new()
		toggle.name = "Setting_" + setting[0]
		toggle.toggled.connect(func(value: bool, key: String = setting[0]):
			state.settings[key] = value
			state.save()
			_refresh_all()
			if key == "muted" or key == "ambience":
				_sync_ambience()
		)
		row.add_child(toggle)
		toggle_box.add_child(row)

	var persistence := _make_label("Saves are stored on this device. Browser private mode or cleared site data can remove them.", 11, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	persistence.name = "Persistence"
	persistence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_column.add_child(persistence)

	var clear := Button.new()
	clear.text = "Clear local save"
	clear.flat = true
	clear.focus_mode = Control.FOCUS_NONE
	clear.add_theme_font_size_override("font_size", 12)
	clear.add_theme_color_override("font_color", DANGER)
	clear.add_theme_color_override("font_hover_color", DANGER)
	clear.modulate.a = 0.75
	clear.pressed.connect(_clear_local_save)
	stats_column.add_child(clear)

## What a stat is and where it stands, opened by tapping a Workshop card's name.
## The card itself stays compact because this holds the description, so a whole
## category fits on one screen. Tapping anywhere dismisses it.
func _build_stat_info() -> void:
	stat_info_screen = Control.new()
	stat_info_screen.visible = false
	stat_info_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stat_info_screen)

	var scrim := Button.new()
	scrim.text = ""
	scrim.flat = true
	scrim.focus_mode = Control.FOCUS_NONE
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0.7), 0))
	scrim.add_theme_stylebox_override("hover", _panel_style(Color(0, 0, 0, 0.7), 0))
	scrim.add_theme_stylebox_override("pressed", _panel_style(Color(0, 0, 0, 0.7), 0))
	scrim.pressed.connect(func(): stat_info_screen.visible = false)
	stat_info_screen.add_child(scrim)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_info_screen.add_child(centre)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(272, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(Color("171c26"), 20, Color(WORKSHOP_ACCENT.r, WORKSHOP_ACCENT.g, WORKSHOP_ACCENT.b, 0.5)))
	centre.add_child(panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 14)
	margin.add_child(inner)

	stat_info_title = _make_label("", 19, HORIZONTAL_ALIGNMENT_CENTER, TEXT)
	inner.add_child(stat_info_title)
	stat_info_body = _make_label("", 13, HORIZONTAL_ALIGNMENT_CENTER, TEXT)
	stat_info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(stat_info_body)
	inner.add_child(HSeparator.new())
	stat_info_level = _make_label("", 13, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	inner.add_child(stat_info_level)
	stat_info_max = _make_label("", 13, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	inner.add_child(stat_info_max)

func _show_stat_info(definition: UpgradeDefinition) -> void:
	if stat_info_screen == null:
		return
	var owned := state.get_owned(definition.id)
	stat_info_title.text = definition.title
	stat_info_body.text = definition.description
	stat_info_level.text = "CURRENT RANK  ·  " + str(owned) + "  (" + _stat_value_text(definition, owned) + ")"
	if definition.is_maxed(owned):
		stat_info_max.text = "MAX RANK  ·  " + str(definition.max_rank) + "  ·  REACHED"
	else:
		stat_info_max.text = "MAX RANK  ·  " + str(definition.max_rank) + "  (" + _stat_value_text(definition, definition.max_rank) + ")"
	stat_info_screen.visible = true

## The run-over report: same scrim-and-sheet shape as the drawer, but modal
## (no scrim-tap-to-dismiss) since a death should be acknowledged, not brushed
## past, and its content is a fixed summary rather than a live-editing form.
func _build_died_screen() -> void:
	died_screen = Control.new()
	died_screen.visible = false
	died_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(died_screen)

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.7)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	died_screen.add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	died_screen.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("171c26"), 22, Color(DANGER.r, DANGER.g, DANGER.b, 0.4)))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 6)
	margin.add_child(inner)

	inner.add_child(_make_label("LOST TO", 12, HORIZONTAL_ALIGNMENT_CENTER, DANGER))
	died_wave_label = _make_label("", 26, HORIZONTAL_ALIGNMENT_CENTER, TEXT)
	inner.add_child(died_wave_label)
	died_cause_label = _make_label("", 13, HORIZONTAL_ALIGNMENT_CENTER, DANGER)
	died_cause_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(died_cause_label)
	var subtitle := _make_label("Your Workshop was retained.", 12, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(subtitle)
	inner.add_child(HSeparator.new())

	died_coins_label = _make_label("", 14, HORIZONTAL_ALIGNMENT_CENTER, COIN_ACCENT)
	inner.add_child(died_coins_label)
	died_knowledge_label = _make_label("", 14, HORIZONTAL_ALIGNMENT_CENTER, CARDS_ACCENT)
	inner.add_child(died_knowledge_label)
	died_peak_label = _make_label("", 12, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	inner.add_child(died_peak_label)

	# Both doors, at the moment the currency lands (D016).
	var doors := HBoxContainer.new()
	doors.add_theme_constant_override("separation", 8)
	inner.add_child(doors)
	doors.add_child(_make_door("WORKSHOP", ACCENT, func():
		_dismiss_died_screen()
		_on_dock_tab_selected("workshop")
	))
	died_knowledge_door = _make_door("SPEND KNOWLEDGE", CARDS_ACCENT, func():
		_dismiss_died_screen()
		_open_knowledge_sheet()
	)
	doors.add_child(died_knowledge_door)

	var continue_button := Button.new()
	continue_button.text = "CONTINUE"
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.custom_minimum_size = Vector2(0, 48)
	continue_button.add_theme_font_size_override("font_size", 14)
	continue_button.add_theme_color_override("font_color", Color("0d1016"))
	continue_button.add_theme_color_override("font_hover_color", Color("0d1016"))
	continue_button.add_theme_stylebox_override("normal", _panel_style(ACCENT, 999))
	continue_button.add_theme_stylebox_override("hover", _panel_style(ACCENT.lightened(0.1), 999))
	continue_button.pressed.connect(_dismiss_died_screen)
	inner.add_child(continue_button)

## A named cause, not a counterfactual: the run was lost to a particular wave's
## hit, and the screen says which and how big.
func _make_door(text: String, tint: Color, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", tint)
	button.add_theme_color_override("font_hover_color", tint)
	button.add_theme_stylebox_override("normal", _panel_style(Color(tint.r, tint.g, tint.b, 0.1), 999, Color(tint.r, tint.g, tint.b, 0.4)))
	button.add_theme_stylebox_override("hover", _panel_style(Color(tint.r, tint.g, tint.b, 0.2), 999, tint))
	button.pressed.connect(on_press)
	return button

func _show_died_screen(summary: RunSummary) -> void:
	if summary == null or died_screen == null:
		return
	var wave_name := "BOSS WAVE " if summary.lost_to_boss else "WAVE "
	died_wave_label.text = wave_name + str(summary.wave_reached)
	died_cause_label.text = "Its hit took " + summary.final_hit.format_value() + " and you had less."
	died_knowledge_door.visible = summary.knowledge_gained > 0 or state.knowledge > 0
	died_coins_label.text = "+" + _coins(summary.coins_earned) + " COINS EARNED"
	if summary.knowledge_gained > 0:
		died_knowledge_label.text = "+" + str(summary.knowledge_gained) + " KNOWLEDGE"
		died_knowledge_label.visible = true
	else:
		died_knowledge_label.visible = false
	died_peak_label.text = "TIER " + str(summary.tier_id) + "  ·  PEAK NUMBER " + summary.peak_number.format_value()
	died_screen.visible = true

func _dismiss_died_screen() -> void:
	died_screen.visible = false
	_refresh_all()

func _select_tab(tab_id: String) -> void:
	if not _is_tab_unlocked(tab_id):
		return
	current_tab = tab_id
	for id in screens:
		screens[id].visible = (id == tab_id)
	if tab_id == "workshop":
		_refresh_workshop()
	_animate_tab_panel(tab_id)
	_refresh_dock()

## The slide-up motion itself: the content starts a little below its resting
## spot and fades in as it settles, rather than simply appearing.
func _animate_tab_panel(tab_id: String) -> void:
	if not tab_panels.has(tab_id) or state.settings.reduce_motion:
		return
	var target: Control = tab_panels[tab_id]
	target.position.y = 24
	target.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate:a", 1.0, 0.18)

func _on_dock_tab_selected(tab_id: String) -> void:
	if tab_id == "settings":
		if not _is_tab_unlocked("settings"):
			_show_toast("REACH " + ScientificNumber.from_float(tab_unlock_lifetime["settings"]).format_value() + " TO UNLOCK SETTINGS", MUTED_TEXT)
			return
		_toggle_drawer()
		return
	if not _is_tab_unlocked(tab_id):
		_show_toast("REACH " + ScientificNumber.from_float(tab_unlock_lifetime[tab_id]).format_value() + " TO UNLOCK " + TAB_NAMES[tab_id], MUTED_TEXT)
		return
	if drawer.visible:
		drawer.visible = false
	if knowledge_sheet != null and knowledge_sheet.visible:
		knowledge_sheet.visible = false
	_select_tab(tab_id)

func _is_tab_unlocked(tab_id: String) -> bool:
	var threshold: float = tab_unlock_lifetime.get(tab_id, 0.0)
	return state.highest_number.compare_to(ScientificNumber.from_float(threshold)) >= 0

func _refresh_dock() -> void:
	var unlocked := {}
	var active := "settings" if drawer.visible else current_tab
	var signature := active
	for tab_id in TAB_IDS:
		unlocked[tab_id] = _is_tab_unlocked(tab_id)
		signature += "|" + ("1" if unlocked[tab_id] else "0")
	unlocked["settings"] = _is_tab_unlocked("settings")
	signature += "|s" + ("1" if unlocked["settings"] else "0")
	# Dock restyling is only worth doing when the active tab or an unlock
	# boundary actually changed; _refresh_all runs eight times a second.
	if signature == dock_signature:
		return
	dock_signature = signature
	nav_dock.update_state(active, unlocked)

func _tap_number() -> void:
	if not state.in_run:
		_show_toast("START A RUN TO PRODUCE NUMBER", MUTED_TEXT)
		return
	var was_banking := state.is_output_banking()
	var event := state.tap()
	var spawn_pos := floating_text_layer.get_local_mouse_position()
	if not Rect2(Vector2.ZERO, floating_text_layer.size).has_point(spawn_pos):
		spawn_pos = floating_text_layer.size * Vector2(0.5, 0.42)
	if event.is_critical:
		_spawn_floating_text(_production_feedback_text(event.amount, true, was_banking), CRITICAL, spawn_pos)
		_pulse_number(1.09)
		_flash_number(CRITICAL)
	else:
		_spawn_floating_text(_production_feedback_text(event.amount, false, was_banking), ACCENT, spawn_pos)
		_pulse_number(1.035)
	if state.settings.haptics:
		Input.vibrate_handheld(8)
	audio_feedback.play_feedback(event.is_critical, bool(state.settings.muted))
	_refresh_all()

func _on_run_button_pressed() -> void:
	if state.in_run:
		var summary := state.end_run()
		if summary != null:
			_show_toast("RETREATED  ·  TIER " + str(summary.tier_id) + " WAVE " + str(summary.wave_reached), DANGER)
	else:
		state.start_run()
		_show_toast("RUN STARTED  ·  WORKSHOP LV " + str(state.get_workshop_level()) + " APPLIED", ACCENT)
	_snap_number_display()
	state.save()
	_refresh_all()

## The tier label doubles as its own selector: between runs it steps to the
## next unlocked tier and wraps, which needs no panel of its own.
func _on_tier_pressed() -> void:
	var tiers: Array = state.balance_profile.tiers
	if tiers.is_empty():
		return
	var start := 0
	for index in range(tiers.size()):
		if tiers[index].id == state.selected_tier:
			start = index
			break
	for step in range(1, tiers.size() + 1):
		var candidate: int = tiers[(start + step) % tiers.size()].id
		if state.is_tier_unlocked(candidate) and state.select_tier(candidate):
			_show_toast("TIER " + str(candidate), ACCENT)
			state.save()
			_refresh_all()
			return
	_show_toast("NO OTHER TIER UNLOCKED", MUTED_TEXT)

func _on_brace_pressed() -> void:
	if state.brace():
		_show_toast("BRACED FOR NEXT WAVE", ACCENT)
		_refresh_all()
	else:
		_show_toast("CANNOT BRACE YET", MUTED_TEXT)

## The core per-tap "juice": a short line of text that rises from the tap
## point and fades, replacing a single static feedback label.
func _spawn_floating_text(text: String, colour: Color, local_pos: Vector2) -> void:
	if floating_text_layer == null:
		return
	var label := _make_label(text, 15, HORIZONTAL_ALIGNMENT_CENTER, colour)
	label.position = local_pos - Vector2(24, 10)
	floating_text_layer.add_child(label)
	if bool(state.settings.reduce_motion):
		get_tree().create_timer(0.9).timeout.connect(func():
			if is_instance_valid(label):
				label.queue_free()
		)
		return
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 70.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.15)
	tween.chain().tween_callback(label.queue_free)

func _production_feedback_text(amount: ScientificNumber, critical: bool, banking: bool) -> String:
	var value := ("+" if banking else "") + amount.format_value()
	if not banking:
		value += " DAMAGE"
	return ("CRITICAL " if critical else "") + value

func _refresh_all() -> void:
	background_rect.visible = not bool(state.settings.high_contrast)
	rate_label.visible = true
	var rate := _stat_number(state.get_rate_per_second())
	if not state.in_run:
		rate_label.text = "STARTING +" + rate + " / sec"
	elif state.is_output_banking():
		rate_label.text = "+" + rate + " / sec"
	else:
		rate_label.text = rate + " DAMAGE / sec"
	tap_hint.text = "TAP TO PRODUCE" if state.in_run else "START A RUN TO PRODUCE"
	coins_label.text = _coins(state.coins)
	knowledge_label.text = str(state.knowledge)
	_refresh_run_bar()
	if offline_message != "":
		_show_toast(offline_message, ACCENT)
		offline_message = ""
	_refresh_dock()
	_refresh_knowledge()
	if current_tab == "workshop":
		# Do not rebuild live buttons during the player's press/release cycle.
		# Rebuilding a Control tree every refresh can eat touch releases on Web.
		workshop_header.text = _coins(state.coins) + " COINS"

## Shows the two independent checks the run turns on: the remaining Wave HP
## production must clear, and the Hit Number must survive.
func _refresh_run_bar() -> void:
	wave_label.text = "WAVE " + str(state.wave) if state.in_run else "NOT RUNNING"
	tier_button.text = "TIER " + str(state.selected_tier)
	tier_button.disabled = state.in_run
	_refresh_boss_notice()
	_refresh_encounter_line()
	brace_button.visible = state.in_run
	brace_cost_label.text = "%.0f%% OF NUMBER" % (state.get_brace_cost_percent() * 100.0)
	brace_button.disabled = not state.can_brace()
	_set_action_enabled(brace_button, not brace_button.disabled)
	run_button.text = "RETREAT & RESET" if state.in_run else "START RUN  ·  WORKSHOP LV " + str(state.get_workshop_level())
	var run_colour := FAINT_TEXT if state.in_run else ACCENT
	run_button.add_theme_color_override("font_color", run_colour)
	run_button.add_theme_color_override("font_hover_color", TEXT if state.in_run else ACCENT)
	run_button.add_theme_font_override("font", _tracked_font())

## The boss warning is the only thing besides a landing hit allowed to use the
## warning colour, so it keeps its weight.
func _refresh_boss_notice() -> void:
	var text := ""
	if state.in_run:
		var encounter: Variant = state.active_encounter
		if encounter != null and encounter.is_boss:
			text = "BOSS WAVE"
		else:
			var until_boss := _waves_until_boss(state.wave)
			if until_boss > 0:
				text = "BOSS IN " + str(until_boss)
	boss_label.text = text
	boss_label.visible = text != ""
	boss_separator.visible = text != ""

## Boss waves land every tenth wave; the profile owns that rule, this only
## reads it so the HUD can warn a few waves out.
func _waves_until_boss(current_wave: int) -> int:
	for ahead in range(1, 4):
		if state.balance_profile.is_boss_wave(current_wave + ahead):
			return ahead
	return 0

func _refresh_encounter_line() -> void:
	if not state.in_run:
		encounter_label.text = "TIER BEST " + str(state.get_tier_best()) + "  ·  " + _coins(state.coins) + " COINS BANKED"
		return
	var encounter: Variant = state.active_encounter
	if encounter == null or encounter.max_liability.is_zero():
		encounter_label.text = "WARM-UP  ·  EVERYTHING BANKS"
		return
	if encounter.is_cleared():
		encounter_label.text = "BEATEN  ·  HIT BLOCKED"
		return
	var seconds_left := maxi(0, ceili(GameState.WAVE_INTERVAL_SECONDS - state.wave_accumulator))
	encounter_label.text = "HITS FOR " + state.get_effective_collection().format_value() + " IN " + str(seconds_left) + "s"

func _set_action_enabled(button: Button, enabled: bool) -> void:
	var verb: Label = button.get_meta("verb_label")
	verb.add_theme_color_override("font_color", ACCENT if enabled else FAINT_TEXT)
	button.modulate.a = 1.0 if enabled else 0.55

func _refresh_workshop() -> void:
	workshop_header.text = str(state.coins) + " COINS"
	for category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
		var active: bool = state.workshop.selected_category == category
		var unlocked := state.is_category_active(category)
		var colour: Color = WORKSHOP_ACCENT if (active and unlocked) else MUTED_TEXT
		(workshop_tab_icons[category] as IconGlyph).set_glyph_color(colour)
		(workshop_tab_labels[category] as Label).add_theme_color_override("font_color", colour)
		var button: Button = workshop_tab_buttons[category]
		button.visible = category != ProgressionTaxonomy.DEFENSE or state.defense_unlocked
		button.disabled = not unlocked
		var border: Color = WORKSHOP_ACCENT if (active and unlocked) else Color.TRANSPARENT
		var fill: Color = Color(WORKSHOP_ACCENT.r, WORKSHOP_ACCENT.g, WORKSHOP_ACCENT.b, 0.14) if (active and unlocked) else Color.TRANSPARENT
		button.add_theme_stylebox_override("normal", _panel_style(fill, 14, border))
		button.add_theme_stylebox_override("disabled", _panel_style(Color.TRANSPARENT, 14, Color.TRANSPARENT))
		(workshop_lock_badges[category] as IconGlyph).visible = not unlocked
	_refresh_workshop_detail()

func _refresh_workshop_detail() -> void:
	_clear_children(workshop_detail)
	var category := state.workshop.selected_category
	if not ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(category):
		category = ProgressionTaxonomy.ATTACK
		state.workshop.selected_category = category
	var description := _make_label(ProgressionTaxonomy.category_description(category), 13, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	workshop_detail.add_child(description)
	if state.in_run:
		workshop_detail.add_child(_make_locked_panel("AVAILABLE BETWEEN RUNS", "Current ranks are active now and will be retained when this run ends."))
	if not state.is_category_active(category):
		if category == ProgressionTaxonomy.DEFENSE:
			workshop_detail.add_child(_make_locked_panel("TAKE YOUR FIRST HIT", "Defense appears after a wave survives its timer and Hits your Number."))
		else:
			workshop_detail.add_child(_make_locked_panel("REACH WORKSHOP LEVEL " + str(state.get_category_required_level(category)), "Your current level is " + str(state.get_workshop_level()) + "."))
		return
	if category == ProgressionTaxonomy.ULTIMATES:
		for ultimate in [["SURGE", 10], ["BULWARK", 25], ["BREACH", 50], ["WINDFALL", 100]]:
			workshop_detail.add_child(_make_locked_panel(ultimate[0], "UNLOCKS AT WAVE " + str(ultimate[1])))
		return
	var found_next := false
	for definition in state.upgrades_for_category(category):
		var maxed := definition.is_maxed(state.get_owned(definition.id))
		var unlocked := state.is_unlocked(definition)
		var is_next := unlocked and not maxed and not found_next
		if is_next:
			found_next = true
		workshop_detail.add_child(_make_ranked_card(definition, CATEGORY_ICON[category], is_next))

func _refresh_labs() -> void:
	_clear_children(labs_content)
	if state.get_workshop_level() < GameState.RESEARCH_WORKSHOP_LEVEL:
		labs_content.add_child(_make_locked_panel("REACH WORKSHOP LEVEL " + str(GameState.RESEARCH_WORKSHOP_LEVEL), "Your current level is " + str(state.get_workshop_level()) + "."))
		return
	if state.focus_category != "":
		labs_content.add_child(_make_focus_locked_card(state.focus_category))
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	labs_content.add_child(grid)
	for category in ProgressionTaxonomy.RESEARCH_FOCUS_CATEGORIES:
		grid.add_child(_make_focus_card(category))

func _make_focus_card(category: String) -> Button:
	var active := state.is_category_active(category)
	var button := _make_tile_button()
	button.custom_minimum_size = Vector2(0, 92)
	button.disabled = not active or state.in_run
	var border := LABS_ACCENT if active else Color.TRANSPARENT
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE, 14, border))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 14, LABS_ACCENT))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("0f5848"), 14, LABS_ACCENT))
	var layout := _tile_layout(button, 14, 12)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(30, 30)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _panel_style(Color(LABS_ACCENT.r, LABS_ACCENT.g, LABS_ACCENT.b, 0.14), 9))
	var chip_center := CenterContainer.new()
	chip_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(chip_center)
	chip_center.add_child(IconGlyph.new(CATEGORY_ICON[category], LABS_ACCENT if active else MUTED_TEXT, 15.0))
	layout.add_child(chip)
	layout.add_child(_make_label(ProgressionTaxonomy.category_name(category), 13, HORIZONTAL_ALIGNMENT_LEFT, TEXT if active else MUTED_TEXT))
	layout.add_child(_make_label("-25% COST", 10, HORIZONTAL_ALIGNMENT_LEFT, LABS_ACCENT if active else MUTED_TEXT))
	button.pressed.connect(func(chosen_category: String = category):
		if state.select_focus(chosen_category):
			_show_toast("RESEARCH FOCUS SET", LABS_ACCENT)
			state.save()
			_refresh_all()
			_refresh_knowledge()
	)
	return button

func _make_focus_locked_card(category: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(SURFACE, 18, LABS_ACCENT))
	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(48, 48)
	chip.add_theme_stylebox_override("panel", _panel_style(Color(LABS_ACCENT.r, LABS_ACCENT.g, LABS_ACCENT.b, 0.16), 14))
	var chip_center := CenterContainer.new()
	chip_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip.add_child(chip_center)
	chip_center.add_child(IconGlyph.new(IconGlyph.Kind.CHECK, LABS_ACCENT, 22.0))
	var chip_wrap := CenterContainer.new()
	chip_wrap.add_child(chip)
	inner.add_child(chip_wrap)
	inner.add_child(_make_label(ProgressionTaxonomy.category_name(category) + " · Research Focus", 15, HORIZONTAL_ALIGNMENT_CENTER, TEXT))
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _tag_style(LABS_ACCENT))
	badge.add_child(_make_label("LOCKED IN", 11, HORIZONTAL_ALIGNMENT_CENTER, LABS_ACCENT))
	var badge_wrap := CenterContainer.new()
	badge_wrap.add_child(badge)
	inner.add_child(badge_wrap)
	var subtitle := _make_label("-25% Coin cost on every " + ProgressionTaxonomy.category_name(category) + " upgrade until your next Prestige.", 12, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(subtitle)
	return panel

func _refresh_cards() -> void:
	cards_knowledge_label.text = str(state.knowledge)
	_clear_children(cards_content)
	for definition in state.definitions_for_progression_type(ProgressionTaxonomy.KNOWLEDGE):
		cards_content.add_child(_make_insight_card(definition))
	cards_content.add_child(HSeparator.new())
	cards_content.add_child(_make_prestige_panel())

func _make_insight_card(definition: UpgradeDefinition) -> Button:
	var owned := state.get_owned(definition.id)
	var disabled := not state.can_purchase_insight()
	var button := _make_row_button()
	button.disabled = disabled
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE, 14, Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 14, CARDS_ACCENT))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("0f5848"), 14, CARDS_ACCENT))
	var row := _row_layout(button, 14, 10)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(36, 36)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _panel_style(Color(CARDS_ACCENT.r, CARDS_ACCENT.g, CARDS_ACCENT.b, 0.14), 10))
	var chip_center := CenterContainer.new()
	chip_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(chip_center)
	chip_center.add_child(IconGlyph.new(IconGlyph.Kind.SPARKLE, CARDS_ACCENT, 16.0))
	row.add_child(chip)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 4)
	row.add_child(mid)
	mid.add_child(_make_label(definition.title, 14, HORIZONTAL_ALIGNMENT_LEFT, TEXT))
	mid.add_child(_make_label("RANK " + str(owned), 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	var description_label := _make_label(definition.description, 11, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(description_label)
	row.add_child(_make_label("1 KNOWLEDGE", 12, HORIZONTAL_ALIGNMENT_RIGHT, TEXT if not disabled else MUTED_TEXT))
	button.pressed.connect(func():
		if state.purchase_insight():
			_show_toast("INSIGHT IMPROVED", CARDS_ACCENT)
			state.save()
			_refresh_all()
			_refresh_knowledge()
		else:
			_show_toast("NEED KNOWLEDGE", MUTED_TEXT)
	)
	return button

func _make_prestige_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(CARDS_ACCENT.r, CARDS_ACCENT.g, CARDS_ACCENT.b, 0.07)
	style.border_color = Color(CARDS_ACCENT.r, CARDS_ACCENT.g, CARDS_ACCENT.b, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 8)
	panel.add_child(inner)
	inner.add_child(_make_label("RESET", 10, HORIZONTAL_ALIGNMENT_CENTER, CARDS_ACCENT))
	var gain := state.get_prestige_knowledge_gain()
	var gain_text := "+" + str(gain) + " KNOWLEDGE" if gain > 0 else "KEEP PLAYING TO EARN KNOWLEDGE"
	inner.add_child(_make_label(gain_text, 22, HORIZONTAL_ALIGNMENT_CENTER, TEXT if gain > 0 else MUTED_TEXT))
	var subtitle := _make_label("Run Number resets. Permanent Workshop ranks, Coins and Insights are retained.", 12, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(subtitle)
	var confirm := Button.new()
	confirm.text = "RESET NUMBER"
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.custom_minimum_size = Vector2(0, 50)
	confirm.add_theme_font_size_override("font_size", 14)
	confirm.disabled = gain <= 0
	confirm.add_theme_color_override("font_color", Color("1a1023"))
	confirm.add_theme_color_override("font_hover_color", Color("1a1023"))
	confirm.add_theme_color_override("font_disabled_color", MUTED_TEXT)
	confirm.add_theme_stylebox_override("normal", _panel_style(CARDS_ACCENT, 999))
	confirm.add_theme_stylebox_override("hover", _panel_style(CARDS_ACCENT.lightened(0.1), 999))
	confirm.add_theme_stylebox_override("pressed", _panel_style(CARDS_ACCENT.darkened(0.1), 999))
	confirm.add_theme_stylebox_override("disabled", _panel_style(SURFACE, 999))
	confirm.pressed.connect(_confirm_prestige)
	inner.add_child(confirm)
	return panel

func _confirm_prestige() -> void:
	var gain := state.prestige()
	if gain <= 0:
		return
	_show_toast("PRESTIGE  ·  +" + str(gain) + " KNOWLEDGE", CARDS_ACCENT)
	_snap_number_display()
	state.save()
	_refresh_all()
	_refresh_knowledge()

## A row card for a ranked, permanent Coin-funded Workshop upgrade: an icon chip, a
## title with an optional NEXT tag, a thin fill bar for rank, and cost/rank
## at the right.
## A compact Workshop card, two to a row: the stat's name on the left, which
## opens its detail, and the value-and-cost box on the right, which buys. The
## description lives in the detail popup rather than on the card, so a category
## fits on one screen.
func _make_stat_card(definition: UpgradeDefinition, category: String) -> PanelContainer:
	var owned := state.get_owned(definition.id)
	var maxed := definition.is_maxed(owned)
	var unlocked := state.is_unlocked(definition)
	var plan := state.plan_purchase(definition.id, _buy_step(category))
	var ranks := int(plan.ranks)
	var affordable := ranks > 0

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var edge: Color = WORKSHOP_ACCENT if affordable else Color(1, 1, 1, 0.07)
	card.add_theme_stylebox_override("panel", _panel_style(SURFACE, 12, edge))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)

	var name_button := Button.new()
	name_button.text = ""
	name_button.flat = true
	name_button.focus_mode = Control.FOCUS_NONE
	name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_button.tooltip_text = definition.description
	var name_layout := _tile_layout(name_button, 10, 6)
	name_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	var name_label := _make_label(definition.title, 12, HORIZONTAL_ALIGNMENT_LEFT, TEXT if unlocked else MUTED_TEXT)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_layout.add_child(name_label)
	name_button.pressed.connect(func(): _show_stat_info(definition))
	row.add_child(name_button)

	var value_button := _make_tile_button()
	value_button.custom_minimum_size = Vector2(84, 58)
	value_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var box_tint: Color = WORKSHOP_ACCENT if affordable else Color(1, 1, 1, 0.05)
	value_button.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0.25), 10, box_tint))
	value_button.add_theme_stylebox_override("hover", _panel_style(Color(WORKSHOP_ACCENT.r, WORKSHOP_ACCENT.g, WORKSHOP_ACCENT.b, 0.12), 10, box_tint))
	var value_layout := _tile_layout(value_button, 6, 6)
	value_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	value_layout.add_child(_make_label(_stat_value_text(definition, owned), 13, HORIZONTAL_ALIGNMENT_RIGHT, TEXT if unlocked else MUTED_TEXT))
	value_layout.add_child(_make_label(_stat_cost_text(definition, owned, maxed, unlocked, plan), 9, HORIZONTAL_ALIGNMENT_RIGHT, WORKSHOP_ACCENT if affordable else MUTED_TEXT))
	value_button.pressed.connect(func(upgrade_id: String = definition.id, step: int = _buy_step(category)):
		var bought := state.purchase_ranks(upgrade_id, step)
		if bought > 0:
			_show_toast("+" + str(bought) + "  " + definition.title, WORKSHOP_ACCENT)
			state.save()
			_refresh_all()
			_refresh_workshop()
		elif maxed:
			_show_toast("ALREADY MAXED", MUTED_TEXT)
		elif not unlocked:
			_show_toast("NEEDS WORKSHOP LV " + str(definition.workshop_level_required), MUTED_TEXT)
		elif state.in_run:
			_show_toast("AVAILABLE BETWEEN RUNS", MUTED_TEXT)
		else:
			_show_toast("NEED " + _coins(state.get_workshop_coin_cost(definition)) + " COINS", MUTED_TEXT)
	)
	row.add_child(value_button)
	return card

## The row's effect read as a player-facing value, formatted by the unit the
## state reports rather than by a per-row special case here.
func _stat_value_text(definition: UpgradeDefinition, rank: int) -> String:
	var display := state.stat_display(definition, rank)
	var value := float(display.value)
	match str(display.unit):
		"percent":
			return "%.2f%%" % (value * 100.0)
		"multiplier":
			return "×%.2f" % value
		"flat":
			# The Number formatter rounds to whole units, which would hide a
			# rank worth 0.05. Small stat values need their decimals.
			return _stat_number(ScientificNumber.from_float(value))
		_:
			return str(rank) + " / " + str(definition.max_rank)

func _stat_cost_text(definition: UpgradeDefinition, owned: int, maxed: bool, unlocked: bool, plan: Dictionary) -> String:
	if maxed:
		return "MAX"
	if not unlocked:
		return "LV " + str(definition.workshop_level_required)
	if int(plan.ranks) > 1:
		return "x" + str(int(plan.ranks)) + " · " + _coins(int(plan.cost)) + " ©"
	if int(plan.ranks) == 1:
		return _coins(int(plan.cost)) + " ©"
	return _coins(state.get_workshop_coin_cost_at(definition, owned)) + " ©"

func _make_locked_panel(title_text: String, subtitle_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 140)
	panel.add_theme_stylebox_override("panel", _panel_style(SURFACE, 16))
	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 8)
	panel.add_child(inner)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(44, 44)
	chip.add_theme_stylebox_override("panel", _panel_style(Color(1, 1, 1, 0.06), 12))
	var chip_center := CenterContainer.new()
	chip_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(chip_center)
	chip_center.add_child(IconGlyph.new(IconGlyph.Kind.LOCK, MUTED_TEXT, 20.0))
	var chip_wrap := CenterContainer.new()
	chip_wrap.add_child(chip)
	inner.add_child(chip_wrap)
	inner.add_child(_make_label("LOCKED · " + title_text, 13, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT))
	inner.add_child(_make_label(subtitle_text, 12, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT))
	return panel

func _refresh_drawer() -> void:
	if drawer == null or not drawer.visible:
		return
	_populate_stats_grid()
	for key in state.settings:
		var toggle: CheckButton = drawer.find_child("Setting_" + key, true, false)
		if toggle != null and toggle.button_pressed != bool(state.settings[key]):
			toggle.set_pressed_no_signal(bool(state.settings[key]))
	var persistence: Label = drawer.find_child("Persistence", true, false)
	if persistence != null:
		persistence.remove_theme_color_override("font_color")
		persistence.text = "Saves are stored on this device. Browser private mode or cleared site data can remove them."
		if not state.has_persistent_storage():
			persistence.text = "LOCAL SAVE MAY NOT PERSIST IN THIS BROWSER. Turn off private browsing or allow site storage."
			persistence.add_theme_color_override("font_color", CRITICAL)

func _populate_stats_grid() -> void:
	_clear_children(stats_grid)
	var entries := [
		["CURRENT NUMBER", state.number.format_value()],
		["SELECTED TIER", str(state.selected_tier)],
		["TIER BEST", str(state.get_tier_best())],
		["KNOWLEDGE", str(state.knowledge)],
		["WORKSHOP LEVEL", str(state.get_workshop_level())],
		["DAMAGE / SEC", state.get_rate_per_second().format_value()],
		["HIGHEST NUMBER", state.highest_number.format_value()],
		["THIS RUN GENERATED", state.lifetime_generated.format_value()],
		["TAPS", str(int(state.statistics.taps))],
		["TICKS", str(int(state.statistics.ticks))],
		["CRITICAL TICKS", str(int(state.statistics.critical_ticks))],
		["COINS SPENT", str(int(state.statistics.get("coins_spent", 0)))],
	]
	for entry in entries:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		cell.add_child(_make_label(entry[0], 9, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
		cell.add_child(_make_label(entry[1], 15, HORIZONTAL_ALIGNMENT_LEFT, TEXT))
		stats_grid.add_child(cell)

func _toggle_drawer() -> void:
	drawer.visible = not drawer.visible
	if drawer.visible:
		_refresh_drawer()
	_refresh_dock()

func _clear_local_save() -> void:
	state.clear_save()
	state = GameState.new()
	_snap_number_display()
	drawer.visible = false
	_select_tab("number")
	_show_toast("LOCAL SAVE CLEARED", CRITICAL)
	_refresh_all()

func _show_toast(text: String, colour: Color) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", colour)
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast_panel.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(1.6)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.5)

## Starts or stops the looping ambient pad to match settings. "Mute sound" is
## a hard override for all audio, including ambience, independent of its own
## toggle.
func _sync_ambience() -> void:
	audio_feedback.set_ambience_enabled(not bool(state.settings.muted) and bool(state.settings.ambience))

func _pulse_number(target_scale: float) -> void:
	if state.settings.reduce_motion:
		return
	var tween := create_tween()
	tween.tween_property(number_col, "scale", Vector2(target_scale, target_scale), 0.06)
	tween.tween_property(number_col, "scale", Vector2.ONE, 0.12)

## Briefly recolours the big number to an event colour and eases it back to
## its resting colour, so a critical tick, a tax hit or a boss hit reads on
## the number itself, not only in the floating text beside it. Not gated on
## Reduce Motion: a colour fade carries no motion-sickness risk.
func _flash_number(colour: Color, duration: float = 0.35) -> void:
	if number_flash_tween != null and number_flash_tween.is_valid():
		number_flash_tween.kill()
	number_label.add_theme_color_override("font_color", colour)
	number_flash_tween = create_tween()
	number_flash_tween.tween_property(number_label, "theme_override_colors/font_color", Color("f5f5f3"), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## A short horizontal rattle reserved for boss hits, so the heaviest loss in
## the game reads as a bigger event than routine tax rather than just a
## brighter colour.
func _shake_number() -> void:
	if state.settings.reduce_motion:
		return
	var tween := create_tween()
	tween.tween_property(number_col, "position:x", -8.0, 0.04)
	tween.tween_property(number_col, "position:x", 8.0, 0.06)
	tween.tween_property(number_col, "position:x", -4.0, 0.06)
	tween.tween_property(number_col, "position:x", 0.0, 0.05)

## A one-shot radial flash behind the number on impact. Kept as its own
## temporary node (freed when done) rather than driving stage_glow directly,
## since stage_glow's modulate is already being written every frame by
## _update_stage_colour and a tween on the same property would just be
## overwritten the next frame.
func _pulse_stage_impact(colour: Color) -> void:
	if state.settings.reduce_motion:
		return
	var flash := TextureRect.new()
	flash.texture = _make_radial_glow(Color.WHITE, 360)
	flash.custom_minimum_size = Vector2(360, 360)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	flash.modulate = Color(colour.r, colour.g, colour.b, 0.0)
	ring.get_parent().add_child(flash)
	ring.get_parent().move_child(flash, ring.get_index())
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.9, 0.05)
	tween.tween_property(flash, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

## How close the current wave is to its Collection hit, 0 (safe) to 1 (about
## to land). Zero whenever no hit is coming: outside a run, during grace, or
## once Liability is already cleared for the wave.
func _stage_danger_progress() -> float:
	if not state.in_run:
		return 0.0
	var encounter: Variant = state.active_encounter
	if encounter == null or encounter.max_liability.is_zero() or encounter.is_cleared():
		return 0.0
	return clampf(state.wave_accumulator / GameState.WAVE_INTERVAL_SECONDS, 0.0, 1.0)

## Drives the stage ring: its arc is how much Liability is cleared, its colour
## is how near the Collection hit is. The glow follows the same colour so the
## whole stage warms together as the hit approaches.
func _update_stage_colour() -> void:
	var colour := _heat_colour(_stage_danger_progress())
	ring.set_arc(_liability_cleared(), colour)
	stage_glow.modulate = colour

## Accent to warning through hue rather than straight RGB, which would pass
## through a muddy olive on the way.
func _heat_colour(t: float) -> Color:
	if t <= 0.0:
		return ACCENT
	var eased := clampf(t, 0.0, 1.0)
	return Color.from_hsv(
		lerpf(ACCENT.h, WARNING.h, eased),
		lerpf(ACCENT.s, WARNING.s, eased),
		lerpf(ACCENT.v, WARNING.v, eased)
	)

## How much of this wave's Liability production has already cleared. A wave
## with nothing due, or one already cleared, reads as a closed ring.
func _liability_cleared() -> float:
	if not state.in_run:
		return 0.0
	var encounter: Variant = state.active_encounter
	if encounter == null or encounter.max_liability.is_zero() or encounter.is_cleared():
		return 1.0
	var remaining: float = encounter.remaining_liability.log10()
	var total: float = encounter.max_liability.log10()
	if is_inf(remaining):
		return 1.0
	# Liability spans orders of magnitude, so the arc tracks the ratio of the
	# real values rather than their logs.
	var ratio: float = pow(10.0, remaining - total)
	return clampf(1.0 - ratio, 0.0, 1.0)

## Moves the displayed number toward the true value every frame instead of
## snapping to it, so production reads as a smooth climb even across
## order-of-magnitude jumps. ScientificNumber is mantissa x 10^exponent, so
## interpolation happens in log space (log10(mantissa) + exponent) rather than
## lerping mantissa directly, which would jump the instant the exponent ticks
## over. Discrete resets (run start/end, death, prestige, clearing the save)
## call _snap_number_display() instead of easing into them.
func _advance_display_number(delta: float) -> void:
	var target := -INF if state.number.is_zero() else state.number.log10()
	if state.settings.reduce_motion or is_inf(display_log_value) or is_inf(target):
		display_log_value = target
		return
	display_log_value = lerp(display_log_value, target, clampf(delta * NUMBER_SMOOTH_RATE, 0.0, 1.0))

func _snap_number_display() -> void:
	display_log_value = -INF if state.number.is_zero() else state.number.log10()

func _refresh_number_display() -> void:
	var display_number := ScientificNumber.new()
	if not is_inf(display_log_value):
		var exponent := floori(display_log_value)
		display_number = ScientificNumber.new(pow(10.0, display_log_value - float(exponent)), exponent)
	number_label.text = display_number.format_value()
	number_label.add_theme_font_size_override("font_size", _number_font_size(number_label.text))

## The number has to sit inside the ring, so its size follows the ring's radius
## and then the measured width of the string it actually has: "9.99e42" and
## "1,048,576" are very different widths at the same font size.
func _number_font_size(text: String) -> int:
	var radius := 168.0
	if ring != null and ring.radius() > 0.0:
		radius = ring.radius()
	var available := radius * 1.62
	var ideal := int(clampf(radius * 0.46, 22.0, 96.0))
	var font := number_label.get_theme_font("font")
	if font == null or text.is_empty():
		return ideal
	var measured := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ideal).x
	if measured <= available or measured <= 0.0:
		return ideal
	return int(clampf(float(ideal) * (available / measured), 16.0, float(ideal)))

func _make_label(content: String, font_size: int, alignment: HorizontalAlignment, colour: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	return label

## A borderless, textless base button meant to be dressed up with an overlaid
## label layout — used by compact stat-tile cards (Labs' focus tiles, locked
## panels) so each can show a small title line and a large value line, which
## a plain Button (one font size for its whole text) cannot do on its own.
func _make_tile_button() -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("disabled", _panel_style(Color("141923"), 12, Color.TRANSPARENT))
	return button

func _tile_layout(button: Button, margin_lr: int, margin_tb: int) -> VBoxContainer:
	var inner_margin := MarginContainer.new()
	inner_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_margin.add_theme_constant_override("margin_left", margin_lr)
	inner_margin.add_theme_constant_override("margin_right", margin_lr)
	inner_margin.add_theme_constant_override("margin_top", margin_tb)
	inner_margin.add_theme_constant_override("margin_bottom", margin_tb)
	button.add_child(inner_margin)
	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 2)
	inner_margin.add_child(layout)
	return layout

## The row-shaped equivalent of _make_tile_button/_tile_layout, used by the
## Workshop and Cards upgrade lists: an icon chip beside a title+bar column
## beside a right-aligned value, instead of a stacked tile.
func _make_row_button() -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 104)
	button.add_theme_stylebox_override("disabled", _panel_style(SURFACE, 14, Color.TRANSPARENT))
	return button

func _row_layout(button: Button, margin_lr: int, margin_tb: int) -> HBoxContainer:
	var inner_margin := MarginContainer.new()
	inner_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_margin.add_theme_constant_override("margin_left", margin_lr)
	inner_margin.add_theme_constant_override("margin_right", margin_lr)
	inner_margin.add_theme_constant_override("margin_top", margin_tb)
	inner_margin.add_theme_constant_override("margin_bottom", margin_tb)
	button.add_child(inner_margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	inner_margin.add_child(row)
	return row

func _chip_style(colour: Color) -> StyleBoxFlat:
	var style := _panel_style(colour, 8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _tag_style(colour: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(colour.r, colour.g, colour.b, 0.18)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _panel_style(colour: Color, radius: int, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.border_width_left = 1 if border != Color.TRANSPARENT else 0
	style.border_width_right = 1 if border != Color.TRANSPARENT else 0
	style.border_width_top = 1 if border != Color.TRANSPARENT else 0
	style.border_width_bottom = 1 if border != Color.TRANSPARENT else 0
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

## Two decimals at most, with trailing zeros dropped, so 1.05 and 6 both read
## naturally on a card.
func _trim(value: float) -> String:
	var text := "%.2f" % value
	if text.contains("."):
		text = text.rstrip("0").rstrip(".")
	return text

## A stat, not a Number: under a thousand it keeps its decimals, because the
## Number formatter rounds to whole units and a rank worth 0.08 would read as
## zero. Above that the Number formatter's abbreviations take over.
func _stat_number(value: ScientificNumber) -> String:
	if value.exponent < 3:
		return _trim(value.mantissa * pow(10.0, value.exponent))
	return value.format_value()

## Coins share the Number formatter: full digits under a million, abbreviated
## above it, so a growing balance never widens the chip that holds it.
func _coins(amount: int) -> String:
	return ScientificNumber.from_float(float(amount)).format_value()

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()

func _format_duration(seconds: float) -> String:
	if seconds < 60.0:
		return str(int(seconds)) + " SEC"
	if seconds < 3600.0:
		return str(int(seconds / 60.0)) + " MIN"
	return str(int(seconds / 3600.0)) + " H"
