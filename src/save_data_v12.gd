class_name SaveDataV12
extends RefCounted

const SaveDataV11Class = preload("res://src/save_data_v11.gd")

## V12 is V11 with The Tower's Workshop (D068). `purchased` now holds levels of
## The Tower's rows, `rig_ranks` a run's levels of them, and Coins are on The
## Tower's scale, about fifteen times the old one. The save adds
## `workshop_groups`, the Workshop unlocks bought with Coins, and the run's
## `rapid_fire_left`. Second Wind and the crit chain are retired, so their keys
## are no longer written. A V11 build would read the new rows' levels as
## unknown ids and the new Coin balance on the old scale, so it refuses a V12
## save instead (D028). An older save loads through the same reader and is
## converted once: its Coins scaled, and every rank of a retired row refunded
## at the Coins it cost, scaled the same way.
const VERSION := 12

static func make(state) -> Dictionary:
	var data: Dictionary = SaveDataV11Class.make(state)
	data.version = VERSION
	data.workshop_groups = state.workshop_groups.duplicate()
	data.rapid_fire_left = state.rapid_fire_left
	data.erase("second_wind_used")
	data.erase("critical_chain")
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
	var older := SaveDataV11Class.problem(data)
	if older != "":
		return older
	if data.has("workshop_groups") and not (data.workshop_groups is Array):
		return "workshop_groups is not a list"
	return ""
