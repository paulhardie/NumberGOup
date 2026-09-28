extends RefCounted
## Every number the game needs that The Tower doesn't tell us, in one place,
## so the owner can replace each when they read the real one
## (docs/REBUILD_SPEC.md, "Guesses"). Numbers The Tower does give live in the
## generated data under data/, never here.

## Metres from the tower where enemies set off. The Tower gives no units; this
## puts them just past the largest Range row (69.5 m), as D067 did.
const SPAWN_DISTANCE_M := 100.0

## Metres a second for SDK speed 1 (a basic enemy before wave 141).
const METRES_PER_SPEED := 10.0

## Where a melee enemy stops: the tower's edge.
const CONTACT_DISTANCE_M := 3.0

## Seconds between an enemy's hits once it is in place, first hit on arrival:
## about one a second at ×1 (the owner, 26 September). TheTowerSDK has no enemy
## attack interval. Ranged enemies stop on the edge of the tower's Range; that
## rule lives in BattleSim, since it follows the Range row.
const ENEMY_HIT_SECONDS := 1.0

## The spawn rate at wave 1 (D114), which no screen has shown: 5, so that a
## wave-1 spawning window of 208 rolls sends about 11 enemies, as the owner
## counted ("about 10 to 12"). From there the rate runs in a straight line to
## each known one (TowerData.spawn_rate): the owner's 15 at wave 22, then the
## SDK's 37 at wave 1,000; the lines between are ours.
const FIRST_WAVE_SPAWN_RATE := 5.0

## Cash every run starts with: none, until the Starting Cash lab (not built;
## The Tower opens it at Tier 1 wave 30, $5 a level). The owner, 26 September.
## TheTowerSDK's $80 is its figure for Utility Dissonance runs, and the $93 on
## the owner's first Tower screen is likely a pack's; neither is a new run's.
const STARTING_CASH := 0.0

## Knockback: metres a unit of force pushes a basic enemy; heavier enemies go
## as much less far as their mass is greater (D068). The Tower gives no units.
const KNOCKBACK_METRES_PER_FORCE := 5.0

## Orbs (D108, The Tower's as the community wikis state them): Orb Speed is
## rotations a minute, 0.4 at the first level (a turn every 2½ minutes) to 6.10
## at the last (one every 10 seconds). They circle at least ORB_MIN_RADIUS_M out,
## outside a 30 m Range, so they sweep the approach rather than the range's
## edge; past that, they sit further inside a growing Range, by ORB_RANGE_SLOPE
## of every metre over the minimum (the slope is ours: The Tower says only "not
## one to one"). They kill an enemy that comes within ORB_HIT_M of one (ours),
## unless it's one orbs can't kill (ORB_IMMUNE).
const ORB_TURNS_PER_SECOND_AT_FIRST_LEVEL := 0.4 / 60.0
const ORB_MIN_RADIUS_M := 60.0
const ORB_RANGE_SLOPE := 0.5
const ORB_HIT_M := 3.0
## Enemies orbs can't kill (D104): bosses and The Tower's elites (D115). An
## enemy a Protector shields can't be killed by them either (BattleSim).
const ORB_IMMUNE := ["boss", "vampire", "ray", "scatter"]

## A Scatter's two pieces land this many radians either side of where it
## fell. Ours; The Tower's split in two is all that's known.
const SCATTER_SPREAD := 0.06

## The Wall stands this far out; melee enemies stop at it and hit it while
## it stands. Ours; The Tower gives no units.
const WALL_DISTANCE_M := 10.0

## Land Mines: at most this many lie in range at once, and a walking enemy
## within this many metres of one sets it off. Ours.
const MAX_LAND_MINES := 30
const LAND_MINE_TRIGGER_M := 2.0

## A shot's flight speed, metres a second.
const SHOT_SPEED_M := 80.0

## Cash a kill pays, times what its wave pays (TowerData.kill_cash, D116).
## These weights are community research (D071); the boss's 20 is ours until
## the owner reads one boss kill, and so are the Protector's and the elites',
## set at their Coin values (D115).
## A Scatter's split-off pieces pay as basics.
const CASH_BY_TYPE := {"basic": 1.0, "fast": 2.0, "ranged": 2.0, "tank": 5.0, "boss": 20.0, "divider": 2.0,
	"protector": 3.0, "vampire": 4.0, "ray": 4.0, "scatter": 4.0}

## Coins a kill pays, flat, whatever its wave (the owner's reference table;
## D074). Paid times the wave, as the SDK's model has it, a wave-22 run earned
## about 14 times the owner's Tower report; flat is within 2 times. Ranged pays
## 2, as The Tower's own enemy list says (D082); the Protector 3 and the
## elites 4 (the SDK's base coin values, D115). A Scatter's pieces pay as basics.
const COINS_BY_TYPE := {"basic": 0.0, "fast": 2.0, "ranged": 2.0, "tank": 4.0, "boss": 5.0, "divider": 2.0,
	"protector": 3.0, "vampire": 4.0, "ray": 4.0, "scatter": 4.0}

## How much of Lifesteal still works once the Number is past Health: 0 would
## be a ceiling (D081); all of it is the owner's choice (D083), measured in
## docs/THE_NUMBER.md 1.2. Health is where the Number starts and what buying
## Number adds to, not a limit. Regen follows PEAK_REGEN_DRIFT instead (D111).
const NUMBER_OVERFILL := 1.0

## The Divider (D082, docs/THE_NUMBER.md section 7): ours, not The Tower's. It
## walks in at a basic enemy's speed and, on reaching the Number, takes away
## 1 - 1/divisor of it through the defences, and is used up. A bigger divisor
## takes more (÷2 half, ÷3 two thirds), so Tier 1, the tutorial, stays gentle
## (D083): ÷1.25 (a fifth) at FROM_WAVE, rising to ÷1.5 (a third) by FULL_WAVE,
## in steps of DIVISOR_STEP so it always reads cleanly (÷1.25 to wave 17, then
## ÷1.5). ÷2 and beyond are for later tiers. Each Divider keeps the divisor it
## spawned with, which is what it shows.
## It takes the Protector's slot in The Tower's standard pool (D094), replacing
## one of a wave's basics, and like the Protector comes at most once a wave.
## None before FROM_WAVE; from there RATE_FIRST a wave (one every third wave,
## so the first comes on wave 7), rising in a straight line to RATE_FULL
## (every other wave) at FULL_WAVE and holding there: rarer than the
## Protector's one a wave, which the owner judged too much for Tier 1. One on
## wave 5 itself cost a fresh tower two waves, below The Tower's wave 8. Its health, in basic enemies',
## can ramp the same way from HEALTH_FIRST to HEALTH_FULL. At ÷2 a fresh tower
## needed 2× at first to keep The Tower's wave-8 death; at Tier 1's gentler
## divisors 4× throughout keeps it, and most Dividers land: frequent, small ÷
## moments that teach the enemy (D083, measured in THE_NUMBER.md 7).
const DIVIDER := {
	"divisor_first": 1.25,
	"divisor_full": 1.5,
	"divisor_step": 0.25,
	"health_first": 4.0,
	"health_full": 4.0,
	"speed": 1.0,
	"from_wave": 5,
	"full_wave": 30,
	"rate_first": 1.0 / 3.0,
	"rate_full": 0.5,
}


## How the Number grows (D111, tested as D098's switches): from fighting and
## buying, with regen only restoring. Both are weak on purpose at the start,
## so the Number climbs slowly early; Labs and Cards are what should raise
## them later, and nothing does yet.
## Regen fills the Number in full up to the highest it has stood this run,
## and past that only at this share (0: it never makes a new high). Lifesteal,
## bought Health and kills still can.
const PEAK_REGEN_DRIFT := 0.0
## An enemy killed before it has landed a hit adds this share of its Attack
## to the Number; one that has hit you adds nothing. Its Attack grows with the
## waves as The Tower's does, so the growth does too, and a boss is a big
## moment.
const KILL_GROWTH := 0.05

## Milestones (D107): the first time the player's best Number reaches each
## new digit, the Workshop gets a one-off Coin reward, sized to the Coins a
## run earns around then. Rewards, never gates: no system waits on the Number.
## Ours; The Tower's milestones are by wave and pay other currencies.
const MILESTONES := [
	{"number": 10.0, "coins": 10.0},
	{"number": 100.0, "coins": 50.0},
	{"number": 1000.0, "coins": 250.0},
	{"number": 10000.0, "coins": 2500.0},
	{"number": 100000.0, "coins": 10000.0},
	{"number": 1000000.0, "coins": 50000.0},
]

