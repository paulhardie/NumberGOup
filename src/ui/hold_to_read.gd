extends Node
## Tap or hold on one control (D151). A tap does what the control always did.
## A hold, kept down for HOLD_SECONDS without drifting, reads the control
## instead (opens its info), and the lift that follows does nothing, so
## reading an upgrade never buys it.
##
## It listens to the control's raw mouse input, which a touch arrives as too,
## and not to a Button's own signals: a disabled button, the one a player most
## wants explained, still reports its input, and a plain panel can be held
## the same way. Attach it with `HoldToRead.attach`; it lives under the control
## and goes with it.

## How long a press must stay down to be a hold. Android's long-press is 0.4 s
## and iOS's 0.5 s.
const HOLD_SECONDS := 0.45
## How far a press may drift, in canvas points, and still be a hold, or on a
## control that isn't a button, a tap; further it is a drag (a list being
## scrolled). A canvas point is about an iPhone's point, and iOS allows 10.
const SLOP := 10.0

var _on_hold: Callable
var _on_tap: Callable
var _pressing := false
var _origin := Vector2.ZERO
var _down_for := 0.0
## What the press that just ended turned out to be. A button's `pressed` comes
## after its release input, so these outlive the release until the frame ends.
var _fired := false
var _dragged := false


## Gives `control` a hold (`on_hold`) and a tap (`on_tap`). A button's tap is
## its `pressed`, so a keyboard or test press still reaches it; any other
## control taps when a press lifts on it.
static func attach(control: Control, on_hold: Callable, on_tap: Callable = Callable()) -> Node:
	var gesture := new()
	gesture._on_hold = on_hold
	gesture._on_tap = on_tap
	control.add_child(gesture)
	control.gui_input.connect(gesture._input_on)
	control.visibility_changed.connect(gesture._cancel)
	if control is BaseButton:
		(control as BaseButton).pressed.connect(gesture._button_tapped)
	return gesture


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if not _pressing:
		return
	_down_for += delta
	if _down_for >= HOLD_SECONDS and not _fired and not _dragged:
		_fired = true
		set_process(false)
		_on_hold.call()


func _input_on(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin(event.position)
		else:
			_end(event.position)
	elif event is InputEventMouseMotion and _pressing and event.position.distance_to(_origin) > SLOP:
		_dragged = true
		set_process(false)


func _begin(at: Vector2) -> void:
	_pressing = true
	_origin = at
	_down_for = 0.0
	_fired = false
	_dragged = false
	set_process(true)


func _end(at: Vector2) -> void:
	if not _pressing:
		return
	_pressing = false
	set_process(false)
	var control := get_parent() as Control
	var tapped := not _fired and not _dragged and at.distance_to(_origin) <= SLOP and Rect2(Vector2.ZERO, control.size).has_point(at)
	if tapped and not (control is BaseButton) and _on_tap.is_valid():
		_on_tap.call()
	# Cleared once the release has been fully handled, so the button's own
	# `pressed` (which follows it) still sees what this press was.
	_forget.call_deferred()


func _forget() -> void:
	_fired = false
	_dragged = false


func _button_tapped() -> void:
	if _fired:
		return
	if _on_tap.is_valid():
		_on_tap.call()


func _cancel() -> void:
	_pressing = false
	set_process(false)
