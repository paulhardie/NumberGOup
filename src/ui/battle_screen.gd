extends Control
## The battle: the arena on top, the tower's and the wave's readouts below it,
## then the tower's stats. It runs the sim at the chosen game speed and draws
## it; every rule lives in BattleSim.

const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")
const ArenaView = preload("res://src/ui/arena_view.gd")

## Game speeds, for testing a run quickly (docs/REBUILD_SPEC.md, "Dev only").
const SPEEDS := [1.0, 2.0, 5.0]
## At most this many ticks a frame, so a slow frame can't snowball.
const MAX_TICKS_PER_FRAME := 400

const STAT_ROWS := [
	["Damage", "damage"],
	["Attack Speed", "attack_speed"],
	["Critical Chance", "critical_chance"],
	["Critical Factor", "critical_factor"],
	["Range", "range"],
	["Health Regen", "health_regen"],
]

var sim: BattleSim
var _speed_index := 0
var _carry := 0.0

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
var _stat_values: Dictionary = {}
var _over: PanelContainer
var _over_text: Label


func _ready() -> void:
	theme = Palette.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	start_run(randi())


func start_run(seed_value: int) -> void:
	sim = BattleSim.new(seed_value)
	sim.record_events = true
	_arena.sim = sim
	_carry = 0.0
	_over.visible = false


func _process(delta: float) -> void:
	if sim == null:
		return
	_carry += delta * float(SPEEDS[_speed_index])
	var ticks := 0
	while sim.alive and _carry >= BattleSim.TICK and ticks < MAX_TICKS_PER_FRAME:
		sim.step()
		_carry -= BattleSim.TICK
		ticks += 1
	if ticks == MAX_TICKS_PER_FRAME:
		_carry = 0.0
	_arena.absorb(sim.events, delta)
	sim.events.clear()
	_arena.queue_redraw()
	_refresh()
	if not sim.alive and not _over.visible:
		_show_run_over()


func _refresh() -> void:
	_cash.text = "$ " + Palette.number(sim.cash)
	_coins.text = "● " + Palette.number(sim.coins)
	_tower_damage.text = "Damage " + Palette.number(sim.stat("damage"))
	_tower_regen.text = "Regen %.2f/s" % sim.stat("health_regen")
	_health_bar.max_value = sim.max_health()
	_health_bar.value = sim.health
	_health_text.text = "%s / %s" % [Palette.number(sim.health), Palette.number(sim.max_health())]
	_wave_title.text = "Wave %d" % sim.wave
	_enemy_attack.text = "Attack " + Palette.number(TowerData.enemy_attack(sim.wave, "basic"))
	_enemy_health.text = "Health " + Palette.number(TowerData.enemy_health(sim.wave, "basic"))
	_wave_bar.value = sim.wave_clock / TowerData.wave_seconds()
	for row in STAT_ROWS:
		_stat_values[row[1]].text = _stat_text(row[1])


func _stat_text(id: String) -> String:
	var value := sim.stat(id)
	match id:
		"attack_speed":
			return "%.2f" % value
		"critical_chance":
			return "%.2f%%" % (value * 100.0)
		"critical_factor":
			return "×%.2f" % value
		"range":
			return "%s m" % Palette.number(value)
		"health_regen":
			return "%.2f/s" % value
	return Palette.number(value)


func _show_run_over() -> void:
	var cause := {"basic": "a basic enemy", "fast": "a fast enemy", "tank": "a tank", "ranged": "a ranged enemy", "boss": "a boss"}
	_over_text.text = "Destroyed on wave %d by %s\n%s of game time · %d kills\nCash earned $%s · Coins %s" % [
		sim.wave, cause.get(sim.killed_by, sim.killed_by), Palette.clock(sim.time), sim.kills,
		Palette.number(sim.cash_earned), Palette.number(sim.coins)]
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

	_speed_button = Button.new()
	_speed_button.text = "×1"
	_speed_button.add_theme_font_override("font", Palette.NUMBER_FONT)
	_speed_button.pressed.connect(_cycle_speed)
	_speed_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_speed_button.position = Vector2(-72, 14)
	_arena.add_child(_speed_button)

	var readouts := HBoxContainer.new()
	readouts.add_theme_constant_override("separation", 8)
	column.add_child(_margined(readouts))
	readouts.add_child(_tower_panel())
	readouts.add_child(_wave_panel())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for row in STAT_ROWS:
		grid.add_child(_stat_card(row[0], row[1]))
	column.add_child(_margined(grid, 16))

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
	var over_title := Label.new()
	over_title.text = "Tower destroyed"
	over_title.add_theme_font_size_override("font_size", 20)
	over_title.add_theme_color_override("font_color", Palette.WARNING)
	over_column.add_child(over_title)
	_over_text = Label.new()
	_over_text.add_theme_color_override("font_color", Palette.MUTED)
	over_column.add_child(_over_text)
	var again := Button.new()
	again.text = "Battle again"
	again.pressed.connect(func(): start_run(randi()))
	over_column.add_child(again)


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


func _stat_card(title: String, id: String) -> PanelContainer:
	var panel := _panel()
	var line := HBoxContainer.new()
	panel.add_child(line)
	var name_label := Label.new()
	name_label.text = title
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 13)
	line.add_child(name_label)
	var value := _number_label(14, Palette.TEXT)
	line.add_child(value)
	_stat_values[id] = value
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
