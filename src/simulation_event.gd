class_name SimulationEvent
extends RefCounted

var type: String
var amount: ScientificNumber
var is_critical: bool = false
## Shots this event fired: 2 when Multishot doubled a tick, so the arena can
## show both.
var hits := 1

func _init(event_type: String, event_amount: ScientificNumber, critical: bool = false) -> void:
	type = event_type
	amount = event_amount
	is_critical = critical
