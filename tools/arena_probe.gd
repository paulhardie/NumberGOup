extends SceneTree
## Plays the run arena through its beats in a real window and checks them:
## the group walking in (D057), motes and pops (D051, D054, D055), a beaten
## front member, clears, boss slams and latching, the Hit's working (D052),
## the pile at the Number and a boss behind it (D058), the Range ring and orbs
## (D068), and Reduce Motion. Saves to a throwaway file and writes screenshots to
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
	for index in range(st.active_encounter.members.size()):
		var member: Dictionary = st.active_encounter.members[index]
		if TaxEncounter.is_alive(member):
			st.active_encounter.damage_member(index, member.hp.copy())
	st._pay_kills()
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
	# Basic enemies to start, so no faster one overtakes the front while the
	# approach is measured; the usual mix returns for the boss.
	var mix: Dictionary = st.balance_profile.ENEMY_MIX.duplicate()
	st.balance_profile.ENEMY_MIX = {"basic": 1.0}
	st.start_run(1, 3)
	st.number = ScientificNumber.from_float(5000)
	# Sturdier than a wave 1 basic, which one shot of Damage 3 kills, so a tap
	# chips the front rather than beating it.
	for member in st.active_encounter.members:
		member.max = ScientificNumber.from_float(100.0)
		member.hp = member.max.copy()
	st.active_encounter._sum_remaining()
	main._refresh_all()
	await _frames(3)
	_check(main.wave_enemy.visible, "a standing wave shows its body")
	var path: Array = main._enemy_path()
	var start_gap: float = (main.wave_enemy.position + main.wave_enemy.size / 2.0).distance_to(path[1])
	# Eight seconds in, so the front basic is 20 m out, inside the reach (D068's
	# 100 m approach), and a tap strikes it.
	st.wave_accumulator = 8.0
	await _frames(2)
	var late_gap: float = (main.wave_enemy.position + main.wave_enemy.size / 2.0).distance_to(path[1])
	var front_arrive: float = st.active_encounter.members[st.active_encounter.front_index()].arrive
	_check(late_gap < start_gap and absf(main.enemy_travel - minf(1.0, st.wave_accumulator / front_arrive)) < 0.02, "the front member closes on its own clock: %f -> %f" % [start_gap, late_gap])
	# Only members that have set off are on the arena (D067).
	var set_off: int = st.active_encounter.members.filter(func(m): return TaxEncounter.is_alive(m) and st.wave_accumulator >= float(m.sets_off)).size()
	_check(_followers(main) == set_off - 1, "every member that has set off is drawn behind the front: %d of %d" % [_followers(main), set_off - 1])
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
	var popped: Array = main.floating_text_layer.get_children().filter(func(label): return label is Label and label.text.begins_with("-"))
	_check(main.damage_readout.visible and main.damage_readout.text.begins_with("-") and popped.is_empty(), "a tap updates one fixed damage readout beside the wave")
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
	st.active_encounter.damage_member(old_front, st.active_encounter.members[old_front].hp.copy())
	await _frames(2)
	_check(_ghosts(main, WaveEnemy.Beat.SHATTER) == 1 and main.enemy_front == old_front + 1 and st.wave == 1, "a beaten front member shatters and the next takes its place")
	await _shot("1e_front_beaten")
	await create_timer(0.8).timeout
	# Beaten well before its clock ends, the wave shatters once and holds its
	# 35 seconds (D067), then the next comes in.
	_beat(st)
	await _frames(2)
	_check(_ghosts(main, WaveEnemy.Beat.SHATTER) == 1 and st.wave == 1, "a beaten wave shatters once and holds its clock")
	await create_timer(0.15).timeout
	await _shot("2_shatter")
	await create_timer(0.75).timeout
	_check(_ghosts(main, WaveEnemy.Beat.SHATTER) == 0 and st.wave == 1, "the shatter frees itself while the clock runs on")
	st.wave_accumulator = GameState.WAVE_INTERVAL_SECONDS - 0.05
	await create_timer(0.25).timeout
	await _frames(2)
	_check(main.wave_enemy.visible and st.wave == 2 and st.wave_accumulator < 1.5 and absf(main.enemy_travel - st.wave_accumulator / st.active_encounter.members[st.active_encounter.front_index()].arrive) < 0.03, "the next wave arrives at the edge: %f" % main.enemy_travel)
	st.balance_profile.ENEMY_MIX = mix
	# A boss that is not beaten reaches the Number at 30 seconds (D068's 100 m)
	# and stays there, the live number, while the next wave comes in behind it
	# at 35 (D063, D065, D066).
	st.wave = 10
	st.active_encounter = st._make_encounter(10)
	st.number = ScientificNumber.from_float(1.0e9)
	st.wave_accumulator = TaxBalanceProfile.boss_arrival_seconds() - 0.1
	await create_timer(0.25).timeout
	var boss_in_wave: int = st.active_encounter.boss_index()
	_check(st.wave == 10 and boss_in_wave >= 0 and int(st.active_encounter.members[boss_in_wave].state) == TaxEncounter.AT_NUMBER, "a boss Hit lands at 30 seconds and the boss stays")
	st.wave_accumulator = 34.9
	await create_timer(0.25).timeout
	var landed_boss: int = st.active_encounter.boss_index()
	_check(st.wave == 11 and landed_boss >= 0 and int(st.active_encounter.members[landed_boss].state) == TaxEncounter.AT_NUMBER, "the boss stays as the next wave comes")
	await _shot("3_slam")
	await create_timer(0.5).timeout
	_check(main.wave_enemy.visible and main.enemy_front == st.active_encounter.boss_index() and main.enemy_travel == 1.0 and main.wave_enemy.modulate.a > 0.99 and st.wave_accumulator < 2.0, "the boss stays on the Number, the live number, after its Hit: %f" % main.enemy_travel)
	_check(main.wave_enemy.caption.contains(" in "), "a latched boss counts down to its next Hit: " + main.wave_enemy.caption)
	await _shot("4_latched")
	# An ordinary missed wave slams once and the next wave comes in.
	st.balance_profile.OPENING_HIT_WAVES = 30
	st.balance_profile.OPENING_EASED_BY = 50
	st.wave = 12
	st.active_encounter = st._make_encounter(12)
	st.wave_accumulator = 34.95
	await _frames(12)
	# Its enemies set off last are still walking in, 100 m out being further
	# than the clock (D068); they carry on into the next wave.
	_check(st.wave == 13 and main.wave_enemy.visible and st.active_encounter.at_number_count() == 0, "an opening wave that is missed slams and the next arrives (D059)")
	# Back to today's rule, enemies staying from wave 1 (D072).
	st.balance_profile.OPENING_HIT_WAVES = 0
	st.balance_profile.OPENING_EASED_BY = 0
	# With Defense Absolute and Defense %, the wave shows its raw Hit and the
	# working plays at contact.
	await create_timer(2.5).timeout
	st.purchased = {"defense_absolute": 2, "defense_percent": 60}
	st.wave = 15
	st.active_encounter = st._make_encounter(15)
	st.number = ScientificNumber.from_float(1.0e9)
	await _frames(3)
	var raw_text: String = st.get_hit_breakdown().raw.format_value()
	var reduced_parts: Dictionary = st.get_hit_breakdown()
	_check(main.wave_enemy.caption.begins_with("hits " + raw_text) and st.get_hit_breakdown().raw.compare_to(st.get_effective_collection().multiply_scalar(st.next_hit_share())) > 0, "the caption shows the raw Hit: " + main.wave_enemy.caption)
	st.wave_accumulator = 14.95
	await create_timer(0.75).timeout
	var ledger_lines := 0
	for child in main.stage_root.get_children():
		if child is VBoxContainer and child != main.number_col:
			ledger_lines = maxi(ledger_lines, child.get_child_count())
	_check(ledger_lines == 4, "a reduced Hit plays raw, guard, armor and result: %d lines" % ledger_lines)
	await _shot("5_ledger")
	var previous_ledger = main.active_hit_ledger
	main._show_hit_ledger(reduced_parts, reduced_parts.final, main.DANGER)
	await _frames(2)
	var live_ledgers: Array = main.stage_root.get_children().filter(func(child): return child is VBoxContainer and child != main.number_col and not child.is_queued_for_deletion())
	_check(main.active_hit_ledger != previous_ledger and live_ledgers.size() == 1, "close reduced Hits replace their working instead of stacking columns")
	# The Range row's ring and the orbs outside it (D068).
	await create_timer(2.5).timeout
	st.purchased = {"range": 79, "orbs": 4, "orb_speed": 38}
	st.active_encounter = st._make_encounter(st.wave)
	st.wave_accumulator = 3.0
	await _frames(3)
	var ring_radius: float = main.arena_fx.ring_points[0].distance_to(main.number_label.get_global_rect().get_center() - main.stage_root.global_position)
	var orb_radius: float = main.arena_fx.orb_points[0].distance_to(main.number_label.get_global_rect().get_center() - main.stage_root.global_position) if not main.arena_fx.orb_points.is_empty() else 0.0
	_check(main.arena_fx.orb_points.size() == 4 and orb_radius > ring_radius * 0.8, "four orbs circle near the 69.5 m ring: ring %f, orbs %f" % [ring_radius, orb_radius])
	await _shot("6_range_orbs")
	st.purchased = {}
	await create_timer(2.6).timeout
	# Basics only, eight seconds after the first sets off, so it is 20 m out
	# and in reach (D067, D068): a random mix could put a tank first, still
	# out of reach, and no shot would leave as a mote.
	var stream_mix: Dictionary = st.balance_profile.ENEMY_MIX
	st.balance_profile.ENEMY_MIX = {"basic": 1.0}
	st.active_encounter = st._make_encounter(st.wave)
	st.balance_profile.ENEMY_MIX = stream_mix
	var first := 0
	for index in range(st.active_encounter.members.size()):
		if float(st.active_encounter.members[index].sets_off) < float(st.active_encounter.members[first].sets_off):
			first = index
	st.wave_accumulator = float(st.active_encounter.members[first].sets_off) + 8.0
	# Tough enough to stand through both stream checks: once it fell, the
	# next basic is still walking in and the readout rightly hides.
	st.active_encounter.members[first].max = ScientificNumber.from_float(1.0e6)
	st.active_encounter.members[first].hp = ScientificNumber.from_float(1.0e6)
	st.active_encounter._sum_remaining()
	st.number = ScientificNumber.from_float(1.0e9)
	# Live: Attack Speed 5.95 under Rapid Fire, 23.8 shots a second at the
	# first Damage, keeps several motes flying without clearing the reach.
	st.purchased["attack_speed"] = 99
	st.rapid_fire_left = 30.0
	var ticks_before: int = st.statistics.ticks
	var peak := 0
	# A second of the wave's clock rather than a count of frames: motes leave
	# once per MOTE_INTERVAL of it, and a fast display can run 40 frames
	# before the first one does.
	var stream_start: float = st.wave_accumulator
	var frames := 0
	while st.wave_accumulator < stream_start + 1.0 and frames < 600:
		await process_frame
		frames += 1
		peak = maxi(peak, main.arena_fx._motes.size())
	await _shot("1d_stream")
	_check(st.statistics.ticks - ticks_before >= 2 and peak >= 1, "live shots leave as motes: %d ticks, peak %d" % [st.statistics.ticks - ticks_before, peak])
	# D061: even at 23.8 shots a second, damage updates one label in place.
	var seen := {}
	for label in main.floating_text_layer.get_children():
		seen[label] = true
	var shots_before: int = st.statistics.ticks
	await create_timer(1.0).timeout
	var pops := 0
	for label in main.floating_text_layer.get_children():
		if label is Label and not seen.has(label) and label.text.begins_with("-"):
			pops += 1
	_check(st.statistics.ticks - shots_before >= 12 and pops == 0 and main.damage_readout.visible, "a stream of shots updates one fixed readout: %d shots, %d pops" % [st.statistics.ticks - shots_before, pops])
	st.purchased.erase("attack_speed")
	st.rapid_fire_left = 0.0
	# D057: a member reaching the Number carries its HP past; that is not
	# damage, so no mote or pop may carry it.
	st.wave = 27
	st.active_encounter = st._make_encounter(27)
	st.number = ScientificNumber.from_float(1.0e9)
	st.wave_accumulator = 9.9
	await _frames(2)
	main.arena_fx.clear_motes()
	main.pop_damage = ScientificNumber.new()
	var member_hp: ScientificNumber = st.active_encounter.members[0].max
	await create_timer(0.25).timeout
	var carried: ScientificNumber = main.arena_fx.in_flight().add(main.pop_damage)
	_check(st.active_encounter.landed_count() == 1 and carried.compare_to(member_hp.multiply_scalar(0.5)) < 0, "a landing member's HP is not shown as damage: %s of %s" % [carried.format_value(), member_hp.format_value()])
	await create_timer(1.0).timeout
	# Damage waiting to be shown enters the fixed readout before the shatter.
	main.pop_damage = ScientificNumber.from_float(7777.0)
	main.pop_crit = false
	main._shatter_enemy(false)
	_check(main.damage_readout.visible and main.damage_readout.text == "-" + main._stat_number(ScientificNumber.from_float(7777.0)) and main.pop_damage.is_zero(), "pending shot damage reaches the readout before the shatter: " + main.damage_readout.text)
	await create_timer(1.0).timeout
	# D058: a pile at the Number while the next wave walks in.
	st.wave = 57
	st.active_encounter = st._make_encounter(57)
	st.number = ScientificNumber.from_float(1.0e12)
	st.wave_accumulator = 34.5
	await create_timer(3.0).timeout
	_check(st.wave == 58 and _followers(main) >= mini(st.active_encounter.at_number_count() - 1, main.MAX_PILE_DRAWN), "the pile is drawn round the Number: %d" % _followers(main))
	main.hit_readout_elapsed = main.COMBAT_READOUT_WINDOW
	main._record_hit_readout(ScientificNumber.from_float(4.0))
	main._record_hit_readout(ScientificNumber.from_float(6.0))
	await process_frame
	_check(main.hit_readout.visible and main.hit_readout.text == "HIT -10" and main.hit_readout.get_global_rect().position.y >= main.number_col.get_global_rect().end.y, "close pile Hits share one readout below the Number: " + main.hit_readout.text)
	await _shot("7_pile")
	# D058 review: behind a pile, a boss stays the live number.
	var pile: Array = st.active_encounter.living_members().filter(func(m): return int(m.state) == TaxEncounter.AT_NUMBER)
	var boss_wave = st._make_encounter(60)
	boss_wave.carry_in(pile)
	st.wave = 60
	st.active_encounter = boss_wave
	st.wave_accumulator = 2.0
	await _frames(3)
	var boss_index: int = st.active_encounter.boss_index()
	_check(boss_index >= 0 and main.enemy_front == boss_index and main.wave_enemy.font_size == 30 and st.active_encounter.front_index() < boss_index, "a boss stays the live number behind a pile")
	await _shot("8_boss_pile")
	st.settings["reduce_motion"] = true
	st.wave_accumulator = 9.0
	await _frames(3)
	main._pop_damage(ScientificNumber.from_float(5.0), true, true)
	_check(main.damage_readout.visible and main.damage_readout.text.begins_with("-") and not main.damage_readout.text.contains("CRIT") and main.damage_readout.get_theme_color("font_color") == main.CRIT_COLOUR and main.damage_readout.get_theme_font("font") == main.number_font_semibold, "Reduce Motion shows a critical as red, heavier damage text without a word")
	var rm_front: Dictionary = st.active_encounter.members[main.enemy_front]
	_check(main.wave_enemy.visible and main.enemy_travel == (1.0 if int(rm_front.state) == TaxEncounter.AT_NUMBER else 0.0), "with Reduce Motion a walking front holds at the edge: %f" % main.enemy_travel)
	_beat(st)
	await _frames(2)
	_check(_ghosts(main, WaveEnemy.Beat.SHATTER) == 0, "with Reduce Motion no shatter plays")
	st.end_run()
	await _frames(2)
	_check(not main.wave_enemy.visible and not main.damage_readout.visible and not main.hit_readout.visible, "no enemy or combat readout between runs")
	st.clear_save()
	print("ARENA PROBE ", "PASS" if fails == 0 else "FAIL %d" % fails, "  screenshots in ", ProjectSettings.globalize_path(OUT))
	quit()
