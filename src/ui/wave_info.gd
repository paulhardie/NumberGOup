extends PanelContainer
## Wave Info (D115), as The Tower's: opened from the wave readout, it shows
## the wave's spawn rate, what it has sent against what it rolled, the field
## against its caps, and each kind's health, attack, speed and chance to
## spawn. BattleSim.wave_info has the numbers; this only lays them out.

const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")
const ArenaView = preload("res://src/ui/arena_view.gd")

const NAMES := {"basic": "Basic", "fast": "Fast", "tank": "Tank", "ranged": "Ranged", "protector": "Protector", "boss": "Boss",
	"divider": "Divider", "vampire": "Vampire", "ray": "Ray", "scatter": "Scatter"}
const COLUMNS := ["", "HP", "Atk", "m/s", "Chance"]

var _title: Label
var _spawns: Label
var _field: Label
var _grid: GridContainer
var _mono := Palette.weight(Palette.NUMBER_FONT, 400)


func _init() -> void:
	add_theme_stylebox_override("panel", Palette.panel_box())
	# Across the screen under the top bar, 16 points in from each side, so it
	# fits a phone.
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_left = 16
	offset_right = -16
	offset_top = 72
	visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	var close := Palette.pill("Close", Palette.SOFT, null, 30)
	close.pressed.connect(func(): visible = false)
	head.add_child(close)
	_spawns = _label(12, Palette.TEXT)
	_spawns.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_spawns)
	_field = _label(11, Palette.MUTED)
	_field.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_field)
	column.add_child(Palette.hairline())
	_grid = GridContainer.new()
	_grid.columns = COLUMNS.size()
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 6)
	column.add_child(_grid)


## Fills it from `sim`: called each frame while it shows.
func show_for(sim: BattleSim) -> void:
	var info := sim.wave_info()
	_title.text = "Wave %d · Tier %d" % [info.wave, info.tier]
	_spawns.text = "Spawn rate %d%% every %s s, %d%% doubled: about %d a wave\nThis wave: %d of %d spawned%s" % [
		roundi(info.spawn_rate), String.num(float(info.roll_seconds), 3), roundi(info.double_spawn), roundi(info.expected),
		info.spawned, info.due, ", %d turned away by a full field" % info.missed if int(info.missed) > 0 else ""]
	_field.text = "On the field: %d / %d normal · %d / %d elite · %d / %d boss" % [info.normal, info.normal_cap, info.elites, info.elite_cap,
		info.bosses, info.boss_cap]
	if info.tier > 1:
		_field.text += "\nProtector shield %s m" % String.num(float(info.protector_radius), 1)
	var cells: Array[String] = []
	cells.assign(COLUMNS)
	var colours: Array[Color] = []
	for header in COLUMNS:
		colours.append(Palette.MUTED)
	for row in info.rows:
		cells.append_array([NAMES.get(row.kind, row.kind), Palette.amount(float(row.health)), Palette.amount(float(row.attack)) if row.kind != "divider" else "÷ a share",
			String.num(float(row.speed), 1), _chance(row)])
		var colour: Color = ArenaView.LOOKS[row.kind].colour if ArenaView.LOOKS.has(row.kind) else Palette.TEXT
		colours.append_array([colour, Palette.TEXT, Palette.TEXT, Palette.TEXT, Palette.SOFT])
	_fill(cells, colours)


## Its chance, and what else it needs saying: a boss's or a shut Protector's
## wait in waves, an elite's chance of a second.
static func _chance(row: Dictionary) -> String:
	var chance := float(row.chance)
	var text := "%d%%" % roundi(chance) if chance >= 1.0 or chance == 0.0 else "%s%%" % String.num(chance, 1)
	if int(row.waits) > 0:
		text += ", in %d" % int(row.waits) if row.kind == "boss" else ", shut %d" % int(row.waits)
	if float(row.second) > 0.0:
		text += " +%d%%" % roundi(float(row.second))
	return text


## Reuses the grid's labels, adding or dropping them only when the row count changes.
func _fill(cells: Array[String], colours: Array[Color]) -> void:
	while _grid.get_child_count() < cells.size():
		_grid.add_child(_label(11, Palette.TEXT))
	while _grid.get_child_count() > cells.size():
		var extra := _grid.get_child(_grid.get_child_count() - 1)
		_grid.remove_child(extra)
		extra.queue_free()
	for index in range(cells.size()):
		var label: Label = _grid.get_child(index)
		label.text = cells[index]
		label.add_theme_color_override("font_color", colours[index])


func _label(font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", _mono)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", colour)
	return label
