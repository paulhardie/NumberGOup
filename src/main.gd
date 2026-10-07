extends Control
## Number Go Up, rebuilt as The Tower first (docs/REBUILD_SPEC.md). Switches
## between the home screen, the battle and the Workshop, and saves the
## permanent progress and any run in progress: after every purchase, when a run ends,
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
const CardsScreen = preload("res://src/ui/cards_screen.gd")
const Settings = preload("res://src/settings.gd")
const AmbientMusic = preload("res://src/ui/ambient_music.gd")
const Progression = preload("res://src/tower/progression.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const Palette = preload("res://src/ui/palette.gd")

const AUTOSAVE_SECONDS := 20.0
## How long a new screen takes to fade in (D138).
const SCREEN_FADE_SECONDS := 0.15

## Where the game saves and logs; the tests point these at their own files.
var save_path := Save.PATH
var log_path := ActivityLog.PATH
var settings_path := Settings.PATH
var workshop: Workshop
var progression: Progression
var settings := Settings.new()
## The music, playing across every screen (D092).
var music := AmbientMusic.new()
var _screen: Control
## The Coins the player had when they left Home for a new run, so Home can
## count up what the battle brought (D141); -1 when there's nothing to count.
var _coins_leaving_home := -1.0


func _ready() -> void:
	progression = Save.load_progress(save_path)
	workshop = progression.workshop
	progression.advance_time()
	settings.read(settings_path)
	music.set_playing(settings.music)
	add_child(music)
	var autosave := Timer.new()
	autosave.wait_time = AUTOSAVE_SECONDS
	autosave.timeout.connect(func():
		progression.advance_time()
		_save())
	add_child(autosave)
	autosave.start()
	var saved := Save.load_run(save_path)
	if saved.is_empty() or not progression.writable:
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
	if progression == null or not progression.writable: return
	progression.advance_time()
	var run := {}
	if _screen is BattleScreen:
		run = _screen.run_state()
	if not Save.save_progress(progression, save_path, run) and _screen is HomeScreen:
		_screen.show_note("Couldn't save progress. Check the save folder before closing the game.")


func _show_home() -> HomeScreen:
	Palette.number_cash = true
	var home := HomeScreen.new()
	home.workshop = workshop
	home.progression = progression
	home.settings = settings
	home.settings_changed.connect(func():
		music.set_playing(settings.music)
		settings.write(settings_path))
	home.test_coins_pressed.connect(func(amount: float):
		if not progression.writable: return
		workshop.add_coins(amount)
		# Logged, so a report never mistakes free Coins for earned ones.
		ActivityLog.append({"kind": "test_coins", "amount": amount, "coins_left": workshop.coins}, log_path)
		_save())
	home.reset_pressed.connect(_reset_progress)
	home.daily_pressed.connect(func():
		if progression.claim_daily():
			ActivityLog.append({"kind": "daily_gems", "gems": Progression.DAILY_GEMS, "day": progression.last_daily_day}, log_path)
			_save()
		home.refresh())
	# The first run's end brings the Workshop's welcome and its Coins (D125).
	if workshop.gift_waiting > 0.0:
		home.show_gift(workshop.gift_waiting)
		workshop.gift_waiting = 0.0
	home.battle_pressed.connect(_show_battle)
	home.workshop_pressed.connect(_show_workshop)
	home.cards_pressed.connect(_show_cards)
	home.test_gems_pressed.connect(func(amount: int):
		if not progression.writable: return
		progression.gems += amount
		ActivityLog.append({"kind": "test_gems", "amount": amount, "gems_left": progression.gems}, log_path)
		_save())
	home.export_pressed.connect(func():
		var result := ActivityLog.export_report(workshop.to_dict(), log_path, ActivityLog.REPORTS, progression.to_dict())
		home.show_exported(result)
		if not result.is_empty():
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(String(result.path))))
	_swap(home)
	if not progression.notice.is_empty(): home.show_note(progression.notice)
	return home


## Home after a battle, counting up the Coins it brought (D141).
func _show_home_after_battle() -> HomeScreen:
	var home := _show_home()
	if _coins_leaving_home >= 0.0:
		home.count_coins_from(_coins_leaving_home)
	_coins_leaving_home = -1.0
	return home


## Testing (D097): back to a fresh Workshop, as a new player has. The log
## keeps what was wiped, so the reports still add up; settings stay.
func _reset_progress() -> void:
	if not progression.writable: return
	ActivityLog.append({"kind": "progress_reset", "workshop": workshop.to_dict(), "progression": progression.to_dict()}, log_path)
	workshop = Workshop.new()
	progression = Progression.new(workshop)
	_save()
	_show_home().show_note("Progress reset: a fresh game.")


## A new run, or the saved one to resume.
func _show_battle(saved: Dictionary = {}) -> void:
	if not progression.writable: return
	progression.advance_time()
	# A resumed run's earlier Coins were banked in a past session, so only a
	# new run's are counted up (D141). Battle again keeps the first balance.
	if saved.is_empty() and _coins_leaving_home < 0.0:
		_coins_leaving_home = workshop.coins
	var battle := BattleScreen.new()
	battle.workshop = workshop
	battle.progression = progression
	battle.tuning = settings.run_tuning()
	battle.wave_reward.connect(func(reward):
		ActivityLog.append({"kind": "wave_milestone", "reward": reward}, log_path)
		_save())
	battle.resume = saved
	battle.resume_failed.connect(_resume_failed)
	battle.run_finished.connect(func():
		_log_run(battle)
		_save())
	battle.home_pressed.connect(_show_home_after_battle)
	battle.digit_reached.connect(func(_power: int): music.chime())
	# Battle again for the other battle (D167): a fresh screen laid out for it.
	battle.rebuild_requested.connect(func(): _show_battle())
	_swap(battle)


func _show_workshop() -> void:
	if not progression.writable: return
	Palette.number_cash = true
	var shop := WorkshopScreen.new()
	shop.workshop = workshop
	shop.progression = progression
	shop.changed.connect(_save)
	shop.activity.connect(func(entry): ActivityLog.append(entry, log_path))
	shop.home_pressed.connect(_show_home)
	shop.cards_pressed.connect(_show_cards)
	_swap(shop)


## Cards between runs (D146): draws, slots and what's equipped, saved as they
## change.
func _show_cards() -> void:
	if not progression.writable: return
	Palette.number_cash = true
	var cards := CardsScreen.new()
	cards.workshop = workshop
	cards.progression = progression
	cards.changed.connect(_save)
	cards.activity.connect(func(entry): ActivityLog.append(entry, log_path))
	cards.home_pressed.connect(_show_home)
	cards.workshop_pressed.connect(_show_workshop)
	_swap(cards)


## A saved run that can't be brought back, because the game updated since or
## the record is damaged: it ends at its saved wave, keeping the Coins it had
## already banked.
func _resume_failed(saved: Dictionary, reason: String) -> void:
	var result = saved.get("result", {})
	var trusted := reason == "changed" and RunReport.valid_record(saved, true)
	var reached := int(result.wave) if trusted else 0
	# A sound record from changed combat still proves its reached wave. Do
	# not turn arbitrary wave values in a damaged record into account unlocks.
	if trusted:
		for reward in progression.observe(int(saved.start.get("tier", 1)), reached, maxi(0, reached - 1)):
			ActivityLog.append({"kind": "wave_milestone", "reward": reward}, log_path)
	var peak := float(result.get("peak_number", 0.0)) if trusted else 0.0
	var earned := float(result.cash_earned) if trusted else 0.0
	for milestone in workshop.finish_run(reached, peak, earned):
		ActivityLog.append({"kind": "milestone", "number": milestone.number, "coins": milestone.coins}, log_path)
	var entry := saved.duplicate(true)
	entry["kind"] = "run"
	entry["resume_failed"] = reason
	ActivityLog.append(entry, log_path)
	_log_gift()
	var note := "Your run at wave %d couldn't carry over to this version of the game, so it ended there. Its Coins are kept." % reached \
		if trusted else "Your saved run couldn't be read, so it ended. Its banked Coins and previous records are kept."
	_show_home().show_note(note)
	_save()


## Logs a run as it ends. A run the window closes on is saved and resumed
## instead, so each run is logged once (D078).
func _log_run(battle: BattleScreen) -> void:
	ActivityLog.append(battle.report(), log_path)
	# Logged apart, so a report never counts a milestone's Coins as earned (D107).
	for milestone in battle.milestones:
		ActivityLog.append({"kind": "milestone", "number": milestone.number, "coins": milestone.coins}, log_path)
	_log_gift()


## Logged apart, so a report never counts the first run's gift as earned (D125).
func _log_gift() -> void:
	if workshop.gift_given > 0.0:
		ActivityLog.append({"kind": "gift", "coins": workshop.gift_given}, log_path)


func _swap(next: Control) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = next
	add_child(next)
	# Screens fade in rather than snap (D138).
	next.modulate.a = 0.0
	next.create_tween().tween_property(next, "modulate:a", 1.0, SCREEN_FADE_SECONDS)
