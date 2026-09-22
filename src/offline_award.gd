class_name OfflineAward
extends RefCounted

var amount: ScientificNumber = ScientificNumber.new()
var seconds: float = 0.0
var capped: bool = false

func _init(award_amount: ScientificNumber = ScientificNumber.new(), award_seconds: float = 0.0, was_capped: bool = false) -> void:
	amount = award_amount
	seconds = award_seconds
	capped = was_capped
