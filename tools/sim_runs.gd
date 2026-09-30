extends SceneTree
## Plays runs headless and prints where each ended: the measuring tool for
## the rebuild (docs/REBUILD_SPEC.md). A measurement, not a gate.
##
##   bash run_godot.sh --headless --path . -s res://tools/sim_runs.gd -- --seeds 20 --buy cheapest
##
## --buy picks how the run spends its Cash, as a stand-in for a player:
##   none      never buys (the default)
##   cheapest  buys the cheapest level it can afford, as soon as it can
##   even      buys whichever open row has the fewest levels, when it can
##   attack    only Damage and Attack Speed, cheapest first
##   core      Damage, Attack Speed, Health, Health Regen and Defense
##             Absolute, cheapest first; in a career its Workshop does the same
##   grow      core in the run; in a career its Workshop also opens the Cash and
##             Coins groups and buys Coins / Kill Bonus and Coins / Wave with the rest
##   health    60% of the Cash earned goes to Health, the rest to the cheapest
##             other core row; in a career its Workshop buys as core does
##   survival  Health only while the Number is under half the run's best, the
##             rest to the cheapest of Damage, Attack Speed and Defense
##             Absolute; in a career its Workshop buys as core does
## --cap-minutes stops a run that is still alive (default 90).
## --divider-share N scales how many Dividers come (1 is Guesses.DIVIDER's,
## 0 none) and --divider-speed N sets their speed as a share of a basic
## enemy's, and --divider-health N its health in basic enemies', for trying
## the Divider's tuning without changing the game; --divider-divisor N fixes
## its divisor at every wave. --overfill N sets how much
## of Lifesteal works past Health (0 a ceiling, 1 none), and --curve
## adds the Number at the end of every fifth wave to each run's line.
## --peak-drift N and --kill-share N try other numbers for how the Number
## grows (D111): regen's share past the run's best, and a clean kill's share
## of its Attack.
## --gains adds where the Number's gains came from: each source's share of
## all it gained, and after the slash its share of the new highs, the gains
## that lifted the Number past its best so far rather than refilling it.
##
## --workshop open plays each run with every Workshop group open at its
## first levels, --workshop max with every row at its last level too, and
## --workshop N with every row at level N (or its last, if lower): how far
## Tier 1 goes for a player who has bought that much.
##
## --workshop-unlock N, with --workshop, opens only the groups that cost N
## Coins or less to unlock (15000: every group up to Orbs).
##
## --until-wave N ends a career once a run reaches wave N, saying which run
## and after how many hours of game time; in single runs it ends each run there.
## --tier N plays each run in Tier N (1 to 3, D107): its enemies' health and
## attack, its Coins bonus and its spawns, from TowerData.tier.
## --career-seed N plays another career: run R is seed N × 1000 + R (0, the
## default, is run R on seed R, as before).
## Experiments that are not the game's rules (BattleSim's measuring options):
## --packages N opens Recovery Packages with its rows at level N in every run;
## --packages-to-best makes a package refill only to the run's best; and
## --sure-divider FROM:EVERY:DIVISOR lands a Divider nothing can stop, every
## EVERY waves from wave FROM.
## --careers N plays N runs in a row from a fresh Workshop instead, spending
## the Coins between runs: it opens the cheapest group it can, otherwise buys
## the open Workshop row with the fewest levels, until nothing is affordable.
## Each run buys with --buy (use even). Each row printed is one run.
## --legacy-progression omits D126's wave rewards for a before/after career
## comparison; normal careers receive the same one-time rewards as the UI.

const BattleSim = preload("res://src/tower/battle_sim.gd")
const TowerData = preload("res://src/tower/tower_data.gd")
const Workshop = preload("res://src/tower/workshop.gd")
const Progression = preload("res://src/tower/progression.gd")

const STRATEGIES := ["none", "cheapest", "even", "attack", "core", "grow", "health", "survival"]
## With --buy health, this share of the Cash earned goes to Health.
const HEALTH_SHARE := 0.6
## With --buy survival, the rows bought when the Number isn't low.
const SURVIVAL_ROWS := ["damage", "attack_speed", "defense_absolute"]
## The rows a focused player buys, with --buy core: in the run, and in a
## career's Workshop (where it opens only the Defense group for them).
const CORE_ROWS := ["damage", "attack_speed", "health", "health_regen", "defense_absolute"]
## With --buy grow, a career's Workshop also opens the Cash and Coins groups and buys
## these with the core rows, cheapest first: a focused player who invests in
## income, as The Tower's players do. In the run it buys as core does.
const GROW_ROWS := ["coins_per_kill", "coins_per_wave"]


func _init() -> void:
	var options := _options()
	var seeds := int(options.get("seeds", "10"))
	var cap_seconds := float(options.get("cap-minutes", "90")) * 60.0
	var strategy: String = options.get("buy", "none")
	if strategy not in STRATEGIES:
		printerr("--buy must be one of %s" % ", ".join(STRATEGIES))
		quit(1)
		return
	if options.has("careers"):
		_career(int(options.careers), strategy, cap_seconds, options)
		quit()
		return
	var workshop: String = options.get("workshop", "")
	if workshop not in ["", "open", "max"] and not workshop.is_valid_int():
		printerr("--workshop must be open, max or a level")
		quit(1)
		return
	var levels := {}
	var groups: Array = BattleSim.START_GROUPS
	if workshop != "":
		groups = TowerData.groups().map(func(entry): return String(entry.id))
		if options.has("workshop-unlock"):
			groups = TowerData.groups().filter(func(entry): return float(entry.unlock_coins) <= float(options["workshop-unlock"])).map(func(entry): return String(entry.id))
		if workshop != "open":
			for id in TowerData.rows():
				if TowerData.group(id) in groups:
					levels[id] = TowerData.max_level(id) if workshop == "max" else mini(int(workshop), TowerData.max_level(id))
	var waves: Array[int] = []
	print("buying: %s%s" % [strategy, ", Workshop " + workshop if workshop != "" else ""])
	print("seed  wave  game time  kills  cash earned  coins  peak Number  ÷ came/landed  ÷ took  killed by  levels bought")
	for index in range(seeds):
		var sim := BattleSim.new(index + 1, levels, groups, int(options.get("tier", "1")))
		_tune(sim, options)
		var last_wave := int(options.get("until-wave", "0"))
		while sim.alive and sim.time < cap_seconds and (last_wave <= 0 or sim.wave < last_wave):
			_spend(sim, strategy)
			sim.step()
		waves.append(sim.wave)
		print("%4d  %4d  %9s  %5d  %11.0f  %5.0f  %11.1f  %13s  %5.0f%%  %-9s  %s" % [index + 1, sim.wave, _clock(sim.time), sim.kills, sim.cash_earned, sim.coins,
			sim.peak_number, "%d/%d" % [sim.dividers_spawned, sim.dividers_landed], _divider_share_of_loss(sim),
			sim.killed_by if not sim.alive else "(alive)", _bought(sim)] + _curve(sim, options) + _gains(sim, options))
	waves.sort()
	print("median wave %d, range %d to %d" % [waves[waves.size() / 2], waves[0], waves[-1]])
	quit()


func _career(runs: int, strategy: String, cap_seconds: float, options: Dictionary) -> void:
	var workshop := Workshop.new()
	var progression := Progression.new(workshop)
	var hours := 0.0
	print("career, buying %s in each run, %d-minute cap" % [strategy, int(cap_seconds / 60.0)])
	print("run  wave  game time  hours  coins earned  coins left  peak Number  start Number  last wave's Number  ÷ came/landed  killed by  Workshop")
	var until := int(options.get("until-wave", "0"))
	var seed_base := int(options.get("career-seed", "0")) * 1000
	for run in range(runs):
		var sim := BattleSim.new(seed_base + run + 1, workshop.levels, workshop.open_groups, int(options.get("tier", "1")))
		_tune(sim, options)
		var start_number := sim.health
		while sim.alive and sim.time < cap_seconds:
			_spend(sim, strategy)
			sim.step()
		workshop.add_coins(sim.coins)
		workshop.finish_run(sim.wave, sim.peak_number)
		# Same one-time rewards as the screens; the switch measures D125's
		# earlier progression without altering any battle rules.
		if not options.has("legacy-progression"):
			progression.observe(sim.tier, sim.wave, sim.wave if sim.killed_by == "data_limit" else sim.wave - 1)
		hours += sim.time / 3600.0
		_spend_workshop(workshop, strategy)
		# The Number as the wave it ended on began (at death it reads 0).
		var entering: float = float(sim.wave_log[-1].health) if not sim.wave_log.is_empty() else start_number
		print("%3d  %4d  %9s  %5.1f  %12.0f  %10.0f  %11.0f  %12.0f  %18.0f  %13s  %-9s  %s" % [run + 1, sim.wave, _clock(sim.time), hours, sim.coins, workshop.coins,
			sim.peak_number, start_number, entering, "%d/%d" % [sim.dividers_spawned, sim.dividers_landed], sim.killed_by if not sim.alive else "(alive)", _workshop_summary(workshop)] + _curve(sim, options) + _gains(sim, options))
		if until > 0 and sim.wave >= until:
			print("reached wave %d on run %d, after %.1f hours of game time" % [until, run + 1, hours])
			return


func _spend_workshop(workshop: Workshop, strategy: String) -> void:
	if strategy in ["core", "grow", "health", "survival"]:
		# The Coins group opens only after Cash, in The Tower's order.
		var groups := ["defense", "cash", "coins"] if strategy == "grow" else ["defense"]
		var rows: Array = CORE_ROWS + GROW_ROWS if strategy == "grow" else CORE_ROWS
		while true:
			var closed := groups.filter(func(group): return not workshop.is_group_open(group))
			if not closed.is_empty():
				if not workshop.open_group(closed[0]):
					return
				continue
			var cheapest := ""
			for id in rows:
				if workshop.level(id) < TowerData.max_level(id) and (cheapest == "" or workshop.price(id) < workshop.price(cheapest)):
					cheapest = id
			if cheapest == "" or not workshop.buy(cheapest):
				return
	while true:
		var cheapest_group := ""
		for category in ["attack", "defense", "utility"]:
			var group := workshop.next_group(category)
			if group != "" and workshop.can_open(group) and (cheapest_group == "" or TowerData.group_price(group) < TowerData.group_price(cheapest_group)):
				cheapest_group = group
		if cheapest_group != "":
			workshop.open_group(cheapest_group)
			continue
		var fewest := ""
		for id in TowerData.rows():
			if workshop.is_group_open(TowerData.group(id)) and workshop.level(id) < TowerData.max_level(id):
				if fewest == "" or workshop.level(id) < workshop.level(fewest):
					fewest = id
		if fewest == "" or not workshop.buy(fewest):
			return


func _workshop_summary(workshop: Workshop) -> String:
	var opened: Array[String] = []
	for group in workshop.open_groups:
		if TowerData.group_price(group) > 0.0:
			opened.append(group)
	var total := 0
	for id in workshop.levels:
		total += int(workshop.levels[id])
	return "%d levels; opened %s" % [total, ", ".join(opened) if not opened.is_empty() else "nothing"]


func _spend(sim: BattleSim, strategy: String) -> void:
	if strategy == "none":
		return
	if strategy == "health":
		_spend_health_heavy(sim)
		return
	if strategy == "survival":
		_spend_survival(sim)
		return
	while true:
		var choice := _choose(sim, strategy)
		if choice == "" or not sim.buy(choice):
			return


## --buy health: every Cash earned is split into a Health budget and a budget
## for the other core rows, and each is spent only on its own rows, waiting
## for the cheapest as core does.
func _spend_health_heavy(sim: BattleSim) -> void:
	var fresh: float = sim.cash_earned - float(sim.get_meta("split", 0.0))
	sim.set_meta("split", sim.cash_earned)
	var for_health: float = float(sim.get_meta("for_health", 0.0)) + fresh * HEALTH_SHARE
	var for_rest: float = float(sim.get_meta("for_rest", 0.0)) + fresh * (1.0 - HEALTH_SHARE)
	while sim.is_open("health") and not sim.at_max("health") and sim.price("health") <= for_health and sim.can_buy("health"):
		for_health -= sim.price("health")
		sim.buy("health")
	while true:
		var cheapest := _cheapest(sim, CORE_ROWS.filter(func(id): return id != "health"))
		if cheapest == "" or sim.price(cheapest) > for_rest or not sim.can_buy(cheapest):
			break
		for_rest -= sim.price(cheapest)
		sim.buy(cheapest)
	sim.set_meta("for_health", for_health)
	sim.set_meta("for_rest", for_rest)


## --buy survival: Health only while the Number is under half the run's best,
## otherwise the cheapest of Damage, Attack Speed and Defense Absolute.
func _spend_survival(sim: BattleSim) -> void:
	while sim.health < 0.5 * sim.peak_number and sim.can_buy("health"):
		sim.buy("health")
	while true:
		var cheapest := _cheapest(sim, SURVIVAL_ROWS)
		if cheapest == "" or not sim.buy(cheapest):
			return


func _cheapest(sim: BattleSim, ids: Array) -> String:
	var best := ""
	for id in ids:
		if sim.is_open(id) and not sim.at_max(id) and (best == "" or sim.price(id) < sim.price(best)):
			best = id
	return best


## The row the strategy buys next, or "" to wait. It waits for its choice
## rather than buying something else, as a player saving up would.
func _choose(sim: BattleSim, strategy: String) -> String:
	var rows: Array[String] = []
	for id in TowerData.rows():
		var allowed: bool = (strategy != "attack" or id in ["damage", "attack_speed"]) and (strategy not in ["core", "grow"] or id in CORE_ROWS)
		if sim.is_open(id) and not sim.at_max(id) and allowed:
			rows.append(id)
	if rows.is_empty():
		return ""
	var best := rows[0]
	for id in rows:
		var better := sim.price(id) < sim.price(best) if strategy != "even" else int(sim.run_levels.get(id, 0)) < int(sim.run_levels.get(best, 0))
		if better:
			best = id
	return best if sim.can_buy(best) else ""


## With --curve, the Number at the end of every fifth wave, as " | 5:12 10:40 …".
func _curve(sim: BattleSim, options: Dictionary) -> String:
	if not options.has("curve"):
		return ""
	var points: Array[String] = []
	for snapshot in sim.wave_log:
		if int(snapshot.wave) % 5 == 0:
			points.append("%d:%.0f" % [int(snapshot.wave), float(snapshot.health)])
	return "  | " + " ".join(points)


## With --gains, " | gained 312: regen 71%/88% health 29%/12%": each source's
## share of everything gained, then of the new highs.
func _gains(sim: BattleSim, options: Dictionary) -> String:
	if not options.has("gains"):
		return ""
	var total := 0.0
	var highs := 0.0
	for source in sim.gained_from:
		total += float(sim.gained_from[source])
	for source in sim.raised_by:
		highs += float(sim.raised_by[source])
	var parts: Array[String] = []
	for source in ["regen", "health", "lifesteal", "package", "kills"]:
		if sim.gained_from.has(source):
			parts.append("%s %.0f%%/%.0f%%" % [source, 100.0 * float(sim.gained_from[source]) / total,
				100.0 * float(sim.raised_by.get(source, 0.0)) / highs if highs > 0.0 else 0.0])
	return "  | gained %.0f, highs %.0f: %s" % [total, highs, " ".join(parts)]


func _tune(sim: BattleSim, options: Dictionary) -> void:
	if options.has("peak-drift"):
		sim.peak_drift = float(options["peak-drift"])
	if options.has("packages"):
		if not "recovery_packages" in sim.open_groups:
			sim.open_groups.append("recovery_packages")
		for id in TowerData.group_rows("recovery_packages"):
			sim.levels[id] = mini(int(options["packages"]), TowerData.max_level(id))
	sim.packages_to_best = options.has("packages-to-best")
	if options.has("sure-divider"):
		var parts: PackedStringArray = String(options["sure-divider"]).split(":")
		sim.sure_from = int(parts[0])
		sim.sure_every = int(parts[1])
		sim.sure_divisor = float(parts[2])
	if options.has("kill-share"):
		sim.kill_share = float(options["kill-share"])
	if options.has("divider-share"):
		var scale := float(options["divider-share"])
		sim.divider.rate_first = minf(1.0, float(sim.divider.rate_first) * scale)
		sim.divider.rate_full = minf(1.0, float(sim.divider.rate_full) * scale)
	if options.has("divider-speed"):
		sim.divider.speed = float(options["divider-speed"])
	if options.has("overfill"):
		sim.overfill = float(options.overfill)
	if options.has("divider-divisor"):
		sim.divider.divisor_first = float(options["divider-divisor"])
		sim.divider.divisor_full = float(options["divider-divisor"])
	if options.has("divider-health"):
		sim.divider.health_first = float(options["divider-health"])
		sim.divider.health_full = float(options["divider-health"])


## The share of everything the Number lost that Dividers took.
func _divider_share_of_loss(sim: BattleSim) -> float:
	var total := 0.0
	for kind in sim.lost_to:
		total += float(sim.lost_to[kind])
	return 100.0 * float(sim.lost_to.get("divider", 0.0)) / total if total > 0.0 else 0.0


func _bought(sim: BattleSim) -> String:
	var parts: Array[String] = []
	for id in sim.run_levels:
		parts.append("%s %d" % [id, sim.run_levels[id]])
	return ", ".join(parts)


func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _options() -> Dictionary:
	var found := {}
	var args := OS.get_cmdline_user_args()
	for index in range(args.size()):
		if args[index].begins_with("--"):
			# An option with no value after it, like --curve, is a switch.
			var has_value := index + 1 < args.size() and not args[index + 1].begins_with("--")
			found[args[index].substr(2)] = args[index + 1] if has_value else "true"
	return found
