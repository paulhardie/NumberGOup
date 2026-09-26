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
			"bought": sim.run_levels.duplicate(), "enemies": sim.enemies.size(), "rng": sim.rng_state(),
		},
		"play": play.duplicate(true),
	}


## The longest run a saved record may claim, in ticks (a week of game time),
## so a damaged file can't set a replay running for ever.
const MOST_TICKS := 30 * 60 * 60 * 24 * 7


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
	# Bounded by the record's own last tick, however long the run.
	again.advance(1 << 62)
	return again.sim


## Whether a saved record has the shape a replay needs, with sane numbers,
## so a damaged save's run fails here rather than part way through a replay
## or while being resumed. Anything a replay or a resume reads is checked.
static func is_replayable(run) -> bool:
	if not run is Dictionary or not _is_number(run.get("seed")):
		return false
	var start = run.get("start")
	if not start is Dictionary or not start.get("levels") is Dictionary or not start.get("groups") is Array:
		return false
	for id in start.levels:
		if not id is String or not _is_number(start.levels[id]):
			return false
	for group in start.groups:
		if not group is String:
			return false
	var result = run.get("result")
	if not run.get("inputs") is Array or not result is Dictionary:
		return false
	for key in ["ticks", "wave", "kills", "cash", "cash_earned", "coins", "health"]:
		if not _is_number(result.get(key)):
			return false
	var last := int(result.ticks)
	if last < 0 or last > MOST_TICKS or not result.get("bought") is Dictionary:
		return false
	var previous := 0
	for input in run.inputs:
		if not input is Dictionary or not _is_number(input.get("tick")):
			return false
		var tick := int(input.tick)
		if tick < previous or tick > last:
			return false
		previous = tick
		if input.has("end"):
			continue
		# A row this version doesn't know would stop the game on an assert.
		if not input.get("buy") is String or not String(input.buy) in TowerData.rows() or not _is_number(input.get("count")):
			return false
	# A saved run in progress also carries the Coins it banked (never more than
	# it earned) and its play time.
	if run.has("banked") and (not _is_number(run.banked) or float(run.banked) < 0.0 or float(run.banked) > float(result.coins)):
		return false
	if run.has("play"):
		var play = run.play
		if not play is Dictionary or not _is_number(play.get("real_seconds", 0.0)) or not play.get("seconds_at_speed", {}) is Dictionary:
			return false
	return true


static func _is_number(value) -> bool:
	return (value is float or value is int) and is_finite(float(value))


## Whether a replay ended where the recorded run did: every input applied,
## the same Cash, levels and enemies, and, where the record has them, the
## random streams at the same place, so it drew exactly the same numbers. A
## rule or price that changed since shows up here.
static func matches(run: Dictionary, sim: BattleSim) -> bool:
	var result: Dictionary = run.get("result", {})
	if sim.inputs.size() != run.get("inputs", []).size():
		return false
	if not (sim.ticks == int(result.get("ticks", -1)) and sim.wave == int(result.get("wave", -1))
			and sim.kills == int(result.get("kills", -1))
			and is_equal_approx(sim.cash, float(result.get("cash", -1.0)))
			and is_equal_approx(sim.cash_earned, float(result.get("cash_earned", -1.0)))
			and is_equal_approx(sim.coins, float(result.get("coins", -1.0)))
			and is_equal_approx(sim.health, float(result.get("health", -1.0)))):
		return false
	var bought = result.get("bought", {})
	if not bought is Dictionary or bought.size() != sim.run_levels.size():
		return false
	for id in bought:
		if int(sim.run_levels.get(String(id), -1)) != int(bought[id]):
			return false
	# Records from before D078's review have no enemy count or streams.
	if result.has("enemies") and int(result.enemies) != sim.enemies.size():
		return false
	if result.has("rng") and Array(result.rng) != Array(sim.rng_state()):
		return false
	return true
