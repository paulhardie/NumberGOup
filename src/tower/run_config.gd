extends RefCounted
## A run's frozen starting build, separate from the permanent collection.
## Version the combat contract independently of UI/build commits.
const TowerData = preload("res://src/tower/tower_data.gd")
const RunRules = preload("res://src/tower/run_rules.gd")
const StatStack = preload("res://src/tower/stat_stack.gd")
const VERSION := 1
const RULES_VERSION := 1


static func valid_effect(effect, rule := false) -> bool:
	if rule:
		return RunRules.valid(effect)
	return effect is Dictionary and effect.get("stat") in TowerData.rows() \
		and effect.get("op") in StatStack.OPS and effect.get("source") is String \
		and number(effect.get("value")) \
		and (effect.op != "multiply" or float(effect.value) >= 0.0)


static func valid(start) -> bool:
	if not start is Dictionary or not start.get("levels") is Dictionary or not start.get("groups") is Array:
		return false
	if start.has("version") and start.version != VERSION:
		return false
	if start.has("rules_version") and start.rules_version != RULES_VERSION:
		return false
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
