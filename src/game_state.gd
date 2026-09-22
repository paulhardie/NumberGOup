class_name GameState
extends RefCounted

const TaxBalanceProfileClass = preload("res://src/tax_balance_profile.gd")
const TaxEncounterClass = preload("res://src/tax_encounter.gd")
const RuleModifierPipelineClass = preload("res://src/rule_modifier_pipeline.gd")
const SaveDataV3Class = preload("res://src/save_data_v3.gd")
const SaveDataV4Class = preload("res://src/save_data_v4.gd")
const SaveDataV5Class = preload("res://src/save_data_v5.gd")

const SAVE_PATH := "user://number_go_up_save.json"
const OFFLINE_CAP_SECONDS := 43200.0
const RESEARCH_WORKSHOP_LEVEL := 120
const PRESTIGE_TEASER_UNLOCK := 110000.0
const PRESTIGE_KNOWLEDGE_SCALE := 4.0

## Public aliases retained for UI/tests. The authored balance lives in
## TaxBalanceProfile rather than being mixed into the state machine.
const WAVE_INTERVAL_SECONDS := 15.0
const FREE_WAVES := 20
const BOSS_WAVE_INTERVAL := 10
const TIER_UNLOCK_WAVE := 100
const BRACE_COST_PERCENT := 0.3
## Armor's id is stable from the Shield Matrix save key it replaced (D013).
const ARMOR_ID := "tax_resistance"
## How many ranks one Workshop press buys. MAX_BUY takes every rank the player
## can afford, up to the row's cap.
const MAX_BUY := -1
const BUY_STEPS := [1, 5, 10, MAX_BUY]

## How to read one row's effect as a player-facing value, keyed by the effect
## the row already declares, so a card cannot drift from what the rank does.
## `base` is the value at rank zero; `op` is how ranks combine, matching the
## _effect_sum / _effect_product call that consumes the effect.
const STAT_DISPLAY := {
	"tap_flat": {"unit": "flat", "base": 1.0, "op": "add"},
	"passive_flat": {"unit": "flat", "base": 0.0, "op": "add"},
	"base_output_multiplier": {"unit": "multiplier", "base": 1.0, "op": "mul"},
	"tick_rate": {"unit": "multiplier", "base": 1.0, "op": "mul"},
	"double_tick_chance": {"unit": "percent", "base": 0.0, "op": "add"},
	"critical_chance": {"unit": "percent", "base": 0.0, "op": "add"},
	"critical_multiplier_add": {"unit": "multiplier", "base": 2.0, "op": "add"},
	"cost_discount": {"unit": "percent", "base": 0.0, "op": "add"},
	"starting_number_flat": {"unit": "flat", "base": 0.0, "op": "add"},
	"collection_resistance": {"unit": "percent", "base": 0.0, "op": "add"},
}

var number := ScientificNumber.new()
var lifetime_generated := ScientificNumber.new()
var highest_number := ScientificNumber.new()
var purchased: Dictionary = {}
var knowledge := 0
var knowledge_purchased: Dictionary = {}
var focus_path := ""
var auto_selected_id := "" # V1 compatibility only; new saves use workshop.automation_targets.
var automation_enabled := true
var workshop := WorkshopState.new()
var wave := 1
var wave_accumulator := 0.0
var coins := 0
var highest_wave := 1
var braced := false
var tax_encounters_enabled := true
var in_run := false
var run_coins_earned := 0
var run_elapsed := 0.0
var run_seed: int = 0
var selected_tier := 1
var tier_records: Dictionary = {}
var active_encounter = null
var active_rule_modifiers: Array = []
var balance_profile = TaxBalanceProfileClass.new()
var last_run_summary: RunSummary = null
var statistics := {
	"taps": 0,
	"ticks": 0,
	"critical_ticks": 0,
	"number_spent": ScientificNumber.new().to_dict(),
	"coins_spent": 0,
	"offline_generated": ScientificNumber.new().to_dict()
}
var settings := {"muted": false, "haptics": true, "reduce_motion": false, "high_contrast": false, "ambience": true}
var tick_accumulator := 0.0
var automation_accumulator := 0.0
var momentum_stacks := 0
var critical_chain := 0
var rng := RandomNumberGenerator.new()
var definitions: Array[UpgradeDefinition] = []
var save_path := SAVE_PATH

func _init() -> void:
	rng.randomize()
	definitions = _make_definitions()
	_ensure_tier_records()

func tap() -> SimulationEvent:
	if not in_run:
		return SimulationEvent.new("tap", ScientificNumber.new(), false)
	statistics.taps += 1
	var is_critical := rng.randf() < _critical_chance()
	var amount := ScientificNumber.from_float(_tap_base() * _base_output_multiplier() * _momentum_multiplier())
	if is_critical:
		amount = amount.multiply_scalar(_critical_multiplier() * (1.0 + _chain_reaction_step() * critical_chain))
		critical_chain += 1
	else:
		critical_chain = 0
	_add_number(amount)
	return SimulationEvent.new("tap", amount, is_critical)

func advance(delta: float) -> Array[SimulationEvent]:
	var events: Array[SimulationEvent] = []
	if not in_run:
		return events
	tick_accumulator += minf(delta, 0.25)
	var interval := 1.0 / _tick_rate()
	var safety := 0
	while tick_accumulator >= interval and safety < 20:
		tick_accumulator -= interval
		events.append(_produce_tick())
		safety += 1
	events.append_array(_advance_waves(delta))
	return events

func _produce_tick() -> SimulationEvent:
	statistics.ticks += 1
	workshop.tick_count += 1
	if _effect_sum("momentum_per_tick") > 0.0:
		momentum_stacks = mini(100, momentum_stacks + 1)
	var is_critical := rng.randf() < _critical_chance()
	var amount := ScientificNumber.from_float(_passive_base() * _base_output_multiplier() * _momentum_multiplier())
	if is_critical:
		amount = amount.multiply_scalar(_critical_multiplier() * (1.0 + _chain_reaction_step() * critical_chain))
		statistics.critical_ticks += 1
		critical_chain += 1
	else:
		critical_chain = 0
	if rng.randf() < _effect_sum("double_tick_chance"):
		amount = amount.multiply_scalar(2.0)
	var burst_interval := _burst_interval()
	if burst_interval > 0 and workshop.tick_count % burst_interval == 0:
		amount = amount.multiply_scalar(2.0)
	_add_number(amount)
	return SimulationEvent.new("tick", amount, is_critical)

func is_output_banking() -> bool:
	return in_run and (active_encounter == null or active_encounter.is_cleared())

func get_rate_per_second() -> ScientificNumber:
	return ScientificNumber.from_float(_passive_base() * _base_output_multiplier() * _momentum_multiplier() * _tick_rate())

func start_run(tier_id: int = -1, seed_override: int = -1) -> bool:
	if in_run:
		return false
	var target_tier := selected_tier if tier_id < 1 else tier_id
	if not select_tier(target_tier):
		return false
	# Number is run health/resources, never a banked head start. Permanent
	# Workshop ranks define the baseline applied to every fresh attempt.
	number = ScientificNumber.from_float(_effect_sum("starting_number_flat"))
	lifetime_generated = ScientificNumber.new()
	workshop.tick_count = 0
	momentum_stacks = 0
	critical_chain = 0
	tick_accumulator = 0.0
	automation_accumulator = 0.0
	in_run = true
	run_coins_earned = 0
	run_elapsed = 0.0
	wave = 1
	wave_accumulator = 0.0
	braced = false
	run_seed = seed_override if seed_override >= 0 else int(Time.get_ticks_usec()) ^ int(Time.get_unix_time_from_system())
	rng.seed = run_seed
	active_encounter = _make_encounter(wave)
	return true

## Retreat is an actual run ending, not a pause. It preserves permanent
## Workshop ranks, Coins, Knowledge, Insights, Shield and tier records.
func end_run() -> RunSummary:
	if not in_run:
		return null
	last_run_summary = RunSummary.new(wave, run_coins_earned, 0, lifetime_generated.copy(), selected_tier, "retreat")
	_reset_run_state()
	return last_run_summary

func select_tier(tier_id: int) -> bool:
	if in_run or not balance_profile.has_tier(tier_id) or not is_tier_unlocked(tier_id):
		return false
	selected_tier = tier_id
	return true

func is_tier_unlocked(tier_id: int) -> bool:
	if tier_id <= 1:
		return balance_profile.has_tier(tier_id)
	if not balance_profile.has_tier(tier_id):
		return false
	return get_tier_best(tier_id - 1) >= balance_profile.get_tier(tier_id).unlock_previous_tier_wave

func get_tier_best(tier_id: int = selected_tier) -> int:
	var record: Dictionary = tier_records.get(str(tier_id), {})
	return int(record.get("highest_wave", 0))

func get_tier_record(tier_id: int = selected_tier) -> Dictionary:
	return tier_records.get(str(tier_id), _new_tier_record())

func _advance_waves(delta: float) -> Array[SimulationEvent]:
	var events: Array[SimulationEvent] = []
	if not tax_encounters_enabled or not in_run:
		return events
	var safe_delta := minf(delta, 0.25)
	run_elapsed += safe_delta
	wave_accumulator += safe_delta
	var safety := 0
	while wave_accumulator >= WAVE_INTERVAL_SECONDS and safety < 10 and in_run:
		wave_accumulator -= WAVE_INTERVAL_SECONDS
		var wave_event := _resolve_wave_boundary()
		if wave_event != null:
			events.append(wave_event)
		safety += 1
	return events

func _resolve_wave_boundary() -> SimulationEvent:
	if active_encounter == null:
		active_encounter = _make_encounter(wave)
	if active_encounter.is_cleared():
		return _complete_current_wave()
	var collection := get_effective_collection()
	if braced:
		collection = ScientificNumber.new()
		braced = false
	number = number.subtract(collection)
	if number.is_zero():
		return _wave_death(wave)
	return SimulationEvent.new("boss_collection" if active_encounter.is_boss else "tax_collection", collection)

func _complete_current_wave() -> SimulationEvent:
	var completed_wave := wave
	var completed_boss: bool = bool(active_encounter.is_boss)
	var coin_gain: int = int(active_encounter.reward)
	var record := get_tier_record(selected_tier).duplicate(true)
	var previous_best := int(record.get("highest_wave", 0))
	record.highest_wave = maxi(previous_best, completed_wave)
	var claimed: Array = record.get("milestones_claimed", [])
	if balance_profile.MILESTONE_WAVES.has(completed_wave) and not claimed.has(completed_wave):
		claimed.append(completed_wave)
		record.milestones_claimed = claimed
		coin_gain += balance_profile.milestone_bonus(selected_tier, completed_wave)
	if completed_wave == TIER_UNLOCK_WAVE:
		var existing_best := float(record.get("best_time", 0.0))
		if existing_best <= 0.0 or run_elapsed < existing_best:
			record.best_time = run_elapsed
	tier_records[str(selected_tier)] = record
	highest_wave = maxi(highest_wave, completed_wave)
	coins += coin_gain
	run_coins_earned += coin_gain
	wave += 1
	active_encounter = _make_encounter(wave)
	if completed_wave == TIER_UNLOCK_WAVE and previous_best < TIER_UNLOCK_WAVE and balance_profile.has_tier(selected_tier + 1):
		return SimulationEvent.new("tier_unlock", ScientificNumber.from_float(float(selected_tier + 1)))
	return SimulationEvent.new("boss_clear" if completed_boss else "wave_clear", ScientificNumber.from_float(float(coin_gain)))

func _make_encounter(target_wave: int):
	var liability := RuleModifierPipelineClass.apply(
		balance_profile.liability_for_wave(selected_tier, target_wave),
		"liability",
		active_rule_modifiers
	)
	return TaxEncounterClass.new(
		selected_tier,
		target_wave,
		liability,
		balance_profile.collection_for_wave(selected_tier, target_wave),
		balance_profile.reward_for_wave(selected_tier, target_wave),
		balance_profile.is_boss_wave(target_wave)
	)

func _wave_death(reached: int) -> SimulationEvent:
	var knowledge_gain := get_prestige_knowledge_gain()
	knowledge += knowledge_gain
	last_run_summary = RunSummary.new(reached, run_coins_earned, knowledge_gain, lifetime_generated.copy(), selected_tier, "death")
	_reset_run_state()
	return SimulationEvent.new("wave_death", ScientificNumber.from_float(float(reached)))

func get_effective_collection() -> ScientificNumber:
	if active_encounter == null:
		return ScientificNumber.new()
	var modifiers := active_rule_modifiers.duplicate(true)
	modifiers.append({
		"source": "armor",
		"target": "collection",
		"stage": "multiplicative",
		"value": clampf(1.0 - _effect_sum("collection_resistance"), 0.0, 1.0),
	})
	return RuleModifierPipelineClass.apply(active_encounter.collection, "collection", modifiers)

func get_effective_liability() -> ScientificNumber:
	if active_encounter == null:
		return ScientificNumber.new()
	return active_encounter.remaining_liability.copy()

func can_brace() -> bool:
	return in_run and active_encounter != null and not active_encounter.is_cleared() and not braced and not number.is_zero()

func brace() -> bool:
	if not can_brace():
		return false
	number = number.subtract(number.multiply_scalar(BRACE_COST_PERCENT))
	braced = true
	return true

func get_definition(upgrade_id: String) -> UpgradeDefinition:
	for definition in definitions:
		if definition.id == upgrade_id:
			return definition
	return null

func definitions_for_progression_type(progression_type: String) -> Array[UpgradeDefinition]:
	var matching: Array[UpgradeDefinition] = []
	for definition in definitions:
		if definition.progression_type == progression_type:
			matching.append(definition)
	return matching

func get_workshop_level() -> int:
	var level := workshop.legacy_credit
	for definition in definitions:
		if definition.category == ProgressionTaxonomy.WORKSHOP:
			level += get_owned(definition.id)
	return level

## A category is open once it has a row to show. Ultimates have none until they
## are authored, so the tab reads as locked without a gate of its own.
func has_category_content(category: String) -> bool:
	for definition in definitions:
		if definition.workshop_category == category:
			return true
	return false

func cards_for_category(category: String) -> Array[UpgradeDefinition]:
	var cards: Array[UpgradeDefinition] = []
	for definition in definitions:
		if definition.workshop_category == category:
			cards.append(definition)
	return cards

func get_owned(upgrade_id: String) -> int:
	if knowledge_purchased.has(upgrade_id):
		return int(knowledge_purchased[upgrade_id])
	return int(purchased.get(upgrade_id, 0))

func get_cost(definition: UpgradeDefinition) -> ScientificNumber:
	return get_cost_at(definition, get_owned(definition.id))

func get_cost_at(definition: UpgradeDefinition, owned: int) -> ScientificNumber:
	var discount := _effect_sum("cost_discount")
	# Focus is a nudge toward a first build, never a permanent branch lock.
	if definition.workshop_category == focus_path:
		discount += 0.25
	return definition.cost_at(owned, discount)

func get_workshop_coin_cost(definition: UpgradeDefinition) -> int:
	return get_workshop_coin_cost_at(definition, get_owned(definition.id))

func get_workshop_coin_cost_at(definition: UpgradeDefinition, owned: int) -> int:
	var cost := get_cost_at(definition, owned)
	if cost.is_zero():
		return 0
	# Authored Workshop costs stay in the exact-number helper so growth and
	# discounts remain inspectable, while Coins themselves are whole units.
	return maxi(1, ceili(cost.mantissa * pow(10.0, cost.exponent)))

## What one press of a multi-buy would actually do: how many ranks land and what
## they cost together. Ranks are priced one at a time and summed, so buying in
## bulk is never cheaper than buying the same ranks one by one. The quote uses
## the discount in force now, so buying Discount ranks in bulk does not make the
## later ranks of that same press cheaper: the price shown is the price paid.
func plan_purchase(upgrade_id: String, count: int = 1) -> Dictionary:
	var refused := {"ranks": 0, "cost": 0}
	var definition := get_definition(upgrade_id)
	if definition == null or definition.category != ProgressionTaxonomy.WORKSHOP:
		return refused
	if in_run or not is_unlocked(definition):
		return refused
	var owned := get_owned(upgrade_id)
	var wanted := definition.max_rank - owned if count == MAX_BUY else maxi(0, count)
	var ranks := 0
	var spent := 0
	while ranks < wanted and owned + ranks < definition.max_rank:
		var step := get_workshop_coin_cost_at(definition, owned + ranks)
		if spent + step > coins:
			break
		spent += step
		ranks += 1
	return {"ranks": ranks, "cost": spent}

func is_unlocked(definition: UpgradeDefinition) -> bool:
	if definition.category == ProgressionTaxonomy.WORKSHOP:
		# Each row carries its own Workshop level, which is what the retired bay
		# gates duplicated: every row's requirement equalled its bay's gate.
		return get_workshop_level() >= definition.workshop_level_required
	return lifetime_generated.compare_to(definition.unlock_lifetime) >= 0

func can_purchase(upgrade_id: String) -> bool:
	return int(plan_purchase(upgrade_id, 1).ranks) > 0

func purchase(upgrade_id: String, silent: bool = false) -> bool:
	return purchase_ranks(upgrade_id, 1) > 0

## Buys what plan_purchase quoted and returns the ranks that landed, so the
## press and the quote can never disagree about the price.
func purchase_ranks(upgrade_id: String, count: int = 1) -> int:
	var plan := plan_purchase(upgrade_id, count)
	var ranks := int(plan.ranks)
	if ranks <= 0:
		return 0
	var cost := int(plan.cost)
	coins -= cost
	purchased[upgrade_id] = get_owned(upgrade_id) + ranks
	statistics.coins_spent = int(statistics.get("coins_spent", 0)) + cost
	return ranks

## The value a row reads as at a given rank, and the unit to read it in. Rows
## with no declared effect (Burst, Crit Chain) fall back to their rank, which is
## what their description already talks in.
func stat_display(definition: UpgradeDefinition, rank: int) -> Dictionary:
	for effect_name in definition.effects:
		if not STAT_DISPLAY.has(effect_name):
			continue
		var shape: Dictionary = STAT_DISPLAY[effect_name]
		var step := float(definition.effects[effect_name])
		var value: float = float(shape.base)
		if str(shape.op) == "mul":
			value *= pow(step, rank)
		else:
			value += step * float(rank)
		return {"value": value, "unit": str(shape.unit)}
	return {"value": float(rank), "unit": "rank"}

func can_purchase_insight() -> bool:
	return knowledge > 0

func purchase_insight() -> bool:
	if not can_purchase_insight():
		return false
	knowledge -= 1
	knowledge_purchased["insight"] = get_owned("insight") + 1
	return true

func get_prestige_knowledge_gain() -> int:
	if lifetime_generated.is_zero():
		return 0
	var order_of_magnitude := lifetime_generated.log10() - log(PRESTIGE_TEASER_UNLOCK) / log(10.0)
	return maxi(0, floori(order_of_magnitude * PRESTIGE_KNOWLEDGE_SCALE))

func can_prestige() -> bool:
	return get_prestige_knowledge_gain() > 0

func prestige() -> int:
	var gain := get_prestige_knowledge_gain()
	if gain <= 0:
		return 0
	knowledge += gain
	_reset_run_state()
	focus_path = ""
	return gain

## Shared by voluntary Prestige and run endings. Workshop ranks are permanent;
## only run Number and transient combat state are cleared.
func _reset_run_state() -> void:
	number = ScientificNumber.new()
	lifetime_generated = ScientificNumber.new()
	workshop.tick_count = 0
	momentum_stacks = 0
	critical_chain = 0
	tick_accumulator = 0.0
	automation_accumulator = 0.0
	wave = 1
	wave_accumulator = 0.0
	braced = false
	in_run = false
	run_elapsed = 0.0
	run_seed = 0
	run_coins_earned = 0
	active_encounter = null

func select_focus(path: String) -> bool:
	if in_run or focus_path != "" or get_workshop_level() < RESEARCH_WORKSHOP_LEVEL:
		return false
	if not ProgressionTaxonomy.WORKSHOP_CATEGORIES.has(path) or not has_category_content(path):
		return false
	focus_path = path
	return true

func has_automation() -> bool:
	return false

func get_auto_slot_count() -> int:
	return 0

func set_automation_target(slot: int, upgrade_id: String) -> void:
	if slot < 0 or slot >= get_auto_slot_count() or get_definition(upgrade_id) == null:
		return
	while workshop.automation_targets.size() <= slot:
		workshop.automation_targets.append("")
	workshop.automation_targets[slot] = upgrade_id

func apply_offline(seconds_elapsed: float) -> OfflineAward:
	# Runs freeze exactly while away. Between runs the Workshop is a management
	# layer, so there is no run Number to generate offline.
	return OfflineAward.new()

func save() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(SaveDataV5Class.make(self)))
	return true

func load() -> OfflineAward:
	if not FileAccess.file_exists(save_path):
		return OfflineAward.new()
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return OfflineAward.new()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if SaveDataV2.is_legacy_v1(parsed):
		_migrate_v1(parsed)
		return OfflineAward.new()
	if SaveDataV2.is_valid(parsed):
		return _migrate_v2(parsed)
	if SaveDataV3Class.is_valid(parsed):
		return _migrate_v3(parsed)
	if SaveDataV4Class.is_valid(parsed):
		return _migrate_v4(parsed)
	if not SaveDataV5Class.is_valid(parsed):
		return OfflineAward.new()
	var data: Dictionary = parsed
	_load_common_fields(data)
	_load_tier_progress(data)
	_restore_saved_run(data)
	return apply_offline(_seconds_since(data))

## V4 kept the Workshop in four bays, with the Armor rank in a field of its own.
## V5 reads the same run, records and currencies; only the Workshop's shape
## changes, and no rank is lost: the Armor rank becomes an ordinary Workshop
## rank and a bay-shaped Research Focus lands on the category that inherited it.
func _migrate_v4(data: Dictionary) -> OfflineAward:
	_load_common_fields(data)
	_fold_retired_workshop_shape(data)
	_load_tier_progress(data)
	_restore_saved_run(data)
	_save_migrated_state()
	return apply_offline(_seconds_since(data))

## Shared by the V2, V3 and V4 migrations, and by nothing else: a V5 save
## already holds the Armor rank in `purchased` and a category in `focus`. The
## Armor rank moves under its stable id, and the retired bay ids that Research
## Focus and the open tab stored become the categories that inherited them.
func _fold_retired_workshop_shape(data: Dictionary) -> void:
	var legacy_armor := int(data.get("tax_resistance_rank", 0))
	if legacy_armor > 0:
		purchased[ARMOR_ID] = maxi(int(purchased.get(ARMOR_ID, 0)), legacy_armor)
	focus_path = ProgressionTaxonomy.category_for_legacy_bay(focus_path)

func _load_tier_progress(data: Dictionary) -> void:
	tier_records = data.get("tier_records", {})
	_ensure_tier_records()
	selected_tier = int(data.get("selected_tier", 1))
	if not balance_profile.has_tier(selected_tier):
		selected_tier = 1

## A saved active run resumes with identical remaining Liability and identical
## RNG state (D006). A save taken between runs restores a clean run instead.
func _restore_saved_run(data: Dictionary) -> void:
	wave = maxi(1, int(data.get("wave", 1)))
	wave_accumulator = clampf(float(data.get("wave_accumulator", 0.0)), 0.0, WAVE_INTERVAL_SECONDS)
	in_run = bool(data.get("in_run", false))
	var loaded_modifiers: Variant = data.get("active_rule_modifiers", [])
	active_rule_modifiers = loaded_modifiers if loaded_modifiers is Array else []
	run_coins_earned = int(data.get("run_coins_earned", 0))
	run_elapsed = maxf(0.0, float(data.get("run_elapsed", 0.0)))
	run_seed = str(data.get("run_seed", "0")).to_int()
	braced = bool(data.get("braced", false))
	if in_run:
		var encounter_data: Variant = data.get("active_encounter", null)
		active_encounter = TaxEncounterClass.from_dict(encounter_data) if encounter_data is Dictionary else _make_encounter(wave)
		var saved_rng_state := str(data.get("rng_state", "0")).to_int()
		if saved_rng_state != 0:
			rng.state = saved_rng_state
		elif run_seed != 0:
			rng.seed = run_seed
	else:
		active_encounter = null
		wave = 1
		wave_accumulator = 0.0

func _seconds_since(data: Dictionary) -> float:
	return Time.get_unix_time_from_system() - float(data.get("last_seen_unix", Time.get_unix_time_from_system()))

func _migrate_v3(data: Dictionary) -> OfflineAward:
	_load_common_fields(data)
	_fold_retired_workshop_shape(data)
	_load_tier_progress(data)
	# V3 Workshop ranks become permanent without any rank loss. A live run is
	# restored; banked Number is retired because V4 Number exists only in runs.
	in_run = bool(data.get("in_run", false))
	var loaded_modifiers: Variant = data.get("active_rule_modifiers", [])
	active_rule_modifiers = loaded_modifiers if loaded_modifiers is Array else []
	if in_run:
		wave = maxi(1, int(data.get("wave", 1)))
		wave_accumulator = clampf(float(data.get("wave_accumulator", 0.0)), 0.0, WAVE_INTERVAL_SECONDS)
		run_coins_earned = int(data.get("run_coins_earned", 0))
		run_elapsed = maxf(0.0, float(data.get("run_elapsed", 0.0)))
		run_seed = str(data.get("run_seed", "0")).to_int()
		braced = bool(data.get("braced", false))
		var encounter_data: Variant = data.get("active_encounter", null)
		active_encounter = TaxEncounterClass.from_dict(encounter_data) if encounter_data is Dictionary else _make_encounter(wave)
		var saved_rng_state := str(data.get("rng_state", "0")).to_int()
		if saved_rng_state != 0:
			rng.state = saved_rng_state
		elif run_seed != 0:
			rng.seed = run_seed
	else:
		_reset_run_state()
	_save_migrated_state()
	return OfflineAward.new()

func _load_common_fields(data: Dictionary) -> void:
	number = ScientificNumber.from_dict(data.number)
	lifetime_generated = ScientificNumber.from_dict(data.lifetime)
	highest_number = ScientificNumber.from_dict(data.get("highest", data.number))
	purchased = data.get("purchased", {})
	knowledge = int(data.get("knowledge", 0))
	knowledge_purchased = data.get("knowledge_purchased", {})
	focus_path = str(data.get("focus", ""))
	automation_enabled = bool(data.get("automation_enabled", true))
	workshop.from_dict(data.get("workshop", {}))
	coins = int(data.get("coins", 0))
	highest_wave = int(data.get("highest_wave", 1))
	statistics.merge(data.get("statistics", {}), true)
	settings.merge(data.get("settings", {}), true)

func _migrate_v2(data: Dictionary) -> OfflineAward:
	_load_common_fields(data)
	_fold_retired_workshop_shape(data)
	selected_tier = 1
	var old_best := maxi(1, int(data.get("highest_wave", 1)))
	tier_records = {"1": {"highest_wave": old_best, "best_time": 0.0, "milestones_claimed": []}}
	_ensure_tier_records()
	in_run = bool(data.get("in_run", false))
	run_coins_earned = int(data.get("run_coins_earned", 0))
	wave = maxi(1, int(data.get("wave", 1))) if in_run else 1
	wave_accumulator = clampf(float(data.get("wave_accumulator", 0.0)), 0.0, WAVE_INTERVAL_SECONDS) if in_run else 0.0
	run_seed = int(Time.get_ticks_usec()) ^ int(Time.get_unix_time_from_system())
	rng.seed = run_seed
	active_encounter = _make_encounter(wave) if in_run else null
	if not in_run:
		_reset_run_state()
	_save_migrated_state()
	return OfflineAward.new()

func _migrate_v1(data: Dictionary) -> void:
	number = ScientificNumber.from_dict(data.number)
	lifetime_generated = ScientificNumber.from_dict(data.lifetime)
	highest_number = ScientificNumber.from_dict(data.get("highest", data.number))
	statistics.merge(data.get("statistics", {}), true)
	settings.merge(data.get("settings", {}), true)
	var legacy: Dictionary = data.get("purchased", {})
	purchased = {}
	# Preserve directly comparable items as ranked Workshop cards. Any excess or
	# unmatched prototype rank becomes non-spendable level credit, never lost progress.
	var hand_ranks := int(legacy.get("stronger_tap", 0)) + int(legacy.get("steady_hand", 0))
	var engine_ranks := int(legacy.get("generator_two", 0)) + int(legacy.get("more_power", 0))
	purchased["stronger_tap"] = mini(5, hand_ranks)
	purchased["generator"] = mini(5, int(legacy.get("generator", 0)))
	purchased["generator_two"] = mini(3, engine_ranks)
	purchased["faster_cadence"] = mini(5, int(legacy.get("faster_cadence", 0)))
	purchased["faster_echo"] = mini(3, int(legacy.get("faster_echo", 0)))
	purchased["more_critical"] = mini(5, int(legacy.get("more_critical", 0)))
	purchased["chain_reaction"] = mini(3, int(legacy.get("chain_reaction", 0)))
	purchased["smarter_efficiency"] = mini(3, int(legacy.get("smarter_efficiency", 0)))
	purchased["automation_core"] = mini(1, int(legacy.get("automation_core", 0)))
	var mapped_ids := ["stronger_tap", "steady_hand", "generator", "generator_two", "more_power", "faster_cadence", "faster_echo", "more_critical", "chain_reaction", "smarter_efficiency", "automation_core", "workshop_bench", "smarter_momentum", "auto_generator"]
	var credit := int(legacy.get("workshop_bench", 0)) + int(legacy.get("smarter_momentum", 0)) + int(legacy.get("auto_generator", 0))
	credit += maxi(0, hand_ranks - 5) + maxi(0, int(legacy.get("generator", 0)) - 5) + maxi(0, engine_ranks - 3)
	credit += maxi(0, int(legacy.get("faster_cadence", 0)) - 5) + maxi(0, int(legacy.get("faster_echo", 0)) - 3)
	credit += maxi(0, int(legacy.get("more_critical", 0)) - 5) + maxi(0, int(legacy.get("chain_reaction", 0)) - 3)
	credit += maxi(0, int(legacy.get("smarter_efficiency", 0)) - 3) + maxi(0, int(legacy.get("automation_core", 0)) - 1)
	for legacy_id in legacy:
		if not mapped_ids.has(legacy_id):
			credit += maxi(0, int(legacy[legacy_id]))
	workshop.legacy_credit = credit
	focus_path = ProgressionTaxonomy.category_for_legacy_bay(str(data.get("focus", "")))
	var old_target := str(data.get("auto_selected", ""))
	if old_target != "":
		workshop.automation_targets = [old_target]
	_reset_run_state()
	_save_migrated_state()

func _save_migrated_state() -> void:
	save()

func clear_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func has_persistent_storage() -> bool:
	return OS.is_userfs_persistent()

## Output damages the active wave first and only the overflow becomes Number
## (D012); lifetime production still counts all of it, so Knowledge is unchanged.
func _add_number(amount: ScientificNumber) -> void:
	lifetime_generated = lifetime_generated.add(amount)
	var overflow := amount
	if in_run and active_encounter != null:
		overflow = amount.subtract(active_encounter.apply_compliance(amount))
	number = number.add(overflow)
	if number.compare_to(highest_number) > 0:
		highest_number = number.copy()

func _ensure_tier_records() -> void:
	for tier in balance_profile.tiers:
		var key := str(tier.id)
		if not tier_records.has(key) or not (tier_records[key] is Dictionary):
			tier_records[key] = _new_tier_record()

func _new_tier_record() -> Dictionary:
	return {"highest_wave": 0, "best_time": 0.0, "milestones_claimed": []}

func _tap_base() -> float:
	return 1.0 + _effect_sum("tap_flat")

func _passive_base() -> float:
	return _effect_sum("passive_flat")

func _tick_rate() -> float:
	return _effect_product("tick_rate", 1.0)

func _base_output_multiplier() -> float:
	return _effect_product("base_output_multiplier", 1.0)

func _momentum_multiplier() -> float:
	return 1.0 + float(momentum_stacks) * _effect_sum("momentum_per_tick")

func _critical_chance() -> float:
	return clampf(_effect_sum("critical_chance"), 0.0, 0.8)

func _critical_multiplier() -> float:
	return 2.0 + _effect_sum("critical_multiplier_add")

func _chain_reaction_step() -> float:
	return 0.005 * get_owned("chain_reaction")

## Burst shortens the interval by one tick per rank, from 12 down to the same
## floor of 6 the three-rank version reached. The floor is what keeps deepening
## this row a pacing change rather than a power change.
func _burst_interval() -> int:
	var rank := get_owned("burst_relay")
	if rank <= 0:
		return 0
	return maxi(6, 12 - rank)

func _effect_sum(effect_name: String) -> float:
	var total := 0.0
	for definition in definitions:
		if definition.effects.has(effect_name):
			total += float(definition.effects[effect_name]) * get_owned(definition.id)
	return total

func _effect_product(effect_name: String, base: float) -> float:
	var total := base
	for definition in definitions:
		if definition.effects.has(effect_name):
			total *= pow(float(definition.effects[effect_name]), get_owned(definition.id))
	return total

## The Workshop catalogue. Every row declares the category it sits on (D013);
## ids are stable because saves key ranks by them, so a row can move shelf or
## change its player-facing name without touching a save.
##
## Ladder shape (D019): each row runs 50-100 ranks at a flat cost growth, rather
## than 3-10 ranks at 1.55-2.00. A rank's effect is divided by the same factor
## its cap was multiplied by, so the value at max rank is unchanged, and each
## row's Coins-to-max is designed rather than inherited: the Workshop still
## costs about 86,000 Coins in total, now spread over 906 ranks instead of 51.
func _make_definitions() -> Array[UpgradeDefinition]:
	const ATTACK := ProgressionTaxonomy.ATTACK
	const DEFENSE := ProgressionTaxonomy.DEFENSE
	const UTILITY := ProgressionTaxonomy.UTILITY
	return [
		UpgradeDefinition.new("stronger_tap", "TAP DAMAGE", "Hand Press. +0.05 damage per tap per rank.", ScientificNumber.from_float(2.77), ScientificNumber.from_float(10), "workshop", {"tap_flat": 0.05}, false, 1.03796, ProgressionTaxonomy.MODULE, ATTACK, 100, 0),
		UpgradeDefinition.new("generator", "DAMAGE PER SECOND", "Desk Dynamo. +0.075 base damage every second per rank.", ScientificNumber.from_float(3.71), ScientificNumber.from_float(20), "workshop", {"passive_flat": 0.075}, false, 1.03796, ProgressionTaxonomy.MODULE, ATTACK, 100, 0),
		UpgradeDefinition.new("generator_two", "DAMAGE MULTIPLIER", "Number Engine. All damage ×1.007 per rank.", ScientificNumber.from_float(12.37), ScientificNumber.from_float(120), "workshop", {"base_output_multiplier": 1.00701257}, false, 1.06452, ProgressionTaxonomy.MODULE, ATTACK, 60, 0),
		UpgradeDefinition.new("faster_cadence", "TICK SPEED", "Tick Wheel. Ticks come ×1.009 faster per rank.", ScientificNumber.from_float(6.52), ScientificNumber.from_float(100), "workshop", {"tick_rate": 1.00915776}, false, 1.03796, ProgressionTaxonomy.MODULE, ATTACK, 100, 12),
		UpgradeDefinition.new("faster_echo", "DOUBLE TICK", "+0.4% chance a tick counts twice per rank.", ScientificNumber.from_float(7.71), ScientificNumber.from_float(300), "workshop", {"double_tick_chance": 0.004}, false, 1.06452, ProgressionTaxonomy.PROTOCOL, ATTACK, 60, 12),
		UpgradeDefinition.new("burst_relay", "BURST", "Burst Relay. Every 11th tick counts double, one tick sooner per rank, down to every 6th.", ScientificNumber.from_float(103), ScientificNumber.from_float(700), "workshop", {}, false, 1.64375, ProgressionTaxonomy.PROTOCOL, ATTACK, 6, 12),
		UpgradeDefinition.new("more_critical", "CRIT CHANCE", "Critical Lens. +0.25% critical chance per rank.", ScientificNumber.from_float(7.45), ScientificNumber.from_float(500), "workshop", {"critical_chance": 0.0025}, false, 1.03796, ProgressionTaxonomy.PROTOCOL, ATTACK, 100, 30),
		UpgradeDefinition.new("magnitude_coil", "CRIT DAMAGE", "Magnitude Coil. +0.05 critical multiplier per rank.", ScientificNumber.from_float(10.82), ScientificNumber.from_float(900), "workshop", {"critical_multiplier_add": 0.05}, false, 1.06452, ProgressionTaxonomy.PROTOCOL, ATTACK, 60, 30),
		UpgradeDefinition.new("chain_reaction", "CRIT CHAIN", "Chain Reaction. Each critical strengthens the next by 0.5% per rank.", ScientificNumber.from_float(15.47), ScientificNumber.from_float(1800), "workshop", {}, false, 1.06452, ProgressionTaxonomy.PROTOCOL, ATTACK, 60, 30),
		UpgradeDefinition.new("automation_core", "AUTO CRANK", "+0.1 base damage every second per rank.", ScientificNumber.from_float(9.23), ScientificNumber.new(), "workshop", {"passive_flat": 0.1}, false, 1.07819, ProgressionTaxonomy.ROUTINE, ATTACK, 50, 60),
		UpgradeDefinition.new(ARMOR_ID, "ARMOR", "Shield Matrix. Every hit is 0.4% smaller per rank.", ScientificNumber.from_float(7.45), ScientificNumber.new(), "workshop", {"collection_resistance": 0.004}, false, 1.03796, ProgressionTaxonomy.MODULE, DEFENSE, 100, 0),
		UpgradeDefinition.new("priority_buffer", "CUSHION", "Starting Reserve. Begin every run with 10 Number per rank.", ScientificNumber.from_float(18.51), ScientificNumber.new(), "workshop", {"starting_number_flat": 10.0}, false, 1.07819, ProgressionTaxonomy.ROUTINE, DEFENSE, 50, 60),
		UpgradeDefinition.new("smarter_efficiency", "DISCOUNT", "Efficiency Matrix. All Workshop costs 0.25% lower per rank.", ScientificNumber.from_float(12.37), ScientificNumber.from_float(2500), "workshop", {"cost_discount": 0.0025}, false, 1.06452, ProgressionTaxonomy.MODULE, UTILITY, 60, 60),
		UpgradeDefinition.new("insight", "INSIGHT", "Base production ×1.02 per rank. Costs Knowledge; survives every reset.", ScientificNumber.new(), ScientificNumber.new(), "knowledge", {"base_output_multiplier": 1.02}, true, 1.0, ProgressionTaxonomy.KNOWLEDGE, "", 999999, 0)
	]
