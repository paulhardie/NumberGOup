extends SceneTree
## Plays runs headless and prints where each ended: the measuring tool for
## the rebuild (docs/REBUILD_SPEC.md). A measurement, not a gate.
##
##   bash run_godot.sh --headless --path . -s res://tools/sim_runs.gd -- --seeds 20 --buy cheapest
##
## --buy picks how the run spends its Cash, as a stand-in for a player:
##   none      never buys (the default)
##   cheapest  buys the cheapest level it can afford, as soon as it can
##   even      buys whichever open row has the fewest levels, when it can
##   attack    only Damage and Attack Speed, cheapest first
##   core      Damage, Attack Speed, Health, Health Regen and Defense
##             Absolute, cheapest first; in a career its Workshop does the same
## --cap-minutes stops a run that is still alive (default 90).
## --divider-share N scales how many Dividers come (1 is Guesses.DIVIDER's,
## 0 none) and --divider-speed N sets their speed as a share of a basic
## enemy's, and --divider-health N its health in basic enemies', for trying
## the Divider's tuning without changing the game; --divider-divisor N fixes
## its divisor at every wave. --overfill N sets how much
## of Regen and Lifesteal works past Health (0 a ceiling, 1 none), and --curve
## adds the Number at the end of every fifth wave to each run's line.
##
## --careers N plays N runs in a row from a fresh Workshop instead, spending
## the Coins between runs: it opens the cheapest group it can, otherwise buys
## the open Workshop row with the fewest levels, until nothing is affordable.
## Each run buys with --buy (use even). Each row printed is one run.

const BattleSim = preload("res://src/tower/battle_sim.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const Workshop = preload("res://src/tower/workshop.gd")

const STRATEGIES := ["none", "cheapest", "even", "attack", "core"]
## The rows a focused player buys, with --buy core: in the run, and in a
## career's Workshop (where it opens only the Defense group for them).
const CORE_ROWS := ["damage", "attack_speed", "health", "health_regen", "defense_absolute"]


func _init() -> void:
	var options := _options()
	var seeds := int(options.get("seeds", "10"))
	var cap_seconds := float(options.get("cap-minutes", "90")) * 60.0
	var strategy: String = options.get("buy", "none")
	if strategy not in STRATEGIES:
		printerr("--buy must be one of %s" % ", ".join(STRATEGIES))
		quit(1)
		return
	if options.has("careers"):
		_career(int(options.careers), strategy, cap_seconds, options)
		quit()
		return
	var waves: Array[int] = []
	print("buying: %s" % strategy)
	print("seed  wave  game time  kills  cash earned  coins  peak Number  ÷ came/landed  ÷ took  killed by  levels bought")
	for index in range(seeds):
		var sim := BattleSim.new(index + 1)
		_tune(sim, options)
		while sim.alive and sim.time < cap_seconds:
			_spend(sim, strategy)
			sim.step()
		waves.append(sim.wave)
		print("%4d  %4d  %9s  %5d  %11.0f  %5.0f  %11.1f  %13s  %5.0f%%  %-9s  %s" % [index + 1, sim.wave, _clock(sim.time), sim.kills, sim.cash_earned, sim.coins,
			sim.peak_number, "%d/%d" % [sim.dividers_spawned, sim.dividers_landed], _divider_share_of_loss(sim),
			sim.killed_by if not sim.alive else "(alive)", _bought(sim)] + _curve(sim, options))
	waves.sort()
	print("median wave %d, range %d to %d" % [waves[waves.size() / 2], waves[0], waves[-1]])
	quit()


func _career(runs: int, strategy: String, cap_seconds: float, options: Dictionary) -> void:
	var workshop := Workshop.new()
	var hours := 0.0
	print("career, buying %s in each run, %d-minute cap" % [strategy, int(cap_seconds / 60.0)])
	print("run  wave  game time  hours  coins earned  coins left  ÷ came/landed  killed by  Workshop")
	for run in range(runs):
		var sim := BattleSim.new(run + 1, workshop.levels, workshop.open_groups)
		_tune(sim, options)
		while sim.alive and sim.time < cap_seconds:
			_spend(sim, strategy)
			sim.step()
		workshop.add_coins(sim.coins)
		workshop.finish_run(sim.wave, sim.peak_number)
		hours += sim.time / 3600.0
		_spend_workshop(workshop, strategy)
		print("%3d  %4d  %9s  %5.1f  %12.0f  %10.0f  %13s  %-9s  %s" % [run + 1, sim.wave, _clock(sim.time), hours, sim.coins, workshop.coins,
			"%d/%d" % [sim.dividers_spawned, sim.dividers_landed], sim.killed_by if not sim.alive else "(alive)", _workshop_summary(workshop)] + _curve(sim, options))


func _spend_workshop(workshop: Workshop, strategy: String) -> void:
	if strategy == "core":
		while true:
			if not workshop.is_group_open("defense"):
				if not workshop.open_group("defense"):
					return
				continue
			var cheapest := ""
			for id in CORE_ROWS:
				if workshop.level(id) < TowerData.max_level(id) and (cheapest == "" or workshop.price(id) < workshop.price(cheapest)):
					cheapest = id
			if cheapest == "" or not workshop.buy(cheapest):
				return
	while true:
		var cheapest_group := ""
		for category in ["attack", "defense", "utility"]:
			var group := workshop.next_group(category)
			if group != "" and workshop.can_open(group) and (cheapest_group == "" or TowerData.group_price(group) < TowerData.group_price(cheapest_group)):
				cheapest_group = group
		if cheapest_group != "":
			workshop.open_group(cheapest_group)
			continue
		var fewest := ""
		for id in TowerData.rows():
			if workshop.is_group_open(TowerData.group(id)) and workshop.level(id) < TowerData.max_level(id):
				if fewest == "" or workshop.level(id) < workshop.level(fewest):
					fewest = id
		if fewest == "" or not workshop.buy(fewest):
			return


func _workshop_summary(workshop: Workshop) -> String:
	var opened: Array[String] = []
	for group in workshop.open_groups:
		if TowerData.group_price(group) > 0.0:
			opened.append(group)
	var total := 0
	for id in workshop.levels:
		total += int(workshop.levels[id])
	return "%d levels; opened %s" % [total, ", ".join(opened) if not opened.is_empty() else "nothing"]


func _spend(sim: BattleSim, strategy: String) -> void:
	if strategy == "none":
		return
	while true:
		var choice := _choose(sim, strategy)
		if choice == "" or not sim.buy(choice):
			return


## The row the strategy buys next, or "" to wait. It waits for its choice
## rather than buying something else, as a player saving up would.
func _choose(sim: BattleSim, strategy: String) -> String:
	var rows: Array[String] = []
	for id in TowerData.rows():
		var allowed: bool = (strategy != "attack" or id in ["damage", "attack_speed"]) and (strategy != "core" or id in CORE_ROWS)
		if sim.is_open(id) and not sim.at_max(id) and allowed:
			rows.append(id)
	if rows.is_empty():
		return ""
	var best := rows[0]
	for id in rows:
		var better := sim.price(id) < sim.price(best) if strategy != "even" else int(sim.run_levels.get(id, 0)) < int(sim.run_levels.get(best, 0))
		if better:
			best = id
	return best if sim.can_buy(best) else ""


## With --curve, the Number at the end of every fifth wave, as " | 5:12 10:40 …".
func _curve(sim: BattleSim, options: Dictionary) -> String:
	if not options.has("curve"):
		return ""
	var points: Array[String] = []
	for snapshot in sim.wave_log:
		if int(snapshot.wave) % 5 == 0:
			points.append("%d:%.0f" % [int(snapshot.wave), float(snapshot.health)])
	return "  | " + " ".join(points)


func _tune(sim: BattleSim, options: Dictionary) -> void:
	if options.has("divider-share"):
		var scale := float(options["divider-share"])
		sim.divider.share_first = float(sim.divider.share_first) * scale
		sim.divider.share_full = float(sim.divider.share_full) * scale
	if options.has("divider-speed"):
		sim.divider.speed = float(options["divider-speed"])
	if options.has("overfill"):
		sim.overfill = float(options.overfill)
	if options.has("divider-divisor"):
		sim.divider.divisor_first = float(options["divider-divisor"])
		sim.divider.divisor_full = float(options["divider-divisor"])
	if options.has("divider-health"):
		sim.divider.health_first = float(options["divider-health"])
		sim.divider.health_full = float(options["divider-health"])


## The share of everything the Number lost that Dividers took.
func _divider_share_of_loss(sim: BattleSim) -> float:
	var total := 0.0
	for kind in sim.lost_to:
		total += float(sim.lost_to[kind])
	return 100.0 * float(sim.lost_to.get("divider", 0.0)) / total if total > 0.0 else 0.0


func _bought(sim: BattleSim) -> String:
	var parts: Array[String] = []
	for id in sim.run_levels:
		parts.append("%s %d" % [id, sim.run_levels[id]])
	return ", ".join(parts)


func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _options() -> Dictionary:
	var found := {}
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if args[index].begins_with("--"):
			# An option with no value after it, like --curve, is a switch.
			var has_value := index + 1 < args.size() and not args[index + 1].begins_with("--")
			found[args[index].substr(2)] = args[index + 1] if has_value else "true"
	return found
