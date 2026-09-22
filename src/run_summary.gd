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
## What the run was lost to: the hit that took Number to zero, and whether the
## wave that landed it was a boss. Zero on a retreat, which nothing lost to.
var final_hit: ScientificNumber = ScientificNumber.new()
var lost_to_boss: bool = false

func _init(
	reached: int = 1,
	coins: int = 0,
	knowledge: int = 0,
	peak: ScientificNumber = null,
	tier: int = 1,
	run_outcome: String = "death",
	killing_hit: ScientificNumber = null,
	boss: bool = false
) -> void:
	wave_reached = reached
	coins_earned = coins
	knowledge_gained = knowledge
	peak_number = peak.copy() if peak != null else ScientificNumber.new()
	tier_id = tier
	outcome = run_outcome
	final_hit = killing_hit.copy() if killing_hit != null else ScientificNumber.new()
	lost_to_boss = boss
