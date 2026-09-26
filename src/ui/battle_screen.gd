extends Control
## The battle: the arena on top, the tower's and the wave's readouts below it,
## then the run's upgrades. It runs the sim at the chosen game speed and draws
## it; every rule lives in BattleSim. A run starts from the Workshop, and the
## Coins it earns go into the Workshop as they come. A run saved mid-way is
## resumed by replaying it from its seed and inputs, a slice a frame (D078).

const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")
const ArenaView = preload("res://src/ui/arena_view.gd")
const UpgradePanel = preload("res://src/ui/upgrade_panel.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")

## The run is over and its record is in the Workshop, so the game can save.
signal run_finished
signal home_pressed
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
	_adopt(BattleSim.new(seed_value, workshop.levels, workshop.open_groups))


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
		workshop.finish_run(sim.wave)
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
	_cash.text = "$ " + Palette.number(sim.cash)
	_coins.text = "● " + Palette.number(workshop.coins)
	_tower_damage.text = "Damage " + Palette.row_value("damage", sim.stat("damage"))
	_tower_regen.text = "Regen %.2f/s" % sim.stat("health_regen")
	# A recovery package can heal past the most; the bar stays full then.
	_health_bar.max_value = maxf(sim.max_health(), sim.health)
	_health_bar.value = sim.health
	# Whole, as The Tower shows it. A tower still standing never reads 0, and
	# full health never reads more than the most, except when overhealed.
	var most := roundf(sim.max_health())
	var now := roundf(sim.health) if sim.health > sim.max_health() else minf(roundf(sim.health), most)
	if sim.alive:
		now = maxf(now, 1.0)
	_health_text.text = "%s / %s" % [Palette.number(now), Palette.number(most)]
	_wave_title.text = "Wave %d" % sim.wave
	_enemy_attack.text = "Attack " + Palette.number(sim.enemy_attack_now("basic"))
	_enemy_health.text = "Health " + Palette.number(sim.enemy_health_now("basic"))
	_wave_bar.value = sim.wave_clock / TowerData.wave_seconds()
	_upgrades.refresh()


func _show_run_over() -> void:
	var cause := {"basic": "a basic enemy", "fast": "a fast enemy", "tank": "a tank", "ranged": "a ranged enemy", "boss": "a boss"}
	var ended := sim.killed_by == "ended"
	_over_title.text = "Run ended" if ended else "Tower destroyed"
	var how := "Ended on wave %d" % sim.wave if ended else "Destroyed on wave %d by %s" % [sim.wave, cause.get(sim.killed_by, sim.killed_by)]
	_over_text.text = "%s\n%s of game time · %d kills\nCash earned $%s · Coins earned %s\nBest wave %d" % [
		how, Palette.clock(sim.time), sim.kills, Palette.number(sim.cash_earned), Palette.number(sim.coins), workshop.best_wave]
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
	column.add_theme_constant_override("separation", 8)
	add_child(column)

	_arena = ArenaView.new()
	_arena.clip_contents = true
	_arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_arena.custom_minimum_size = Vector2(0, 320)
	_arena.resized.connect(func(): _arena.centre = Vector2(_arena.size.x * 0.5, _arena.size.y * 0.55))
	column.add_child(_arena)

	var money := VBoxContainer.new()
	money.position = Vector2(16, 14)
	_arena.add_child(money)
	_cash = _number_label(20, Palette.TEXT)
	_coins = _number_label(16, Palette.COIN)
	money.add_child(_cash)
	money.add_child(_coins)

	# The speed and End run buttons, right-aligned in the arena's corner.
	var corner := VBoxContainer.new()
	corner.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	corner.offset_right = -16
	corner.offset_top = 14
	corner.alignment = BoxContainer.ALIGNMENT_END
	_arena.add_child(corner)
	_speed_button = Button.new()
	_speed_button.text = "×1"
	_speed_button.add_theme_font_override("font", Palette.NUMBER_FONT)
	_speed_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_speed_button.pressed.connect(_cycle_speed)
	corner.add_child(_speed_button)
	var end := Button.new()
	end.text = "End run"
	end.size_flags_horizontal = Control.SIZE_SHRINK_END
	end.pressed.connect(func():
		if sim != null:
			sim.end_run())
	corner.add_child(end)

	var readouts := HBoxContainer.new()
	readouts.add_theme_constant_override("separation", 8)
	column.add_child(_margined(readouts))
	readouts.add_child(_tower_panel())
	readouts.add_child(_wave_panel())

	_upgrades = UpgradePanel.new()
	column.add_child(_margined(_upgrades, 16))

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
	over_column.add_child(_over_text)
	var again := Button.new()
	again.text = "Battle again"
	again.pressed.connect(func(): start_run(randi()))
	over_column.add_child(again)
	var home := Button.new()
	home.text = "Home"
	home.pressed.connect(func(): home_pressed.emit())
	over_column.add_child(home)


func _tower_panel() -> PanelContainer:
	var panel := _panel()
	var column := VBoxContainer.new()
	panel.add_child(column)
	var line := HBoxContainer.new()
	column.add_child(line)
	_tower_damage = _number_label(13, Palette.MUTED)
	_tower_regen = _number_label(13, Palette.MUTED)
	_tower_damage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(_tower_damage)
	line.add_child(_tower_regen)
	var bar_holder := Control.new()
	bar_holder.custom_minimum_size = Vector2(0, 22)
	column.add_child(bar_holder)
	_health_bar = _bar(Palette.ACCENT)
	_health_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_holder.add_child(_health_bar)
	_health_text = _number_label(13, Palette.TEXT)
	_health_text.add_theme_color_override("font_outline_color", Palette.GROUND)
	_health_text.add_theme_constant_override("outline_size", 4)
	_health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_holder.add_child(_health_text)
	return panel


func _wave_panel() -> PanelContainer:
	var panel := _panel()
	var column := VBoxContainer.new()
	panel.add_child(column)
	var line := HBoxContainer.new()
	column.add_child(line)
	_wave_title = Label.new()
	_wave_title.add_theme_font_size_override("font_size", 18)
	_wave_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(_wave_title)
	var enemy := VBoxContainer.new()
	enemy.add_theme_constant_override("separation", 0)
	line.add_child(enemy)
	_enemy_attack = _number_label(11, Palette.MUTED)
	_enemy_health = _number_label(11, Palette.MUTED)
	_enemy_attack.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enemy_health.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemy.add_child(_enemy_attack)
	enemy.add_child(_enemy_health)
	_wave_bar = _bar(Palette.ACCENT)
	_wave_bar.max_value = 1.0
	_wave_bar.custom_minimum_size = Vector2(0, 6)
	column.add_child(_wave_bar)
	return panel


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.panel_box())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel


func _bar(colour: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	var back := StyleBoxFlat.new()
	back.bg_color = Palette.SURFACE_RAISED
	back.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = colour
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _number_label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", Palette.NUMBER_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	return label


func _margined(child: Control, bottom: int = 0) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(child)
	return margin
