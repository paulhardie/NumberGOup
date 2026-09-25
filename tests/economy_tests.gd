extends SceneTree

const RuleModifierPipelineClass = preload("res://src/rule_modifier_pipeline.gd")
const GameDataClass = preload("res://src/game_data.gd")

var failures := 0

func _init() -> void:
	_test_scientific_number()
	_test_workshop_unlocks_in_the_towers_order()
	_test_research_focus_targets_a_category()
	_test_multi_buy_matches_buying_one_at_a_time()
	_test_workshop_prices_are_the_towers()
	_test_stat_values_read_the_towers_tables()
	_test_tower_rows_run_to_their_maxima()
	_test_multishot_and_bounce_strike_more_enemies()
	_test_shots_crit_and_super_crit()
	_test_rapid_fire_and_regen()
	_test_range_damage_per_meter_and_knockback()
	_test_resumed_walkers_keep_their_hits()
	_test_orbs_kill_what_they_touch()
	_test_health_sets_the_starting_number()
	_test_save_round_trip_and_legacy_migration()
	_test_old_workshop_is_refunded_on_the_towers_scale()
	_test_bad_saves_are_never_written_over()
	_test_v5_saves_migrate_without_loss()
	_test_long_run_replays_identically_across_a_reload()
	_test_offline_policy()
	_test_prestige_reset_and_gain()
	_test_first_run_funds_permanent_workshop()
	_test_tier_pressure_and_curve_gates()
	_test_tier_one_opening()
	_test_production_clears_liability()
	_test_a_wave_is_a_group()
	_test_enemy_types_and_pay_per_kill()
	_test_distance_and_reach()
	_test_saved_numbers_read_back_exactly()
	_test_group_members_land_one_by_one()
	_test_group_brace_guard_and_thorns()
	_test_group_saves_and_resumes()
	_test_members_stay_and_the_pile_grows()
	_test_tower_shaped_bosses_and_heat_up()
	_test_opening_members_pass()
	_test_d058_opening_save_reconciles()
	_test_output_is_number_and_strikes_the_wave()
	_test_repeated_taps_count_once()
	_test_missed_waves_move_on_and_bosses_stay()
	_test_beaten_wave_waits_out_its_clock()
	_test_missed_checkpoint_pays_when_passed()
	_test_mid_wave_save_resumes_identically()
	_test_collection_is_absolute()
	_test_boss_axes_and_rewards()
	_test_brace_blocks_next_collection()
	_test_defense_percent_reduces_the_hit_and_survives_reset()
	_test_lifesteal_feeds_the_number()
	_test_thorns_deal_the_hit_to_the_wave_in_front()
	_test_death_defy_ignores_an_ending_hit()
	_test_card_start_scales_with_the_tier()
	_test_coin_rows_lift_what_a_run_pays()
	_test_cash_comes_from_kills_and_waves()
	_test_free_upgrades_raise_run_levels()
	_test_run_upgrades_cost_the_towers_cash()
	_test_rig_purchase_spends_cash_and_stacks()
	_test_rig_multi_buy_quotes_and_spends()
	_test_rig_stops_at_the_rows_max_rank()
	_test_rig_is_run_scoped()
	_test_rig_refuses_what_it_does_not_sell()
	_test_rig_save_round_trip()
	_test_run_health_pays_its_number_now()
	_test_lab_definitions_cover_the_open_categories()
	_test_lab_research_costs_coins_and_takes_real_time()
	_test_lab_slots_limit_concurrent_research()
	_test_lab_slots_open_with_gems()
	_test_research_finished_mid_run_waits_for_the_next_run()
	_test_lab_research_is_a_between_run_action()
	_test_finished_lab_research_applies_its_effect()
	_test_lab_speed_shortens_other_lines_not_itself()
	_test_lab_save_round_trip()
	_test_card_definitions_are_common_and_rare()
	_test_card_pull_costs_gems_and_grants_a_level()
	_test_card_pull_is_a_between_run_action()
	_test_card_pull_never_exceeds_max_level()
	_test_card_pull_duplicate_protection()
	_test_card_equip_respects_slot_cap_and_run_state()
	_test_active_card_applies_its_effect_but_inventory_does_not()
	_test_card_save_round_trip()
	_test_defensive_ceilings_bound_the_combined_effects()
	_test_armor_ceiling_bounds_armor_not_other_rules()
	_test_guard_flat_reduction_and_floor()
	_test_game_data_loads_cleanly()
	_test_catalogues_are_internally_consistent()
	_test_loaded_ranks_stay_within_their_caps()
	_test_v8_save_migrates_to_v9()
	_test_wave_death_resets_run_but_keeps_meta_progress()
	_test_run_gates_the_wave_clock()
	_test_retreat_ends_and_resets_run()
	_test_tier_records_milestones_and_unlocks()
	_test_claimed_milestones_survive_a_reload()
	_test_boss_waves_and_checkpoints_pay_gems()
	_test_passed_checkpoints_are_paid_on_load()
	_test_modifier_pipeline_order()
	_test_deterministic_run_seed()
	_test_high_wave_values_remain_valid()
	if failures > 0:
		print("FAIL: ", failures, " economy tests")
		quit(1)
	else:
		print("PASS: economy tests")
		quit(0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_scientific_number() -> void:
	_expect(ScientificNumber.from_float(1000).format_value() == "1,000", "numbers under a million should stay as full digits")
	_expect(ScientificNumber.from_float(999999).format_value() == "999,999", "full digits should extend to just under a million")
	_expect(ScientificNumber.from_float(1500000).format_value() == "1.5M", "abbreviation should start at a million")
	_expect(ScientificNumber.new(4.72, 36).format_value() == "4.72e36", "large numbers should use scientific notation")
	var sum := ScientificNumber.new(9.0, 5).add(ScientificNumber.new(2.0, 5))
	_expect(sum.compare_to(ScientificNumber.new(1.1, 6)) == 0, "addition should normalize")
	_expect(ScientificNumber.from_float(5).subtract(ScientificNumber.from_float(9)).is_zero(), "subtraction cannot go negative")

## D068: The Tower's Workshop opens a category a group at a time, in its
## order, each group bought with Coins between runs. Damage, Attack Speed and
## the crit rows, and Health and Regen, are open from the start; Utility opens
## nothing until Cash Bonus and Cash / Wave are bought.
func _test_workshop_unlocks_in_the_towers_order() -> void:
	var state := GameState.new()
	for definition in state.definitions:
		if definition.category == ProgressionTaxonomy.WORKSHOP:
			_expect(ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(definition.workshop_category), "every Workshop row needs one of the four categories: " + definition.id)
	for row_id in ["damage", "attack_speed", "critical_chance", "critical_factor", "health", "health_regen"]:
		_expect(state.is_unlocked(state.get_definition(row_id)), row_id + " should be open from the start")
	for row_id in ["range", "defense_percent", "thorns", "cash_bonus", "coins_per_wave", "orbs"]:
		_expect(not state.is_unlocked(state.get_definition(row_id)), row_id + " should wait for its unlock")
	_expect(str(state.next_locked_group("attack").get("id", "")) == "range" and str(state.next_locked_group("utility").get("id", "")) == "cash", "each category should offer its first unlock next")
	state.coins = 49
	_expect(not state.can_unlock_group("range") and not state.unlock_group("range"), "Range should not open short of its 50 Coins")
	state.coins = 10000
	_expect(not state.can_unlock_group("multishot"), "Multishot should wait for Range, The Tower's order")
	_expect(state.unlock_group("range") and state.coins == 9950 and state.is_unlocked(state.get_definition("damage_per_meter")), "Range should open for exactly 50 Coins, with Damage / Meter")
	_expect(not state.unlock_group("range"), "an open group should not sell again")
	_expect(state.unlock_group("multishot") and state.coins == 9550, "Multishot should open next for 400 Coins")
	_expect(state.unlock_group("cash") and state.unlock_group("defense"), "Cash and Defense should open for their Coins")
	state.start_run(1, 3)
	state.coins = 1000000
	_expect(not state.unlock_group("coins") and not state.can_unlock_group("coins"), "unlocking should wait for the run to end")
	state.end_run()
	_expect(state.unlock_group("coins") and state.is_unlocked(state.get_definition("coins_per_wave")), "between runs it should open")
	var damage := state.get_definition("damage")
	state.purchased["damage"] = damage.max_rank
	_expect(not state.can_purchase("damage"), "a row should stop at its last level")
	var level_before := state.get_workshop_level()
	state.purchased["health"] = 2
	_expect(state.get_workshop_level() == level_before + 2, "every row's levels should count toward the Workshop level")
	_expect(not state.has_category_content(ProgressionTaxonomy.ULTIMATE), "Ultimates should hold no rows until they are authored")

func _test_research_focus_targets_a_category() -> void:
	var state := _funded_state()
	state.purchased = {"damage": 100, "health": 20}
	_expect(state.get_workshop_level() >= GameState.RESEARCH_WORKSHOP_LEVEL, "this build should reach the Research Focus level")
	_expect(not state.select_focus("output"), "a retired bay id should no longer be selectable")
	_expect(not state.select_focus(ProgressionTaxonomy.ULTIMATE), "a category with no rows should not be selectable")
	var health := state.get_definition("health")
	var damage := state.get_definition("damage")
	var health_before := state.get_workshop_coin_cost(health)
	var damage_before := state.get_workshop_coin_cost(damage)
	_expect(state.select_focus(ProgressionTaxonomy.DEFENSE), "Defense should be selectable as a Research Focus")
	_expect(state.get_workshop_coin_cost(health) < health_before, "Research Focus should discount its own category")
	_expect(state.get_workshop_coin_cost(damage) == damage_before, "Research Focus should not discount another category")
	_expect(not state.select_focus(ProgressionTaxonomy.ATTACK), "Research Focus should lock in until Prestige")

## A multi-buy press must never be a discount or a surcharge: it is the same
## levels at the same prices, charged in one go.
func _test_multi_buy_matches_buying_one_at_a_time() -> void:
	var one := _funded_state()
	var single_total := 0
	for rank in range(5):
		single_total += one.get_workshop_coin_cost(one.get_definition("damage"))
		_expect(one.purchase("damage"), "each single Damage level should purchase")
	var bulk := _funded_state()
	var plan := bulk.plan_purchase("damage", 5)
	_expect(int(plan.ranks) == 5 and int(plan.cost) == single_total and single_total == 30 + 55 + 88 + 128 + 177, "a five-level press should quote exactly what five single presses cost")
	_expect(bulk.purchase_ranks("damage", 5) == 5, "a five-level press should land five levels")
	_expect(bulk.coins == one.coins and bulk.get_owned("damage") == 5, "bulk and single buying should end in the same place")
	var capped := _funded_state()
	capped.coins = 1000000000
	var cap: int = capped.get_definition("attack_speed").max_rank
	_expect(capped.purchase_ranks("attack_speed", cap * 2) == cap, "a press larger than the row should stop at its last level")
	_expect(capped.purchase_ranks("attack_speed", GameState.MAX_BUY) == 0, "a maxed row should refuse a further press")

	# Derived rather than hardcoded, so the rule survives a table change: MAX
	# takes levels while the next one still fits inside the balance.
	var short := _funded_state()
	short.coins = 500
	var damage := short.get_definition("damage")
	var affordable := 0
	var tally := 0
	while affordable < damage.max_rank and tally + short.get_workshop_coin_cost_at(damage, affordable) <= 500:
		tally += short.get_workshop_coin_cost_at(damage, affordable)
		affordable += 1
	_expect(affordable > 1 and affordable < damage.max_rank, "500 Coins should be a genuinely partial press on this row")
	var partial := short.plan_purchase("damage", GameState.MAX_BUY)
	_expect(int(partial.ranks) == affordable and int(partial.cost) == tally, "MAX should buy exactly the levels the player can afford")
	_expect(short.purchase_ranks("damage", GameState.MAX_BUY) == affordable and short.coins == 500 - tally, "a partial press should spend only what it quoted")

	# Quotes come from cached running totals (D047); a Research Focus changes
	# every price, so the next quote must use the new ones.
	var focused := _funded_state()
	var before_focus := int(focused.plan_purchase("damage", 5).cost)
	focused.focus_path = ProgressionTaxonomy.ATTACK
	var focus_singles := 0
	for rank in range(5):
		focus_singles += focused.get_workshop_coin_cost_at(focused.get_definition("damage"), rank)
	var after_focus := int(focused.plan_purchase("damage", 5).cost)
	_expect(after_focus < before_focus and after_focus == focus_singles, "a quote should follow a Research Focus choice at once")

	var deep := _funded_state()
	deep.purchased = {"damage": 2000}
	deep.coins = 1000000000000
	var deep_singles := 0
	var deep_damage := deep.get_definition("damage")
	for rank in range(2000, 2040):
		deep_singles += deep.get_workshop_coin_cost_at(deep_damage, rank)
	var deep_plan := deep.plan_purchase("damage", 40)
	_expect(int(deep_plan.ranks) == 40 and int(deep_plan.cost) == deep_singles, "a deep press should quote exactly what single presses cost")

	var locked := _funded_state()
	_expect(int(locked.plan_purchase("range", 5).ranks) == 0, "a row not yet unlocked should quote nothing")
	var running := _funded_state()
	running.start_run(1, 3)
	_expect(int(running.plan_purchase("damage", 5).ranks) == 0, "a run should refuse a Workshop press of any size")

## D068: every Workshop price is The Tower's, level by level.
func _test_workshop_prices_are_the_towers() -> void:
	var state := GameState.new()
	var damage := state.get_definition("damage")
	var health := state.get_definition("health")
	_expect(state.get_workshop_coin_cost(damage) == 30 and state.get_workshop_coin_cost(health) == 30 and state.get_workshop_coin_cost(state.get_definition("critical_chance")) == 50, "a first level of Damage or Health should cost 30 Coins and of Critical Chance 50")
	_expect(state.get_workshop_coin_cost_at(damage, 1) == 55 and state.get_workshop_coin_cost_at(damage, 2) == 88 and state.get_workshop_coin_cost_at(health, 2) == 87, "prices should follow The Tower's table level by level")
	_expect(state.get_workshop_coin_cost_at(state.get_definition("attack_speed"), 98) == 118797, "Attack Speed's last level should cost The Tower's 118,796.3 Coins, rounded up")
	_expect(state.get_workshop_coin_cost_at(damage, damage.max_rank) == 0, "a row past its last level should have no price")
	_expect(is_equal_approx(float(state.get_group("range").unlock_coins), 50.0) and is_equal_approx(float(state.get_group("defense").unlock_coins), 75.0) and is_equal_approx(float(state.get_group("cash").unlock_coins), 40.0) and is_equal_approx(float(state.get_group("death_defy").unlock_coins), 1500000.0), "unlocks should cost The Tower's Coins")
	state.coins = 173
	_expect(state.purchase_ranks("damage", 3) == 3 and state.coins == 0, "173 Coins should buy exactly three Damage levels")
	_expect(state.start_run(1, 7) and is_equal_approx(state.stat("damage"), 8.908 + 0.0) == false and is_equal_approx(state.stat("damage"), damage.value_at(3)), "the next run should shoot at Damage level 3")

## The card face reads the row's own table, so it cannot drift from what the
## level does (D068).
func _test_stat_values_read_the_towers_tables() -> void:
	var state := _funded_state()
	var damage := state.get_definition("damage")
	_expect(is_equal_approx(float(state.stat_display(damage, 0).value), 3.0) and str(state.stat_display(damage, 0).unit) == "flat", "Damage should read 3 before any level, as a fresh Tower does")
	_expect(is_equal_approx(float(state.stat_display(damage, 1).value), 5.877) and is_equal_approx(float(state.stat_display(damage, 100).value), 1053.0), "Damage should follow The Tower's table: 5.877 at level 1, 1,053 at 100")
	state.purchased = {"damage": 100}
	_expect(is_equal_approx(state.stat("damage"), 1053.0) and is_equal_approx(float(state.stat_display(damage, 100).value), state._damage()), "the card value should equal what the level actually shoots")
	var health := state.get_definition("health")
	_expect(is_equal_approx(float(state.stat_display(health, 0).value), 5.0) and is_equal_approx(float(state.stat_display(health, 1).value), 10.0), "Health should read 5, then 10 at level 1")
	var speed := state.get_definition("attack_speed")
	_expect(str(state.stat_display(speed, 0).unit) == "per_second" and is_equal_approx(float(state.stat_display(speed, 0).value), 1.0) and is_equal_approx(float(state.stat_display(speed, 20).value), 2.0), "Attack Speed should read 1 shot a second, 2 at level 20")
	var reach := state.get_definition("range")
	_expect(str(state.stat_display(reach, 0).unit) == "metres" and is_equal_approx(float(state.stat_display(reach, 0).value), 30.0) and is_equal_approx(float(state.stat_display(reach, 79).value), 69.5), "Range should read 30 m, 69.5 m at its last level")
	var crit := state.get_definition("critical_chance")
	_expect(str(state.stat_display(crit, 0).unit) == "percent" and is_equal_approx(float(state.stat_display(crit, 0).value), 0.01), "Critical Chance should read as a share, 1% before any level")
	_expect(str(state.card_stat_display("card_attack_speed", 1).unit) == "multiplier", "the Attack Speed card should still read as a multiplier")

## D068: a Multishot fires at other enemies in reach as well, and a Bounce
## Shot goes on from the enemy it struck to the nearest near it. Each strike
## deals the shot's damage, and all of it is Number.
func _test_multishot_and_bounce_strike_more_enemies() -> void:
	var state := GameState.new()
	state.balance_profile.ENEMY_MIX = {"basic": 1.0}
	state.purchased = {"multishot_chance": 99, "multishot_targets": 7}
	state.start_run(1, 5)
	_all_in_reach(state)
	for member in state.active_encounter.members:
		member.hp = ScientificNumber.from_float(1000.0)
		member.max = member.hp.copy()
	state.active_encounter._sum_remaining()
	var multi: SimulationEvent = null
	var single: SimulationEvent = null
	for shot in range(60):
		var before: Array = state.active_encounter.members.map(func(member): return member.hp.copy())
		var event := state.tap()
		var struck := 0
		for index in range(before.size()):
			if state.active_encounter.members[index].hp.compare_to(before[index]) < 0:
				struck += 1
		_expect(struck == event.hits, "a shot should strike as many enemies as it says: %d of %d" % [struck, event.hits])
		if event.hits > 1 and multi == null:
			multi = event
		if event.hits == 1 and single == null:
			single = event
	_expect(multi != null and multi.hits == 9, "a Multishot at level 7 should fire at nine enemies")
	_expect(single != null, "a Multishot should be a chance, not every shot")
	_expect(multi != null and not multi.is_critical and absf(multi.amount.log10() - log(9.0 * state._damage()) / log(10.0)) < 1.0e-9, "every strike of a Multishot should be Number")

	var bouncing := GameState.new()
	bouncing.balance_profile.ENEMY_MIX = {"basic": 1.0}
	bouncing.purchased = {"bounce_shot_chance": 85, "bounce_shot_targets": 7, "bounce_shot_range": 60}
	bouncing.start_run(1, 6)
	_all_in_reach(bouncing)
	for member in bouncing.active_encounter.members:
		member.hp = ScientificNumber.from_float(1000.0)
	bouncing.active_encounter._sum_remaining()
	var most := 1
	for shot in range(40):
		most = maxi(most, bouncing.tap().hits)
	# Everything stands at the Number, so every enemy is within 40 m of every
	# other: a bounce goes on to eight more.
	_expect(most == 9, "a Bounce Shot should go on to eight more enemies at level 7: %d" % most)
	var fresh := GameState.new()
	fresh.start_run(1, 5)
	var shots := 0
	for step in range(32):
		shots += fresh.advance(0.125).filter(func(event): return event.type == "tick").size()
	_expect(shots == 4, "a fresh run should fire once a second, The Tower's Attack Speed 1.0: %d" % shots)

## D068: a shot's damage is Damage, times Critical Factor on a crit, times
## Super Crit Mult on a super crit, which only a crit can be.
func _test_shots_crit_and_super_crit() -> void:
	var state := GameState.new()
	state.purchased = {"damage": 10, "critical_chance": 79, "critical_factor": 20, "super_crit_chance": 100, "super_crit_mult": 20}
	state.start_run(1, 11)
	var damage := state.stat("damage")
	var factor := state.stat("critical_factor")
	var super_mult := state.stat("super_crit_mult")
	var counts := {"plain": 0, "crit": 0, "super": 0}
	for shot in range(2000):
		var event := state.tap()
		var amount := event.amount.mantissa * pow(10.0, event.amount.exponent)
		if not event.is_critical:
			_expect(is_equal_approx(amount, damage), "a plain shot should deal Damage")
			counts.plain += 1
		elif is_equal_approx(amount, damage * factor):
			counts.crit += 1
		else:
			_expect(is_equal_approx(amount, damage * factor * super_mult), "a super critical should multiply a critical by Super Crit Mult")
			counts.super += 1
	var crit_share := float(counts.crit + counts.super) / 2000.0
	_expect(absf(crit_share - 0.8) < 0.04, "Critical Chance at level 79 should crit 80%% of the time: %f" % crit_share)
	_expect(absf(float(counts.super) / float(counts.crit + counts.super) - 0.2) < 0.04, "Super Crit Chance should super-crit 20% of crits")
	var bare := GameState.new()
	bare.start_run(1, 12)
	_expect(is_equal_approx(bare._critical_chance(), 0.01), "a fresh run should crit 1% of the time, as The Tower's does")

## D068: every row's value at its last level is The Tower's.
func _test_tower_rows_run_to_their_maxima() -> void:
	var state := _funded_state()
	for definition in state.definitions:
		if definition.category == ProgressionTaxonomy.WORKSHOP:
			state.purchased[definition.id] = definition.max_rank
	var expected := {
		"damage": 71114390.0, "attack_speed": 5.95, "critical_chance": 0.8, "critical_factor": 16.2,
		"range": 69.5, "damage_per_meter": 0.59, "multishot_chance": 0.495, "multishot_targets": 9.0,
		"rapid_fire_chance": 0.34, "rapid_fire_duration": 5.55, "bounce_shot_chance": 0.68,
		"bounce_shot_targets": 8.0, "bounce_shot_range": 40.0, "super_crit_chance": 0.2, "super_crit_mult": 13.2,
		"health": 6709183000.0, "health_regen": 10170860000.0, "defense_percent": 0.495,
		"defense_absolute": 80214390.0, "thorns": 0.99, "lifesteal": 0.04460204, "knockback_chance": 0.8,
		"knockback_force": 6.08, "orb_speed": 6.1, "orbs": 4.0, "death_defy": 0.3, "cash_bonus": 2.49,
		"cash_per_wave": 596.0, "coins_per_kill": 2.49, "coins_per_wave": 150.0,
		"free_attack_upgrade": 0.495, "free_defense_upgrade": 0.495, "free_utility_upgrade": 0.495, "interest": 0.0594,
	}
	for row_id in expected:
		_expect(absf(state.stat(row_id) / float(expected[row_id]) - 1.0) < 1.0e-6, "%s should reach %s at its last level: %s" % [row_id, str(expected[row_id]), str(state.stat(row_id))])
	var maxima := {"damage": 6000, "attack_speed": 99, "critical_chance": 79, "critical_factor": 150, "health": 6000, "health_regen": 6000, "defense_absolute": 5000, "orbs": 4, "coins_per_wave": 149}
	for row_id in maxima:
		_expect(state.get_definition(row_id).max_rank == int(maxima[row_id]), "%s should have The Tower's %d levels" % [row_id, int(maxima[row_id])])
	_expect(is_equal_approx(state._critical_chance(), 0.8) and absf(state._range() - 69.5) < 1.0e-6, "the run should read the rows' values")

## D068: Rapid Fire fires four times as fast while it lasts; Health Regen adds
## Number every second, which isn't output.
func _test_rapid_fire_and_regen() -> void:
	var state := GameState.new()
	state.purchased = {"rapid_fire_chance": 85, "rapid_fire_duration": 99}
	state.start_run(1, 13)
	var shots := 0
	var rapid_seen := false
	for step in range(400):
		shots += state.advance(0.25).filter(func(event): return event.type == "tick").size()
		rapid_seen = rapid_seen or state.rapid_fire_left > 0.0
	_expect(rapid_seen and state._attack_speed() >= 1.0, "a Rapid Fire chance should start Rapid Fire")
	_expect(shots > 150, "Rapid Fire should fire far more than one shot a second over 100 seconds: %d" % shots)
	state.rapid_fire_left = 1.0
	_expect(is_equal_approx(state._attack_speed(), 4.0), "Rapid Fire should fire four times as fast")
	var regen := GameState.new()
	regen.purchased = {"health_regen": 100}
	regen.start_run(1, 14)
	regen.active_encounter = null
	regen.tax_encounters_enabled = false
	var before: ScientificNumber = regen.number.copy()
	var lifetime_before: ScientificNumber = regen.lifetime_generated.copy()
	regen._regenerate(2.0)
	_expect(absf(regen.number.subtract(before).log10() - log(2.0 * regen.stat("health_regen")) / log(10.0)) < 1.0e-9, "Health Regen should add its value a second")
	_expect(regen.lifetime_generated.compare_to(lifetime_before) == 0, "Health Regen should not count as output")

## D068: Range sets the Number's reach, Damage / Meter lifts a strike by the
## enemy's distance, and Knockback pushes an enemy back to walk in again.
func _test_range_damage_per_meter_and_knockback() -> void:
	var state := GameState.new()
	state.balance_profile.ENEMY_MIX = {"basic": 1.0}
	state.purchased = {"range": 40}
	state.start_run(1, 15)
	_expect(is_equal_approx(state._range(), 50.0) and is_equal_approx(state.active_encounter.reach, 50.0), "Range at level 40 should reach 50 m")
	state.wave_accumulator = 5.0
	_expect(state.is_wave_standing(), "a basic set off at 0 should be in a 50 m reach at 5 seconds")

	var far := GameState.new()
	far.balance_profile.ENEMY_MIX = {"basic": 1.0}
	far.purchased = {"damage_per_meter": 200}
	far.start_run(1, 16)
	far.wave_accumulator = 7.5
	far._sync_encounter()
	var target: int = far.active_encounter.target_index()
	var member: Dictionary = far.active_encounter.members[target]
	member.hp = ScientificNumber.new(1.0, 9)
	far.active_encounter._sum_remaining()
	var distance := TaxEncounter.distance_of(member, 7.5)
	var event := far.tap()
	var dealt := ScientificNumber.new(1.0, 9).subtract(member.hp)
	var base := far._damage() * (far.stat("critical_factor") if event.is_critical else 1.0)
	var lifted := base * (1.0 + 0.59 * 25.0)
	_expect(is_equal_approx(distance, 25.0) and absf(dealt.log10() - log(lifted) / log(10.0)) < 1.0e-6 and absf(event.amount.log10() - log(lifted) / log(10.0)) < 1.0e-9, "Damage / Meter should lift a strike, and the Number it banks, by the enemy's distance")

	var pushed := GameState.new()
	pushed.balance_profile.ENEMY_MIX = {"basic": 1.0}
	pushed.purchased = {"knockback_chance": 80, "knockback_force": 40}
	pushed.start_run(1, 17)
	pushed.wave_accumulator = 8.0
	pushed._sync_encounter()
	var pushed_member: Dictionary = pushed.active_encounter.members[0]
	pushed_member.hp = ScientificNumber.new(1.0, 9)
	pushed.active_encounter._sum_remaining()
	var before := TaxEncounter.distance_of(pushed_member, 8.0)
	var knocked := false
	for shot in range(20):
		pushed.tap()
		if TaxEncounter.distance_of(pushed_member, 8.0) > before:
			knocked = true
			break
	_expect(knocked and absf(TaxEncounter.distance_of(pushed_member, 8.0) - before - TaxBalanceProfile.knockback_metres(6.08, "basic")) < 1.0e-6, "a knockback should push a basic back by the force's metres")
	_expect(is_equal_approx(float(pushed_member.next_hit), 8.0 + TaxEncounter.distance_of(pushed_member, 8.0) / TaxBalanceProfile.speed_metres("basic")), "a pushed enemy should hit when it walks back in")
	_expect(TaxBalanceProfile.knockback_metres(6.08, "tank") < TaxBalanceProfile.knockback_metres(6.08, "basic") / 4.0, "a heavier enemy should be pushed less")

	# An enemy pushed off the Number walks back and hits again when it arrives.
	var pile := GameState.new()
	pile.balance_profile.ENEMY_MIX = {"basic": 1.0}
	pile.balance_profile.OPENING_HIT_WAVES = 0
	pile.balance_profile.OPENING_EASED_BY = 0
	pile.start_run(1, 18)
	pile.number = ScientificNumber.new(1.0, 9)
	for step in range(41):
		pile._advance_waves(0.25)
	var landed: Dictionary = pile.active_encounter.members[0]
	_expect(int(landed.state) == TaxEncounter.AT_NUMBER, "the fixture's front enemy should be at the Number")
	pile.active_encounter.knock_back(0, 10.0)
	_expect(int(landed.state) == TaxEncounter.STANDING and is_equal_approx(TaxEncounter.distance_of(landed, pile.wave_accumulator), 10.0), "a knockback should lift an enemy off the Number")
	var hits_before := int(landed.hits)
	for step in range(5):
		pile._advance_waves(0.25)
	_expect(int(landed.hits) == hits_before + 1 and int(landed.state) == TaxEncounter.AT_NUMBER, "it should hit again when it walks back in")

## A run resumed from a save keeps each walking enemy's hit where it was due:
## one knocked back in the opening waves, whose hit falls after the wave's
## clock, and one timed on an older profile that set enemies off from nearer.
func _test_resumed_walkers_keep_their_hits() -> void:
	var pile := GameState.new()
	pile.balance_profile.ENEMY_MIX = {"basic": 1.0}
	pile.balance_profile.OPENING_HIT_WAVES = 0
	pile.balance_profile.OPENING_EASED_BY = 0
	pile.start_run(1, 18)
	pile.number = ScientificNumber.new(1.0, 9)
	while pile.wave_accumulator < 34.0:
		pile._advance_waves(0.25)
	var index := -1
	for candidate in range(pile.active_encounter.members.size()):
		if int(pile.active_encounter.members[candidate].state) == TaxEncounter.AT_NUMBER:
			index = candidate
			break
	_expect(index >= 0, "the knockback fixture should have an enemy at the Number late in the wave")
	pile.active_encounter.knock_back(index, 90.0)
	var pushed: Dictionary = pile.active_encounter.members[index]
	_expect(float(pushed.next_hit) > TaxBalanceProfile.WAVE_INTERVAL_SECONDS + float(pushed.interval), "the fixture's pushed enemy should be due after the wave's clock and its interval")
	var restored = TaxEncounter.from_dict(pile.active_encounter.to_dict())
	var back: Dictionary = restored.members[index]
	_expect(is_equal_approx(float(back.next_hit), float(pushed.next_hit)), "a knocked-back enemy should keep its hit across a reload: %f, not %f" % [float(back.next_hit), float(pushed.next_hit)])
	_expect(is_equal_approx(TaxEncounter.distance_of(back, pile.wave_accumulator), TaxEncounter.distance_of(pushed, pile.wave_accumulator)), "a knocked-back enemy should stand where it was after a reload")

	var save_path := "res://.number_go_up_test_save.json"
	var older := GameState.new()
	older.balance_profile.ENEMY_MIX = {"basic": 1.0}
	older.start_run(1, 21)
	older.number = ScientificNumber.new(1.0, 9)
	for step in range(8):
		older._advance_waves(0.25)
	older.save_path = save_path
	_expect(older.save(), "the older-profile fixture should save")
	var old_data: Dictionary = _read_json(save_path)
	old_data.balance_profile_id = "tax-foundation-v15"
	# On that profile enemies set off 60 m out, so a basic walked in for 6
	# seconds rather than 10, and arrived 4 seconds sooner.
	var due: Array = []
	for member in old_data.active_encounter.members:
		if int(member.state) == TaxEncounter.STANDING:
			member.next_hit = float(member.next_hit) - 4.0
			member.sets_off = float(member.next_hit) - 6.0
			due.append(float(member.next_hit))
	_write_json(save_path, old_data)
	var resumed := GameState.new()
	resumed.balance_profile.ENEMY_MIX = {"basic": 1.0}
	resumed.save_path = save_path
	resumed.load()
	var walkers: Array = resumed.active_encounter.members.filter(func(member): return int(member.state) == TaxEncounter.STANDING)
	_expect(not walkers.is_empty() and walkers.size() == due.size(), "the older-profile fixture should resume with its walkers")
	var aligned := true
	for position in range(walkers.size()):
		var walker: Dictionary = walkers[position]
		var left := TaxEncounter.distance_of(walker, resumed.wave_accumulator) - TaxBalanceProfile.stop_distance("basic")
		var expected_left := maxf(0.0, TaxBalanceProfile.speed_metres("basic") * (float(walker.next_hit) - resumed.wave_accumulator))
		aligned = aligned and is_equal_approx(float(walker.next_hit), float(due[position])) and absf(left - minf(expected_left, TaxBalanceProfile.SPAWN_DISTANCE_METRES - TaxBalanceProfile.stop_distance("basic"))) < 1.0e-6
	_expect(aligned, "a walker resumed on today's profile should keep its hit and stand as far out as that hit is away")
	resumed.clear_save()

## D068: Orbs circle the Number and kill any enemy but a boss they touch.
func _test_orbs_kill_what_they_touch() -> void:
	var state := GameState.new()
	state.balance_profile.ENEMY_MIX = {"tank": 1.0}
	state.purchased = {"orbs": 4, "orb_speed": 38}
	state.start_run(1, 19)
	state.number = ScientificNumber.new(1.0, 9)
	var killed := 0
	for step in range(4 * 30):
		state._advance_waves(0.25)
	for member in state.active_encounter.members:
		if int(member.state) == TaxEncounter.KILLED:
			killed += 1
	# Slow tanks cross the 60 m circle over 1.8 s, and four orbs at 6.1 turns a
	# minute pass any direction every 2.5 s, so most are caught.
	_expect(killed > 5, "orbs should kill tanks walking through their circle: %d" % killed)
	_expect(state.coins > 0, "an orb kill should pay like any kill")
	var boss := GameState.new()
	boss.purchased = {"orbs": 4, "orb_speed": 38}
	boss.start_run(1, 20)
	boss.wave = 10
	boss.active_encounter = _lone_boss(boss, 10)
	boss.active_encounter.members[0].sets_off = 0.0
	for step in range(4 * 30):
		boss._advance_waves(0.25)
	_expect(boss.active_encounter.boss_index() >= 0, "orbs should never kill a boss")
	var none := GameState.new()
	none.start_run(1, 19)
	_expect(none.orb_angles().is_empty(), "no orbs should circle without the row")

## D068: the Health row sets the Number a run starts with, as The Tower's
## tower starts at full health; Workshop levels are permanent.
func _test_health_sets_the_starting_number() -> void:
	var state := _funded_state()
	state.purchased = {"health": 100, "damage": 60, "health_regen": 10}
	_expect(state.start_run(1, 44), "a fresh run should start from the permanent Workshop")
	_expect(state.number.compare_to(ScientificNumber.from_float(state.get_definition("health").value_at(100))) == 0, "Health should set the fresh-run Number")
	_expect(state.get_rate_per_second().compare_to(ScientificNumber.from_float(state.stat("damage") * 1.0 + state.stat("health_regen"))) == 0, "the rate should be Damage a shot at Attack Speed, plus Regen")
	_expect(not state.purchase("damage"), "permanent Workshop purchases must be locked during a run")
	state.end_run()
	_expect(state.get_owned("health") == 100 and state.get_owned("damage") == 60, "Workshop levels must survive retreat")
	var bare := GameState.new()
	bare.start_run(1, 44)
	_expect(bare.number.compare_to(ScientificNumber.from_float(5.0)) == 0, "a fresh Tower starts at Health 5")

func _test_save_round_trip_and_legacy_migration() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original: GameState = _funded_state()
	original.save_path = save_path
	original.purchased = {"damage": 2, "health": 1}
	original.workshop_groups = ["range", "cash"]
	original.workshop.automation_targets = ["health"]
	original.tier_records["1"] = {"highest_wave": GameState.TIER_UNLOCK_WAVE, "best_time": 0.0, "milestones_claimed": [10, 20, 25, 30, 40, 50, 60, 75, 90, 100]}
	_expect(original.start_run(2, 77), "an unlocked Tier 2 run should start")
	original.workshop.tick_count = 7
	original.rapid_fire_left = 1.25
	original.tap()
	var saved_remaining: ScientificNumber = original.active_encounter.remaining_liability.copy()
	var saved_rng_state := original.rng.state
	_expect(original.save(), "the current save should write")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV12.VERSION and not _read_json(save_path).has("second_wind_used"), "the save should be V12, without the retired Second Wind")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.get_owned("damage") == 2 and restored.workshop.tick_count == 7, "saved permanent Workshop state should round-trip")
	_expect(restored.workshop_groups == original.workshop_groups and restored.is_unlocked(restored.get_definition("range")), "bought Workshop unlocks should round-trip")
	_expect(restored.coins == original.coins, "a V12 save's Coins should load as they are, not scaled again")
	_expect(restored.workshop.selected_category == original.workshop.selected_category, "a save should round-trip the open Workshop category")
	_expect(restored.in_run and restored.selected_tier == 2, "a save should restore the active tier run")
	_expect(restored.active_encounter.remaining_liability.compare_to(saved_remaining) == 0, "a save should restore exact encounter liability")
	_expect(restored.run_seed == 77 and restored.rng.state == saved_rng_state, "a save should restore deterministic run RNG state")
	_expect(is_equal_approx(restored.rapid_fire_left, 1.25) and restored.run_peak_number.compare_to(original.run_peak_number) == 0, "a save should restore the run's Rapid Fire and peak")
	restored.clear_save()

	# A real V4 save: built from a live state, then reshaped exactly as V4 stored
	# it, with bays and the Armor rank in a field of its own. Its old Workshop
	# ranks are refunded on The Tower's Coin scale (D068).
	var v4_source := _funded_state()
	v4_source.knowledge = 4
	v4_source.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	_expect(v4_source.start_run(2, 55), "the V4 fixture should start a Tier 2 run")
	v4_source.tap()
	var v4_remaining: ScientificNumber = v4_source.active_encounter.remaining_liability.copy()
	var v4_rng_state := v4_source.rng.state
	var v4: Dictionary = SaveDataV12.make(v4_source)
	v4.version = 4
	v4.purchased = {"stronger_tap": 2, "generator": 1}
	v4.erase("workshop_groups")
	v4.tax_resistance_rank = 3
	v4.focus = "speed"
	v4.workshop = {"selected_bay": "logic", "tick_count": 2, "automation_targets": [], "legacy_credit": 0}
	_write_json(save_path, v4)
	var migrated_v4 := GameState.new()
	migrated_v4.save_path = save_path
	migrated_v4.load()
	# Tap Damage 2 + 2, Damage 2, and three Armor ranks 4 + 4 + 5, all x15.
	_expect(migrated_v4.purchased.is_empty(), "a V4 save's old Workshop ranks, Armor included, should be refunded")
	# The fixture's record reached wave 100 with nothing claimed, so migration
	# also pays those checkpoints' Coin bonuses on load (D030).
	var v4_owed_coins := 0
	for checkpoint in migrated_v4.balance_profile.COIN_MILESTONE_WAVES:
		if checkpoint <= GameState.TIER_UNLOCK_WAVE:
			v4_owed_coins += migrated_v4.balance_profile.milestone_bonus(1, checkpoint)
	_expect(migrated_v4.coins == (v4_source.coins + 19) * 15 + v4_owed_coins and migrated_v4.knowledge == 4, "V4 currencies should migrate on The Tower's scale, with the refund and the checkpoints the record had passed")
	_expect(migrated_v4.get_tier_best(1) == GameState.TIER_UNLOCK_WAVE, "V4 tier records should migrate")
	_expect(migrated_v4.focus_path == ProgressionTaxonomy.ATTACK, "a V4 Speed focus should land on Attack")
	_expect(migrated_v4.workshop.selected_category == ProgressionTaxonomy.UTILITY, "a V4 Logic tab should land on Utility")
	_expect(migrated_v4.workshop.tick_count == 2, "V4 Workshop state beside the bay should survive")
	_expect(migrated_v4.in_run and migrated_v4.selected_tier == 2, "a V4 live run should survive migration")
	_expect(migrated_v4.active_encounter.remaining_liability.compare_to(v4_remaining) == 0, "a migrated V4 run should keep its exact remaining Liability")
	_expect(migrated_v4.rng.state == v4_rng_state, "a migrated V4 run should keep its RNG state")
	var rewritten := GameState.new()
	rewritten.save_path = save_path
	rewritten.load()
	_expect(rewritten.coins == migrated_v4.coins and rewritten.focus_path == ProgressionTaxonomy.ATTACK, "migration should rewrite the save in the current shape immediately, converted once")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV12.VERSION, "the rewritten save should carry the current version")
	var kept_v4 := "res://.number_go_up_test_save.v4-backup.json"
	_expect(int(_read_json(kept_v4).get("version", 0)) == 4, "migration should keep the V4 file it read, unchanged, beside the new save")
	rewritten.clear_save()
	_expect(not FileAccess.file_exists(kept_v4), "clearing the save should also remove its migration copy")

	var v3 := {
		"version": 3,
		"number": ScientificNumber.from_float(500).to_dict(),
		"lifetime": ScientificNumber.from_float(1000).to_dict(),
		"highest": ScientificNumber.from_float(1000).to_dict(),
		"purchased": {"stronger_tap": 2},
		"workshop": {"selected_bay": "chance"},
		"focus": "output",
		"tax_resistance_rank": 4,
		"coins": 25,
		"tier_records": {},
		"in_run": false,
		"statistics": {},
		"settings": {"ambience": true, "muted": true},
	}
	_write_json(save_path, v3)
	var migrated_v3 := GameState.new()
	migrated_v3.save_path = save_path
	migrated_v3.load()
	_expect(migrated_v3.settings.get("ambience") == null and bool(migrated_v3.settings.get("muted")), "the retired ambience setting should be purged without disturbing the rest")
	_expect(migrated_v3.number.is_zero(), "V3 banked Number should retire when migrating to run-only Number")
	# 25 Coins, Tap Damage 2 + 2, Armor 4 + 4 + 5 + 5, all x15.
	_expect(migrated_v3.purchased.is_empty() and migrated_v3.coins == (25 + 4 + 18) * 15, "V3 Workshop ranks and Coins should be kept as Coins on The Tower's scale")
	_expect(migrated_v3.focus_path == ProgressionTaxonomy.ATTACK and migrated_v3.workshop.selected_category == ProgressionTaxonomy.ATTACK, "V3 bays should map onto categories")
	migrated_v3.clear_save()

	var v2 := {
		"version": 2,
		"number": ScientificNumber.from_float(500).to_dict(),
		"lifetime": ScientificNumber.from_float(1000).to_dict(),
		"highest": ScientificNumber.from_float(500).to_dict(),
		"purchased": {"stronger_tap": 1},
		"workshop": {},
		"wave": 25,
		"highest_wave": 33,
		"in_run": false,
		"statistics": {},
		"settings": {},
		"last_seen_unix": Time.get_unix_time_from_system(),
	}
	_write_json(save_path, v2)
	var migrated_v2 := GameState.new()
	migrated_v2.save_path = save_path
	migrated_v2.load()
	_expect(migrated_v2.number.is_zero(), "V2 banked Number should retire under the run-only Number model")
	_expect(migrated_v2.get_tier_best(1) == 33, "V2 highest wave should become the Tier 1 record")
	_expect(migrated_v2.coins == 2 * 15 + migrated_v2.balance_profile.milestone_bonus(1, 10) + migrated_v2.balance_profile.milestone_bonus(1, 25), "a V2 rank should be refunded, with the checkpoints its record passed")
	_expect(not migrated_v2.in_run and migrated_v2.wave == 1, "a banked V2 run should become a fresh, non-exploitable run")
	migrated_v2.clear_save()

	# Malformed and newer-version saves must not crash or half-load: the load
	# leaves the fresh default state.
	for broken in [{"version": 99, "number": ScientificNumber.from_float(5).to_dict(), "lifetime": ScientificNumber.from_float(5).to_dict()}, {"version": 5}, {}]:
		_write_json(save_path, broken)
		var refused := GameState.new()
		refused.save_path = save_path
		refused.load()
		_expect(refused.number.is_zero() and refused.coins == 0 and not refused.in_run, "an unreadable save should leave a fresh state, not a partial one")
		refused.clear_save()
	_expect(_leftover_save_files().is_empty(), "clearing the save should leave no file behind")
	var v1 := {
		"version": 1,
		"number": ScientificNumber.from_float(100).to_dict(),
		"lifetime": ScientificNumber.from_float(1000).to_dict(),
		"highest": ScientificNumber.from_float(100).to_dict(),
		"purchased": {"stronger_tap": 1, "steady_hand": 1, "workshop_bench": 2, "prototype_oddity": 4},
		"auto_selected": "generator",
		"statistics": {},
		"settings": {"ambience": true},
		"last_seen_unix": Time.get_unix_time_from_system(),
	}
	_write_json(save_path, v1)
	var migrated_v1 := GameState.new()
	migrated_v1.save_path = save_path
	migrated_v1.load()
	_expect(migrated_v1.settings.get("ambience") == null, "the V1 migration should also purge the retired ambience setting")
	_expect(migrated_v1.purchased.is_empty() and migrated_v1.coins == 4 * 15, "V1 hand upgrades should be refunded as Coins")
	_expect(migrated_v1.workshop.legacy_credit == 6, "unmatched V1 progress should become Workshop credit")
	_expect(migrated_v1.workshop.automation_targets == ["generator"], "V1 automation should become first priority")
	migrated_v1.clear_save()

## D068: a save from before The Tower's Workshop keeps everything it paid for,
## as Coins: every retired rank is refunded at its old price, and the balance
## and refund move to The Tower's scale, once. Run ranks of retired rows die
## with them; the Lab ladders move to the same scale.
func _test_old_workshop_is_refunded_on_the_towers_scale() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var source := GameState.new()
	source.coins = 70
	var v11: Dictionary = SaveDataV12.make(source)
	v11.version = 11
	v11.erase("workshop_groups")
	v11.purchased = {"stronger_tap": 100, "generator": 40, "unknown_row": 3}
	_write_json(save_path, v11)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.load_status == GameState.LOAD_OK and loaded.coins == (70 + 2068 + 206) * 15, "a V11 save should be refunded its ranks at their old prices, on The Tower's scale: %d" % loaded.coins)
	_expect(loaded.purchased == {"unknown_row": 3} and loaded.get_workshop_level() == 0, "retired rows should be emptied, an id it never knew kept")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV12.VERSION and int(_read_json("res://.number_go_up_test_save.v11-backup.json").get("version", 0)) == 11, "a V11 save should be rewritten as V12, with the V11 file kept")
	var again := GameState.new()
	again.save_path = save_path
	again.load()
	_expect(again.coins == loaded.coins, "the conversion should happen once")
	again.clear_save()
	var labs := GameState.new()
	_expect(labs.get_lab_cost("lab_damage") == 800 * 15, "Lab prices should move to The Tower's Coin scale")
	_expect(_leftover_save_files().is_empty(), "the refund checks should leave no file behind")

## D028: no save the loader cannot read is ever written over. A newer build's
## save pauses saving; an unreadable one is moved aside intact and the backup
## the previous save left behind loads instead; a write swaps in whole.
func _test_bad_saves_are_never_written_over() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var backup_path := save_path + ".bak"

	# Every save after the first keeps the one it replaced as the backup, and
	# leaves no temp file behind.
	var writer := _funded_state()
	writer.save_path = save_path
	writer.coins = 111
	_expect(writer.save(), "a first save should write")
	writer.coins = 222
	_expect(writer.save(), "a second save should write")
	_expect(int(_read_json(save_path).get("coins", 0)) == 222 and int(_read_json(backup_path).get("coins", 0)) == 111, "a save should keep the save it replaced as the backup")
	_expect(not FileAccess.file_exists(save_path + ".tmp"), "a finished save should leave no temp file")
	writer.clear_save()

	# A save from a newer build is left byte for byte, and saving pauses.
	var future: Dictionary = SaveDataV12.make(_funded_state())
	future.version = SaveDataV12.VERSION + 1
	_write_json(save_path, future)
	var future_text := FileAccess.get_file_as_string(save_path)
	var older_build := GameState.new()
	older_build.save_path = save_path
	older_build.load()
	_expect(older_build.load_status == GameState.LOAD_NEWER and older_build.saving_paused, "a newer save should pause saving")
	_expect(older_build.coins == 0, "a newer save should not be half-read")
	_expect(not older_build.save(), "a paused save should refuse to write")
	_expect(FileAccess.get_file_as_string(save_path) == future_text, "a newer save should be left exactly as it was")
	older_build.clear_save()

	# A live save that cannot be read is moved aside, and the backup loads.
	var good := _funded_state()
	good.coins = 999
	_write_json(backup_path, SaveDataV12.make(good))
	var torn := JSON.stringify(SaveDataV12.make(_funded_state()))
	_write_text(save_path, torn.substr(0, torn.length() / 2))
	var recovered := GameState.new()
	recovered.save_path = save_path
	recovered.load()
	_expect(recovered.load_status == GameState.LOAD_RECOVERED and recovered.coins == 999, "a torn live save should fall back to the backup")
	var moved_aside := _leftover_save_files().filter(func(name): return str(name).contains(GameState.QUARANTINE_INFIX))
	_expect(moved_aside.size() == 1 and FileAccess.get_file_as_string("res://" + str(moved_aside[0])) == torn.substr(0, torn.length() / 2), "the torn save should be kept, byte for byte, beside the live one")
	_expect(recovered.save() and int(_read_json(save_path).get("coins", 0)) == 999, "saving after a recovery should write the recovered state")
	recovered.clear_save()
	_expect(_leftover_save_files().is_empty(), "clearing the save should also remove the moved-aside copy")

	# With no backup to fall back to, the game starts fresh and says so, and
	# the unreadable save is still kept.
	var typed_wrong: Dictionary = SaveDataV12.make(_funded_state())
	typed_wrong.purchased = "not a dictionary"
	# Cash is read only while a run is saved, so the bad value sits in one.
	var cash_wrong: Dictionary = SaveDataV12.make(_funded_state())
	cash_wrong.in_run = true
	cash_wrong.cash = "not a number"
	var earned_wrong: Dictionary = SaveDataV12.make(_funded_state())
	earned_wrong.in_run = true
	earned_wrong.run_cash_earned = {"exponent": 0, "mantissa": "lots"}
	# A plain highest block, without the exact bits every saved number now
	# carries, so the text to corrupt is known.
	var finite_data: Dictionary = SaveDataV12.make(_funded_state())
	finite_data.highest = {"exponent": 0, "mantissa": 0.0}
	var not_finite := JSON.stringify(finite_data).replace('"highest":{"exponent":0,"mantissa":0.0}', '"highest":{"exponent":0,"mantissa":1e999}')
	for unreadable in [JSON.stringify(typed_wrong), JSON.stringify(cash_wrong), JSON.stringify(earned_wrong), not_finite, "{", ""]:
		_write_text(save_path, unreadable)
		var fresh := GameState.new()
		fresh.save_path = save_path
		fresh.load()
		_expect(fresh.load_status == GameState.LOAD_UNREADABLE and fresh.coins == 0 and not fresh.in_run, "an unreadable save with no backup should start a fresh game")
		_expect(not FileAccess.file_exists(save_path) and _leftover_save_files().size() == 1, "the unreadable save should be moved aside rather than left to be written over")
		fresh.clear_save()

	# A live save that vanished between the two renames of a save still has its
	# backup.
	_write_json(backup_path, SaveDataV12.make(good))
	var interrupted := GameState.new()
	interrupted.save_path = save_path
	interrupted.load()
	_expect(interrupted.load_status == GameState.LOAD_RECOVERED and interrupted.coins == 999, "a missing live save should fall back to the backup")
	interrupted.clear_save()
	var nothing := GameState.new()
	nothing.save_path = save_path
	nothing.load()
	_expect(nothing.load_status == GameState.LOAD_NEW_GAME, "no save at all should read as a new game")
	_expect(ScientificNumber.new(INF, 0).is_zero() and ScientificNumber.new(NAN, 3).is_zero(), "a non-finite value should read as zero rather than hang")
	_expect(_leftover_save_files().is_empty(), "the bad-save checks should leave no file behind")

## Every field V5 gained after it shipped survives migration to the current
## schema, and the V5 file is kept beside the new save.
func _test_v5_saves_migrate_without_loss() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var source := _funded_state()
	source.knowledge = 9
	source.gems = 41
	source.card_ranks = {"card_damage": 3}
	source.card_active = ["card_damage"]
	source.lab_ranks = {"lab_damage": 2}
	source.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	source.tier_records["1"].milestones_claimed = [10, 25]
	_expect(source.start_lab("lab_speed"), "the V5 fixture should have research running")
	_expect(source.start_run(2, 88), "the V5 fixture should hold a live run")
	source.rig_ranks = {"damage": 2}
	for tap_index in range(4):
		source.tap()
	var v5: Dictionary = SaveDataV12.make(source)
	v5.version = 5
	v5.purchased = {"stronger_tap": 7, "tax_resistance": 3}
	v5.rig_ranks = {"stronger_tap": 2, "damage": 2}
	v5.erase("workshop_groups")
	v5.erase("rapid_fire_left")
	v5.erase("tick_accumulator")
	v5.erase("critical_chain")
	v5.erase("lab_slots")
	_write_json(save_path, v5)
	var migrated := GameState.new()
	migrated.save_path = save_path
	migrated.load()
	_expect(migrated.load_status == GameState.LOAD_OK, "a V5 save should load")
	# The record reached wave 100 but claimed only 10 and 25 at the old rate of
	# one Gem (D030): those two are topped up, and every other checkpoint up to
	# 100 is paid on load, Coin bonus included.
	var profile = migrated.balance_profile
	var expected_gems := 41
	# Its Coins and old ranks (Tap Damage 14, Armor 13) are refunded on The
	# Tower's scale (D068) before the checkpoints pay.
	var expected_coins := (source.coins + 14 + 13) * 15
	for checkpoint in profile.MILESTONE_WAVES:
		if checkpoint > GameState.TIER_UNLOCK_WAVE:
			continue
		if checkpoint == 10 or checkpoint == 25:
			expected_gems += profile.milestone_gems(1, checkpoint) - GameState.PRE_V8_MILESTONE_GEMS
		else:
			expected_gems += profile.milestone_gems(1, checkpoint)
			expected_coins += profile.milestone_bonus(1, checkpoint)
	_expect(migrated.coins == expected_coins and migrated.knowledge == 9 and migrated.gems == expected_gems, "V5 currencies should survive migration, plus the milestones it is owed")
	_expect(migrated.purchased.is_empty(), "V5 Workshop ranks should be refunded (D068)")
	_expect(migrated.get_card_level("card_damage") == 3 and migrated.is_card_active("card_damage"), "V5 Cards should survive migration")
	_expect(migrated.lab_ranks.get("lab_damage") == 2.0 and migrated.lab_active.has("lab_speed"), "V5 Labs should survive migration")
	_expect(migrated.get_tier_record(1).milestones_claimed == [10, 20, 25, 30, 40, 50, 60, 75, 90, 100], "V5 records should survive migration, with every passed checkpoint claimed")
	_expect(migrated.in_run and migrated.rig_owned("damage") == 2 and not migrated.rig_ranks.has("stronger_tap") and migrated.rng.state == source.rng.state, "a V5 live run should survive migration, its retired rows' run ranks gone")
	_expect(migrated.lab_slots_total() == LabResearch.LEGACY_SLOTS, "a V5 save should keep the two Lab slots every player then had")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV12.VERSION, "a V5 save should be rewritten in the current shape at once")
	_expect(int(_read_json("res://.number_go_up_test_save.v5-backup.json").get("version", 0)) == 5, "the V5 file should be kept beside the new save")
	migrated.clear_save()
	_expect(_leftover_save_files().is_empty(), "the V5 migration check should leave no file behind")

## D006 holds past the moment of saving: a run reloaded mid-way, with ticks,
## taps and a live crit chain, ends exactly where the uninterrupted run does.
func _test_long_run_replays_identically_across_a_reload() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var build := {"damage": 100, "attack_speed": 60, "critical_chance": 60, "multishot_chance": 60, "multishot_targets": 3, "bounce_shot_chance": 40, "bounce_shot_targets": 3, "rapid_fire_chance": 50, "rapid_fire_duration": 50, "knockback_chance": 40, "knockback_force": 20, "orbs": 2, "orb_speed": 20, "defense_percent": 60, "health": 200, "health_regen": 100, "free_attack_upgrade": 60, "cash_per_wave": 40, "interest": 50}
	var frames := 60 * 400
	var straight := GameState.new()
	straight.purchased = build.duplicate()
	straight.start_run(1, 2024)
	for frame in range(frames):
		straight.advance(1.0 / 60.0)
		if frame % 20 == 0:
			straight.tap()
	var reloaded := GameState.new()
	reloaded.save_path = save_path
	reloaded.purchased = build.duplicate()
	reloaded.start_run(1, 2024)
	var saw_chain := false
	for frame in range(frames):
		if frame == 60 * 137 + 7:
			saw_chain = reloaded.rapid_fire_left > 0.0 or reloaded.tick_accumulator > 0.0
			reloaded.save()
			var resumed := GameState.new()
			resumed.save_path = save_path
			resumed.load()
			reloaded = resumed
		reloaded.advance(1.0 / 60.0)
		if frame % 20 == 0:
			reloaded.tap()
	_expect(saw_chain, "the reload should land mid-shot or mid-Rapid Fire, or this check proves nothing")
	_expect(reloaded.lifetime_generated.to_dict() == straight.lifetime_generated.to_dict() and reloaded.number.to_dict() == straight.number.to_dict(), "a reloaded run should produce exactly what the uninterrupted run did")
	_expect(reloaded.rng.state == straight.rng.state and reloaded.wave == straight.wave and reloaded.coins == straight.coins and reloaded.rig_ranks == straight.rig_ranks and reloaded.cash.to_dict() == straight.cash.to_dict(), "a reloaded run should reach the same wave, Coins, Cash, free upgrades and RNG state")
	reloaded.clear_save()

func _test_offline_policy() -> void:
	var outside := GameState.new()
	outside.purchased.damage = 1
	var award := outside.apply_offline(GameState.OFFLINE_CAP_SECONDS + 3600.0)
	_expect(award.amount.is_zero(), "the between-run Workshop must not generate run Number offline")
	var hub_tap := outside.tap()
	_expect(hub_tap.amount.is_zero() and outside.number.is_zero(), "tapping outside a run must not bank a head start")
	var active := GameState.new()
	active.purchased.damage = 1
	active.start_run(1, 1)
	active.number = ScientificNumber.from_float(100)
	var before := active.number.copy()
	var frozen := active.apply_offline(3600.0)
	_expect(frozen.amount.is_zero(), "an active run must not receive risk-free offline production")
	_expect(active.number.compare_to(before) == 0, "an active run should resume from the exact frozen Number")

func _test_prestige_reset_and_gain() -> void:
	var state := GameState.new()
	state.purchased = {"damage": 2, "health": 1}
	_expect(state.start_run(1, 7), "the Prestige fixture should start a run")
	state.wave = 12
	state.number = ScientificNumber.from_float(1)
	state.lifetime_generated = ScientificNumber.from_float(1000000000.0)
	state.workshop.tick_count = 5
	state.run_coins_earned = 9
	state.run_gems_earned = 2
	state.last_run_summary = RunSummary.new(3, 4, 0, null, 1, "retreat")
	var expected_gain := state.get_prestige_knowledge_gain()
	_expect(expected_gain > 0, "progress far past the threshold should grant Knowledge")
	var gain := state.prestige()
	_expect(gain == expected_gain and state.knowledge == gain, "Prestige should bank the expected Knowledge")
	_expect(state.number.is_zero() and state.get_owned("damage") == 2, "Prestige should reset run Number but retain permanent Workshop ranks")
	var summary := state.last_run_summary
	_expect(summary != null and summary.outcome == "prestige", "Prestige should replace the previous run summary")
	_expect(summary.wave_reached == 12 and summary.tier_id == 1, "Prestige should record the run's wave and tier before reset")
	_expect(summary.coins_earned == 9 and summary.gems_earned == 2 and summary.knowledge_gained == gain, "Prestige should record every reward earned by that run")
	_expect(summary.final_hit.is_zero() and summary.attack_gap.is_zero() and summary.defense_gap.is_zero(), "Prestige should not record a killing hit or gaps")
	_expect(state.prestige() == 0 and state.last_run_summary == summary and state.knowledge == gain, "a repeated Prestige should not change the summary or pay twice")
	_expect(state.purchase_insight(), "Knowledge should buy Insight")
	_expect(state.get_owned("insight") == 1, "Insight should survive reset")

func _test_first_run_funds_permanent_workshop() -> void:
	var state := GameState.new()
	_expect(state.start_run(1, 7), "the first run should start without prior Workshop ranks")
	var profile = state.balance_profile
	var expected: int = profile.milestone_bonus(1, 10) + _roster_kill_coins(state, 7, 1, 20)
	for completed_wave in range(1, 21):
		state.active_encounter.remaining_liability = ScientificNumber.new()
		state._resolve_wave_boundary()
	# D068: every kill pays its type's Coins times its wave, every wave's end
	# its Coins / Wave, plus the wave 10 checkpoint, so a first run to wave 20
	# funds real levels at The Tower's prices.
	_expect(state.coins == expected and state.coins > 1000, "clearing Tier 1 to wave 20 should pay every kill, every wave's end and the wave 10 bonus: %d" % state.coins)
	state.end_run()
	var before := state.coins
	var damage_price := state.get_workshop_coin_cost(state.get_definition("damage"))
	var health_price := state.get_workshop_coin_cost(state.get_definition("health"))
	_expect(state.purchase("damage"), "first-run Coins should buy a permanent Damage level")
	_expect(state.purchase("health"), "first-run Coins should also buy the first Health level")
	_expect(state.coins == before - damage_price - health_price, "first Workshop purchases should spend Coins, not Number")
	_expect(state.purchase_ranks("damage", GameState.MAX_BUY) >= 8, "the first failed run should fund a stack of levels")
	state.start_run(1, 8)
	_expect(state.stat("damage") > 30.0 and state.number.compare_to(ScientificNumber.from_float(10.0)) == 0, "the next run should start from the upgraded permanent baseline")

## D040: Tier 1 runs one set of rules from wave 1, and Wave HP follows one
## smooth curve. Since D068 a fresh run is The Tower's fresh tower: Damage 3
## once a second and Health 5, on every tier.
func _test_tier_one_opening() -> void:
	var fresh := GameState.new()
	fresh.start_run(1, 3)
	var profile = fresh.balance_profile
	_expect(fresh.get_rate_per_second().compare_to(ScientificNumber.from_float(3.0 + 0.0005)) == 0, "a fresh run should shoot Damage 3 a second, with The Tower's trace of Regen")
	_expect(fresh.number.compare_to(ScientificNumber.from_float(5.0)) == 0, "a Tier 1 run should start at Health 5")
	var tier_two := GameState.new()
	tier_two.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	tier_two.start_run(2, 3)
	_expect(tier_two.number.compare_to(ScientificNumber.from_float(5.0)) == 0, "Tier 2 should start at Health too")

	# One curve from wave 1: below wave 100, no ordinary enemy's HP or Hit is
	# ever more than 1.6 times the one a wave before it. The wave-21 spike D040
	# removed was 3x HP and 30x Hit in five waves. Milestone steps land on boss
	# waves, so neighbours are compared across them; wave 100's x1.5 step is
	# the tier gate and is deliberate. A whole wave's HP also moves with how
	# many tanks it draws (D066), so the curve is one enemy's.
	var previous := 0
	for check_wave in range(1, 101):
		if profile.is_boss_wave(check_wave):
			continue
		var hp := profile.enemy_liability(1, check_wave)
		var hit := profile.enemy_collection(1, check_wave)
		_expect(hit.compare_to(ScientificNumber.new()) > 0, "an ordinary Hit should be positive (wave " + str(check_wave) + ")")
		if previous > 0 and check_wave < 100:
			var growth := pow(10.0, hp.log10() - profile.enemy_liability(1, previous).log10())
			var hit_growth := pow(10.0, hit.log10() - profile.enemy_collection(1, previous).log10())
			_expect(growth > 1.0 and growth < 1.6, "Wave HP should rise smoothly from wave " + str(previous) + " to " + str(check_wave))
			_expect(hit_growth > 1.0 and hit_growth < 1.6, "the Hit should rise smoothly from wave " + str(previous) + " to " + str(check_wave))
		previous = check_wave
	_expect(profile.enemy_liability(1, 21).compare_to(profile.enemy_liability(1, 19)) > 0 and pow(10.0, profile.enemy_liability(1, 21).log10() - profile.enemy_liability(1, 19).log10()) < 1.4, "wave 21 should no longer jump")
	# D063: the Hit is the wave's HP divided by a ratio on The Tower's shape,
	# which grows with the wave: about 2.4 at wave 1, 11 at 100, 118 at 500 and
	# 1,480 at 1,000, so enemies grow tankier than they hit.
	var previous_ratio := 0.0
	for check_wave in [1, 21, 49, 99, 101, 499, 501, 999, 1001, 5001]:
		var hp_log := profile.liability_for_wave(1, check_wave).log10()
		var hit_log := profile.collection_for_wave(1, check_wave).log10()
		var ratio := pow(10.0, hp_log - hit_log)
		_expect(absf(hp_log - hit_log - profile.hit_ratio_log10(check_wave)) < 0.000001, "an ordinary Hit should be the wave's HP over the D063 ratio (wave " + str(check_wave) + ")")
		_expect(ratio >= previous_ratio, "enemies should never grow less tanky relative to their Hit (wave " + str(check_wave) + ")")
		previous_ratio = ratio
	for anchor in [[1, 2.4], [100, 11.0], [500, 118.0], [1000, 1480.0]]:
		var anchor_ratio := pow(10.0, profile.hit_ratio_log10(int(anchor[0])))
		_expect(absf(anchor_ratio / float(anchor[1]) - 1.0) < 0.05, "the ratio should sit on The Tower's shape at wave %d: %f" % [int(anchor[0]), anchor_ratio])
	_expect(profile.collection_for_wave(2, 21).compare_to(profile.collection_for_wave(1, 21).multiply_scalar(20.0)) == 0, "Tier 2 should multiply the same Hit curve by 20")
	# D065: a boss wave sends its ordinary enemies and a boss, which carries
	# twenty enemies' HP and hits like one (D063).
	var boss_run := GameState.new()
	boss_run.start_run(1, 3)
	boss_run.wave = 10
	boss_run.active_encounter = boss_run._make_encounter(10)
	var boss_at: int = boss_run.active_encounter.boss_index()
	var boss_member: Dictionary = boss_run.active_encounter.members[boss_at]
	var one_enemy_hp_10 := profile._from_log10(profile._wave_hp_log10(10))
	var ordinary_hit_10 := profile._from_log10(profile._wave_hit_log10(10))
	_expect(boss_run.active_encounter.members.size() == profile.ordinary_members(10) + 1 and boss_run.active_encounter.members.filter(func(member): return bool(member.boss)).size() == 1, "a boss wave should send its ordinary enemies and one boss")
	_expect(absf(boss_member.max.log10() - one_enemy_hp_10.multiply_scalar(profile.BOSS_HP_WEIGHT).log10()) < 0.000001, "a boss should carry twenty enemies' HP")
	_expect(absf(boss_member.wave_hit.multiply_scalar(TaxEncounter.hit_part(boss_member)).log10() - ordinary_hit_10.log10()) < 0.000001, "a boss should hit like one ordinary enemy of its wave (D063)")
	# Doing nothing still ends, and earns clearly less than a player tapping
	# once a second. A fresh Tower (D068) lasts about 11 minutes idle and 18
	# tapping.
	var no_action := GameState.new()
	no_action.start_run(1, 7)
	for step in range(4 * 1200):
		if not no_action.in_run:
			break
		no_action.advance(0.25)
	var one_tap := GameState.new()
	one_tap.start_run(1, 7)
	for step in range(4 * 1200):
		if not one_tap.in_run:
			break
		if step % 4 == 0:
			one_tap.tap()
		one_tap.advance(0.25)
	_expect(not no_action.in_run and not one_tap.in_run, "both openings should end within twenty minutes")
	_expect(no_action.coins * 4 < one_tap.coins * 3, "a no-action opening must earn clearly less than tapping once a second")
	var armored := GameState.new()
	armored.purchased = {"defense_percent": 1}
	armored.start_run(1, 3)
	armored.wave = 21
	armored.active_encounter = armored._make_encounter(21)
	_expect(armored.get_effective_collection().compare_to(profile.collection_for_wave(1, 21, armored.run_seed).multiply_scalar(0.995)) == 0, "Defense % should reduce Tier 1's Hit")
	_expect(tier_two.get_effective_collection().compare_to(tier_two.active_encounter.collection) == 0, "Tier 2's opening hit should be its base")

	# An unbeaten wave's members land and stay (D058); at the end of its clock
	# it moves on (D037). Nothing was cleared, so its one Coin is not paid and
	# it sets no record, and its members carry into the next wave.
	var stuck := GameState.new()
	# Fast enemies, which all arrive inside the wave's clock (D068's 100 m).
	stuck.balance_profile.ENEMY_MIX = {"fast": 1.0}
	stuck.start_run(1, 3)
	stuck.number = ScientificNumber.from_float(1000.0)
	var before: ScientificNumber = stuck.number.copy()
	var hit := stuck.get_effective_collection()
	var one_share: float = TaxEncounter.hit_part(stuck.active_encounter.members[0])
	var sent: int = stuck.active_encounter.members.size()
	var event := stuck._resolve_wave_boundary()
	_expect(event.type == "tax_collection" and absf(event.amount.log10() - hit.multiply_scalar(one_share).log10()) < 0.000001, "each member should land one enemy's Hit")
	# In the opening (D059) each member hits once and leaves: one enemy's Hit
	# each, once, whatever HP its type carries (D066).
	_expect(absf(before.subtract(stuck.number).log10() - hit.multiply_scalar(one_share * float(sent)).log10()) < 0.000001 and not stuck.number.is_zero(), "an opening wave should cost its Hit once, not the run")
	_expect(stuck.active_encounter.at_number_count() == 0, "opening members should not stay at the Number")
	_expect(stuck.wave == 2 and stuck.coins == floori(profile.wave_end_coins(1, 1.0) + 0.000001) and stuck.get_tier_best(1) == 0, "the missed wave should move on with only its Coins / Wave, and unrecorded")
	# The first boss stays and fights like every boss, but waves keep coming
	# (D063): it joins the next wave's pile.
	stuck.wave = 10
	stuck.active_encounter = stuck._make_encounter(10)
	stuck.number = ScientificNumber.new(1.0, 9)
	stuck._resolve_wave_boundary()
	_expect(stuck.wave == 11 and stuck.active_encounter.boss_index() >= 0, "the wave 10 boss should stay at the Number while the next wave comes")

func _test_tier_pressure_and_curve_gates() -> void:
	var state := GameState.new()
	var profile = state.balance_profile
	# D040: Tier 1's one curve starts small at wave 1 and keeps rising.
	# D065: many enemies, each small at first.
	var wave_one := profile.liability_for_wave(1, 1)
	_expect(wave_one.multiply_scalar(1.0 / profile.wave_weight(1)).compare_to(ScientificNumber.from_float(3.0)) < 0 and wave_one.compare_to(ScientificNumber.from_float(60.0)) < 0 and not wave_one.is_zero(), "Tier 1 wave 1 should be small enemies in a small wave")
	_expect(profile.enemy_liability(1, 19).compare_to(profile.enemy_liability(1, 21)) < 0 and profile.enemy_collection(1, 19).compare_to(profile.enemy_collection(1, 21)) < 0, "Tier 1 should keep rising through wave 21")
	var tier1_liability := profile.liability_for_wave(1, 21)
	var tier2_liability := profile.liability_for_wave(2, 21)
	var tier1_collection := profile.collection_for_wave(1, 21)
	var tier2_collection := profile.collection_for_wave(2, 21)
	var tier3_liability := profile.liability_for_wave(3, 21)
	var tier3_collection := profile.collection_for_wave(3, 21)
	_expect(tier2_liability.compare_to(tier1_liability.multiply_scalar(20.0)) == 0, "Tier 2 liability must be exactly 20x Tier 1")
	_expect(tier2_collection.compare_to(tier1_collection.multiply_scalar(20.0)) == 0, "Tier 2 collection must be exactly 20x Tier 1")
	_expect(tier3_liability.compare_to(tier1_liability.multiply_scalar(60.0)) == 0, "Tier 3 liability must be exactly 60x Tier 1")
	_expect(tier3_collection.compare_to(tier1_collection.multiply_scalar(60.0)) == 0, "Tier 3 collection must be exactly 60x Tier 1")
	_expect(not profile.liability_for_wave(2, 1).is_zero(), "Tier 2 should apply pressure from wave one")
	_expect(is_equal_approx(profile.get_tier(2).reward_multiplier, 1.8), "Tier 2 reward multiplier should be 1.8x")
	_expect(profile.reward_for_wave(2, 100) == roundi(float(profile.reward_for_wave(1, 100)) * 1.8), "Tier 2 rewards should keep the 1.8x ratio at equal pressured waves")

func _test_production_clears_liability() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.number = ScientificNumber.from_float(10000)
	_expect(state.start_run(2, 9), "Tier 2 run should start after unlock")
	_all_in_reach(state)
	var before: ScientificNumber = state.active_encounter.remaining_liability.copy()
	var tap := state.tap()
	_expect(state.active_encounter.remaining_liability.compare_to(before.subtract(tap.amount)) == 0, "every produced unit should deal equal compliance damage")
	state.active_encounter.apply_compliance(ScientificNumber.new(9.9, 300))
	# D057: one blow beats only the front member; what it carried past that
	# member's HP is lost, as it was past a whole wave's.
	_expect(state.active_encounter.members[0].hp.is_zero() and state.active_encounter.standing_count() == state.active_encounter.members.size() - 1, "one blow should beat only the front member")
	for blow in range(state.active_encounter.members.size()):
		state.active_encounter.apply_compliance(ScientificNumber.new(9.9, 300))
	_expect(state.active_encounter.is_cleared(), "sufficient compliance should clear Liability without making it negative")
	var event := state._resolve_wave_boundary()
	_expect(event.type == "wave_clear" and state.wave == 2, "a cleared Liability should advance at the boundary")

func _test_output_is_number_and_strikes_the_wave() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	_expect(state.start_run(2, 21), "Tier 2 run should start after unlock")
	state.number = ScientificNumber.from_float(1000)
	_one_enemy(state, ScientificNumber.from_float(50))
	var lifetime_before: ScientificNumber = state.lifetime_generated.copy()

	# D037: every unit is Number and also counts against the wave.
	state._add_number(ScientificNumber.from_float(30))
	_expect(state.number.compare_to(ScientificNumber.from_float(1030)) == 0, "output below remaining Liability should still raise Number")
	_expect(state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(20)) == 0, "output should damage the wave one-for-one")

	state._add_number(ScientificNumber.from_float(20))
	_expect(state.active_encounter.is_cleared(), "output exactly equal to remaining Liability should beat the wave")
	_expect(state.number.compare_to(ScientificNumber.from_float(1050)) == 0, "the clearing output should be Number too")

	state._add_number(ScientificNumber.from_float(45))
	_expect(state.number.compare_to(ScientificNumber.from_float(1095)) == 0, "output after the wave is beaten should all become Number")
	_expect(state.lifetime_generated.compare_to(lifetime_before.add(ScientificNumber.from_float(95))) == 0, "lifetime production should count each unit once")

	state.active_encounter = state._make_encounter(state.wave)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(50)
	state._add_number(ScientificNumber.from_float(80))
	_expect(state.active_encounter.members[0].hp.is_zero() and state.number.compare_to(ScientificNumber.from_float(1175)) == 0, "an output past the front member's HP should beat it and bank in full")

	state.active_encounter = state._make_encounter(state.wave)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(50)
	var zero_lifetime: ScientificNumber = state.lifetime_generated.copy()
	state._add_number(ScientificNumber.new())
	_expect(state.number.compare_to(ScientificNumber.from_float(1175)) == 0 and state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(50)) == 0, "zero output should change nothing")
	_expect(state.lifetime_generated.compare_to(zero_lifetime) == 0, "zero output should not count as production")

	state.number = ScientificNumber.new()
	_one_enemy(state, ScientificNumber.new(5.0, 300))
	state._add_number(ScientificNumber.new(7.0, 300))
	_expect(state.active_encounter.is_cleared() and state.number.compare_to(ScientificNumber.new(7.0, 300)) == 0, "Number should stay exact at very large values")

	var warm_up := GameState.new()
	warm_up.start_run(1, 22)
	var warm_up_hp: ScientificNumber = warm_up.active_encounter.remaining_liability.copy()
	var starting: ScientificNumber = warm_up.number.copy()
	_expect(warm_up_hp.compare_to(warm_up.balance_profile.liability_for_wave(1, 1)) == 0, "wave 1 should carry a small Wave HP")
	warm_up._add_number(ScientificNumber.from_float(5))
	_expect(warm_up.number.compare_to(starting.add(ScientificNumber.from_float(5))) == 0, "the first tap's worth of output should raise Number at once")

	var outside := GameState.new()
	outside.tap()
	_expect(outside.number.is_zero() and outside.lifetime_generated.is_zero(), "tapping outside a run should grant nothing")

func _test_repeated_taps_count_once() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(2, 23)
	_all_in_reach(state)
	state.active_encounter.remaining_liability = ScientificNumber.from_float(30)
	var number_before: ScientificNumber = state.number.copy()
	var lifetime_before: ScientificNumber = state.lifetime_generated.copy()
	var produced := ScientificNumber.new()
	for tap_index in range(50):
		produced = produced.add(state.tap().amount)
	_expect(state.active_encounter.is_cleared(), "fifty shots should beat a 30-HP wave")
	_expect(state.number.compare_to(number_before.add(produced)) == 0, "every shot should bank once, before and after the clear")
	_expect(state.lifetime_generated.compare_to(lifetime_before.add(produced)) == 0, "every shot should count once toward lifetime production")

func _test_missed_waves_move_on_and_bosses_stay() -> void:
	# D037: an ordinary wave that outlasts its timer hits once and moves on,
	# paying Coins for the share cleared; it is not beaten, so it sets no record.
	var state := GameState.new()
	# Fast enemies, which all arrive inside the wave's clock (D068's 100 m).
	state.balance_profile.ENEMY_MIX = {"fast": 1.0}
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(2, 24)
	state.wave = 31
	state.active_encounter = state._make_encounter(31)
	state.number = ScientificNumber.from_float(1e9)
	# The front 70% beaten, so every member left arrives late enough to hit
	# once before the clock ends, on wave 31's 14.5-second interval (D059).
	state.active_encounter.remaining_liability = state.active_encounter.max_liability.multiply_scalar(0.3)
	var owed := _kill_coins_owed(state, state.balance_profile.wave_end_coins(2, 1.0))
	var hit := state.get_effective_collection()
	# Front-first, so the members beaten are the front ones; each still
	# standing lands its full share, however damaged (D057).
	var standing_share := 0.0
	var standing := 0
	for member in state.active_encounter.members:
		if TaxEncounter.is_alive(member):
			standing_share += TaxEncounter.hit_part(member)
			standing += 1
	var event := state._resolve_wave_boundary()
	_expect(event.type == "tax_collection" and state.wave == 32, "a missed ordinary wave should hit and move on")
	_expect(absf(ScientificNumber.from_float(1e9).subtract(state.number).log10() - hit.multiply_scalar(standing_share).log10()) < 0.000001, "only the members left standing should land, each one enemy's Hit")
	_expect(owed > 0 and state.coins == owed, "a missed wave's kills should have paid their Coins, and its end its Coins per Wave (D066)")
	_expect(state.get_tier_best(2) == 0, "a missed wave should set no record")
	_expect(state.active_encounter.own_uncleared().compare_to(state.active_encounter.max_liability) == 0, "the next wave should arrive whole")
	_expect(state.active_encounter.at_number_count() == standing and state.active_encounter.front_index() == 0, "the missed wave's standing members should stay at the Number, in front")

	# D063: waves keep coming while a boss stands. An unbeaten boss hits and
	# joins the pile in front of the next wave, keeping the damage dealt.
	var boss := GameState.new()
	boss.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	boss.start_run(2, 25)
	boss.wave = 30
	boss.active_encounter = _lone_boss(boss, 30)
	_all_in_reach(boss)
	boss.number = ScientificNumber.from_float(1e12)
	var boss_hp: ScientificNumber = boss.active_encounter.max_liability.copy()
	boss._add_number(ScientificNumber.from_float(40))
	event = boss._resolve_wave_boundary()
	_expect(event.type == "boss_collection" and boss.wave == 31, "a boss still standing at its boundary should hit and let the next wave come")
	var carried_boss: int = boss.active_encounter.boss_index()
	_expect(carried_boss == 0 and boss.active_encounter.front_index() == 0, "the boss should stay at the Number, in front of the next wave")
	_expect(boss.active_encounter.members[carried_boss].hp.compare_to(boss_hp.subtract(ScientificNumber.from_float(40.0))) <= 0, "a standing boss should keep the damage already dealt")
	boss._add_number(boss.active_encounter.members[carried_boss].hp.copy())
	_expect(boss.active_encounter.boss_index() < 0 and boss.get_tier_best(2) == 0, "a boss beaten after its wave passed should not count its wave as beaten")
	_beat_wave(boss)
	boss._resolve_wave_boundary()
	_expect(boss.wave == 32 and boss.get_tier_best(2) == 31, "beating the next wave should advance and count")

func _test_missed_checkpoint_pays_when_passed() -> void:
	# D037 with D030: wave 25 is an ordinary checkpoint. Missing it claims
	# nothing; beating a later wave pays it in the run, as a reload would.
	var state := GameState.new()
	state.tier_records["1"] = {"highest_wave": 24, "best_time": 0.0, "milestones_claimed": [10, 20]}
	state.start_run(1, 29)
	state.wave = 25
	state.active_encounter = state._make_encounter(25)
	state.number = ScientificNumber.from_float(1e9)
	var coins_before := state.coins
	var gems_before := state.gems
	state._resolve_wave_boundary()
	_expect(state.wave == 26 and not state.get_tier_record(1).milestones_claimed.has(25), "a missed checkpoint wave should claim nothing")
	_beat_wave(state)
	state._resolve_wave_boundary()
	var bonus: int = state.balance_profile.milestone_bonus(1, 25)
	_expect(state.get_tier_record(1).milestones_claimed.has(25), "beating a later wave should claim the passed checkpoint")
	_expect(state.coins - coins_before >= bonus and state.gems - gems_before == state.balance_profile.milestone_gems(1, 25), "the passed checkpoint should pay its Coin bonus and Gems once")
	var paid_coins := state.coins
	var paid_gems := state.gems
	state._catch_up_passed_milestones()
	_expect(state.coins == paid_coins and state.gems == paid_gems, "a reload catch-up should find nothing left to pay")

func _test_beaten_wave_waits_out_its_clock() -> void:
	# D067, replacing D037's early clear: a wave lasts its whole 35 seconds, as
	# The Tower's do, however soon it is beaten; then it counts as beaten.
	var state := GameState.new()
	state.start_run(1, 26)
	_beat_wave(state)
	var wave_one_coins := _kill_coins_owed(state, state.balance_profile.wave_end_coins(1, 1.0))
	var events: Array = []
	for step in range(4 * 34):
		events.append_array(state.advance(0.25))
	_expect(state.active_encounter.is_cleared() and state.wave == 1 and not events.any(func(event): return event.type == "wave_clear"), "a beaten wave should hold its clock")
	for step in range(8):
		events.append_array(state.advance(0.25))
	_expect(state.wave == 2 and events.any(func(event): return event.type == "wave_clear") and state.get_tier_best(1) == 1, "at 35 seconds a beaten wave should count and give way")
	_expect(state.coins == wave_one_coins and state.wave_accumulator < 2.0, "its kills and its end should have paid, and the next clock start fresh")

	# Driven through the clock: an ordinary wave left standing hits once at 15
	# seconds and moves on, with its partial Coins, exactly like the boundary.
	var clocked := GameState.new()
	clocked.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	clocked.start_run(2, 27)
	clocked.wave = 31
	clocked.active_encounter = clocked._make_encounter(31)
	clocked.number = ScientificNumber.from_float(1e9)
	var hp: ScientificNumber = clocked.active_encounter.max_liability.copy()
	clocked.active_encounter.remaining_liability = hp.multiply_scalar(0.2)
	var clocked_owed := _kill_coins_owed(clocked, clocked.balance_profile.wave_end_coins(2, 1.0))
	_advance_seconds(clocked, GameState.WAVE_INTERVAL_SECONDS - 0.5)
	_expect(clocked.wave == 31, "a standing wave should not move on before its timer")
	_advance_seconds(clocked, 0.5)
	_expect(clocked.wave == 32 and clocked.coins == clocked_owed, "at 35 seconds a standing ordinary wave should hit and move on, its kills paid")

	# 20 left of 100 is exactly 0.8 cleared: the share must not round down a Coin.
	var exact := GameState.new()
	exact.start_run(1, 28)
	exact.active_encounter = TaxEncounter.new(1, 1, ScientificNumber.from_float(100), ScientificNumber.from_float(1), 10, false, [6.0, 10.5, 15.0])
	exact.active_encounter.remaining_liability = ScientificNumber.from_float(20)
	_expect(floori(10.0 * exact.get_wave_cleared_share() + 0.000001) == 8, "a cleared share of exactly 0.8 should pay 8 of 10 Coins")

func _test_mid_wave_save_resumes_identically() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original := GameState.new()
	original.save_path = save_path
	original.purchased = {"damage": 60, "critical_chance": 79}
	original.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	original.start_run(2, 31)
	_all_in_reach(original)
	for tap_index in range(5):
		original.tap()
	_expect(not original.active_encounter.is_cleared(), "the save should be taken mid-wave")
	_expect(original.save(), "mid-wave save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	# A wave is many enemies now (D065), so it takes more taps to beat.
	for tap_index in range(600):
		original.tap()
		restored.tap()
	_expect(original.active_encounter.is_cleared(), "continued tapping should carry the wave past its clear point")
	_expect(restored.number.compare_to(original.number) == 0, "a restored run should bank the same overflow as the original")
	_expect(restored.active_encounter.remaining_liability.compare_to(original.active_encounter.remaining_liability) == 0, "a restored run should deal the same damage as the original")
	_expect(restored.lifetime_generated.compare_to(original.lifetime_generated) == 0 and restored.rng.state == original.rng.state, "a restored run should stay deterministic")
	restored.clear_save()

	# A saved encounter keeps its stored Hit: a run saved under an older curve
	# resumes with the Hit it had, and resolves identically after a reload.
	var opening := GameState.new()
	opening.save_path = save_path
	opening.start_run(1, 31)
	opening.wave = 21
	opening.active_encounter = opening._make_encounter(21)
	opening.active_encounter.collection = opening.active_encounter.collection.multiply_scalar(2.0)
	opening.number = ScientificNumber.from_float(1000.0)
	var opening_hit: ScientificNumber = opening.get_effective_collection()
	_expect(opening_hit.compare_to(opening.balance_profile.collection_for_wave(1, 21, opening.run_seed).multiply_scalar(2.0)) == 0, "a saved larger base hit should be the Hit that lands")
	_expect(opening.save(), "a mid-run Tier 1 wave should save")
	var opening_restored := GameState.new()
	opening_restored.save_path = save_path
	opening_restored.load()
	_expect(opening_restored.wave == 21 and opening_restored.get_effective_collection().compare_to(opening_hit) == 0, "a reloaded wave should keep the same effective hit")
	opening._resolve_wave_boundary()
	opening_restored._resolve_wave_boundary()
	_expect(opening_restored.number.compare_to(opening.number) == 0 and opening_restored.wave == opening.wave, "the reloaded Tier 1 hit should resolve identically")
	opening_restored.clear_save()

	# D040: a run saved under an older balance profile resumes on the current
	# curve. The old profile read a small wave 21 Hit through a ramp it never
	# stored; its saved encounter holds the full old Hit (156), which must not
	# land. The rebuilt wave keeps the share of HP already cleared.
	var legacy := GameState.new()
	legacy.save_path = save_path
	legacy.start_run(1, 32)
	legacy.wave = 21
	legacy.active_encounter = legacy._make_encounter(21)
	legacy.number = ScientificNumber.from_float(1000.0)
	_expect(legacy.save(), "the legacy fixture should save")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	saved.balance_profile_id = "tax-foundation-v6"
	# A save from before groups (D057) had no members, only its wave's HP.
	saved.active_encounter.erase("members")
	saved.active_encounter.erase("passed_liability")
	saved.active_encounter.max_liability = ScientificNumber.from_float(238.0).to_dict()
	saved.active_encounter.remaining_liability = ScientificNumber.from_float(166.6).to_dict()
	saved.active_encounter.collection = ScientificNumber.from_float(156.0).to_dict()
	_write_json(save_path, saved)
	var migrated := GameState.new()
	migrated.save_path = save_path
	migrated.load()
	_expect(migrated.in_run and migrated.wave == 21, "an old-profile run should resume at its wave")
	_expect(migrated.get_effective_collection().compare_to(migrated.balance_profile.collection_for_wave(1, 21, migrated.run_seed)) == 0, "an old-profile wave should hit with today's Hit, not its stored one")
	_expect(absf(migrated.get_wave_cleared_share() - 0.3) < 0.0001, "an old-profile wave should keep the share of HP already cleared")
	migrated.clear_save()

func _test_collection_is_absolute() -> void:
	var small := GameState.new()
	small.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	small.start_run(2, 4)
	small.number = ScientificNumber.from_float(5000)
	var expected := small.get_effective_collection()
	var one_share: float = TaxEncounter.hit_part(small.active_encounter.members[0])
	var small_event := small._resolve_wave_boundary()
	var large := GameState.new()
	large.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	large.start_run(2, 4)
	large.number = ScientificNumber.from_float(500000000)
	var large_event := large._resolve_wave_boundary()
	_expect(small_event.type == "tax_collection" and large_event.type == "tax_collection", "uncleared encounters should collect")
	_expect(small_event.amount.compare_to(large_event.amount) == 0 and absf(small_event.amount.log10() - expected.multiply_scalar(one_share).log10()) < 0.000001, "Collection must be the same absolute value at every player Number")

func _test_boss_axes_and_rewards() -> void:
	var profile = GameState.new().balance_profile
	var normal_liability := profile.liability_for_wave(2, 29)
	var boss_liability := profile.liability_for_wave(2, 30)
	var normal_collection := profile.collection_for_wave(2, 29)
	var boss_collection := profile.collection_for_wave(2, 30)
	_expect(boss_liability.compare_to(normal_liability) > 0, "boss liability should exceed the preceding normal wave")
	var one_enemy_30 := profile._from_log10(profile._wave_hit_log10(30)).multiply_scalar(20.0)
	var boss_lands: ScientificNumber = profile.collection_for_wave(2, 30).multiply_scalar(1.0 / profile.wave_weight(30))
	_expect(absf(boss_lands.log10() - one_enemy_30.log10()) < 0.000001 and absf(profile.enemy_collection(2, 30).log10() - one_enemy_30.log10()) < 0.000001 and boss_lands.compare_to(normal_collection) < 0 and boss_collection.compare_to(normal_collection) > 0, "a boss should be a wall of HP that hits like one enemy, not a whole wave (D063)")
	_expect(profile.kill_coins(2, 30, "boss") > profile.kill_coins(2, 30, "tank") and profile.kill_coins(2, 30, "basic") == 0.0, "a boss kill should pay the most Coins and a basic none (D066)")

func _test_brace_blocks_next_collection() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(2, 5)
	state.number = ScientificNumber.from_float(10000)
	_expect(state.can_brace() and state.brace(), "Brace should be available against active Liability")
	_expect(state.number.compare_to(ScientificNumber.from_float(7000)) == 0, "Brace should cost 30% of current Number")
	var event := state._resolve_wave_boundary()
	_expect(event.type == "tax_collection" and event.amount.is_zero(), "Brace should block one Collection hit")
	_expect(state.number.compare_to(ScientificNumber.from_float(7000)) == 0 and not state.braced, "Brace should preserve Number and then be consumed")

func _test_defense_percent_reduces_the_hit_and_survives_reset() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.coins = 1000
	_expect(not state.purchase("defense_percent"), "Defense % should wait for its unlock")
	_expect(state.unlock_group("defense") and state.coins == 925, "Defense % and Defense Absolute should unlock for 75 Coins")
	var armor := state.get_definition("defense_percent")
	_expect(state.get_workshop_coin_cost(armor) == 50, "the first Defense % level should cost 50 Coins")
	_expect(state.purchase("defense_percent"), "Defense % should be purchasable with enough Coins")
	state.start_run(2, 6)
	state.number = ScientificNumber.from_float(10000)
	var base_collection: ScientificNumber = state.active_encounter.collection.copy()
	_expect(state.get_effective_collection().compare_to(base_collection.multiply_scalar(0.995)) == 0, "one Defense % level should take 0.5% off the hit")
	_expect(not state.purchase("defense_percent"), "a Workshop level must be locked during a run")
	state._reset_run_state()
	_expect(state.coins == 875 and state.get_owned("defense_percent") == 1, "Coins and levels must survive reset")
	state.purchased["defense_percent"] = armor.max_rank
	_expect(not state.can_purchase("defense_percent"), "Defense % should stop at its last level")
	state.start_run(2, 6)
	var maxed_base: ScientificNumber = state.active_encounter.collection.copy()
	var maxed_hit := state.get_effective_collection()
	_expect(absf(maxed_hit.log10() - maxed_base.multiply_scalar(0.505).log10()) < 1.0e-9, "a maxed Defense % should take The Tower's 49.5% off the hit")

## D068: Lifesteal adds a share of the damage shots take off enemies to the
## Number again, any enemy's, and never what passes an enemy's HP.
func _test_lifesteal_feeds_the_number() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"lifesteal": 80}
	_expect(state.start_run(2, 41), "Tier 2 run should start after unlock")
	var share := state.stat("lifesteal")
	_expect(is_equal_approx(share, 0.04460204), "Lifesteal at level 80 should be The Tower's 4.46%")
	state.number = ScientificNumber.from_float(1000)
	_one_enemy(state, ScientificNumber.from_float(100))
	state._add_number(ScientificNumber.from_float(40))
	_expect(state.active_encounter.remaining_liability.compare_to(ScientificNumber.from_float(60)) == 0, "Lifesteal must not change the damage the enemy takes")
	_expect(absf(state.number.log10() - log(1040.0 + 40.0 * share) / log(10.0)) < 1.0e-12, "Lifesteal should add its share of the 40 dealt")
	state._add_number(ScientificNumber.from_float(100))
	_expect(state.active_encounter.is_cleared() and absf(state.number.log10() - log(1140.0 + 100.0 * share) / log(10.0)) < 1.0e-12, "only the 60 the enemy absorbed should feed Lifesteal")

	# The same through a real shot, the way a player gets it.
	state.number = ScientificNumber.from_float(1000)
	_one_enemy(state, ScientificNumber.from_float(100))
	var shot := state.tap()
	var dealt := float(shot.amount.mantissa) * pow(10.0, shot.amount.exponent)
	_expect(dealt > 0.0 and dealt < 100.0, "the fixture's tap should strike without clearing the enemy")
	_expect(absf(state.number.log10() - log(1000.0 + dealt * (1.0 + share)) / log(10.0)) < 1.0e-9, "a tap should bank what it dealt plus Lifesteal's share of it")

func _test_thorns_deal_the_hit_to_the_wave_in_front() -> void:
	# D064: Thorns deals the enemy that hit a share of its own
	# maximum HP, half on a boss, as The Tower's does.
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"thorns": 50}
	state.start_run(2, 42)
	state.number = ScientificNumber.from_float(1e9)
	state.wave = 20
	state.active_encounter = state._make_encounter(20)
	var boss_at_start: int = state.active_encounter.boss_index()
	var boss_max: ScientificNumber = state.active_encounter.members[boss_at_start].max.copy()
	var before: ScientificNumber = state.active_encounter.members[boss_at_start].hp.copy()
	state._resolve_wave_boundary()
	_expect(state.wave == 21 and state.active_encounter.boss_index() >= 0, "an unbeaten boss should hit and join the pile (D063)")
	var thorned_boss: Dictionary = state.active_encounter.members[state.active_encounter.boss_index()]
	var boss_thorns := boss_max.multiply_scalar(state.stat("thorns") * state.balance_profile.BOSS_THORNS_SHARE)
	# A boss reaches the Number at 30 seconds (D068's 100 m) and hits once
	# before its wave passes at 35, taking Thorns.
	_expect(absf(before.subtract(thorned_boss.hp).log10() - boss_thorns.log10()) < 1.0e-9, "a boss should take half of Thorns' share of its maximum HP each time it hits")

	# An ordinary wave's members stay at the Number (D058), so Thorns returns
	# each hit to them, and the wave that replaces a missed one arrives whole.
	state.wave = 21
	state.active_encounter = state._make_encounter(21)
	var wave_hp: ScientificNumber = state.active_encounter.max_liability.copy()
	state._resolve_wave_boundary()
	_expect(state.wave == 22, "a missed ordinary wave should move on")
	var pile_hp := ScientificNumber.new()
	for member in state.active_encounter.members:
		if not state.active_encounter.is_own(member):
			pile_hp = pile_hp.add(member.hp)
	_expect(pile_hp.compare_to(wave_hp) < 0 and state.active_encounter.own_uncleared().compare_to(state.active_encounter.max_liability) == 0, "Thorns should land on the members at the Number, and the next wave arrive whole")

	# The contact still happens, so Thorns still bites through a Brace (D064).
	# Wave 51's enemies stay after hitting, so the pile shows what Thorns took.
	var braced := GameState.new()
	braced.purchased = {"thorns": 50}
	braced.start_run(1, 43)
	braced.number = ScientificNumber.from_float(1e9)
	braced.wave = 51
	braced.active_encounter = braced._make_encounter(51)
	var braced_wave_hp: ScientificNumber = braced.active_encounter.max_liability.copy()
	_expect(braced.brace(), "Brace should be available against an active wave")
	var after_brace := braced.number.copy()
	braced._resolve_wave_boundary()
	var braced_pile := ScientificNumber.new()
	for member in braced.active_encounter.members:
		if not braced.active_encounter.is_own(member):
			braced_pile = braced_pile.add(member.hp)
	_expect(braced.wave == 52 and braced.number.compare_to(after_brace) == 0 and not braced_pile.is_zero() and braced_pile.compare_to(braced_wave_hp) < 0, "a Brace should block every hit of its clock while Thorns still bites")

	# Guard taking every hit to nothing still leaves the contact, so Thorns
	# still bites: The Tower's Tier 1 turtle (D064).
	var turtle := GameState.new()
	turtle.purchased = {"thorns": 50, "defense_absolute": 5000}
	turtle.start_run(1, 44)
	turtle.number = ScientificNumber.from_float(1000)
	turtle.wave = 51
	turtle.active_encounter = turtle._make_encounter(51)
	var turtle_front_max: ScientificNumber = turtle.active_encounter.members[0].max.copy()
	for step in range(41):
		turtle._advance_waves(0.25)
	var turtle_front: Dictionary = turtle.active_encounter.members[0]
	_expect(turtle.number.compare_to(ScientificNumber.from_float(1000)) >= 0 and bool(turtle_front.landed), "Guard should take the first hit to nothing")
	_expect(absf(turtle_front_max.subtract(turtle_front.hp).log10() - turtle_front_max.multiply_scalar(turtle.stat("thorns")).log10()) < 1.0e-9, "Thorns should still bite when Guard takes the hit to nothing")

	# At 99%, an opening enemy that hits after taking any damage dies to Thorns
	# before it can leave, so its wave can still be beaten.
	var opener := GameState.new()
	# Fast enemies, which all arrive inside the wave's clock; a basic set off
	# last would still be walking in reach when it ends (D068's 100 m).
	opener.balance_profile.ENEMY_MIX = {"fast": 1.0}
	opener.purchased = {"thorns": 99}
	opener.start_run(1, 45)
	opener.number = ScientificNumber.from_float(1e6)
	for member in opener.active_encounter.members:
		member.hp = member.max.multiply_scalar(0.5)
	opener.active_encounter._sum_remaining()
	# The last of wave 1's enemies arrives at about 30 seconds, and the wave
	# counts at the end of its 35 (D067).
	for step in range(141):
		opener._advance_waves(0.25)
	_expect(opener.wave == 2 and opener.get_tier_best(1) == 1, "opening enemies Thorns kills as they hit should leave their wave beaten")

## D068: Death Defy ignores a hit that would end the run, by its chance.
func _test_death_defy_ignores_an_ending_hit() -> void:
	var bare := GameState.new()
	bare.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	bare.start_run(2, 44)
	bare.number = ScientificNumber.from_float(10)
	_expect(bare._resolve_wave_boundary().type == "wave_death", "without the row, an ending hit should end the run")

	var defied := 0
	var died := 0
	for seed in range(40):
		var state := GameState.new()
		state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
		state.purchased = {"death_defy": 75}
		state.start_run(2, 100 + seed)
		state.number = ScientificNumber.from_float(1)
		var event := _play_until(state, "death_defy", 12.0)
		if event != null:
			defied += 1
			_expect(state.in_run and state.number.compare_to(ScientificNumber.from_float(1)) == 0, "Death Defy should leave the Number as it was")
		elif not state.in_run:
			died += 1
	_expect(defied > 0 and died > 0, "Death Defy should be a chance: %d defied, %d died" % [defied, died])

## A Card's flat start is priced in the tier's hits rather than in absolute
## Number, or it is a trap everywhere above Tier 1; Health is The Tower's
## absolute value.
func _test_card_start_scales_with_the_tier() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.card_ranks = {"card_health": 2}
	state.card_active = ["card_health"]
	state.start_run(1, 47)
	_expect(state.number.compare_to(ScientificNumber.from_float(5.0 + 10.0)) == 0, "the Health card should add its face value on Tier 1, on top of Health")
	state.end_run()
	state.start_run(2, 47)
	var scale := state.get_cushion_scale(2)
	_expect(is_equal_approx(scale, 20.0), "Tier 2 should scale the card by its own pressure multiplier")
	_expect(state.number.compare_to(ScientificNumber.from_float(5.0 + 10.0 * scale)) == 0, "the card should be worth twenty times as much against Tier 2 hits")

## D068: Coins / Kill Bonus multiplies what kills pay, and Coins / Wave what a
## wave's end pays; each kill's part of a Coin carries to the next.
func _test_coin_rows_lift_what_a_run_pays() -> void:
	var plain := GameState.new()
	plain.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	plain.start_run(2, 51)
	for wave in range(1, 31):
		plain.active_encounter.remaining_liability = ScientificNumber.new()
		plain._resolve_wave_boundary()
	var base_coins := plain.coins
	_expect(base_coins > 0, "thirty pressured waves should pay something to compare against")

	var rich := GameState.new()
	rich.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	rich.purchased = {"coins_per_kill": 50}
	rich.start_run(2, 51)
	for wave in range(1, 31):
		rich.active_encounter.remaining_liability = ScientificNumber.new()
		rich._resolve_wave_boundary()
	# Only kills are lifted: wave ends and checkpoints pay as before.
	var unlifted := 30.0 * plain.balance_profile.wave_end_coins(2, 1.0) + float(plain.balance_profile.milestone_bonus(2, 10) + plain.balance_profile.milestone_bonus(2, 25))
	var kill_part := float(base_coins) - unlifted
	_expect(kill_part > 0.0 and absf(float(rich.coins - base_coins) - 0.5 * kill_part) <= 2.0, "Coins / Kill Bonus at level 50 should pay half again on kills, within rounding: %d against %d" % [rich.coins, base_coins])

	var per_wave := GameState.new()
	per_wave.purchased = {"coins_per_wave": 10}
	per_wave.start_run(1, 52)
	per_wave.active_encounter.remaining_liability = ScientificNumber.new()
	var grace_owed := _kill_coins_owed(per_wave, per_wave.balance_profile.wave_end_coins(1, 11.0))
	per_wave._resolve_wave_boundary()
	_expect(per_wave.coins == grace_owed and per_wave.coin_fraction < 1.0, "Coins / Wave at level 10 should pay 11 Coins at a wave's end, and parts of a Coin carry (D066)")

	var carded := GameState.new()
	carded.card_ranks = {"card_coins": 7}
	carded.card_active = ["card_coins"]
	_expect(is_equal_approx(carded.get_coin_bonus_multiplier(), 1.07), "a Coin Bonus card should lift the Coin multiplier")

## The Defense % ceiling (D023) bounds Defense %'s own share of a hit. A rule
## that shrinks hits for its own reason stacks on top rather than being clawed
## back to the ceiling.
func _test_armor_ceiling_bounds_armor_not_other_rules() -> void:
	var state := GameState.new()
	state.purchased = {"defense_percent": 99}
	state.lab_ranks = {"lab_resilience": 200}
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.start_run(2, 4)
	var ceiling: float = state.balance_profile.DEFENSE_PERCENT_CEILING
	_expect(state.stat("defense_percent") + state._effect_sum("collection_resistance") > ceiling, "the fixture should stack Defense % past its ceiling")
	var base: ScientificNumber = state.active_encounter.collection
	_expect(absf(state.get_effective_collection().log10() - base.multiply_scalar(1.0 - ceiling).log10()) < 1.0e-9, "stacked Defense % alone should stop at its ceiling")
	state.active_rule_modifiers = [{"source": "test_rule", "target": "collection", "stage": "multiplicative", "value": 0.2}]
	_expect(absf(state.get_effective_collection().log10() - base.multiply_scalar((1.0 - ceiling) * 0.2).log10()) < 1.0e-9, "a separate rule that shrinks hits should still apply past the ceiling")

## Defense Absolute: a flat amount off each enemy's hit, after Defense % and
## down to nothing, the same at every tier, as in The Tower (D063, D068).
func _test_guard_flat_reduction_and_floor() -> void:
	var state := GameState.new()
	state.start_run(1, 4)
	state.wave = 40
	state.active_encounter = state._make_encounter(40)
	var base_hit: ScientificNumber = state.active_encounter.collection.copy()
	_expect(state.get_effective_collection().compare_to(base_hit) == 0, "with no defences, the hit should match its base")

	state.purchased = {"defense_absolute": 10}
	var flat := state.stat("defense_absolute")
	_expect(absf(flat - 11.1952) < 1.0e-4, "Defense Absolute at level 10 should take The Tower's 11.1952 off")
	_expect(state.get_effective_collection().compare_to(base_hit.subtract(ScientificNumber.from_float(flat))) == 0, "Defense Absolute should take exactly its value off a hit")

	var wave_one := GameState.new()
	wave_one.purchased = {"defense_absolute": 100}
	wave_one.start_run(1, 4)
	_expect(wave_one.get_effective_collection().is_zero(), "Defense Absolute larger than a hit should take it to nothing")

	state.purchased = {"defense_absolute": 10, "defense_percent": 60}
	var armor_first := base_hit.multiply_scalar(1.0 - state.stat("defense_percent")).subtract(ScientificNumber.from_float(flat))
	_expect(absf(state.get_effective_collection().log10() - armor_first.log10()) < 1.0e-9, "Defense % should come off before Defense Absolute")

	state.purchased = {"defense_absolute": 10}
	state.active_rule_modifiers = [{"source": "test_perk", "target": "collection", "stage": "multiplicative", "value": 0.5}]
	_expect(absf(state.get_effective_collection().log10() - base_hit.multiply_scalar(0.5).subtract(ScientificNumber.from_float(flat)).log10()) < 1.0e-9, "a rule that shrinks hits should apply before Defense Absolute")
	state.active_rule_modifiers = []

	# The Hit shown on the wave is its raw size; its defences come off at contact
	# (D052). The parts must add up to the Hit that lands, in every mix.
	var bare := GameState.new()
	bare.start_run(1, 4)
	var bare_parts := bare.get_hit_breakdown()
	_expect(bare_parts.guard.is_zero() and bare_parts.armor.is_zero() and bare_parts.raw.compare_to(bare_parts.final) == 0, "with no defences the raw Hit is the Hit that lands")
	bare.wave = 40
	bare.active_encounter = bare._make_encounter(40)
	var front_member: Dictionary = bare.active_encounter.members[bare.active_encounter.front_index()]
	for mix in [{"defense_absolute": 3}, {"defense_percent": 60}, {"defense_absolute": 3, "defense_percent": 60}]:
		bare.purchased = mix
		for rules in [[], [{"source": "test_perk", "target": "collection", "stage": "multiplicative", "value": 0.5}]]:
			bare.active_rule_modifiers = rules
			var parts := bare.get_hit_breakdown()
			var rebuilt: ScientificNumber = parts.raw.subtract(parts.armor).subtract(parts.guard)
			var lands: ScientificNumber = bare._effective_hit(bare._member_raw_hit(front_member))
			_expect(not parts.final.is_zero() and absf(rebuilt.log10() - parts.final.log10()) < 1.0e-9 and parts.final.compare_to(lands) == 0, "a Hit's parts should add up to the Hit that lands: %s" % str(mix))
	bare.purchased = {"defense_absolute": 3, "defense_percent": 60}
	bare.active_rule_modifiers = []
	var both := bare.get_hit_breakdown()
	_expect(not both.guard.is_zero() and not both.armor.is_zero(), "Defense Absolute and Defense % should each show what they took off")

	# The same flat at Tier 2, where enemies hit twenty times as hard.
	var tier_two := GameState.new()
	tier_two.purchased = {"defense_absolute": 10}
	tier_two.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	_expect(tier_two.start_run(2, 4), "the Tier 2 fixture should start")
	tier_two.wave = 40
	tier_two.active_encounter = tier_two._make_encounter(40)
	var t2_base_hit: ScientificNumber = tier_two.active_encounter.collection.copy()
	_expect(tier_two.get_effective_collection().compare_to(t2_base_hit.subtract(ScientificNumber.from_float(flat))) == 0, "Defense Absolute should not scale with the tier")

	var save_path := "res://.number_go_up_test_save.json"
	state.save_path = save_path
	state.purchased = {"defense_absolute": 25}
	_expect(state.save(), "save with Defense Absolute should write")
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.get_owned("defense_absolute") == 25, "loaded save should keep 25 Defense Absolute levels")
	loaded.clear_save()

func _test_game_data_loads_cleanly() -> void:
	GameDataClass.clear_cache()
	var workshop: Array = GameDataClass.get_workshop_upgrades()
	_expect(workshop.size() == 34, "GameData should load The Tower's 34 Workshop rows")
	var knowledge: Array = GameDataClass.get_knowledge_upgrades()
	_expect(knowledge.size() == 1 and knowledge[0].id == "insight", "GameData should load Insight from knowledge upgrades")
	var all: Array = GameDataClass.get_all_upgrades()
	_expect(all.size() == 35, "GameData should return all 35 upgrades")
	_expect(GameDataClass.get_workshop_groups().size() == 17, "GameData should load The Tower's 17 Workshop unlocks")
	_expect(GameDataClass.get_retired_workshop_upgrades().size() == 21, "the retired rows should load for refunds")
	var cached: Array = GameDataClass.get_all_upgrades()
	_expect(cached.size() == 35, "cached upgrades should match")

## Every catalogue a save keys ranks by: ids unique across all three, effects
## the game knows how to read, shelves that exist, The Tower's tables whole,
## and unlocks that open in a real order.
func _test_catalogues_are_internally_consistent() -> void:
	var state := GameState.new()
	var ids := {}
	var effect_keys: Array = []
	for definition in state.definitions:
		_expect(not ids.has(definition.id), "catalogue id %s should be unique" % definition.id)
		ids[definition.id] = true
		effect_keys.append_array(definition.effects.keys())
		_expect(definition.max_rank > 0, "%s should have a last level" % definition.id)
		if definition.category != ProgressionTaxonomy.WORKSHOP:
			continue
		_expect(ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(definition.workshop_category), "%s should sit on one of the four Workshop categories" % definition.id)
		_expect(definition.is_table() and definition.values.size() == definition.max_rank + 1 and definition.coin_prices.size() == definition.max_rank and definition.cash_prices.size() == definition.max_rank, "%s should state a value at every level and a price for every step" % definition.id)
		var group := state.get_group(definition.group)
		_expect(not group.is_empty() and str(group.workshop_category) == definition.workshop_category, "%s should open with a group on its own shelf" % definition.id)
		var rising := true
		for level in range(1, definition.values.size()):
			# The Tower's own Knockback Force dips once, at level 30.
			rising = rising and (definition.values[level] >= definition.values[level - 1] or (definition.id == "knockback_force" and level == 30))
		var priced := true
		for level in range(definition.coin_prices.size()):
			priced = priced and definition.coin_prices[level] > 0.0
		_expect(rising and priced, "%s should never lose value with a level and always cost Coins" % definition.id)
		_expect(["flat", "per_second", "percent", "multiplier", "metres", "per_metre", "seconds", "rpm", "count"].has(definition.unit), "%s should have a unit the Workshop can show" % definition.id)
	for category in ProgressionTaxonomy.WORKSHOP_CATEGORIES:
		var orders: Array = []
		for group in state.workshop_group_list:
			if str(group.workshop_category) == category:
				orders.append(int(group.order))
		var unique := {}
		for order in orders:
			unique[order] = true
		_expect(unique.size() == orders.size(), "%s's unlocks should each have their own place in the order" % category)
	for lab_definition in state.lab_research.definitions:
		_expect(not ids.has(lab_definition.id), "catalogue id %s should be unique" % lab_definition.id)
		ids[lab_definition.id] = true
		effect_keys.append_array(lab_definition.effects.keys())
		_expect(lab_definition.max_rank > 0 and lab_definition.base_cost > 0 and lab_definition.base_duration > 0.0, "%s should have a cap, a price and a duration" % lab_definition.id)
		_expect(lab_definition.category == "main" or ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(lab_definition.category), "%s should sit on Main or a Workshop category" % lab_definition.id)
	for card_definition in state.card_collection.definitions:
		_expect(not ids.has(card_definition.id), "catalogue id %s should be unique" % card_definition.id)
		ids[card_definition.id] = true
		effect_keys.append_array(card_definition.effects.keys())
		_expect(CardCollection.RARITY_WEIGHT.has(card_definition.rarity), "%s should have a known rarity" % card_definition.id)
	for effect_name in effect_keys:
		_expect(GameState.STAT_DISPLAY.has(effect_name), "effect %s should be one the game reads and displays; a typo would do nothing" % effect_name)

## D028: a V8 save loads with its run's Cash intact, keeps a copy of the file
## it read, and is rewritten in the current version at once, its old ranks
## refunded (D068); deep levels round-trip.
func _test_v8_save_migrates_to_v9() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var source := _funded_state()
	source.start_run(1, 31)
	source.cash = ScientificNumber.from_float(1234.0)
	var v8: Dictionary = SaveDataV12.make(source)
	v8.version = 8
	v8.purchased = {"stronger_tap": 100, "generator": 40}
	_write_json(save_path, v8)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.purchased.is_empty() and loaded.coins == (source.coins + 2068 + 206) * 15, "a V8 save's ranks should be refunded on The Tower's scale")
	_expect(loaded.in_run and loaded.cash.compare_to(ScientificNumber.from_float(1234.0)) == 0, "a V8 save should keep its run's Cash")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV12.VERSION, "a V8 save should be rewritten in the current version at once")
	_expect(int(_read_json("res://.number_go_up_test_save.v8-backup.json").get("version", 0)) == 8, "the V8 file should be kept beside the new save")
	loaded.clear_save()

	var deep := _funded_state()
	deep.save_path = save_path
	deep.purchased = {"damage": 4321, "defense_absolute": 2500}
	_expect(deep.save(), "a save with deep ranks should write")
	var reloaded := GameState.new()
	reloaded.save_path = save_path
	reloaded.load()
	_expect(reloaded.get_owned("damage") == 4321 and reloaded.get_owned("defense_absolute") == 2500, "deep levels should round-trip")
	reloaded.clear_save()

## A save holding more ranks than a row allows loads at the cap, so a lowered
## cap takes effect; a rank under a retired id is kept but counts for nothing.
func _test_loaded_ranks_stay_within_their_caps() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var data: Dictionary = SaveDataV12.make(GameState.new())
	data.purchased = {"damage": 90000, "health": -4, "retired_row": 30}
	data.knowledge_purchased = {"insight": 3}
	data.lab_ranks = {"lab_damage": 900, "retired_line": 2}
	data.card_ranks = {"card_damage": 500, "card_coins": -1}
	data.card_active = ["card_damage"]
	_write_json(save_path, data)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	var tap := loaded.get_definition("damage")
	_expect(loaded.get_owned("damage") == tap.max_rank and loaded.get_owned("health") == 0, "Workshop levels should load between zero and the row's last")
	_expect(loaded.purchased.get("retired_row") == 30 and loaded.get_workshop_level() == tap.max_rank, "a retired row's ranks should be kept but not counted")
	_expect(loaded.get_owned("insight") == 3, "Insight ranks should load unchanged")
	_expect(loaded.get_lab_owned("lab_damage") == loaded.lab_research.get_definition("lab_damage").max_rank and loaded.lab_ranks.get("retired_line") == 2, "Lab ranks should load within their cap, and a retired line's kept")
	_expect(loaded.get_card_level("card_damage") == CardCollection.MAX_LEVEL and loaded.get_card_level("card_coins") == 0, "Card levels should load between zero and the top level")
	loaded.clear_save()

func _test_wave_death_resets_run_but_keeps_meta_progress() -> void:
	var state := GameState.new()
	state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	state.purchased = {"damage": 3, "defense_percent": 2}
	state.coins = 42
	state.start_run(2, 7)
	# Chip the wave down first, so a summary that recorded the wave's full HP
	# would differ from the HP Attack actually left.
	state.active_encounter.apply_compliance(state.active_encounter.max_liability.multiply_scalar(0.4))
	state.number = ScientificNumber.from_float(1)
	state.lifetime_generated = ScientificNumber.from_float(GameState.PRESTIGE_TEASER_UNLOCK * 100.0)
	state.workshop.tick_count = 12
	state.run_coins_earned = 5
	var expected_knowledge := state.get_prestige_knowledge_gain()
	# The first member to land is the one that ends the run: its share.
	var killing_hit: ScientificNumber = state.get_hit_breakdown().final
	var was_boss: bool = state.active_encounter.is_boss
	var expected_attack_gap: ScientificNumber = state.active_encounter.own_uncleared()
	var number_before_hit := state.number.copy()
	var event := state._resolve_wave_boundary()
	_expect(event.type == "wave_death", "Collection that depletes Number should report death")
	_expect(state.number.is_zero() and state.get_owned("damage") == 3, "death should reset run Number and retain permanent Workshop progress")
	_expect(not state.in_run and state.wave == 1, "death should end the run at the hub")
	_expect(state.knowledge == expected_knowledge and state.coins == 42, "death should retain permanent currencies")
	_expect(state.get_owned("defense_percent") == 2, "Defense % should survive death")
	_expect(state.last_run_summary != null and state.last_run_summary.tier_id == 2, "death should record the tier")
	_expect(state.last_run_summary.coins_earned == 5, "failed waves should not award unearned rewards")
	# The run-over screen names what the run was lost to, so the summary has to
	# carry it: _reset_run_state wipes the encounter before anything can read it.
	_expect(state.last_run_summary.final_hit.compare_to(killing_hit) == 0, "the summary should record the hit the run was lost to")
	_expect(state.last_run_summary.lost_to_boss == was_boss, "the summary should record whether a boss landed it")
	# The two gaps under "Lost to" (step 6): the wave HP Attack left, and the
	# Number the hit exceeded. Both are read before the encounter is wiped.
	_expect(state.last_run_summary.attack_gap.compare_to(expected_attack_gap) == 0, "the summary should record how much wave HP Attack left")
	_expect(state.last_run_summary.defense_gap.compare_to(killing_hit.subtract(number_before_hit)) == 0, "the summary should record how far short of the hit the Number fell")

	var boss_run := GameState.new()
	boss_run.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	boss_run.start_run(2, 71)
	boss_run.wave = 10
	_one_enemy(boss_run, boss_run.balance_profile.liability_for_wave(2, 10))
	_expect(boss_run.active_encounter.is_boss, "wave ten should be a boss")
	boss_run.number = ScientificNumber.from_float(1)
	_expect(boss_run._resolve_wave_boundary().type == "wave_death", "a boss hit that empties Number should end the run")
	_expect(boss_run.last_run_summary.lost_to_boss, "a run lost to a boss should say so")
	_expect(not boss_run.last_run_summary.final_hit.is_zero(), "a boss hit should be recorded at its real size")

	# Recoil can finish the wave on the very boundary that lands the killing
	# hit. The Attack gap must still be what Attack itself left: Recoil's return
	# is Defense's damage, and crediting it to Attack would mispoint the screen.
	var recoil_death := GameState.new()
	# Fast enemies, so the last one left arrives inside the wave (D066, D068).
	recoil_death.balance_profile.ENEMY_MIX = {"fast": 1.0}
	recoil_death.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	recoil_death.purchased = {"thorns": 50}
	recoil_death.start_run(2, 73)
	recoil_death.number = ScientificNumber.from_float(1)
	var recoil_hp_left := recoil_death.get_effective_collection().multiply_scalar(0.25)
	recoil_death.active_encounter.remaining_liability = recoil_hp_left
	# The member left in front lands first, with its share of the Hit (D057).
	var recoil_hit: ScientificNumber = recoil_death.get_hit_breakdown().final
	var recoil_event := recoil_death._resolve_wave_boundary()
	_expect(recoil_event.type == "wave_death", "a killing hit should still end the run when Recoil clears the wave")
	_expect(recoil_death.last_run_summary.attack_gap.compare_to(recoil_hp_left) == 0, "the Attack gap should be the HP Attack left, before Recoil returned part of the hit")
	_expect(recoil_death.last_run_summary.defense_gap.compare_to(recoil_hit.subtract(ScientificNumber.from_float(1))) == 0, "the hit shortfall should still be recorded when Recoil clears the wave")

	# A hit exactly equal to the Number is still a death, with no Defense gap.
	var exact_death := GameState.new()
	# Fast enemies, whose hits add up to the wave's Hit (D066) and all land
	# inside its clock (D068).
	exact_death.balance_profile.ENEMY_MIX = {"fast": 1.0}
	exact_death.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
	exact_death.start_run(2, 74)
	exact_death.number = exact_death.get_effective_collection()
	exact_death._resolve_wave_boundary()
	_expect(exact_death.last_run_summary.defense_gap.is_zero(), "a Number exactly equal to the hit should leave no Defense gap")

	var retreat := GameState.new()
	retreat.start_run(1, 72)
	var summary := retreat.end_run()
	_expect(summary.final_hit.is_zero() and not summary.lost_to_boss, "a retreat was lost to nothing, so it records no hit")
	_expect(summary.attack_gap.is_zero() and summary.defense_gap.is_zero(), "a retreat was lost to nothing, so it records no gaps")

func _test_run_gates_the_wave_clock() -> void:
	var state := GameState.new()
	state.number = ScientificNumber.from_float(1000)
	_advance_seconds(state, 20.0)
	_expect(state.wave == 1, "wave clock must not advance outside an active run")
	_expect(state.start_run(1, 10), "starting a run should succeed")
	_expect(not state.start_run(1, 10), "starting while already active should fail")
	_advance_seconds(state, GameState.WAVE_INTERVAL_SECONDS + 1.0)
	_expect(state.wave == 2, "an opening wave should advance when its 35-second clock runs out (D065)")

func _test_retreat_ends_and_resets_run() -> void:
	var state := GameState.new()
	state.purchased = {"damage": 2}
	state.coins = 7
	state.start_run(1, 11)
	state.number = ScientificNumber.from_float(1000)
	state.wave = 25
	var summary := state.end_run()
	_expect(summary != null and summary.outcome == "retreat", "end_run should record a retreat")
	_expect(not state.in_run and state.number.is_zero(), "retreat must end and reset rather than pause")
	_expect(state.wave == 1 and state.get_owned("damage") == 2, "retreat should create fresh run state while retaining the Workshop")
	_expect(state.coins == 7, "retreat must retain permanent Coins")

func _test_tier_records_milestones_and_unlocks() -> void:
	var state := GameState.new()
	state.number = ScientificNumber.new(9.9, 300)
	state.start_run(1, 12)
	var unlock_event: SimulationEvent = null
	for completed_wave in range(1, GameState.TIER_UNLOCK_WAVE + 1):
		state.active_encounter.remaining_liability = ScientificNumber.new()
		unlock_event = state._resolve_wave_boundary()
	_expect(state.get_tier_best(1) == GameState.TIER_UNLOCK_WAVE, "Tier 1 record should track the highest cleared wave")
	var claimed: Array = state.get_tier_record(1).milestones_claimed
	_expect(claimed == [10, 20, 25, 30, 40, 50, 60, 75, 90, 100], "milestones should be claimed once at authored checkpoints")
	_expect(state.is_tier_unlocked(2), "clearing Tier 1 wave 100 should unlock Tier 2")
	_expect(unlock_event != null and unlock_event.type == "tier_unlock", "the first wave-100 clear should announce the newly unlocked tier")
	_expect(not state.is_tier_unlocked(3), "Tier 3 should remain locked until Tier 2 wave 100")
	state.end_run()
	_expect(state.select_tier(2), "an unlocked tier should be selectable outside a run")

## A milestone claimed before a reload stays claimed after it. JSON reads the
## claimed waves back as floats, which once made every milestone pay again on
## the first pass after each load.
func _test_claimed_milestones_survive_a_reload() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var first := GameState.new()
	first.save_path = save_path
	first.start_run(1, 5)
	_clear_waves_through(first, 10)
	first.end_run()
	var first_gems: int = first.balance_profile.milestone_gems(1, 10) + first.balance_profile.BOSS_WAVE_GEMS
	var wave_coins := _roster_kill_coins(first, 5, 1, 10)
	var bonus: int = first.balance_profile.milestone_bonus(1, 10)
	_expect(first.coins == wave_coins + bonus and first.gems == first_gems, "the first wave-10 clear should pay its waves' Coins, the milestone bonus, and the checkpoint's and the boss wave's Gems")
	_expect(first.save(), "the milestone save should write")
	var reloaded := GameState.new()
	reloaded.save_path = save_path
	reloaded.load()
	var claimed: Array = reloaded.get_tier_record(1).milestones_claimed
	_expect(claimed == [10] and typeof(claimed[0]) == TYPE_INT, "a claimed milestone should reload as the whole-number wave it was")
	reloaded.start_run(1, 5)
	_clear_waves_through(reloaded, 10)
	reloaded.end_run()
	_expect(reloaded.coins == wave_coins + bonus + wave_coins, "a reloaded milestone should pay only its wave Coins, not its bonus again")
	_expect(reloaded.gems == first_gems + reloaded.balance_profile.BOSS_WAVE_GEMS, "a reloaded milestone should not grant its Gems again; only the boss wave pays")
	_expect(reloaded.get_tier_record(1).milestones_claimed == [10], "a reclaimed pass should not list the milestone twice")
	reloaded.clear_save()

	# A save written before the fix can hold the same wave twice, plus junk;
	# it collapses to each real wave once.
	var damaged: Dictionary = SaveDataV12.make(GameState.new())
	damaged.tier_records["1"] = {"highest_wave": 30, "best_time": 0.0, "milestones_claimed": [10, 10.0, "junk", -3, 25]}
	damaged.tier_records["9"] = "a tier this build does not know"
	_write_json(save_path, damaged)
	var repaired := GameState.new()
	repaired.save_path = save_path
	repaired.load()
	_expect(repaired.get_tier_record(1).milestones_claimed == [10, 20, 25, 30], "duplicate and junk milestone entries should collapse on load, and passed checkpoints be claimed")
	_expect(typeof(repaired.get_tier_record(1).highest_wave) == TYPE_INT and repaired.get_tier_best(1) == 30, "a reloaded tier best should stay a whole-number wave")
	repaired.clear_save()

## D030: every boss wave pays a Gem, every run; each tier's checkpoints pay a
## larger, growing number of Gems once per tier record; harder tiers pay more.
func _test_boss_waves_and_checkpoints_pay_gems() -> void:
	var profile = GameState.new().balance_profile
	_expect(profile.milestone_gems(1, 10) == 6 and profile.milestone_gems(1, 100) == 20 and profile.milestone_gems(1, 200) == 28, "checkpoint Gems should grow with the wave")
	_expect(profile.milestone_gems(2, 100) == 36 and profile.milestone_gems(3, 100) == 52, "harder tiers should pay more for the same checkpoint")
	_expect(profile.milestone_gems(1, 11) == 0 and profile.wave_gems(11) == 0 and profile.wave_gems(30) == 1, "only checkpoints and boss waves should pay Gems")
	var first_run_gems := 0
	for checkpoint in profile.MILESTONE_WAVES:
		first_run_gems += profile.milestone_gems(1, checkpoint)
	_expect(first_run_gems >= 200, "Tier 1's checkpoints should be worth a lot together")

	var state := GameState.new()
	state.start_run(1, 5)
	_clear_waves_through(state, 30)
	var expected := 0
	for completed in range(1, 31):
		expected += profile.wave_gems(completed) + profile.milestone_gems(1, completed)
	_expect(state.gems == expected and state.run_gems_earned == expected, "a run through wave 30 should pay three boss Gems and four checkpoints")
	var summary := state.end_run()
	_expect(summary.gems_earned == expected and state.run_gems_earned == 0, "the run summary should report the run's Gems, and the next run start at none")
	state.start_run(1, 5)
	_clear_waves_through(state, 30)
	_expect(state.gems == expected + 3, "a second run should pay only the three boss waves again")
	state.end_run()

	# The run's Gems so far survive a mid-run reload.
	var save_path := "res://.number_go_up_test_save.json"
	var mid := GameState.new()
	mid.save_path = save_path
	mid.start_run(1, 6)
	_clear_waves_through(mid, 10)
	var mid_gems := mid.run_gems_earned
	_expect(mid_gems > 0 and mid.save(), "the mid-run fixture should have Gems to save")
	var resumed := GameState.new()
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.run_gems_earned == mid_gems, "a reloaded run should remember the Gems it has paid")
	resumed.clear_save()

## A checkpoint a record has passed but not claimed pays on load, once; a save
## from before V8 has its old one-Gem claims topped up, once.
func _test_passed_checkpoints_are_paid_on_load() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var profile = GameState.new().balance_profile
	var passed: Dictionary = SaveDataV12.make(GameState.new())
	passed.tier_records["1"] = {"highest_wave": 60, "best_time": 0.0, "milestones_claimed": [10, 25, 50]}
	_write_json(save_path, passed)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	var owed: int = profile.milestone_gems(1, 20) + profile.milestone_gems(1, 30) + profile.milestone_gems(1, 40) + profile.milestone_gems(1, 60)
	_expect(loaded.gems == owed and loaded.milestone_gems_caught_up == owed, "passed but unclaimed checkpoints should pay their Gems on load")
	_expect(loaded.coins == 0, "checkpoints without a Coin bonus should pay no Coins")
	_expect(loaded.get_tier_record(1).milestones_claimed == [10, 20, 25, 30, 40, 50, 60], "paid checkpoints should be claimed")
	loaded.save()
	var again := GameState.new()
	again.save_path = save_path
	again.load()
	_expect(again.gems == owed and again.milestone_gems_caught_up == 0, "a second load should pay nothing more")
	again.clear_save()

	var old: Dictionary = SaveDataV12.make(GameState.new())
	old.version = 7
	old.erase("run_gems_earned")
	old.gems = 2
	old.tier_records["1"] = {"highest_wave": 25, "best_time": 0.0, "milestones_claimed": [10, 20, 25]}
	_write_json(save_path, old)
	var topped := GameState.new()
	topped.save_path = save_path
	topped.load()
	var top_up: int = (profile.milestone_gems(1, 10) - GameState.PRE_V8_MILESTONE_GEMS) + (profile.milestone_gems(1, 25) - GameState.PRE_V8_MILESTONE_GEMS)
	_expect(topped.gems == 2 + top_up, "a pre-V8 save should have its old one-Gem Coin checkpoints topped up")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV12.VERSION, "the topped-up save should be rewritten in the current version at once")
	var reread := GameState.new()
	reread.save_path = save_path
	reread.load()
	_expect(reread.gems == 2 + top_up, "a top-up should never be paid twice")
	reread.clear_save()
	_expect(_leftover_save_files().is_empty(), "the checkpoint checks should leave no file behind")

func _clear_waves_through(state: GameState, last_wave: int) -> void:
	while state.in_run and state.wave <= last_wave:
		state.active_encounter.remaining_liability = ScientificNumber.new()
		state._resolve_wave_boundary()

func _test_modifier_pipeline_order() -> void:
	var modifiers: Array = [
		{"target": "collection", "stage": "multiplicative", "value": 0.5},
		{"target": "collection", "stage": "flat", "amount": ScientificNumber.from_float(10).to_dict()},
		{"target": "collection", "stage": "additive", "value": 0.5},
		{"target": "collection", "stage": "cap_max", "amount": ScientificNumber.from_float(80).to_dict()},
	]
	var result := RuleModifierPipelineClass.apply(ScientificNumber.from_float(100), "collection", modifiers)
	_expect(result.compare_to(ScientificNumber.from_float(80)) == 0, "modifier order should be flat, additive, multiplicative, then caps")
	# D063: a last flat reduction (Guard) comes off after every percentage and
	# before the caps: (100 x 0.5) - 20 = 30, where before the percentage it
	# would give 40, and a cap of 25 then holds rather than leaving 5.
	var last: Array = [
		{"target": "collection", "stage": "flat_reduce_last", "amount": ScientificNumber.from_float(20).to_dict()},
		{"target": "collection", "stage": "multiplicative", "value": 0.5},
	]
	_expect(RuleModifierPipelineClass.apply(ScientificNumber.from_float(100), "collection", last).compare_to(ScientificNumber.from_float(30)) == 0, "a last flat reduction should come off after the percentages")
	last.append({"target": "collection", "stage": "cap_max", "amount": ScientificNumber.from_float(25).to_dict()})
	_expect(RuleModifierPipelineClass.apply(ScientificNumber.from_float(100), "collection", last).compare_to(ScientificNumber.from_float(25)) == 0, "the caps should come after a last flat reduction")

func _test_deterministic_run_seed() -> void:
	var left := GameState.new()
	var right := GameState.new()
	left.purchased = {"critical_chance": 40, "multishot_chance": 50, "bounce_shot_chance": 50}
	right.purchased = {"critical_chance": 40, "multishot_chance": 50, "bounce_shot_chance": 50}
	left.start_run(1, 123456)
	right.start_run(1, 123456)
	for tap_index in range(20):
		var left_event := left.tap()
		var right_event := right.tap()
		_expect(left_event.is_critical == right_event.is_critical, "matching run seeds should reproduce critical outcomes")
		_expect(left_event.amount.compare_to(right_event.amount) == 0, "matching run seeds should reproduce produced amounts")
	_expect(left.rng.state == right.rng.state, "matching seeded runs should finish with identical RNG state")

func _test_high_wave_values_remain_valid() -> void:
	var profile = GameState.new().balance_profile
	for tier_id in [1, 2, 3]:
		var liability := profile.liability_for_wave(tier_id, 100000)
		var collection := profile.collection_for_wave(tier_id, 100000)
		_expect(not liability.is_zero() and liability.exponent > 0, "high-wave Liability should remain a valid ScientificNumber")
		_expect(not collection.is_zero() and collection.exponent > 0, "high-wave Collection should remain a valid ScientificNumber")

## D068: a run Upgrade costs The Tower's Cash for the row, by how many of it
## the run has bought, whatever the Workshop level, the wave or the income.
func _test_run_upgrades_cost_the_towers_cash() -> void:
	var state := GameState.new()
	state.start_run(1, 5)
	_expect(state.cash.is_zero(), "a run should start with no Cash, as The Tower's does")
	_expect(state.get_rig_cost("damage", 0).compare_to(ScientificNumber.from_float(10.0)) == 0 and state.get_rig_cost("damage", 1).compare_to(ScientificNumber.from_float(12.0)) == 0 and state.get_rig_cost("damage", 4).compare_to(ScientificNumber.from_float(20.0)) == 0, "Damage should cost $10, $12 and on up its Cash table")
	_expect(state.get_rig_cost("attack_speed").compare_to(ScientificNumber.from_float(5.0)) == 0 and state.get_rig_cost("health").compare_to(ScientificNumber.from_float(10.0)) == 0, "Attack Speed's first should cost $5 and Health's $10")
	var built := GameState.new()
	built.purchased = {"damage": 500}
	built.start_run(1, 5)
	built.wave = 30
	built.active_encounter = built._make_encounter(30)
	_expect(built.get_rig_cost("damage").compare_to(state.get_rig_cost("damage")) == 0, "a run's first Damage Upgrade should cost the same at any Workshop level or wave")
	built.cash = ScientificNumber.new(1.0, 9)
	for rank in range(8):
		var quoted: ScientificNumber = built.plan_rig_purchase("damage", 1).cost
		_expect(quoted.compare_to(built.get_rig_cost("damage")) == 0, "a one-level quote should equal the live price (level " + str(rank + 1) + ")")
		built.purchase_rig("damage")
	_expect(built.get_rig_cost("damage").compare_to(ScientificNumber.from_float(built.get_definition("damage").cash_prices[8])) == 0, "each run Upgrade should move one step up the Cash table")

func _test_rig_purchase_spends_cash_and_stacks() -> void:
	var state := _funded_state()
	state.start_run(1, 6)
	state.cash = ScientificNumber.from_float(1.0e9)
	var price := state.get_rig_cost("damage")
	var before_cash: ScientificNumber = state.cash.copy()
	var before_number: ScientificNumber = state.number.copy()
	_expect(state.purchase_rig("damage"), "a run Upgrade should purchase with enough Cash")
	_expect(state.rig_owned("damage") == 1 and state.get_owned("damage") == 0, "the run level should land beside the permanent Workshop level, not inside it")
	_expect(state.cash.compare_to(before_cash.subtract(price)) == 0, "the purchase should spend exactly the quoted Cash")
	_expect(state.number.compare_to(before_number) == 0, "a Damage Upgrade must leave Number untouched")
	_expect(is_equal_approx(state.stat("damage"), 5.877), "a run level should raise the row one level, The Tower's worth")
	_expect(state.get_workshop_level() == 0, "run levels must not raise the Workshop level")
	# D044: Workshop and run levels together stop at the row's last level.
	state.cash = ScientificNumber.new(1.0, 40)
	var cap: int = state.get_definition("attack_speed").max_rank
	_expect(state.purchase_rig_ranks("attack_speed", GameState.MAX_BUY) == cap, "run levels should sell up to the row's last level")
	_expect(state.rig_owned("attack_speed") == cap and state.rig_room("attack_speed") == 0, "run levels should fill the row exactly")
	var cash_at_cap: ScientificNumber = state.cash.copy()
	_expect(not state.can_purchase_rig("attack_speed") and not state.purchase_rig("attack_speed"), "a full row should sell no more")
	_expect(state.cash.compare_to(cash_at_cap) == 0 and int(state.plan_rig_purchase("attack_speed", GameState.MAX_BUY).ranks) == 0, "a full row should quote nothing and spend nothing")

## D044: a row maxed in the Workshop sells nothing in a run, and a part-built
## row sells only the levels it has left, whatever the press asks for.
func _test_rig_stops_at_the_rows_max_rank() -> void:
	var state := _funded_state()
	var speed := state.get_definition("attack_speed")
	var crit := state.get_definition("critical_chance")
	state.purchased = {"attack_speed": speed.max_rank, "critical_chance": crit.max_rank - 3}
	state.start_run(1, 19)
	state.cash = ScientificNumber.new(1.0, 40)
	_expect(state.rig_room("attack_speed") == 0 and not state.can_purchase_rig("attack_speed"), "a Workshop-maxed row should sell nothing in a run")
	_expect(state.purchase_rig_ranks("attack_speed", GameState.MAX_BUY) == 0, "MAX on a Workshop-maxed row should buy nothing")
	_expect(state.rig_room("critical_chance") == 3, "a row should have room for its unbought levels only")
	_expect(int(state.plan_rig_purchase("critical_chance", 5).ranks) == 3, "an x5 press should quote only the room left")
	_expect(state.purchase_rig_ranks("critical_chance", GameState.MAX_BUY) == 3 and state.rig_room("critical_chance") == 0, "MAX should fill the row to its last level and stop")

func _test_rig_multi_buy_quotes_and_spends() -> void:
	var fresh := GameState.new()
	fresh.start_run(1, 7)
	fresh.cash = ScientificNumber.from_float(50.0)
	var one_by_one := GameState.new()
	one_by_one.start_run(1, 7)
	one_by_one.cash = ScientificNumber.from_float(50.0)
	var partial := fresh.plan_rig_purchase("damage", 5)
	_expect(int(partial.ranks) == 3 and partial.cost.compare_to(ScientificNumber.from_float(36.0)) == 0, "$50 should quote three Damage Upgrades, $10 + $12 + $14")
	_expect(fresh.rig_owned("damage") == 0 and not fresh.rig_ranks.has("damage"), "quoting should leave the run's levels untouched")
	var before_number: ScientificNumber = fresh.number.copy()
	_expect(fresh.purchase_rig_ranks("damage", 5) == 3 and fresh.cash.compare_to(ScientificNumber.from_float(14.0)) == 0, "an x5 press should buy exactly the quoted levels and spend their price")
	_expect(fresh.number.compare_to(before_number) == 0, "bulk run Upgrades must not touch Number")
	for rank in range(3):
		one_by_one.purchase_rig("damage")
	_expect(one_by_one.cash.compare_to(fresh.cash) == 0 and one_by_one.rig_owned("damage") == fresh.rig_owned("damage"), "a bulk press should cost exactly what the same levels cost singly")

	var maxed := _funded_state()
	maxed.start_run(1, 18)
	maxed.cash = ScientificNumber.from_float(10000.0)
	var all := maxed.plan_rig_purchase("damage", GameState.MAX_BUY)
	var max_before: ScientificNumber = maxed.cash.copy()
	_expect(int(all.ranks) > 5, "MAX should quote every affordable level, past x5")
	_expect(maxed.purchase_rig_ranks("damage", GameState.MAX_BUY) == int(all.ranks), "MAX should buy exactly its quoted levels")
	_expect(maxed.cash.compare_to(max_before.subtract(all.cost)) == 0 and not maxed.can_purchase_rig("damage"), "MAX should spend its quote and leave the next level unaffordable")
	_expect(maxed.purchase_rig_ranks("damage", 0) == 0 and maxed.purchase_rig_ranks("not_a_row", GameState.MAX_BUY) == 0, "invalid multi-buy requests should change nothing")

func _test_rig_is_run_scoped() -> void:
	var state := _funded_state()
	state.start_run(1, 7)
	state.cash = ScientificNumber.from_float(1.0e9)
	var base := state.stat("damage")
	_expect(state.purchase_rig("damage"), "a run Upgrade should purchase during the run")
	_expect(state.end_run() != null, "retreat should end the run")
	_expect(state.rig_ranks.is_empty() and state.cash.is_zero(), "retreat should clear run Upgrades and Cash")
	_expect(is_equal_approx(state.stat("damage"), base), "run Upgrades should end with the run")

	# Death shares the ending machinery.
	state.start_run(1, 7)
	state.cash = ScientificNumber.from_float(1.0e9)
	_expect(state.purchase_rig("damage"), "the next run should buy its own run Upgrade")
	state.wave = 21
	state.active_encounter = state._make_encounter(21)
	state.number = ScientificNumber.from_float(0.01)
	state._resolve_wave_boundary()
	_expect(not state.in_run and state.rig_ranks.is_empty() and state.cash.is_zero(), "death should clear run Upgrades and Cash like every other ending")

	var prestige_state := _funded_state()
	prestige_state.start_run(1, 7)
	prestige_state.cash = ScientificNumber.from_float(1.0e9)
	_expect(prestige_state.purchase_rig("damage"), "the Prestige fixture should hold a run Upgrade")
	prestige_state.lifetime_generated = ScientificNumber.from_float(1.0e6)
	_expect(prestige_state.prestige() > 0 and prestige_state.rig_ranks.is_empty() and prestige_state.cash.is_zero(), "Prestige should clear run Upgrades and Cash")

func _test_rig_refuses_what_it_does_not_sell() -> void:
	var state := _funded_state()
	_expect(not state.purchase_rig("damage"), "run Upgrades must refuse a purchase outside a run")
	state.workshop_groups = ["range", "cash"]
	state.start_run(1, 8)
	state.cash = ScientificNumber.from_float(1.0e9)
	for definition in state.definitions:
		if not definition.is_table():
			continue
		_expect(state.can_purchase_rig(definition.id) == state.is_unlocked(definition), "a run should sell exactly the rows the Workshop has opened: " + definition.id)
	_expect(state.can_purchase_rig("range") and state.can_purchase_rig("cash_per_wave") and not state.can_purchase_rig("multishot_chance"), "unlocked groups should sell and locked ones not")
	_expect(not state.can_purchase_rig("not_a_row"), "an unknown row should quote nothing")

	var poor := _funded_state()
	poor.start_run(1, 9)
	_expect(not poor.purchase_rig("damage"), "a level the Cash cannot cover should refuse")

	# The exact price sells and leaves zero Cash (D015).
	var exact := _funded_state()
	exact.start_run(1, 10)
	exact.cash = exact.get_rig_cost("damage").copy()
	_expect(exact.purchase_rig("damage"), "a level the Cash exactly covers should sell")
	_expect(exact.cash.is_zero(), "spending the exact price should leave zero Cash")

## D068: Cash comes from kills and waves, as The Tower's does: shots alone pay
## none; a kill pays its HP's share of its wave's Cash, times Cash Bonus; a
## wave's end pays Cash / Wave times Cash Bonus, then Interest on what is held.
func _test_cash_comes_from_kills_and_waves() -> void:
	var state := GameState.new()
	state.purchased = {"damage": 50, "attack_speed": 60}
	state.start_run(1, 21)
	_one_enemy(state, ScientificNumber.new(1.0, 30))
	for step in range(40):
		state.advance(0.25)
	_expect(state.cash.is_zero(), "shots that kill nothing should pay no Cash")
	var profile := TaxBalanceProfile.new()
	_expect(is_equal_approx(profile.wave_cash(1), 15.0) and is_equal_approx(profile.wave_cash(21), 115.0) and is_equal_approx(profile.wave_cash(10), 180.0), "a wave should be worth 10 + 5 x its number in Cash, x3 on a boss")
	var clearing := GameState.new()
	clearing.start_run(1, 22)
	clearing.active_encounter.remaining_liability = ScientificNumber.new()
	clearing._complete_current_wave()
	_expect(absf(clearing.cash.log10() - log(profile.wave_cash(1)) / log(10.0)) < 1.0e-9, "beating wave 1 should pay its Cash, kill by kill")
	_expect(clearing.run_cash_earned.compare_to(clearing.cash) == 0, "Cash earned should count the wave's Cash")
	var bonus := GameState.new()
	bonus.purchased = {"cash_bonus": 100, "cash_per_wave": 10, "interest": 50}
	bonus.start_run(1, 22)
	bonus.cash = ScientificNumber.from_float(1000.0)
	bonus.active_encounter.remaining_liability = ScientificNumber.new()
	bonus._complete_current_wave()
	var kills := profile.wave_cash(1) * 2.0
	var held := 1000.0 + kills + 40.0 * 2.0
	_expect(absf(bonus.cash.log10() - log(held * (1.0 + 0.03)) / log(10.0)) < 1.0e-9, "Cash Bonus should double kills and Cash / Wave, then Interest pay 3%% of the Cash held: %s" % bonus.cash.format_value())

## Health bought mid-run adds what it adds to the Number now, as The Tower's
## raises the tower's health (D068); other rows leave the Number alone.
func _test_run_health_pays_its_number_now() -> void:
	var state := _funded_state()
	state.start_run(1, 23)
	state.cash = ScientificNumber.from_float(1.0e9)
	var before: ScientificNumber = state.number.copy()
	_expect(state.purchase_rig_ranks("health", 2) == 2, "two Health Upgrades should sell")
	_expect(absf(state.number.subtract(before).log10() - log(15.077 - 5.0) / log(10.0)) < 1.0e-6, "run Health should add its gain to the Number now")
	_expect(state.run_peak_number.compare_to(state.number) >= 0, "the run peak should include it")
	var number_before: ScientificNumber = state.number.copy()
	state.purchase_rig("attack_speed")
	_expect(state.number.compare_to(number_before) == 0, "a row that isn't Health should leave Number alone")

## D068: after each wave a Free Upgrade row's chance raises a random open,
## unmaxed row of its category by one run level, never a maxed one.
func _test_free_upgrades_raise_run_levels() -> void:
	var state := GameState.new()
	state.purchased = {"free_attack_upgrade": 99, "attack_speed": 99, "critical_chance": 79, "critical_factor": 150}
	state.start_run(1, 24)
	state.number = ScientificNumber.new(1.0, 9)
	var events: Array = []
	for step in range(4 * 35 * 20):
		events.append_array(state.advance(0.25))
		if not state.in_run:
			break
	var free: Array = events.filter(func(event): return event.type == "free_upgrade")
	_expect(free.size() > 4 and free.size() < 16, "at 49.5%% a wave, twenty waves should bring about ten free upgrades: %d" % free.size())
	_expect(state.rig_owned("damage") == free.size() and state.rig_owned("attack_speed") == 0, "a free upgrade should go to the one open row with room, never a maxed one")
	_expect(free.all(func(event): return event.label == "DAMAGE"), "a free upgrade should name its row")

func _test_rig_save_round_trip() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original := _funded_state()
	original.save_path = save_path
	original.start_run(1, 77)
	original.cash = ScientificNumber.from_float(1.0e9)
	_expect(original.purchase_rig("damage") and original.purchase_rig("health"), "the fixture should hold two run Upgrades")
	var saved_cash: ScientificNumber = original.cash.copy()
	var saved_number: ScientificNumber = original.number.copy()
	var saved_rng := original.rng.state
	_expect(original.save(), "the Rig save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.rig_owned("damage") == 1 and restored.rig_owned("health") == 1, "run Upgrades should round-trip with the active run")
	_expect(restored.cash.compare_to(saved_cash) == 0, "the Cash left after Rig spending should round-trip")
	_expect(restored.number.compare_to(saved_number) == 0, "the Number left after Rig spending should round-trip")
	_expect(restored.rng.state == saved_rng, "Rig spending must not disturb the RNG state")
	restored.clear_save()

	# A save written before the Rig existed resumes with no ranks, and a
	# malformed Rig block reads as empty rather than crashing.
	var pre_rig := GameState.new()
	pre_rig.save_path = save_path
	pre_rig.start_run(1, 5)
	var legacy: Dictionary = SaveDataV12.make(pre_rig)
	legacy.erase("rig_ranks")
	legacy.erase("cash")
	_write_json(save_path, legacy)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.in_run and loaded.rig_ranks.is_empty() and loaded.cash.is_zero(), "a pre-Rig save should resume with an empty Rig and zero Cash")
	loaded.clear_save()
	legacy["rig_ranks"] = "garbage"
	_write_json(save_path, legacy)
	var malformed := GameState.new()
	malformed.save_path = save_path
	malformed.load()
	_expect(malformed.in_run and malformed.rig_ranks.is_empty(), "a malformed Rig block should read as empty, not crash")
	malformed.clear_save()

## D024: Labs are permanent research paid in Coins and gated by real time,
## distinct from both the Workshop's instant purchases and the Rig's run-scoped
## ones. The four starting lines cover Main and the three open categories.
func _test_lab_definitions_cover_the_open_categories() -> void:
	var state := GameState.new()
	var ids := []
	for definition in state.lab_research.definitions:
		ids.append(definition.id)
	_expect(ids.has("lab_speed") and ids.has("lab_damage") and ids.has("lab_resilience") and ids.has("lab_coin_research"), "Labs should open with one line for Main and each of Attack, Defense and Utility")
	_expect(state.lab_research.get_definition("lab_damage").category == ProgressionTaxonomy.ATTACK, "Damage Research should sit on the Attack shelf")
	_expect(state.lab_research.get_definition("nope") == null, "an unknown research id should not resolve to a line")

func _test_lab_research_costs_coins_and_takes_real_time() -> void:
	var state := _funded_state()
	_expect(state.can_start_lab("lab_damage"), "Damage Research should be startable with Coins in hand")
	var cost := state.get_lab_cost("lab_damage")
	var duration := state.get_lab_duration("lab_damage")
	_expect(cost > 0 and duration > 0.0, "a research line should cost Coins and take real time")
	var coins_before := state.coins
	_expect(state.start_lab("lab_damage"), "starting research should succeed while a slot and the Coins are free")
	_expect(state.coins == coins_before - cost, "starting research should spend exactly its quoted Coin cost")
	_expect(state.lab_is_active("lab_damage") and state.get_lab_owned("lab_damage") == 0, "research in progress should not yet be a finished rank")
	_expect(not state.can_start_lab("lab_damage"), "a line already researching should not be startable again")
	var started: float = state.lab_active["lab_damage"].started_unix
	_expect(state.get_lab_owned("lab_damage", started + duration - 1.0) == 0, "research should not settle a moment before its duration elapses")
	_expect(state.get_lab_owned("lab_damage", started + duration) == 1, "research should settle into a rank once its duration has elapsed")
	_expect(not state.lab_is_active("lab_damage", started + duration), "a settled line should leave its slot")

func _test_lab_slots_limit_concurrent_research() -> void:
	var state := _funded_state()
	state.gems = LabResearch.SLOT_GEM_COSTS[0]
	_expect(state.unlock_lab_slot(), "the fixture should open a second Lab slot")
	_expect(state.start_lab("lab_speed") and state.start_lab("lab_damage"), "both of the two Lab slots should be fillable")
	_expect(state.lab_active_count() == state.lab_slots_total(), "every slot should now be in use")
	_expect(not state.can_start_lab("lab_resilience") and not state.start_lab("lab_resilience"), "a third line should wait for a slot to free")
	var started: float = state.lab_active["lab_speed"].started_unix
	var duration := state.get_lab_duration("lab_speed", started)
	_expect(state.can_start_lab("lab_resilience", started + duration), "settling one line should free its slot for another")

## D029: Labs start with one slot and open up to five with Gems. Existing
## saves keep the two slots every player had before slots were bought.
func _test_lab_slots_open_with_gems() -> void:
	var state := _funded_state()
	_expect(state.lab_slots_total() == LabResearch.STARTING_SLOTS and LabResearch.STARTING_SLOTS == 1, "a new game should start with one Lab slot")
	_expect(state.start_lab("lab_damage") and not state.can_start_lab("lab_speed"), "one slot should hold one line at a time")
	_expect(state.get_lab_slot_cost() == 20, "the second slot should cost 20 Gems")
	state.gems = 19
	_expect(not state.can_unlock_lab_slot() and not state.unlock_lab_slot() and state.gems == 19, "a slot should not open without its Gems")
	state.gems = 20
	_expect(state.unlock_lab_slot() and state.gems == 0 and state.lab_slots_total() == 2, "a slot should open for exactly its Gem cost")
	_expect(state.can_start_lab("lab_speed"), "an opened slot should take a second line")
	state.gems = 10000
	var spent := 0
	while state.can_unlock_lab_slot():
		spent += state.get_lab_slot_cost()
		state.unlock_lab_slot()
	_expect(state.lab_slots_total() == LabResearch.MAX_SLOTS and spent == 40 + 80 + 160, "slots should open to five, at 40, 80 and 160 Gems after the second")
	_expect(state.get_lab_slot_cost() == 0 and not state.unlock_lab_slot() and state.gems == 10000 - spent, "a sixth slot should not exist")
	var running := _funded_state()
	running.gems = 100
	running.start_run(1, 3)
	_expect(not running.can_unlock_lab_slot() and not running.unlock_lab_slot() and running.gems == 100, "opening a slot mid-run should be refused, like other Gem spends")

	var save_path := "res://.number_go_up_test_save.json"
	var saved := _funded_state()
	saved.save_path = save_path
	saved.gems = 60
	saved.unlock_lab_slot()
	saved.unlock_lab_slot()
	_expect(saved.save(), "the slot save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.lab_slots_total() == 3 and restored.gems == 0, "opened slots should survive a reload")
	restored.clear_save()

	# A V6 save predates bought slots: it keeps two, and becomes V7 at once.
	var v6: Dictionary = SaveDataV12.make(_funded_state())
	v6.version = 6
	v6.erase("lab_slots")
	_write_json(save_path, v6)
	var migrated := GameState.new()
	migrated.save_path = save_path
	migrated.load()
	_expect(migrated.lab_slots_total() == LabResearch.LEGACY_SLOTS, "a V6 save should keep its two Lab slots")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV12.VERSION and int(_read_json("res://.number_go_up_test_save.v6-backup.json").get("version", 0)) == 6, "a V6 save should be rewritten in the current version, with the V6 file kept")
	migrated.clear_save()
	for stored in [99, -3, 0]:
		var odd: Dictionary = SaveDataV12.make(_funded_state())
		odd.lab_slots = stored
		_write_json(save_path, odd)
		var clamped := GameState.new()
		clamped.save_path = save_path
		clamped.load()
		_expect(clamped.lab_slots_total() >= LabResearch.STARTING_SLOTS and clamped.lab_slots_total() <= LabResearch.MAX_SLOTS, "a stored slot count should stay between one and five")
		clamped.clear_save()
	_expect(_leftover_save_files().is_empty(), "the slot checks should leave no file behind")

## D031: research that finishes during a run takes effect from the next one,
## so a run's power never changes with the wall clock and a seeded run replays
## identically however long research takes.
func _test_research_finished_mid_run_waits_for_the_next_run() -> void:
	var build := {"damage": 100, "attack_speed": 50, "critical_chance": 79}
	var outcomes := []
	for finish_mid_run in [false, true]:
		var state := _funded_state()
		state.purchased = build.duplicate()
		_expect(state.start_lab("lab_damage"), "the fixture should have Damage Research running")
		state.start_run(1, 42)
		for frame in range(1200):
			if finish_mid_run and frame == 600:
				# The clock passes the line's end mid-run, and the UI asks.
				state.lab_active["lab_damage"].started_unix = 0.0
				_expect(state.get_lab_owned("lab_damage") == 0 and state.lab_is_done_awaiting_run_end("lab_damage"), "a line finishing mid-run should wait, and say so")
			state.advance(1.0 / 60.0)
		outcomes.append([state.lifetime_generated.to_dict(), state.rng.state])
		state.end_run()
		if finish_mid_run:
			_expect(state.get_lab_owned("lab_damage") == 1 and not state.lab_active.has("lab_damage"), "the run's end should settle the finished line")
	_expect(outcomes[0] == outcomes[1], "a seeded run should produce the same output whether research finishes during it or not")

	# Research finished before a run starts counts for all of that run.
	var early := _funded_state()
	early.start_lab("lab_damage")
	early.lab_active["lab_damage"].started_unix = 0.0
	early.start_run(1, 3)
	_expect(early.get_lab_owned("lab_damage") == 1 and is_equal_approx(early._base_output_multiplier(), 1.01), "research finished before the run should count from its start")
	early.end_run()

	# A save taken mid-run keeps the finished line waiting through the reload.
	var save_path := "res://.number_go_up_test_save.json"
	var mid := _funded_state()
	mid.save_path = save_path
	mid.start_lab("lab_damage")
	mid.start_run(1, 3)
	mid.lab_active["lab_damage"].started_unix = 0.0
	mid.save()
	var resumed := GameState.new()
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.in_run and resumed.get_lab_owned("lab_damage") == 0 and is_equal_approx(resumed._base_output_multiplier(), 1.0), "a run resumed from a save should not gain research that finished while it was away")
	resumed.end_run()
	_expect(resumed.get_lab_owned("lab_damage") == 1, "the resumed run's end should settle the line")
	resumed.clear_save()

	# A clock set back never shows more time left than the line takes.
	var rewound := _funded_state()
	rewound.start_lab("lab_speed", 5000.0)
	var duration := float(rewound.lab_active["lab_speed"].duration)
	_expect(is_equal_approx(rewound.get_lab_time_remaining("lab_speed", 5000.0 - 3600.0), duration), "a clock set back should show the line's full time, not more")

func _test_lab_research_is_a_between_run_action() -> void:
	var state := _funded_state()
	state.start_run(1, 9)
	_expect(not state.can_start_lab("lab_damage"), "starting research mid-run should be refused, like a Workshop purchase")
	_expect(not state.start_lab("lab_damage"), "Labs should not spend Coins while a run is active")

func _test_finished_lab_research_applies_its_effect() -> void:
	var without := GameState.new()
	without.purchased.damage = 1
	var base_rate := without.get_rate_per_second()

	var with_lab := GameState.new()
	with_lab.purchased.damage = 1
	with_lab.lab_active["lab_damage"] = {"started_unix": 1000.0, "duration": 100.0}
	_expect(with_lab.get_lab_owned("lab_damage", 1101.0) == 1, "Damage Research should settle once its duration has passed")
	_expect(with_lab.get_rate_per_second().compare_to(base_rate) > 0, "a finished Damage Research rank should lift produced damage like a Workshop or Rig rank does")

func _test_lab_speed_shortens_other_lines_not_itself() -> void:
	var state := _funded_state()
	var plain_duration := state.get_lab_duration("lab_damage")
	state.lab_ranks["lab_speed"] = 10
	var discounted_duration := state.get_lab_duration("lab_damage")
	_expect(discounted_duration < plain_duration, "Lab Speed should shorten another line's duration")
	var expected := plain_duration * (1.0 - 10.0 * LabResearch.SPEED_DURATION_STEP)
	_expect(is_equal_approx(discounted_duration, expected), "the discount should match its documented per-rank step")
	var base_speed_duration: float = state.lab_research.duration_at(state.lab_research.get_definition("lab_speed"), state.get_lab_owned("lab_speed"), 0)
	_expect(is_equal_approx(state.get_lab_duration("lab_speed"), base_speed_duration), "Lab Speed must not discount itself, at whatever rank it holds")

func _test_lab_save_round_trip() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original := _funded_state()
	original.save_path = save_path
	_expect(original.start_lab("lab_speed"), "the fixture should have Lab Speed researching")
	original.lab_ranks["lab_damage"] = 3
	var saved_active: Dictionary = original.lab_active["lab_speed"].duplicate(true)
	_expect(original.save(), "the Labs save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.get_lab_owned("lab_damage") == 3, "a finished Labs rank should round-trip")
	_expect(restored.lab_is_active("lab_speed"), "an in-progress line should round-trip as still active")
	var remaining_at_save := restored.get_lab_time_remaining("lab_speed", float(saved_active.started_unix))
	_expect(is_equal_approx(remaining_at_save, float(saved_active.duration)), "the remaining time at the moment it was saved should round-trip exactly")
	restored.clear_save()

	# A save written before Labs existed resumes with none, and a malformed
	# Labs block reads as empty rather than crashing.
	var legacy: Dictionary = SaveDataV12.make(_funded_state())
	legacy.erase("lab_ranks")
	legacy.erase("lab_active")
	_write_json(save_path, legacy)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.lab_ranks.is_empty() and loaded.lab_active.is_empty(), "a pre-Labs save should resume with no Labs state")
	loaded.clear_save()
	legacy["lab_active"] = "garbage"
	_write_json(save_path, legacy)
	var malformed := GameState.new()
	malformed.save_path = save_path
	malformed.load()
	_expect(malformed.lab_active.is_empty(), "a malformed Labs block should read as empty, not crash")
	malformed.clear_save()

## D027: Cards are a permanent, Gem-pulled collection with a capped Active
## set. Only an Active card's effect counts; an owned-but-idle one in
## Inventory does not, unlike a Workshop or Lab rank which always applies.
func _test_card_definitions_are_common_and_rare() -> void:
	var state := GameState.new()
	var common: Array = state.card_collection.definitions_for_rarity(CardCollection.COMMON)
	var rare: Array = state.card_collection.definitions_for_rarity(CardCollection.RARE)
	_expect(not common.is_empty() and not rare.is_empty(), "the starting catalogue should hold both a common and a rare tier")
	_expect(state.card_collection.get_definition("card_damage") != null, "Damage should be a real card")
	_expect(state.card_collection.get_definition("nope") == null, "an unknown card id should not resolve")

func _test_card_pull_costs_gems_and_grants_a_level() -> void:
	var state := _funded_state()
	state.gems = 100
	_expect(state.can_pull_card(), "a pull should be affordable with Gems in hand")
	var gems_before := state.gems
	var drawn := state.pull_card()
	_expect(drawn != "", "an affordable pull should draw a card")
	_expect(state.card_collection.get_definition(drawn) != null, "the drawn id should be a real card")
	_expect(state.gems == gems_before - state.get_pull_cost(), "a pull should spend exactly its quoted Gem cost")
	_expect(state.get_card_level(drawn) == 1, "a first pull of a card should own it at level 1")
	_expect(not state.card_collection.get_definition(drawn).is_maxed(3), "level 3 of 7 should not read as maxed")
	_expect(state.card_collection.get_definition(drawn).is_maxed(CardCollection.MAX_LEVEL), "level 7 should read as maxed")

func _test_card_pull_is_a_between_run_action() -> void:
	var state := _funded_state()
	state.gems = 100
	state.start_run(1, 3)
	_expect(not state.can_pull_card() and state.pull_card() == "", "pulling mid-run should be refused, like a Workshop purchase")

func _test_card_pull_never_exceeds_max_level() -> void:
	var state := _funded_state()
	state.gems = 100000
	state.card_ranks["card_damage"] = CardCollection.MAX_LEVEL
	var gems_before := state.gems
	# Enough pulls that a maxed card is drawn at least once with near
	# certainty (~17.5% per pull, one of four commons); the contract is that
	# no level can ever pass MAX_LEVEL, drawn or not.
	for i in range(200):
		state.pull_card()
	_expect(state.get_card_level("card_damage") == CardCollection.MAX_LEVEL, "a maxed card should never level past its cap")
	_expect(state.gems < gems_before, "pulls should still spend Gems even when a maxed card is drawn")
	_expect(not state.has_unmaxed_cards(), "all cards should now be maxed")
	_expect(not state.can_pull_card(), "pulls should be disabled when all cards are maxed")
	var gems_at_cap := state.gems
	_expect(state.pull_card() == "" and state.gems == gems_at_cap, "pulling when all cards are maxed must not spend gems")

func _test_card_pull_duplicate_protection() -> void:
	var state := _funded_state()
	state.gems = 1000
	state.card_ranks["card_damage"] = CardCollection.MAX_LEVEL
	for i in range(20):
		var drawn := state.pull_card()
		if drawn != "":
			_expect(drawn != "card_damage", "a maxed card should never be drawn while other cards can level up")

func _test_card_equip_respects_slot_cap_and_run_state() -> void:
	var state := _funded_state()
	for id in ["card_damage", "card_attack_speed", "card_coins", "card_critical_chance"]:
		state.card_ranks[id] = 1
	_expect(state.card_slots_total() == CardCollection.ACTIVE_SLOTS, "the slot cap should match the catalogue's constant")
	for id in ["card_damage", "card_attack_speed", "card_coins", "card_critical_chance"]:
		_expect(state.equip_card(id), "an owned card should equip while a slot is free")
	_expect(state.active_card_count() == state.card_slots_total(), "every slot should now be in use")
	state.card_ranks["card_health"] = 1
	_expect(not state.can_equip_card("card_health") and not state.equip_card("card_health"), "a full Active set should refuse another card")
	_expect(state.unequip_card("card_damage"), "an equipped card should unequip, freeing its slot")
	_expect(state.equip_card("card_health"), "unequipping should free a slot for another card")
	_expect(state.get_card_level("card_damage") == 1, "unequipping must not touch the card's owned level")
	state.start_run(1, 4)
	_expect(not state.can_equip_card("card_damage"), "equipping mid-run should be refused, like a Workshop purchase")
	_expect(not state.unequip_card("card_coins"), "unequipping mid-run should also be refused")

func _test_active_card_applies_its_effect_but_inventory_does_not() -> void:
	var without := GameState.new()
	without.purchased.damage = 1
	var base_rate := without.get_rate_per_second()

	var owned_only := GameState.new()
	owned_only.purchased.damage = 1
	owned_only.card_ranks["card_damage"] = 3
	_expect(owned_only.get_rate_per_second().compare_to(base_rate) == 0, "an owned-but-inactive card should not affect production")

	var active := GameState.new()
	active.purchased.damage = 1
	active.card_ranks["card_damage"] = 3
	active.card_active.append("card_damage")
	_expect(active.get_rate_per_second().compare_to(base_rate) > 0, "an Active card should lift produced damage like a Workshop or Lab rank does")

func _test_card_save_round_trip() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var original := _funded_state()
	original.save_path = save_path
	original.gems = 42
	original.card_ranks = {"card_damage": 3, "card_coins": 1}
	original.card_active = ["card_damage"]
	_expect(original.save(), "the Cards save should write")
	var restored := GameState.new()
	restored.save_path = save_path
	restored.load()
	_expect(restored.gems == 42, "Gems should round-trip")
	_expect(restored.get_card_level("card_damage") == 3 and restored.get_card_level("card_coins") == 1, "card levels should round-trip")
	_expect(restored.is_card_active("card_damage") and not restored.is_card_active("card_coins"), "the Active set should round-trip")
	restored.clear_save()

	# A save written before Cards existed resumes with none, and a malformed
	# block reads as empty rather than crashing.
	var legacy: Dictionary = SaveDataV12.make(_funded_state())
	legacy.erase("gems")
	legacy.erase("card_ranks")
	legacy.erase("card_active")
	_write_json(save_path, legacy)
	var loaded := GameState.new()
	loaded.save_path = save_path
	loaded.load()
	_expect(loaded.gems == 0 and loaded.card_ranks.is_empty() and loaded.card_active.is_empty(), "a pre-Cards save should resume with no Cards state")
	loaded.clear_save()
	legacy["card_active"] = "garbage"
	legacy["card_ranks"] = "garbage"
	_write_json(save_path, legacy)
	var malformed := GameState.new()
	malformed.save_path = save_path
	malformed.load()
	_expect(malformed.card_ranks.is_empty() and malformed.card_active.is_empty(), "a malformed Cards block should read as empty, not crash")
	malformed.clear_save()
	# An Active list naming an id outside the catalogue, or repeating one,
	# should be sanitised rather than trusted wholesale.
	legacy["card_ranks"] = {"card_damage": 1}
	legacy["card_active"] = ["card_damage", "not_a_real_card", "card_damage"]
	_write_json(save_path, legacy)
	var sanitised := GameState.new()
	sanitised.save_path = save_path
	sanitised.load()
	_expect(sanitised.card_active == ["card_damage"], "an Active list should drop unknown ids and duplicates")
	sanitised.clear_save()
	# An Active list beyond the slot cap should be truncated to it, not
	# trusted past what equip_card would ever have allowed.
	legacy["card_ranks"] = {"card_damage": 1, "card_attack_speed": 1, "card_coins": 1, "card_critical_chance": 1, "card_health": 1}
	legacy["card_active"] = ["card_damage", "card_attack_speed", "card_coins", "card_critical_chance", "card_health"]
	_write_json(save_path, legacy)
	var overfull := GameState.new()
	overfull.save_path = save_path
	overfull.load()
	_expect(overfull.card_active.size() == CardCollection.ACTIVE_SLOTS, "an Active list beyond the slot cap should be truncated to it on load")
	overfull.clear_save()



## D023: the combined defensive effects are bounded. Run ranks worth more than
## Workshop ranks, Labs and Cards can all stack past a row's own cap, so the
## fixture stands in for them with ranks past the Workshop maximum.
func _test_defensive_ceilings_bound_the_combined_effects() -> void:
	var state := _funded_state()
	state.start_run(1, 13)
	state.purchased = {"defense_percent": 99, "thorns": 99}
	state.lab_ranks = {"lab_resilience": 200}
	_expect(state.stat("defense_percent") + state._effect_sum("collection_resistance") > state.balance_profile.DEFENSE_PERCENT_CEILING, "the fixture should stack Defense % past its ceiling")
	# A lone boss, so Leech and Thorns reach it rather than enemies in front.
	state.wave = 30
	_one_enemy(state, state.balance_profile.liability_for_wave(1, 30))
	var base: ScientificNumber = state.active_encounter.collection.copy()
	var effective := state.get_effective_collection()
	_expect(absf(effective.log10() - base.multiply_scalar(1.0 - state.balance_profile.DEFENSE_PERCENT_CEILING).log10()) < 1.0e-9, "a hit should never fall below the combined Defense % ceiling")
	_expect(not effective.is_zero(), "the ceiling keeps hits real, not free")

	# Thorns: never more than the ceiling's share of an enemy's maximum HP,
	# halved on a boss (D064).
	_expect(state.stat("thorns") <= state.balance_profile.RECOIL_CEILING, "The Tower's Thorns should stay inside its ceiling")
	var ceiling_boss_max: ScientificNumber = state.active_encounter.members[0].max.copy()
	var liability_before: ScientificNumber = state.active_encounter.members[0].hp.copy()
	state.number = ScientificNumber.new(1.0, 40)
	state._resolve_wave_boundary()
	# The boss joins the next wave's pile (D063); its own HP shows what came off.
	var dealt := liability_before.subtract(state.active_encounter.members[state.active_encounter.boss_index()].hp)
	_expect(absf(dealt.log10() - ceiling_boss_max.multiply_scalar(state.stat("thorns") * state.balance_profile.BOSS_THORNS_SHARE).log10()) < 1.0e-9, "a boss should take half of Thorns' share of its maximum HP")

## D057, D065: a wave is a group of many enemies, each with the full enemy
## HP, as The Tower's are: 20 at wave 1, about 142 by wave 1,000, capped at
## 220. A boss wave adds a boss carrying twenty enemies' HP. Members walk in as
## a column, the front arriving at 10 seconds and the last 26 seconds later.
func _test_a_wave_is_a_group() -> void:
	var profile := TaxBalanceProfile.new()
	_expect(profile.members_for_wave(1) == 20 and profile.members_for_wave(9) == 20 and profile.members_for_wave(101) == 32, "a wave should start as twenty enemies and grow with the wave")
	_expect(profile.members_for_wave(100) == profile.ordinary_members(100) + 1 and profile.member_weights(100).count(profile.BOSS_HP_WEIGHT) == 1, "a boss wave should add one boss to its enemies")
	_expect(profile.members_for_wave(999) == 142 and profile.members_for_wave(10001) == profile.MAX_WAVE_MEMBERS, "the count should reach about 142 at wave 1,000 and stop at its cap")
	var basics := TaxBalanceProfile.new()
	basics.ENEMY_MIX = {"basic": 1.0}
	var column: Array = basics.member_arrivals(1)
	_expect(is_equal_approx(float(column[0]), 10.0) and is_equal_approx(float(column[19]), 36.0), "basic enemies should arrive from 10 seconds through the next 26 (D068's 100 m)")
	_expect(profile.member_arrivals(10).has(profile.boss_arrival_seconds()) and _sorted(profile.member_arrivals(10)), "a boss should walk in among its wave in arrival order")
	var state := GameState.new()
	# Basic enemies only, so every share is equal; types are D066's test.
	state.balance_profile.ENEMY_MIX = {"basic": 1.0}
	state.start_run(1, 51)
	var encounter = state.active_encounter
	var count: int = encounter.members.size()
	var total := ScientificNumber.new()
	for member in encounter.members:
		total = total.add(member.max)
		_expect(is_equal_approx(float(member.share), 1.0 / float(count)), "each enemy should carry an equal share of an ordinary wave")
	_expect(absf(total.log10() - encounter.max_liability.log10()) < 0.000001, "the members' HP should add up to the wave's")
	_expect(absf(encounter.members[0].max.log10() - profile._from_log10(profile._wave_hp_log10(1)).log10()) < 0.000001, "each enemy should carry the full enemy HP (D065)")
	_expect(is_equal_approx(state.next_hit_share(), 1.0 / float(count)) and state.get_hit_breakdown().final.compare_to(state.get_effective_collection().multiply_scalar(1.0 / float(count))) == 0, "the next Hit shown should be the front member's share")
	# Damage strikes the front member, and what passes its HP is lost. Every
	# member in reach here, so the front is the first (D067's test is its own).
	_all_in_reach(state)
	var front_hp: ScientificNumber = encounter.members[0].hp.copy()
	var applied: ScientificNumber = encounter.apply_compliance(front_hp.multiply_scalar(2.0))
	_expect(applied.compare_to(front_hp) == 0 and encounter.members[0].hp.is_zero() and encounter.members[1].hp.compare_to(encounter.members[1].max) == 0, "a blow should stop at the front member")
	_expect(encounter.front_index() == 1 and encounter.standing_count() == count - 1, "the next member should become the front")

## D066: The Tower's enemy types. A wave's roster is drawn from the run's seed
## and the wave: the same run replays the same waves, another run differs.
## A tank carries five enemies' HP and a boss twenty, but every type hits like
## one enemy. Fast enemies overtake; slow ones can arrive after the wave's
## clock. Every kill pays when it happens: Coins by type (basics none), Cash by
## HP; every wave's end pays its Coins per Wave.
func _test_enemy_types_and_pay_per_kill() -> void:
	var profile := TaxBalanceProfile.new()
	var roster: Array = profile.wave_roster(12, 99)
	_expect(roster == profile.wave_roster(12, 99), "the same run and wave should draw the same roster")
	var differs := false
	for other_seed in range(100, 110):
		differs = differs or profile.wave_roster(12, other_seed).map(func(entry): return entry.kind) != roster.map(func(entry): return entry.kind)
	_expect(differs, "other runs should draw other rosters")
	_expect(_sorted(roster.map(func(entry): return entry.arrive)), "a roster should be in arrival order")
	var counts := {"basic": 0, "fast": 0, "tank": 0, "ranged": 0}
	var total := 0
	for draw_wave in range(1, 400):
		for entry in profile.wave_roster(draw_wave, 7):
			if entry.kind != "boss":
				counts[entry.kind] += 1
				total += 1
	for kind in counts:
		var share := float(counts[kind]) / float(total)
		_expect(absf(share - float(profile.ENEMY_MIX[kind])) < 0.01, "%s should spawn about %d%% of the time: %f" % [kind, roundi(100.0 * float(profile.ENEMY_MIX[kind])), share])
	var boss_roster: Array = profile.wave_roster(10, 3)
	var bosses: Array = boss_roster.filter(func(entry): return entry.kind == "boss")
	_expect(bosses.size() == 1 and is_equal_approx(float(bosses[0].arrive), 30.0), "a boss wave's boss should set off at the start and arrive at 30 seconds")
	_expect(is_equal_approx(profile.latest_arrival(), 56.0), "the slowest enemy set off last should arrive at 56 seconds")

	var state := GameState.new()
	state.start_run(1, 61)
	state.number = ScientificNumber.from_float(1e9)
	state.wave = 21
	state.active_encounter = state._make_encounter(21)
	var encounter: TaxEncounter = state.active_encounter
	var enemy_hp: ScientificNumber = profile.enemy_liability(1, 21)
	var enemy_hit: ScientificNumber = profile.enemy_collection(1, 21)
	var weights := 0.0
	for member in encounter.members:
		weights += float(member.weight)
		_expect(absf(member.max.log10() - enemy_hp.multiply_scalar(float(profile.ENEMY_HP_WEIGHT[member.kind])).log10()) < 0.000001, "a %s should carry %d enemies' HP" % [member.kind, int(profile.ENEMY_HP_WEIGHT[member.kind])])
		_expect(absf(state._member_raw_hit(member).log10() - enemy_hit.log10()) < 0.000001, "a %s should hit like one enemy" % member.kind)
	_expect(is_equal_approx(weights, profile.wave_weight(21, 61)) and absf(encounter.max_liability.log10() - enemy_hp.multiply_scalar(weights).log10()) < 0.000001, "a wave's HP should be its roster's")

	# Kills pay by type as they happen.
	var kinds_paid := {}
	for index in range(encounter.members.size()):
		var member: Dictionary = encounter.members[index]
		if kinds_paid.has(member.kind):
			continue
		kinds_paid[member.kind] = true
		var coins_before := state.coins
		var fraction_before := state.coin_fraction
		var cash_before: ScientificNumber = state.cash.copy()
		encounter.damage_member(index, member.hp.copy())
		state._pay_kills()
		var paid: float = float(state.coins - coins_before) + state.coin_fraction - fraction_before
		_expect(absf(paid - profile.kill_coins(1, 21, member.kind)) < 0.000001, "a %s kill should pay its Coins: %f" % [member.kind, paid])
		_expect(absf(state.cash.subtract(cash_before).log10() - log(profile.wave_cash(21) * float(member.weight) / weights) / log(10.0)) < 0.000001, "a %s kill should pay its HP's share of the wave's Cash" % member.kind)
		_expect(bool(member.paid), "a paid kill should be marked")
	_expect(is_zero_approx(profile.kill_coins(1, 21, "basic")) and profile.kill_coins(1, 21, "fast") < profile.kill_coins(1, 21, "ranged") and profile.kill_coins(1, 21, "ranged") < profile.kill_coins(1, 21, "tank") and profile.kill_coins(1, 21, "tank") < profile.kill_coins(1, 21, "boss"), "Coins per kill should run basic 0, then fast, ranged, tank and boss")
	# The Tower's scale (D068): a kill pays its type's worth times its wave.
	_expect(is_equal_approx(profile.kill_coins(1, 21, "fast"), 42.0) and is_equal_approx(profile.kill_coins(2, 21, "tank"), 4.0 * 21.0 * 1.8), "a kill should pay its type's worth times its wave, times the tier's reward")

	# A tank set off late arrives after its wave's clock, is carried, and a
	# saved run keeps its arrival and type.
	var late := GameState.new()
	late.balance_profile.ENEMY_MIX = {"tank": 1.0}
	late.start_run(1, 62)
	late.number = ScientificNumber.from_float(1e9)
	var last: Dictionary = late.active_encounter.members[late.active_encounter.members.size() - 1]
	_expect(last.kind == "tank" and is_equal_approx(float(last.arrive), 56.0), "the last tank should arrive at 56 seconds")
	var save_path := "res://.number_go_up_test_save.json"
	late.save_path = save_path
	_expect(late.save(), "a wave with late tanks should save")
	var restored := GameState.new()
	restored.balance_profile.ENEMY_MIX = {"tank": 1.0}
	restored.save_path = save_path
	restored.load()
	var restored_last: Dictionary = restored.active_encounter.members[restored.active_encounter.members.size() - 1]
	_expect(restored_last.kind == "tank" and is_equal_approx(float(restored_last.arrive), 56.0) and is_equal_approx(float(restored_last.next_hit), 56.0) and not bool(restored_last.paid), "a late tank should load with its type and arrival")
	for step in range(141):
		late._advance_waves(0.25)
		restored._advance_waves(0.25)
	_expect(late.wave == 2 and late.active_encounter.members.any(func(member): return member.kind == "tank" and not late.active_encounter.is_own(member)), "tanks still walking when the wave ends should carry into the next")
	_expect(restored.wave == late.wave and restored.number.compare_to(late.number) == 0 and restored.coins == late.coins, "the restored run should play out the same")
	restored.clear_save()

	# Saved while those tanks walk into the next opening wave, a reload keeps
	# them: they have yet to hit, so they have not left (D059, D066).
	_expect(late.save(), "a run with tanks carried past their wave should save")
	var walking := func(st: GameState) -> int: return st.active_encounter.members.filter(func(member): return not st.active_encounter.is_own(member) and not bool(member.landed) and TaxEncounter.is_alive(member)).size()
	var carried_walkers: int = walking.call(late)
	var reloaded := GameState.new()
	reloaded.balance_profile.ENEMY_MIX = {"tank": 1.0}
	reloaded.save_path = save_path
	reloaded.load()
	_expect(carried_walkers > 0 and walking.call(reloaded) == carried_walkers, "a reload should keep tanks still walking from the last opening wave: %d of %d" % [walking.call(reloaded), carried_walkers])
	for step in range(48):
		late._advance_waves(0.25)
		reloaded._advance_waves(0.25)
	_expect(reloaded.number.mantissa == late.number.mantissa and reloaded.number.exponent == late.number.exponent and reloaded.active_encounter.members.size() == late.active_encounter.members.size(), "the reloaded run should take the same hits, exactly")
	reloaded.clear_save()

	# A save from before types, reloaded on today's profile, pays for the
	# enemies it had killed: the old rules paid a wave's kills only at its end.
	var migrating := GameState.new()
	migrating.balance_profile.ENEMY_MIX = {"tank": 1.0}
	migrating.start_run(1, 63)
	migrating.number = ScientificNumber.from_float(1e9)
	for kill in range(3):
		migrating.active_encounter.members[kill].hp = ScientificNumber.new()
		migrating.active_encounter.members[kill].state = TaxEncounter.KILLED
	migrating.active_encounter._sum_remaining()
	migrating.save_path = save_path
	_expect(migrating.save(), "the pre-types fixture should save")
	var old_data: Dictionary = _read_json(save_path)
	old_data.balance_profile_id = "tax-foundation-v13"
	for member in old_data.active_encounter.members:
		member.erase("kind")
		member.erase("paid")
	_write_json(save_path, old_data)
	var migrated_types := GameState.new()
	migrated_types.balance_profile.ENEMY_MIX = {"tank": 1.0}
	migrated_types.save_path = save_path
	migrated_types.load()
	var owed_for_three: float = 3.0 * migrated_types.balance_profile.kill_coins(1, 1, "tank")
	var paid_for_three: float = float(migrated_types.coins) + migrated_types.coin_fraction
	_expect(owed_for_three > 0.0 and absf(paid_for_three - owed_for_three) < 0.000001 and migrated_types.active_encounter.members.slice(0, 3).all(func(member): return bool(member.paid)), "a migrated save should pay the kills it had made: %f of %f" % [paid_for_three, owed_for_three])
	migrated_types.clear_save()

	# An enemy carried under D063's rules still owes its share of its passed
	# wave's reward, and pays that at its kill rather than its type's Coins.
	var owing := GameState.new()
	owing.start_run(1, 64)
	owing.number = ScientificNumber.from_float(1e9)
	var owing_member: Dictionary = owing.active_encounter.members[0]
	owing_member.unpaid = 0.5
	owing_member.kind = "basic"
	var owing_restored = TaxEncounter.from_dict(owing.active_encounter.to_dict())
	owing.active_encounter = owing_restored
	owing.active_encounter.damage_member(0, owing.active_encounter.members[0].hp.copy())
	owing._pay_kills()
	var owed_share: float = float(owing.balance_profile.reward_for_wave(1, 1)) * 0.5 * TaxBalanceProfile.COIN_RESCALE
	_expect(absf(float(owing.coins) + owing.coin_fraction - owed_share) < 0.000001, "an enemy owing a D063 share should pay it at its kill, on today's Coin scale")

## D067: distance, The Tower's way. Enemies set off 100 m out (D068) and walk in at
## their type's speed; the Number's damage strikes only enemies within its
## 30 m reach, nearest first; ranged enemies stop at the edge of reach and
## fire from there; positions carry across a wave's end and a save.
func _test_distance_and_reach() -> void:
	var profile := TaxBalanceProfile.new()
	_expect(is_equal_approx(TaxBalanceProfile.travel_seconds("basic"), 10.0) and is_equal_approx(TaxBalanceProfile.travel_seconds("fast"), 4.171875) and is_equal_approx(TaxBalanceProfile.travel_seconds("tank"), 30.0) and is_equal_approx(TaxBalanceProfile.travel_seconds("ranged"), 14.0), "travel times should come from speeds over the 100 m approach")
	var state := GameState.new()
	state.balance_profile.ENEMY_MIX = {"basic": 1.0}
	state.start_run(1, 71)
	var encounter: TaxEncounter = state.active_encounter
	var before: ScientificNumber = encounter.remaining_liability.copy()
	var number_before: ScientificNumber = state.number.copy()
	state.tap()
	_expect(encounter.remaining_liability.compare_to(before) == 0 and state.number.compare_to(number_before) > 0 and encounter.target_index() < 0, "at the start nothing is in reach: a tap banks Number and strikes nothing")
	encounter.now = 6.9
	_expect(encounter.target_index() < 0, "a basic set off at 0 is still out of reach at 6.9 seconds")
	encounter.now = 7.0
	_expect(encounter.target_index() == 0 and is_equal_approx(TaxEncounter.distance_of(encounter.members[0], 7.0), 30.0), "at 7 seconds it walks into the 30 m reach")

	# Nearest first: a fast enemy set off later overtakes basics set off earlier.
	var mixed := GameState.new()
	mixed.balance_profile.ENEMY_MIX = {"basic": 0.5, "fast": 0.5}
	mixed.start_run(1, 72)
	var crowd: TaxEncounter = mixed.active_encounter
	crowd.now = 9.0
	var nearest := -1
	var nearest_distance := INF
	for index in range(crowd.members.size()):
		var member: Dictionary = crowd.members[index]
		if crowd.has_set_off(member):
			var distance := TaxEncounter.distance_of(member, 9.0)
			if distance <= crowd.reach and distance < nearest_distance:
				nearest = index
				nearest_distance = distance
	_expect(nearest >= 0 and crowd.target_index() == nearest, "damage should strike the nearest enemy in reach")

	# Ranged enemies stop at the edge of reach, fire from there, and can be struck.
	var ranged := GameState.new()
	ranged.balance_profile.ENEMY_MIX = {"ranged": 1.0}
	ranged.balance_profile.OPENING_HIT_WAVES = 0
	ranged.balance_profile.OPENING_EASED_BY = 0
	ranged.start_run(1, 73)
	ranged.number = ScientificNumber.from_float(1e9)
	var hits := 0
	for step in range(57):
		hits += ranged._advance_waves(0.25).filter(func(event): return event.type == "tax_collection").size()
	var shooter: Dictionary = ranged.active_encounter.members[0]
	_expect(hits == 1 and int(shooter.state) == TaxEncounter.AT_NUMBER and is_equal_approx(TaxEncounter.distance_of(shooter, ranged.wave_accumulator), 30.0) and ranged.active_encounter.target_index() == 0, "a ranged enemy should fire at 14 seconds from 30 m and stay there, in reach")

	# A wave counts as beaten when everything that came within reach fell,
	# though a tank set off late is still walking in when the clock ends: it
	# carries on into the next wave (D067).
	var sweeper := GameState.new()
	sweeper.balance_profile.ENEMY_MIX = {"tank": 1.0}
	sweeper.start_run(1, 75)
	sweeper.number = ScientificNumber.from_float(1e9)
	for step in range(141):
		sweeper.active_encounter.now = sweeper.wave_accumulator
		for blow in range(40):
			var in_reach: int = sweeper.active_encounter.target_index()
			if in_reach < 0:
				break
			sweeper.active_encounter.damage_member(in_reach, sweeper.active_encounter.members[in_reach].hp.copy())
		sweeper._pay_kills()
		sweeper._advance_waves(0.25)
	_expect(sweeper.wave == 2 and sweeper.get_tier_best(1) == 1 and sweeper.active_encounter.members.any(func(member): return int(member.wave) == 1 and TaxEncounter.is_alive(member)), "a wave should count as beaten when all within reach fell, a late tank carried on")

	# A walker carried past its wave's clock keeps walking from where it was.
	var carry := GameState.new()
	carry.balance_profile.ENEMY_MIX = {"tank": 1.0}
	carry.start_run(1, 74)
	carry.number = ScientificNumber.from_float(1e9)
	var last: Dictionary = carry.active_encounter.members[carry.active_encounter.members.size() - 1]
	var at_35 := TaxEncounter.distance_of(last, 35.0)
	for step in range(140):
		carry._advance_waves(0.25)
	_expect(carry.wave == 2 and not carry.active_encounter.is_own(last) and absf(TaxEncounter.distance_of(last, carry.active_encounter.now) - at_35) < 0.01, "a tank carried past its wave should keep its place: %f against %f" % [TaxEncounter.distance_of(last, carry.active_encounter.now), at_35])
	var save_path := "res://.number_go_up_test_save.json"
	carry.save_path = save_path
	_expect(carry.save(), "a run with a walker between waves should save")
	var carried_back := GameState.new()
	carried_back.balance_profile.ENEMY_MIX = {"tank": 1.0}
	carried_back.save_path = save_path
	carried_back.load()
	var back_last: Dictionary = carried_back.active_encounter.members[carry.active_encounter.members.find(last)]
	_expect(float(back_last.sets_off) == float(last.sets_off) and carried_back.active_encounter.target_index() == carry.active_encounter.target_index(), "a reload should keep where each enemy set off and what the Number strikes")
	for step in range(40):
		carry.tap()
		carried_back.tap()
		carry._advance_waves(0.25)
		carried_back._advance_waves(0.25)
	_expect(carried_back.active_encounter.remaining_liability.mantissa == carry.active_encounter.remaining_liability.mantissa and carried_back.number.mantissa == carry.number.mantissa, "the reloaded run should strike and be struck exactly as the original")
	carried_back.clear_save()

## Saved numbers read back bit for bit (law 6): Godot's JSON reader misreads
## about one mantissa in thirteen, so each number carries its exact bits too.
## The readable mantissa stays the authority.
func _test_saved_numbers_read_back_exactly() -> void:
	var mixer := RandomNumberGenerator.new()
	mixer.seed = 5
	var mismatches := 0
	for trial in range(2000):
		var value := ScientificNumber.new(mixer.randf_range(1.0, 10.0), mixer.randi_range(-10, 400))
		var back := ScientificNumber.from_dict(JSON.parse_string(JSON.stringify(value.to_dict(), "", true, true)))
		if back.mantissa != value.mantissa or back.exponent != value.exponent:
			mismatches += 1
	_expect(mismatches == 0, "every saved number should read back exactly: %d did not" % mismatches)
	var older := ScientificNumber.from_dict({"mantissa": 2.5, "exponent": 3})
	_expect(older.mantissa == 2.5 and older.exponent == 3, "a number saved without bits should read as before")
	var edited: Dictionary = ScientificNumber.new(2.5, 3).to_dict()
	edited.mantissa = 7.25
	_expect(ScientificNumber.from_dict(edited).mantissa == 7.25, "bits that disagree with the mantissa should be ignored")
	edited.bits = "not hex at all!!"
	_expect(ScientificNumber.from_dict(edited).mantissa == 7.25, "unreadable bits should be ignored")

func _sorted(values: Array) -> bool:
	for index in range(1, values.size()):
		if float(values[index]) < float(values[index - 1]):
			return false
	return true

## D057: each member left standing reaches the Number at its arrival time and
## lands its share of the Hit. A wave with a member still standing when its
## clock runs out is passed, not beaten, and pays for the share it cleared.
func _test_group_members_land_one_by_one() -> void:
	var state := GameState.new()
	state.balance_profile.ENEMY_MIX = {"basic": 1.0}
	state.start_run(1, 52)
	state.number = ScientificNumber.from_float(1e6)
	var count: int = state.active_encounter.members.size()
	var share_hit := state.get_effective_collection().multiply_scalar(1.0 / float(count))
	var start := state.number.copy()
	var events := state._advance_waves(0.25)
	for step in range(38):
		events.append_array(state._advance_waves(0.25))
	var hits := events.filter(func(event): return event.type == "tax_collection")
	_expect(hits.size() == 0 and state.number.compare_to(start) == 0, "nothing should land before the front member arrives at 10 seconds")
	events = state._advance_waves(0.25)
	hits = events.filter(func(event): return event.type == "tax_collection")
	_expect(hits.size() == 1 and hits[0].amount.compare_to(share_hit) == 0, "the front member should land its share of the Hit at 10 seconds")
	_expect(state.number.compare_to(start.subtract(share_hit)) == 0 and state.active_encounter.landed_count() == 1 and state.wave == 1, "one landing should cost its share and the wave should stand on")
	var landed := 1
	for step in range(120):
		landed += state._advance_waves(0.25).filter(func(event): return event.type == "tax_collection").size()
	_expect(landed == count and state.wave == 2, "every member should land by 36 seconds and the wave should pass at 35")
	_expect(int(state.get_tier_record(1).highest_wave) == 0, "a passed wave should set no record")

	# Beat the front two in time: only the last lands, and the wave pays for
	# the two thirds it cleared.
	var partial := GameState.new()
	partial.balance_profile.ENEMY_MIX = {"basic": 1.0}
	partial.start_run(1, 53)
	partial.number = ScientificNumber.from_float(1e6)
	partial.wave = 7
	partial.active_encounter = partial._make_encounter(7)
	var partial_count: int = partial.active_encounter.members.size()
	var coins_before := partial.coins
	for kill in range(2):
		partial.active_encounter.damage_member(kill, partial.active_encounter.members[kill].hp.copy())
	var partial_hits := 0
	for step in range(150):
		partial_hits += partial._advance_waves(0.25).filter(func(event): return event.type == "tax_collection").size()
	_expect(partial_hits == partial_count - 2 and partial.wave == 8, "with two beaten, only the rest should land and the wave should pass")
	_expect(partial.coins == coins_before + floori(partial.balance_profile.wave_end_coins(1, 1.0) + 0.000001), "basic kills should pay no Coins, and a passed wave its Coins per Wave (D066)")

	# Beat every member in time: no landing, and the wave is beaten.
	var clean := GameState.new()
	clean.start_run(1, 54)
	_beat_wave(clean)
	var clean_events: Array = []
	for step in range(141):
		clean_events.append_array(clean._advance_waves(0.25))
	_expect(clean.wave == 2 and clean_events.any(func(event): return event.type == "wave_clear") and clean.get_tier_record(1).highest_wave >= 1, "a wave beaten before any member lands should count as beaten")

	# A landing that empties the Number ends the run, with that landing as the
	# Hit that did it.
	var fatal := GameState.new()
	fatal.start_run(1, 55)
	fatal.number = ScientificNumber.from_float(0.5)
	var fatal_events: Array = []
	for step in range(41):
		fatal_events.append_array(fatal._advance_waves(0.25))
	_expect(not fatal.in_run and fatal_events.any(func(event): return event.type == "wave_death") and fatal.last_run_summary.wave_reached == 1, "a landing that empties the Number should end the run")

## D057: Brace blocks every member of the wave it was raised against and is
## spent when that wave ends; Guard and Armor work on the whole Hit, so each
## member lands its share of what the single wave would have; Thorns returns a
## share of each landing to what still stands.
func _test_group_brace_guard_and_thorns() -> void:
	var braced := GameState.new()
	braced.balance_profile.ENEMY_MIX = {"basic": 1.0}
	braced.start_run(1, 56)
	braced.number = ScientificNumber.from_float(1e6)
	_expect(braced.brace(), "a Brace should be raised")
	var after_brace := braced.number.copy()
	for step in range(43):
		braced._advance_waves(0.25)
	# By 10.75 seconds the first of wave 1's twenty has arrived (D065, D068).
	_expect(braced.wave == 1 and braced.active_encounter.landed_count() >= 1 and braced.number.compare_to(after_brace) == 0, "a Brace should block the first members")
	for step in range(98):
		braced._advance_waves(0.25)
	_expect(braced.wave == 2 and braced.number.compare_to(after_brace) == 0 and not braced.braced, "a Brace should block every member and be spent when the wave ends")

	var guarded := GameState.new()
	# Basic enemies, so only the front one lands by 10.25 seconds (D066).
	guarded.balance_profile.ENEMY_MIX = {"basic": 1.0}
	guarded.purchased = {"defense_absolute": 3}
	guarded.start_run(1, 57)
	guarded.number = ScientificNumber.from_float(1e6)
	guarded.wave = 31
	guarded.active_encounter = guarded._make_encounter(31)
	var own_hit: ScientificNumber = guarded.active_encounter.collection.multiply_scalar(TaxEncounter.hit_part(guarded.active_encounter.members[0]))
	var before := guarded.number.copy()
	for step in range(41):
		guarded._advance_waves(0.25)
	_expect(absf(before.subtract(guarded.number).log10() - own_hit.subtract(ScientificNumber.from_float(guarded.stat("defense_absolute"))).log10()) < 1.0e-6, "a member should land its own share of the Hit less Defense Absolute (D063)")

	var thorny := GameState.new()
	thorny.purchased = {"thorns": 50}
	thorny.start_run(1, 58)
	thorny.number = ScientificNumber.from_float(1e6)
	thorny.wave = 31
	thorny.active_encounter = thorny._make_encounter(31)
	var standing_before: ScientificNumber = thorny.active_encounter.remaining_liability.copy()
	var front_hp: ScientificNumber = thorny.active_encounter.members[0].hp.copy()
	var thorns: ScientificNumber = thorny.active_encounter.members[0].max.multiply_scalar(minf(thorny.stat("thorns"), thorny.balance_profile.RECOIL_CEILING))
	for step in range(41):
		thorny._advance_waves(0.25)
	# The member that hit takes a share of its own maximum HP (D064).
	var expected_left := standing_before.subtract(thorns if thorns.compare_to(front_hp) < 0 else front_hp)
	_expect(thorny.active_encounter.landed_count() == 1 and absf(thorny.active_encounter.remaining_liability.log10() - expected_left.log10()) < 0.000001, "Thorns should deal the enemy that hit a share of its own maximum HP")

## D057: V10 keeps each member's HP and state, so a run saved mid-wave resumes
## exactly; a V9 run resumes its wave as a group, keeping the share cleared.
func _test_group_saves_and_resumes() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var source := GameState.new()
	source.save_path = save_path
	source.start_run(1, 59)
	source.number = ScientificNumber.from_float(1e6)
	source.wave = 31
	source.active_encounter = source._make_encounter(31)
	source.active_encounter.damage_member(0, source.active_encounter.members[0].hp.copy())
	source.active_encounter.damage_member(1, source.active_encounter.members[1].hp.multiply_scalar(0.5))
	for step in range(46):
		source.advance(0.25)
	_expect(source.active_encounter.landed_count() >= 1 and source.active_encounter.members[0].state == TaxEncounter.KILLED, "the fixture should have a beaten member and a landed one")
	_expect(source.save(), "a mid-wave group should save")
	var saved := _read_json(save_path)
	_expect(int(saved.version) == SaveDataV12.VERSION and saved.active_encounter.members.size() == source.active_encounter.members.size(), "V10 should write every member")
	var resumed := GameState.new()
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.active_encounter.members.size() == source.active_encounter.members.size(), "every member should come back")
	for index in range(source.active_encounter.members.size()):
		var a: Dictionary = source.active_encounter.members[index]
		var b: Dictionary = resumed.active_encounter.members[index]
		_expect(int(a.state) == int(b.state) and a.hp.compare_to(b.hp) == 0 and is_equal_approx(float(a.arrive), float(b.arrive)), "member %d should resume exactly" % index)
	_expect(resumed.active_encounter.own_uncleared().compare_to(source.active_encounter.own_uncleared()) == 0 and resumed.active_encounter.at_number_count() == source.active_encounter.at_number_count(), "the members at the Number should resume")
	for step in range(120):
		source.advance(0.25)
		resumed.advance(0.25)
	_expect(resumed.wave == source.wave and resumed.number.compare_to(source.number) == 0 and resumed.coins == source.coins, "a resumed group should play out exactly as the saved one")
	resumed.clear_save()

	# A V9 run saved before groups: its wave was one pool of HP.
	var old := GameState.new()
	old.save_path = save_path
	old.start_run(1, 60)
	old.wave = 31
	old.active_encounter = old._make_encounter(31)
	var v9: Dictionary = SaveDataV12.make(old)
	v9.version = 9
	v9.erase("brace_spent")
	v9.balance_profile_id = "tax-foundation-v10"
	v9.active_encounter.erase("members")
	v9.active_encounter.erase("passed_liability")
	v9.active_encounter.remaining_liability = ScientificNumber.from_dict(v9.active_encounter.max_liability).multiply_scalar(0.4).to_dict()
	_write_json(save_path, v9)
	var migrated := GameState.new()
	migrated.save_path = save_path
	migrated.load()
	_expect(migrated.in_run and migrated.wave == 31 and migrated.active_encounter.members.size() == migrated.balance_profile.members_for_wave(31), "a V9 run should resume its wave as a group")
	_expect(absf(migrated.get_wave_cleared_share() - 0.6) < 0.0001 and migrated.active_encounter.front_index() > 0, "a V9 wave should keep the share it had cleared, taken off the front")
	_expect(int(_read_json(save_path).get("version", 0)) == SaveDataV12.VERSION and int(_read_json("res://.number_go_up_test_save.v9-backup.json").get("version", 0)) == 9, "a V9 save should be rewritten as V10, with the V9 file kept")
	migrated.clear_save()

	# A run saved on an older balance profile keeps each member's state, so a
	# member that has landed never lands again on load.
	var landed_once := GameState.new()
	landed_once.save_path = save_path
	landed_once.start_run(1, 61)
	landed_once.number = ScientificNumber.from_float(1e6)
	landed_once.wave = 31
	landed_once.active_encounter = landed_once._make_encounter(31)
	for step in range(200):
		if landed_once.active_encounter.landed_count() > 0:
			break
		landed_once._advance_waves(0.25)
	var number_after_landing := landed_once.number.copy()
	var states_before: Array = landed_once.active_encounter.members.map(func(member): return int(member.state))
	_expect(landed_once.save(), "the landed fixture should save")
	var older_profile := _read_json(save_path)
	older_profile.balance_profile_id = "tax-foundation-v10"
	_write_json(save_path, older_profile)
	var rebuilt := GameState.new()
	rebuilt.save_path = save_path
	rebuilt.load()
	_expect(rebuilt.active_encounter.members.map(func(member): return int(member.state)) == states_before, "a rebuilt wave should keep each member's state")
	rebuilt._advance_waves(0.05)
	_expect(rebuilt.number.compare_to(number_after_landing) == 0, "a member that landed before the save should not land again")
	rebuilt.clear_save()

	for bad_members in ["three", [1, 2, 3], [{"hp": 5, "max": {}}]]:
		var malformed: Dictionary = SaveDataV12.make(GameState.new())
		malformed.active_encounter = {"members": bad_members}
		_write_json(save_path, malformed)
		var turned_away := GameState.new()
		turned_away.save_path = save_path
		turned_away.load()
		_expect(turned_away.load_status == GameState.LOAD_UNREADABLE, "a save with malformed members should be refused whole: %s" % str(bad_members))
		turned_away.clear_save()

	var damaged: Dictionary = SaveDataV12.make(GameState.new())
	damaged.active_encounter = {"members": "three"}
	_write_json(save_path, damaged)
	var refused := GameState.new()
	refused.save_path = save_path
	refused.load()
	_expect(refused.load_status == GameState.LOAD_UNREADABLE, "a save whose members are not a list should be refused whole")
	refused.clear_save()

## D058: a member that reaches the Number stays and hits again every
## MEMBER_HIT_SECONDS until beaten. When its wave's clock runs out it carries
## into the next wave, in front, so an unbeaten pile grows wave on wave. A boss
## holds the clock and hits every 15 seconds. A member beaten after landing
## still counts towards beating its wave, and a Brace covers the whole clock.
## D063: a boss is a wall that joins the pile when its wave passes, heat-up
## and the boss marker survive a save, and older saves load with safe
## defaults.
func _test_tower_shaped_bosses_and_heat_up() -> void:
	var state := GameState.new()
	state.balance_profile.OPENING_HIT_WAVES = 0
	state.balance_profile.OPENING_EASED_BY = 0
	state.start_run(1, 91)
	state.number = ScientificNumber.from_float(1e12)
	state.wave = 20
	state.active_encounter = _lone_boss(state, 20)
	state._resolve_wave_boundary()
	var boss_at: int = state.active_encounter.boss_index()
	_expect(state.wave == 21 and boss_at == 0, "the unbeaten boss should lead the next wave's pile")

	# A boss standing in front of an ordinary wave hits like one of its enemies,
	# heated up for the hits it has landed.
	var carried := GameState.new()
	carried.balance_profile.OPENING_HIT_WAVES = 0
	carried.balance_profile.OPENING_EASED_BY = 0
	carried.start_run(1, 92)
	carried.number = ScientificNumber.from_float(1e12)
	carried.wave = 10
	carried.active_encounter = _lone_boss(carried, 10)
	carried._resolve_wave_boundary()
	var boss: Dictionary = carried.active_encounter.members[carried.active_encounter.boss_index()]
	# It reaches the Number at 30 seconds (D068) and hits every 5 through its
	# wave's boundary at 35: at 30 and 35.
	_expect(int(boss.hits) == 2 and is_equal_approx(float(boss.interval), carried.balance_profile.MEMBER_HIT_SECONDS), "the boss should have hit on its wave's clock and keep it")
	var heated: ScientificNumber = carried.get_hit_breakdown(carried.active_encounter.boss_index()).raw
	_expect(absf(heated.log10() - boss.wave_hit.multiply_scalar(TaxEncounter.hit_part(boss) * pow(carried.balance_profile.HEAT_UP_PER_HIT, 2.0)).log10()) < 1.0e-9, "the boss's next hit should be heated up 4% a hit")

	# The carried boss and its heat survive a save and load exactly.
	var save_path := "res://.number_go_up_test_save.json"
	carried.save_path = save_path
	_expect(carried.save(), "a run with a carried boss should save")
	var loaded := GameState.new()
	loaded.balance_profile.OPENING_HIT_WAVES = 0
	loaded.balance_profile.OPENING_EASED_BY = 0
	loaded.save_path = save_path
	loaded.load()
	var loaded_boss_at: int = loaded.active_encounter.boss_index()
	_expect(loaded_boss_at >= 0 and int(loaded.active_encounter.members[loaded_boss_at].hits) == int(boss.hits) and loaded.active_encounter.members[loaded_boss_at].hp.compare_to(boss.hp) == 0, "the carried boss should load with its HP and heat")
	loaded.clear_save()

	# A member saved before D063 has no marker or count: a boss is its own
	# wave's, and a member that has landed has hit once. No older save could
	# hold a carried boss, so members of an ordinary wave load as ordinary.
	var own_boss: Dictionary = _lone_boss(carried, 10).to_dict()
	var mixed: Dictionary = carried.active_encounter.to_dict()
	for fixture in [own_boss, mixed]:
		for member in fixture.members:
			member.erase("boss")
			member.erase("hits")
			member.erase("kind")
			member.erase("paid")
	var restored_boss = TaxEncounter.from_dict(own_boss)
	_expect(restored_boss.boss_index() == 0 and restored_boss.members.size() == 1 and int(restored_boss.members[0].hits) == 0, "an older boss wave should load its boss, not yet having hit")
	var restored_mixed = TaxEncounter.from_dict(mixed)
	_expect(restored_mixed.boss_index() < 0 and restored_mixed.members.all(func(member): return int(member.hits) == (1 if bool(member.landed) else 0)), "an older ordinary wave should load no boss and one hit per landed member")

	# A boss beaten after its wave passed pays what its wave still owed: the
	# rest of its Coins, its Cash and its Gem, and says so (D063).
	var owed := GameState.new()
	owed.balance_profile.OPENING_HIT_WAVES = 0
	owed.balance_profile.OPENING_EASED_BY = 0
	owed.start_run(1, 94)
	owed.number = ScientificNumber.from_float(1e12)
	owed.wave = 20
	owed.active_encounter = _lone_boss(owed, 20)
	owed._resolve_wave_boundary()
	var coins_after_pass := owed.coins
	var gems_after_pass := owed.gems
	var owed_at: int = owed.active_encounter.boss_index()
	var wave_end_20: float = owed.balance_profile.wave_end_coins(1, 1.0)
	var boss_coins := floori(wave_end_20 + owed.balance_profile.kill_coins(1, 20, "boss") + 0.000001)
	_expect(coins_after_pass == floori(wave_end_20 + 0.000001) and not bool(owed.active_encounter.members[owed_at].paid) and boss_coins > coins_after_pass, "a boss passed untouched should not have paid yet, only its wave's end")
	owed._add_number(owed.active_encounter.members[owed_at].hp.copy())
	var cleared_events: Array = owed.advance(0.0).filter(func(event): return event.type == "boss_clear")
	_expect(owed.coins == boss_coins and owed.gems == gems_after_pass + owed.balance_profile.wave_gems(20), "the beaten boss should pay its kill's Coins and its Gem (D066)")
	_expect(cleared_events.size() == 1 and owed.get_tier_best(1) == 0, "the beaten boss should announce itself once and set no record")
	owed._add_number(ScientificNumber.from_float(1))
	_expect(owed.coins == boss_coins, "a beaten boss should pay once")

	# Ordinary enemies carried in the pile pay their share of their wave's
	# Coins when beaten later, as The Tower pays on the kill (D063).
	var pile_pay := GameState.new()
	pile_pay.balance_profile.OPENING_HIT_WAVES = 0
	pile_pay.balance_profile.OPENING_EASED_BY = 0
	pile_pay.start_run(1, 96)
	pile_pay.number = ScientificNumber.from_float(1e12)
	pile_pay.wave = 31
	pile_pay.active_encounter = pile_pay._make_encounter(31)
	pile_pay.active_encounter.remaining_liability = pile_pay.active_encounter.max_liability.multiply_scalar(0.4)
	var pile_reward: int = _roster_kill_coins(pile_pay, 96, 31, 31)
	var owed_at_pass := _kill_coins_owed(pile_pay, pile_pay.balance_profile.wave_end_coins(1, 1.0))
	pile_pay._resolve_wave_boundary()
	var paid_at_pass := pile_pay.coins
	_expect(paid_at_pass == owed_at_pass, "the passing wave's kills should have paid (D066)")
	# Each kill's part of a Coin carries over, so beating the carried enemies
	# pays the rest of what the whole wave is worth.
	var carried_count := 0
	for member in pile_pay.active_encounter.members:
		if not pile_pay.active_encounter.is_own(member):
			carried_count += 1
	for kill in range(carried_count):
		pile_pay._add_number(pile_pay.active_encounter.members[pile_pay.active_encounter.front_index()].hp.copy())
	_expect(carried_count > 2 and pile_pay.coins == pile_reward, "the carried enemies beaten later should pay the rest of their wave's kill Coins: %d of %d" % [pile_pay.coins, pile_reward])
	# The part of a Coin still owed survives a save (D065).
	pile_pay.coin_fraction = 0.625
	pile_pay.save_path = "res://.number_go_up_test_save.json"
	_expect(pile_pay.save(), "a run owing part of a Coin should save")
	var fraction_loaded := GameState.new()
	fraction_loaded.save_path = pile_pay.save_path
	fraction_loaded.load()
	_expect(is_equal_approx(fraction_loaded.coin_fraction, 0.625), "the part of a Coin owed should load with the run")
	fraction_loaded.clear_save()

	# A V10 save migrates to V11, keeping a copy, and resumes its boss wave.
	var v10_path := "res://.number_go_up_test_save.json"
	var v10 := GameState.new()
	v10.start_run(1, 95)
	v10.wave = 10
	v10.active_encounter = v10._make_encounter(10)
	v10.save_path = v10_path
	var v10_data: Dictionary = SaveDataV12.make(v10)
	v10_data.version = 10
	for member in v10_data.active_encounter.members:
		member.erase("boss")
		member.erase("hits")
		member.erase("kind")
		member.erase("paid")
	_write_json(v10_path, v10_data)
	var migrated := GameState.new()
	migrated.save_path = v10_path
	migrated.load()
	_expect(migrated.load_status == GameState.LOAD_OK and migrated.in_run and migrated.active_encounter.boss_index() == 0, "a V10 boss wave should resume with its boss")
	_expect(int(_read_json(v10_path).get("version", 0)) == SaveDataV12.VERSION and FileAccess.file_exists(migrated._migration_backup_path(10)), "a V10 save should be rewritten as V11 and kept as a copy")
	migrated.clear_save()

	# Tier 2 opens with the first beaten wave past 100 when the wave 100 boss
	# was passed rather than beaten.
	var gate := GameState.new()
	gate.start_run(1, 93)
	gate.number = ScientificNumber.from_float(1e30)
	gate.wave = 100
	gate.active_encounter = gate._make_encounter(100)
	gate._resolve_wave_boundary()
	_expect(gate.wave == 101 and not gate.is_tier_unlocked(2), "passing the wave 100 boss should not open Tier 2 by itself")
	_beat_wave(gate)
	var opened := false
	for step in range(141):
		for event in gate.advance(0.25):
			opened = opened or event.type == "tier_unlock"
	_expect(opened and gate.is_tier_unlocked(2), "beating wave 101 should open Tier 2 and say so")

func _test_members_stay_and_the_pile_grows() -> void:
	var state := GameState.new()
	state.balance_profile.OPENING_HIT_WAVES = 0
	state.balance_profile.OPENING_EASED_BY = 0
	state.balance_profile.FIRST_WAVE_MEMBERS = 3
	state.start_run(1, 71)
	state.number = ScientificNumber.from_float(1e9)
	var interval: float = state.balance_profile.MEMBER_HIT_SECONDS
	# Three enemies a wave keep the pile's arithmetic readable; they arrive at
	# 10, 23 and 36 seconds of the 35-second wave (D065, D068).
	var share_hit := state.get_effective_collection().multiply_scalar(1.0 / 3.0)
	var first_hits: Array = []
	var repeats: Array = []
	var clock := 0.0
	while clock < 18.5:
		for event in state._advance_waves(0.25):
			if event.type == "tax_collection":
				first_hits.append(clock)
			elif event.type == "pile_hit":
				repeats.append(clock)
				_expect(absf(event.amount.log10() - share_hit.multiply_scalar(state.balance_profile.HEAT_UP_PER_HIT).log10()) < 1.0e-9, "a repeat hit should be the member's share heated up 4% (D063)")
		clock += 0.25
	# Times are the clock at the start of the step the hit fell in.
	_expect(first_hits.size() == 1 and repeats.size() == 1 and absf(float(repeats[0]) + 0.25 - (10.0 + interval)) < 0.01, "the front member should hit again one interval after it lands: %s" % str(repeats))
	for step in range(82):
		state._advance_waves(0.25)
	_expect(state.wave == 2 and state.active_encounter.at_number_count() == 3 and state.active_encounter.front_index() == 0 and not state.active_encounter.is_own(state.active_encounter.members[0]), "unbeaten members should carry into the next wave, in front")
	var front_before: ScientificNumber = state.active_encounter.members[0].hp.copy()
	state.active_encounter.apply_compliance(ScientificNumber.from_float(0.5))
	_expect(state.active_encounter.members[0].hp.compare_to(front_before.subtract(ScientificNumber.from_float(0.5))) == 0, "damage should strike the carried member at the Number first")

	# A pile saves and resumes exactly, and a run resumed on an older profile
	# keeps its pile where it was, on today's curve.
	var save_path := "res://.number_go_up_test_save.json"
	state.save_path = save_path
	_expect(state.save(), "a run with a pile should save")
	var resumed := GameState.new()
	resumed.balance_profile.OPENING_HIT_WAVES = 0
	resumed.balance_profile.OPENING_EASED_BY = 0
	resumed.balance_profile.FIRST_WAVE_MEMBERS = 3
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.active_encounter.at_number_count() == state.active_encounter.at_number_count() and resumed.active_encounter.members[0].wave == 1, "the pile should resume in front")
	for step in range(80):
		state._advance_waves(0.25)
		resumed._advance_waves(0.25)
	_expect(resumed.number.compare_to(state.number) == 0 and resumed.wave == state.wave, "a resumed pile should play out exactly as the saved one")
	_expect(resumed.save(), "the resumed pile should save")
	var older := _read_json(save_path)
	older.balance_profile_id = "tax-foundation-v10"
	_write_json(save_path, older)
	var rebuilt := GameState.new()
	rebuilt.balance_profile.OPENING_HIT_WAVES = 0
	rebuilt.balance_profile.OPENING_EASED_BY = 0
	rebuilt.balance_profile.FIRST_WAVE_MEMBERS = 3
	rebuilt.save_path = save_path
	rebuilt.load()
	var carried_hits: Array = rebuilt.active_encounter.members.filter(func(member): return not rebuilt.active_encounter.is_own(member)).map(func(member): return member.wave_hit.compare_to(rebuilt.balance_profile.collection_for_wave(1, int(member.wave))) == 0)
	_expect(not carried_hits.is_empty() and not carried_hits.has(false) and rebuilt.active_encounter.at_number_count() == resumed.active_encounter.at_number_count(), "a rebuilt pile should keep its members at the Number, on today's Hit")
	var rebuilt_before := rebuilt.number.copy()
	rebuilt._advance_waves(0.01)
	_expect(rebuilt.number.compare_to(rebuilt_before) == 0, "a rebuilt pile should not land an extra hit on load")
	rebuilt.clear_save()

	# Left alone, the pile grows, and so do the hits it lands each clock.
	var pile := GameState.new()
	pile.balance_profile.OPENING_HIT_WAVES = 0
	pile.balance_profile.OPENING_EASED_BY = 0
	pile.balance_profile.FIRST_WAVE_MEMBERS = 3
	pile.start_run(1, 72)
	pile.number = ScientificNumber.from_float(1e12)
	var hits_per_clock: Array = []
	for clock_index in range(4):
		var count := 0
		for step in range(140):
			count += pile._advance_waves(0.25).filter(func(event): return event.type == "tax_collection" or event.type == "pile_hit").size()
		hits_per_clock.append(count)
	_expect(hits_per_clock[3] > hits_per_clock[1] and hits_per_clock[1] > hits_per_clock[0], "an unbeaten pile should hit more often clock on clock: %s" % str(hits_per_clock))

	# D063: a boss lets waves keep coming. It reaches the Number at 30 seconds
	# (D068), hits, joins the next wave's pile and hits again on its wave's clock.
	var boss := GameState.new()
	boss.balance_profile.OPENING_HIT_WAVES = 0
	boss.balance_profile.OPENING_EASED_BY = 0
	boss.start_run(1, 73)
	boss.number = ScientificNumber.from_float(1e12)
	boss.wave = 10
	boss.active_encounter = boss._make_encounter(10)
	var boss_hits := 0
	for step in range(150):
		boss_hits += boss._advance_waves(0.25).filter(func(event): return event.type == "boss_collection").size()
	# At 30 seconds, then 35; its next is 5 seconds into wave 11.
	_expect(boss.wave == 11 and boss_hits == 2 and boss.active_encounter.boss_index() >= 0, "a boss should let waves come and hit every %.0f seconds: wave %d, %d hits" % [boss.balance_profile.MEMBER_HIT_SECONDS, boss.wave, boss_hits])

	# Beaten after landing: the wave still counts as beaten.
	var late := GameState.new()
	late.balance_profile.OPENING_HIT_WAVES = 0
	late.balance_profile.OPENING_EASED_BY = 0
	late.balance_profile.FIRST_WAVE_MEMBERS = 3
	late.start_run(1, 74)
	late.number = ScientificNumber.from_float(1e6)
	for step in range(141):
		late._advance_waves(0.25)
	_expect(late.wave == 2, "the fixture should carry wave 1's members into wave 2")
	for step in range(41):
		late._advance_waves(0.25)
	_expect(late.wave == 2 and late.active_encounter.landed_count() >= 1, "the fixture should have one of wave 2's own members at the Number")
	_beat_wave(late)
	var late_events: Array = []
	for step in range(99):
		late_events.append_array(late._advance_waves(0.25))
	_expect(late.wave == 3 and late_events.any(func(event): return event.type == "wave_clear") and late.get_tier_record(1).highest_wave >= 2, "a wave whose members are all beaten should count as beaten")

	# A Brace blocks every hit of the clock it was raised in, the pile's too.
	var braced := GameState.new()
	braced.balance_profile.OPENING_HIT_WAVES = 0
	braced.balance_profile.OPENING_EASED_BY = 0
	braced.balance_profile.FIRST_WAVE_MEMBERS = 3
	braced.start_run(1, 75)
	braced.number = ScientificNumber.from_float(1e6)
	for step in range(141):
		braced._advance_waves(0.25)
	_expect(braced.brace(), "a Brace should be raised against the pile")
	var after_brace := braced.number.copy()
	for step in range(138):
		braced._advance_waves(0.25)
	_expect(braced.number.compare_to(after_brace) == 0 and braced.braced, "a Brace should block every hit until its clock ends")
	for step in range(2):
		braced._advance_waves(0.25)
	_expect(not braced.braced, "a spent Brace should end with its clock")

## D059: to wave 30 a member that reaches the Number hits once and leaves,
## and a wave with one through passes unbeaten; from wave 31 members stay,
## hitting every 15 seconds and easing to MEMBER_HIT_SECONDS by wave 50.
func _test_opening_members_pass() -> void:
	var profile := TaxBalanceProfile.new()
	_expect(profile.member_hit_seconds(1) == 0.0 and profile.member_hit_seconds(30) == 0.0, "opening members should hit once and pass")
	_expect(is_equal_approx(profile.member_hit_seconds(31), 14.5) and is_equal_approx(profile.member_hit_seconds(40), 10.0) and is_equal_approx(profile.member_hit_seconds(50), profile.MEMBER_HIT_SECONDS), "after the opening the interval should ease from 15 seconds to the member interval by wave 50")
	var state := GameState.new()
	state.balance_profile.ENEMY_MIX = {"basic": 1.0}
	state.start_run(1, 81)
	state.number = ScientificNumber.from_float(1e6)
	var hits := 0
	var opening_count: int = state.active_encounter.members.size()
	for step in range(145):
		hits += state._advance_waves(0.25).filter(func(event): return event.type == "tax_collection" or event.type == "pile_hit").size()
	_expect(hits == opening_count and state.wave == 2 and state.active_encounter.at_number_count() == 0, "an opening wave's enemies should each hit once and leave nothing behind")
	_expect(int(state.get_tier_record(1).highest_wave) == 0, "an opening wave with a member through should not count as beaten")
	state.wave = 31
	state.wave_accumulator = 0.0
	state.active_encounter = state._make_encounter(31)
	for step in range(41):
		state._advance_waves(0.25)
	_expect(state.active_encounter.at_number_count() == 1, "from wave 31 a member that reaches the Number should stay")

## D060: a V10 active save from before the D059 opening rule may contain a
## repeating member from an early wave, despite having the same profile ID.
func _test_d058_opening_save_reconciles() -> void:
	var save_path := "res://.number_go_up_test_save.json"
	var old := GameState.new()
	old.save_path = save_path
	old.start_run(1, 82)
	old.number = ScientificNumber.from_float(1e6)
	old.coins = 123
	old.cash = ScientificNumber.from_float(456)
	old.wave = 2
	old.wave_accumulator = 6.25
	old.active_encounter = old._make_encounter(2)
	var own_count: int = old.active_encounter.members.size()
	for member in old.active_encounter.members:
		member.interval = 5.0
	var own_front: Dictionary = old.active_encounter.members[0]
	own_front.state = TaxEncounter.AT_NUMBER
	own_front.landed = true
	own_front.next_hit = 11.0
	var carried: Dictionary = old._make_encounter(1).members[0]
	carried.state = TaxEncounter.AT_NUMBER
	carried.landed = true
	carried.interval = 5.0
	carried.next_hit = 7.0
	old.active_encounter.carry_in([carried])
	var number_before: ScientificNumber = old.number.copy()
	var own_hp_before: ScientificNumber = old.active_encounter.own_uncleared()
	_expect(old.save(), "a D058-shaped V10 opening run should save")
	var saved := _read_json(save_path)
	_expect(int(saved.version) == SaveDataV12.VERSION and str(saved.balance_profile_id) == old.balance_profile.PROFILE_ID, "the old fixture should have D059's save version and profile ID")
	var resumed := GameState.new()
	resumed.save_path = save_path
	resumed.load()
	_expect(resumed.load_status == GameState.LOAD_OK and resumed.wave == 2, "the old V10 opening run should load")
	_expect(resumed.active_encounter.members.size() == own_count and resumed.active_encounter.members.all(func(member): return int(member.wave) == 2), "members carried from an opening wave should leave on load")
	_expect(int(resumed.active_encounter.members[0].state) == TaxEncounter.LANDED and resumed.active_encounter.members.all(func(member): return float(member.interval) == 0.0), "the old opening member should have hit once and approaching members should pass")
	_expect(resumed.number.compare_to(number_before) == 0 and resumed.active_encounter.own_uncleared().compare_to(own_hp_before) == 0 and resumed.coins == 123 and resumed.cash.compare_to(ScientificNumber.from_float(456)) == 0, "conversion should keep Number, Coins, Cash and this wave's uncleared HP")
	for step in range(3):
		resumed._advance_waves(0.25)
	_expect(resumed.number.compare_to(number_before) == 0, "a converted opening member should not hit again")
	_expect(resumed.save(), "the converted opening run should save in D059 form")
	var current := GameState.new()
	current.save_path = save_path
	current.load()
	_expect(current.active_encounter.to_dict() == resumed.active_encounter.to_dict() and current.number.compare_to(resumed.number) == 0, "the converted D059 encounter should round-trip exactly")
	resumed.clear_save()

	var later := GameState.new()
	later.save_path = save_path
	later.start_run(1, 83)
	later.number = ScientificNumber.from_float(1e9)
	later.wave = 31
	later.wave_accumulator = 6.25
	later.active_encounter = later._make_encounter(31)
	var eased_front: Dictionary = later.active_encounter.members[0]
	eased_front.state = TaxEncounter.AT_NUMBER
	eased_front.landed = true
	eased_front.interval = 5.0
	eased_front.next_hit = 11.0
	var early: Dictionary = later._make_encounter(29).members[0]
	early.state = TaxEncounter.AT_NUMBER
	early.landed = true
	early.interval = 5.0
	later.active_encounter.carry_in([early])
	_expect(later.save(), "a D058-shaped later run with an opening pile should save")
	var later_resumed := GameState.new()
	later_resumed.save_path = save_path
	later_resumed.load()
	_expect(later_resumed.active_encounter.members.all(func(member): return int(member.wave) == 31) and later_resumed.active_encounter.at_number_count() == 1, "an early carried member should leave, while wave 31's own member stays")
	_expect(is_equal_approx(float(later_resumed.active_encounter.members[0].interval), 14.5) and is_equal_approx(float(later_resumed.active_encounter.members[0].next_hit), 20.5), "a D058 member at wave 31 should adopt D059's eased interval and next Hit")
	var premature_hits := 0
	for step in range(20):
		premature_hits += later_resumed._advance_waves(0.25).filter(func(event): return event.type == "pile_hit").size()
	_expect(premature_hits == 0, "a converted wave-31 member should not repeat on D058's old five-second clock")
	_expect(later_resumed.save(), "the converted eased wave should save")
	var later_roundtrip := GameState.new()
	later_roundtrip.save_path = save_path
	later_roundtrip.load()
	_expect(later_roundtrip.active_encounter.to_dict() == later_resumed.active_encounter.to_dict(), "the eased interval and next Hit should round-trip exactly")
	later_roundtrip.clear_save()

	var boss := GameState.new()
	boss.save_path = save_path
	boss.start_run(1, 85)
	boss.wave = 30
	boss.active_encounter = boss._make_encounter(30)
	var early_boss: Dictionary = boss.active_encounter.members[boss.active_encounter.boss_index()]
	early_boss.state = TaxEncounter.AT_NUMBER
	early_boss.landed = true
	early_boss.next_hit = 15.0
	_expect(boss.save(), "an early boss encounter should save")
	var boss_resumed := GameState.new()
	boss_resumed.save_path = save_path
	boss_resumed.load()
	_expect(boss_resumed.active_encounter.to_dict() == boss.active_encounter.to_dict(), "the wave-30 boss should keep its repeat interval and state")
	boss_resumed.clear_save()

	var fresh := GameState.new()
	fresh.save_path = save_path
	fresh.start_run(1, 84)
	fresh.number = ScientificNumber.from_float(1e6)
	for step in range(41):
		fresh._advance_waves(0.25)
	_expect(int(fresh.active_encounter.members[0].state) == TaxEncounter.LANDED, "the D059 fixture should have a member that hit once and left")
	_expect(fresh.save(), "a current D059 opening run should save")
	var fresh_resumed := GameState.new()
	fresh_resumed.save_path = save_path
	fresh_resumed.load()
	_expect(fresh_resumed.active_encounter.to_dict() == fresh.active_encounter.to_dict() and fresh_resumed.number.compare_to(fresh.number) == 0, "a current D059 opening encounter should load exactly")
	for step in range(40):
		fresh._advance_waves(0.25)
		fresh_resumed._advance_waves(0.25)
	_expect(fresh_resumed.wave == fresh.wave and fresh_resumed.number.compare_to(fresh.number) == 0 and fresh_resumed.coins == fresh.coins, "a current D059 opening run should continue identically after load")
	fresh_resumed.clear_save()

## Plays the wave clock in quarter seconds until an event of `type` happens,
## for up to `seconds`, and returns it (null if none).
func _play_until(state: GameState, type: String, seconds: float = 30.0) -> SimulationEvent:
	var elapsed := 0.0
	while elapsed < seconds and state.in_run:
		for event in state._advance_waves(0.25):
			if event.type == type:
				return event
		elapsed += 0.25
	return null

## Beats every member of the active wave with exactly its HP, front first, so
## the Number gains what the whole wave had, as one blow used to (D057).
## A wave of one enemy with `hp` HP, for tests about output and Number rather
## than groups: with many enemies (D065), damage past the front one is lost.
func _one_enemy(state: GameState, hp: ScientificNumber) -> void:
	var profile = state.balance_profile
	state.active_encounter = TaxEncounter.new(state.selected_tier, state.wave, hp, profile.collection_for_wave(state.selected_tier, state.wave), profile.reward_for_wave(state.selected_tier, state.wave), profile.is_boss_wave(state.wave))

## A boss wave that is only its boss: twenty enemies' HP, one enemy's Hit, on
## its wave's clock (D063, D065). For tests of boss rules, where the enemies a
## real boss wave sends would otherwise stand in front of it.
func _lone_boss(state: GameState, boss_wave: int) -> TaxEncounter:
	var profile = state.balance_profile
	var enemy_hp: ScientificNumber = profile.liability_for_wave(state.selected_tier, boss_wave).multiply_scalar(1.0 / profile.wave_weight(boss_wave))
	var enemy_hit: ScientificNumber = profile.collection_for_wave(state.selected_tier, boss_wave).multiply_scalar(1.0 / profile.wave_weight(boss_wave))
	return TaxEncounter.new(state.selected_tier, boss_wave, enemy_hp.multiply_scalar(profile.BOSS_HP_WEIGHT), enemy_hit, profile.reward_for_wave(state.selected_tier, boss_wave), true, [profile.boss_arrival_seconds()], profile.boss_hit_seconds(boss_wave))

## The Coins the active wave's killed members pay in all (D066), paid yet or
## not, plus `extra` Coins before Coin Bonus: each kill its type's worth times
## Coins / Kill Bonus (D068), lifted by Coin Bonus, summed before the whole
## Coins are paid.
func _kill_coins_owed(state: GameState, extra: float = 0.0) -> int:
	var owed := 0.0
	for member in state.active_encounter.members:
		if int(member.state) == TaxEncounter.KILLED:
			owed += state.balance_profile.kill_coins(state.selected_tier, int(member.wave), str(member.kind)) * state.stat("coins_per_kill")
	return floori((owed + extra) * (1.0 + state._effect_sum("coin_bonus")) + 0.000001)

## The Coins waves `from` to `to` pay when every enemy is killed, for a run
## with this seed and no Coin Bonus (D066): each kill, and each wave's end.
func _roster_kill_coins(state: GameState, seed: int, from: int, to: int) -> int:
	var owed := 0.0
	for roster_wave in range(from, to + 1):
		owed += state.balance_profile.wave_end_coins(state.selected_tier, 1.0)
		for entry in state.balance_profile.wave_roster(roster_wave, seed):
			owed += state.balance_profile.kill_coins(state.selected_tier, roster_wave, str(entry.kind))
	return floori(owed + 0.000001)

## Kills every living member of the active wave, wherever it is, and pays
## for the kills.
func _beat_wave(state: GameState) -> void:
	for index in range(state.active_encounter.members.size()):
		var member: Dictionary = state.active_encounter.members[index]
		if TaxEncounter.is_alive(member):
			state.active_encounter.damage_member(index, member.hp.copy())
	state._pay_kills()

## Puts every member of the active wave in the Number's reach, as if it set
## off long ago, for a test about something other than distance (D067). Its
## hits still come on its own clock.
func _all_in_reach(state: GameState) -> void:
	for member in state.active_encounter.members:
		member.sets_off = TaxEncounter.LONG_AGO
	state.active_encounter._sum_remaining()

func _advance_seconds(state: GameState, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		state.advance(0.25)
		elapsed += 0.25

func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))

func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)

func _read_json(path: String) -> Dictionary:
	var json := JSON.new()
	if not FileAccess.file_exists(path) or json.parse(FileAccess.get_file_as_string(path)) != OK or not (json.data is Dictionary):
		return {}
	return json.data

## Every test save file still on disk; a test that leaves one is a bug.
func _leftover_save_files() -> Array:
	var leftovers := []
	var directory := DirAccess.open("res://")
	if directory != null:
		directory.include_hidden = true
		for file_name in directory.get_files():
			if file_name.begins_with(".number_go_up_test_save"):
				leftovers.append(file_name)
	return leftovers

func _funded_state() -> GameState:
	var state := GameState.new()
	state.coins = 1000000
	state.number = ScientificNumber.from_float(1000000)
	state.lifetime_generated = ScientificNumber.from_float(1000000)
	return state
