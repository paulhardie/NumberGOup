extends RefCounted
## Which enemies each wave sends and when, factored out of BattleSim (AGENTS.md
## law 7, D117): The Tower's spawn rolls (D114), its mix and caps (D113), the
## Protector's gate and the elites' chances (D115), and the Divider's slot
## (D094). It rolls a wave as the wave starts and hands each enemy to the sim
## as it falls due; what an enemy is comes from EnemyKinds.
## It draws only from its own two streams, in the same order as before, so a
## run and its replay are unchanged.

const Guesses = preload("res://src/tower/guesses.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const EnemyKinds = preload("res://src/tower/enemy_kinds.gd")

## The battle, held weakly: the battle holds this, so a strong reference back
## would keep both alive for ever.
var sim:
	get:
		return _battle.get_ref()
var _battle: WeakRef

var _spawn_rng := RandomNumberGenerator.new()
## Which basic a Divider replaces is drawn from its own stream, so The Tower's
## enemies, which kinds come and where from, are exactly what they were
## without it.
var _divider_rng := RandomNumberGenerator.new()
## The Divider owed but not yet due: a wave's share carries to the next.
var divider_due := 0.0
## This wave's spawns in order, {kind, at} with `at` seconds into the wave,
## and the next one due.
var schedule: Array[Dictionary] = []
var next_spawn := 0
## This wave's spawns so far, and those the caps turned away (Wave Info).
var wave_spawned := 0
var wave_missed := 0
## The Protector's gate (D115): waves counted down, 2 a wave, until one may
## come; and whether one may this wave.
var protector_gate := 0
var _protector_due := false


func _init(battle) -> void:
	_battle = weakref(battle)


## Seeds the streams from the run's seed and shuts the Protector's gate.
func start(seed_value: int) -> void:
	_spawn_rng.seed = hash([seed_value, "spawn"])
	_divider_rng.seed = hash([seed_value, "divider"])
	protector_gate = int(TowerData.tier(sim.tier).protector_gate)


func spawn_state() -> String:
	return str(_spawn_rng.state)


func divider_state() -> String:
	return str(_divider_rng.state)


## Rolls the wave that has just started.
func schedule_wave() -> void:
	var wave: int = sim.wave
	var tier: int = sim.tier
	schedule.clear()
	next_spawn = 0
	wave_spawned = 0
	wave_missed = 0
	# The Protector (D115): a share of the draws once its gate, counted down 2
	# a wave, is open; at most one a wave, and one coming shuts the gate again.
	protector_gate = maxi(0, protector_gate - int(TowerData.enemies().protector.gate_step))
	var protector := TowerData.protector_chance(wave, tier) if protector_gate <= 0 else 0.0
	_protector_due = protector > 0.0
	var mix := tier_mix(protector / 100.0)
	if TowerData.is_boss_wave(wave, tier):
		schedule.append({"kind": "boss", "at": 0.0})
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
		schedule.append({"kind": _draw_spawn(mix), "at": at})
		if _spawn_rng.randf() < double:
			schedule.append({"kind": _draw_spawn(mix), "at": at})
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
				insert_spawn(kind, _spawn_rng.randf() * TowerData.spawn_seconds())
	# A Divider takes the Protector's slot in The Tower's standard pool (D094):
	# it replaces one of the wave's basics, so the wave's size and the rest of
	# its enemies are The Tower's. At most one a wave, so at a rate of one
	# every other wave or less never two waves running; one owed with no basic
	# to replace waits for the next wave without piling up.
	divider_due += EnemyKinds.divider_rate(sim.divider, wave)
	if divider_due < 1.0 - sim.SKIP_SLACK:
		return
	var basics: Array[int] = []
	for index in range(schedule.size()):
		if schedule[index].kind == "basic":
			basics.append(index)
	if basics.is_empty():
		divider_due = 1.0
		return
	divider_due -= 1.0
	schedule[basics[_divider_rng.randi_range(0, basics.size() - 1)]].kind = "divider"


## Hands the sim every spawn now due, bar those the caps turn away.
func spawn_due() -> void:
	while next_spawn < schedule.size() and float(schedule[next_spawn].at) <= sim.wave_clock:
		var kind: String = schedule[next_spawn].kind
		next_spawn += 1
		# The field is full of its sort: this one never comes (The Tower's caps).
		if not has_room(kind):
			wave_missed += 1
			continue
		wave_spawned += 1
		# A Divider comes from where the basic it replaced would have, so every
		# other enemy's direction is The Tower's too.
		sim._place(kind, _spawn_rng.randf() * TAU)


## The mix of kinds: a tier raises the fast, tank and ranged shares by its
## weight, the Protector takes its `protector` share, and basics fill the
## rest. Tier 1's is the data's as it stands.
func tier_mix(protector := 0.0) -> Dictionary:
	var mix: Dictionary = TowerData.enemies().mix
	var weight := float(TowerData.tier(sim.tier).mix_weight)
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
	for enemy in sim.enemies:
		if enemy.kind == kind or (kind == "normal" and enemy.kind != "boss" and not EnemyKinds.is_elite(enemy.kind)) \
				or (kind == "elite" and EnemyKinds.is_elite(enemy.kind)):
			count += 1
	return count


## Whether the caps leave room for one more `kind`: 120 normal enemies, 20
## elites with 8 of a type, and 10 bosses (D113, D115).
func has_room(kind: String) -> bool:
	if kind == "boss":
		return count_on_field("boss") < TowerData.boss_cap()
	if EnemyKinds.is_elite(kind):
		return count_on_field("elite") < TowerData.elite_cap() and count_on_field(kind) < TowerData.elite_type_cap()
	return count_on_field("normal") < TowerData.enemy_cap()


## Puts a spawn into the wave's schedule, after everything due at or before it.
func insert_spawn(kind: String, at: float) -> void:
	var index := schedule.size()
	while index > 0 and float(schedule[index - 1].at) > at:
		index -= 1
	schedule.insert(index, {"kind": kind, "at": at})


## A normal enemy's kind, from the mix; a Protector drawn after this wave's
## one comes as a basic.
func _draw_spawn(mix: Dictionary) -> String:
	var kind := _draw_kind(mix)
	if kind != "protector":
		return kind
	if not _protector_due:
		return "basic"
	_protector_due = false
	protector_gate = int(TowerData.tier(sim.tier).protector_gate)
	return kind


func _draw_kind(mix: Dictionary) -> String:
	var roll := _spawn_rng.randf()
	for kind in mix:
		roll -= float(mix[kind])
		if roll < 0.0:
			return kind
	return "basic"


## What the Wave Info panel shows (D115), as The Tower's does: the wave's
## spawn rate and double-spawn chance, how many it has sent and turned away,
## what's on the field against the caps, and each kind's health, attack,
## speed and chance.
func wave_info() -> Dictionary:
	var wave: int = sim.wave
	var tier: int = sim.tier
	var rolls := roundi(TowerData.spawn_seconds() / TowerData.spawn_roll_seconds())
	var rate := TowerData.spawn_rate(wave)
	var double := float(TowerData.tier(tier).double_spawn)
	var protector := TowerData.protector_chance(wave, tier)
	var mix := tier_mix(protector / 100.0)
	# Each row's chance, and for some, waves until it may come or a second's chance.
	var rows: Array[Dictionary] = []
	for kind in mix:
		var gate := ceili(float(protector_gate) / float(TowerData.enemies().protector.gate_step)) if kind == "protector" else 0
		rows.append(_info_row(kind, 100.0 * float(mix[kind]), gate))
	var boss_every := int(TowerData.tier(tier).boss_every)
	var boss_in := (boss_every - wave % boss_every) % boss_every
	rows.append(_info_row("boss", 100.0 if boss_in == 0 else 0.0, boss_in))
	var dividers := EnemyKinds.divider_rate(sim.divider, wave)
	if dividers > 0.0:
		rows.append(_info_row("divider", 100.0 * minf(1.0, dividers)))
	var elite := TowerData.elite_chance(wave, tier)
	for kind in TowerData.ELITES:
		rows.append(_info_row(kind, elite.single, 0, elite.double))
	return {
		"wave": wave, "tier": tier, "spawn_rate": rate, "double_spawn": 100.0 * double, "rolls": rolls,
		"roll_seconds": TowerData.spawn_roll_seconds(), "expected": rolls * rate / 100.0 * (1.0 + double),
		"due": schedule.size(), "spawned": wave_spawned, "missed": wave_missed,
		"normal": count_on_field("normal"), "normal_cap": TowerData.enemy_cap(),
		"elites": count_on_field("elite"), "elite_cap": TowerData.elite_cap(),
		"bosses": count_on_field("boss"), "boss_cap": TowerData.boss_cap(),
		"protector_radius": TowerData.protector_radius_m(wave, tier), "rows": rows,
	}


func _info_row(kind: String, chance: float, waits := 0, second := 0.0) -> Dictionary:
	return {"kind": kind, "health": sim.enemy_health_now(kind), "attack": sim.enemy_attack_now(kind),
		"speed": EnemyKinds.speed_m(kind, sim.wave, sim.tier, sim.divider), "chance": chance, "waits": waits, "second": second}
