extends RefCounted
## What's coming, shown now (D160), on the owner's word: "more placeholder content
## for what's coming next (missions, a better settings menu, etc. Use the tower
## as a reference)". Everything here is a stand-in: it reads no save, changes no
## rule and writes no setting, and each piece says when it is due or that it
## isn't scheduled. When a system is built, its stand-in is replaced by the
## real screen. The one real figure is the next tier's row, read from
## `TowerData`, because that is what Tier 2 will be.

const Palette = preload("res://src/ui/palette.gd")
const Overlay = preload("res://src/ui/overlay.gd")
const TowerData = preload("res://src/tower/tower_data.gd")

## For a stand-in whose system isn't on the roadmap (D079).
const LATER := "later"
## The roadmap version that brings tiers (D079).
const TIERS_VERSION := "1.4"
const TILE_HEIGHT := 64
## What the next tier asks (D138: the wave of the one before).
const NEXT_TIER_WAVE := 100

## Samples of the shape a mission could take, as The Tower's daily missions do.
## What they ask and pay is not decided, and nothing counts toward them.
const SAMPLE_DAILY := [
	{"goal": "Reach wave 20", "reward": "◆ 5"},
	{"goal": "Take your Number past 1,000", "reward": "● 50"},
	{"goal": "Buy 5 Workshop upgrades", "reward": "◆ 5"},
]
const SAMPLE_WEEKLY := [
	{"goal": "Finish 20 runs", "reward": "◆ 20"},
]


## A small capsule saying when something comes: a roadmap version, or "later".
static func tag(words: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := Palette.pill_box(Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.08), 8)
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Palette.MUTED)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel


## A settings group's name, small and spaced, as Home's wordmark is.
static func section(words: String) -> Label:
	var label := Label.new()
	label.text = words.to_upper()
	var font := Palette.weight(Palette.WORD_FONT, 500)
	font.spacing_glyph = 2
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Palette.MUTED)
	return label


## A line of small print under a setting.
static func hint(words: String) -> Label:
	var label := Label.new()
	label.text = words
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(Overlay.TEXT_WIDTH - 40, 0)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Palette.MUTED)
	return label


## A setting that isn't built: its name dimmed, what it would do, and when.
## Not a control, so nothing here can be turned on or change a file.
static func setting(name: String, what: String, when: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 1)
	row.add_child(words)
	var title := Label.new()
	title.text = name
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(Palette.TEXT, 0.5))
	words.add_child(title)
	words.add_child(hint(what))
	row.add_child(tag(when))
	return row


## A tile on Home's shelf: a small caption, what it holds, and when it comes.
## `bar` is a share of the way there, or negative for none.
static func tile(caption: String, headline: String, when: String, bar: float, on_press: Callable) -> Button:
	var button := Palette.card_button(TILE_HEIGHT)
	button.pressed.connect(on_press)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 12
	column.offset_right = -12
	column.offset_top = 8
	column.offset_bottom = -8
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	var label := Label.new()
	label.text = caption.to_upper()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Palette.MUTED)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(label)
	top.add_child(tag(when))
	var line := Label.new()
	line.text = headline
	line.name = "Headline"
	line.clip_text = true
	line.add_theme_font_size_override("font_size", 13)
	line.add_theme_color_override("font_color", Palette.TEXT)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(line)
	if bar >= 0.0:
		var progress := Palette.progress_bar()
		progress.name = "Progress"
		Palette.fill_progress(progress, bar, true, Palette.ACCENT)
		column.add_child(progress)
	return button


## Missions: samples of what a day's goals would look like.
static func missions_sheet() -> Overlay:
	var sheet := Overlay.new()
	sheet.heading("Missions", true)
	sheet.text("A few goals a day that pay Gems and Coins, as The Tower's do. These are samples of the shape: nothing counts toward them yet, and what they ask and pay isn't decided.", Palette.MUTED, 12)
	sheet.rule()
	sheet.column.add_child(section("Daily"))
	for mission in SAMPLE_DAILY:
		sheet.column.add_child(_mission(mission))
	sheet.column.add_child(section("Weekly"))
	for mission in SAMPLE_WEEKLY:
		sheet.column.add_child(_mission(mission))
	sheet.rule()
	sheet.text("Daily goals would reset at 00:00 UTC, as the free Gems do.", Palette.MUTED, 11)
	return sheet


static func _mission(mission: Dictionary) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	var row := HBoxContainer.new()
	column.add_child(row)
	var goal := Label.new()
	goal.text = String(mission.goal)
	goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal.custom_minimum_size = Vector2(170, 0)
	goal.add_theme_font_size_override("font_size", 13)
	goal.add_theme_color_override("font_color", Color(Palette.TEXT, 0.7))
	row.add_child(goal)
	var reward := Label.new()
	reward.text = String(mission.reward)
	reward.add_theme_font_size_override("font_size", 13)
	reward.add_theme_color_override("font_color", Palette.COIN if String(mission.reward).begins_with("●") else Palette.ACCENT)
	row.add_child(reward)
	var progress := Palette.progress_bar()
	Palette.fill_progress(progress, 0.0, false, Palette.ACCENT)
	column.add_child(progress)
	return column


## The next tier: its real row, and how far the player is from opening it.
static func tier_sheet(best_wave: int) -> Overlay:
	var next := TowerData.tier(2)
	var sheet := Overlay.new()
	sheet.heading("Tier 2", true)
	sheet.text("Opens when you reach wave %d of Tier 1. Your best is %d." % [NEXT_TIER_WAVE, best_wave], Palette.SOFT, 12)
	sheet.rule()
	sheet.text("Enemy health ×%s and attack ×%s.\nCoins ×%s." % [_plain(next.enemy_health), _plain(next.enemy_attack), _plain(next.coins)], Palette.TEXT, 13)
	sheet.text("Tiers come in %s. Until then Tier 1 is the whole game." % TIERS_VERSION, Palette.MUTED, 11)
	return sheet


## 20 as "20", 1.8 as "1.8".
static func _plain(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value)
