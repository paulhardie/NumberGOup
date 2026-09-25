class_name TaxBalanceProfile
extends RefCounted

const TierDefinitionClass = preload("res://src/tier_definition.gd")

## Number Go Up's original, inspectable interpretation of The Tower's scaling
## shape: independent polynomial bodies, milestone growth and explicit tiers.
## The coefficients are deliberately ours rather than copied game data.
const PROFILE_ID := "tax-foundation-v16"
## The Tower's wave (D065): 26 seconds in which enemies spawn, then a 9-second
## gap, 35 in all. Every wave lasts its whole 35 seconds, beaten or not, as
## The Tower's do (D067, replacing D037's early clear).
const WAVE_INTERVAL_SECONDS := 35.0
const SPAWN_SECONDS := 26.0
const BOSS_WAVE_INTERVAL := 10
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
## What a wave paid in Coins before kills paid (D040), on the old Coin scale.
## Read only for a member saved under D063 that still owes its share.
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
## Since D068 the Workshop is The Tower's: a fresh run fires Damage 3 once a
## second (Attack Speed 1.0), with no separate output floor (D033) or base
## shot rate (D055).
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
## Members set off evenly through SPAWN_SECONDS, as The Tower's spawn through
## its 26 seconds, and a basic enemy takes this long to reach the Number.
const FIRST_ARRIVAL_SECONDS := 6.0
## Distance (D067), The Tower's way. Enemies set off this far from the Number
## and walk in at their type's speed; the Number reaches TOWER_RANGE_METRES,
## The Tower's base Range, until the Range row raises it (D068), and its damage
## strikes only enemies inside it. The spawn distance is ours (TheTowerSDK
## doesn't give one). It was 60 m; D068 moved it to 100 m because The Tower's
## Range row reaches 69.5 m and its orbs circle at 60 m or more, both of
## which must lie inside where enemies appear. A basic still spends its last 3
## seconds in the base reach.
const SPAWN_DISTANCE_METRES := 100.0
const TOWER_RANGE_METRES := 30.0
const BASIC_SPEED_METRES := 10.0
## Enemy types (D066), The Tower's Tier 1 set. Each carries this many enemies'
## HP (the owner's wave 22 Wave Info: tank 5x, the rest 1x; a boss 20x) and
## hits like one enemy, as the same screen shows every type at one Attack.
const ENEMY_HP_WEIGHT := {"basic": 1.0, "fast": 1.0, "tank": 5.0, "ranged": 1.0, "boss": 20.0}
## How often each ordinary type spawns: the owner's wave 22 Wave Info. The
## Tower's mix shifts towards the rarer types deep into a run; one wave's
## screen is all the evidence so far, so it holds at every wave. Mutable so
## tests and tools can send one type.
var ENEMY_MIX := {"basic": 0.85, "fast": 0.07, "tank": 0.06, "ranged": 0.02}
## Each type's speed as a share of a basic's, from TheTowerSDK's ratios rounded
## to our own figures: fast 2.4x, tank and boss a third, ranged a half. A ranged
## enemy stops at the Number's range and fires from there, as The Tower's do;
## the rest walk up to the Number (D067).
const ENEMY_SPEED := {"basic": 1.0, "fast": 2.4, "tank": 1.0 / 3.0, "ranged": 0.5, "boss": 1.0 / 3.0}

## How far from the Number an enemy of `kind` stops to attack (D067).
static func stop_distance(kind: String) -> float:
	return TOWER_RANGE_METRES if kind == "ranged" else 0.0

## Metres a second an enemy of `kind` walks (D067).
static func speed_metres(kind: String) -> float:
	return BASIC_SPEED_METRES * float(ENEMY_SPEED.get(kind, 1.0))

## Seconds from setting off to its first hit: to the Number, or for a ranged
## enemy to the edge of range (D067). On a 1/64-second grid, so saved arrivals
## read back exactly: basic and ranged 6, fast 2.5, tank and boss 18.
static func travel_seconds(kind: String) -> float:
	return snappedf((SPAWN_DISTANCE_METRES - stop_distance(kind)) / speed_metres(kind), 1.0 / 64.0)
## Coins a kill is worth, in kill-coin units (the owner's reference table and
## play): basics pay none, the rarer types pay more.
const KILL_COINS := {"basic": 0.0, "fast": 2.0, "ranged": 3.0, "tank": 4.0, "boss": 5.0}
## A boss sets off at the start of its wave and walks at a tank's speed.
static func boss_arrival_seconds() -> float:
	return travel_seconds("boss")
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
	# No tier gives a starting Number since D068: the Health row sets it, as
	# The Tower's does.
	tiers = [
		TierDefinitionClass.new(1, 1.0, 1.0, 1.0, 0.0, 0),
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

## A wave's enemies, front first in arrival order: each is {kind, arrive}
## (D066). Ordinary enemies set off evenly through SPAWN_SECONDS and each is
## a type drawn from ENEMY_MIX; a boss wave's boss sets off at the start. The
## draw is seeded by the run and the wave, so a run's waves differ from the
## next run's but a saved run replays the same ones (law 6), and the run's
## own RNG stream is untouched.
func wave_roster(wave: int, seed: int = 0) -> Array:
	var count := ordinary_members(wave)
	var mixer := RandomNumberGenerator.new()
	mixer.seed = _roster_seed(seed, wave)
	var roster: Array = []
	for index in range(count):
		var kind := _draw_kind(mixer.randf())
		# Snapped to 1/64 of a second, which a saved run stores and reads back
		# exactly; 26/19 of a second does not survive JSON bit for bit (law 6).
		var sets_off := snappedf(SPAWN_SECONDS * float(index) / float(count - 1), 1.0 / 64.0) if count > 1 else 0.0
		roster.append({"kind": kind, "sets_off": sets_off, "arrive": sets_off + travel_seconds(kind), "order": index})
	if is_boss_wave(wave):
		roster.append({"kind": "boss", "sets_off": 0.0, "arrive": boss_arrival_seconds(), "order": -1})
	# Nearest the Number first; a fast enemy overtakes the slower ones set off
	# before it. Ties keep the order they set off in, the boss first.
	roster.sort_custom(func(a, b): return float(a.arrive) < float(b.arrive) or (float(a.arrive) == float(b.arrive) and int(a.order) < int(b.order)))
	for entry in roster:
		entry.erase("order")
	return roster

func _draw_kind(roll: float) -> String:
	var reached := 0.0
	for kind in ENEMY_MIX:
		reached += float(ENEMY_MIX[kind])
		if roll < reached:
			return kind
	return "basic"

## One integer from the run's seed and the wave, mixed so neighbouring waves
## and seeds draw unrelated rosters.
static func _roster_seed(seed: int, wave: int) -> int:
	var mixed := seed ^ (wave * 0x5851F42D4C957F2D)
	mixed ^= mixed >> 29
	mixed *= 0x14057B7EF767814F
	mixed ^= mixed >> 32
	return mixed

## How many enemies' worth of HP a whole wave carries: each enemy's type
## weight, the boss's included (D066).
func wave_weight(wave: int, seed: int = 0) -> float:
	return roster_weight(wave_roster(wave, seed))

func roster_weight(roster: Array) -> float:
	var total := 0.0
	for entry in roster:
		total += float(ENEMY_HP_WEIGHT[entry.kind])
	return total

## Each member's HP weight, front first in arrival order.
func member_weights(wave: int, seed: int = 0) -> Array:
	return wave_roster(wave, seed).map(func(entry): return float(ENEMY_HP_WEIGHT[entry.kind]))

## Coins a kill of `kind` pays at `wave`, before the Coins / Kill Bonus row
## and Coin Bonus (D068): its type's worth times the wave, times the tier's
## reward multiplier, as The Tower's kills pay (TheTowerSDK: kills x wave x
## type weight). The type worths are the owner's reference table (D066).
func kill_coins(tier_id: int, wave: int, kind: String) -> float:
	return float(KILL_COINS.get(kind, 0.0)) * float(maxi(1, wave)) * get_tier(tier_id).reward_multiplier

## What a wave's end pays in Coins (D068): the Coins / Wave row's value times
## the tier's reward multiplier, before Coin Bonus.
func wave_end_coins(tier_id: int, coins_per_wave: float) -> float:
	return coins_per_wave * get_tier(tier_id).reward_multiplier

## Coins became The Tower's scale with its Workshop (D068): a kill now pays
## about 15 times what it did, and The Tower's first Workshop rank costs 30
## Coins where ours cost 2. A save from before is converted at this rate
## (its Coins, and the Coins its retired Workshop ranks cost, refunded), and
## Coin prices and rewards that stayed ours (Labs, checkpoints) scale by it.
const COIN_RESCALE := 15.0

## The Cash one kill pays: its HP's share of its wave's Cash (D066).
func kill_cash(wave: int, weight: float, of: float) -> float:
	if of <= 0.0:
		return 0.0
	return wave_cash(wave) * weight / of

## How often a boss hits once it reaches the Number: as often as the enemies
## that stay at its wave (D063), and every 15 seconds through the opening,
## where ordinary enemies hit once and leave but a boss stays.
func boss_hit_seconds(wave: int) -> float:
	var interval := member_hit_seconds(wave)
	return interval if interval > 0.0 else OPENING_HIT_SECONDS

## Every member's arrival, front first, the boss's included.
func member_arrivals(wave: int, seed: int = 0) -> Array:
	return wave_roster(wave, seed).map(func(entry): return float(entry.arrive))

## The latest any member can arrive: the last to set off, at the slowest
## speed. A member may arrive after its wave's clock ends, and is carried.
static func latest_arrival() -> float:
	var slowest := 0.0
	for kind in ENEMY_SPEED:
		slowest = maxf(slowest, travel_seconds(kind))
	return SPAWN_SECONDS + slowest

func is_boss_wave(wave: int) -> bool:
	return wave > 0 and wave % BOSS_WAVE_INTERVAL == 0

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

## A wave's whole HP: one enemy's times every enemy's worth it carries (D065),
## for the roster `seed` draws (D066).
func liability_for_wave(tier_id: int, wave: int, seed: int = 0) -> ScientificNumber:
	var tier: Variant = get_tier(tier_id)
	return _from_log10(_wave_hp_log10(wave) + log(tier.liability_multiplier * wave_weight(wave, seed)) / log(10.0))

## One basic enemy's HP at a tier and wave.
func enemy_liability(tier_id: int, wave: int) -> ScientificNumber:
	return _from_log10(_wave_hp_log10(wave) + log(get_tier(tier_id).liability_multiplier) / log(10.0))

## The Hit one enemy lands at a tier and wave, whatever its type (D066).
func enemy_collection(tier_id: int, wave: int) -> ScientificNumber:
	return _from_log10(_wave_hit_log10(wave) + log(get_tier(tier_id).collection_multiplier) / log(10.0))

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

## A wave's whole Hit, weighted like its HP. Every member lands one enemy's
## Hit, which is this over the wave's weight, whatever it carries in HP: a tank
## or a boss hits like any enemy (D063, D066).
func collection_for_wave(tier_id: int, wave: int, seed: int = 0) -> ScientificNumber:
	var tier: Variant = get_tier(tier_id)
	return _from_log10(_wave_hit_log10(wave) + log(tier.collection_multiplier * wave_weight(wave, seed)) / log(10.0))

## Every tier shares the same wave base, which keeps the 1.8x/2.6x reward
## ratios honest at equal waves.
func reward_for_wave(tier_id: int, wave: int) -> int:
	var base_reward := float(maxi(1, wave)) * WAVE_REWARD_SCALE
	var boss_multiplier := BOSS_REWARD_MULTIPLIER if is_boss_wave(wave) else 1.0
	return maxi(1, roundi(base_reward * get_tier(tier_id).reward_multiplier * boss_multiplier))

## The Cash a whole wave is worth (D042), paid by its kills, each its HP's
## share (D066).
func wave_cash(wave: int) -> float:
	var boss_multiplier := BOSS_CASH_MULTIPLIER if is_boss_wave(wave) else 1.0
	return (CASH_WAVE_BASE + CASH_PER_WAVE * float(maxi(1, wave))) * boss_multiplier

func is_milestone_wave(wave: int) -> bool:
	return MILESTONE_WAVES.has(wave)

## The Coin bonus a checkpoint pays on top of the wave's own reward.
func milestone_bonus(tier_id: int, wave: int) -> int:
	if not COIN_MILESTONE_WAVES.has(wave):
		return 0
	return maxi(1, roundi(float(wave) * get_tier(tier_id).reward_multiplier * 2.0 * COIN_RESCALE))

## The Gems a checkpoint pays, once per tier record.
func milestone_gems(tier_id: int, wave: int) -> int:
	if not MILESTONE_WAVES.has(wave):
		return 0
	return maxi(1, roundi(MILESTONE_GEM_SCALE * sqrt(float(wave)) * get_tier(tier_id).reward_multiplier))

## The Gem a boss wave's boss pays when it falls, checkpoint or not (D030,
## D066).
func wave_gems(wave: int) -> int:
	return BOSS_WAVE_GEMS if is_boss_wave(wave) else 0

## Combined ceilings (D023). Labs and Cards stack on the Workshop rows, so a
## row's own cap does not bound the combined effect. Defense % stops at The
## Tower's global 98% (community research, not verified); Thorns at all of an
## enemy's health.
const DEFENSE_PERCENT_CEILING := 0.98
const RECOIL_CEILING := 1.0
## Bosses take half of Thorns, as The Tower's do (D064).
const BOSS_THORNS_SHARE := 0.5

## The Tower's attack rows (D068), where its tables leave a rule to us.
## Rapid Fire fires four times as fast, as the row's own text says.
const RAPID_FIRE_SPEED := 4.0
## Orbs circle at The Tower's 60 m or more, drifting out at half the Range past
## it (the wiki: "lower than a 1:1 adjustment"), and kill any enemy but a boss
## whose centre comes within ORB_HIT_METRES of one: ours.
const ORB_MIN_RADIUS_METRES := 60.0
const ORB_HIT_METRES := 3.0
## Knockback (D068): a push of the row's force times this many metres, over the
## enemy's mass relative to a basic (TheTowerSDK's Wave Info masses). The
## metres per unit of force are ours; The Tower gives force no unit.
const KNOCKBACK_METRES_PER_FORCE := 5.0
const ENEMY_MASS := {"basic": 1.0, "fast": 1.0, "tank": 4.85627, "ranged": 1.0, "boss": 12.38}

static func orb_radius(range_metres: float) -> float:
	return ORB_MIN_RADIUS_METRES + 0.5 * maxf(0.0, range_metres - ORB_MIN_RADIUS_METRES)

static func knockback_metres(force: float, kind: String) -> float:
	return force * KNOCKBACK_METRES_PER_FORCE / float(ENEMY_MASS.get(kind, 1.0))

func _from_log10(value_log: float) -> ScientificNumber:
	if not is_finite(value_log):
		return ScientificNumber.new()
	var value_exponent := floori(value_log)
	return ScientificNumber.new(pow(10.0, value_log - float(value_exponent)), value_exponent)
