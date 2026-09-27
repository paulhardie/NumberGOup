extends Control
## Number Go Up, rebuilt as The Tower first (docs/REBUILD_SPEC.md). Switches
## between the home screen, the battle and the Workshop, and saves the
## Workshop and any run in progress: after every purchase, when a run ends,
## every AUTOSAVE_SECONDS of battle (a run's Coins go into the Workshop as
## they're earned), and when the window closes or loses focus. A game closed
## mid-run opens back into that run, as The Tower does (D078). Every run and
## Workshop purchase also goes into the activity log, which Home exports as a
## report (D077). The player's settings live in their own file (D088), and
## the generative music (D092) plays across every screen.

const Save = preload("res://src/tower/save.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const HomeScreen = preload("res://src/ui/home_screen.gd")
const BattleScreen = preload("res://src/ui/battle_screen.gd")
const WorkshopScreen = preload("res://src/ui/workshop_screen.gd")
const Settings = preload("res://src/settings.gd")
const AmbientMusic = preload("res://src/ui/ambient_music.gd")

const AUTOSAVE_SECONDS := 20.0

## Where the game saves and logs; the tests point these at their own files.
var save_path := Save.PATH
var log_path := ActivityLog.PATH
var settings_path := Settings.PATH
var workshop: Workshop
var settings := Settings.new()
## The music, playing across every screen (D092).
var music := AmbientMusic.new()
var _screen: Control


func _ready() -> void:
	workshop = Save.load_workshop(save_path)
	settings.read(settings_path)
	music.set_playing(settings.music)
	add_child(music)
	var autosave := Timer.new()
	autosave.wait_time = AUTOSAVE_SECONDS
	autosave.timeout.connect(func():
		if _screen is BattleScreen:
			_save())
	add_child(autosave)
	autosave.start()
	var saved := Save.load_run(save_path)
	if saved.is_empty():
		_show_home()
	else:
		_show_battle(saved)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if workshop != null:
			_save()


## The run in progress goes in the same write as the Workshop, so the Coins it
## has banked and its record of them always agree.
func _save() -> void:
	var run := {}
	if _screen is BattleScreen:
		run = _screen.run_state()
	Save.save_workshop(workshop, save_path, run)


func _show_home() -> HomeScreen:
	var home := HomeScreen.new()
	home.workshop = workshop
	home.settings = settings
	home.settings_changed.connect(func():
		music.set_playing(settings.music)
		settings.write(settings_path))
	home.test_coins_pressed.connect(func(amount: float):
		workshop.add_coins(amount)
		# Logged, so a report never mistakes free Coins for earned ones.
		ActivityLog.append({"kind": "test_coins", "amount": amount, "coins_left": workshop.coins}, log_path)
		_save())
	home.reset_pressed.connect(_reset_progress)
	home.battle_pressed.connect(_show_battle)
	home.workshop_pressed.connect(_show_workshop)
	home.export_pressed.connect(func():
		var result := ActivityLog.export_report(workshop.to_dict(), log_path)
		home.show_exported(result)
		if not result.is_empty():
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(String(result.path))))
	_swap(home)
	return home


## Testing (D097): back to a fresh Workshop, as a new player has. The log
## keeps what was wiped, so the reports still add up; settings stay.
func _reset_progress() -> void:
	ActivityLog.append({"kind": "progress_reset", "workshop": workshop.to_dict()}, log_path)
	workshop = Workshop.new()
	_save()
	_show_home().show_note("Progress reset: a fresh Workshop.")


## A new run, or the saved one to resume.
func _show_battle(saved: Dictionary = {}) -> void:
	var battle := BattleScreen.new()
	battle.workshop = workshop
	battle.resume = saved
	battle.resume_failed.connect(_resume_failed)
	battle.run_finished.connect(func():
		_log_run(battle)
		_save())
	battle.home_pressed.connect(_show_home)
	battle.digit_reached.connect(func(_power: int): music.chime())
	_swap(battle)


func _show_workshop() -> void:
	var shop := WorkshopScreen.new()
	shop.workshop = workshop
	shop.changed.connect(_save)
	shop.activity.connect(func(entry): ActivityLog.append(entry, log_path))
	shop.home_pressed.connect(_show_home)
	_swap(shop)


## A saved run that can't be brought back, because the game updated since or
## the record is damaged: it ends at its saved wave, keeping the Coins it had
## already banked.
func _resume_failed(saved: Dictionary, reason: String) -> void:
	var result = saved.get("result", {})
	var wave = result.get("wave", 0) if result is Dictionary else 0
	# A damaged record can hold anything here.
	var reached := int(wave) if (wave is float or wave is int) and is_finite(float(wave)) and float(wave) >= 0.0 else 0
	var peak = result.get("peak_number", 0.0) if result is Dictionary else 0.0
	for milestone in workshop.finish_run(reached, float(peak) if (peak is float or peak is int) and is_finite(float(peak)) and float(peak) >= 0.0 else 0.0):
		ActivityLog.append({"kind": "milestone", "number": milestone.number, "coins": milestone.coins}, log_path)
	var entry := saved.duplicate(true)
	entry["kind"] = "run"
	entry["resume_failed"] = reason
	ActivityLog.append(entry, log_path)
	var why := "couldn't carry over to this version of the game" if reason == "changed" else "couldn't be read"
	_show_home().show_note("Your run at wave %d %s, so it ended there. Its Coins are kept." % [reached, why])
	_save()


## Logs a run as it ends. A run the window closes on is saved and resumed
## instead, so each run is logged once (D078).
func _log_run(battle: BattleScreen) -> void:
	ActivityLog.append(battle.report(), log_path)
	# Logged apart, so a report never counts a milestone's Coins as earned (D107).
	for milestone in battle.milestones:
		ActivityLog.append({"kind": "milestone", "number": milestone.number, "coins": milestone.coins}, log_path)


func _swap(next: Control) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = next
	add_child(next)
