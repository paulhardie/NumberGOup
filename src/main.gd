extends Control
## Number Go Up, rebuilt as The Tower first (docs/REBUILD_SPEC.md). Switches
## between the home screen, the battle and the Workshop, and saves the
## Workshop: after every purchase, when a run ends, every AUTOSAVE_SECONDS of
## battle (a run's Coins go into the Workshop as they're earned), and when
## the window closes or loses focus. Every run and Workshop purchase also goes
## into the activity log, which Home exports as a report (D077).

const Save = preload("res://src/tower/save.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const HomeScreen = preload("res://src/ui/home_screen.gd")
const BattleScreen = preload("res://src/ui/battle_screen.gd")
const WorkshopScreen = preload("res://src/ui/workshop_screen.gd")

const AUTOSAVE_SECONDS := 20.0

var workshop: Workshop
var _screen: Control


func _ready() -> void:
	workshop = Save.load_workshop()
	var autosave := Timer.new()
	autosave.wait_time = AUTOSAVE_SECONDS
	autosave.timeout.connect(func():
		if _screen is BattleScreen:
			_save())
	add_child(autosave)
	autosave.start()
	_show_home()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if workshop != null:
			_save()
	# A run closed mid-way still goes in the log, marked as closed.
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _screen is BattleScreen and _screen.sim != null and _screen.sim.alive:
		_log_run(_screen)


func _save() -> void:
	Save.save_workshop(workshop)


func _show_home() -> void:
	var home := HomeScreen.new()
	home.workshop = workshop
	home.battle_pressed.connect(_show_battle)
	home.workshop_pressed.connect(_show_workshop)
	home.export_pressed.connect(func():
		var result := ActivityLog.export_report(workshop.to_dict())
		home.show_exported(result)
		if not result.is_empty():
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(String(result.path))))
	_swap(home)


func _show_battle() -> void:
	var battle := BattleScreen.new()
	battle.workshop = workshop
	battle.run_finished.connect(func():
		_log_run(battle)
		_save())
	battle.home_pressed.connect(_show_home)
	_swap(battle)


func _show_workshop() -> void:
	var shop := WorkshopScreen.new()
	shop.workshop = workshop
	shop.changed.connect(_save)
	shop.activity.connect(func(entry): ActivityLog.append(entry))
	shop.home_pressed.connect(_show_home)
	_swap(shop)


## Logs a battle's run once, whether it ended or the window closed on it.
func _log_run(battle: BattleScreen) -> void:
	if not battle.has_meta("logged"):
		battle.set_meta("logged", true)
		ActivityLog.append(battle.report())


func _swap(next: Control) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = next
	add_child(next)
