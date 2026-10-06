extends Control
## The battle (premium minimal since D143): Cash, Coins and the speed and End
## run pills along the top, the arena with the Number large in its light, a
## slim wave line under it (tap for Wave Info), then the run's upgrades. No
## Tower-style stats strip: the Number is the tower's health, and the rest
## lives in Wave Info and on the upgrade cards. It runs the sim at the chosen
## game speed and draws it; every rule lives in BattleSim. A run starts from the Workshop, and the
## Coins it earns go into the Workshop as they come. A run saved mid-way is
## resumed from exact state (D126); older saves replay their inputs (D078).

const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")
const ArenaView = preload("res://src/ui/arena_view.gd")
const UpgradePanel = preload("res://src/ui/upgrade_panel.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")
const WaveInfo = preload("res://src/ui/wave_info.gd")
const Overlay = preload("res://src/ui/overlay.gd")
const UpgradeInfo = preload("res://src/ui/upgrade_info.gd")
const Progression = preload("res://src/tower/progression.gd")
const BattleSnapshot = preload("res://src/tower/battle_snapshot.gd")

## The run is over and its record is in the Workshop, so the game can save.
signal run_finished
signal home_pressed
## The Number reached a new digit (D099), for the music's chime.
signal digit_reached(power: int)
signal wave_reward(reward: Dictionary)
## A saved run couldn't be brought back: its record is damaged ("damaged"),
## or the game changed so its replay no longer ends where it was left
## ("changed").
signal resume_failed(saved: Dictionary, reason: String)

## Game speeds, for testing a run quickly (docs/REBUILD_SPEC.md, "Dev only").
const SPEEDS := [1.0, 2.0, 5.0]
## How fast The Tower's ×1 runs against real time: its 26 seconds of spawning
## take 22.9 real seconds (the owner's recording, D121). Every speed runs this
## much faster, so ours match The Tower's ×1 (D122); its ×2 and ×5 haven't
## been measured.
const TOWER_CLOCK := 1.135
## The wave bar while enemies are spawning.
const WAVE_BAR := Color(1, 1, 1, 0.55)
## What a new enemy does, said once the first time a player meets it (D133,
## D144, D145, D125's disclosure): its sign and one line. A player meets it
## the first time it comes on a wave past their best, since our enemies, the
## first tank and the boss come on the same waves in every run; so nothing
## new is saved.
const FIRST_SIGHT := {
	"lock": {"sign": "=", "text": "Lock: while it stands in range, your Number can't go up. Kill it, or knock it back."},
	"tank": {"sign": "5×", "text": "Tank: five times a basic's health, slow and heavy. Knockback barely moves it."},
	"boss": {"sign": "20×", "text": "Boss: twenty times a basic's health, every tenth wave. Orbs and shockwaves can't touch it."},
}
## Real seconds a first-sight card stays up, unless tapped away.
const FIRST_SIGHT_SECONDS := 8.0
## At most this many ticks a frame, so a slow frame can't snowball.
const MAX_TICKS_PER_FRAME := 400
## Ticks of a saved run replayed a frame while resuming: about an hour of game
## time takes a few seconds, and the screen stays live meanwhile.
const RESUME_TICKS_PER_FRAME := 2000

var sim: BattleSim
## The milestones the run just ended reached, for its panel and the log (D107).
var milestones: Array[Dictionary] = []
## Set before the screen is added; a fresh one if not.
var workshop: Workshop
var progression: Progression
## The saved run to resume (Save.load_run), set before the screen is added;
## empty for a new run.
var resume: Dictionary = {}
## The rules a new run starts with (RunConfig.game_tuning, D158), which the game
## sets from the settings. A resumed run keeps the ones it started with; empty
## where nothing sets it, as the tools and tests that play the old rules.
var tuning: Dictionary = {}
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
## The Cash chip around it, set aside with the Number as Cash (D156).
var _cash_chip: Control
var _coins: Label
var _speed_button: Button
var _wave_title: Label
var _wave_bar: ProgressBar
## The wave bar's fill, recoloured for the cooldown.
var _wave_fill: StyleBoxFlat
var _mono := Palette.weight(Palette.NUMBER_FONT, 400)
var _mono_bold := Palette.weight(Palette.NUMBER_FONT, 500)
var _upgrades: UpgradePanel
var _over: PanelContainer
## The run-over panel's "Battle again", hidden after a first run (D125).
var _again: Button
var _wave_info: WaveInfo
var _over_title: Label
var _over_text: Label
## The first-sight card, the kinds it has told of this run, and how long it has left.
var _sight: Overlay
var _sight_sign: Label
var _sight_text: Label
var _sight_left := 0.0
var _sighted: Array[String] = []
## An upgrade held in battle (D151): its card, the row it reads and what it
## lays out, kept up to date while the run goes on beneath it.
var _held_card: Overlay
var _held_id := ""
var _held_info: UpgradeInfo


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
	var effects := progression.run_effects() if progression != null else []
	var rules := progression.run_effects("rule") if progression != null else []
	_adopt(BattleSim.new(seed_value, workshop.levels, workshop.open_groups, 1, effects, rules, tuning))


func _begin_resume() -> void:
	_resuming = Label.new()
	_resuming.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_resuming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resuming.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_resuming.add_theme_font_size_override("font_size", 20)
	_resuming.text = "Resuming your run…"
	add_child(_resuming)
	if not RunReport.is_replayable(resume):
		_fail_resume("changed" if RunReport.valid_record(resume, true) else "damaged")
		return
	if resume.has("snapshot"):
		var restored := BattleSnapshot.restore(resume.snapshot)
		if restored == null or not restored.alive or not RunReport.matches(resume, restored):
			_fail_resume("changed")
			return
		_accept_resume(restored)
		return
	_replay = RunReport.Replay.new(resume)


func _finish_resume() -> void:
	var again := _replay.sim
	_replay = null
	if not again.alive or not RunReport.matches(resume, again):
		_fail_resume("changed")
		return
	_accept_resume(again)


func _accept_resume(again: BattleSim) -> void:
	var saved := resume
	resume = {}
	_resuming.queue_free()
	_adopt(again)
	# The Coins it had already put in the Workshop, which the save kept with it.
	_banked = again.coins if saved.has("snapshot") else float(saved.get("banked", again.coins))
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
	# The run's words follow the run's own rules, whatever the switch says now.
	Palette.number_cash = sim.number_cash
	# Before the first frame draws, so a resumed run never shows the Cash chip
	# it doesn't have (or lacks the one it does).
	_cash_chip.visible = not sim.number_cash
	_banked = 0.0
	_arena.sim = sim
	_upgrades.set_sim(sim)
	_carry = 0.0
	_real_seconds = 0.0
	_seconds_at_speed = {}
	_over.visible = false
	_sighted.clear()
	_sight.dismiss()
	if _held_card != null:
		_held_card.dismiss()


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
	_carry += delta * float(SPEEDS[_speed_index]) * TOWER_CLOCK
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
	if progression != null:
		for reward in progression.observe(sim.tier, sim.wave, sim.wave if sim.killed_by == "data_limit" else sim.wave - 1):
			wave_reward.emit(reward)
	_refresh()
	_first_sight(delta)
	if not sim.alive and not _over.visible:
		milestones = workshop.finish_run(sim.wave, sim.peak_number, sim.cash_earned)
		run_finished.emit()
		_show_run_over()


## The run to keep in the save: one still being resumed as it was loaded, the
## one being played with the Coins it has banked, or {} once it's over.
func run_state() -> Dictionary:
	if not resume.is_empty():
		return resume
	if sim == null or not sim.alive:
		return {}
	# The same atomic save keeps every earned Coin with this snapshot. Resume
	# uses its lossless Coin total rather than the rounded report readout.
	_bank_coins()
	var state := report()
	state["banked"] = _banked
	# The version that recorded it, which a lost run's log entry keeps.
	state["game"] = ActivityLog.game_version()
	state["snapshot"] = BattleSnapshot.capture(sim)
	return state


## The run for the activity log: replayable, with its real play time.
func report() -> Dictionary:
	return RunReport.build(sim, {"real_seconds": _real_seconds, "seconds_at_speed": _seconds_at_speed.duplicate()})


func _bank_coins() -> void:
	workshop.add_coins(sim.coins - _banked)
	_banked = sim.coins


## The wave line's title: the wave, and "Boss" while one lives (D145). The ›
## says it opens Wave Info.
static func wave_title(battle: BattleSim) -> String:
	return ("Wave %d · Boss  ›" if boss_alive(battle) else "Wave %d  ›") % battle.wave


static func boss_alive(battle: BattleSim) -> bool:
	return battle.enemies.any(func(enemy): return enemy.kind == "boss")


func _refresh() -> void:
	_cash.text = "$ " + Palette.money(sim.cash)
	# With the Number as Cash (D156) the Number is the wallet: no Cash of its own.
	_cash_chip.visible = not sim.number_cash
	_coins.text = "● " + Palette.money(workshop.coins)
	_wave_title.text = wave_title(sim)
	# As The Tower's (D122): the bar fills over the spawning, then again, in
	# the accent, over the cooldown.
	var spawn := TowerData.spawn_seconds()
	var cooling := sim.wave_clock >= spawn
	var through := (sim.wave_clock - spawn) / (TowerData.wave_seconds() - spawn) if cooling else sim.wave_clock / spawn
	# While a boss lives, the bar is in its glow (D145).
	_wave_fill.bg_color = Palette.BOSS_GLOW if boss_alive(sim) else Palette.ACCENT if cooling else WAVE_BAR
	_wave_bar.value = clampf(through, 0.0, 1.0)
	if _wave_info.visible:
		_wave_info.show_for(sim)
	_upgrades.refresh()
	if _held_card != null:
		_update_held()


func _show_run_over() -> void:
	var cause := {"basic": "a basic enemy", "fast": "a fast enemy", "tank": "a tank", "ranged": "a ranged enemy", "boss": "a boss", "divider": "a Divider",
		"protector": "a Protector", "vampire": "a Vampire", "ray": "a Ray", "scatter": "a Scatter"}
	var ended := sim.killed_by in ["ended", "data_limit"]
	_over_title.text = "Run ended" if ended else "Tower destroyed"
	var how := "Ended on wave %d" % sim.wave if ended else "Destroyed on wave %d by %s" % [sim.wave, cause.get(sim.killed_by, sim.killed_by)]
	var lost := 0.0
	for kind in sim.lost_to:
		lost += float(sim.lost_to[kind])
	var divided := float(sim.lost_to.get("divider", 0.0))
	var dividers := "%d Divider%s reached you, taking %s of the %s you lost" % [sim.dividers_landed, "" if sim.dividers_landed == 1 else "s",
		Palette.amount(divided), Palette.amount(lost)] if sim.dividers_landed > 0 else "No Divider reached you"
	_over_text.text = ("%s\n%s of game time · %d kills\nPeak Number %s · %s\n" + ("Number earned %s" if sim.number_cash else "Cash earned $%s") + " · Coins earned %s\nBest wave %d · best Number %s") % [
		how, Palette.clock(sim.time), sim.kills, Palette.full(ceilf(sim.peak_number)), dividers, Palette.money(sim.cash_earned),
		Palette.money(sim.coins), workshop.best_wave, Palette.full(ceilf(workshop.best_number))]
	if sim.number_cash:
		# Income is in "Number earned" above; what a Lock was still holding when
		# the run ended is lost with it (D157).
		if sim.lock_held > 0.0:
			_over_text.text += "\n%s was still held on a Lock" % Palette.amount(sim.lock_held)
	else:
		_over_text.text += "\nKills grew the Number by %s" % Palette.amount(float(sim.gained_from.get("kills", 0.0)))
	if sim.killed_by == "data_limit":
		_over_text.text += "\nAll supported waves cleared. More enemy data is needed to continue further."
	for milestone in milestones:
		_over_text.text += "\nMilestone: %s earned · +● %s" % [Palette.full(float(milestone.number), INF), Palette.money(float(milestone.coins))]
	# A first run's end leads Home, where the Workshop's welcome waits (D125).
	_again.visible = workshop.gift_waiting <= 0.0
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

	# One line along the top, above the arena rather than over it, so an
	# enemy walking in never passes under the chips (D143): Cash and Coins on
	# the left, the speed and End run pills on the right.
	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0, 36)
	top.add_theme_constant_override("separation", 8)
	var top_margin := _margined(top, 4)
	top_margin.add_theme_constant_override("margin_top", 20)
	column.add_child(top_margin)
	var money := Palette.money_line(_mono_bold)
	top.add_child(money.line)
	_cash = money.cash
	_cash_chip = money.line.get_child(0)
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

	_arena = ArenaView.new()
	_arena.digit_reached.connect(func(power: int): digit_reached.emit(power))
	_arena.clip_contents = true
	_arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_arena.custom_minimum_size = Vector2(0, 320)
	_arena.resized.connect(func(): _arena.centre = Vector2(_arena.size.x * 0.5, _arena.size.y * 0.52))
	column.add_child(_arena)

	# The wave line: its number (tap for Wave Info) and The Tower's two-phase
	# bar (D122), in place of the old Tower and Wave readouts (D143).
	var wave_margin := _margined(_wave_line(), 14)
	wave_margin.add_theme_constant_override("margin_top", 10)
	column.add_child(wave_margin)

	_upgrades = UpgradePanel.new()
	_upgrades.info_requested.connect(_show_held)
	var upgrades_margin := _margined(_upgrades, 24)
	upgrades_margin.add_theme_constant_override("margin_top", 4)
	column.add_child(upgrades_margin)

	# Both banners live under the screen from the start, hidden, so they go
	# with it whether or not they were ever shown.
	_wave_info = WaveInfo.new()
	add_child(_wave_info)
	_build_first_sight()

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
	_again = Button.new()
	_again.text = "Battle again"
	_again.pressed.connect(func(): start_run(randi()))
	over_column.add_child(_again)
	var home := Button.new()
	home.text = "Home"
	home.pressed.connect(func(): home_pressed.emit())
	over_column.add_child(home)


## The card that tells a player what a new enemy does, under the top line.
## Tapping it puts it away. A banner like Wave Info, kept between uses.
func _build_first_sight() -> void:
	_sight = Overlay.new(Overlay.Kind.BANNER, true, true)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	_sight.column.add_child(line)
	_sight_sign = Label.new()
	_sight_sign.add_theme_font_override("font", Palette.weight(Palette.NUMBER_FONT, 700))
	_sight_sign.add_theme_font_size_override("font_size", 26)
	line.add_child(_sight_sign)
	_sight_text = Label.new()
	_sight_text.add_theme_font_size_override("font_size", 13)
	_sight_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sight_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sight_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(_sight_text)
	add_child(_sight)


## Shows the card when one of ours first comes on a wave past the player's
## best, once a run, and puts it away after FIRST_SIGHT_SECONDS.
func _first_sight(delta: float) -> void:
	if _sight.visible:
		_sight_left -= delta
		if _sight_left <= 0.0:
			_sight.dismiss()
	# One card at a time: two new kinds meeting the player at once each get
	# theirs, the second once the first has gone. The banner is shared with
	# Wave Info and a held upgrade, which the player opened, so they are
	# never pushed off by a card they didn't ask for.
	if sim.wave <= workshop.best_wave or Overlay.current(self, Overlay.Kind.BANNER) != null:
		return
	for kind in FIRST_SIGHT:
		if kind in _sighted or not sim.enemies.any(func(enemy): return enemy.kind == kind):
			continue
		_sighted.append(kind)
		_sight_sign.text = FIRST_SIGHT[kind].sign
		_sight_sign.add_theme_color_override("font_color", ArenaView.LOOKS[kind].colour)
		_sight_text.text = FIRST_SIGHT[kind].text
		_sight_left = FIRST_SIGHT_SECONDS
		_sight.show_over(self)
		return


## The wave's number and its bar on one slim line. A tap anywhere on it
## opens Wave Info, as The Tower's wave readout does.
func _wave_line() -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	line.mouse_filter = Control.MOUSE_FILTER_STOP
	_wave_title = Label.new()
	_wave_title.text = "Wave 1  ›"
	_wave_title.add_theme_font_override("font", Palette.weight(Palette.WORD_FONT, 500))
	_wave_title.add_theme_font_size_override("font_size", 13)
	_wave_title.add_theme_color_override("font_color", Palette.SOFT)
	_wave_title.mouse_filter = Control.MOUSE_FILTER_PASS
	line.add_child(_wave_title)
	_wave_bar = _bar(WAVE_BAR)
	_wave_bar.custom_minimum_size = Vector2(0, 3)
	_wave_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wave_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_wave_bar.max_value = 1.0
	_wave_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	_wave_fill = _wave_bar.get_theme_stylebox("fill") as StyleBoxFlat
	line.add_child(_wave_bar)
	line.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and sim != null:
			if _wave_info.visible:
				_wave_info.dismiss()
			else:
				_wave_info.show_for(sim)
				_wave_info.show_over(self))
	return line


## An upgrade tile held in battle: its card, a banner so the run goes on
## beneath it, with the same numbers the tile shows and what one more level
## would give.
func _show_held(id: String) -> void:
	if sim == null:
		return
	var card := Overlay.new(Overlay.Kind.BANNER)
	_held_card = card
	_held_id = id
	_held_info = UpgradeInfo.new(card, id, Palette.ACCENT)
	card.closed.connect(func():
		if _held_card == card:
			_held_card = null
			_held_info = null)
	_update_held()
	card.show_over(self)


func _update_held() -> void:
	var maxed := sim.at_max(_held_id)
	_held_info.update(sim.level(_held_id), TowerData.max_level(_held_id), Palette.row_value(_held_id, sim.stat(_held_id)),
		"" if maxed else Palette.row_value(_held_id, sim.stat_with(_held_id, 1)),
		"" if maxed else UpgradePanel.price_symbol(sim) + Palette.money(sim.price(_held_id), true))


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


func _margined(child: Control, bottom: int = 0) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(child)
	return margin
