extends RefCounted
## The Tower's own numbers, read from the generated data: enemies from
## data/tower/enemies.json (tools/import_tower_enemies.mjs) and the Workshop
## from data/workshop/upgrades.json (tools/import_tower_workshop.py).

const Guesses = preload("res://src/tower/guesses.gd")

const ENEMIES_PATH := "res://data/tower/enemies.json"
## The Tower's elites (D115): Vampire, Ray and Scatter.
const ELITES := ["vampire", "ray", "scatter"]
const WORKSHOP_PATH := "res://data/workshop/upgrades.json"

static var _enemies: Dictionary
static var _upgrades: Dictionary
static var _groups: Array


static func enemies() -> Dictionary:
	if _enemies.is_empty():
		_enemies = _load(ENEMIES_PATH)
	return _enemies


static func upgrade(id: String) -> Dictionary:
	if _upgrades.is_empty():
		for row in _load(WORKSHOP_PATH).upgrades:
			_upgrades[row.id] = row
	assert(_upgrades.has(id), "no Workshop row %s" % id)
	return _upgrades[id]


## Past the last generated wave the data holds its last value; generate more
## waves before any run can get there.
static func _per_wave(key: String, wave: int) -> float:
	var values: Array = enemies()[key]
	return float(values[clampi(wave, 1, values.size()) - 1])


static func enemy_health(wave: int, kind: String) -> float:
	return _per_wave("basic_health", wave) * float(enemies().types[kind].health)


static func enemy_attack(wave: int, kind: String) -> float:
	return _per_wave("basic_attack", wave) * float(enemies().types[kind].attack)


static func enemy_speed_m(wave: int, kind: String) -> float:
	return _per_wave("basic_speed", wave) * float(enemies().types[kind].speed) * Guesses.METRES_PER_SPEED


## A kind's mass as a share of a basic enemy's, which is how much less far
## Knockback pushes it.
static func mass_ratio(kind: String) -> float:
	return float(enemies().types[kind].mass) / float(enemies().types.basic.mass)


## How much heavier every enemy spawning on `wave` is than on wave 1: 1 until
## wave 4,000, then The Tower's growth (D115).
static func mass_growth(wave: int) -> float:
	return _per_wave("mass_growth", wave)


static func wave_seconds() -> float:
	return float(enemies().spawn_seconds) + float(enemies().cooldown_seconds)


static func spawn_seconds() -> float:
	return float(enemies().spawn_seconds)


static func is_boss_wave(wave: int, tier_number: int = 1) -> bool:
	return wave > 0 and wave % int(tier(tier_number).boss_every) == 0


## A tier's row (D107, D112): its enemy health and attack multipliers, Coins
## bonus, boss cadence, double-spawn chance and the weight on fast, tank and
## ranged spawns. Tiers past the generated ones hold the last.
static func tier(number: int) -> Dictionary:
	var rows: Array = enemies().tiers
	return rows[clampi(number, 1, rows.size()) - 1]


static func tier_count() -> int:
	return enemies().tiers.size()


## The wave's spawn rate, 0 to 100 (D114): the chance of an enemy on each
## spawn roll. The generated chart holds from its first wave, stepping up as
## The Tower's does; before it, straight lines join Guesses' wave-1 rate, the
## owner's readings and the chart's first point. The same in every tier.
static func spawn_rate(wave: int) -> float:
	var spawn: Dictionary = enemies().spawn
	var chart: Array = spawn.chart
	if wave >= int(chart[0].wave):
		var rate := float(chart[0].rate)
		for row in chart:
			if wave >= int(row.wave):
				rate = float(row.rate)
		return rate
	var points: Array = [{"wave": 1, "rate": Guesses.FIRST_WAVE_SPAWN_RATE}] + spawn.readings + [chart[0]]
	for index in range(1, points.size()):
		if wave <= int(points[index].wave):
			var from: Dictionary = points[index - 1]
			var to: Dictionary = points[index]
			var along := float(wave - int(from.wave)) / float(int(to.wave) - int(from.wave))
			return lerpf(float(from.rate), float(to.rate), clampf(along, 0.0, 1.0))
	return float(chart[0].rate)


## Seconds between spawn rolls in the spawning window.
static func spawn_roll_seconds() -> float:
	return float(enemies().spawn.roll_seconds)


## The most normal enemies (all but elites and bosses) on the field at once;
## a spawn due while it's full doesn't happen, as in The Tower.
static func enemy_cap() -> int:
	return int(enemies().enemy_cap)


## The most elites on the field at once, and of any one elite type; and of bosses.
static func elite_cap() -> int:
	return int(enemies().elite_cap)


static func elite_type_cap() -> int:
	return int(enemies().elite_type_cap)


static func boss_cap() -> int:
	return int(enemies().boss_cap)


## The Protector's share of a wave's spawns in `tier`, 0 to 100: none in Tier 1,
## then by the band of waves `wave` falls in (D115).
static func protector_chance(wave: int, tier_number: int) -> float:
	var chance := 0.0
	for band in tier(tier_number).protector:
		if wave >= int(band.wave):
			chance = float(band.chance)
	return chance


## How far round a Protector its shield reaches, in metres.
static func protector_radius_m(wave: int, tier_number: int) -> float:
	return _per_wave("protector_radius", wave) * float(tier(tier_number).protector_radius)


## The chance, 0 to 100, that each elite type sends one on `wave`, and once
## that is 100, the chance of a second: the Elite Spawn Chance chart's row
## for the tier (D115).
static func elite_chance(wave: int, tier_number: int) -> Dictionary:
	var chance := {"single": 0.0, "double": 0.0}
	for row in tier(tier_number).elites:
		if wave >= int(row.wave):
			chance = {"single": float(row.single), "double": float(row.double)}
	return chance


## The row's value at `level`; levels past the row's last hold its last value.
static func value(id: String, level: int) -> float:
	var values: Array = upgrade(id)["values"]
	return float(values[clampi(level, 0, values.size() - 1)])


static func max_level(id: String) -> int:
	return int(upgrade(id).max_rank)


## The Cash one more level costs, when the run has already bought `bought`
## of this row. Past the row's table there is nothing left to buy.
static func cash_price(id: String, bought: int) -> float:
	var prices: Array = upgrade(id)["cash_prices"]
	return float(prices[bought]) if bought < prices.size() else INF


## A multi-buy: `count` levels (fewer if `room` or the price list runs out),
## or for `count` 0 (Max) as many as `budget` covers. Levels are priced one at
## a time from `prices[first]` and summed, so a press costs exactly what the
## same levels cost bought singly. {levels, cost}; affording it is the caller's
## check, since a ×10 it can't afford still quotes its price.
static func plan_buy(prices: Array, first: int, room: int, count: int, budget: float) -> Dictionary:
	var most := room if count <= 0 else mini(count, room)
	var levels := 0
	var cost := 0.0
	while levels < most and first + levels < prices.size():
		var next := cost + float(prices[first + levels])
		if count <= 0 and next > budget:
			break
		cost = next
		levels += 1
	return {"levels": levels, "cost": cost}


## Every Workshop row, in The Tower's order.
static func rows() -> Array[String]:
	upgrade("damage")
	var ids: Array[String] = []
	ids.assign(_upgrades.keys())
	return ids


## Attack, Defense or Utility.
static func category(id: String) -> String:
	return String(upgrade(id).workshop_category)


static func group(id: String) -> String:
	return String(upgrade(id).group)


## The Coins one more Workshop level costs, from `level`.
static func coin_price(id: String, level: int) -> float:
	var prices: Array = upgrade(id)["coin_prices"]
	return float(prices[level]) if level < prices.size() else INF


## The Workshop's groups, in The Tower's order within each category:
## {id, workshop_category, order, unlock_coins}.
static func groups() -> Array:
	if _groups.is_empty():
		_groups = _load(WORKSHOP_PATH).groups
		_groups.sort_custom(func(a, b): return int(a.order) < int(b.order))
	return _groups


static func has_group(id: String) -> bool:
	return groups().any(func(entry): return String(entry.id) == id)


static func _group_entry(id: String) -> Dictionary:
	for entry in groups():
		if String(entry.id) == id:
			return entry
	assert(false, "no Workshop group %s" % id)
	return {}


static func group_price(id: String) -> float:
	return float(_group_entry(id).unlock_coins)


static func group_category(id: String) -> String:
	return String(_group_entry(id).workshop_category)


## The rows a group opens, in The Tower's order.
static func group_rows(id: String) -> Array[String]:
	var found: Array[String] = []
	for row in rows():
		if group(row) == id:
			found.append(row)
	return found


static func _load(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	assert(parsed is Dictionary, "could not read %s" % path)
	return parsed
