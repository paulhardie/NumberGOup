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
const Workshop = preload("res://src/tower/workshop.gd")
const Save = preload("res://src/tower/save.gd")

const TEST_SAVE := "user://test_tower_save.json"

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


func test_a_fresh_workshop_is_the_towers() -> void:
	var workshop := Workshop.new()
	check(workshop.coins == 0.0 and workshop.levels.is_empty(), "no Coins, no levels")
	check(workshop.open_groups == ["attack_start", "defense_start"], "only the free groups open: %s" % [workshop.open_groups])
	check(workshop.price("damage") == 30.0, "the first Damage level costs 30 Coins")
	check(workshop.price("critical_chance") == 50.0, "the crit rows cost 50")


func test_workshop_levels_cost_coins() -> void:
	var workshop := Workshop.new()
	check(not workshop.buy("damage"), "no Coins, no level")
	workshop.add_coins(100.0)
	check(workshop.buy("damage") and workshop.level("damage") == 1, "30 Coins buys Damage level 1")
	check_near(workshop.coins, 70.0, 0.0, "30 spent")
	check(workshop.price("damage") == 55.0, "the next costs 55")
	check(not workshop.buy("range") and not workshop.buy("thorns"), "rows in closed groups can't be bought")
	workshop.add_coins(-50.0)
	check_near(workshop.coins, 70.0, 0.0, "nothing takes Coins away but spending")


func test_groups_open_in_the_towers_order() -> void:
	var workshop := Workshop.new()
	workshop.coins = 1e6
	check(workshop.next_group("attack") == "range", "Range is Attack's next group")
	check(not workshop.open_group("multishot"), "Multishot waits for Range")
	check(workshop.open_group("range"), "Range opens")
	check_near(workshop.coins, 1e6 - 50.0, 0.0, "for 50 Coins")
	check(workshop.next_group("attack") == "multishot" and workshop.open_group("multishot"), "then Multishot, for 400")
	check(workshop.next_group("attack") == "rapid_fire" and not workshop.can_open("rapid_fire"), "Rapid Fire isn't built yet, so it can't be opened")
	check(workshop.open_group("defense") and workshop.open_group("thorns"), "Defense, then Thorns")
	check(workshop.open_group("cash") and workshop.open_group("coins"), "Cash, then Coins")
	check(workshop.buy("thorns") and workshop.buy("cash_bonus"), "their rows can then be bought")


func test_a_run_starts_from_the_workshop() -> void:
	var workshop := Workshop.new()
	workshop.coins = 1e6
	workshop.open_group("defense")
	for _i in range(5):
		workshop.buy("damage")
	var sim := BattleSim.new(1, workshop.levels, workshop.open_groups)
	check_near(sim.stat("damage"), TowerData.value("damage", 5), 0.0, "Damage starts at the Workshop's level")
	check(sim.is_open("defense_absolute") and not sim.is_open("thorns"), "the run sells what the Workshop opened")
	sim.cash = 1e6
	check(sim.price("damage") == 10.0, "the run's own first Damage level still costs $10")
	check(sim.buy("defense_absolute"), "and Defense Absolute can be bought in the run")
	workshop.levels["damage"] = 9
	check_near(sim.stat("damage"), TowerData.value("damage", 5), 0.0, "a run keeps the levels it started with")


func test_the_save_round_trips() -> void:
	_clear_test_saves()
	var workshop := Workshop.new()
	workshop.coins = 40.0
	workshop.open_group("cash")
	workshop.coins = 123456789.123456
	workshop.levels = {"damage": 7, "health": 3}
	workshop.finish_run(12)
	workshop.finish_run(9)
	check(Save.save_workshop(workshop, TEST_SAVE), "saved")
	check(not FileAccess.file_exists(TEST_SAVE + ".tmp"), "no half-written file left behind")
	var loaded := Save.load_workshop(TEST_SAVE)
	check(loaded.coins == 123456789.123456, "Coins kept to the last digit: %.6f" % loaded.coins)
	check(loaded.levels == {"damage": 7, "health": 3}, "levels kept: %s" % [loaded.levels])
	check("cash" in loaded.open_groups and "attack_start" in loaded.open_groups, "groups kept")
	check(loaded.best_wave == 12 and loaded.runs == 2, "best wave and runs kept")
	_clear_test_saves()


func test_no_save_starts_fresh() -> void:
	_clear_test_saves()
	var loaded := Save.load_workshop(TEST_SAVE)
	check(loaded.coins == 0.0 and loaded.runs == 0, "a fresh Workshop")
	check(not FileAccess.file_exists(TEST_SAVE), "and loading writes nothing")


func test_an_unreadable_save_is_kept_aside_never_written_over() -> void:
	for text in ["{not json", JSON.stringify({"version": 2, "workshop": {"coins": 5}}), JSON.stringify([1, 2])]:
		_clear_test_saves()
		var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
		file.store_string(text)
		file.close()
		var loaded := Save.load_workshop(TEST_SAVE)
		check(loaded.coins == 0.0, "starts fresh from %s" % text)
		check(not FileAccess.file_exists(TEST_SAVE), "the unreadable file is moved away")
		var kept := _test_save_copies()
		check(kept.size() == 1 and FileAccess.get_file_as_string("user://" + kept[0]) == text, "and kept whole beside it: %s" % [kept])
	_clear_test_saves()


func test_a_damaged_save_keeps_what_makes_sense() -> void:
	_clear_test_saves()
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "workshop": {
		"coins": -40, "levels": {"damage": 1e12, "health": "lots", "retired_row": 4, "range": 2},
		"open_groups": ["range", "made_up", 7], "best_wave": -3, "runs": 2.0}}))
	file.close()
	var loaded := Save.load_workshop(TEST_SAVE)
	check(loaded.coins == 0.0, "negative Coins read as none")
	check(loaded.level("damage") == TowerData.max_level("damage"), "a level past the row's end stops at its last")
	check(loaded.level("health") == 0 and not loaded.levels.has("retired_row"), "nonsense and unknown rows are dropped")
	check(loaded.level("range") == 2 and loaded.is_group_open("range"), "good data kept")
	check(not loaded.is_group_open("made_up"), "unknown groups dropped")
	check(loaded.best_wave == 0 and loaded.runs == 2, "counts can't go negative")
	_clear_test_saves()


func test_defense_comes_off_every_hit() -> void:
	var sim := BattleSim.new(1, {"defense_percent": 20, "defense_absolute": 10})
	var share := TowerData.value("defense_percent", 20)
	var flat := TowerData.value("defense_absolute", 10)
	check_near(sim.landed_damage(100.0), 100.0 * (1.0 - share) - flat, 0.0001, "Defense %, then Defense Absolute")
	check_near(sim.landed_damage(flat * 0.5), 0.0, 0.0, "a hit can come to nothing")


func test_thorns_hurt_what_hits_the_tower() -> void:
	var sim := _quiet_sim()
	sim.levels = {"thorns": 50, "health": 100}
	sim.health = sim.max_health()
	var share := TowerData.value("thorns", 50)
	var enemy := _place(sim, "tank", Guesses.CONTACT_DISTANCE_M)
	var boss := _place(sim, "boss", Guesses.CONTACT_DISTANCE_M)
	sim.step()
	check_near(enemy.max_health - enemy.health, enemy.max_health * share, 0.0001, "a share of its own maximum health")
	check_near(boss.max_health - boss.health, boss.max_health * share * 0.5, 0.0001, "half on a boss")
	var weak := _place(sim, "basic", Guesses.CONTACT_DISTANCE_M)
	weak.health = 0.01
	var kills_before := sim.kills
	sim.step()
	check(sim.kills == kills_before + 1 and not sim.enemies.has(weak), "and Thorns can kill, and pays")


func test_multishot_fires_at_more_enemies() -> void:
	var sim := _quiet_sim()
	sim.levels = {"multishot_chance": TowerData.max_level("multishot_chance"), "multishot_targets": 1}
	var targets := int(sim.stat("multishot_targets"))
	for distance in [10.0, 12.0, 14.0, 16.0, 18.0]:
		var enemy := _place(sim, "basic", distance)
		enemy.max_health = 1e9
		enemy.health = 1e9
	var volleys: Array[int] = []
	var nearest_first := true
	for _i in range(roundi(30.0 / BattleSim.TICK)):
		sim.step()
		# A shot fired this tick still has the tower as its last position.
		var fired := sim.shots.filter(func(shot): return shot.last_position == Vector2.ZERO)
		if fired.is_empty():
			continue
		volleys.append(fired.size())
		var aimed := fired.map(func(shot): return shot.target.distance)
		aimed.sort()
		nearest_first = nearest_first and aimed == [10.0, 12.0, 14.0, 16.0, 18.0].slice(0, fired.size())
	var multi := volleys.filter(func(size): return size == targets).size()
	check(volleys.all(func(size): return size == 1 or size == targets), "a volley is one shot or %d: %s" % [targets, volleys])
	check(nearest_first, "at the nearest enemies")
	var share := float(multi) / float(volleys.size())
	check(share > 0.3 and share < 0.7, "about %.1f%% of volleys are multishots: %.2f" % [sim.stat("multishot_chance") * 100.0, share])


func test_damage_per_meter_lifts_far_strikes() -> void:
	var sim := _quiet_sim()
	sim.levels = {"damage_per_meter": 50}
	sim.record_events = true
	var enemy := _place(sim, "basic", 25.0)
	enemy.max_health = 1e9
	enemy.health = 1e9
	for _i in range(60):
		sim.step()
	var strikes := sim.events.filter(func(event): return event.type == "enemy_hit" and not event.critical)
	check(not strikes.is_empty(), "the tower struck")
	var want := sim.stat("damage") * (1.0 + sim.stat("damage_per_meter") * 25.0)
	check_near(strikes[0].damage, want, 0.0001, "Damage times (1 + Damage / Meter × 25 m)")


func test_cash_and_coin_rows_pay() -> void:
	var sim := BattleSim.new(1, {"cash_bonus": 50, "cash_per_wave": 3, "coins_per_kill": 50, "coins_per_wave": 4}, ["attack_start", "defense_start", "cash", "coins"])
	sim._schedule.clear()
	var tank := _place(sim, "tank", 10.0)
	tank.health = 0.01
	for _i in range(60):
		sim.step()
	check_near(sim.cash, 5.0 * sim.stat("cash_bonus"), 0.0001, "Cash Bonus multiplies a kill's Cash")
	check_near(sim.coins, 4.0 * sim.stat("coins_per_kill"), 0.0001, "Coins / Kill Bonus multiplies a kill's Coins")
	var cash_before := sim.cash
	var coins_before := sim.coins
	sim.wave_clock = TowerData.wave_seconds() - BattleSim.TICK * 0.5
	sim.step()
	check_near(sim.cash - cash_before, sim.stat("cash_per_wave") * sim.stat("cash_bonus"), 0.0001, "Cash / Wave, times Cash Bonus, as a wave ends")
	check_near(sim.coins - coins_before, sim.stat("coins_per_wave"), 0.0001, "Coins / Wave as a wave ends")


func test_coins_per_wave_pays_nothing_until_opened() -> void:
	var sim := _quiet_sim()
	sim.wave_clock = TowerData.wave_seconds() - BattleSim.TICK * 0.5
	sim.step()
	check(sim.wave == 2 and sim.coins == 0.0, "a closed Coins / Wave row pays nothing")


func test_ending_a_run() -> void:
	var sim := _quiet_sim()
	sim.cash = 50.0
	sim.end_run()
	check(not sim.alive and sim.killed_by == "ended", "the run ends")
	check(not sim.buy("damage"), "and nothing more can be bought")


func test_the_battle_banks_coins_into_the_workshop() -> void:
	var screen = BattleScreen.new()
	screen.workshop = Workshop.new()
	root.add_child(screen)
	screen.set_process(false)
	screen.sim.coins = 12.0
	screen._bank_coins()
	screen._bank_coins()
	check_near(screen.workshop.coins, 12.0, 0.0, "a run's Coins go into the Workshop once")
	screen.sim.coins = 20.0
	screen._bank_coins()
	check_near(screen.workshop.coins, 20.0, 0.0, "and keep coming as they're earned")
	screen.sim.end_run()
	screen._process(0.0)
	screen._process(0.0)
	check(screen.workshop.runs == 1 and screen._over.visible, "an ended run is counted once and shows its summary")
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


func _test_save_copies() -> Array[String]:
	var found: Array[String] = []
	for name in DirAccess.get_files_at("user://"):
		if name.begins_with("test_tower_save"):
			found.append(name)
	return found


func _clear_test_saves() -> void:
	for name in _test_save_copies():
		DirAccess.remove_absolute("user://" + name)
