class_name WorkshopState
extends RefCounted

var selected_category := ProgressionTaxonomy.ATTACK
var tick_count := 0
var automation_targets: Array[String] = []
var legacy_credit := 0

func to_dict() -> Dictionary:
	return {
		"selected_category": selected_category,
		"tick_count": tick_count,
		"automation_targets": automation_targets,
		"legacy_credit": legacy_credit
	}

func from_dict(data: Dictionary) -> void:
	# Pre-V5 saves stored a bay here; category_for_legacy_bay maps it and passes
	# a category through unchanged.
	var stored := str(data.get("selected_category", data.get("selected_bay", ProgressionTaxonomy.ATTACK)))
	selected_category = ProgressionTaxonomy.category_for_legacy_bay(stored)
	if selected_category == "":
		selected_category = ProgressionTaxonomy.ATTACK
	tick_count = int(data.get("tick_count", 0))
	legacy_credit = int(data.get("legacy_credit", 0))
	automation_targets.clear()
	for target in data.get("automation_targets", []):
		automation_targets.append(str(target))
