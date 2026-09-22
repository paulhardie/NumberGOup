class_name RunSummary
extends RefCounted

## Snapshot taken at death, retreat or Prestige, since _reset_run_state() immediately
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
## The two gaps under "Lost to" (D022, step 6): how far short Attack fell
## against the wave's HP — the HP it left when the timer ran out, before Recoil
## returned any of the hit — and how far short Defense fell against the killing
## hit, the hit minus the Number held before it. Both zero on a retreat, which
## was lost to nothing.
var attack_gap: ScientificNumber = ScientificNumber.new()
var defense_gap: ScientificNumber = ScientificNumber.new()
## Gems the run paid: boss waves and any checkpoints it claimed (D030).
var gems_earned: int = 0

func _init(
	reached: int = 1,
	coins: int = 0,
	knowledge: int = 0,
	peak: ScientificNumber = null,
	tier: int = 1,
	run_outcome: String = "death",
	killing_hit: ScientificNumber = null,
	boss: bool = false,
	hp_left: ScientificNumber = null,
	hit_shortfall: ScientificNumber = null
) -> void:
	wave_reached = reached
	coins_earned = coins
	knowledge_gained = knowledge
	peak_number = peak.copy() if peak != null else ScientificNumber.new()
	tier_id = tier
	outcome = run_outcome
	final_hit = killing_hit.copy() if killing_hit != null else ScientificNumber.new()
	lost_to_boss = boss
	attack_gap = hp_left.copy() if hp_left != null else ScientificNumber.new()
	defense_gap = hit_shortfall.copy() if hit_shortfall != null else ScientificNumber.new()
