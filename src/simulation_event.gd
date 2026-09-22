class_name SimulationEvent
extends RefCounted

var type: String
var amount: ScientificNumber
var is_critical: bool = false

func _init(event_type: String, event_amount: ScientificNumber, critical: bool = false) -> void:
	type = event_type
	amount = event_amount
	is_critical = critical
