extends SceneTree
## Opens the game's screens in a real window and saves screenshots to
## user://capture, for looking at, never for pixel comparison: the home screen
## and Workshop with some progress, then a seeded run fast-forwarded to a few
## moments, buying upgrades as it goes, and Tier 2's later enemies with Wave
## Info open. Every screen gets its own Workshop,
## so nothing is saved. On headless Linux wrap it in
## xvfb-run -a -s "-screen 0 1024x1100x24".

const Workshop = preload("res://src/tower/workshop.gd")
const HomeScreen = preload("res://src/ui/home_screen.gd")
const WorkshopScreen = preload("res://src/ui/workshop_screen.gd")
const BattleScreen = preload("res://src/ui/battle_screen.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Progression = preload("res://src/tower/progression.gd")
const CardsScreen = preload("res://src/ui/cards_screen.gd")
const Cards = preload("res://src/tower/cards.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const RunConfig = preload("res://src/tower/run_config.gd")

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
	# A peak below what a run earned, as a spender's is: the emblem shows the
	# peak, the milestone sheet the Number earned (D164).
	progress.best_number = 180.0
	progress.best_earned = 1500.0
	progress.levels = {"damage": 3, "health": 2}
	progress.open_groups.append("cash")

	var home := HomeScreen.new()
	home.workshop = progress
	home.progression = Progression.new(progress)
	await _shoot(home, "home")
	var earned := Progression.new(progress)
	earned.observe(1, 50, 49)
	home = HomeScreen.new()
	home.workshop = progress
	home.progression = earned
	home.ready.connect(home._open_milestones)
	await _shoot(home, "home_wave_milestones")
	earned.claim_daily()
	home = HomeScreen.new()
	home.workshop = progress
	home.progression = earned
	await _shoot(home, "home_daily_claimed")
	home = HomeScreen.new()
	home.workshop = progress
	home.progression = earned
	home.ready.connect(home._open_settings)
	await _shoot(home, "home_settings")
	home = HomeScreen.new()
	home.workshop = progress
	home.progression = earned
	home.ready.connect(home._open_settings)
	await _shoot(home, "home_settings_bottom", true)
	home = HomeScreen.new()
	home.workshop = progress
	home.progression = earned
	home.ready.connect(home._open_missions)
	await _shoot(home, "home_missions")
	home = HomeScreen.new()
	home.workshop = progress
	home.progression = earned
	home.ready.connect(home._open_next_tier)
	await _shoot(home, "home_next_tier")
	home = HomeScreen.new()
	home.workshop = progress
	home.progression = earned
	home.show_gift(57.0)
	await _shoot(home, "home_welcome")
	var shop := WorkshopScreen.new()
	shop.workshop = progress
	await _shoot(shop, "workshop_attack")
	shop = WorkshopScreen.new()
	shop.workshop = progress
	shop.ready.connect(func(): shop.show_upgrade("damage"))
	await _shoot(shop, "workshop_row_held")
	shop = WorkshopScreen.new()
	shop.workshop = progress
	shop.ready.connect(func(): shop.show_group(shop.workshop.next_group("attack"), "Unlocks"))
	await _shoot(shop, "workshop_unlock_held")
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

	# Cards (D146): a few found and two equipped, then a draw's card, then a
# card's details from the grid (D147).
	var collected := Progression.new(progress)
	collected.observe(1, 25, 24)
	collected.gems = 140
	collected.cards.copies = {"damage": 4, "attack_speed": 1, "health": 9, "cash": 2, "free_upgrades": 1}
	collected.cards.slots = 2
	collected.cards.equipped.assign(["damage", "health"])
	var cards := CardsScreen.new()
	cards.workshop = progress
	cards.progression = collected
	await _shoot(cards, "cards")
	cards = CardsScreen.new()
	cards.workshop = progress
	cards.progression = collected
	cards.ready.connect(func():
		cards.rng.seed = 5
		cards.draw())
	await _shoot(cards, "cards_drawn")
	cards = CardsScreen.new()
	cards.workshop = progress
	cards.progression = collected
	cards.ready.connect(func(): cards.show_card("damage"))
	await _shoot(cards, "cards_card")
	for art_id in ["health", "cash"]:
		cards = CardsScreen.new()
		cards.workshop = progress
		cards.progression = collected
		cards.ready.connect(cards.show_card.bind(art_id))
		await _shoot(cards, "cards_card_" + art_id)

	# One maxed card beside ordinary cards, both equipped and unequipped.
	var gilded := Progression.new(progress)
	gilded.observe(1, 25, 24)
	gilded.gems = 140
	gilded.cards.copies = collected.cards.copies.duplicate()
	gilded.cards.copies["damage"] = int(Cards.data().copies_to_level[-1])
	gilded.cards.slots = 2
	gilded.cards.equipped.assign(["damage", "health"])
	cards = CardsScreen.new()
	cards.workshop = progress
	cards.progression = gilded
	await _shoot(cards, "cards_gold")
	gilded.cards.unequip("damage")
	cards = CardsScreen.new()
	cards.workshop = progress
	cards.progression = gilded
	await _shoot(cards, "cards_gold_unequipped")

	# Layout boundaries: a newly opened Cards screen, an unused bought slot,
	# and a fully collected loadout whose inventory needs scrolling.
	var fresh_cards := Progression.new()
	fresh_cards.observe(1, 20, 19)
	cards = CardsScreen.new()
	cards.workshop = fresh_cards.workshop
	cards.progression = fresh_cards
	await _shoot(cards, "cards_empty")
	collected.cards.slots = 3
	cards = CardsScreen.new()
	cards.workshop = progress
	cards.progression = collected
	await _shoot(cards, "cards_empty_slot")
	var complete := Progression.new()
	complete.observe(1, 30, 29)
	complete.gems = 0
	complete.cards.slots = Cards.built_ids().size()
	for id in Cards.built_ids():
		complete.cards.copies[id] = int(Cards.data().copies_to_level[-1])
	complete.cards.equipped.assign(Cards.built_ids())
	cards = CardsScreen.new()
	cards.workshop = complete.workshop
	cards.progression = complete
	await _shoot(cards, "cards_maxed")
	cards = CardsScreen.new()
	cards.workshop = complete.workshop
	cards.progression = complete
	await _shoot(cards, "cards_maxed_inventory", true)
	var open_shop := Workshop.new()
	open_shop.coins = 1e12
	for group in TowerData.groups():
		if not open_shop.is_group_open(String(group.id)):
			open_shop.open_groups.append(String(group.id))
	for id in TowerData.rows():
		open_shop.levels[id] = TowerData.max_level(id)
	shop = WorkshopScreen.new()
	shop.workshop = open_shop
	await _shoot(shop, "workshop_maxed")
	shop = WorkshopScreen.new()
	shop.workshop = open_shop
	await _shoot(shop, "workshop_maxed_bottom", true)
	for tab in ["defense", "utility"]:
		shop = WorkshopScreen.new()
		shop.workshop = open_shop
		shop.ready.connect(shop.show_tab.bind(tab))
		await _shoot(shop, "workshop_maxed_" + tab)
		shop = WorkshopScreen.new()
		shop.workshop = open_shop
		shop.ready.connect(shop.show_tab.bind(tab))
		await _shoot(shop, "workshop_maxed_" + tab + "_bottom", true)

	# A strong tower, to show the later groups: orbs, Rapid Fire, bounces,
	# the wall, land mines and a shockwave.
	var strong := Workshop.new()
	strong.open_groups.append_array(["range", "multishot", "rapid_fire", "bounce_shot", "defense", "thorns", "lifesteal", "knockback", "orbs",
		"shockwave", "land_mines", "wall", "recovery_packages"])
	strong.levels = {"damage": 60, "attack_speed": 30, "health": 60, "orbs": 4, "orb_speed": 20, "rapid_fire_chance": 40,
		"rapid_fire_duration": 40, "multishot_chance": 60, "bounce_shot_chance": 60, "knockback_chance": 40,
		"land_mine_chance": 30, "wall_health": 400}
	var showcase := BattleScreen.new()
	showcase.tuning = RunConfig.game_tuning()
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
	# The Wall falling (D106): its brackets tipping away, part way down.
	showcase.sim.defences.wall_health = 0.0
	showcase.sim.defences.wall_rebuild_in = showcase.sim.stat("wall_rebuild")
	showcase._arena.absorb([{"type": "wall_down"}], 0.0)
	showcase._arena.absorb([], showcase._arena.WALL_FALL_SECONDS * 0.35)
	showcase._arena.queue_redraw()
	await _frames()
	_save_png("battle_wall_down")
	showcase.queue_free()
	await process_frame

	# The moment a Divider reaches the Number (D082).
	var divided := BattleScreen.new()
	divided.tuning = RunConfig.game_tuning()
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

	# Full Range (D101): the view zooms out so the range stays on screen.
	var far := BattleScreen.new()
	far.tuning = RunConfig.game_tuning()
	var reaching := Workshop.new()
	reaching.open_groups.append("range")
	reaching.levels = {"damage": 25, "attack_speed": 10, "health": 20, "health_regen": 10, "range": 79}
	far.workshop = reaching
	root.add_child(far)
	await process_frame
	far.start_run(7)
	far.set_process(false)
	while far.sim.time < 150.0:
		far.sim.step()
		far.sim.events.clear()
	for _i in range(40):
		far._arena.absorb([], 0.05)
	far._refresh()
	far._arena.queue_redraw()
	await _frames()
	_save_png("battle_full_range")
	far.queue_free()
	await process_frame

	# The moment the Number reaches a new digit (D099), a moment after it lands.
	var digits := BattleScreen.new()
	digits.tuning = RunConfig.game_tuning()
	var climbing := Workshop.new()
	climbing.levels = {"damage": 25, "attack_speed": 10, "health": 20, "health_regen": 30}
	digits.workshop = climbing
	root.add_child(digits)
	await process_frame
	digits.start_run(5)
	digits.set_process(false)
	var reached := [false]
	digits._arena.digit_reached.connect(func(_power: int): reached[0] = true)
	digits._arena.absorb([], 0.0)
	while digits.sim.alive and not reached[0] and digits.sim.time < 3600.0:
		digits.sim.step()
		digits.sim.events.clear()
		digits._arena.absorb([], 0.0)
	digits._arena.absorb([], 0.15)
	digits._refresh()
	digits._arena.queue_redraw()
	await _frames()
	_save_png("battle_new_digit")
	digits.queue_free()
	await process_frame

	# A kill growing the Number (D111): its sparks, its Cash, and the "+" by
	# the Number, a moment after a kill that grew it by at least 1.
	var grown := BattleScreen.new()
	grown.tuning = RunConfig.game_tuning()
	grown.workshop = middling
	root.add_child(grown)
	await process_frame
	grown.start_run(11)
	grown.set_process(false)
	var grew := false
	while grown.sim.alive and not grew and grown.sim.time < 3600.0:
		grown.sim.step()
		grew = grown.sim.events.any(func(event): return event.type == "grown" and float(event.gain) >= 1.0)
		if grew:
			grown._arena.absorb(grown.sim.events, 0.0)
		grown.sim.events.clear()
	grown._arena.absorb([], 0.1)
	grown._refresh()
	grown._arena.queue_redraw()
	await _frames()
	_save_png("battle_kill_grows")
	grown.queue_free()
	await process_frame

	# A crowd with the wave-10 boss in it, to see every enemy type's number
	# side by side (D085).
	var crowd := BattleScreen.new()
	crowd.tuning = RunConfig.game_tuning()
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

	# The Tower's later enemies (D115): Tier 2 deep in, a Protector's shield
	# and elites on the field, then Wave Info open over them. The Number is
	# held up, since only the look matters here.
	var invaded := BattleScreen.new()
	invaded.tuning = RunConfig.game_tuning()
	invaded.workshop = strong
	root.add_child(invaded)
	await process_frame
	invaded._adopt(BattleSim.new(5, strong.levels, strong.open_groups, 2))
	invaded.set_process(false)
	var deep: BattleSim = invaded.sim
	deep.wave = 600
	deep.health_level = 600
	deep.attack_level = 600
	# Each where it can be seen: a Protector with basics in its shield, a
	# Vampire draining and a Ray charging on the range's edge, a Scatter and
	# two of its pieces walking in.
	var staged := [["protector", -0.6, 48.0], ["basic", -0.52, 44.0], ["basic", -0.68, 51.0], ["basic", -0.6, 55.0],
		["vampire", 2.3, 0.0], ["ray", 0.9, 0.0], ["scatter", 3.9, 45.0], ["scatter", 3.6, 38.0], ["scatter", 3.75, 36.0], ["fast", 1.7, 60.0]]
	deep.spawns.schedule.assign(staged.map(func(entry): return {"kind": entry[0], "at": 0.0}))
	deep.spawns.next_spawn = 0
	deep.wave_clock = 0.0
	deep.step()
	for index in range(staged.size()):
		var enemy: BattleSim.Enemy = deep.enemies[index]
		enemy.angle = staged[index][1]
		enemy.distance = staged[index][2] if staged[index][2] > 0.0 else deep.stat("range")
		enemy.speed = 0.0 if staged[index][2] > 0.0 else enemy.speed
		if index == 7 or index == 8:
			enemy.generation = 1
			enemy.max_health *= 0.5
	var invaded_events: Array[Dictionary] = []
	for tick in range(40):
		deep.health = 1e30
		deep.step()
		invaded_events.append_array(deep.events)
		deep.events.clear()
	invaded._arena.absorb(invaded_events.slice(maxi(0, invaded_events.size() - 6)), 0.0)
	invaded._refresh()
	invaded._arena.queue_redraw()
	await _frames()
	_save_png("battle_invaders")
	invaded._wave_info.show_over(invaded)
	invaded._refresh()
	await _frames()
	_save_png("battle_wave_info")
	invaded.queue_free()
	await process_frame

	# The Lock (D133) on Tier 1's wave 40, holding the Number from the range's
	# edge in a crowd walking in, with the card a player sees the first time.
	var held := BattleScreen.new()
	held.tuning = RunConfig.game_tuning()
	held.workshop = middling
	root.add_child(held)
	await process_frame
	held._adopt(BattleSim.new(7, middling.levels, middling.open_groups))
	held.set_process(false)
	var locked: BattleSim = held.sim
	locked.wave = 40
	locked.health_level = 40
	locked.attack_level = 40
	var walking := [["lock", 0.4, 0.0], ["basic", 0.5, 40.0], ["basic", 0.3, 47.0], ["fast", 0.45, 52.0], ["basic", 2.2, 30.0],
		["ranged", 2.6, 0.0], ["tank", 3.4, 44.0], ["divider", 4.4, 38.0], ["basic", 5.2, 34.0], ["basic", 5.3, 39.0]]
	locked.spawns.schedule.assign(walking.map(func(entry): return {"kind": entry[0], "at": 0.0}))
	locked.spawns.next_spawn = 0
	locked.wave_clock = 0.0
	locked.step()
	for index in range(walking.size()):
		var enemy: BattleSim.Enemy = locked.enemies[index]
		enemy.angle = walking[index][1]
		enemy.distance = walking[index][2] if walking[index][2] > 0.0 else locked.stat("range")
		enemy.speed = 0.0
	locked.health = locked.max_health() * 3.0
	for tick in range(10):
		locked.step()
	var best_before := middling.best_wave
	middling.best_wave = 30
	held._first_sight(0.0)
	middling.best_wave = best_before
	held._refresh()
	held._arena.queue_redraw()
	await _frames()
	_save_png("battle_lock")
	held._first_sight(BattleScreen.FIRST_SIGHT_SECONDS + 0.1)
	held._show_held("damage")
	held._refresh()
	await _frames()
	_save_png("battle_upgrade_held")
	held.queue_free()
	await process_frame

	# The five base enemies as ours (D145): a fast one trailing its number, a
	# fresh tank and a worn one thinned, and the boss as a rival Number, with
	# the wave line naming it.
	var base := BattleScreen.new()
	base.tuning = RunConfig.game_tuning()
	base.workshop = middling
	root.add_child(base)
	await process_frame
	base._adopt(BattleSim.new(7, middling.levels, middling.open_groups))
	base.set_process(false)
	var lineup: BattleSim = base.sim
	lineup.wave = 10
	# Kind, angle, share of the range out, share of health left.
	var placed := [["basic", 0.3, 0.8, 1.0], ["fast", 1.2, 0.75, 1.0], ["tank", 2.2, 0.7, 1.0], ["tank", 3.0, 0.8, 0.25],
		["boss", 4.2, 0.85, 1.0], ["divider", 5.3, 0.75, 1.0]]
	lineup.spawns.schedule.assign(placed.map(func(entry): return {"kind": entry[0], "at": 0.0}))
	lineup.spawns.next_spawn = 0
	lineup.wave_clock = 0.0
	lineup.step()
	for index in range(placed.size()):
		var enemy: BattleSim.Enemy = lineup.enemies[index]
		enemy.angle = placed[index][1]
		enemy.distance = placed[index][2] * lineup.stat("range")
		enemy.last_distance = enemy.distance
		enemy.health = enemy.max_health * placed[index][3]
	base._refresh()
	base._arena.queue_redraw()
	await _frames()
	_save_png("battle_base_enemies")
	base.queue_free()
	await process_frame

	var screen := BattleScreen.new()
	screen.tuning = RunConfig.game_tuning()
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
			screen.workshop.finish_run(screen.sim.wave, screen.sim.peak_number, screen.sim.cash_earned)
			screen._show_run_over()
		screen._arena.queue_redraw()
		await _frames()
		_save_png("battle_%03ds" % int(moment))
	quit()


func _shoot(screen: Control, name: String, scroll_bottom: bool = false) -> void:
	root.add_child(screen)
	await _frames()
	if scroll_bottom:
		var scroll := screen.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
		scroll.scroll_vertical = 100000
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
