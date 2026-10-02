extends SceneTree
## Layout preview only. Sample jobs are illustrative, never saved or wired
## into navigation. Run through run_godot.sh; writes two screenshots then exits.
const Palette = preload("res://src/ui/palette.gd")
const NavBar = preload("res://src/ui/nav_bar.gd")


func _init() -> void:
	_preview.call_deferred()


func _preview() -> void:
	var screen := Control.new()
	screen.theme = Palette.make_theme()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(screen)
	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(ground)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	screen.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("LABS", 18, Palette.TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_label("DESIGN PREVIEW", 10, Palette.WARNING))
	column.add_child(_label("Sample research · values and slots are illustrative", 11, Palette.MUTED))
	column.add_child(Palette.hairline())
	column.add_child(_label("RESEARCH SLOTS", 11, Palette.SOFT))
	column.add_child(_job("LAB 1 · RESEARCHING", "Damage · level 3", "Current effect → next effect", "2h 18m remaining", 0.6))
	column.add_child(_job("LAB 2 · RESEARCHING", "Attack speed · level 2", "Current effect → next effect", "46m remaining", 0.85))
	var empty := _job("LAB 3 · IDLE", "Choose research", "A permanent upgrade for future runs", "Browse research below", 0.0)
	column.add_child(empty)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(space)
	var browse := Palette.pill("Browse research", Palette.ACCENT, null, 44)
	column.add_child(browse)
	column.add_child(_label("Layout study only · Labs is not playable yet", 11, Palette.MUTED))
	column.add_child(Palette.hairline())
	column.add_child(NavBar.new("labs", 3, 30))
	await process_frame
	await process_frame
	_capture("labs_layout")
	var overlay := PanelContainer.new()
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0, 0, 0, 0.8)
	overlay.add_theme_stylebox_override("panel", shade)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(overlay)
	var centre := CenterContainer.new()
	overlay.add_child(centre)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	panel.add_theme_stylebox_override("panel", Palette.panel_box())
	centre.add_child(panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	panel.add_child(list)
	list.add_child(_label("Choose research", 20, Palette.TEXT))
	list.add_child(_label("Sample catalogue · no purchases", 11, Palette.WARNING))
	for entry in [["MAIN RESEARCH", "Game speed"], ["ATTACK", "Damage"], ["DEFENSE", "Number regen"], ["UTILITY", "Cash bonus"]]:
		list.add_child(_label(entry[0], 11, Palette.ACCENT))
		list.add_child(Palette.hairline())
		list.add_child(_label("%s    Lv · effect → next\nTime to complete                 Coin cost" % entry[1], 12, Palette.SOFT))
	list.add_child(Palette.pill("Back to Labs", Palette.SOFT, null, 38))
	await process_frame
	await process_frame
	_capture("labs_catalogue_layout")
	screen.queue_free()
	await process_frame
	quit()


func _job(state: String, title: String, effect: String, time: String, share: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.panel_box())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	column.add_child(_label(state, 10, Palette.ACCENT if share > 0.0 else Palette.MUTED))
	column.add_child(_label(title, 17, Palette.TEXT))
	column.add_child(_label(effect, 12, Palette.SOFT))
	column.add_child(_label(time, 12, Palette.ACCENT if share > 0.0 else Palette.MUTED))
	var bar := Palette.progress_bar()
	Palette.fill_progress(bar, share, share > 0.0, Palette.ACCENT)
	column.add_child(bar)
	return panel


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label


func _capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("user://capture")
	var path := "user://capture/%s.png" % name
	root.get_texture().get_image().save_png(path)
	print("wrote ", ProjectSettings.globalize_path(path))
