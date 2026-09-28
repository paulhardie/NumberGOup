extends RefCounted
## The Workshop's later defences in a battle, factored out of BattleSim (AGENTS.md
## law 7): the Wall, orbs, shockwaves and land mines. Each keeps its own
## state here and acts on the sim's enemies through it: the sim calls in at
## fixed points of its tick, in the same order as before, so a run and its
## replay are unchanged. Their rules are The Tower's where it says, and ours,
## in Guesses, where it doesn't (D076, D104).

const Guesses = preload("res://src/tower/guesses.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const EnemyKinds = preload("res://src/tower/enemy_kinds.gd")

## The battle, held weakly: the battle holds these defences, so a strong
## reference back would keep both alive for ever.
var sim:
	get:
		return _battle.get_ref()
var _battle: WeakRef
## The Wall's health now, and seconds until a fallen one is rebuilt.
var wall_health := 0.0
var wall_rebuild_in := 0.0
## Seconds until the next shockwave.
var shockwave_in := 0.0
## Land mines lying in range, as positions.
var mines: Array[Vector2] = []
## How fast orbs turn at Orb Speed's first level (Guesses), which the
## measuring tools may change before the first step to try others.
var orb_turns_first := Guesses.ORB_TURNS_PER_SECOND_AT_FIRST_LEVEL
var orb_hit_m := Guesses.ORB_HIT_M


func _init(battle) -> void:
	_battle = weakref(battle)


## Sets them up as a run starts: a standing Wall, a shockwave's timer.
func start() -> void:
	if sim.is_open("wall_health"):
		wall_health = wall_max_health()
	if sim.is_open("shockwave_frequency"):
		shockwave_in = sim.stat("shockwave_frequency")


func wall_max_health() -> float:
	return sim.stat("wall_health") * sim.max_health() if sim.is_open("wall_health") else 0.0


func wall_up() -> bool:
	return wall_health > 0.0


## The Wall takes `loss`; if that brings it down, it rebuilds after Wall
## Rebuild seconds.
func hit_wall(loss: float) -> void:
	wall_health -= loss
	if wall_health <= 0.0:
		wall_health = 0.0
		wall_rebuild_in = sim.stat("wall_rebuild")
		if sim.record_events:
			sim.events.append({"type": "wall_down"})


func tick_wall() -> void:
	if not sim.is_open("wall_health"):
		return
	wall_health = minf(wall_health, wall_max_health())
	if wall_up():
		return
	wall_rebuild_in -= sim.TICK
	if wall_rebuild_in <= 0.0:
		wall_health = wall_max_health()
		# Rising again, it pushes out every enemy that came inside while it
		# was down, so none is trapped against the Number (D116).
		for enemy in sim.enemies:
			enemy.distance = maxf(enemy.distance, Guesses.WALL_DISTANCE_M)
		if sim.record_events:
			sim.events.append({"type": "wall_up"})


## Shockwave: every Shockwave Frequency seconds, every enemy in range but a
## boss or an elite is pushed back by Shockwave Size, never past where
## enemies set off.
func tick_shockwave() -> void:
	if not sim.is_open("shockwave_frequency"):
		return
	shockwave_in -= sim.TICK
	if shockwave_in > 0.0:
		return
	shockwave_in += sim.stat("shockwave_frequency")
	for enemy in sim.enemies:
		if EnemyKinds.shockwave_moves(enemy.kind) and enemy.distance <= sim.stat("range"):
			enemy.distance = minf(Guesses.SPAWN_DISTANCE_M, enemy.distance + sim.stat("shockwave_size"))
	if sim.record_events:
		sim.events.append({"type": "shockwave"})


## Orbs circle at least Guesses.ORB_MIN_RADIUS_M out, further inside a Range
## that grows past it (D108), and kill any enemy that comes within
## Guesses.ORB_HIT_M of one, walking or standing, unless it's one orbs can't
## kill (EnemyKinds.orbs_kill) or a Protector shields it (D115). They turn on the run's clock, and each tick
## checks the whole arc an orb swept, not just where it ends up.
func orb_radius() -> float:
	return Guesses.ORB_MIN_RADIUS_M + Guesses.ORB_RANGE_SLOPE * maxf(0.0, sim.stat("range") - Guesses.ORB_MIN_RADIUS_M)


func orb_turns_per_second() -> float:
	return orb_turns_first * sim.stat("orb_speed") / TowerData.value("orb_speed", 0)


func orb_angles(at_time: float = sim.time) -> Array[float]:
	var angles: Array[float] = []
	var count: int = int(sim.stat("orbs"))
	for orb in range(count):
		angles.append(fposmod(TAU * orb_turns_per_second() * at_time + TAU * float(orb) / float(count), TAU))
	return angles


func sweep_orbs() -> void:
	var starts: Array[float] = orb_angles(sim.time - sim.TICK)
	if starts.is_empty():
		return
	var radius: float = orb_radius()
	var sweep: float = TAU * orb_turns_per_second() * sim.TICK
	var slack: float = orb_hit_m / radius
	var touched := []
	for enemy in sim.enemies:
		if not EnemyKinds.orbs_kill(enemy.kind) or absf(enemy.distance - radius) > orb_hit_m:
			continue
		for start in starts:
			# How far ahead of the orb's starting angle the enemy sits.
			if fposmod(enemy.angle - start + slack, TAU) <= sweep + 2.0 * slack:
				touched.append(enemy)
				break
	for enemy in touched.filter(func(enemy): return not sim.shielded(enemy)):
		enemy.health = 0.0
		sim._kill(enemy, "orb")


## A shot may lay a land mine, by Land Mine Chance, somewhere between the
## tower's edge and its Range, while there's room for another. Drawn from the
## combat stream, at the moment the sim fires, as it always was.
func maybe_lay_mine() -> void:
	if sim.stat("land_mine_chance") > 0.0 and mines.size() < Guesses.MAX_LAND_MINES and sim._combat_rng.randf() < sim.stat("land_mine_chance"):
		var reach: float = sim._combat_rng.randf_range(Guesses.CONTACT_DISTANCE_M, sim.stat("range"))
		mines.append(Vector2.from_angle(sim._combat_rng.randf() * TAU) * reach)


## A blast: Land Mine Damage's share of Damage, with the average crit built
## in as The Tower's is: × (1 + Critical Factor × Critical Chance) × (1 +
## Super Crit Mult × Super Crit Chance × Critical Chance) (D116).
func mine_damage() -> float:
	var crit: float = 1.0 + sim.stat("critical_factor") * sim.stat("critical_chance")
	var super_crit: float = 1.0 + sim.stat("super_crit_mult") * sim.stat("super_crit_chance") * sim.stat("critical_chance")
	return sim.stat("damage") * sim.stat("land_mine_damage") * crit * super_crit


## A walking enemy that comes within LAND_MINE_TRIGGER_M of a mine sets it off:
## every enemy within Land Mine Radius takes Land Mine Damage's share of Damage.
func trigger_mines() -> void:
	if mines.is_empty():
		return
	var blasts: Array[Vector2] = []
	for mine in mines:
		for enemy in sim.enemies:
			if not enemy.arrived() and enemy.position().distance_to(mine) <= Guesses.LAND_MINE_TRIGGER_M:
				blasts.append(mine)
				break
	for mine in blasts:
		mines.erase(mine)
		var fallen := []
		for enemy in sim.enemies:
			if enemy.position().distance_to(mine) <= sim.stat("land_mine_radius"):
				enemy.health -= mine_damage() * sim.damage_taken(enemy)
				if enemy.health <= 0.0:
					fallen.append(enemy)
		for enemy in fallen:
			sim._kill(enemy)
		if sim.record_events:
			sim.events.append({"type": "mine", "at": mine})
