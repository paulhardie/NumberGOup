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
const WorkshopScreen = preload("res://src/ui/workshop_screen.gd")
const Save = preload("res://src/tower/save.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")
const HomeScreen = preload("res://src/ui/home_screen.gd")
const Main = preload("res://src/main.gd")

const TEST_SAVE := "user://test_tower_save.json"
const TEST_LOG := "user://test_activity.jsonl"
const TEST_REPORTS := "user://test_reports"

var _failures: Array[String] = []
var _checks := 0


func _init() -> void:
	# Once the tree is running, so screens added to it set themselves up.
	_run.call_deferred()


func _run() -> void:
	for method in get_method_list():
		if String(method.name).begins_with("test_"):
			# Awaited, so a test that waits a frame finishes before the next starts.
			await call(method.name)
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
	check_near(sim.cash, 0.0, 0.0, "a run starts with no Cash, as a new Tower account's does")


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
	check_near(sim.coins, 4.0, 0.0, "and 4 Coins, whatever its wave (D074)")


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
## nothing, dies at once (the owner, 25 September). With the owner's 26
## September enemy count (about 11 in wave 1) that is waves 2 to 5, within
## about two and a half minutes; it was waves 2 and 3 at 20 enemies a wave.
func test_a_fresh_tower_that_buys_nothing_falls_in_the_first_waves() -> void:
	for seed_value in range(1, 6):
		var sim := BattleSim.new(seed_value)
		sim.run_until_dead(600.0)
		check(not sim.alive and sim.wave <= 5 and sim.time < 180.0, "seed %d fell on wave %d at %.0f s" % [seed_value, sim.wave, sim.time])


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
	screen.sim.health = screen.sim.max_health() * 1.5
	screen._refresh()
	check(screen._health_text.text.begins_with(Palette.number(roundf(screen.sim.health))), "overhealed health reads above the most: %s" % screen._health_text.text)
	check(screen._health_bar.value == screen._health_bar.max_value, "and the bar is full")
	screen._upgrades.show_tab("utility")
	check(screen._upgrades._cards.is_empty() and screen._upgrades._empty.visible, "Utility says its rows open in the Workshop")
	screen.free()


func test_the_multiplier_buys_several_levels_a_press() -> void:
	var screen = BattleScreen.new()
	root.add_child(screen)
	screen.sim.cash = 1e6
	var panel = screen._upgrades
	panel._amount_button.pressed.emit()
	check(panel._amount_button.text == "Buy ×5", "one press of the multiplier makes it ×5")
	panel.refresh()
	check(panel._cards["damage"].price.text.begins_with("+5 $"), "and a card quotes five levels: %s" % panel._cards["damage"].price.text)
	panel._cards["damage"].button.pressed.emit()
	check(screen.sim.level("damage") == 5, "pressing it buys five")
	panel._amount_button.pressed.emit()
	panel._amount_button.pressed.emit()
	check(panel._amount_button.text == "Buy Max", "×10, then Max")
	screen.sim.cash = 0.0
	panel.refresh()
	check(panel._cards["damage"].price.text == "$" + Palette.number(screen.sim.price("damage")), "Max it can't afford quotes the next level: %s" % panel._cards["damage"].price.text)
	panel._amount_button.pressed.emit()
	check(panel._amount_button.text == "Buy ×1", "and back round to ×1")
	screen.free()


func test_the_workshop_shows_only_each_tabs_next_group() -> void:
	var workshop := Workshop.new()
	workshop.coins = 60.0
	var shop = WorkshopScreen.new()
	shop.workshop = workshop
	root.add_child(shop)
	var unlocks := _unlock_cards(shop)
	check(unlocks.size() == 1, "one Unlock card on the Attack tab: %d" % unlocks.size())
	check(not unlocks[0].disabled, "Range's, which 60 Coins can open")
	unlocks[0].pressed.emit()
	check(workshop.is_group_open("range") and workshop.coins == 10.0, "pressing it opens Range for 50")
	unlocks = _unlock_cards(shop)
	check(unlocks.size() == 1 and unlocks[0].disabled, "then Multishot's card shows, too dear for now")
	workshop.coins = 1e15
	for group in ["multishot", "rapid_fire", "bounce_shot", "super_crit", "rend_armor"]:
		workshop.open_group(group)
	shop.show_tab("attack")
	check(_unlock_cards(shop).is_empty(), "with every Attack group open there is no Unlock card")
	shop.free()


## The Workshop screen's Unlock cards: its list's buttons outside the row grid.
func _unlock_cards(shop) -> Array[Button]:
	var found: Array[Button] = []
	for child in shop._list.get_children():
		if child is Button and not child.is_queued_for_deletion():
			found.append(child)
	return found


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
	check(workshop.open_group("rapid_fire") and workshop.open_group("bounce_shot"), "then Rapid Fire and Bounce Shot")
	check(workshop.next_group("attack") == "super_crit" and not workshop.can_open("super_crit"), "Super Crit's 100M Coins are more than there are")
	check(workshop.open_group("defense") and workshop.open_group("thorns"), "Defense, then Thorns")
	check(workshop.open_group("cash") and workshop.open_group("coins"), "Cash, then Coins")
	check(workshop.buy("thorns") and workshop.buy("cash_bonus"), "their rows can then be bought")
	workshop.coins = 1e12
	check(workshop.open_group("super_crit") and workshop.open_group("rend_armor"), "then Super Crit, then Rend Armor")
	check(workshop.next_group("attack") == "", "and Attack has nothing left to open")


func test_every_group_opens_and_its_rows_can_be_bought() -> void:
	var workshop := Workshop.new()
	workshop.coins = 1e15
	for tab in ["attack", "defense", "utility"]:
		while workshop.next_group(tab) != "":
			var group := workshop.next_group(tab)
			check(workshop.open_group(group), "%s opens" % group)
	check(workshop.open_groups.size() == TowerData.groups().size(), "every group is open")
	for id in TowerData.rows():
		check(workshop.can_buy(id), "%s can be bought once its group is open" % id)
	var sim := BattleSim.new(1, workshop.levels, workshop.open_groups)
	sim.cash = 1e9
	for id in TowerData.rows():
		check(sim.can_buy(id), "%s can be bought in a run" % id)


func test_multi_buy_in_the_workshop() -> void:
	var workshop := Workshop.new()
	var prices: Array = TowerData.upgrade("damage")["coin_prices"]
	var five := 0.0
	for index in range(5):
		five += float(prices[index])
	workshop.coins = five
	var buying := workshop.plan("damage", 5)
	check(int(buying.levels) == 5 and is_equal_approx(float(buying.cost), five), "×5 quotes five levels, priced one at a time: %s" % [buying])
	check(not workshop.can_buy("damage", 10) and not workshop.buy("damage", 10), "×10 it can't afford buys nothing")
	check(workshop.level("damage") == 0 and workshop.coins == five, "and changes nothing")
	check(workshop.buy("damage", 5) and workshop.level("damage") == 5, "×5 buys five levels")
	check_near(workshop.coins, 0.0, 0.0001, "for exactly what it quoted")
	workshop.coins = 1000.0
	check(workshop.buy("damage", 0), "Max buys")
	check(workshop.coins < workshop.price("damage"), "as many levels as the Coins cover: %d, %s left" % [workshop.level("damage"), workshop.coins])
	var top := TowerData.max_level("critical_chance")
	workshop.levels["critical_chance"] = top - 3
	workshop.coins = 1e12
	check(int(workshop.plan("critical_chance", 10).levels) == 3, "×10 near the top quotes only the levels left")
	check(workshop.buy("critical_chance", 0) and workshop.level("critical_chance") == top, "Max stops at the last level")
	check(not workshop.can_buy("critical_chance", 1) and not workshop.can_buy("critical_chance", 0), "and nothing more can be bought")


func test_multi_buy_in_a_run() -> void:
	var sim := _quiet_sim()
	var prices: Array = TowerData.upgrade("damage")["cash_prices"]
	var ten := 0.0
	for index in range(10):
		ten += float(prices[index])
	sim.cash = ten
	check(sim.buy("damage", 10) and sim.level("damage") == 10, "×10 buys ten levels")
	check_near(sim.cash, 0.0, 0.0001, "at the run's prices, summed")
	check(sim.price("damage") == float(prices[10]), "and the run's next price is the eleventh")
	sim.cash = 500.0
	var health_before := sim.health
	var max_before := sim.max_health()
	check(sim.buy("health", 0), "Max buys Health")
	check(sim.cash < sim.price("health"), "as much as the Cash covers")
	check_near(sim.health - health_before, sim.max_health() - max_before, 0.0001, "and heals by the whole gain")
	sim.levels["attack_speed"] = TowerData.max_level("attack_speed") - 2
	sim.cash = 1e9
	check(sim.buy("attack_speed", 5) and sim.at_max("attack_speed"), "×5 two levels from the top buys the two")
	sim.end_run()
	check(not sim.buy("damage", 0), "a fallen tower buys nothing, Max or not")


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
	sim.cash = 0.0
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


func test_rapid_fire_fires_four_times_as_fast() -> void:
	var sim := _quiet_sim()
	var enemy := _place(sim, "basic", 10.0)
	enemy.max_health = 1e9
	enemy.health = 1e9
	sim.rapid_fire_left = 100.0
	var volleys := 0
	for _i in range(roundi(10.0 / BattleSim.TICK)):
		sim.step()
		volleys += sim.shots.filter(func(shot): return shot.last_position == Vector2.ZERO).size()
	check(volleys >= 39 and volleys <= 41, "four shots a second at Attack Speed 1: %d in 10 s" % volleys)


func test_rapid_fire_starts_by_its_chance_for_its_duration() -> void:
	var sim := _quiet_sim()
	sim.levels = {"rapid_fire_chance": TowerData.max_level("rapid_fire_chance"), "rapid_fire_duration": 10}
	var enemy := _place(sim, "basic", 10.0)
	enemy.max_health = 1e9
	enemy.health = 1e9
	var started := false
	for _i in range(roundi(20.0 / BattleSim.TICK)):
		sim.step()
		if sim.rapid_fire_left > 0.0:
			started = true
			check(sim.rapid_fire_left <= sim.stat("rapid_fire_duration"), "it lasts at most its duration")
			break
	check(started, "a 34% chance starts it within 20 shots")


func test_bounce_shot_goes_on_to_the_nearest_enemy_in_its_range() -> void:
	var sim := _quiet_sim()
	sim.levels = {"bounce_shot_chance": TowerData.max_level("bounce_shot_chance")}
	var first := _place(sim, "basic", 10.0)
	var near := _place(sim, "basic", 12.0)
	var far := _place(sim, "basic", 10.0)
	far.angle = PI
	for enemy in [first, near, far]:
		enemy.max_health = 1e9
		enemy.health = 1e9
	for _i in range(roundi(30.0 / BattleSim.TICK)):
		sim.step()
	check(first.health < first.max_health, "the tower shoots the first")
	check(near.health < near.max_health, "shots bounce on to the enemy 2 m from it")
	check(far.health == far.max_health, "but not to one 20 m away, past Bounce Shot Range (%s m)" % sim.stat("bounce_shot_range"))
	var per_shot := sim.stat("damage")
	var bounced := roundi((near.max_health - near.health) / per_shot)
	var shot_at_first := roundi((first.max_health - first.health) / per_shot)
	check(bounced > 0 and bounced < shot_at_first, "some shots bounce, not all: %d of %d" % [bounced, shot_at_first])


func test_lifesteal_heals_a_share_of_what_strikes_take_off() -> void:
	var sim := _quiet_sim()
	sim.levels = {"lifesteal": TowerData.max_level("lifesteal"), "damage": 100, "health": 100}
	sim.record_events = true
	sim.health = 1.0
	var enemy := _place(sim, "basic", 10.0)
	enemy.max_health = 1e9
	enemy.health = 1e9
	while sim.events.filter(func(event): return event.type == "enemy_hit").is_empty():
		sim.step()
	var dealt: float = sim.events.filter(func(event): return event.type == "enemy_hit")[0].damage
	var regen := sim.stat("health_regen") * sim.time
	check_near(sim.health, 1.0 + regen + dealt * sim.stat("lifesteal"), 0.001, "healed %.2f%% of %s" % [sim.stat("lifesteal") * 100.0, dealt])


func test_knockback_pushes_by_force_over_mass() -> void:
	for kind in ["basic", "tank"]:
		var sim := _quiet_sim()
		sim.levels = {"knockback_chance": TowerData.max_level("knockback_chance"), "knockback_force": 10}
		var enemy := _place(sim, kind, 20.0)
		enemy.max_health = 1e9
		enemy.health = 1e9
		var pushed := 0.0
		for _i in range(roundi(10.0 / BattleSim.TICK)):
			sim.step()
			if enemy.distance > 20.0:
				pushed = enemy.distance - 20.0
				break
		var want := sim.stat("knockback_force") * Guesses.KNOCKBACK_METRES_PER_FORCE / TowerData.mass_ratio(kind)
		check_near(pushed, want, 0.0001, "a %s goes %.2f m back" % [kind, want])


func test_knockback_never_pushes_past_the_spawn() -> void:
	var sim := _quiet_sim()
	sim.levels = {"knockback_chance": TowerData.max_level("knockback_chance"), "knockback_force": TowerData.max_level("knockback_force"), "range": TowerData.max_level("range")}
	var enemy := _place(sim, "basic", Guesses.SPAWN_DISTANCE_M - 1.0)
	enemy.max_health = 1e9
	enemy.health = 1e9
	sim.levels["range"] = TowerData.max_level("range")
	enemy.distance = sim.stat("range")
	for _i in range(roundi(30.0 / BattleSim.TICK)):
		sim.step()
		check(enemy.distance <= Guesses.SPAWN_DISTANCE_M, "at most %s m out" % Guesses.SPAWN_DISTANCE_M)


func test_interest_pays_on_cash_held_up_to_its_cap() -> void:
	var sim := BattleSim.new(1, {"interest": 10}, ["attack_start", "defense_start", "cash", "interest"])
	sim._schedule.clear()
	sim.cash = 100.0
	sim.wave_clock = TowerData.wave_seconds() - BattleSim.TICK * 0.5
	sim.step()
	check_near(sim.cash, 100.0 * (1.0 + sim.stat("interest")), 0.0001, "%.2f%% of the Cash held" % (sim.stat("interest") * 100.0))
	sim.cash = 1e6
	sim.wave_clock = TowerData.wave_seconds() - BattleSim.TICK * 0.5
	sim.step()
	check_near(sim.cash, 1e6 + 50.0, 0.0001, "but no more than $50 a wave")


func test_free_upgrades_raise_open_rows_of_their_category() -> void:
	var sim := BattleSim.new(1, {"free_attack_upgrade": TowerData.max_level("free_attack_upgrade"), "free_utility_upgrade": TowerData.max_level("free_utility_upgrade")},
		["attack_start", "defense_start", "cash"])
	sim._schedule.clear()
	sim.record_events = true
	for _i in range(40):
		sim.wave_clock = TowerData.wave_seconds() - BattleSim.TICK * 0.5
		sim.step()
	var free := sim.events.filter(func(event): return event.type == "free_upgrade")
	var raised := 0
	for id in sim.run_levels:
		raised += int(sim.run_levels[id])
		check(TowerData.category(id) in ["attack", "utility"] and sim.is_open(id), "%s is an open Attack or Utility row" % id)
	check(free.size() > 20 and free.size() < 60, "about half of 80 chances: %d" % free.size())
	check(raised == free.size(), "each free upgrade is one level: %d and %d" % [raised, free.size()])
	check(sim.cash >= 0.0, "and costs nothing: $%s" % sim.cash)


func test_orbs_kill_walking_enemies_but_not_bosses() -> void:
	var sim := _quiet_sim()
	sim.levels = {"orbs": 4}
	var orb: float = sim.orb_angles(sim.time)[0]
	var walker := _place(sim, "basic", sim.orb_radius())
	walker.angle = orb + 0.05
	walker.stop_at = Guesses.CONTACT_DISTANCE_M
	var boss := _place(sim, "boss", sim.orb_radius())
	boss.angle = orb + 0.05
	boss.stop_at = Guesses.CONTACT_DISTANCE_M
	var kills := sim.kills
	sim.step()
	check(not sim.enemies.has(walker) and sim.kills == kills + 1, "an orb kills the enemy it sweeps past, and it pays")
	check(sim.enemies.has(boss) and boss.health == boss.max_health, "but never a boss")
	check(sim.orb_angles().size() == 4, "four orbs, spaced evenly")


func test_orbs_circle_on_the_range_edge_a_turn_a_second() -> void:
	var sim := _quiet_sim()
	sim.levels = {"orbs": 1}
	check_near(sim.orb_radius(), sim.stat("range"), 0.0, "on the edge of Range")
	check_near(sim.orb_turns_per_second(), 1.0, 0.0001, "a full turn a second at Orb Speed's first level")
	sim.levels["range"] = 20
	check_near(sim.orb_radius(), sim.stat("range"), 0.0, "and out with more Range")
	sim.levels["orb_speed"] = 10
	check(sim.orb_turns_per_second() > 1.0, "faster with Orb Speed")


func test_one_orb_sweeps_a_ranged_enemy_off_the_range_edge_within_a_second() -> void:
	var sim := _quiet_sim()
	sim.levels = {"orbs": 1}
	var ranged := _place(sim, "ranged", sim.stat("range"))
	ranged.angle = 2.0
	ranged.max_health = 1e9
	ranged.health = 1e9
	var steps := 0
	while sim.enemies.has(ranged) and steps < roundi(1.0 / BattleSim.TICK) + 1:
		sim.step()
		steps += 1
	check(not sim.enemies.has(ranged), "a turn a second reaches it, however tough it is")


func test_ranged_enemies_stop_on_the_range_edge() -> void:
	var sim := _quiet_sim()
	var ranged := _place(sim, "ranged", 60.0)
	ranged.speed = 20.0
	ranged.stop_at = 0.0
	ranged.max_health = 1e9
	ranged.health = 1e9
	sim.step()
	check_near(ranged.stop_at, sim.stat("range"), 0.0, "it will stop at the tower's Range")
	sim.levels["range"] = 20
	sim.step()
	check_near(ranged.stop_at, sim.stat("range"), 0.0, "and further out once Range grows while it walks")
	for _i in range(90):
		sim.step()
	check_near(ranged.distance, sim.stat("range"), 0.0001, "then stands exactly on the line")


func test_an_enemy_in_place_hits_once_a_second() -> void:
	var sim := _quiet_sim()
	sim.levels = {"health": 200}
	sim.health = sim.max_health()
	var enemy := _place(sim, "basic", Guesses.CONTACT_DISTANCE_M)
	enemy.max_health = 1e9
	enemy.health = 1e9
	for _i in range(roundi(10.0 / BattleSim.TICK)):
		sim.step()
	check(enemy.hits == 10 or enemy.hits == 11, "about ten hits in ten seconds: %d" % enemy.hits)


func test_super_crit_multiplies_a_critical_again() -> void:
	var levels := {"critical_chance": TowerData.max_level("critical_chance"), "super_crit_chance": TowerData.max_level("super_crit_chance"), "super_crit_mult": 10}
	var sim := _quiet_sim(levels, BattleSim.START_GROUPS + ["super_crit"])
	sim.record_events = true
	var enemy := _place(sim, "basic", 10.0)
	enemy.max_health = 1e12
	enemy.health = 1e12
	for _i in range(roundi(400.0 / BattleSim.TICK)):
		sim.step()
	var crit := sim.stat("damage") * sim.stat("critical_factor")
	var strikes := sim.events.filter(func(event): return event.type == "enemy_hit" and event.critical)
	var supers := strikes.filter(func(event): return is_equal_approx(event.damage, crit * sim.stat("super_crit_mult")))
	for event in strikes:
		check(is_equal_approx(event.damage, crit) or is_equal_approx(event.damage, crit * sim.stat("super_crit_mult")), "a crit deals Critical Factor, or times Super Crit Mult too: %s" % event.damage)
	var share := float(supers.size()) / float(strikes.size())
	check(share > 0.12 and share < 0.28, "about 20%% of crits are super: %.2f of %d" % [share, strikes.size()])


func test_death_defy_ignores_a_hit_that_would_end_the_run_by_its_chance() -> void:
	var defied := 0
	var runs := 300
	for seed_value in range(runs):
		var sim := BattleSim.new(seed_value, {"death_defy": TowerData.max_level("death_defy")}, BattleSim.START_GROUPS + ["death_defy"])
		sim._schedule.clear()
		sim.wave_clock = -1e9
		var enemy := _place(sim, "basic", Guesses.CONTACT_DISTANCE_M)
		enemy.attack = 1e9
		sim.step()
		if sim.alive:
			defied += 1
			check(is_equal_approx(sim.health, sim.max_health()), "a defied hit takes nothing")
	var share := float(defied) / float(runs)
	check(share > 0.22 and share < 0.38, "about 30%% of deadly hits are defied: %.2f" % share)
	var sim := _quiet_sim({"death_defy": TowerData.max_level("death_defy")}, BattleSim.START_GROUPS + ["death_defy"])
	var enemy := _place(sim, "basic", Guesses.CONTACT_DISTANCE_M)
	sim.health = 1e6
	sim.step()
	check(sim.health < 1e6, "a hit that wouldn't end the run is never defied")


func test_rend_armor_makes_later_strikes_hit_harder_up_to_its_cap() -> void:
	var levels := {"rend_armor_chance": TowerData.max_level("rend_armor_chance"), "rend_armor_mult": TowerData.max_level("rend_armor_mult")}
	var closed := _quiet_sim(levels)
	var sim := _quiet_sim(levels, BattleSim.START_GROUPS + ["rend_armor"])
	for each in [closed, sim]:
		each.record_events = true
		var enemy := _place(each, "basic", 10.0)
		enemy.max_health = 1e12
		enemy.health = 1e12
		for _i in range(roundi(120.0 / BattleSim.TICK)):
			each.step()
	check(closed.enemies[0].rend == 0.0, "no rending before Rend Armor opens")
	var enemy: BattleSim.Enemy = sim.enemies[0]
	check(enemy.rend > 0.0 and enemy.rend <= BattleSim.REND_CAP, "rends stack on the enemy: %s" % enemy.rend)
	var plain := sim.events.filter(func(event): return event.type == "enemy_hit" and not event.critical)
	var first: float = plain[0].damage
	var last: float = plain[-1].damage
	check(last > first and last <= first * (1.0 + BattleSim.REND_CAP) + 0.0001, "later strikes hit harder, by at most 800%% more: %s then %s" % [first, last])
	enemy.rend = BattleSim.REND_CAP - 0.01
	for _i in range(roundi(30.0 / BattleSim.TICK)):
		sim.step()
	check(enemy.rend == BattleSim.REND_CAP, "rending stops at 800%% more: %s" % enemy.rend)


func test_shockwave_pushes_enemies_in_range_back_but_not_bosses() -> void:
	var closed := _quiet_sim()
	closed.record_events = true
	for _i in range(roundi(25.0 / BattleSim.TICK)):
		closed.step()
	check(closed.events.filter(func(event): return event.type == "shockwave").is_empty(), "no shockwaves before Shockwave opens")
	var sim := _quiet_sim({}, BattleSim.START_GROUPS + ["shockwave"])
	sim.record_events = true
	var near := _place(sim, "basic", 20.0)
	var far := _place(sim, "basic", 50.0)
	var boss := _place(sim, "boss", 20.0)
	for enemy in [near, far, boss]:
		enemy.max_health = 1e12
		enemy.health = 1e12
	while sim.events.filter(func(event): return event.type == "shockwave").is_empty():
		sim.step()
	check_near(sim.time, sim.stat("shockwave_frequency"), BattleSim.TICK * 1.5, "the first shockwave comes after Shockwave Frequency seconds")
	check_near(near.distance, 20.0 + sim.stat("shockwave_size"), 0.0001, "an enemy in range is pushed back by Shockwave Size")
	check_near(far.distance, 50.0, 0.0, "one out of range isn't")
	check_near(boss.distance, 20.0, 0.0, "nor is a boss")


func test_land_mines_are_laid_in_range_and_blast_what_walks_onto_them() -> void:
	var sim := _quiet_sim({"land_mine_chance": TowerData.max_level("land_mine_chance")}, BattleSim.START_GROUPS + ["land_mines"])
	var target := _place(sim, "basic", 25.0)
	target.angle = PI
	target.max_health = 1e12
	target.health = 1e12
	for _i in range(roundi(60.0 / BattleSim.TICK)):
		sim.step()
	check(not sim.mines.is_empty(), "shots lay mines: %d" % sim.mines.size())
	for mine in sim.mines:
		check(mine.length() >= Guesses.CONTACT_DISTANCE_M - 0.0001 and mine.length() <= sim.stat("range") + 0.0001, "a mine lies in range: %s" % mine.length())
	sim = _quiet_sim({}, BattleSim.START_GROUPS + ["land_mines"])
	sim.record_events = true
	sim.mines = [Vector2(20.0, 0.0)]
	var walker := _place(sim, "basic", 21.0)
	var beside := _place(sim, "basic", 20.0)
	beside.angle = 0.2
	var away := _place(sim, "basic", 20.0)
	away.angle = PI
	for enemy in [walker, away]:
		enemy.max_health = 1000.0
		enemy.health = 1000.0
	beside.health = 1.0
	var kills := sim.kills
	sim.step()
	check(sim.mines.is_empty(), "a walking enemy within 2 m sets the mine off")
	check_near(walker.health, 1000.0 - sim.stat("damage") * sim.stat("land_mine_damage"), 0.0001, "the blast deals Land Mine Damage's share of Damage")
	check(not sim.enemies.has(beside) and sim.kills == kills + 1, "an enemy within Land Mine Radius it kills is paid for")
	check_near(away.health, 1000.0, 0.0, "one out of the radius is untouched")


func test_the_wall_stops_melee_enemies_until_it_falls_then_rebuilds() -> void:
	check(not _quiet_sim().wall_up(), "no wall before Wall opens")
	var sim := _quiet_sim({"health": 100}, BattleSim.START_GROUPS + ["wall"])
	sim.record_events = true
	check(sim.wall_up() and is_equal_approx(sim.wall_health, sim.max_health() * sim.stat("wall_health")), "the wall starts at Wall Health's share of Health")
	var walker := _place(sim, "basic", 12.0)
	walker.speed = 30.0
	walker.max_health = 1e12
	walker.health = 1e12
	for _i in range(30):
		sim.step()
	check_near(walker.distance, Guesses.WALL_DISTANCE_M, 0.0, "a melee enemy stops at the wall")
	check(sim.wall_health < sim.wall_max_health() and is_equal_approx(sim.health, sim.max_health()), "and hits the wall, not the tower")
	sim.wall_health = 0.01
	while sim.wall_up():
		sim.step()
	check(not sim.events.filter(func(event): return event.type == "wall_down").is_empty(), "the wall falls")
	check_near(sim.wall_rebuild_in, sim.stat("wall_rebuild"), BattleSim.TICK, "and rebuilds after Wall Rebuild seconds")
	for _i in range(15):
		sim.step()
	check(walker.distance < Guesses.WALL_DISTANCE_M, "the enemy walks on once the wall is down")
	sim.enemies.clear()
	sim.wall_rebuild_in = 0.5
	for _i in range(16):
		sim.step()
	check(sim.wall_up() and is_equal_approx(sim.wall_health, sim.wall_max_health()), "a rebuilt wall is whole")


func test_recovery_packages_heal_past_health_up_to_max_recovery() -> void:
	var closed := _quiet_sim({"package_chance": TowerData.max_level("package_chance")})
	closed.health = 1.0
	for _i in range(50):
		closed._pay_wave_end()
	check(closed.health == 1.0, "no packages before Recovery Packages opens")
	var sim := _quiet_sim({"package_chance": TowerData.max_level("package_chance")}, BattleSim.START_GROUPS + ["recovery_packages"])
	sim.record_events = true
	var drops := 0
	for _i in range(1000):
		sim.events.clear()
		sim.health = sim.max_health()
		sim._pay_wave_end()
		if not sim.events.filter(func(event): return event.type == "package").is_empty():
			drops += 1
			check_near(sim.health, sim.max_health() * (1.0 + sim.stat("recovery_amount")), 0.0001, "a package heals Recovery Amount's share of Health, past it")
	check(drops > 250 and drops < 350, "about 30%% of waves drop one: %d of 1000" % drops)
	var over := sim.health
	sim._heal(1.0)
	check(sim.health >= over, "regen and lifesteal never cut an overheal")
	sim.health = sim.max_health() * sim.stat("max_recovery")
	for _i in range(20):
		sim._pay_wave_end()
	check_near(sim.health, sim.max_health() * sim.stat("max_recovery"), 0.0001, "never past Max Recovery times Health")


func test_enemy_level_skip_holds_back_a_share_of_waves() -> void:
	var closed := _quiet_sim({"enemy_health_level_skip": 699, "enemy_attack_level_skip": 699})
	for _i in range(20):
		closed._advance_levels()
	check(closed.health_level == 21 and closed.attack_level == 21, "without it, every wave is a level up")
	var sim := _quiet_sim({"enemy_health_level_skip": 699, "enemy_attack_level_skip": 199}, BattleSim.START_GROUPS + ["enemy_level_skip"])
	for _i in range(100):
		sim._advance_levels()
	check(sim.health_level == 1 + 100 - 35, "35%% of 100 waves skip Health: level %d" % sim.health_level)
	check(sim.attack_level == 1 + 100 - 10, "10%% skip Attack: level %d" % sim.attack_level)
	sim._schedule = [{"kind": "tank", "at": 0.0}]
	sim._next_spawn = 0
	sim.wave_clock = 0.0
	sim._spawn_due()
	var tank: BattleSim.Enemy = sim.enemies[-1]
	check_near(tank.max_health, TowerData.enemy_health(sim.health_level, "tank"), 0.0001, "new enemies have the held-back health")
	check_near(tank.attack, TowerData.enemy_attack(sim.attack_level, "tank"), 0.0001, "and attack")


func test_a_run_records_its_inputs_and_waves() -> void:
	var sim := _quiet_sim()
	sim.step()
	sim.step()
	check(not sim.buy("damage") and sim.inputs.is_empty(), "a buy that fails isn't an input")
	sim.cash = 1000.0
	check(sim.buy("damage", 5), "a ×5 buy")
	check(sim.inputs == [{"tick": 2, "buy": "damage", "count": 5}], "is recorded with its tick and count: %s" % [sim.inputs])
	sim._pay_wave_end()
	check(sim.wave_log.size() == 1 and int(sim.wave_log[0].bought.damage) == 5, "a wave's end is snapshotted, with what was bought")
	sim.end_run()
	check(sim.inputs[-1] == {"tick": 2, "end": true}, "ending the run is an input too")


func test_a_recorded_run_replays_exactly() -> void:
	var workshop := Workshop.new()
	workshop.coins = 1e7
	for group in ["range", "multishot", "defense", "thorns", "cash", "coins", "free_upgrades", "rapid_fire", "lifesteal", "knockback", "orbs", "shockwave", "land_mines"]:
		workshop.open_group(group)
	workshop.levels = {"damage": 30, "health": 30, "defense_absolute": 10, "thorns": 5, "free_attack_upgrade": 20,
		"land_mine_chance": 10, "orbs": 1, "multishot_chance": 20, "knockback_chance": 10}
	var played := BattleSim.new(20260926, workshop.levels, workshop.open_groups)
	var amounts := [1, 5, 10, 0]
	var rows := ["damage", "attack_speed", "health", "defense_absolute", "health_regen", "thorns"]
	var turn := 0
	while played.alive and played.time < 900.0:
		played.step()
		# Buy something every few seconds, with every multiplier.
		if played.ticks % 97 == 0:
			played.buy(rows[turn % rows.size()], amounts[turn % amounts.size()])
			turn += 1
	if played.alive:
		played.end_run()
	var run := RunReport.build(played, {"real_seconds": 12.0})
	check(run.inputs.size() > 10, "the run made plenty of inputs: %d" % run.inputs.size())
	# Through JSON and back, as the log stores it.
	var json := JSON.new()
	check(json.parse(JSON.stringify(run, "", false, true)) == OK, "the run writes and reads as JSON")
	var again := RunReport.replay(json.data)
	check(RunReport.matches(json.data, again), "the replay ends where the run did: wave %d/%d, ticks %d/%d, kills %d/%d, coins %s/%s" % [
		again.wave, played.wave, again.ticks, played.ticks, again.kills, played.kills, again.coins, played.coins])
	check(again.wave_log.size() == played.wave_log.size() and is_equal_approx(again.cash, played.cash), "wave by wave, down to the Cash")
	var other: Dictionary = json.data.duplicate(true)
	other.seed = float(int(other.seed) + 1)
	check(not RunReport.matches(other, RunReport.replay(other)), "and another seed doesn't match")


func test_the_activity_log_appends_reads_and_exports() -> void:
	_clear_test_logs()
	check(ActivityLog.read(TEST_LOG).is_empty(), "no log, no entries")
	check(ActivityLog.append({"kind": "workshop_buy", "id": "damage", "cost": 30.0}, TEST_LOG), "an entry is written")
	var sim := _quiet_sim()
	sim.end_run()
	check(ActivityLog.append(RunReport.build(sim), TEST_LOG), "and a run")
	# A crash mid-write can leave a torn last line.
	var file := FileAccess.open(TEST_LOG, FileAccess.READ_WRITE)
	file.seek_end()
	file.store_string("{\"kind\": \"ru")
	file.close()
	var entries := ActivityLog.read(TEST_LOG)
	check(entries.size() == 2 and entries[0].id == "damage" and entries[1].kind == "run", "both read back, the torn line skipped")
	check(String(entries[0].at).length() >= 19 and entries[0].has("game") and entries[0].version == ActivityLog.version(), "each is stamped with the time, the commit and the version")
	check(ActivityLog.version() == "0.9", "the game is at roadmap version 0.9: %s" % ActivityLog.version())
	var version := ActivityLog.game_version()
	check(version == "unknown" or (version.length() == 12 and version.is_valid_hex_number()), "the version is a commit or unknown: %s" % version)
	var result := ActivityLog.export_report({"coins": 5.0}, TEST_LOG, TEST_REPORTS)
	check(int(result.get("runs", 0)) == 1 and int(result.get("entries", 0)) == 2, "the export counts what it holds: %s" % [result])
	var json := JSON.new()
	check(json.parse(FileAccess.get_file_as_string(result.path)) == OK and json.data.format == ActivityLog.FORMAT, "the report reads as one JSON file")
	check(json.data.entries.size() == 2 and json.data.workshop.coins == 5.0 and json.data.game_version == "0.9", "with the log, the Workshop and the version")
	var second := ActivityLog.export_report({}, TEST_LOG, TEST_REPORTS)
	check(second.path != result.path, "a second export in the same second gets its own file")
	_clear_test_logs()


func test_screens_report_what_the_log_needs() -> void:
	var workshop := Workshop.new()
	workshop.coins = 100.0
	var shop = WorkshopScreen.new()
	shop.workshop = workshop
	root.add_child(shop)
	var seen: Array[Dictionary] = []
	shop.activity.connect(func(entry): seen.append(entry))
	shop._cards[0].button.pressed.emit()
	check(seen.size() == 1 and seen[0].kind == "workshop_buy" and seen[0].id == "damage" and seen[0].to == 1 and seen[0].cost == 30.0, "a Workshop buy is reported: %s" % [seen])
	_unlock_cards(shop)[0].pressed.emit()
	check(seen.size() == 2 and seen[1].kind == "workshop_open" and seen[1].group == "range" and seen[1].cost == 50.0, "and an unlock: %s" % [seen])
	shop.free()
	var screen = BattleScreen.new()
	root.add_child(screen)
	screen._process(0.5)
	var run: Dictionary = screen.report()
	check(run.kind == "run" and run.seed == screen.sim.run_seed and is_equal_approx(float(run.play.real_seconds), 0.5), "a battle reports its run and play time")
	check(bool(run.result.closed_mid_run), "a run still going is marked as closed mid-run")
	screen.free()
	var home = HomeScreen.new()
	home.workshop = workshop
	root.add_child(home)
	home.show_exported({"path": "user://reports/number_go_up_report-x.json", "runs": 3, "entries": 9})
	check(home._note.text.begins_with("Saved number_go_up_report-x.json (3 runs)"), "Home says where the report went: %s" % home._note.text)
	home.show_exported({})
	check(home._note.text == "Couldn't write the report.", "or that it couldn't")
	home.free()


func test_a_replay_in_slices_ends_where_one_in_one_go_does() -> void:
	var played := _played_run(7, 300.0)
	var run := _through_json(RunReport.build(played))
	var sliced := RunReport.Replay.new(run)
	var slices := 0
	while not sliced.advance(37):
		slices += 1
	check(slices > 20, "it took many slices: %d" % slices)
	check(RunReport.matches(run, sliced.sim), "and ends where the run did")
	check(sliced.sim.inputs == RunReport.replay(run).inputs, "with the same inputs as a replay in one go")


func test_only_a_sound_record_is_replayable() -> void:
	var run := _through_json(RunReport.build(_played_run(3, 60.0)))
	check(RunReport.is_replayable(run), "a recorded run is")
	var broken: Array[Dictionary] = []
	for damage in ["seed", "start", "inputs", "result"]:
		var copy: Dictionary = run.duplicate(true)
		copy.erase(damage)
		broken.append(copy)
	var copy: Dictionary = run.duplicate(true)
	copy.result.ticks = -5.0
	broken.append(copy)
	copy = run.duplicate(true)
	copy.result.ticks = float(RunReport.MOST_TICKS + 1)
	broken.append(copy)
	copy = run.duplicate(true)
	copy.inputs.append({"tick": 0.0, "buy": "damage", "count": 1.0})
	broken.append(copy)
	copy = run.duplicate(true)
	copy.inputs.append({"tick": copy.result.ticks, "buy": "a_row_from_the_future", "count": 1.0})
	broken.append(copy)
	copy = run.duplicate(true)
	copy.inputs.append({"tick": copy.result.ticks + 1.0, "end": true})
	broken.append(copy)
	for damage in [["start", "groups", [5.0]], ["start", "levels", {"damage": {}}], ["result", "wave", "x"], ["result", "coins", INF],
			["result", "bought", []]]:
		copy = run.duplicate(true)
		copy[damage[0]][damage[1]] = damage[2]
		broken.append(copy)
	for extra in [{"banked": "lots"}, {"banked": -1.0}, {"banked": float(run.result.coins) + 1.0}, {"play": 7.0},
			{"play": {"real_seconds": "x"}}, {"play": {"seconds_at_speed": []}}]:
		copy = run.duplicate(true)
		copy.merge(extra, true)
		broken.append(copy)
	for each in broken:
		check(not RunReport.is_replayable(each), "a damaged record isn't: %s" % [each.keys()])
	copy = run.duplicate(true)
	copy.merge({"banked": run.result.coins, "play": {"real_seconds": 3.0, "seconds_at_speed": {"×1": 3.0}}}, true)
	check(RunReport.is_replayable(copy), "a saved run with its banked Coins and play time is")
	check(not RunReport.is_replayable("not a run") and not RunReport.is_replayable({}), "nor is something that isn't one")


func test_the_save_keeps_a_run_in_progress_with_the_workshop() -> void:
	_clear_test_saves()
	var workshop := Workshop.new()
	workshop.coins = 123.0
	var run := RunReport.build(_played_run(5, 90.0))
	run["banked"] = run.result.coins
	check(Save.save_workshop(workshop, TEST_SAVE, run), "saved with a run")
	check(is_equal_approx(Save.load_workshop(TEST_SAVE).coins, 123.0), "the Workshop loads as before")
	var loaded := Save.load_run(TEST_SAVE)
	check(RunReport.is_replayable(loaded) and is_equal_approx(float(loaded.banked), float(run.result.coins)) and int(loaded.seed) == 5, "and the run comes back whole")
	check(Save.save_workshop(workshop, TEST_SAVE), "saved again with no run")
	check(Save.load_run(TEST_SAVE).is_empty(), "and then there's none")
	# A version 1 save as the game wrote it before runs were kept.
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string('{"version": 1, "workshop": {"coins": 50.0, "levels": {"damage": 3}, "open_groups": ["attack_start", "defense_start"], "best_wave": 8, "runs": 4}}')
	file.close()
	check(Save.load_workshop(TEST_SAVE).level("damage") == 3 and Save.load_run(TEST_SAVE).is_empty(), "an older save loads, with no run")
	file = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string('{"version": 1, "workshop": {"coins": 50.0}, "run": "garbage"}')
	file.close()
	check(Save.load_run(TEST_SAVE).is_empty(), "a run that isn't one reads as none")
	check(Save.load_run("user://no_such_save.json").is_empty(), "no file, no run")
	_clear_test_saves()


func test_a_replay_must_end_in_the_same_state_not_just_the_same_totals() -> void:
	var played := _played_run(21, 200.0)
	var run := _through_json(RunReport.build(played))
	check(RunReport.matches(run, RunReport.replay(run)), "the true record matches")
	# Each stands in for a rule or price that changed after the run was saved.
	var changes := {
		"Cash held": func(copy): copy.result.cash = float(copy.result.cash) + 1.0,
		"levels bought": func(copy): copy.result.bought["damage"] = float(copy.result.bought.get("damage", 0.0)) + 1.0,
		"enemies": func(copy): copy.result.enemies = float(copy.result.enemies) + 1.0,
		"random streams": func(copy): copy.result.rng = [copy.result.rng[0], "12345"],
		"a buy it couldn't make": func(copy): copy.inputs.append({"tick": copy.result.ticks, "buy": "damage", "count": 0.0}),
	}
	for change in changes:
		var copy: Dictionary = run.duplicate(true)
		changes[change].call(copy)
		var again := RunReport.replay(copy)
		check(not RunReport.matches(copy, again), "a replay ending with different %s doesn't match" % change)


func test_a_saved_run_resumes_where_it_was_left() -> void:
	var workshop := Workshop.new()
	# Sturdy enough to live through the minute played.
	workshop.levels = {"damage": 20, "health": 60, "health_regen": 30}
	var first = BattleScreen.new()
	first.workshop = workshop
	root.add_child(first)
	first.start_run(99)
	for frame in range(1800):
		first._process(1.0 / 30.0)
		if frame % 40 == 0:
			first._upgrades._cards["attack_speed" if frame % 80 == 0 else "critical_chance"].button.pressed.emit()
	check(first.sim.alive, "the first screen's run is still going")
	var coins_banked := workshop.coins
	var saved := _through_json(first.run_state())
	check(saved.has("banked") and is_equal_approx(float(saved.banked), first._banked), "the run keeps the Coins it has banked")
	check(first.sim.inputs.size() > 1, "and some buys to replay: %d" % first.sim.inputs.size())
	var second = BattleScreen.new()
	second.workshop = workshop
	second.resume = saved
	root.add_child(second)
	check(second.sim == null and second.run_state() == saved, "while it replays, the save keeps the run as it was loaded")
	second._upgrades.show_tab("defense")
	second._process(0.1)
	var frames := 1
	while second.sim == null and frames < 200:
		second._process(0.0)
		frames += 1
	check(second.sim != null, "the run comes back")
	check(second.sim.ticks == first.sim.ticks and second.sim.wave == first.sim.wave and is_equal_approx(second.sim.cash, first.sim.cash)
		and is_equal_approx(second.sim.health, first.sim.health) and second.sim.enemies.size() == first.sim.enemies.size(), "exactly where it was left")
	second._process(0.0)
	check(is_equal_approx(workshop.coins, coins_banked), "without banking its Coins twice")
	check(is_equal_approx(second._real_seconds, first._real_seconds), "keeping its play time")
	second._process(1.0)
	check(second.sim.ticks > first.sim.ticks, "and plays on")
	check(not second.run_state().is_empty(), "saving itself as it goes")
	second.sim.end_run()
	check(second.run_state().is_empty(), "until it ends")
	first.free()
	second.free()


func test_a_run_that_cant_be_replayed_is_given_up_not_played_wrong() -> void:
	var played := _played_run(11, 120.0)
	var tampered := _through_json(RunReport.build(played))
	tampered.result.kills = float(played.kills + 1)
	var failed: Array[Dictionary] = []
	var screen = BattleScreen.new()
	screen.workshop = Workshop.new()
	screen.resume = tampered
	screen.resume_failed.connect(func(saved, reason): failed.append({"saved": saved, "reason": reason}))
	root.add_child(screen)
	for _frame in range(50):
		screen._process(0.0)
	await process_frame
	check(failed.size() == 1 and int(failed[0].saved.seed) == 11 and failed[0].reason == "changed", "a replay that ends elsewhere says so, once")
	check(screen.sim == null and screen.run_state().is_empty(), "and nothing is played or saved from it")
	screen.free()
	failed.clear()
	var damaged = BattleScreen.new()
	damaged.workshop = Workshop.new()
	damaged.resume = {"seed": "x"}
	damaged.resume_failed.connect(func(saved, reason): failed.append({"saved": saved, "reason": reason}))
	root.add_child(damaged)
	await process_frame
	check(failed.size() == 1 and failed[0].reason == "damaged" and damaged.run_state().is_empty(), "a damaged record fails straight away")
	damaged.free()


func test_the_game_opens_into_a_saved_run_and_gives_up_one_it_cant_replay() -> void:
	_clear_test_saves()
	_clear_test_logs()
	var workshop := Workshop.new()
	workshop.coins = 60.0
	var played := _played_run(31, 45.0)
	var run := RunReport.build(played)
	run["banked"] = played.coins
	Save.save_workshop(workshop, TEST_SAVE, run)
	var game = _game()
	for _frame in range(30):
		await process_frame
	check(game._screen is BattleScreen and game._screen.sim != null and game._screen.sim.ticks >= played.ticks, "the game opens straight into the saved run")
	game._save()
	check(int(Save.load_run(TEST_SAVE).result.ticks) >= played.ticks and is_equal_approx(Save.load_workshop(TEST_SAVE).coins, 60.0), "and keeps saving it, Coins unchanged")
	game.free()
	for reason in ["changed", "damaged"]:
		var bad := _through_json(run)
		if reason == "changed":
			bad.result.kills = float(played.kills + 2)
		else:
			bad.start.groups = [5.0]
		Save.save_workshop(workshop, TEST_SAVE, bad)
		game = _game()
		for _frame in range(10):
			await process_frame
		var loaded := Save.load_workshop(TEST_SAVE)
		check(game._screen is HomeScreen, "a %s run ends and the game goes Home" % reason)
		check(game._screen._note.text.begins_with("Your run at wave %d" % played.wave), "saying so: %s" % game._screen._note.text)
		check(Save.load_run(TEST_SAVE).is_empty() and loaded.runs == 1 and loaded.best_wave == played.wave and is_equal_approx(loaded.coins, 60.0),
			"the run is cleared, counted at its wave, and its Coins kept")
		var entries := ActivityLog.read(TEST_LOG)
		check(entries.size() == 1 and entries[0].resume_failed == reason, "and logged as lost: %s" % [entries.map(func(entry): return entry.get("resume_failed"))])
		game.free()
		_clear_test_logs()
	_clear_test_saves()


func test_every_run_on_a_battle_screen_is_logged() -> void:
	_clear_test_saves()
	_clear_test_logs()
	var game = _game()
	await process_frame
	game._show_battle()
	var battle = game._screen
	for seed_value in [1, 2]:
		battle.start_run(seed_value)
		battle.sim.end_run()
		battle._process(0.0)
	var entries := ActivityLog.read(TEST_LOG)
	check(entries.size() == 2 and int(entries[0].seed) == 1 and int(entries[1].seed) == 2, "a run and its Battle again are both logged: %d" % entries.size())
	check(Save.load_run(TEST_SAVE).is_empty(), "and neither stays in the save")
	game.free()
	_clear_test_logs()
	_clear_test_saves()


func test_dividers_come_on_top_of_the_towers_enemies_and_leave_them_untouched() -> void:
	var sim := BattleSim.new(8)
	var plain := BattleSim.new(8)
	plain.divider.share_first = 0.0
	plain.divider.share_full = 0.0
	check(sim.divider_share(4) == 0.0 and is_equal_approx(sim.divider_share(5), 0.03), "none before wave 5, then 3%")
	check(is_equal_approx(sim.divider_share(30), 0.06) and is_equal_approx(sim.divider_share(200), 0.06), "rising to 6% by wave 30, and holding")
	var counted := 0
	var expected := 0.0
	for at_wave in range(2, 41):
		for each in [sim, plain]:
			each.wave = at_wave
			each._schedule_wave()
		var theirs: Array = sim._schedule.filter(func(entry): return entry.kind != "divider")
		counted += sim._schedule.size() - theirs.size()
		expected += sim.divider_share(at_wave) * float(theirs.size() - (1 if TowerData.is_boss_wave(at_wave) else 0))
		check(theirs == plain._schedule, "wave %d: The Tower's enemies come exactly as without Dividers" % at_wave)
		for index in range(sim._schedule.size() - 1):
			if float(sim._schedule[index].at) > float(sim._schedule[index + 1].at):
				check(false, "wave %d: the schedule stays in time order" % at_wave)
	check(absi(counted - roundi(expected)) <= 1, "as many Dividers as their share adds up to: %d against %.1f" % [counted, expected])


func test_a_divider_halves_the_number_through_the_defences_and_is_used_up() -> void:
	var sim := _quiet_sim({"health": 400})
	sim.record_events = true
	sim.health = 100.0
	var cash := sim.cash
	var kills := sim.kills
	var divider := _place(sim, "divider", Guesses.CONTACT_DISTANCE_M)
	sim.step()
	check_near(sim.health, 50.0 + sim.stat("health_regen") * BattleSim.TICK, 0.0001, "÷2 takes half the Number")
	check(not sim.enemies.has(divider) and divider.health == 0.0, "and the Divider is used up")
	check(sim.kills == kills and sim.cash == cash and sim.dividers_landed == 1, "without paying or counting as a kill")
	check_near(float(sim.lost_to.divider), 50.0, 0.0001, "the loss is put down to Dividers")
	check(not sim.events.filter(func(event): return event.type == "divided").is_empty(), "and the screen hears of it")
	var guarded := _quiet_sim({"health": 400, "defense_percent": 40, "defense_absolute": 10})
	guarded.health = 100.0
	_place(guarded, "divider", Guesses.CONTACT_DISTANCE_M)
	guarded.step()
	var took := 100.0 + guarded.stat("health_regen") * BattleSim.TICK - guarded.health
	check_near(took, guarded.landed_damage(50.0), 0.0001, "the same defences as any hit, Defense %% then Absolute: %.2f" % took)
	var tiny := _quiet_sim()
	tiny.health = 0.01
	_place(tiny, "divider", Guesses.CONTACT_DISTANCE_M)
	tiny.step()
	check(tiny.alive and tiny.health > 0.0, "half of anything is never all of it: a Divider can't end a run")


func test_a_divider_in_flight_is_lost_to_shots_and_pays_when_killed() -> void:
	var sim := _quiet_sim()
	var divider := _place(sim, "divider", 20.0)
	check_near(divider.max_health, TowerData.enemy_health(sim.wave, "basic") * 2.0, 0.0001, "twice a basic enemy's health at first")
	sim.wave = 30
	sim.health_level = 30
	check_near(sim.enemy_health_now("divider"), TowerData.enemy_health(30, "basic") * 4.0, 0.0001, "four times by wave 30")
	sim.wave = 1
	sim.health_level = 1
	check(sim.enemy_attack_now("divider") == 0.0, "and no flat hit of its own")
	divider.health = 0.5
	var cash := sim.cash
	while sim.enemies.has(divider):
		sim.step()
	check(sim.kills == 1 and is_equal_approx(sim.cash - cash, 2.0 * sim.stat("cash_bonus")) and sim.coins == 2.0, "killed, it pays twice a basic's Cash and 2 Coins")
	var walker := _quiet_sim()
	var near := _place(walker, "divider", Guesses.CONTACT_DISTANCE_M + 0.5)
	near.speed = 30.0
	near.stop_at = Guesses.CONTACT_DISTANCE_M
	near.max_health = 1e9
	near.health = 1e9
	walker.levels = {"damage": 50}
	for _i in range(40):
		walker.step()
	check(walker.kills == 0 and walker.dividers_landed == 1, "shots still flying at a Divider that landed are lost, not paid")


func test_a_divider_breaks_on_the_wall() -> void:
	var sim := _quiet_sim({"health": 100}, BattleSim.START_GROUPS + ["wall"])
	var number := sim.health
	var wall := sim.wall_health
	_place(sim, "divider", Guesses.WALL_DISTANCE_M)
	sim.step()
	check_near(sim.wall_health, wall / 2.0, 0.0001, "the Wall loses half")
	check(sim.health >= number and sim.dividers_landed == 1, "and the Number nothing")


func test_the_number_keeps_its_peak_as_a_record() -> void:
	var sim := _quiet_sim({"health": 50})
	var start := sim.health
	check_near(sim.peak_number, start, 0.0, "a run's peak starts at its Number")
	sim.cash = 1e6
	sim.buy("health", 10)
	sim.step()
	var high := sim.peak_number
	check(high > start, "buying Health raises it")
	sim.health = 1.0
	sim.step()
	check_near(sim.peak_number, high, 0.0, "and a hit never lowers it")
	var workshop := Workshop.new()
	workshop.finish_run(5, 12.5)
	workshop.finish_run(3, 7.0)
	workshop.finish_run(4, INF)
	check(workshop.best_number == 12.5 and workshop.best_wave == 5, "the Workshop keeps the best Number")
	var again := Workshop.new()
	again.restore(workshop.to_dict())
	check(again.best_number == 12.5, "through a save")
	var older := Workshop.new()
	older.restore({"coins": 5.0, "best_wave": 4, "runs": 2})
	check(older.best_number == 0.0 and older.best_wave == 4, "and a save from before it starts at 0")
	check(TowerData.upgrade("health").title == "NUMBER" and TowerData.upgrade("health_regen").title == "NUMBER REGEN", "Health reads as Number")
	check(Guesses.COINS_BY_TYPE.ranged == 2.0, "a ranged enemy pays 2 Coins, as The Tower's list says")


func test_numbers_read_as_the_towers() -> void:
	check(Palette.number(2.35) == "2.35", "two decimals while small")
	check(Palette.number(3.0) == "3", "whole numbers stay whole")
	check(Palette.number(402.9) == "402", "whole past 100")
	check(Palette.number(1460.0) == "1.46K", "K past a thousand")
	check(Palette.number(7.42e8) == "742.00M", "M past a million")


## A sim with nothing spawning, for placing enemies by hand.
func _quiet_sim(row_levels: Dictionary = {}, groups: Array = BattleSim.START_GROUPS) -> BattleSim:
	var sim := BattleSim.new(1, row_levels, groups)
	sim._schedule.clear()
	sim.wave_clock = -1e9
	sim.cash = 0.0
	return sim


func _place(sim: BattleSim, kind: String, distance: float) -> BattleSim.Enemy:
	var enemy := BattleSim.Enemy.new()
	enemy.id = sim._next_id
	sim._next_id += 1
	enemy.kind = kind
	enemy.wave = sim.wave
	enemy.max_health = sim.enemy_health_now(kind)
	enemy.health = enemy.max_health
	enemy.attack = sim.enemy_attack_now(kind)
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


func _clear_test_logs() -> void:
	if FileAccess.file_exists(TEST_LOG):
		DirAccess.remove_absolute(TEST_LOG)
	if DirAccess.dir_exists_absolute(TEST_REPORTS):
		for name in DirAccess.get_files_at(TEST_REPORTS):
			DirAccess.remove_absolute(TEST_REPORTS + "/" + name)
		DirAccess.remove_absolute(TEST_REPORTS)


## A run played by buying something every few seconds, `seconds` long.
func _played_run(seed_value: int, seconds: float) -> BattleSim:
	var sim := BattleSim.new(seed_value)
	var rows := ["damage", "attack_speed", "health", "health_regen"]
	var turn := 0
	while sim.alive and sim.time < seconds:
		sim.step()
		if sim.ticks % 61 == 0:
			sim.buy(rows[turn % rows.size()], [1, 5, 0][turn % 3])
			turn += 1
	return sim


## A record as it comes back from a file: every number a float.
func _through_json(record: Dictionary) -> Dictionary:
	var json := JSON.new()
	json.parse(JSON.stringify(record, "", false, true))
	return json.data


## The game itself, saving and logging to the tests' own files.
func _game():
	var game = Main.new()
	game.save_path = TEST_SAVE
	game.log_path = TEST_LOG
	root.add_child(game)
	return game
