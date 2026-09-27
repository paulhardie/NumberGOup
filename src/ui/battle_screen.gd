extends Control
## The battle, laid out as the owner's main-screen design: Cash, Coins and the
## speed and End run pills over the arena, the Number large in its light, the
## tower's and the wave's readouts under a hairline, then the run's upgrades. It runs the sim at the chosen game speed and draws
## it; every rule lives in BattleSim. A run starts from the Workshop, and the
## Coins it earns go into the Workshop as they come. A run saved mid-way is
## resumed by replaying it from its seed and inputs, a slice a frame (D078).

const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")
const ArenaView = preload("res://src/ui/arena_view.gd")
const Settings = preload("res://src/settings.gd")
const UpgradePanel = preload("res://src/ui/upgrade_panel.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")

## The run is over and its record is in the Workshop, so the game can save.
signal run_finished
signal home_pressed
## The Number reached a new digit (D099), for the music's chime.
signal digit_reached(power: int)
## A saved run couldn't be brought back: its record is damaged ("damaged"),
## or the game changed so its replay no longer ends where it was left
## ("changed").
signal resume_failed(saved: Dictionary, reason: String)

## Game speeds, for testing a run quickly (docs/REBUILD_SPEC.md, "Dev only").
const SPEEDS := [1.0, 2.0, 5.0]
## At most this many ticks a frame, so a slow frame can't snowball.
const MAX_TICKS_PER_FRAME := 400
## Ticks of a saved run replayed a frame while resuming: about an hour of game
## time takes a few seconds, and the screen stays live meanwhile.
const RESUME_TICKS_PER_FRAME := 2000

var sim: BattleSim
## Set before the screen is added; a fresh one if not.
var workshop: Workshop
## The player's settings (D088), set before the screen is added; defaults if not.
var settings: Settings
## The saved run to resume (Save.load_run), set before the screen is added;
## empty for a new run.
var resume: Dictionary = {}
var _replay: RunReport.Replay
var _resuming: Label
var _speed_index := 0
## The run's Coins already moved into the Workshop.
var _banked := 0.0
var _carry := 0.0
## Real seconds the run has been played, and how many at each game speed,
## for the activity log.
var _real_seconds := 0.0
var _seconds_at_speed := {}

var _arena: ArenaView
var _cash: Label
var _coins: Label
var _speed_button: Button
var _tower_damage: Label
var _tower_regen: Label
var _health_bar: ProgressBar
var _health_text: Label
var _wave_title: Label
var _enemy_attack: Label
var _enemy_health: Label
var _wave_bar: ProgressBar
var _mono := Palette.weight(Palette.NUMBER_FONT, 400)
var _mono_bold := Palette.weight(Palette.NUMBER_FONT, 500)
var _upgrades: UpgradePanel
var _over: PanelContainer
var _over_title: Label
var _over_text: Label


func _ready() -> void:
	theme = Palette.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if workshop == null:
		workshop = Workshop.new()
	_build()
	if resume.is_empty():
		start_run(randi())
	else:
		_begin_resume()


func start_run(seed_value: int) -> void:
	_adopt(BattleSim.new(seed_value, workshop.levels, workshop.open_groups, settings.switches() if settings != null else {}))


func _begin_resume() -> void:
	_resuming = Label.new()
	_resuming.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_resuming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resuming.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_resuming.add_theme_font_size_override("font_size", 20)
	_resuming.text = "Resuming your run…"
	add_child(_resuming)
	if not RunReport.is_replayable(resume):
		_fail_resume("damaged")
		return
	_replay = RunReport.Replay.new(resume)


func _finish_resume() -> void:
	var again := _replay.sim
	_replay = null
	if not again.alive or not RunReport.matches(resume, again):
		_fail_resume("changed")
		return
	var saved := resume
	resume = {}
	_resuming.queue_free()
	_adopt(again)
	# The Coins it had already put in the Workshop, which the save kept with it.
	_banked = float(saved.get("banked", again.coins))
	var play: Dictionary = saved.get("play", {})
	_real_seconds = float(play.get("real_seconds", 0.0))
	_seconds_at_speed = play.get("seconds_at_speed", {}).duplicate()


## Deferred, so the game can change screens outside this one's frame.
func _fail_resume(reason: String) -> void:
	var saved := resume
	resume = {}
	_replay = null
	resume_failed.emit.call_deferred(saved, reason)


## Plays `run_sim` from here on.
func _adopt(run_sim: BattleSim) -> void:
	sim = run_sim
	sim.record_events = true
	_banked = 0.0
	_arena.sim = sim
	_upgrades.set_sim(sim)
	_carry = 0.0
	_real_seconds = 0.0
	_seconds_at_speed = {}
	_over.visible = false


func _process(delta: float) -> void:
	if _replay != null:
		# is_replayable should make this impossible; never sit on the
		# resuming screen for good if a record still slips through.
		if _replay.sim == null:
			_fail_resume("damaged")
			return
		if _replay.advance(RESUME_TICKS_PER_FRAME):
			_finish_resume()
		else:
			_resuming.text = "Resuming your run… wave %d" % _replay.sim.wave
		return
	if sim == null:
		return
	if sim.alive:
		_real_seconds += delta
		var speed := "×%d" % int(SPEEDS[_speed_index])
		_seconds_at_speed[speed] = float(_seconds_at_speed.get(speed, 0.0)) + delta
	_carry += delta * float(SPEEDS[_speed_index])
	var ticks := 0
	while sim.alive and _carry >= BattleSim.TICK and ticks < MAX_TICKS_PER_FRAME:
		sim.step()
		_carry -= BattleSim.TICK
		ticks += 1
	if ticks == MAX_TICKS_PER_FRAME:
		_carry = 0.0
	# Draw each enemy and shot between its last two ticks, so movement is
	# smooth whatever the display's frame rate.
	_arena.blend = clampf(_carry / BattleSim.TICK, 0.0, 1.0) if sim.alive else 1.0
	_arena.absorb(sim.events, delta)
	sim.events.clear()
	_arena.queue_redraw()
	_bank_coins()
	_refresh()
	if not sim.alive and not _over.visible:
		workshop.finish_run(sim.wave, sim.peak_number)
		run_finished.emit()
		_show_run_over()


## The run to keep in the save: one still being resumed as it was loaded, the
## one being played with the Coins it has banked, or {} once it's over.
func run_state() -> Dictionary:
	if not resume.is_empty():
		return resume
	if sim == null or not sim.alive:
		return {}
	var state := report()
	state["banked"] = _banked
	# The version that recorded it, which a lost run's log entry keeps.
	state["game"] = ActivityLog.game_version()
	return state


## The run for the activity log: replayable, with its real play time.
func report() -> Dictionary:
	return RunReport.build(sim, {"real_seconds": _real_seconds, "seconds_at_speed": _seconds_at_speed.duplicate()})


func _bank_coins() -> void:
	workshop.add_coins(sim.coins - _banked)
	_banked = sim.coins


func _refresh() -> void:
	_cash.text = Palette.number(sim.cash)
	_coins.text = Palette.number(workshop.coins)
	_tower_damage.text = "dmg " + Palette.row_value("damage", sim.stat("damage"))
	_tower_regen.text = "+%.2f/s" % sim.stat("health_regen")
	# The Number against this run's peak (D083: it has no ceiling).
	_health_bar.max_value = maxf(sim.peak_number, 0.001)
	_health_bar.value = sim.health
	var now := Palette.number_shown(sim.health, sim.max_health(), sim.alive)
	_health_text.text = "%s / %s" % [Palette.number(now), Palette.number(maxf(now, roundf(sim.peak_number)))]
	_wave_title.text = "Wave %d" % sim.wave
	var through := clampf(sim.wave_clock / TowerData.wave_seconds(), 0.0, 1.0)
	# The basic enemy's Attack and Health this wave, as values, not multipliers.
	_enemy_attack.text = "atk " + Palette.number(sim.enemy_attack_now("basic"))
	_enemy_health.text = "hp " + Palette.number(sim.enemy_health_now("basic"))
	_wave_bar.value = through
	_upgrades.refresh()


func _show_run_over() -> void:
	var cause := {"basic": "a basic enemy", "fast": "a fast enemy", "tank": "a tank", "ranged": "a ranged enemy", "boss": "a boss", "divider": "a Divider", "multiplier": "a Multiplier"}
	var ended := sim.killed_by == "ended"
	_over_title.text = "Run ended" if ended else "Tower destroyed"
	var how := "Ended on wave %d" % sim.wave if ended else "Destroyed on wave %d by %s" % [sim.wave, cause.get(sim.killed_by, sim.killed_by)]
	var lost := 0.0
	for kind in sim.lost_to:
		lost += float(sim.lost_to[kind])
	var divided := float(sim.lost_to.get("divider", 0.0))
	var dividers := "%d Divider%s reached you, taking %s of the %s you lost" % [sim.dividers_landed, "" if sim.dividers_landed == 1 else "s",
		Palette.number(divided), Palette.number(lost)] if sim.dividers_landed > 0 else "No Divider reached you"
	_over_text.text = "%s\n%s of game time · %d kills\nPeak Number %s · %s\nCash earned $%s · Coins earned %s\nBest wave %d · best Number %s" % [
		how, Palette.clock(sim.time), sim.kills, Palette.number(ceilf(sim.peak_number)), dividers, Palette.number(sim.cash_earned),
		Palette.number(sim.coins), workshop.best_wave, Palette.number(ceilf(workshop.best_number))]
	if sim.multipliers:
		_over_text.text += "\nMultipliers killed %d of %d, adding %s" % [sim.multipliers_killed, sim.multipliers_spawned,
			Palette.number(float(sim.gained_from.get("multiplier", 0.0)))]
	if sim.kill_growth:
		_over_text.text += "\nKills grew the Number by %s" % Palette.number(float(sim.gained_from.get("kills", 0.0)))
	_over.visible = true


func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_speed_button.text = "×%d" % int(SPEEDS[_speed_index])


func _build() -> void:
	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 0)
	add_child(column)

	_arena = ArenaView.new()
	_arena.digit_reached.connect(func(power: int): digit_reached.emit(power))
	_arena.clip_contents = true
	_arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_arena.custom_minimum_size = Vector2(0, 320)
	_arena.resized.connect(func(): _arena.centre = Vector2(_arena.size.x * 0.5, _arena.size.y * 0.55))
	column.add_child(_arena)

	# One line over the arena: Cash and Coins at the same size on the left,
	# the speed and End run pills on the right, all centred on the pills.
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 20
	top.custom_minimum_size = Vector2(0, 36)
	top.add_theme_constant_override("separation", 8)
	_arena.add_child(top)
	var money := Palette.money_line(_mono_bold)
	top.add_child(money.line)
	_cash = money.cash
	_coins = money.coins
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	_speed_button = Palette.pill("×1", Palette.TEXT, _mono)
	_speed_button.pressed.connect(_cycle_speed)
	top.add_child(_speed_button)
	var end := Palette.pill("End run", Palette.SOFT)
	end.pressed.connect(func():
		if sim != null:
			sim.end_run())
	top.add_child(end)

	var readouts := HBoxContainer.new()
	readouts.add_theme_constant_override("separation", 28)
	var readout_margin := _margined(readouts)
	readout_margin.add_theme_constant_override("margin_top", 16)
	readout_margin.add_theme_constant_override("margin_bottom", 16)
	column.add_child(_hairline())
	column.add_child(readout_margin)
	readouts.add_child(_tower_panel())
	readouts.add_child(_wave_panel())
	column.add_child(_hairline())

	_upgrades = UpgradePanel.new()
	var upgrades_margin := _margined(_upgrades, 24)
	upgrades_margin.add_theme_constant_override("margin_top", 4)
	column.add_child(upgrades_margin)

	_over = PanelContainer.new()
	_over.add_theme_stylebox_override("panel", Palette.panel_box())
	_over.set_anchors_preset(Control.PRESET_CENTER)
	_over.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_over.grow_vertical = Control.GROW_DIRECTION_BOTH
	_over.custom_minimum_size = Vector2(300, 0)
	add_child(_over)
	var over_column := VBoxContainer.new()
	over_column.add_theme_constant_override("separation", 12)
	_over.add_child(over_column)
	_over_title = Label.new()
	_over_title.add_theme_font_size_override("font_size", 20)
	_over_title.add_theme_color_override("font_color", Palette.WARNING)
	over_column.add_child(_over_title)
	_over_text = Label.new()
	_over_text.add_theme_color_override("font_color", Palette.MUTED)
	_over_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_over_text.custom_minimum_size = Vector2(300, 0)
	over_column.add_child(_over_text)
	var again := Button.new()
	again.text = "Battle again"
	again.pressed.connect(func(): start_run(randi()))
	over_column.add_child(again)
	var home := Button.new()
	home.text = "Home"
	home.pressed.connect(func(): home_pressed.emit())
	over_column.add_child(home)


func _tower_panel() -> VBoxContainer:
	var parts := _readout("Tower", Palette.ACCENT)
	_health_text = parts.value
	_health_bar = parts.bar
	_tower_damage = parts.left
	_tower_regen = parts.right
	return parts.column


func _wave_panel() -> VBoxContainer:
	var parts := _readout("Wave 1", Color(1, 1, 1, 0.55))
	_wave_title = parts.title
	# Only the bar says how far through the wave is; a ticking count was noise.
	parts.value.visible = false
	_wave_bar = parts.bar
	_wave_bar.max_value = 1.0
	_enemy_attack = parts.left
	_enemy_health = parts.right
	return parts.column


## One readout: a title and a figure, a thin bar in `colour`, and two small
## figures under it. Returns its pieces by name.
func _readout(title_text: String, colour: Color) -> Dictionary:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 13)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var value := _number_label(12, Palette.MUTED)
	head.add_child(value)
	var bar := _bar(colour)
	bar.custom_minimum_size = Vector2(0, 3)
	column.add_child(bar)
	var foot := HBoxContainer.new()
	column.add_child(foot)
	var left := _number_label(11, Palette.MUTED)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := _number_label(11, Palette.MUTED)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	foot.add_child(left)
	foot.add_child(right)
	return {"column": column, "title": title, "value": value, "bar": bar, "left": left, "right": right}


## A thin line across the screen between the arena, the readouts and the upgrades.
func _hairline() -> MarginContainer:
	return _margined(Palette.hairline())


func _bar(colour: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	var back := StyleBoxFlat.new()
	back.bg_color = Palette.HAIRLINE
	back.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = colour
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _number_label(font_size: int, colour: Color, font: Font = null, text: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font if font != null else _mono)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	return label


func _margined(child: Control, bottom: int = 0) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(child)
	return margin
