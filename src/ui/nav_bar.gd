extends HBoxContainer
## The bar along the bottom of Home and the Workshop, as The Tower has one:
## Battle (Home), the Workshop, and the screens the roadmap brings later (D079),
## shown locked with the version that brings them until they exist (D096).
## Each appears only when The Tower would show it (D125), so a new player
## isn't met with screens they can't use: the Workshop once the first run has
## ended, Cards once a run reaches wave 20 (built, D146) and Labs wave 30
## (The Tower's milestones). When The Tower shows Weapons isn't known, so they wait until
## they're built. The battle itself has no bar; a run fills the screen.

const Palette = preload("res://src/ui/palette.gd")
const Progression = preload("res://src/tower/progression.gd")

## A screen that exists was chosen: "battle" (Home), "workshop" or "cards".
signal chosen(id: String)

## [id, name, the roadmap version that brings it, or "" for a screen that
## exists]. Reveal points belong to the generated milestone table.
const ITEMS := [
	["battle", "Battle", ""],
	["workshop", "Workshop", ""],
	["cards", "Cards", ""],
	["labs", "Labs", "1.2"],
	["weapons", "Weapons", "1.3"],
]
## Each screen's glyph, from the game's own arithmetic rather than icon art
## (D138): play, add (the Workshop builds up), then the operators.
const GLYPHS := {"battle": "▶", "workshop": "+", "cards": "×", "labs": "÷", "weapons": "^"}
const HEIGHT := 76
const GLYPH_PX := 22

## The screen this bar sits on, shown as chosen.
var current := "battle"
## id → Button, for the tests and for showing the current one.
var buttons := {}


## Workshop-only callers retain their Tier 1 view; the real screens pass
## progression so another tier's best cannot reveal Tier 1's systems.
func _init(on: String = "battle", runs: int = 0, best_wave: int = 0, progression: Progression = null) -> void:
	current = on
	custom_minimum_size = Vector2(0, HEIGHT)
	add_theme_constant_override("separation", 0)
	for item in ITEMS:
		var shown := progression.unlocked(String(item[0])) if progression != null else Progression.revealed(String(item[0]), runs, {"1": {"reached": best_wave}})
		if shown:
			add_child(_item(item[0], item[1], item[2]))


func _item(id: String, name: String, version: String) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, HEIGHT)
	button.disabled = version != ""
	button.focus_mode = Control.FOCUS_NONE
	var here := id == current
	# A dock, not a tab bar: no filled tab. The chosen screen's glyph is lit
	# in the accent with a dot under it (D138).
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1, 0.03) if state == "hover" and not here else Color(0, 0, 0, 0)
		button.add_theme_stylebox_override(state, box)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	var tone: Color = Palette.ACCENT if here else (Palette.SOFT if version == "" else Color(Palette.MUTED, 0.45))
	var glyph := Label.new()
	glyph.text = GLYPHS.get(id, "·")
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.add_theme_font_override("font", Palette.weight(Palette.WORD_FONT, 500))
	glyph.add_theme_font_size_override("font_size", GLYPH_PX)
	glyph.add_theme_color_override("font_color", tone)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(glyph)
	var label := Label.new()
	# Locked: the roadmap version that brings it, beside its name.
	label.text = name if version == "" else "%s · %s" % [name, version]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Palette.TEXT if here else tone)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(4, 4)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dot.color = Palette.ACCENT if here else Color(0, 0, 0, 0)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(dot)
	if version == "" and not here:
		Palette.press(button)
		button.pressed.connect(func(): chosen.emit(id))
	buttons[id] = button
	return button
