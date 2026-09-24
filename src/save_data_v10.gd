class_name SaveDataV10
extends RefCounted

const SaveDataV9Class = preload("res://src/save_data_v9.gd")

## V10 is V9 plus a wave's members (D057): the active encounter carries each
## member's HP, share, arrival time and state, and the run carries whether a
## Brace has already blocked a member of the current wave. A V9 build would
## load the wave back as one enemy and lose who had already landed, so it
## refuses a V10 save instead (D028). Every other key keeps its V9 name and
## meaning, and a V9 save loads through the same reader.
const VERSION := 10

static func make(state) -> Dictionary:
	var data: Dictionary = SaveDataV9Class.make(state)
	data.version = VERSION
	data.brace_spent = state.brace_spent
	return data

static func is_valid(data: Variant) -> bool:
	return (
		data is Dictionary
		and int(data.get("version", 0)) == VERSION
		and data.has("number")
		and data.has("lifetime")
	)

## Why a parsed save of any version cannot be loaded, or "" if it can.
static func problem(data: Dictionary) -> String:
	var older := SaveDataV9Class.problem(data)
	if older != "":
		return older
	var encounter: Variant = data.get("active_encounter", null)
	if encounter != null and not (encounter is Dictionary):
		return "active_encounter is not an object"
	if encounter is Dictionary and encounter.has("members") and not (encounter.members is Array):
		return "active_encounter members is not a list"
	return ""
