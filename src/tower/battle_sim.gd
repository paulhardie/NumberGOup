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
const BattleSpawns = preload("res://src/tower/battle_spawns.gd")
const EnemyKinds = preload("res://src/tower/enemy_kinds.gd")
const StatStack = preload("res://src/tower/stat_stack.gd")

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
	## for each wave it stays alive (EnemyKinds.mass_now).
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
## Effects on this run's stats (D118): Cards, Labs and Perks will add theirs
## before the first step. Every stat is read through it, with its hard cap.
var stats := StatStack.new()
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

var _combat_rng := RandomNumberGenerator.new()
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
## The Protectors on the field (D115), whose shields BattleSim.shielded reads.
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
## Which enemies each wave sends and when (D117).
var spawns := BattleSpawns.new(self)
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
	# Separate streams, so a change in how often the tower fires or crits
	# never changes which enemies a wave sends.
	spawns.start(seed_value)
	_combat_rng.seed = hash([seed_value, "combat"])
	health = max_health()
	peak_number = health
	_high = health
	defences.start()
	spawns.schedule_wave()


## Where the two random streams stand, as text: their 64-bit states are more
## than JSON's numbers hold exactly. A replay that drew exactly the same
## numbers ends with the same states.
func rng_state() -> Array[String]:
	return [spawns.spawn_state(), str(_combat_rng.state), spawns.divider_state()]


func level(id: String) -> int:
	return int(levels.get(id, 0)) + int(run_levels.get(id, 0))


## A stat's value now: its Workshop row at the run's level, built up by any
## effects on it and held to its hard cap (StatStack).
func stat(id: String) -> float:
	return stats.value(id, TowerData.value(id, level(id)))


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


## The health and attack a `kind` has right now, Enemy Level Skip included
## (EnemyKinds holds the maths).
func enemy_health_now(kind: String) -> float:
	return EnemyKinds.health(kind, health_level, wave, tier, divider)


func enemy_attack_now(kind: String) -> float:
	return EnemyKinds.attack(kind, attack_level, tier)


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
		spawns.schedule_wave()
	spawns.spawn_due()
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


## Puts a new `kind` on the field at `angle`, where enemies set off
## (BattleSpawns decides which and when).
func _place(kind: String, angle: float) -> void:
	var enemy := Enemy.new()
	enemy.id = _next_id
	_next_id += 1
	enemy.kind = kind
	enemy.wave = wave
	enemy.max_health = enemy_health_now(kind)
	enemy.health = enemy.max_health
	enemy.attack = enemy_attack_now(kind)
	enemy.speed = EnemyKinds.speed_m(kind, wave, tier, divider)
	enemy.angle = angle
	if kind == "divider":
		enemy.divisor = EnemyKinds.divider_divisor(divider, wave)
		dividers_spawned += 1
	enemy.distance = Guesses.SPAWN_DISTANCE_M
	enemy.last_distance = enemy.distance
	enemy.stop_at = stat("range") if EnemyKinds.stops_at_range(kind) else Guesses.CONTACT_DISTANCE_M
	enemy.mass = EnemyKinds.spawn_mass(kind, wave)
	# A Ray charges before its first shot, and between shots.
	if EnemyKinds.attack_style(kind) == "charge":
		enemy.hit_in = EnemyKinds.hit_seconds(kind)
	elif kind == "protector":
		_protectors.append(enemy)
	enemies.append(enemy)


func _move_enemies() -> void:
	for enemy in enemies:
		# Ranged enemies stop on the edge of the tower's Range, wherever it is
		# now: more Range and the ones still walking stop further out.
		if EnemyKinds.stops_at_range(enemy.kind) and not enemy.arrived():
			enemy.stop_at = stat("range")
		# Melee enemies stop at a standing Wall, and walk on when it falls.
		elif not EnemyKinds.stops_at_range(enemy.kind):
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
		var style := EnemyKinds.attack_style(enemy.kind)
		if style == "divide":
			spent.append(enemy)
			continue
		# A Vampire in range drains a share of Health a second, past the
		# defences and the Wall, and stops Regen and Lifesteal while it does;
		# no Thorns, since nothing touches the tower (D115).
		if style == "drain":
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
		enemy.hit_in += EnemyKinds.hit_seconds(enemy.kind)
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
		var thorns := stat("thorns") * EnemyKinds.thorns_share(enemy.kind)
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
	var divisor := enemy.divisor if enemy.divisor > 0.0 else EnemyKinds.divider_divisor(divider, wave)
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


## What a hit of `raw` leaves after the tower's defences.
func landed_damage(raw: float) -> float:
	return maxf(0.0, raw * (1.0 - stat("defense_percent")) - stat("defense_absolute"))


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
	# The roll is made for every kind, so an immune one never shifts the
	# stream the rest of the run draws from.
	var knocked := enemy.health > damage and stat("knockback_chance") > 0.0 and _combat_rng.randf() < stat("knockback_chance")
	if knocked and EnemyKinds.knockback_moves(enemy.kind):
		var push := stat("knockback_force") * Guesses.KNOCKBACK_METRES_PER_FORCE / EnemyKinds.mass_now(enemy, wave)
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
	var paid_cash := EnemyKinds.cash(enemy, stat("cash_bonus"))
	var paid_coins := EnemyKinds.coins(enemy, wave, stat("coins_per_kill"), tier)
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
