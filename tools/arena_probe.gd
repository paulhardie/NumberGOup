extends SceneTree
## Plays the run arena through its beats in a real window and checks them:
## the group walking in (D057), motes and pops (D051, D054, D055), a beaten
## front member, clears, boss slams and latching, the Hit's working (D052),
## Second Wind, the pile at the Number and a boss behind it (D058), and
## Reduce Motion. Saves to a throwaway file and writes screenshots to
## user://arena_probe (the scratch HOME that run_godot.sh sets).
## Run: bash run_godot.sh --path . -s res://tools/arena_probe.gd
## (headless Linux: xvfb-run -a -s "-screen 0 1024x1100x24" bash run_godot.sh ...)
## A check tool, not a gate: it drives real frames, so a slow machine can
## shift a timing check.
const OUT := "user://arena_probe"
var fails := 0
func _check(ok: bool, msg: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", msg)
func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT) + "/" + name + ".png")
func _ghosts(main, kind: int) -> int:
	var count := 0
	for child in main.stage_root.get_children():
		if child is WaveEnemy and child != main.wave_enemy and child.beat == kind and not child.is_queued_for_deletion():
			count += 1
	return count
func _beat(st) -> void:
	while not st.active_encounter.is_cleared():
		st.active_encounter.apply_compliance(st.active_encounter.members[st.active_encounter.front_index()].hp)
func _followers(main) -> int:
	return main.enemy_followers.filter(func(node): return node.visible).size()
func rescue_parts_empty(parts: Dictionary) -> bool:
	return parts.is_empty() or parts.final.is_zero()

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await process_frame
	root.size = Vector2i(390, 844)
	var main = load("res://scenes/main.tscn").instantiate()
	main.state.save_path = "user://enemy_probe_save.json"
	root.add_child(main)
	await process_frame
	var st = main.state
	st.highest_number = ScientificNumber.from_float(250000)
	st.settings["reduce_motion"] = false
	st.start_run(1, 3)
	st.number = ScientificNumber.from_float(5000)
	main._refresh_all()
	await _frames(3)
	_check(main.wave_enemy.visible, "a standing wave shows its body")
	var path: Array = main._enemy_path()
	var start_gap: float = (main.wave_enemy.position + main.wave_enemy.size / 2.0).distance_to(path[1])
	st.wave_accumulator = 4.0
	await _frames(2)
	var late_gap: float = (main.wave_enemy.position + main.wave_enemy.size / 2.0).distance_to(path[1])
	var front_arrive: float = st.active_encounter.members[st.active_encounter.front_index()].arrive
	_check(late_gap < start_gap and absf(main.enemy_travel - minf(1.0, st.wave_accumulator / front_arrive)) < 0.02, "the front member closes on its own clock: %f -> %f" % [start_gap, late_gap])
	_check(_followers(main) == st.active_encounter.standing_count() - 1, "every member behind the front is drawn: %d" % _followers(main))
	await _shot("1_approach")
	# A tap sends a mote, and the shown HP waits for it to land.
	var shown_before: String = main.wave_enemy.text
	main._tap_number()
	await process_frame
	var tap_motes: Array = main.arena_fx._motes.filter(func(m): return m.tap)
	_check(tap_motes.size() == 1, "a tap puts a mote in flight")
	await process_frame
	_check(main.wave_enemy.text == shown_before, "the shown HP holds while the mote flies: %s vs %s" % [shown_before, main.wave_enemy.text])
	await _shot("1b_mote")
	await create_timer(0.45).timeout
	_check(not main.arena_fx._motes.has(tap_motes[0]) and main.wave_enemy.text != shown_before, "the HP drops once the mote lands: " + main.wave_enemy.text)
	var popped: Array = main.floating_text_layer.get_children().filter(func(label): return label is Label and label.text.begins_with("-") and label.global_position.y < main.number_label.global_position.y)
	_check(popped.size() >= 1, "a tap's damage comes off the wave, above the Number")
	main._tap_number()
	await create_timer(0.36).timeout
	await _shot("1c_damage_pops")
	# D054: one mote per shot; a Multishot sends two, the second a beat behind,
	# and together the motes carry exactly what the step took off.
	await create_timer(0.4).timeout
	main.arena_fx.clear_motes()
	var one := SimulationEvent.new("tick", ScientificNumber.from_float(10.0))
	var two := SimulationEvent.new("tick", ScientificNumber.from_float(20.0), true)
	two.hits = 2
	var shots: Array[SimulationEvent] = [one, two]
	main._send_shots(shots, ScientificNumber.from_float(30.0), 0.016)
	var motes: Array = main.arena_fx._motes
	_check(motes.size() == 3, "two shots, one a Multishot, send three motes: %d" % motes.size())
	_check(main.arena_fx.in_flight().compare_to(ScientificNumber.from_float(30.0)) == 0, "the motes carry exactly the damage dealt: " + main.arena_fx.in_flight().format_value())
	var waiting: Array = motes.filter(func(m): return m.t < 0.0)
	_check(waiting.size() == 1, "a Multishot's second shot waits a beat")
	_check(motes.filter(func(m): return m.crit).size() == 2, "a crit Multishot's shots are both bright")
	await create_timer(0.45).timeout
	_check(not waiting.is_empty() and not main.arena_fx._motes.has(waiting[0]), "the delayed shot lands too")
	# D057: beating the front member breaks it apart where it stood, and the
	# next member becomes the live number.
	var old_front: int = st.active_encounter.front_index()
	st.active_encounter.apply_compliance(st.active_encounter.members[old_front].hp)
	await _frames(2)
	_check(_ghosts(main, WaveEnemy.Beat.SHATTER) == 1 and main.enemy_front == old_front + 1 and st.wave == 1, "a beaten front member shatters and the next takes its place")
	await _shot("1e_front_beaten")
	await create_timer(0.8).timeout
	# Beaten after the 2.5-second beat: replaced in the same step.
	_beat(st)
	await _frames(2)
	_check(_ghosts(main, WaveEnemy.Beat.SHATTER) == 1, "a wave beaten late shatters once")
	await create_timer(0.15).timeout
	await _shot("2_shatter")
	await create_timer(0.75).timeout
	_check(_ghosts(main, WaveEnemy.Beat.SHATTER) == 0, "the shatter frees itself")
	await _frames(4)
	_check(main.wave_enemy.visible and st.wave_accumulator < 1.5 and absf(main.enemy_travel - st.wave_accumulator / st.active_encounter.members[st.active_encounter.front_index()].arrive) < 0.03, "the next wave arrives at the edge: %f" % main.enemy_travel)
	# Beaten inside the beat: held on screen until 2.5 seconds.
	st.wave_accumulator = 0.5
	_beat(st)
	await _frames(2)
	_check(_ghosts(main, WaveEnemy.Beat.SHATTER) == 1 and not main.wave_enemy.visible, "a wave beaten early shatters once and stays gone")
	await create_timer(2.6).timeout
	_check(main.wave_enemy.visible and _ghosts(main, WaveEnemy.Beat.SHATTER) == 0, "after the beat the next wave shows")
	# A boss that is not beaten hits at 15 seconds and is knocked back.
	st.wave = 10
	st.active_encounter = st._make_encounter(10)
	st.number = ScientificNumber.from_float(1.0e9)
	st.wave_accumulator = 14.9
	await _frames(12)
	_check(main.enemy_latched, "a boss Hit lands and latches")
	await _shot("3_slam")
	await create_timer(0.5).timeout
	_check(main.wave_enemy.visible and main.enemy_latched and main.enemy_travel == 1.0 and st.wave_accumulator < 2.0, "the boss stays on the Number after its Hit: %f" % main.enemy_travel)
	_check(main.wave_enemy.caption.contains(" in "), "a latched boss counts down to its next Hit: " + main.wave_enemy.caption)
	await _shot("4_latched")
	# An ordinary missed wave slams once and the next wave comes in.
	st.wave = 12
	st.active_encounter = st._make_encounter(12)
	st.wave_accumulator = 14.95
	await _frames(12)
	_check(st.wave == 13 and main.wave_enemy.visible and st.active_encounter.at_number_count() >= 1 and main.enemy_travel == 1.0, "a missed wave slams and its members stay at the Number into the next (D058)")
	# With Guard and Armor, the wave shows its raw Hit and the working plays at contact.
	await create_timer(2.5).timeout
	st.purchased = {"guard": 30, GameState.ARMOR_ID: 60}
	st.wave = 15
	st.active_encounter = st._make_encounter(15)
	st.number = ScientificNumber.from_float(1.0e9)
	await _frames(3)
	var raw_text: String = st.get_hit_breakdown().raw.format_value()
	_check(main.wave_enemy.caption == "hits " + raw_text and st.get_hit_breakdown().raw.compare_to(st.get_effective_collection().multiply_scalar(st.next_hit_share())) > 0, "the caption shows the raw Hit: " + main.wave_enemy.caption)
	st.wave_accumulator = 14.95
	await create_timer(0.75).timeout
	var ledger_lines := 0
	for child in main.stage_root.get_children():
		if child is VBoxContainer and child != main.number_col:
			ledger_lines = maxi(ledger_lines, child.get_child_count())
	_check(ledger_lines == 4, "a reduced Hit plays raw, guard, armor and result: %d lines" % ledger_lines)
	await _shot("5_ledger")
	# Second Wind: an ordinary wave's forgiven Hit keeps its own colour and
	# still shows its working.
	await create_timer(2.5).timeout
	st.purchased = {"guard": 30, GameState.ARMOR_ID: 60, "second_wind": 20}
	st.second_wind_used = false
	st.wave = 17
	st.active_encounter = st._make_encounter(17)
	st.number = ScientificNumber.from_float(0.5)
	st.run_peak_number = ScientificNumber.from_float(1.0e6)
	await _frames(3)
	var rescued_parts: Dictionary = st.get_hit_breakdown()
	st.wave_accumulator = 14.95
	await create_timer(0.75).timeout
	_check(st.second_wind_used, "the probe's Hit should call Second Wind")
	var rescue_lines := 0
	var rescue_colour := Color.BLACK
	for child in main.stage_root.get_children():
		if child is VBoxContainer and child != main.number_col and child.get_child_count() > rescue_lines:
			rescue_lines = child.get_child_count()
			rescue_colour = child.get_child(0).get_theme_color("font_color")
	_check(rescue_lines == 4 and not rescue_parts_empty(rescued_parts), "a Hit Second Wind forgave still shows its working: %d lines" % rescue_lines)
	_check(rescue_colour.is_equal_approx(main.DANGER), "an ordinary wave's forgiven Hit is not boss red")
	await _shot("6_second_wind")
	await create_timer(2.6).timeout
	st.active_encounter = st._make_encounter(st.wave)
	st.wave_accumulator = 0.0
	st.number = ScientificNumber.from_float(1.0e9)
	# Live: a run at 5.95 shots a second keeps several motes flying.
	st.purchased["faster_cadence"] = 100
	st.purchased["generator"] = 40
	var ticks_before: int = st.statistics.ticks
	var peak := 0
	for i in range(40):
		await process_frame
		peak = maxi(peak, main.arena_fx._motes.size())
	await _shot("1d_stream")
	_check(st.statistics.ticks - ticks_before >= 2 and peak >= 1, "live shots leave as motes: %d ticks, peak %d" % [st.statistics.ticks - ticks_before, peak])
	# D055: at 14.9 shots a second the passive "-X" folds to one per 0.33 s.
	var seen := {}
	for label in main.floating_text_layer.get_children():
		seen[label] = true
	var shots_before: int = st.statistics.ticks
	await create_timer(1.0).timeout
	var pops := 0
	for label in main.floating_text_layer.get_children():
		if label is Label and not seen.has(label) and (label.text.begins_with("-") or label.text.begins_with("CRIT -")):
			pops += 1
	_check(st.statistics.ticks - shots_before >= 12 and pops <= 4, "fourteen shots a second fold into a few pops: %d shots, %d pops" % [st.statistics.ticks - shots_before, pops])
	st.purchased.erase("faster_cadence")
	st.purchased.erase("generator")
	# D057: a member reaching the Number carries its HP past; that is not
	# damage, so no mote or pop may carry it.
	st.wave = 27
	st.active_encounter = st._make_encounter(27)
	st.number = ScientificNumber.from_float(1.0e9)
	st.wave_accumulator = 5.9
	await _frames(2)
	main.arena_fx.clear_motes()
	main.pop_damage = ScientificNumber.new()
	var member_hp: ScientificNumber = st.active_encounter.members[0].max
	await _frames(8)
	var carried: ScientificNumber = main.arena_fx.in_flight().add(main.pop_damage)
	_check(st.active_encounter.landed_count() == 1 and carried.compare_to(member_hp.multiply_scalar(0.5)) < 0, "a landing member's HP is not shown as damage: %s of %s" % [carried.format_value(), member_hp.format_value()])
	await create_timer(1.0).timeout
	# D055: shot damage still waiting to pop rises before the wave shatters.
	main.pop_damage = ScientificNumber.from_float(7777.0)
	main.pop_crit = false
	var before_clear := {}
	for label in main.floating_text_layer.get_children():
		before_clear[label] = true
	main._shatter_enemy(false)
	var flushed: Array = main.floating_text_layer.get_children().filter(func(label): return not before_clear.has(label) and label is Label and label.text.begins_with("-"))
	_check(flushed.size() == 1 and main.pop_damage.is_zero(), "the pending shot pop rises before the shatter: %s" % str(flushed.map(func(label): return label.text)))
	await create_timer(1.0).timeout
	# D058: a pile at the Number while the next wave walks in.
	st.wave = 27
	st.active_encounter = st._make_encounter(27)
	st.number = ScientificNumber.from_float(1.0e12)
	st.wave_accumulator = 14.5
	await create_timer(3.0).timeout
	_check(st.wave == 28 and _followers(main) >= st.active_encounter.at_number_count() - 1, "the pile is drawn round the Number: %d" % _followers(main))
	await _shot("7_pile")
	# D058 review: behind a pile, a boss stays the live number.
	var pile: Array = st.active_encounter.living_members().filter(func(m): return int(m.state) == TaxEncounter.AT_NUMBER)
	var boss_wave = st._make_encounter(30)
	boss_wave.carry_in(pile)
	st.wave = 30
	st.active_encounter = boss_wave
	st.wave_accumulator = 2.0
	await _frames(3)
	var boss_index: int = st.active_encounter.members.size() - 1
	_check(main.enemy_front == boss_index and main.wave_enemy.font_size == 30 and st.active_encounter.front_index() < boss_index, "a boss stays the live number behind a pile")
	await _shot("8_boss_pile")
	st.settings["reduce_motion"] = true
	st.wave_accumulator = 9.0
	await _frames(3)
	var rm_front: Dictionary = st.active_encounter.members[main.enemy_front]
	_check(main.wave_enemy.visible and main.enemy_travel == (1.0 if int(rm_front.state) == TaxEncounter.AT_NUMBER else 0.0), "with Reduce Motion a walking front holds at the edge")
	_beat(st)
	await _frames(2)
	_check(_ghosts(main, WaveEnemy.Beat.SHATTER) == 0, "with Reduce Motion no shatter plays")
	st.end_run()
	await _frames(2)
	_check(not main.wave_enemy.visible, "no body between runs")
	st.clear_save()
	print("ARENA PROBE ", "PASS" if fails == 0 else "FAIL %d" % fails, "  screenshots in ", ProjectSettings.globalize_path(OUT))
	quit()
