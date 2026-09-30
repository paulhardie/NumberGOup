extends SceneTree
## Check a copied version-1 rebuilt save without changing the input. All
## migration writes use run_godot.sh's scratch user://, never the play save.
## bash run_godot.sh --headless --path . -s res://tools/check_migration.gd -- --file <old-save-copy.json>
const Save = preload("res://src/tower/save.gd")
const Progression = preload("res://src/tower/progression.gd")
const RunReport = preload("res://src/tower/run_report.gd")
var probe_path := "user://migration_check-%d.json" % Time.get_ticks_usec()
var failures: Array[String] = []
var checks := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--file")
	if at < 0 or at + 1 >= args.size() or not FileAccess.file_exists(args[at + 1]):
		printerr("Give a readable version-1 rebuilt save copy with --file <path>.")
		quit(1)
		return
	var input: String = args[at + 1]
	var text := FileAccess.get_file_as_string(input)
	var old = JSON.parse_string(text)
	if not old is Dictionary or old.get("version") != 1 or not old.get("workshop") is Dictionary:
		printerr("The probe needs a version-1 rebuilt save copy.")
		quit(1)
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
		var replayable := RunReport.is_replayable(active)
		check(replayable, "legacy active record remains replayable")
		if replayable: check(RunReport.matches(active, RunReport.replay(active)), "legacy active battle resumes on the current rules")
	check(Save.save_progress(p, probe_path, active), "version-2 migration writes atomically")
	var loaded := Save.load_progress(probe_path)
	check(loaded.writable and Save._view(loaded.to_dict()) == Save._view(p.to_dict()), "current progress reloads unchanged")
	check(loaded.workshop.coins == p.workshop.coins and loaded.observe(1, int(old.workshop.best_wave)).is_empty(), "reload cannot pay migration rewards twice")
	check(Save._view(Save.load_run(probe_path)) == Save._view(active), "current save retains the active record")
	check(JSON.parse_string(FileAccess.get_file_as_string(probe_path)).version == Save.VERSION, "written schema is current")
	check(FileAccess.get_file_as_string(input) == text, "input copy was never modified")
	for failure in failures: printerr("FAIL: ", failure)
	print("%s: copied-save migration (%d checks; %d ranks, %d runs, best wave %d; +%s Coins, +%d Gems)" % ["PASS" if failures.is_empty() else "FAIL", checks, old.workshop.levels.size(), int(old.workshop.runs), int(old.workshop.best_wave), coin_reward, gem_reward])
	quit(0 if failures.is_empty() else 1)
