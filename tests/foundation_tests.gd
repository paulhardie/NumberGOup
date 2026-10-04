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
const NavBar = preload("res://src/ui/nav_bar.gd")
const WorkshopScreen = preload("res://src/ui/workshop_screen.gd")
const ActivityLog = preload("res://src/tower/activity_log.gd")
const Cards = preload("res://src/tower/cards.gd")
const CardsScreen = preload("res://src/ui/cards_screen.gd")
const Overlay = preload("res://src/ui/overlay.gd")
const HoldToRead = preload("res://src/ui/hold_to_read.gd")
const UpgradeInfo = preload("res://src/ui/upgrade_info.gd")
const Palette = preload("res://src/ui/palette.gd")
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
	var window := root.size
	for method in get_method_list():
		if String(method.name).begins_with("test_"):
			await call(method.name)
			# Tests of real input size the window like a phone; the rest don't care.
			root.size = window
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


## Berserker and Super Tower (candidate cards) keep their state in what a saved
## battle already carries (what the Number lost, the cooldowns), so a battle
## saved mid-burst or off one continues exactly.
func test_snapshot_keeps_berserker_and_super_tower() -> void:
	var rules: Array = []
	for id in ["berserker", "super_tower"]:
		rules.append_array(Cards.effects_at(id, 7))
	for stop_at in [300, 700]:
		# A big Number with three enemies already at it, so it is hit.
		var sim := BattleSim.new(3, {"health": 200}, BattleSim.START_GROUPS, 1, [], rules)
		for i in range(3):
			sim._place("basic", float(i))
			sim.enemies[-1].distance = sim.enemies[-1].stop_at
		for i in range(stop_at): sim.step()
		check(sim.cooldowns.time_left("super_tower_wait") > 0.0, "Super Tower has started its cycle by tick %d" % stop_at)
		var saved: Dictionary = json(Snapshot.capture(sim))
		var again := Snapshot.restore(saved)
		check(again != null, "a battle with the candidate rules restores at tick %d" % stop_at)
		if again == null: continue
		for i in range(900):
			sim.step()
			again.step()
		check(sim.damage_absorbed() > 0.0, "the Number absorbed something, so Berserker had a bonus to carry")
		check(Snapshot.capture(sim).digest == Snapshot.capture(again).digest, "exact continuation from tick %d: %s" % [stop_at, difference(json(Snapshot.capture(sim)), json(Snapshot.capture(again)))])


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


## D146: Cards are drawn for Gems once wave 20 opens them, level by copies,
## fill bought slots, and go into a run's frozen starting build.
func test_cards_draw_level_equip_and_reach_a_run() -> void:
	var p := Progression.new()
	p.gems = 1000
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	check(p.draw_card(rng) == "" and p.gems == 1000, "no draw before Cards open, and no Gems taken")
	p.observe(1, 20, 19)
	p.gems = 19
	check(p.draw_card(rng) == "" and p.gems == 19, "a draw waits for its 20 Gems")
	p.gems = 1000
	var id := p.draw_card(rng)
	check(id in Cards.built_ids() and p.cards.copies[id] == 1 and p.cards.level(id) == 1 and p.gems == 980, "a draw gives a built card's first copy for 20 Gems: %s" % id)
	check([0, 1, 2, 3, 7, 8, 79, 80].map(func(n): return Cards.level_for(n)) == [0, 1, 1, 2, 2, 3, 6, 7], "levels by the wiki's copies, 80 to max")
	# Every built card can be drawn, by rarity first, until all are maxed.
	var all := Cards.new()
	var seen := {}
	var rares := 0
	var draws := 0
	while all.can_draw():
		var got := all.draw(rng)
		seen[got] = true
		draws += 1
		if Cards.card(got).rarity == "rare" and draws <= 200:
			rares += 1
	check(seen.size() == Cards.built_ids().size() and draws == 80 * Cards.built_ids().size(), "every built card drawn, each to 80 copies: %d draws" % draws)
	check(all.draw(rng) == "" and Cards.built_ids().all(func(each): return all.maxed(each)), "nothing more to draw once all are maxed")
	check(rares >= 15 and rares <= 60, "rares come about a sixth of the time while commons last: %d of 200" % rares)
	check(not Cards.built("death_ray") and not Cards.built_ids().has("enemy_balance"), "unbuilt cards are never drawn")
	# Slots and the loadout.
	var cards := p.cards
	cards.copies = {"damage": 3, "cash": 1, "free_upgrades": 1}
	check(cards.equip("damage") and not cards.equip("cash") and not cards.equip("health"), "one free slot; unowned cards can't be equipped")
	check(cards.slot_price() == 50 and p.buy_card_slot() and cards.slots == 2 and p.gems == 930, "the second slot costs 50 Gems")
	check(cards.equip("cash") and not cards.equip("free_upgrades") and not cards.equip("cash"), "two slots, each card once")
	cards.unequip("cash")
	check(cards.equip("free_upgrades") and cards.equipped == ["damage", "free_upgrades"], "taken off, its slot is free again")
	p.gems = 0
	check(not p.buy_card_slot() and cards.slots == 2, "a slot waits for its Gems")
	var full := Cards.new()
	full.slots = Cards.built_ids().size()
	check(full.slot_price() == -1, "no slot is sold beyond one for each built card")
	var odds := Cards.new().odds()
	check(odds.keys() == ["common", "rare"] and is_equal_approx(odds.common + odds.rare, 1.0) and is_equal_approx(odds.rare, 0.17 / 0.97),
		"with no epic built, a draw's real odds are The Tower's among common and rare: %s" % [odds])
	check(CardsScreen.odds_text(odds) == "Common 82% · Rare 18%", "and the screen shows them: %s" % CardsScreen.odds_text(odds))
	var stat_effects := p.run_effects()
	check(stat_effects.size() == 4 and stat_effects[0] == {"stat": "damage", "op": "multiply", "value": 2.0, "source": "card:damage", "domain": "stat"},
		"a level-2 Damage card multiplies Damage by 2: %s" % [stat_effects])
	check(stat_effects.slice(1).all(func(effect): return effect.op == "add" and is_equal_approx(effect.value, 0.04) and effect.source == "card:free_upgrades"),
		"Free Upgrades adds 4% to each free upgrade chance")
	cards.unequip("free_upgrades")
	cards.equip("cash")
	check(p.run_effects("rule") == [{"domain": "rule", "stat": "cash_multiplier", "op": "multiply", "value": 1.2, "source": "card:cash"}], "Cash is a rule effect")
	# A run starts with them, frozen in its starting build.
	var screen := BattleScreen.new()
	screen.workshop = p.workshop
	screen.progression = p
	root.add_child(screen)
	screen.set_process(false)
	var plain := BattleSim.new(screen.sim.run_seed)
	check(is_equal_approx(screen.sim.stat("damage"), plain.stat("damage") * 2.0) and is_equal_approx(screen.sim.rules.value("cash_multiplier"), 1.2), "the run's Damage and Cash carry the cards")
	check(RunConfig.valid(screen.sim.start_config()) and screen.sim.start_config().effects.any(func(effect): return effect.source == "card:damage"), "and its frozen build records them")
	var saved: Dictionary = json(screen.run_state())
	cards.unequip("damage")
	var resumed := BattleScreen.new()
	resumed.workshop = p.workshop
	resumed.progression = p
	resumed.resume = saved
	root.add_child(resumed)
	resumed.set_process(false)
	check(resumed.sim != null and is_equal_approx(resumed.sim.stat("damage"), plain.stat("damage") * 2.0), "a resumed run keeps the cards it began with, whatever is equipped now")
	screen.free()
	resumed.free()


## D146: save version 3 holds Cards; a version-2 save migrates to an empty
## collection with a byte-exact backup, and damaged Cards are protected.
func test_cards_save_and_version_two_migration() -> void:
	for extra in ["", ".v2-backup.json"]:
		DirAccess.remove_absolute(PATH + extra)
	var p := Progression.new()
	p.observe(1, 25, 24)
	p.gems = 300
	p.cards.copies = {"damage": 8, "coins": 1}
	p.cards.slots = 2
	p.cards.equipped.assign(["coins", "damage"])
	check(Save.save_progress(p, PATH), "Cards save")
	var loaded := Save.load_progress(PATH)
	check(loaded.writable and loaded.to_dict() == p.to_dict() and loaded.cards.level("damage") == 3 and loaded.cards.equipped == ["coins", "damage"], "and load exactly: %s" % [loaded.cards.to_dict()])
	check(JSON.parse_string(FileAccess.get_file_as_string(PATH)).version == 3, "as version 3")
	var older := Progression.new()
	older.observe(1, 25, 24)
	older.gems = 40
	var v2_progression := older.to_dict()
	v2_progression.erase("cards")
	write({"version": 2, "workshop": older.workshop.to_dict(), "progression": v2_progression})
	var bytes := FileAccess.get_file_as_string(PATH)
	loaded = Save.load_progress(PATH)
	check(loaded.writable and loaded.gems == 40 and loaded.best_wave(1) == 25 and loaded.cards.copies.is_empty() and loaded.cards.slots == 1, "version 2 migrates with its Gems and records, and no Cards")
	check(FileAccess.get_file_as_string(PATH + ".v2-backup.json") == bytes, "keeping a byte-exact backup")
	check(Save.save_progress(loaded, PATH) and Save.load_progress(PATH).writable, "and writes version 3")
	var claimed_cards := v2_progression.duplicate(true)
	claimed_cards.cards = {"copies": {"damage": 80}, "slots": 22, "equipped": ["damage"]}
	write({"version": 2, "workshop": older.workshop.to_dict(), "progression": claimed_cards})
	bytes = FileAccess.get_file_as_string(PATH)
	loaded = Save.load_progress(PATH)
	check(not loaded.writable and FileAccess.get_file_as_string(PATH) == bytes, "a version-2 save claiming Cards, which no version-2 build wrote, is protected")
	for broken in [{"copies": {"damage": 81}}, {"copies": {"retired_card": 3}}, {"copies": {"damage": 1}, "equipped": ["health"]},
			{"slots": 0}, {"slots": 23}, {"copies": {"damage": 1.5}}]:
		var damaged := {"version": Save.VERSION, "workshop": p.workshop.to_dict(), "progression": p.to_dict()}
		var saved_cards := {"copies": {}, "slots": 1, "equipped": []}
		saved_cards.merge(broken, true)
		damaged.progression.cards = saved_cards
		write(damaged)
		bytes = FileAccess.get_file_as_string(PATH)
		loaded = Save.load_progress(PATH)
		check(not loaded.writable and not Save.save_progress(loaded, PATH) and FileAccess.get_file_as_string(PATH) == bytes, "damaged Cards are protected, never dropped: %s" % [broken])
	var missing := {"version": Save.VERSION, "workshop": p.workshop.to_dict(), "progression": p.to_dict()}
	missing.progression.erase("cards")
	write(missing)
	check(not Save.load_progress(PATH).writable, "a version-3 save without Cards is damaged")
	for extra in ["", ".v2-backup.json"]:
		DirAccess.remove_absolute(PATH + extra)


## D146: the Cards screen draws, buys a slot and equips, saying so each time.
func test_the_cards_screen() -> void:
	var p := Progression.new()
	p.observe(1, 20, 19)
	p.gems = 100
	var screen := CardsScreen.new()
	screen.workshop = p.workshop
	screen.progression = p
	root.add_child(screen)
	await process_frame
	screen.rng.seed = 3
	var said: Array[Dictionary] = []
	var saves := [0]
	screen.activity.connect(func(entry): said.append(entry))
	screen.changed.connect(func(): saves[0] += 1)
	check(screen.rows.size() == Cards.built_ids().size(), "a row for every built card")
	check(screen._active_grid.get_child_count() == 1 and screen._active_grid.get_child(0).disabled, "a fresh collection shows its empty active slot")
	var id := screen.draw()
	check(id != "" and p.gems == 80 and screen.drawn_panel != null and said[-1].kind == "card_draw" and saves[0] == 1, "a draw shows the card and saves")
	check(screen.rows.size() == Cards.built_ids().size() and screen.rows.all(func(row): return row.button.get_parent() is GridContainer), "the cards sit in a grid (D147)")
	var tile: Button = screen.rows.filter(func(row): return row.id == id)[0].button
	tile.pressed.emit()
	check(screen.info_panel != null and screen.drawn_panel == null and screen.info_equip.text == "Equip", "a tap opens the card, replacing the draw's panel")
	screen.info_equip.pressed.emit()
	check(p.cards.is_equipped(id) and said[-1].kind == "card_equip" and screen.info_panel == null, "its Equip equips it and closes")
	var other: String = Cards.built_ids().filter(func(each): return each != id)[0]
	screen.rows.filter(func(row): return row.id == other)[0].button.pressed.emit()
	check(screen.info_equip.disabled and screen.info_equip.text in ["Not found", "No free slot"], "an unfound card can't be equipped: %s" % screen.info_equip.text)
	Overlay.close_current(screen)
	check(screen.info_panel == null, "and closes")
	check(screen.toggle(id) and not p.cards.is_equipped(id), "toggling takes it off")
	check(screen.toggle(id) and p.cards.is_equipped(id), "and back on")
	check(screen.buy_slot() and p.cards.slots == 2 and p.gems == 30 and said[-1].kind == "card_slot", "a slot is bought")
	check(screen._active_grid.get_child_count() == 2 and not screen._active_grid.get_child(0).disabled and screen._active_grid.get_child(1).disabled,
		"the active grid shows the equipped card and the bought empty slot")
	screen._active_grid.get_child(0).pressed.emit()
	check(screen.info_panel != null and screen.info_equip.text == "Remove", "an active card opens the same removable details")
	Overlay.close_current(screen)
	check(screen.toggle(id) and not p.cards.is_equipped(id), "and a second tap takes it off")
	check(screen._active_grid.get_children().all(func(slot): return slot.disabled), "removing the card clears the active slots")
	check(Save.save_progress(p, PATH), "screen actions save through the existing contract")
	var loaded := Save.load_progress(PATH)
	check(loaded.to_dict() == p.to_dict(), "draw, slot and equip changes survive save/reload")
	for suffix in ["", ".bak"]:
		DirAccess.remove_absolute(PATH + suffix)
	check(CardsScreen.describe("damage", 1) == "×1.50" and CardsScreen.describe("critical_chance", 1) == "+5%" and CardsScreen.describe("free_upgrades", 7) == "+10% each",
		"values read as The Tower writes them: %s" % CardsScreen.describe("damage", 1))
	screen.free()


func test_the_cards_screen_with_a_complete_collection() -> void:
	var p := Progression.new()
	p.observe(1, 30, 29)
	p.gems = 0
	p.cards.slots = Cards.built_ids().size()
	for id in Cards.built_ids():
		p.cards.copies[id] = int(Cards.data().copies_to_level[-1])
	p.cards.equipped.assign(Cards.built_ids())
	var screen := CardsScreen.new()
	screen.workshop = p.workshop
	screen.progression = p
	root.add_child(screen)
	await process_frame
	check(screen._draw_button.disabled and not screen._slot_button.visible, "a complete collection cannot draw or buy unused slots")
	check(screen._active_grid.get_child_count() == Cards.built_ids().size(), "every equipped card has an active slot")
	for index in [0, 1, Cards.built_ids().size() - 1]:
		screen._active_grid.get_child(index).pressed.emit()
		var expected := String(Cards.card(Cards.built_ids()[index]).name)
		check(screen.info_equip.text == "Remove" and screen.info_panel.find_children("*", "Label", true, false).any(func(label): return label.text == expected),
			"active slot %d opens its own card: %s" % [index, expected])
		Overlay.close_current(screen)
	screen._active_grid.get_child(1).pressed.emit()
	screen.info_equip.pressed.emit()
	check(not p.cards.is_equipped(Cards.built_ids()[1]) and p.cards.is_equipped(Cards.built_ids()[0])
		and p.cards.equipped.size() == Cards.built_ids().size() - 1 and screen._active_grid.get_child(-1).disabled,
		"removing the chosen card from a full collection leaves a visible empty slot")
	screen.queue_free()
	await process_frame


## What a screen's menus and pop-ups are built from (D151). Input here is real:
## it goes through the window's own GUI routing, as a mouse or a touch does.
func _mouse(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event)


func _drag(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event)


func _touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	Input.parse_input_event(event)


func _centre(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


func _tap(control: Control) -> void:
	_mouse(_centre(control), true)
	_mouse(_centre(control), false)


func _gesture_of(control: Control) -> Node:
	for child in control.get_children():
		if child.get_script() == HoldToRead:
			return child
	return null


## Presses `control` and keeps it down long enough to be a hold.
func _hold(control: Control) -> void:
	_mouse(_centre(control), true)
	_gesture_of(control)._process(HoldToRead.HOLD_SECONDS)


func _texts(node: Node) -> Array:
	return node.find_children("*", "Label", true, false).filter(func(label): return label.is_visible_in_tree()).map(func(label): return label.text)


## A headless window is 64 points square, too small to be pressed anywhere:
## input tests size it as the game's phone canvas.
func _phone() -> void:
	root.size = Vector2i(390, 844)


## A host with a button beneath, for tests of what an overlay blocks.
func _stage() -> Dictionary:
	_phone()
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var under := Button.new()
	under.position = Vector2(20, 400)
	under.size = Vector2(200, 80)
	host.add_child(under)
	var presses := [0]
	under.pressed.connect(func(): presses[0] += 1)
	return {"host": host, "under": under, "presses": presses}


func test_a_tap_acts_and_a_hold_reads() -> void:
	var stage := _stage()
	var host: Control = stage.host
	var button := Button.new()
	button.position = Vector2(20, 100)
	button.size = Vector2(200, 80)
	host.add_child(button)
	var taps := [0]
	var holds := [0]
	HoldToRead.attach(button, func(): holds[0] += 1, func(): taps[0] += 1)
	await process_frame
	_tap(button)
	check(taps[0] == 1 and holds[0] == 0, "a quick press is a tap")
	_hold(button)
	check(holds[0] == 1 and taps[0] == 1, "kept down, it reads")
	_gesture_of(button)._process(5.0)
	check(holds[0] == 1, "and reads once however long it's held")
	_mouse(_centre(button), false)
	await process_frame
	check(taps[0] == 1, "the lift after a hold taps nothing")
	button.pressed.emit()
	check(taps[0] == 2, "yet the next press, however it comes, is a tap again")
	_mouse(_centre(button), true)
	_gesture_of(button)._process(HoldToRead.HOLD_SECONDS - 0.05)
	_mouse(_centre(button), false)
	await process_frame
	check(taps[0] == 3 and holds[0] == 1, "a press just short of a hold is a tap")
	_mouse(_centre(button), true)
	_drag(_centre(button) + Vector2(HoldToRead.SLOP - 2.0, 0.0))
	_gesture_of(button)._process(HoldToRead.HOLD_SECONDS)
	_mouse(_centre(button) + Vector2(HoldToRead.SLOP - 2.0, 0.0), false)
	await process_frame
	check(holds[0] == 2 and taps[0] == 3, "a little jitter still holds")
	_mouse(_centre(button), true)
	_drag(_centre(button) + Vector2(0.0, HoldToRead.SLOP + 6.0))
	_gesture_of(button)._process(HoldToRead.HOLD_SECONDS)
	_mouse(_centre(button) + Vector2(0.0, HoldToRead.SLOP + 6.0), false)
	await process_frame
	check(holds[0] == 2 and taps[0] == 4, "a drag is no hold, and a button still takes it as the press it always did")
	host.free()


func test_a_disabled_button_can_still_be_held() -> void:
	var stage := _stage()
	var host: Control = stage.host
	var button := Button.new()
	button.position = Vector2(20, 100)
	button.size = Vector2(200, 80)
	button.disabled = true
	host.add_child(button)
	var taps := [0]
	var holds := [0]
	HoldToRead.attach(button, func(): holds[0] += 1, func(): taps[0] += 1)
	await process_frame
	_tap(button)
	check(taps[0] == 0, "a disabled button isn't tapped")
	_hold(button)
	_mouse(_centre(button), false)
	await process_frame
	check(holds[0] == 1 and taps[0] == 0, "but it can be read, which is when a player most wants to")
	host.free()


func test_a_touch_taps_and_holds_once() -> void:
	var stage := _stage()
	var host: Control = stage.host
	var button := Button.new()
	button.position = Vector2(20, 100)
	button.size = Vector2(200, 80)
	host.add_child(button)
	var taps := [0]
	var holds := [0]
	HoldToRead.attach(button, func(): holds[0] += 1, func(): taps[0] += 1)
	await process_frame
	# Touches come through the input singleton, which delivers them a frame on.
	_touch(_centre(button), true)
	await process_frame
	_touch(_centre(button), false)
	await process_frame
	check(taps[0] == 1 and holds[0] == 0, "a touch is one tap, though it arrives as a touch and a mouse press")
	_touch(_centre(button), true)
	await process_frame
	_gesture_of(button)._process(HoldToRead.HOLD_SECONDS)
	_touch(_centre(button), false)
	await process_frame
	check(taps[0] == 1 and holds[0] == 1, "and a held touch reads once and taps nothing")
	host.free()


func test_a_plain_control_can_be_tapped_and_held() -> void:
	var stage := _stage()
	var host: Control = stage.host
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 100)
	panel.size = Vector2(200, 80)
	host.add_child(panel)
	var taps := [0]
	var holds := [0]
	HoldToRead.attach(panel, func(): holds[0] += 1, func(): taps[0] += 1)
	await process_frame
	_tap(panel)
	check(taps[0] == 1 and holds[0] == 0, "a panel taps when a press lifts on it")
	_hold(panel)
	_mouse(_centre(panel), false)
	await process_frame
	check(taps[0] == 1 and holds[0] == 1, "and holds, its lift tapping nothing")
	_mouse(_centre(panel), true)
	_mouse(_centre(panel) + Vector2(400, 0), false)
	await process_frame
	check(taps[0] == 1, "a press that lifts off it isn't a tap")
	_mouse(_centre(panel), true)
	_drag(_centre(panel) + Vector2(HoldToRead.SLOP + 6.0, 0.0))
	_gesture_of(panel)._process(HoldToRead.HOLD_SECONDS)
	_mouse(_centre(panel) + Vector2(HoldToRead.SLOP + 6.0, 0.0), false)
	await process_frame
	check(taps[0] == 1 and holds[0] == 1, "and a drag across it is neither a tap nor a hold")
	host.free()


func test_overlays_block_replace_and_close() -> void:
	var stage := _stage()
	var host: Control = stage.host
	var under: Button = stage.under
	var presses: Array = stage.presses
	await process_frame
	var first := Overlay.new()
	first.text("First")
	var closed := [0]
	first.closed.connect(func(): closed[0] += 1)
	check(Overlay.current(host) == null, "nothing is up before one is shown")
	first.show_over(host)
	check(Overlay.current(host) == first and first.visible, "a shown sheet is the host's current one")
	_tap(under)
	check(presses[0] == 0, "a sheet blocks what's beneath it")
	_mouse(Vector2(2, 2), true)
	_mouse(Vector2(2, 2), false)
	check(Overlay.current(host) == null and closed[0] == 1, "a tap on its shade closes it, once")
	await process_frame
	check(not is_instance_valid(first), "and a sheet that isn't kept is freed")
	var must_answer := Overlay.new(Overlay.Kind.SHEET, false)
	must_answer.text("Answer me")
	must_answer.show_over(host)
	_mouse(Vector2(2, 2), true)
	_mouse(Vector2(2, 2), false)
	check(Overlay.current(host) == must_answer, "a sheet that must be answered ignores its shade")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	check(Overlay.current(host) == must_answer, "and Escape")
	Overlay.close_current(host)
	var one := Overlay.new()
	one.text("One")
	one.show_over(host)
	var card_at := _centre(one.column.get_parent())
	_mouse(card_at, true)
	_mouse(card_at, false)
	check(Overlay.current(host) == one, "a tap on the card itself leaves it")
	var two := Overlay.new()
	var one_closed := [0]
	one.closed.connect(func(): one_closed[0] += 1)
	two.show_over(host)
	check(Overlay.current(host) == two and one_closed[0] == 1 and not one.visible, "a second sheet replaces the first")
	root.push_input(escape)
	check(Overlay.current(host) == null, "Escape closes a sheet that can be dismissed")
	host.free()
	await process_frame


func test_a_banner_blocks_nothing_and_sits_beneath_a_sheet() -> void:
	var stage := _stage()
	var host: Control = stage.host
	var under: Button = stage.under
	var presses: Array = stage.presses
	await process_frame
	var banner := Overlay.new(Overlay.Kind.BANNER, false, true)
	banner.text("Banner")
	banner.show_over(host)
	_tap(under)
	check(presses[0] == 1, "a banner leaves the screen beneath it live")
	var sheet := Overlay.new()
	sheet.show_over(host)
	check(Overlay.current(host, Overlay.Kind.BANNER) == banner and Overlay.current(host) == sheet, "a sheet and a banner can both be up")
	check(sheet.get_index() > banner.get_index(), "with the sheet above")
	var later := Overlay.new(Overlay.Kind.BANNER, false, true)
	later.show_over(host)
	check(sheet.get_index() > later.get_index() and not banner.visible, "a newer banner replaces the older and still sits under the sheet")
	banner.show_over(host)
	check(banner.visible and not later.visible and banner.get_parent() == host, "a kept banner shows again")
	banner.dismiss()
	check(not banner.visible and is_instance_valid(banner), "and closes without being freed")
	sheet.dismiss()
	host.free()
	await process_frame


func test_a_card_action_closes_first_and_then_acts() -> void:
	var stage := _stage()
	var host: Control = stage.host
	await process_frame
	var sheet := Overlay.new()
	var seen := []
	var act := sheet.action("Go", Palette.ACCENT, func(): seen.append(Overlay.current(host)))
	var stay := sheet.action("Stay", Palette.ACCENT, func(): seen.append("stayed"), false)
	sheet.show_over(host)
	stay.pressed.emit()
	check(seen == ["stayed"] and Overlay.current(host) == sheet, "an action that keeps the card leaves it up")
	act.pressed.emit()
	check(seen == ["stayed", null], "an action closes the card, then runs, so it meets a screen with nothing over it")
	host.free()
	await process_frame


func test_every_workshop_row_says_what_it_does() -> void:
	var blank: Array[String] = []
	for id in TowerData.rows():
		if String(TowerData.upgrade(id).description).strip_edges().is_empty():
			blank.append(id)
	check(blank.is_empty(), "a held row has something to read: %s" % [blank])


func test_the_upgrade_card_lays_out_a_row_and_hides_what_a_maxed_row_lacks() -> void:
	var sheet := Overlay.new()
	var info := UpgradeInfo.new(sheet, "damage", Palette.COIN)
	info.update(3, 10, "12", "14", "● 120")
	var texts := _texts_unshown(sheet)
	check("Damage" in texts and String(TowerData.upgrade("damage").description) in texts, "it names the row and says what it does: %s" % [texts])
	check("3 / 10" in texts and "12" in texts and "14" in texts and "● 120" in texts, "with its level, now, next and price")
	info.update(10, 10, "20", "", "")
	var visible_texts := sheet.find_children("*", "Label", true, false).filter(func(label): return label.visible).map(func(label): return label.text)
	check("10 / 10  ·  max" in visible_texts and not ("Next level" in visible_texts) and not ("Price" in visible_texts), "a maxed row has no next level or price: %s" % [visible_texts])
	sheet.free()


func _texts_unshown(node: Node) -> Array:
	return node.find_children("*", "Label", true, false).map(func(label): return label.text)


func test_holding_a_workshop_row_reads_it_and_never_buys_it() -> void:
	_phone()
	var shop := WorkshopScreen.new()
	shop.workshop = Workshop.new()
	shop.workshop.coins = 1.0e6
	shop.progression = Progression.new(shop.workshop)
	var said: Array[Dictionary] = []
	var saves := [0]
	shop.activity.connect(func(entry): said.append(entry))
	shop.changed.connect(func(): saves[0] += 1)
	root.add_child(shop)
	await process_frame
	await process_frame
	var row: Dictionary = shop._cards.filter(func(card): return card.has("id"))[0]
	var id: String = row.id
	check(not row.button.disabled, "the row can be paid")
	_hold(row.button)
	var card := Overlay.current(shop)
	check(card != null, "holding a row opens its card")
	var texts := _texts(card)
	check(Palette.row_title(id) in texts and String(TowerData.upgrade(id).description) in texts, "naming it and saying what it does: %s" % [texts])
	check("0 / %s" % Palette.full(TowerData.max_level(id)) in texts, "and what level it's at: %s" % [texts])
	_mouse(_centre(row.button), false)
	await process_frame
	check(shop.workshop.level(id) == 0 and shop.workshop.coins == 1.0e6 and said.is_empty() and saves[0] == 0, "the lift buys nothing")
	check(Overlay.current(shop) == card, "and leaves the card up")
	Overlay.close_current(shop)
	await process_frame
	_tap(row.button)
	check(shop.workshop.level(id) == 1 and said[-1].kind == "workshop_buy" and saves[0] == 1, "a tap still buys")
	shop.workshop.coins = 0.0
	shop.refresh()
	var broke: Dictionary = shop._cards.filter(func(card): return card.has("id"))[1]
	check(broke.button.disabled, "a row that can't be paid is dimmed")
	_hold(broke.button)
	_mouse(_centre(broke.button), false)
	await process_frame
	check(Overlay.current(shop) != null and shop.workshop.level(broke.id) == 0, "and can still be read")
	Overlay.close_current(shop)
	var unlock: Dictionary = shop._cards.filter(func(card): return card.has("group"))[0]
	shop.workshop.coins = TowerData.group_price(unlock.group)
	shop.refresh()
	_hold(unlock.button)
	_mouse(_centre(unlock.button), false)
	await process_frame
	var preview := Overlay.current(shop)
	var names := _texts(preview)
	check(preview != null and "Unlocks" in names and TowerData.group_rows(unlock.group).all(func(each): return Palette.row_title(each) in names),
		"holding the next unlock says what it opens: %s" % [names])
	check(not shop.workshop.is_group_open(unlock.group) and shop.workshop.coins == TowerData.group_price(unlock.group), "without opening it")
	Overlay.close_current(shop)
	shop.free()
	await process_frame


func test_holding_a_run_upgrade_reads_it_while_the_run_goes_on() -> void:
	_phone()
	var battle := BattleScreen.new()
	battle.workshop = Workshop.new()
	root.add_child(battle)
	battle.set_process(false)
	await process_frame
	await process_frame
	var sim: BattleSim = battle.sim
	sim.cash = 1.0e6
	battle._upgrades.refresh()
	var id: String = battle._upgrades._cards.keys()[0]
	var tile: Button = battle._upgrades._cards[id].button
	_hold(tile)
	var card := Overlay.current(battle, Overlay.Kind.BANNER)
	check(card != null and card != battle._wave_info, "holding a tile opens its card, a banner")
	_mouse(_centre(tile), false)
	await process_frame
	check(sim.level(id) == 0 and sim.cash == 1.0e6, "the lift buys nothing")
	check(Overlay.current(battle, Overlay.Kind.SHEET) == null, "and nothing shades the battle")
	var level_before := sim.level(id)
	var texts := _texts(card)
	check("%d / %s" % [level_before, Palette.full(TowerData.max_level(id))] in texts and Palette.row_value(id, sim.stat(id)) in texts and Palette.row_value(id, sim.stat_with(id, 1)) in texts,
		"it reads the level, the value and what a level more gives: %s" % [texts])
	_tap(tile)
	battle._process(0.0)
	check(sim.level(id) == level_before + 1 and "%d / %s" % [level_before + 1, Palette.full(TowerData.max_level(id))] in _texts(card), "a buy beneath it updates it")
	battle._wave_info.show_for(sim)
	battle._wave_info.show_over(battle)
	check(Overlay.current(battle, Overlay.Kind.BANNER) == battle._wave_info and not card.visible, "Wave Info takes the banner's place")
	battle._wave_info.dismiss()
	_hold(tile)
	_mouse(_centre(tile), false)
	await process_frame
	var again := Overlay.current(battle, Overlay.Kind.BANNER)
	check(again != null and again != battle._wave_info, "and a held tile takes it back")
	battle.sim.wave = 40
	var met := BattleSim.Enemy.new()
	met.kind = "lock"
	battle.sim.enemies.append(met)
	battle._first_sight(0.0)
	check(not battle._sight.visible, "a new enemy's card waits while the player's own is up")
	again.dismiss()
	battle._first_sight(0.0)
	check(battle._sight.visible, "and shows once it's gone")
	battle.start_run(7)
	check(not battle._sight.visible and Overlay.current(battle, Overlay.Kind.BANNER) == null, "a new run clears what was up")
	battle.free()
	await process_frame


func test_a_stat_can_be_read_a_level_on() -> void:
	var sim := BattleSim.new(3, {"damage": 4}, BattleSim.START_GROUPS)
	check(sim.stat_with("damage", 0) == sim.stat("damage"), "no levels on is the stat as it stands")
	var promised := sim.stat_with("damage", 1)
	sim.cash = 1.0e9
	check(sim.buy("damage") and sim.stat("damage") == promised and promised > TowerData.value("damage", 0), "one on is what a buy then gives")
	var pass_through := BattleSim.new(3, {}, BattleSim.START_GROUPS, 1, [{"stat": "damage", "op": "multiply", "value": 2.0, "source": "card:damage"}])
	check(pass_through.stat_with("damage", 1) == TowerData.value("damage", 1) * 2.0, "and goes through the run's effects as the stat does")


func test_home_sheets_open_answer_and_close() -> void:
	_phone()
	var p := Progression.new()
	p.workshop.runs = 1
	var home := Home.new()
	home.workshop = p.workshop
	home.progression = p
	home.show_gift(57.0)
	root.add_child(home)
	await process_frame
	var gift := Overlay.current(home)
	check(gift != null and home._gift_panel == gift and not gift.dismissable, "the Workshop's welcome opens with Home")
	_mouse(Vector2(2, 2), true)
	_mouse(Vector2(2, 2), false)
	check(Overlay.current(home) == gift, "and isn't dismissed from its shade")
	var opened := [0]
	home.workshop_pressed.connect(func(): opened[0] += 1)
	var go: Button = gift.find_children("*", "Button", true, false).filter(func(button): return button.text == "Open the Workshop")[0]
	go.pressed.emit()
	check(opened[0] == 1 and Overlay.current(home) == null and home._gift_panel == null, "answering it opens the Workshop and puts it away")
	home._open_milestones()
	var milestones := Overlay.current(home)
	check(milestones != null and milestones == home._milestones_panel, "Milestones opens as the sheet")
	home._open_settings()
	check(Overlay.current(home) != milestones and not milestones.visible and home._milestones_panel == null, "and Settings replaces it")
	home._press_reset()
	check(home._reset_armed, "Reset asks first")
	Overlay.close_current(home)
	check(not home._reset_armed, "and asks again from the start the next time Settings opens")
	home.free()
	await process_frame


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
	home._open_milestones()
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


func test_both_bars_follow_the_milestone_table() -> void:
	var original: Array = Progression.MILESTONES
	var changed: Array = original.duplicate(true)
	for row in changed:
		if "cards" in row.get("reveals", []): row.wave = 21
		if "labs" in row.get("reveals", []): row.wave = 31
	Progression.MILESTONES = changed
	var early := NavBar.new("battle", 2, 20)
	var cards := NavBar.new("battle", 2, 21)
	var labs := NavBar.new("battle", 2, 31)
	check(not early.buttons.has("cards") and cards.buttons.has("cards") and not cards.buttons.has("labs") and labs.buttons.has("labs"), "bar reveals move with their table rows")
	var p := Progression.new()
	p.workshop.runs = 2
	p.workshop.best_wave = 500
	p.records = {"2": {"reached": 500, "cleared": 499}, "1": {"reached": 20, "cleared": 19}}
	check(not p.unlocked("cards") and not p.unlocked("labs"), "domain gates use the same rows and the right tier")
	for screen in [Home.new(), WorkshopScreen.new()]:
		screen.workshop = p.workshop
		screen.progression = p
		root.add_child(screen)
		var bars: Array = screen.find_children("*", "HBoxContainer", true, false).filter(func(node): return node is NavBar)
		check(bars.size() == 1 and not bars[0].buttons.has("cards") and not bars[0].buttons.has("labs"), "Home and Workshop use progression rather than the global Workshop best")
		screen.free()
	Progression.MILESTONES = original
	early.free()
	cards.free()
	labs.free()


func test_malformed_optional_replay_fields_recover_safely() -> void:
	var sim := BattleSim.new(5)
	var recorded: Dictionary = json(RunReport.build(sim))
	for value in [null, [], {}, "bad", INF, -1, 1.5, 2049]:
		var broken: Dictionary = recorded.duplicate(true)
		broken.result.enemies = value
		check(not RunReport.valid_record(broken) and not RunReport.matches(broken, sim), "malformed optional enemy count cannot fail inside matching")
	for value in [null, {}, "bad", [], ["1"], ["1", "2", 3], ["1", "2", "9223372036854775808"]]:
		var broken: Dictionary = recorded.duplicate(true)
		broken.result.rng = value
		check(not RunReport.valid_record(broken) and not RunReport.matches(broken, sim), "malformed optional RNG cannot fail inside matching")
	for value in [null, [], {}, "bad", INF, -1.0]:
		var broken: Dictionary = recorded.duplicate(true)
		broken.result.peak_number = value
		check(not RunReport.valid_record(broken), "malformed peak cannot grant a milestone during recovery")


## D152: the Number-as-capital trial's options validate, are recorded only
## while they are on (so every other run and snapshot is as it was), and a
## battle with a thief mid-flight restores and replays exactly.
func test_the_number_capital_trial_validates_records_and_continues() -> void:
	var on := {"thieves": true, "thief_recovery": 1.5, "thief_speed": 2.0, "thief_fade": 600.0, "thief_priority": true, "number_power": 0.3}
	check(RunConfig.valid_tuning({}) and RunConfig.valid_tuning(on), "the trial's options are valid tuning, on or absent")
	for bad in [{"thieves": 1}, {"thief_priority": "yes"}, {"thief_recovery": -0.1}, {"thief_speed": 0.0}, {"thief_fade": -1.0},
			{"number_power": 5.0}, {"number_power": INF}, {"thief_recovery": NAN}, {"thief_unknown": 1}]:
		check(not RunConfig.valid_tuning(bad), "rejected: %s" % [bad])
	var plain: Dictionary = RunConfig.unpack(Snapshot.capture(BattleSim.new(3, {"health": 500})))
	check(plain.start.tuning.size() == RunConfig.default_tuning().size() and not plain.state.has("trial"), "a run without the trial records none of it")
	var tuning := RunConfig.default_tuning()
	tuning.divider.from_wave = 1
	tuning.divider.rate_first = 1.0
	tuning.divider.rate_full = 1.0
	# Tough enough that the tower can't kill one before it lands.
	tuning.divider.health_first = 1e4
	tuning.divider.health_full = 1e4
	tuning.merge({"thieves": true, "thief_recovery": 0.5, "thief_speed": 1.5, "thief_fade": 120.0, "thief_priority": true, "number_power": 0.2})
	var sim := BattleSim.new(7, {"health": 500})
	check(sim.configure_tuning(tuning) and sim.start_config().tuning.thieves == true, "the options freeze before the first wave and are recorded")
	while sim.alive and sim.ticks < 3 * 3600 and not sim.enemies.any(func(enemy): return enemy.fleeing):
		sim.step()
	check(sim.alive and sim.thefts > 0, "a Divider reached the Number and is carrying its bite off")
	var saved: Dictionary = json(Snapshot.capture(sim))
	var again := Snapshot.restore(saved)
	check(again != null and Snapshot.capture(again).digest == saved.digest, "a battle with a thief mid-flight round trips exactly")
	if again != null:
		check(again.thief_held == sim.thief_held and again.thefts == sim.thefts and again.enemies.filter(func(enemy): return enemy.fleeing).size() == sim.enemies.filter(func(enemy): return enemy.fleeing).size(), "the hold, the ledger and the carrier come back")
		for i in range(900):
			sim.step()
			again.step()
		check(Snapshot.capture(sim).digest == Snapshot.capture(again).digest, "and continues exactly: %s" % difference(json(Snapshot.capture(sim)), json(Snapshot.capture(again))))
	var report: Dictionary = json(RunReport.build(sim))
	check(RunReport.is_replayable(report) and RunReport.matches(report, RunReport.replay(report)), "a run with the trial replays from its seed")
	for key in ["thief_held", "thefts"]:
		var state: Dictionary = RunConfig.unpack(saved)
		state.state.trial[key] = -1
		var corrupt := RunConfig.pack(state)
		corrupt.version = Snapshot.VERSION
		check(Snapshot.restore(corrupt) == null, "a negative %s in the trial's state is rejected" % key)


## D155: the fuel economy's options validate, are recorded only while on, and
## a battle with it on restores, continues and replays exactly, ledger and all.
func test_the_fuel_economy_validates_records_and_continues() -> void:
	var on := {"shot_price": 1.0, "bounty_share": 0.25, "free_bounty_share": 0.5, "base_regen": 1.0, "regen_scale": 10.0, "hold_doomed": true}
	check(RunConfig.valid_tuning(on), "the fuel economy's options are valid tuning")
	for bad in [{"shot_price": -1.0}, {"bounty_share": NAN}, {"free_bounty_share": 0.6}, {"base_regen": INF}, {"regen_scale": -0.5}, {"hold_doomed": 1}]:
		check(not RunConfig.valid_tuning(bad), "rejected: %s" % [bad])
	var plain: Dictionary = RunConfig.unpack(Snapshot.capture(BattleSim.new(3, {"health": 500})))
	check(not plain.state.has("fuel"), "a run without it saves none of its ledger")
	var sim := BattleSim.new(5, {"damage": 30, "health": 30, "health_regen": 10, "attack_speed": 10})
	check(sim.configure_tuning({"shot_price": 1.0, "bounty_share": 0.25, "base_regen": 1.0, "hold_doomed": true}), "the options freeze before the first wave")
	while sim.alive and (sim.wave < 3 or sim.shots.is_empty()):
		sim.step()
	check(sim.alive and sim.fuel_log.size() == 2 and not sim.shots.is_empty(), "a battle on wave 3 with shots in flight")
	var saved: Dictionary = json(Snapshot.capture(sim))
	var again := Snapshot.restore(saved)
	check(again != null and Snapshot.capture(again).digest == saved.digest, "it round trips exactly")
	if again != null:
		check(again.shots_paid == sim.shots_paid and again.fuel_spent == sim.fuel_spent and again.peak_wave == sim.peak_wave and again.fuel_log == sim.fuel_log,
			"the ledger comes back")
		for i in range(900):
			sim.step()
			again.step()
		check(Snapshot.capture(sim).digest == Snapshot.capture(again).digest, "and continues exactly: %s" % difference(json(Snapshot.capture(sim)), json(Snapshot.capture(again))))
	var report: Dictionary = json(RunReport.build(sim))
	check(RunReport.is_replayable(report) and RunReport.matches(report, RunReport.replay(report)), "a run with it replays from its seed")
	var state: Dictionary = RunConfig.unpack(saved)
	state.state.fuel.peak_wave = 99
	var corrupt := RunConfig.pack(state)
	corrupt.version = Snapshot.VERSION
	check(Snapshot.restore(corrupt) == null, "a peak wave past the battle's is rejected")


## D156: the Number as Cash validates, is recorded only while on, and a battle
## with it on restores, continues and replays exactly, ceiling and free levels too.
func test_the_number_as_cash_validates_records_and_continues() -> void:
	check(RunConfig.valid_tuning({"number_cash": true, "upgrades_off": true, "reserve_share": 0.5}), "its options are valid tuning")
	for bad in [{"number_cash": 1}, {"upgrades_off": "no"}, {"reserve_share": 1.0}, {"reserve_share": -0.1}, {"reserve_share": NAN}]:
		check(not RunConfig.valid_tuning(bad), "rejected: %s" % [bad])
	var plain: Dictionary = RunConfig.unpack(Snapshot.capture(BattleSim.new(3, {"health": 500})))
	check(not plain.state.has("number_cash"), "a run without it saves none of its state")
	var levels := {"damage": 30, "health": 30, "health_regen": 10}
	for id in ["free_attack_upgrade", "free_defense_upgrade", "free_utility_upgrade"]:
		levels[id] = TowerData.max_level(id)
	var sim := BattleSim.new(5, levels, BattleSim.START_GROUPS + ["free_upgrades"])
	check(sim.configure_tuning({"number_cash": true, "lock_holds_cash": true}) and sim.start_config().tuning.lock_holds_cash == true, "it freezes before the first wave and is recorded, the Lock's hold with it")
	while sim.alive and (sim.wave < 4 or sim.shots.is_empty()):
		if sim.can_buy("attack_speed"):
			sim.buy("attack_speed")
		sim.step()
	check(sim.alive and sim.run_levels.size() > 0 and not sim.free_levels.is_empty(), "a battle on wave 4 that has bought and been given levels: %s free" % [sim.free_levels])
	sim.lock_held = 3.5
	var saved: Dictionary = json(Snapshot.capture(sim))
	var again := Snapshot.restore(saved)
	check(again != null and Snapshot.capture(again).digest == saved.digest, "it round trips exactly")
	if again != null:
		check(again._ceiling == sim._ceiling and again.free_levels == sim.free_levels and again.cash == 0.0, "the ceiling and the free levels come back")
		check(again.lock_held == 3.5 and again.lock_holds_cash, "and the Cash a Lock is holding")
		for i in range(900):
			sim.step()
			again.step()
		check(Snapshot.capture(sim).digest == Snapshot.capture(again).digest, "and continues exactly: %s" % difference(json(Snapshot.capture(sim)), json(Snapshot.capture(again))))
	var report: Dictionary = json(RunReport.build(sim))
	check(RunReport.is_replayable(report) and RunReport.matches(report, RunReport.replay(report)), "a run with it replays from its seed, buys and all")
	var state: Dictionary = RunConfig.unpack(saved)
	var some: String = state.state.number_cash.free_levels.keys()[0]
	state.state.number_cash.free_levels[some] = 999
	var corrupt := RunConfig.pack(state)
	corrupt.version = Snapshot.VERSION
	check(Snapshot.restore(corrupt) == null, "more free levels than a row has are rejected")
	var stripped: Dictionary = RunConfig.unpack(saved)
	stripped.state.erase("number_cash")
	var without := RunConfig.pack(stripped)
	without.version = Snapshot.VERSION
	check(Snapshot.restore(without) == null, "a run under its rules with its Number-as-Cash state missing is rejected, not restored with a guessed ceiling")
	var added: Dictionary = RunConfig.unpack(Snapshot.capture(BattleSim.new(3, {"health": 500})))
	added.state["number_cash"] = {"ceiling": 5.0, "free_levels": {}}
	var alone := RunConfig.pack(added)
	alone.version = Snapshot.VERSION
	check(Snapshot.restore(alone) == null, "and the state without the rules is rejected too")


func test_starting_tuning_replays_and_freezes_before_wave_one() -> void:
	var tuning := RunConfig.default_tuning()
	tuning.lock.from_wave = 1
	tuning.lock.every_first = 1
	tuning.lock.health = 1e6
	tuning.divider.from_wave = 1
	tuning.divider.rate_first = 1.0
	tuning.divider.rate_full = 1.0
	tuning.divider.refill_seconds = 30.0
	var sim := BattleSim.new(7, {"health": 500})
	check(sim.configure_tuning(tuning), "measuring switches freeze before the first wave")
	tuning.lock.health = 1.0
	check(sim.start_config().tuning.lock.health == 1e6 and sim.spawns.schedule.any(func(item): return item.kind == "lock"), "a wave-one Lock uses the copied starting tuning")
	while sim.alive and sim.ticks < 3600 and not (sim.locked and sim.divider_held > 0.0): sim.step()
	check(sim.alive and sim.locked and sim.divider_held > 0.0, "a real scheduled Lock and held Divider loss are active together")
	var report: Dictionary = json(RunReport.build(sim))
	check(RunReport.is_replayable(report) and RunReport.matches(report, RunReport.replay(report)), "starting Lock and refill switches replay from the first wave")
	check(not sim.configure_tuning(RunConfig.default_tuning()), "starting switches cannot change after a tick")
	var saved: Dictionary = json(Snapshot.capture(sim))
	var again := Snapshot.restore(saved)
	check(again != null and Snapshot.capture(again).digest == saved.digest, "actual Lock and held-loss state round trips exactly")
	if again != null:
		for i in range(600):
			sim.step()
			again.step()
		check(Snapshot.capture(sim).digest == Snapshot.capture(again).digest, "scheduled Lock and refill continue exactly for 600 ticks")
	var disabled := RunConfig.default_tuning()
	disabled.lock.from_wave = 0
	disabled.divider.rate_first = 0.0
	disabled.divider.rate_full = 0.0
	check(RunConfig.valid_tuning(disabled), "disabled Lock, Divider rates and default zero refill remain valid")
	disabled.lock.every_first = 0
	check(not RunConfig.valid_tuning(disabled), "a zero Lock interval cannot reach modulo arithmetic")


func test_changed_and_damaged_run_recovery_preserves_the_account() -> void:
	var sim := BattleSim.new(4)
	sim.wave = 39
	sim.peak_number = 1500.0
	var old: Dictionary = json(RunReport.build(sim))
	old.start.rules_version = 1
	old.commands = RunConfig.pack({"start": old.start, "inputs": old.inputs})
	check(not RunReport.is_replayable(old) and RunReport.valid_record(old, true), "old declared combat rules are readable for recovery, not current equivalence")
	var legacy: Dictionary = json(RunReport.build(BattleSim.new(6)))
	legacy.erase("commands")
	for key in ["version", "rules_version", "tuning"]: legacy.start.erase(key)
	check(RunReport.is_replayable(legacy) and RunReport.matches(legacy, RunReport.replay(legacy)), "a compatible unversioned legacy record still replays")
	for damaged in [false, true]:
		var record := old.duplicate(true)
		if damaged:
			record.seed = "bad"
			record.result.wave = TowerData.last_wave()
			record.result.peak_number = 1e300
		var permanent := Workshop.new()
		permanent.coins = 100.0
		permanent.runs = 2
		permanent.best_wave = 27
		permanent.best_number = 100.0
		permanent.levels = {"health": 3}
		var p := Progression.new(permanent)
		p.observe(1, 27, 26)
		DirAccess.remove_absolute("user://recovery_test.jsonl")
		check(Save.save_progress(p, PATH, record), "recovery fixture saves")
		var main := Main.new()
		main.save_path = PATH
		main.log_path = "user://recovery_test.jsonl"
		main.settings_path = "user://recovery_settings.json"
		root.add_child(main)
		for frame in range(4): await process_frame
		check(main._screen is Home and Save.load_run(PATH).is_empty(), "incompatible or damaged run ends once and opens Home")
		var loaded := Save.load_progress(PATH)
		check(loaded.workshop.levels == permanent.levels and loaded.workshop.runs == 3, "ranks survive and the ended run is counted once")
		if damaged:
			check(loaded.workshop.coins == 110.0 and loaded.workshop.best_wave == 27 and loaded.workshop.best_number == 100.0, "damaged wave and peak cannot inflate permanent bests or milestone Coins")
			check(loaded.best_wave(1) == 27 and not loaded.unlocked("labs"), "damaged values cannot create progression unlocks")
		else:
			check(loaded.workshop.coins == 360.0 and loaded.workshop.best_wave == 39 and loaded.workshop.best_number == 1500.0, "sound old-rules recovery keeps its wave, peak and one earned Number reward")
			check(loaded.best_wave(1) == 39 and loaded.best_wave(1, true) == 38 and loaded.unlocked("labs"), "changed combat preserves reached/cleared records and Labs")
		var run_entries := ActivityLog.read(main.log_path).filter(func(entry): return entry.kind == "run")
		check(run_entries.size() == 1 and run_entries[0].resume_failed == ("damaged" if damaged else "changed"), "recovery is logged once with the right reason")
		main.free()
		await process_frame
		var coins := loaded.workshop.coins
		check(loaded.observe(1, loaded.best_wave(1), loaded.best_wave(1, true)).is_empty() and loaded.workshop.coins == coins, "reload cannot repay recovery wave rewards")
	DirAccess.remove_absolute(PATH)


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
