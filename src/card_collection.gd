class_name CardCollection
extends RefCounted

## Cards (The Tower): a permanently-owned collection, pulled with Gems rather
## than bought outright, with a capped number of Active slots feeding the
## same effect pipeline Workshop and Labs use. Toned down from the reference
## on the owner's direction (D027): one flat per-level step per card rather
## than the reference's separate stars-and-levels split, no Mastery-into-Labs
## tie yet, and no named loadout presets — one Active set, swapped by hand.
## The owner is designing the Gem economy (pull cost, pity, sources)
## separately; PULL_COST_GEMS and the rarity weights below are placeholders
## until that pass, the same way the Rig's and Labs' first numbers were.

const MAX_LEVEL := 7
const PULL_COST_GEMS := 20
const ACTIVE_SLOTS := 4

const COMMON := "common"
const RARE := "rare"
## Weighted by rarity, uniform within a rarity. A placeholder shape, not a
## tuned one: the owner's economy pass decides the real odds and any pity.
const RARITY_WEIGHT := {
	COMMON: 70,
	RARE: 30,
}

## One card: a permanent, gacha-owned rank ladder capped at MAX_LEVEL, using
## the same declared-effect shape UpgradeDefinition and LabResearch.Definition
## already use, so it reads through the same generic effect pipeline.
class Definition:
	var id: String
	var title: String
	var description: String
	var rarity: String
	var effects: Dictionary

	func _init(
			definition_id: String,
			definition_title: String,
			definition_description: String,
			definition_rarity: String,
			definition_effects: Dictionary
		) -> void:
		id = definition_id
		title = definition_title
		description = definition_description
		rarity = definition_rarity
		effects = definition_effects

	func is_maxed(owned: int) -> bool:
		return owned >= MAX_LEVEL

var definitions: Array[Definition] = []

func _init() -> void:
	definitions = _make_definitions()

func get_definition(card_id: String) -> Definition:
	for definition in definitions:
		if definition.id == card_id:
			return definition
	return null

func definitions_for_rarity(rarity: String) -> Array[Definition]:
	var matching: Array[Definition] = []
	for definition in definitions:
		if definition.rarity == rarity:
			matching.append(definition)
	return matching

## Six cards to start, matching Labs' precedent of a small real catalogue
## over a large speculative one. Each reuses an existing effect key rather
## than inventing new mechanics, so a card is a new acquisition path onto
## stats the Workshop and Labs already touch, not a fourth kind of stat.
func _make_definitions() -> Array[Definition]:
	return [
		Definition.new("card_damage", "DAMAGE", "All damage ×1.025 per level.", COMMON, {"base_output_multiplier": 1.025}),
		Definition.new("card_attack_speed", "ATTACK SPEED", "Ticks come ×1.02 faster per level.", COMMON, {"tick_rate": 1.02}),
		Definition.new("card_coins", "COINS", "+1% Coins from every wave beaten, per level.", COMMON, {"coin_bonus": 0.01}),
		Definition.new("card_critical_chance", "CRITICAL CHANCE", "+0.5% critical chance per level.", COMMON, {"critical_chance": 0.005}),
		Definition.new("card_health", "HEALTH", "Begin every run with 5 extra Number per level.", RARE, {"starting_number_flat": 5.0}),
		Definition.new("card_extra_defense", "EXTRA DEFENSE", "Every hit is 0.3% smaller per level.", RARE, {"collection_resistance": 0.003}),
	]
