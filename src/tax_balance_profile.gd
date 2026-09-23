class_name TaxBalanceProfile
extends RefCounted

const TierDefinitionClass = preload("res://src/tier_definition.gd")

## Number Go Up's original, inspectable interpretation of The Tower's scaling
## shape: independent polynomial bodies, milestone growth and explicit tiers.
## The coefficients are deliberately ours rather than copied game data.
const PROFILE_ID := "tax-foundation-v8"
const WAVE_INTERVAL_SECONDS := 15.0
const BOSS_WAVE_INTERVAL := 10
## A beaten wave stays on screen at least this long before the next arrives
## (D037), so a clear still registers when the build outclasses the wave.
const MIN_WAVE_SECONDS := 2.5
const TIER_UNLOCK_WAVE := 100
## Every tier's milestone checkpoints. Extends to wave 5,000 with final milestone
## at 5,000, paying Gems at every checkpoint and Coins at coin checkpoints.
const MILESTONE_WAVES := [10, 20, 25, 30, 40, 50, 60, 75, 90, 100, 150, 200, 250, 350, 500, 750, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000]
const COIN_MILESTONE_WAVES := [10, 25, 50, 100, 250, 500, 750, 1000, 2500, 5000]
## A checkpoint pays this times the square root of its wave, times the tier's
## reward multiplier, in Gems: deeper checkpoints and harder tiers pay more,
## without a hand-authored table to drift.
const MILESTONE_GEM_SCALE := 2.0
## Every boss wave beaten pays this many Gems, every run (D030).
const BOSS_WAVE_GEMS := 1

## Tier 1's difficulty curve: one set of rules from wave 1, with no
## warm-up splice. Wave HP rises a little faster than wave squared, which
## matches how Workshop damage grows with Coins spent: each investment level
## (early, mid, maxed) has a natural wave it stops at. Every tenth wave steps
## up by the milestone factors. Higher tiers multiply the same curve (D002).
const LIABILITY_SCALE := 4.0
## The Attack scale for Collection Hit, decoupled from Wave HP into its own
## independent polynomial curve.
const COLLECTION_SCALE := 1.5
## Every wave pays this times its number in Coins, times the tier's reward
## multiplier, from wave 1 (D040).
const WAVE_REWARD_SCALE := 0.65
const BOSS_LIABILITY_MULTIPLIER := 3.0
const BOSS_COLLECTION_MULTIPLIER := 1.5
const BOSS_REWARD_MULTIPLIER := 5.0
## A beaten wave pays this much Cash plus CASH_PER_WAVE times its number, times
## BOSS_CASH_MULTIPLIER on a boss (D042). It is flat rather than income-scaled,
## so it matters most in the opening and fades beside income deeper in.
const CASH_WAVE_BASE := 10.0
const CASH_PER_WAVE := 5.0
const BOSS_CASH_MULTIPLIER := 3.0
## Output every run has from its first second, before any Workshop rank, which
## upgrades do not raise (D033).
const BASE_DAMAGE_PER_SECOND := 1.0

var tiers: Array = []

func _init() -> void:
	# Tier 1 starts a run with 50 Number so its first Hit costs Number, not the
	# run. Higher tiers start with none, so their difficulty is honest from
	# wave one (Cushion buys a start there).
	tiers = [
		TierDefinitionClass.new(1, 1.0, 1.0, 1.0, 50.0, 0),
		TierDefinitionClass.new(2, 20.0, 20.0, 1.8, 0.0, TIER_UNLOCK_WAVE),
		TierDefinitionClass.new(3, 60.0, 60.0, 2.6, 0.0, TIER_UNLOCK_WAVE),
	]

func get_tier(tier_id: int):
	for tier in tiers:
		if tier.id == tier_id:
			return tier
	return tiers[0]

func has_tier(tier_id: int) -> bool:
	for tier in tiers:
		if tier.id == tier_id:
			return true
	return false

func is_boss_wave(wave: int) -> bool:
	return wave > 0 and wave % BOSS_WAVE_INTERVAL == 0

## What every run of a tier starts with, before any Workshop rank.
func starting_number(tier_id: int) -> float:
	return get_tier(tier_id).starting_number

## What every run starts with in Cash: enough to afford opening Rig ranks
## based on the player's opening income rate.
func starting_cash(income_per_second: float) -> float:
	return RIG_PRICE_SECONDS * maxf(income_per_second, BASE_DAMAGE_PER_SECOND) * 2.5

## An ordinary wave's HP on the Tier 1 scale, in log10 so deep waves stay
## finite: 4 x (0.05 w^2.13 + 0.8 w + 1.5), x1.08 every 10 waves, x1.2 every
## 50 and x1.5 every 100.
func _wave_hp_log10(wave: int) -> float:
	var w := float(maxi(1, wave))
	var body := 0.05 * pow(w, 2.13) + 0.8 * w + 1.5
	var milestone_log := (
		float(wave / 10) * log(1.08)
		+ float(wave / 50) * log(1.20)
		+ float(wave / 100) * log(1.50)
	) / log(10.0)
	return log(LIABILITY_SCALE * body) / log(10.0) + milestone_log

func liability_for_wave(tier_id: int, wave: int) -> ScientificNumber:
	var tier: Variant = get_tier(tier_id)
	var boss_multiplier := BOSS_LIABILITY_MULTIPLIER if is_boss_wave(wave) else 1.0
	return _from_log10(_wave_hp_log10(wave) + log(tier.liability_multiplier * boss_multiplier) / log(10.0))

## An ordinary wave's Attack/Hit on the Tier 1 scale: independent of
## Wave HP so DPS checks (beating the clock) and EHP checks (surviving contact)
## are calibrated separately. Scales to wave 5,000 and beyond.
func _wave_hit_log10(wave: int) -> float:
	var w := float(maxi(1, wave))
	var body := 0.08 * pow(w, 2.10) + 0.4 * w + 1.0
	var milestone_log := (
		float(wave / 10) * log(1.08)
		+ float(wave / 50) * log(1.20)
		+ float(wave / 100) * log(1.50)
	) / log(10.0)
	return log(COLLECTION_SCALE * body) / log(10.0) + milestone_log

## A boss's Hit is 1.5 times an ordinary Hit at its wave, not a multiple of its
## tripled HP, so a boss fight is long rather than instantly lethal.
func collection_for_wave(tier_id: int, wave: int) -> ScientificNumber:
	var tier: Variant = get_tier(tier_id)
	var boss_multiplier := BOSS_COLLECTION_MULTIPLIER if is_boss_wave(wave) else 1.0
	return _from_log10(_wave_hit_log10(wave) + log(tier.collection_multiplier * boss_multiplier) / log(10.0))

## Every tier shares the same wave base, which keeps the 1.8x/2.6x reward
## ratios honest at equal waves.
func reward_for_wave(tier_id: int, wave: int) -> int:
	var base_reward := float(maxi(1, wave)) * WAVE_REWARD_SCALE
	var boss_multiplier := BOSS_REWARD_MULTIPLIER if is_boss_wave(wave) else 1.0
	return maxi(1, roundi(base_reward * get_tier(tier_id).reward_multiplier * boss_multiplier))

## The Cash a beaten wave pays (D042). A missed wave pays the share of it
## that was cleared.
func wave_cash(wave: int) -> float:
	var boss_multiplier := BOSS_CASH_MULTIPLIER if is_boss_wave(wave) else 1.0
	return (CASH_WAVE_BASE + CASH_PER_WAVE * float(maxi(1, wave))) * boss_multiplier

func is_milestone_wave(wave: int) -> bool:
	return MILESTONE_WAVES.has(wave)

## The Coin bonus a checkpoint pays on top of the wave's own reward.
func milestone_bonus(tier_id: int, wave: int) -> int:
	if not COIN_MILESTONE_WAVES.has(wave):
		return 0
	return maxi(1, roundi(float(wave) * get_tier(tier_id).reward_multiplier * 2.0))

## The Gems a checkpoint pays, once per tier record.
func milestone_gems(tier_id: int, wave: int) -> int:
	if not MILESTONE_WAVES.has(wave):
		return 0
	return maxi(1, roundi(MILESTONE_GEM_SCALE * sqrt(float(wave)) * get_tier(tier_id).reward_multiplier))

## The Gems a beaten wave pays whether or not it is a checkpoint.
func wave_gems(wave: int) -> int:
	return BOSS_WAVE_GEMS if is_boss_wave(wave) else 0

## The Rig (D015): run-scoped ranks bought with Cash during a run (D042). Since
## D039 a rank is priced in seconds of the player's own steady income, not in
## Wave HP: `k` times RIG_PRICE_SECONDS of income, times the row's growth per
## rank already owned. The price follows what the player makes, so it stays in
## proportion at every tier and depth with no per-tier data, and a purchase
## that raises income raises the next price with it.
const RIG_PRICE_SECONDS := 5.0
const RIG_COST_K := {
	"attack": 1.0,
	"defense": 1.0,
	"utility": 2.0,
}
## Each rank of a row costs this many times the last, at the same income.
## Swept at 1.3-1.6 (D039): 1.4 keeps the climb gentle while top builds still
## stop buying before a run turns endless. At a fresh start six ranks of a row
## that does not raise income cost 10, 14, 20, 27, 38, 54; a row that does,
## such as Damage per Second, climbs a little faster (10, 16, 24, 37, 56).
## Mutable so the balance simulator can sweep it.
var RIG_COST_GROWTH := {
	"attack": 1.4,
	"defense": 1.4,
	"utility": 1.4,
}
## Which rows the Rig sells: all 21 Workshop rows from the canonical catalogue
## are available in-run (matching The Tower). Upgrades spend in-run Cash.
const RIG_ROWS := {
	"attack": [
		"stronger_tap", "generator", "generator_two", "faster_cadence",
		"faster_echo", "burst_relay", "more_critical", "magnitude_coil",
		"chain_reaction", "automation_core", "boss_damage",
	],
	"defense": [
		"tax_resistance", "guard", "siphon", "recoil",
		"priority_buffer", "brace_discount", "second_wind",
	],
	"utility": [
		"smarter_efficiency", "coin_bonus", "knowledge_bonus",
	],
}

func rig_has_row(category: String, upgrade_id: String) -> bool:
	var rows: Array = RIG_ROWS.get(category, [])
	return rows.has(upgrade_id)

## A Rig rank is worth more than a Workshop rank. The measurement that forced
## this: with one-to-one effects, spending Number was a net loss at every build
## (mid 40 against 50, attack max 94 against 96), because the rank's effect was
## worth less than the hit buffer its Number bought. Temporary power has to beat
## the buffer, or the optimal player ignores the Rig and the panel is noise.
## Since D042 the Rig spends Cash, not Number, so that reason no longer holds;
## the value is unchanged until an owner-approved re-sweep.
## Mutable so the balance simulator can sweep it; the sweep picks the value.
var RIG_EFFECT_MULTIPLIER := {
	"attack": 3.0,
	"defense": 3.0,
	"utility": 3.0,
}

func rig_effect_multiplier(category: String, upgrade_id: String) -> float:
	return float(RIG_EFFECT_MULTIPLIER.get(category, 1.0))

## Combined defensive ceilings (D023). Workshop caps alone cannot bound a layer
## that stacks on top of them and is uncapped: Rig Armor at 2% a rank would
## reach immunity within one run's Number. These are the ceilings the combined
## effect can never pass, whichever lens the ranks came from.
const COLLECTION_RESISTANCE_CEILING := 0.75
const SIPHON_CEILING := 0.5
const RECOIL_CEILING := 1.0
## Combined defensive floor (WORKSHOP_EXPANSION): a Hit never drops below 10%
## of its base size after Guard and Armor together.
const HIT_FLOOR_PERCENT := 0.10

## One rank costs `k` times RIG_PRICE_SECONDS of the given income at the first
## rank and grows from there (D039). Ranks are uncapped; cost growth against
## the income each rank adds is the only limit (D015).
func rig_cost(category: String, rank: int, income_per_second: float) -> ScientificNumber:
	var scale := float(RIG_COST_K.get(category, 1.0))
	var growth := float(RIG_COST_GROWTH.get(category, 1.4))
	return ScientificNumber.from_float(RIG_PRICE_SECONDS * maxf(income_per_second, BASE_DAMAGE_PER_SECOND) * scale * pow(growth, float(maxi(0, rank))))

func _from_log10(value_log: float) -> ScientificNumber:
	if not is_finite(value_log):
		return ScientificNumber.new()
	var value_exponent := floori(value_log)
	return ScientificNumber.new(pow(10.0, value_log - float(value_exponent)), value_exponent)
