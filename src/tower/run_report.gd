extends RefCounted
## One run as the activity log keeps it (D077): enough to replay it exactly,
## that is the seed, the Workshop it started from and every input with its tick,
## plus how it stood at each wave's end and how it ended. A replay only
## matches on the game version that recorded it; the wave snapshots still
## read after the rules change.

const BattleSim = preload("res://src/tower/battle_sim.gd")


## `play` is what only the screen knows: real seconds played, seconds at each
## game speed.
static func build(sim: BattleSim, play: Dictionary = {}) -> Dictionary:
	return {
		"kind": "run",
		"seed": sim.run_seed,
		"start": {"levels": sim.levels.duplicate(), "groups": sim.open_groups.duplicate()},
		"inputs": sim.inputs.duplicate(true),
		"waves": sim.wave_log.duplicate(true),
		"result": {
			"wave": sim.wave, "time": sim.time, "ticks": sim.ticks, "killed_by": sim.killed_by,
			"closed_mid_run": sim.alive, "health": sim.health, "cash": sim.cash,
			"cash_earned": sim.cash_earned, "coins": sim.coins, "kills": sim.kills,
			"bought": sim.run_levels.duplicate(),
		},
		"play": play.duplicate(true),
	}


## Plays a recorded run again from its seed and inputs, to the tick it was
## left at. Takes a run straight from JSON, where every number is a float.
static func replay(run: Dictionary) -> BattleSim:
	var start: Dictionary = run.get("start", {})
	var levels := {}
	var saved_levels: Dictionary = start.get("levels", {})
	for id in saved_levels:
		levels[String(id)] = int(saved_levels[id])
	var groups: Array = []
	for group in start.get("groups", []):
		groups.append(String(group))
	# The seed must go back to an int: the RNGs are seeded from its hash.
	var sim := BattleSim.new(int(run.get("seed", 0)), levels, groups)
	for input in run.get("inputs", []):
		while sim.alive and sim.ticks < int(input.tick):
			sim.step()
		if input.has("end"):
			sim.end_run()
		else:
			sim.buy(String(input.buy), int(input.count))
	var last := int(run.get("result", {}).get("ticks", 0))
	while sim.alive and sim.ticks < last:
		sim.step()
	return sim


## Whether a replay ended where the recorded run did.
static func matches(run: Dictionary, sim: BattleSim) -> bool:
	var result: Dictionary = run.get("result", {})
	return (sim.ticks == int(result.get("ticks", -1)) and sim.wave == int(result.get("wave", -1))
		and sim.kills == int(result.get("kills", -1))
		and is_equal_approx(sim.cash_earned, float(result.get("cash_earned", -1.0)))
		and is_equal_approx(sim.coins, float(result.get("coins", -1.0)))
		and is_equal_approx(sim.health, float(result.get("health", -1.0))))
