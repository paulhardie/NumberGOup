extends RefCounted
## The Tower's own numbers, read from the generated data: enemies from
## data/tower/enemies.json (tools/import_tower_enemies.mjs) and the Workshop
## from data/workshop/upgrades.json (tools/import_tower_workshop.py).

const Guesses = preload("res://src/tower/guesses.gd")

const ENEMIES_PATH := "res://data/tower/enemies.json"
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


static func wave_seconds() -> float:
	return float(enemies().spawn_seconds) + float(enemies().cooldown_seconds)


static func spawn_seconds() -> float:
	return float(enemies().spawn_seconds)


static func is_boss_wave(wave: int) -> bool:
	return wave > 0 and wave % int(enemies().boss_every) == 0


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
