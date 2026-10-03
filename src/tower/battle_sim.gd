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
const RunRules = preload("res://src/tower/run_rules.gd")
const RunConfig = preload("res://src/tower/run_config.gd")
const BattleCooldowns = preload("res://src/tower/battle_cooldowns.gd")

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
	## A thief's flight (the trial's `thieves`, D151): set once a Divider has
	## carried a bite of the Number off, which stays out until it is killed.
	var fleeing := false
	var carried := 0.0
	## Its health when it grabbed the bite: the damage dealt to it pays the bite
	## back against this.
	var carry_health := 0.0
	## The share of the bite already paid back, 0 to 1.
	var carry_paid := 0.0

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
const INTEREST_CAP := RunRules.DEFAULTS.interest_cap
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
## Effects on this run's stats (D119). Every stat is read through it, with its
## hard cap. Effects a run starts with (Cards, Labs) come through `_init`, so
## the starting Number, the Wall and the first Shockwave are built with them.
var stats := StatStack.new()
var rules := RunRules.new()
var cooldowns := BattleCooldowns.new()
var starting_effects: Array = []
var starting_rules: Array = []
## Damage and kills by source, shared by stats and later missions/Weapons.
var damage_by: Dictionary = {}
var kills_by: Dictionary = {}
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
## The Lock's numbers for this run (Guesses.LOCK), the same way.
var lock: Dictionary = Guesses.LOCK.duplicate()
## The wave the first tank comes on (Guesses.TANK_INTRO_WAVE, D144); the
## measuring tools may set 0 for none. The game never changes it, so a
## battle snapshot needn't carry it.
var tank_intro := Guesses.TANK_INTRO_WAVE
var _starting_tuning: Dictionary
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
## The Number-as-capital trial's measuring options (D151, THE_NUMBER.md
## section 10): off in the game, so every run and replay is as before, and kept
## out of a run's recorded tuning while they are off. `thieves`: a Divider that
## reaches the Number carries its bite away instead of being used up, the
## damage dealt to it pays `thief_recovery` times that bite back, and one that
## walks out to where enemies set off keeps it. `thief_speed` is its flight
## against its walking speed, `thief_fade` the seconds an unreturned bite stays
## out of Regen's reach (0: for ever), and `thief_priority` has the tower shoot
## carriers first. `number_power` multiplies the tower's shots by the Number
## over The Tower's starting Health, to that power.
var thieves := false
var thief_recovery := 0.0
var thief_speed := 1.0
var thief_fade := 0.0
var thief_priority := false
var number_power := 0.0
## What thieves are holding out of Regen's reach now, and since the start the
## thefts, the bite they took, what came back (more than was taken once the
## recovery passes 1) and what walked away unreturned.
var thief_held := 0.0
var _thief_release := 0.0
var thefts := 0
var thief_taken := 0.0
var thief_recovered := 0.0
var thief_escaped := 0.0
var thieves_escaped := 0

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
## Whether a Lock stood in range last tick (D133): the Number can't go up,
## by Regen, Lifesteal, a Recovery Package or a kill. Bought Health still lands.
var locked := false
## Seconds the Number has stood held by a Lock this run; counted only.
var locked_seconds := 0.0
## What Dividers have taken that Regen may not yet put back (D134), and how
## fast it comes back: the lot evenly over `divider.refill_seconds` from the
## last bite.
var divider_held := 0.0
var _held_release := 0.0
var _next_id := 1
var _shot_charge := 0.0
## Seconds of Rapid Fire left.
var rapid_fire_left: float:
	get: return cooldowns.time_left("rapid_fire")
	set(value): cooldowns.set_time("rapid_fire", value)

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
## and the groups it may buy from. `effects` are the ones the run starts with,
## each {stat, op, value, source} (StatStack.add); a refused one is an error.
func _init(seed_value: int, row_levels: Dictionary = {}, groups: Array = START_GROUPS, run_tier: int = 1, effects: Array = [], rule_effects: Array = [], tuning: Dictionary = {}) -> void:
	run_seed = seed_value
	tier = clampi(run_tier, 1, TowerData.tier_count())
	levels = row_levels.duplicate()
	open_groups = groups.duplicate()
	starting_effects = effects.duplicate(true)
	starting_rules = rule_effects.duplicate(true)
	if not RunConfig.valid_tuning(tuning):
		push_error("BattleSim: refused starting tuning")
		return
	for key in tuning:
		set(key, tuning[key].duplicate(true) if tuning[key] is Dictionary else tuning[key])
	_starting_tuning = tuning_config()
	# Before anything below reads a stat: the starting Number, its best, the
	# Wall and the first Shockwave all come from the built values.
	for effect in effects:
		if not stats.add(str(effect.get("stat", "")), str(effect.get("op", "")), float(effect.get("value", NAN)), str(effect.get("source", ""))):
			push_error("BattleSim: refused a starting stat effect %s" % [effect])
	for effect in rule_effects:
		if not rules.add(effect):
			push_error("BattleSim: refused a starting rule effect %s" % [effect])
	cash = rules.value("starting_cash")
	# Separate streams, so a change in how often the tower fires or crits
	# never changes which enemies a wave sends.
	spawns.start(seed_value)
	_combat_rng.seed = hash([seed_value, "combat"])
	health = max_health()
	peak_number = health
	_high = health
	defences.start()
	spawns.schedule_wave()


func start_config() -> Dictionary:
	return {"version": RunConfig.VERSION, "rules_version": RunConfig.RULES_VERSION,
		"tier": tier, "levels": levels.duplicate(), "groups": open_groups.duplicate(),
		"effects": starting_effects.duplicate(true), "rules": starting_rules.duplicate(true),
		"tuning": _starting_tuning.duplicate(true)}


func tuning_config() -> Dictionary:
	var result := {}
	for key in RunConfig.default_tuning():
		var value = get(key)
		result[key] = value.duplicate(true) if value is Dictionary else value
	# The trial's options are recorded only while they are on, so a run made
	# without them is byte for byte what it was.
	var trial := RunConfig.trial_tuning()
	for key in trial:
		if get(key) != trial[key]:
			result[key] = get(key)
	return result


## Whether any of the Number-as-capital trial's options is in play.
func trial_active() -> bool:
	return thieves or number_power > 0.0


## Measuring switches are fixed before the first step. Re-roll wave 1 from
## its original streams so even a Lock introduced at wave 1 replays exactly.
func configure_tuning(tuning: Dictionary) -> bool:
	if ticks != 0 or wave != 1 or not inputs.is_empty() or not RunConfig.valid_tuning(tuning): return false
	for key in tuning:
		set(key, tuning[key].duplicate(true) if tuning[key] is Dictionary else tuning[key])
	_starting_tuning = tuning_config()
	spawns.start(run_seed)
	spawns.divider_due = 0.0
	spawns.schedule_wave()
	return true


## Perks and later loadout changes use a recorded domain input, so a replay
## applies the same effect at the same tick.
func apply_effect(effect: Dictionary, domain := "stat", record := true) -> bool:
	if not alive or domain not in ["stat", "rule"] or not RunConfig.valid_effect(effect, domain == "rule"):
		return false
	var before := max_health()
	if domain == "rule":
		if not rules.add(effect):
			return false
	else:
		if not stats.add(String(effect.stat), String(effect.op), float(effect.value), String(effect.source)):
			return false
		var previous := health
		health = maxf(0.0, health + max_health() - before)
		_count_gain("health", previous)
		if health == 0.0:
			alive = false
			killed_by = "effect"
	if record:
		inputs.append({"tick": ticks, "effect": effect.duplicate(true), "domain": domain})
	return true


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
## ceiling). Neither takes away a recovery package's overheal. What Dividers
## took and haven't given back yet lowers Regen's ceiling (D134).
func _heal(amount: float, source: String) -> void:
	# A draining Vampire stops both (D115), and so does a standing Lock (D133).
	if (draining or locked) and (source == "regen" or source == "lifesteal"):
		return
	var before := health
	var held := divider_held + thief_held
	if source == "regen" and held > 0.0:
		# No drift past the best while any of a bite is held: the ceiling is
		# below the best.
		health += minf(amount, maxf(0.0, maxf(max_health(), peak_number) - held - health))
	elif source == "regen":
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
	return EnemyKinds.health(kind, health_level, wave, tier, divider, lock)


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
		if wave >= TowerData.last_wave():
			alive = false
			killed_by = "data_limit"
			return
		wave += 1
		_advance_levels()
		spawns.schedule_wave()
	spawns.spawn_due()
	if sure_from > 0 and wave >= sure_from and (wave - sure_from) % sure_every == 0 and _sure_landed != wave and wave_clock >= SURE_LANDS_AT:
		_land_sure_divider()
	divider_held = maxf(0.0, divider_held - _held_release * TICK)
	if thief_held > 0.0:
		thief_held = maxf(0.0, thief_held - _thief_release * TICK)
	_heal(stat("health_regen") * TICK, "regen")
	peak_number = maxf(peak_number, health)
	defences.tick_wall()
	defences.tick_shockwave()
	_move_enemies()
	_enemies_hit()
	if locked:
		locked_seconds += TICK
	if not alive:
		return
	_tick_super_tower()
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
	# Factor (a candidate card): a boss arrives with less health.
	if kind == "boss":
		enemy.max_health *= minf(1.0, rules.value("boss_health"))
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
	# Slow Aura (a candidate card): enemies inside Range walk slower.
	var slow := clampf(rules.value("slow_aura"), 0.0, Guesses.SLOW_AURA_MOST)
	var reach := stat("range") if slow > 0.0 else 0.0
	var escaped: Array[Enemy] = []
	for enemy in enemies:
		# A thief walks its bite back out, and is gone where enemies set off.
		if enemy.fleeing:
			enemy.distance += enemy.speed * thief_speed * TICK
			if enemy.distance >= Guesses.SPAWN_DISTANCE_M:
				escaped.append(enemy)
			continue
		# Ranged enemies stop on the edge of the tower's Range, wherever it is
		# now: more Range and the ones still walking stop further out.
		if EnemyKinds.stops_at_range(enemy.kind) and not enemy.arrived():
			enemy.stop_at = stat("range")
		# Melee enemies stop at a standing Wall, and walk on when it falls.
		elif not EnemyKinds.stops_at_range(enemy.kind):
			var at_wall := defences.wall_up() and enemy.distance >= Guesses.WALL_DISTANCE_M
			enemy.stop_at = Guesses.WALL_DISTANCE_M if at_wall else Guesses.CONTACT_DISTANCE_M
		if not enemy.arrived():
			var speed := enemy.speed * (1.0 - slow) if slow > 0.0 and enemy.distance <= reach else enemy.speed
			enemy.distance = maxf(enemy.stop_at, enemy.distance - speed * TICK)
	for enemy in escaped:
		_escape(enemy)


## Every enemy in place hits when its time comes: Defense % comes off first,
## then Defense Absolute, which can take a hit to nothing. Thorns then deals
## the enemy a share of its own maximum health, half on a boss, whatever the
## defences took off, because the contact still happened.
func _enemies_hit() -> void:
	var thorned: Array[Enemy] = []
	var spent: Array[Enemy] = []
	draining = false
	locked = false
	for enemy in enemies:
		if enemy.fleeing or not enemy.arrived():
			continue
		var style := EnemyKinds.attack_style(enemy.kind)
		if style == "divide":
			spent.append(enemy)
			continue
		# A Lock in place hits nothing, so takes no Thorns; it only holds the
		# Number where it is (D133).
		if style == "hold":
			locked = true
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
			deal_damage(enemy, enemy.max_health * thorns, "thorns", false)
			if enemy.health <= 0.0:
				thorned.append(enemy)
	# Removed after the loop, which mustn't lose enemies from under it.
	for enemy in spent:
		_divide(enemy)
	for enemy in thorned:
		_kill(enemy, "thorns")


## A Divider reaches the Number, or the Wall in front of it, and takes
## 1 - 1/divisor of it through the defences (D081's single pipeline), then is
## used up: gone, unpaid, and no longer a target for shots already flying.
## Half of anything is never all of it, so it can't end a run on its own.
func _divide(enemy: Enemy) -> void:
	var divisor := enemy.divisor if enemy.divisor > 0.0 else EnemyKinds.divider_divisor(divider, wave)
	var share := divide_share(divisor)
	var at_wall := defences.wall_up() and enemy.distance > Guesses.CONTACT_DISTANCE_M
	var loss := 0.0
	if at_wall:
		loss = minf(defences.wall_health, landed_damage(defences.wall_health * share))
		defences.hit_wall(loss)
	else:
		loss = divide_loss(divisor)
		health -= loss
		if float(divider.get("refill_seconds", 0.0)) > 0.0:
			divider_held += loss
			_held_release = divider_held / float(divider.refill_seconds)
		lost_to["divider"] = float(lost_to.get("divider", 0.0)) + loss
	dividers_landed += 1
	# A thief keeps its bite and walks it out (D151). Only a bite that reached
	# the Number can be carried, not one the Wall took, and the measuring
	# Divider (`sure_from`) was never on the field to carry anything.
	if thieves and not at_wall and loss > 0.0 and enemy in enemies:
		_carry_off(enemy, loss)
	else:
		enemy.health = 0.0
		enemies.erase(enemy)
	if record_events:
		# The Number as it stood, for the screen's peel (D145).
		events.append({"type": "divided", "enemy": enemy, "damage": loss, "at_wall": at_wall, "divisor": divisor, "before": health + (0.0 if at_wall else loss)})


## A thief grabs `bite` of the Number and starts walking it out (D151). The
## bite stays out of Regen's reach while the thief lives, and fades from there
## only if `thief_fade` says so.
func _carry_off(thief: Enemy, bite: float) -> void:
	thief.fleeing = true
	thief.carried = bite
	thief.carry_health = thief.health
	thief.carry_paid = 0.0
	# It has hit once, so killing it later isn't a clean kill that grows the Number.
	thief.hits = maxi(thief.hits, 1)
	thefts += 1
	thief_taken += bite
	thief_held += bite
	_thief_release = thief_held / thief_fade if thief_fade > 0.0 else 0.0


## Damage dealt to a carrier pays its bite back in proportion: `dealt` of the
## health it had when it grabbed it. The share comes back times
## `thief_recovery`, so a recovery past 1 returns more than was taken, and the
## held bite is released by what came back, so Regen can't refill the rest.
func _pay_back(thief: Enemy, dealt: float) -> void:
	if thief.carry_health <= 0.0:
		return
	var share := minf(dealt / thief.carry_health, 1.0 - thief.carry_paid)
	if share <= 0.0:
		return
	thief.carry_paid += share
	var returned := thief.carried * share * thief_recovery
	var before := health
	health += returned
	thief_held = maxf(0.0, thief_held - returned)
	thief_recovered += returned
	_count_gain("recovery", before)


## A thief reaches where enemies set off and takes what it still holds with it.
func _escape(thief: Enemy) -> void:
	thieves_escaped += 1
	thief_escaped += thief.carried * (1.0 - thief.carry_paid)
	thief.health = 0.0
	enemies.erase(thief)
	if record_events:
		events.append({"type": "escaped", "enemy": thief})


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
	return minf(health, landed_damage(health * divide_share(divisor)))


## The share a ÷ of `divisor` takes, of the Number or of a standing Wall:
## 1 - 1/divisor, softened by Remainder (a candidate card).
func divide_share(divisor: float) -> float:
	return (1.0 - 1.0 / maxf(1.0, divisor)) * minf(1.0, rules.value("divide_share"))


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
		# Berserker and Super Tower (candidate cards) raise the tower's Damage
		# before a critical multiplies it; both are neutral without their card.
		var tower_damage := (stat("damage") + berserker_bonus()) * super_tower_boost() * number_boost()
		var damage := tower_damage * (stat("critical_factor") if critical else 1.0)
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


## What the Number has absorbed this run, as Berserker counts it: the hits
## that took it off after defences, and a Vampire's drain. A Divider divides the
## Number rather than damaging it, and what the Wall took never reached it, so
## neither counts. Read from `lost_to`, which a saved battle already carries.
func damage_absorbed() -> float:
	var total := 0.0
	for kind in lost_to:
		if kind != "divider":
			total += float(lost_to[kind])
	return total


## Berserker (a candidate card): its share of the damage absorbed so far, added
## to each shot's Damage, up to BERSERKER_MOST times the Damage.
func berserker_bonus() -> float:
	var share := rules.value("berserker")
	if share <= 0.0:
		return 0.0
	return minf(share * damage_absorbed(), Guesses.BERSERKER_MOST * stat("damage"))


## Super Tower (a candidate card): the times Damage while its burst lasts, 1
## otherwise and without the card.
func super_tower_boost() -> float:
	if cooldowns.time_left("super_tower") > SKIP_SLACK:
		return rules.value("super_tower")
	return 1.0


## The Number as ammunition (D151, a measuring option): the tower's shots are
## multiplied by the Number over The Tower's starting Health, to the power
## `number_power`, never under 1. Mines, Thorns and Orbs don't use it. Neutral
## at 0, the game's.
func number_boost() -> float:
	if number_power <= 0.0:
		return 1.0
	var start := TowerData.value("health", 0)
	return pow(maxf(health, start) / start, number_power)


## Super Tower runs on two cooldowns, so a saved battle carries its place in
## the cycle: how long the burst has left, and how long until it is ready
## again. It is ready as the run begins. Without the card it adds neither.
func _tick_super_tower() -> void:
	if rules.value("super_tower") <= 1.0:
		return
	cooldowns.set_time("super_tower", maxf(0.0, cooldowns.time_left("super_tower") - TICK))
	cooldowns.set_time("super_tower_wait", maxf(0.0, cooldowns.time_left("super_tower_wait") - TICK))
	if cooldowns.time_left("super_tower_wait") <= SKIP_SLACK:
		cooldowns.set_time("super_tower", Guesses.SUPER_TOWER_ACTIVE)
		cooldowns.set_time("super_tower_wait", Guesses.SUPER_TOWER_PERIOD)


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
		if enemy.distance <= reach and (nearest == null or _comes_first(enemy, nearest)):
			nearest = enemy
	return nearest


func _in_range_nearest_first() -> Array[Enemy]:
	var reach := stat("range")
	var found: Array[Enemy] = []
	for enemy in enemies:
		if enemy.distance <= reach:
			found.append(enemy)
	found.sort_custom(_comes_first)
	return found


## Which of two enemies in range the tower shoots first: the nearer, or with
## `thief_priority` a carrier before anything else (D151).
func _comes_first(a: Enemy, b: Enemy) -> bool:
	if thief_priority and a.fleeing != b.fleeing:
		return a.fleeing
	return a.distance < b.distance


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
	# Unequal (a candidate card): shots hit a Lock harder.
	if enemy.kind == "lock":
		damage *= rules.value("lock_damage")
	# Rend Armor: by its chance a strike makes every later one on this enemy
	# hit harder, stacking to REND_CAP.
	if is_open("rend_armor_chance") and _combat_rng.randf() < stat("rend_armor_chance"):
		enemy.rend = minf(REND_CAP, enemy.rend + stat("rend_armor_mult"))
	_heal(stat("lifesteal") * minf(damage, maxf(enemy.health, 0.0)), "lifesteal")
	# The roll is made for every kind, so an immune one never shifts the
	# stream the rest of the run draws from.
	var knocked := enemy.health > damage and stat("knockback_chance") > 0.0 and _combat_rng.randf() < stat("knockback_chance")
	# A thief is already walking out, so a push would only help it escape.
	if knocked and EnemyKinds.knockback_moves(enemy.kind) and not enemy.fleeing:
		var push := stat("knockback_force") * Guesses.KNOCKBACK_METRES_PER_FORCE / EnemyKinds.mass_now(enemy, wave)
		enemy.distance = minf(Guesses.SPAWN_DISTANCE_M, enemy.distance + push)
	deal_damage(enemy, damage, "shot", false)
	if record_events:
		events.append({"type": "enemy_hit", "enemy": enemy, "damage": damage, "critical": critical})
	if enemy.health <= 0.0:
		_kill(enemy)
		# Critical Coin (a candidate card): a basic a critical shot kills may
		# drop Coins. Rolled only with the card, so the stream is unchanged without.
		var drop := rules.value("critical_coin")
		if critical and drop > 0.0 and EnemyKinds.pays_as(enemy) == "basic" and _combat_rng.randf() < drop:
			# Paid as a basic worth CRITICAL_COIN_COINS, decay and all.
			var dropped := EnemyKinds.coins(enemy, wave, stat("coins_per_kill"), tier, Guesses.CRITICAL_COIN_COINS) * rules.value("coin_multiplier")
			coins += dropped
			if record_events:
				events.append({"type": "critical_coin", "enemy": enemy, "coins": dropped})


## One damage/kill boundary for shots, defences and later abilities. The
## caller resolves source-specific crit, shielding and lifesteal first.
## Deferred kills preserve existing iteration and effect order.
func deal_damage(enemy: Enemy, amount: float, source: String, finish := true) -> bool:
	if enemy not in enemies or enemy.health <= 0.0 or not is_finite(amount) or amount < 0.0 or source.is_empty():
		return false
	var dealt := minf(amount, enemy.health)
	damage_by[source] = float(damage_by.get(source, 0.0)) + dealt
	if enemy.fleeing:
		_pay_back(enemy, dealt)
	enemy.health -= amount
	if finish and enemy.health <= 0.0:
		_kill(enemy, source)
	return true


## `by` names what killed it when the screen draws that differently: "orb" for
## an orb, which sets it to 0 (D106).
func _kill(enemy: Enemy, by := "") -> void:
	if enemy not in enemies:
		return
	enemies.erase(enemy)
	_protectors.erase(enemy)
	kills += 1
	var source := by if by != "" else "shot"
	kills_by[source] = int(kills_by.get(source, 0)) + 1
	if enemy.hits == 0 and enemy.attack > 0.0 and not locked:
		# Killed before it could land a hit: a share of the hit it never
		# landed grows the Number, past Health too (D098); not under a Lock.
		var before := health
		health += enemy.attack * kill_share * rules.value("kill_growth")
		_count_gain("kills", before)
		if record_events:
			events.append({"type": "grown", "enemy": enemy, "gain": health - before})
	var paid_cash := EnemyKinds.cash(enemy, stat("cash_bonus")) * rules.value("cash_multiplier")
	var paid_coins := EnemyKinds.coins(enemy, wave, stat("coins_per_kill"), tier, rules.value("basic_coins")) * rules.value("coin_multiplier")
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
	var paid_cash := stat("cash_per_wave") * stat("cash_bonus") * rules.value("cash_multiplier")
	# Interest on the Cash held, after the wave's Cash, up to its cap.
	paid_cash += minf(rules.value("interest_cap"), (cash + paid_cash) * stat("interest"))
	cash += paid_cash
	cash_earned += paid_cash
	if is_open("coins_per_wave"):
		coins += stat("coins_per_wave") * float(TowerData.tier(tier).coins) * rules.value("coin_multiplier")
	# Recovery Packages: by its chance a wave's end heals a share of Health,
	# which may go past Health up to Max Recovery times it. A standing Lock
	# stops it (D133), after the roll, so the stream is drawn as ever.
	if is_open("package_chance") and _combat_rng.randf() < stat("package_chance") and not locked:
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
