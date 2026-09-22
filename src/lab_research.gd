class_name LabResearch
extends RefCounted

## Labs (The Tower): permanent research paid in Coins and gated by real time,
## distinct from the Workshop's instant Coin purchases and from the Knowledge
## sheet's Research Focus / Insight / Prestige (D016), which spend Knowledge
## and are not time-gated. One line runs at a time to start, and more slots
## open with Gems (D029), so which to prioritise while the others wait is a
## real decision rather than a queue.
const LAB_SPEED_ID := "lab_speed"
const STARTING_SLOTS := 1
const MAX_SLOTS := 5
## Gems for the second, third, fourth and fifth slot. Starting proposals sized
## against a Card pull (20 Gems), like the Rig's and Labs' first numbers, until
## the owner's Gem economy pass (D027) replaces them.
const SLOT_GEM_COSTS := [20, 40, 80, 160]
## Every save from before slots were bought held two slots, and keeps them.
const LEGACY_SLOTS := 2

## How much one rank of Lab Speed shortens every other line's duration, and the
## floor that keeps a maxed Speed line a strong discount rather than "instant".
const SPEED_DURATION_STEP := 0.02
const SPEED_DURATION_FLOOR := 0.4

## One research line: a Coin cost ladder and a real-time duration ladder, each
## growing independently, plus the permanent effect a finished rank grants.
## Lines with no declared effect (Lab Speed) act on duration itself instead,
## the way Burst and Crit Chain read as a rank rather than a declared effect.
class Definition:
	var id: String
	var title: String
	var description: String
	var category: String
	var base_cost: int
	var cost_growth: float
	var base_duration: float
	var duration_growth: float
	var max_rank: int
	var effects: Dictionary

	func _init(
			definition_id: String,
			definition_title: String,
			definition_description: String,
			definition_category: String,
			starting_cost: int,
			coin_growth: float,
			starting_duration: float,
			time_growth: float,
			rank_cap: int,
			definition_effects: Dictionary
		) -> void:
		id = definition_id
		title = definition_title
		description = definition_description
		category = definition_category
		base_cost = starting_cost
		cost_growth = coin_growth
		base_duration = starting_duration
		duration_growth = time_growth
		max_rank = rank_cap
		effects = definition_effects

	func is_maxed(owned: int) -> bool:
		return owned >= max_rank

var definitions: Array[Definition] = []

func _init() -> void:
	definitions = _make_definitions()

func get_definition(research_id: String) -> Definition:
	for definition in definitions:
		if definition.id == research_id:
			return definition
	return null

## Gems for the next slot when `slots` are open, or 0 once every slot is.
func slot_cost(slots: int) -> int:
	var index := slots - STARTING_SLOTS
	if index < 0 or index >= SLOT_GEM_COSTS.size():
		return 0
	return int(SLOT_GEM_COSTS[index])

## Coins for the next rank. Whole Coins, like every other Coin cost.
func cost_at(definition: Definition, owned: int) -> int:
	return maxi(1, ceili(float(definition.base_cost) * pow(definition.cost_growth, float(owned))))

## Real seconds for the next rank. Lab Speed discounts every other line but
## never itself, so a maxed Speed line can still be re-run to prove the math.
func duration_at(definition: Definition, owned: int, speed_rank: int) -> float:
	var raw := definition.base_duration * pow(definition.duration_growth, float(owned))
	if definition.id == LAB_SPEED_ID:
		return raw
	var discount := clampf(float(speed_rank) * SPEED_DURATION_STEP, 0.0, 1.0 - SPEED_DURATION_FLOOR)
	return raw * (1.0 - discount)

## Starting proposals, in the same spirit as the Rig's RIG_COST_K (D015): sized
## by hand to feel like a background system rather than tuned by a simulator.
func _make_definitions() -> Array[Definition]:
	return [
		Definition.new(
			LAB_SPEED_ID, "LAB SPEED",
			"Every other line researches 2% faster per rank, to a floor of 60% of its time.",
			"main", 500, 1.8, 120.0, 1.5, 20, {}
		),
		Definition.new(
			"lab_damage", "DAMAGE RESEARCH",
			"All damage ×1.01 per rank.",
			ProgressionTaxonomy.ATTACK, 800, 1.7, 180.0, 1.55, 40,
			{"base_output_multiplier": 1.01}
		),
		Definition.new(
			"lab_resilience", "RESILIENCE RESEARCH",
			"Every hit is 0.5% smaller per rank.",
			ProgressionTaxonomy.DEFENSE, 800, 1.7, 180.0, 1.55, 40,
			{"collection_resistance": 0.005}
		),
		Definition.new(
			"lab_coin_research", "COIN RESEARCH",
			"+1% Coins from every wave beaten, per rank.",
			ProgressionTaxonomy.UTILITY, 1000, 1.7, 240.0, 1.55, 40,
			{"coin_bonus": 0.01}
		),
	]
