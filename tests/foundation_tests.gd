extends SceneTree
## Observable contracts for the scaling foundations; all files use user://
## under run_godot.sh's scratch HOME, never the player's progress.
const Progression = preload("res://src/tower/progression.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Snapshot = preload("res://src/tower/battle_snapshot.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const RunConfig = preload("res://src/tower/run_config.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const Save = preload("res://src/tower/save.gd")
const RealClock = preload("res://src/tower/real_clock.gd")
const BattleScreen = preload("res://src/ui/battle_screen.gd")
const Main = preload("res://src/main.gd")
const Home = preload("res://src/ui/home_screen.gd")
const PATH := "user://foundation_save.json"
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)


func json(value):
	return JSON.parse_string(JSON.stringify(value, "", true, true))


func run() -> void:
	for method in get_method_list():
		if String(method.name).begins_with("test_"): await call(method.name)
	for failure in failures: printerr("FAIL: ", failure)
	print("%s: foundation tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


func test_wave_rewards_and_daily_claims() -> void:
	var p := Progression.new()
	check(p.observe(1, 9).is_empty() and not p.unlocked("workshop"), "fresh wave gates")
	check(p.observe(1, 10).size() == 1 and p.workshop.coins == 10.0, "wave 10 pays Coins")
	check(p.observe(1, 10).is_empty(), "wave reward cannot pay twice")
	p.observe(1, 30, 29)
	check(p.gems == 10 and p.unlocked("cards") and p.unlocked("labs"), "wave 20 Gems and 30 Labs gate")
	p.observe(1, 100, 99)
	check(not p.tier_open(2), "reached 100 is not cleared 100")
	p.observe(1, 101, 100)
	check(p.tier_open(2) and not p.tier_open(3), "clear unlock is per tier")
	p.observe(2, 10)
	check(p.workshop.coins == 1910.0 and p.gems == 45, "known rewards by tier")
	check(not p.claim_daily(86400.0), "daily claim waits for first run")
	p.workshop.finish_run(1)
	check(p.claim_daily(86400.0) and not p.claim_daily(86401.0), "one daily claim")
	check(not p.claim_daily(0.0) and not p.claim_daily(NAN), "rollback and invalid clock grant no Gems")
	check(p.claim_daily(172800.0) and p.gems == 85, "next UTC day")
	check(not p.spend_gems(-1) and not p.spend_gems(86) and p.spend_gems(10), "Gem spending boundaries")
	var loaded := Progression.new()
	loaded.restore(json(p.to_dict()))
	check(loaded.to_dict() == p.to_dict() and loaded.observe(2, 10).is_empty(), "records and claims round trip")
	loaded.writable = false
	check(not loaded.claim_daily(259200.0) and loaded.observe(1, 200).is_empty(), "protected progress cannot earn rewards")


func test_coin_precision_and_affordability() -> void:
	var w := Workshop.new()
	w.coins = 1e20
	for i in range(1000): w.add_coins(1.0)
	var restored := Workshop.new()
	restored.restore(json(w.to_dict()))
	check(restored.spend_coins(1e20) and restored.coins == 1000.0, "tiny awards survive large-balance saving and spending")
	check(not restored.spend_coins(1001.0) and not restored.spend_coins(-1.0) and not restored.spend_coins(INF), "invalid spending leaves balance")
	check(restored.spend_coins(1000.0) and restored.coins == 0.0, "exact final spend")
	w.coins = 1e20
	w.spend_coins(1.0)
	check(not w.spend_coins(1e20), "negative remainder cannot pay the high part for free")
	w.add_coins(1.0)
	check(w.spend_coins(1e20) and w.coins == 0.0, "tiny cost and award cancel exactly")
	var shifted := 0.0
	for i in range(1, 5000):
		var candidate := 123456.7 / (float(i) + 0.1)
		if json({"v": candidate}).v != candidate:
			shifted = candidate
			break
	check(shifted > 0.0, "fixture demonstrably shifts in decimal JSON")
	w.coins = shifted
	var p := Progression.new(w)
	check(Save.save_progress(p, PATH) and Save.load_progress(PATH).workshop.coins == shifted, "permanent Coins persist without decimal rounding")
	DirAccess.remove_absolute(PATH)
	var screen := BattleScreen.new()
	screen.workshop = Workshop.new()
	root.add_child(screen)
	screen.set_process(false)
	screen.sim.coins = shifted
	var saved: Dictionary = json(screen.run_state())
	var after := BattleScreen.new()
	after.workshop = screen.workshop
	after.resume = saved
	root.add_child(after)
	after.set_process(false)
	after._process(0.0)
	check(after._banked == shifted and after.workshop.coins == shifted, "rounded report balance cannot duplicate or lose banked Coins")
	screen.free()
	after.free()


func test_research_time_and_frozen_effects() -> void:
	var p := Progression.new()
	p.workshop.coins = 100.0
	var effect := {"stat": "health", "op": "multiply", "value": 2.0, "source": "lab:health"}
	check(not p.start_research("health", 10.0, 60.0, [effect], 0.0), "Labs must unlock before a job")
	p.observe(1, 30)
	check(p.start_research("health", 10.0, 60.0, [effect], 0.0), "paid research starts")
	effect.value = 99.0
	check(not p.start_research("health", 10.0, 60.0, [effect], 1.0), "duplicate job cannot charge again")
	check(p.workshop.coins == 100.0, "one cost, alongside wave-10 reward")
	check(p.advance_time(30.0).is_empty(), "research still running")
	var loaded := Progression.new()
	loaded.restore(json(p.to_dict()))
	check(loaded.advance_time(60.0) == ["health"], "closed time finishes research")
	check(loaded.advance_time(60.0).is_empty() and loaded.advance_time(20.0).is_empty(), "reload and clock rollback cannot complete twice")
	var battle := BattleSim.new(4, {}, BattleSim.START_GROUPS, 1, loaded.run_effects())
	check(battle.health == 10.0 and loaded.research.levels.health == 1, "completed research builds the next run with its frozen effect")
	check(loaded.start_research("health", 0.0, 60.0, [{"stat": "health", "op": "multiply", "value": 3.0, "source": "lab:health"}], 60.0), "next research level")
	loaded.advance_time(120.0)
	check(BattleSim.new(4, {}, BattleSim.START_GROUPS, 1, loaded.run_effects()).health == 15.0 and battle.health == 10.0, "higher research replaces its effect; active battle stays frozen")
	var clock := RealClock.new()
	check(clock.advance(0.0) == 0.0 and clock.advance(1.0) == 1.0, "epoch zero is a valid initial clock")
	check(clock.advance(0.0) == 0.0 and clock.advance(2.0) == 1.0, "clock uses saved high-water mark")
	check(clock.advance(86400.0 * 100.0) > 86400.0 * 90.0, "long research catches up without silently losing days")
	loaded.research.restore({"slots": {}, "jobs": [null, {"id": "x"}], "levels": {"x": "bad"}})
	check(loaded.research.jobs.is_empty() and loaded.research.slots == 1, "damaged research is rejected without errors")
	loaded.workshop.coins = 100.0
	loaded.research.completed_effects = {"z": [{"stat": "damage", "op": "multiply", "value": 1e10, "source": "lab:z"}], "a": [{"stat": "health", "op": "multiply", "value": 2.0, "source": "lab:a"}]}
	check(loaded.run_effects()[0].source == "lab:a", "research flattens in stable id order")
	check(not loaded.start_research("overflow", 10.0, 1.0, [{"stat": "damage", "op": "multiply", "value": 1e20, "source": "lab:overflow"}], 121.0) and loaded.workshop.coins == 100.0, "combined research build rejects overflow before charging")


func test_research_completion_order_cannot_break_the_account() -> void:
	var p := Progression.new()
	p.observe(1, 30)
	p.workshop.coins = 100.0
	p.research.slots = 2
	p.research.completed_effects = {
		"a": [{"domain": "rule", "stat": "coin_multiplier", "op": "multiply", "value": 1e-10, "source": "lab:a"}],
		"b": [{"domain": "rule", "stat": "coin_multiplier", "op": "multiply", "value": 1e20, "source": "lab:b"}],
	}
	check(p.start_research("a", 10.0, 100.0, [{"domain": "rule", "stat": "coin_multiplier", "op": "multiply", "value": 1e-25, "source": "lab:a"}], 0.0), "a slow reducing replacement starts")
	check(not p.start_research("b", 10.0, 10.0, [{"domain": "rule", "stat": "coin_multiplier", "op": "multiply", "value": 1e50, "source": "lab:b"}], 0.0) and p.workshop.coins == 90.0, "a fast job cannot create an unsupported intermediate build or charge Coins")
	check(p.advance_time(100.0) == ["a"], "the safe replacement completes")
	check(p.start_research("b", 10.0, 10.0, [{"domain": "rule", "stat": "coin_multiplier", "op": "multiply", "value": 1e50, "source": "lab:b"}], 100.0), "the larger replacement is safe after the reduction completes")
	p.advance_time(110.0)
	check(Save.save_progress(p, PATH) and Save.load_progress(PATH).writable, "completed replacements save and reload without protecting valid progress")


func test_config_replay_and_sources() -> void:
	var effects := [{"stat": "health", "op": "multiply", "value": 2.0, "source": "card:health"}]
	var rules := [{"stat": "starting_cash", "op": "add", "value": 100.0, "source": "card:cash"}]
	var sim := BattleSim.new(9223372036854775807, {"health": 20}, BattleSim.START_GROUPS, 2, effects, rules)
	for i in range(120): sim.step()
	sim.buy("damage")
	sim.apply_effect({"stat": "health", "op": "multiply", "value": 1.5, "source": "perk:health"})
	for i in range(100): sim.step()
	var report: Dictionary = json(RunReport.build(sim))
	check(RunReport.is_replayable(report) and RunReport.matches(report, RunReport.replay(report)), "tier, 64-bit seed, initial rules and mid-run effects replay")
	check(RunReport.replay(report).enemy_attack_now("basic") == sim.enemy_attack_now("basic"), "tier replay cannot silently become Tier 1")
	var wrong: Dictionary = report.duplicate(true)
	wrong.start.tier = 1
	check(not RunReport.matches(wrong, sim), "wrong-tier result is rejected even before totals differ")
	wrong = report.duplicate(true)
	wrong.start.version = 1.1
	check(not RunReport.is_replayable(wrong), "fractional contract version rejected")
	for bad in [null, [], "bad"]:
		wrong = report.duplicate(true)
		wrong.result = bad
		check(not RunReport.is_replayable(wrong), "malformed current record result rejects safely")
	for bad in [{}, [], "bad", INF, 1.5]:
		wrong = report.duplicate(true)
		wrong.result.ticks = bad
		check(not RunReport.is_replayable(wrong), "malformed tick rejects before conversion")
	var fresh := BattleSim.new(1)
	check(not RunReport.matches(RunReport.build(fresh), BattleSim.new(1, {"damage": 1})), "equal totals cannot conceal a different starting Workshop")
	var overflow: Dictionary = sim.start_config()
	overflow.effects = [{"stat": "health", "op": "multiply", "value": 1e300, "source": "bad"}]
	check(not RunConfig.valid(overflow), "effects cannot overflow at later Workshop levels")
	overflow.effects = [{"stat": "attack_speed", "op": "multiply", "value": 1e100, "source": "bad"}]
	check(not RunConfig.valid(overflow), "finite but unsupported attack speed cannot stall a tick")
	var quiet := BattleSim.new(3, {"health": 20})
	quiet.spawns.schedule.clear()
	quiet._place("basic", 0.0)
	var enemy = quiet.enemies.back()
	var hp: float = enemy.health
	check(quiet.deal_damage(enemy, hp * 10.0, "weapon:test"), "shared damage resolves kill")
	check(not quiet.deal_damage(enemy, hp, "weapon:test") and quiet.kills == 1, "same enemy cannot award a second kill")
	check(quiet.damage_by["weapon:test"] == hp and quiet.kills_by["weapon:test"] == 1, "actual damage, excluding overkill, and kill attribution")


func test_decimal_shifting_effects_replay_and_resume() -> void:
	var shifted := 0.0
	for i in range(1, 5000):
		var candidate := 123456.7 / (float(i) + 0.1)
		if json({"v": candidate}).v != candidate:
			shifted = candidate
			break
	check(shifted > 0.0, "effect fixture demonstrably shifts in decimal JSON")
	var p := Progression.new()
	p.research.completed_effects = {"health": [{"stat": "health", "op": "add", "value": shifted, "source": "lab:health"}]}
	var first := BattleScreen.new()
	first.workshop = p.workshop
	first.progression = p
	root.add_child(first)
	first.set_process(false)
	for i in range(120): first.sim.step()
	first.sim.apply_effect({"stat": "health", "op": "add", "value": shifted, "source": "perk:health"})
	for i in range(100): first.sim.step()
	var saved: Dictionary = json(first.run_state())
	var replayable := RunReport.is_replayable(saved)
	check(replayable, "decimal-shifting starting and mid-run effects remain readable/replayable")
	check(replayable and RunReport.matches(saved, RunReport.replay(saved)), "exact effects survive report JSON round trip and replay")
	var second := BattleScreen.new()
	second.workshop = p.workshop
	second.resume = saved
	root.add_child(second)
	second.set_process(false)
	check(second.sim != null and Snapshot.capture(second.sim).digest == Snapshot.capture(first.sim).digest, "decimal-shifting effects resume directly with every saved field exact")
	first.free()
	second.free()


func test_snapshot_continuation() -> void:
	var groups: Array = []
	var ranks := {}
	for group in TowerData.groups(): groups.append(String(group.id))
	for id in TowerData.rows(): ranks[id] = mini(25, TowerData.max_level(id))
	ranks.health = 500
	for tier in [1, 2, 3]:
		for seed in [1, 7, 23]:
			var sim := BattleSim.new(seed, ranks, groups, tier)
			sim.wave = 450
			sim.health_level = 450
			sim.attack_level = 450
			sim.spawns.schedule_wave()
			for i in range(200): sim.step()
			sim.apply_effect({"stat": "damage", "op": "multiply", "value": 1.2, "source": "perk:damage"})
			sim.cooldowns.set_time("weapon:test", 17.0)
			var saved: Dictionary = json(Snapshot.capture(sim))
			var again := Snapshot.restore(saved)
			check(again != null, "snapshot parses tier %d seed %d" % [tier, seed])
			if again == null: continue
			check(Snapshot.capture(again).digest == saved.digest, "every saved field round trips: %s / %s" % [Snapshot.capture(again).digest, saved.digest])
			for i in range(600):
				sim.step()
				again.step()
			check(Snapshot.capture(sim).digest == Snapshot.capture(again).digest, "exact continuation tier %d seed %d: %s" % [tier, seed, difference(json(Snapshot.capture(sim)), json(Snapshot.capture(again)))])
	var sim := BattleSim.new(8, {"health": 100})
	for i in range(80): sim.step()
	var saved: Dictionary = json(Snapshot.capture(sim))
	for key in ["version", "encoding", "payload", "digest"]:
		var damaged := saved.duplicate(true)
		damaged[key] = null
		check(Snapshot.restore(damaged) == null, "damaged snapshot rejected: " + key)
	var corrupt := saved.duplicate(true)
	corrupt.payload = "x" + corrupt.payload.substr(1)
	check(Snapshot.restore(corrupt) == null, "snapshot checksum detects changed state")
	var state: Dictionary = RunConfig.unpack(saved)
	state.current_effects = [{"stat": "health", "op": "multiply", "value": INF, "source": "bad"}]
	corrupt = RunConfig.pack(state)
	corrupt.version = Snapshot.VERSION
	check(Snapshot.restore(corrupt) == null, "non-finite snapshot effect rejected without errors")
	for key in ["divider", "run_levels"]:
		state = RunConfig.unpack(saved)
		state.state[key] = {} if key == "divider" else {"unknown": 1.0}
		corrupt = RunConfig.pack(state)
		corrupt.version = Snapshot.VERSION
		check(Snapshot.restore(corrupt) == null, "semantically broken state rejected: " + key)


## D133, D134: a Lock holding the Number, one still to come, and a Divider's
## held bite all survive a snapshot and continue exactly.
func test_snapshot_keeps_the_lock_and_a_held_bite() -> void:
	var sim := BattleSim.new(5, {"health": 200, "damage": 20, "attack_speed": 10})
	sim.divider.refill_seconds = 10.0
	sim.wave = 38
	sim.health_level = 38
	sim.attack_level = 38
	sim.spawns.schedule_wave()
	check(sim.spawns.schedule.any(func(item): return item.kind == "lock" and item.has("angle")), "wave 38 schedules a Lock with its own direction")
	while sim.alive and not sim.locked and sim.ticks < 30 * 60:
		sim.health = sim.max_health() * 50.0
		sim.step()
	check(sim.locked, "a Lock stands and holds the Number")
	var divider := BattleSim.Enemy.new()
	divider.id = sim._next_id
	sim._next_id += 1
	divider.kind = "divider"
	divider.wave = sim.wave
	divider.max_health = 1.0
	divider.health = 1.0
	divider.divisor = 1.5
	divider.distance = 0.0
	divider.stop_at = 3.0
	divider.mass = 1.0
	sim.enemies.append(divider)
	sim.step()
	check(sim.divider_held > 0.0, "and a Divider's bite is held back")
	sim.spawns.schedule_wave()
	var saved: Dictionary = json(Snapshot.capture(sim))
	var again := Snapshot.restore(saved)
	check(again != null, "a snapshot with a Lock parses")
	if again == null: return
	check(again.locked and again.divider_held == sim.divider_held and again.lock == sim.lock, "the Lock's hold, its numbers and the held bite come back")
	check(Snapshot.capture(again).digest == saved.digest, "every saved field round trips")
	for i in range(600):
		sim.step()
		again.step()
	check(Snapshot.capture(sim).digest == Snapshot.capture(again).digest, "exact continuation with a Lock: %s" % difference(json(Snapshot.capture(sim)), json(Snapshot.capture(again))))
	var state: Dictionary = RunConfig.unpack(saved)
	state.state.lock = {}
	var broken := RunConfig.pack(state)
	broken.version = Snapshot.VERSION
	check(Snapshot.restore(broken) == null, "a snapshot without the Lock's numbers is rejected")


func test_save_migration_and_future_protection() -> void:
	DirAccess.remove_absolute(PATH)
	DirAccess.remove_absolute(PATH + ".v1-backup.json")


	var old := {"version": 1, "workshop": {"coins": 123.5, "levels": {"health": 3}, "best_wave": 100, "best_number": 42.0, "runs": 2}}
	write(old)
	var p := Save.load_progress(PATH)
	check(p.workshop.coins == 1783.5 and p.gems == 45 and p.workshop.level("health") == 3, "v1 migration preserves progress and grants newly introduced rewards")
	check(not p.tier_open(2) and FileAccess.file_exists(PATH + ".v1-backup.json"), "migration keeps backup and does not assume clear")
	check(Save.save_progress(p, PATH), "migration writes current schema")
	var loaded := Save.load_progress(PATH)
	check(loaded.to_dict() == p.to_dict() and loaded.observe(1, 100).is_empty(), "current schema round trip without duplicate rewards")
	check(Save.save_workshop(loaded.workshop, PATH) and Save.load_progress(PATH).gems == 45, "Workshop-only tools preserve other progress")
	var future := {"version": 999, "workshop": {"coins": 999999.0}, "progression": {"future": true}}
	write(future)
	var exact := FileAccess.get_file_as_string(PATH)
	loaded = Save.load_progress(PATH)
	check(not loaded.writable and not loaded.notice.is_empty() and Save.load_run(PATH).is_empty(), "future save enters protected state")
	check(not Save.save_progress(loaded, PATH) and not Save.save_workshop(Workshop.new(), PATH), "future save blocks both writers")
	check(FileAccess.get_file_as_string(PATH) == exact, "future save stays byte-identical at original path")
	write({"version": 2, "workshop": {"coins": 50.0}})
	loaded = Save.load_progress(PATH)
	check(not loaded.writable and loaded.workshop.coins == 50.0, "missing current progression stays protected")
	var damaged := {"version": Save.VERSION, "workshop": p.workshop.to_dict(), "progression": p.to_dict()}
	damaged.workshop.levels["retired_row"] = 5
	write(damaged)
	var bytes := FileAccess.get_file_as_string(PATH)
	loaded = Save.load_progress(PATH)
	check(not loaded.writable and not Save.save_progress(loaded, PATH) and FileAccess.get_file_as_string(PATH) == bytes, "unsupported current permanent progress is never silently dropped")
	DirAccess.remove_absolute(PATH)
	DirAccess.remove_absolute(PATH + ".v1-backup.json")


func write(value) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "", true, true))
	file.close()


func test_protected_active_save_shows_home() -> void:
	write({"version": 2, "workshop": {"coins": 50.0}, "run": RunReport.build(BattleSim.new(3))})
	var main := Main.new()
	main.save_path = PATH
	main.log_path = "user://foundation_log.jsonl"
	main.settings_path = "user://foundation_settings.json"
	root.add_child(main)
	check(main._screen is Home and not main._screen._note.text.is_empty(), "protected active save shows recovery Home, not an empty screen")
	main._save()
	check(FileAccess.file_exists(PATH) and not main.progression.writable, "protected UI leaves the file untouched")
	main.free()
	DirAccess.remove_absolute(PATH)


func test_direct_screen_resume_and_home() -> void:
	var first := BattleScreen.new()
	first.workshop = Workshop.new()
	first.workshop.levels = {"health": 100}
	root.add_child(first)
	first.set_process(false)
	first.start_run(6)
	first._process(10.0)
	var saved: Dictionary = json(first.run_state())
	var coins := first.workshop.coins
	var second := BattleScreen.new()
	second.workshop = first.workshop
	second.resume = saved
	root.add_child(second)
	second.set_process(false)
	check(second.sim != null and second._replay == null and second.sim.ticks == first.sim.ticks, "screen resumes snapshot directly")
	second._process(0.0)
	check(first.workshop.coins == coins, "direct resume never banks twice")
	first.free()
	second.free()
	var p := Progression.new()
	p.workshop.runs = 1
	p.observe(1, 30, 29)
	var home := Home.new()
	home.workshop = p.workshop
	home.progression = p
	root.add_child(home)
	check(home._gems.text == "◆ 10" and not home._daily.disabled, "Home shows Gems and claim")
	p.claim_daily()
	home.refresh()
	check(home._daily.disabled and home._milestones_list.get_child_count() > 10, "claimed state and wave milestones visible")
	home.free()


func test_supported_horizon() -> void:
	var sim := BattleSim.new(1, {"health": 6000})
	sim.enemies.clear()
	sim.spawns.schedule.clear()
	sim.wave = TowerData.last_wave()
	sim.wave_clock = TowerData.wave_seconds() - BattleSim.TICK * 0.5
	sim.step()
	check(not sim.alive and sim.killed_by == "data_limit" and sim.wave == TowerData.last_wave(), "run ends safely at data horizon instead of farming a flat plateau")


func difference(a, b, path := "") -> String:
	if a is Dictionary and b is Dictionary:
		for key in a:
			if key == "digest": continue
			if not b.has(key): return path + "." + key + " missing"
			var found := difference(a[key], b[key], path + "." + key)
			if not found.is_empty(): return found
		return ""
	if a is Array and b is Array:
		if a.size() != b.size(): return path + " size differs"
		for i in range(a.size()):
			var found := difference(a[i], b[i], path + "[%d]" % i)
			if not found.is_empty(): return found
		return ""
	return "" if a == b else "%s: %s / %s" % [path, a, b]
