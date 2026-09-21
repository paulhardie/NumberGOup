class_name SaveDataV5
extends RefCounted

## V5 is V4 with the Workshop reorganised into four categories (D013, D017).
## Two keys change meaning and one disappears:
##   - `focus` holds a category id instead of a retired bay id;
##   - `workshop.selected_category` replaces `workshop.selected_bay`;
##   - `tax_resistance_rank` is gone, because Armor is now an ordinary Workshop
##     rank inside `purchased` under its stable id `tax_resistance`.
## Every other key keeps its V4 name and meaning, so a V4 reader's expectations
## about run state, RNG and records still hold.
const VERSION := 5

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
