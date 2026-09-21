extends SceneTree

## Temporary visual-evidence harness: builds the real main scene at several
## window sizes and saves PNGs to user://ui_capture. Run windowed:
##   Godot --path . -s res://tools/capture_ui.gd

const SIZES := [
	[320, 568, "small"],
	[390, 844, "tall"],
	[768, 1024, "tablet"],
	[540, 960, "base"],
]
const OUT_DIR := "user://ui_capture"
const IGNORE_SAVE := "user://capture_ignore_save.json"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame
	for entry in SIZES:
		await _capture_size(Vector2i(entry[0], entry[1]), str(entry[2]))
	print("CAPTURED ", ProjectSettings.globalize_path(OUT_DIR))
	quit()

func _capture_size(window_size: Vector2i, label: String) -> void:
	root.size = window_size
	await process_frame
	await process_frame
	await _capture_state(window_size, label, "hub", false)
	await _capture_state(window_size, label, "run", false)
	await _capture_state(window_size, label, "run_standing", false)
	await _capture_state(window_size, label, "workshop", false)
	await _capture_state(window_size, label, "labs", false)
	await _capture_state(window_size, label, "cards", false)
	await _capture_state(window_size, label, "drawer", true)

func _capture_state(window_size: Vector2i, label: String, state_name: String, open_drawer: bool) -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.state.save_path = IGNORE_SAVE
	root.add_child(main)
	await process_frame
	var state = main.state
	state.highest_number = ScientificNumber.from_float(250000)
	state.lifetime_generated = ScientificNumber.from_float(250000)
	state.coins = 1240
	state.knowledge = 14
	state.purchased = {
		"stronger_tap": 5,
		"generator": 4,
		"generator_two": 3,
		"faster_cadence": 3,
		"faster_echo": 1,
		"more_critical": 2,
	}
	state.settings["reduce_motion"] = true
	if state_name == "run" or state_name == "run_standing":
		state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
		state.start_run(2, 99)
		state.number = ScientificNumber.from_float(238500)
		state.wave = 27
		state.wave_accumulator = 7.5
		state.run_coins_earned = 640
		state.active_encounter = state._make_encounter(27)
		if state_name == "run_standing":
			state.active_encounter.apply_compliance(state.active_encounter.max_liability.multiply_scalar(0.55))
		else:
			state.active_encounter.apply_compliance(ScientificNumber.from_float(55900))
	elif state_name == "workshop":
		main._select_tab("workshop")
	elif state_name == "labs":
		main._select_tab("labs")
	elif state_name == "cards":
		main._select_tab("cards")
	if open_drawer:
		main._toggle_drawer()
	main._refresh_all()
	await process_frame
	await process_frame
	main._refresh_all()
	# Let the tab slide/fade finish so captures show the resting state.
	await create_timer(0.4).timeout
	_save_frame(window_size, label, state_name)
	main.queue_free()
	await process_frame

func _save_frame(window_size: Vector2i, label: String, state_name: String) -> void:
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(OUT_DIR).path_join(
		"%s_%dx%d_%s.png" % [label, window_size.x, window_size.y, state_name]
	)
	image.save_png(path)
