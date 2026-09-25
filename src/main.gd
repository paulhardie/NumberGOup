extends Control
## Number Go Up, rebuilt as The Tower first (docs/REBUILD_SPEC.md). For now the
## game is the battle alone; the Workshop and home screens join it later.

const BattleScreen = preload("res://src/ui/battle_screen.gd")


func _ready() -> void:
	add_child(BattleScreen.new())
