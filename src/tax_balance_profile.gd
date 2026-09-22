class_name TaxBalanceProfile
extends RefCounted

const TierDefinitionClass = preload("res://src/tier_definition.gd")

## Number Go Up's original, inspectable interpretation of The Tower's scaling
## shape: independent polynomial bodies, milestone growth and explicit tiers.
## The coefficients are deliberately ours rather than copied game data.
const PROFILE_ID := "tax-foundation-v2"
const WAVE_INTERVAL_SECONDS := 15.0
const BOSS_WAVE_INTERVAL := 10
const TIER_UNLOCK_WAVE := 100
const MILESTONE_WAVES := [10, 25, 50, 100]

## v2 halves both axes and trims pressured rewards to compensate for D012: with
## no free heal while stuck, the same build reaches the same wave in far less
## time, so per-wave Coins come down to hold Coins per minute level.
const LIABILITY_SCALE := 4.0
const COLLECTION_SCALE := 10.0
const PRESSURED_REWARD_SCALE := 0.65
const BOSS_LIABILITY_MULTIPLIER := 3.0
const BOSS_COLLECTION_MULTIPLIER := 1.5
const BOSS_REWARD_MULTIPLIER := 5.0

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

func is_pressured_wave(tier_id: int, wave: int) -> bool:
	return wave > get_tier(tier_id).free_waves

func liability_for_wave(tier_id: int, wave: int) -> ScientificNumber:
	if not is_pressured_wave(tier_id, wave):
		return ScientificNumber.new()
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
		return ScientificNumber.new()
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

func reward_for_wave(tier_id: int, wave: int) -> int:
	if not is_pressured_wave(tier_id, wave):
		# Grace is safe onboarding, not empty time. A small repeatable payout makes
		# the first failed attempt fund permanent Workshop progress.
		return 5 if is_boss_wave(wave) else 1
	# Once a wave is pressured every tier shares the same wave base. This keeps
	# 1.8x/2.6x reward ratios honest at equal waves.
	var base_reward := float(maxi(1, wave)) * PRESSURED_REWARD_SCALE
	var boss_multiplier := BOSS_REWARD_MULTIPLIER if is_boss_wave(wave) else 1.0
	return maxi(1, roundi(base_reward * get_tier(tier_id).reward_multiplier * boss_multiplier))

func milestone_bonus(tier_id: int, wave: int) -> int:
	if not MILESTONE_WAVES.has(wave):
		return 0
	return maxi(1, roundi(float(wave) * get_tier(tier_id).reward_multiplier * 2.0))

func _from_log10(value_log: float) -> ScientificNumber:
	if not is_finite(value_log):
		return ScientificNumber.new()
	var value_exponent := floori(value_log)
	return ScientificNumber.new(pow(10.0, value_log - float(value_exponent)), value_exponent)
