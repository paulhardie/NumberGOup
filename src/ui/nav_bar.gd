extends HBoxContainer
## The bar along the bottom of Home and the Workshop, as The Tower has one:
## Battle (Home), the Workshop, and the screens the roadmap brings later (D079),
## shown locked with the version that brings them until they exist (D096).
## Each appears only when The Tower would show it (D125), so a new player
## isn't met with screens they can't use: the Workshop once the first run has
## ended, Cards once a run reaches wave 20 and Labs wave 30 (The Tower's
## milestones). When The Tower shows Weapons isn't known, so they wait until
## they're built. The battle itself has no bar; a run fills the screen.

const Palette = preload("res://src/ui/palette.gd")

## A screen that exists was chosen: "battle" (Home) or "workshop".
signal chosen(id: String)

## [id, name, the roadmap version that brings it, or "" for a screen that
## exists, and when it appears: the best wave a run must reach, AFTER_FIRST_RUN,
## or NOT_YET].
const ITEMS := [
	["battle", "Battle", "", 0],
	["workshop", "Workshop", "", AFTER_FIRST_RUN],
	["cards", "Cards", "1.1", 20],
	["labs", "Labs", "1.2", 30],
	["weapons", "Weapons", "1.3", NOT_YET],
]
const AFTER_FIRST_RUN := -1
const NOT_YET := 1 << 30
const HEIGHT := 64

## The screen this bar sits on, shown as chosen.
var current := "battle"
## id → Button, for the tests and for showing the current one.
var buttons := {}


## `runs` and `best_wave` are the Workshop's, and decide what shows.
func _init(on: String = "battle", runs: int = 0, best_wave: int = 0) -> void:
	current = on
	custom_minimum_size = Vector2(0, HEIGHT)
	add_theme_constant_override("separation", 0)
	for item in ITEMS:
		if shows(int(item[3]), runs, best_wave):
			add_child(_item(item[0], item[1], item[2]))


## Whether an item that appears at `from` shows yet.
static func shows(from: int, runs: int, best_wave: int) -> bool:
	return runs > 0 if from == AFTER_FIRST_RUN else best_wave >= from


func _item(id: String, name: String, version: String) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, HEIGHT)
	button.disabled = version != ""
	var here := id == current
	var fill := Palette.SURFACE if here else Color(0, 0, 0, 0)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = fill if state != "hover" or here else Color(1, 1, 1, 0.03)
		# The chosen screen carries a line of the accent along its top.
		box.border_color = Palette.ACCENT
		box.border_width_top = 2 if here else 0
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	var label := Label.new()
	label.text = name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Palette.TEXT if here else (Palette.SOFT if version == "" else Color(Palette.MUTED, 0.6)))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
	if version != "":
		# Locked: the roadmap version that brings it, small, under its name.
		var soon := Label.new()
		soon.text = version
		soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		soon.add_theme_font_override("font", Palette.NUMBER_FONT)
		soon.add_theme_font_size_override("font_size", 10)
		soon.add_theme_color_override("font_color", Color(Palette.MUTED, 0.6))
		soon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(soon)
	if version == "" and not here:
		button.pressed.connect(func(): chosen.emit(id))
	buttons[id] = button
	return button
