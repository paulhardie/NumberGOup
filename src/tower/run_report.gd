extends RefCounted
## One run as the activity log keeps it (D077): enough to replay it exactly,
## that is the seed, the Workshop it started from and every input with its tick,
## plus how it stood at each wave's end and how it ended. A replay only
## matches on the game version that recorded it; the wave snapshots still
## read after the rules change.

const BattleSim = preload("res://src/tower/battle_sim.gd")
const TowerData = preload("res://src/tower/tower_data.gd")


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


## The longest run a saved record may claim, in ticks (a day of game time), so
## a damaged file can't set a replay running for ever.
const MOST_TICKS := 30 * 60 * 60 * 24


## Plays a recorded run again from its seed and inputs, a slice at a time,
## so the battle screen can resume a long run without freezing.
class Replay:
	var sim: BattleSim
	var _inputs: Array
	var _next := 0
	var _last: int

	## Takes a run straight from JSON, where every number is a float.
	func _init(run: Dictionary) -> void:
		_inputs = run.get("inputs", [])
		_last = int(run.get("result", {}).get("ticks", 0))
		var start: Dictionary = run.get("start", {})
		var levels := {}
		var saved_levels: Dictionary = start.get("levels", {})
		for id in saved_levels:
			levels[String(id)] = int(saved_levels[id])
		var groups: Array = []
		for group in start.get("groups", []):
			groups.append(String(group))
		# The seed must go back to an int: the RNGs are seeded from its hash.
		sim = BattleSim.new(int(run.get("seed", 0)), levels, groups)

	## Steps at most `budget` ticks, applying each input at its tick; true once
	## the run is back at the tick it was left at (or has ended).
	func advance(budget: int) -> bool:
		while true:
			var target := int(_inputs[_next].tick) if _next < _inputs.size() else _last
			while sim.alive and sim.ticks < target:
				if budget <= 0:
					return false
				sim.step()
				budget -= 1
			if _next >= _inputs.size():
				return true
			var input: Dictionary = _inputs[_next]
			_next += 1
			if input.has("end"):
				sim.end_run()
			else:
				sim.buy(String(input.buy), int(input.count))
		return true


## Plays a recorded run again, all at once, to the tick it was left at.
static func replay(run: Dictionary) -> BattleSim:
	var again := Replay.new(run)
	again.advance(MOST_TICKS)
	return again.sim


## Whether a saved record has the shape a replay needs, with sane numbers.
## A damaged save's run fails here rather than part way through a replay.
static func is_replayable(run) -> bool:
	if not run is Dictionary:
		return false
	if not (run.get("seed") is float or run.get("seed") is int):
		return false
	if not run.get("start") is Dictionary or not run.start.get("levels") is Dictionary or not run.start.get("groups") is Array:
		return false
	if not run.get("inputs") is Array or not run.get("result") is Dictionary:
		return false
	var last = run.result.get("ticks")
	if not (last is float or last is int) or int(last) < 0 or int(last) > MOST_TICKS:
		return false
	var previous := 0
	for input in run.inputs:
		if not input is Dictionary or not (input.get("tick") is float or input.get("tick") is int):
			return false
		var tick := int(input.tick)
		if tick < previous or tick > int(last):
			return false
		previous = tick
		if input.has("end"):
			continue
		# A row this version doesn't know would stop the game on an assert.
		if not input.get("buy") is String or not String(input.buy) in TowerData.rows():
			return false
		if not (input.get("count") is float or input.get("count") is int):
			return false
	return true


## Whether a replay ended where the recorded run did.
static func matches(run: Dictionary, sim: BattleSim) -> bool:
	var result: Dictionary = run.get("result", {})
	return (sim.ticks == int(result.get("ticks", -1)) and sim.wave == int(result.get("wave", -1))
		and sim.kills == int(result.get("kills", -1))
		and is_equal_approx(sim.cash_earned, float(result.get("cash_earned", -1.0)))
		and is_equal_approx(sim.coins, float(result.get("coins", -1.0)))
		and is_equal_approx(sim.health, float(result.get("health", -1.0))))
