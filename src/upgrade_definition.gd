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

static func from_dict(dict: Dictionary) -> UpgradeDefinition:
	var def_id: String = str(dict.get("id", ""))
	var def_title: String = str(dict.get("title", dict.get("name", "")))
	var def_description: String = str(dict.get("description", ""))
	var def_cost: ScientificNumber
	if dict.has("cost_base"):
		def_cost = ScientificNumber.from_float(float(dict["cost_base"]))
	elif dict.has("cost"):
		if dict["cost"] is Dictionary:
			def_cost = ScientificNumber.from_dict(dict["cost"])
		else:
			def_cost = ScientificNumber.from_float(float(dict["cost"]))
	else:
		def_cost = ScientificNumber.new()
	var def_unlock: ScientificNumber
	if dict.has("unlock_lifetime"):
		if dict["unlock_lifetime"] is Dictionary:
			def_unlock = ScientificNumber.from_dict(dict["unlock_lifetime"])
		else:
			def_unlock = ScientificNumber.from_float(float(dict["unlock_lifetime"]))
	elif dict.has("unlock_at"):
		if dict["unlock_at"] is Dictionary:
			def_unlock = ScientificNumber.from_dict(dict["unlock_at"])
		else:
			def_unlock = ScientificNumber.from_float(float(dict["unlock_at"]))
	else:
		def_unlock = ScientificNumber.new()
	var def_category: String = str(dict.get("category", "workshop"))
	var def_shelf: String = str(dict.get("workshop_category", dict.get("shelf", "")))
	var def_progression: String = str(dict.get("progression_type", "module"))
	var def_cap: int = int(dict.get("max_rank", dict.get("rank_cap", 1)))
	var def_req_level: int = int(dict.get("required_workshop_level", dict.get("opens_at_workshop_level", 0)))
	var def_effects: Dictionary = dict.get("effects", dict.get("effects_per_rank", {}))
	var def_repeatable: bool = bool(dict.get("repeatable", false))
	var def_growth: float = float(dict.get("cost_growth", dict.get("cost_growth_per_rank", 1.0)))
	return UpgradeDefinition.new(
		def_id,
		def_title,
		def_description,
		def_cost,
		def_unlock,
		def_category,
		def_effects,
		def_repeatable,
		def_growth,
		def_progression,
		def_shelf,
		def_cap,
		def_req_level
	)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"category": category,
		"workshop_category": workshop_category,
		"progression_type": progression_type,
		"cost_base": cost.mantissa * pow(10.0, cost.exponent),
		"cost_growth": cost_growth,
		"max_rank": max_rank,
		"required_workshop_level": workshop_level_required,
		"unlock_lifetime": unlock_lifetime.mantissa * pow(10.0, unlock_lifetime.exponent),
		"repeatable": repeatable,
		"effects": effects,
	}
