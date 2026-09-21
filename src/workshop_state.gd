class_name WorkshopState
extends RefCounted

var selected_bay := "output"
var tick_count := 0
var automation_targets: Array[String] = []
var legacy_credit := 0

func to_dict() -> Dictionary:
	return {
		"selected_bay": selected_bay,
		"tick_count": tick_count,
		"automation_targets": automation_targets,
		"legacy_credit": legacy_credit
	}

func from_dict(data: Dictionary) -> void:
	selected_bay = str(data.get("selected_bay", "output"))
	tick_count = int(data.get("tick_count", 0))
	legacy_credit = int(data.get("legacy_credit", 0))
	automation_targets.clear()
	for target in data.get("automation_targets", []):
		automation_targets.append(str(target))
