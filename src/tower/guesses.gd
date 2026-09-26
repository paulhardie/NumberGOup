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

## Where a ranged enemy stops and fires from (D067).
const RANGED_DISTANCE_M := 30.0

## Seconds between an enemy's hits once it is in place, first hit on arrival
## (D072). TheTowerSDK has no enemy attack interval.
const ENEMY_HIT_SECONDS := 5.0

## Each hit an enemy lands makes its next 4% harder, compounding. The earlier
## research says the SDK agrees; the owner's 25 September research says it
## grows per wave survived instead. Unsettled.
const HEAT_UP_PER_HIT := 1.04

## Enemies a wave, bosses aside: 20 at wave 1, plus 0.123 a wave to wave
## 1,000, then 0.0145 a wave, at most 220 (D065). The SDK's spawn model says
## about 4 early, which the owner's screens contradict (10+ on screen by wave 8,
## 16 active at wave 22).
const FIRST_WAVE_ENEMIES := 20
const ENEMIES_PER_WAVE := 0.123
const DEEP_ENEMIES_FROM := 1000
const DEEP_ENEMIES_PER_WAVE := 0.0145
const MAX_WAVE_ENEMIES := 220

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
