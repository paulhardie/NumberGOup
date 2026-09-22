class_name TaxBalanceProfile
extends RefCounted

const TierDefinitionClass = preload("res://src/tier_definition.gd")

## Number Go Up's original, inspectable interpretation of The Tower's scaling
## shape: independent polynomial bodies, milestone growth and explicit tiers.
## The coefficients are deliberately ours rather than copied game data.
const PROFILE_ID := "tax-foundation-v3"
const WAVE_INTERVAL_SECONDS := 15.0
const BOSS_WAVE_INTERVAL := 10
const TIER_UNLOCK_WAVE := 100
## Every tier's milestone checkpoints (D030). Each pays once per tier record:
## Gems at every checkpoint, and the Coin bonus as well at the four Coin
## checkpoints (D002, D010).
const MILESTONE_WAVES := [10, 20, 25, 30, 40, 50, 60, 75, 90, 100, 125, 150, 200]
const COIN_MILESTONE_WAVES := [10, 25, 50, 100]
## A checkpoint pays this times the square root of its wave, times the tier's
## reward multiplier, in Gems: deeper checkpoints and harder tiers pay more,
## without a hand-authored table to drift.
const MILESTONE_GEM_SCALE := 2.0
## Every boss wave beaten pays this many Gems, every run (D030).
const BOSS_WAVE_GEMS := 1

## v2 halves both axes and trims pressured rewards to compensate for D012: with
## no free heal while stuck, the same build reaches the same wave in far less
## time, so per-wave Coins come down to hold Coins per minute level.
const LIABILITY_SCALE := 4.0
const COLLECTION_SCALE := 10.0
const PRESSURED_REWARD_SCALE := 0.65
const BOSS_LIABILITY_MULTIPLIER := 3.0
const BOSS_COLLECTION_MULTIPLIER := 1.5
const BOSS_REWARD_MULTIPLIER := 5.0

## The Tier 1 opening (D033): warm-up wave HP and hit at wave 1 and how much
## each grows per wave, what a warm-up boss multiplies them by, the Number a run with
## a warm-up starts with, output every run has before any Workshop rank, and
## the share of the first full wave's HP the Rig quotes for a run's first few
## purchases during the warm-up.
const WARM_UP_START_HP := 30.0
const WARM_UP_HP_GROWTH := 1.12
const WARM_UP_START_HIT := 1.0
const WARM_UP_HIT_GROWTH := 1.08
const WARM_UP_BOSS_HP := 1.4
const WARM_UP_BOSS_HIT := 1.4
const WARM_UP_STARTING_NUMBER := 50.0
const BASE_DAMAGE_PER_SECOND := 1.0
const RIG_WARM_UP_PRICE_SCALE := 0.05
const RIG_WARM_UP_DISCOUNTED_PURCHASES := 2
const TIER_ONE_TRANSITION_LAST_WAVE := 25
const TIER_ONE_TRANSITION_HIT_GROWTH := 2.0

var tiers: Array = []

func _init() -> void:
	# T1 retains the prototype's onboarding grace. Higher tiers start applying
	# pressure immediately so their difficulty choice is honest from wave one.
	tiers = [
		TierDefinitionClass.new(1, 1.0, 1.0, 1.0, 20, 0),
		TierDefinitionClass.new(2, 20.0, 20.0, 1.8, 0, TIER_UNLOCK_WAVE),
		TierDefinitionClass.new(3, 60.0, 60.0, 2.6, 0, TIER_UNLOCK_WAVE),
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

## Past the tier's warm-up: the full curves apply and waves pay by depth. A
## warm-up wave is not free (D033); it ramps into the first full wave.
func is_pressured_wave(tier_id: int, wave: int) -> bool:
	return wave > get_tier(tier_id).free_waves

## Tier 1's opening (D033). Its warm-up waves are small but real: wave HP and
## the hit start low and grow a fixed share each wave, so a new player is under
## attack from the first wave without a hit that can end the run, and a warm-up
## boss is softened rather than tripled. The first full wave after the warm-up
## is where the curves take over. Tiers without a warm-up are pressured from
## wave 1 already.
func _warm_up_value(wave: int, start: float, growth: float, boss_factor: float) -> ScientificNumber:
	var value := start * pow(growth, float(maxi(1, wave) - 1))
	if is_boss_wave(wave):
		value *= boss_factor
	return ScientificNumber.from_float(value)

## What every run of a tier starts with, before any Workshop rank: a tier with
## a warm-up gives a little, so the first hit costs Number instead of the run.
func starting_number(tier_id: int) -> float:
	return WARM_UP_STARTING_NUMBER if get_tier(tier_id).free_waves > 0 else 0.0

func liability_for_wave(tier_id: int, wave: int) -> ScientificNumber:
	if not is_pressured_wave(tier_id, wave):
		return _warm_up_value(wave, WARM_UP_START_HP, WARM_UP_HP_GROWTH, WARM_UP_BOSS_HP)
	var w := float(maxi(1, wave))
	var body := 0.05 * pow(w, 2.13) + 0.8 * w + 1.5
	var milestone_log := (
		float(wave / 10) * log(1.08) / log(10.0)
		+ float(wave / 50) * log(1.20) / log(10.0)
		+ float(wave / 100) * log(1.50) / log(10.0)
	)
	var tier: Variant = get_tier(tier_id)
	var boss_multiplier := BOSS_LIABILITY_MULTIPLIER if is_boss_wave(wave) else 1.0
	var value_log := log(LIABILITY_SCALE * body * tier.liability_multiplier * boss_multiplier) / log(10.0) + milestone_log
	return _from_log10(value_log)

func collection_for_wave(tier_id: int, wave: int) -> ScientificNumber:
	if not is_pressured_wave(tier_id, wave):
		return _warm_up_value(wave, WARM_UP_START_HIT, WARM_UP_HIT_GROWTH, WARM_UP_BOSS_HIT)
	var w := float(maxi(1, wave))
	var body := 0.021 * pow(w, 2.007) + 0.16 * w + 1.07
	var milestone_log := (
		float(wave / 10) * log(1.06) / log(10.0)
		+ float(wave / 50) * log(1.18) / log(10.0)
		+ float(wave / 100) * log(1.40) / log(10.0)
	)
	var tier: Variant = get_tier(tier_id)
	var boss_multiplier := BOSS_COLLECTION_MULTIPLIER if is_boss_wave(wave) else 1.0
	var value_log := log(COLLECTION_SCALE * body * tier.collection_multiplier * boss_multiplier) / log(10.0) + milestone_log
	return _from_log10(value_log)

## Tier 1's first pressured hits grow from its final warm-up boss rather than
## jumping straight to the full curve. The full curve remains the encounter's
## base Collection, so higher tiers keep their exact pressure ratios and Armor
## still reduces the effective hit through the shared modifier pipeline.
func tier_one_transition_hit_multiplier(tier_id: int, wave: int, base_hit: ScientificNumber) -> float:
	if tier_id != 1 or wave <= get_tier(1).free_waves or wave > TIER_ONE_TRANSITION_LAST_WAVE or base_hit.is_zero():
		return 1.0
	var last_warm_up_hit := WARM_UP_START_HIT * pow(WARM_UP_HIT_GROWTH, float(get_tier(1).free_waves - 1)) * WARM_UP_BOSS_HIT
	var ramped_hit := ScientificNumber.from_float(last_warm_up_hit * pow(TIER_ONE_TRANSITION_HIT_GROWTH, float(wave - get_tier(1).free_waves)))
	if ramped_hit.compare_to(base_hit) >= 0:
		return 1.0
	return pow(10.0, ramped_hit.log10() - base_hit.log10())

func reward_for_wave(tier_id: int, wave: int) -> int:
	if not is_pressured_wave(tier_id, wave):
		# The warm-up pays a small repeatable amount, so the first failed attempt
		# funds permanent Workshop progress (D010).
		return 5 if is_boss_wave(wave) else 1
	# Once a wave is pressured every tier shares the same wave base. This keeps
	# 1.8x/2.6x reward ratios honest at equal waves.
	var base_reward := float(maxi(1, wave)) * PRESSURED_REWARD_SCALE
	var boss_multiplier := BOSS_REWARD_MULTIPLIER if is_boss_wave(wave) else 1.0
	return maxi(1, roundi(base_reward * get_tier(tier_id).reward_multiplier * boss_multiplier))

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

## The Rig (D015): run-scoped ranks bought with Number during a run. Prices are
## quoted against the wave's HP rather than in absolute Number, so one table
## scales across tiers and depth with no per-tier data. These coefficients are
## the design's starting proposals until the balance simulator tunes them.
const RIG_COST_K := {
	"attack": 1.0,
	"defense": 1.0,
	"utility": 2.0,
}
const RIG_COST_GROWTH := {
	"attack": 1.7,
	"defense": 1.6,
	"utility": 1.5,
}
## Which rows the Rig sells: the shared catalogue minus the rows whose value is
## decided before a run starts. Brace is the Defense tab's first row as a free
## action, not a purchase. Cushion, Brace Cost, Second Wind, Knowledge Bonus and
## Workshop Discount stay Workshop-only, because buying them mid-run is either
## meaningless or a solved decision (D015).
const RIG_ROWS := {
	"attack": [
		"stronger_tap", "generator", "generator_two", "faster_cadence",
		"faster_echo", "burst_relay", "more_critical", "magnitude_coil",
		"chain_reaction", "boss_damage",
	],
	"defense": ["tax_resistance", "siphon", "recoil"],
	"utility": ["coin_bonus"],
}

func rig_has_row(category: String, upgrade_id: String) -> bool:
	var rows: Array = RIG_ROWS.get(category, [])
	return rows.has(upgrade_id)

## A Rig rank is worth more than a Workshop rank. The measurement that forced
## this: with one-to-one effects, spending Number was a net loss at every build
## (mid 40 against 50, attack max 94 against 96), because the rank's effect was
## worth less than the hit buffer its Number bought. Temporary power has to beat
## the buffer, or the optimal player ignores the Rig and the panel is noise.
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

## One rank costs `k` waves' worth of HP at the first rank and grows from there.
## Ranks are uncapped; cost growth is the only limit (D015).
func rig_cost(category: String, rank: int, reference_hp: ScientificNumber) -> ScientificNumber:
	var scale := float(RIG_COST_K.get(category, 1.0))
	var growth := float(RIG_COST_GROWTH.get(category, 1.7))
	return reference_hp.multiply_scalar(scale * pow(growth, float(maxi(0, rank))))

## The price floor: the tier's first pressured wave, so Tier 1's warm-up waves
## cannot make the whole panel free.
func rig_reference_hp(tier_id: int, wave: int) -> ScientificNumber:
	var first_pressured: int = get_tier(tier_id).free_waves + 1
	return liability_for_wave(tier_id, maxi(wave, first_pressured))

## What the warm-up's discounted Rig ranks are quoted against (D033): a share
## of the first full wave's HP.
func rig_warm_up_reference_hp(tier_id: int) -> ScientificNumber:
	return liability_for_wave(tier_id, get_tier(tier_id).free_waves + 1).multiply_scalar(RIG_WARM_UP_PRICE_SCALE)

func _from_log10(value_log: float) -> ScientificNumber:
	if not is_finite(value_log):
		return ScientificNumber.new()
	var value_exponent := floori(value_log)
	return ScientificNumber.new(pow(10.0, value_log - float(value_exponent)), value_exponent)
