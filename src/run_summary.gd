class_name RunSummary
extends RefCounted

## Snapshot taken at death or retreat, since _reset_run_state() immediately
## wipes the fields a run-end report or toast needs to describe.
var wave_reached: int = 1
var coins_earned: int = 0
var knowledge_gained: int = 0
var peak_number: ScientificNumber = ScientificNumber.new()
var tier_id: int = 1
var outcome: String = "death"

func _init(
	reached: int = 1,
	coins: int = 0,
	knowledge: int = 0,
	peak: ScientificNumber = null,
	tier: int = 1,
	run_outcome: String = "death"
) -> void:
	wave_reached = reached
	coins_earned = coins
	knowledge_gained = knowledge
	peak_number = peak.copy() if peak != null else ScientificNumber.new()
	tier_id = tier
	outcome = run_outcome
