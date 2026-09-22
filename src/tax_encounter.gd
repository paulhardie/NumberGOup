class_name TaxEncounter
extends RefCounted

var tier_id: int = 1
var wave: int = 1
var max_liability := ScientificNumber.new()
var remaining_liability := ScientificNumber.new()
var collection := ScientificNumber.new()
var reward: int = 0
var is_boss: bool = false

func _init(
	encounter_tier: int = 1,
	encounter_wave: int = 1,
	liability: ScientificNumber = null,
	collection_amount: ScientificNumber = null,
	reward_amount: int = 0,
	boss: bool = false
) -> void:
	tier_id = encounter_tier
	wave = encounter_wave
	max_liability = liability.copy() if liability != null else ScientificNumber.new()
	remaining_liability = max_liability.copy()
	collection = collection_amount.copy() if collection_amount != null else ScientificNumber.new()
	reward = reward_amount
	is_boss = boss

func apply_compliance(amount: ScientificNumber, multiplier: float = 1.0) -> ScientificNumber:
	if is_cleared() or amount.is_zero() or multiplier <= 0.0:
		return ScientificNumber.new()
	var requested := amount.multiply_scalar(multiplier)
	var applied := requested if requested.compare_to(remaining_liability) <= 0 else remaining_liability.copy()
	remaining_liability = remaining_liability.subtract(applied)
	return applied

func is_cleared() -> bool:
	return remaining_liability.is_zero()

func to_dict() -> Dictionary:
	return {
		"tier_id": tier_id,
		"wave": wave,
		"max_liability": max_liability.to_dict(),
		"remaining_liability": remaining_liability.to_dict(),
		"collection": collection.to_dict(),
		"reward": reward,
		"is_boss": is_boss,
	}

static func from_dict(data: Dictionary) -> TaxEncounter:
	var encounter = (load("res://src/tax_encounter.gd") as GDScript).new(
		int(data.get("tier_id", 1)),
		int(data.get("wave", 1)),
		ScientificNumber.from_dict(data.get("max_liability", {})),
		ScientificNumber.from_dict(data.get("collection", {})),
		int(data.get("reward", 0)),
		bool(data.get("is_boss", false))
	)
	encounter.remaining_liability = ScientificNumber.from_dict(data.get("remaining_liability", data.get("max_liability", {})))
	return encounter
