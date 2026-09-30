extends RefCounted
## What each kind of enemy is, in one place (D117): its traits (where it
## stops, what can't touch it, how it attacks) and the maths of its numbers
## (health, attack, speed, mass, what it pays). The Tower's numbers come from
## the generated data through TowerData, ours from Guesses. BattleSim, its
## defences and the screens ask here rather than testing kinds themselves.

const Guesses = preload("res://src/tower/guesses.gd")
const TowerData = preload("res://src/tower/tower_data.gd")

## Each kind's traits; any a kind leaves out take DEFAULTS.
## - stops_at_range: it stops on the edge of the tower's Range and attacks
##   from there, rather than walking to the Number.
## - orbs_kill, shockwave_moves: whether orbs can kill it and shockwaves push
##   it. The Tower's bosses and elites are immune to both (D104, D115).
## - knockback_moves: whether Knockback pushes it at all. The Tower's Ray is
##   immune (D117); every other kind is pushed less the heavier it is.
## - thorns: the share of Thorns it takes; a boss takes half (TheTowerSDK's
##   breakpoints agree).
## - attack: "hit" every ENEMY_HIT_SECONDS; "charge", a Ray's charged shot;
##   "drain", a Vampire's share of Health a second; "divide", a Divider's ÷;
##   "hold", a Lock's: no hit, but the Number can't go up while it stands.
const TRAITS := {
	"ranged": {"stops_at_range": true},
	"boss": {"orbs_kill": false, "shockwave_moves": false, "thorns": 0.5},
	"vampire": {"stops_at_range": true, "orbs_kill": false, "shockwave_moves": false, "attack": "drain"},
	"ray": {"stops_at_range": true, "orbs_kill": false, "shockwave_moves": false, "knockback_moves": false, "attack": "charge"},
	"scatter": {"orbs_kill": false, "shockwave_moves": false},
	"divider": {"attack": "divide"},
	"lock": {"stops_at_range": true, "attack": "hold"},
}
const DEFAULTS := {"stops_at_range": false, "orbs_kill": true, "shockwave_moves": true, "knockback_moves": true, "thorns": 1.0, "attack": "hit"}


static func _trait(kind: String, name: String):
	return TRAITS.get(kind, {}).get(name, DEFAULTS[name])


static func is_elite(kind: String) -> bool:
	return kind in TowerData.ELITES


static func stops_at_range(kind: String) -> bool:
	return _trait(kind, "stops_at_range")


static func orbs_kill(kind: String) -> bool:
	return _trait(kind, "orbs_kill")


static func shockwave_moves(kind: String) -> bool:
	return _trait(kind, "shockwave_moves")


static func knockback_moves(kind: String) -> bool:
	return _trait(kind, "knockback_moves")


static func thorns_share(kind: String) -> float:
	return _trait(kind, "thorns")


static func attack_style(kind: String) -> String:
	return _trait(kind, "attack")


## Seconds from one hit to the next: a Ray's charge, else Guesses' second.
## A Ray charges before its first shot too.
static func hit_seconds(kind: String) -> float:
	if attack_style(kind) == "charge":
		return float(TowerData.enemies().elites.ray_charge_seconds)
	return Guesses.ENEMY_HIT_SECONDS


## A `kind`'s health at Enemy Level Skip's `level`, on `wave`, in `tier`. The
## Divider and the Lock aren't The Tower's: their health is a basic enemy's
## times the run's `divider` or `lock` numbers (Guesses.DIVIDER, Guesses.LOCK).
static func health(kind: String, level: int, wave: int, tier: int, divider: Dictionary, lock: Dictionary = Guesses.LOCK) -> float:
	var scale := float(TowerData.tier(tier).enemy_health)
	if kind == "lock":
		return TowerData.enemy_health(level, "basic") * float(lock.health) * scale
	if kind == "divider":
		return TowerData.enemy_health(level, "basic") * lerpf(float(divider.health_first), float(divider.health_full), divider_ramp(divider, wave)) * scale
	return TowerData.enemy_health(level, kind) * scale


## A `kind`'s attack at Enemy Level Skip's `level`, in `tier`. A Divider
## doesn't subtract: it takes a share (BattleSim._divide); a Lock never hits.
static func attack(kind: String, level: int, tier: int) -> float:
	if kind == "divider" or kind == "lock":
		return 0.0
	return TowerData.enemy_attack(level, kind) * float(TowerData.tier(tier).enemy_attack)


## Metres a second on `wave`: a tier's weight speeds every enemy as it raises
## the shares (D115).
static func speed_m(kind: String, wave: int, tier: int, divider: Dictionary) -> float:
	var weight := float(TowerData.tier(tier).mix_weight)
	if kind == "divider":
		return TowerData.enemy_speed_m(wave, "basic") * float(divider.speed) * weight
	if kind == "lock":
		return TowerData.enemy_speed_m(wave, "basic") * weight
	return TowerData.enemy_speed_m(wave, kind) * weight


## A kind's mass over a basic enemy's; a Divider and a Lock weigh as a basic.
static func mass_ratio(kind: String) -> float:
	return 1.0 if kind == "divider" or kind == "lock" else TowerData.mass_ratio(kind)


## The mass a `kind` spawns with on `wave` (heavier past wave 4,000).
static func spawn_mass(kind: String, wave: int) -> float:
	return mass_ratio(kind) * TowerData.mass_growth(wave)


## How heavy `enemy` is on `wave`, over a basic enemy on wave 1: its mass as
## it spawned, 4% more for each wave since (D115). Knockback pushes it that
## much less.
static func mass_now(enemy, wave: int) -> float:
	return enemy.mass * pow(float(TowerData.enemies().mass_per_wave_alive), wave - enemy.wave)


## What a kill pays as: a Scatter's split-off pieces pay as basics.
static func pays_as(enemy) -> String:
	return "basic" if enemy.generation > 0 else enemy.kind


## The Cash `enemy` pays when killed: its wave's Cash (TowerData.kill_cash)
## times its kind's weight and Cash Bonus.
static func cash(enemy, cash_bonus: float) -> float:
	return TowerData.kill_cash(enemy.wave) * float(Guesses.CASH_BY_TYPE[pays_as(enemy)]) * cash_bonus


## The Coins `enemy` pays when killed on `wave`: its kind's Coins times Coins /
## Kill and the tier's bonus, halved once it has lived three waves (The
## Tower's coin decay, D115).
static func coins(enemy, wave: int, coins_per_kill: float, tier: int) -> float:
	var paid := float(Guesses.COINS_BY_TYPE[pays_as(enemy)]) * coins_per_kill * float(TowerData.tier(tier).coins)
	var decay: Dictionary = TowerData.enemies().coin_decay
	if wave - enemy.wave >= int(decay.after_waves):
		paid *= float(decay.share)
	return paid


## How many Dividers a wave brings, on average: a fraction of one.
static func divider_rate(divider: Dictionary, wave: int) -> float:
	if wave < int(divider.from_wave):
		return 0.0
	return lerpf(float(divider.rate_first), float(divider.rate_full), divider_ramp(divider, wave))


## The divisor a Divider spawning on `wave` carries.
static func divider_divisor(divider: Dictionary, wave: int) -> float:
	var smooth := lerpf(float(divider.divisor_first), float(divider.divisor_full), divider_ramp(divider, wave))
	# In clean steps, so the ÷ on its body always reads simply.
	return snappedf(smooth, float(divider.get("divisor_step", 0.0))) if float(divider.get("divisor_step", 0.0)) > 0.0 else smooth


## How far along its ramp the Divider is on `wave`: 0 at its first wave, 1
## from its full wave on.
static func divider_ramp(divider: Dictionary, wave: int) -> float:
	var first := int(divider.from_wave)
	return clampf(float(wave - first) / float(maxi(1, int(divider.full_wave) - first)), 0.0, 1.0)


## Whether a Lock (Guesses.LOCK's shape) comes on `wave`: on its first wave
## and every `every_first` waves after, then every `every_full` from its full
## wave. A fixed beat rather than a chance, so nothing about it needs saving.
static func lock_comes(lock: Dictionary, wave: int) -> bool:
	return lock_waits(lock, wave) == 0


## Waves until the next Lock from `wave`: 0 if one comes on it, -1 if none
## ever will.
static func lock_waits(lock: Dictionary, wave: int) -> int:
	var first := int(lock.from_wave)
	if first <= 0:
		return -1
	if wave < first:
		return first - wave
	var full := maxi(first, int(lock.full_wave))
	var every := maxi(1, int(lock.every_first))
	# On the first beat until its next would pass the full wave; the second
	# beat counts from the full wave itself.
	if wave < full:
		var next := wave + posmod(first - wave, every)
		if next < full:
			return next - wave
	var every_full := maxi(1, int(lock.every_full))
	return posmod(full - wave, every_full)
