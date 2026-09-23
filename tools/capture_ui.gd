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
	await _capture_state(window_size, label, "hub_played", false)
	await _capture_state(window_size, label, "milestones", false)
	await _capture_state(window_size, label, "run", false)
	await _capture_state(window_size, label, "run_standing", false)
	await _capture_state(window_size, label, "boss", false)
	await _capture_state(window_size, label, "workshop", false)
	await _capture_state(window_size, label, "knowledge", false)
	await _capture_state(window_size, label, "labs", false)
	await _capture_state(window_size, label, "cards", false)
	await _capture_state(window_size, label, "lost", false)
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
	if state_name == "run" or state_name == "run_standing" or state_name == "boss":
		state.tier_records["1"].highest_wave = GameState.TIER_UNLOCK_WAVE
		state.start_run(2, 99)
		state.number = ScientificNumber.from_float(238500)
		state.wave = 27
		state.wave_accumulator = 7.5
		state.run_coins_earned = 640
		state.active_encounter = state._make_encounter(27)
		if state_name == "boss":
			# Late in a boss wave, so the telegraph glow is live in the capture.
			state.wave = 30
			state.wave_accumulator = 14.0
			state.active_encounter = state._make_encounter(30)
			state.active_encounter.apply_compliance(state.active_encounter.max_liability.multiply_scalar(0.4))
		elif state_name == "run_standing":
			state.active_encounter.apply_compliance(state.active_encounter.max_liability.multiply_scalar(0.55))
		else:
			state.active_encounter.apply_compliance(ScientificNumber.from_float(55900))
	elif state_name == "hub_played" or state_name == "milestones":
		state.gems = 46
		state.tier_records["1"].highest_wave = 47
		state.tier_records["1"].milestones_claimed = [10, 20, 25, 30, 40]
		state.last_run_summary = RunSummary.new(
			47, 612, 0, ScientificNumber.from_float(48210), 1, "death",
			ScientificNumber.from_float(5230), false,
			ScientificNumber.from_float(3100), ScientificNumber.from_float(900)
		)
		if state_name == "milestones":
			main._open_milestones_sheet()
	elif state_name == "workshop":
		main._select_tab("workshop")
	elif state_name == "knowledge":
		main._open_knowledge_sheet()
	elif state_name == "labs":
		state.lab_ranks = {"lab_damage": 4, "lab_resilience": 1}
		state.lab_active["lab_coin_research"] = {"started_unix": Time.get_unix_time_from_system(), "duration": 240.0}
		main._open_lab_research_sheet()
	elif state_name == "cards":
		state.gems = 46
		state.card_ranks = {"card_damage": 3, "card_coins": 5, "card_health": 1}
		state.card_active.append("card_damage")
		state.card_active.append("card_coins")
		main._open_card_collection_sheet()
	elif state_name == "lost":
		main._show_died_screen(RunSummary.new(
			96, 4203, 2, ScientificNumber.from_float(142580), 1, "death",
			ScientificNumber.from_float(12300), true,
			ScientificNumber.from_float(8400), ScientificNumber.from_float(2100)
		))
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
