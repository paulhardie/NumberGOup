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
## --cap-minutes stops a run that is still alive (default 90).

const BattleSim = preload("res://src/tower/battle_sim.gd")
const TowerData = preload("res://src/tower/tower_data.gd")

const STRATEGIES := ["none", "cheapest", "even", "attack"]


func _init() -> void:
	var options := _options()
	var seeds := int(options.get("seeds", "10"))
	var cap_seconds := float(options.get("cap-minutes", "90")) * 60.0
	var strategy: String = options.get("buy", "none")
	if strategy not in STRATEGIES:
		printerr("--buy must be one of %s" % ", ".join(STRATEGIES))
		quit(1)
		return
	var waves: Array[int] = []
	print("buying: %s" % strategy)
	print("seed  wave  game time  kills  cash earned  coins  killed by  levels bought")
	for index in range(seeds):
		var sim := BattleSim.new(index + 1)
		while sim.alive and sim.time < cap_seconds:
			_spend(sim, strategy)
			sim.step()
		waves.append(sim.wave)
		print("%4d  %4d  %9s  %5d  %11.0f  %5.0f  %-9s  %s" % [index + 1, sim.wave, _clock(sim.time), sim.kills, sim.cash_earned, sim.coins,
			sim.killed_by if not sim.alive else "(alive)", _bought(sim)])
	waves.sort()
	print("median wave %d, range %d to %d" % [waves[waves.size() / 2], waves[0], waves[-1]])
	quit()


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
		if sim.is_open(id) and not sim.at_max(id) and (strategy != "attack" or id in ["damage", "attack_speed"]):
			rows.append(id)
	if rows.is_empty():
		return ""
	var best := rows[0]
	for id in rows:
		var better := sim.price(id) < sim.price(best) if strategy != "even" else int(sim.run_levels.get(id, 0)) < int(sim.run_levels.get(best, 0))
		if better:
			best = id
	return best if sim.can_buy(best) else ""


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
	for index in range(0, args.size() - 1):
		if args[index].begins_with("--"):
			found[args[index].substr(2)] = args[index + 1]
	return found
