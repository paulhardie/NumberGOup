extends RefCounted
## Full fixed-tick battle state. Explicit field lists form the save contract;
## presentation events are intentionally absent. Reports still replay inputs.

const BattleSim = preload("res://src/tower/battle_sim.gd")
const RunConfig = preload("res://src/tower/run_config.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const VERSION := 2
const FLOATS := ["time", "wave_clock", "health", "cash", "cash_earned", "coins",
	"peak_drift", "kill_share", "overfill", "sure_divisor", "peak_number", "_high",
	"_shot_charge", "_health_skip", "_attack_skip", "locked_seconds", "divider_held", "_held_release"]
const INTS := ["ticks", "wave", "kills", "sure_from", "sure_every", "_sure_landed",
	"dividers_spawned", "dividers_landed", "_next_id", "health_level", "attack_level"]
const BOOLS := ["alive", "packages_to_best", "draining", "locked"]
const MAPS := ["run_levels", "lost_to", "gained_from", "raised_by", "damage_by", "kills_by"]
const ENEMY_FLOATS := ["health", "max_health", "attack", "speed", "angle", "distance",
	"stop_at", "hit_in", "last_distance", "rend", "divisor", "mass"]
const ENEMY_INTS := ["id", "wave", "hits", "generation"]
const SPAWN_INTS := ["next_spawn", "wave_spawned", "wave_missed", "protector_gate"]
## Our enemies, which The Tower's generated data doesn't list (D082, D133).
const OUR_KINDS := ["divider", "lock"]
## The Number-as-capital trial's state, and a carrier's, written only while
## the trial is in play (D152), so every other snapshot is byte for byte what
## it was and older ones stay valid.
const TRIAL_FLOATS := ["thief_held", "_thief_release", "thief_taken", "thief_recovered", "thief_escaped"]
const TRIAL_INTS := ["thefts", "thieves_escaped"]
const ENEMY_FLIGHT := ["carried", "carry_health", "carry_paid"]
## The fuel economy's ledger (D155), written only while it is on, the same way.
const FUEL_FLOATS := ["fuel_spent"]
const FUEL_INTS := ["shots_paid", "peak_wave"]
const FUEL_WAVE := ["income", "spent", "lost", "net"]
## The Number as Cash's state (D156), written only while it is on.
## Guesses.DIVIDER's numbers that may be 0: the slow refill, off (D134).


static func capture(sim: BattleSim) -> Dictionary:
	var state := {}
	for key in FLOATS + INTS + BOOLS + MAPS:
		var value = sim.get(key)
		state[key] = value.duplicate(true) if value is Dictionary else value
	state.killed_by = sim.killed_by
	state.divider = sim.divider.duplicate()
	state.lock = sim.lock.duplicate()
	state.cooldowns = sim.cooldowns.remaining.duplicate()
	if sim.trial_active():
		var trial := {}
		for key in TRIAL_FLOATS + TRIAL_INTS:
			trial[key] = sim.get(key)
		state.trial = trial
	if sim.fuel_active():
		var fuel := {"log": sim.fuel_log.duplicate(true)}
		for key in FUEL_FLOATS + FUEL_INTS:
			fuel[key] = sim.get(key)
		state.fuel = fuel
	if sim.number_cash:
		state.number_cash = {"ceiling": sim._ceiling, "free_levels": sim.free_levels.duplicate(),
			"paid_by": sim.paid_by.duplicate(), "locked_out": sim.locked_out, "lock_held": sim.lock_held}
	var targets := {}
	var field: Array = []
	for enemy in sim.enemies:
		field.append(enemy.id)
		targets[str(enemy.id)] = _enemy(enemy)
	var shots: Array = []
	for shot in sim.shots:
		# A killed target may still own a shot in flight until the next tick.
		targets[str(shot.target.id)] = _enemy(shot.target)
		shots.append({"target": shot.target.id, "position": _vector(shot.position),
			"last_position": _vector(shot.last_position), "damage": shot.damage,
			"critical": shot.critical, "bounces": shot.bounces, "struck": shot.struck.duplicate()})
	var spawns := {"schedule": sim.spawns.schedule.duplicate(true),
		"divider_due": sim.spawns.divider_due, "protector_due": sim.spawns._protector_due}
	for key in SPAWN_INTS:
		spawns[key] = sim.spawns.get(key)
	var data := {"version": VERSION, "start": sim.start_config(), "seed": str(sim.run_seed),
		"data_signature": TowerData.data_signature(),
		"current_effects": sim.stats.effects.duplicate(true), "current_rules": sim.rules.effects.duplicate(true),
		"state": state, "targets": targets, "field": field, "shots": shots,
		"spawns": spawns, "rng": sim.rng_state(), "inputs": sim.inputs.duplicate(true),
		"waves": sim.wave_log.duplicate(true),
		"defences": {"wall_health": sim.defences.wall_health,
			"orb_turns_first": sim.defences.orb_turns_first, "orb_hit_m": sim.defences.orb_hit_m,
			"mines": sim.defences.mines.map(func(mine): return _vector(mine))}}
	var packed := RunConfig.pack(data)
	packed.version = VERSION
	return packed


static func _enemy(enemy) -> Dictionary:
	var result := {"kind": enemy.kind}
	for key in ENEMY_FLOATS + ENEMY_INTS:
		result[key] = enemy.get(key)
	if enemy.fleeing:
		result.fleeing = true
		for key in ENEMY_FLIGHT:
			result[key] = enemy.get(key)
	return result


static func _vector(value: Vector2) -> Array:
	return [value.x, value.y]


static func valid(data) -> bool:
	if not data is Dictionary or data.get("version") != VERSION: return false
	return _valid_state(RunConfig.unpack(data))


static func _valid_state(data) -> bool:
	if not data is Dictionary or data.get("version") != VERSION or not RunConfig.valid(data.get("start")):
		return false
	if not RunReport.valid_seed(data.get("seed")) or not data.get("rng") is Array or data.rng.size() != 3:
		return false
	if data.get("data_signature") != TowerData.data_signature():
		return false
	var current: Dictionary = data.start.duplicate(true)
	current.effects = data.get("current_effects")
	current.rules = data.get("current_rules")
	if not RunConfig.valid(current): return false
	for rng in data.rng:
		if not rng is String or not RunReport.valid_seed(rng):
			return false
	var state = data.get("state")
	if not state is Dictionary:
		return false
	for key in FLOATS:
		if not RunConfig.number(state.get(key)):
			return false
	for key in INTS:
		if not _integer(state.get(key)):
			return false
	for key in BOOLS:
		if not state.get(key) is bool:
			return false
	for key in MAPS:
		if not _numeric_map(state.get(key)):
			return false
	if int(state.ticks) < 0 or int(state.ticks) > 30 * 60 * 60 * 24 * 7 or int(state.wave) < 1 \
			or int(state.sure_every) <= 0 or not state.get("killed_by") is String \
			or not _numeric_map(state.get("cooldowns")):
		return false
	if int(state.wave) > TowerData.last_wave() or int(state.health_level) < 1 or int(state.health_level) > int(state.wave) \
			or int(state.attack_level) < 1 or int(state.attack_level) > int(state.wave) or float(state._shot_charge) < 0.0 or float(state._shot_charge) > 128.0:
		return false
	for key in ["health", "cash", "cash_earned", "coins", "peak_number", "locked_seconds", "divider_held", "_held_release"]:
		if float(state[key]) < 0.0: return false
	var tuning := {}
	for key in RunConfig.default_tuning(): tuning[key] = state.get(key)
	if not RunConfig.valid_tuning(tuning): return false
	if state.has("trial"):
		var trial = state.trial
		if not trial is Dictionary: return false
		for key in TRIAL_FLOATS:
			if not RunConfig.number(trial.get(key)) or float(trial[key]) < 0.0: return false
		for key in TRIAL_INTS:
			if not _integer(trial.get(key)) or int(trial[key]) < 0: return false
	if state.has("number_cash"):
		var held = state.number_cash
		if not held is Dictionary or not RunConfig.number(held.get("ceiling")) or float(held.ceiling) < 0.0 \
				or not held.get("free_levels") is Dictionary or not held.get("paid_by", {}) is Dictionary \
				or not RunConfig.number(held.get("locked_out", 0.0)) or float(held.get("locked_out", 0.0)) < 0.0 \
				or not RunConfig.number(held.get("lock_held", 0.0)) or float(held.get("lock_held", 0.0)) < 0.0: return false
		for kind in held.get("paid_by", {}):
			if not RunConfig.number(held.paid_by[kind]) or float(held.paid_by[kind]) < 0.0: return false
		for id in held.free_levels:
			if id not in TowerData.rows() or not _integer(held.free_levels[id]) or int(held.free_levels[id]) < 0 \
					or int(held.free_levels[id]) > int(state.run_levels.get(id, 0)): return false
	if state.has("fuel"):
		var fuel = state.fuel
		if not fuel is Dictionary or not fuel.get("log") is Array or fuel.log.size() > int(state.wave): return false
		for key in FUEL_FLOATS:
			if not RunConfig.number(fuel.get(key)) or float(fuel[key]) < 0.0: return false
		for key in FUEL_INTS:
			if not _integer(fuel.get(key)) or int(fuel[key]) < 0: return false
		if int(fuel.peak_wave) < 1 or int(fuel.peak_wave) > int(state.wave): return false
		for logged in fuel.log:
			if not logged is Dictionary or not _integer(logged.get("wave")): return false
			for key in FUEL_WAVE:
				if not RunConfig.number(logged.get(key)): return false
	for id in state.run_levels:
		if id not in TowerData.rows() or not _integer(state.run_levels[id]) or int(state.run_levels[id]) < 0 \
				or int(state.run_levels[id]) + int(data.start.levels.get(id, 0)) > TowerData.max_level(id): return false
	if not data.get("targets") is Dictionary or not data.get("field") is Array \
			or data.field.size() > 2048 or data.targets.size() > 100000 \
			or not data.get("shots") is Array or data.shots.size() > 100000:
		return false
	for id in data.targets:
		var enemy = data.targets[id]
		if not id is String or not enemy is Dictionary or not enemy.get("kind") is String \
				or not _known_kind(enemy.kind):
			return false
		for key in ENEMY_FLOATS:
			if not RunConfig.number(enemy.get(key)):
				return false
		for key in ENEMY_INTS:
			if not _integer(enemy.get(key)):
				return false
		if id != str(int(enemy.id)) or int(enemy.id) <= 0 or float(enemy.max_health) <= 0.0:
			return false
		if int(enemy.wave) < 1 or int(enemy.wave) > int(state.wave) or float(enemy.mass) <= 0.0 or float(enemy.speed) < 0.0 or float(enemy.distance) < 0.0:
			return false
		if enemy.has("fleeing"):
			if not enemy.fleeing is bool or not enemy.fleeing: return false
			for key in ENEMY_FLIGHT:
				if not RunConfig.number(enemy.get(key)) or float(enemy[key]) < 0.0: return false
			if float(enemy.carry_health) <= 0.0 or float(enemy.carry_paid) > 1.0: return false
	var seen := {}
	for id in data.field:
		if not _integer(id) or not data.targets.has(str(int(id))) or seen.has(str(int(id))):
			return false
		seen[str(int(id))] = true
	for shot in data.shots:
		if not shot is Dictionary or not _integer(shot.get("target")) or not data.targets.has(str(int(shot.target))) \
				or not _valid_vector(shot.get("position")) or not _valid_vector(shot.get("last_position")) \
				or not RunConfig.number(shot.get("damage")) or not shot.get("critical") is bool \
				or not _integer(shot.get("bounces")) or int(shot.bounces) < -1 or int(shot.bounces) > 128 \
				or not shot.get("struck") is Array or shot.struck.size() > 129:
			return false
		for id in shot.struck:
			if not _integer(id):
				return false
	var spawns = data.get("spawns")
	if not spawns is Dictionary or not spawns.get("schedule") is Array \
			or not RunConfig.number(spawns.get("divider_due")) or not spawns.get("protector_due") is bool:
		return false
	for key in SPAWN_INTS:
		if not _integer(spawns.get(key)) or int(spawns[key]) < 0:
			return false
	if int(spawns.next_spawn) > spawns.schedule.size() or spawns.schedule.size() > 10000:
		return false
	var previous := -1.0
	for item in spawns.schedule:
		if not item is Dictionary or not item.get("kind") is String \
				or not _known_kind(item.kind) \
				or not RunConfig.number(item.get("at")) or float(item.at) < previous \
				or (item.has("angle") and not RunConfig.number(item.angle)):
			return false
		previous = float(item.at)
	var defences = data.get("defences")
	if not defences is Dictionary or not defences.get("mines") is Array or defences.mines.size() > 30:
		return false
	for key in ["wall_health", "orb_turns_first", "orb_hit_m"]:
		if not RunConfig.number(defences.get(key)):
			return false
	for mine in defences.mines:
		if not _valid_vector(mine):
			return false
	if not RunReport.valid_inputs(data.get("inputs"), int(state.ticks)) or not data.get("waves") is Array:
		return false
	for item in data.waves:
		if not item is Dictionary or not _numeric_map(item.get("bought", {})): return false
	return true


static func restore(data) -> BattleSim:
	if not data is Dictionary or data.get("version") != VERSION: return null
	data = RunConfig.unpack(data)
	if not _valid_state(data):
		return null
	var start: Dictionary = data.start
	var sim := BattleSim.new(int(data.seed), start.levels, start.groups, int(start.get("tier", 1)), start.get("effects", []), start.get("rules", []), start.get("tuning", {}))
	for key in FLOATS:
		sim.set(key, float(data.state[key]))
	for key in INTS:
		sim.set(key, int(data.state[key]))
	for key in BOOLS + MAPS:
		var value = data.state[key]
		sim.set(key, value.duplicate(true) if value is Dictionary else value)
	sim.killed_by = data.state.killed_by
	sim.divider = data.state.divider.duplicate()
	sim.lock = data.state.lock.duplicate()
	sim.cooldowns.remaining = data.state.cooldowns.duplicate()
	if data.state.has("trial"):
		for key in TRIAL_FLOATS:
			sim.set(key, float(data.state.trial[key]))
		for key in TRIAL_INTS:
			sim.set(key, int(data.state.trial[key]))
	if data.state.has("number_cash"):
		sim._ceiling = float(data.state.number_cash.ceiling)
		sim.free_levels = {}
		for id in data.state.number_cash.free_levels:
			sim.free_levels[id] = int(data.state.number_cash.free_levels[id])
		# Saves from before these were counted read as nothing yet.
		sim.paid_by = {}
		for kind in data.state.number_cash.get("paid_by", {}):
			sim.paid_by[kind] = float(data.state.number_cash.paid_by[kind])
		sim.locked_out = float(data.state.number_cash.get("locked_out", 0.0))
		sim.lock_held = float(data.state.number_cash.get("lock_held", 0.0))
	if data.state.has("fuel"):
		for key in FUEL_FLOATS:
			sim.set(key, float(data.state.fuel[key]))
		for key in FUEL_INTS:
			sim.set(key, int(data.state.fuel[key]))
		sim.fuel_log.clear()
		for logged in data.state.fuel.log:
			var entry := {"wave": int(logged.wave)}
			for key in FUEL_WAVE:
				entry[key] = float(logged[key])
			sim.fuel_log.append(entry)
	# Mid-run effects are state, not the frozen starting build.
	sim.stats = preload("res://src/tower/stat_stack.gd").new()
	for effect in data.get("current_effects", start.get("effects", [])):
		sim.stats.add(String(effect.stat), String(effect.op), float(effect.value), String(effect.source))
	sim.rules = preload("res://src/tower/run_rules.gd").new()
	for effect in data.get("current_rules", start.get("rules", [])):
		sim.rules.add(effect)
	var targets := {}
	for id in data.targets:
		var enemy := BattleSim.Enemy.new()
		enemy.kind = data.targets[id].kind
		for key in ENEMY_FLOATS:
			enemy.set(key, float(data.targets[id][key]))
		for key in ENEMY_INTS:
			enemy.set(key, int(data.targets[id][key]))
		if data.targets[id].has("fleeing"):
			enemy.fleeing = true
			for key in ENEMY_FLIGHT:
				enemy.set(key, float(data.targets[id][key]))
		targets[id] = enemy
	sim.enemies.clear()
	sim._protectors.clear()
	for id in data.field:
		var enemy = targets[str(int(id))]
		sim.enemies.append(enemy)
		if enemy.kind == "protector":
			sim._protectors.append(enemy)
	sim.shots.clear()
	for saved in data.shots:
		var shot := BattleSim.Shot.new()
		shot.target = targets[str(int(saved.target))]
		shot.position = Vector2(float(saved.position[0]), float(saved.position[1]))
		shot.last_position = Vector2(float(saved.last_position[0]), float(saved.last_position[1]))
		shot.damage = float(saved.damage)
		shot.critical = saved.critical
		shot.bounces = int(saved.bounces)
		for id in saved.struck:
			shot.struck.append(int(id))
		sim.shots.append(shot)
	for key in SPAWN_INTS:
		sim.spawns.set(key, int(data.spawns[key]))
	sim.spawns.schedule.clear()
	for item in data.spawns.schedule:
		sim.spawns.schedule.append(item.duplicate())
	sim.spawns.divider_due = float(data.spawns.divider_due)
	sim.spawns._protector_due = data.spawns.protector_due
	sim.spawns._spawn_rng.state = int(data.rng[0])
	sim._combat_rng.state = int(data.rng[1])
	sim.spawns._divider_rng.state = int(data.rng[2])
	sim.defences.wall_health = float(data.defences.wall_health)
	sim.defences.orb_turns_first = float(data.defences.orb_turns_first)
	sim.defences.orb_hit_m = float(data.defences.orb_hit_m)
	sim.defences.mines.clear()
	for mine in data.defences.mines:
		sim.defences.mines.append(Vector2(float(mine[0]), float(mine[1])))
	sim.inputs.clear()
	for item in data.inputs:
		sim.inputs.append(item.duplicate(true))
	sim.wave_log.clear()
	for item in data.waves:
		sim.wave_log.append(item.duplicate(true))
	return sim


static func _known_kind(kind: String) -> bool:
	return kind in OUR_KINDS or TowerData.enemies().types.has(kind)


static func _integer(value) -> bool:
	return RunConfig.number(value) and float(value) == int(value) and absf(float(value)) <= 9007199254740991.0


static func _numeric_map(value) -> bool:
	if not value is Dictionary:
		return false
	for key in value:
		if not key is String or not RunConfig.number(value[key]):
			return false
	return true


static func _valid_vector(value) -> bool:
	return value is Array and value.size() == 2 and RunConfig.number(value[0]) and RunConfig.number(value[1])
