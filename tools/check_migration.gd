extends SceneTree
## Check a copied version-1 or version-2 rebuilt save without changing the
## input. All migration writes use run_godot.sh's scratch user://, never the
## play save. Version 2 gains an empty Cards collection (D146) and nothing else.
## bash run_godot.sh --headless --path . -s res://tools/check_migration.gd -- --file <old-save-copy.json>
const Save = preload("res://src/tower/save.gd")
const Progression = preload("res://src/tower/progression.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const Main = preload("res://src/main.gd")
const Home = preload("res://src/ui/home_screen.gd")
const BattleScreen = preload("res://src/ui/battle_screen.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")
const Guesses = preload("res://src/tower/guesses.gd")
const Workshop = preload("res://src/tower/workshop.gd")
var probe_path := "user://migration_check-%d.json" % Time.get_ticks_usec()
var failures: Array[String] = []
var checks := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)


func _init() -> void:
	run.call_deferred()


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var expect_recovery := "--expect-recovery" in args
	var at := args.find("--file")
	if at < 0 or at + 1 >= args.size() or not FileAccess.file_exists(args[at + 1]):
		printerr("Give a readable version-1 rebuilt save copy with --file <path>.")
		quit(1)
		return
	var input: String = args[at + 1]
	var text := FileAccess.get_file_as_string(input)
	var old = JSON.parse_string(text)
	if not old is Dictionary or old.get("version") not in [1, 2, 1.0, 2.0] or not old.get("workshop") is Dictionary:
		printerr("The probe needs a version-1 or version-2 rebuilt save copy.")
		quit(1)
		return
	if int(old.version) == 2:
		await run_version_two(input, text, old)
		return
	if FileAccess.file_exists(probe_path) or FileAccess.file_exists(probe_path + ".v1-backup.json"):
		printerr("The scratch probe path already exists. Retry with a fresh scratch home.")
		quit(1)
		return
	if DirAccess.copy_absolute(input, probe_path) != OK:
		printerr("Couldn't copy the fixture into the scratch save folder.")
		quit(1)
		return
	var p := Save.load_progress(probe_path)
	check(p.writable, "migrated progress stays writable")
	check(FileAccess.get_file_as_string(probe_path + ".v1-backup.json") == text, "backup preserves every original byte")
	for key in old.workshop:
		if key != "coins":
			check(Save._view(p.workshop.to_dict().get(key)) == Save._view(old.workshop[key]), "permanent %s preserved" % key)
	var coin_reward := 0.0
	var gem_reward := 0
	for row in Progression.MILESTONES:
		if int(row.tier) == 1 and int(row.wave) <= int(old.workshop.best_wave) and (int(row.wave) != 100 or int(old.workshop.best_wave) > 100):
			coin_reward += float(row.coins)
			gem_reward += int(row.gems)
	check(p.workshop.coins == float(old.workshop.coins) + coin_reward and p.gems == gem_reward, "only the newly introduced rewards change balances")
	check(p.best_wave(1) == int(old.workshop.best_wave) and p.best_wave(1, true) == maxi(0, int(old.workshop.best_wave) - 1), "legacy reached/cleared records migrate conservatively")
	var active := Save.load_run(probe_path)
	check(Save._view(active) == Save._view(old.get("run", {})), "active record and its banked Coins preserved")
	if not active.is_empty():
		if expect_recovery:
			check(RunReport.valid_record(active, true), "changed-rules record remains structurally sound")
			check(not RunReport.is_replayable(active) or not RunReport.matches(active, RunReport.replay(active)), "the explicit recovery case cannot resume under current combat")
		else:
			var replayable := RunReport.is_replayable(active)
			check(replayable, "legacy active record remains replayable")
			if replayable: check(RunReport.matches(active, RunReport.replay(active)), "legacy active battle resumes on the current rules")
	check(Save.save_progress(p, probe_path, active), "version-2 migration writes atomically")
	var loaded := Save.load_progress(probe_path)
	check(loaded.writable and Save._view(loaded.to_dict()) == Save._view(p.to_dict()), "current progress reloads unchanged")
	check(loaded.workshop.coins == p.workshop.coins and loaded.observe(1, int(old.workshop.best_wave)).is_empty(), "reload cannot pay migration rewards twice")
	check(Save._view(Save.load_run(probe_path)) == Save._view(active), "current save retains the active record")
	check(JSON.parse_string(FileAccess.get_file_as_string(probe_path)).version == Save.VERSION, "written schema is current")
	if expect_recovery:
		check(not active.is_empty(), "explicit recovery requires an active run")
		if not active.is_empty() and RunReport.valid_record(active, true): await check_recovery(active, p)
	check(FileAccess.get_file_as_string(input) == text, "input copy was never modified")
	for failure in failures: printerr("FAIL: ", failure)
	print("%s: copied-save migration (%d checks; %d ranks, %d runs, best wave %d; +%s Coins, +%d Gems)" % ["PASS" if failures.is_empty() else "FAIL", checks, old.workshop.levels.size(), int(old.workshop.runs), int(old.workshop.best_wave), coin_reward, gem_reward])
	quit(0 if failures.is_empty() else 1)


## Version 2 to 3 (D146): everything kept exactly, an empty Cards collection
## added, a byte-exact backup, and an active run still resuming.
func run_version_two(input: String, text: String, old: Dictionary) -> void:
	if FileAccess.file_exists(probe_path) or FileAccess.file_exists(probe_path + ".v2-backup.json"):
		printerr("The scratch probe path already exists. Retry with a fresh scratch home.")
		quit(1)
		return
	if DirAccess.copy_absolute(input, probe_path) != OK:
		printerr("Couldn't copy the fixture into the scratch save folder.")
		quit(1)
		return
	var p := Save.load_progress(probe_path)
	check(p.writable, "migrated progress stays writable: %s" % p.notice)
	check(FileAccess.get_file_as_string(probe_path + ".v2-backup.json") == text, "backup preserves every original byte")
	var workshop: Dictionary = p.workshop.to_dict()
	for key in old.workshop:
		check(Save._view(workshop.get(key)) == Save._view(old.workshop[key]), "permanent %s preserved" % key)
	var progression: Dictionary = p.to_dict()
	check(Save._view(progression.cards) == Save._view({"copies": {}, "slots": 1, "equipped": []}), "Cards start empty, one free slot")
	progression.erase("cards")
	check(Save._view(progression) == Save._view(old.get("progression", {})), "every progression field preserved: Gems, records, claims, research")
	var active := Save.load_run(probe_path)
	check(Save._view(active) == Save._view(old.get("run", {})), "active record and its banked Coins preserved")
	if not active.is_empty():
		var screen := BattleScreen.new()
		screen.workshop = p.workshop
		screen.progression = p
		screen.resume = active
		var failed := [""]
		screen.resume_failed.connect(func(_saved, reason): failed[0] = reason)
		root.add_child(screen)
		screen.set_process(false)
		check(screen.sim != null and failed[0] == "", "the active battle resumes after migration: %s" % failed[0])
		screen.free()
	check(Save.save_progress(p, probe_path, active), "version-3 migration writes atomically")
	var loaded := Save.load_progress(probe_path)
	check(loaded.writable and Save._view(loaded.to_dict()) == Save._view(p.to_dict()), "current progress reloads unchanged")
	check(Save._view(Save.load_run(probe_path)) == Save._view(active), "current save retains the active record")
	check(JSON.parse_string(FileAccess.get_file_as_string(probe_path)).version == Save.VERSION, "written schema is current")
	check(FileAccess.get_file_as_string(input) == text, "input copy was never modified")
	for failure in failures: printerr("FAIL: ", failure)
	print("%s: copied version-2 save migration (%d checks; %d ranks, %d runs, best wave %d, %d Gems%s)" % ["PASS" if failures.is_empty() else "FAIL", checks,
		old.workshop.get("levels", {}).size(), int(old.workshop.get("runs", 0)), int(old.workshop.get("best_wave", 0)), p.gems, ", with an active run" if not active.is_empty() else ""])
	quit(0 if failures.is_empty() else 1)


## Exercise the actual screen-to-account recovery, not a duplicate migration.
func check_recovery(active: Dictionary, before: Progression) -> void:
	var tier := int(active.start.get("tier", 1))
	var reached := int(active.result.wave)
	var cleared := reached - 1
	var expected_coins := before.workshop.coins
	var expected_gems := before.gems
	for row in Progression.MILESTONES:
		var id := "%d:%d" % [int(row.tier), int(row.wave)]
		if int(row.tier) == tier and reached >= int(row.wave) and id not in before.claimed and (int(row.wave) != 100 or cleared >= 100):
			expected_coins += float(row.coins)
			expected_gems += int(row.gems)
	var peak := float(active.result.get("peak_number", 0.0))
	for row in Guesses.MILESTONES:
		if before.workshop.best_number < float(row.number) and peak >= float(row.number): expected_coins += float(row.coins)
	if before.workshop.runs == 0: expected_coins += Workshop.FIRST_RUN_GIFT
	var main := Main.new()
	main.save_path = probe_path
	main.log_path = probe_path + ".activity.jsonl"
	main.settings_path = probe_path + ".settings.json"
	root.add_child(main)
	if main._screen is BattleScreen: main._screen.set_process(false)
	for frame in range(100):
		if main._screen is Home: break
		if main._screen is BattleScreen: main._screen._process(0.0)
		await process_frame
	check(main._screen is Home, "actual incompatible battle recovers to Home within the probe budget")
	check(Save.load_run(probe_path).is_empty(), "recovery removes the active run")
	var after := Save.load_progress(probe_path)
	check(after.writable and after.workshop.levels == before.workshop.levels and after.workshop.open_groups == before.workshop.open_groups, "recovery preserves every rank and opened group")
	check(is_equal_approx(after.workshop.coins, expected_coins) and after.gems == expected_gems, "banked Coins are kept, never banked twice; only earned new rewards are added")
	check(after.workshop.runs == before.workshop.runs + 1 and after.workshop.best_wave == maxi(before.workshop.best_wave, reached) and is_equal_approx(after.workshop.best_number, maxf(before.workshop.best_number, peak)), "recovered run retains its records and is counted once")
	check(after.best_wave(tier) == maxi(before.best_wave(tier), reached) and after.best_wave(tier, true) == maxi(before.best_wave(tier, true), cleared), "recovered tier reached/cleared progress is retained")
	if tier == 1 and reached >= 30: check(after.unlocked("labs"), "saved Labs reveal survives changed combat")
	var entries := ActivityLog.read(main.log_path).filter(func(entry): return entry.kind == "run")
	check(entries.size() == 1 and entries[0].resume_failed == "changed", "actual recovery is logged once as changed combat")
	main.free()
	await process_frame
	var coins := after.workshop.coins
	check(after.observe(tier, reached, cleared).is_empty() and after.workshop.coins == coins, "recovered wave rewards cannot be paid twice")
	print("recovery: wave %d, %d runs, %s Coins, %d Gems, Labs %s" % [reached, after.workshop.runs, after.workshop.coins, after.gems, after.unlocked("labs")])
