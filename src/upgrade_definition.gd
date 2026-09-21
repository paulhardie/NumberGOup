class_name UpgradeDefinition
extends RefCounted

var id: String
var title: String
var description: String
var cost: ScientificNumber
var unlock_lifetime: ScientificNumber
## The progression layer this row belongs to: "workshop" (Coins) or
## "knowledge" (Insight). Distinct from workshop_category, which is the shelf
## a Workshop row sits on.
var category: String
var progression_type: String
## One of ProgressionTaxonomy.WORKSHOP_CATEGORIES, or "" for a non-Workshop row.
var workshop_category: String
var max_rank: int
var workshop_level_required: int
var effects: Dictionary
var repeatable: bool
var cost_growth: float

func _init(
		upgrade_id: String,
		upgrade_title: String,
		upgrade_description: String,
		upgrade_cost: ScientificNumber,
		unlock_at: ScientificNumber,
		upgrade_category: String,
		upgrade_effects: Dictionary,
		is_repeatable: bool = false,
		growth: float = 1.0,
		upgrade_progression_type: String = "module",
		shelf: String = "",
		rank_cap: int = 1,
		required_workshop_level: int = 0
	) -> void:
	id = upgrade_id
	title = upgrade_title
	description = upgrade_description
	cost = upgrade_cost
	unlock_lifetime = unlock_at
	category = upgrade_category
	progression_type = upgrade_progression_type
	workshop_category = shelf
	max_rank = rank_cap
	workshop_level_required = required_workshop_level
	effects = upgrade_effects
	repeatable = is_repeatable
	cost_growth = growth

func cost_at(owned: int, discount: float = 0.0) -> ScientificNumber:
	var scaled := cost.multiply_scalar(pow(cost_growth, owned))
	return scaled.multiply_scalar(maxf(0.1, 1.0 - discount))

func is_maxed(owned: int) -> bool:
	return owned >= max_rank
