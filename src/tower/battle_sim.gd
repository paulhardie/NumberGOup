extends RefCounted
## One run of the battle: the Number in the centre (the tower, D080), Tier 1's
## waves walking in. Its health is the Number: The Tower's flat enemies take
## from it, and Dividers (D082) take a share of it.
## It is the only owner of combat rules. The battle screen draws it and the
## headless tools run it, so what is measured is exactly what is played.
## It steps in fixed ticks from a seed, so the same seed and the same inputs
## always give the same run.

const Guesses = preload("res://src/tower/guesses.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const BattleDefences = preload("res://src/tower/battle_defences.gd")

const TICK := 1.0 / 30.0


class Enemy:
	var id: int
	var kind: String
	var wave: int
	var health: float
	var max_health: float
	var attack: float
	var speed: float
	var angle: float
	var distance: float
	var stop_at: float
	## Seconds until its next hit; it hits on arrival, then every
	## Guesses.ENEMY_HIT_SECONDS.
	var hit_in := 0.0
	var hits := 0
	## Where it was a tick ago, so the screen can draw between the two.
	var last_distance: float
	## Rend Armor: how much more damage this enemy takes from strikes.
	var rend := 0.0
	## A Divider's divisor, fixed when it spawns; 0 for every other enemy.
	var divisor := 0.0
	## Its mass over a basic enemy's on wave 1, as it spawned (D115); it grows
	## for each wave it stays alive (BattleSim.knock_mass).
	var mass := 1.0
	## A Scatter's splits behind it: 0 as it spawns, one more each split.
	var generation := 0

	func position() -> Vector2:
		return Vector2.from_angle(angle) * distance

	## Where to draw it `blend` of the way from the last tick to this one.
	func drawn_at(blend: float) -> Vector2:
		return Vector2.from_angle(angle) * lerpf(last_distance, distance, blend)

	func arrived() -> bool:
		return distance <= stop_at


class Shot:
	var target: Enemy
	var position: Vector2
	var last_position: Vector2
	var damage: float
	var critical: bool
	## Bounce Shot: -1 until its first strike rolls for a bounce, then how many
	## more enemies it may bounce on to.
	var bounces := -1
	## The enemies this shot and its bounces have struck, never struck twice.
	var struck: Array[int] = []


## The groups of rows a run may buy from, before the Workshop opens more.
const START_GROUPS := ["attack_start", "defense_start"]
## The most Defense % can take off a hit (community research, unverified).
const DEFENSE_PERCENT_CAP := 0.98
## A boss takes this share of Thorns (TheTowerSDK's breakpoints agree).
const BOSS_THORNS_SHARE := 0.5
## Rapid Fire fires four times as fast while it lasts (the community wiki).
const RAPID_FIRE_SPEED := 4.0
## The most Interest pays a wave before Labs raise it (D071).
const INTEREST_CAP := 50.0
## The Free Upgrade row for each category.
const FREE_UPGRADE_ROWS := {"attack": "free_attack_upgrade", "defense": "free_defense_upgrade", "utility": "free_utility_upgrade"}
## Rend Armor stacks to 800% more damage taken (the community wiki).
const REND_CAP := 8.0
const SKIP_SLACK := 1e-9

var run_seed: int
## Row id → Workshop level, the level every run starts from. Rows not listed
## are at level 0.
var levels: Dictionary
## Row id → levels bought with Cash in this run, on top of the Workshop's.
var run_levels: Dictionary = {}
var open_groups: Array = START_GROUPS.duplicate()

var time := 0.0
var wave := 1
var wave_clock := 0.0
var alive := true
## What ended the run: an enemy kind, or "ended" when the player stopped it.
var killed_by := ""

var health: float
var cash := Guesses.STARTING_CASH
var cash_earned := 0.0
var coins := 0.0
var kills := 0

var enemies: Array[Enemy] = []
var shots: Array[Shot] = []

## What happened this tick, for the screen: {type, ...}. Only filled while
## record_events is on, so headless runs don't build it up.
var record_events := false
var events: Array[Dictionary] = []

## Ticks stepped so far, and every input that changed the run with the tick
## it came after: {tick, buy, count} or {tick, end}. With the seed and the
## starting Workshop they replay the run exactly (src/tower/run_report.gd).
var ticks := 0
var inputs: Array[Dictionary] = []
## How the run stood as each wave ended, for the activity log.
var wave_log: Array[Dictionary] = []

var _spawn_rng := RandomNumberGenerator.new()
var _combat_rng := RandomNumberGenerator.new()
## Which basic a Divider replaces is drawn from its own stream, so The Tower's
## enemies, which kinds come and where from, are exactly what they were
## without it.
var _divider_rng := RandomNumberGenerator.new()
## The Divider owed but not yet due: a wave's share carries to the next.
var _divider_due := 0.0
## How the Number grows (D111, from D098's tests): regen restores it only
## up to its best, past which it drifts at `peak_drift`'s share, and an enemy
## killed before it lands a hit grows it by `kill_share` of its Attack. Both
## start weak on purpose (Guesses); the measuring tools may change them before
## the first step to try others.
var peak_drift := Guesses.PEAK_REGEN_DRIFT
## The tier this run plays (D107, D112): its row in TowerData scales enemy
## health, attack and Coins and shapes each wave's spawns. The game plays
## Tier 1 until tiers open (1.4); the measuring tools may choose another.
var tier := 1
var kill_share := Guesses.KILL_GROWTH
## The Divider's numbers for this run (Guesses.DIVIDER), which the measuring
## tools may change before the first step to try others.
var divider: Dictionary = Guesses.DIVIDER.duplicate()
## Guesses.NUMBER_OVERFILL for this run, which the measuring tools may change.
var overfill := Guesses.NUMBER_OVERFILL
## Measuring options for sim_runs.gd, off in the game so every run and replay
## is as before. `packages_to_best`: a Recovery Package refills the Number
## only up to this run's best, never past it. `sure_from`: from that wave
## (0: never), every `sure_every` waves, a Divider that nothing can stop
## lands ÷`sure_divisor` SURE_LANDS_AT seconds into the wave, through the
## same defences as any Divider.
var packages_to_best := false
var sure_from := 0
var sure_every := 5
var sure_divisor := 1.1
const SURE_LANDS_AT := 10.0
var _sure_landed := 0

## The highest the Number has stood this run: the run's record (D081).
var peak_number := 0.0
## What the Number has lost to each kind of enemy, after defences.
var lost_to: Dictionary = {}
## What the Number has gained from each source ("regen", "lifesteal",
## "health" bought or free, "package"), and the part of each that lifted it to
## a new high: what makes the Number go up rather than refilling it. Counted
## only; nothing reads them to decide anything.
var gained_from: Dictionary = {}
var raised_by: Dictionary = {}
## The highest the Number has stood, as the gains above see it.
var _high := 0.0
## Dividers that came, and the ones that reached the Number or the Wall.
var dividers_spawned := 0
var dividers_landed := 0
var _schedule: Array[Dictionary] = []
var _next_spawn := 0
## This wave's spawns so far, and those the caps turned away (Wave Info).
var wave_spawned := 0
var wave_missed := 0
## The Protector's gate (D115): waves counted down, 2 a wave, until one may
## come; whether one may this wave, and the Protectors on the field.
var _protector_gate := 0
var _protector_due := false
var _protectors: Array[Enemy] = []
## Whether a Vampire was draining the tower last tick, which stops Regen and
## Lifesteal (D115).
var draining := false
var _next_id := 1
var _shot_charge := 0.0
## Seconds of Rapid Fire left.
var rapid_fire_left := 0.0

## The Wall, orbs, shockwaves and land mines, with their own state.
var defences := BattleDefences.new(self)
## Enemy Level Skip: the wave whose health and attack enemies have, which
## lags the wave by every level skipped.
var health_level := 1
var attack_level := 1
var _health_skip := 0.0
var _attack_skip := 0.0


## `row_levels` and `groups` are the Workshop's: the levels a run starts from
## and the groups it may buy from.
func _init(seed_value: int, row_levels: Dictionary = {}, groups: Array = START_GROUPS, run_tier: int = 1) -> void:
	run_seed = seed_value
	tier = clampi(run_tier, 1, TowerData.tier_count())
	levels = row_levels.duplicate()
	open_groups = groups.duplicate()
	# Two streams, so a change in how often the tower fires or crits never
	# changes which enemies a wave sends.
	_spawn_rng.seed = hash([seed_value, "spawn"])
	_combat_rng.seed = hash([seed_value, "combat"])
	_divider_rng.seed = hash([seed_value, "divider"])
	_protector_gate = int(TowerData.tier(tier).protector_gate)
	health = max_health()
	peak_number = health
	_high = health
	defences.start()
	_schedule_wave()


## Where the two random streams stand, as text: their 64-bit states are more
## than JSON's numbers hold exactly. A replay that drew exactly the same
## numbers ends with the same states.
func rng_state() -> Array[String]:
	return [str(_spawn_rng.state), str(_combat_rng.state), str(_divider_rng.state)]


func level(id: String) -> int:
	return int(levels.get(id, 0)) + int(run_levels.get(id, 0))


func stat(id: String) -> float:
	return TowerData.value(id, level(id))


func is_open(id: String) -> bool:
	return TowerData.group(id) in open_groups


func at_max(id: String) -> bool:
	return level(id) >= TowerData.max_level(id)


## What one more level of `id` costs now. The Tower prices a run's upgrades by
## how many of that row the run has bought, whatever the Workshop level.
func price(id: String) -> float:
	return TowerData.cash_price(id, int(run_levels.get(id, 0)))


## What a buy of `count` levels of `id` gets and costs; 0 is Max, as many as
## the Cash covers (TowerData.plan_buy).
func plan(id: String, count: int = 1) -> Dictionary:
	return TowerData.plan_buy(TowerData.upgrade(id)["cash_prices"], int(run_levels.get(id, 0)), TowerData.max_level(id) - level(id), count, cash)


func can_buy(id: String, count: int = 1) -> bool:
	if not alive or not is_open(id):
		return false
	var buying := plan(id, count)
	return int(buying.levels) > 0 and cash >= float(buying.cost)


## Buys `count` levels of `id` (0: Max) with Cash; false, and nothing
## changes, if it can't.
func buy(id: String, count: int = 1) -> bool:
	if not can_buy(id, count):
		return false
	var buying := plan(id, count)
	cash -= float(buying.cost)
	for _level in range(int(buying.levels)):
		_raise(id)
	inputs.append({"tick": ticks, "buy": id, "count": count})
	return true


## One more run level of `id`, bought or free.
func _raise(id: String) -> void:
	var health_before := max_health()
	var before := health
	run_levels[id] = int(run_levels.get(id, 0)) + 1
	# More Health raises the health you have now by the same amount.
	health += max_health() - health_before
	_count_gain("health", before)


func max_health() -> float:
	return stat("health")


## Regen restores in full up to the higher of Health and the run's best, and
## past it only at `peak_drift`'s share (D111). Lifesteal fills in full up to
## Health, and past it at `overfill`'s share (Guesses.NUMBER_OVERFILL; 0 is a
## ceiling). Neither takes away a recovery package's overheal.
func _heal(amount: float, source: String) -> void:
	# A draining Vampire stops both (D115); packages still land.
	if draining and (source == "regen" or source == "lifesteal"):
		return
	var before := health
	if source == "regen":
		# Regen restores what enemies took, up to the best this run.
		var to_best := maxf(0.0, maxf(max_health(), peak_number) - health)
		health += minf(amount, to_best) + maxf(0.0, amount - to_best) * peak_drift
	else:
		var room := maxf(0.0, max_health() - health)
		health += minf(amount, room) + maxf(0.0, amount - room) * overfill
	_count_gain(source, before)


## Books what the Number just gained from `source`, and the part of it that
## took the Number past its highest yet.
func _count_gain(source: String, before: float) -> void:
	var gained := health - before
	if gained <= 0.0:
		return
	gained_from[source] = float(gained_from.get(source, 0.0)) + gained
	if health > _high:
		raised_by[source] = float(raised_by.get(source, 0.0)) + health - maxf(_high, before)
		_high = health


## The health and attack a `kind` has right now, Enemy Level Skip included.
## The Divider isn't The Tower's, so its numbers are a basic enemy's times ours.
func enemy_health_now(kind: String) -> float:
	var scale := float(TowerData.tier(tier).enemy_health)
	if kind == "divider":
		return TowerData.enemy_health(health_level, "basic") * lerpf(float(divider.health_first), float(divider.health_full), _divider_ramp(wave)) * scale
	return TowerData.enemy_health(health_level, kind) * scale


func enemy_attack_now(kind: String) -> float:
	# A Divider doesn't subtract: it takes a share (_divide).
	if kind == "divider":
		return 0.0
	return TowerData.enemy_attack(attack_level, kind) * float(TowerData.tier(tier).enemy_attack)


## A tier's weight speeds every enemy as it raises the shares (D115).
func _speed_m(kind: String) -> float:
	var weight := float(TowerData.tier(tier).mix_weight)
	if kind == "divider":
		return TowerData.enemy_speed_m(wave, "basic") * float(divider.speed) * weight
	return TowerData.enemy_speed_m(wave, kind) * weight


func _mass_ratio(kind: String) -> float:
	return 1.0 if kind == "divider" else TowerData.mass_ratio(kind)


## How heavy `enemy` is now, over a basic enemy on wave 1: its mass as it
## spawned, 4% more for each wave since (D115). Knockback pushes it that much less.
func knock_mass(enemy: Enemy) -> float:
	return enemy.mass * pow(float(TowerData.enemies().mass_per_wave_alive), wave - enemy.wave)


static func is_elite(kind: String) -> bool:
	return kind in TowerData.ELITES


## Enemies that stop on the edge of the tower's Range and attack from there.
static func stops_at_range(kind: String) -> bool:
	return kind == "ranged" or kind == "vampire" or kind == "ray"


## Whether a Protector shields `enemy`: it is one, or stands within the
## radius of one (D115). A shielded enemy takes less damage and Thorns, and
## orbs can't kill it.
func shielded(enemy: Enemy) -> bool:
	if _protectors.is_empty():
		return false
	if enemy.kind == "protector":
		return true
	var radius := TowerData.protector_radius_m(wave, tier)
	var at := enemy.position()
	for protector in _protectors:
		if at.distance_to(protector.position()) <= radius:
			return true
	return false


## The share of a strike's damage `enemy` takes: The Tower's 0.6 under a
## Protector, else all of it.
func damage_taken(enemy: Enemy) -> float:
	return float(TowerData.enemies().protector.damage_taken) if shielded(enemy) else 1.0


## How many Dividers a wave brings, on average: a fraction of one.
func divider_rate(at_wave: int) -> float:
	if at_wave < int(divider.from_wave):
		return 0.0
	return lerpf(float(divider.rate_first), float(divider.rate_full), _divider_ramp(at_wave))


## The divisor a Divider spawning on `at_wave` carries.
func divider_divisor(at_wave: int) -> float:
	var smooth := lerpf(float(divider.divisor_first), float(divider.divisor_full), _divider_ramp(at_wave))
	# In clean steps, so the ÷ on its body always reads simply.
	return snappedf(smooth, float(divider.get("divisor_step", 0.0))) if float(divider.get("divisor_step", 0.0)) > 0.0 else smooth


## How far along its ramp the Divider is at `at_wave`: 0 at its first wave,
## 1 from FULL_WAVE on.
func _divider_ramp(at_wave: int) -> float:
	var first := int(divider.from_wave)
	return clampf(float(at_wave - first) / float(maxi(1, int(divider.full_wave) - first)), 0.0, 1.0)


func step() -> void:
	if not alive:
		return
	ticks += 1
	time += TICK
	wave_clock += TICK
	for enemy in enemies:
		enemy.last_distance = enemy.distance
	for shot in shots:
		shot.last_position = shot.position
	if wave_clock >= TowerData.wave_seconds():
		wave_clock -= TowerData.wave_seconds()
		_pay_wave_end()
		wave += 1
		_advance_levels()
		_schedule_wave()
	_spawn_due()
	if sure_from > 0 and wave >= sure_from and (wave - sure_from) % sure_every == 0 and _sure_landed != wave and wave_clock >= SURE_LANDS_AT:
		_land_sure_divider()
	_heal(stat("health_regen") * TICK, "regen")
	peak_number = maxf(peak_number, health)
	defences.tick_wall()
	defences.tick_shockwave()
	_move_enemies()
	_enemies_hit()
	if not alive:
		return
	_fire()
	_move_shots()
	defences.sweep_orbs()
	defences.trigger_mines()


## The player stops the run; it ends as if the tower fell, keeping what it earned.
func end_run() -> void:
	if alive:
		alive = false
		killed_by = "ended"
		inputs.append({"tick": ticks, "end": true})


## Runs until the tower falls or `max_seconds` of game time pass.
func run_until_dead(max_seconds: float) -> void:
	while alive and time < max_seconds:
		step()


func _schedule_wave() -> void:
	_schedule.clear()
	_next_spawn = 0
	wave_spawned = 0
	wave_missed = 0
	# The Protector (D115): a share of the draws once its gate, counted down 2
	# a wave, is open; at most one a wave, and one coming shuts the gate again.
	_protector_gate = maxi(0, _protector_gate - int(TowerData.enemies().protector.gate_step))
	var protector := TowerData.protector_chance(wave, tier) if _protector_gate <= 0 else 0.0
	_protector_due = protector > 0.0
	var mix := _tier_mix(protector / 100.0)
	if TowerData.is_boss_wave(wave, tier):
		_schedule.append({"kind": "boss", "at": 0.0})
	# The Tower's spawning (D114): a roll every spawn_roll_seconds of the
	# spawning window, an enemy by the wave's spawn rate, and by the tier's
	# double-spawn chance a second with it. Rolled as the wave starts, from the
	# spawn stream, so a replay sends the same.
	var every := TowerData.spawn_roll_seconds()
	var chance := TowerData.spawn_rate(wave) / 100.0
	var double := float(TowerData.tier(tier).double_spawn)
	for roll in range(roundi(TowerData.spawn_seconds() / every)):
		if _spawn_rng.randf() >= chance:
			continue
		var at := float(roll) * every
		_schedule.append({"kind": _draw_spawn(mix), "at": at})
		if _spawn_rng.randf() < double:
			_schedule.append({"kind": _draw_spawn(mix), "at": at})
	# Elites (D115): each type rolls the chart's chance for one this wave, and
	# once that's certain, for a second, each coming at a random moment of
	# the spawning window. Nothing is drawn while the chart has none.
	var elite := TowerData.elite_chance(wave, tier)
	if elite.single > 0.0:
		for kind in TowerData.ELITES:
			var count := 1 if _spawn_rng.randf() < elite.single / 100.0 else 0
			if elite.single >= 100.0 and elite.double > 0.0 and _spawn_rng.randf() < elite.double / 100.0:
				count += 1
			for copy in range(count):
				_insert_spawn(kind, _spawn_rng.randf() * TowerData.spawn_seconds())
	# A Divider takes the Protector's slot in The Tower's standard pool (D094):
	# it replaces one of the wave's basics, so the wave's size and the rest of
	# its enemies are The Tower's. At most one a wave, so at a rate of one
	# every other wave or less never two waves running; one owed with no basic
	# to replace waits for the next wave without piling up.
	_divider_due += divider_rate(wave)
	if _divider_due < 1.0 - SKIP_SLACK:
		return
	var basics: Array[int] = []
	for index in range(_schedule.size()):
		if _schedule[index].kind == "basic":
			basics.append(index)
	if basics.is_empty():
		_divider_due = 1.0
		return
	_divider_due -= 1.0
	_schedule[basics[_divider_rng.randi_range(0, basics.size() - 1)]].kind = "divider"


## The mix of kinds: a tier raises the fast, tank and ranged shares by its
## weight, the Protector takes its `protector` share, and basics fill the
## rest. Tier 1's is the data's as it stands.
func _tier_mix(protector := 0.0) -> Dictionary:
	var mix: Dictionary = TowerData.enemies().mix
	var weight := float(TowerData.tier(tier).mix_weight)
	if weight == 1.0 and protector <= 0.0:
		return mix
	var weighted := {"basic": 1.0}
	for kind in mix:
		if kind != "basic":
			weighted[kind] = float(mix[kind]) * weight
			weighted.basic -= weighted[kind]
	if protector > 0.0:
		weighted.protector = protector
		weighted.basic -= protector
	return weighted


## What is on the field of `kind`'s sort: bosses, one elite type, or normal enemies.
func count_on_field(kind: String) -> int:
	var count := 0
	for enemy in enemies:
		if enemy.kind == kind or (kind == "normal" and enemy.kind != "boss" and not is_elite(enemy.kind)) \
				or (kind == "elite" and is_elite(enemy.kind)):
			count += 1
	return count


## Whether the caps leave room for one more `kind`: 120 normal enemies, 20
## elites with 8 of a type, and 10 bosses (D113, D115).
func _has_room(kind: String) -> bool:
	if kind == "boss":
		return count_on_field("boss") < TowerData.boss_cap()
	if is_elite(kind):
		return count_on_field("elite") < TowerData.elite_cap() and count_on_field(kind) < TowerData.elite_type_cap()
	return count_on_field("normal") < TowerData.enemy_cap()


## A normal enemy's kind, from the mix; a Protector drawn after this wave's
## one comes as a basic.
func _draw_spawn(mix: Dictionary) -> String:
	var kind := _draw_kind(mix)
	if kind != "protector":
		return kind
	if not _protector_due:
		return "basic"
	_protector_due = false
	_protector_gate = int(TowerData.tier(tier).protector_gate)
	return kind


## Puts a spawn into the wave's schedule, after everything due at or before it.
func _insert_spawn(kind: String, at: float) -> void:
	var index := _schedule.size()
	while index > 0 and float(_schedule[index - 1].at) > at:
		index -= 1
	_schedule.insert(index, {"kind": kind, "at": at})


func _draw_kind(mix: Dictionary) -> String:
	var roll := _spawn_rng.randf()
	for kind in mix:
		roll -= float(mix[kind])
		if roll < 0.0:
			return kind
	return "basic"


func _spawn_due() -> void:
	while _next_spawn < _schedule.size() and float(_schedule[_next_spawn].at) <= wave_clock:
		var kind: String = _schedule[_next_spawn].kind
		_next_spawn += 1
		# The field is full of its sort: this one never comes (The Tower's caps).
		if not _has_room(kind):
			wave_missed += 1
			continue
		wave_spawned += 1
		var enemy := Enemy.new()
		enemy.id = _next_id
		_next_id += 1
		enemy.kind = kind
		enemy.wave = wave
		enemy.max_health = enemy_health_now(kind)
		enemy.health = enemy.max_health
		enemy.attack = enemy_attack_now(kind)
		enemy.speed = _speed_m(kind)
		# A Divider comes from where the basic it replaced would have, so every
		# other enemy's direction is The Tower's too.
		enemy.angle = _spawn_rng.randf() * TAU
		if kind == "divider":
			enemy.divisor = divider_divisor(wave)
			dividers_spawned += 1
		enemy.distance = Guesses.SPAWN_DISTANCE_M
		enemy.last_distance = enemy.distance
		enemy.stop_at = stat("range") if stops_at_range(kind) else Guesses.CONTACT_DISTANCE_M
		enemy.mass = _mass_ratio(kind) * TowerData.mass_growth(wave)
		# A Ray charges before its first shot, and between shots.
		if kind == "ray":
			enemy.hit_in = float(TowerData.enemies().elites.ray_charge_seconds)
		elif kind == "protector":
			_protectors.append(enemy)
		enemies.append(enemy)


func _move_enemies() -> void:
	for enemy in enemies:
		# Ranged enemies stop on the edge of the tower's Range, wherever it is
		# now: more Range and the ones still walking stop further out.
		if stops_at_range(enemy.kind) and not enemy.arrived():
			enemy.stop_at = stat("range")
		# Melee enemies stop at a standing Wall, and walk on when it falls.
		elif not stops_at_range(enemy.kind):
			var at_wall := defences.wall_up() and enemy.distance >= Guesses.WALL_DISTANCE_M
			enemy.stop_at = Guesses.WALL_DISTANCE_M if at_wall else Guesses.CONTACT_DISTANCE_M
		if not enemy.arrived():
			enemy.distance = maxf(enemy.stop_at, enemy.distance - enemy.speed * TICK)


## Every enemy in place hits when its time comes: Defense % comes off first,
## then Defense Absolute, which can take a hit to nothing. Thorns then deals
## the enemy a share of its own maximum health, half on a boss, whatever the
## defences took off, because the contact still happened.
func _enemies_hit() -> void:
	var thorned: Array[Enemy] = []
	var spent: Array[Enemy] = []
	draining = false
	for enemy in enemies:
		if not enemy.arrived():
			continue
		if enemy.kind == "divider":
			spent.append(enemy)
			continue
		# A Vampire in range drains a share of Health a second, past the
		# defences and the Wall, and stops Regen and Lifesteal while it does;
		# no Thorns, since nothing touches the tower (D115).
		if enemy.kind == "vampire":
			draining = true
			enemy.hits = maxi(enemy.hits, 1)
			var drained := minf(health, max_health() * float(TowerData.enemies().elites.vampire_drain) * TICK)
			health -= drained
			lost_to.vampire = float(lost_to.get("vampire", 0.0)) + drained
			if health <= 0.0:
				health = 0.0
				alive = false
				killed_by = enemy.kind
				return
			continue
		enemy.hit_in -= TICK
		if enemy.hit_in > 0.0:
			continue
		enemy.hit_in += float(TowerData.enemies().elites.ray_charge_seconds) if enemy.kind == "ray" else Guesses.ENEMY_HIT_SECONDS
		var damage := landed_damage(enemy.attack * pow(TowerData.heat_up_per_hit(), enemy.hits))
		enemy.hits += 1
		# While the Wall stands it takes every hit, ranged ones too: The Tower's
		# tower takes nothing but a Vampire's drain behind it (D116). When it
		# falls, it rebuilds after Wall Rebuild seconds.
		if defences.wall_up():
			defences.hit_wall(damage)
			if record_events:
				events.append({"type": "wall_hit", "enemy": enemy, "damage": damage})
			continue
		# Death Defy: by its chance a hit that would end the run is ignored.
		if health - damage <= 0.0 and stat("death_defy") > 0.0 and _combat_rng.randf() < stat("death_defy"):
			damage = 0.0
			if record_events:
				events.append({"type": "death_defy"})
		health -= damage
		lost_to[enemy.kind] = float(lost_to.get(enemy.kind, 0.0)) + damage
		if record_events:
			events.append({"type": "tower_hit", "enemy": enemy, "damage": damage})
		if health <= 0.0:
			health = 0.0
			alive = false
			killed_by = enemy.kind
			return
		var thorns := minf(stat("thorns"), 1.0) * (BOSS_THORNS_SHARE if enemy.kind == "boss" else 1.0)
		if shielded(enemy):
			thorns *= float(TowerData.enemies().protector.thorns_taken)
		if thorns > 0.0:
			enemy.health -= enemy.max_health * thorns
			if enemy.health <= 0.0:
				thorned.append(enemy)
	# Removed after the loop, which mustn't lose enemies from under it.
	for enemy in spent:
		_divide(enemy)
	for enemy in thorned:
		_kill(enemy)


## A Divider reaches the Number, or the Wall in front of it, and takes
## 1 - 1/divisor of it through the defences (D081's single pipeline), then is
## used up: gone, unpaid, and no longer a target for shots already flying.
## Half of anything is never all of it, so it can't end a run on its own.
func _divide(enemy: Enemy) -> void:
	var divisor := enemy.divisor if enemy.divisor > 0.0 else divider_divisor(wave)
	var share := 1.0 - 1.0 / maxf(1.0, divisor)
	var at_wall := defences.wall_up() and enemy.distance > Guesses.CONTACT_DISTANCE_M
	var loss := 0.0
	if at_wall:
		loss = minf(defences.wall_health, landed_damage(defences.wall_health * share))
		defences.hit_wall(loss)
	else:
		loss = divide_loss(divisor)
		health -= loss
		lost_to["divider"] = float(lost_to.get("divider", 0.0)) + loss
	dividers_landed += 1
	enemy.health = 0.0
	enemies.erase(enemy)
	if record_events:
		events.append({"type": "divided", "enemy": enemy, "damage": loss, "at_wall": at_wall, "divisor": divisor})


## The most a Recovery Package may heal the Number to: Max Recovery times
## Health, or with `packages_to_best` only back to this run's best.
func package_ceiling() -> float:
	return maxf(max_health(), peak_number) if packages_to_best else max_health() * stat("max_recovery")


## The measuring Divider (`sure_from`): it lands on the Number without
## walking, so no shot, orb, knockback or wall can stop it.
func _land_sure_divider() -> void:
	_sure_landed = wave
	var sure := Enemy.new()
	sure.kind = "divider"
	sure.divisor = sure_divisor
	sure.distance = Guesses.CONTACT_DISTANCE_M
	dividers_spawned += 1
	_divide(sure)


## What a Divider of `divisor` landing now would take off the Number: 1 -
## 1/divisor of it, through the defences, never all of it. The arena's
## preview of a coming ÷ reads this too.
func divide_loss(divisor: float) -> float:
	var share := 1.0 - 1.0 / maxf(1.0, divisor)
	return minf(health, landed_damage(health * share))


## What the Wave Info panel shows (D115), as The Tower's does: the wave's
## spawn rate and double-spawn chance, how many it has sent and turned away,
## what's on the field against the caps, and each kind's health, attack,
## speed and chance.
func wave_info() -> Dictionary:
	var rolls := roundi(TowerData.spawn_seconds() / TowerData.spawn_roll_seconds())
	var rate := TowerData.spawn_rate(wave)
	var double := float(TowerData.tier(tier).double_spawn)
	var protector := TowerData.protector_chance(wave, tier)
	var mix := _tier_mix(protector / 100.0)
	# Each row's chance, and for some, waves until it may come or a second's chance.
	var rows: Array[Dictionary] = []
	for kind in mix:
		var gate := ceili(float(_protector_gate) / float(TowerData.enemies().protector.gate_step)) if kind == "protector" else 0
		rows.append(_info_row(kind, 100.0 * float(mix[kind]), gate))
	var boss_every := int(TowerData.tier(tier).boss_every)
	var boss_in := (boss_every - wave % boss_every) % boss_every
	rows.append(_info_row("boss", 100.0 if boss_in == 0 else 0.0, boss_in))
	if divider_rate(wave) > 0.0:
		rows.append(_info_row("divider", 100.0 * minf(1.0, divider_rate(wave))))
	var elite := TowerData.elite_chance(wave, tier)
	for kind in TowerData.ELITES:
		rows.append(_info_row(kind, elite.single, 0, elite.double))
	return {
		"wave": wave, "tier": tier, "spawn_rate": rate, "double_spawn": 100.0 * double, "rolls": rolls,
		"roll_seconds": TowerData.spawn_roll_seconds(), "expected": rolls * rate / 100.0 * (1.0 + double),
		"due": _schedule.size(), "spawned": wave_spawned, "missed": wave_missed,
		"normal": count_on_field("normal"), "normal_cap": TowerData.enemy_cap(),
		"elites": count_on_field("elite"), "elite_cap": TowerData.elite_cap(),
		"bosses": count_on_field("boss"), "boss_cap": TowerData.boss_cap(),
		"protector_radius": TowerData.protector_radius_m(wave, tier), "rows": rows,
	}


func _info_row(kind: String, chance: float, waits := 0, second := 0.0) -> Dictionary:
	return {"kind": kind, "health": enemy_health_now(kind), "attack": enemy_attack_now(kind), "speed": _speed_m(kind), "chance": chance,
		"waits": waits, "second": second}


## What a hit of `raw` leaves after the tower's defences.
func landed_damage(raw: float) -> float:
	var share := clampf(stat("defense_percent"), 0.0, DEFENSE_PERCENT_CAP)
	return maxf(0.0, raw * (1.0 - share) - stat("defense_absolute"))


func _fire() -> void:
	var speed := stat("attack_speed") * (RAPID_FIRE_SPEED if rapid_fire_left > 0.0 else 1.0)
	rapid_fire_left = maxf(0.0, rapid_fire_left - TICK)
	_shot_charge += speed * TICK
	while _shot_charge >= 1.0:
		var target := _nearest_in_range()
		if target == null:
			# Ready to fire the moment something steps in, but no banking.
			_shot_charge = 1.0
			return
		_shot_charge -= 1.0
		var critical := _combat_rng.randf() < stat("critical_chance")
		var damage := stat("damage") * (stat("critical_factor") if critical else 1.0)
		# Super Crit: a critical shot may be super critical, multiplied again.
		if critical and stat("super_crit_chance") > 0.0 and _combat_rng.randf() < stat("super_crit_chance"):
			damage *= stat("super_crit_mult")
		var targets: Array[Enemy] = [target]
		# Multishot: by its chance the same shot also flies at the next
		# nearest enemies in range, up to its targets in all.
		if stat("multishot_chance") > 0.0 and _combat_rng.randf() < stat("multishot_chance"):
			var others := _in_range_nearest_first()
			others.erase(target)
			targets.append_array(others.slice(0, int(stat("multishot_targets")) - 1))
		for each in targets:
			_launch(each, Vector2.ZERO, damage, critical)
		# Rapid Fire: each volley may start it, while it isn't running.
		if rapid_fire_left <= 0.0 and stat("rapid_fire_chance") > 0.0 and _combat_rng.randf() < stat("rapid_fire_chance"):
			rapid_fire_left = stat("rapid_fire_duration")
			if record_events:
				events.append({"type": "rapid_fire"})
		# Land Mines: each volley may lay one somewhere in range.
		defences.maybe_lay_mine()


func _launch(target: Enemy, from: Vector2, damage: float, critical: bool) -> Shot:
	var shot := Shot.new()
	shot.target = target
	shot.position = from
	shot.last_position = from
	shot.critical = critical
	shot.damage = damage
	shots.append(shot)
	return shot


func _nearest_in_range() -> Enemy:
	var reach := stat("range")
	var nearest: Enemy = null
	for enemy in enemies:
		if enemy.distance <= reach and (nearest == null or enemy.distance < nearest.distance):
			nearest = enemy
	return nearest


func _in_range_nearest_first() -> Array[Enemy]:
	var reach := stat("range")
	var found: Array[Enemy] = []
	for enemy in enemies:
		if enemy.distance <= reach:
			found.append(enemy)
	found.sort_custom(func(a, b): return a.distance < b.distance)
	return found


func _move_shots() -> void:
	var flying: Array[Shot] = []
	for shot in shots:
		# A shot whose target already fell is lost, as an overkill is.
		if shot.target.health <= 0.0:
			continue
		var target_at := shot.target.position()
		var step_m := Guesses.SHOT_SPEED_M * TICK
		if shot.position.distance_to(target_at) > step_m:
			shot.position = shot.position.move_toward(target_at, step_m)
			flying.append(shot)
			continue
		_strike(shot.target, shot.damage, shot.critical)
		var bounce := _bounce(shot)
		if bounce != null:
			flying.append(bounce)
	shots = flying


## Bounce Shot: a shot's first strike rolls its chance; on a bounce it goes on
## from the enemy it struck to the nearest other enemy within Bounce Shot
## Range, up to its targets, never striking one twice.
func _bounce(shot: Shot) -> Shot:
	shot.struck.append(shot.target.id)
	if shot.bounces < 0:
		var chance := stat("bounce_shot_chance")
		shot.bounces = int(stat("bounce_shot_targets")) if chance > 0.0 and _combat_rng.randf() < chance else 0
	if shot.bounces <= 0:
		return null
	var from := shot.target.position()
	var reach := stat("bounce_shot_range")
	var next: Enemy = null
	for enemy in enemies:
		if enemy.id in shot.struck or enemy.health <= 0.0:
			continue
		var gap := from.distance_to(enemy.position())
		if gap <= reach and (next == null or gap < from.distance_to(next.position())):
			next = enemy
	if next == null:
		return null
	# Launched through _launch for its setup, but carried by the caller's list.
	var bounce := _launch(next, from, shot.damage, shot.critical)
	shots.erase(bounce)
	bounce.bounces = shot.bounces - 1
	bounce.struck = shot.struck.duplicate()
	return bounce


## A shot lands, lifted by Damage / Meter for how far out its enemy is.
## Lifesteal heals a share of what it took off, and Knockback may push the
## enemy back by its force over the enemy's mass, never past where enemies
## set off; it walks back and hits again when it arrives.
func _strike(enemy: Enemy, shot_damage: float, critical: bool) -> void:
	var damage := shot_damage * (1.0 + stat("damage_per_meter") * enemy.distance) * (1.0 + enemy.rend) * damage_taken(enemy)
	# Rend Armor: by its chance a strike makes every later one on this enemy
	# hit harder, stacking to REND_CAP.
	if is_open("rend_armor_chance") and _combat_rng.randf() < stat("rend_armor_chance"):
		enemy.rend = minf(REND_CAP, enemy.rend + stat("rend_armor_mult"))
	_heal(stat("lifesteal") * minf(damage, maxf(enemy.health, 0.0)), "lifesteal")
	if enemy.health > damage and stat("knockback_chance") > 0.0 and _combat_rng.randf() < stat("knockback_chance"):
		var push := stat("knockback_force") * Guesses.KNOCKBACK_METRES_PER_FORCE / knock_mass(enemy)
		enemy.distance = minf(Guesses.SPAWN_DISTANCE_M, enemy.distance + push)
	enemy.health -= damage
	if record_events:
		events.append({"type": "enemy_hit", "enemy": enemy, "damage": damage, "critical": critical})
	if enemy.health <= 0.0:
		_kill(enemy)


## `by` names what killed it when the screen draws that differently: "orb" for
## an orb, which sets it to 0 (D106).
func _kill(enemy: Enemy, by := "") -> void:
	enemies.erase(enemy)
	_protectors.erase(enemy)
	kills += 1
	if enemy.hits == 0 and enemy.attack > 0.0:
		# Killed before it could land a hit: a share of the hit it never
		# landed grows the Number, past Health too (D098).
		var before := health
		health += enemy.attack * kill_share
		_count_gain("kills", before)
		if record_events:
			events.append({"type": "grown", "enemy": enemy, "gain": health - before})
	# A Scatter's split-off pieces pay as basics.
	var pays_as := "basic" if enemy.generation > 0 else enemy.kind
	var paid_cash := TowerData.kill_cash(enemy.wave) * float(Guesses.CASH_BY_TYPE[pays_as]) * stat("cash_bonus")
	var paid_coins := float(Guesses.COINS_BY_TYPE[pays_as]) * stat("coins_per_kill") * float(TowerData.tier(tier).coins)
	# Coin decay (D115): an enemy alive three waves pays half its Coins.
	var decay: Dictionary = TowerData.enemies().coin_decay
	if wave - enemy.wave >= int(decay.after_waves):
		paid_coins *= float(decay.share)
	cash += paid_cash
	cash_earned += paid_cash
	coins += paid_coins
	if record_events:
		events.append({"type": "kill", "enemy": enemy, "cash": paid_cash, "coins": paid_coins, "by": by})
	if enemy.kind == "scatter" and enemy.generation < int(TowerData.enemies().elites.scatter_splits):
		_split(enemy)


## A Scatter falls into two, each with half its health, either side of where
## it fell (D115). The pieces come whatever the caps.
func _split(scatter: Enemy) -> void:
	for side in [-1.0, 1.0]:
		var piece := Enemy.new()
		piece.id = _next_id
		_next_id += 1
		piece.kind = "scatter"
		piece.wave = scatter.wave
		piece.max_health = scatter.max_health * 0.5
		piece.health = piece.max_health
		piece.attack = scatter.attack
		piece.speed = scatter.speed
		piece.angle = scatter.angle + side * Guesses.SCATTER_SPREAD
		piece.distance = scatter.distance
		piece.last_distance = scatter.distance
		piece.stop_at = Guesses.CONTACT_DISTANCE_M
		piece.mass = scatter.mass
		piece.generation = scatter.generation + 1
		enemies.append(piece)
		if record_events:
			events.append({"type": "split", "enemy": piece})


## As each wave ends: Cash / Wave times Cash Bonus, and Coins / Wave once the
## Workshop has opened it (its first level is worth 1, so a closed row must pay
## nothing).
func _pay_wave_end() -> void:
	var paid_cash := stat("cash_per_wave") * stat("cash_bonus")
	# Interest on the Cash held, after the wave's Cash, up to its cap.
	paid_cash += minf(INTEREST_CAP, (cash + paid_cash) * stat("interest"))
	cash += paid_cash
	cash_earned += paid_cash
	if is_open("coins_per_wave"):
		coins += stat("coins_per_wave") * float(TowerData.tier(tier).coins)
	# Recovery Packages: by its chance a wave's end heals a share of Health,
	# which may go past Health up to Max Recovery times it.
	if is_open("package_chance") and _combat_rng.randf() < stat("package_chance"):
		var before := health
		health = maxf(health, minf(package_ceiling(), health + max_health() * stat("recovery_amount")))
		_count_gain("package", before)
		if record_events:
			events.append({"type": "package"})
	# Free Upgrades: by each category's chance, a random open row of it that
	# isn't at its last level goes up one, free.
	for category in FREE_UPGRADE_ROWS:
		var chance := stat(FREE_UPGRADE_ROWS[category])
		if chance <= 0.0 or _combat_rng.randf() >= chance:
			continue
		var rows: Array[String] = []
		for id in TowerData.rows():
			if TowerData.category(id) == category and is_open(id) and not at_max(id):
				rows.append(id)
		if rows.is_empty():
			continue
		var chosen := rows[_combat_rng.randi_range(0, rows.size() - 1)]
		_raise(chosen)
		if record_events:
			events.append({"type": "free_upgrade", "id": chosen})
	wave_log.append({"wave": wave, "time": time, "health": health, "max_health": max_health(), "cash": cash,
		"cash_earned": cash_earned, "coins": coins, "kills": kills, "enemy_attack": enemy_attack_now("basic"),
		"enemy_health": enemy_health_now("basic"), "bought": run_levels.duplicate()})


## Enemy Level Skip: each new wave's enemies are a level tougher and a level
## harder-hitting, except that each skip row's share of waves stays put. The
## Tower made it steady rather than random, so it adds its share every wave
## and skips when that reaches a whole wave (50% skips every other wave).
func _advance_levels() -> void:
	if not is_open("enemy_health_level_skip"):
		health_level += 1
		attack_level += 1
		return
	_health_skip += stat("enemy_health_level_skip")
	_attack_skip += stat("enemy_attack_level_skip")
	# The slack keeps float drift from losing a skip: 100 waves at 35% add
	# up to 34.9999… and must still skip 35.
	if _health_skip >= 1.0 - SKIP_SLACK:
		_health_skip -= 1.0
	else:
		health_level += 1
	if _attack_skip >= 1.0 - SKIP_SLACK:
		_attack_skip -= 1.0
	else:
		attack_level += 1
