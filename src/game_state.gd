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
const ARMOR_PER_RANK := 0.04

var number := ScientificNumber.new()
var lifetime_generated := ScientificNumber.new()
var highest_number := ScientificNumber.new()
var purchased: Dictionary = {}
var knowledge := 0
var knowledge_purchased: Dictionary = {}
var focus_category := ""
var auto_selected_id := "" # V1 compatibility only; new saves use workshop.automation_targets.
var automation_enabled := true
var workshop := WorkshopState.new()
var wave := 1
var wave_accumulator := 0.0
var coins := 0
var highest_wave := 1
var braced := false
var defense_unlocked := false
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
	var amount := ScientificNumber.from_float(_tap_base() * _damage_multiplier() * _momentum_multiplier())
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
	var amount := ScientificNumber.from_float(_passive_base() * _damage_multiplier() * _momentum_multiplier())
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
	return ScientificNumber.from_float(_passive_base() * _damage_multiplier() * _momentum_multiplier() * _tick_rate())

func start_run(tier_id: int = -1, seed_override: int = -1) -> bool:
	if in_run:
		return false
	var target_tier := selected_tier if tier_id < 1 else tier_id
	if not select_tier(target_tier):
		return false
	# Number is run health/resources, never a banked head start. Permanent
	# Workshop ranks define the baseline applied to every fresh attempt.
	# Cushion scales with the tier's pressure, or it is a trap above Tier 1:
	# a flat 500 against a wave-1 hit twenty times that size buys nothing.
	number = ScientificNumber.from_float(_effect_sum("starting_number_flat") * get_cushion_scale())
	run_peak_number = number.copy()
	second_wind_used = false
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
## Workshop ranks, Coins, Knowledge, Insights, Armor and tier records.
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

## Cushion is the first stat whose worth depends on which tier is being played,
## so it is priced in that tier's hits rather than in absolute Number.
func get_cushion_scale(tier_id: int = selected_tier) -> float:
	return balance_profile.get_tier(tier_id).collection_multiplier

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
	defense_unlocked = true
	var collection := get_effective_collection()
	if braced:
		collection = ScientificNumber.new()
		braced = false
	number = number.subtract(collection)
	# Recoil turns the hit into progress on the wave that landed it. A braced
	# boundary deals none, because no hit landed.
	var recoil := _effect_sum("recoil_share")
	if recoil > 0.0 and not collection.is_zero():
		active_encounter.apply_compliance(collection.multiply_scalar(recoil))
	if number.is_zero():
		var rescued := _try_second_wind()
		if not rescued:
			return _wave_death(wave, collection, active_encounter.is_boss)
		return SimulationEvent.new("second_wind", number.copy())
	return SimulationEvent.new("boss_collection" if active_encounter.is_boss else "tax_collection", collection)

## Once per run, a hit that would end the run leaves a share of the run's peak
## Number instead. The share is the rank's own value, so an early rank buys a
## breath rather than a rescue.
func _try_second_wind() -> bool:
	if second_wind_used:
		return false
	var share := _effect_sum("second_wind_share")
	if share <= 0.0:
		return false
	var restored := run_peak_number.multiply_scalar(share)
	if restored.is_zero():
		return false
	second_wind_used = true
	number = restored
	return true

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
	# Coin Bonus lifts everything a beaten wave pays, milestone bonuses included:
	# a milestone is a wave beaten, and one rule is easier to read than two.
	# Floored, not rounded: "+50% Coins" that sometimes pays +100% reads as a
	# bug. Coins are whole, so a 1-Coin grace wave carries no percentage at all
	# — which costs nothing real, because this row opens at Workshop level 60,
	# far past the waves that pay one Coin.
	coin_gain = floori(float(coin_gain) * (1.0 + _effect_sum("coin_bonus")))
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

func _wave_death(reached: int, hit: ScientificNumber, boss: bool) -> SimulationEvent:
	var knowledge_gain := get_prestige_knowledge_gain()
	knowledge += knowledge_gain
	last_run_summary = RunSummary.new(reached, run_coins_earned, knowledge_gain, lifetime_generated.copy(), selected_tier, "death", hit, boss)
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
		"value": maxf(0.0, 1.0 - _effect_sum("hit_reduction")),
	})
	return RuleModifierPipelineClass.apply(active_encounter.collection, "collection", modifiers)

func get_effective_liability() -> ScientificNumber:
	if active_encounter == null:
		return ScientificNumber.new()
	return active_encounter.remaining_liability.copy()

func can_brace() -> bool:
	return in_run and active_encounter != null and not active_encounter.is_cleared() and not braced and not number.is_zero()

func get_brace_cost_percent() -> float:
	return clampf(BRACE_COST_PERCENT + _effect_sum("brace_discount"), BRACE_COST_FLOOR, BRACE_COST_PERCENT)

func brace() -> bool:
	if not can_brace():
		return false
	number = number.subtract(number.multiply_scalar(get_brace_cost_percent()))
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
		if definition.workshop_category != "" and definition.counts_toward_workshop_level:
			level += get_owned(definition.id)
	return level

func is_category_active(category: String) -> bool:
	return get_workshop_level() >= get_category_required_level(category)

func get_category_required_level(category: String) -> int:
	return {
		ProgressionTaxonomy.ATTACK: 0,
		ProgressionTaxonomy.DEFENSE: 0 if defense_unlocked else 99,
		ProgressionTaxonomy.UTILITY: 8,
		ProgressionTaxonomy.ULTIMATES: 0,
	}.get(category, 99)

func upgrades_for_category(category: String) -> Array[UpgradeDefinition]:
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
	if definition.workshop_category == focus_category:
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
	if definition.category == "workshop":
		return get_workshop_level() >= definition.workshop_level_required and is_category_active(definition.workshop_category)
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
	var earned := order_of_magnitude * PRESTIGE_KNOWLEDGE_SCALE * (1.0 + _effect_sum("knowledge_bonus"))
	return maxi(0, floori(earned))

func can_prestige() -> bool:
	return get_prestige_knowledge_gain() > 0

func prestige() -> int:
	var gain := get_prestige_knowledge_gain()
	if gain <= 0:
		return 0
	knowledge += gain
	_reset_run_state()
	focus_category = ""
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
	run_peak_number = ScientificNumber.new()
	second_wind_used = false
	in_run = false
	run_elapsed = 0.0
	run_seed = 0
	run_coins_earned = 0
	active_encounter = null

func select_focus(category: String) -> bool:
	if in_run or focus_category != "" or get_workshop_level() < RESEARCH_WORKSHOP_LEVEL:
		return false
	if not ProgressionTaxonomy.RESEARCH_FOCUS_CATEGORIES.has(category) or not is_category_active(category):
		return false
	focus_category = category
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
	_restore_tier_and_run_fields(data)
	var elapsed := Time.get_unix_time_from_system() - float(data.get("last_seen_unix", Time.get_unix_time_from_system()))
	return apply_offline(elapsed)

func _restore_tier_and_run_fields(data: Dictionary) -> void:
	var saved_tier_records: Variant = data.get("tier_records", {})
	tier_records = saved_tier_records.duplicate(true) if saved_tier_records is Dictionary else {}
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
	# Added after V5 shipped; a save without them resumes with an unspent Second
	# Wind and its peak re-established from the Number it restores.
	var saved_peak: Variant = data.get("run_peak_number", null)
	run_peak_number = ScientificNumber.from_dict(saved_peak) if saved_peak is Dictionary else number.copy()
	second_wind_used = bool(data.get("second_wind_used", false))
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

func _migrate_v4(data: Dictionary) -> OfflineAward:
	_load_common_fields(data)
	_migrate_legacy_workshop(data)
	_restore_tier_and_run_fields(data)
	_save_migrated_state()
	return OfflineAward.new()

func _migrate_v3(data: Dictionary) -> OfflineAward:
	_load_common_fields(data)
	_migrate_legacy_workshop(data)
	# V3 Workshop ranks become permanent without any rank loss. A live run is
	# restored; banked Number is retired because V4 Number exists only in runs.
	_restore_tier_and_run_fields(data)
	if not in_run:
		_reset_run_state()
	_save_migrated_state()
	return OfflineAward.new()

func _load_common_fields(data: Dictionary) -> void:
	number = ScientificNumber.from_dict(data.number)
	lifetime_generated = ScientificNumber.from_dict(data.lifetime)
	highest_number = ScientificNumber.from_dict(data.get("highest", data.number))
	var saved_purchased: Variant = data.get("purchased", {})
	purchased = saved_purchased.duplicate(true) if saved_purchased is Dictionary else {}
	knowledge = int(data.get("knowledge", 0))
	var saved_knowledge: Variant = data.get("knowledge_purchased", {})
	knowledge_purchased = saved_knowledge.duplicate(true) if saved_knowledge is Dictionary else {}
	focus_category = str(data.get("focus_category", ""))
	if not ProgressionTaxonomy.RESEARCH_FOCUS_CATEGORIES.has(focus_category):
		focus_category = ""
	automation_enabled = bool(data.get("automation_enabled", true))
	var saved_workshop: Variant = data.get("workshop", {})
	workshop.from_dict(saved_workshop if saved_workshop is Dictionary else {})
	coins = int(data.get("coins", 0))
	highest_wave = int(data.get("highest_wave", 1))
	defense_unlocked = bool(data.get("defense_unlocked", false)) or int(purchased.get("armor", 0)) > 0
	var saved_statistics: Variant = data.get("statistics", {})
	if saved_statistics is Dictionary:
		statistics.merge(saved_statistics, true)
	var saved_settings: Variant = data.get("settings", {})
	if saved_settings is Dictionary:
		settings.merge(saved_settings, true)

func _migrate_legacy_workshop(data: Dictionary) -> void:
	# Armor was directly purchasable before categories existed, so every legacy
	# player retains access even if the save has no evidence of taking a Hit.
	defense_unlocked = true
	var old_focus := str(data.get("focus", ""))
	focus_category = ProgressionTaxonomy.migrate_legacy_category(old_focus, "")
	var old_armor_rank := maxi(0, int(data.get("tax_resistance_rank", 0)))
	if old_armor_rank > 0:
		purchased["armor"] = maxi(int(purchased.get("armor", 0)), old_armor_rank)

func _migrate_v2(data: Dictionary) -> OfflineAward:
	_load_common_fields(data)
	_migrate_legacy_workshop(data)
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
	defense_unlocked = true
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
	var old_focus := str(data.get("focus", ""))
	if old_focus != "":
		focus_category = ProgressionTaxonomy.migrate_legacy_category(old_focus, "")
	var old_armor_rank := maxi(0, int(data.get("tax_resistance_rank", 0)))
	if old_armor_rank > 0:
		purchased["armor"] = old_armor_rank
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
	var into_wave := ScientificNumber.new()
	if in_run and active_encounter != null:
		into_wave = active_encounter.apply_compliance(amount)
	var banked := amount.subtract(into_wave)
	# Siphon is the one way damage dealt to a wave still reaches Number, which
	# is what stops a wave you cannot beat from being a slow death sentence.
	var siphon := _effect_sum("siphon_share")
	if siphon > 0.0 and not into_wave.is_zero():
		banked = banked.add(into_wave.multiply_scalar(siphon))
	number = number.add(banked)
	if number.compare_to(highest_number) > 0:
		highest_number = number.copy()
	if number.compare_to(run_peak_number) > 0:
		run_peak_number = number.copy()

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

## Everything that scales produced damage, including the boss-only bonus. Taps,
## ticks and the displayed rate all read it, so a boss wave cannot show one
## number and deal another.
func _damage_multiplier() -> float:
	return _base_output_multiplier() * _boss_damage_multiplier()

func _boss_damage_multiplier() -> float:
	if active_encounter == null or not active_encounter.is_boss:
		return 1.0
	return 1.0 + _effect_sum("boss_damage")

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
		UpgradeDefinition.new("stronger_tap", "HAND PRESS", "+1 base tap per rank.", ScientificNumber.from_float(10), ScientificNumber.from_float(10), "workshop", {"tap_flat": 1.0}, false, 1.55, ProgressionTaxonomy.MODULE, ProgressionTaxonomy.ATTACK, 5, 0),
		UpgradeDefinition.new("generator", "DESK DYNAMO", "+1.5 base Number/sec per rank.", ScientificNumber.from_float(35), ScientificNumber.from_float(20), "workshop", {"passive_flat": 1.5}, false, 1.7, ProgressionTaxonomy.MODULE, ProgressionTaxonomy.ATTACK, 5, 0),
		UpgradeDefinition.new("generator_two", "NUMBER ENGINE", "Base production ×1.15 per rank.", ScientificNumber.from_float(180), ScientificNumber.from_float(120), "workshop", {"base_output_multiplier": 1.15}, false, 2.0, ProgressionTaxonomy.MODULE, ProgressionTaxonomy.ATTACK, 3, 0),
		UpgradeDefinition.new("faster_cadence", "TICK WHEEL", "Production ticks ×1.20 faster per rank.", ScientificNumber.from_float(130), ScientificNumber.from_float(100), "workshop", {"tick_rate": 1.20}, false, 1.7, ProgressionTaxonomy.MODULE, ProgressionTaxonomy.ATTACK, 5, 2),
		UpgradeDefinition.new("faster_echo", "DOUBLE TICK", "+8% repeated production-tick chance per rank.", ScientificNumber.from_float(420), ScientificNumber.from_float(300), "workshop", {"double_tick_chance": 0.08}, false, 1.85, ProgressionTaxonomy.PROTOCOL, ProgressionTaxonomy.ATTACK, 3, 2),
		UpgradeDefinition.new("burst_relay", "BURST RELAY", "Every 12 / 9 / 6 ticks produces an extra tick.", ScientificNumber.from_float(1100), ScientificNumber.from_float(700), "workshop", {}, false, 2.0, ProgressionTaxonomy.PROTOCOL, ProgressionTaxonomy.ATTACK, 3, 2),
		UpgradeDefinition.new("more_critical", "CRITICAL LENS", "+5% critical chance per rank.", ScientificNumber.from_float(360), ScientificNumber.from_float(500), "workshop", {"critical_chance": 0.05}, false, 1.75, ProgressionTaxonomy.PROTOCOL, ProgressionTaxonomy.ATTACK, 5, 5),
		UpgradeDefinition.new("magnitude_coil", "MAGNITUDE COIL", "+1 critical multiplier per rank.", ScientificNumber.from_float(1050), ScientificNumber.from_float(900), "workshop", {"critical_multiplier_add": 1.0}, false, 2.0, ProgressionTaxonomy.PROTOCOL, ProgressionTaxonomy.ATTACK, 3, 5),
		UpgradeDefinition.new("chain_reaction", "CHAIN REACTION", "Each critical strengthens the next critical by 10% per rank.", ScientificNumber.from_float(2400), ScientificNumber.from_float(1800), "workshop", {}, false, 2.0, ProgressionTaxonomy.PROTOCOL, ProgressionTaxonomy.ATTACK, 3, 5),
		UpgradeDefinition.new("automation_core", "AUTO CRANK", "+5 base Number/sec per rank.", ScientificNumber.from_float(4000), ScientificNumber.new(), "workshop", {"passive_flat": 5.0}, false, 1.0, ProgressionTaxonomy.ROUTINE, ProgressionTaxonomy.ATTACK, 1, 8),
		# Armor keeps Shield Matrix's round-to-nearest base prices and its former
		# exclusion from Workshop-level gates. Only the category presentation and
		# new Research Focus discount change.
		UpgradeDefinition.new("armor", "ARMOR", "Every Hit is 4% smaller per rank.", ScientificNumber.from_float(15), ScientificNumber.new(), "workshop", {"hit_reduction": ARMOR_PER_RANK}, false, 1.6, ProgressionTaxonomy.MODULE, ProgressionTaxonomy.DEFENSE, 10, 0, true, false),
		UpgradeDefinition.new("priority_buffer", "STARTING RESERVE", "Begin every run with 250 Number per rank.", ScientificNumber.from_float(8500), ScientificNumber.new(), "workshop", {"starting_number_flat": 250.0}, false, 2.0, ProgressionTaxonomy.ROUTINE, ProgressionTaxonomy.DEFENSE, 2, 8),
		UpgradeDefinition.new("smarter_efficiency", "EFFICIENCY MATRIX", "All upgrade costs 5% lower per rank.", ScientificNumber.from_float(1000), ScientificNumber.from_float(2500), "workshop", {"cost_discount": 0.05}, false, 2.0, ProgressionTaxonomy.MODULE, ProgressionTaxonomy.UTILITY, 3, 8),
		UpgradeDefinition.new("insight", "INSIGHT", "Base production ×1.02 per rank. Costs Knowledge; survives every reset.", ScientificNumber.new(), ScientificNumber.new(), "knowledge", {"base_output_multiplier": 1.02}, true, 1.0, ProgressionTaxonomy.KNOWLEDGE, "", 999999, 0)
	]
