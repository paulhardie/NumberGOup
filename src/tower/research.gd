extends RefCounted
## The Labs' saved jobs. Definitions are supplied by their catalogue when
## 1.2 ships; jobs freeze their paid cost, duration and resulting effects.
## No automatic next purchase and no battle-speed dependence.

const RunConfig = preload("res://src/tower/run_config.gd")
var slots := 1
var levels: Dictionary = {}
var completed_effects: Dictionary = {}
var jobs: Array[Dictionary] = []


func start(id: String, cost: float, seconds: float, effects: Array, workshop) -> bool:
	if id.is_empty() or jobs.size() >= slots or jobs.any(func(job): return job.id == id):
		return false
	if not is_finite(cost) or cost < 0.0 or not is_finite(seconds) or seconds <= 0.0:
		return false
	if not _effects_valid(effects):
		return false
	var pending: Array = jobs.duplicate(true)
	pending.append({"id": id, "effects": effects})
	if not _pending_valid(completed_effects, pending): return false
	if not workshop.spend_coins(cost):
		return false
	jobs.append({"id": id, "level": int(levels.get(id, 0)) + 1,
		"remaining": seconds, "cost": cost, "effects": effects.duplicate(true)})
	return true


func advance(seconds: float) -> Array[String]:
	var finished: Array[String] = []
	if not is_finite(seconds) or seconds <= 0.0:
		return finished
	var waiting: Array[Dictionary] = []
	for job in jobs:
		job.remaining = maxf(0.0, float(job.remaining) - seconds)
		if float(job.remaining) == 0.0:
			levels[job.id] = int(job.level)
			completed_effects[job.id] = job.effects.duplicate(true)
			finished.append(String(job.id))
		else:
			waiting.append(job)
	jobs = waiting
	return finished


func effects() -> Array:
	var result: Array = []
	var ids := completed_effects.keys()
	ids.sort()
	for id in ids:
		result.append_array(completed_effects[id].duplicate(true))
	return result


func to_dict() -> Dictionary:
	return {"slots": slots, "levels": levels.duplicate(), "effects": completed_effects.duplicate(true), "jobs": jobs.duplicate(true)}


func restore(data: Dictionary) -> void:
	slots = clampi(int(data.slots), 1, 5) if _number(data.get("slots")) else 1
	levels.clear()
	completed_effects.clear()
	jobs.clear()
	if data.get("levels") is Dictionary:
		for id in data.levels:
			if id is String and _number(data.levels[id]) and float(data.levels[id]) >= 0.0 and float(data.levels[id]) <= 9007199254740991.0 and float(data.levels[id]) == int(data.levels[id]):
				levels[id] = int(data.levels[id])
	if data.get("effects") is Dictionary:
		for id in data.effects:
			if id is String and data.effects[id] is Array and _effects_valid(data.effects[id]):
				completed_effects[id] = data.effects[id].duplicate(true)
	if data.get("jobs") is Array:
		for job in data.jobs:
			if jobs.size() >= slots:
				break
			if job is Dictionary and job.get("id") is String and not String(job.id).is_empty() \
					and _number(job.get("remaining")) and float(job.remaining) > 0.0 \
					and _number(job.get("cost")) and float(job.cost) >= 0.0 \
					and _number(job.get("level")) and float(job.level) == int(job.level) and int(job.level) == int(levels.get(job.id, 0)) + 1 \
					and job.get("effects") is Array and _effects_valid(job.effects) and not jobs.any(func(other): return other.id == job.id):
				jobs.append(job.duplicate(true))


static func _number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _effects_valid(effects: Array) -> bool:
	for effect in effects:
		if not effect is Dictionary or effect.get("domain", "stat") not in ["stat", "rule"] or not RunConfig.valid_effect(effect, effect.get("domain", "stat") == "rule"):
			return false
	return true


static func _build_valid(by_id: Dictionary) -> bool:
	var config := {"levels": {}, "groups": [], "effects": [], "rules": []}
	var ids := by_id.keys()
	ids.sort()
	for id in ids:
		for effect in by_id[id]:
			config["rules" if effect.get("domain", "stat") == "rule" else "effects"].append(effect)
	return RunConfig.valid(config)


## Jobs can finish in any order. Every reachable build must be supported,
## including a fast replacement before another job's reduction completes.
static func _pending_valid(completed: Dictionary, pending: Array) -> bool:
	if pending.size() > 5: return false
	for mask in range(1 << pending.size()):
		var candidate := completed.duplicate(true)
		for index in range(pending.size()):
			if mask & (1 << index): candidate[pending[index].id] = pending[index].effects
		if not _build_valid(candidate): return false
	return true
