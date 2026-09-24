extends Control

const SAVE_INTERVAL_SECONDS := 20.0
# The Instrument look (D049): a near-black ground, borderless surfaces a step
# lighter, and three greys for text, so containers read by fill, not outline.
const BACKGROUND_TOP := Color("111213")
const BACKGROUND_BOTTOM := Color("0f1011")
const BACKGROUND := BACKGROUND_BOTTOM
const SURFACE := Color("17181a")
const SURFACE_RAISED := Color("1c1d20")
const SURFACE_HOVER := Color("222326")
const SHEET := Color("151618")
const LINE := Color("232427")
const TEXT := Color("ececea")
const MUTED_TEXT := Color("8b8c88")
const FAINT_TEXT := Color("5e5f5c")
const DIVIDER := Color("1e1f21")
const ACCENT_INK := Color("0d1016")

# One accent carries every positive state, and a single warning carries every
# negative one. Severity inside a valence (routine tax against a boss hit) is
# motion and duration, never an extra hue: more colours on this HUD read as
# noise rather than as meaning.
const ACCENT := Color("8fbfa8")
const WARNING := Color("d68e5c")
# Currency icons are the one exception (D049): gold and blue say which
# currency, not good or bad, so they stay on the icons and never tint amounts.
const COIN_COLOUR := Color("d4b04e")
const GEM_COLOUR := Color("6aa6d6")
# Bosses are red (D051, owner direction): their number, the BOSS WAVE label and
# their Hit, so the fight that stays apart from the waves that pass reads at a
# glance. The second exception to one accent and one warning.
const BOSS_COLOUR := Color("e0625a")
const UI_FONT_PATH := "res://assets/fonts/Geist.ttf"
## Every number on screen is monospaced, so a climbing value never jitters.
const NUMBER_FONT_PATH := "res://assets/fonts/GeistMono.ttf"
# A critical tick is the one moment worth lifting above the accent, so it
# brightens towards white instead of introducing a third colour.
const CRITICAL := Color("f5f5f3")
const DANGER := WARNING
const BOSS_DANGER := BOSS_COLOUR
const WORKSHOP_ACCENT := ACCENT
const LABS_ACCENT := ACCENT
const CARDS_ACCENT := ACCENT

# Keyed by the literal category ids so this stays a constant expression.
const CATEGORY_ICON := {
	"attack": 7, # IconGlyph.Kind.BOLT
	"defense": 14, # IconGlyph.Kind.SHIELD
	"utility": 9, # IconGlyph.Kind.CHIP
	"ultimate": 12, # IconGlyph.Kind.SPARKLE
}

## The run screen's category strip, flush at the foot of the screen.
const CATEGORY_STRIP_HEIGHT := 60
## How long a card must be held to read it rather than act on it.
const LONG_PRESS_SECONDS := 0.45
## The run screen's vertical budget (D018, D032, D049): the stage starts below
## the wave line with the hit and Brace row under it, and the Upgrades sheet
## sits on the category strip at the foot. Whatever height is left stays empty
## between them, held for systems that will want the upper half later.
const RUN_STAGE_TOP := 84.0
## Where the Number sits in the run arena, as a share of its height (D051).
const NUMBER_HEIGHT_SHARE := 0.72
## Passive damage leaves the Number as one mote this often, carrying what built
## up since the last, so a deep Tick Speed is a stream, not a firehose.
const MOTE_INTERVAL := 0.33
const RUN_SHEET_MIN := 150.0
const RUN_SHEET_MAX := 262.0
const RUN_SHEET_SHARE := 0.31

const TAB_IDS: Array[String] = ["number", "workshop"]
const TAB_NAMES := {"number": "BATTLE", "workshop": "WORKSHOP", "cards": "CARDS", "labs": "LABS", "settings": "SETTINGS"}
## The hub column's widest, so panels do not stretch across a tablet (D048).
const HUB_MAX_WIDTH := 440.0
const HUB_BATTLE_HEIGHT := 56.0
const HUB_RING_SIZE := 232.0
## Lifetime Number required before a row inside the Knowledge sheet can be used.
## These were the Labs and Cards dock gates before D016 moved them inside.
const RESEARCH_UNLOCK := 1000.0
## Non-critical passive ticks are batched into one float rather than one per
## tick: at a deepened Tick Speed, dozens of ticks land per second, and a
## label per tick would be noise (pillar 1) and a node-churn cost, not signal.
const PASSIVE_FLOAT_INTERVAL := 0.45

var state := GameState.new()
# Lifetime Number required before a dock icon even appears tappable. Each
# tab's own feature may still gate further inside itself (e.g. Labs needs
# Workshop level 12). "settings" gates the stats/settings sheet the same way
# the old top-right MENU button used to appear only once the player was in.
var tab_unlock_lifetime := {"number": 0.0, "workshop": 10.0, "cards": 10.0, "labs": 10.0, "settings": 10.0}
var save_elapsed := 0.0
var refresh_elapsed := 0.0
## Batches non-critical tick production into one periodic "+X" float, so
## passive gain becomes visible without spamming a label per tick.
var passive_float_accumulator := ScientificNumber.new()
var passive_float_elapsed := 0.0

var number_button: Button
var number_label: Label
var number_col: VBoxContainer
var rate_label: Label
var tap_hint: Label
var coins_label: Label
var knowledge_label: Label
var gems_label: Label
var gems_button: Button
var floating_text_layer: Control
var arena_fx: ArenaFx
## The box the Number and its rate sit centred in, moved by the layout.
var number_frame: CenterContainer
## The wave as a body closing on the Number over its clock (D050).
var wave_enemy: WaveEnemy
## The encounter the body is drawn for; a new one means a new wave arrived.
var enemy_encounter: Variant = null
## A boss that has reached the Number stays on it and hits again every clock
## (D051): it cannot be knocked back, only (later) slowed.
var enemy_latched := false
## The wave HP dealt since the last passive mote left (D051).
var mote_damage := ScientificNumber.new()
var mote_elapsed := 0.0
var mote_crit := false
## Where along its path the body is drawn, 0 at the arena's top edge and 1 at
## the Number. It is the wave clock.
var enemy_travel := 0.0
## Where across the arena's top edge the wave entered, as a share of its width.
var enemy_entry := 0.5
var stage_glow: TextureRect
## The ring's parent frame. Combat rattles move this rather than the number
## column: a container re-sorts its child whenever the number's width changes,
## which would overwrite a position tween mid-shake.
var stage_root: Control
## Which layout the run screen holds, so it is only reapplied when the run
## state, the tab or the height changes.
var screen_layout_key := ""
## What each open sheet last showed. A sheet rebuilds its buttons only when
## this changes: rebuilding a Control tree every refresh can swap a button out
## between a press and its release, which eats the tap on Web, the reason the
## Workshop already avoids it. Countdowns tick in place instead.
var knowledge_sheet_signature := ""
var lab_sheet_signature := ""
var card_sheet_signature := ""
var lab_status_labels: Dictionary = {}
## Shown in the stage's place between runs, since Number exists only during a
## run (pillar 3) and an empty ring/number stage has nothing live to say.
## The battle hub between runs (D048), in place of the D025 landing panel.
var hub_panel: Control
var hub_column: VBoxContainer
var hub_coins_label: Label
var hub_gems_label: Label
var hub_knowledge_label: Label
var hub_ring: RingArc
var hub_ring_caption: Label
var hub_last_run_label: Label
var hub_last_run_cause: Label
var hub_last_run_hit: Label
var hub_last_run_reward: Label
var hub_last_run_coin: Control
var hub_last_run_extra: Label
var hub_coin_bonus_label: Label
var hub_milestones_label: Label
var hub_knowledge_row_label: Label
var hub_tier_label: Label
var hub_best_wave_label: Label
var hub_reward_label: Label
var hub_prev_tier: Button
var hub_next_tier: Button
var currency_stack: HBoxContainer
var wave_line: HBoxContainer
var milestones_sheet: Control
var milestones_title: Label
var milestones_content: VBoxContainer
var milestones_signature := ""
var tracked_font: FontVariation
var ui_font: Font
var ui_font_medium: FontVariation
var number_font: Font
var number_flash_tween: Tween
# Smoothed log10 of the displayed Number (log10(mantissa) + exponent), eased
# toward the true value every frame instead of snapping to it. -INF means 0.
var display_log_value := -INF

const NUMBER_SMOOTH_RATE := 12.0

## The boss hit's telegraph: the stage glow starts throbbing once the wave clock
## passes this share, at a rate of ~1.3 Hz (radians per millisecond).
const BOSS_TELEGRAPH_START := 0.7
const BOSS_TELEGRAPH_BEAT_RATE := 0.008

var toast_wrap: Control
var toast_panel: PanelContainer
var toast_label: Label
var toast_tween: Tween

var wave_label: Label
var tier_button: Button
var boss_label: Label
var boss_separator: Label
## The row under the stage: a key for the ring's two arcs, and Brace.
var brace_button: Button
var brace_cost_label: Label
var run_button: Button

var rig_panel: Control
var rig_detail: VBoxContainer
var rig_category_header: Label
var rig_cash_label: Label
var rig_multiplier_label: Label
var rig_tab_buttons: Dictionary = {}
var rig_tab_icons: Dictionary = {}
var rig_tab_labels: Dictionary = {}
var rig_tab_marks: Dictionary = {}

var died_screen: Control
var died_title_label: Label
var died_wave_label: Label
var died_coins_label: Label
var died_knowledge_label: Label
var died_knowledge_tile: Control
var died_gems_label: Label
var died_gems_tile: Control
var died_peak_label: Label
var died_cause_label: Label
var died_gap_rows: Control
var died_attack_gap_label: Label
var died_defense_gap_label: Label
var died_knowledge_door: Button

var nav_dock: NavDock
var drawer: Control
var drawer_content: VBoxContainer
var stats_grid: GridContainer

var workshop_header: Label
var workshop_board_row: HBoxContainer
var workshop_detail: VBoxContainer
var workshop_purpose: Label
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
var stat_info_extra: Label
## The Rig panel builds its cards once per category and rank change and
## updates prices in place: rebuilding every refresh swapped a card out under
## a held finger, which ate taps on Web and would break a long press.
var rig_detail_signature := ""
var rig_card_refs: Dictionary = {}
var workshop_tab_buttons: Dictionary = {}

var labs_content: VBoxContainer
var cards_content: VBoxContainer
var cards_knowledge_label: Label
var knowledge_sheet: Control
var knowledge_research_header: Control
var knowledge_insight_header: Control
var coins_button: Button
var knowledge_button: Button

## The Labs sheet (D024): real research, distinct from the Knowledge sheet
## above. Opened from its seat on the bottom bar (D048).
var lab_research_sheet: Control
var lab_research_content: VBoxContainer
var lab_research_slots_label: Label
var lab_slot_button: Button

## The Cards sheet (D027): a permanent, gacha-pulled collection with a capped
## Active set. Opened from its seat on the bottom bar and from the Gems chip (D048).
var card_collection_sheet: Control
var card_collection_active_content: VBoxContainer
var card_collection_active_label: Label
var card_collection_inventory_content: VBoxContainer
var card_collection_gems_label: Label
var card_collection_pull_button: Button

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
	offline_message = _load_status_message(state.load_status)
	if offline_message == "" and state.milestone_gems_caught_up > 0:
		offline_message = "MILESTONES CAUGHT UP  ·  +" + str(state.milestone_gems_caught_up) + " GEMS"
	if not offline.amount.is_zero():
		offline_message = "WELCOME BACK  +" + offline.amount.format_value() + "  /  " + _format_duration(offline.seconds)
		if offline.capped:
			offline_message += " (12H CAP)"
	_snap_number_display()
	_refresh_number_display()
	_refresh_all()

## What the player needs to know about the save the game just opened (D028).
func _load_status_message(status: String) -> String:
	match status:
		GameState.LOAD_RECOVERED:
			return "SAVE RESTORED FROM BACKUP"
		GameState.LOAD_UNREADABLE:
			return "SAVE COULD NOT BE READ  ·  A COPY WAS KEPT  ·  STARTING FRESH"
		GameState.LOAD_NEWER:
			return "SAVE IS FROM A NEWER VERSION  ·  PROGRESS HERE WILL NOT BE SAVED"
	return ""

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		state.save()

func _process(delta: float) -> void:
	var gems_before := state.gems
	var hp_encounter: Variant = state.active_encounter if state.is_wave_standing() else null
	var hp_before: ScientificNumber = hp_encounter.remaining_liability.copy() if hp_encounter != null else null
	var events := state.advance(delta)
	# Gems land with a wave's clear (D030); a boss's toast carries them, and a
	# checkpoint that is not a boss wave gets a toast of its own.
	var gem_gain := state.gems - gems_before
	for event in events:
		if event.is_critical:
			_spawn_floating_text(_output_float_text(event.amount, true), CRITICAL, _stage_float_point())
			_pulse_number(1.06)
			_flash_number(CRITICAL)
		elif event.type == "tick":
			if not event.amount.is_zero():
				passive_float_accumulator = passive_float_accumulator.add(event.amount)
		elif event.type == "tax_collection" or event.type == "boss_collection":
			var boss_hit: bool = event.type == "boss_collection"
			var hit_colour: Color = BOSS_DANGER if boss_hit else DANGER
			_enemy_landed(ACCENT if event.amount.is_zero() else hit_colour)
			if event.amount.is_zero():
				_show_toast("HIT BLOCKED · 0 NUMBER LOST", ACCENT)
				_flash_number(ACCENT)
			else:
				_spawn_floating_text("-" + _stat_number(event.amount) + " NUMBER", hit_colour, _stage_float_point())
				# D037: an ordinary wave hits once and passes; a boss stays and hits again.
				_show_toast(("BOSS HIT · HITS AGAIN IN " + str(int(GameState.WAVE_INTERVAL_SECONDS)) + "s" if boss_hit else "WAVE PASSED") + " · -" + _stat_number(event.amount) + " NUMBER · " + state.number.format_value() + " LEFT", hit_colour)
				_snap_number_display()
				_flash_number(hit_colour, 0.5 if boss_hit else 0.35)
				_pulse_stage_impact(hit_colour)
				_shake_stage(9.0 if boss_hit else 3.5)
				if state.settings.haptics:
					Input.vibrate_handheld(35 if boss_hit else 14)
		elif event.type == "wave_clear" or event.type == "boss_clear":
			var boss_clear: bool = event.type == "boss_clear"
			# A wave beaten after the 2.5-second beat is replaced in the same
			# step, so its body shatters here rather than waiting to be seen.
			_shatter_enemy(boss_clear)
			var clear_colour: Color = CRITICAL if boss_clear else ACCENT
			_pulse_stage_impact(clear_colour)
			_pop_label(wave_label, 1.18 if boss_clear else 1.08)
			if not event.amount.is_zero():
				_pop_label(coins_label, 1.15 if boss_clear else 1.08)
			if boss_clear:
				_show_toast("BOSS BEATEN  ·  +" + event.amount.format_value() + " COINS" + ("  ·  +" + str(gem_gain) + " GEMS" if gem_gain > 0 else ""), CRITICAL)
			elif gem_gain > 0:
				_show_toast("MILESTONE  ·  +" + str(gem_gain) + " GEMS", CRITICAL)
		elif event.type == "tier_unlock":
			_show_toast("TIER " + event.amount.format_value() + " UNLOCKED", CRITICAL)
		elif event.type == "second_wind":
			_enemy_landed(BOSS_DANGER)
			_show_toast("SECOND WIND  ·  " + event.amount.format_value() + " LEFT", CRITICAL)
			_flash_number(CRITICAL, 0.6)
			_pulse_stage_impact(CRITICAL)
			_shake_stage(9.0)
		elif event.type == "wave_death":
			_show_died_screen(state.last_run_summary)
			_snap_number_display()
			state.save()
			passive_float_accumulator = ScientificNumber.new()
	passive_float_elapsed += delta
	if passive_float_elapsed >= PASSIVE_FLOAT_INTERVAL:
		passive_float_elapsed = 0.0
		if not passive_float_accumulator.is_zero():
			_spawn_floating_text(_output_float_text(passive_float_accumulator, false), ACCENT, _stage_float_point())
			passive_float_accumulator = ScientificNumber.new()
	_advance_display_number(delta)
	_refresh_number_display()
	_update_stage_colour()
	# Whatever this step took off the wave that is still standing leaves the
	# Number as a mote (D051); a crit tick makes that mote a bright one.
	if hp_encounter != null and state.active_encounter == hp_encounter and state.is_wave_standing():
		var crit_tick := events.any(func(event): return event.is_critical)
		_gather_passive_damage(hp_before.subtract(hp_encounter.remaining_liability), crit_tick, delta)
	_update_wave_enemy(delta)
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
	_load_fonts()
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
	_build_lab_research_sheet()
	_build_card_collection_sheet()
	_build_milestones_sheet()
	_build_stat_info()
	_build_died_screen()

	audio_feedback = AudioFeedback.new()
	add_child(audio_feedback)

	_select_tab("number")

## Geist for words and Geist Mono for numbers (D049). The theme sets Geist as
## every Control's default, so only numbers need a font of their own.
func _load_fonts() -> void:
	ui_font = load(UI_FONT_PATH)
	number_font = load(NUMBER_FONT_PATH)
	ui_font_medium = _weighted_font(ui_font, 500)
	var ui_theme := Theme.new()
	ui_theme.default_font = ui_font
	theme = ui_theme

func _weighted_font(base: Font, weight: int) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = base
	variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return variation

## Registers a tab's screen and its fade/slide tween target together, since
## every other builder in this file works through _build_flat_screen instead.
func _register_screen(tab_id: String, screen: Control) -> void:
	screens[tab_id] = screen
	tab_panels[tab_id] = screen

## The run screen, staged top to bottom: permanent currency, the run's state
## line, the arena, then the run's own controls sitting above the tab bar.
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
	_build_hub(screen)
	_build_run_controls(screen)
	_build_rig_panel(screen)

	floating_text_layer = Control.new()
	floating_text_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_text_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(floating_text_layer)

## Permanent currency only: what survives the run, so it reads as a different
## class of thing from the run state below it.
## A currency is the door to its own spend (D016): Coins open the Workshop and
## Knowledge opens the Knowledge sheet, which is why neither needs a dock seat.
func _build_currency_stack(parent: Control) -> void:
	var stack := HBoxContainer.new()
	currency_stack = stack
	stack.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	stack.offset_left = 12
	stack.offset_top = 8
	stack.add_theme_constant_override("separation", 0)
	parent.add_child(stack)
	coins_button = _make_currency_row(stack, IconGlyph.Kind.GOLD_COIN, COIN_COLOUR, 12.0, 12, MUTED_TEXT)
	coins_label = coins_button.get_meta("value_label")
	coins_button.tooltip_text = "Open the Workshop"
	coins_button.pressed.connect(func(): _on_dock_tab_selected("workshop"))
	gems_button = _make_currency_row(stack, IconGlyph.Kind.GEM, GEM_COLOUR, 12.0, 12, MUTED_TEXT)
	gems_label = gems_button.get_meta("value_label")
	gems_button.tooltip_text = "Pull a Card"
	gems_button.pressed.connect(_open_card_collection_sheet)
	knowledge_button = _make_currency_row(stack, IconGlyph.Kind.BOOK, MUTED_TEXT, 12.0, 12, MUTED_TEXT)
	knowledge_label = knowledge_button.get_meta("value_label")
	knowledge_button.tooltip_text = "Spend Knowledge"
	knowledge_button.pressed.connect(_open_knowledge_sheet)

## A currency's icon and amount, pressable as the door to its spend. Tall
## enough for a thumb even where the text is small.
func _make_currency_row(parent: Control, icon_kind: int, icon_colour: Color, icon_size: float, font_size: int, text_colour: Color) -> Button:
	var button := Button.new()
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(button)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	var label := _make_number_label("", font_size, HORIZONTAL_ALIGNMENT_LEFT, text_colour)
	value_wrap.add_child(label)
	button.set_meta("value_label", label)
	# The row is laid over the button rather than inside a container, so the
	# button's width follows the row's plus side padding.
	row.minimum_size_changed.connect(func(): button.custom_minimum_size.x = row.get_combined_minimum_size().x + 16)
	row.offset_left = 8
	return button

## Wave, tier and the boss warning on one line, shown during a run; between
## runs the hub's Difficulty panel selects the tier (D048).
func _build_wave_line(parent: Control) -> void:
	var line := HBoxContainer.new()
	wave_line = line
	line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	line.offset_top = 54
	line.offset_bottom = 74
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 10)
	parent.add_child(line)

	wave_label = _make_tracked_label("WAVE 1", 12, TEXT)
	line.add_child(wave_label)
	line.add_child(_make_tracked_label("·", 12, LINE.lightened(0.15)))
	tier_button = Button.new()
	tier_button.flat = true
	tier_button.focus_mode = Control.FOCUS_NONE
	tier_button.add_theme_font_override("font", _tracked_font())
	tier_button.add_theme_font_size_override("font_size", 12)
	tier_button.add_theme_constant_override("outline_size", 0)
	tier_button.add_theme_color_override("font_color", MUTED_TEXT)
	tier_button.add_theme_color_override("font_hover_color", ACCENT)
	tier_button.add_theme_color_override("font_pressed_color", ACCENT)
	tier_button.add_theme_color_override("font_disabled_color", MUTED_TEXT)
	line.add_child(tier_button)
	boss_separator = _make_tracked_label("·", 12, LINE.lightened(0.15))
	line.add_child(boss_separator)
	boss_label = _make_tracked_label("", 12, WARNING)
	line.add_child(boss_label)

## The run arena (D051): everything between the wave line and the Upgrades
## sheet. The Number sits low in it, near the thumb, and each wave drops in
## from the top edge towards it, so the wave's own number and its distance
## carry what D049's two rings did.
func _build_stage(parent: Control) -> void:
	var stage := Control.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_top = 150
	stage.offset_bottom = -250
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stage)
	stage_root = stage

	# Built white and tinted through modulate, so the ring's colour can drive
	# the glow every frame without rebuilding the gradient texture.
	stage_glow = TextureRect.new()
	stage_glow.texture = _make_radial_glow(Color.WHITE, 300, 0.08)
	stage_glow.modulate = ACCENT
	stage_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_glow.anchor_left = 0.5
	stage_glow.anchor_right = 0.5
	stage_glow.offset_left = -150.0
	stage_glow.offset_right = 150.0
	stage.add_child(stage_glow)

	arena_fx = ArenaFx.new()
	arena_fx.accent = ACCENT
	arena_fx.critical = CRITICAL
	arena_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(arena_fx)

	# Centred on NUMBER_HEIGHT_SHARE of the arena's height: a box from twice
	# that share less one down to the foot has its middle there.
	# Placed by _apply_screen_layout, low in the arena and clear of Brace.
	var centre := CenterContainer.new()
	number_frame = centre
	centre.anchor_right = 1.0
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(centre)
	number_col = VBoxContainer.new()
	number_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_col.alignment = BoxContainer.ALIGNMENT_CENTER
	number_col.add_theme_constant_override("separation", 6)
	number_col.resized.connect(func(): number_col.pivot_offset = number_col.size / 2.0)
	centre.add_child(number_col)
	number_label = _make_number_label("", 48, HORIZONTAL_ALIGNMENT_CENTER, Color("f5f5f3"))
	number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_col.add_child(number_label)
	rate_label = _make_number_label("", 13, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	number_col.add_child(rate_label)

	wave_enemy = WaveEnemy.new(number_font)
	wave_enemy.visible = false
	stage.add_child(wave_enemy)

## The battle hub between runs (D048), in the Instrument look (D049): the
## currencies across the top, a ring of the highest wave against the next goal
## with each milestone on the way as a dot, the tier selector, the last run,
## then the doors as a plain list, with BATTLE pinned above the bar. Scrolls
## rather than overlaps on a short screen.
func _build_hub(parent: Control) -> void:
	hub_panel = Control.new()
	hub_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(hub_panel)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hub_panel.add_child(scroll)
	var column := VBoxContainer.new()
	hub_column = column
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	scroll.add_child(column)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 0)
	column.add_child(bar)
	var coins := _make_currency_row(bar, IconGlyph.Kind.GOLD_COIN, COIN_COLOUR, 14.0, 13, TEXT)
	coins.tooltip_text = "Open the Workshop"
	coins.pressed.connect(func(): _on_dock_tab_selected("workshop"))
	hub_coins_label = coins.get_meta("value_label")
	var gems := _make_currency_row(bar, IconGlyph.Kind.GEM, GEM_COLOUR, 14.0, 13, TEXT)
	gems.tooltip_text = "Pull a Card"
	gems.pressed.connect(func(): _on_dock_tab_selected("cards"))
	hub_gems_label = gems.get_meta("value_label")
	var knowledge := _make_currency_row(bar, IconGlyph.Kind.BOOK, MUTED_TEXT, 14.0, 13, TEXT)
	knowledge.tooltip_text = "Spend Knowledge"
	knowledge.pressed.connect(_open_knowledge_sheet)
	hub_knowledge_label = knowledge.get_meta("value_label")

	column.add_child(_make_gap(20))
	var ring_box := Control.new()
	ring_box.custom_minimum_size = Vector2(HUB_RING_SIZE, HUB_RING_SIZE)
	ring_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ring_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(ring_box)
	hub_ring = RingArc.new()
	hub_ring.radius_ratio = (HUB_RING_SIZE * 0.5 - 8.0) / HUB_RING_SIZE
	hub_ring.thickness = 3.0
	hub_ring.marker_colour = ACCENT
	hub_ring.marker_next_colour = TEXT
	hub_ring.cutout_colour = BACKGROUND
	hub_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring_box.add_child(hub_ring)
	var ring_text := VBoxContainer.new()
	ring_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring_text.alignment = BoxContainer.ALIGNMENT_CENTER
	ring_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_text.add_theme_constant_override("separation", 4)
	ring_box.add_child(ring_text)
	ring_text.add_child(_make_tracked_label("HIGHEST WAVE", 11, MUTED_TEXT))
	hub_best_wave_label = _make_number_label("", 72, HORIZONTAL_ALIGNMENT_CENTER, TEXT)
	ring_text.add_child(hub_best_wave_label)
	hub_ring_caption = _make_number_label("", 12, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	ring_text.add_child(hub_ring_caption)

	column.add_child(_make_gap(12))
	var selector := HBoxContainer.new()
	selector.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(selector)
	hub_prev_tier = _make_tier_arrow(-1)
	selector.add_child(hub_prev_tier)
	var tier_text := VBoxContainer.new()
	tier_text.custom_minimum_size = Vector2(96, 0)
	tier_text.alignment = BoxContainer.ALIGNMENT_CENTER
	tier_text.add_theme_constant_override("separation", 2)
	selector.add_child(tier_text)
	hub_tier_label = _make_tracked_label("", 15, TEXT)
	tier_text.add_child(hub_tier_label)
	hub_reward_label = _make_number_label("", 11, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
	tier_text.add_child(hub_reward_label)
	hub_next_tier = _make_tier_arrow(1)
	selector.add_child(hub_next_tier)

	column.add_child(_make_gap(18))
	var last_run := PanelContainer.new()
	var card_style := _panel_style(SURFACE, 12)
	card_style.content_margin_left = 16
	card_style.content_margin_right = 16
	card_style.content_margin_top = 14
	card_style.content_margin_bottom = 14
	last_run.add_theme_stylebox_override("panel", card_style)
	column.add_child(last_run)
	var last_column := VBoxContainer.new()
	last_column.add_theme_constant_override("separation", 6)
	last_run.add_child(last_column)
	var heading := HBoxContainer.new()
	last_column.add_child(heading)
	var heading_title := _make_label("Last run", 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	heading_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_title)
	hub_last_run_label = _make_number_label("", 12, HORIZONTAL_ALIGNMENT_RIGHT, MUTED_TEXT)
	heading.add_child(hub_last_run_label)
	var outcome := HBoxContainer.new()
	outcome.add_theme_constant_override("separation", 6)
	last_column.add_child(outcome)
	hub_last_run_cause = _make_label("", 14, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	outcome.add_child(hub_last_run_cause)
	hub_last_run_hit = _make_number_label("", 14, HORIZONTAL_ALIGNMENT_LEFT, WARNING)
	hub_last_run_hit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outcome.add_child(hub_last_run_hit)
	hub_last_run_reward = _make_number_label("", 14, HORIZONTAL_ALIGNMENT_RIGHT, ACCENT)
	outcome.add_child(hub_last_run_reward)
	hub_last_run_coin = CenterContainer.new()
	hub_last_run_coin.add_child(IconGlyph.new(IconGlyph.Kind.GOLD_COIN, COIN_COLOUR, 12.0))
	outcome.add_child(hub_last_run_coin)
	hub_last_run_extra = _make_label("", 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	last_column.add_child(hub_last_run_extra)

	column.add_child(_make_gap(8))
	hub_milestones_label = _make_hub_row(column, "Milestones", _open_milestones_sheet, true)
	hub_coin_bonus_label = _make_hub_row(column, "Total Coin bonus", Callable(), true)
	hub_knowledge_row_label = _make_hub_row(column, "Knowledge", _open_knowledge_sheet, true)
	_make_hub_row(column, "Stats", func(): _on_dock_tab_selected("settings"), false)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	# Seats for systems still to come (D048), as one quiet line rather than
	# doors that do nothing: tier conditions and challenge runs will enter
	# through the modifier pipeline (architecture law 3).
	var soon := _make_label("Modules · Perks · Challenge runs — coming later", 11, HORIZONTAL_ALIGNMENT_CENTER, FAINT_TEXT)
	soon.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(soon)
	column.add_child(_make_gap(6))

## A fixed vertical gap in a column.
func _make_gap(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap

## One of the hub's doors: a name, what is behind it, and a chevron. With no
## action it is a fact rather than a door, so it shows no chevron.
func _make_hub_row(parent: Control, title: String, on_press: Callable, divided: bool) -> Label:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 48)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if on_press.is_valid() else Control.CURSOR_ARROW
	if on_press.is_valid():
		button.pressed.connect(on_press)
	parent.add_child(button)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	button.add_child(row)
	var name_label := _make_label(title, 14, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_vertical = Control.SIZE_FILL
	row.add_child(name_label)
	var value := _make_number_label("", 13, HORIZONTAL_ALIGNMENT_RIGHT, MUTED_TEXT)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.size_flags_vertical = Control.SIZE_FILL
	row.add_child(value)
	var chevron := CenterContainer.new()
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron.add_child(IconGlyph.new(IconGlyph.Kind.CHEVRON, FAINT_TEXT if on_press.is_valid() else Color.TRANSPARENT, 14.0))
	row.add_child(chevron)
	if divided:
		var line := ColorRect.new()
		line.color = DIVIDER
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		line.offset_top = -1
		button.add_child(line)
	return value

func _make_tier_arrow(direction: int) -> Button:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(44, 44)
	button.tooltip_text = "Next tier" if direction > 0 else "Previous tier"
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(centre)
	var chevron := IconGlyph.new(IconGlyph.Kind.CHEVRON if direction > 0 else IconGlyph.Kind.CHEVRON_LEFT, TEXT, 16.0)
	centre.add_child(chevron)
	button.set_meta("chevron", chevron)
	button.pressed.connect(func(): _step_tier(direction))
	return button

## The run's own controls: Brace, the answer to a Hit the wave will land, in
## the arena's lower corner (D051); and the way out.
func _build_run_controls(parent: Control) -> void:
	brace_button = _make_pill_action("BRACE")
	brace_button.tooltip_text = "Spend a share of Number to block the next hit. Brace Cost lowers the share."
	brace_cost_label = brace_button.get_meta("cost_label")
	brace_button.pressed.connect(_on_brace_pressed)
	parent.add_child(brace_button)

	# Deliberately the quietest control on the screen: ending a run is
	# destructive and rare, so it should never be the thing a thumb finds first.
	run_button = Button.new()
	run_button.flat = true
	run_button.focus_mode = Control.FOCUS_NONE
	run_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	run_button.add_theme_constant_override("outline_size", 0)
	run_button.pressed.connect(_on_run_button_pressed)
	parent.add_child(run_button)

	# Under the Number, where the tap lands, for a player who has not found it.
	tap_hint = _make_tracked_label("TAP TO PRODUCE", 10, FAINT_TEXT)
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number_col.add_child(tap_hint)


## The Upgrades sheet (the Rig in code; D042, D045): buy ranks with Cash during
## a run. A sheet resting on the category strip at the foot of the screen
## (D049), so the upper half stays free; it shows the selected category's rows
## as tiles. Tap a tile to buy, hold it to read it.
func _build_rig_panel(parent: Control) -> void:
	rig_panel = Control.new()
	rig_panel.visible = false
	rig_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(rig_panel)

	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_bottom = -CATEGORY_STRIP_HEIGHT
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = SHEET
	sheet_style.corner_radius_top_left = 20
	sheet_style.corner_radius_top_right = 20
	sheet_style.content_margin_left = 20
	sheet_style.content_margin_right = 20
	sheet_style.content_margin_top = 8
	sheet_style.content_margin_bottom = 10
	sheet.add_theme_stylebox_override("panel", sheet_style)
	rig_panel.add_child(sheet)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	sheet.add_child(content)
	content.add_child(_make_sheet_handle())

	var category_row := HBoxContainer.new()
	category_row.add_theme_constant_override("separation", 10)
	content.add_child(category_row)
	rig_category_header = _make_label("", 15, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	rig_category_header.add_theme_font_override("font", ui_font_medium)
	category_row.add_child(rig_category_header)
	rig_cash_label = _make_number_label("", 12, HORIZONTAL_ALIGNMENT_LEFT, ACCENT)
	rig_cash_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_row.add_child(rig_cash_label)
	category_row.add_child(_make_rig_multiplier_chip())

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(detail_scroll)
	rig_detail = VBoxContainer.new()
	rig_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rig_detail.add_theme_constant_override("separation", 8)
	detail_scroll.add_child(rig_detail)

	_build_rig_category_strip(rig_panel)

## The grab handle at the top of every sheet.
func _make_sheet_handle() -> CenterContainer:
	var handle := Panel.new()
	handle.custom_minimum_size = Vector2(36, 4)
	handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var handle_style := StyleBoxFlat.new()
	handle_style.bg_color = Color("2a2b2e")
	handle_style.set_corner_radius_all(2)
	handle.add_theme_stylebox_override("panel", handle_style)
	var handle_wrap := CenterContainer.new()
	handle_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	handle_wrap.add_child(handle)
	return handle_wrap

## An outlined pill: the verb, and under it what it costs.
func _make_pill_action(verb: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(104, 48)
	var style := _panel_style(Color.TRANSPARENT, 24, Color("2a2b2e"))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE, 24, Color("2a2b2e")))
	button.add_theme_stylebox_override("pressed", _panel_style(SURFACE_HOVER, 24, Color("2a2b2e")))
	button.add_theme_stylebox_override("disabled", style)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 1)
	button.add_child(column)
	var verb_label := _make_tracked_label(verb, 12, TEXT)
	verb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(verb_label)
	var cost_label := _make_number_label("", 10, HORIZONTAL_ALIGNMENT_CENTER, MUTED_TEXT)
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
		tracked_font = _weighted_font(ui_font, 500)
		tracked_font.spacing_glyph = 1
	return tracked_font

## Numbers are set in Geist Mono (D049), so digits keep their width as a value
## climbs and columns of values line up.
func _make_number_label(content: String, font_size: int, alignment: HorizontalAlignment, colour: Color) -> Label:
	var label := _make_label(content, font_size, alignment, colour)
	label.add_theme_font_override("font", number_font)
	return label

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

func _make_radial_glow(colour: Color, diameter: int, strength: float = 0.18) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(colour.r, colour.g, colour.b, strength), Color(colour.r, colour.g, colour.b, 0.0)])
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

## The Workshop (D049): a title, the Coins to spend, the four categories as one
## segmented control at the top, then the open category's rows as a list. Rows
## that are not open yet fold into one line saying what opens them.
func _build_workshop_screen(parent: Control) -> void:
	var content := _build_flat_screen(parent, "workshop")
	var margin := content.get_parent() as MarginContainer
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", int(NavDock.BAR_HEIGHT))
	content.add_theme_constant_override("separation", 0)

	var header_row := HBoxContainer.new()
	content.add_child(header_row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	header_row.add_child(titles)
	var title := _make_label("Workshop", 22, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	title.add_theme_font_override("font", ui_font_medium)
	titles.add_child(title)
	titles.add_child(_make_label("Permanent. Every run starts from here.", 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	var balance := HBoxContainer.new()
	balance.add_theme_constant_override("separation", 7)
	balance.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header_row.add_child(balance)
	var coin_wrap := CenterContainer.new()
	coin_wrap.add_child(IconGlyph.new(IconGlyph.Kind.GOLD_COIN, COIN_COLOUR, 14.0))
	balance.add_child(coin_wrap)
	workshop_header = _make_number_label("", 15, HORIZONTAL_ALIGNMENT_RIGHT, TEXT)
	balance.add_child(workshop_header)

	content.add_child(_make_gap(20))
	workshop_board_row = _build_category_segments(content)

	content.add_child(_make_gap(14))
	var purpose_row := HBoxContainer.new()
	purpose_row.add_theme_constant_override("separation", 8)
	content.add_child(purpose_row)
	workshop_purpose = _make_label("", 13, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	workshop_purpose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	workshop_purpose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purpose_row.add_child(workshop_purpose)
	purpose_row.add_child(_make_multiplier_chip())
	content.add_child(_make_gap(6))

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(detail_scroll)
	workshop_detail = VBoxContainer.new()
	workshop_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workshop_detail.add_theme_constant_override("separation", 0)
	detail_scroll.add_child(workshop_detail)

## Refresh the Rig panel's detail display for the currently selected category.
func _refresh_rig() -> void:
	if rig_panel == null or not rig_panel.visible:
		return
	var category: String = state.workshop.selected_category
	if not ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(category):
		category = ProgressionTaxonomy.ATTACK
		state.workshop.selected_category = category
	rig_category_header.text = ProgressionTaxonomy.category_name(category).capitalize()
	rig_cash_label.text = state.cash.format_value() + " Cash · this run"
	rig_multiplier_label.text = _buy_step_label(category)
	for tab_category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
		var active: bool = category == tab_category
		var colour: Color = TEXT if active else MUTED_TEXT
		(rig_tab_icons[tab_category] as IconGlyph).set_glyph_color(colour)
		(rig_tab_labels[tab_category] as Label).add_theme_color_override("font_color", colour)
		(rig_tab_marks[tab_category] as ColorRect).visible = active
	_refresh_rig_detail(category)

func _refresh_rig_detail(category: String) -> void:
	var signature := "|".join([category, str(state.rig_ranks), str(state.purchased)])
	if signature == rig_detail_signature and not rig_card_refs.is_empty():
		for definition in state.cards_for_category(category):
			if rig_card_refs.has(definition.id):
				_update_rig_card(definition)
		return
	rig_detail_signature = signature
	rig_card_refs.clear()
	_clear_children(rig_detail)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	rig_detail.add_child(grid)
	for definition in state.cards_for_category(category):
		if state.balance_profile.rig_has_row(category, definition.id):
			grid.add_child(_make_rig_stat_card(definition, category))

## The multi-buy control: one press cycles x1 → x5 → x10 → MAX for the open
## category, which is how a player buys a ladder without a hundred taps.
func _make_multiplier_chip() -> Button:
	var button := _make_step_chip()
	workshop_multiplier_label = button.get_meta("label")
	button.pressed.connect(func():
		var category: String = state.workshop.selected_category
		buy_step_index[category] = (_buy_step_index(category) + 1) % GameState.BUY_STEPS.size()
		_refresh_workshop()
	)
	return button

func _make_rig_multiplier_chip() -> Button:
	var button := _make_step_chip()
	rig_multiplier_label = button.get_meta("label")
	button.pressed.connect(func():
		var category: String = state.workshop.selected_category
		buy_step_index[category] = (_buy_step_index(category) + 1) % GameState.BUY_STEPS.size()
		_refresh_rig()
	)
	return button

## A small filled pill holding the buy step; tall enough to press, drawn small.
func _make_step_chip() -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(52, 36)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE_RAISED, 14))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 14))
	button.add_theme_stylebox_override("pressed", _panel_style(SURFACE_HOVER, 14))
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(centre)
	var label := _make_number_label("", 12, HORIZONTAL_ALIGNMENT_CENTER, TEXT)
	centre.add_child(label)
	button.set_meta("label", label)
	return button

func _buy_step_index(category: String) -> int:
	return int(buy_step_index.get(category, 0))

func _buy_step(category: String) -> int:
	return int(GameState.BUY_STEPS[_buy_step_index(category)])

func _buy_step_label(category: String) -> String:
	var step := _buy_step(category)
	return "MAX" if step == GameState.MAX_BUY else "×" + str(step)

## The run's category strip, flush at the foot of the screen and joined to the
## Upgrades sheet above it: the active category carries a short accent bar.
func _build_rig_category_strip(parent: Control) -> HBoxContainer:
	var strip := Panel.new()
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -(CATEGORY_STRIP_HEIGHT)
	strip.offset_bottom = 0
	strip.add_theme_stylebox_override("panel", _panel_style(SHEET, 0))
	parent.add_child(strip)
	var divider := ColorRect.new()
	divider.color = DIVIDER
	divider.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	divider.offset_bottom = 1
	strip.add_child(divider)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 0)
	strip.add_child(row)
	for category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
		row.add_child(_make_rig_category_tab(category))
	return row

## The Workshop's four categories as one segmented control.
func _build_category_segments(parent: Control) -> HBoxContainer:
	var track := PanelContainer.new()
	var track_style := _panel_style(SURFACE, 22)
	track_style.set_content_margin_all(3)
	track.add_theme_stylebox_override("panel", track_style)
	parent.add_child(track)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	track.add_child(row)
	for category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
		row.add_child(_make_category_tab(category))
	return row

func _make_category_tab(category: String) -> Button:
	var button := Button.new()
	button.text = ProgressionTaxonomy.category_name(category).capitalize()
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func(selected: String = category):
		state.workshop.selected_category = selected
		_refresh_workshop()
	)
	workshop_tab_buttons[category] = button
	return button

func _make_rig_category_tab(category: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var layout := _tile_layout(button, 4, 4)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 5)
	var icon_wrap := CenterContainer.new()
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := IconGlyph.new(CATEGORY_ICON[category], MUTED_TEXT, 18.0)
	icon_wrap.add_child(icon)
	layout.add_child(icon_wrap)
	var label := _make_tracked_label(ProgressionTaxonomy.category_name(category), 10, MUTED_TEXT)
	layout.add_child(label)
	var mark := ColorRect.new()
	mark.color = ACCENT
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.anchor_left = 0.5
	mark.anchor_right = 0.5
	mark.offset_left = -10
	mark.offset_right = 10
	mark.offset_top = 0
	mark.offset_bottom = 2
	mark.visible = false
	button.add_child(mark)
	button.pressed.connect(func(selected: String = category):
		state.workshop.selected_category = selected
		_refresh_rig()
	)
	rig_tab_buttons[category] = button
	rig_tab_icons[category] = icon
	rig_tab_labels[category] = label
	rig_tab_marks[category] = mark
	return button

## Research Focus, Insight and Prestige in one sheet (D016). None of the three
## is visited often enough to hold a seat on a three-icon bar: Focus is chosen
## once per Prestige, Insight is one repeatable row, and Prestige is rare and
## irreversible. The Knowledge chip on the run screen opens it.
func _build_knowledge_sheet() -> void:
	knowledge_sheet = Control.new()
	knowledge_sheet.visible = false
	knowledge_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(knowledge_sheet)

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			knowledge_sheet.visible = false
	)
	knowledge_sheet.add_child(scrim)

	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_top = 150
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = SHEET
	sheet_style.corner_radius_top_left = 24
	sheet_style.corner_radius_top_right = 24
	sheet.add_theme_stylebox_override("panel", sheet_style)
	knowledge_sheet.add_child(sheet)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 24)
	sheet.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_sheet_handle())

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
	chip_row.add_child(IconGlyph.new(IconGlyph.Kind.BOOK, MUTED_TEXT, 13.0))
	cards_knowledge_label = _make_number_label("", 12, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
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
	_close_sheets()
	_seat_sheet(knowledge_sheet)
	knowledge_sheet.visible = true
	_refresh_dock()
	_refresh_knowledge()

## The two gates that used to decide whether a dock icon appeared now decide
## whether a row inside the sheet does (D016).
func _refresh_knowledge() -> void:
	if knowledge_sheet == null or not knowledge_sheet.visible:
		return
	cards_knowledge_label.text = str(state.knowledge)
	var research_open := state.highest_number.compare_to(ScientificNumber.from_float(RESEARCH_UNLOCK)) >= 0
	var insight_signature_open := state.highest_number.compare_to(ScientificNumber.from_float(GameState.PRESTIGE_TEASER_UNLOCK)) >= 0
	var signature := "|".join([
		state.knowledge, research_open, insight_signature_open, state.focus_path, state.in_run,
		state.get_workshop_level(), state.get_owned("insight"), state.get_prestige_knowledge_gain(),
	])
	if signature == knowledge_sheet_signature:
		return
	knowledge_sheet_signature = signature
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

## Real research (D024): permanent, paid in Coins, gated by real time rather
## than by Coins alone. Distinct from the Knowledge sheet above, which spends
## Knowledge and has no clock. Opened from the LABS chip on the Workshop
## screen, since Labs spends the same currency the Workshop does.
func _build_lab_research_sheet() -> void:
	lab_research_sheet = Control.new()
	lab_research_sheet.visible = false
	lab_research_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(lab_research_sheet)

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			lab_research_sheet.visible = false
	)
	lab_research_sheet.add_child(scrim)

	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_top = 150
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = SHEET
	sheet_style.corner_radius_top_left = 24
	sheet_style.corner_radius_top_right = 24
	sheet.add_theme_stylebox_override("panel", sheet_style)
	lab_research_sheet.add_child(sheet)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 24)
	sheet.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_sheet_handle())

	var header_row := HBoxContainer.new()
	column.add_child(header_row)
	var title := _make_label("Labs", 19, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _chip_style(SURFACE))
	lab_research_slots_label = _make_label("", 12, HORIZONTAL_ALIGNMENT_LEFT, LABS_ACCENT)
	chip.add_child(lab_research_slots_label)
	header_row.add_child(chip)
	column.add_child(_make_label("PERMANENT · KEEPS RESEARCHING WHILE YOU'RE AWAY", 10, HORIZONTAL_ALIGNMENT_LEFT, LABS_ACCENT))

	# More slots open with Gems (D029). Built once and updated in place, so a
	# refresh cannot swap the button out from under a press.
	lab_slot_button = Button.new()
	lab_slot_button.focus_mode = Control.FOCUS_NONE
	lab_slot_button.custom_minimum_size = Vector2(0, 44)
	lab_slot_button.add_theme_font_size_override("font_size", 13)
	lab_slot_button.add_theme_color_override("font_color", ACCENT_INK)
	lab_slot_button.add_theme_color_override("font_hover_color", ACCENT_INK)
	lab_slot_button.add_theme_color_override("font_disabled_color", MUTED_TEXT)
	lab_slot_button.add_theme_stylebox_override("normal", _panel_style(LABS_ACCENT, 12))
	lab_slot_button.add_theme_stylebox_override("hover", _panel_style(LABS_ACCENT.lightened(0.1), 12))
	lab_slot_button.add_theme_stylebox_override("disabled", _panel_style(SURFACE, 12))
	lab_slot_button.pressed.connect(_on_lab_slot_pressed)
	column.add_child(lab_slot_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	lab_research_content = VBoxContainer.new()
	lab_research_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab_research_content.add_theme_constant_override("separation", 10)
	scroll.add_child(lab_research_content)

func _open_lab_research_sheet() -> void:
	if lab_research_sheet == null:
		return
	if drawer != null and drawer.visible:
		drawer.visible = false
	if knowledge_sheet != null and knowledge_sheet.visible:
		knowledge_sheet.visible = false
	if card_collection_sheet != null and card_collection_sheet.visible:
		card_collection_sheet.visible = false
	if milestones_sheet != null and milestones_sheet.visible:
		milestones_sheet.visible = false
	_seat_sheet(lab_research_sheet)
	lab_research_sheet.visible = true
	_refresh_lab_research()

func _refresh_lab_research() -> void:
	if lab_research_sheet == null or not lab_research_sheet.visible:
		return
	lab_research_slots_label.text = str(state.lab_active_count()) + " / " + str(state.lab_slots_total()) + " SLOTS"
	var slot_cost := state.get_lab_slot_cost()
	lab_slot_button.visible = slot_cost > 0
	lab_slot_button.text = "OPEN SLOT " + str(state.lab_slots_total() + 1) + "  ·  " + str(slot_cost) + " GEMS"
	lab_slot_button.disabled = not state.can_unlock_lab_slot()
	var parts: Array = [state.in_run, state.coins, state.lab_slots_total(), state.lab_active_count()]
	for definition in state.lab_research.definitions:
		parts.append_array([state.get_lab_owned(definition.id), state.lab_is_active(definition.id), state.lab_is_done_awaiting_run_end(definition.id), state.can_start_lab(definition.id)])
	var signature := "|".join(parts)
	if signature == lab_sheet_signature:
		# Only the countdowns move between changes; they tick in place.
		for definition in state.lab_research.definitions:
			var status: Label = lab_status_labels.get(definition.id)
			if status != null and is_instance_valid(status):
				status.text = _lab_status_text(definition, definition.is_maxed(state.get_lab_owned(definition.id)), state.lab_is_active(definition.id))
		return
	lab_sheet_signature = signature
	_clear_children(lab_research_content)
	lab_status_labels.clear()
	for definition in state.lab_research.definitions:
		lab_research_content.add_child(_make_lab_research_card(definition))

func _on_lab_slot_pressed() -> void:
	if state.unlock_lab_slot():
		_show_toast("LAB SLOT " + str(state.lab_slots_total()) + " OPEN", LABS_ACCENT)
		state.save()
		_refresh_all()
		_refresh_lab_research()
	elif state.in_run:
		_show_toast("OPEN SLOTS BETWEEN RUNS", MUTED_TEXT)
	else:
		_show_toast("NEED " + str(state.get_lab_slot_cost()) + " GEMS", MUTED_TEXT)

func _make_lab_research_card(definition: LabResearch.Definition) -> Button:
	var owned := state.get_lab_owned(definition.id)
	var maxed := definition.is_maxed(owned)
	var active := state.lab_is_active(definition.id)
	var button := _make_row_button()
	button.disabled = maxed or active or not state.can_start_lab(definition.id)
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE, 14, Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 14, LABS_ACCENT))
	button.add_theme_stylebox_override("pressed", _panel_style(SURFACE_HOVER, 14, LABS_ACCENT))
	button.add_theme_stylebox_override("disabled", _panel_style(SURFACE, 14, LABS_ACCENT if active else Color.TRANSPARENT))
	var row := _row_layout(button, 14, 10)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(36, 36)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _panel_style(Color(LABS_ACCENT.r, LABS_ACCENT.g, LABS_ACCENT.b, 0.14), 10))
	var chip_center := CenterContainer.new()
	chip_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(chip_center)
	chip_center.add_child(IconGlyph.new(IconGlyph.Kind.FLASK, LABS_ACCENT, 16.0))
	row.add_child(chip)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 4)
	row.add_child(mid)
	mid.add_child(_make_label(definition.title, 14, HORIZONTAL_ALIGNMENT_LEFT, TEXT))
	mid.add_child(_make_label("RANK " + str(owned) + " / " + str(definition.max_rank), 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	var description_label := _make_label(definition.description, 11, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(description_label)
	var right := _make_label(_lab_status_text(definition, maxed, active), 12, HORIZONTAL_ALIGNMENT_RIGHT, LABS_ACCENT if active else (TEXT if not button.disabled else MUTED_TEXT))
	right.custom_minimum_size = Vector2(84, 0)
	row.add_child(right)
	lab_status_labels[definition.id] = right
	button.pressed.connect(func():
		if state.start_lab(definition.id):
			_show_toast(definition.title + " STARTED", LABS_ACCENT)
			state.save()
			_refresh_all()
			_refresh_lab_research()
		else:
			_show_toast("CAN'T START RESEARCH", MUTED_TEXT)
	)
	return button

func _lab_status_text(definition: LabResearch.Definition, maxed: bool, active: bool) -> String:
	if maxed:
		return "MAXED"
	if state.lab_is_done_awaiting_run_end(definition.id):
		return "DONE\nNEXT RUN"
	if active:
		return _format_duration(state.get_lab_time_remaining(definition.id)) + "\nLEFT"
	return _coins(state.get_lab_cost(definition.id)) + " ©\n" + _format_duration(state.get_lab_duration(definition.id))

## Cards (D027): a permanent, Gem-pulled collection with a capped Active set.
## Toned down from the reference: one flat per-level step per card, one
## Active set rather than named loadout presets, no Mastery tie to Labs yet.
func _build_card_collection_sheet() -> void:
	card_collection_sheet = Control.new()
	card_collection_sheet.visible = false
	card_collection_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(card_collection_sheet)

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			card_collection_sheet.visible = false
	)
	card_collection_sheet.add_child(scrim)

	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_top = 150
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = SHEET
	sheet_style.corner_radius_top_left = 24
	sheet_style.corner_radius_top_right = 24
	sheet.add_theme_stylebox_override("panel", sheet_style)
	card_collection_sheet.add_child(sheet)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 24)
	sheet.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_sheet_handle())

	var header_row := HBoxContainer.new()
	column.add_child(header_row)
	var title := _make_label("Cards", 19, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _chip_style(SURFACE))
	var chip_row := HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 6)
	chip.add_child(chip_row)
	chip_row.add_child(IconGlyph.new(IconGlyph.Kind.GEM, GEM_COLOUR, 13.0))
	card_collection_gems_label = _make_number_label("", 12, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	chip_row.add_child(card_collection_gems_label)
	header_row.add_child(chip)
	column.add_child(_make_label("PERMANENT · ACTIVE CARDS APPLY TO EVERY RUN", 10, HORIZONTAL_ALIGNMENT_LEFT, CARDS_ACCENT))

	card_collection_pull_button = Button.new()
	card_collection_pull_button.focus_mode = Control.FOCUS_NONE
	card_collection_pull_button.custom_minimum_size = Vector2(0, 44)
	card_collection_pull_button.add_theme_font_size_override("font_size", 13)
	card_collection_pull_button.add_theme_color_override("font_color", ACCENT_INK)
	card_collection_pull_button.add_theme_color_override("font_hover_color", ACCENT_INK)
	card_collection_pull_button.add_theme_color_override("font_disabled_color", MUTED_TEXT)
	card_collection_pull_button.add_theme_stylebox_override("normal", _panel_style(CARDS_ACCENT, 12))
	card_collection_pull_button.add_theme_stylebox_override("hover", _panel_style(CARDS_ACCENT.lightened(0.1), 12))
	card_collection_pull_button.add_theme_stylebox_override("disabled", _panel_style(SURFACE, 12))
	card_collection_pull_button.pressed.connect(_on_card_pull_pressed)
	column.add_child(card_collection_pull_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 10)
	scroll.add_child(inner)

	card_collection_active_label = _make_label("ACTIVE", 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	inner.add_child(card_collection_active_label)
	card_collection_active_content = VBoxContainer.new()
	card_collection_active_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_collection_active_content.add_theme_constant_override("separation", 8)
	inner.add_child(card_collection_active_content)

	inner.add_child(HSeparator.new())
	inner.add_child(_make_label("INVENTORY", 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	card_collection_inventory_content = VBoxContainer.new()
	card_collection_inventory_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_collection_inventory_content.add_theme_constant_override("separation", 8)
	inner.add_child(card_collection_inventory_content)

func _open_card_collection_sheet() -> void:
	if card_collection_sheet == null:
		return
	if drawer != null and drawer.visible:
		drawer.visible = false
	if knowledge_sheet != null and knowledge_sheet.visible:
		knowledge_sheet.visible = false
	if lab_research_sheet != null and lab_research_sheet.visible:
		lab_research_sheet.visible = false
	if milestones_sheet != null and milestones_sheet.visible:
		milestones_sheet.visible = false
	_seat_sheet(card_collection_sheet)
	card_collection_sheet.visible = true
	_refresh_card_collection()

## Every checkpoint of the selected tier and what it pays (D048). The table and
## the payouts come from the balance profile and the tier record, so the
## sheet only reads them.
func _build_milestones_sheet() -> void:
	milestones_sheet = Control.new()
	milestones_sheet.visible = false
	milestones_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(milestones_sheet)
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			milestones_sheet.visible = false
	)
	milestones_sheet.add_child(scrim)
	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_top = 150
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = SHEET
	sheet_style.corner_radius_top_left = 24
	sheet_style.corner_radius_top_right = 24
	sheet.add_theme_stylebox_override("panel", sheet_style)
	milestones_sheet.add_child(sheet)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 20)
	sheet.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	milestones_title = _make_label("", 19, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	column.add_child(milestones_title)
	column.add_child(_make_label("EACH PAYS ONCE PER TIER, THE FIRST TIME A RUN PASSES IT", 10, HORIZONTAL_ALIGNMENT_LEFT, ACCENT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	milestones_content = VBoxContainer.new()
	milestones_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestones_content.add_theme_constant_override("separation", 6)
	scroll.add_child(milestones_content)

func _open_milestones_sheet() -> void:
	_close_sheets()
	_seat_sheet(milestones_sheet)
	milestones_sheet.visible = true
	_refresh_milestones()
	_refresh_dock()

func _refresh_milestones() -> void:
	var profile: TaxBalanceProfile = state.balance_profile
	var tier_id := state.selected_tier
	var best := state.get_tier_best(tier_id)
	var claimed := {}
	for wave in state.get_tier_record(tier_id).get("milestones_claimed", []):
		claimed[int(wave)] = true
	var signature := str(tier_id) + "|" + str(best) + "|" + str(claimed.size())
	if signature == milestones_signature:
		return
	milestones_signature = signature
	milestones_title.text = "Milestones  ·  Tier " + str(tier_id)
	_clear_children(milestones_content)
	var next_marked := false
	for wave in profile.MILESTONE_WAVES:
		var done := claimed.has(int(wave))
		var is_next := not done and not next_marked
		next_marked = next_marked or is_next
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _panel_style(SURFACE, 12, ACCENT if is_next else Color.TRANSPARENT))
		row.modulate.a = 1.0 if done or is_next else 0.6
		milestones_content.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		row.add_child(line)
		var status := CenterContainer.new()
		status.custom_minimum_size = Vector2(18, 0)
		status.add_child(IconGlyph.new(IconGlyph.Kind.CHECK if done else IconGlyph.Kind.LOCK, ACCENT if done else MUTED_TEXT, 14.0))
		line.add_child(status)
		var name_label := _make_label("WAVE " + str(wave) + ("  ·  NEXT" if is_next else ""), 14, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		var reward := "+" + str(profile.milestone_gems(tier_id, wave)) + " GEMS"
		var coins := profile.milestone_bonus(tier_id, wave)
		if coins > 0:
			reward += "  ·  +" + _coins(coins) + " COINS"
		line.add_child(_make_label(reward, 11, HORIZONTAL_ALIGNMENT_RIGHT, ACCENT if done else MUTED_TEXT))

func _on_card_pull_pressed() -> void:
	if not state.has_unmaxed_cards():
		_show_toast("ALL CARDS ARE AT MAX LEVEL", CARDS_ACCENT)
		return
	var drawn := state.pull_card()
	if drawn == "":
		_show_toast("NEED " + str(state.get_pull_cost()) + " GEMS", MUTED_TEXT)
		return
	var definition := state.card_collection.get_definition(drawn)
	_show_toast((definition.title if definition != null else "CARD") + " · LEVEL " + str(state.get_card_level(drawn)), CARDS_ACCENT)
	state.save()
	_refresh_all()
	_refresh_card_collection()

func _refresh_card_collection() -> void:
	if card_collection_sheet == null or not card_collection_sheet.visible:
		return
	card_collection_gems_label.text = str(state.gems)
	if not state.has_unmaxed_cards():
		card_collection_pull_button.text = "ALL CARDS MAXED"
		card_collection_pull_button.disabled = true
	else:
		card_collection_pull_button.text = "PULL A CARD  ·  " + str(state.get_pull_cost()) + " GEMS"
		card_collection_pull_button.disabled = not state.can_pull_card()
	card_collection_active_label.text = "ACTIVE  " + str(state.active_card_count()) + " / " + str(state.card_slots_total())
	var signature := "|".join([state.in_run, str(state.card_ranks), str(state.card_active)])
	if signature == card_sheet_signature:
		return
	card_sheet_signature = signature
	_clear_children(card_collection_active_content)
	_clear_children(card_collection_inventory_content)
	var any_active := false
	for definition in state.card_collection.definitions:
		if state.is_card_active(definition.id):
			any_active = true
			card_collection_active_content.add_child(_make_card_tile(definition, true))
	if not any_active:
		card_collection_active_content.add_child(_make_label("No cards equipped yet.", 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	for definition in state.card_collection.definitions:
		card_collection_inventory_content.add_child(_make_card_tile(definition, false))

## One row: the card's rarity-tinted chip, its title and level, and the tap
## action — unequip in Active, equip in Inventory (an equipped card does not
## repeat in Inventory's own tap target, but still shows so its level reads).
func _make_card_tile(definition: CardCollection.Definition, in_active_section: bool) -> Button:
	var owned := state.get_card_level(definition.id)
	var locked := owned <= 0
	var active := state.is_card_active(definition.id)
	var tint: Color = CRITICAL if definition.rarity == CardCollection.RARE else CARDS_ACCENT
	var button := _make_row_button()
	button.custom_minimum_size = Vector2(0, 72)
	var can_act := (not in_active_section and state.can_equip_card(definition.id)) or (in_active_section and not state.in_run and active)
	button.disabled = locked or not can_act
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE, 14, Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 14, tint))
	button.add_theme_stylebox_override("pressed", _panel_style(SURFACE_HOVER, 14, tint))
	var row := _row_layout(button, 14, 8)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(32, 32)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _panel_style(Color(tint.r, tint.g, tint.b, 0.14 if not locked else 0.06), 9))
	var chip_center := CenterContainer.new()
	chip_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(chip_center)
	chip_center.add_child(IconGlyph.new(IconGlyph.Kind.DICE, tint if not locked else MUTED_TEXT, 15.0))
	row.add_child(chip)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	row.add_child(mid)
	mid.add_child(_make_label(definition.title, 13, HORIZONTAL_ALIGNMENT_LEFT, TEXT if not locked else MUTED_TEXT))
	var level_text := "NOT OWNED" if locked else ("LEVEL " + str(owned) + " / " + str(CardCollection.MAX_LEVEL))
	mid.add_child(_make_label(level_text, 10, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	var status := "ACTIVE" if active else ("EQUIP" if not locked else "")
	row.add_child(_make_label("UNEQUIP" if (in_active_section and active) else status, 11, HORIZONTAL_ALIGNMENT_RIGHT, tint if not button.disabled else MUTED_TEXT))
	button.pressed.connect(func():
		if in_active_section:
			state.unequip_card(definition.id)
		else:
			if not state.equip_card(definition.id):
				_show_toast("ACTIVE IS FULL", MUTED_TEXT)
				return
		state.save()
		_refresh_all()
		_refresh_card_collection()
	)
	return button

## Toasts sit just above the screen's main controls (D049): over the
## Upgrades sheet in a run, over BATTLE on the hub, over the bar elsewhere, so
## they never land on the ring or the Number.
func _build_toast() -> void:
	toast_wrap = Control.new()
	toast_wrap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
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
	sheet_style.bg_color = SHEET
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

	drawer_content.add_child(_make_sheet_handle())

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
	knowledge_route.add_theme_stylebox_override("normal", _panel_style(SURFACE, 14))
	knowledge_route.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 14, CARDS_ACCENT))
	var route_row := _row_layout(knowledge_route, 14, 10)
	route_row.add_child(IconGlyph.new(IconGlyph.Kind.BOOK, MUTED_TEXT, 16.0))
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

	# Not flat: a flat button skips its stylebox, which left the detail panel
	# floating over an undimmed screen.
	var scrim := Button.new()
	scrim.text = ""
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
	panel.add_theme_stylebox_override("panel", _panel_style(SHEET, 20))
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
	stat_info_extra = _make_label("", 12, HORIZONTAL_ALIGNMENT_CENTER, WORKSHOP_ACCENT)
	stat_info_extra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(stat_info_extra)

## A card's detail: what it does, how many of its ranks are owned against its
## maximum, its value now and at the cap, and what it waits on. From the Rig,
## also the run's own ranks and what each is worth.
func _show_stat_info(definition: UpgradeDefinition, from_rig: bool = false) -> void:
	if stat_info_screen == null:
		return
	var owned := state.get_owned(definition.id)
	stat_info_title.text = definition.title
	stat_info_body.text = definition.description
	stat_info_level.text = "RANK " + str(owned) + " / " + str(definition.max_rank) + "  ·  NOW " + _stat_value_text(definition, owned)
	if definition.is_maxed(owned):
		stat_info_max.text = "MAX RANK REACHED"
	else:
		stat_info_max.text = "AT MAX RANK  ·  " + _stat_value_text(definition, definition.max_rank)
	var extra: Array[String] = []
	if not state.is_unlocked(definition):
		extra.append("OPENS AT WORKSHOP LV " + str(definition.workshop_level_required) + "  ·  YOU ARE LV " + str(state.get_workshop_level()))
	if from_rig:
		var rig_ranks := state.rig_owned(definition.id)
		var worth := state.balance_profile.rig_effect_multiplier(definition.workshop_category, definition.id)
		var next := ("NEXT " + state.get_rig_cost(definition.id).format_value() + " CASH") if state.rig_room(definition.id) > 0 else "AT MAX RANK"
		extra.append("THIS RUN  ·  " + str(rig_ranks) + " RUN RANK" + ("" if rig_ranks == 1 else "S") + ", EACH WORTH " + _trim(worth) + " WORKSHOP RANKS  ·  " + next)
	stat_info_extra.text = "\n".join(extra)
	stat_info_extra.visible = not extra.is_empty()
	stat_info_screen.visible = true

## The run-over report (D049): a sheet from the foot of the screen over a
## dimmed stage, modal (no scrim-tap-to-dismiss) since a death should be
## acknowledged, not brushed past. It names the wave and its hit, how far
## Attack and Defense fell short, what the run earned, and the ways on.
func _build_died_screen() -> void:
	died_screen = Control.new()
	died_screen.visible = false
	died_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(died_screen)

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	died_screen.add_child(scrim)

	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = SHEET
	sheet_style.corner_radius_top_left = 24
	sheet_style.corner_radius_top_right = 24
	sheet_style.content_margin_left = 20
	sheet_style.content_margin_right = 20
	sheet_style.content_margin_top = 10
	sheet_style.content_margin_bottom = 28
	sheet.add_theme_stylebox_override("panel", sheet_style)
	died_screen.add_child(sheet)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 0)
	sheet.add_child(inner)
	inner.add_child(_make_sheet_handle())
	inner.add_child(_make_gap(22))
	died_title_label = _make_tracked_label("", 11, WARNING)
	died_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	inner.add_child(died_title_label)
	inner.add_child(_make_gap(6))
	var wave_row := HBoxContainer.new()
	wave_row.add_theme_constant_override("separation", 8)
	inner.add_child(wave_row)
	died_wave_label = _make_label("", 28, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	died_wave_label.add_theme_font_override("font", ui_font_medium)
	wave_row.add_child(died_wave_label)
	inner.add_child(_make_gap(6))
	died_cause_label = _make_label("", 14, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	died_cause_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(died_cause_label)

	# The two gaps (D022, step 6): how far short Attack fell against the wave's
	# HP and Defense against its hit.
	var gaps := VBoxContainer.new()
	gaps.add_theme_constant_override("separation", 0)
	died_gap_rows = gaps
	inner.add_child(gaps)
	gaps.add_child(_make_gap(20))
	var top_line := ColorRect.new()
	top_line.color = LINE
	top_line.custom_minimum_size = Vector2(0, 1)
	gaps.add_child(top_line)
	died_attack_gap_label = _make_gap_row(gaps, IconGlyph.Kind.BOLT, "Attack", "HP short")
	died_defense_gap_label = _make_gap_row(gaps, IconGlyph.Kind.SHIELD, "Defense", "short of the hit")

	inner.add_child(_make_gap(20))
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 8)
	inner.add_child(rewards)
	died_coins_label = _make_reward_tile(rewards, IconGlyph.Kind.GOLD_COIN, COIN_COLOUR, "Coins earned")
	died_knowledge_label = _make_reward_tile(rewards, IconGlyph.Kind.BOOK, MUTED_TEXT, "Knowledge")
	died_knowledge_tile = died_knowledge_label.get_meta("tile")
	died_gems_label = _make_reward_tile(rewards, IconGlyph.Kind.GEM, GEM_COLOUR, "Gems")
	died_gems_tile = died_gems_label.get_meta("tile")

	inner.add_child(_make_gap(14))
	var footnote := HBoxContainer.new()
	inner.add_child(footnote)
	died_peak_label = _make_number_label("", 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	died_peak_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footnote.add_child(died_peak_label)
	footnote.add_child(_make_label("Workshop kept", 12, HORIZONTAL_ALIGNMENT_RIGHT, MUTED_TEXT))

	# Both doors, at the moment the currency lands (D016).
	inner.add_child(_make_gap(22))
	var doors := HBoxContainer.new()
	doors.add_theme_constant_override("separation", 8)
	inner.add_child(doors)
	doors.add_child(_make_door("Workshop", TEXT, func():
		_dismiss_died_screen()
		_on_dock_tab_selected("workshop")
	))
	died_knowledge_door = _make_door("Spend Knowledge", TEXT, func():
		_dismiss_died_screen()
		_open_knowledge_sheet()
	)
	doors.add_child(died_knowledge_door)

	inner.add_child(_make_gap(10))
	var continue_button := _make_primary_button("CONTINUE")
	continue_button.pressed.connect(_dismiss_died_screen)
	inner.add_child(continue_button)

## One shortfall line on the run-over sheet: its category, how far short, and
## of what. Returns the amount's label.
func _make_gap_row(parent: Control, icon_kind: int, category: String, unit: String) -> Label:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 48)
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var icon_wrap := CenterContainer.new()
	icon_wrap.add_child(IconGlyph.new(icon_kind, MUTED_TEXT, 16.0))
	row.add_child(icon_wrap)
	var name_label := _make_label(category, 14, HORIZONTAL_ALIGNMENT_LEFT, TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_vertical = Control.SIZE_FILL
	row.add_child(name_label)
	var amount := _make_number_label("", 14, HORIZONTAL_ALIGNMENT_RIGHT, TEXT)
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.size_flags_vertical = Control.SIZE_FILL
	row.add_child(amount)
	var unit_label := _make_label(unit, 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT)
	unit_label.custom_minimum_size = Vector2(108, 0)
	unit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	unit_label.size_flags_vertical = Control.SIZE_FILL
	row.add_child(unit_label)
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size = Vector2(0, 1)
	parent.add_child(line)
	return amount

## A reward tile on the run-over sheet: the currency's icon and name over the
## amount earned. Returns the amount's label, with its tile in meta "tile".
func _make_reward_tile(parent: Control, icon_kind: int, icon_colour: Color, caption: String) -> Label:
	var tile := PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := _panel_style(SURFACE_RAISED, 12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	tile.add_theme_stylebox_override("panel", style)
	parent.add_child(tile)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	tile.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	column.add_child(heading)
	var icon_wrap := CenterContainer.new()
	icon_wrap.add_child(IconGlyph.new(icon_kind, icon_colour, 12.0))
	heading.add_child(icon_wrap)
	heading.add_child(_make_label(caption, 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
	var amount := _make_number_label("", 26, HORIZONTAL_ALIGNMENT_LEFT, ACCENT)
	column.add_child(amount)
	amount.set_meta("tile", tile)
	return amount

## The one filled button a screen has: its main way on.
func _make_primary_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 56)
	button.add_theme_font_override("font", _tracked_font())
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", ACCENT_INK)
	button.add_theme_color_override("font_hover_color", ACCENT_INK)
	button.add_theme_color_override("font_pressed_color", ACCENT_INK)
	button.add_theme_stylebox_override("normal", _panel_style(ACCENT, 999))
	button.add_theme_stylebox_override("hover", _panel_style(ACCENT.lightened(0.1), 999))
	button.add_theme_stylebox_override("pressed", _panel_style(ACCENT.darkened(0.08), 999))
	return button

## An outlined pill for a secondary way on.
func _make_door(text: String, tint: Color, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", tint)
	button.add_theme_color_override("font_hover_color", tint)
	button.add_theme_color_override("font_pressed_color", tint)
	button.add_theme_stylebox_override("normal", _panel_style(Color.TRANSPARENT, 999, Color("2a2b2e")))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE, 999, Color("2a2b2e")))
	button.add_theme_stylebox_override("pressed", _panel_style(SURFACE_HOVER, 999, Color("2a2b2e")))
	button.pressed.connect(on_press)
	return button

func _show_died_screen(summary: RunSummary) -> void:
	if summary == null or died_screen == null:
		return
	died_title_label.text = "RUN OVER  ·  TIER " + str(summary.tier_id)
	died_wave_label.text = ("Boss wave " if summary.lost_to_boss else "Wave ") + str(summary.wave_reached)
	died_cause_label.text = "Its hit took " + summary.final_hit.format_value() + " and you had less."
	# The smaller gap is the closer fix, so it carries the accent: the sheet
	# points at the category to open next without saying so in words. A tie
	# leaves both plain.
	var lost_to_a_hit := not summary.final_hit.is_zero()
	died_gap_rows.visible = lost_to_a_hit
	if lost_to_a_hit:
		var smaller_gap := summary.attack_gap.compare_to(summary.defense_gap)
		died_attack_gap_label.text = summary.attack_gap.format_value()
		died_defense_gap_label.text = summary.defense_gap.format_value()
		died_attack_gap_label.add_theme_color_override("font_color", ACCENT if smaller_gap < 0 else TEXT)
		died_defense_gap_label.add_theme_color_override("font_color", ACCENT if smaller_gap > 0 else TEXT)
	died_knowledge_door.visible = summary.knowledge_gained > 0 or state.knowledge > 0
	_count_total(died_coins_label, summary.coins_earned, func(value: int): return "+" + _coins(value))
	died_knowledge_tile.visible = summary.knowledge_gained > 0
	if summary.knowledge_gained > 0:
		_count_total(died_knowledge_label, summary.knowledge_gained, func(value: int): return "+" + str(value), 0.7)
	died_gems_tile.visible = summary.gems_earned > 0
	if summary.gems_earned > 0:
		_count_total(died_gems_label, summary.gems_earned, func(value: int): return "+" + str(value), 0.7)
	died_peak_label.text = "Peak Number " + summary.peak_number.format_value()
	died_screen.visible = true

func _dismiss_died_screen() -> void:
	died_screen.visible = false
	_refresh_all()

func _select_tab(tab_id: String) -> void:
	if not _is_tab_unlocked(tab_id):
		return
	current_tab = tab_id
	_apply_screen_layout()
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
	if NavDock.SOON_TABS.has(tab_id):
		_show_toast("ULTIMATE WEAPONS  ·  COMING LATER", MUTED_TEXT)
		return
	if not _is_tab_unlocked(tab_id):
		_show_toast("REACH " + ScientificNumber.from_float(tab_unlock_lifetime[tab_id]).format_value() + " TO UNLOCK " + TAB_NAMES[tab_id], MUTED_TEXT)
		return
	# Labs, Cards and MORE are sheets over whichever screen is showing (D048):
	# their seat opens them, and pressing it again closes them.
	if tab_id == "settings":
		_toggle_drawer()
		return
	if tab_id == "labs" or tab_id == "cards":
		var sheet: Control = lab_research_sheet if tab_id == "labs" else card_collection_sheet
		if sheet.visible:
			sheet.visible = false
		elif tab_id == "labs":
			_open_lab_research_sheet()
		else:
			_open_card_collection_sheet()
		_refresh_dock()
		return
	_close_sheets()
	_select_tab(tab_id)

func _close_sheets() -> void:
	for sheet in [drawer, knowledge_sheet, lab_research_sheet, card_collection_sheet, milestones_sheet]:
		if sheet != null:
			sheet.visible = false

## Sheets stop at the dock's top edge whenever the dock shows, so the bar
## stays pressable and marks the open sheet (D048); a run screen has no dock,
## so there a sheet runs to the foot of the screen.
func _seat_sheet(sheet: Control) -> void:
	sheet.offset_bottom = -NavDock.BAR_HEIGHT if nav_dock.visible else 0.0

func _is_tab_unlocked(tab_id: String) -> bool:
	var threshold: float = tab_unlock_lifetime.get(tab_id, 0.0)
	return state.highest_number.compare_to(ScientificNumber.from_float(threshold)) >= 0

func _refresh_dock() -> void:
	var unlocked := {}
	var active := current_tab
	if drawer.visible:
		active = "settings"
	elif lab_research_sheet.visible:
		active = "labs"
	elif card_collection_sheet.visible:
		active = "cards"
	var signature := active
	for tab_id in NavDock.TAB_ORDER:
		unlocked[tab_id] = _is_tab_unlocked(tab_id)
		signature += "|" + ("1" if unlocked[tab_id] else "0")
	# Dock restyling is only worth doing when the active tab or an unlock
	# boundary actually changed; _refresh_all runs eight times a second.
	if signature == dock_signature:
		return
	dock_signature = signature
	nav_dock.update_state(active, unlocked)

## Every point of output is Number (D037), so the floating text always reads
## as a gain; the ring pulse is what shows the same output striking a wave.
func _output_float_text(amount: ScientificNumber, critical: bool) -> String:
	return ("CRITICAL " if critical else "") + "+" + amount.format_value()

func _tap_number() -> void:
	if not state.in_run:
		_show_toast("START A RUN TO PRODUCE NUMBER", MUTED_TEXT)
		return
	var hp_encounter: Variant = state.active_encounter if state.is_wave_standing() else null
	var hp_before: ScientificNumber = hp_encounter.remaining_liability.copy() if hp_encounter != null else null
	var event := state.tap()
	var spawn_pos := floating_text_layer.get_local_mouse_position()
	if not Rect2(Vector2.ZERO, floating_text_layer.size).has_point(spawn_pos):
		spawn_pos = _stage_float_point()
	if event.is_critical:
		_spawn_floating_text(_output_float_text(event.amount, true), CRITICAL, spawn_pos)
		_pulse_number(1.09)
		_flash_number(CRITICAL)
	else:
		_spawn_floating_text(_output_float_text(event.amount, false), ACCENT, spawn_pos)
		_pulse_number(1.035)
	# A tap that still has a wave to chew through sends it a mote at once, so the
	# player sees the wave take the hit, not only their own Number rise.
	if hp_encounter != null and state.active_encounter == hp_encounter and state.is_wave_standing():
		_fire_mote(hp_before.subtract(hp_encounter.remaining_liability), event.is_critical)
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
	passive_float_accumulator = ScientificNumber.new()
	passive_float_elapsed = 0.0
	_snap_number_display()
	state.save()
	_refresh_all()

func _on_brace_pressed() -> void:
	var cost := state.number.multiply_scalar(state.get_brace_cost_percent())
	if state.brace():
		_show_toast("BRACED · -" + _stat_number(cost) + " NUMBER", ACCENT)
		_snap_number_display()
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

func _refresh_all() -> void:
	background_rect.visible = not bool(state.settings.high_contrast)
	rate_label.visible = true
	var rate := _stat_number(state.get_rate_per_second())
	rate_label.text = ("+" if state.in_run else "STARTING +") + rate + " / sec"
	tap_hint.text = "TAP TO PRODUCE" if state.in_run else "START A RUN TO PRODUCE"
	coins_label.text = _coins(state.coins)
	knowledge_label.text = str(state.knowledge)
	gems_label.text = str(state.gems)
	_refresh_run_bar()
	_refresh_rig()
	if offline_message != "":
		_show_toast(offline_message, ACCENT)
		offline_message = ""
	_refresh_dock()
	_refresh_knowledge()
	_refresh_lab_research()
	_refresh_card_collection()
	if milestones_sheet.visible:
		_refresh_milestones()
	if current_tab == "workshop":
		# Do not rebuild live buttons during the player's press/release cycle.
		# Rebuilding a Control tree every refresh can eat touch releases on Web.
		workshop_header.text = _coins(state.coins)

## The run screen has two layouts (D032, D049). During a run the currencies
## and Retreat share the top line, the wave line sits under them, then the
## stage and the row with the ring's key and Brace. The Upgrades sheet rests on
## the category strip at the foot, with no dock (D016); the height between the
## Brace row and the sheet is left empty on purpose, for systems that will want
## the upper half. The dock still shows on other tabs mid-run, so the Workshop
## always has a way back. Between runs the hub (D048) takes the screen: a
## width-capped column, with BATTLE pinned above the dock.
func _apply_screen_layout() -> void:
	var screen: Control = screens.get("number")
	if screen == null or stage_root == null:
		return
	var height := screen.size.y
	var width := screen.size.x
	var key := ("run" if state.in_run else "between") + "|" + current_tab + "|" + str(int(height)) + "x" + str(int(width))
	if key == screen_layout_key or height <= 0.0:
		return
	screen_layout_key = key
	nav_dock.visible = not (state.in_run and current_tab == "number")
	currency_stack.visible = state.in_run
	wave_line.visible = state.in_run
	brace_button.visible = state.in_run
	number_button.visible = state.in_run
	if state.in_run:
		var sheet_height := clampf(height * RUN_SHEET_SHARE, RUN_SHEET_MIN, RUN_SHEET_MAX)
		var sheet_top := height - CATEGORY_STRIP_HEIGHT - sheet_height
		# The arena is everything between the wave line and the sheet (D051).
		var arena_height := maxf(sheet_top - RUN_STAGE_TOP, 0.0)
		_place(stage_root, 0.0, RUN_STAGE_TOP, 0.0, sheet_top)
		var brace_size := brace_button.get_combined_minimum_size()
		brace_button.position = Vector2(16.0, sheet_top - 14.0 - brace_size.y)
		brace_button.size = brace_size
		# Low in the arena, near the thumb, but never down onto Brace.
		var number_height := number_col.get_combined_minimum_size().y
		var number_centre := minf(arena_height * NUMBER_HEIGHT_SHARE, arena_height - 14.0 - brace_size.y - number_height / 2.0 - 8.0)
		number_centre = maxf(number_centre, number_height / 2.0)
		number_frame.offset_top = number_centre - number_height / 2.0
		number_frame.offset_bottom = number_centre + number_height / 2.0
		stage_glow.offset_top = number_centre - 150.0
		stage_glow.offset_bottom = number_centre + 150.0
		_place(rig_panel, 1.0, -(sheet_height + CATEGORY_STRIP_HEIGHT), 1.0, 0.0)
		run_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		run_button.offset_left = -130
		run_button.offset_right = -12
		run_button.offset_top = 8
		run_button.offset_bottom = 52
		run_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		var half := minf(width - 40.0, HUB_MAX_WIDTH) * 0.5
		var battle_bottom := -NavDock.BAR_HEIGHT - 12.0
		var battle_top := battle_bottom - HUB_BATTLE_HEIGHT
		hub_panel.anchor_left = 0.5
		hub_panel.anchor_right = 0.5
		hub_panel.anchor_top = 0.0
		hub_panel.anchor_bottom = 1.0
		hub_panel.offset_left = -half
		hub_panel.offset_right = half
		hub_panel.offset_top = 8.0
		hub_panel.offset_bottom = battle_top - 6.0
		hub_column.custom_minimum_size.y = height + battle_top - 6.0 - 8.0
		run_button.anchor_left = 0.5
		run_button.anchor_right = 0.5
		run_button.anchor_top = 1.0
		run_button.anchor_bottom = 1.0
		run_button.offset_left = -half
		run_button.offset_right = half
		run_button.offset_top = battle_top
		run_button.offset_bottom = battle_bottom
		run_button.alignment = HORIZONTAL_ALIGNMENT_CENTER

## Stretches a control across the screen's width between two edges, each an
## anchor (0 top, 1 bottom) plus a pixel offset from it.
func _place(control: Control, top_anchor: float, top: float, bottom_anchor: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_right = 1.0
	control.offset_left = 0.0
	control.offset_right = 0.0
	control.anchor_top = top_anchor
	control.anchor_bottom = bottom_anchor
	control.offset_top = top
	control.offset_bottom = bottom

## Where floating numbers rise from: the Number itself, wherever the stage is.
func _stage_float_point() -> Vector2:
	if stage_root == null or not stage_root.visible:
		return floating_text_layer.size * Vector2(0.5, 0.42)
	return number_label.get_global_rect().get_center() - floating_text_layer.global_position - Vector2(0.0, 24.0)

## Shows the two independent checks the run turns on: the remaining Liability
## production must clear, and the Collection hit Number must survive.
func _refresh_run_bar() -> void:
	_apply_screen_layout()
	wave_label.text = "WAVE " + str(state.wave) if state.in_run else "NOT RUNNING"
	tier_button.text = "TIER " + str(state.selected_tier)
	tier_button.disabled = state.in_run
	_refresh_boss_notice()
	if rig_panel != null:
		rig_panel.visible = state.in_run
	if stage_root != null:
		stage_root.visible = state.in_run
	_refresh_hub()
	tap_hint.visible = state.in_run
	brace_cost_label.text = "−" + _stat_number(state.number.multiply_scalar(state.get_brace_cost_percent()))
	brace_button.disabled = not state.can_brace()
	_set_action_enabled(brace_button, not brace_button.disabled)
	run_button.text = "RETREAT" if state.in_run else "BATTLE"
	run_button.tooltip_text = "End this run. Number and run Upgrades reset; the Workshop is kept." if state.in_run else ""
	run_button.add_theme_font_size_override("font_size", 11 if state.in_run else 15)
	# Retreat is destructive and rare, so it stays the quietest control on the
	# screen (flat text). Starting is the whole point of being here, so it
	# gets the filled pill the run-over sheet's CONTINUE uses (D025).
	run_button.flat = state.in_run
	var run_colour := FAINT_TEXT if state.in_run else ACCENT_INK
	run_button.add_theme_color_override("font_color", run_colour)
	run_button.add_theme_color_override("font_hover_color", MUTED_TEXT if state.in_run else ACCENT_INK)
	run_button.add_theme_color_override("font_pressed_color", MUTED_TEXT if state.in_run else ACCENT_INK)
	run_button.add_theme_font_override("font", _tracked_font())
	if state.in_run:
		run_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		run_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		run_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	else:
		run_button.add_theme_stylebox_override("normal", _panel_style(ACCENT, 999))
		run_button.add_theme_stylebox_override("hover", _panel_style(ACCENT.lightened(0.1), 999))
		run_button.add_theme_stylebox_override("pressed", _panel_style(ACCENT.darkened(0.08), 999))

## The hub's facts (D048, D049), including the D025 landing beat: what the
## last run did, and what the next one will be.
func _refresh_hub() -> void:
	if hub_panel == null:
		return
	hub_panel.visible = not state.in_run
	if state.in_run:
		return
	hub_coins_label.text = _coins(state.coins)
	hub_gems_label.text = str(state.gems)
	hub_knowledge_label.text = str(state.knowledge)
	var summary := state.last_run_summary
	var reward_visible := summary != null and summary.coins_earned > 0
	hub_last_run_reward.visible = reward_visible
	hub_last_run_coin.visible = reward_visible
	hub_last_run_hit.text = ""
	hub_last_run_extra.text = ""
	if summary == null:
		hub_last_run_label.text = ""
		hub_last_run_cause.text = "No runs yet. Press Battle when you're ready."
	else:
		hub_last_run_label.text = "Tier " + str(summary.tier_id) + " · wave " + str(summary.wave_reached)
		match summary.outcome:
			"retreat": hub_last_run_cause.text = "Retreated"
			"prestige": hub_last_run_cause.text = "Prestiged"
			_:
				hub_last_run_cause.text = "Lost to a hit of"
				hub_last_run_hit.text = summary.final_hit.format_value()
		hub_last_run_reward.text = "+" + _coins(summary.coins_earned)
		var extra: Array[String] = []
		if summary.knowledge_gained > 0:
			extra.append("+" + str(summary.knowledge_gained) + " Knowledge")
		if summary.gems_earned > 0:
			extra.append("+" + str(summary.gems_earned) + " Gems")
		hub_last_run_extra.text = "  ·  ".join(extra)
	hub_last_run_extra.visible = hub_last_run_extra.text != ""
	hub_coin_bonus_label.text = "×" + ("%.2f" % state.get_coin_bonus_multiplier())
	hub_knowledge_row_label.text = str(state.knowledge) + " to spend" if state.knowledge > 0 else "0"
	var tier: Variant = state.balance_profile.get_tier(state.selected_tier)
	hub_tier_label.text = "TIER " + str(state.selected_tier)
	hub_reward_label.text = "rewards ×" + ("%.1f" % tier.reward_multiplier)
	var index := _selected_tier_index()
	var tiers: Array = state.balance_profile.tiers
	hub_prev_tier.disabled = index <= 0
	hub_next_tier.disabled = index >= tiers.size() - 1
	for arrow in [hub_prev_tier, hub_next_tier]:
		(arrow.get_meta("chevron") as IconGlyph).set_glyph_color(Color("3a3b3e") if arrow.disabled else TEXT)
	_refresh_hub_ring(index)

## The hub ring's goal is the next tier's gate while it is shut, else the next
## milestone; its dots are the tier's milestones up to that goal (D049). The
## ring only reads the tier record and the balance profile.
func _refresh_hub_ring(tier_index: int) -> void:
	var profile: TaxBalanceProfile = state.balance_profile
	var tiers: Array = profile.tiers
	var tier_id := state.selected_tier
	var best := state.get_tier_best(tier_id)
	var claimed := {}
	for wave in state.get_tier_record(tier_id).get("milestones_claimed", []):
		claimed[int(wave)] = true
	var goal := 0
	if tier_index + 1 < tiers.size() and not state.is_tier_unlocked(tiers[tier_index + 1].id):
		goal = int(tiers[tier_index + 1].unlock_previous_tier_wave)
		hub_ring_caption.text = "of " + str(goal) + " for Tier " + str(tiers[tier_index + 1].id)
	else:
		for wave in profile.MILESTONE_WAVES:
			if int(wave) > best:
				goal = int(wave)
				break
		hub_ring_caption.text = ("next milestone " + str(goal)) if goal > 0 else "every milestone passed"
	if goal <= 0:
		goal = maxi(best, 1)
	hub_best_wave_label.text = str(best)
	hub_ring.set_arc(float(best) / float(goal), ACCENT)
	var markers: Array = []
	var next_marked := false
	var shown_claimed := 0
	for wave in profile.MILESTONE_WAVES:
		if int(wave) > goal:
			break
		var marker_state := RingArc.Marker.AHEAD
		if claimed.has(int(wave)):
			marker_state = RingArc.Marker.CLAIMED
			shown_claimed += 1
		elif not next_marked:
			marker_state = RingArc.Marker.NEXT
			next_marked = true
		markers.append({"at": float(wave) / float(goal), "state": marker_state})
	hub_ring.set_markers(markers)
	hub_milestones_label.text = str(shown_claimed) + " / " + str(markers.size())

func _selected_tier_index() -> int:
	var tiers: Array = state.balance_profile.tiers
	for index in range(tiers.size()):
		if tiers[index].id == state.selected_tier:
			return index
	return 0

## The hub's arrows step one tier either way; a locked tier says what opens it
## rather than skipping past it, so the next goal is always on screen.
func _step_tier(direction: int) -> void:
	var tiers: Array = state.balance_profile.tiers
	var target := _selected_tier_index() + direction
	if target < 0 or target >= tiers.size():
		return
	var candidate: int = tiers[target].id
	if state.select_tier(candidate):
		state.save()
		_refresh_all()
		if milestones_sheet != null and milestones_sheet.visible:
			_refresh_milestones()
	else:
		_show_toast("TIER " + str(candidate) + " OPENS AT WAVE " + str(tiers[target].unlock_previous_tier_wave) + " IN TIER " + str(tiers[target - 1].id), MUTED_TEXT)

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
	# A boss on the field is red (D051); one still waves away stays a warning.
	boss_label.add_theme_color_override("font_color", BOSS_COLOUR if text == "BOSS WAVE" else WARNING)
	boss_label.visible = text != ""
	boss_separator.visible = text != ""

## Boss waves land every tenth wave; the profile owns that rule, this only
## reads it so the HUD can warn a few waves out.
func _waves_until_boss(current_wave: int) -> int:
	for ahead in range(1, 4):
		if state.balance_profile.is_boss_wave(current_wave + ahead):
			return ahead
	return 0

func _set_action_enabled(button: Button, enabled: bool) -> void:
	var verb: Label = button.get_meta("verb_label")
	verb.add_theme_color_override("font_color", TEXT if enabled else FAINT_TEXT)
	button.modulate.a = 1.0 if enabled else 0.55

func _refresh_workshop() -> void:
	var category: String = state.workshop.selected_category
	if not ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(category):
		category = ProgressionTaxonomy.ATTACK
		state.workshop.selected_category = category
	workshop_header.text = _coins(state.coins)
	workshop_purpose.text = ProgressionTaxonomy.category_purpose(category)
	workshop_multiplier_label.text = _buy_step_label(category)
	# Every segment opens, including one with nothing in it yet: its panel is
	# where the player reads what is coming and when.
	for tab_category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
		var active: bool = category == tab_category
		var has_rows := state.has_category_content(tab_category)
		var button: Button = workshop_tab_buttons[tab_category]
		var colour: Color = TEXT if active else (MUTED_TEXT if has_rows else Color("3a3b3e"))
		button.add_theme_color_override("font_color", colour)
		button.add_theme_color_override("font_hover_color", TEXT)
		button.add_theme_color_override("font_pressed_color", TEXT)
		button.add_theme_font_override("font", ui_font_medium if active else ui_font)
		button.add_theme_stylebox_override("normal", _panel_style(Color("26272a"), 19) if active else StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", _panel_style(Color("26272a"), 19) if active else StyleBoxEmpty.new())
	_refresh_workshop_detail(category)

## The open category as a list (D049): one row per open upgrade, and the rows
## still shut folded into a line per Workshop level that opens them.
func _refresh_workshop_detail(category: String) -> void:
	_clear_children(workshop_detail)
	if state.in_run:
		workshop_detail.add_child(_make_locked_panel("AVAILABLE BETWEEN RUNS", "Current ranks are active now and will be retained when this run ends."))
		workshop_detail.add_child(_make_gap(8))
	if not state.has_category_content(category):
		workshop_detail.add_child(_make_locked_panel("NOTHING HERE YET", "Ultimates unlock at waves 10, 25, 50 and 100."))
		return
	var locked_by_level := {}
	for definition in state.cards_for_category(category):
		if state.is_unlocked(definition):
			workshop_detail.add_child(_make_stat_card(definition, category))
		else:
			var level := definition.workshop_level_required
			if not locked_by_level.has(level):
				locked_by_level[level] = []
			locked_by_level[level].append(definition.title.capitalize())
	if not locked_by_level.is_empty():
		workshop_detail.add_child(_make_gap(16))
		workshop_detail.add_child(_make_locked_rows_panel(locked_by_level))

## What is still shut in this category and the Workshop level that opens it.
func _make_locked_rows_panel(locked_by_level: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _panel_style(Color.TRANSPARENT, 12, LINE)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var lines := VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.add_theme_constant_override("separation", 3)
	row.add_child(lines)
	var levels: Array = locked_by_level.keys()
	levels.sort()
	for i in range(levels.size()):
		var names: Array = locked_by_level[levels[i]]
		if i == 0:
			lines.add_child(_make_label(str(names.size()) + " more at Workshop level " + str(levels[i]), 13, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT))
			var first := _make_label(", ".join(names), 12, HORIZONTAL_ALIGNMENT_LEFT, FAINT_TEXT)
			first.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lines.add_child(first)
		else:
			var later := _make_label(", ".join(names) + " at level " + str(levels[i]), 12, HORIZONTAL_ALIGNMENT_LEFT, FAINT_TEXT)
			later.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lines.add_child(later)
	var level_label := _make_number_label("You: Lv " + str(state.get_workshop_level()), 12, HORIZONTAL_ALIGNMENT_RIGHT, MUTED_TEXT)
	level_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(level_label)
	return panel

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
	for category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
		grid.add_child(_make_focus_card(category))

func _make_focus_card(category: String) -> Button:
	var active := state.has_category_content(category)
	var button := _make_tile_button()
	button.custom_minimum_size = Vector2(0, 92)
	button.disabled = not active or state.in_run
	var border := LABS_ACCENT if active else Color.TRANSPARENT
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE, 14, border))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 14, LABS_ACCENT))
	button.add_theme_stylebox_override("pressed", _panel_style(SURFACE_HOVER, 14, LABS_ACCENT))
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
	button.add_theme_stylebox_override("pressed", _panel_style(SURFACE_HOVER, 14, CARDS_ACCENT))
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
	confirm.add_theme_color_override("font_color", ACCENT_INK)
	confirm.add_theme_color_override("font_hover_color", ACCENT_INK)
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

## One Workshop row (D049): the upgrade's name and rank, its value now, and a
## price chip. Tap the row to buy at the chosen step; hold it to read it. The
## description lives in the detail popup, so a category fits on one screen.
func _make_stat_card(definition: UpgradeDefinition, category: String) -> Button:
	var owned := state.get_owned(definition.id)
	var maxed := definition.is_maxed(owned)
	var unlocked := state.is_unlocked(definition)
	var plan := state.plan_purchase(definition.id, _buy_step(category))
	var affordable := int(plan.ranks) > 0

	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 60)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = definition.description
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	button.add_child(row)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_theme_constant_override("separation", 3)
	row.add_child(names)
	names.add_child(_make_label(definition.title.capitalize(), 14, HORIZONTAL_ALIGNMENT_LEFT, TEXT if unlocked else MUTED_TEXT))
	names.add_child(_make_number_label("Rank " + _coins(owned) + " / " + _coins(definition.max_rank), 11, HORIZONTAL_ALIGNMENT_LEFT, FAINT_TEXT))
	var value := _make_number_label(_stat_value_text(definition, owned), 16, HORIZONTAL_ALIGNMENT_RIGHT, TEXT if unlocked else MUTED_TEXT)
	value.custom_minimum_size = Vector2(72, 0)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.size_flags_vertical = Control.SIZE_FILL
	row.add_child(value)
	var chip := PanelContainer.new()
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip_style := _panel_style(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.12) if affordable else SURFACE, 16)
	chip_style.content_margin_left = 12
	chip_style.content_margin_right = 12
	chip_style.content_margin_top = 7
	chip_style.content_margin_bottom = 7
	chip.add_theme_stylebox_override("panel", chip_style)
	chip.add_child(_make_number_label(_stat_cost_text(definition, owned, maxed, unlocked, plan), 12, HORIZONTAL_ALIGNMENT_CENTER, ACCENT if affordable else MUTED_TEXT))
	var chip_wrap := HBoxContainer.new()
	chip_wrap.custom_minimum_size = Vector2(64, 0)
	chip_wrap.alignment = BoxContainer.ALIGNMENT_END
	chip_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_wrap.add_child(chip)
	row.add_child(chip_wrap)
	var line := ColorRect.new()
	line.color = DIVIDER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	line.offset_top = -1
	button.add_child(line)

	_add_long_press(button, func(): _show_stat_info(definition))
	button.pressed.connect(func(upgrade_id: String = definition.id, step: int = _buy_step(category)):
		if _consume_long_press(button):
			return
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
	return button

## A run Upgrades tile (D049): the row's name over its value, with the Cash
## price in the corner. Tap to buy, hold to read. Built once; _update_rig_card
## fills the parts that move with Cash.
func _make_rig_stat_card(definition: UpgradeDefinition, category: String) -> Button:
	var unlocked := state.is_unlocked(definition)
	var tile := Button.new()
	tile.text = ""
	tile.focus_mode = Control.FOCUS_NONE
	tile.custom_minimum_size = Vector2(0, 68)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.tooltip_text = definition.description
	if unlocked:
		tile.add_theme_stylebox_override("normal", _panel_style(SURFACE_RAISED, 12))
		tile.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, 12))
		tile.add_theme_stylebox_override("pressed", _panel_style(SURFACE_HOVER, 12))
	else:
		# A row the Workshop has not opened yet: an outline, not a fill.
		for stylebox_name in ["normal", "hover", "pressed"]:
			tile.add_theme_stylebox_override(stylebox_name, _panel_style(Color.TRANSPARENT, 12, LINE))
	var layout := _tile_layout(tile, 14, 11)
	layout.alignment = BoxContainer.ALIGNMENT_BEGIN
	var name_label := _make_label(definition.title.capitalize(), 12, HORIZONTAL_ALIGNMENT_LEFT, MUTED_TEXT if unlocked else FAINT_TEXT)
	name_label.clip_text = true
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(name_label)
	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(bottom)
	var value_label := _make_number_label("", 18, HORIZONTAL_ALIGNMENT_LEFT, TEXT if unlocked else FAINT_TEXT)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(value_label)
	var cost_label := _make_number_label("", 11, HORIZONTAL_ALIGNMENT_RIGHT, MUTED_TEXT)
	cost_label.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom.add_child(cost_label)
	_add_long_press(tile, func(): _show_stat_info(definition, true))
	tile.pressed.connect(func(upgrade_id: String = definition.id):
		if _consume_long_press(tile):
			return
		var step := _buy_step(state.workshop.selected_category)
		var plan := state.plan_rig_purchase(upgrade_id, step)
		if int(plan.ranks) == 0:
			if state.rig_room(upgrade_id) <= 0:
				_show_toast(definition.title + " IS AT MAX RANK", MUTED_TEXT)
			elif not state.is_unlocked(definition):
				_show_toast("NEEDS WORKSHOP LV " + str(definition.workshop_level_required), MUTED_TEXT)
			else:
				_show_toast("NEED " + state.get_rig_cost(upgrade_id).format_value() + " CASH", MUTED_TEXT)
			return
		var bought := state.purchase_rig_ranks(upgrade_id, step)
		if bought > 0:
			_show_toast("-" + _stat_number(plan.cost) + " CASH · +" + str(bought) + " " + definition.title, WORKSHOP_ACCENT)
			_snap_number_display()
			state.save()
			_refresh_all()
		else:
			_show_toast("CANNOT BUY NOW", MUTED_TEXT)
	)
	rig_card_refs[definition.id] = {"card": tile, "value_label": value_label, "cost_label": cost_label}
	_update_rig_card(definition)
	return tile

## The parts of a run Upgrades tile that move with Cash: its price, whether it
## is affordable, and MAX once Workshop and run ranks fill the row (D044).
func _update_rig_card(definition: UpgradeDefinition) -> void:
	var refs: Dictionary = rig_card_refs[definition.id]
	var tile: Button = refs.card
	if not is_instance_valid(tile):
		return
	var unlocked := state.is_unlocked(definition)
	var effective := state.get_owned(definition.id) + int(state.rig_rank_equivalent(definition))
	var next_cost := state.get_rig_cost(definition.id)
	var plan := state.plan_rig_purchase(definition.id, _buy_step(state.workshop.selected_category))
	var ranks := int(plan.ranks)
	var can_afford := ranks > 0
	var quoted_cost: ScientificNumber = plan.cost if can_afford else next_cost
	(refs.value_label as Label).text = _stat_value_text(definition, effective)
	var cost_label: Label = refs.cost_label
	if not unlocked:
		cost_label.text = "Workshop Lv " + str(definition.workshop_level_required)
		cost_label.add_theme_color_override("font_color", FAINT_TEXT)
		return
	if state.rig_room(definition.id) <= 0:
		cost_label.text = "MAX"
		cost_label.add_theme_color_override("font_color", MUTED_TEXT)
		return
	cost_label.text = ("×" + str(ranks) + " · " if ranks > 1 else "") + _stat_number(quoted_cost)
	cost_label.add_theme_color_override("font_color", ACCENT if can_afford else FAINT_TEXT)

## Holding a card reads it instead of acting on it: after LONG_PRESS_SECONDS
## held, the card's detail opens, and the release that follows is swallowed so
## a hold never buys.
func _add_long_press(button: Button, on_long_press: Callable) -> void:
	button.set_meta("long_pressed", false)
	# Held weakly: a card can be rebuilt, freeing its button, before the timer
	# fires, and a strong capture would then call into a freed object.
	var button_ref: WeakRef = weakref(button)
	button.button_down.connect(func():
		(button_ref.get_ref() as Button).set_meta("long_pressed", false)
		get_tree().create_timer(LONG_PRESS_SECONDS).timeout.connect(func():
			var held: Button = button_ref.get_ref()
			if held != null and held.is_pressed():
				held.set_meta("long_pressed", true)
				on_long_press.call()
		)
	)

## True, once, when this release ends a long press rather than a tap.
func _consume_long_press(button: Button) -> bool:
	if bool(button.get_meta("long_pressed", false)):
		button.set_meta("long_pressed", false)
		return true
	return false

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
		return "×" + str(int(plan.ranks)) + " · " + _coins(int(plan.cost))
	if int(plan.ranks) == 1:
		return _coins(int(plan.cost))
	return _coins(state.get_workshop_coin_cost_at(definition, owned))

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
		if state.saving_paused:
			persistence.text = "SAVING PAUSED. This save was made by a newer version of the game, so it is left untouched and progress here is not kept."
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
	var opening := not drawer.visible
	_close_sheets()
	_seat_sheet(drawer)
	drawer.visible = opening
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
	# In a run the foot of the arena holds Brace and the Number (D051), so the
	# toast reads at its head, under the wave line.
	var in_arena := current_tab == "number" and state.in_run
	toast_wrap.anchor_top = 0.0 if in_arena else 1.0
	toast_wrap.anchor_bottom = toast_wrap.anchor_top
	var bottom := RUN_STAGE_TOP + 30.0 if in_arena else _toast_bottom()
	toast_wrap.offset_top = bottom - 28.0
	toast_wrap.offset_bottom = bottom
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", colour)
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast_panel.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(1.6)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.5)

func _toast_bottom() -> float:
	if current_tab == "number":
		return -NavDock.BAR_HEIGHT - 12.0 - HUB_BATTLE_HEIGHT - 8.0
	return -NavDock.BAR_HEIGHT - 8.0

func _pulse_number(target_scale: float) -> void:
	if state.settings.reduce_motion:
		return
	var tween := create_tween()
	tween.tween_property(number_col, "scale", Vector2(target_scale, target_scale), 0.06)
	tween.tween_property(number_col, "scale", Vector2.ONE, 0.12)

## A one-shot reward total counts up from zero and lands with a small pop, so
## the reward reads as arriving rather than as having always been there. Used on
## the run-over sheet only: live production keeps its always-chasing follow.
func _count_total(label: Label, target: int, formatter: Callable, duration: float = 0.55) -> void:
	if state.settings.reduce_motion:
		label.text = formatter.call(target)
		return
	label.text = formatter.call(0)
	var tween := create_tween()
	tween.tween_method(
		func(value: float): label.text = formatter.call(int(round(value))),
		0.0, float(target), duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _pop_label(label))

## The landing beat of a count, and the wave-cleared beat. Scale is visual only,
## so a label inside a container can pop without disturbing the layout.
func _pop_label(label: Label, strength: float = 1.12) -> void:
	if state.settings.reduce_motion or label == null:
		return
	label.pivot_offset = label.size / 2.0
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(strength, strength), 0.07)
	tween.tween_property(label, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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

## A short horizontal rattle of the whole stage when a hit lands. Boss hits are
## heavier than routine tax so the two read as different events rather than the
## same one at two colours.
func _shake_stage(intensity: float = 6.0) -> void:
	if state.settings.reduce_motion or stage_root == null:
		return
	var tween := create_tween()
	tween.tween_property(stage_root, "position:x", -intensity, 0.04)
	tween.tween_property(stage_root, "position:x", intensity, 0.06)
	tween.tween_property(stage_root, "position:x", -intensity * 0.5, 0.06)
	tween.tween_property(stage_root, "position:x", 0.0, 0.05)

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
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.size = Vector2(360, 360)
	flash.position = stage_glow.position + stage_glow.size / 2.0 - flash.size / 2.0
	flash.modulate = Color(colour.r, colour.g, colour.b, 0.0)
	stage_root.add_child(flash)
	stage_root.move_child(flash, stage_glow.get_index() + 1)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.9, 0.05)
	tween.tween_property(flash, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

## How close the current wave is to its Collection hit, 0 (safe) to 1 (about
## to land). Zero whenever no hit is coming: outside a run, or once Liability
## is already cleared for the wave.
func _stage_danger_progress() -> float:
	if not state.in_run:
		return 0.0
	var encounter: Variant = state.active_encounter
	if encounter == null or encounter.max_liability.is_zero() or encounter.is_cleared():
		return 0.0
	return clampf(state.wave_accumulator / GameState.WAVE_INTERVAL_SECONDS, 0.0, 1.0)

## The glow behind the Number warms as the Hit approaches, and throbs through
## the last seconds of a boss wave so the heaviest Hit is telegraphed before it
## lands.
func _update_stage_colour() -> void:
	var danger := _stage_danger_progress()
	var colour := _heat_colour(danger)
	var encounter: Variant = state.active_encounter
	var boss: bool = state.in_run and encounter != null and encounter.is_boss
	var alpha := 1.0
	if boss and danger > BOSS_TELEGRAPH_START:
		var phase := (danger - BOSS_TELEGRAPH_START) / (1.0 - BOSS_TELEGRAPH_START)
		var beat := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * BOSS_TELEGRAPH_BEAT_RATE)
		alpha = lerpf(1.0, lerpf(0.6, 1.0, beat), phase)
	stage_glow.modulate = Color(colour.r, colour.g, colour.b, alpha)

## Moves the wave's number along its path (D050, D051). Its place is the wave
## clock, so it reaches the Number exactly when the Hit lands, 15 seconds in;
## a boss that has landed stays on the Number. It shows the HP still standing,
## less nothing the motes in flight have yet to deliver, and warms through the
## last half of its approach. A beaten wave scatters where it was; a new wave
## fades in at the arena's top edge.
func _update_wave_enemy(delta: float) -> void:
	if wave_enemy == null:
		return
	arena_fx.step(delta)
	var encounter: Variant = state.active_encounter
	var standing: bool = state.in_run and encounter != null and not encounter.max_liability.is_zero() and not encounter.is_cleared()
	if not standing:
		# Beaten inside the 2.5-second beat: the wave is still on screen.
		if encounter == enemy_encounter and state.in_run and encounter != null:
			_shatter_enemy(encounter.is_boss)
		wave_enemy.visible = false
		enemy_encounter = encounter
		_clear_arena()
		return
	if encounter != enemy_encounter or not wave_enemy.visible:
		enemy_encounter = encounter
		enemy_latched = false
		enemy_entry = _enemy_entry(state.wave)
		_clear_arena()
		wave_enemy.visible = true
		if not state.settings.reduce_motion:
			wave_enemy.modulate.a = 0.0
			create_tween().tween_property(wave_enemy, "modulate:a", 1.0, 0.3)
	# Reduce Motion stops movement, not information (MOTION_SYSTEM rule 1): the
	# number holds at the top edge and its caption keeps the time.
	var clock := clampf(state.wave_accumulator / GameState.WAVE_INTERVAL_SECONDS, 0.0, 1.0)
	if enemy_latched:
		enemy_travel = 1.0
	elif state.settings.reduce_motion:
		enemy_travel = 0.0
	else:
		enemy_travel = clock
	var boss: bool = encounter.is_boss
	var tint: Color = BOSS_COLOUR if boss else TEXT.lerp(WARNING, smoothstep(0.5, 1.0, enemy_travel))
	var shown: ScientificNumber = encounter.remaining_liability.add(arena_fx.in_flight()).add(mote_damage)
	if shown.compare_to(encounter.max_liability) > 0:
		shown = encounter.max_liability
	var caption := "hits " + state.get_effective_collection().format_value()
	if enemy_latched or state.settings.reduce_motion:
		caption += " in " + str(maxi(0, ceili(GameState.WAVE_INTERVAL_SECONDS - state.wave_accumulator))) + "s"
	wave_enemy.show_value(_stat_number(shown), tint, 30 if boss else 18, caption, BOSS_COLOUR if boss else MUTED_TEXT)
	var path := _enemy_path()
	var point: Vector2 = path[0].lerp(path[1], enemy_travel)
	wave_enemy.centre_on(point)
	arena_fx.target = wave_enemy.value_centre()
	arena_fx.trail_from = path[0]
	arena_fx.trail_to = point
	arena_fx.trail_colour = Color(tint, 0.22) if enemy_travel > 0.02 and not enemy_latched else Color.TRANSPARENT

## Drops the motes and the trail, for a wave that is gone or a new one.
func _clear_arena() -> void:
	arena_fx.clear_motes()
	arena_fx.trail_colour = Color.TRANSPARENT
	mote_damage = ScientificNumber.new()
	mote_elapsed = 0.0
	mote_crit = false

## Where the wave's number starts and stops, in the arena's space: from the top
## edge at the wave's entry point, straight towards the Number, stopping where
## the number and its caption meet the Number's own box.
func _enemy_path() -> Array:
	var number_box := number_label.get_global_rect()
	var home := number_box.get_center() - stage_root.global_position
	var value_half := wave_enemy.font.get_height(wave_enemy.font_size) / 2.0
	var margin := maxf(wave_enemy.size.x / 2.0 + 12.0, 40.0)
	var start := Vector2(clampf(enemy_entry * stage_root.size.x, margin, stage_root.size.x - margin), value_half + 8.0)
	var direction := (home - start).normalized()
	# The caption hangs below the number, so from above the gap is its whole
	# height; from the side, half the widths.
	var half := number_box.size / 2.0 + Vector2(wave_enemy.size.x / 2.0, wave_enemy.size.y - value_half) + Vector2(4.0, 4.0)
	var reach := INF
	if absf(direction.x) > 0.001:
		reach = half.x / absf(direction.x)
	if absf(direction.y) > 0.001:
		reach = minf(reach, half.y / absf(direction.y))
	var finish := home - direction * reach
	if finish.y < start.y:
		finish = start
	return [start, finish]

## Where across the top edge a wave enters, as a share of the arena's width. A
## golden-ratio step spreads successive waves out, and it never draws on the
## game's random stream, so it cannot change a run.
func _enemy_entry(wave: int) -> float:
	return 0.18 + 0.64 * fposmod(float(wave) * 0.618034, 1.0)

## A clean clear: the number breaks apart where it stood, with the no-Hit beat
## D041 asks for. Once only, since the body hides as it shatters.
func _shatter_enemy(boss: bool) -> void:
	if wave_enemy == null or not wave_enemy.visible:
		return
	_enemy_beat(WaveEnemy.Beat.SHATTER, BOSS_COLOUR if boss else TEXT)
	_spawn_floating_text("BEATEN · NO HIT", ACCENT, wave_enemy.value_centre() + stage_root.position)
	wave_enemy.visible = false
	_clear_arena()

## The wave reached the Number and its Hit came off (or was blocked). An
## ordinary wave swells into the Number and gives way to the next; a boss stays
## on the Number and hits again every clock (D051): no force pushes it back.
func _enemy_landed(colour: Color) -> void:
	_enemy_beat(WaveEnemy.Beat.SLAM, colour)
	if enemy_encounter != null and state.active_encounter == enemy_encounter and enemy_encounter.is_boss:
		enemy_latched = true

## Sends the wave damage just dealt from the Number to the wave's number as a
## mote (D051). The damage is already dealt; the mote only decides when the
## shown HP catches up.
func _fire_mote(amount: ScientificNumber, crit: bool) -> void:
	if amount.is_zero() or state.settings.reduce_motion or not wave_enemy.visible:
		return
	var number_box := number_label.get_global_rect()
	var from := Vector2(number_box.get_center().x, number_box.position.y) - stage_root.global_position
	arena_fx.fire(from, amount, crit)

## Passive damage goes out as one mote every MOTE_INTERVAL, carrying what built
## up, so a deep Tick Speed reads as a steady stream rather than a firehose.
func _gather_passive_damage(dealt: ScientificNumber, crit: bool, delta: float) -> void:
	if state.settings.reduce_motion or not wave_enemy.visible:
		mote_damage = ScientificNumber.new()
		return
	mote_damage = mote_damage.add(dealt)
	mote_crit = mote_crit or crit
	mote_elapsed += delta
	if mote_elapsed >= MOTE_INTERVAL and not mote_damage.is_zero():
		_fire_mote(mote_damage, mote_crit)
		mote_damage = ScientificNumber.new()
		mote_crit = false
		mote_elapsed = 0.0

## Plays a beat on a copy of the wave's number where it is now, so the live one
## is free to fade in as the next wave or stay on the Number as a boss. A
## shatter scatters its digits; a slam swells it into the Number and fades.
func _enemy_beat(kind: int, colour: Color) -> void:
	if wave_enemy == null or not wave_enemy.visible or state.settings.reduce_motion:
		return
	var ghost := WaveEnemy.new(number_font)
	ghost.beat = kind
	stage_root.add_child(ghost)
	ghost.show_value(wave_enemy.text, colour, wave_enemy.font_size)
	var point := wave_enemy.value_centre()
	if kind == WaveEnemy.Beat.SLAM:
		point = _enemy_path()[1]
	ghost.centre_on(point)
	var tween := create_tween()
	if kind == WaveEnemy.Beat.SLAM:
		tween.tween_property(ghost, "scale", Vector2(1.35, 1.35), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(ghost, "beat_progress", 1.0, 0.35)
	else:
		tween.tween_property(ghost, "beat_progress", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(ghost.queue_free)

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

## The Number is set at 48 (D049) and shrinks only when the string it has
## would not fit across the arena: "9.99e42" and "1,048,576" are very
## different widths at the same size.
func _number_font_size(text: String) -> int:
	var available := 300.0
	if stage_root != null and stage_root.size.x > 0.0:
		available = stage_root.size.x - 48.0
	var ideal := 48
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
	button.add_theme_stylebox_override("disabled", _panel_style(SURFACE, 12, Color.TRANSPARENT))
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
