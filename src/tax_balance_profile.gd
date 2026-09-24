class_name TaxBalanceProfile
extends RefCounted

const TierDefinitionClass = preload("res://src/tier_definition.gd")

## Number Go Up's original, inspectable interpretation of The Tower's scaling
## shape: independent polynomial bodies, milestone growth and explicit tiers.
## The coefficients are deliberately ours rather than copied game data.
const PROFILE_ID := "tax-foundation-v13"
## The Tower's wave (D065): 26 seconds in which enemies spawn, then a 9-second
## gap, 35 in all. A wave beaten early still gives way after MIN_WAVE_SECONDS
## (D037).
const WAVE_INTERVAL_SECONDS := 35.0
const SPAWN_SECONDS := 26.0
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
## warm-up splice. Since D065 this is one enemy's HP, not a wave's: a wave is
## many enemies, each with the full amount, as The Tower's are. Wave HP rises a little faster than wave squared, which
## matches how Workshop damage grows with Coins spent: each investment level
## (early, mid, maxed) has a natural wave it stops at. Every tenth wave steps
## up by the milestone factors. Higher tiers multiply the same curve (D002).
## One enemy's HP is this times the curve's body. At 1 it tracks The Tower's
## basic enemy: 64.5 at wave 22 against the 63.11 the owner's Wave Info shows.
const LIABILITY_SCALE := 1.0
## A multiplier on every Hit, 1 by default. Since D063 the Hit follows the
## wave's HP through HIT_RATIO rather than its own curve; this stays so the
## balance simulator can sweep the Hit's size (`-- --hit-sweep`).
var COLLECTION_SCALE := 1.0
## The Tower's shape (D063): an enemy's health divided by its damage grows
## with the wave, so the long run is a wall of HP to clear rather than of Hits
## to absorb. log10 of the ratio is log10(HIT_RATIO_BASE) + HIT_RATIO_POWER x
## log10(w) + HIT_RATIO_GROWTH x w to wave 100; past it, DEEP_RATIO_POWER x
## log10(w / 100) + DEEP_RATIO_GROWTH x (w - 100) on top. Our own coefficients
## (D009), fitted to The Tower's Tier 1 ratio: about 2.4 at wave 1, 11 at 100,
## 118 at 500 and 1,480 at 1,000.
const HIT_RATIO_BASE := 2.4
const HIT_RATIO_POWER := 0.15
const HIT_RATIO_GROWTH := 0.0036
const DEEP_RATIO_POWER := 0.33
const DEEP_RATIO_GROWTH := 0.002
## Every hit an enemy lands makes its next one this much stronger,
## compounding, as The Tower's do (D063), so nothing that reaches the Number
## can stay there harmlessly.
const HEAT_UP_PER_HIT := 1.04
## Every wave pays this times its number in Coins, times the tier's reward
## multiplier, from wave 1 (D040).
const WAVE_REWARD_SCALE := 0.65
## A boss carries this many enemies' HP (The Tower's 20) and hits like one
## (D063, D065).
const BOSS_HP_WEIGHT := 20.0
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
## Shots a second before any Attack Speed (D055). Damage per shot is priced
## against it, so raising it means more, smaller shots at the same damage per
## second: a fresh run shows a stream of motes rather than one a second.
const BASE_SHOTS_PER_SECOND := 2.5
## How many enemies an ordinary wave sends (D065), each with the full enemy
## HP, as The Tower's do. FIRST_WAVE_MEMBERS is an estimate from the owner's
## wave 22 battle report (roughly 20 to 30 a wave early on; the SDK only
## calibrates from wave 600), kept as one setting to correct when The Tower's
## Stats tab gives the real count. Past that, our own fit to TheTowerSDK's
## spawn model: about 143 at wave 1,000, then slower growth to a cap near
## The Tower's wave 6,500 density. Mutable so the tools can sweep it.
var FIRST_WAVE_MEMBERS := 20
const MEMBERS_PER_WAVE := 0.123
const DEEP_MEMBERS_FROM := 1000
const DEEP_MEMBERS_PER_WAVE := 0.0145
const MAX_WAVE_MEMBERS := 220
## Members walk in as a column: the first reaches the Number this many
## seconds into the wave and the last SPAWN_SECONDS later, evenly spaced, as
## The Tower's spawn through its 26 seconds.
const FIRST_ARRIVAL_SECONDS := 6.0
## A boss sets off with its wave and walks slower, reaching the Number here.
const BOSS_ARRIVAL_SECONDS := 15.0
## A member that reaches the Number stays and hits again this often until
## beaten (D058). A boss keeps the 15-second clock. Mutable so the balance
## tools can sweep it.
const DEFAULT_MEMBER_HIT_SECONDS := 5.0
var MEMBER_HIT_SECONDS := DEFAULT_MEMBER_HIT_SECONDS
## The opening is gentler (D059): to wave OPENING_HIT_WAVES a member that
## reaches the Number hits once and leaves (D057's rule), so a new player
## banks Cash before any pile forms. After that members stay, hitting every
## OPENING_HIT_SECONDS at first and easing to MEMBER_HIT_SECONDS by wave
## OPENING_EASED_BY. Zero means "hits once and passes".
const OPENING_HIT_SECONDS := 15.0
## Mutable so tests of the staying rule can start past the opening.
var OPENING_HIT_WAVES := 30
var OPENING_EASED_BY := 50

func member_hit_seconds(wave: int) -> float:
	if wave <= OPENING_HIT_WAVES:
		return 0.0
	if wave >= OPENING_EASED_BY or OPENING_EASED_BY <= OPENING_HIT_WAVES:
		return MEMBER_HIT_SECONDS
	var eased := float(wave - OPENING_HIT_WAVES) / float(OPENING_EASED_BY - OPENING_HIT_WAVES)
	return lerpf(OPENING_HIT_SECONDS, MEMBER_HIT_SECONDS, eased)

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

## Every member of a wave: its ordinary enemies, and a boss wave's boss too.
func members_for_wave(wave: int) -> int:
	return ordinary_members(wave) + (1 if is_boss_wave(wave) else 0)

## How many ordinary enemies a wave at `wave` has, boss wave or not (D065).
func ordinary_members(wave: int) -> int:
	var w := maxi(1, wave)
	var count := FIRST_WAVE_MEMBERS + floori(MEMBERS_PER_WAVE * float(mini(w, DEEP_MEMBERS_FROM) - 1))
	if w > DEEP_MEMBERS_FROM:
		count += floori(DEEP_MEMBERS_PER_WAVE * float(w - DEEP_MEMBERS_FROM))
	return clampi(count, 1, MAX_WAVE_MEMBERS)

## How many enemies' worth of HP the whole wave carries: one per ordinary
## enemy, and BOSS_HP_WEIGHT more on a boss wave.
func wave_weight(wave: int) -> float:
	return float(ordinary_members(wave)) + (BOSS_HP_WEIGHT if is_boss_wave(wave) else 0.0)

## Each member's HP weight, front first in arrival order, and where the boss
## stands among them (-1 on an ordinary wave).
func member_weights(wave: int) -> Array:
	var weights: Array = []
	for index in range(ordinary_members(wave)):
		weights.append(1.0)
	if is_boss_wave(wave):
		weights.insert(boss_position(wave), BOSS_HP_WEIGHT)
	return weights

## The boss's place in its wave's column: after every ordinary enemy that
## reaches the Number before BOSS_ARRIVAL_SECONDS.
func boss_position(wave: int) -> int:
	var count := ordinary_members(wave)
	var position := 0
	while position < count and member_arrival(position, count) <= BOSS_ARRIVAL_SECONDS:
		position += 1
	return position

## How often a boss hits once it reaches the Number: as often as the enemies
## that stay at its wave (D063), and every 15 seconds through the opening,
## where ordinary enemies hit once and leave but a boss stays.
func boss_hit_seconds(wave: int) -> float:
	var interval := member_hit_seconds(wave)
	return interval if interval > 0.0 else OPENING_HIT_SECONDS

## When ordinary member `index` (0 is the front) of `count` reaches the
## Number, in seconds from the wave's start (D065).
func member_arrival(index: int, count: int) -> float:
	if count <= 1:
		return FIRST_ARRIVAL_SECONDS
	# Snapped to 1/64 of a second, which a saved run stores and reads back
	# exactly; 26/19 of a second does not survive JSON bit for bit, and a
	# resumed run must play out identically (law 6).
	return snappedf(FIRST_ARRIVAL_SECONDS + SPAWN_SECONDS * float(index) / float(count - 1), 1.0 / 64.0)

## Every member's arrival, front first, the boss's included.
func member_arrivals(wave: int) -> Array:
	var count := ordinary_members(wave)
	var arrivals: Array = []
	for index in range(count):
		arrivals.append(member_arrival(index, count))
	if is_boss_wave(wave):
		arrivals.insert(boss_position(wave), BOSS_ARRIVAL_SECONDS)
	return arrivals

func is_boss_wave(wave: int) -> bool:
	return wave > 0 and wave % BOSS_WAVE_INTERVAL == 0

## What every run of a tier starts with, before any Workshop rank.
func starting_number(tier_id: int) -> float:
	return get_tier(tier_id).starting_number

## What every run starts with in Cash: enough to afford opening Rig ranks
## based on the player's opening income rate.
func starting_cash(income_per_second: float) -> float:
	return RIG_PRICE_SECONDS * maxf(income_per_second, BASE_DAMAGE_PER_SECOND) * 2.5

## One enemy's HP on the Tier 1 scale, in log10 so deep waves stay finite:
## 0.05 w^2.13 + 0.8 w + 1.5, x1.08 every 10 waves, x1.2 every 50 and x1.5
## every 100.
func _wave_hp_log10(wave: int) -> float:
	var w := float(maxi(1, wave))
	var body := 0.05 * pow(w, 2.13) + 0.8 * w + 1.5
	var milestone_log := (
		float(wave / 10) * log(1.08)
		+ float(wave / 50) * log(1.20)
		+ float(wave / 100) * log(1.50)
	) / log(10.0)
	return log(LIABILITY_SCALE * body) / log(10.0) + milestone_log

## A wave's whole HP: one enemy's times every enemy's worth it carries (D065).
func liability_for_wave(tier_id: int, wave: int) -> ScientificNumber:
	var tier: Variant = get_tier(tier_id)
	return _from_log10(_wave_hp_log10(wave) + log(tier.liability_multiplier * wave_weight(wave)) / log(10.0))

## log10 of how many times its Hit an enemy's HP is (D063).
func hit_ratio_log10(wave: int) -> float:
	var w := float(maxi(1, wave))
	var early := minf(w, 100.0)
	var ratio_log := log(HIT_RATIO_BASE) / log(10.0) + HIT_RATIO_POWER * log(early) / log(10.0) + HIT_RATIO_GROWTH * early
	if w > 100.0:
		ratio_log += DEEP_RATIO_POWER * log(w / 100.0) / log(10.0) + DEEP_RATIO_GROWTH * (w - 100.0)
	return ratio_log

## One enemy's Hit on the Tier 1 scale: its HP divided by the ratio, so the
## milestone steps move both together. Scales to wave 5,000 and beyond.
func _wave_hit_log10(wave: int) -> float:
	return _wave_hp_log10(wave) - hit_ratio_log10(wave) + log(COLLECTION_SCALE) / log(10.0)

## A wave's whole Hit, weighted like its HP, so each member's share of it is
## what that member carries (D065). A boss's share is its HP weight, so it
## takes its Hit from `boss_wave_hit` instead and hits like one enemy (D063).
func collection_for_wave(tier_id: int, wave: int) -> ScientificNumber:
	var tier: Variant = get_tier(tier_id)
	return _from_log10(_wave_hit_log10(wave) + log(tier.collection_multiplier * wave_weight(wave)) / log(10.0))

## The whole Hit a boss member's share is taken from, so the Hit it lands is
## one enemy's.
func boss_wave_hit(tier_id: int, wave: int) -> ScientificNumber:
	return collection_for_wave(tier_id, wave).multiply_scalar(1.0 / BOSS_HP_WEIGHT)

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
## such as Damage, climbs a little faster (10, 16, 24, 37, 56).
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

## A run rank is worth two Workshop ranks (D044). With run ranks capped at the
## row's max rank, this is the dial on how much buying them speeds a career.
## Measured by tools/career_simulator.gd from a fresh save to wave 100: 5.0
## hours at worth 2 against 7.6 without them; with the proposed coin gates,
## 7.2 hours at worth 1 (The Tower's), 6.3 at 2 and 4.9 at 3, against 8.7. At 2
## they clearly pay without replacing the Workshop. Mutable so the simulators
## can sweep it.
var RIG_EFFECT_MULTIPLIER := {
	"attack": 2.0,
	"defense": 2.0,
	"utility": 2.0,
}

func rig_effect_multiplier(category: String, upgrade_id: String) -> float:
	return float(RIG_EFFECT_MULTIPLIER.get(category, 1.0))

## Combined defensive ceilings (D023). Run ranks are worth more than Workshop
## ranks, and Labs and Cards stack on both, so a row's own cap does not bound
## the combined effect. These are the ceilings it can never pass, whichever
## layer the ranks came from.
const COLLECTION_RESISTANCE_CEILING := 0.75
const SIPHON_CEILING := 0.5
const RECOIL_CEILING := 1.0
## Bosses take half of Thorns, as The Tower's do (D064).
const BOSS_THORNS_SHARE := 0.5

## One rank costs `k` times RIG_PRICE_SECONDS of the given income at the first
## rank and grows from there (D039). Past that, a row's Workshop and run ranks
## together stop at its max rank (D044).
func rig_cost(category: String, rank: int, income_per_second: float) -> ScientificNumber:
	var scale := float(RIG_COST_K.get(category, 1.0))
	var growth := float(RIG_COST_GROWTH.get(category, 1.4))
	return ScientificNumber.from_float(RIG_PRICE_SECONDS * maxf(income_per_second, BASE_DAMAGE_PER_SECOND) * scale * pow(growth, float(maxi(0, rank))))

func _from_log10(value_log: float) -> ScientificNumber:
	if not is_finite(value_log):
		return ScientificNumber.new()
	var value_exponent := floori(value_log)
	return ScientificNumber.new(pow(10.0, value_log - float(value_exponent)), value_exponent)
