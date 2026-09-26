extends SceneTree
## Opens the battle in a real window, fast-forwards a seeded run to a few
## moments and saves a screenshot of each to user://capture, for looking at,
## never for pixel comparison. Nothing is saved: the game has no save yet.
## On headless Linux wrap it in xvfb-run -a -s "-screen 0 1024x1100x24".

const BattleScreen = preload("res://src/ui/battle_screen.gd")

const MOMENTS := [4.0, 12.0, 30.0, 45.0, 200.0]


func _init() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var screen: BattleScreen = main.get_child(0)
	screen.start_run(7)
	screen.set_process(false)
	var folder := "user://capture"
	DirAccess.make_dir_recursive_absolute(folder)
	for moment in MOMENTS:
		var events: Array[Dictionary] = []
		while screen.sim.time < moment and screen.sim.alive:
			screen.sim.step()
			events.append_array(screen.sim.events)
			screen.sim.events.clear()
		# The last second's events, so kills show their floating Cash.
		screen._arena.absorb(events.slice(maxi(0, events.size() - 6)), 0.0)
		screen._refresh()
		if not screen.sim.alive:
			screen._show_run_over()
		screen._arena.queue_redraw()
		await process_frame
		await process_frame
		var path := "%s/battle_%03ds.png" % [folder, int(moment)]
		root.get_texture().get_image().save_png(path)
		print("wrote ", ProjectSettings.globalize_path(path))
	quit()
