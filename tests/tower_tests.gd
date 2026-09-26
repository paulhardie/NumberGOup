extends SceneTree
## The rebuild's tests: The Tower's numbers as the data states them, the
## battle's rules, and that a run replays exactly from its seed.
##
##   bash run_tests.sh

const Guesses = preload("res://src/tower/guesses.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Palette = preload("res://src/ui/palette.gd")
const BattleScreen = preload("res://src/ui/battle_screen.gd")

var _failures: Array[String] = []
var _checks := 0


func _init() -> void:
	# Once the tree is running, so screens added to it set themselves up.
	_run.call_deferred()


func _run() -> void:
	for method in get_method_list():
		if String(method.name).begins_with("test_"):
			call(method.name)
	if _failures.is_empty():
		print("PASS: tower tests (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: ", failure)
		printerr("FAIL: %d of %d checks" % [_failures.size(), _checks])
		quit(1)


func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func check_near(got: float, want: float, tolerance: float, message: String) -> void:
	check(absf(got - want) <= tolerance, "%s: got %s, want %s" % [message, got, want])


func test_enemy_stats_match_the_owners_screens() -> void:
	for reading in TowerData.enemies().readings:
		var wave := int(reading.wave)
		check_near(TowerData.enemy_attack(wave, "basic"), float(reading.attack), 0.011, "wave %d attack" % wave)
		check_near(TowerData.enemy_health(wave, "basic"), float(reading.health), maxf(0.011, float(reading.health) * 0.003), "wave %d health" % wave)


func test_enemy_types_scale_the_basic_enemy() -> void:
	var wave := 30
	var basic_health := TowerData.enemy_health(wave, "basic")
	var basic_attack := TowerData.enemy_attack(wave, "basic")
	check_near(TowerData.enemy_health(wave, "boss"), basic_health * 20.0, 0.001, "a boss has 20 basics' health")
	check_near(TowerData.enemy_attack(wave, "boss"), basic_attack, 0.001, "a boss hits like a basic")
	check_near(TowerData.enemy_health(wave, "tank"), basic_health * 5.0, 0.001, "a tank has 5 basics' health")
	check_near(TowerData.enemy_attack(wave, "tank"), basic_attack * 0.5, 0.001, "a tank hits half as hard")
	check(TowerData.enemy_speed_m(wave, "fast") > TowerData.enemy_speed_m(wave, "basic"), "fast enemies are faster")


func test_a_fresh_tower_is_the_towers() -> void:
	var sim := BattleSim.new(1)
	check_near(sim.stat("damage"), 3.0, 0.0, "fresh Damage")
	check_near(sim.stat("attack_speed"), 1.0, 0.0, "fresh Attack Speed")
	check_near(sim.stat("critical_chance"), 0.01, 0.0, "fresh Critical Chance")
	check_near(sim.stat("critical_factor"), 1.2, 0.0, "fresh Critical Factor")
	check_near(sim.stat("range"), 30.0, 0.0, "fresh Range in metres")
	check_near(sim.health, 5.0, 0.0, "fresh Health")
	check_near(sim.cash, 0.0, 0.0, "a run starts with no Cash")


func test_a_wave_lasts_the_towers_time() -> void:
	check_near(TowerData.spawn_seconds(), 26.0, 0.0, "26 seconds of spawning")
	check_near(TowerData.wave_seconds(), 34.7, 0.01, "then about 8.7 seconds of cooldown")
	var sim := BattleSim.new(3)
	sim.levels = {"health": 6000, "health_regen": 6000}
	sim.health = sim.max_health()
	while sim.time < TowerData.wave_seconds() - BattleSim.TICK:
		sim.step()
	check(sim.wave == 1, "still wave 1 just before its time is up")
	sim.step()
	sim.step()
	check(sim.wave == 2, "wave 2 once wave 1's time is up")


func test_the_tower_shoots_the_nearest_enemy_in_range_only() -> void:
	var sim := _quiet_sim()
	var near := _place(sim, "basic", 20.0)
	var far := _place(sim, "basic", 25.0)
	var outside := _place(sim, "basic", 31.0)
	for _i in range(40):
		sim.step()
	check(near.health < near.max_health or not sim.enemies.has(near), "the nearest enemy in range is shot")
	check(far.health == far.max_health, "the one further away waits")
	check(outside.health == outside.max_health, "an enemy out of range is never shot")


func test_a_kill_pays_cash_by_type_and_wave() -> void:
	var sim := _quiet_sim()
	var enemy := _place(sim, "basic", 10.0)
	enemy.health = 0.5
	for _i in range(60):
		sim.step()
	check_near(sim.cash, 1.0, 0.0, "a basic pays $1 on wave 1")
	check_near(sim.coins, 0.0, 0.0, "a basic pays no Coins")
	sim.wave = 10
	var tank := _place(sim, "tank", 10.0)
	tank.wave = 10
	tank.health = 0.5
	for _i in range(60):
		sim.step()
	check_near(sim.cash, 1.0 + 2.0 * 5.0, 0.0, "a wave 10 tank pays $2 times 5")
	check_near(sim.coins, 4.0 * 10.0, 0.0, "and 4 Coins times its wave")


func test_an_enemy_hits_on_arrival_then_harder_each_time() -> void:
	var sim := _quiet_sim()
	sim.levels = {"health": 20}
	sim.health = sim.max_health()
	var start := sim.health
	var enemy := _place(sim, "basic", Guesses.CONTACT_DISTANCE_M)
	enemy.max_health = 1e9
	enemy.health = 1e9
	sim.step()
	check_near(start - sim.health, enemy.attack, 0.0001, "the first hit lands on arrival")
	var after_first := sim.health
	for _i in range(roundi(Guesses.ENEMY_HIT_SECONDS / BattleSim.TICK)):
		sim.step()
	var regained := sim.stat("health_regen") * Guesses.ENEMY_HIT_SECONDS
	check_near(after_first - sim.health + regained, enemy.attack * Guesses.HEAT_UP_PER_HIT, 0.0001, "the second is 4% harder")


func test_the_tower_falls_at_no_health() -> void:
	var sim := _quiet_sim()
	var enemy := _place(sim, "boss", Guesses.CONTACT_DISTANCE_M)
	enemy.attack = 100.0
	enemy.health = 1e9
	sim.step()
	check(not sim.alive, "the tower falls")
	check(sim.killed_by == "boss", "and says what felled it")
	check_near(sim.health, 0.0, 0.0, "at no health")


func test_a_critical_shot_multiplies_its_damage() -> void:
	var sim := _quiet_sim()
	# 80%, The Tower's cap on Critical Chance.
	sim.levels = {"critical_chance": TowerData.max_level("critical_chance")}
	sim.record_events = true
	var enemy := _place(sim, "basic", 10.0)
	enemy.max_health = 1e9
	enemy.health = 1e9
	for _i in range(roundi(200.0 / BattleSim.TICK)):
		sim.step()
	var strikes := sim.events.filter(func(event): return event.type == "enemy_hit")
	var crits := strikes.filter(func(event): return event.critical)
	check(strikes.size() >= 195, "about a shot a second landed: %d" % strikes.size())
	for event in strikes:
		var want := sim.stat("damage") * (sim.stat("critical_factor") if event.critical else 1.0)
		check_near(event.damage, want, 0.0001, "a strike deals Damage, times Critical Factor on a crit")
	var share := float(crits.size()) / float(strikes.size())
	check(share > 0.7 and share < 0.9, "about 80%% of shots crit: %.2f" % share)


func test_a_run_replays_exactly_from_its_seed() -> void:
	var first := BattleSim.new(42, {"damage": 3, "health": 5})
	var second := BattleSim.new(42, {"damage": 3, "health": 5})
	first.run_until_dead(400.0)
	second.run_until_dead(400.0)
	check(first.time == second.time and first.wave == second.wave, "same end time and wave")
	check(first.kills == second.kills and first.cash == second.cash and first.health == second.health, "same kills, Cash and health")
	var other := BattleSim.new(43, {"damage": 3, "health": 5})
	other.run_until_dead(400.0)
	check(other.time != first.time or other.kills != first.kills, "another seed plays differently")


## The rebuild's milestone 1 benchmark: The Tower's fresh tower, buying
## nothing, dies at once (the owner, 25 September).
func test_a_fresh_tower_that_buys_nothing_falls_in_the_first_waves() -> void:
	for seed_value in range(1, 6):
		var sim := BattleSim.new(seed_value)
		sim.run_until_dead(600.0)
		check(not sim.alive and sim.wave <= 3, "seed %d fell on wave %d" % [seed_value, sim.wave])


func test_buying_a_level_costs_the_towers_cash() -> void:
	var sim := _quiet_sim()
	check(not sim.buy("damage"), "no Cash, no purchase")
	sim.cash = 25.0
	check(sim.price("damage") == 10.0, "the first Damage level costs $10")
	check(sim.buy("damage"), "a level bought with $10")
	check_near(sim.cash, 15.0, 0.0, "$10 spent")
	check_near(sim.stat("damage"), TowerData.value("damage", 1), 0.0, "Damage rises one level")
	check(sim.price("damage") == 12.0, "the next costs $12")
	check(sim.buy("damage") and not sim.buy("damage"), "$12 more buys one more, then the Cash runs out")
	check_near(sim.cash, 3.0, 0.0, "$3 left")


func test_a_run_prices_by_its_own_purchases() -> void:
	var sim := BattleSim.new(1, {"damage": 20})
	check(sim.price("damage") == 10.0, "Workshop levels don't raise a run's first price")
	check_near(sim.stat("damage"), TowerData.value("damage", 20), 0.0, "the run starts at the Workshop's level")


func test_only_open_rows_can_be_bought() -> void:
	var sim := _quiet_sim()
	sim.cash = 1e6
	for id in ["damage", "attack_speed", "critical_chance", "critical_factor", "health", "health_regen"]:
		check(sim.is_open(id), "%s is open from the start" % id)
	for id in ["range", "defense_absolute", "thorns", "cash_bonus", "coins_per_wave"]:
		check(not sim.is_open(id) and not sim.buy(id), "%s waits for the Workshop" % id)


func test_buying_health_heals_by_the_gain() -> void:
	var sim := _quiet_sim()
	sim.health = 2.0
	sim.cash = 10.0
	check(sim.buy("health"), "Health bought")
	check_near(sim.max_health(), 10.0, 0.0, "the most rises from 5 to 10")
	check_near(sim.health, 7.0, 0.0, "and the health you have rises by the same 5")


func test_nothing_past_a_rows_last_level() -> void:
	var sim := BattleSim.new(1, {"attack_speed": TowerData.max_level("attack_speed")})
	sim.cash = 1e9
	check(sim.at_max("attack_speed") and not sim.buy("attack_speed"), "a maxed row can't be bought")


func test_a_fallen_tower_buys_nothing() -> void:
	var sim := _quiet_sim()
	sim.cash = 100.0
	sim.alive = false
	check(not sim.buy("damage"), "no buying after the run ends")
	check_near(sim.cash, 100.0, 0.0, "and no Cash taken")


func test_things_are_drawn_between_their_last_two_ticks() -> void:
	var sim := _quiet_sim()
	var enemy := _place(sim, "basic", 50.0)
	enemy.speed = 30.0
	enemy.stop_at = Guesses.CONTACT_DISTANCE_M
	sim.step()
	check_near(enemy.drawn_at(0.0).length(), 50.0, 0.0001, "at blend 0, where it was a tick ago")
	check_near(enemy.drawn_at(1.0).length(), 49.0, 0.0001, "at blend 1, where it is now")
	check_near(enemy.drawn_at(0.5).length(), 49.5, 0.0001, "halfway between at 0.5")


func test_pressing_an_upgrade_card_buys_it() -> void:
	var screen = BattleScreen.new()
	root.add_child(screen)
	screen.sim.cash = 10.0
	screen._upgrades.refresh()
	var card: Button = screen._upgrades._cards["damage"].button
	check(not card.disabled, "an affordable card can be pressed")
	card.pressed.emit()
	check(screen.sim.run_levels.get("damage", 0) == 1, "pressing Damage buys a level")
	check_near(screen.sim.cash, 0.0, 0.0, "for $10")
	check(card.disabled, "and the card greys out once Cash runs short")
	screen.sim.health = screen.sim.max_health()
	screen.sim.run_levels = {"health": 2}
	screen.sim.health = screen.sim.max_health()
	screen._refresh()
	check(screen._health_text.text == "15 / 15", "full health 15.08 reads 15 / 15: %s" % screen._health_text.text)
	screen.sim.health = 0.3
	screen._refresh()
	check(screen._health_text.text.begins_with("1 /"), "a tower still standing never reads 0: %s" % screen._health_text.text)
	screen._upgrades.show_tab("utility")
	check(screen._upgrades._cards.is_empty() and screen._upgrades._empty.visible, "Utility says its rows open in the Workshop")
	screen.free()


func test_numbers_read_as_the_towers() -> void:
	check(Palette.number(2.35) == "2.35", "two decimals while small")
	check(Palette.number(3.0) == "3", "whole numbers stay whole")
	check(Palette.number(402.9) == "402", "whole past 100")
	check(Palette.number(1460.0) == "1.46K", "K past a thousand")
	check(Palette.number(7.42e8) == "742.00M", "M past a million")


## A sim with nothing spawning, for placing enemies by hand.
func _quiet_sim() -> BattleSim:
	var sim := BattleSim.new(1)
	sim._schedule.clear()
	sim.wave_clock = -1e9
	return sim


func _place(sim: BattleSim, kind: String, distance: float) -> BattleSim.Enemy:
	var enemy := BattleSim.Enemy.new()
	enemy.kind = kind
	enemy.wave = sim.wave
	enemy.max_health = TowerData.enemy_health(sim.wave, kind)
	enemy.health = enemy.max_health
	enemy.attack = TowerData.enemy_attack(sim.wave, kind)
	enemy.speed = 0.0
	enemy.angle = 0.0
	enemy.distance = distance
	enemy.last_distance = distance
	enemy.stop_at = minf(distance, Guesses.CONTACT_DISTANCE_M)
	sim.enemies.append(enemy)
	return enemy
