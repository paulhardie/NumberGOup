extends SceneTree
## Repeatable scaling measurement, not a gate. Supports --hours N (1 by
## default). Reports actual finite data limits and exact resume continuation.
const TowerData = preload("res://src/tower/tower_data.gd")
const BattleSim = preload("res://src/tower/battle_sim.gd")
const Snapshot = preload("res://src/tower/battle_snapshot.gd")
const RunReport = preload("res://src/tower/run_report.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var hours := 1.0
	if "--hours" in args:
		var at := args.find("--hours")
		if at + 1 >= args.size() or not args[at + 1].is_valid_float():
			printerr("--hours needs a finite number from 0 to 168")
			quit(1)
			return
		hours = args[at + 1].to_float()
	if not is_finite(hours) or hours <= 0.0 or hours > 168.0:
		printerr("--hours needs a finite number from 0 to 168")
		quit(1)
		return
	var groups: Array = []
	var levels := {}
	var max_cost := 0.0
	for group in TowerData.groups():
		groups.append(String(group.id))
		max_cost += float(group.unlock_coins)
	for id in TowerData.rows():
		levels[id] = mini(25, TowerData.max_level(id))
		for price in TowerData.upgrade(id).coin_prices: max_cost += float(price)
	var sim := BattleSim.new(7, levels, groups)
	var began := Time.get_ticks_usec()
	sim.run_until_dead(hours * 3600.0)
	var play_ms := (Time.get_ticks_usec() - began) / 1000.0
	var saved := Snapshot.capture(sim)
	began = Time.get_ticks_usec()
	var restored := Snapshot.restore(saved)
	var restore_ms := (Time.get_ticks_usec() - began) / 1000.0
	var report := RunReport.build(sim)
	began = Time.get_ticks_usec()
	var replayed := RunReport.replay(report)
	var replay_ms := (Time.get_ticks_usec() - began) / 1000.0
	var identical: bool = restored != null and Snapshot.capture(restored).digest == saved.digest
	if restored != null:
		for i in range(600):
			sim.step()
			restored.step()
		identical = identical and Snapshot.capture(sim).digest == Snapshot.capture(restored).digest
	print("data horizon: waves 1–%d, tiers 1–%d" % [TowerData.last_wave(), TowerData.tier_count()])
	print("last basic HP %s, attack %s; complete Workshop cost %s Coins" % [TowerData.enemy_health(TowerData.last_wave(), "basic"), TowerData.enemy_attack(TowerData.last_wave(), "basic"), max_cost])
	print("run: wave %d, %d ticks, alive %s; simulation %.2f ms" % [int(report.result.wave), int(report.result.ticks), bool(report.result.closed_mid_run), play_ms])
	print("snapshot: %d bytes, restore %.2f ms; replay %.2f ms, matches %s" % [JSON.stringify(saved).length(), restore_ms, replay_ms, RunReport.matches(report, replayed)])
	print("600-tick exact continuation: %s" % identical)
	quit(0 if identical and RunReport.matches(report, replayed) else 1)
