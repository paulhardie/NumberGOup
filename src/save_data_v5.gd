class_name SaveDataV5
extends RefCounted

const VERSION := 5

static func make(state) -> Dictionary:
	return {
		"version": VERSION,
		"economy_model": "workshop-categories-v2",
		"number": state.number.to_dict(),
		"lifetime": state.lifetime_generated.to_dict(),
		"highest": state.highest_number.to_dict(),
		"purchased": state.purchased,
		"knowledge": state.knowledge,
		"knowledge_purchased": state.knowledge_purchased,
		"focus_category": state.focus_category,
		"automation_enabled": state.automation_enabled,
		"workshop": state.workshop.to_dict(),
		"wave": state.wave,
		"wave_accumulator": state.wave_accumulator,
		"coins": state.coins,
		"highest_wave": state.highest_wave,
		"defense_unlocked": state.defense_unlocked,
		"braced": state.braced,
		"in_run": state.in_run,
		"run_coins_earned": state.run_coins_earned,
		"run_elapsed": state.run_elapsed,
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
	if not (data is Dictionary) or int(data.get("version", 0)) != VERSION:
		return false
	for key in ["number", "lifetime", "highest", "purchased", "knowledge_purchased", "workshop", "tier_records", "statistics", "settings"]:
		if not data.has(key) or not (data.get(key) is Dictionary):
			return false
	if not data.has("active_rule_modifiers") or not (data.get("active_rule_modifiers") is Array):
		return false
	var encounter: Variant = data.get("active_encounter", null)
	return encounter == null or encounter is Dictionary
