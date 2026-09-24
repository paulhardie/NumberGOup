class_name NavDock
extends Control

## The bottom navigation strip, laid out as The Tower's (D048): the battle
## hub, then each permanent system a player returns to between runs, with
## settings and stats behind MORE. A seat for a system that is not built yet
## shows SOON rather than hiding, so the bar's shape does not move when it
## lands. Insight and Prestige stay in the Knowledge sheet (D016).

signal tab_selected(tab_id: String)

const TAB_ORDER: Array[String] = ["number", "workshop", "cards", "ultimates", "labs", "settings"]
## Seats held for systems still to be built.
const SOON_TABS: Array[String] = ["ultimates"]
const MUTED := Color("8b8c88")
const ACTIVE := Color("ececea")
## A seat for a system not built yet: present, but plainly not pressable.
const SOON_COLOUR := Color("3a3b3e")
const DIVIDER := Color("1c1d1f")
const BAR_HEIGHT := 92.0
const ICON_SIZE := 21.0

var _icon_kind := {
	"number": IconGlyph.Kind.HOME,
	"workshop": IconGlyph.Kind.GEAR,
	"cards": IconGlyph.Kind.DICE,
	"ultimates": IconGlyph.Kind.SPARKLE,
	"labs": IconGlyph.Kind.FLASK,
	"settings": IconGlyph.Kind.SLIDERS,
}
# One accent for every tab: per-tab hues were HUD noise.
const ACCENT := Color("8fbfa8")
var _buttons: Dictionary = {}
var _icons: Dictionary = {}
var _labels: Dictionary = {}
var _locks: Dictionary = {}
var _soon_tags: Dictionary = {}
var _marks: Dictionary = {}

## A flush bar rather than a floating pill: a pill is an app pattern, and it
## competed with the stage for attention. The active tab is lit and carries a
## short accent bar at the bar's top edge (D049), so no tab needs a box.
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
	row.offset_left = 4
	row.offset_right = -4
	row.offset_top = 1
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
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", MUTED)
	column.add_child(label)

	var mark := ColorRect.new()
	mark.color = ACCENT
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.anchor_left = 0.5
	mark.anchor_right = 0.5
	mark.offset_left = -10
	mark.offset_right = 10
	mark.offset_top = -1
	mark.offset_bottom = 1
	mark.visible = false
	button.add_child(mark)

	var lock := IconGlyph.new(IconGlyph.Kind.LOCK, MUTED, 11.0)
	lock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lock.position += Vector2(-6, 0)
	lock.visible = false
	button.add_child(lock)

	var soon := Label.new()
	soon.text = "SOON"
	soon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	soon.add_theme_font_size_override("font_size", 7)
	soon.add_theme_color_override("font_color", SOON_COLOUR)
	soon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	soon.offset_left = 8
	soon.offset_top = 0
	soon.visible = SOON_TABS.has(tab_id)
	button.add_child(soon)

	_buttons[tab_id] = button
	_icons[tab_id] = icon
	_labels[tab_id] = label
	_locks[tab_id] = lock
	_soon_tags[tab_id] = soon
	_marks[tab_id] = mark
	return button

func _tab_label(tab_id: String) -> String:
	match tab_id:
		"settings":
			return "More"
		"number":
			return "Battle"
		_:
			return tab_id.capitalize()

## unlocked maps each tab id to whether it can be opened; active_id is the
## tab or sheet currently showing ("settings", "labs" or "cards" for a sheet).
func update_state(active_id: String, unlocked: Dictionary) -> void:
	for tab_id in TAB_ORDER:
		var button: Button = _buttons[tab_id]
		var icon: IconGlyph = _icons[tab_id]
		var label: Label = _labels[tab_id]
		var lock: IconGlyph = _locks[tab_id]
		var is_soon := SOON_TABS.has(tab_id)
		var is_locked := not is_soon and not bool(unlocked.get(tab_id, true))
		var is_active := tab_id == active_id and not is_locked
		var colour: Color = ACTIVE if is_active else (SOON_COLOUR if is_soon else MUTED)
		icon.set_glyph_color(colour)
		label.add_theme_color_override("font_color", colour)
		(_marks[tab_id] as ColorRect).visible = is_active
		lock.visible = is_locked
		button.modulate.a = 0.5 if is_locked else 1.0
