extends Control
## A card laid over a screen: the one primitive every menu and pop-up is built
## from (D151; docs/UI_POPUPS.md has the rules). A screen makes one with
## `Overlay.new()`, puts its content in `column` (or with the helpers below),
## and `show_over(self)`s it. Two kinds:
## - SHEET: centred over a shade that blocks the screen, for something the
##   player answers or reads on its own (Settings, Milestones, a card's
##   details, what a group opened).
## - BANNER: pinned under the top bar with nothing else blocked, so a run goes
##   on beneath it (Wave Info, a new enemy's card, an upgrade held in battle).
## A host shows one SHEET and one BANNER at a time: showing another of the same
## kind replaces it, and a SHEET always sits above a BANNER. Nothing here pauses
## the game, and what a card says is the screen's to decide.

const Palette = preload("res://src/ui/palette.gd")

enum Kind { SHEET, BANNER }

const CARD_WIDTH := 300.0
## Wide enough for a paragraph to wrap inside a SHEET's card.
const TEXT_WIDTH := 260.0
const SHADE := Color(0, 0, 0, 0.6)
## A BANNER's gap from the screen's sides, and its top edge: just under the
## battle's top bar.
const BANNER_SIDE := 16
const BANNER_TOP := 68
const META := "overlay_kind"

## The card was closed, by the player or by `dismiss`.
signal closed

var kind := Kind.SHEET
## A SHEET: a tap on the shade, or Escape, closes it. A BANNER: a tap on the
## card does. Off for a card that must be answered or has a Close of its own.
var dismissable := true
## Kept, hidden, when closed, for a card that is filled and shown again;
## otherwise it is freed.
var keep := false
## Where the content goes.
var column: VBoxContainer
var _card: PanelContainer


func _init(of: Kind = Kind.SHEET, tap_closes: bool = true, retained: bool = false) -> void:
	kind = of
	dismissable = tap_closes
	keep = retained
	set_meta(META, int(kind))
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", Palette.panel_box())
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_card.add_child(column)
	if kind == Kind.SHEET:
		mouse_filter = Control.MOUSE_FILTER_STOP
		var shade := ColorRect.new()
		shade.color = SHADE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)
		var centre := CenterContainer.new()
		centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(centre)
		_card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
		centre.add_child(_card)
		gui_input.connect(_tapped)
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_card.set_anchors_preset(Control.PRESET_TOP_WIDE)
		_card.offset_left = BANNER_SIDE
		_card.offset_right = -BANNER_SIDE
		_card.offset_top = BANNER_TOP
		add_child(_card)
		_card.gui_input.connect(_tapped)


## The open card of `of` on `host`, or null. A card still waiting to be freed
## is hidden, so it doesn't count.
static func current(host: Node, of: Kind = Kind.SHEET) -> Control:
	for child in host.get_children():
		if child.has_meta(META) and child.get_meta(META) == int(of) and (child as Control).visible:
			return child
	return null


## Closes `host`'s open card of `of`, if any.
static func close_current(host: Node, of: Kind = Kind.SHEET) -> void:
	var open := current(host, of)
	if open != null:
		open.dismiss()


## Shows the card over `host`, replacing the one of its kind that was up.
func show_over(host: Control) -> void:
	var other := current(host, kind)
	if other != null and other != self:
		other.dismiss()
	if get_parent() != host:
		host.add_child(self)
	visible = true
	host.move_child(self, -1)
	if kind == Kind.BANNER:
		var sheet := current(host, Kind.SHEET)
		if sheet != null:
			host.move_child(sheet, -1)


func dismiss() -> void:
	if not visible:
		return
	visible = false
	closed.emit()
	if not keep:
		queue_free()


func _input(event: InputEvent) -> void:
	if kind == Kind.SHEET and dismissable and visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		dismiss()


func _tapped(event: InputEvent) -> void:
	if dismissable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dismiss()


## The heading line, with a Close pill beside it when asked.
func heading(words: String, with_close: bool = false) -> Label:
	var line := HBoxContainer.new()
	column.add_child(line)
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", 16)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(label)
	if with_close:
		var close := Palette.pill("Close", Palette.SOFT, null, 30)
		close.pressed.connect(dismiss)
		line.add_child(close)
	return label


## A paragraph that wraps inside the card.
func text(words: String, tone: Color = Palette.SOFT, font_size: int = 12) -> Label:
	var label := Label.new()
	label.text = words
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tone)
	column.add_child(label)
	return label


## A button across the card. A press closes the card first, unless `then_close`
## is off, and then runs `on_press`, so whatever it does (leave the screen,
## change a setting) meets a screen with nothing over it.
func action(words: String, tone: Color, on_press: Callable, then_close: bool = true, height: int = 38) -> Button:
	var button := Palette.pill(words, tone, null, height)
	button.pressed.connect(func():
		if then_close:
			dismiss()
		on_press.call())
	column.add_child(button)
	return button


## The quiet button at a card's foot that just closes it.
func done(words: String = "Close") -> Button:
	return action(words, Palette.SOFT, func(): pass, true, 36)


func rule() -> void:
	column.add_child(Palette.hairline())
