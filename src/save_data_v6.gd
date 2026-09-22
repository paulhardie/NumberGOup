class_name SaveDataV6
extends RefCounted

## V6 is V5 with every field added after V5 shipped made part of the schema,
## plus the two run fields a resumed run needs to replay identically (D006):
##   - the Rig's `rig_ranks`, the run's `run_peak_number` and
##     `second_wind_used`, Labs' `lab_ranks` and `lab_active`, and Cards'
##     `gems`, `card_ranks` and `card_active` are now declared V6 keys rather
##     than additions a V5 reader may not know;
##   - `tick_accumulator` and `critical_chain` join the active-run block: the
##     tick phase and the crit chain carry into the next outputs, so a run
##     resumed without them drifted from the run that was saved.
## A new saved field bumps the version from here on (D028), so a build that
## meets a save newer than it understands can refuse it instead of silently
## writing it back without the fields it does not know.
const VERSION := 6

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
		"gems": state.gems,
		"card_ranks": state.card_ranks,
		"card_active": state.card_active,
		"in_run": state.in_run,
		"run_coins_earned": state.run_coins_earned,
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
		"last_seen_unix": Time.get_unix_time_from_system(),
	}

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)

## Why a parsed save of any version cannot be loaded, or "" if it can. The
## loader assigns these blocks to typed fields, so a wrong type would stop the
## load halfway and leave a partial state for the next autosave to write over
## the player's progress. Checking first turns such a file away whole.
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
	for key in ["coins", "knowledge", "gems", "wave", "highest_wave", "selected_tier"]:
		if data.has(key) and not (data[key] is int or data[key] is float):
			return key + " is not a number"
	return ""
