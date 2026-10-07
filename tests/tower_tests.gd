extends SceneTree
## The rebuild's tests: The Tower's numbers as the data states them, the
## battle's rules, and that a run replays exactly from its seed.
##
##   bash run_tests.sh

const Guesses = preload("res://src/tower/guesses.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const EnemyKinds = preload("res://src/tower/enemy_kinds.gd")
const StatStack = preload("res://src/tower/stat_stack.gd")
const Palette = preload("res://src/ui/palette.gd")
const BattleScreen = preload("res://src/ui/battle_screen.gd")
const ArenaView = preload("res://src/ui/arena_view.gd")
const ArenaEffects = preload("res://src/ui/arena_effects.gd")
const NumberMotion = preload("res://src/ui/number_motion.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const WorkshopScreen = preload("res://src/ui/workshop_screen.gd")
const Save = preload("res://src/tower/save.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")
const HomeScreen = preload("res://src/ui/home_screen.gd")
const NavBar = preload("res://src/ui/nav_bar.gd")
const Main = preload("res://src/main.gd")
const Settings = preload("res://src/settings.gd")
const RunConfig = preload("res://src/tower/run_config.gd")
const AmbientMusic = preload("res://src/ui/ambient_music.gd")
const WaveInfo = preload("res://src/ui/wave_info.gd")
const Cards = preload("res://src/tower/cards.gd")
const CardsScreen = preload("res://src/ui/cards_screen.gd")

const TEST_SAVE := "user://test_tower_save.json"
const TEST_LOG := "user://test_activity.jsonl"
const TEST_SETTINGS := "user://test_settings.json"
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
		check_near(TowerData.enemy_attack(int(reading.attack_level), "basic"), float(reading.attack), 0.011, "wave %d attack" % wave)
		if reading.has("health"):
			check_near(TowerData.enemy_health(int(reading.health_level), "basic"), float(reading.health), maxf(0.011, float(reading.health) * 0.003), "wave %d health" % wave)
	# D120: the owner's waves 50 and 100, at the levels their Enemy Level Skip
	# left, read as the SDK's health exactly.
	check_near(TowerData.enemy_health(23, "basic"), 75.17, 0.01, "wave 50's basic, 27 health levels skipped")
	check_near(TowerData.enemy_health(45, "basic"), 341.33, 0.01, "wave 100's basic, 55 skipped")


func test_the_mix_follows_the_owners_wave_info() -> void:
	var read := {1: [5, 0, 0], 22: [7, 6, 2], 50: [10, 10, 6], 100: [11, 13, 7]}
	for wave in read:
		var mix := TowerData.mix(wave)
		check_near(mix.fast, read[wave][0] / 100.0, 1e-9, "wave %d fast" % wave)
		check_near(mix.tank, read[wave][1] / 100.0, 1e-9, "wave %d tank" % wave)
		check_near(mix.ranged, read[wave][2] / 100.0, 1e-9, "wave %d ranged" % wave)
	var between := TowerData.mix(36)
	check_near(between.tank, 8.0 / 100.0, 1e-9, "halfway from 22 to 50, tanks are halfway, in whole percents")
	check(TowerData.mix(0) == TowerData.mix(1) and TowerData.mix(6500) == TowerData.mix(100), "held before the first reading and past the last")
	for wave in [1, 7, 36, 99, 100, 5000]:
		var mix := TowerData.mix(wave)
		check_near(mix.basic + mix.fast + mix.tank + mix.ranged, 1.0, 1e-9, "wave %d adds to 100%%" % wave)
		check(mix.keys() == ["basic", "fast", "tank", "ranged"], "in the order the draw reads them")
	var fresh := _quiet_sim()
	check(fresh.spawns.tier_mix() == TowerData.mix(1), "a run's first wave draws wave 1's mix")
	fresh.wave = 100
	check(fresh.spawns.tier_mix() == TowerData.mix(100), "and its hundredth, wave 100's")


func test_enemies_walk_the_towers_speeds_and_the_clock_runs_its_pace() -> void:
	# D122: the owner's Wave Info, each type's speed as a basic's.
	var read := {"fast": 2.1, "tank": 0.6, "ranged": 1.2, "boss": 0.4, "protector": 0.4, "vampire": 0.4, "ray": 0.4, "scatter": 0.6}
	for kind in read:
		check_near(TowerData.enemy_speed_m(1, kind) / TowerData.enemy_speed_m(1, "basic"), read[kind], 1e-6, "%s walks at Wave Info's speed" % kind)
	var screen = BattleScreen.new()
	root.add_child(screen)
	screen.set_process(false)
	screen.sim.levels = {"health": 6000}
	screen.sim.health = screen.sim.max_health()
	screen._process(1.0)
	check(screen.sim.ticks == floori(1.135 / BattleSim.TICK), "a real second at ×1 plays The Tower's 1.135 game seconds: %d ticks" % screen.sim.ticks)
	screen.sim.wave_clock = TowerData.spawn_seconds() * 0.5
	screen._refresh()
	check(is_equal_approx(screen._wave_bar.value, 0.5) and screen._wave_fill.bg_color == screen.WAVE_BAR, "the wave bar fills over the spawning")
	screen.sim.wave_clock = TowerData.spawn_seconds() + 4.5
	screen._refresh()
	check(is_equal_approx(screen._wave_bar.value, 0.5) and screen._wave_fill.bg_color == Palette.ACCENT, "then again, in the accent, over the 9-second cooldown")
	screen.free()


func test_enemy_types_scale_the_basic_enemy() -> void:
	var wave := 30
	var basic_health := TowerData.enemy_health(wave, "basic")
	var basic_attack := TowerData.enemy_attack(wave, "basic")
	check_near(TowerData.enemy_health(wave, "boss"), basic_health * 20.0, 0.001, "a boss has 20 basics' health")
	check_near(TowerData.enemy_attack(wave, "boss"), basic_attack, 0.001, "a boss hits like a basic")
	check_near(TowerData.enemy_health(wave, "tank"), basic_health * 5.0, 0.001, "a tank has 5 basics' health")
	check_near(TowerData.enemy_attack(wave, "tank"), basic_attack * 0.5, 0.001, "a tank hits half as hard")
	check(TowerData.enemy_speed_m(wave, "fast") > TowerData.enemy_speed_m(wave, "basic"), "fast enemies are faster")


## D119: every stat is its Workshop value, built up by effects and held to
## The Tower's hard caps.
func test_with_no_effects_every_stat_is_its_workshop_value() -> void:
	var sim := _quiet_sim()
	var wrong: Array[String] = []
	for id in TowerData.rows():
		for at in [0, 1, TowerData.max_level(id) / 2, TowerData.max_level(id)]:
			sim.levels[id] = at
			if sim.stat(id) != TowerData.value(id, at):
				wrong.append("%s at %d" % [id, at])
	check(wrong.is_empty(), "every row at every level reads exactly its Workshop value: %s" % ", ".join(wrong))


func test_effects_add_then_multiply() -> void:
	var stack := StatStack.new()
	check(stack.add("damage", "multiply", 1.5, "test:lab") and stack.add("damage", "add", 2.0, "test:card"), "effects go on")
	check(stack.add("damage", "multiply", 2.0, "test:perk"), "and stack")
	check_near(stack.value("damage", 3.0), (3.0 + 2.0) * 1.5 * 2.0, 0.0, "adds come first, then every multiplier, in any order given")
	check_near(stack.value("health", 5.0), 5.0, 0.0, "a stat with no effects is untouched")
	check(stack.effects.size() == 3 and stack.effects[1].source == "test:card", "each effect is kept with its source")


func test_effects_are_held_to_the_towers_hard_caps() -> void:
	var stack := StatStack.new()
	stack.add("defense_percent", "add", 0.9, "test")
	stack.add("thorns", "add", 0.5, "test")
	stack.add("shockwave_frequency", "multiply", 0.1, "test")
	stack.add("wall_rebuild", "multiply", 0.01, "test")
	check_near(stack.value("defense_percent", 0.495), 0.98, 0.0, "Defense % stops at 98%")
	check_near(stack.value("thorns", 0.99), 0.99, 0.0, "Thorns at 99%")
	check_near(stack.value("shockwave_frequency", 14.0), 7.0, 0.0, "Shockwave Frequency at 7 s")
	check_near(stack.value("wall_rebuild", 600.0), 150.0, 0.0, "Wall Rebuild at 150 s")
	stack.add("defense_percent", "add", -5.0, "test")
	check_near(stack.value("defense_percent", 0.495), 0.0, 0.0, "and Defense % never below nothing")


func test_a_bad_effect_changes_nothing() -> void:
	var stack := StatStack.new()
	check(not stack.add("no_such_row", "add", 1.0, "test"), "an unknown row is refused")
	check(not stack.add("damage", "divide", 2.0, "test"), "an unknown op is refused")
	check(not stack.add("damage", "multiply", NAN, "test") and not stack.add("damage", "add", INF, "test"), "a value that isn't a finite number is refused")
	check(stack.effects.is_empty() and stack.value("damage", 3.0) == 3.0, "and nothing changed")


func test_the_battle_reads_its_stats_through_the_stack() -> void:
	var sim := _quiet_sim()
	var damage := sim.stat("damage")
	sim.stats.add("damage", "multiply", 2.0, "test")
	check_near(sim.stat("damage"), damage * 2.0, 0.0, "a multiplier on Damage doubles the tower's Damage")
	sim.stats.add("defense_percent", "add", 1.0, "test")
	check_near(sim.landed_damage(100.0), 100.0 * (1.0 - 0.98) - sim.stat("defense_absolute"), 0.0001, "a hit keeps 2% at the Defense % cap, however much is added")


func test_a_run_starts_from_its_starting_effects() -> void:
	var groups: Array = BattleSim.START_GROUPS + ["wall", "shockwave"]
	var plain := BattleSim.new(1, {"health": 10}, groups)
	var effects := [
		{"stat": "health", "op": "multiply", "value": 2.0, "source": "test:card"},
		{"stat": "wall_health", "op": "add", "value": 0.1, "source": "test:lab"},
		{"stat": "shockwave_frequency", "op": "multiply", "value": 0.5, "source": "test:lab"},
	]
	var sim := BattleSim.new(1, {"health": 10}, groups, 1, effects)
	check(sim.stats.effects.size() == 3, "every starting effect goes on")
	check_near(sim.max_health(), plain.max_health() * 2.0, 0.0, "Health is built with them")
	check_near(sim.health, sim.max_health(), 0.0, "and the Number starts full")
	check_near(sim.peak_number, sim.max_health(), 0.0, "with its best where it starts")
	check_near(sim.defences.wall_health, sim.max_health() * (plain.stat("wall_health") + 0.1), 0.0001, "the Wall starts whole at the built share of the built Health")
	check_near(sim.defences.shockwave_in, maxf(plain.stat("shockwave_frequency") * 0.5, 7.0), 0.0, "and the first Shockwave waits the built time")


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
	check_near(TowerData.wave_seconds(), 35.0, 0.0, "then 9 seconds of cooldown, as the owner's wave bar shows (D121)")
	# D121: the owner's recording had a wave-1 basic cross the 30 m range in
	# about 3.9 game seconds.
	check_near(TowerData.enemy_speed_m(1, "basic"), 7.66, 0.0001, "a basic walks 7.66 m a second")
	check_near(30.0 / TowerData.enemy_speed_m(1, "basic"), 3.9, 0.05, "so it crosses a fresh tower's Range in 3.9 s")
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
	check_near(after_first - sim.health + regained, enemy.attack * 1.04, 0.0001, "the second is 4% harder")


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
	# The Number is the tower's health, shown only in the centre since D143;
	# the rule it's shown by, as the old readout was.
	check(Palette.number_shown(15.08, 15.08, true) == 15.0, "full health 15.08 reads 15")
	check(Palette.number_shown(0.3, 15.08, true) == 1.0, "a tower still standing never reads 0")
	check(Palette.number_shown(22.6, 15.08, true) == 23.0, "overhealed health reads above the most")
	# D143: the lit price and its bar, as the Workshop's.
	screen.sim.cash = 5.0
	screen._upgrades.refresh()
	var damage: Dictionary = screen._upgrades._cards["damage"]
	check(damage.price.get_theme_color("font_color") == Palette.MUTED and is_equal_approx(damage.bar.value, 5.0 / screen.sim.price("damage")), "a price out of reach is dim, its bar part-way")
	screen.sim.cash = 1000.0
	screen._upgrades.refresh()
	check(damage.price.get_theme_color("font_color") == Palette.ACCENT and damage.bar.value == 1.0, "and lit, its bar full, once it can be paid")
	check(screen._upgrades._grid.columns == 2, "the tiles stay two to a row")
	check(screen.find_children("*", "Label", true, false).filter(func(label): return label.text.begins_with("dmg ") or label.text.begins_with("atk ")).is_empty(), "no Tower-style stats strip")
	screen._upgrades.show_tab("utility")
	check(screen._upgrades._cards.is_empty() and screen._upgrades._empty.visible, "Utility says its rows open in the Workshop")
	screen.free()


## D129: as The Tower's, tapping the open tab folds the run's upgrade cards
## away so the battle takes the screen; tapping a tab brings them back.
func test_the_upgrade_panel_folds_away() -> void:
	var screen = BattleScreen.new()
	root.add_child(screen)
	screen.set_process(false)
	await process_frame
	await process_frame
	var panel = screen._upgrades
	var open_height: float = screen._arena.size.y
	panel._tab_buttons["attack"].pressed.emit()
	await process_frame
	await process_frame
	check(panel.collapsed and not panel._scroll.visible, "the open tab tapped again folds the cards away")
	check(screen._arena.size.y > open_height + 150.0, "and the battle takes the room: %.0f px tall, from %.0f" % [screen._arena.size.y, open_height])
	check(not panel._tab_buttons["attack"].button_pressed, "no tab reads as open")
	panel._tab_buttons["defense"].pressed.emit()
	await process_frame
	check(not panel.collapsed and panel._scroll.visible and panel._tab == "defense" and panel._tab_buttons["defense"].button_pressed, "a tab tapped while folded opens it")
	panel._tab_buttons["attack"].pressed.emit()
	check(not panel.collapsed and panel._tab == "attack", "and another tab switches as before")
	screen.free()


func test_the_multiplier_buys_several_levels_a_press() -> void:
	var screen = BattleScreen.new()
	root.add_child(screen)
	screen.sim.cash = 1e6
	var panel = screen._upgrades
	panel._amount_button.pressed.emit()
	check(panel._amount_button.text == "buy ×5", "one press of the multiplier makes it ×5")
	panel.refresh()
	check(panel._cards["damage"].price.text.begins_with("+5 $"), "and a card quotes five levels: %s" % panel._cards["damage"].price.text)
	panel._cards["damage"].button.pressed.emit()
	check(screen.sim.level("damage") == 5, "pressing it buys five")
	panel._amount_button.pressed.emit()
	panel._amount_button.pressed.emit()
	check(panel._amount_button.text == "buy max", "×10, then Max")
	screen.sim.cash = 0.0
	panel.refresh()
	check(panel._cards["damage"].price.text == "$" + Palette.number(screen.sim.price("damage")), "Max it can't afford quotes the next level: %s" % panel._cards["damage"].price.text)
	panel._amount_button.pressed.emit()
	check(panel._amount_button.text == "buy ×1", "and back round to ×1")
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


## The Workshop's two-column layout preserves affordability and progress,
## with the next unlock following the upgrades it expands.
func test_the_workshop_lights_what_can_be_bought() -> void:
	var workshop := Workshop.new()
	workshop.coins = 60.0
	var shop = WorkshopScreen.new()
	shop.workshop = workshop
	root.add_child(shop)
	await process_frame
	check(shop._list.get_child(0) is GridContainer and shop._list.get_child(0).columns == 2, "upgrades sit in two columns")
	check(shop._list.get_child(1) == _unlock_cards(shop)[0], "the next unlock follows the upgrade grid")
	check(shop._tab_buttons["attack"].button_pressed and not shop._tab_buttons["defense"].button_pressed, "the switch marks only the chosen category")
	check(Palette.row_value("health_regen", 1000000.0, true) == "1.00M/s" and Palette.row_value("health_regen", 0.0, true) == "0.00/s",
		"Workshop rates stay readable at large values without losing the unit")
	check(Palette.row_value("health_regen", 1000000.0) == "1000000.00/s", "other screens retain their existing rate format")
	var rows: Array = shop._cards.filter(func(card): return card.has("id"))
	check(rows.size() == 4, "the Attack category's four starting rows: %d" % rows.size())
	for card in rows:
		var lit: bool = card.price.label.get_theme_color("font_color") == Palette.COIN
		check(lit == workshop.can_buy(card.id, 1), "%s's price is lit exactly when it can be bought" % card.id)
		check_near(card.bar.value, WorkshopScreen.toward(workshop.coins, workshop.plan(card.id, 1).cost), 0.0001, "%s's bar reads how far the Coins have come" % card.id)
	var hero: Dictionary = shop._cards.filter(func(card): return card.has("group"))[0]
	check(hero.price.label.get_theme_color("font_color") == Palette.COIN and hero.bar.value == 1.0, "the unlock lights when it can be opened")
	workshop.coins = 10.0
	shop.refresh()
	check(hero.price.label.get_theme_color("font_color") == Palette.MUTED and is_equal_approx(hero.bar.value, 10.0 / TowerData.group_price("range")), "and dims, its bar part-way, when it can't")
	check(WorkshopScreen.toward(5.0, 10.0) == 0.5 and WorkshopScreen.toward(50.0, 10.0) == 1.0 and WorkshopScreen.toward(5.0, INF) == 0.0, "a bar never passes full, and a maxed row's target never fills it")
	shop.queue_free()
	await process_frame


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
	workshop.finish_run(12)
	workshop.finish_run(9)
	workshop.coins = 123456789.123456
	workshop.levels = {"damage": 7, "health": 3}
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
	for text in ["{not json", JSON.stringify({"version": 0, "workshop": {"coins": 5}}), JSON.stringify([1, 2])]:
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
	sim.spawns.schedule.clear()
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


func test_knockback_never_moves_a_ray() -> void:
	var sim := _quiet_sim()
	sim.levels = {"knockback_chance": TowerData.max_level("knockback_chance"), "knockback_force": TowerData.max_level("knockback_force")}
	var ray := _place(sim, "ray", 20.0)
	ray.max_health = 1e9
	ray.health = 1e9
	for _i in range(roundi(10.0 / BattleSim.TICK)):
		sim.step()
	check(ray.health < ray.max_health, "the tower shoots the Ray")
	check_near(ray.distance, 20.0, 0.0, "and Knockback never moves it: The Tower's Ray is immune (D117)")
	check(not EnemyKinds.knockback_moves("ray") and EnemyKinds.knockback_moves("boss"), "only the Ray is immune; a boss is just heavy")


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
	sim.spawns.schedule.clear()
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
	sim.spawns.schedule.clear()
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
	var orb: float = sim.defences.orb_angles(sim.time)[0]
	var walker := _place(sim, "basic", sim.defences.orb_radius())
	walker.angle = orb + 0.05
	walker.stop_at = Guesses.CONTACT_DISTANCE_M
	var boss := _place(sim, "boss", sim.defences.orb_radius())
	boss.angle = orb + 0.05
	boss.stop_at = Guesses.CONTACT_DISTANCE_M
	var kills := sim.kills
	sim.record_events = true
	sim.step()
	check(not sim.enemies.has(walker) and sim.kills == kills + 1, "an orb kills the enemy it sweeps past, and it pays")
	check(sim.enemies.has(boss) and boss.health == boss.max_health, "but never a boss")
	var killed := sim.events.filter(func(event): return event.type == "kill")
	check(killed.size() == 1 and killed[0].by == "orb", "the kill says an orb did it")
	var arena := ArenaView.new()
	arena.sim = sim
	arena.absorb(sim.events, 0.0)
	check(arena.effects.pops.size() == 1 and arena.effects.pops[0].text == "0", "so it pops as a 0, set to zero (D106): %s" % [arena.effects.pops])
	arena.free()
	check(not EnemyKinds.orbs_kill("boss") and EnemyKinds.orbs_kill("basic"), "orbs can't kill bosses, and can kill the rest of The Tower's launch enemies")
	check(sim.defences.orb_angles().size() == 4, "four orbs, spaced evenly")


## Orbs as The Tower has them (D108): Orb Speed in rotations a minute, and at
## least 60 m out, further inside a Range that grows past that.
func test_orbs_circle_at_the_towers_distance_and_speed() -> void:
	var sim := _quiet_sim()
	sim.levels = {"orbs": 1}
	check_near(sim.defences.orb_radius(), Guesses.ORB_MIN_RADIUS_M, 0.0, "60 m out, beyond a 30 m Range")
	check_near(sim.defences.orb_turns_per_second() * 60.0, TowerData.value("orb_speed", 0), 0.0001, "Orb Speed's value is rotations a minute")
	check(is_equal_approx(1.0 / sim.defences.orb_turns_per_second(), 150.0), "a turn every 2½ minutes at its first level: %.1f s" % (1.0 / sim.defences.orb_turns_per_second()))
	sim.levels["orb_speed"] = TowerData.max_level("orb_speed")
	var lap := 1.0 / sim.defences.orb_turns_per_second()
	check(lap > 9.0 and lap < 11.0, "about one every 10 seconds at its last: %.1f s" % lap)
	sim.levels["range"] = TowerData.max_level("range")
	var range_m := sim.stat("range")
	check(range_m > Guesses.ORB_MIN_RADIUS_M and sim.defences.orb_radius() > Guesses.ORB_MIN_RADIUS_M and sim.defences.orb_radius() < range_m,
		"a Range past 60 m takes them further out, but inside it: %.1f m of %.1f" % [sim.defences.orb_radius(), range_m])


func test_orbs_sweep_the_approach_not_a_small_ranges_edge() -> void:
	var sim := _quiet_sim()
	sim.levels = {"orbs": 1, "orb_speed": TowerData.max_level("orb_speed")}
	var turn := 1.0 / sim.defences.orb_turns_per_second()
	var ranged := _place(sim, "ranged", sim.stat("range"))
	ranged.angle = 2.0
	ranged.max_health = 1e9
	ranged.health = 1e9
	# Harmless, so the tower outlasts a whole turn.
	ranged.attack = 0.0
	var walker := _place(sim, "basic", sim.defences.orb_radius())
	walker.angle = 4.0
	walker.max_health = 1e9
	walker.health = 1e9
	walker.attack = 0.0
	for _i in range(roundi(turn / BattleSim.TICK) + 1):
		sim.step()
	check(sim.enemies.has(ranged), "a ranged enemy on a 30 m Range's edge is out of their reach")
	check(not sim.enemies.has(walker), "one on their circle dies within a turn, however tough")


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
		sim.spawns.schedule.clear()
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
	check(not sim.defences.mines.is_empty(), "shots lay mines: %d" % sim.defences.mines.size())
	for mine in sim.defences.mines:
		check(mine.length() >= Guesses.CONTACT_DISTANCE_M - 0.0001 and mine.length() <= sim.stat("range") + 0.0001, "a mine lies in range: %s" % mine.length())
	sim = _quiet_sim({}, BattleSim.START_GROUPS + ["land_mines"])
	sim.record_events = true
	sim.defences.mines = [Vector2(20.0, 0.0)]
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
	check(sim.defences.mines.is_empty(), "a walking enemy within 2 m sets the mine off")
	var average_crit := (1.0 + sim.stat("critical_factor") * sim.stat("critical_chance")) * (1.0 + sim.stat("super_crit_mult") * sim.stat("super_crit_chance") * sim.stat("critical_chance"))
	check_near(walker.health, 1000.0 - sim.stat("damage") * sim.stat("land_mine_damage") * average_crit, 0.0001, "the blast deals Land Mine Damage's share of Damage, with the average crit (D116)")
	check(not sim.enemies.has(beside) and sim.kills == kills + 1, "an enemy within Land Mine Radius it kills is paid for")
	check_near(away.health, 1000.0, 0.0, "one out of the radius is untouched")


func test_the_wall_stops_melee_enemies_until_it_falls_then_rebuilds() -> void:
	check(not _quiet_sim().defences.wall_up(), "no wall before Wall opens")
	var sim := _quiet_sim({"health": 100}, BattleSim.START_GROUPS + ["wall"])
	sim.record_events = true
	check(sim.defences.wall_up() and is_equal_approx(sim.defences.wall_health, sim.max_health() * sim.stat("wall_health")), "the wall starts at Wall Health's share of Health")
	var walker := _place(sim, "basic", 12.0)
	walker.speed = 30.0
	walker.max_health = 1e12
	walker.health = 1e12
	for _i in range(30):
		sim.step()
	check_near(walker.distance, Guesses.WALL_DISTANCE_M, 0.0, "a melee enemy stops at the wall")
	check(sim.defences.wall_health < sim.defences.wall_max_health() and is_equal_approx(sim.health, sim.max_health()), "and hits the wall, not the tower")
	sim.defences.wall_health = 0.01
	while sim.defences.wall_up():
		sim.step()
	check(not sim.events.filter(func(event): return event.type == "wall_down").is_empty(), "the wall falls")
	check_near(sim.defences.wall_rebuild_in, sim.stat("wall_rebuild"), BattleSim.TICK, "and rebuilds after Wall Rebuild seconds")
	for _i in range(15):
		sim.step()
	check(walker.distance < Guesses.WALL_DISTANCE_M, "the enemy walks on once the wall is down")
	sim.defences.wall_rebuild_in = 0.5
	for _i in range(16):
		sim.step()
	check(sim.defences.wall_up() and walker.distance >= Guesses.WALL_DISTANCE_M, "a rebuilt wall pushes out the enemy inside it (D116): %s" % walker.distance)
	sim.step()
	check_near(walker.distance, Guesses.WALL_DISTANCE_M, 0.0, "which then stands at the wall")
	sim.enemies.clear()
	sim.defences.wall_health = 0.0
	sim.defences.wall_rebuild_in = 10.0
	sim.defences.wall_rebuild_in = 0.5
	for _i in range(16):
		sim.step()
	check(sim.defences.wall_up() and is_equal_approx(sim.defences.wall_health, sim.defences.wall_max_health()), "a rebuilt wall is whole")


func test_a_standing_wall_takes_ranged_hits_but_not_a_vampires_drain() -> void:
	var sim := _quiet_sim({"health": 100}, BattleSim.START_GROUPS + ["wall"])
	sim.record_events = true
	var shooter := _place(sim, "ranged", 25.0)
	shooter.stop_at = 25.0
	shooter.max_health = 1e12
	shooter.health = 1e12
	var wall_before := sim.defences.wall_health
	sim.step()
	check(sim.defences.wall_health < wall_before, "a ranged hit lands on the standing wall (D116)")
	check(is_equal_approx(sim.health, sim.max_health()), "and not on the Number")
	check(sim.events.any(func(event): return event.type == "wall_hit" and event.enemy == shooter), "and the screen hears of it, to draw the shot ending at the wall")
	sim.defences.wall_health = 0.0
	sim.defences.wall_rebuild_in = 1e9
	shooter.hit_in = 0.0
	sim.step()
	check(sim.health < sim.max_health(), "with the wall down it reaches the Number again")
	sim = _quiet_sim({"health": 100}, BattleSim.START_GROUPS + ["wall"])
	var vampire := _place(sim, "vampire", 25.0)
	vampire.stop_at = 25.0
	var wall_full := sim.defences.wall_health
	sim.step()
	check(sim.health < sim.max_health() and is_equal_approx(sim.defences.wall_health, wall_full), "a Vampire drains the Number past the wall, as in The Tower")


func test_kill_cash_slows_past_wave_200() -> void:
	for pair in [[1, 1.0], [9, 1.0], [10, 2.0], [199, 20.0], [200, 21.0], [219, 21.0], [220, 22.0], [260, 24.0], [1000, 61.0], [6500, 336.0]]:
		check_near(TowerData.kill_cash(int(pair[0])), float(pair[1]), 0.0, "a wave-%d kill pays $%d before its type (D116)" % [pair[0], pair[1]])
	var sim := _quiet_sim()
	sim.wave = 260
	var tank := _place(sim, "tank", 10.0)
	tank.health = 0.5
	for _i in range(60):
		sim.step()
	check_near(sim.cash, 24.0 * 5.0, 0.0, "a wave-260 tank pays $24 times 5")


func test_heat_up_comes_from_the_generated_data() -> void:
	check_near(TowerData.heat_up_per_hit(), 1.04, 0.0, "each hit an enemy lands makes its next 4% harder (TheTowerSDK, D116)")


## The wave a run has cleared is the sim's to say: it pays the wave rewards and
## opens tiers. Every wave before the one it stands on, except at the data
## horizon, whose own end is the achievement.
func test_cleared_waves_come_from_the_sim() -> void:
	var sim := _quiet_sim()
	sim.wave = 12
	check(sim.cleared_wave() == 11, "a run standing on wave 12 has cleared 11")
	sim.killed_by = "basic"
	check(sim.cleared_wave() == 11, "dying on it clears the waves before it")
	sim.killed_by = "ended"
	check(sim.cleared_wave() == 11, "and ending the run by hand does not claim the wave")
	sim.killed_by = "data_limit"
	check(sim.cleared_wave() == 12, "the data horizon's last wave is itself an achievement")


## The Wall is drawn as brackets round the Number (D106): enemies held at it
## stand clear of the brackets, and once it falls they come in to the digits.
func test_enemies_at_the_wall_stand_clear_of_its_brackets() -> void:
	var sim := _quiet_sim({"health": 100}, BattleSim.START_GROUPS + ["wall"])
	var arena := ArenaView.new()
	arena.size = Vector2(390, 440)
	arena.centre = Vector2(195, 242)
	arena.sim = sim
	var half := arena.enemy_half("basic", "−1")
	arena._number_layout()
	var digits: float = arena._number_half.x
	var held := arena.enemy_at(0.0, 0.0, half).x - arena.centre.x
	check(held - half.x > digits + ArenaView.WALL_GAP_PX + 2.0, "with the Wall up an arriving enemy stands outside the brackets: %.0f against digits to %.0f" % [held, digits])
	check(arena._float_side() > arena._clear_half.x, "and the hit float starts outside them too")
	sim.defences.wall_health = 0.0
	arena._number_layout()
	var through := arena.enemy_at(0.0, 0.0, half).x - arena.centre.x
	check(through < held and is_equal_approx(through - half.x, digits + ArenaView.CONTACT_GAP_PX), "with it down, just clear of the digits: %.0f" % through)
	arena.absorb([{"type": "wall_down"}], 0.0)
	check(arena.effects.wall_fell and arena.effects.wall_changed_age == 0.0, "its fall is timed, so the brackets can drop away")
	arena.free()


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
	sim._heal(1.0, "regen")
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
	sim.spawns.schedule = [{"kind": "tank", "at": 0.0}]
	sim.spawns.next_spawn = 0
	sim.wave_clock = 0.0
	sim.spawns.spawn_due()
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
	check(run.kind == "run" and int(run.seed) == screen.sim.run_seed and is_equal_approx(float(run.play.real_seconds), 0.5), "a battle reports its run and play time")
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
	while not sliced.advance(17):
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
	# Legacy records still resume by replay. Full snapshots have their own
	# continuation and direct-resume coverage in foundation_tests.gd.
	saved.erase("snapshot")
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


## D158: a saved battle comes back under the rules it began with, whichever
## the game plays now: one begun as Cash (every save from before) keeps its
## Cash chip and words, one begun as the game's rules keeps the Number's, each
## from a full snapshot and from a replay of its record.
func test_a_saved_run_resumes_under_the_rules_it_began_with() -> void:
	for game in [false, true]:
		var shop := Workshop.new()
		shop.levels = {"damage": 20, "health": 60, "health_regen": 30}
		var first := BattleScreen.new()
		first.workshop = shop
		if game:
			first.tuning = RunConfig.game_tuning()
		root.add_child(first)
		first.start_run(99)
		for frame in range(1500):
			first._process(1.0 / 30.0)
			if frame % 60 == 0 and first.sim.can_buy("attack_speed"):
				first.sim.buy("attack_speed")
		check(first.sim.alive and first.sim.number_cash == game and first.sim.run_levels.size() > 0,
			"%s: a run that has bought is still going" % ["game's rules" if game else "Cash rules"])
		var saved := _through_json(first.run_state())
		check(saved.has("snapshot") and saved.start.tuning.has("number_cash") == game and not saved.start.tuning.has("lock_holds_cash") != game,
			"its record says which rules it began with")
		for from_snapshot in [true, false]:
			var record := saved.duplicate(true)
			if not from_snapshot:
				record.erase("snapshot")
			var second := BattleScreen.new()
			second.workshop = shop
			second.resume = record
			root.add_child(second)
			var frames := 0
			while second.sim == null and frames < 300:
				second._process(0.0)
				frames += 1
			var how := "%s, from %s" % ["game's rules" if game else "Cash rules", "a snapshot" if from_snapshot else "a replay"]
			check(second.sim != null and second.sim.ticks == first.sim.ticks and is_equal_approx(second.sim.health, first.sim.health)
				and is_equal_approx(second.sim.cash, first.sim.cash) and second.sim.number_cash == game, "%s: exactly where it was left, under its rules" % how)
			check(second._cash_chip.visible != game and Palette.number_cash == game, "%s: the Cash chip and the words follow the run" % how)
			check(Palette.row_title("cash_bonus") == ("Number bonus" if game else "Cash bonus") and second._upgrades.sim.in_shop("health") != game,
				"%s: the shop sells what its rules sell" % how)
			second._process(1.0)
			check(second.sim.ticks > first.sim.ticks, "%s: and plays on" % how)
			second.free()
		first.free()
	Palette.number_cash = false


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
	# Short enough that the run is still alive to resume (it dies at 34 s since D120's wave-1 mix).
	var played := _played_run(31, 30.0)
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
		check(game._screen._note.text.begins_with("Your run at wave %d" % played.wave if reason == "changed" else "Your saved run couldn't be read"), "saying so: %s" % game._screen._note.text)
		# Sound changed-rules records retain milestones; damaged values can't pay.
		var expected := Workshop.new()
		expected.coins = 60.0
		expected.finish_run(played.wave if reason == "changed" else 0, played.peak_number if reason == "changed" else 0.0, played.cash_earned if reason == "changed" else 0.0)
		check(Save.load_run(TEST_SAVE).is_empty() and loaded.runs == 1 and loaded.best_wave == expected.best_wave and is_equal_approx(loaded.coins, expected.coins),
			"the run is cleared, counted at its wave, and its Coins kept, milestones paid: %s" % loaded.coins)
		var entries := ActivityLog.read(TEST_LOG).filter(func(entry): return entry.kind == "run")
		check(entries.size() == 1 and entries[0].resume_failed == reason, "and logged as lost: %s" % [entries.map(func(entry): return entry.get("resume_failed"))])
		game.free()
		_clear_test_logs()
	_clear_test_saves()


## D158: the game itself starts every run under its rules, again and again, with
## Run upgrades off read from the settings only as a run starts, and Home, the
## Workshop and Cards write about the Number.
func test_the_game_starts_every_run_under_its_rules() -> void:
	_clear_test_saves()
	_clear_test_logs()
	var game = _game()
	await process_frame
	game._show_battle()
	var battle = game._screen
	check(battle.sim.number_cash and battle.sim.lock_holds_cash and not battle.sim.upgrades_off and not battle._cash_chip.visible,
		"a new run plays the game's rules, with the shop open")
	battle.sim.end_run()
	battle._process(0.0)
	check(battle._over_text.text.contains("Number earned") and not battle._over_text.text.contains("Cash earned") and not battle._over_text.text.contains("Kills grew"),
		"the run-over panel speaks of the Number, with no clean-kill line the new rules don't have")
	battle.start_run(5)
	check(battle.sim.number_cash and battle.sim.lock_holds_cash, "and so does the next one (Battle again)")
	var record := RunReport.build(battle.sim)
	check(record.start.tuning.number_cash == true and record.start.tuning.lock_holds_cash == true and RunReport.is_replayable(record), "recorded in its start config, so it replays")
	battle.sim.end_run()
	battle._process(0.0)
	game.settings.upgrades_off = true
	check(battle.sim.upgrades_off == false, "the setting changes nothing for the screen already open")
	game._show_home()
	check(Palette.number_cash and Palette.row_title("cash_per_wave") == "Number / wave", "Home and the Workshop write about the Number")
	game._show_battle()
	check(game._screen.sim.upgrades_off and game._screen.sim.number_cash and not game._screen.sim.can_buy("damage"), "with Run upgrades off, the next run's shop is shut")
	game.free()
	Palette.number_cash = false
	_clear_test_saves()
	_clear_test_logs()


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
	var entries := ActivityLog.read(TEST_LOG).filter(func(entry): return entry.kind == "run")
	check(entries.size() == 2 and int(entries[0].seed) == 1 and int(entries[1].seed) == 2, "a run and its Battle again are both logged: %d" % entries.size())
	var gifts := ActivityLog.read(TEST_LOG).filter(func(entry): return entry.kind == "gift")
	check(gifts.size() == 1 and float(gifts[0].coins) == Workshop.FIRST_RUN_GIFT, "and the first run's gift once, apart from what runs earned (D125)")
	check(Save.load_run(TEST_SAVE).is_empty(), "and neither stays in the save")
	game.free()
	_clear_test_logs()
	_clear_test_saves()


func test_a_divider_takes_the_protectors_slot_replacing_a_basic() -> void:
	var sim := BattleSim.new(8)
	var plain := BattleSim.new(8)
	plain.divider.rate_first = 0.0
	plain.divider.rate_full = 0.0
	check(EnemyKinds.divider_rate(sim.divider, 4) == 0.0 and is_equal_approx(EnemyKinds.divider_rate(sim.divider, 5), 1.0 / 3.0), "none before wave 5, then one every third wave")
	check(is_equal_approx(EnemyKinds.divider_rate(sim.divider, 30), 0.5) and is_equal_approx(EnemyKinds.divider_rate(sim.divider, 200), 0.5), "rising to every other wave by wave 30, and holding")
	check(is_equal_approx(EnemyKinds.divider_divisor(sim.divider, 5), 1.25) and is_equal_approx(EnemyKinds.divider_divisor(sim.divider, 30), 1.5) and is_equal_approx(EnemyKinds.divider_divisor(sim.divider, 99), 1.5),
		"their divisor rises from ÷1.25 to ÷1.5 by wave 30: gentle, since Tier 1 is the tutorial")
	for at_wave in range(5, 40):
		var divisor := EnemyKinds.divider_divisor(sim.divider, at_wave)
		check(is_equal_approx(divisor, 1.25) or is_equal_approx(divisor, 1.5), "wave %d's divisor reads cleanly: %s" % [at_wave, divisor])
	check(is_equal_approx(EnemyKinds.divider_divisor(sim.divider, 17), 1.25) and is_equal_approx(EnemyKinds.divider_divisor(sim.divider, 18), 1.5), "÷1.25 to wave 17, then ÷1.5")
	var walking := BattleSim.new(8)
	walking.spawns.schedule.clear()
	walking.wave = 17
	walking.spawns.schedule = [{"kind": "divider", "at": 0.0}]
	walking.spawns.next_spawn = 0
	walking.wave_clock = 0.0
	walking.spawns.spawn_due()
	check_near(walking.enemies[-1].divisor, EnemyKinds.divider_divisor(walking.divider, 17), 0.0, "a Divider carries the divisor of the wave it came in")
	var divider_waves: Array[int] = []
	var expected := 0.0
	for at_wave in range(2, 61):
		for each in [sim, plain]:
			each.wave = at_wave
			each.spawns.schedule_wave()
		check(sim.spawns.schedule.size() == plain.spawns.schedule.size(), "wave %d: as many enemies as The Tower sends" % at_wave)
		var replaced := 0
		for index in range(sim.spawns.schedule.size()):
			var ours: Dictionary = sim.spawns.schedule[index]
			var theirs: Dictionary = plain.spawns.schedule[index]
			if ours.kind == "divider":
				replaced += 1
				check(theirs.kind == "basic" and float(ours.at) == float(theirs.at), "wave %d: a Divider stands where a basic would have" % at_wave)
			elif ours != theirs:
				check(false, "wave %d: every other enemy comes exactly as without Dividers" % at_wave)
		check(replaced <= 1, "wave %d: at most one Divider a wave" % at_wave)
		if replaced == 1:
			divider_waves.append(at_wave)
		expected += EnemyKinds.divider_rate(sim.divider, at_wave)
	check(not divider_waves.is_empty() and divider_waves[0] == 7, "the first comes on wave 7, once a third a wave adds up to one: %s" % [divider_waves])
	for index in range(divider_waves.size() - 1):
		check(divider_waves[index + 1] - divider_waves[index] >= 2, "never two waves running: %s" % [divider_waves])
	# What's owed but not yet come is always less than one.
	check(divider_waves.size() <= expected + 0.001 and divider_waves.size() > expected - 1.0,
		"as many as their rate adds up to: %d against %.1f" % [divider_waves.size(), expected])
	# The Divider comes from where its basic would have, so every other enemy
	# comes from The Tower's direction too.
	sim.spawns.divider_due = 1.0
	for each in [sim, plain]:
		each.enemies.clear()
		each.wave = 7
		each.spawns.schedule_wave()
		each.wave_clock = 999.0
		each.spawns.spawn_due()
	check(sim.enemies.size() == plain.enemies.size(), "a Divider's wave sends as many enemies")
	var same_directions := true
	var dividers := 0
	for index in range(sim.enemies.size()):
		same_directions = same_directions and sim.enemies[index].angle == plain.enemies[index].angle
		dividers += 1 if sim.enemies[index].kind == "divider" else 0
	check(same_directions and dividers == 1, "and each comes from the same direction, one of them a Divider")


func test_a_divider_halves_the_number_through_the_defences_and_is_used_up() -> void:
	var sim := _quiet_sim({"health": 400})
	sim.record_events = true
	sim.health = 100.0
	var cash := sim.cash
	var kills := sim.kills
	var divider := _place(sim, "divider", Guesses.CONTACT_DISTANCE_M)
	sim.step()
	# Tier 1 starts at ÷1.25: a fifth of the Number, since a bigger divisor takes more.
	check_near(EnemyKinds.divider_divisor(sim.divider, 1), 1.25, 0.0, "Tier 1's first Dividers are ÷1.25")
	check_near(sim.health, 80.0 + sim.stat("health_regen") * BattleSim.TICK, 0.0001, "÷1.25 takes a fifth of the Number")
	check(not sim.enemies.has(divider) and divider.health == 0.0, "and the Divider is used up")
	check(sim.kills == kills and sim.cash == cash and sim.dividers_landed == 1, "without paying or counting as a kill")
	check_near(float(sim.lost_to.divider), 20.0, 0.0001, "the loss is put down to Dividers")
	check(not sim.events.filter(func(event): return event.type == "divided").is_empty(), "and the screen hears of it")
	var guarded := _quiet_sim({"health": 400, "defense_percent": 40, "defense_absolute": 10})
	guarded.health = 100.0
	_place(guarded, "divider", Guesses.CONTACT_DISTANCE_M)
	guarded.step()
	var took := 100.0 + guarded.stat("health_regen") * BattleSim.TICK - guarded.health
	check_near(took, guarded.landed_damage(20.0), 0.0001, "the same defences as any hit, Defense %% then Absolute: %.2f" % took)
	var tiny := _quiet_sim()
	tiny.health = 0.01
	_place(tiny, "divider", Guesses.CONTACT_DISTANCE_M)
	tiny.step()
	check(tiny.alive and tiny.health > 0.0, "half of anything is never all of it: a Divider can't end a run")


func test_a_divider_in_flight_is_lost_to_shots_and_pays_when_killed() -> void:
	var sim := _quiet_sim()
	var divider := _place(sim, "divider", 20.0)
	check_near(divider.max_health, TowerData.enemy_health(sim.wave, "basic") * 4.0, 0.0001, "four times a basic enemy's health")
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
	var wall := sim.defences.wall_health
	_place(sim, "divider", Guesses.WALL_DISTANCE_M)
	sim.step()
	check_near(sim.defences.wall_health, wall / 1.25, 0.0001, "the Wall loses what the Number would")
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


func test_overfill_decides_how_far_past_its_ceiling_the_number_can_rise() -> void:
	var sim := _quiet_sim()
	check(sim.overfill == Guesses.NUMBER_OVERFILL and sim.overfill == 1.0, "the game has no ceiling (D083)")
	var most := sim.max_health()
	sim.overfill = 0.0
	sim.health = most - 1.0
	sim._heal(3.0, "lifesteal")
	check_near(sim.health, most, 0.0, "with a ceiling, healing stops at Health")
	sim.overfill = 0.5
	sim.health = most - 1.0
	sim._heal(3.0, "lifesteal")
	check_near(sim.health, most + 1.0, 0.0001, "at half, what's past Health counts half")
	sim.overfill = 1.0
	sim._heal(4.0, "lifesteal")
	check_near(sim.health, most + 5.0, 0.0001, "with none, the Number keeps rising")


## The sim books where the Number's gains come from, and which of them set a
## new high rather than refilling it, for measuring (sim_runs.gd --gains).
func test_gains_are_booked_by_source_and_new_highs() -> void:
	var sim := _quiet_sim()
	var start := sim.health
	sim._heal(2.0, "lifesteal")
	check_near(float(sim.gained_from.lifesteal), 2.0, 0.0001, "lifesteal's gain is booked")
	check_near(float(sim.raised_by.lifesteal), 2.0, 0.0001, "and, past the start, it set a new high")
	sim.health -= 3.0
	sim._heal(1.0, "regen")
	check_near(float(sim.gained_from.regen), 1.0, 0.0001, "regen's gain is booked")
	check(not sim.raised_by.has("regen"), "but refilling below the high is not a new high")
	sim._heal(6.0, "lifesteal")
	check_near(float(sim.raised_by.lifesteal), 6.0, 0.0001, "only the part past the old high counts: %s" % sim.raised_by)
	sim.cash = 1e9
	sim.buy("health")
	check(float(sim.gained_from.get("health", 0.0)) > 0.0, "buying Health books its raise")
	check(sim.health > start, "and none of this touched the battle's rules")


## Spawning is The Tower's (D114): every 1/8 second of the spawning window an
## enemy comes by the wave's spawn rate, 5 at wave 1, the owner's 15 at wave
## 22, then the SDK's chart from 37 at wave 1,000 to 56 at 6,500.
func test_spawns_roll_by_the_waves_spawn_rate() -> void:
	check_near(TowerData.spawn_roll_seconds(), 0.25, 0.0, "a roll every quarter second: 104 a wave, as the owner counted (D135)")
	check_near(TowerData.spawn_rate(1), 10.0, 0.0001, "10 at wave 1, from The Tower's chart (D118)")
	check_near(TowerData.spawn_rate(2), 10.0, 0.0001, "in steps")
	check_near(TowerData.spawn_rate(3), 11.0, 0.0001, "11 from wave 3")
	check_near(TowerData.spawn_rate(22), 15.0, 0.0001, "15 at wave 22, as the owner read it")
	check_near(TowerData.spawn_rate(100), 22.0, 0.0001, "22 from wave 100")
	check_near(TowerData.spawn_rate(799), 34.0, 0.0001, "34 to wave 799")
	check_near(TowerData.spawn_rate(1250), 38.0, 0.0001, "38 from 1,250")
	check_near(TowerData.spawn_rate(1000), 37.0, 0.0001, "37 from wave 1,000")
	check_near(TowerData.spawn_rate(1249), 37.0, 0.0001, "in the chart's steps")
	check_near(TowerData.spawn_rate(1500), 39.0, 0.0001, "39 from 1,500")
	check_near(TowerData.spawn_rate(9000), 56.0, 0.0001, "and 56 at most")
	for at_wave in [1, 22, 100]:
		var total := 0
		for seed in range(1, 41):
			var sim := BattleSim.new(seed)
			sim.wave = at_wave
			sim.spawns.schedule_wave()
			# The Tower's spawns: not the boss, nor the Lock on top (D133).
			total += sim.spawns.schedule.filter(func(entry): return entry.kind != "boss" and entry.kind != "lock").size()
		var rolls := TowerData.spawn_seconds() / TowerData.spawn_roll_seconds()
		var expected := rolls * TowerData.spawn_rate(at_wave) / 100.0 * (1.0 + float(TowerData.tier(1).double_spawn))
		check_near(float(total) / 40.0, expected, expected * 0.08, "wave %d sends about %.0f enemies: %.1f" % [at_wave, expected, float(total) / 40.0])


## Tiers (D107, D112) come from the generated data: Tier 2's enemies have 20
## times Tier 1's health and attack and pay 1.8 times the Coins, Tier 3's 60
## and 2.6; a tier shifts the mix towards fast, tank and ranged and adds its
## double-spawn chance; and in every tier a full field stops more spawning.
func test_tiers_scale_enemies_and_spawns() -> void:
	check(TowerData.tier_count() == 3, "Tiers 1 to 3 are generated")
	var first := BattleSim.new(1)
	var second := BattleSim.new(1, {}, BattleSim.START_GROUPS, 2)
	var third := BattleSim.new(1, {}, BattleSim.START_GROUPS, 3)
	check(first.tier == 1 and second.tier == 2 and BattleSim.new(1, {}, BattleSim.START_GROUPS, 9).tier == 3, "a run knows its tier, held to the ones there are")
	for sim in [first, second, third]:
		sim.wave = 50
		sim.health_level = 50
		sim.attack_level = 50
	check_near(second.enemy_health_now("basic") / first.enemy_health_now("basic"), 20.0, 0.0001, "Tier 2's health is 20 times")
	check_near(third.enemy_attack_now("tank") / first.enemy_attack_now("tank"), 60.0, 0.0001, "Tier 3's attack is 60 times")
	check_near(second.enemy_health_now("divider") / first.enemy_health_now("divider"), 20.0, 0.0001, "Dividers too")
	check(first.spawns.tier_mix() == TowerData.mix(50), "Tier 1 keeps the data's mix")
	check_near(float(third.spawns.tier_mix().fast), float(TowerData.mix(50).fast) * 1.08, 0.0001, "Tier 3 has 8% more fast enemies")
	var shares := 0.0
	for kind in third.spawns.tier_mix():
		shares += float(third.spawns.tier_mix()[kind])
	check_near(shares, 1.0, 0.0001, "and basics fill the rest")
	check(TowerData.tier(2).double_spawn == TowerData.tier(1).double_spawn and TowerData.tier(3).double_spawn > TowerData.tier(1).double_spawn, "Tier 2 double-spawns as Tier 1 does, Tier 3 a touch more")

	var paying := _quiet_sim()
	paying.tier = 2
	var tank := _place(paying, "tank", 20.0)
	paying._kill(tank)
	check_near(paying.coins, float(Guesses.COINS_BY_TYPE.tank) * 1.8, 0.0001, "Tier 2 pays 1.8 times the Coins")

	var full := _quiet_sim()
	for n in range(TowerData.enemy_cap()):
		_place(full, "basic", 90.0)
	full.spawns.schedule = [{"kind": "basic", "at": 0.0}, {"kind": "boss", "at": 0.0}]
	full.spawns.next_spawn = 0
	full.wave_clock = 0.0
	full.spawns.spawn_due()
	check(full.enemies.size() == TowerData.enemy_cap() + 1 and full.enemies[-1].kind == "boss", "a full field of %d takes no more normal enemies, but a boss still comes" % TowerData.enemy_cap())


## The Tower's Protector (D115): none in Tier 1; from Tier 2 wave 80 a share
## of the draws, at most one a wave behind a gate. It and the enemies near it
## take 60% of a strike and 70% of Thorns, and orbs can't kill them.
func test_protectors_shield_from_tier_2() -> void:
	check(TowerData.protector_chance(500, 1) == 0.0, "no Protector in Tier 1")
	check(TowerData.protector_chance(79, 2) == 0.0 and TowerData.protector_chance(80, 2) == 1.0 and TowerData.protector_chance(160, 3) == 2.0
		and TowerData.protector_chance(800, 2) == 4.0, "Tier 2 and 3: 1% from wave 80, 2% from 160, 3% from 320, 4% from 751")
	var counts := {}
	for seed in range(1, 21):
		var sim := BattleSim.new(seed, {}, BattleSim.START_GROUPS, 2)
		var sent := 0
		var last := -100
		var closest := 100
		for at_wave in range(400, 460):
			sim.wave = at_wave
			sim.spawns.schedule_wave()
			var here := sim.spawns.schedule.filter(func(entry): return entry.kind == "protector").size()
			check(here <= 1, "at most one Protector a wave")
			if here == 1:
				closest = mini(closest, at_wave - last)
				last = at_wave
				sent += 1
		counts[seed] = sent
		check(closest >= 5, "the gate keeps them five waves apart at least: %d" % closest)
	var total := 0
	for seed in counts:
		total += int(counts[seed])
	check(total > 60 and total < 240, "Protectors come every several waves at 3%%: %d in 20 runs of 60 waves" % total)

	var sim := _quiet_sim()
	sim.tier = 2
	sim.wave = 100
	var guard := _place(sim, "protector", 30.0)
	var near := _place(sim, "basic", 30.0 + TowerData.protector_radius_m(100, 2) * 0.5)
	var far := _place(sim, "basic", 30.0 + TowerData.protector_radius_m(100, 2) * 2.0)
	check(sim.shielded(guard) and sim.shielded(near) and not sim.shielded(far), "a Protector shields itself and what's within its radius")
	near.health = 1000.0
	far.health = 1000.0
	sim._strike(near, 10.0, false)
	sim._strike(far, 10.0, false)
	check_near(1000.0 - near.health, 6.0, 0.001, "a shielded enemy takes 60% of a strike")
	check_near(1000.0 - far.health, 10.0, 0.001, "one outside takes all of it")
	sim._kill(guard)
	check(not sim.shielded(near), "a dead Protector shields nothing")


## Elites (D115): the chart's chance for each of Vampire, Ray and Scatter, from
## wave 500 in Tier 1 and 10% sooner a tier; at most 20 on the field and 8 of
## a type; orbs and shockwaves don't touch them.
func test_elites_come_by_the_chart() -> void:
	check(TowerData.elite_chance(499, 1).single == 0.0 and TowerData.elite_chance(500, 1).single == 1.0, "Tier 1's first elites at wave 500, 1%")
	check(TowerData.elite_chance(449, 2).single == 0.0 and TowerData.elite_chance(450, 2).single == 1.0 and TowerData.elite_chance(405, 3).single == 1.0,
		"Tier 2's at wave 450, Tier 3's at 405")
	check(TowerData.elite_chance(8000, 1).single == 100.0 and TowerData.elite_chance(9000, 1).double == 4.0, "certain by wave 8,000, then a second")
	var before := BattleSim.new(3)
	before.wave = 499
	before.spawns.schedule_wave()
	var early := BattleSim.new(3)
	early.wave = 499
	early.spawns.schedule_wave()
	check(before.spawns.schedule == early.spawns.schedule, "before the chart opens, spawning draws nothing new")
	var elites := 0
	for seed in range(1, 41):
		var sim := BattleSim.new(seed)
		sim.wave = 6000
		sim.spawns.schedule_wave()
		var times: Array = sim.spawns.schedule.map(func(entry): return float(entry.at))
		var sorted := times.duplicate()
		sorted.sort()
		check(times == sorted, "the schedule stays in time order")
		elites += sim.spawns.schedule.filter(func(entry): return EnemyKinds.is_elite(entry.kind)).size()
	check_near(float(elites) / 40.0, 3.0 * 0.64, 0.6, "at wave 6,000 each type comes 64%% of waves: %.2f a wave" % (float(elites) / 40.0))

	var full := _quiet_sim()
	for n in range(TowerData.elite_type_cap()):
		_place(full, "vampire", 90.0)
	check(not full.spawns.has_room("vampire") and full.spawns.has_room("ray"), "8 Vampires fill their type, not the others")
	for n in range(TowerData.elite_cap() - TowerData.elite_type_cap()):
		_place(full, "ray" if n < TowerData.elite_type_cap() else "scatter", 90.0)
	check(not full.spawns.has_room("scatter") and full.spawns.has_room("basic"), "20 elites fill the elite cap, and normal enemies still come")
	for n in range(TowerData.boss_cap()):
		_place(full, "boss", 90.0)
	check(not full.spawns.has_room("boss"), "and 10 bosses the boss cap")

	var sim := _quiet_sim({}, BattleSim.START_GROUPS + ["shockwave"])
	var ray := _place(sim, "ray", sim.stat("range") * 0.5)
	var basic := _place(sim, "basic", sim.stat("range") * 0.5)
	check(not EnemyKinds.orbs_kill(ray.kind), "orbs can't kill elites")
	sim.defences.shockwave_in = 0.0
	sim.defences.tick_shockwave()
	check(basic.distance > ray.distance and is_equal_approx(ray.distance, sim.stat("range") * 0.5), "and shockwaves don't push them")


## A Vampire in range drains 2% of Health a second, through the Wall and the
## defences, and stops Regen and Lifesteal while it does.
func test_vampire_drains_and_stops_regen() -> void:
	var sim := _quiet_sim({"health_regen": 20})
	var vampire := _place(sim, "vampire", 20.0)
	vampire.stop_at = 20.0
	sim.health = sim.max_health() * 0.5
	var start := sim.health
	for tick in range(30):
		sim._enemies_hit()
		sim._heal(sim.stat("health_regen") * BattleSim.TICK, "regen")
	check(sim.draining, "a Vampire in range drains")
	check_near(start - sim.health, sim.max_health() * 0.02, sim.max_health() * 0.0005, "2%% of Health over a second, with no Regen: lost %s" % (start - sim.health))
	check(float(sim.lost_to.get("vampire", 0.0)) > 0.0, "and it's booked as the Vampire's")
	check(ArenaView.shown_text(sim, vampire) == "2%/s", "it shows its drain, not a hit, bare as every hit is (D128): %s" % ArenaView.shown_text(sim, vampire))
	sim._kill(vampire)
	sim._enemies_hit()
	var healed := sim.health
	sim._heal(1.0, "regen")
	check(not sim.draining and sim.health > healed, "Regen comes back once it's gone")


## D133: a Lock standing in range stops the Number going up by any means but
## buying Health, and hits nothing.
func test_a_lock_holds_the_number_while_it_stands() -> void:
	var sim := _quiet_sim({"health_regen": 20, "thorns": 10, "lifesteal": 10}, BattleSim.START_GROUPS + ["recovery_packages"])
	sim.levels["package_chance"] = TowerData.max_level("package_chance")
	var lock := _place(sim, "lock", 20.0)
	lock.stop_at = 20.0
	check(EnemyKinds.stops_at_range("lock") and lock.attack == 0.0, "a Lock stops at range and has no Attack")
	check_near(lock.max_health, sim.enemy_health_now("basic") * float(Guesses.LOCK.health), 0.0001, "and a basic's health times Guesses.LOCK's")
	sim.health = sim.max_health() * 0.5
	var start := sim.health
	for tick in range(90):
		sim._enemies_hit()
		sim._heal(sim.stat("health_regen") * BattleSim.TICK, "regen")
	check(sim.locked and sim.health == start, "while it stands the Number holds: no hit, no Regen")
	check(lock.hits == 0 and lock.health == lock.max_health, "it never hits, so takes no Thorns")
	sim._heal(5.0, "lifesteal")
	check(sim.health == start, "no Lifesteal")
	var clean := _place(sim, "basic", 50.0)
	sim._kill(clean)
	check(sim.health == start, "no growth from a kill")
	for _i in range(50):
		sim._pay_wave_end()
	check(sim.health == start, "no Recovery Package")
	sim._raise("health")
	check(sim.health > start, "but bought Health still lands")
	# Knocked back off its spot, it frees the Number until it walks back.
	lock.distance = 40.0
	sim._enemies_hit()
	var held := sim.health
	sim._heal(1.0, "regen")
	check(not sim.locked and sim.health > held, "knocked out of place, it lets Regen back")
	lock.distance = 20.0
	sim._enemies_hit()
	check(sim.locked, "and holds again once back in place")
	var cash := sim.cash
	sim._kill(lock)
	check_near(sim.cash - cash, EnemyKinds.cash(lock, sim.stat("cash_bonus")), 0.0, "killed, it pays as a basic")
	check_near(EnemyKinds.cash(lock, 1.0), TowerData.kill_cash(lock.wave), 0.0, "which is a basic's Cash")
	sim._enemies_hit()
	check(not sim.locked, "and the Number is free once it's gone")
	# Beside a Vampire, which lets packages through, the Lock still stops them.
	var both := _quiet_sim({}, BattleSim.START_GROUPS + ["recovery_packages"])
	both.levels["package_chance"] = TowerData.max_level("package_chance")
	var vampire := _place(both, "vampire", 20.0)
	vampire.stop_at = 20.0
	both.health = both.max_health()
	both._enemies_hit()
	var drained := both.health
	both.record_events = true
	for _i in range(20):
		both._pay_wave_end()
	check(both.health > drained, "a Vampire alone lets packages land, as The Tower's does")


## D144: the first tank comes on wave 5, in one basic's place: the wave's
## size and every other enemy, the Divider's pick included, are as without it.
func test_the_first_tank_comes_on_wave_5() -> void:
	check(Guesses.TANK_INTRO_WAVE == 5, "the first tank's wave is 5")
	for seed in range(1, 21):
		var sim := BattleSim.new(seed)
		var plain := BattleSim.new(seed)
		plain.tank_intro = 0
		for at_wave in range(2, 9):
			for each in [sim, plain]:
				each.wave = at_wave
				each.spawns.schedule_wave()
			var ours: Array = sim.spawns.schedule
			var theirs: Array = plain.spawns.schedule
			check(ours.size() == theirs.size(), "seed %d wave %d: the same number of enemies" % [seed, at_wave])
			var changed := []
			for index in range(ours.size()):
				if ours[index] != theirs[index]:
					changed.append(index)
			if at_wave != 5:
				check(changed.is_empty(), "seed %d wave %d: untouched" % [seed, at_wave])
			elif theirs.any(func(entry): return entry.kind == "basic"):
				check(changed.size() == 1 and theirs[changed[0]].kind == "basic" and ours[changed[0]].kind == "tank"
					and float(ours[changed[0]].at) == float(theirs[changed[0]].at), "seed %d: one basic became a tank, at its time" % seed)
	# Spawned, it is The Tower's tank, from the direction its basic would have come.
	var sim := BattleSim.new(3)
	var plain := BattleSim.new(3)
	plain.tank_intro = 0
	for each in [sim, plain]:
		each.wave = 5
		each.spawns.schedule_wave()
		each.wave_clock = 999.0
		each.spawns.spawn_due()
	var tanks := sim.enemies.filter(func(enemy): return enemy.kind == "tank")
	check(tanks.size() == 1 and tanks[0].max_health == sim.enemy_health_now("tank") and tanks[0].speed == EnemyKinds.speed_m("tank", 5, 1, sim.divider), "it walks in as The Tower's tank")
	var same := true
	for index in range(sim.enemies.size()):
		same = same and sim.enemies[index].angle == plain.enemies[index].angle
	check(same, "and every enemy comes from the same direction as without it")
	check(ArenaView.LOOKS.tank.size == 22 and ArenaView.LOOKS.tank.has("glow"), "the tank is drawn heavier, with a glow")
	check(BattleScreen.FIRST_SIGHT.has("tank"), "and is explained the first time it's met")
	var screen = BattleScreen.new()
	screen.workshop = Workshop.new()
	root.add_child(screen)
	screen.set_process(false)
	screen.sim.wave = 40
	for kind in ["lock", "tank"]:
		var met := BattleSim.Enemy.new()
		met.kind = kind
		screen.sim.enemies.append(met)
	screen._first_sight(0.0)
	check(screen._sight.visible and screen._sight_text.text.begins_with("Lock") and screen._sighted == ["lock"], "two new kinds at once: the first card shows")
	screen._first_sight(0.0)
	check(screen._sight_text.text.begins_with("Lock"), "and stays until it's gone")
	screen._first_sight(BattleScreen.FIRST_SIGHT_SECONDS + 0.1)
	screen._first_sight(0.0)
	check(screen._sight.visible and screen._sight_text.text.begins_with("Tank"), "then the second's")
	screen.free()


## D145: the base enemies each read as ours. The tank thins as it's shot but
## keeps its weight (D154), so Knockback never throws it like a basic; the
## fast one trails its number; the boss is a rival Number with a card and the wave line; a landed ÷ peels
## the Number it cut away.
func test_the_base_enemies_read_as_ours() -> void:
	var sim := _quiet_sim()
	sim.wave = 10
	var tank := _place(sim, "tank", 50.0)
	var basic := _place(sim, "basic", 50.0)
	var full := EnemyKinds.mass_now(tank, sim.wave)
	check_near(full, TowerData.mass_ratio("tank"), 0.0001, "a fresh tank weighs The Tower's tank")
	tank.health = tank.max_health * 0.01
	check_near(EnemyKinds.mass_now(tank, sim.wave), full, 0.0001, "and nearly dead, it weighs just the same (D154)")
	basic.health = basic.max_health * 0.5
	check_near(EnemyKinds.mass_now(basic, sim.wave), 1.0, 0.0001, "a basic weighs the same however shot")
	var boss := _place(sim, "boss", 50.0)
	boss.health = boss.max_health * 0.5
	check_near(EnemyKinds.mass_now(boss, sim.wave), TowerData.mass_ratio("boss"), 0.0001, "and so does a boss")
	# Knockback reads it: a worn tank goes no further than a fresh one.
	for share in [1.0, 0.1]:
		var pushed := _quiet_sim()
		pushed.levels = {"knockback_chance": TowerData.max_level("knockback_chance"), "knockback_force": 10}
		var shot := _place(pushed, "tank", 20.0)
		shot.max_health = 1e9
		shot.health = 1e9 * share
		for _i in range(roundi(10.0 / BattleSim.TICK)):
			pushed.step()
			if shot.distance > 20.0:
				break
		var want: float = pushed.stat("knockback_force") * Guesses.KNOCKBACK_METRES_PER_FORCE / TowerData.mass_ratio("tank")
		check_near(shot.distance - 20.0, want, 0.001, "a tank at %d%% health goes %.2f m back" % [roundi(share * 100.0), want])
	tank.health = tank.max_health
	check(ArenaView.tank_weight_step(tank) == ArenaView.TANK_WEIGHTS.size() - 1, "a fresh tank is drawn at its heaviest")
	tank.health = tank.max_health * 0.5
	check(ArenaView.tank_weight_step(tank) == 2, "half shot, in the middle weight")
	tank.health = tank.max_health * 0.05
	check(ArenaView.tank_weight_step(tank) == 0, "nearly dead, at its lightest")
	var fast := _place(sim, "fast", 50.0)
	check(ArenaView.shows_trail(fast, {"shown": "full"}), "a fast enemy written in full trails its number")
	check(not ArenaView.shows_trail(fast, {"shown": "sign"}) and not ArenaView.shows_trail(basic, {"shown": "full"}), "not as a crowd dot, and no other kind does")
	fast.distance = fast.stop_at
	check(not ArenaView.shows_trail(fast, {"shown": "full"}), "nor once it stands at the Number")
	check(ArenaView.LOOKS.boss.get("number_font", false), "the boss is drawn in the Number's own font")
	check(BattleScreen.FIRST_SIGHT.has("boss"), "and is explained the first time it's met")
	check(BattleScreen.wave_title(sim) == "Wave 10 · Boss  ›", "the wave line names it while it lives: %s" % BattleScreen.wave_title(sim))
	sim._kill(boss)
	check(BattleScreen.wave_title(sim) == "Wave 10  ›", "and not once it's dead")
	var arena := ArenaView.new()
	var divider := BattleSim.Enemy.new()
	divider.kind = "divider"
	arena.absorb([{"type": "divided", "enemy": divider, "damage": 10.0, "at_wall": false, "divisor": 1.5, "before": 30.0}], 0.0)
	check(arena.effects.peels.size() == 1 and is_equal_approx(arena.effects.peels[0].value, 30.0), "a landed ÷ peels away the Number as it stood")
	arena.absorb([{"type": "divided", "enemy": divider, "damage": 5.0, "at_wall": true, "divisor": 1.5, "before": 20.0}], 0.0)
	check(arena.effects.peels.size() == 1, "but not one the Wall took")
	arena.absorb([], ArenaEffects.PEEL_SECONDS + 0.01)
	check(arena.effects.peels.is_empty(), "and it's gone once it has fallen")
	arena.free()
	var cut := _quiet_sim()
	cut.health = 30.0
	var landing := _place(cut, "divider", 1.0)
	landing.divisor = 1.5
	cut.record_events = true
	cut._divide(landing)
	var event: Dictionary = cut.events.filter(func(item): return item.type == "divided")[0]
	check_near(float(event.before), 30.0, 0.0001, "the sim tells the screen what the Number stood at")


## The card test series' candidates (docs/CARDS.md): each rule acts only
## with its card's effect, and none is ever drawn.
func test_candidate_cards_act_only_when_equipped() -> void:
	for id in Cards.CANDIDATES:
		check(Cards.candidate(id) and not Cards.built(id) and id not in Cards.built_ids(), "%s is measured, never drawn" % id)
	check(CardsScreen.describe("interest", 1) == "+25" and CardsScreen.describe("remainder", 1) == "×0.85" and CardsScreen.describe("slow_aura", 7) == "+31%",
		"candidates read as cards do: %s" % CardsScreen.describe("interest", 1))
	# Slow Aura: inside Range only.
	for slow in [0.0, 0.13]:
		var sim := _quiet_sim()
		if slow > 0.0:
			check(sim.rules.add(Cards.effects_at("slow_aura", 1)[0]), "Slow Aura is a valid rule")
		var near := _place(sim, "basic", sim.stat("range") - 1.0)
		var far := _place(sim, "basic", sim.stat("range") + 20.0)
		near.speed = 5.0
		far.speed = 5.0
		var near_from := near.distance
		var far_from := far.distance
		sim._move_enemies()
		check_near(near_from - near.distance, 5.0 * BattleSim.TICK * (1.0 - slow), 1e-9, "inside Range an enemy walks %d%% slower" % roundi(slow * 100.0))
		check_near(far_from - far.distance, 5.0 * BattleSim.TICK, 1e-9, "outside it, at full speed")
	# Compound: a clean kill grows the Number by more.
	for level in [0, 7]:
		var sim := _quiet_sim()
		if level > 0:
			sim.rules.add(Cards.effects_at("compound", level)[0])
		var before := sim.health
		var clean := _place(sim, "basic", 20.0)
		sim._kill(clean)
		check_near(sim.health - before, clean.attack * sim.kill_share * (4.0 if level > 0 else 1.0), 1e-9, "a clean kill grows the Number ×%s" % ("4" if level > 0 else "1"))
	# Remainder: a ÷ takes less.
	var plain := _quiet_sim()
	plain.health = 300.0
	var softened := _quiet_sim()
	softened.health = 300.0
	softened.rules.add(Cards.effects_at("remainder", 7)[0])
	check_near(softened.divide_loss(1.5), plain.divide_loss(1.5) * 0.5, 1e-9, "Remainder at its last level halves what a ÷1.5 takes: %s" % softened.divide_loss(1.5))
	# Unequal: shots hit a Lock harder, and nothing else.
	for id in ["", "unequal"]:
		var sim := _quiet_sim()
		if id != "":
			sim.rules.add(Cards.effects_at(id, 3)[0])
		var lock := _place(sim, "lock", 20.0)
		lock.max_health = 1e9
		lock.health = 1e9
		var basic := _place(sim, "basic", 20.0)
		basic.max_health = 1e9
		basic.health = 1e9
		sim._strike(lock, 10.0, false)
		sim._strike(basic, 10.0, false)
		check_near(1e9 - lock.health, 10.0 * (3.0 if id != "" else 1.0), 1e-6, "a Lock takes ×%s" % ("3" if id != "" else "1"))
		check_near(1e9 - basic.health, 10.0, 1e-6, "a basic takes the shot as it was")
	# Critical Coin: a basic killed by a critical shot drops Coins.
	for chance in [0.0, 1.0]:
		var sim := _quiet_sim()
		if chance > 0.0:
			sim.rules.add({"domain": "rule", "stat": "critical_coin", "op": "add", "value": chance, "source": "card:critical_coin"})
		var basic := _place(sim, "basic", 20.0)
		var tank := _place(sim, "tank", 20.0)
		var before := sim.coins
		var stream: int = sim._combat_rng.state
		sim._strike(basic, basic.health * 2.0, true)
		check((sim._combat_rng.state == stream) == (chance == 0.0), "the combat stream moves only with the card")
		var dropped := sim.coins - before
		check_near(dropped, Guesses.CRITICAL_COIN_COINS * sim.stat("coins_per_kill") if chance > 0.0 else 0.0, 1e-9, "a critical kill of a basic drops %s Coins" % dropped)
		before = sim.coins
		sim._strike(tank, tank.health * 2.0, true)
		check_near(sim.coins - before, EnemyKinds.coins(tank, sim.wave, sim.stat("coins_per_kill"), sim.tier), 1e-9, "a tank pays only its own")
	# Remainder softens a ÷ at the Wall too.
	var walled := _quiet_sim()
	walled.rules.add(Cards.effects_at("remainder", 7)[0])
	check_near(walled.divide_share(1.5), (1.0 - 1.0 / 1.5) * 0.5, 1e-9, "one share for the Number and the Wall")
	# Factor: a boss arrives with less health; nothing else does.
	for id in ["", "factor"]:
		var sim := _quiet_sim()
		sim.wave = 10
		if id != "":
			sim.rules.add(Cards.effects_at(id, 1)[0])
		sim._place("boss", 0.0)
		sim._place("basic", 1.0)
		var boss: BattleSim.Enemy = sim.enemies.filter(func(e): return e.kind == "boss")[0]
		var basic: BattleSim.Enemy = sim.enemies.filter(func(e): return e.kind == "basic")[0]
		check_near(boss.max_health, sim.enemy_health_now("boss") * (0.7 if id != "" else 1.0), 1e-6, "a boss arrives with ×%s health" % ("0.7" if id != "" else "1"))
		check(boss.health == boss.max_health and basic.max_health == sim.enemy_health_now("basic"), "full of it, and a basic unchanged")
	# Interest raises the cap on what interest pays.
	var capped := _quiet_sim()
	capped.rules.add(Cards.effects_at("interest", 1)[0])
	check_near(capped.rules.value("interest_cap"), BattleSim.INTEREST_CAP + 25.0, 1e-9, "Interest lifts the cap by $25")
	# A candidate equipped by any path never reaches a real run.
	var cards := Cards.new()
	cards.copies = {"slow_aura": 1}
	cards.equipped.assign(["slow_aura"])
	check(cards.effects().is_empty(), "an equipped candidate adds nothing to a run")


## Berserker and Super Tower (candidate cards, docs/CARDS.md): each raises the
## Damage of a shot only with its card, and rolls nothing.
func test_berserker_and_super_tower_candidates() -> void:
	check(CardsScreen.describe("berserker", 1) == "+0.8%" and CardsScreen.describe("super_tower", 7) == "×5.00",
		"they read as cards do: %s, %s" % [CardsScreen.describe("berserker", 1), CardsScreen.describe("super_tower", 7)])
	# Berserker: a share of what the Number has absorbed, added to each shot.
	var plain := _quiet_sim()
	var berserk := _quiet_sim()
	berserk.rules.add(Cards.effects_at("berserker", 1)[0])
	for sim in [plain, berserk]:
		sim.lost_to = {"basic": 600.0, "ranged": 400.0, "divider": 5000.0}
	check_near(berserk.damage_absorbed(), 1000.0, 1e-9, "a Divider's ÷ divides the Number; it isn't damage absorbed")
	check_near(plain.berserker_bonus(), 0.0, 0.0, "no card, no bonus")
	check_near(berserk.berserker_bonus(), 8.0, 1e-9, "level 1 adds 0.8%% of what was absorbed: %s" % berserk.berserker_bonus())
	berserk.lost_to = {"basic": 1e9}
	check_near(berserk.berserker_bonus(), 8.0 * berserk.stat("damage"), 1e-9, "the bonus stops at 8 times the tower's Damage")
	berserk.lost_to = {"basic": 600.0}
	for sim in [plain, berserk]:
		sim._shot_charge = 1.0
		_place(sim, "basic", 5.0)
		sim._fire()
		check(sim.shots.size() == 1, "the tower fires")
		var shot: BattleSim.Shot = sim.shots[0]
		var bonus := 4.8 if sim == berserk else 0.0
		check_near(shot.damage, (sim.stat("damage") + bonus) * (sim.stat("critical_factor") if shot.critical else 1.0), 1e-9,
			"a shot carries Berserker's bonus (%s) before a critical: %s" % [bonus, shot.damage])
	# Super Tower: ×N for 15 s, off for 15, ready as the run begins; neither it
	# nor Berserker touches the combat stream or, without a card, the cooldowns.
	for level in [1, 7]:
		var sim := _quiet_sim()
		sim.rules.add(Cards.effects_at("super_tower", level)[0])
		var stream: int = sim._combat_rng.state
		var boosts: Array[float] = []
		for tick in range(1800):
			sim._tick_super_tower()
			boosts.append(sim.super_tower_boost())
		var want := 2.5 if level == 1 else 5.0
		check(sim._combat_rng.state == stream, "Super Tower rolls nothing")
		check(boosts.slice(0, 450).all(func(each): return each == want), "×%s from the first tick for 15 seconds" % want)
		check(boosts.slice(450, 900).all(func(each): return each == 1.0), "then off for 15 more")
		check(boosts.slice(900, 1350).all(func(each): return each == want) and boosts.slice(1350).all(func(each): return each == 1.0),
			"and the same again from second 30: ×%s then off" % want)
	var without := _quiet_sim()
	for tick in range(100):
		without._tick_super_tower()
	check(without.cooldowns.remaining.is_empty() and without.super_tower_boost() == 1.0, "without the card there is no cooldown and no boost")
	# Both together, in a shot: (Damage + bonus) × the burst, then a critical.
	var both := _quiet_sim()
	both.rules.add(Cards.effects_at("berserker", 7)[0])
	both.rules.add(Cards.effects_at("super_tower", 7)[0])
	both.lost_to = {"basic": 1000.0}
	both._tick_super_tower()
	both._shot_charge = 1.0
	_place(both, "basic", 5.0)
	both._fire()
	var shot: BattleSim.Shot = both.shots[0]
	check_near(shot.damage, (both.stat("damage") + 14.0) * 5.0 * (both.stat("critical_factor") if shot.critical else 1.0), 1e-9,
		"the two stack: %s" % shot.damage)


## D133: the Lock comes on a fixed beat on top of The Tower's wave; with it
## every Tower enemy, and the Divider, is exactly as without it.
func test_a_lock_comes_on_top_of_the_towers_wave() -> void:
	var lock: Dictionary = Guesses.LOCK
	var waves: Array[int] = []
	for at_wave in range(1, 81):
		if EnemyKinds.lock_comes(lock, at_wave):
			waves.append(at_wave)
	check(waves[0] == 35, "the first comes on wave 35, after Labs: %s" % [waves])
	check(waves.slice(0, 9) == [35, 38, 41, 44, 47, 50, 53, 56, 59], "every third wave until wave 60: %s" % [waves])
	check(waves.slice(9, 12) == [60, 62, 64] and waves[-1] == 80, "then every other: %s" % [waves])
	check(EnemyKinds.lock_waits(lock, 30) == 5 and EnemyKinds.lock_waits(lock, 36) == 2 and EnemyKinds.lock_waits(lock, 61) == 1, "Wave Info can say how long until the next")
	check(EnemyKinds.lock_waits({"from_wave": 0, "every_first": 3, "full_wave": 60, "every_full": 2}, 50) == -1, "from wave 0 there are none")
	var sim := BattleSim.new(8)
	var plain := BattleSim.new(8)
	plain.lock.from_wave = 0
	for at_wave in range(30, 71):
		for each in [sim, plain]:
			each.wave = at_wave
			each.spawns.schedule_wave()
		var locks := sim.spawns.schedule.filter(func(entry): return entry.kind == "lock")
		check(locks.size() == (1 if EnemyKinds.lock_comes(lock, at_wave) else 0), "wave %d: one Lock on its beat, else none" % at_wave)
		var rest := sim.spawns.schedule.filter(func(entry): return entry.kind != "lock")
		check(rest == plain.spawns.schedule, "wave %d: every other enemy, Dividers too, comes as without it" % at_wave)
	for each in [sim, plain]:
		each.enemies.clear()
		each.wave = 35
		each.spawns.schedule_wave()
		each.wave_clock = 999.0
		each.spawns.spawn_due()
	var others := sim.enemies.filter(func(enemy): return enemy.kind != "lock")
	check(others.size() == plain.enemies.size() and sim.enemies.size() == plain.enemies.size() + 1, "a Lock's wave sends one more")
	var same_directions := true
	for index in range(others.size()):
		same_directions = same_directions and others[index].angle == plain.enemies[index].angle and others[index].kind == plain.enemies[index].kind
	check(same_directions, "and every other enemy comes from the same direction")
	var again := BattleSim.new(8)
	again.wave = 35
	again.spawns.schedule_wave()
	check(again.spawns.schedule.filter(func(entry): return entry.kind == "lock") == sim.spawns.schedule.filter(func(entry): return entry.kind == "lock"),
		"the same seed and wave bring the same Lock, with nothing saved")
	# It counts against the normal cap, as any normal enemy does.
	var full := _quiet_sim()
	for _i in range(TowerData.enemy_cap()):
		_place(full, "basic", 90.0)
	full.spawns.schedule = [{"kind": "lock", "at": 0.0, "angle": 0.0}]
	full.spawns.next_spawn = 0
	full.wave_clock = 0.0
	full.spawns.spawn_due()
	check(full.spawns.wave_missed == 1 and not full.enemies.any(func(enemy): return enemy.kind == "lock"), "a full field turns a Lock away")
	var info := BattleSim.new(8)
	info.wave = 33
	var rows: Array = info.spawns.wave_info().rows.filter(func(row): return row.kind == "lock")
	check(rows.size() == 1 and rows[0].waits == 2 and rows[0].chance == 0.0, "Wave Info shows the Lock coming in two waves: %s" % [rows])
	info.wave = 20
	check(info.spawns.wave_info().rows.all(func(row): return row.kind != "lock"), "and nothing of it long before")


## D133: the Lock shows =, Wave Info says what it does, and the first time a
## player meets one, past their best wave, a card says so once.
func test_a_lock_shows_its_sign_and_is_explained_once() -> void:
	var sim := _quiet_sim()
	var lock := _place(sim, "lock", 20.0)
	check(ArenaView.shown_text(sim, lock) == "=", "a Lock shows = on its body: %s" % ArenaView.shown_text(sim, lock))
	check(ArenaView.LOOKS.lock.colour == Palette.LOCK and ArenaView.LABEL_RANK.lock == 0, "in its own colour, written in full in a crowd as a Divider is")
	check(WaveInfo._attack_text({"kind": "lock", "attack": 0.0}) == "holds" and WaveInfo._chance({"kind": "lock", "chance": 0.0, "waits": 2, "second": 0.0}) == "0%, in 2",
		"Wave Info says it holds, and how many waves until one")
	var screen = BattleScreen.new()
	screen.workshop = Workshop.new()
	screen.workshop.best_wave = 34
	root.add_child(screen)
	screen.set_process(false)
	screen.sim.wave = 35
	screen._first_sight(0.0)
	check(not screen._sight.visible, "no card before a Lock is on the field")
	var first := BattleSim.Enemy.new()
	first.kind = "lock"
	screen.sim.enemies.append(first)
	screen._first_sight(0.0)
	check(screen._sight.visible and screen._sight_sign.text == "=" and screen._sight_text.text.contains("can't go up"), "the first Lock past the best wave brings its card")
	screen._first_sight(BattleScreen.FIRST_SIGHT_SECONDS + 0.1)
	check(not screen._sight.visible, "which goes away on its own")
	screen._first_sight(0.0)
	check(not screen._sight.visible, "and doesn't come back the same run")
	screen._adopt(BattleSim.new(3))
	screen.sim.wave = 35
	screen.sim.enemies.append(first)
	screen.workshop.best_wave = 40
	screen._first_sight(0.0)
	check(not screen._sight.visible, "a player who has been past it before isn't told again")
	screen.free()


## D134, a measuring option: what a Divider takes, Regen gives back only over
## `refill_seconds` from the last bite, whatever the Regen; two bites add up.
func test_a_dividers_bite_comes_back_slowly() -> void:
	check(float(Guesses.DIVIDER.refill_seconds) == 0.0, "the game keeps the old rule: it moved no wall")
	var sim := _quiet_sim({"health": 400})
	sim.divider.refill_seconds = 10.0
	var best := sim.max_health()
	sim.health = best
	_place(sim, "divider", Guesses.CONTACT_DISTANCE_M)
	sim.step()
	var bite := best * 0.2
	check_near(sim.divider_held, bite, 0.0001, "a ÷1.25 bite holds back the fifth it took")
	sim._heal(1e9, "regen")
	check_near(sim.health, best - bite, 0.0001, "however strong the Regen, it can't refill that at once")
	sim._heal(5.0, "lifesteal")
	check_near(sim.health, best - bite + 5.0, 0.0001, "Lifesteal still lands")
	sim.health = best - bite
	var seconds := float(sim.divider.refill_seconds)
	for tick in range(roundi(seconds * 0.5 / BattleSim.TICK) - 1):
		sim.step()
		sim._heal(1e9, "regen")
	check_near(sim.health, best - bite * 0.5, best * 0.001, "half of it after five seconds: %.1f of %.1f" % [sim.health, best])
	_place(sim, "divider", Guesses.CONTACT_DISTANCE_M)
	var before := sim.health
	sim.step()
	var second := before / 5.0
	check_near(sim.divider_held, bite * 0.5 + second, best * 0.001, "a second bite adds to what's still held")
	for tick in range(roundi(seconds / BattleSim.TICK)):
		sim.step()
		sim._heal(1e9, "regen")
	check(sim.divider_held == 0.0 and is_equal_approx(sim.health, best), "and ten seconds after the last, it's all back")
	var old := _quiet_sim({"health": 400})
	old.divider.refill_seconds = 0.0
	old.health = old.max_health()
	_place(old, "divider", Guesses.CONTACT_DISTANCE_M)
	old.step()
	old._heal(1e9, "regen")
	check(old.divider_held == 0.0 and is_equal_approx(old.health, old.max_health()), "a refill of 0 is the old rule: Regen puts it straight back")


## The Number-as-capital trial (D152, THE_NUMBER.md section 10): measuring
## options, off in the game.
func test_the_trial_is_off_and_leaves_no_trace() -> void:
	var sim := BattleSim.new(1)
	check(not sim.thieves and not sim.thief_priority and sim.thief_recovery == 0.0 and sim.thief_speed == 1.0 \
			and sim.thief_fade == 0.0 and sim.number_power == 0.0, "the game plays none of the trial")
	check(not sim.trial_active() and sim.number_boost() == 1.0, "and its power on the shots is neutral")
	check(not sim.tuning_config().has("thieves") and not sim.tuning_config().has("number_power"), "a run records none of its options while they are off")
	sim.thieves = true
	sim.number_power = 0.2
	var recorded := sim.tuning_config()
	check(recorded.thieves == true and recorded.number_power == 0.2 and not recorded.has("thief_speed"), "and only the ones that are on")


func test_a_thief_carries_its_bite_and_damage_pays_it_back() -> void:
	var sim := _thief_sim(1.0)
	var best := sim.health
	var thief := _steal(sim)
	var bite := best * 0.2
	check(sim.enemies.has(thief) and thief.fleeing and thief.health > 0.0, "a Divider that lands isn't used up: it flees with its bite")
	check_near(thief.carried, bite, 0.0001, "carrying the fifth it took")
	check(sim.thefts == 1 and is_equal_approx(sim.thief_taken, bite) and sim.dividers_landed == 1, "and the ledger has the theft")
	check_near(sim.health, best - bite, 0.0001, "the Number is down by it")
	sim._heal(1e9, "regen")
	check_near(sim.health, best - bite, 0.0001, "and Regen can't refill what a thief is carrying")
	sim.deal_damage(thief, thief.health * 0.5, "shot")
	check_near(sim.health, best - bite * 0.5, 0.0001, "half its health in damage pays half the bite back")
	check_near(sim.thief_held, bite * 0.5, 0.0001, "and frees that half of the hold")
	var kills := sim.kills
	sim.deal_damage(thief, 1e9, "shot")
	check(sim.kills == kills + 1 and not sim.enemies.has(thief), "killing it ends the flight, paid like any kill")
	check_near(sim.health, best, 0.0001, "the rest comes back, and overkill pays nothing more")
	check(sim.thief_held == 0.0 and is_equal_approx(sim.thief_recovered, bite), "with nothing held and the ledger square")
	check(sim.thieves_escaped == 0 and sim.thief_escaped == 0.0, "and no one got away")


## Recovery is what Labs raise: weak, it leaves a scar Regen can't fill; past
## 1, the Number lands above where it was.
func test_recovery_starts_weak_and_labs_can_take_it_past_whole() -> void:
	var weak := _thief_sim(0.5)
	var best := weak.health
	var bite := best * 0.2
	weak.deal_damage(_steal(weak), 1e9, "shot")
	check_near(weak.health, best - bite * 0.5, 0.0001, "a recovery of 0.5 returns half the bite on a kill")
	weak._heal(1e9, "regen")
	check_near(weak.health, best - bite * 0.5, 0.0001, "and Regen can't refill the other half: it stays held")
	check_near(weak.thief_held, bite * 0.5, 0.0001, "held, not gone")
	var rich := _thief_sim(1.5)
	rich.deal_damage(_steal(rich), 1e9, "shot")
	check_near(rich.health, best + bite * 0.5, 0.0001, "a recovery of 1.5 puts the Number above where it was")
	check(rich.thief_held == 0.0 and rich.raised_by.get("recovery", 0.0) > 0.0, "the extra counts as a new high from recovery")
	var none := _thief_sim(0.0)
	none.deal_damage(_steal(none), 1e9, "shot")
	check_near(none.health, best - bite, 0.0001, "and a recovery of 0 returns nothing")


func test_a_thief_that_gets_away_keeps_the_bite() -> void:
	var sim := _thief_sim(1.0)
	var best := sim.health
	var thief := _steal(sim, 1e12)
	thief.speed = 40.0
	var bite := thief.carried
	sim.deal_damage(thief, 4e11, "shot")
	check_near(sim.health, best - bite * 0.6, 0.001, "damage before it leaves pays its share back")
	var kills := sim.kills
	for _i in range(roundi(5.0 / BattleSim.TICK)):
		sim.step()
	check(not sim.enemies.has(thief) and sim.thieves_escaped == 1, "it walks out to where enemies set off and is gone")
	check_near(sim.thief_escaped, bite * 0.6, 0.001, "with the 60% it still held")
	check(sim.kills == kills and thief.health == 0.0, "unpaid, and no longer a target for shots already flying")
	check_near(sim.thief_held, bite * 0.6, 0.001, "and with no fade the loss stays out of Regen's reach")
	var fading := _thief_sim(1.0)
	fading.thief_fade = 10.0
	var holder := _steal(fading, 1e12)
	var held := holder.carried
	for _i in range(roundi(5.0 / BattleSim.TICK)):
		fading.step()
	check_near(fading.thief_held, held * 0.5, held * 0.02, "with a fade it is released evenly: half after half the time")
	for _i in range(roundi(5.5 / BattleSim.TICK)):
		fading.step()
	check(fading.thief_held == 0.0, "and all of it after the fade")
	fading._heal(1e9, "regen")
	check_near(fading.health, best, 0.0001, "so Regen can refill it")


func test_a_bite_the_wall_took_is_not_carried() -> void:
	var sim := _thief_sim(1.0, BattleSim.START_GROUPS + ["wall"])
	var wall := sim.defences.wall_health
	var divider := _place(sim, "divider", Guesses.WALL_DISTANCE_M)
	sim.step()
	check_near(sim.defences.wall_health, wall / 1.25, 0.0001, "the Wall loses what the Number would")
	check(not divider.fleeing and not sim.enemies.has(divider) and sim.thefts == 0, "and the Divider is used up as before: nothing was taken to carry")
	var sure := _thief_sim(1.0)
	sure.sure_from = 1
	sure.sure_every = 1
	sure.wave_clock = BattleSim.SURE_LANDS_AT
	sure.step()
	check(sure.dividers_landed == 1 and sure.thefts == 0 and sure.enemies.is_empty(), "nor is the measuring Divider's, which was never on the field")


## Thorns is the blender's answer to a thief: it hurts the carrier as it grabs,
## as it does any enemy on contact, and the damage pays the bite back.
func test_a_thief_takes_thorns_as_it_grabs() -> void:
	var sim := _thief_sim(1.0)
	sim.levels = {"health": 400, "thorns": 50}
	var best := sim.health
	var bite := best * 0.2
	var share := TowerData.value("thorns", 50)
	var thief := _steal(sim, 1e12)
	check_near(thief.health, 1e12 * (1.0 - share), 1e3, "Thorns hurts a thief as it grabs, by its share of the thief's own health")
	check_near(sim.health, best - bite + bite * share, 0.001, "and that share of the bite comes straight back")
	var weak := _thief_sim(1.0)
	weak.levels = {"health": 400, "thorns": 50}
	var frail := _place(weak, "divider", Guesses.CONTACT_DISTANCE_M)
	frail.max_health = 100.0
	frail.health = 1.0
	weak.step()
	check(not weak.enemies.has(frail) and weak.kills == 1 and weak.thefts == 1, "a thief Thorns can finish dies on the spot")
	check_near(weak.health, best, 0.001, "and the whole bite is back")
	var plain := _quiet_sim({"health": 400})
	plain.levels = {"health": 400, "thorns": 50}
	_place(plain, "divider", Guesses.CONTACT_DISTANCE_M)
	plain.step()
	check(not plain.damage_by.has("thorns") and plain.thefts == 0, "without the trial a landing Divider is used up and takes no Thorns, as before")


func test_the_tower_shoots_carriers_first_when_told_to() -> void:
	var sim := _thief_sim(1.0)
	var carrier := _steal(sim, 1e12)
	carrier.distance = 20.0
	var basic := _place(sim, "basic", 8.0)
	check(sim._nearest_in_range() == basic and sim._in_range_nearest_first()[0] == basic, "by default the nearest comes first")
	sim.thief_priority = true
	check(sim._nearest_in_range() == carrier and sim._in_range_nearest_first()[0] == carrier, "with priority a carrier does, though it is farther")


func test_nothing_pushes_a_thief_further_out() -> void:
	var sim := _thief_sim(1.0, BattleSim.START_GROUPS + ["knockback", "shockwave"])
	sim.levels = {"health": 400, "knockback_chance": TowerData.max_level("knockback_chance"), "knockback_force": 10}
	sim.record_events = true
	var thief := _steal(sim, 1e12)
	var start := thief.distance
	var control := _place(sim, "basic", 20.0)
	control.max_health = 1e12
	control.health = 1e12
	while sim.events.filter(func(event): return event.type == "shockwave").is_empty():
		sim.step()
	check(thief.health < thief.max_health, "the tower shoots the thief")
	check_near(thief.distance, start, 0.0, "yet neither Knockback nor a Shockwave moves it: they would only help it escape")
	check(control.distance > 20.0, "while the same shocks do push an ordinary enemy")


func test_the_number_powers_the_towers_shots() -> void:
	var sim := _quiet_sim({"health": 400})
	sim.number_power = 0.5
	sim.health = 500.0
	check_near(sim.number_boost(), 10.0, 1e-9, "a Number of 500 over The Tower's 5, to the power one half, is ×10")
	sim.health = 2.0
	check(sim.number_boost() == 1.0, "never under 1")
	sim.health = 500.0
	var target := _place(sim, "basic", 20.0)
	target.max_health = 1e12
	target.health = 1e12
	sim._shot_charge = 1.0
	sim._fire()
	var shot: BattleSim.Shot = sim.shots[0]
	var want := sim.stat("damage") * 10.0 * (sim.stat("critical_factor") if shot.critical else 1.0)
	check_near(shot.damage, want, 1e-6, "a shot leaves ten times as strong")
	sim.number_power = 0.0
	check(sim.number_boost() == 1.0, "and nothing changes at 0, the game's")


## A quiet sim with the trial's thieves on at `recovery` and its Number full.
func _thief_sim(recovery: float, groups: Array = BattleSim.START_GROUPS) -> BattleSim:
	var sim := _quiet_sim({"health": 400}, groups)
	sim.thieves = true
	sim.thief_recovery = recovery
	sim.health = sim.max_health()
	return sim


## A Divider lands on `sim`'s Number and becomes a carrier, in one step. With a
## `health`, it has that much when it grabs the bite.
func _steal(sim: BattleSim, health := -1.0) -> BattleSim.Enemy:
	var thief := _place(sim, "divider", Guesses.CONTACT_DISTANCE_M)
	if health > 0.0:
		thief.max_health = health
		thief.health = health
	sim.step()
	return thief


## A Ray charges 30 seconds, then fires its attack, twice a basic's, and
## charges again.
func test_ray_charges_between_shots() -> void:
	var sim := _quiet_sim()
	sim.health = 1e9
	var ray := _place(sim, "ray", 20.0)
	ray.stop_at = 20.0
	check_near(ray.attack / sim.enemy_attack_now("basic"), 2.0, 0.0001, "a Ray hits for twice a basic enemy")
	var charge := float(TowerData.enemies().elites.ray_charge_seconds)
	for tick in range(roundi(charge / BattleSim.TICK) - 2):
		sim._enemies_hit()
	check(ray.hits == 0, "no shot while it charges")
	for tick in range(4):
		sim._enemies_hit()
	check(ray.hits == 1, "then one")
	for tick in range(roundi(charge / BattleSim.TICK) - 4):
		sim._enemies_hit()
	check(ray.hits == 1, "and none for another charge")


## A Scatter splits in two with half its health, four times over: 31 kills.
func test_scatter_splits_four_times() -> void:
	var sim := _quiet_sim()
	var scatter := _place(sim, "scatter", 50.0)
	var full := scatter.max_health
	sim._kill(scatter)
	check(sim.enemies.size() == 2 and sim.enemies.all(func(piece): return piece.generation == 1 and is_equal_approx(piece.max_health, full * 0.5)),
		"two pieces with half its health")
	var kills := 1
	while not sim.enemies.is_empty():
		sim._kill(sim.enemies[0])
		kills += 1
	check(kills == 31, "four splits deep: %d kills" % kills)
	check_near(sim.coins, float(Guesses.COINS_BY_TYPE.scatter), 0.0001, "only the whole Scatter pays an elite's Coins")


## An enemy alive three waves pays half its Coins, and gets 4% heavier each
## wave it lives, so Knockback pushes it less; past wave 4,000 every enemy
## spawns heavier; and a tier speeds enemies by its weight.
func test_enemies_age_and_tiers_speed_them() -> void:
	var sim := _quiet_sim()
	sim.wave = 10
	var fresh := _place(sim, "tank", 50.0)
	var old := _place(sim, "tank", 50.0)
	old.wave = 7
	check_near(EnemyKinds.mass_now(old, sim.wave) / EnemyKinds.mass_now(fresh, sim.wave), pow(1.04, 3), 0.0001, "4% heavier for each wave alive")
	sim._kill(fresh)
	var paid := sim.coins
	sim._kill(old)
	check_near(sim.coins - paid, paid * 0.5, 0.0001, "and after three waves it pays half the Coins")
	check(TowerData.mass_growth(3999) == 1.0 and TowerData.mass_growth(5000) > 1.5, "heavier from wave 4,000")
	var first := BattleSim.new(1)
	var third := BattleSim.new(1, {}, BattleSim.START_GROUPS, 3)
	check_near(EnemyKinds.speed_m("fast", third.wave, third.tier, third.divider) / EnemyKinds.speed_m("fast", first.wave, first.tier, first.divider), 1.08, 0.0001, "Tier 3's enemies are 8% faster")


## Wave Info (D115) reads the sim: the spawn rate, what the wave sent and
## turned away, and a row for each kind.
func test_wave_info_reports_the_wave() -> void:
	var sim := BattleSim.new(5, {}, BattleSim.START_GROUPS, 2)
	sim.wave = 200
	sim.spawns.schedule_wave()
	sim.wave_clock = 0.0
	while sim.wave_clock < TowerData.spawn_seconds() - BattleSim.TICK:
		sim.wave_clock += BattleSim.TICK
		sim.spawns.spawn_due()
	var info := sim.spawns.wave_info()
	check(info.spawned + info.missed == info.due and info.due == sim.spawns.schedule.size(), "every enemy due either came or was turned away")
	check_near(float(info.spawn_rate), TowerData.spawn_rate(200), 0.0001, "the wave's spawn rate")
	var kinds: Array = info.rows.map(func(row): return row.kind)
	for kind in ["basic", "fast", "tank", "ranged", "protector", "boss", "divider", "vampire", "ray", "scatter"]:
		check(kind in kinds, "a row for %s" % kind)
	var shares := 0.0
	for row in info.rows:
		if row.kind in ["basic", "fast", "tank", "ranged", "protector"]:
			shares += float(row.chance)
	check_near(shares, 100.0, 0.001, "the normal kinds' chances make 100%")
	check(info.rows.filter(func(row): return row.kind == "boss")[0].chance == 100.0, "wave 200 is a boss wave")
	var panel := WaveInfo.new()
	panel.show_for(sim)
	check(panel._grid.get_child_count() == (info.rows.size() + 1) * WaveInfo.COLUMNS.size(), "the panel lays out a line for each kind under its headings")
	check("Wave 200 · Tier 2" in panel._title.text and ("%d of %d spawned" % [info.spawned, info.due]) in panel._spawns.text, "and names the wave and its count: %s" % panel._spawns.text)
	panel.free()


## The measuring options (sim_runs.gd) are off unless set: a Divider nothing
## can stop lands ÷1.1 once each chosen wave, and packages can be held to the
## run's best.
func test_measuring_options_only_act_when_set() -> void:
	var sim := _quiet_sim()
	check(sim.sure_from == 0 and not sim.packages_to_best, "both are off in the game")
	sim.health = 1000.0
	sim.wave = 100
	sim.wave_clock = BattleSim.SURE_LANDS_AT
	sim.step()
	check_near(sim.health, 1000.0, 0.01, "off, nothing lands")
	sim.sure_from = 100
	sim.step()
	check_near(sim.health, 1000.0 / 1.1, 0.01, "on, a ÷1.1 lands on its wave: %s" % sim.health)
	var once := sim.health
	sim.step()
	check_near(sim.health, once, 0.01, "once a wave")
	sim.wave = 101
	sim.step()
	check_near(sim.health, once, 0.01, "and only every fifth wave")
	sim.wave = 105
	sim.step()
	check(sim.health < once and sim.dividers_landed == 2, "the next lands five waves on")

	var packed := _quiet_sim()
	packed.levels["max_recovery"] = 25
	packed.peak_number = packed.max_health() * 1.5
	check_near(packed.package_ceiling(), packed.max_health() * packed.stat("max_recovery"), 0.0001, "a package overheals to Max Recovery times Health")
	packed.packages_to_best = true
	check_near(packed.package_ceiling(), packed.max_health() * 1.5, 0.0001, "held to the best, it refills only that far")


## How the Number grows (D111): regen only restores it up to the run's best,
## and a kill before the enemy lands a hit grows it by a share of its Attack.
## The Multiplier and the testing switches are gone.
func test_the_number_grows_by_fighting_not_waiting() -> void:
	var sim := _quiet_sim()
	sim.health = 10.0
	sim.peak_number = 20.0
	sim._heal(15.0, "regen")
	check_near(sim.health, 20.0, 0.0001, "regen restores up to the best and stops")
	sim.peak_drift = 0.5
	sim.health = 10.0
	sim._heal(14.0, "regen")
	check_near(sim.health, 22.0, 0.0001, "past it only at the drift's share")
	sim.peak_drift = 0.0
	sim.health = 20.0
	sim._heal(2.0, "lifesteal")
	check(sim.health > 20.0, "lifesteal still climbs past the best")

	var grower := _quiet_sim()
	var clean := BattleSim.Enemy.new()
	clean.kind = "basic"
	clean.attack = 10.0
	grower.enemies.append(clean)
	var start := grower.health
	grower._kill(clean)
	check_near(grower.health, start + 10.0 * Guesses.KILL_GROWTH, 0.0001, "a kill before it lands a hit adds a share of its Attack")
	var hitter := BattleSim.Enemy.new()
	hitter.kind = "basic"
	hitter.attack = 10.0
	hitter.hits = 1
	grower.enemies.append(hitter)
	var before := grower.health
	grower._kill(hitter)
	check_near(grower.health, before, 0.0, "one that has hit you adds nothing")
	check(float(grower.gained_from.kills) > 0.0, "and kills' growth is booked")
	var arena := ArenaView.new()
	arena.absorb([{"type": "grown", "enemy": clean, "gain": 0.75}, {"type": "grown", "enemy": hitter, "gain": 1.5}], 0.0)
	var pluses := arena.effects.floats.filter(func(item): return item.get("anchor") == "growing")
	check(pluses.size() == 1 and pluses[0].text == "+2", "a frame's kills show as one whole \"+\" by the Number: %s" % [pluses])
	arena.absorb([{"type": "grown", "enemy": clean, "gain": 0.2}], 0.0)
	check(arena.effects.floats.filter(func(item): return item.get("anchor") == "growing").size() == 1, "and less than half of one shows nothing")
	arena.free()

	var fresh := BattleSim.new(8)
	check(fresh.rng_state().size() == 3, "a run has three random streams")
	for at_wave in range(2, 41):
		fresh.wave = at_wave
		fresh.spawns.schedule_wave()
		check(fresh.spawns.schedule.all(func(entry): return entry.kind in ["basic", "fast", "tank", "ranged", "boss", "divider", "lock"]), "wave %d: no Multipliers" % at_wave)

	var played := BattleSim.new(13)
	played.run_until_dead(300.0)
	var record := _through_json(RunReport.build(played))
	check(not record.start.has("switches"), "a run's record keeps no switches")
	# A run recorded while the switches existed still loads and replays.
	record.erase("commands")
	record.start["switches"] = {"multipliers": true, "peak_regen": true, "kill_growth": true}
	var again := RunReport.Replay.new(record)
	while not again.advance(100000):
		pass
	check(RunReport.matches(record, again.sim), "one recorded with the old switches still replays, ending the same")

	DirAccess.remove_absolute(TEST_SETTINGS)
	var old := FileAccess.open(TEST_SETTINGS, FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 1, "music": false, "multipliers": true, "peak_regen": true, "kill_growth": true}))
	old.close()
	var settings := Settings.new()
	settings.read(TEST_SETTINGS)
	check(not settings.music, "a settings file with the old switches still reads")
	check(settings.write(TEST_SETTINGS) and not FileAccess.get_file_as_string(TEST_SETTINGS).contains("multipliers"), "and is written without them")
	DirAccess.remove_absolute(TEST_SETTINGS)
	var home := HomeScreen.new()
	home.workshop = Workshop.new()
	home.settings = settings
	root.add_child(home)
	await process_frame
	home._open_settings()
	var names := home.find_children("*", "CheckButton", true, false).map(func(toggle): return toggle.text)
	check(names == ["Music", "Run upgrades off (next run)", "Top-down battle (next run)"],
		"Home's Settings has the music switch, D158's Run upgrades off and D167's top-down battle, and none of D111's old Testing switches or D156's Number is Cash: %s" % [names])
	home.queue_free()
	await process_frame


## Testing tools on Home (D097): free Coins, logged as such, and a reset that
## asks twice and leaves a fresh Workshop, the wiped one kept in the log.
func test_free_coins_and_reset_for_testing() -> void:
	_clear_test_saves()
	_clear_test_logs()
	var game = _game()
	await process_frame
	var home = game._screen
	check(home is HomeScreen, "the game opens Home")
	home.test_coins_pressed.emit(1000.0)
	check(is_equal_approx(game.workshop.coins, 1000.0), "free Coins go into the Workshop")
	check(is_equal_approx(Save.load_workshop(TEST_SAVE).coins, 1000.0), "and are saved")
	var entries := ActivityLog.read(TEST_LOG)
	check(entries.size() == 1 and entries[0].kind == "test_coins", "and logged as test Coins, never earned")
	game.workshop.buy("damage")
	home._open_settings()
	home._press_reset()
	check(game.workshop.level("damage") == 1, "one press of Reset only asks")
	home._press_reset()
	await process_frame
	check(game.workshop.coins == 0.0 and game.workshop.levels.is_empty() and game.workshop.runs == 0, "the second gives a fresh Workshop")
	check(Save.load_workshop(TEST_SAVE).levels.is_empty(), "saved fresh")
	entries = ActivityLog.read(TEST_LOG)
	check(entries[-1].kind == "progress_reset" and int(entries[-1].workshop.levels.damage) == 1, "and the wiped Workshop is kept in the log")
	game.free()
	_clear_test_saves()
	_clear_test_logs()


## As Range grows the view zooms out rather than letting the range run off
## the screen (D101), easing rather than jumping.
func test_the_view_zooms_out_to_keep_the_range_on_screen() -> void:
	var arena := ArenaView.new()
	arena.size = Vector2(390, 440)
	arena.centre = Vector2(195, 242)
	var sim := _quiet_sim()
	arena.sim = sim
	arena.absorb([], 0.0)
	var towers := arena.size.x * 0.5 * ArenaView.RANGE_SHARE / TowerData.value("range", 0)
	check_near(arena.px_per_metre(), towers, 0.0001, "at the starting Range, The Tower's scale")
	var far := _quiet_sim({"range": TowerData.max_level("range")})
	arena.sim = far
	arena.absorb([], 0.0)
	var room := minf(195.0, minf(242.0, 440.0 - 242.0)) * ArenaView.MAX_RANGE_SHARE
	check(far.stat("range") * arena.px_per_metre() <= room + 0.001, "at full Range the ring stays on screen: %.0f of %.0f" % [far.stat("range") * arena.px_per_metre(), room])
	far.run_levels["range"] = 0
	var before := arena.px_per_metre()
	far.levels["range"] = 0
	arena.absorb([], 0.05)
	check(arena.px_per_metre() > before and arena.px_per_metre() < arena.target_px_per_metre(), "a change of Range eases the zoom rather than jumping")
	arena.free()


## D127: in a crowd each spot has one full label, the most pressing; others
## just like it count on it, and anything else there shows only its sign.
func test_a_crowd_keeps_one_readable_label_a_spot() -> void:
	var sim := _quiet_sim({"health": 100})
	var arena := ArenaView.new()
	arena.size = Vector2(474, 427)
	arena.centre = Vector2(237, 235)
	arena.sim = sim
	arena.absorb([], 0.0)
	var stack: Array = []
	for i in range(4):
		stack.append(_place(sim, "basic", 5.0))
	var near := _place(sim, "basic", 4.0)
	near.attack *= 3.0
	var divider := _place(sim, "divider", 5.0)
	var apart := _place(sim, "basic", 25.0)
	apart.angle = PI
	var plan := arena.label_plan()
	check(plan[divider.id].shown == "full", "a Divider in the crowd keeps its full label")
	check(plan[near.id].shown == "sign", "a different number in its spot shows only its sign")
	var counted: Array = stack.filter(func(enemy): return plan[enemy.id].shown == "counted")
	check(stack.filter(func(enemy): return plan[enemy.id].shown == "sign").size() == stack.size() - counted.size(), "the stacked basics are signs or counted, never overlapping labels")
	check(plan[apart.id].shown == "full" and int(plan[apart.id].count) == 1, "an enemy on its own keeps its full label")
	sim.enemies.clear()
	var same: Array = []
	for i in range(4):
		same.append(_place(sim, "basic", 20.0))
	plan = arena.label_plan()
	var full: Array = same.filter(func(enemy): return plan[enemy.id].shown == "full")
	check(full.size() == 1 and int(plan[full[0].id].count) == 4, "four of the same in one spot read as one label counting 4")
	arena.free()


## D123: the Number fits inside its range ring, even with orbs zooming the
## view out, so the ring always shows round it.
func test_the_number_fits_inside_its_range() -> void:
	var arena := ArenaView.new()
	arena.size = Vector2(474, 427)
	arena.centre = Vector2(237, 235)
	for groups in [BattleSim.START_GROUPS, BattleSim.START_GROUPS + ["orbs"]]:
		var sim := _quiet_sim({"health": 200, "orbs": 2}, groups)
		arena.sim = sim
		arena.motion = NumberMotion.new()
		for _frame in range(240):
			arena.absorb([], 1.0 / 60.0)
		var layout: Dictionary = arena._number_layout()
		var ring := sim.stat("range") * arena.px_per_metre()
		check(arena._number_half.x <= ring * ArenaView.NUMBER_RING_SHARE + 1.0, "%s's digits reach %.0f of a %.0f px ring (orbs: %s)" % [layout.text, arena._number_half.x, ring, "orbs" in groups])
	var unsized := ArenaView.new()
	unsized.sim = _quiet_sim({"health": 200})
	check(unsized._fit_size("143,009") > ArenaView.NUMBER_MIN_PX, "before the view has a size, the Number isn't squeezed to its smallest")
	arena.free()
	unsized.free()


## Milestones (D107, D164): the first time a run's Number earned reaches each
## new digit, the Workshop gets its Coins, once; a best already past a milestone
## pays nothing more, the peak doesn't count, and Home lists them.
func test_milestones_pay_once_when_the_number_earned_reaches_a_new_digit() -> void:
	var workshop := Workshop.new()
	# Past the first run's gift (D125), so only milestones pay here.
	workshop.runs = 1
	check(workshop.finish_run(3, 500.0, 9.99).is_empty() and workshop.coins == 0.0, "earning under 10 reaches none, whatever the peak")
	var first := workshop.finish_run(5, 3.0, 10.0)
	check(first.size() == 1 and float(first[0].number) == 10.0 and workshop.coins == 10.0, "earning exactly 10 pays its Coins: %s" % [first])
	check(workshop.finish_run(5, 3.0, 40.0).is_empty() and workshop.coins == 10.0, "and never again")
	var jump := workshop.finish_run(20, 3.0, 1500.0)
	check(jump.size() == 2 and workshop.coins == 10.0 + 25.0 + 250.0, "a jump past two digits pays both, digit 100 at 25: %s" % [jump])
	check(workshop.best_number == 500.0 and workshop.best_earned == 1500.0, "the record stays the peak, the ladder's best is what was earned")
	check(float(workshop.next_milestone().number) == 10000.0, "the next is 10,000")
	check(workshop.finish_run(1, 3.0, INF).is_empty() and workshop.finish_run(1, 3.0, NAN).is_empty() and workshop.finish_run(1, 3.0, -5.0).is_empty(),
		"an earned that isn't a number, or is below zero, reaches nothing")
	check(workshop.best_earned == 1500.0 and workshop.coins == 10.0 + 25.0 + 250.0, "and changes nothing")
	var home := HomeScreen.new()
	home.workshop = workshop
	root.add_child(home)
	await process_frame
	# Tapping the best Number opens them (D138), with the next digit's reward
	# written under it.
	check(home.find_children("*", "Button", true, false).filter(func(button): return button.text == "Milestones").is_empty(), "no Milestones pill any more")
	check(home._next_digit.text.contains(Palette.money(float(workshop.next_milestone().coins))) and home._next_digit.text.contains("earn 10,000 in a run"),
		"the next digit's reward shows, and what a run must earn for it: %s" % home._next_digit.text)
	home._emblem.pressed.emit()
	check(home._milestones_panel.visible and home._milestones_list.get_child_count() == Guesses.MILESTONES.size() + 1, "listing every milestone, with progress to the next")
	var bars := home._milestones_list.find_children("*", "ProgressBar", true, false)
	check(bars.size() == 1 and (bars[0] as ProgressBar).value == 1500.0 and (bars[0] as ProgressBar).max_value == 10000.0, "the bar runs from the best earned to the next digit")
	home.queue_free()
	await process_frame


## D154: the best Number is written in full to a trillion, so a long one
## shrinks to fit the emblem on a phone-wide screen instead of being cut off.
func test_a_long_best_number_fits_its_emblem() -> void:
	var workshop := Workshop.new()
	workshop.runs = 1
	workshop.best_number = 123.0
	var home := HomeScreen.new()
	home.workshop = workshop
	home.size = Vector2(390, 844)
	root.add_child(home)
	await process_frame
	var font := home._best_number.get_theme_font("font")
	check(home._best_number.get_theme_font_size("font_size") == HomeScreen.EMBLEM_NUMBER_PX, "a short best is drawn full size")
	workshop.best_number = 999999999999.0
	home.refresh()
	await process_frame
	var font_size := home._best_number.get_theme_font_size("font_size")
	var width := font.get_string_size(home._best_number.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	check(home._best_number.text == "999,999,999,999" and home._best_number.size.x > 0.0 and width <= home._best_number.size.x,
		"twelve digits fit the emblem: %.0f px at %d in %.0f" % [width, font_size, home._best_number.size.x])
	home.queue_free()
	await process_frame


## D138: one neutral face, Inter, for words and numbers, with every glyph the
## screens use and every digit the same width, so a ticking number stays put.
func test_one_neutral_font_has_every_glyph_and_steady_digits() -> void:
	check(Palette.WORD_FONT == Palette.NUMBER_FONT and Palette.WORD_FONT.resource_path.ends_with("Inter.ttf"), "Inter for words and numbers alike")
	for glyph in "●◆▶+×÷^✓‹›→…•·=()$%":
		check(Palette.WORD_FONT.has_char(glyph.unicode_at(0)), "Inter has %s" % glyph)
	var cut := Palette.weight(Palette.NUMBER_FONT, 400)
	check(int(cut.opentype_features.get(TextServerManager.get_primary_interface().name_to_tag("tnum"), 0)) == 1, "cuts ask for tabular digits")
	var widths := {}
	for digit in "0123456789":
		widths[roundi(cut.get_string_size(digit, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x * 10.0)] = true
	check(widths.size() == 1, "and get them: every digit the same width, %s" % [widths.keys()])


func test_numbers_read_as_the_towers() -> void:
	check(Palette.number(2.35) == "2.35", "two decimals while small")
	check(Palette.number(3.0) == "3", "whole numbers stay whole")
	check(Palette.number(402.9) == "402", "whole past 100")
	check(Palette.number(1460.0) == "1.46K", "K past a thousand")
	check(Palette.number(7.42e8) == "742.00M", "M past a million")
	# The Number itself is written out in full below a million (D100).
	check(Palette.full(2.35) == "2.35" and Palette.full(402.9) == "402", "the Number reads as number() while small")
	check(Palette.full(1460.0) == "1,460" and Palette.full(999999.4) == "999,999", "and in full, with commas, up to 999,999")
	check(Palette.full(12345.9) == "12,345" and Palette.full(-5000.0) == "-5,000", "whole, never rounded up past what it is")
	check(Palette.full(1e6) == "1,000,000" and Palette.full(7.42e8) == "742,000,000", "in full past a million (D154)")
	check(Palette.full(999999999999.0) == "999,999,999,999" and Palette.full(1e12) == "1.00T", "shortening only from a trillion")
	check(Palette.full(1e6, INF) == "1,000,000", "or never, when asked, as a milestone is")


## An enemy shows what it does to the Number (D085, D102), with the damage
## dealt so far under it once it has lived through a shot, and a Divider in
## range is previewed at the Number.
func test_an_enemy_shows_what_it_does() -> void:
	# Without a decimal point (D105): money rounds down, prices up, and damage
	# to the nearest, never reading 0 for a real hit.
	check(Palette.money(12.9) == "12" and Palette.money(1208.4) == "1,208", "money, rounded down, in full")
	check(Palette.money(30622.93, true) == "30,623" and Palette.money(50.0, true) == "50", "a price rounds up")
	check(Palette.amount(2.4) == "2" and Palette.amount(2.6) == "3" and Palette.amount(1084.0) == "1,084", "damage to the nearest, in full")
	check(Palette.amount(0.3) == "1" and Palette.amount(0.0) == "0", "a real hit never reads 0")

	var sim := _quiet_sim({"defense_absolute": 10})
	var basic := _place(sim, "basic", 20.0)
	basic.attack = 20.0
	var first := sim.landed_damage(20.0)
	check(ArenaView.shown_text(sim, basic) == Palette.amount(first), "walking in, it shows what its hit will take, after defences (D102), without a − (D128): %s" % ArenaView.shown_text(sim, basic))
	check(ArenaView.dealt_text(basic) == "", "unhurt, nothing under it")
	basic.health = basic.max_health * 0.4
	check(ArenaView.shown_text(sim, basic) == Palette.amount(first), "shot, its number doesn't count down")
	check(ArenaView.dealt_text(basic) == Palette.amount(basic.max_health * 0.6), "the damage dealt so far shows under it: %s" % ArenaView.dealt_text(basic))
	basic.health = 0.0
	check(ArenaView.dealt_text(basic) == "", "and a dead one shows none, so a one-shot kill never does")
	basic.health = basic.max_health
	basic.distance = basic.stop_at
	check(ArenaView.shown_text(sim, basic) == Palette.amount(first), "arrived, the same: its next hit")
	basic.hits = 10
	var tenth := sim.landed_damage(20.0 * pow(TowerData.heat_up_per_hit(), 10))
	check(tenth > first and ArenaView.shown_text(sim, basic) == Palette.amount(tenth), "and it grows with each hit it lands: %s" % ArenaView.shown_text(sim, basic))
	check_near(sim.next_hit_damage(basic), tenth, 0.0, "the sim's own next hit is the same number, since the screen reads it")

	var far := _place(sim, "divider", sim.stat("range") + 5.0)
	far.divisor = 1.25
	check(ArenaView.divider_preview(sim).is_empty(), "no preview while the Divider is out of range")
	var near := _place(sim, "divider", sim.stat("range") - 1.0)
	near.divisor = 1.5
	near.distance = near.stop_at
	check(ArenaView.shown_text(sim, near) == "÷1.5", "a Divider shows its ÷ from the start: %s" % ArenaView.shown_text(sim, near))
	var preview := ArenaView.divider_preview(sim)
	var expected := sim.health - sim.divide_loss(1.5)
	check(preview.get("sign") == "÷1.5", "the nearest in range is previewed: %s" % preview)
	check(preview.get("after") == Palette.full(Palette.number_shown(expected, sim.max_health(), true)), "with what it will leave: %s" % preview)
	sim.enemies.erase(far)
	sim._divide(near)
	check(Palette.full(Palette.number_shown(sim.health, sim.max_health(), true)) == preview.after, "and the landing leaves exactly that: %s" % sim.health)


## A new digit (D099) is a moment the first time a run reaches it: 10, 100,
## 1K. Falling back and climbing past it again isn't; a new or resumed run
## starts from where its Number stands.
func test_a_new_digit_is_a_moment_once_a_run() -> void:
	check(NumberMotion.power_of(9.4) == 0 and NumberMotion.power_of(9.6) == 1 and NumberMotion.power_of(100.0) == 2, "9 has no noughts; 10 (shown whole) has one; 100 two")
	check(NumberMotion.power_of(999.0) == 2 and NumberMotion.power_of(1000.0) == 3 and NumberMotion.power_of(1e15) == 15, "and on, however big")
	var arena := ArenaView.new()
	var reached: Array[int] = []
	arena.digit_reached.connect(func(power: int): reached.append(power))
	var sim := _quiet_sim()
	sim.peak_number = 8.0
	arena.sim = sim
	arena.absorb([], 0.0)
	check(reached.is_empty(), "a run starts from where its Number stands")
	sim.peak_number = 12.0
	arena.absorb([], 0.1)
	check(reached == [1] and arena.motion.digit_left > 0.0 and arena.motion.flare_state.get("colour") == Palette.NUMBER, "reaching 10 is a moment: the light flares white: %s" % [reached])
	arena.absorb([], NumberMotion.DIGIT_SECONDS)
	check(arena.motion.digit_left == 0.0, "which passes")
	sim.peak_number = 1200.0
	arena.absorb([], 0.1)
	check(reached == [1, 3], "a jump past two digits at once is one moment, for the new one: %s" % [reached])
	arena.absorb([], 0.1)
	check(reached == [1, 3], "and it doesn't repeat")
	var resumed := _quiet_sim()
	resumed.peak_number = 5000.0
	arena.sim = resumed
	arena.absorb([], 0.1)
	check(reached == [1, 3], "a resumed or new run doesn't celebrate what it already had")
	arena.free()

	var music := AmbientMusic.new()
	root.add_child(music)
	await process_frame
	await process_frame
	var before := music._voices.size()
	music.chime()
	await create_timer(AmbientMusic.CHIME_GAP_SECONDS * AmbientMusic.CHIME_NOTES + 0.1).timeout
	check(music._voices.size() >= before + AmbientMusic.CHIME_NOTES, "the music chimes a run of notes: %d → %d" % [before, music._voices.size()])
	music.set_playing(false)
	music.chime()
	await create_timer(AmbientMusic.CHIME_GAP_SECONDS * AmbientMusic.CHIME_NOTES + 0.1).timeout
	check(music._voices.is_empty(), "and stays silent while the music is off")
	music.queue_free()
	await process_frame

	var game = _game()
	await process_frame
	game._show_battle()
	await process_frame
	game.music.set_playing(true)
	var voices: int = game.music._voices.size()
	game._screen.digit_reached.emit(2)
	await create_timer(AmbientMusic.CHIME_GAP_SECONDS * AmbientMusic.CHIME_NOTES + 0.1).timeout
	check(game.music._voices.size() > voices, "a battle's new digit reaches the music")
	game.free()
	_clear_test_saves()
	_clear_test_logs()


## Motion with weight (D103), drawing only: the Number stays anchored as its
## digits change, rolls to new values, springs back from hits and gains, and
## enemies rock back from shots, heavier ones less.
func test_the_number_and_enemies_move_with_weight() -> void:
	var arena := ArenaView.new()
	var ones := arena._number_cut.get_string_size("11,111", HORIZONTAL_ALIGNMENT_LEFT, -1, 96).x
	var eights := arena._number_cut.get_string_size("88,888", HORIZONTAL_ALIGNMENT_LEFT, -1, 96).x
	check(is_equal_approx(ones, eights), "every digit is the same width, so the Number stays put: %.1f and %.1f" % [ones, eights])
	var sim := _quiet_sim()
	sim.health = 100.0
	arena.sim = sim
	arena.size = Vector2(390, 440)
	arena.centre = Vector2(195, 242)
	arena.absorb([], 0.0)
	arena.absorb([], 0.016)
	check(arena.motion.shown_number == 100.0, "it starts at the Number")
	sim.health = 200.0
	arena.absorb([], 0.016)
	check(arena.motion.shown_number > 100.0 and arena.motion.shown_number < 200.0, "a jump rolls up rather than landing at once: %.1f" % arena.motion.shown_number)
	for _i in range(60):
		arena.absorb([], 0.016)
	check(arena.motion.shown_number == 200.0, "and arrives within a second")
	var enemy := _place(sim, "basic", 5.0)
	arena.absorb([{"type": "tower_hit", "enemy": enemy, "damage": 50.0}], 0.016)
	arena.absorb([], 0.05)
	check(arena.motion.nudge.length() > 0.5, "a hit knocks the Number: %s" % arena.motion.nudge)
	check(arena.motion.nudge.dot(Vector2.from_angle(enemy.angle)) < 0.0, "away from the enemy that landed it")
	for _i in range(120):
		arena.absorb([], 0.016)
	check(arena.motion.nudge.length() < 0.05 and absf(arena.motion.lift) < 0.001, "and springs back to rest")
	var light := _place(sim, "basic", 20.0)
	var heavy := _place(sim, "tank", 20.0)
	arena.absorb([{"type": "enemy_hit", "enemy": light, "damage": 1.0, "critical": false},
		{"type": "enemy_hit", "enemy": heavy, "damage": 1.0, "critical": false}], 0.0)
	check(float(arena.effects.recoil[light.id]) > float(arena.effects.recoil[heavy.id]) * 2.0, "a shot rocks a basic back more than a tank: %s" % arena.effects.recoil)
	for _i in range(60):
		arena.absorb([], 0.016)
	check(arena.effects.recoil.is_empty(), "and they settle")
	arena.free()


## The light behind the Number (D087) flares for a ÷ and fades back to white.
func test_the_light_behind_the_number_flares_and_fades() -> void:
	var arena := ArenaView.new()
	var divider := BattleSim.Enemy.new()
	divider.kind = "divider"
	var landed: Array[Dictionary] = [{"type": "divided", "enemy": divider, "damage": 10.0, "at_wall": false, "divisor": 1.5}]
	arena.absorb(landed, 0.0)
	check(arena.motion.flare_state.get("colour") == Palette.DIVIDER, "a ÷ landing flares the light violet")
	arena.absorb([], ArenaEffects.DIVIDE_FLARE_SECONDS * 0.5)
	check(not arena.motion.flare_state.is_empty(), "still fading part way")
	arena.absorb([], ArenaEffects.DIVIDE_FLARE_SECONDS * 0.6)
	check(arena.motion.flare_state.is_empty(), "and back to white once its time is up")
	arena.free()


## The player's settings (D088) outlive the game closing, apart from the save.
## The range has no switch any more (D096): an older file's "show_range" is
## ignored and dropped when the file is next written.
func test_settings_drop_the_old_range_switch() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)
	var file := FileAccess.open(TEST_SETTINGS, FileAccess.WRITE)
	file.store_string('{"version": 1, "show_range": true, "music": false}')
	file.close()
	var settings := Settings.new()
	settings.read(TEST_SETTINGS)
	check(not settings.music, "an older file with the range switch still reads")
	check(settings.write(TEST_SETTINGS), "and is written")
	var written := FileAccess.get_file_as_string(TEST_SETTINGS)
	check(not written.contains("show_range"), "without the range switch: %s" % written)
	DirAccess.remove_absolute(TEST_SETTINGS)
	var home := HomeScreen.new()
	home.workshop = Workshop.new()
	root.add_child(home)
	await process_frame
	var toggles := home.find_children("*", "CheckButton", true, false).filter(func(toggle): return toggle.text == "Show range")
	check(toggles.is_empty(), "Home has no range switch")
	home.queue_free()
	await process_frame


## D141: back from a battle, Home's Coins count up from what they read when
## the player left, landing on the balance; a resumed run counts nothing.
func test_home_counts_up_the_coins_a_battle_brought() -> void:
	var home := HomeScreen.new()
	home.workshop = Workshop.new()
	home.workshop.add_coins(500.0)
	root.add_child(home)
	await process_frame
	home.count_coins_from(100.0)
	check(home._coins.text == "● 100", "it starts from the Coins held on leaving Home: %s" % home._coins.text)
	home.refresh()
	check(home._coins.text == "● 100", "and a refresh mid-count doesn't jump it")
	home._coin_count.custom_step(HomeScreen.COUNT_SECONDS_MOST + 1.0)
	check(home._coins.text == "● 500" and not home._coin_count.is_running(), "it lands on the balance: %s" % home._coins.text)
	home.count_coins_from(600.0)
	check(home._coins.text == "● 500", "nothing counts down")
	home.queue_free()
	_clear_test_saves()
	_clear_test_logs()
	var game = _game()
	await process_frame
	var before: float = game.workshop.coins
	game._show_battle()
	check(game._coins_leaving_home == before, "a new run remembers the Coins held on leaving Home")
	var battle = game._screen
	battle.sim.coins = 12.0
	battle._bank_coins()
	battle.sim.end_run()
	battle._process(0.0)
	battle.home_pressed.emit()
	await process_frame
	var back = game._screen
	check(back is HomeScreen and back._coin_count != null and back._coin_count.is_running() and back._coins.text != "● " + Palette.money(game.workshop.coins),
		"Home is counting up towards the balance: %s of %s" % [back._coins.text, Palette.money(game.workshop.coins)])
	check(game._coins_leaving_home < 0.0, "and forgets it once counted")
	game._show_battle({"seed": "1"})
	check(game._coins_leaving_home < 0.0, "a resumed run counts nothing: its Coins were banked before")
	await process_frame


## D125: a new player's first run ends with The Tower's welcome: 50 Coins,
## given once, and a popup on Home that opens the Workshop. A save already
## past its first run never gets it.
func test_a_first_run_ends_with_the_workshops_welcome() -> void:
	var fresh := Workshop.new()
	fresh.finish_run(4, 6.0)
	check(fresh.coins == Workshop.FIRST_RUN_GIFT and fresh.gift_waiting == Workshop.FIRST_RUN_GIFT, "the first run's end gives %d Coins" % Workshop.FIRST_RUN_GIFT)
	fresh.gift_waiting = 0.0
	fresh.finish_run(6, 7.0)
	check(fresh.coins == Workshop.FIRST_RUN_GIFT and fresh.gift_waiting == 0.0, "and the second gives none")
	var played := Workshop.new()
	played.restore({"coins": 10.0, "runs": 12})
	played.finish_run(9, 5.0)
	check(played.coins == 10.0 and played.gift_waiting == 0.0, "a save already past its first run never gets it")
	_clear_test_saves()
	_clear_test_logs()
	var game = _game()
	await process_frame
	game._show_battle()
	var battle = game._screen
	battle.sim.end_run()
	battle._process(0.0)
	check(not battle._again.visible, "the first run's end leads Home, not straight into another battle")
	check(Save.load_workshop(TEST_SAVE).coins == Workshop.FIRST_RUN_GIFT + battle.sim.coins, "the gift is saved with the run's end")
	battle.home_pressed.emit()
	await process_frame
	var home = game._screen
	check(home is HomeScreen and home._gift_panel != null and home._gift_panel.visible, "Home opens with the Workshop's welcome")
	var open: Array = home.find_children("*", "Button", true, false).filter(func(button): return button.text == "Open the Workshop")
	open[0].pressed.emit()
	await process_frame
	check(game._screen is WorkshopScreen, "which takes the player into the Workshop")
	game._show_home()
	await process_frame
	check(game._screen._gift_panel == null, "and it shows once")
	game._show_battle()
	battle = game._screen
	battle.sim.end_run()
	battle._process(0.0)
	check(battle._again.visible, "later runs end with Battle again as before")
	game.free()
	_clear_test_saves()
	_clear_test_logs()


## D125: opening a Workshop group says what its rows do, as The Tower explains
## an upgrade the first time it unlocks.
func test_opening_a_group_says_what_it_does() -> void:
	var shop = WorkshopScreen.new()
	shop.workshop = Workshop.new()
	shop.workshop.coins = 1000.0
	root.add_child(shop)
	await process_frame
	var unlock: Array = shop.find_children("*", "Button", true, false).filter(func(button): return not button.find_children("*", "Label", true, false).filter(func(label): return label.text.begins_with("Unlock")).is_empty())
	unlock[0].pressed.emit()
	check(shop.workshop.is_group_open("range") and shop._opened_panel != null, "opening Range shows what it opened")
	var texts: Array = shop._opened_panel.find_children("*", "Label", true, false).map(func(label): return label.text)
	check("Range" in texts and String(TowerData.upgrade("range").description) in texts, "each row with what it does: %s" % [texts])
	shop.free()


## Home and the Workshop share a bar along the bottom (D096): Battle, the
## Workshop and Cards (D146) take the player there, and the roadmap's later screens stand
## locked with the version that brings them, each appearing only when The
## Tower would show it (D125). Tier 1 rides on the Battle button until Tier 2
## exists, with no locked arrows or Coin bonus card on Home (D138).
func test_the_bottom_bar_and_placeholders() -> void:
	var fresh := Workshop.new()
	var first_bar := NavBar.new("battle", fresh.runs, fresh.best_wave)
	check(first_bar.buttons.keys() == ["battle"], "before a first run ends the bar is Battle alone: %s" % [first_bar.buttons.keys()])
	first_bar.free()
	var after_first := NavBar.new("battle", 1, 19)
	check(after_first.buttons.keys() == ["battle", "workshop"], "a first run's end brings the Workshop")
	after_first.free()
	var at_20 := NavBar.new("battle", 5, 20)
	check(at_20.buttons.keys() == ["battle", "workshop", "cards"] and not at_20.buttons.cards.disabled, "wave 20 brings Cards, built (D146)")
	at_20.free()
	var at_30 := NavBar.new("battle", 5, 30)
	check(at_30.buttons.keys() == ["battle", "workshop", "cards", "labs"] and at_30.buttons.labs.disabled, "wave 30 brings Labs; Weapons wait until they're built")
	at_30.free()
	var home := HomeScreen.new()
	home.workshop = Workshop.new()
	home.workshop.runs = 3
	root.add_child(home)
	await process_frame
	var bars := home.find_children("*", "HBoxContainer", true, false).filter(func(node): return node is NavBar)
	check(bars.size() == 1, "Home has the bar")
	var bar: NavBar = bars[0]
	var went := [""]
	home.workshop_pressed.connect(func(): went[0] = "workshop")
	bar.buttons["workshop"].pressed.emit()
	check(went[0] == "workshop", "the bar takes Home to the Workshop")
	check(home.find_children("*", "Button", true, false).filter(func(button): return button.text == "Missions").is_empty(), "no Missions placeholder, as it isn't on the roadmap")
	for name in ["‹", "›"]:
		check(home.find_children("*", "Button", true, false).filter(func(button): return button.text == name).is_empty(), "no locked %s on Home" % name)
	var words := home._battle.find_children("*", "Label", true, false).map(func(label): return label.text)
	check("Tier 1" in words and words.any(func(text): return text.contains("Battle")), "the Battle button carries the tier: %s" % [words])
	check(home.find_children("*", "Label", true, false).filter(func(label): return label.text == "Coin bonus").is_empty(), "the Coin bonus is the Workshop's to show")
	check(bar.buttons["battle"].find_children("*", "Label", true, false).any(func(label): return label.text == NavBar.GLYPHS.battle), "the dock shows each screen's glyph")
	home.queue_free()
	var shop = WorkshopScreen.new()
	shop.workshop = Workshop.new()
	root.add_child(shop)
	await process_frame
	var back := [false]
	shop.home_pressed.connect(func(): back[0] = true)
	var shop_bar: NavBar = shop.find_children("*", "HBoxContainer", true, false).filter(func(node): return node is NavBar)[0]
	shop_bar.buttons["battle"].pressed.emit()
	check(back[0], "and the Workshop's takes it back Home")
	shop.queue_free()
	await process_frame


## Shot feel (D090) is drawing only: a knockback slides back rather than
## jumping, walking is drawn exactly, and a hit throws chips that fade.
func test_hits_and_knockback_are_drawn_with_weight() -> void:
	var arena := ArenaView.new()
	arena.size = Vector2(390, 500)
	var sim := _quiet_sim()
	arena.sim = sim
	var walker := _place(sim, "basic", 12.0)
	arena.absorb([], 1.0 / 60.0)
	check_near(arena._shown_metres(walker), 12.0, 0.0001, "a walking enemy is drawn where it is")
	walker.distance = 8.0
	walker.last_distance = 8.0
	arena.absorb([], 1.0 / 60.0)
	check_near(arena._shown_metres(walker), 8.0, 0.0001, "and follows it in exactly")
	walker.distance = 20.0
	walker.last_distance = 20.0
	arena.absorb([], 1.0 / 60.0)
	var sliding := arena._shown_metres(walker)
	check(sliding > 8.0 and sliding < 20.0, "a knockback slides back rather than jumping: %s" % sliding)
	for frame in range(60):
		arena.absorb([], 1.0 / 60.0)
	check_near(arena._shown_metres(walker), 20.0, 0.05, "and arrives within a second")

	var hit: Array[Dictionary] = [{"type": "enemy_hit", "enemy": walker, "damage": 1.0, "critical": false}]
	arena.absorb(hit, 0.0)
	check(arena.effects.chips.size() == ArenaEffects.CHIPS, "a hit knocks chips off the number: %d" % arena.effects.chips.size())
	var crit: Array[Dictionary] = [{"type": "enemy_hit", "enemy": walker, "damage": 1.0, "critical": true}]
	arena.absorb(crit, 0.0)
	check(arena.effects.chips.size() == ArenaEffects.CHIPS + ArenaEffects.CRIT_CHIPS, "a critical knocks off more")
	arena.absorb([], ArenaEffects.CHIP_SECONDS + 0.01)
	check(arena.effects.chips.is_empty(), "and they fade")
	sim.enemies.clear()
	arena.absorb([], 1.0 / 60.0)
	check(arena.effects.eased.is_empty(), "an enemy gone is forgotten")
	arena.free()


## A kill (D109) bursts into sparks, more for a heavier enemy, and floats
## what it paid beside it: Cash, and Coins when it paid any. The Number's
## shots leave from the edge of its digits, flashing there once each.
func test_kills_burst_and_shots_leave_the_numbers_edge() -> void:
	var arena := ArenaView.new()
	arena.size = Vector2(390, 500)
	arena.centre = Vector2(195, 275)
	var sim := _quiet_sim()
	arena.sim = sim
	var basic := _place(sim, "basic", 12.0)
	var tank := _place(sim, "tank", 14.0)
	arena.absorb([], 1.0 / 60.0)
	var cash_only: Array[Dictionary] = [{"type": "kill", "enemy": basic, "cash": 3.0, "coins": 0.0, "by": ""}]
	arena.absorb(cash_only, 0.0)
	check(arena.effects.sparks.size() == ArenaEffects.SPARKS.basic and arena.effects.death_rings.size() == 1, "a kill bursts into sparks with a ring: %d" % arena.effects.sparks.size())
	check(arena.effects.sparks.all(func(spark): return spark.colour == ArenaView.LOOKS.basic.colour), "all in the enemy's own colour")
	var paid: Array = arena.effects.floats.filter(func(item): return item.has("parts"))
	check(paid.size() == 1 and paid[0].parts.size() == 1 and paid[0].parts[0][0] == "$3", "a kill that pays no Coins floats its Cash alone: %s" % [paid])
	var both: Array[Dictionary] = [{"type": "kill", "enemy": tank, "cash": 12.0, "coins": 2.0, "by": ""}]
	arena.absorb(both, 0.0)
	check(arena.effects.sparks.size() == ArenaEffects.SPARKS.basic + ArenaEffects.SPARKS.tank, "a tank bursts into more")
	paid = arena.effects.floats.filter(func(item): return item.has("parts"))
	check(paid.size() == 2 and paid[1].parts.size() == 2 and paid[1].parts[1][0].ends_with("2") and paid[1].parts[1][3] == Palette.COIN,
		"one that pays Coins floats them beside its Cash, in the Coins' colour: %s" % [paid[1].parts])
	arena.absorb([], ArenaEffects.SPARK_SECONDS * 1.2 + 0.01)
	check(arena.effects.sparks.is_empty() and arena.effects.death_rings.is_empty(), "and they fade")

	arena._number_half = Vector2(30.0, 12.0)
	check_near(arena.edge_px(Vector2.RIGHT), 30.0, 0.0001, "the Number's edge is its box's side across")
	check_near(arena.edge_px(Vector2.UP), 12.0, 0.0001, "and its top and bottom up and down")
	var shot := BattleSim.Shot.new()
	shot.target = basic
	sim.shots.append(shot)
	arena.absorb([], 1.0 / 60.0)
	check(arena.effects.glints.size() == 1, "a shot leaving the Number flashes on its edge")
	check_near((arena.effects.glints[0].at - arena.centre).length(), arena.edge_px((arena.to_view(basic.position()) - arena.centre).normalized()), 0.01, "where it crosses it, towards its target")
	arena.absorb([], 1.0 / 60.0)
	check(arena.effects.glints.size() == 1, "once, not every frame")
	var bounce := BattleSim.Shot.new()
	bounce.target = tank
	bounce.position = basic.position()
	sim.shots.append(bounce)
	arena.absorb([], ArenaEffects.GLINT_SECONDS + 0.01)
	check(arena.effects.glints.is_empty(), "a shot starting out at an enemy, a bounce, doesn't flash, and a flash fades")
	arena.free()


## The music (D092) is on unless the player turns it off, and older settings
## files without it mean on.
func test_the_music_plays_unless_the_player_turns_it_off() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)
	var settings := Settings.new()
	settings.read(TEST_SETTINGS)
	check(settings.music, "music is on by default")
	var file := FileAccess.open(TEST_SETTINGS, FileAccess.WRITE)
	file.store_string('{"version": 1}')
	file.close()
	settings.read(TEST_SETTINGS)
	check(settings.music, "a settings file from before music still reads, with music on")
	settings.music = false
	settings.write(TEST_SETTINGS)
	var again := Settings.new()
	again.read(TEST_SETTINGS)
	check(not again.music, "turned off, it stays off")
	file = FileAccess.open(TEST_SETTINGS, FileAccess.WRITE)
	file.store_string('{"version": 1, "music": "no"}')
	file.close()
	again.read(TEST_SETTINGS)
	check(again.music, "a value of the wrong kind means on")
	DirAccess.remove_absolute(TEST_SETTINGS)

	var music := AmbientMusic.new()
	root.add_child(music)
	await process_frame
	await process_frame
	var bus := AudioServer.get_bus_index(AmbientMusic.BUS)
	check(bus != -1 and not AudioServer.is_bus_mute(bus), "the music has its own bus, playing")
	check(music._chord.size() == AmbientMusic.CHORDS[music._chord_index].size() * 2, "a chord swells in straight away, two voices a note: %d" % music._chord.size())
	music.set_playing(false)
	check(AudioServer.is_bus_mute(bus) and music._voices.is_empty() and not music._hiss.playing, "off, it falls silent and holds nothing")
	music.set_playing(true)
	await process_frame
	await process_frame
	check(not music._chord.is_empty() and not AudioServer.is_bus_mute(bus), "and on again, it starts again")
	music.queue_free()
	await process_frame

	var home := HomeScreen.new()
	home.workshop = Workshop.new()
	var chosen := Settings.new()
	home.settings = chosen
	root.add_child(home)
	await process_frame
	home._open_settings()
	var toggles := home.find_children("*", "CheckButton", true, false).filter(func(toggle): return toggle.text == "Music")
	check(toggles.size() == 1 and (toggles[0] as CheckButton).button_pressed, "Home has the music switch, on")
	(toggles[0] as CheckButton).button_pressed = false
	check(not chosen.music, "turning it off changes the setting")
	home.queue_free()
	await process_frame


## A sim with nothing spawning, for placing enemies by hand.
## The fuel economy (D155, THE_NUMBER.md section 12): measuring options, off
## in the game.
## D164 (THE_NUMBER.md 17): the digit ladder climbs the Number earned and saves its
## best. A save from before it starts from its best peak, which the old ladder paid
## on, so no digit pays twice; a damaged best is read the same way. The old ladder
## and a reward scale stay as measuring options, never saved.
func test_the_digit_ladder_climbs_the_number_earned_and_saves_it() -> void:
	var shop := Workshop.new()
	var paid := shop.finish_run(30, 50.0, 1500.0)
	check(paid.map(func(digit): return float(digit.number)) == [10.0, 100.0, 1000.0], "a run that earned 1,500 reaches digits 10, 100 and 1,000 with a peak of 50")
	check(shop.coins == Workshop.FIRST_RUN_GIFT + 10.0 + 25.0 + 250.0, "each paid in full, beside the first run's gift")
	var coins := shop.coins
	check(shop.finish_run(20, 400.0, 900.0).is_empty() and shop.coins == coins and shop.best_number == 400.0, "a smaller run earns nothing, though its peak is a record")
	var again := Workshop.new()
	again.restore(shop.to_dict())
	check(again.best_earned == 1500.0 and again.best_number == 400.0, "both bests come through a save")
	check(again.finish_run(5, 1.0, 1500.0).is_empty() and float(again.next_milestone().number) == 10000.0, "and a saved best pays nothing twice")
	# Before D164: a best peak of 252 paid digits 10 and 100.
	var older := Workshop.new()
	older.restore({"coins": 5.0, "best_wave": 41, "best_number": 252.0, "runs": 30})
	check(older.best_earned == 252.0, "a save from before it climbs from its best peak")
	paid = older.finish_run(30, 200.0, 999.0)
	check(paid.is_empty() and older.coins == 5.0, "so earning past 10 and 100 pays neither again")
	paid = older.finish_run(30, 200.0, 1000.0)
	check(paid.size() == 1 and float(paid[0].number) == 1000.0 and older.coins == 255.0, "and earning 1,000 pays digit 1,000")
	for damaged in [null, "1500", -1.0, NAN, INF, [], {}]:
		var read := Workshop.new()
		read.restore({"best_number": 120.0, "best_earned": damaged})
		check(read.best_earned == 120.0, "a damaged best earned (%s) reads as the best peak, so it pays nothing twice" % [damaged])
	var zero := Workshop.new()
	zero.restore({"best_number": 120.0, "best_earned": 0})
	check(zero.best_earned == 0.0, "a saved best of 0 is kept as saved")
	var peak := Workshop.new()
	peak.ladder_on_peak = true
	peak.ladder_scale = 0.5
	paid = peak.finish_run(30, 150.0, 5000.0)
	check(paid.map(func(digit): return float(digit.number)) == [10.0, 100.0] and float(paid[1].coins) == 12.5, "measuring the old ladder, the peak pays, at its scale")
	check(peak.best_earned == 5000.0 and float(peak.next_milestone().number) == 1000.0, "the best earned is still kept, and the next digit follows the peak")
	check(not peak.to_dict().has("ladder_on_peak") and not peak.to_dict().has("ladder_scale"), "neither option is saved")


## A run of the game's rules, with Coins following the Number earned or not (D162).
func _earned_run(seed_value: int, tuning: Dictionary, run_tier: int = 1, seconds: float = 400.0) -> BattleSim:
	var sim := BattleSim.new(seed_value, {"damage": 20, "health": 30, "health_regen": 10}, BattleSim.START_GROUPS, run_tier)
	check(sim.configure_tuning(tuning), "a run takes its tuning before its first wave")
	var rows := ["damage", "attack_speed", "health_regen"]
	var turn := 0
	while sim.alive and sim.time < seconds:
		sim.step()
		if sim.ticks % 61 == 0 and sim.can_buy(rows[turn % rows.size()]):
			sim.buy(rows[turn % rows.size()])
			turn += 1
	return sim


## D162 (THE_NUMBER.md section 16): off in the game and recorded only while on;
## the rule pays the Coins the section says, and a seed plays exactly as it does
## without it, so only the Coins differ (the criteria's per-seed comparison).
func test_coins_following_the_number_earned_pay_by_the_rule_and_change_only_the_coins() -> void:
	var rules := {"number_cash": true, "lock_holds_cash": true}
	var plain := BattleSim.new(1)
	check(not plain.earned_active() and plain.earned_share == 0.0 and plain.earned_scale == 0.0 and plain.earned_power == 1.0, "the game plays none of it")
	check(["earned_share", "earned_power", "earned_scale"].all(func(key): return not plain.tuning_config().has(key)), "and a run records none of its options while they are off")
	var control := _earned_run(7, rules)
	check(control.coins > 0.0 and control.cash_earned > 0.0 and control.earned_coins == 0.0, "the control earns Number and ordinary Coins: %.1f Coins, %.1f earned" % [control.coins, control.cash_earned])
	var all_of_it := _earned_run(7, rules.merged({"earned_share": 1.0, "earned_power": 1.0, "earned_scale": 0.1}))
	check(all_of_it.earned_active() and all_of_it.start_config().tuning.earned_share == 1.0 and not all_of_it.start_config().tuning.has("earned_power"), "turned on it is recorded, and only what differs from off")
	check(all_of_it.ticks == control.ticks and all_of_it.wave == control.wave and all_of_it.kills == control.kills and is_equal_approx(all_of_it.cash_earned, control.cash_earned)
			and is_equal_approx(all_of_it.health, control.health) and is_equal_approx(all_of_it.peak_number, control.peak_number),
		"the same seed plays the same run: waves, kills, Number earned and Number all equal the control's")
	check_near(all_of_it.coins, 0.1 * all_of_it.cash_earned, 1e-6 * maxf(1.0, all_of_it.coins), "a whole share pays scale times the Number earned and the kills' own Coins nothing")
	check_near(all_of_it.earned_coins, all_of_it.coins, 1e-9 * maxf(1.0, all_of_it.coins), "all of it from the earned rule")
	var half := _earned_run(7, rules.merged({"earned_share": 0.5, "earned_power": 0.8, "earned_scale": 0.2}))
	var paid := 0.5 * 0.2 * pow(half.cash_earned, 0.8)
	check_near(half.earned_coins, paid, 1e-6 * maxf(1.0, paid), "half a share at a power pays share times scale times earned to the power")
	check_near(half.coins, 0.5 * control.coins + half.earned_coins, 1e-6 * maxf(1.0, half.coins), "and the kills and waves pay the other half of what they did")
	var second := _earned_run(7, rules.merged({"earned_share": 1.0, "earned_power": 1.0, "earned_scale": 0.1}), 2, 300.0)
	check(second.tier == 2 and second.cash_earned > 0.0, "a Tier 2 run earned Number")
	check_near(second.coins, 0.1 * float(TowerData.tier(2).coins) * second.cash_earned, 1e-6 * maxf(1.0, second.coins), "the tier's Coin bonus multiplies the earned part, and the Number earned isn't scaled by the tier's Attack")


func test_the_fuel_economy_is_off_and_leaves_no_trace() -> void:
	var sim := BattleSim.new(1)
	check(not sim.fuel_active() and sim.shot_price == 0.0 and sim.bounty_share == 0.0 and sim.free_bounty_share == 0.0 \
			and sim.base_regen == 0.0 and sim.regen_scale == 1.0 and not sim.hold_doomed, "the game plays none of the fuel economy")
	check(sim.regen_rate() == sim.stat("health_regen"), "and Regen is exactly the row")
	var recorded := sim.tuning_config()
	check(["shot_price", "bounty_share", "free_bounty_share", "base_regen", "regen_scale", "hold_doomed"].all(func(key): return not recorded.has(key)),
		"a run records none of its options while they are off")
	sim.shot_price = 1.0
	sim.base_regen = 1.0
	recorded = sim.tuning_config()
	check(sim.fuel_active() and recorded.shot_price == 1.0 and recorded.base_regen == 1.0 and not recorded.has("bounty_share"), "and only the ones that are on")
	check_near(sim.regen_rate(), sim.stat("health_regen") + 1.0, 0.000001, "a base Regen adds to the row")
	sim.regen_scale = 10.0
	check_near(sim.regen_rate(), sim.stat("health_regen") * 10.0 + 1.0, 0.000001, "which its scale multiplies first")


func test_a_shot_costs_its_price_and_a_broke_tower_goes_quiet() -> void:
	var sim := _quiet_sim()
	sim.shot_price = 1.0
	sim.health = 10.0
	var target := _place(sim, "basic", 20.0)
	target.health = 1e9
	target.max_health = 1e9
	for i in range(60):
		if sim.shots_paid > 0:
			break
		sim.step()
	check(sim.shots_paid == 1 and sim.fuel_spent == 1.0, "a volley is paid for: %d shots, %.2f spent" % [sim.shots_paid, sim.fuel_spent])
	check_near(sim.health, 9.0, 0.01, "out of the Number")
	sim.health = 1.5
	var paid := sim.shots_paid
	for i in range(90):
		sim.step()
	check(sim.shots_paid == paid and sim.health >= 1.5, "a shot that would leave less than 1 is never fired: the tower goes quiet")
	# Multishot's copies ride free.
	var multi := BattleSim.new(1, {"multishot_targets": 1}, BattleSim.START_GROUPS + ["multishot"], 1,
		[{"stat": "multishot_chance", "op": "add", "value": 1.0, "source": "test"}])
	multi.spawns.schedule.clear()
	multi.wave_clock = -1e9
	multi.shot_price = 1.0
	multi.health = 10.0
	for distance in [20.0, 22.0]:
		var each := _place(multi, "basic", distance)
		each.health = 1e9
		each.max_health = 1e9
	for i in range(60):
		if multi.shots_paid > 0:
			break
		multi.step()
	check(multi.shots_paid == 1 and multi.shots.size() == 2, "a multishot flies at two for the price of one: %d paid, %d flying" % [multi.shots_paid, multi.shots.size()])


func test_a_kill_pays_its_bounty() -> void:
	var sim := _quiet_sim()
	sim.bounty_share = 0.25
	var basic := _place(sim, "basic", 20.0)
	basic.hits = 1
	var before := sim.health
	sim.deal_damage(basic, 1e9, "shot")
	check_near(sim.health - before, basic.attack * 0.25, 0.000001, "a shot kill pays a quarter of its Attack, even one that hit first")
	check(sim.gained_from.has("bounty") and not sim.gained_from.has("kills"), "booked as a bounty, in place of D111's clean-kill growth")
	before = sim.health
	sim.deal_damage(_place(sim, "basic", 20.0), 1e9, "orb")
	check(sim.health == before, "an orb's kill pays nothing at the start")
	sim.free_bounty_share = 0.5
	var orbed := _place(sim, "basic", 20.0)
	sim.deal_damage(orbed, 1e9, "orb")
	check_near(sim.health - before, orbed.attack * 0.25 * 0.5, 0.000001, "and half a shot's once the Labs wake it")
	check(sim.gained_from.has("free_bounty"), "booked apart, so a printer would show")
	before = sim.health
	sim.deal_damage(_place(sim, "divider", 20.0), 1e9, "shot")
	check_near(sim.health - before, sim.enemy_attack_now("basic") * 0.25, 0.000001, "a Divider, with no Attack, pays a basic's")
	sim.locked = true
	before = sim.health
	sim.deal_damage(_place(sim, "basic", 20.0), 1e9, "shot")
	check(sim.health == before, "and nothing pays while a Lock stands")
	var bounty_row := _quiet_sim({"coins_per_kill": 25}, BattleSim.START_GROUPS + ["coins"])
	bounty_row.bounty_share = 0.25
	var paid := _place(bounty_row, "basic", 20.0)
	before = bounty_row.health
	bounty_row.deal_damage(paid, 1e9, "shot")
	check_near(bounty_row.health - before, paid.attack * 0.25 * bounty_row.stat("coins_per_kill"), 0.000001, "Coins / Kill raises it, standing in for Bounty")


func test_holding_fire_on_a_doomed_enemy_saves_the_shots() -> void:
	for hold in [true, false]:
		var sim := _quiet_sim({"attack_speed": TowerData.max_level("attack_speed")})
		sim.hold_doomed = hold
		sim.shot_price = 1.0
		sim.health = 50.0
		var target := _place(sim, "basic", 25.0)
		target.health = sim.stat("damage") * 0.5
		for i in range(120):
			if not sim.enemies.has(target):
				break
			sim.step()
		check(not sim.enemies.has(target), "the enemy falls")
		if hold:
			check(sim.shots_paid == 1, "holding fire, one shot is paid for an enemy one shot kills: %d" % sim.shots_paid)
		else:
			check(sim.shots_paid > 1, "without it, the shots fired while the first flies are wasted: %d" % sim.shots_paid)


func test_the_fuel_ledger_books_each_wave() -> void:
	var sim := BattleSim.new(3, {"damage": 20, "health": 20, "health_regen": 10})
	check(sim.configure_tuning({"shot_price": 1.0, "bounty_share": 0.25, "base_regen": 1.0, "hold_doomed": true}), "the fuel economy is set before the first wave")
	var start := sim.health
	while sim.alive and sim.wave < 4:
		if sim.can_buy("health"):
			sim.buy("health")
		sim.step()
	check(sim.alive, "the tower lives to wave 4")
	check(sim.fuel_log.size() == sim.wave - 1 and sim.fuel_log.all(func(logged): return is_equal_approx(logged.net, logged.income - logged.spent - logged.lost)),
		"each finished wave is booked, its net its income less its spending: %d waves" % sim.fuel_log.size())
	var nets := float(sim.fuel_wave().net)
	var spent := float(sim.fuel_wave().spent)
	for logged in sim.fuel_log:
		nets += float(logged.net)
		spent += float(logged.spent)
	check_near(spent, sim.fuel_spent, 0.0001, "the waves' spending adds up to the shots' cost")
	check_near(nets, sim.health - start - float(sim.gained_from.get("health", 0.0)), 0.0001, "and their nets to the Number's change, less bought Health")
	check(sim.peak_wave >= 1 and sim.peak_wave <= sim.wave and sim.shots_paid > 0, "the peak's wave and the shots paid are kept: wave %d, %d shots" % [sim.peak_wave, sim.shots_paid])


## The Number is Cash (D156, THE_NUMBER.md section 13): off in the game unless
## a run's tuning turns it on (D158 makes that the game's rules), and recorded only while on.
func test_the_number_as_cash_is_off_and_leaves_no_trace() -> void:
	var sim := BattleSim.new(1)
	check(not sim.number_cash and not sim.upgrades_off and sim.reserve_share == 0.0, "the game plays none of it")
	check(sim.spendable() == sim.cash and sim.heal_ceiling() == maxf(sim.max_health(), sim.peak_number) and sim.in_shop("health"),
		"Cash, Regen's ceiling and the shop are as they were")
	var recorded := sim.tuning_config()
	check(not recorded.has("number_cash") and not recorded.has("upgrades_off") and not recorded.has("reserve_share"), "a run records none of it while off")


func test_cash_pays_into_the_number_and_buys_with_it() -> void:
	var sim := _quiet_sim({"health": 40})
	sim.number_cash = true
	sim._start_number()
	var start := sim.health
	check(sim.cash == 0.0 and is_equal_approx(sim._ceiling, start), "no Cash of its own; Regen's ceiling starts at the Number")
	var basic := _place(sim, "basic", 20.0)
	basic.hits = 0
	sim.deal_damage(basic, 1e9, "shot")
	var paid := EnemyKinds.cash(basic, sim.stat("cash_bonus"))
	check_near(sim.health - start, paid, 0.000001, "a kill's Cash lands in the Number, and no clean-kill growth on top")
	check(sim.gained_from.has("kill_cash") and not sim.gained_from.has("kills") and is_equal_approx(sim.cash_earned, paid), "booked as income")
	check(is_equal_approx(float(sim.paid_by.get("basic", 0.0)), paid), "and counted against the kind that paid it")
	sim.locked = true
	var held := sim.health
	sim.deal_damage(_place(sim, "basic", 20.0), 1e9, "shot")
	check(sim.health == held and is_equal_approx(sim.locked_out, paid) and is_equal_approx(float(sim.paid_by.basic), paid),
		"while a Lock stands a kill's Cash is lost, and counted as kept out")
	sim.locked = false
	check(not sim.can_buy("health"), "Health isn't sold: it would buy Number with Number")
	sim.health = 50.0
	sim._ceiling = 50.0
	var cost := sim.price("damage")
	check(sim.buy("damage") and is_equal_approx(sim.health, 50.0 - cost) and is_equal_approx(sim._ceiling, 50.0 - cost),
		"a purchase spends the Number and lowers Regen's ceiling with it")
	sim._heal(5.0, "regen")
	check_near(sim.health, 50.0 - cost + 5.0 * sim.peak_drift, 0.000001, "so Regen doesn't hand the spending back, past drifting as it does past a best")
	sim.health = 50.0 - cost
	sim._ceiling = sim.health
	sim.health -= 10.0
	sim._heal(10.0, "regen")
	check_near(sim.health, 50.0 - cost, 0.000001, "but it does restore what an enemy takes")
	sim.health = 1.0 + sim.price("damage") - 0.01
	check(not sim.can_buy("damage"), "and nothing is bought that would leave less than 1")
	sim.health = 100.0
	sim.reserve_share = 0.5
	sim.peak_number = 190.0
	check(is_equal_approx(sim.spendable(), 5.0), "the bots' reserve keeps a share of the best back: %.2f spendable" % sim.spendable())


## D158: the game's rules are one place (RunConfig.game_tuning) and a new run
## reads them, with Run upgrades off from the settings; a run that has started
## keeps what it started with, and an old settings file is read without the
## Testing switch D156 had.
func test_a_new_run_plays_the_games_rules_and_reads_run_upgrades_off() -> void:
	var rules := RunConfig.game_tuning()
	check(rules == {"number_cash": true, "lock_holds_cash": true} and RunConfig.valid_tuning(rules), "the game's rules: the Number is Cash and the Lock holds it")
	check(RunConfig.game_tuning(true) == {"number_cash": true, "lock_holds_cash": true, "upgrades_off": true}, "and with the shop shut on request")
	var settings := Settings.new()
	check(not settings.upgrades_off and settings.run_tuning() == rules, "by default a run gets the game's rules and an open shop")
	settings.upgrades_off = true
	check(settings.write(TEST_SETTINGS), "written")
	var back := Settings.new()
	back.read(TEST_SETTINGS)
	check(back.upgrades_off and back.run_tuning() == RunConfig.game_tuning(true), "and read back as the next run's tuning")
	DirAccess.remove_absolute(TEST_SETTINGS)
	var old := FileAccess.open(TEST_SETTINGS, FileAccess.WRITE)
	old.store_string(JSON.stringify({"version": 1, "music": false, "number_cash": true, "upgrades_off": true}))
	old.close()
	var legacy := Settings.new()
	legacy.read(TEST_SETTINGS)
	check(not legacy.music and legacy.upgrades_off and not legacy.get("number_cash"), "a file from D156's Testing switch still reads, the Number is Cash key ignored")
	check(legacy.write(TEST_SETTINGS) and not FileAccess.get_file_as_string(TEST_SETTINGS).contains("number_cash"), "and is written without it")
	DirAccess.remove_absolute(TEST_SETTINGS)
	var bad := FileAccess.open(TEST_SETTINGS, FileAccess.WRITE)
	bad.store_string(JSON.stringify({"version": 1, "upgrades_off": "yes"}))
	bad.close()
	var strange := Settings.new()
	strange.read(TEST_SETTINGS)
	check(not strange.upgrades_off, "a value that isn't a boolean falls back to the shop open")
	DirAccess.remove_absolute(TEST_SETTINGS)
	var battle := BattleScreen.new()
	battle.workshop = Workshop.new()
	battle.tuning = back.run_tuning()
	root.add_child(battle)
	await process_frame
	check(battle.sim.number_cash and battle.sim.lock_holds_cash and battle.sim.upgrades_off and not battle._cash_chip.visible, "a new run starts with them, and the Cash readout steps aside")
	back.upgrades_off = false
	check(battle.sim.upgrades_off, "changing the setting doesn't change a run that has started")
	check(Palette.number_cash and Palette.row_title("cash_bonus") == "Number bonus" and Palette.row_title("cash_per_wave") == "Number / wave",
		"and its words follow the run: the Cash rows read as the Number's")
	battle.queue_free()
	await process_frame
	Palette.number_cash = false
	check(Palette.row_title("cash_bonus") == "Cash bonus" and Palette.row_description("cash_per_wave").contains("Cash")
		and CardsScreen.card_name("cash") == "Cash", "with the switch off, everything reads as before")
	Palette.number_cash = true
	check(Palette.row_description("interest").contains("Number") and CardsScreen.card_name("cash") == "Number Income"
		and CardsScreen.card_description("cash").contains("Number") and Palette.row_title("damage") == "Damage",
		"with it on, the Interest row and the Cash card are about the Number too, and other rows are untouched")
	Palette.number_cash = false


## A settings write that cannot swap its file in says so, rather than replacing
## the player's file with a half-written one (as the save already does).
## D167: the top-down battle. A setting, off by default and in older files,
## that puts `top_down` in the next run's rules; on, enemies fall in columns,
## distance is height, every position is true, and the screen lays itself out
## from the rules of the run it shows, with the Number at the bottom and the
## run upgrades folded below it.
func test_the_top_down_battle_falls_in_columns_and_lays_out_from_its_rules() -> void:
	var settings := Settings.new()
	check(not settings.top_down and not settings.run_tuning().has("top_down"), "off by default, and a run records none of it")
	settings.top_down = true
	check(settings.run_tuning() == RunConfig.game_tuning(false, true) and settings.run_tuning().top_down == true, "on, the next run's rules carry it")
	check(settings.write(TEST_SETTINGS), "written")
	var back := Settings.new()
	back.read(TEST_SETTINGS)
	check(back.top_down, "and read back")
	var odd := FileAccess.open(TEST_SETTINGS, FileAccess.WRITE)
	odd.store_string(JSON.stringify({"version": 1, "top_down": "yes"}))
	odd.close()
	var reread := Settings.new()
	reread.read(TEST_SETTINGS)
	check(not reread.top_down, "a value that isn't a switch reads as off")
	DirAccess.remove_absolute(TEST_SETTINGS)
	check(is_equal_approx(BattleSim.column_m(-PI / 2.0), 0.0) and BattleSim.column_m(0.0) > 0.0 and BattleSim.column_m(PI) < 0.0
		and is_equal_approx(BattleSim.column_m(0.0), -BattleSim.column_m(PI)), "straight up is the middle column, right and left either side")
	check(absf(BattleSim.column_m(PI / 2.0 - 0.001)) <= Guesses.TOP_DOWN_WIDTH_M * 0.5 and absf(BattleSim.column_m(PI / 2.0 + 0.001)) <= Guesses.TOP_DOWN_WIDTH_M * 0.5,
		"straight down is an edge, inside the field")
	var round := BattleSim.new(4, {}, BattleSim.START_GROUPS, 1, [], [], RunConfig.game_tuning())
	var columns := BattleSim.new(4, {}, BattleSim.START_GROUPS, 1, [], [], RunConfig.game_tuning(false, true))
	check(columns.top_down and columns.start_config().tuning.top_down == true and not round.start_config().tuning.has("top_down"), "the rule is recorded only while on")
	for i in range(240):
		round.step()
		columns.step()
	check(round.enemies.size() == columns.enemies.size() and round.enemies.size() > 0, "the same seed sends the same enemies at the same moments")
	var falling = columns.enemies[0]
	var walking = round.enemies[0]
	check(falling.straight and not walking.straight and falling.kind == walking.kind and is_equal_approx(falling.distance, walking.distance)
		and is_equal_approx(falling.x, BattleSim.column_m(walking.angle)), "each falls in the column its direction gives, as far in")
	check(falling.position().is_equal_approx(Vector2(falling.x, -falling.distance)), "its position is its column and its height")
	var arena := ArenaView.new()
	arena.size = Vector2(400, 800)
	arena.centre = Vector2(200, 400)
	var classic := arena.project(Vector2(10, -5))
	check(classic.is_equal_approx(arena.centre + Vector2(10, -5) * arena.px_per_metre()), "the round view is unchanged")
	arena.invaders = true
	arena.centre = arena.invaders_centre()
	check(arena.centre.x == 200.0 and arena.centre.y == 800.0 - ArenaView.INVADERS_BOTTOM_PX, "the Number stands centred at the bottom: %s" % [arena.centre])
	var px := arena.px_per_metre()
	check(px * Guesses.SPAWN_DISTANCE_M <= arena.centre.y - ArenaView.INVADERS_TOP_PX + 0.001 and px * Guesses.TOP_DOWN_WIDTH_M <= 400.0 - 2.0 * ArenaView.INVADERS_SIDE_PX + 0.001,
		"one scale fits the walk in and the field's width")
	check(arena.project(Vector2(12, -30)).is_equal_approx(arena.centre + Vector2(12, -30) * px), "every point is drawn where it truly is")
	var at_edge := arena.enemy_at(-PI / 2.0, 3.0, Vector2(8, 6), 25.0)
	var at_number := arena.enemy_at(-PI / 2.0, 3.0, Vector2(8, 6), 0.0)
	check(is_equal_approx(at_edge.x, 200.0 + 25.0 * px) and at_number.y < arena.centre.y, "an enemy at the bottom stands in its column, above the Number's digits if it's over them")
	arena.free()
	var screen := BattleScreen.new()
	screen.tuning = RunConfig.game_tuning(false, true)
	root.add_child(screen)
	await process_frame
	await process_frame
	check(screen.invaders and screen._arena.invaders and screen.sim.top_down and screen._upgrades.collapsed, "a top-down run draws top-down, the run upgrades folded")
	var column: VBoxContainer = screen._arena.get_parent()
	check(column.get_children().find(screen._arena) > column.get_children().find(screen._wave_title.get_parent().get_parent()), "the wave line sits above the arena")
	check(screen._arena.centre.y > screen._arena.size.y * 0.75, "and the Number near the arena's bottom: %s of %s" % [screen._arena.centre.y, screen._arena.size.y])
	var saved := screen.run_state()
	screen.queue_free()
	await process_frame
	var resumed := BattleScreen.new()
	resumed.tuning = RunConfig.game_tuning()
	resumed.resume = saved
	root.add_child(resumed)
	await process_frame
	await process_frame
	check(resumed.invaders and resumed.sim != null and resumed.sim.top_down, "a resumed top-down run keeps its rules and its layout, whatever the setting says now")
	resumed.queue_free()
	var plain := BattleScreen.new()
	plain.tuning = RunConfig.game_tuning()
	root.add_child(plain)
	await process_frame
	check(not plain.invaders and not plain._arena.invaders and not plain.sim.top_down, "a round run is laid out as it always was")
	plain.queue_free()
	await process_frame


func test_a_settings_write_that_cannot_land_reports_failure() -> void:
	DirAccess.remove_absolute(TEST_SETTINGS)
	var settings := Settings.new()
	check(settings.write(TEST_SETTINGS), "a normal write lands")
	DirAccess.remove_absolute(TEST_SETTINGS)
	DirAccess.make_dir_recursive_absolute(TEST_SETTINGS)
	var sentinel := FileAccess.open(TEST_SETTINGS + "/keep.txt", FileAccess.WRITE)
	sentinel.store_string("keep")
	sentinel.close()
	check(not settings.write(TEST_SETTINGS), "a write whose swap cannot land reports failure")
	check(FileAccess.get_file_as_string(TEST_SETTINGS + "/keep.txt") == "keep", "and what was already there is untouched")
	DirAccess.remove_absolute(TEST_SETTINGS + ".tmp")
	DirAccess.remove_absolute(TEST_SETTINGS + "/keep.txt")
	DirAccess.remove_absolute(TEST_SETTINGS)


## D157: with the Lock holding Cash, what a standing Lock blocks is kept, not
## lost, and paid in full when it dies; two Locks pay when the last one falls.
func test_a_lock_holds_the_cash_it_blocks_and_pays_it_when_it_dies() -> void:
	for holds in [false, true]:
		var sim := _quiet_sim()
		sim.number_cash = true
		sim.lock_holds_cash = holds
		var lock := _place(sim, "lock", 0.0)
		var other := _place(sim, "lock", 0.0)
		sim.step()
		check(sim.locked, "a Lock in place holds the Number")
		var before := sim.health
		var first_basic := _place(sim, "basic", 20.0)
		sim.deal_damage(first_basic, 1e9, "shot")
		var blocked := EnemyKinds.cash(first_basic, sim.stat("cash_bonus"))
		check(sim.health == before and is_equal_approx(sim.locked_out, blocked), "its kill's Cash is blocked either way")
		check(is_equal_approx(sim.lock_held, blocked if holds else 0.0), "and held only with the option: %.2f" % sim.lock_held)
		var held := sim.lock_held
		sim.record_events = true
		sim.events.clear()
		var lock_cash := EnemyKinds.cash(lock, sim.stat("cash_bonus")) + EnemyKinds.cash(other, sim.stat("cash_bonus"))
		sim.deal_damage(lock, 1e9, "shot")
		check(sim.locked and sim.health == before, "one Lock down, another still stands: nothing is paid yet")
		var popped := sim.events.filter(func(event): return event.type == "kill")
		var own_pay := EnemyKinds.cash(lock, sim.stat("cash_bonus"))
		check(popped.size() == 1 and popped[0].cash == 0.0 and is_equal_approx(float(popped[0].held), own_pay if holds else 0.0),
			"the pop-up of a kill under a standing Lock reads held (with the option), never gained")
		sim.deal_damage(other, 1e9, "shot")
		if holds:
			check(not sim.locked and sim.lock_held == 0.0, "the last Lock down frees the Number and empties the pool")
			check_near(sim.health - before, held + lock_cash, 0.000001, "all that was held, and both Locks' own Cash, is paid in: %.2f" % (sim.health - before))
			check(sim.gained_from.has("lock_cash") and float(sim.paid_by.get("lock", 0.0)) > 0.0, "booked as the Locks' payday")
		else:
			check(sim.health == before and sim.lock_held == 0.0, "as today, a standing Lock blocks even its own Cash: nothing is kept")


func test_with_the_number_as_cash_free_levels_dont_raise_prices() -> void:
	var sim := _quiet_sim()
	sim.number_cash = true
	var before := sim.price("damage")
	sim.run_levels["damage"] = 1
	sim.free_levels["damage"] = 1
	check(sim.price("damage") == before, "a free level leaves the next level's price where it was")
	sim.number_cash = false
	check(sim.price("damage") > before, "where today's rules count it as bought")


func test_interest_is_paid_on_the_number_up_to_its_cap() -> void:
	var sim := _quiet_sim({"interest": 10}, BattleSim.START_GROUPS + ["interest"])
	sim.number_cash = true
	sim.health = 100.0
	sim._ceiling = 100.0
	var before := sim.health
	sim._pay_wave_end()
	check_near(float(sim.gained_from.get("interest", 0.0)), minf(sim.rules.value("interest_cap"), 100.0 * sim.stat("interest")), 0.000001, "a wave's interest is on the Number")
	sim.health = 1e9
	sim._ceiling = 1e9
	var high := float(sim.gained_from.interest)
	sim._pay_wave_end()
	check_near(float(sim.gained_from.interest) - high, sim.rules.value("interest_cap"), 0.000001, "and never more than the cap, however big the Number")
	check(sim.health > before, "the Number rose")


func test_upgrades_off_shuts_the_shop_but_free_levels_still_land() -> void:
	var sim := _quiet_sim({}, BattleSim.START_GROUPS + ["free_upgrades"])
	sim.upgrades_off = true
	sim.cash = 1e9
	check(not sim.can_buy("damage") and not sim.buy("damage"), "nothing can be bought")
	sim.levels["free_attack_upgrade"] = TowerData.max_level("free_attack_upgrade")
	var levels := 0
	for i in range(20):
		sim._pay_wave_end()
	for id in sim.run_levels:
		levels += int(sim.run_levels[id])
	check(levels > 0, "Free Upgrades still land: %d levels" % levels)


func _quiet_sim(row_levels: Dictionary = {}, groups: Array = BattleSim.START_GROUPS) -> BattleSim:
	var sim := BattleSim.new(1, row_levels, groups)
	sim.spawns.schedule.clear()
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
	enemy.mass = EnemyKinds.mass_ratio(kind) * TowerData.mass_growth(sim.wave)
	if kind == "ray":
		enemy.hit_in = float(TowerData.enemies().elites.ray_charge_seconds)
	elif kind == "protector":
		sim._protectors.append(enemy)
	sim.enemies.append(enemy)
	return enemy


func _test_save_copies() -> Array[String]:
	var found: Array[String] = []
	for name in DirAccess.get_files_at(ProjectSettings.globalize_path("user://")):
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
	game.settings_path = TEST_SETTINGS
	root.add_child(game)
	return game
