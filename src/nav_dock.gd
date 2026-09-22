class_name NavDock
extends Control

## The bottom navigation strip. It carries only what can be acted on between
## runs (D016): the run itself, the Workshop, and everything rarer behind MORE.
## Labs, Insight and Prestige left it for the Knowledge sheet, which the
## Knowledge chip on the run screen opens.

signal tab_selected(tab_id: String)

const TAB_ORDER: Array[String] = ["number", "workshop", "settings"]
const MUTED := Color(0.925, 0.925, 0.918, 0.35)
const DIVIDER := Color(0.925, 0.925, 0.918, 0.08)
const BAR_HEIGHT := 92.0
const ICON_SIZE := 21.0

var _icon_kind := {
	"number": IconGlyph.Kind.HOME,
	"workshop": IconGlyph.Kind.GEAR,
	"settings": IconGlyph.Kind.SLIDERS,
}
# One accent for every tab: per-tab hues were HUD noise, and the active tab is
# already unambiguous from colour against the muted rest.
const ACCENT := Color("8fbfa8")
var _accent := {
	"number": ACCENT,
	"workshop": ACCENT,
	"settings": ACCENT,
}
var _buttons: Dictionary = {}
var _icons: Dictionary = {}
var _labels: Dictionary = {}
var _locks: Dictionary = {}

## A flush bar rather than a floating pill: a pill is an app pattern, and it
## competed with the stage for attention. Colour alone marks the active tab,
## so no tab needs a box of its own.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, BAR_HEIGHT)
	var divider := ColorRect.new()
	divider.color = DIVIDER
	divider.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	divider.custom_minimum_size = Vector2(0, 1)
	divider.offset_bottom = 1
	add_child(divider)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.offset_top = 14
	row.offset_bottom = -30
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	for tab_id in TAB_ORDER:
		row.add_child(_make_button(tab_id))

func _make_button(tab_id: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = tab_id.capitalize()
	button.pressed.connect(func(): tab_selected.emit(tab_id))

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	button.add_child(column)

	var icon_wrap := CenterContainer.new()
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon_wrap)
	var icon := IconGlyph.new(_icon_kind[tab_id], MUTED, ICON_SIZE)
	icon_wrap.add_child(icon)

	var label := Label.new()
	label.text = _tab_label(tab_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", MUTED)
	column.add_child(label)

	var lock := IconGlyph.new(IconGlyph.Kind.LOCK, MUTED, 11.0)
	lock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lock.position += Vector2(-6, 0)
	lock.visible = false
	button.add_child(lock)

	_buttons[tab_id] = button
	_icons[tab_id] = icon
	_labels[tab_id] = label
	_locks[tab_id] = lock
	return button

func _tab_label(tab_id: String) -> String:
	match tab_id:
		"settings":
			return "MORE"
		"number":
			return "RUN"
		_:
			return tab_id.to_upper()

## unlocked maps each tab id to whether it can be opened; active_id is the
## tab currently showing (or "settings" while the sheet is open).
func update_state(active_id: String, unlocked: Dictionary) -> void:
	for tab_id in TAB_ORDER:
		var button: Button = _buttons[tab_id]
		var icon: IconGlyph = _icons[tab_id]
		var label: Label = _labels[tab_id]
		var lock: IconGlyph = _locks[tab_id]
		var is_locked := not bool(unlocked.get(tab_id, true))
		var is_active := tab_id == active_id and not is_locked
		var colour: Color = _accent[tab_id] if is_active else MUTED
		icon.set_glyph_color(colour)
		label.add_theme_color_override("font_color", colour)
		lock.visible = is_locked
		button.modulate.a = 0.5 if is_locked else 1.0
