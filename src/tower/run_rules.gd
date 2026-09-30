extends RefCounted
## Non-Workshop rules needed by the next Cards and Labs. Effects keep their
## source, use the stat stack's add-then-multiply order and reject unknowns.

const Guesses = preload("res://src/tower/guesses.gd")
const DEFAULTS := {"starting_cash": Guesses.STARTING_CASH, "interest_cap": 50.0, "basic_coins": Guesses.COINS_BY_TYPE.basic, "cash_multiplier": 1.0, "coin_multiplier": 1.0}
const MAX_VALUE := 1e30
var effects: Array[Dictionary] = []


func add(effect: Dictionary) -> bool:
	if not valid(effect):
		return false
	effects.append(effect.duplicate(true))
	if not is_finite(value(String(effect.stat))) or value(String(effect.stat)) > MAX_VALUE:
		effects.pop_back()
		return false
	return true


static func valid(effect) -> bool:
	return effect is Dictionary and effect.get("stat") in DEFAULTS \
		and effect.get("op") in ["add", "multiply"] and effect.get("source") is String \
		and (effect.get("value") is int or effect.get("value") is float) \
		and is_finite(float(effect.value)) and float(effect.value) >= 0.0


func value(id: String) -> float:
	assert(id in DEFAULTS)
	var add := 0.0
	var multiplier := 1.0
	for effect in effects:
		if effect.stat == id:
			if effect.op == "add":
				add += float(effect.value)
			else:
				multiplier *= float(effect.value)
	return (float(DEFAULTS[id]) + add) * multiplier
