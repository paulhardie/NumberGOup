extends RefCounted
## How a stat's value is built in a run (D119): the Workshop row's value at
## its level, then every effect on it in The Tower's order, then the stat's
## hard cap. The Tower builds its stats this way (the community wiki's
## formulas, for example Attack Speed = (Workshop × Lab × Card + module) ×
## Enhancement, and Defense % summing every source up to 98%):
## - "add" effects are added to the Workshop value, as the cards and labs that
##   add a share do (Extra Defense's Defense %, a lab's Wall Health);
## - "multiply" effects multiply that sum, as Labs, Cards and Perks multiply
##   Damage, Health or Cash Bonus.
## The Tower's later stages, a module's add after the multipliers and
## Enhancements multiplying that, wait for Modules and Enhancements (AGENTS.md
## law 8). Nothing adds effects yet: Cards (1.1) and Labs (1.2) will, before a
## run's first step, and a run's record must then carry them for its replay.

const TowerData = preload("res://src/tower/tower_data.gd")

const OPS := ["add", "multiply"]
## Hard caps no source passes, as [lowest, highest]: The Tower's, from the
## wiki and TheTowerSDK's reading of the game (TOWER_RULES.md, "Hard caps").
## The Workshop alone never reaches them.
const HARD_CAPS := {
	"defense_percent": [0.0, 0.98],
	"thorns": [0.0, 0.99],
	"shockwave_frequency": [7.0, INF],
	"wall_rebuild": [150.0, INF],
}

## Every effect as it was given, {stat, op, value, source}, for the run's
## record and for the screens to explain a value.
var effects: Array[Dictionary] = []
## Stat → the sum of its adds, and the product of its multipliers.
var _adds: Dictionary = {}
var _multipliers: Dictionary = {}


## Puts an effect on `stat` (a Workshop row id) from `source` (for example
## "card:damage"); false, and nothing changes, if the row or op is unknown or
## the value isn't a finite number.
func add(stat: String, op: String, value: float, source: String) -> bool:
	if op not in OPS or not is_finite(value) or stat not in TowerData.rows():
		return false
	if op == "add":
		_adds[stat] = float(_adds.get(stat, 0.0)) + value
	else:
		_multipliers[stat] = float(_multipliers.get(stat, 1.0)) * value
	effects.append({"stat": stat, "op": op, "value": value, "source": source})
	return true


## `stat`'s value built from `base`, its Workshop value at its level. With no
## effects and under its caps it is `base` exactly.
func value(stat: String, base: float) -> float:
	var built := base
	if _adds.has(stat):
		built += float(_adds[stat])
	if _multipliers.has(stat):
		built *= float(_multipliers[stat])
	var cap = HARD_CAPS.get(stat)
	if cap != null:
		built = clampf(built, float(cap[0]), float(cap[1]))
	return built
