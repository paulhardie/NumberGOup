extends RefCounted
## A run's frozen starting build, separate from the permanent collection.
## Version the combat contract independently of UI/build commits.
const TowerData = preload("res://src/tower/tower_data.gd")
const RunRules = preload("res://src/tower/run_rules.gd")
const StatStack = preload("res://src/tower/stat_stack.gd")
const Guesses = preload("res://src/tower/guesses.gd")
const VERSION := 1
const RULES_VERSION := 2


static func default_tuning() -> Dictionary:
	return {"divider": Guesses.DIVIDER.duplicate(), "lock": Guesses.LOCK.duplicate(),
		"peak_drift": Guesses.PEAK_REGEN_DRIFT, "kill_share": Guesses.KILL_GROWTH,
		"overfill": Guesses.NUMBER_OVERFILL, "packages_to_best": false,
		"sure_from": 0, "sure_every": 5, "sure_divisor": 1.1}


## The Number-as-capital trial's measuring options (D152), the fuel
## economy's (D155), the Number as Cash (D156), and what each is when off. A run records one only while it is on, so every run and save made
## without them is byte for byte what it was.
static func trial_tuning() -> Dictionary:
	return {"thieves": false, "thief_recovery": 0.0, "thief_speed": 1.0, "thief_fade": 0.0,
		"thief_priority": false, "number_power": 0.0,
		"shot_price": 0.0, "bounty_share": 0.0, "free_bounty_share": 0.0, "base_regen": 0.0,
		"regen_scale": 1.0, "hold_doomed": false,
		"number_cash": false, "upgrades_off": false, "reserve_share": 0.0, "lock_holds_cash": false}


## The measuring tool is a real consumer: its starting switches must replay
## before the first wave is rolled, just like the normal game's build.
static func valid_tuning(tuning) -> bool:
	if not tuning is Dictionary: return false
	var defaults := default_tuning()
	var trial := trial_tuning()
	for key in tuning:
		if key not in defaults and key not in trial: return false
	var full := defaults.duplicate(true)
	full.merge(tuning, true)
	if not full.packages_to_best is bool: return false
	for key in ["peak_drift", "kill_share", "overfill", "sure_divisor"]:
		if not number(full[key]) or float(full[key]) < 0.0 or float(full[key]) > 1e6: return false
	if full.sure_divisor < 1.0: return false
	for key in ["sure_from", "sure_every"]:
		if not _integer(full[key], 0 if key == "sure_from" else 1): return false
	for key in ["divider", "lock"]:
		if not full[key] is Dictionary or full[key].size() != defaults[key].size(): return false
		for part in defaults[key]:
			if not number(full[key].get(part)) or float(full[key][part]) < 0.0 or float(full[key][part]) > 1e12: return false
	var divider: Dictionary = full.divider
	for key in ["from_wave", "full_wave"]:
		if not _integer(divider[key], 1): return false
	for key in ["divisor_step", "health_first", "health_full", "speed"]:
		if divider[key] <= 0.0: return false
	if divider.full_wave < divider.from_wave or divider.rate_first > 1.0 or divider.rate_full > 1.0 \
			or divider.divisor_first < 1.0 or divider.divisor_full < 1.0: return false
	var lock: Dictionary = full.lock
	for key in ["from_wave", "full_wave", "every_first", "every_full"]:
		if not _integer(lock[key], 0 if key == "from_wave" else 1): return false
	if not (lock.full_wave >= lock.from_wave and lock.health > 0.0): return false
	var options := {}
	for key in trial: options[key] = tuning.get(key, trial[key])
	for key in ["thieves", "thief_priority", "hold_doomed", "number_cash", "upgrades_off", "lock_holds_cash"]:
		if not options[key] is bool: return false
	for key in ["thief_recovery", "thief_fade", "shot_price", "bounty_share", "base_regen", "regen_scale"]:
		if not number(options[key]) or float(options[key]) < 0.0 or float(options[key]) > 1e6: return false
	# The free killers' share is capped at half a shot kill's (THE_NUMBER.md 11.14).
	if not number(options.free_bounty_share) or float(options.free_bounty_share) < 0.0 or float(options.free_bounty_share) > 0.5: return false
	if not number(options.reserve_share) or float(options.reserve_share) < 0.0 or float(options.reserve_share) >= 1.0: return false
	if not number(options.thief_speed) or float(options.thief_speed) <= 0.0 or float(options.thief_speed) > 1e3: return false
	return number(options.number_power) and float(options.number_power) >= 0.0 and float(options.number_power) <= 4.0


static func _integer(value, minimum: int) -> bool:
	return number(value) and float(value) >= minimum and float(value) <= 100000.0 and float(value) == int(value)


static func valid_effect(effect, rule := false) -> bool:
	if rule:
		return RunRules.valid(effect)
	return effect is Dictionary and effect.get("stat") in TowerData.rows() \
		and effect.get("op") in StatStack.OPS and effect.get("source") is String \
		and number(effect.get("value")) \
		and (effect.op != "multiply" or float(effect.value) >= 0.0)


static func valid(start, allow_old_rules := false) -> bool:
	if not start is Dictionary or not start.get("levels") is Dictionary or not start.get("groups") is Array:
		return false
	if start.has("version") and start.version != VERSION:
		return false
	if start.has("rules_version"):
		if not _integer(start.rules_version, 1) or start.rules_version > RULES_VERSION \
				or (not allow_old_rules and start.rules_version != RULES_VERSION): return false
	if not valid_tuning(start.get("tuning", {})): return false
	if not number(start.get("tier", 1)) or float(start.get("tier", 1)) != int(start.get("tier", 1)) \
			or int(start.get("tier", 1)) < 1 or int(start.get("tier", 1)) > TowerData.tier_count():
		return false
	for id in start.levels:
		var rank = start.levels[id]
		if not id is String or id not in TowerData.rows() or not number(rank) \
				or float(rank) != int(rank) or int(rank) < 0 or int(rank) > TowerData.max_level(id):
			return false
	for group in start.groups:
		if not group is String or not TowerData.has_group(group):
			return false
	for domain in ["effects", "rules"]:
		var effects = start.get(domain, [])
		if not effects is Array:
			return false
		var rule_stack := RunRules.new()
		var stat_stack := StatStack.new()
		for effect in effects:
			if not valid_effect(effect, domain == "rules"):
				return false
			if domain == "rules":
				if not rule_stack.add(effect): return false
			elif not stat_stack.add(String(effect.stat), String(effect.op), float(effect.value), String(effect.source)):
				return false
	return true


static func number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))


## Godot's decimal JSON parser can round a double by one bit. The bounded
## object-free Variant payload preserves exact numbers and typed arrays.
static func pack(data: Dictionary) -> Dictionary:
	var payload := Marshalls.raw_to_base64(var_to_bytes(data))
	return {"encoding": 1, "payload": payload, "digest": payload.sha256_text()}


static func unpack(record):
	if not record is Dictionary or record.get("encoding") != 1 or not record.get("payload") is String \
			or record.payload.length() > 30000000 or not record.get("digest") is String \
			or record.payload.sha256_text() != record.digest:
		return null
	var data = bytes_to_var(Marshalls.base64_to_raw(record.payload))
	return data if data is Dictionary else null
