class_name NavDock
extends Control

## The floating bottom icon dock: one shared, reusable strip of five circular
## buttons that replaces the old text tab bar plus the separate MENU button.

signal tab_selected(tab_id: String)

const TAB_ORDER: Array[String] = ["number", "workshop", "labs", "cards", "settings"]
const MUTED := Color("8f9aac")
const BUTTON_SIZE := 52.0

var _icon_kind := {
	"number": IconGlyph.Kind.HOME,
	"workshop": IconGlyph.Kind.GEAR,
	"labs": IconGlyph.Kind.FLASK,
	"cards": IconGlyph.Kind.DIAMOND,
	"settings": IconGlyph.Kind.SLIDERS,
}
var _accent := {
	"number": Color("91f5c4"),
	"workshop": Color("91f5c4"),
	"labs": Color("7ec8ff"),
	"cards": Color("d9a5ff"),
	"settings": Color("f4f7fb"),
}
var _buttons: Dictionary = {}
var _icons: Dictionary = {}
var _locks: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, BUTTON_SIZE + 16)
	var wrap := CenterContainer.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)
	var pill := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.15, 0.94)
	style.border_color = Color(1, 1, 1, 0.07)
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(BUTTON_SIZE / 2.0 + 8.0))
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 16
	pill.add_theme_stylebox_override("panel", style)
	wrap.add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	pill.add_child(row)
	for tab_id in TAB_ORDER:
		row.add_child(_make_button(tab_id))

func _make_button(tab_id: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = tab_id.capitalize()
	button.add_theme_stylebox_override("normal", _bg_style(Color.TRANSPARENT, Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _bg_style(Color(1, 1, 1, 0.07), Color.TRANSPARENT))
	button.add_theme_stylebox_override("pressed", _bg_style(Color(1, 1, 1, 0.12), Color.TRANSPARENT))
	button.add_theme_stylebox_override("disabled", _bg_style(Color.TRANSPARENT, Color.TRANSPARENT))
	button.pressed.connect(func(): tab_selected.emit(tab_id))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)
	var icon := IconGlyph.new(_icon_kind[tab_id], MUTED, 22.0)
	center.add_child(icon)
	var lock := IconGlyph.new(IconGlyph.Kind.LOCK, MUTED, 11.0)
	lock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lock.position += Vector2(-2, -2)
	lock.visible = false
	button.add_child(lock)
	_buttons[tab_id] = button
	_icons[tab_id] = icon
	_locks[tab_id] = lock
	return button

func _bg_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2 if border != Color.TRANSPARENT else 0)
	style.set_corner_radius_all(int(BUTTON_SIZE / 2.0))
	return style

## unlocked maps each tab id to whether it can be opened; active_id is the
## tab currently showing (or "settings" while the sheet is open).
func update_state(active_id: String, unlocked: Dictionary) -> void:
	for tab_id in TAB_ORDER:
		var button: Button = _buttons[tab_id]
		var icon: IconGlyph = _icons[tab_id]
		var lock: IconGlyph = _locks[tab_id]
		var is_locked := not bool(unlocked.get(tab_id, true))
		var is_active := tab_id == active_id and not is_locked
		var accent: Color = _accent[tab_id]
		icon.set_glyph_color(accent if is_active else MUTED)
		lock.visible = is_locked
		button.modulate.a = 0.5 if is_locked else 1.0
		if is_active:
			button.add_theme_stylebox_override("normal", _bg_style(Color(accent.r, accent.g, accent.b, 0.16), accent))
		else:
			button.add_theme_stylebox_override("normal", _bg_style(Color.TRANSPARENT, Color.TRANSPARENT))
