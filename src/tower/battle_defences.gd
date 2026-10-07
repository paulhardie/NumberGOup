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
var wall_rebuild_in: float:
	get: return sim.cooldowns.time_left("wall")
	set(value): sim.cooldowns.set_time("wall", value)
## Seconds until the next shockwave.
var shockwave_in: float:
	get: return sim.cooldowns.time_left("shockwave")
	set(value): sim.cooldowns.set_time("shockwave", value)
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
		# A thief walking its bite out would only be helped on its way (D152).
		if EnemyKinds.shockwave_moves(enemy.kind) and enemy.distance <= sim.stat("range") and not enemy.fleeing:
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


## Top-down patrol-line orbs (D168) cross the field once a turn: 150 seconds
## at the first Orb Speed level, about 10 at the last. So each column is passed
## as often as a round orb passes it; as fast as a round orb moves, the line
## passed each column about six times as often and orbs became most of the
## damage (TOP_DOWN.md 6). Metres a second.
func orb_line_speed() -> float:
	return Guesses.TOP_DOWN_WIDTH_M * orb_turns_per_second()


## How far along its patrol each orb has come, in metres unfolded (one patrol,
## across and back, is twice the field).
func orb_line_travel(at_time: float = sim.time) -> Array[float]:
	var travel: Array[float] = []
	var count: int = int(sim.stat("orbs"))
	for orb in range(count):
		travel.append(orb_line_speed() * at_time + 2.0 * Guesses.TOP_DOWN_WIDTH_M * float(orb) / float(count))
	return travel


## Where an orb stands, from the Number, `travelled` metres along its patrol:
## out from the left edge, back from the right.
func orb_line_point(travelled: float) -> Vector2:
	var width: float = Guesses.TOP_DOWN_WIDTH_M
	var along: float = fposmod(travelled, 2.0 * width)
	return Vector2((along if along < width else 2.0 * width - along) - width * 0.5, -orb_radius())


func orb_line_points(at_time: float = sim.time) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for travelled in orb_line_travel(at_time):
		points.append(orb_line_point(travelled))
	return points


func sweep_orbs() -> void:
	if sim.orb_line:
		_sweep_orb_line()
		return
	var starts: Array[float] = orb_angles(sim.time - sim.TICK)
	if starts.is_empty():
		return
	var radius: float = orb_radius()
	var sweep: float = TAU * orb_turns_per_second() * sim.TICK
	var slack: float = orb_hit_m / radius
	var touched := []
	for enemy in sim.enemies:
		# Where it truly is from the Number: its own line round, or top-down
		# (D167) its column and height.
		var at: Vector2 = enemy.position()
		var reach: float = at.length() if enemy.straight else enemy.distance
		var bearing: float = at.angle() if enemy.straight else enemy.angle
		if not EnemyKinds.orbs_kill(enemy.kind) or absf(reach - radius) > orb_hit_m:
			continue
		for start in starts:
			# How far ahead of the orb's starting angle the enemy sits.
			if fposmod(bearing - start + slack, TAU) <= sweep + 2.0 * slack:
				touched.append(enemy)
				break
	for enemy in touched.filter(func(enemy): return not sim.shielded(enemy)):
		sim.deal_damage(enemy, enemy.health, "orb")


## Each tick checks the stretch each orb covered, including a turn at an edge,
## and kills what stands within Guesses.ORB_HIT_M of it, as round orbs do.
func _sweep_orb_line() -> void:
	var before: Array[float] = orb_line_travel(sim.time - sim.TICK)
	if before.is_empty():
		return
	var after: Array[float] = orb_line_travel()
	var width: float = Guesses.TOP_DOWN_WIDTH_M
	var height: float = orb_radius()
	var stretches: Array[Vector2] = []
	for orb in range(before.size()):
		var from: float = orb_line_point(before[orb]).x
		var to: float = orb_line_point(after[orb]).x
		var low := minf(from, to)
		var high := maxf(from, to)
		# Crossing an edge mid-tick: the edge is part of the stretch.
		if floorf(before[orb] / width) != floorf(after[orb] / width):
			var edge: float = width * 0.5 * (1.0 if fposmod(floorf(after[orb] / width), 2.0) == 1.0 else -1.0)
			low = minf(low, edge)
			high = maxf(high, edge)
		stretches.append(Vector2(low - orb_hit_m, high + orb_hit_m))
	var touched := []
	for enemy in sim.enemies:
		var at: Vector2 = enemy.position()
		if not EnemyKinds.orbs_kill(enemy.kind) or absf(-at.y - height) > orb_hit_m:
			continue
		for stretch in stretches:
			if at.x >= stretch.x and at.x <= stretch.y:
				touched.append(enemy)
				break
	for enemy in touched.filter(func(enemy): return not sim.shielded(enemy)):
		sim.deal_damage(enemy, enemy.health, "orb")


## A shot may lay a land mine, by Land Mine Chance, somewhere between the
## tower's edge and its Range, while there's room for another. Drawn from the
## combat stream, at the moment the sim fires, as it always was.
func maybe_lay_mine() -> void:
	if sim.stat("land_mine_chance") > 0.0 and mines.size() < Guesses.MAX_LAND_MINES and sim._combat_rng.randf() < sim.stat("land_mine_chance"):
		var reach: float = sim._combat_rng.randf_range(Guesses.CONTACT_DISTANCE_M, sim.stat("range"))
		var turn: float = sim._combat_rng.randf()
		if sim.top_down:
			# Top-down (D167): above the Number, where enemies are, inside the field,
			# and no lower than they stop, so a walking one can always set it off.
			var half := Guesses.TOP_DOWN_WIDTH_M * 0.5
			var spot := Vector2.from_angle(-PI * turn) * reach
			mines.append(Vector2(clampf(spot.x, -half, half), minf(spot.y, -Guesses.CONTACT_DISTANCE_M)))
		else:
			mines.append(Vector2.from_angle(turn * TAU) * reach)


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
				sim.deal_damage(enemy, mine_damage() * sim.damage_taken(enemy), "mine", false)
				if enemy.health <= 0.0:
					fallen.append(enemy)
		for enemy in fallen:
			sim._kill(enemy, "mine")
		if sim.record_events:
			sim.events.append({"type": "mine", "at": mine})
