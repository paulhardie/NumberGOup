extends SceneTree
## Frozen bytes exercise the real loader; no fixture is built by today's code.
## Every write is in a unique scratch directory under run_godot.sh's user://.
const Save = preload("res://src/tower/save.gd")
const Progression = preload("res://src/tower/progression.gd")
const Snapshot = preload("res://src/tower/battle_snapshot.gd")
const RunReport = preload("res://src/tower/run_report.gd")
const BattleScreen = preload("res://src/ui/battle_screen.gd")
const FIXTURES := "res://tests/fixtures/saves/"
const VALID := ["v1.json", "v2.json", "v3-pre-d158.json", "v3-current.json", "v4-current.json", "v3-fresh.json", "v3-large-coins.json"]
# Measured by each fixture's original build, after 600 further ticks.
# A second restore by today's code would share any restoration regression.
const CONTINUATION := {
	"v3-pre-d158.json": "0d230094679a2530020b39d2b988fba7bcbdcf1fe791ff6071f40edb0f1aee57",
	"v3-current.json": "ada1fa4059a8a470e407c52b5fdee5f8f63df74ef367570546419659b7917888",
	"v4-current.json": "91b51b0c423f766c9d560011510e36b69f8c0e1231bef97ab19f4517e9874401",
}
const PROTECTED := ["future.json", "nan-string.json", "huge-string.json", "missing-progression.json", "unknown-rank.json", "damaged-cards.json"]
const UNREADABLE := ["non-integer-version.json", "truncated.json", "missing-workshop.json", "empty.json"]
var scratch := "user://save-fixtures-173-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
var checks := 0
var failures: Array[String] = []


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)


## Compare declared fields, allowing later schemas to add optional fields.
func fields(expected, actual, label: String) -> void:
	if expected is Dictionary:
		check(actual is Dictionary, label + " remains a dictionary")
		if not actual is Dictionary: return
		for key in expected:
			check(actual.has(key), label + "." + str(key) + " exists")
			if actual.has(key): fields(expected[key], actual[key], label + "." + str(key))
	else:
		check(Save._view(actual) == Save._view(expected), label + " preserved")


func copy_fixture(name: String) -> String:
	var source := FIXTURES + name
	check(FileAccess.file_exists(source), name + " is committed on disk")
	var path := scratch.path_join(name)
	check(DirAccess.copy_absolute(source, path) == OK, name + " copies into scratch")
	return path


func run() -> void:
	if DirAccess.make_dir_recursive_absolute(scratch) != OK:
		printerr("FAIL: couldn't create the scratch fixture directory")
		quit(1)
		return
	for name in VALID: test_valid(name)
	for name in PROTECTED: test_protected(name)
	for name in UNREADABLE: test_unreadable(name)
	# Only this suite owns this unique directory; leave no test saves behind.
	for name in DirAccess.get_files_at(scratch):
		check(DirAccess.remove_absolute(scratch.path_join(name)) == OK, "scratch file removed: " + name)
	check(DirAccess.remove_absolute(scratch) == OK, "scratch directory removed")
	for failure in failures: printerr("FAIL: ", failure)
	print("%s: frozen save fixtures (%d files, %d checks)" % ["PASS" if failures.is_empty() else "FAIL", VALID.size() + PROTECTED.size() + UNREADABLE.size(), checks])
	quit(0 if failures.is_empty() else 1)


func test_valid(name: String) -> void:
	var path := copy_fixture(name)
	var bytes := FileAccess.get_file_as_bytes(FIXTURES + name)
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(saved is Dictionary, name + " parses")
	if not saved is Dictionary: return
	var p := Save.load_progress(path)
	check(p.writable and p.notice.is_empty(), name + " loads writable without repair")
	check(FileAccess.get_file_as_bytes(path) == bytes, name + " load doesn't rewrite input")
	if int(saved.version) in Save.OLDER:
		check(FileAccess.get_file_as_bytes(path + ".v%d-backup.json" % int(saved.version)) == bytes, name + " migration backup is byte exact")
	var expected_workshop: Dictionary = saved.workshop.duplicate(true)
	var expected_progression: Dictionary
	if int(saved.version) == 1:
		# Hand checked against the known free wave table: reaching 100 is not
		# clearing it; only 10/20/30/40/50/80/90 pay on this legacy best.
		expected_workshop.coins = 2894.5
		expected_progression = {"gems": 45, "records": {"1": {"reached": 100, "cleared": 99}},
			"claimed": ["1:10", "1:20", "1:30", "1:40", "1:50", "1:80", "1:90"],
			"last_daily_day": -1, "clock": -1.0,
			"research": {"slots": 1, "levels": {}, "effects": {}, "jobs": []},
			"cards": {"copies": {}, "slots": 1, "equipped": []}}
	else:
		expected_progression = saved.progression.duplicate(true)
		if int(saved.version) == 2:
			expected_progression.cards = {"copies": {}, "slots": 1, "equipped": []}
	fields(expected_workshop, p.workshop.to_dict(), name + " Workshop")
	fields(expected_progression, p.to_dict(), name + " progression")
	var active := Save.load_run(path)
	fields(saved.get("run", {}), active, name + " active record")
	if not active.is_empty(): test_active(name, p, active)
	check(Save.save_progress(p, path, active), name + " saves atomically")
	check(int(JSON.parse_string(FileAccess.get_file_as_string(path)).version) == Save.VERSION, name + " writes current schema")
	var loaded := Save.load_progress(path)
	check(loaded.writable and loaded.notice.is_empty(), name + " reload remains writable")
	fields(expected_workshop, loaded.workshop.to_dict(), name + " reloaded Workshop")
	fields(expected_progression, loaded.to_dict(), name + " reloaded progression")
	fields(active, Save.load_run(path), name + " reloaded active record")
	# Whole current state must also survive, including fields added since a
	# fixture was frozen. Neither migration nor a reload may claim twice.
	fields(p.workshop.to_dict(), loaded.workshop.to_dict(), name + " full round trip Workshop")
	fields(p.to_dict(), loaded.to_dict(), name + " full round trip progression")
	for tier in loaded.records:
		var record: Dictionary = loaded.records[tier]
		check(loaded.observe(int(tier), int(record.reached), int(record.cleared)).is_empty(), name + " wave rewards cannot pay twice")
	fields(expected_workshop, loaded.workshop.to_dict(), name + " after repeated rewards")
	fields(expected_progression, loaded.to_dict(), name + " after repeated rewards")
	if name == "v3-large-coins.json":
		check(loaded.workshop.spend_coins(1e20) and loaded.workshop.coins == 1000.0, "frozen Coin compensation preserves 1,000 beside 1e20")
	if name == "v1.json": check(not loaded.tier_open(2), "legacy reached 100 does not unlock Tier 2")
	check(FileAccess.get_file_as_bytes(FIXTURES + name) == bytes, name + " repository fixture was never changed")


func test_active(name: String, p: Progression, active: Dictionary) -> void:
	var number_cash := name != "v3-pre-d158.json"
	check(bool(active.start.tuning.get("number_cash", false)) == number_cash, name + " frozen run has its original Cash rules")
	check(RunReport.is_replayable(active), name + " frozen run can replay")
	check(RunReport.matches(active, RunReport.replay(active)), name + " independent replay matches frozen result")
	var screen := BattleScreen.new()
	screen.workshop = p.workshop
	screen.progression = p
	screen.resume = active
	var failure := [""]
	screen.resume_failed.connect(func(_saved, reason): failure[0] = reason)
	root.add_child(screen)
	screen.set_process(false)
	check(screen.sim != null and failure[0] == "", name + " actual screen resumes without recovery")
	if screen.sim != null:
		check(screen.sim.number_cash == number_cash, name + " screen retains original Cash rules")
		check(Snapshot.capture(screen.sim).digest == active.snapshot.digest, name + " screen adopts exact frozen state")
		for tick in range(600):
			screen.sim.step()
		check(Snapshot.capture(screen.sim).digest == CONTINUATION[name], name + " resumed screen matches its original build after 600 ticks")
	screen.free()


func test_protected(name: String) -> void:
	var path := copy_fixture(name)
	var bytes := FileAccess.get_file_as_bytes(path)
	var p := Save.load_progress(path)
	check(not p.writable and not p.notice.is_empty(), name + " blocks writes with recovery notice")
	if name == "future.json": check(Save.load_run(path).is_empty(), "future schema never exposes its active run")
	check(not Save.save_progress(p, path), name + " refuses account writes")
	check(not Save.save_workshop(p.workshop, path), name + " refuses Workshop-only writes")
	var loaded := Save.load_progress(path)
	check(not loaded.writable and not loaded.notice.is_empty(), name + " repeated load stays protected")
	check(not FileAccess.file_exists(path + ".tmp"), name + " creates no replacement file")
	check(FileAccess.get_file_as_bytes(path) == bytes, name + " original stays byte identical at original path")
	check(FileAccess.get_file_as_bytes(FIXTURES + name) == bytes, name + " repository fixture was never changed")


func test_unreadable(name: String) -> void:
	var path := copy_fixture(name)
	var bytes := FileAccess.get_file_as_bytes(path)
	var p := Save.load_progress(path)
	check(p.writable and not p.notice.is_empty(), name + " offers a fresh account with recovery notice")
	check(not FileAccess.file_exists(path), name + " unreadable original moves aside")
	var backups: Array[String] = []
	var prefix := name.get_basename() + ".unreadable-"
	for file in DirAccess.get_files_at(scratch):
		if file.begins_with(prefix): backups.append(file)
	check(backups.size() == 1, name + " has exactly one recovery copy")
	if backups.size() != 1: return
	var backup := scratch.path_join(backups[0])
	check(FileAccess.get_file_as_bytes(backup) == bytes, name + " recovery copy preserves every original byte")
	var fresh := Progression.new()
	fields(fresh.workshop.to_dict(), p.workshop.to_dict(), name + " fresh Workshop")
	fields(fresh.to_dict(), p.to_dict(), name + " fresh progression")
	check(Save.save_progress(p, path), name + " fresh account can save")
	var loaded := Save.load_progress(path)
	check(loaded.writable and loaded.notice.is_empty(), name + " fresh account reloads normally")
	fields(p.workshop.to_dict(), loaded.workshop.to_dict(), name + " fresh Workshop round trip")
	fields(p.to_dict(), loaded.to_dict(), name + " fresh progression round trip")
	check(FileAccess.get_file_as_bytes(backup) == bytes, name + " fresh save never overwrites recovery copy")
	check(FileAccess.get_file_as_bytes(FIXTURES + name) == bytes, name + " repository fixture was never changed")
