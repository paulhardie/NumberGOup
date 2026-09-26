extends RefCounted
## One run of the battle: the tower in the centre, Tier 1's waves walking in.
## It is the only owner of combat rules. The battle screen draws it and the
## headless tools run it, so what is measured is exactly what is played.
## It steps in fixed ticks from a seed, so the same seed and the same inputs
## always give the same run.

const Guesses = preload("res://src/tower/guesses.gd")
const TowerData = preload("res://src/tower/tower_data.gd")

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


## The groups of rows a run may buy from, before the Workshop opens more.
const START_GROUPS := ["attack_start", "defense_start"]
## The most Defense % can take off a hit (community research, unverified).
const DEFENSE_PERCENT_CAP := 0.98
## A boss takes this share of Thorns (TheTowerSDK's breakpoints agree).
const BOSS_THORNS_SHARE := 0.5

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
var cash := 0.0
var cash_earned := 0.0
var coins := 0.0
var kills := 0

var enemies: Array[Enemy] = []
var shots: Array[Shot] = []

## What happened this tick, for the screen: {type, ...}. Only filled while
## record_events is on, so headless runs don't build it up.
var record_events := false
var events: Array[Dictionary] = []

var _spawn_rng := RandomNumberGenerator.new()
var _combat_rng := RandomNumberGenerator.new()
var _schedule: Array[Dictionary] = []
var _next_spawn := 0
var _next_id := 1
var _shot_charge := 0.0


## `row_levels` and `groups` are the Workshop's: the levels a run starts from
## and the groups it may buy from.
func _init(seed_value: int, row_levels: Dictionary = {}, groups: Array = START_GROUPS) -> void:
	run_seed = seed_value
	levels = row_levels.duplicate()
	open_groups = groups.duplicate()
	# Two streams, so a change in how often the tower fires or crits never
	# changes which enemies a wave sends.
	_spawn_rng.seed = hash([seed_value, "spawn"])
	_combat_rng.seed = hash([seed_value, "combat"])
	health = max_health()
	_schedule_wave()


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


func can_buy(id: String) -> bool:
	return alive and is_open(id) and not at_max(id) and cash >= price(id)


## Buys one level of `id` with Cash; false, and nothing changes, if it can't.
func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	var health_before := max_health()
	cash -= price(id)
	run_levels[id] = int(run_levels.get(id, 0)) + 1
	# More Health raises the health you have now by the same amount.
	health += max_health() - health_before
	return true


func max_health() -> float:
	return stat("health")


func step() -> void:
	if not alive:
		return
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
		_schedule_wave()
	_spawn_due()
	health = minf(max_health(), health + stat("health_regen") * TICK)
	_move_enemies()
	_enemies_hit()
	if not alive:
		return
	_fire()
	_move_shots()


## The player stops the run; it ends as if the tower fell, keeping what it earned.
func end_run() -> void:
	if alive:
		alive = false
		killed_by = "ended"


## Runs until the tower falls or `max_seconds` of game time pass.
func run_until_dead(max_seconds: float) -> void:
	while alive and time < max_seconds:
		step()


func _schedule_wave() -> void:
	_schedule.clear()
	_next_spawn = 0
	var count := Guesses.enemies_in_wave(wave)
	var mix: Dictionary = TowerData.enemies().mix
	if TowerData.is_boss_wave(wave):
		_schedule.append({"kind": "boss", "at": 0.0})
	for index in range(count):
		_schedule.append({"kind": _draw_kind(mix), "at": TowerData.spawn_seconds() * float(index) / float(count)})


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
		var enemy := Enemy.new()
		enemy.id = _next_id
		_next_id += 1
		enemy.kind = kind
		enemy.wave = wave
		enemy.max_health = TowerData.enemy_health(wave, kind)
		enemy.health = enemy.max_health
		enemy.attack = TowerData.enemy_attack(wave, kind)
		enemy.speed = TowerData.enemy_speed_m(wave, kind)
		enemy.angle = _spawn_rng.randf() * TAU
		enemy.distance = Guesses.SPAWN_DISTANCE_M
		enemy.last_distance = enemy.distance
		enemy.stop_at = Guesses.RANGED_DISTANCE_M if kind == "ranged" else Guesses.CONTACT_DISTANCE_M
		enemies.append(enemy)


func _move_enemies() -> void:
	for enemy in enemies:
		if not enemy.arrived():
			enemy.distance = maxf(enemy.stop_at, enemy.distance - enemy.speed * TICK)


## Every enemy in place hits when its time comes: Defense % comes off first,
## then Defense Absolute, which can take a hit to nothing. Thorns then deals
## the enemy a share of its own maximum health, half on a boss, whatever the
## defences took off, because the contact still happened.
func _enemies_hit() -> void:
	var thorned: Array[Enemy] = []
	for enemy in enemies:
		if not enemy.arrived():
			continue
		enemy.hit_in -= TICK
		if enemy.hit_in > 0.0:
			continue
		enemy.hit_in += Guesses.ENEMY_HIT_SECONDS
		var damage := landed_damage(enemy.attack * pow(Guesses.HEAT_UP_PER_HIT, enemy.hits))
		enemy.hits += 1
		health -= damage
		if record_events:
			events.append({"type": "tower_hit", "enemy": enemy, "damage": damage})
		if health <= 0.0:
			health = 0.0
			alive = false
			killed_by = enemy.kind
			return
		var thorns := minf(stat("thorns"), 1.0) * (BOSS_THORNS_SHARE if enemy.kind == "boss" else 1.0)
		if thorns > 0.0:
			enemy.health -= enemy.max_health * thorns
			if enemy.health <= 0.0:
				thorned.append(enemy)
	# Killed after the loop, which mustn't lose enemies from under it.
	for enemy in thorned:
		_kill(enemy)


## What a hit of `raw` leaves after the tower's defences.
func landed_damage(raw: float) -> float:
	var share := clampf(stat("defense_percent"), 0.0, DEFENSE_PERCENT_CAP)
	return maxf(0.0, raw * (1.0 - share) - stat("defense_absolute"))


func _fire() -> void:
	_shot_charge += stat("attack_speed") * TICK
	while _shot_charge >= 1.0:
		var target := _nearest_in_range()
		if target == null:
			# Ready to fire the moment something steps in, but no banking.
			_shot_charge = 1.0
			return
		_shot_charge -= 1.0
		var critical := _combat_rng.randf() < stat("critical_chance")
		var damage := stat("damage") * (stat("critical_factor") if critical else 1.0)
		var targets: Array[Enemy] = [target]
		# Multishot: by its chance the same shot also flies at the next
		# nearest enemies in range, up to its targets in all.
		if stat("multishot_chance") > 0.0 and _combat_rng.randf() < stat("multishot_chance"):
			var others := _in_range_nearest_first()
			others.erase(target)
			targets.append_array(others.slice(0, int(stat("multishot_targets")) - 1))
		for each in targets:
			var shot := Shot.new()
			shot.target = each
			shot.position = Vector2.ZERO
			shot.last_position = Vector2.ZERO
			shot.critical = critical
			shot.damage = damage
			shots.append(shot)


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
	shots = flying


## A shot lands, lifted by Damage / Meter for how far out its enemy is.
func _strike(enemy: Enemy, shot_damage: float, critical: bool) -> void:
	var damage := shot_damage * (1.0 + stat("damage_per_meter") * enemy.distance)
	enemy.health -= damage
	if record_events:
		events.append({"type": "enemy_hit", "enemy": enemy, "damage": damage, "critical": critical})
	if enemy.health <= 0.0:
		_kill(enemy)


func _kill(enemy: Enemy) -> void:
	enemies.erase(enemy)
	kills += 1
	var paid_cash := (1.0 + floorf(enemy.wave / 10.0)) * float(Guesses.CASH_BY_TYPE[enemy.kind]) * stat("cash_bonus")
	var paid_coins := float(Guesses.COINS_BY_TYPE[enemy.kind]) * float(enemy.wave) * stat("coins_per_kill")
	cash += paid_cash
	cash_earned += paid_cash
	coins += paid_coins
	if record_events:
		events.append({"type": "kill", "enemy": enemy, "cash": paid_cash, "coins": paid_coins})


## As each wave ends: Cash / Wave times Cash Bonus, and Coins / Wave once the
## Workshop has opened it (its first level is worth 1, so a closed row must pay
## nothing).
func _pay_wave_end() -> void:
	var paid_cash := stat("cash_per_wave") * stat("cash_bonus")
	cash += paid_cash
	cash_earned += paid_cash
	if is_open("coins_per_wave"):
		coins += stat("coins_per_wave")
