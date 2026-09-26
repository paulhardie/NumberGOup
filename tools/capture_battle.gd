extends SceneTree
## Opens the game's screens in a real window and saves screenshots to
## user://capture, for looking at, never for pixel comparison: the home screen
## and Workshop with some progress, then a seeded run fast-forwarded to a few
## moments, buying upgrades as it goes. Every screen gets its own Workshop,
## so nothing is saved. On headless Linux wrap it in
## xvfb-run -a -s "-screen 0 1024x1100x24".

const Workshop = preload("res://src/tower/workshop.gd")
const HomeScreen = preload("res://src/ui/home_screen.gd")
const WorkshopScreen = preload("res://src/ui/workshop_screen.gd")
const BattleScreen = preload("res://src/ui/battle_screen.gd")

const MOMENTS := [4.0, 30.0, 120.0, 240.0, 600.0]
const FOLDER := "user://capture"


func _init() -> void:
	_capture.call_deferred()


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var progress := Workshop.new()
	progress.coins = 180.0
	progress.best_wave = 9
	progress.runs = 3
	progress.levels = {"damage": 3, "health": 2}
	progress.open_groups.append("cash")

	var home := HomeScreen.new()
	home.workshop = progress
	await _shoot(home, "home")
	var shop := WorkshopScreen.new()
	shop.workshop = progress
	await _shoot(shop, "workshop_attack")
	shop = WorkshopScreen.new()
	shop.workshop = progress
	shop.ready.connect(func(): shop.show_tab("utility"))
	await _shoot(shop, "workshop_utility")

	shop = WorkshopScreen.new()
	shop.workshop = progress
	shop.ready.connect(func():
		shop.show_tab("defense")
		shop._next_amount())
	await _shoot(shop, "workshop_defense_x5")

	# A strong tower, to show the later groups: orbs, Rapid Fire, bounces,
	# the wall, land mines and a shockwave.
	var strong := Workshop.new()
	strong.open_groups.append_array(["range", "multishot", "rapid_fire", "bounce_shot", "defense", "thorns", "lifesteal", "knockback", "orbs",
		"shockwave", "land_mines", "wall", "recovery_packages"])
	strong.levels = {"damage": 60, "attack_speed": 30, "health": 60, "orbs": 4, "orb_speed": 20, "rapid_fire_chance": 40,
		"rapid_fire_duration": 40, "multishot_chance": 60, "bounce_shot_chance": 60, "knockback_chance": 40,
		"land_mine_chance": 30, "wall_health": 400}
	var showcase := BattleScreen.new()
	showcase.workshop = strong
	root.add_child(showcase)
	await process_frame
	showcase.start_run(3)
	showcase.set_process(false)
	var shown: Array[Dictionary] = []
	while showcase.sim.alive and (showcase.sim.time < 420.0 or not shown.any(func(event): return event.type == "shockwave")):
		if showcase.sim.time < 420.0:
			shown.clear()
		showcase.sim.step()
		shown.append_array(showcase.sim.events)
		showcase.sim.events.clear()
	showcase._arena.absorb(shown.slice(maxi(0, shown.size() - 10)), 0.0)
	# Part way through the shockwave's ring.
	showcase._arena.absorb([], 0.15)
	showcase._refresh()
	showcase._arena.queue_redraw()
	await _frames()
	_save_png("battle_strong")
	showcase.queue_free()
	await process_frame

	# The moment a Divider reaches the Number (D082).
	var divided := BattleScreen.new()
	var middling := Workshop.new()
	middling.levels = {"damage": 25, "attack_speed": 10, "health": 80, "health_regen": 40}
	divided.workshop = middling
	root.add_child(divided)
	await process_frame
	divided.start_run(11)
	divided.set_process(false)
	var landed := false
	var walking_shot := false
	while divided.sim.alive and not landed and divided.sim.time < 3600.0:
		# One frame of a Divider on its way in, before any has landed: inside
		# the range, so its preview shows above the Number (D085).
		if not walking_shot and divided.sim.enemies.any(func(enemy): return enemy.kind == "divider" and enemy.distance < divided.sim.stat("range") * 0.7):
			walking_shot = true
			divided._refresh()
			divided._arena.queue_redraw()
			await _frames()
			_save_png("battle_divider_walking")
		divided.sim.step()
		landed = divided.sim.events.any(func(event): return event.type == "divided" and not event.at_wall)
		if landed:
			divided._arena.absorb(divided.sim.events, 0.0)
		divided.sim.events.clear()
	divided._arena.absorb([], 0.08)
	divided._refresh()
	divided._arena.queue_redraw()
	await _frames()
	_save_png("battle_divided")
	divided.queue_free()
	await process_frame

	# A crowd with the wave-10 boss in it, to see every enemy type's number
	# side by side (D085).
	var crowd := BattleScreen.new()
	crowd.workshop = middling
	root.add_child(crowd)
	await process_frame
	crowd.start_run(11)
	crowd.set_process(false)
	var crowd_events: Array[Dictionary] = []
	# The first boss once it is well inside the view.
	while crowd.sim.alive and crowd.sim.time < 3600.0 and not crowd.sim.enemies.any(
			func(enemy): return enemy.kind == "boss" and enemy.distance < crowd.sim.stat("range") * 0.8):
		crowd.sim.step()
		crowd_events.append_array(crowd.sim.events)
		crowd.sim.events.clear()
	crowd._arena.absorb(crowd_events.slice(maxi(0, crowd_events.size() - 6)), 0.0)
	crowd._refresh()
	crowd._arena.queue_redraw()
	await _frames()
	_save_png("battle_crowd")
	crowd.queue_free()
	await process_frame

	var screen := BattleScreen.new()
	screen.workshop = Workshop.new()
	root.add_child(screen)
	await process_frame
	screen.start_run(7)
	screen.set_process(false)
	for moment in MOMENTS:
		var events: Array[Dictionary] = []
		while screen.sim.time < moment and screen.sim.alive:
			_buy_evenly(screen.sim)
			screen.sim.step()
			events.append_array(screen.sim.events)
			screen.sim.events.clear()
		# The last few events, so kills show their floating Cash.
		screen._arena.absorb(events.slice(maxi(0, events.size() - 6)), 0.0)
		screen._bank_coins()
		screen._refresh()
		if not screen.sim.alive:
			screen.workshop.finish_run(screen.sim.wave, screen.sim.peak_number)
			screen._show_run_over()
		screen._arena.queue_redraw()
		await _frames()
		_save_png("battle_%03ds" % int(moment))
	quit()


func _shoot(screen: Control, name: String) -> void:
	root.add_child(screen)
	await _frames()
	_save_png(name)
	screen.queue_free()
	await process_frame


func _frames() -> void:
	await process_frame
	await process_frame


func _save_png(name: String) -> void:
	var path := "%s/%s.png" % [FOLDER, name]
	root.get_texture().get_image().save_png(path)
	print("wrote ", ProjectSettings.globalize_path(path))


## Buys whichever open row has the fewest levels, when it can afford it.
func _buy_evenly(sim) -> void:
	var fewest := ""
	for id in ["damage", "attack_speed", "critical_chance", "critical_factor", "health", "health_regen"]:
		if fewest == "" or int(sim.run_levels.get(id, 0)) < int(sim.run_levels.get(fewest, 0)):
			fewest = id
	sim.buy(fewest)
