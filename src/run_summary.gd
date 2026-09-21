class_name RunSummary
extends RefCounted

## Snapshot taken at the moment a run ends in death, since _reset_run_state()
## immediately wipes the very fields a DIED screen needs to report on.
var wave_reached: int = 1
var coins_earned: int = 0
var knowledge_gained: int = 0
var peak_number: ScientificNumber = ScientificNumber.new()

func _init(reached: int = 1, coins: int = 0, knowledge: int = 0, peak: ScientificNumber = ScientificNumber.new()) -> void:
	wave_reached = reached
	coins_earned = coins
	knowledge_gained = knowledge
	peak_number = peak
