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
## The final stand, in three numbers: what the wave still had after the last
## timer, what the run dealt to it in that timer, and what was left to take the
## hit. The two gaps on the run-over screen are read from these (D022).
var wave_hp_left: ScientificNumber = ScientificNumber.new()
var damage_in_timer: ScientificNumber = ScientificNumber.new()
var number_before_hit: ScientificNumber = ScientificNumber.new()

## How many times over the HP still standing exceeded what the run could deal in
## one timer. 1.0 means one more timer at that rate would have cleared it. INF
## when nothing was dealt at all, and 0.0 when nothing was left standing —
## Recoil can beat a wave with the same hit that ends the run.
func attack_shortfall() -> float:
	if wave_hp_left.is_zero():
		return 0.0
	if damage_in_timer.is_zero():
		return INF
	return pow(10.0, wave_hp_left.log10() - damage_in_timer.log10())

## How many times over the hit exceeded the Number left to take it. Always above
## 1.0 on a death, by definition. INF when the run had nothing left at all,
## which is the ordinary Tier 2 opening before Cushion.
func defense_shortfall() -> float:
	if number_before_hit.is_zero():
		return INF
	return pow(10.0, final_hit.log10() - number_before_hit.log10())

## Which gap was the nearer miss, and so the one worth leaning on next. Attack
## wins ties because it is the check that stops a wave hitting at all.
func nearest_gap() -> String:
	return "attack" if attack_shortfall() <= defense_shortfall() else "defense"

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
