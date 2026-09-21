extends Control

const SAVE_INTERVAL_SECONDS := 20.0
const BACKGROUND := Color("0d1016")
const SURFACE := Color("171c26")
const SURFACE_HOVER := Color("202838")
const TEXT := Color("f4f7fb")
const MUTED_TEXT := Color("8f9aac")
# Event colour is valence, not event type: mint = gain, amber = exciting gain,
# red = loss. Severity within a valence (routine tax vs a boss hit) is shown
# through a deeper/more saturated shade of the same hue plus stronger motion,
# not a separate colour the player would have to learn on its own.
const ACCENT := Color("91f5c4")
const CRITICAL := Color("ffcf6b")
const DANGER := Color("ff9e9e")
const BOSS_DANGER := Color("ff4d6d")
const COIN_ACCENT := Color("e8a23c")

# Each screen gets its own accent instead of one colour for everything, so
# Workshop / Labs / Cards read as distinct places rather than one long list.
# These match the floating dock's per-tab colours one for one.
const WORKSHOP_ACCENT := ACCENT
const LABS_ACCENT := Color("7ec8ff")
const CARDS_ACCENT := Color("d9a5ff")

const BAY_ICON := {
	"output": 6, # IconGlyph.Kind.CHART
	"speed": 7, # IconGlyph.Kind.BOLT
	"chance": 8, # IconGlyph.Kind.DICE
	"logic": 9, # IconGlyph.Kind.CHIP
}

const TAB_IDS: Array[String] = ["number", "workshop", "labs", "cards"]
const TAB_NAMES := {"number": "NUMBER", "workshop": "WORKSHOP", "labs": "LABS", "cards": "CARDS", "settings": "SETTINGS"}

var state := GameState.new()
# Lifetime Number required before a dock icon even appears tappable. Each
# tab's own feature may still gate further inside itself (e.g. Labs needs
# Workshop level 12). "settings" gates the stats/settings sheet the same way
# the old top-right MENU button used to appear only once the player was in.
var tab_unlock_lifetime := {"number": 0.0, "workshop": 10.0, "labs": 1000.0, "cards": GameState.PRESTIGE_TEASER_UNLOCK, "settings": 10.0}
var save_elapsed := 0.0
var refresh_elapsed := 0.0

var number_button: Button
var number_display_lead: Label
var number_display_tail: Label
var number_col: VBoxContainer
var rate_label: Label
var tap_hint: Label
var level_label: Label
var floating_text_layer: Control
var ring_a: Panel
var ring_tween: Tween
var stage_glow: TextureRect
var number_flash_tween: Tween
# Smoothed log10 of the displayed Number (log10(mantissa) + exponent), eased
# toward the true value every frame instead of snapping to it. -INF means 0.
var display_log_value := -INF
var stage_alert := false

const NUMBER_SMOOTH_RATE := 12.0
const RING_ALERT_THRESHOLD := 0.55

var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween

var wave_label: Label
var run_coins_label: Label
var tier_selector: OptionButton
var brace_button: Button
var shield_button: Button
var run_button: Button

var died_screen: Control
var died_wave_label: Label
var died_coins_label: Label
var died_knowledge_label: Label
var died_peak_label: Label

var nav_dock: NavDock
var drawer: Control
var drawer_content: VBoxContainer
var stats_grid: GridContainer

var workshop_header: Label
var workshop_board_row: HBoxContainer
var workshop_detail: VBoxContainer
var workshop_tab_buttons: Dictionary = {}
var workshop_tab_icons: Dictionary = {}
var workshop_tab_labels: Dictionary = {}
var workshop_lock_badges: Dictionary = {}

var labs_content: VBoxContainer
var cards_content: VBoxContainer
var cards_knowledge_label: Label

var screens: Dictionary = {}
# The content root inside each slide-up screen, kept separately so it (not
# the screen wrapper) is what tweens into place on selection.
var tab_panels: Dictionary = {}
var current_tab := "number"
var offline_message := ""
var drawer_elapsed := 0.0
var dock_signature := ""
var audio_feedback: AudioFeedback
var background_rect: ColorRect

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
	_refresh_all()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		state.save()

func _process(delta: float) -> void:
	var events := state.advance(delta)
	for event in events:
		if event.is_critical:
			_spawn_floating_text("CRITICAL +" + event.amount.format_value(), CRITICAL, floating_text_layer.size * Vector2(0.5, 0.42))
			_pulse_number(1.06)
			_flash_number(CRITICAL)
		elif event.type == "tax_collection":
			_show_toast("TAX COLLECTED  -" + event.amount.format_value(), DANGER)
			_flash_number(DANGER)
			_pulse_stage_impact(DANGER)
		elif event.type == "boss_collection":
			_show_toast("BOSS COLLECTION  -" + event.amount.format_value(), BOSS_DANGER)
			_flash_number(BOSS_DANGER, 0.5)
			_pulse_stage_impact(BOSS_DANGER)
			_shake_number()
			if state.settings.haptics:
				Input.vibrate_handheld(35)
		elif event.type == "boss_clear":
			_show_toast("BOSS CLEARED  ·  +" + event.amount.format_value() + " COINS", CRITICAL)
		elif event.type == "tier_unlock":
			_show_toast("TIER " + event.amount.format_value() + " UNLOCKED", CRITICAL)
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
	background_rect = ColorRect.new()
	background_rect.color = BACKGROUND
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)

	var content_area := Control.new()
	content_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content_area)
	_build_number_screen(content_area)
	_build_workshop_screen(content_area)
	_build_labs_screen(content_area)
	_build_cards_screen(content_area)

	_build_toast()

	nav_dock = NavDock.new()
	nav_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nav_dock.offset_top = -92
	add_child(nav_dock)
	nav_dock.tab_selected.connect(_on_dock_tab_selected)

	_build_drawer()
	_build_died_screen()

	audio_feedback = AudioFeedback.new()
	add_child(audio_feedback)

	_select_tab("number")
	_start_ring_animation()

## Registers a tab's screen and its fade/slide tween target together, since
## every other builder in this file works through _build_flat_screen instead.
func _register_screen(tab_id: String, screen: Control) -> void:
	screens[tab_id] = screen
	tab_panels[tab_id] = screen

func _build_number_screen(parent: Control) -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(screen)
	_register_screen("number", screen)

	var header := HBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 24
	header.offset_right = -24
	header.offset_top = 20
	header.custom_minimum_size = Vector2(0, 24)
	screen.add_child(header)
	var wordmark := _make_label("NUMBER GO UP", 11, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	wordmark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(wordmark)
	level_label = _make_label("", 11, HORIZONTAL_ALIGNMENT_RIGHT, MUTED_TEXT)
	header.add_child(level_label)

	number_button = Button.new()
	number_button.flat = true
	number_button.focus_mode = Control.FOCUS_NONE
	number_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	number_button.offset_top = 56
	number_button.tooltip_text = "Tap to make Number go up"
	number_button.pressed.connect(_tap_number)
	screen.add_child(number_button)

	# Built white and tinted entirely through modulate, so the ambient danger
	# colour (see _update_stage_colour) can retint it every frame without
	# rebuilding the gradient texture.
	stage_glow = TextureRect.new()
	stage_glow.texture = _make_radial_glow(Color.WHITE, 340)
	stage_glow.modulate = ACCENT
	stage_glow.custom_minimum_size = Vector2(340, 340)
	stage_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_glow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	number_button.add_child(stage_glow)

	ring_a = _make_ring_panel(210, ACCENT)
	ring_a.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ring_a.pivot_offset = Vector2(105, 105)
	number_button.add_child(ring_a)

	var number_center := CenterContainer.new()
	number_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	number_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_button.add_child(number_center)
	number_col = VBoxContainer.new()
	number_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_col.alignment = BoxContainer.ALIGNMENT_CENTER
	number_col.add_theme_constant_override("separation", 10)
	number_col.resized.connect(func(): number_col.pivot_offset = number_col.size / 2.0)
	number_center.add_child(number_col)
	var number_row := HBoxContainer.new()
	number_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_row.add_theme_constant_override("separation", 0)
	number_col.add_child(number_row)
	number_display_lead = Label.new()
	number_display_lead.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_display_lead.add_theme_font_size_override("font_size", 74)
	number_display_lead.add_theme_color_override("font_color", TEXT)
	number_row.add_child(number_display_lead)
	number_display_tail = Label.new()
	number_display_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_display_tail.add_theme_font_size_override("font_size", 74)
	number_display_tail.add_theme_color_override("font_color", MUTED_TEXT)
	number_row.add_child(number_display_tail)
	rate_label = _make_label("", 15, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	number_col.add_child(rate_label)
	tap_hint = _make_label("TAP ANYWHERE", 11, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	number_col.add_child(tap_hint)

	floating_text_layer = Control.new()
	floating_text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_text_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	number_button.add_child(floating_text_layer)

	_build_run_bar(number_button)

## Compact Tax-run control surface: tier choice, two-axis encounter status,
## permanent defence and the explicit start/retreat boundary.
func _build_run_bar(parent: Control) -> void:
	var bar := VBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 24
	bar.offset_right = -24
	bar.offset_bottom = -124
	bar.offset_top = -334
	bar.add_theme_constant_override("separation", 8)
	parent.add_child(bar)

	wave_label = _make_label("", 13, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	bar.add_child(wave_label)
	run_coins_label = _make_label("", 12, HORIZONTAL_ALIGNMENT_CENTER, COIN_ACCENT)
	bar.add_child(run_coins_label)
	tier_selector = OptionButton.new()
	tier_selector.focus_mode = Control.FOCUS_NONE
	tier_selector.custom_minimum_size = Vector2(0, 34)
	tier_selector.add_theme_font_size_override("font_size", 12)
	tier_selector.add_theme_color_override("font_color", TEXT)
	tier_selector.add_theme_color_override("font_disabled_color", MUTED_TEXT)
	tier_selector.add_theme_stylebox_override("normal", _panel_style(SURFACE, 12))
	tier_selector.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 12, ACCENT))
	tier_selector.add_theme_stylebox_override("pressed", _panel_style(SURFACE_HOVER, 12))
	tier_selector.add_theme_stylebox_override("disabled", _panel_style(Color(1, 1, 1, 0.04), 12))
	for tier in state.balance_profile.tiers:
		tier_selector.add_item("TIER " + str(tier.id), tier.id)
	tier_selector.item_selected.connect(_on_tier_selected)
	bar.add_child(tier_selector)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 8)
	bar.add_child(action_row)
	brace_button = _make_pill_button("BRACE", DANGER, 130)
	brace_button.tooltip_text = "Spend 30% of Number to block the next Collection hit."
	brace_button.pressed.connect(_on_brace_pressed)
	action_row.add_child(brace_button)
	shield_button = _make_pill_button("SHIELD", ACCENT, 150)
	shield_button.tooltip_text = "Spend Coins for a permanent reduction to Collection. Survives every reset."
	shield_button.pressed.connect(_on_shield_matrix_pressed)
	action_row.add_child(shield_button)

	run_button = Button.new()
	run_button.focus_mode = Control.FOCUS_NONE
	run_button.custom_minimum_size = Vector2(0, 50)
	run_button.add_theme_font_size_override("font_size", 14)
	run_button.add_theme_color_override("font_color", Color("0d1016"))
	run_button.add_theme_color_override("font_hover_color", Color("0d1016"))
	run_button.pressed.connect(_on_run_button_pressed)
	bar.add_child(run_button)

func _make_pill_button(content: String, colour: Color, width: float) -> Button:
	var button := Button.new()
	button.text = content
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(width, 44)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", colour)
	button.add_theme_color_override("font_hover_color", colour)
	button.add_theme_color_override("font_disabled_color", MUTED_TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(Color(colour.r, colour.g, colour.b, 0.1), 999, Color(colour.r, colour.g, colour.b, 0.4)))
	button.add_theme_stylebox_override("hover", _panel_style(Color(colour.r, colour.g, colour.b, 0.18), 999, colour))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(1, 1, 1, 0.04), 999, Color.TRANSPARENT))
	return button

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

func _make_ring_panel(diameter: int, colour: Color) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(diameter, diameter)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(colour.r, colour.g, colour.b, 0.24)
	style.set_border_width_all(1)
	style.set_corner_radius_all(diameter / 2)
	panel.add_theme_stylebox_override("panel", style)
	return panel

## The single expanding "core" ring behind the number: scales up and fades
## out on an endless loop, restarting cleanly each time via from().
func _start_ring_animation() -> void:
	if ring_tween != null and ring_tween.is_valid():
		ring_tween.kill()
	if bool(state.settings.reduce_motion):
		ring_a.visible = false
		return
	ring_a.visible = true
	# Faster breathing while a Collection hit is imminent (see
	# _update_stage_colour), so the ring's pace itself signals urgency.
	var duration := 1.1 if stage_alert else 2.2
	ring_tween = create_tween()
	ring_tween.set_loops()
	ring_tween.tween_property(ring_a, "scale", Vector2(1.9, 1.9), duration).from(Vector2(0.7, 0.7)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ring_tween.parallel().tween_property(ring_a, "modulate:a", 0.0, duration).from(0.6)

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

func _build_workshop_screen(parent: Control) -> void:
	var content := _build_flat_screen(parent, "workshop")
	var header_row := HBoxContainer.new()
	content.add_child(header_row)
	var title := _make_label("Permanent Workshop", 19, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
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

	content.add_child(_make_label("CHOOSE A BAY", 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	workshop_board_row = HBoxContainer.new()
	workshop_board_row.add_theme_constant_override("separation", 8)
	content.add_child(workshop_board_row)
	for bay in ProgressionTaxonomy.WORKSHOP_BAYS:
		workshop_board_row.add_child(_make_bay_tab(bay))
	content.add_child(HSeparator.new())

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(detail_scroll)
	workshop_detail = VBoxContainer.new()
	workshop_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workshop_detail.add_theme_constant_override("separation", 10)
	detail_scroll.add_child(workshop_detail)

func _make_bay_tab(bay: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 64)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var layout := _tile_layout(button, 4, 10)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon_wrap := CenterContainer.new()
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := IconGlyph.new(BAY_ICON[bay], MUTED_TEXT, 18.0)
	icon_wrap.add_child(icon)
	layout.add_child(icon_wrap)
	var label := _make_label(ProgressionTaxonomy.bay_name(bay), 9, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	layout.add_child(label)
	var lock_badge := IconGlyph.new(IconGlyph.Kind.LOCK, MUTED_TEXT, 10.0)
	lock_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lock_badge.position += Vector2(-4, 4)
	button.add_child(lock_badge)
	button.pressed.connect(func(selected: String = bay):
		state.workshop.selected_bay = selected
		_refresh_workshop()
	)
	workshop_tab_buttons[bay] = button
	workshop_tab_icons[bay] = icon
	workshop_tab_labels[bay] = label
	workshop_lock_badges[bay] = lock_badge
	return button

func _build_labs_screen(parent: Control) -> void:
	var content := _build_flat_screen(parent, "labs")
	content.add_child(_make_label("Labs", 19, HORIZONTAL_ALIGNMENT_LEFT, TEXT))
	content.add_child(_make_label("RESEARCH FOCUS", 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	var description := _make_label("Pick one Workshop bay to discount by 25%. It locks in until your next Prestige.", 13, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
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

func _build_cards_screen(parent: Control) -> void:
	var content := _build_flat_screen(parent, "cards")
	var header_row := HBoxContainer.new()
	content.add_child(header_row)
	var title := _make_label("Cards", 19, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
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
	content.add_child(_make_label("INSIGHTS", 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	cards_content = VBoxContainer.new()
	cards_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_content.add_theme_constant_override("separation", 10)
	scroll.add_child(cards_content)

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
	toast_panel = PanelContainer.new()
	toast_panel.modulate.a = 0.0
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override("panel", _panel_style(Color("171c26"), 12, Color(1, 1, 1, 0.08)))
	center.add_child(toast_panel)
	toast_label = _make_label("", 12, HORIZONTAL_ALIGNMENT_CENTER, ACCENT)
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

	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 14)
	stats_grid.add_theme_constant_override("v_separation", 14)
	stats_column.add_child(stats_grid)
	stats_column.add_child(HSeparator.new())

	var toggle_box := VBoxContainer.new()
	toggle_box.add_theme_constant_override("separation", 14)
	stats_column.add_child(toggle_box)
	for setting in [["muted", "Mute sound"], ["haptics", "Haptics"], ["reduce_motion", "Reduce motion"], ["high_contrast", "High contrast"]]:
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
			if key == "reduce_motion":
				_start_ring_animation()
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

	inner.add_child(_make_label("RUN OVER", 12, HORIZONTAL_ALIGNMENT_CENTER, DANGER))
	died_wave_label = _make_label("", 26, HORIZONTAL_ALIGNMENT_CENTER, TEXT)
	inner.add_child(died_wave_label)
	var subtitle := _make_label("The equation finally asked for more than you had. Your Workshop was retained.", 12, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(subtitle)
	inner.add_child(HSeparator.new())

	died_coins_label = _make_label("", 14, HORIZONTAL_ALIGNMENT_CENTER, COIN_ACCENT)
	inner.add_child(died_coins_label)
	died_knowledge_label = _make_label("", 14, HORIZONTAL_ALIGNMENT_CENTER, CARDS_ACCENT)
	inner.add_child(died_knowledge_label)
	died_peak_label = _make_label("", 12, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	inner.add_child(died_peak_label)

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

func _show_died_screen(summary: RunSummary) -> void:
	if summary == null or died_screen == null:
		return
	died_wave_label.text = "TIER " + str(summary.tier_id) + "  ·  WAVE " + str(summary.wave_reached)
	died_coins_label.text = "+" + str(summary.coins_earned) + " COINS EARNED"
	if summary.knowledge_gained > 0:
		died_knowledge_label.text = "+" + str(summary.knowledge_gained) + " KNOWLEDGE"
		died_knowledge_label.visible = true
	else:
		died_knowledge_label.visible = false
	died_peak_label.text = "PEAK NUMBER  ·  " + summary.peak_number.format_value()
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
	elif tab_id == "labs":
		_refresh_labs()
	elif tab_id == "cards":
		_refresh_cards()
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
	var event := state.tap()
	var spawn_pos := floating_text_layer.get_local_mouse_position()
	if not Rect2(Vector2.ZERO, floating_text_layer.size).has_point(spawn_pos):
		spawn_pos = floating_text_layer.size * Vector2(0.5, 0.42)
	if event.is_critical:
		_spawn_floating_text("CRITICAL +" + event.amount.format_value(), CRITICAL, spawn_pos)
		_pulse_number(1.09)
		_flash_number(CRITICAL)
	else:
		_spawn_floating_text("+" + event.amount.format_value(), ACCENT, spawn_pos)
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

func _on_tier_selected(index: int) -> void:
	var tier_id := tier_selector.get_item_id(index)
	if state.select_tier(tier_id):
		_show_toast("TIER " + str(tier_id) + " SELECTED", ACCENT)
		state.save()
	else:
		_show_toast("TIER LOCKED", MUTED_TEXT)
	_refresh_all()

func _on_brace_pressed() -> void:
	if state.brace():
		_show_toast("BRACED FOR NEXT WAVE", ACCENT)
		_refresh_all()
	else:
		_show_toast("CANNOT BRACE YET", MUTED_TEXT)

func _on_shield_matrix_pressed() -> void:
	if state.purchase_tax_resistance():
		_show_toast("SHIELD MATRIX +1", ACCENT)
		state.save()
		_refresh_all()
	else:
		_show_toast("NEED " + str(state.get_tax_resistance_cost()) + " COINS", MUTED_TEXT)

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

func _refresh_all() -> void:
	background_rect.color = Color.BLACK if bool(state.settings.high_contrast) else BACKGROUND
	rate_label.visible = true
	rate_label.text = ("+" if state.in_run else "STARTING +") + state.get_rate_per_second().format_value() + "/sec"
	tap_hint.text = "TAP ANYWHERE" if state.in_run else "START A RUN TO PRODUCE"
	level_label.text = "LV " + str(state.get_workshop_level())
	_refresh_run_bar()
	if offline_message != "":
		_show_toast(offline_message, ACCENT)
		offline_message = ""
	_refresh_dock()
	if current_tab == "workshop":
		# Do not rebuild live buttons during the player's press/release cycle.
		# Rebuilding a Control tree every refresh can eat touch releases on Web.
		workshop_header.text = str(state.coins) + " COINS"

## Shows the two independent checks: remaining Liability that production must
## clear and the absolute Collection hit Number must be able to survive.
func _refresh_run_bar() -> void:
	for index in range(tier_selector.item_count):
		var tier_id := tier_selector.get_item_id(index)
		var unlocked := state.is_tier_unlocked(tier_id)
		tier_selector.set_item_disabled(index, not unlocked)
		tier_selector.set_item_text(index, "TIER " + str(tier_id) + ("" if unlocked else "  ·  LOCKED"))
		if tier_id == state.selected_tier:
			tier_selector.select(index)
	tier_selector.disabled = state.in_run
	if not state.in_run:
		wave_label.text = "TIER " + str(state.selected_tier) + "  ·  WORKSHOP LV " + str(state.get_workshop_level()) + " BASELINE"
		wave_label.add_theme_color_override("font_color", MUTED_TEXT)
	else:
		var encounter: Variant = state.active_encounter
		var boss_tag := "  ·  BOSS" if encounter != null and encounter.is_boss else ""
		if encounter == null or encounter.max_liability.is_zero():
			wave_label.text = "WAVE " + str(state.wave) + "  ·  GRACE" + boss_tag
			wave_label.add_theme_color_override("font_color", MUTED_TEXT)
		elif encounter.is_cleared():
			wave_label.text = "WAVE " + str(state.wave) + "  ·  LIABILITY CLEARED" + boss_tag
			wave_label.add_theme_color_override("font_color", ACCENT)
		else:
			var seconds_left := maxi(0, ceili(GameState.WAVE_INTERVAL_SECONDS - state.wave_accumulator))
			wave_label.text = "WAVE " + str(state.wave) + "  ·  LIABILITY " + encounter.remaining_liability.format_value() + "  ·  HIT -" + state.get_effective_collection().format_value() + " IN " + str(seconds_left) + "s" + boss_tag
			wave_label.add_theme_color_override("font_color", CRITICAL if boss_tag != "" else DANGER)
	run_coins_label.text = "COINS " + str(state.coins) + "   ·   TIER BEST " + str(state.get_tier_best())
	brace_button.visible = state.in_run
	brace_button.disabled = not state.can_brace()
	shield_button.disabled = not state.can_purchase_tax_resistance()
	if state.tax_resistance_rank >= GameState.TAX_RESISTANCE_MAX_RANK:
		shield_button.text = "SHIELD MAXED"
	else:
		shield_button.text = "SHIELD +1 (" + str(state.get_tax_resistance_cost()) + ")"
	if state.in_run:
		run_button.text = "RETREAT & RESET"
		run_button.add_theme_stylebox_override("normal", _panel_style(DANGER, 999))
		run_button.add_theme_stylebox_override("hover", _panel_style(DANGER.lightened(0.1), 999))
	else:
		run_button.text = "START FROM WORKSHOP LV " + str(state.get_workshop_level())
		run_button.add_theme_stylebox_override("normal", _panel_style(ACCENT, 999))
		run_button.add_theme_stylebox_override("hover", _panel_style(ACCENT.lightened(0.1), 999))

func _refresh_workshop() -> void:
	workshop_header.text = str(state.coins) + " COINS"
	for bay in ProgressionTaxonomy.WORKSHOP_BAYS:
		var active: bool = state.workshop.selected_bay == bay
		var unlocked := state.is_bay_active(bay)
		var colour: Color = WORKSHOP_ACCENT if (active and unlocked) else MUTED_TEXT
		(workshop_tab_icons[bay] as IconGlyph).set_glyph_color(colour)
		(workshop_tab_labels[bay] as Label).add_theme_color_override("font_color", colour)
		var button: Button = workshop_tab_buttons[bay]
		button.disabled = not unlocked
		var border: Color = WORKSHOP_ACCENT if (active and unlocked) else Color.TRANSPARENT
		var fill: Color = Color(WORKSHOP_ACCENT.r, WORKSHOP_ACCENT.g, WORKSHOP_ACCENT.b, 0.14) if (active and unlocked) else Color.TRANSPARENT
		button.add_theme_stylebox_override("normal", _panel_style(fill, 14, border))
		button.add_theme_stylebox_override("disabled", _panel_style(Color.TRANSPARENT, 14, Color.TRANSPARENT))
		(workshop_lock_badges[bay] as IconGlyph).visible = not unlocked
	_refresh_workshop_detail()

func _refresh_workshop_detail() -> void:
	_clear_children(workshop_detail)
	var bay := state.workshop.selected_bay
	if not ProgressionTaxonomy.WORKSHOP_BAYS.has(bay):
		bay = "output"
		state.workshop.selected_bay = bay
	var description := _make_label(ProgressionTaxonomy.bay_description(bay), 13, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	workshop_detail.add_child(description)
	if state.in_run:
		workshop_detail.add_child(_make_locked_panel("AVAILABLE BETWEEN RUNS", "Current ranks are active now and will be retained when this run ends."))
	if not state.is_bay_active(bay):
		workshop_detail.add_child(_make_locked_panel("REACH WORKSHOP LEVEL " + str(state.get_bay_required_level(bay)), "Your current level is " + str(state.get_workshop_level()) + "."))
		return
	var found_next := false
	for definition in state.cards_for_bay(bay):
		var maxed := definition.is_maxed(state.get_owned(definition.id))
		var unlocked := state.is_unlocked(definition)
		var is_next := unlocked and not maxed and not found_next
		if is_next:
			found_next = true
		workshop_detail.add_child(_make_ranked_card(definition, BAY_ICON[bay], is_next))

func _refresh_labs() -> void:
	_clear_children(labs_content)
	if state.get_workshop_level() < GameState.RESEARCH_WORKSHOP_LEVEL:
		labs_content.add_child(_make_locked_panel("REACH WORKSHOP LEVEL " + str(GameState.RESEARCH_WORKSHOP_LEVEL), "Your current level is " + str(state.get_workshop_level()) + "."))
		return
	if state.focus_path != "":
		labs_content.add_child(_make_focus_locked_card(state.focus_path))
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	labs_content.add_child(grid)
	for bay in ProgressionTaxonomy.WORKSHOP_BAYS:
		grid.add_child(_make_focus_card(bay))

func _make_focus_card(bay: String) -> Button:
	var active := state.is_bay_active(bay)
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
	chip_center.add_child(IconGlyph.new(BAY_ICON[bay], LABS_ACCENT if active else MUTED_TEXT, 15.0))
	layout.add_child(chip)
	layout.add_child(_make_label(ProgressionTaxonomy.bay_name(bay), 13, HORIZONTAL_ALIGNMENT_LEFT, TEXT if active else MUTED_TEXT))
	layout.add_child(_make_label("-25% COST", 10, HORIZONTAL_ALIGNMENT_LEFT, LABS_ACCENT if active else MUTED_TEXT))
	button.pressed.connect(func(chosen_bay: String = bay):
		if state.select_focus(chosen_bay):
			_show_toast("RESEARCH FOCUS SET", LABS_ACCENT)
			state.save()
			_refresh_all()
			_refresh_labs()
	)
	return button

func _make_focus_locked_card(bay: String) -> PanelContainer:
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
	inner.add_child(_make_label(ProgressionTaxonomy.bay_name(bay) + " · Research Focus", 15, HORIZONTAL_ALIGNMENT_CENTER, TEXT))
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _tag_style(LABS_ACCENT))
	badge.add_child(_make_label("LOCKED IN", 11, HORIZONTAL_ALIGNMENT_CENTER, LABS_ACCENT))
	var badge_wrap := CenterContainer.new()
	badge_wrap.add_child(badge)
	inner.add_child(badge_wrap)
	var subtitle := _make_label("-25% Coin cost on every " + ProgressionTaxonomy.bay_name(bay) + " upgrade until your next Prestige.", 12, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
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
			_refresh_cards()
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
	_refresh_cards()

## A row card for a ranked, permanent Coin-funded Workshop upgrade: an icon chip, a
## title with an optional NEXT tag, a thin fill bar for rank, and cost/rank
## at the right.
func _make_ranked_card(definition: UpgradeDefinition, icon_kind: int, is_next: bool) -> Button:
	var owned := state.get_owned(definition.id)
	var maxed := definition.is_maxed(owned)
	var disabled := maxed or not state.is_unlocked(definition) or state.in_run
	var button := _make_row_button()
	button.disabled = disabled
	var border := WORKSHOP_ACCENT if (is_next and not disabled) else Color.TRANSPARENT
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE, 14, border))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 14, WORKSHOP_ACCENT))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("0f5848"), 14, WORKSHOP_ACCENT))
	var row := _row_layout(button, 14, 10)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(36, 36)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip_tint := MUTED_TEXT if disabled else WORKSHOP_ACCENT
	chip.add_theme_stylebox_override("panel", _panel_style(Color(chip_tint.r, chip_tint.g, chip_tint.b, 0.14), 10))
	var chip_center := CenterContainer.new()
	chip_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(chip_center)
	chip_center.add_child(IconGlyph.new(icon_kind, chip_tint, 16.0))
	row.add_child(chip)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 7)
	row.add_child(mid)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	mid.add_child(title_row)
	title_row.add_child(_make_label(definition.title, 14, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT if disabled else TEXT))
	if is_next and not disabled:
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel", _tag_style(WORKSHOP_ACCENT))
		tag.add_child(_make_label("NEXT", 8, HORIZONTAL_ALIGNMENT_CENTER, WORKSHOP_ACCENT))
		title_row.add_child(tag)
	var description_label := _make_label(definition.description, 11, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(description_label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 4)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.max_value = maxf(1, definition.max_rank)
	bar.value = owned
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(1, 1, 1, 0.1)
	bar_bg.set_corner_radius_all(2)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = MUTED_TEXT if disabled else WORKSHOP_ACCENT
	bar_fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bar_bg)
	bar.add_theme_stylebox_override("fill", bar_fill)
	mid.add_child(bar)
	var right := VBoxContainer.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
	var value_text := "MAXED" if maxed else str(state.get_workshop_coin_cost(definition)) + " COINS"
	right.add_child(_make_label(value_text, 14, HORIZONTAL_ALIGNMENT_RIGHT, TEXT if not disabled else MUTED_TEXT))
	right.add_child(_make_label(str(owned) + "/" + str(definition.max_rank), 9, HORIZONTAL_ALIGNMENT_RIGHT, MUTED_TEXT))
	button.pressed.connect(func(upgrade_id: String = definition.id):
		if state.purchase(upgrade_id):
			_show_toast("WORKSHOP IMPROVED", WORKSHOP_ACCENT)
			state.save()
			_refresh_all()
			_refresh_workshop()
		else:
			_show_toast("NEED " + str(state.get_workshop_coin_cost(definition)) + " COINS", MUTED_TEXT)
	)
	return button

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
		["NUMBER / SEC", state.get_rate_per_second().format_value()],
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
	number_display_lead.add_theme_color_override("font_color", colour)
	number_display_tail.add_theme_color_override("font_color", colour)
	number_flash_tween = create_tween()
	number_flash_tween.set_parallel(true)
	number_flash_tween.tween_property(number_display_lead, "theme_override_colors/font_color", TEXT, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	number_flash_tween.tween_property(number_display_tail, "theme_override_colors/font_color", MUTED_TEXT, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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
	number_button.add_child(flash)
	number_button.move_child(flash, ring_a.get_index())
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

## Ties the stage's ring and glow to that danger: calm mint normally, warming
## toward red (or the deeper boss red) as the hit approaches, so the stage
## itself foreshadows the wave outcome instead of staying static.
func _update_stage_colour() -> void:
	var danger := _stage_danger_progress()
	var is_boss := state.in_run and state.active_encounter != null and bool(state.active_encounter.is_boss)
	var hot: Color = BOSS_DANGER if is_boss else DANGER
	var colour := ACCENT
	if danger > RING_ALERT_THRESHOLD:
		var t := (danger - RING_ALERT_THRESHOLD) / (1.0 - RING_ALERT_THRESHOLD)
		colour = ACCENT.lerp(hot, t)
	var style := ring_a.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.border_color = Color(colour.r, colour.g, colour.b, lerpf(0.24, 0.5, danger))
	stage_glow.modulate = colour
	var alert := danger > RING_ALERT_THRESHOLD
	if alert != stage_alert:
		stage_alert = alert
		_start_ring_animation()

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
	var text := display_number.format_value()
	var last_comma := text.rfind(",")
	var lead := text
	var tail := ""
	# Fade the trailing digit group instead of animating it: it is the part that
	# changes almost every refresh, and a static fade reads as calmer than either
	# a flicker or a per-digit roll animation. Skipped under High Contrast.
	if last_comma != -1 and not bool(state.settings.get("high_contrast", false)):
		lead = text.substr(0, last_comma + 1)
		tail = text.substr(last_comma + 1)
	number_display_lead.text = lead
	number_display_tail.text = tail
	var font_size := _number_font_size(display_number)
	number_display_lead.add_theme_font_size_override("font_size", font_size)
	number_display_tail.add_theme_font_size_override("font_size", font_size)

func _number_font_size(display_number: ScientificNumber) -> int:
	# Measure the button the number actually lives in, not the whole canvas: the
	# canvas expands on wide windows, and a font sized from it overflows the panel.
	var width := maxf(size.x, 320.0)
	if number_button != null and number_button.size.x > 0.0:
		width = number_button.size.x
	var scale := 0.105 if display_number.exponent >= 18 else 0.155
	return int(clampf(width * scale, 24.0, 96.0))

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

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()

func _format_duration(seconds: float) -> String:
	if seconds < 60.0:
		return str(int(seconds)) + " SEC"
	if seconds < 3600.0:
		return str(int(seconds / 60.0)) + " MIN"
	return str(int(seconds / 3600.0)) + " H"
