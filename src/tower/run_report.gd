extends RefCounted
## One run as the activity log keeps it (D077): enough to replay it exactly,
## that is the seed, the Workshop it started from and every input with its tick,
## plus how it stood at each wave's end and how it ended. A replay only
## matches on the game version that recorded it; the wave snapshots still
## read after the rules change.

const BattleSim = preload("res://src/tower/battle_sim.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const RunConfig = preload("res://src/tower/run_config.gd")


## `play` is what only the screen knows: real seconds played, seconds at each
## game speed.
static func build(sim: BattleSim, play: Dictionary = {}) -> Dictionary:
	return {
		"kind": "run",
		"seed": str(sim.run_seed),
		"start": sim.start_config(),
		"commands": RunConfig.pack({"start": sim.start_config(), "inputs": sim.inputs.duplicate(true)}),
		"inputs": sim.inputs.duplicate(true),
		"waves": sim.wave_log.duplicate(true),
		"result": {
			"wave": sim.wave, "time": sim.time, "ticks": sim.ticks, "killed_by": sim.killed_by,
			"closed_mid_run": sim.alive, "health": sim.health, "cash": sim.cash,
			"cash_earned": sim.cash_earned, "coins": sim.coins, "kills": sim.kills,
			"bought": sim.run_levels.duplicate(), "enemies": sim.enemies.size(), "rng": sim.rng_state(),
			"peak_number": sim.peak_number, "lost_to": sim.lost_to.duplicate(),
			"dividers": {"spawned": sim.dividers_spawned, "landed": sim.dividers_landed},
			"gained_from": sim.gained_from.duplicate(), "raised_by": sim.raised_by.duplicate(),
			"damage_by": sim.damage_by.duplicate(), "kills_by": sim.kills_by.duplicate(),
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
		var commands = RunConfig.unpack(run.get("commands"))
		_inputs = commands.inputs if commands is Dictionary else run.get("inputs", [])
		_last = int(run.get("result", {}).get("ticks", 0))
		var start: Dictionary = commands.start if commands is Dictionary else run.get("start", {})
		var levels := {}
		var saved_levels: Dictionary = start.get("levels", {})
		for id in saved_levels:
			levels[String(id)] = int(saved_levels[id])
		var groups: Array = []
		for group in start.get("groups", []):
			groups.append(String(group))
		# The seed must go back to an int: the RNGs are seeded from its hash.
		# Runs recorded with the testing switches (D097, D098) kept them in
		# "switches"; the rules they tested are now the game's or gone (D111),
		# so those runs replay only on the commits that recorded them, as any does.
		sim = BattleSim.new(int(run.get("seed", 0)), levels, groups, int(start.get("tier", 1)), start.get("effects", []), start.get("rules", []), start.get("tuning", {}))

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
			elif input.has("effect"):
				sim.apply_effect(input.effect, String(input.domain))
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
	return valid_record(run)


## Older declared rules may be read for end-run recovery, never asserted as
## equivalent to today's combat. Legacy unversioned runs still compare a replay.
static func valid_record(run, allow_old_rules := false) -> bool:
	if not run is Dictionary or not valid_seed(run.get("seed")):
		return false
	var start = run.get("start")
	if not RunConfig.valid(start, allow_old_rules):
		return false
	var result = run.get("result")
	if not run.get("inputs") is Array or not result is Dictionary:
		return false
	if run.has("commands") and not commands_match(run, allow_old_rules): return false
	for key in ["ticks", "wave", "kills", "cash", "cash_earned", "coins", "health"]:
		if not _is_number(result.get(key)):
			return false
	for key in ["ticks", "wave", "kills"]:
		if float(result[key]) < 0.0 or float(result[key]) > 9007199254740991.0 or float(result[key]) != int(result[key]): return false
	if result.wave < 1 or result.wave > TowerData.last_wave(): return false
	if result.has("enemies"):
		if not _is_number(result.enemies) or float(result.enemies) < 0.0 or float(result.enemies) > 2048.0 \
				or float(result.enemies) != int(result.enemies): return false
	if result.has("rng"):
		if not result.rng is Array or result.rng.size() != 3: return false
		for state in result.rng:
			if not state is String or not valid_seed(state): return false
	if result.has("peak_number") and (not _is_number(result.peak_number) or float(result.peak_number) < 0.0): return false
	var last := int(result.ticks)
	if last < 0 or last > MOST_TICKS or not result.get("bought") is Dictionary:
		return false
	for id in result.bought:
		var count = result.bought[id]
		if id not in TowerData.rows() or not _is_number(count) or float(count) < 0.0 \
				or float(count) > TowerData.max_level(id) or float(count) != int(count): return false
	if not valid_inputs(run.inputs, last):
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


static func commands_match(run: Dictionary, allow_old_rules := false) -> bool:
	if not run.get("result") is Dictionary: return false
	var tick = run.result.get("ticks")
	if not _is_number(tick) or float(tick) < 0.0 or float(tick) > MOST_TICKS or float(tick) != int(tick): return false
	var commands = RunConfig.unpack(run.get("commands"))
	if not commands is Dictionary or not RunConfig.valid(commands.get("start"), allow_old_rules) or not valid_inputs(commands.get("inputs"), int(tick)): return false
	return _json_view(commands.start) == _json_view(run.get("start")) and _json_view(commands.inputs) == _json_view(run.get("inputs"))


static func _json_view(value) -> String:
	var json := JSON.new()
	if json.parse(JSON.stringify(value, "", true, true)) != OK: return "invalid"
	return JSON.stringify(json.data, "", true, true)


static func valid_seed(value) -> bool:
	return (value is String and value.is_valid_int() and str(int(value)) == value) or (_is_number(value) and absf(float(value)) <= 9007199254740991.0 and float(value) == int(value))


static func valid_inputs(inputs, last: int) -> bool:
	if not inputs is Array or inputs.size() > 100000:
		return false
	var previous := 0
	for input in inputs:
		if not input is Dictionary or not _is_number(input.get("tick")) or float(input.tick) != int(input.tick):
			return false
		var tick := int(input.tick)
		if tick < previous or tick > last:
			return false
		previous = tick
		if input.has("end"):
			if input.end != true: return false
		elif input.has("effect"):
			if input.get("domain") not in ["stat", "rule"] or not RunConfig.valid_effect(input.effect, input.domain == "rule"): return false
		elif not input.get("buy") is String or input.buy not in TowerData.rows() or not _is_number(input.get("count")) or float(input.count) != int(input.count) or float(input.count) < 0.0 or float(input.count) > TowerData.max_level(input.buy):
			return false
	return true


static func _is_number(value) -> bool:
	return (value is float or value is int) and is_finite(float(value))


## Whether a replay ended where the recorded run did: every input applied,
## the same Cash, levels and enemies, and, where the record has them, the
## random streams at the same place, so it drew exactly the same numbers. A
## rule or price that changed since shows up here.
static func matches(run: Dictionary, sim: BattleSim) -> bool:
	if sim == null or not valid_record(run): return false
	if run.has("commands") and not commands_match(run): return false
	var start: Dictionary = run.get("start", {})
	if run.has("commands"): start = RunConfig.unpack(run.commands).start
	var config := sim.start_config()
	var expected := {}
	for key in config: expected[key] = start.get(key, {"version": RunConfig.VERSION, "rules_version": RunConfig.RULES_VERSION, "tier": 1, "effects": [], "rules": [], "tuning": RunConfig.default_tuning()}.get(key))
	if _json_view(config) != _json_view(expected) or _json_view(sim.inputs) != _json_view(run.get("inputs", [])):
		return false
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
