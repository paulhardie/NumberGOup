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

## Each hit an enemy lands makes its next 4% harder, compounding. The earlier
## research says the SDK agrees; the owner's 25 September research says it
## grows per wave survived instead. Unsettled.
const HEAT_UP_PER_HIT := 1.04

## Enemies a wave, bosses aside: 11 at wave 1 (the owner: "about 10 to 12",
## two or three on screen at once early), plus 0.123 a wave to wave 1,000
## (about 133 there, near TheTowerSDK's 120-143), then 0.0145 a wave, at most
## 220. The SDK's early counts (about 4) contradict the owner's screens.
const FIRST_WAVE_ENEMIES := 11
const ENEMIES_PER_WAVE := 0.123
const DEEP_ENEMIES_FROM := 1000
const DEEP_ENEMIES_PER_WAVE := 0.0145
const MAX_WAVE_ENEMIES := 220

## Cash every run starts with: none, until the Starting Cash lab (not built;
## The Tower opens it at Tier 1 wave 30, $5 a level). The owner, 26 September.
## TheTowerSDK's $80 is its figure for Utility Dissonance runs, and the $93 on
## the owner's first Tower screen is likely a pack's; neither is a new run's.
const STARTING_CASH := 0.0

## Knockback: metres a unit of force pushes a basic enemy; heavier enemies go
## as much less far as their mass is greater (D068). The Tower gives no units.
const KNOCKBACK_METRES_PER_FORCE := 5.0

## Orbs circle on the edge of the tower's Range and kill an enemy but a boss
## that comes within ORB_HIT_M of one, ranged enemies standing on that edge
## included (the owner, 26 September). At Orb Speed's first level they make a
## full turn a second, and faster in proportion to the row's value. The 3 m
## is ours.
const ORB_TURNS_PER_SECOND_AT_FIRST_LEVEL := 1.0
const ORB_HIT_M := 3.0

## The Wall stands this far out; melee enemies stop at it and hit it while
## it stands. Ours; The Tower gives no units.
const WALL_DISTANCE_M := 10.0

## Land Mines: at most this many lie in range at once, and a walking enemy
## within this many metres of one sets it off. Ours.
const MAX_LAND_MINES := 30
const LAND_MINE_TRIGGER_M := 2.0

## A shot's flight speed, metres a second.
const SHOT_SPEED_M := 80.0

## Cash a kill pays, times $1 plus $1 every ten waves (D071, from community
## research). The boss's 20 is ours until the owner reads one boss kill.
const CASH_BY_TYPE := {"basic": 1.0, "fast": 2.0, "ranged": 2.0, "tank": 5.0, "boss": 20.0}

## Coins a kill pays, flat, whatever its wave (the owner's reference table;
## D074). Paid times the wave, as the SDK's model has it, a wave-22 run earned
## about 14 times the owner's Tower report; flat is within 2 times.
const COINS_BY_TYPE := {"basic": 0.0, "fast": 2.0, "ranged": 3.0, "tank": 4.0, "boss": 5.0}


static func enemies_in_wave(wave: int) -> int:
	var w := maxi(1, wave)
	var count := FIRST_WAVE_ENEMIES + floori(ENEMIES_PER_WAVE * float(mini(w, DEEP_ENEMIES_FROM) - 1))
	if w > DEEP_ENEMIES_FROM:
		count += floori(DEEP_ENEMIES_PER_WAVE * float(w - DEEP_ENEMIES_FROM))
	return mini(count, MAX_WAVE_ENEMIES)
