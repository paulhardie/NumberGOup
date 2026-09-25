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

	func position() -> Vector2:
		return Vector2.from_angle(angle) * distance

	func arrived() -> bool:
		return distance <= stop_at


class Shot:
	var target: Enemy
	var position: Vector2
	var damage: float
	var critical: bool


var run_seed: int
## Row id → level. Every row not listed is at level 0.
var levels: Dictionary

var time := 0.0
var wave := 1
var wave_clock := 0.0
var alive := true
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


func _init(seed_value: int, row_levels: Dictionary = {}) -> void:
	run_seed = seed_value
	levels = row_levels.duplicate()
	# Two streams, so a change in how often the tower fires or crits never
	# changes which enemies a wave sends.
	_spawn_rng.seed = hash([seed_value, "spawn"])
	_combat_rng.seed = hash([seed_value, "combat"])
	health = max_health()
	_schedule_wave()


func stat(id: String) -> float:
	return TowerData.value(id, int(levels.get(id, 0)))


func max_health() -> float:
	return stat("health")


func step() -> void:
	if not alive:
		return
	time += TICK
	wave_clock += TICK
	if wave_clock >= TowerData.wave_seconds():
		wave_clock -= TowerData.wave_seconds()
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
		enemy.stop_at = Guesses.RANGED_DISTANCE_M if kind == "ranged" else Guesses.CONTACT_DISTANCE_M
		enemies.append(enemy)


func _move_enemies() -> void:
	for enemy in enemies:
		if not enemy.arrived():
			enemy.distance = maxf(enemy.stop_at, enemy.distance - enemy.speed * TICK)


func _enemies_hit() -> void:
	for enemy in enemies:
		if not enemy.arrived():
			continue
		enemy.hit_in -= TICK
		if enemy.hit_in > 0.0:
			continue
		enemy.hit_in += Guesses.ENEMY_HIT_SECONDS
		var damage := enemy.attack * pow(Guesses.HEAT_UP_PER_HIT, enemy.hits)
		enemy.hits += 1
		health -= damage
		if record_events:
			events.append({"type": "tower_hit", "enemy": enemy, "damage": damage})
		if health <= 0.0:
			health = 0.0
			alive = false
			killed_by = enemy.kind
			return


func _fire() -> void:
	_shot_charge += stat("attack_speed") * TICK
	while _shot_charge >= 1.0:
		var target := _nearest_in_range()
		if target == null:
			# Ready to fire the moment something steps in, but no banking.
			_shot_charge = 1.0
			return
		_shot_charge -= 1.0
		var shot := Shot.new()
		shot.target = target
		shot.position = Vector2.ZERO
		shot.critical = _combat_rng.randf() < stat("critical_chance")
		shot.damage = stat("damage") * (stat("critical_factor") if shot.critical else 1.0)
		shots.append(shot)


func _nearest_in_range() -> Enemy:
	var reach := stat("range")
	var nearest: Enemy = null
	for enemy in enemies:
		if enemy.distance <= reach and (nearest == null or enemy.distance < nearest.distance):
			nearest = enemy
	return nearest


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


func _strike(enemy: Enemy, damage: float, critical: bool) -> void:
	enemy.health -= damage
	if record_events:
		events.append({"type": "enemy_hit", "enemy": enemy, "damage": damage, "critical": critical})
	if enemy.health <= 0.0:
		_kill(enemy)


func _kill(enemy: Enemy) -> void:
	enemies.erase(enemy)
	kills += 1
	var paid_cash := (1.0 + floorf(enemy.wave / 10.0)) * float(Guesses.CASH_BY_TYPE[enemy.kind])
	var paid_coins := float(Guesses.COINS_BY_TYPE[enemy.kind]) * float(enemy.wave)
	cash += paid_cash
	cash_earned += paid_cash
	coins += paid_coins
	if record_events:
		events.append({"type": "kill", "enemy": enemy, "cash": paid_cash, "coins": paid_coins})
