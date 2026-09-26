extends SceneTree
## Reads an activity report the owner exported from Home (D077): a table of
## their runs, each replayed from its seed and inputs to check it matches, then
## their Workshop spending. A replay only matches on the game version that
## recorded it (each run's "game" commit); check that commit out to replay
## older runs.
##
##   bash run_godot.sh --headless --path . -s res://tools/read_report.gd -- --file <report.json>
##   ... -- --file <report.json> --run 3     that run wave by wave, with its buys

const ActivityLog = preload("res://src/tower/activity_log.gd")
const RunReport = preload("res://src/tower/run_report.gd")


func _init() -> void:
	var options := _options()
	var path := String(options.get("file", ""))
	var json := JSON.new()
	if path == "" or not FileAccess.file_exists(path) or json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		printerr("Give a readable report with --file <path>.")
		quit(1)
		return
	var report: Dictionary = json.data
	if report.get("format") != ActivityLog.FORMAT:
		printerr("%s isn't a Number Go Up activity report." % path)
		quit(1)
		return
	var runs: Array = report.entries.filter(func(entry): return entry.get("kind") == "run")
	var here := ActivityLog.game_version()
	var workshop: Dictionary = report.get("workshop", {})
	print("Exported %s from v%s (%s); this checkout is %s." % [report.exported_at, report.get("game_version", "?"), report.game, here])
	print("Workshop now: %s Coins, best wave %d, %d runs, groups %s" % [
		_n(workshop.get("coins", 0.0)), int(workshop.get("best_wave", 0)), int(workshop.get("runs", 0)), ", ".join(workshop.get("open_groups", []))])
	if options.has("run"):
		_print_run(runs, int(options.run))
	else:
		_print_runs(runs, here)
		_print_workshop(report.entries)
	quit(0)


func _print_runs(runs: Array, here: String) -> void:
	print("\n  #  when (UTC)           wave  game time  real time  kills  cash earned  coins  ended by  buys  replay")
	for index in range(runs.size()):
		var run: Dictionary = runs[index]
		if not RunReport.is_replayable(run):
			print("%3d  %-19s  a damaged record%s" % [index + 1, run.get("at", "?"), ", lost on resume" if run.has("resume_failed") else ""])
			continue
		var result: Dictionary = run.result
		var replay := "other version"
		if String(run.get("game", "")) == here:
			replay = "matches" if RunReport.matches(run, RunReport.replay(run)) else "DIFFERS"
		var ended := String(result.killed_by)
		if run.get("resume_failed", false):
			ended = "lost"
		elif bool(result.closed_mid_run):
			ended = "closed"
		print("%3d  %-19s  %4d  %9s  %9s  %5d  %11s  %5s  %-8s  %4d  %s" % [index + 1, run.get("at", "?"), int(result.wave),
			_clock(float(result.time)), _clock(float(run.play.get("real_seconds", 0.0))), int(result.kills),
			_n(result.cash_earned), _n(result.coins), ended, run.inputs.size(), replay])


func _print_run(runs: Array, number: int) -> void:
	if number < 1 or number > runs.size():
		printerr("There are %d runs." % runs.size())
		return
	var run: Dictionary = runs[number - 1]
	if not RunReport.is_replayable(run):
		print("\nRun %d is a damaged record: %s" % [number, JSON.stringify(run).left(400)])
		return
	print("\nRun %d: seed %d, started with %s" % [number, int(run.seed), run.start.levels])
	print("Played %s real, at speeds %s" % [_clock(float(run.play.get("real_seconds", 0.0))), run.play.get("seconds_at_speed", {})])
	print("\n wave  game time  health / most   cash  earned  coins  kills  enemy atk  enemy hp  bought")
	for snapshot in run.waves:
		print("%5d  %9s  %13s  %5s  %6s  %5s  %5d  %9s  %8s  %s" % [int(snapshot.wave), _clock(float(snapshot.time)),
			"%s / %s" % [_n(snapshot.health), _n(snapshot.max_health)], _n(snapshot.cash), _n(snapshot.cash_earned),
			_n(snapshot.coins), int(snapshot.kills), _n(snapshot.enemy_attack), _n(snapshot.enemy_health), _levels(snapshot.bought)])
	print("\nBuys (game time, row × count):")
	for input in run.inputs:
		var at := _clock(float(input.tick) * RunReport.BattleSim.TICK)
		print("  %s  %s" % [at, "End run" if input.has("end") else "%s ×%s" % [input.buy, "Max" if int(input.count) == 0 else str(int(input.count))]])
	var result: Dictionary = run.result
	print("\nEnded wave %d at %s by %s." % [int(result.wave), _clock(float(result.time)), "closing the game" if bool(result.closed_mid_run) else result.killed_by])


func _print_workshop(entries: Array) -> void:
	var spent := {}
	var opened: Array[String] = []
	for entry in entries:
		match entry.get("kind"):
			"workshop_buy":
				spent[entry.id] = float(spent.get(entry.id, 0.0)) + float(entry.cost)
			"workshop_open":
				opened.append("%s (%s, %s)" % [entry.group, _n(entry.cost), entry.get("at", "?")])
	print("\nGroups opened: %s" % (", ".join(opened) if not opened.is_empty() else "none"))
	var rows := spent.keys()
	rows.sort_custom(func(a, b): return spent[a] > spent[b])
	print("Coins spent by row: %s" % (", ".join(rows.map(func(id): return "%s %s" % [id, _n(spent[id])])) if not rows.is_empty() else "none"))


func _levels(bought: Dictionary) -> String:
	return " ".join(bought.keys().map(func(id): return "%s %d" % [id, int(bought[id])]))


func _n(value) -> String:
	var number := float(value)
	return "%.2f" % number if absf(number) < 100.0 else String.num(roundf(number), 0)


func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _options() -> Dictionary:
	var found := {}
	var args := OS.get_cmdline_user_args()
	for index in range(0, args.size() - 1):
		if args[index].begins_with("--"):
			found[args[index].substr(2)] = args[index + 1]
	return found
