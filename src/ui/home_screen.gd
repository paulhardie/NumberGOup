extends Control
## Between runs: the best wave, the Coins to spend, and the way into a battle
## or the Workshop.

const Workshop = preload("res://src/tower/workshop.gd")
const Palette = preload("res://src/ui/palette.gd")

signal battle_pressed
signal workshop_pressed

var workshop: Workshop
var _coins: Label
var _record: Label


func _ready() -> void:
	theme = Palette.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ground)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(280, 0)
	column.add_theme_constant_override("separation", 14)
	centre.add_child(column)
	var title := Label.new()
	title.text = "NUMBER GO UP"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_record = Label.new()
	_record.add_theme_color_override("font_color", Palette.MUTED)
	_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_record)
	_coins = Label.new()
	_coins.add_theme_font_override("font", Palette.NUMBER_FONT)
	_coins.add_theme_font_size_override("font_size", 22)
	_coins.add_theme_color_override("font_color", Palette.COIN)
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_coins)
	var battle := Button.new()
	battle.text = "Battle"
	battle.custom_minimum_size = Vector2(0, 56)
	battle.add_theme_font_size_override("font_size", 20)
	battle.pressed.connect(func(): battle_pressed.emit())
	column.add_child(battle)
	var shop := Button.new()
	shop.text = "Workshop"
	shop.custom_minimum_size = Vector2(0, 48)
	shop.pressed.connect(func(): workshop_pressed.emit())
	column.add_child(shop)
	refresh()


func refresh() -> void:
	_coins.text = "● " + Palette.number(workshop.coins)
	_record.text = "Best wave %d · %d runs" % [workshop.best_wave, workshop.runs] if workshop.runs > 0 else "Tier 1"
