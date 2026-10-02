extends RefCounted
## The player's Cards (D146): The Tower's card table from the generated data
## (data/cards/cards.json, tools/import_tower_cards.py), and what this player
## owns of it. A card is bought for Gems as a random draw, rarity first, then
## a card of that rarity; each copy counts towards its next level, seven in
## all. Slots, the first free and the rest bought with Gems, limit how many
## are equipped. Equipped cards' effects go into a run's frozen starting build
## through Progression.run_effects, so a run keeps the cards it began with.
## What each card does in a run is ours, in EFFECTS; a card not there isn't
## built, so it is never drawn and the screen doesn't offer it.

const RunConfig = preload("res://src/tower/run_config.gd")

const DATA_PATH := "res://data/cards/cards.json"
const RARITIES := ["common", "rare", "epic"]

## What each built card does, at its level's value from the data: a Workshop
## stat it multiplies or adds to (StatStack), or a run rule (RunRules, with
## "domain": "rule"). The Tower's wording, from its card table:
## - Damage, Attack Speed, Health, Health Regen, Range, Fortress (Defense
##   Absolute): multiply that stat.
## - Cash, Coins: multiply all Cash or Coins earned.
## - Critical Chance, Extra Defense (Defense %): add their share.
## - Free Upgrades: adds its share to each of the three free upgrade chances.
## The others wait for the rules they need (docs/CARDS.md).
const EFFECTS := {
	"damage": [{"stat": "damage", "op": "multiply"}],
	"attack_speed": [{"stat": "attack_speed", "op": "multiply"}],
	"health": [{"stat": "health", "op": "multiply"}],
	"health_regen": [{"stat": "health_regen", "op": "multiply"}],
	"range": [{"stat": "range", "op": "multiply"}],
	"cash": [{"domain": "rule", "stat": "cash_multiplier", "op": "multiply"}],
	"coins": [{"domain": "rule", "stat": "coin_multiplier", "op": "multiply"}],
	"critical_chance": [{"stat": "critical_chance", "op": "add"}],
	"extra_defense": [{"stat": "defense_percent", "op": "add"}],
	"fortress": [{"stat": "defense_absolute", "op": "multiply"}],
	"free_upgrades": [{"stat": "free_attack_upgrade", "op": "add"}, {"stat": "free_defense_upgrade", "op": "add"},
		{"stat": "free_utility_upgrade", "op": "add"}],
}

## Cards under test (the card test series, docs/CARDS.md): measured with
## sim_runs.gd --cards, never drawn, listed, equipped or saved. Two are The
## Tower's, valued from its table; the rest are ours, with their own values,
## scaled as The Tower's nearest cards are. The rules they need live in
## RunRules and BattleSim, inert without them.
const CANDIDATES := {
	"slow_aura": {"effects": [{"domain": "rule", "stat": "slow_aura", "op": "add"}]},
	"critical_coin": {"effects": [{"domain": "rule", "stat": "critical_coin", "op": "add"}]},
	"compound": {"name": "Compound", "rarity": "common", "unit": "multiplier", "description": "Clean kills grow the Number by [x]",
		"values": [1.5, 2.0, 2.4, 2.8, 3.2, 3.6, 4.0], "effects": [{"domain": "rule", "stat": "kill_growth", "op": "multiply"}]},
	"remainder": {"name": "Remainder", "rarity": "rare", "unit": "multiplier", "description": "A landed ÷ takes [x] of its share",
		"values": [0.85, 0.8, 0.75, 0.7, 0.65, 0.6, 0.5], "effects": [{"domain": "rule", "stat": "divide_share", "op": "multiply"}]},
	"unequal": {"name": "Unequal", "rarity": "common", "unit": "multiplier", "description": "Shots deal [x] damage to a Lock",
		"values": [2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0], "effects": [{"domain": "rule", "stat": "lock_damage", "op": "multiply"}]},
	"interest": {"name": "Interest", "rarity": "common", "unit": "count", "description": "Raises the interest cap by $[x] a wave",
		"values": [25.0, 50.0, 75.0, 100.0, 150.0, 200.0, 250.0], "effects": [{"domain": "rule", "stat": "interest_cap", "op": "add"}]},
}

static var _data: Dictionary
static var _by_id: Dictionary

## Copies owned of each card, by id; a card not here isn't owned.
var copies: Dictionary = {}
## Slots bought, the free first one included.
var slots := 1
## The equipped cards' ids, in the order they were equipped.
var equipped: Array[String] = []


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		for card in _data.cards:
			_by_id[card.id] = card
	return _data


static func card(id: String) -> Dictionary:
	data()
	return _by_id.get(id, {})


## Every card in The Tower's table, in its order.
static func all_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in data().cards:
		ids.append(String(entry.id))
	return ids


## A card's name, rarity, unit and values: The Tower's table, or a
## candidate's own (CANDIDATES), or empty.
static func definition(id: String) -> Dictionary:
	if not card(id).is_empty():
		return card(id)
	var candidate: Dictionary = CANDIDATES.get(id, {})
	return candidate if candidate.has("values") else {}


static func candidate(id: String) -> bool:
	return CANDIDATES.has(id) and not definition(id).is_empty()


## The effects of card `id` at `level`, built or candidate, each naming its
## card as its source.
static func effects_at(id: String, level: int) -> Array:
	var result := []
	for effect in EFFECTS.get(id, CANDIDATES.get(id, {}).get("effects", [])):
		var built_effect: Dictionary = effect.duplicate()
		built_effect.value = value_at(id, level)
		built_effect.source = "card:" + id
		if not built_effect.has("domain"):
			built_effect.domain = "stat"
		result.append(built_effect)
	return result


static func built(id: String) -> bool:
	return EFFECTS.has(id) and not card(id).is_empty()


## The built cards, in the table's order: what a draw can give and the
## screen lists.
static func built_ids() -> Array[String]:
	return all_ids().filter(func(id): return built(id))


static func max_level() -> int:
	return data().copies_to_level.size()


static func max_slots() -> int:
	return data().slot_gems.size()


static func price() -> int:
	return int(data().price_gems)


## A card's level from its copies: 0 until the first, then one more at each
## of the data's copy counts.
static func level_for(count: int) -> int:
	var level := 0
	for needed in data().copies_to_level:
		if count >= int(needed):
			level += 1
	return level


## A card's value at `level` (1 to 7) in the data's units.
static func value_at(id: String, level: int) -> float:
	return float(definition(id).values[clampi(level, 1, max_level()) - 1])


func level(id: String) -> int:
	return level_for(int(copies.get(id, 0)))


func owned(id: String) -> bool:
	return int(copies.get(id, 0)) > 0


func maxed(id: String) -> bool:
	return level(id) >= max_level()


## Copies towards the next level, and how many it takes, counted from this
## level's: [have, need]; [0, 0] once maxed.
func progress(id: String) -> Array[int]:
	if maxed(id):
		return [0, 0]
	var counts: Array = data().copies_to_level
	var have := int(copies.get(id, 0))
	var from := 0 if level(id) == 0 else int(counts[level(id) - 1])
	return [have - from, int(counts[level(id)]) - from]


func value(id: String) -> float:
	return value_at(id, level(id))


## The Gems the next slot costs; -1 when every slot is bought, or there are
## already as many slots as built cards to fill them.
func slot_price() -> int:
	return -1 if slots >= mini(max_slots(), built_ids().size()) else int(data().slot_gems[slots])


## What a draw can give: built cards not yet maxed.
func drawable(id: String) -> bool:
	return built(id) and not maxed(id)


func can_draw() -> bool:
	return built_ids().any(func(id): return drawable(id))


## Each rarity's chance on the next draw (D146): The Tower's odds among the
## rarities that still have a card to give, in proportion; empty when nothing
## can be drawn. What the screen shows is what a draw uses.
func odds() -> Dictionary:
	var weights := {}
	var total := 0.0
	for rarity in RARITIES:
		if built_ids().any(func(id): return drawable(id) and card(id).rarity == rarity):
			weights[rarity] = float(data().odds[rarity])
			total += weights[rarity]
	for rarity in weights:
		weights[rarity] /= total
	return weights


## A draw (D146): a rarity by `odds`, then one of that rarity's cards evenly.
## Adds a copy and returns its id, or "" when nothing can be drawn. Paying for
## it is the caller's (Progression.draw_card).
func draw(rng: RandomNumberGenerator) -> String:
	var weights := odds()
	if weights.is_empty():
		return ""
	var roll := rng.randf()
	var rarity: String = weights.keys()[-1]
	for each in weights:
		if roll < weights[each]:
			rarity = each
			break
		roll -= weights[each]
	var pool := built_ids().filter(func(id): return drawable(id) and card(id).rarity == rarity)
	var id: String = pool[rng.randi_range(0, pool.size() - 1)]
	copies[id] = int(copies.get(id, 0)) + 1
	return id


func is_equipped(id: String) -> bool:
	return id in equipped


func can_equip(id: String) -> bool:
	return built(id) and owned(id) and not is_equipped(id) and equipped.size() < slots


func equip(id: String) -> bool:
	if not can_equip(id):
		return false
	equipped.append(id)
	return true


func unequip(id: String) -> bool:
	if not is_equipped(id):
		return false
	equipped.erase(id)
	return true


## The equipped cards' effects at their levels, each naming its card as its
## source, for a run's starting build.
func effects() -> Array:
	var result := []
	for id in equipped:
		# Only built cards reach a run; a candidate is the sim's alone.
		if built(id):
			result.append_array(effects_at(id, level(id)))
	return result


func to_dict() -> Dictionary:
	return {"copies": copies.duplicate(), "slots": slots, "equipped": equipped.duplicate()}


## Takes what a save holds, keeping only what's sound: known cards with a
## whole number of copies up to a maxed card's, slots within the table, and
## owned, built cards equipped once each within the slots. Anything dropped
## shows as a difference from the save, which Save treats as damage.
func restore(saved) -> void:
	copies.clear()
	slots = 1
	equipped.clear()
	if not saved is Dictionary:
		return
	var most := int(data().copies_to_level[-1])
	if saved.get("copies") is Dictionary:
		for id in saved.copies:
			var count = saved.copies[id]
			if id is String and not card(id).is_empty() and RunConfig.number(count) and float(count) == int(count) \
					and int(count) >= 1 and int(count) <= most:
				copies[id] = int(count)
	var bought = saved.get("slots", 1)
	if RunConfig.number(bought) and float(bought) == int(bought) and int(bought) >= 1 and int(bought) <= max_slots():
		slots = int(bought)
	if saved.get("equipped") is Array:
		for id in saved.equipped:
			if id is String and can_equip(id):
				equipped.append(id)
