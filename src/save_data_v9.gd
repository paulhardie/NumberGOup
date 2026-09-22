class_name SaveDataV9
extends RefCounted

## V9 is V8 plus the last completed run's report. It is null before the first
## run. Older saves have no report to recover and migrate with null.
const VERSION := 9

static func make(state) -> Dictionary:
	return {
		"version": VERSION,
		"economy_model": "workshop-categories-v1",
		"number": state.number.to_dict(),
		"lifetime": state.lifetime_generated.to_dict(),
		"highest": state.highest_number.to_dict(),
		"purchased": state.purchased,
		"knowledge": state.knowledge,
		"knowledge_purchased": state.knowledge_purchased,
		"focus": state.focus_path,
		"automation_enabled": state.automation_enabled,
		"workshop": state.workshop.to_dict(),
		"wave": state.wave,
		"wave_accumulator": state.wave_accumulator,
		"coins": state.coins,
		"highest_wave": state.highest_wave,
		"braced": state.braced,
		"run_peak_number": state.run_peak_number.to_dict(),
		"second_wind_used": state.second_wind_used,
		"rig_ranks": state.rig_ranks,
		"tick_accumulator": state.tick_accumulator,
		"critical_chain": state.critical_chain,
		"lab_ranks": state.lab_ranks,
		"lab_active": state.lab_active,
		"lab_slots": state.lab_slots,
		"gems": state.gems,
		"card_ranks": state.card_ranks,
		"card_active": state.card_active,
		"in_run": state.in_run,
		"run_coins_earned": state.run_coins_earned,
		"run_gems_earned": state.run_gems_earned,
		"run_elapsed": state.run_elapsed,
		# JSON numbers cannot exactly represent every 64-bit RNG value. Strings
		# preserve deterministic replay across save/load without precision loss.
		"run_seed": str(state.run_seed),
		"rng_state": str(state.rng.state),
		"selected_tier": state.selected_tier,
		"tier_records": state.tier_records,
		"active_encounter": state.active_encounter.to_dict() if state.active_encounter != null else null,
		"active_rule_modifiers": state.active_rule_modifiers,
		"balance_profile_id": state.balance_profile.PROFILE_ID,
		"statistics": state.statistics,
		"settings": state.settings,
		"last_run_summary": state.last_run_summary.to_dict() if state.last_run_summary != null else null,
		"last_seen_unix": Time.get_unix_time_from_system(),
	}

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
		and data.has("last_run_summary")
	)

## Check fields before the loader changes any state. V1-V8 lack a summary; V9
## requires null or a complete, well-typed report so damaged saves recover.
static func problem(data: Dictionary) -> String:
	for key in ["number", "lifetime"]:
		if not (data.get(key) is Dictionary):
			return key + " is missing"
	for key in ["number", "lifetime", "highest"]:
		if data.has(key) and data[key] is Dictionary:
			var mantissa: Variant = data[key].get("mantissa", 0.0)
			if not ((mantissa is int or mantissa is float) and is_finite(float(mantissa))):
				return key + " is not a finite number"
	for key in ["highest", "purchased", "knowledge_purchased", "workshop", "tier_records", "statistics", "settings"]:
		if data.has(key) and not (data[key] is Dictionary):
			return key + " is not an object"
	for key in ["coins", "knowledge", "gems", "lab_slots", "run_gems_earned", "wave", "highest_wave", "selected_tier"]:
		if data.has(key) and not (data[key] is int or data[key] is float):
			return key + " is not a number"
	if int(data.get("version", 0)) != VERSION:
		return ""
	var saved_summary: Variant = data.get("last_run_summary")
	if saved_summary == null:
		return ""
	if not (saved_summary is Dictionary):
		return "last_run_summary is not an object"
	for key in ["wave_reached", "coins_earned", "knowledge_gained", "tier_id", "gems_earned"]:
		var minimum := 1 if key == "wave_reached" or key == "tier_id" else 0
		if not _is_whole_number(saved_summary.get(key), minimum):
			return "last_run_summary." + key + " is not a valid whole number"
	if not (saved_summary.get("outcome") is String) or not ["death", "retreat", "prestige"].has(saved_summary.outcome):
		return "last_run_summary.outcome is invalid"
	if not (saved_summary.get("lost_to_boss") is bool):
		return "last_run_summary.lost_to_boss is not a boolean"
	for key in ["peak_number", "final_hit", "attack_gap", "defense_gap"]:
		if not _valid_scientific_number(saved_summary.get(key)):
			return "last_run_summary." + key + " is not a finite number"
	return ""

static func _is_whole_number(value: Variant, minimum: int) -> bool:
	if not (value is int or value is float):
		return false
	var number := float(value)
	return is_finite(number) and number >= float(minimum) and number < 9.223372036854776e18 and floor(number) == number

static func _valid_scientific_number(value: Variant) -> bool:
	if not (value is Dictionary):
		return false
	var mantissa: Variant = value.get("mantissa")
	var exponent: Variant = value.get("exponent")
	if not (mantissa is int or mantissa is float) or not (exponent is int or exponent is float):
		return false
	var exponent_number := float(exponent)
	return (is_finite(float(mantissa)) and float(mantissa) >= 0.0
		and is_finite(exponent_number) and absf(exponent_number) < 9.223372036854776e18
		and floor(exponent_number) == exponent_number)
