class_name TierDefinition
extends RefCounted

## Data-only campaign tier. Explicit multipliers make large difficulty cliffs
## visible, reviewable and testable instead of burying them in a formula.
var id: int = 1
var liability_multiplier: float = 1.0
var collection_multiplier: float = 1.0
var reward_multiplier: float = 1.0
## Number every run of this tier starts with, before Cushion (D040).
var starting_number: float = 0.0
var unlock_previous_tier_wave: int = 0

func _init(
	tier_id: int = 1,
	liability: float = 1.0,
	collection: float = 1.0,
	reward: float = 1.0,
	opening_number: float = 0.0,
	unlock_wave: int = 0
) -> void:
	id = tier_id
	liability_multiplier = liability
	collection_multiplier = collection
	reward_multiplier = reward
	starting_number = opening_number
	unlock_previous_tier_wave = unlock_wave

