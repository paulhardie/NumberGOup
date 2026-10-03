extends RefCounted
## What an upgrade row says about itself when it's held (D151): its name, what
## it does, its level, what it gives now and one level on, and the price.
## The Workshop (Coins, permanent levels) and a run (Cash, run levels) both
## show it, each handing over its own numbers, so the two read alike. It only
## lays the card out: the screens work the numbers out and `update` them as
## they change, since a run goes on beneath its card.

const Overlay = preload("res://src/ui/overlay.gd")
const Palette = preload("res://src/ui/palette.gd")
const TowerData = preload("res://src/tower/tower_data.gd")

## Row name → [its caption, its value], so a row with nothing to say can hide.
var _rows := {}
var _mono := Palette.weight(Palette.NUMBER_FONT, 400)


## Fills `sheet` for row `id`; `price_tone` is the currency's colour.
func _init(sheet: Overlay, id: String, price_tone: Color) -> void:
	sheet.heading(Palette.row_title(id), true)
	sheet.text(String(TowerData.upgrade(id).description))
	sheet.rule()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 6)
	sheet.column.add_child(grid)
	_add(grid, "level", "Level", Palette.TEXT)
	_add(grid, "now", "Now", Palette.TEXT)
	_add(grid, "next", "Next level", Palette.ACCENT)
	_add(grid, "price", "Price", price_tone)


## `level` of `top`, then the value now and at the next level and the price,
## each written as the screen writes it. An empty `next` or `price` hides its
## line, as a maxed row has neither.
func update(level: int, top: int, now: String, next: String, price: String) -> void:
	var maxed := level >= top
	_say("level", "%s / %s%s" % [Palette.full(level), Palette.full(top), "  ·  max" if maxed else ""])
	_say("now", now)
	_say("next", next, next != "")
	_say("price", price, price != "")


func _add(grid: GridContainer, key: String, caption: String, tone: Color) -> void:
	var name_label := Label.new()
	name_label.text = caption
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Palette.MUTED)
	grid.add_child(name_label)
	var value := Label.new()
	value.add_theme_font_override("font", _mono)
	value.add_theme_font_size_override("font_size", 13)
	value.add_theme_color_override("font_color", tone)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(value)
	_rows[key] = [name_label, value]


func _say(key: String, words: String, shown: bool = true) -> void:
	var row: Array = _rows[key]
	(row[0] as Label).visible = shown
	(row[1] as Label).visible = shown
	(row[1] as Label).text = words
