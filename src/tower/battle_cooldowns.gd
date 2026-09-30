extends RefCounted
## Simulation-owned named cooldowns, serialised with a battle snapshot.
## Existing defences and later Weapons advance these at their fixed tick
## positions; callers retain control of trigger order and repeating periods.

var remaining: Dictionary = {}


func set_time(id: String, seconds: float) -> void:
	assert(not id.is_empty() and is_finite(seconds))
	remaining[id] = seconds


func time_left(id: String) -> float:
	return float(remaining.get(id, 0.0))


func advance(id: String, seconds: float) -> float:
	assert(is_finite(seconds) and seconds >= 0.0)
	var left := time_left(id) - seconds
	remaining[id] = left
	return left
