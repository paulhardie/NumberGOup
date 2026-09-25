extends SceneTree
## Plays runs headless and prints where each ended: the measuring tool for
## the rebuild (docs/REBUILD_SPEC.md). A measurement, not a gate.
##
##   bash run_godot.sh --headless --path . -s res://tools/sim_runs.gd -- --seeds 20 --cap-minutes 90

const BattleSim = preload("res://src/tower/battle_sim.gd")


func _init() -> void:
	var options := _options()
	var seeds := int(options.get("seeds", "10"))
	var cap_seconds := float(options.get("cap-minutes", "90")) * 60.0
	var waves: Array[int] = []
	print("seed  wave  game time  kills  cash earned  coins  killed by")
	for index in range(seeds):
		var sim := BattleSim.new(index + 1)
		sim.run_until_dead(cap_seconds)
		waves.append(sim.wave)
		print("%4d  %4d  %9s  %5d  %11.0f  %5.0f  %s" % [index + 1, sim.wave, _clock(sim.time), sim.kills, sim.cash_earned, sim.coins, sim.killed_by if not sim.alive else "(alive at cap)"])
	waves.sort()
	print("median wave %d, range %d to %d" % [waves[waves.size() / 2], waves[0], waves[-1]])
	quit()


func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _options() -> Dictionary:
	var found := {}
	var args := OS.get_cmdline_user_args()
	for index in range(0, args.size() - 1):
		if args[index].begins_with("--"):
			found[args[index].substr(2)] = args[index + 1]
	return found
